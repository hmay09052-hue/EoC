--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Einstellungen laden/speichern (Server)
-------------------------------------------------------------------------------------------------------------]]

local S = symchars.settings
local DB = symchars.db

function S.Load(done)
    DB.Query("SELECT k, v FROM sc_settings", function(rows)
        S.values = {}
        for _, row in ipairs(rows) do
            local meta = S.meta[row.k]
            if meta then
                local decoded = symchars.net.Unjson(row.v or "")
                if istable(decoded) and decoded.v ~= nil then
                    local value = S.Normalize(row.k, decoded.v)
                    if value ~= nil then S.values[row.k] = value end
                end
            end
        end
        -- Alter Standard-Job "citizen" gespeichert -> durch Zivilist (teamzivilisten) ersetzen
        if S.values.defaultjob == "citizen" or S.values.defaultjob == "" then
            S.values.defaultjob = nil
            DB.Query("DELETE FROM sc_settings WHERE k = 'defaultjob'")
        end
        if done then done() end
    end, function() if done then done() end end)
end

function S.Sync(ply)
    symchars.net.Send("settings", S.values, ply)
end

function S.Set(key, value)
    local normalized = S.Normalize(key, value)
    if normalized == nil then return false end
    S.values[key] = normalized
    DB.Replace("sc_settings", { "k", "v" }, { DB.Str(key), DB.Str(symchars.net.Json({ v = normalized })) })
    return true
end

function S.Reset(key)
    S.values[key] = nil
    DB.Query("DELETE FROM sc_settings WHERE k = " .. DB.Str(key))
end

symchars.net.Receive("settings_save", function(ply, data)
    if not symchars.IsSuperAdmin(ply) then
        symchars.Notify(ply, "Dir fehlt die Berechtigung.", "error")
        return
    end
    if not istable(data) then return end

    local changed = 0
    for key, value in pairs(istable(data.values) and data.values or {}) do
        if S.meta[key] and S.Set(key, value) then changed = changed + 1 end
    end
    for _, key in ipairs(istable(data.reset) and data.reset or {}) do
        if S.meta[key] then S.Reset(key) changed = changed + 1 end
    end

    S.Sync()
    hook.Run("symchars_settings_changed")
    symchars.Notify(ply, changed .. " Einstellung(en) gespeichert.", "succ")
end, 1)
