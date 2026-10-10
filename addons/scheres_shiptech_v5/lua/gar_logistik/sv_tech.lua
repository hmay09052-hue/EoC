-- Technik: Schiffs- & Fahrzeugreparatur (Fusion-Cutter-Addon), Fahrzeugregister, Wartungsberichte

util.AddNetworkString("GARLog_Report")

local cfg = GARLog.Config
local DB = GARLog.DB
local Builders = GARLog.SyncBuilders
local Actions = GARLog.Actions
local RCFG = cfg.Reports

GARLog.Reports  = GARLog.Reports or {}
GARLog.Vehicles = GARLog.Vehicles or {}   -- Entity -> true (nur Basis-Fahrzeuge, keine Anbauteile)
local Reports, Vehicles = GARLog.Reports, GARLog.Vehicles

GARLog.FullSections.rpt = true
GARLog.FullSections.veh = true

---------------------------------------------------------------------------
-- Start: Berichte laden, alte Entity-Verweise verwerfen
---------------------------------------------------------------------------
if not GARLog.TechBooted then
    GARLog.TechBooted = true
    -- Entity-Indizes aus der letzten Sitzung zeigen nach einem Neustart auf andere Objekte
    for _, o in pairs(GARLog.Repairs) do o.ent = nil end
    for _, r in ipairs(DB.Load("rpt") or {}) do
        if istable(r) and tonumber(r.id) then Reports[tonumber(r.id)] = r end
    end
end

---------------------------------------------------------------------------
-- Fusion-Cutter-Anbindung
---------------------------------------------------------------------------
function GARLog.UseFCR()
    return cfg.VehicleRepair.UseFCR ~= false and FCR ~= nil and FCR.Util ~= nil
        and FCR.Session ~= nil and FCR.Session.TryBegin ~= nil
end

-- Welches Lager zahlt die Ersatzteile? Feldbasis > nächstes verankertes Lager > Heimatschiff
function GARLog.VehicleRepairLocation(ent)
    local pos = ent:GetPos()
    local f = GARLog.FOB.At(pos)
    if f then return f.locId end
    local id = GARLog.FindReceiver(pos, cfg.VehicleRepair.AnchorRange)
    if id then return id end
    if GARLog.GetLoc(cfg.DefaultShip) then return cfg.DefaultShip end
end

function GARLog.VehicleRepairCost(ent)
    local hp, max = GARLog.VehicleHealth(ent)
    return math.ceil(math.max(0, max - hp) * cfg.VehicleRepair.CostPerHP), hp, max
end

local REASON_TEXT = {
    vehicle_locked = "Dieses Fahrzeug wird bereits von einem anderen Techniker repariert.",
    session_active = "Du führst bereits ein Reparaturprotokoll durch.",
    group_blocked  = "Keine Berechtigung für das Reparaturprotokoll.",
    job_blocked    = "Keine Berechtigung für das Reparaturprotokoll.",
}

-- LMB mit dem Datapad: auf ein Schiff / Fahrzeug gerichtet -> Fusion-Cutter-Protokoll. true = behandelt
function GARLog.TryVehicleRepair(ply, wep)
    if not GARLog.UseFCR() then return false end
    local U, C = FCR.Util, FCR.Config
    local tr = U.GetTargetTrace(ply, (C.RepairDistance or 210) + (C.RepairRangeGrace or 0))
    local ent = U.ResolveRepairEntity(tr.Entity)
    if not U.IsSupportedVehicle(ent) then return false end

    if not U.IsRepairTarget(ent) then
        GARLog.NotifyOnce(ply, "veh_full", GARLog.VehicleLabel(ent) .. ": Integrität 100 % – keine Reparatur nötig.", "info", 3)
        return true
    end
    local ok, why = FCR.Session.TryBegin(ply, wep)
    if not ok and REASON_TEXT[why] then GARLog.NotifyOnce(ply, "fcr_" .. why, REASON_TEXT[why], "err", 2) end
    return true
end

hook.Add("FCR_CanBegin", "GARLog_VehicleRepair", function(ply, ent, wep)
    if not GARLog.IsTool(wep) then return end   -- der eigenständige Fusion Cutter bleibt unverändert
    if not GARLog.Can(ply, "repair.vehicle") then
        GARLog.Notify(ply, "Keine Berechtigung: Schiffe & Fahrzeuge reparieren nur Techniker.", "err")
        return false, "garlog_perm"
    end

    local cost, hp, max = GARLog.VehicleRepairCost(ent)
    local locId = GARLog.VehicleRepairLocation(ent)
    if cfg.VehicleRepair.RequireStock and cost > 0 then
        if not locId then
            GARLog.Notify(ply, "Kein Lager erreichbar – Ersatzteile können nicht gebucht werden.", "err")
            return false, "garlog_parts"
        end
        local have = GARLog.Stock(locId, "tech")
        if have < cost then
            GARLog.Notify(ply, string.format("%s: nicht genug Ersatzteile (%s / %s TEC) – Nachschub anfordern!",
                GARLog.LocName(locId), GARLog.FmtNum(have), GARLog.FmtNum(cost)), "err")
            return false, "garlog_parts"
        end
    end

    ply.GARLogFCRJob = { ent = ent, loc = locId, cost = cost, hp = hp, max = max }
    if cost > 0 and locId then
        GARLog.Notify(ply, string.format("Reparaturprotokoll: %s (%d %%) – %s TEC aus %s.", GARLog.VehicleLabel(ent),
            math.floor(hp / math.max(1, max) * 100), GARLog.FmtNum(cost), GARLog.LocName(locId)), "info")
    end
end)

hook.Add("FCR_RepairCompleted", "GARLog_VehicleRepair", function(ply, ent, session)
    if not IsValid(ent) then return end
    local job = IsValid(ply) and ply.GARLogFCRJob or nil
    if job and job.ent ~= ent then job = nil end
    if IsValid(ply) then ply.GARLogFCRJob = nil end

    local paid = 0
    if job and job.cost > 0 and job.loc then paid = GARLog.TakeUpTo(job.loc, "tech", job.cost, true) end
    local profile = session and session.difficultyProfile
    GARLog.OnVehicleServiced(ply, ent, job and job.loc or GARLog.VehicleRepairLocation(ent), {
        paid = paid,
        hpBefore = (session and session.hpBefore) or (job and job.hp) or 0,
        hpMax = (session and session.hpMax) or (job and job.max) or 0,
        fails = session and session.failures or 0,
        diff = profile and (profile.Name or profile.Id) or nil,
        fcr = true,
    })
end)

hook.Add("FCR_SessionEnded", "GARLog_VehicleRepair", function(ply, ent, reason, session)
    if IsValid(ply) and ply.GARLogFCRJob and reason ~= "success_cleanup" then ply.GARLogFCRJob = nil end
    if reason == "attempts_exhausted" and IsValid(ply) and IsValid(ent) then
        GARLog.Log(string.format("%s: Reparaturprotokoll an %s fehlgeschlagen (alle Versuche verbraucht).",
            GARLog.Name(ply), GARLog.VehicleLabel(ent)), "warn")
    end
    GARLog.MarkDirty("veh")
end)

-- Fahrzeug vollständig instandgesetzt (Fusion Cutter oder Technikerstation)
function GARLog.OnVehicleServiced(ply, ent, locId, info)
    info = info or {}
    local name = IsValid(ply) and GARLog.Name(ply) or "Unbekannt"
    local label = GARLog.VehicleLabel(ent)
    ent.GARLogLastService = { t = os.time(), by = name }

    -- verknüpfte Reparaturaufträge abschließen
    local idx = ent:EntIndex()
    for _, o in pairs(GARLog.Repairs) do
        if o.ent == idx and o.st <= GARLog.REP_ASSIGNED then GARLog.CloseRepair(o, GARLog.REP_DONE, name) end
    end

    local before = info.hpMax and info.hpMax > 0 and math.floor(info.hpBefore / info.hpMax * 100) or nil
    GARLog.Log(string.format("%s hat %s instandgesetzt%s%s.", name, label,
        before and string.format(" (%d %% -> 100 %%)", before) or "",
        (info.paid or 0) > 0 and string.format(", %s TEC aus %s", GARLog.FmtNum(info.paid), GARLog.LocName(locId)) or ""), "ok")

    if RCFG.AutoFromFCR and info.fcr then
        local fd = before and string.format("Integrität vor der Instandsetzung: %d %% (%s / %s HP).", before,
            GARLog.FmtNum(info.hpBefore), GARLog.FmtNum(info.hpMax)) or "Strukturschaden festgestellt."
        local ms = "Fusion-Cutter-Reparaturprotokoll erfolgreich abgeschlossen. Integrität wiederhergestellt."
        if info.diff then ms = ms .. "\nSchwierigkeit: " .. tostring(info.diff) .. "." end
        if (info.fails or 0) > 0 then ms = ms .. "\nFehlversuche: " .. info.fails .. "." end
        GARLog.CreateReport(ply, {
            cat = "vehicle", obj = label, loc = locId or "", st = 1, fd = fd, ms = ms, veh = ent:GetClass(),
        }, { auto = true, prepaid = info.paid or 0 })
    end
    GARLog.MarkDirty("veh")
end

---------------------------------------------------------------------------
-- Fahrzeugregister (alle Schiffe & Fahrzeuge auf der Map)
---------------------------------------------------------------------------
-- Schnelle Vorprüfung ohne Funktionsaufrufe ins Fusion-Cutter-Addon (Projektile, Effekte usw. fallen sofort raus)
local SIMFPHYS_BASE = "gmod_sent_vehicle_fphysics_base"
local function MaybeVehicle(ent)
    return ent.LVS == true or ent.LFS == true or ent:GetClass() == SIMFPHYS_BASE
end

local function TrackVehicle(ent)
    if not IsValid(ent) or Vehicles[ent] or not MaybeVehicle(ent) then return end
    if GARLog.ResolveVehicle(ent) ~= ent or not GARLog.IsVehicle(ent) then return end  -- Anbauteile ignorieren
    Vehicles[ent] = true
    GARLog.MarkDirty("veh")
end

-- Neue Entities nur sammeln; ein Timer prüft sie gebündelt (kein Timer pro Entity)
local pendingVeh = {}
hook.Add("OnEntityCreated", "GARLog_Vehicles", function(ent)
    if ent:IsScripted() then pendingVeh[#pendingVeh + 1] = ent end
end)

timer.Create("GARLog_VehicleQueue", 1, 0, function()
    if #pendingVeh == 0 then return end
    local list = pendingVeh
    pendingVeh = {}
    for i = 1, #list do TrackVehicle(list[i]) end
end)

hook.Add("EntityRemoved", "GARLog_Vehicles", function(ent)
    if Vehicles[ent] then
        Vehicles[ent] = nil
        GARLog.MarkDirty("veh")
    end
end)

local function ScanVehicles()
    for _, e in ipairs(ents.GetAll()) do
        if e:IsScripted() then TrackVehicle(e) end
    end
end
hook.Add("InitPostEntity", "GARLog_Vehicles", function() timer.Simple(5, ScanVehicles) end)
timer.Simple(0, ScanVehicles) -- Lua-Refresh

-- Nur bei Zustandsänderung neu senden und nur, wenn jemand das Datapad offen hat
local lastSig
local function WatchVehicles()
    if not next(Vehicles) or not GARLog.HasFullSubscribers() then return end
    local parts = {}
    for ent in pairs(Vehicles) do
        if IsValid(ent) then
            local hp, mx = GARLog.VehicleHealth(ent)
            parts[#parts + 1] = ent:EntIndex() .. ":" .. math.floor(hp / math.max(1, mx) * 50)   -- 2-%-Schritte
        else
            Vehicles[ent] = nil
        end
    end
    table.sort(parts)
    local sig = table.concat(parts, ",")
    if sig ~= lastSig then
        lastSig = sig
        GARLog.MarkDirty("veh")
    end
end
timer.Create("GARLog_VehicleWatch", 2, 0, function() GARLog.Protected("Fahrzeug-Überwachung", WatchVehicles) end)

Builders.veh = function()
    local list = {}
    local active = FCR and FCR.Session and FCR.Session.ActiveByVehicle or {}
    for ent in pairs(Vehicles) do
        if IsValid(ent) then
            local hp, mx = GARLog.VehicleHealth(ent)
            local e = {
                i = ent:EntIndex(), n = GARLog.VehicleLabel(ent), c = ent:GetClass(),
                hp = math.floor(hp), mx = math.floor(mx), at = GARLog.DescribePos(ent:GetPos()),
            }
            local ls = ent.GARLogLastService
            if ls then e.ls, e.lb = ls.t, ls.by end
            if active[e.i] then e.fcr = true end
            if isfunction(ent.GetDriver) then
                local ok, d = pcall(ent.GetDriver, ent)
                if ok and IsValid(d) and d:IsPlayer() then e.d = d:Nick() end
            end
            list[#list + 1] = e
        end
    end
    table.sort(list, function(a, b)
        local fa, fb = a.hp / math.max(1, a.mx), b.hp / math.max(1, b.mx)
        if fa ~= fb then return fa < fb end
        return a.i < b.i
    end)
    return list
end

---------------------------------------------------------------------------
-- Wartungsberichte
-- Sync enthält nur Kopfdaten; den vollständigen Bericht holt der Client bei Bedarf (rpt.get).
---------------------------------------------------------------------------
local function Header(r)
    return {
        id = r.id, cat = r.cat, obj = r.obj, st = r.st, by = r.by, sid = r.sid, t = r.t, u = r.u, v = r.v,
        loc = r.loc, ln = r.ln, a = r.auto or nil, pt = r.pt, n = #(r.notes or {}), veh = r.veh, rep = r.rep,
    }
end

local function SortedReports()
    local list = {}
    for _, r in pairs(Reports) do list[#list + 1] = r end
    table.sort(list, function(a, b) return a.id > b.id end)
    return list
end

Builders.rpt = function()
    local list, out = SortedReports(), {}
    for i = 1, math.min(#list, 200) do out[i] = Header(list[i]) end
    return out
end

DB.Register("rpt", SortedReports)

local function TouchReport(r)
    r.u = os.time()
    r.v = (r.v or 0) + 1   -- Versionszähler (Client-Cache), unabhängig von der Sekunde
    GARLog.MarkDirty("rpt")
    DB.MarkDirty("rpt")
end

local function PruneReports()
    local list = SortedReports()
    for i = RCFG.MaxStored + 1, #list do Reports[list[i].id] = nil end
end

function GARLog.SendReport(ply, r)
    local comp = util.Compress(util.TableToJSON(r))
    if not comp then return end
    net.Start("GARLog_Report")
        net.WriteUInt(#comp, 32)
        net.WriteData(comp, #comp)
    net.Send(ply)
end

local function StateName(st)
    local s = RCFG.States[st]
    return s and s.name or "?"
end

-- data: cat, obj, loc, st, fd, ms, parts, rep, veh   meta: auto, prepaid (bereits abgebuchte Ersatzteile)
function GARLog.CreateReport(ply, data, meta)
    meta = meta or {}
    local obj = GARLog.CleanText(data.obj, RCFG.TitleLength)
    if obj == "" then return nil, "Bitte das betroffene Objekt angeben." end
    local fd = GARLog.CleanMultiline(data.fd, RCFG.TextLength)
    local ms = GARLog.CleanMultiline(data.ms, RCFG.TextLength)
    if fd == "" and ms == "" then return nil, "Bitte Befund oder Maßnahmen eintragen." end

    local cat = GARLog.ReportCategory(data.cat).id
    local st = math.Clamp(math.floor(tonumber(data.st) or 1), 1, #RCFG.States)
    local loc = isstring(data.loc) and GARLog.GetLoc(data.loc) and data.loc or ""

    local parts = 0
    if meta.prepaid then
        parts = math.max(0, math.floor(tonumber(meta.prepaid) or 0))
    else
        parts = math.Clamp(math.floor(tonumber(data.parts) or 0), 0, RCFG.MaxParts)
        if parts > 0 then
            if loc == "" then return nil, "Für verbrauchte Ersatzteile muss ein Standort gewählt werden." end
            if not GARLog.TakeStock(loc, { tech = parts }, true) then
                return nil, GARLog.LocName(loc) .. ": nicht genug Ersatzteile auf Lager."
            end
        end
    end

    local rep = tonumber(data.rep)
    if rep and not GARLog.Repairs[rep] then rep = nil end
    local veh = GARLog.CleanText(data.veh, 60)

    local r = {
        id = GARLog.NextId("nextRpt"), cat = cat, obj = obj, st = st, fd = fd, ms = ms,
        loc = loc, ln = loc ~= "" and GARLog.LocName(loc) or nil, pt = parts > 0 and parts or nil,
        rep = rep, veh = veh ~= "" and veh or nil, auto = meta.auto or nil,
        by = IsValid(ply) and GARLog.Name(ply) or "System", sid = IsValid(ply) and ply:SteamID() or "",
        t = os.time(), notes = {},
    }
    Reports[r.id] = r
    PruneReports()
    TouchReport(r)

    if rep then
        local o = GARLog.Repairs[rep]
        o.rpt = r.id
        GARLog.MarkDirty("rep")
        if o.k == "manual" then DB.MarkDirty("rep") end
    end

    if not meta.auto then
        GARLog.Log(string.format("Wartungsbericht W-%d von %s: %s – %s", r.id, r.by, obj, StateName(st)))
        if st == 3 then
            GARLog.NotifyPerm("repair.work", string.format("Wartungsbericht W-%d: %s AUSSER BETRIEB%s", r.id, obj,
                loc ~= "" and (" (" .. GARLog.LocName(loc) .. ")") or ""), "warn", ply)
        end
    end
    return r
end

---------------------------------------------------------------------------
-- Aktionen
---------------------------------------------------------------------------
local function Fail(ply, err) if err then GARLog.Notify(ply, err, "err") end end
local function RptById(id) return Reports[tonumber(id) or -1] end

local function CanEdit(ply, r)
    return r.sid == ply:SteamID() or GARLog.Can(ply, "report.manage")
end

Actions["rpt.get"] = function(ply, a)
    local r = RptById(a.id)
    if r then GARLog.SendReport(ply, r) end
end

Actions["rpt.create"] = function(ply, a)
    if not GARLog.Can(ply, "report.create") then return Fail(ply, "Keine Berechtigung, Wartungsberichte zu erstellen.") end
    local r, err = GARLog.CreateReport(ply, a)
    if not r then return Fail(ply, err) end
    GARLog.Notify(ply, "Wartungsbericht W-" .. r.id .. " gespeichert.", "ok")
    GARLog.SendReport(ply, r)
end

Actions["rpt.edit"] = function(ply, a)
    local r = RptById(a.id)
    if not r then return end
    if not CanEdit(ply, r) then return Fail(ply, "Nur der Verfasser oder das Kommando kann diesen Bericht bearbeiten.") end
    local obj = GARLog.CleanText(a.obj, RCFG.TitleLength)
    local fd = GARLog.CleanMultiline(a.fd, RCFG.TextLength)
    local ms = GARLog.CleanMultiline(a.ms, RCFG.TextLength)
    if obj == "" or (fd == "" and ms == "") then return Fail(ply, "Objekt und Befund oder Maßnahmen sind Pflicht.") end
    r.obj, r.fd, r.ms = obj, fd, ms
    r.cat = GARLog.ReportCategory(a.cat).id
    r.st = math.Clamp(math.floor(tonumber(a.st) or r.st), 1, #RCFG.States)
    r.ed = GARLog.Name(ply)
    TouchReport(r)
    GARLog.Notify(ply, "Wartungsbericht W-" .. r.id .. " aktualisiert.", "ok")
    GARLog.SendReport(ply, r)
end

Actions["rpt.note"] = function(ply, a)
    local r = RptById(a.id)
    if not r then return end
    if not (GARLog.Can(ply, "report.create") or GARLog.Can(ply, "repair.work")) then return Fail(ply, "Keine Berechtigung.") end
    local text = GARLog.CleanMultiline(a.text, RCFG.NoteLength)
    if text == "" then return end
    r.notes = r.notes or {}
    if #r.notes >= RCFG.MaxNotes then return Fail(ply, "Maximale Anzahl an Notizen erreicht.") end
    r.notes[#r.notes + 1] = { t = os.time(), b = GARLog.Name(ply), x = text }
    TouchReport(r)
    GARLog.SendReport(ply, r)
end

Actions["rpt.delete"] = function(ply, a)
    local r = RptById(a.id)
    if not r then return end
    if not CanEdit(ply, r) then return Fail(ply, "Nur der Verfasser oder das Kommando kann diesen Bericht löschen.") end
    Reports[r.id] = nil
    GARLog.MarkDirty("rpt")
    DB.MarkDirty("rpt")
    GARLog.Log(string.format("Wartungsbericht W-%d gelöscht von %s.", r.id, GARLog.Name(ply)), "warn")
end
