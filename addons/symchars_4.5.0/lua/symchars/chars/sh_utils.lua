--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Charakter-Hilfsfunktionen (Namen, RP-ID, Slots)
-------------------------------------------------------------------------------------------------------------]]

symchars.utils = symchars.utils or {}

local UT = symchars.utils
local U = symchars.util

function UT.VarIsEnabled(var)
    var = tostring(var or "")
    if var == "" then return true end
    for _, v in ipairs(symchars.Config("disabledvariables") or {}) do
        if v == var then return false end
    end
    return true
end

function UT.GetEnabledDataPayload(data)
    local out = {}
    for k, v in pairs(istable(data) and data or {}) do
        if UT.VarIsEnabled(k) then out[k] = v end
    end
    return out
end

function UT.IsForbiddenName(name)
    local lower = string.lower(tostring(name or ""))
    if lower == "" then return false end
    for _, word in ipairs(symchars.Config("forbiddennames") or {}) do
        local w = string.lower(U.Trim(word))
        if w ~= "" and string.find(lower, w, 1, true) then return true, word end
    end
    return false
end

-- Prüft einen Namen. Gibt true oder false, fehlertext zurück.
function UT.ValidateName(name)
    name = U.Trim(name)
    local len = utf8.len(name) or #name
    local min, max = symchars.Config("minnamechars") or 3, symchars.Config("maxnamechars") or 24
    if len < min then return false, "Der Name ist zu kurz (mindestens " .. min .. " Zeichen)." end
    if len > max then return false, "Der Name ist zu lang (höchstens " .. max .. " Zeichen)." end
    if string.find(name, "[%c\"\\<>{}%[%]]") then return false, "Der Name enthält ungültige Zeichen." end
    if UT.IsForbiddenName(name) then return false, "Dieser Name ist nicht erlaubt." end
    return true
end

function UT.CharPlayed(id)
    id = tonumber(id)
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetNW2Int("symchars_charid", 0) == id then return true, ply end
    end
    return false
end

function UT.GetRankName(faction, rank)
    faction = symchars.factions.Get(faction)
    local r = faction and faction:GetRank(rank)
    return r and r.name or "none"
end

function UT.FindFlag(flags, flag)
    return U.InList(flags, flag)
end

---------------------------------------------------------------------------------------------------------------
-- RP-ID
---------------------------------------------------------------------------------------------------------------
-- Regel (Präfix/Länge) für einen Job und eine Einheit
function UT.GetRPIDRule(job, factionID)
    local prefix = symchars.Config("rpidprefix") or ""
    local length = symchars.Config("rpidlength") or 4
    for _, rule in ipairs(symchars.Config("rpidrules") or {}) do
        local hit = false
        if job and U.InList(rule.jobs, job) then hit = true end
        if not hit and factionID and factionID ~= "" then
            for _, unit in ipairs(rule.units or {}) do
                if unit == factionID or symchars.factions.IsDescendant(factionID, unit) then hit = true break end
            end
        end
        if hit then
            prefix, length = rule.prefix or prefix, rule.length or length
        end
    end
    return prefix, length
end

function UT.IsValidRPIDNumber(value, length)
    value = U.Trim(value)
    if not string.match(value, "^%d+$") then return false end
    return #value == length
end

function UT.BuildRoleplayID(char)
    if isnumber(char) or isstring(char) then char = symchars.chars.Get(char) end
    if not char then return "" end
    if not symchars.Config("useroleplayid") then return "" end
    local id = U.Trim(char.roleplayID)
    if id == "" or id == "none" or id == "NULL" then return "" end
    local prefix, length = UT.GetRPIDRule(char.job, char.faction)
    return prefix .. string.sub(id, 1, length)
end

-- "CT-1011 Schere"
function UT.BuildDisplayName(char)
    if isnumber(char) then char = symchars.chars.Get(char) end
    if not char then return "" end
    local rpid = UT.BuildRoleplayID(char)
    if rpid ~= "" then return rpid .. " " .. tostring(char.name or "") end
    return tostring(char.name or "")
end

-- Name für DarkRP (rpname): nur RP-ID + Name, z.B. "CT-7567 Rex" (kein Rang, keine Einheit)
function UT.BuildPlayerName(char)
    if isnumber(char) then char = symchars.chars.Get(char) end
    if not char then return end
    if symchars.Config("displayroleplayid") then
        local rpid = UT.BuildRoleplayID(char)
        if rpid ~= "" then return rpid .. " " .. tostring(char.name or "") end
    end
    return tostring(char.name or "")
end

---------------------------------------------------------------------------------------------------------------
-- Nationalität
---------------------------------------------------------------------------------------------------------------
function UT.Nationalities()
    return symchars.Config("nationalities") or {}
end

function UT.GetNationality(id)
    for _, n in ipairs(UT.Nationalities()) do
        if n.id == id then return n end
    end
    return nil
end

function UT.NationalityName(id)
    local n = UT.GetNationality(id)
    return n and n.name or tostring(id or "-")
end

-- Ist dieser Job für die Nationalität gesperrt?
function UT.NationalityBlocksJob(natId, job)
    local n = UT.GetNationality(natId)
    return n ~= nil and U.InList(n.blockedjobs, job)
end

-- Nationalität eines Charakters (nil = keine gesetzt oder Feld deaktiviert -> keine Sperren)
function UT.CharNationality(char)
    if not char or not UT.VarIsEnabled("nationality") then return nil end
    local nat = istable(char.data) and char.data.nationality or nil
    if not isstring(nat) or nat == "" then return nil end
    return nat
end

-- Darf man mit dieser Nationalität in der Einheit starten? Gibt erlaubt, grund zurück.
function UT.NationalityAllowsUnit(natId, unit)
    unit = symchars.factions.Get(unit)
    if not unit or not natId or natId == "" then return true end
    local allowed = unit.nationalities or {}
    if #allowed > 0 and not U.InList(allowed, natId) then
        return false, "Nicht für " .. UT.NationalityName(natId)
    end
    local job = unit.job
    local r1 = unit:GetRank(1)
    if r1 and U.Trim(r1.job) ~= "" then job = r1.job end
    if UT.NationalityBlocksJob(natId, job) or UT.NationalityBlocksJob(natId, unit.job) then
        return false, "Nicht für " .. UT.NationalityName(natId)
    end
    return true
end

---------------------------------------------------------------------------------------------------------------
-- Slots
---------------------------------------------------------------------------------------------------------------
function UT.GetSlots(ply)
    local slots = symchars.Config("slotsdefault") or 1
    if IsValid(ply) then
        local group = ply:GetUserGroup()
        for g, count in pairs(symchars.Config("slotsbygroup") or {}) do
            if g == group and count > slots then slots = count end
        end
        if ply:IsSuperAdmin() then
            local sa = (symchars.Config("slotsbygroup") or {}).superadmin
            if sa and sa > slots then slots = sa end
        end
    end
    return math.max(1, slots)
end

---------------------------------------------------------------------------------------------------------------
-- Suche
---------------------------------------------------------------------------------------------------------------
local function Normalize(s)
    s = string.lower(U.Trim(s))
    s = string.gsub(s, "[%p%c%s]", "")
    return s
end

-- Sucht einen online gespielten Charakter nach Name oder RP-ID
function UT.FindCharByName(search)
    search = U.Trim(search)
    if search == "" then return nil end
    local needle = Normalize(search)
    local best, bestPly, bestScore = nil, nil, math.huge

    for _, ply in ipairs(player.GetAll()) do
        local char = ply:GetCharacter()
        if char then
            for _, candidate in ipairs({ char.name or "", UT.BuildDisplayName(char), UT.BuildRoleplayID(char) }) do
                local hay = Normalize(candidate)
                if hay ~= "" then
                    if hay == needle then return ply, char end
                    local s = string.find(hay, needle, 1, true)
                    if s then
                        local score = #hay - #needle
                        if score < bestScore then best, bestPly, bestScore = char, ply, score end
                    end
                end
            end
        end
    end

    return bestPly, best
end

if CLIENT then
    function symchars.confirmation(yes, no)
        symchars.ui.Confirm("Bist du sicher?", "Diese Aktion kann nicht rückgängig gemacht werden.", yes, no)
    end
end
