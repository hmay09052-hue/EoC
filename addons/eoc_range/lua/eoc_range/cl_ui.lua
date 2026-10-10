--[[
    EoC Range – Oberfläche: Terminal, Auswertung, Ausbilder-Menü
    Reiter im Menü: Ranglisten · Bahnen · Prüfung · Disziplinen · Ergebnisse · Einstellungen
]]

local C = EoCRange.Config
local P = EoCRange.Colors

EoCRange.UI = EoCRange.UI or {}
local UI = EoCRange.UI

local T = {
    accent = P.yellow, text = P.text, white = P.white, dim = P.soft, muted = P.muted,
    bg = P.bg, panel = P.panel, panel2 = P.panel2, line = P.line, lineS = P.lineS,
    red = P.red, green = P.green, blue = P.blue, orange = P.orange,
}

local function Click() surface.PlaySound("buttons/lightswitch2.wav") end

---------------------------------------------------------------------------
-- Bausteine (Server-Design über SYMUI, ohne SymChars eigener flacher Stil)
---------------------------------------------------------------------------
function UI.StyleScroll(scroll)
    local bar = scroll:GetVBar()
    bar:SetWide(4)
    bar.Paint = function(_, w, h) surface.SetDrawColor(T.line) surface.DrawRect(0, 0, w, h) end
    bar.btnUp.Paint = function() end
    bar.btnDown.Paint = function() end
    bar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(T.accent) surface.DrawRect(0, 0, w, h) end
    return scroll
end

function UI.Scroll(parent)
    return UI.StyleScroll(vgui.Create("DScrollPanel", parent))
end

function UI.Frame(title, w, h, sub, status)
    local f = vgui.Create("DFrame")
    local W, H = math.min(w, ScrW() - 40), math.min(h, ScrH() - 40)
    f:SetSize(W, H)
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetDraggable(true)
    f:DockPadding(20, 80, 20, 20)
    f:MakePopup()
    f:SetAlpha(0)
    f:AlphaTo(255, 0.15)
    f.Paint = function(_, pw, ph)
        if SYMUI then
            local st, sc
            if status then st, sc = status() end
            SYMUI.PaintWindow(pw, ph, nil, { header = 64 })
            SYMUI.PaintEoCHeader(title, "SCHIESSSTAND // " .. string.upper(sub or ""), "EoCR_UITitle", "EoCR_UISub", T.accent, st, sc or T.dim)
            return
        end
        surface.SetDrawColor(T.bg)
        surface.DrawRect(0, 0, pw, ph)
        surface.SetDrawColor(T.panel2)
        surface.DrawRect(0, 0, pw, 62)
        surface.SetDrawColor(P.yellowD)
        surface.DrawRect(0, 62, pw, 1)
        surface.SetDrawColor(T.accent)
        surface.DrawRect(0, 62, 180, 2)
        surface.DrawRect(0, 0, 14, 2)
        surface.DrawRect(0, 0, 2, 14)
        surface.DrawRect(pw - 14, ph - 2, 14, 2)
        surface.DrawRect(pw - 2, ph - 14, 2, 14)
        draw.SimpleText(string.upper(title), "EoCR_UITitle", 20, 24, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local subW = draw.SimpleText("SCHIESSSTAND // " .. string.upper(sub or ""), "EoCR_UISub", 21, 46, T.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if status then
            local st, sc = status()
            if st then draw.SimpleText("//  " .. st, "EoCR_UISub", 21 + subW + 8, 46, sc or T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
        end
        draw.SimpleText("EOC RANGE", "EoCR_Aurebesh", pw - 70, ph - 14, ColorAlpha(T.accent, 70), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(T.line)
        surface.DrawOutlinedRect(0, 0, pw, ph, 1)
    end
    local close = UI.Button(f, "X", T.red, function() f:Close() end)
    close:SetSize(34, 34)
    close:SetPos(W - 48, 14)
    return f
end

-- Großgeschriebene Hauptaktionen werden gefüllt dargestellt
function UI.Button(parent, text, col, fn)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Label = text
    b.Accent = col or T.accent
    b.Solid = #text > 6 and text == string.upper(text) and col ~= T.dim
    b:SetTall(34)
    b.Paint = function(s, w, h)
        if SYMUI then
            local tc = SYMUI.PaintEoCButton(s, w, h, T.red)
            draw.SimpleText(s.Label, "EoCR_UIBold", w / 2, h / 2, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        local enabled = s:IsEnabled()
        local hov = s:IsHovered() and enabled
        local bg = s.Active and ColorAlpha(s.Accent, 26) or (hov and T.panel2 or T.panel)
        if s.Solid and enabled then bg = hov and s.Accent or ColorAlpha(s.Accent, 215) end
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor((s.Active or s.Solid) and enabled and ColorAlpha(s.Accent, 185) or (hov and T.lineS or T.line))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if not s.Solid and enabled then
            surface.SetDrawColor(ColorAlpha(s.Accent, hov and 255 or 150))
            surface.DrawRect(0, 0, 2, h)
        end
        if s.Active then
            surface.SetDrawColor(s.Accent)
            surface.DrawRect(0, h - 2, w, 2)
        end
        local tc = not enabled and T.muted or (s.Solid and T.bg or (s.Active and s.Accent or T.text))
        draw.SimpleText(s.Label, "EoCR_UIBold", w / 2, h / 2, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = function(s)
        Click()
        if fn then fn(s) end
    end
    return b
end

function UI.Label(parent, text, font, col)
    local l = vgui.Create("DLabel", parent)
    l:SetFont(font or "EoCR_UI")
    l:SetTextColor(col or T.text)
    l:SetText(text)
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    return l
end

function UI.Header(parent, text)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(26)
    p:DockMargin(0, 8, 0, 4)
    p.Paint = function(_, w, h)
        surface.SetDrawColor(T.accent)
        surface.DrawRect(0, 8, 2, h - 14)
        draw.SimpleText(string.upper(text), "EoCR_UISection", 10, h / 2 + 1, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    return p
end

function UI.Note(parent, text, col)
    local l = UI.Label(parent, text, "EoCR_UISmall", col or T.muted)
    l:Dock(TOP)
    l:DockMargin(4, 0, 4, 6)
    return l
end

function UI.TextEntry(parent, placeholder, value)
    local e = vgui.Create("DTextEntry", parent)
    e:SetFont("EoCR_UI")
    e:SetTall(30)
    e:SetPaintBackground(false)
    if value ~= nil then e:SetText(tostring(value)) end
    e.Paint = function(s, w, h)
        surface.SetDrawColor(T.panel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(s:HasFocus() and ColorAlpha(T.accent, 170) or T.line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if s:GetText() == "" and placeholder then
            draw.SimpleText(placeholder, "EoCR_UI", 6, h / 2, T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        s:DrawTextEntryText(T.text, ColorAlpha(T.accent, 70), T.accent)
    end
    return e
end

function UI.Combo(parent, options, selected, onSelect)
    local c = vgui.Create("DComboBox", parent)
    c:SetFont("EoCR_UI")
    c:SetTextColor(T.text)
    c:SetTall(30)
    c.Paint = function(s, w, h)
        surface.SetDrawColor(T.panel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor((s:IsHovered() or s:IsMenuOpen()) and ColorAlpha(T.accent, 170) or T.line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    for _, o in ipairs(options) do c:AddChoice(o[2], o[1], o[1] == selected) end
    c.OnSelect = function(_, _, _, data) if onSelect then onSelect(data) end end
    return c
end

function UI.Check(parent, text, value)
    local c = vgui.Create("DCheckBoxLabel", parent)
    c:SetText(text)
    c:SetFont("EoCR_UI")
    c:SetTextColor(T.text)
    c:SetValue(value and 1 or 0)
    c.Button.Paint = function(s, w, h)
        surface.SetDrawColor(T.panel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(s:GetChecked() and T.accent or T.line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if s:GetChecked() then
            surface.SetDrawColor(T.accent)
            surface.DrawRect(3, 3, w - 6, h - 6)
        end
    end
    return c
end

-- Reiterleiste; tabs = { { id, name, build(panel) }, ... }
function UI.Tabs(parent, tabs, active)
    local bar = vgui.Create("DPanel", parent)
    bar:Dock(TOP)
    bar:SetTall(34)
    bar:DockMargin(0, 0, 0, 10)
    bar.Paint = nil
    local content = vgui.Create("DPanel", parent)
    content:Dock(FILL)
    content.Paint = nil
    local buttons = {}
    local api = { content = content }

    function api.Select(id)
        if not IsValid(content) then return end
        content:Clear()
        api.active = id
        for _, b in ipairs(buttons) do b.Active = b.TabId == id end
        for _, t in ipairs(tabs) do
            if t.id == id then t.build(content) end
        end
    end

    surface.SetFont("EoCR_UIBold")
    for _, t in ipairs(tabs) do
        local b = UI.Button(bar, t.name, nil, function() api.Select(t.id) end)
        b.Solid = false
        b.TabId = t.id
        b:Dock(LEFT)
        b:DockMargin(0, 0, 6, 0)
        b:SetWide(surface.GetTextSize(t.name) + 34)
        buttons[#buttons + 1] = b
    end
    local found = false
    for _, t in ipairs(tabs) do if t.id == active then found = true end end
    api.Select(found and active or tabs[1].id)
    return api
end

-- Zeile in einer Liste
function UI.Row(parent, tall, paint)
    local r = vgui.Create("DPanel", parent)
    r:Dock(TOP)
    r:SetTall(tall or 34)
    r:DockMargin(0, 0, 0, 3)
    r.Paint = function(s, w, h)
        surface.SetDrawColor(s:IsHovered() and T.panel2 or T.panel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(T.line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if paint then paint(s, w, h) end
    end
    return r
end

local function Ask(title, text, cb)
    Derma_StringRequest(title, text, "", function(v) cb(v) end, nil, "OK", "Abbrechen")
end

local function DateText(t)
    return os.date("%d.%m.%Y %H:%M", tonumber(t) or 0)
end

local function DiscOptions(withAll)
    local out = {}
    if withAll then out[#out + 1] = { "", "Alle Disziplinen" } end
    for _, d in ipairs(EoCRange.AllDisciplines()) do out[#out + 1] = { d.id, d.name } end
    return out
end

---------------------------------------------------------------------------
-- Trefferbild (2D)
---------------------------------------------------------------------------
function UI.DrawHitPicture(x, y, size, result)
    local holes = result.holes or {}
    if result.mode == "rings" then
        local cx, cy, R = x + size / 2, y + size / 2, size / 2 - 6
        surface.SetDrawColor(226, 222, 208)
        surface.DrawRect(x, y, size, size)
        for ring = 1, 10 do
            local r = math.floor(R * (11 - ring) / 10)
            local dark = ring >= 7
            EoCRange.FillCircle(cx, cy, r, dark and Color(24, 26, 30) or Color(226, 222, 208), 40)
            surface.DrawCircle(cx, cy, r, dark and 200 or 40, dark and 200 or 40, dark and 200 or 40, 255)
        end
        for _, h in ipairs(holes) do
            local hx, hy = cx + h.u * R, cy - h.v * R
            EoCRange.FillCircle(math.floor(hx), math.floor(hy), 5, P.yellow, 10)
            EoCRange.FillCircle(math.floor(hx), math.floor(hy), 3, Color(10, 10, 10), 10)
        end
        return
    end

    -- Silhouette mit allen Treffern (häufigste Silhouette des Laufs)
    local count = {}
    for _, h in ipairs(holes) do count[h.s or 1] = (count[h.s or 1] or 0) + 1 end
    local best, sIdx = 0, 1
    for k, n in pairs(count) do if n > best then best, sIdx = n, k end end
    local sdef = EoCRange.SilhouetteDef(sIdx)
    local shape = EoCRange.Shapes[sdef.id] or EoCRange.Shapes.b1
    surface.SetDrawColor(T.panel2)
    surface.DrawRect(x, y, size, size)
    local k = (size - 20) / sdef.h
    local ox, oy = x + size / 2, y + size - 10
    surface.SetDrawColor(shape.col)
    for _, r in ipairs(shape.rects) do
        surface.DrawRect(ox + r[1] * k, oy - (r[2] + r[4]) * k, r[3] * k, r[4] * k)
    end
    surface.SetDrawColor(255, 255, 255, 40)
    surface.DrawRect(ox - sdef.w / 2 * k, oy - sdef.h * C.HeadZone * k, sdef.w * k, 1)
    for _, h in ipairs(holes) do
        local hx, hy = ox + h.u * (sdef.w / 2) * k, oy - h.v * sdef.h * k
        EoCRange.FillCircle(math.floor(hx), math.floor(hy), 4, h.h == 1 and P.red or P.yellow, 10)
    end
end

---------------------------------------------------------------------------
-- Auswertung nach jedem Lauf
---------------------------------------------------------------------------
local resultFrame

function UI.OpenResult(d)
    if IsValid(resultFrame) then resultFrame:Remove() end
    local def = EoCRange.GetDiscipline(d.disc)
    local f = UI.Frame("Auswertung", 760, 560, d.name or "Lauf")
    resultFrame = f

    local left = vgui.Create("DPanel", f)
    left:Dock(LEFT)
    left:SetWide(330)
    left:DockMargin(0, 0, 16, 0)
    left.Paint = function(_, w, h)
        UI.DrawHitPicture(0, 0, w, d)
        draw.SimpleText("TREFFERBILD", "EoCR_UISub", 4, w + 12, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if d.mode ~= "rings" then
            draw.SimpleText("rot = Kopfzone", "EoCR_UISmall", w - 4, w + 12, T.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    local right = vgui.Create("DPanel", f)
    right:Dock(FILL)
    right.Paint = function(_, w, h)
        local y = 0
        draw.SimpleText("ERGEBNIS", "EoCR_UISub", 0, y, T.dim)
        draw.SimpleText(tostring(d.valueText or "–"), "EoCR_UIBig", 0, y + 12, d.flagged and T.orange or T.accent)
        if d.isPB then draw.SimpleText("NEUE BESTLEISTUNG", "EoCR_UIBold", w, y + 30, T.green, TEXT_ALIGN_RIGHT) end
        y = y + 92

        local function Line(label, value, col)
            draw.SimpleText(label, "EoCR_UI", 0, y, T.dim)
            draw.SimpleText(value, "EoCR_UI", w, y, col or T.text, TEXT_ALIGN_RIGHT)
            surface.SetDrawColor(T.line)
            surface.DrawRect(0, y + 24, w, 1)
            y = y + 30
        end

        Line("Platz in " .. (d.unitName or "der Einheit"), d.flagged and "ungeprüft" or ("#" .. tostring(d.unitRank or "–")))
        Line("Platz auf dem Server", d.flagged and "ungeprüft" or ("#" .. tostring(d.serverRank or "–")))
        Line("Treffer", tostring(d.hits or 0) .. (d.total and d.total > 0 and (" / " .. d.total) or ""))
        Line("Trefferquote", string.format("%.1f %%", d.accuracy or 0) .. "  (" .. (d.shotHits or 0) .. " von " .. (d.shots or 0) .. " Schüssen)")
        if d.react then Line("Ø Reaktionszeit", string.format("%d ms", math.Round(d.react * 1000))) end
        if d.rawTime then Line("Reine Laufzeit", string.format("%.2f s", d.rawTime)) end
        if d.multiplier then Line("Stufe / Multiplikator", tostring(d.stage) .. " / x" .. d.multiplier) end
        for _, p in ipairs(d.penalties or {}) do Line("Strafe", p, T.red) end
        Line("Eigene Bestleistung (vorher)", EoCRange.Format(def, d.pb), d.isPB and T.green or T.text)
        Line("Bahnrekord", EoCRange.Format(def, d.laneRecord) .. (d.isLaneRecord and "  – NEU" or ""), d.isLaneRecord and T.green or T.text)
        Line("Serverrekord", EoCRange.Format(def, d.serverRecord))
        if d.flagged then
            draw.SimpleText("Reaktionszeit unter " .. C.ReactionMinMs .. " ms – Wertung erst nach Prüfung durch einen Admin.", "EoCR_UISmall", 0, y + 6, T.orange)
        elseif d.exam then
            draw.SimpleText("Prüfungslauf – der Ausbilder bestätigt oder verwirft das Ergebnis.", "EoCR_UISmall", 0, y + 6, T.blue)
        end
    end

    local close = UI.Button(f, "SCHLIESSEN", T.accent, function() f:Close() end)
    close:SetSize(160, 34)
    close:SetPos(f:GetWide() - 180, f:GetTall() - 54)
    timer.Simple(0, function()
        if IsValid(f) then f:SetMouseInputEnabled(true) end
    end)
end

EoCRange.Receive("rundetail", function(r)
    local data = istable(r.data) and r.data or {}
    local def = EoCRange.GetDiscipline(r.discipline)
    UI.OpenResult({
        disc = r.discipline, name = (def and def.name or r.discipline) .. " · " .. tostring(r.name), mode = def and def.mode or "rings",
        valueText = EoCRange.Format(def, r.score), holes = data.holes or {}, hits = r.hits, total = data.total, accuracy = r.accuracy,
        shots = r.shots, shotHits = data.shotHits, react = (r.react or 0) > 0 and r.react or nil, penalties = data.penalties,
        flagged = r.flagged == 1, unitName = r.unit_name, unitRank = "–", serverRank = "–",
    })
end)

---------------------------------------------------------------------------
-- Ranglisten-Ansicht (Terminal und Menü)
---------------------------------------------------------------------------
local boardTarget

EoCRange.Receive("boardreply", function(d)
    if boardTarget and IsValid(boardTarget.panel) then boardTarget.fill(d) end
end)

local function BuildBoardView(parent, discId, showOverall)
    local top = vgui.Create("DPanel", parent)
    top:Dock(TOP)
    top:SetTall(30)
    top:DockMargin(0, 0, 0, 8)
    top.Paint = nil

    local state = { disc = discId or EoCRange.DisciplineOrder[1], period = "all", unit = false }
    local list = UI.Scroll(parent)
    list:Dock(FILL)

    local function Fill(d)
        list:Clear()
        local def = EoCRange.GetDiscipline(d.disc)
        local rows = d.list or {}
        if #rows == 0 then UI.Note(list, "Noch keine Ergebnisse in diesem Zeitraum.") end
        for i, r in ipairs(rows) do
            UI.Row(list, 32, function(_, w, h)
                local col = i == 1 and T.accent or (i <= 3 and T.white or T.text)
                draw.SimpleText(i .. ".", "EoCR_UIBold", 12, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(r.n), "EoCR_UI", 50, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(r.un or ""), "EoCR_UISmall", w * 0.58, h / 2, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(EoCRange.Format(def, r.s), "EoCR_UIBold", w - 12, h / 2, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end)
        end
        if not d.unit and d.units and #d.units > 0 then
            UI.Header(list, "Einheitenwertung (Woche, Ø der besten " .. C.UnitScoreTop .. ")")
            for i, u in ipairs(d.units) do
                UI.Row(list, 30, function(_, w, h)
                    surface.SetDrawColor(EoCRange.UnitColor(u.u))
                    surface.DrawRect(8, 7, 4, h - 14)
                    draw.SimpleText(i .. ". " .. tostring(u.un), "EoCR_UI", 22, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(EoCRange.Format(def, u.v) .. "  ·  " .. (u.n or 0) .. " Schützen", "EoCR_UISmall", w - 12, h / 2, i == 1 and T.accent or T.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end)
            end
        end
        if showOverall then
            UI.Header(list, "Gesamtwertung der Einheiten (Woche)")
            local trophy = GetGlobal2String("EoCR_TrophyName", "")
            UI.Note(list, "Wochenpokal: " .. (trophy ~= "" and trophy or "noch nicht vergeben") .. " · Reset jeden Montag 04:00 Uhr", T.accent)
            for i, u in ipairs(EoCRange.ClientOverall or {}) do
                UI.Row(list, 30, function(_, w, h)
                    draw.SimpleText(i .. ". " .. tostring(u.un), "EoCR_UI", 14, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(tostring(u.v) .. " Pkt.", "EoCR_UIBold", w - 12, h / 2, i == 1 and T.accent or T.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end)
            end
        end
    end
    boardTarget = { panel = list, fill = Fill }

    local function Request()
        EoCRange.Send("board", { disc = state.disc, period = state.period, unit = state.unit })
    end

    local combo = UI.Combo(top, DiscOptions(false), state.disc, function(v)
        state.disc = v
        Request()
    end)
    combo:Dock(LEFT)
    combo:SetWide(220)
    combo:DockMargin(0, 0, 10, 0)

    local periodButtons = {}
    local function Period(id, label, unit)
        local b = UI.Button(top, label, nil, function(self)
            state.period, state.unit = id, unit
            for _, o in ipairs(periodButtons) do o.Active = o == self end
            Request()
        end)
        b.Solid = false
        b:Dock(LEFT)
        b:SetWide(110)
        b:DockMargin(0, 0, 6, 0)
        periodButtons[#periodButtons + 1] = b
        return b
    end
    Period("all", "Allzeit", false).Active = true
    Period("month", "Monat", false)
    Period("week", "Woche", false)
    Period("all", "Meine Einheit", true)
    Request()
end
UI.BuildBoardView = BuildBoardView

---------------------------------------------------------------------------
-- Persönliche Werte
---------------------------------------------------------------------------
local personalTarget

EoCRange.Receive("personal", function(d)
    if personalTarget and IsValid(personalTarget) then personalTarget.Fill(d) end
end)

local function BuildPersonal(parent)
    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)
    personalTarget = scroll
    UI.Note(scroll, "Lade …")
    function scroll.Fill(d)
        scroll:Clear()
        local lvl = d.badge or 0
        UI.Header(scroll, "Schützenabzeichen")
        UI.Row(scroll, 40, function(_, w, h)
            local col = lvl > 0 and C.BadgeColors[lvl] or T.dim
            draw.SimpleText(EoCRange.BadgeName(lvl), "EoCR_UIMed", 12, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(d.name or ""), "EoCR_UISmall", w - 12, h / 2, T.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end)

        UI.Header(scroll, "Bestwerte")
        local best = {}
        local week, month = EoCRange.WeekKey(), EoCRange.MonthKey()
        for _, r in ipairs(d.bests or {}) do
            best[r.discipline] = best[r.discipline] or {}
            local k = r.period == "all" and "all" or (r.period == week and "week" or (r.period == month and "month" or nil))
            if k then best[r.discipline][k] = r.score end
        end
        UI.Row(scroll, 26, function(_, w, h)
            draw.SimpleText("DISZIPLIN", "EoCR_UISub", 12, h / 2, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("ALLZEIT", "EoCR_UISub", w * 0.55, h / 2, T.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("MONAT", "EoCR_UISub", w * 0.72, h / 2, T.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("WOCHE", "EoCR_UISub", w * 0.89, h / 2, T.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end)
        for _, def in ipairs(EoCRange.AllDisciplines()) do
            local b = best[def.id] or {}
            UI.Row(scroll, 30, function(_, w, h)
                draw.SimpleText(def.name, "EoCR_UI", 12, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(EoCRange.Format(def, b.all), "EoCR_UIBold", w * 0.55, h / 2, b.all and T.accent or T.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(EoCRange.Format(def, b.month), "EoCR_UI", w * 0.72, h / 2, T.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(EoCRange.Format(def, b.week), "EoCR_UI", w * 0.89, h / 2, T.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end)
        end

        UI.Header(scroll, "Letzte Läufe (anklicken für Trefferbild)")
        for _, r in ipairs(d.runs or {}) do
            local def = EoCRange.GetDiscipline(r.discipline)
            local row = UI.Row(scroll, 30, function(_, w, h)
                draw.SimpleText(DateText(r.created), "EoCR_UISmall", 12, h / 2, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(def and def.name or r.discipline, "EoCR_UI", 140, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                local tag = r.flagged == 1 and "ungeprüft" or (r.flagged == 2 and "zurückgesetzt" or (r.exam == 1 and "Prüfung" or ""))
                draw.SimpleText(tag, "EoCR_UISmall", w * 0.62, h / 2, r.flagged == 1 and T.orange or T.blue, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(EoCRange.Format(def, r.score), "EoCR_UIBold", w - 12, h / 2, T.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end)
            row:SetCursor("hand")
            row.OnMousePressed = function() EoCRange.Send("rundetail", { id = r.id }) end
        end

        if #(d.badges or {}) > 0 then
            UI.Header(scroll, "Abzeichen-Verlauf")
            for _, b in ipairs(d.badges) do
                UI.Row(scroll, 30, function(_, w, h)
                    draw.SimpleText(DateText(b.created), "EoCR_UISmall", 12, h / 2, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(EoCRange.BadgeName(b.level), "EoCR_UI", 140, h / 2, b.revoked == 1 and T.muted or C.BadgeColors[b.level], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local txt = b.revoked == 1 and ("entzogen: " .. tostring(b.reason)) or ("Prüfer: " .. tostring(b.instructor))
                    draw.SimpleText(txt, "EoCR_UISmall", w - 12, h / 2, b.revoked == 1 and T.red or T.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end)
            end
        end
    end
    EoCRange.Send("personal", {})
end

---------------------------------------------------------------------------
-- Terminal
---------------------------------------------------------------------------
local terminalFrame

local function BuildRunTab(parent, d, frame)
    local selected
    local stage = 1

    local list = UI.Scroll(parent)
    list:Dock(LEFT)
    list:SetWide(300)
    list:DockMargin(0, 0, 14, 0)

    local detail = vgui.Create("DPanel", parent)
    detail:Dock(FILL)
    detail.Paint = nil

    local function ShowDetail(def)
        detail:Clear()
        selected = def
        if not def then return end
        local bests = (d.bests or {})[def.id] or {}

        local info = vgui.Create("DPanel", detail)
        info:Dock(TOP)
        info:SetTall(250)
        info.Paint = function(_, w, h)
            draw.SimpleText(string.upper(def.name), "EoCR_UIMed", 0, 0, T.white)
            draw.SimpleText(EoCRange.ModeName(def) .. "  ·  " .. (def.scoring == "time" and "Wertung nach Zeit (weniger ist besser)" or "Wertung nach Punkten"), "EoCR_UISmall", 0, 36, T.accent)
            local y = 64
            for _, line in ipairs(string.Explode("\n", def.desc or "")) do
                draw.DrawText(line, "EoCR_UI", 0, y, T.text)
                y = y + 22
            end
            y = y + 8
            draw.SimpleText("Erlaubte Waffen: " .. EoCRange.WeaponNames(def), "EoCR_UISmall", 0, y, T.dim)
            y = y + 30
            draw.SimpleText("Bestleistung", "EoCR_UISub", 0, y, T.dim)
            draw.SimpleText("Allzeit " .. EoCRange.Format(def, bests.all) .. "   ·   Monat " .. EoCRange.Format(def, bests.month) .. "   ·   Woche " .. EoCRange.Format(def, bests.week), "EoCR_UI", 0, y + 16, T.text)
            if C.Thresholds[def.id] then
                y = y + 50
                draw.SimpleText("Abzeichen-Schwellen", "EoCR_UISub", 0, y, T.dim)
                local parts = {}
                for lvl = 1, 3 do parts[#parts + 1] = C.BadgeNames[lvl] .. " " .. EoCRange.ThresholdText(def.id, lvl) end
                draw.SimpleText(table.concat(parts, "  ·  "), "EoCR_UISmall", 0, y + 16, T.text)
            end
        end

        if def.stages then
            UI.Header(detail, "Stufe")
            local row = vgui.Create("DPanel", detail)
            row:Dock(TOP)
            row:SetTall(34)
            row.Paint = nil
            local buttons = {}
            for i = 1, 3 do
                local b = UI.Button(row, "Stufe " .. i .. "  (x" .. C.MoverMultipliers[i] .. ")", nil, function(s)
                    stage = i
                    for _, o in ipairs(buttons) do o.Active = o == s end
                end)
                b.Solid = false
                b:Dock(LEFT)
                b:SetWide(150)
                b:DockMargin(0, 0, 6, 0)
                b.Active = i == stage
                buttons[i] = b
            end
        end
        if def.squad then
            UI.Note(detail, "Squad-Lauf: alle Mitglieder deines Squads (" .. C.SquadMin .. "–" .. C.SquadMax .. ") müssen in der Bahnzone stehen und eine erlaubte Waffe halten.", T.blue)
        end
        if def.mode == "parcours" then
            UI.Note(detail, "Stell dich in die Startzone. Die Zeit läuft ab dem Verlassen der Startzone und stoppt in der Zielzone.", T.blue)
        end

        local bottom = vgui.Create("DPanel", detail)
        bottom:Dock(BOTTOM)
        bottom:SetTall(40)
        bottom.Paint = nil
        local blocked = d.defcon and ("DEFCON " .. d.defcon .. " – Gefechtsbereitschaft") or (d.locked and ("Bahn gesperrt " .. d.locked))
            or (d.exam and "Prüfung läuft") or (d.busy and "Bahn belegt")
        local start = UI.Button(bottom, "LAUF STARTEN", T.accent, function()
            EoCRange.Send("start", { ent = d.ent, disc = def.id, stage = stage })
            frame:Close()
        end)
        start:Dock(RIGHT)
        start:SetWide(220)
        if blocked then
            start:SetEnabled(false)
            local l = UI.Label(bottom, blocked, "EoCR_UIBold", T.red)
            l:Dock(FILL)
            l:SetContentAlignment(4)
        end
        if EoCRange.ClientRun() then
            local abort = UI.Button(bottom, "Lauf abbrechen", T.red, function()
                EoCRange.Send("abort", {})
                frame:Close()
            end)
            abort:Dock(LEFT)
            abort:SetWide(160)
        end
    end

    local first
    for _, id in ipairs(d.allowed or {}) do
        local def = EoCRange.GetDiscipline(id)
        if def then
            local b = UI.Row(list, 52, function(s, w, h)
                if selected == def then
                    surface.SetDrawColor(T.accent)
                    surface.DrawRect(0, 0, 3, h)
                end
                draw.SimpleText(def.name, "EoCR_UIBold", 12, 16, selected == def and T.accent or T.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                local b = ((d.bests or {})[def.id] or {}).all
                draw.SimpleText(def.custom and "Eigene Disziplin" or EoCRange.ModeName(def), "EoCR_UISmall", 12, 36, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(b and EoCRange.Format(def, b) or "", "EoCR_UIBold", w - 12, h / 2, T.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end)
            b:SetCursor("hand")
            b.OnMousePressed = function() ShowDetail(def) end
            first = first or def
        end
    end
    ShowDetail(first)
end

EoCRange.Receive("terminal", function(d)
    if IsValid(terminalFrame) then terminalFrame:Remove() end
    local f = UI.Frame("Bahn " .. tostring(d.lane), 900, 620, "Terminal", function()
        if d.defcon then return "DEFCON " .. d.defcon .. " – GESPERRT", T.red end
        if d.locked then return "GESPERRT", T.red end
        if d.exam then return "PRÜFUNG", T.orange end
        if d.busy then return "BELEGT", T.accent end
        if d.reserved then return "RESERVIERT – " .. d.reserved, T.blue end
        return "FREI", T.green
    end)
    terminalFrame = f

    local tabs = {
        { id = "run", name = "Lauf", build = function(p) BuildRunTab(p, d, f) end },
        { id = "board", name = "Rangliste", build = function(p) BuildBoardView(p, d.allowed and d.allowed[1]) end },
        { id = "personal", name = "Persönlich", build = BuildPersonal },
    }
    if d.instructor then
        tabs[#tabs + 1] = { id = "instructor", name = "Ausbilder", build = function(p)
            UI.Note(p, "Prüfungen, Bahnen und eigene Disziplinen verwaltest du im Ausbilder-Menü (!range).")
            local b = UI.Button(p, "AUSBILDER-MENÜ ÖFFNEN", T.accent, function()
                f:Close()
                EoCRange.Send("menu", { tab = "exam" })
            end)
            b:Dock(TOP)
            b:SetTall(40)
        end }
    end
    UI.Tabs(f, tabs, "run")
end)

---------------------------------------------------------------------------
-- Ausbilder-Menü
---------------------------------------------------------------------------
local menuFrame, menuTabs
EoCRange.MenuData = EoCRange.MenuData or {}

-- Bahnen
local function BuildLanes(parent)
    local d = EoCRange.MenuData
    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)
    if #(d.lanes or {}) == 0 then UI.Note(scroll, "Auf dieser Map steht noch kein Bahn-Terminal (Spawnmenü → Entities → EoC Range).") end
    for _, l in ipairs(d.lanes or {}) do
        local row = UI.Row(scroll, 64, function(_, w, h)
            draw.SimpleText("BAHN " .. l.lane, "EoCR_UIMed", 14, 20, T.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local state, col = "frei", T.green
            if l.locked then state, col = "gesperrt" .. (l.lockReason ~= "" and (" – " .. l.lockReason) or "") .. " (" .. l.lockedBy .. ")", T.red
            elseif l.exam ~= "" then state, col = "Prüfung – " .. l.exam, T.orange
            elseif l.reserved ~= "" then state, col = "reserviert – " .. l.reserved, T.blue end
            draw.SimpleText(state, "EoCR_UI", 14, 46, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if l.busy ~= "" then draw.SimpleText("Lauf: " .. l.busy, "EoCR_UISmall", 260, 20, T.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
            if l.disciplines ~= "" then draw.SimpleText("Disziplinen: " .. l.disciplines, "EoCR_UISmall", 260, 46, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
        end)
        local function Btn(text, col, fn)
            local b = UI.Button(row, text, col, fn)
            b.Solid = false
            b:Dock(RIGHT)
            b:SetWide(120)
            b:DockMargin(4, 14, 0, 14)
        end
        if l.busy ~= "" then
            Btn("Abbrechen", T.red, function() EoCRange.Send("lane", { lane = l.lane, action = "abort" }) end)
        end
        if l.locked then
            Btn("Entsperren", T.green, function() EoCRange.Send("lane", { lane = l.lane, action = "unlock" }) end)
        else
            Btn("Sperren", T.red, function()
                Ask("Bahn " .. l.lane .. " sperren", "Grund (optional):", function(v) EoCRange.Send("lane", { lane = l.lane, action = "lock", reason = v }) end)
            end)
        end
        if l.reserved ~= "" then
            Btn("Freigeben", T.blue, function() EoCRange.Send("lane", { lane = l.lane, action = "release" }) end)
        else
            Btn("Reservieren", T.blue, function() EoCRange.Send("lane", { lane = l.lane, action = "reserve" }) end)
        end
    end
    if d.role and d.role.superadmin then
        UI.Header(scroll, "Einrichtung (Superadmin)")
        UI.Note(scroll, "Entities über das Spawnmenü (Entities → EoC Range) platzieren, Bahn-Nr. per Rechtsklick → Eigenschaften bearbeiten. "
            .. "Zonen mit der Toolgun „EoC Range – Zone“ aufziehen. Speichern pro Map: range_save · neu laden: range_load · entfernen: range_clear.")
        local b = UI.Button(scroll, "ENTITIES SPEICHERN (" .. string.upper(d.map or "") .. ")", T.accent, function() EoCRange.Send("save_entities", {}) end)
        b:Dock(TOP)
        b:SetTall(38)
    end
end

-- Prüfung
local function CellColor(cell)
    if not cell then return T.muted end
    if cell.status == "confirmed" then return T.green end
    if cell.status == "done" then return T.accent end
    if cell.status == "live" then return T.blue end
    if cell.status == "aborted" then return T.red end
    return T.muted
end

local function BuildExam(parent)
    local d = EoCRange.MenuData
    local exam = d.exam

    if not exam then
        UI.Header(parent, "Neue Prüfung")
        UI.Note(parent, "Die Kandidaten schießen nacheinander " .. #C.ExamDisciplines .. " Disziplinen. Du siehst die Ergebnisse live und bestätigst oder verwirfst jeden Lauf. "
            .. "Für eine Stufe müssen alle Disziplinen in derselben Prüfung erreicht werden.")
        local top = vgui.Create("DPanel", parent)
        top:Dock(TOP)
        top:SetTall(30)
        top:DockMargin(0, 4, 0, 8)
        top.Paint = nil
        local laneOpts, laneSel = {}, nil
        for _, l in ipairs(d.lanes or {}) do
            laneOpts[#laneOpts + 1] = { l.lane, "Bahn " .. l.lane }
            laneSel = laneSel or l.lane
        end
        local lane = laneSel
        local combo = UI.Combo(top, laneOpts, laneSel, function(v) lane = v end)
        combo:Dock(LEFT)
        combo:SetWide(160)

        local chosen = {}
        UI.Header(parent, "Kandidaten")
        local scroll = UI.Scroll(parent)
        scroll:Dock(FILL)
        for _, p in ipairs(d.players or {}) do
            if p.uid ~= LocalPlayer():UserID() then
                local row = UI.Row(scroll, 30, function(_, w, h)
                    draw.SimpleText(p.unit or "", "EoCR_UISmall", w * 0.55, h / 2, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(EoCRange.BadgeName(p.badge or 0), "EoCR_UISmall", w - 12, h / 2, (p.badge or 0) > 0 and C.BadgeColors[p.badge] or T.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end)
                local cb = UI.Check(row, p.name, false)
                cb:Dock(LEFT)
                cb:SetWide(320)
                cb:DockMargin(10, 7, 0, 7)
                cb.OnChange = function(_, v) chosen[p.uid] = v or nil end
            end
        end
        local go = UI.Button(parent, "PRÜFUNG STARTEN", T.accent, function()
            local list = {}
            for uid in pairs(chosen) do list[#list + 1] = uid end
            EoCRange.Send("exam_start", { lane = lane, candidates = list })
        end)
        go:Dock(BOTTOM)
        go:SetTall(40)
        go:DockMargin(0, 8, 0, 0)
        return
    end

    -- laufende Prüfung
    local head = vgui.Create("DPanel", parent)
    head:Dock(TOP)
    head:SetTall(60)
    head.Paint = function(_, w, h)
        draw.SimpleText("PRÜFUNG AUF BAHN " .. exam.lane, "EoCR_UIMed", 0, 14, T.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local parts = {}
        for _, disc in ipairs(exam.disciplines) do
            local def = EoCRange.GetDiscipline(disc)
            parts[#parts + 1] = (def and def.short or disc) .. ": " .. EoCRange.ThresholdText(disc, 1) .. " / " .. EoCRange.ThresholdText(disc, 2) .. " / " .. EoCRange.ThresholdText(disc, 3)
        end
        draw.SimpleText("Schwellen (Schütze / Scharfschütze / Meisterschütze)  –  " .. table.concat(parts, "  ·  "), "EoCR_UISmall", 0, 44, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)
    local nameW = 200
    for _, cand in ipairs(exam.candidates) do
        local row = UI.Row(scroll, 92, function(_, w, h)
            draw.SimpleText(cand.name, "EoCR_UIBold", 12, 20, cand.online and T.white or T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText((cand.unit or "") .. "  ·  " .. EoCRange.BadgeName(cand.badge or 0), "EoCR_UISmall", 12, 42, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            -- erreichbare Stufe
            local lvl, complete = 3, true
            for _, disc in ipairs(exam.disciplines) do
                local c = cand.results[disc]
                if not c or c.status ~= "confirmed" then complete = false else lvl = math.min(lvl, c.level or 0) end
            end
            local txt = complete and (lvl > 0 and ("Bestanden: " .. EoCRange.BadgeName(lvl)) or "Nicht bestanden") or "offen"
            draw.SimpleText(txt, "EoCR_UISmall", 12, 66, complete and (lvl > 0 and T.green or T.red) or T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end)
        local cells = vgui.Create("DPanel", row)
        cells:Dock(FILL)
        cells:DockMargin(nameW, 6, 6, 6)
        cells.Paint = nil
        local count = #exam.disciplines
        cells.PerformLayout = function(s, w)
            local cw = math.floor((w - (count - 1) * 6) / count)
            for _, child in ipairs(s:GetChildren()) do
                if child:GetWide() ~= cw then child:SetWide(cw) end
            end
        end
        for _, disc in ipairs(exam.disciplines) do
            local def = EoCRange.GetDiscipline(disc)
            local cell = cand.results[disc]
            local box = vgui.Create("DPanel", cells)
            box:Dock(LEFT)
            box:DockMargin(0, 0, 6, 0)
            box:SetWide(150)
            box.Paint = function(_, w, h)
                surface.SetDrawColor(T.panel2)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(CellColor(cell))
                surface.DrawRect(0, 0, w, 2)
                draw.SimpleText(def and def.short or disc, "EoCR_UISub", 8, 10, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                local val = "–"
                if cell then
                    if cell.status == "live" then val = "läuft …"
                    elseif cell.status == "aborted" then val = "abgebrochen"
                    elseif cell.status == "pending" then val = cell.note or "–"
                    else val = tostring(cell.text or cell.value) end
                end
                draw.SimpleText(val, "EoCR_UIBold", 8, 30, CellColor(cell), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if cell and cell.level then
                    draw.SimpleText(cell.level > 0 and C.BadgeNames[cell.level] or "unter Schwelle", "EoCR_UISmall", w - 8, 10, cell.level > 0 and C.BadgeColors[cell.level] or T.red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                if cell and cell.flagged then draw.SimpleText("!", "EoCR_UIBold", w - 8, 30, T.orange, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
            end
            local btns = vgui.Create("DPanel", box)
            btns:Dock(BOTTOM)
            btns:SetTall(26)
            btns:DockMargin(4, 0, 4, 4)
            btns.Paint = nil
            local function Small(text, col, fn)
                local b = UI.Button(btns, text, col, fn)
                b.Solid = false
                b:SetTall(26)
                b:Dock(LEFT)
                b:DockMargin(0, 0, 4, 0)
                surface.SetFont("EoCR_UIBold")
                b:SetWide(surface.GetTextSize(text) + 18)
            end
            local status = cell and cell.status or "pending"
            if status == "done" then
                Small("OK", T.green, function() EoCRange.Send("exam_confirm", { sid = cand.sid, disc = disc }) end)
                Small("Verwerfen", T.red, function()
                    Ask("Lauf verwerfen", "Grund (z. B. Bug):", function(v) EoCRange.Send("exam_discard", { sid = cand.sid, disc = disc, reason = v }) end)
                end)
            elseif status == "confirmed" then
                Small("Verwerfen", T.red, function()
                    Ask("Lauf verwerfen", "Grund:", function(v) EoCRange.Send("exam_discard", { sid = cand.sid, disc = disc, reason = v }) end)
                end)
            elseif status ~= "live" then
                Small("Start", T.accent, function() EoCRange.Send("exam_run", { sid = cand.sid, disc = disc }) end)
            end
        end
        local rm = UI.Button(row, "X", T.red, function() EoCRange.Send("exam_remove", { sid = cand.sid }) end)
        rm:SetSize(24, 24)
        rm:SetPos(nameW - 34, 8)
    end

    local bottom = vgui.Create("DPanel", parent)
    bottom:Dock(BOTTOM)
    bottom:SetTall(40)
    bottom:DockMargin(0, 8, 0, 0)
    bottom.Paint = nil
    local finish = UI.Button(bottom, "PRÜFUNG ABSCHLIESSEN", T.green, function() EoCRange.Send("exam_finish", {}) end)
    finish:Dock(RIGHT)
    finish:SetWide(260)
    local cancel = UI.Button(bottom, "Abbrechen", T.red, function()
        Derma_Query("Prüfung wirklich abbrechen? Es werden keine Abzeichen vergeben.", "Prüfung abbrechen", "Ja", function() EoCRange.Send("exam_cancel", {}) end, "Nein")
    end)
    cancel:Dock(LEFT)
    cancel:SetWide(130)
    local opts = {}
    for _, p in ipairs(d.players or {}) do opts[#opts + 1] = { p.uid, p.name } end
    local add = UI.Combo(bottom, opts, nil, function(v) EoCRange.Send("exam_add", { uid = v }) end)
    add:SetValue("Kandidat hinzufügen …")
    add:Dock(LEFT)
    add:SetWide(240)
    add:DockMargin(8, 5, 0, 5)
end

-- Eigene Disziplinen
local function BuildDisciplines(parent)
    local left = UI.Scroll(parent)
    left:Dock(LEFT)
    left:SetWide(280)
    left:DockMargin(0, 0, 14, 0)
    local form = UI.Scroll(parent)
    form:Dock(FILL)

    local function Edit(def)
        form:Clear()
        if def and not def.custom then
            UI.Header(form, def.name .. " (Standard)")
            UI.Note(form, def.desc or "", T.text)
            UI.Note(form, "Modus: " .. EoCRange.ModeName(def) .. " · Waffen: " .. EoCRange.WeaponNames(def) .. " · ID: " .. def.id)
            UI.Note(form, "Standard-Disziplinen sind fest eingebaut. Lege für eigene Abläufe eine neue Disziplin an.")
            return
        end
        local v = def or { mode = "sequence", count = 8, visible = 1.5, gap = { 0.6, 1.4 }, order = "random", reactionBonus = true, headDouble = true,
            missPenalty = true, weapons = { "dc15a", "dc15s", "dc17" }, timeLimit = C.TimedLimit, distance = 0 }
        UI.Header(form, def and ("Bearbeiten: " .. def.name) or "Neue Disziplin")
        local fields = {}
        local function Field(label, key, value, placeholder)
            UI.Note(form, label, T.dim)
            local e = UI.TextEntry(form, placeholder, value)
            e:Dock(TOP)
            e:DockMargin(0, 0, 0, 6)
            fields[key] = e
        end
        Field("Name", "name", v.name or "", "z. B. Kill-House Bravo")
        Field("Kürzel (max. 4)", "short", v.short or "", "KHB")
        Field("Beschreibung", "desc", v.desc or "", "Ablauf in einem Satz")

        UI.Note(form, "Ablauf", T.dim)
        local base = v.mode == "all" and "all" or "sequence"
        local combo = UI.Combo(form, { { "sequence", "Ziele nacheinander (Punkte)" }, { "all", "Alle Ziele gleichzeitig (Zeit)" } }, base, function(x) base = x end)
        combo:Dock(TOP)
        combo:DockMargin(0, 0, 0, 6)
        local order = v.order or "random"
        local ocombo = UI.Combo(form, { { "random", "Reihenfolge zufällig" }, { "fixed", "Reihenfolge fest (Feld „Reihenfolge“ am Klappziel)" } }, order, function(x) order = x end)
        ocombo:Dock(TOP)
        ocombo:DockMargin(0, 0, 0, 6)

        Field("Anzahl Ziele (nacheinander)", "count", v.count or 8)
        Field("Sichtbarkeit je Ziel (s)", "visible", v.visible or 1.5)
        Field("Pause min. (s)", "gapMin", (v.gap and v.gap[1]) or 0.6)
        Field("Pause max. (s)", "gapMax", (v.gap and v.gap[2]) or 1.4)
        Field("Nur Ziele mit Distanz (m, 0 = alle)", "distance", v.distance or 0)
        Field("Zeitlimit (s, bei „alle Ziele“)", "timeLimit", v.timeLimit or C.TimedLimit)
        Field("Strafe je Fehlschuss (leer = Standard: " .. C.MissPenaltyPoints .. " Pkt. / " .. C.MissPenaltySecs .. " s)", "missValue", v.missValue or "")
        Field("Strafe je Geisel (leer = Standard: " .. C.HostagePenaltyPoints .. " Pkt. / " .. C.HostagePenaltySecs .. " s)", "hostageValue", v.hostageValue or "")

        local checks = {}
        local function Check(text, key, value)
            local c = UI.Check(form, text, value)
            c:Dock(TOP)
            c:DockMargin(0, 4, 0, 4)
            checks[key] = c
        end
        Check("Geiselziele einbeziehen", "hostages", v.hostages)
        Check("Reaktionsbonus (nur nacheinander)", "reactionBonus", v.reactionBonus ~= false)
        Check("Kopfzone zählt doppelt", "headDouble", v.headDouble ~= false)
        Check("Fehlschüsse bestrafen", "missPenalty", v.missPenalty ~= false)

        UI.Note(form, "Erlaubte Waffen", T.dim)
        if C.AllowAllArcCW then
            UI.Note(form, "Hinweis: Zurzeit ist jede ArcCW-Waffe überall erlaubt (Einstellungen). Diese Auswahl greift erst, wenn das abgeschaltet ist.", T.orange)
        end
        local wchecks = {}
        for key, grp in SortedPairs(C.Weapons) do
            local c = UI.Check(form, grp.name, EoCRange.InList(v.weapons, key))
            c:Dock(TOP)
            c:DockMargin(0, 2, 0, 2)
            wchecks[key] = c
        end

        local bar = vgui.Create("DPanel", form)
        bar:Dock(TOP)
        bar:SetTall(40)
        bar:DockMargin(0, 12, 0, 0)
        bar.Paint = nil
        local save = UI.Button(bar, "SPEICHERN", T.accent, function()
            local raw = {
                name = fields.name:GetText(), short = fields.short:GetText(), desc = fields.desc:GetText(), base = base, order = order,
                count = fields.count:GetText(), visible = fields.visible:GetText(), gapMin = fields.gapMin:GetText(), gapMax = fields.gapMax:GetText(),
                distance = fields.distance:GetText(), timeLimit = fields.timeLimit:GetText(),
                missValue = tonumber(fields.missValue:GetText()), hostageValue = tonumber(fields.hostageValue:GetText()),
                hostages = checks.hostages:GetChecked(), reactionBonus = checks.reactionBonus:GetChecked(),
                headDouble = checks.headDouble:GetChecked(), missPenalty = checks.missPenalty:GetChecked(), weapons = {},
            }
            for key, c in pairs(wchecks) do if c:GetChecked() then raw.weapons[#raw.weapons + 1] = key end end
            EoCRange.Send("disc_save", { id = def and def.id or nil, raw = raw })
        end)
        save:Dock(RIGHT)
        save:SetWide(180)
        if def then
            local del = UI.Button(bar, "Löschen", T.red, function()
                Derma_Query("Disziplin '" .. def.name .. "' löschen? Ihre Läufe bleiben im Archiv.", "Löschen", "Ja", function()
                    EoCRange.Send("disc_delete", { id = def.id })
                end, "Nein")
            end)
            del:Dock(LEFT)
            del:SetWide(120)
        end
    end

    local function FillList()
        left:Clear()
        local new = UI.Button(left, "+ NEUE DISZIPLIN", T.accent, function() Edit(nil) end)
        new:Dock(TOP)
        new:DockMargin(0, 0, 0, 8)
        for _, def in ipairs(EoCRange.AllDisciplines()) do
            local row = UI.Row(left, 44, function(_, w, h)
                draw.SimpleText(def.name, "EoCR_UIBold", 10, 14, def.custom and T.accent or T.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(def.custom and "Eigene Disziplin" or "Standard", "EoCR_UISmall", 10, 32, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end)
            row:SetCursor("hand")
            row.OnMousePressed = function() Edit(def) end
        end
    end
    FillList()
    Edit(nil)
    hook.Add("EoCRange_Synced", "EoCRange_DiscList", function()
        if IsValid(left) then FillList() else hook.Remove("EoCRange_Synced", "EoCRange_DiscList") end
    end)
end

-- Ergebnisse
local resultsTarget, badgesTarget, logsTarget

EoCRange.Receive("results", function(d) if resultsTarget and IsValid(resultsTarget) then resultsTarget.Fill(d) end end)
EoCRange.Receive("badges", function(d) if badgesTarget and IsValid(badgesTarget) then badgesTarget.Fill(d) end end)
EoCRange.Receive("logs", function(d) if logsTarget and IsValid(logsTarget) then logsTarget.Fill(d) end end)

local function BuildRuns(parent)
    local filter = { discipline = "", flagged = false, exam = false, mine = false, search = "" }
    local top = vgui.Create("DPanel", parent)
    top:Dock(TOP)
    top:SetTall(30)
    top:DockMargin(0, 0, 0, 8)
    top.Paint = nil
    local list = UI.Scroll(parent)
    list:Dock(FILL)
    resultsTarget = list

    local function Request() EoCRange.Send("results", filter) end

    local combo = UI.Combo(top, DiscOptions(true), "", function(v) filter.discipline = v Request() end)
    combo:Dock(LEFT)
    combo:SetWide(190)
    local search = UI.TextEntry(top, "Name oder SteamID")
    search:Dock(LEFT)
    search:SetWide(170)
    search:DockMargin(6, 0, 6, 0)
    search.OnEnter = function(s) filter.search = s:GetText() Request() end
    for _, c in ipairs({ { "flagged", "ungeprüft" }, { "exam", "Prüfungen" }, { "mine", "meine Prüfungen" } }) do
        local cb = UI.Check(top, c[2], false)
        cb:Dock(LEFT)
        cb:DockMargin(8, 7, 0, 7)
        cb:SizeToContents()
        cb.OnChange = function(_, v) filter[c[1]] = v Request() end
    end

    function list.Fill(d)
        list:Clear()
        if #(d.rows or {}) == 0 then UI.Note(list, "Keine Läufe gefunden.") end
        for _, r in ipairs(d.rows or {}) do
            local def = EoCRange.GetDiscipline(r.discipline)
            local row = UI.Row(list, 40, function(_, w, h)
                draw.SimpleText("#" .. r.id, "EoCR_UISmall", 10, 12, T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(DateText(r.created), "EoCR_UISmall", 10, 28, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(r.name), "EoCR_UI", 130, 12, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(r.unit_name) .. " · " .. (def and def.name or r.discipline) .. " · Bahn " .. tostring(r.lane), "EoCR_UISmall", 130, 28, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                local tag = r.flagged == 1 and "UNGEPRÜFT" or (r.flagged == 2 and "ZURÜCKGESETZT" or (r.exam == 1 and ("PRÜFUNG · " .. tostring(r.instructor)) or ""))
                draw.SimpleText(tag, "EoCR_UISub", w * 0.52, h / 2, r.flagged == 1 and T.orange or T.blue, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(EoCRange.Format(def, r.score), "EoCR_UIBold", w * 0.72, h / 2, T.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end)
            local function Btn(text, col, fn)
                local b = UI.Button(row, text, col, fn)
                b.Solid = false
                b:Dock(RIGHT)
                b:SetWide(92)
                b:DockMargin(4, 5, 0, 5)
            end
            if r.canDelete then
                Btn("Löschen", T.red, function()
                    Ask("Lauf #" .. r.id .. " löschen", "Grund (wird protokolliert):", function(v)
                        EoCRange.Send("result_delete", { id = r.id, reason = v })
                        timer.Simple(0.6, Request)
                    end)
                end)
            end
            if r.canApprove then
                Btn("Werten", T.green, function()
                    EoCRange.Send("result_approve", { id = r.id })
                    timer.Simple(0.6, Request)
                end)
            end
            Btn("Ansehen", T.accent, function() EoCRange.Send("rundetail", { id = r.id }) end)
        end
    end
    Request()
end

local function BuildBadges(parent)
    local top = vgui.Create("DPanel", parent)
    top:Dock(TOP)
    top:SetTall(30)
    top:DockMargin(0, 0, 0, 8)
    top.Paint = nil
    local list = UI.Scroll(parent)
    list:Dock(FILL)
    badgesTarget = list
    local search = UI.TextEntry(top, "Name suchen und Enter")
    search:Dock(LEFT)
    search:SetWide(260)
    search.OnEnter = function(s) EoCRange.Send("badges", { search = s:GetText() }) end

    function list.Fill(d)
        list:Clear()
        if #(d.rows or {}) == 0 then UI.Note(list, "Keine Abzeichen gefunden.") end
        for _, b in ipairs(d.rows or {}) do
            local row = UI.Row(list, 40, function(_, w, h)
                draw.SimpleText(tostring(b.name), "EoCR_UI", 10, 12, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(DateText(b.created) .. " · Prüfer: " .. tostring(b.instructor), "EoCR_UISmall", 10, 28, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(EoCRange.BadgeName(b.level), "EoCR_UIBold", w * 0.45, h / 2, b.revoked == 1 and T.muted or C.BadgeColors[b.level], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if b.revoked == 1 then
                    draw.SimpleText("entzogen von " .. tostring(b.revoked_by) .. ": " .. tostring(b.reason), "EoCR_UISmall", w * 0.62, h / 2, T.red, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end)
            if b.revoked ~= 1 then
                local btn = UI.Button(row, "Entziehen", T.red, function()
                    Ask("Abzeichen entziehen", "Begründung (Pflicht, steht im Verlauf der Akte):", function(v)
                        EoCRange.Send("badge_revoke", { id = b.id, reason = v })
                        timer.Simple(0.6, function() EoCRange.Send("badges", { search = search:GetText() }) end)
                    end)
                end)
                btn.Solid = false
                btn:Dock(RIGHT)
                btn:SetWide(110)
                btn:DockMargin(4, 5, 4, 5)
            end
        end
    end
    EoCRange.Send("badges", {})
end

local function BuildLogs(parent)
    local list = UI.Scroll(parent)
    list:Dock(FILL)
    logsTarget = list
    function list.Fill(d)
        list:Clear()
        if #(d.lines or {}) == 0 then UI.Note(list, "Keine Einträge in den letzten 7 Tagen.") end
        for _, line in ipairs(d.lines or {}) do
            local l = UI.Label(list, line, "EoCR_UISmall", T.text)
            l:Dock(TOP)
            l:DockMargin(4, 0, 4, 4)
        end
    end
    EoCRange.Send("logs", {})
end

local function BuildResults(parent)
    UI.Tabs(parent, {
        { id = "runs", name = "Läufe", build = BuildRuns },
        { id = "badges", name = "Abzeichen", build = BuildBadges },
        { id = "logs", name = "Protokoll", build = BuildLogs },
    }, "runs")
end

-- Einstellungen (Admin)
local function BuildSettings(parent)
    local d = EoCRange.MenuData
    local s = table.Copy(d.settings or EoCRange.SettingsTable())
    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)

    UI.Header(scroll, "Einheiten und DEFCON")
    local unit = s.UnitLevel
    local uc = UI.Combo(scroll, { { "sub", "Untereinheit zählt (z. B. ARF)" }, { "main", "Haupteinheit zählt (z. B. 501st)" } }, unit, function(v) unit = v end)
    uc:Dock(TOP)
    uc:DockMargin(0, 0, 0, 6)
    UI.Note(scroll, "Gesperrt ab DEFCON-Stufe (und darunter). 0 = nie sperren.", T.dim)
    local defcon = UI.TextEntry(scroll, "2", s.DefconLockLevel)
    defcon:Dock(TOP)
    defcon:DockMargin(0, 0, 0, 6)

    UI.Header(scroll, "Waffen")
    local anyArc = UI.Check(scroll, "Jede ArcCW-Waffe in allen Disziplinen erlauben", s.AllowAllArcCW)
    anyArc:Dock(TOP)
    anyArc:DockMargin(0, 4, 0, 4)
    UI.Note(scroll, "Aus: Es zählen nur die Waffen, die eine Disziplin freigibt (Standard: Trainingswaffen). Eigene Disziplinen können „Alle ArcCW-Waffen“ einzeln erlauben.")

    UI.Header(scroll, "Abzeichen-Schwellen")
    UI.Note(scroll, "Punkte: Wert muss erreicht werden (≥). Zeitlauf: Zeit darf nicht überschritten werden (≤). Schnellfeuer: Treffer von 8.")
    local entries = {}
    for _, disc in ipairs(C.ExamDisciplines) do
        local def = EoCRange.GetDiscipline(disc)
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:SetTall(32)
        row:DockMargin(0, 0, 0, 4)
        row.Paint = function(_, w, h) draw.SimpleText(def and def.name or disc, "EoCR_UI", 0, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
        entries[disc] = {}
        for lvl = 3, 1, -1 do
            local e = UI.TextEntry(row, C.BadgeNames[lvl], (s.Thresholds[disc] or {})[lvl])
            e:Dock(RIGHT)
            e:SetWide(120)
            e:DockMargin(6, 0, 0, 0)
            e:SetTooltip(C.BadgeNames[lvl])
            entries[disc][lvl] = e
        end
    end
    local head = vgui.Create("DPanel", scroll)
    head:Dock(TOP)
    head:SetTall(18)
    head.Paint = function(_, w, h)
        for i, lvl in ipairs({ 3, 2, 1 }) do
            draw.SimpleText(C.BadgeNames[lvl], "EoCR_UISub", w - (i - 1) * 126 - 60, h / 2, C.BadgeColors[lvl], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    local save = UI.Button(scroll, "EINSTELLUNGEN SPEICHERN", T.accent, function()
        local th = {}
        for disc, list in pairs(entries) do
            th[disc] = {}
            for lvl, e in pairs(list) do th[disc][lvl] = tonumber(e:GetText()) end
        end
        EoCRange.Send("settings_save", { Thresholds = th, UnitLevel = unit, DefconLockLevel = tonumber(defcon:GetText()), AllowAllArcCW = anyArc:GetChecked() })
    end)
    save:Dock(TOP)
    save:SetTall(38)
    save:DockMargin(0, 10, 0, 0)

    UI.Header(scroll, "Ranglisten zurücksetzen")
    UI.Note(scroll, "Bestwerte werden gelöscht; die Läufe bleiben als „zurückgesetzt“ im Archiv. Der Wochen-Reset passiert automatisch montags 04:00 Uhr.")
    local rdisc, rperiod = "", "week"
    local row = vgui.Create("DPanel", scroll)
    row:Dock(TOP)
    row:SetTall(30)
    row.Paint = nil
    local dc = UI.Combo(row, DiscOptions(true), "", function(v) rdisc = v end)
    dc:Dock(LEFT)
    dc:SetWide(220)
    local pc = UI.Combo(row, { { "week", "Diese Woche" }, { "month", "Dieser Monat" }, { "all", "Alles (Allzeit)" } }, "week", function(v) rperiod = v end)
    pc:Dock(LEFT)
    pc:SetWide(180)
    pc:DockMargin(6, 0, 0, 0)
    local reset = UI.Button(row, "ZURÜCKSETZEN", T.red, function()
        Derma_Query("Rangliste wirklich zurücksetzen?", "Ranglisten zurücksetzen", "Ja", function()
            EoCRange.Send("board_reset", { disc = rdisc ~= "" and rdisc or nil, period = rperiod })
        end, "Nein")
    end)
    reset:Dock(RIGHT)
    reset:SetWide(180)
end

local function OpenMenu(d)
    EoCRange.MenuData = d
    local active = d.tab or (menuTabs and menuTabs.active)
    if IsValid(menuFrame) then menuFrame:Remove() end
    local role = d.role or {}
    local f = UI.Frame("EoC Range", 1100, 720, role.instructor and "Ausbilder-Menü" or "Ranglisten", function()
        if role.admin then return "ADMIN", T.red end
        if role.instructor then return "AUSBILDER", T.accent end
        return "SPIELER", T.dim
    end)
    menuFrame = f
    local tabs = { { id = "boards", name = "Ranglisten", build = function(p) BuildBoardView(p, nil, true) end } }
    if not role.instructor then
        tabs[#tabs + 1] = { id = "personal", name = "Persönlich", build = BuildPersonal }
    end
    if role.instructor then
        tabs[#tabs + 1] = { id = "lanes", name = "Bahnen", build = BuildLanes }
        tabs[#tabs + 1] = { id = "exam", name = "Prüfung", build = BuildExam }
        tabs[#tabs + 1] = { id = "disciplines", name = "Disziplinen", build = BuildDisciplines }
        tabs[#tabs + 1] = { id = "results", name = "Ergebnisse", build = BuildResults }
    end
    if role.admin then
        tabs[#tabs + 1] = { id = "settings", name = "Einstellungen", build = BuildSettings }
    end
    menuTabs = UI.Tabs(f, tabs, active or (role.instructor and "lanes" or "boards"))
end

EoCRange.Receive("menu", OpenMenu)

EoCRange.Receive("exam", function(d)
    EoCRange.MenuData.exam = d
    if IsValid(menuFrame) and menuTabs and menuTabs.active == "exam" then menuTabs.Select("exam") end
end)

EoCRange.Receive("examdone", function(d)
    Derma_Message(table.concat(d.lines or {}, "\n"), "Prüfung abgeschlossen", "OK")
end)
