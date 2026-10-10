AddCSLuaFile()

SWEP.Base = "arccw_k_nade_base"
SWEP.Spawnable = true

SWEP.Slot = 4

SWEP.Category = "[ArcCW] Kraken's Explosives - Grenades"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "C-25 Fragmentation Grenade"
SWEP.Trivia_Class = "Hand Grenade, Fragmentation Grenade"
SWEP.Trivia_Desc = "The C-25 fragmentation grenade was a fragmentation grenade manufactured by Merr-Sonn Munitions, Inc.. It consisted of a sphere of baradium-impregnated detonite encased in a conductive shell, which was itself housed within a cylinder that was activated with a twist"
SWEP.Trivia_Manufacturer = "Merr-Sonn Munitions, Inc"
SWEP.Trivia_Calibre = "High Fragmentation Explosive"
SWEP.Trivia_Mechanism = "Explosive"
SWEP.Trivia_Country = "Galactic Empire"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_c25.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_c25.mdl"

SWEP.ViewModelFOV = 56

SWEP.WorldModelOffset = {
    pos = Vector(-10.9, -4, -2),
    ang = Angle(0, 0, -50),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

SWEP.ShootEntity = "arccw_nade_k_thrown_c25"

SWEP.MuzzleVelocity = 1050
SWEP.MuzzleVelocityAlt = 500

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 1

SWEP.FuseTime = 3.5
SWEP.PullPinTime = 0.5

SWEP.Num = 1
SWEP.Firemodes = {
    {
        Mode = 1,
    },
}

SWEP.SpeedMult = 0.925
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

SWEP.Primary.Ammo = "grenade"

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "grenade"
SWEP.HoldtypeSights = "grenade"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE

SWEP.ActivePos = Vector(0, 6, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(0, -1, -0.3)
SWEP.SprintAng = Angle(3, -5, 0)

SWEP.CrouchPos = Vector(-0.5, -0, -1)
SWEP.CrouchAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["idle_sprint"] = {Source = "sprint", Mult = 0.9},
    ["enter_sprint"] = {Source = "sprint_in", Mult = 0.1},
    ["exit_sprint"] = {Source = "sprint_out", Mult = 0.1},
    ["ready"] = {
        Source = "draw",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Draw", t = 0.1/30},
        },
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Draw", t = 0.1/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Holster", t = 0.1/30},
        },
    },
    ["pre_throw"] = {
        Source = "pullpin",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.PreThrow", t = 0.1/30},
        },
        MinProgress = 0.5,
    },
    ["fire"] = {
        Source = "pullpin",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Throw", t = 0.1/30},
        },
    },
    ["throw"] = {
        Source = {"toss_overhead"},
        TPAnim = ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE,
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Throw", t = 0.1/30},
        },
    },
    ["throw_alt"] = {
        Source = {"underhand"},
        Mult = 1,
        TPAnim = ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE,
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Throw", t = 0.1/30},
        },
    },
    ["bash"] = {
        Source = {"melee"},
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.6,
        LHIKEaseOut = 0.4,
    },
    ["enter_inspect"] = {
        Source = "inspect_in",
        LHIK = true,
    },
    ["exit_inspect"] = {
        Source = "inspect_out",
        LHIK = true,
    },
    ["idle_inspect"] = {
        Source = "inspect",
        LHIK = true,
    },
}
