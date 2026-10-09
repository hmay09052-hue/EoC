local WS = GRNSerials
WS.DB = WS.DB or {}
local DB = WS.DB

-- SQLite über sql.Query reicht für einen Server. Für mehrere Server mit
-- gemeinsamer Datenbank kann DB.Query/DB.Row durch MySQLOO ersetzt werden;
-- der Rest des Systems spricht nur über diese Funktionen mit der Datenbank.

local function esc(v)
    if v == nil then return "NULL" end
    if isbool(v) then return v and "1" or "0" end
    if isnumber(v) then
        if v ~= v or v == math.huge or v == -math.huge then return "0" end
        return tostring(v)
    end
    return sql.SQLStr(tostring(v))
end
DB.Escape = esc

-- DB.Query("SELECT * FROM t WHERE a = ? AND b = ?", 1, "x")
function DB.Format(q, ...)
    local args = { ... }
    local n = select("#", ...)
    local i = 0
    return (string.gsub(q, "%?", function()
        i = i + 1
        if i > n then return "NULL" end
        return esc(args[i])
    end))
end

function DB.Query(q, ...)
    local query = DB.Format(q, ...)
    local res = sql.Query(query)
    if res == false then
        ErrorNoHalt("[GRN Serials] SQL-Fehler: " .. tostring(sql.LastError()) .. "\n  " .. query .. "\n")
    end
    return res
end

function DB.Rows(q, ...)
    local res = DB.Query(q, ...)
    return istable(res) and res or {}
end

function DB.Row(q, ...)
    return DB.Rows(q, ...)[1]
end

function DB.Value(q, ...)
    local row = DB.Row(q, ...)
    if not row then return nil end
    for _, v in pairs(row) do return v end
end

local function addColumn(tbl, col, def)
    local info = DB.Rows("PRAGMA table_info(" .. tbl .. ")")
    for _, c in ipairs(info) do
        if c.name == col then return end
    end
    sql.Query("ALTER TABLE " .. tbl .. " ADD COLUMN " .. col .. " " .. def)
end

function DB.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS ws_counter (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at INTEGER)]])
    sql.Query([[CREATE TABLE IF NOT EXISTS ws_weapons (
        serial TEXT PRIMARY KEY,
        class TEXT NOT NULL,
        base TEXT,
        created_at INTEGER,
        condition REAL DEFAULT 100,
        dirt REAL DEFAULT 0,
        rounds_fired INTEGER DEFAULT 0,
        owner_sid64 TEXT,
        owner_name TEXT,
        regiment_id TEXT,
        status TEXT DEFAULT 'STORED',
        nickname TEXT,
        nick_changed_at INTEGER DEFAULT 0,
        is_tradition INTEGER DEFAULT 0,
        honor_name TEXT,
        kills_total INTEGER DEFAULT 0,
        holders INTEGER DEFAULT 0,
        longest_kill REAL DEFAULT 0,
        locked INTEGER DEFAULT 0,
        batch TEXT,
        captured_once INTEGER DEFAULT 0,
        barrel_rounds INTEGER DEFAULT 0,
        last_transfer INTEGER DEFAULT 0,
        status_since INTEGER DEFAULT 0,
        item_id TEXT
    )]])
    sql.Query([[CREATE INDEX IF NOT EXISTS ws_weapons_owner ON ws_weapons(owner_sid64)]])
    sql.Query([[CREATE INDEX IF NOT EXISTS ws_weapons_regiment ON ws_weapons(regiment_id, status)]])

    sql.Query([[CREATE TABLE IF NOT EXISTS ws_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial TEXT NOT NULL,
        type TEXT NOT NULL,
        actor_sid64 TEXT,
        target_sid64 TEXT,
        data TEXT,
        ts INTEGER
    )]])
    sql.Query([[CREATE INDEX IF NOT EXISTS ws_events_serial ON ws_events(serial, type, ts)]])
    sql.Query([[CREATE INDEX IF NOT EXISTS ws_events_actor ON ws_events(actor_sid64, ts)]])

    sql.Query([[CREATE TABLE IF NOT EXISTS ws_milestones (
        serial TEXT NOT NULL,
        milestone TEXT NOT NULL,
        holder_sid64 TEXT,
        holder_name TEXT,
        ts INTEGER,
        PRIMARY KEY (serial, milestone)
    )]])

    sql.Query([[CREATE TABLE IF NOT EXISTS ws_regiment_chronicle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        regiment_id TEXT,
        serial TEXT,
        text TEXT,
        ts INTEGER
    )]])
    sql.Query([[CREATE INDEX IF NOT EXISTS ws_chronicle_regiment ON ws_regiment_chronicle(regiment_id, ts)]])

    -- Besitzerkette: ein Eintrag pro Trägerzeit (dauerhaft).
    sql.Query([[CREATE TABLE IF NOT EXISTS ws_holders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial TEXT NOT NULL,
        holder_sid64 TEXT,
        holder_name TEXT,
        from_ts INTEGER,
        to_ts INTEGER,
        kills INTEGER DEFAULT 0,
        ended TEXT
    )]])
    sql.Query([[CREATE INDEX IF NOT EXISTS ws_holders_serial ON ws_holders(serial, from_ts)]])

    sql.Query([[CREATE TABLE IF NOT EXISTS ws_tradition_proposals (
        serial TEXT PRIMARY KEY,
        regiment_id TEXT,
        proposer_sid64 TEXT,
        proposer_name TEXT,
        honor_name TEXT,
        ts INTEGER
    )]])

    -- Spätere Spalten bei bestehenden Datenbanken nachziehen.
    addColumn("ws_weapons", "status_since", "INTEGER DEFAULT 0")
    addColumn("ws_weapons", "item_id", "TEXT")
end

function DB.NextCounter()
    sql.Query("INSERT INTO ws_counter (created_at) VALUES (" .. os.time() .. ")")
    return tonumber(sql.QueryValue("SELECT last_insert_rowid()")) or 0
end

local WEAPON_COLUMNS = {
    "class", "base", "created_at", "condition", "dirt", "rounds_fired", "owner_sid64", "owner_name",
    "regiment_id", "status", "nickname", "nick_changed_at", "is_tradition", "honor_name", "kills_total",
    "holders", "longest_kill", "locked", "batch", "captured_once", "barrel_rounds", "last_transfer", "status_since",
    "item_id",
}
DB.WeaponColumns = WEAPON_COLUMNS

local NUMERIC = {
    created_at = true, condition = true, dirt = true, rounds_fired = true, nick_changed_at = true,
    is_tradition = true, kills_total = true, holders = true, longest_kill = true, locked = true,
    captured_once = true, barrel_rounds = true, last_transfer = true, status_since = true,
}

function DB.Normalize(row)
    if not row then return nil end
    for col in pairs(NUMERIC) do row[col] = tonumber(row[col]) or 0 end
    for _, col in ipairs({ "owner_sid64", "owner_name", "regiment_id", "nickname", "honor_name", "batch", "base", "item_id" }) do
        if row[col] == "NULL" then row[col] = nil end
    end
    row.is_tradition = row.is_tradition == 1
    row.locked = row.locked == 1
    row.captured_once = row.captured_once == 1
    return row
end

function DB.LoadWeapon(serial)
    return DB.Normalize(DB.Row("SELECT * FROM ws_weapons WHERE serial = ?", serial))
end

function DB.InsertWeapon(rec)
    local cols, vals = { "serial" }, { esc(rec.serial) }
    for _, c in ipairs(WEAPON_COLUMNS) do
        cols[#cols + 1] = c
        vals[#vals + 1] = esc(rec[c])
    end
    return DB.Query("INSERT INTO ws_weapons (" .. table.concat(cols, ",") .. ") VALUES (" .. table.concat(vals, ",") .. ")")
end

function DB.SaveWeapon(rec)
    local sets = {}
    for _, c in ipairs(WEAPON_COLUMNS) do
        sets[#sets + 1] = c .. " = " .. esc(rec[c])
    end
    return DB.Query("UPDATE ws_weapons SET " .. table.concat(sets, ", ") .. " WHERE serial = " .. esc(rec.serial))
end

function DB.AddEvent(serial, typ, actor, target, data)
    local json = istable(data) and util.TableToJSON(data, false) or nil
    DB.Query("INSERT INTO ws_events (serial, type, actor_sid64, target_sid64, data, ts) VALUES (?, ?, ?, ?, ?, ?)",
        serial, typ, actor, target, json, os.time())
end

-- Detail-Ereignisse begrenzen (Summen bleiben in ws_weapons).
function DB.TrimEvents(serial, typ, keep)
    DB.Query([[DELETE FROM ws_events WHERE serial = ? AND type = ? AND id NOT IN
        (SELECT id FROM ws_events WHERE serial = ? AND type = ? ORDER BY id DESC LIMIT ?)]], serial, typ, serial, typ, keep)
end
