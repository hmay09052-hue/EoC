SWEP.Base = "arccw_base_melee"
SWEP.Spawnable = true
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.AdminOnly = false

SWEP.PrintName = "Guard Pike"
SWEP.Trivia_Class = "Melee"
SWEP.SubCategory = "7Melee"
SWEP.Trivia_Desc = "Melee weapon with good damage. Designed and prepared for Red Guards from the Galactic Empire."
SWEP.Trivia_Manufacturer = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/guardpike.png"

SWEP.Slot = 0
SWEP.NPCWeaponType = "weapon_crowbar"
SWEP.NPCWeight = 250

SWEP.MuzzleEffectAttachment = 1
SWEP.CaseEffectAttachment = 2
SWEP.CamAttachment = 3

SWEP.UseHands = true

SWEP.ViewModelFOV = 54 

SWEP.ViewModel = "models/arccw/kraken/empire/v_melee_guardpike.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_guardpike.mdl"
SWEP.MirrorVMWM = true
SWEP.WorldModelOffset = {
    pos = Vector(-14, 5, -8),
    ang = Angle(-10, 0, 180 + 5)
}

SWEP.SprintPos = Vector(0, -2, 1)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.ActivePos = Vector(0, -2, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(0, -2, 1)
SWEP.CustomizeAng = Angle(0, 0, 0)


SWEP.ImpactEffect = "StunstickImpact"
SWEP.MeleeGesture = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
SWEP.ShootWhileSprint = true
SWEP.NotForNPCs = true

SWEP.Firemodes = {
    {
        Mode = 1,
        PrintName = "PIKE"
    },
}

SWEP.PrimaryBash = true
SWEP.CanBash = true
SWEP.MeleeDamage = 45
SWEP.MeleeRange = 119
SWEP.MeleeDamageType = DMG_SHOCK + DMG_AIRBOAT + DMG_GENERIC + DMG_CLUB

SWEP.MeleeHitSound = "arccw/kraken/new_empire/melee/sword.mp3"
SWEP.MeleeHitNPCSound = "arccw/kraken/new_empire/melee/sword.mp3"
SWEP.MeleeMissSound = "arccw/kraken/new_empire/melee/sword.mp3"
SWEP.MeleeSwingSound = "arccw/kraken/new_empire/melee/spearattack.mp3"

SWEP.MeleeTime = 1
SWEP.MeleeAttackTime = 0.35*0.75
SWEP.Delay = 60 / 670

SWEP.Lunge = true
SWEP.LungeLength = 72

SWEP.Melee2 = true
SWEP.Melee2Damage = 75
SWEP.Melee2DamageBackstab = 100
SWEP.Melee2Range = 30
SWEP.Melee2Time = 1
SWEP.Melee2Gesture = nil
SWEP.Melee2AttackTime = 0.25

SWEP.Backstab = true
SWEP.BackstabMultiplier = 2

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "melee2"
SWEP.DrawCrosshair = true
SWEP.IronSightStruct = false
SWEP.ShootWhileSprint = false

SWEP.Primary.ClipSize = -1

SWEP.Attachments = {     
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
    }, 
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["draw"] = {
        Source = {"draw", "draw2", "draw3"},
        SoundTable = {
            {s = "arccw/kraken/new_empire/melee/new/rampart/problemsolver_swing_wrenchfoley_v1_2ch_03.ogg", t = 0.1/30},
        },
    },
    ["holster"] = {
        Source = "putaway",
        SoundTable = {
            {s = "arccw/kraken/new_empire/melee/new/rampart/problemsolver_insp_batteryreplace_g_v1_2ch_01.ogg", t = 0.1/30},
        },
    },
    ["ready"] = {
        Source = {"draw", "draw2", "draw3"},
        SoundTable = {
            {s = "arccw/kraken/new_empire/melee/new/rampart/problemsolver_swing_wrenchfoley_v1_2ch_03.ogg", t = 0.1/30},
        },
    },
    ["bash"] = {
        Source = {"melee_jump","melee_sliding","melee_smack_down","melee_sprinting","melee_swing_down"},
    },
    ["bash2"] = {
        Source = {"melee_swirl","melee_reversal"},
    },
    ["bash_backstab"] = {
        Source = {"melee_crouch"},
    },
    ["bash2_backstab"] = {
        Source = {"melee_crouch"},
    },
    ["enter_inspect"] = {
        Source = "inspect_in",
    },
    ["exit_inspect"] = {
        Source = "inspect_out",
    },
    ["idle_inspect"] = {
        Source = "inspect",
    },
}
