GRNWeaponrio = GRNWeaponrio or {}
local C = GRNWeaponrio.Config or {}

util.AddNetworkString("grn_armario_jobs")
util.AddNetworkString("grn_armario_request")
util.AddNetworkString("grn_armario_equip")
util.AddNetworkString("grn_armario_feedback")
util.AddNetworkString("grn_armario_close")

GRNWeaponrio.Sessions = GRNWeaponrio.Sessions or {}
GRNWeaponrio.AppearanceCache = GRNWeaponrio.AppearanceCache or {}
GRNWeaponrio.NextUse = GRNWeaponrio.NextUse or {}
GRNWeaponrio.SpawnSerial = GRNWeaponrio.SpawnSerial or {}

sql.Query([[CREATE TABLE IF NOT EXISTS grn_armario_appearance (
    owner_key TEXT NOT NULL,
    job_key TEXT NOT NULL,
    model TEXT NOT NULL,
    bodygroups TEXT NOT NULL,
    updated INTEGER NOT NULL,
    PRIMARY KEY (owner_key, job_key)
)]])

local function debugPrint(...)
    if not C.Debug then return end
    MsgC(Color(255, 190, 50), "[GRN Wardrobe] ", color_white, table.concat({...}, " "), "\n")
end

local function safeCall(fn, ...)
    if not isfunction(fn) then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        debugPrint("Error en callback:", tostring(a))
        return nil
    end
    return a, b, c
end

local function ownerKey(ply)
    local key = safeCall(C.PersistenceOwnerKey, ply)
    key = tostring(key or ply:SteamID64() or "0")
    return key
end

local function getJob(teamID)
    if not RPExtraTeams then return nil end
    return RPExtraTeams[tonumber(teamID) or -1]
end

local function getModels(job)
    if not job then return {} end
    local raw = job.model
    if isstring(raw) then return {raw} end
    if istable(raw) then
        local out = {}
        for _, mdl in ipairs(raw) do
            if isstring(mdl) and mdl ~= "" then out[#out + 1] = mdl end
        end
        return out
    end
    return {}
end

local function getConfiguredMenuIcon(job)
    if not istable(job) then return tostring(C.DefaultMenuIcon or "") end

    local command = string.lower(tostring(job.command or ""))
    local category = tostring(job.category or "")

    if istable(C.JobIcons) and command ~= "" and isstring(C.JobIcons[command]) and C.JobIcons[command] ~= "" then
        return C.JobIcons[command]
    end

    if istable(C.CategoryIcons) and category ~= "" and isstring(C.CategoryIcons[category]) and C.CategoryIcons[category] ~= "" then
        return C.CategoryIcons[category]
    end

    return tostring(C.DefaultMenuIcon or "")
end

local function jobKey(teamID, job)
    if job and isstring(job.command) and job.command ~= "" then
        return string.lower(job.command)
    end
    return tostring(teamID)
end

local function isModelAllowed(job, mdl)
    if not isstring(mdl) or mdl == "" then return false end
    for _, allowed in ipairs(getModels(job)) do
        if string.lower(allowed) == string.lower(mdl) then return true end
    end
    return false
end

local function loadAppearance(ply, teamID, job)
    if not IsValid(ply) then return nil end

    local oKey = ownerKey(ply)
    local jKey = jobKey(teamID, job)
    GRNWeaponrio.AppearanceCache[oKey] = GRNWeaponrio.AppearanceCache[oKey] or {}

    if GRNWeaponrio.AppearanceCache[oKey][jKey] ~= nil then
        return GRNWeaponrio.AppearanceCache[oKey][jKey] or nil
    end

    local row = sql.QueryRow("SELECT model, bodygroups FROM grn_armario_appearance WHERE owner_key = " .. sql.SQLStr(oKey) .. " AND job_key = " .. sql.SQLStr(jKey) .. " LIMIT 1")
    if not row then
        GRNWeaponrio.AppearanceCache[oKey][jKey] = false
        return nil
    end

    local data = {
        model = tostring(row.model or ""),
        bodygroups = util.JSONToTable(row.bodygroups or "{}") or {}
    }

    GRNWeaponrio.AppearanceCache[oKey][jKey] = data
    return data
end

local function saveAppearance(ply, teamID, job, mdl, bodygroups)
    local oKey = ownerKey(ply)
    local jKey = jobKey(teamID, job)
    local cleaned = {}

    for id, value in pairs(bodygroups or {}) do
        local bgID = math.floor(tonumber(id) or -1)
        local bgValue = math.floor(tonumber(value) or 0)
        if bgID >= 0 and bgID <= (C.MaxBodygroupIndex or 63) then
            cleaned[tostring(bgID)] = math.Clamp(bgValue, 0, C.MaxBodygroupValue or 63)
        end
    end

    local encoded = util.TableToJSON(cleaned, false) or "{}"
    local query = "REPLACE INTO grn_armario_appearance (owner_key, job_key, model, bodygroups, updated) VALUES (" ..
        sql.SQLStr(oKey) .. "," .. sql.SQLStr(jKey) .. "," .. sql.SQLStr(mdl) .. "," .. sql.SQLStr(encoded) .. "," .. os.time() .. ")"

    sql.Query(query)
    GRNWeaponrio.AppearanceCache[oKey] = GRNWeaponrio.AppearanceCache[oKey] or {}
    GRNWeaponrio.AppearanceCache[oKey][jKey] = {model = mdl, bodygroups = cleaned}
end

local function isLuctusWhitelisted(ply, teamID, job)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    job = job or getJob(teamID)
    if not job then return false end

    -- Lucid/Luctus Whitelist guarda los permisos usando exactamente el nombre
    -- del job como NWBool por jugador y GlobalBool para la whitelist "everyone".
    local jobName = tostring(team.GetName(teamID) or job.name or "")
    if jobName == "" then return false end

    if GetGlobalBool(jobName, false) then return true end
    if ply:GetNWBool(jobName, false) then return true end

    return false
end

function GRNWeaponrio.CanUseJob(ply, teamID, job)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    job = job or getJob(teamID)
    if not job then return false end

    if C.HiddenJobCommands and job.command and C.HiddenJobCommands[string.lower(job.command)] then
        return false
    end

    -- Bypass opcional para administración. Si querés que ni los staff vean
    -- jobs sin whitelist, dejá C.BypassGroups vacío en sh_config.lua.
    if C.BypassGroups and C.BypassGroups[ply:GetUserGroup()] then
        return true
    end

    -- Integración DIRECTA con el sistema que usa el servidor:
    -- luctus_whitelist / Lucid Whitelist. Fuera de los bypass configurados,
    -- la whitelist es obligatoria y ninguna regla externa puede saltársela.
    if not isLuctusWhitelisted(ply, teamID, job) then
        return false
    end

    local forced = safeCall(C.CustomWhitelistCheck, ply, teamID, job)
    if forced ~= nil then return forced == true end

    local hookDecision = hook.Run("GRNWeaponrioCanUseJob", ply, teamID, job)
    if hookDecision ~= nil then return hookDecision == true end

    if tonumber(job.admin or 0) > 0 and not ply:IsAdmin() then
        return false
    end

    if job.vote and C.AllowVoteJobs == false then
        return false
    end

    if isfunction(job.customCheck) then
        local allowed = safeCall(job.customCheck, ply)
        if allowed == false then return false end
    end

    return true
end

local function buildJobPayload(ply)
    local jobs = {}
    if not RPExtraTeams then return jobs end

    for teamID, job in pairs(RPExtraTeams) do
        if isnumber(teamID) and istable(job) and GRNWeaponrio.CanUseJob(ply, teamID, job) then
            local models = getModels(job)
            if #models > 0 then
                local saved = loadAppearance(ply, teamID, job)
                if saved and not isModelAllowed(job, saved.model) then
                    saved = nil
                end

                local col = job.color or Color(77, 128, 202)
                jobs[#jobs + 1] = {
                    id = teamID,
                    name = tostring(job.name or ("Job " .. teamID)),
                    command = tostring(job.command or teamID),
                    category = tostring(job.category or "Ohne Kategorie"),
                    description = tostring(job.description or ""),
                    models = models,
                    color = {r = col.r or 77, g = col.g or 128, b = col.b or 202},
                    icon = getConfiguredMenuIcon(job),
                    saved = saved,
                    current = ply:Team() == teamID
                }
            end
        end
    end

    table.sort(jobs, function(a, b)
        if a.current ~= b.current then return a.current end
        if a.category ~= b.category then return a.category < b.category end
        return a.name < b.name
    end)

    return jobs
end

local function writeCompressedTable(tbl)
    local json = util.TableToJSON(tbl, false) or "{}"
    local compressed = util.Compress(json) or ""
    net.WriteUInt(#compressed, 32)
    if #compressed > 0 then net.WriteData(compressed, #compressed) end
end

local function sendFeedback(ply, ok, text)
    net.Start("grn_armario_feedback")
    net.WriteBool(ok == true)
    net.WriteString(tostring(text or ""))
    net.Send(ply)
end

function GRNWeaponrio.SendJobList(ply, openMenu)
    if not IsValid(ply) then return end

    net.Start("grn_armario_jobs")
    net.WriteBool(openMenu == true)
    local session = GRNWeaponrio.Sessions[ply]
    writeCompressedTable({
        title = C.MenuTitle or "UNIFORM",
        footer = C.MenuFooter or "Echoes of Clones · Uniformsystem",
        currentTeam = ply:Team(),
        entity = session and IsValid(session.ent) and session.ent:EntIndex() or 0,
        jobs = buildJobPayload(ply)
    })
    net.Send(ply)
end

local function validSession(ply, ent)
    if not IsValid(ply) or not IsValid(ent) or ent:GetClass() ~= "grn_armario_locker" then return false end
    local session = GRNWeaponrio.Sessions[ply]
    if not session or session.ent ~= ent then return false end
    if CurTime() - (session.time or 0) > (C.SessionTimeout or 90) then return false end
    if ply:GetPos():DistToSqr(ent:GetPos()) > ((C.EntityUseDistance or 180) + 70) ^ 2 then return false end
    return true
end

function GRNWeaponrio.OpenLocker(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return end

    local nextUse = GRNWeaponrio.NextUse[ply] or 0
    if nextUse > CurTime() then return end
    GRNWeaponrio.NextUse[ply] = CurTime() + (C.EntityUseCooldown or 0.75)

    if ply:GetPos():DistToSqr(ent:GetPos()) > (C.EntityUseDistance or 180) ^ 2 then return end

    GRNWeaponrio.Sessions[ply] = {ent = ent, time = CurTime()}
    GRNWeaponrio.SendJobList(ply, true)
end

net.Receive("grn_armario_request", function(_, ply)
    local ent = Entity(net.ReadUInt(16))
    if not validSession(ply, ent) then return end
    GRNWeaponrio.Sessions[ply].time = CurTime()
    GRNWeaponrio.SendJobList(ply, false)
end)

net.Receive("grn_armario_close", function(_, ply)
    GRNWeaponrio.Sessions[ply] = nil
end)

local function applyAppearance(ply, teamID, mdl, bodygroups)
    if not IsValid(ply) then return end
    local job = getJob(teamID)
    if not job or ply:Team() ~= teamID then return end
    if not isModelAllowed(job, mdl) then return end

    ply:SetModel(mdl)
    for id, value in pairs(bodygroups or {}) do
        local bgID = math.floor(tonumber(id) or -1)
        local bgValue = math.floor(tonumber(value) or 0)
        if bgID >= 0 and bgID <= (C.MaxBodygroupIndex or 63) then
            ply:SetBodygroup(bgID, math.Clamp(bgValue, 0, C.MaxBodygroupValue or 63))
        end
    end
end

local function applySavedForCurrentJob(ply)
    if not IsValid(ply) then return end
    local teamID = ply:Team()
    local job = getJob(teamID)
    if not job then return end
    local saved = loadAppearance(ply, teamID, job)
    if not saved or not isModelAllowed(job, saved.model) then return end
    applyAppearance(ply, teamID, saved.model, saved.bodygroups)
end

net.Receive("grn_armario_equip", function(_, ply)
    local ent = Entity(net.ReadUInt(16))
    if not validSession(ply, ent) then
        sendFeedback(ply, false, "Du musst in der Nähe des Schranks sein.")
        return
    end

    local teamID = net.ReadUInt(16)
    local modelIndex = net.ReadUInt(8)
    local count = math.min(net.ReadUInt(8), 64)
    local bodygroups = {}

    for _ = 1, count do
        local bgID = net.ReadUInt(8)
        local bgValue = net.ReadUInt(8)
        if bgID <= (C.MaxBodygroupIndex or 63) then
            bodygroups[bgID] = math.Clamp(bgValue, 0, C.MaxBodygroupValue or 63)
        end
    end

    local job = getJob(teamID)
    if not job or not GRNWeaponrio.CanUseJob(ply, teamID, job) then
        sendFeedback(ply, false, "Du bist für diesen Job nicht gewhitelistet.")
        GRNWeaponrio.SendJobList(ply, false)
        return
    end

    local models = getModels(job)
    local mdl = models[modelIndex]
    if not mdl or not isModelAllowed(job, mdl) then
        sendFeedback(ply, false, "Ungültiges Modell für diesen Job.")
        return
    end

    local wasSameTeam = ply:Team() == teamID
    local spawnSerialBefore = GRNWeaponrio.SpawnSerial[ply] or 0

    if not wasSameTeam then
        if isfunction(ply.changeTeam) then
            local ok, result = pcall(ply.changeTeam, ply, teamID, false)
            if not ok or result == false then
                sendFeedback(ply, false, "Das Jobsystem hat den Wechsel abgelehnt.")
                return
            end
        else
            ply:SetTeam(teamID)
        end
    end

    timer.Simple(C.ApplyDelay or 0.20, function()
        if not IsValid(ply) then return end
        if ply:Team() ~= teamID then
            sendFeedback(ply, false, "Das Jobsystem hat den Wechsel abgelehnt.")
            return
        end

        saveAppearance(ply, teamID, job, mdl, bodygroups)

        -- Si DarkRP ya respawneó al jugador, no duplicamos el spawn. Si no lo
        -- hizo, lo forzamos para cumplir el cambio de uniforme/job.
        if C.SpawnAfterEquip and (GRNWeaponrio.SpawnSerial[ply] or 0) == spawnSerialBefore then
            ply:Spawn()
        end

        timer.Simple(0.05, function()
            if IsValid(ply) and ply:Team() == teamID then
                applyAppearance(ply, teamID, mdl, bodygroups)
                sendFeedback(ply, true, "Uniform angelegt und gespeichert.")
            end
        end)
    end)
end)

hook.Add("PlayerSpawn", "GRNWeaponrio.ApplySavedBodygroups", function(ply)
    GRNWeaponrio.SpawnSerial[ply] = (GRNWeaponrio.SpawnSerial[ply] or 0) + 1

    timer.Simple(C.ApplyDelay or 0.20, function()
        applySavedForCurrentJob(ply)
    end)

    timer.Simple(C.ApplyAgainDelay or 0.85, function()
        applySavedForCurrentJob(ply)
    end)
end)

hook.Add("OnPlayerChangedTeam", "GRNWeaponrio.ApplyAfterTeamChange", function(ply)
    timer.Simple(C.ApplyDelay or 0.20, function()
        applySavedForCurrentJob(ply)
    end)
end)

-- Lucid/Luctus Whitelist ejecuta este hook justo después de guardar y aplicar
-- una whitelist. Si el jugador tiene el armario abierto, la lista se actualiza
-- sin que tenga que closelo ni reconectarse.
hook.Add("LuctusWhitelistUpdate", "GRNWeaponrio.RefreshOnLuctusWhitelist", function(_, steamid)
    steamid = tostring(steamid or "")

    timer.Simple(0, function()
        for target, session in pairs(GRNWeaponrio.Sessions) do
            if IsValid(target) and session then
                if steamid == "everyone" or target:SteamID() == steamid then
                    GRNWeaponrio.SendJobList(target, false)
                end
            end
        end
    end)
end)

hook.Add("PlayerDisconnected", "GRNWeaponrio.Cleanup", function(ply)
    GRNWeaponrio.Sessions[ply] = nil
    GRNWeaponrio.NextUse[ply] = nil
    GRNWeaponrio.SpawnSerial[ply] = nil
end)

concommand.Add("grn_armario_reload", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    for _, target in ipairs(player.GetAll()) do
        GRNWeaponrio.AppearanceCache[ownerKey(target)] = nil
    end
    print("[GRN Wardrobe] Appearance cache cleared.")
end)
