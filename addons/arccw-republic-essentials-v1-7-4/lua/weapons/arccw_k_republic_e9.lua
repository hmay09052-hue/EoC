AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "E-9"
SWEP.Trivia_Class = "Blaster, Rifle"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "An experimental Blaster Rifle designed to be cheaper and better than the DC-15 series."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Laser Bolt"
SWEP.Trivia_Mechanism = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00001000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/republic/v_e9.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_e9.mdl"

SWEP.MirrorWorldModel = nil
SWEP.ViewModelFOV = 54


SWEP.WorldModelOffset = {
    pos = Vector(-15, 8, -9.6),
    ang = Angle(-30, 25, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1.1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 20
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.2
SWEP.HeatFix = true

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 38
SWEP.DamageMin = 20
SWEP.RangeMin = 0
SWEP.Range = 300
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 45

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.7

SWEP.Delay = 60 / 330
SWEP.Num = 1
SWEP.Firemode = 2
SWEP.Firemodes = {
    {
		Mode = 2,
    },
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}

SWEP.AccuracyMOA = 5
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200

-- Speed Mult
SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.30

-- Ammo, Sounds & MuzzleEffect

SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0

SWEP.ShootSound = "ArcCW_Kraken.SW_DC15S"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DC15A_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 255)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.33, -7, 2.55),
    Ang = Vector(1, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, -2, 2)
SWEP.ActiveAng = Angle(0, 0, 0)


SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 30

SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["e9_grip"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["e9_holosight"] = {
        VMBodygroups = {{ind = 6, bg = 1}, {ind = 5, bg = 1}, {ind = 4, bg = 1}, {ind = 2, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Sight",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Slot = {"optic", "kraken_holohud"},
        Bone = "E11_GUN",
        Offset = {
            vpos = Vector(0.22, -4, 2.2),
            vang = Angle(0, -90, 0),
        },
        InstalledEles = {"e9_holosight"},
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Muzzle",
        VMScale = Vector(1.2, 1.2, 1.2),
        WMScale = Vector(1.2, 1.2, 1.2),
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "E11_GUN",
        Offset = {
            vpos = Vector(0.17, 8.1, 1.2),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol"},
        Bone = "E11_GUN",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(-0.3, 4.1, 1.2),
            vang = Angle(0, -90, -90),
        },
    },
    {
        PrintName = "Foregrip",
        Slot = {"foregrip", "sw_ubgl"},
        Bone = "E11_GUN",
        InstalledEles = {"e9_grip"},
        Offset = {
            vpos = Vector(-0, 4.3, 0.5),
            vang = Angle(90, -90, -90),   
        }, 
    },
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_rifle"},
    },   
    {
        PrintName = "Energization",
        Slot = {"ammo"}
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
    {
        PrintName = "Perk",
        Slot = "perk",
    },
    {
        PrintName = "Charm",
        Slot = {"charm"},
        Bone = "E11_GUN",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.75, -2.7, 0),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        Bone = "E11_GUN",
        VMScale = Vector(0.9, 0.9, 0.9),
        wmScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(0.95, -4, 1),
            vang = Angle(0, -90, 0),
        },
    },
}

-- Animations
SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["fire"] = {
        Source = "fire"
    },
    ["fire_iron"] = {},
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {s = "weapon_hand/reload_gentle/hits_and_grabs/023d-00000b29.mp3", t = 0.1 / 10},
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = "weapon_hand/reload_heavy/mag_load/023d-00000f0b.mp3", t = 0.1 / 10},
        },
    },
    ["reload"] = {
        Source = "reload",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, 
        SoundTable = {
            {s = "weapon_hand/reload_gentle/mag_eject/023d-000000e1.mp3", t = 0.1 / 30},
            {s = "weapon_hand/023d-00000d8c.mp3", t = 35 / 30},
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 60 / 30},
            {s = "ArcCW_Kraken.Grab", t = 58 / 30},
        },
    },
}
