--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Job-Whitelist (Server), Tabelle sy_whitelist (altes Format: steamid -> JSON-Liste der Jobs)
-------------------------------------------------------------------------------------------------------------]]

local W = symchars.whitelist
local DB = symchars.db
local Json, Unjson = symchars.net.Json, symchars.net.Unjson

function W.Load(done)
    DB.Query("SELECT steamid, json FROM sy_whitelist", function(rows)
        W.loaded = {}
        for _, row in ipairs(rows) do
            local sid = tostring(row.steamid or "")
            local decoded = Unjson(row.json or "") or {}
            if sid ~= "" then
                W.loaded[sid] = {}
                for k, v in pairs(decoded) do
                    local job = v == true and k or v
                    if isstring(job) and job ~= "" then W.loaded[sid][job] = true end
                end
            end
        end
        if done then done() end
    end, function() if done then done() end end)
end

function W.Sync(ply)
    if not IsValid(ply) then
        for _, p in ipairs(player.GetAll()) do W.Sync(p) end
        return
    end
    local data
    if symchars.HasPriv(ply, "symchars_charmanage") then
        data = W.loaded
    else
        data = { [ply:SteamID64()] = W.loaded[ply:SteamID64()] or {} }
    end
    symchars.net.Send("whitelist", data, ply)
end

function W.Save(steamid)
    local jobs = {}
    for job, on in pairs(W.loaded[steamid] or {}) do if on then jobs[#jobs + 1] = job end end
    table.sort(jobs)
    if #jobs == 0 then
        DB.Query("DELETE FROM sy_whitelist WHERE steamid = " .. DB.Str(steamid))
    else
        DB.Replace("sy_whitelist", { "steamid", "json" }, { DB.Str(steamid), DB.Str(Json(jobs)) })
    end
end

function W.Set(steamid, job, state)
    if steamid == "" or job == "" then return end
    W.loaded[steamid] = W.loaded[steamid] or {}
    W.loaded[steamid][job] = state == true or nil
    W.Save(steamid)
end

symchars.net.Receive("whitelist_set", function(ply, data)
    if not symchars.IsSuperAdmin(ply) then return end
    if not istable(data) then return end
    local sid = tostring(data.steamid or "")
    if not string.match(sid, "^%d+$") then symchars.Notify(ply, "Ungültige SteamID64.", "error") return end
    if data.all ~= nil then
        W.loaded[sid] = {}
        if data.all then
            for _, job in pairs(RPExtraTeams or {}) do W.loaded[sid][job.command] = true end
        end
        W.Save(sid)
    else
        W.Set(sid, tostring(data.job or ""), data.state == true)
    end
    W.Sync()
end, 0.2)
