KrakensStore.ServerConfig = KrakensStore.ServerConfig or {}

KrakensStore.ServerConfig.Database = {
    Type = "sqlite",
    InstanceId = "",
    MySQL = {
        Host = "localhost",
        Port = 3306,
        Database = "krakens_store",
        Username = "root",
        Password = "",
    },
    Backup = {
        Enabled = true,
        MaxBackups = 24,
    },
}

KrakensStore.ServerConfig.Discord = {
    Enabled = false,
    WebhookURL = "",
    PurchaseColor = 3066993,
    SaleColor = 15158332,
    AdminColor = 3447003,
    ErrorColor = 15158332,
    IncludeProfileLink = true,
    BotName = "Kraken's Store",
    AvatarURL = "",
}

KrakensStore.ServerConfig.Internal = {
    DebugMode = false,
    LogRetentionDays = 30,
}

function KrakensStore.ServerConfig.DebugLog(...)
    if KrakensStore.ServerConfig.Internal.DebugMode then KrakensStore.Log("info", ...) end
end

local INSTANCE_FILE = "krakens_store/server_instance_id.txt"
local cachedInstanceId

local function PersistInstanceId(id)
    if not file.Exists("krakens_store", "DATA") then file.CreateDir("krakens_store") end
    file.Write(INSTANCE_FILE, id)
end

local function GetServerId()
    if cachedInstanceId then return cachedInstanceId end

    local configured = string.Trim(tostring(KrakensStore.ServerConfig.Database.InstanceId or ""))
    if configured ~= "" then
        cachedInstanceId = configured
        PersistInstanceId(configured)
        return configured
    end

    if KrakensStore.ServerConfig.Database.Type ~= "mysql" then
        cachedInstanceId = "ks_default"
        return cachedInstanceId
    end

    if file.Exists(INSTANCE_FILE, "DATA") then
        local saved = string.Trim(file.Read(INSTANCE_FILE, "DATA") or "")
        if saved ~= "" then cachedInstanceId = saved; return saved end
    end

    local hostIp = GetConVar("hostip") and GetConVar("hostip"):GetInt() or 0
    local hostPort = GetConVar("hostport") and GetConVar("hostport"):GetInt() or 0
    local seed = (hostIp > 0 or hostPort > 0) and (hostIp .. ":" .. hostPort) or ((GetHostName() or "ks") .. ":" .. hostPort)
    local generated = "ks_" .. string.lower(util.CRC("krakens_store:" .. seed))

    PersistInstanceId(generated)
    cachedInstanceId = generated
    return generated
end

KrakensStore.DB = KrakensStore.DB or {}
KrakensStore.DB.Providers = KrakensStore.DB.Providers or {}

local DB = KrakensStore.DB
local activeProvider = DB._provider
local OnDatabaseInitialized
local Fire = KrakensStore.Fire
local RECONNECT_TIMER = "KrakensStore_MySQLReconnect"

local T_ITEMS = "krakens_store_items"
local T_CATEGORIES = "krakens_store_categories"
local T_NPCS = "krakens_store_npcs"
local T_INVENTORY = "krakens_store_inventory"
local T_PLAYERS = "krakens_store_players"
local T_CONFIG = "krakens_store_config"
local T_LOGS = "krakens_store_logs"
local T_META = "krakens_store_meta"
local T_RECOVERIES = "krakens_store_recoveries"

local COLUMN_TYPES = {
    str = { "TEXT", "VARCHAR(128)" },
    short = { "TEXT", "VARCHAR(64)" },
    name = { "TEXT", "VARCHAR(255)" },
    steamid = { "TEXT", "VARCHAR(32)" },
    text = { "TEXT", "LONGTEXT" },
    int = { "INTEGER", "INT" },
    bigint = { "INTEGER", "BIGINT" },
    bool = { "INTEGER", "TINYINT" },
}

local SERVER_ID = { "server_id", "str", "NOT NULL DEFAULT 'ks_default'" }
local BLOB_COLUMNS = { SERVER_ID, { "id", "str", "NOT NULL" }, { "data", "text", "NOT NULL" }, { "modified", "bigint", "DEFAULT 0" } }

local TABLES = {
    { name = T_ITEMS, key = { "id" }, backup = true, pk = { "server_id", "id" }, columns = BLOB_COLUMNS },
    { name = T_CATEGORIES, key = { "id" }, backup = true, pk = { "server_id", "id" }, columns = BLOB_COLUMNS },
    { name = T_NPCS, key = { "id" }, backup = true, pk = { "server_id", "id" }, columns = BLOB_COLUMNS },
    { name = T_INVENTORY, key = { "steamid", "item_id" }, backup = true, pk = { "server_id", "steamid", "item_id" },
      columns = { SERVER_ID, { "steamid", "steamid", "NOT NULL" }, { "item_id", "str", "NOT NULL" }, { "quantity", "int", "NOT NULL DEFAULT 1" },
                  { "equipped", "bool", "NOT NULL DEFAULT 0" }, { "data", "text", "NOT NULL", sqlite = "NOT NULL DEFAULT '{}'" },
                  { "purchased", "bigint", "DEFAULT 0" }, { "expires", "bigint", "DEFAULT -1" } },
      indexes = { { "ks_idx_inventory_steamid", "server_id, steamid" }, { "ks_idx_inventory_expires", "expires" } } },
    { name = T_PLAYERS, key = { "steamid" }, backup = true, pk = { "server_id", "steamid" },
      columns = { SERVER_ID, { "steamid", "steamid", "NOT NULL" }, { "data", "text", "NOT NULL" }, { "first_seen", "bigint", "DEFAULT 0" }, { "last_seen", "bigint", "DEFAULT 0" },
                  { "total_spent", "bigint", "DEFAULT 0" }, { "total_earned", "bigint", "DEFAULT 0" }, { "items_purchased", "int", "DEFAULT 0" }, { "items_sold", "int", "DEFAULT 0" } } },
    { name = T_CONFIG, key = { "key" }, backup = true, pk = { "server_id", "key" },
      columns = { SERVER_ID, { "key", "str", "NOT NULL" }, { "value", "text", "NOT NULL" }, { "modified", "bigint", "DEFAULT 0" } } },
    { name = T_LOGS, autoId = true,
      columns = { SERVER_ID, { "type", "short", "NOT NULL" }, { "steamid", "steamid" }, { "item_id", "str" }, { "item_name", "name" }, { "quantity", "int", "DEFAULT 0" },
                  { "amount", "bigint", "DEFAULT 0" }, { "data", "text" }, { "timestamp", "bigint", "DEFAULT 0" } },
      indexes = { { "ks_idx_logs_scope", "server_id, timestamp" }, { "ks_idx_logs_steamid", "steamid" }, { "ks_idx_logs_type", "server_id, type, timestamp" } } },
    { name = T_META, key = { "key" }, repair = false, pk = { "server_id", "key" },
      columns = { SERVER_ID, { "key", "short", "NOT NULL" }, { "value", "text", "NOT NULL" } } },
    { name = T_RECOVERIES, autoId = true,
      columns = { SERVER_ID, { "steamid", "steamid", "NOT NULL" }, { "type", "short", "NOT NULL" }, { "amount", "bigint", "NOT NULL DEFAULT 0" }, { "reason", "str" }, { "created", "bigint", "DEFAULT 0" } },
      indexes = { { "ks_idx_recoveries_owner", "server_id, steamid" } } },
}

local function ColumnName(name, mysql)
    return (mysql and name == "key") and "`key`" or name
end

local function SchemaStatements(mysql)
    local dialect = mysql and 2 or 1
    local statements = {}
    for _, tbl in ipairs(TABLES) do
        local parts = {}
        if tbl.autoId then parts[1] = mysql and "id BIGINT AUTO_INCREMENT PRIMARY KEY" or "id INTEGER PRIMARY KEY AUTOINCREMENT" end
        for _, col in ipairs(tbl.columns) do
            local constraint = (mysql and col.mysql) or (not mysql and col.sqlite) or col[3]
            parts[#parts + 1] = ColumnName(col[1], mysql) .. " " .. COLUMN_TYPES[col[2]][dialect] .. (constraint and (" " .. constraint) or "")
        end
        if tbl.pk then
            local cols = {}
            for i, name in ipairs(tbl.pk) do cols[i] = ColumnName(name, mysql) end
            parts[#parts + 1] = "PRIMARY KEY (" .. table.concat(cols, ", ") .. ")"
        end
        statements[#statements + 1] = "CREATE TABLE IF NOT EXISTS " .. tbl.name .. " (" .. table.concat(parts, ", ") .. ")" .. (mysql and " ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" or "")
    end
    return statements
end

local function AddColumnDDL(tableName, col, mysql)
    local constraint = (mysql and col.mysql) or (not mysql and col.sqlite) or col[3] or ""
    if not string.find(constraint, "DEFAULT", 1, true) then constraint = "" end
    return string.format("ALTER TABLE %s ADD COLUMN %s %s %s", tableName, ColumnName(col[1], mysql), COLUMN_TYPES[col[2]][mysql and 2 or 1], constraint)
end

DB.Schema = { SQLite = SchemaStatements(false), MySQL = SchemaStatements(true) }
DB.Tables = TABLES

local function DiscardProvider(reason)
    local old = activeProvider
    activeProvider, DB._provider = nil, nil
    if not old then return end
    timer.Remove(RECONNECT_TIMER)
    if old.connection then
        local noop = function() end
        old.connection.onConnected, old.connection.onDisconnected, old.connection.onConnectionFailed = noop, noop, noop
        old.connection = nil
    end
    if old.FailPending then old:FailPending(reason or "database provider was replaced") end
end

function DB.Initialize()
    local wanted = KrakensStore.ServerConfig.Database.Type == "mysql" and "mysql" or "sqlite"
    if activeProvider and activeProvider:IsConnected() and activeProvider:GetType() == wanted then
        activeProvider:EnsureSchema(function() OnDatabaseInitialized(wanted) end)
        return true
    end

    DiscardProvider("database is being reinitialised")

    if wanted == "mysql" then
        if not DB.Providers.MySQL.IsAvailable() then
            return false, "mysqloo module is not installed but Database.Type is mysql"
        end
        activeProvider = DB.Providers.MySQL.New()
    else
        activeProvider = DB.Providers.SQLite.New()
    end
    DB._provider = activeProvider
    activeProvider:Initialize()
    return true
end

function DB.GetType()
    return activeProvider and activeProvider:GetType() or "unknown"
end

DB.GetServerId = GetServerId

function DB.GetEscapedServerId()
    return DB.Escape(DB.GetServerId())
end

local function Scope(where)
    return string.format("(%s) AND server_id='%s'", where, DB.GetEscapedServerId())
end

function DB.IsConnected()
    return activeProvider ~= nil and activeProvider:IsConnected()
end

function DB.Query(queryString, callback)
    if not activeProvider then
        Fire(callback, nil, "no provider")
        return nil, "no provider"
    end
    return activeProvider:Query(queryString, callback)
end

function DB.Transaction(queries, callback)
    if #queries == 0 then Fire(callback, true) return end
    if not activeProvider or not activeProvider:IsConnected() then
        Fire(callback, false, "not connected")
        return
    end
    activeProvider:Transaction(queries, callback)
end

function DB.KeyCol()
    return DB.GetType() == "mysql" and "`key`" or "key"
end

function DB.SetMeta(key, value, callback)
    local keyCol = DB.KeyCol()
    local query = DB.BuildUpsert(T_META,
        { "server_id", keyCol, "value" },
        { server_id = DB.GetServerId(), [keyCol] = key, value = tostring(value) },
        { updateCols = { "value" } }
    )
    DB.Query(query, function(_, err) Fire(callback, err == nil, err) end)
end

local function ReadSchemaVersion(callback)
    DB.ListColumns(T_META, function(cols)
        local where = string.format("%s='schema_version'", DB.KeyCol())
        if cols.server_id then
            where = where .. string.format(" AND server_id='%s'", DB.GetEscapedServerId())
        end
        DB.Query("SELECT value FROM " .. T_META .. " WHERE " .. where, function(rows, err)
            if err then callback(nil, "schema version is unreadable: " .. tostring(err)) return end
            callback(tonumber(rows and rows[1] and rows[1].value) or 0)
        end)
    end)
end

function DB.RunMigrations(callback)
    ReadSchemaVersion(function(from, readErr)
        if not from then Fire(callback, false, readErr) return end
        local target = DB.SchemaVersion

        local function finish(ok, err)
            if ok == false then Fire(callback, false, err) return end
            KrakensStore.Lifecycle.Migrations = "INDEXES"
            DB.EnsureIndexes(function(ok2, err2) Fire(callback, ok2 ~= false, err2) end)
        end

        local function applyNext(v)
            if v > target then
                DB.SetMeta("schema_version", target, finish)
                return
            end
            local migration = DB.Migrations[v]
            if not migration then applyNext(v + 1) return end
            KrakensStore.Lifecycle.Migrations = "RUNNING v" .. v
            KrakensStore.Log("info", "DB migrating to schema v" .. v)
            migration(function(ok, err)
                if ok == false then
                    KrakensStore.Log("error", "Migration v" .. v .. " failed: " .. tostring(err))
                    Fire(callback, false, err)
                    return
                end
                DB.SetMeta("schema_version", v, function() applyNext(v + 1) end)
            end, from)
        end

        KrakensStore.Lifecycle.Migrations = "REPAIR"
        DB.RepairColumns(function(ok, err)
            if ok == false then Fire(callback, false, err) return end
            if from >= target then finish(true) return end
            KrakensStore.Log("warn", string.format("DB schema v%d to v%d, creating a backup first", from, target))
            KrakensStore.Lifecycle.Migrations = "BACKUP"
            DB.CreateBackup(function(backupFile)
                if not backupFile then
                    KrakensStore.Log("error", "Backup failed, migrations aborted. No data was modified.")
                    Fire(callback, false, "backup failed")
                    return
                end
                KrakensStore.Log("success", "Pre-migration backup: " .. backupFile)
                DB.RekeyTables(function(ok2, err2)
                    if ok2 == false then Fire(callback, false, err2) return end
                    applyNext(from + 1)
                end)
            end)
        end)
    end)
end

function DB.Escape(str)
    if activeProvider then return activeProvider:Escape(str) end
    return string.gsub(tostring(str or ""), "'", "''")
end

local function FormatLiteral(v)
    if isnumber(v) then return tostring(v) end
    return "'" .. DB.Escape(tostring(v)) .. "'"
end

function DB.BuildUpsert(tableName, columns, values, opts)
    local mysql = DB.GetType() == "mysql"
    local overrides = not mysql and opts.sqliteOverrides or {}
    local literals, ordered, assigns = {}, {}, {}
    for i, col in ipairs(columns) do
        literals[col] = FormatLiteral(values[col])
        ordered[i] = overrides[col] or literals[col]
    end
    local insert = string.format("INTO %s (%s) VALUES (%s)", tableName, table.concat(columns, ", "), table.concat(ordered, ", "))
    if not mysql then return "INSERT OR REPLACE " .. insert end
    for i, col in ipairs(opts.updateCols) do assigns[i] = col .. "=" .. literals[col] end
    return "INSERT " .. insert .. " ON DUPLICATE KEY UPDATE " .. table.concat(assigns, ", ")
end


local Esc = DB.Escape

local BACKUP_DIR = "krakens_store/backups"

function DB.CreateBackup(callback)
    if not DB.IsConnected() then Fire(callback, nil) return end
    if not file.Exists(BACKUP_DIR, "DATA") then file.CreateDir(BACKUP_DIR) end

    local backup = { timestamp = os.time(), version = KrakensStore.Version, schema = DB.SchemaVersion }
    local index = 0

    local function step()
        index = index + 1
        local entry = TABLES[index]
        if entry and not entry.backup then step() return end
        if not entry then
            local encoded = util.TableToJSON(backup, true)
            if not encoded then
                KrakensStore.Log("error", "Backup aborted: the snapshot could not be encoded")
                Fire(callback, nil)
                return
            end
            local filename = string.format("%s/backup_%s.json", BACKUP_DIR, os.date("%Y%m%d_%H%M%S"))
            file.Write(filename, encoded)
            if not file.Exists(filename, "DATA") then
                KrakensStore.Log("error", "Backup aborted: could not write " .. filename)
                Fire(callback, nil)
                return
            end

            local maxBackups = KrakensStore.ServerConfig.Database.Backup.MaxBackups
            local files = file.Find(BACKUP_DIR .. "/*.json", "DATA")
            if #files > maxBackups then
                table.sort(files)
                for i = 1, #files - maxBackups do file.Delete(BACKUP_DIR .. "/" .. files[i]) end
            end

            Fire(callback, filename)
            return
        end
        local label = string.sub(entry.name, #"krakens_store_" + 1)
        KrakensStore.Lifecycle.Migrations = "BACKUP " .. label
        DB.ListColumns(entry.name, function(cols)
            if not next(cols) then
                backup[label] = {}
                step()
                return
            end
            local where = cols.server_id and Scope("1=1") or "1=1"
            DB.Query(string.format("SELECT * FROM %s WHERE %s", entry.name, where), function(rows, err)
                if err then
                    KrakensStore.Log("error", "Backup aborted: " .. label .. ": " .. tostring(err))
                    Fire(callback, nil)
                    return
                end
                backup[label] = rows or {}
                step()
            end)
        end)
    end

    step()
end

timer.Create("KrakensStore_Backup", 3600, 0, function()
    local cfg = KrakensStore.ServerConfig.Database.Backup
    if cfg and cfg.Enabled then DB.CreateBackup() end
end)

function DB.SetShutdownMode()
    if activeProvider and activeProvider.SetShutdownMode then activeProvider:SetShutdownMode() end
end

local SQLite = {}
SQLite.__index = SQLite

function SQLite.New()
    return setmetatable({ ready = false }, SQLite)
end

function SQLite:EnsureSchema(callback)
    for _, q in ipairs(KrakensStore.DB.Schema.SQLite) do
        if sql.Query(q) == false then
            KrakensStore.Log("error", "SQLite schema: " .. tostring(sql.LastError()))
        end
    end
    Fire(callback)
end

function SQLite:Initialize()
    self:EnsureSchema()
    self.ready = true
    OnDatabaseInitialized("sqlite")
end

function SQLite:Query(queryString, callback)
    local result = sql.Query(queryString)
    if result == false then
        local err = sql.LastError()
        KrakensStore.Log("error", "SQLite query: " .. tostring(err))
        Fire(callback, nil, err)
        return nil, err
    end
    Fire(callback, result)
    return result
end

function SQLite:Transaction(queries, callback)
    sql.Query("BEGIN TRANSACTION")
    for _, q in ipairs(queries) do
        if sql.Query(q) == false then
            local err = sql.LastError()
            sql.Query("ROLLBACK")
            KrakensStore.Log("error", "SQLite transaction: " .. tostring(err))
            Fire(callback, false, err)
            return
        end
    end
    if sql.Query("COMMIT") == false then
        Fire(callback, false, sql.LastError())
        return
    end
    Fire(callback, true)
end

function SQLite:Escape(str)
    return sql.SQLStr(tostring(str or ""), true)
end

function SQLite:GetType() return "sqlite" end
function SQLite:IsConnected() return self.ready end

KrakensStore.DB.Providers.SQLite = SQLite

local MySQL = {}
MySQL.__index = MySQL

local PENDING_TIMER = "KrakensStore_MySQLPending"
local PENDING_LIMIT = 4096
local PENDING_TIMEOUT = 25

function MySQL.IsAvailable() return mysqloo ~= nil end

function MySQL.New()
    return setmetatable({
        connected = false,
        ready = false,
        connection = nil,
        pending = {},
        shutdownMode = false,
    }, MySQL)
end

function MySQL:Initialize()
    local cfg = KrakensStore.ServerConfig.Database.MySQL
    self.connection = mysqloo.connect(cfg.Host, cfg.Username, cfg.Password, cfg.Database, cfg.Port)

    self.connection.onConnected = function()
        self.connected = true
        self.everConnected = true
        self:EnsureSchema(function()
            if activeProvider ~= self then return end
            self.ready = true
            self:drainPending()
            OnDatabaseInitialized("mysql")
        end)
    end

    self.connection.onConnectionFailed = function(_, err)
        self.connected = false
        self.ready = false
        if not self.everConnected then
            KrakensStore.Lifecycle.Fail("MySQL connection failed: " .. tostring(err))
            return
        end
        KrakensStore.Log("error", "MySQL reconnect failed: " .. tostring(err) .. ", retrying in 10s")
        timer.Create(RECONNECT_TIMER, 10, 1, function() self.connection:connect() end)
    end

    self.connection.onDisconnected = function()
        self.connected = false
        self.ready = false
        KrakensStore.Log("warn", "MySQL disconnected, reconnecting in 5s")
        timer.Create(RECONNECT_TIMER, 5, 1, function() self.connection:connect() end)
    end

    self.connection:connect()
end

function MySQL:EnsureSchema(callback)
    local schema = KrakensStore.DB.Schema.MySQL
    local remaining = #schema
    if remaining == 0 then callback() return end

    for _, queryString in ipairs(schema) do
        local q = self.connection:query(queryString)
        q.onSuccess = function() remaining = remaining - 1; if remaining == 0 then callback() end end
        q.onError = function(_, err)
            if not string.find(string.lower(err), "already exists", 1, true) then
                KrakensStore.Log("error", "MySQL schema: " .. err)
            end
            remaining = remaining - 1
            if remaining == 0 then callback() end
        end
        q:start()
    end
end

function MySQL:exec(queryString, callback)
    local q = self.connection:query(queryString)
    q.onSuccess = function(query, data)
        Fire(callback, data or { affected_rows = query:affectedRows() })
    end
    q.onError = function(_, err)
        KrakensStore.Log("error", "MySQL query: " .. err)
        Fire(callback, nil, err)
    end
    q:start()
    if self.shutdownMode then q:wait() end
end

function MySQL:drainPending()
    timer.Remove(PENDING_TIMER)
    local pending = self.pending
    self.pending = {}
    for _, p in ipairs(pending) do self:exec(p.query, p.callback) end
end

function MySQL:FailPending(reason)
    timer.Remove(PENDING_TIMER)
    local pending = self.pending
    self.pending = {}
    if #pending == 0 then return end
    KrakensStore.Log("error", string.format("%d queued MySQL queries dropped: %s", #pending, tostring(reason)))
    for _, p in ipairs(pending) do Fire(p.callback, nil, reason) end
end

function MySQL:Query(queryString, callback)
    if not self.ready then
        if #self.pending >= PENDING_LIMIT then
            Fire(callback, nil, "MySQL query queue is full")
            return
        end
        self.pending[#self.pending + 1] = { query = queryString, callback = callback }
        if not timer.Exists(PENDING_TIMER) then
            timer.Create(PENDING_TIMER, PENDING_TIMEOUT, 1, function()
                self:FailPending(string.format("MySQL was unreachable for %ds", PENDING_TIMEOUT))
            end)
        end
        return
    end
    self:exec(queryString, callback)
end

function MySQL:Transaction(queries, callback)
    local tx = self.connection:createTransaction()
    for _, q in ipairs(queries) do tx:addQuery(self.connection:query(q)) end
    tx.onSuccess = function() Fire(callback, true) end
    tx.onError = function(_, err)
        KrakensStore.Log("error", "MySQL transaction: " .. err)
        Fire(callback, false, err)
    end
    tx:start()
end

function MySQL:Escape(str)
    if self.connected then return self.connection:escape(tostring(str or "")) end
    return string.gsub(tostring(str or ""), "'", "''")
end

function MySQL:GetType() return "mysql" end
function MySQL:IsConnected() return self.connected and self.ready end
function MySQL:SetShutdownMode() self.shutdownMode = true end

KrakensStore.DB.Providers.MySQL = MySQL

KrakensStore.Data = KrakensStore.Data or {}
local Data = KrakensStore.Data

local function DeleteWhere(tbl, where, callback)
    DB.Query(string.format("DELETE FROM %s WHERE %s", tbl, Scope(where)), function(_, err) Fire(callback, err == nil, err) end)
end

local function MakeGetAll(tbl)
    return function(callback)
        DB.Query(string.format("SELECT data FROM %s WHERE %s", tbl, Scope("1=1")), function(rows, err)
            if err then Fire(callback, nil, err) return end
            local out = {}
            for _, row in ipairs(rows or {}) do
                local obj = util.JSONToTable(row.data)
                if obj and isstring(obj.id) and obj.id ~= "" then
                    out[obj.id] = obj
                end
            end
            Fire(callback, out)
        end)
    end
end

local function Upsert(tbl, record, callback)
    if not record or not record.id then
        Fire(callback, false, "invalid record")
        return
    end
    local time = os.time()
    local query = DB.BuildUpsert(tbl,
        { "server_id", "id", "data", "modified" },
        { server_id = DB.GetServerId(), id = record.id, data = util.TableToJSON(record), modified = time },
        { updateCols = { "data", "modified" } }
    )

    DB.Query(query, function(_, err)
        Fire(callback, err == nil, err)
    end)
end

function Data.SaveItem(item, cb) Upsert(T_ITEMS, item, cb) end
function Data.SaveCategory(c, cb) Upsert(T_CATEGORIES, c, cb) end
function Data.SaveNPC(n, cb) Upsert(T_NPCS, n, cb) end

Data.GetAllItems = MakeGetAll(T_ITEMS)
Data.GetAllCategories = MakeGetAll(T_CATEGORIES)
Data.GetAllNPCs = MakeGetAll(T_NPCS)

function Data.DeleteItem(id, cb) DeleteWhere(T_ITEMS, "id='" .. Esc(id) .. "'", cb) end
function Data.DeleteCategory(id, cb) DeleteWhere(T_CATEGORIES, "id='" .. Esc(id) .. "'", cb) end
function Data.DeleteNPC(id, cb) DeleteWhere(T_NPCS, "id='" .. Esc(id) .. "'", cb) end

function Data.BulkUpdateItemCategory(oldCat, newCat, callback)
    local affected = {}
    for _, item in pairs(KrakensStore.Items.Cache) do
        if item.category == oldCat then
            item.category = newCat
            table.insert(affected, item)
        end
    end
    if #affected == 0 then Fire(callback, true) return end

    local queries = {}
    for _, item in ipairs(affected) do
        table.insert(queries, string.format(
            "UPDATE %s SET data='%s', modified=%d WHERE %s",
            T_ITEMS, Esc(util.TableToJSON(item)), os.time(),
            Scope(string.format("id='%s'", Esc(item.id)))
        ))
    end
    DB.Transaction(queries, function(ok, err)
        if not ok then
            for _, item in ipairs(affected) do item.category = oldCat end
        else
            for _, item in ipairs(affected) do KrakensStore.Items.BroadcastUpdate(item) end
        end
        Fire(callback, ok, err)
    end)
end

function Data.GetPlayerInventory(steamId, callback)
    DB.Query(
        string.format(
            "SELECT item_id, quantity, equipped, data, purchased, expires FROM %s WHERE %s",
            T_INVENTORY, Scope(string.format("steamid='%s'", Esc(steamId)))
        ),
        function(rows, err)
            if err then Fire(callback, nil, err) return end
            local inv = {}
            for _, row in ipairs(rows or {}) do
                local decoded = util.JSONToTable(row.data) or {}
                inv[row.item_id] = {
                    itemId = row.item_id,
                    customData = decoded,
                    purchased = tonumber(row.purchased),
                    expires = tonumber(row.expires) or -1,
                    quantity = math.max(1, tonumber(row.quantity) or 1),
                    equipped = tonumber(row.equipped) == 1,
                }
            end
            Fire(callback, inv)
        end
    )
end

local function PrepInvFields(itemData)
    if not itemData then return nil end
    local customData = table.Copy(itemData.customData or itemData.data or {})
    customData.quantity = nil
    customData.equipped = nil
    return {
        quantity = math.max(1, math.floor(tonumber(itemData.quantity) or 1)),
        equipped = (itemData.equipped == true) and 1 or 0,
        data = util.TableToJSON(customData),
        purchased = math.floor(tonumber(itemData.purchased) or os.time()),
        expires = math.floor(tonumber(itemData.expires) or -1),
    }
end

function Data.BuildSaveInventoryItemQuery(steamId, itemId, itemData)
    local f = PrepInvFields(itemData)
    if not f then return nil end
    return DB.BuildUpsert(T_INVENTORY,
        { "server_id", "steamid", "item_id", "quantity", "equipped", "data", "purchased", "expires" },
        {
            server_id = DB.GetServerId(), steamid = steamId, item_id = itemId,
            quantity = f.quantity, equipped = f.equipped, data = f.data,
            purchased = f.purchased, expires = f.expires,
        },
        { updateCols = { "quantity", "equipped", "data", "expires" } }
    )
end

function Data.BuildRemoveInventoryItemQuery(steamId, itemId)
    return string.format(
        "DELETE FROM %s WHERE %s",
        T_INVENTORY,
        Scope(string.format("steamid='%s' AND item_id='%s'", Esc(steamId), Esc(itemId)))
    )
end

function Data.RemoveInventoryItems(steamId, itemIds, callback)
    if #itemIds == 0 then Fire(callback, true) return end
    local escaped = {}
    for i, id in ipairs(itemIds) do escaped[i] = "'" .. Esc(id) .. "'" end
    DeleteWhere(T_INVENTORY, string.format("steamid='%s' AND item_id IN (%s)", Esc(steamId), table.concat(escaped, ",")), callback)
end

function Data.DeleteInventoryItemEverywhere(itemId, callback)
    DeleteWhere(T_INVENTORY, "item_id='" .. Esc(itemId) .. "'", callback)
end

function Data.ClearPlayerInventory(steamId, callback)
    DeleteWhere(T_INVENTORY, "steamid='" .. Esc(steamId) .. "'", callback)
end

function Data.GetPlayerData(steamId, callback)
    DB.Query(
        string.format(
            "SELECT data, first_seen, last_seen, total_spent, total_earned, items_purchased, items_sold FROM %s WHERE %s",
            T_PLAYERS, Scope(string.format("steamid='%s'", Esc(steamId)))
        ),
        function(rows, err)
            if err then Fire(callback, nil, err) return end

            local row = rows and rows[1]
            if row then
                local data = util.JSONToTable(row.data) or {}
                KrakensStore.Schema.MergeDefaults(data, KrakensStore.Schema.PlayerDataDefaults())
                data.firstSeen = tonumber(row.first_seen)
                data.lastSeen = tonumber(row.last_seen)
                data.stats = {
                    totalSpent = tonumber(row.total_spent) or 0,
                    totalEarned = tonumber(row.total_earned) or 0,
                    itemsPurchased = tonumber(row.items_purchased) or 0,
                    itemsSold = tonumber(row.items_sold) or 0,
                }
                Fire(callback, data)
                return
            end

            local newData = KrakensStore.Schema.MergeDefaults({
                firstSeen = os.time(),
                lastSeen = os.time(),
            }, KrakensStore.Schema.PlayerDataDefaults())
            Data.SavePlayerData(steamId, newData)
            Fire(callback, newData)
        end
    )
end

local pendingPlayerData = {}
local PLAYER_FLUSH_INTERVAL = 2

local function FlushPlayer(steamId)
    local pending = pendingPlayerData[steamId]
    if not pending then return end
    pendingPlayerData[steamId] = nil

    local data = pending.data
    local stats = data.stats or {}
    local firstSeen = data.firstSeen or os.time()
    local time = os.time()

    local blob = table.Copy(data)
    blob.stats = nil
    blob.firstSeen = nil
    blob.lastSeen = nil

    local totalSpent = math.floor(tonumber(stats.totalSpent) or 0)
    local totalEarned = math.floor(tonumber(stats.totalEarned) or 0)
    local itemsPurchased = math.floor(tonumber(stats.itemsPurchased) or 0)
    local itemsSold = math.floor(tonumber(stats.itemsSold) or 0)
    local jsonData = util.TableToJSON(blob)

    local query = DB.BuildUpsert(T_PLAYERS,
        { "server_id", "steamid", "data", "first_seen", "last_seen", "total_spent", "total_earned", "items_purchased", "items_sold" },
        {
            server_id = DB.GetServerId(), steamid = steamId, data = jsonData,
            first_seen = firstSeen, last_seen = time,
            total_spent = totalSpent, total_earned = totalEarned,
            items_purchased = itemsPurchased, items_sold = itemsSold,
        },
        {
            updateCols = { "data", "last_seen", "total_spent", "total_earned", "items_purchased", "items_sold" },
            sqliteOverrides = {
                first_seen = string.format("COALESCE((SELECT first_seen FROM %s WHERE %s),%d)",
                    T_PLAYERS, Scope(string.format("steamid='%s'", Esc(steamId))), firstSeen),
            },
        }
    )

    DB.Query(query, function(_, err)
        for _, cb in ipairs(pending.callbacks) do cb(err == nil) end
    end)
end

function Data.SavePlayerData(steamId, data, callback)
    if not isstring(steamId) or steamId == "" then Fire(callback, false) return end
    local pending = pendingPlayerData[steamId]
    if pending then
        pending.data = data
        if callback then table.insert(pending.callbacks, callback) end
        return
    end
    pendingPlayerData[steamId] = { data = data, callbacks = callback and { callback } or {} }
    timer.Create("KS_FlushPlayer_" .. steamId, PLAYER_FLUSH_INTERVAL, 1, function() FlushPlayer(steamId) end)
end

function Data.DeletePlayerData(steamId, callback)
    pendingPlayerData[steamId] = nil
    timer.Remove("KS_FlushPlayer_" .. steamId)
    DeleteWhere(T_PLAYERS, "steamid='" .. Esc(steamId) .. "'", callback)
end

function Data.FlushPendingPlayer(steamId)
    if pendingPlayerData[steamId] then
        timer.Remove("KS_FlushPlayer_" .. steamId)
        FlushPlayer(steamId)
    end
end

function Data.FlushAllPlayerData()
    for steamId in pairs(pendingPlayerData) do
        timer.Remove("KS_FlushPlayer_" .. steamId)
        FlushPlayer(steamId)
    end
end

function Data.GetConfig(key, callback)
    DB.Query(
        string.format("SELECT value FROM %s WHERE %s", T_CONFIG, Scope(string.format("%s='%s'", DB.KeyCol(), Esc(key)))),
        function(rows, err)
            if err then Fire(callback, nil, err) return end
            local row = rows and rows[1]
            if not row then Fire(callback, nil, nil, false) return end
            local decoded = util.JSONToTable(row.value, false, true)
            if not decoded then
                KrakensStore.Log("warn", "Data.GetConfig: corrupted JSON for key=" .. tostring(key))
                Fire(callback, nil, nil, false)
                return
            end
            Fire(callback, decoded, nil, true)
        end
    )
end

function Data.DeleteConfig(key, callback)
    DeleteWhere(T_CONFIG, string.format("%s='%s'", DB.KeyCol(), Esc(key)), callback)
end

function Data.SetConfig(key, value, callback)
    local json = util.TableToJSON(value)
    if not json then Fire(callback, false, "invalid json") return end

    local keyCol = DB.KeyCol()
    local time = os.time()
    local query = DB.BuildUpsert(T_CONFIG,
        { "server_id", keyCol, "value", "modified" },
        { server_id = DB.GetServerId(), [keyCol] = key, value = json, modified = time },
        { updateCols = { "value", "modified" } }
    )
    DB.Query(query, function(_, err) Fire(callback, err == nil, err) end)
end

local LOG_SETTINGS = {
    purchase = "LogPurchases", sale = "LogSales", equip = "LogEquips", unequip = "LogEquips",
    admin_give = "LogAdminActions", admin_take = "LogAdminActions", admin_reset = "LogAdminActions",
}

function Data.Log(logType, steamId, data, callback)
    if not isstring(logType) or logType == "" then Fire(callback, false) return end
    local logging = KrakensStore.Config.Logging
    if LOG_SETTINGS[logType] and not logging[LOG_SETTINGS[logType]] then Fire(callback, true) return end

    hook.Run("KrakensStore_PostDataLog", logType, steamId, data)
    Data.SendDiscordLog(logType, steamId, data)

    if string.StartsWith(logType, "admin_") and not logging.LogAdminActions then
        Fire(callback, true)
        return
    end

    local itemId = data and data.itemId
    local itemName = data and data.itemName
    local quantity = data and tonumber(data.quantity) or 0
    local amount = data and (tonumber(data.price) or tonumber(data.refund) or 0) or 0

    local dataJson = util.TableToJSON(data or {}) or "{}"
    if #dataJson > 4096 then dataJson = "{}" end

    local query = string.format(
        "INSERT INTO %s (server_id, type, steamid, item_id, item_name, quantity, amount, data, timestamp) VALUES ('%s','%s',%s,%s,%s,%d,%d,'%s',%d)",
        T_LOGS, DB.GetEscapedServerId(), Esc(logType),
        steamId and ("'" .. Esc(steamId) .. "'") or "NULL",
        itemId and ("'" .. Esc(tostring(itemId)) .. "'") or "NULL",
        itemName and ("'" .. Esc(tostring(itemName)) .. "'") or "NULL",
        quantity, amount,
        Esc(dataJson),
        os.time()
    )
    DB.Query(query, function(_, err) Fire(callback, err == nil) end)
end

function Data.GetLogs(limit, callback)
    local safeLimit = math.Clamp(math.floor(tonumber(limit) or 100), 1, 500)
    DB.Query(
        string.format("SELECT * FROM %s WHERE %s ORDER BY timestamp DESC LIMIT %d", T_LOGS, Scope("1=1"), safeLimit),
        function(rows, err)
            if err then Fire(callback, nil, err) return end
            local out = {}
            for _, row in ipairs(rows or {}) do
                table.insert(out, {
                    id = row.id, type = row.type, steamId = row.steamid,
                    itemId = row.item_id, itemName = row.item_name,
                    quantity = tonumber(row.quantity) or 0, amount = tonumber(row.amount) or 0,
                    data = util.JSONToTable(row.data) or {},
                    timestamp = tonumber(row.timestamp),
                })
            end
            Fire(callback, out)
        end
    )
end

function Data.SendDiscordLog(logType, steamId, data)
    local cfg = KrakensStore.ServerConfig.Discord
    if not cfg.Enabled or not cfg.WebhookURL or cfg.WebhookURL == "" then return end

    local ply = steamId and player.GetBySteamID64(steamId)
    local playerName = IsValid(ply) and ply:Nick() or (steamId or "System")
    local playerLink = (cfg.IncludeProfileLink and steamId) and ("\n[Steam Profile](https://steamcommunity.com/profiles/" .. steamId .. ")") or ""

    local color = cfg.AdminColor
    if string.find(logType, "purchase") then color = cfg.PurchaseColor
    elseif string.find(logType, "sale") or string.find(logType, "sell") then color = cfg.SaleColor
    elseif string.find(logType, "error") then color = cfg.ErrorColor end

    local desc = string.format("**Type:** %s\n**Player:** %s%s", logType, playerName, playerLink)
    if data then
        if data.itemName then desc = desc .. "\n**Item:** " .. data.itemName end
        if data.price then desc = desc .. "\n**Price:** " .. tostring(data.price) end
        if data.quantity then desc = desc .. "\n**Quantity:** " .. tostring(data.quantity) end
    end

    HTTP({
        url = cfg.WebhookURL,
        method = "POST",
        headers = { ["Content-Type"] = "application/json" },
        body = util.TableToJSON({
            username = cfg.BotName,
            avatar_url = cfg.AvatarURL ~= "" and cfg.AvatarURL or nil,
            embeds = {{ title = "Kraken's Store Log", description = desc, color = color, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") }},
        }),
        failed = function() end,
    })
end

function Data.PruneLogs()
    local retentionDays = KrakensStore.ServerConfig.Internal.LogRetentionDays
    if retentionDays <= 0 then return end
    DeleteWhere(T_LOGS, "timestamp < " .. (os.time() - retentionDays * 86400))
end

function Data.QueueRecovery(steamId, entry)
    if not isstring(steamId) or steamId == "" then return end
    if not istable(entry) then return end
    local amount = math.floor(tonumber(entry.amount) or 0)
    if amount <= 0 then return end

    DB.Query(string.format(
        "INSERT INTO %s (server_id, steamid, type, amount, reason, created) VALUES ('%s','%s','%s',%d,'%s',%d)",
        T_RECOVERIES, DB.GetEscapedServerId(), Esc(steamId),
        Esc(tostring(entry.type or "refund")), amount,
        Esc(tostring(entry.reason or "")), KrakensStore.Now()))

    KrakensStore.Log("warn", string.format("Recovery queued for %s: %s %d", steamId, tostring(entry.type), amount))
end

function Data.ProcessRecoveriesForPlayer(ply)
    if not IsValid(ply) then return end
    local steamId = ply:SteamID64()

    DB.Query(string.format("SELECT id, type, amount FROM %s WHERE %s", T_RECOVERIES,
        Scope(string.format("steamid='%s'", Esc(steamId)))), function(rows, err)
        if err or not rows or #rows == 0 then return end

        local settled = {}
        for _, row in ipairs(rows) do
            local amount = math.floor(tonumber(row.amount) or 0)
            if amount > 0 and IsValid(ply) then
                local ok = pcall(function()
                    if row.type == "clawback" then
                        KF.Currency.Remove(ply, amount, KrakensStore.CurrencyKey)
                    else
                        KF.Currency.Add(ply, amount, KrakensStore.CurrencyKey)
                    end
                end)
                if ok then settled[#settled + 1] = tostring(math.floor(tonumber(row.id) or 0)) end
            end
        end

        if #settled == 0 then return end
        DB.Query(string.format("DELETE FROM %s WHERE id IN (%s)", T_RECOVERIES, table.concat(settled, ",")))
        KrakensStore.Log("success", string.format("Settled %d pending recoveries for %s", #settled, steamId))
    end)
end

hook.Add("KrakensStore_PlayerLoaded", "KrakensStore_ProcessRecoveries", Data.ProcessRecoveriesForPlayer)

concommand.Add("ks_db_dryrun", function(ply)
    if IsValid(ply) then ply:ChatPrint(KrakensStore.L("err_console_only")) return end
    if not DB.IsConnected() then KrakensStore.Log("error", "Database is not connected") return end

    ReadSchemaVersion(function(from, err)
        if not from then KrakensStore.Log("error", err) return end
        KrakensStore.Log("info", string.format("provider=%s server_id=%s schema=v%d target=v%d",
            DB.GetType(), DB.GetServerId(), from, DB.SchemaVersion))
        if from >= DB.SchemaVersion then
            KrakensStore.Log("success", "No migrations pending")
            return
        end
        for v = from + 1, DB.SchemaVersion do
            KrakensStore.Log(DB.Migrations[v] and "warn" or "info",
                string.format("  v%d %s", v, DB.Migrations[v] and "PENDING" or "(no-op)"))
        end
        KrakensStore.Log("info", "A backup is taken automatically before the first step")
    end)
end)

KrakensStore.SpawnAssignments = KrakensStore.SpawnAssignments or {}

function Data.SaveSpawnAssignments(assignments, callback)
    local next_ = assignments or {}
    Data.SetConfig("spawn_assignments", next_, function(ok, err)
        if ok then KrakensStore.SpawnAssignments = next_ end
        Fire(callback, ok, err)
    end)
end

local dbBacked = { items = {}, categories = {}, npcs = {} }
local coldLoad = false

local function SyncCache(cache, rows, kind)
    local tracked = dbBacked[kind]
    if coldLoad then
        table.Empty(cache)
    else
        for id in pairs(tracked) do
            if rows[id] == nil then cache[id] = nil end
        end
    end
    table.Empty(tracked)
    for id, row in pairs(rows) do
        cache[id] = row
        tracked[id] = true
    end
    return cache
end

KrakensStore.Lifecycle = KrakensStore.Lifecycle or {}
local LC = KrakensStore.Lifecycle

LC.Phase = LC.Phase or "UNINITIALIZED"
LC.Provider = LC.Provider or "none"
LC.Migrations = LC.Migrations or "PENDING"
LC.Steps = LC.Steps or {}
LC.StepOrder = {}
LC.Failure = nil

KrakensStore.EntitiesReady = KrakensStore.EntitiesReady or false
local entityWaiters = {}

hook.Add("InitPostEntity", "KrakensStore_EntitiesReady", function()
    KrakensStore.EntitiesReady = true
    local pending = entityWaiters
    entityWaiters = {}
    for _, fn in ipairs(pending) do fn() end
end)

local function WhenEntitiesReady(fn)
    if KrakensStore.EntitiesReady then fn() return end
    entityWaiters[#entityWaiters + 1] = fn
end

local STEP_TIMEOUT = 30
local CONNECT_TIMEOUT = 30
local MIGRATION_TIMEOUT = 300
local RECOVERY_FAST_ATTEMPTS = 5
local RECOVERY_SLOW_DELAY = 300
local recoveryAttempts = 0
local readyWaiters = {}

local function SetPhase(phase, failure)
    LC.Phase = phase
    LC.Failure = failure
    hook.Run("KrakensStore_StateChanged", phase, failure)
end

function LC.RetryInfo()
    if LC.Phase ~= "FAILED" then return nil end
    if not timer.Exists("KrakensStore_Recovery") then return "no retry scheduled, run ks_store_retry" end
    return string.format("attempt %d in %ds", LC.RetryAttempt or 0, math.max(0, math.ceil((LC.NextRetry or 0) - CurTime())))
end

function LC.FailureDetail()
    if not LC.Failure then return "" end
    local retry = LC.RetryInfo()
    return retry and (LC.Failure .. " (" .. retry .. ")") or LC.Failure
end

function LC.Describe()
    local parts = {
        "Store State: " .. LC.Phase,
        "DB: " .. LC.Provider .. " " .. (DB.IsConnected() and "CONNECTED" or "DISCONNECTED"),
        "Migrations: " .. LC.Migrations,
    }
    for _, name in ipairs(LC.StepOrder) do
        parts[#parts + 1] = name .. ": " .. (LC.Steps[name] or "PENDING")
    end
    local waiting = LC.PendingCount()
    if waiting > 0 then parts[#parts + 1] = "Waiting requests: " .. waiting end
    if LC.Failure then parts[#parts + 1] = "Failure: " .. LC.Failure end
    local retry = LC.RetryInfo()
    if retry then parts[#parts + 1] = "Retry: " .. retry end
    return table.concat(parts, " / ")
end

function LC.PrintStatus()
    local level = LC.Phase == "READY" and "success" or (LC.Phase == "FAILED" and "error" or "info")
    KrakensStore.Log(level, LC.Describe())
end

function LC.WhenReady(key, fn, onFail)
    if LC.Phase == "READY" then fn() return true end
    readyWaiters[key] = { fn = fn, onFail = onFail }
    return false
end

function LC.PendingCount()
    local n = 0
    for _ in pairs(readyWaiters) do n = n + 1 end
    return n
end

function LC.CancelWaitsFor(steamId)
    local suffix = ":" .. tostring(steamId)
    for key in pairs(readyWaiters) do
        if string.EndsWith(key, suffix) then readyWaiters[key] = nil end
    end
end

local function DrainWaiters()
    local waiters = readyWaiters
    readyWaiters = {}
    for _, entry in pairs(waiters) do entry.fn() end
end

local function ScheduleRecovery()
    recoveryAttempts = recoveryAttempts + 1
    local fast = recoveryAttempts <= RECOVERY_FAST_ATTEMPTS
    local delay = fast and math.min(5 * 2 ^ (recoveryAttempts - 1), 60) or RECOVERY_SLOW_DELAY
    LC.RetryAttempt = recoveryAttempts
    LC.NextRetry = CurTime() + delay
    KrakensStore.Log("warn", string.format("Retrying startup in %ds (attempt %d%s). Fix the cause above, or run ks_store_retry to retry now.",
        delay, recoveryAttempts, fast and "" or ", slow cadence"))
    timer.Create("KrakensStore_Recovery", delay, 1, function()
        if LC.Phase == "FAILED" then KrakensStore.Boot(true) end
    end)
end

function LC.Fail(reason)
    KrakensStore.Log("error", "Startup failed: " .. tostring(reason))
    if LC.Phase ~= "FAILED" then
        timer.Remove("KrakensStore_ConnectWatchdog")
        timer.Remove("KrakensStore_MigrationWatchdog")
        for _, step in ipairs(LC.StepOrder) do timer.Remove("KrakensStore_Step_" .. step) end
        ScheduleRecovery()
    end
    SetPhase("FAILED", reason)
    LC.PrintStatus()
    local waiters = readyWaiters
    readyWaiters = {}
    for _, entry in pairs(waiters) do
        if entry.onFail then entry.onFail(reason) end
    end
end

local function RunSteps(steps, index, onDone, generation)
    local step = steps[index]
    if not step then Fire(onDone, true) return end
    LC.Steps[step.name] = "WAITING"
    local settled = false
    local watchdog = "KrakensStore_Step_" .. step.name
    timer.Create(watchdog, STEP_TIMEOUT, 1, function()
        if settled or LC.Generation ~= generation then return end
        settled = true
        LC.Steps[step.name] = "TIMEOUT"
        Fire(onDone, false, string.format("%s did not answer within %ds", step.name, STEP_TIMEOUT))
    end)
    step.run(function(ok, err)
        if settled or LC.Generation ~= generation then return end
        settled = true
        timer.Remove(watchdog)
        if ok == false then
            LC.Steps[step.name] = "FAILED"
            Fire(onDone, false, step.name .. ": " .. tostring(err or "unknown error"))
            return
        end
        LC.Steps[step.name] = "COMPLETE"
        RunSteps(steps, index + 1, onDone, generation)
    end)
end

local function ConfigStep(name, key, apply)
    return { name = name, run = function(done)
        Data.GetConfig(key, function(data, err)
            if err then done(false, err) return end
            apply(data)
            done(true)
        end)
    end }
end

local function CacheStep(name, fetchName, cache, kind, after)
    return { name = name, run = function(done)
        Data[fetchName](function(data, err)
            if err or not data then done(false, err or "query returned no result") return end
            SyncCache(cache, data, kind)
            if after then after(cache) end
            done(true)
        end)
    end }
end

local LOAD_STEPS = {
    ConfigStep("Settings", "settings", function(data) Data.ApplyGeneralSettings(data) end),
    ConfigStep("Blacklist", "attachment_blacklist", function(data) KrakensStore.Config.ApplyBlacklist(data) end),
    ConfigStep("Spawns", "spawn_assignments", function(data) KrakensStore.SpawnAssignments = data or {} end),
    CacheStep("Categories", "GetAllCategories", KrakensStore.Categories.Cache, "categories", function(categories)
        if next(categories) then return end
        for _, cat in ipairs(KrakensStore.Schema.GetDefaultCategories()) do
            Data.SaveCategory(cat)
            categories[cat.id] = cat
        end
    end),
    CacheStep("Items", "GetAllItems", KrakensStore.Items.Cache, "items", function(items)
        for _, item in pairs(items) do KrakensStore.Schema.NormalizeItemData(item) end
    end),
    CacheStep("NPCs", "GetAllNPCs", KrakensStore.NPCs.Cache, "npcs"),
}

for _, step in ipairs(LOAD_STEPS) do LC.StepOrder[#LC.StepOrder + 1] = step.name end

function Data.IsLoaded() return LC.Phase == "READY" end

function Data.LoadAllData(force, cold)
    if LC.Phase == "READY" and not force then return end
    if LC.Phase == "LOADING" then return end
    if not DB.IsConnected() then LC.Fail("database is not connected") return end

    SetPhase("LOADING")
    table.Empty(LC.Steps)
    coldLoad = cold == true

    RunSteps(LOAD_STEPS, 1, function(ok, err)
        coldLoad = false
        if not ok then LC.Fail(err) return end
        recoveryAttempts = 0
        SetPhase("READY")
        KrakensStore.Log("success", string.format("Loaded: %d categories, %d items, %d NPCs",
            table.Count(KrakensStore.Categories.Cache), table.Count(KrakensStore.Items.Cache),
            table.Count(KrakensStore.NPCs.Cache)))
        if DB.GetType() == "mysql" and DB.GetServerId() ~= "ks_default" then
            Data.GetAllServerIds(function(ids)
                if not ids.ks_default then return end
                KrakensStore.Log("warn", "Rows exist under server_id 'ks_default' while this server is '" .. DB.GetServerId() .. "'. Run krakens_store_serverids, then krakens_store_migrate ks_default to adopt them.")
            end)
        end
        DrainWaiters()
        local SInv = KrakensStore.ServerInventory
        for _, ply in ipairs(player.GetAll()) do
            SInv.LoadPlayer(ply)
            SInv.ApplyEquippedItems(ply)
        end
        hook.Run("KrakensStore_DataLoaded")
        timer.Create("KrakensStore_PruneLogs", 3600, 0, Data.PruneLogs)
        Data.PruneLogs()
        WhenEntitiesReady(function() KrakensStore.NPCs.SpawnPlaced() end)
    end, LC.Generation)
end

function KrakensStore.Boot(force)
    local busy = LC.Phase == "CONNECTING" or LC.Phase == "MIGRATING" or LC.Phase == "LOADING"
    if busy and not force then return end
    if busy then
        KrakensStore.Log("warn", "Restarting startup, previous attempt stopped at: " .. LC.Describe())
    end
    timer.Remove("KrakensStore_Recovery")
    timer.Remove("KrakensStore_MigrationWatchdog")
    timer.Remove("KrakensStore_ConnectWatchdog")
    for _, step in ipairs(LC.StepOrder) do timer.Remove("KrakensStore_Step_" .. step) end
    LC.Generation = (LC.Generation or 0) + 1
    LC.Migrations = "PENDING"
    table.Empty(LC.Steps)
    SetPhase("CONNECTING")
    timer.Create("KrakensStore_ConnectWatchdog", CONNECT_TIMEOUT, 1, function()
        if LC.Phase == "CONNECTING" then
            LC.Fail(string.format("database did not become available within %ds", CONNECT_TIMEOUT))
        end
    end)
    local ok, err = DB.Initialize()
    if not ok then LC.Fail(err) end
end

hook.Add("Initialize", "KrakensStore_Boot", KrakensStore.Boot)

function OnDatabaseInitialized(kind)
    timer.Remove("KrakensStore_ConnectWatchdog")
    LC.Provider = kind or "unknown"
    if LC.Phase == "READY" or LC.Phase == "MIGRATING" or LC.Phase == "LOADING" then return end

    SetPhase("MIGRATING")
    LC.Migrations = "RUNNING"
    timer.Create("KrakensStore_MigrationWatchdog", MIGRATION_TIMEOUT, 1, function()
        if LC.Phase ~= "MIGRATING" then return end
        KrakensStore.Log("error", "Migration stalled at: " .. LC.Describe())
        LC.Migrations = "STALLED"
        LC.Fail(string.format("migrations stopped responding after %ds", MIGRATION_TIMEOUT))
    end)

    local generation = LC.Generation
    local function Finish(ok, err)
        if LC.Phase ~= "MIGRATING" or LC.Generation ~= generation then return end
        timer.Remove("KrakensStore_MigrationWatchdog")
        if not ok then
            LC.Migrations = "FAILED"
            LC.Fail("migrations: " .. tostring(err or "unknown error"))
            return
        end
        LC.Migrations = "COMPLETE"
        Data.LoadAllData(true, true)
    end

    local ok, err = pcall(DB.RunMigrations, Finish)
    if not ok then Finish(false, "crashed: " .. tostring(err)) end
end

concommand.Add("ks_store_status", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, LC.Describe()) end
    LC.PrintStatus()
end)

concommand.Add("ks_store_retry", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    recoveryAttempts = 0
    if LC.Phase == "READY" then
        Data.LoadAllData(true)
    else
        KrakensStore.Boot(true)
    end
end)

function Data.GetAllServerIds(callback)
    local out = {}
    local remaining = #TABLES
    for _, entry in ipairs(TABLES) do
        local tbl = entry.name
        DB.Query("SELECT server_id, COUNT(*) AS cnt FROM " .. tbl .. " GROUP BY server_id", function(rows)
            for _, row in ipairs(rows or {}) do
                local sid = row.server_id or "NULL"
                out[sid] = out[sid] or {}
                out[sid][tbl] = tonumber(row.cnt) or 0
            end
            remaining = remaining - 1
            if remaining <= 0 and callback then callback(out) end
        end)
    end
end

function Data.MigrateServerData(oldServerId, newServerId, callback)
    if not oldServerId or oldServerId == "" then Fire(callback, false, "invalid old id") return end
    newServerId = newServerId or DB.GetServerId()
    if oldServerId == newServerId then Fire(callback, false, "same id") return end

    local oldEsc, newEsc = Esc(oldServerId), Esc(newServerId)
    local mysql = DB.GetType() == "mysql"
    local quote = mysql and "`" or ""

    local remaining = #TABLES
    local hadError = false

    for _, entry in ipairs(TABLES) do
        local tbl, keys = entry.name, entry.key
        local delConflicts
        if keys then
            if mysql then
                local joinParts = {}
                for _, k in ipairs(keys) do
                    table.insert(joinParts, "dst." .. quote .. k .. quote .. "=src." .. quote .. k .. quote)
                end
                delConflicts = string.format(
                    "DELETE dst FROM %s dst INNER JOIN %s src ON src.server_id='%s' AND dst.server_id='%s' AND %s",
                    tbl, tbl, oldEsc, newEsc, table.concat(joinParts, " AND ")
                )
            else
                local sel = table.concat(keys, " || ':' || ")
                delConflicts = string.format(
                    "DELETE FROM %s WHERE server_id='%s' AND %s IN (SELECT %s FROM %s WHERE server_id='%s')",
                    tbl, newEsc, sel, sel, tbl, oldEsc
                )
            end
        end

        local function migrate()
            DB.Query(string.format("UPDATE %s SET server_id='%s' WHERE server_id='%s'", tbl, newEsc, oldEsc), function(_, err)
                if err then hadError = true end
                remaining = remaining - 1
                if remaining <= 0 and callback then
                    callback(not hadError, hadError and "migration_failed" or nil)
                end
            end)
        end

        if delConflicts then DB.Query(delConflicts, migrate) else migrate() end
    end
end

concommand.Add("krakens_store_serverids", function(ply)
    if IsValid(ply) then ply:ChatPrint(KrakensStore.L("err_console_only")) return end
    local currentId = DB.GetServerId()
    KrakensStore.Log("info", "Current server_id: " .. currentId)
    Data.GetAllServerIds(function(serverIds)
        if not serverIds or not next(serverIds) then
            KrakensStore.Log("warn", "No data found.")
            return
        end
        for sid, tables in pairs(serverIds) do
            KrakensStore.Log("info", "  '" .. sid .. "'" .. (sid == currentId and " <- ACTIVE" or ""))
            for tbl, count in pairs(tables) do
                KrakensStore.Log("info", "    " .. tbl .. ": " .. count)
            end
        end
    end)
end)

concommand.Add("krakens_store_migrate", function(ply, _, args)
    if IsValid(ply) then ply:ChatPrint(KrakensStore.L("err_console_only")) return end
    local oldId = args and args[1]
    if not oldId or oldId == "" then
        KrakensStore.Log("info", "Usage: krakens_store_migrate <old_server_id> [new_server_id]")
        return
    end
    local newId = (args[2] and args[2] ~= "") and args[2] or DB.GetServerId()
    Data.MigrateServerData(oldId, newId, function(ok, err)
        if ok then KrakensStore.Log("success", "Migration done. Run ks_reload.")
        else KrakensStore.Log("error", "Migration failed: " .. tostring(err)) end
    end)
end)

function Data.ApplyConfiguredEntityModels()
    local entities, EC = KrakensStore.Config.Entities, KrakensStore.EntityClasses
    for className, cfg in pairs({ [EC.Terminal] = entities.Terminal, [EC.Workbench] = entities.Workbench }) do
        local look = cfg.Look or {}
        for _, ent in ipairs(ents.FindByClass(className)) do
            if ent:GetModel() ~= cfg.Model then
                KrakensStore.Utils.SetupEntityPhysics(ent, cfg.Model, cfg.Look)
            else
                KF.Utils.ApplyLook(ent, look.skin, look.bodygroups)
            end
        end
    end
    KrakensStore.NPCs.ForEachEntity(function(ent)
        local npcId = ent:GetNPCConfigId()
        local model, skin, bodygroups = KrakensStore.NPCs.Resolve(npcId)
        if ent:GetModel() ~= model then
            KrakensStore.NPCs.ConfigureEntity(ent, npcId)
        else
            KF.Utils.ApplyLook(ent, skin, bodygroups)
        end
    end)
end

function Data.ApplyGeneralSettings(saved)
    if not saved then return end
    KrakensStore.Config.ApplySettings(saved)
    KF.Lang.SetLanguage(KrakensStore.AID, KrakensStore.Config.General.Language)
    Data.ApplyConfiguredEntityModels()
    hook.Run("KrakensStore_GeneralSettingsLoaded", saved)
end

DB.SchemaVersion = 9
DB.Migrations = {}

local function Serial(steps, done, index)
    index = index or 1
    local step = steps[index]
    if not step then Fire(done, true) return end
    step(function(ok, err)
        if ok == false then Fire(done, false, err) return end
        Serial(steps, done, index + 1)
    end)
end

function DB.ListColumns(tableName, done)
    if DB.GetType() == "mysql" then
        DB.Query(string.format(
            "SELECT COLUMN_NAME AS name FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '%s'",
            DB.Escape(tableName)), function(rows)
            local set = {}
            for _, row in ipairs(rows or {}) do set[row.name] = true end
            done(set)
        end)
        return
    end
    DB.Query(string.format("PRAGMA table_info(%s)", tableName), function(rows)
        local set = {}
        for _, row in ipairs(rows or {}) do set[row.name] = true end
        done(set)
    end)
end

local function RebuildWithKey(tableName, key, done)
    if DB.GetType() == "mysql" then
        local cols = {}
        for i, name in ipairs(key) do cols[i] = "`" .. name .. "`" end
        DB.Query(string.format("ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY (%s)",
            tableName, table.concat(cols, ", ")), function(_, err)
            if err then KrakensStore.Log("warn", "PK rebuild skipped for " .. tableName .. ": " .. tostring(err)) end
            Fire(done, true)
        end)
        return
    end

    DB.ListColumns(tableName, function(existing)
        local cols = {}
        for _, name in ipairs(key) do
            if existing[name] then cols[#cols + 1] = name end
        end
        if #cols ~= #key then Fire(done, true) return end

        local ordered = {}
        for name in pairs(existing) do ordered[#ordered + 1] = name end
        table.sort(ordered)
        local colList = table.concat(ordered, ", ")
        local tmp = tableName .. "_ksmig"

        DB.Query(string.format("SELECT sql FROM sqlite_master WHERE type='table' AND name='%s'", tableName), function(rows)
            local ddl = rows and rows[1] and rows[1].sql
            if not ddl then Fire(done, true) return end
            local pkClause = "PRIMARY KEY (" .. table.concat(key, ", ") .. ")"
            if string.find(ddl, pkClause, 1, true) then Fire(done, true) return end

            local renamed = string.gsub(ddl, "^CREATE TABLE%s+[%w_\"]+", "CREATE TABLE " .. tmp, 1)
            local newDdl, swapped = string.gsub(renamed, "PRIMARY KEY%s*%b()", pkClause, 1)
            if swapped == 0 and not string.find(renamed, "AUTOINCREMENT", 1, true) then
                local stripped, removed = string.gsub(renamed, "%s+PRIMARY%s+KEY", "", 1)
                if removed == 1 then newDdl, swapped = string.gsub(stripped, "%)%s*$", ", " .. pkClause .. ")", 1) end
            end
            if swapped == 0 then
                KrakensStore.Log("warn", "PK rebuild skipped for " .. tableName .. ": no PRIMARY KEY clause could be rewritten")
                Fire(done, true)
                return
            end

            DB.Transaction({
                newDdl,
                string.format("INSERT OR IGNORE INTO %s (%s) SELECT %s FROM %s", tmp, colList, colList, tableName),
                string.format("DROP TABLE %s", tableName),
                string.format("ALTER TABLE %s RENAME TO %s", tmp, tableName),
            }, function(ok, err)
                if not ok then KrakensStore.Log("error", "PK rebuild failed for " .. tableName .. ": " .. tostring(err)) end
                Fire(done, ok ~= false, err)
            end)
        end)
    end)
end

local function ListIndexes(tableName, done)
    if DB.GetType() == "mysql" then
        DB.Query("SHOW INDEX FROM " .. tableName, function(rows)
            local set = {}
            for _, row in ipairs(rows or {}) do set[row.Key_name] = true end
            done(set)
        end)
        return
    end
    DB.Query(string.format("PRAGMA index_list(%s)", tableName), function(rows)
        local set = {}
        for _, row in ipairs(rows or {}) do set[row.name] = true end
        done(set)
    end)
end

local function RunQueries(queries, done)
    local steps = {}
    for i, query in ipairs(queries) do
        steps[i] = function(next_)
            KrakensStore.Log("info", "DB " .. query)
            DB.Query(query, function(_, err) next_(err == nil, err) end)
        end
    end
    Serial(steps, done)
end

function DB.RepairColumns(done)
    local mysql = DB.GetType() == "mysql"
    local steps = {}
    for _, entry in ipairs(TABLES) do
        if entry.repair ~= false then
            steps[#steps + 1] = function(next_)
                KrakensStore.Lifecycle.Migrations = "REPAIR " .. entry.name
                DB.ListColumns(entry.name, function(existing)
                    if not next(existing) then next_(true) return end
                    local queries = {}
                    for _, col in ipairs(entry.columns) do
                        if not existing[col[1]] then
                            queries[#queries + 1] = AddColumnDDL(entry.name, col, mysql)
                            if col[1] == "server_id" and DB.GetServerId() ~= "ks_default" then
                                queries[#queries + 1] = string.format("UPDATE %s SET server_id='%s'", entry.name, DB.GetEscapedServerId())
                            end
                        end
                    end
                    RunQueries(queries, next_)
                end)
            end
        end
    end
    Serial(steps, done)
end

function DB.EnsureIndexes(done)
    local create = DB.GetType() == "mysql" and "CREATE INDEX %s ON %s (%s)" or "CREATE INDEX IF NOT EXISTS %s ON %s (%s)"
    local steps = {}
    for _, entry in ipairs(TABLES) do
        if entry.indexes then
            steps[#steps + 1] = function(next_)
                ListIndexes(entry.name, function(indexes)
                    local queries = {}
                    for _, idx in ipairs(entry.indexes) do
                        if not indexes[idx[1]] then queries[#queries + 1] = string.format(create, idx[1], entry.name, idx[2]) end
                    end
                    RunQueries(queries, next_)
                end)
            end
        end
    end
    Serial(steps, done)
end

function DB.RekeyTables(done)
    local steps = {}
    for _, entry in ipairs(TABLES) do
        if entry.repair ~= false and entry.key then
            steps[#steps + 1] = function(next_)
                KrakensStore.Lifecycle.Migrations = "REKEY " .. entry.name
                RebuildWithKey(entry.name, { "server_id", unpack(entry.key) }, next_)
            end
        end
    end
    Serial(steps, done)
end

DB.Migrations[2] = function(done)
    DB.ListColumns(T_META, function(existing)
        if existing.server_id then Fire(done, true) return end
        local ddl
        for _, query in ipairs(DB.Schema[DB.GetType() == "mysql" and "MySQL" or "SQLite"]) do
            if string.find(query, "krakens_store_meta (", 1, true) then
                ddl = string.gsub(query, "IF NOT EXISTS krakens_store_meta", "krakens_store_meta_ksmig")
            end
        end
        local keyCol = DB.KeyCol()
        DB.Transaction({
            ddl,
            string.format("INSERT INTO krakens_store_meta_ksmig (server_id, %s, value) SELECT '%s', %s, value FROM krakens_store_meta",
                keyCol, DB.GetEscapedServerId(), keyCol),
            "DROP TABLE krakens_store_meta",
            "ALTER TABLE krakens_store_meta_ksmig RENAME TO krakens_store_meta",
        }, function(ok, err) Fire(done, ok ~= false, err) end)
    end)
end

DB.Migrations[3] = function(done)
    Data.GetConfig("pending_recoveries", function(pending, err)
        if err then Fire(done, false, err) return end
        if not istable(pending) or not next(pending) then Fire(done, true) return end
        local queries = {}
        for steamId, entries in pairs(pending) do
            if isstring(steamId) and istable(entries) then
                for _, entry in ipairs(entries) do
                    local amount = math.floor(tonumber(entry.amount) or 0)
                    if amount > 0 then
                        queries[#queries + 1] = string.format(
                            "INSERT INTO krakens_store_recoveries (server_id, steamid, type, amount, reason, created) VALUES ('%s','%s','%s',%d,'%s',%d)",
                            DB.GetEscapedServerId(), Esc(steamId), Esc(tostring(entry.type or "refund")),
                            amount, Esc(tostring(entry.reason or "")), math.floor(tonumber(entry.timestamp) or os.time()))
                    end
                end
            end
        end
        if #queries == 0 then
            Data.DeleteConfig("pending_recoveries")
            Fire(done, true)
            return
        end
        DB.Transaction(queries, function(ok, err2)
            if not ok then
                KrakensStore.Log("error", "Recovery migration aborted, the original blob was kept")
                Fire(done, false, err2)
                return
            end
            Data.DeleteConfig("pending_recoveries")
            KrakensStore.Log("success", "Migrated " .. #queries .. " pending currency recoveries")
            Fire(done, true)
        end)
    end)
end

local function MigrateBlobRows(tableName, transform, done)
    DB.Query(string.format("SELECT id, data FROM %s WHERE %s", tableName, Scope("1=1")), function(rows, err)
        if err then Fire(done, false, err) return end
        local queries = {}
        for _, row in ipairs(rows or {}) do
            local decoded = util.JSONToTable(row.data or "")
            if istable(decoded) and transform(decoded) then
                queries[#queries + 1] = string.format("UPDATE %s SET data='%s' WHERE %s",
                    tableName, Esc(util.TableToJSON(decoded)),
                    Scope(string.format("id='%s'", Esc(row.id))))
            end
        end
        DB.Transaction(queries, function(ok, err2) Fire(done, ok ~= false, err2) end)
    end)
end

DB.Migrations[4] = function(done)
    MigrateBlobRows(T_ITEMS, function(item)
        local pct = tonumber(item.refundPercent)
        if pct == nil then return false end
        item.refundPercent = math.Clamp(math.Round(pct <= 1 and pct * 100 or pct), 0, 100)
        return true
    end, done)
end

local DATA_ALIASES = {
    modelPath = "model", playerModel = "model", armorAmount = "armor", healthAmount = "health",
    buffType = "action", buffValue = "value", trailMaterial = "texture",
}

DB.Migrations[5] = function(done)
    MigrateBlobRows(T_ITEMS, function(item)
        local d = item.data
        if not istable(d) then return false end
        local changed = false
        for legacy, canonical in pairs(DATA_ALIASES) do
            if d[legacy] ~= nil then
                if d[canonical] == nil then d[canonical] = d[legacy] end
                d[legacy] = nil
                changed = true
            end
        end
        if item.type == "permbooster" and d.percents == nil and d.value ~= nil then
            d.percents = d.value
            d.value = nil
            changed = true
        end
        return changed
    end, done)
end

DB.Migrations[6] = function(done)
    Data.GetConfig("general_settings", function(legacy, legacyErr)
        if legacyErr then Fire(done, false, legacyErr) return end
        if not istable(legacy) or not next(legacy) then Fire(done, true) return end
        Data.GetConfig("settings", function(current, currentErr)
            if currentErr then Fire(done, false, currentErr) return end
            local merged = istable(current) and current or {}
            for key, value in pairs(legacy) do
                if key ~= "cvars" and merged[key] == nil then merged[key] = value end
            end
            Data.SetConfig("settings", merged, function(ok, err)
                if not ok then Fire(done, false, err) return end
                Data.DeleteConfig("general_settings")
                Fire(done, true)
            end)
        end)
    end)
end

DB.Migrations[7] = function(done, from)
    if from < 4 then Fire(done, true) return end
    MigrateBlobRows(T_ITEMS, function(item)
        local pct = tonumber(item.refundPercent)
        if pct == nil then return false end
        local percent = math.Clamp(pct > 1 and pct or math.Round(pct * 100, 2), 0, 100)
        if percent == pct then return false end
        item.refundPercent = percent
        return true
    end, done)
end

DB.Migrations[8] = function(done)
    Data.GetConfig("settings", function(current, err)
        if err then Fire(done, false, err) return end
        if not istable(current) then Fire(done, true) return end
        local changed = false
        for key in pairs(current) do
            if string.StartsWith(key, "cvar_") then
                current[key] = nil
                changed = true
            end
        end
        if not changed then Fire(done, true) return end
        Data.SetConfig("settings", current, done)
    end)
end

local LEGACY_DATA_KEYS = { attachment = "attachmentId", weapon = "weaponClass", class = "weaponClass" }
local LEGACY_BOOSTER_INDEX = { "max_health", "max_armor", "speed", "damage_bonus", "jump_power" }

DB.Migrations[9] = function(done)
    MigrateBlobRows(T_ITEMS, function(item)
        local changed = false
        if item.itemData ~= nil then
            if not istable(item.data) and istable(item.itemData) then item.data = item.itemData end
            item.itemData, changed = nil, true
        end
        local d = item.data
        if not istable(d) then return changed end
        for legacy, canonical in pairs(LEGACY_DATA_KEYS) do
            if d[legacy] ~= nil then
                if d[canonical] == nil then d[canonical] = d[legacy] end
                d[legacy], changed = nil, true
            end
        end
        if item.type == "permbooster" then
            if tonumber(d.action) and not isstring(d.action) then
                d.action, changed = LEGACY_BOOSTER_INDEX[tonumber(d.action) + 1], true
            end
            if d.percents == nil and d.value ~= nil then d.percents, d.value, changed = d.value, nil, true end
        end
        return changed
    end, function(ok, err)
        if ok == false then Fire(done, false, err) return end
        DB.Query(string.format("UPDATE %s SET expires = -1 WHERE %s", T_INVENTORY, Scope("expires IS NULL OR expires <= 0")),
            function(_, err2) Fire(done, err2 == nil, err2) end)
    end)
end
