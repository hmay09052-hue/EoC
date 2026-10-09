EoCSport = EoCSport or {}

local C = EoCSport.Config
local cam = C.Camera

local blend = 0
local camAng = Angle()
local wasActive = false
local lastHeight = 50

local function LocalState()
    local lp = LocalPlayer()
    local st = IsValid(lp) and EoCSport.States[lp]
    if st and not st.leaving then return true, st end
    if EoCSport.Preview then return true, nil end
    return false, st
end

local function Smooth(t)
    return t * t * (3 - 2 * t)
end

hook.Add("Think", "EoCSport_View", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local active, st = LocalState()
    if active and not wasActive then
        camAng = lp:EyeAngles()
        camAng.r = 0
    end
    wasActive = active

    if EoCSport.Preview then
        camAng = Angle(15, EoCSport.Preview.yaw + (EoCSport.PreviewCamYaw or 160), 0)
        lastHeight = 40
    elseif st then
        local ex = EoCSport.GetExercise(st.id)
        if ex and not st.leaving then lastHeight = ex.camHeight or 50 end
    end

    blend = math.Approach(blend, active and 1 or 0, FrameTime() / cam.BlendTime)
end)

-- Maus dreht nur die Kamera, nicht den Körper.
hook.Add("InputMouseApply", "EoCSport_View", function(cmd, x, y)
    local lp = LocalPlayer()
    local st = EoCSport.States[lp]
    if not st or st.leaving then return end

    local yawScale = GetConVar("m_yaw"):GetFloat()
    local pitchScale = GetConVar("m_pitch"):GetFloat()
    camAng.y = math.NormalizeAngle(camAng.y - x * yawScale)
    camAng.p = math.Clamp(camAng.p + y * pitchScale, cam.MinPitch, cam.MaxPitch)

    cmd:SetMouseX(0)
    cmd:SetMouseY(0)
    return true
end)

hook.Add("CalcView", "EoCSport_View", function(ply, origin, angles, fov)
    if blend <= 0 then return end

    local t = Smooth(blend)
    local target = ply:GetPos() + Vector(0, 0, lastHeight)
    local desired = target - camAng:Forward() * cam.Distance + camAng:Right() * cam.Side + Vector(0, 0, cam.Up)

    local tr = util.TraceHull({
        start = target,
        endpos = desired,
        mins = Vector(-6, -6, -6),
        maxs = Vector(6, 6, 6),
        filter = function(ent) return ent ~= ply and not ent:IsPlayer() end,
        mask = MASK_SOLID,
    })

    return {
        origin = LerpVector(t, origin, tr.HitPos),
        angles = LerpAngle(t, angles, camAng),
        fov = fov,
        drawviewer = true,
    }
end)

hook.Add("ShouldDrawLocalPlayer", "EoCSport_View", function()
    if blend > 0.05 then return true end
end)

hook.Add("PreDrawViewModel", "EoCSport_View", function()
    if blend > 0 then return true end
end)

hook.Add("HUDShouldDraw", "EoCSport_View", function(name)
    if name == "CHudCrosshair" and blend > 0 then return false end
end)
