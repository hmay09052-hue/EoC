--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Design im Stil des Servers (SymChars)
    Schwarze Kopfleiste mit grossen Reitern, Bernstein-Akzent aus der SymChars-Config, cremefarbene Etiketten,
    abgeschraegte Platten, Karten mit Bernstein-Glow und Randmarkierungen, Aurebesh unter den Beschriftungen.
    Farben und Akzent kommen direkt aus SymChars; skaliert wird auf den Tablet-Bildschirm.
-------------------------------------------------------------------------------------------------------------]]

GAR_DP.ui = GAR_DP.ui or {}
local D = GAR_DP.ui
local SU = symchars.ui
local CFG = GAR_DP.Config

D.BASE_H = 760
D.k = D.k or 1

function D.S(px)
    return math.max(1, math.floor(px * D.k + 0.5))
end
local S = D.S

---------------------------------------------------------------------------------------------------------------
-- Farben (aus SymChars)
---------------------------------------------------------------------------------------------------------------
D.col = setmetatable({ glass = Color(9, 11, 14, 236) }, { __index = SU.col })

function D.Accent(alpha) return SU.Accent(alpha) end
function D.Holo(alpha) return SU.Holo and SU.Holo(alpha) or Color(90, 190, 255, alpha or 255) end
function D.Alpha(col, a) return Color(col.r, col.g, col.b, a) end
D.Lerp = SU.Lerp
D.Approach = SU.Approach
D.Ease = SU.Ease
D.Gradient = SU.Gradient
D.Circle = SU.Circle
D.Ring = SU.Ring
D.Arc = SU.Arc
D.Glow = SU.Glow
D.Cut = SU.Cut
D.CutOutline = SU.CutOutline
D.TextSize = SU.TextSize
D.Trim = SU.Trim
D.Text = SU.Text
D.TextFit = SU.TextFit
D.Wrap = SU.Wrap
D.ToAurebesh = SU.ToAurebesh
D.ThickLine = SU.ThickLine

function D.Readable(col)
    if SU.Readable then return SU.Readable(col) end
    return col
end

function D.Box(x, y, w, h, col)
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, w, h)
end

function D.Outline(x, y, w, h, col, thick)
    surface.SetDrawColor(col)
    for i = 0, (thick or 1) - 1 do surface.DrawOutlinedRect(x + i, y + i, w - i * 2, h - i * 2) end
end

-- Text auf farbiger Flaeche: hell oder dunkel je nach Helligkeit
function D.OnColor(col)
    local lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
    return lum > 140 and D.col.ink or D.col.text
end

---------------------------------------------------------------------------------------------------------------
-- Klaenge
---------------------------------------------------------------------------------------------------------------
-- gleiche Klaenge wie das Charaktermenue
function D.Sound(kind)
    if kind == "back" then kind = "click" end
    SU.Sound(kind)
end

---------------------------------------------------------------------------------------------------------------
-- Schriften
---------------------------------------------------------------------------------------------------------------
local fontK
function D.SetScale(h)
    D.k = math.Clamp(h / D.BASE_H, 0.45, 2)
    if fontK and math.abs(fontK - D.k) < 0.01 then return end
    fontK = D.k
    local f = CFG.Fonts or {}
    local head, body, mono = f.head or "BigNoodleTitling", f.body or "Roboto Condensed", f.mono or "Courier New"
    local function Font(name, face, size, weight)
        surface.CreateFont(name, { font = face, size = math.max(8, S(size)), weight = weight or 500, antialias = true, extended = true })
    end
    Font("gdp.big", head, 62)
    Font("gdp.h1", head, 40)
    Font("gdp.h2", head, 30)
    Font("gdp.h3", head, 24)
    Font("gdp.h4", head, 19)
    Font("gdp.name", body, 28, 700)
    Font("gdp.body", body, 19, 500)
    Font("gdp.body.b", body, 19, 800)
    Font("gdp.input", body, 19, 500)
    Font("gdp.small", body, 16, 500)
    Font("gdp.small.b", body, 16, 800)
    Font("gdp.tiny", body, 13, 500)
    Font("gdp.tiny.b", body, 13, 800)
    Font("gdp.mono", mono, 15, 600)
    Font("gdp.mono.small", mono, 12, 600)
    Font("gdp.map", body, 14, 700)
    Font("gdp.map.small", body, 12, 600)
    Font("gdp.map.region", head, 26)
end
D.SetScale(D.BASE_H)

---------------------------------------------------------------------------------------------------------------
-- Aurebesh (ueber SymChars; Bild-Atlas, braucht keine Schrift)
---------------------------------------------------------------------------------------------------------------
local AURE_FONTS = { ["gdp.aure.small"] = "symchars.aure.small", ["gdp.aure"] = "symchars.aure", ["gdp.aure.big"] = "symchars.aure.big" }

function D.Aurebesh(text, font, x, y, col, ax, ay, maxW)
    SU.Aurebesh(text, AURE_FONTS[font or "gdp.aure"] or "symchars.aure", x, y, col or D.Alpha(D.col.dim, 130), ax, ay, maxW)
end

function D.AurebeshHeight(font)
    local f = AURE_FONTS[font or "gdp.aure"] or "symchars.aure"
    if SU.AurebeshHeight then return SU.AurebeshHeight(f) end
    local _, h = D.TextSize("A", f)
    return h
end

---------------------------------------------------------------------------------------------------------------
-- Formen
---------------------------------------------------------------------------------------------------------------
-- kleine Ecken (fuer Auswahl / Fokus)
function D.Brackets(x, y, w, h, col, len, thick)
    len = len or S(10)
    thick = thick or S(2)
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, len, thick) surface.DrawRect(x, y, thick, len)
    surface.DrawRect(x + w - len, y, len, thick) surface.DrawRect(x + w - thick, y, thick, len)
    surface.DrawRect(x, y + h - thick, len, thick) surface.DrawRect(x, y + h - len, thick, len)
    surface.DrawRect(x + w - len, y + h - thick, len, thick) surface.DrawRect(x + w - thick, y + h - len, thick, len)
end

-- schraege Streifen (gesperrt)
function D.Hatch(x, y, w, h, col, gap)
    gap = gap or S(10)
    surface.SetDrawColor(col)
    for sx = x - h, x + w, gap do
        local x1, y1, x2, y2 = sx, y + h, sx + h, y
        if x1 < x then y1 = y1 - (x - x1) x1 = x end
        if x2 > x + w then y2 = y2 + (x2 - x - w) x2 = x + w end
        if x2 > x1 then surface.DrawLine(x1, y1, x2, y2) end
    end
end

-- Randmarkierungen rechts an Karten (wie die Charakterkarten)
function D.EdgeMarks(x, y, h, col)
    local cy = y + S(6)
    local pattern = { 2, 0, 1, 1, 0, 2, 1 }
    for _, kind in ipairs(pattern) do
        if cy > y + h - S(10) then break end
        if kind == 1 then
            D.Box(x, cy, S(3), S(14), col)
            cy = cy + S(20)
        elseif kind == 2 then
            D.Outline(x - 1, cy, S(5), S(5), D.Alpha(col, 140))
            cy = cy + S(10)
        else
            D.Box(x, cy, S(3), S(4), col)
            cy = cy + S(10)
        end
    end
end

-- cremefarbenes Etikett ("AKTE"), gibt Breite und Hoehe zurueck
function D.Tag(text, x, y)
    local label = string.upper(text)
    local tw = D.TextSize(label, "gdp.h4")
    local w, h = tw + S(26), S(26)
    D.Cut(x, y, w, h, D.col.cream, S(8), "br")
    D.Text(label, "gdp.h4", x + S(10), y + h / 2, D.col.ink, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    return w, h
end

-- Platte wie im Charaktermenue: dunkle Flaeche, feiner Rahmen, abgeschraegte Ecken, optional Etikett
function D.Frame(x, y, w, h, opts)
    opts = opts or {}
    local c = opts.cut or S(14)
    D.Cut(x, y, w, h, opts.fill or D.col.panel, c, "tlbr")
    D.CutOutline(x, y, w, h, opts.stroke or D.col.line2, c, "tlbr")
    if opts.title then
        local tw = D.Tag(opts.title, x + S(14), y + S(12))
        D.Aurebesh(opts.title, "gdp.aure.small", x + S(22) + tw, y + S(19), D.Alpha(D.col.dim, 110))
    end
end

function D.Panel(x, y, w, h, opts)
    opts = opts or {}
    D.Frame(x, y, w, h, { fill = opts.fill, title = opts.title, cut = S(10) })
end

---------------------------------------------------------------------------------------------------------------
-- Text-Helfer
---------------------------------------------------------------------------------------------------------------
-- Grosse Ueberschrift + Aurebesh darunter (wie die Reiter im Menue). Gibt die Gesamthoehe zurueck.
function D.Heading(text, font, x, y, col, ax, maxW)
    font = font or "gdp.h2"
    local label = string.upper(tostring(text or ""))
    local _, h = D.TextSize("Ag", font)
    if maxW then D.TextFit(label, font, x, y, col or D.col.text, maxW, ax) else D.Text(label, font, x, y, col or D.col.text, ax) end
    local aure = h > S(30) and "gdp.aure" or "gdp.aure.small"
    D.Aurebesh(text, aure, x + (ax and 0 or S(2)), y + h - S(6), D.Alpha(col or D.col.text, 130), ax, nil, maxW)
    return h + D.AurebeshHeight(aure)
end

-- Abschnittstitel: Titel, Linie nach rechts, Aurebesh rechts ueber der Linie (wie "AKTE" / "SPIELZEIT")
function D.Section(text, x, y, w, col)
    local label = string.upper(text)
    D.Text(label, "gdp.h3", x, y, col or D.col.text)
    local tw, th = D.TextSize(label, "gdp.h3")
    if w then
        D.Box(x + tw + S(10), y + th * 0.55, math.max(0, w - tw - S(10)), 1, D.col.line2)
        D.Aurebesh(text, "gdp.aure.small", x + w, y + th * 0.55 - S(14), D.Alpha(D.col.dim, 120), TEXT_ALIGN_RIGHT)
    end
    return th + S(8)
end

-- Abschnitt mit senkrechtem Strich (wie "DIENST", "STATISTIK", "BESCHREIBUNG")
function D.Bar(text, x, y)
    local label = string.upper(text)
    local tw, th = D.TextSize(label, "gdp.h3")
    D.Box(x, y, S(3), th + S(4), D.col.line3)
    D.Text(label, "gdp.h3", x + S(12), y + S(2), D.col.text)
    D.Aurebesh(text, "gdp.aure.small", x + S(20) + tw, y + th * 0.5, D.Alpha(D.col.dim, 100), nil, TEXT_ALIGN_CENTER)
    return th + S(12)
end

function D.DrawWrapped(text, font, x, y, maxW, col, maxLines, gap)
    local lines = D.Wrap(text, font, maxW)
    local _, lh = D.TextSize("Ag", font)
    lh = lh + (gap or 0)
    for i, line in ipairs(lines) do
        if maxLines and i > maxLines then break end
        if maxLines and i == maxLines and #lines > maxLines then line = D.Trim(line .. " …", font, maxW) end
        draw.SimpleText(line, font, x, y + (i - 1) * lh, col or D.col.text)
    end
    return math.min(#lines, maxLines or #lines) * lh
end

-- gefuellter Chip (wie "501ST" / "CAPTAIN" / "AKTIV")
function D.ChipSize(text, font)
    local tw, th = D.TextSize(string.upper(tostring(text)), font or "gdp.tiny.b")
    return tw + S(14), th + S(6)
end

function D.Chip(text, x, y, color, bg, outline, font)
    font = font or "gdp.tiny.b"
    color = color or D.Accent()
    text = string.upper(tostring(text))
    local pw, ph = D.ChipSize(text, font)
    D.Cut(x, y, pw, ph, bg or D.Alpha(color, 235), S(4), "tlbr")
    if outline then D.CutOutline(x, y, pw, ph, outline, S(4), "tlbr") end
    D.Text(text, font, x + pw / 2, y + ph / 2, bg and color or D.OnColor(color), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return pw, ph
end

function D.LevelChip(level, x, y, short)
    local data = GAR_DP.LevelData(level)
    return D.Chip(short and ("S" .. data.level) or ("Stufe " .. data.level), x, y, data.color)
end

-- Feld wie in der Akte: BESCHRIFTUNG ....... (gepunktet), Wert darunter. Gibt die Hoehe zurueck.
function D.KeyValue(label, value, x, y, w, valueCol, valueFont)
    local lab = string.upper(label)
    D.Text(lab, "gdp.tiny.b", x, y, D.col.dim)
    local lw, lh = D.TextSize(lab, "gdp.tiny.b")
    surface.SetDrawColor(255, 255, 255, 34)
    for dx = x + lw + S(8), x + w - S(2), S(5) do surface.DrawRect(dx, y + lh * 0.6, S(2), 1) end
    D.TextFit(tostring(value or "-"), valueFont or "gdp.body", x, y + lh - S(1), valueCol or D.col.text, w)
    local _, vh = D.TextSize("Ag", valueFont or "gdp.body")
    return lh + vh + S(6)
end

function D.Redacted(x, y, w, h, seed)
    local state = (seed or 1) * 9301 + 49297
    local cx = x
    while cx < x + w do
        state = (state * 9301 + 49297) % 233280
        local bw = math.min(S(20) + math.floor(state / 233280 * S(50)), x + w - cx)
        D.Box(cx, y, bw, h, Color(0, 0, 0, 240))
        cx = cx + bw + S(5)
    end
end

---------------------------------------------------------------------------------------------------------------
-- Icons
---------------------------------------------------------------------------------------------------------------
local Line = D.ThickLine

function D.Icon(name, x, y, s, col)
    col = col or D.col.text
    surface.SetDrawColor(col)
    draw.NoTexture()
    local t = math.max(2, math.floor(s / 10))
    local cx, cy = x + s / 2, y + s / 2

    if name == "planet" then
        D.Circle(cx, cy, s * 0.26, col, 24)
        local lx, ly
        for a = 0, 360, 15 do
            local r = math.rad(a)
            local px = cx + math.cos(r) * s * 0.46
            local py = cy + math.sin(r) * s * 0.14 - math.cos(r) * s * 0.1
            if lx then Line(lx, ly, px, py, math.max(1, t - 1)) end
            lx, ly = px, py
        end
    elseif name == "republic" then
        D.Ring(cx, cy, s * 0.46, col, t, 32)
        D.Circle(cx, cy, s * 0.12, col, 16)
        for i = 0, 5 do
            local a = math.rad(i * 60 - 90)
            local a1, a2 = a - 0.16, a + 0.16
            surface.DrawPoly({
                { x = cx + math.cos(a1) * s * 0.18, y = cy + math.sin(a1) * s * 0.18 },
                { x = cx + math.cos(a) * s * 0.4, y = cy + math.sin(a) * s * 0.4 },
                { x = cx + math.cos(a2) * s * 0.18, y = cy + math.sin(a2) * s * 0.18 },
            })
        end
    elseif name == "back" then
        Line(x + s * 0.62, y + s * 0.18, x + s * 0.3, cy, t + 1)
        Line(x + s * 0.3, cy, x + s * 0.62, y + s * 0.82, t + 1)
    elseif name == "minus" then
        surface.DrawRect(x + s * 0.2, cy - t / 2, s * 0.6, t)
    elseif name == "folder" then
        D.Cut(x + s * 0.1, y + s * 0.24, s * 0.36, s * 0.14, col, s * 0.06, "tr")
        D.Box(x + s * 0.1, y + s * 0.34, s * 0.8, s * 0.48, col)
    elseif name == "key" then
        D.Ring(x + s * 0.32, cy, s * 0.18, col, t, 18)
        surface.DrawRect(x + s * 0.48, cy - t / 2, s * 0.42, t)
        surface.DrawRect(x + s * 0.72, cy, t, s * 0.16)
        surface.DrawRect(x + s * 0.84, cy, t, s * 0.12)
    elseif name == "target" then
        D.Ring(cx, cy, s * 0.4, col, t, 28)
        D.Ring(cx, cy, s * 0.2, col, t, 20)
        surface.DrawRect(cx - t / 2, y, t, s * 0.18)
        surface.DrawRect(cx - t / 2, y + s * 0.82, t, s * 0.18)
        surface.DrawRect(x, cy - t / 2, s * 0.18, t)
        surface.DrawRect(x + s * 0.82, cy - t / 2, s * 0.18, t)
    elseif name == "home" then
        surface.DrawPoly({ { x = cx, y = y + s * 0.12 }, { x = x + s * 0.9, y = y + s * 0.5 }, { x = x + s * 0.1, y = y + s * 0.5 } })
        D.Box(x + s * 0.22, y + s * 0.5, s * 0.56, s * 0.36, col)
    elseif name == "power" then
        D.Arc(cx, cy + s * 0.04, s * 0.34, t, -50, 230, col, 20)
        surface.DrawRect(cx - t / 2, y + s * 0.08, t, s * 0.42)
    else
        SU.Icon(name, x, y, s, col)
    end
end

---------------------------------------------------------------------------------------------------------------
-- Charakter-Helfer
---------------------------------------------------------------------------------------------------------------
function D.CharName(char)
    if isnumber(char) then char = symchars.chars.Get(char) end
    if not char then return "Unbekannt" end
    return symchars.utils.BuildDisplayName(char)
end

function D.CharRank(char)
    local rank = char and char:GetRankData()
    return rank and rank.name or "", rank and D.Readable(rank.color) or D.col.dim
end

function D.CharUnit(char)
    local f = char and char:GetFaction()
    return f and f.name or "Keine Einheit", f and D.Readable(f:GetColor()) or D.col.dim
end

function D.LocalChar()
    local lp = LocalPlayer()
    return IsValid(lp) and lp:GetCharacter() or nil
end

function D.AllChars(filter)
    local out = {}
    for _, char in pairs(symchars.chars.All()) do
        if char:IsActive() and (not filter or filter(char)) then out[#out + 1] = char end
    end
    table.sort(out, function(a, b)
        local oa, ob = a:IsOnline(), b:IsOnline()
        if oa ~= ob then return oa end
        local fa, fb = a.faction or "", b.faction or ""
        if fa ~= fb then return fa < fb end
        if a:GetRank() ~= b:GetRank() then return a:GetRank() > b:GetRank() end
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)
    return out
end

function D.MatchChar(char, query)
    if query == "" then return true end
    local hay = string.lower(D.CharName(char) .. " " .. (char.roleplayID or "") .. " " .. D.CharUnit(char) .. " " .. D.CharRank(char) .. " " .. tostring(char.charUser or ""))
    return string.find(hay, query, 1, true) ~= nil
end

---------------------------------------------------------------------------------------------------------------
-- Anfragen an den Server
---------------------------------------------------------------------------------------------------------------
local pending, nextRid = {}, 0

function GAR_DP.Request(action, data, callback)
    nextRid = nextRid + 1
    data = data or {}
    data.rid = nextRid
    pending[nextRid] = { cb = callback, t = RealTime() }
    symchars.net.SendToServer("gdp_" .. action, data)
end

symchars.net.Receive("gdp_reply", function(data)
    if not istable(data) then return end
    local p = pending[tonumber(data.rid) or -1]
    if not p then return end
    pending[data.rid] = nil
    if not data.ok then
        GAR_DP.Notify(data.err or "Fehler", "error")
        if p.cb then p.cb(nil, data.err) end
        return
    end
    if p.cb then p.cb(data.data or {}) end
end)

timer.Create("gar_datapad_pending", 10, 0, function()
    for rid, p in pairs(pending) do
        if RealTime() - p.t > 30 then pending[rid] = nil end
    end
end)

GAR_DP.galaxyState = GAR_DP.galaxyState or {}

symchars.net.Receive("gdp_manual", function(list)
    GAR_DP.manual = {}
    for _, m in ipairs(istable(list) and list or {}) do
        GAR_DP.manual[tonumber(m.id)] = { level = tonumber(m.level), by = m.by, at = m.at }
    end
    hook.Run("gar_datapad_manual")
end)

symchars.net.Receive("gdp_galaxy", function(list)
    GAR_DP.galaxyState = {}
    for _, s in ipairs(istable(list) and list or {}) do
        GAR_DP.galaxyState[s.planet] = { status = s.status, note = s.note, by = s.by, at = s.at }
    end
    hook.Run("gar_datapad_galaxy")
end)

function GAR_DP.Notify(text, kind)
    if IsValid(GAR_DP.tablet) and GAR_DP.tablet.Toast then
        GAR_DP.tablet:Toast(text, kind)
        return
    end
    local col = kind == "error" and D.col.red or kind == "warn" and D.col.yellow or D.Accent()
    chat.AddText(col, "[Datapad] ", color_white, tostring(text))
    surface.PlaySound(kind == "error" and "buttons/button10.wav" or "buttons/blip1.wav")
end

symchars.net.Receive("gdp_notify", function(data)
    if istable(data) then GAR_DP.Notify(data.text, data.kind) end
end)
