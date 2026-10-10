AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. II"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Hutt Splitter"
SWEP.Trivia_Class = "Slugthrower rifle"
SWEP.Trivia_Desc = "Slugthrower rifle designed originally for military purposes, now modernized and being used by many Bounty Hunters, Civillians and even Mercenaries or Military Corporations in the galaxy. Is uses old tech, shooting Solid Slug rounds. Apparently created during the ancient wars of the Old Republic, it remains an effective weapon. Even shooting Solid Slug bullets, it could hit targets at extreme ranges and penetrate energy shields. Used primarily by primitive cultures and hunters, they were strong enough to tear whole limbs from a body"
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Solid Slug"
SWEP.IconOverride = "entities/galexpansion_vol2/huttsplitter.png"

-- Base
SWEP.DefaultBodygroups = "010000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/galexpansion_vol2/v_huttsplitter.mdl"
SWEP.WorldModel = "models/arccw/kraken/galexpansion_vol2/worldmodel/w_huttsplitter.mdl"

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

SWEP.Damage = 22
SWEP.DamageMin = 11
SWEP.RangeMin = 0
SWEP.Range = 150
SWEP.Penetration = 8
SWEP.DamageType = DMG_BUCKSHOT
SWEP.MuzzleVelocity = 700

SWEP.NoRandSpread = true
SWEP.CanBash = true

SWEP.ShotgunSpreadPattern = {
    [1] = Angle(0, 0, 0),
    [2] = Angle(0, 1, 0),
    [3] = Angle(0, -1, 0),
    [4] = Angle(2.1, 0, 0),
    [5] = Angle(-2.1, 0, 0),
    [6] = Angle(1.4, 1.2, 0),
    [7] = Angle(-1.4, 1.2, 0),
    [8] = Angle(1.4, -1.2, 0),
    [9] = Angle(-1.4, -1.2, 0),
}

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 8

SWEP.Recoil = 2
SWEP.RecoilSide = 2
SWEP.RecoilRise = 2
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1.5
SWEP.RecoilVMShake = 2

SWEP.Delay = 60 / 120
SWEP.Num = 9
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
		Mode = -2,
        Mult_RPM = 4,
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

SWEP.AccuracyMOA = 5
SWEP.HipDispersion = 100
SWEP.MoveDispersion = 75
SWEP.JumpDispersion = 150

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

SWEP.ShootSound = "ArcCW_Kraken.SW_HUTTSPLITTER_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_HUTTSPLITTER_Distant"
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
    Pos = Vector(-1.975, 2, 0.1),
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

SWEP.ActivePos = Vector(0, 3, 0-1)
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
            vpos = Vector(-0.01, -1.2, 1.3),
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
            vpos = Vector(0.03, -0.45, 18.6),
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
            vpos = Vector(-0.5, -0.5, 8),
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
            vpos = Vector(0.59, 0.8, -3.62),
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
            vpos = Vector(0.85, -0.3, 1.2),
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
        Source = "fire_slam",
        SoundTable = {
            {s =  "weapon_hand/reload_heavy/locknload/023d-00000ad0.mp3" ,   t = 5 / 40},
        },
    },
    ["reload"] = {
        Source = "overheat",
        Mult = 1.5,
        ShellEjectAt = false,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
}