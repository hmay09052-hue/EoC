--[[
    ShipTech – Kopplung an GAR Logistik
    Reparaturen, Wartung, Kalibrierung und Kühlmittel verbrauchen echtes Material aus dem Schiffslager
    der Logistik (Venator). "Ersatzteile anfordern" erzeugt einen echten Versorgungsantrag.
    Ohne GAR Logistik gilt weiter der einfache Ersatzteil-Zähler von ShipTech.
]]

local C = ShipTech.Config
local L = C.Logistik

-- Ist die Logistik aktiv? (Server & Client)
function ShipTech.LogiActive()
    return L.Enabled and GARLog ~= nil and GARLog.Res ~= nil
end

function ShipTech.LogiLoc()
    return L.Location or (GARLog and GARLog.Config and GARLog.Config.DefaultShip) or "venator"
end

local function Scale(base, f)
    local out = {}
    for res, n in pairs(base or {}) do
        local v = math.ceil(n * f)
        if v > 0 and (not GARLog or not GARLog.Res or GARLog.Res[res]) then out[res] = v end
    end
    return out
end

-- Material für eine Störung (abhängig von Störungsart und Schadensstufe)
function ShipTech.RepairItems(ftype, sev)
    return Scale(L.FaultItems[ftype] or L.FaultItems.default, L.StageFactor[sev or 0] or 1)
end

function ShipTech.MaintItems(id)
    return Scale(L.MaintItems[id] or L.MaintItems.default, 1)
end

function ShipTech.CalibItems()
    return Scale(L.CalibItems, 1)
end

function ShipTech.ResName(res)
    local r = GARLog and GARLog.Res and GARLog.Res[res]
    return r and r.name or res
end

function ShipTech.ItemsText(items)
    local parts = {}
    for res, n in SortedPairs(items or {}) do parts[#parts + 1] = n .. " " .. ShipTech.ResName(res) end
    return #parts > 0 and table.concat(parts, ", ") or "kein Material"
end

-- Bestand im Schiffslager (Client: aus dem synchronisierten Zustand)
function ShipTech.StockOf(res)
    if SERVER and ShipTech.LogiActive() then return GARLog.Stock(ShipTech.LogiLoc(), res) end
    local S = ShipTech.State
    return (S and S.logi and S.logi.stock and S.logi.stock[res]) or 0
end

-- Fehlendes Material (leer = alles da)
function ShipTech.MissingItems(items)
    local miss = {}
    for res, n in pairs(items or {}) do
        local have = ShipTech.StockOf(res)
        if have < n then miss[res] = n - have end
    end
    return miss
end

-- Kosten einer Reparatur: Logistik-Material oder (ohne Logistik) Anzahl Ersatzteile
function ShipTech.CanPayRepair(ftype, sev)
    if ShipTech.LogiActive() then
        local items = ShipTech.RepairItems(ftype, sev)
        local miss = ShipTech.MissingItems(items)
        if next(miss) then return false, "Materialmangel im Schiffslager – es fehlen: " .. ShipTech.ItemsText(miss) .. ". Nachschub über die Logistik anfordern." end
        return true, items
    end
    local need = C.PartsPerFault[sev or 0] or 0
    local S = ShipTech.State
    if (S.parts or 0) < need then return false, "Ersatzteilmangel! Benötigt: " .. need .. " – Ersatzteile über die Brücke anfordern." end
    return true, need
end

if SERVER then
    local function TakeItems(items, why, ply)
        if not next(items) then return true end
        if not GARLog.TakeStock(ShipTech.LogiLoc(), items, true) then return false end
        if GARLog.Log then
            GARLog.Log(string.format("Schiffstechnik: %s verbraucht (%s%s).", GARLog.ItemsText(items), why or "Wartung",
                IsValid(ply) and (", " .. ply:Nick()) or ""))
        end
        ShipTech.UpdateLogiStock()
        return true
    end

    -- Bucht die Kosten ab. Rückgabe: ok, Beschreibung für das Protokoll
    function ShipTech.PayRepair(ftype, sev, why, ply)
        local ok, cost = ShipTech.CanPayRepair(ftype, sev)
        if not ok then return false, cost end
        if ShipTech.LogiActive() then
            if not TakeItems(cost, why, ply) then return false, "Materialmangel im Schiffslager." end
            return true, next(cost) and ShipTech.ItemsText(cost) or nil
        end
        ShipTech.State.parts = ShipTech.State.parts - cost
        return true, cost > 0 and (cost .. " Ersatzteile") or nil
    end

    -- Wartung / Kalibrierung: Material optional (fehlt es, gibt es nur eine Warnung? -> nein: Pflicht)
    function ShipTech.PayItems(items, why, ply)
        if not ShipTech.LogiActive() or not next(items) then return true end
        local miss = ShipTech.MissingItems(items)
        if next(miss) then return false, "Materialmangel im Schiffslager – es fehlen: " .. ShipTech.ItemsText(miss) .. "." end
        if not TakeItems(items, why, ply) then return false, "Materialmangel im Schiffslager." end
        return true, ShipTech.ItemsText(items)
    end

    -- Lagerbestand der für die Technik relevanten Güter in den ShipTech-Zustand spiegeln (für Anzeigen)
    function ShipTech.UpdateLogiStock()
        local S = ShipTech.State
        if not S then return end
        if not ShipTech.LogiActive() then
            S.logi = nil
            return
        end
        local loc = ShipTech.LogiLoc()
        local l = GARLog.GetLoc(loc)
        local stock, cap = {}, {}
        for _, res in ipairs(L.ShownItems) do
            if GARLog.Res[res] then
                stock[res] = GARLog.Stock(loc, res)
                cap[res] = l and l.cap and l.cap[res] or 0
            end
        end
        S.logi = { name = GARLog.LocName(loc), stock = stock, cap = cap }
        ShipTech.MarkDirty()
    end

    local nextStock = 0
    hook.Add("ShipTech_FastTick", "ShipTech_LogiStock", function()
        if CurTime() < nextStock then return end
        nextStock = CurTime() + 4
        ShipTech.UpdateLogiStock()
    end)

    -- Versorgungsantrag an die Logistik (statt automatischer Lieferung)
    function ShipTech.RequestSupplies(ply, items, note)
        if not ShipTech.LogiActive() then return nil, "Logistik nicht aktiv." end
        local src = L.RequestFrom or "central"
        local r, err = GARLog.CreateRequest(ply, ShipTech.LogiLoc(), src, items or L.RequestItems, L.RequestPrio or 3,
            note or "Schiffstechnik: Nachschub für Reparatur und Wartung")
        if not r then return nil, err end
        ShipTech.Log("ERSATZTEILE", "Logistik-Antrag #" .. r.id .. " gestellt: " .. GARLog.ItemsText(r.it), ply)
        ShipTech.ChatTechs("info", "Versorgungsantrag #" .. r.id .. " an die Logistik gestellt – wartet auf Genehmigung.")
        return r
    end
end
