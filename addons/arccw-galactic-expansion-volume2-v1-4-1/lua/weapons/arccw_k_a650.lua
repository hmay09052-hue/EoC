AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. II"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "A-650"
SWEP.Trivia_Class = "Blaster Rifle"
SWEP.Trivia_Desc = "Military Blaster Rifle used along the galaxy. It offers what is necessary and what every blaster should offer to satisfy the needs of its shooter."
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/galexpansion_vol2/a650.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "011000000000000"

SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/galexpansion_vol2/v_a650.mdl"
SWEP.WorldModel = "models/arccw/kraken/galexpansion_vol2/worldmodel/w_a650.mdl"

SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(6, 0.5, -4.9),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}
-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 35
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
SWEP.HeatFix = true
SWEP.HeatDelayTime = 0.5

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 46
SWEP.DamageMin = 24
SWEP.RangeMin = 0
SWEP.Range = 340
SWEP.Penetration = 10
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.Recoil = 0.8
SWEP.RecoilSide = 0.3
SWEP.RecoilRise = 0.7
SWEP.MaxRecoilBlowback = 1
SWEP.RecoilPunch = 1
SWEP.RecoilVMShake = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 70

SWEP.Delay = 60 / 500
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
		Mode = 2,
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

SWEP.ShootSound = "ArcCW_Kraken.SW_A650_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_A650_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.HasHoloHUD1 = true
SWEP.IronSightStruct = {
    Pos = Vector(-2.9, 0, 1.2),
    Ang = Vector(0, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "ar2"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.SprintPos = Vector(2, -1, 0)
SWEP.SprintAng = Angle(-10, 26, 0)

SWEP.CustomizePos = Vector(10, 0, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.CrouchPos = Vector(-3, 0, 0)
SWEP.CrouchAng = Angle(0, 0, 0)

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BipodDispersion = 1
SWEP.BipodRecoil = 1

SWEP.InBipodPos = Vector(-8, 0, -4)
SWEP.InBipodMult = Vector(2, 1, 1)

SWEP.BarrelLength = 35
-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "STG44",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(0, 0, 34),
                   ang = Angle(90, 0, 0),
               },
               IsMuzzleDevice = false,
           }
        }, 
    },
    ["integrated_holosight"] = {
        VMBodygroups = {{ind = 1, bg = 1}, {ind = 2, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Holosight", 
        DefaultAttName = "Integrated Holosight",
        Slot = "optic",
        Bone = "STG44",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        InstalledEles = {"integrated_holosight"},
        Offset = {
            vpos = Vector(-0.37, 1.856, 6),
            vang = Angle(90, -90, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(180,0,0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        VMScale = Vector(1.2,1.2,1.2),
        WMScale = Vector(1.2,1.2,1.2),
        Bone = "STG44",
        Offset = {
            vpos = Vector(-0.37, 18.9, 5.5),
            vang = Angle(90, -90, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "STG44",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Offset = {
            vpos = Vector(-0.7, 9, 5.5),
            vang = Angle(90, -90, -180),
        },
    },
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        Bone = "STG44",
        Offset = {
            vpos = Vector(-0.25, 6.5, 2),
            vang = Angle(90, -90, -90),
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
        Bone = "STG44",
        Offset = {
            vpos = Vector(0.6, -9.1, 3.15),
            vang = Angle(90, -90, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Bone = "STG44",
        Offset = {
            vpos = Vector(0.55, 0, 3),
            vang = Angle(90, -90, -90),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
local path = "arccw/kraken/galexpansion_vol2/reloadsounds/stg/stg44_"

SWEP.Animations = {
    ["idle"] = { Source = "idle" },
    ["fire"] = { Mult = 0.9, Source = {
        "base_fire",
        "base_fire2",
        "base_fire3"
    } },
    ["fire_iron"] = { Mult = 0.9, Source = {
        "iron_fire_1",
        "iron_fire_2",
        "iron_fire_3",
    } },
    ["dryfire"] = { Source = "base_dryfire" },
    ["dryfire_iron"] = { Source = "iron_dryfire" },
    ["bash"] = { Source = "base_melee_bash" },
    ["reload"] = { Source = "overheat",         LHIK = true,
    TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,  MinProgress = 0.75,         SoundTable = {
        {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
        {s = "ArcCW_Kraken.OverheatFix", t = 60 / 30},
        {s = "ArcCW_Kraken.Grab", t = 65 / 30},
    }, },
    ["fix"] = { Source = "overheat",         LHIK = true,
    TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,  MinProgress = 0.75,         SoundTable = {
        {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
        {s = "ArcCW_Kraken.OverheatFix", t = 60 / 30},
        {s = "ArcCW_Kraken.Grab", t = 65 / 30},
    }, },
    ["reload_empty"] = { Source = "base_reload",         LHIK = true,
    TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,  MinProgress = 0.75, SoundTable = {
        {t = 15 / 30, s = path .. "magrelease.wav"},
        {t = 18 / 30, s = path .. "magout.wav"},
        {t = 62 / 30, s = path .. "magin.wav"},
    } },
    ["draw"] = { Source = "base_draw", SoundTable = {
    } },
    ["holster"] = { Source = "base_holster", SoundTable = {
    } },
}