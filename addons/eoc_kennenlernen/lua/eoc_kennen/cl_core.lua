local K = EOC_KENNEN

K.KnownFor = K.KnownFor or 0 -- Charakter-ID, zu der die Liste gehört
K.Known = K.Known or {}
K.Orig = K.Orig or {}
K.Wrapped = K.Wrapped or {}

net.Receive("eoc_kennen_sync", function()
    local charID = net.ReadUInt(32)
    local count = net.ReadUInt(16)
    local known = {}
    for _ = 1, count do
        known[net.ReadUInt(32)] = true
    end
    K.KnownFor, K.Known = charID, known
end)

net.Receive("eoc_kennen_add", function()
    local charID = net.ReadUInt(32)
    local otherID = net.ReadUInt(32)
    if charID ~= K.KnownFor then
        K.KnownFor, K.Known = charID, {}
    end
    K.Known[otherID] = true
end)

-- Kennt der lokale Spieler (mit seinem aktiven Charakter) diesen Spieler?
function K.KnowsPlayer(ply)
    local lp = LocalPlayer()
    if not IsValid(ply) or not IsValid(lp) or ply == lp then return true end
    if not ply:IsPlayer() then return true end

    local otherID = K.GetCharID(ply)
    if otherID == 0 then return true end -- ohne Charakter gibt es keinen RP-Namen
    if K.CanSeeAll(lp) then return true end

    local myID = K.GetCharID(lp)
    if myID == 0 or myID ~= K.KnownFor then return false end
    return K.Known[otherID] == true
end

-- Pro Frame zwischenspeichern, Nick() wird sehr oft aufgerufen
local cache, cacheFrame = {}, -1

function K.UnknownName(ply, overhead)
    local frame = FrameNumber()
    if frame ~= cacheFrame then cache, cacheFrame = {}, frame end

    local key = ply:EntIndex() .. (overhead and "o" or "n")
    local name = cache[key]
    if name then return name end

    local cfg = K.Cfg()
    name = K.FormatUnknown(K.GetChar(ply), overhead and cfg.UnknownOverheadFormat or cfg.UnknownFormat)
    cache[key] = name
    return name
end

-- Echter Name, ohne die eigenen Wrapper (DarkRP-Nick liest selbst getDarkRPVar("rpname"))
function K.RealName(ply)
    if K.Orig.getDarkRPVar then
        local name = K.Orig.getDarkRPVar(ply, "rpname")
        if isstring(name) and name ~= "" then return name end
    end
    if K.Orig.Nick then return K.Orig.Nick(ply) end
    return ply:Nick()
end

---------------------------------------------------------------------------------------------------------------
-- Overrides. DarkRP und andere Addons setzen Nick/Name erst nach den Autorun-Dateien,
-- deshalb mehrfach versuchen und nur wrappen, wenn die Funktion sich geändert hat.
---------------------------------------------------------------------------------------------------------------
local function wrapPlayerNames()
    local PLAYER = FindMetaTable("Player")

    for _, fn in ipairs({ "Nick", "Name", "GetName" }) do
        local current = PLAYER[fn]
        if current and current ~= K.Wrapped[fn] then
            K.Orig[fn] = current
            K.Wrapped[fn] = function(self, ...)
                local real = K.Orig[fn](self, ...)
                if K.KnowsPlayer(self) then return real end
                return K.UnknownName(self)
            end
            PLAYER[fn] = K.Wrapped[fn]
        end
    end

    local getVar = PLAYER.getDarkRPVar
    if getVar and getVar ~= K.Wrapped.getDarkRPVar then
        K.Orig.getDarkRPVar = getVar
        K.Wrapped.getDarkRPVar = function(self, var, ...)
            local value = K.Orig.getDarkRPVar(self, var, ...)
            if var == "rpname" and value ~= nil and not K.KnowsPlayer(self) then
                return K.UnknownName(self)
            end
            return value
        end
        PLAYER.getDarkRPVar = K.Wrapped.getDarkRPVar
    end
end

-- SymChars Namensschild über dem Kopf (Rang steht dort schon darunter)
local function wrapSymChars()
    local UT = symchars and symchars.utils
    if not UT or not UT.BuildDisplayName or UT.BuildDisplayName == K.Wrapped.BuildDisplayName then return end

    K.Orig.BuildDisplayName = UT.BuildDisplayName
    K.Wrapped.BuildDisplayName = function(char, ...)
        local real = K.Orig.BuildDisplayName(char, ...)
        if isnumber(char) and symchars.chars then char = symchars.chars.Get(char) end
        local ply = istable(char) and char.GetPlayer and char:GetPlayer()
        if not IsValid(ply) or K.KnowsPlayer(ply) then return real end
        return K.UnknownName(ply, true)
    end
    UT.BuildDisplayName = K.Wrapped.BuildDisplayName
end

-- Kraken-Addons (Scoreboard, Squad, Medic) holen den Namen teils hierüber
local function wrapKraken()
    local I = KF and KF.Integrations
    if not I or not I.GetPlayerName or I.GetPlayerName == K.Wrapped.GetPlayerName then return end

    K.Orig.GetPlayerName = I.GetPlayerName
    K.Wrapped.GetPlayerName = function(ply, ...)
        local real = K.Orig.GetPlayerName(ply, ...)
        if not IsValid(ply) or not ply:IsPlayer() or K.KnowsPlayer(ply) then return real end
        return K.UnknownName(ply)
    end
    I.GetPlayerName = K.Wrapped.GetPlayerName
end

-- Chat: Server-Nachrichten (DarkRP OOC/Lokal usw.) enthalten den Namen schon als Text.
-- Echte Namen von Unbekannten im Text ersetzen.
local function maskText(text)
    for _, ply in ipairs(player.GetAll()) do
        if not K.KnowsPlayer(ply) then
            local real = K.RealName(ply)
            if isstring(real) and #real >= 3 and string.find(text, real, 1, true) then
                text = string.Replace(text, real, K.UnknownName(ply))
            end
        end
    end
    return text
end

local function wrapChat()
    local current = chat.AddText
    if not current or current == K.Wrapped.AddText then return end

    K.Orig.AddText = current
    K.Wrapped.AddText = function(...)
        local args = { ... }
        for i = 1, select("#", ...) do
            if isstring(args[i]) then args[i] = maskText(args[i]) end
        end
        return K.Orig.AddText(unpack(args, 1, select("#", ...)))
    end
    chat.AddText = K.Wrapped.AddText
end

function K.InstallOverrides()
    wrapPlayerNames()
    wrapSymChars()
    wrapKraken()
    wrapChat()
end

hook.Add("Initialize", "EOC_Kennen_Overrides", K.InstallOverrides)
hook.Add("InitPostEntity", "EOC_Kennen_Overrides", function()
    K.InstallOverrides()
    -- Manche Addons (z.B. AtlasChat) ersetzen Funktionen erst später
    timer.Simple(5, K.InstallOverrides)
    timer.Simple(30, K.InstallOverrides)
end)
if GAMEMODE then K.InstallOverrides() end
