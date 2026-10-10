--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Charakter-Objekt (kompatibel zur alten symchars-API)
-------------------------------------------------------------------------------------------------------------]]

symchars.chars = symchars.chars or {}
symchars.chars.loaded = symchars.chars.loaded or {}

local C = symchars.chars
local U = symchars.util

local CHAR = C._meta or {}
CHAR.__index = CHAR
CHAR.__type = "symchars.character"
C._meta = CHAR

function CHAR:GetID() return self.charID end
function CHAR:GetSteamID() return self.charUser end
function CHAR:GetName() return self.name end
function CHAR:GetModel() return self.model end
function CHAR:GetJob() return self.job end
function CHAR:GetMoney() return self.money end
function CHAR:GetRoleplayID() return self.roleplayID end
function CHAR:IsActive() return tonumber(self.charActive) ~= 0 end
function CHAR:GetFactionID() return (self.faction and self.faction ~= "none") and self.faction or nil end

function CHAR:GetFaction()
    local id = self.faction
    if id == nil or id == "none" or id == "" then return nil end
    return symchars.factions.Get(id)
end

function CHAR:GetRank() return tonumber(self.rank) or 1 end

function CHAR:GetRankData()
    local faction = self:GetFaction()
    return faction and faction:GetRank(self:GetRank()) or nil
end

function CHAR:GetRankName()
    local rank = self:GetRankData()
    return rank and rank.name or ""
end

function CHAR:HasRankFlag(flag)
    local rank = self:GetRankData()
    if not rank then return false end
    return U.InList(rank.flags, flag)
end

function CHAR:HasSharedRankFlag(sharedFaction, flag)
    local rank = self:GetRankData()
    local shared = symchars.factions.Get(sharedFaction)
    if not rank or not shared then return false end
    return U.InList(rank.flags, shared.uniqueID .. "_" .. flag)
end

function CHAR:GetData(key, default)
    local data = self.data or {}
    if key == nil then return data end
    if not symchars.utils.VarIsEnabled(key) then return default end
    local value = data[key]
    if value == nil then return default end
    return value
end

function CHAR:SetData(key, value)
    if not symchars.utils.VarIsEnabled(key) then return end
    self.data = self.data or {}
    self.data[key] = value
    if SERVER and C.SaveData then C.SaveData(self) end
end

function CHAR:IsCustom() return istable(self.customs) end
function CHAR:GetCustoms() return istable(self.customs) and self.customs or "none" end
function CHAR:GetCustomWeapons() return istable(self.customs) and self.customs.weapons or nil end
function CHAR:GetCustomHealth() return istable(self.customs) and self.customs.hp or nil end
function CHAR:GetCustomArmor() return istable(self.customs) and self.customs.ap or nil end

-- Fortbildungen: self.trainings = { [trainingID] = { at, by, byName, note, exp } }
function CHAR:GetTrainings() return self.trainings or {} end

function CHAR:HasTraining(id)
    local t = (self.trainings or {})[id]
    if not t then return false end
    if t.exp and t.exp > 0 and t.exp < os.time() then return false end
    return true
end

-- charID -> Spieler, einmal pro Tick aufgebaut (Listen fragen das sehr oft ab)
local onlineStamp, onlineMap = -1, {}
function C.OnlineMap()
    -- Server: immer frisch (Auswahl/Wechsel passieren innerhalb eines Ticks), Client: pro Tick zwischenspeichern
    local stamp = SERVER and -2 or CurTime()
    if stamp ~= onlineStamp or SERVER then
        onlineStamp, onlineMap = stamp, {}
        for _, ply in ipairs(player.GetAll()) do
            local id = ply:GetNW2Int("symchars_charid", 0)
            if id ~= 0 then onlineMap[id] = ply end
        end
    end
    return onlineMap
end

function CHAR:GetPlayer()
    local ply = C.OnlineMap()[self.charID]
    if IsValid(ply) then return ply end
    return nil
end

function CHAR:IsOnline()
    return IsValid(self:GetPlayer())
end

-- Anzeigename inkl. RP-ID, z.B. "CT-1011 Schere"
function CHAR:GetFullName()
    return symchars.utils.BuildDisplayName(self)
end

function CHAR:ToTable(options)
    local copy = {}
    for k, v in pairs(self) do
        if not (options and options.excludeHistory and (k == "history" or k == "_historyLoaded")) and string.sub(k, 1, 1) ~= "_" then
            copy[k] = v
        end
    end
    return copy
end

function C.Meta() return CHAR end

function C.Create(data)
    data = data or {}
    data.data = istable(data.data) and data.data or {}
    data.trainings = istable(data.trainings) and data.trainings or {}
    local id = tonumber(data.charID)
    if id then data.charID = id end

    local existing = id and C.loaded[id]
    if existing then
        for k in pairs(existing) do
            if data[k] == nil and (k == "history" or k == "_historyLoaded" or string.sub(k, 1, 1) == "_") then
                data[k] = existing[k]
            end
        end
    end

    local char = setmetatable(data, CHAR)
    if id then C.loaded[id] = char end
    return char
end

function C.Register(char)
    if char and char.charID then C.loaded[char.charID] = char end
    return char
end

function C.Get(id)
    if id == nil then return nil end
    return C.loaded[tonumber(id) or id]
end

function C.All() return C.loaded end

-- Alle aktiven Charaktere eines Spielers (SteamID64), sortiert nach ID
function C.GetByOwner(steamid)
    local out = {}
    steamid = tostring(steamid or "")
    for _, char in pairs(C.loaded) do
        if char:IsActive() and tostring(char.charUser) == steamid then out[#out + 1] = char end
    end
    table.sort(out, function(a, b) return a.charID < b.charID end)
    return out
end

-- Alle aktiven Charaktere einer Einheit (optional inkl. Untereinheiten)
function C.GetMembers(faction, includeSub)
    local root = symchars.factions.Get(faction)
    local out = {}
    if not root then return out end
    for _, char in pairs(C.loaded) do
        if char:IsActive() and char.faction then
            if char.faction == root.uniqueID or (includeSub and symchars.factions.IsDescendant(char.faction, root)) then
                out[#out + 1] = char
            end
        end
    end
    return out
end

---------------------------------------------------------------------------------------------------------------
-- Spieler
---------------------------------------------------------------------------------------------------------------
local PLAYER = FindMetaTable("Player")

function PLAYER:GetCharacter()
    local id = self:GetNW2Int("symchars_charid", 0)
    if id == 0 then return nil end
    return C.loaded[id]
end

function PLAYER:GetCharacterID()
    local id = self:GetNW2Int("symchars_charid", 0)
    return id ~= 0 and id or nil
end

---------------------------------------------------------------------------------------------------------------
-- Client-Sync
---------------------------------------------------------------------------------------------------------------
if CLIENT then
    local function Changed(char)
        hook.Run("symchars_char_updated", char)
    end

    symchars.net.Receive("chars_full", function(data)
        if not istable(data) then return end
        local keep = {}
        for _, raw in pairs(data) do
            if istable(raw) and raw.charID then
                local char = C.Create(raw)
                keep[char.charID] = true
            end
        end
        for id in pairs(C.loaded) do
            if not keep[id] then C.loaded[id] = nil end
        end
        C._synced = true
        hook.Run("symchars_chars_synced")
    end)

    symchars.net.Receive("char", function(raw)
        if not istable(raw) or not raw.charID then return end
        Changed(C.Create(raw))
    end)

    symchars.net.Receive("char_removed", function(data)
        local id = tonumber(istable(data) and data.id)
        if not id then return end
        C.loaded[id] = nil
        hook.Run("symchars_char_updated", nil, id)
    end)
end
