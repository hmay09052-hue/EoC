-- Netzwerk: Aktionen der Datapads (alle Eingaben werden hier geprüft)

local cfg = GARLog.Config
local FOB = GARLog.FOB

---------------------------------------------------------------------------
-- Zugriff
---------------------------------------------------------------------------
-- Zugriff über das Datapad oder kürzlich an einem Terminal / einer Struktur geöffnet
function GARLog.GrantAccess(ply, ent)
    ply.GARLogAccess = { pos = ent:GetPos(), exp = CurTime() + 900 }
end

function GARLog.CanUseUI(ply)
    if not IsValid(ply) then return false end
    if GARLog.IsAdmin(ply) then return true end
    if not ply:Alive() or not GARLog.Can(ply, "view") then return false end
    if ply:HasWeapon(cfg.DatapadClass) then return true end
    local acc = ply.GARLogAccess
    return acc ~= nil and acc.exp > CurTime() and ply:GetPos():DistToSqr(acc.pos) < 450 * 450
end

-- Datapad-Apps: 1 = Logistik, 2 = Feldbasis (Bauplanung), 3 = Technik-Kontrollterminal
GARLog.APP_LOGISTIK, GARLog.APP_FELDBASIS, GARLog.APP_TECHNIK = 1, 2, 3

-- kind: 1 = Datapad (App/Tab), 3 = Container, 4 = Abbau bestätigen
function GARLog.OpenMenu(ply, tab, locId, ent, app)
    if IsValid(ent) then GARLog.GrantAccess(ply, ent) end
    net.Start("GARLog_Open")
        net.WriteUInt(1, 3)
        net.WriteUInt(app or GARLog.APP_LOGISTIK, 3)
        net.WriteUInt(tab or 1, 4)
        net.WriteString(locId or "")
        net.WriteBool(IsValid(ent))
    net.Send(ply)
end

function GARLog.OpenBuilder(ply)
    GARLog.OpenMenu(ply, 1, nil, nil, GARLog.APP_FELDBASIS)
end

function GARLog.OpenTechnik(ply, tab)
    GARLog.OpenMenu(ply, tab or 1, nil, nil, GARLog.APP_TECHNIK)
end

function GARLog.OpenEntityMenu(ply, kind, ent)
    net.Start("GARLog_Open")
        net.WriteUInt(kind, 3)
        net.WriteEntity(ent)
    net.Send(ply)
end

---------------------------------------------------------------------------
-- Aktionen
---------------------------------------------------------------------------
local Actions = {}
GARLog.Actions = Actions

-- Diese Aktionen funktionieren ohne Datapad (eigene Prüfungen)
local NO_UI = {
    ["cnt.unload"] = true, ["cnt.attach"] = true, ["cnt.detach"] = true,
    ["gen.toggle"] = true, ["build.place"] = true, ["build.dismantle"] = true,
}

local function Fail(ply, err)
    if err then GARLog.Notify(ply, err, "err") end
end

local function Done(ply, msg)
    if msg then GARLog.Notify(ply, msg, "ok") end
end

local function Need(ply, perm)
    if GARLog.Can(ply, perm) then return true end
    Fail(ply, "Keine Berechtigung.")
    return false
end

local function ReqById(id) return GARLog.Requests[tonumber(id) or -1] end
local function RepById(id) return GARLog.Repairs[tonumber(id) or -1] end

Actions["sub"] = function(ply, a)
    local level = tonumber(a.level) or (a.on == true and 2 or 0)
    GARLog.Subscribe(ply, GARLog.CanUseUI(ply) and level or 0)
end

-- Anträge -----------------------------------------------------------------
Actions["req.create"] = function(ply, a)
    local r, err = GARLog.CreateRequest(ply, a.from, a.src, a.items, a.prio, a.note)
    if r then Done(ply, "Versorgungsantrag #" .. r.id .. " gestellt.") else Fail(ply, err) end
end

Actions["req.approve"] = function(ply, a)
    if not Need(ply, "request.approve") then return end
    local r = ReqById(a.id)
    if not r then return end
    local ok, err = GARLog.ApproveRequest(ply, r, a.ok == true, a.reason)
    if not ok then Fail(ply, err) end
end

Actions["req.cancel"] = function(ply, a)
    local r = ReqById(a.id)
    if not r then return end
    local ok, err = GARLog.CancelRequest(ply, r)
    if not ok then Fail(ply, err) end
end

Actions["req.plan"] = function(ply, a)
    if not Need(ply, "request.plan") then return end
    local r = ReqById(a.id)
    if not r then return end
    local ok, err = GARLog.PlanRequest(ply, r, a.mode == "container" and "container" or "shuttle", a.items)
    if ok then Done(ply, "Lieferung zu Antrag #" .. r.id .. " ist unterwegs.") else Fail(ply, err) end
end

-- Transporte & Container --------------------------------------------------
Actions["trn.create"] = function(ply, a)
    if not Need(ply, "transport.create") then return end
    local t, err = GARLog.CreateShuttle(ply, a.src, a.dst, a.items)
    if t then Done(ply, string.format("Shuttle T-%d gestartet (ETA %s).", t.id, GARLog.FmtTime(t.ft))) else Fail(ply, err) end
end

Actions["cnt.pack"] = function(ply, a)
    local ent, err = GARLog.PackContainer(ply, a.loc, a.items)
    if IsValid(ent) then Done(ply, "Container C-" .. ent:GetContainerID() .. " bereitgestellt.") else Fail(ply, err) end
end

Actions["cnt.unload"] = function(ply, a)
    local ok, err = GARLog.StartUnload(ply, Entity(tonumber(a.ent) or 0))
    if not ok then Fail(ply, err) end
end

Actions["cnt.attach"] = function(ply, a)
    local ok, err = GARLog.AttachContainer(ply, Entity(tonumber(a.ent) or 0))
    if ok then Done(ply, "Container angekoppelt.") else Fail(ply, err) end
end

Actions["cnt.detach"] = function(ply, a)
    local ok, err = GARLog.DetachContainer(ply, Entity(tonumber(a.ent) or 0))
    if ok then Done(ply, "Container abgekoppelt.") else Fail(ply, err) end
end

-- Produktion --------------------------------------------------------------
Actions["prd.add"] = function(ply, a)
    if not Need(ply, "production") then return end
    local ok, err = GARLog.AddProduction(ply, a.res, a.n, a.line)
    if ok then Done(ply, "Produktionsauftrag erteilt.") else Fail(ply, err) end
end

Actions["prd.cancel"] = function(ply, a)
    if not Need(ply, "production") then return end
    local ok, err = GARLog.CancelProduction(ply, a.line, tonumber(a.id))
    if not ok then Fail(ply, err) end
end

-- Reparaturaufträge -------------------------------------------------------
Actions["rep.accept"] = function(ply, a)
    if not Need(ply, "repair.work") then return end
    local o = RepById(a.id)
    if not o or o.st ~= GARLog.REP_OPEN then return Fail(ply, "Auftrag ist nicht mehr offen.") end
    o.st, o.as, o.asid = GARLog.REP_ASSIGNED, GARLog.Name(ply), ply:SteamID()
    GARLog.MarkDirty("rep")
    if o.k == "manual" then GARLog.DB.MarkDirty("rep") end
    if o.ent or o.pos then GARLog.SendWaypoint(ply, o) end
    Done(ply, string.format("Reparaturauftrag R-%d übernommen: %s", o.id, o.title))
end

Actions["rep.drop"] = function(ply, a)
    local o = RepById(a.id)
    if not o or o.st ~= GARLog.REP_ASSIGNED then return end
    if o.asid ~= ply:SteamID() and not GARLog.IsAdmin(ply) then return Fail(ply, "Nicht dein Auftrag.") end
    local assigned = player.GetBySteamID(o.asid or "")
    o.st, o.as, o.asid = GARLog.REP_OPEN, nil, nil
    if IsValid(assigned) then
        net.Start("GARLog_Waypoint") net.WriteUInt(o.id, 16) net.WriteBool(false) net.Send(assigned)
    end
    GARLog.MarkDirty("rep")
    if o.k == "manual" then GARLog.DB.MarkDirty("rep") end
end

Actions["rep.done"] = function(ply, a)
    local o = RepById(a.id)
    if not o or o.k ~= "manual" or o.st >= GARLog.REP_DONE then return end
    if o.asid ~= ply:SteamID() and not GARLog.Can(ply, "repair.create") then return Fail(ply, "Keine Berechtigung.") end
    GARLog.CloseRepair(o, GARLog.REP_DONE, GARLog.Name(ply))
    GARLog.Log(string.format("Reparaturauftrag R-%d erledigt (%s): %s", o.id, GARLog.Name(ply), o.title), "ok")
end

Actions["rep.cancel"] = function(ply, a)
    local o = RepById(a.id)
    if not o or o.k ~= "manual" or o.st >= GARLog.REP_DONE then return end
    if o.bysid ~= ply:SteamID() and not GARLog.IsAdmin(ply) then return Fail(ply, "Nur der Ersteller kann den Auftrag zurückziehen.") end
    GARLog.CloseRepair(o, GARLog.REP_CANCELLED, GARLog.Name(ply))
end

Actions["rep.create"] = function(ply, a)
    if not Need(ply, "repair.create") then return end
    if not GARLog.GetLoc(a.loc) then return Fail(ply, "Unbekannter Standort.") end
    local title = GARLog.CleanText(a.title, 60)
    if title == "" then return Fail(ply, "Bitte eine Bezeichnung angeben.") end
    local data = {
        k = "manual", loc = a.loc, title = title, nt = GARLog.CleanText(a.note, 200),
        pr = math.Clamp(math.floor(tonumber(a.prio) or 2), 1, 4), by = GARLog.Name(ply), bysid = ply:SteamID(),
    }
    -- optional: Ziel-Entity (Schiff / Fahrzeug / Struktur) für Wegpunkt & automatischen Abschluss
    local target = tonumber(a.ent) and Entity(tonumber(a.ent))
    if IsValid(target) and (GARLog.IsVehicle(target) or GARLog.FOBEnts[target]) then
        data.ent, data.pos = target:EntIndex(), target:WorldSpaceCenter()
        data.veh = GARLog.IsVehicle(target) or nil
    end
    if tonumber(a.rpt) and GARLog.Reports and GARLog.Reports[tonumber(a.rpt)] then data.rpt = tonumber(a.rpt) end
    local o = GARLog.CreateRepair(data)
    GARLog.Log(string.format("Reparaturauftrag R-%d erstellt von %s: %s (%s)", o.id, o.by, title, GARLog.LocName(a.loc)))
    GARLog.NotifyPerm("repair.work", string.format("Neuer Reparaturauftrag R-%d: %s (%s)", o.id, title, GARLog.LocName(a.loc)), o.pr >= 3 and "warn" or "info", ply)
    Done(ply, "Reparaturauftrag R-" .. o.id .. " erstellt.")
end

-- Feldbasis ---------------------------------------------------------------
Actions["fob.rename"] = function(ply, a)
    local f = FOB.Get(tonumber(a.fob) or -1)
    if not f then return end
    local ok, err = FOB.Rename(ply, f, a.name)
    if not ok then Fail(ply, err) end
end

Actions["fob.dissolve"] = function(ply, a)
    if not Need(ply, "fob.manage") then return end
    local f = FOB.Get(tonumber(a.fob) or -1)
    if not f then return end
    if not GARLog.IsAdmin(ply) and ply.GARLogInFOB ~= f.id then return Fail(ply, "Du musst dich in der Feldbasis befinden.") end
    FOB.Dissolve(f, "aufgelöst von " .. GARLog.Name(ply))
end

Actions["build.place"] = function(ply, a)
    local pos = Vector(tonumber(a.x) or 0, tonumber(a.y) or 0, tonumber(a.z) or 0)
    local ok, err = FOB.Place(ply, tostring(a.key or ""), pos, tonumber(a.yaw) or 0, a.name)
    if not ok then Fail(ply, err) end
end

Actions["build.dismantle"] = function(ply, a)
    local wep = ply:GetActiveWeapon()
    if not GARLog.IsTool(wep) then return Fail(ply, "Datapad erforderlich.") end
    local ok, err = FOB.Dismantle(ply, Entity(tonumber(a.ent) or 0))
    if not ok then Fail(ply, err) end
end

Actions["gen.toggle"] = function(ply, a)
    local ent = Entity(tonumber(a.ent) or 0)
    if not IsValid(ent) or ent:GetClass() ~= "garlog_generator" then return end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 250 * 250 then return end
    ent:Toggle(ply)
end

-- Admin -------------------------------------------------------------------
Actions["admin.setstock"] = function(ply, a)
    if not GARLog.IsAdmin(ply) then return end
    local n = tonumber(a.n)
    if not GARLog.GetLoc(a.loc) or not GARLog.Res[a.res] or not n then return end
    GARLog.SetStock(a.loc, a.res, n)
    GARLog.Log(string.format("Admin %s: %s / %s auf %s gesetzt.", GARLog.Name(ply), GARLog.LocName(a.loc), GARLog.Res[a.res].name, GARLog.FmtNum(n)), "warn")
end

---------------------------------------------------------------------------
-- Empfang (mit Ratenbegrenzung)
---------------------------------------------------------------------------
net.Receive("GARLog_Action", function(len, ply)
    if not IsValid(ply) or len > 65536 then return end

    local now = CurTime()
    if (ply.GARLogActWin or 0) < now then
        ply.GARLogActWin, ply.GARLogActN = now + 1, 0
    end
    ply.GARLogActN = ply.GARLogActN + 1
    if ply.GARLogActN > 12 then return end

    local name = net.ReadString()
    local raw = net.ReadString()
    local fn = Actions[name]
    if not fn or #raw > 8192 then return end

    local args = util.JSONToTable(raw)
    if not istable(args) then args = {} end
    if not NO_UI[name] and not GARLog.CanUseUI(ply) then return end

    GARLog.Protected("Aktion " .. name, fn, ply, args)
end)
