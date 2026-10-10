--[[
    ShipTech – Spieleraktionen: Konsolen, Minigames, Reparaturen, Berichte, Freigaben, Fortbildungen
]]

local C = ShipTech.Config

local function Def(id) return ShipTech.SystemById[id] end
local function Sys(id) return ShipTech.State.systems[id] end
local function StageOf(h) return ShipTech.StageOf(h) end
local function Deny(ply, text) ShipTech.Notify(ply, text, 1) end
local function Ok(ply, text) ShipTech.Notify(ply, text, 0) end

---------------------------------------------------------------------------
-- Qualifikationen (data/shiptech/quals.json, Schlüssel = SteamID)
---------------------------------------------------------------------------
ShipTech.Quals = ShipTech.Quals or {}

local function LoadQuals()
    local raw = file.Read("shiptech/quals.json", "DATA")
    ShipTech.Quals = (raw and util.JSONToTable(raw)) or {}
end

local function SaveQuals()
    file.Write("shiptech/quals.json", util.TableToJSON(ShipTech.Quals, true))
end

function ShipTech.GetPlayerQuals(sid)
    local stored = ShipTech.Quals[sid] or {}
    local set = {}
    for q, v in pairs(stored) do
        if v == true then set[q] = true end
    end
    for _, q in ipairs(C.DefaultQuals) do
        if stored[q] == nil then set[q] = true end
    end
    return set
end

function ShipTech.ApplyQuals(ply)
    local list = {}
    for q in pairs(ShipTech.GetPlayerQuals(ply:SteamID())) do list[#list + 1] = q end
    table.sort(list)
    ply:SetNW2String("ST_Quals", "," .. table.concat(list, ",") .. ",")
end

LoadQuals()
for _, ply in ipairs(player.GetAll()) do ShipTech.ApplyQuals(ply) end

hook.Add("PlayerInitialSpawn", "ShipTech_Init", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        ShipTech.ApplyQuals(ply)
        ShipTech.SendState(ply)
    end)
end)

---------------------------------------------------------------------------
-- Konsole öffnen
---------------------------------------------------------------------------
function ShipTech.OpenFor(ply, ent)
    if (ply.ST_NextUse or 0) > CurTime() then return end
    ply.ST_NextUse = CurTime() + 0.5
    net.Start("ShipTech_Open")
    net.WriteEntity(ent)
    net.Send(ply)
end

---------------------------------------------------------------------------
-- Fortschrittsbalken (Spieler muss an der Konsole bleiben)
---------------------------------------------------------------------------
ShipTech.Progress = ShipTech.Progress or {}

local function SendProgress(ply, label, dur)
    net.Start("ShipTech_Progress")
    net.WriteString(label or "")
    net.WriteFloat(dur or 0)
    net.Send(ply)
end

function ShipTech.StartProgress(ply, ent, dur, label, cb)
    ShipTech.Progress[ply] = { ent = ent, done = CurTime() + dur, cb = cb, tool = C.Tool.Required and ShipTech.HasTool(ply) }
    SendProgress(ply, label, dur)
end

local function IsBusy(ply)
    return ply.ST_Task ~= nil or ShipTech.Progress[ply] ~= nil
end

timer.Create("ShipTech_ProgressThink", 0.2, 0, function()
    local maxDist = (C.UseDistance * 1.6) ^ 2
    for ply, p in pairs(ShipTech.Progress) do
        if not IsValid(ply) then
            ShipTech.Progress[ply] = nil
        elseif not ply:Alive() or not IsValid(p.ent) or ply:GetPos():DistToSqr(p.ent:GetPos()) > maxDist then
            ShipTech.Progress[ply] = nil
            SendProgress(ply, "", 0)
            Deny(ply, "Arbeit abgebrochen – du hast dich von der Konsole entfernt.")
        elseif p.tool and not ShipTech.HasTool(ply) then
            ShipTech.Progress[ply] = nil
            SendProgress(ply, "", 0)
            Deny(ply, "Arbeit abgebrochen – Werkzeug weggesteckt.")
        elseif CurTime() < p.done then
            -- Arbeitsanimation mit dem Datapad
            if p.tool and CurTime() >= (p.nextAnim or 0) then
                p.nextAnim = CurTime() + 0.9
                local wep = ply:GetActiveWeapon()
                if IsValid(wep) then wep:SendWeaponAnim(ACT_VM_HITCENTER) end
                ply:SetAnimation(PLAYER_ATTACK1)
                local ed = EffectData()
                ed:SetOrigin(p.ent:LocalToWorld(Vector(0, 0, p.ent:OBBMaxs().z * 0.7)))
                ed:SetMagnitude(1)
                ed:SetScale(1)
                ed:SetRadius(2)
                util.Effect("ElectricSpark", ed, true, true)
                p.ent:EmitSound(math.random() < 0.5 and "physics/metal/metal_solid_impact_hard1.wav" or "ambient/energy/spark" .. math.random(1, 6) .. ".wav", 65, math.random(95, 110), 0.5)
            end
        else
            ShipTech.Progress[ply] = nil
            SendProgress(ply, "", 0)
            local ok, err = pcall(p.cb)
            if not ok then ErrorNoHalt("[ShipTech] " .. tostring(err) .. "\n") end
        end
    end
    -- hängende Minigames aufräumen
    for _, ply in ipairs(player.GetAll()) do
        local t = ply.ST_Task
        if t and CurTime() > t.start + t.limit + 20 then ply.ST_Task = nil end
    end
end)

---------------------------------------------------------------------------
-- Minigames
---------------------------------------------------------------------------
function ShipTech.StartMinigame(ply, ent, game, title, diff, cb)
    if IsBusy(ply) then
        Deny(ply, "Du arbeitest bereits an etwas.")
        return
    end
    local limit = math.floor(C.MinigameTime * (ShipTech.State.combat and C.CombatTimeFactor or 1))
    local token = math.random(1, 2000000000)
    ply.ST_Task = { token = token, ent = ent, cb = cb, start = CurTime(), limit = limit }

    net.Start("ShipTech_Minigame")
    net.WriteUInt(token, 32)
    net.WriteString(game)
    net.WriteString(title)
    net.WriteUInt(math.Clamp(diff or 1, 1, 3), 3)
    net.WriteUInt(limit, 8)
    net.Send(ply)
end

net.Receive("ShipTech_MinigameResult", function(_, ply)
    local token = net.ReadUInt(32)
    local ok = net.ReadBool()
    local task = ply.ST_Task
    if not task or task.token ~= token then return end
    ply.ST_Task = nil

    local elapsed = CurTime() - task.start
    if ok and elapsed < C.MinigameMinTime then ok = false end
    if elapsed > task.limit + 10 then ok = false end
    if not IsValid(task.ent) or ply:GetPos():DistToSqr(task.ent:GetPos()) > (C.UseDistance * 2) ^ 2 then ok = false end

    local s, err = pcall(task.cb, ok)
    if not s then ErrorNoHalt("[ShipTech] " .. tostring(err) .. "\n") end
end)

hook.Add("PlayerDeath", "ShipTech_ClearTask", function(ply)
    ply.ST_Task = nil
    ShipTech.Progress[ply] = nil
end)

hook.Add("PlayerDisconnected", "ShipTech_ClearTask", function(ply)
    ShipTech.Progress[ply] = nil
end)

local function Diff(id)
    local s = Sys(id)
    return math.Clamp(math.max(StageOf(s.health), s.wfSev or 0), 1, 3)
end

---------------------------------------------------------------------------
-- Aktionen
---------------------------------------------------------------------------
local Actions = {}
ShipTech.Actions = Actions

-- System an der eigenen Konsole oder (falls erlaubt) über ein Terminal
local function ConsoleSys(ent)
    if ent.ConsoleKind == "system" then return ent.SysId end
end

local function AnySys(ent, arg)
    if ent.ConsoleKind == "system" then return ent.SysId end
    if ent.ConsoleKind == "terminal" and isstring(arg) and Def(arg) then return arg end
end

-- Datapad muss in der Hand sein
local function NeedTool(ply)
    if not C.Tool.Required or ShipTech.HasTool(ply) then return true end
    Deny(ply, "Du brauchst das Datapad in der Hand (" .. C.Tool.Class .. ").")
    return false
end

-- Brennende Konsolen müssen erst gelöscht werden
local function BurningDeny(ply, id)
    if ShipTech.IsBurning and ShipTech.IsBurning(id) then
        Deny(ply, "Die Konsole brennt – zuerst den Brand löschen!")
        return true
    end
    return false
end

local function NeedWork(ply, id)
    if ShipTech.CanWork(ply, id) then return true end
    Deny(ply, "Dir fehlt die Fortbildung: " .. ShipTech.QualById[Def(id).qual].name)
    return false
end

-- System hoch-/herunterfahren
Actions.power = function(ply, ent, a)
    local id = AnySys(ent, a.sys)
    if not id or id == "reactor" then return end
    if not ShipTech.CanWork(ply, id) and not ShipTech.IsNavy(ply) then
        return Deny(ply, "Keine Berechtigung für dieses System.")
    end
    local s, def = Sys(id), Def(id)
    if a.on then
        if s.wf then return Deny(ply, def.name .. " befindet sich in Wartung.") end
        if s.health <= 0 then return Deny(ply, def.name .. " ist ausgefallen – Reparatur erforderlich.") end
        if s.coolLock then return Deny(ply, def.name .. " kühlt nach einer Sicherheitsabschaltung noch ab.") end
        if def.navy and not s.navyClear then return Deny(ply, "Navy-Freigabe für " .. def.name .. " erforderlich.") end
        if ent:GetNW2Bool("ST_NoPow") then return Deny(ply, "Diese Konsole hat keine Energie.") end
        s.on = true
        ShipTech.Log("SYSTEM", def.name .. " hochgefahren", ply)
        Ok(ply, def.name .. " wird hochgefahren.")
    else
        s.on = false
        ShipTech.Log("SYSTEM", def.name .. " heruntergefahren", ply)
        Ok(ply, def.name .. " wurde heruntergefahren.")
    end
    ShipTech.MarkDirty()
end

Actions.reactor_start = function(ply, ent)
    if ConsoleSys(ent) ~= "reactor" then return end
    if not NeedWork(ply, "reactor") then return end
    local ok, err = ShipTech.StartReactor(ply)
    if not ok then Deny(ply, err) end
end

Actions.reactor_scram = function(ply, ent)
    if ConsoleSys(ent) ~= "reactor" then return end
    if not ShipTech.CanWork(ply, "reactor") and not ShipTech.IsNavy(ply) then
        return Deny(ply, "Keine Berechtigung.")
    end
    local ok, err = ShipTech.ScramReactor(ply)
    if not ok then Deny(ply, err) end
end

-- Fehlersuche / Diagnose
Actions.diagnose = function(ply, ent)
    local id = ConsoleSys(ent)
    if not id or not NeedWork(ply, id) or not NeedTool(ply) or BurningDeny(ply, id) then return end
    local def = Def(id)
    ShipTech.StartMinigame(ply, ent, "scan", "Fehlersuche: " .. def.name, Diff(id), function(ok)
        if not ok then return Deny(ply, "Fehlersuche fehlgeschlagen.") end
        ShipTech.StartProgress(ply, ent, C.DiagnoseTime, "Systemdiagnose: " .. def.name, function()
            local s = Sys(id)
            if #s.faults == 0 then
                s.maint = math.min(100, s.maint + 5)
                ShipTech.Log("DIAGNOSE", def.name .. ": Systemtest ohne Befund", ply)
                Ok(ply, "Diagnose abgeschlossen: Keine Störungen gefunden.")
                ShipTech.MarkDirty()
                return
            end
            for _, f in ipairs(s.faults) do f.k = true end
            if not s.wf then
                s.wf = "repair"
                s.wfSev = StageOf(s.health)
                s.on = false
            end
            ShipTech.Log("DIAGNOSE", def.name .. ": " .. #s.faults .. " Störung(en) identifiziert – System in Wartung", ply)
            Ok(ply, #s.faults .. " Störung(en) gefunden. " .. def.name .. " wurde für die Reparatur abgeschaltet.")
            ShipTech.MarkDirty()
        end)
    end)
end

-- Einzelne Störung beheben
Actions.repair = function(ply, ent, a)
    local id = ConsoleSys(ent)
    if not id or not NeedWork(ply, id) or not NeedTool(ply) or BurningDeny(ply, id) then return end
    local s, def = Sys(id), Def(id)
    local fault = s.faults[tonumber(a.idx) or 0]
    if not fault then return end
    if s.wf ~= "repair" or not fault.k then return Deny(ply, "Zuerst eine Diagnose durchführen.") end
    local canPay, why = ShipTech.CanPayRepair(fault.t, s.wfSev or 0)
    if not canPay then return Deny(ply, why) end
    local ft = ShipTech.FaultTypes[fault.t]

    ShipTech.StartMinigame(ply, ent, ft.game, "Reparatur: " .. ft.name, Diff(id), function(ok)
        if not ok then
            ShipTech.Log("REPARATUR", def.name .. ": Reparaturversuch fehlgeschlagen (" .. ft.name .. ")", ply)
            return Deny(ply, "Reparatur fehlgeschlagen – versuche es erneut.")
        end
        ShipTech.StartProgress(ply, ent, C.RepairTime[s.wfSev or 0] or 6, "Reparatur: " .. ft.name, function()
            local cur = Sys(id)
            local idx
            for i, f in ipairs(cur.faults) do
                if f == fault then idx = i break end
            end
            if not idx then return end
            local paid, used = ShipTech.PayRepair(fault.t, cur.wfSev or 0, "Reparatur " .. def.name, ply)
            if not paid then return Deny(ply, used or "Materialmangel – Reparatur nicht möglich.") end

            table.remove(cur.faults, idx)
            ShipTech.Log("REPARATUR", def.name .. ": " .. ft.name .. " behoben" .. (used and (" (" .. used .. ")") or ""), ply)

            if #cur.faults == 0 then
                cur.health = 100
                cur.maint = math.max(cur.maint, 70)
                if (cur.wfSev or 0) >= 2 then
                    cur.wf = "test"
                    Ok(ply, "Alle Störungen behoben. Nächster Schritt: Testlauf.")
                else
                    cur.wf = "report"
                    Ok(ply, "Alle Störungen behoben. Nächster Schritt: Wartungsbericht.")
                end
                ShipTech.ChatTechs("info", def.name .. ": Reparatur abgeschlossen – " .. ShipTech.WorkflowNames[cur.wf] .. ".")
            else
                cur.health = math.min(99, cur.health + (100 - cur.health) / (#cur.faults + 1))
                Ok(ply, ft.name .. " behoben. Verbleibende Störungen: " .. #cur.faults)
            end
            ShipTech.MarkDirty()
        end)
    end)
end

-- Testlauf nach schweren Schäden
Actions.testrun = function(ply, ent)
    local id = ConsoleSys(ent)
    if not id or not NeedWork(ply, id) or not NeedTool(ply) or BurningDeny(ply, id) then return end
    local s, def = Sys(id), Def(id)
    if s.wf ~= "test" then return Deny(ply, "Kein Testlauf erforderlich.") end
    ShipTech.StartMinigame(ply, ent, "testrun", "Testlauf: " .. def.name, Diff(id), function(ok)
        if not ok then
            ShipTech.Log("TESTLAUF", def.name .. ": Testlauf fehlgeschlagen", ply)
            return Deny(ply, "Testlauf fehlgeschlagen – erneut durchführen.")
        end
        ShipTech.StartProgress(ply, ent, C.TestRunTime, "Testlauf: " .. def.name, function()
            local cur = Sys(id)
            if cur.wf ~= "test" then return end
            cur.wf = "report"
            ShipTech.Log("TESTLAUF", def.name .. ": Testlauf erfolgreich", ply)
            Ok(ply, "Testlauf erfolgreich. Nächster Schritt: Wartungsbericht.")
            ShipTech.MarkDirty()
        end)
    end)
end

-- Routinewartung
Actions.maintain = function(ply, ent)
    local id = ConsoleSys(ent)
    if not id or not NeedWork(ply, id) or not NeedTool(ply) or BurningDeny(ply, id) then return end
    local s, def = Sys(id), Def(id)
    if s.wf then return Deny(ply, "Das System befindet sich bereits in einem Wartungsablauf.") end
    ShipTech.StartMinigame(ply, ent, def.maintGame or "wires", "Routinewartung: " .. def.name, 1, function(ok)
        if not ok then return Deny(ply, "Wartung fehlgeschlagen.") end
        ShipTech.StartProgress(ply, ent, C.MaintenanceTime, "Routinewartung: " .. def.name, function()
            local cur = Sys(id)
            local paid, used = ShipTech.PayItems(ShipTech.MaintItems(id), "Wartung " .. def.name, ply)
            if not paid then return Deny(ply, used) end
            cur.maint = 100
            cur.hours = 0
            cur.insp = cur.insp or {}
            for i = 1, #ShipTech.InspectionsFor(id) do cur.insp[i] = os.time() end
            if #cur.faults == 0 then cur.health = math.min(100, cur.health + 15) end
            ShipTech.Log("WARTUNG", def.name .. ": Routinewartung durchgeführt", ply)
            Ok(ply, "Wartung abgeschlossen. Bitte Wartungsbericht nicht vergessen.")
            ShipTech.MarkDirty()
        end)
    end)
end

-- Kalibrierung (Geschütze, Sensoren)
Actions.calibrate = function(ply, ent)
    local id = ConsoleSys(ent)
    if not id or not NeedWork(ply, id) or not NeedTool(ply) or BurningDeny(ply, id) then return end
    local s, def = Sys(id), Def(id)
    if not def.calib then return end
    if s.wf then return Deny(ply, "Das System befindet sich in Wartung.") end
    ShipTech.StartMinigame(ply, ent, "frequency", "Kalibrierung: " .. def.name, 2, function(ok)
        if not ok then return Deny(ply, "Kalibrierung fehlgeschlagen.") end
        ShipTech.StartProgress(ply, ent, C.CalibrationTime, "Kalibrierung: " .. def.name, function()
            local paid, used = ShipTech.PayItems(ShipTech.CalibItems(), "Kalibrierung " .. def.name, ply)
            if not paid then return Deny(ply, used) end
            Sys(id).calib = 100
            ShipTech.Log("KALIBRIERUNG", def.name .. " kalibriert", ply)
            Ok(ply, def.name .. " erfolgreich kalibriert.")
            ShipTech.MarkDirty()
        end)
    end)
end

-- Wartungsbericht
Actions.report = function(ply, ent, a)
    if not ShipTech.IsTechnician(ply) then return Deny(ply, "Nur Techniker können Wartungsberichte erstellen.") end
    local cause    = string.Trim(string.sub(tostring(a.cause or ""), 1, 600))
    local measures = string.Trim(string.sub(tostring(a.measures or ""), 1, 800))
    local notes    = string.Trim(string.sub(tostring(a.notes or ""), 1, 600))
    if #measures < 5 then return Deny(ply, "Bitte die durchgeführten Maßnahmen beschreiben.") end

    local id = (isstring(a.sys) and Def(a.sys)) and a.sys or nil
    local orderId = tonumber(a.order)
    local reports = ShipTech.Reports
    local rep = {
        id = ((reports[#reports] and reports[#reports].id) or 0) + 1,
        t = os.time(), author = ply:Nick(), sys = id, order = orderId,
        cause = cause, measures = measures, notes = notes,
    }
    reports[#reports + 1] = rep
    while #reports > C.ReportKeep do table.remove(reports, 1) end
    ShipTech.SaveReports()

    if id then
        local s = Sys(id)
        if s.wf == "report" then
            s.wf = "release"
            ShipTech.CompleteOrders(id, rep.id)
            ShipTech.ChatTechs("info", Def(id).name .. ": Wartungsbericht #" .. rep.id .. " eingereicht – Freigabe ausstehend.")
        end
    end
    if orderId then
        for _, o in ipairs(ShipTech.State.orders) do
            if o.id == orderId and (o.status == "open" or o.status == "accepted") then
                o.status = "done"
                o.report = rep.id
            end
        end
    end
    ShipTech.Log("BERICHT", "Wartungsbericht #" .. rep.id .. (id and (" (" .. Def(id).name .. ")") or "") .. " erstellt", ply)
    Ok(ply, "Wartungsbericht #" .. rep.id .. " gespeichert.")
    ShipTech.MarkDirty()
end

-- Freigabe
Actions.release = function(ply, ent, a)
    local id = AnySys(ent, a.sys)
    if not id then return end
    local s, def = Sys(id), Def(id)
    if not ShipTech.CanRelease(ply, id) then return Deny(ply, "Für die Freigabe wird die Fortbildung 'Systemfreigabe' benötigt.") end
    if s.wf ~= "release" then return Deny(ply, "Das System wartet nicht auf eine Freigabe.") end
    s.wf = nil
    s.wfSev = 0
    if ShipTech.IsOperational(s) and (not def.navy or s.navyClear) and id ~= "reactor" then s.on = true end
    ShipTech.Log("FREIGABE", def.name .. " freigegeben", ply)
    ShipTech.Chat("info", def.name .. " wurde von " .. ply:Nick() .. " freigegeben und ist wieder einsatzbereit.")
    ShipTech.MarkDirty()
end

-- Energieverteilung
Actions.alloc = function(ply, ent, a)
    -- Reaktor- und Energiekonsole sind verbunden und steuern beide die Verteilung
    if not (ent.ConsoleKind == "terminal" or ent.SysId == "power" or ent.SysId == "reactor") then return end
    if not ShipTech.CanManagePower(ply) then return Deny(ply, "Keine Berechtigung für die Energieverteilung.") end
    if ent:GetNW2Bool("ST_NoPow") then return Deny(ply, "Diese Konsole hat keine Energie.") end
    if not istable(a.alloc) then return end
    local total, new, parts = 0, {}, {}
    for _, def in ipairs(ShipTech.Systems) do
        if def.id ~= "reactor" then
            local v = math.Clamp(math.floor(tonumber(a.alloc[def.id]) or Sys(def.id).alloc), 0, C.MaxAllocPerSystem)
            new[def.id] = v
            total = total + v
            parts[#parts + 1] = def.name .. " " .. v
        end
    end
    if total > C.PowerBudget then return Deny(ply, "Die Gesamtzuteilung übersteigt " .. C.PowerBudget .. " Einheiten.") end
    for id, v in pairs(new) do Sys(id).alloc = v end
    ShipTech.Log("ENERGIE", "Energieverteilung geändert: " .. table.concat(parts, ", "), ply)
    Ok(ply, "Energieverteilung übernommen.")
    ShipTech.MarkDirty()
end

-- Schildsektor verstärken
Actions.shield_focus = function(ply, ent, a)
    if ConsoleSys(ent) ~= "shields" and ent.ConsoleKind ~= "terminal" then return end
    if not ShipTech.CanWork(ply, "shields") and not ShipTech.IsNavy(ply) then return Deny(ply, "Keine Berechtigung.") end
    local f = math.Clamp(math.floor(tonumber(a.sector) or 0), 0, 4)
    ShipTech.State.shields.focus = f
    ShipTech.Log("SCHILDE", f == 0 and "Schilde ausgeglichen" or ("Schildsektor " .. ShipTech.SectorNames[f] .. " verstärkt"), ply)
    ShipTech.MarkDirty()
end

-- Aufträge
Actions.order_accept = function(ply, ent, a)
    if not ShipTech.IsTechnician(ply) then return end
    for _, o in ipairs(ShipTech.State.orders) do
        if o.id == tonumber(a.id) and o.status == "open" then
            o.status = "accepted"
            o.assignee = ply:Nick()
            ShipTech.Log("AUFTRAG", "Auftrag #" .. o.id .. " angenommen", ply)
            Ok(ply, "Auftrag #" .. o.id .. " angenommen.")
            ShipTech.MarkDirty()
            return
        end
    end
end

Actions.order_create = function(ply, ent, a)
    if not ShipTech.CanCreateOrders(ply) then return Deny(ply, "Keine Berechtigung, Aufträge zu erstellen.") end
    local title = string.Trim(tostring(a.title or ""))
    if #title < 3 then return Deny(ply, "Bitte einen Titel angeben.") end
    ShipTech.CreateOrder({ sys = a.sys, title = title, desc = tostring(a.desc or ""), prio = a.prio }, ply)
    Ok(ply, "Auftrag erstellt.")
end

Actions.order_cancel = function(ply, ent, a)
    if not ShipTech.CanCreateOrders(ply) then return Deny(ply, "Keine Berechtigung.") end
    for _, o in ipairs(ShipTech.State.orders) do
        if o.id == tonumber(a.id) and (o.status == "open" or o.status == "accepted") then
            o.status = "cancel"
            ShipTech.Log("AUFTRAG", "Auftrag #" .. o.id .. " storniert", ply)
            ShipTech.MarkDirty()
            return
        end
    end
end

-- Navy / Brücke
Actions.navy_clear = function(ply, ent, a)
    if ent.ConsoleKind ~= "terminal" then return end
    if not ShipTech.IsNavy(ply) then return Deny(ply, "Nur die Navy kann Startfreigaben erteilen.") end
    local id = isstring(a.sys) and Def(a.sys) and a.sys
    if not id or not Def(id).navy then return end
    local s = Sys(id)
    s.navyClear = a.val and true or false
    if not s.navyClear then s.on = false end
    ShipTech.Log("NAVY", "Startfreigabe " .. Def(id).name .. (s.navyClear and " erteilt" or " entzogen"), ply)
    ShipTech.Chat("navy", "Startfreigabe für " .. Def(id).name .. (s.navyClear and " erteilt." or " entzogen."))
    ShipTech.MarkDirty()
end

Actions.combat = function(ply, ent, a)
    if ent.ConsoleKind ~= "terminal" then return end
    if not ShipTech.IsNavy(ply) then return Deny(ply, "Keine Berechtigung.") end
    ShipTech.State.combat = a.val and true or false
    ShipTech.Chat(a.val and "crit" or "navy", a.val and "GEFECHTSALARM! Alle Mann auf Gefechtsstation!" or "Gefechtsalarm aufgehoben.")
    ShipTech.Log("NAVY", "Gefechtsalarm " .. (a.val and "ausgelöst" or "aufgehoben"), ply)
    ShipTech.MarkDirty()
end

Actions.request_parts = function(ply, ent)
    if ent.ConsoleKind ~= "terminal" then return end
    if not ShipTech.IsNavy(ply) and not ShipTech.HasQual(ply, "freigabe") then return Deny(ply, "Keine Berechtigung.") end
    local S = ShipTech.State
    if ShipTech.LogiActive() then
        local r, err = ShipTech.RequestSupplies(ply)
        if not r then return Deny(ply, err or "Antrag konnte nicht gestellt werden.") end
        return Ok(ply, "Versorgungsantrag #" .. r.id .. " an die Logistik gestellt.")
    end
    if S.partsETA > 0 then return Deny(ply, "Eine Lieferung ist bereits unterwegs.") end
    if CurTime() < (S.partsNext or 0) then
        return Deny(ply, "Nächste Anforderung in " .. math.ceil(S.partsNext - CurTime()) .. " Sekunden möglich.")
    end
    S.partsETA = CurTime() + C.SpareParts.RequestDelay
    S.partsNext = CurTime() + C.SpareParts.RequestCooldown
    ShipTech.ChatTechs("info", "Ersatzteile angefordert – Lieferung in " .. C.SpareParts.RequestDelay .. " Sekunden.")
    ShipTech.Log("ERSATZTEILE", "Ersatzteile angefordert", ply)
    ShipTech.MarkDirty()
end

Actions.alarm = function(ply, ent, a)
    if ent.ConsoleKind ~= "terminal" then return end
    if not ShipTech.IsNavy(ply) then return Deny(ply, "Keine Berechtigung.") end
    if not ShipTech.AlarmTypes[a.id] then return end
    ShipTech.SetAlarm(a.id, a.val and true or false, ply, false, string.sub(tostring(a.info or ""), 1, 80))
end

-- Sektor-Energieverteiler instand setzen
Actions.breaker_repair = function(ply, ent)
    if ent.ConsoleKind ~= "breaker" then return end
    if not ShipTech.IsTechnician(ply) or not ShipTech.HasQual(ply, "basis") then return Deny(ply, "Dir fehlt die Grundausbildung Technik.") end
    if not NeedTool(ply) then return end
    local name = ent:GetSector()
    if not ShipTech.IsOutage(name) then return Deny(ply, "Dieser Sektor wird normal versorgt.") end
    ShipTech.StartMinigame(ply, ent, "wires", "Sicherungen: " .. name, 2, function(ok)
        if not ok then return Deny(ply, "Instandsetzung fehlgeschlagen.") end
        ShipTech.StartProgress(ply, ent, 6, "Sektor " .. name .. " wird wieder versorgt", function()
            ShipTech.RestoreSector(name, ply)
        end)
    end)
end

-- Fortbildungen vergeben / entziehen
Actions.qual_set = function(ply, ent, a)
    if ent.ConsoleKind ~= "terminal" then return end
    if not ShipTech.CanInstruct(ply) then return Deny(ply, "Nur Ausbilder können Fortbildungen vergeben.") end
    local q = ShipTech.QualById[a.qual]
    if not q then return end
    if a.qual == "ausbilder" and not ShipTech.IsAdmin(ply) then return Deny(ply, "Die Ausbilder-Berechtigung können nur Admins vergeben.") end
    local sid = tostring(a.sid or "")
    if not string.match(sid, "^STEAM_%d:%d:%d+$") then return end

    ShipTech.Quals[sid] = ShipTech.Quals[sid] or {}
    ShipTech.Quals[sid][a.qual] = a.val and true or false
    SaveQuals()

    local target = player.GetBySteamID(sid)
    local tname = IsValid(target) and target:Nick() or sid
    if IsValid(target) then
        ShipTech.ApplyQuals(target)
        ShipTech.Notify(target, "Fortbildung '" .. q.name .. "' " .. (a.val and "erhalten." or "entzogen."), a.val and 0 or 1)
    end
    ShipTech.Log("PERSONAL", "Fortbildung '" .. q.name .. "' " .. (a.val and "erteilt an " or "entzogen von ") .. tname, ply)
    ply.ST_NextData = 0
    timer.Simple(0.1, function() if IsValid(ply) then ShipTech.SendData(ply, "players") end end)
end

---------------------------------------------------------------------------
-- Netzwerk
---------------------------------------------------------------------------
net.Receive("ShipTech_Action", function(_, ply)
    if (ply.ST_NextAction or 0) > CurTime() then return end
    ply.ST_NextAction = CurTime() + 0.2

    local action = net.ReadString()
    local ent = net.ReadEntity()
    local json = net.ReadString()
    if #json > 5000 then return end

    local fn = Actions[action]
    if not fn then return end
    if not IsValid(ent) or not ent.IsShipTech then return end
    if ply:GetPos():DistToSqr(ent:GetPos()) > (C.UseDistance * 1.8) ^ 2 then
        return Deny(ply, "Du bist zu weit von der Konsole entfernt.")
    end
    local args = util.JSONToTable(json) or {}
    fn(ply, ent, args)
end)

function ShipTech.SendData(ply, kind)
    local payload
    if kind == "logs" and (ShipTech.IsTechnician(ply) or ShipTech.IsNavy(ply) or ShipTech.IsEventler(ply)) then
        payload = {}
        local logs = ShipTech.Logs
        for i = #logs, math.max(1, #logs - 200), -1 do payload[#payload + 1] = logs[i] end
    elseif kind == "reports" and (ShipTech.IsTechnician(ply) or ShipTech.IsNavy(ply)) then
        payload = {}
        local reps = ShipTech.Reports
        for i = #reps, math.max(1, #reps - 80), -1 do payload[#payload + 1] = reps[i] end
    elseif kind == "players" and ShipTech.CanInstruct(ply) then
        payload = {}
        for _, p in ipairs(player.GetAll()) do
            local quals = {}
            for q in pairs(ShipTech.GetPlayerQuals(p:SteamID())) do quals[#quals + 1] = q end
            payload[#payload + 1] = { sid = p:SteamID(), name = p:Nick(), job = team.GetName(p:Team()), quals = quals }
        end
    end
    if not payload then return end
    local data = util.Compress(util.TableToJSON(payload))
    net.Start("ShipTech_Data")
    net.WriteString(kind)
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)
    net.Send(ply)
end

net.Receive("ShipTech_RequestData", function(_, ply)
    if (ply.ST_NextData or 0) > CurTime() then return end
    ply.ST_NextData = CurTime() + 1
    ShipTech.SendData(ply, net.ReadString())
end)

---------------------------------------------------------------------------
-- Chat: Event-Befehl & Kommunikationsausfall
---------------------------------------------------------------------------
function ShipTech.CommsDown()
    local c = Sys("comms")
    if not c then return false end
    if c.health <= 0 then return true end
    if StageOf(c.health) >= 2 then return math.random() < 0.5 end
    return false
end

hook.Add("PlayerSay", "ShipTech_Commands", function(ply, text)
    local lower = string.lower(string.Trim(text))
    for _, cmd in ipairs(C.EventCommands) do
        if lower == cmd then
            if ShipTech.IsEventler(ply) then
                net.Start("ShipTech_OpenEvent")
                net.Send(ply)
            else
                Deny(ply, "Keine Berechtigung für das Event-Menü.")
            end
            return ""
        end
    end

    for _, cmd in ipairs(C.CommsBlockedCommands) do
        if lower == cmd or string.sub(lower, 1, #cmd + 1) == cmd .. " " then
            if ShipTech.CommsDown() then
                Deny(ply, "Kommunikationssystem gestört – keine Verbindung!")
                return ""
            end
            break
        end
    end
end)
