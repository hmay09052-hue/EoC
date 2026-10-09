AddCSLuaFile()

SWEP.Base = "arccw_k_nade_base"
SWEP.Spawnable = true

SWEP.Slot = 4

SWEP.Category = "[ArcCW] Kraken's Explosives - Grenades"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Class-A Thermal Detonator"
SWEP.Trivia_Class = "Hand Grenade, High Explosive"
SWEP.Trivia_Desc = "Thermal detonators, also known as thermal charges or thermal devices, were palm-sized, spherical devices that were used as extremely deadly explosive weapons."
SWEP.Trivia_Manufacturer = "BlastTech Industries, Merr-Sonn Munitions Inc."
SWEP.Trivia_Calibre = "Explosive"
SWEP.Trivia_Mechanism = "Thermal Detonator"
SWEP.Trivia_Country = "Universal"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_thermal.mdl"
SWEP.WorldModel = "models/arccw/kraken/w_e11.mdl"

SWEP.ViewModelFOV = 56

SWEP.WorldModelOffset = {
    pos = Vector(-9, 6, -2),
    ang = Angle(-10, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

SWEP.ShootEntity = "arccw_nade_k_thrown_thermal"

SWEP.MuzzleVelocity = 850
SWEP.MuzzleVelocityAlt = 500

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 1

SWEP.FuseTime = 3
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
    ["idle_primed"] = {
        Source = "idle_primed"
    },
    ["draw"] = {
        Source = "deploy",
    },
    ["holster"] = {
        Source = "holster",
		Mult = 0.5,
        SoundTable = {
            {s = "kraken/shared/rifle_fetch-1.wav", t = 0.1/30},
        },
    },
    ["pre_throw"] = {
        Source = "pullpin",
        MinProgress = 0.666,
        FireASAP = true,
        SoundTable = {
            {s = "kraken/explosives/thermaldetonator/click.wav", t = 0.4},
        },
    },
    ["throw"] = {
        Source = "throw",
        SoundTable = {
            {s = "kraken/shared/rifle_fetch-1.wav", t = 0.1},
        },
        MinProgress = 0.3
    },
    ["throw_alt"] = {
        Source = "throw",
        SoundTable = {
            {s = "kraken/shared/rifle_fetch-1.wav", t = 0.1},
        },
        MinProgress = 0.3
    }
}
