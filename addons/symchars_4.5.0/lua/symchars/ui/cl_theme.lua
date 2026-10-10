--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Design-System
    Mischung aus Battlefront-Menü (dunkle Flächen, Bernstein-Glow, große Überschriften mit Aurebesh darunter)
    und den Kraken-Scripts (abgeschrägte Platten, Cremeweiß, Stahlblau, Rasterlinien).
-------------------------------------------------------------------------------------------------------------]]

symchars.ui = symchars.ui or {}

local UI = symchars.ui

UI.fonts = {
    head = "BigNoodleTitling",
    body = "Roboto Condensed",
    aure = "Aurebesh",
    mono = "Courier New",
}

---------------------------------------------------------------------------------------------------------------
-- Farben
---------------------------------------------------------------------------------------------------------------
UI.col = {
    bg = Color(6, 8, 11),
    panel = Color(11, 14, 18, 232),
    panel2 = Color(18, 22, 28, 240),
    panel3 = Color(27, 32, 40, 245),
    slate = Color(31, 32, 36, 240),
    line = Color(255, 255, 255, 22),
    line2 = Color(255, 255, 255, 50),
    line3 = Color(255, 255, 255, 95),
    text = Color(236, 233, 224),
    dim = Color(168, 174, 180),
    muted = Color(112, 119, 127),
    faint = Color(70, 76, 84),
    cream = Color(231, 225, 213),
    ink = Color(18, 21, 25),
    cyan = Color(64, 196, 255),
    steel = Color(43, 101, 133),
    red = Color(205, 62, 56),
    green = Color(95, 200, 120),
    blue = Color(80, 170, 230),
    yellow = Color(240, 200, 80),
    black = Color(0, 0, 0),
    white = Color(255, 255, 255),
}

function UI.Accent(alpha)
    local c = symchars.Config("accentcolor") or Color(252, 178, 73)
    if alpha then return Color(c.r, c.g, c.b, alpha) end
    return c
end

function UI.Holo(alpha)
    local c = symchars.Config("hologramcolor") or Color(90, 190, 255)
    if alpha then return Color(c.r, c.g, c.b, alpha) end
    return c
end

function UI.Alpha(col, a)
    return Color(col.r, col.g, col.b, a)
end

function UI.Lerp(t, a, b)
    return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b), Lerp(t, a.a or 255, b.a or 255))
end

function UI.Darken(col, f)
    return Color(col.r * f, col.g * f, col.b * f, col.a or 255)
end

-- Hellt zu dunkle Farben auf, damit Text auf dunklem Grund lesbar bleibt. Der Farbton bleibt:
-- erst auf volle Helligkeit strecken, dann nur leicht aufhellen (Blau Richtung Himmelblau, nicht Richtung Lila).
function UI.Readable(col, minLum)
    if not col then return UI.col.text end
    minLum = minLum or 120
    local r, g, b = col.r, col.g, col.b
    local function Lum() return 0.299 * r + 0.587 * g + 0.114 * b end
    if Lum() >= minLum then return col end
    local m = math.max(r, g, b)
    if m < 1 then return UI.col.dim end
    r, g, b = r * 255 / m, g * 255 / m, b * 255 / m
    local lum = Lum()
    if lum < minLum then
        local tr, tg, tb = 255, 255, 255
        if b >= r and b >= g then tr, tg, tb = 110, 190, 255 end -- Blautöne
        local tlum = 0.299 * tr + 0.587 * tg + 0.114 * tb
        local t = math.Clamp((minLum - lum) / math.max(1, tlum - lum), 0, 0.7)
        r, g, b = Lerp(t, r, tr), Lerp(t, g, tg), Lerp(t, b, tb)
    end
    return Color(r, g, b, col.a or 255)
end

-- Farbe eines Charakters = Farbe seiner Einheit (für Mitgliederlisten, Akte usw.)
function UI.UnitColor(char)
    local faction = char and char.GetFaction and char:GetFaction()
    return faction and faction:GetColor() or UI.Accent()
end

---------------------------------------------------------------------------------------------------------------
-- Skalierung & Schriften
---------------------------------------------------------------------------------------------------------------
function UI.S(px)
    return math.max(1, math.floor(px * ScrH() / 1080 + 0.5))
end

local function Font(name, font, size, weight, extra)
    local data = { font = font, size = math.max(8, UI.S(size)), weight = weight or 500, antialias = true, extended = true }
    if extra then for k, v in pairs(extra) do data[k] = v end end
    surface.CreateFont(name, data)
end

function UI.CreateFonts()
    local f = UI.fonts
    Font("symchars.title", f.head, 68)
    Font("symchars.tab", f.head, 46)
    Font("symchars.h1", f.head, 42)
    Font("symchars.h2", f.head, 34)
    Font("symchars.h3", f.head, 27)
    Font("symchars.h4", f.head, 22)
    Font("symchars.button", f.head, 30)
    Font("symchars.button.small", f.head, 23)
    Font("symchars.big", f.head, 96)

    Font("symchars.name", f.body, 34, 600)
    Font("symchars.name.small", f.body, 26, 600)
    Font("symchars.body", f.body, 21, 500)
    Font("symchars.body.bold", f.body, 21, 800)
    Font("symchars.input", f.body, 24, 500)
    Font("symchars.small", f.body, 18, 500)
    Font("symchars.small.bold", f.body, 18, 800)
    Font("symchars.tiny", f.body, 15, 500)
    Font("symchars.tiny.bold", f.body, 15, 800)

    Font("symchars.aure", f.aure, 15, 500)
    Font("symchars.aure.small", f.aure, 11, 500)
    Font("symchars.aure.big", f.aure, 22, 500)


    -- feste Größe (3D2D über dem Kopf, unabhängig von der Auflösung)
    surface.CreateFont("symchars.overhead.name", { font = f.body, size = 64, weight = 700, antialias = true, extended = true })
    surface.CreateFont("symchars.overhead.rank", { font = f.head, size = 54, weight = 500, antialias = true, extended = true })

    -- Dokumente: Text, Überschriften in vier Schnitten
    local sizes = { p = 22, h1 = 44, h2 = 34, h3 = 27, code = 19, small = 17 }
    for key, size in pairs(sizes) do
        local face = key == "code" and f.mono or f.body
        Font("symchars.doc." .. key, face, size, key:sub(1, 1) == "h" and 700 or 500)
        Font("symchars.doc." .. key .. ".b", face, size, 800)
        Font("symchars.doc." .. key .. ".i", face, size, key:sub(1, 1) == "h" and 700 or 500, { italic = true })
        Font("symchars.doc." .. key .. ".bi", face, size, 800, { italic = true })
    end

    -- Holo-Anzeigen in der Welt (feste Größe, unabhängig von der Auflösung)
    surface.CreateFont("symchars.world.title", { font = f.head, size = 64, weight = 500, antialias = true, extended = true })
    surface.CreateFont("symchars.world.h", { font = f.head, size = 40, weight = 500, antialias = true, extended = true })
    surface.CreateFont("symchars.world.body", { font = f.body, size = 30, weight = 500, antialias = true, extended = true })
    surface.CreateFont("symchars.world.small", { font = f.body, size = 24, weight = 500, antialias = true, extended = true })
    surface.CreateFont("symchars.world.aure", { font = f.aure, size = 22, weight = 500, antialias = true, extended = true })
    surface.CreateFont("symchars.world.name", { font = f.body, size = 34, weight = 700, antialias = true, extended = true })
end

UI.CreateFonts()
hook.Add("OnScreenSizeChanged", "symchars_fonts", function() UI.CreateFonts() end)

---------------------------------------------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------------------------------------------
function UI.TextSize(text, font)
    surface.SetFont(font)
    return surface.GetTextSize(tostring(text or ""))
end

function UI.Trim(text, font, maxW)
    text = tostring(text or "")
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxW then return text end
    local chars = {}
    for _, code in utf8.codes(text) do chars[#chars + 1] = utf8.char(code) end
    local lo, hi = 0, #chars
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if surface.GetTextSize(table.concat(chars, "", 1, mid) .. "…") <= maxW then lo = mid else hi = mid - 1 end
    end
    return table.concat(chars, "", 1, lo) .. "…"
end

function UI.Text(text, font, x, y, col, ax, ay)
    draw.SimpleText(tostring(text or ""), font, x, y, col or UI.col.text, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
end

function UI.TextFit(text, font, x, y, col, maxW, ax, ay)
    UI.Text(UI.Trim(text, font, maxW), font, x, y, col, ax, ay)
end

-- Zeilenumbruch, gibt Liste von Zeilen zurück
function UI.Wrap(text, font, maxW)
    local lines = {}
    surface.SetFont(font)
    for _, paragraph in ipairs(string.Explode("\n", tostring(text or ""))) do
        local line = ""
        for word in string.gmatch(paragraph, "%S+") do
            local candidate = line == "" and word or (line .. " " .. word)
            if surface.GetTextSize(candidate) <= maxW then
                line = candidate
            else
                if line ~= "" then lines[#lines + 1] = line end
                if surface.GetTextSize(word) > maxW then
                    line = UI.Trim(word, font, maxW)
                else
                    line = word
                end
            end
        end
        lines[#lines + 1] = line
    end
    return lines
end

function UI.WrapHeight(text, font, maxW)
    local _, lh = UI.TextSize("Ag", font)
    return #UI.Wrap(text, font, maxW) * lh, lh
end

function UI.DrawWrapped(text, font, x, y, maxW, col, maxLines, lineGap)
    local lines = UI.Wrap(text, font, maxW)
    local _, lh = UI.TextSize("Ag", font)
    lh = lh + (lineGap or 0)
    for i, line in ipairs(lines) do
        if maxLines and i > maxLines then break end
        if maxLines and i == maxLines and #lines > maxLines then line = UI.Trim(line .. " …", font, maxW) end
        draw.SimpleText(line, font, x, y + (i - 1) * lh, col or UI.col.text)
    end
    return math.min(#lines, maxLines or #lines) * lh
end

-- Aurebesh: Umlaute umschreiben, Zeichen, die die Schrift nicht kennt, entfernen
local AUREMAP = { ["ä"] = "ae", ["ö"] = "oe", ["ü"] = "ue", ["Ä"] = "AE", ["Ö"] = "OE", ["Ü"] = "UE", ["ß"] = "ss" }
function UI.ToAurebesh(text)
    text = tostring(text or "")
    text = string.gsub(text, "[\195][\128-\191]", function(c) return AUREMAP[c] or "" end)
    text = string.gsub(text, "[^%w%s%-%.%,%:%!%?]", "")
    return string.upper(text)
end

function UI.Aurebesh(text, font, x, y, col, ax, ay, maxW)
    text = UI.ToAurebesh(text)
    if maxW then text = UI.Trim(text, font or "symchars.aure", maxW) end
    draw.SimpleText(text, font or "symchars.aure", x, y, col or UI.Alpha(UI.col.dim, 170), ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
end

-- Überschrift mit Aurebesh-Zeile darunter (wie im Battlefront-Menü)
function UI.Heading(text, font, x, y, col, ax, aureCol, aureFont)
    local w, h = UI.TextSize(text, font)
    UI.Text(string.upper(text), font, x, y, col or UI.col.text, ax)
    UI.Aurebesh(text, aureFont or "symchars.aure.small", x + (ax == TEXT_ALIGN_CENTER and 0 or (ax == TEXT_ALIGN_RIGHT and 0 or UI.S(2))), y + h - UI.S(6), aureCol or UI.Alpha(col or UI.col.text, 150), ax)
    return w, h + UI.S(10)
end

---------------------------------------------------------------------------------------------------------------
-- Formen
---------------------------------------------------------------------------------------------------------------
function UI.Box(x, y, w, h, col)
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, w, h)
end

function UI.Outline(x, y, w, h, col, thick)
    surface.SetDrawColor(col)
    thick = thick or 1
    for i = 0, thick - 1 do surface.DrawOutlinedRect(x + i, y + i, w - i * 2, h - i * 2) end
end

-- weicher Leucht-Rahmen (Bernstein-Glow ausgewählter Karten)
function UI.Glow(x, y, w, h, col, size, strength)
    size = size or UI.S(10)
    strength = strength or 1
    for i = 1, size do
        local a = (1 - i / size) ^ 2 * 90 * strength * ((col.a or 255) / 255)
        surface.SetDrawColor(col.r, col.g, col.b, a)
        surface.DrawOutlinedRect(x - i, y - i, w + i * 2, h + i * 2)
    end
end

local polyCache = {}
local function CutPoly(x, y, w, h, c, corners)
    local key = x .. ":" .. y .. ":" .. w .. ":" .. h .. ":" .. c .. ":" .. (corners or "")
    local cached = polyCache[key]
    if cached then return cached end
    corners = corners or "tlbr"
    local tl, tr, br, bl = string.find(corners, "tl", 1, true), string.find(corners, "tr", 1, true), string.find(corners, "br", 1, true), string.find(corners, "bl", 1, true)
    local pts = {}
    local function P(px, py) pts[#pts + 1] = { x = px, y = py } end
    if tl then P(x, y + c) P(x + c, y) else P(x, y) end
    if tr then P(x + w - c, y) P(x + w, y + c) else P(x + w, y) end
    if br then P(x + w, y + h - c) P(x + w - c, y + h) else P(x + w, y + h) end
    if bl then P(x + c, y + h) P(x, y + h - c) else P(x, y + h) end
    if table.Count(polyCache) > 600 then polyCache = {} end
    polyCache[key] = pts
    return pts
end

-- Platte mit abgeschrägten Ecken (corners: "tl", "tr", "br", "bl" kombinierbar)
function UI.Cut(x, y, w, h, col, c, corners)
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly(CutPoly(x, y, w, h, c or UI.S(10), corners))
end

function UI.CutOutline(x, y, w, h, col, c, corners)
    local pts = CutPoly(x, y, w, h, c or UI.S(10), corners)
    surface.SetDrawColor(col)
    for i = 1, #pts do
        local a, b = pts[i], pts[i % #pts + 1]
        surface.DrawLine(a.x, a.y, b.x, b.y)
    end
end

function UI.Circle(cx, cy, r, col, seg)
    seg = seg or 32
    local pts = {}
    for i = 0, seg - 1 do
        local a = math.rad(i / seg * -360)
        pts[#pts + 1] = { x = cx + math.sin(a) * r, y = cy + math.cos(a) * r }
    end
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly(pts)
end

function UI.Ring(cx, cy, r, col, thick, seg)
    seg = seg or 40
    thick = thick or 2
    surface.SetDrawColor(col)
    for t = 0, thick - 1 do
        local rr = r - t
        local lx, ly
        for i = 0, seg do
            local a = math.rad(i / seg * 360)
            local px, py = cx + math.cos(a) * rr, cy + math.sin(a) * rr
            if lx then surface.DrawLine(lx, ly, px, py) end
            lx, ly = px, py
        end
    end
end

function UI.Arc(cx, cy, r, thick, from, to, col, seg)
    seg = seg or 32
    surface.SetDrawColor(col)
    for t = 0, thick - 1 do
        local rr = r - t
        local lx, ly
        for i = 0, seg do
            local a = math.rad(from + (to - from) * i / seg)
            local px, py = cx + math.cos(a) * rr, cy + math.sin(a) * rr
            if lx then surface.DrawLine(lx, ly, px, py) end
            lx, ly = px, py
        end
    end
end

-- kleine Markierungen am Rand von Karten (wie im Battlefront-Menü)
function UI.EdgeMarks(x, y, h, col, seed)
    seed = seed or 1
    local s = UI.S(1)
    local cy = y + UI.S(6)
    local pattern = { 3, 0, 1, 2, 0, 1, 1 }
    for i = 1, #pattern do
        local kind = pattern[(i + seed) % #pattern + 1]
        if cy > y + h - UI.S(10) then break end
        if kind == 3 then
            surface.SetDrawColor(col)
            surface.DrawRect(x, cy, UI.S(4), UI.S(18))
            cy = cy + UI.S(24)
        elseif kind == 1 then
            surface.SetDrawColor(col)
            surface.DrawRect(x, cy, UI.S(4), UI.S(6))
            cy = cy + UI.S(10)
        elseif kind == 2 then
            surface.SetDrawColor(UI.Alpha(col, 120))
            surface.DrawOutlinedRect(x, cy, UI.S(6), UI.S(6))
            cy = cy + UI.S(10)
        else
            cy = cy + UI.S(8)
        end
        s = s + 1
    end
end

-- linke Bildschirmlinie mit Knick und Markierungen (Battlefront-Menü)
function UI.Rail(w, h, col)
    col = col or UI.Alpha(UI.col.text, 60)
    local x1, x2 = UI.S(58), UI.S(88)
    local y1, y2, y3 = UI.S(110), h * 0.22, h * 0.52
    surface.SetDrawColor(col)
    surface.DrawLine(x2, 0, x2, y1)
    surface.DrawLine(x2, y1, x2 + UI.S(26), y1 + UI.S(26))
    surface.DrawLine(x2 + UI.S(26), y1 + UI.S(26), x2 + UI.S(26), y2)
    surface.DrawLine(x2 + UI.S(26), y2, x1, y3)
    surface.DrawLine(x1, y3, x1, h)
    surface.DrawLine(x2 + UI.S(4), 0, x2 + UI.S(4), y1 - UI.S(2))

    local tick = UI.Alpha(UI.col.text, 200)
    surface.SetDrawColor(tick)
    local tx = x2 - UI.S(30)
    surface.DrawRect(tx, y1 + UI.S(40), UI.S(4), UI.S(22))
    surface.DrawRect(tx, y1 + UI.S(76), UI.S(4), UI.S(5))
    surface.DrawRect(tx, y1 + UI.S(88), UI.S(4), UI.S(5))
    surface.DrawRect(tx, y1 + UI.S(130), UI.S(4), UI.S(26))
    surface.DrawRect(tx, y1 + UI.S(162), UI.S(4), UI.S(6))

    local bx = x1 + UI.S(18)
    local by = h * 0.66
    surface.DrawRect(bx, by, UI.S(18), UI.S(12))
    surface.DrawRect(bx, by + UI.S(30), UI.S(8), UI.S(84))
    surface.DrawRect(bx, by + UI.S(122), UI.S(18), UI.S(12))
    surface.DrawRect(bx, by + UI.S(160), UI.S(18), UI.S(5))
    surface.DrawRect(bx, by + UI.S(174), UI.S(18), UI.S(5))
    surface.DrawRect(bx, by + UI.S(188), UI.S(18), UI.S(12))
end

-- feine Rasterlinien / Scanlines
function UI.Scanlines(x, y, w, h, alpha, gap)
    gap = gap or UI.S(3)
    surface.SetDrawColor(0, 0, 0, alpha or 40)
    for yy = y, y + h, gap do surface.DrawRect(x, yy, w, 1) end
end

local gradD = Material("vgui/gradient-d")
local gradU = Material("vgui/gradient-u")
local gradR = Material("vgui/gradient-r")
local gradL = Material("vgui/gradient-l")
UI.mat = { gradD = gradD, gradU = gradU, gradR = gradR, gradL = gradL }

function UI.Gradient(x, y, w, h, col, dir)
    surface.SetDrawColor(col)
    surface.SetMaterial(dir == "up" and gradU or dir == "right" and gradR or dir == "left" and gradL or gradD)
    surface.DrawTexturedRect(x, y, w, h)
end

local blur = Material("pp/blurscreen")
function UI.Blur(panel, amount, alpha)
    local x, y = panel:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255, alpha or 255)
    surface.SetMaterial(blur)
    for i = 1, 3 do
        blur:SetFloat("$blur", (i / 3) * (amount or 6))
        blur:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end
end

-- Standard-Fläche (Panel)
function UI.Panel(x, y, w, h, opts)
    opts = opts or {}
    if opts.cut then
        UI.Cut(x, y, w, h, opts.fill or UI.col.panel, opts.cut, opts.corners)
        UI.CutOutline(x, y, w, h, opts.stroke or UI.col.line, opts.cut, opts.corners)
    else
        UI.Box(x, y, w, h, opts.fill or UI.col.panel)
        UI.Outline(x, y, w, h, opts.stroke or UI.col.line)
    end
    if opts.accent then
        UI.Box(x, y, opts.accentW or UI.S(4), h, opts.accent)
    end
end

-- Abschnittstitel in Panels (mit Aurebesh rechts)
function UI.Section(text, x, y, w, col)
    UI.Text(string.upper(text), "symchars.h3", x, y, col or UI.col.text)
    local tw, th = UI.TextSize(string.upper(text), "symchars.h3")
    if w then
        UI.Box(x + tw + UI.S(10), y + th * 0.55, w - tw - UI.S(10), 1, UI.col.line2)
        UI.Aurebesh(text, "symchars.aure.small", x + w, y + th * 0.55 - UI.S(14), UI.Alpha(UI.col.dim, 120), TEXT_ALIGN_RIGHT)
    end
    return th
end

-- kleiner Chip (Tag)
function UI.Chip(text, font, x, y, fg, bg, outline)
    font = font or "symchars.tiny.bold"
    text = string.upper(tostring(text))
    local tw, th = UI.TextSize(text, font)
    local pw, ph = tw + UI.S(14), th + UI.S(6)
    UI.Cut(x, y, pw, ph, bg or UI.col.panel3, UI.S(5), "tlbr")
    if outline then UI.CutOutline(x, y, pw, ph, outline, UI.S(5), "tlbr") end
    UI.Text(text, font, x + pw / 2, y + ph / 2, fg or UI.col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return pw, ph
end

---------------------------------------------------------------------------------------------------------------
-- Icons (Vektor)
---------------------------------------------------------------------------------------------------------------
local function Line(x1, y1, x2, y2, t)
    t = t or 2
    if t <= 1 then surface.DrawLine(x1, y1, x2, y2) return end
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return end
    -- Normale so gewählt, dass das Viereck immer im Uhrzeigersinn liegt (sonst zeichnet DrawPoly nichts)
    local nx, ny = dy / len * t / 2, -dx / len * t / 2
    draw.NoTexture()
    surface.DrawPoly({ { x = x1 + nx, y = y1 + ny }, { x = x2 + nx, y = y2 + ny }, { x = x2 - nx, y = y2 - ny }, { x = x1 - nx, y = y1 - ny } })
end
UI.ThickLine = Line

function UI.Icon(name, x, y, s, col)
    surface.SetDrawColor(col or UI.col.text)
    draw.NoTexture()
    local t = math.max(2, math.floor(s / 10))
    local cx, cy = x + s / 2, y + s / 2

    if name == "plus" then
        surface.DrawRect(cx - t / 2, y + s * 0.2, t, s * 0.6)
        surface.DrawRect(x + s * 0.2, cy - t / 2, s * 0.6, t)
    elseif name == "close" then
        Line(x + s * 0.25, y + s * 0.25, x + s * 0.75, y + s * 0.75, t)
        Line(x + s * 0.75, y + s * 0.25, x + s * 0.25, y + s * 0.75, t)
    elseif name == "check" then
        Line(x + s * 0.2, y + s * 0.52, x + s * 0.42, y + s * 0.74, t + 1)
        Line(x + s * 0.42, y + s * 0.74, x + s * 0.82, y + s * 0.28, t + 1)
    elseif name == "lock" then
        UI.Arc(cx, y + s * 0.42, s * 0.22, t, 180, 360, col or UI.col.text, 12)
        surface.DrawRect(x + s * 0.22, y + s * 0.42, s * 0.56, s * 0.42)
    elseif name == "user" then
        UI.Circle(cx, y + s * 0.32, s * 0.17, col or UI.col.text, 16)
        UI.Cut(x + s * 0.2, y + s * 0.56, s * 0.6, s * 0.3, col or UI.col.text, s * 0.12, "tltr")
    elseif name == "credits" then
        -- Republik-Credit-Symbol (stilisiert)
        surface.DrawRect(x + s * 0.18, y + s * 0.18, s * 0.6, t)
        surface.DrawRect(x + s * 0.18, y + s * 0.34, s * 0.42, t)
        Line(x + s * 0.78, y + s * 0.18, x + s * 0.36, y + s * 0.86, t + 1)
    elseif name == "clock" then
        UI.Ring(cx, cy, s * 0.38, col or UI.col.text, t, 24)
        surface.DrawRect(cx - t / 2, y + s * 0.28, t, s * 0.24)
        surface.DrawRect(cx, cy - t / 2, s * 0.2, t)
    elseif name == "calendar" then
        UI.Outline(x + s * 0.15, y + s * 0.22, s * 0.7, s * 0.62, col or UI.col.text, t)
        surface.DrawRect(x + s * 0.15, y + s * 0.36, s * 0.7, t)
        surface.DrawRect(x + s * 0.3, y + s * 0.12, t, s * 0.18)
        surface.DrawRect(x + s * 0.66, y + s * 0.12, t, s * 0.18)
    elseif name == "doc" then
        UI.Cut(x + s * 0.2, y + s * 0.1, s * 0.6, s * 0.8, col or UI.col.text, s * 0.18, "tr")
        surface.SetDrawColor(UI.col.ink)
        surface.DrawRect(x + s * 0.3, y + s * 0.42, s * 0.4, t)
        surface.DrawRect(x + s * 0.3, y + s * 0.56, s * 0.4, t)
        surface.DrawRect(x + s * 0.3, y + s * 0.7, s * 0.28, t)
    elseif name == "form" then
        UI.Outline(x + s * 0.18, y + s * 0.12, s * 0.64, s * 0.78, col or UI.col.text, t)
        Line(x + s * 0.3, y + s * 0.35, x + s * 0.38, y + s * 0.43, t)
        Line(x + s * 0.38, y + s * 0.43, x + s * 0.5, y + s * 0.3, t)
        surface.DrawRect(x + s * 0.3, y + s * 0.58, s * 0.4, t)
        surface.DrawRect(x + s * 0.3, y + s * 0.72, s * 0.3, t)
    elseif name == "star" then
        local pts = {}
        for i = 0, 9 do
            local r = (i % 2 == 0) and s * 0.45 or s * 0.2
            local a = math.rad(-90 + i * 36)
            pts[#pts + 1] = { x = cx + math.cos(a) * r, y = cy + math.sin(a) * r }
        end
        for i = 1, #pts do
            local a, b = pts[i], pts[i % #pts + 1]
            Line(a.x, a.y, b.x, b.y, t)
        end
    elseif name == "edit" then
        Line(x + s * 0.25, y + s * 0.75, x + s * 0.72, y + s * 0.28, t + 2)
        Line(x + s * 0.2, y + s * 0.8, x + s * 0.3, y + s * 0.78, t)
    elseif name == "trash" then
        surface.DrawRect(x + s * 0.2, y + s * 0.22, s * 0.6, t)
        surface.DrawRect(x + s * 0.4, y + s * 0.12, s * 0.2, t)
        UI.Outline(x + s * 0.27, y + s * 0.3, s * 0.46, s * 0.56, col or UI.col.text, t)
    elseif name == "arrow_left" or name == "arrow_right" or name == "arrow_up" or name == "arrow_down" then
        local dir = name == "arrow_left" and 180 or name == "arrow_right" and 0 or name == "arrow_up" and -90 or 90
        local a1, a2 = math.rad(dir + 140), math.rad(dir - 140)
        local tipx, tipy = cx + math.cos(math.rad(dir)) * s * 0.25, cy + math.sin(math.rad(dir)) * s * 0.25
        Line(tipx, tipy, tipx + math.cos(a1) * s * 0.35, tipy + math.sin(a1) * s * 0.35, t)
        Line(tipx, tipy, tipx + math.cos(a2) * s * 0.35, tipy + math.sin(a2) * s * 0.35, t)
    elseif name == "search" then
        UI.Ring(x + s * 0.42, y + s * 0.42, s * 0.26, col or UI.col.text, t, 20)
        Line(x + s * 0.6, y + s * 0.6, x + s * 0.85, y + s * 0.85, t + 1)
    elseif name == "shield" then
        local pts = { { x = cx, y = y + s * 0.1 }, { x = x + s * 0.85, y = y + s * 0.25 }, { x = x + s * 0.78, y = y + s * 0.62 }, { x = cx, y = y + s * 0.92 }, { x = x + s * 0.22, y = y + s * 0.62 }, { x = x + s * 0.15, y = y + s * 0.25 } }
        surface.DrawPoly(pts)
    elseif name == "medal" then
        UI.Circle(cx, y + s * 0.62, s * 0.24, col or UI.col.text, 20)
        Line(x + s * 0.3, y + s * 0.1, cx, y + s * 0.42, t)
        Line(x + s * 0.7, y + s * 0.1, cx, y + s * 0.42, t)
    elseif name == "holo" then
        UI.Ring(cx, y + s * 0.82, s * 0.32, col or UI.col.text, t, 20)
        Line(x + s * 0.18, y + s * 0.82, cx, y + s * 0.12, t)
        Line(x + s * 0.82, y + s * 0.82, cx, y + s * 0.12, t)
    elseif name == "gear" then
        UI.Ring(cx, cy, s * 0.24, col or UI.col.text, t + 1, 20)
        for i = 0, 7 do
            local a = math.rad(i * 45)
            Line(cx + math.cos(a) * s * 0.28, cy + math.sin(a) * s * 0.28, cx + math.cos(a) * s * 0.44, cy + math.sin(a) * s * 0.44, t + 1)
        end
    elseif name == "chevron" then
        Line(x + s * 0.3, y + s * 0.4, cx, y + s * 0.65, t)
        Line(cx, y + s * 0.65, x + s * 0.7, y + s * 0.4, t)
    elseif name == "info" then
        UI.Ring(cx, cy, s * 0.4, col or UI.col.text, t, 24)
        surface.DrawRect(cx - t / 2, y + s * 0.42, t, s * 0.3)
        surface.DrawRect(cx - t / 2, y + s * 0.26, t, t)
    elseif name == "warn" then
        Line(cx, y + s * 0.12, x + s * 0.88, y + s * 0.85, t)
        Line(x + s * 0.88, y + s * 0.85, x + s * 0.12, y + s * 0.85, t)
        Line(x + s * 0.12, y + s * 0.85, cx, y + s * 0.12, t)
        surface.DrawRect(cx - t / 2, y + s * 0.38, t, s * 0.25)
    else
        UI.Outline(x + s * 0.2, y + s * 0.2, s * 0.6, s * 0.6, col or UI.col.text, t)
    end
end

-- runder Akzent-Knopf mit Icon (wie das "+" bei "Neuen Charakter erstellen")
function UI.RoundIcon(name, cx, cy, r, bg, fg)
    UI.Circle(cx, cy, r, bg or UI.Accent(), 32)
    UI.Icon(name, cx - r * 0.7, cy - r * 0.7, r * 1.4, fg or UI.col.ink)
end

---------------------------------------------------------------------------------------------------------------
-- Sounds
---------------------------------------------------------------------------------------------------------------
UI.sounds = {
    hover = "ui/buttonrollover.wav",
    click = "ui/buttonclickrelease.wav",
    open = "buttons/button24.wav",
    error = "buttons/button10.wav",
    success = "buttons/button14.wav",
    notify = "buttons/blip1.wav",
}

function UI.Sound(kind)
    local path = UI.sounds[kind]
    if path then surface.PlaySound(path) end
end

---------------------------------------------------------------------------------------------------------------
-- Allgemeine Helfer
---------------------------------------------------------------------------------------------------------------
function UI.Ease(t)
    t = math.Clamp(t, 0, 1)
    return t < 0.5 and 4 * t * t * t or 1 - ((-2 * t + 2) ^ 3) / 2
end

function UI.Approach(cur, target, speed)
    return Lerp(math.min(FrameTime() * (speed or 10), 1), cur, target)
end

function UI.LocalChar()
    local lp = LocalPlayer()
    return IsValid(lp) and lp:GetCharacter() or nil
end

function UI.FactionColor(faction)
    faction = symchars.factions.Get(faction)
    return faction and faction:GetColor() or UI.Accent()
end
