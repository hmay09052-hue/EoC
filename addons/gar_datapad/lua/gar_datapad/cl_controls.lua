--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Bedienelemente im Stil des Charaktermenues (SymChars)
    Alles bleibt innerhalb des Tablet-Bildschirms (Auswahllisten, Dialoge, Meldungen).
-------------------------------------------------------------------------------------------------------------]]

local D = GAR_DP.ui
local S = D.S

---------------------------------------------------------------------------------------------------------------
-- Button  (Stile: default, primary, danger, ghost, select, card, icon)
-- Ab ca. 40 px Hoehe steht Aurebesh unter dem Text.
---------------------------------------------------------------------------------------------------------------
local BTN = {}

function BTN:Init()
    self:SetText("")
    self._label = ""
    self._style = "default"
    self._font = "gdp.h4"
    self._align = TEXT_ALIGN_CENTER
    self._hover, self._sel = 0, 0
    self:SetCursor("hand")
end

function BTN:SetText(t) self._label = tostring(t or "") end
function BTN:GetText() return self._label end
function BTN:SetStyle(s) self._style = s return self end
function BTN:SetFont(f) self._font = f return self end
function BTN:SetAlign(a) self._align = a return self end
function BTN:SetIcon(i) self._icon = i return self end
function BTN:SetSub(t) self._sub = t return self end
function BTN:SetSelected(on) self._selected = on == true end
function BTN:SetAccentColor(c) self._accent = c return self end
function BTN:SetAurebesh(on) self._aure = on return self end

function BTN:OnCursorEntered() if self:IsEnabled() then D.Sound("hover") end end
function BTN:DoClickInternal() D.Sound("click") end

function BTN:Think()
    self._hover = D.Approach(self._hover, (self:IsHovered() and self:IsEnabled()) and 1 or 0, 14)
    self._sel = D.Approach(self._sel, self._selected and 1 or 0, 12)
end

function BTN:Paint(w, h)
    local style, hv, sel = self._style, self._hover, self._sel
    local accent = self._accent or D.Accent()
    local disabled = not self:IsEnabled()
    local textCol = D.col.text
    local c = S(7)

    if style == "primary" then
        local fill = disabled and D.Alpha(accent, 90) or D.Lerp(hv, accent, Color(math.min(255, accent.r + 25), math.min(255, accent.g + 25), math.min(255, accent.b + 25)))
        D.Cut(0, 0, w, h, fill, c, "tlbr")
        if hv > 0.01 and not disabled then D.Glow(0, 0, w, h, D.Alpha(accent, 200 * hv), S(7)) end
        textCol = D.col.ink
    elseif style == "danger" then
        D.Cut(0, 0, w, h, D.Lerp(hv, Color(90, 18, 18, 230), Color(150, 30, 28, 240)), c, "tlbr")
        D.CutOutline(0, 0, w, h, D.Alpha(D.col.red, 140 + hv * 115), c, "tlbr")
    elseif style == "ghost" then
        textCol = D.Lerp(math.max(hv, sel), D.col.dim, sel > 0.5 and accent or D.col.text)
        if sel > 0.01 then
            D.Box(0, 0, w, h, D.Alpha(accent, 26 * sel))
            D.Gradient(0, 0, w, h, D.Alpha(accent, 60 * sel), "up")
            D.Box(0, h - S(3), w, S(3), D.Alpha(accent, 255 * sel))
        end
        if hv > 0.01 and sel < 0.99 then D.Box(0, h - S(2), w, S(2), D.Alpha(accent, 130 * hv)) end
    elseif style == "select" then
        local active = math.max(hv * 0.5, sel)
        D.Box(0, 0, w, h, D.Lerp(hv, Color(8, 10, 13, 220), Color(18, 21, 26, 235)))
        if sel > 0.01 then D.Glow(0, 0, w, h, D.Alpha(accent, 255 * sel), S(8), 0.8) end
        D.Outline(0, 0, w, h, D.Lerp(active, D.col.line2, accent), sel > 0.5 and S(2) or 1)
        textCol = D.Lerp(sel, D.Lerp(hv, D.col.dim, D.col.text), accent)
    elseif style == "icon" then
        textCol = D.Lerp(hv, D.col.dim, accent)
    else
        D.Cut(0, 0, w, h, D.Lerp(hv, D.col.panel2, D.col.panel3), c, "tlbr")
        D.CutOutline(0, 0, w, h, D.Lerp(math.max(hv, sel), D.col.line2, accent), c, "tlbr")
        textCol = disabled and D.col.muted or D.Lerp(hv, D.col.dim, D.col.text)
    end

    local label = self._label
    local font = self._font
    local pad = S(10)
    local iconSize = self._icon and math.floor(math.min(h * 0.5, S(22))) or 0
    local _, lh = D.TextSize("Ag", font)
    local aureH = D.AurebeshHeight("gdp.aure.small")
    local aure = label ~= "" and self._aure ~= false and style ~= "icon" and h >= lh + aureH + S(2)
    local blockH = aure and (lh + aureH - S(6)) or lh
    local ty = math.floor((h - blockH) / 2)
    local up = string.upper(label)
    local tw = label ~= "" and D.TextSize(up, font) or 0
    local iconPart = iconSize > 0 and (iconSize + (label ~= "" and S(8) or 0)) or 0

    local tx
    if self._align == TEXT_ALIGN_LEFT then tx = pad + iconPart else tx = (w - tw - iconPart) / 2 + iconPart end
    if self._icon then
        local ix = label == "" and (w - iconSize) / 2 or (tx - iconSize - S(8))
        D.Icon(self._icon, ix, (h - iconSize) / 2, iconSize, textCol)
    end
    if label ~= "" then
        D.TextFit(up, font, tx, ty, textCol, w - tx - pad / 2)
        if aure then D.Aurebesh(label, "gdp.aure.small", tx + S(1), ty + lh - S(6), D.Alpha(textCol, 120), nil, nil, w - tx - pad) end
    end
    if self._sub then
        D.TextFit(self._sub, "gdp.tiny", tx, h - S(4), D.Alpha(textCol, 170), w - tx - pad, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end
    return true
end

vgui.Register("gdp.Button", BTN, "DButton")

function D.Button(parent, text, style, onClick)
    local b = vgui.Create("gdp.Button", parent)
    b:SetText(text)
    if style then b:SetStyle(style) end
    if onClick then b.DoClick = function(s) onClick(s) end end
    return b
end

---------------------------------------------------------------------------------------------------------------
-- Texteingabe: das Tablet nimmt die Tastatur nur, solange ein Feld aktiv ist
---------------------------------------------------------------------------------------------------------------
local ENTRY = {}

function ENTRY:Init()
    self:SetFont("gdp.input")
    self:SetTextColor(D.col.text)
    self:SetCursorColor(D.Accent())
    self:SetHighlightColor(D.Accent(90))
    self:SetPaintBackground(false)
    self:SetDrawLanguageID(false)
    self:SetUpdateOnType(true)
    self._focus = 0
    self.gdpEntry = true
end

function ENTRY:OnGetFocus()
    if IsValid(GAR_DP.tablet) then GAR_DP.tablet:SetKeyboardInputEnabled(true) end
    hook.Run("OnTextEntryGetFocus", self)
end

function ENTRY:OnLoseFocus()
    if IsValid(GAR_DP.tablet) then GAR_DP.tablet:SetKeyboardInputEnabled(false) end
    hook.Run("OnTextEntryLoseFocus", self)
end

function ENTRY:Think()
    self._focus = D.Approach(self._focus, self:HasFocus() and 1 or 0, 12)
end

function ENTRY:Paint(w, h)
    local accent = D.Accent()
    D.Box(0, 0, w, h, Color(4, 6, 8, 230))
    D.Outline(0, 0, w, h, D.Lerp(self._focus, D.col.line2, accent), self._focus > 0.5 and S(2) or 1)
    if self._focus > 0.01 then D.Glow(0, 0, w, h, D.Alpha(accent, 140 * self._focus), S(5), 0.6) end
    if self:GetValue() == "" and not self:HasFocus() and (self:GetPlaceholderText() or "") ~= "" then
        D.Text(self:GetPlaceholderText(), self:GetFont(), S(5), self:IsMultiline() and S(4) or h / 2, D.col.muted, TEXT_ALIGN_LEFT, self:IsMultiline() and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
    end
    self:DrawTextEntryText(D.col.text, D.Accent(90), D.Accent())
end

vgui.Register("gdp.Entry", ENTRY, "DTextEntry")

function D.Entry(parent, placeholder, value, multiline)
    local e = vgui.Create("gdp.Entry", parent)
    e:SetPlaceholderText(placeholder or "")
    if multiline then
        e:SetMultiline(true)
        e:SetVerticalScrollbarEnabled(true)
    end
    if value then e:SetValue(value) end
    return e
end

---------------------------------------------------------------------------------------------------------------
-- Scrollbereich
---------------------------------------------------------------------------------------------------------------
local SCROLL = {}

function SCROLL:Init()
    local bar = self:GetVBar()
    bar:SetWide(S(5))
    bar:SetHideButtons(true)
    bar.Paint = function(_, w, h) D.Box(w / 2 - 1, 0, 2, h, D.col.line) end
    bar.btnGrip.Paint = function(s, w, h) D.Box(0, 0, w, h, s:IsHovered() and D.Accent() or D.Accent(150)) end
    self:GetCanvas():DockPadding(0, 0, S(8), 0)
end

vgui.Register("gdp.Scroll", SCROLL, "DScrollPanel")

function D.Scroll(parent)
    return vgui.Create("gdp.Scroll", parent)
end

---------------------------------------------------------------------------------------------------------------
-- Auswahlliste (klappt innerhalb des Tablets auf)
---------------------------------------------------------------------------------------------------------------
local COMBO = {}

function COMBO:Init()
    self:SetText("")
    self._choices = {}
    self._placeholder = "Auswählen…"
    self._hover = 0
    self:SetCursor("hand")
end

function COMBO:Clear() self._choices = {} self._selected = nil end
function COMBO:SetPlaceholder(t) self._placeholder = t end
function COMBO:AddChoice(text, data, select, color)
    self._choices[#self._choices + 1] = { text = tostring(text), data = data, color = color }
    if select then self._selected = #self._choices end
end
function COMBO:GetSelectedData()
    local c = self._choices[self._selected or 0]
    return c and c.data
end
function COMBO:ChooseData(data)
    for i, c in ipairs(self._choices) do
        if c.data == data then self._selected = i return true end
    end
end
function COMBO:OnSelect() end

function COMBO:Think()
    self._hover = D.Approach(self._hover, (self:IsHovered() or IsValid(self._menu)) and 1 or 0, 14)
end

function COMBO:Paint(w, h)
    D.Box(0, 0, w, h, Color(4, 6, 8, 230))
    D.Outline(0, 0, w, h, D.Lerp(self._hover, D.col.line2, D.Accent()))
    local c = self._choices[self._selected or 0]
    local x = S(10)
    if c and c.color then D.Box(S(6), h / 2 - S(6), S(4), S(12), c.color) x = S(16) end
    D.TextFit(c and c.text or self._placeholder, "gdp.body", x, h / 2, c and D.col.text or D.col.muted, w - h - x, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    D.Icon("chevron", w - h + S(4), S(4), h - S(8), D.Lerp(self._hover, D.col.dim, D.Accent()))
    return true
end

function COMBO:DoClick()
    if IsValid(self._menu) then self._menu:Remove() return end
    local root = GAR_DP.tablet
    if not IsValid(root) then return end
    D.Sound("click")

    local catcher = vgui.Create("DPanel", root)
    catcher:SetSize(root:GetSize())
    catcher:SetZPos(30000)
    catcher.Paint = nil
    catcher.OnMousePressed = function(s) s:Remove() end
    catcher.gdpPopup = true
    self._menu = catcher

    local rowH = S(32)
    local sx, sy = self:LocalToScreen(0, self:GetTall())
    local x, y = root:ScreenToLocal(sx, sy)
    local w = self:GetWide()
    local h = math.min(#self._choices, 9) * rowH + S(4)
    if y + h > root:GetTall() - S(6) then y = y - self:GetTall() - h end
    y = math.max(S(4), y)

    local list = vgui.Create("DPanel", catcher)
    list:SetPos(x, y)
    list:SetSize(w, math.max(rowH, h))
    list.Paint = function(_, pw, ph)
        D.Box(0, 0, pw, ph, Color(8, 10, 13, 252))
        D.Outline(0, 0, pw, ph, D.Accent(160))
    end
    local scroll = D.Scroll(list)
    scroll:Dock(FILL)
    scroll:DockMargin(S(2), S(2), S(2), S(2))

    for i, choice in ipairs(self._choices) do
        local row = vgui.Create("DButton", scroll)
        row:Dock(TOP)
        row:SetTall(rowH)
        row:SetText("")
        row.Paint = function(s, rw, rh)
            local sel = i == self._selected
            if s:IsHovered() then D.Box(0, 0, rw, rh, D.Accent(40)) end
            if sel then D.Box(0, 0, S(3), rh, D.Accent()) end
            local tx = S(10)
            if choice.color then D.Box(S(8), rh / 2 - S(5), S(4), S(10), choice.color) tx = S(18) end
            D.TextFit(choice.text, "gdp.body", tx, rh / 2, sel and D.Accent() or D.col.text, rw - tx - S(6), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            return true
        end
        row.DoClick = function()
            D.Sound("click")
            self._selected = i
            if IsValid(catcher) then catcher:Remove() end
            self:OnSelect(choice.data, choice.text)
        end
    end
end

function COMBO:OnRemove()
    if IsValid(self._menu) then self._menu:Remove() end
end

vgui.Register("gdp.Combo", COMBO, "DButton")

function D.Combo(parent, placeholder, onSelect)
    local c = vgui.Create("gdp.Combo", parent)
    if placeholder then c:SetPlaceholder(placeholder) end
    if onSelect then c.OnSelect = function(_, data, text) onSelect(data, text) end end
    return c
end

function D.LevelCombo(parent, selected, maxLevel, minLevel, onSelect)
    local c = D.Combo(parent, "Stufe", onSelect)
    for lvl = minLevel or 1, math.max(minLevel or 1, maxLevel) do
        local data = GAR_DP.LevelData(lvl)
        c:AddChoice("Stufe " .. lvl .. "  ·  " .. data.name, lvl, lvl == selected, data.color)
    end
    if not c:GetSelectedData() then c:ChooseData(minLevel or 1) end
    return c
end

---------------------------------------------------------------------------------------------------------------
-- Haken
---------------------------------------------------------------------------------------------------------------
function D.Check(parent, label, value, onChange)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b._on = value == true
    b:SetCursor("hand")
    b.GetChecked = function(s) return s._on end
    b.DoClick = function(s)
        s._on = not s._on
        D.Sound("click")
        if onChange then onChange(s._on) end
    end
    b.Paint = function(s, w, h)
        local box = math.min(h - S(4), S(24))
        local y = (h - box) / 2
        D.Box(0, y, box, box, Color(4, 6, 8, 220))
        D.Outline(0, y, box, box, s:IsHovered() and D.Accent() or D.col.line3, S(2))
        if s._on then
            D.Box(S(4), y + S(4), box - S(8), box - S(8), D.Accent())
            D.Icon("check", S(4), y + S(4), box - S(8), D.col.ink)
        end
        local lab = string.upper(label)
        D.Text(lab, "gdp.h4", box + S(10), h / 2, s:IsHovered() and D.col.text or D.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        D.Aurebesh(label, "gdp.aure.small", box + S(18) + D.TextSize(lab, "gdp.h4"), h / 2, D.Alpha(D.col.dim, 110), nil, TEXT_ALIGN_CENTER)
        return true
    end
    return b
end

---------------------------------------------------------------------------------------------------------------
-- Unterreiter (wie AKTE | FORTBILDUNGEN | AKTIONEN im Menue)
---------------------------------------------------------------------------------------------------------------
function D.SubTabs(parent, tabs, onChange, active)
    local bar = vgui.Create("DPanel", parent)
    bar.Paint = function(_, w, h)
        D.Box(0, 0, w, h, Color(0, 0, 0, 170))
        D.Box(0, h - 1, w, 1, D.Accent(70))
    end
    bar.buttons = {}
    bar.SetActive = function(s, id, silent)
        s.active = id
        for _, b in ipairs(s.buttons) do b:SetSelected(b.id == id) end
        if not silent then onChange(id) end
    end
    for _, tab in ipairs(tabs) do
        local b = D.Button(bar, tab.name, "ghost", function() if bar.active ~= tab.id then bar:SetActive(tab.id) end end)
        b.id = tab.id
        b:SetFont("gdp.h3")
        b:Dock(LEFT)
        surface.SetFont("gdp.h3")
        b:SetWide(surface.GetTextSize(string.upper(tab.name)) + S(32))
        local basePaint = b.Paint
        b.Paint = function(s, w, h)
            basePaint(s, w, h)
            D.Box(w - 1, math.floor(h * 0.28), 1, math.floor(h * 0.44), Color(255, 255, 255, 18))
            return true
        end
        bar.buttons[#bar.buttons + 1] = b
    end
    bar:SetActive(active or tabs[1].id, true)
    return bar
end

---------------------------------------------------------------------------------------------------------------
-- Formularfeld: Beschriftung + Aurebesh, Steuerelement darunter
---------------------------------------------------------------------------------------------------------------
function D.Field(parent, label, height, dock)
    local f = vgui.Create("DPanel", parent)
    f:Dock(dock or TOP)
    f:DockMargin(0, 0, 0, S(8))
    local labelH = S(24)
    f:SetTall(labelH + (height or S(34)))
    f:DockPadding(0, labelH, 0, 0)
    f.Paint = function()
        local lab = string.upper(label)
        D.Text(lab, "gdp.h4", 0, 0, D.col.text)
        D.Aurebesh(label, "gdp.aure.small", D.TextSize(lab, "gdp.h4") + S(8), S(5), D.Alpha(D.col.dim, 110))
    end
    return f
end

---------------------------------------------------------------------------------------------------------------
-- Dialog innerhalb des Tablets (wie symchars.Frame; ESC / Zurueck schliesst ihn)
---------------------------------------------------------------------------------------------------------------
function D.Modal(title, w, h)
    local root = GAR_DP.tablet
    if not IsValid(root) then return end
    local overlay = vgui.Create("DPanel", root)
    overlay:SetSize(root:GetSize())
    overlay:SetZPos(20000)
    overlay.gdpPopup = true
    local start = RealTime()
    overlay.Paint = function(_, ow, oh)
        D.Box(0, 0, ow, oh, Color(0, 0, 0, 180 * math.min(1, (RealTime() - start) * 6)))
    end

    local card = vgui.Create("DPanel", overlay)
    card:SetSize(math.min(w, root:GetWide() - S(40)), math.min(h, root:GetTall() - S(40)))
    card:Center()
    card:DockPadding(S(20), S(74), S(20), S(16))
    card.Paint = function(_, cw, ch)
        D.Cut(0, 0, cw, ch, Color(9, 11, 14, 250), S(16), "tlbr")
        D.CutOutline(0, 0, cw, ch, D.Accent(120), S(16), "tlbr")
        D.Box(S(20), S(62), cw - S(40), 1, D.col.line2)
        D.Box(S(20), S(62), S(80), S(2), D.Accent())
        D.Heading(title, "gdp.h2", S(20), S(12), D.col.text, nil, cw - S(80))
    end

    local close = D.Button(card, "", "icon", function() overlay:Remove() D.Sound("click") end)
    close:SetIcon("close")
    close:SetSize(S(28), S(28))
    close:SetPos(card:GetWide() - S(44), S(18))

    card.Close = function() if IsValid(overlay) then overlay:Remove() end end
    overlay.card = card
    return card, overlay
end

function D.Confirm(title, text, onYes, yesText)
    local card = D.Modal(title, S(500), S(260))
    if not card then return end
    local lbl = vgui.Create("DLabel", card)
    lbl:Dock(FILL)
    lbl:SetWrap(true)
    lbl:SetContentAlignment(7)
    lbl:SetFont("gdp.body")
    lbl:SetTextColor(D.col.dim)
    lbl:SetText(text or "")
    local row = vgui.Create("DPanel", card)
    row:Dock(BOTTOM)
    row:SetTall(S(44))
    row.Paint = nil
    local no = D.Button(row, "Abbrechen", "default", function() card:Close() end)
    no:Dock(LEFT)
    no:SetWide(S(170))
    local yes = D.Button(row, yesText or "Bestätigen", "danger", function() card:Close() onYes() end)
    yes:Dock(RIGHT)
    yes:SetWide(S(190))
end

---------------------------------------------------------------------------------------------------------------
-- Leere Flaeche / Hinweis
---------------------------------------------------------------------------------------------------------------
function D.Placeholder(parent, text, icon)
    local p = vgui.Create("DPanel", parent)
    p:Dock(FILL)
    p.Paint = function(_, w, h)
        local s = S(48)
        D.Icon(icon or "info", w / 2 - s / 2, h / 2 - s - S(6), s, D.Alpha(D.col.dim, 90))
        D.Text(string.upper(text), "gdp.h3", w / 2, h / 2 + S(4), D.col.muted, TEXT_ALIGN_CENTER)
        D.Aurebesh(text, "gdp.aure.small", w / 2, h / 2 + S(32), D.Alpha(D.col.dim, 80), TEXT_ALIGN_CENTER, nil, w - S(40))
    end
    return p
end

---------------------------------------------------------------------------------------------------------------
-- Charakterlisten (wie die Mitgliederliste in VERWALTUNG)
---------------------------------------------------------------------------------------------------------------
function D.CharRow(parent, char, onClick, isSelected, extra)
    local row = vgui.Create("DButton", parent)
    row:Dock(TOP)
    row:SetTall(S(60))
    row:DockMargin(0, 0, 0, S(4))
    row:SetText("")
    row._hover = 0
    row.char = char
    row.Think = function(s) s._hover = D.Approach(s._hover, s:IsHovered() and 1 or 0, 14) end
    row.OnCursorEntered = function() D.Sound("hover") end
    row.Paint = function(s, w, h)
        local sel = isSelected and isSelected(char)
        local hv = s._hover
        local unitCol = D.Readable(select(2, D.CharUnit(char)))
        if sel then
            D.Box(0, 0, w, h, D.Accent(24))
            D.Outline(0, 0, w, h, D.Accent(220))
        else
            D.Box(0, 0, w, h, D.Lerp(hv, Color(8, 10, 13, 160), Color(18, 21, 26, 220)))
            if hv > 0.01 then D.Outline(0, 0, w, h, D.Alpha(D.col.line2, 255 * hv)) end
        end
        D.Box(0, 0, S(3), h, unitCol)
        local online = char:IsOnline()
        D.Circle(S(18), S(17), S(4), online and D.col.green or D.col.faint, 12)
        local name = D.CharName(char)
        D.TextFit(name, "gdp.body.b", S(30), S(5), D.col.text, w - S(40))
        local _, nh = D.TextSize("Ag", "gdp.body.b")
        D.Aurebesh(name, "gdp.aure.small", S(31), S(5) + nh - S(4), D.Alpha(D.col.dim, 90), nil, nil, w - S(40))
        local rank, rankCol = D.CharRank(char)
        D.TextFit((rank ~= "" and (rank .. "  ·  ") or "") .. D.CharUnit(char), "gdp.small", S(30), h - S(5), rankCol, w - S(40), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        if extra then extra(s, w, h) end
        return true
    end
    row.DoClick = function() D.Sound("click") onClick(char) end
    return row
end

function D.CharList(parent, opts)
    opts = opts or {}
    local wrap = vgui.Create("DPanel", parent)
    wrap.Paint = nil

    local search = D.Entry(wrap, opts.placeholder or "Name, RP-ID oder SteamID64…")
    search:Dock(TOP)
    search:SetTall(S(38))
    search:DockMargin(0, 0, 0, S(8))

    local info = vgui.Create("DPanel", wrap)
    info:Dock(TOP)
    info:SetTall(S(24))
    info.Paint = function(_, w, h)
        local t = string.upper(wrap.countText or "")
        D.Text(t, "gdp.h4", 0, 0, D.col.text)
        D.Aurebesh(wrap.countText or "", "gdp.aure.small", D.TextSize(t, "gdp.h4") + S(8), S(5), D.Alpha(D.col.dim, 90), nil, nil, w * 0.4)
    end

    local scroll = D.Scroll(wrap)
    scroll:Dock(FILL)
    scroll:DockMargin(0, S(4), 0, 0)

    function wrap:Refresh()
        scroll:Clear()
        local q = string.lower(string.Trim(search:GetValue() or ""))
        local shown = 0
        for _, char in ipairs(D.AllChars(opts.filter)) do
            if D.MatchChar(char, q) then
                shown = shown + 1
                if shown <= 250 then D.CharRow(scroll, char, opts.onSelect, opts.isSelected, opts.extra) end
            end
        end
        wrap.countText = shown .. " " .. (opts.countLabel or "Personen")
        if shown == 0 then
            local empty = vgui.Create("DPanel", scroll)
            empty:Dock(TOP)
            empty:SetTall(S(50))
            empty.Paint = function(_, w, h) D.Text(opts.emptyText or "Keine Einträge", "gdp.small", w / 2, h / 2, D.col.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
        end
    end
    search.OnValueChange = function() wrap:Refresh() end
    wrap.search = search
    wrap:Refresh()
    return wrap
end

---------------------------------------------------------------------------------------------------------------
-- Eintrags-Karte (wie die Akte-Eintraege: Strich links, Titel, Datum + Verfasser)
-- opts = { chips(item) -> { {text, color} }, meta(item) -> text, maxLines, onClick, onEdit, onDelete, accent(item) -> Color }
---------------------------------------------------------------------------------------------------------------
function D.RecordCard(parent, item, opts)
    opts = opts or {}
    local card = vgui.Create("DButton", parent)
    card:Dock(TOP)
    card:DockMargin(0, 0, 0, S(6))
    card:SetText("")
    card:SetTall(S(70))
    card._hover = 0
    card.item = item
    card:SetCursor(opts.onClick and "hand" or "arrow")
    card.Think = function(s) s._hover = D.Approach(s._hover, s:IsHovered() and 1 or 0, 14) end

    local body = item.body or item.preview or ""
    local _, lh = D.TextSize("Ag", "gdp.small")

    if not item.redacted then
        if item.canDelete and opts.onDelete then
            local del = D.Button(card, "", "icon", function() opts.onDelete(item) end)
            del:SetIcon("trash")
            del:SetSize(S(28), S(28))
            card.del = del
        end
        if item.canEdit and opts.onEdit then
            local edit = D.Button(card, "", "icon", function() opts.onEdit(item) end)
            edit:SetIcon("edit")
            edit:SetSize(S(28), S(28))
            card.edit = edit
        end
    end

    local TOP_H = S(58)
    card.PerformLayout = function(s, w)
        local x = w - S(6)
        if s.del then x = x - S(28) s.del:SetPos(x, S(6)) end
        if s.edit then x = x - S(28) s.edit:SetPos(x, S(6)) end
        local need
        if item.redacted then
            need = S(64)
        else
            local lines = body ~= "" and #D.Wrap(body, "gdp.small", w - S(30)) or 0
            if opts.maxLines then lines = math.min(lines, opts.maxLines) end
            need = TOP_H + lines * lh + (lines > 0 and S(8) or 0)
        end
        if s:GetTall() ~= need then s:SetTall(need) end
    end

    card.Paint = function(s, w, h)
        local hv = s._hover
        if item.redacted then
            local ld = GAR_DP.LevelData(item.level)
            D.Box(0, 0, w, h, Color(24, 8, 8, 220))
            D.Hatch(0, 0, w, h, D.Alpha(D.col.red, 16), S(10))
            D.Outline(0, 0, w, h, D.Alpha(D.col.red, 70 + hv * 60))
            D.Box(0, 0, S(3), h, D.col.red)
            D.Redacted(S(16), S(12), math.min(w * 0.55, S(360)), S(16), item.id)
            D.Text("ZUGRIFF VERWEIGERT  ·  FREIGABE STUFE " .. item.level .. " ERFORDERLICH", "gdp.tiny.b", S(16), h - S(10), D.Alpha(D.col.red, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
            local cw = D.ChipSize("Klassifiziert · Stufe " .. item.level)
            D.Chip("Klassifiziert · Stufe " .. item.level, w - cw - S(10), S(10), ld.color)
            return true
        end

        local accent = opts.accent and opts.accent(item) or D.Accent()
        D.Box(0, 0, w, h, D.Lerp(hv, Color(9, 11, 14, 200), Color(17, 20, 25, 230)))
        if opts.onClick and hv > 0.01 then D.Outline(0, 0, w, h, D.Alpha(D.Accent(), 200 * hv)) else D.Outline(0, 0, w, h, D.col.line) end
        D.Box(0, 0, S(3), h, accent)

        local cx = w - S(10) - (s.del and S(28) or 0) - (s.edit and S(28) or 0)
        local chips = { { "Stufe " .. item.level, GAR_DP.LevelData(item.level).color } }
        if opts.chips then for _, c in ipairs(opts.chips(item) or {}) do chips[#chips + 1] = c end end
        for i = #chips, 1, -1 do
            local c = chips[i]
            local cw = D.ChipSize(c[1])
            cx = cx - cw
            D.Chip(c[1], cx, S(10), c[2])
            cx = cx - S(6)
        end

        D.TextFit(item.title or "", "gdp.body.b", S(14), S(6), D.col.text, cx - S(20))
        local _, th = D.TextSize("Ag", "gdp.body.b")
        D.Aurebesh(item.title or "", "gdp.aure.small", S(15), S(6) + th - S(3), D.Alpha(D.col.dim, 100), nil, nil, cx - S(20))
        local meta = opts.meta and opts.meta(item) or (GAR_DP.FormatDate(item.created, true) .. "  ·  " .. (item.authorName or ""))
        D.TextFit(meta, "gdp.tiny", S(14), TOP_H - S(6), D.col.muted, w - S(28), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        if body ~= "" then
            D.DrawWrapped(body, "gdp.small", S(14), TOP_H, w - S(28), D.col.dim, opts.maxLines)
        end
        return true
    end

    if opts.onClick then card.DoClick = function() D.Sound("click") opts.onClick(item) end end
    return card
end

function D.FillRecords(scroll, items, opts, emptyText)
    scroll:Clear()
    if not items or #items == 0 then
        local empty = vgui.Create("DPanel", scroll)
        empty:Dock(TOP)
        empty:SetTall(S(80))
        empty.Paint = function(_, w, h)
            D.Text(emptyText or "Keine Einträge vorhanden.", "gdp.body", w / 2, h / 2 - S(6), D.col.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            D.Aurebesh(emptyText or "Keine Eintraege", "gdp.aure.small", w / 2, h / 2 + S(10), D.Alpha(D.col.dim, 70), TEXT_ALIGN_CENTER, nil, w - S(20))
        end
        return
    end
    for _, item in ipairs(items) do D.RecordCard(scroll, item, opts) end
end

-- Kopfzeile einer Spalte: Titel + Aurebesh links (wie "2 MITGLIEDER"), Knoepfe rechts
function D.ColumnHeader(parent, title, sub)
    local head = vgui.Create("DPanel", parent)
    head:Dock(TOP)
    head:SetTall(S(52))
    head:DockMargin(0, 0, 0, S(8))
    head.Paint = function(_, w, h)
        local t = isfunction(title) and title() or title
        local st = isfunction(sub) and sub() or sub
        D.Heading(t or "", "gdp.h2", 0, 0, D.col.text, nil, w * 0.6)
        if st and st ~= "" then D.TextFit(st, "gdp.tiny", w * 0.6, h - S(6), D.col.muted, w * 0.4, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM) end
        D.Box(0, h - 1, w, 1, D.col.line2)
    end
    head.AddButton = function(s, text, style, icon, onClick)
        local b = D.Button(s, text, style, onClick)
        if icon then b:SetIcon(icon) end
        b:SetFont("gdp.h4")
        b:SetAurebesh(false)
        b:Dock(RIGHT)
        b:DockMargin(S(6), S(6), 0, S(10))
        surface.SetFont("gdp.h4")
        b:SetWide((text ~= "" and surface.GetTextSize(string.upper(text)) or 0) + (icon and S(34) or 0) + S(26))
        return b
    end
    return head
end
