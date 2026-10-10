local AID = BattleGrid.AID
if SYMUI then SYMUI.HookKraken() end -- SymChars-Design (Farben/Schriften/Formen)

KF.RegisterAddon(AID, "Battle Grid", {
    version = BattleGrid.Version,
    prefix = "BG",
})

KF.Fonts.Register(AID, {
    prefix = "BG",
    primary = "Roboto Condensed",
    secondary = "Roboto",
    accent = "Aurebesh",
    sizes = {
        title = 48, header = 32, subheader = 24, body = 18,
        button = 20, small = 14, tiny = 12, stat = 16,
        nav = 17, section = 22, caption = 16, description = 14,
        sliderval = 16, toolbar = 24,
    },
    extras = {
        { name = "Respawn.Title", size = 28, weight = 700 },
        { name = "Respawn.Name", size = 16, weight = 700 },
        { name = "Respawn.Role", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 11, weight = 400 },
        { name = "Respawn.Status", size = 10, weight = 700 },
        { name = "Respawn.Btn", size = 14, weight = 700 },
        { name = "Respawn.Hint", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 13, weight = 400 },
        { name = "CPAnnounce.Tag", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 14, weight = 700 },
        { name = "CPAnnounce.Sub", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 16, weight = 400 },
        { name = "CPAnnounce.Bold", font = SYMUI and SYMUI.FontFace("head") or "Roboto", size = 41, weight = 700 },
        { name = "CPAnnounce.Bold.Blur", font = SYMUI and SYMUI.FontFace("head") or "Roboto", size = 41, weight = 700, blursize = 8 },
        { name = "BF.CPLetter", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 16, weight = 700 },
        { name = "BF.CPLetterLarge", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 22, weight = 700 },
        { name = "BF.TicketScore", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 26, weight = 700 },
        { name = "BF.TicketLabel", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 11, weight = 700 },
        { name = "BF.CompassDeg", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 12, weight = 500 },
        { name = "BF.CompassCard", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 14, weight = 700 },
        { name = "BF.Overlay", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 13, weight = 400 },
        { name = "BF.OverlayBold", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 13, weight = 700 },
        { name = "BF.MapName", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 15, weight = 600 },
        { name = "BF.ZoomPct", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 12, weight = 400 },
        { name = "Context", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 18, weight = 500, shadow = true },
        { name = "World.Name", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 20, weight = 600, shadow = true },
        { name = "World.Distance", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 15, weight = 400, shadow = true },
        { name = "MapLabel", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 14, weight = 100, shadow = true },
        { name = "MapLabelSmall", font = SYMUI and SYMUI.FontFace("body") or "Roboto", size = 11, weight = 100, shadow = true },
        { name = "Header", font = SYMUI and SYMUI.FontFace("head") or "Roboto", size = 32, weight = 700, shadow = true },
    },
})

local palette = KF.UI.DefaultDarkPalette()

palette.MapOverlay    = Color(10, 14, 20, 120)
palette.GridDots      = Color(255, 255, 255, 18)
palette.PlayerIcon    = Color(58, 147, 255)
palette.SquadIcon     = Color(90, 220, 120)
palette.AreaDefine    = Color(80, 240, 255)
palette.BluforColor   = Color(58, 147, 255)
palette.OpforColor    = Color(255, 72, 61)
palette.NeutralCP     = Color(140, 140, 140)
palette.ContestedCP   = Color(255, 180, 50)
palette.HUDBg         = Color(0, 0, 0, 160)
palette.HUDBorder     = Color(255, 255, 255, 25)
palette.TicketBar     = Color(0, 0, 0, 180)
palette.MapSeparator  = Color(255, 215, 0, 180)
palette.BarTrack      = Color(30, 30, 30, 200)
palette.BarTrackLight = Color(40, 40, 40, 180)
palette.VoidFloor     = Color(10, 12, 15, 255)
palette.CPDiamond     = Color(80, 85, 95)
palette.NPCSpawn      = Color(0, 168, 255)
palette.RadialHover   = Color(30, 35, 48)
palette.RadialBg      = Color(14, 16, 22)

KF.UI.SetTheme(AID, palette)

BattleGrid.Theme = {}
local theme = BattleGrid.Theme

theme.PresetColors = {
    Color(255, 255, 255),
    Color(255, 80, 80),
    Color(80, 255, 120),
    Color(255, 200, 50),
    Color(200, 80, 255),
    Color(255, 140, 50),
    Color(80, 180, 255),
    Color(0, 225, 255),
}

theme.CableColors = {
    Color(230, 85, 85),
    Color(80, 200, 120),
    Color(80, 160, 255),
    Color(255, 190, 50),
    Color(200, 80, 255),
    Color(0, 225, 255),
}

theme.Size = {
    HEADER_H       = 80,
    NAV_H          = 56,
    ROW_H          = 44,
    INPUT_H        = 40,
    BUTTON_H       = 40,
    BUTTON_H_SMALL = 32,
    SCROLLBAR_W    = 6,
    CLOSE_BTN      = 44,
    SIDEBAR_W      = 260,
    BORDER_THIN    = 1,
    BORDER_NORMAL  = 2,
    TOOLBAR_W      = 52,
    TOOLBAR_BTN    = 40,
}

KF.Fonts.Create(AID)
KF.UI.ApplyAccentColor(AID, Color(255, 190, 50))
hook.Add("OnScreenSizeChanged", "BattleGrid.RebuildFonts", function() KF.Fonts.Create(AID) end)

function BattleGrid.F(name) return KF.Fonts.Get(AID, name) end
function BattleGrid.FB(name) return KF.Fonts.GetBold(AID, name) end

function BattleGrid.C(key) return KF.UI.GetColor(key, AID) end

function BattleGrid:Toast(text, toastType, duration)
    KF.Notifications.Show(text, toastType or "info", duration or 4, AID)
end

local S = KF.Scale
local T = BattleGrid.Theme

local circleCache = {}
local circleCacheCount = 0
local CIRCLE_CACHE_MAX = 256

local function GetCirclePoly(x, y, radius, segments)
    segments = segments or 32
    local rx, ry, rr = math.Round(x), math.Round(y), math.Round(radius)
    local key = rx + ry * 100003 + rr * 10000019 + segments * 1000000007

    if circleCache[key] then return circleCache[key] end

    if circleCacheCount >= CIRCLE_CACHE_MAX then
        circleCache = {}
        circleCacheCount = 0
    end

    local cir = {}
    cir[1] = {x = x, y = y, u = 0.5, v = 0.5}

    for i = 0, segments do
        local a = math.rad((i / segments) * -360)
        cir[#cir + 1] = {
            x = x + math.sin(a) * radius,
            y = y + math.cos(a) * radius,
            u = math.sin(a) / 2 + 0.5,
            v = math.cos(a) / 2 + 0.5,
        }
    end

    local a = math.rad(0)
    cir[#cir + 1] = {
        x = x + math.sin(a) * radius,
        y = y + math.cos(a) * radius,
        u = math.sin(a) / 2 + 0.5,
        v = math.cos(a) / 2 + 0.5,
    }

    circleCache[key] = cir
    circleCacheCount = circleCacheCount + 1
    return cir
end

function BattleGrid:DrawCircle(x, y, radius, segments)
    surface.DrawPoly(GetCirclePoly(x, y, radius, segments))
end

function BattleGrid:DrawCircleFromPoints(cx, cy, px, py, segments)
    local radius = math.sqrt((px - cx)^2 + (py - cy)^2)
    self:DrawCircle(cx, cy, radius, segments or 32)
end

function BattleGrid:DrawOutlinedCircleFromPoints(cx, cy, px, py, segments, thickness)
    segments = segments or 32
    thickness = thickness or 2
    local radius = math.sqrt((px - cx)^2 + (py - cy)^2)

    for t = 0, thickness - 1 do
        local r = radius - t
        for i = 0, segments do
            local a1 = math.rad((i / segments) * -360)
            local a2 = math.rad(((i + 1) / segments) * -360)
            surface.DrawLine(
                cx + math.sin(a1) * r,
                cy + math.cos(a1) * r,
                cx + math.sin(a2) * r,
                cy + math.cos(a2) * r
            )
        end
    end
end

function BattleGrid:DrawRectFromPoints(x1, y1, x2, y2)
    local sx = math.min(x1, x2)
    local sy = math.min(y1, y2)
    surface.DrawRect(sx, sy, math.abs(x2 - x1), math.abs(y2 - y1))
end

function BattleGrid:DrawOutlinedRectFromPoints(x1, y1, x2, y2, thickness)
    local sx = math.min(x1, x2)
    local sy = math.min(y1, y2)
    surface.DrawOutlinedRect(sx, sy, math.abs(x2 - x1), math.abs(y2 - y1), thickness or 1)
end

function BattleGrid:DrawIcon(path, x, y, w, h, col)
    local mat = KF.Materials.Get(path)
    if not mat then return end
    surface.SetDrawColor(col or color_white)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x, y, w, h)
end

function BattleGrid:TruncateToWidth(text, maxWidth, font)
    if maxWidth <= 0 then return text end
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxWidth then return text end
    while #text > 1 and surface.GetTextSize(text) > maxWidth do
        text = string.sub(text, 1, #text - 1)
    end
    return text .. "..."
end

function BattleGrid:DrawHex(cx, cy, size, fillCol, borderCol)
    local verts = {}
    for i = 0, 5 do
        local angle = math.rad(60 * i - 90)
        verts[i + 1] = { x = cx + math.cos(angle) * size, y = cy + math.sin(angle) * size }
    end
    draw.NoTexture()
    surface.SetDrawColor(fillCol)
    surface.DrawPoly(verts)
    if borderCol then
        surface.SetDrawColor(borderCol)
        for i = 1, 6 do
            local j = (i % 6) + 1
            surface.DrawLine(verts[i].x, verts[i].y, verts[j].x, verts[j].y)
        end
    end
    return verts
end

do
    local hidden = {}

    function BattleGrid:SetEntitiesNoDraw(state)
        if state then
            for _, ent in ipairs(ents.GetAll()) do
                if ent:IsWorld() or ent:GetNoDraw() then continue end
                local mdl = ent:GetModel()
                if mdl and mdl:sub(1, 1) == "*" then continue end
                ent:SetNoDraw(true)
                hidden[#hidden + 1] = ent
            end
            return
        end
        for i = #hidden, 1, -1 do
            local ent = hidden[i]
            if IsValid(ent) then ent:SetNoDraw(false) end
            hidden[i] = nil
        end
    end
end

BattleGrid._formWidth = 0

function BattleGrid:PlaySound(key)
    if not self:GetPref("enable_sounds") then return end
    local snd = self.Sounds and self.Sounds[key]
    if snd and snd ~= "" then KF.Helpers.PlaySound(snd) end
end

function BattleGrid:NormalizeVector(value, fallback)
    if isvector(value) then return value end
    local src = istable(value) and value or {}
    local base = isvector(fallback) and fallback or vector_origin
    return Vector(src.x or src[1] or base.x, src.y or src[2] or base.y, src.z or src[3] or base.z)
end

function BattleGrid:NormalizeColor(value, fallback)
    if IsColor(value) then return value end
    local src = istable(value) and value or {}
    local base = IsColor(fallback) and fallback or color_white
    return BattleGrid.ColorCopy({ r = src.r or src[1] or base.r, g = src.g or src[2] or base.g, b = src.b or src[3] or base.b, a = src.a or src[4] or base.a })
end

function BattleGrid:CreateHeaderPanel(parent, opts)
    local cfg = opts or {}
    local header = vgui.Create("DPanel", parent)
    header:Dock(TOP)
    header:SetTall(cfg.height or S(56))

    header.Paint = function(_, w, h)
        if cfg.drawBackground ~= false then
            surface.SetDrawColor(cfg.backgroundColor or BattleGrid.C("PanelDark"))
            surface.DrawRect(0, 0, w, h)
        end
        surface.SetDrawColor(cfg.borderColor or BattleGrid.C("Accent"))
        surface.DrawRect(0, h - 1, w, 1)
        local margin = S(cfg.margin or 12)
        local titleY = cfg.subtitle and (h / 2 - S(10)) or (h / 2)
        draw.SimpleText(cfg.title or "", cfg.titleFont or BattleGrid.F("header"), margin, titleY, cfg.titleColor or BattleGrid.C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if cfg.subtitle then
            draw.SimpleText(cfg.subtitle, cfg.subtitleFont or BattleGrid.F("small"), margin, h / 2 + S(14), cfg.subtitleColor or BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    return header
end

function BattleGrid:CreateToggle(parent, label, default, onChange)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(S(32))
    row:DockMargin(0, S(2), 0, S(2))
    row.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        local bg = KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("PanelDark"), BattleGrid.C("PanelHover"))
        draw.RoundedBox(2, 0, 0, w, h, bg)
    end
    local cb = vgui.Create("KF.Checkbox", row)
    cb:Dock(FILL)
    cb:DockMargin(0, 0, 0, 0)
    cb:SetAddon(AID)
    cb:SetLabel(label)
    cb:SetChecked(tobool(default))
    DButton.SetText(cb, "")
    if onChange then
        cb.OnChange = function(_, val)
            BattleGrid:PlaySound("Click")
            onChange(val)
        end
    end
    row.GetValue = function() return cb:GetChecked() end
    row.SetValue = function(_, v) cb:SetChecked(tobool(v)) end
    return row
end

function BattleGrid:CreateTextInput(parent, label, default, onChange, maxLength)
    local opts = { addonId = AID, value = tostring(default or ""), placeholder = label }
    if BattleGrid._formWidth > 0 then opts.width = BattleGrid._formWidth end
    local c, input = KF.FormBuilder.TextField(parent, label, opts)
    if maxLength then input:SetMaximumCharCount(maxLength) end
    c:Dock(TOP)
    c:DockMargin(0, S(2), 0, S(4))
    c.PerformLayout = function(s, w) for _, ch in ipairs(s:GetChildren()) do ch:SetWide(w) end end
    if onChange then
        input.OnChange = function(s) onChange(s.GetValue and s:GetValue() or s:GetText()) end
    end
    c.Entry = input
    c.GetValue = function() return input.GetValue and input:GetValue() or input:GetText() end
    c.SetValue = function(_, v) if input.SetValue then input:SetValue(tostring(v)) else input:SetText(tostring(v)) end end
    return c
end

function BattleGrid:StyleSlider(slider, font)
    font = font or BattleGrid.F("small")
    slider:SetText("")
    slider.Label:SetVisible(false)
    slider.TextArea:SetFont(font)
    slider.TextArea:SetTextColor(BattleGrid.C("TextMuted"))
    slider.TextArea.Paint = function(s, w, h)
        s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
    end
    if slider.Slider then
        slider.Slider.Paint = function(_, w, h)
            draw.RoundedBox(2, 0, math.floor(h / 2) - 1, w, 2, BattleGrid.C("PanelLight"))
        end
        if slider.Slider.Knob then
            slider.Slider.Knob.Paint = function(_, w, h)
                draw.RoundedBox(w / 2, 0, 0, w, h, BattleGrid.C("Accent"))
            end
        end
    end
end

function BattleGrid:CreateSlider(parent, label, min, max, decimals, default, onChange)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(S(36))
    row:DockMargin(0, S(2), 0, S(2))
    row.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        local bg = KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("PanelDark"), BattleGrid.C("PanelHover"))
        draw.RoundedBox(2, 0, 0, w, h, bg)
    end
    local lbl = vgui.Create("DLabel", row)
    lbl:Dock(LEFT)
    lbl:DockMargin(S(4), 0, 0, 0)
    lbl:SetFont(BattleGrid.F("small"))
    lbl:SetText(label)
    lbl:SetTextColor(BattleGrid.C("TextPrimary"))
    lbl:SizeToContents()
    local slider = vgui.Create("DNumSlider", row)
    slider:Dock(FILL)
    slider:DockMargin(S(8), S(2), S(12), S(2))
    slider:SetMin(min or 0)
    slider:SetMax(max or 100)
    slider:SetDecimals(decimals or 0)
    slider:SetValue(default or min or 0)
    BattleGrid:StyleSlider(slider)
    if onChange then
        slider.OnValueChanged = function(_, val) onChange(val) end
    end
    row.Slider = slider
    row.GetValue = function() return slider:GetValue() end
    row.SetValue = function(_, v) slider:SetValue(v) end
    return row
end

function BattleGrid:CreateNumberInput(parent, label, default, onChange)
    local opts = { addonId = AID, value = tostring(default or ""), numeric = true }
    if BattleGrid._formWidth > 0 then opts.width = BattleGrid._formWidth end
    local c, input = KF.FormBuilder.TextField(parent, label, opts)
    c:Dock(TOP)
    c:DockMargin(0, S(2), 0, S(4))
    c.PerformLayout = function(s, w) for _, ch in ipairs(s:GetChildren()) do ch:SetWide(w) end end
    if onChange then
        input.OnChange = function(s)
            local val = tonumber(s.GetValue and s:GetValue() or s:GetText())
            if val then onChange(val) end
        end
    end
    c.Entry = input
    c.GetValue = function() return tonumber(input.GetValue and input:GetValue() or input:GetText()) end
    c.SetValue = function(_, v) if input.SetValue then input:SetValue(tostring(v)) else input:SetText(tostring(v)) end end
    return c
end

function BattleGrid:CreateButton(parent, text, style, onClick, opts)
    opts = opts or {}
    local styleMap = { primary = "primary", danger = "danger", success = "success", ghost = "secondary" }
    local btn = vgui.Create("KF.Button", parent)
    btn:SetTall(S(opts.tall or T.Size.BUTTON_H))
    btn:SetAddon(AID)
    btn:SetLabel(text)
    local mappedStyle = styleMap[style] or style or "default"
    btn:SetStyle(mappedStyle)
    btn:SetSolid(style == "primary" or style == "danger" or style == "success" or style == "solid")
    btn:SetSound(BattleGrid.Sounds.Click)
    if opts.dock then
        btn:Dock(opts.dock)
        local m = opts.margin
        if m then btn:DockMargin(S(m[1] or 0), S(m[2] or 0), S(m[3] or 0), S(m[4] or 0)) end
    end
    if onClick then btn.DoClick = function() onClick() end end
    return btn
end

function BattleGrid.FormHeader(parent, title, desc)
    local opts = { addonId = AID }
    if BattleGrid._formWidth > 0 then opts.width = BattleGrid._formWidth end
    local h = KF.FormBuilder.SectionHeader(parent, title, desc, opts)
    h:Dock(TOP)
    h:DockMargin(0, S(10), 0, S(6))
    return h
end

function BattleGrid.FormSpacer(parent, height)
    local s = KF.FormBuilder.Spacer(parent, height or 8)
    s:Dock(TOP)
    return s
end

function BattleGrid.MakeScroll(parent)
    local scroll = vgui.Create("KF.ScrollPanel", parent)
    scroll:Dock(FILL)
    scroll:DockMargin(S(16), S(6), S(16), S(12))
    scroll:SetAddon(AID)
    return scroll
end

function BattleGrid:CreateDropdown(parent, label, choices, default, onChange)
    local formChoices = {}
    for _, choice in ipairs(choices) do
        if istable(choice) then
            table.insert(formChoices, { name = tostring(choice[2] or choice[1]), value = tostring(choice[1]) })
        else
            table.insert(formChoices, { name = tostring(choice), value = tostring(choice) })
        end
    end

    local opts = { addonId = AID, choices = formChoices, dropdownClass = "KF.PopupDropdown" }
    if default then opts.value = tostring(default) end
    if BattleGrid._formWidth > 0 then opts.width = BattleGrid._formWidth end
    local c, dd = KF.FormBuilder.Dropdown(parent, label, opts)
    c:Dock(TOP)
    c:DockMargin(0, S(2), 0, S(4))
    c.PerformLayout = function(s, w) for _, ch in ipairs(s:GetChildren()) do ch:SetWide(w) end end
    if onChange then dd.OnSelect = function(_, idx, text, val)
        BattleGrid:PlaySound("Click")
        onChange(val or text)
    end end
    c.Dropdown = dd
    c.GetValue = function() return dd.GetSelectedValue and dd:GetSelectedValue() or (dd.GetValue and dd:GetValue()) or default end
    return c
end

function BattleGrid:CreateCloseButton(parent, onClick)
    local size = S(T.Size.CLOSE_BTN)
    local btn = KF.Menu.CloseButton(parent, 0, 0, BattleGrid.FB("subheader"), function()
        BattleGrid:PlaySound("Click")
        if onClick then onClick() end
    end, {
        TextMuted = BattleGrid.C("TextMuted"),
        Error = BattleGrid.C("Error"),
    })
    btn:SetSize(size, size)
    return btn
end

function BattleGrid:CreateEditorFrame(title, width, height)
    local frame = vgui.Create("KF.Frame")
    frame:SetAddon(AID)
    frame:SetSize(width, height)
    frame:MakePopup()
    frame:Center()
    frame:SetDraggable(true)
    frame:SetFrameTitle(title)
    frame:SetHeaderHeight(56)
    frame:DockPadding(0, S(60), 0, 0)

    local basePaint = frame.Paint
    frame.Paint = function(self, w, h)
        KF.Materials.DrawBlur(self, 3)
        basePaint(self, w, h)
    end

    local closeBtn = BattleGrid:CreateCloseButton(frame, function() frame:Remove() end)
    closeBtn:SetPos(width - S(52), S(8))

    return frame
end

function BattleGrid:CreatePositionInput(parent, pos)
    local posRow = vgui.Create("DPanel", parent)
    posRow:SetTall(S(T.Size.INPUT_H))
    posRow:Dock(TOP)
    posRow:DockMargin(0, 0, 0, S(6))
    posRow.Paint = function() end

    local inputs = {}
    local labels = {"X", "Y", "Z"}
    local values = {pos.x, pos.y, pos.z}
    local wraps = {}

    for i, lbl in ipairs(labels) do
        local wrap = vgui.Create("DPanel", posRow)
        wrap:Dock(LEFT)
        wrap:DockMargin(0, 0, i < 3 and S(6) or 0, 0)
        wrap.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelLight"))
            surface.SetDrawColor(BattleGrid.C("BorderSubtle"))
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(lbl, BattleGrid.F("small"), S(6), h / 2, BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local entry = vgui.Create("KF.TextInput", wrap)
        entry:SetAddon(AID)
        entry:Dock(FILL)
        entry:DockMargin(S(20), 0, S(4), 0)
        entry:SetNumeric(true)
        entry:SetValue(tostring(math.Round(values[i])))
        inputs[i] = entry
        wraps[i] = wrap
    end

    posRow.PerformLayout = function(_, w)
        local cellW = math.floor((w - S(6) * 2) / 3)
        for _, wr in ipairs(wraps) do wr:SetWide(cellW) end
    end

    posRow.GetVector = function()
        return Vector(tonumber(inputs[1]:GetValue()) or 0, tonumber(inputs[2]:GetValue()) or 0, tonumber(inputs[3]:GetValue()) or 0)
    end

    return posRow
end

function BattleGrid:CreateColorPresets(parent, presets, data)
    local colorRow = vgui.Create("DPanel", parent)
    colorRow:SetTall(S(28))
    colorRow:Dock(TOP)
    colorRow:DockMargin(0, 0, 0, S(6))
    colorRow.Paint = function() end

    local colorPreview = vgui.Create("DPanel", colorRow)
    colorPreview:Dock(LEFT)
    colorPreview:SetWide(S(28))
    colorPreview:DockMargin(0, 0, S(6), 0)
    colorPreview.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, data.color)
        surface.SetDrawColor(BattleGrid.C("Border"))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local mixer
    for _, preset in ipairs(presets) do
        local cbtn = vgui.Create("DButton", colorRow)
        cbtn:Dock(LEFT)
        cbtn:SetWide(S(28))
        cbtn:DockMargin(0, 0, S(2), 0)
        cbtn:SetText("")
        cbtn:SetCursor("hand")
        cbtn.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, preset)
            local isSel = data.color.r == preset.r and data.color.g == preset.g and data.color.b == preset.b
            if isSel then
                surface.SetDrawColor(BattleGrid.C("Accent"))
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            elseif cbtn:IsHovered() then
                surface.SetDrawColor(BattleGrid.C("TextPrimary"))
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
        end
        cbtn.DoClick = function()
            BattleGrid:PlaySound("Click")
            data.color = BattleGrid.ColorCopy(preset)
            if IsValid(mixer) then mixer:SetColor(data.color) end
        end
    end

    mixer = vgui.Create("DColorMixer", parent)
    mixer:Dock(TOP)
    mixer:SetTall(S(150))
    mixer:DockMargin(0, 0, 0, S(6))
    mixer:SetPalette(false)
    mixer:SetAlphaBar(false)
    mixer:SetWangs(true)
    mixer:SetColor(data.color)
    mixer.ValueChanged = function(_, col) data.color = BattleGrid.ColorCopy(col) end

    return colorRow
end

function BattleGrid:OpenContextMenu(items)
    local menu = DermaMenu()
    menu.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("Panel"))
        surface.SetDrawColor(BattleGrid.C("Border"))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    for _, item in ipairs(items) do
        local opt = menu:AddOption(item.text, item.callback)
        opt:SetFont(BattleGrid.F("Context"))
        opt:SetTextColor(item.color or BattleGrid.C("TextPrimary"))
        opt.Paint = function(_, w, h)
            if opt:IsHovered() then
                if not opt._soundPlayed then BattleGrid:PlaySound("Hover"); opt._soundPlayed = true end
                draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelHover"))
            else
                opt._soundPlayed = false
            end
        end
    end

    menu:Open()
    return menu
end

function BattleGrid:CreateEmptyState(parent, text)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetTall(S(80))
    pnl:Dock(TOP)
    pnl.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, KF.UI.ColorAlpha(BattleGrid.C("PanelLight"), 80))
        KF.Draw.EmptyState(w, h, text, nil, { addonId = AID, showIcon = false })
    end
    return pnl
end

function BattleGrid:CreateIconButton(parent, icon, hoverColor, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:Dock(RIGHT)
    btn:SetWide(S(32))
    btn:SetText("")
    btn:SetCursor("hand")

    btn.Paint = function(_, w, h)
        KF.Anim.UpdateHoverLerp(btn)
        KF.Helpers.HandleHoverSound(btn, BattleGrid.Sounds.Hover)
        local col = KF.UI.LerpColor(btn._hoverLerp, BattleGrid.C("TextMuted"), hoverColor)
        draw.SimpleText(icon, BattleGrid.F("body"), w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if onClick then
        btn.DoClick = function()
            BattleGrid:PlaySound("Click")
            onClick()
        end
    end

    return btn
end

function BattleGrid:CreateEditButton(parent, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:Dock(RIGHT)
    btn:SetWide(S(52))
    btn:DockMargin(0, S(8), S(4), S(8))
    btn:SetText("")
    btn:SetCursor("hand")

    btn.Paint = function(pnl, w, h)
        KF.Anim.UpdateHoverLerp(pnl)
        KF.Helpers.HandleHoverSound(pnl, BattleGrid.Sounds.Hover)
        local a = pnl._hoverLerp
        local bgCol = KF.UI.ColorAlpha(BattleGrid.C("Accent"), math.floor(20 + a * 40))
        local borderCol = KF.UI.ColorAlpha(BattleGrid.C("Accent"), math.floor(80 + a * 175))
        KF.Draw.NotchedBox(0, 0, w, h, S(4), bgCol, borderCol, 1, "right")
        local textCol = KF.UI.LerpColor(a, BattleGrid.C("TextSecondary"), BattleGrid.C("Accent"))
        draw.SimpleText(string.upper(BattleGrid:L("ADMIN_EDIT")), BattleGrid.F("tiny"), w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if onClick then
        btn.DoClick = function()
            BattleGrid:PlaySound("Click")
            onClick()
        end
    end

    return btn
end

function BattleGrid:CreateEditorActionPanel(parent, label, onClick)
    local panel = vgui.Create("DPanel", parent)
    panel:Dock(BOTTOM)
    panel:SetTall(S(56))
    panel:DockMargin(S(16), 0, S(16), S(12))
    panel.Paint = function() end
    local button = BattleGrid:CreateButton(panel, label, "success", onClick)
    button:Dock(FILL)
    return panel, button
end

function BattleGrid:OpenAdaptiveEditor(frameKey, title, sidebarWidth, frameWidth, frameHeight, editIdentifier)
    if IsValid(self[frameKey]) then self[frameKey]:Remove() end

    local container
    if IsValid(self.MapFrame) then
        container = vgui.Create("DPanel", self.MapFrame)
        container:Dock(RIGHT)
        container:SetWide(sidebarWidth)
        container.Paint = function(_, w, h)
            surface.SetDrawColor(BattleGrid.C("PanelDark"))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(BattleGrid.C("BorderSubtle"))
            surface.DrawRect(0, 0, 1, h)
        end
        BattleGrid:CreateHeaderPanel(container, {
            title = title, titleFont = BattleGrid.FB("nav"), titleColor = BattleGrid.C("TextPrimary"),
            height = S(44), margin = 16, borderColor = KF.UI.ColorAlpha(BattleGrid.C("Border"), 40), drawBackground = false,
        })
        local closeBtn = BattleGrid:CreateCloseButton(container, function()
            if IsValid(container) then container:Remove() end
            self[frameKey] = nil
        end)
        container.PerformLayout = function(_, w) closeBtn:SetPos(w - S(44), S(4)) end
    else
        container = self:CreateEditorFrame(title, frameWidth, frameHeight)
    end

    self[frameKey] = container
    container._editIdentifier = editIdentifier

    return container, function()
        if IsValid(container) then container:Remove() end
        self[frameKey] = nil
    end
end

function BattleGrid:CreateKeybindCapture(parent, currentKey, fallbackName, onCapture, label)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(S(36))
    row:DockMargin(0, S(2), 0, 0)
    row.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        local bg = KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("PanelDark"), BattleGrid.C("PanelHover"))
        draw.RoundedBox(2, 0, 0, w, h, bg)
        draw.SimpleText(label or BattleGrid:L("PREF_OPEN_KEY") or fallbackName or "", BattleGrid.F("small"), S(12), h / 2,
            BattleGrid.C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local binder = vgui.Create("DBinder", row)
    binder:Dock(RIGHT)
    binder:DockMargin(0, S(4), S(12), S(4))
    binder:SetWide(S(140))
    binder:SetValue(currentKey or 0)
    binder:SetText("")
    binder.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s, 10)
        local bg = KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("PanelDark"), BattleGrid.C("PanelHover"))
        draw.RoundedBox(2, 0, 0, w, h, bg)
        surface.SetDrawColor(KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("Border"), BattleGrid.C("Accent")))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local keyName = s.Trapping and BattleGrid:L("PREF_KEY_PRESS") or
            (input.GetKeyName(s:GetSelectedNumber()) or string.upper(fallbackName or "?"))
        draw.SimpleText(string.upper(keyName), BattleGrid.F("small"), w / 2, h / 2,
            BattleGrid.C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    binder.UpdateText = function(s) s:SetText("") end
    binder.OnCursorEntered = function() KF.Helpers.PlaySound(BattleGrid.Sounds.Hover) end
    binder.DoClick = function(s)
        BattleGrid:PlaySound("Click")
        s:SetText("")
        input.StartKeyTrapping()
        s.Trapping = true
    end
    binder.OnChange = function(_, num)
        if num and num > 0 and onCapture then onCapture(num) end
    end

    row._keyCode = currentKey
    row._binder = binder
    return row
end

function BattleGrid:CreateSpawnTypesEditor(parent, initialJSON, onChange)
    local entries = {}
    if initialJSON and initialJSON ~= "" then
        local tbl = util.JSONToTable(initialJSON)
        if istable(tbl) then
            for _, e in ipairs(tbl) do
                if e.class and e.max then
                    table.insert(entries, { class = e.class, max = tonumber(e.max) or 1 })
                end
            end
        end
    end

    local function FireChange()
        if #entries == 0 then
            onChange("")
            return
        end
        local out = {}
        for _, e in ipairs(entries) do
            table.insert(out, { class = e.class, max = e.max })
        end
        onChange(util.TableToJSON(out))
    end

    local npcList = list.Get("NPC") or {}
    local npcChoices = {}
    for class, data in SortedPairs(npcList) do
        table.insert(npcChoices, { class, (data.Name or class) .. " [" .. class .. "]" })
    end

    local container = vgui.Create("DPanel", parent)
    container:Dock(TOP)
    container:DockMargin(0, S(4), 0, S(4))
    container.Paint = function() end

    local rowsPanel = vgui.Create("DPanel", container)
    rowsPanel:Dock(TOP)
    rowsPanel.Paint = function() end

    local function RebuildRows()
        rowsPanel:Clear()
        if #entries == 0 then
            local empty = vgui.Create("DPanel", rowsPanel)
            empty:Dock(TOP)
            empty:SetTall(S(28))
            empty.Paint = function(_, w, h)
                draw.SimpleText(BattleGrid:L("ADMIN_CP_NPC_SPAWN_TYPES_NONE"), BattleGrid.F("small"), S(4), h / 2,
                    BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            rowsPanel:SetTall(S(28))
        else
            local rowH = S(38)
            for i, entry in ipairs(entries) do
                local row = vgui.Create("DPanel", rowsPanel)
                row:Dock(TOP)
                row:SetTall(rowH)
                row:DockMargin(0, 0, 0, S(2))
                row.Paint = function(_, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelDark"))
                end

                local removeBtn = vgui.Create("DButton", row)
                removeBtn:Dock(RIGHT)
                removeBtn:SetWide(S(28))
                removeBtn:SetText("")
                removeBtn:SetCursor("hand")
                removeBtn.Paint = function(s, w, h)
                    KF.Anim.UpdateHoverLerp(s)
                    local col = KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("TextMuted"), BattleGrid.C("Error"))
                    draw.SimpleText("×", BattleGrid.F("body"), w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                removeBtn.DoClick = function()
                    BattleGrid:PlaySound("Click")
                    table.remove(entries, i)
                    FireChange()
                    RebuildRows()
                end

                local maxInput = vgui.Create("DTextEntry", row)
                maxInput:Dock(RIGHT)
                maxInput:SetWide(S(50))
                maxInput:DockMargin(S(4), S(4), S(4), S(4))
                maxInput:SetNumeric(true)
                maxInput:SetValue(tostring(entry.max or 1))
                if maxInput.SetFont then maxInput:SetFont(BattleGrid.F("small")) end
                maxInput.OnChange = function(s)
                    local val = tonumber(s:GetValue())
                    if val and val >= 0 then
                        entry.max = math.floor(val)
                        FireChange()
                    end
                end

                local maxLabel = vgui.Create("DPanel", row)
                maxLabel:Dock(RIGHT)
                maxLabel:SetWide(S(24))
                maxLabel.Paint = function(_, w, h)
                    draw.SimpleText(BattleGrid:L("ADMIN_CP_NPC_SPAWN_TYPES_MAX"), BattleGrid.F("tiny"), w / 2, h / 2,
                        BattleGrid.C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                local nameLabel = vgui.Create("DPanel", row)
                nameLabel:Dock(FILL)
                nameLabel:DockMargin(S(8), 0, 0, 0)
                local displayName = entry.class
                if npcList[entry.class] then
                    displayName = (npcList[entry.class].Name or entry.class)
                end
                nameLabel.Paint = function(_, w, h)
                    draw.SimpleText(displayName, BattleGrid.F("small"), 0, h / 2,
                        BattleGrid.C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
            rowsPanel:SetTall(#entries * (rowH + S(2)))
        end
        container:SizeToChildren(false, true)
        container:InvalidateParent(true)
    end

    local addBtn = vgui.Create("DButton", container)
    addBtn:Dock(TOP)
    addBtn:SetTall(S(30))
    addBtn:DockMargin(0, S(2), 0, 0)
    addBtn:SetText("")
    addBtn:SetCursor("hand")
    addBtn.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        local bg = KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("PanelDark"), BattleGrid.C("PanelHover"))
        draw.RoundedBox(4, 0, 0, w, h, bg)
        local col = KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("TextMuted"), BattleGrid.C("Accent"))
        draw.SimpleText("+ " .. BattleGrid:L("ADMIN_CP_NPC_SPAWN_TYPES_ADD"), BattleGrid.F("small"), w / 2, h / 2,
            col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    addBtn.DoClick = function()
        BattleGrid:PlaySound("Click")
        local menu = DermaMenu()
        for _, choice in ipairs(npcChoices) do
            menu:AddOption(choice[2], function()
                table.insert(entries, { class = choice[1], max = 1 })
                FireChange()
                RebuildRows()
            end)
        end
        menu:Open()
    end

    RebuildRows()
    container:SizeToChildren(false, true)
    container.GetJSON = function() return #entries > 0 and util.TableToJSON(entries) or "" end
    return container
end

BattleGrid.PrefDefaults = {
    show_wp_map = true, show_area_map = true, show_cp_map = true, show_player = true, show_squad = true,
    show_grid = true, show_compass = true, z_filter_markers = false,
    show_world_waypoints = true, show_wp_descriptions = true, show_cp_world = true, show_cp_status_bar = true,
    show_wp_compass = true, show_cp_compass = true,
    waypoint_render_distance = 8000, cp_render_distance = 12000, cp_world_alpha = 255,
    distance_format = "meters", enable_sounds = true, open_key = 0, radar_map_show = true,
}

-- Cookies are SQLite reads; prefs are consulted every frame so they are cached after the first read.
local prefCache = {}

function BattleGrid:GetPref(key)
    local v = prefCache[key]
    if v == nil then
        local raw = cookie.GetString("BattleGrid." .. key, nil)
        local default = self.PrefDefaults[key]
        if raw == nil then v = default
        elseif isbool(default) then v = raw == "true"
        elseif isnumber(default) then v = tonumber(raw) or default
        else v = raw end
        prefCache[key] = v
    end
    return v
end

function BattleGrid:SetPref(key, value)
    prefCache[key] = value
    cookie.Set("BattleGrid." .. key, tostring(value))
end

function BattleGrid:FormatDistance(srcUnits)
    local fmt = self:GetPref("distance_format")
    if fmt == "kilometers" then
        local km = srcUnits * 0.01905
        return km >= 1 and string.format("%.1f km", km) or string.format("%d m", math.Round(km * 1000))
    elseif fmt == "miles" then
        local mi = srcUnits * 0.00001184
        return mi >= 0.1 and string.format("%.2f mi", mi) or string.format("%d ft", math.Round(mi * 5280))
    elseif fmt == "feet" then
        local ft = srcUnits * 0.0625
        return ft >= 1000 and string.format("%.1fk ft", ft / 1000) or string.format("%d ft", math.Round(ft))
    end
    return srcUnits >= 1000 and string.format("%.1f km", srcUnits / 1000) or string.format("%d m", math.Round(srcUnits))
end

function BattleGrid:OpenPreferences()
    if IsValid(self.MapFrame) then
        self:ToggleMapSettings()
        return
    end
    if IsValid(self.PrefFrame) then self.PrefFrame:Remove() end

    local width = S(460)
    local height = S(720)

    local frame = self:CreateEditorFrame(BattleGrid:L("PREF_TITLE"), width, height)
    self.PrefFrame = frame
    self:PopulateSettingsPanel(frame)
end

function BattleGrid:PopulateSettingsPanel(parent)
    local content = BattleGrid.MakeScroll(parent)

    BattleGrid.FormHeader(content, BattleGrid:L("PREF_MAP"))
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_WP_MAP"), BattleGrid:GetPref("show_wp_map"), function(v) BattleGrid:SetPref("show_wp_map", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_AREA_MAP"), BattleGrid:GetPref("show_area_map"), function(v) BattleGrid:SetPref("show_area_map", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_CP_MAP"), BattleGrid:GetPref("show_cp_map"), function(v) BattleGrid:SetPref("show_cp_map", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_PLAYER"), BattleGrid:GetPref("show_player"), function(v) BattleGrid:SetPref("show_player", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_SQUAD"), BattleGrid:GetPref("show_squad"), function(v) BattleGrid:SetPref("show_squad", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_GRID"), BattleGrid:GetPref("show_grid"), function(v) BattleGrid:SetPref("show_grid", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_COMPASS"), BattleGrid:GetPref("show_compass"), function(v) BattleGrid:SetPref("show_compass", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_Z_FILTER_MARKERS"), BattleGrid:GetPref("z_filter_markers"), function(v) BattleGrid:SetPref("z_filter_markers", v) end)

    BattleGrid.FormHeader(content, BattleGrid:L("PREF_HUD"))
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_WORLD_WP"), BattleGrid:GetPref("show_world_waypoints"), function(v) BattleGrid:SetPref("show_world_waypoints", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_WP_DESC"), BattleGrid:GetPref("show_wp_descriptions"), function(v) BattleGrid:SetPref("show_wp_descriptions", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_CP_WORLD"), BattleGrid:GetPref("show_cp_world"), function(v) BattleGrid:SetPref("show_cp_world", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_CP_STATUS_BAR"), BattleGrid:GetPref("show_cp_status_bar"), function(v) BattleGrid:SetPref("show_cp_status_bar", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_WP_COMPASS"), BattleGrid:GetPref("show_wp_compass"), function(v) BattleGrid:SetPref("show_wp_compass", v) end)
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_SHOW_CP_COMPASS"), BattleGrid:GetPref("show_cp_compass"), function(v) BattleGrid:SetPref("show_cp_compass", v) end)

    BattleGrid.FormHeader(content, BattleGrid:L("PREF_RENDER"))
    BattleGrid:CreateSlider(content, BattleGrid:L("PREF_WP_RENDER_DIST"), 500, 20000, 0, BattleGrid:GetPref("waypoint_render_distance"), function(v) BattleGrid:SetPref("waypoint_render_distance", tostring(math.floor(v))) end)
    BattleGrid:CreateSlider(content, BattleGrid:L("PREF_CP_RENDER_DIST"), 500, 20000, 0, BattleGrid:GetPref("cp_render_distance"), function(v) BattleGrid:SetPref("cp_render_distance", tostring(math.floor(v))) end)
    BattleGrid:CreateSlider(content, BattleGrid:L("PREF_CP_WORLD_ALPHA"), 10, 255, 0, BattleGrid:GetPref("cp_world_alpha"), function(v) BattleGrid:SetPref("cp_world_alpha", tostring(math.floor(v))) end)

    BattleGrid:CreateDropdown(content, BattleGrid:L("PREF_DISTANCE_FORMAT"), {
        {"meters",     BattleGrid:L("DIST_METERS")},
        {"kilometers", BattleGrid:L("DIST_KILOMETERS")},
        {"miles",      BattleGrid:L("DIST_MILES")},
        {"feet",       BattleGrid:L("DIST_FEET")},
    }, BattleGrid:GetPref("distance_format"), function(v) BattleGrid:SetPref("distance_format", v) end)

    BattleGrid.FormHeader(content, BattleGrid:L("PREF_CONTROLS"))
    BattleGrid:CreateToggle(content, BattleGrid:L("PREF_ENABLE_SOUNDS"), BattleGrid:GetPref("enable_sounds"), function(v) BattleGrid:SetPref("enable_sounds", v) end)
    local serverDefault = BattleGrid:GetConfigNumber("open_key")
    local serverKeyName = input.GetKeyName(serverDefault) or "M"
    local playerKey = BattleGrid:GetPref("open_key")
    BattleGrid:CreateKeybindCapture(content, playerKey > 0 and playerKey or serverDefault,
        string.upper(serverKeyName),
        function(key) BattleGrid:SetPref("open_key", key) end)

    BattleGrid.FormHeader(content, BattleGrid:L("PREF_LAYOUT"))
    BattleGrid:CreateButton(content, BattleGrid:L("LAYOUT_OPEN"), "ghost", function()
        if IsValid(BattleGrid.MapFrame) then BattleGrid.MapFrame:Remove() end
        if IsValid(BattleGrid.PrefFrame) then BattleGrid.PrefFrame:Remove() end
        BattleGrid:OpenLayoutEditor()
    end, { tall = 36, dock = TOP, margin = { 0, 4, 0, 6 } })

    if BattleGrid:GetConfigBool("radar_map_enabled") and BattleGrid.Compat.HasBF2HUD() then
        BattleGrid.FormHeader(content, BattleGrid:L("PREF_RADAR_MAP"))
        BattleGrid:CreateToggle(content, BattleGrid:L("PREF_RADAR_MAP_ENABLED"), BattleGrid:GetPref("radar_map_show"), function(v) BattleGrid:SetPref("radar_map_show", v) end)
    end

    if BattleGrid:HasPermission(LocalPlayer(), "BattleGrid.Admin") then
        BattleGrid.FormHeader(content, BattleGrid:L("PREF_ADMIN"))
        BattleGrid:CreateButton(content, BattleGrid:L("ADMIN_TITLE"), "primary", function()
            if IsValid(BattleGrid.MapFrame) then BattleGrid.MapFrame:Remove() end
            if IsValid(BattleGrid.PrefFrame) then BattleGrid.PrefFrame:Remove() end
            BattleGrid:OpenAdminMenu()
        end, { tall = 36, dock = TOP, margin = { 0, 4, 0, 6 } })
    end

    return content
end

hook.Add("PopulateToolMenu", "BattleGrid.ContextMenuPanel", function()
    spawnmenu.AddToolMenuOption("Utilities", BattleGrid:L("ADDON_NAME"), "BattleGrid_Config", BattleGrid:L("ADDON_NAME"), "", "", function(panel)
        panel:ClearControls()

        panel:Help(BattleGrid:L("ADDON_NAME") .. " v" .. BattleGrid.Version)

        local worldWP = panel:CheckBox(BattleGrid:L("PREF_SHOW_WORLD_WP"), "")
        worldWP:SetChecked(BattleGrid:GetPref("show_world_waypoints"))
        worldWP.OnChange = function(_, val)
            BattleGrid:SetPref("show_world_waypoints", val)
        end

        panel:Button(BattleGrid:L("MAP_OPEN"), "battlegrid_open")
        panel:Button(BattleGrid:L("PREF_OPEN_FULL"), "battlegrid_preferences")

        if BattleGrid:HasPermission(LocalPlayer(), "BattleGrid.Admin") then
            panel:Button(BattleGrid:L("ADMIN_TITLE"), "battlegrid_admin")
        end
    end)
end)

concommand.Add("battlegrid_open", function()
    BattleGrid:OpenMap()
end)

concommand.Add("battlegrid_preferences", function()
    BattleGrid:OpenPreferences()
end)

hook.Add("PlayerButtonDown", "BattleGrid.OpenMapKey", function(ply, btn)
    if not IsFirstTimePredicted() then return end
    if not IsValid(ply) or ply ~= LocalPlayer() then return end
    if gui.IsGameUIVisible() then return end

    local playerKey = BattleGrid:GetPref("open_key")
    local openKey = playerKey > 0 and playerKey or BattleGrid:GetConfigNumber("open_key")

    if btn == openKey then
        if IsValid(BattleGrid.MapFrame) then
            BattleGrid.MapFrame:Remove()
        else
            BattleGrid:OpenMap()
        end
    end
end)

BattleGrid.Layout = BattleGrid.Layout or {}
BattleGrid.Layout.ClientLayout = BattleGrid.Layout.ClientLayout or {}

BattleGrid.Layout.Blocks = {
    { id = "cp_announce", labelKey = "LAYOUT_CP_ANNOUNCE", w = 0.25, h = 0.12 },
    { id = "cp_world",    labelKey = "LAYOUT_CP_WORLD",    w = 0.20, h = 0.15 },
}

BattleGrid.Layout.Defaults = {
    cp_announce = { x = 0.5,  y = 0.27,  anchor = "center", yAnchor = "center", scale = 1 },
    cp_world    = { x = 0.5,  y = 0.12,  anchor = "center", yAnchor = "top",    scale = 1 },
}

local COOKIE_PREFIX = "bg_layout_"

local function NormToScreen(nx, ny, bw, bh, anchorH, anchorV)
    local sw, sh = ScrW(), ScrH()
    local px = math.Clamp(nx or 0.5, 0, 1) * sw
    local py = math.Clamp(ny or 0.5, 0, 1) * sh
    local ah = string.lower(anchorH or "left")
    local av = string.lower(anchorV or "top")
    local sx = px
    if ah == "center" then sx = px - bw / 2
    elseif ah == "right" then sx = px - bw end
    local sy = py
    if av == "center" then sy = py - bh / 2
    elseif av == "bottom" then sy = py - bh end
    return sx, sy
end

local function ScreenToNorm(sx, sy, bw, bh, anchorH, anchorV)
    local sw, sh = ScrW(), ScrH()
    local ah = string.lower(anchorH or "left")
    local av = string.lower(anchorV or "top")
    local px = sx
    if ah == "center" then px = sx + bw / 2
    elseif ah == "right" then px = sx + bw end
    local py = sy
    if av == "center" then py = sy + bh / 2
    elseif av == "bottom" then py = sy + bh end
    return math.Clamp(px / sw, 0, 1), math.Clamp(py / sh, 0, 1)
end

function BattleGrid.Layout.Resolve(blockId)
    local lp = BattleGrid.Layout._LivePreview
    if lp and lp[blockId] then return lp[blockId] end
    local cl = BattleGrid.Layout.ClientLayout[blockId]
    if cl then return cl end
    return BattleGrid.Layout.Defaults[blockId] or { x = 0.5, y = 0.5, anchor = "center", yAnchor = "center", scale = 1 }
end

function BattleGrid.Layout.ToPixels(blockId, bw, bh)
    local data = BattleGrid.Layout.Resolve(blockId)
    local scale = data.scale or 1
    if not bw then
        for _, b in ipairs(BattleGrid.Layout.Blocks) do
            if b.id == blockId then
                bw = b.w * ScrW() * scale
                bh = b.h * ScrH() * scale
                break
            end
        end
    end
    bw = bw or 0
    bh = bh or 0
    local sx, sy = NormToScreen(data.x, data.y, bw, bh, data.anchor, data.yAnchor)
    return sx, sy, scale
end

function BattleGrid.Layout.LoadClientLayout()
    BattleGrid.Layout.ClientLayout = {}
    for _, block in ipairs(BattleGrid.Layout.Blocks) do
        local raw = cookie.GetString(COOKIE_PREFIX .. block.id)
        if raw and raw ~= "" then
            local x, y, a, ya, sc = string.match(raw, "([%d%.]+),([%d%.]+),(%a+),(%a+),?([%d%.]*)")
            if x then
                BattleGrid.Layout.ClientLayout[block.id] = {
                    x = tonumber(x), y = tonumber(y),
                    anchor = a, yAnchor = ya,
                    scale = tonumber(sc) or 1,
                }
            end
        end
    end
end

function BattleGrid.Layout.SaveClientLayout()
    for _, block in ipairs(BattleGrid.Layout.Blocks) do
        local cl = BattleGrid.Layout.ClientLayout[block.id]
        if cl then
            cookie.Set(COOKIE_PREFIX .. block.id,
                string.format("%.4f,%.4f,%s,%s,%.2f", cl.x, cl.y, cl.anchor, cl.yAnchor, cl.scale or 1))
        else
            cookie.Set(COOKIE_PREFIX .. block.id, "")
        end
    end
end

function BattleGrid.Layout.ResetClientLayout()
    BattleGrid.Layout.ClientLayout = {}
    for _, block in ipairs(BattleGrid.Layout.Blocks) do
        cookie.Set(COOKIE_PREFIX .. block.id, "")
    end
end

BattleGrid.Layout.LoadClientLayout()

function BattleGrid:OpenLayoutEditor()
    if IsValid(BattleGrid._LayoutFrame) then BattleGrid._LayoutFrame:Remove() end

    local frameRef = {}
    BattleGrid.Layout._LivePreview = {}

    local overlay, blockPanels, editingLayout = KF.LayoutEditor.Open({
        blocks = BattleGrid.Layout.Blocks,
        defaults = BattleGrid.Layout.Defaults,
        isAdmin = false,
        L = function(k) return BattleGrid:L(k) end,
        fontPrefix = "BGLayout",
        frameRef = frameRef,
        titleClient = BattleGrid:L("LAYOUT_TITLE"),
        hint = BattleGrid:L("LAYOUT_HINT"),
        btnSave = BattleGrid:L("LAYOUT_SAVE"),
        btnReset = BattleGrid:L("LAYOUT_RESET"),
        btnClose = BattleGrid:L("LAYOUT_CLOSE"),
        scaleStep = 0.1,
        scaleMin = 0.5,
        scaleMax = 2,
        resolveLayout = function(blockId)
            local cl = BattleGrid.Layout.ClientLayout[blockId]
            if cl then return cl end
            return BattleGrid.Layout.Defaults[blockId]
        end,
        onLayoutChange = function(layout)
            BattleGrid.Layout._LivePreview = layout
        end,
        onSave = function(layoutData)
            BattleGrid.Layout.ClientLayout = {}
            for id, data in pairs(layoutData) do
                BattleGrid.Layout.ClientLayout[id] = table.Copy(data)
            end
            BattleGrid.Layout.SaveClientLayout()
            BattleGrid.Layout._LivePreview = nil
            BattleGrid._LayoutFrame = nil
        end,
        onReset = function()
            BattleGrid.Layout.ResetClientLayout()
        end,
        onClose = function()
            BattleGrid.Layout._LivePreview = nil
            BattleGrid._LayoutFrame = nil
        end,
    })

    BattleGrid._LayoutFrame = frameRef[1]
end

concommand.Add("battlegrid_layout", function() BattleGrid:OpenLayoutEditor() end)

BattleGrid._cfg = BattleGrid._cfg or {}
BattleGrid._pendingCfg = BattleGrid._pendingCfg or {}

BattleGrid.Net:Receive("SyncConfig", function()
    local data = BattleGrid.Net:ReadJSON()
    if not data then return end
    for k, v in pairs(data) do
        BattleGrid._cfg[k] = v
    end
    hook.Run("BattleGrid.ConfigUpdated")
end)

hook.Add("InitPostEntity", "BattleGrid.ClientReady", function()
    BattleGrid.Net:SendToServer("ClientReady")
end)

function BattleGrid:CompassProject(pos, plyPos, yaw, px, width)
    local delta = pos - plyPos
    if delta:LengthSqr() < 1 then return nil end

    local targetHeading = (360 - (delta:Angle().y % 360)) % 360
    local rel = (targetHeading - yaw + 540) % 360 - 180
    if math.abs(rel) > 90 then return nil end

    local fade = math.Clamp((1 - (math.abs(rel / 90) - 0.7) / 0.3), 0, 1)
    return px + (rel / 180) * width, fade
end
