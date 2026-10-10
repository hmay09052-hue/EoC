--[[
    EoC Range – Datenbank (SQLite sv.db, optional MySQL über mysqloo) und Ranglisten-Cache

    eocr_runs         alle Läufe (flagged: 0 = gültig, 1 = verdächtig/ungeprüft, 2 = zurückgesetzt)
    eocr_best         Bestwert je Charakter, Disziplin und Zeitraum ("all", "m:2026-10", "w:2026-10-05")
    eocr_badges       Schützenabzeichen
    eocr_disciplines  eigene Disziplinen der Ausbilder (JSON)
    eocr_lanes        Bahnen und Ziele pro Map (zusätzlich data/eoc_range/maps/<map>.json)
    eocr_trophies     Wochenpokal-Archiv
]]

EoCRange.DB = EoCRange.DB or {}
local DB = EoCRange.DB
local C = EoCRange.Config

local useMySQL, conn, connected = false, nil, false
local queue = {}

file.CreateDir("eoc_range")
file.CreateDir("eoc_range/logs")
file.CreateDir("eoc_range/maps")

---------------------------------------------------------------------------
-- Grundfunktionen
---------------------------------------------------------------------------
function DB.IsMySQL() return useMySQL end

function DB.Str(value)
    value = tostring(value == nil and "" or value)
    if useMySQL and conn then return "'" .. conn:escape(value) .. "'" end
    return sql.SQLStr(value)
end

function DB.Num(value)
    local n = tonumber(value) or 0
    if n ~= n or n == math.huge or n == -math.huge then n = 0 end
    if n == math.floor(n) then return string.format("%d", n) end
    return string.format("%.4f", n)
end

local function Fail(q, err)
    ErrorNoHalt("[EoC Range] Datenbankfehler: " .. tostring(err) .. "\n  " .. string.sub(q, 1, 300) .. "\n")
end

-- ok(rows, lastInsertId)
function DB.Query(q, ok, fail)
    if useMySQL then
        if not connected then
            queue[#queue + 1] = { q, ok, fail }
            return
        end
        local query = conn:query(q)
        function query:onSuccess(data)
            if ok then ok(data or {}, self:lastInsert()) end
        end
        function query:onError(err)
            Fail(q, err)
            if fail then fail(err) end
        end
        query:start()
        return
    end

    local r = sql.Query(q)
    if r == false then
        local err = sql.LastError()
        Fail(q, err)
        if fail then fail(err) end
        return
    end
    if ok then
        local last
        if string.find(string.upper(string.sub(q, 1, 12)), "INSERT", 1, true) then
            last = tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
        end
        ok(r or {}, last)
    end
end

-- Mehrere Abfragen nacheinander
function DB.Sequence(list, done)
    local i = 0
    local function step()
        i = i + 1
        if i > #list then
            if done then done() end
            return
        end
        DB.Query(list[i], step, step)
    end
    step()
end

local function Schema()
    if useMySQL then
        return {
            [[CREATE TABLE IF NOT EXISTS eocr_runs (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, char_id BIGINT, steamid VARCHAR(32), name VARCHAR(96),
                unit VARCHAR(64), unit_name VARCHAR(64), discipline VARCHAR(48), score DOUBLE, time DOUBLE, hits INT, shots INT, accuracy DOUBLE,
                react DOUBLE, created INT, week VARCHAR(16), month VARCHAR(16), flagged INT, exam INT, instructor VARCHAR(96), instructor_sid VARCHAR(32),
                lane INT, map VARCHAR(64), data MEDIUMTEXT, INDEX idx_cd (char_id, discipline), INDEX idx_disc (discipline, flagged))]],
            [[CREATE TABLE IF NOT EXISTS eocr_best (char_id BIGINT NOT NULL, discipline VARCHAR(48) NOT NULL, period VARCHAR(16) NOT NULL, score DOUBLE,
                run_id INT, name VARCHAR(96), unit VARCHAR(64), unit_name VARCHAR(64), created INT, PRIMARY KEY (char_id, discipline, period),
                INDEX idx_dp (discipline, period))]],
            [[CREATE TABLE IF NOT EXISTS eocr_badges (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, char_id BIGINT, steamid VARCHAR(32), name VARCHAR(96),
                level INT, created INT, instructor VARCHAR(96), instructor_sid VARCHAR(32), revoked INT, reason TEXT, revoked_by VARCHAR(96), revoked_at INT)]],
            [[CREATE TABLE IF NOT EXISTS eocr_disciplines (id VARCHAR(32) NOT NULL PRIMARY KEY, data TEXT, created_by VARCHAR(96), created INT)]],
            [[CREATE TABLE IF NOT EXISTS eocr_lanes (map VARCHAR(64) NOT NULL PRIMARY KEY, data MEDIUMTEXT, updated INT)]],
            [[CREATE TABLE IF NOT EXISTS eocr_trophies (week VARCHAR(16) NOT NULL PRIMARY KEY, unit VARCHAR(64), unit_name VARCHAR(64), score DOUBLE, created INT)]],
        }
    end
    return {
        [[CREATE TABLE IF NOT EXISTS eocr_runs (id INTEGER PRIMARY KEY AUTOINCREMENT, char_id INTEGER, steamid TEXT, name TEXT, unit TEXT, unit_name TEXT,
            discipline TEXT, score REAL, time REAL, hits INTEGER, shots INTEGER, accuracy REAL, react REAL, created INTEGER, week TEXT, month TEXT,
            flagged INTEGER, exam INTEGER, instructor TEXT, instructor_sid TEXT, lane INTEGER, map TEXT, data TEXT)]],
        [[CREATE INDEX IF NOT EXISTS eocr_runs_cd ON eocr_runs (char_id, discipline)]],
        [[CREATE INDEX IF NOT EXISTS eocr_runs_disc ON eocr_runs (discipline, flagged)]],
        [[CREATE TABLE IF NOT EXISTS eocr_best (char_id INTEGER, discipline TEXT, period TEXT, score REAL, run_id INTEGER, name TEXT, unit TEXT,
            unit_name TEXT, created INTEGER, PRIMARY KEY (char_id, discipline, period))]],
        [[CREATE INDEX IF NOT EXISTS eocr_best_dp ON eocr_best (discipline, period)]],
        [[CREATE TABLE IF NOT EXISTS eocr_badges (id INTEGER PRIMARY KEY AUTOINCREMENT, char_id INTEGER, steamid TEXT, name TEXT, level INTEGER,
            created INTEGER, instructor TEXT, instructor_sid TEXT, revoked INTEGER, reason TEXT, revoked_by TEXT, revoked_at INTEGER)]],
        [[CREATE TABLE IF NOT EXISTS eocr_disciplines (id TEXT PRIMARY KEY, data TEXT, created_by TEXT, created INTEGER)]],
        [[CREATE TABLE IF NOT EXISTS eocr_lanes (map TEXT PRIMARY KEY, data TEXT, updated INTEGER)]],
        [[CREATE TABLE IF NOT EXISTS eocr_trophies (week TEXT PRIMARY KEY, unit TEXT, unit_name TEXT, score REAL, created INTEGER)]],
    }
end

function DB.Init(done)
    local M = C.MySQL or {}
    if M.Enabled then
        local okReq = pcall(require, "mysqloo")
        if okReq and mysqloo then
            conn = mysqloo.connect(M.Host, M.User, M.Password, M.Database, M.Port)
            useMySQL = true
            function conn:onConnected()
                connected = true
                MsgC(Color(255, 190, 50), "[EoC Range] ", color_white, "MySQL verbunden.\n")
                local pending = queue
                queue = {}
                DB.Sequence(Schema(), function()
                    for _, q in ipairs(pending) do DB.Query(q[1], q[2], q[3]) end
                    if done then done() end
                end)
            end
            function conn:onConnectionFailed(err)
                MsgC(Color(225, 88, 88), "[EoC Range] ", color_white, "MySQL fehlgeschlagen (" .. tostring(err) .. "), nutze SQLite.\n")
                useMySQL, conn = false, nil
                local pending = queue
                queue = {}
                DB.Sequence(Schema(), function()
                    for _, q in ipairs(pending) do DB.Query(q[1], q[2], q[3]) end
                    if done then done() end
                end)
            end
            conn:connect()
            return
        end
        MsgC(Color(225, 88, 88), "[EoC Range] ", color_white, "mysqloo nicht installiert, nutze SQLite.\n")
    end
    DB.Sequence(Schema(), done)
end

-- SQLite liefert alles als Text: Zahlenspalten umwandeln
local NUMERIC = {
    id = true, char_id = true, score = true, time = true, hits = true, shots = true, accuracy = true, react = true, created = true,
    flagged = true, exam = true, lane = true, run_id = true, level = true, revoked = true, revoked_at = true, lvl = true, n = true, v = true,
}

local function Row(r)
    for k, v in pairs(r) do
        if NUMERIC[k] then r[k] = tonumber(v) or 0 end
    end
    return r
end
DB.Row = Row

local function Rows(rows)
    for i, r in ipairs(rows or {}) do rows[i] = Row(r) end
    return rows or {}
end

local function Order(def)
    return (def and def.scoring == "time") and "ASC" or "DESC"
end

local function Cmp(def)
    return (def and def.scoring == "time") and "<" or ">"
end

---------------------------------------------------------------------------
-- Läufe
---------------------------------------------------------------------------
function DB.InsertRun(r, cb)
    local cols = { "char_id", "steamid", "name", "unit", "unit_name", "discipline", "score", "time", "hits", "shots", "accuracy", "react",
        "created", "week", "month", "flagged", "exam", "instructor", "instructor_sid", "lane", "map", "data" }
    local vals = {
        DB.Num(r.char_id), DB.Str(r.steamid), DB.Str(r.name), DB.Str(r.unit), DB.Str(r.unit_name), DB.Str(r.discipline), DB.Num(r.score),
        DB.Num(r.time), DB.Num(r.hits), DB.Num(r.shots), DB.Num(r.accuracy), DB.Num(r.react), DB.Num(r.created), DB.Str(r.week),
        DB.Str(r.month), DB.Num(r.flagged), DB.Num(r.exam), DB.Str(r.instructor), DB.Str(r.instructor_sid), DB.Num(r.lane), DB.Str(r.map),
        DB.Str(r.data),
    }
    DB.Query("INSERT INTO eocr_runs (" .. table.concat(cols, ", ") .. ") VALUES (" .. table.concat(vals, ", ") .. ")", function(_, id)
        if cb then cb(tonumber(id)) end
    end, function() if cb then cb(nil) end end)
end

function DB.GetRun(id, cb)
    DB.Query("SELECT * FROM eocr_runs WHERE id = " .. DB.Num(id), function(rows) cb(rows[1] and Row(rows[1]) or nil) end, function() cb(nil) end)
end

function DB.DeleteRun(id, cb)
    DB.Query("DELETE FROM eocr_runs WHERE id = " .. DB.Num(id), cb, cb)
end

function DB.SetFlag(id, flag, cb)
    DB.Query("UPDATE eocr_runs SET flagged = " .. DB.Num(flag) .. " WHERE id = " .. DB.Num(id), cb, cb)
end

-- filter: discipline, flagged (true = nur ungeprüfte), exam, instructor_sid, search, limit
function DB.ListRuns(filter, cb)
    local where = {}
    if filter.discipline and filter.discipline ~= "" then where[#where + 1] = "discipline = " .. DB.Str(filter.discipline) end
    if filter.flagged then where[#where + 1] = "flagged = 1" end
    if filter.exam then where[#where + 1] = "exam = 1" end
    if filter.instructor_sid then where[#where + 1] = "instructor_sid = " .. DB.Str(filter.instructor_sid) end
    if filter.char_id then where[#where + 1] = "char_id = " .. DB.Num(filter.char_id) end
    if filter.search and filter.search ~= "" then
        where[#where + 1] = "(name LIKE " .. DB.Str("%" .. filter.search .. "%") .. " OR steamid = " .. DB.Str(filter.search) .. ")"
    end
    local q = "SELECT id, char_id, steamid, name, unit, unit_name, discipline, score, time, hits, shots, accuracy, react, created, flagged, exam, instructor, instructor_sid, lane FROM eocr_runs"
    if #where > 0 then q = q .. " WHERE " .. table.concat(where, " AND ") end
    q = q .. " ORDER BY id DESC LIMIT " .. DB.Num(math.Clamp(filter.limit or 100, 1, 300))
    DB.Query(q, function(rows) cb(Rows(rows)) end, function() cb({}) end)
end

function DB.LaneRecord(def, lane, map, cb)
    local agg = def.scoring == "time" and "MIN" or "MAX"
    DB.Query("SELECT " .. agg .. "(score) AS v FROM eocr_runs WHERE discipline = " .. DB.Str(def.id) .. " AND lane = " .. DB.Num(lane)
        .. " AND map = " .. DB.Str(map) .. " AND flagged = 0", function(rows)
        cb(rows[1] and tonumber(rows[1].v) or nil)
    end, function() cb(nil) end)
end

---------------------------------------------------------------------------
-- Bestwerte
---------------------------------------------------------------------------
function DB.BestOf(charId, discId, period, cb)
    DB.Query("SELECT score FROM eocr_best WHERE char_id = " .. DB.Num(charId) .. " AND discipline = " .. DB.Str(discId)
        .. " AND period = " .. DB.Str(period), function(rows)
        cb(rows[1] and tonumber(rows[1].score) or nil)
    end, function() cb(nil) end)
end

local function ReplaceBest(r, period)
    return "REPLACE INTO eocr_best (char_id, discipline, period, score, run_id, name, unit, unit_name, created) VALUES ("
        .. DB.Num(r.char_id) .. ", " .. DB.Str(r.discipline) .. ", " .. DB.Str(period) .. ", " .. DB.Num(r.score) .. ", "
        .. DB.Num(r.run_id) .. ", " .. DB.Str(r.name) .. ", " .. DB.Str(r.unit) .. ", " .. DB.Str(r.unit_name) .. ", " .. DB.Num(r.created) .. ")"
end

-- Neuen Lauf in die Bestwerte eintragen (nur wenn besser). cb(changed = { all = true, ... })
function DB.UpdateBest(def, r, cb)
    local keys = { "all", r.month, r.week }
    local inList = {}
    for _, k in ipairs(keys) do inList[#inList + 1] = DB.Str(k) end
    DB.Query("SELECT period, score FROM eocr_best WHERE char_id = " .. DB.Num(r.char_id) .. " AND discipline = " .. DB.Str(def.id)
        .. " AND period IN (" .. table.concat(inList, ", ") .. ")", function(rows)
        local current = {}
        for _, row in ipairs(rows) do current[row.period] = tonumber(row.score) end
        local qs, changed = {}, {}
        for _, k in ipairs(keys) do
            if EoCRange.Better(def, r.score, current[k]) then
                qs[#qs + 1] = ReplaceBest(r, k)
                changed[k] = true
            end
        end
        -- Name und Einheit in allen Bestwerten aktuell halten (Beförderung, Einheitenwechsel)
        qs[#qs + 1] = "UPDATE eocr_best SET name = " .. DB.Str(r.name) .. ", unit = " .. DB.Str(r.unit) .. ", unit_name = " .. DB.Str(r.unit_name)
            .. " WHERE char_id = " .. DB.Num(r.char_id)
        DB.Sequence(qs, function() if cb then cb(changed) end end)
    end, function() if cb then cb({}) end end)
end

-- Bestwerte eines Charakters in einer Disziplin aus den gültigen Läufen neu aufbauen (nach Löschen/Freigabe)
function DB.RecomputeBest(charId, discId, cb)
    local def = EoCRange.GetDiscipline(discId)
    DB.Query("SELECT id, score, created, week, month, name, unit, unit_name FROM eocr_runs WHERE char_id = " .. DB.Num(charId)
        .. " AND discipline = " .. DB.Str(discId) .. " AND flagged = 0", function(rows)
        local best = {}
        for _, r in ipairs(Rows(rows)) do
            for _, k in ipairs({ "all", r.month, r.week }) do
                if k and k ~= "" and (not best[k] or EoCRange.Better(def, r.score, best[k].score)) then best[k] = r end
            end
        end
        local qs = { "DELETE FROM eocr_best WHERE char_id = " .. DB.Num(charId) .. " AND discipline = " .. DB.Str(discId) }
        if def then
            for k, r in pairs(best) do
                qs[#qs + 1] = ReplaceBest({ char_id = charId, discipline = discId, score = r.score, run_id = r.id, name = r.name,
                    unit = r.unit, unit_name = r.unit_name, created = r.created }, k)
            end
        end
        DB.Sequence(qs, cb)
    end, cb)
end

function DB.Top(def, period, limit, unit, cb)
    local q = "SELECT char_id, name, unit, unit_name, score, created, run_id FROM eocr_best WHERE discipline = " .. DB.Str(def.id)
        .. " AND period = " .. DB.Str(period)
    if unit then q = q .. " AND unit = " .. DB.Str(unit) end
    q = q .. " ORDER BY score " .. Order(def) .. ", created ASC LIMIT " .. DB.Num(limit or 10)
    DB.Query(q, function(rows) cb(Rows(rows)) end, function() cb({}) end)
end

-- Platz eines Wertes (1 = bester)
function DB.Rank(def, period, value, unit, cb)
    local q = "SELECT COUNT(*) AS n FROM eocr_best WHERE discipline = " .. DB.Str(def.id) .. " AND period = " .. DB.Str(period)
        .. " AND score " .. Cmp(def) .. " " .. DB.Num(value)
    if unit then q = q .. " AND unit = " .. DB.Str(unit) end
    DB.Query(q, function(rows) cb((tonumber(rows[1] and rows[1].n) or 0) + 1) end, function() cb(nil) end)
end

function DB.PeriodRows(period, discId, cb)
    local q = "SELECT char_id, discipline, unit, unit_name, score FROM eocr_best WHERE period = " .. DB.Str(period)
    if discId then q = q .. " AND discipline = " .. DB.Str(discId) end
    DB.Query(q, function(rows) cb(Rows(rows)) end, function() cb({}) end)
end

function DB.PersonalBests(charId, cb)
    local keys = { DB.Str("all"), DB.Str(EoCRange.MonthKey()), DB.Str(EoCRange.WeekKey()) }
    DB.Query("SELECT discipline, period, score FROM eocr_best WHERE char_id = " .. DB.Num(charId) .. " AND period IN (" .. table.concat(keys, ", ") .. ")",
        function(rows) cb(Rows(rows)) end, function() cb({}) end)
end

-- Rangliste zurücksetzen: Bestwerte löschen und die zugehörigen Läufe als "zurückgesetzt" markieren (Archiv bleibt erhalten)
function DB.ResetBoard(discId, period, cb)
    local qs = {}
    local runWhere = { "flagged = 0" }
    local bestWhere = {}
    if discId then
        runWhere[#runWhere + 1] = "discipline = " .. DB.Str(discId)
        bestWhere[#bestWhere + 1] = "discipline = " .. DB.Str(discId)
    end
    if period == "week" then
        local k = EoCRange.WeekKey()
        runWhere[#runWhere + 1] = "week = " .. DB.Str(k)
        bestWhere[#bestWhere + 1] = "period = " .. DB.Str(k)
    elseif period == "month" then
        local k = EoCRange.MonthKey()
        runWhere[#runWhere + 1] = "month = " .. DB.Str(k)
        bestWhere[#bestWhere + 1] = "period = " .. DB.Str(k)
    end
    qs[#qs + 1] = "UPDATE eocr_runs SET flagged = 2 WHERE " .. table.concat(runWhere, " AND ")
    qs[#qs + 1] = "DELETE FROM eocr_best" .. (#bestWhere > 0 and (" WHERE " .. table.concat(bestWhere, " AND ")) or "")
    -- Bei Woche/Monat bleiben die Allzeit-Bestwerte; sie werden aus den verbleibenden Läufen neu berechnet
    DB.Sequence(qs, function()
        if period ~= "week" and period ~= "month" then
            if cb then cb() end
            return
        end
        local q = "SELECT DISTINCT char_id, discipline FROM eocr_runs WHERE flagged = 2" .. (discId and (" AND discipline = " .. DB.Str(discId)) or "")
        DB.Query(q, function(rows)
            local i = 0
            local function nextOne()
                i = i + 1
                local r = rows[i]
                if not r then if cb then cb() end return end
                DB.RecomputeBest(tonumber(r.char_id), r.discipline, nextOne)
            end
            nextOne()
        end, cb)
    end)
end

---------------------------------------------------------------------------
-- Ranglisten-Cache
---------------------------------------------------------------------------
EoCRange.Boards = EoCRange.Boards or {}       -- [disc] = { all = {...}, month = {...}, week = {...}, units = {...} }
EoCRange.UnitOverall = EoCRange.UnitOverall or {}

local function Entry(r)
    return { c = r.char_id, n = r.name, u = r.unit, un = EoCRange.UnitName(r.unit, r.unit_name), s = r.score }
end

-- Einheitenwertung: Durchschnitt der besten N Schützen je Einheit
function EoCRange.ComputeUnitScores(def, rows)
    local byUnit = {}
    for _, r in ipairs(rows) do
        if r.unit and r.unit ~= "" then
            local u = byUnit[r.unit]
            if not u then
                u = { unit = r.unit, name = EoCRange.UnitName(r.unit, r.unit_name), scores = {} }
                byUnit[r.unit] = u
            end
            u.scores[#u.scores + 1] = tonumber(r.score) or 0
        end
    end
    local out = {}
    for _, u in pairs(byUnit) do
        table.sort(u.scores, function(a, b) return EoCRange.Better(def, a, b) end)
        local n, sum = math.min(#u.scores, C.UnitScoreTop or 5), 0
        for i = 1, n do sum = sum + u.scores[i] end
        out[#out + 1] = { u = u.unit, un = u.name, v = n > 0 and (sum / n) or 0, n = #u.scores }
    end
    table.sort(out, function(a, b) return EoCRange.Better(def, a.v, b.v) end)
    return out
end

-- Gesamtwertung über alle Disziplinen: je Disziplin 0..1000 relativ zur besten Einheit, dann Summe
function EoCRange.ComputeOverall(unitsByDisc)
    local total = {}
    for discId, list in pairs(unitsByDisc) do
        local def = EoCRange.GetDiscipline(discId)
        local best = list[1] and list[1].v
        if def and best and best > 0 then
            for _, u in ipairs(list) do
                local pts
                if def.scoring == "time" then pts = u.v > 0 and (best / u.v * 1000) or 0 else pts = u.v / best * 1000 end
                local t = total[u.u]
                if not t then
                    t = { u = u.u, un = u.un, v = 0 }
                    total[u.u] = t
                end
                t.v = t.v + math.max(pts, 0)
            end
        end
    end
    local out = {}
    for _, t in pairs(total) do
        t.v = math.Round(t.v)
        out[#out + 1] = t
    end
    table.sort(out, function(a, b) return a.v > b.v end)
    return out
end

local function RecomputeOverall()
    local byDisc = {}
    for id, b in pairs(EoCRange.Boards) do byDisc[id] = b.units or {} end
    EoCRange.UnitOverall = EoCRange.ComputeOverall(byDisc)
end

function DB.RefreshDiscipline(discId, cb)
    local def = EoCRange.GetDiscipline(discId)
    if not def then
        EoCRange.Boards[discId] = nil
        RecomputeOverall()
        if cb then cb() end
        return
    end
    local b = { all = {}, month = {}, week = {}, units = {} }
    DB.Top(def, "all", 10, nil, function(all)
        for _, r in ipairs(all) do b.all[#b.all + 1] = Entry(r) end
        DB.Top(def, EoCRange.MonthKey(), 10, nil, function(month)
            for _, r in ipairs(month) do b.month[#b.month + 1] = Entry(r) end
            DB.Top(def, EoCRange.WeekKey(), 10, nil, function(week)
                for _, r in ipairs(week) do b.week[#b.week + 1] = Entry(r) end
                DB.PeriodRows(EoCRange.WeekKey(), discId, function(rows)
                    b.units = EoCRange.ComputeUnitScores(def, rows)
                    EoCRange.Boards[discId] = b
                    RecomputeOverall()
                    if cb then cb() end
                end)
            end)
        end)
    end)
end

function DB.RefreshAll(cb)
    local list = EoCRange.AllDisciplines()
    local i = 0
    local function step()
        i = i + 1
        if not list[i] then
            if cb then cb() end
            return
        end
        DB.RefreshDiscipline(list[i].id, step)
    end
    step()
end

---------------------------------------------------------------------------
-- Wochenpokal
---------------------------------------------------------------------------
-- Gewinner einer (vergangenen) Woche bestimmen und archivieren. cb(unit, unitName)
function DB.EnsureTrophy(weekKey, cb)
    DB.Query("SELECT * FROM eocr_trophies WHERE week = " .. DB.Str(weekKey), function(rows)
        if rows[1] then
            cb(rows[1].unit, rows[1].unit_name)
            return
        end
        DB.PeriodRows(weekKey, nil, function(all)
            local perDisc = {}
            for _, r in ipairs(all) do
                perDisc[r.discipline] = perDisc[r.discipline] or {}
                table.insert(perDisc[r.discipline], r)
            end
            local unitsByDisc = {}
            for discId, rws in pairs(perDisc) do
                local def = EoCRange.GetDiscipline(discId)
                if def then unitsByDisc[discId] = EoCRange.ComputeUnitScores(def, rws) end
            end
            local overall = EoCRange.ComputeOverall(unitsByDisc)
            local win = overall[1]
            if not win then
                cb(nil, nil)
                return
            end
            DB.Query("REPLACE INTO eocr_trophies (week, unit, unit_name, score, created) VALUES (" .. DB.Str(weekKey) .. ", " .. DB.Str(win.u)
                .. ", " .. DB.Str(win.un) .. ", " .. DB.Num(win.v) .. ", " .. DB.Num(os.time()) .. ")")
            cb(win.u, win.un, true)
        end)
    end, function() cb(nil, nil) end)
end

---------------------------------------------------------------------------
-- Abzeichen
---------------------------------------------------------------------------
EoCRange.BadgeCache = EoCRange.BadgeCache or {}

function DB.LoadBadges(cb)
    DB.Query("SELECT char_id, MAX(level) AS lvl FROM eocr_badges WHERE revoked = 0 GROUP BY char_id", function(rows)
        EoCRange.BadgeCache = {}
        for _, r in ipairs(rows) do EoCRange.BadgeCache[tonumber(r.char_id)] = tonumber(r.lvl) or 0 end
        if cb then cb() end
    end, cb)
end

function DB.InsertBadge(b, cb)
    DB.Query("INSERT INTO eocr_badges (char_id, steamid, name, level, created, instructor, instructor_sid, revoked, reason, revoked_by, revoked_at) VALUES ("
        .. DB.Num(b.char_id) .. ", " .. DB.Str(b.steamid) .. ", " .. DB.Str(b.name) .. ", " .. DB.Num(b.level) .. ", " .. DB.Num(os.time()) .. ", "
        .. DB.Str(b.instructor) .. ", " .. DB.Str(b.instructor_sid) .. ", 0, '', '', 0)", function(_, id) if cb then cb(id) end end)
end

function DB.ListBadges(search, cb)
    local q = "SELECT * FROM eocr_badges"
    if search and search ~= "" then q = q .. " WHERE name LIKE " .. DB.Str("%" .. search .. "%") end
    q = q .. " ORDER BY id DESC LIMIT 150"
    DB.Query(q, function(rows) cb(Rows(rows)) end, function() cb({}) end)
end

function DB.CharBadges(charId, cb)
    DB.Query("SELECT * FROM eocr_badges WHERE char_id = " .. DB.Num(charId) .. " ORDER BY id DESC", function(rows) cb(Rows(rows)) end, function() cb({}) end)
end

function DB.RevokeBadge(id, by, reason, cb)
    DB.Query("UPDATE eocr_badges SET revoked = 1, reason = " .. DB.Str(reason) .. ", revoked_by = " .. DB.Str(by) .. ", revoked_at = "
        .. DB.Num(os.time()) .. " WHERE id = " .. DB.Num(id), cb, cb)
end

---------------------------------------------------------------------------
-- Eigene Disziplinen
---------------------------------------------------------------------------
function DB.LoadCustom(cb)
    DB.Query("SELECT * FROM eocr_disciplines", function(rows)
        EoCRange.Custom = {}
        for _, r in ipairs(rows) do
            local raw = util.JSONToTable(r.data or "") or {}
            EoCRange.Custom[r.id] = EoCRange.NormalizeCustom(raw, r.id)
        end
        if cb then cb() end
    end, cb)
end

function DB.SaveCustom(id, raw, by, cb)
    DB.Query("REPLACE INTO eocr_disciplines (id, data, created_by, created) VALUES (" .. DB.Str(id) .. ", " .. DB.Str(util.TableToJSON(raw))
        .. ", " .. DB.Str(by) .. ", " .. DB.Num(os.time()) .. ")", cb, cb)
end

function DB.DeleteCustom(id, cb)
    DB.Query("DELETE FROM eocr_disciplines WHERE id = " .. DB.Str(id), cb, cb)
end

---------------------------------------------------------------------------
-- Bahnen pro Map
---------------------------------------------------------------------------
function DB.SaveLanes(map, json, cb)
    DB.Query("REPLACE INTO eocr_lanes (map, data, updated) VALUES (" .. DB.Str(map) .. ", " .. DB.Str(json) .. ", " .. DB.Num(os.time()) .. ")", cb, cb)
end

function DB.LoadLanes(map, cb)
    DB.Query("SELECT data FROM eocr_lanes WHERE map = " .. DB.Str(map), function(rows) cb(rows[1] and rows[1].data or nil) end, function() cb(nil) end)
end
