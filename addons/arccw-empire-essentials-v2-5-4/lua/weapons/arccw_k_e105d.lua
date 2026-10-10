AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "E-105d"
SWEP.Trivia_Class = "Blaster, DMR"
SWEP.SubCategory = "5Snipers"
SWEP.Trivia_Desc = "The BlasTech Industries E-105 blaster rifle, also referred to as the E-105 BlasTech Standard Imperial Sidearm, the Stormtrooper Armament Blaster Rifle (BlasTech E-105), and the E-105 Military Issue Blaster Rifle, was a blaster rifle used during the time of the Galactic Empire. It was the standard-issue blaster rifle of the Imperial stormtroopers. A powerful, light and compact weapon, the E-105 was used widely throughout the galaxy for nearly a century and a half."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/e105d.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000001100"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_e105.mdl"
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

SWEP.Damage = 57
SWEP.DamageMin = 29
SWEP.RangeMin = 0
SWEP.Range = 910
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

SWEP.RecoilSide = 0.4
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.9

SWEP.Delay = 60 / 200
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
        Mult_RPM = 2,
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
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_E105_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_E11D_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_green"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 250, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.44, -5.18, 2),
    Ang = Angle(0, 0, 0),
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
    ["e11_stock_complete"] = {
        VMBodygroups = {{ind = 8, bg = 2}, {ind = 2, bg = 1}},
    },
    ["e11_stock_grid"] = {
        VMBodygroups = {{ind = 8, bg = 1}, {ind = 2, bg = 1}},
    },
    ["e11_k_powercell"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["e11_scope"] = {
        VMBodygroups = {{ind = 5, bg = 1}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 9, bg = 1}},
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
            vpos = Vector(0.06, -4, 2.75),
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
            vpos = Vector(0.1, 14.2, 1.25),
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
            vpos = Vector(1.6, 7, 1.6),
            vang = Angle(0, -90, 90),
        },
    },
    {
        PrintName = "Stock",
        DefaultAttName = "E-10r Stock",
        Slot = {"e11_grid_complete", "e11_grid"},
        InstalledEles = {"e11_stock_complete"},
    },
    {
        PrintName = "Power Cell",
        DefaultAttName = "Standard",
        Slot = {"e11_k_powercell"}
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
            vpos = Vector(1.22, -7.4, 1.24),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "E11_GUN",
        VMScale = Vector(0.8, 0.8, 0.8),
        Offset = {
            vpos = Vector(1, -3, 0.2),
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
