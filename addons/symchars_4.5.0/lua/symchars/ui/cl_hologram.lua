--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Hologramm-Modelle
    symchars.HoloModel:
        mode "solid": normales Modell, beim Wechsel baut es sich als Hologramm von unten nach oben auf
        mode "holo" : dauerhaftes Hologramm (blau, flackernd, Scan-Linie, Projektor-Ring + Lichtkegel)
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S

local WIRE = Material("models/wireframe")
local WHITE = Material("models/debug/debugwhite")
local GLOW = Material("sprites/light_glow02_add")
local RING = Material("effects/select_ring")
local BEAM = Material("vgui/gradient-u")

local UP, DOWN = Vector(0, 0, 1), Vector(0, 0, -1)
local SWEEP_TIME = 1.7

local IDLE_SEQUENCES = { "idle_all_01", "idle_passive", "idle_subtle", "pose_standing_02", "idle_all_02", "idle" }

local FRAMING = {
    full = { low = -0.04, top = 0.08 },
    holo = { low = -0.16, top = 0.10 },
    bust = { low = 0.55, top = 0.06 },
    portrait = { low = 0.42, top = 0.06 },
}

local PANEL = {}

function PANEL:Init()
    self:SetFOV(28)
    self._mode = "solid"
    self._yaw = 25
    self._spin = 0
    self._framing = "full"
    self._bottom, self._top = 0, 72
    self:SetCursor("sizewe")
    self:SetAnimated(true)
end

function PANEL:SetMode(mode)
    self._mode = mode
    if mode == "holo" and self._framing == "full" then self._framing = "holo" end
end
function PANEL:SetSpin(speed) self._spin = speed or 0 end
function PANEL:SetFraming(name) self._framing = FRAMING[name] and name or "full" self:InvalidateLayout() end
function PANEL:SetLabel(text) self._label = text end
function PANEL:SetHoloColor(col) self._holoColor = col end
function PANEL:SetYaw(yaw) self._yaw = yaw end

-- model, opts = { skin, bodygroups = { [id] = value }, noSweep }
function PANEL:SetHoloModel(model, opts)
    opts = opts or {}
    model = tostring(model or "")
    if model == "" then
        if IsValid(self.Entity) then self.Entity:Remove() end
        self.Entity = nil
        self._model = nil
        return
    end
    if model == self._model and IsValid(self.Entity) and not opts.force then return end
    self._model = model
    self:SetModel(model)
    local ent = self.Entity
    if not IsValid(ent) then return end

    ent:SetSkin(opts.skin or 0)
    for id, value in pairs(opts.bodygroups or {}) do ent:SetBodygroup(tonumber(id) or 0, tonumber(value) or 0) end

    for _, name in ipairs(IDLE_SEQUENCES) do
        local seq = ent:LookupSequence(name)
        if seq and seq > 0 then ent:ResetSequence(seq) break end
    end

    local mins, maxs = ent:GetRenderBounds()
    self._bottom = mins.z
    self._top = math.max(maxs.z, mins.z + 20)
    self:InvalidateLayout(true)
    if not opts.noSweep then self:Materialize() end
end

function PANEL:Materialize()
    self._sweepStart = RealTime()
end

function PANEL:PerformLayout(w, h)
    if w <= 0 or h <= 0 then return end
    local f = FRAMING[self._framing] or FRAMING.full
    local height = self._top - self._bottom
    local low = self._bottom + height * f.low
    local top = self._top + height * f.top
    local span = math.max(top - low, 8)
    local centre = (top + low) / 2
    local fov = self:GetFOV()
    local dist = (span * (w / h)) / (2 * math.tan(math.rad(fov) / 2))
    -- bei sehr schmalen Panels Breite berücksichtigen
    dist = math.max(dist, (height * 0.62) / (2 * math.tan(math.rad(fov) / 2)) * 1.0)
    self:SetCamPos(Vector(dist, 0, centre))
    self:SetLookAt(Vector(0, 0, centre))
end

function PANEL:OnMousePressed(code)
    if code == MOUSE_LEFT then self._drag = gui.MouseX() end
end

function PANEL:OnMouseReleased() self._drag = nil end
function PANEL:OnCursorExited() self._drag = nil end

function PANEL:LayoutEntity(ent)
    if self._drag then
        if not input.IsMouseDown(MOUSE_LEFT) then
            self._drag = nil
        else
            local mx = gui.MouseX()
            self._yaw = self._yaw + (mx - self._drag) * 0.6
            self._drag = mx
        end
    elseif self._spin ~= 0 then
        self._yaw = self._yaw + FrameTime() * self._spin
    end
    ent:SetAngles(Angle(0, self._yaw, 0))
    if self:GetAnimated() then self:RunAnimation() end
end

local function Ease(t)
    t = math.Clamp(t, 0, 1)
    return t < 0.5 and 4 * t * t * t or 1 - ((-2 * t + 2) ^ 3) / 2
end

local function Projector(bottom, top, col, alpha)
    local pos = Vector(0, 0, bottom + 0.6)
    render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)

    local pulse = 0.85 + math.sin(RealTime() * 3) * 0.15
    render.SetMaterial(RING)
    render.DrawQuadEasy(pos, UP, 46, 46, Color(col.r, col.g, col.b, 200 * alpha), RealTime() * 20)
    render.DrawQuadEasy(pos, UP, 30, 30, Color(col.r, col.g, col.b, 120 * alpha), -RealTime() * 35)

    render.SetMaterial(GLOW)
    render.DrawQuadEasy(pos, UP, 70 * pulse, 70 * pulse, Color(col.r, col.g, col.b, 140 * alpha), 0)

    -- Lichtkegel (zur Kamera ausgerichtet, Kamera liegt auf +X)
    local h = (top - bottom) * 1.05
    render.SetMaterial(BEAM)
    render.DrawQuad(
        Vector(0, -24, bottom + h), Vector(0, 24, bottom + h),
        Vector(0, 7, bottom), Vector(0, -7, bottom),
        Color(col.r, col.g, col.b, 38 * alpha * pulse)
    )
    render.OverrideBlend(false)
end

function PANEL:DrawHolo(ent, col, alpha)
    local now = RealTime()
    local bottom, top = self._bottom, self._top
    local age = self._sweepStart and (now - self._sweepStart) / SWEEP_TIME or 2
    local reveal = Ease(math.min(age, 1))
    local cut = Lerp(reveal, bottom, top + 4)

    local flicker = 1
    if math.random() < 0.025 then flicker = 0.45 end
    local r, g, b = col.r / 255, col.g / 255, col.b / 255

    local clipping = render.EnableClipping(true)

    render.PushCustomClipPlane(DOWN, -cut)
    render.MaterialOverride(WHITE)
    render.SetColorModulation(r, g, b)
    render.SetBlend(0.42 * flicker * alpha)
    ent:DrawModel()

    render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
    render.MaterialOverride(WIRE)
    render.SetColorModulation(r * 1.2, g * 1.2, b * 1.2)
    render.SetBlend(0.3 * flicker * alpha)
    ent:DrawModel()
    render.OverrideBlend(false)
    render.PopCustomClipPlane()

    -- wandernde Scan-Linie
    local range = top - bottom + 12
    local bandZ = bottom - 6 + ((now * 18) % range)
    render.PushCustomClipPlane(DOWN, -(bandZ + 1.4))
    render.PushCustomClipPlane(UP, bandZ - 1.4)
    render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
    render.MaterialOverride(WHITE)
    render.SetColorModulation(1, 1, 1)
    render.SetBlend(0.5 * flicker * alpha)
    if bandZ < cut then ent:DrawModel() end
    render.OverrideBlend(false)
    render.PopCustomClipPlane()
    render.PopCustomClipPlane()

    -- Aufbau-Kante
    if age < 1 then
        render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
        render.SetMaterial(GLOW)
        render.DrawQuadEasy(Vector(0, 0, cut), UP, 64, 64, Color(col.r, col.g, col.b, 200), 0)
        render.DrawSprite(Vector(0, 0, cut), 70, 6, Color(col.r, col.g, col.b, 255))
        render.OverrideBlend(false)
    end

    render.MaterialOverride()
    render.SetColorModulation(1, 1, 1)
    render.SetBlend(1)
    render.EnableClipping(clipping)
end

function PANEL:DrawSweep(ent, col, age)
    local bottom, top = self._bottom, self._top
    local time = age * 2
    local modelIn = time > 1 and Ease(time - 1) or 0
    local wireIn = time < 1 and Ease(math.sqrt(math.max(time, 0))) or 1
    local lowZ, highZ = Lerp(modelIn, bottom, top + 2), Lerp(wireIn, bottom, top + 2)
    local f = time % 1
    local pulse = math.max(0, -4 * f * f + 4 * f)
    local centre = Vector(0, 0, time > 1 and lowZ or highZ)

    local clipping = render.EnableClipping(true)

    render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
    render.SetMaterial(GLOW)
    render.DrawQuadEasy(centre, UP, 60 * pulse + 10, 60 * pulse + 10, col, 0)
    render.DrawSprite(centre, 96 * pulse + 20, 10 * pulse + 2, col)
    render.OverrideBlend(false)

    render.PushCustomClipPlane(DOWN, -highZ)
    render.PushCustomClipPlane(UP, lowZ)
    render.MaterialOverride(WIRE)
    local mod = Lerp(math.Clamp(time - 1, 0, 1), 128, 48)
    render.SetColorModulation(col.r / mod, col.g / mod, col.b / mod)
    ent:DrawModel()
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride()
    render.PopCustomClipPlane()
    render.PopCustomClipPlane()

    if modelIn > 0 then
        render.PushCustomClipPlane(DOWN, -lowZ)
        ent:DrawModel()
        render.PopCustomClipPlane()
    end

    render.EnableClipping(clipping)
end

function PANEL:DrawModel()
    local ent = self.Entity
    if not IsValid(ent) then return end
    local col = self._holoColor or UI.Holo()
    local alpha = self:GetAlpha() / 255

    if self._mode == "holo" then
        Projector(self._bottom, self._top, col, alpha)
        self:DrawHolo(ent, col, alpha)
        return
    end

    local age = self._sweepStart and (RealTime() - self._sweepStart) / SWEEP_TIME or 2
    if age < 1 then
        self:DrawSweep(ent, col, age)
    else
        ent:DrawModel()
    end
end

function PANEL:PaintOver(w, h)
    if self._label and self._label ~= "" then
        local text = string.upper(self._label)
        local tw = math.max(UI.TextSize(text, "symchars.h1") + S(60), S(220))
        local bh = S(64)
        local x, y = (w - tw) / 2, h - bh - S(10)
        UI.Box(x, y, tw, bh, Color(0, 0, 0, 200))
        UI.Outline(x, y, tw, bh, UI.col.line3)
        UI.Text(text, "symchars.h1", w / 2, y + bh / 2, UI.col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("symchars.HoloModel", PANEL, "DModelPanel")

function UI.HoloModel(parent, mode)
    local p = vgui.Create("symchars.HoloModel", parent)
    p:SetMode(mode or "solid")
    return p
end
