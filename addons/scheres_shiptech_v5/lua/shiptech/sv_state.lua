--[[
    ShipTech – Serverseitiger Schiffszustand & Simulation
]]

local C = ShipTech.Config

file.CreateDir("shiptech")
file.CreateDir("shiptech/logs")
file.CreateDir("shiptech/maps")

ShipTech.Logs = ShipTech.Logs or {}
ShipTech.Reports = ShipTech.Reports or {}

local function Def(id) return ShipTech.SystemById[id] end
local function StageOf(h) return ShipTech.StageOf(h) end
local function HF(sys) return ShipTech.HealthFactor[StageOf(sys.health)] end

---------------------------------------------------------------------------
-- Synchronisation
---------------------------------------------------------------------------
-- Es werden nur geänderte Teile übertragen ("sys.<id>" je System, sonst die obersten Schlüssel).
local dirty = false
local lastSent = {}
function ShipTech.MarkDirty() dirty = true end

local function WriteCompressed(msg, tbl)
    local data = util.Compress(util.TableToJSON(tbl))
    if not data then return false end
    net.Start(msg)
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)
    return true
end

-- vollständiger Zustand (beim Beitritt / nach Reset)
function ShipTech.SendState(target)
    if not ShipTech.State then return end
    if not WriteCompressed("ShipTech_State", ShipTech.State) then return end
    if target then net.Send(target) else net.Broadcast() end
end

local function Parts(S)
    local parts = {}
    for k, v in pairs(S) do
        if k == "systems" then
            for id, sys in pairs(v) do parts["sys." .. id] = sys end
        else
            parts[k] = v
        end
    end
    return parts
end

function ShipTech.ResetSync()
    lastSent = {}
    for k, v in pairs(Parts(ShipTech.State)) do lastSent[k] = util.TableToJSON({ v }) end
end

timer.Create("ShipTech_Sync", 0.25, 0, function()
    if not dirty or not ShipTech.State then return end
    dirty = false
    local delta, n = {}, 0
    for k, v in pairs(Parts(ShipTech.State)) do
        local j = util.TableToJSON({ v })
        if lastSent[k] ~= j then
            lastSent[k] = j
            delta[k] = v
            n = n + 1
        end
    end
    if n == 0 then return end
    if WriteCompressed("ShipTech_Delta", delta) then net.Broadcast() end
end)

---------------------------------------------------------------------------
-- Meldungen & Protokoll
---------------------------------------------------------------------------
-- Ohne Ziel gehen Meldungen nur an Engineering, Navy und AVP (siehe C.Notify)
function ShipTech.Chat(kind, text, target)
    if not target then
        target = ShipTech.NotifyRecipients()
        if #target == 0 then return end
    end
    net.Start("ShipTech_Chat")
    net.WriteString(kind or "info")
    net.WriteString(text)
    net.Send(target)
end

function ShipTech.ChatTechs(kind, text)
    ShipTech.Chat(kind, text)
end

function ShipTech.Notify(ply, text, typ)
    if not IsValid(ply) then return end
    net.Start("ShipTech_Notify")
    net.WriteString(text)
    net.WriteUInt(typ or 0, 3)
    net.Send(ply)
end

function ShipTech.FX(kind, target)
    net.Start("ShipTech_FX")
    net.WriteString(kind)
    if target then net.Send(target) else net.Broadcast() end
end

function ShipTech.Log(kind, text, ply)
    local who = (IsValid(ply) and ply:IsPlayer()) and ply:Nick() or nil
    local entry = { t = os.time(), k = kind, m = text, p = who }
    local logs = ShipTech.Logs
    logs[#logs + 1] = entry
    while #logs > C.LogKeep do table.remove(logs, 1) end

    local line = os.date("[%H:%M:%S] ") .. "[" .. kind .. "] " .. text
    if who then line = line .. " (" .. who .. " / " .. ply:SteamID() .. ")" end
    file.Append("shiptech/logs/" .. os.date("%Y-%m-%d") .. ".txt", line .. "\n")
    hook.Run("ShipTech_Log", entry)
end

function ShipTech.LoadReports()
    local raw = file.Read("shiptech/reports.json", "DATA")
    ShipTech.Reports = (raw and util.JSONToTable(raw)) or {}
end

function ShipTech.SaveReports()
    file.Write("shiptech/reports.json", util.TableToJSON(ShipTech.Reports))
end

-- Funken & Sound an allen Konsolen eines Systems
function ShipTech.ConsoleFX(id, snd)
    for _, ent in ipairs(ShipTech.ConsoleList(nil, id)) do
        do
            if snd then
                ent:EmitSound(snd, 75, 100, 0.8)
            else
                local ed = EffectData()
                ed:SetOrigin(ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z * 0.8)))
                ed:SetMagnitude(3)
                ed:SetScale(1)
                ed:SetRadius(3)
                util.Effect("ElectricSpark", ed, true, true)
                ent:EmitSound(C.Sounds.Spark, 70, 100, 0.7)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Zustand anlegen / zurücksetzen
---------------------------------------------------------------------------
local function NewSystem(def)
    return {
        on = false, health = 100, maint = 100, calib = def.calib and 100 or nil,
        heat = 15, alloc = def.nominal or 0, faults = {}, wfSev = 0,
        coolLock = false, navyClear = not def.navy, power = 0, eff = 0,
    }
end

function ShipTech.ResetState()
    timer.Remove("ShipTech_ReactorScan")
    local S = {
        systems = {},
        backup = { active = false, charge = 100 },
        shields = { sectors = { 0, 0, 0, 0 }, focus = 0 },
        parts = C.SpareParts.Start, partsETA = 0, partsNext = 0,
        supply = { output = 0, demand = 0, ratio = 0 },
        combat = false, alarms = {}, outages = {}, sectorList = {},
        orders = {}, nextOrder = 1, randomFaults = C.RandomFaults, mods = {},
        checklist = { n = 0, by = {} },
        hyper = { phase = "idle", dest = "", t = 0 },
        sequences = {}, fires = 0,
    }
    for _, def in ipairs(ShipTech.Systems) do
        S.systems[def.id] = NewSystem(def)
    end
    if C.AutoStart then
        for _, s in pairs(S.systems) do
            s.on = true
            s.navyClear = true
            s.heat = 45
        end
        S.shields.sectors = { 100, 100, 100, 100 }
        S.systems.reactor.heat = 40
        -- Startcheckliste gilt als erledigt
        local by = {}
        for i = 1, #ShipTech.ChecklistSteps do by[i] = "Automatischer Start" end
        S.checklist = { n = #ShipTech.ChecklistSteps, by = by }
    end
    ShipTech.State = S
    if ShipTech.InitCooling then ShipTech.InitCooling(S) end
    if ShipTech.ExtinguishAll then ShipTech.ExtinguishAll() end
    if ShipTech.CancelAllSequences then ShipTech.CancelAllSequences() end
    ShipTech.ResetSync()
    ShipTech.SendState()
end

---------------------------------------------------------------------------
-- Aufträge
---------------------------------------------------------------------------
function ShipTech.CreateOrder(data, ply)
    local S = ShipTech.State
    local o = {
        id = S.nextOrder,
        sys = (data.sys and Def(data.sys)) and data.sys or nil,
        title = string.sub(data.title or "Wartungsauftrag", 1, 80),
        desc = string.sub(data.desc or "", 1, 400),
        prio = math.Clamp(math.floor(tonumber(data.prio) or 2), 1, 3),
        status = "open",
        by = data.by or ((IsValid(ply) and ply:IsPlayer()) and ply:Nick() or "Schiffssystem"),
        t = os.time(),
        auto = data.auto or nil,
    }
    S.nextOrder = S.nextOrder + 1
    S.orders[#S.orders + 1] = o

    while #S.orders > C.OrderKeep do
        local removed = false
        for i, ord in ipairs(S.orders) do
            if ord.status == "done" or ord.status == "cancel" then
                table.remove(S.orders, i)
                removed = true
                break
            end
        end
        if not removed then table.remove(S.orders, 1) end
    end

    ShipTech.Log("AUFTRAG", "Auftrag #" .. o.id .. " erstellt: " .. o.title, ply)
    ShipTech.ChatTechs("order", "#" .. o.id .. " " .. o.title .. (o.sys and (" (" .. Def(o.sys).name .. ")") or ""))
    ShipTech.MarkDirty()
    return o
end

function ShipTech.HasOpenOrder(id)
    for _, o in ipairs(ShipTech.State.orders) do
        if o.sys == id and (o.status == "open" or o.status == "accepted") then return true end
    end
    return false
end

function ShipTech.EnsureOrder(id)
    if ShipTech.SuppressAutoOrder or not C.AutoOrders then return end
    local sys = ShipTech.State.systems[id]
    if #sys.faults == 0 or ShipTech.HasOpenOrder(id) then return end
    local stage = StageOf(sys.health)
    ShipTech.CreateOrder({
        sys = id, auto = true, prio = math.max(1, stage),
        title = "Störung: " .. Def(id).name,
        desc = ShipTech.Stages[stage].name .. " – Ursache ermitteln, reparieren und Wartungsbericht erstellen.",
    })
end

function ShipTech.CompleteOrders(id, reportId)
    for _, o in ipairs(ShipTech.State.orders) do
        if o.sys == id and (o.status == "open" or o.status == "accepted") then
            o.status = "done"
            o.report = reportId
        end
    end
    ShipTech.MarkDirty()
end

---------------------------------------------------------------------------
-- Schäden & Störungen
---------------------------------------------------------------------------
local function EnsureFaults(id, stage)
    local sys, def = ShipTech.State.systems[id], Def(id)
    local need = C.FaultCount[stage] or 0
    while #sys.faults < need do
        sys.faults[#sys.faults + 1] = { t = def.faults[math.random(#def.faults)], k = false }
    end
end

-- Neue Schäden während eines laufenden Wartungsablaufs -> zurück in die Reparatur
local function ReopenRepair(sys)
    if sys.wf and sys.wf ~= "repair" then sys.wf = "repair" end
    if sys.wf then sys.wfSev = math.max(sys.wfSev or 0, StageOf(sys.health)) end
end

function ShipTech.SetHealth(id, h, reason, ply)
    local S = ShipTech.State
    local sys = S and S.systems[id]
    if not sys then return end
    local def = Def(id)
    local old = StageOf(sys.health)
    sys.health = math.Clamp(h, 0, 100)
    local new = StageOf(sys.health)

    if new > old then
        EnsureFaults(id, new)
        ReopenRepair(sys)
        local why = reason and (" (" .. reason .. ")") or ""
        if new == 3 then
            sys.on = false
            ShipTech.Chat("crit", def.name .. " ist AUSGEFALLEN!" .. why)
            ShipTech.Log("AUSFALL", def.name .. " ausgefallen" .. why, ply)
        else
            ShipTech.Chat(new >= 2 and "crit" or "warn", def.name .. ": " .. ShipTech.Stages[new].name .. why)
            ShipTech.Log("SCHADEN", def.name .. " -> " .. ShipTech.Stages[new].name .. why, ply)
        end
        if id == "reactor" and new >= 2 then ShipTech.AbortReactorBoot() end
        if new >= 2 then ShipTech.MaybeIgnite(id, C.Fire.ChanceOnCritical) end
        ShipTech.ConsoleFX(id)
        ShipTech.EnsureOrder(id)
        hook.Run("ShipTech_StageChanged", id, old, new)
    elseif new < old then
        hook.Run("ShipTech_StageChanged", id, old, new)
    end
    ShipTech.MarkDirty()
end

function ShipTech.AddFault(id, ftype, reason, ply)
    local sys, def = ShipTech.State.systems[id], Def(id)
    if not sys then return end
    if not ftype or not ShipTech.FaultTypes[ftype] then
        ftype = def.faults[math.random(#def.faults)]
    end
    sys.faults[#sys.faults + 1] = { t = ftype, k = false }
    ReopenRepair(sys)
    ShipTech.Log("STÖRUNG", def.name .. ": " .. ShipTech.FaultTypes[ftype].name .. (reason and (" – " .. reason) or ""), ply)

    if sys.health >= 75 then
        ShipTech.SetHealth(id, 70, reason, ply)
    else
        ShipTech.Chat("warn", def.name .. ": Neue Störung erkannt." .. (reason and (" (" .. reason .. ")") or ""))
        ShipTech.ConsoleFX(id)
    end
    ShipTech.EnsureOrder(id)
    ShipTech.MarkDirty()
end

function ShipTech.FullRepair(id)
    local sys, def = ShipTech.State.systems[id], Def(id)
    sys.faults = {}
    sys.health = 100
    sys.maint = 100
    if def.calib then sys.calib = 100 end
    sys.wf = nil
    sys.wfSev = 0
    sys.coolLock = false
    sys.heat = math.min(sys.heat, 40)
    ShipTech.MarkDirty()
end

function ShipTech.SafetyShutdown(id, reason)
    local sys, def = ShipTech.State.systems[id], Def(id)
    sys.on = false
    sys.coolLock = true
    sys.warnHeat = nil
    if id == "reactor" then ShipTech.AbortReactorBoot(true) end
    reason = reason or "Überhitzung"
    ShipTech.Chat("crit", "SICHERHEITSABSCHALTUNG: " .. def.name .. " – " .. reason)
    ShipTech.Log("ABSCHALTUNG", def.name .. ": Sicherheitsabschaltung (" .. reason .. ")")
    ShipTech.ConsoleFX(id, C.Sounds.Shutdown)
    ShipTech.MaybeIgnite(id, C.Fire.ChanceOnOverheat)
    ShipTech.AddFault(id, (math.random() < 0.5) and "kuehlmittel" or "energiekopplung", reason)
    ShipTech.SetHealth(id, sys.health - 20, reason)
    ShipTech.MarkDirty()
end

---------------------------------------------------------------------------
-- Reaktorstart mit Systemscan
---------------------------------------------------------------------------
function ShipTech.AbortReactorBoot(silent)
    local r = ShipTech.State.systems.reactor
    if r.booting then
        r.booting = false
        timer.Remove("ShipTech_ReactorScan")
        if not silent then ShipTech.Chat("reactor", "Systemscan abgebrochen!") end
        ShipTech.MarkDirty()
    end
end

local function ScanBar(p)
    local n = math.floor(p / 10)
    return "[" .. string.rep("|", n) .. string.rep(".", 10 - n) .. "]"
end

function ShipTech.StartReactor(ply)
    local S = ShipTech.State
    local r = S.systems.reactor
    if r.on or r.booting then return false, "Der Reaktor läuft bereits." end
    if r.wf then return false, "Der Reaktor befindet sich in Wartung." end
    if r.health <= 0 then return false, "Der Reaktor ist ausgefallen." end
    if r.coolLock then return false, "Der Reaktor kühlt nach einer Sicherheitsabschaltung noch ab." end

    r.booting = true
    ShipTech.Log("REAKTOR", "Reaktor wird hochgefahren – Systemscan gestartet", ply)
    ShipTech.Chat("reactor", "Reaktor wird hochgefahren. Systemscan gestartet ...")
    ShipTech.ConsoleFX("reactor", C.Sounds.ReactorStart)

    local steps, i = C.ReactorScanSteps, 0
    timer.Create("ShipTech_ReactorScan", C.ReactorScanDelay, #steps + 1, function()
        if not ShipTech.State or ShipTech.State.systems.reactor ~= r or not r.booting then
            timer.Remove("ShipTech_ReactorScan")
            return
        end
        i = i + 1
        if i <= #steps then
            ShipTech.Chat("reactor", "Systemscan  " .. ScanBar(steps[i]) .. " " .. steps[i] .. "%")
            return
        end

        r.booting = false
        r.on = true
        r.heat = math.max(r.heat, 35)
        ShipTech.Chat("reactor", "Reaktorscan abgeschlossen.")
        ShipTech.Chat("reactor", "Reaktorleistung stabil.")
        ShipTech.Chat("reactor", "Schilde werden hochgefahren.")
        local sh = ShipTech.State.systems.shields
        if ShipTech.IsOperational(sh) then
            sh.on = true
        else
            ShipTech.Chat("warn", "Schilde konnten nicht hochgefahren werden – Wartung erforderlich!")
        end
        ShipTech.Log("REAKTOR", "Reaktor online – Leistung stabil, Schilde werden hochgefahren")
        ShipTech.MarkDirty()
    end)
    ShipTech.MarkDirty()
    return true
end

function ShipTech.ScramReactor(ply)
    local r = ShipTech.State.systems.reactor
    if not r.on and not r.booting then return false, "Der Reaktor ist nicht aktiv." end
    ShipTech.AbortReactorBoot(true)
    r.on = false
    ShipTech.Chat("crit", "NOTABSCHALTUNG DES REAKTORS! Notstrom wird aktiviert.")
    ShipTech.Log("REAKTOR", "Notabschaltung (SCRAM) ausgelöst", ply)
    ShipTech.ConsoleFX("reactor", C.Sounds.Shutdown)
    ShipTech.MarkDirty()
    return true
end

---------------------------------------------------------------------------
-- Alarme / Notfallprotokolle
---------------------------------------------------------------------------
function ShipTech.SetAlarm(id, active, ply, auto, info)
    local A = ShipTech.State.alarms
    local def = ShipTech.AlarmTypes[id]
    if not def then return end
    if active then
        local isNew = A[id] == nil
        A[id] = { auto = auto or nil, t = os.time(), info = (info ~= "" and info) or nil }
        if isNew then
            ShipTech.Chat("crit", def.name .. ((info and info ~= "") and (" – " .. info) or "") .. " | " .. def.protocol)
            ShipTech.Log("ALARM", def.name .. " ausgelöst" .. (auto and " (automatisch)" or ""), ply)
            hook.Run("ShipTech_Alarm", id, true)
        end
    elseif A[id] then
        A[id] = nil
        ShipTech.Chat("info", def.name .. " aufgehoben.")
        ShipTech.Log("ALARM", def.name .. " aufgehoben", ply)
        hook.Run("ShipTech_Alarm", id, false)
    end
    ShipTech.MarkDirty()
end

function ShipTech.AutoAlarm(id, active, info)
    local A = ShipTech.State.alarms
    if active then
        if not A[id] then
            ShipTech.SetAlarm(id, true, nil, true, info)
        elseif A[id].auto then
            A[id].info = info
        end
    elseif A[id] and A[id].auto then
        ShipTech.SetAlarm(id, false)
    end
end

---------------------------------------------------------------------------
-- Schilde & Treffer
---------------------------------------------------------------------------
function ShipTech.HullHit(amount, sector)
    local S = ShipTech.State
    local ids = {}
    for _, def in ipairs(ShipTech.Systems) do ids[#ids + 1] = def.id end
    local hits = math.Clamp(math.ceil(amount / 30), 1, 3)
    local where = ShipTech.SectorNames[sector] or "?"
    ShipTech.Chat("crit", "Hüllentreffer im Sektor " .. where .. "!")
    for _ = 1, hits do
        local id = ids[math.random(#ids)]
        ShipTech.SetHealth(id, S.systems[id].health - amount * math.Rand(0.4, 0.9), "Treffer – Sektor " .. where)
        ShipTech.MaybeIgnite(id, C.Fire.ChanceOnHullHit)
    end
    ShipTech.FX("hit")
end

-- Öffentliche API: Schaden auf die Schilde. Überschuss trifft die Hülle und beschädigt Systeme.
function ShipTech.DamageShields(amount, sector)
    local S = ShipTech.State
    if not S then return 0 end
    local secs = S.shields.sectors
    sector = tonumber(sector)
    if not sector or sector < 1 or sector > 4 then sector = math.random(4) end
    local absorbed = math.min(secs[sector] or 0, amount)
    secs[sector] = (secs[sector] or 0) - absorbed
    local overflow = amount - absorbed
    ShipTech.FX("shieldhit")
    if overflow > 0.5 then ShipTech.HullHit(overflow, sector) end
    hook.Run("ShipTech_ShieldHit", sector, amount, overflow)
    ShipTech.MarkDirty()
    return overflow
end

---------------------------------------------------------------------------
-- Sektoren / Stromausfälle an Konsolen
---------------------------------------------------------------------------
function ShipTech.UpdateConsolePower()
    local S = ShipTech.State
    local blackout = (S.supply.output or 0) <= 0
    local gridDown = S.systems.power.health <= 0
    local outPos, names, seen = {}, {}, {}
    for _, b in ipairs(ShipTech.ConsoleList("breaker")) do
        local n = b:GetSector()
        if n ~= "" and not seen[n] then
            seen[n] = true
            names[#names + 1] = n
        end
        if ShipTech.IsOutage(n) then outPos[#outPos + 1] = b:GetPos() end
    end
    table.sort(names)
    S.sectorList = names

    local r2 = C.BreakerRadius * C.BreakerRadius
    for _, e in ipairs(ShipTech.ConsoleList()) do
        if e.ConsoleKind ~= "breaker" and e.SysId ~= "reactor" then
            local nopow = blackout
            -- ausgefallenes Energienetz: nicht-essentielle Konsolen verlieren den Strom
            if not nopow and gridDown and e.SysId and e.SysId ~= "power" then
                local def = Def(e.SysId)
                if def and not def.essential then nopow = true end
            end
            if not nopow and #outPos > 0 then
                local p = e:GetPos()
                for _, bp in ipairs(outPos) do
                    if p:DistToSqr(bp) <= r2 then nopow = true break end
                end
            end
            if e:GetNW2Bool("ST_NoPow") ~= nopow then e:SetNW2Bool("ST_NoPow", nopow) end
        end
    end
end

---------------------------------------------------------------------------
-- SIMULATION – schneller Takt (Energie, Temperatur, Schilde, Kettenreaktionen)
---------------------------------------------------------------------------
-- Annäherung, deren Stärke für 5-Sekunden-Schritte definiert ist, auf beliebige dt umrechnen
local function Approach(cur, target, perFive, dt)
    local f = 1 - (1 - perFive) ^ (dt / 5)
    return cur + (target - cur) * f
end

local flickers = {}
local nextFlickerMsg = 0

function ShipTech.FastTick(dt)
    local S = ShipTech.State
    if not S then return end
    local dtm = dt / 60
    local now = CurTime()
    local sys = S.systems

    -- Energieerzeugung
    local r = sys.reactor
    r.power, r.eff = 0, 0
    if r.on and not ShipTech.IsOperational(r) then r.on = false end
    local output = 0
    if r.on then
        r.eff = HF(r)
        r.power = 1
        output = C.PowerBudget * r.eff
    end

    local B = S.backup
    if output > 0 then
        if B.active then ShipTech.Log("ENERGIE", "Notstrombetrieb beendet – Reaktor versorgt das Schiff") end
        B.active = false
        B.charge = math.min(100, B.charge + C.Backup.RechargePerMinute * dtm)
    elseif C.Backup.Enabled and B.charge > 0 then
        if not B.active then
            ShipTech.Chat("warn", "Notstrom aktiviert – nur essentielle Systeme werden versorgt.")
            ShipTech.Log("ENERGIE", "Notstrombetrieb aktiviert")
        end
        B.active = true
        output = C.Backup.Output
    else
        if B.active then
            ShipTech.Chat("crit", "Notstrom erschöpft – Totalausfall der Energieversorgung!")
            ShipTech.Log("ENERGIE", "Notstrom erschöpft – Totalausfall")
        end
        B.active = false
    end

    -- Verbraucher
    local demand, consumers = 0, {}
    for _, def in ipairs(ShipTech.Systems) do
        local s = sys[def.id]
        if def.id ~= "reactor" then
            if s.on and not ShipTech.IsOperational(s) then s.on = false end
            if s.on and (not B.active or def.essential) then
                demand = demand + s.alloc
                consumers[#consumers + 1] = def
            end
        end
    end

    if B.active then
        B.charge = math.max(0, B.charge - C.Backup.DrainPerMinute * dtm * (0.2 + 0.8 * math.min(1, demand / math.max(C.Backup.Output, 1))))
    end

    local ratio = demand > 0 and math.min(1, output / demand) or (output > 0 and 1 or 0)
    local pw = sys.power
    local grid = (pw.on and ShipTech.IsOperational(pw)) and (0.7 + 0.3 * HF(pw)) or 0.5
    ratio = ratio * grid

    -- Kettenreaktion: beschädigtes Energienetz lässt Systeme kurz ausfallen
    if C.Chain.Enabled and #consumers > 0 and StageOf(pw.health) >= 1 then
        local chance = C.Chain.FlickerChance * dt * (StageOf(pw.health) >= 2 and 2 or 1)
        if math.random() < chance then
            local def = consumers[math.random(#consumers)]
            flickers[def.id] = now + 2
            ShipTech.ConsoleFX(def.id)
            if now > nextFlickerMsg then
                nextFlickerMsg = now + 30
                ShipTech.Chat("warn", "Energieschwankung im Netz – " .. def.name .. " kurzzeitig ohne Energie.")
            end
        end
    end

    for _, def in ipairs(ShipTech.Systems) do
        if def.id ~= "reactor" then
            local s = sys[def.id]
            local p = 0
            if s.on and output > 0 and (not B.active or def.essential) and (flickers[def.id] or 0) < now then
                p = ratio * math.Clamp(s.alloc / math.max(def.nominal, 1), 0, 1.5)
            end
            s.power = math.Round(p, 3)
            if p > 0 then
                local calibF = s.calib and (0.4 + 0.6 * s.calib / 100) or 1
                s.eff = math.Round(HF(s) * math.min(p, 1) * calibF * (1 + math.max(0, p - 1) * 0.3), 3)
            else
                s.eff = 0
            end
        end
    end
    S.supply = { output = math.Round(output, 1), demand = demand, ratio = math.Round(ratio, 3) }

    -- Temperatur, Überhitzung, Sicherheitsabschaltung
    local cool = sys.coolant
    local coolEff = (cool.eff > 0) and math.min(1, cool.eff) or 0.15
    local reactorLoad = (r.on and not B.active and output > 0) and math.min(1.5, demand / output) or 0
    for _, def in ipairs(ShipTech.Systems) do
        local s = sys[def.id]
        local load
        if def.id == "reactor" then
            load = r.on and math.max(reactorLoad, 0.5) or 0
        else
            load = s.power
        end
        local target = 15
        if load > 0 then
            target = 20 + 35 * math.min(load, 1) + math.max(0, load - 1) * 130 * (def.overloadHeat or 1) + (1 - coolEff) * 55
        end
        target = target + (ShipTech.FireHeat and ShipTech.FireHeat(def.id) or 0)
        -- leerer/niedriger Kühlkreislauf: zusätzliche Hitze
        if load > 0 and ShipTech.CircuitFactor then
            target = target + (1 - ShipTech.CircuitFactor(ShipTech.CircuitForSys(def.id))) * 45 * coolEff
        end
        local upRate = 0.12 * (C.HeatRate or 1) * (def.heatRate or 1)
        if def.id == "hyperdrive" then upRate = upRate * (C.HyperHeatFactor or 1) end
        s.heat = math.Round(Approach(s.heat, target, (target > s.heat) and math.Clamp(upRate, 0.005, 0.9) or 0.2, dt), 2)

        if s.heat >= 100 and s.on then
            ShipTech.SafetyShutdown(def.id, "Überhitzung")
        elseif s.heat >= 85 and s.on and not s.warnHeat then
            s.warnHeat = true
            ShipTech.Chat("warn", def.name .. ": Temperatur kritisch (" .. math.Round(s.heat) .. " %) – Energiezufuhr senken oder Kühlung prüfen!")
        elseif s.heat < 75 then
            s.warnHeat = nil
        end
        if s.coolLock and s.heat < 45 then
            s.coolLock = false
            ShipTech.Chat("info", def.name .. " ist abgekühlt und kann wieder hochgefahren werden.")
        end
    end

    -- Kettenreaktionen: Kühlung & Überspannung
    if C.Chain.Enabled then
        local coolDown = r.on and cool.eff <= 0
        if coolDown and not S.coolWarn then
            S.coolWarn = true
            ShipTech.Chat("crit", "Kühlsystem ohne Funktion – Reaktortemperatur steigt!")
        elseif not coolDown then
            S.coolWarn = nil
        end
        if r.on and r.heat >= C.Chain.SurgeHeat and pw.health > 0 and math.random() < C.Chain.SurgeChance * dt then
            ShipTech.Chat("crit", "Überspannung durch Reaktorüberhitzung – Energienetz beschädigt!")
            ShipTech.SetHealth("power", pw.health - 12, "Überspannung")
            ShipTech.MaybeIgnite("power", 0.3)
        end
    end

    -- Schilde (Werte in der Konfiguration gelten pro 5 Sekunden)
    local sh = sys.shields
    local sec = S.shields.sectors
    local focus = S.shields.focus or 0
    local cap = math.min(100, 100 * sh.eff)
    local k = dt / 5
    for i = 1, 4 do
        local v = sec[i] or 0
        if sh.eff <= 0 then
            v = math.max(0, v - C.ShieldDrainOff * k)
        else
            local mul, capi = 1, cap
            if focus > 0 then
                if focus == i then
                    mul, capi = 1.8, math.min(100, cap * 1.25)
                else
                    mul, capi = 0.7, cap * 0.85
                end
            end
            mul = mul * (hook.Run("ShipTech_ShieldRegenMul", i) or 1)
            if v < capi then
                v = math.min(capi, v + C.ShieldRegen * sh.eff * mul * k)
            else
                v = math.max(capi, v - 4 * k)
            end
        end
        sec[i] = math.Round(v, 1)
    end

    -- Auswirkungen auf das Gameplay
    S.mods = {
        shield    = math.Round(ShipTech.GetShieldPercent()),
        shieldCap = math.Round(cap),
        speed     = math.Round(math.min(sys.engines.eff, 1.5) * 100),
        hyper     = (sys.hyperdrive.eff >= C.Hyper.MinEfficiency and sys.hyperdrive.navyClear) and true or false,
        weapons   = math.Round(sys.weapons.eff * 100),
        accuracy  = math.Round(sys.weapons.calib or 0),
        sensors   = math.Round(sys.sensors.eff * 100),
        comms     = sys.comms.health > 0,
    }
    hook.Run("ShipTech_Modifiers", S.mods)

    -- Automatische Notfallprotokolle
    ShipTech.AutoAlarm("reactor", StageOf(r.health) >= 2 or r.heat >= 90)
    ShipTech.AutoAlarm("power", output <= 0 or (B.active and B.charge < 20) or (demand > 0 and ratio < 0.5))
    ShipTech.AutoAlarm("drive", StageOf(sys.engines.health) >= 2 or StageOf(sys.hyperdrive.health) >= 2)
    local failed = {}
    for _, def in ipairs(ShipTech.Systems) do
        if sys[def.id].health <= 0 then failed[#failed + 1] = def.name end
    end
    ShipTech.AutoAlarm("system", #failed > 0, table.concat(failed, ", "))

    -- Ersatzteillieferung
    if S.partsETA > 0 and now >= S.partsETA then
        S.partsETA = 0
        S.parts = math.min(C.SpareParts.Max, S.parts + C.SpareParts.RequestAmount)
        ShipTech.ChatTechs("info", "Ersatzteillieferung eingetroffen. Bestand: " .. S.parts)
        ShipTech.Log("ERSATZTEILE", "Lieferung eingetroffen (+" .. C.SpareParts.RequestAmount .. ")")
    end

    hook.Run("ShipTech_FastTick", dt)
    ShipTech.UpdateConsolePower()
    ShipTech.MarkDirty()
end

---------------------------------------------------------------------------
-- SIMULATION – langsamer Takt (Verschleiß, Kalibrierung, Zufallsstörungen)
---------------------------------------------------------------------------
function ShipTech.SlowTick(dt)
    local S = ShipTech.State
    if not S then return end
    local dtm = dt / 60
    for _, def in ipairs(ShipTech.Systems) do
        local id, s = def.id, S.systems[def.id]
        local wear = s.wear or 1   -- Alter, Last, Gefecht, Hitze, Energie, Kühlmittel, Inspektionen, Schäden
        s.maint = math.max(0, s.maint - C.MaintDecayPerMinute * dtm * (s.on and 1 or 0.25) * wear)
        if s.calib then
            s.calib = math.max(0, s.calib - C.CalibDecayPerMinute * dtm * (s.on and 1 or 0.2) * wear)
        end
        if s.on and s.health > 0 then
            if s.maint < C.WearBelowMaint then
                ShipTech.SetHealth(id, s.health - C.WearPerMinute * dtm * wear, "Verschleiß durch mangelnde Wartung")
            end
            if S.randomFaults and math.random() < C.RandomFaultBase * (1 + (100 - s.maint) / 25) * dtm * wear then
                ShipTech.AddFault(id, nil, "Zufällige technische Störung")
            end
        end
    end
    hook.Run("ShipTech_SlowTick", dt)
    ShipTech.MarkDirty()
end

function ShipTech.StartTimers()
    timer.Remove("ShipTech_Tick")
    timer.Create("ShipTech_FastTick", C.FastTick, 0, function()
        local ok, err = pcall(ShipTech.FastTick, C.FastTick)
        if not ok then ErrorNoHalt("[ShipTech] Fehler im schnellen Takt: " .. tostring(err) .. "\n") end
    end)
    timer.Create("ShipTech_SlowTick", C.SlowTick, 0, function()
        local ok, err = pcall(ShipTech.SlowTick, C.SlowTick)
        if not ok then ErrorNoHalt("[ShipTech] Fehler im langsamen Takt: " .. tostring(err) .. "\n") end
    end)
end
ShipTech.StartTimers()

if not ShipTech.State then
    ShipTech.ResetState()
end
ShipTech.LoadReports()
