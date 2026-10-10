CryptoRadio = CryptoRadio or {}
CryptoRadio.Log      = CryptoRadio.Log or {}
CryptoRadio.NextSend = CryptoRadio.NextSend or {}
CryptoRadio.Draft    = CryptoRadio.Draft or {
    text     = "",
    range    = CryptoRadio.RANGE_SHORT,
    encrypt  = false,
    selected = {},
}

local cfg = CryptoRadio.Config
local SHORT, LONG = CryptoRadio.RANGE_SHORT, CryptoRadio.RANGE_LONG

-- Farben passend zum Echoes of Clones HUD (grn_hud_v1)
local C = {
    yellow  = Color(252, 178, 73),
    yellowD = Color(252, 178, 73, 56),
    yellowF = Color(252, 178, 73, 20),
    white   = Color(244, 241, 233),
    text    = Color(216, 219, 225),
    soft    = Color(157, 163, 173),
    muted   = Color(101, 107, 117),
    bg      = Color(7, 9, 12, 240),
    panel   = Color(8, 11, 15, 220),
    panel2  = Color(14, 18, 23, 235),
    line    = Color(207, 216, 228, 38),
    lineS   = Color(207, 216, 228, 77),
    red     = Color(225, 88, 88),
    green   = Color(74, 203, 130),
    blue    = Color(90, 170, 255),
    cyan    = Color(80, 200, 220),
    me      = Color(255, 220, 150),
}
if SYMUI then SYMUI.ApplyEoCPalette(C) end -- SymChars-Design
-- Alias für andere Dateien (Störsender)
C.accent = C.yellow
CryptoRadio.Colors = C

surface.CreateFont("CryptoRadio_Title",   { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 34, weight = 400, extended = true })
surface.CreateFont("CryptoRadio_Button",  { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 22, weight = 400, extended = true })

local function Notify(text, isErr)
    chat.AddText(C.yellow, "[FUNK] ", isErr and C.red or C.white, text)
    if isErr then surface.PlaySound(cfg.Sounds.Error) end
end
CryptoRadio.ClientNotify = Notify

local function RangeTag(range)
    if range == LONG then return "LANG", C.yellow end
    return "KURZ", C.soft
end

---------------------------------------------------------------------------
-- Funklog
---------------------------------------------------------------------------
local function AddLog(entry)
    table.insert(CryptoRadio.Log, 1, entry)
    while #CryptoRadio.Log > cfg.ClientLogSize do
        table.remove(CryptoRadio.Log)
    end
end

---------------------------------------------------------------------------
-- Netzwerk: Funk
---------------------------------------------------------------------------
local ROLE_IN, ROLE_OUT, ROLE_OVERHEAR = 1, 2, 3

net.Receive("CryptoRadio_Notify", function()
    Notify(net.ReadString(), net.ReadBool())
end)

net.Receive("CryptoRadio_Open", function()
    CryptoRadio.OpenMenu(net.ReadUInt(2))
end)

net.Receive("CryptoRadio_Radio", function()
    local role   = net.ReadUInt(2)
    local sender = net.ReadString()
    local targets = {}
    for i = 1, net.ReadUInt(8) do targets[i] = net.ReadString() end
    local range     = net.ReadUInt(2)
    local encrypted = net.ReadBool()
    local jammed    = net.ReadBool()
    local text      = net.ReadString()

    local tag, tcol = RangeTag(range)
    local parts = {}

    if encrypted then
        table.Add(parts, { C.green, "[V-FUNK] " })
    else
        table.Add(parts, { C.yellow, "[FUNK] " })
    end
    table.Add(parts, { tcol, "[" .. tag .. "] " })
    if jammed then table.Add(parts, { C.red, "[GESTÖRT] " }) end

    if role == ROLE_IN then
        local to = #targets > 1 and ("Dich +" .. (#targets - 1)) or "Dich"
        table.Add(parts, { C.white, sender, C.soft, " » " .. to .. ": ", C.white, text })
        local snd = cfg.Sounds
        for i = 0, math.max((snd.BeepCount or 1) - 1, 0) do
            timer.Simple(i * (snd.BeepDelay or 0.14), function() surface.PlaySound(snd.Beep) end)
        end

        AddLog({ dir = "in", sender = sender, targets = targets, range = range,
            encrypted = encrypted, jammed = jammed, text = text, time = os.time() })

    elseif role == ROLE_OUT then
        table.Add(parts, { C.white, "Du", C.soft, " » " .. table.concat(targets, ", ") .. ": ", C.white, text })

        AddLog({ dir = "out", sender = "Du", targets = targets, range = range,
            encrypted = encrypted, jammed = jammed, text = text, time = os.time() })

        CryptoRadio.NextSend[range] = CurTime() + (range == LONG and cfg.LongCooldown or cfg.ShortCooldown)
        CryptoRadio.Draft.text = ""
        if IsValid(CryptoRadio.ComlinkEntry) then CryptoRadio.ComlinkEntry:SetText("") end

    else -- mitgehört
        table.Add(parts, { C.soft, sender .. " » " .. table.concat(targets, ", ") .. ": " })
        if encrypted then
            table.Add(parts, { C.muted, text })
        else
            table.Add(parts, { C.text, text })
        end
    end

    chat.AddText(unpack(parts))
end)

---------------------------------------------------------------------------
-- Netzwerk: RP-Aktionen
---------------------------------------------------------------------------
local function ScanBar(pct)
    local n = math.floor(pct / 10)
    return "[" .. string.rep("|", n) .. string.rep(".", 10 - n) .. "] " .. pct .. "%"
end

net.Receive("CryptoRadio_Action", function()
    local kind = net.ReadString()
    local name = net.ReadString()
    local text = net.ReadString()
    local pct  = net.ReadUInt(7)

    if kind == "akt" then
        chat.AddText(C.yellow, "[AKTION] ", C.white, name .. ": ", C.text, text)
    elseif kind == "me" then
        chat.AddText(C.me, "* " .. name .. " " .. text)
    elseif kind == "eakt" then
        chat.AddText(C.blue, "[TECHNIK] ", C.white, name .. ": ", C.text, text)
    elseif kind == "makt" then
        chat.AddText(C.red, "[MEDIZIN] ", C.white, name .. ": ", C.text, text)
    elseif kind == "scan_start" then
        local what = text ~= "" and (" – " .. text) or ""
        chat.AddText(C.cyan, "[SCAN] ", C.white, name, C.soft, " startet einen Scan" .. what)
        surface.PlaySound(cfg.Sounds.ScanTick)
    elseif kind == "scan" then
        chat.AddText(C.cyan, "[SCAN] ", C.white, name .. ": ", C.soft, (text ~= "" and text .. "  " or ""), C.cyan, ScanBar(pct))
        surface.PlaySound(cfg.Sounds.ScanTick)
    elseif kind == "scan_done" then
        chat.AddText(C.cyan, "[SCAN] ", C.white, name .. ": ", C.soft, (text ~= "" and text .. "  " or ""), C.green, ScanBar(pct) .. " – Scan abgeschlossen")
        surface.PlaySound(cfg.Sounds.ScanDone)
    elseif kind == "scan_abort" then
        chat.AddText(C.cyan, "[SCAN] ", C.white, name .. ": ", C.red, "Scan abgebrochen.")
    end
end)

---------------------------------------------------------------------------
-- Empfänger (alle Spieler, kein Datapad nötig)
---------------------------------------------------------------------------
local function EligiblePlayers()
    local lp = LocalPlayer()
    local list = {}
    for _, p in ipairs(player.GetAll()) do
        if p ~= lp then
            list[#list + 1] = p
        end
    end
    table.sort(list, function(a, b) return a:Nick():lower() < b:Nick():lower() end)
    return list
end
CryptoRadio.EligiblePlayers = EligiblePlayers

-- true = in Reichweite, false = außer Reichweite, nil = unbekannt
local function InRange(p, range)
    if range == LONG or (cfg.ShortRange or 0) <= 0 then return true end
    if p:IsDormant() then return nil end
    return CryptoRadio.InRadioRange(LocalPlayer():GetPos(), p:GetPos(), range)
end
CryptoRadio.InRangeClient = InRange

---------------------------------------------------------------------------
-- Befehle (werden im Comlink-Reiter BEFEHLE angezeigt)
---------------------------------------------------------------------------
local HELP = {
    { "/funk <Empfänger> <Nachricht>",   "Normaler Funk" },
    { "/vfunk <Empfänger> <Nachricht>",  "Verschlüsselter Funk (nur Empfänger kann lesen)" },
    { "/lfunk <Empfänger> <Nachricht>",  "Langstrecken-Funk" },
    { "/vlfunk <Empfänger> <Nachricht>", "Verschlüsselter Langstrecken-Funk" },
    { "/akt <Text>",  "Aktion ausführen" },
    { "/me <Text>",   "Aktion für dich selbst" },
    { "/eakt <Text>", "Technische Aktion" },
    { "/makt <Text>", "Medizinische Aktion" },
    { "/scan <Ziel>", "Scan durchführen (10% – 100%)" },
}
CryptoRadio.Help = HELP

-- Öffnet den Textfunk über dem Comlink am Arm (wie Taste J), nur in der Ego-Perspektive
function CryptoRadio.OpenMenu(tab)
    if CryptoRadio.OpenComlink then CryptoRadio.OpenComlink(tab) end
end

concommand.Add("crypto_radio_log", function() CryptoRadio.OpenMenu(2) end)
