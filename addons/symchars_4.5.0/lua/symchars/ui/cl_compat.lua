--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Design für andere Addons
    Alle Addons des Servers zeichnen über diese Funktionen, damit alles wie das Charaktermenü aussieht.
    Global: SYMUI (= symchars.ui)

    UI.Skin(panel)                     Derma-Skin "SymChars" für ein Fenster und alle Kinder setzen
    UI.StyleFrame(frame, title, opts)  DFrame im SymChars-Look (Titel, Schließen-Knopf, Fläche)
    UI.StyleButton(btn, style)         DButton: "default", "primary", "danger", "ghost", "select", "card"
    UI.StyleEntry(entry)               DTextEntry
    UI.StyleScroll(scroll)             DScrollPanel / DListView / DVScrollBar
    UI.StyleCombo(combo)               DComboBox
    UI.StyleCheck(check)               DCheckBox / DCheckBoxLabel
    UI.StyleLabel(label, kind)         DLabel: "text", "dim", "muted", "accent", "head"
    UI.PaintWindow(w, h, title, opts)  Fensterfläche für eigene Paint-Funktionen
    UI.PaintButton(panel, w, h, style) Knopf-Fläche für eigene Paint-Funktionen
    UI.HudPanel(x, y, w, h, opts)      Fläche für HUD-Elemente
    UI.Bar(x, y, w, h, frac, col, opts) Leiste (Leben, Rüstung, Fortschritt)
    UI.FontFace(kind)                  Schriftart: "head", "body", "aure", "mono"
    UI.FontPx(size, kind, weight)      Schrift mit fester Pixelgröße (für Addons mit eigenen Größen)
    UI.FontS(size, kind, weight)       Schrift, die mit der Auflösung skaliert (1080p-Werte)
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S

SYMUI = UI

---------------------------------------------------------------------------------------------------------------
-- Akzentfarbe als festes Color-Objekt, das bei Änderung der Einstellung mitwandert
-- (für Addons, die ihre Farben einmal beim Laden in Tabellen ablegen)
---------------------------------------------------------------------------------------------------------------
local live = {}

function UI.LiveAccent(alpha)
    local a = UI.Accent()
    local c = Color(a.r, a.g, a.b, alpha or 255)
    live[#live + 1] = c
    return c
end

timer.Create("symchars_live_accent", 2, 0, function()
    local a = UI.Accent()
    for _, c in ipairs(live) do c.r, c.g, c.b = a.r, a.g, a.b end
end)

-- Palette für Addons: gleiche Schlüssel wie UI.col, dazu accent / accentD / accentF (lebend)
function UI.Palette()
    return {
        accent = UI.LiveAccent(), accentD = UI.LiveAccent(56), accentF = UI.LiveAccent(20),
        bg = Color(9, 11, 14, 248), panel = UI.col.panel, panel2 = UI.col.panel2, panel3 = UI.col.panel3,
        line = UI.col.line, line2 = UI.col.line2, line3 = UI.col.line3,
        text = UI.col.text, white = UI.col.text, dim = UI.col.dim, muted = UI.col.muted, faint = UI.col.faint,
        cream = UI.col.cream, ink = UI.col.ink, red = UI.col.red, green = UI.col.green, blue = UI.col.blue,
        yellow = UI.col.yellow, cyan = UI.col.cyan, steel = UI.col.steel,
    }
end

-- Farbtabelle der EoC-Addons (yellow, white, soft, panel, line ...) auf SymChars umstellen (in place)
local EOC_KEYS = {
    yellow = function() return UI.LiveAccent() end,
    yellowD = function() return UI.LiveAccent(56) end,
    yellowF = function() return UI.LiveAccent(20) end,
    yellowS = function() return UI.LiveAccent(170) end,
    accent = function() return UI.LiveAccent() end,
    white = function() return UI.col.text end,
    text = function() return UI.col.text end,
    soft = function() return UI.col.dim end,
    muted = function() return UI.col.muted end,
    bg = function() return Color(9, 11, 14, 248) end,
    panel = function() return UI.col.panel end,
    panel2 = function() return UI.col.panel2 end,
    panel3 = function() return UI.col.panel3 end,
    line = function() return UI.col.line end,
    lineS = function() return UI.col.line2 end,
    line2 = function() return UI.col.line2 end,
    red = function() return UI.col.red end,
    green = function() return UI.col.green end,
    blue = function() return UI.col.blue end,
    cyan = function() return UI.col.cyan end,
    barBG = function() return Color(0, 0, 0, 170) end,
}

function UI.ApplyEoCPalette(t, skip)
    if not istable(t) then return t end
    for k, fn in pairs(EOC_KEYS) do
        if t[k] ~= nil and not (skip and skip[k]) then t[k] = fn() end
    end
    return t
end

---------------------------------------------------------------------------------------------------------------
-- Schriften
---------------------------------------------------------------------------------------------------------------
function UI.FontFace(kind)
    return UI.fonts[kind or "body"] or UI.fonts.body
end

local made = {}

function UI.FontPx(size, kind, weight)
    kind, weight = kind or "body", weight or (kind == "head" and 500 or 600)
    size = math.max(8, math.floor(size))
    local name = "symchars.px." .. kind .. "." .. size .. "." .. weight
    if not made[name] then
        surface.CreateFont(name, { font = UI.FontFace(kind), size = size, weight = weight, antialias = true, extended = true })
        made[name] = true
    end
    return name
end

local scaled = {}

function UI.FontS(size, kind, weight)
    kind, weight = kind or "body", weight or (kind == "head" and 500 or 600)
    local name = "symchars.s." .. kind .. "." .. math.floor(size) .. "." .. weight
    if not scaled[name] then
        scaled[name] = { size = size, kind = kind, weight = weight }
        surface.CreateFont(name, { font = UI.FontFace(kind), size = math.max(8, S(size)), weight = weight, antialias = true, extended = true })
    end
    return name
end

hook.Add("OnScreenSizeChanged", "symchars_compat_fonts", function()
    for name, d in pairs(scaled) do
        surface.CreateFont(name, { font = UI.FontFace(d.kind), size = math.max(8, S(d.size)), weight = d.weight, antialias = true, extended = true })
    end
end)

-- GMod-Standardschriften -> SymChars-Schriften (für Addons, die "Trebuchet24", "DermaLarge" ... benutzen)
local STOCK = {
    DermaDefault = "symchars.small", DermaDefaultBold = "symchars.small.bold", DermaLarge = "symchars.h2",
    Trebuchet18 = "symchars.small.bold", Trebuchet24 = "symchars.body.bold",
    ChatFont = "symchars.small", TargetID = "symchars.body.bold", TargetIDSmall = "symchars.small.bold",
    HudHintTextLarge = "symchars.body", HudHintTextSmall = "symchars.tiny", Default = "symchars.small",
    CloseCaption_Normal = "symchars.body", CloseCaption_Bold = "symchars.body.bold",
    GModNotify = "symchars.body.bold", BudgetLabel = "symchars.tiny", HudSelectionText = "symchars.tiny.bold",
}

function UI.F(name)
    return STOCK[name] or name
end

-- größte Überschrift-Schrift, die in die Höhe passt
local HEAD_FONTS = { "symchars.h1", "symchars.h2", "symchars.h3", "symchars.h4", "symchars.small.bold" }
function UI.FitFont(h, list)
    for _, f in ipairs(list or HEAD_FONTS) do
        local _, th = UI.TextSize("Ag", f)
        if th <= h then return f end
    end
    return (list or HEAD_FONTS)[#(list or HEAD_FONTS)]
end

---------------------------------------------------------------------------------------------------------------
-- Flächen
---------------------------------------------------------------------------------------------------------------

-- Fenster: abgeschrägte dunkle Platte, Akzentrahmen, Titel mit Aurebesh, Linie unter der Kopfzeile
-- opts: header (Höhe der Kopfzeile), blur (Panel für Hintergrundunschärfe), accent (Farbe), cut
function UI.PaintWindow(w, h, title, opts)
    opts = opts or {}
    local accent = opts.accent or UI.Accent()
    local header = opts.header or S(66)
    local cut = opts.cut or math.min(S(16), math.floor(math.min(w, h) / 4))
    if opts.blur then Derma_DrawBackgroundBlur(opts.blur, opts.blur._symStart or 0) end
    UI.Cut(0, 0, w, h, opts.fill or Color(9, 11, 14, 248), cut, "tlbr")
    UI.CutOutline(0, 0, w, h, UI.Alpha(accent, 120), cut, "tlbr")
    if header > 0 then
        local pad = math.max(S(10), math.min(S(22), cut + S(6)))
        UI.Box(pad, header - S(2), w - pad * 2, 1, UI.col.line2)
        UI.Box(pad, header - S(2), math.min(S(80), w - pad * 2), S(2), accent)
        if title and title ~= "" then
            local big = header >= S(56)
            local font = big and "symchars.h2" or UI.FitFont(header - S(6), { "symchars.h3", "symchars.h4", "symchars.small.bold" })
            local _, th = UI.TextSize("Ag", font)
            if big then
                UI.TextFit(string.upper(title), font, pad, S(14), UI.col.text, w - pad * 2 - S(40))
                UI.Aurebesh(title, "symchars.aure.small", pad + S(2), S(14) + th - S(6), UI.Alpha(UI.col.dim, 120), nil, nil, w - pad * 2 - S(40))
            else
                UI.TextFit(string.upper(title), font, pad, (header - th) / 2, UI.col.text, w - pad * 2 - S(40))
            end
        end
    end
end

-- Knopf-Fläche (ohne Text). Rückgabe: passende Textfarbe
function UI.PaintButton(panel, w, h, style, accent)
    style = style or "default"
    accent = accent or panel._symAccent or UI.Accent()
    panel._symHover = UI.Approach(panel._symHover or 0, (panel:IsHovered() and panel:IsEnabled()) and 1 or 0, 14)
    local hv = panel._symHover
    local down = panel.Depressed or (panel.IsDown and panel:IsDown())
    local sel = (panel.GetToggle and panel:GetToggle()) or (panel.m_bSelected) or panel._symSelected
    local disabled = not panel:IsEnabled()
    local c = math.min(S(8), math.floor(h / 3))

    if style == "primary" then
        local fill = disabled and UI.Darken(accent, 0.35) or UI.Lerp(hv, accent, Color(math.min(255, accent.r + 25), math.min(255, accent.g + 25), math.min(255, accent.b + 25)))
        if down then fill = UI.Darken(fill, 0.85) end
        UI.Cut(0, 0, w, h, fill, c, "tlbr")
        return disabled and UI.Alpha(UI.col.ink, 160) or UI.col.ink
    elseif style == "danger" then
        UI.Cut(0, 0, w, h, UI.Lerp(hv, Color(90, 18, 18, 230), Color(150, 30, 28, 240)), c, "tlbr")
        UI.CutOutline(0, 0, w, h, UI.Alpha(UI.col.red, 140 + hv * 115), c, "tlbr")
        return disabled and UI.col.muted or UI.col.text
    elseif style == "ghost" then
        if sel then UI.Box(0, h - S(3), w, S(3), accent) end
        return sel and accent or UI.Lerp(hv, UI.col.dim, UI.col.text)
    elseif style == "select" then
        UI.Box(0, 0, w, h, UI.Lerp(hv, Color(8, 10, 13, 220), Color(18, 21, 26, 235)))
        UI.Outline(0, 0, w, h, sel and accent or UI.Lerp(hv * 0.5, UI.col.line2, accent), sel and S(2) or 1)
        return sel and accent or UI.Lerp(hv, UI.col.dim, UI.col.text)
    elseif style == "card" then
        UI.Box(0, 0, w, h, UI.Lerp(hv, UI.col.panel, UI.col.panel2))
        UI.Outline(0, 0, w, h, (sel and accent) or UI.Lerp(hv, UI.col.line, accent))
        return UI.col.text
    end

    UI.Cut(0, 0, w, h, down and UI.col.panel or UI.Lerp(hv, UI.col.panel2, UI.col.panel3), c, "tlbr")
    UI.CutOutline(0, 0, w, h, (sel and accent) or UI.Lerp(hv, UI.col.line2, accent), c, "tlbr")
    return disabled and UI.col.muted or UI.Lerp(hv, UI.col.dim, UI.col.text)
end

-- Ersatz für draw.RoundedBox / RoundedBoxEx: abgeschrägte statt runder Ecken (Kreise bleiben rund)
function UI.RoundedBox(r, x, y, w, h, col)
    if w <= 0 or h <= 0 then return end
    if r <= 0 then UI.Box(x, y, w, h, col) return end
    if r * 2 >= math.min(w, h) then return draw.RoundedBox(r, x, y, w, h, col) end
    UI.Cut(x, y, w, h, col, math.floor(math.min(r, w / 3, h / 3)), "tlbr")
end

function UI.RoundedBoxEx(r, x, y, w, h, col, tl, tr, bl, br)
    if w <= 0 or h <= 0 then return end
    if r <= 0 or not (tl or tr or bl or br) then UI.Box(x, y, w, h, col) return end
    if r * 2 >= math.min(w, h) then return draw.RoundedBoxEx(r, x, y, w, h, col, tl, tr, bl, br) end
    -- Ecken wie bei SymChars nur oben links / unten rechts abschrägen
    local corners = (tl and "tl" or "") .. (br and "br" or "")
    if corners == "" then corners = (tr and "tr" or "") .. (bl and "bl" or "") end
    UI.Cut(x, y, w, h, col, math.floor(math.min(r, w / 3, h / 3)), corners)
end

-- Knopf der EoC-Addons (Felder s.Active, s.Solid, s.Accent, s.SideMark). Rückgabe: Textfarbe
function UI.PaintEoCButton(s, w, h, redCol)
    local hov = s:IsHovered() and s:IsEnabled()
    local isRed = redCol ~= nil and s.Accent == redCol
    local style = s.Solid and (isRed and "danger" or "primary") or "default"
    s._symSelected = s.Active
    local tc = UI.PaintButton(s, w, h, style, (not isRed) and s.Accent or nil)
    if s.Active then
        surface.SetDrawColor(s.Accent or UI.Accent())
        if s.SideMark then surface.DrawRect(0, 0, S(3), h) else surface.DrawRect(0, h - S(3), w, S(3)) end
        tc = s.Accent or UI.Accent()
    end
    if isRed and not s.Solid and hov then tc = UI.col.red end
    return tc
end

-- Kopf der EoC-Fenster (gleiche Positionen wie vorher, damit Reiter/Knöpfe in der Kopfzeile frei bleiben)
function UI.PaintEoCHeader(title, sub, titleFont, subFont, subCol, status, statusCol)
    draw.SimpleText(string.upper(tostring(title or "")), titleFont, 20, 24, UI.col.text, 0, 1)
    local subW = 0
    if sub and sub ~= "" then subW = draw.SimpleText(sub, subFont, 21, 46, subCol or UI.Accent(), 0, 1) end
    if status then draw.SimpleText("//  " .. status, subFont, 21 + subW + 8, 46, statusCol or UI.col.green, 0, 1) end
end

-- HUD-Fläche: halbtransparent, abgeschrägt, optional Akzentkante links und Titel
-- opts: title, accent, alpha, cut, corners, edge (Akzentkante links)
function UI.HudPanel(x, y, w, h, opts)
    opts = opts or {}
    local alpha = opts.alpha or 1
    local cut = opts.cut or math.min(S(10), math.floor(h / 3))
    local accent = opts.accent or UI.Accent()
    UI.Cut(x, y, w, h, Color(9, 11, 14, 215 * alpha), cut, opts.corners or "tlbr")
    UI.CutOutline(x, y, w, h, Color(255, 255, 255, 30 * alpha), cut, opts.corners or "tlbr")
    if opts.edge ~= false then UI.Box(x, y + cut, S(3), h - cut * 2, UI.Alpha(accent, 220 * alpha)) end
    if opts.title then
        UI.Text(string.upper(opts.title), "symchars.h4", x + S(12), y + S(4), UI.Alpha(UI.col.text, 255 * alpha))
    end
end

-- Leiste: dunkle Spur, gefüllter Teil in Farbe, feine Segmente
-- opts: segments (Anzahl Striche), bg, text (mittig), font
function UI.Bar(x, y, w, h, frac, col, opts)
    opts = opts or {}
    frac = math.Clamp(tonumber(frac) or 0, 0, 1)
    col = col or UI.Accent()
    UI.Box(x, y, w, h, opts.bg or Color(0, 0, 0, 170))
    if frac > 0 then
        UI.Box(x, y, math.floor(w * frac), h, col)
        UI.Box(x, y, math.floor(w * frac), math.max(1, math.floor(h / 3)), Color(255, 255, 255, 30))
    end
    local seg = opts.segments
    if seg and seg > 1 then
        surface.SetDrawColor(0, 0, 0, 120)
        for i = 1, seg - 1 do surface.DrawRect(x + math.floor(w * i / seg), y, 1, h) end
    end
    UI.Outline(x, y, w, h, Color(255, 255, 255, 24))
    if opts.text then
        UI.Text(opts.text, opts.font or "symchars.tiny.bold", x + w / 2, y + h / 2, UI.col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

---------------------------------------------------------------------------------------------------------------
-- Vorhandene Panels umstylen
---------------------------------------------------------------------------------------------------------------
local function Recolor(panel, col)
    if panel.SetTextStyleColor then panel:SetTextStyleColor(col) elseif panel.SetTextColor then panel:SetTextColor(col) end
end

function UI.StyleButton(btn, style, font)
    if not IsValid(btn) then return btn end
    btn._symStyle = style or "default"
    if font ~= false and btn.SetFont then btn:SetFont(font or "symchars.button.small") end
    btn.Paint = function(s, w, h)
        s._symTextCol = UI.PaintButton(s, w, h, s._symStyle)
    end
    btn.UpdateColours = function(s)
        Recolor(s, s._symTextCol or UI.col.dim)
    end
    local think = btn.Think
    btn.Think = function(s, ...)
        if s._symTextCol then Recolor(s, s._symTextCol) end
        if think then return think(s, ...) end
    end
    return btn
end

function UI.StyleEntry(entry, font)
    if not IsValid(entry) then return entry end
    if entry.SetFont then entry:SetFont(font or "symchars.body") end
    if entry.SetTextColor then entry:SetTextColor(UI.col.text) end
    if entry.SetPaintBackground then entry:SetPaintBackground(false) end
    entry.Paint = function(s, w, h)
        local accent = UI.Accent()
        s._symFocus = UI.Approach(s._symFocus or 0, s:HasFocus() and 1 or 0, 12)
        UI.Box(0, 0, w, h, Color(4, 6, 8, 230))
        UI.Outline(0, 0, w, h, UI.Lerp(s._symFocus, UI.col.line2, accent), s._symFocus > 0.5 and S(2) or 1)
        if s.GetPlaceholderText and s:GetValue() == "" and (s:GetPlaceholderText() or "") ~= "" and not s:HasFocus() then
            UI.Text(s:GetPlaceholderText(), s:GetFont(), S(4), s:IsMultiline() and S(3) or h / 2, UI.col.muted, TEXT_ALIGN_LEFT, s:IsMultiline() and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
        end
        s:DrawTextEntryText(UI.col.text, UI.Accent(90), UI.Accent())
        return true
    end
    return entry
end

local function StyleVBar(bar)
    if not IsValid(bar) then return end
    bar:SetWide(math.max(S(6), 4))
    if bar.SetHideButtons then bar:SetHideButtons(true) end
    bar.Paint = function(_, w, h) UI.Box(w / 2 - 1, 0, 2, h, UI.col.line) end
    if IsValid(bar.btnGrip) then
        bar.btnGrip.Paint = function(s, w, h) UI.Box(0, 0, w, h, s:IsHovered() and UI.Accent() or UI.Accent(150)) return true end
    end
    if IsValid(bar.btnUp) then bar.btnUp.Paint = function() return true end end
    if IsValid(bar.btnDown) then bar.btnDown.Paint = function() return true end end
end
UI.StyleVBar = StyleVBar

function UI.StyleScroll(scroll, bg)
    if not IsValid(scroll) then return scroll end
    local bar = scroll.GetVBar and scroll:GetVBar() or (scroll.VBar)
    StyleVBar(bar)
    if bg then
        scroll.Paint = function(_, w, h) UI.Box(0, 0, w, h, UI.col.panel) UI.Outline(0, 0, w, h, UI.col.line) end
    elseif scroll.ClassName == "DScrollPanel" or scroll.GetCanvas then
        scroll.Paint = function() end
    end
    return scroll
end

function UI.StyleLabel(label, kind, font)
    if not IsValid(label) then return label end
    local col = kind == "dim" and UI.col.dim or kind == "muted" and UI.col.muted or kind == "accent" and UI.Accent() or UI.col.text
    if font then label:SetFont(font) elseif kind == "head" then label:SetFont("symchars.h3") end
    if kind == "head" then label:SetText(string.upper(label:GetText() or "")) end
    label:SetTextColor(col)
    return label
end

function UI.StyleCheck(check)
    if not IsValid(check) then return check end
    local box = check.Button or check
    box.Paint = function(s, w, h)
        local on = s.GetChecked and s:GetChecked()
        UI.Box(0, 0, w, h, Color(4, 6, 8, 220))
        UI.Outline(0, 0, w, h, s:IsHovered() and UI.Accent() or UI.col.line3)
        if on then
            local i = math.max(2, math.floor(w / 5))
            UI.Box(i, i, w - i * 2, h - i * 2, UI.Accent())
        end
        return true
    end
    if check.Label and IsValid(check.Label) then
        check.Label:SetFont("symchars.body")
        check.Label:SetTextColor(UI.col.dim)
    end
    return check
end

function UI.StyleCombo(combo)
    if not IsValid(combo) then return combo end
    combo:SetFont("symchars.body")
    combo:SetTextColor(UI.col.text)
    combo.Paint = function(s, w, h)
        s._symHover = UI.Approach(s._symHover or 0, (s:IsHovered() or s:IsMenuOpen()) and 1 or 0, 14)
        UI.Box(0, 0, w, h, Color(4, 6, 8, 230))
        UI.Outline(0, 0, w, h, UI.Lerp(s._symHover, UI.col.line2, UI.Accent()))
        return true
    end
    if IsValid(combo.DropButton) then
        combo.DropButton.Paint = function(s, w, h)
            UI.Icon("chevron", 0, 0, math.min(w, h), UI.Lerp(combo._symHover or 0, UI.col.dim, UI.Accent()))
            return true
        end
    end
    local open = combo.OpenMenu
    combo.OpenMenu = function(s, ...)
        open(s, ...)
        if IsValid(s.Menu) then UI.Skin(s.Menu) end
    end
    return combo
end

-- DFrame umstylen. opts: header (Höhe Kopfzeile, Standard = bisheriger oberer Innenabstand), blur, accent
function UI.StyleFrame(frame, title, opts)
    if not IsValid(frame) then return frame end
    opts = opts or {}
    title = title or (frame.GetTitle and frame:GetTitle()) or ""
    frame._symTitle = title
    if frame.SetTitle and frame.lblTitle then frame.lblTitle:SetVisible(false) end
    if IsValid(frame.btnMinim) then frame.btnMinim:SetVisible(false) end
    if IsValid(frame.btnMaxim) then frame.btnMaxim:SetVisible(false) end
    local _, top = frame:GetDockPadding()
    local header = opts.header or math.max(top or 0, S(30))
    if opts.header and opts.header > (top or 0) then
        local l, _, r, b = frame:GetDockPadding()
        frame:DockPadding(l, opts.header + S(6), r, b)
    end
    frame._symHeader = header
    frame._symStart = SysTime()
    frame.Paint = function(s, w, h)
        UI.PaintWindow(w, h, s._symTitle, { header = s._symHeader, blur = opts.blur and s or nil, accent = opts.accent })
    end
    if IsValid(frame.btnClose) then
        frame.btnClose.Paint = function(s, w, h)
            local size = math.min(w, h, S(24))
            UI.Icon("close", (w - size) / 2, (h - size) / 2, size, s:IsHovered() and UI.col.red or UI.col.dim)
            return true
        end
        local layout = frame.PerformLayout
        frame.PerformLayout = function(s, w, h)
            if layout then layout(s, w, h) end
            if IsValid(s.btnClose) then
                local size = math.min(S(30), s._symHeader - S(4))
                s.btnClose:SetSize(size, size)
                s.btnClose:SetPos(w - size - S(12), math.max(S(2), (s._symHeader - size) / 2))
            end
        end
    end
    local setTitle = frame.SetTitle
    frame.SetTitle = function(s, t)
        s._symTitle = t
        if setTitle then setTitle(s, t) end
        if s.lblTitle then s.lblTitle:SetVisible(false) end
    end
    UI.Skin(frame)
    frame:InvalidateLayout(true)
    return frame
end

-- true, wenn das Addon dem Panel eine eigene Paint-Funktion gegeben hat (vgui.Create kopiert die
-- Klassenfunktionen in die Instanz, darum mit der Klassen-Paint vergleichen)
local function HasOwnPaint(panel)
    local t = panel:GetTable()
    if not t or not t.Paint then return false end
    local ctrl = panel.ClassName and vgui.GetControlTable(panel.ClassName)
    return not ctrl or t.Paint ~= ctrl.Paint
end
UI.HasOwnPaint = HasOwnPaint

-- Für Addons mit Standard-DFrame: nach dem Aufbau (nächster Frame) Fenster + Kinder umstylen.
-- Hat das Addon dem Fenster eine eigene Paint-Funktion gegeben, bleibt die erhalten (nur Skin + Kinder).
function UI.AutoStyle(frame, opts)
    if not IsValid(frame) then return frame end
    UI.Skin(frame)
    timer.Simple(0, function()
        if not IsValid(frame) then return end
        local own = HasOwnPaint(frame)
        if not own and frame.lblTitle then UI.StyleFrame(frame, nil, opts) end
        UI.StyleTree(frame)
    end)
    return frame
end

-- ganzes Fenster mit allen vorhandenen Kindern umstylen (nur Standard-Derma-Elemente ohne eigene Paint-Funktion)
function UI.StyleTree(panel)
    if not IsValid(panel) then return end
    UI.Skin(panel)
    local pclass = panel.ClassName
    -- Innenleben von Scrollleisten, Zahlenfeldern, Farbmischern usw. nicht anfassen (Skin reicht)
    if pclass == "DVScrollBar" or pclass == "DHScrollBar" or pclass == "DNumberWang" or pclass == "DColorMixer" or pclass == "DFileBrowser" then return end
    for _, child in ipairs(panel:GetChildren()) do
        local class = child.ClassName
        local t = child:GetTable()
        if t and not t._symDone and not HasOwnPaint(child) and child ~= panel.btnClose and child ~= panel.btnMaxim and child ~= panel.btnMinim then
            t._symDone = true
            if class == "DButton" then UI.StyleButton(child, "default", false)
            elseif class == "DTextEntry" then UI.StyleEntry(child)
            elseif class == "DComboBox" then UI.StyleCombo(child)
            elseif class == "DScrollPanel" then UI.StyleScroll(child)
            elseif class == "DCheckBoxLabel" then UI.StyleCheck(child)
            end
        end
        UI.StyleTree(child)
    end
end

---------------------------------------------------------------------------------------------------------------
-- Kraken's Framework (KF): Battle Grid, Medical, Squad, Store, BF2-Scoreboard
-- Die Addons holen Farben/Schriften über KF.UI.SetTheme / KF.Fonts.Register. Diese Aufrufe werden hier
-- abgefangen und auf SymChars umgebogen. UI.HookKraken() wird von den Kraken-Addons selbst aufgerufen
-- (dann gibt es KF sicher), zusätzlich beim Laden und bei Initialize.
---------------------------------------------------------------------------------------------------------------
function UI.KrakenPalette(p)
    if not istable(p) then return p end
    local a, c = UI.Accent(), UI.col
    local function set(k, v) p[k] = v end
    set("Background", Color(6, 8, 11, 250)) set("BackgroundDark", Color(4, 6, 8, 250)) set("BG", Color(6, 8, 11, 250))
    set("Panel", Color(11, 14, 18, 240)) set("PanelDark", Color(9, 11, 14, 245)) set("PanelLight", Color(27, 32, 40, 245))
    set("PanelHover", Color(31, 37, 46, 245)) set("CardBg", Color(11, 14, 18, 240)) set("CardBorder", c.line2)
    set("Row", Color(11, 14, 18, 200)) set("RowAlt", Color(255, 255, 255, 5)) set("RowHover", Color(255, 255, 255, 12))
    set("Border", c.line2) set("BorderSubtle", c.line) set("BorderLight", c.line3) set("BorderAccent", Color(a.r, a.g, a.b, 120))
    set("TextPrimary", c.text) set("TextSecondary", c.dim) set("TextMuted", c.muted) set("TextDisabled", c.faint)
    set("TextAccent", Color(a.r, a.g, a.b)) set("Muted", c.muted)
    set("Accent", Color(a.r, a.g, a.b)) set("AccentHover", Color(math.min(255, a.r + 25), math.min(255, a.g + 25), math.min(255, a.b + 25)))
    set("AccentMuted", Color(a.r, a.g, a.b, 60))
    set("Error", c.red) set("ErrorHover", Color(225, 80, 74)) set("Success", c.green) set("Warning", c.yellow) set("Info", c.blue)
    return p
end

function UI.HookKraken()
    if not (KF and KF.UI and KF.Fonts) or KF._symHooked then return end
    KF._symHooked = true

    local setTheme = KF.UI.SetTheme
    if setTheme then
        KF.UI.SetTheme = function(aid, palette, ...)
            return setTheme(aid, UI.KrakenPalette(palette), ...)
        end
    end

    local applyAccent = KF.UI.ApplyAccentColor
    if applyAccent then
        KF.UI.ApplyAccentColor = function(aid, col, ...)
            local a = UI.Accent()
            return applyAccent(aid, Color(a.r, a.g, a.b), ...)
        end
    end

    local register = KF.Fonts.Register
    if register then
        KF.Fonts.Register = function(aid, opts, ...)
            if istable(opts) then
                opts.primary = UI.fonts.body
                opts.secondary = UI.fonts.body
                if opts.accent then opts.accent = UI.fonts.aure end
            end
            return register(aid, opts, ...)
        end
    end

    if KF.Draw and KF.Draw.RoundedBox then
        local rounded = KF.Draw.RoundedBox
        -- KF-Reihenfolge: (x, y, w, h, radius, farbe)
        KF.Draw.RoundedBox = function(x, y, w, h, r, col, ...)
            if isnumber(x) and isnumber(w) and isnumber(h) and isnumber(r) and IsColor(col) and select("#", ...) == 0 then
                return UI.RoundedBox(r, x, y, w, h, col)
            end
            return rounded(x, y, w, h, r, col, ...)
        end
    end
end

UI.HookKraken()
hook.Add("Initialize", "symchars_kraken", function() UI.HookKraken() end)

-- VoidUI (Bibliothek von gWare Utilities): Farbtabelle umfärben, sobald VoidUI geladen ist
function UI.HookVoidUI()
    if not (VoidUI and istable(VoidUI.Colors)) or VoidUI._symHooked then return end
    VoidUI._symHooked = true
    local col, a = VoidUI.Colors, UI.Accent()
    local map = {
        Background = Color(9, 11, 14, 248), BackgroundTransparent = Color(9, 11, 14, 220),
        Primary = Color(18, 22, 28, 240), Secondary = Color(27, 32, 40, 245), Hover = Color(31, 37, 46, 245),
        InputDark = Color(4, 6, 8, 230), InputLight = Color(18, 22, 28, 240),
        Blue = Color(a.r, a.g, a.b), Accent = Color(a.r, a.g, a.b),
        White = UI.col.text, Gray = UI.col.dim, LightGray = UI.col.dim, TextGray = UI.col.muted, DarkGray = UI.col.faint,
        Red = UI.col.red, Green = UI.col.green,
    }
    for k, v in pairs(map) do
        if col[k] ~= nil then col[k] = v end
    end
end

-- PIXEL UI (Bibliothek von Chat Commands u. a.): Farbtabelle umfärben
function UI.HookPixel()
    if not (PIXEL and istable(PIXEL.Colors)) or PIXEL._symHooked then return end
    PIXEL._symHooked = true
    local col, a = PIXEL.Colors, UI.Accent()
    local map = {
        Background = Color(9, 11, 14, 248), Header = Color(18, 22, 28, 250), SecondaryHeader = Color(27, 32, 40, 250),
        Scroller = Color(a.r, a.g, a.b, 150), PrimaryText = UI.col.text, SecondaryText = UI.col.dim, DisabledText = UI.col.muted,
        Primary = Color(a.r, a.g, a.b), Disabled = Color(60, 64, 70), Positive = UI.col.green, Negative = UI.col.red,
    }
    for k, v in pairs(map) do
        if col[k] ~= nil then col[k] = v end
    end
end

hook.Add("InitPostEntity", "symchars_voidui", function() UI.HookVoidUI() UI.HookPixel() end)

---------------------------------------------------------------------------------------------------------------
-- SUI (Bibliothek von SAM): Farbtabelle im SymChars-Look, Schriften auf Roboto Condensed
---------------------------------------------------------------------------------------------------------------
function UI.SUITheme()
    local a, c = UI.Accent(), UI.col
    local A = function(al) return Color(a.r, a.g, a.b, al or 255) end
    return {
        frame = Color(9, 11, 14, 248), frame_blur = false,
        title = c.text, header = Color(18, 22, 28, 250),
        close = c.dim, close_hover = c.red, close_press = Color(255, 255, 255, 30),
        button = A(), button_text = c.ink, button_hover = Color(255, 255, 255, 30), button_click = Color(0, 0, 0, 60),
        button_disabled = Color(60, 64, 70), button_disabled_text = c.muted,
        button2_hover = A(12), button2_selected = A(30),
        scroll = Color(255, 255, 255, 22), scroll_grip = A(),
        scroll_panel = Color(11, 14, 18, 240), scroll_panel_outline = false,
        text_entry_bg = Color(4, 6, 8, 230), text_entry_bar_color = Color(0, 0, 0, 0),
        text_entry = c.text, text_entry_2 = c.muted, text_entry_3 = A(),
        property_sheet_bg = Color(18, 22, 28, 240), property_sheet_tab = c.dim,
        property_sheet_tab_click = Color(255, 255, 255, 30), property_sheet_tab_active = A(),
        toggle_button = c.faint, toggle_button_switch = c.text, toggle_button_active = A(65), toggle_button_switch_active = A(),
        slider_knob = A(), slider_track = A(65), slider_hover = A(10), slider_pressed = A(30),
        on_sheet = Color(27, 32, 40, 220), on_sheet_hover = Color(255, 255, 255, 14),
        query_box_bg = Color(9, 11, 14, 250), query_box_cancel = Color(205, 62, 56, 40), query_box_cancel_text = c.red,
        menu = Color(8, 10, 13, 250), menu_option = Color(8, 10, 13, 250), menu_option_text = c.dim,
        menu_option_hover = A(40), menu_option_hover_text = c.text, menu_spacer = c.line2,
        line = c.line2,
        column_sheet = Color(9, 11, 14, 248), column_sheet_bar = Color(0, 0, 0, 225),
        column_sheet_tab = Color(0, 0, 0, 0), column_sheet_tab_hover = A(16), column_sheet_tab_active = A(36),
        column_sheet_tab_icon = c.dim, column_sheet_tab_icon_hover = c.text, column_sheet_tab_icon_active = A(),
        collapse_category_header = Color(27, 32, 40, 245), collapse_category_header_hover = Color(31, 37, 46, 245),
        collapse_category_header_active = A(30),
        collapse_category_header_text = c.dim, collapse_category_header_text_hover = c.text, collapse_category_header_text_active = A(),
        collapse_category_item = Color(18, 22, 28, 240), collapse_category_item_hover = Color(27, 32, 40, 245),
        collapse_category_item_active = A(40),
        collapse_category_item_text = c.dim, collapse_category_item_text_hover = c.text, collapse_category_item_text_active = c.text,
        -- SAM
        menu_tabs_title = c.text, player_list_titles = c.text, player_list_names = c.text, player_list_names_2 = c.red,
        player_list_data = c.dim, player_list_rank = A(), player_list_console = c.green, player_list_rank_text = c.ink,
        player_list_steamid = c.muted, actions_button = Color(0, 0, 0, 0), actions_button_hover = A(40),
        actions_button_icon = c.dim, actions_button_icon_hover = c.text, page_switch_bg = Color(18, 22, 28, 240),
    }
end

-- Schriftnamen von SUI/SAM ("Roboto Bold" usw.) -> Schnitt von Roboto Condensed
function UI.SUIFont(font, weight)
    local f = string.lower(tostring(font or ""))
    if not string.find(f, "roboto", 1, true) and not string.find(f, "montserrat", 1, true) then return font, weight end
    if string.find(f, "bold", 1, true) or string.find(f, "black", 1, true) then return UI.fonts.body, math.max(weight or 0, 800) end
    if string.find(f, "medium", 1, true) then return UI.fonts.body, math.max(weight or 0, 600) end
    return UI.fonts.body, weight or 500
end

---------------------------------------------------------------------------------------------------------------
-- HTML-Menüs (DHTML): SymChars-Farben und -Schriften als CSS-Variablen einsetzen
-- UI.ThemeHTML(html, opts) hängt vor </head> einen <style>-Block an, der die üblichen Variablen
-- der EoC-Vorlagen (--yellow, --white, --panel, --line, --fontMain ...) überschreibt.
-- opts.skip = { accent = true, ... }  Variablen, die das Addon selbst dynamisch setzt, nicht anfassen
-- opts.css  = zusätzliche CSS-Regeln
---------------------------------------------------------------------------------------------------------------
local function RGBA(c, a)
    return string.format("rgba(%d,%d,%d,%s)", c.r, c.g, c.b, a or string.format("%.3f", (c.a or 255) / 255))
end
UI.RGBA = RGBA

function UI.HTMLVars()
    local a, c = UI.Accent(), UI.col
    local head = "'SymHead','BigNoodleTitling','Bebas Neue',Arial,sans-serif"
    local body = "'SymBody','Roboto Condensed','Montserrat',Arial,sans-serif"
    return {
        -- eigene Namen
        ["sy-accent"] = RGBA(a, 1), ["sy-accent-soft"] = RGBA(a, ".68"), ["sy-accent-dim"] = RGBA(a, ".22"), ["sy-accent-faint"] = RGBA(a, ".08"),
        ["sy-text"] = RGBA(c.text, 1), ["sy-dim"] = RGBA(c.dim, 1), ["sy-muted"] = RGBA(c.muted, 1),
        ["sy-bg"] = "rgba(9,11,14,.97)", ["sy-panel"] = RGBA(c.panel), ["sy-panel2"] = RGBA(c.panel2), ["sy-panel3"] = RGBA(c.panel3),
        ["sy-line"] = RGBA(c.line), ["sy-line2"] = RGBA(c.line2), ["sy-line3"] = RGBA(c.line3),
        ["sy-red"] = RGBA(c.red, 1), ["sy-green"] = RGBA(c.green, 1), ["sy-ink"] = RGBA(c.ink, 1),
        ["sy-head"] = head, ["sy-body"] = body, ["sy-aure"] = "'SymAure','Aurebesh',monospace",
        -- Namen der EoC-Vorlagen
        yellow = RGBA(a, 1), ["yellow-soft"] = RGBA(a, ".68"), yellowSoft = RGBA(a, ".68"),
        ["yellow-dim"] = RGBA(a, ".22"), yellowDim = RGBA(a, ".22"), ["yellow-faint"] = RGBA(a, ".08"), yellowFaint = RGBA(a, ".08"),
        accent = RGBA(a, 1), ["accent-gold"] = RGBA(a, 1),
        white = RGBA(c.text, 1), text = RGBA(c.text, 1), ["text-main"] = RGBA(c.text, 1), ["text-primary"] = RGBA(c.text, 1), ["text-color"] = RGBA(c.text, 1),
        soft = RGBA(c.dim, 1), ["text-soft"] = RGBA(c.dim, 1), ["text-dim"] = RGBA(c.dim, 1),
        muted = "rgba(140,147,155,1)", muted2 = RGBA(c.muted, 1),
        panel = "rgba(11,14,18,.86)", panelSoft = "rgba(18,22,28,.66)", ["panel-soft"] = "rgba(18,22,28,.66)",
        panelStrong = "rgba(9,11,14,.95)", ["panel-strong"] = "rgba(9,11,14,.95)", panel2 = RGBA(c.panel2), panel3 = RGBA(c.panel3),
        dark = "rgba(6,8,11,.92)", ["bg-dark"] = "rgba(6,8,11,.92)", ["bg-color"] = "rgba(9,11,14,.95)",
        line = "rgba(255,255,255,.09)", line2 = "rgba(255,255,255,.2)", lineStrong = "rgba(255,255,255,.2)", ["line-strong"] = "rgba(255,255,255,.2)",
        ["border-color"] = "rgba(255,255,255,.2)",
        red = RGBA(c.red, 1), danger = RGBA(c.red, 1), green = RGBA(c.green, 1), cyan = RGBA(c.cyan, 1),
        fontMain = body, ["font-main"] = body, ["body-font"] = body,
        fontTitle = head, ["font-title"] = head, ["title-font"] = head,
    }
end

function UI.HTMLStyle(opts)
    opts = opts or {}
    local skip = opts.skip or {}
    local vars = {}
    for k, v in SortedPairs(UI.HTMLVars()) do
        if not skip[k] then vars[#vars + 1] = "--" .. k .. ":" .. v end
    end
    return "<link href=\"https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Roboto+Condensed:wght@400;500;600;700;800&display=swap\" rel=\"stylesheet\">"
        .. "<style id=\"symchars-theme\">"
        .. "@font-face{font-family:'SymHead';src:url('asset://garrysmod/resource/fonts/symchars_bignoodle.ttf')}"
        .. "@font-face{font-family:'SymBody';src:url('asset://garrysmod/resource/fonts/symchars_robotocondensed.ttf')}"
        .. "@font-face{font-family:'SymAure';src:url('asset://garrysmod/resource/fonts/symchars_aurebesh.ttf')}"
        .. ":root{" .. table.concat(vars, ";") .. "}"
        .. "::selection{background:var(--sy-accent-dim)}"
        .. "::-webkit-scrollbar{width:6px;height:6px}::-webkit-scrollbar-track{background:rgba(255,255,255,.06)}"
        .. "::-webkit-scrollbar-thumb{background:var(--sy-accent-soft)}::-webkit-scrollbar-thumb:hover{background:var(--sy-accent)}"
        .. (opts.css or "")
        .. "</style>"
end

-- feste Werte der EoC-Vorlagen (Schriftnamen, Gelb) durch SymChars ersetzen
-- Die Anführungszeichen der Vorlage bleiben erhalten (Schriftnamen können in style="..." stehen)
local LITERALS = {
    { "'Bebas Neue'", "SymHead,BigNoodleTitling,'Bebas Neue'" },
    { "\"Bebas Neue\"", "SymHead,BigNoodleTitling,\"Bebas Neue\"" },
    { "'Montserrat'", "SymBody,'Roboto Condensed','Montserrat'" },
    { "\"Montserrat\"", "SymBody,\"Roboto Condensed\",\"Montserrat\"" },
}
local YELLOWS = { "255,190,50", "255, 190, 50" }

function UI.ThemeHTML(html, opts)
    html = tostring(html or "")
    opts = opts or {}
    if not opts.noLiteral then
        for _, pair in ipairs(LITERALS) do html = string.Replace(html, pair[1], pair[2]) end
        local a = UI.Accent()
        local rgb = a.r .. "," .. a.g .. "," .. a.b
        for _, y in ipairs(opts.yellows or YELLOWS) do html = string.Replace(html, y, rgb) end
        for _, hex in ipairs(opts.hexes or { "#ffbe32", "#FFBE32" }) do html = string.Replace(html, hex, string.format("#%02x%02x%02x", a.r, a.g, a.b)) end
    end
    local style = UI.HTMLStyle(opts)
    local s, e = string.find(html, "</head>", 1, true)
    if s then return string.sub(html, 1, s - 1) .. style .. string.sub(html, s) end
    return style .. html
end

---------------------------------------------------------------------------------------------------------------
-- Derma-Skin "SymChars": färbt Standard-Derma (DFrame, DButton, DListView, DMenu, DPropertySheet ...) um
---------------------------------------------------------------------------------------------------------------
local SKIN = {}
SKIN.PrintName = "SymChars"
SKIN.Author = "SymChars"
SKIN.DermaVersion = 1
SKIN.Base = "Default"

SKIN.fontFrame = "symchars.h4"
SKIN.fontTab = "symchars.small.bold"
SKIN.fontButton = "symchars.small.bold"
SKIN.fontCategoryHeader = "symchars.small.bold"

SKIN.colTextEntryText = UI.col.text
SKIN.colTextEntryTextHighlight = Color(252, 178, 73, 90)
SKIN.colTextEntryTextCursor = Color(252, 178, 73)
SKIN.colTextEntryTextPlaceholder = UI.col.muted

local function DefaultColours(key)
    local d = derma.GetNamedSkin("Default")
    return d and d.Colours and d.Colours[key]
end

SKIN.Colours = setmetatable({
    Window = { TitleActive = UI.col.text, TitleInactive = UI.col.dim },
    Button = { Normal = UI.col.dim, Hover = UI.col.text, Down = UI.col.text, Disabled = UI.col.muted },
    Label = { Default = UI.col.text, Bright = UI.col.text, Dark = UI.col.dim, Highlight = Color(252, 178, 73) },
    Tab = {
        Active = { Normal = UI.col.text, Hover = UI.col.text, Down = UI.col.text, Disabled = UI.col.muted },
        Inactive = { Normal = UI.col.dim, Hover = UI.col.text, Down = UI.col.text, Disabled = UI.col.muted },
    },
    Tree = { Lines = UI.col.line2, Normal = UI.col.dim, Hover = UI.col.text, Selected = Color(252, 178, 73) },
    Category = {
        Header = UI.col.text, Header_Closed = UI.col.dim,
        Line = { Text = UI.col.dim, Text_Hover = UI.col.text, Text_Selected = Color(252, 178, 73), Button = Color(0, 0, 0, 0), Button_Hover = Color(255, 255, 255, 10), Button_Selected = Color(252, 178, 73, 40) },
        LineAlt = { Text = UI.col.dim, Text_Hover = UI.col.text, Text_Selected = Color(252, 178, 73), Button = Color(255, 255, 255, 4), Button_Hover = Color(255, 255, 255, 10), Button_Selected = Color(252, 178, 73, 40) },
    },
    TooltipText = UI.col.text,
}, { __index = function(_, k) return DefaultColours(k) end })

-- Akzentfarbe aus den SymChars-Einstellungen übernehmen (kann sich zur Laufzeit ändern)
local function SyncAccent()
    local a = UI.Accent()
    SKIN.Colours.Label.Highlight = a
    SKIN.Colours.Tree.Selected = a
    SKIN.Colours.Category.Line.Text_Selected = a
    SKIN.Colours.Category.LineAlt.Text_Selected = a
    SKIN.colTextEntryTextHighlight = UI.Alpha(a, 90)
    SKIN.colTextEntryTextCursor = a
end
timer.Create("symchars_skin_accent", 5, 0, SyncAccent)

function SKIN:PaintFrame(panel, w, h)
    UI.PaintWindow(w, h, nil, { header = S(24) + S(5), cut = S(10) })
end

function SKIN:PaintPanel(panel, w, h)
    if not panel.m_bBackground then return end
    UI.Box(0, 0, w, h, UI.col.panel)
end

function SKIN:PaintShadow() end

function SKIN:PaintButton(panel, w, h)
    if not panel.m_bBackground then return end
    UI.PaintButton(panel, w, h, "default")
end

function SKIN:PaintWindowCloseButton(panel, w, h)
    if not panel.m_bBackground then return end
    local size = math.min(w, h)
    UI.Icon("close", (w - size) / 2, (h - size) / 2, size, panel:IsHovered() and UI.col.red or UI.col.dim)
end
function SKIN:PaintWindowMinimizeButton() end
function SKIN:PaintWindowMaximizeButton() end

function SKIN:PaintTextEntry(panel, w, h)
    if panel.m_bBackground then
        local focus = panel:HasFocus()
        UI.Box(0, 0, w, h, panel:GetDisabled() and Color(20, 22, 26, 230) or Color(4, 6, 8, 230))
        UI.Outline(0, 0, w, h, focus and UI.Accent() or UI.col.line2)
    end
    if panel.GetPlaceholderText and panel:GetPlaceholderText() and panel:GetPlaceholderText():Trim() ~= "" and panel:GetText() == "" and not panel:HasFocus() then
        local old = panel:GetText()
        local str = panel:GetPlaceholderText()
        if str:StartWith("#") then str = str:sub(2) end
        str = language.GetPhrase(str)
        panel:SetText(str)
        panel:DrawTextEntryText(UI.col.muted, self.colTextEntryTextHighlight, self.colTextEntryTextCursor)
        panel:SetText(old)
        return
    end
    panel:DrawTextEntryText(panel:GetTextColor() or UI.col.text, self.colTextEntryTextHighlight, self.colTextEntryTextCursor)
end

function SKIN:PaintMenu(panel, w, h)
    UI.Box(0, 0, w, h, Color(8, 10, 13, 250))
    UI.Outline(0, 0, w, h, UI.Accent(160))
end

function SKIN:PaintMenuSpacer(panel, w, h)
    UI.Box(S(6), 0, w - S(12), h, UI.col.line2)
end

function SKIN:PaintMenuOption(panel, w, h)
    if panel.m_bBackground and (panel.Hovered or panel.Highlight) then
        UI.Box(0, 0, w, h, UI.Accent(40))
        UI.Box(0, 0, S(3), h, UI.Accent())
    end
    if panel:GetChecked() then UI.Icon("check", S(4), (h - S(16)) / 2, S(16), UI.Accent()) end
end

function SKIN:PaintMenuRightArrow(panel, w, h)
    UI.Icon("arrow_right", 0, 0, math.min(w, h), UI.col.dim)
end

function SKIN:PaintPropertySheet(panel, w, h)
    local active = panel:GetActiveTab()
    local offset = active and active:GetTall() - 8 or 0
    UI.Box(0, offset, w, h - offset, UI.col.panel)
    UI.Outline(0, offset, w, h - offset, UI.col.line)
end

function SKIN:PaintTab(panel, w, h)
    if panel:IsActive() then
        UI.Box(0, 0, w, h - 8, UI.Accent(30))
        UI.Box(0, h - 8 - S(3), w, S(3), UI.Accent())
    else
        UI.Box(0, 0, w, h, panel:IsHovered() and Color(255, 255, 255, 10) or Color(0, 0, 0, 160))
    end
end

function SKIN:PaintActiveTab(panel, w, h) self:PaintTab(panel, w, h) end

function SKIN:PaintCheckBox(panel, w, h)
    UI.Box(0, 0, w, h, Color(4, 6, 8, 220))
    UI.Outline(0, 0, w, h, panel:IsHovered() and UI.Accent() or UI.col.line3)
    if panel:GetChecked() then
        local i = math.max(2, math.floor(w / 5))
        UI.Box(i, i, w - i * 2, h - i * 2, panel:GetDisabled() and UI.col.muted or UI.Accent())
    end
end

function SKIN:PaintExpandButton(panel, w, h)
    UI.Icon(panel:GetExpanded() and "chevron" or "arrow_right", 0, 0, math.min(w, h), UI.col.dim)
end

function SKIN:PaintVScrollBar(panel, w, h)
    UI.Box(w / 2 - 1, 0, 2, h, UI.col.line)
end

function SKIN:PaintScrollBarGrip(panel, w, h)
    UI.Box(math.floor(w / 4), 0, math.ceil(w / 2), h, (panel.Hovered or panel.Depressed) and UI.Accent() or UI.Accent(150))
end

function SKIN:PaintButtonUp(panel, w, h) UI.Icon("arrow_up", 0, 0, math.min(w, h), panel.Hovered and UI.col.text or UI.col.muted) end
function SKIN:PaintButtonDown(panel, w, h) UI.Icon("arrow_down", 0, 0, math.min(w, h), panel.Hovered and UI.col.text or UI.col.muted) end
function SKIN:PaintButtonLeft(panel, w, h) UI.Icon("arrow_left", 0, 0, math.min(w, h), panel.Hovered and UI.col.text or UI.col.muted) end
function SKIN:PaintButtonRight(panel, w, h) UI.Icon("arrow_right", 0, 0, math.min(w, h), panel.Hovered and UI.col.text or UI.col.muted) end

function SKIN:PaintComboDownArrow(panel, w, h)
    UI.Icon("chevron", 0, 0, math.min(w, h), panel.ComboBox and panel.ComboBox:IsMenuOpen() and UI.Accent() or UI.col.dim)
end

function SKIN:PaintComboBox(panel, w, h)
    UI.Box(0, 0, w, h, Color(4, 6, 8, 230))
    UI.Outline(0, 0, w, h, (panel.Hovered or panel:IsMenuOpen()) and UI.Accent() or UI.col.line2)
end

function SKIN:PaintListBox(panel, w, h)
    UI.Box(0, 0, w, h, UI.col.panel)
    UI.Outline(0, 0, w, h, UI.col.line)
end

function SKIN:PaintNumberUp(panel, w, h) self:PaintButtonUp(panel, w, h) end
function SKIN:PaintNumberDown(panel, w, h) self:PaintButtonDown(panel, w, h) end

function SKIN:PaintTreeNode(panel, w, h)
    if not panel.m_bDrawLines then return end
    surface.SetDrawColor(UI.col.line2)
    if panel.m_bLastChild then
        surface.DrawRect(9, 0, 1, 7)
        surface.DrawRect(9, 7, 9, 1)
    else
        surface.DrawRect(9, 0, 1, h)
        surface.DrawRect(9, 7, 9, 1)
    end
end

function SKIN:PaintTreeNodeButton(panel, w, h)
    if not panel.m_bSelected then return end
    local tw = panel:GetTextSize()
    UI.Box(38, 0, tw + 6, h, UI.Accent(40))
end

function SKIN:PaintSelection(panel, w, h)
    UI.Box(0, 0, w, h, UI.Accent(40))
    UI.Outline(0, 0, w, h, UI.Accent(160))
end

function SKIN:PaintSliderKnob(panel, w, h)
    local hv = panel.Hovered or panel.Depressed
    UI.Box(math.floor(w / 2) - S(3), 0, S(6), h, hv and UI.Accent() or UI.col.cream)
end

local function PaintNotches(x, y, w, h, num)
    if not num then return end
    local space = w / num
    for i = 0, num do surface.DrawRect(x + i * space, y + 4, 1, 5) end
end

function SKIN:PaintNumSlider(panel, w, h)
    UI.Box(8, h / 2 - 1, w - 15, 2, UI.col.line3)
    surface.SetDrawColor(UI.col.line2)
    PaintNotches(8, h / 2 - 1, w - 16, 1, panel.m_iNotches)
end

function SKIN:PaintProgress(panel, w, h)
    UI.Bar(0, 0, w, h, panel:GetFraction(), UI.Accent())
end

function SKIN:PaintCollapsibleCategory(panel, w, h)
    if h <= panel:GetHeaderHeight() then
        UI.Box(0, 0, w, h, UI.col.panel2)
        UI.Box(0, 0, S(3), h, UI.col.line3)
        return
    end
    UI.Box(0, 0, w, panel:GetHeaderHeight(), UI.col.panel3)
    UI.Box(0, 0, S(3), panel:GetHeaderHeight(), UI.Accent())
    UI.Box(0, panel:GetHeaderHeight(), w, h - panel:GetHeaderHeight(), UI.col.panel)
end

function SKIN:PaintCategoryList(panel, w, h)
    UI.Box(0, 0, w, h, UI.col.panel)
end

function SKIN:PaintCategoryButton(panel, w, h)
    if panel.AltLine then
        UI.Box(0, 0, w, h, (panel.Depressed or panel.m_bSelected) and UI.Accent(40) or panel.Hovered and Color(255, 255, 255, 10) or Color(255, 255, 255, 4))
    else
        UI.Box(0, 0, w, h, (panel.Depressed or panel.m_bSelected) and UI.Accent(40) or panel.Hovered and Color(255, 255, 255, 10) or Color(0, 0, 0, 0))
    end
end

function SKIN:PaintListView(panel, w, h)
    if not panel.m_bBackground then return end
    UI.Box(0, 0, w, h, UI.col.panel)
    UI.Outline(0, 0, w, h, UI.col.line)
end

function SKIN:PaintListViewLine(panel, w, h)
    if panel:IsSelected() then
        UI.Box(0, 0, w, h, UI.Accent(45))
        UI.Box(0, 0, S(3), h, UI.Accent())
    elseif panel.Hovered then
        UI.Box(0, 0, w, h, Color(255, 255, 255, 12))
    elseif panel.m_bAlt then
        UI.Box(0, 0, w, h, Color(255, 255, 255, 5))
    end
end

function SKIN:PaintTooltip(panel, w, h)
    UI.Box(0, 0, w, h, Color(8, 10, 13, 245))
    UI.Outline(0, 0, w, h, UI.Accent(160))
end

function SKIN:PaintMenuBar(panel, w, h)
    UI.Box(0, 0, w, h, Color(0, 0, 0, 225))
    UI.Box(0, h - 1, w, 1, UI.Accent(70))
end

function SKIN:PaintSelectedPanel(panel, w, h)
    UI.Outline(0, 0, w, h, UI.Accent(), S(2))
end

derma.DefineSkin("SymChars", "Design des SymChars-Charaktermenüs", SKIN)

function UI.Skin(panel)
    if IsValid(panel) then panel:SetSkin("SymChars") end
    return panel
end

-- Optional: Skin für ALLE Derma-Fenster (auch Q-/C-Menü). Standard: aus.
local global = CreateClientConVar("symchars_ui_globalskin", "0", true, false, "SymChars-Design für alle Derma-Fenster (auch Q-/C-Menü)")
hook.Add("ForceDermaSkin", "symchars_globalskin", function()
    if global:GetBool() then return "SymChars" end
end)

hook.Run("symchars_ui_ready", UI)
