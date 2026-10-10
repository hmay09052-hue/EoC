--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Fortbildungen (Server)
-------------------------------------------------------------------------------------------------------------]]

local T = symchars.trainings
local C = symchars.chars
local U = symchars.util
local UT = symchars.utils
local DB = symchars.db
local Json, Unjson = symchars.net.Json, symchars.net.Unjson

function T.Load(done)
    DB.Query("SELECT id, data FROM sc_trainings", function(rows)
        T.loaded = {}
        for _, row in ipairs(rows) do
            local t = T.Normalize(Unjson(row.data or ""), row.id)
            if t.id ~= "" then T.loaded[t.id] = t end
        end
        DB.Query("SELECT * FROM sc_char_trainings", function(list)
            for _, char in pairs(C.loaded) do char.trainings = {} end
            for _, row in ipairs(list) do
                local char = C.Get(tonumber(row.charID))
                if char then
                    char.trainings[row.training] = {
                        at = tonumber(row.grantedAt) or 0,
                        by = tonumber(row.grantedBy) or 0,
                        byName = row.grantedByName or "",
                        note = row.note or "",
                        exp = tonumber(row.expiresAt) or 0,
                    }
                end
            end
            T._loadedOnce = true
            T.EnsureFreigabe()
            symchars.print(table.Count(T.loaded) .. " Fortbildungen geladen.")
            if done then done() end
        end, function() if done then done() end end)
    end, function() if done then done() end end)
end

-- Die Fortbildungs-Freigabe (berechtigt zum Eintragen) muss es immer geben
function T.EnsureFreigabe()
    local id = T.FreigabeID()
    if id == "" or T.Get(id) then return end
    local t = T.Normalize({
        name = "Fortbildungs-Freigabe", short = "FBF", category = "Verwaltung", sort = -100,
        color = Color(252, 178, 73), createdBy = "System",
        description = "Berechtigt dazu, anderen Charakteren Fortbildungen einzutragen und zu entziehen. Wird nur von Admins vergeben.",
    }, id)
    T.loaded[id] = t
    DB.Replace("sc_trainings", { "id", "data" }, { DB.Str(id), DB.Str(Json(T.ToSave(t))) })
end

-- Neue Freigabe-ID in den Einstellungen -> Fortbildung anlegen, falls sie fehlt
hook.Add("symchars_settings_changed", "symchars_trainings_freigabe", function()
    if not T._loadedOnce or T.Get(T.FreigabeID()) then return end
    T.EnsureFreigabe()
    T.SyncAll()
end)

-- Neu erstellte Charaktere haben noch keine Fortbildungen geladen -> bei Bedarf nachladen
hook.Add("symchars_created", "symchars_trainings_init", function(_, _, id)
    local char = C.Get(id)
    if char then char.trainings = char.trainings or {} end
end)

function T.SyncAll(ply)
    local list = {}
    for _, t in pairs(T.loaded) do list[#list + 1] = T.ToSave(t) end
    symchars.net.Send("trainings", list, ply)
end

function T.Grant(char, training, actorPly, note)
    local actor = IsValid(actorPly) and actorPly:GetCharacter()
    local now = os.time()
    local exp = training.validDays > 0 and (now + training.validDays * 86400) or 0
    local byName = actor and UT.BuildDisplayName(actor) or (IsValid(actorPly) and actorPly:Nick() or "System")
    note = U.Clean(note, 300)

    char.trainings = char.trainings or {}
    char.trainings[training.id] = { at = now, by = actor and actor.charID or 0, byName = byName, note = note, exp = exp }

    DB.Replace("sc_char_trainings", { "charID", "training", "grantedAt", "grantedBy", "grantedByName", "note", "expiresAt" }, {
        DB.Num(char.charID), DB.Str(training.id), DB.Num(now), DB.Num(actor and actor.charID or 0), DB.Str(byName), DB.Str(note), DB.Num(exp),
    })

    symchars.history.Log(char.charID, "training", "Fortbildung bestanden: " .. training.name .. (note ~= "" and (" (" .. note .. ")") or ""), byName)
    C.Sync(char)

    local ply = C.OnlinePlayer(char)
    if IsValid(ply) then
        symchars.Notify(ply, "Fortbildung bestanden: " .. training.name, "succ", 6)
        symchars.net.Send("training_passed", { id = training.id }, ply)
        C.ApplyExtras(ply, false)
    end

    if symchars.Config("trainingannounce") and char:GetFaction() then
        local root = char:GetFaction():GetRoot()
        local targets = {}
        for _, p in ipairs(player.GetAll()) do
            local pc = p:GetCharacter()
            if pc and p ~= ply and pc:GetFaction() and symchars.factions.IsInTree(pc:GetFaction(), root) then targets[#targets + 1] = p end
        end
        if #targets > 0 then
            symchars.Notify(targets, UT.BuildDisplayName(char) .. " hat die Fortbildung " .. training.name .. " bestanden.", "info")
        end
    end

    hook.Run("symchars_training_granted", byName, char, training.id)
end

function T.Revoke(char, training, actorPly, reason)
    if not char.trainings or not char.trainings[training.id] then return false end
    local actor = IsValid(actorPly) and actorPly:GetCharacter()
    local byName = actor and UT.BuildDisplayName(actor) or (IsValid(actorPly) and actorPly:Nick() or "System")
    char.trainings[training.id] = nil
    DB.Query("DELETE FROM sc_char_trainings WHERE charID = " .. DB.Num(char.charID) .. " AND training = " .. DB.Str(training.id))
    reason = U.Clean(reason, 300)
    symchars.history.Log(char.charID, "training", "Fortbildung entzogen: " .. training.name .. (reason ~= "" and (" (" .. reason .. ")") or ""), byName)
    C.Sync(char)
    local ply = C.OnlinePlayer(char)
    if IsValid(ply) then symchars.Notify(ply, "Fortbildung entzogen: " .. training.name, "error", 6) end
    hook.Run("symchars_training_revoked", byName, char, training.id)
    return true
end

---------------------------------------------------------------------------------------------------------------
-- Netzwerk
---------------------------------------------------------------------------------------------------------------
symchars.net.Receive("training_grant", function(ply, data)
    if not istable(data) then return end
    local training = T.Get(U.ID(data.training))
    local target = C.Get(data.id)
    if not training or not target then return end
    local actor = ply:GetCharacter()

    if not T.CanTeach(ply, actor, training) then
        symchars.Notify(ply, "Du darfst diese Fortbildung nicht eintragen.", "error")
        return
    end
    if actor and actor.charID == target.charID and not symchars.HasPriv(ply, "symchars_trainings_admin") then
        symchars.Notify(ply, "Du kannst dir selbst keine Fortbildung eintragen.", "error")
        return
    end
    if target:HasTraining(training.id) then
        symchars.Notify(ply, "Der Charakter hat diese Fortbildung bereits.", "error")
        return
    end
    local ok, why = T.CanReceive(training, target)
    if not ok and not (data.force == true and symchars.HasPriv(ply, "symchars_trainings_admin")) then
        symchars.Notify(ply, why, "error")
        return
    end

    T.Grant(target, training, ply, data.note)
    symchars.Notify(ply, training.name .. " für " .. UT.BuildDisplayName(target) .. " eingetragen.", "succ")
end, 0.5)

symchars.net.Receive("training_revoke", function(ply, data)
    if not istable(data) then return end
    local training = T.Get(U.ID(data.training))
    local target = C.Get(data.id)
    if not training or not target then return end
    if not T.CanTeach(ply, ply:GetCharacter(), training) then
        symchars.Notify(ply, "Du darfst diese Fortbildung nicht entziehen.", "error")
        return
    end
    if T.Revoke(target, training, ply, data.reason) then
        symchars.Notify(ply, training.name .. " wurde " .. UT.BuildDisplayName(target) .. " entzogen.", "succ")
    end
end, 0.5)

symchars.net.Receive("training_save", function(ply, data)
    if not istable(data) or not istable(data.training) then return end
    local raw = data.training
    local previous = U.ID(data.previousID)
    local t = T.Normalize(raw, raw.id)
    if t.id == "" then symchars.Notify(ply, "Die Fortbildung braucht eine ID.", "error") return end
    if t.name == "" then symchars.Notify(ply, "Die Fortbildung braucht einen Namen.", "error") return end

    local existing = T.Get(previous ~= "" and previous or t.id)
    if existing then
        if not T.CanEdit(ply) then symchars.Notify(ply, "Nur Superadmins dürfen Fortbildungen bearbeiten.", "error") return end
    elseif not T.CanCreate(ply) then
        symchars.Notify(ply, "Nur Superadmins dürfen Fortbildungen anlegen.", "error")
        return
    end
    if T.IsFreigabe(existing) and previous ~= t.id then
        symchars.Notify(ply, "Die ID der Fortbildungs-Freigabe kann nicht geändert werden (Einstellungen).", "error")
        return
    end
    if previous ~= t.id and T.Get(t.id) then
        symchars.Notify(ply, "Die ID '" .. t.id .. "' ist bereits vergeben.", "error")
        return
    end

    t.createdBy = existing and existing.createdBy or ply:Nick()

    if previous ~= "" and previous ~= t.id and T.Get(previous) then
        T.loaded[previous] = nil
        DB.Query("DELETE FROM sc_trainings WHERE id = " .. DB.Str(previous))
        DB.Query("UPDATE sc_char_trainings SET training = " .. DB.Str(t.id) .. " WHERE training = " .. DB.Str(previous))
        for _, char in pairs(C.loaded) do
            if char.trainings and char.trainings[previous] then
                char.trainings[t.id] = char.trainings[previous]
                char.trainings[previous] = nil
                C.Sync(char)
            end
        end
    end

    T.loaded[t.id] = t
    DB.Replace("sc_trainings", { "id", "data" }, { DB.Str(t.id), DB.Str(Json(T.ToSave(t))) })
    T.SyncAll()
    symchars.Notify(ply, "Fortbildung '" .. t.name .. "' gespeichert.", "succ")
end, 0.5)

symchars.net.Receive("training_delete", function(ply, data)
    local t = T.Get(U.ID(istable(data) and data.id))
    if not t then return end
    if not T.CanEdit(ply) then symchars.Notify(ply, "Dir fehlt die Berechtigung.", "error") return end
    if T.IsFreigabe(t) then
        symchars.Notify(ply, "Die Fortbildungs-Freigabe kann nicht gelöscht werden.", "error")
        return
    end
    T.loaded[t.id] = nil
    DB.Query("DELETE FROM sc_trainings WHERE id = " .. DB.Str(t.id))
    DB.Query("DELETE FROM sc_char_trainings WHERE training = " .. DB.Str(t.id))
    for _, char in pairs(C.loaded) do
        if char.trainings and char.trainings[t.id] then
            char.trainings[t.id] = nil
            C.Sync(char)
        end
    end
    T.SyncAll()
    symchars.Notify(ply, "Fortbildung '" .. t.name .. "' gelöscht.", "succ")
end, 1)

-- Abgelaufene Fortbildungen werden beim Prüfen ignoriert (CHAR:HasTraining). Einmal am Tag aufräumen:
timer.Create("symchars_trainings_expire", 3600, 0, function()
    local now = os.time()
    DB.Query("DELETE FROM sc_char_trainings WHERE expiresAt > 0 AND expiresAt < " .. DB.Num(now - 86400 * 30))
end)
