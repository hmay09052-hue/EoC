--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - TAB-Menü: Design
    Farben und Schriften kommen aus SymChars (global SYMUI) - nichts davon wird kopiert, nur benutzt.
    Gezeichnet wird bewusst nur mit exakten Rechtecken auf ganzen Pixeln (keine schrägen Polygone, keine
    halbtransparenten Flächen übereinander) - so bleibt alles in jeder Auflösung scharf.
    Aurebesh wird als echte Schrift gezeichnet, sobald sie beim Spieler installiert ist.
-------------------------------------------------------------------------------------------------------------]]

local CFG = EOCSB.Config

EOCSB.D = EOCSB.D or {}
local D = EOCSB.D
local floor = math.floor

function EOCSB.HasDesign()
    local UI = SYMUI or (symchars and symchars.ui)
    if UI and UI.col and UI.Accent and UI.S then EOCSB.UI = UI return true end
    return false
end

local function UI() return EOCSB.UI end

function D.S(px)
    return math.max(1, floor(px * ScrH() / 1080 + 0.5))
end
local S = D.S

---------------------------------------------------------------------------------------------------------------
-- Farben (aus SymChars)
---------------------------------------------------------------------------------------------------------------
function D.Accent(a)
    local c = UI().Accent()
    if a then return Color(c.r, c.g, c.b, a) end
    return c
end

function D.Col(key) return UI().col[key] end

function D.Alpha(c, a) return Color(c.r, c.g, c.b, a) end

function D.Lerp(t, a, b)
    return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b), Lerp(t, a.a or 255, b.a or 255))
end

function D.Readable(c, minLum)
    return UI().Readable and UI().Readable(c, minLum) or c
end

function D.Approach(cur, target, speed)
    return Lerp(math.min(FrameTime() * (speed or 12), 1), cur or 0, target)
end

function D.Sound(kind)
    if UI().Sound then UI().Sound(kind) end
end

-- deckende Flächen (kein Durchscheinen, kein Milchglas)
D.fill = {
    bar   = Color(4, 5, 7, 250),
    row   = Color(13, 16, 20, 238),
    row2  = Color(17, 20, 25, 238),
    hover = Color(26, 31, 38, 245),
    card  = Color(14, 17, 22, 240),
    frame = Color(9, 11, 14, 252),
    btn   = Color(20, 24, 30, 245),
    btnH  = Color(30, 36, 44, 250),
}

---------------------------------------------------------------------------------------------------------------
-- Grundformen auf ganzen Pixeln
---------------------------------------------------------------------------------------------------------------
function D.Box(x, y, w, h, col)
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    surface.DrawRect(floor(x), floor(y), floor(w), floor(h))
end

function D.Outline(x, y, w, h, col, t)
    t = t or 1
    x, y, w, h = floor(x), floor(y), floor(w), floor(h)
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    surface.DrawRect(x, y, w, t)
    surface.DrawRect(x, y + h - t, w, t)
    surface.DrawRect(x, y + t, t, h - t * 2)
    surface.DrawRect(x + w - t, y + t, t, h - t * 2)
end

-- Ecken-Markierung (gerade Winkel statt schräger Schnitt, wirkt wie die SymChars-Platten)
function D.Corners(x, y, w, h, col, len, t)
    len, t = len or S(10), t or S(2)
    D.Box(x, y, len, t, col) D.Box(x, y, t, len, col)
    D.Box(x + w - len, y + h - t, len, t, col) D.Box(x + w - t, y + h - len, t, len, col)
end

function D.Text(text, font, x, y, col, ax, ay)
    draw.SimpleText(tostring(text or ""), font, floor(x), floor(y), col, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
end

function D.TextSize(text, font)
    surface.SetFont(font)
    return surface.GetTextSize(tostring(text or ""))
end

function D.Trim(text, font, maxW)
    return UI().Trim(text, font, maxW)
end

function D.TextFit(text, font, x, y, col, maxW, ax, ay)
    D.Text(D.Trim(text, font, maxW), font, x, y, col, ax, ay)
end

---------------------------------------------------------------------------------------------------------------
-- Aurebesh: scharf als Schrift, sonst das Bild aus SymChars
---------------------------------------------------------------------------------------------------------------
local aureOK
function D.CreateFonts()
    local function F(name, face, size, weight)
        surface.CreateFont(name, { font = face, size = math.max(8, S(size)), weight = weight or 500, antialias = true, extended = true })
    end
    F("eocsb.aure.s", "Aurebesh", 12)
    F("eocsb.aure.m", "Aurebesh", 15)
    surface.CreateFont("eocsb.test.aure", { font = "Aurebesh", size = 40 })
    surface.CreateFont("eocsb.test.tahoma", { font = "Tahoma", size = 40 })
    surface.CreateFont("eocsb.test.arial", { font = "Arial", size = 40 })
    aureOK = nil
end
D.CreateFonts()
hook.Add("OnScreenSizeChanged", "EOCSB_Fonts", D.CreateFonts)

local function AurebeshInstalled()
    if aureOK ~= nil then return aureOK end
    local probe = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local wa = D.TextSize(probe, "eocsb.test.aure")
    aureOK = wa ~= D.TextSize(probe, "eocsb.test.tahoma") and wa ~= D.TextSize(probe, "eocsb.test.arial")
    return aureOK
end

-- size: "s" | "m"
function D.Aurebesh(text, size, x, y, col, ax, ay, maxW)
    local ui = UI()
    local plain = ui.ToAurebesh and ui.ToAurebesh(text) or string.upper(tostring(text or ""))
    if plain == "" then return end
    if AurebeshInstalled() then
        local font = size == "m" and "eocsb.aure.m" or "eocsb.aure.s"
        if maxW then plain = D.Trim(plain, font, maxW) end
        D.Text(plain, font, x, y, col, ax, ay)
    else
        ui.Aurebesh(text, size == "m" and "symchars.aure" or "symchars.aure.small", floor(x), floor(y), col, ax, ay, maxW)
    end
end

---------------------------------------------------------------------------------------------------------------
-- Abschnittstitel (wie UI.Section in SymChars, nur scharf)
---------------------------------------------------------------------------------------------------------------
function D.Section(text, x, y, w, col)
    local t = string.upper(text)
    D.Text(t, "symchars.h3", x, y, col or D.Col("text"))
    local tw, th = D.TextSize(t, "symchars.h3")
    local ly = floor(y + th * 0.55)
    D.Box(x + tw + S(12), ly, w - tw - S(12), 1, D.Col("line2"))
    D.Box(x + tw + S(12), ly - 1, S(28), 3, D.Accent(200))
    D.Aurebesh(text, "s", x + w, ly - S(16), D.Alpha(D.Col("dim"), 110), TEXT_ALIGN_RIGHT)
    return th
end

---------------------------------------------------------------------------------------------------------------
-- Knopf (scharf, im SymChars-Look). style: "default" | "primary" | "danger"
---------------------------------------------------------------------------------------------------------------
local BTN = {}

function BTN:Init()
    self:SetText("")
    self._label = ""
    self._style = "default"
    self._font = "symchars.button.small"
    self._align = TEXT_ALIGN_CENTER
    self._hover = 0
    self:SetCursor("hand")
end
function BTN:SetLabel(t) self._label = tostring(t or "") end
function BTN:SetStyle(s) self._style = s end
function BTN:SetFont(f) self._font = f end
function BTN:SetAlign(a) self._align = a end
function BTN:SetAccentColor(c) self._accent = c end
function BTN:SetSubText(t) self._sub = t end
function BTN:SetSelected(on) self._selected = on end
function BTN:OnCursorEntered() D.Sound("hover") end
function BTN:DoClickInternal() D.Sound("click") end

function BTN:Paint(w, h)
    self._hover = D.Approach(self._hover, self:IsHovered() and 1 or 0, 14)
    local hv = self._hover
    local accent = self._accent or D.Accent()
    local textCol

    if self._style == "primary" then
        D.Box(0, 0, w, h, D.Lerp(hv, D.Alpha(accent, 235), accent))
        textCol = D.Col("ink")
    elseif self._style == "danger" then
        local red = D.Col("red")
        D.Box(0, 0, w, h, D.Lerp(hv, Color(70, 16, 16, 245), Color(120, 26, 24, 250)))
        D.Outline(0, 0, w, h, D.Alpha(red, 150 + 100 * hv))
        textCol = D.Col("text")
    else
        local sel = self._selected and 1 or 0
        D.Box(0, 0, w, h, D.Lerp(hv, D.fill.btn, D.fill.btnH))
        D.Outline(0, 0, w, h, D.Lerp(math.max(hv, sel), D.Col("line2"), accent))
        if sel > 0 or hv > 0.01 then D.Box(0, 0, S(3), h, D.Alpha(accent, 255 * math.max(sel, hv))) end
        textCol = D.Lerp(math.max(hv, sel), D.Col("dim"), D.Col("text"))
    end

    local pad = S(16)
    local tx = self._align == TEXT_ALIGN_LEFT and pad or w / 2
    local maxW = w - pad * 2
    if self._sub then
        local _, lh = D.TextSize("Ag", self._font)
        local _, sh = D.TextSize("Ag", "symchars.tiny")
        local top = floor((h - lh - sh + S(2)) / 2)
        D.TextFit(self._label, self._font, tx, top, textCol, maxW, self._align)
        D.TextFit(self._sub, "symchars.tiny", tx, top + lh - S(2), D.Alpha(textCol, 170), maxW, self._align)
    else
        D.TextFit(self._label, self._font, tx, h / 2, textCol, maxW, self._align, TEXT_ALIGN_CENTER)
    end
    return true
end
vgui.Register("eocsb.Button", BTN, "DButton")

function D.Button(parent, label, style, onClick)
    local b = vgui.Create("eocsb.Button", parent)
    b:SetLabel(label)
    if style then b:SetStyle(style) end
    if onClick then b.DoClick = function() onClick() end end
    return b
end

---------------------------------------------------------------------------------------------------------------
-- Scrollbereich
---------------------------------------------------------------------------------------------------------------
function D.Scroll(parent)
    local sc = vgui.Create("DScrollPanel", parent)
    local bar = sc:GetVBar()
    bar:SetWide(S(6))
    bar:SetHideButtons(true)
    bar.Paint = function(_, w, h) D.Box(floor(w / 2) - 1, 0, 2, h, D.Col("line")) end
    bar.btnGrip.Paint = function(s, w, h) D.Box(0, 0, w, h, s:IsHovered() and D.Accent() or D.Accent(160)) end
    sc:GetCanvas():DockPadding(0, 0, S(10), 0)
    return sc
end

---------------------------------------------------------------------------------------------------------------
-- Fenster (Titel + Aurebesh + Linie, wie symchars.Frame, nur scharf)
---------------------------------------------------------------------------------------------------------------
function D.PaintFrame(w, h, title, sub)
    D.Box(0, 0, w, h, D.fill.frame)
    D.Outline(0, 0, w, h, D.Col("line2"))
    D.Corners(0, 0, w, h, D.Accent(), S(14), S(2))
    D.TextFit(string.upper(title), "symchars.h2", S(22), S(14), D.Col("text"), w - S(80))
    D.Aurebesh(title, "s", S(24), S(48), D.Alpha(D.Col("dim"), 130), nil, nil, w - S(80))
    if sub then sub(w, h) end
    D.Box(S(22), S(70), w - S(44), 1, D.Col("line2"))
    D.Box(S(22), S(69), S(80), 3, D.Accent())
end

function D.Frame(title, w, h)
    local f = vgui.Create("EditablePanel")
    f:SetSize(math.min(w, ScrW() - S(40)), math.min(h, ScrH() - S(40)))
    f:Center()
    f:MakePopup()
    f:DockPadding(S(22), S(86), S(22), S(20))
    f.Paint = function(s, ww, hh) D.PaintFrame(ww, hh, title) end
    f.OnKeyCodePressed = function(s, key) if key == KEY_ESCAPE then s:Remove() end end

    local close = vgui.Create("DButton", f)
    close:SetText("")
    close:SetSize(S(30), S(30))
    close:SetPos(f:GetWide() - S(48), S(20))
    close.hov = 0
    close.Paint = function(s, cw, ch)
        s.hov = D.Approach(s.hov, s:IsHovered() and 1 or 0, 14)
        local col = D.Lerp(s.hov, D.Col("dim"), D.Col("red"))
        D.Outline(0, 0, cw, ch, D.Lerp(s.hov, D.Col("line2"), D.Col("red")))
        UI().Icon("close", S(6), S(6), cw - S(12), col)
        return true
    end
    close.DoClick = function() D.Sound("click") f:Remove() end
    D.Sound("open")
    return f
end

---------------------------------------------------------------------------------------------------------------
-- Hilfen
---------------------------------------------------------------------------------------------------------------
function EOCSB.FormatTime(sec)
    sec = math.max(0, floor(sec or 0))
    return string.format("%02d:%02d:%02d", floor(sec / 3600), floor(sec / 60) % 60, sec % 60)
end

function EOCSB.HexColor(hex, fallback)
    if IsColor(hex) then return hex end
    hex = string.gsub(tostring(hex or ""), "#", "")
    if #hex ~= 6 then return fallback end
    return Color(tonumber(hex:sub(1, 2), 16) or 255, tonumber(hex:sub(3, 4), 16) or 255, tonumber(hex:sub(5, 6), 16) or 255)
end

-- Logo: eingebautes Bild (cl_logo_*.lua) oder Link aus der Config
local logoMat
function EOCSB.Logo()
    if logoMat ~= nil then return logoMat or nil end
    logoMat = false
    file.CreateDir("eocsb")

    local url = CFG.LogoURL or ""
    if url ~= "" then
        local path = "eocsb/logo_" .. util.CRC(url) .. ".png"
        if file.Exists(path, "DATA") then
            local m = Material("data/" .. path, "smooth mips")
            if not m:IsError() then logoMat = m return m end
        end
        http.Fetch(url, function(body)
            if not body or #body < 8 then return end
            file.Write(path, body)
            local m = Material("data/" .. path, "smooth mips")
            if not m:IsError() then logoMat = m end
        end)
    end

    if EOCSB.LogoData and EOCSB.LogoData ~= "" then
        local path = "eocsb/logo_" .. util.CRC(EOCSB.LogoData) .. ".png"
        if not file.Exists(path, "DATA") then
            local raw = util.Base64Decode(EOCSB.LogoData)
            if raw and raw ~= "" then file.Write(path, raw) end
        end
        local m = Material("data/" .. path, "smooth mips")
        if not m:IsError() and not logoMat then logoMat = m end
    end
    return logoMat or nil
end
