--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - TAB-Menü: gemeinsame Helfer
    Liest SymChars nur aus (falls vorhanden). Nichts davon schreibt in SymChars.
-------------------------------------------------------------------------------------------------------------]]

EOCSB = EOCSB or {}

local CFG = EOCSB.Config

local function HasSymChars()
    return symchars ~= nil and symchars.factions ~= nil and symchars.chars ~= nil
end
EOCSB.HasSymChars = HasSymChars

local function UseFactions()
    if not HasSymChars() or not symchars.Config then return false end
    local ok, v = pcall(symchars.Config, "usefactions")
    return not ok or v ~= false
end

-- SymChars-Charakter des Spielers (oder nil)
function EOCSB.GetChar(ply)
    if not IsValid(ply) or not HasSymChars() or not ply.GetCharacter then return nil end
    local ok, char = pcall(ply.GetCharacter, ply)
    if ok and istable(char) and char.GetRankData then return char end
    return nil
end

-- Einheit (SymChars-Faction) des Spielers
function EOCSB.GetFaction(ply)
    if not UseFactions() then return nil end
    local char = EOCSB.GetChar(ply)
    return char and char:GetFaction() or nil
end

-- Rang-Daten ({ name, short, color, icon, ... }) und Rang-Nummer
function EOCSB.GetRank(ply)
    if not UseFactions() then return nil, 0 end
    local char = EOCSB.GetChar(ply)
    if not char then return nil, 0 end
    return char:GetRankData(), char:GetRank() or 0
end

-- "CT-1011 Schere" (SymChars) oder der normale Name
function EOCSB.GetName(ply)
    if not IsValid(ply) then return "" end
    local char = EOCSB.GetChar(ply)
    if char and symchars.utils and symchars.utils.BuildDisplayName then
        local ok, name = pcall(symchars.utils.BuildDisplayName, char)
        if ok and isstring(name) and name ~= "" then return name end
    end
    return ply:Nick()
end

---------------------------------------------------------------------------------------------------------------
-- Rangtafel (Config: RankBranches)
---------------------------------------------------------------------------------------------------------------
local branches
local function Branches()
    if branches then return branches end
    branches = {}
    for _, br in ipairs(CFG.RankBranches or {}) do
        local b = { def = br, byName = {}, search = {} }
        for i, r in ipairs(br.ranks or {}) do
            local entry = { name = r[1], color = r[2], index = i, branch = b }
            for k = 1, #r do
                if isstring(r[k]) then
                    local alias = string.lower(r[k])
                    b.byName[alias] = entry
                    b.search[#b.search + 1] = { alias, entry }
                end
            end
        end
        -- längste Namen zuerst, damit "Lieutenant Commander" nicht als "Commander" erkannt wird
        table.sort(b.search, function(x, y) return #x[1] > #y[1] end)
        branches[#branches + 1] = b
    end
    return branches
end

-- Navy-Spieler zuerst gegen die Navy-Ränge prüfen (Captain/Commander/Lieutenant gibt es in beiden)
local function BranchOrder(ply)
    local list = Branches()
    local f = EOCSB.GetFaction(ply)
    local text = string.lower((team.GetName(ply:Team()) or "") .. " " .. (f and f.name or "") .. " " .. (f and f.uniqueID or ""))
    if f and symchars.factions.GetRoot then
        local root = symchars.factions.GetRoot(f)
        if root then text = text .. " " .. string.lower(root.name or "") end
    end
    local first, rest = {}, {}
    for _, b in ipairs(list) do
        local hit = false
        for _, m in ipairs(b.def.match or {}) do
            if string.find(text, string.lower(m), 1, true) then hit = true break end
        end
        if hit then first[#first + 1] = b else rest[#rest + 1] = b end
    end
    for _, b in ipairs(rest) do first[#first + 1] = b end
    return first
end

local function FindRankEntry(ply)
    local symRank = EOCSB.GetRank(ply)
    local order = BranchOrder(ply)
    if symRank and symRank.name and symRank.name ~= "" then
        local key = string.lower(symRank.name)
        for _, b in ipairs(order) do
            if b.byName[key] then return b.byName[key] end
        end
        return { name = symRank.name, index = 999 }
    end
    local job = string.lower(team.GetName(ply:Team()) or "")
    for _, b in ipairs(order) do
        for _, s in ipairs(b.search) do
            if string.find(job, s[1], 1, true) then return s[2] end
        end
    end
    return nil
end

-- Rang laut Rangtafel: { name, color, index } (nil = keiner gefunden). Wird pro Spieler kurz zwischengespeichert.
function EOCSB.GetRankEntry(ply)
    if not IsValid(ply) then return nil end
    local now = CurTime()
    if ply._eocsbRankAt and now - ply._eocsbRankAt < 1 then return ply._eocsbRank end
    ply._eocsbRank = FindRankEntry(ply)
    ply._eocsbRankAt = now
    return ply._eocsbRank
end

function EOCSB.GetRankName(ply)
    local e = EOCSB.GetRankEntry(ply)
    if e then return e.name end
    return team.GetName(ply:Team()) or ""
end

function EOCSB.GetRankColor(ply)
    local e = EOCSB.GetRankEntry(ply)
    return e and e.color or nil
end

-- höher = höherer Rang (zum Sortieren)
function EOCSB.GetRankWeight(ply)
    local e = EOCSB.GetRankEntry(ply)
    if e and e.index < 999 then return 1000 - e.index end
    local _, n = EOCSB.GetRank(ply)
    return n or 0
end

local function InGroupList(ply, list)
    local ug = string.lower(ply:GetUserGroup() or "")
    for _, g in ipairs(list or {}) do
        if string.lower(g) == ug then return true end
    end
    return false
end
EOCSB.InGroupList = InGroupList

function EOCSB.IsAdmin(ply)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    return InGroupList(ply, CFG.AdminGroups)
end

function EOCSB.GetOfficerRankDef(id)
    for _, r in ipairs(CFG.OfficerRanks or {}) do
        if r.id == id then return r end
    end
end

-- Ist der Spieler in einer der Einheiten (inkl. Untereinheiten)?
function EOCSB.InUnits(ply, units)
    if not units or #units == 0 then return false end
    local f = EOCSB.GetFaction(ply)
    if not f then return false end
    for _, u in ipairs(units) do
        u = string.lower(u)
        if f.uniqueID == u or symchars.factions.IsDescendant(f, u) then return true end
    end
    return false
end

-- Hat der Spieler mindestens den Rang mit diesem Namen?
-- Zuerst laut Rangtafel (gleiche Laufbahn), sonst laut den Rängen seiner SymChars-Einheit.
function EOCSB.HasMinRank(ply, rankName)
    if not rankName or rankName == "" then return false end
    local e = EOCSB.GetRankEntry(ply)
    if e and e.branch then
        local need = e.branch.byName[string.lower(rankName)]
        if need then return e.index <= need.index end
    end
    local f = EOCSB.GetFaction(ply)
    if not f then return false end
    local _, current = EOCSB.GetRank(ply)
    local wanted = string.lower(rankName)
    for i, r in ipairs(f:GetRanks()) do
        if string.lower(r.name or "") == wanted then return current >= i end
    end
    return false
end

-- Darf der Spieler diesen Officer-Posten haben?
function EOCSB.OfficerAllowed(ply, rank)
    if not IsValid(ply) or not rank then return false end
    if not rank.minRank and not rank.units and not rank.jobs then return true end
    if rank.minRank and EOCSB.HasMinRank(ply, rank.minRank) then return true end
    if rank.units and EOCSB.InUnits(ply, rank.units) then return true end
    if rank.jobs then
        local job = team.GetName(ply:Team()) or ""
        for _, part in ipairs(rank.jobs) do
            if string.find(job, part, 1, true) then return true end
        end
    end
    return false
end

-- Zählt die Sicherheitssoldaten
function EOCSB.IsSecurity(ply)
    if EOCSB.InUnits(ply, CFG.SecurityUnits) then return true end
    local job = team.GetName(ply:Team()) or ""
    for _, part in ipairs(CFG.SecurityJobs or {}) do
        if string.find(job, part, 1, true) then return true end
    end
    return false
end
