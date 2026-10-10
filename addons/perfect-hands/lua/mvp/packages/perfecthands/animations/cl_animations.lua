local P = mvp.package.Get()

P.animations = P.animations or {}

local closestBone = nil
local closestBoneDist = 999999
function P.animations.Apply(ply, animationID, targetValue)
    if (not mvp.config.Get("phands.useAnimations")) then
        return
    end

    if (not IsValid(ply)) then
        return
    end
    if (not animationID) then
        return
    end

    if (not P.animations.Get(animationID)) then
        return
    end

    if (ply.mvp_phands_animation_progress ~= targetValue) then
        ply.mvp_phands_animation_progress = Lerp(FrameTime() * (mvp.config.Get("phands.animationSpeed", 5)), ply.mvp_phands_animation_progress, targetValue)
    end

    local oldAnimationID = ply.mvp_phands_animationID_old

    if (oldAnimationID ~= animationID and P.animations.Get(oldAnimationID)) then
       
        for boneName, _ in pairs(P.animations.Get(oldAnimationID)) do
            local bone = ply:LookupBone(boneName)

            if (not bone) then
                continue
            end

            ply:ManipulateBoneAngles(bone, Angle(0, 0, 0))
        end

        if (P.animations.Get(oldAnimationID)["Animation.ZOffset"]) then
            ply:ManipulateBonePosition(0, Vector(0, 0, 0))
        end
    end

    ply.mvp_phands_animationID_old = animationID

    for boneName, angles in pairs(P.animations.Get(animationID)) do
        local bone = ply:LookupBone(boneName)

        if (not bone) then
            continue
        end

        ply:ManipulateBoneAngles(bone, angles * ply.mvp_phands_animation_progress)
    end

    if (P.animations.Get(animationID)["Animation.ZOffset"]) then
        ply:ManipulateBonePosition(0, Vector(0, 0, P.animations.Get(animationID)["Animation.ZOffset"] * ply.mvp_phands_animation_progress))
    end
end

hook.Add("Think", "mvp.phands.ApplyAnimations", function()
    if (not mvp.config.Get("phands.useAnimations")) then
        return
    end

    for k, ply in ipairs(player.GetAll()) do
        if (not IsValid(ply)) then
            continue
        end
        if (ply:InVehicle()) then
            continue
        end

        local animationID = ply.mvp_phands_animationID

        if (animationID == nil) then
            continue
        end

        if (not ply.mvp_phands_animation_progress) then
            ply.mvp_phands_animation_progress = 0
        end

        if (ply.mvp_phands_animation_playing) then
            P.animations.Apply(ply, animationID, 1)
        else
            P.animations.Apply(ply, animationID, 0)
        end
    end
end)

function P.animations.CreateCamera()
    local ply = LocalPlayer()
    local cameraAng = ply:EyeAngles()
    local savedAng = nil

    local conX = 0
    local conY = -15
    local conZ = 0

    P.animations.cameraActive = true

    hook.Add("Think", "mvp.phands.CameraLook", function()
        if (not ply:Alive()) then
            P.animations.DestroyCamera()
            return
        end

        local weapon = ply:GetActiveWeapon()
        if (IsValid(weapon) and weapon:GetClass() ~= "mvp_perfecthands") then
            P.animations.DestroyCamera()
            return
        end

        local allowFreelook = mvp.config.Get("phands.animationAllowFreelook", true)

        if (allowFreelook and not ply:KeyDown(IN_RELOAD)) then
            if (savedAng) then
                cameraAng = savedAng
            end

            savedAng = nil
            return 
        end

        savedAng = savedAng or ply:EyeAngles()
        ply:SetEyeAngles(savedAng)
    end)
    
    hook.Add("CalcView", "!!!mvp.phands.AnimationView", function(ply, camPos, ang, fov, znear, zfar)
        if (not IsValid(ply) or not cameraAng) then
            return
        end
    
        local camTr = util.TraceLine({
            start = camPos,
            endpos = camPos + (cameraAng:Forward() * 9999),
            filter = ply
        })
    
        local trace = util.TraceHull({
            start = camPos,
            endpos = camPos - cameraAng:Forward() * (100 + conZ) - cameraAng:Right() * conX - cameraAng:Up() * conY,
            filter = { ply:GetActiveWeapon(), ply },
            mins = Vector(-6, -4, -4),
            maxs = Vector(6, 4, 4)
        })

        local pos

        if (trace.Hit) then
            pos = trace.HitPos
        else
            pos = camPos - cameraAng:Forward() * (100 + conZ)
            pos = pos - cameraAng:Right() * (conX)
            pos = pos - cameraAng:Up() * (conY)
        end

        ply:SetEyeAngles( (camTr.HitPos - ply:EyePos()):Angle() )

        return {
            fov = fov,
            drawviewer = true,
            origin = pos,
            angles = cameraAng
        }
    end)

    hook.Add("InputMouseApply", "mvp.phands.ModifyMouseInput", function(cmd, x, y, ang)
        if (not cameraAng) then
            cameraAng = Angle(0, 0, 0)
        end

        cameraAng.p = math.NormalizeAngle(cameraAng.p + y / 50)
        cameraAng.y = math.NormalizeAngle(cameraAng.y - x / 50)

        cameraAng.p = math.Clamp(cameraAng.p, -60, 80)

        return true
    end)
end

function P.animations.DestroyCamera()
    hook.Remove("CalcView", "!!!mvp.phands.AnimationView")
    hook.Remove("Think", "mvp.phands.CameraLook")
    hook.Remove("InputMouseApply", "mvp.phands.ModifyMouseInput")

    P.animations.cameraActive = false
end

net.Receive("mvp.phands.startAnimation", function()
    local anim = net.ReadString()
    local ply = net.ReadEntity()

    ply.mvp_phands_animationID = anim
    ply.mvp_phands_animation_playing = true

    if (ply == LocalPlayer()) then
        P.animations.CreateCamera()
    end
end)

net.Receive("mvp.phands.stopAnimation", function()
    local ply = net.ReadEntity()

    ply.mvp_phands_animation_playing = false

    local closestBone = nil
    local closestBoneDist = 999999

    if (ply == LocalPlayer()) then
        P.animations.DestroyCamera()
    end
end)