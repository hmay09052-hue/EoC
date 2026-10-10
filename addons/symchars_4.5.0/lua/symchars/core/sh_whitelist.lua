--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Job-Whitelist (nur aktiv, wenn das Einheitensystem ausgeschaltet ist)
    Daten bleiben in der alten Tabelle sy_whitelist.
-------------------------------------------------------------------------------------------------------------]]

symchars.whitelist = symchars.whitelist or {}
symchars.whitelist.loaded = symchars.whitelist.loaded or {}

local W = symchars.whitelist

function W.Has(ply, job)
    job = tostring(job or "")
    if job ~= "" and job == tostring(symchars.Config("defaultjob") or "") then return true end
    local steamid = IsValid(ply) and ply:SteamID64() or tostring(ply or "")
    local entry = W.loaded[steamid]
    return entry ~= nil and entry[job] == true
end

function W.Get(ply)
    local steamid = IsValid(ply) and ply:SteamID64() or tostring(ply or "")
    return W.loaded[steamid] or {}
end

function W.IsBuiltInActive() return true end

if CLIENT then
    symchars.net.Receive("whitelist", function(data)
        W.loaded = istable(data) and data or {}
        hook.Run("symchars_whitelist_sync")
    end)
end
