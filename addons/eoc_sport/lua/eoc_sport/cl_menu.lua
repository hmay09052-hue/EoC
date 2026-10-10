EoCSport = EoCSport or {}

local C = EoCSport.Config
local T = EoCSport.Theme

local frame

---------------------------------------------------------------------------
-- Bausteine
---------------------------------------------------------------------------
local function Label(parent, text, font, col)
    local l = vgui.Create("DLabel", parent)
    l:SetText(text)
    l:SetFont(font or "EoCSport_Head")
    l:SetTextColor(col or T.accent)
    l:SizeToContents()
    return l
end

local function Button(parent, text, onClick, danger)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Label = text
    b.DoClick = function(self)
        if self:GetDisabled() then return end
        surface.PlaySound("buttons/lightswitch2.wav")
        onClick(self)
    end
    b.Paint = function(self, w, h)
        local disabled = self:GetDisabled()
        local base = danger and T.red or T.accent
        if disabled then
            surface.SetDrawColor(T.panel2)
        elseif self:IsHovered() then
            surface.SetDrawColor(base)
        else
            surface.SetDrawColor(base.r, base.g, base.b, 40)
        end
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(disabled and T.line or base)
        surface.DrawOutlinedRect(0, 0, w, h)
        local col = disabled and T.muted or (self:IsHovered() and Color(15, 15, 15) or T.text)
        draw.SimpleText(self.Label, "EoCSport_Head", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return b
end

local function NumberField(parent, min, max, value)
    local n = vgui.Create("DNumberWang", parent)
    n:SetMinMax(min, max)
    n:SetDecimals(0)
    n:SetValue(value)
    n:SetFont("EoCSport_TextBold")
    n:SetTextColor(T.text)
    n:SetCursorColor(T.accent)
    n:SetPaintBackground(false)
    n.PaintOver = function(self, w, h)
        surface.SetDrawColor(T.line)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    n.Paint = function(self, w, h)
        surface.SetDrawColor(T.panel2)
        surface.DrawRect(0, 0, w, h)
        self:DrawTextEntryText(T.text, T.accent, T.text)
    end
    return n
end

local function GetNumber(field, min, max)
    return math.Clamp(math.floor(tonumber(field:GetValue()) or 0), min, max)
end

local function Combo(parent)
    local c = vgui.Create("DComboBox", parent)
    c:SetFont("EoCSport_Text")
    c:SetTextColor(T.text)
    c.Paint = function(self, w, h)
        surface.SetDrawColor(T.panel2)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(self:IsHovered() and T.accent or T.line)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
    return c
end

local function StartExercise(id, target, penalty)
    net.Start("EoCSport_Start")
    net.WriteString(id or "")
    net.WriteUInt(math.Clamp(target or 0, 0, 999), 16)
    net.WriteBool(penalty == true)
    net.SendToServer()
    if IsValid(frame) then frame:Close() end
end

local function GroupCmd(op, writer)
    net.Start("EoCSport_GroupCmd")
    net.WriteUInt(op, 4)
    if writer then writer() end
    net.SendToServer()
end

local function UnavailableReason(ex)
    if ex.needsBar and not IsValid(EoCSport.FindPullupBar(LocalPlayer())) then
        return "Keine Klimmzugstange in der Nähe"
    end
end

---------------------------------------------------------------------------
-- Reiter "Übungen"
---------------------------------------------------------------------------
local function BuildExercises(panel)
    local selected

    local pen = EoCSport.MyPenalty
    if pen and EoCSport.GetExercise(pen.id) then
        local ex = EoCSport.GetExercise(pen.id)
        local bar = vgui.Create("DPanel", panel)
        bar:Dock(TOP)
        bar:SetTall(48)
        bar:DockMargin(0, 0, 0, 10)
        bar.Paint = function(_, w, h)
            surface.SetDrawColor(T.accentDim)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(T.accent)
            surface.DrawRect(0, 0, 3, h)
            draw.SimpleText("STRAFRUNDE: " .. EoCSport.FormatCount(ex, pen.count) .. " " .. ex.name,
                "EoCSport_Head", 14, h / 2, T.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("von " .. pen.by, "EoCSport_Small", w - 150, h / 2, T.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        local go = Button(bar, "STARTEN", function() StartExercise(pen.id, pen.count, true) end)
        go:Dock(RIGHT)
        go:SetWide(130)
        go:DockMargin(8, 8, 8, 8)
    end

    local bottom = vgui.Create("DPanel", panel)
    bottom:Dock(BOTTOM)
    bottom:SetTall(44)
    bottom:DockMargin(0, 10, 0, 0)
    bottom.Paint = nil

    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    local sbar = scroll:GetVBar()
    sbar:SetWide(6)
    sbar.Paint = nil
    sbar.btnUp.Paint = nil
    sbar.btnDown.Paint = nil
    sbar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(T.accent) surface.DrawRect(0, 0, w, h) end

    local layout = vgui.Create("DIconLayout", scroll)
    layout:Dock(FILL)
    layout:SetSpaceX(10)
    layout:SetSpaceY(10)

    local targetLabel = Label(bottom, "ZIELWERT", "EoCSport_Head", T.muted)
    targetLabel:Dock(LEFT)
    targetLabel:DockMargin(0, 0, 10, 0)

    local target = NumberField(bottom, 0, 999, 0)
    target:Dock(LEFT)
    target:SetWide(80)
    target:DockMargin(0, 6, 10, 6)

    local hint = Label(bottom, "0 = frei zählen", "EoCSport_Small", T.muted)
    hint:Dock(LEFT)

    local startBtn = Button(bottom, "ÜBUNG STARTEN", function()
        if selected then StartExercise(selected, GetNumber(target, 0, 999)) end
    end)
    startBtn:Dock(RIGHT)
    startBtn:SetWide(200)
    startBtn:SetDisabled(true)

    local tileW = 268
    for _, ex in ipairs(EoCSport.GetExerciseList()) do
        local tile = layout:Add("DButton")
        tile:SetSize(tileW, 104)
        tile:SetText("")
        local reason = UnavailableReason(ex)
        local icon = ex.icon and Material(ex.icon, "smooth")

        tile.DoClick = function()
            if reason then return end
            selected = ex.id
            startBtn:SetDisabled(false)
            surface.PlaySound("buttons/lightswitch2.wav")
        end
        tile.DoDoubleClick = function()
            if reason then return end
            StartExercise(ex.id, GetNumber(target, 0, 999))
        end

        tile.Paint = function(self, w, h)
            local sel = selected == ex.id
            surface.SetDrawColor(self:IsHovered() and not reason and T.hover or T.panel2)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(sel and T.accent or T.line)
            surface.DrawOutlinedRect(0, 0, w, h, sel and 2 or 1)

            -- Vorschaubild
            local s = h - 24
            surface.SetDrawColor(T.bg)
            surface.DrawRect(12, 12, s, s)
            if icon and not icon:IsError() then
                surface.SetDrawColor(reason and Color(255, 255, 255, 60) or color_white)
                surface.SetMaterial(icon)
                surface.DrawTexturedRect(12, 12, s, s)
            else
                draw.SimpleText(ex.short or string.sub(ex.name, 1, 2), "EoCSport_Title", 12 + s / 2, 12 + s / 2,
                    reason and T.muted or T.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            local tx = 24 + s
            draw.SimpleText(string.upper(ex.name), "EoCSport_Head", tx, 10, reason and T.muted or T.text)
            local mode = ex.mode == "hold" and "Sekunden" or (string.format("%.1f s pro Wdh.", ex.duration))
            draw.SimpleText(mode, "EoCSport_Small", w - 10, 15, T.muted, TEXT_ALIGN_RIGHT)

            local lines = {}
            local text = reason or ex.desc or ""
            surface.SetFont("EoCSport_Small")
            local line = ""
            for word in string.gmatch(text, "%S+") do
                local test = line == "" and word or (line .. " " .. word)
                if surface.GetTextSize(test) > w - tx - 10 and line ~= "" then
                    lines[#lines + 1] = line
                    line = word
                else
                    line = test
                end
            end
            lines[#lines + 1] = line
            for i = 1, math.min(#lines, 3) do
                draw.SimpleText(lines[i], "EoCSport_Small", tx, 38 + (i - 1) * 16, reason and T.red or T.muted)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Reiter "Gruppe" (Ausbilder)
---------------------------------------------------------------------------
local function Section(parent, title)
    local l = Label(parent, title, "EoCSport_Head", T.accent)
    l:Dock(TOP)
    l:DockMargin(0, 8, 0, 4)
    return l
end

local function Row(parent, label, height)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(height or 30)
    row:DockMargin(0, 0, 0, 6)
    row.Paint = nil
    local l = Label(row, label, "EoCSport_Text", T.muted)
    l:Dock(LEFT)
    l:SetWide(90)
    return row
end

local function FillExercises(combo, filter)
    for i, ex in ipairs(EoCSport.GetExerciseList()) do
        if not filter or filter(ex) then combo:AddChoice(ex.name, ex.id, i == 1) end
    end
end

local function BuildGroup(panel)
    local left = vgui.Create("DPanel", panel)
    left:Dock(LEFT)
    left:SetWide(330)
    left:DockMargin(0, 0, 16, 0)
    left.Paint = nil

    local right = vgui.Create("DPanel", panel)
    right:Dock(FILL)
    right.Paint = function(_, w, h)
        surface.SetDrawColor(T.panel2)
        surface.DrawRect(0, 0, w, h)
    end

    -- Gruppentraining anlegen
    Section(left, "GRUPPENTRAINING")

    local exCombo = Combo(Row(left, "Übung"))
    exCombo:Dock(FILL)
    FillExercises(exCombo, function(ex) return ex.groupAllowed ~= false end)

    local targetField = NumberField(Row(left, "Zielwert"), 1, 999, 20)
    targetField:Dock(LEFT)
    targetField:SetWide(80)

    local radiusRow = Row(left, "Umkreis")
    local radius = vgui.Create("DNumSlider", radiusRow)
    radius:Dock(FILL)
    radius:SetMinMax(100, C.Group.MaxRadius)
    radius:SetDecimals(0)
    radius:SetValue(C.Group.DefaultRadius)
    radius:SetText("")
    radius.Label:SetWide(0)
    radius.TextArea:SetTextColor(T.text)

    local tempo = vgui.Create("DCheckBoxLabel", left)
    tempo:Dock(TOP)
    tempo:DockMargin(90, 0, 0, 8)
    tempo:SetText("Takt vorgeben (nur Wiederholungen)")
    tempo:SetFont("EoCSport_Small")
    tempo:SetTextColor(T.text)

    local create = Button(left, "GRUPPE STARTEN", function()
        local _, id = exCombo:GetSelected()
        if not id then return end
        GroupCmd(EoCSport.GC_CREATE, function()
            net.WriteString(id)
            net.WriteUInt(GetNumber(targetField, 1, 999), 16)
            net.WriteUInt(math.floor(radius:GetValue()), 16)
            net.WriteBool(tempo:GetChecked())
        end)
    end)
    create:Dock(TOP)
    create:SetTall(36)

    -- Strafrunde
    Section(left, "STRAFRUNDE")

    local plyCombo = Combo(Row(left, "Spieler"))
    plyCombo:Dock(FILL)
    local function fillPlayers()
        plyCombo:Clear()
        local lp = LocalPlayer()
        local list = {}
        for _, p in ipairs(player.GetAll()) do
            local d = p:GetPos():Distance(lp:GetPos())
            if p ~= lp and d <= C.Penalty.MaxRadius then list[#list + 1] = { p = p, d = d } end
        end
        table.sort(list, function(a, b) return a.d < b.d end)
        for _, e in ipairs(list) do
            plyCombo:AddChoice(EoCSport.GetName(e.p) .. "  (" .. math.floor(e.d) .. ")", e.p)
        end
    end
    fillPlayers()
    local openMenu = plyCombo.OpenMenu
    plyCombo.OpenMenu = function(self, ...)
        fillPlayers()
        return openMenu(self, ...)
    end

    local penCombo = Combo(Row(left, "Übung"))
    penCombo:Dock(FILL)
    FillExercises(penCombo, function(ex) return not ex.needsBar end)

    local penCount = NumberField(Row(left, "Anzahl"), 1, C.Penalty.MaxCount, 10)
    penCount:Dock(LEFT)
    penCount:SetWide(80)

    local give = Button(left, "STRAFRUNDE GEBEN", function()
        local _, target = plyCombo:GetSelected()
        local _, id = penCombo:GetSelected()
        if not IsValid(target) or not id then return end
        GroupCmd(EoCSport.GC_PENALTY, function()
            net.WriteEntity(target)
            net.WriteString(id)
            net.WriteUInt(GetNumber(penCount, 1, C.Penalty.MaxCount), 16)
        end)
    end)
    give:Dock(TOP)
    give:SetTall(36)

    local abortAll = Button(left, "ALLE IM UMKREIS ABBRECHEN", function()
        GroupCmd(EoCSport.GC_ABORT_ALL)
    end, true)
    abortAll:Dock(BOTTOM)
    abortAll:SetTall(36)

    -- Live-Liste
    local header = vgui.Create("DPanel", right)
    header:Dock(TOP)
    header:SetTall(44)
    header:DockMargin(12, 8, 12, 0)
    header.Paint = function(_, w, h)
        local g = EoCSport.LeaderGroup
        local title, sub = "KEIN GRUPPENTRAINING", "Links Übung und Ziel wählen und starten."
        if g then
            local ex = EoCSport.GetExercise(g.exId)
            title = string.upper(ex and ex.name or g.exId) .. " · ZIEL " .. g.target
            if g.state == "invite" then
                sub = "Aufforderung läuft · " .. math.max(0, math.ceil(g.inviteEnd - CurTime())) .. " s"
            elseif g.state == "countdown" then
                sub = "Countdown"
            else
                sub = "Läuft seit " .. EoCSport.FormatTime(CurTime() - g.startAt) .. (g.tempo and (" · Takt " .. g.beat) or "")
            end
        end
        draw.SimpleText(title, "EoCSport_Head", 0, 0, T.accent)
        draw.SimpleText(sub, "EoCSport_Small", 0, 26, T.muted)
    end

    local buttons = vgui.Create("DPanel", right)
    buttons:Dock(BOTTOM)
    buttons:SetTall(40)
    buttons:DockMargin(12, 0, 12, 12)
    buttons.Paint = nil

    local beat = Button(buttons, "TAKT: EINS!", function() GroupCmd(EoCSport.GC_BEAT) end)
    beat:Dock(LEFT)
    beat:SetWide(200)

    local cancel = Button(buttons, "GRUPPE ABBRECHEN", function() GroupCmd(EoCSport.GC_CANCEL) end, true)
    cancel:Dock(RIGHT)
    cancel:SetWide(200)

    local list = vgui.Create("DListView", right)
    list:Dock(FILL)
    list:DockMargin(12, 8, 12, 8)
    list:SetMultiSelect(false)
    list:AddColumn("Name")
    list:AddColumn("Zähler"):SetFixedWidth(70)
    list:AddColumn("Status"):SetFixedWidth(130)
    list:AddColumn("Zeit"):SetFixedWidth(70)
    list.Paint = function(_, w, h)
        surface.SetDrawColor(T.bg)
        surface.DrawRect(0, 0, w, h)
    end

    local lastSig
    right.Think = function()
        local g = EoCSport.LeaderGroup
        beat:SetDisabled(not (g and g.tempo and g.state == "running"))
        cancel:SetDisabled(not g)

        local parts = {}
        for _, e in ipairs(g and g.entries or {}) do
            parts[#parts + 1] = e.name .. e.count .. e.state
        end
        local sig = table.concat(parts, "|")
        if sig == lastSig then return end
        lastSig = sig

        list:Clear()
        for _, e in ipairs(g and g.entries or {}) do
            local line = list:AddLine(e.name, e.count, EoCSport.MemberStateNames[e.state] or e.state,
                e.state == "done" and EoCSport.FormatTime(e.doneTime) or "–")
            for _, col in pairs(line.Columns) do
                col:SetTextColor(e.state == "done" and T.green or T.text)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Fenster
---------------------------------------------------------------------------
function EoCSport.OpenMenu()
    if IsValid(frame) then frame:Remove() end

    local w, h = math.min(900, ScrW() - 40), math.min(620, ScrH() - 40)
    frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    frame:DockPadding(20, 76, 20, 20)
    frame.Paint = function(_, pw, ph)
        Derma_DrawBackgroundBlur(frame, frame.created)
        surface.SetDrawColor(T.panel)
        surface.DrawRect(0, 0, pw, ph)
        surface.SetDrawColor(T.accent)
        surface.DrawRect(0, 0, pw, 3)
        draw.SimpleText("EOC SPORT", "EoCSport_Title", 20, 14, T.text)
        surface.SetDrawColor(T.line)
        surface.DrawRect(20, 60, pw - 40, 1)
        draw.SimpleText("Echoes of Clones · Sportsystem", "EoCSport_Small", pw - 70, 26, T.muted, TEXT_ALIGN_RIGHT)
    end
    frame.created = SysTime()
    frame.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE then frame:Close() end
    end

    local close = vgui.Create("DButton", frame)
    close:SetText("")
    close:SetSize(36, 36)
    close:SetPos(w - 56, 14)
    close.DoClick = function() frame:Close() end
    close.Paint = function(self, cw, ch)
        surface.SetDrawColor(self:IsHovered() and T.red or T.panel2)
        surface.DrawRect(0, 0, cw, ch)
        draw.SimpleText("✕", "EoCSport_Head", cw / 2, ch / 2, T.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local tabs = {}
    local pages = {}
    local function addTab(name, build)
        local page = vgui.Create("DPanel", frame)
        page:Dock(FILL)
        page.Paint = nil
        page:SetVisible(false)
        build(page)
        pages[#pages + 1] = page

        local index = #pages
        local tab = vgui.Create("DButton", frame)
        tab:SetText("")
        tab:SetSize(130, 30)
        tab:SetPos(200 + (index - 1) * 140, 18)
        tab.DoClick = function()
            for i, p in ipairs(pages) do p:SetVisible(i == index) end
            frame.activeTab = index
        end
        tab.Paint = function(self, tw, th)
            local active = frame.activeTab == index
            draw.SimpleText(name, "EoCSport_Head", tw / 2, th / 2 - 2, active and T.accent or (self:IsHovered() and T.text or T.muted), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if active then
                surface.SetDrawColor(T.accent)
                surface.DrawRect(10, th - 2, tw - 20, 2)
            end
        end
        tabs[index] = tab
    end

    addTab("ÜBUNGEN", BuildExercises)
    if EoCSport.IsInstructor(LocalPlayer()) then
        addTab("GRUPPE", BuildGroup)
    end

    tabs[1]:DoClick()
end

net.Receive("EoCSport_Menu", function()
    EoCSport.OpenMenu()
end)
