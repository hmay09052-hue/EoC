--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Datenbank (SQLite, sv.db)

    gdp_records:   alle Eintraege (kind = penal | personnel | report | classified)
    gdp_clearance: von Hand vergebene Sicherheitsstufen
    gdp_galaxy:    Lage der Planeten
-------------------------------------------------------------------------------------------------------------]]

GAR_DP.db = GAR_DP.db or {}
local DB = GAR_DP.db

local function Q(text)
    local result = sql.Query(text)
    if result == false then
        ErrorNoHalt("[GAR Datapad] SQL-Fehler: " .. tostring(sql.LastError()) .. "\n  " .. text .. "\n")
    end
    return result
end
DB.Query = Q

local S = sql.SQLStr

Q([[CREATE TABLE IF NOT EXISTS gdp_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    kind TEXT NOT NULL,
    target INTEGER NOT NULL DEFAULT 0,
    author INTEGER NOT NULL DEFAULT 0,
    author_name TEXT NOT NULL DEFAULT '',
    title TEXT NOT NULL DEFAULT '',
    body TEXT NOT NULL DEFAULT '',
    level INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT '',
    extra TEXT NOT NULL DEFAULT '{}',
    created INTEGER NOT NULL DEFAULT 0,
    updated INTEGER NOT NULL DEFAULT 0
)]])
Q("CREATE INDEX IF NOT EXISTS gdp_records_kind ON gdp_records (kind, target)")

Q([[CREATE TABLE IF NOT EXISTS gdp_clearance (
    char_id INTEGER PRIMARY KEY,
    level INTEGER NOT NULL,
    by_name TEXT NOT NULL DEFAULT '',
    at INTEGER NOT NULL DEFAULT 0
)]])

Q([[CREATE TABLE IF NOT EXISTS gdp_galaxy (
    planet TEXT PRIMARY KEY,
    status TEXT NOT NULL DEFAULT '',
    note TEXT NOT NULL DEFAULT '',
    by_name TEXT NOT NULL DEFAULT '',
    at INTEGER NOT NULL DEFAULT 0
)]])

---------------------------------------------------------------------------------------------------------------
-- Eintraege
---------------------------------------------------------------------------------------------------------------
local function FromRow(row)
    return {
        id = tonumber(row.id),
        kind = row.kind,
        target = tonumber(row.target) or 0,
        author = tonumber(row.author) or 0,
        authorName = row.author_name or "",
        title = row.title or "",
        body = row.body or "",
        level = tonumber(row.level) or 1,
        status = row.status or "",
        extra = util.JSONToTable(row.extra or "{}") or {},
        created = tonumber(row.created) or 0,
        updated = tonumber(row.updated) or 0,
    }
end

function DB.List(kind, target)
    local where = "kind = " .. S(kind)
    if target then where = where .. " AND target = " .. math.floor(tonumber(target) or 0) end
    local rows = Q("SELECT * FROM gdp_records WHERE " .. where .. " ORDER BY created DESC LIMIT 500") or {}
    local out = {}
    for _, row in ipairs(rows) do out[#out + 1] = FromRow(row) end
    return out
end

function DB.Get(id)
    local rows = Q("SELECT * FROM gdp_records WHERE id = " .. math.floor(tonumber(id) or 0))
    return rows and rows[1] and FromRow(rows[1]) or nil
end

function DB.Insert(rec)
    local now = os.time()
    Q(string.format("INSERT INTO gdp_records (kind, target, author, author_name, title, body, level, status, extra, created, updated) VALUES (%s, %d, %d, %s, %s, %s, %d, %s, %s, %d, %d)",
        S(rec.kind), rec.target or 0, rec.author or 0, S(rec.authorName or ""), S(rec.title or ""), S(rec.body or ""),
        rec.level or 1, S(rec.status or ""), S(util.TableToJSON(rec.extra or {}) or "{}"), now, now))
    local id = Q("SELECT last_insert_rowid() AS id")
    return id and id[1] and tonumber(id[1].id)
end

function DB.Update(rec)
    Q(string.format("UPDATE gdp_records SET title = %s, body = %s, level = %d, status = %s, extra = %s, updated = %d WHERE id = %d",
        S(rec.title or ""), S(rec.body or ""), rec.level or 1, S(rec.status or ""), S(util.TableToJSON(rec.extra or {}) or "{}"), os.time(), rec.id))
end

function DB.Delete(id)
    Q("DELETE FROM gdp_records WHERE id = " .. math.floor(tonumber(id) or 0))
end

---------------------------------------------------------------------------------------------------------------
-- Sicherheitsstufen von Hand
---------------------------------------------------------------------------------------------------------------
function DB.LoadClearance()
    GAR_DP.manual = {}
    for _, row in ipairs(Q("SELECT * FROM gdp_clearance") or {}) do
        GAR_DP.manual[tonumber(row.char_id)] = { level = tonumber(row.level), by = row.by_name, at = tonumber(row.at) }
    end
end

function DB.SetClearance(charID, level, byName)
    charID = math.floor(tonumber(charID) or 0)
    if level and level > 0 then
        Q(string.format("REPLACE INTO gdp_clearance (char_id, level, by_name, at) VALUES (%d, %d, %s, %d)", charID, level, S(byName or ""), os.time()))
        GAR_DP.manual[charID] = { level = level, by = byName, at = os.time() }
    else
        Q("DELETE FROM gdp_clearance WHERE char_id = " .. charID)
        GAR_DP.manual[charID] = nil
    end
end

---------------------------------------------------------------------------------------------------------------
-- Galaxie-Lage
---------------------------------------------------------------------------------------------------------------
function DB.LoadGalaxy()
    GAR_DP.galaxyState = {}
    local rows = Q("SELECT * FROM gdp_galaxy")
    if not rows or #rows == 0 then
        -- erster Start: Lage aus der Config uebernehmen
        for planet, status in pairs(GAR_DP.Config.GalaxyDefaults or {}) do
            DB.SetGalaxy(planet, status, "", "Oberkommando")
        end
        return
    end
    for _, row in ipairs(rows) do
        GAR_DP.galaxyState[row.planet] = { status = row.status, note = row.note, by = row.by_name, at = tonumber(row.at) }
    end
end

function DB.SetGalaxy(planet, status, note, byName)
    if status == "" or status == nil then
        Q("DELETE FROM gdp_galaxy WHERE planet = " .. S(planet))
        GAR_DP.galaxyState[planet] = nil
        return
    end
    Q(string.format("REPLACE INTO gdp_galaxy (planet, status, note, by_name, at) VALUES (%s, %s, %s, %s, %d)", S(planet), S(status), S(note or ""), S(byName or ""), os.time()))
    GAR_DP.galaxyState[planet] = { status = status, note = note or "", by = byName, at = os.time() }
end

DB.LoadClearance()
DB.LoadGalaxy()
