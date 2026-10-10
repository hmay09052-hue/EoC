--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Fortbildungen / Lizenzen

    Anlegen/Bearbeiten: nur Admins (ADMIN > FORTBILDUNGEN).
    Eintragen/Entziehen (VERWALTUNG > Mitglied > Fortbildungen): Admins und jeder mit der Fortbildung
    "Fortbildungs-Freigabe" (ID in den Einstellungen). Die Freigabe selbst vergeben nur Admins.

    Definition:
        id, name, short, description, category, icon (Imgur), color, sort
        units = { einheit-ids }, includeSubunits = true     -- Gültig für (leer = alle)
        jobs  = { job-befehle }                              -- Gültig für Jobs (leer = egal)
        trainerNeedsTraining = false                         -- Ausbilder muss die Fortbildung selbst besitzen
        requires = { fortbildungs-ids }                      -- Voraussetzungen
        vehicles = { entity-klassen }                        -- Freischaltung im SSE-Fahrzeugterminal
        weapons  = { waffen-klassen }                        -- Waffen beim Spawn
        validDays = 0                                        -- Gültigkeit in Tagen (0 = unbegrenzt)
-------------------------------------------------------------------------------------------------------------]]

symchars.trainings = symchars.trainings or {}
symchars.trainings.loaded = symchars.trainings.loaded or {}

local T = symchars.trainings
local U = symchars.util
local F = symchars.factions

function T.Normalize(raw, id)
    raw = istable(raw) and raw or {}
    local out = {
        id = U.ID(id or raw.id),
        name = U.Clean(raw.name, 64),
        short = U.Clean(raw.short, 12),
        description = U.Clean(raw.description, 2000, true),
        category = U.Clean(raw.category, 32),
        icon = U.ImageURL(raw.icon),
        color = U.TableToColor(raw.color, Color(252, 178, 73)),
        sort = U.Int(raw.sort, 0, -1000, 1000),
        units = U.IDList(raw.units, 64),
        includeSubunits = raw.includeSubunits ~= false,
        jobs = U.StringList(raw.jobs, 64, 64),
        trainerNeedsTraining = raw.trainerNeedsTraining == true,
        requires = U.IDList(raw.requires, 16),
        vehicles = U.StringList(raw.vehicles, 64, 96),
        weapons = U.StringList(raw.weapons, 64, 96),
        validDays = U.Int(raw.validDays, 0, 0, 3650),
        createdBy = U.Clean(raw.createdBy, 64),
    }
    if out.name == "" then out.name = out.id end
    if out.short == "" then out.short = string.upper(string.sub(out.name, 1, 4)) end
    return out
end

function T.ToSave(t)
    local copy = table.Copy(t)
    copy.color = U.ColorToTable(t.color)
    return copy
end

function T.Get(id) return T.loaded[id] end
function T.All() return T.loaded end

function T.List()
    local out = {}
    for _, t in pairs(T.loaded) do out[#out + 1] = t end
    table.sort(out, function(a, b)
        if a.sort ~= b.sort then return a.sort < b.sort end
        if a.category ~= b.category then return a.category < b.category end
        return string.lower(a.name) < string.lower(b.name)
    end)
    return out
end

-- Gilt die Fortbildung für eine Einheit?
function T.AppliesToUnit(t, factionID)
    if #t.units == 0 then return true end
    if not factionID or factionID == "" then return false end
    for _, unit in ipairs(t.units) do
        if unit == factionID then return true end
        if t.includeSubunits and F.IsDescendant(factionID, unit) then return true end
    end
    return false
end

-- Ist die Fortbildung für diesen Charakter in seiner aktuellen Einheit/Job wirksam?
function T.IsActiveFor(t, char)
    if not t or not char then return false end
    if #t.units > 0 and not T.AppliesToUnit(t, char.faction) then
        if #t.jobs == 0 or not U.InList(t.jobs, char.job) then return false end
    elseif #t.units == 0 and #t.jobs > 0 and not U.InList(t.jobs, char.job) then
        return false
    end
    return true
end

-- Fortbildungen, die ein Charakter grundsätzlich bekommen kann (Einheit oder Job passt)
function T.AvailableFor(char)
    local out = {}
    for _, t in ipairs(T.List()) do
        if T.IsActiveFor(t, char) then out[#out + 1] = t end
    end
    return out
end

function T.MissingRequirements(t, char)
    local missing = {}
    for _, req in ipairs(t.requires or {}) do
        if not char:HasTraining(req) then
            local def = T.Get(req)
            missing[#missing + 1] = def and def.name or req
        end
    end
    return missing
end

-- ID der Fortbildung, die zum Eintragen berechtigt ("Fortbildungs-Freigabe")
function T.FreigabeID()
    return U.ID(symchars.Config("trainingfreigabe") or "")
end

function T.IsFreigabe(t)
    local id = T.FreigabeID()
    return t ~= nil and id ~= "" and t.id == id
end

-- Hat der Charakter die Fortbildungs-Freigabe?
function T.HasFreigabe(actor)
    local id = T.FreigabeID()
    return actor ~= nil and id ~= "" and actor:HasTraining(id)
end

-- Darf ply (mit Charakter actor) diese Fortbildung eintragen/entziehen?
function T.CanTeach(ply, actor, t)
    if not t then return false end
    if symchars.HasPriv(ply, "symchars_trainings_admin") then return true, "Admin" end
    if not actor or T.IsFreigabe(t) then return false end
    if not T.HasFreigabe(actor) then return false end
    if t.trainerNeedsTraining and not actor:HasTraining(t.id) then return false end
    return true, "Fortbildungs-Freigabe"
end

-- Darf ply diese Fortbildung bearbeiten (Definition)? Nur Admins.
function T.CanEdit(ply)
    return symchars.IsSuperAdmin(ply)
end

-- Darf ply neue Fortbildungen anlegen? Nur Superadmins.
function T.CanCreate(ply)
    return symchars.IsSuperAdmin(ply)
end

-- Ziel-Charakter: gilt die Fortbildung für ihn?
function T.CanReceive(t, target)
    if not t or not target then return false, "Unbekannt." end
    if not T.IsActiveFor(t, target) then return false, "Diese Fortbildung gilt nicht für seine Einheit oder seinen Job." end
    local missing = T.MissingRequirements(t, target)
    if #missing > 0 then return false, "Voraussetzung fehlt: " .. table.concat(missing, ", ") end
    return true
end

---------------------------------------------------------------------------------------------------------------
-- Freischaltungen
---------------------------------------------------------------------------------------------------------------
-- Klasse -> Liste von Fortbildungs-IDs, die sie freischalten
function T.VehicleIndex()
    local index = {}
    for id, t in pairs(T.loaded) do
        for _, class in ipairs(t.vehicles or {}) do
            index[class] = index[class] or {}
            table.insert(index[class], id)
        end
    end
    return index
end

function T.UnlockedVehicles(char)
    local out, seen = {}, {}
    if not char then return out end
    for id in pairs(char:GetTrainings()) do
        local t = T.Get(id)
        if t and char:HasTraining(id) and T.IsActiveFor(t, char) then
            for _, class in ipairs(t.vehicles) do
                if not seen[class] then seen[class] = true out[#out + 1] = class end
            end
        end
    end
    return out
end

function T.UnlockedWeapons(char)
    local out, seen = {}, {}
    if not char then return out end
    for id in pairs(char:GetTrainings()) do
        local t = T.Get(id)
        if t and char:HasTraining(id) and T.IsActiveFor(t, char) then
            for _, class in ipairs(t.weapons) do
                if not seen[class] then seen[class] = true out[#out + 1] = class end
            end
        end
    end
    return out
end

-- Filtert die Fahrzeugliste des SSE-Terminals
function T.FilterVehicles(ply, list)
    if not symchars.Config("trainingsse") then return list end
    local char = IsValid(ply) and ply:GetCharacter()
    local out, seen = {}, {}
    local index = T.VehicleIndex()
    local filter = symchars.Config("trainingssefilter")

    local unlocked = U.ToSet(T.UnlockedVehicles(char))

    for _, class in pairs(list or {}) do
        if isstring(class) and not seen[class] then
            if not filter or not index[class] or unlocked[class] then
                seen[class] = true
                out[#out + 1] = class
            end
        end
    end

    for class in pairs(unlocked) do
        if not seen[class] then
            seen[class] = true
            out[#out + 1] = class
        end
    end

    return out
end

function T.InstallSSE()
    if not SSE or not SSE.Config or not SSE.Config.VehicleRequisition then return false end
    local vr = SSE.Config.VehicleRequisition
    if vr.GetVehicles == T._sseWrapper then return true end
    local original = vr.GetVehicles
    T._sseOriginal = original
    T._sseWrapper = function(ply)
        local base = {}
        if isfunction(T._sseOriginal) then
            local ok, result = pcall(T._sseOriginal, ply)
            if ok and istable(result) then base = result end
        end
        return T.FilterVehicles(ply, base)
    end
    vr.GetVehicles = T._sseWrapper
    return true
end

hook.Add("Initialize", "symchars_trainings_sse", function() T.InstallSSE() end)
hook.Add("InitPostEntity", "symchars_trainings_sse", function() T.InstallSSE() end)
timer.Create("symchars_trainings_sse", 15, 0, function() T.InstallSSE() end)
T.InstallSSE()

if CLIENT then
    symchars.net.Receive("trainings", function(data)
        T.loaded = {}
        for _, raw in ipairs(istable(data) and data or {}) do
            local t = T.Normalize(raw)
            if t.id ~= "" then T.loaded[t.id] = t end
        end
        hook.Run("symchars_trainings_synced")
    end)
end
