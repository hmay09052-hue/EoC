AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DC-15le"
SWEP.Trivia_Class = "Blaster Rifle"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "The DC-15LE was a blaster rifle and variant of the standard DC-15A blaster rifle, which could be modified for long-range engagements or to fire explosive blaster bolts."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00101000000000"
SWEP.DefaultWMBodygroups = "00101000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/republic/v_dc15a.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_dc15a.mdl"

SWEP.HideBones = {"Mag_Ball"}
SWEP.ReloadHideBoneTables = {[1] = {}}

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-13, 5, -5),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 15
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

SWEP.Damage = 55
SWEP.DamageMin = 20
SWEP.RangeMin = 0
SWEP.Range = 425
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 40

SWEP.Recoil = 0.75
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.4

SWEP.Delay = 60 / 220
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

SWEP.AccuracyMOA = 0.5
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

SWEP.ShootSound = "ArcCW_Kraken.SW_DC15LE"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DC15LE_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 250)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-4.669, -14.197, 3.532),
    Ang = Angle(0.896, 0, 0),
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

SWEP.ActivePos = Vector(0, 0, 2)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4, -3, -1)
SWEP.SprintAng = Angle(0, 30, -15)

SWEP.CustomizePos = Vector(15, -5, 5)
SWEP.CustomizeAng = Angle(0, 40, 30)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Angle(0, 30, -15)

SWEP.BarrelLength = 40

-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["muzzle_attach"] = {
        VMBodygroups = {{ind = 1, bg = 0}},
    },
    ["vibroknife"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        Slot = {"optic", "kraken_holohud"}, 
        Bone = "Barrel",
        Offset = {
            vpos = Vector(0.66, 9.4, 2.5),
            vang = Angle(0, -90, 0),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },          
    {
        PrintName = "Muzzle",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "Barrel",
        InstalledEles = {"muzzle_attach"},
        Offset = {
            vpos = Vector(0.66, 31.5, 0.9),
            vang = Angle(0, -90, 0),
        },
    },  
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "Barrel", 
        Offset = {
            vpos = Vector(-0.6, 25, 0.9),
            vang = Angle(-90, -90, 0),
        },
    },  
    {
        PrintName = "Foregrip",
        Slot = {"foregrip"},
        Bone = "Barrel",
        Offset = {
            vpos = Vector(0.66, 6, -0.7),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_rifle"},
    },   
    {
        PrintName = "Underbarrel",
        Slot = {"vibroknife"},    
    },    
    {
        PrintName = "Internal Modifications",
        Slot = "uc_fg",
    },   
    {
        PrintName = "Ammunition", 
        Slot = "ammo",
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
        PrintName = "Charms",
        Slot = {"charm"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "Barrel",
        Offset = {
            vpos = Vector(1.7, 7, 1.8),
            vang = Angle(0, -90, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        Bone = "dc15a_DC15_mat",
        Offset = {
            vpos = Vector(1.2, -9, 0.7),
            vang = Angle(0, -90, 0),
        },
    },         
}

-- Don't touch this unless you know what you're doing
SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["idle"] = {
        Time = 9,
        Source = "idle",
    },
    ["fire"] = {
        Time = 1,
        Source = {"shoot", "shoot2"},
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
        LHIKIn = 0.2,
        LHIKOut = 0.7,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {hide = 1, t = 0},
            {s = "weapon_hand/023d-00000d8a.mp3", t = 1 / 30},
            {s = "weapon_hand/reload_heavy/mag_eject/0215-00001ec8.mp3", t = 5 / 30},
            {s = "weapon_hand/reload_heavy/mag_eject/0215-00001ed0.mp3", t = 27 / 30},
            {s = "weapon_hand/reload_heavy/mag_eject/023d-00000071.mp3", t = 30 / 30},
            {s = "weapon_hand/reload_heavy/mag_load/023d-0000059a.mp3", t = 55 / 30},
            {s = "ArcCW_Kraken.Overheat", t = 5 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 65 / 30},
            {s = "ArcCW_Kraken.Grab", t = 70 / 30},
            {hide = 0, t = 70 / 30},
        },
    },
    ["fix"] = {
        Source = "overheat", 
        Mult = 4.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
}
