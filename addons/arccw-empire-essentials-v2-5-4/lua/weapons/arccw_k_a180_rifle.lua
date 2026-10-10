AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "A-180 Rifle"
SWEP.Trivia_Class = "Blaster, Rifle"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "The A-180 blaster, also known as the A180 pistol, was a modular blaster manufactured by BlasTech Industries. It was a highly versatile design with multiple configurations that could be easily reconfigured from a blaster pistol to a blaster rifle, a sniper rifle/longblaster[5], or an portable ion launcher depending on the situation."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Rebel Alliance"
SWEP.IconOverride = "entities/kraken/empire-essentials/a180_rifle.png"

-- Viewmodel & Entity Properties
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.DefaultBodygroups = "0001000000"
SWEP.ViewModel = "models/arccw/kraken/empire/v_a180.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_a180_rifle.mdl"

SWEP.ViewModelFOV = 54
SWEP.WorldModelOffset = {
    pos = Vector(-8, 4, -4),
    ang = Angle(-15, 0, -180),
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

SWEP.Damage = 35
SWEP.DamageMin = 29
SWEP.RangeMin = 0
SWEP.Range = 620
SWEP.Penetration = 10
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 900

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 35

SWEP.Recoil = 0.56
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.75

SWEP.Delay = 60 / 390
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


SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 200
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

SWEP.ShootSound = "ArcCW_Kraken.SW_A180_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_A180_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.14, -11, 2.55),
    Ang = Angle(0, 0, -3.201),
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

SWEP.ActivePos = Vector(0, 4, 1)
SWEP.ActiveAng = Angle(0, 0, -3.95)


SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(15, 0, -1.321)
SWEP.CustomizeAng = Angle(18.2, 39.4, 14.8)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 30

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["e11_scope"] = {
        VMBodygroups = {{ind = 5, bg = 1}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["e11_muzzle"] = {
        VMBodygroups = {{ind = 2, bg = 0}},
    },
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "E11S_CONTR",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(-0.29, 15, -0.22),
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
        DefaultAttName = "Iron Sight",
        Slot = "optic",
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(-0.19, 5, 1),
            vang = Angle(0, -90, 0),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
        InstalledEles = {"e11_scope"},
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "E11S_CONTR",
        InstalledEles = {"e11_laser"},
        Offset = {
            vpos = Vector(0.87, 11.5, 0.1),
            vang = Angle(90, -90, 0),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        InstalledEles = {"e11_muzzle"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(-0.29, 13.7, -0.22),
            vang = Angle(0, -90, 0),
        },
    },  
    {
        PrintName = "Foregrip", 
        DefaultAttName = "Standard",
        Slot = "foregrip",
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(-0.1, 3, -2.8),
            vang = Angle(0, -90, 0),
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
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(1.15, -4.5, -1),
            vang = Angle(0, -90, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(0.5, 4, -0.4),
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
        Source = "shoot",
    },
    ["fire_iron"] = {},
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
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
}
