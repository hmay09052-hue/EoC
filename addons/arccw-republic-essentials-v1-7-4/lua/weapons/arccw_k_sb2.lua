AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "SB-2"
SWEP.Trivia_Class = "Blaster Heavy Shotgun"
SWEP.SubCategory = "6Shotguns"
SWEP.Trivia_Desc = "The SB-2 was a type of blaster that could pierce through enemy defenses. It was used by the Grand Army of the Republic's clone troopers during the Clone Wars between the Galactic Republic and the Confederacy of Independent Systems. The DP-23 fired blue blaster bolts, and had a ridged barrel with a pointed muzzle, a black stock, and a small foregrip."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/republic/v_sb2.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_sb2.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-2, 3.5, -4),
    ang = Angle(-10, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.NoRandSpread = true
SWEP.CanBash = true

SWEP.ShotgunReload = true
SWEP.ManualAction = true

SWEP.ShotgunSpreadPattern = {
    [1] = Angle(0, 0, 0),
    [2] = Angle(0, 1, 0),
    [3] = Angle(0, -1, 0),
    [4] = Angle(2.1, 0, 0),
    [5] = Angle(-2.1, 0, 0),
    [6] = Angle(1.4, 1.2, 0),
    [7] = Angle(-1.4, 1.2, 0),
    [8] = Angle(1.4, -1.2, 0),
    [9] = Angle(-1.4, -1.2, 0),
}

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 22
SWEP.DamageMin = 9
SWEP.RangeMin = 0
SWEP.Range = 170
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 12

SWEP.Recoil = 4
SWEP.RecoilSide = 1
SWEP.RecoilRise = 2
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1.5
SWEP.RecoilVMShake = 2

SWEP.Delay = 60 / 312
SWEP.Num = 9
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}

SWEP.AccuracyMOA = 5
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 75
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.30

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0

SWEP.ShootSound = "ArcCW_Kraken.SW_SB2"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_SB2_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 255)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2.5, 0, 0.6),
    Ang = Angle(-0.25, 0.1, 0),
     Magnification = 1.2,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(1, 3, 0.25)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4, -3, -2)
SWEP.SprintAng = Angle(0, 30, -15)

SWEP.CustomizePos = Vector(15, 3, -2)
SWEP.CustomizeAng = Angle(15, 40, 20)

SWEP.HolsterPos = Vector(0.532, -6, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.BarrelLength = 25

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["scope_attach"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Optic", 
        Slot = {"optic", "optic_lp", "kraken_holohud"},
        Bone = "tag_weapon", 
        InstalledEles = {"scope_attach"},
        Offset = {
            vpos = Vector(6, 0, 3.35), 
            vang = Angle(0, 0, 0),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
    }, 
    {
        PrintName = "Internal Compression",
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
    },
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.95, 0.95, 0.95),
        WMScale = Vector(0.95, 0.95, 0.95),
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(12.5, -0.7, 2.87),
            vang = Angle(0, 0, 120),
        },
    },
    {
        PrintName = "Mode",
        Slot = {"sw_mode_rifle"},
    },   
    {
        PrintName = "Ammunition",
        Slot = {"ammo"}
    },
    {
        PrintName = "Internal Modifications",
        Slot = "uc_fg",
    },
    {
        PrintName = "Perk",
        Slot = "perk",
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
    {
        PrintName = "Charm",
        Slot = {"charm"},
        Bone = "tag_weapon",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1.8, -0.55, 1.5), 
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        Bone = "tag_weapon",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(5, -0.55, 1.5), 
            vang = Angle(0, 0, 0),
        },
    },
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
        Time = 1 / 35,
    },
    ["draw"] = {
        Source = "draw",
        Time = 1,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 1,
    },
    ["holster"] = {
        Source = "holster",
        Time = 0.75,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.2,
    },
    ["ready"] = {
        Source = "first_draw",
        Time = 2,
        SoundTable = {
            {s = "weapon_hand/reload_heavy/locknload/023d-00000ae8.mp3", t = 14 / 30},
        },
    },
    ["fire"] = {
        Source = {
            "fire",
        },
        Time = 3 / 10,
        ShellEjectAt = false,
    },
    ["fire_iron"] = {
        Source = {
            "fire_ads",
        },
        Time = 3 / 10,
        ShellEjectAt = false,
    },
    ["cycle"] = {
        Source = {
            "pump",
        },
        Time = 20 / 35,
        --ShellEjectAt = 0.3,
        SoundTable = {
            {s = "weapon_hand/reload_heavy/locknload/023d-00000ae8.mp3", t = 2 / 30},
        },
    },
    ["cycle_iron"] = {
        Source = {
            "pump_ads",
        },
        Time = 20 / 35,
        --ShellEjectAt = 0.3,
        SoundTable = {
            {s = "weapon_hand/reload_heavy/locknload/023d-00000ae8.mp3", t = 2 / 30},
        },
    },

    --RELOADS
    ["sgreload_start"] = {
        Source = "reload_in",
        Time = 40 / 30,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        RestoreAmmo = 1, -- loads a shell since the first reload has a shell in animation
        MinProgress = 1,
        SoundTable = {
            {s = "ArcCW_Kraken.ShotgunLoad", t = 21 / 30},
        },
    },
    ["sgreload_insert"] = {
        Source = "reload_loop",
        Time = 26 / 30,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        TPAnimStartTime = 0.3,
        MinProgress = 15 / 30,
        SoundTable = {
            {s = "ArcCW_Kraken.ShotgunLoad", t = 10 / 30},
        },
    },
    ["sgreload_finish"] = {
        Source = "reload_out",
        Time = 30 / 30,
        SoundTable = {
            {s = "arccw/kraken/republic/sb2/back_870.wav", t = 8 / 30},
            {s = "arccw/kraken/republic/sb2/fwd_870.wav", t = 12 / 30},
        },
    },
}
