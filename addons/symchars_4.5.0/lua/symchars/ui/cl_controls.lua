--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Bedienelemente
    symchars.Button, symchars.Entry, symchars.Check, symchars.Combo, symchars.Scroll, symchars.Frame,
    symchars.Tabs, symchars.ColorButton, symchars.Picker (Mehrfachauswahl mit Suche)
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S

---------------------------------------------------------------------------------------------------------------
-- Button
---------------------------------------------------------------------------------------------------------------
local BTN = {}

function BTN:Init()
    self:SetText("")
    self._label = ""
    self._style = "default"
    self._font = "symchars.button"
    self._align = TEXT_ALIGN_CENTER
    self._hover = 0
    self._sel = 0
    self:SetCursor("hand")
end

function BTN:SetText(text) self._label = tostring(text or "") end
function BTN:GetText() return self._label end
function BTN:SetLabel(text) self._label = tostring(text or "") end
function BTN:SetStyle(style) self._style = style return self end
function BTN:SetFont(font) self._font = font return self end
function BTN:SetAlign(align) self._align = align return self end
function BTN:SetIcon(icon) self._icon = icon return self end
function BTN:SetSubText(text) self._sub = text return self end
function BTN:SetAurebesh(on) self._aure = on return self end
function BTN:SetSelected(on) self._selected = on == true end
function BTN:IsSelected() return self._selected == true end
function BTN:SetLocked(text) self._locked = text end
function BTN:SetAccentColor(col) self._accentCol = col return self end
function BTN:SetBadge(n) self._badge = n end

function BTN:OnCursorEntered()
    if self:IsEnabled() then UI.Sound("hover") end
end

function BTN:DoClickInternal()
    if self._locked then UI.Sound("error") return end
    UI.Sound("click")
end

function BTN:Think()
    local hovered = self:IsHovered() and self:IsEnabled()
    self._hover = UI.Approach(self._hover, hovered and 1 or 0, 14)
    self._sel = UI.Approach(self._sel, self._selected and 1 or 0, 12)
end

function BTN:Paint(w, h)
    local style, hv, sel = self._style, self._hover, self._sel
    local accent = self._accentCol or UI.Accent()
    local disabled = not self:IsEnabled()
    local textCol = UI.col.text
    local c = S(8)

    if self._locked then
        UI.Box(0, 0, w, h, Color(60, 10, 10, 220))
        UI.Outline(0, 0, w, h, Color(150, 30, 30, 200 + hv * 55))
        textCol = Color(150, 70, 70)
    elseif style == "primary" then
        local fill = disabled and UI.Darken(accent, 0.35) or UI.Lerp(hv, accent, Color(math.min(255, accent.r + 25), math.min(255, accent.g + 25), math.min(255, accent.b + 25)))
        UI.Cut(0, 0, w, h, fill, c, "tlbr")
        if hv > 0.01 and not disabled then UI.Glow(0, 0, w, h, UI.Alpha(accent, 200 * hv), S(8)) end
        textCol = disabled and UI.Alpha(UI.col.ink, 160) or UI.col.ink
    elseif style == "danger" then
        local red = UI.col.red
        UI.Cut(0, 0, w, h, UI.Lerp(hv, Color(90, 18, 18, 230), Color(150, 30, 28, 240)), c, "tlbr")
        UI.CutOutline(0, 0, w, h, UI.Alpha(red, 140 + hv * 115), c, "tlbr")
        textCol = disabled and UI.col.muted or UI.col.text
    elseif style == "ghost" then
        textCol = UI.Lerp(math.max(hv, sel), UI.col.dim, UI.col.text)
        if sel > 0.01 then UI.Box(0, h - S(3), w, S(3), UI.Alpha(accent, 255 * sel)) end
    elseif style == "select" then
        local active = math.max(hv * 0.5, sel)
        UI.Box(0, 0, w, h, UI.Lerp(hv, Color(8, 10, 13, 220), Color(18, 21, 26, 235)))
        if sel > 0.01 then UI.Glow(0, 0, w, h, UI.Alpha(accent, 255 * sel), S(9), 0.8) end
        UI.Outline(0, 0, w, h, UI.Lerp(active, UI.col.line2, accent), sel > 0.5 and S(2) or 1)
        textCol = UI.Lerp(sel, UI.Lerp(hv, UI.col.dim, UI.col.text), accent)
    elseif style == "card" then
        UI.Box(0, 0, w, h, UI.Lerp(hv, UI.col.panel, UI.col.panel2))
        UI.Outline(0, 0, w, h, UI.Lerp(math.max(hv, sel), UI.col.line, accent))
    else
        UI.Cut(0, 0, w, h, UI.Lerp(hv, UI.col.panel2, UI.col.panel3), c, "tlbr")
        UI.CutOutline(0, 0, w, h, UI.Lerp(math.max(hv, sel), UI.col.line2, accent), c, "tlbr")
        textCol = disabled and UI.col.muted or UI.Lerp(hv, UI.col.dim, UI.col.text)
    end

    local label = self._locked and (self._label .. "  -  " .. self._locked) or self._label
    local font = self._font
    local pad = S(14)
    local iconSize = self._icon and math.floor(h * 0.5) or 0
    local tx = self._align == TEXT_ALIGN_LEFT and pad + (iconSize > 0 and iconSize + S(10) or 0) or w / 2
    local ty = h / 2

    if self._icon then
        local ix = self._align == TEXT_ALIGN_LEFT and pad or (w / 2 - (UI.TextSize(label, font) + iconSize + S(8)) / 2)
        UI.Icon(self._icon, ix, (h - iconSize) / 2, iconSize, textCol)
        if self._align ~= TEXT_ALIGN_LEFT then tx = ix + iconSize + S(8) + UI.TextSize(label, font) / 2 end
    end

    local maxW = w - pad * 2 - (iconSize > 0 and iconSize + S(10) or 0)
    if self._sub or self._aure then
        -- Text + Unterzeile als Block mittig setzen, Schrift verkleinern, falls der Button zu flach ist
        local subFont = self._sub and "symchars.tiny" or "symchars.aure.small"
        local sh = self._sub and select(2, UI.TextSize("Ag", subFont)) or UI.AurebeshHeight(subFont)
        local _, lh = UI.TextSize("Ag", font)
        for _, smaller in ipairs({ "symchars.h3", "symchars.h4", "symchars.small.bold" }) do
            if lh + sh - S(4) <= h - S(4) then break end
            font = smaller
            _, lh = UI.TextSize("Ag", font)
        end
        local top = math.floor((h - (lh + sh - S(4))) / 2)
        UI.TextFit(label, font, tx, top, textCol, maxW, self._align, TEXT_ALIGN_TOP)
        if self._sub then
            UI.TextFit(self._sub, subFont, tx, top + lh - S(4), UI.Alpha(textCol, 170), maxW, self._align, TEXT_ALIGN_TOP)
        else
            UI.Aurebesh(label, subFont, tx, top + lh - S(4), UI.Alpha(textCol, 120), self._align, TEXT_ALIGN_TOP, maxW)
        end
    else
        local _, lh = UI.TextSize("Ag", font)
        for _, smaller in ipairs({ "symchars.h3", "symchars.h4", "symchars.small.bold" }) do
            if lh <= h then break end
            font = smaller
            _, lh = UI.TextSize("Ag", font)
        end
        UI.TextFit(label, font, tx, ty, textCol, maxW, self._align, TEXT_ALIGN_CENTER)
    end

    if self._badge and self._badge > 0 then
        local r = S(10)
        UI.Circle(w - r - S(4), r + S(4), r, UI.col.red, 20)
        UI.Text(self._badge > 99 and "99" or tostring(self._badge), "symchars.tiny.bold", w - r - S(4), r + S(4), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return true
end

vgui.Register("symchars.Button", BTN, "DButton")

function UI.Button(parent, text, style, onClick)
    local b = vgui.Create("symchars.Button", parent)
    b:SetText(text)
    if style then b:SetStyle(style) end
    if onClick then b.DoClick = onClick end
    return b
end

---------------------------------------------------------------------------------------------------------------
-- Texteingabe
---------------------------------------------------------------------------------------------------------------
local ENTRY = {}

function ENTRY:Init()
    self:SetFont("symchars.input")
    self:SetTextColor(UI.col.text)
    self:SetCursorColor(UI.Accent())
    self:SetHighlightColor(UI.Accent(90))
    self:SetPaintBackground(false)
    self._focus = 0
    self:SetUpdateOnType(true)
end

function ENTRY:Think()
    self._focus = UI.Approach(self._focus, self:HasFocus() and 1 or 0, 12)
end

function ENTRY:SetError(on) self._error = on end

function ENTRY:Paint(w, h)
    local accent = UI.Accent()
    UI.Box(0, 0, w, h, Color(4, 6, 8, 230))
    local border = self._error and UI.col.red or UI.Lerp(self._focus, UI.col.line2, accent)
    UI.Outline(0, 0, w, h, border, self._focus > 0.5 and S(2) or 1)
    if self._focus > 0.01 then UI.Glow(0, 0, w, h, UI.Alpha(accent, 140 * self._focus), S(6), 0.6) end

    -- Platzhalter an derselben Stelle wie der eingegebene Text (TextEntry rückt ca. 3-5 px ein)
    if self:GetValue() == "" and self:GetPlaceholderText() and self:GetPlaceholderText() ~= "" and not self:HasFocus() then
        local ty = self:IsMultiline() and S(3) or h / 2
        UI.Text(self:GetPlaceholderText(), self:GetFont(), S(4), ty, UI.col.muted, TEXT_ALIGN_LEFT, self:IsMultiline() and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
    end
    self:DrawTextEntryText(UI.col.text, UI.Accent(90), UI.Accent())
end

vgui.Register("symchars.Entry", ENTRY, "DTextEntry")

function UI.Entry(parent, placeholder, value)
    local e = vgui.Create("symchars.Entry", parent)
    e:SetPlaceholderText(placeholder or "")
    if value then e:SetValue(value) end
    return e
end

---------------------------------------------------------------------------------------------------------------
-- Checkbox
---------------------------------------------------------------------------------------------------------------
local CHECK = {}

function CHECK:Init()
    self:SetText("")
    self._checked = false
    self._label = ""
    self._font = "symchars.h3"
    self._anim = 0
    self:SetCursor("hand")
end

function CHECK:SetLabel(text) self._label = tostring(text or "") return self end
function CHECK:SetFont(font) self._font = font return self end
function CHECK:SetChecked(on) self._checked = on == true end
function CHECK:GetChecked() return self._checked end
function CHECK:SetValue(on) self:SetChecked(on) end
function CHECK:GetValue() return self._checked end
function CHECK:OnChange() end

function CHECK:DoClick()
    self._checked = not self._checked
    UI.Sound("click")
    self:OnChange(self._checked)
end

function CHECK:Think()
    self._anim = UI.Approach(self._anim, self._checked and 1 or 0, 16)
end

function CHECK:Paint(w, h)
    local box = math.min(h - S(4), S(42))
    local y = (h - box) / 2
    local hovered = self:IsHovered()
    UI.Box(0, y, box, box, Color(4, 6, 8, 220))
    UI.Outline(0, y, box, box, hovered and UI.Accent() or UI.col.line3, S(2))
    if self._anim > 0.01 then
        local inset = S(6)
        UI.Box(inset, y + inset, box - inset * 2, box - inset * 2, UI.Accent(255 * self._anim))
        UI.Icon("check", inset, y + inset, box - inset * 2, UI.Alpha(UI.col.ink, 255 * self._anim))
    end
    UI.Text(self._label, self._font, box + S(12), h / 2, hovered and UI.col.text or UI.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    return true
end

vgui.Register("symchars.Check", CHECK, "DButton")

function UI.Check(parent, label, value, onChange)
    local c = vgui.Create("symchars.Check", parent)
    c:SetLabel(label)
    c:SetChecked(value)
    if onChange then c.OnChange = function(_, v) onChange(v) end end
    return c
end

---------------------------------------------------------------------------------------------------------------
-- Scrollbereich
---------------------------------------------------------------------------------------------------------------
local SCROLL = {}

function SCROLL:Init()
    local bar = self:GetVBar()
    bar:SetWide(S(6))
    bar:SetHideButtons(true)
    bar.Paint = function(_, w, h) UI.Box(w / 2 - 1, 0, 2, h, UI.col.line) end
    bar.btnGrip.Paint = function(s, w, h)
        UI.Box(0, 0, w, h, s:IsHovered() and UI.Accent() or UI.Accent(150))
    end
    self:GetCanvas():DockPadding(0, 0, S(8), 0)
end

vgui.Register("symchars.Scroll", SCROLL, "DScrollPanel")

function UI.Scroll(parent)
    return vgui.Create("symchars.Scroll", parent)
end

---------------------------------------------------------------------------------------------------------------
-- Dropdown
---------------------------------------------------------------------------------------------------------------
local COMBO = {}

function COMBO:Init()
    self:SetText("")
    self._choices = {}
    self._selected = nil
    self._placeholder = "Auswählen…"
    self._font = "symchars.body"
    self._hover = 0
    self:SetCursor("hand")
end

function COMBO:Clear()
    self._choices = {}
    self._selected = nil
end

-- depth: Einrückung (für Untereinheiten), sub: kleiner Zusatztext
function COMBO:AddChoice(text, data, select, depth, sub)
    self._choices[#self._choices + 1] = { text = tostring(text), data = data, depth = depth or 0, sub = sub }
    if select then self._selected = #self._choices end
    return #self._choices
end

function COMBO:SetPlaceholder(text) self._placeholder = text end
function COMBO:SetFont(font) self._font = font end
function COMBO:SetValue(text) self._placeholder = text end
function COMBO:GetSelectedID() return self._selected end
function COMBO:GetSelected()
    local c = self._choices[self._selected or 0]
    if c then return c.text, c.data end
end
function COMBO:GetSelectedData()
    local c = self._choices[self._selected or 0]
    return c and c.data
end

function COMBO:ChooseOptionID(i, silent)
    if not self._choices[i] then return end
    self._selected = i
    if not silent then self:OnSelect(i, self._choices[i].text, self._choices[i].data) end
end

function COMBO:ChooseData(data, silent)
    for i, c in ipairs(self._choices) do
        if c.data == data then self:ChooseOptionID(i, silent) return true end
    end
    return false
end

function COMBO:OnSelect() end

function COMBO:Think()
    self._hover = UI.Approach(self._hover, (self:IsHovered() or IsValid(self._menu)) and 1 or 0, 14)
end

function COMBO:Paint(w, h)
    UI.Box(0, 0, w, h, Color(4, 6, 8, 230))
    UI.Outline(0, 0, w, h, UI.Lerp(self._hover, UI.col.line2, UI.Accent()))
    local c = self._choices[self._selected or 0]
    local text = c and c.text or self._placeholder
    UI.TextFit(text, self._font, S(10), h / 2, c and UI.col.text or UI.col.muted, w - h - S(14), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    UI.Icon("chevron", w - h + S(4), S(4), h - S(8), UI.Lerp(self._hover, UI.col.dim, UI.Accent()))
    return true
end

function COMBO:DoClick()
    if IsValid(self._menu) then self._menu:Remove() return end
    UI.Sound("click")
    local x, y = self:LocalToScreen(0, self:GetTall())
    local rowH = S(34)
    local w = self:GetWide()
    local maxRows = math.min(#self._choices, 10)
    local h = math.max(rowH, maxRows * rowH) + S(4)
    if y + h > ScrH() - S(20) then y = select(2, self:LocalToScreen(0, 0)) - h end

    local catcher = vgui.Create("EditablePanel")
    catcher:SetSize(ScrW(), ScrH())
    catcher:MakePopup()
    catcher:SetKeyboardInputEnabled(false)
    catcher.Paint = function() end
    catcher.OnMousePressed = function(s) s:Remove() end
    self._menu = catcher

    local list = vgui.Create("DPanel", catcher)
    list:SetPos(x, y)
    list:SetSize(w, h)
    list.Paint = function(_, pw, ph)
        UI.Box(0, 0, pw, ph, Color(8, 10, 13, 250))
        UI.Outline(0, 0, pw, ph, UI.Accent(160))
    end

    local scroll = UI.Scroll(list)
    scroll:Dock(FILL)
    scroll:DockMargin(S(2), S(2), S(2), S(2))

    if #self._choices == 0 then
        local empty = vgui.Create("DLabel", scroll)
        empty:Dock(TOP)
        empty:SetTall(rowH)
        empty:SetFont("symchars.small")
        empty:SetText("  Keine Einträge")
        empty:SetTextColor(UI.col.muted)
    end

    for i, choice in ipairs(self._choices) do
        local row = vgui.Create("DButton", scroll)
        row:Dock(TOP)
        row:SetTall(rowH)
        row:SetText("")
        row.Paint = function(s, rw, rh)
            local sel = i == self._selected
            if s:IsHovered() then UI.Box(0, 0, rw, rh, UI.Accent(40)) end
            if sel then UI.Box(0, 0, S(3), rh, UI.Accent()) end
            local x0 = S(10) + choice.depth * S(18)
            if choice.depth > 0 then
                surface.SetDrawColor(UI.col.line2)
                surface.DrawLine(x0 - S(10), 0, x0 - S(10), rh / 2)
                surface.DrawLine(x0 - S(10), rh / 2, x0 - S(3), rh / 2)
            end
            UI.TextFit(choice.text, self._font, x0, rh / 2, sel and UI.Accent() or UI.col.text, rw - x0 - S(10), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if choice.sub then UI.Text(choice.sub, "symchars.tiny", rw - S(10), rh / 2, UI.col.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
            return true
        end
        row.DoClick = function()
            UI.Sound("click")
            self:ChooseOptionID(i)
            if IsValid(catcher) then catcher:Remove() end
        end
    end
end

function COMBO:OnRemove()
    if IsValid(self._menu) then self._menu:Remove() end
end

vgui.Register("symchars.Combo", COMBO, "DButton")

function UI.Combo(parent, placeholder, onSelect)
    local c = vgui.Create("symchars.Combo", parent)
    if placeholder then c:SetPlaceholder(placeholder) end
    if onSelect then c.OnSelect = function(_, i, text, data) onSelect(data, text, i) end end
    return c
end

-- Dropdown mit allen Einheiten in Baumreihenfolge
function UI.FillUnitCombo(combo, selected, opts)
    opts = opts or {}
    combo:Clear()
    if opts.none then combo:AddChoice(opts.none, "", selected == "" or selected == nil) end
    for _, item in ipairs(symchars.factions.GetHierarchyList()) do
        if not opts.filter or opts.filter(item.data) then
            combo:AddChoice(item.label, item.id, item.id == selected, item.depth)
        end
    end
end

function UI.FillJobCombo(combo, selected, none)
    combo:Clear()
    if none then combo:AddChoice(none, "", selected == "" or selected == nil) end
    local jobs = {}
    for _, job in pairs(RPExtraTeams or {}) do jobs[#jobs + 1] = job end
    table.sort(jobs, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    for _, job in ipairs(jobs) do combo:AddChoice(job.name, job.command, job.command == selected, 0, job.command) end
end

---------------------------------------------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------------------------------------------
local FRAME = {}

function FRAME:Init()
    self._title = ""
    self:DockPadding(S(22), S(78), S(22), S(20))
    self._open = 0
    self.startTime = SysTime()

    self.close = vgui.Create("DButton", self)
    self.close:SetText("")
    self.close.Paint = function(s, w, h)
        UI.Icon("close", 0, 0, w, s:IsHovered() and UI.col.red or UI.col.dim)
        return true
    end
    self.close.DoClick = function() UI.Sound("click") self:Close() end
end

function FRAME:SetTitle(text) self._title = tostring(text or "") end
function FRAME:Close() self:Remove() end

function FRAME:PerformLayout(w, h)
    self.close:SetSize(S(26), S(26))
    self.close:SetPos(w - S(42), S(22))
end

function FRAME:OnMousePressed(code)
    if code == MOUSE_LEFT then
        local _, my = self:CursorPos()
        if my < S(64) then
            self._drag = { gui.MouseX() - self.x, gui.MouseY() - self.y }
            self:MouseCapture(true)
        end
    end
end

function FRAME:OnMouseReleased()
    self._drag = nil
    self:MouseCapture(false)
end

function FRAME:Think()
    if self._drag then
        self:SetPos(math.Clamp(gui.MouseX() - self._drag[1], 0, ScrW() - self:GetWide()), math.Clamp(gui.MouseY() - self._drag[2], 0, ScrH() - self:GetTall()))
    end
end

function FRAME:OnKeyCodePressed(key)
    if key == KEY_ESCAPE then self:Close() end
end

function FRAME:Paint(w, h)
    Derma_DrawBackgroundBlur(self, self.startTime)
    UI.Cut(0, 0, w, h, Color(9, 11, 14, 248), S(16), "tlbr")
    UI.CutOutline(0, 0, w, h, UI.Accent(120), S(16), "tlbr")
    UI.Box(S(22), S(66), w - S(44), 1, UI.col.line2)
    UI.Box(S(22), S(66), S(80), S(2), UI.Accent())
    UI.Text(string.upper(self._title), "symchars.h2", S(22), S(14), UI.col.text)
    UI.Aurebesh(self._title, "symchars.aure.small", S(24), S(46), UI.Alpha(UI.col.dim, 120))
end

vgui.Register("symchars.Frame", FRAME, "EditablePanel")

function UI.Frame(title, w, h)
    local f = vgui.Create("symchars.Frame")
    f:SetTitle(title)
    f:SetSize(math.min(w, ScrW() - S(40)), math.min(h, ScrH() - S(40)))
    f:Center()
    f:MakePopup()
    UI.Sound("open")
    return f
end

---------------------------------------------------------------------------------------------------------------
-- Formularfeld (Titel + Beschreibung + Steuerelement)
---------------------------------------------------------------------------------------------------------------
function UI.Field(parent, label, desc, height)
    local field = vgui.Create("DPanel", parent)
    field:Dock(TOP)
    field:DockMargin(0, 0, 0, S(14))
    local labelH = S(30)
    local descH = 0
    if desc and desc ~= "" then descH = S(20) end
    field:SetTall(labelH + descH + (height or S(42)))
    field:DockPadding(0, labelH + descH, 0, 0)
    field.Paint = function(_, w)
        UI.Text(string.upper(label), "symchars.h3", 0, 0, UI.col.text)
        if descH > 0 then UI.TextFit(desc, "symchars.tiny", 0, labelH - S(4), UI.col.muted, w) end
    end
    return field
end

---------------------------------------------------------------------------------------------------------------
-- Tabs: schwarze Leiste, aktiver Reiter orange mit Leuchtkante, Aurebesh unter dem Namen
---------------------------------------------------------------------------------------------------------------
local TABS = {}

-- Schriften von groß nach klein, die kleinste, bei der alle Reiter passen, wird genommen
local TAB_FONTS = { "symchars.tab", "symchars.h1", "symchars.h2", "symchars.h3", "symchars.h4" }

function TABS:Init()
    self._tabs = {}
    self._active = nil
    self._font = "symchars.tab"
    self._maxFont = 1
    self._pad = S(26)
    self._bg = true
end

-- SetFont legt die größte erlaubte Schrift fest (wird bei Platzmangel verkleinert)
function TABS:SetFont(font)
    self._maxFont = 1
    for i, f in ipairs(TAB_FONTS) do if f == font then self._maxFont = i end end
    self._font = font
    self:InvalidateLayout()
end
function TABS:SetGap(gap) self._pad = math.max(S(10), math.floor(gap / 2)) self:InvalidateLayout() end
function TABS:SetBackground(on) self._bg = on end

function TABS:Paint(w, h)
    if not self._bg then return end
    UI.Box(0, 0, w, h, Color(0, 0, 0, 225))
    UI.Box(0, h - 1, w, 1, UI.Accent(70))
end

function TABS:SetTabs(list)
    for _, child in ipairs(self:GetChildren()) do child:Remove() end
    self._tabs = {}
    for _, tab in ipairs(list) do
        local b = vgui.Create("DButton", self)
        b:SetText("")
        b.tab = tab
        b._hover = 0
        b._act = 0
        b.Think = function(s)
            s._hover = UI.Approach(s._hover, s:IsHovered() and 1 or 0, 12)
            s._act = UI.Approach(s._act, self._active == tab.id and 1 or 0, 14)
        end
        b.OnCursorEntered = function() UI.Sound("hover") end
        b.Paint = function(s, w, h)
            local accent = UI.Accent()
            local act, hv = s._act, s._hover
            local font = self._font

            -- Fläche
            if act > 0.01 then
                UI.Box(0, 0, w, h, UI.Accent(30 * act))
                UI.Gradient(0, 0, w, h, UI.Accent(70 * act), "up")
                UI.Box(0, h - S(3), w, S(3), UI.Accent(255 * act))
                UI.Box(0, 0, w, 1, UI.Accent(60 * act))
            end
            if hv > 0.01 and act < 0.99 then
                UI.Box(0, 0, w, h, UI.Accent(16 * hv * (1 - act)))
                UI.Box(0, h - S(2), w, S(2), UI.Accent(130 * hv * (1 - act)))
            end
            UI.Box(w - 1, math.floor(h * 0.28), 1, math.floor(h * 0.44), Color(255, 255, 255, 16))

            -- Text mittig, Aurebesh darunter (nur wenn genug Platz)
            local col = UI.Lerp(act, UI.Lerp(hv, UI.col.dim, UI.col.text), accent)
            local label = string.upper(tab.name)
            local _, lh = UI.TextSize("Ag", font)
            local ah = UI.AurebeshHeight("symchars.aure.small")
            local aure = h >= lh + ah + S(2)
            local blockH = aure and (lh + ah - S(4)) or lh
            local y = math.floor((h - blockH) / 2)
            UI.Text(label, font, w / 2, y, col, TEXT_ALIGN_CENTER)
            if aure then UI.Aurebesh(tab.name, "symchars.aure.small", w / 2, y + lh - S(4), UI.Alpha(col, 90 + 110 * act), TEXT_ALIGN_CENTER) end

            if tab.badge and tab.badge > 0 then
                local r = S(9)
                UI.Circle(w - r - S(4), r + S(4), r, UI.col.red, 18)
                UI.Text(tostring(math.min(tab.badge, 99)), "symchars.tiny.bold", w - r - S(4), r + S(4), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            return true
        end
        b.DoClick = function()
            if self._active == tab.id then return end
            UI.Sound("click")
            self:SetActive(tab.id)
        end
        self._tabs[#self._tabs + 1] = b
    end
    self:InvalidateLayout(true)
end

function TABS:SetBadge(id, n)
    for _, b in ipairs(self._tabs) do
        if b.tab.id == id then b.tab.badge = n end
    end
end

function TABS:SetActive(id, silent)
    self._active = id
    if not silent then self:OnChange(id) end
end

function TABS:GetActive() return self._active end
function TABS:OnChange() end

function TABS:PerformLayout(w, h)
    -- größte Schrift wählen, bei der alle Reiter in die Breite passen
    local font, pad = TAB_FONTS[#TAB_FONTS], self._pad
    for i = self._maxFont, #TAB_FONTS do
        local f = TAB_FONTS[i]
        local _, lh = UI.TextSize("Ag", f)
        local total = 0
        for _, b in ipairs(self._tabs) do total = total + UI.TextSize(string.upper(b.tab.name), f) + pad * 2 end
        if total <= w and lh <= h then font = f break end
    end
    self._font = font

    local x = 0
    for _, b in ipairs(self._tabs) do
        local tw = UI.TextSize(string.upper(b.tab.name), font) + pad * 2
        b:SetPos(x, 0)
        b:SetSize(tw, h)
        x = x + tw
    end
end

-- Breite, die alle Reiter mit der aktuellen Schrift brauchen
function TABS:GetContentWidth()
    local total = 0
    for _, b in ipairs(self._tabs) do total = total + b:GetWide() end
    return total
end

vgui.Register("symchars.Tabs", TABS, "DPanel")

---------------------------------------------------------------------------------------------------------------
-- Farbauswahl
---------------------------------------------------------------------------------------------------------------
local COLORBTN = {}

function COLORBTN:Init()
    self:SetText("")
    self._color = Color(255, 255, 255)
end

function COLORBTN:SetColor(col) self._color = Color(col.r, col.g, col.b, col.a or 255) end
function COLORBTN:GetColor() return self._color end
function COLORBTN:OnChange() end

function COLORBTN:Paint(w, h)
    UI.Box(0, 0, w, h, Color(4, 6, 8, 230))
    UI.Box(S(4), S(4), h - S(8), h - S(8), self._color)
    UI.Outline(0, 0, w, h, self:IsHovered() and UI.Accent() or UI.col.line2)
    UI.Text(symchars.util.ColorToHex(self._color), "symchars.body", h + S(4), h / 2, UI.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    return true
end

function COLORBTN:DoClick()
    local f = UI.Frame("Farbe wählen", S(420), S(420))
    local mixer = vgui.Create("DColorMixer", f)
    mixer:Dock(FILL)
    mixer:SetPalette(true)
    mixer:SetAlphaBar(false)
    mixer:SetWangs(true)
    mixer:SetColor(self._color)
    local ok = UI.Button(f, "Übernehmen", "primary", function()
        local c = mixer:GetColor()
        self._color = Color(c.r, c.g, c.b, 255)
        self:OnChange(self._color)
        f:Close()
    end)
    ok:Dock(BOTTOM)
    ok:SetTall(S(44))
    ok:DockMargin(0, S(10), 0, 0)
end

vgui.Register("symchars.ColorButton", COLORBTN, "DButton")

---------------------------------------------------------------------------------------------------------------
-- Mehrfachauswahl mit Suche (Einheiten, Jobs, Waffen, Fahrzeuge ...)
-- items = { { id, text, sub, depth } }
---------------------------------------------------------------------------------------------------------------
local PICKER = {}

function PICKER:Init()
    self._items = {}
    self._selected = {}
    self.search = UI.Entry(self, "Suchen…")
    self.search:Dock(TOP)
    self.search:SetTall(S(36))
    self.search.OnValueChange = function() self:Rebuild() end
    self.list = UI.Scroll(self)
    self.list:Dock(FILL)
    self.list:DockMargin(0, S(6), 0, 0)
    self.info = vgui.Create("DLabel", self)
    self.info:Dock(BOTTOM)
    self.info:SetTall(S(22))
    self.info:SetFont("symchars.tiny")
    self.info:SetTextColor(UI.col.muted)
end

function PICKER:SetItems(items) self._items = items or {} self:Rebuild() end
function PICKER:SetSelected(list)
    self._selected = {}
    for _, id in ipairs(list or {}) do self._selected[id] = true end
    self:Rebuild()
end
function PICKER:SetSingle(on) self._single = on end
function PICKER:GetSelected()
    local out = {}
    for _, item in ipairs(self._items) do
        if self._selected[item.id] then out[#out + 1] = item.id end
    end
    for id in pairs(self._selected) do
        local known = false
        for _, item in ipairs(self._items) do if item.id == id then known = true break end end
        if not known then out[#out + 1] = id end
    end
    return out
end
function PICKER:OnChange() end

function PICKER:Rebuild()
    self.list:Clear()
    local q = string.lower(self.search:GetValue() or "")
    local shown = 0
    for _, item in ipairs(self._items) do
        local hay = string.lower(item.text .. " " .. (item.sub or "") .. " " .. item.id)
        if q == "" or string.find(hay, q, 1, true) then
            shown = shown + 1
            if shown <= 400 then
                local row = vgui.Create("DButton", self.list)
                row:Dock(TOP)
                row:SetTall(S(30))
                row:SetText("")
                row.Paint = function(s, w, h)
                    local on = self._selected[item.id] == true
                    if s:IsHovered() then UI.Box(0, 0, w, h, UI.Accent(30)) end
                    local x = S(6) + (item.depth or 0) * S(16)
                    local box = S(16)
                    UI.Outline(x, (h - box) / 2, box, box, on and UI.Accent() or UI.col.line3)
                    if on then UI.Box(x + S(3), (h - box) / 2 + S(3), box - S(6), box - S(6), UI.Accent()) end
                    UI.TextFit(item.text, "symchars.small", x + box + S(8), h / 2, on and UI.col.text or UI.col.dim, w - x - box - S(140), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    if item.sub then UI.TextFit(item.sub, "symchars.tiny", w - S(6), h / 2, UI.col.muted, S(130), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
                    return true
                end
                row.DoClick = function()
                    UI.Sound("click")
                    if self._single then self._selected = {} end
                    self._selected[item.id] = not self._selected[item.id] or nil
                    self:OnChange(self:GetSelected())
                    self:UpdateInfo()
                end
            end
        end
    end
    self:UpdateInfo()
end

function PICKER:UpdateInfo()
    local n = 0
    for _ in pairs(self._selected) do n = n + 1 end
    self.info:SetText(n .. " ausgewählt")
end

function PICKER:Paint(w, h) end

vgui.Register("symchars.Picker", PICKER, "DPanel")

function UI.UnitItems()
    local items = {}
    for _, item in ipairs(symchars.factions.GetHierarchyList()) do
        items[#items + 1] = { id = item.id, text = item.label, sub = item.data.short, depth = item.depth }
    end
    return items
end

function UI.JobItems()
    local items = {}
    for _, job in pairs(RPExtraTeams or {}) do items[#items + 1] = { id = job.command, text = job.name, sub = job.command } end
    table.sort(items, function(a, b) return string.lower(a.text) < string.lower(b.text) end)
    return items
end

function UI.WeaponItems()
    local items = {}
    for class, data in pairs(list.Get("Weapon") or {}) do
        items[#items + 1] = { id = class, text = (data.PrintName and data.PrintName ~= "") and language.GetPhrase(data.PrintName) or class, sub = class }
    end
    table.sort(items, function(a, b) return string.lower(a.text) < string.lower(b.text) end)
    return items
end

function UI.VehicleItems()
    local items, seen = {}, {}
    for class, data in pairs(list.Get("SpawnableEntities") or {}) do
        local cat = string.lower(tostring(data.Category or ""))
        local lower = string.lower(class)
        if string.find(lower, "lvs") or string.find(lower, "lfs") or string.find(lower, "veh") or string.find(cat, "lvs") or string.find(cat, "lfs") or string.find(cat, "fahrzeug") or string.find(cat, "vehicle") or string.find(cat, "star wars") then
            seen[class] = true
            items[#items + 1] = { id = class, text = (data.PrintName and data.PrintName ~= "") and language.GetPhrase(data.PrintName) or class, sub = class }
        end
    end
    for class, data in pairs(list.Get("Vehicles") or {}) do
        if not seen[class] then items[#items + 1] = { id = class, text = data.Name or class, sub = class } end
    end
    for _, job in pairs(RPExtraTeams or {}) do
        for _, class in ipairs(istable(job.vehicles) and job.vehicles or {}) do
            if not seen[class] then
                seen[class] = true
                local stored = scripted_ents.Get(class)
                items[#items + 1] = { id = class, text = stored and stored.PrintName or class, sub = class }
            end
        end
    end
    table.sort(items, function(a, b) return string.lower(a.text) < string.lower(b.text) end)
    return items
end

---------------------------------------------------------------------------------------------------------------
-- Dialoge
---------------------------------------------------------------------------------------------------------------
function UI.Confirm(title, text, onYes, onNo, yesText)
    local f = UI.Frame(title or "Bestätigen", S(520), S(260))
    local lbl = vgui.Create("DLabel", f)
    lbl:Dock(FILL)
    lbl:SetWrap(true)
    lbl:SetContentAlignment(7)
    lbl:SetFont("symchars.body")
    lbl:SetTextColor(UI.col.dim)
    lbl:SetText(text or "")
    local row = vgui.Create("DPanel", f)
    row:Dock(BOTTOM)
    row:SetTall(S(44))
    row.Paint = nil
    local no = UI.Button(row, "Abbrechen", "default", function() f:Close() if onNo then onNo() end end)
    no:Dock(LEFT)
    no:SetWide(S(200))
    local yes = UI.Button(row, yesText or "Bestätigen", "primary", function() f:Close() if onYes then onYes() end end)
    yes:Dock(RIGHT)
    yes:SetWide(S(220))
    return f
end

-- opts: { numeric = bool, multiline = bool, placeholder }
function UI.Prompt(title, text, default, onDone, opts)
    opts = opts or {}
    local f = UI.Frame(title or "Eingabe", S(560), opts.multiline and S(420) or S(300))
    local lbl = vgui.Create("DLabel", f)
    lbl:Dock(TOP)
    lbl:SetTall(S(40))
    lbl:SetWrap(true)
    lbl:SetFont("symchars.body")
    lbl:SetTextColor(UI.col.dim)
    lbl:SetText(text or "")
    local entry = UI.Entry(f, opts.placeholder or "", default and tostring(default) or "")
    entry:Dock(opts.multiline and FILL or TOP)
    entry:SetTall(S(44))
    entry:DockMargin(0, S(8), 0, S(8))
    if opts.multiline then entry:SetMultiline(true) end
    if opts.numeric then entry:SetNumeric(true) end
    entry:RequestFocus()
    local row = vgui.Create("DPanel", f)
    row:Dock(BOTTOM)
    row:SetTall(S(44))
    row.Paint = nil
    local cancel = UI.Button(row, "Abbrechen", "default", function() f:Close() end)
    cancel:Dock(LEFT)
    cancel:SetWide(S(200))
    local function Submit()
        local v = entry:GetValue()
        f:Close()
        if onDone then onDone(v) end
    end
    local ok = UI.Button(row, "OK", "primary", Submit)
    ok:Dock(RIGHT)
    ok:SetWide(S(220))
    if not opts.multiline then entry.OnEnter = Submit end
    return f
end

-- choices = { { text, data, sub } }
function UI.Choose(title, text, choices, onPick)
    local f = UI.Frame(title or "Auswahl", S(560), S(560))
    if text and text ~= "" then
        local lbl = vgui.Create("DLabel", f)
        lbl:Dock(TOP)
        lbl:SetTall(S(34))
        lbl:SetFont("symchars.body")
        lbl:SetTextColor(UI.col.dim)
        lbl:SetText(text)
    end
    local scroll = UI.Scroll(f)
    scroll:Dock(FILL)
    for _, choice in ipairs(choices) do
        local b = UI.Button(scroll, choice[1], "select", function() f:Close() onPick(choice[2], choice[1]) end)
        b:Dock(TOP)
        b:SetTall(choice[3] and S(60) or S(48))
        b:DockMargin(0, 0, 0, S(6))
        b:SetAlign(TEXT_ALIGN_LEFT)
        b:SetFont("symchars.h3")
        if choice[3] then b:SetSubText(choice[3]) end
        if choice.color then b:SetAccentColor(UI.Readable(choice.color)) end
        if choice.depth and choice.depth > 0 then b:DockMargin(choice.depth * S(22), 0, 0, S(6)) end
    end
    return f
end
