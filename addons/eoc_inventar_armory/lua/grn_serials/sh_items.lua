local WS = GRNSerials
local C = WS.Config
local INV = GRNInventory
if not (INV and isfunction(INV.RegisterItem)) then return end

-- Verbrauchsgut aus der Logistik. Kann wie jedes Inventar-Item im Shop,
-- in der Waffenkammer (Job-Loadouts) oder per Admin vergeben werden.
INV.RegisterItem(C.CleaningKitItem, {
    Name = "Reinigungsset",
    Description = "Setzt die Verschmutzung der Waffe in der Hand auf 0 (10 Sekunden, Waffe halten).",
    Type = "consumable",
    Icon = "fa-spray-can-sparkles",
    Rarity = "common",
    Stack = 5,
    Weight = 0.3,
    DropModel = "models/props_junk/garbage_metalcan001a.mdl",
    OnUse = SERVER and function(ply) return GRNSerials.StartCleaning(ply) end or nil,
})

INV.RegisterItem(C.SparePartsItem, {
    Name = "Ersatzteile",
    Description = "Für Reparaturen und Laufwechsel an der Werkbank (nur Waffenmeister).",
    Type = "material",
    Icon = "fa-gears",
    Rarity = "uncommon",
    Stack = 20,
    Weight = 0.2,
    DropModel = "models/props_c17/tools_wrench01a.mdl",
})
