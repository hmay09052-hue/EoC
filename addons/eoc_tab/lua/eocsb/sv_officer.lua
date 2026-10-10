--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - Officer-System (Server)
    Posten gelten nur, solange der Spieler auf dem Server ist (keine Datenbank).
-------------------------------------------------------------------------------------------------------------]]

EOCSB.Officers = EOCSB.Officers or {}

local CFG = EOCSB.Config

util.AddNetworkString("EOCSB_OfficerSync")
util.AddNetworkString("EOCSB_OfficerAction")
util.AddNetworkString("EOCSB_OfficerOpen")
util.AddNetworkString("EOCSB_OfficerAnnounce")

local ACTION_JOIN, ACTION_LEAVE, ACTION_ASSIGN, ACTION_CLEAR = 1, 2, 3, 4

local function WriteSync()
    local ranks = CFG.OfficerRanks or {}
    local count = 0
    for _, r in ipairs(ranks) do if EOCSB.Officers[r.id] then count = count + 1 end end
    net.WriteUInt(count, 8)
    for _, r in ipairs(ranks) do
        local o = EOCSB.Officers[r.id]
        if o then
            net.WriteString(r.id)
            net.WriteString(o.sid)
            net.WriteString(o.name)
        end
    end
end

local function SyncAll()
    net.Start("EOCSB_OfficerSync")
    WriteSync()
    net.Broadcast()
end

local function SyncTo(ply)
    net.Start("EOCSB_OfficerSync")
    WriteSync()
    net.Send(ply)
end

function EOCSB.GetOfficerRankOf(sid)
    for id, o in pairs(EOCSB.Officers) do
        if o.sid == sid then return id end
    end
end

function EOCSB.IsOfficer(ply)
    return IsValid(ply) and EOCSB.GetOfficerRankOf(ply:SteamID64() or "") ~= nil
end

local function CanSelfAssign(ply)
    if EOCSB.IsAdmin(ply) then return true end
    if not CFG.OfficerSelfAssign then return false end
    local allowed = CFG.OfficerAllowedGroups or {}
    if #allowed == 0 then return true end
    return EOCSB.InGroupList(ply, allowed)
end

local function Announce(rank, name, joined)
    if not rank or rank.announce == false then return end
    net.Start("EOCSB_OfficerAnnounce")
    net.WriteString(rank.id)
    net.WriteString(name)
    net.WriteBool(joined)
    net.Broadcast()
end

local function ClearOfficer(rankId)
    local o = EOCSB.Officers[rankId]
    if not o then return end
    EOCSB.Officers[rankId] = nil
    SyncAll()
    Announce(EOCSB.GetOfficerRankDef(rankId), o.name, false)
    hook.Run("EOCSB_OfficerChanged", rankId, nil)
end

local function SetOfficer(rankId, ply)
    local rank = EOCSB.GetOfficerRankDef(rankId)
    if not rank or not IsValid(ply) then return end
    local sid = ply:SteamID64() or ""
    local old = EOCSB.GetOfficerRankOf(sid)
    if old == rankId then return end
    if old then ClearOfficer(old) end
    if EOCSB.Officers[rankId] then ClearOfficer(rankId) end
    local name = EOCSB.GetName(ply)
    EOCSB.Officers[rankId] = { sid = sid, name = name }
    SyncAll()
    Announce(rank, name, true)
    hook.Run("EOCSB_OfficerChanged", rankId, ply)
end

net.Receive("EOCSB_OfficerAction", function(_, ply)
    if not IsValid(ply) then return end
    if (ply._eocsbOfficerNext or 0) > CurTime() then return end
    ply._eocsbOfficerNext = CurTime() + 0.5

    local action = net.ReadUInt(3)
    local rankId = net.ReadString()
    local rank = EOCSB.GetOfficerRankDef(rankId)
    if not rank then return end
    local holder = EOCSB.Officers[rankId]
    local sid = ply:SteamID64() or ""
    local isAdmin = EOCSB.IsAdmin(ply)
    local ignoreRules = isAdmin and CFG.OfficerAdminIgnoresJobs

    if action == ACTION_JOIN then
        if holder then return end
        if not CanSelfAssign(ply) then return end
        if not ignoreRules and not EOCSB.OfficerAllowed(ply, rank) then return end
        SetOfficer(rankId, ply)
    elseif action == ACTION_LEAVE then
        if not holder or holder.sid ~= sid then return end
        ClearOfficer(rankId)
    elseif action == ACTION_ASSIGN then
        local target = net.ReadEntity()
        if not IsValid(target) or not target:IsPlayer() then return end
        if not ignoreRules and not EOCSB.OfficerAllowed(target, rank) then return end
        if not isAdmin then
            -- normale Spieler füllen nur FREIE Posten mit Spielern, die noch keinen Posten haben
            if not CanSelfAssign(ply) then return end
            if holder then return end
            if EOCSB.GetOfficerRankOf(target:SteamID64() or "") then return end
        end
        SetOfficer(rankId, target)
    elseif action == ACTION_CLEAR then
        if not isAdmin then return end
        ClearOfficer(rankId)
    end
end)

-- Name im Posten aktuell halten (z.B. nach Namens-/RP-ID-Änderung in SymChars) und Regeln prüfen
timer.Create("EOCSB_OfficerRefresh", 5, 0, function()
    local changed = false
    for rankId, o in pairs(EOCSB.Officers) do
        local ply = player.GetBySteamID64(o.sid)
        if IsValid(ply) then
            local rank = EOCSB.GetOfficerRankDef(rankId)
            if CFG.OfficerRemoveOnJobChange and rank and not EOCSB.OfficerAllowed(ply, rank) then
                ClearOfficer(rankId)
            else
                local name = EOCSB.GetName(ply)
                if name ~= o.name then o.name = name changed = true end
            end
        end
    end
    if changed then SyncAll() end
end)

hook.Add("PlayerDisconnected", "EOCSB_OfficerLeave", function(ply)
    local rankId = EOCSB.GetOfficerRankOf(ply:SteamID64() or "")
    if rankId then ClearOfficer(rankId) end
end)

local function OpenMenu(ply)
    SyncTo(ply)
    net.Start("EOCSB_OfficerOpen")
    net.Send(ply)
end

hook.Add("PlayerSay", "EOCSB_OfficerCommand", function(ply, text)
    local cmd = string.lower(string.Trim(text))
    for _, c in ipairs(CFG.OfficerChatCommands or {}) do
        if cmd == string.lower(c) then
            OpenMenu(ply)
            return ""
        end
    end
end)

concommand.Add("eocsb_officer", function(ply)
    if IsValid(ply) then OpenMenu(ply) end
end)

hook.Add("PlayerInitialSpawn", "EOCSB_OfficerSync", function(ply)
    timer.Simple(3, function()
        if IsValid(ply) then SyncTo(ply) end
    end)
end)

---------------------------------------------------------------------------------------------------------------
-- Nur EIN Officer-System: das alte Kraken-Scoreboard (BF2SB) hat ein eigenes /officer - das wird abgeschaltet.
-- Liegt noch die alte Version dieses Addons (Ordner eoc_scoreboard) auf dem Server, gibt es eine Warnung.
---------------------------------------------------------------------------------------------------------------
local function RemoveOtherOfficerSystems()
    hook.Remove("PlayerSay", "BF2SB_OfficerCommand")
    hook.Remove("PlayerDisconnected", "BF2SB_OfficerLeave")
    hook.Remove("PlayerInitialSpawn", "BF2SB_OfficerSync")
    hook.Remove("OnPlayerChangedTeam", "BF2SB_OfficerJobCheck")
    concommand.Remove("bf2sb_officer")
    if BF2SB then
        print("[EoC Scoreboard] Kraken BF2-Scoreboard gefunden - dessen Officer-System wurde abgeschaltet. Bitte 'krakens-bf2scoreboard' vom Server entfernen.")
    end
    if file.Exists("autorun/eoc_scoreboard.lua", "LUA") then
        print("[EoC Scoreboard] ACHTUNG: Die alte Version (addons/eoc_scoreboard) liegt noch auf dem Server - bitte löschen, sonst läuft alles doppelt.")
    end
end
hook.Add("Initialize", "EOCSB_OnlyOneOfficerSystem", RemoveOtherOfficerSystems)
timer.Simple(0, RemoveOtherOfficerSystems)
