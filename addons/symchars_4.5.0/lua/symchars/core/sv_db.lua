--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Datenbank (SQLite oder MySQLOO)
-------------------------------------------------------------------------------------------------------------]]

symchars.db = symchars.db or {}

local DB = symchars.db
local cfg = symchars.dbconfig or { mysql = false }

DB.queue = DB.queue or {}
DB.connected = DB.connected or false

local useMySQL = cfg.mysql == true

if useMySQL then
    local ok = pcall(require, "mysqloo")
    if not ok or not mysqloo then
        symchars.print("MySQLOO nicht gefunden - nutze SQLite. (gmsv_mysqloo_* in garrysmod/lua/bin legen)")
        useMySQL = false
    end
end

function DB.IsMySQL() return useMySQL end

-- Gibt einen sicheren, gequoteten String-Literal zurück
local MYSQL_ESCAPES = { ["\0"] = "\\0", ["\\"] = "\\\\", ["'"] = "\\'", ["\""] = "\\\"", ["\n"] = "\\n", ["\r"] = "\\r", ["\26"] = "\\Z" }

function DB.Str(value)
    value = tostring(value == nil and "" or value)
    if useMySQL then
        if DB.conn and DB.connected then
            return "'" .. DB.conn:escape(value) .. "'"
        end
        return "'" .. string.gsub(value, "[%z\\'\"\n\r\26]", MYSQL_ESCAPES) .. "'"
    end
    return sql.SQLStr(value)
end

function DB.Num(value)
    local n = tonumber(value) or 0
    if n ~= n then n = 0 end
    return tostring(math.floor(n))
end

local function Fail(q, err, onError)
    symchars.print("SQL-Fehler: " .. tostring(err))
    symchars.print("  Abfrage: " .. string.sub(tostring(q), 1, 300))
    if onError then onError(err) end
end

local function RunMySQL(q, onSuccess, onError)
    local query = DB.conn:query(q)
    function query:onSuccess(data)
        if onSuccess then onSuccess(data or {}, self:lastInsert()) end
    end
    function query:onError(err)
        if DB.conn:status() ~= mysqloo.DATABASE_CONNECTED then
            DB.connected = false
            table.insert(DB.queue, { q, onSuccess, onError })
            DB.Connect()
            return
        end
        Fail(q, err, onError)
    end
    query:start()
end

function DB.Query(q, onSuccess, onError)
    if useMySQL then
        if not DB.connected then
            table.insert(DB.queue, { q, onSuccess, onError })
            return
        end
        RunMySQL(q, onSuccess, onError)
        return
    end

    local result = sql.Query(q)
    if result == false then
        Fail(q, sql.LastError(), onError)
        return
    end
    if onSuccess then
        local lastId = tonumber(sql.QueryValue("SELECT last_insert_rowid()")) or 0
        onSuccess(result or {}, lastId)
    end
end

-- Mehrere Abfragen nacheinander, Callback am Ende
function DB.Sequence(list, done)
    local i = 0
    local function nextQuery()
        i = i + 1
        if i > #list then
            if done then done() end
            return
        end
        DB.Query(list[i], nextQuery, nextQuery)
    end
    nextQuery()
end

function DB.Connect()
    if not useMySQL then return end
    if DB.connecting then return end
    DB.connecting = true
    DB.conn = mysqloo.connect(cfg.host or "127.0.0.1", cfg.user or "root", cfg.password or "", cfg.database or "gmod", tonumber(cfg.port) or 3306)

    function DB.conn:onConnected()
        DB.connecting = false
        DB.connected = true
        symchars.print("MySQL verbunden.")
        self:setCharacterSet("utf8mb4")
        local queued = DB.queue
        DB.queue = {}
        for _, entry in ipairs(queued) do RunMySQL(entry[1], entry[2], entry[3]) end
    end

    function DB.conn:onConnectionFailed(err)
        DB.connecting = false
        DB.connected = false
        symchars.print("MySQL-Verbindung fehlgeschlagen: " .. tostring(err) .. " - neuer Versuch in 15s")
        timer.Simple(15, DB.Connect)
    end

    DB.conn:connect()
end

---------------------------------------------------------------------------------------------------------------
-- Tabellen
---------------------------------------------------------------------------------------------------------------
local function Schema()
    local my = useMySQL
    local AUTO = my and "INT NOT NULL AUTO_INCREMENT" or "INTEGER PRIMARY KEY AUTOINCREMENT"
    local KEY = my and "VARCHAR(64)" or "TEXT"
    local PK_AUTO = my and ", PRIMARY KEY (id)" or ""
    local ENGINE = my and " ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" or ""

    local list = {}

    if my then
        list[#list + 1] = [[CREATE TABLE IF NOT EXISTS sy_characters (
            charID INT NOT NULL AUTO_INCREMENT, charActive INT NOT NULL DEFAULT 1, charUser VARCHAR(255) NOT NULL,
            name VARCHAR(255) NOT NULL, model VARCHAR(255) NOT NULL, job VARCHAR(255) NOT NULL, createdAt TEXT NOT NULL,
            lastActive TEXT NOT NULL, faction VARCHAR(255) NOT NULL DEFAULT 'none', `rank` INT NOT NULL DEFAULT 1,
            money INT NOT NULL DEFAULT 0, data TEXT, roleplayID VARCHAR(255) NOT NULL DEFAULT 'none', customs TEXT,
            PRIMARY KEY (charID))]] .. ENGINE
        list[#list + 1] = "CREATE TABLE IF NOT EXISTS sy_whitelist (steamid VARCHAR(255) NOT NULL, json TEXT NOT NULL, PRIMARY KEY (steamid))" .. ENGINE
    else
        list[#list + 1] = [[CREATE TABLE IF NOT EXISTS sy_characters (
            charID INTEGER PRIMARY KEY AUTOINCREMENT, charActive INTEGER NOT NULL DEFAULT 1, charUser TEXT NOT NULL,
            name TEXT NOT NULL, model TEXT NOT NULL, job TEXT NOT NULL, createdAt TEXT NOT NULL, lastActive TEXT NOT NULL,
            faction TEXT NOT NULL DEFAULT 'none', `rank` INTEGER NOT NULL DEFAULT 1, money INTEGER NOT NULL DEFAULT 0,
            data TEXT, roleplayID TEXT NOT NULL DEFAULT 'none', customs TEXT DEFAULT 'none')]]
        list[#list + 1] = "CREATE TABLE IF NOT EXISTS sy_whitelist (steamid TEXT NOT NULL PRIMARY KEY, json TEXT NOT NULL)"
    end

    list[#list + 1] = "CREATE TABLE IF NOT EXISTS sc_settings (k " .. KEY .. " NOT NULL PRIMARY KEY, v TEXT)" .. ENGINE
    list[#list + 1] = "CREATE TABLE IF NOT EXISTS sc_factions (id " .. KEY .. " NOT NULL PRIMARY KEY, data TEXT)" .. ENGINE
    list[#list + 1] = "CREATE TABLE IF NOT EXISTS sc_history (charID INT NOT NULL PRIMARY KEY, data TEXT)" .. ENGINE
    list[#list + 1] = "CREATE TABLE IF NOT EXISTS sc_trainings (id " .. KEY .. " NOT NULL PRIMARY KEY, data TEXT)" .. ENGINE
    list[#list + 1] = "CREATE TABLE IF NOT EXISTS sc_char_trainings (charID INT NOT NULL, training " .. KEY .. " NOT NULL, grantedAt INT NOT NULL DEFAULT 0, grantedBy INT NOT NULL DEFAULT 0, grantedByName TEXT, note TEXT, expiresAt INT NOT NULL DEFAULT 0, PRIMARY KEY (charID, training))" .. ENGINE
    list[#list + 1] = "CREATE TABLE IF NOT EXISTS sc_docs (id " .. AUTO .. ", folder " .. KEY .. " NOT NULL, title TEXT, data " .. (my and "MEDIUMTEXT" or "TEXT") .. ", perms TEXT, createdBy TEXT, createdBySteam " .. KEY .. ", createdAt INT NOT NULL DEFAULT 0, updatedAt INT NOT NULL DEFAULT 0, updatedBy TEXT" .. PK_AUTO .. ")" .. ENGINE
    list[#list + 1] = "CREATE TABLE IF NOT EXISTS sc_holos (id " .. AUTO .. ", map " .. KEY .. " NOT NULL, class " .. KEY .. " NOT NULL, pos TEXT, ang TEXT, data TEXT" .. PK_AUTO .. ")" .. ENGINE

    return list
end

function DB.Init(done)
    if useMySQL then DB.Connect() end
    DB.Sequence(Schema(), function()
        symchars.print("Datenbank bereit (" .. (useMySQL and "MySQL" or "SQLite") .. ").")
        if done then done() end
    end)
end

-- Einfache Schlüssel/Wert-Speicherung (REPLACE funktioniert in SQLite und MySQL)
function DB.Replace(tbl, cols, values, done)
    local q = "REPLACE INTO " .. tbl .. " (" .. table.concat(cols, ", ") .. ") VALUES (" .. table.concat(values, ", ") .. ")"
    DB.Query(q, done)
end
