AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Valken 38i"
SWEP.Trivia_Class = "Blaster, Long Rifle"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The Valken-38x was a model of longblaster that was manufactured for high precision and power over long ranges. It was utilized by the Galactic Republic during the Clone Wars."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Galactic Republic"
SWEP.IconOverride = "entities/kraken/empire-essentials/valken38_sniper.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00000100"
SWEP.DefaultWMBodygroups = "00000100"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_valken38i.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_valken38i.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-7, 4, -6),
    ang = Angle(-10, 0, -180),
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

SWEP.Damage = 89
SWEP.DamageMin = 45
SWEP.RangeMin = 0
SWEP.Range = 900
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 250, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_green"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 18

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 1.2

SWEP.Delay = 60 / 180
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
        Mode = -3,
        PostBurstDelay = 0.15,
        RunawayBurst = false,
        Mult_RPM = 3,
    },
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0.2
SWEP.HipDispersion = 250
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

SWEP.ShootSound = "ArcCW_Kraken.SW_VALKEN_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_VALKEN_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_green"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 250, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2.99, -4.258, 1.36),
    Ang = Vector(0, 0.127, 2.813),
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

SWEP.ActivePos = Vector(0, 2, 1)
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
    ["valken_stock"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["dlt19_bipoddown"] = {
        VMBodygroups = {{ind = 5, bg = 0}},
    },
    ["dlt19_bipodoff"] = {
        VMBodygroups = {{ind = 5, bg = 1}},
    },
    ["valken_muzzle"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["valken_scope"] = {
        VMBodygroups = {{ind = 3, bg = 1}, {ind = 1, bg = 1}},
    },
    ["e11_grip_standard"] = {
        VMBodygroups = {{ind = 4, bg = 0}},
    },
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "Valken38x_material",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(0.19, 19.5, 0.65),
                   ang = Angle(0, -90, 0),
               },
               IsMuzzleDevice = true
           }
        }
    }
}

SWEP.Attachments = {
    {
        PrintName = "Optics",
        DefaultAttName = "Standard",
        Slot = "optic",
        Bone = "Valken38x_material",
        Offset = {
            vpos = Vector(0.25, -3.2, 1.5),
            vang = Angle(0, -90, -0),
        },
        InstalledEles = {"valken_scope"},
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Valken 38x Muzzle",
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "Valken38x_material",
        InstalledEles = {"valken_muzzle"},
        Offset = {
            vpos = Vector(0.19, 19.5, 0.65),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "Valken38x_material",
        VMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.9, 16.5, 0.65),
            vang = Angle(0, -90, 90),
        },
    },
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"dlt19_bipod", "foregrip"},
        Bone = "Valken38x_material",
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
        Bone = "Valken38x_material",
        VMScale = Vector(0.5, 0.5, 0.5),
        Offset = {
            vpos = Vector(1.05, -3.65, -1.13),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "Valken38x_material",
        VMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(1.05, 2.2 , 0.55),
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
        Source = false,
    },
    ["fire"] = {
        Source = "Shoot"
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
