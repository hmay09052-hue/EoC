AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. II"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "MX-1 Aquiles"
SWEP.Trivia_Class = "Slugthrower rifle"
SWEP.Trivia_Desc = "Slugthrower rifle designed originally for military purposes, now modernized and being used by many Bounty Hunters, Civillians and even Mercenaries or Military Corporations in the galaxy. Is uses old tech, shooting Solid Slug rounds. Apparently created during the ancient wars of the Old Republic, it remains an effective weapon. Even shooting Solid Slug bullets, it could hit targets at extreme ranges and penetrate energy shields. Used primarily by primitive cultures and hunters, they were strong enough to tear whole limbs from a body"
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Solid Slug"
SWEP.IconOverride = "entities/galexpansion_vol2/aquiles.png"

-- Base
SWEP.DefaultBodygroups = "010000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/galexpansion_vol2/v_slugrifle.mdl"
SWEP.WorldModel = "models/arccw/kraken/galexpansion_vol2/worldmodel/w_slugrifle.mdl"

SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-0, 2.7, -4),
    ang = Angle(-15, 0, 180),
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

SWEP.Damage = 105
SWEP.DamageMin = 95
SWEP.RangeMin = 0
SWEP.Range = 700
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 700

SWEP.AlwaysPhysBullet = true
SWEP.PhysTracerProfile = 4

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 8

SWEP.Recoil = 1.1
SWEP.RecoilSide = 0.6
SWEP.RecoilRise = 0.9

SWEP.Delay = 60 / 170
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

local s = "ArcCW_Kraken.OverheatWarn"
local p = {
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

SWEP.ShootSound = "ArcCW_Kraken.SW_MX1_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_MX1_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "muzzleflash_shotgun"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false

SWEP.ShellModel = "models/shells/shell_556.mdl"
SWEP.ShellPitch = 90
SWEP.ShellScale = 1.2
SWEP.ShellRotateAngle = Angle(0, 180, 0)
SWEP.MuzzleFlashColor = Color(255, 174, 0)

-- Ironsight
SWEP.HasHoloHUD1 = true
SWEP.IronSightStruct = {
    Pos = Vector(-2.037, -0.552, 0.749),
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
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.SprintPos = Vector(2, -1, 0)
SWEP.SprintAng = Angle(-10, 26, 0)

SWEP.CustomizePos = Vector(9, 1, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.CrouchPos = Vector(0, 0, 0)
SWEP.CrouchAng = Angle(0, 0, 0)

SWEP.ActivePos = Vector(0, 3, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, 2, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 30
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["scopeattach"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Sight", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "W_Main",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        InstalledEles = {"scopeattach"},
        Offset = {
            vpos = Vector(-0.01, -0.2, 8.6),
            vang = Angle(90, 0, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        Bone = "W_Main",
        VMScale = Vector(1.1, 1.1, 1.1),
        WMScale = Vector(1.1, 1.1, 1.1),
        Offset = {
            vpos = Vector(0.03, 0.3, 30.4),
            vang = Angle(90, 0, -90),
        },
    },  
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "W_Main",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(-0.2, 0.25, 25),
            vang = Angle(90, 0, 180),
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
        Bone = "W_Main",
        Offset = {
            vpos = Vector(0.88, 1.1, -2.3),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Bone = "W_Main",
        Offset = {
            vpos = Vector(0.95, 1.2, 2),
            vang = Angle(90, 0, -90),
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
    ["idle_empty"] = {
        Source = "idle_emp",
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
    ["draw_empty"] = {
        Source = "draw_emp",
        Mult = 1,
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
        Source = "idle",
        Time = 0
    },
    ["holster_empty"] = {
        Source = "idle_emp",
        Time = 0
    },
    ["fire"] = {
        Source = "fire",
        ShellEjectAt = 0.1 / 40,
    },
    ["fire_iron"] = {
        Source = "fire_iron",
        ShellEjectAt = 0.1 / 40,
    },
    ["fire_empty"] = {
        Source = "fire_gempty_no",
        ShellEjectAt = 0.1 / 40,
        SoundTable = {
            {s =  "ArcCW_Kraken.PingAquiles" ,   t = 1 / 40},
        },
    },
    ["fire_iron_empty"] = {
        Source = "fire_iron_no",
        ShellEjectAt = 0.1 / 40,
        SoundTable = {
            {s =  "ArcCW_Kraken.PingAquiles" ,   t = 1 / 40},
        },
    },
    ["reload"] = {
        Source = "wet",
        Mult = 1.5,
        Shelleject = 17 / 40,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s =  "arccw/kraken/galexpansion_vol2/aquiles/handling/garand_boltback.wav" ,   t = 10.1 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/aquiles/handling/garand_magout.wav" ,   t = 16 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/aquiles/handling/garand_magin.wav" ,    t = 75 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/aquiles/handling/garand_maghit.wav" ,   t = 85 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/aquiles/handling/garand_boltrelease.wav" ,    t = 110.1 / 40},		
        },
    },
    ["reload_empty"] = {
        Source = "dry",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s =  "arccw/kraken/galexpansion_vol2/aquiles/handling/garand_maghit.wav" ,   t = 30.1 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/aquiles/handling/garand_magin.wav" ,    t = 35 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/aquiles/handling/garand_boltrelease.wav" ,    t = 50.1 / 40},
        },
    },
}