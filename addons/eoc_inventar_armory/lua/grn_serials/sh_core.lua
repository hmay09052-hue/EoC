GRNSerials = GRNSerials or {}
local WS = GRNSerials
local C = WS.Config

WS.STATUS = {
    STORED = "STORED",       -- Waffenkammer
    ISSUED = "ISSUED",       -- ausgegeben
    DROPPED = "DROPPED",     -- am Boden (Träger gefallen)
    CAPTURED = "CAPTURED",   -- erbeutet / vermisst
    BROKEN = "BROKEN",       -- Werkbank
    RETIRED = "RETIRED",     -- ausgemustert
}

WS.StatusLabels = {
    STORED = "In der Waffenkammer",
    ISSUED = "Ausgegeben",
    DROPPED = "Am Boden",
    CAPTURED = "Vermisst",
    BROKEN = "Werkbank",
    RETIRED = "Ausgemustert",
}

-- ---------------------------------------------------------
-- Prüfziffer (Luhn)
-- ---------------------------------------------------------
function WS.Luhn(digits)
    digits = tostring(digits or "")
    local sum, double = 0, true
    for i = #digits, 1, -1 do
        local d = tonumber(string.sub(digits, i, i)) or 0
        if double then
            d = d * 2
            if d > 9 then d = d - 9 end
        end
        sum = sum + d
        double = not double
    end
    return (10 - (sum % 10)) % 10
end

-- Prüft eine abgetippte Nummer (z. B. im RP).
function WS.IsValidSerial(serial)
    local prefix, year, body, check = string.match(tostring(serial or ""), "^(%u+)%-(%d%d)%-(%d+)%-(%d)$")
    if not prefix then return false end
    return WS.Luhn(year .. body) == tonumber(check)
end

function WS.PrefixForClass(class)
    class = string.lower(tostring(class or ""))
    for _, pair in ipairs(C.ManufacturerPrefixes or {}) do
        if string.find(class, pair[1], 1, true) then return pair[2] end
    end
    return C.DefaultPrefix or "REP"
end

function WS.ClassTracked(class)
    class = string.lower(tostring(class or ""))
    if class == "" then return false end
    for _, pat in ipairs(C.ExcludeClasses or {}) do
        if string.find(class, pat, 1, true) then return false end
    end
    local inc = C.IncludeClasses or {}
    if #inc == 0 then return true end
    for _, pat in ipairs(inc) do
        if string.find(class, pat, 1, true) then return true end
    end
    return false
end

-- ---------------------------------------------------------
-- Zustand
-- ---------------------------------------------------------
function WS.TierFor(condition)
    condition = tonumber(condition) or 100
    local tiers = C.Wear.Tiers
    local last = tiers[#tiers]
    if condition <= 0 then return last end
    for _, tier in ipairs(tiers) do
        if not tier.Blocked and (condition >= tier.Min or tier.Min <= 1) then return tier end
    end
    return last
end

function WS.GetWeaponSerial(wep)
    if not IsValid(wep) then return "" end
    return wep:GetNW2String("ws_serial", "")
end

-- ---------------------------------------------------------
-- Regiment & Rang aus dem DarkRP-Job
-- ---------------------------------------------------------
local function jobCommand(ply)
    if not IsValid(ply) then return "" end
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    return string.lower(tostring(job and job.command or ""))
end
WS.JobCommand = jobCommand

local function unitJobs()
    local inv = GRNInventory and GRNInventory.Config
    return (C.RegimentJobs) or (inv and inv.Armor and inv.Armor.UnitJobs) or {}
end

function WS.RegimentForCommand(command)
    command = string.lower(tostring(command or ""))
    if command == "" then return nil end
    local best, bestLen
    for unit, prefixes in pairs(unitJobs()) do
        for _, p in ipairs(prefixes) do
            p = string.lower(p)
            if (command == p or string.sub(command, 1, #p) == p) and (not bestLen or #p > bestLen) then
                best, bestLen = unit, #p
            end
        end
    end
    return best
end

function WS.GetRegiment(ply)
    return WS.RegimentForCommand(jobCommand(ply))
end

function WS.RegimentName(id)
    if not id then return "Ohne Regiment" end
    return (C.RegimentNames or {})[id] or tostring(id)
end

function WS.RankIndex(rank)
    for i, r in ipairs(C.RankOrder or {}) do
        if r == rank then return i end
    end
    return 0
end

function WS.GetRank(ply)
    local command = jobCommand(ply)
    local best, bestIdx = nil, 0
    for i, r in ipairs(C.RankOrder or {}) do
        local suffix = "_" .. r
        if string.sub(command, -#suffix) == suffix and #suffix > 0 then
            if i > bestIdx then best, bestIdx = r, i end
        end
    end
    return best, bestIdx
end

function WS.HasRank(ply, minRank)
    local _, idx = WS.GetRank(ply)
    return idx > 0 and idx >= WS.RankIndex(minRank)
end

function WS.IsAdmin(ply)
    return IsValid(ply) and ((C.AdminGroups or {})[ply:GetUserGroup()] == true or ply:IsSuperAdmin())
end

function WS.IsArmorer(ply)
    if not IsValid(ply) then return false end
    if (C.ArmorerUserGroups or {})[ply:GetUserGroup()] then return true end
    local command = jobCommand(ply)
    for _, p in ipairs(C.ArmorerJobs or {}) do
        p = string.lower(p)
        if command == p or string.sub(command, 1, #p) == p then return true end
    end
    return false
end

function WS.GetFaction(ent)
    if not IsValid(ent) then return "none" end
    if ent:IsNPC() or ent:IsNextBot() then
        local d = ent.Disposition and IsValid(player.GetAll()[1]) and ent:Disposition(player.GetAll()[1])
        if d == D_LI then return "republic" end
        return "npc_hostile"
    end
    if not ent:IsPlayer() then return "none" end
    if WS.GetRegiment(ent) then return "republic" end
    local job = RPExtraTeams and RPExtraTeams[ent:Team()]
    local cat = job and job.category or team.GetName(ent:Team())
    return (C.FactionOverrides or {})[cat] or tostring(cat or "none")
end

-- ---------------------------------------------------------
-- ArcCW-Adapter (Kern bleibt basis-unabhängig, siehe WS.Adapters)
-- ---------------------------------------------------------
WS.Adapters = WS.Adapters or {}

WS.Adapters.arccw = {
    Match = function(wep) return wep.ArcCW == true end,
}

function WS.AdapterFor(wep)
    if not IsValid(wep) then return nil end
    for name, a in pairs(WS.Adapters) do
        if a.Match(wep) then return a, name end
    end
end

-- ArcCW ruft für jedes "Hook_*" zusätzlich einen globalen Hook gleichen
-- Namens auf. Das funktioniert auf Server und Client gleich.
hook.Add("Hook_ModDispersion", "GRNSerials_Spread", function(wep, hip)
    if not isnumber(hip) or not IsValid(wep) then return end
    if WS.GetWeaponSerial(wep) == "" then return end
    local tier = WS.TierFor(wep:GetNW2Float("ws_cond", 100))
    if tier.Spread and tier.Spread ~= 1 then return hip * tier.Spread end
end)

hook.Add("Hook_ShouldNotFire", "GRNSerials_Blocked", function(wep)
    if not IsValid(wep) or WS.GetWeaponSerial(wep) == "" then return end
    if WS.TierFor(wep:GetNW2Float("ws_cond", 100)).Blocked then return true end
    if wep:GetNW2Bool("ws_locked", false) then return true end
end)
