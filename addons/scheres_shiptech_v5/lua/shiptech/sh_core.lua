--[[
    ShipTech – gemeinsame Definitionen, Hilfsfunktionen und Rechte
]]

local C = ShipTech.Config

if SERVER then
    for _, name in ipairs({
        "ShipTech_Delta", "ShipTech_ConfigSync", "ShipTech_ConfigSet", "ShipTech_OpenAdmin",
        "ShipTech_State", "ShipTech_Chat", "ShipTech_Notify", "ShipTech_Open", "ShipTech_Action",
        "ShipTech_Minigame", "ShipTech_MinigameResult", "ShipTech_Progress", "ShipTech_RequestData",
        "ShipTech_Data", "ShipTech_OpenEvent", "ShipTech_EventAction", "ShipTech_FX",
    }) do
        util.AddNetworkString(name)
    end
end

---------------------------------------------------------------------------
-- Nachschlagetabellen
---------------------------------------------------------------------------
ShipTech.SystemById = {}
for i, def in ipairs(ShipTech.Systems) do
    def.index = i
    ShipTech.SystemById[def.id] = def
end

ShipTech.QualById = {}
for _, q in ipairs(ShipTech.Qualifications) do
    ShipTech.QualById[q.id] = q
end

ShipTech.ConsoleByClass = {}
for _, ct in ipairs(ShipTech.ConsoleTypes) do
    ShipTech.ConsoleByClass[ct.class] = ct
end

ShipTech.Stages = {
    [0] = { name = "Betriebsbereit",       short = "OK",        col = Color(80, 220, 120) },
    [1] = { name = "Beschädigt",           short = "BESCHÄDIGT", col = Color(245, 200, 60) },
    [2] = { name = "Kritisch beschädigt",  short = "KRITISCH",  col = Color(255, 130, 40) },
    [3] = { name = "Ausgefallen",          short = "AUSFALL",   col = Color(235, 50, 50) },
}
ShipTech.StageHealth  = { [0] = 100, [1] = 60, [2] = 25, [3] = 0 }
ShipTech.HealthFactor = { [0] = 1, [1] = 0.7, [2] = 0.35, [3] = 0 }

ShipTech.WorkflowNames = {
    repair  = "In Reparatur",
    test    = "Testlauf ausstehend",
    report  = "Wartungsbericht ausstehend",
    release = "Freigabe ausstehend",
}

-- Reihenfolge im Uhrzeigersinn ab Bug (oben)
ShipTech.SectorNames = { "Bug", "Steuerbord", "Heck", "Backbord" }

ShipTech.AlarmTypes = {
    reactor  = { prio = 1, name = "REAKTORNOTFALL",            protocol = "Protokoll R-1: Reaktorleistung drosseln, Kühlsystem prüfen, Reaktorsektor räumen." },
    power    = { prio = 2, name = "KRITISCHES ENERGIEPROBLEM", protocol = "Protokoll E-2: Nicht-essentielle Systeme abschalten, Notstrom überwachen." },
    drive    = { prio = 3, name = "SCHWERER ANTRIEBSSCHADEN",  protocol = "Protokoll A-3: Antrieb sichern, Techniker zu Triebwerken und Hyperantrieb." },
    system   = { prio = 4, name = "SYSTEMAUSFALL",             protocol = "Protokoll S-1: Ausgefallene Systeme isolieren und Wartungsaufträge abarbeiten." },
    evac     = { prio = 0, name = "EVAKUIERUNG",               protocol = "Alle Personen verlassen den betroffenen Bereich unverzüglich." },
    security = { prio = 5, name = "SICHERHEITSALARM",          protocol = "Protokoll X-1: Sicherheitskräfte an ihre Stationen, Zugänge sichern." },
    fire     = { prio = 1, name = "BRAND AN BORD",             protocol = "Protokoll F-1: Feuerlöscher holen, Brandherd löschen, Bereich räumen." },
}

---------------------------------------------------------------------------
-- Konsolen-Register (statt jedes Mal ents.GetAll() zu durchsuchen)
---------------------------------------------------------------------------
ShipTech.Consoles = ShipTech.Consoles or {}

function ShipTech.RegisterConsole(ent) ShipTech.Consoles[ent] = true end
function ShipTech.UnregisterConsole(ent) ShipTech.Consoles[ent] = nil end

-- kind / sysId optional als Filter
function ShipTech.ConsoleList(kind, sysId)
    local out = {}
    for e in pairs(ShipTech.Consoles) do
        if not IsValid(e) then
            ShipTech.Consoles[e] = nil
        elseif (not kind or e.ConsoleKind == kind) and (not sysId or e.SysId == sysId) then
            out[#out + 1] = e
        end
    end
    return out
end

function ShipTech.HasTool(ply)
    local w = IsValid(ply) and ply:GetActiveWeapon()
    return IsValid(w) and w:GetClass() == C.Tool.Class
end

---------------------------------------------------------------------------
-- Ingame-Konfiguration: Werte lesen/setzen über Schlüssel wie "Backup.Output"
---------------------------------------------------------------------------
ShipTech.ConfigDefaults = ShipTech.ConfigDefaults or {}

local function SplitKey(key)
    local parts = string.Explode(".", key)
    for i, p in ipairs(parts) do parts[i] = tonumber(p) or p end
    return parts
end

function ShipTech.GetConfigValue(key)
    if string.sub(key, 1, 6) == "Model:" then
        local ct = ShipTech.ConsoleByClass[string.sub(key, 7)]
        return ct and ct.model
    end
    local t = C
    local parts = SplitKey(key)
    for i = 1, #parts - 1 do
        t = t[parts[i]]
        if type(t) ~= "table" then return nil end
    end
    return t[parts[#parts]]
end

function ShipTech.SetConfigValue(key, value)
    if ShipTech.ConfigDefaults[key] == nil then
        local cur = ShipTech.GetConfigValue(key)
        ShipTech.ConfigDefaults[key] = istable(cur) and table.Copy(cur) or cur
    end
    if string.sub(key, 1, 6) == "Model:" then
        local class = string.sub(key, 7)
        local ct = ShipTech.ConsoleByClass[class]
        if not ct or not isstring(value) then return end
        ct.model = value
        local stored = scripted_ents.GetStored(class)
        if stored and stored.t then stored.t.ConsoleModel = value end
        if SERVER then
            for _, e in ipairs(ShipTech.ConsoleList()) do
                if e:GetClass() == class then e:SetModel(value) end
            end
        end
        return
    end
    local t = C
    local parts = SplitKey(key)
    for i = 1, #parts - 1 do
        if type(t[parts[i]]) ~= "table" then t[parts[i]] = {} end
        t = t[parts[i]]
    end
    t[parts[#parts]] = value
end

---------------------------------------------------------------------------
-- Zustands-Hilfsfunktionen (Server & Client)
---------------------------------------------------------------------------
function ShipTech.StageOf(h)
    h = h or 100
    if h <= 0 then return 3 end
    if h < 35 then return 2 end
    if h < 75 then return 1 end
    return 0
end

function ShipTech.Sys(id)
    local S = ShipTech.State
    return S and S.systems and S.systems[id]
end

function ShipTech.IsOperational(sys)
    return sys ~= nil and sys.health > 0 and not sys.wf and not sys.coolLock
end

function ShipTech.GetEfficiency(id)
    local s = ShipTech.Sys(id)
    return s and s.eff or 0
end

function ShipTech.GetShieldPercent()
    local S = ShipTech.State
    if not S or not S.shields or not S.shields.sectors then return 0 end
    local t = 0
    for i = 1, 4 do t = t + (S.shields.sectors[i] or 0) end
    return t / 4
end

function ShipTech.IsOutage(name)
    local S = ShipTech.State
    if not S or not S.outages then return false end
    for _, n in ipairs(S.outages) do
        if n == name then return true end
    end
    return false
end

-- Gameplay-Werte (für andere Addons): shield, shieldCap, speed, hyper, weapons, accuracy, sensors, comms
function ShipTech.GetModifiers()
    local S = ShipTech.State
    return (S and S.mods) or {}
end

-- Statustext + Farbe eines Systems
function ShipTech.StatusInfo(id)
    local sys = ShipTech.Sys(id)
    if not sys then return "KEINE DATEN", Color(140, 140, 140) end
    if id == "reactor" and sys.booting then return "SYSTEMSCAN LÄUFT", Color(255, 170, 50) end
    if sys.coolLock then return "SICHERHEITSABSCHALTUNG", Color(235, 50, 50) end
    if sys.health <= 0 then return "AUSGEFALLEN", Color(235, 50, 50) end
    if sys.wf then return string.upper(ShipTech.WorkflowNames[sys.wf] or "IN WARTUNG"), Color(255, 170, 50) end
    if not sys.on then return "OFFLINE", Color(140, 150, 165) end
    if (sys.power or 0) <= 0 then return "KEINE ENERGIE", Color(235, 80, 50) end
    return "ONLINE", Color(80, 220, 120)
end

---------------------------------------------------------------------------
-- Rechte
---------------------------------------------------------------------------
local function InSet(set, v)
    return set ~= nil and v ~= nil and set[v] == true
end

local function TeamName(ply)
    return team.GetName(ply:Team()) or ""
end

function ShipTech.IsAdmin(ply)
    return IsValid(ply) and (ply:IsSuperAdmin() or InSet(C.AdminGroups, ply:GetUserGroup()))
end

function ShipTech.IsEventler(ply)
    return IsValid(ply) and (ShipTech.IsAdmin(ply) or InSet(C.EventlerGroups, ply:GetUserGroup()))
end

function ShipTech.HasQual(ply, q)
    if not IsValid(ply) then return false end
    if not C.UseQualifications or ShipTech.IsAdmin(ply) then return true end
    return string.find(ply:GetNW2String("ST_Quals", ","), "," .. q .. ",", 1, true) ~= nil
end

function ShipTech.IsTechnician(ply)
    if not IsValid(ply) then return false end
    if ShipTech.IsAdmin(ply) then return true end
    local name = TeamName(ply)
    if InSet(C.TechnicianTeams, name) then return true end
    local patterns = C.TechnicianTeamPatterns or {}
    local lower = string.lower(name)
    for _, p in ipairs(patterns) do
        if p ~= "" and string.find(lower, string.lower(p), 1, true) then return true end
    end
    -- keine Einschränkung konfiguriert = jeder ist Techniker
    return next(C.TechnicianTeams) == nil and #patterns == 0
end

function ShipTech.IsNavy(ply)
    if not IsValid(ply) then return false end
    if ShipTech.IsAdmin(ply) then return true end
    if InSet(C.NavyTeams, TeamName(ply)) then return true end
    local tn = string.lower(TeamName(ply))
    for _, p in ipairs(C.NavyTeamPatterns or {}) do
        if p ~= "" and string.find(tn, string.lower(p), 1, true) then return true end
    end
    if GARLog and GARLog.HasRole and GARLog.HasRole(ply, "navy") then return true end
    if C.UseQualifications then return ShipTech.HasQual(ply, "navy") end
    return next(C.NavyTeams) == nil
end

function ShipTech.CanWork(ply, id)
    local def = ShipTech.SystemById[id]
    if not def then return false end
    return ShipTech.IsTechnician(ply) and ShipTech.HasQual(ply, def.qual)
end

function ShipTech.CanRelease(ply, id)
    if ShipTech.IsAdmin(ply) then return true end
    return ShipTech.CanWork(ply, id) and ShipTech.HasQual(ply, "freigabe")
end

function ShipTech.CanInstruct(ply)
    if not IsValid(ply) then return false end
    if ShipTech.IsAdmin(ply) or InSet(C.InstructorGroups, ply:GetUserGroup()) then return true end
    return C.UseQualifications and ShipTech.HasQual(ply, "ausbilder")
end

function ShipTech.CanManagePower(ply)
    return ShipTech.IsNavy(ply) or (ShipTech.IsTechnician(ply) and ShipTech.HasQual(ply, "basis"))
end

function ShipTech.CanCreateOrders(ply)
    return ShipTech.IsNavy(ply) or ShipTech.IsEventler(ply) or ShipTech.HasQual(ply, "freigabe")
end

---------------------------------------------------------------------------
-- Empfänger von Technik-Meldungen (nur bestimmte Jobs)
---------------------------------------------------------------------------
function ShipTech.GetsNotify(ply)
    if not IsValid(ply) then return false end
    local N = C.Notify or {}
    if N.Admins and ShipTech.IsAdmin(ply) then return true end
    if N.UseLogistikRoles and GARLog and GARLog.HasRole then
        for role in pairs(N.LogistikRoles or {}) do
            if GARLog.HasRole(ply, role) then return true end
        end
    end
    local tn = string.lower(team.GetName(ply:Team()) or "")
    for _, p in ipairs(N.JobPatterns or {}) do
        if p ~= "" and string.find(tn, string.lower(p), 1, true) then return true end
    end
    return false
end

function ShipTech.NotifyRecipients()
    local list = {}
    for _, ply in ipairs(player.GetAll()) do
        if ShipTech.GetsNotify(ply) then list[#list + 1] = ply end
    end
    return list
end