AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Geonosian Blaster"
SWEP.Trivia_Class = "Sonic Blaster"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "The Geonosian Sonic Blaster is a blaster pistol used by the Geonosian species during the Clone Wars. It fires sonic projectiles that can cause disorientation and damage to targets. The blaster is known for its unique design and effectiveness in close-quarters combat."
SWEP.Trivia_Manufacturer = "Geonosian Armory"
SWEP.Trivia_Calibre = "Sonic Energy"
SWEP.Trivia_Country = "Confederacy of Independent Systems"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000000000000000"
SWEP.DefaultWMBodygroups = "0000000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/cis/v_geonosianblaster.mdl"
SWEP.WorldModel = "models/arccw/kraken/cis/world/w_geonosianblaster.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-11, 5.5, -2),
    ang = Angle(-20, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1.3,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 10
SWEP.HeatDissipation = 2
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 1
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
SWEP.DamageMin = 35
SWEP.RangeMin = 0
SWEP.Range = 300
SWEP.Penetration = 8
SWEP.DamageType = DMG_SHOCK
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "geonosian_ring"
SWEP.TracerCol = Color(0, 250, 0)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 50

SWEP.Recoil = 1
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.5

SWEP.Delay = 60 / 280
SWEP.Num = 1
SWEP.Firemode = 1
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
SWEP.HipDispersion = 100
SWEP.MoveDispersion = 100
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

SWEP.ShootSound = "ArcCW_Kraken.SW_GEOBLASTER"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GEOBLASTER_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_green"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(43, 255, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-4.83, -8.98, 1.7),
    Ang = Vector(0, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(0, -4, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4, -3, -1)
SWEP.SprintAng = Angle(0, 30, -15)

SWEP.CustomizePos = Vector(15, 0, 4)
SWEP.CustomizeAng = Angle(0, 40, 30)

SWEP.HolsterPos = Vector(4, -3, -1)
SWEP.HolsterAng = Angle(0, 30, -15)

SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "dlt34",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(0, 0, 10),
                   ang = Angle(90, 0, 0),
               },
               IsMuzzleDevice = true,
           }
        }, 
    },
}

SWEP.BarrelLength = 30

SWEP.Attachments = { 
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_rifle"},
    },   
    {
        PrintName = "Ammunition",
        Slot = {"ammo"},
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
        PrintName = "Internal Modifications",
        Slot = "uc_fg",
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
        Mult = 2,
        Source = "shoot"
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
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        Mult = 0.3,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatFix", t = 60 / 30},
            {s = "ArcCW_Kraken.Grab", t = 55 / 30},
        },
    },
    ["fix"] = {
        Source = "reload", 
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        Mult = 0.3,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatFix", t = 60 / 30},
            {s = "ArcCW_Kraken.Grab", t = 55 / 30},
        },
    },
}
