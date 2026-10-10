--[[
    EoC Range – Standard-Disziplinen und eigene Disziplinen der Ausbilder

    Modi:
        rings     – Schüsse auf die Ringscheibe (shots), Wertung nach Ringen
        sequence  – Klappziele nacheinander (count, visible, gap), Treffer + Reaktion
        all       – alle Ziele der Bahn gleichzeitig, auf Zeit (Strafsekunden)
        moving    – Bewegtziele auf der Schiene, Stufe 1–3 als Multiplikator
        parcours  – Kill-House von Start- zu Zielzone, Zeit + Strafsekunden

    scoring: "points" (höher ist besser) oder "time" (niedriger ist besser)
]]

local C = EoCRange.Config

EoCRange.Disciplines = {}
EoCRange.DisciplineOrder = {}
EoCRange.Custom = EoCRange.Custom or {}

function EoCRange.RegisterDiscipline(def)
    def.weapons = def.weapons or { "dc15a", "dc15s", "dc17" }
    EoCRange.Disciplines[def.id] = def
    if not EoCRange.InList(EoCRange.DisciplineOrder, def.id) then
        table.insert(EoCRange.DisciplineOrder, def.id)
    end
end

EoCRange.RegisterDiscipline({
    id = "precision_25", name = "Präzision 25 m", short = "P25", mode = "rings", scoring = "points",
    shots = 10, distance = 25, max = 100, weapons = { "dc15a", "dc15s", "dc17" },
    desc = "10 Schuss auf die Ringscheibe, kein Zeitlimit. Gewertet nach Ringen (max. 100).",
})

EoCRange.RegisterDiscipline({
    id = "precision_50", name = "Präzision 50 m", short = "P50", mode = "rings", scoring = "points",
    shots = 10, distance = 50, max = 100, weapons = { "dc15a", "dc15s", "dc17" },
    desc = "10 Schuss auf die Ringscheibe in 50 m, kein Zeitlimit. Gewertet nach Ringen (max. 100).",
})

EoCRange.RegisterDiscipline({
    id = "rapid", name = "Schnellfeuer", short = "SF", mode = "sequence", scoring = "points",
    count = 8, visible = 1.5, gap = { 0.6, 1.4 }, reactionBonus = true, headDouble = true, missPenalty = true,
    badgeValue = "hits", weapons = { "dc15s", "dc17" },
    desc = "8 Klappziele nacheinander, je 1,5 s sichtbar. Gewertet nach Treffern und Reaktionszeit.",
})

EoCRange.RegisterDiscipline({
    id = "timed", name = "Zeitlauf", short = "ZL", mode = "all", scoring = "time",
    hostages = true, missPenalty = true, weapons = { "dc15a", "dc15s", "dc17" },
    desc = "Alle Ziele der Bahn so schnell wie möglich. Fehlschuss +2 s, Geisel +5 s.",
})

EoCRange.RegisterDiscipline({
    id = "moving", name = "Bewegtziel", short = "BZ", mode = "moving", scoring = "points",
    duration = 30, stages = true, headDouble = true, missPenalty = true, weapons = { "dc15a" },
    desc = "Ziele fahren auf der Schiene. 30 s, Stufe 1–3 wirkt als Multiplikator.",
})

EoCRange.RegisterDiscipline({
    id = "parcours", name = "Parcours (CQB)", short = "CQB", mode = "parcours", scoring = "time",
    hostages = true, missPenalty = true, weapons = { "dc15s", "dc17" },
    desc = "Lauf durch das Kill-House von der Start- zur Zielzone. Zeit plus Strafsekunden.",
})

EoCRange.RegisterDiscipline({
    id = "sniper", name = "Scharfschütze", short = "SS", mode = "sequence", scoring = "points",
    distances = { 100, 150, 200 }, perDistance = 2, visible = 5, gap = { 1.5, 3 },
    headDouble = true, missPenalty = true, sniper = true, weapons = { "dc15x" },
    desc = "Ziele in 100, 150 und 200 m, je 5 s sichtbar. Treffer zählen, Kopf doppelt.",
})

EoCRange.RegisterDiscipline({
    id = "squad", name = "Squad-Lauf", short = "SQ", mode = "all", scoring = "time",
    squad = true, hostages = true, missPenalty = true, weapons = { "dc15a", "dc15s", "dc17" },
    desc = "2–5 Spieler auf einer Bahn, alle Ziele, gemeinsame Zeit.",
})

---------------------------------------------------------------------------
-- Eigene Disziplinen (Ausbilder)
---------------------------------------------------------------------------
-- Rohdaten aus dem Menü -> saubere Definition
function EoCRange.NormalizeCustom(raw, id)
    raw = istable(raw) and raw or {}
    local base = raw.base == "all" and "all" or "sequence"
    local scoring = base == "all" and "time" or (raw.scoring == "time" and "time" or "points")
    local weapons = {}
    for _, g in ipairs(istable(raw.weapons) and raw.weapons or {}) do
        if C.Weapons[g] and not EoCRange.InList(weapons, g) then weapons[#weapons + 1] = g end
    end
    if #weapons == 0 then weapons = { "dc15a", "dc15s", "dc17" } end

    return {
        id = id or raw.id,
        custom = true,
        name = EoCRange.Clean(raw.name, 40) ~= "" and EoCRange.Clean(raw.name, 40) or "Eigene Disziplin",
        short = string.upper(EoCRange.Clean(raw.short, 4)),
        desc = EoCRange.Clean(raw.desc, 200),
        mode = base,
        scoring = scoring,
        count = math.Clamp(math.floor(tonumber(raw.count) or 8), 1, 40),
        visible = math.Clamp(tonumber(raw.visible) or 1.5, 0.4, 15),
        gap = { math.Clamp(tonumber(raw.gapMin) or 0.6, 0, 10), math.Clamp(tonumber(raw.gapMax) or 1.4, 0, 10) },
        order = raw.order == "fixed" and "fixed" or "random",
        hostages = raw.hostages == true,
        reactionBonus = raw.reactionBonus ~= false and base == "sequence",
        headDouble = raw.headDouble ~= false,
        missPenalty = raw.missPenalty ~= false,
        missValue = tonumber(raw.missValue),
        hostageValue = tonumber(raw.hostageValue),
        distance = math.Clamp(math.floor(tonumber(raw.distance) or 0), 0, 1000),
        timeLimit = math.Clamp(math.floor(tonumber(raw.timeLimit) or C.TimedLimit), 10, C.MaxRunTime),
        weapons = weapons,
        createdBy = EoCRange.Clean(raw.createdBy, 64),
    }
end

function EoCRange.GetDiscipline(id)
    if not id then return nil end
    return EoCRange.Disciplines[id] or EoCRange.Custom[id]
end

-- Alle Disziplinen in fester Reihenfolge (Standard, dann eigene nach Name)
function EoCRange.AllDisciplines()
    local out = {}
    for _, id in ipairs(EoCRange.DisciplineOrder) do out[#out + 1] = EoCRange.Disciplines[id] end
    local custom = {}
    for _, d in pairs(EoCRange.Custom) do custom[#custom + 1] = d end
    table.sort(custom, function(a, b) return a.name < b.name end)
    for _, d in ipairs(custom) do out[#out + 1] = d end
    return out
end

function EoCRange.ModeName(def)
    local names = { rings = "Ringscheibe", sequence = "Klappziele nacheinander", all = "Alle Ziele auf Zeit", moving = "Bewegtziele", parcours = "Parcours" }
    return names[def and def.mode] or "?"
end
