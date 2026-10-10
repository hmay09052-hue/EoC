AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "EE-3"
SWEP.Trivia_Class = "Blaster, Carbine"
SWEP.SubCategory = "2Carbines"
SWEP.Trivia_Desc = "The EE-3 carbine rifle was a blaster that was modeled after the E-11 blaster rifle later used by Imperial stormtroopers. The rifle consisted of a small handle attached to a long circular barrel. At least two versions of the EE-3 were known to exist, with one featuring a hand grip covering the length of the barrel."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Rebel Alliance, Mercenaries"
SWEP.IconOverride = "entities/kraken/empire-essentials/ee3.png"

-- Viewmodel & Entity Properties
SWEP.UseHands = true

SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_ee3.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_ee3.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-7, 4, -3.7),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Special Properties
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 35
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.5
SWEP.HeatFix = true 

SWEP.InfiniteAmmo = true 
SWEP.BottomlessClip = true 

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

SWEP.Damage = 37
SWEP.DamageMin = 30
SWEP.RangeMin = 0
SWEP.Range = 320
SWEP.Penetration = 15
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.65

SWEP.Delay = 60 / 450
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
        Mult_RPM = 3,
    },
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0.1
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 500

-- Speed Mult
SWEP.SpeedMult = 0.85 + 0.05
SWEP.SightedSpeedMult = 0.7 / 0.85
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult =  0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_EMPIRE_EE3_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_EMPIRE_EE3_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.05, -3.704, 2.1),
    Ang = Vector(0, 0, -3.9),
    Magnification = 1.15,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
    ViewModelFOV = 55,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 2, 1)
SWEP.ActiveAng = Angle(0, 0, -3.95)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 25

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["e11_scope"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["muzzle"] = {
        VMElements = {
            {
                Model = "models/hunter/plates/plate.mdl",
                Bone = "E11S_CONTR",
                Scale = Vector(0, 0, 0),                
                Offset = {
                    pos = Vector(0, 14, -0.5),
                    ang = Angle(-90, -90, 0)
                },
                IsMuzzleDevice = true
            }
         }, 
    }
}

SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "None",
        Slot = "optic",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(0.55, 0, 1.8),
            vang = Angle(0, -90, 0),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, -0.01),
        InstalledEles = {"e11_scope"},
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "E11S_CONTR",
        InstalledEles = {"e11_laser"},
        Offset = {
            vpos = Vector(1.1, 6.5, 0.6),
            vang = Angle(90, -90, 0),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        Bone = "E11S_CONTR",
        VMScale = Vector(1.4, 1.4, 1.4),
        WMScale = Vector(1.4, 1.4, 1.4),
        Offset = {
            vpos = Vector(0, 11.75, 0),
            vang = Angle(0, -90, 0),
        },
    },  
    {
        PrintName = "Foregrip", 
        DefaultAttName = "Standard",
        Slot = "foregrip",
        Bone = "E11S_CONTR",
        VMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(0.1, 4, -0.8),
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
        VMScale = Vector(0.7, 0.7, 0.7),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(1.1, -1, -1.4),
            vang = Angle(0, -90, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(1.1, -3, -0.45),
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
    ["fix"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 45 / 30},
        },
    },
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
