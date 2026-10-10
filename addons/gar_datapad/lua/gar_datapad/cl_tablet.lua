--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Der Bildschirm des Tablets (Server-Design wie das SymChars-Menue)
    Das Fenster liegt genau auf dem Bildschirm des Easzy-Tablets in der Hand (Ecken aus dem Viewmodel).
    Aufbau: schwarze Kopfleiste (ZURUECK, Reiter mit Aurebesh, Person), Inhalt, Fusszeile in Aurebesh.
    Zurueck / ESC geht einen Schritt zurueck (Dialog -> Eintrag -> vorheriger Bereich -> Start).
    Erst auf dem Startbildschirm schliesst ESC das Datapad.
-------------------------------------------------------------------------------------------------------------]]

local D = GAR_DP.ui
local S = D.S

GAR_DP.apps = GAR_DP.apps or {}

-- app = { id, name, short, desc, icon, order, build = function(parent, tablet, opts) end }
function GAR_DP.RegisterApp(app)
    GAR_DP.apps[app.id] = app
end

local function SortedApps()
    local list = {}
    for _, app in pairs(GAR_DP.apps) do list[#list + 1] = app end
    table.sort(list, function(a, b) return (a.order or 0) < (b.order or 0) end)
    return list
end

local function Weapon()
    local lp = LocalPlayer()
    local wep = IsValid(lp) and lp:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == GAR_DP.WEAPON then return wep end
end

local function ScreenRect()
    local wep = Weapon()
    local r = wep and wep.gdp_screen
    if r and RealTime() - r.t < 1 and r.w > 200 and r.h > 120 then
        return math.floor(r.x), math.floor(r.y), math.floor(r.w), math.floor(r.h)
    end
    local w, h = math.floor(ScrW() * 0.6), math.floor(ScrH() * 0.72)
    return math.floor((ScrW() - w) / 2), math.floor((ScrH() - h) / 2), w, h
end

local function LockReason(app)
    local ok, reason = GAR_DP.CanUse(LocalPlayer(), app.id)
    if ok then return nil end
    return reason or "Gesperrt"
end

---------------------------------------------------------------------------------------------------------------
-- Charaktermodell (Startseite: ganze Figur auf Holo-Ring, Akten: Kopf + Schultern)
---------------------------------------------------------------------------------------------------------------
function D.HoloModel(parent, model, mode)
    local mdl = vgui.Create("DModelPanel", parent)
    mdl:SetModel(model or "models/player/kleiner.mdl")
    mdl:SetMouseInputEnabled(false)
    mdl.LayoutEntity = function(s, ent)
        if not IsValid(ent) then return end
        ent:SetAngles(Angle(0, 25 + math.sin(RealTime() * 0.5) * 20, 0))
        -- Entfernung so waehlen, dass die gewuenschte Hoehe sicher ins Feld passt (Kopf nie abgeschnitten)
        local aspect = s:GetTall() / math.max(1, s:GetWide())
        local tanHalf = math.tan(math.rad(15))
        s:SetFOV(30)
        local look, span
        if mode == "full" then
            local mins, maxs = ent:GetRenderBounds()
            local height = math.max(40, maxs.z - mins.z)
            look = Vector(0, 0, mins.z + height * 0.5)
            span = height * 1.12
        else
            local bone = ent:LookupBone("ValveBiped.Bip01_Head1")
            local z = bone and ent:GetBonePosition(bone).z or 64
            if z < 10 then z = 64 end
            look = Vector(0, 0, z - 6)
            span = 46
        end
        local dist = math.max((span / math.max(aspect, 0.01)) / (2 * tanHalf), span / (2 * tanHalf))
        s:SetLookAt(look)
        s:SetCamPos(look + Vector(dist, 0, 0))
    end
    local basePaint = mdl.Paint
    mdl.Paint = function(s, w, h)
        if mode == "full" then
            -- Holo-Ring am Boden wie im Charaktermenue
            D.Gradient(0, h * 0.7, w, h * 0.3, D.Holo(18), "up")
            D.Ring(w / 2, h - S(14), w * 0.3, D.Holo(90), 1, 40)
            D.Ring(w / 2, h - S(14), w * 0.2, D.Holo(50), 1, 32)
            basePaint(s, w, h)
        else
            D.Box(0, 0, w, h, Color(10, 14, 20, 200))
            D.Gradient(0, h * 0.5, w, h * 0.5, D.Holo(30), "up")
            basePaint(s, w, h)
            D.Outline(0, 0, w, h, D.col.line2)
        end
    end
    return mdl
end

---------------------------------------------------------------------------------------------------------------
-- Tablet
---------------------------------------------------------------------------------------------------------------
local TAB = {}
local TOP_H, FOOT_H = 64, 30
local TAB_FONTS = { "gdp.h2", "gdp.h3", "gdp.h4" }

function TAB:Init()
    local x, y, w, h = ScreenRect()
    D.SetScale(h)
    self:SetPos(x, y)
    self:SetSize(w, h)
    self._rect = { x, y, w, h }
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self.openTime = RealTime()
    self.bootTime = GAR_DP._booted and 0.35 or 1.6
    GAR_DP._booted = true
    self.history = {}
    self.toasts = {}

    -- Kopfleiste
    self.top = vgui.Create("DPanel", self)
    self.top.Paint = function(_, pw, ph) self:PaintTop(pw, ph) end

    -- ZURUECK
    self.backBtn = vgui.Create("DButton", self.top)
    self.backBtn:SetText("")
    self.backBtn:SetCursor("hand")
    self.backBtn._hover = 0
    self.backBtn.Think = function(s) s._hover = D.Approach(s._hover, s:IsHovered() and 1 or 0, 14) end
    self.backBtn.OnCursorEntered = function() if self:CanGoBack() then D.Sound("hover") end end
    self.backBtn.DoClick = function() self:Back() end
    self.backBtn.Paint = function(s, pw, ph)
        local can = self:CanGoBack()
        local hv = can and s._hover or 0
        local col = can and D.Lerp(hv, D.col.text, D.Accent()) or D.col.faint
        if hv > 0.01 then
            D.Box(0, 0, pw, ph, D.Accent(16 * hv))
            D.Box(0, ph - S(2), pw, S(2), D.Accent(130 * hv))
        end
        local is = S(20)
        D.Icon("arrow_left", S(10) - hv * S(3), ph / 2 - is / 2 - S(5), is, can and D.Accent() or D.col.faint)
        D.Text("ZURÜCK", "gdp.h3", S(34), ph / 2 - S(5), col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        D.Aurebesh("Zurueck", "gdp.aure.small", S(35), ph / 2 + S(9), D.Alpha(col, 120), nil, TEXT_ALIGN_CENTER)
        D.Box(pw - 1, ph * 0.25, 1, ph * 0.5, Color(255, 255, 255, 25))
        return true
    end

    -- Reiter
    self.tabs = {}
    local function AddTab(id, name)
        local b = vgui.Create("DButton", self.top)
        b:SetText("")
        b:SetCursor("hand")
        b._hover, b._act = 0, 0
        b.id = id
        b.name = name
        b.Think = function(s)
            s._hover = D.Approach(s._hover, s:IsHovered() and 1 or 0, 12)
            s._act = D.Approach(s._act, self.view == id and 1 or 0, 14)
        end
        b.OnCursorEntered = function() D.Sound("hover") end
        b.DoClick = function()
            local app = GAR_DP.apps[id]
            local locked = app and LockReason(app)
            if locked then D.Sound("error") GAR_DP.Notify(locked, "error") return end
            if self.view == id then return end
            D.Sound("click")
            self:Navigate(id)
        end
        b.Paint = function(s, pw, ph) self:PaintTab(s, pw, ph) return true end
        self.tabs[#self.tabs + 1] = b
    end
    AddTab("home", "Start")
    for _, app in ipairs(SortedApps()) do AddTab(app.id, app.short or app.name) end

    self.closeBtn = D.Button(self.top, "", "icon", function() GAR_DP.CloseTablet() end)
    self.closeBtn:SetIcon("close")

    self.body = vgui.Create("DPanel", self)
    self.body.Paint = nil
    self.body:SetVisible(false)

    timer.Simple(self.bootTime, function()
        if not IsValid(self) then return end
        self.body:SetVisible(true)
        if not self.view then self:Navigate("home", nil, true) end
        D.Sound("open")
    end)
end

function TAB:PaintTab(s, w, h)
    local app = GAR_DP.apps[s.id]
    local locked = app and LockReason(app)
    local act, hv = s._act, locked and 0 or s._hover
    local accent = D.Accent()
    if act > 0.01 then
        D.Box(0, 0, w, h, D.Accent(30 * act))
        D.Gradient(0, 0, w, h, D.Accent(70 * act), "up")
        D.Box(0, h - S(3), w, S(3), D.Accent(255 * act))
        D.Box(0, 0, w, 1, D.Accent(60 * act))
    end
    if hv > 0.01 and act < 0.99 then
        D.Box(0, 0, w, h, D.Accent(16 * hv * (1 - act)))
        D.Box(0, h - S(2), w, S(2), D.Accent(130 * hv * (1 - act)))
    end
    D.Box(w - 1, math.floor(h * 0.28), 1, math.floor(h * 0.44), Color(255, 255, 255, 16))

    local col = locked and D.Alpha(D.col.faint, 255) or D.Lerp(act, D.Lerp(hv, D.col.dim, D.col.text), accent)
    local font = self.tabFont or "gdp.h3"
    local label = string.upper(s.name)
    local _, lh = D.TextSize("Ag", font)
    local ah = D.AurebeshHeight("gdp.aure.small")
    local y = math.floor((h - lh - ah + S(6)) / 2)
    D.Text(label, font, w / 2, y, col, TEXT_ALIGN_CENTER)
    D.Aurebesh(s.name, "gdp.aure.small", w / 2, y + lh - S(6), D.Alpha(col, locked and 60 or (90 + 110 * act)), TEXT_ALIGN_CENTER)
    if locked then D.Icon("lock", w - S(16), S(6), S(11), D.Alpha(D.col.red, 200)) end
end

function TAB:PerformLayout(w, h)
    local th = S(TOP_H)
    self.top:SetPos(0, 0)
    self.top:SetSize(w, th)

    local backW = S(124)
    self.backBtn:SetPos(0, 0)
    self.backBtn:SetSize(backW, th)

    self.closeBtn:SetSize(S(34), S(34))
    self.closeBtn:SetPos(w - S(44), (th - S(34)) / 2)

    -- Platz rechts fuer Name/Rang
    local infoW = math.min(S(230), math.floor(w * 0.2))
    self.infoX = w - S(52) - infoW
    local tabsX, tabsW = backW + S(6), self.infoX - backW - S(16)

    -- groesste Schrift, bei der alle Reiter passen
    local pad = S(14)
    self.tabFont = TAB_FONTS[#TAB_FONTS]
    for _, f in ipairs(TAB_FONTS) do
        local total = 0
        for _, b in ipairs(self.tabs) do total = total + D.TextSize(string.upper(b.name), f) + pad * 2 end
        if total <= tabsW then self.tabFont = f break end
    end
    local x = tabsX
    for _, b in ipairs(self.tabs) do
        local tw = D.TextSize(string.upper(b.name), self.tabFont) + pad * 2
        b:SetPos(x, 0)
        b:SetSize(tw, th)
        x = x + tw
    end

    self.body:SetPos(S(18), th + S(14))
    self.body:SetSize(w - S(36), h - th - S(14) - S(FOOT_H) - S(10))
end

function TAB:Think()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() or not Weapon() then
        GAR_DP.CloseTablet(true)
        return
    end
    local x, y, w, h = ScreenRect()
    local r = self._rect
    if math.abs(r[1] - x) > 2 or math.abs(r[2] - y) > 2 or math.abs(r[3] - w) > 2 or math.abs(r[4] - h) > 2 then
        self._rect = { x, y, w, h }
        self:SetPos(x, y)
        if math.abs(r[3] - w) > 2 or math.abs(r[4] - h) > 2 then
            self:SetSize(w, h)
            if math.abs(r[4] - h) / math.max(1, r[4]) > 0.03 then
                D.SetScale(h)
                self:InvalidateLayout(true)
                self:Show(self.view or "home", self.viewOpts)
            end
        end
    end
end

---------------------------------------------------------------------------------------------------------------
-- Navigation mit Verlauf
---------------------------------------------------------------------------------------------------------------
function TAB:TopPopup()
    local best
    for _, child in ipairs(self:GetChildren()) do
        if child.gdpPopup and IsValid(child) and (not best or child:GetZPos() >= best:GetZPos()) then best = child end
    end
    return best
end

function TAB:CanGoBack()
    return self:TopPopup() ~= nil or self.backHandler ~= nil or #self.history > 0 or (self.view ~= nil and self.view ~= "home")
end

-- Ein Bereich kann einen eigenen Zurueck-Schritt anmelden (z.B. Eintrag schliessen)
function TAB:SetBackHandler(fn)
    self.backHandler = fn
end

-- gibt false zurueck, wenn es nichts mehr zurueck gibt
function TAB:Back()
    local popup = self:TopPopup()
    if popup then
        popup:Remove()
        D.Sound("click")
        return true
    end
    if self.backHandler then
        local fn = self.backHandler
        self.backHandler = nil
        if fn() ~= false then D.Sound("click") return true end
    end
    if #self.history > 0 then
        local prev = table.remove(self.history)
        D.Sound("click")
        self:Show(prev.id, prev.opts)
        return true
    end
    if self.view and self.view ~= "home" then
        D.Sound("click")
        self:Show("home")
        return true
    end
    return false
end

function TAB:Navigate(id, opts, noHistory)
    if id == self.view and not opts then return end
    if self.view and not noHistory then
        table.insert(self.history, { id = self.view, opts = self.viewOpts })
        if #self.history > 20 then table.remove(self.history, 1) end
    end
    if id == "home" then self.history = {} end
    self:Show(id, opts)
end

function TAB:Show(id, opts)
    local popup = self:TopPopup()
    while popup do popup:Remove() popup = self:TopPopup() end
    self.backHandler = nil
    self.body:Clear()
    self.view = id
    self.viewOpts = opts
    self.viewStart = RealTime()
    self:InvalidateLayout(true)

    if id == "home" then
        self:BuildHome()
        return
    end
    local app = GAR_DP.apps[id]
    if not app then self:Show("home") return end
    local locked = LockReason(app)
    if locked then GAR_DP.Notify(locked, "error") self:Show("home") return end
    local ok, err = pcall(app.build, self.body, self, opts or {})
    if not ok then
        ErrorNoHaltWithStack("[GAR Datapad] Fehler in '" .. id .. "': " .. tostring(err) .. "\n")
        D.Placeholder(self.body, "Dieser Bereich konnte nicht geladen werden", "warn")
    end
end

function TAB:OpenApp(id, opts) self:Navigate(id, opts) end
function TAB:ShowHome() self:Navigate("home") end

---------------------------------------------------------------------------------------------------------------
-- Startseite: Kommandonetz + Modell links, Akte rechts
---------------------------------------------------------------------------------------------------------------
function TAB:BuildHome()
    local body = self.body
    local stats = {}
    GAR_DP.Request("home", {}, function(data) if data then stats = data end end)

    local right = vgui.Create("DPanel", body)
    right:Dock(RIGHT)
    right:SetWide(math.floor(body:GetWide() * 0.42))
    right:DockMargin(S(14), 0, 0, 0)
    right.Paint = function(_, w, h) self:PaintAkte(w, h, stats) end

    local left = vgui.Create("DPanel", body)
    left:Dock(FILL)
    left.Paint = function(_, w, h)
        D.Heading("Kommandonetz", "gdp.h1", 0, -S(4), D.col.text)
        D.Text(os.date("%H:%M"), "gdp.h1", w, -S(4), D.Accent(), TEXT_ALIGN_RIGHT)
        D.Text(os.date("%d.%m.%Y"), "gdp.small", w, S(34), D.col.dim, TEXT_ALIGN_RIGHT)
    end

    local char = D.LocalChar()
    if char then
        local mdl = D.HoloModel(left, char.model, "full")
        mdl:Dock(FILL)
        mdl:DockMargin(0, S(62), 0, 0)
    end
end

function TAB:PaintAkte(w, h, stats)
    D.Frame(0, 0, w, h)
    local tw = D.Tag("Akte", S(14), S(14))
    D.Aurebesh("Akte", "gdp.aure.small", S(22) + tw, S(21), D.Alpha(D.col.dim, 110))

    local char = D.LocalChar()
    local x, y, cw = S(16), S(52), w - S(32)
    if not char then
        D.Text("KEIN CHARAKTER", "gdp.h3", x, y, D.col.muted)
        return
    end
    local rank, rankCol = D.CharRank(char)
    local unit, unitCol = D.CharUnit(char)
    y = y + D.KeyValue("Name", char.name or "-", x, y, cw)
    y = y + D.KeyValue("RP-ID", char.roleplayID or "-", x, y, cw)
    y = y + D.KeyValue("Einheit", unit, x, y, cw, unitCol)
    y = y + D.KeyValue("Rang", rank ~= "" and rank or "-", x, y, cw)

    -- Freigabe
    y = y + S(4)
    y = y + D.Bar("Freigabe", x, y)
    local cx = x
    local faction = char:GetFaction()
    if faction then
        cx = cx + D.Chip(faction.short or faction.name, cx, y, faction:GetColor()) + S(6)
    end
    if rank ~= "" then cx = cx + D.Chip(rank, cx, y, D.Accent()) + S(6) end
    local level = GAR_DP.Clearance(LocalPlayer())
    D.LevelChip(level, cx, y)
    y = y + S(26)
    D.TextFit(GAR_DP.LevelData(level).name, "gdp.small", x, y, GAR_DP.LevelData(level).color, cw)
    y = y + S(26)

    -- Lage
    if y + S(60) > h then return end
    y = y + D.Bar("Lage", x, y)
    local lines = {}
    if stats.wanted then lines[#lines + 1] = { "Offene Fahndungen", stats.wanted, stats.wanted > 0 and D.col.red or nil } end
    lines[#lines + 1] = { "Berichte 24 Std.", stats.reports or "…" }
    lines[#lines + 1] = { "Zugängliche Akten", stats.classified or "…" }
    local rep, sep = 0, 0
    for _, s in pairs(GAR_DP.galaxyState or {}) do
        if s.status == "rep" then rep = rep + 1 elseif s.status == "sep" then sep = sep + 1 end
    end
    lines[#lines + 1] = { "Systeme Republik / KUS", rep .. " / " .. sep }
    for _, l in ipairs(lines) do
        if y + S(40) > h then break end
        y = y + D.KeyValue(l[1], tostring(l[2]), x, y, cw, l[3])
    end
end

---------------------------------------------------------------------------------------------------------------
-- Zeichnen
---------------------------------------------------------------------------------------------------------------
function TAB:PaintTop(w, h)
    D.Box(0, 0, w, h, Color(0, 0, 0, 240))
    D.Gradient(0, h * 0.45, w, h * 0.55, D.Accent(14), "up")
    D.Box(0, h - 1, w, 1, D.Accent(110))

    -- Name + Rang rechts (wie im Charaktermenue)
    local x = self.infoX or (w - S(280))
    local rw = w - S(52) - x
    D.Box(x, S(12), 1, h - S(24), Color(255, 255, 255, 30))
    D.Box(w - S(52), S(12), 1, h - S(24), Color(255, 255, 255, 30))
    local char = D.LocalChar()
    if char then
        local rank, rankCol = D.CharRank(char)
        local faction = char:GetFaction()
        local rx = w - S(60)
        D.TextFit(D.CharName(char), "gdp.body.b", rx, h / 2 - S(2), D.col.text, rw - S(12), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        D.TextFit((rank ~= "" and (rank .. "  ·  ") or "") .. (faction and faction.name or ""), "gdp.tiny", rx, h / 2 + S(1), rankCol, rw - S(12), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        D.Aurebesh(D.CharName(char), "gdp.aure.small", rx, h / 2 + S(16), D.Alpha(D.col.dim, 90), TEXT_ALIGN_RIGHT, nil, rw - S(12))
    end
end

function TAB:Paint(w, h)
    D.Box(0, 0, w, h, Color(6, 8, 11, 254))
    D.Gradient(0, 0, w * 0.35, h, Color(0, 0, 0, 140), "right")
    D.Gradient(0, h * 0.7, w, h * 0.3, Color(0, 0, 0, 110), "up")
    -- feines Raster unten rechts (wie im Menue)
    surface.SetDrawColor(255, 255, 255, 6)
    for gx = w - S(360), w - S(20), S(22) do surface.DrawRect(gx, h - S(FOOT_H) - S(10), 1, S(8)) end

    -- Fusszeile in Aurebesh
    local fy = h - S(FOOT_H)
    D.Box(S(18), fy, w - S(36), 1, D.col.line)
    local hint = self:CanGoBack() and "ESC Zurueck" or "ESC Schliessen"
    D.Aurebesh(hint, "gdp.aure", S(18), fy + S(FOOT_H) / 2, D.Alpha(D.col.dim, 200), nil, TEXT_ALIGN_CENTER)
    local hw = symchars.ui.AurebeshSize and symchars.ui.AurebeshSize(hint, "symchars.aure") or S(150)
    local tx = S(18) + hw + S(24)
    local tw = w - tx - S(200)
    if tw > S(40) then
        local sx, sy = self:LocalToScreen(tx, fy)
        render.SetScissorRect(sx, sy, sx + tw, sy + S(FOOT_H), true)
        local ticker = "Verbindung zum Kommandonetz stabil - Verschluesselung aktiv - Grosse Armee der Republik - "
        local off = (RealTime() * S(26)) % S(1000)
        D.Aurebesh(ticker .. ticker, "gdp.aure.small", tx - off, fy + S(FOOT_H) / 2, D.Alpha(D.col.dim, 70), nil, TEXT_ALIGN_CENTER)
        render.SetScissorRect(0, 0, 0, 0, false)
    end
    D.Aurebesh("GAR Datapad " .. GAR_DP.version, "gdp.aure.small", w - S(18), fy + S(FOOT_H) / 2, D.Alpha(D.col.dim, 120), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

function TAB:PaintOver(w, h)
    -- Startanimation
    local t = (RealTime() - self.openTime) / self.bootTime
    if t < 1.25 then
        local fade = t < 1 and 255 or 255 * (1 - (t - 1) / 0.25)
        D.Box(0, 0, w, h, Color(4, 6, 9, fade))
        if self.bootTime > 1 and t < 1 then
            local a = math.min(255, t * 600)
            local s = S(110)
            D.Icon("republic", w / 2 - s / 2, h * 0.34 - s / 2, s, D.Accent(a))
            D.Text("GAR DATAPAD", "gdp.big", w / 2, h * 0.34 + s * 0.62, Color(236, 233, 224, a), TEXT_ALIGN_CENTER)
            D.Aurebesh("Grosse Armee der Republik", "gdp.aure.big", w / 2, h * 0.34 + s * 0.62 + S(62), D.Alpha(D.col.dim, a * 0.7), TEXT_ALIGN_CENTER)
            local bw = S(300)
            D.Box(w / 2 - bw / 2, h * 0.7, bw, S(3), Color(255, 255, 255, 30))
            D.Box(w / 2 - bw / 2, h * 0.7, bw * D.Ease(t), S(3), D.Accent(a))
            local steps = { "Verbindung zum Kommandonetz", "Identität wird geprüft", "Freigabe wird geladen" }
            local step = steps[math.min(#steps, math.floor(t * #steps) + 1)]
            D.Text(string.upper(step), "gdp.h4", w / 2, h * 0.7 + S(12), D.Alpha(D.col.dim, a), TEXT_ALIGN_CENTER)
            D.Aurebesh(step, "gdp.aure.small", w / 2, h * 0.7 + S(34), D.Alpha(D.col.dim, a * 0.5), TEXT_ALIGN_CENTER)
        end
    end

    if self.viewStart and t >= 1 then
        local vt = (RealTime() - self.viewStart) / 0.18
        if vt < 1 then D.Box(0, S(TOP_H), w, h - S(TOP_H) - S(FOOT_H), Color(6, 8, 11, 255 * (1 - vt))) end
    end

    D.Outline(0, 0, w, h, Color(255, 255, 255, 18))

    -- Meldungen
    local ty = S(TOP_H) + S(10)
    for i = #self.toasts, 1, -1 do
        local toast = self.toasts[i]
        local age = RealTime() - toast.t
        if age > 5 then
            table.remove(self.toasts, i)
        else
            local a = math.min(1, age * 6, (5 - age) * 3)
            local col = toast.kind == "error" and D.col.red or toast.kind == "warn" and D.col.yellow or D.Accent()
            local tw = math.min(S(420), w * 0.45)
            local lines = D.Wrap(toast.text, "gdp.small", tw - S(30))
            local th = #lines * S(18) + S(14)
            local tx = w - tw - S(16) + (1 - a) * S(30)
            D.Box(tx, ty, tw, th, Color(8, 10, 13, 245 * a))
            D.Outline(tx, ty, tw, th, D.Alpha(col, 170 * a))
            D.Box(tx, ty, S(3), th, D.Alpha(col, 255 * a))
            for li, line in ipairs(lines) do
                D.Text(line, "gdp.small", tx + S(14), ty + S(7) + (li - 1) * S(18), Color(236, 233, 224, 255 * a))
            end
            ty = ty + th + S(6)
        end
    end
end

function TAB:Toast(text, kind)
    table.insert(self.toasts, { text = tostring(text or ""), kind = kind, t = RealTime() })
    D.Sound(kind == "error" and "error" or "notify")
end

function TAB:OnRemove()
    if GAR_DP.tablet == self then GAR_DP.tablet = nil end
end

vgui.Register("gdp.Tablet", TAB, "EditablePanel")

---------------------------------------------------------------------------------------------------------------
-- Oeffnen / Schliessen
---------------------------------------------------------------------------------------------------------------
function GAR_DP.OpenTablet()
    if IsValid(GAR_DP.tablet) then return GAR_DP.tablet end
    if not Weapon() then return end
    GAR_DP.tablet = vgui.Create("gdp.Tablet")
    return GAR_DP.tablet
end

function GAR_DP.CloseTablet(fromServer)
    if IsValid(GAR_DP.tablet) then GAR_DP.tablet:Remove() end
    GAR_DP.tablet = nil
    if not fromServer then
        net.Start("gar_datapad_close")
        net.SendToServer()
    end
end

-- ESC: einen Schritt zurueck; erst auf der Startseite wird das Datapad geschlossen
hook.Add("OnPauseMenuShow", "gar_datapad_esc", function()
    local tab = GAR_DP.tablet
    if IsValid(tab) then
        local focus = vgui.GetKeyboardFocus()
        if IsValid(focus) and focus.gdpEntry then
            focus:KillFocus()
            tab:SetKeyboardInputEnabled(false)
            return false
        end
        if not tab:Back() then GAR_DP.CloseTablet() end
        return false
    end
end)

hook.Add("OnScreenSizeChanged", "gar_datapad_resize", function()
    if IsValid(GAR_DP.tablet) then GAR_DP.tablet:Remove() end
end)

if IsValid(GAR_DP.tablet) then GAR_DP.tablet:Remove() end
