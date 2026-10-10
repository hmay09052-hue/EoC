if not CLIENT then return end

GRN_DEFCON = GRN_DEFCON or {}

local C = GRN_DEFCON.Config
local NET_TERMINAL_DATA = "GRN_Defcon_TerminalData"
local NET_TERMINAL_ACTION = "GRN_Defcon_TerminalAction"
local NET_REQUEST = "GRN_Defcon_Request"

local SND_CLICK = "buttons/lightswitch2.wav"
local SND_ERROR = "buttons/button10.wav"

-- Farben passend zum Echoes of Clones HUD / Militärischen Funksystem
local P = {
    yellow  = Color(255, 190, 50),
    yellowD = Color(255, 190, 50, 56),
    yellowF = Color(255, 190, 50, 20),
    white   = Color(244, 241, 233),
    text    = Color(216, 219, 225),
    soft    = Color(157, 163, 173),
    muted   = Color(101, 107, 117),
    bg      = Color(7, 9, 12, 240),
    panel   = Color(8, 11, 15, 220),
    panel2  = Color(14, 18, 23, 235),
    line    = Color(207, 216, 228, 38),
    lineS   = Color(207, 216, 228, 77),
    red     = Color(225, 88, 88),
    green   = Color(74, 203, 130),
}
GRN_DEFCON.UIColors = P
if SYMUI then SYMUI.ApplyEoCPalette(P) end -- SymChars-Design

surface.CreateFont("GRNDefcon_Title",   { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 34, weight = 400, extended = true })
surface.CreateFont("GRNDefcon_Head",    { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 22, weight = 400, extended = true })
surface.CreateFont("GRNDefcon_Num",     { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 30, weight = 400, extended = true })
surface.CreateFont("GRNDefcon_Name",    { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 30, weight = 400, extended = true })
surface.CreateFont("GRNDefcon_Big",     { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 72, weight = 400, extended = true })
surface.CreateFont("GRNDefcon_Sub",     { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 12, weight = 600, extended = true })
surface.CreateFont("GRNDefcon_Section", { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 13, weight = 700, extended = true })
surface.CreateFont("GRNDefcon_Text",    { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 16, weight = 500, extended = true })
surface.CreateFont("GRNDefcon_Small",   { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 13, weight = 500, extended = true })
surface.CreateFont("GRNDefcon_Button",  { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 22, weight = 400, extended = true })

local COLOR_PRESETS = { "#55E18F", "#55B8FF", "#FFD85A", "#FF994D", "#FF4F5E", "#B47CFF", "#E6E6E6" }

local payload
local selectedId
local Draft = { editing = nil, pending = nil, id = "", name = "", state = "", short = "", desc = "", color = "#55B8FF" }

---------------------------------------------------------------------------
-- Hilfsfunktionen
---------------------------------------------------------------------------
local function PlayClick() surface.PlaySound(SND_CLICK) end

local function HexToColor(hex, alpha)
    local raw = string.gsub(tostring(hex or "#55b8ff"), "#", "")
    if #raw ~= 6 then raw = "55b8ff" end
    return Color(
        tonumber(string.sub(raw, 1, 2), 16) or 85,
        tonumber(string.sub(raw, 3, 4), 16) or 184,
        tonumber(string.sub(raw, 5, 6), 16) or 255,
        alpha or 255
    )
end

local function GetLevel(id)
    if not payload then return nil end
    id = tonumber(id)
    for _, level in ipairs(payload.levels or {}) do
        if tonumber(level.ID) == id then return level end
    end
end

local function Fit(text, font, maxWidth)
    text = tostring(text or "")
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxWidth then return text end
    while #text > 0 and surface.GetTextSize(text .. "...") > maxWidth do
        text = string.sub(text, 1, (utf8.offset(text, -1) or #text) - 1)
    end
    return text .. "..."
end

local function SendSelect(level)
    net.Start(NET_TERMINAL_ACTION)
        net.WriteUInt(0, 2)
        net.WriteUInt(math.Clamp(math.floor(tonumber(level) or 1), 1, 65535), 16)
    net.SendToServer()

    timer.Simple(0.35, function()
        net.Start(NET_REQUEST)
        net.SendToServer()
    end)
end

local function SendSave(id, name, state, short, description, color)
    net.Start(NET_TERMINAL_ACTION)
        net.WriteUInt(1, 2)
        net.WriteUInt(math.Clamp(math.floor(tonumber(id) or 1), 1, 65535), 16)
        net.WriteString(tostring(name or ""))
        net.WriteString(tostring(state or ""))
        net.WriteString(tostring(short or ""))
        net.WriteString(tostring(description or ""))
        net.WriteString(tostring(color or "#55B8FF"))
    net.SendToServer()
end

local function SendDelete(id)
    net.Start(NET_TERMINAL_ACTION)
        net.WriteUInt(2, 2)
        net.WriteUInt(math.Clamp(math.floor(tonumber(id) or 1), 1, 65535), 16)
    net.SendToServer()
end

---------------------------------------------------------------------------
-- UI Bausteine
---------------------------------------------------------------------------
local function MakeButton(parent, label, onClick)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Label  = label
    b.Accent = P.yellow
    b.Paint = function(s, w, h)
        if SYMUI then
            local tc = SYMUI.PaintEoCButton(s, w, h, P.red)
            draw.SimpleText(s.Label, s.Font or "GRNDefcon_Button", w / 2, h / 2, tc, 1, 1)
            return
        end
        local enabled = s:IsEnabled()
        local hov = s:IsHovered() and enabled
        local bg = s.Active and ColorAlpha(s.Accent, 26) or (hov and P.panel2 or P.panel)
        if s.Solid and enabled then bg = hov and s.Accent or ColorAlpha(s.Accent, 215) end

        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor((s.Active or s.Solid) and enabled and ColorAlpha(s.Accent, 185) or (hov and P.lineS or P.line))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if s.Active then
            surface.SetDrawColor(s.Accent)
            surface.DrawRect(0, h - 2, w, 2)
        end

        local tc = not enabled and P.muted or (s.Solid and P.bg or (s.Active and s.Accent or P.white))
        draw.SimpleText(s.Label, s.Font or "GRNDefcon_Button", w / 2, h / 2, tc, 1, 1)
    end
    b.DoClick = function(s)
        PlayClick()
        if onClick then onClick(s) end
    end
    return b
end

local function StyleEntry(e, placeholder)
    e:SetFont("GRNDefcon_Text")
    e.Placeholder = placeholder
    e.Paint = function(s, w, h)
        surface.SetDrawColor(P.panel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(s:HasFocus() and ColorAlpha(P.yellow, 170) or P.line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if s:GetText() == "" and s.Placeholder then
            draw.SimpleText(s.Placeholder, "GRNDefcon_Text", 6, s:IsMultiline() and 4 or h / 2, P.muted, 0, s:IsMultiline() and 0 or 1)
        end
        s:DrawTextEntryText(s:IsEditable() and P.white or P.muted, ColorAlpha(P.yellow, 70), P.yellow)
    end
end

local function Section(parent, text, tall)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(tall or 26)
    p.Text = text
    p.Paint = function(s, w, h)
        if SYMUI then
            local text = string.upper(isfunction(s.Text) and s.Text() or s.Text or "")
            surface.SetFont("GRNDefcon_Section")
            local tw = surface.GetTextSize(text)
            draw.SimpleText(text, "GRNDefcon_Section", 0, h / 2 + 1, P.white, 0, 1)
            local rw = 0
            if s.Right then
                local rt, col = s.Right()
                rw = draw.SimpleText(rt or "", "GRNDefcon_Sub", w - 2, h / 2 + 1, col or P.muted, 2, 1) or 0
            end
            surface.SetDrawColor(P.lineS)
            surface.DrawRect(tw + 10, h / 2 + 1, math.max(0, w - tw - 20 - rw), 1)
            return
        end
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(0, 8, 2, h - 14)
        draw.SimpleText(isfunction(s.Text) and s.Text() or s.Text, "GRNDefcon_Section", 10, h / 2 + 1, P.soft, 0, 1)
        if s.Right then
            local text, col = s.Right()
            draw.SimpleText(text or "", "GRNDefcon_Sub", w - 2, h / 2 + 1, col or P.muted, 2, 1)
        end
    end
    return p
end

local function Spacer(parent, h)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(h)
    p.Paint = nil
    return p
end

local function StyleScroll(scroll)
    local bar = scroll:GetVBar()
    bar:SetWide(4)
    bar.Paint = function(_, w, h) surface.SetDrawColor(P.line) surface.DrawRect(0, 0, w, h) end
    bar.btnUp.Paint = function() end
    bar.btnDown.Paint = function() end
    bar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(P.yellow) surface.DrawRect(0, 0, w, h) end
end

local function FramedPanel(parent)
    local p = vgui.Create("DPanel", parent)
    p.Paint = function(_, w, h)
        surface.SetDrawColor(P.panel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(P.line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    return p
end

local function EmptyLabel(parent, text)
    local l = vgui.Create("DLabel", parent)
    l:Dock(TOP)
    l:SetTall(60)
    l:SetFont("GRNDefcon_Small")
    l:SetTextColor(P.muted)
    l:SetContentAlignment(5)
    l:SetText(text)
    return l
end

local function LevelTag(level)
    if payload and tonumber(level.ID) == tonumber(payload.current) then return "AKTIV", P.green end
    if level.Custom then return "EIGENE", P.yellow end
    return "BASIS", P.muted
end

-- Zeile in einer Stufenliste (Stil wie die Funklog-Einträge)
local function LevelRow(scroll, level, isSelected, onClick)
    local col = HexToColor(level.Color)
    local row = vgui.Create("DButton", scroll)
    row:Dock(TOP)
    row:SetTall(56)
    row:DockMargin(0, 0, 6, 4)
    row:SetText("")
    row.Paint = function(s, w, h)
        local sel = isSelected()
        if SYMUI then
            local SY = SYMUI
            SY.Box(0, 0, w, h, sel and SY.Accent(22) or (s:IsHovered() and SY.col.panel2 or SY.col.panel))
            if sel then SY.Glow(0, 0, w, h, SY.Accent(200), SY.S(6), 0.7) end
            SY.Outline(0, 0, w, h, sel and SY.Accent() or (s:IsHovered() and SY.col.line2 or SY.col.line))
            SY.Box(0, 0, SY.S(3), h, col)
        else
            surface.SetDrawColor(sel and P.yellowF or (s:IsHovered() and P.panel2 or P.panel))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(sel and ColorAlpha(P.yellow, 150) or P.line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            surface.SetDrawColor(col)
            surface.DrawRect(0, 0, 2, h)
        end

        draw.SimpleText(tostring(level.ID), "GRNDefcon_Num", 30, h / 2, col, 1, 1)

        local tag, tcol = LevelTag(level)
        local tagW = draw.SimpleText(tag, "GRNDefcon_Sub", w - 10, 17, tcol, 2, 1)
        if tag == "AKTIV" then
            local a = 140 + math.sin(CurTime() * 4) * 115
            draw.RoundedBox(3, w - 10 - tagW - 12, 14, 6, 6, ColorAlpha(P.green, a))
        end

        draw.SimpleText(Fit(level.Name or "UNBEKANNT", "GRNDefcon_Text", w - 70 - tagW - 28), "GRNDefcon_Text", 56, 17, P.white, 0, 1)
        draw.SimpleText(Fit(level.State or "", "GRNDefcon_Small", w - 70), "GRNDefcon_Small", 56, 39, P.soft, 0, 1)
    end
    row.DoClick = function()
        PlayClick()
        onClick()
    end
    return row
end

---------------------------------------------------------------------------
-- Tab: Stufen
---------------------------------------------------------------------------
local function BuildLevelsTab(parent)
    if not GetLevel(selectedId) then selectedId = payload.current end

    -- Rechte Spalte: Details
    local right = vgui.Create("DPanel", parent)
    right:Dock(RIGHT)
    right:SetWide(340)
    right.Paint = nil

    Section(right, "PROTOKOLL-DETAILS")
    Spacer(right, 4)

    local activate = MakeButton(right, "")
    activate:Dock(BOTTOM)
    activate:SetTall(48)
    activate.Solid = true
    activate.Think = function(s)
        local level = GetLevel(selectedId)
        if not level then
            s.Label = "KEINE STUFE GEWÄHLT"
            s:SetEnabled(false)
        elseif not payload.canChange then
            s.Label = "KEINE BERECHTIGUNG"
            s:SetEnabled(false)
        elseif tonumber(level.ID) == tonumber(payload.current) then
            s.Label = "DEFCON " .. level.ID .. " IST AKTIV"
            s:SetEnabled(false)
        else
            s.Label = "DEFCON " .. level.ID .. " AKTIVIEREN"
            s:SetEnabled(true)
        end
        s.Accent = level and HexToColor(level.Color) or P.yellow
    end
    activate.DoClick = function()
        local level = GetLevel(selectedId)
        if not level then return end
        PlayClick()
        SendSelect(level.ID)
    end

    local box = FramedPanel(right)
    box:Dock(FILL)
    box:DockMargin(0, 0, 0, 10)
    box:DockPadding(16, 150, 6, 10)
    local base = box.Paint
    box.Paint = function(s, w, h)
        base(s, w, h)
        local level = GetLevel(selectedId)
        if not level then return end
        local col = HexToColor(level.Color)

        surface.SetDrawColor(col.r, col.g, col.b, 12)
        surface.DrawRect(1, 1, w - 2, 128)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, 2, 130)

        draw.SimpleText("DEFCON", "GRNDefcon_Sub", 16, 20, P.soft, 0, 1)
        local tag, tcol = LevelTag(level)
        draw.SimpleText(tag, "GRNDefcon_Sub", w - 12, 20, tcol, 2, 1)

        local numW = draw.SimpleText(tostring(level.ID), "GRNDefcon_Big", 14, 66, col, 0, 1)
        local tx = 14 + numW + 14
        draw.SimpleText(Fit(level.Name or "UNBEKANNT", "GRNDefcon_Name", w - tx - 12), "GRNDefcon_Name", tx, 56, P.white, 0, 1)
        draw.SimpleText(Fit(level.State or "", "GRNDefcon_Sub", w - tx - 12), "GRNDefcon_Sub", tx, 80, col, 0, 1)

        surface.SetDrawColor(P.line)
        surface.DrawRect(12, 130, w - 24, 1)
        draw.SimpleText(Fit(level.Short or "", "GRNDefcon_Head", w - 28), "GRNDefcon_Head", 16, 112, P.text, 0, 1)
    end

    local descScroll = vgui.Create("DScrollPanel", box)
    descScroll:Dock(FILL)
    StyleScroll(descScroll)

    local desc = vgui.Create("DLabel", descScroll)
    desc:Dock(TOP)
    desc:DockMargin(0, 0, 8, 0)
    desc:SetWrap(true)
    desc:SetAutoStretchVertical(true)
    desc:SetFont("GRNDefcon_Small")
    desc:SetTextColor(P.soft)
    desc.Think = function(s)
        local level = GetLevel(selectedId)
        local text = level and (level.Description or "") or "Stufe auswählen."
        if s._text ~= text then
            s._text = text
            s:SetText(text)
        end
    end

    -- Linke Spalte: aktueller Status + Liste
    local left = vgui.Create("DPanel", parent)
    left:Dock(FILL)
    left:DockMargin(0, 0, 18, 0)
    left.Paint = nil

    Section(left, "AKTIVER STATUS")
    Spacer(left, 4)

    local status = FramedPanel(left)
    status:Dock(TOP)
    status:SetTall(84)
    local sBase = status.Paint
    status.Paint = function(s, w, h)
        sBase(s, w, h)
        local level = GetLevel(payload.current) or {}
        local col = HexToColor(level.Color)
        surface.SetDrawColor(col.r, col.g, col.b, 16)
        surface.DrawRect(1, 1, w - 2, h - 2)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, 2, h)

        draw.SimpleText("DEFCON", "GRNDefcon_Sub", 16, 22, P.soft, 0, 1)
        local numW = draw.SimpleText(tostring(payload.current or "?"), "GRNDefcon_Big", 14, h / 2 + 8, col, 0, 1)
        local tx = math.max(90, 14 + numW + 18)

        local a = 140 + math.sin(CurTime() * 4) * 115
        draw.RoundedBox(3, w - 112, 19, 6, 6, ColorAlpha(P.green, a))
        draw.SimpleText("SYNCHRONISIERT", "GRNDefcon_Sub", w - 12, 22, P.green, 2, 1)

        draw.SimpleText(Fit(level.Name or "UNBEKANNT", "GRNDefcon_Name", w - tx - 130), "GRNDefcon_Name", tx, h / 2 - 8, P.white, 0, 1)
        draw.SimpleText(Fit(level.State or "", "GRNDefcon_Sub", w - tx - 16), "GRNDefcon_Sub", tx, h / 2 + 17, col, 0, 1)
    end

    Spacer(left, 10)
    local head = Section(left, "VERFÜGBARE STUFEN")
    head.Right = function()
        local n = #(payload.levels or {})
        return n .. (n == 1 and " STUFE" or " STUFEN"), P.muted
    end
    Spacer(left, 4)

    local scroll = vgui.Create("DScrollPanel", left)
    scroll:Dock(FILL)
    StyleScroll(scroll)

    if #(payload.levels or {}) == 0 then
        EmptyLabel(scroll, "Keine Stufen vorhanden.")
    end

    for _, level in ipairs(payload.levels or {}) do
        local id = tonumber(level.ID)
        local row = LevelRow(scroll, level,
            function() return tonumber(selectedId) == id end,
            function() selectedId = id end)
        row.DoDoubleClick = function()
            if payload.canChange and id ~= tonumber(payload.current) then
                PlayClick()
                SendSelect(id)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Tab: Verwaltung (Staff)
---------------------------------------------------------------------------
local function ResetDraft()
    Draft.editing, Draft.pending = nil, nil
    Draft.id, Draft.name, Draft.state, Draft.short, Draft.desc = "", "", "", "", ""
    Draft.color = "#55B8FF"
end

local function LoadDraft(level)
    Draft.editing = tonumber(level.ID)
    Draft.pending = nil
    Draft.id = tostring(level.ID)
    Draft.name = level.Name or ""
    Draft.state = level.State or ""
    Draft.short = level.Short or ""
    Draft.desc = level.Description or ""
    Draft.color = string.upper(level.Color or "#55B8FF")
end

local function Field(parent, label, key, placeholder, tall)
    local wrap = vgui.Create("DPanel", parent)
    wrap.Paint = function(_, w)
        draw.SimpleText(label, "GRNDefcon_Sub", 1, 8, P.soft, 0, 1)
    end
    wrap:DockPadding(0, 18, 0, 0)

    local e = vgui.Create("DTextEntry", wrap)
    e:Dock(FILL)
    StyleEntry(e, placeholder)
    e:SetText(Draft[key] or "")
    e.OnChange = function(s) Draft[key] = s:GetText() end
    wrap.Entry = e
    wrap:SetTall((tall or 34) + 18)
    return wrap, e
end

local function BuildManageTab(parent, frame)
    local editing = Draft.editing and GetLevel(Draft.editing)
    if not (editing and editing.Custom) then Draft.editing = nil end

    -- Linke Spalte: eigene Stufen
    local listCol = vgui.Create("DPanel", parent)
    listCol:Dock(LEFT)
    listCol:SetWide(340)
    listCol.Paint = nil

    local head = Section(listCol, "EIGENE STUFEN")
    local bNew = MakeButton(head, "NEU", function()
        ResetDraft()
        frame:ShowTab(2)
    end)
    bNew:Dock(RIGHT)
    bNew:SetWide(72)
    bNew:DockMargin(0, 1, 0, 1)
    Spacer(listCol, 6)

    local customCount = 0
    for _, level in ipairs(payload.levels or {}) do
        if level.Custom then customCount = customCount + 1 end
    end

    local footer = vgui.Create("DPanel", listCol)
    footer:Dock(BOTTOM)
    footer:SetTall(24)
    footer.Paint = function(_, w, h)
        local maximum = math.max(1, tonumber(C.MaximumCustomLevels) or 32)
        draw.SimpleText(customCount .. " / " .. maximum .. " EIGENE STUFEN", "GRNDefcon_Section", 2, h / 2, customCount >= maximum and P.red or P.muted, 0, 1)
    end

    local scroll = vgui.Create("DScrollPanel", listCol)
    scroll:Dock(FILL)
    StyleScroll(scroll)

    if customCount == 0 then
        EmptyLabel(scroll, "Noch keine eigenen Stufen erstellt.")
    end

    for _, level in ipairs(payload.levels or {}) do
        if level.Custom then
            local id = tonumber(level.ID)
            LevelRow(scroll, level,
                function() return Draft.editing == id end,
                function()
                    LoadDraft(level)
                    frame:ShowTab(2)
                end)
        end
    end

    -- Rechte Spalte: Editor
    local form = vgui.Create("DPanel", parent)
    form:Dock(FILL)
    form:DockMargin(18, 0, 0, 0)
    form.Paint = nil

    Section(form, Draft.editing and ("STUFE " .. Draft.editing .. " BEARBEITEN") or "NEUE STUFE ERSTELLEN")
    Spacer(form, 4)

    local row1 = vgui.Create("DPanel", form)
    row1:Dock(TOP)
    row1:SetTall(52)
    row1.Paint = nil

    local fId, eId = Field(row1, "NUMMER", "id", "z.B. 6")
    fId:Dock(LEFT)
    fId:SetWide(110)
    eId:SetNumeric(true)
    eId:SetEditable(Draft.editing == nil)

    local fName = Field(row1, "NAME", "name", "z.B. LOCKDOWN")
    fName:Dock(FILL)
    fName:DockMargin(10, 0, 0, 0)

    Spacer(form, 8)
    local fState = Field(form, "STATUS", "state", "z.B. BASIS ABGERIEGELT")
    fState:Dock(TOP)

    Spacer(form, 8)
    local fShort = Field(form, "KURZTEXT", "short", "z.B. ALLE ZUGÄNGE GESPERRT")
    fShort:Dock(TOP)

    Spacer(form, 8)
    local colorRow = vgui.Create("DPanel", form)
    colorRow:Dock(TOP)
    colorRow:SetTall(52)
    colorRow.Paint = nil

    local fColor, eColor = Field(colorRow, "FARBE", "color", "#55B8FF")
    fColor:Dock(LEFT)
    fColor:SetWide(150)

    local swatches = vgui.Create("DPanel", colorRow)
    swatches:Dock(FILL)
    swatches:DockMargin(10, 18, 0, 0)
    swatches.Paint = nil
    for _, hex in ipairs(COLOR_PRESETS) do
        local col = HexToColor(hex)
        local sw = vgui.Create("DButton", swatches)
        sw:Dock(LEFT)
        sw:SetWide(34)
        sw:DockMargin(0, 0, 6, 0)
        sw:SetText("")
        sw.Paint = function(s, w, h)
            local active = string.upper(Draft.color or "") == hex
            surface.SetDrawColor(col.r, col.g, col.b, s:IsHovered() and 255 or 200)
            surface.DrawRect(4, 4, w - 8, h - 8)
            surface.SetDrawColor(active and P.yellow or (s:IsHovered() and P.lineS or P.line))
            surface.DrawOutlinedRect(0, 0, w, h, active and 2 or 1)
        end
        sw.DoClick = function()
            PlayClick()
            Draft.color = hex
            eColor:SetText(hex)
        end
    end

    Spacer(form, 8)
    local fDesc = Field(form, "BESCHREIBUNG", "desc", "Anweisungen für alle Einheiten...", 70)
    fDesc:Dock(TOP)
    fDesc.Entry:SetMultiline(true)

    local actions = vgui.Create("DPanel", form)
    actions:Dock(BOTTOM)
    actions:SetTall(48)
    actions.Paint = nil

    if Draft.editing then
        local del = MakeButton(actions, "LÖSCHEN", function()
            Draft.pending = nil
            SendDelete(Draft.editing)
        end)
        del.Accent = P.red
        del:Dock(RIGHT)
        del:SetWide(130)
        del:DockMargin(8, 0, 0, 0)
    end

    local save = MakeButton(actions, "")
    save:Dock(FILL)
    save.Solid = true
    save.Think = function(s)
        s.Label = Draft.editing and "ÄNDERUNGEN SPEICHERN" or "STUFE ERSTELLEN"
        local hex = string.upper(Draft.color or "")
        s.Accent = string.match(hex, "^#%x%x%x%x%x%x$") and HexToColor(hex) or P.yellow
    end
    save.DoClick = function()
        local id = tonumber(Draft.id)
        local name = string.Trim(Draft.name or "")
        if not id or id < 1 or name == "" then
            surface.PlaySound(SND_ERROR)
            frame:SetMessage("Nummer und Name eingeben.", 2)
            return
        end
        PlayClick()
        Draft.pending = id
        SendSave(id, name, Draft.state, Draft.short, Draft.desc, Draft.color)
    end
end

---------------------------------------------------------------------------
-- Hauptfenster
---------------------------------------------------------------------------
local function OpenTerminal()
    local existing = GRN_DEFCON.TerminalFrame
    if IsValid(existing) then
        if existing.CanManage == payload.canManage then
            existing:SetMessage(payload.message, payload.messageType)
            existing:ShowTab(existing.Tab or 1)
            existing:MakePopup()
            return
        end
        existing:Remove()
    end

    local W = math.min(1000, ScrW() - 40)
    local H = math.min(640, ScrH() - 40)
    local canManage = payload.canManage

    local f = vgui.Create("DFrame")
    GRN_DEFCON.TerminalFrame = f
    f.CanManage = canManage
    f:SetSize(W, H)
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetDraggable(true)
    f:DockPadding(20, 80, 20, 20)
    f:MakePopup()
    f:SetAlpha(0)
    f:AlphaTo(255, 0.15)

    f.OnKeyCodePressed = function(s, key)
        if key == KEY_ESCAPE then s:Close() end
    end

    function f:SetMessage(text, kind)
        if not text or text == "" then return end
        self.Msg, self.MsgKind, self.MsgUntil = text, kind, CurTime() + 4
        if kind == 2 then surface.PlaySound(SND_ERROR) end
    end

    f.Paint = function(s, w, h)
        if SYMUI then
            local status, scol
            if s.Msg and CurTime() < (s.MsgUntil or 0) then
                status = string.upper(s.Msg)
                scol = s.MsgKind == 2 and P.red or (s.MsgKind == 1 and P.green or P.yellow)
            elseif payload and payload.canChange then
                status, scol = "ZUGRIFF AUTORISIERT", P.green
            else
                status, scol = "NUR LESEZUGRIFF", P.soft
            end
            SYMUI.PaintWindow(w, h, nil, { header = 64 })
            SYMUI.PaintEoCHeader("DEFCON KONTROLLSYSTEM", "TERMINAL // SICHERHEITSNETZ", "GRNDefcon_Title", "GRNDefcon_Sub", P.yellow, status, scol)
            return
        end
        surface.SetDrawColor(P.bg)
        surface.DrawRect(0, 0, w, h)

        -- Kopfzeile wie im HUD: dunkler Balken, gelbe Linie mit Verlauf
        surface.SetDrawColor(P.panel2)
        surface.DrawRect(0, 0, w, 62)
        surface.SetDrawColor(P.yellowD)
        surface.DrawRect(0, 62, w, 1)
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(0, 62, 180, 2)

        -- Ecken-Markierungen
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(0, 0, 14, 2)
        surface.DrawRect(0, 0, 2, 14)
        surface.DrawRect(w - 14, h - 2, 14, 2)
        surface.DrawRect(w - 2, h - 14, 2, 14)

        draw.SimpleText("DEFCON KONTROLLSYSTEM", "GRNDefcon_Title", 20, 24, P.white, 0, 1)
        local subW = draw.SimpleText("TERMINAL // SICHERHEITSNETZ", "GRNDefcon_Sub", 21, 46, P.yellow, 0, 1)

        local status, scol
        if s.Msg and CurTime() < (s.MsgUntil or 0) then
            status = string.upper(s.Msg)
            scol = s.MsgKind == 2 and P.red or (s.MsgKind == 1 and P.green or P.yellow)
        elseif payload and payload.canChange then
            status, scol = "ZUGRIFF AUTORISIERT", P.green
        else
            status, scol = "NUR LESEZUGRIFF", P.soft
        end
        draw.SimpleText("//  " .. status, "GRNDefcon_Sub", 21 + subW + 8, 46, scol, 0, 1)

        surface.SetDrawColor(P.line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local close = MakeButton(f, "X", function() f:Close() end)
    close.Accent = P.red
    close:SetSize(34, 34)
    close:SetPos(W - 48, 14)

    local tabs = {}
    local tabDefs = { { 1, "STUFEN" } }
    if canManage then tabDefs[2] = { 2, "VERWALTUNG" } end

    -- Tabs rechtsbündig neben dem Schließen-Button
    local tabX = W - 48 - 10 - #tabDefs * 120 - (#tabDefs - 1) * 6
    for i, def in ipairs(tabDefs) do
        local b = MakeButton(f, def[2], function() f:ShowTab(def[1]) end)
        b:SetSize(120, 34)
        b:SetPos(tabX + (i - 1) * 126, 14)
        tabs[def[1]] = b
    end

    local content = vgui.Create("DPanel", f)
    content:Dock(FILL)
    content.Paint = nil

    function f:ShowTab(id)
        if id == 2 and not self.CanManage then id = 1 end
        self.Tab = id
        for k, b in pairs(tabs) do b.Active = k == id end
        content:Clear()
        if id == 2 then
            BuildManageTab(content, self)
        else
            BuildLevelsTab(content)
        end
    end

    f.OnRemove = function()
        if GRN_DEFCON.TerminalFrame == f then GRN_DEFCON.TerminalFrame = nil end
    end

    f:SetMessage(payload.message, payload.messageType)
    f:ShowTab(1)
end

local function CloseTerminal()
    if IsValid(GRN_DEFCON.TerminalFrame) then GRN_DEFCON.TerminalFrame:Remove() end
    GRN_DEFCON.TerminalFrame = nil
end

hook.Add("GRN_Defcon_ClientLevelChanged", "GRN_Defcon_UpdateTerminalCurrent", function(level, data)
    if istable(data) then
        GRN_DEFCON.ClientLevels = GRN_DEFCON.ClientLevels or {}
        GRN_DEFCON.ClientLevels[level] = data
    end

    if not payload then return end
    payload.current = level

    if istable(data) then
        local copy = table.Copy(data)
        copy.ID = level
        local found = false
        for index, existing in ipairs(payload.levels or {}) do
            if tonumber(existing.ID) == tonumber(level) then
                payload.levels[index] = copy
                found = true
                break
            end
        end
        if not found then payload.levels[#payload.levels + 1] = copy end
    end
end)

net.Receive(NET_TERMINAL_DATA, function()
    local current = net.ReadUInt(16)
    local canChange = net.ReadBool()
    local canManage = net.ReadBool()
    local levels = util.JSONToTable(net.ReadString() or "") or {}
    local message = net.ReadString()
    local messageType = net.ReadUInt(2)

    GRN_DEFCON.ClientLevels = GRN_DEFCON.ClientLevels or {}
    for _, levelData in ipairs(levels) do
        local id = math.floor(tonumber(levelData.ID) or -1)
        if id > 0 then GRN_DEFCON.ClientLevels[id] = levelData end
    end

    payload = {
        current = current,
        canChange = canChange,
        canManage = canManage,
        levels = levels,
        message = message,
        messageType = messageType
    }

    -- Nach erfolgreichem Speichern/Löschen den Editor-Zustand nachziehen
    if messageType == 1 then
        local saved = Draft.pending and GetLevel(Draft.pending)
        if saved and saved.Custom then
            LoadDraft(saved)
        elseif Draft.editing and not GetLevel(Draft.editing) then
            ResetDraft()
        end
    end
    Draft.pending = nil

    OpenTerminal()
end)

GRN_DEFCON.CloseTerminalMenu = CloseTerminal
