--[[
    ShipTech – Kühlkreisläufe, Inspektionen und Verschleißfaktoren
    5 Kühlkreisläufe (Reaktor, Triebwerke, Waffen/Türme, Hyperantrieb, Schiff) mit Füllstand und Druck.
    Inspektionsschritte je System (z. B. Reaktorkern, Reaktordruck, Sicherheitsventile).
    Verschleiß hängt ab von: Wartung, Alter (Betriebsstunden), Last, Gefechtsschäden, Hitze,
    Energieversorgung, Kühlmittel und überfälligen Inspektionen.
]]

local C = ShipTech.Config
local CC = C.Cooling

ShipTech.CircuitById = {}
ShipTech.CircuitOfSys = {}
for _, c in ipairs(ShipTech.Circuits) do
    ShipTech.CircuitById[c.id] = c
    for _, sid in ipairs(c.systems) do ShipTech.CircuitOfSys[sid] = c.id end
end

function ShipTech.Circuit(cid)
    local S = ShipTech.State
    return S and S.cooling and S.cooling[cid]
end

function ShipTech.CircuitForSys(sysId)
    return ShipTech.CircuitOfSys[sysId] or "ship"
end

-- grobe Stufe für die Menü-Aktualisierung (nicht bei jedem Zehntelprozent neu bauen)
function ShipTech.CircuitBucket(sysId)
    local c = ShipTech.Circuit(ShipTech.CircuitForSys(sysId))
    return c and math.floor((c.level or 0) / 10) or 0
end

-- Kühlleistung eines Kreislaufs (0..1): unter dem Mindestfüllstand bricht sie stark ein
function ShipTech.CircuitFactor(cid)
    local c = ShipTech.Circuit(cid)
    if not c then return 1 end
    local lvl, low = math.Clamp(c.level or 100, 0, 100), CC.LowLevel
    if lvl >= low then return 0.6 + 0.4 * (lvl - low) / math.max(1, 100 - low) end
    return 0.6 * lvl / math.max(1, low)
end

function ShipTech.InspectionsFor(id)
    return ShipTech.Inspections[id] or {}
end

function ShipTech.OverdueCount(sys, id)
    local n = 0
    local now = os.time()
    for i = 1, #ShipTech.InspectionsFor(id) do
        local t = sys.insp and sys.insp[i] or 0
        if t <= 0 or now - t > C.Inspection.Overdue then n = n + 1 end
    end
    return n
end
