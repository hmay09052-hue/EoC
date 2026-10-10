AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.HasHoloHUD1 = true

SWEP.Slot = 4 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DLT-20s"
SWEP.Trivia_Class = "Blaster Rifle"
SWEP.Trivia_Desc = "The DLT-20A blaster rifle, also known as the DLT-20A laser rifle, was a model of blaster rifle and longblaster produced by BlasTech Industries. Members of the Galactic Empire's Stormtrooper Corps sometimes used DLT-20As instead of their standard issue E-11 medium blaster rifles. IG-assassin droid IG-11 carried this model of rifle, without the scope attached. Another type of rifle, the pulse cannon, utilized the frame assembly of a DLT-20A. Han Solo used a DLT-20A as a sniper rifle during the Battle of Vrogas Vas."
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.IconOverride = "entities/kraken/galactic/dlt20s.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00100000000000"

SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/galactic/v_dlt20a.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_dlt20.mdl"

SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-7, 3, -3),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 15
SWEP.HeatDissipation = 7
SWEP.HeatLockout = true
SWEP.HeatFix = true
SWEP.HeatDelayTime = 0.5

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 45
SWEP.DamageMin = 28
SWEP.RangeMin = 0
SWEP.Range = 650
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 250, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_green"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 25

SWEP.Recoil = 0.8
SWEP.RecoilSide = 0.35
SWEP.RecoilRise = 0.75

SWEP.Delay = 60 / 300
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
        Mode = -3,
        Mult_RPM = 3,
        PostBurstDelay = 0.1,
    },
	{
		Mode = 0,
   	}
}

local s = "ArcCW_Kraken.OverheatWarn"
local p = {
    [5] = 70,
    [4] = 70,
    [3] = 70,
    [2] = 80,
    [1] = 90,
    [0] = 100,
}
SWEP.Hook_AddShootSound = function(wep, data)
    local pitch = p[wep:Clip1()]
    if pitch then
        wep:MyEmitSound(s, 100, pitch, 0.5, CHAN_AUTO)
    end
end

SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 150
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
SWEP.ShootPitchVariation = 0

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_DLT20_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_DLT20_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "blaster_muzzle_green"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(0, 250, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2.994, -4, -0.05),
    Ang = Vector(2.042, 0, 0),
    Magnification = 1.15,
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

SWEP.ActivePos = Vector(-1, 2, -1)
SWEP.ActiveAng = Angle(2, 0, -2)

SWEP.SprintPos = Vector(4.019, -5.226, -3)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(0, 0, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.InBipodPos = Vector(-8, 0, -4)
SWEP.InBipodMult = Vector(2, 0, 1)
SWEP.BarrelLength = 25
-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "E11S_CONTR",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(-2.4, 24, 2),
                   ang = Angle(-90, -90, 0),
               },
               IsMuzzleDevice = true,
           }
        }, 
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "Iron Sight",
        Slot = "optic",
        Bone = "E11S_CONTR",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.1, 1, 2.4),
            vang = Angle(0, -90, 0),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, -0.05),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(-0.8, 8.5, 0.9),
            vang = Angle(-90, -90, 0),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        VMScale = Vector(1.5, 1.5, 1.5),
        WMScale = Vector(1.5, 1.5, 1.5),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(-0.1, 25.3, 0.9),
            vang = Angle(0, -90, 0),
        },
    },  
    {
        PrintName = "Foregrip", 
        DefaultAttName = "None",
        Slot = "foregrip",
        Bone = "E11S_CONTR",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(0., 6, 0.2),
            vang = Angle(5, -90, 0),
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
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(0.8, -0.2, -0.8),
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
            vpos = Vector(0.9, -0.33, 0.2),
            vang = Angle(0, -90, 0),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}
-- Don't touch this unless you know what you're doing
SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
	["fire"] = {
        Source = "shoot",
    },
    ["fire_iron"] = {
        Source = "shoot",
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 45 / 30},
            {s = "ArcCW_Kraken.Grab", t = 43 / 30},
        },
    },
    ["fix"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 45 / 30},
            {s = "ArcCW_Kraken.Grab", t = 43 / 30},
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