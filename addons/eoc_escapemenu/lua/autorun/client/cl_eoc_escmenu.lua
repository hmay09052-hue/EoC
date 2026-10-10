--[[-------------------------------------------------------------------------
    Echoes of Clones – Escape Menu (Client)
    Design: SymChars – kantige dunkle Platte links, BigNoodle-Menüpunkte,
    Akzent-Leuchtbalken am aktiven Menüpunkt. Farben und Schriften wie im TAB-Menü und HUD.
---------------------------------------------------------------------------]]

include("eoc_escmenu/config.lua")

local CFG = EOC_ESC.Config

local cvBlur  = CreateClientConVar("eoc_escmenu_blur", "1", true, false, "Hintergrund-Unschärfe im Escape-Menü")
local cvSound = CreateClientConVar("eoc_escmenu_sounds", "1", true, false, "Sounds im Escape-Menü")

-- Logo laden: erst aus materials/, sonst das im TAB-Menü eingebettete Logo (eoc_tab) mitbenutzen
local function LoadLogo()
    local mat = Material(CFG.Logo, "smooth mips")
    if not mat:IsError() then return mat end

    mat = Material("eoc/logo.png", "smooth mips")
    if not mat:IsError() then return mat end

    local tabLogo = EOCSB and EOCSB.Logo and EOCSB.Logo()
    return tabLogo or mat
end
local logoMat -- wird beim ersten Öffnen geladen (dann sind alle Workshop-Inhalte sicher gemountet)
local blurMat = Material("pp/blurscreen")

---------------------------------------------------------------------------
-- Helfer
---------------------------------------------------------------------------
local function S(px) return math.Round(px * (ScrH() / 1080)) end

local HEAD = "BigNoodleTitling"
local BODY = "Roboto Condensed"

local function CreateFonts()
    surface.CreateFont("EOC.Esc.Item",     { font = HEAD, size = S(34), weight = 500, extended = true })
    surface.CreateFont("EOC.Esc.Row",      { font = BODY, size = S(22), weight = 500, extended = true })
    surface.CreateFont("EOC.Esc.Head",     { font = HEAD, size = S(42), weight = 500, extended = true })
    surface.CreateFont("EOC.Esc.Sub",      { font = BODY, size = S(14), weight = 700, extended = true })
    surface.CreateFont("EOC.Esc.Name",     { font = BODY, size = S(18), weight = 700, extended = true })
    surface.CreateFont("EOC.Esc.Small",    { font = BODY, size = S(14), weight = 500, extended = true })
    surface.CreateFont("EOC.Esc.SmallB",   { font = BODY, size = S(14), weight = 800, extended = true })
end
CreateFonts()

-- Akzentfarbe live aus SymChars (wie TAB-Menü und HUD), sonst aus der Config
local function Accent()
    if SYMUI and SYMUI.Accent then return SYMUI.Accent() end
    return CFG.Accent
end

local function Snd(name)
    if cvSound:GetBool() then surface.PlaySound(name) end
end

local function ColA(c, a) return Color(c.r, c.g, c.b, a) end

local function LerpCol(t, a, b)
    return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b), Lerp(t, a.a or 255, b.a or 255))
end

local function DrawBlur(pnl, amount)
    if not cvBlur:GetBool() then return end
    local x, y = pnl:LocalToScreen(0, 0)
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(blurMat)
    for i = 1, 3 do
        blurMat:SetFloat("$blur", (i / 3) * amount)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end
end

-- Rahmen aus vier Rechtecken (kantig, auf ganzen Pixeln)
local function DrawOutline(x, y, w, h, col, t)
    t = t or 1
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, w, t)
    surface.DrawRect(x, y + h - t, w, t)
    surface.DrawRect(x, y + t, t, h - t * 2)
    surface.DrawRect(x + w - t, y + t, t, h - t * 2)
end

-- Akzent-Ecken wie bei den SymChars-Platten
local function DrawCorners(x, y, w, h, col, len, t)
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, len, t) surface.DrawRect(x, y, t, len)
    surface.DrawRect(x + w - len, y, len, t) surface.DrawRect(x + w - t, y, t, len)
    surface.DrawRect(x, y + h - t, len, t) surface.DrawRect(x, y + h - len, t, len)
    surface.DrawRect(x + w - len, y + h - t, len, t) surface.DrawRect(x + w - t, y + h - len, t, len)
end

-- Text mit Buchstabenabstand (zentriert)
local function DrawSpacedText(text, font, cx, cy, spacing, col)
    surface.SetFont(font)
    local chars, total = {}, 0
    for _, ch in utf8.codes(text) do
        local c = utf8.char(ch)
        local w = surface.GetTextSize(c)
        chars[#chars + 1] = { c, w }
        total = total + w + spacing
    end
    total = total - spacing
    local x = cx - total / 2
    for _, v in ipairs(chars) do
        draw.SimpleText(v[1], font, x, cy, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        x = x + v[2] + spacing
    end
end

-- Dünner gelber Leuchtstrich links neben dem Menüpunkt
local function DrawGlowBar(x, y, h, col, alpha)
    if alpha <= 1 then return end
    local bw = math.max(1, S(2))
    for i = 3, 1, -1 do
        surface.SetDrawColor(col.r, col.g, col.b, alpha * 0.06 * (4 - i))
        surface.DrawRect(x, y - i, bw + i * S(3), h + i * 2)
    end
    surface.SetDrawColor(col.r, col.g, col.b, alpha)
    surface.DrawRect(x, y, bw, h)
end

---------------------------------------------------------------------------
-- Menüpunkt (nur Text)
---------------------------------------------------------------------------
local function MenuItem(parent, text, onClick, danger)
    local item = vgui.Create("DButton", parent)
    item:Dock(TOP)
    item:SetTall(S(58))
    item:SetText("")
    item.hv = 0

    function item:OnCursorEntered() Snd("ui/buttonrollover.wav") end
    function item:DoClick() Snd("ui/buttonclickrelease.wav") onClick(self) end

    function item:Paint(w, h)
        self.hv = Lerp(FrameTime() * 14, self.hv, self:IsHovered() and 1 or 0)
        local hv = self.hv

        local base = danger and CFG.Danger or CFG.Text
        local act  = danger and Color(255, 130, 130) or CFG.TextActive
        local col  = LerpCol(hv, base, act)

        DrawGlowBar(0, S(14), h - S(28), danger and CFG.Danger or Accent(), 255 * hv)
        draw.SimpleText(text, "EOC.Esc.Item", S(22) + S(12) * hv, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    return item
end

local function Gap(parent, h)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(S(h or 26))
    p.Paint = nil
    return p
end

---------------------------------------------------------------------------
-- Einstellungen (gleicher Stil: Text links, Wert rechts)
---------------------------------------------------------------------------
local function SettingToggle(parent, label, convar)
    local cv = GetConVar(convar)
    local row = vgui.Create("DButton", parent)
    row:Dock(TOP)
    row:SetTall(S(52))
    row:SetText("")
    row.hv, row.on = 0, (cv and cv:GetBool()) and 1 or 0

    function row:OnCursorEntered() Snd("ui/buttonrollover.wav") end
    function row:DoClick()
        if not cv then return end
        Snd("ui/buttonclickrelease.wav")
        RunConsoleCommand(convar, cv:GetBool() and "0" or "1")
    end

    function row:Paint(w, h)
        self.hv = Lerp(FrameTime() * 14, self.hv, self:IsHovered() and 1 or 0)
        self.on = Lerp(FrameTime() * 14, self.on, (cv and cv:GetBool()) and 1 or 0)

        DrawGlowBar(0, S(13), h - S(26), Accent(), 255 * self.hv)
        local col = cv and LerpCol(self.hv, CFG.Text, CFG.TextActive) or CFG.TextDim
        draw.SimpleText(label, "EOC.Esc.Row", S(22) + S(12) * self.hv, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Schalter
        local tw, th = S(38), S(18)
        local tx, ty = w - tw, h / 2 - th / 2
        surface.SetDrawColor(LerpCol(self.on, Color(255, 255, 255, 18), ColA(Accent(), 60)))
        surface.DrawRect(tx, ty, tw, th)
        DrawOutline(tx, ty, tw, th, LerpCol(self.on, Color(255, 255, 255, 50), Accent()))
        local k = th - S(6)
        surface.SetDrawColor(LerpCol(self.on, CFG.TextDim, Accent()))
        surface.DrawRect(tx + S(3) + (tw - k - S(6)) * self.on, ty + S(3), k, k)
    end
    return row
end

local function SettingSlider(parent, label, convar, min, max, decimals)
    local cv = GetConVar(convar)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(S(70))
    row:DockPadding(S(22), S(40), 0, S(12))
    row.hv = 0

    function row:Paint(w, h)
        self.hv = Lerp(FrameTime() * 14, self.hv, (self:IsChildHovered() or self:IsHovered()) and 1 or 0)
        DrawGlowBar(0, S(12), h - S(24), Accent(), 255 * self.hv)
        draw.SimpleText(label, "EOC.Esc.Row", S(22), S(22), cv and CFG.Text or CFG.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local val = cv and tostring(math.Round(cv:GetFloat(), decimals)) or "-"
        draw.SimpleText(val, "EOC.Esc.Row", w, S(22), Accent(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local slider = vgui.Create("DSlider", row)
    slider:Dock(FILL)
    slider:SetLockY(0.5)
    slider:SetSlideX(cv and math.Clamp((cv:GetFloat() - min) / (max - min), 0, 1) or 0)
    slider.Knob:SetSize(S(12), S(12))
    function slider:Paint(w, h)
        surface.SetDrawColor(255, 255, 255, 25)
        surface.DrawRect(0, h / 2 - 1, w, S(2))
        surface.SetDrawColor(Accent())
        surface.DrawRect(0, h / 2 - 1, w * self:GetSlideX(), S(2))
    end
    function slider.Knob:Paint(w, h)
        surface.SetDrawColor(self:IsHovered() and Accent() or CFG.TextActive)
        surface.DrawRect(0, 0, w, h)
    end
    function slider:TranslateValues(x, y)
        local v = math.Round(min + (max - min) * x, decimals)
        if cv and v ~= math.Round(cv:GetFloat(), decimals) then RunConsoleCommand(convar, tostring(v)) end
        return x, y
    end
    return row
end

---------------------------------------------------------------------------
-- Menü
---------------------------------------------------------------------------
local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self.openFrac = 0
    self.closing = false

    local w = math.max(S(CFG.MinWidth), math.Round(ScrW() * CFG.WidthFrac))
    local m = S(CFG.Margin)
    self.sideW, self.margin = w, m

    -- schwebendes Glas-Panel mit Abstand zum Bildschirmrand
    local side = vgui.Create("DPanel", self)
    side:SetSize(w, ScrH() - m * 2)
    side:SetPos(-w - m, m)
    side:DockPadding(S(48), S(56), S(48), S(36))
    self.Side = side

    function side:Paint(pw, ph)
        DrawBlur(self, 6)
        surface.SetDrawColor(CFG.Background)
        surface.DrawRect(0, 0, pw, ph)
        DrawOutline(0, 0, pw, ph, CFG.Border)
        local acc = Accent()
        surface.SetDrawColor(acc)
        surface.DrawRect(0, 0, S(4), ph)
        DrawCorners(0, 0, pw, ph, acc, S(22), S(3))
    end

    -- Logo + Untertitel
    if not logoMat or logoMat:IsError() then logoMat = LoadLogo() end
    local logoW = w - S(96)
    local ratio = (logoMat:Width() > 0 and logoMat:Height() > 0) and logoMat:Width() / logoMat:Height() or 2.5
    local logoH = math.Round(logoW / ratio)
    if logoH > S(CFG.LogoMaxH) then
        logoH = S(CFG.LogoMaxH)
        logoW = math.Round(logoH * ratio)
    end
    local header = vgui.Create("DPanel", side)
    header:Dock(TOP)
    local hasSub = CFG.Subtitle and CFG.Subtitle ~= ""
    header:SetTall(logoH + (hasSub and (S(10) + S(16) + S(56)) or S(48)))
    function header:Paint(pw)
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(logoMat)
        surface.DrawTexturedRect((pw - logoW) / 2, 0, logoW, logoH)
        if hasSub then
            DrawSpacedText(CFG.Subtitle, "EOC.Esc.Sub", pw / 2, logoH + S(18), S(4), CFG.TextDim)
        end
    end

    self:BuildFooter(side)

    local content = vgui.Create("DScrollPanel", side)
    content:Dock(FILL)
    local vbar = content:GetVBar()
    vbar:SetWide(S(3))
    vbar:SetHideButtons(true)
    function vbar:Paint() end
    function vbar.btnGrip:Paint(pw, ph) surface.SetDrawColor(255, 255, 255, 30) surface.DrawRect(0, 0, pw, ph) end
    self.Content = content

    self:ShowPage("main")
    Snd("ui/buttonclick.wav")
end

function PANEL:BuildFooter(side)
    local footer = vgui.Create("DPanel", side)
    footer:Dock(BOTTOM)
    footer:SetTall(S(67))

    function footer:Paint(pw, ph)
        surface.SetDrawColor(255, 255, 255, 20)
        surface.DrawRect(0, 0, pw, 1)

        local lp = LocalPlayer()
        local cy = S(20) + S(23)
        local x = S(46) + S(14)
        draw.SimpleText(IsValid(lp) and lp:Nick() or "", "EOC.Esc.Name", x, cy - S(1), CFG.TextActive, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(("Ping %d ms"):format(IsValid(lp) and lp:Ping() or 0), "EOC.Esc.Small", x, cy + S(3), CFG.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        draw.SimpleText(("%d / %d SPIELER"):format(player.GetCount(), game.MaxPlayers()), "EOC.Esc.SmallB", pw, cy - S(2), Accent(), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(string.upper(game.GetMap()), "EOC.Esc.SmallB", pw, cy + S(3), CFG.TextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    local avBg = vgui.Create("DPanel", footer)
    avBg:SetPos(0, S(20))
    avBg:SetSize(S(46), S(46))
    function avBg:Paint(pw, ph) surface.SetDrawColor(255, 255, 255, 15) surface.DrawRect(0, 0, pw, ph) DrawOutline(0, 0, pw, ph, ColA(Accent(), 120)) end

    local av = vgui.Create("AvatarImage", avBg)
    av:SetPos(S(2), S(2))
    av:SetSize(S(42), S(42))
    av:SetPlayer(LocalPlayer(), 64)
end

function PANEL:ShowPage(page)
    local c = self.Content
    c:Clear()
    local canvas = c:GetCanvas()
    canvas:SetAlpha(0)
    canvas:AlphaTo(255, 0.2, 0)

    local menu = self

    if page == "main" then
        MenuItem(c, "Weiterspielen", function() menu:Close() end)
        MenuItem(c, "Einstellungen", function() menu:ShowPage("settings") end)
        if CFG.Discord ~= ""  then MenuItem(c, "Discord", function() gui.OpenURL(CFG.Discord) end) end
        if CFG.Workshop ~= "" then MenuItem(c, "Workshop-Kollektion", function() gui.OpenURL(CFG.Workshop) end) end
        if CFG.Website ~= ""  then MenuItem(c, "Webseite", function() gui.OpenURL(CFG.Website) end) end
        Gap(c)
        MenuItem(c, "Erneut verbinden", function() RunConsoleCommand("retry") end)
        MenuItem(c, "Server verlassen", function() menu:ShowPage("confirm_leave") end, true)

    elseif page == "settings" then
        MenuItem(c, "Zurück", function() menu:ShowPage("main") end)
        Gap(c, 14)
        SettingToggle(c, "Hintergrund-Unschärfe", "eoc_escmenu_blur")
        SettingToggle(c, "Menü-Sounds", "eoc_escmenu_sounds")
        for _, s in ipairs(CFG.Settings or {}) do
            if s.type == "checkbox" then
                SettingToggle(c, s.label, s.convar)
            elseif s.type == "slider" then
                SettingSlider(c, s.label, s.convar, s.min or 0, s.max or 1, s.decimals or 0)
            end
        end
        Gap(c, 14)
        MenuItem(c, "Spieloptionen", function()
            menu:Close()
            gui.ActivateGameUI()
            RunConsoleCommand("gamemenucommand", "openoptionsdialog")
        end)

    elseif page == "confirm_leave" then
        local head = vgui.Create("DPanel", c)
        head:Dock(TOP)
        head:SetTall(S(74))
        function head:Paint(w, h)
            draw.SimpleText("Server verlassen?", "EOC.Esc.Head", S(22), S(22), CFG.TextActive, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Du wirst vom Server getrennt.", "EOC.Esc.Name", S(22), S(54), CFG.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        Gap(c, 14)
        MenuItem(c, "Ja, verlassen", function() RunConsoleCommand("disconnect") end, true)
        MenuItem(c, "Abbrechen", function() menu:ShowPage("main") end)
    end
end

function PANEL:Think()
    local target = self.closing and 0 or 1
    self.openFrac = math.Approach(self.openFrac, target, FrameTime() * 5)
    local e = 1 - (1 - self.openFrac) ^ 3 -- ease-out
    self.Side:SetX(-self.sideW - self.margin + (self.sideW + self.margin * 2) * e)

    if self.closing and self.openFrac <= 0 then self:Remove() end
end

function PANEL:OnMousePressed()
    -- Klick neben das Menü = weiterspielen
    self:Close()
end

function PANEL:Paint(w, h)
    local e = 1 - (1 - self.openFrac) ^ 3
    surface.SetDrawColor(ColA(CFG.ScreenDim, CFG.ScreenDim.a * e))
    surface.DrawRect(0, 0, w, h)

    -- weicher Schatten unter dem Panel
    local sx, sy = self.Side:GetPos()
    local sw, sh = self.Side:GetSize()
    for i = 1, 6 do
        local o = S(4) * i
        surface.SetDrawColor(0, 0, 0, 22 * e * (1 - i / 7))
        surface.DrawRect(sx - o, sy - o + S(10), sw + o * 2, sh + o * 2)
    end
end

function PANEL:Close()
    if self.closing then return end
    self.closing = true
    self:SetMouseInputEnabled(false)
    self:KillFocus()
    Snd("ui/buttonclickrelease.wav")
end

vgui.Register("EOC.EscMenu", PANEL, "EditablePanel")

---------------------------------------------------------------------------
-- ESC abfangen
---------------------------------------------------------------------------
function EOC_ESC.Open()
    if IsValid(EOC_ESC.Menu) and not EOC_ESC.Menu.closing then return end
    if IsValid(EOC_ESC.Menu) then EOC_ESC.Menu:Remove() end
    EOC_ESC.Menu = vgui.Create("EOC.EscMenu")
end

function EOC_ESC.Toggle()
    if IsValid(EOC_ESC.Menu) and not EOC_ESC.Menu.closing then
        EOC_ESC.Menu:Close()
    else
        EOC_ESC.Open()
    end
end

hook.Add("OnPauseMenuShow", "EOC.EscMenu", function()
    if CFG.ShiftOpensLegacyMenu and input.IsKeyDown(KEY_LSHIFT) then return end
    EOC_ESC.Toggle()
    return false
end)

-- GMod-Hinweis "Du kannst das Öffnen des Hauptmenüs erzwingen ..." unterdrücken
hook.Add("OnPauseMenuBlockedTooManyTimes", "EOC.EscMenu", function() return true end)

hook.Add("OnScreenSizeChanged", "EOC.EscMenu", function()
    CreateFonts()
    if IsValid(EOC_ESC.Menu) then EOC_ESC.Menu:Remove() end
end)

concommand.Add("eoc_escmenu", EOC_ESC.Toggle)
