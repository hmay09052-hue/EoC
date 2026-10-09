AddCSLuaFile()

SWEP.Base = "arccw_base_melee"
SWEP.Spawnable = true -- this obviously has to be set to true
SWEP.AdminOnly = false

SWEP.IsShieldWeapon = true


SWEP.Slot = 0

SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Coruscant Guard Shield"
SWEP.Trivia_Class = "Ballistic Shield"
SWEP.SubCategory = "7Melee"
SWEP.Trivia_Desc = "Anti-blaster fire shield for the grand army of the Republic. Stops blaster fire, specially from those damm clankers."
SWEP.Trivia_Country = "Galactic Republic"

SWEP.NotForNPCs = true

SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/republic/v_cgshield.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/v_cgshield.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(0, 15, -12),
    ang = Angle(0, 0, 180 - 15)
}

SWEP.ShieldProps = {
    {
        Model = "models/arccw/kraken/republic/v_cgshield.mdl",
        Pos = Vector(0, -15, -12),
        Ang = Angle(0, 0, 180 - 15),
        Resistance = 100
    }
}

SWEP.PrimaryBash = true

SWEP.Hook_PreBash = function(self)
    self:MyEmitSound(self.MeleeSwingSound, 75, 100, 1, CHAN_USER_BASE + 1)
end

SWEP.SpeedMult = 0.85

SWEP.MeleeDamage = 35
SWEP.MeleeRange = 32
SWEP.MeleeDamageType = DMG_CLUB
SWEP.MeleeTime = 1
SWEP.MeleeGesture = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
SWEP.MeleeAttackTime = 0

SWEP.MeleeSwingSound = {
    "arccw/kraken/republic/shield/wfoly_me_riotshield_swing_01.ogg",
    "arccw/kraken/republic/shield/wfoly_me_riotshield_swing_02.ogg",
    "arccw/kraken/republic/shield/wfoly_me_riotshield_swing_03.ogg",
    "arccw/kraken/republic/shield/wfoly_me_riotshield_swing_04.ogg",
}
SWEP.MeleeHitSound = {
    "arccw/kraken/republic/shield/shield_hit_world_01.ogg",
    "arccw/kraken/republic/shield/shield_hit_world_02.ogg",
    "arccw/kraken/republic/shield/shield_hit_world_03.ogg",
    "arccw/kraken/republic/shield/shield_hit_world_04.ogg",
}
SWEP.MeleeHitNPCSound = {
    "arccw/kraken/republic/shield/shield_hit_flesh_01.ogg",
    "arccw/kraken/republic/shield/shield_hit_flesh_02.ogg",
    "arccw/kraken/republic/shield/shield_hit_flesh_03.ogg",
    "arccw/kraken/republic/shield/shield_hit_flesh_04.ogg",
}

SWEP.Firemodes = {
    {
        Mode = 1,
        PrintName = "MELEE"
    },
}

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "melee2"

SWEP.Primary.ClipSize = -1

SWEP.Animations = {
    ["draw"] = {
        Source = "deploy",
        SoundTable = {
            { s = "arccw/kraken/republic/shield/wfoly_me_riotshield_draw.ogg", t = 0, v = 75, p = 100, c = CHAN_ITEM },
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["bash"] = {
        Source = "bash",
        Time = 2,
        SoundTable = {
            { s = "arccw/kraken/republic/shield/shield_push_01.wav", t = 0, v = 75, p = 100, c = CHAN_ITEM },
        },
    },
}

SWEP.IronSightStruct = false

SWEP.ActivePos = Vector(0, 0, 1)

SWEP.BashPreparePos = Vector(0, 0, 0)
SWEP.BashPrepareAng = Angle(0, 5, 0)

SWEP.CustomizePos = Vector(15, 5, 0)
SWEP.CustomizeAng = Angle(0, 60, 0)

SWEP.BashPos = Vector(0, 0, 0)
SWEP.BashAng = Angle(10, -10, 0)

SWEP.HolsterPos = Vector(0, -1, 2)
SWEP.HolsterAng = Angle(-15, 0, 0)

sound.Add({
    name = "ARCCW_GO_SHIELD.ShieldEquipStart",
    channel = 16,
    volume = 1.0,
    sound = "arccw/kraken/republic/shield/shield_equip_04.wav"
})

sound.Add({
    name = "ARCCW_GO_SHIELD.ShieldEquipEnd",
    channel = 16,
    volume = 1.0,
    sound = "arccw/kraken/republic/shield/shield_equip_05.wav"
})

if SERVER then
    util.AddNetworkString("ArcCW_Kraken_ShieldBlock")

    hook.Add("EntityTakeDamage", "ArcCW_Kraken_ShieldProtection", function(target, dmginfo)
        if not target:IsPlayer() then return end

        local wep = target:GetActiveWeapon()
        if not IsValid(wep) then return end
        if not wep.IsShieldWeapon then return end

        local dmgpos = dmginfo:GetDamagePosition()
        local attacker = dmginfo:GetAttacker()

        if dmgpos == vector_origin and IsValid(attacker) then
            dmgpos = attacker:GetPos()
        end

        if dmgpos == vector_origin then return end

        local aimDir = target:GetAimVector()
        local toThreat = (dmgpos - target:GetShootPos()):GetNormalized()
        local dot = aimDir:Dot(toThreat)

        if dot > 0 then

            dmginfo:SetDamage(0)
            dmginfo:SetDamageType(DMG_GENERIC)

            local snd = "arccw/kraken/republic/shield/impact_riotshield_0" .. math.random(1, 5) .. ".ogg"
            target:EmitSound(snd, 75, math.random(90, 115), 0.6, CHAN_AUTO)

            return true
        end
    end)
end

if CLIENT then
    hook.Add("EntityFireBullets", "ArcCW_Kraken_ShieldSuppressBlood", function(ent, data)
        local oldCallback = data.Callback
        data.Callback = function(attacker, tr, dmginfo)
            if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
                local wep = tr.Entity:GetActiveWeapon()
                if IsValid(wep) and wep.IsShieldWeapon then
                    local aimDir = tr.Entity:GetAimVector()
                    local toThreat = (tr.StartPos - tr.Entity:GetShootPos()):GetNormalized()
                    if aimDir:Dot(toThreat) > 0 then

                        return
                    end
                end
            end
            if oldCallback then oldCallback(attacker, tr, dmginfo) end
        end
        return true
    end)
end
