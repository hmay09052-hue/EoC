--[[
    ShipTech EVA – Konfiguration (liegt in ShipTech.Config.EVA, ingame über !shiptechadmin → EVA)
    Einfaches Hüllensystem: Ankerpunkte (Schadensstellen), EVA-Spind (Luftschleuse),
    Versorgungspunkte und das Hüllenschweißgerät. Anzug & Sauerstoff = passives RP.
]]

local C = ShipTech.Config
C.EVA = {
    Enabled = true,

    -- Wer darf reparieren? Techniker-Jobs (optional zusätzlich mit Fortbildung "Außeneinsatz (EVA)")
    RequireQual = false,

    ---------------------------------------------------------------------
    -- Hüllenbrüche
    ---------------------------------------------------------------------
    BreachChance = {               -- Überschuss-Schaden durch leere Schildsektoren -> Chance auf Bruch
        { max = 30,   chance = 0.15, stage = 1 },
        { max = 90,   chance = 0.40, stage = 2 },
        { max = 9999, chance = 0.75, stage = 3 },
    },
    WorsenAfter    = 300,          -- Sekunden: offener Bruch wird eine Stufe schlimmer (0 = nie)
    SystemCap      = 70,           -- Systeme im Sektor höchstens bis hier reparierbar
    ShieldRegenMul = 0.5,          -- Schildregeneration im Sektor
    -- Systeme je Hüllensektor (1 Bug, 2 Steuerbord, 3 Heck, 4 Backbord)
    SectorSystems = {
        [1] = { "sensors", "comms" },
        [2] = { "shields", "weapons" },
        [3] = { "engines", "hyperdrive", "reactor" },
        [4] = { "power", "coolant" },
    },

    -- Reparatur je Stufe (alles alleine machbar)
    Stages = {
        [1] = { name = "Riss",    plates = 0, clear = false },
        [2] = { name = "Leck",    plates = 1, clear = true  },
        [3] = { name = "Bresche", plates = 2, clear = true  },
    },
    StepTime = { clear = 5, plate = 4, weld = 5, wires = 4 },

    ---------------------------------------------------------------------
    -- Hüllenplatten
    ---------------------------------------------------------------------
    MaxPlates          = 10,       -- so viele Platten kann man tragen
    PlatesFromLogistik = true,     -- Platten aus dem Logistik-Lager ("hull"), sonst unbegrenzt

    Sounds = {
        Warn = "buttons/blip2.wav",
        Weld = "ambient/energy/spark6.wav",
    },
}

-- Fortbildung in ShipTech (nur nötig, wenn RequireQual = true)
if not ShipTech.QualById.eva then
    local q = { id = "eva", name = "Außeneinsatz (EVA)", desc = "Arbeiten an der Außenhülle, Hüllenreparatur" }
    table.insert(ShipTech.Qualifications, q)
    ShipTech.QualById.eva = q
end

-- Ingame-Konfiguration (!shiptechadmin → EVA)
local function N(key, label, min, max) return { cat = "EVA", key = "EVA." .. key, type = "number", label = label, min = min, max = max } end
local function B(key, label) return { cat = "EVA", key = "EVA." .. key, type = "bool", label = label } end
for _, e in ipairs({
    B("Enabled", "Hüllenbrüche aktiv"),
    B("RequireQual", "Fortbildung EVA nötig"),
    N("WorsenAfter", "Bruch verschlimmert sich nach (s, 0 = nie)", 0, 3600),
    N("SystemCap", "Systeme im Bruch-Sektor max. (%)", 10, 100),
    N("ShieldRegenMul", "Schildregeneration im Bruch-Sektor", 0, 1),
    N("MaxPlates", "Hüllenplatten pro Person", 1, 30),
    B("PlatesFromLogistik", "Hüllenplatten aus dem Logistik-Lager"),
}) do
    table.insert(ShipTech.ConfigSchema, e)
end

-- Szenario-Vorlagen für den Reiter "Abläufe"
for _, sc in ipairs({
    { name = "Mikrometeoriten", desc = "Drei Risse nacheinander in verschiedenen Sektoren", steps = {
        { 0,   "eva_breach", { sector = 1, stage = 1 } },
        { 90,  "eva_breach", { sector = 2, stage = 1 } },
        { 180, "eva_breach", { sector = 4, stage = 1 } },
    } },
    { name = "Bresche am Bug", desc = "Schilde Bug auf 0, danach eine Bresche am Bug", steps = {
        { 0, "combat", { on = true } },
        { 2, "eva_shields_bow", {} },
        { 4, "eva_breach", { sector = 1, stage = 3 } },
    } },
    { name = "Antennenmast", desc = "Kommunikationsausfall – Ursache ist eine Schadensstelle am Bug", steps = {
        { 0, "comms", {} },
        { 3, "eva_breach", { sector = 1, stage = 2 } },
    } },
}) do
    table.insert(ShipTech.Scenarios, sc)
end

table.insert(ShipTech.SequenceActions, { id = "eva_breach", name = "Hüllenbruch (zufälliger Sektor)" })
