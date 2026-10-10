AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "SG-6"
SWEP.Trivia_Class = "Blaster, Scatter"
SWEP.SubCategory = "6Shotguns"
SWEP.Trivia_Desc = "Short and Medium Range blaster scatter used by the Confederacy of Independent Systems during the Clone Wars."
SWEP.Trivia_Manufacturer = "Baktoid Armor Workshop"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Confederacy of Independent Systems"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/cis/v_cis_shotgun.mdl"
SWEP.WorldModel = "models/arccw/kraken/cis/world/w_cis_shotgun.mdl"

SWEP.MirrorWorldModel = nil
SWEP.ViewModelFOV = 54


SWEP.WorldModelOffset = {
    pos = Vector(-8.6, 5.5, -5),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 10
SWEP.HeatDissipation = 2
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 1
SWEP.HeatFix = true

SWEP.NoRandSpread = true
SWEP.CanBash = true

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

SWEP.Damage = 18
SWEP.DamageMin = 5
SWEP.RangeMin = 0
SWEP.Range = 200
SWEP.Penetration = 8
SWEP.DamageType = DMG_BUCKSHOT
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_red"
SWEP.TracerCol = Color(250, 0, 0)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 24

SWEP.Recoil = 2
SWEP.RecoilSide = 1
SWEP.RecoilRise = 2
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1.5
SWEP.RecoilVMShake = 2

SWEP.Delay = 60 / 140
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
SWEP.HipDispersion = 100
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

SWEP.ShootSound = "ArcCW_Kraken.SW_DP23"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DP23_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-4.858, 0, 1.5),
    Ang = Vector(0, -0.452, 0),
     Magnification = 1,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "shotgun"
SWEP.HoldtypeSights = "shotgun"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.SprintPos = Vector(2, -1, 0)
SWEP.SprintAng = Angle(-10, 26, 0)

SWEP.CustomizePos = Vector(10, 0, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.ActivePos = Vector(-3, 0, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 25

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMElements = {
            {
                Model = "models/hunter/plates/plate.mdl",
                Bone = "dlt34",
                Scale = Vector(0, 0, 0),                
                Offset = {
                    pos = Vector(0.05, -1.75, 18.8),
                    ang = Angle(90, 0, -90),
                },
                IsMuzzleDevice = true,
            }
         }, 
    },
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        Slot = {"optic", "kraken_holohud"}, 
        Bone = "dlt34",
        Offset = {
            vpos = Vector(-0., -4, 12),
            vang = Angle(90, 0, -90),
        },
        CorrectiveAng = Angle(0, 0, 0),
        CorrectivePos = Vector(0, 0, 0),
    },          
    {
        PrintName = "Muzzle",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "dlt34",
        Offset = {
            vpos = Vector(0.05, -1.75, 18.8),
            vang = Angle(90, 0, -90),
        },
    },  
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "dlt34", 
        Offset = {
            vpos = Vector(-1.05, -1.5, 10),
            vang = Angle(90, 0, -180),
        },
    },  
    {
        PrintName = "Mode",
        Slot = {"sw_mode"},
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
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
    {
        PrintName = "Perk",
        Slot = "perk",
    },
    {
        PrintName = "Charms",
        Slot = {"charm"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "dlt34",
        Offset = {
            vpos = Vector(0.85, -0.3, 1.7),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Bone = "dlt34",
        Offset = {
            vpos = Vector(0.7, -1.4, 1.78),
            vang = Angle(90, 0, -90),
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
        Time = 0.6,
        Source = {"fire"},
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
        Source = "overheat", 
        Mult = 2.2,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
    ["fix"] = {
        Source = "overheat", 
        Mult = 2.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
}
