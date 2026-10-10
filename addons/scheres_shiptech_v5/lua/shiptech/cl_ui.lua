--[[
    ShipTech – Konsolen-Menüs & Kontrollterminals
]]

local C = ShipTech.Config

-- Design: wie das Charaktersystem (EOCUI) – abgeschrägte Platten, Bernstein-Akzent, Überschriften mit Aurebesh
local P = ShipTech.Colors
local E = EOCUI
local T = {
    bg = P.bg, panel = P.panel, panel2 = P.panel2, panel3 = P.panel3, line = P.line, lineS = P.lineS,
    accent = P.yellow, text = P.text, dim = P.soft, muted = P.muted, ink = P.ink, cream = P.cream,
    green = P.green, yellow = P.yellow, orange = P.orange, red = P.red, blue = P.blue, cyan = P.cyan,
}
ShipTech.Theme = T

local UI = {}
ShipTech.UI = UI

local function Def(id) return ShipTech.SystemById[id] end
local function StageOf(h) return ShipTech.StageOf(h) end

-- Platte mit abgeschrägten Ecken (ersetzt die alten Boxen)
local function Plate(x, y, w, h, col, outline, cut, corners)
    cut = cut or 8
    corners = corners or "tlbr"
    if w < cut * 2 + 2 or h < cut * 2 + 2 then
        surface.SetDrawColor(col)
        surface.DrawRect(x, y, w, h)
        if outline ~= false then
            surface.SetDrawColor(outline or T.line)
            surface.DrawOutlinedRect(x, y, w, h, 1)
        end
        return
    end
    E.Cut(x, y, w, h, col, cut, corners)
    if outline ~= false then E.CutOutline(x, y, w, h, outline or T.line, cut, corners) end
end
UI.Plate = Plate

local function RBox(_, x, y, w, h, col)
    Plate(x, y, w, h, col)
end

local function PlayClick()
    surface.PlaySound("ui/buttonclickrelease.wav")
end

---------------------------------------------------------------------------
-- Bausteine
---------------------------------------------------------------------------
function UI.StyleScroll(scroll)
    local bar = scroll:GetVBar()
    bar:SetWide(4)
    bar:SetHideButtons(true)
    bar.Paint = function(_, w, h) surface.SetDrawColor(T.line) surface.DrawRect(0, 0, w, h) end
    bar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(T.accent) surface.DrawRect(0, 0, w, h) end
    return scroll
end

function UI.Scroll(parent)
    return UI.StyleScroll(vgui.Create("DScrollPanel", parent))
end

function UI.StyleCombo(c)
    c:SetFont("ShipTech_UI")
    c:SetTextColor(T.text)
    c.Paint = function(s, w, h)
        Plate(0, 0, w, h, T.panel2, (s:IsHovered() or s:IsMenuOpen()) and ColorAlpha(T.accent, 170) or T.line, 6, "br")
    end
    return c
end

-- Fenster: Titel mit Aurebesh, Akzentlinie, Reiter oben rechts (UI.AddTabs), Eckmarken
function UI.Frame(title, w, h, sub, status)
    local f = vgui.Create("DFrame")
    local W, H = math.min(w, ScrW() - 40), math.min(h, ScrH() - 40)
    f:SetSize(W, H)
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetDraggable(true)
    f:DockPadding(24, 96, 24, 34)
    f:MakePopup()
    f:SetAlpha(0)
    f:AlphaTo(255, 0.15)
    f.STTitle = string.upper(title or "")
    f.Paint = function(s, pw, ph)
        Plate(0, 0, pw, ph, T.bg, ColorAlpha(T.accent, 90), 22, "tlbr")
        -- Kopf
        surface.SetDrawColor(T.panel)
        surface.DrawRect(22, 1, pw - 23, 80)
        surface.SetDrawColor(ColorAlpha(T.accent, 60))
        surface.DrawRect(0, 81, pw, 1)
        surface.SetDrawColor(T.accent)
        surface.DrawRect(24, 81, 200, 2)

        draw.SimpleText(s.STTitle, "ShipTech_UITitle", 26, 8, T.text)
        E.Aurebesh(title or "", "eocui.aure.small", 28, 46, ColorAlpha(T.text, 110))
        local subW = draw.SimpleText(string.upper("Schiffstechnik // " .. (sub or "System")), "ShipTech_UISub", 28, 64, T.accent)
        if status then
            local st, sc = status()
            if st then draw.SimpleText("//  " .. st, "ShipTech_UISub", 28 + subW + 8, 64, sc) end
        end

        -- Rand-Markierungen links (wie im Charaktersystem)
        E.EdgeMarks(6, 100, ph - 140, ColorAlpha(T.text, 70), 2)
        -- Fußzeile
        surface.SetDrawColor(T.line)
        surface.DrawRect(24, ph - 26, pw - 48, 1)
        draw.SimpleText("ESC / X  SCHLIESSEN", "ShipTech_UISub", 26, ph - 13, T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        E.Aurebesh("ShipTech", "eocui.aure.small", pw - 26, ph - 13, ColorAlpha(T.text, 70), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    f.OnKeyCodePressed = function(s, key) if key == KEY_ESCAPE then s:Close() end end

    local close = UI.Button(f, "X", T.red, function() f:Close() end)
    close.Solid = false
    close:SetSize(40, 40)
    close:SetPos(W - 56, 20)
    f.CloseBtn = close
    return f
end

-- Reiter im Fensterkopf: große Überschrift mit Aurebesh, aktiver Reiter bernsteinfarben gefüllt
-- tabs = { {id=, name=}, ... } · onSelect(id) · gibt Funktion select(id) zurück
function UI.AddTabs(f, tabs, onSelect, rightPad, row)
    local btns = {}
    local x, y, th = 0, 2, 79
    local font = "ShipTech_Tab"
    surface.SetFont("ShipTech_UITitle")
    x = 26 + surface.GetTextSize(f.STTitle or "") + 40
    local maxX = f:GetWide() - (rightPad or 70)
    if row then
        -- eigene Reiterleiste unter dem Kopf (für viele Reiter)
        x, y, th, font = 24, 86, 62, "ShipTech_TabS"
        maxX = f:GetWide() - 24
        f:DockPadding(24, 160, 24, 34)
        local oldPaint = f.Paint
        f.Paint = function(s, pw, ph)
            oldPaint(s, pw, ph)
            surface.SetDrawColor(T.panel)
            surface.DrawRect(24, 86, pw - 48, 62)
            surface.SetDrawColor(T.line)
            surface.DrawRect(24, 148, pw - 48, 1)
        end
    end
    local current
    local function select(id)
        current = id
        for tid, b in pairs(btns) do b.Active = (tid == id) end
        if onSelect then onSelect(id) end
    end
    for _, t in ipairs(tabs) do
        local label = string.upper(t.name)
        surface.SetFont(font)
        local tw = surface.GetTextSize(label) + 34
        if x + tw > maxX then break end
        local b = vgui.Create("DButton", f)
        b:SetText("")
        b:SetPos(x, y)
        b:SetSize(tw, th)
        b.Paint = function(s, w, h)
            local hov = s:IsHovered()
            if s.Active then
                surface.SetDrawColor(T.accent)
                surface.DrawRect(0, 0, w, h)
            elseif hov then
                surface.SetDrawColor(ColorAlpha(T.accent, 24))
                surface.DrawRect(0, 0, w, h)
            end
            local col = s.Active and T.ink or (hov and T.text or ColorAlpha(T.text, 210))
            draw.SimpleText(label, font, w / 2, h / 2 - 6, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            E.Aurebesh(t.name, "eocui.aure.small", w / 2, h / 2 + (row and 15 or 18), s.Active and ColorAlpha(T.ink, 150) or ColorAlpha(T.text, 90), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if not s.Active then
                surface.SetDrawColor(T.line)
                surface.DrawRect(w - 1, 16, 1, h - 32)
            end
        end
        b.DoClick = function() PlayClick() select(t.id) end
        btns[t.id] = b
        x = x + tw
    end
    f.STTabs = btns
    return select, btns
end

-- Button: Standard = dunkle Platte mit Akzentstrich; Großbuchstaben-Hauptaktion = bernsteinfarben gefüllt
function UI.Button(parent, text, col, fn)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Label = text
    b.Accent = col or T.accent
    b.Solid = #text > 6 and text == string.upper(text) and col ~= T.dim
    b:SetTall(38)
    b.Paint = function(s, w, h)
        local enabled = s:IsEnabled()
        local hov = s:IsHovered() and enabled
        local c = s.Accent
        if s.Solid and enabled then
            Plate(0, 0, w, h, hov and c or ColorAlpha(c, 225), false, 8, "br")
            draw.SimpleText(string.upper(s.Label), "ShipTech_UIBold", w / 2, h / 2, T.ink, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        local bg = s.Active and ColorAlpha(c, 30) or (hov and T.panel3 or T.panel2)
        Plate(0, 0, w, h, bg, (s.Active or hov) and enabled and ColorAlpha(c, 200) or T.line, 6, "br")
        if enabled then
            surface.SetDrawColor(ColorAlpha(c, hov and 255 or 170))
            surface.DrawRect(0, 0, 3, h)
        end
        if s.Active then
            surface.SetDrawColor(c)
            surface.DrawRect(0, h - 2, w - 6, 2)
        end
        local tc = not enabled and T.muted or (s.Active and c or T.text)
        draw.SimpleText(string.upper(s.Label), "ShipTech_UIBold", w / 2, h / 2, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.OnCursorEntered = function(s) if s:IsEnabled() then surface.PlaySound("ui/buttonrollover.wav") end end
    b.DoClick = function(s)
        PlayClick()
        if fn then fn(s) end
    end
    return b
end

function UI.Label(parent, text, font, col)
    local l = vgui.Create("DLabel", parent)
    l:SetFont(font or "ShipTech_UI")
    l:SetTextColor(col or T.text)
    l:SetText(text)
    l:SetWrap(true)
    l:SetAutoStretchVertical(true)
    return l
end

-- Abschnittsüberschrift: groß, Linie, Aurebesh rechts (wie im Charaktersystem)
function UI.Header(parent, text)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(36)
    p:DockMargin(0, 10, 0, 4)
    p.Paint = function(_, w, h)
        local up = string.upper(text)
        local tw = draw.SimpleText(up, "ShipTech_UIMed", 0, h / 2 + 1, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(T.lineS)
        surface.DrawRect(tw + 10, h / 2 + 2, math.max(0, w - tw - 10), 1)
        E.Aurebesh(text, "eocui.aure.small", w, h / 2 - 12, ColorAlpha(T.dim, 110), TEXT_ALIGN_RIGHT)
    end
    return p
end

function UI.Note(parent, text, col)
    local l = UI.Label(parent, text, "ShipTech_UISmall", col or T.muted)
    l:Dock(TOP)
    l:DockMargin(4, 0, 4, 6)
    return l
end

function UI.TextEntry(parent, placeholder, multiline, tall)
    local e = vgui.Create("DTextEntry", parent)
    e:SetFont("ShipTech_UI")
    e:SetMultiline(multiline and true or false)
    e:SetTall(tall or 34)
    e:SetPaintBackground(false)
    e.Paint = function(s, w, h)
        Plate(0, 0, w, h, T.panel, s:HasFocus() and ColorAlpha(T.accent, 190) or T.lineS, 6, "br")
        if s:GetText() == "" and placeholder then
            draw.SimpleText(placeholder, "ShipTech_UI", 8, multiline and 6 or h / 2, T.muted, TEXT_ALIGN_LEFT, multiline and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
        end
        s:DrawTextEntryText(T.text, ColorAlpha(T.accent, 80), T.accent)
    end
    return e
end

-- Segmentbalken mit Beschriftung
function UI.DrawBar(x, y, w, h, frac, col, label, value)
    E.Bar(x, y, w, h, frac, col, 20)
    if label then draw.SimpleText(string.upper(label), "ShipTech_UISub", x, y - 4, T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM) end
    if value then draw.SimpleText(value, "ShipTech_UISub", x + w, y - 4, T.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM) end
end

-- Schließen, wenn man sich von der Konsole entfernt
local function BindToEnt(f, ent)
    local oldThink = f.Think
    f.Think = function(s)
        if oldThink then oldThink(s) end
        if not IsValid(ent) or LocalPlayer():GetPos():Distance(ent:GetPos()) > C.UseDistance * 2.2 then s:Close() end
    end
end

---------------------------------------------------------------------------
-- SYSTEM-KONSOLE
---------------------------------------------------------------------------
local STEPS = { "Diagnose", "Reparatur", "Testlauf", "Bericht", "Freigabe" }

local function WorkflowIndex(sys)
    if not sys.wf then return 0 end
    if sys.wf == "repair" then
        for _, f in ipairs(sys.faults or {}) do
            if not f.k then return 1 end
        end
        return 2
    end
    if sys.wf == "test" then return 3 end
    if sys.wf == "report" then return 4 end
    if sys.wf == "release" then return 5 end
    return 0
end

-- Energiefluss-Diagramm: REAKTOR ── NETZ ── SYSTEM (zeigt die Verbindung der Konsolen)
local function DrawPowerChain(x, y, w, id)
    local S = ShipTech.State
    local r, pw, sys = S.systems.reactor, S.systems.power, S.systems[id]
    local nodes = {
        { "REAKTOR", (S.supply.output or 0) > 0 and not (S.backup and S.backup.active), S.backup and S.backup.active and "NOTSTROM" or (math.Round(S.supply.output or 0) .. " E") },
        { "NETZ", pw.on and ShipTech.IsOperational(pw), math.Round((S.supply.ratio or 0) * 100) .. " %" },
        { string.upper(Def(id).name), (sys.power or 0) > 0, math.Round((sys.power or 0) * 100) .. " %" },
    }
    if S.backup and S.backup.active then nodes[1][2] = true end
    local nw, nh = (w - 2 * 40) / 3, 44
    for i, n in ipairs(nodes) do
        local nx = x + (i - 1) * (nw + 40)
        local col = n[2] and T.green or T.red
        ShipTech.Box(nx, y, nw, nh, T.panel2)
        surface.SetDrawColor(col)
        surface.DrawRect(nx, y, 2, nh)
        draw.SimpleText(n[1], "ShipTech_UIBold", nx + nw / 2, y + 14, T.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(n[3], "ShipTech_UISub", nx + nw / 2, y + 32, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if i < 3 then
            local lx, ly = nx + nw, y + nh / 2
            local flowing = n[2] and nodes[i + 1][2]
            surface.SetDrawColor(flowing and ColorAlpha(T.accent, 90) or T.line)
            surface.DrawRect(lx, ly - 1, 40, 2)
            if flowing then
                local t = (RealTime() * 1.5) % 1
                surface.SetDrawColor(T.accent)
                surface.DrawRect(lx + t * 34, ly - 2, 6, 4)
            end
        end
    end
end

function UI.PaintSystemInfo(w, h, id, ent)
    ShipTech.Box(0, 0, w, h, T.panel)
    local S = ShipTech.State
    local sys = ShipTech.Sys(id)
    local def = Def(id)
    if not sys then
        draw.SimpleText("KEINE DATEN", "ShipTech_UIBold", w / 2, h / 2, T.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end
    local stage = StageOf(sys.health)
    local st = ShipTech.Stages[stage]
    local stText, stCol = ShipTech.StatusInfo(id)

    -- Kopf
    surface.SetDrawColor(T.accent)
    surface.DrawRect(0, 0, 2, 66)
    draw.SimpleText(string.upper(def.name), "ShipTech_UISub", 16, 16, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(stText, "ShipTech_UIMed", 16, 42, stCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetFont("ShipTech_UIBold")
    local bw = surface.GetTextSize(string.upper(st.name)) + 24
    surface.SetDrawColor(ColorAlpha(st.col, 26))
    surface.DrawRect(w - bw - 14, 28, bw, 28)
    surface.SetDrawColor(ColorAlpha(st.col, 185))
    surface.DrawOutlinedRect(w - bw - 14, 28, bw, 28, 1)
    draw.SimpleText(string.upper(st.name), "ShipTech_UIBold", w - bw / 2 - 14, 42, st.col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(T.line)
    surface.DrawRect(14, 72, w - 28, 1)

    local y, bx, bwid, step = 104, 16, w - 32, 38
    UI.DrawBar(bx, y, bwid, 12, sys.health / 100, st.col, "Zustand", math.Round(sys.health) .. " %")
    y = y + step
    UI.DrawBar(bx, y, bwid, 12, sys.maint / 100, ShipTech.PctColor(sys.maint / 100), "Wartungszustand", math.Round(sys.maint) .. " %")
    y = y + step
    if sys.calib then
        UI.DrawBar(bx, y, bwid, 12, sys.calib / 100, ShipTech.PctColor(sys.calib / 100), "Kalibrierung", math.Round(sys.calib) .. " %")
        y = y + step
    end
    UI.DrawBar(bx, y, bwid, 12, sys.heat / 100, ShipTech.HeatColor(sys.heat), "Temperatur", math.Round(sys.heat) .. " %")
    y = y + step
    local cid = ShipTech.CircuitForSys(id)
    local circ = ShipTech.Circuit(cid)
    if circ then
        local cdef = ShipTech.CircuitById[cid]
        UI.DrawBar(bx, y, bwid, 12, circ.level / 100, circ.level < C.Cooling.LowLevel and T.red or T.cyan,
            cdef.name .. "  ·  Druck " .. math.Round(circ.pressure), math.Round(circ.level) .. " %")
        y = y + step
    end
    local wear = sys.wear or 1
    draw.SimpleText("VERSCHLEISS  x" .. string.format("%.2f", wear) .. "   ·   BETRIEBSSTUNDEN " .. string.format("%.1f", sys.hours or 0)
        .. "   ·   INSPEKTIONEN ÜBERFÄLLIG " .. ShipTech.OverdueCount(sys, id), "ShipTech_UISub", bx, y - 6,
        wear >= 2 and T.red or (wear >= 1.4 and T.orange or T.muted))
    y = y + 14

    if id == "reactor" then
        local out = (S.supply and S.supply.output) or 0
        UI.DrawBar(bx, y, bwid, 12, out / C.PowerBudget, T.accent, "Energieabgabe", math.Round(out) .. " / " .. C.PowerBudget .. " E")
        y = y + step
        local dem = (S.supply and S.supply.demand) or 0
        local load = out > 0 and dem / out or 0
        UI.DrawBar(bx, y, bwid, 12, math.min(1, load / 1.5), load > 1 and T.red or (load > 0.85 and T.orange or T.green), "Auslastung (Bedarf " .. dem .. " E)", math.Round(load * 100) .. " %")
        y = y + step
        local b = S.backup or {}
        UI.DrawBar(bx, y, bwid, 12, (b.charge or 0) / 100, b.active and T.orange or T.green, "Notstrom-Speicher" .. (b.active and " (aktiv)" or ""), math.Round(b.charge or 0) .. " %")
        y = y + step
    else
        UI.DrawBar(bx, y, bwid, 12, (sys.power or 0) / 1.5, (sys.power or 0) > 1.05 and T.orange or T.accent, "Energiezufuhr", sys.alloc .. " E (" .. math.Round((sys.power or 0) * 100) .. " %)")
        y = y + step
        UI.DrawBar(bx, y, bwid, 12, math.min(1, sys.eff or 0), ShipTech.PctColor(sys.eff or 0), "Effizienz", math.Round((sys.eff or 0) * 100) .. " %")
        y = y + step
    end

    -- Wartungsablauf
    surface.SetDrawColor(T.accent)
    surface.DrawRect(14, y - 4, 2, 12)
    draw.SimpleText("WARTUNGSABLAUF", "ShipTech_UISection", 22, y + 2, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    y = y + 30
    local cur = WorkflowIndex(sys)
    local sx, sw = 34, (w - 68) / 4
    surface.SetDrawColor(T.line)
    surface.DrawRect(sx, y - 1, w - 68, 2)
    for i, name in ipairs(STEPS) do
        local x = sx + (i - 1) * sw
        local skip = (i == 3 and cur > 0 and (sys.wfSev or 0) < 2)
        local col = T.muted
        if cur > 0 then
            if i < cur then col = T.green
            elseif i == cur then col = ColorAlpha(T.accent, 150 + 105 * math.abs(math.sin(RealTime() * 4))) end
        end
        if skip then col = T.line end
        surface.SetDrawColor(T.bg)
        surface.DrawRect(x - 8, y - 8, 16, 16)
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(x - 8, y - 8, 16, 16, 1)
        if cur > 0 and i <= cur and not skip then surface.DrawRect(x - 4, y - 4, 8, 8) end
        draw.SimpleText(skip and "–" or string.upper(name), "ShipTech_UISub", x, y + 14, (i == cur) and T.accent or T.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    y = y + 44

    -- Verbindung zum Energienetz
    if id ~= "reactor" then
        surface.SetDrawColor(T.accent)
        surface.DrawRect(14, y - 4, 2, 12)
        draw.SimpleText("ENERGIEVERSORGUNG", "ShipTech_UISection", 22, y + 2, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        y = y + 18
        DrawPowerChain(14, y, w - 28, id)
        y = y + 58
    end

    if def.navy then
        draw.SimpleText("NAVY-STARTFREIGABE: " .. (sys.navyClear and "ERTEILT" or "AUSSTEHEND"), "ShipTech_UIBold", 16, y, sys.navyClear and T.green or T.orange)
        y = y + 24
    end
    if IsValid(ent) and ent:GetNW2Bool("ST_NoPow") then
        draw.SimpleText("KONSOLE OHNE ENERGIE – NUR HANDBETRIEB", "ShipTech_UIBold", 16, y, T.red)
        y = y + 24
    end
    if S.combat then
        draw.SimpleText("GEFECHTSALARM – REPARATUREN UNTER ZEITDRUCK", "ShipTech_UIBold", 16, y, T.red)
    end
end

local function ActionSig(id, ent)
    local sys = ShipTech.Sys(id)
    if not sys then return "" end
    local S = ShipTech.State
    return util.TableToJSON({ sys.on, sys.booting, sys.wf, sys.faults, sys.coolLock, sys.navyClear, StageOf(sys.health),
        S.shields and S.shields.focus, S.parts, IsValid(ent) and ent:GetNW2Bool("ST_NoPow"), LocalPlayer():GetNW2String("ST_Quals"),
        ShipTech.HasTool(LocalPlayer()), ShipTech.ConsoleBurning(id), math.floor(sys.maint / 10), sys.heat >= 85,
        S.logi and S.logi.stock, ShipTech.CircuitBucket and ShipTech.CircuitBucket(id), sys.insp })
end

---------------------------------------------------------------------------
-- Tooltips & Lernhilfe
---------------------------------------------------------------------------
local HELP = {
    { "NOTABSCHALTUNG",          "Schaltet den Reaktor sofort ab. Das Schiff läuft danach auf Notstrom – nur essentielle Systeme bleiben versorgt." },
    { "REAKTOR HOCHFAHREN",      "Startet den Reaktor mit Systemscan (10 % bis 100 % im Chat). Danach fahren die Schilde automatisch hoch. Kühlsystem nicht vergessen!" },
    { "System herunterfahren",   "Schaltet das System ab. Es verbraucht dann keine Energie mehr und kühlt ab." },
    { "System hochfahren",       "Schaltet das System ein. Es bekommt Energie entsprechend der Energieverteilung." },
    { "Beheben",                 "Behebt diese Störung über das passende Minigame. Danach musst du die Reparaturzeit an der Konsole abwarten." },
    { "Diagnose",                "Minigame Fehlersuche: findet unbekannte Störungen. Das System geht danach in den Wartungsmodus (offline)." },
    { "TESTLAUF",                "Nach kritischen Schäden Pflicht: Minigame Synchronisation. Danach folgt der Wartungsbericht." },
    { "WARTUNGSBERICHT ERSTELLEN", "Beschreibe Ursache und durchgeführte Arbeiten. Danach kann ein leitender Techniker das System freigeben." },
    { "SYSTEM FREIGEBEN",        "Gibt das reparierte System wieder für den Betrieb frei. Nur mit Fortbildung 'Systemfreigabe'." },
    { "Routinewartung",          "Setzt den Wartungszustand auf 100 %. Regelmäßige Wartung verhindert Verschleiß und Zufallsstörungen." },
    { "Kalibrierung",            "Minigame Frequenzabgleich: stellt die Kalibrierung wieder her (Zielgenauigkeit / Sensorleistung)." },
    { "Wartungsbericht schreiben", "Allgemeiner Bericht, z. B. nach einer Routinewartung oder für einen Wartungsauftrag." },
    { "Ausgeglichen",            "Alle vier Schildsektoren gleichmäßig laden." },
}
local WORK = { "Beheben", "Diagnose", "TESTLAUF", "Routinewartung", "Kalibrierung" }

function UI.HelpFor(text)
    for _, h in ipairs(HELP) do
        if string.sub(text, 1, #h[1]) == h[1] then return h[2] end
    end
end

function UI.IsWorkAction(text)
    for _, w in ipairs(WORK) do
        if string.sub(text, 1, #w) == w then return true end
    end
    return false
end

function ShipTech.ConsoleBurning(id)
    for _, e in ipairs(ShipTech.ConsoleList("system", id)) do
        if e:GetNW2Float("ST_Fire", 0) > 0 then return true end
    end
    return false
end

-- Was soll der Techniker als Nächstes tun?
function UI.NextStep(id, burning, hasTool)
    local sys = ShipTech.Sys(id)
    if not sys then return end
    local def = Def(id)
    if burning then return "Brand löschen – Feuerlöscher benutzen (Linksklick halten).", T.red end
    local unknown, known = 0, 0
    for _, f in ipairs(sys.faults or {}) do
        if f.k then known = known + 1 else unknown = unknown + 1 end
    end
    local toolHint = hasTool and "" or "  (Datapad in die Hand nehmen)"
    if unknown > 0 then return "Diagnose starten – " .. unknown .. " unbekannte Störung(en)." .. toolHint, T.orange end
    if known > 0 then return known .. " Störung(en) einzeln beheben." .. toolHint, T.orange end
    if sys.wf == "test" then return "Testlauf durchführen." .. toolHint, T.accent end
    if sys.wf == "report" then return "Wartungsbericht schreiben.", T.accent end
    if sys.wf == "release" then return "Freigabe durch einen leitenden Techniker.", T.accent end
    if sys.coolLock then return "System kühlt nach Sicherheitsabschaltung ab – warten.", T.orange end
    if id == "reactor" and not sys.on and not sys.booting then return "Reaktor hochfahren, danach Kühlsystem und Energieverteilung starten.", T.accent end
    if id ~= "reactor" and not sys.on then
        if def.navy and not sys.navyClear then return "Navy-Startfreigabe am Brückenterminal anfordern.", T.orange end
        return "System hochfahren.", T.accent
    end
    if sys.heat >= 85 then return "Temperatur kritisch – Energiezufuhr senken oder Kühlsystem prüfen.", T.red end
    if sys.maint < 40 then return "Routinewartung durchführen (Wartungszustand " .. math.Round(sys.maint) .. " %)." .. toolHint, T.orange end
    if sys.calib and sys.calib < 50 then return "Kalibrierung durchführen (" .. math.Round(sys.calib) .. " %)." .. toolHint, T.orange end
    return "Alles in Ordnung – System läuft stabil.", T.green
end

-- „LERNHILFE“-Button im Fensterkopf
function UI.AddHelpButton(f, topic)
    local b = UI.Button(f, "LERNHILFE", T.accent, function() ShipTech.OpenHandbook(topic) end)
    b.Solid = false
    b:SetSize(130, 40)
    b:SetPos(f:GetWide() - 56 - 140, 20)
    b:SetTooltip("Öffnet das Techniker-Handbuch mit allen Abläufen und Minigame-Erklärungen.")
    return b
end

function UI.BuildSystemActions(scroll, ent, id, frame)
    local S = ShipTech.State
    local sys = ShipTech.Sys(id)
    local def = Def(id)
    if not sys then return end
    local ply = LocalPlayer()
    local canWork = ShipTech.CanWork(ply, id)
    local noPow = ent:GetNW2Bool("ST_NoPow")
    local qualName = ShipTech.QualById[def.qual] and ShipTech.QualById[def.qual].name or def.qual
    local noQual = "Benötigt Fortbildung: " .. qualName

    local burning = ShipTech.ConsoleBurning and ShipTech.ConsoleBurning(id)
    local hasTool = not C.Tool.Required or ShipTech.HasTool(ply)

    local function add(text, col, fn, enabled, tip, helpText)
        local b = UI.Button(scroll, text, col, fn)
        b:Dock(TOP)
        b:DockMargin(0, 0, 0, 6)
        b:SetTall(38)
        local help = helpText or UI.HelpFor(text)
        -- Arbeiten am System: Werkzeug nötig, nicht bei Brand
        if enabled ~= false and UI.IsWorkAction(text) then
            if burning then
                enabled, tip = false, "Die Konsole brennt – zuerst mit dem Feuerlöscher löschen."
            elseif not hasTool then
                enabled, tip = false, "Datapad in die Hand nehmen (" .. C.Tool.Class .. ")."
            end
        end
        if enabled == false then
            b:SetEnabled(false)
            b:SetTooltip("GESPERRT: " .. (tip or "nicht verfügbar") .. (help and ("\n\n" .. help) or ""))
        elseif help then
            b:SetTooltip(help)
        end
        return b
    end

    -- Lernhilfe: was ist jetzt zu tun?
    local stepText, stepCol = UI.NextStep(id, burning, hasTool)
    if stepText then
        local p = vgui.Create("DPanel", scroll)
        p:Dock(TOP)
        p:SetTall(58)
        p:DockMargin(0, 0, 0, 8)
        p.Paint = function(s, w, h)
            ShipTech.Box(0, 0, w, h, T.panel2)
            surface.SetDrawColor(stepCol)
            surface.DrawRect(0, 0, 2, h)
            draw.SimpleText("NÄCHSTER SCHRITT", "ShipTech_UISub", 12, 14, stepCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(stepText, "ShipTech_UI", 12, 38, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    if id == "shields" then
        local g = vgui.Create("DPanel", scroll)
        g:Dock(TOP)
        g:SetTall(330)
        g:DockMargin(0, 0, 0, 6)
        g.Paint = function(s, w, h)
            RBox(6, 0, 0, w, h, T.panel)
            ShipTech.DrawShieldGraphic(w / 2, h / 2 + 4, 125, { bigFont = "ShipTech_UIBig", smallFont = "ShipTech_UIBold" })
        end
    end

    UI.Header(scroll, "STEUERUNG")
    if id == "reactor" then
        if sys.on or sys.booting then
            add("NOTABSCHALTUNG (SCRAM)", T.red, function()
                Derma_Query("Reaktor wirklich notabschalten?", "Notabschaltung", "Ja, SCRAM", function()
                    ShipTech.SendAction("reactor_scram", ent)
                end, "Abbrechen")
            end, canWork or ShipTech.IsNavy(ply), noQual)
        else
            local why = not canWork and noQual or (not ShipTech.IsOperational(sys) and "Reaktor nicht betriebsbereit – Wartung/Abkühlung erforderlich") or nil
            add("REAKTOR HOCHFAHREN", T.green, function() ShipTech.SendAction("reactor_start", ent) end, why == nil, why)
        end
    else
        local canPower = canWork or ShipTech.IsNavy(ply)
        if sys.on then
            add("System herunterfahren", T.orange, function() ShipTech.SendAction("power", ent, { on = false }) end, canPower, noQual)
        else
            local why
            if not canPower then why = noQual
            elseif sys.wf then why = "System befindet sich in Wartung"
            elseif sys.health <= 0 then why = "System ausgefallen"
            elseif sys.coolLock then why = "Sicherheitsabschaltung – System kühlt ab"
            elseif def.navy and not sys.navyClear then why = "Navy-Startfreigabe fehlt (Brückenterminal)"
            elseif noPow then why = "Konsole ohne Energie" end
            add("System hochfahren", T.green, function() ShipTech.SendAction("power", ent, { on = true }) end, why == nil, why)
        end
    end

    if id == "shields" then
        UI.Header(scroll, "SEKTOR-VERSTÄRKUNG")
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:SetTall(36)
        row:DockMargin(0, 0, 0, 6)
        row.Paint = function() end
        local names = { [0] = "Ausgeglichen", "Bug", "Steuerbord", "Heck", "Backbord" }
        local btns = {}
        for i = 0, 4 do
            local b = UI.Button(row, names[i], T.accent, function() ShipTech.SendAction("shield_focus", ent, { sector = i }) end)
            b.Active = (S.shields.focus or 0) == i
            b:SetTooltip(i == 0 and "Alle vier Schildsektoren gleichmäßig laden." or ("Sektor " .. names[i] .. " bevorzugt laden (+25 % Kapazität), die anderen Sektoren werden schwächer."))
            if not (canWork or ShipTech.IsNavy(ply)) then b:SetEnabled(false) end
            btns[#btns + 1] = b
        end
        row.PerformLayout = function(s, w, h)
            local bw = (w - 4 * 4) / 5
            for i, b in ipairs(btns) do
                b:SetPos((i - 1) * (bw + 4), 0)
                b:SetSize(bw, h)
            end
        end
    end

    UI.Header(scroll, "STÖRUNGEN & REPARATUR")
    if #sys.faults == 0 then
        UI.Note(scroll, "Keine bekannten Störungen.", T.green)
    else
        for i, fl in ipairs(sys.faults) do
            local ft = ShipTech.FaultTypes[fl.t]
            if fl.k and ft then
                local why = not canWork and noQual or (sys.wf ~= "repair" and "Zuerst Diagnose durchführen") or nil
                local okPay, payInfo = ShipTech.CanPayRepair(fl.t, sys.wfSev or 0)
                if why == nil and not okPay then why = payInfo end
                local need = ShipTech.LogiActive() and ShipTech.ItemsText(ShipTech.RepairItems(fl.t, sys.wfSev or 0)) or nil
                local b = add("Beheben: " .. ft.name .. "   [" .. (ShipTech.GameNames[ft.game] or "") .. "]", T.yellow, function()
                    ShipTech.SendAction("repair", ent, { idx = i })
                end, why == nil, why)
                if need and why == nil then b:SetTooltip((UI.HelpFor("Beheben") or "") .. "\n\nMaterial: " .. need) end
            else
                UI.Note(scroll, "• Unbekannte Störung – Diagnose erforderlich", T.orange)
            end
        end
    end
    add("Diagnose / Fehlersuche starten", T.accent, function() ShipTech.SendAction("diagnose", ent) end, canWork, noQual)

    if sys.wf == "test" then
        add("TESTLAUF DURCHFÜHREN", T.green, function() ShipTech.SendAction("testrun", ent) end, canWork, noQual)
    elseif sys.wf == "report" then
        add("WARTUNGSBERICHT ERSTELLEN", T.green, function() UI.OpenReportForm(ent, id) end, ShipTech.IsTechnician(ply), "Nur für Techniker")
    elseif sys.wf == "release" then
        add("SYSTEM FREIGEBEN", T.green, function() ShipTech.SendAction("release", ent) end, ShipTech.CanRelease(ply, id), "Benötigt Fortbildung: Systemfreigabe (Leitung)")
    end

    if ShipTech.LogiActive() and S.logi then
        local parts = {}
        for _, res in ipairs(C.Logistik.ShownItems) do
            if S.logi.stock[res] then parts[#parts + 1] = ShipTech.ResName(res) .. " " .. S.logi.stock[res] end
        end
        UI.Note(scroll, "Schiffslager (" .. (S.logi.name or "Logistik") .. "): " .. table.concat(parts, " · "), T.dim)
    else
        local cost = C.PartsPerFault[sys.wfSev or 0] or 0
        UI.Note(scroll, "Ersatzteile an Bord: " .. (S.parts or 0) .. (cost > 0 and ("   ·   Bedarf je Störung: " .. cost) or ""), (S.parts or 0) < cost and T.red or T.dim)
    end

    -- Inspektionen
    local steps = ShipTech.InspectionsFor(id)
    if #steps > 0 then
        UI.Header(scroll, "INSPEKTION")
        for i, name in ipairs(steps) do
            local t0 = sys.insp and sys.insp[i] or 0
            local ago = t0 > 0 and math.floor((os.time() - t0) / 60) or nil
            local overdue = not ago or (os.time() - t0) > C.Inspection.Overdue
            local label = name .. "   ·   " .. (ago and ("vor " .. ago .. " min") or "nie") .. (overdue and "  (fällig)" or "")
            local b = add(label, overdue and T.orange or T.accent, function()
                ShipTech.SendAction("inspect", ent, { idx = i })
            end, canWork and not burning, not canWork and noQual or "Die Konsole brennt.",
                "Prüfschritt (ca. " .. C.Inspection.Time .. " s): erhöht den Wartungszustand und kann versteckte Störungen aufdecken. Überfällige Inspektionen erhöhen den Verschleiß.")
            b.Solid = false
        end
    end

    -- Kühlkreisläufe (nur an der Kühlsystem-Steuerung)
    if id == "coolant" then
        UI.Header(scroll, "KÜHLKREISLÄUFE")
        for _, c in ipairs(ShipTech.Circuits) do
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:SetTall(52)
            row:DockMargin(0, 0, 0, 6)
            row.Paint = function(s, w, h)
                local st = ShipTech.Circuit(c.id)
                if not st then return end
                UI.Plate(0, 0, w, h, T.panel, T.line, 6, "br")
                draw.SimpleText(string.upper(c.name), "ShipTech_UIBold", 12, 14, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText("DRUCK " .. math.Round(st.pressure) .. "   ·   TEMP " .. math.Round(st.temp) .. " %", "ShipTech_UISub", w - 150, 14, st.pressure >= C.Cooling.MaxPressure and T.red or T.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                UI.DrawBar(12, 34, w - 170, 10, st.level / 100, st.level < C.Cooling.LowLevel and T.red or T.cyan)
                draw.SimpleText(math.Round(st.level) .. " %", "ShipTech_UISub", w - 150, 39, T.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            local b = UI.Button(row, "Nachfüllen", T.cyan, function() ShipTech.SendAction("coolant_refill", ent, { circuit = c.id }) end)
            b:Dock(RIGHT)
            b:SetWide(130)
            b:DockMargin(0, 8, 8, 8)
            b:SetEnabled(canWork)
            b:SetTooltip("Füllt +" .. C.Cooling.RefillStep .. " % nach. Verbraucht Kühlmittel aus dem Schiffslager (" .. math.ceil(C.Logistik.CoolantPer10 * C.Cooling.RefillStep / 10) .. " KMT).")
        end
    end

    UI.Header(scroll, "ROUTINE")
    add("Routinewartung durchführen   [" .. (ShipTech.GameNames[def.maintGame] or "") .. "]", T.accent, function()
        ShipTech.SendAction("maintain", ent)
    end, canWork and not sys.wf, not canWork and noQual or "System befindet sich in einem Wartungsablauf")
    if def.calib then
        add("Kalibrierung durchführen   [Frequenzabgleich]", T.accent, function() ShipTech.SendAction("calibrate", ent) end, canWork and not sys.wf, not canWork and noQual or "System befindet sich in Wartung")
    end
    add("Wartungsbericht schreiben", T.dim, function() UI.OpenReportForm(ent, id) end, ShipTech.IsTechnician(ply), "Nur für Techniker")

    if not canWork then
        UI.Note(scroll, "Dir fehlt die Fortbildung „" .. qualName .. "“. Wende dich an einen Ausbilder.", T.red)
    end
end

-- kompakter Statusblock eines Systems (für die Energiezentrale)
local function CompactInfo(parent, id)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(150)
    p:DockMargin(0, 0, 0, 6)
    p.Paint = function(s, w, h)
        ShipTech.Box(0, 0, w, h, T.panel)
        local sys = ShipTech.Sys(id)
        if not sys then return end
        local st = ShipTech.Stages[StageOf(sys.health)]
        local txt, col = ShipTech.StatusInfo(id)
        surface.SetDrawColor(st.col)
        surface.DrawRect(0, 0, 2, h)
        draw.SimpleText(string.upper(Def(id).name), "ShipTech_UIBold", 12, 16, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(txt, "ShipTech_UISub", w - 10, 16, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        UI.DrawBar(12, 50, w - 24, 10, sys.health / 100, st.col, "Zustand", math.Round(sys.health) .. " %")
        UI.DrawBar(12, 84, w - 24, 10, sys.maint / 100, ShipTech.PctColor(sys.maint / 100), "Wartung", math.Round(sys.maint) .. " %")
        UI.DrawBar(12, 118, w - 24, 10, sys.heat / 100, ShipTech.HeatColor(sys.heat), "Temperatur", math.Round(sys.heat) .. " %")
        if #(sys.faults or {}) > 0 then
            draw.SimpleText(#sys.faults .. " STÖRUNG(EN)", "ShipTech_UISub", w - 10, 140, T.orange, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    return p
end

local function FrameStatus()
    local S = ShipTech.State
    if not S then return nil end
    if next(S.alarms or {}) then return "ALARM AKTIV", ColorAlpha(T.red, 150 + math.sin(CurTime() * 6) * 105) end
    if S.backup and S.backup.active then return "NOTSTROMBETRIEB", T.orange end
    if (S.supply and S.supply.output or 0) <= 0 then return "KEINE ENERGIE", T.red end
    return "SYSTEME STABIL", T.green
end
UI.FrameStatus = FrameStatus

-- Reaktor- und Energiekonsole: verbundene Energiezentrale (beide zeigen dasselbe)
function UI.OpenEnergyCentral(ent)
    if IsValid(UI.Current) then UI.Current:Remove() end
    local id = ent.SysId
    local f = UI.Frame("Energiezentrale", 1420, 820, ent.PrintName .. " // Reaktor + Energienetz verbunden", FrameStatus)
    UI.Current = f
    UI.AddHelpButton(f, 4)
    BindToEnt(f, ent)

    -- links: Reaktor (identisch an beiden Konsolen)
    local left = vgui.Create("DPanel", f)
    left:Dock(LEFT)
    left:SetWide(math.min(400, f:GetWide() * 0.3))
    left:DockMargin(0, 0, 14, 0)
    left.Paint = function(s, w, h) UI.PaintSystemInfo(w, h, "reactor", ent) end

    -- rechts: Netzstatus + Aktionen der eigenen Konsole
    local right = vgui.Create("DPanel", f)
    right:Dock(RIGHT)
    right:SetWide(math.min(370, f:GetWide() * 0.27))
    right:DockMargin(14, 0, 0, 0)
    right.Paint = function() end
    UI.Header(right, "ENERGIENETZ")
    CompactInfo(right, "power")
    UI.Header(right, "AKTIONEN – " .. string.upper(Def(id).name))
    local actions = UI.Scroll(right)
    actions:Dock(FILL)

    -- Mitte: Energieverteilung (identisch an beiden Konsolen)
    local center = vgui.Create("DPanel", f)
    center:Dock(FILL)
    center.Paint = function() end
    UI.Header(center, "ENERGIEVERTEILUNG")
    local Builders = UI.Builders
    Builders.power(center, ent)

    local sig
    local function rebuild()
        sig = ActionSig(id, ent)
        actions:Clear()
        UI.BuildSystemActions(actions, ent, id, f)
    end
    rebuild()
    hook.Add("ShipTech_StateUpdated", f, function(self)
        if ActionSig(id, ent) ~= sig then rebuild() end
    end)
end

function UI.OpenSystem(ent)
    local id = ent.SysId
    local def = Def(id)
    if not def then return end
    if id == "reactor" or id == "power" then return UI.OpenEnergyCentral(ent) end
    if IsValid(UI.Current) then UI.Current:Remove() end

    local f = UI.Frame(ent.PrintName, 1040, 740, def.name .. " // " .. def.desc, FrameStatus)
    UI.Current = f
    UI.AddHelpButton(f, 3)
    BindToEnt(f, ent)

    local left = vgui.Create("DPanel", f)
    left:Dock(LEFT)
    left:SetWide(math.min(470, f:GetWide() * 0.48))
    left:DockMargin(0, 0, 18, 0)
    left.Paint = function(s, w, h) UI.PaintSystemInfo(w, h, id, ent) end

    local right = UI.Scroll(f)
    right:Dock(FILL)

    local sig
    local function rebuild()
        sig = ActionSig(id, ent)
        right:Clear()
        UI.BuildSystemActions(right, ent, id, f)
    end
    rebuild()

    hook.Add("ShipTech_StateUpdated", f, function(self)
        if ActionSig(id, ent) ~= sig then rebuild() end
    end)
end

---------------------------------------------------------------------------
-- WARTUNGSBERICHT
---------------------------------------------------------------------------
function UI.OpenReportForm(ent, sysId, orderId)
    local f = UI.Frame("WARTUNGSBERICHT", 640, 640)
    local S = ShipTech.State

    local function lbl(text)
        local l = UI.Label(f, text, "ShipTech_UIBold", T.dim)
        l:Dock(TOP)
        l:DockMargin(0, 6, 0, 4)
    end

    lbl("System")
    local sysBox = UI.StyleCombo(vgui.Create("DComboBox", f))
    sysBox:Dock(TOP)
    sysBox:SetTall(30)
    sysBox:AddChoice("– Allgemein / kein System –", "", sysId == nil)
    for _, def in ipairs(ShipTech.Systems) do
        sysBox:AddChoice(def.name, def.id, def.id == sysId)
    end

    lbl("Bezug zu Wartungsauftrag")
    local ordBox = UI.StyleCombo(vgui.Create("DComboBox", f))
    ordBox:Dock(TOP)
    ordBox:SetTall(30)
    ordBox:AddChoice("– kein Auftrag –", 0, orderId == nil)
    for _, o in ipairs(S.orders or {}) do
        if o.status == "open" or o.status == "accepted" then
            ordBox:AddChoice("#" .. o.id .. " " .. o.title, o.id, o.id == orderId)
        end
    end

    lbl("Ursache / Befund")
    local cause = UI.TextEntry(f, "Was war die Ursache des Problems?", true, 90)
    cause:Dock(TOP)
    lbl("Durchgeführte Maßnahmen *")
    local measures = UI.TextEntry(f, "Welche Arbeiten wurden durchgeführt?", true, 120)
    measures:Dock(TOP)
    lbl("Bemerkungen")
    local notes = UI.TextEntry(f, "Empfehlungen, Ersatzteile, Hinweise ...", true, 70)
    notes:Dock(TOP)

    local send = UI.Button(f, "BERICHT EINREICHEN", T.green, function()
        local _, sid = sysBox:GetSelected()
        local _, oid = ordBox:GetSelected()
        ShipTech.SendAction("report", ent, {
            sys = (sid ~= "" and sid) or nil,
            order = (oid and oid ~= 0) and oid or nil,
            cause = cause:GetValue(), measures = measures:GetValue(), notes = notes:GetValue(),
        })
        f:Close()
    end)
    send:Dock(BOTTOM)
    send:SetTall(42)
end

---------------------------------------------------------------------------
-- KONTROLLTERMINAL
---------------------------------------------------------------------------
local Builders = {}
UI.Builders = Builders

-- Übersicht ---------------------------------------------------------------
Builders.overview = function(content)
    local p = vgui.Create("DPanel", content)
    p:Dock(FILL)
    p.Paint = function(s, w, h)
        local S = ShipTech.State
        if not S then return end
        local sensorsBad = (S.mods and (S.mods.sensors or 0) < 50)
        local function J(v)
            if sensorsBad then return math.Clamp(v + math.random(-9, 9), 0, 100) end
            return v
        end

        -- Kopfzeile
        local tiles = {}
        local rt, rc = ShipTech.StatusInfo("reactor")
        tiles[1] = { "REAKTOR", rt, rc, math.Round(S.supply.output or 0) .. " / " .. C.PowerBudget .. " E" }
        local b = S.backup or {}
        tiles[2] = { "NOTSTROM", b.active and "AKTIV" or "BEREIT", b.active and T.yellow or T.green, math.Round(b.charge or 0) .. " % Speicher" }
        if S.logi then
            local tech, cap = S.logi.stock.tech or 0, (S.logi.cap and S.logi.cap.tech) or 0
            tiles[3] = { "ERSATZTEILE", tostring(tech), (cap > 0 and tech / cap > 0.25) and T.green or T.red, "Kühlmittel " .. (S.logi.stock.coolant or 0) .. " · " .. (S.logi.name or "Lager") }
        else
            tiles[3] = { "ERSATZTEILE", tostring(S.parts or 0), (S.parts or 0) > 3 and T.green or T.red, (S.partsETA or 0) > 0 and ("Lieferung in " .. math.max(0, math.ceil(S.partsETA - CurTime())) .. " s") or "an Bord" }
        end
        tiles[4] = { "GEFECHTSSTATUS", S.combat and "GEFECHTSALARM" or "NORMAL", S.combat and T.red or T.green, "Versorgung " .. math.Round((S.supply.ratio or 0) * 100) .. " %" }
        local tw = (w - 30) / 4
        for i, t in ipairs(tiles) do
            local x = (i - 1) * (tw + 10)
            RBox(6, x, 0, tw, 76, T.panel)
            draw.SimpleText(t[1], "ShipTech_UISmall", x + 12, 10, T.dim)
            draw.SimpleText(t[2], "ShipTech_UIMed", x + 12, 26, t[3])
            draw.SimpleText(t[4], "ShipTech_UISmall", x + 12, 58, T.dim)
        end

        -- Schilde
        RBox(6, 0, 88, 340, 372, T.panel)
        draw.SimpleText("SCHILDSTATUS", "ShipTech_UIBold", 12, 98, T.accent)
        ShipTech.DrawShieldGraphic(170, 290, 118, { bigFont = "ShipTech_UIBig", smallFont = "ShipTech_UIBold" })

        -- Systemkarten
        local gx, gy = 352, 88
        local cw = (w - gx - 20) / 3
        local ch = 116
        for i, def in ipairs(ShipTech.Systems) do
            local sys = S.systems[def.id]
            local cx = gx + ((i - 1) % 3) * (cw + 10)
            local cy = gy + math.floor((i - 1) / 3) * (ch + 12)
            local st = ShipTech.Stages[StageOf(sys.health)]
            local txt, col = ShipTech.StatusInfo(def.id)
            RBox(6, cx, cy, cw, ch, T.panel)
            surface.SetDrawColor(st.col)
            surface.DrawRect(cx, cy, 4, ch)
            draw.SimpleText(def.name, "ShipTech_UIBold", cx + 14, cy + 10, T.text)
            draw.SimpleText(txt, "ShipTech_UISmall", cx + 14, cy + 32, col)
            UI.DrawBar(cx + 14, cy + 70, cw - 28, 10, J(sys.health) / 100, st.col, "Zustand", math.Round(J(sys.health)) .. " %")
            local effTxt = def.id == "reactor" and (math.Round(S.supply.output or 0) .. " E") or (math.Round((sys.eff or 0) * 100) .. " % Eff.")
            draw.SimpleText(effTxt, "ShipTech_UISmall", cx + cw - 14, cy + 12, T.dim, TEXT_ALIGN_RIGHT)
            if #(sys.faults or {}) > 0 then
                draw.SimpleText(#sys.faults .. " Störung(en)", "ShipTech_UISmall", cx + 14, cy + 90, T.orange)
            elseif sys.maint < 40 then
                draw.SimpleText("Wartung fällig", "ShipTech_UISmall", cx + 14, cy + 90, T.yellow)
            end
            draw.SimpleText(math.Round(sys.heat) .. " % Temp.", "ShipTech_UISmall", cx + cw - 14, cy + 90, ShipTech.HeatColor(sys.heat), TEXT_ALIGN_RIGHT)
        end

        -- Schiffsleistung
        local m = S.mods or {}
        local y = 472
        RBox(6, 0, y, w, 56, T.panel)
        local items = {
            { "Geschwindigkeit", J(m.speed or 0) .. " %", ShipTech.PctColor((m.speed or 0) / 100) },
            { "Feuerbereitschaft", J(m.weapons or 0) .. " %", ShipTech.PctColor((m.weapons or 0) / 100) },
            { "Zielgenauigkeit", J(m.accuracy or 0) .. " %", ShipTech.PctColor((m.accuracy or 0) / 100) },
            { "Sensoren", (m.sensors or 0) .. " %", ShipTech.PctColor((m.sensors or 0) / 100) },
            { "Hyperantrieb", m.hyper and "SPRUNGBEREIT" or "NICHT BEREIT", m.hyper and T.green or T.red },
            { "Kommunikation", m.comms and "ONLINE" or "AUSGEFALLEN", m.comms and T.green or T.red },
        }
        local iw = w / #items
        for i, it in ipairs(items) do
            draw.SimpleText(it[1], "ShipTech_UISmall", (i - 0.5) * iw, y + 16, T.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(it[2], "ShipTech_UIBold", (i - 0.5) * iw, y + 38, it[3], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Alarme
        y = y + 66
        local list = {}
        for id, a in pairs(S.alarms or {}) do
            local def = ShipTech.AlarmTypes[id]
            if def then list[#list + 1] = def.name .. ((a.info and a.info ~= "") and (" – " .. a.info) or "") end
        end
        if sensorsBad then list[#list + 1] = "SENSORDATEN UNZUVERLÄSSIG – Werte können abweichen" end
        if #list == 0 then
            draw.SimpleText("Keine aktiven Alarme.", "ShipTech_UI", 4, y, T.green)
        else
            for i, txt in ipairs(list) do
                draw.SimpleText("! " .. txt, "ShipTech_UIBold", 4, y + (i - 1) * 22, T.red)
            end
        end
    end
end

-- Energieverteilung -------------------------------------------------------
local PRESETS = {
    { "Standard", nil },
    { "Gefecht",       { shields = 30, weapons = 30, engines = 15, hyperdrive = 2,  sensors = 10, comms = 6, coolant = 5, power = 2 } },
    { "Manöver",       { shields = 15, weapons = 10, engines = 35, hyperdrive = 10, sensors = 12, comms = 8, coolant = 7, power = 3 } },
    { "Hyperraum",     { shields = 15, weapons = 5,  engines = 15, hyperdrive = 35, sensors = 10, comms = 8, coolant = 9, power = 3 } },
    { "Schildfokus",   { shields = 40, weapons = 15, engines = 15, hyperdrive = 2,  sensors = 10, comms = 8, coolant = 7, power = 3 } },
}

Builders.power = function(content, ent)
    local S = ShipTech.State
    local draft = {}
    local consumers = {}
    for _, def in ipairs(ShipTech.Systems) do
        if def.id ~= "reactor" then
            consumers[#consumers + 1] = def
            draft[def.id] = S.systems[def.id].alloc
        end
    end
    local can = ShipTech.CanManagePower(LocalPlayer())

    local function total()
        local t = 0
        for _, v in pairs(draft) do t = t + v end
        return t
    end

    UI.Note(content, "Verteile die Reaktorleistung auf die Systeme. Mehr Energie als der Normalwert erhöht die Leistung, aber auch die Temperatur. Übersteigt der Bedarf die Reaktorleistung, wird der Reaktor überlastet.", T.dim)

    local presetRow = vgui.Create("DPanel", content)
    presetRow:Dock(TOP)
    presetRow:SetTall(34)
    presetRow:DockMargin(0, 0, 0, 10)
    presetRow.Paint = function() end
    local pbtns = {}
    for _, pr in ipairs(PRESETS) do
        pbtns[#pbtns + 1] = UI.Button(presetRow, pr[1], T.accent, function()
            for _, def in ipairs(consumers) do
                draft[def.id] = pr[2] and pr[2][def.id] or def.nominal
            end
        end)
    end
    presetRow.PerformLayout = function(s, w, h)
        local bw = (w - (#pbtns - 1) * 6) / #pbtns
        for i, b in ipairs(pbtns) do
            b:SetPos((i - 1) * (bw + 6), 0)
            b:SetSize(bw, h)
        end
    end

    for _, def in ipairs(consumers) do
        local row = vgui.Create("DPanel", content)
        row:Dock(TOP)
        row:SetTall(44)
        row:DockMargin(0, 0, 0, 4)
        local minus = UI.Button(row, "–", T.accent, function() draft[def.id] = math.max(0, draft[def.id] - 1) end)
        local plus = UI.Button(row, "+", T.accent, function() draft[def.id] = math.min(C.MaxAllocPerSystem, draft[def.id] + 1) end)
        minus:SetEnabled(can)
        plus:SetEnabled(can)
        row.PerformLayout = function(s, w, h)
            minus:SetPos(180, 6)
            minus:SetSize(36, h - 12)
            plus:SetPos(w - 150, 6)
            plus:SetSize(36, h - 12)
        end
        row.Paint = function(s, w, h)
            RBox(4, 0, 0, w, h, T.panel)
            local sys = ShipTech.Sys(def.id)
            local _, col = ShipTech.StatusInfo(def.id)
            draw.SimpleText(def.name, "ShipTech_UIBold", 12, h / 2 - 8, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText((def.essential and "essentiell · " or "") .. "Normal " .. def.nominal, "ShipTech_UISmall", 12, h / 2 + 10, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local bx, bw = 226, w - 226 - 160
            local v = draft[def.id]
            local over = v > def.nominal * 1.2
            UI.DrawBar(bx, h / 2 - 6, bw, 12, v / C.MaxAllocPerSystem, over and T.orange or T.accent)
            local nx = bx + bw * def.nominal / C.MaxAllocPerSystem
            surface.SetDrawColor(255, 255, 255, 180)
            surface.DrawRect(nx - 1, h / 2 - 12, 2, 24)
            draw.SimpleText(v .. " E", "ShipTech_UIBold", w - 104, h / 2 - 8, over and T.orange or T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(math.Round((sys.power or 0) * 100) .. " % · Temp. " .. math.Round(sys.heat) .. " %", "ShipTech_UISmall", w - 104, h / 2 + 10, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        row.OnMousePressed = function(s)
            if not can then return end
            local mx = s:CursorPos()
            local bx, bw = 226, s:GetWide() - 226 - 160
            if mx >= bx and mx <= bx + bw then
                draft[def.id] = math.Clamp(math.Round((mx - bx) / bw * C.MaxAllocPerSystem), 0, C.MaxAllocPerSystem)
            end
        end
    end

    local bottom = vgui.Create("DPanel", content)
    bottom:Dock(BOTTOM)
    bottom:SetTall(70)
    local reset = UI.Button(bottom, "Zurücksetzen", T.dim, function()
        for _, def in ipairs(consumers) do draft[def.id] = ShipTech.Sys(def.id).alloc end
    end)
    local apply = UI.Button(bottom, "ÜBERNEHMEN", T.green, function()
        if total() > C.PowerBudget then
            notification.AddLegacy("Gesamtzuteilung zu hoch (max. " .. C.PowerBudget .. ")", NOTIFY_ERROR, 4)
            return
        end
        ShipTech.SendAction("alloc", ent, { alloc = draft })
    end)
    apply:SetEnabled(can)
    if not can then apply:SetTooltip("Keine Berechtigung") end
    bottom.PerformLayout = function(s, w, h)
        reset:SetPos(w - 340, 16)
        reset:SetSize(150, 40)
        apply:SetPos(w - 180, 16)
        apply:SetSize(180, 40)
    end
    bottom.Paint = function(s, w, h)
        local St = ShipTech.State
        local t = total()
        draw.SimpleText("Zugeteilt: " .. t .. " / " .. C.PowerBudget .. " E", "ShipTech_UIMed", 4, 22, t > C.PowerBudget and T.red or T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local out = St.supply.output or 0
        local txt = "Verfügbare Leistung: " .. math.Round(out) .. " E" .. (St.backup.active and "  (NOTSTROM – nur essentielle Systeme)" or "")
        draw.SimpleText(txt, "ShipTech_UI", 4, 52, St.backup.active and T.yellow or T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

-- Aufträge ----------------------------------------------------------------
local STATUS = { open = { "OFFEN", T.yellow }, accepted = { "ANGENOMMEN", T.accent }, done = { "ERLEDIGT", T.green }, cancel = { "STORNIERT", T.dim } }
local PRIO = { [1] = { "Niedrig", T.green }, [2] = { "Mittel", T.yellow }, [3] = { "Hoch", T.red } }

function UI.OpenOrderForm(sendFn)
    local f = UI.Frame("NEUER WARTUNGSAUFTRAG", 560, 480)
    local function lbl(text)
        local l = UI.Label(f, text, "ShipTech_UIBold", T.dim)
        l:Dock(TOP)
        l:DockMargin(0, 6, 0, 4)
    end
    lbl("System")
    local sysBox = UI.StyleCombo(vgui.Create("DComboBox", f))
    sysBox:Dock(TOP)
    sysBox:SetTall(30)
    sysBox:AddChoice("– Allgemein –", "", true)
    for _, def in ipairs(ShipTech.Systems) do sysBox:AddChoice(def.name, def.id) end
    lbl("Titel")
    local title = UI.TextEntry(f, "z. B. Turbolaserbatterie 3 prüfen")
    title:Dock(TOP)
    lbl("Beschreibung")
    local desc = UI.TextEntry(f, "Details zum Auftrag ...", true, 110)
    desc:Dock(TOP)
    lbl("Priorität")
    local prio = UI.StyleCombo(vgui.Create("DComboBox", f))
    prio:Dock(TOP)
    prio:SetTall(30)
    prio:AddChoice("Niedrig", 1)
    prio:AddChoice("Mittel", 2, true)
    prio:AddChoice("Hoch", 3)
    local send = UI.Button(f, "AUFTRAG ERSTELLEN", T.green, function()
        local _, sid = sysBox:GetSelected()
        local _, pr = prio:GetSelected()
        sendFn({ sys = (sid ~= "" and sid) or nil, title = title:GetValue(), desc = desc:GetValue(), prio = pr or 2 })
        f:Close()
    end)
    send:Dock(BOTTOM)
    send:SetTall(42)
end

Builders.orders = function(content, ent)
    local S = ShipTech.State
    local ply = LocalPlayer()
    local top = vgui.Create("DPanel", content)
    top:Dock(TOP)
    top:SetTall(40)
    top:DockMargin(0, 0, 0, 8)
    top.Paint = function(s, w, h)
        local open = 0
        for _, o in ipairs(S.orders or {}) do
            if o.status == "open" or o.status == "accepted" then open = open + 1 end
        end
        draw.SimpleText("Offene Aufträge: " .. open, "ShipTech_UIMed", 4, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    if ShipTech.CanCreateOrders(ply) then
        local nb = UI.Button(top, "+ Neuer Auftrag", T.green, function()
            UI.OpenOrderForm(function(data) ShipTech.SendAction("order_create", ent, data) end)
        end)
        nb:Dock(RIGHT)
        nb:SetWide(180)
    end

    local scroll = UI.Scroll(content)
    scroll:Dock(FILL)

    local list = {}
    for _, o in ipairs(S.orders or {}) do list[#list + 1] = o end
    table.sort(list, function(a, b)
        local ao = (a.status == "open" or a.status == "accepted") and 1 or 0
        local bo = (b.status == "open" or b.status == "accepted") and 1 or 0
        if ao ~= bo then return ao > bo end
        if ao == 1 and a.prio ~= b.prio then return a.prio > b.prio end
        return a.id > b.id
    end)

    if #list == 0 then UI.Note(scroll, "Keine Wartungsaufträge vorhanden.") end

    for _, o in ipairs(list) do
        local active = o.status == "open" or o.status == "accepted"
        local card = vgui.Create("DPanel", scroll)
        card:Dock(TOP)
        card:SetTall(104)
        card:DockMargin(0, 0, 0, 6)
        local st = STATUS[o.status] or STATUS.open
        local pr = PRIO[o.prio] or PRIO[2]
        local desc = o.desc or ""
        if #desc > 150 then desc = string.sub(desc, 1, 147) .. "..." end
        card.Paint = function(s, w, h)
            RBox(6, 0, 0, w, h, active and T.panel or Color(14, 18, 24))
            surface.SetDrawColor(pr[2])
            surface.DrawRect(0, 0, 5, h)
            draw.SimpleText("#" .. o.id .. "  " .. o.title, "ShipTech_UIBold", 16, 10, active and T.text or T.dim)
            local sub = (o.sys and Def(o.sys) and (Def(o.sys).name .. "  ·  ") or "") .. "Priorität: " .. pr[1] .. "  ·  von " .. (o.by or "?") .. "  ·  " .. os.date("%H:%M", o.t or 0)
            draw.SimpleText(sub, "ShipTech_UISmall", 16, 34, T.dim)
            draw.SimpleText(desc, "ShipTech_UISmall", 16, 56, T.text)
            local stt = st[1]
            if o.status == "accepted" and o.assignee then stt = stt .. " – " .. o.assignee end
            if o.status == "done" and o.report then stt = stt .. " – Bericht #" .. o.report end
            draw.SimpleText(stt, "ShipTech_UIBold", w - 14, 12, st[2], TEXT_ALIGN_RIGHT)
        end
        if active then
            local bar = vgui.Create("DPanel", card)
            bar:Dock(BOTTOM)
            bar:SetTall(30)
            bar:DockMargin(16, 0, 10, 6)
            bar.Paint = function() end
            local function btn(text, col, fn)
                local b = UI.Button(bar, text, col, fn)
                b:Dock(RIGHT)
                b:SetWide(150)
                b:DockMargin(6, 0, 0, 0)
                return b
            end
            if ShipTech.CanCreateOrders(ply) then
                btn("Stornieren", T.red, function() ShipTech.SendAction("order_cancel", ent, { id = o.id }) end)
            end
            if ShipTech.IsTechnician(ply) then
                btn("Bericht schreiben", T.green, function() UI.OpenReportForm(ent, o.sys, o.id) end)
                if o.status == "open" then
                    btn("Annehmen", T.accent, function() ShipTech.SendAction("order_accept", ent, { id = o.id }) end)
                end
            end
        end
    end
end

-- Berichte ----------------------------------------------------------------
local function ShowReport(r)
    local f = UI.Frame("WARTUNGSBERICHT #" .. r.id, 620, 560)
    local scroll = UI.Scroll(f)
    scroll:Dock(FILL)
    local function sec(title, text)
        UI.Header(scroll, title)
        UI.Note(scroll, (text and text ~= "") and text or "–", T.text)
    end
    UI.Note(scroll, "Verfasser: " .. (r.author or "?") .. "   ·   " .. os.date("%d.%m.%Y %H:%M", r.t or 0), T.dim)
    UI.Note(scroll, "System: " .. ((r.sys and Def(r.sys)) and Def(r.sys).name or "Allgemein") .. (r.order and ("   ·   Auftrag #" .. r.order) or ""), T.dim)
    sec("URSACHE / BEFUND", r.cause)
    sec("DURCHGEFÜHRTE MASSNAHMEN", r.measures)
    sec("BEMERKUNGEN", r.notes)
end

Builders.reports = function(content, ent)
    ShipTech.RequestData("reports")
    local top = vgui.Create("DPanel", content)
    top:Dock(TOP)
    top:SetTall(40)
    top:DockMargin(0, 0, 0, 8)
    top.Paint = function(s, w, h) draw.SimpleText("Wartungsberichte", "ShipTech_UIMed", 4, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
    if ShipTech.IsTechnician(LocalPlayer()) then
        local nb = UI.Button(top, "+ Bericht schreiben", T.green, function() UI.OpenReportForm(ent) end)
        nb:Dock(RIGHT)
        nb:SetWide(200)
    end
    local scroll = UI.Scroll(content)
    scroll:Dock(FILL)
    local reps = ShipTech.Data.reports or {}
    if #reps == 0 then UI.Note(scroll, "Noch keine Berichte vorhanden (oder keine Berechtigung).") end
    for _, r in ipairs(reps) do
        local row = vgui.Create("DButton", scroll)
        row:SetText("")
        row:Dock(TOP)
        row:SetTall(54)
        row:DockMargin(0, 0, 0, 4)
        local m = r.measures or ""
        if #m > 110 then m = string.sub(m, 1, 107) .. "..." end
        row.Paint = function(s, w, h)
            RBox(4, 0, 0, w, h, s:IsHovered() and T.panel2 or T.panel)
            draw.SimpleText("#" .. r.id .. "  " .. ((r.sys and Def(r.sys)) and Def(r.sys).name or "Allgemein"), "ShipTech_UIBold", 12, 8, T.text)
            draw.SimpleText(os.date("%d.%m. %H:%M", r.t or 0) .. "  ·  " .. (r.author or "?"), "ShipTech_UISmall", w - 12, 10, T.dim, TEXT_ALIGN_RIGHT)
            draw.SimpleText(m, "ShipTech_UISmall", 12, 30, T.dim)
        end
        row.DoClick = function() ShowReport(r) end
    end
end

-- Protokoll ---------------------------------------------------------------
Builders.logs = function(content)
    ShipTech.RequestData("logs")
    local top = vgui.Create("DPanel", content)
    top:Dock(TOP)
    top:SetTall(36)
    top:DockMargin(0, 0, 0, 8)
    top.Paint = function() end
    local filter = UI.TextEntry(top, "Filtern (System, Typ, Name ...)")
    filter:Dock(FILL)
    local refresh = UI.Button(top, "Aktualisieren", T.accent, function() ShipTech.RequestData("logs") end)
    refresh:Dock(RIGHT)
    refresh:SetWide(150)
    refresh:DockMargin(8, 0, 0, 0)

    local lv = UI.Scroll(content)
    lv:Dock(FILL)

    local KIND_COL = {
        SCHADEN = T.orange, AUSFALL = T.red, ALARM = T.red, ABSCHALTUNG = T.red, ["STÖRUNG"] = T.orange,
        REPARATUR = T.green, FREIGABE = T.green, WARTUNG = T.green, KALIBRIERUNG = T.green, TESTLAUF = T.green,
        EVENT = T.accent, NAVY = T.blue, AUFTRAG = T.blue, BERICHT = T.blue, REAKTOR = T.cyan, ENERGIE = T.cyan,
    }

    local function fill()
        lv:Clear()
        local q = string.lower(filter:GetValue() or "")
        local n = 0
        for _, e in ipairs(ShipTech.Data.logs or {}) do
            local line = string.lower((e.k or "") .. " " .. (e.m or "") .. " " .. (e.p or ""))
            if q == "" or string.find(line, q, 1, true) then
                n = n + 1
                local col = KIND_COL[e.k] or T.dim
                local row = vgui.Create("DPanel", lv)
                row:Dock(TOP)
                row:SetTall(40)
                row:DockMargin(0, 0, 6, 3)
                row.Paint = function(s, w, h)
                    ShipTech.Box(0, 0, w, h, T.panel)
                    surface.SetDrawColor(col)
                    surface.DrawRect(0, 0, 2, h)
                    draw.SimpleText(e.k or "", "ShipTech_UIBold", 12, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(e.m or "", "ShipTech_UISmall", 150, h / 2 - 7, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(os.date("%d.%m. %H:%M:%S", e.t or 0) .. (e.p and ("  //  " .. e.p) or ""), "ShipTech_UISub", 150, h / 2 + 9, T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
        end
        if n == 0 then UI.Note(lv, "Keine Einträge.") end
    end
    fill()
    filter.OnChange = fill
    hook.Add("ShipTech_DataUpdated", lv, function(self, kind) if kind == "logs" then fill() end end)
end

-- Navy / Brücke -----------------------------------------------------------
Builders.navy = function(content, ent)
    local S = ShipTech.State
    local navy = ShipTech.IsNavy(LocalPlayer())
    local scroll = UI.Scroll(content)
    scroll:Dock(FILL)
    if not navy then UI.Note(scroll, "Nur Navy-Personal kann hier Änderungen vornehmen.", T.red) end

    local function row(label, sub, btnText, btnCol, fn, enabled)
        local r = vgui.Create("DPanel", scroll)
        r:Dock(TOP)
        r:SetTall(50)
        r:DockMargin(0, 0, 0, 4)
        r.Paint = function(s, w, h)
            RBox(4, 0, 0, w, h, T.panel)
            draw.SimpleText(label, "ShipTech_UIBold", 12, 16, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local st, sc = sub()
            draw.SimpleText(st, "ShipTech_UISmall", 12, 36, sc, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local b = UI.Button(r, btnText, btnCol, fn)
        b:Dock(RIGHT)
        b:SetWide(200)
        b:DockMargin(0, 8, 8, 8)
        if enabled == nil then enabled = navy end
        b:SetEnabled(enabled)
        return r
    end

    UI.Header(scroll, "STARTFREIGABEN")
    for _, def in ipairs(ShipTech.Systems) do
        if def.navy then
            local sys = S.systems[def.id]
            row(def.name, function()
                local s2 = ShipTech.Sys(def.id)
                return s2.navyClear and "Freigabe erteilt" or "Keine Freigabe – System kann nicht hochgefahren werden", s2.navyClear and T.green or T.yellow
            end, sys.navyClear and "Freigabe entziehen" or "Freigabe erteilen", sys.navyClear and T.orange or T.green, function()
                ShipTech.SendAction("navy_clear", ent, { sys = def.id, val = not sys.navyClear })
            end)
        end
    end

    UI.Header(scroll, "GEFECHTSSTATUS")
    row("Gefechtsalarm", function()
        return ShipTech.State.combat and "AKTIV – Reparaturen unter Zeitdruck" or "Normalbetrieb", ShipTech.State.combat and T.red or T.green
    end, S.combat and "Aufheben" or "Auslösen", S.combat and T.green or T.red, function()
        ShipTech.SendAction("combat", ent, { val = not S.combat })
    end)

    UI.Header(scroll, ShipTech.LogiActive() and "NACHSCHUB (LOGISTIK)" or "ERSATZTEILE")
    row(ShipTech.LogiActive() and "Technisches Material" or "Ersatzteilbestand", function()
        local St = ShipTech.State
        if St.logi then
            return "Ersatzteile " .. (St.logi.stock.tech or 0) .. " · Kühlmittel " .. (St.logi.stock.coolant or 0) .. " · Elektronik " .. (St.logi.stock.electronics or 0),
                (St.logi.stock.tech or 0) > 50 and T.green or T.red
        end
        local txt = (St.parts or 0) .. " an Bord"
        if (St.partsETA or 0) > 0 then txt = txt .. " · Lieferung in " .. math.max(0, math.ceil(St.partsETA - CurTime())) .. " s" end
        return txt, (St.parts or 0) > 3 and T.green or T.red
    end, ShipTech.LogiActive() and "Antrag an Logistik" or "Ersatzteile anfordern", T.accent, function() ShipTech.SendAction("request_parts", ent) end,
        ShipTech.IsNavy(LocalPlayer()) or ShipTech.HasQual(LocalPlayer(), "freigabe"))

    UI.Header(scroll, "NOTFALLPROTOKOLLE")
    local info = UI.TextEntry(scroll, "Bereich / Zusatzinfo (z. B. Deck 4, Hangar)")
    info:Dock(TOP)
    info:DockMargin(0, 0, 0, 6)
    local ids = {}
    for id in pairs(ShipTech.AlarmTypes) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b) return ShipTech.AlarmTypes[a].prio < ShipTech.AlarmTypes[b].prio end)
    for _, id in ipairs(ids) do
        local def = ShipTech.AlarmTypes[id]
        local active = S.alarms and S.alarms[id]
        row(def.name, function()
            local a = ShipTech.State.alarms and ShipTech.State.alarms[id]
            return a and ("AKTIV" .. (a.auto and " (automatisch)" or "")) or def.protocol, a and T.red or T.dim
        end, active and "Aufheben" or "Auslösen", active and T.green or T.red, function()
            ShipTech.SendAction("alarm", ent, { id = id, val = not active, info = info:GetValue() })
        end)
    end
end

local function NavySig()
    local S = ShipTech.State
    local t = { S.combat, S.parts, S.partsETA }
    for _, def in ipairs(ShipTech.Systems) do t[#t + 1] = S.systems[def.id].navyClear end
    for id in pairs(S.alarms or {}) do t[#t + 1] = id end
    return util.TableToJSON(t)
end

-- Fortbildung -------------------------------------------------------------
Builders.staff = function(content, ent, f)
    ShipTech.RequestData("players")
    local left = UI.Scroll(content)
    left:Dock(LEFT)
    left:SetWide(300)
    left:DockMargin(0, 0, 10, 0)
    local right = UI.Scroll(content)
    right:Dock(FILL)

    local function showPlayer(p)
        right:Clear()
        if not p then
            UI.Note(right, "Spieler links auswählen.", T.dim)
            return
        end
        UI.Header(right, string.upper(p.name) .. "  ·  " .. (p.job or ""))
        local has = {}
        for _, q in ipairs(p.quals or {}) do has[q] = true end
        for _, q in ipairs(ShipTech.Qualifications) do
            local r = vgui.Create("DPanel", right)
            r:Dock(TOP)
            r:SetTall(52)
            r:DockMargin(0, 0, 0, 4)
            r.Paint = function(s, w, h)
                RBox(4, 0, 0, w, h, T.panel)
                draw.SimpleText(q.name, "ShipTech_UIBold", 12, 16, has[q.id] and T.green or T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(q.desc, "ShipTech_UISmall", 12, 36, T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            local b = UI.Button(r, has[q.id] and "Entziehen" or "Erteilen", has[q.id] and T.red or T.green, function()
                ShipTech.SendAction("qual_set", ent, { sid = p.sid, qual = q.id, val = not has[q.id] })
            end)
            b:Dock(RIGHT)
            b:SetWide(140)
            b:DockMargin(0, 9, 8, 9)
            if q.id == "ausbilder" and not ShipTech.IsAdmin(LocalPlayer()) then b:SetEnabled(false) end
        end
    end

    local function fill()
        left:Clear()
        local sel
        for _, p in ipairs(ShipTech.Data.players or {}) do
            local b = UI.Button(left, p.name, T.accent, function()
                f.StaffSel = p.sid
                showPlayer(p)
            end)
            b:Dock(TOP)
            b:DockMargin(0, 0, 0, 4)
            if p.sid == f.StaffSel then sel = p end
        end
        showPlayer(sel)
    end
    fill()
    hook.Add("ShipTech_DataUpdated", left, function(self, kind) if kind == "players" then fill() end end)
end

-- Startcheckliste ---------------------------------------------------------
Builders.checklist = function(content, ent)
    local navy = ShipTech.IsNavy(LocalPlayer())
    UI.Note(content, "Die Brücke bestätigt jeden Schritt der Reihe nach, sobald er erfüllt ist. Grün = bestätigt, gelb = als Nächstes zu bestätigen.", T.muted)

    local list = vgui.Create("DPanel", content)
    list:Dock(FILL)
    list.Paint = function(s, w, h)
        local S = ShipTech.State
        local n = (S.checklist and S.checklist.n) or 0
        local by = (S.checklist and S.checklist.by) or {}
        local rh = 56
        for i, st in ipairs(ShipTech.ChecklistSteps) do
            local y = (i - 1) * (rh + 6)
            local met = st.check(S)
            local done = i <= n
            local col = done and T.green or (i == n + 1 and T.accent or T.muted)
            ShipTech.Box(0, y, w, rh, done and ColorAlpha(T.green, 14) or T.panel)
            surface.SetDrawColor(col)
            surface.DrawRect(0, y, 2, rh)
            surface.DrawOutlinedRect(14, y + rh / 2 - 9, 18, 18, 1)
            if done then surface.DrawRect(18, y + rh / 2 - 5, 10, 10) end
            draw.SimpleText(i .. ".  " .. string.upper(st.name), "ShipTech_UIBold", 46, y + 18, done and T.text or T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local sub = done and ("Bestätigt von " .. (by[i] or "?")) or st.hint
            draw.SimpleText(sub, "ShipTech_UISmall", 46, y + 38, T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(met and "ERFÜLLT" or "NICHT ERFÜLLT", "ShipTech_UISub", w - 14, y + rh / 2, met and T.green or T.red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    local bottom = vgui.Create("DPanel", content)
    bottom:Dock(BOTTOM)
    bottom:SetTall(48)
    bottom.Paint = function() end
    local confirm = UI.Button(bottom, "NÄCHSTEN SCHRITT BESTÄTIGEN", T.green, function() ShipTech.SendAction("check_confirm", ent) end)
    confirm:Dock(FILL)
    confirm:SetEnabled(navy)
    confirm:SetTooltip(navy and "Bestätigt den nächsten Schritt, wenn er erfüllt ist." or "Nur Navy-Personal kann bestätigen.")
    local reset = UI.Button(bottom, "ZURÜCKSETZEN", T.red, function()
        Derma_Query("Startcheckliste zurücksetzen?", "Startcheckliste", "Ja", function() ShipTech.SendAction("check_reset", ent) end, "Abbrechen")
    end)
    reset.Solid = false
    reset:Dock(RIGHT)
    reset:SetWide(180)
    reset:DockMargin(8, 0, 0, 0)
    reset:SetEnabled(navy)
end

-- Hyperraum ---------------------------------------------------------------
local PHASES = {
    { "idle",      "BEREITSCHAFT" },
    { "calc",      "KURSBERECHNUNG" },
    { "ready",     "KURS BERECHNET" },
    { "routed",    "ENERGIE UMGELEITET" },
    { "countdown", "COUNTDOWN" },
    { "hyperspace", "IM HYPERRAUM" },
}

-- mode = "nav": Sprungpult der Navigationsstation, sonst Vorbereitung am Brückenterminal
Builders.hyper = function(content, ent, f, mode)
    local S = ShipTech.State
    local H = S.hyper or { phase = "idle" }
    local navy = ShipTech.IsNavy(LocalPlayer())

    local info = vgui.Create("DPanel", content)
    info:Dock(TOP)
    info:SetTall(240)
    info:DockMargin(0, 0, 0, 10)
    info.Paint = function(s, w, h)
        local St = ShipTech.State
        local Hh = St.hyper or {}
        ShipTech.Box(0, 0, w, h, T.panel)
        -- Phasenleiste
        local idx = 1
        for i, p in ipairs(PHASES) do if p[1] == Hh.phase then idx = i end end
        local pw = (w - 40) / #PHASES
        for i, p in ipairs(PHASES) do
            local x = 20 + (i - 1) * pw
            local col = (i < idx) and T.green or (i == idx and T.accent or T.muted)
            surface.SetDrawColor(col)
            surface.DrawRect(x, 22, pw - 8, 4)
            draw.SimpleText(p[2], "ShipTech_UISub", x, 38, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        draw.SimpleText("ZIEL", "ShipTech_UISub", 20, 70, T.dim)
        draw.SimpleText((Hh.dest and Hh.dest ~= "") and string.upper(Hh.dest) or "–", "ShipTech_UIMed", 20, 84, T.text)
        if Hh.phase == "calc" or Hh.phase == "countdown" then
            draw.SimpleText(math.max(0, math.ceil((Hh.t or 0) - CurTime())) .. " S", "ShipTech_UIBig", w - 20, 70, T.accent, TEXT_ALIGN_RIGHT)
        end
        -- Voraussetzungen
        local hd = St.systems.hyperdrive
        local checks = {
            { "Sensoren für Kursberechnung", (St.systems.sensors.eff or 0) >= C.Hyper.MinSensors },
            { "Hyperantrieb online", hd.on },
            { "Navy-Freigabe Hyperantrieb", hd.navyClear },
            { "Energie Hyperantrieb (" .. hd.alloc .. "/" .. C.Hyper.MinAlloc .. " E)", hd.alloc >= C.Hyper.MinAlloc },
            { "Effizienz Hyperantrieb (" .. math.Round((hd.eff or 0) * 100) .. " %)", (hd.eff or 0) >= C.Hyper.MinEfficiency },
            { "Triebwerke online", St.systems.engines.on },
            { "Wartungszustand Hyperantrieb " .. math.Round(hd.maint) .. " %", hd.maint >= 40 },
        }
        for i, c in ipairs(checks) do
            local col = c[2] and T.green or T.red
            local x = 20 + ((i - 1) % 2) * (w / 2)
            local y = 130 + math.floor((i - 1) / 2) * 26
            surface.SetDrawColor(col)
            surface.DrawRect(x, y - 4, 8, 8)
            draw.SimpleText(c[1], "ShipTech_UISmall", x + 16, y, c[2] and T.text or T.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local function btn(text, col, fn, enabled, tip)
        local b = UI.Button(content, text, col, fn)
        b:Dock(TOP)
        b:SetTall(46)
        b:DockMargin(0, 0, 0, 6)
        b:SetEnabled(enabled and navy)
        b:SetTooltip(navy and tip or "Nur Navy-Personal kann den Hyperraumsprung steuern.")
        return b
    end

    if mode == "nav" then
        -- Navigationsstation: hier (und nur hier) wird gesprungen
        UI.Header(content, "Sprungsteuerung")
        if H.phase == "hyperspace" then
            btn("RÜCKSTURZ AUS DEM HYPERRAUM", T.cyan, function() ShipTech.SendAction("hyper_exit", ent) end, true, "Verlässt den Hyperraum am Ziel.")
        elseif H.phase == "countdown" then
            local b = btn("COUNTDOWN ABBRECHEN", T.red, function() ShipTech.SendAction("hyper_abort", ent) end, true, "Bricht den laufenden Countdown ab.")
        else
            btn("HYPERRAUMSPRUNG AUSLÖSEN", T.accent, function()
                Derma_Query("Hyperraumsprung nach '" .. ((H.dest ~= "" and H.dest) or "?") .. "' auslösen?", "Hyperraumsprung", "Sprung auslösen", function()
                    ShipTech.SendAction("hyper_jump", ent)
                end, "Abbrechen")
            end, H.phase == "routed", H.phase == "routed" and "Startet den Countdown. Beschädigte oder schlecht gewartete Hyperantriebe können versagen."
                or "Erst am Brücken-Kontrollterminal Kurs berechnen und Energie umleiten.")
        end
        if H.phase == "routed" then
            local nb = btn("Notsprung (Sperren übergehen)", T.red, function()
                Derma_Query("NOTSPRUNG: Personen im Außeneinsatz werden zurückgelassen und sterben. Wirklich springen?", "Notsprung", "Notsprung", function()
                    ShipTech.SendAction("hyper_jump", ent, { force = true })
                end, "Abbrechen")
            end, true, "Springt auch, wenn z. B. noch Techniker im Außeneinsatz sind. Die Brücke erhält eine Warnung mit Namen.")
            nb.Solid = false
        end
        UI.Note(content, "Die Vorbereitung (Kurs berechnen, Energie umleiten) erfolgt am Brücken-Kontrollterminal. Ausgelöst wird ausschließlich an dieser Navigationsstation.", T.muted)
        return
    end

    -- Brückenterminal: nur Vorbereitung
    UI.Header(content, "Sprungvorbereitung")
    local dest = UI.TextEntry(content, "Ziel / Koordinaten eingeben (z. B. Coruscant, Sektor 7G)")
    dest:Dock(TOP)
    dest:DockMargin(0, 0, 0, 6)
    btn("1. KURS BERECHNEN", T.accent, function() ShipTech.SendAction("hyper_calc", ent, { dest = dest:GetValue() }) end,
        H.phase == "idle", "Minigame Befehlssequenz am Navigationscomputer. Dauer hängt von den Sensoren ab.")
    btn("2. ENERGIE UMLEITEN", T.accent, function() ShipTech.SendAction("hyper_route", ent) end,
        H.phase == "ready", "Leitet Energie von Geschützen, Schilden und Triebwerken zum Hyperantrieb um.")
    local b = btn("Vorbereitung abbrechen", T.red, function() ShipTech.SendAction("hyper_abort", ent) end,
        H.phase == "calc" or H.phase == "ready" or H.phase == "routed", "Verwirft Kurs und Energieumleitung.")
    b.Solid = false
    local hint = H.phase == "routed" and "SPRUNGBEREIT – der Sprung wird an der Navigationsstation ausgelöst." or
        "Nach der Vorbereitung wird der Sprung an der Navigationsstation ausgelöst."
    UI.Note(content, hint, H.phase == "routed" and T.green or T.muted)
end

-- Navigationsstation
function UI.OpenNav(ent)
    if IsValid(UI.Current) then UI.Current:Remove() end
    local f = UI.Frame(ent.PrintName, 1000, 760, "Hyperraumsprung", UI.FrameStatus)
    UI.Current = f
    BindToEnt(f, ent)
    local content = vgui.Create("DPanel", f)
    content:Dock(FILL)
    content.Paint = function() end
    local phase
    local function build()
        phase = (ShipTech.State.hyper or {}).phase
        content:Clear()
        Builders.hyper(content, ent, f, "nav")
    end
    build()
    hook.Add("ShipTech_StateUpdated", f, function()
        if (ShipTech.State.hyper or {}).phase ~= phase then build() end
    end)
end

-- Kühlung & Verschleiß --------------------------------------------------
Builders.cooling = function(content)
    local p = vgui.Create("DPanel", content)
    p:Dock(FILL)
    p.Paint = function(s, w, h)
        local S = ShipTech.State
        if not S or not S.cooling then return end
        local cw = (w - 4 * 12) / 5
        for i, c in ipairs(ShipTech.Circuits) do
            local st = S.cooling[c.id]
            local x = (i - 1) * (cw + 12)
            UI.Plate(x, 0, cw, 200, T.panel, T.line, 10, "tlbr")
            draw.SimpleText(string.upper(c.name), "ShipTech_UIBold", x + 12, 18, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            EOCUI.Aurebesh(c.name, "eocui.aure.small", x + 12, 32, ColorAlpha(T.text, 80))
            local col = st.level < C.Cooling.LowLevel and T.red or T.cyan
            draw.SimpleText(math.Round(st.level) .. "%", "ShipTech_UIBig", x + 12, 88, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            UI.DrawBar(x + 12, 128, cw - 24, 10, st.level / 100, col, "Füllstand")
            UI.DrawBar(x + 12, 166, cw - 24, 10, math.min(1, st.pressure / C.Cooling.MaxPressure), st.pressure >= C.Cooling.MaxPressure * 0.9 and T.red or T.accent, "Druck", tostring(math.Round(st.pressure)))
            draw.SimpleText("TEMP " .. math.Round(st.temp) .. " %", "ShipTech_UISub", x + 12, 188, T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        -- Verschleiß je System
        local y = 226
        draw.SimpleText("VERSCHLEISS & INSPEKTIONEN", "ShipTech_UIMed", 0, y, T.text)
        y = y + 40
        local colW = (w - 12) / 2
        for i, def in ipairs(ShipTech.Systems) do
            local sys = S.systems[def.id]
            local x = ((i - 1) % 2) * (colW + 12)
            local yy = y + math.floor((i - 1) / 2) * 44
            local wear = sys.wear or 1
            UI.Plate(x, yy, colW, 38, T.panel2, T.line, 6, "br")
            draw.SimpleText(string.upper(def.name), "ShipTech_UIBold", x + 12, yy + 19, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local od = ShipTech.OverdueCount(sys, def.id)
            draw.SimpleText(string.format("x%.2f", wear) .. "   ·   " .. string.format("%.1f h", sys.hours or 0) .. (od > 0 and ("   ·   " .. od .. " fällig") or ""),
                "ShipTech_UISub", x + colW - 12, yy + 19, wear >= 2 and T.red or (wear >= 1.4 and T.orange or T.muted), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
end

local TABS = {
    { id = "overview",  name = "Übersicht", wall = true },
    { id = "checklist", name = "Checkliste", wall = true, sig = function() return util.TableToJSON(ShipTech.State.checklist or {}) end },
    { id = "hyper",     name = "Hyperraum", sig = function() return (ShipTech.State.hyper or {}).phase end },
    { id = "power",     name = "Energie" },
    { id = "cooling",   name = "Kühlung" },
    { id = "orders",    name = "Aufträge", sig = function() return util.TableToJSON(ShipTech.State.orders or {}) end },
    { id = "reports",   name = "Berichte" },
    { id = "logs",      name = "Protokoll" },
    { id = "navy",      name = "Navy", sig = NavySig },
    { id = "staff",     name = "Fortbildungen", check = ShipTech.CanInstruct },
}

function UI.OpenTerminal(ent, tab)
    if IsValid(UI.Current) then UI.Current:Remove() end
    local f = UI.Frame(ent.PrintName, 1420, 860, ent.Purpose, UI.FrameStatus)
    UI.Current = f
    UI.AddHelpButton(f, 2)
    BindToEnt(f, ent)

    local content = vgui.Create("DPanel", f)
    content:Dock(FILL)
    content.Paint = function() end

    local btns = {}
    local curSig

    local function show(id)
        local def
        for _, t in ipairs(TABS) do if t.id == id then def = t end end
        if not def then return end
        f.Tab = id
        f.TabDef = def
        content:Clear()
        for tid, b in pairs(btns) do b.Active = (tid == id) end
        curSig = def.sig and def.sig() or nil
        Builders[id](content, ent, f)
    end

    local visible = {}
    for _, t in ipairs(TABS) do
        if (not t.check or t.check(LocalPlayer())) and (ent.ConsoleKind ~= "wall" or t.wall) then
            visible[#visible + 1] = t
        end
    end
    local _, tabBtns = UI.AddTabs(f, visible, function(id) show(id) end, nil, true)
    btns = tabBtns

    hook.Add("ShipTech_StateUpdated", f, function(self)
        local def = self.TabDef
        if def and def.sig then
            local s = def.sig()
            if s ~= curSig then show(def.id) end
        end
    end)

    show(btns[tab or ""] and tab or "overview")
end

---------------------------------------------------------------------------
-- Schildanzeige & Sektorverteiler
---------------------------------------------------------------------------
function UI.OpenShieldDisplay(ent)
    if IsValid(UI.Current) then UI.Current:Remove() end
    local f = UI.Frame("Schildstatus", 680, 760, "Deflektorschilde", UI.FrameStatus)
    UI.Current = f
    BindToEnt(f, ent)
    local p = vgui.Create("DPanel", f)
    p:Dock(FILL)
    p.Paint = function(s, w, h)
        RBox(6, 0, 0, w, h, T.panel)
        local r = math.min(w, h - 120) * 0.38
        ShipTech.DrawShieldGraphic(w / 2, 40 + r * 1.15, r, { bigFont = "ShipTech_UIBig", smallFont = "ShipTech_UIBold" })
        local S = ShipTech.State
        if not S then return end
        local sh = S.systems.shields
        local txt, col = ShipTech.StatusInfo("shields")
        local y = h - 70
        draw.SimpleText("Generator: " .. txt, "ShipTech_UIBold", 20, y, col)
        draw.SimpleText("Max. Kapazität: " .. ((S.mods and S.mods.shieldCap) or 0) .. " %", "ShipTech_UIBold", 20, y + 26, T.text)
        draw.SimpleText("Energie: " .. sh.alloc .. " E  ·  Temp. " .. math.Round(sh.heat) .. " %", "ShipTech_UIBold", w - 20, y, T.text, TEXT_ALIGN_RIGHT)
        local fn = { [0] = "Ausgeglichen", "Bug", "Steuerbord", "Heck", "Backbord" }
        draw.SimpleText("Verstärkt: " .. (fn[S.shields.focus or 0] or "–"), "ShipTech_UIBold", w - 20, y + 26, T.accent, TEXT_ALIGN_RIGHT)
    end
end

function UI.OpenBreaker(ent)
    if IsValid(UI.Current) then UI.Current:Remove() end
    local f = UI.Frame("Sektor-Energieverteiler", 540, 330, "Sektor " .. ent:GetSector())
    UI.Current = f
    BindToEnt(f, ent)
    local p = vgui.Create("DPanel", f)
    p:Dock(FILL)
    p.Paint = function(s, w, h)
        RBox(6, 0, 0, w, h, T.panel)
        local out = ShipTech.IsOutage(ent:GetSector())
        draw.SimpleText("Sektor: " .. ent:GetSector(), "ShipTech_UIMed", w / 2, 40, T.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(out and "STROMAUSFALL" or "VERSORGT", "ShipTech_UIBig", w / 2, 100, out and T.red or T.green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local b = UI.Button(p, "Sicherungen instand setzen   [Leitungen verbinden]", T.yellow, function()
        ShipTech.SendAction("breaker_repair", ent)
        f:Close()
    end)
    b:Dock(BOTTOM)
    b:DockMargin(12, 0, 12, 12)
    b:SetTall(42)
    b:SetEnabled(ShipTech.IsOutage(ent:GetSector()))
end

---------------------------------------------------------------------------
-- Öffnen
---------------------------------------------------------------------------
net.Receive("ShipTech_Open", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) or not ShipTech.State then return end
    local kind = ent.ConsoleKind
    if kind == "system" then
        UI.OpenSystem(ent)
    elseif kind == "terminal" then
        UI.OpenTerminal(ent, ent.DefaultTab)
    elseif kind == "display" then
        UI.OpenShieldDisplay(ent)    elseif kind == "wall" then
        UI.OpenTerminal(ent, "overview")    elseif kind == "nav" then
        UI.OpenNav(ent)
    elseif kind == "breaker" then
        UI.OpenBreaker(ent)
    end
end)
