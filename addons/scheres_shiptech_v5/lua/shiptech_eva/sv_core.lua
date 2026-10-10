--[[
    ShipTech EVA – Server: Hüllenbrüche, Reparatur mit dem Hüllenschweißgerät, Spind, Event-Aktionen
    Reparatur (alleine machbar), Linksklick mit dem Schweißgerät auf den Ankerpunkt:
      1. Freilegen      (nur Leck/Bresche)          – Arbeitszeit
      2. Platte setzen  (Leck 1x, Bresche 2x)       – verbraucht eine getragene Hüllenplatte
      3. Verschweißen                               – Minigame "Schweißnaht"
      4. Leitungen      (nur bei Störung im Sektor) – Minigame "Leitungen verbinden"
]]

local C = ShipTech.Config
local EC = C.EVA
local EVA = ShipTech.EVA
local St = EVA.State

local function Deny(ply, t) ShipTech.Notify(ply, t, 1) end
local function Ok(ply, t) ShipTech.Notify(ply, t, 0) end

---------------------------------------------------------------------------
-- Synchronisation
---------------------------------------------------------------------------
local dirty = false
function EVA.MarkDirty() dirty = true end

local function Snapshot()
    local out = { breaches = {} }
    for id, b in pairs(St.breaches) do
        out.breaches[#out.breaches + 1] = {
            id = id, a = IsValid(b.anchor) and b.anchor:EntIndex() or 0, s = b.sector, g = b.stage,
            d = b.done, w = b.wires, t = b.opened, pos = IsValid(b.anchor) and b.anchor:GetPos() or b.pos,
        }
    end
    return out
end

function EVA.Send(target)
    net.Start("ShipTechEVA_State")
    net.WriteString(util.TableToJSON(Snapshot()))
    if target then net.Send(target) else net.Broadcast() end
end

timer.Create("ShipTechEVA_Sync", 0.5, 0, function()
    if dirty then
        dirty = false
        EVA.Send()
    end
end)
hook.Add("PlayerInitialSpawn", "ShipTechEVA_Sync", function(ply)
    timer.Simple(3, function() if IsValid(ply) then EVA.Send(ply) end end)
end)

function EVA.FX(kind, pos)
    net.Start("ShipTechEVA_FX")
    net.WriteString(kind)
    net.WriteVector(pos or vector_origin)
    net.Broadcast()
end

---------------------------------------------------------------------------
-- Hüllenplatten & Schweißgerät
---------------------------------------------------------------------------
local function UseLogi() return EC.PlatesFromLogistik and ShipTech.LogiActive() and GARLog and GARLog.Res and GARLog.Res.hull end

function EVA.TakePlate(ply)
    EVA.TakePlates(ply, 1)
end

function EVA.TakePlates(ply, count)
    if not EVA.CanEVA(ply) then return Deny(ply, "Nur Techniker können Hüllenplatten aufnehmen.") end
    local n = ply:GetNW2Int("ST_EVA_Plates", 0)
    local want = math.min(math.max(1, math.floor(tonumber(count) or 1)), EC.MaxPlates - n)
    if want <= 0 then return Deny(ply, "Du trägst bereits " .. EC.MaxPlates .. " Hüllenplatten (Maximum).") end
    if UseLogi() then
        local have = ShipTech.StockOf and ShipTech.StockOf("hull")
        if have then want = math.min(want, have) end
        if want <= 0 or not GARLog.TakeStock(ShipTech.LogiLoc(), { hull = want }, true) then
            return Deny(ply, "Keine Hüllenplatten im Lager – Nachschub über die Logistik anfordern.")
        end
    end
    ply:SetNW2Int("ST_EVA_Plates", n + want)
    ply:EmitSound("physics/metal/metal_sheet_impact_soft2.wav", 60)
    Ok(ply, want .. " Hüllenplatte(n) aufgenommen (" .. (n + want) .. "/" .. EC.MaxPlates .. ").")
end

function EVA.ReturnPlates(ply)
    local plates = ply:GetNW2Int("ST_EVA_Plates", 0)
    if plates <= 0 then return end
    if UseLogi() then GARLog.AddStock(ShipTech.LogiLoc(), { hull = plates }) end
    ply:SetNW2Int("ST_EVA_Plates", 0)
end

hook.Add("PlayerDeath", "ShipTechEVA_Death", function(ply) EVA.ReturnPlates(ply) end)
hook.Add("PlayerDisconnected", "ShipTechEVA_Leave", function(ply) EVA.ReturnPlates(ply) end)

---------------------------------------------------------------------------
-- Hüllenbrüche
---------------------------------------------------------------------------
local nextBreach = 1

local function FreeAnchor(sector)
    local list = {}
    for _, a in ipairs(ents.FindByClass("shiptech_eva_anchor")) do
        if (not sector or a:GetHullSector() == sector) and (a:GetBreachId() or 0) == 0 then list[#list + 1] = a end
    end
    if #list == 0 then return nil end
    return list[math.random(#list)]
end

local function SectorHasFaults(sector)
    for _, sid in ipairs(EC.SectorSystems[sector] or {}) do
        local sys = ShipTech.Sys(sid)
        if sys and #(sys.faults or {}) > 0 then return true end
    end
    return false
end

function EVA.CreateBreach(sector, stage, anchor, why)
    if not EC.Enabled then return end
    sector = math.Clamp(math.floor(tonumber(sector) or math.random(4)), 1, 4)
    stage = math.Clamp(math.floor(tonumber(stage) or 1), 1, 3)
    anchor = IsValid(anchor) and anchor or FreeAnchor(sector)
    if not IsValid(anchor) then
        ShipTech.Log("EVA", "Hüllenbruch im Sektor " .. EVA.SectorName(sector) .. " – kein freier Ankerpunkt platziert")
        return
    end
    local id = nextBreach
    nextBreach = nextBreach + 1
    local b = { id = id, anchor = anchor, pos = anchor:GetPos(), sector = sector, stage = stage, done = 0,
        opened = os.time(), worsenAt = CurTime() + EC.WorsenAfter, plates = 0, wires = SectorHasFaults(sector) }
    St.breaches[id] = b
    anchor:SetBreachId(id)
    local def = EVA.StageDef(stage)
    ShipTech.Chat("crit", "HÜLLENBRUCH im Sektor " .. EVA.SectorName(sector) .. " (" .. def.name .. ")" .. (why and (" – " .. why) or "") .. ". Techniker zur Luftschleuse!")
    ShipTech.Log("EVA", "Hüllenbruch Sektor " .. EVA.SectorName(sector) .. ": " .. def.name .. (why and (" (" .. why .. ")") or ""))
    EVA.FX("breach", anchor:GetPos())
    if C.AutoOrders then
        ShipTech.CreateOrder({ title = "Hüllenbruch Sektor " .. EVA.SectorName(sector) .. " (" .. def.name .. ")",
            desc = "Außenhülle: " .. (def.clear and "freilegen, " or "") .. (def.plates > 0 and (def.plates .. " Hüllenplatte(n) setzen, ") or "") .. "verschweißen.",
            prio = stage >= 2 and 3 or 2, by = "Schiffssystem" })
    end
    EVA.MarkDirty()
    hook.Run("ShipTechEVA_Breach", b)
    return b
end

function EVA.CloseBreach(id, ply)
    local b = St.breaches[id]
    if not b then return end
    St.breaches[id] = nil
    if IsValid(b.anchor) then b.anchor:SetBreachId(0) end
    ShipTech.Chat("info", "Hüllenbruch im Sektor " .. EVA.SectorName(b.sector) .. " abgedichtet.")
    ShipTech.Log("EVA", "Hüllenbruch Sektor " .. EVA.SectorName(b.sector) .. " repariert", ply)
    -- Wartungsbericht automatisch
    if ShipTech.Reports then
        local reports = ShipTech.Reports
        reports[#reports + 1] = {
            id = ((reports[#reports] and reports[#reports].id) or 0) + 1, t = os.time(),
            author = IsValid(ply) and ply:Nick() or "EVA-Team", cause = "Hüllenbruch Sektor " .. EVA.SectorName(b.sector) .. " (" .. EVA.StageDef(b.stage).name .. ")",
            measures = "Außenhülle: " .. (b.plates > 0 and (b.plates .. " Hüllenplatte(n) gesetzt, ") or "") .. "verschweißt" .. (b.wires and ", Leitungen geprüft" or "") .. ".",
            notes = "Automatisch erstellt (ShipTech EVA).",
        }
        if ShipTech.SaveReports then ShipTech.SaveReports() end
    end
    EVA.FX("sealed", b.pos)
    EVA.MarkDirty()
    hook.Run("ShipTechEVA_BreachClosed", b, ply)
end

function EVA.WorsenBreach(id)
    local b = St.breaches[id]
    if not b or b.stage >= 3 then return end
    b.stage = b.stage + 1
    b.done = 0
    b.worsenAt = CurTime() + EC.WorsenAfter
    ShipTech.Chat("crit", "Hüllenbruch im Sektor " .. EVA.SectorName(b.sector) .. " hat sich verschlimmert: " .. EVA.StageDef(b.stage).name .. "!")
    ShipTech.Log("EVA", "Hüllenbruch Sektor " .. EVA.SectorName(b.sector) .. " verschlimmert -> " .. EVA.StageDef(b.stage).name)
    EVA.MarkDirty()
end

-- Treffer auf leere Schilde -> Chance auf Hüllenbruch
hook.Add("ShipTech_ShieldHit", "ShipTechEVA_Breach", function(sector, amount, overflow)
    if not EC.Enabled or not overflow or overflow <= 0.5 then return end
    for _, row in ipairs(EC.BreachChance) do
        if overflow <= row.max then
            if math.random() < row.chance then EVA.CreateBreach(sector, row.stage, nil, "Treffer") end
            return
        end
    end
end)

-- Schildregeneration im Bruch-Sektor
hook.Add("ShipTech_ShieldRegenMul", "ShipTechEVA", function(sector)
    for _, b in pairs(St.breaches) do
        if b.sector == sector then return EC.ShieldRegenMul end
    end
end)

-- Auswirkungen offener Brüche (jede Sekunde)
hook.Add("ShipTech_FastTick", "ShipTechEVA_Breaches", function()
    local now = CurTime()
    local count = 0
    for id, b in pairs(St.breaches) do
        if not IsValid(b.anchor) then
            St.breaches[id] = nil
            EVA.MarkDirty()
        else
            count = count + 1
            for _, sid in ipairs(EC.SectorSystems[b.sector] or {}) do
                local sys = ShipTech.Sys(sid)
                if sys and sys.health > EC.SystemCap then sys.health = EC.SystemCap end
            end
            if EC.WorsenAfter > 0 and b.stage < 3 and now >= b.worsenAt then EVA.WorsenBreach(id) end
            if not b.wires and SectorHasFaults(b.sector) then
                b.wires = true
                EVA.MarkDirty()
            end
        end
    end
    ShipTech.AutoAlarm("breach", count > 0, count > 1 and (count .. " Schadensstellen") or nil)
end)

---------------------------------------------------------------------------
-- Reparatur (Hüllenschweißgerät: Linksklick auf den Ankerpunkt) – alleine machbar
---------------------------------------------------------------------------
local function StepDone(b, ply, stepName)
    if not St.breaches[b.id] then return end
    b.done = b.done + 1
    EVA.MarkDirty()
    local steps = EVA.Steps(b)
    ShipTech.Log("EVA", "Hüllenbruch Sektor " .. EVA.SectorName(b.sector) .. ": " .. EVA.StepNames[stepName] .. " erledigt", ply)
    if b.done >= #steps then
        EVA.CloseBreach(b.id, ply)
        Ok(ply, "Schadensstelle abgedichtet!")
    else
        Ok(ply, EVA.StepNames[stepName] .. " erledigt. Nächster Schritt: " .. EVA.StepNames[steps[b.done + 1]] .. ".")
    end
end

function EVA.WorkOnBreach(ply, anchor)
    if not EVA.CanEVA(ply) then return Deny(ply, "Nur Techniker können die Außenhülle reparieren.") end
    local b = St.breaches[anchor:GetBreachId() or 0]
    if not b then return Ok(ply, "Ankerpunkt intakt – hier ist kein Schaden.") end
    if ply.ST_Task or ShipTech.Progress[ply] then return Deny(ply, "Du arbeitest bereits.") end

    local steps = EVA.Steps(b)
    local step = steps[b.done + 1]
    if not step then return EVA.CloseBreach(b.id, ply) end
    local title = EVA.StepNames[step] .. " – Sektor " .. EVA.SectorName(b.sector)
    local t = EC.StepTime[step] or 4
    local done = function() StepDone(b, ply, step) end

    if step == "clear" then
        ShipTech.StartProgress(ply, anchor, t, title, done)
    elseif step == "plate" then
        if ply:GetNW2Int("ST_EVA_Plates", 0) <= 0 then
            return Deny(ply, "Du trägst keine Hüllenplatte – am EVA-Spind oder Versorgungspunkt aufnehmen.")
        end
        ShipTech.StartProgress(ply, anchor, t, title, function()
            if ply:GetNW2Int("ST_EVA_Plates", 0) <= 0 then return Deny(ply, "Keine Hüllenplatte mehr.") end
            ply:SetNW2Int("ST_EVA_Plates", ply:GetNW2Int("ST_EVA_Plates", 0) - 1)
            b.plates = b.plates + 1
            done()
        end)
    elseif step == "weld" then
        ShipTech.StartMinigame(ply, anchor, "weld", title, b.stage, function(ok)
            if not ok then return Deny(ply, "Die Naht ist gerissen – nochmal schweißen.") end
            ShipTech.StartProgress(ply, anchor, t, title, done)
        end)
    elseif step == "wires" then
        ShipTech.StartMinigame(ply, anchor, "wires", title, 1, function(ok)
            if not ok then return Deny(ply, "Leitungsprüfung fehlgeschlagen – nochmal versuchen.") end
            ShipTech.StartProgress(ply, anchor, t, title, done)
        end)
    end
end

---------------------------------------------------------------------------
-- Aktionen am EVA-Spind
---------------------------------------------------------------------------
local A = {}
EVA.Actions = A

A.take_welder = function(ply)
    if not EVA.CanEVA(ply) then return Deny(ply, "Nur Techniker erhalten das Hüllenschweißgerät.") end
    if ply:HasWeapon("st_eva_welder") then return Deny(ply, "Du hast bereits ein Hüllenschweißgerät.") end
    ply:Give("st_eva_welder")
    ply:SelectWeapon("st_eva_welder")
    Ok(ply, "Hüllenschweißgerät ausgegeben.")
end

A.return_welder = function(ply)
    if not ply:HasWeapon("st_eva_welder") then return end
    ply:StripWeapon("st_eva_welder")
    Ok(ply, "Hüllenschweißgerät zurückgegeben.")
end

A.take_plates = function(ply, ent, a) EVA.TakePlates(ply, a.n) end

A.return_plates = function(ply)
    if ply:GetNW2Int("ST_EVA_Plates", 0) <= 0 then return end
    EVA.ReturnPlates(ply)
    Ok(ply, "Hüllenplatten zurück ins Lager gelegt.")
end

net.Receive("ShipTechEVA_Action", function(_, ply)
    if (ply.STEVA_NextAct or 0) > CurTime() then return end
    ply.STEVA_NextAct = CurTime() + 0.25
    local act = net.ReadString()
    local ent = net.ReadEntity()
    local args = util.JSONToTable(net.ReadString()) or {}
    local fn = A[act]
    if not fn or not IsValid(ent) or not ent.IsShipTechEVA then return end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 200 * 200 then return Deny(ply, "Zu weit entfernt.") end
    fn(ply, ent, args)
end)

---------------------------------------------------------------------------
-- Event-Aktionen (/event → Reiter "Außenhülle" und Abläufe)
---------------------------------------------------------------------------
local E = ShipTech.EventActions
if E then
    local function Log(ply, text) ShipTech.Log("EVENT", text, ply) end

    E.eva_breach = function(ply, a)
        local sector = tonumber(a.sector)
        if not sector or sector < 1 then sector = math.random(4) end
        local stage = tonumber(a.stage) or math.random(1, 2)
        local b = EVA.CreateBreach(sector, stage, nil, "Ereignis")
        if not b and IsValid(ply) then ShipTech.Notify(ply, "Kein freier Ankerpunkt im Sektor " .. EVA.SectorName(sector) .. " platziert.", 1) end
        Log(ply, "Hüllenbruch ausgelöst: Sektor " .. EVA.SectorName(sector))
    end

    E.eva_repair_all = function(ply)
        for id in pairs(table.Copy(St.breaches)) do EVA.CloseBreach(id) end
        Log(ply, "Alle Hüllenbrüche sofort repariert")
    end

    E.eva_worsen_all = function(ply)
        for id in pairs(St.breaches) do EVA.WorsenBreach(id) end
        Log(ply, "Alle Hüllenbrüche verschlimmert")
    end

    E.eva_shields_bow = function(ply)
        ShipTech.State.shields.sectors[1] = 0
        ShipTech.MarkDirty()
        Log(ply, "Schilde Bug auf 0")
    end
end
