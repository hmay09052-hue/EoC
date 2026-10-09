AddCSLuaFile()

SWEP.Base = "arccw_k_nade_base"
SWEP.Spawnable = true

SWEP.Slot = 4

SWEP.Category = "[ArcCW] Kraken's Explosives - Grenades"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Dioxis Grenade"
SWEP.Trivia_Class = "Explosive, Dioxis"
SWEP.Trivia_Desc = "The dioxis grenade, dioxis mine, or dioxis charge was a grenade that upon being thrown, would release a toxic gas known as dioxis. The gas was only mild, however it would choke to death those who were in its range for an extended period of time. It was known to be used by the BX-series droid commandos of the Separatist Alliance, and later the Rebel Alliance, Galactic Empire, and the New Republic."
SWEP.Trivia_Manufacturer = "BlastTech Industries, Merr Sonn Munitions Inc."
SWEP.Trivia_Calibre = "Releasing dioxis"
SWEP.Trivia_Mechanism = "Explosive"
SWEP.Trivia_Country = "Universal"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_grenade_dioxis.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_grenade_dioxis.mdl"

SWEP.ViewModelFOV = 56

SWEP.WorldModelOffset = {
    pos = Vector(-16, 6, -2),
    ang = Angle(-10, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

SWEP.ShootEntity = "arccw_nade_k_thrown_dioxis"

SWEP.MuzzleVelocity = 900
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

SWEP.ActivePos = Vector(0, 0, 0)
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
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Draw", t = 0.1/30},
        },
    },
    ["holster"] = {
        Source = "holster",
		Mult = 0.5,
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Holster", t = 0.1/30},
        },
    },
    ["pre_throw"] = {
        Source = "pullpin",
        MinProgress = 0.666,
        FireASAP = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.PreThrow", t = 0.1/30},
        },
    },
    ["throw"] = {
        Source = "throw",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Throw", t = 0.1/30},
        },
        MinProgress = 0.3
    },
    ["throw_alt"] = {
        Source = "underhand",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Throw", t = 0.1/30},
        },
        MinProgress = 0.3
    }
}
