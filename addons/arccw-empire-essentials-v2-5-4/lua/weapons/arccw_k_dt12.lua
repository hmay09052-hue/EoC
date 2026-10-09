AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 2 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DT-12"
SWEP.Trivia_Class = "Blaster Pistol"
SWEP.SubCategory = "1Pistols"
SWEP.Trivia_Desc = "The DT-12 heavy blaster pistol was a model of blaster pistol. A DT-12 was used by the bounty hunter Greedo during his unsuccessful confrontation with the smuggler Han Solo at Chalmun's Spaceport Cantina."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Rebel Alliance"
SWEP.IconOverride = "entities/kraken/empire-essentials/dt12.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_dt12.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_dt12.mdl"

SWEP.ViewModelFOV = 54
SWEP.HideViewmodel = false
SWEP.WorldModelOffset = {
    pos = Vector(-12, 7, -7),
    ang = Angle(-70, 20, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 1.5,
    [HITGROUP_CHEST] = 1,
    [HITGROUP_STOMACH] = 1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.9,
    [HITGROUP_RIGHTLEG] = 0.9,
}

SWEP.Damage = 24
SWEP.DamageMin = 20
SWEP.RangeMin = 0
SWEP.Range = 270
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 17

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.9

SWEP.Delay = 60 / 330
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
        Mode = -3,
        PostBurstDelay = 0.1,
        RunawayBurst = false,
        Mult_RPM = 5,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 150
SWEP.JumpDispersion = 300

-- Speed Mult
SWEP.SpeedMult = 1
SWEP.SightedSpeedMult = 0.77
SWEP.ShootSpeedMult = 1

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW__DT12Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DT12_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_pistol_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2.053, -6.136, 0.785),
    Ang = Angle(0, -1.563, 4.584),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "pistol"
SWEP.HoldtypeSights = "revolver"
SWEP.HoltypeCustomize = "slam"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.SprintPos = Vector(0, -3, -5)
SWEP.SprintAng = Angle(20, 0, 0)

SWEP.CustomizePos = Vector(10, -10, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.HolsterPos = Vector(0, -10, -5)
SWEP.HolsterAng = Angle(20, 0, 0)

SWEP.BarrelLength = 20

-- Attachments
SWEP.DefaultElements = {"muzzle1"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["e11_scope"] = {
        VMBodygroups = {{ind = 2, bg = 1}, {ind = 3, bg = 1}},
    },
    ["muzzle1"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "Gun_Controller",
               Scale = Vector(0, 0, 0),                
               Offset = {
                pos = Vector(0, 8, 2),
                ang = Angle(0, -90, 0)
               },
               IsMuzzleDevice = true
           }
        }
    }
}

SWEP.Attachments = {     
    {
        PrintName = "Optics",
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "Gun_Controller",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0, 1, 2.32),
            vang = Angle(0, -90, 0),
        },
        InstalledEles = {"e11_scope"},
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "DT-12 Muzzle",
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "Gun_Controller",
        InstalledEles = {"muzzle"},
        Offset = {
            vpos = Vector(0, 5.45, 1.75),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Bone = "Gun_Controller",
        Offset = {
            vpos = Vector(0.5, 1.5, 1.85),
            vang = Angle(0, -90, 90),
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
        PrintName = "Internal Modifications",
        DefaultAttName = "None",
        Slot = {"uc_fg"},
    },    
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = "charm",
        VMScale = Vector(0.5, 0.5, 0.5),
        WMScale = Vector(0.5, 0.5, 0.5),       
        Bone = "Gun_Controller",
        Offset = {
            vpos = Vector(0.7, 0.5, 0.5),
            vang = Angle(0, -90, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "Gun_Controller",
        Offset = {
            vpos = Vector(0.4, -0.3, 1.7),
            vang = Angle(0, -90, 0),
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
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        SoundTable = {
            {s = "arccw/kraken/empire/e-series/e11_reload.wav", t = 0.1 },
        },
    },
}
