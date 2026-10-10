--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Gemeinsame Logik (Server + Client)
    Sicherheitsstufen, Job-Pruefung und Zugriff auf die einzelnen Bereiche.
    Der Server prueft alles noch einmal selbst, der Client nutzt das nur fuer die Anzeige.
-------------------------------------------------------------------------------------------------------------]]

GAR_DP = GAR_DP or {}
GAR_DP.version = "1.0.0"
GAR_DP.WEAPON = "gar_datapad"
GAR_DP.manual = GAR_DP.manual or {}     -- [charID] = { level, by, at }  (von Hand vergebene Stufen)

local CFG = GAR_DP.Config

---------------------------------------------------------------------------------------------------------------
-- Kleine Helfer
---------------------------------------------------------------------------------------------------------------
local function Lower(v) return string.lower(tostring(v or "")) end

local function ListToSet(list)
    local set = {}
    for _, v in ipairs(list or {}) do set[Lower(v)] = true end
    return set
end

local shockSet

function GAR_DP.ById(list, id)
    for _, v in ipairs(list or {}) do
        if v.id == id then return v end
    end
end

function GAR_DP.LevelData(level)
    level = math.Clamp(tonumber(level) or 1, 1, 6)
    local data = CFG.Levels[level] or {}
    return { level = level, name = data.name or ("Stufe " .. level), color = data.color or Color(200, 200, 200) }
end

function GAR_DP.Char(ply)
    if not IsValid(ply) or not ply.GetCharacter then return nil end
    return ply:GetCharacter()
end

function GAR_DP.JobOf(ply)
    if not IsValid(ply) then return "", "" end
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    if job then return Lower(job.command), Lower(job.name) end
    return "", Lower(team.GetName(ply:Team()))
end

local function HasJob(ply, set)
    local cmd, name = GAR_DP.JobOf(ply)
    return set[cmd] == true or set[name] == true
end

function GAR_DP.IsShock(ply)
    shockSet = shockSet or ListToSet(CFG.ShockJobs)
    return HasJob(ply, shockSet)
end

function GAR_DP.IsAdmin(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if ply:IsSuperAdmin() then return true end
    if CFG.AdminGroups[ply:GetUserGroup()] then return true end
    if CAMI and CAMI.PlayerHasAccess then
        local allowed
        CAMI.PlayerHasAccess(ply, "gar_datapad_admin", function(result) allowed = result end)
        if allowed == true then return true end
    end
    return false
end

local function RegisterPrivilege()
    if CAMI and CAMI.RegisterPrivilege then
        CAMI.RegisterPrivilege({ Name = "gar_datapad_admin", MinAccess = "superadmin", Description = "GAR Datapad: Stufe 6 und Freigaben" })
    end
end
RegisterPrivilege()
hook.Add("InitPostEntity", "gar_datapad_cami", RegisterPrivilege)

---------------------------------------------------------------------------------------------------------------
-- Sicherheitsstufen
---------------------------------------------------------------------------------------------------------------
-- Rang aus einer Regel ("Sergeant" oder 5) in eine Rangnummer der Einheit umwandeln
local function RuleRank(faction, rank)
    if isnumber(rank) then return rank end
    local wanted = Lower(rank)
    for n, data in pairs(faction and faction:GetRanks() or {}) do
        if Lower(data.name) == wanted or Lower(data.short) == wanted then return tonumber(n) end
    end
    return nil
end

local function LevelFromRules(rules, faction, rankNumber)
    local best = 0
    for _, rule in ipairs(rules or {}) do
        local need = RuleRank(faction, rule.rank)
        if need and rankNumber >= need then best = math.max(best, tonumber(rule.level) or 0) end
    end
    return best
end

-- Stufe nur aus Rang, Einheit und Job (ohne Handvergabe)
function GAR_DP.AutoClearance(char, jobCommand)
    if not char then return 1 end
    local level = 1
    local faction = char:GetFaction()
    if faction then
        local rules = CFG.ClearanceByRank
        local chain = { faction }
        if symchars.factions.GetAncestors then
            for _, anc in ipairs(symchars.factions.GetAncestors(faction)) do chain[#chain + 1] = anc end
        end
        for _, f in ipairs(chain) do
            if CFG.ClearanceByUnit[f.uniqueID] then rules = CFG.ClearanceByUnit[f.uniqueID] break end
        end
        level = math.max(level, LevelFromRules(rules, faction, char:GetRank()))
    end
    local job = Lower(jobCommand or char:GetJob())
    if CFG.ClearanceByJob[job] then level = math.max(level, CFG.ClearanceByJob[job]) end
    return math.Clamp(level, 1, 6)
end

-- Stufe eines Charakters inkl. Handvergabe (Handvergabe ersetzt die automatische Stufe)
function GAR_DP.CharClearance(char, jobCommand)
    if not char then return 1 end
    local manual = GAR_DP.manual[char:GetID()]
    if manual and tonumber(manual.level) and manual.level > 0 then return math.Clamp(manual.level, 1, 6) end
    return GAR_DP.AutoClearance(char, jobCommand)
end

function GAR_DP.Clearance(ply)
    if not IsValid(ply) then return 0 end
    if GAR_DP.IsAdmin(ply) then return 6 end
    local char = GAR_DP.Char(ply)
    if not char then return 0 end
    return GAR_DP.CharClearance(char, (GAR_DP.JobOf(ply)))
end

---------------------------------------------------------------------------------------------------------------
-- Zugriff auf Bereiche: gibt ok, Grund zurueck
---------------------------------------------------------------------------------------------------------------
GAR_DP.Access = {
    personnel = function(ply)
        return GAR_DP.Char(ply) ~= nil, "Kein Charakter"
    end,
    penal = function(ply)
        if GAR_DP.IsShock(ply) then return true end
        if CFG.PenalAdminAccess and GAR_DP.IsAdmin(ply) then return true end
        return false, "Nur Schocktruppen"
    end,
    reports = function(ply)
        return GAR_DP.Char(ply) ~= nil, "Kein Charakter"
    end,
    classified = function(ply)
        return GAR_DP.Char(ply) ~= nil, "Kein Charakter"
    end,
    galaxy = function()
        return true
    end,
    clearance = function(ply)
        if GAR_DP.IsAdmin(ply) or GAR_DP.Clearance(ply) >= CFG.GrantMinLevel then return true end
        return false, "Ab Stufe " .. CFG.GrantMinLevel
    end,
}

function GAR_DP.CanUse(ply, app)
    local fn = GAR_DP.Access[app]
    if not fn then return false, "Unbekannt" end
    local ok, reason = fn(ply)
    return ok == true, reason
end

-- Darf ply die Personalakte von targetChar sehen?
function GAR_DP.CanViewPersonnel(ply, targetChar)
    if not targetChar then return false end
    if GAR_DP.IsAdmin(ply) then return true end
    local own = GAR_DP.Char(ply)
    if not own then return false end
    if own:GetID() == targetChar:GetID() then return true end
    local level = GAR_DP.Clearance(ply)
    if level >= CFG.PersonnelAllLevel then return true end
    if level >= CFG.PersonnelUnitLevel then
        local a, b = own:GetFaction(), targetChar:GetFaction()
        if a and b then
            local ra, rb = symchars.factions.GetRoot(a), symchars.factions.GetRoot(b)
            return ra ~= nil and rb ~= nil and ra.uniqueID == rb.uniqueID
        end
    end
    return false
end

-- Darf ply Vermerke in die Personalakte von targetChar schreiben?
function GAR_DP.CanWritePersonnel(ply, targetChar)
    if not targetChar then return false end
    if GAR_DP.IsAdmin(ply) then return true end
    local own = GAR_DP.Char(ply)
    if not own or own:GetID() == targetChar:GetID() then return false end
    if not GAR_DP.CanViewPersonnel(ply, targetChar) then return false end
    if GAR_DP.Clearance(ply) >= CFG.PersonnelWriteLevel then return true end
    if symchars.authority and symchars.authority.CanActOn then
        return symchars.authority.CanActOn(own, targetChar, "promotions") == true
    end
    return false
end

-- Hoechste Stufe, die ply von Hand vergeben darf (0 = gar nicht)
function GAR_DP.MaxGrant(ply)
    if GAR_DP.IsAdmin(ply) then return 6 end
    local level = GAR_DP.Clearance(ply)
    if level >= CFG.GrantMinLevel then return level end
    return 0
end

function GAR_DP.FormatDate(ts, withTime)
    ts = tonumber(ts) or 0
    if ts <= 0 then return "-" end
    return os.date(withTime and "%d.%m.%Y %H:%M" or "%d.%m.%Y", ts)
end
