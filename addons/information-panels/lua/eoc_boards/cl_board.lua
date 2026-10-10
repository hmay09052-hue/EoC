--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - Info-Tafeln: Zeichnen (Client)
    SymChars-Look: dunkle Platte, feines Raster, Akzent-Ecken, BigNoodle-Überschriften, Aurebesh-Zeile.
    Seiten werden einmal gesetzt und zwischengespeichert - pro Frame wird nur noch gezeichnet.

    Seiten-Aufbau (ENT.Pages im cl_init.lua der Tafel):
        { title = "Überschrift", accent = Color(...) (optional),
          body  = { {"h", "Zwischenüberschrift"}, {"p", "Absatz"}, {"b", "Aufzählung"}, {"c", "zentriert"},
                    {"kv", "Begriff", "Erklärung"}, {"gap", 20} },
          draw  = function(B, ent, x, y, w, h, accent) end,   -- eigene Grafik (optional)
          split = 0.42 }                                       -- Anteil der Grafik, wenn draw UND body
-------------------------------------------------------------------------------------------------------------]]

local B = EOC_BOARD
local floor = math.floor

local FACE = { head = "BigNoodleTitling", body = "Roboto Condensed", aure = "Aurebesh" }

local function Font(name, face, size, weight)
    surface.CreateFont(name, { font = face, size = size, weight = weight or 500, antialias = true, extended = true })
end

Font("eocboard.label",  FACE.body, 30, 800)
Font("eocboard.title",  FACE.head, 80)
Font("eocboard.aure",   FACE.aure, 24)
Font("eocboard.btn",    FACE.head, 46)
Font("eocboard.hint",   FACE.body, 28, 600)
Font("eocboard.big",    FACE.head, 120)
Font("eocboard.mark",   FACE.head, 54)
-- zwei Größen für den Fließtext: normal und kompakt (für volle Seiten)
Font("eocboard.h",      FACE.head, 60)
Font("eocboard.p",      FACE.body, 42, 500)
Font("eocboard.pb",     FACE.body, 42, 800)
Font("eocboard.h.c",    FACE.head, 50)
Font("eocboard.p.c",    FACE.body, 35, 500)
Font("eocboard.pb.c",   FACE.body, 35, 800)

B.col = {
    plate = Color(8, 10, 13),
    head  = Color(15, 18, 23),
    card  = Color(20, 24, 30),
    grid  = Color(255, 255, 255, 5),
    line  = Color(255, 255, 255, 24),
    text  = Color(236, 233, 224),
    dim   = Color(168, 174, 180),
    muted = Color(112, 119, 127),
    steel = Color(80, 170, 230),
    ink   = Color(12, 14, 18),
}
local COL = B.col

function B.Accent(a)
    local c = (SYMUI and SYMUI.Accent and SYMUI.Accent()) or Color(252, 178, 73)
    return Color(c.r, c.g, c.b, a or 255)
end

---------------------------------------------------------------------------------------------------------------
-- Grundformen
---------------------------------------------------------------------------------------------------------------
function B.Rect(x, y, w, h, c)
    surface.SetDrawColor(c.r, c.g, c.b, c.a or 255)
    surface.DrawRect(floor(x), floor(y), floor(w), floor(h))
end
local Rect = B.Rect

function B.Outline(x, y, w, h, c, t)
    t = t or 3
    Rect(x, y, w, t, c) Rect(x, y + h - t, w, t, c)
    Rect(x, y + t, t, h - t * 2, c) Rect(x + w - t, y + t, t, h - t * 2, c)
end

function B.Corners(x, y, w, h, c, len, t)
    len, t = len or 40, t or 5
    Rect(x, y, len, t, c) Rect(x, y, t, len, c)
    Rect(x + w - len, y, len, t, c) Rect(x + w - t, y, t, len, c)
    Rect(x, y + h - t, len, t, c) Rect(x, y + h - len, t, len, c)
    Rect(x + w - len, y + h - t, len, t, c) Rect(x + w - t, y + h - len, t, len, c)
end

function B.Text(text, font, x, y, c, ax, ay)
    draw.SimpleText(text, font, floor(x), floor(y), c, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
end

function B.TextSize(text, font)
    surface.SetFont(font)
    return surface.GetTextSize(text)
end

-- Kennzeichnungs-Quadrat (Formationen, Legenden)
function B.Marker(x, y, s, c, label)
    Rect(x, y, s, s, Color(c.r, c.g, c.b, 40))
    B.Outline(x, y, s, s, c, math.max(3, floor(s / 22)))
    Rect(x + s * 0.3, y + s * 0.3, s * 0.4, s * 0.4, c)
    if label then B.Text(label, "eocboard.hint", x + s / 2, y + s + 8, COL.dim, TEXT_ALIGN_CENTER) end
end

local AUREBESH_OK
local function Aurebesh(text)
    if AUREBESH_OK == nil then
        AUREBESH_OK = B.TextSize("ABCDEFGHIJ", "eocboard.aure") ~= B.TextSize("ABCDEFGHIJ", "eocboard.hint")
    end
    return AUREBESH_OK and string.upper(text) or nil
end

---------------------------------------------------------------------------------------------------------------
-- Textsatz
---------------------------------------------------------------------------------------------------------------
local function Wrap(text, font, maxW)
    surface.SetFont(font)
    local lines, line = {}, ""
    for word in string.gmatch(text, "%S+") do
        local try = line == "" and word or line .. " " .. word
        if line ~= "" and surface.GetTextSize(try) > maxW then
            lines[#lines + 1] = line
            line = word
        else
            line = try
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

local TIERS = {
    { h = "eocboard.h",   p = "eocboard.p",   pb = "eocboard.pb",   lh = 56, hh = 74, bullet = 12 },
    { h = "eocboard.h.c", p = "eocboard.p.c", pb = "eocboard.pb.c", lh = 47, hh = 62, bullet = 10 },
}

-- Setzt eine Seite in eine Spalte der Breite maxW. Gibt Zeichen-Befehle, Breite und Höhe zurück.
local function Layout(body, tier, maxW)
    local ops, y, natW = {}, 0, 0
    local indent = tier.bullet * 3

    -- Breite der Begriffs-Spalte für "kv"-Zeilen
    local keyW = 0
    for _, it in ipairs(body) do
        if it[1] == "kv" then keyW = math.max(keyW, B.TextSize(it[2], tier.pb)) end
    end
    keyW = math.min(keyW + 40, maxW * 0.45)

    for i, it in ipairs(body) do
        local kind = it[1]
        if kind == "gap" then
            y = y + (it[2] or 20)
        elseif kind == "h" then
            if i > 1 then y = y + 14 end
            ops[#ops + 1] = { "h", it[2], 0, y }
            natW = math.max(natW, B.TextSize(it[2], tier.h))
            y = y + tier.hh
        elseif kind == "p" or kind == "c" or kind == "b" then
            local off = kind == "b" and indent or 0
            local lines = Wrap(it[2], tier.p, maxW - off)
            for n, line in ipairs(lines) do
                ops[#ops + 1] = { kind, line, off, y, n == 1 }
                natW = math.max(natW, off + B.TextSize(line, tier.p))
                y = y + tier.lh
            end
            if kind == "b" then y = y + 8 end
        elseif kind == "kv" then
            local lines = Wrap(it[3], tier.p, maxW - keyW)
            ops[#ops + 1] = { "k", it[2], 0, y }
            for _, line in ipairs(lines) do
                ops[#ops + 1] = { "v", line, keyW, y }
                natW = math.max(natW, keyW + B.TextSize(line, tier.p))
                y = y + tier.lh
            end
            y = y + 4
        end
    end
    return ops, math.min(natW, maxW), y
end

local cache = {}

local function GetLayout(ent, index, body, maxW, maxH)
    local key = ent:GetClass() .. "#" .. index .. "#" .. floor(maxW)
    local c = cache[key]
    if c then return c end
    for t, tier in ipairs(TIERS) do
        local ops, w, h = Layout(body, tier, maxW)
        if h <= maxH or t == #TIERS then
            c = { ops = ops, w = w, h = h, tier = tier }
            break
        end
    end
    cache[key] = c
    return c
end

local function DrawBody(lay, x, y, w, h, accent)
    local tier = lay.tier
    local bx = x + floor((w - lay.w) / 2)
    local by = y + floor((h - lay.h) / 2)
    for _, op in ipairs(lay.ops) do
        local kind, text, ox, oy = op[1], op[2], op[3], op[4]
        if kind == "h" then
            B.Text(text, tier.h, bx, by + oy, accent)
        elseif kind == "p" then
            B.Text(text, tier.p, bx + ox, by + oy, COL.text)
        elseif kind == "c" then
            B.Text(text, tier.p, bx + lay.w / 2, by + oy, COL.dim, TEXT_ALIGN_CENTER)
        elseif kind == "b" then
            if op[5] then
                local s = tier.bullet
                Rect(bx + s * 0.5, by + oy + tier.lh / 2 - s / 2 - 2, s, s, accent)
            end
            B.Text(text, tier.p, bx + ox, by + oy, COL.text)
        elseif kind == "k" then
            B.Text(text, tier.pb, bx, by + oy, accent)
        elseif kind == "v" then
            B.Text(text, tier.p, bx + ox, by + oy, COL.text)
        end
    end
end

---------------------------------------------------------------------------------------------------------------
-- Tafel
---------------------------------------------------------------------------------------------------------------
local function Button(r, label, enabled, hovered, accent)
    local c = enabled and (hovered and accent or COL.dim) or Color(COL.muted.r, COL.muted.g, COL.muted.b, 90)
    Rect(r.x, r.y, r.w, r.h, hovered and enabled and Color(accent.r, accent.g, accent.b, 36) or COL.card)
    B.Outline(r.x, r.y, r.w, r.h, c, 3)
    B.Text(label, "eocboard.btn", r.x + r.w / 2, r.y + r.h / 2 + 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function B.Paint(ent, cx, cy)
    local W, H = ent.BoardW, ent.BoardH
    local x0, y0 = -W / 2, -H / 2
    local pages = ent.Pages or {}
    local max = math.min(#pages, B.PageCount(ent))
    if max < 1 then return end
    local index = math.Clamp(floor(ent:GetPage()), 1, max)
    local page = pages[index]
    local accent = page.accent or B.Accent()

    -- Platte + Raster
    Rect(x0, y0, W, H, COL.plate)
    for gx = x0 + 60, x0 + W - 1, 60 do Rect(gx, y0 + B.Head, 2, H - B.Head - B.Foot, COL.grid) end
    for gy = y0 + B.Head + 60, y0 + H - B.Foot - 1, 60 do Rect(x0, gy, W, 2, COL.grid) end

    -- Kopfzeile
    Rect(x0, y0, W, B.Head, COL.head)
    Rect(x0, y0 + B.Head - 5, W, 5, accent)
    Rect(x0, y0, 16, B.Head - 5, accent)
    B.Text(string.upper(ent.BoardLabel or ent.PrintName or ""), "eocboard.label", x0 + 56, y0 + 18, accent)
    B.Text(page.title or "", "eocboard.title", x0 + 54, y0 + 44, COL.text)

    local rightX = x0 + W - 50
    local logo = EOCSB and EOCSB.Logo and EOCSB.Logo()
    if logo and not logo:IsError() and logo:Height() > 0 then
        local lh = B.Head - 44
        local lw = floor(lh * logo:Width() / logo:Height())
        surface.SetDrawColor(255, 255, 255, 235)
        surface.SetMaterial(logo)
        surface.DrawTexturedRect(rightX - lw, y0 + 20, lw, lh)
        rightX = rightX - lw - 40
    end
    local aure = Aurebesh(page.title or "")
    if aure then B.Text(aure, "eocboard.aure", rightX, y0 + B.Head / 2, COL.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end

    -- Fußzeile
    local fy = y0 + H - B.Foot
    Rect(x0, fy, W, B.Foot, COL.head)
    Rect(x0, fy, W, 3, COL.line)
    if max > 1 then
        local prev, nxt = B.Buttons(ent)
        local hit = cx and B.HitTest(ent, cx, cy)
        Button(prev, "ZURÜCK", index > 1, hit == -1, accent)
        Button(nxt, "WEITER", true, hit == 1, accent)

        local dot, gap = 16, 12
        local total = max * dot + (max - 1) * gap
        local dx = -total / 2
        for i = 1, max do
            Rect(dx, fy + 30, dot, dot, i == index and accent or COL.line)
            dx = dx + dot + gap
        end
        B.Text(("SEITE %d / %d  ·  [E] ZUM BLÄTTERN"):format(index, max), "eocboard.hint", 0, fy + 62, COL.muted, TEXT_ALIGN_CENTER)
    end

    B.Corners(x0, y0, W, H, accent, 46, 6)

    -- Inhalt
    local ax, ay = x0 + 80, y0 + B.Head + 36
    local aw, ah = W - 160, H - B.Head - B.Foot - 72
    if page.draw and page.body then
        local gw = floor(aw * (page.split or 0.42))
        page.draw(B, ent, ax, ay, gw, ah, accent)
        Rect(ax + gw + 30, ay + 20, 3, ah - 40, COL.line)
        DrawBody(GetLayout(ent, index, page.body, aw - gw - 120, ah), ax + gw + 90, ay, aw - gw - 90, ah, accent)
    elseif page.draw then
        page.draw(B, ent, ax, ay, aw, ah, accent)
    elseif page.body then
        DrawBody(GetLayout(ent, index, page.body, math.min(aw, 1600), ah), ax, ay, aw, ah, accent)
    end
end

local DRAW_DIST, FADE = 1000, 160
local LIFT = Vector(0, 0, 2.5)
local TURN = Angle(0, 90, 0)

-- Gemeinsames ENT:Draw
function B.Draw(ent)
    ent:DrawModel()

    local eye = EyePos()
    local pos = ent:LocalToWorld(LIFT)
    local ang = ent:LocalToWorldAngles(TURN)
    local dist = eye:Distance(pos)
    if dist > DRAW_DIST then return end
    if (eye - pos):Dot(ang:Up()) <= 0 then return end -- Rückseite: nichts zeichnen

    local cx, cy
    local lp = LocalPlayer()
    if dist < 260 and IsValid(lp) then
        local tr = lp:GetEyeTrace()
        if tr.Entity == ent then cx, cy = B.ToBoard(ent, tr.HitPos) end
    end

    local alpha = math.Clamp((DRAW_DIST - dist) / FADE, 0, 1)
    cam.Start3D2D(pos, ang, B.Scale)
        surface.SetAlphaMultiplier(alpha)
        B.Paint(ent, cx, cy)
        surface.SetAlphaMultiplier(1)
    cam.End3D2D()
end
