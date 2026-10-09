AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "WESTAR M5"
SWEP.Trivia_Class = "Blaster, Rifle"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "The WESTAR-M5 blaster rifle was a blaster rifle used during the Clone Wars by the Grand Army of the Republic. This blaster improved on the DC-15 design, making it easier to aim. It featured an extendable stock and a larger ammunition magazine."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Laser Bolt"
SWEP.Trivia_Mechanism = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00001000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/republic/v_westar.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_westar.mdl"

SWEP.MirrorWorldModel = nil
SWEP.ViewModelFOV = 54


SWEP.WorldModelOffset = {
    pos = Vector(-10, 3.5, -3.4),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1.7,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 25
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
SWEP.DamageMin = 22
SWEP.RangeMin = 0
SWEP.Range = 360
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 75

SWEP.Recoil = 0.2
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6

SWEP.Delay = 60 / 700
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

SWEP.ShootSound = "ArcCW_Kraken.SW_WESTAR"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_WESTAR_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 255)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.13, -3.314, 3.33),
    Ang = Vector(0, 0, 0.5),
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

SWEP.ActivePos = Vector(-1, -1, 3)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4, -3, 1)
SWEP.SprintAng = Angle(0, 30, -15)

SWEP.CustomizePos = Vector(8, -5, 6)
SWEP.CustomizeAng = Angle(0, 40, 30)

SWEP.HolsterPos = Vector(2, -3, 2)
SWEP.HolsterAng = Angle(0, 30, -15)

SWEP.BarrelLength = 25

SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["scope_attach"] = {
        VMBodygroups = {{ind = 2, bg = 1}, {ind = 1, bg = 1}, {ind = 3, bg = 1}},
    },
}

SWEP.Attachments = {
	{
		PrintName = "Sight",
		Slot = {"optic", "kraken_holohud"},
        InstalledEles = {"scope_attach"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
		Bone = "weapon",
		Offset = {
            vpos = Vector(-0.03, -1.5, 2.25),
            vang = Angle(90, 0, -90),
        },
	},
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol"},
		Bone = "weapon",
        VMScale = Vector(0.5, 0.5, 0.5),
        WMScale = Vector(0.5, 0.5, 0.5),
        Offset = {
            vpos = Vector(-0.7, -0.75, 4.7),
            vang = Angle(90, 0, -180),
        },
    },
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_rifle"},
    },   
    {
        PrintName = "Internal Compression",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
    },  
    {
        PrintName = "Energization", 
        Slot = {"ammo", "special_ammo"}
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
        PrintName = "Internal Modifications",
        Slot = "uc_fg",
    },
    {
        PrintName = "Charms", 
        Slot = {"charm"},
		Bone = "weapon",
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Offset = {
            vpos = Vector(0.75, -1.05, -0.55),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        Bone = "weapon",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.5, 0.07, -1.3),
            vang = Angle(90, 0, -90),
        },
    },                         
}

-- Animations
SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["idle"] = {
        Time = 9,
        Source = "idle",
    },
	["fire"] = {
        Source = "fire",
    },
    ["fire_iron"] = {},
	["reload"] = {
        Source = "reload_empty",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
		SoundTable = {
	        {s = "weapon_hand/reload_gentle/mag_eject/023d-000000d6.mp3", t = 0.1 },
            {s = "weapon_hand/reload_gentle/mag_load/0215-00001ea5.mp3", t = 1 },
            {s = "ArcCW_Kraken.Overheat", t = 0.1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 46 / 30},
        },
    },
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
    ["fix"] = {
        Source = "overheat", 
        Mult = 1.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
}
