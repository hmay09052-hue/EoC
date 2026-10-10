-- UI-Bausteine im Stil des Echoes of Clones HUD (wie Militärisches Funksystem)

GARLog.UI = GARLog.UI or {}
local UI = GARLog.UI
local cfg = GARLog.Config

local E = EOCUI
local C = {
    yellow  = Color(252, 178, 73),
    yellowD = Color(252, 178, 73, 56),
    yellowF = Color(252, 178, 73, 22),
    white   = Color(236, 233, 224),
    text    = Color(236, 233, 224),
    soft    = Color(168, 174, 180),
    muted   = Color(112, 119, 127),
    bg      = Color(6, 8, 11, 245),
    panel   = Color(11, 14, 18, 232),
    panel2  = Color(18, 22, 28, 240),
    panel3  = Color(27, 32, 40, 245),
    line    = Color(255, 255, 255, 22),
    lineS   = Color(255, 255, 255, 50),
    red     = Color(205, 62, 56),
    green   = Color(95, 200, 120),
    blue    = Color(80, 170, 230),
    cyan    = Color(64, 196, 255),
    orange  = Color(240, 140, 60),
    purple  = Color(190, 120, 255),
    ink     = Color(18, 21, 25),
    barBG   = Color(255, 255, 255, 14),
}
C.accent = C.yellow
UI.C = C

-- Design wie das Charaktersystem: BigNoodleTitling für Überschriften, Roboto Condensed für Text
local HEAD, BODY = "BigNoodleTitling", "Roboto Condensed"
surface.CreateFont("GARLog_Title",   { font = HEAD, size = 40, weight = 500, extended = true })
surface.CreateFont("GARLog_Big",     { font = HEAD, size = 34, weight = 500, extended = true })
surface.CreateFont("GARLog_Head",    { font = HEAD, size = 26, weight = 500, extended = true })
surface.CreateFont("GARLog_Button",  { font = HEAD, size = 25, weight = 500, extended = true })
surface.CreateFont("GARLog_ButtonS", { font = HEAD, size = 21, weight = 500, extended = true })
surface.CreateFont("GARLog_Tab",     { font = HEAD, size = 30, weight = 500, extended = true })
surface.CreateFont("GARLog_Sub",     { font = BODY, size = 13, weight = 800, extended = true })
surface.CreateFont("GARLog_Section", { font = HEAD, size = 26, weight = 500, extended = true })
surface.CreateFont("GARLog_Text",    { font = BODY, size = 17, weight = 500, extended = true })
surface.CreateFont("GARLog_Small",   { font = BODY, size = 15, weight = 500, extended = true })
surface.CreateFont("GARLog_Tiny",    { font = BODY, size = 13, weight = 700, extended = true })

-- Welt-Anzeigen (3D2D, werden klein skaliert)
surface.CreateFont("GARLog_W_Title", { font = HEAD, size = 70, weight = 500, extended = true })
surface.CreateFont("GARLog_W_Head",  { font = HEAD, size = 46, weight = 500, extended = true })
surface.CreateFont("GARLog_W_Text",  { font = BODY, size = 28, weight = 600, extended = true })
surface.CreateFont("GARLog_W_Small", { font = BODY, size = 22, weight = 600, extended = true })

-- Platte mit abgeschrägten Ecken
local function Plate(x, y, w, h, col, outline, cut, corners)
    cut = cut or 7
    if not E or w < cut * 2 + 2 or h < cut * 2 + 2 then
        surface.SetDrawColor(col)
        surface.DrawRect(x, y, w, h)
        if outline then surface.SetDrawColor(outline) surface.DrawOutlinedRect(x, y, w, h, 1) end
        return
    end
    E.Cut(x, y, w, h, col, cut, corners or "br")
    if outline then E.CutOutline(x, y, w, h, outline, cut, corners or "br") end
end
UI.Plate = Plate
function UI.Click() surface.PlaySound("ui/buttonclickrelease.wav") end
function UI.ErrorSound() surface.PlaySound(cfg.Sounds.Error) end

---------------------------------------------------------------------------
-- Zeichnen
---------------------------------------------------------------------------
function UI.Bar(x, y, w, h, frac, col, bg)
    surface.SetDrawColor(bg or C.panel3)
    surface.DrawRect(x, y, w, h)
    frac = math.Clamp(frac or 0, 0, 1)
    if frac > 0 then
        surface.SetDrawColor(col or C.yellow)
        surface.DrawRect(x, y, math.max(1, math.floor(w * frac)), h)
    end
    if w > 60 then
        surface.SetDrawColor(6, 8, 11, 190)
        for i = 1, 19 do surface.DrawRect(x + math.floor(w * i / 20), y, 1, h) end
    end
end

-- Kleines umrandetes Etikett; Rückgabe: Breite
function UI.Tag(text, x, y, col, font, alignRight)
    font = font or "GARLog_Tiny"
    surface.SetFont(font)
    local tw, th = surface.GetTextSize(text)
    local w, h = tw + 12, th + 4
    if alignRight then x = x - w end
    Plate(x, y - h / 2, w, h, ColorAlpha(col, 40), ColorAlpha(col, 170), 4, "tlbr")
    draw.SimpleText(text, font, x + 6, y, col, 0, 1)
    return w
end

function UI.Corners(w, h, col, len)
    len = len or 14
    surface.SetDrawColor(col or C.yellow)
    surface.DrawRect(0, 0, len, 2)
    surface.DrawRect(0, 0, 2, len)
    surface.DrawRect(w - len, h - 2, len, 2)
    surface.DrawRect(w - 2, h - len, 2, len)
end

-- Kürzt Text auf eine Breite. Wird in Paint-Funktionen pro Frame aufgerufen ->
-- Ergebnis zwischenspeichern und per Binärsuche kürzen (statt Zeichen für Zeichen).
local truncCache, truncCount = {}, 0
function UI.Truncate(text, font, maxW)
    text = tostring(text or "")
    maxW = math.floor(maxW)
    local key = font .. "\1" .. maxW .. "\1" .. text
    local hit = truncCache[key]
    if hit then return hit end

    surface.SetFont(font)
    local res = text
    if surface.GetTextSize(text) > maxW then
        local chars = utf8.len(text)
        local function prefix(n)
            if chars then return text:sub(1, (utf8.offset(text, n + 1) or (#text + 1)) - 1) end
            return text:sub(1, n)
        end
        local lo, hi = 0, chars or #text
        while lo < hi do
            local mid = math.ceil((lo + hi) / 2)
            if surface.GetTextSize(prefix(mid) .. "…") <= maxW then lo = mid else hi = mid - 1 end
        end
        res = prefix(lo) .. "…"
    end

    truncCount = truncCount + 1
    if truncCount > 4096 then truncCache, truncCount = {}, 0 end
    truncCache[key] = res
    return res
end

---------------------------------------------------------------------------
-- Bausteine
---------------------------------------------------------------------------
function UI.Button(parent, label, onClick)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Label = label
    b.Accent = C.yellow
    b.Paint = function(s, w, h)
        local enabled = s:IsEnabled()
        local hov = s:IsHovered() and enabled
        local bg = s.Active and ColorAlpha(s.Accent, 30) or (hov and C.panel3 or C.panel2)
        if s.Solid and enabled then bg = hov and s.Accent or ColorAlpha(s.Accent, 225) end
        local outline = (s.Active or s.Solid) and enabled and ColorAlpha(s.Accent, 200) or (hov and C.lineS or C.line)
        Plate(0, 0, w, h, bg, outline, math.min(7, h / 4), "br")
        if s.Active then
            surface.SetDrawColor(s.Accent)
            if s.SideMark then surface.DrawRect(0, 0, 3, h) else surface.DrawRect(0, h - 2, w - 6, 2) end
        end

        local tc = not enabled and C.muted or (s.Solid and C.ink or (s.Active and s.Accent or C.white))
        local ax = s.AlignLeft and 0 or 1
        local tx = s.AlignLeft and 14 or w / 2
        if s.Sub then
            draw.SimpleText(s.Label, s.Font or "GARLog_Button", tx, h / 2 - 8, tc, ax, 1)
            draw.SimpleText(s.Sub, "GARLog_Tiny", tx, h / 2 + 11, s.SubColor or (s.Active and ColorAlpha(s.Accent, 200) or C.soft), ax, 1)
        else
            draw.SimpleText(s.Label, s.Font or "GARLog_Button", tx, h / 2, tc, ax, 1)
        end
        if s.Badge and s.Badge > 0 then
            local bw = UI.Tag(tostring(s.Badge), w - 8, h / 2, s.BadgeColor or C.yellow, "GARLog_Tiny", true)
        end
    end
    b.OnCursorEntered = function(s) if s:IsEnabled() then surface.PlaySound("ui/buttonrollover.wav") end end
    b.DoClick = function(s)
        UI.Click()
        if onClick then onClick(s) end
    end
    return b
end

function UI.Entry(parent, placeholder, multiline)
    local e = vgui.Create("DTextEntry", parent)
    e:SetFont("GARLog_Text")
    e:SetMultiline(multiline or false)
    e.Placeholder = placeholder
    e.Paint = function(s, w, h)
        Plate(0, 0, w, h, C.panel, s:HasFocus() and ColorAlpha(C.yellow, 190) or C.lineS, 6, "br")
        if s:GetText() == "" and s.Placeholder then
            draw.SimpleText(s.Placeholder, "GARLog_Text", 6, s:IsMultiline() and 4 or h / 2, C.muted, 0, s:IsMultiline() and 0 or 1)
        end
        s:DrawTextEntryText(C.white, ColorAlpha(C.yellow, 70), C.yellow)
    end
    return e
end

function UI.Section(parent, text, tall)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(tall or 26)
    p.Text = text
    p:SetTall(math.max(tall or 30, 30))
    p.Paint = function(s, w, h)
        local up = string.upper(s.Text)
        local tw = draw.SimpleText(up, "GARLog_Section", 0, h / 2 + 1, C.white, 0, 1)
        surface.SetDrawColor(C.lineS)
        surface.DrawRect(tw + 10, h / 2 + 2, math.max(0, w - tw - 10), 1)
        if E then E.Aurebesh(s.Text, "eocui.aure.small", w, h / 2 - 12, ColorAlpha(C.soft, 110), TEXT_ALIGN_RIGHT) end
    end
    return p
end

function UI.Spacer(parent, h)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(h)
    p.Paint = nil
    return p
end

function UI.StyleScroll(scroll)
    local bar = scroll:GetVBar()
    bar:SetWide(4)
    bar.Paint = function(_, w, h) surface.SetDrawColor(C.line) surface.DrawRect(0, 0, w, h) end
    bar.btnUp.Paint = function() end
    bar.btnDown.Paint = function() end
    bar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(C.yellow) surface.DrawRect(0, 0, w, h) end
end

function UI.Scroll(parent)
    local s = vgui.Create("DScrollPanel", parent)
    UI.StyleScroll(s)
    return s
end

function UI.Framed(parent)
    local p = vgui.Create("DPanel", parent)
    p.Paint = function(_, w, h)
        Plate(0, 0, w, h, C.panel, C.line, 10, "tlbr")
    end
    return p
end

function UI.Label(parent, text, font, color, tall)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP)
    l:SetFont(font or "GARLog_Small")
    l:SetTextColor(color or C.muted)
    l:SetWrap(true)
    l:SetAutoStretchVertical(tall == nil)
    if tall then l:SetTall(tall) end
    l:SetText(text or "")
    return l
end

function UI.Empty(parent, text)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP)
    l:SetTall(60)
    l:SetFont("GARLog_Small")
    l:SetTextColor(C.muted)
    l:SetContentAlignment(5)
    l:SetText(text)
    return l
end

-- Auswahlfeld im HUD-Stil. options = { { label, value }, ... }
function UI.Combo(parent, options, selected, onSelect)
    local b = UI.Button(parent, "")
    b.AlignLeft = true
    b.Font = "GARLog_ButtonS"
    b.Options, b.Value = options, selected

    local function sync()
        b.Label = "—"
        for _, o in ipairs(b.Options) do
            if o[2] == b.Value then b.Label = o[1] end
        end
    end
    function b:SetOptions(opts, value)
        self.Options = opts
        if value ~= nil then self.Value = value end
        sync()
    end
    function b:SetValue(v) self.Value = v sync() end
    function b:GetValue() return self.Value end

    local basePaint = b.Paint
    b.Paint = function(s, w, h)
        basePaint(s, w, h)
        local cx, cy = w - 14, h / 2
        surface.SetDrawColor(C.soft)
        draw.NoTexture()
        surface.DrawPoly({ { x = cx - 5, y = cy - 3 }, { x = cx + 5, y = cy - 3 }, { x = cx, y = cy + 3 } })
    end
    b.DoClick = function(s)
        UI.Click()
        local m = DermaMenu()
        m.Paint = function(_, w, h)
            surface.SetDrawColor(C.bg)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(C.lineS)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        for _, o in ipairs(s.Options) do
            local opt = m:AddOption(o[1], function()
                s.Value = o[2]
                sync()
                if onSelect then onSelect(o[2]) end
            end)
            opt:SetFont("GARLog_Small")
            opt:SetTextColor(o[2] == s.Value and C.yellow or C.white)
            opt.Paint = function(p, w, h)
                if p:IsHovered() then
                    surface.SetDrawColor(C.yellowF)
                    surface.DrawRect(0, 0, w, h)
                end
            end
        end
        m:SetMinimumWidth(s:GetWide())
        local x, y = s:LocalToScreen(0, s:GetTall())
        m:Open(x, y)
    end
    sync()
    return b
end

---------------------------------------------------------------------------
-- Güterauswahl: Zeilen je Ressource mit - / Eingabe / + / MAX
-- opts = { items = {}, max = {} | nil, list = {res...} | nil, onChange = fn(items) }
---------------------------------------------------------------------------
function UI.ItemPicker(parent, opts)
    local p = vgui.Create("DPanel", parent)
    p.Paint = nil
    p.Items = table.Copy(opts.items or {})
    p.Max = opts.max
    p.Rows = {}
    local list = opts.list or GARLog.ResOrder
    local ROW = 34

    local function changed()
        if opts.onChange then opts.onChange(p:GetItems()) end
    end

    local function clamp(res, n)
        n = math.max(0, math.floor(tonumber(n) or 0))
        if p.Max then n = math.min(n, p.Max[res] or 0) end
        return n
    end

    for i, res in ipairs(list) do
        local r = GARLog.Res[res]
        local row = vgui.Create("DPanel", p)
        row:Dock(TOP)
        row:SetTall(ROW)
        row:DockMargin(0, 0, 0, 4)
        row.Paint = function(_, w, h)
            surface.SetDrawColor(C.panel)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(C.line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            surface.SetDrawColor(r.color)
            surface.DrawRect(0, 0, 2, h)
            draw.SimpleText(r.name:upper(), "GARLog_ButtonS", 12, h / 2, C.white, 0, 1)
            if p.Max then
                draw.SimpleText("VERFÜGBAR " .. GARLog.FmtNum(p.Max[res] or 0), "GARLog_Tiny", 140, h / 2, (p.Max[res] or 0) > 0 and C.soft or C.muted, 0, 1)
            elseif p.Hint then
                local have, want = p.Hint[res] or 0, p.Items[res] or 0
                draw.SimpleText("IM LAGER " .. GARLog.FmtNum(have), "GARLog_Tiny", 140, h / 2, want > have and C.orange or C.soft, 0, 1)
            end
        end

        local maxB = UI.Button(row, "MAX", function()
            if not p.Max then return end
            p:SetAmount(res, p.Max[res] or 0)
            changed()
        end)
        maxB.Font = "GARLog_ButtonS"
        maxB:Dock(RIGHT)
        maxB:SetWide(46)
        maxB:DockMargin(2, 4, 4, 4)
        maxB:SetVisible(p.Max ~= nil)

        local plus = UI.Button(row, "+", function()
            local step = input.IsKeyDown(KEY_LSHIFT) and 100 or (input.IsKeyDown(KEY_LCONTROL) and 1 or 10)
            p:SetAmount(res, (p.Items[res] or 0) + step)
            changed()
        end)
        plus:Dock(RIGHT)
        plus:SetWide(30)
        plus:DockMargin(2, 4, 2, 4)

        local entry = UI.Entry(row, "0")
        entry:SetNumeric(true)
        entry:Dock(RIGHT)
        entry:SetWide(80)
        entry:DockMargin(2, 4, 2, 4)
        entry:SetText((p.Items[res] or 0) > 0 and tostring(p.Items[res]) or "")
        entry.OnChange = function(s)
            local n = clamp(res, s:GetText())
            p.Items[res] = n > 0 and n or nil
            changed()
        end
        entry.OnLoseFocus = function(s)
            s:SetText((p.Items[res] or 0) > 0 and tostring(p.Items[res]) or "")
        end

        local minus = UI.Button(row, "-", function()
            local step = input.IsKeyDown(KEY_LSHIFT) and 100 or (input.IsKeyDown(KEY_LCONTROL) and 1 or 10)
            p:SetAmount(res, (p.Items[res] or 0) - step)
            changed()
        end)
        minus:Dock(RIGHT)
        minus:SetWide(30)
        minus:DockMargin(2, 4, 2, 4)

        p.Rows[res] = { entry = entry, max = maxB }
    end
    p:SetTall(#list * (ROW + 4))

    function p:SetAmount(res, n)
        n = clamp(res, n)
        self.Items[res] = n > 0 and n or nil
        local row = self.Rows[res]
        if row then row.entry:SetText(n > 0 and tostring(n) or "") end
    end

    function p:SetMax(max)
        self.Max = max
        for res, row in pairs(self.Rows) do
            row.max:SetVisible(max ~= nil)
            if max and (self.Items[res] or 0) > (max[res] or 0) then self:SetAmount(res, max[res] or 0) end
        end
        changed()
    end

    function p:SetItems(items)
        for res in pairs(self.Rows) do self:SetAmount(res, (items or {})[res] or 0) end
        changed()
    end

    function p:GetItems()
        local out = {}
        for res, n in pairs(self.Items) do
            if n and n > 0 then out[res] = n end
        end
        return out
    end

    return p
end

-- Kapazitätsanzeige (FE) für Container / Shuttle
function UI.CapacityBar(parent, capacity, label)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(40)
    p.Volume, p.Capacity = 0, capacity
    p.Paint = function(s, w, h)
        local frac = s.Volume / math.max(1, s.Capacity)
        local col = frac > 1 and C.red or (frac > 0.85 and C.orange or C.yellow)
        draw.SimpleText(label or "LADUNG", "GARLog_Section", 0, 10, C.soft, 0, 1)
        draw.SimpleText(GARLog.FmtNum(s.Volume) .. " / " .. GARLog.FmtNum(s.Capacity) .. " FE", "GARLog_Section", w, 10, col, 2, 1)
        UI.Bar(0, 24, w, 8, frac, col)
    end
    return p
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
local function CloseButton(f, x)
    local close = UI.Button(f, "X", function() f:Close() end)
    close.Accent = C.red
    close:SetSize(34, 34)
    close:SetPos(x, 14)
    return close
end

-- Hauptfenster wie beim Funksystem. statusFn() -> text, farbe
function UI.Frame(title, sub, w, h, statusFn)
    w, h = math.min(w, ScrW() - 40), math.min(h, ScrH() - 40)
    local f = vgui.Create("DFrame")
    f:SetSize(w, h)
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetDraggable(true)
    f:DockPadding(20, 80, 20, 20)
    f:MakePopup()
    f:SetAlpha(0)
    f:AlphaTo(255, 0.15)
    f.TitleText, f.SubText = title, sub

    f.Paint = function(s, pw, ph)
        Plate(0, 0, pw, ph, C.bg, ColorAlpha(C.yellow, 90), 20, "tlbr")
        surface.SetDrawColor(C.panel)
        surface.DrawRect(20, 1, pw - 21, 61)
        surface.SetDrawColor(C.yellowD)
        surface.DrawRect(0, 62, pw, 1)
        surface.SetDrawColor(C.yellow)
        surface.DrawRect(20, 62, 180, 2)

        draw.SimpleText(string.upper(s.TitleText or ""), "GARLog_Title", 22, 4, C.white, 0, 0)
        if E then E.Aurebesh(s.TitleText or "", "eocui.aure.small", 24, 37, ColorAlpha(C.white, 100)) end
        local subW = draw.SimpleText(string.upper(s.SubText or ""), "GARLog_Sub", 24, 52, C.yellow, 0, 1)
        if statusFn then
            local text, col = statusFn()
            if text then draw.SimpleText("//  " .. text, "GARLog_Sub", 24 + subW + 8, 52, col or C.green, 0, 1) end
        end
        if E then E.EdgeMarks(5, 80, ph - 110, ColorAlpha(C.white, 60), 3) end
    end

    f.CloseBtn = CloseButton(f, w - 48)

    UI.Stack[#UI.Stack + 1] = f
    f.OnRemove = function(s)
        for i = #UI.Stack, 1, -1 do
            if UI.Stack[i] == s then table.remove(UI.Stack, i) end
        end
        if s.OnRemoved then s:OnRemoved() end
    end
    return f
end

-- ESC schließt nur das oberste Logistik-Fenster
UI.Stack = UI.Stack or {}
local escDown = false
hook.Add("Think", "GARLog_UIEscape", function()
    local down = input.IsKeyDown(KEY_ESCAPE)
    if down and not escDown then
        for i = #UI.Stack, 1, -1 do
            local top = UI.Stack[i]
            if IsValid(top) then
                gui.HideGameUI()
                top:Close()
                break
            end
            table.remove(UI.Stack, i)
        end
    end
    escDown = down
end)

-- Modaler Dialog
function UI.Dialog(title, sub, w, h)
    local f = UI.Frame(title, sub or "", w, h)
    f:DockPadding(18, 78, 18, 18)
    f:DoModal()
    return f
end

function UI.Confirm(title, text, yesLabel, onYes, accent)
    local d = UI.Dialog(title, "BESTÄTIGUNG", 460, 230)
    local l = UI.Label(d, text, "GARLog_Text", C.text)
    local row = vgui.Create("DPanel", d)
    row:Dock(BOTTOM)
    row:SetTall(42)
    row.Paint = nil
    local no = UI.Button(row, "ABBRECHEN", function() d:Close() end)
    no:Dock(LEFT)
    no:SetWide(150)
    local yes = UI.Button(row, yesLabel or "BESTÄTIGEN", function()
        d:Close()
        onYes()
    end)
    yes.Solid = true
    yes.Accent = accent or C.yellow
    yes:Dock(RIGHT)
    yes:SetWide(200)
    return d
end

function UI.Prompt(title, text, placeholder, default, onOk, maxLen, numeric)
    local d = UI.Dialog(title, "EINGABE", 460, 250)
    UI.Label(d, text, "GARLog_Small", C.soft)
    UI.Spacer(d, 8)
    local e = UI.Entry(d, placeholder)
    e:Dock(TOP)
    e:SetTall(36)
    e:SetText(default or "")
    if numeric then e:SetNumeric(true) end
    if maxLen then
        e.AllowInput = function(s) return (utf8.len(s:GetText()) or 0) >= maxLen end
    end
    local row = vgui.Create("DPanel", d)
    row:Dock(BOTTOM)
    row:SetTall(42)
    row.Paint = nil
    local no = UI.Button(row, "ABBRECHEN", function() d:Close() end)
    no:Dock(LEFT)
    no:SetWide(150)
    local function submit()
        local v = string.Trim(e:GetText())
        if v == "" then UI.ErrorSound() return end
        d:Close()
        onOk(v)
    end
    local ok = UI.Button(row, "OK", submit)
    ok.Solid = true
    ok:Dock(RIGHT)
    ok:SetWide(200)
    e.OnEnter = submit
    timer.Simple(0, function() if IsValid(e) then e:RequestFocus() end end)
    return d
end
