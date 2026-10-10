--[[
    ShipTech – Kühlkreisläufe, Inspektionen und Verschleiß (Server)
]]

local C = ShipTech.Config
local CC = C.Cooling


---------------------------------------------------------------------------
-- SERVER
---------------------------------------------------------------------------
local function Def(id) return ShipTech.SystemById[id] end

function ShipTech.InitCooling(S)
    S.cooling = {}
    for _, c in ipairs(ShipTech.Circuits) do
        S.cooling[c.id] = { level = 100, pressure = 40, temp = 20 }
    end
    local now = os.time()
    for id, sys in pairs(S.systems) do
        sys.insp = {}
        for i = 1, #ShipTech.InspectionsFor(id) do sys.insp[i] = now end
        sys.hours = 0
        sys.wear = 1
    end
end

-- Kühlkreisläufe & Verschleiß im schnellen Takt
hook.Add("ShipTech_FastTick", "ShipTech_Cooling", function(dt)
    local S = ShipTech.State
    if not S then return end
    if not S.cooling then ShipTech.InitCooling(S) end
    local dtm = dt / 60
    local pumpFaults = #(S.systems.coolant.faults or {})
    local pumpOn = S.systems.coolant.on and (S.systems.coolant.eff or 0) > 0

    for _, c in ipairs(ShipTech.Circuits) do
        local st = S.cooling[c.id]
        local leaks, heatSum, n = 0, 0, 0
        for _, sid in ipairs(c.systems) do
            local sys = S.systems[sid]
            if sys then
                for _, f in ipairs(sys.faults or {}) do
                    if f.t == "kuehlmittel" then leaks = leaks + 1 end
                end
                heatSum, n = heatSum + sys.heat, n + 1
            end
        end
        local drain = CC.EvaporatePerMinute + leaks * CC.LeakPerMinute + pumpFaults * CC.PumpLeakPerMinute
        st.level = math.Round(math.max(0, st.level - drain * dtm), 2)
        st.temp = math.Round(n > 0 and heatSum / n or 20, 1)
        -- Druck: steigt mit Hitze; ohne laufende Pumpen staut sich die Wärme
        local target = 25 + st.temp * 0.55 + (pumpOn and 0 or 20) + (100 - st.level) * 0.15
        st.pressure = math.Round(st.pressure + (target - st.pressure) * math.min(1, dt * 0.2), 1)

        if st.pressure >= CC.MaxPressure and not st.vented then
            st.vented = true
            st.level = math.max(0, st.level - 4)
            ShipTech.Chat("warn", c.name .. ": Überdruck – Sicherheitsventile haben Kühlmittel abgelassen!")
            ShipTech.Log("KÜHLUNG", c.name .. ": Überdruck, Sicherheitsventile geöffnet")
        elseif st.pressure < CC.MaxPressure - 10 then
            st.vented = nil
        end
        if st.level < CC.LowLevel and not st.lowWarn then
            st.lowWarn = true
            ShipTech.Chat("warn", c.name .. ": Kühlmittel niedrig (" .. math.Round(st.level) .. " %) – nachfüllen an der Kühlsystem-Steuerung!")
        elseif st.level >= CC.LowLevel + 5 then
            st.lowWarn = nil
        end
    end

    -- Verschleißfaktor je System
    local W = C.Wear
    local ratio = S.supply and S.supply.ratio or 1
    for _, def in ipairs(ShipTech.Systems) do
        local sys = S.systems[def.id]
        if sys.on then sys.hours = (sys.hours or 0) + dt / 3600 end
        local wear = 1
        wear = wear + math.floor((sys.hours or 0) / W.AgeHours) * 0.1
        if (sys.power or 0) > 1 then wear = wear + (sys.power - 1) * W.LoadFactor end
        if S.combat then wear = wear + W.CombatFactor end
        if sys.heat > W.HeatFrom then wear = wear + (sys.heat - W.HeatFrom) / 30 end
        if sys.on and ratio < 0.8 then wear = wear + W.PowerFactor end
        local cid = ShipTech.CircuitForSys(def.id)
        if S.cooling[cid] and S.cooling[cid].level < CC.LowLevel then wear = wear + W.CoolFactor end
        wear = wear + ShipTech.OverdueCount(sys, def.id) * W.OverdueFactor
        wear = wear + ShipTech.StageOf(sys.health) * W.DamageFactor
        sys.wear = math.Round(math.min(W.Max, wear), 2)
    end
end)

---------------------------------------------------------------------------
-- Aktionen: Inspektion & Kühlmittel nachfüllen
---------------------------------------------------------------------------
local Actions = ShipTech.Actions
local function Deny(ply, t) ShipTech.Notify(ply, t, 1) end
local function Ok(ply, t) ShipTech.Notify(ply, t, 0) end

Actions.inspect = function(ply, ent, a)
    local id = ent.ConsoleKind == "system" and ent.SysId
    if not id then return end
    if not ShipTech.CanWork(ply, id) then return Deny(ply, "Dir fehlt die Fortbildung für dieses System.") end
    if C.Tool.Required and not ShipTech.HasTool(ply) then return Deny(ply, "Du brauchst das Datapad in der Hand.") end
    if ShipTech.IsBurning and ShipTech.IsBurning(id) then return Deny(ply, "Die Konsole brennt – zuerst löschen!") end
    local steps = ShipTech.InspectionsFor(id)
    local idx = math.floor(tonumber(a.idx) or 0)
    local name = steps[idx]
    if not name then return end
    local def = Def(id)
    ShipTech.StartProgress(ply, ent, C.Inspection.Time, "Inspektion: " .. name, function()
        local sys = ShipTech.State.systems[id]
        sys.insp = sys.insp or {}
        sys.insp[idx] = os.time()
        sys.maint = math.min(100, sys.maint + C.Inspection.MaintGain)
        local found
        for _, f in ipairs(sys.faults or {}) do
            if not f.k and math.random() < C.Inspection.RevealChance then
                f.k = true
                found = ShipTech.FaultTypes[f.t] and ShipTech.FaultTypes[f.t].name or f.t
                break
            end
        end
        ShipTech.Log("INSPEKTION", def.name .. ": " .. name .. (found and (" – Störung entdeckt: " .. found) or " – ohne Befund"), ply)
        if found then
            Ok(ply, name .. ": Störung entdeckt (" .. found .. "). Diagnose starten, um die Reparatur zu beginnen.")
        else
            Ok(ply, name .. ": ohne Befund.")
        end
        ShipTech.MarkDirty()
    end)
end

Actions.coolant_refill = function(ply, ent, a)
    if ent.SysId ~= "coolant" then return end
    if not ShipTech.CanWork(ply, "coolant") then return Deny(ply, "Dir fehlt die Grundausbildung Technik.") end
    if C.Tool.Required and not ShipTech.HasTool(ply) then return Deny(ply, "Du brauchst das Datapad in der Hand.") end
    local cid = tostring(a.circuit or "")
    local c = ShipTech.CircuitById[cid]
    local st = ShipTech.Circuit(cid)
    if not c or not st then return end
    if st.level >= 99 then return Deny(ply, c.name .. " ist bereits voll.") end
    local step = math.min(CC.RefillStep, 100 - st.level)
    local items = { coolant = math.ceil(C.Logistik.CoolantPer10 * step / 10) }
    local miss = ShipTech.LogiActive() and ShipTech.MissingItems(items) or {}
    if next(miss) then return Deny(ply, "Kein Kühlmittel im Schiffslager – Nachschub über die Logistik anfordern.") end
    ShipTech.StartProgress(ply, ent, CC.RefillTime, "Kühlmittel nachfüllen: " .. c.name, function()
        local paid, used = ShipTech.PayItems(items, "Kühlmittel " .. c.name, ply)
        if not paid then return Deny(ply, used) end
        local cur = ShipTech.Circuit(cid)
        cur.level = math.min(100, cur.level + step)
        ShipTech.Log("KÜHLUNG", c.name .. " nachgefüllt auf " .. math.Round(cur.level) .. " %" .. (used and (" (" .. used .. ")") or ""), ply)
        Ok(ply, c.name .. ": Füllstand " .. math.Round(cur.level) .. " %.")
        ShipTech.MarkDirty()
    end)
end

-- Event: Leck in einem Kreislauf
local E = ShipTech.EventActions
if E then
    E.coolant_leak = function(ply, a)
        local cid = ShipTech.CircuitById[a.circuit or ""] and a.circuit or ShipTech.Circuits[math.random(#ShipTech.Circuits)].id
        local c = ShipTech.CircuitById[cid]
        local st = ShipTech.Circuit(cid)
        st.level = math.min(st.level, 35)
        ShipTech.AddFault(c.systems[1], "kuehlmittel", "Leck in der " .. c.name, ply)
        ShipTech.Chat("crit", "Leck in der " .. c.name .. " – Kühlmittel tritt aus!")
        ShipTech.Log("EVENT", "Kühlmittelleck: " .. c.name, ply)
    end
    E.coolant_fill = function(ply)
        for _, c in ipairs(ShipTech.Circuits) do ShipTech.State.cooling[c.id].level = 100 end
        ShipTech.Log("EVENT", "Alle Kühlkreisläufe aufgefüllt", ply)
    end
end
