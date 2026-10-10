AddCSLuaFile()

SWEP.Base = "arccw_k_nade_base"
SWEP.Spawnable = true

SWEP.Slot = 4

SWEP.Category = "[ArcCW] Kraken's Explosives - Grenades"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Smoke Grenade"
SWEP.Trivia_Class = "Hand Grenade, Smoke"
SWEP.Trivia_Desc = "A smoke grenade is a canister-type grenade used as a signaling device, target or landing zone marking device, or as a screening device for unit movements.."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Smoke"
SWEP.Trivia_Mechanism = "Non-Lethal Smoke"
SWEP.Trivia_Country = "Universal"

SWEP.DefaultBodygroups = "0000000000"
SWEP.MirrorVMWM = false
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_smoke.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_grenade_smoke.mdl"

SWEP.ViewModelFOV = 60

SWEP.WorldModelOffset = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 0.09
}

SWEP.ShootEntity = "arccw_nade_k_thrown_smoke"

SWEP.MuzzleVelocity = 800
SWEP.MuzzleVelocityAlt = 700

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

SWEP.SprintPos = Vector(0,0,-5)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.DefaultElements = {"grenade"}
SWEP.AttachmentElements = {
    ["grenade"] = {
            WMElements = {
            {
                Model = "models/arccw/kraken/sw/explosives/v_smoke.mdl",
                Bone = "ValveBiped.Bip01_R_Hand",
                Scale = Vector(1,1,1),
                ModelBodygroups = "0000000000000000000",
                Offset = {
                    pos = Vector(-140,100,-20),
                    ang = Angle(0, 0, 180),
                },
            },
        },
    },
}WMOverride = "models/arccw/kraken/sw/explosives/v_smoke.mdl"

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["idle_primed"] = {
        Source = "idle_primed"
    },
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
        MinProgress = 0,
		Mult = 1.4,
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.PreThrow", t = 0.1/30},
        },
        FireASAP = true,
    },
    ["throw"] = {
        Source = "throw",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Throw", t = 0.1/30},
        },
        MinProgress = 0.1
    },
    ["throw_alt"] = {
        Source = "underhand",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Throw", t = 0.1/30},
        },
        MinProgress = 0.1
    },
    ["bash"] = {
        Source = {"melee"}
    },
}
