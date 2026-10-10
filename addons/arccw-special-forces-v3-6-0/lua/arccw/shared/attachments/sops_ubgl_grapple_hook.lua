local HOOK_ENT_CLASS = "arccw_kraken_ubgl_hook"

att.PrintName    = "GRAPPLING HOOK"
att.AbbrevName   = "GRAPPLE"
att.Description  = "Adds a grappling hook as an underbarrel module. Launch, retract or extend a tether to pull yourself or light entities. Replicates the original hats_hook behavior."
att.SortOrder    = -99999

att.Icon         = Material("entities/kraken/sops/atts/grapple.png", "mips smooth")
att.AutoStats    = true

att.Free         = true
att.NotForNPCs   = true

att.Slot         = "swrp_ubgl_grapple"

att.UBGL             = true
att.UBGL_PrintName   = "Grapple"
att.UBGL_Automatic   = true
att.UBGL_ClipSize    = 1
att.UBGL_Capacity    = 1   -- required: cl_hud.lua GetHUDData compares clip2 > UBGL_Capacity unguarded; nil here crashes the HUD
att.UBGL_Ammo        = "Pistol"
att.UBGL_RPM         = 600
att.UBGL_Recoil      = 0
att.UBGL_BaseAnims   = false

att.SelectUBGLSound  = ""
att.ExitUBGLSound    = ""

local ServerConvarFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
if not ConVarExists("kraken_grapple_hookplayers") then
    CreateConVar("kraken_grapple_hookplayers", "1", ServerConvarFlags, "Allows the Grappling Hook to grab players")
    CreateConVar("kraken_grapple_physics",     "1", ServerConvarFlags, "Grappling hook is launched as a projectile")
    CreateConVar("kraken_grapple_speed",       "1000", ServerConvarFlags, "Launch velocity of the grappling hook (Max range for non-physics hooks)")
    CreateConVar("kraken_grapple_breakpower",  "3", ServerConvarFlags, "Strength of each breakout attempt")
    CreateConVar("kraken_grapple_breakregen",  "1", ServerConvarFlags, "Breakout depletion rate")
    CreateConVar("kraken_grapple_ammo",        "-1", ServerConvarFlags, "Number of uses each grappling hook has. -1 is infinite.")
end

local function GetHook(wep)        return wep:GetNWEntity("ArcCWKrakenGrappleHook") end
local function SetHook(wep, ent)   wep:SetNWEntity("ArcCWKrakenGrappleHook", ent) end
local function GetCooldown(wep)    return wep:GetNWInt("ArcCWKrakenGrappleCooldown", 0) end
local function SetCooldown(wep, v) wep:SetNWInt("ArcCWKrakenGrappleCooldown", math.max(v or 0, 0)) end

local function GetClip(wep)
    local v = wep.ArcCWKrakenGrappleClip
    if v == nil then
        local initial = cvars.Number("kraken_grapple_ammo") or (-1)
        wep.ArcCWKrakenGrappleClip = initial
        return initial
    end
    return v
end

local function AddClip(wep, delta)
    if GetClip(wep) < 0 then return end
    wep.ArcCWKrakenGrappleClip = math.max((wep.ArcCWKrakenGrappleClip or 0) + delta, 0)
end

local function GetFilter(wep)
    return cvars.Bool("kraken_grapple_hookplayers") and {wep:GetOwner()} or player.GetAll()
end

local function EnsureWeaponMethodBridge(wep)
    if wep.ArcCWKrakenGrappleMethodsInstalled then return end
    function wep:SetCooldown(v) SetCooldown(self, v) end
    function wep:GetCooldown() return GetCooldown(self) end
    function wep:SetHook(ent)  SetHook(self, ent) end
    function wep:GetHook()     return GetHook(self) end
    wep.ArcCWKrakenGrappleMethodsInstalled = true
end

local function LaunchInstant(wep)
    local owner = wep:GetOwner()
    if not IsValid(owner) then return end
    local muzzle = owner:GetShootPos()
    local tr = util.TraceLine({
        start  = muzzle,
        endpos = muzzle + (owner:GetAimVector() * cvars.Number("kraken_grapple_speed")),
        filter = GetFilter(wep),
    })
    if tr.HitSky or not tr.Hit then return end
    sound.Play("physics/metal/metal_canister_impact_soft" .. math.random(1, 3) .. ".wav", muzzle, 75, 100, 0.5)
    owner:ViewPunch(Angle(math.Rand(-10, -5), math.Rand(-4, 4), 0))
    local hk = ents.Create(HOOK_ENT_CLASS)
    if not IsValid(hk) then return end
    hk:SetPos(tr.HitPos)
    hk:SetAngles(tr.Normal:Angle())
    hk.FireVelocity = Vector(0, 0, 0)
    hk:SetOwner(owner)
    hk:Spawn()
    SetHook(wep, hk)
    hk:SetWep(wep)
    hk:PhysicsCollide({HitEntity = tr.Entity, HitPos = tr.HitPos, HitNormal = tr.Normal})
end

local function LaunchHook(wep)
    local owner = wep:GetOwner()
    if not IsValid(owner) then return end

    local muzzle = owner:GetShootPos()
    local clip = GetClip(wep)
    if clip == 0 then return end
    if clip > 0 then AddClip(wep, -1) end
    if not cvars.Bool("kraken_grapple_physics") then return LaunchInstant(wep) end
    sound.Play("physics/metal/metal_canister_impact_soft" .. math.random(1, 3) .. ".wav", muzzle, 75, 100, 0.5)
    owner:ViewPunch(Angle(math.Rand(-5, -2.5), math.Rand(-2, 2), 0))
    local hk = ents.Create(HOOK_ENT_CLASS)
    if not IsValid(hk) then return end
    hk:SetPos(muzzle - owner:GetAimVector() * 5)
    local ang = owner:EyeAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    hk:SetAngles(ang)
    hk.FireVelocity = owner:GetAimVector() * 500
    hk:SetOwner(owner)
    hk:Spawn()
    SetHook(wep, hk)
    hk:SetWep(wep)
end

local function ValidPullEnt(ent)
    if (not IsValid(ent)) or ent:IsPlayer() then return false end
    local phys = ent:GetPhysicsObject()
    return (not IsValid(phys))
        or ((not phys:HasGameFlag(FVPHYSICS_NO_PLAYER_PICKUP))
            and (phys:GetMass() <= 50)
            and (ent.CanPickup ~= false)
            and phys:IsMotionEnabled())
end

local function PlayerMoveHandlerFactory(wep)
    return function(ply, mv, cmd)
        if not IsValid(wep) then return end
        local owner = wep:GetOwner()
        local hk = GetHook(wep)
        if not wep:GetInUBGL() then return end
        if not (IsValid(hk) and hk.GetHasHit and hk:GetHasHit()) then return end
        if not (IsValid(owner) and IsValid(ply) and owner:Alive() and ply:Alive()) then return end
        local targ = (hk.GetTargetEnt and hk:GetTargetEnt()) or nil
        local isOwner = ply == owner
        local targIsValid = IsValid(targ)
        local isTarget = targIsValid and ply == targ

        if not isOwner and not isTarget then return end
        if isTarget and not targ:IsPlayer() and not ValidPullEnt(targ) then return end

        if ply:InVehicle() or owner:InVehicle() or (not ply:Alive()) then
            if SERVER then
                SetCooldown(wep, 10)
                hk:Remove()
            end
            return
        end
        if ply ~= owner then
            ply.was_pushed = {t = CurTime(), att = owner}
        end
        local TargetPoint = hk:GetPos()
        local ApproachDir = (TargetPoint - ply:GetPos()):GetNormal()
        local ShootPos = owner:GetShootPos() + (Vector(0, 0, (owner:Crouching() and 0) or (hk:GetUp()[1] > 0.9 and -45) or 0))
        local Distance = hk:GetDist()
        if ply ~= owner then
            TargetPoint = ShootPos
            ShootPos = ply:GetShootPos() + (Vector(0, 0, (ply:Crouching() and 0) or (hk:GetUp()[1] > 0.9 and -45) or 0))
            ApproachDir = (TargetPoint - ply:GetPos()):GetNormal()
        end
        local DistFromTarget = ShootPos:Distance(TargetPoint)
        if DistFromTarget < (Distance + 5) then return end
        local TargetPos = TargetPoint - (ApproachDir * Distance)
        local xDif = math.abs(ShootPos[1] - TargetPos[1])
        local yDif = math.abs(ShootPos[2] - TargetPos[2])
        local zDif = math.abs(ShootPos[3] - TargetPos[3])
        local speedMult = 3 + ((xDif + yDif) * 0.5) ^ 1.01
        local vertMult = math.max((math.max(300 - (xDif + yDif), -10) * 0.08) ^ 1.01 + (zDif / 2), 0)
        if ply ~= owner and owner:GetGroundEntity() == ply then vertMult = -vertMult end
        local TargetVel = (TargetPos - ShootPos):GetNormal() * 10
        TargetVel[1] = TargetVel[1] * speedMult
        TargetVel[2] = TargetVel[2] * speedMult
        TargetVel[3] = TargetVel[3] * vertMult
        local dir = mv:GetVelocity()
        local clamp = 50
        local vclamp = 20
        local accel = 200
        local vaccel = 30 * (vertMult / 50)
        dir[1] = (dir[1] > TargetVel[1] - clamp or dir[1] < TargetVel[1] + clamp) and math.Approach(dir[1], TargetVel[1], accel) or dir[1]
        dir[2] = (dir[2] > TargetVel[2] - clamp or dir[2] < TargetVel[2] + clamp) and math.Approach(dir[2], TargetVel[2], accel) or dir[2]
        if ShootPos[3] < TargetPos[3] then
            dir[3] = (dir[3] > TargetVel[3] - vclamp or dir[3] < TargetVel[3] + vclamp) and math.Approach(dir[3], TargetVel[3], vaccel) or dir[3]
            wep._ArcCWKrakenGrappleForceJump = ply
        end
        mv:SetVelocity(dir)
    end
end

local function ForceJumpThink(wep)
    local ply = wep._ArcCWKrakenGrappleForceJump
    if not ply then return end
    wep._ArcCWKrakenGrappleForceJump = nil
    if not (IsValid(ply) and ply:IsPlayer()) then return end
    if not ply:OnGround() then return end
    local tr = util.TraceLine({start = ply:GetPos(), endpos = ply:GetPos() + Vector(0, 0, 20), filter = ply})
    if tr.Hit then return end
    ply:SetPos(ply:GetPos() + Vector(0, 0, 5))
end

local function RemoveMoveHook(wep)
    if wep._ArcCWKrakenGrappleMoveHook then
        hook.Remove("SetupMove", wep._ArcCWKrakenGrappleMoveHook)
        wep._ArcCWKrakenGrappleMoveHook = nil
    end
end

local function EnsureMoveHook(wep)
    if wep._ArcCWKrakenGrappleMoveHook then return end
    local id = "ArcCW_KrakenGrapple_Move_" .. wep:EntIndex()
    wep._ArcCWKrakenGrappleMoveHook = id
    hook.Add("SetupMove", id, PlayerMoveHandlerFactory(wep))
end

local function BreakRope(wep)
    local hk = GetHook(wep)
    if not IsValid(hk) then return end
    if hk:GetDurability() > 0 then
        SetCooldown(wep, hk:GetDurability() + 20)
    else
        SetCooldown(wep, 10)
    end
    hk:Remove()
end

if CLIENT then
    local HookCable = Material("cable/physbeam")
    local HUD_BarColor    = Color(120, 200, 255)
    local HUD_DangerColor = Color(255, 90, 90)
    local HUD_TextCol     = Color(235, 245, 255)
    local HUD_DimCol      = Color(170, 195, 220)

    surface.CreateFont("arccw_kraken_grapple_small", {
        font = SYMUI and SYMUI.FontFace("body") or "Roboto",
        size = 17,
        weight = 500,
        antialias = true,
        extended = true,
    })
    surface.CreateFont("arccw_kraken_grapple_label", {
        font = SYMUI and SYMUI.FontFace("body") or "Roboto",
        size = 14,
        weight = 400,
        antialias = true,
        extended = true,
    })
    surface.CreateFont("arccw_kraken_grapple_large", {
        font = SYMUI and SYMUI.FontFace("body") or "Roboto",
        size = 22,
        weight = 600,
        antialias = true,
        extended = true,
    })

    local function GetMuzzlePos(wep)
        if not IsValid(wep) then return nil end
        local owner = wep:GetOwner()

        if IsValid(owner) and owner == LocalPlayer() and not hook.Call("ShouldDrawLocalPlayer", GAMEMODE, owner) then
            local vm = owner:GetViewModel()
            if IsValid(vm) then
                local idx = vm:LookupAttachment("muzzle") or vm:LookupAttachment("1") or 1
                local atta = vm:GetAttachment(idx or 1)
                if atta and atta.Pos then return atta.Pos end
            end
        end

        local idx = wep:LookupAttachment("muzzle") or wep:LookupAttachment("1") or 1
        local atta = wep:GetAttachment(idx or 1)
        if atta and atta.Pos then return atta.Pos end

        if IsValid(owner) then return owner:GetShootPos() end
        return nil
    end

    local function DrawRope(wep)
        local owner = wep:GetOwner()
        local hk = GetHook(wep)
        if not IsValid(hk) then return end
        if owner ~= LocalPlayer() or hook.Call("ShouldDrawLocalPlayer", GAMEMODE, owner) then return hk:Draw() end
        local attPos = GetMuzzlePos(wep)
        if not attPos then return end
        if IsValid(hk:GetTargetEnt()) then
            local bpos, bang = hk:GetTargetEnt():GetBonePosition(hk:GetFollowBone())
            local npos, nang = hk:GetFollowOffset(), hk:GetFollowAngle()
            if npos and nang and bpos and bang then
                npos:Rotate(nang)
                nang = nang + bang
                npos = bpos + npos
                hk:SetPos(npos)
                hk:SetAngles(nang)
            end
        end
        render.SetMaterial(HookCable)
        render.DrawBeam(hk:GetPos(), attPos, 2, 0, 1, Color(255, 255, 255, 255))
    end

    local function DrawMinimalBar(xpos, ypos, width, charge, col)
        charge = math.Clamp(charge or 0, 0, 100)
        col = col or HUD_BarColor
        surface.SetDrawColor(255, 255, 255, 22)
        surface.DrawRect(xpos, ypos, width, 2)
        surface.SetDrawColor(col.r, col.g, col.b, 220)
        surface.DrawRect(xpos, ypos, width * (charge / 100), 2)
    end

    local function ShadowText(txt, font, x, y, col)
        col = col or HUD_TextCol
        draw.DrawText(txt, font, x + 1, y + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.DrawText(txt, font, x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    local LINE_H = 18
    local function DrawHardKey(keyText, action, x, y)
        ShadowText(keyText .. "  -  " .. action, "arccw_kraken_grapple_small", x, y)
    end

    local function DrawHUD_Grapple(wep)
        if not wep:GetInUBGL() then return end
        local hk = GetHook(wep)
        local cx = ScrW() / 2
        local barW = 160
        local hintsY = ScrH() - 320

        local clip = GetClip(wep)
        local clipText = (clip >= 0) and ("   |   " .. tostring(clip) .. " HOOKS") or ""

        if IsValid(hk) and hk:GetHasHit() then
            ShadowText("ROPE LENGTH  " .. tostring(hk:GetDist()) .. clipText, "arccw_kraken_grapple_label", cx, hintsY - 26, HUD_DimCol)

            local y = hintsY
            DrawHardKey("MOUSE1", "Retract rope", cx, y); y = y + LINE_H
            DrawHardKey("MOUSE2", "Extend rope",  cx, y); y = y + LINE_H
            DrawHardKey("R",      "Break rope",   cx, y); y = y + LINE_H

            if IsValid(hk:GetTargetEnt()) and hk:GetTargetEnt():IsPlayer() then
                DrawMinimalBar(cx - barW / 2, hintsY - 4, barW, hk:GetDurability(), HUD_DangerColor)
            else
                DrawHardKey("T", "Jump off", cx, y)
            end
        elseif GetCooldown(wep) > 0 then
            ShadowText("RECHARGING" .. clipText, "arccw_kraken_grapple_label", cx, hintsY - 14, HUD_DimCol)
            DrawMinimalBar(cx - barW / 2, hintsY + 8, barW, GetCooldown(wep), HUD_DimCol)
        else
            if IsValid(hk) and not hk:GetHasHit() then
                ShadowText("HOOK IN FLIGHT" .. clipText, "arccw_kraken_grapple_label", cx, hintsY - 26, HUD_DimCol)
            elseif clip >= 0 then
                ShadowText(tostring(clip) .. " HOOKS READY", "arccw_kraken_grapple_label", cx, hintsY - 26, HUD_DimCol)
            end

            local y = hintsY
            DrawHardKey("MOUSE1", "Launch grapple",        cx, y); y = y + LINE_H
            DrawHardKey("MOUSE2", "Extend (when hooked)",  cx, y); y = y + LINE_H
            DrawHardKey("R",      "Break rope",            cx, y); y = y + LINE_H
            DrawHardKey("T",      "Jump off (when above)", cx, y)
        end
    end

    local function EnsureClientHooks(wep)
        if wep._ArcCWKrakenGrappleClientHooks then return end
        local id = "ArcCW_KrakenGrapple_Client_" .. wep:EntIndex()
        hook.Add("HUDPaint", id, function()
            if IsValid(wep) and wep:GetOwner() == LocalPlayer() then DrawHUD_Grapple(wep) end
        end)
        hook.Add("PostDrawOpaqueRenderables", id, function()
            if IsValid(wep) and IsValid(wep:GetOwner()) then DrawRope(wep) end
        end)
        wep._ArcCWKrakenGrappleClientHooks = true
    end

    local function RemoveClientHooks(wep)
        if not wep._ArcCWKrakenGrappleClientHooks then return end
        local id = "ArcCW_KrakenGrapple_Client_" .. wep:EntIndex()
        hook.Remove("HUDPaint", id)
        hook.Remove("PostDrawOpaqueRenderables", id)
        wep._ArcCWKrakenGrappleClientHooks = nil
    end

    function _G.ArcCWKrakenGrappleClientThink(wep)
        local lp = LocalPlayer()
        local active = IsValid(lp) and lp:GetActiveWeapon() == wep
        if wep:GetInUBGL() and active then
            EnsureClientHooks(wep)
        else
            RemoveClientHooks(wep)
        end
    end

    function _G.ArcCWKrakenGrappleClientCleanup(wep)
        RemoveClientHooks(wep)
    end
end

local function DoJumpOff(ply)
    if not (IsValid(ply) and ply:Alive()) then return end
    local wep = ply:GetActiveWeapon()
    if not (IsValid(wep) and wep.ArcCW and wep:GetInUBGL()) then return end
    local hk = GetHook(wep)
    if not (IsValid(hk) and hk.GetHasHit and hk:GetHasHit()) then return end
    if ply ~= wep:GetOwner() then return end

    if hk:GetPos()[3] > ply:GetShootPos()[3] then
        ply:SetVelocity(Vector(0, 0, 300))
    end
    SetCooldown(wep, 10)
    hk:Remove()
end

if SERVER then
    util.AddNetworkString("ArcCW_KrakenGrapple_JumpOff")
    net.Receive("ArcCW_KrakenGrapple_JumpOff", function(_, ply)
        DoJumpOff(ply)
    end)
end

if CLIENT then
    local lastT = false
    local nextSend = 0
    hook.Add("Think", "ArcCW_KrakenGrapple_TKey", function()
        local lp = LocalPlayer()
        if not IsValid(lp) then lastT = false return end
        local wep = lp:GetActiveWeapon()
        local valid = IsValid(wep) and wep.ArcCW and wep:GetInUBGL()
        local pressed = input.IsKeyDown(KEY_T)
        if valid and pressed and not lastT and CurTime() >= nextSend then
            local hk = GetHook(wep)
            if IsValid(hk) and hk.GetHasHit and hk:GetHasHit() then
                net.Start("ArcCW_KrakenGrapple_JumpOff")
                net.SendToServer()
                nextSend = CurTime() + 0.25
            end
        end
        lastT = pressed
    end)
end

att.Hook_ShouldNotSight = function(wep)
    if wep:GetInUBGL() then return true end
end

att.UBGL_Fire = function(wep, ubgl)
    if not SERVER then return end
    local owner = wep:GetOwner()
    if not IsValid(owner) then return end
    local hk = GetHook(wep)
    local hookHit = IsValid(hk) and hk.GetHasHit and hk:GetHasHit()

    if hookHit then
        hk:SetDist(math.Approach(hk:GetDist(), 0, 10))
        return
    end

    if not IsValid(hk) and GetCooldown(wep) <= 0 then
        LaunchHook(wep)
    end
end

att.UBGL_Reload = function(wep, ubgl)
    if SERVER then BreakRope(wep) end
end

att.Hook_Think = function(wep)
    if CLIENT and _G.ArcCWKrakenGrappleClientThink then
        _G.ArcCWKrakenGrappleClientThink(wep)
    end

    if SERVER then
        if not wep._ArcCWKrakenGrappleCooldownTick or wep._ArcCWKrakenGrappleCooldownTick < CurTime() then
            SetCooldown(wep, math.Approach(GetCooldown(wep), 0, 2))
            wep._ArcCWKrakenGrappleCooldownTick = CurTime() + 0.1
        end
    end

    if wep:Clip2() <= 0 then wep:SetClip2(1) end
    EnsureWeaponMethodBridge(wep)

    if not wep:GetInUBGL() then
        RemoveMoveHook(wep)
        return
    end

    if wep.GetState and wep:GetState() == ArcCW.STATE_SIGHTS then wep:ExitSights() end

    EnsureMoveHook(wep)

    local owner = wep:GetOwner()
    if not IsValid(owner) then return end

    local hk = GetHook(wep)
    local hookHit = IsValid(hk) and hk.GetHasHit and hk:GetHasHit()

    if hookHit and owner:KeyDown(IN_ATTACK2) then
        if not wep._ArcCWKrakenGrappleExtendNext or wep._ArcCWKrakenGrappleExtendNext < CurTime() then
            if SERVER then hk:SetDist(hk:GetDist() + 10) end
            wep._ArcCWKrakenGrappleExtendNext = CurTime() + 0.05
        end
    end

    if SERVER and hookHit and hk.GetTargetEnt and IsValid(hk:GetTargetEnt()) then
        local targ = hk:GetTargetEnt()
        local phys = targ:GetPhysicsObject()
        if ValidPullEnt(targ) and IsValid(phys) and not targ:IsPlayer() then
            local TargetPoint = owner:GetShootPos()
            local ShootPos = targ:GetPos()
            local ApproachDir = (TargetPoint - targ:GetPos()):GetNormal()
            local Distance = hk:GetDist()
            local DistFromTarget = ShootPos:Distance(TargetPoint)
            if DistFromTarget >= (Distance + 5) then
                local TargetPos = TargetPoint - (ApproachDir * Distance)
                local xDif = math.abs(ShootPos[1] - TargetPos[1])
                local yDif = math.abs(ShootPos[2] - TargetPos[2])
                local zDif = math.abs(ShootPos[3] - TargetPos[3])
                local speedMult = 3 + ((xDif + yDif) * 0.5) ^ 1.01
                local vertMult = math.max((math.max(100 - (xDif + yDif), -10) * 0.1) ^ 1.01 + (zDif / 2), 0)
                if owner:GetGroundEntity() == targ then vertMult = -vertMult end
                local TargetVel = (TargetPos - ShootPos):GetNormal() * 6 * (1 - (phys:GetMass() / 50))
                TargetVel[1] = TargetVel[1] * speedMult
                TargetVel[2] = TargetVel[2] * speedMult
                TargetVel[3] = TargetVel[3] * vertMult
                local dir = targ:GetVelocity()
                local clamp = 50
                local vclamp = 20
                local accel = 200
                local vaccel = 40 * (vertMult / 50)
                dir[1] = (dir[1] > TargetVel[1] - clamp or dir[1] < TargetVel[1] + clamp) and math.Approach(dir[1], TargetVel[1], accel) or dir[1]
                dir[2] = (dir[2] > TargetVel[2] - clamp or dir[2] < TargetVel[2] + clamp) and math.Approach(dir[2], TargetVel[2], accel) or dir[2]
                if ShootPos[3] < TargetPos[3] and vertMult ~= 0 then
                    dir[3] = (dir[3] > TargetVel[3] - vclamp or dir[3] < TargetVel[3] + vclamp) and math.Approach(dir[3], TargetVel[3], vaccel) or dir[3]
                end
                phys:SetVelocity(dir)
            end
        end
    end

    ForceJumpThink(wep)
end

att.Hook_OnHolster = function(wep)
    RemoveMoveHook(wep)
    if CLIENT and _G.ArcCWKrakenGrappleClientCleanup then
        _G.ArcCWKrakenGrappleClientCleanup(wep)
    end
end
