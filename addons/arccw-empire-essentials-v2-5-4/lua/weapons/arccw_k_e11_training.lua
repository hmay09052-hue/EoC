AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "E-11 Training"
SWEP.Trivia_Class = "Blaster, Rifle"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "The BlasTech Industries E-11 blaster rifle, also referred to as the E-11 BlasTech Standard Imperial Sidearm, the Stormtrooper Armament Blaster Rifle (BlasTech E-11), and the E-11 Military Issue Blaster Rifle, was a blaster rifle used during the time of the Galactic Empire. It was the standard-issue blaster rifle of the Imperial stormtroopers. A powerful, light and compact weapon, the E-11 was used widely throughout the galaxy for nearly a century and a half."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/e11_training.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00000100000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_e11.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_e11.mdl"

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

SWEP.Damage = 1
SWEP.DamageMin = 1
SWEP.RangeMin = 0
SWEP.Range = 620
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(255, 174, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_orange"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 45

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.7

SWEP.Delay = 60 / 330
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


SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 400
SWEP.MoveDispersion = 200
SWEP.JumpDispersion = 1000

-- Speed Mult
SWEP.SpeedMult = 0.925
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.05

SWEP.ShootSound = "ArcCW_Kraken.SW_E11_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_E11_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_orange"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(255, 190, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.336, -8.598, 2.263),
    Ang = Angle(0, 0.472, 0),
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

SWEP.BarrelLength = 30

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["e11_k_splitter"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["e11_k_supressor"] = {
        VMBodygroups = {{ind = 1, bg = 2}},
    },
    ["e11_powerpack"] = {
        VMBodygroups = {{ind = 7, bg = 1}, {ind = 8, bg = 1}},
    },
    ["e11_stock_complete"] = {
        VMBodygroups = {{ind = 9, bg = 1}},
    },
    ["e11_grip_standard"] = {
        VMBodygroups = {{ind = 5, bg = 0}},
    },
    ["e11_k_powercell"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["e11_scope"] = {
        VMBodygroups = {{ind = 6, bg = 1}},
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
        DefaultAttName = "E-11d Ironsight",
        Slot = "optic",
        Bone = "E11_GUN",
        Offset = {
            vpos = Vector(0.12, -4, 2.23),
            vang = Angle(0, -90, 0),
        },
        InstalledEles = {"e11_scope"},
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Internal Compression",
        DefaultAttName = "None",
        Slot = {"e11_k_muzzles", "muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "E11_GUN",
        InstalledEles = {"e11_laser"},
        VMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1.9, 9, 1.6),
            vang = Angle(0, -90, 90),
        },
    },
    {
        PrintName = "Stock",
        DefaultAttName = "None",
        Slot = {"e11_stock_complete", "e11_grid", "e11_grid_complete"},
    },
    {
        PrintName = "Power Cell",
        DefaultAttName = "Standard",
        Slot = {"e11_k_powercell"}
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
            vpos = Vector(0.78, -4.5, 0.6),
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
            vpos = Vector(0.6, -1, 0),
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
    ["idle_iron"] = {
        Source = false,
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
