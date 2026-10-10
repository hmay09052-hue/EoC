--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Befehlsgewalt innerhalb der Einheiten

    Ein Charakter hat ein Recht (Flag) über eine Einheit, wenn:
      - er in dieser Einheit ist und sein Rang das Flag (oder "admin") hat
        oder sein Rang mindestens der Rang ist, ab dem das Recht in seiner Einheit automatisch gilt
        (z.B. Befördern ab Sergeant, Aufnehmen ab Corporal – Einstellungen > Rechte bzw. Einheiten-Editor)
      - er in einer übergeordneten Einheit ist und eine der beiden Bedingungen dort erfüllt
      - sein Rang das geteilte Flag "<einheit>_<flag>" für diese Einheit oder eine Obereinheit hat
-------------------------------------------------------------------------------------------------------------]]

symchars.authority = symchars.authority or {}

local A = symchars.authority
local F = symchars.factions
local U = symchars.util

local function RankFlags(char)
    local rank = char and char:GetRankData()
    return rank and rank.flags or {}
end

-- Hat die Flag-Liste das Recht? (inkl. alter Flags wie "member", prefix = "<einheit>_" für geteilte Rechte)
local function ListHas(flags, flag, prefix)
    prefix = prefix or ""
    if U.InList(flags, prefix .. flag) or U.InList(flags, prefix .. "admin") then return true end
    for legacy, covers in pairs(F.LEGACY_FLAGS or {}) do
        if U.InList(covers, flag) and U.InList(flags, prefix .. legacy) then return true end
    end
    return false
end
A.ListHas = ListHas

-- Gilt das Recht für den Rang des Charakters automatisch (Rang-Schwelle in seiner Einheit)?
function A.RankThresholdMet(char, flag)
    local own = char and char:GetFaction()
    if not own then return false end
    local from = F.RightThreshold(own, flag)
    return from ~= nil and char:GetRank() >= from
end

-- Gibt zurück: hatRecht, art ("same" | "parent" | "shared"), nurUeberRang
function A.HasFlag(char, factionID, flag)
    if not char then return false end
    local target = F.Get(factionID)
    local own = char:GetFaction()
    if not target or not own then return false end

    local flags = RankFlags(char)
    local explicit = ListHas(flags, flag)
    local byRank = not explicit and A.RankThresholdMet(char, flag)

    if explicit or byRank then
        if own.uniqueID == target.uniqueID then return true, "same", byRank end
        if F.IsDescendant(target, own) then return true, "parent", byRank end
    end

    local chain = { target }
    for _, anc in ipairs(F.GetAncestors(target)) do chain[#chain + 1] = anc end
    for _, f in ipairs(chain) do
        if ListHas(flags, flag, f.uniqueID .. "_") then
            return true, "shared", false
        end
    end

    return false
end

-- Darf actorChar mit Recht "flag" auf targetChar wirken?
-- requireHigher: bei gleicher Einheit muss der eigene Rang höher sein.
-- Gilt das Recht nur über die Rang-Schwelle, muss der Rang auch gegenüber Untereinheiten höher sein.
function A.CanActOn(actorChar, targetChar, flag, requireHigher)
    if not actorChar or not targetChar then return false end
    if actorChar.charID == targetChar.charID then return false end
    local targetFaction = targetChar:GetFaction()
    if not targetFaction then return false end

    local ok, kind, byRank = A.HasFlag(actorChar, targetFaction.uniqueID, flag)
    if not ok then return false end

    if requireHigher ~= false and actorChar:GetRank() <= targetChar:GetRank() then
        if kind == "same" or (kind == "parent" and byRank) then return false end
    end

    return true, kind, byRank
end

-- Einheiten, in denen der Charakter irgendein Verwaltungsrecht hat (inkl. Untereinheiten)
function A.ManagedUnits(char, flag)
    local out = {}
    if not char then return out end
    for id in pairs(F.All()) do
        if flag then
            if A.HasFlag(char, id, flag) then out[id] = true end
        else
            for _, f in ipairs(F.FLAGS) do
                if A.HasFlag(char, id, f.id) then out[id] = true break end
            end
        end
    end
    return out
end

function A.KindText(kind)
    if kind == "admin" then return "Admin" end
    if kind == "same" then return "Einheit" end
    if kind == "parent" then return "Obereinheit" end
    if kind == "shared" then return "Geteilte Rechte" end
    return ""
end
