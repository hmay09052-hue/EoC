--[[-------------------------------------------------------------------------------------------------------------
    SSE - Design-System (angepasst an das Server-Design von SymChars 2 / Kraken-Scripts)
    Dunkle Flächen, Bernstein-Akzent, abgeschrägte Platten, große Überschriften mit Aurebesh darunter,
    Holo-Blau für Anzeigen in der Welt. Funktioniert auch ohne SymChars (eigene Schriften & Farben).
-------------------------------------------------------------------------------------------------------------]]

SSE.UI = SSE.UI or {}

local UI = SSE.UI

UI.fonts = {
    head = "BigNoodleTitling",
    body = "Roboto Condensed",
    aure = "Aurebesh",
}

---------------------------------------------------------------------------------------------------------------
-- Farben (identisch zu symchars.ui.col)
---------------------------------------------------------------------------------------------------------------
UI.col = {
    bg = Color(6, 8, 11),
    panel = Color(11, 14, 18, 232),
    panel2 = Color(18, 22, 28, 240),
    panel3 = Color(27, 32, 40, 245),
    line = Color(255, 255, 255, 22),
    line2 = Color(255, 255, 255, 50),
    line3 = Color(255, 255, 255, 95),
    text = Color(236, 233, 224),
    dim = Color(168, 174, 180),
    muted = Color(112, 119, 127),
    faint = Color(70, 76, 84),
    ink = Color(18, 21, 25),
    red = Color(205, 62, 56),
    green = Color(95, 200, 120),
    blue = Color(80, 170, 230),
    yellow = Color(240, 200, 80),
}

local DEFAULT_ACCENT = Color(252, 178, 73)
local DEFAULT_HOLO = Color(90, 190, 255)

-- Akzent/Holo-Farbe: SSE-Config > SymChars-Einstellung > Standard
local function FromSymChars(key)
    if not symchars or not symchars.Config then return end
    local ok, col = pcall(symchars.Config, key)
    if ok and IsColor(col) then return col end
    if ok and istable(col) and col.r then return Color(col.r, col.g, col.b) end
end

function UI.Accent(alpha)
    local c = (SSE.Config and SSE.Config.AccentColor) or FromSymChars("accentcolor") or DEFAULT_ACCENT
    return Color(c.r, c.g, c.b, alpha or 255)
end

function UI.Holo(alpha)
    local c = (SSE.Config and SSE.Config.HoloColor) or FromSymChars("hologramcolor") or DEFAULT_HOLO
    return Color(c.r, c.g, c.b, alpha or 255)
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

-- Hellt zu dunkle Farben auf, damit Text auf dunklem Grund lesbar bleibt
function UI.Readable(col, minLum)
    if not col then return UI.col.text end
    minLum = minLum or 150
    local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
    if lum >= minLum then return col end
    local t = math.Clamp((minLum - lum) / math.max(1, 255 - lum), 0, 1)
    return Color(Lerp(t, col.r, 255), Lerp(t, col.g, 255), Lerp(t, col.b, 255), col.a or 255)
end

---------------------------------------------------------------------------------------------------------------
-- Skalierung & Schriften
---------------------------------------------------------------------------------------------------------------
function UI.S(px)
    return math.max(1, math.floor(px * ScrH() / 1080 + 0.5))
end

local function Font(name, font, size, weight)
    surface.CreateFont(name, { font = font, size = math.max(8, UI.S(size)), weight = weight or 500, antialias = true, extended = true })
end

local function WorldFont(name, font, size, weight)
    surface.CreateFont(name, { font = font, size = size, weight = weight or 500, antialias = true, extended = true })
end

function UI.CreateFonts()
    local f = UI.fonts
    Font("sse.h1", f.head, 42)
    Font("sse.h2", f.head, 34)
    Font("sse.h3", f.head, 27)
    Font("sse.h4", f.head, 22)
    Font("sse.button", f.head, 28)
    Font("sse.hud", f.head, 40)

    Font("sse.body", f.body, 21, 500)
    Font("sse.input", f.body, 24, 500)
    Font("sse.small", f.body, 18, 500)
    Font("sse.small.bold", f.body, 18, 800)
    Font("sse.tiny.bold", f.body, 15, 800)

    Font("sse.aure", f.aure, 15, 500)
    Font("sse.aure.small", f.aure, 11, 500)

    -- Anzeigen in der Welt (3D2D, feste Größe)
    WorldFont("sse.world.huge", f.head, 150)
    WorldFont("sse.world.big", f.head, 100)
    WorldFont("sse.world.title", f.head, 72)
    WorldFont("sse.world.h", f.head, 48)
    WorldFont("sse.world.button", f.head, 32)
    WorldFont("sse.world.body", f.body, 34, 500)
    WorldFont("sse.world.small", f.body, 24, 600)
    WorldFont("sse.world.aure", f.aure, 22)
    WorldFont("sse.world.aure.big", f.aure, 34)
end

UI.CreateFonts()
hook.Add("OnScreenSizeChanged", "SSE.UI.Fonts", function() UI.CreateFonts() end)

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
                line = surface.GetTextSize(word) > maxW and UI.Trim(word, font, maxW) or word
            end
        end
        lines[#lines + 1] = line
    end
    return lines
end

function UI.TextShadow(text, font, x, y, col, ax, ay, off)
    off = off or 2
    draw.SimpleText(tostring(text or ""), font, x + off, y + off, Color(0, 0, 0, 200 * ((col and col.a or 255) / 255)), ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
    draw.SimpleText(tostring(text or ""), font, x, y, col or UI.col.text, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
end

-- Aurebesh: Umlaute umschreiben, Zeichen, die die Schrift nicht kennt, entfernen
local AUREMAP = { ["ä"] = "ae", ["ö"] = "oe", ["ü"] = "ue", ["Ä"] = "AE", ["Ö"] = "OE", ["Ü"] = "UE", ["ß"] = "ss" }
function UI.ToAurebesh(text)
    text = tostring(text or "")
    text = string.gsub(text, "[\195][\128-\191]", function(c) return AUREMAP[c] or "" end)
    text = string.gsub(text, "[^%w%s%-%.%,%:%!%?]", "")
    return string.upper(text)
end

-- Aurebesh wird als Bild-Atlas gezeichnet: Schriften aus resource/fonts lädt GMod erst nach einem
-- Spielneustart, ein Bild dagegen sofort (gleiches Verfahren wie im Funksystem helio_radio).
local ATLAS = include("sse/cl_aurebesh_atlas.lua")
local ATLAS_SPACING = 0.08
local atlasMat -- nil = noch nicht geladen, false = nicht verfügbar

local function AtlasUsable(mat)
    return mat ~= nil and not mat:IsError()
end

-- 1. Bild aus dem Serverpaket, 2. eingebettetes Bild über data/, 3. sonst Schrift als Ersatz
local function GetAtlas()
    if atlasMat ~= nil then return atlasMat end

    local mat = Material("vgui/hradio/aurebesh_atlas.png", "smooth mips")
    local source = "Serverpaket (vgui/hradio/aurebesh_atlas.png)"
    if not AtlasUsable(mat) and ATLAS and ATLAS.png then
        source = "eingebettetes Bild (data/sse/)"
        local path = "sse/aurebesh_atlas_" .. #ATLAS.png .. ".png"
        if not file.Exists(path, "DATA") then
            file.CreateDir("sse")
            file.Write(path, util.Base64Decode(ATLAS.png))
        end
        mat = Material("../data/" .. path, "smooth mips")
        if not AtlasUsable(mat) then mat = Material("data/" .. path, "smooth mips") end
    end

    atlasMat = AtlasUsable(mat) and mat or false
    if atlasMat then
        print("[SSE] Aurebesh-Atlas geladen: " .. source)
    else
        print("[SSE] Aurebesh-Atlas konnte nicht geladen werden, nutze Schrift als Ersatz.")
    end
    return atlasMat
end

-- Zellhöhe des Atlas je "Schrift" (die Zeichen selbst sind etwa 60 % davon hoch)
local function AtlasHeight(font)
    if font == "sse.aure.small" then return UI.S(16) end
    if font == "sse.world.aure" then return 30 end
    if font == "sse.world.aure.big" then return 46 end
    return UI.S(22)
end

local function AtlasWidth(text, h)
    local w = 0
    for i = 1, #text do
        local ch = string.sub(text, i, i)
        local g = ATLAS.glyphs[ch]
        if g then
            w = w + (g[3] + ATLAS_SPACING) * h
        elseif ch == " " then
            w = w + ATLAS.space * h
        end
    end
    return w
end

function UI.Aurebesh(text, font, x, y, col, ax, ay, maxW)
    text = UI.ToAurebesh(text)
    font = font or "sse.aure"
    col = col or UI.Alpha(UI.col.dim, 170)

    local mat = GetAtlas()
    if not mat then
        if maxW then text = UI.Trim(text, font, maxW) end
        draw.SimpleText(text, font, x, y, col, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
        return
    end

    local h = AtlasHeight(font)
    if maxW then
        while #text > 0 and AtlasWidth(text, h) > maxW do text = string.sub(text, 1, -2) end
    end

    local w = AtlasWidth(text, h)
    local pen = x
    if ax == TEXT_ALIGN_CENTER then pen = x - w / 2 elseif ax == TEXT_ALIGN_RIGHT then pen = x - w end
    local cy = y + h * 0.5
    if ay == TEXT_ALIGN_CENTER then cy = y elseif ay == TEXT_ALIGN_BOTTOM then cy = y - h * 0.5 end
    -- Zellen haben oben/unten Leerraum, Text näher an die Zeile darüber rücken
    if ay == nil or ay == TEXT_ALIGN_TOP then cy = cy - h * 0.15 end

    local size, cell = ATLAS.size, ATLAS.cell
    surface.SetMaterial(mat)
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    for i = 1, #text do
        local ch = string.sub(text, i, i)
        local g = ATLAS.glyphs[ch]
        if g then
            local adv = g[3] * h
            surface.DrawTexturedRectUV(pen + adv * 0.5 - h * 0.5, cy - h * 0.5, h, h, g[1] / size, g[2] / size, (g[1] + cell) / size, (g[2] + cell) / size)
            pen = pen + adv + ATLAS_SPACING * h
        elseif ch == " " then
            pen = pen + ATLAS.space * h
        end
    end
    draw.NoTexture()
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

-- weicher Leucht-Rahmen
function UI.Glow(x, y, w, h, col, size, strength)
    size = size or UI.S(10)
    strength = strength or 1
    for i = 1, size do
        local a = (1 - i / size) ^ 2 * 90 * strength * ((col.a or 255) / 255)
        surface.SetDrawColor(col.r, col.g, col.b, a)
        surface.DrawOutlinedRect(x - i, y - i, w + i * 2, h + i * 2)
    end
end

local polyCache, polyCount = {}, 0
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
    polyCount = polyCount + 1
    if polyCount > 600 then polyCache, polyCount = {}, 0 end
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
    seg = seg or 24
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

-- dicke Linie als Viereck (im Uhrzeigersinn, sonst zeichnet DrawPoly nichts)
function UI.ThickLine(x1, y1, x2, y2, t)
    t = t or 2
    if t <= 1 then surface.DrawLine(x1, y1, x2, y2) return end
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return end
    local nx, ny = dy / len * t / 2, -dx / len * t / 2
    draw.NoTexture()
    surface.DrawPoly({ { x = x1 + nx, y = y1 + ny }, { x = x2 + nx, y = y2 + ny }, { x = x2 - nx, y = y2 - ny }, { x = x1 - nx, y = y1 - ny } })
end

function UI.Icon(name, x, y, s, col)
    surface.SetDrawColor(col or UI.col.text)
    local t = math.max(2, math.floor(s / 10))
    if name == "close" then
        UI.ThickLine(x + s * 0.25, y + s * 0.25, x + s * 0.75, y + s * 0.75, t)
        UI.ThickLine(x + s * 0.75, y + s * 0.25, x + s * 0.25, y + s * 0.75, t)
    elseif name == "arrow_left" or name == "arrow_right" then
        local dir = name == "arrow_left" and 180 or 0
        local cx, cy = x + s / 2, y + s / 2
        local a1, a2 = math.rad(dir + 140), math.rad(dir - 140)
        local tipx, tipy = cx + math.cos(math.rad(dir)) * s * 0.25, cy
        UI.ThickLine(tipx, tipy, tipx + math.cos(a1) * s * 0.35, tipy + math.sin(a1) * s * 0.35, t)
        UI.ThickLine(tipx, tipy, tipx + math.cos(a2) * s * 0.35, tipy + math.sin(a2) * s * 0.35, t)
    end
end

-- feine Scanlines
function UI.Scanlines(x, y, w, h, alpha, gap)
    gap = gap or 6
    surface.SetDrawColor(0, 0, 0, alpha or 55)
    for yy = y, y + h, gap do surface.DrawRect(x, yy, w, 2) end
end

-- Abschnittstitel (mit Linie und Aurebesh rechts)
function UI.Section(text, x, y, w, col)
    text = string.upper(tostring(text or ""))
    UI.Text(text, "sse.h3", x, y, col or UI.col.text)
    local tw, th = UI.TextSize(text, "sse.h3")
    if w and w > tw + UI.S(20) then
        UI.Box(x + tw + UI.S(10), y + th * 0.55, w - tw - UI.S(10), 1, UI.col.line2)
        UI.Aurebesh(text, "sse.aure.small", x + w, y + th * 0.55 - UI.S(14), UI.Alpha(UI.col.dim, 120), TEXT_ALIGN_RIGHT)
    end
    return th
end

---------------------------------------------------------------------------------------------------------------
-- Anzeigen in der Welt (3D2D) - gleicher Holo-Stil wie die SymChars-Hologramme
---------------------------------------------------------------------------------------------------------------
function UI.WorldPanel(x, y, w, h, col, opts)
    opts = opts or {}
    col = col or UI.Holo()
    UI.Box(x, y, w, h, opts.fill or Color(col.r * 0.12, col.g * 0.18, col.b * 0.25, 170))
    UI.Box(x, y, w, h, Color(4, 8, 14, opts.dark or 150))
    if opts.scanlines ~= false then UI.Scanlines(x, y, w, h, 55, 6) end
    if opts.sweep ~= false then
        local scanY = (CurTime() * 120 + (opts.seed or 0) * 40) % (h + 80) - 40
        if scanY > 0 and scanY < h - 10 then UI.Box(x, y + scanY, w, 10, Color(col.r, col.g, col.b, 30)) end
    end
    UI.Outline(x, y, w, h, Color(col.r, col.g, col.b, 230), opts.border or 3)
    UI.Box(x, y, w, opts.bar or 6, Color(col.r, col.g, col.b, 255))
end

-- Überschrift in der Welt mit Aurebesh-Zeile
function UI.WorldHeading(text, x, y, col, ax, font, aureFont)
    font = font or "sse.world.title"
    local _, th = UI.TextSize("Ag", font)
    UI.Text(string.upper(text or ""), font, x, y, color_white, ax)
    UI.Aurebesh(text, aureFont or "sse.world.aure", x, y + th - 8, Color(col.r, col.g, col.b, 220), ax)
    return th + 22
end

-- Knopf in der Welt (für SSE.Imgui); gibt true zurück, wenn geklickt wurde
function UI.WorldButton(imgui, text, x, y, w, h, col, font)
    col = col or UI.Holo()
    local hovered = imgui.IsHovering(x, y, w, h)
    local pressing = hovered and imgui.IsPressing()
    local clicked = imgui.xButton(x, y, w, h, 0)

    local c = math.floor(h * 0.22)
    UI.Cut(x, y, w, h, pressing and Color(col.r, col.g, col.b, 120) or hovered and Color(col.r * 0.35, col.g * 0.35, col.b * 0.35, 230) or Color(4, 8, 14, 210), c, "tlbr")
    UI.CutOutline(x, y, w, h, Color(col.r, col.g, col.b, hovered and 255 or 150), c, "tlbr")
    if hovered then UI.Box(x + c, y + h - 3, w - c * 2, 3, Color(col.r, col.g, col.b, 255)) end
    UI.Text(string.upper(text or ""), font or "sse.world.button", x + w / 2, y + h / 2, hovered and color_white or Color(215, 228, 238), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    return clicked
end

-- Radar-Fläche (Battlepad, Scanner, Live-Radar)
function UI.WorldRadar(size, col, bg, title, seed)
    col = col or UI.Holo()
    local x, y, w, h = -size, -size, size * 2, size * 2
    UI.WorldPanel(x, y, w, h, col, { fill = bg, seed = seed })

    -- Raster
    local step = w / 8
    for i = 1, 7 do
        local a = (i == 4) and 70 or 25
        UI.Box(x + i * step, y, 1, h, Color(col.r, col.g, col.b, a))
        UI.Box(x, y + i * step, w, 1, Color(col.r, col.g, col.b, a))
    end

    -- Ecken-Markierungen
    local m = math.floor(size * 0.12)
    surface.SetDrawColor(col.r, col.g, col.b, 255)
    for _, p in ipairs({ { x, y, 1, 1 }, { x + w, y, -1, 1 }, { x, y + h, 1, -1 }, { x + w, y + h, -1, -1 } }) do
        surface.DrawRect(p[3] > 0 and p[1] or p[1] - m, p[4] > 0 and p[2] or p[2] - 6, m, 6)
        surface.DrawRect(p[3] > 0 and p[1] or p[1] - 6, p[4] > 0 and p[2] or p[2] - m, 6, m)
    end

    if title then
        UI.Text(string.upper(title), "sse.world.h", x, y - 64, color_white, TEXT_ALIGN_LEFT)
        UI.Aurebesh(title, "sse.world.aure", x + w, y - 40, Color(col.r, col.g, col.b, 200), TEXT_ALIGN_RIGHT)
        UI.Box(x, y - 12, w, 2, Color(col.r, col.g, col.b, 120))
    end
end

-- Punkt auf dem Radar (mit Ring)
function UI.WorldBlip(px, py, col, r)
    r = r or 7
    UI.Circle(px, py, r, col, 16)
    local pulse = (CurTime() * 1.5 + px * 0.01) % 1
    UI.Ring(px, py, r + 4 + pulse * 10, Color(col.r, col.g, col.b, 160 * (1 - pulse)), 2, 20)
end

---------------------------------------------------------------------------------------------------------------
-- Sounds & Helfer
---------------------------------------------------------------------------------------------------------------
UI.sounds = {
    hover = "ui/buttonrollover.wav",
    click = "ui/buttonclickrelease.wav",
    open = "buttons/button24.wav",
}

function UI.Sound(kind)
    local path = UI.sounds[kind]
    if path then surface.PlaySound(path) end
end

function UI.Approach(cur, target, speed)
    return Lerp(math.min(FrameTime() * (speed or 10), 1), cur, target)
end

-- Konsole: "sse_version" zeigt die geladene Version und den Aurebesh-Status
concommand.Add("sse_version", function()
    print("[SSE] Version " .. tostring(SSE.Version))
    atlasMat = nil
    GetAtlas()
end)

print("[SSE] Server-Design geladen (Version " .. tostring(SSE.Version) .. ")")
