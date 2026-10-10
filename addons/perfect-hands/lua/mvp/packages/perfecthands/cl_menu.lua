--[[-------------------------------------------------------------------------------------------------------------
    Perfect Hands - Posen-Menü im SymChars-Design (kompakt)
    Schmale Spalte in der Bildschirmmitte, Hintergrund halb durchsichtig (man sieht, was vor einem ist).
    Oben: kleine Vorschau mit dem eigenen Spielermodell – zeigt die Pose, über der die Maus steht
          (so steht man nach dem Auswählen). Vorschau ziehen = Modell drehen.
    Darunter: alle Posen untereinander. Linksklick = Pose einnehmen. Rechtsklick / ESC / X = schließen.
    Braucht SYMUI (SymChars oder SymChars-UI-Basis). Ohne SYMUI benutzt die Waffe weiter das Radialmenü.
-------------------------------------------------------------------------------------------------------------]]

if SERVER then return end

local P = mvp.package.Get()

-- Größen bei 1080p (werden mit SYMUI.S skaliert)
local MENU_W = 270
local MENU_H = 640
local HEADER_H = 44
local PREVIEW_H = 190
local INFO_H = 50
local ROW_H = 30
local FOOTER_H = 24
local BG_ALPHA = 165 -- Hintergrund: 0 = ganz durchsichtig, 255 = deckend

local function L(key, fallback)
    return mvp.q.LangFallback(key, fallback)
end

-- alle Knochen, die irgendeine Pose bewegt (damit beim Wechsel alte Knochen sauber zurückgehen)
local function AllBones()
    local set = {}
    for _, data in pairs(P.animations.GetAll()) do
        for bone, ang in pairs(data) do
            if isangle(ang) then set[bone] = true end
        end
    end
    return set
end

local registered = false

local function Register()
    if registered then return end
    registered = true

    local UI = SYMUI
    local S = UI.S

    -------------------------------------------------------------------------------------------------------------
    -- Modell-Vorschau (klein)
    -------------------------------------------------------------------------------------------------------------
    local PREVIEW = {}

    function PREVIEW:Init()
        self:SetFOV(30)
        self:SetAnimated(true)
        self:SetCursor("sizewe")
        self._yaw = 20
        self._cur = {}
        self._boneIdx = {}
        self._z = 0
        self._height = 72
        self._bones = AllBones()
        self:LoadPlayer()
    end

    function PREVIEW:LoadPlayer()
        local ply = LocalPlayer()
        self:SetModel(ply:GetModel())

        local ent = self:GetEntity()
        if not IsValid(ent) then return end

        ent:SetSkin(ply:GetSkin())
        ent:SetMaterial(ply:GetMaterial())
        for i = 0, ply:GetNumBodyGroups() - 1 do
            ent:SetBodygroup(i, ply:GetBodygroup(i))
        end
        for i = 0, #(ply:GetMaterials() or {}) - 1 do
            local sub = ply:GetSubMaterial(i)
            if sub and sub ~= "" then ent:SetSubMaterial(i, sub) end
        end

        local playerColor = ply:GetPlayerColor()
        ent.GetPlayerColor = function() return playerColor end

        local seq = ent:LookupSequence("idle_all_01")
        if seq and seq > 0 then ent:ResetSequence(seq) end

        local mn, mx = ent:GetModelBounds()
        local height = (mn and mx) and (mx.z - mn.z) or 72
        if height < 30 or height > 200 then height = 72 end
        self._height = height

        -- ganzer Körper passt in die kleine Vorschau
        self:SetLookAt(Vector(0, 0, height * 0.5))
        self:SetCamPos(Vector(height * 2.7, 0, height * 0.58))

        local accent = UI.Accent()
        self:SetAmbientLight(Color(45, 48, 56))
        self:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
        self:SetDirectionalLight(BOX_FRONT, Color(170, 170, 180))
        self:SetDirectionalLight(BOX_BACK, Color(accent.r * 0.8, accent.g * 0.8, accent.b * 0.8))
        self:SetDirectionalLight(BOX_RIGHT, Color(60, 70, 85))
        self:SetDirectionalLight(BOX_LEFT, Color(60, 70, 85))
    end

    function PREVIEW:SetPose(id) self._pose = id end
    function PREVIEW:GetPose() return self._pose end

    function PREVIEW:LayoutEntity(ent)
        if self._drag then
            local mx = gui.MouseX()
            self._yaw = self._yaw + (mx - self._drag) * 0.6
            self._drag = mx
        end

        ent:SetAngles(Angle(0, self._yaw, 0))
        self:RunAnimation()

        -- Pose weich einblenden (wie am echten Spieler)
        local target = (self._pose and P.animations.Get(self._pose)) or {}
        local t = math.min(FrameTime() * 8, 1)

        for bone in pairs(self._bones) do
            local idx = self._boneIdx[bone]
            if idx == nil then
                idx = ent:LookupBone(bone) or false
                self._boneIdx[bone] = idx
            end

            if idx then
                local goal = isangle(target[bone]) and target[bone] or angle_zero
                local cur = LerpAngle(t, self._cur[bone] or Angle(0, 0, 0), goal)
                self._cur[bone] = cur
                ent:ManipulateBoneAngles(idx, cur)
            end
        end

        self._z = Lerp(t, self._z, target["Animation.ZOffset"] or 0)
        ent:ManipulateBonePosition(0, Vector(0, 0, self._z))
    end

    -- Holo-Ring unter den Füßen
    function PREVIEW:PostDrawModel(ent)
        local accent = UI.Accent()
        local r = self._height * 0.26
        local seg = 40
        local z = 0.5

        for ring = 1, 2 do
            local rr = ring == 1 and r or r * 0.6
            local col = Color(accent.r, accent.g, accent.b, ring == 1 and 200 or 90)
            local last
            for i = 0, seg do
                local a = math.rad(i / seg * 360)
                local p = Vector(math.cos(a) * rr, math.sin(a) * rr, z)
                if last then render.DrawLine(last, p, col, false) end
                last = p
            end
        end
    end

    function PREVIEW:OnMousePressed(code)
        if code == MOUSE_LEFT then
            self._drag = gui.MouseX()
            self:MouseCapture(true)
        elseif code == MOUSE_RIGHT and self.OnRightClick then
            self:OnRightClick()
        end
    end

    function PREVIEW:OnMouseReleased()
        self._drag = nil
        self:MouseCapture(false)
    end

    vgui.Register("mvp.phands.Preview", PREVIEW, "DModelPanel")

    -------------------------------------------------------------------------------------------------------------
    -- Posen-Zeile (eine Pose pro Zeile, untereinander)
    -------------------------------------------------------------------------------------------------------------
    local ROW = {}

    function ROW:Init()
        self:SetText("")
        self:SetCursor("hand")
        self._hover = 0
        self._active = 0
        self._index = 1
        self._name = ""
    end

    function ROW:Setup(index, id, canUse)
        self._index = index
        self._id = id
        self._locked = not canUse
        self._name = L("phands.animation." .. id, id)
    end

    function ROW:OnCursorEntered()
        UI.Sound("hover")
        if self.OnHover then self:OnHover() end
    end

    function ROW:Think()
        self._hover = UI.Approach(self._hover, self:IsHovered() and 1 or 0, 16)
        self._active = UI.Approach(self._active, (self.IsActive and self:IsActive()) and 1 or 0, 12)
    end

    function ROW:Paint(w, h)
        local hv = math.max(self._hover, self._active)
        local accent = self._locked and UI.col.red or UI.Accent()
        local pad = S(8)

        -- Hover: leichte Akzentfläche + Balken links
        if hv > 0.01 then
            UI.Box(0, 0, w, h, UI.Alpha(accent, 26 * hv))
            UI.Gradient(0, 0, w * 0.6, h, UI.Alpha(accent, 30 * hv), "right")
        end
        UI.Box(0, S(4), S(2), h - S(8), UI.Alpha(accent, 40 + 215 * hv))

        -- Trennlinie
        UI.Box(pad, h - 1, w - pad * 2, 1, UI.col.line)

        -- Nummer
        local numW = S(24)
        UI.Text(string.format("%02d", self._index), "symchars.tiny.bold", pad + S(2), h / 2,
            UI.Alpha(UI.col.dim, 90 + 130 * hv), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Name
        local nameX = pad + numW
        local nameW = w - nameX - pad - (self._locked and S(18) or 0)
        local nameCol = self._locked and Color(200, 110, 100) or UI.Lerp(hv, UI.col.text, accent)
        UI.TextFit(string.upper(self._name), "symchars.h4", nameX, h / 2 + S(1), nameCol, nameW, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if self._locked then
            local is = S(14)
            UI.Icon("lock", w - pad - is, (h - is) / 2, is, UI.Alpha(UI.col.red, 200))
        end

        return true
    end

    vgui.Register("mvp.phands.Row", ROW, "DButton")
end

---------------------------------------------------------------------------------------------------------------
-- Menü öffnen
---------------------------------------------------------------------------------------------------------------
function P.OpenMenu()
    if IsValid(P.menu) then P.menu:Remove() end
    Register()

    local UI = SYMUI
    local S = UI.S
    local ply = LocalPlayer()
    local list = P.animations.listSeq

    local w = S(MENU_W)
    local h = math.min(S(MENU_H), ScrH() - S(80))

    local frame = vgui.Create("EditablePanel")
    P.menu = frame
    frame:SetSize(w, h)
    frame:Center()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false) -- Tastatur bleibt beim Spiel
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.12)
    UI.Sound("open")

    function frame:Close()
        if self._closing then return end
        self._closing = true
        self:AlphaTo(0, 0.1, 0, function() if IsValid(self) then self:Remove() end end)
    end

    frame.Think = function(s)
        -- ESC schließt das Menü statt das Spielmenü zu öffnen
        if gui.IsGameUIVisible() then
            gui.HideGameUI()
            s:Close()
            return
        end

        local wep = ply:GetActiveWeapon()
        if not ply:Alive() or not IsValid(wep) or wep:GetClass() ~= "mvp_perfecthands" or ply.mvp_phands_animation_playing then
            s:Close()
        end
    end

    frame.OnMousePressed = function(s, code)
        if code == MOUSE_RIGHT then s:Close() end
    end

    frame.Paint = function(s, pw, ph)
        local accent = UI.Accent()
        local c = S(10)

        -- halb durchsichtig: man sieht, was vor einem ist
        UI.Cut(0, 0, pw, ph, Color(7, 9, 12, BG_ALPHA), c, "tlbr")
        UI.CutOutline(0, 0, pw, ph, UI.col.line2, c, "tlbr")

        -- Kopfzeile
        UI.Text(string.upper(L("phands.menu.title", "Posen")), "symchars.h3", S(14), S(6), UI.col.text)
        UI.Aurebesh(L("phands.menu.title", "Posen"), "symchars.aure.small", S(15), S(30), UI.Alpha(UI.col.dim, 110))
        UI.Box(S(14), S(HEADER_H) - 1, pw - S(28), 1, UI.col.line2)
        UI.Box(S(14), S(HEADER_H) - 1, S(50), S(2), accent)
    end

    ---------------------------------------------------------------------------------------------------------
    -- Kopf: Anzahl + Schließen
    ---------------------------------------------------------------------------------------------------------
    local head = vgui.Create("DPanel", frame)
    head:Dock(TOP)
    head:SetTall(S(HEADER_H))
    head:SetMouseInputEnabled(false)
    head.Paint = function(s, pw, ph)
        local tw = UI.TextSize(tostring(#list), "symchars.tiny.bold") + S(14)
        UI.Chip(tostring(#list), "symchars.tiny.bold", pw - S(44) - tw, S(12), UI.col.ink, UI.Accent())
    end

    local close = vgui.Create("DButton", frame)
    close:SetText("")
    close:SetSize(S(26), S(26))
    close:SetPos(w - S(36), S(9))
    close.Paint = function(s, pw, ph)
        local col = s:IsHovered() and UI.col.red or UI.col.dim
        UI.Icon("close", S(5), S(5), pw - S(10), col)
        return true
    end
    close.DoClick = function()
        UI.Sound("click")
        frame:Close()
    end

    ---------------------------------------------------------------------------------------------------------
    -- Vorschau (eigenes Modell)
    ---------------------------------------------------------------------------------------------------------
    local stage = vgui.Create("DPanel", frame)
    stage:Dock(TOP)
    stage:SetTall(S(PREVIEW_H))
    stage:DockMargin(S(10), S(8), S(10), 0)
    stage.Paint = function(s, pw, ph)
        local c = S(8)

        UI.Cut(0, 0, pw, ph, Color(0, 0, 0, 70), c, "tlbr")

        -- feines Raster
        surface.SetDrawColor(255, 255, 255, 6)
        local step = S(22)
        for x = c, pw - c, step do surface.DrawRect(x, c, 1, ph - c * 2) end
        for y = c, ph - c, step do surface.DrawRect(c, y, pw - c * 2, 1) end

        UI.CutOutline(0, 0, pw, ph, UI.col.line, c, "tlbr")
        UI.Text(string.upper(L("phands.menu.preview", "Vorschau")), "symchars.tiny.bold", pw - S(10), S(6), UI.Alpha(UI.col.dim, 140), TEXT_ALIGN_RIGHT)
    end

    local preview = vgui.Create("mvp.phands.Preview", stage)
    preview:Dock(FILL)
    preview.OnRightClick = function() frame:Close() end

    -- Name + Beschreibung der gezeigten Pose
    local info = vgui.Create("DPanel", frame)
    info:Dock(TOP)
    info:SetTall(S(INFO_H))
    info:DockMargin(S(12), S(6), S(12), S(4))
    info:SetMouseInputEnabled(false)
    info.Paint = function(s, pw, ph)
        local id = preview:GetPose()
        local name = id and L("phands.animation." .. id, id) or L("phands.menu.choose", "Pose wählen")
        local desc = id and L("phands.animation." .. id .. ".description", "")
            or L("phands.menu.choose.short", "Maus über eine Pose = Vorschau")

        UI.TextFit(string.upper(name), "symchars.small.bold", 0, 0, id and UI.Accent() or UI.col.text, pw)
        UI.DrawWrapped(desc, "symchars.tiny", 0, S(20), pw, UI.col.dim, 2)
    end

    ---------------------------------------------------------------------------------------------------------
    -- Fußzeile
    ---------------------------------------------------------------------------------------------------------
    local footer = vgui.Create("DPanel", frame)
    footer:Dock(BOTTOM)
    footer:SetTall(S(FOOTER_H))
    footer:DockMargin(S(10), 0, S(10), S(4))
    footer:SetMouseInputEnabled(false)
    footer.Paint = function(s, pw, ph)
        UI.Box(0, 0, pw, 1, UI.col.line)
        UI.TextFit(L("phands.menu.hint.compact", "Klick: Pose  ·  Rechtsklick/ESC: Schließen"), "symchars.tiny",
            pw / 2, ph / 2 + S(1), UI.col.muted, pw, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    ---------------------------------------------------------------------------------------------------------
    -- Posen-Liste (untereinander)
    ---------------------------------------------------------------------------------------------------------
    local scroll = UI.Scroll(frame)
    scroll:Dock(FILL)
    scroll:DockMargin(S(6), S(2), S(4), S(4))

    for i, id in ipairs(list) do
        local canUse = hook.Run("mvp.phands.CanUseAnimation", ply, id)
        if canUse == nil then canUse = true end

        local row = vgui.Create("mvp.phands.Row", scroll)
        row:Dock(TOP)
        row:SetTall(S(ROW_H))
        row:Setup(i, id, canUse)
        row.OnHover = function() preview:SetPose(id) end
        row.IsActive = function() return preview:GetPose() == id end
        row.DoRightClick = function() frame:Close() end
        row.DoClick = function()
            if not canUse then UI.Sound("error") return end
            UI.Sound("click")
            net.Start("mvp.phands.requestAnimation")
                net.WriteString(id)
            net.SendToServer()
            frame:Close()
        end
    end

    return frame
end
