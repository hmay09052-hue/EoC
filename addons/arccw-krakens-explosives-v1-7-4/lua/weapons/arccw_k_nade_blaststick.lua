AddCSLuaFile()

SWEP.Base = "arccw_k_nade_base"
SWEP.Spawnable = true

SWEP.Slot = 4

SWEP.Category = "[ArcCW] Kraken's Explosives - Grenades"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Blast Stick"
SWEP.Trivia_Class = "Hand Grenade"
SWEP.Trivia_Desc = "When thrown, anti-vehicle grenades begin a 3 second fuse, and bounce off any surfaces they contact. Anti-vehicle grenades can stick to vehicles and will do so to the first appropriate unit they contact, including to friendlies. Anti-vehicle grenades do not deal any additional damage if stuck to a target, as compared to exploding within range."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "High Explosive Anti-Vehicle"
SWEP.Trivia_Mechanism = "Explosive"
SWEP.Trivia_Country = "Galactic Empire"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_blaststick.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_blaststick.mdl"

SWEP.ViewModelFOV = 56

SWEP.WorldModelOffset = {
    pos = Vector(2, 1, -7),
    ang = Angle(-10, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

SWEP.ShootEntity = "arccw_nade_k_thrown_blaststick"

SWEP.MuzzleVelocity = 1200
SWEP.MuzzleVelocityAlt = 900

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

SWEP.ActivePos = Vector(0, 9, 0)
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
    ["quicknade"] = {
        Source = "quick_pullout",
        MinProgress = 0.3,
        FireASAP = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Draw", t = 0.1/30},
        },
    },
    ["draw"] = {
        Source = "draw",
        MinProgress = 0.3,
        FireASAP = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Draw", t = 0.1/30},
        },
    },
    ["ready"] = {
        Source = "draw",
        MinProgress = 0.3,
        FireASAP = true,
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
        MinProgress = 0.666,
		Mult = 1.5,
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
        MinProgress = 0.52
    },
    ["throw_alt"] = {
        Source = "throw",
        SoundTable = {
            {s = "ArcCW_Kraken.Explosives.Throw", t = 0.1/30},
        },
        MinProgress = 0.52
    },
    ["idle_sprint"] = {
        Source = "sprint",
    },
    ["enter_sprint"] = {
        Source = "sprint_in",
		Mult = 3,
    },
    ["exit_sprint"] = {
        Source = "sprint_out",
		Mult = 3,
    },
    ["bash"] = {
        Source = {"melee_hit01","melee_hit02","melee_hit03"},
    },
}
