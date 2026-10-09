AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 2 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "E-11 Pistol"
SWEP.Trivia_Class = "Blaster, Pistol"
SWEP.SubCategory = "1Pistols"
SWEP.Trivia_Desc = "The BlasTech Industries E-11 blaster pistol, also referred to as the E-11 BlasTech Standard Imperial Sidearm, the Stormtrooper Armament blaster pistol (BlasTech E-11), and the E-11 Military Issue blaster pistol, was a blaster pistol used during the time of the Galactic Empire. It was the standard-issue blaster pistol of the Imperial stormtroopers. A powerful, light and compact weapon, the E-11 was used widely throughout the galaxy for nearly a century and a half."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.IconOverride = "entities/kraken/empire-essentials/e11_pistol.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_e11pistol.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_e11pistol.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-18, 6, -5.7),
    ang = Angle(0, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
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

SWEP.Damage = 20
SWEP.DamageMin = 12
SWEP.RangeMin = 0
SWEP.Range = 200
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 22

SWEP.Recoil = 0.4
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.2

SWEP.Delay = 60 / 270
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 100
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200

-- Speed Mult
SWEP.SpeedMult = 0.955
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_E11_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_E11_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_pistol_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-5.2, -15, 0.9),
    Ang = Angle(0,0,0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 54,
}

-- Holdtype
SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "pistol"
SWEP.HoldtypeSights = "revolver"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL

SWEP.SprintPos = Vector(0, -10, -5)
SWEP.SprintAng = Angle(20, 0, 0)

SWEP.CustomizePos = Vector(10, -10, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.ActivePos = Vector(-2, -8, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.HolsterPos = Vector(0, -10, -5)
SWEP.HolsterAng = Angle(20, 0, 0)

SWEP.BarrelLength = 20

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["e11_k_splitter"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["e11_k_supressor"] = {
        VMBodygroups = {{ind = 3, bg = 2}},
    },
    ["e11_powerpack"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["e11_stock_complete"] = {
        VMBodygroups = {{ind = 8, bg = 2}},
    },
    ["e11_k_powercell"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["e11_scope"] = {
        VMBodygroups = {{ind = 5, bg = 1}},
    },
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "DC-15SA",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(-0.13, -1.45, 5),
                   ang = Angle(90, 0, -90)
               },
               IsMuzzleDevice = true
           }
        }
    }
}

SWEP.Attachments = {     
    {
        PrintName = "Sight", 
        DefaultAttName = "Iron Sight",
        Slot = "optic",
        Bone = "DC-15SA",
        InstalledEles = {"e11_scope"},
        VMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(-0.13, -2.35, -3.5),
            vang = Angle(90, 0, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        Bone = "DC-15SA",
        Offset = {
            vpos = Vector(-0.13, -1.45, 5),
            vang = Angle(90, 0, -90),
        },
    },  
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "DC-15SA",
        VMScale = Vector(0.8,0.8,0.8),
        Offset = {
            vpos = Vector(-0.13, 0.3, 2.2),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Energization",
        DefaultAttName = "None",
        Slot = {"ammo"},
    },
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
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
        PrintName = "Internal Modifications",
        DefaultAttName = "None",
        Slot = {"uc_fg"},
    },    
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = "charm",
        VMScale = Vector(0.5, 0.5, 0.5),
        Bone = "DC-15SA",
        Offset = {
            vpos = Vector(0.81, -0.8, -6.6),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        Bone = "DC-15SA",
        Offset = {
            vpos = Vector(0.6, -1.5, -5),
            vang = Angle(90, 0, -90),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["idle"] = {
        Source = false,
    },
    ["idle_iron"] = {
        Source = false,
    },
	["fire"] = {
        Source = {"fire"},
    },
    ["fire_iron"] = {},
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        LHIK = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 45 / 30},
        },
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {
                s = "arccw/kraken/empire/draw_pistol.wav",
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
                s = "arccw/kraken/empire/draw_pistol.wav",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
}
