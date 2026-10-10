AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "E-105e"
SWEP.Trivia_Class = "Blaster, Rifle"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "The BlasTech Industries E-105 blaster rifle, also referred to as the E-105 BlasTech Standard Imperial Sidearm, the Stormtrooper Armament Blaster Rifle (BlasTech E-105), and the E-105 Military Issue Blaster Rifle, was a blaster rifle used during the time of the Galactic Empire. It was the standard-issue blaster rifle of the Imperial stormtroopers. A powerful, light and compact weapon, the E-105 was used widely throughout the galaxy for nearly a century and a half."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.IconOverride = "entities/kraken/empire-essentials/e105e.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "001000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_e10rifle.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_e105.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-15, 8, -9),
    ang = Angle(-30, 25, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 45
SWEP.DamageMin = 26
SWEP.RangeMin = 0
SWEP.Range = 720
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 250, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_green"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 25

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.8

SWEP.Delay = 60 / 310
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 2,
    },
    {
        Mode = -3,
        PostBurstDelay = 0.1,
        RunawayBurst = false,
        Mult_RPM = 5,
    },
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0.2
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 150
SWEP.JumpDispersion = 500

-- Speed Mult
SWEP.SpeedMult = 0.925
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 95
SWEP.ShootPitchVariation = 0.5

SWEP.ShootSound = "ArcCW_Kraken.SW_E105_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_E11_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_green"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 250, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.45, -6.159, 2.7),
    Ang = Angle(0, -0.065, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, -2, 2)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 40

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["e11_powerpack"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["e11_scope"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 5, bg = 1}},
    },
    ["e11_grip_standard"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
        AttPosMods = {
            [6] = {
                vpos = Vector(-.1, 0.1, 24.6),
            },
        }
    },
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "E11_GUN",
               Scale = Vector(0, 0, 0),                
               Offset = {
                pos = Vector(0, 15, 0),
                ang = Angle(-90, -90, 0)
            },
               IsMuzzleDevice = true
           }
        }
    }
}

SWEP.Attachments = {
    {
        PrintName = "Sight",
        DefaultAttName = "Standard E-10 Sight",
        Slot = "optic",
        Bone = "E11_GUN",
        Offset = {
            vpos = Vector(0.087, -2, 2.1),
            vang = Angle(0, -90, 0),
        },
        InstalledEles = {"e11_scope"},
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"e11_k_muzzles", "muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "E11_GUN",
        Offset = {
            vpos = Vector(0.1, 13.5, 1.15),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "E11_GUN",
        InstalledEles = {"e11_laser"},
        VMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1.6, 7, 1.5),
            vang = Angle(0, -90, 90),
        },
    },
    {
        PrintName = "Foregrip",
        DefaultAttName = "Standard E-105 Grip",
        Slot = {"foregrip"},
        Bone = "E11_GUN",
        InstalledEles = {"e11_grip_standard"},
        Offset = {
            vpos = Vector(-0, 0.2, 2.5),
            vang = Angle(90, -90, -90),   
        },
        SlideAmount = {
        vmin = Vector(0.2, 4, 0.4),
        vmax = Vector(0.2, 6, 0.5),
        },    
    },
    {
        PrintName = "Power Pack",
        DefaultAttName = "None",
        Slot = {"e11_k_powerpack"}
    },
    {
        PrintName = "Energization",
        DefaultAttName = "Red Tibanna",
        Slot = {"ammo", "special_ammo"}
    },
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
    },
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = {"charm"},
        Bone = "E11_GUN",
        VMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1.25, -3.55, 0.5),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "E11_GUN",
        VMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(0.87, -7, 1.05),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

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
            {
                s = "ArcCW_Kraken.Draw",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {
                s = "ArcCW_Kraken.Holster",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["reload"] = {
        Source = "reload",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, 
        SoundTable = {
            {s = "arccw/kraken/empire/e-series/e11_reload.wav", t = 0.1 },
        },
    },
}
