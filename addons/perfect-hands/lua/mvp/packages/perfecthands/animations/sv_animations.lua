local P = mvp.package.Get()

P.animations = P.animations or {}

util.AddNetworkString("mvp.phands.requestAnimation")
util.AddNetworkString("mvp.phands.startAnimation")
util.AddNetworkString("mvp.phands.stopAnimation")

net.Receive("mvp.phands.requestAnimation", function(_, ply)
    local anim = net.ReadString()

    local animData = P.animations.Get(anim)
    if not animData then return end

    local canUse, reason = hook.Run("mvp.phands.CanUseAnimation", ply, anim)

    if (canUse == nil) then
        canUse = true
    end

    if (not canUse) then
        mvp.q.NotifyFail(mvp.q.Lang("general.no_permission"), reason or mvp.q.Lang("phands.cant_use_animation", mvp.q.Lang("phands.animation." .. anim)), nil, ply)

        return
    end

    net.Start("mvp.phands.startAnimation")
        net.WriteString(anim)
        net.WriteEntity(ply)
    net.Broadcast()
    ply.mvp_phands_animation_playing = true
end)

local function VelocityIsHigher(ply, value)
    local x, y, z = math.abs(ply:GetVelocity().x), math.abs(ply:GetVelocity().y), math.abs(ply:GetVelocity().z)

    if x > value or y > value or z > value then
        return true
    else
        return false
    end
end

hook.Add("SetupMove", "mvp.phands.animationStop", function(ply, moveData, cmd)
    if (not mvp.config.Get("phands.useAnimations", true)) then
        return
    end

    if (not ply.mvp_phands_animation_playing) then return end

    if (VelocityIsHigher(ply, mvp.config.Get("phands.animationVelocityCutoff", 5))) then
        net.Start("mvp.phands.stopAnimation")
            net.WriteEntity(ply)
        net.Broadcast()
        ply.mvp_phands_animation_playing = false
    end

    if (ply:KeyDown(IN_DUCK) or ply:KeyDown(IN_JUMP) or ply:KeyDown(IN_USE)) then
        net.Start("mvp.phands.stopAnimation")
            net.WriteEntity(ply)
        net.Broadcast()
        ply.mvp_phands_animation_playing = false
    end
end)