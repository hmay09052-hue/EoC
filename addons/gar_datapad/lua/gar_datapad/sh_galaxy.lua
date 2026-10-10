--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Galaxie: Planeten, Raster, Hyperraumrouten und Regionsflaechen aus den Rohdaten aufbauen
-------------------------------------------------------------------------------------------------------------]]

GAR_DP.galaxy = GAR_DP.galaxy or {}
local G = GAR_DP.galaxy

G.CELL = 100
G.BOUNDS = { minX = -1100, maxX = 1100, minY = -1200, maxY = 900 }

-- Regionen von aussen nach innen (Zeichenreihenfolge)
G.REGIONS = {
    { id = "Unknown Regions",   name = "Unbekannte Regionen", color = Color(60, 70, 90) },
    { id = "Wild Space",        name = "Wilder Raum",         color = Color(55, 75, 95) },
    { id = "Outer Rim",         name = "Outer Rim",           color = Color(40, 80, 115) },
    { id = "Hutt Space",        name = "Hutten-Raum",         color = Color(110, 90, 50) },
    { id = "Mid Rim",           name = "Mid Rim",             color = Color(45, 95, 135) },
    { id = "Expansion Regions", name = "Expansionsregion",    color = Color(50, 110, 150) },
    { id = "Inner Rim",         name = "Inner Rim",           color = Color(60, 125, 165) },
    { id = "Colonies",          name = "Kolonien",            color = Color(70, 140, 180) },
    { id = "Core",              name = "Kernwelten",          color = Color(90, 160, 200) },
    { id = "Deep Core",         name = "Tiefkern",            color = Color(130, 190, 225) },
}

function G.GridOf(x, y)
    local col = math.floor(x / G.CELL) + 12
    local row = 9 - math.floor(y / G.CELL)
    if col < 1 or col > 26 then return "-" end
    return string.char(64 + col) .. "-" .. row
end

-- konvexe Huelle (monotone chain), gegen den Uhrzeigersinn in Weltkoordinaten
local function Hull(points)
    table.sort(points, function(a, b) return a.x < b.x or (a.x == b.x and a.y < b.y) end)
    if #points < 3 then return points end
    local function Cross(o, a, b) return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x) end
    local lower, upper = {}, {}
    for _, p in ipairs(points) do
        while #lower >= 2 and Cross(lower[#lower - 1], lower[#lower], p) <= 0 do table.remove(lower) end
        lower[#lower + 1] = p
    end
    for i = #points, 1, -1 do
        local p = points[i]
        while #upper >= 2 and Cross(upper[#upper - 1], upper[#upper], p) <= 0 do table.remove(upper) end
        upper[#upper + 1] = p
    end
    table.remove(lower)
    table.remove(upper)
    for _, p in ipairs(upper) do lower[#lower + 1] = p end
    return lower
end

-- Huelle nach aussen aufweiten und abrunden (jede Ecke wird zu einem kleinen Bogen, bleibt konvex)
local function Inflate(hull, margin)
    local out = {}
    local n = #hull
    for i = 1, n do
        local prev, cur, nxt = hull[(i - 2) % n + 1], hull[i], hull[i % n + 1]
        local a1 = math.atan2(cur.y - prev.y, cur.x - prev.x) - math.pi / 2
        local a2 = math.atan2(nxt.y - cur.y, nxt.x - cur.x) - math.pi / 2
        while a2 < a1 do a2 = a2 + math.pi * 2 end
        local steps = math.max(1, math.ceil((a2 - a1) / 0.35))
        for s = 0, steps do
            local a = a1 + (a2 - a1) * s / steps
            out[#out + 1] = { x = cur.x + math.cos(a) * margin, y = cur.y + math.sin(a) * margin }
        end
    end
    return out
end

function G.Build()
    if G.built then return end
    G.planets, G.byName, G.lanes, G.hulls = {}, {}, {}, {}

    local keySet = {}
    for _, name in ipairs(GAR_DP.Config.KeyPlanets or {}) do keySet[string.lower(name)] = true end

    local regionPoints = {}
    for line in string.gmatch(GAR_DP.galaxyRaw or "", "[^\n]+") do
        local name, x, y, region, sector, canon = string.match(line, "^(.-)|(.-)|(.-)|(.-)|(.-)|(.-)$")
        x, y = tonumber(x), tonumber(y)
        if name and x and y then
            local p = {
                name = name, x = x, y = y, region = region, sector = sector ~= "" and sector or nil,
                canon = canon == "1", key = keySet[string.lower(name)] == true, grid = G.GridOf(x, y),
            }
            G.planets[#G.planets + 1] = p
            G.byName[string.lower(name)] = G.byName[string.lower(name)] or p
            regionPoints[region] = regionPoints[region] or {}
            table.insert(regionPoints[region], { x = x, y = y })
        end
    end

    for _, lane in ipairs(GAR_DP.hyperlanesRaw or {}) do
        local last
        for _, pname in ipairs(lane.planets) do
            local p = G.byName[string.lower(pname)]
            if p then
                if last and last ~= p then G.lanes[#G.lanes + 1] = { a = last, b = p, route = lane.name } end
                last = p
            end
        end
    end

    for _, region in ipairs(G.REGIONS) do
        local pts = regionPoints[region.id]
        if pts and #pts >= 3 then
            local hull = Hull(table.Copy(pts))
            local cx, cy = 0, 0
            for _, p in ipairs(pts) do cx, cy = cx + p.x, cy + p.y end
            G.hulls[#G.hulls + 1] = { region = region, poly = Inflate(hull, 28), cx = cx / #pts, cy = cy / #pts }
        end
    end

    -- grosse Welten zuletzt zeichnen (liegen oben)
    table.sort(G.planets, function(a, b)
        if a.key ~= b.key then return not a.key end
        if a.canon ~= b.canon then return not a.canon end
        return a.name < b.name
    end)

    G.built = true
end

function G.Find(name)
    G.Build()
    return G.byName[string.lower(tostring(name or ""))]
end

function G.RegionName(id)
    for _, r in ipairs(G.REGIONS) do
        if r.id == id then return r.name end
    end
    return id or "-"
end
