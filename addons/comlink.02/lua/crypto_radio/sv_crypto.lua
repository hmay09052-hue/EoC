util.AddNetworkString("CryptoRadio_Open")
util.AddNetworkString("CryptoRadio_Send")
util.AddNetworkString("CryptoRadio_Radio")
util.AddNetworkString("CryptoRadio_Action")
util.AddNetworkString("CryptoRadio_Notify")

local cfg = CryptoRadio.Config
local SHORT, LONG = CryptoRadio.RANGE_SHORT, CryptoRadio.RANGE_LONG

-- Rollen für CryptoRadio_Radio
local ROLE_IN, ROLE_OUT, ROLE_OVERHEAR = 1, 2, 3

---------------------------------------------------------------------------
-- Hilfsfunktionen
---------------------------------------------------------------------------
function CryptoRadio.Notify(ply, text, isErr)
    net.Start("CryptoRadio_Notify")
        net.WriteString(text)
        net.WriteBool(isErr and true or false)
    net.Send(ply)
end
local Notify = CryptoRadio.Notify

function CryptoRadio.OpenMenu(ply, tab)
    net.Start("CryptoRadio_Open")
        net.WriteUInt(tab or 1, 2)
    net.Send(ply)
end

local JAM_CHARS = { "#", "%", "&", "*", "~", "?", "/", "\\", "=", "+", "$", "!", "_", "|" }

local function Scramble(text, strength)
    local out = {}
    for _, code in utf8.codes(text) do
        local ch = utf8.char(code)
        if ch ~= " " and math.random() < strength then
            ch = JAM_CHARS[math.random(#JAM_CHARS)]
        end
        out[#out + 1] = ch
    end
    return table.concat(out)
end

-- Unlesbarer Zeichensalat für alle, die verschlüsselten Funk mitbekommen
local function MakeCipher(text)
    local out = {}
    local n = math.min(#text, 32)
    for i = 1, n do
        out[#out + 1] = string.format("%02X", bit.bxor(string.byte(text, i), math.random(0, 255)))
    end
    local s = table.concat(out, " ")
    if #text > n then s = s .. " ..." end
    return s
end

local function PlayersNear(pos, radius, exclude)
    local r2 = radius ^ 2
    local list = {}
    for _, p in ipairs(player.GetAll()) do
        if not (exclude and exclude[p]) and p:GetPos():DistToSqr(pos) <= r2 then
            list[#list + 1] = p
        end
    end
    return list
end
CryptoRadio.PlayersNear = PlayersNear

local function WriteRadio(role, sender, targetNames, range, encrypted, jammed, text)
    net.Start("CryptoRadio_Radio")
        net.WriteUInt(role, 2)
        net.WriteString(sender)
        net.WriteUInt(#targetNames, 8)
        for _, n in ipairs(targetNames) do net.WriteString(n) end
        net.WriteUInt(range, 2)
        net.WriteBool(encrypted)
        net.WriteBool(jammed)
        net.WriteString(text)
end

---------------------------------------------------------------------------
-- Empfänger prüfen
---------------------------------------------------------------------------
-- Gibt nil zurück wenn der Spieler empfangen kann, sonst einen Fehlertext
function CryptoRadio.CanReceive(sender, target, range)
    if not IsValid(target) or target == sender then return "Ungültiger Empfänger." end
    local name = CryptoRadio.GetName(target)
    if not cfg.DeadCanReceive and not target:Alive() then
        return name .. " ist nicht erreichbar."
    end
    if not CryptoRadio.InRadioRange(sender:GetPos(), target:GetPos(), range) then
        return name .. " ist außer Kurzstrecken-Reichweite (nutze /lfunk)."
    end
end

---------------------------------------------------------------------------
-- Funkspruch übertragen (wird von Menü und Chat-Befehlen genutzt)
---------------------------------------------------------------------------
function CryptoRadio.Transmit(ply, targets, range, encrypted, text)
    if not IsValid(ply) or not ply:Alive() then return false end

    text = text:gsub("[\r\n\t]", " ")
    text = string.Trim(text)

    local len = utf8.len(text)
    if not len or len == 0 then
        Notify(ply, "Die Nachricht ist leer oder ungültig.", true)
        return false
    end
    if len > cfg.MaxLength then
        Notify(ply, "Die Nachricht ist zu lang (max. " .. cfg.MaxLength .. " Zeichen).", true)
        return false
    end

    if range == LONG and cfg.LongRangeNeedsAntenna and CryptoRadio.IsAntennaDown() then
        Notify(ply, "Langstreckenfunk ausgefallen – die Antenne ist beschädigt.", true)
        return false
    end

    ply.CryptoRadioNext = ply.CryptoRadioNext or {}
    local now = CurTime()
    local nextAllowed = ply.CryptoRadioNext[range] or 0
    if nextAllowed > now then
        Notify(ply, string.format("Funkgerät lädt noch (%.1fs).", nextAllowed - now), true)
        return false
    end

    -- Empfänger filtern
    local valid, seen, firstErr = {}, {}, nil
    for _, t in ipairs(targets) do
        if not seen[t] then
            seen[t] = true
            local err = CryptoRadio.CanReceive(ply, t, range)
            if err then
                firstErr = firstErr or err
            else
                valid[#valid + 1] = t
            end
        end
    end

    if #valid == 0 then
        Notify(ply, firstErr or "Kein gültiger Empfänger erreichbar.", true)
        return false
    end

    if hook.Run("CryptoRadio_CanSend", ply, valid, range, text, encrypted) == false then return false end

    ply.CryptoRadioNext[range] = now + (range == LONG and cfg.LongCooldown or cfg.ShortCooldown)

    local senderName = CryptoRadio.GetName(ply)
    local senderJammed = CryptoRadio.IsJammed(ply:GetPos())
    local strength = range == LONG and cfg.JamStrengthLong or cfg.JamStrength

    local names, involved = {}, { [ply] = true }
    for _, t in ipairs(valid) do
        names[#names + 1] = CryptoRadio.GetName(t)
        involved[t] = true
    end

    -- An die Empfänger
    for _, t in ipairs(valid) do
        local jammed = senderJammed or CryptoRadio.IsJammed(t:GetPos())
        local delivered = jammed and Scramble(text, strength) or text
        WriteRadio(ROLE_IN, senderName, names, range, encrypted, jammed, delivered)
        net.Send(t)
    end

    -- Bestätigung an den Sender
    WriteRadio(ROLE_OUT, senderName, names, range, encrypted, senderJammed, text)
    net.Send(ply)

    if cfg.Sounds.Send and cfg.Sounds.Send ~= "" then
        ply:EmitSound(cfg.Sounds.Send, 60, 100, 0.6)
    end

    -- Umstehende bekommen den Funk mit (verschlüsselt = unlesbar)
    if cfg.OverhearRange and cfg.OverhearRange > 0 then
        local listeners = PlayersNear(ply:GetPos(), cfg.OverhearRange, involved)
        if #listeners > 0 then
            WriteRadio(ROLE_OVERHEAR, senderName, names, range, encrypted, senderJammed,
                encrypted and MakeCipher(text) or text)
            net.Send(listeners)
        end
    end

    if cfg.ServerConsoleLog then
        MsgN(string.format("[CryptoRadio] %s (%s) -> %s [%s%s]: %s", ply:Nick(), ply:SteamID(),
            table.concat(names, ", "), range == LONG and "LANG" or "KURZ", encrypted and ", VERSCHL." or "", text))
    end

    hook.Run("CryptoRadio_Sent", ply, valid, range, text, encrypted)
    return true
end

---------------------------------------------------------------------------
-- Senden über das Comlink (Taste J)
---------------------------------------------------------------------------
net.Receive("CryptoRadio_Send", function(_, ply)
    if not IsValid(ply) then return end

    local range     = net.ReadUInt(2)
    local text      = net.ReadString()
    local encrypted = net.ReadBool()
    local count     = math.min(net.ReadUInt(8), 128)

    local targets = {}
    for i = 1, count do
        local t = Player(net.ReadUInt(32))
        if IsValid(t) then targets[#targets + 1] = t end
    end

    if range ~= SHORT and range ~= LONG then return end

    CryptoRadio.Transmit(ply, targets, range, encrypted, text)
end)

---------------------------------------------------------------------------
-- RP-Aktionen (/akt, /me, /eakt, /makt, /scan)
---------------------------------------------------------------------------
function CryptoRadio.SendAction(ply, kind, text, percent)
    local listeners = PlayersNear(ply:GetPos(), cfg.ActionRange)
    net.Start("CryptoRadio_Action")
        net.WriteString(kind)
        net.WriteString(CryptoRadio.GetName(ply))
        net.WriteString(text or "")
        net.WriteUInt(percent or 0, 7)
    net.Send(listeners)
end

function CryptoRadio.StartScan(ply, text)
    if ply.CryptoRadioScanning then
        Notify(ply, "Es läuft bereits ein Scan.", true)
        return
    end
    ply.CryptoRadioScanning = true

    local steps = cfg.ScanSteps
    local timerName = "CryptoRadio_Scan_" .. ply:EntIndex()
    local i = 0

    CryptoRadio.SendAction(ply, "scan_start", text, 0)

    timer.Create(timerName, cfg.ScanInterval, #steps, function()
        if not IsValid(ply) then
            timer.Remove(timerName)
            return
        end
        if not ply:Alive() then
            ply.CryptoRadioScanning = nil
            CryptoRadio.SendAction(ply, "scan_abort", text, 0)
            timer.Remove(timerName)
            return
        end

        i = i + 1
        local pct = steps[i]
        CryptoRadio.SendAction(ply, i == #steps and "scan_done" or "scan", text, pct)

        if i >= #steps then
            ply.CryptoRadioScanning = nil
        end
    end)
end
