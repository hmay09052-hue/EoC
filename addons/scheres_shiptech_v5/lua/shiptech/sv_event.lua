--[[
    ShipTech – Event-System (/event)
    Eventler können gezielt Schäden, Störungen, Notfälle und Aufträge auslösen.
]]

local C = ShipTech.Config

local function Def(id) return ShipTech.SystemById[id] end
local function Sys(id) return ShipTech.State.systems[id] end
local function StageOf(h) return ShipTech.StageOf(h) end
local function Nick(ply) return (IsValid(ply) and ply:IsPlayer()) and ply:Nick() or "Ablauf" end

---------------------------------------------------------------------------
-- Stromausfälle in Sektoren
---------------------------------------------------------------------------
function ShipTech.OutageSector(name, ply)
    if name == "" or ShipTech.IsOutage(name) then return end
    table.insert(ShipTech.State.outages, name)
    ShipTech.Chat("warn", "Stromausfall in Sektor " .. name .. "!")
    ShipTech.Log("STROMAUSFALL", "Stromausfall in Sektor " .. name, ply)
    for _, b in ipairs(ShipTech.ConsoleList("breaker")) do
        if b:GetSector() == name then
            b:EmitSound(C.Sounds.Shutdown, 75, 100, 0.8)
            local ed = EffectData()
            ed:SetOrigin(b:WorldSpaceCenter())
            ed:SetMagnitude(4)
            ed:SetScale(1)
            ed:SetRadius(4)
            util.Effect("ElectricSpark", ed, true, true)
        end
    end
    ShipTech.UpdateConsolePower()
    ShipTech.MarkDirty()
end

function ShipTech.RestoreSector(name, ply)
    local list = ShipTech.State.outages
    for i = #list, 1, -1 do
        if list[i] == name then table.remove(list, i) end
    end
    ShipTech.Chat("info", "Sektor " .. name .. " wird wieder mit Energie versorgt.")
    ShipTech.Log("STROMAUSFALL", "Sektor " .. name .. " wiederhergestellt", ply)
    ShipTech.UpdateConsolePower()
    ShipTech.MarkDirty()
end

---------------------------------------------------------------------------
-- Event-Aktionen
---------------------------------------------------------------------------
local E = {}

local function ValidSys(a)
    return (isstring(a.sys) and Def(a.sys)) and a.sys or nil
end

local function EventLog(ply, text)
    ShipTech.Log("EVENT", text, ply)
end

-- optionaler Wartungsauftrag (Checkbox im Event-Menü)
local function MaybeOrder(ply, a, id, title)
    if not a.order then return end
    local t = string.Trim(tostring(a.orderTitle or ""))
    ShipTech.CreateOrder({
        sys = id,
        title = (t ~= "") and t or title,
        desc = tostring(a.orderDesc or ""),
        prio = tonumber(a.prio) or 3,
        by = "Event (" .. Nick(ply) .. ")",
    }, ply)
end

E.stage = function(ply, a)
    local id = ValidSys(a)
    if not id then return end
    local st = math.Clamp(math.floor(tonumber(a.stage) or 0), 0, 3)
    local s, def = Sys(id), Def(id)
    if st == 0 then
        ShipTech.FullRepair(id)
        ShipTech.Chat("info", def.name .. " ist wieder betriebsbereit.")
    elseif StageOf(s.health) > st then
        -- Schadensstufe verringern
        s.health = ShipTech.StageHealth[st]
        while #s.faults > (C.FaultCount[st] or 0) do table.remove(s.faults) end
    else
        ShipTech.SetHealth(id, math.min(s.health, ShipTech.StageHealth[st]), "Ereignis", ply)
    end
    EventLog(ply, def.name .. " auf Schadensstufe '" .. ShipTech.Stages[st].name .. "' gesetzt")
    if st > 0 then MaybeOrder(ply, a, id, "Schaden: " .. def.name .. " (" .. ShipTech.Stages[st].name .. ")") end
end

E.fault = function(ply, a)
    local id = ValidSys(a)
    if not id then return end
    local ft = ShipTech.FaultTypes[a.fault] and a.fault or nil
    ShipTech.AddFault(id, ft, "Ereignis", ply)
    EventLog(ply, Def(id).name .. ": Störung hinzugefügt (" .. (ft and ShipTech.FaultTypes[ft].name or "zufällig") .. ")")
    MaybeOrder(ply, a, id, "Störung: " .. Def(id).name)
end

E.shutdown = function(ply, a)
    local id = ValidSys(a)
    if not id then return end
    Sys(id).on = false
    if id == "reactor" then ShipTech.AbortReactorBoot(true) end
    ShipTech.Chat("warn", Def(id).name .. " ist offline gegangen!")
    EventLog(ply, Def(id).name .. " abgeschaltet")
end

E.overheat = function(ply, a)
    local id = ValidSys(a)
    if not id then return end
    Sys(id).heat = 100
    ShipTech.SafetyShutdown(id, "Überhitzung")
    EventLog(ply, Def(id).name .. " überhitzt (Sicherheitsabschaltung)")
    MaybeOrder(ply, a, id, "Überhitzung: " .. Def(id).name)
end

E.calib = function(ply, a)
    local id = ValidSys(a)
    if not id or not Def(id).calib then return end
    Sys(id).calib = math.min(Sys(id).calib or 100, 15)
    ShipTech.Chat("warn", Def(id).name .. ": Kalibrierung verloren – Neukalibrierung erforderlich!")
    EventLog(ply, Def(id).name .. ": Kalibrierung verloren")
    MaybeOrder(ply, a, id, "Kalibrierung: " .. Def(id).name)
end

E.maint = function(ply, a)
    local id = ValidSys(a)
    if not id then return end
    Sys(id).maint = math.Clamp(tonumber(a.value) or 100, 0, 100)
    EventLog(ply, Def(id).name .. ": Wartungszustand auf " .. math.Round(Sys(id).maint) .. " % gesetzt")
end

E.repair = function(ply, a)
    local id = ValidSys(a)
    if not id then return end
    ShipTech.FullRepair(id)
    EventLog(ply, Def(id).name .. " sofort repariert")
end

E.repair_all = function(ply)
    for _, def in ipairs(ShipTech.Systems) do ShipTech.FullRepair(def.id) end
    ShipTech.Chat("info", "Alle Systeme wurden instand gesetzt.")
    EventLog(ply, "Alle Systeme repariert")
end

E.shields_set = function(ply, a)
    if not istable(a.sectors) then return end
    for i = 1, 4 do
        ShipTech.State.shields.sectors[i] = math.Clamp(tonumber(a.sectors[i]) or 0, 0, 100)
    end
    EventLog(ply, "Schildwerte gesetzt")
end

E.shields_off = function(ply)
    Sys("shields").on = false
    ShipTech.Chat("crit", "Schilde ausgefallen!")
    EventLog(ply, "Schilde deaktiviert")
end

E.shields_weaken = function(ply, a)
    local secs = ShipTech.State.shields.sectors
    for i = 1, 4 do secs[i] = (secs[i] or 0) * 0.5 end
    ShipTech.SetHealth("shields", math.min(Sys("shields").health, 60), "Schildgenerator überlastet", ply)
    EventLog(ply, "Schilde geschwächt")
    MaybeOrder(ply, a, "shields", "Schildgenerator überlastet")
end

E.hit = function(ply, a)
    local amount = math.Clamp(tonumber(a.amount) or 20, 1, 200)
    local count = math.Clamp(math.floor(tonumber(a.count) or 1), 1, 10)
    for i = 1, count do
        timer.Simple((i - 1) * 0.6, function()
            if ShipTech.State then ShipTech.DamageShields(amount, tonumber(a.sector) or 0) end
        end)
    end
    EventLog(ply, "Beschuss simuliert (" .. count .. "x " .. amount .. ")")
end

E.comms = function(ply, a)
    ShipTech.SetHealth("comms", 0, "Kommunikationsausfall", ply)
    EventLog(ply, "Kommunikationsausfall ausgelöst")
    MaybeOrder(ply, a, "comms", "Kommunikationsausfall")
end

E.coolant = function(ply, a)
    ShipTech.AddFault("coolant", "kuehlmittel", "Kühlmittelleck", ply)
    ShipTech.SetHealth("coolant", math.min(Sys("coolant").health, 25), "Kühlmittelleck", ply)
    ShipTech.Chat("crit", "Kühlmittelleck! Temperatur der Systeme steigt.")
    EventLog(ply, "Kühlmittelproblem ausgelöst")
    MaybeOrder(ply, a, "coolant", "Kühlmittelleck beheben")
end

E.overload = function(ply, a)
    for _, def in ipairs(ShipTech.Systems) do
        local s = Sys(def.id)
        if s.on then s.heat = math.max(s.heat, 92) end
    end
    ShipTech.AddFault("power", "energiekopplung", "Energieüberlastung", ply)
    ShipTech.Chat("crit", "ENERGIEÜBERLASTUNG im gesamten Netz! Energiezufuhr sofort reduzieren!")
    EventLog(ply, "Energieüberlastung ausgelöst")
    MaybeOrder(ply, a, "power", "Energieüberlastung – Netz prüfen")
end

E.random = function(ply, a)
    local def = ShipTech.Systems[math.random(#ShipTech.Systems)]
    ShipTech.AddFault(def.id, nil, "Zufällige technische Störung", ply)
    EventLog(ply, "Zufällige Störung -> " .. def.name)
    MaybeOrder(ply, a, def.id, "Störung: " .. def.name)
end

E.outage = function(ply, a)
    local name = string.Trim(tostring(a.sector or ""))
    if name == "" then return end
    ShipTech.OutageSector(name, ply)
    EventLog(ply, "Stromausfall in Sektor " .. name)
end

E.restore = function(ply, a)
    local name = string.Trim(tostring(a.sector or ""))
    if name == "" then return end
    ShipTech.RestoreSector(name, ply)
end

E.restore_all = function(ply)
    for _, n in ipairs(table.Copy(ShipTech.State.outages)) do ShipTech.RestoreSector(n, ply) end
end

E.reactor_emergency = function(ply, a)
    local r = Sys("reactor")
    ShipTech.SetHealth("reactor", math.min(r.health, 25), "Reaktornotfall", ply)
    r.heat = math.max(r.heat, 92)
    ShipTech.SetAlarm("reactor", true, ply, false, "Ereignis")
    EventLog(ply, "Reaktornotfall ausgelöst")
    MaybeOrder(ply, a, "reactor", "REAKTORNOTFALL – sofort beheben")
end

E.alarm = function(ply, a)
    if not ShipTech.AlarmTypes[a.id] then return end
    ShipTech.SetAlarm(a.id, true, ply, false, string.sub(tostring(a.info or ""), 1, 80))
end

E.alarm_clear = function(ply, a)
    if not ShipTech.AlarmTypes[a.id] then return end
    ShipTech.SetAlarm(a.id, false, ply)
end

E.alarm_clear_all = function(ply)
    for id in pairs(table.Copy(ShipTech.State.alarms)) do ShipTech.SetAlarm(id, false, ply) end
end

E.combat = function(ply, a)
    ShipTech.State.combat = a.on and true or false
    ShipTech.Chat(a.on and "crit" or "navy", a.on and "GEFECHTSALARM! Alle Mann auf Gefechtsstation!" or "Gefechtsalarm aufgehoben.")
    EventLog(ply, "Gefechtsalarm " .. (a.on and "an" or "aus"))
end

E.parts = function(ply, a)
    if ShipTech.LogiActive() then
        local v = math.Clamp(math.floor(tonumber(a.value) or 0), 0, 999999)
        for _, res in ipairs(C.Logistik.ShownItems) do
            if GARLog.Res[res] and res ~= "hull" and res ~= "cells" then GARLog.SetStock(ShipTech.LogiLoc(), res, v) end
        end
        ShipTech.UpdateLogiStock()
        if v == 0 then ShipTech.ChatTechs("warn", "Materialmangel! Das technische Lager ist leer.") end
        EventLog(ply, "Technisches Lager (Logistik) auf " .. v .. " je Gut gesetzt")
        return
    end
    ShipTech.State.parts = math.Clamp(math.floor(tonumber(a.value) or 0), 0, 999)
    if ShipTech.State.parts == 0 then ShipTech.ChatTechs("warn", "Ersatzteilmangel! Keine Ersatzteile mehr an Bord.") end
    EventLog(ply, "Ersatzteile auf " .. ShipTech.State.parts .. " gesetzt")
end

E.randomfaults = function(ply, a)
    ShipTech.State.randomFaults = a.on and true or false
    EventLog(ply, "Zufallsstörungen " .. (a.on and "aktiviert" or "deaktiviert"))
end

E.order = function(ply, a)
    local title = string.Trim(tostring(a.title or ""))
    if #title < 3 then return ShipTech.Notify(ply, "Bitte einen Titel angeben.", 1) end
    ShipTech.CreateOrder({ sys = ValidSys(a), title = title, desc = tostring(a.desc or ""), prio = a.prio, by = "Event (" .. Nick(ply) .. ")" }, ply)
end

E.order_cancel = function(ply, a)
    for _, o in ipairs(ShipTech.State.orders) do
        if o.id == tonumber(a.id) and (o.status == "open" or o.status == "accepted") then
            o.status = "cancel"
            EventLog(ply, "Auftrag #" .. o.id .. " storniert")
        end
    end
end

E.reactor = function(ply, a)
    local r = Sys("reactor")
    if a.on then
        if not ShipTech.IsOperational(r) then ShipTech.FullRepair("reactor") end
        ShipTech.AbortReactorBoot(true)
        r.on = true
        ShipTech.Chat("reactor", "Reaktorleistung stabil.")
    else
        ShipTech.AbortReactorBoot(true)
        r.on = false
        ShipTech.Chat("crit", "Reaktor offline!")
    end
    EventLog(ply, "Reaktor sofort " .. (a.on and "online" or "offline"))
end

E.boot_all = function(ply)
    for _, def in ipairs(ShipTech.Systems) do
        local s = Sys(def.id)
        if ShipTech.IsOperational(s) then
            s.on = true
            if def.navy then s.navyClear = true end
        end
    end
    ShipTech.AbortReactorBoot(true)
    ShipTech.Chat("info", "Alle einsatzbereiten Systeme wurden hochgefahren.")
    EventLog(ply, "Alle Systeme hochgefahren")
end

E.navy_all = function(ply, a)
    for _, def in ipairs(ShipTech.Systems) do
        if def.navy then
            Sys(def.id).navyClear = a.on and true or false
            if not a.on then Sys(def.id).on = false end
        end
    end
    EventLog(ply, "Alle Navy-Freigaben " .. (a.on and "erteilt" or "entzogen"))
end

E.reset = function(ply)
    ShipTech.ResetState()
    ShipTech.Chat("event", "Schiffstechnik wurde vollständig zurückgesetzt.")
    EventLog(ply, "Kompletter Reset")
end

ShipTech.EventActions = E

---------------------------------------------------------------------------
-- Netzwerk & Befehle
---------------------------------------------------------------------------
net.Receive("ShipTech_EventAction", function(_, ply)
    if not ShipTech.IsEventler(ply) then return end
    if (ply.ST_NextEvent or 0) > CurTime() then return end
    ply.ST_NextEvent = CurTime() + 0.15

    local act = net.ReadString()
    local json = net.ReadString()
    if #json > 5000 then return end
    local fn = E[act]
    if not fn then return end

    ShipTech.SuppressAutoOrder = true
    local ok, err = pcall(fn, ply, util.JSONToTable(json) or {})
    ShipTech.SuppressAutoOrder = false
    if not ok then ErrorNoHalt("[ShipTech] Event-Fehler (" .. act .. "): " .. tostring(err) .. "\n") end
    ShipTech.MarkDirty()
end)

concommand.Add("shiptech_event", function(ply)
    if not IsValid(ply) then return end
    if not ShipTech.IsEventler(ply) then return ShipTech.Notify(ply, "Keine Berechtigung.", 1) end
    net.Start("ShipTech_OpenEvent")
    net.Send(ply)
end)
