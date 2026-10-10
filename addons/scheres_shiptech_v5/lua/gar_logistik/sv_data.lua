-- Persistenz (SQLite, Schlüssel -> JSON)
-- Daten werden nur als "dirty" markiert und gebündelt in einer Transaktion geschrieben.

GARLog.DB = GARLog.DB or {}
local DB = GARLog.DB
local cfg = GARLog.Config

sql.Query("CREATE TABLE IF NOT EXISTS garlog_kv (k TEXT PRIMARY KEY, v TEXT)")

local providers = DB.Providers or {}
local dirty = DB.Dirty or {}
DB.Providers, DB.Dirty = providers, dirty

function DB.Load(key)
    local v = sql.QueryValue("SELECT v FROM garlog_kv WHERE k = " .. sql.SQLStr(key))
    if not v or v == "NULL" or v == false then return nil end
    return util.JSONToTable(v)
end

local function write(key, data)
    sql.Query("REPLACE INTO garlog_kv (k, v) VALUES (" .. sql.SQLStr(key) .. ", " .. sql.SQLStr(util.TableToJSON(data)) .. ")")
end

function DB.Save(key, data)
    write(key, data)
end

-- fn liefert die zu speichernde Tabelle, wenn der Schlüssel dirty ist
function DB.Register(key, fn)
    providers[key] = fn
end

function DB.MarkDirty(key)
    dirty[key] = true
end

function DB.Flush()
    if not next(dirty) then return end
    local keys = {}
    for k in pairs(dirty) do keys[#keys + 1] = k end
    table.Empty(dirty)

    sql.Begin()
    for _, key in ipairs(keys) do
        local fn = providers[key]
        if fn then
            local ok, data = pcall(fn)
            if ok and istable(data) then
                write(key, data)
            elseif not ok then
                ErrorNoHalt("[GAR Logistik] Speichern von '" .. key .. "' fehlgeschlagen: " .. tostring(data) .. "\n")
            end
        end
    end
    sql.Commit()
end

timer.Create("GARLog_Save", cfg.SaveInterval, 0, function()
    local t0 = SysTime()
    DB.Flush()
    if GARLog.PerfAdd then GARLog.PerfAdd("Speichern (SQLite)", SysTime() - t0) end
end)

hook.Add("ShutDown", "GARLog_Save", function()
    GARLog.ShuttingDown = true
    hook.Run("GARLog_PreSave")
    DB.Flush()
end)
