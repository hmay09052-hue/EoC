--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Hauptmenü (Menü-Taste, Standard F4, oder /chars)
    Tabs: CHARAKTERE, EINHEITEN, VERWALTUNG, DOKUMENTE, ADMIN
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S

local function BarH() return S(92) end

UI.pages = UI.pages or {}

-- page = { id, name, order, visible = function() end, build = function(parent, opts) end, needsChar = bool }
function UI.RegisterPage(page)
    UI.pages[page.id] = page
end

local function SortedPages()
    local list = {}
    local hasChar = UI.LocalChar() ~= nil
    for _, page in pairs(UI.pages) do
        local ok = (not page.needsChar or hasChar) and (not page.visible or page.visible())
        if ok then list[#list + 1] = page end
    end
    table.sort(list, function(a, b) return (a.order or 0) < (b.order or 0) end)
    return list
end

---------------------------------------------------------------------------------------------------------------
-- Musik
---------------------------------------------------------------------------------------------------------------
local music

local function StopMusic()
    if music then
        local m = music
        pcall(function() m:Stop() end)
    end
    music = nil
end

local function PlayMusic()
    StopMusic()
    if not symchars.Config("usemusic") or cookie.GetNumber("symchars_music", 1) == 0 then return end
    local url = string.Trim(tostring(symchars.Config("musicurl") or ""))
    if url == "" then return end
    local vol = math.Clamp((symchars.Config("musicvolume") or 25) / 100, 0, 1)
    if string.match(url, "^https?://") then
        sound.PlayURL(url, "noblock", function(station)
            if not IsValid(station) then return end
            if not IsValid(UI.menu) then station:Stop() return end
            station:SetVolume(vol)
            station:EnableLooping(true)
            station:Play()
            music = station
        end)
    else
        local snd = CreateSound(LocalPlayer(), url)
        if snd then
            snd:PlayEx(vol, 100)
            music = snd
        end
    end
end

---------------------------------------------------------------------------------------------------------------
-- Menü
---------------------------------------------------------------------------------------------------------------
local MENU = {}

function MENU:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()
    self:SetKeyboardInputEnabled(true)
    self.openTime = RealTime()

    self.tabs = vgui.Create("symchars.Tabs", self)
    self.tabs:SetBackground(false)
    self.tabs.OnChange = function(_, id) self:ShowPage(id) end

    self.content = vgui.Create("DPanel", self)
    self.content.Paint = nil

    self.close = UI.Button(self, "", "default", function() self:TryClose() end)
    self.close:SetFont("symchars.button.small")
    self.close:SetIcon("close")

    -- Name + Rang oben rechts (fängt keine Klicks ab, liegt nie über den Reitern)
    self.charInfo = vgui.Create("DPanel", self)
    self.charInfo:SetMouseInputEnabled(false)
    self.charInfo.Paint = function(_, w, h)
        local char = UI.LocalChar()
        if not char then return end
        local faction = char:GetFaction()
        local rank = char:GetRankData()
        UI.Box(0, S(14), 1, h - S(28), Color(255, 255, 255, 30))
        local name = symchars.utils.BuildDisplayName(char)
        UI.TextFit(name, "symchars.body.bold", w, h / 2 - S(2), UI.col.text, w - S(14), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        local sub = (rank and rank.name or "") .. ((rank and faction) and "  ·  " or "") .. (faction and faction.name or "")
        UI.TextFit(sub, "symchars.tiny", w, h / 2 + S(2), UI.Readable(UI.UnitColor(char)), w - S(14), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        UI.Aurebesh(name, "symchars.aure.small", w, h / 2 + S(22), UI.Alpha(UI.col.dim, 90), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, w - S(14))
    end

    self:RebuildTabs()
    UI.menu = self

    hook.Add("symchars_char_updated", self, function(s, char)
        if char and char.charID == LocalPlayer():GetCharacterID() then s:RebuildTabs(true) end
    end)
    hook.Add("symchars_settings_changed", self, function(s) s:RebuildTabs(true) end)

    PlayMusic()
end

function MENU:RebuildTabs(keep)
    local list = {}
    for _, page in ipairs(SortedPages()) do list[#list + 1] = { id = page.id, name = page.name, badge = page.badge and page.badge() } end
    local active = self.tabs:GetActive()
    self.tabs:SetTabs(list)
    if keep and active then
        local still = false
        for _, t in ipairs(list) do if t.id == active then still = true end end
        if still then self.tabs:SetActive(active, true) return end
    end
end

function MENU:PerformLayout(w, h)
    local bar = BarH()
    local bh = S(44)
    local by = math.floor((bar - bh) / 2)
    local x = w - S(40)

    self.close:SetSize(S(160), bh)
    x = x - S(160)
    self.close:SetPos(x, by)

    local infoW = math.min(S(300), math.floor(w * 0.18))
    x = x - S(16) - infoW
    self.charInfo:SetPos(x, 0)
    self.charInfo:SetSize(infoW, bar)

    self.tabs:SetPos(S(150), 0)
    self.tabs:SetSize(math.max(S(200), x - S(16) - S(150)), bar)

    self.content:SetPos(S(150), bar + S(36))
    self.content:SetSize(w - S(150) - S(56), h - bar - S(36) - S(60))

    if IsValid(self.play) then
        self.play:SetSize(S(320), S(60))
        self.play:SetPos(math.floor((w - S(320)) / 2), math.floor((h - S(60)) / 2))
    end
end

function MENU:ShowPage(id, opts)
    local page = UI.pages[id]
    if not page then return end
    -- Startbildschirm verlassen
    if IsValid(self.play) then
        self.play:Remove()
        self.play = nil
        self.tabs:SetVisible(true)
        self.charInfo:SetVisible(true)
        self:InvalidateLayout()
    end
    if page.needsChar and not UI.LocalChar() then id = "characters" page = UI.pages.characters end
    self.tabs:SetActive(id, true)
    self.content:Clear()
    self.pageId = id
    UI.lastPage = id
    local ok, err = pcall(page.build, self.content, opts or {})
    if not ok then
        ErrorNoHaltWithStack("[SymChars] Fehler beim Aufbau von '" .. id .. "': " .. tostring(err) .. "\n")
    end
end

-- Startbildschirm beim ersten Beitritt: nur der Spielen-Knopf in der Bildschirmmitte
function MENU:ShowSplash()
    self.tabs:SetVisible(false)
    self.charInfo:SetVisible(false)
    self.content:Clear()
    if IsValid(self.play) then self.play:Remove() end
    self.play = UI.Button(self, "Spielen", "primary", function()
        self:RebuildTabs()
        self:ShowPage("characters")
    end)
    self.play:SetFont("symchars.h2")
    self:InvalidateLayout()
end

function MENU:CanClose()
    return UI.LocalChar() ~= nil
end

function MENU:TryClose()
    if self:CanClose() then
        self:Remove()
    else
        UI.Confirm("Server verlassen", "Du hast noch keinen Charakter ausgewählt. Möchtest du den Server verlassen?", function()
            RunConsoleCommand("disconnect")
        end, nil, "Verlassen")
    end
end

-- Menü-Taste (Standard F4) schließt das offene Menü. Solange das Menü offen ist, laufen keine Binds und
-- PlayerButtonDown nicht zuverlässig, deshalb wird die Taste hier direkt abgefragt (nur beim Drücken, nicht beim Halten).
function MENU:CheckMenuKey()
    local key = symchars.Config("openkey") or 0
    if key == 0 then return end
    local down = input.IsKeyDown(key)
    local was = self._menuKeyDown
    self._menuKeyDown = down
    if was == nil or was or not down then return end -- erster Frame (Taste vom Öffnen noch gedrückt) oder keine neue Taste
    local focus = vgui.GetKeyboardFocus()
    if IsValid(focus) and focus:GetClassName() == "TextEntry" then return end -- beim Tippen nicht schließen
    UI.ToggleMenu()
end

function MENU:Think()
    self:CheckMenuKey()
    local can = self:CanClose()
    if self.close then
        self.close:SetText(can and "Schließen" or "Verlassen")
    end
    if self._couldClose ~= can then
        self._couldClose = can
        self:InvalidateLayout()
    end
end

function MENU:OnRemove()
    StopMusic()
    if UI.menu == self then UI.menu = nil end
end

function UI.CloseHint()
    local key = symchars.Config("openkey") or 0
    local name = key ~= 0 and input.GetKeyName(key)
    return name and ("ESC / " .. string.upper(name) .. "  SCHLIESSEN") or "ESC  SCHLIESSEN"
end

function MENU:Paint(w, h)
    local bg = symchars.Config("backgroundurl") or ""
    local drewImage = bg ~= "" and UI.DrawImage(bg, 0, 0, w, h, color_white, "cover")
    if not drewImage then
        if symchars.Config("blurbackground") ~= false then UI.Blur(self, 6) end
        UI.Box(0, 0, w, h, Color(4, 6, 9, 120))
    end
    UI.Box(0, 0, w, h, Color(3, 5, 8, symchars.Config("darkoverlay") or 205))

    -- Vignette & Kanten
    UI.Gradient(0, 0, w * 0.35, h, Color(0, 0, 0, 160), "right")
    UI.Gradient(0, h * 0.7, w, h * 0.3, Color(0, 0, 0, 120), "up")
    UI.Rail(w, h)

    -- schwarze Kopfleiste mit orangefarbener Kante
    local bar = BarH()
    if self.tabs:IsVisible() then
        UI.Box(0, 0, w, bar, Color(0, 0, 0, 238))
        UI.Box(0, bar - 1, w, 1, UI.Accent(110))
        UI.Gradient(0, bar, w, S(18), Color(0, 0, 0, 140), "down")
        UI.Aurebesh(symchars.Config("communityName") or "", "symchars.aure.small", S(150) - S(26), bar / 2, UI.Alpha(UI.col.dim, 70), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, S(90))
    end

    -- Startbildschirm: nur der Spielen-Knopf
    if IsValid(self.play) then return end

    -- feines Raster unten rechts (Kraken-Stil)
    surface.SetDrawColor(255, 255, 255, 6)
    for x = w - S(420), w - S(40), S(24) do surface.DrawRect(x, h - S(52), 1, S(10)) end

    -- Fußzeile
    UI.Box(S(150), h - S(46), w - S(206), 1, UI.col.line)
    UI.Text(self:CanClose() and UI.CloseHint() or "WÄHLE ODER ERSTELLE EINEN CHARAKTER", "symchars.h4", S(150), h - S(38), UI.col.muted)
    UI.Aurebesh("SymChars " .. symchars.version, "symchars.aure.small", w - S(56), h - S(34), UI.Alpha(UI.col.dim, 90), TEXT_ALIGN_RIGHT)
end

vgui.Register("symchars.Menu", MENU, "EditablePanel")

---------------------------------------------------------------------------------------------------------------
-- Öffnen
---------------------------------------------------------------------------------------------------------------
function UI.OpenMenu(tab, opts, splash)
    if IsValid(UI.menu) then
        if tab then UI.menu:RebuildTabs(true) UI.menu:ShowPage(tab, opts) end
        return UI.menu
    end
    local menu = vgui.Create("symchars.Menu")
    UI.Sound("open")
    if splash then
        menu:ShowSplash()
    else
        menu:ShowPage(tab or UI.lastPage or "characters", opts)
    end
    return menu
end

-- Auf/zu mit kurzer Sperre, damit ein Tastendruck nicht doppelt zählt
local nextToggle = 0
function UI.ToggleMenu()
    if nextToggle > RealTime() then return end
    nextToggle = RealTime() + 0.3
    if IsValid(UI.menu) then
        if UI.menu:CanClose() then UI.menu:Remove() end
    else
        UI.OpenMenu()
    end
end

function UI.CloseMenu()
    if IsValid(UI.menu) then UI.menu:Remove() end
end
symchars.RemoveMenu = UI.CloseMenu

concommand.Add("symchars_open", function() UI.OpenMenu("characters") end)

symchars.net.Receive("menu_open", function(data)
    data = istable(data) and data or {}
    -- auf/zu
    if data.toggle then UI.ToggleMenu() return end
    local opts = { unit = data.unit, doc = data.doc }
    UI.OpenMenu(data.tab or "characters", opts)
end)

symchars.net.Receive("ready", function(data)
    symchars.clientReady = true
    if istable(data) and data.first and not UI.LocalChar() then
        timer.Simple(0.5, function() UI.OpenMenu("characters", nil, true) end)
    end
end)

hook.Add("InitPostEntity", "symchars_hello", function()
    timer.Simple(1, function() symchars.net.SendToServer("hello", {}) end)
end)

-- Menü-Taste öffnet (geschlossen wird im Menü selbst, siehe MENU:CheckMenuKey)
hook.Add("PlayerButtonDown", "symchars_menukey", function(ply, key)
    if ply ~= LocalPlayer() or not IsFirstTimePredicted() then return end
    local bind = symchars.Config("openkey") or 0
    if bind == 0 or key ~= bind then return end
    if IsValid(UI.menu) then return end
    if vgui.GetKeyboardFocus() or gui.IsGameUIVisible() or (LocalPlayer().IsTyping and LocalPlayer():IsTyping()) then return end
    UI.ToggleMenu()
end)

-- ESC schließt das Menü statt das Spielmenü zu öffnen
hook.Add("OnPauseMenuShow", "symchars_menu", function()
    if IsValid(UI.menu) then
        if UI.menu:CanClose() then UI.menu:Remove() end
        return false
    end
end)
