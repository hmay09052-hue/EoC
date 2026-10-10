local AID = KrakenSquad.AID
local P   = KrakenSquad.P
local SOUNDS = KrakenSquad.SOUNDS

local function F(n)  return KF.Fonts.Get(AID, n) end
local function FB(n) return KF.Fonts.GetBold(AID, n) end

KrakenSquad.UI = KrakenSquad.UI or {}

function KrakenSquad.MakeScroll(parent)
    local s = vgui.Create("KF.ScrollPanel", parent)
    s:Dock(FILL)
    s:DockMargin(KF.Scale(12), KF.Scale(8), KF.Scale(12), KF.Scale(4))
    s:SetAddon(AID)
    return s
end

function KrakenSquad.FormHeader(parent, title, desc, width)
    local opts = { addonId = AID }
    if width and width > 0 then opts.width = width end
    local h = KF.FormBuilder.SectionHeader(parent, title, desc, opts)
    h:Dock(TOP)
    h:DockMargin(0, KF.Scale(10), 0, KF.Scale(6))
    return h
end

function KrakenSquad.FormSpacer(parent, height)
    local s = KF.FormBuilder.Spacer(parent, height or 8)
    s:Dock(TOP)
    return s
end

function KrakenSquad.FormDesc(parent, text)
    if not text or text == "" then return end
    local lbl = vgui.Create("DLabel", parent)
    lbl:Dock(TOP)
    lbl:DockMargin(KF.Scale(2), 0, 0, KF.Scale(2))
    lbl:SetFont(F("small"))
    lbl:SetText(text)
    lbl:SetTextColor(P("TextMuted"))
    lbl:SetWrap(true)
    lbl:SetAutoStretchVertical(true)
    return lbl
end

function KrakenSquad.FormField(parent, label, value, onChange, opts)
    opts = opts or {}
    opts.addonId = AID
    opts.value   = value
    if opts.desc then opts.placeholder = opts.desc; opts.desc = nil end
    local c, input = KF.FormBuilder.TextField(parent, label, opts)
    c:Dock(TOP)
    c:DockMargin(0, KF.Scale(2), 0, KF.Scale(6))
    if onChange then
        input.OnEnter     = function(s) onChange(s:GetValue()) end
        input.OnLoseFocus = function(s) onChange(s:GetValue()) end
    end
    return c, input
end

function KrakenSquad.FormToggle(parent, label, checked, onChange, desc, width)
    local opts = { addonId = AID }
    if width and width > 0 then opts.width = width end
    local c, cb = KF.FormBuilder.Checkbox(parent, label, checked, opts)
    c:Dock(TOP)
    c:DockMargin(0, KF.Scale(4), 0, KF.Scale(4))
    DButton.SetText(cb, "")
    if onChange then
        cb.OnChange = function(_, v)
            KF.Helpers.PlaySound(SOUNDS.click)
            onChange(v)
        end
    end
    if desc and desc ~= "" then
        local origPaint = cb.Paint
        cb.Paint = function(s, w, h)
            origPaint(s, w, h)
            local boxSize = math.Clamp(h - 8, 16, s._size or 20)
            local labelX  = 4 + boxSize + KF.Scale(10)
            surface.SetFont(F("body"))
            local labelW = surface.GetTextSize(s._label or "")
            draw.SimpleText("- " .. desc, F("small"), labelX + labelW + KF.Scale(8),
                math.floor(h / 2), P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    return c, cb
end

function KrakenSquad.FormNumber(parent, label, value, onChange, opts)
    opts = opts or {}
    opts.numeric = true
    return KrakenSquad.FormField(parent, label, tostring(value or 0), function(v)
        local n = tonumber(v)
        if n then onChange(n) end
    end, opts)
end

function KrakenSquad.FormDropdown(parent, label, value, choices, onChange, desc, width)
    local opts = {
        addonId = AID, value = value, choices = choices,
        dropdownClass = "KF.PopupDropdown",
    }
    if width and width > 0 then opts.width = width end
    local c, input = KF.FormBuilder.Dropdown(parent, label, opts)
    c:Dock(TOP); c:DockMargin(0, KF.Scale(2), 0, KF.Scale(6))
    if input.SetSound      then input:SetSound(SOUNDS.click) end
    if input.SetHoverSound then input:SetHoverSound(SOUNDS.hover) end
    input.OnSelect = function(_, _, text, val) onChange(val or text) end
    if desc and desc ~= "" and input.SetPlaceholder then input:SetPlaceholder(desc) end
    return c, input
end

function KrakenSquad.MakeKFButton(parent, label, style, onClick, tall, margin)
    local btn = vgui.Create("KF.Button", parent)
    btn:Dock(TOP)
    btn:SetTall(KF.Scale(tall or 32))
    btn:DockMargin(0, KF.Scale(margin and margin[1] or 10), 0, KF.Scale(margin and margin[2] or 6))
    btn:SetAddon(AID)
    btn:SetLabel(label)
    if style == "solid" then btn:SetSolid(true)
    elseif style        then btn:SetStyle(style) end
    btn.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        onClick()
    end
    return btn
end

function KrakenSquad.MakeCloseButton(parent, x, y)
    local btn = KF.Menu.CloseButton(parent, x, y, FB("subheader"),
        function() parent:Remove() end, KrakenSquad.GetMenuColors())
    btn:SetSize(KF.Scale(26), KF.Scale(26))
    return btn
end

function KrakenSquad.MakeEmptyLabel(parent, text)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(KF.Scale(40))
    p:DockMargin(0, KF.Scale(4), 0, 0)
    p.Paint = function(_, _, h)
        draw.SimpleText(text or KrakenSquad.L("admin_no_items"), F("small"),
            KF.Scale(8), h / 2, P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    return p
end

function KrakenSquad.MakeSidebarButton(parent, label, isActive, onClick)
    local transparent = KF.UI.ColorAlpha(color_black, 0)
    local btn = vgui.Create("DButton", parent)
    btn:Dock(TOP)
    btn:SetTall(KF.Scale(26))
    btn:DockMargin(KF.Scale(4), KF.Scale(1), KF.Scale(4), 0)
    btn:SetText("")
    btn._hoverLerp = 0
    btn.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        local active = isActive()
        local bg = active and KF.UI.ColorAlpha(P("Accent"), 60)
                  or KF.UI.LerpColor(s._hoverLerp, transparent, P("PanelHover"))
        KF.Draw.RoundedBox(0, 0, w, h, 4, bg)
        if active then
            surface.SetDrawColor(P("Accent"))
            surface.DrawRect(0, 0, 3, h)
        end
        draw.SimpleText(label, F("body"), KF.Scale(12), h / 2,
            active and P("Accent") or P("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    btn.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        onClick()
    end
    return btn
end

function KrakenSquad.MakeSidebarGroupLabel(parent, labelKey)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(KF.Scale(18))
    p:DockMargin(KF.Scale(10), KF.Scale(5), KF.Scale(4), 0)
    p.Paint = function(_, _, h)
        draw.SimpleText(KrakenSquad.L(labelKey):upper(), F("tiny"),
            0, h / 2, P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    return p
end

local _menuColors

function KrakenSquad.GetMenuColors()
    if _menuColors then return _menuColors end
    _menuColors = {
        BG = P("BG"), Panel = P("Panel"), Header = P("Header"),
        Row = P("Row"), RowHover = P("RowHover"), RowAlt = P("RowAlt"),
        Accent = P("Accent"), AccentDim = P("AccentDim"), AccentHover = P("AccentHover"),
        Text = P("Text"), TextBright = P("TextBright"), TextMuted = P("TextMuted"),
        Success = P("Success"), SuccessHover = P("SuccessHover"),
        Error = P("Error"), ErrorHover = P("ErrorHover"),
        Border = P("Border"), InputBG = P("InputBG"),
        ScrollTrack = P("ScrollTrack"), ToggleTrack = P("ToggleTrack"),
        Disabled = P("Disabled"), DisabledText = P("DisabledText"),
    }
    return _menuColors
end

hook.Add("KrakenSquad.ConfigUpdated", "KS.FlushMenuColors", function() _menuColors = nil end)

local PRIO_CYCLE = { main = "secondary", secondary = "main" }

function KrakenSquad.BuildObjectiveRow(parent, obj, idx, pending, onRebuild)
    local rowH = KF.Scale(38)
    local op = vgui.Create("DPanel", parent)
    op:Dock(TOP); op:SetTall(rowH); op:DockMargin(0, KF.Scale(2), 0, 0)
    op.Paint = function(_, w, h)
        local isMain = (obj.priority or "main") == "main"
        local accent = P("Accent")
        KF.Draw.RoundedBox(0, 0, w, h, 0, P("PanelDark"))
        if isMain then
            surface.SetDrawColor(accent.r, accent.g, accent.b, 15)
            surface.DrawRect(0, 0, w, h)
        end
        surface.SetDrawColor(isMain and accent or P("TextMuted"))
        surface.DrawRect(0, 0, 3, h)
    end

    local prioBadge = vgui.Create("DButton", op)
    prioBadge:Dock(LEFT); prioBadge:SetWide(KF.Scale(26))
    prioBadge:DockMargin(KF.Scale(6), KF.Scale(6), 0, KF.Scale(6))
    prioBadge:SetText(""); prioBadge:SetCursor("hand"); prioBadge._hoverLerp = 0
    prioBadge.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        local isMain = (obj.priority or "main") == "main"
        local col = isMain and P("Accent") or P("TextMuted")
        KF.Draw.RoundedBox(0, 0, w, h, 3, KF.UI.ColorAlpha(col, math.floor(Lerp(s._hoverLerp, 40, 80))))
        draw.SimpleText(idx, FB("button"), w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    prioBadge.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        obj.priority = PRIO_CYCLE[obj.priority or "main"]
    end

    local del = vgui.Create("DButton", op)
    del:Dock(RIGHT); del:SetWide(KF.Scale(28))
    del:DockMargin(0, 0, KF.Scale(4), 0); del:SetText(""); del._hoverLerp = 0
    del.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        draw.SimpleText("\xe2\x9c\x95", F("tiny"), w / 2, h / 2,
            KF.UI.LerpColor(s._hoverLerp, P("TextMuted"), P("Error")),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    del.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        table.remove(pending.objectives, idx)
        onRebuild()
    end

    local prioLabel = vgui.Create("DPanel", op)
    prioLabel:Dock(RIGHT); prioLabel:SetWide(KF.Scale(90))
    prioLabel.Paint = function(_, w, h)
        local isMain = (obj.priority or "main") == "main"
        local key = isMain and "order_prio_main" or "order_prio_secondary"
        draw.SimpleText(KrakenSquad.L(key), F("tiny"), w / 2, h / 2,
            isMain and P("Accent") or P("TextMuted"),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local entry = vgui.Create("DTextEntry", op)
    entry:Dock(FILL); entry:DockMargin(KF.Scale(8), KF.Scale(7), KF.Scale(4), KF.Scale(7))
    entry:SetFont(F("small")); entry:SetTextColor(P("TextPrimary"))
    entry:SetText(obj.text or ""); entry:SetDrawBackground(false)
    entry.Paint = function(s, w, h) KF.Helpers.TextEntryPaint(s, w, h, F("small"), AID) end
    entry.OnLoseFocus = function(s) pending.objectives[idx].text = s:GetValue() end

    return op, rowH
end

function KrakenSquad.MakeAccessCheckbox(parent, w, h, label, checked)
    local cb = vgui.Create("KF.Checkbox", parent)
    cb:SetSize(w, h)
    cb:SetAddon(AID); cb:SetLabel(label); cb:SetChecked(checked or false)
    DButton.SetText(cb, "")
    cb._checked = checked or false
    cb.OnChange = function(s, v)
        KF.Helpers.PlaySound(SOUNDS.click)
        s._checked = v
    end
    return cb
end

function KrakenSquad.MakeCollapsibleSection(parent, sectionKey, label, items, selected, store)
    if #items == 0 then return end
    store[sectionKey] = {}
    local displayLabel = label:sub(1, 1):upper() .. label:sub(2)

    local header = vgui.Create("DButton", parent)
    header:Dock(TOP); header:SetTall(KF.Scale(32))
    header:DockMargin(0, KF.Scale(4), 0, KF.Scale(2)); header:SetText("")
    header._expanded = false; header._hoverLerp = 0
    header.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        KF.Draw.RoundedBox(0, 0, w, h, 4, KF.UI.LerpColor(s._hoverLerp, P("PanelDark"), P("PanelHover")))
        local ax, ay = KF.Scale(14), h / 2
        surface.SetDrawColor(KF.UI.LerpColor(s._hoverLerp, P("TextMuted"), P("Accent")))
        draw.NoTexture()
        if s._expanded then
            surface.DrawPoly({ { x = ax - 4, y = ay - 2 }, { x = ax + 4, y = ay - 2 }, { x = ax, y = ay + 4 } })
        else
            surface.DrawPoly({ { x = ax - 2, y = ay - 4 }, { x = ax + 3, y = ay }, { x = ax - 2, y = ay + 4 } })
        end
        draw.SimpleText(displayLabel .. " (" .. #items .. ")", FB("small"),
            KF.Scale(28), h / 2, P("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    header.OnCursorEntered = function() KF.Helpers.PlaySound(SOUNDS.hover) end

    local rowH     = KF.Scale(28)
    local rows     = math.ceil(#items / 2)
    local contentH = rows * rowH + KF.Scale(12)

    local grid = vgui.Create("DPanel", parent)
    grid:Dock(TOP); grid:SetTall(0)
    grid:DockMargin(KF.Scale(8), 0, 0, KF.Scale(4)); grid:SetVisible(false)
    grid.Paint = function(_, w, h)
        KF.Draw.RoundedBox(0, 0, w, h, 4, KF.UI.ColorAlpha(P("Panel"), 60))
    end
    grid.PerformLayout = function(_, w)
        local colW = math.floor((w - KF.Scale(16)) / 2)
        for i, item in ipairs(items) do
            local id = item.id or item.name or tostring(item)
            local cb = store[sectionKey][id]
            if IsValid(cb) then
                cb:SetPos(((i - 1) % 2) * colW + KF.Scale(8), math.floor((i - 1) / 2) * rowH + KF.Scale(6))
                cb:SetSize(colW, rowH - 2)
            end
        end
    end
    for _, item in ipairs(items) do
        local id   = item.id or item.name or tostring(item)
        local name = item.name or item.id or tostring(item)
        local checked = false
        if istable(selected) then
            for _, sel in ipairs(selected) do
                if tostring(sel) == tostring(id) then checked = true break end
            end
        end
        store[sectionKey][id] = KrakenSquad.MakeAccessCheckbox(grid, KF.Scale(100), rowH - 2, name, checked)
    end
    header.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        header._expanded = not header._expanded
        grid:SetVisible(header._expanded)
        grid:SetTall(header._expanded and contentH or 0)
        grid:InvalidateParent(true)
        parent:InvalidateLayout(true)
    end
end

function KrakenSquad.CollectFilters(filterStore)
    local filters = {}
    for ftype, items in pairs(filterStore) do
        for itemId, cb in pairs(items) do
            if IsValid(cb) and cb._checked then
                filters[#filters + 1] = { type = ftype, value = tonumber(itemId) or itemId }
            end
        end
    end
    return filters
end

function KrakenSquad.UI.OpenColorDialog(title, currentColor, onApply)
    local S = KF.Scale
    local w, h = S(260), S(270)

    local picker = vgui.Create("KF.Frame")
    picker:SetSize(w, h); picker:MakePopup(); picker:Center()
    picker:SetAddon(AID); picker:SetFrameTitle(title:upper())
    picker:SetHeaderHeight(42)
    picker._color = KF.UI.ColorAlpha(currentColor, 255)
    KrakenSquad.MakeCloseButton(picker, w - S(42), S(8))

    local headerH = S(42)
    local preview = vgui.Create("DPanel", picker)
    preview:SetPos(S(14), headerH + S(4))
    preview:SetSize(w - S(28), S(28))
    preview.Paint = function(_, pw, ph)
        KF.Draw.RoundedBox(0, 0, pw, ph, 2, picker._color)
        surface.SetDrawColor(P("Border"))
        surface.DrawOutlinedRect(0, 0, pw, ph, 1)
    end

    local function MakeSlider(yPos, channel, val)
        local lbl = vgui.Create("DLabel", picker)
        lbl:SetPos(S(14), yPos); lbl:SetSize(S(16), S(22))
        lbl:SetFont("KS.tiny.light"); lbl:SetText(channel); lbl:SetTextColor(P("Text"))
        local s = vgui.Create("DNumSlider", picker)
        s:SetPos(S(30), yPos); s:SetSize(w - S(44), S(22))
        s:SetMin(0); s:SetMax(255); s:SetDecimals(0)
        s:SetValue(val); s:SetText("")
        s.Label:SetWide(0); s.TextArea:SetWide(S(36))
        s.TextArea:SetFont("KS.tiny.light"); s.TextArea:SetTextColor(P("Text"))
        if s.Scratch then s.Scratch:SetVisible(false); s.Scratch:SetWide(0) end
        if s.Slider then
            s.Slider.Paint = function(_, sw, sh) KF.Draw.RoundedBox(0, sh / 2 - 2, sw, 4, 2, P("ToggleTrack")) end
            if s.Slider.Knob then
                s.Slider.Knob.Paint = function(_, kw, kh) KF.Draw.RoundedBox(0, 0, kw, kh, 4, P("Accent")) end
            end
        end
        return s
    end

    local r = MakeSlider(headerH + S(40),  "R", picker._color.r)
    local g = MakeSlider(headerH + S(70),  "G", picker._color.g)
    local b = MakeSlider(headerH + S(100), "B", picker._color.b)

    local function Apply()
        picker._color = Color(
            math.Clamp(math.floor(r:GetValue()), 0, 255),
            math.Clamp(math.floor(g:GetValue()), 0, 255),
            math.Clamp(math.floor(b:GetValue()), 0, 255), 255)
    end
    r.OnValueChanged, g.OnValueChanged, b.OnValueChanged = Apply, Apply, Apply

    local hex = vgui.Create("DTextEntry", picker)
    hex:SetPos(S(14), headerH + S(134)); hex:SetSize(w - S(28), S(26))
    hex:SetFont("KS.tiny.light"); hex:SetTextColor(P("Text"))
    hex:SetText(("#%02X%02X%02X"):format(picker._color.r, picker._color.g, picker._color.b))
    hex:SetDrawBackground(false)
    hex.Paint = function(s, hw, hh) KF.Helpers.TextEntryPaint(s, hw, hh, "KS.tiny.light", AID) end
    hex.OnEnter = function(s)
        local txt = s:GetValue():Trim():gsub("^#", "")
        if #txt == 6 then
            r:SetValue(tonumber(txt:sub(1, 2), 16) or 255)
            g:SetValue(tonumber(txt:sub(3, 4), 16) or 255)
            b:SetValue(tonumber(txt:sub(5, 6), 16) or 255)
            Apply()
        end
    end

    local apply = vgui.Create("KF.Button", picker)
    apply:SetPos(S(14), h - S(44))
    apply:SetSize(w - S(28), S(32))
    apply:SetAddon(AID); apply:SetLabel(KrakenSquad.L("admin_save"))
    apply:SetStyle("success"); apply:SetSolid(true)
    apply.DoClick = function()
        Apply()
        onApply(picker._color)
        picker:Remove()
    end
end

function KrakenSquad.UI.MakeListCard(parent, opts)
    local card = vgui.Create("DPanel", parent)
    card:Dock(TOP)
    card:SetTall(KF.Scale(opts.tall or 56))
    card:DockMargin(0, KF.Scale(opts.gap or 3), 0, KF.Scale(opts.gap or 3))
    card._hoverLerp = 0
    card.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.LerpColor(s._hoverLerp, P("PanelDark"), P("PanelHover")))
        surface.SetDrawColor(opts.statusColor and opts.statusColor() or P("Accent"))
        surface.DrawRect(0, 0, 3, h)
        if opts.paint then opts.paint(s, w, h) end
    end
    if opts.cursor then
        card:SetMouseInputEnabled(true)
        card:SetCursor(opts.cursor)
    end
    return card
end
