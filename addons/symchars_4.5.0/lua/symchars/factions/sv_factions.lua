--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Einheiten (Server): Laden, Import aus altem symchars, Speichern, Löschen
-------------------------------------------------------------------------------------------------------------]]

local F = symchars.factions
local U = symchars.util
local DB = symchars.db

local OLD_FILE = "symchars/factions/factions.json"

local function DefaultFactions()
    local defaultJob = symchars.Config("defaultjob") or "teamzivilisten"
    if TEAM_ZIVILIST and RPExtraTeams and RPExtraTeams[TEAM_ZIVILIST] then
        defaultJob = RPExtraTeams[TEAM_ZIVILIST].command
    elseif not U.GetJob(defaultJob) and RPExtraTeams and GAMEMODE and RPExtraTeams[GAMEMODE.DefaultTeam] then
        defaultJob = RPExtraTeams[GAMEMODE.DefaultTeam].command
    end
    return {
        citizen = {
            uniqueID = "citizen", name = "Zivilisten", short = "ZIV", isDefault = true, job = defaultJob,
            color = { r = 140, g = 200, b = 120, a = 255 },
            ranks = {
                { name = "Bürger", short = "B", flags = {} },
                { name = "Vertreter", short = "V", flags = { "invite", "kick", "transfer", "promotions" } },
                { name = "Leitung", short = "L", flags = { "admin" } },
            },
        },
    }
end

function F.SaveOne(faction)
    local data = F.ToSaveTable(faction)
    DB.Replace("sc_factions", { "id", "data" }, { DB.Str(faction.uniqueID), DB.Str(symchars.net.Json(data)) })
end

function F.DeleteRow(id)
    DB.Query("DELETE FROM sc_factions WHERE id = " .. DB.Str(id))
end

function F.Load(done)
    DB.Query("SELECT id, data FROM sc_factions", function(rows)
        F.loaded = {}
        for _, row in ipairs(rows) do
            local data = symchars.net.Unjson(row.data or "")
            if istable(data) then
                data.uniqueID = data.uniqueID or row.id
                F.Create(F.Normalize(data))
            end
        end

        -- Einheiten, die noch den alten DarkRP-Job "citizen" nutzen, auf Zivilist (teamzivilisten) umstellen
        for _, f in pairs(F.loaded) do
            local changed = false
            if f.job == "citizen" or (f.uniqueID == "citizen" and not U.GetJob(f.job)) then
                f.job = "teamzivilisten"
                changed = true
            end
            for _, rank in ipairs(f.ranks or {}) do
                if rank.job == "citizen" then rank.job = "teamzivilisten" changed = true end
            end
            if changed then F.SaveOne(f) end
        end

        if table.Count(F.loaded) > 0 then
            symchars.print(table.Count(F.loaded) .. " Einheiten geladen.")
            if done then done() end
            return
        end

        -- Erststart: alte symchars-Einheiten übernehmen
        local source = nil
        if file.Exists(OLD_FILE, "DATA") then
            source = symchars.net.Unjson(file.Read(OLD_FILE, "DATA") or "")
            if istable(source) then symchars.print("Übernehme Einheiten aus data/" .. OLD_FILE) end
        end
        if not istable(source) or table.Count(source) == 0 then
            source = DefaultFactions()
            symchars.print("Keine Einheiten gefunden - lege Standard-Einheit an.")
        end

        for id, data in pairs(source) do
            if istable(data) then
                data.uniqueID = data.uniqueID or id
                local faction = F.Create(F.Normalize(data))
                F.SaveOne(faction)
            end
        end
        if done then done() end
    end, function() if done then done() end end)
end

function F.SyncAll(ply)
    local out = {}
    for id, f in pairs(F.loaded) do out[id] = F.ToSaveTable(f) end
    symchars.net.Send("factions", out, ply)
    if not ply then hook.Run("symchars_factions_synced", out) end
end

---------------------------------------------------------------------------------------------------------------
-- Umbenennen / Löschen
---------------------------------------------------------------------------------------------------------------
local function RenameReferences(oldID, newID, newJob)
    for _, f in pairs(F.loaded) do
        if F.NormalizeParentID(f.subfaction_of) == oldID then
            f.subfaction_of = newID
            F.SaveOne(f)
        end
    end
    for _, char in pairs(symchars.chars.All()) do
        if char.faction == oldID then
            char.faction = newID
            if newJob and newJob ~= "" then char.job = newJob end
            symchars.chars.Sync(char)
        end
    end
    local setJob = (newJob and newJob ~= "") and (", job = " .. DB.Str(newJob)) or ""
    DB.Query("UPDATE sy_characters SET faction = " .. DB.Str(newID) .. setJob .. " WHERE faction = " .. DB.Str(oldID))
end

function F.Delete(id)
    local faction = F.Get(id)
    if not faction then return false, "Die Einheit existiert nicht." end
    local fallbackID, fallback = F.FindFallback(id)
    if not fallback then return false, "Die letzte Einheit kann nicht gelöscht werden." end

    local parentID = F.NormalizeParentID(faction.subfaction_of)
    F.loaded[id] = nil
    F.DeleteRow(id)

    for _, f in pairs(F.loaded) do
        if F.NormalizeParentID(f.subfaction_of) == id then
            f.subfaction_of = parentID
            F.SaveOne(f)
        end
        local changed = false
        for _, rank in ipairs(f.ranks or {}) do
            local cleaned = {}
            for _, flag in ipairs(rank.flags or {}) do
                if string.sub(flag, 1, #id + 1) == id .. "_" then changed = true else cleaned[#cleaned + 1] = flag end
            end
            rank.flags = cleaned
        end
        if changed then F.SaveOne(f) end
    end

    if faction.isDefault then
        local hasDefault = false
        for _, f in pairs(F.loaded) do if f.isDefault then hasDefault = true break end end
        if not hasDefault then fallback.isDefault = true F.SaveOne(fallback) end
    end

    for _, char in pairs(symchars.chars.All()) do
        if char.faction == id then
            symchars.chars.SetFaction(char.charID, fallbackID, { ignoreRankLimit = true, silent = true })
        end
    end

    return true, fallback
end

---------------------------------------------------------------------------------------------------------------
-- Netzwerk (Editor)
---------------------------------------------------------------------------------------------------------------
local function CanEdit(ply)
    return symchars.IsSuperAdmin(ply)
end

symchars.net.Receive("faction_save", function(ply, data)
    if not CanEdit(ply) then symchars.Notify(ply, "Dir fehlt die Berechtigung.", "error") return end
    if not istable(data) or not istable(data.faction) then return end

    local previousID = U.Lower(data.previousID)
    local raw = data.faction
    local ok, issues = F.Validate(raw, previousID)
    if not ok then
        for i = 1, math.min(#issues, 4) do symchars.Notify(ply, issues[i], "error") end
        return
    end

    local faction = F.Normalize(raw)
    if previousID ~= "" and previousID ~= faction.uniqueID then
        F.loaded[previousID] = nil
        F.DeleteRow(previousID)
        RenameReferences(previousID, faction.uniqueID, faction.job)
    end

    F.Create(faction)
    F.SaveOne(faction)
    F.SyncAll()

    -- Spieler dieser Einheit aktualisieren (Name, Job, Modell)
    for _, target in ipairs(player.GetAll()) do
        local char = target:GetCharacter()
        if char and char.faction == faction.uniqueID then
            symchars.chars.RefreshPlayer(target)
        end
    end

    symchars.Notify(ply, "Einheit '" .. faction.name .. "' gespeichert.", "succ")
end, 0.5)

symchars.net.Receive("faction_delete", function(ply, data)
    if not CanEdit(ply) then symchars.Notify(ply, "Dir fehlt die Berechtigung.", "error") return end
    local id = U.Lower(istable(data) and data.id)
    local ok, result = F.Delete(id)
    if not ok then symchars.Notify(ply, result, "error") return end
    F.SyncAll()
    symchars.Notify(ply, "Einheit gelöscht. Mitglieder wurden nach '" .. result.name .. "' verschoben.", "succ")
end, 1)
