-- Gemeinsame Grundlagen: Enums, Ressourcen, Rollen, Formatierung

GARLog = GARLog or {}
local cfg = GARLog.Config

---------------------------------------------------------------------------
-- Farben (passend zum Echoes of Clones HUD / Crypto-Radio)
---------------------------------------------------------------------------
GARLog.Col = {
    yellow = Color(252, 178, 73),
    white  = Color(244, 241, 233),
    text   = Color(216, 219, 225),
    soft   = Color(157, 163, 173),
    muted  = Color(101, 107, 117),
    red    = Color(225, 88, 88),
    orange = Color(235, 135, 60),
    green  = Color(74, 203, 130),
    blue   = Color(90, 170, 255),
    cyan   = Color(80, 200, 220),
    purple = Color(190, 120, 255),
}
local COL = GARLog.Col

---------------------------------------------------------------------------
-- Status-Enums
---------------------------------------------------------------------------
GARLog.REQ_OPEN, GARLog.REQ_APPROVED, GARLog.REQ_TRANSIT = 1, 2, 3
GARLog.REQ_DONE, GARLog.REQ_REJECTED, GARLog.REQ_CANCELLED = 4, 5, 6

GARLog.ReqStatus = {
    [1] = { name = "OFFEN",        color = COL.yellow },
    [2] = { name = "GENEHMIGT",    color = COL.blue },
    [3] = { name = "IM TRANSPORT", color = COL.cyan },
    [4] = { name = "GELIEFERT",    color = COL.green },
    [5] = { name = "ABGELEHNT",    color = COL.red },
    [6] = { name = "STORNIERT",    color = COL.muted },
}

GARLog.Prio = {
    [1] = { name = "NIEDRIG",  color = COL.soft },
    [2] = { name = "NORMAL",   color = COL.text },
    [3] = { name = "HOCH",     color = COL.orange },
    [4] = { name = "KRITISCH", color = COL.red },
}

GARLog.TRN_TRANSIT, GARLog.TRN_RETURN, GARLog.TRN_DONE = 1, 2, 3
GARLog.TrnStatus = {
    [1] = { name = "UNTERWEGS", color = COL.cyan },
    [2] = { name = "RÜCKFLUG",  color = COL.soft },
    [3] = { name = "ERLEDIGT",  color = COL.green },
}

GARLog.REP_OPEN, GARLog.REP_ASSIGNED, GARLog.REP_DONE, GARLog.REP_CANCELLED = 1, 2, 3, 4
GARLog.RepStatus = {
    [1] = { name = "OFFEN",       color = COL.yellow },
    [2] = { name = "ÜBERNOMMEN",  color = COL.cyan },
    [3] = { name = "ERLEDIGT",    color = COL.green },
    [4] = { name = "HINFÄLLIG",   color = COL.muted },
}

GARLog.LocTypeName = { central = "ZENTRALLAGER", ship = "FLOTTE", fob = "FELDBASIS" }

GARLog.LogKinds = { info = 0, ok = 1, warn = 2, err = 3 }
GARLog.LogKindColor = { info = COL.text, ok = COL.green, warn = COL.orange, err = COL.red }

---------------------------------------------------------------------------
-- Ressourcen
---------------------------------------------------------------------------
GARLog.Res = {}
GARLog.ResOrder = {}
for i, r in ipairs(cfg.Resources) do
    r.index = i
    GARLog.Res[r.id] = r
    GARLog.ResOrder[i] = r.id
end

GARLog.StaticLoc = {}
for i, l in ipairs(cfg.Locations) do
    l.index = i
    GARLog.StaticLoc[l.id] = l
end

---------------------------------------------------------------------------
-- Baubare Dinge (Strukturen + SSE)
-- key: "s:<id>" für Strukturen, "e:<class>" für SSE-Ausstattung
---------------------------------------------------------------------------
GARLog.BuildDefs = {}
GARLog.BuildOrder = {}

for _, id in ipairs(cfg.StructureOrder) do
    local s = cfg.Structures[id]
    if s then
        s.id, s.key, s.kind = id, "s:" .. id, "structure"
        s.time = s.buildTime
        GARLog.BuildDefs[s.key] = s
        GARLog.BuildOrder[#GARLog.BuildOrder + 1] = s.key
    end
end

for _, e in ipairs(cfg.SSE) do
    e.key, e.kind, e.sse = "e:" .. e.class, "sse", true
    e.health = e.health or 400
    e.needsPower = e.power
    GARLog.BuildDefs[e.key] = e
    GARLog.BuildOrder[#GARLog.BuildOrder + 1] = e.key
end

function GARLog.ClassInstalled(class)
    return scripted_ents.GetStored(class) ~= nil
end

---------------------------------------------------------------------------
-- Modelle (mit Fallback, "@Schlüssel" = SSE.Config)
---------------------------------------------------------------------------
local modelCache = {}
function GARLog.ResolveModel(m, fallback)
    local key = tostring(m) .. "|" .. tostring(fallback)
    local cached = modelCache[key]
    if cached then return cached end

    local path = m
    if isstring(m) and m:sub(1, 1) == "@" then
        local t = SSE and SSE.Config and SSE.Config[m:sub(2)]
        path = t and t["Model"] or nil
        if not SSE then return fallback or "models/props_junk/wood_crate002a.mdl" end -- SSE noch nicht geladen: nicht cachen
    end

    local res = (isstring(path) and util.IsValidModel(path)) and path or fallback or "models/props_junk/wood_crate002a.mdl"
    modelCache[key] = res
    return res
end

function GARLog.DefModel(def)
    return GARLog.ResolveModel(def.model, def.fallback)
end

---------------------------------------------------------------------------
-- Formatierung
---------------------------------------------------------------------------
-- Zahlen werden in Paint-Funktionen ständig formatiert -> Ergebnis zwischenspeichern
local fmtCache, fmtCount = {}, 0
function GARLog.FmtNum(n)
    n = math.floor(tonumber(n) or 0)
    local hit = fmtCache[n]
    if hit then return hit end
    local s = tostring(math.abs(n))
    local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
    if out:sub(1, 1) == "." then out = out:sub(2) end
    out = (n < 0 and "-" or "") .. out
    fmtCount = fmtCount + 1
    if fmtCount > 8192 then fmtCache, fmtCount = {}, 0 end
    fmtCache[n] = out
    return out
end

function GARLog.FmtTime(sec)
    sec = math.max(0, math.floor(sec or 0))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

-- Grobe Dauer für Reichweiten: "~12 MIN", "~3 H"
function GARLog.FmtSpan(minutes)
    if not minutes or minutes == math.huge then return "—" end
    if minutes < 1 then return "< 1 MIN" end
    if minutes < 120 then return "~" .. math.floor(minutes) .. " MIN" end
    if minutes < 60 * 48 then return "~" .. math.floor(minutes / 60) .. " H" end
    return "> 2 TAGE"
end

-- Client: Ergebnis pro Güter-Tabelle merken (Sync-Tabellen ändern sich nicht, werden nur ersetzt)
local itemsCache = CLIENT and setmetatable({}, { __mode = "k" }) or nil
function GARLog.ItemsText(items, sep)
    if not istable(items) then return "—" end
    if itemsCache and not sep then
        local hit = itemsCache[items]
        if hit then return hit end
    end
    local parts = {}
    for _, id in ipairs(GARLog.ResOrder) do
        local n = items[id]
        if n and n > 0 then parts[#parts + 1] = GARLog.FmtNum(n) .. " " .. GARLog.Res[id].short end
    end
    local res = #parts == 0 and "—" or table.concat(parts, sep or " · ")
    if itemsCache and not sep then itemsCache[items] = res end
    return res
end

function GARLog.ItemVolume(items)
    local v = 0
    if not istable(items) then return 0 end
    for id, n in pairs(items) do
        local r = GARLog.Res[id]
        if r and n > 0 then v = v + n * (r.volume or 1) end
    end
    return v
end

function GARLog.ItemCount(items)
    local c = 0
    for _, n in pairs(items or {}) do if n > 0 then c = c + n end end
    return c
end

-- Bereinigt eine Ressourcen-Tabelle (nur bekannte IDs, ganze positive Zahlen)
function GARLog.SanitizeItems(t, maxEach)
    local out, any = {}, false
    if not istable(t) then return out, false end
    maxEach = maxEach or 1000000
    for _, id in ipairs(GARLog.ResOrder) do
        local n = tonumber(t[id])
        if n and n == n then
            n = math.floor(n)
            if n > 0 then
                out[id] = math.min(n, maxEach)
                any = true
            end
        end
    end
    return out, any
end

function GARLog.SupplyStatus(frac)
    frac = frac or 0
    for i, s in ipairs(cfg.SupplyStatus) do
        if frac >= s.min then return i, s end
    end
    local n = #cfg.SupplyStatus
    return n, cfg.SupplyStatus[n]
end

function GARLog.FlightTime(srcType, dstType)
    return cfg.Shuttle.FlightTime[srcType .. ">" .. dstType] or cfg.Shuttle.DefaultTime or 120
end

function GARLog.CleanText(s, maxLen)
    if not isstring(s) then return "" end
    s = s:gsub("[%c]", " ")
    s = string.Trim(s)
    local len = utf8.len(s)
    if not len then return "" end
    if len > maxLen then s = s:sub(1, (utf8.offset(s, maxLen + 1) or (#s + 1)) - 1) end
    return s
end

---------------------------------------------------------------------------
-- Rollen & Berechtigungen
---------------------------------------------------------------------------
local function toSet(list)
    local set = {}
    for _, v in ipairs(list or {}) do set[string.lower(v)] = true end
    return set
end

for id, r in pairs(cfg.Roles) do
    r.id = id
    r._jobs = toSet(r.jobs)
    r._cats = toSet(r.categories)
    r._groups = toSet(r.usergroups)
    r._kw = {}
    for _, k in ipairs(r.keywords or {}) do r._kw[#r._kw + 1] = string.lower(k) end
end

function GARLog.IsAdmin(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return ply:IsSuperAdmin() or cfg.AdminGroups[ply:GetUserGroup()] == true
end

local function computeRoles(ply)
    local roles = {}
    local teamId = ply:Team()
    local job = string.lower(team.GetName(teamId) or "")
    local cat = ""
    local jt = RPExtraTeams and RPExtraTeams[teamId]
    if jt and isstring(jt.category) then cat = string.lower(jt.category) end
    local group = string.lower(ply:GetUserGroup() or "")

    for id, r in pairs(cfg.Roles) do
        local has
        if cfg.CustomRoleCheck then has = cfg.CustomRoleCheck(ply, id) end
        if has == nil then
            has = r._jobs[job] or r._cats[cat] or r._groups[group] or false
            if not has and cfg.UseKeywords and job ~= "" then
                for _, k in ipairs(r._kw) do
                    if job:find(k, 1, true) then has = true break end
                end
            end
        end
        if has then roles[id] = true end
    end
    return roles
end

local NO_ROLES = {}
function GARLog.GetRoles(ply)
    if not IsValid(ply) then return NO_ROLES end
    local t, g, now = ply:Team(), ply:GetUserGroup(), CurTime()
    if ply.GARLogRoleTeam ~= t or ply.GARLogRoleGroup ~= g or (ply.GARLogRoleExp or 0) < now then
        ply.GARLogRoles = computeRoles(ply)
        ply.GARLogRoleTeam, ply.GARLogRoleGroup, ply.GARLogRoleExp = t, g, now + 10
    end
    return ply.GARLogRoles
end

function GARLog.HasRole(ply, role)
    return GARLog.GetRoles(ply)[role] == true
end

-- Rolle hat die Berechtigung (ohne Admin-Überschreibung)
function GARLog.HasPermRole(ply, perm)
    local list = cfg.Permissions[perm]
    if not list then return false end
    local roles = GARLog.GetRoles(ply)
    for _, r in ipairs(list) do
        if r == "*" or roles[r] then return true end
    end
    return false
end

function GARLog.Can(ply, perm)
    if not IsValid(ply) then return false end
    if GARLog.IsAdmin(ply) then return true end
    return GARLog.HasPermRole(ply, perm)
end

function GARLog.Name(ply)
    if not IsValid(ply) then return "Unbekannt" end
    return ply:Nick()
end

-- Das eine Werkzeug (GAR-Datapad)
function GARLog.IsTool(wep)
    return IsValid(wep) and wep:GetClass() == cfg.DatapadClass
end

-- Mehrzeiliger Text (Berichte): Zeilenumbrüche bleiben, Steuerzeichen raus
function GARLog.CleanMultiline(s, maxLen)
    if not isstring(s) then return "" end
    s = s:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("[%z\1-\9\11-\31]", " ")
    s = s:gsub("\n\n\n+", "\n\n")
    s = string.Trim(s)
    local len = utf8.len(s)
    if not len then return "" end
    if len > maxLen then s = s:sub(1, (utf8.offset(s, maxLen + 1) or (#s + 1)) - 1) end
    return s
end

---------------------------------------------------------------------------
-- Schiffe & Fahrzeuge (LVS / LFS / simfphys), nutzt das Fusion-Cutter-Addon falls vorhanden
---------------------------------------------------------------------------
function GARLog.FCRAvailable()
    return FCR ~= nil and FCR.Util ~= nil and (CLIENT or (FCR.Session ~= nil and FCR.Session.TryBegin ~= nil))
end

function GARLog.ResolveVehicle(ent)
    if not IsValid(ent) then return NULL end
    if FCR and FCR.Util and FCR.Util.ResolveRepairEntity then return FCR.Util.ResolveRepairEntity(ent) end
    return ent
end

function GARLog.IsVehicle(ent)
    if not IsValid(ent) then return false end
    if FCR and FCR.Util and FCR.Util.IsSupportedVehicle then return FCR.Util.IsSupportedVehicle(ent) end
    return (ent.LVS == true or ent.LFS == true) and isfunction(ent.GetHP)
end

function GARLog.VehicleHealth(ent)
    if FCR and FCR.Util and FCR.Util.GetVehicleHealth then return FCR.Util.GetVehicleHealth(ent) end
    if not IsValid(ent) or not isfunction(ent.GetHP) then return 0, 0 end
    return ent:GetHP() or 0, isfunction(ent.GetMaxHP) and ent:GetMaxHP() or 0
end

function GARLog.VehicleLabel(ent)
    if FCR and FCR.Util and FCR.Util.GetVehicleLabel then return FCR.Util.GetVehicleLabel(ent) end
    if not IsValid(ent) then return "—" end
    return string.upper(isstring(ent.PrintName) and ent.PrintName ~= "" and ent.PrintName or ent:GetClass())
end

function GARLog.ReportCategory(id)
    for _, c in ipairs(cfg.Reports.Categories) do
        if c.id == id then return c end
    end
    return cfg.Reports.Categories[#cfg.Reports.Categories]
end
