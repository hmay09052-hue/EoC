local KMS = KrakensMedical

KMS.ServerConfig = KMS.ServerConfig or {}
KMS.ServerConfig.Database = {
    Type = "sqlite",
    InstanceId = "",
    MySQL = {
        Host = "localhost",
        Port = 3306,
        Database = "krakens_medical",
        Username = "root",
        Password = "",
    },
}

KMS.Data = KMS.Data or {}
local Data = KMS.Data

local SCHEMA = {
    SQLite = {
        [[CREATE TABLE IF NOT EXISTS kms_config (
            server_id TEXT NOT NULL DEFAULT 'kms_default',
            key TEXT NOT NULL,
            value TEXT NOT NULL,
            PRIMARY KEY (server_id, key)
        )]],
        [[CREATE TABLE IF NOT EXISTS kms_players (
            server_id TEXT NOT NULL DEFAULT 'kms_default',
            steamid TEXT NOT NULL,
            data TEXT NOT NULL,
            PRIMARY KEY (server_id, steamid)
        )]],
    },
    MySQL = {
        [[CREATE TABLE IF NOT EXISTS kms_config (
            server_id VARCHAR(128) NOT NULL DEFAULT 'kms_default',
            `key` VARCHAR(128) NOT NULL,
            value LONGTEXT NOT NULL,
            PRIMARY KEY (server_id, `key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
        [[CREATE TABLE IF NOT EXISTS kms_players (
            server_id VARCHAR(128) NOT NULL DEFAULT 'kms_default',
            steamid VARCHAR(32) NOT NULL,
            data LONGTEXT NOT NULL,
            PRIMARY KEY (server_id, steamid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    },
}

local function Fire(callback, ...)
    if isfunction(callback) then callback(...) end
end

local INSTANCE_FILE = "krakens_medical/server_instance_id.txt"
local cachedInstanceId

local function GetInstanceId()
    if cachedInstanceId then return cachedInstanceId end
    local configured = string.Trim(tostring(KMS.ServerConfig.Database.InstanceId or ""))
    if configured ~= "" then
        cachedInstanceId = configured
        return configured
    end
    if not file.Exists("krakens_medical", "DATA") then file.CreateDir("krakens_medical") end
    if file.Exists(INSTANCE_FILE, "DATA") then
        local saved = string.Trim(file.Read(INSTANCE_FILE, "DATA") or "")
        if saved ~= "" then
            cachedInstanceId = saved
            return saved
        end
    end
    local hostPort = GetConVar("hostport") and GetConVar("hostport"):GetInt() or 0
    local generated = "kms_" .. string.lower(util.CRC("krakens_medical:" .. (GetHostName() or "kms") .. ":" .. hostPort))
    file.Write(INSTANCE_FILE, generated)
    cachedInstanceId = generated
    return generated
end

local SQLite = {}
SQLite.__index = SQLite

function SQLite.New()
    return setmetatable({ ready = false }, SQLite)
end

function SQLite:Initialize(callback)
    for _, q in ipairs(SCHEMA.SQLite) do
        if sql.Query(q) == false then
            KMS.Log("error", "SQLite schema: " .. tostring(sql.LastError()))
        end
    end
    self.ready = true
    Fire(callback, true)
    return true
end

function SQLite:Query(queryString, callback)
    if isfunction(queryString) then queryString = queryString() end
    local result = sql.Query(queryString)
    if result == false then
        local err = sql.LastError()
        KMS.Log("error", "SQLite query: " .. tostring(err))
        Fire(callback, nil, err)
        return
    end
    Fire(callback, result)
end

function SQLite:Escape(str)
    return sql.SQLStr(tostring(str or ""), true)
end

function SQLite:GetType() return "sqlite" end

local MySQL = {}
MySQL.__index = MySQL

function MySQL.IsAvailable() return mysqloo ~= nil end

function MySQL.New()
    return setmetatable({ ready = false, connected = false, pending = {} }, MySQL)
end

function MySQL:Initialize(callback)
    local cfg = KMS.ServerConfig.Database.MySQL
    self.connection = mysqloo.connect(cfg.Host, cfg.Username, cfg.Password, cfg.Database, cfg.Port)
    self.connection.onConnected = function()
        self.connected = true
        local remaining = #SCHEMA.MySQL
        for _, queryString in ipairs(SCHEMA.MySQL) do
            local q = self.connection:query(queryString)
            local function done()
                remaining = remaining - 1
                if remaining == 0 then
                    self.ready = true
                    local pending = self.pending
                    self.pending = {}
                    for _, p in ipairs(pending) do self:Query(p.query, p.callback) end
                    Fire(callback, true)
                end
            end
            q.onSuccess = done
            q.onError = function(_, err)
                KMS.Log("error", "MySQL schema: " .. tostring(err))
                done()
            end
            q:start()
        end
    end
    self.connection.onConnectionFailed = function(_, err)
        self.connected = false
        KMS.Log("error", "MySQL connection failed: " .. tostring(err))
        timer.Simple(10, function() if self.connection then self.connection:connect() end end)
    end
    self.connection.onDisconnected = function()
        self.connected = false
        self.ready = false
        KMS.Log("warn", "MySQL disconnected, reconnecting...")
        timer.Simple(5, function() if self.connection then self.connection:connect() end end)
    end
    self.connection:connect()
    return true
end

function MySQL:Query(queryString, callback)
    if not self.ready then
        self.pending[#self.pending + 1] = { query = queryString, callback = callback }
        return
    end
    if isfunction(queryString) then queryString = queryString() end
    local q = self.connection:query(queryString)
    q.onSuccess = function(_, data) Fire(callback, data) end
    q.onError = function(_, err)
        KMS.Log("error", "MySQL query: " .. tostring(err))
        Fire(callback, nil, err)
    end
    q:start()
end

function MySQL:Escape(str)
    if self.connected then return self.connection:escape(tostring(str or "")) end
    return string.gsub(tostring(str or ""), "'", "''")
end

function MySQL:GetType() return "mysql" end

local provider

local function KeyCol()
    return provider:GetType() == "mysql" and "`key`" or "key"
end

local function ServerId()
    return provider:GetType() == "mysql" and GetInstanceId() or "kms_default"
end

function Data.SetConfig(key, value)
    if not Data.Loaded then return end
    local json = util.TableToJSON({ v = value }) or "{}"
    provider:Query(function()
        local serverId = provider:Escape(ServerId())
        local escapedKey = provider:Escape(key)
        local escapedValue = provider:Escape(json)
        if provider:GetType() == "mysql" then
            return string.format(
                "INSERT INTO kms_config (server_id, %s, value) VALUES ('%s', '%s', '%s') ON DUPLICATE KEY UPDATE value='%s'",
                KeyCol(), serverId, escapedKey, escapedValue, escapedValue)
        end
        return string.format(
            "INSERT OR REPLACE INTO kms_config (server_id, key, value) VALUES ('%s', '%s', '%s')",
            serverId, escapedKey, escapedValue)
    end)
end

function Data.GetConfig(key, callback)
    provider:Query(function()
        return string.format(
            "SELECT value FROM kms_config WHERE server_id='%s' AND %s='%s'",
            provider:Escape(ServerId()), KeyCol(), provider:Escape(key))
    end, function(rows, err)
        local raw = rows and rows[1] and rows[1].value
        local decoded = raw and util.JSONToTable(raw)
        Fire(callback, istable(decoded) and decoded.v or nil, err)
    end)
end

function Data.SaveSettings()
    Data.SetConfig("settings", KMS.Settings)
    Data.SetConfig("preset", KMS.ActivePreset or "")
end

KMS.ActivePreset = KMS.ActivePreset or ""
KMS.FirstRun = false
Data.Loaded = false

function Data.SaveNPCs()
    Data.SetConfig("npcs", KMS.NPCs)
end

function Data.SaveItems()
    Data.SetConfig("items", KMS.ItemConfig)
end

function Data.SaveVehicles()
    Data.SetConfig("vehicles", KMS.SavedVehicles)
end

function Data.LoadPlayer(sid, callback)
    provider:Query(function()
        return string.format("SELECT data FROM kms_players WHERE server_id='%s' AND steamid='%s'",
            provider:Escape(ServerId()), provider:Escape(sid))
    end, function(rows, err)
        local raw = rows and rows[1] and rows[1].data
        Fire(callback, KMS.SanitizePlayer(raw and util.JSONToTable(raw)), err)
    end)
end

function Data.SavePlayer(sid, record)
    if not Data.Loaded then return end
    local json = util.TableToJSON(record) or "{}"
    provider:Query(function()
        local serverId = provider:Escape(ServerId())
        local escapedId = provider:Escape(sid)
        local escapedValue = provider:Escape(json)
        if provider:GetType() == "mysql" then
            return string.format(
                "INSERT INTO kms_players (server_id, steamid, data) VALUES ('%s', '%s', '%s') ON DUPLICATE KEY UPDATE data='%s'",
                serverId, escapedId, escapedValue, escapedValue)
        end
        return string.format(
            "INSERT OR REPLACE INTO kms_players (server_id, steamid, data) VALUES ('%s', '%s', '%s')",
            serverId, escapedId, escapedValue)
    end)
end

function Data.LoadAll()
    Data.GetConfig("items", function(rawItems, itemsErr)
        if itemsErr then return end
        KMS.ApplyItemConfig(rawItems)
    Data.GetConfig("settings", function(saved, err)
        if err then return end
        KMS.FirstRun = saved == nil
        KMS.ApplySettings(saved)
        Data.GetConfig("preset", function(preset, presetErr)
            if presetErr then return end
            KMS.ActivePreset = isstring(preset) and preset or ""
            Data.GetConfig("npcs", function(rawNPCs, npcsErr)
                if npcsErr then return end
                KMS.NPCs = {}
                for id, raw in pairs(istable(rawNPCs) and rawNPCs or {}) do
                    local npc = KMS.SanitizeNPC(raw)
                    if npc and npc.id == id then KMS.NPCs[id] = npc end
                end
                Data.GetConfig("vehicles", function(rawVehicles, vehiclesErr)
                    if vehiclesErr then return end
                    KMS.SavedVehicles = {}
                    for id, raw in pairs(istable(rawVehicles) and rawVehicles or {}) do
                        local vehicle = KMS.SanitizeVehicle(raw)
                        if vehicle and vehicle.id == id then KMS.SavedVehicles[id] = vehicle end
                    end
                    Data.Loaded = true
                    KMS.SyncConfig(nil)
                    hook.Run("KMS_DataLoaded")
                end)
            end)
        end)
    end)
    end)
end

function KMS.InvIdentity(ply)
    local char = ply.GetCharacter and ply:GetCharacter() or ply.getChar and ply:getChar()
    if char then
        local id = char.GetID and char:GetID() or char.getID and char:getID()
        if id then return "char:" .. id end
    end
    if ix ~= nil or nut ~= nil then return nil end
    return "sid:" .. ply:SteamID64()
end

function KMS.LoadInventory(ply)
    local id = KMS.InvIdentity(ply)
    ply.KMSInvId = id
    if not id then return {} end
    local record = KMS.PlayerRecord(ply)
    record.invs = record.invs or {}
    local inv = record.invs[id]
    if not inv then
        inv = KMS.TierLoadout(ply)
        record.invs[id] = inv
        KMS.SavePlayer(ply)
    end
    return inv
end

function KMS.PersistInv(ply)
    if not ply.KMSInvId or not KMS.PersistentInv() then return end
    timer.Create("KMS_InvSave_" .. ply:EntIndex(), 5, 1, function()
        if IsValid(ply) then KMS.SavePlayer(ply) end
    end)
end

local function SwapCharacterInv(ply)
    if not IsValid(ply) or not KMS.PersistentInv() then return end
    ply.KMSInv = KMS.LoadInventory(ply)
    KMS.MarkDirty(ply)
end

hook.Add("PlayerLoadedCharacter", "KMS_CharInv", SwapCharacterInv)
hook.Add("PlayerLoadedChar", "KMS_CharInv", SwapCharacterInv)

function KMS.PlayerRecord(ply)
    local sid = IsValid(ply) and ply:SteamID64()
    if not sid or sid == "0" then return KMS.SanitizePlayer(nil) end
    local record = KMS.PlayerData[sid]
    if not record then
        record = KMS.SanitizePlayer(nil)
        KMS.PlayerData[sid] = record
    end
    return record
end

function KMS.SavePlayer(ply)
    local sid = IsValid(ply) and ply:SteamID64()
    if not sid or sid == "0" then return end
    Data.SavePlayer(sid, KMS.PlayerData[sid])
end

local function LoadPlayerRecord(ply)
    local sid = IsValid(ply) and ply:SteamID64()
    if not sid or sid == "0" or not Data.Loaded then return end
    Data.LoadPlayer(sid, function(record)
        if not record then return end
        KMS.PlayerData[sid] = record
        if not IsValid(ply) then return end
        KMS.ClearAccessCache(ply)
        KMS.SyncSelf(ply)
        KMS.MarkDirty(ply)
    end)
end

hook.Add("PlayerInitialSpawn", "KMS_LoadPlayer", LoadPlayerRecord)

hook.Add("PlayerDisconnected", "KMS_UnloadPlayer", function(ply)
    local timerName = "KMS_InvSave_" .. ply:EntIndex()
    if timer.Exists(timerName) then
        timer.Remove(timerName)
        KMS.SavePlayer(ply)
    end
    local sid = ply:SteamID64()
    if sid then KMS.PlayerData[sid] = nil end
end)

hook.Add("KMS_DataLoaded", "KMS_LoadPlayers", function()
    for _, ply in ipairs(player.GetAll()) do
        LoadPlayerRecord(ply)
    end
end)

local ADMIN_ONLY_SETTINGS = { medicWhitelist = true, doctorWhitelist = true, loadoutDefault = true, loadoutMedic = true, loadoutDoctor = true, koWeapons = true, staminaProfiles = true, damageProfiles = true, immuneWhitelist = true, medVehicleWhitelist = true, adminWhitelist = true, mapPresets = true }
local SUPERADMIN_SETTINGS = { adminWhitelist = true, immuneWhitelist = true }

local installedMaps

local function InstalledMaps()
    if not installedMaps then
        installedMaps = {}
        for _, f in ipairs(file.Find("maps/*.bsp", "GAME") or {}) do
            installedMaps[#installedMaps + 1] = string.lower(string.StripExtension(f))
        end
        table.sort(installedMaps)
    end
    return installedMaps
end

local function ConfigPayload(isAdmin)
    local settings = {}
    for key, value in pairs(KMS.Settings) do
        if isAdmin or not ADMIN_ONLY_SETTINGS[key] then
            settings[key] = value
        end
    end
    local npcs = {}
    for id, npc in pairs(KMS.NPCs) do
        if isAdmin then
            npcs[id] = npc
        else
            npcs[id] = { id = npc.id, name = npc.name, model = npc.model, npcType = npc.npcType }
        end
    end
    return {
        settings = settings,
        preset = KMS.ActivePreset,
        firstRun = KMS.FirstRun,
        npcs = npcs,
        items = KMS.ItemConfig,
        maps = isAdmin and InstalledMaps() or nil,
    }
end

local function SendConfig(targets)
    local groups = {}
    for _, target in ipairs(targets) do
        local isAdmin = KMS.IsAdmin(target) == true
        local group = groups[isAdmin] or {}
        groups[isAdmin] = group
        group[#group + 1] = target
    end
    for isAdmin, group in pairs(groups) do
        KF.Net.Send("KMS_SyncConfig", function()
            KF.Net.WriteCompressed(ConfigPayload(isAdmin), 32)
        end, group)
    end
end

function KMS.SyncConfig(ply)
    if ply then
        SendConfig({ ply })
        return
    end
    timer.Create("KMS_ConfigSync", 0.25, 1, function()
        SendConfig(player.GetAll())
    end)
end

function KMS.Notify(ply, msgType, key, ...)
    if ply ~= nil and (not IsValid(ply) or not ply:IsPlayer()) then return end
    local args = { ... }
    KF.Net.Send("KMS_Notify", function()
        net.WriteString(msgType)
        net.WriteString(key)
        net.WriteUInt(math.min(#args, 5), 3)
        for i = 1, math.min(#args, 5) do
            net.WriteString(tostring(args[i]))
        end
    end, ply)
end

KF.Admin.WatchSync(KMS.AID)

local function InitDatabase()
    if Data._provider then
        provider = Data._provider
        Data.LoadAll()
        return
    end
    local dbType = string.lower(tostring(KMS.ServerConfig.Database.Type or "sqlite"))
    if dbType == "mysql" then
        if MySQL.IsAvailable() then
            provider = MySQL.New()
            Data._provider = provider
            provider:Initialize(function() Data.LoadAll() end)
            return
        end
        KMS.Log("warn", "mysqloo module not found, falling back to SQLite")
    end
    provider = SQLite.New()
    Data._provider = provider
    provider:Initialize(function() Data.LoadAll() end)
end

if Data._provider then InitDatabase() else hook.Add("Initialize", "KMS_InitDatabase", InitDatabase) end

function KMS.SyncSelf(ply)
    local state = ply.KMSState
    if not state then return end
    local anyTq, anyFrac, anySplint = false, false, false
    for _, partState in pairs(state.parts) do
        if partState.tq then anyTq = true end
        if partState.frac then
            if partState.splint then anySplint = true else anyFrac = true end
        end
    end
    KF.Net.Send("KMS_SyncSelf", function()
        KF.Net.WriteCompressed({
            inv = KMS.Settings.infiniteSupplies and {} or (ply.KMSInv or {}),
            painBand = KMS.PainBand(KMS.PerceivedPain(state)),
            bloodClass = KMS.BloodClass(state.blood / KMS.Settings.maxBlood),
            bleedBand = KMS.BleedBand(KMS.BleedRate(state), state),
            hr = math.Round(state.hr),
            spo2 = math.Round(state.spo2 or KMS.NormalSpO2),
            tq = anyTq,
            frac = anyFrac,
            splint = anySplint,
            conscious = state.conscious,
            arrest = state.arrest,
            deathIn = not state.conscious and KMS.DeathETA(ply) or nil,
            downFor = not state.conscious and math.max(0, CurTime() - (state.downAt or CurTime())) or nil,
            tier = KMS.MedicTier(ply),
        }, 32)
    end, ply)
end

local function BuildSnapshot(patient)
    local state = patient.KMSState
    local parts = {}
    for partId, partState in pairs(state.parts) do
        local wounds = {}
        for _, wound in ipairs(partState.wounds) do
            wounds[#wounds + 1] = { t = wound.t, s = wound.s, n = wound.n, b = wound.b, f = math.Round(KMS.WoundFlow(wound), 2) }
        end
        local st
        if partState.st then
            st = {}
            for _, wound in ipairs(partState.st) do
                st[#st + 1] = { t = wound.t, s = wound.s, n = wound.n }
            end
        end
        parts[partId] = {
            wounds = wounds,
            st = st,
            frac = partState.frac,
            splint = partState.splint,
            tq = partState.tq,
            dmg = partState.dmg or 0,
        }
    end
    local cprProvider = KMS.CPRProvider(patient)
    local medIds = {}
    for medId in pairs(state.meds) do
        medIds[#medIds + 1] = medId
    end
    local meds = {}
    for _, medId in ipairs(medIds) do
        local n = KMS.ActiveMeds(state, medId)
        if n > 0 then meds[medId] = n end
    end
    local ivs
    for _, bag in ipairs(state.ivBags or {}) do
        if bag.left > 0 then
            ivs = ivs or {}
            local kind = bag.kind or "saline"
            ivs[kind] = math.floor((ivs[kind] or 0) + bag.left)
        end
    end
    return {
        parts = parts,
        meds = meds,
        inv = ((KMS.Settings.itemSharing or KMS.Settings.invLootDowned) and not KMS.Settings.infiniteSupplies) and (patient.KMSInv or {}) or nil,
        log = state.log,
        quick = state.quick,
        states = {
            conscious = state.conscious,
            arrest = state.arrest,
            painBand = KMS.PainBand(KMS.PerceivedPain(state)),
            bloodClass = KMS.BloodClass(state.blood / KMS.Settings.maxBlood),
            stable = KMS.IsStable(patient),
            triage = state.triage,
            morphineIn = math.max(0, KMS.Settings.morphineCooldown - (CurTime() - state.lastMorphine)),
            ivs = ivs,
            cpr = cprProvider and cprProvider:Nick() or nil,
        },
    }
end

function KMS.SyncPatient(patient, only)
    local watchers = patient.KMSWatchers
    if not watchers or not next(watchers) then return end
    local recipients = {}
    for watcher in pairs(watchers) do
        if IsValid(watcher) and (watcher == patient or KMS.CanReach(watcher, patient, KMS.WatchMargin)) then
            if not only or watcher == only then
                recipients[#recipients + 1] = watcher
            end
        else
            watchers[watcher] = nil
        end
    end
    if #recipients == 0 then return end
    local snapshot = BuildSnapshot(patient)
    KF.Net.Send("KMS_SyncPatient", function()
        net.WriteEntity(patient)
        KF.Net.WriteCompressed(snapshot, 32)
    end, recipients)
end

KF.Net.Receive("KMS_Watch", function(_, ply)
    local patient = net.ReadEntity()
    local watching = net.ReadBool()
    if not KMS.ValidPatient(patient) then return end
    patient.KMSWatchers = patient.KMSWatchers or {}
    if watching then
        if patient ~= ply and not KMS.CanReach(ply, patient, KMS.WatchMargin) then return end
        local known = patient.KMSWatchers[ply]
        patient.KMSWatchers[ply] = true
        if not known then KMS.SyncPatient(patient, ply) end
    else
        patient.KMSWatchers[ply] = nil
    end
end, { rateLimit = 0.2 })

KF.Net.Receive("KMS_Treat", function(_, ply)
    local patient = net.ReadEntity()
    local treatId = net.ReadString()
    local partId = net.ReadString()
    local usePatient = net.ReadBool()
    -- Strivon: aus dem Comlink-Medic-Menü mit Schnellbehandlung (Pfeiltasten-Reihenfolge)
    local quick = net.ReadBool()
    if not KMS.ValidPatient(patient) then return end
    ply.KMSQuickTreat = quick
    KMS.StartTreatment(ply, patient, treatId, partId, usePatient)
    ply.KMSQuickTreat = nil
end, { rateLimit = 0.3 })

KF.Net.Receive("KMS_CancelTreat", function(_, ply)
    if ply.KMSJob then
        KMS.CancelTreatment(ply, true)
    end
end, { rateLimit = 0.3 })

KF.Net.Receive("KMS_VehicleLoad", function(_, ply)
    local patient = net.ReadEntity()
    local vehicle = net.ReadEntity()
    if not IsValid(patient) or not patient:IsPlayer() or not patient.KMSState then return end
    if IsValid(vehicle) then
        KMS.LoadPatient(ply, patient, vehicle)
    else
        KMS.UnloadPatient(ply, patient)
    end
end, { rateLimit = 0.5 })

KF.Net.Receive("KMS_Drag", function(_, ply)
    local patient = net.ReadEntity()
    local carry = net.ReadBool()
    if not IsValid(patient) or not patient:IsPlayer() then return end
    KMS.StartDrag(ply, patient, carry and "carry" or "drag")
end, { rateLimit = 0.4 })

KF.Net.Receive("KMS_Release", function(_, ply)
    KMS.ReleaseHaul(ply)
end, { rateLimit = 0.2 })

KF.Net.Receive("KMS_Downed", function(_, ply)
    if net.ReadBool() then
        KMS.GiveUp(ply)
    else
        KMS.CallMedic(ply)
    end
end, { rateLimit = 0.5 })

KF.Net.Receive("KMS_Triage", function(_, ply)
    local patient = net.ReadEntity()
    local level = net.ReadUInt(3)
    if not KMS.Settings.enabled then return end
    if not ply:Alive() or not (ply.KMSState and ply.KMSState.conscious) then return end
    if not KMS.ValidPatient(patient) then return end
    if not KMS.TriageById[level] or level == 4 then return end
    if patient ~= ply and not KMS.CanReach(ply, patient) then return end
    patient.KMSState.triage = level
    patient:SetNWInt("kms_triage", level)
    KMS.AddLog(patient, "log_triage", ply:Nick(), "#triage_" .. (level == 0 and "none" or ("t" .. level)))
    KMS.MarkDirty(patient)
end, { rateLimit = 0.5 })

KF.Net.Receive("KMS_QuickUse", function(_, ply)
    KMS.QuickUse(ply)
end, { rateLimit = 0.3 })

KF.Net.Receive("KMS_RequestSync", function(_, ply)
    local wantAdmin = net.ReadBool()
    KMS.SyncConfig(ply)
    KMS.SyncSelf(ply)
    if not wantAdmin then return end
    if not KMS.IsAdmin(ply) then
        KMS.Notify(ply, "error", "err_admin_only")
        return
    end
    KF.Net.Send("KMS_OpenMenu", function() net.WriteBool(true) end, ply)
end, { rateLimit = 1 })

hook.Add("PlayerSay", "KMS_ChatCommand", function(ply, text)
    text = string.lower(string.Trim(text))
    local cmd, arg = string.match(text, "^(%S+)%s*(.*)$")
    if not cmd then return end
    local revive = string.lower(string.Trim(KMS.Settings.reviveCommand or ""))
    local heal = string.lower(string.Trim(KMS.Settings.healCommand or ""))
    if (cmd == revive and revive ~= "") or (cmd == heal and heal ~= "") then
        if not KMS.CanHeal(ply) then return end
        KMS.AdminHeal(ply, arg, cmd == revive)
        return ""
    end
    if not KMS.Settings.enabled or not KMS.Settings.commandEnabled then return end
    local command = string.lower(string.Trim(KMS.Settings.chatCommand or ""))
    if command == "" or text ~= command then return end
    KF.Net.Send("KMS_OpenMenu", function() net.WriteBool(false) end, ply)
    return ""
end)

local AdminActions = KMS.AdminActions

local RESYNC_SELF = {
    medicMode = true, medicWhitelist = true, doctorWhitelist = true,
    tierOverrides = true, infiniteSupplies = true,
}

local ACCESS_KEYS = {
    medicMode = true, medicWhitelist = true, doctorWhitelist = true,
    immuneWhitelist = true, adminWhitelist = true,
    medVehicleAccess = true, medVehicleWhitelist = true,
}

local function SettingEffects(key, oldValue)
    local newValue = KMS.Settings[key]
    if newValue == oldValue then return false end
    if ACCESS_KEYS[key] then KMS.ClearAccessCache() end
    if key == "enabled" and newValue == false then
        for _, other in ipairs(player.GetAll()) do
            KMS.Detach(other)
        end
        return false
    end
    if key == "maxBlood" and isnumber(oldValue) and oldValue > 0 then
        for _, other in ipairs(player.GetAll()) do
            local state = other.KMSState
            if state then
                state.blood = state.blood * (newValue / oldValue)
                KMS.MarkDirty(other)
            end
        end
    elseif key == "fractureMode" and newValue == "disabled" then
        for _, other in ipairs(player.GetAll()) do
            local state = other.KMSState
            if state then
                for _, partState in pairs(state.parts) do
                    partState.frac = false
                    partState.splint = false
                end
                other:SetNWInt("kms_mobility", 0)
                other:SetNWBool("kms_noarms", false)
                KMS.MarkDirty(other)
            end
        end
    end
    if key == "medVehicles" or key == "medVehicleInvDefault" then
        KMS.RescanMedVehicles()
    end
    if key == "staminaEnabled" or key == "staminaProfiles" then
        KMS.RefreshStamina()
    end
    if key == "damageProfiles" then
        KMS.RefreshDamageProfiles()
    end
    if key == "mapPresets" then
        local preset = KMS.PresetById[newValue[string.lower(game.GetMap())] or ""]
        if preset and KMS.ActivePreset ~= preset.id then
            KMS.ApplyPreset(preset)
        end
    end
    if key == "npcModels" then
        for _, ent in ipairs(ents.FindByClass("kms_medbay")) do
            ent:SetModel(newValue.medbay)
            ent:PhysicsInit(SOLID_VPHYSICS)
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then phys:EnableMotion(false) end
        end
    end
    return RESYNC_SELF[key] == true
end

local function ResyncSelfAll()
    for _, other in ipairs(player.GetAll()) do
        KMS.SyncSelf(other)
    end
end

function KMS.ApplyPreset(preset)
    local applied = true
    local oldValues = {}
    for key, value in pairs(preset.values) do
        oldValues[key] = KMS.Settings[key]
        local clean = KMS.SanitizeSetting(key, value)
        if clean == nil or clean ~= value then
            applied = false
            ErrorNoHalt("[KMS] preset '" .. preset.id .. "': invalid value for '" .. key .. "'\n")
        end
        if clean ~= nil then KMS.Settings[key] = clean end
    end
    local resync = false
    for key, oldValue in pairs(oldValues) do
        if SettingEffects(key, oldValue) then resync = true end
    end
    if resync then ResyncSelfAll() end
    KMS.ActivePreset = applied and preset.id or "custom"
    KMS.FirstRun = false
    KMS.Data.SaveSettings()
    KMS.SyncConfig(nil)
end

hook.Add("KMS_DataLoaded", "KMS_MapPreset", function()
    local preset = KMS.PresetById[KMS.Settings.mapPresets[string.lower(game.GetMap())] or ""]
    if preset and KMS.ActivePreset ~= preset.id then
        KMS.ApplyPreset(preset)
        KMS.Log("info", "preset '" .. preset.id .. "' applied for map " .. game.GetMap())
    end
end)

local function PushItems()
    KMS.ApplyItemConfig(KMS.ItemConfig)
    KMS.Data.SaveItems()
    KMS.SyncConfig(nil)
    return true, "adm_ok_setting"
end

AdminActions = table.Merge(AdminActions, {
    update_setting = function(ply, payload)
        local key = tostring(payload.key or "")
        if SUPERADMIN_SETTINGS[key] and not ply:IsSuperAdmin() then return false, "adm_err_superadmin" end
        local clean = KMS.SanitizeSetting(key, payload.value)
        if clean == nil then return false, "adm_err_invalid" end
        local oldValue = KMS.Settings[key]
        KMS.Settings[key] = clean
        if SettingEffects(key, oldValue) then
            ResyncSelfAll()
        end
        if KMS.ActivePreset == "" then
            if clean ~= oldValue then KMS.ActivePreset = "custom" end
        elseif KMS.ActivePreset ~= "custom" and table.HasValue(KMS.PresetKeys, key) then
            local preset = KMS.PresetById[KMS.ActivePreset]
            if preset and preset.values[key] ~= nil and preset.values[key] ~= clean then
                KMS.ActivePreset = "custom"
            end
        end
        KMS.Data.SaveSettings()
        KMS.FirstRun = false
        KMS.SyncConfig(nil)
        return true, "adm_ok_setting"
    end,
    apply_preset = function(ply, payload)
        local preset = KMS.PresetById[tostring(payload.id or "")]
        if not preset then return false, "adm_err_invalid" end
        KMS.ApplyPreset(preset)
        return true, "msg_preset_applied", { "#preset_" .. preset.id }
    end,
    save_item = function(ply, payload)
        local record = istable(payload.record) and KF.Sanitize.Apply(payload.record, KMS.ItemSchema) or nil
        if not record or record.id == "" then return false, "adm_err_invalid" end
        if KMS.BaseItemIds[record.id] then return false, "adm_item_exists" end
        KMS.ItemConfig.custom[record.id] = record
        return PushItems()
    end,
    delete_item = function(ply, payload)
        local id = tostring(payload.id or "")
        if not KMS.ItemConfig.custom[id] then return false, "adm_err_invalid" end
        KMS.ItemConfig.custom[id] = nil
        return PushItems()
    end,
    toggle_item = function(ply, payload)
        local id = tostring(payload.id or "")
        if not KMS.BaseItemIds[id] then return false, "adm_err_invalid" end
        KMS.ItemConfig.disabled[id] = payload.disabled == true or nil
        return PushItems()
    end,
    rename_item = function(ply, payload)
        local id = tostring(payload.id or "")
        local name = string.sub(KF.Sanitize.Clean.String(payload.name, ""), 1, 48)
        if KMS.BaseItemIds[id] then
            KMS.ItemConfig.renames[id] = name ~= "" and name or nil
        elseif KMS.ItemConfig.custom[id] then
            KMS.ItemConfig.custom[id].name = name
        else
            return false, "adm_err_invalid"
        end
        return PushItems()
    end,
    dismiss_firstrun = function()
        KMS.FirstRun = false
        KMS.Data.SaveSettings()
        KMS.SyncConfig(nil)
        return true, "adm_ok_setting"
    end,
    reset_defaults = function()
        local oldValues = {}
        for key in pairs(KMS.DefaultSettings) do
            oldValues[key] = KMS.Settings[key]
        end
        KMS.ApplySettings(nil)
        local resync = false
        for key, oldValue in pairs(oldValues) do
            if SettingEffects(key, oldValue) then resync = true end
        end
        if resync then ResyncSelfAll() end
        KMS.ActivePreset = ""
        KMS.FirstRun = false
        KMS.Data.SaveSettings()
        KMS.SyncConfig(nil)
        return true, "msg_settings_reset"
    end,
})

KF.Net.Receive("KMS_AdminAction", function(_, ply)
    if not KMS.IsAdmin(ply) then return end
    local action = net.ReadString()
    local payload = KF.Net.ReadCompressed(32, 131072)
    local handler = AdminActions[action]
    if not handler or not istable(payload) then return end
    local success, key, args = handler(ply, payload)
    KF.Net.Send("KMS_AdminResponse", function()
        KF.Net.WriteCompressed({ success = success == true, key = key, args = args }, 16)
    end, ply)
end, { rateLimit = 0.15 })

local function ResyncTier(ply)
    if not IsValid(ply) then return end
    KMS.MarkDirty(ply)
    KMS.SyncConfig(ply)
end

hook.Add("OnPlayerChangedTeam", "KMS_TierSync", ResyncTier)
hook.Add("PlayerChangedUserGroup", "KMS_TierSync", ResyncTier)
hook.Add("CAMI.PlayerUsergroupChanged", "KMS_TierSync", ResyncTier)

hook.Add("PlayerInitialSpawn", "KMS_InitialSync", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        KMS.SyncConfig(ply)
        KMS.SyncSelf(ply)
    end)
end)
