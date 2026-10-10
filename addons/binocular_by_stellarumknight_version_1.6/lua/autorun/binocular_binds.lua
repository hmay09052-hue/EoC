-- Bind-Menü für Fernglas / Rangefinder
-- Öffnen per Chat: /binds (oder !binds) bzw. Konsole: binocular_binds

if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("Binocular_OpenBinds")

    hook.Add("PlayerSay", "Binocular_BindsCommand", function(ply, text)
        local cmd = string.lower(string.Trim(text))
        if cmd == "/binds" or cmd == "!binds" then
            net.Start("Binocular_OpenBinds")
            net.Send(ply)
            return ""
        end
    end)

    return
end

BinocularBinds = BinocularBinds or {}

-- Aktionen: global = Name der Variable aus config.lua, die binocular.lua abfragt
local ACTIONS = {
    { id = "toggle",      global = "KEY_TOGGLE",            group = "FERNGLAS",    label = "FERNGLAS / VISIER",      hint = "Fernglas bzw. Sonnenvisier an/aus" },
    { id = "zoom",        global = "KEY_ZOOM",              group = "FERNGLAS",    label = "HERANZOOMEN",            hint = "Gedrückt halten" },
    { id = "unzoom",      global = "KEY_UNZOOM",            group = "FERNGLAS",    label = "HERAUSZOOMEN",           hint = "Gedrückt halten" },
    { id = "night",       global = "KEY_NIGHT",             group = "SICHTMODI",   label = "NACHTSICHT",             hint = "Nur mit aktivem Fernglas" },
    { id = "thermal",     global = "KEY_THERMAL",           group = "SICHTMODI",   label = "WÄRMEBILD",              hint = "Nur mit aktivem Fernglas" },
    { id = "thermalmod",  global = "KEY_THERMAL_MODIFIER",  group = "SICHTMODI",   label = "WÄRMEBILD-MODIFIKATOR",  hint = "Optional – blockiert Nachtsicht solange gehalten", optional = true },
    { id = "rangefinder", global = "KEY_RANGEFINDER",       group = "RANGEFINDER", label = "RANGEFINDER",            hint = "Rangefinder an/aus" },
    { id = "lock",        global = "RangefinderNPCLockKey", group = "RANGEFINDER", label = "ZIEL ERFASSEN",          hint = "Gedrückt halten zum Aufschalten" },
}

-- Diese Paare dürfen absichtlich dieselbe Taste haben (Standard: beide J)
local SHARED_OK = { toggle = { rangefinder = true }, rangefinder = { toggle = true } }

-- Standardwerte aus config.lua (binocular.lua hat sie an dieser Stelle schon geladen)
BinocularBinds.Defaults = BinocularBinds.Defaults or {}
for _, a in ipairs(ACTIONS) do
    if BinocularBinds.Defaults[a.id] == nil then
        BinocularBinds.Defaults[a.id] = _G[a.global] or KEY_NONE
    end
end

local cvars_ = {}
for _, a in ipairs(ACTIONS) do
    cvars_[a.id] = CreateClientConVar("binocular_bind_" .. a.id, tostring(BinocularBinds.Defaults[a.id]), true, false)
end

local function GetBind(id)
    return cvars_[id]:GetInt()
end

local function ApplyBinds()
    for _, a in ipairs(ACTIONS) do
        local key = GetBind(a.id)
        if a.optional and key == KEY_NONE then
            _G[a.global] = nil
        else
            _G[a.global] = key
        end
    end
end
BinocularBinds.Apply = ApplyBinds

for _, a in ipairs(ACTIONS) do
    cvars.AddChangeCallback("binocular_bind_" .. a.id, ApplyBinds, "Binocular_Binds")
end

-- config.lua läuft als Autorun nach dieser Datei nochmal und setzt die Standardwerte zurück
timer.Simple(0, ApplyBinds)
hook.Add("InitPostEntity", "Binocular_ApplyBinds", ApplyBinds)

local function SetBind(id, key)
    RunConsoleCommand("binocular_bind_" .. id, tostring(key))
end

local function KeyName(key)
    if not key or key == KEY_NONE then return "—" end
    local name = input.GetKeyName(key)
    return name and string.upper(name) or ("#" .. key)
end

---------------------------------------------------------------------------
-- Design (wie Funk / Officer)
---------------------------------------------------------------------------
local C = {
    yellow  = Color(252, 178, 73),
    yellowD = Color(252, 178, 73, 56),
    yellowF = Color(252, 178, 73, 20),
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
if SYMUI then SYMUI.ApplyEoCPalette(C) end -- SymChars-Design

surface.CreateFont("BinocularBinds_Title",   { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 34, weight = 400, extended = true })
surface.CreateFont("BinocularBinds_Sub",     { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 12, weight = 600, extended = true })
surface.CreateFont("BinocularBinds_Section", { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 13, weight = 700, extended = true })
surface.CreateFont("BinocularBinds_Text",    { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 16, weight = 500, extended = true })
surface.CreateFont("BinocularBinds_Small",   { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 13, weight = 500, extended = true })
surface.CreateFont("BinocularBinds_Button",  { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 22, weight = 400, extended = true })
surface.CreateFont("BinocularBinds_Key",     { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 26, weight = 400, extended = true })

local function PlayClick()
    surface.PlaySound("buttons/button15.wav")
end

local function MakeButton(parent, label, onClick)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Label  = label
    b.Accent = C.yellow
    b.Paint = function(s, w, h)
        local hov = s:IsHovered()
        local tc
        if SYMUI then
            tc = SYMUI.PaintEoCButton(s, w, h, C.red)
        else
        local bg = s.Active and ColorAlpha(s.Accent, 26) or (hov and C.panel2 or C.panel)
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(s.Active and ColorAlpha(s.Accent, 185) or (hov and C.lineS or C.line))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if s.Active then
            surface.SetDrawColor(s.Accent)
            surface.DrawRect(0, h - 2, w, 2)
        end
        tc = s.Active and s.Accent or (hov and s.Accent or C.white)
        end
        draw.SimpleText(s.Label, s.Font or "BinocularBinds_Button", w / 2, h / 2, tc, 1, 1)
    end
    b.DoClick = function(s)
        PlayClick()
        if onClick then onClick(s) end
    end
    return b
end

local function Section(parent, text)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(30)
    p.Paint = function(_, w, h)
        surface.SetDrawColor(C.yellow)
        surface.DrawRect(0, 10, 2, h - 14)
        draw.SimpleText(text, "BinocularBinds_Section", 10, h / 2 + 3, C.soft, 0, 1)
    end
    return p
end

local function StyleScroll(scroll)
    local bar = scroll:GetVBar()
    bar:SetWide(4)
    bar.Paint = function(_, w, h) surface.SetDrawColor(C.line) surface.DrawRect(0, 0, w, h) end
    bar.btnUp.Paint = function() end
    bar.btnDown.Paint = function() end
    bar.btnGrip.Paint = function(_, w, h) surface.SetDrawColor(C.yellow) surface.DrawRect(0, 0, w, h) end
end

-- Liefert die Labels der Aktionen, die dieselbe Taste nutzen
local function Conflicts(a)
    local key = GetBind(a.id)
    if key == KEY_NONE then return nil end
    local out = {}
    for _, o in ipairs(ACTIONS) do
        if o ~= a and GetBind(o.id) == key and not (SHARED_OK[a.id] and SHARED_OK[a.id][o.id]) then
            out[#out + 1] = o.label
        end
    end
    return #out > 0 and out or nil
end

---------------------------------------------------------------------------
-- Menü
---------------------------------------------------------------------------
function BinocularBinds.OpenMenu()
    if IsValid(BinocularBinds.Frame) then BinocularBinds.Frame:Remove() end

    local W = math.min(720, ScrW() - 40)
    local H = math.min(640, ScrH() - 40)

    local capturing    -- id der Aktion, die gerade auf eine Taste wartet
    local heldAtStart = {}

    local f = vgui.Create("DFrame")
    BinocularBinds.Frame = f
    f:SetSize(W, H)
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:SetDraggable(true)
    f:DockPadding(20, 80, 20, 20)
    f:MakePopup()
    f:SetAlpha(0)
    f:AlphaTo(255, 0.15)

    f.Paint = function(s, w, h)
        if SYMUI then
            SYMUI.PaintWindow(w, h, nil, { header = 64 })
        else
        surface.SetDrawColor(C.bg)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.panel2)
        surface.DrawRect(0, 0, w, 62)
        surface.SetDrawColor(C.yellowD)
        surface.DrawRect(0, 62, w, 1)
        surface.SetDrawColor(C.yellow)
        surface.DrawRect(0, 62, 180, 2)

        surface.SetDrawColor(C.yellow)
        surface.DrawRect(0, 0, 14, 2)
        surface.DrawRect(0, 0, 2, 14)
        surface.DrawRect(w - 14, h - 2, 14, 2)
        surface.DrawRect(w - 2, h - 14, 2, 14)
        end

        draw.SimpleText("TASTENBELEGUNG", "BinocularBinds_Title", 20, 24, C.white, 0, 1)
        local subW = draw.SimpleText("OPTIK // FERNGLAS & RANGEFINDER", "BinocularBinds_Sub", 21, 46, C.yellow, 0, 1)
        if capturing then
            draw.SimpleText("//  TASTE DRÜCKEN  ·  ESC ABBRECHEN  ·  RÜCKTASTE LEEREN", "BinocularBinds_Sub", 21 + subW + 8, 46,
                ColorAlpha(C.yellow, 150 + math.sin(CurTime() * 6) * 105), 0, 1)
        end

        if not SYMUI then
            surface.SetDrawColor(C.line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
    end

    local close = MakeButton(f, "X", function() f:Close() end)
    close.Accent = C.red
    close:SetSize(34, 34)
    close:SetPos(W - 48, 14)

    local reset = MakeButton(f, "STANDARD", function()
        capturing = nil
        for _, a in ipairs(ACTIONS) do SetBind(a.id, BinocularBinds.Defaults[a.id]) end
    end)
    reset:SetSize(120, 34)
    reset:SetPos(W - 48 - 10 - 120, 14)

    local hint = vgui.Create("DLabel", f)
    hint:Dock(BOTTOM)
    hint:DockMargin(0, 10, 0, 0)
    hint:SetFont("BinocularBinds_Small")
    hint:SetTextColor(C.muted)
    hint:SetText("Linksklick: neu belegen   ·   Rechtsklick: Standard   ·   Einstellungen werden lokal gespeichert")

    local scroll = vgui.Create("DScrollPanel", f)
    scroll:Dock(FILL)
    StyleScroll(scroll)

    local lastGroup
    for _, a in ipairs(ACTIONS) do
        if a.group ~= lastGroup then
            lastGroup = a.group
            Section(scroll, a.group)
        end

        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 4, 6, 0)
        row:SetTall(54)
        row.Paint = function(s, w, h)
            local conf = Conflicts(a)
            local accent = conf and C.red or C.yellow
            surface.SetDrawColor((s:IsHovered() or s:IsChildHovered()) and C.panel2 or C.panel)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(ColorAlpha(accent, capturing == a.id and 22 or 8))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(accent)
            surface.DrawRect(0, 0, 3, h)
            surface.SetDrawColor(C.line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            draw.SimpleText(a.label, "BinocularBinds_Button", 16, h / 2 - 9, C.white, 0, 1)
            if conf then
                draw.SimpleText("Doppelt belegt mit: " .. table.concat(conf, ", "), "BinocularBinds_Small", 16, h / 2 + 12, C.red, 0, 1)
            else
                draw.SimpleText(a.hint, "BinocularBinds_Small", 16, h / 2 + 12, C.soft, 0, 1)
            end
        end

        local key = vgui.Create("DButton", row)
        key:SetText("")
        key:Dock(RIGHT)
        key:DockMargin(0, 9, 10, 9)
        key:SetWide(150)
        key.Paint = function(s, w, h)
            local active = capturing == a.id
            local hov = s:IsHovered()
            surface.SetDrawColor(active and C.yellowF or (hov and C.panel2 or C.bg))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(active and ColorAlpha(C.yellow, 185) or (hov and C.lineS or C.line))
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            if active then
                surface.SetDrawColor(C.yellow)
                surface.DrawRect(0, h - 2, w, 2)
                draw.SimpleText("…", "BinocularBinds_Key", w / 2, h / 2, ColorAlpha(C.yellow, 150 + math.sin(CurTime() * 6) * 105), 1, 1)
            else
                local k = GetBind(a.id)
                local col = k == KEY_NONE and C.muted or (Conflicts(a) and C.red or (hov and C.yellow or C.white))
                draw.SimpleText(KeyName(k), "BinocularBinds_Key", w / 2, h / 2, col, 1, 1)
            end
        end
        key.DoClick = function()
            PlayClick()
            if capturing == a.id then
                capturing = nil
                return
            end
            capturing = a.id
            heldAtStart = {}
            for k = KEY_FIRST + 1, KEY_LAST do
                if input.IsKeyDown(k) then heldAtStart[k] = true end
            end
        end
        key.DoRightClick = function()
            PlayClick()
            capturing = nil
            SetBind(a.id, BinocularBinds.Defaults[a.id])
        end
    end

    -- Tasten abfragen, solange eine Aktion auf Eingabe wartet
    f.Think = function(s)
        if not capturing then
            if input.IsKeyDown(KEY_ESCAPE) then
                gui.HideGameUI()
                s:Close()
            end
            return
        end
        for k = KEY_FIRST + 1, KEY_LAST do
            if input.IsKeyDown(k) then
                if not heldAtStart[k] then
                    if k == KEY_ESCAPE then
                        gui.HideGameUI()
                    elseif k == KEY_BACKSPACE then
                        SetBind(capturing, KEY_NONE)
                    else
                        SetBind(capturing, k)
                    end
                    surface.PlaySound("buttons/button14.wav")
                    capturing = nil
                    -- ESC soll das Menü nicht direkt mitschließen
                    s._blockEscUntilRelease = true
                    return
                end
            else
                heldAtStart[k] = nil
            end
        end
    end

    local baseThink = f.Think
    f.Think = function(s)
        if s._blockEscUntilRelease then
            if input.IsKeyDown(KEY_ESCAPE) then return end
            s._blockEscUntilRelease = nil
        end
        baseThink(s)
    end
end

net.Receive("Binocular_OpenBinds", BinocularBinds.OpenMenu)
concommand.Add("binocular_binds", BinocularBinds.OpenMenu)
