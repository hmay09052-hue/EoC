--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Einheiten (Fraktionen) mit Untereinheiten

    Felder einer Einheit:
        uniqueID, name, short, description, subfaction_of (Obereinheit), color, job,
        logo (Imgur), banner (Imgur), icon (alt), model (Beispielmodell), sort,
        isDefault (Starteinheit bei Charaktererstellung), isJoinable (frei beitretbar),
        startGroups (Usergroups fuer Start, leer = alle), lockedText, hidden,
        nationalities (erlaubte Nationalitaeten, leer = alle),
        ranks = { { name, short, color, icon, job, max, flags, extras = { health, armor, speed, model, weapons } } }

    Rang-Flags: admin (Einheitsleitung), promotions (befoerdern), invite (aufnehmen), kick (entlassen),
                transfer (versetzen), docs (Dokumente verwalten). Alt: member = invite + kick + transfer.
                promotions/invite/kick/transfer gelten zusaetzlich automatisch ab einem Rang (rightsFrom / Einstellungen).
                Fortbildungen eintragen: nur Admins und wer die Fortbildung "Fortbildungs-Freigabe" hat.
                Geteilte Flags fuer andere Einheiten: "<einheitid>_<flag>"
-------------------------------------------------------------------------------------------------------------]]

symchars.factions = symchars.factions or {}
symchars.factions.loaded = symchars.factions.loaded or {}

local F = symchars.factions
local U = symchars.util

F.FLAGS = {
    { id = "admin", name = "Einheitsleitung", desc = "Alle Rechte in der Einheit und ihren Untereinheiten" },
    { id = "promotions", name = "Befördern", desc = "Befördern, Degradieren und Rang setzen" },
    { id = "invite", name = "Aufnehmen", desc = "Spieler in die Einheit einladen" },
    { id = "kick", name = "Entlassen", desc = "Mitglieder aus der Einheit entlassen" },
    { id = "transfer", name = "Versetzen", desc = "Mitglieder in andere Einheiten versetzen" },
    { id = "docs", name = "Dokumente", desc = "Dokumente der Einheit verwalten" },
}

-- Rechte, die automatisch ab einem Rang gelten (Einstellungen > Rechte bzw. pro Einheit im Editor)
F.RANK_RIGHTS = { "promotions", "invite", "kick", "transfer" }

-- alte Flags: "trainer" ohne Wirkung, "member" = Aufnehmen + Entlassen + Versetzen
F.LEGACY_FLAGS = { member = { "invite", "kick", "transfer" }, trainer = {} }

local VALID_FLAGS = { trainer = true, member = true }
for _, f in ipairs(F.FLAGS) do VALID_FLAGS[f.id] = true end

F.RANK_EXTRA_LIMITS = {
    health = { default = 0, min = 0, max = 1000 },
    armor = { default = 0, min = 0, max = 1000 },
    speed = { default = 0, min = -250, max = 250 },
}

---------------------------------------------------------------------------------------------------------------
-- Meta
---------------------------------------------------------------------------------------------------------------
local FACTION = {}
FACTION.__index = FACTION
FACTION.__type = "symchars.faction"

function FACTION:GetID() return self.uniqueID end
function FACTION:GetName() return self.name end
function FACTION:GetShort() return self.short end
function FACTION:GetShortName() return self.short end
function FACTION:GetDescription() return tostring(self.description or "") end
function FACTION:GetColor() return self.color or Color(255, 255, 255) end
function FACTION:GetIcon() return self.icon end
function FACTION:GetLogo() return self.logo ~= "" and self.logo or self.icon end
function FACTION:GetBanner() return self.banner end
function FACTION:GetJob() return self.job end
function FACTION:IsDefault() return self.isDefault == true end
function FACTION:IsJoinable() return self.isJoinable == true end
function FACTION:GetRanks() return self.ranks or {} end
function FACTION:GetRank(n) if not n then return nil end return (self.ranks or {})[tonumber(n)] end
function FACTION:GetRankExtras(n) return F.GetRankExtras(self:GetRank(n)) end
function FACTION:GetParent() return F.GetParent(self) end
function FACTION:GetParentID() return F.GetParentID(self) end
function FACTION:GetRoot() return F.GetRoot(self) end

function FACTION:GetModel()
    if U.Trim(self.model) ~= "" then return self.model end
    local first = U.FirstModel(self.job)
    return first or "models/player/kleiner.mdl"
end

function FACTION:ToTable()
    local copy = {}
    for k, v in pairs(self) do copy[k] = v end
    return copy
end

function F.Meta() return FACTION end

---------------------------------------------------------------------------------------------------------------
-- Normalisierung
---------------------------------------------------------------------------------------------------------------
function F.NormalizeID(value) return U.Lower(value) end
function F.SanitizeID(value) return U.ID(value) end

function F.IsValidID(value)
    local id = U.Lower(value)
    return id ~= "" and string.match(id, "^[a-z0-9][a-z0-9_%-]*$") ~= nil
end

function F.NormalizeParentID(value)
    local id = U.Lower(value)
    if id == "" or id == "none" then return "" end
    return id
end

function F.NormalizeFlags(flags)
    local out, seen = {}, {}
    if isstring(flags) then flags = string.Explode(",", flags) end
    if not istable(flags) then return out end
    for _, flag in ipairs(flags) do
        flag = U.Lower(flag)
        if flag ~= "" and not seen[flag] then
            seen[flag] = true
            out[#out + 1] = flag
        end
    end
    return out
end

function F.IsValidRankFlag(flag)
    flag = U.Lower(flag)
    if VALID_FLAGS[flag] then return true end
    local factionID, suffix = string.match(flag, "^([a-z0-9_%-]+)_([a-z]+)$")
    return factionID ~= nil and VALID_FLAGS[suffix] == true
end

function F.NormalizeRankMax(value)
    return U.Int(value, 0, 0, 100000)
end

function F.GetRankMax(rank)
    if not istable(rank) then return 0 end
    return F.NormalizeRankMax(rank.max)
end

function F.NormalizeRankExtras(extras)
    extras = istable(extras) and extras or {}
    local function num(key)
        local lim = F.RANK_EXTRA_LIMITS[key]
        return U.Int(extras[key], lim.default, lim.min, lim.max)
    end
    local model = U.Trim(extras.model)
    if model ~= "" and not string.match(string.lower(model), "^models/.+%.mdl$") then model = "" end
    return {
        health = num("health"),
        armor = num("armor"),
        speed = num("speed"),
        model = model,
        weapons = U.StringList(extras.weapons, 64, 96),
    }
end

function F.GetRankExtras(rank)
    if not istable(rank) then return F.NormalizeRankExtras() end
    return F.NormalizeRankExtras(rank.extras)
end

local function OrderedRanks(ranks)
    local ordered = {}
    if not istable(ranks) then return ordered end
    if #ranks > 0 then
        for i = 1, #ranks do ordered[#ordered + 1] = ranks[i] end
        return ordered
    end
    local keys = {}
    for key in pairs(ranks) do
        local idx = tonumber(key)
        if idx then keys[#keys + 1] = idx end
    end
    table.sort(keys)
    for _, k in ipairs(keys) do ordered[#ordered + 1] = ranks[k] or ranks[tostring(k)] end
    return ordered
end

function F.Normalize(data)
    data = istable(data) and data or {}
    local out = {}
    out.uniqueID = U.Lower(data.uniqueID or data.id or "")
    out.name = U.Clean(data.name, 64)
    if out.name == "" then out.name = out.uniqueID end
    out.short = U.Clean(data.short, 16)
    out.description = U.Clean(data.description, 2000, true)
    out.subfaction_of = F.NormalizeParentID(data.subfaction_of)
    out.color = U.TableToColor(data.color, Color(200, 200, 200))
    out.icon = U.Trim(data.icon)
    out.logo = U.ImageURL(data.logo)
    out.banner = U.ImageURL(data.banner)
    out.model = U.Trim(data.model)
    if out.model ~= "" and not string.match(string.lower(out.model), "^models/.+%.mdl$") then out.model = "" end
    out.job = U.Trim(data.job)
    out.sort = U.Int(data.sort, 0, -1000, 1000)
    out.isDefault = data.isDefault == true
    out.isJoinable = data.isJoinable == true
    out.hidden = data.hidden == true
    out.startGroups = U.StringList(data.startGroups, 32, 32)
    out.lockedText = U.Clean(data.lockedText, 160)
    out.nationalities = U.IDList(data.nationalities, 20)
    -- Rechte ab Rang: 0 = Standard aus den Einstellungen, -1 = niemand (nur angehakte Rang-Rechte), n = ab Rang n
    out.rightsFrom = {}
    local rf = istable(data.rightsFrom) and data.rightsFrom or {}
    for _, flag in ipairs(F.RANK_RIGHTS) do out.rightsFrom[flag] = U.Int(rf[flag], 0, -1, 64) end
    out.ranks = {}

    for _, rank in ipairs(OrderedRanks(data.ranks)) do
        if istable(rank) then
            local name = U.Clean(rank.name, 48)
            if name == "" then name = "Rekrut" end
            out.ranks[#out.ranks + 1] = {
                name = name,
                short = U.Clean(rank.short, 12),
                color = U.TableToColor(rank.color, out.color),
                icon = U.Trim(rank.icon),
                job = U.Trim(rank.job),
                flags = F.NormalizeFlags(rank.flags),
                max = F.NormalizeRankMax(rank.max),
                extras = F.NormalizeRankExtras(rank.extras),
            }
        end
        if #out.ranks >= 64 then break end
    end

    if #out.ranks == 0 then
        out.ranks[1] = { name = "Rekrut", short = "REK", color = out.color, icon = "", job = "", flags = {}, max = 0, extras = F.NormalizeRankExtras() }
    end

    return out
end

function F.ToSaveTable(faction)
    if not faction then return nil end
    local out = {
        uniqueID = faction.uniqueID, name = faction.name, short = faction.short, description = faction.description,
        subfaction_of = faction.subfaction_of, color = U.ColorToTable(faction.color), icon = faction.icon,
        logo = faction.logo, banner = faction.banner, model = faction.model, job = faction.job, sort = faction.sort,
        isDefault = faction.isDefault == true, isJoinable = faction.isJoinable == true, hidden = faction.hidden == true,
        startGroups = faction.startGroups or {}, lockedText = faction.lockedText or "",
        nationalities = faction.nationalities or {}, rightsFrom = table.Copy(faction.rightsFrom or {}), ranks = {},
    }
    for i, rank in ipairs(faction.ranks or {}) do
        out.ranks[i] = {
            name = rank.name, short = rank.short, color = U.ColorToTable(rank.color), icon = rank.icon, job = rank.job,
            flags = rank.flags, max = F.GetRankMax(rank), extras = F.GetRankExtras(rank),
        }
    end
    return out
end

function F.Create(data)
    local faction = setmetatable(data, FACTION)
    if faction.uniqueID and faction.uniqueID ~= "" then
        F.loaded[faction.uniqueID] = faction
    end
    return faction
end

function F.Register(faction)
    if not faction or not faction.uniqueID then return end
    F.loaded[faction.uniqueID] = faction
    return faction
end

function F.Get(id)
    if id == nil then return nil end
    if istable(id) then return id end
    return F.loaded[id]
end

function F.All() return F.loaded end

---------------------------------------------------------------------------------------------------------------
-- Hierarchie
---------------------------------------------------------------------------------------------------------------
function F.GetParentID(faction)
    faction = F.Get(faction)
    if not faction then return "" end
    return F.NormalizeParentID(faction.subfaction_of)
end

function F.GetParent(faction)
    local pid = F.GetParentID(faction)
    if pid == "" then return nil end
    return F.Get(pid)
end

-- Liste der Vorfahren (naechster zuerst)
function F.GetAncestors(faction)
    local out, seen = {}, {}
    local cur = F.GetParent(faction)
    while cur and not seen[cur.uniqueID] do
        seen[cur.uniqueID] = true
        out[#out + 1] = cur
        cur = F.GetParent(cur)
    end
    return out
end

function F.GetRoot(faction)
    faction = F.Get(faction)
    if not faction then return nil end
    local anc = F.GetAncestors(faction)
    return anc[#anc] or faction
end

function F.GetDepth(faction)
    return #F.GetAncestors(faction)
end

function F.IsDescendant(child, ancestor)
    child, ancestor = F.Get(child), F.Get(ancestor)
    if not child or not ancestor then return false end
    for _, a in ipairs(F.GetAncestors(child)) do
        if a.uniqueID == ancestor.uniqueID then return true end
    end
    return false
end

-- gleich oder darunter
function F.IsInTree(child, root)
    child, root = F.Get(child), F.Get(root)
    if not child or not root then return false end
    return child.uniqueID == root.uniqueID or F.IsDescendant(child, root)
end

local function SortFactions(list)
    table.sort(list, function(a, b)
        if (a.sort or 0) ~= (b.sort or 0) then return (a.sort or 0) < (b.sort or 0) end
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)
    return list
end
F.Sort = SortFactions

function F.GetChildren(faction)
    faction = F.Get(faction)
    local out = {}
    if not faction then return out end
    for _, f in pairs(F.loaded) do
        if F.NormalizeParentID(f.subfaction_of) == faction.uniqueID and f.uniqueID ~= faction.uniqueID then
            out[#out + 1] = f
        end
    end
    return SortFactions(out)
end

-- alle Nachfahren als flache Liste mit Tiefe { data, depth }
function F.GetDescendants(faction)
    local out, seen = {}, {}
    local function walk(f, depth)
        for _, child in ipairs(F.GetChildren(f)) do
            if not seen[child.uniqueID] then
                seen[child.uniqueID] = true
                out[#out + 1] = { data = child, depth = depth }
                walk(child, depth + 1)
            end
        end
    end
    walk(faction, 1)
    return out
end

function F.GetRoots()
    local out = {}
    for _, f in pairs(F.loaded) do
        local pid = F.NormalizeParentID(f.subfaction_of)
        if pid == "" or pid == f.uniqueID or not F.loaded[pid] then
            out[#out + 1] = f
        end
    end
    return SortFactions(out)
end

-- Flache Liste aller Einheiten in Baumreihenfolge { id, depth, data, label, pathLabel }
function F.GetHierarchyList(options)
    options = options or {}
    local out, visited = {}, {}
    local exclude = {}
    if options.excludeID then exclude[U.Lower(options.excludeID)] = true end

    local function add(f, depth)
        if visited[f.uniqueID] or exclude[f.uniqueID] then return end
        visited[f.uniqueID] = true
        out[#out + 1] = { id = f.uniqueID, depth = depth, data = f, label = F.GetSimpleDisplayName(f), pathLabel = F.GetDisplayName(f) }
        for _, child in ipairs(F.GetChildren(f)) do add(child, depth + 1) end
    end

    for _, root in ipairs(F.GetRoots()) do add(root, 0) end
    for _, f in pairs(F.loaded) do
        if not visited[f.uniqueID] then add(f, 0) end
    end
    return out
end

function F.WouldCreateParentCycle(uniqueID, parentID)
    uniqueID, parentID = U.Lower(uniqueID), F.NormalizeParentID(parentID)
    if uniqueID == "" or parentID == "" then return false end
    if uniqueID == parentID then return true end
    local seen, cur = {}, parentID
    while cur ~= "" do
        if seen[cur] or cur == uniqueID then return true end
        seen[cur] = true
        local f = F.Get(cur)
        if not f then break end
        cur = F.NormalizeParentID(f.subfaction_of)
    end
    return false
end

function F.GetSimpleDisplayName(faction)
    faction = F.Get(faction)
    if not faction then return "" end
    return tostring(faction.name or faction.uniqueID or "")
end

function F.GetDisplayName(faction, options)
    faction = F.Get(faction)
    if not faction then return "" end
    if options and options.includeHierarchy == false then return F.GetSimpleDisplayName(faction) end
    local parts = { F.GetSimpleDisplayName(faction) }
    for _, a in ipairs(F.GetAncestors(faction)) do table.insert(parts, 1, F.GetSimpleDisplayName(a)) end
    return table.concat(parts, " / ")
end

function F.FindDefault()
    for id, f in pairs(F.loaded) do
        if f.isDefault then return id, f end
    end
end

function F.FindFallback(excludeID)
    excludeID = U.Lower(excludeID)
    local designated = F.NormalizeParentID(symchars.Config("designateddefaultfaction"))
    if designated ~= "" and designated ~= excludeID and F.Get(designated) then
        return designated, F.Get(designated)
    end
    local excluded = excludeID ~= "" and F.Get(excludeID) or nil
    local parent = excluded and F.GetParent(excluded)
    if parent and parent.uniqueID ~= excludeID then return parent.uniqueID, parent end
    for id, f in pairs(F.loaded) do
        if id ~= excludeID and f.isDefault then return id, f end
    end
    for id, f in pairs(F.loaded) do
        if id ~= excludeID then return id, f end
    end
end

function F.JobExists(command)
    return U.GetJob(command) ~= nil
end

---------------------------------------------------------------------------------------------------------------
-- Rechte ab Rang
---------------------------------------------------------------------------------------------------------------
-- Rang über den Namen finden. names = "Sergeant" oder "Sergeant, Feldwebel" (erster Treffer zählt).
-- Reihenfolge: genauer Name, Kürzel, dann niedrigster Rang, der den Namen enthält.
function F.FindRankByName(faction, names)
    faction = F.Get(faction)
    if not faction then return nil end
    local ranks = faction.ranks or {}
    for _, name in ipairs(string.Explode(",", tostring(names or ""))) do
        name = string.lower(U.Trim(name))
        if name ~= "" then
            for i, r in ipairs(ranks) do if string.lower(U.Trim(r.name)) == name then return i end end
            for i, r in ipairs(ranks) do if string.lower(U.Trim(r.short)) == name then return i end end
            for i, r in ipairs(ranks) do if string.find(string.lower(tostring(r.name)), name, 1, true) then return i end end
        end
    end
    return nil
end

-- Ab welchem Rang gilt ein Recht in dieser Einheit? nil = für keinen Rang automatisch
function F.RightThreshold(faction, flag)
    faction = F.Get(faction)
    if not faction then return nil end
    local v = faction.rightsFrom and tonumber(faction.rightsFrom[flag]) or 0
    if v == -1 then return nil end
    if v >= 1 then return v <= #(faction.ranks or {}) and v or nil end
    return F.FindRankByName(faction, symchars.Config("right" .. flag) or "")
end

-- Darf der Spieler mit dieser Einheit starten? (nationality optional)
function F.CanStartIn(ply, faction, nationality)
    faction = F.Get(faction)
    if not faction or not faction.isDefault then return false end
    if nationality and not symchars.utils.NationalityAllowsUnit(nationality, faction) then return false end
    local groups = faction.startGroups or {}
    if #groups == 0 then return true end
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    local group = ply:GetUserGroup()
    for _, g in ipairs(groups) do
        if g == group then return true end
    end
    return false
end

---------------------------------------------------------------------------------------------------------------
-- Validierung (Editor)
---------------------------------------------------------------------------------------------------------------
function F.Validate(data, previousID)
    local issues = {}
    local function add(text) issues[#issues + 1] = text end
    previousID = U.Lower(previousID)
    local id = U.Lower(data.uniqueID)
    local parent = F.NormalizeParentID(data.subfaction_of)

    if id == "" then
        add("Die Einheit braucht eine ID.")
    elseif id ~= previousID and not F.IsValidID(id) then
        add("Die ID darf nur a-z, 0-9, _ und - enthalten.")
    elseif id ~= previousID and F.Get(id) then
        add("Die ID '" .. id .. "' ist bereits vergeben.")
    end

    if U.Trim(data.name) == "" then add("Die Einheit braucht einen Namen.") end

    if parent ~= "" then
        if parent == id or parent == previousID then
            add("Eine Einheit kann nicht ihre eigene Obereinheit sein.")
        elseif not F.Get(parent) then
            add("Die Obereinheit existiert nicht.")
        elseif F.WouldCreateParentCycle(id, parent) or (previousID ~= "" and F.WouldCreateParentCycle(previousID, parent)) then
            add("Diese Obereinheit würde eine Schleife erzeugen.")
        end
    end

    if U.Trim(data.job) == "" then
        add("Die Einheit braucht einen DarkRP-Job.")
    elseif not F.JobExists(data.job) then
        add("Der Job '" .. tostring(data.job) .. "' existiert nicht.")
    end

    local ranks = OrderedRanks(data.ranks)
    if #ranks == 0 then add("Die Einheit braucht mindestens einen Rang.") end
    for i, rank in ipairs(ranks) do
        if U.Trim(rank.name) == "" then add("Rang " .. i .. " braucht einen Namen.") end
        if U.Trim(rank.job) ~= "" and not F.JobExists(rank.job) then add("Rang " .. i .. ": Job '" .. tostring(rank.job) .. "' existiert nicht.") end
        for _, flag in ipairs(F.NormalizeFlags(rank.flags)) do
            if not F.IsValidRankFlag(flag) then add("Rang " .. i .. ": ungültiges Recht '" .. flag .. "'.") end
        end
    end

    return #issues == 0, issues
end

---------------------------------------------------------------------------------------------------------------
-- Sync
---------------------------------------------------------------------------------------------------------------
function F.ApplySync(data)
    F.loaded = {}
    for id, fac in pairs(data or {}) do
        if istable(fac) then
            fac.uniqueID = fac.uniqueID or id
            F.Create(F.Normalize(fac))
        end
    end
    F._synced = true
    hook.Run("symchars_factions_synced")
end

if CLIENT then
    symchars.net.Receive("factions", function(data)
        F.ApplySync(data)
    end)
end
