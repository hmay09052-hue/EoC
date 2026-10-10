--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Galaxiekarte
    Echte Koordinaten (swgalaxymap), Regionen, Raster A-V / 1-21, Hyperraumrouten, Suche,
    Lage der Klonkriege (Republik / Separatisten / umkaempft / Einsatzort), ab GalaxyEditLevel bearbeitbar.
    Bedienung: Ziehen = verschieben, Mausrad = zoomen, Klick = Planet auswaehlen.
-------------------------------------------------------------------------------------------------------------]]

local D = GAR_DP.ui
local S = D.S
local CFG = GAR_DP.Config
local G = GAR_DP.galaxy

local function StatusData(id) return id and GAR_DP.ById(CFG.GalaxyStatus, id) or nil end
local function StateOf(p) return GAR_DP.galaxyState[p.name] end

-- Sterne im Hintergrund (fest, Bildschirmkoordinaten 0..1)
local STARS = {}
for i = 1, 260 do STARS[i] = { math.Rand(0, 1), math.Rand(0, 1), math.Rand(0.2, 1) } end

local MAP = {}

function MAP:Init()
    G.Build()
    self.camX, self.camY = 0, -150
    self.zoom = 0.3
    self.showLanes, self.showGrid, self.canonOnly, self.showStatus = true, true, false, true
    self:SetCursor("sizeall")
end

function MAP:FitZoom(w, h)
    return math.min(w / 2300, h / 2150)
end

function MAP:PerformLayout(w, h)
    if not self.fitted and w > 0 and h > 0 then self.fitted = true self.zoom = self:FitZoom(w, h) end
    if self.OnLayout then self:OnLayout(w, h) end
end

function MAP:ToScreen(x, y)
    local w, h = self:GetSize()
    return w / 2 + (x - self.camX) * self.zoom, h / 2 - (y - self.camY) * self.zoom
end

function MAP:ToWorld(sx, sy)
    local w, h = self:GetSize()
    return self.camX + (sx - w / 2) / self.zoom, self.camY - (sy - h / 2) / self.zoom
end

function MAP:Visible(p)
    if self.canonOnly and not p.canon and not p.key and not StateOf(p) then return false end
    return true
end

function MAP:PlanetAt(mx, my, radius)
    local best, bestD = nil, (radius or S(10)) ^ 2
    for _, p in ipairs(G.planets) do
        if self:Visible(p) then
            local sx, sy = self:ToScreen(p.x, p.y)
            local d = (sx - mx) ^ 2 + (sy - my) ^ 2
            if d < bestD then best, bestD = p, d end
        end
    end
    return best
end

function MAP:FocusPlanet(p, zoomIn)
    self.targetX, self.targetY = p.x, p.y
    if zoomIn then self.targetZoom = math.max(self.zoom, 1.6) end
    self.selected = p
    if self.OnSelect then self:OnSelect(p) end
end

function MAP:SetZoom(z, sx, sy)
    local w, h = self:GetSize()
    sx, sy = sx or w / 2, sy or h / 2
    local wx, wy = self:ToWorld(sx, sy)
    self.zoom = math.Clamp(z, self:FitZoom(w, h) * 0.6, 12)
    -- Punkt unter der Maus bleibt stehen
    self.camX = wx - (sx - w / 2) / self.zoom
    self.camY = wy + (sy - h / 2) / self.zoom
end

function MAP:OnMouseWheeled(delta)
    local mx, my = self:CursorPos()
    self.targetZoom = nil
    self:SetZoom(self.zoom * (delta > 0 and 1.2 or 1 / 1.2), mx, my)
    return true
end

function MAP:OnMousePressed(code)
    if code ~= MOUSE_LEFT then return end
    local mx, my = self:CursorPos()
    self.drag = { mx = mx, my = my, cx = self.camX, cy = self.camY, moved = false }
    self.targetX, self.targetY, self.targetZoom = nil, nil, nil
    self:MouseCapture(true)
end

function MAP:OnMouseReleased(code)
    if code ~= MOUSE_LEFT then return end
    self:MouseCapture(false)
    local drag = self.drag
    self.drag = nil
    if drag and not drag.moved then
        local mx, my = self:CursorPos()
        local p = self:PlanetAt(mx, my, S(12))
        if p then
            D.Sound("click")
            self.selected = p
            if self.OnSelect then self:OnSelect(p) end
        end
    end
end

function MAP:Think()
    if self.drag then
        local mx, my = self:CursorPos()
        local dx, dy = mx - self.drag.mx, my - self.drag.my
        if math.abs(dx) + math.abs(dy) > 4 then self.drag.moved = true end
        self.camX = self.drag.cx - dx / self.zoom
        self.camY = self.drag.cy + dy / self.zoom
    end
    if self.targetX then
        self.camX = D.Approach(self.camX, self.targetX, 6)
        self.camY = D.Approach(self.camY, self.targetY, 6)
        if math.abs(self.camX - self.targetX) < 0.5 and math.abs(self.camY - self.targetY) < 0.5 then self.targetX = nil end
    end
    if self.targetZoom then
        self.zoom = D.Approach(self.zoom, self.targetZoom, 6)
        if math.abs(self.zoom - self.targetZoom) < 0.01 then self.targetZoom = nil end
    end
    local mx, my = self:CursorPos()
    self.hover = (not self.drag and self:IsHovered()) and self:PlanetAt(mx, my, S(9)) or nil
end

local function PlanetColor(p)
    if p.key then return Color(236, 233, 224) end
    if p.canon then return Color(170, 205, 230) end
    return Color(110, 140, 165)
end

function MAP:Paint(w, h)
    local zoom = self.zoom or 1
    D.Box(0, 0, w, h, Color(3, 6, 12, 255))
    for _, st in ipairs(STARS) do
        surface.SetDrawColor(255, 255, 255, 40 * st[3])
        surface.DrawRect(st[1] * w, st[2] * h, 1, 1)
    end

    -- Regionen (von aussen nach innen)
    draw.NoTexture()
    for _, hull in ipairs(G.hulls) do
        local pts = {}
        for i, pt in ipairs(hull.poly) do
            local sx, sy = self:ToScreen(pt.x, pt.y)
            pts[i] = { x = sx, y = sy }
        end
        local col = hull.region.color
        surface.SetDrawColor(col.r, col.g, col.b, 34)
        surface.DrawPoly(pts)
        surface.SetDrawColor(col.r, col.g, col.b, 70)
        for i = 1, #pts do
            local a, b = pts[i], pts[i % #pts + 1]
            surface.DrawLine(a.x, a.y, b.x, b.y)
        end
    end

    -- Raster
    if self.showGrid then
        local B = G.BOUNDS
        surface.SetDrawColor(255, 255, 255, 14)
        for gx = B.minX, B.maxX, G.CELL do
            local sx = self:ToScreen(gx, 0)
            local _, sy1 = self:ToScreen(0, B.maxY)
            local _, sy2 = self:ToScreen(0, B.minY)
            surface.DrawLine(sx, sy1, sx, sy2)
        end
        for gy = B.minY, B.maxY, G.CELL do
            local _, sy = self:ToScreen(0, gy)
            local sx1 = self:ToScreen(B.minX, 0)
            local sx2 = self:ToScreen(B.maxX, 0)
            surface.DrawLine(sx1, sy, sx2, sy)
        end
        if zoom * G.CELL > S(26) then
            for col = 1, 22 do
                local cx = self:ToScreen(B.minX + (col - 0.5) * G.CELL, 0)
                if cx > 0 and cx < w then D.Text(string.char(64 + col), "gdp.map.small", cx, S(4), Color(255, 255, 255, 60), TEXT_ALIGN_CENTER) end
            end
            for row = 1, 21 do
                local _, cy = self:ToScreen(0, B.maxY - (row - 0.5) * G.CELL)
                if cy > 0 and cy < h then D.Text(tostring(row), "gdp.map.small", S(4), cy, Color(255, 255, 255, 60), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
            end
        end
    end

    -- Regionsnamen (nur weit herausgezoomt)
    if zoom < 0.9 then
        for _, hull in ipairs(G.hulls) do
            local sx, sy = self:ToScreen(hull.cx, hull.cy)
            local a = math.Clamp((0.9 - zoom) * 400, 0, 90)
            D.Text(string.upper(hull.region.name), "gdp.map.region", sx, sy, Color(200, 225, 255, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Hyperraumrouten
    if self.showLanes then
        local accent = D.Accent()
        surface.SetDrawColor(accent.r, accent.g, accent.b, 70)
        for _, lane in ipairs(G.lanes) do
            local ax, ay = self:ToScreen(lane.a.x, lane.a.y)
            local bx, by = self:ToScreen(lane.b.x, lane.b.y)
            if not ((ax < 0 and bx < 0) or (ax > w and bx > w) or (ay < 0 and by < 0) or (ay > h and by > h)) then
                surface.DrawLine(ax, ay, bx, by)
            end
        end
    end

    -- Planeten
    local labels = {}
    local pulse = 0.5 + 0.5 * math.sin(RealTime() * 4)
    local dotScale = math.Clamp(zoom / 0.5, 0.7, 2.2)
    for _, p in ipairs(G.planets) do
        if self:Visible(p) then
            local sx, sy = self:ToScreen(p.x, p.y)
            if sx > -20 and sx < w + 20 and sy > -20 and sy < h + 20 then
                local state = self.showStatus and StateOf(p)
                local st = state and StatusData(state.status)
                local r = (p.key and 3 or p.canon and 2 or 1.2) * dotScale
                local col = PlanetColor(p)
                if st then
                    col = st.color
                    local rr = r + S(4) + (st.id == "einsatz" and pulse * S(4) or 0)
                    D.Ring(sx, sy, rr, D.Alpha(st.color, st.id == "einsatz" and 120 + pulse * 135 or 170), 1, 16)
                end
                if r < 1.6 then
                    surface.SetDrawColor(col)
                    surface.DrawRect(sx - 1, sy - 1, 2, 2)
                else
                    D.Circle(sx, sy, r, col, 10)
                end
                local wantLabel = p.key or st or (p.canon and zoom > 1.1) or zoom > 3.2
                if wantLabel then labels[#labels + 1] = { p = p, x = sx, y = sy, r = r, col = st and st.color or col } end
            end
        end
    end

    -- Beschriftungen (einfache Ueberlappungspruefung)
    local placed = {}
    for i = #labels, 1, -1 do
        local l = labels[i]
        local font = l.p.key and "gdp.map" or "gdp.map.small"
        local tw, th = D.TextSize(l.p.name, font)
        local lx, ly = l.x + l.r + S(4), l.y - th / 2
        local free = true
        for _, b in ipairs(placed) do
            if lx < b[3] and lx + tw > b[1] and ly < b[4] and ly + th > b[2] then free = false break end
        end
        if free or l.p.key then
            placed[#placed + 1] = { lx, ly, lx + tw, ly + th }
            draw.SimpleTextOutlined(l.p.name, font, lx, ly, D.Alpha(l.col, l.p.key and 255 or 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 200))
        end
    end

    -- Auswahl / Hover
    local function Mark(p, col, big)
        local sx, sy = self:ToScreen(p.x, p.y)
        local r = big and S(14) + pulse * S(3) or S(9)
        D.Ring(sx, sy, r, col, S(2), 24)
        if big then
            surface.SetDrawColor(col)
            surface.DrawLine(sx - r - S(10), sy, sx - r - S(2), sy)
            surface.DrawLine(sx + r + S(2), sy, sx + r + S(10), sy)
            surface.DrawLine(sx, sy - r - S(10), sx, sy - r - S(2))
            surface.DrawLine(sx, sy + r + S(2), sx, sy + r + S(10))
        end
    end
    if self.selected then Mark(self.selected, D.Accent(), true) end
    if self.hover and self.hover ~= self.selected then
        Mark(self.hover, Color(255, 255, 255, 180), false)
        local mx, my = self:CursorPos()
        local text = self.hover.name .. "  ·  " .. self.hover.grid
        local tw, th = D.TextSize(text, "gdp.small.b")
        D.Box(mx + S(14), my + S(10), tw + S(12), th + S(6), Color(0, 0, 0, 220))
        D.Outline(mx + S(14), my + S(10), tw + S(12), th + S(6), D.Accent(150))
        D.Text(text, "gdp.small.b", mx + S(20), my + S(13), D.col.text)
    end

    D.Outline(0, 0, w, h, D.col.line2)
end

vgui.Register("gdp.GalaxyMap", MAP, "DPanel")

---------------------------------------------------------------------------------------------------------------
-- Infokarte rechts
---------------------------------------------------------------------------------------------------------------
local function BuildInfo(info, map, p)
    local panel = info.content
    panel:Clear()
    info:SetVisible(p ~= nil)
    if not p then return end
    local canEdit = GAR_DP.Clearance(LocalPlayer()) >= CFG.GalaxyEditLevel

    local routes = {}
    local seen = {}
    for _, lane in ipairs(G.lanes) do
        if (lane.a == p or lane.b == p) and not seen[lane.route] then
            seen[lane.route] = true
            routes[#routes + 1] = lane.route
        end
    end

    local info = vgui.Create("DPanel", panel)
    info:Dock(TOP)
    info:SetTall(S(250))
    info.Paint = function(_, w, h)
        local state = StateOf(p)
        local st = state and StatusData(state.status)
        D.TextFit(p.name, "gdp.h1", 0, -S(4), D.col.text, w - S(30))
        D.Aurebesh(p.name, "gdp.aure", S(1), S(34), D.Alpha(D.col.dim, 110), nil, nil, w)
        local y = S(56)
        if st then
            D.Chip(st.name, 0, y, st.color, D.Alpha(st.color, 30), D.Alpha(st.color, 170))
        else
            D.Chip("Keine Lagedaten", 0, y, D.col.muted, D.col.panel3)
        end
        if p.canon then
            local cw = D.ChipSize("Kanon")
            D.Chip("Kanon", w - cw, y, D.col.dim, D.col.panel3)
        end
        y = y + S(30)
        y = y + D.KeyValue("Region", G.RegionName(p.region), 0, y, w)
        y = y + D.KeyValue("Sektor", p.sector or "-", 0, y, w)
        local half = (w - S(10)) / 2
        D.KeyValue("Raster", p.grid, 0, y, half)
        y = y + D.KeyValue("Koordinaten", string.format("%.0f / %.0f", p.x, p.y), half + S(10), y, half)
        if #routes > 0 then
            D.Text("HYPERRAUMROUTEN", "gdp.tiny.b", 0, y, D.col.muted)
            D.DrawWrapped(table.concat(routes, ", "), "gdp.small", 0, y + S(14), w, D.Accent(), 2)
        end
    end

    local stateBox = vgui.Create("DPanel", panel)
    stateBox:Dock(TOP)
    stateBox:SetTall(S(70))
    stateBox:DockMargin(0, S(4), 0, 0)
    stateBox.Paint = function(_, w, h)
        local state = StateOf(p)
        D.Box(0, 0, w, 1, D.col.line2)
        D.Text("LAGEBERICHT", "gdp.tiny.b", 0, S(6), D.col.muted)
        if state and state.note and state.note ~= "" then
            D.DrawWrapped(state.note, "gdp.small", 0, S(22), w, D.col.text, 2)
        else
            D.Text("Keine Anmerkungen.", "gdp.small", 0, S(22), D.col.muted)
        end
        if state and state.by then
            D.TextFit((state.by or "") .. "  ·  " .. GAR_DP.FormatDate(state.at, true), "gdp.tiny", 0, h - S(2), D.col.muted, w, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        end
    end

    if canEdit then
        local state = StateOf(p) or {}
        local statusField = D.Field(panel, "Lage setzen", S(30))
        statusField:DockMargin(0, S(8), 0, S(6))
        local combo = D.Combo(statusField)
        combo:Dock(FILL)
        combo:AddChoice("Keine Lagedaten", "", (state.status or "") == "")
        for _, st in ipairs(CFG.GalaxyStatus) do combo:AddChoice(st.name, st.id, st.id == state.status, st.color) end
        local note = D.Entry(panel, "Anmerkung (z.B. 212th im Einsatz, Droidenfabrik)", state.note)
        note:Dock(TOP)
        note:SetTall(S(32))
        note:DockMargin(0, 0, 0, S(6))
        local save = D.Button(panel, "Lage speichern", "primary", function()
            GAR_DP.Request("galaxy_set", { planet = p.name, status = combo:GetSelectedData() or "", note = note:GetValue() }, function(res)
                if res then GAR_DP.Notify("Lage für " .. p.name .. " aktualisiert.", "info") end
            end)
        end)
        save:Dock(TOP)
        save:SetTall(S(34))
    end
end

---------------------------------------------------------------------------------------------------------------
-- App
---------------------------------------------------------------------------------------------------------------
GAR_DP.RegisterApp({
    id = "galaxy",
    short = "Karte",
    name = "Galaxiekarte",
    desc = "Die Galaxis mit über 2.000 Systemen, Hyperraumrouten und der aktuellen Lage der Klonkriege.",
    icon = "planet",
    order = 6,
    build = function(parent, tablet, opts)
        local map = vgui.Create("gdp.GalaxyMap", parent)
        map:Dock(FILL)

        -- Infokarte (rechts ueber der Karte)
        local info = vgui.Create("DPanel", map)
        info:SetVisible(false)
        info:DockPadding(S(14), S(30), S(14), S(12))
        info.Paint = function(_, w, h) D.Frame(0, 0, w, h, { fill = Color(3, 9, 15, 240), title = "Systemdaten" }) end
        info.content = vgui.Create("DPanel", info)
        info.content:Dock(FILL)
        info.content.Paint = nil
        local closeInfo = D.Button(info, "", "icon", function() map.selected = nil info:SetVisible(false) tablet:SetBackHandler(nil) end)
        closeInfo:SetIcon("close")

        map.OnSelect = function(_, p)
            BuildInfo(info, map, p)
            -- Zurueck schliesst zuerst die Systemdaten
            tablet:SetBackHandler(function()
                if not IsValid(info) or not info:IsVisible() then return false end
                map.selected = nil
                info:SetVisible(false)
            end)
        end
        hook.Add("gar_datapad_galaxy", info, function() if map.selected then BuildInfo(info, map, map.selected) end end)

        -- Suche
        local search = D.Entry(map, "Planet suchen…")
        local results = vgui.Create("DPanel", map)
        results:SetVisible(false)
        results.Paint = function(_, w, h)
            D.Box(0, 0, w, h, Color(3, 9, 15, 250))
            D.Outline(0, 0, w, h, D.Accent(130))
            D.Brackets(0, 0, w, h, D.Accent(), S(8), S(2))
        end
        search.OnValueChange = function(_, value)
            results:Clear()
            local q = string.lower(string.Trim(value or ""))
            if #q < 2 then results:SetVisible(false) return end
            local found = {}
            for _, p in ipairs(G.planets) do
                local n = string.lower(p.name)
                if string.find(n, q, 1, true) then
                    found[#found + 1] = { p = p, starts = string.sub(n, 1, #q) == q }
                end
            end
            table.sort(found, function(a, b)
                if a.starts ~= b.starts then return a.starts end
                if a.p.key ~= b.p.key then return a.p.key end
                if a.p.canon ~= b.p.canon then return a.p.canon end
                return a.p.name < b.p.name
            end)
            for i = 1, math.min(8, #found) do
                local p = found[i].p
                local row = vgui.Create("DButton", results)
                row:Dock(TOP)
                row:SetTall(S(28))
                row:SetText("")
                row.Paint = function(s, w, h)
                    if s:IsHovered() then D.Box(0, 0, w, h, D.Accent(40)) end
                    D.TextFit(p.name, "gdp.small.b", S(8), h / 2, D.col.text, w * 0.55, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    D.Text(p.grid .. "  ·  " .. G.RegionName(p.region), "gdp.tiny", w - S(8), h / 2, D.col.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    return true
                end
                row.DoClick = function()
                    D.Sound("click")
                    if p.canon == false and map.canonOnly then map.canonOnly = false end
                    map:FocusPlanet(p, true)
                    results:SetVisible(false)
                    search:SetValue("")
                    search:KillFocus()
                end
            end
            results:SetVisible(#found > 0)
            results:SetTall(math.min(8, #found) * S(28) + S(4))
            results:DockPadding(S(2), S(2), S(2), S(2))
        end

        -- Schalter
        local toggles = {}
        local function Toggle(label, key)
            local b = D.Button(map, label, "select", function(s)
                map[key] = not map[key]
                s:SetSelected(map[key])
            end)
            b:SetFont("gdp.h4")
            b:SetSelected(map[key])
            toggles[#toggles + 1] = b
            return b
        end
        Toggle("Routen", "showLanes")
        Toggle("Raster", "showGrid")
        Toggle("Lage", "showStatus")
        Toggle("Nur Kanon", "canonOnly")

        local zoomIn = D.Button(map, "", "default", function() map.targetZoom = nil map:SetZoom(map.zoom * 1.4) end)
        zoomIn:SetIcon("plus")
        local zoomOut = D.Button(map, "", "default", function() map.targetZoom = nil map:SetZoom(map.zoom / 1.4) end)
        zoomOut:SetIcon("minus")
        local home = D.Button(map, "", "default", function()
            local w, h = map:GetSize()
            map.targetX, map.targetY, map.targetZoom = 0, -150, map:FitZoom(w, h)
        end)
        home:SetIcon("home")
        local coruscant = D.Button(map, "Coruscant", "default", function()
            local p = G.Find("Coruscant")
            if p then map:FocusPlanet(p, true) end
        end)
        coruscant:SetFont("gdp.h4")

        -- Legende
        local legend = vgui.Create("DPanel", map)
        legend:SetMouseInputEnabled(false)
        legend.Paint = function(_, w, h)
            if not map.showStatus then return end
            D.Frame(0, 0, w, h, { fill = Color(3, 9, 15, 225), bracket = S(8) })
            local y = S(8)
            D.Text("LAGE", "gdp.tiny.b", S(10), y, D.col.muted)
            D.Aurebesh("Lage", "gdp.aure.small", S(44), y + S(1), D.Accent(100))
            y = y + S(18)
            for _, st in ipairs(CFG.GalaxyStatus) do
                D.Ring(S(16), y + S(7), S(5), st.color, S(2), 12)
                D.Text(st.name, "gdp.tiny", S(28), y, D.col.dim)
                y = y + S(17)
            end
        end

        map.OnLayout = function(_, w, h)
            local pad = S(10)
            search:SetPos(pad, pad)
            search:SetSize(S(260), S(32))
            results:SetPos(pad, pad + S(34))
            results:SetWide(S(320))
            local x = w - pad
            for i = #toggles, 1, -1 do
                local b = toggles[i]
                surface.SetFont("gdp.h4")
                local bw = surface.GetTextSize(b:GetText()) + S(24)
                x = x - bw
                b:SetPos(x, pad)
                b:SetSize(bw, S(30))
                x = x - S(6)
            end
            local zy = h - pad - S(34)
            zoomOut:SetSize(S(34), S(34)) zoomOut:SetPos(w - pad - S(34), zy)
            zoomIn:SetSize(S(34), S(34)) zoomIn:SetPos(w - pad - S(72), zy)
            home:SetSize(S(34), S(34)) home:SetPos(w - pad - S(110), zy)
            coruscant:SetSize(S(110), S(34)) coruscant:SetPos(w - pad - S(226), zy)
            legend:SetSize(S(170), S(34) + #CFG.GalaxyStatus * S(17))
            legend:SetPos(pad, h - pad - legend:GetTall())
            local iw = math.min(S(340), w * 0.36)
            info:SetSize(iw, h - S(50) - S(56))
            info:SetPos(w - iw - pad, pad + S(40))
            closeInfo:SetSize(S(28), S(28))
            closeInfo:SetPos(iw - S(36), S(8))
        end

        if opts.planet then
            local p = G.Find(opts.planet)
            if p then timer.Simple(0, function() if IsValid(map) then map:FocusPlanet(p, true) end end) end
        end
    end,
})
