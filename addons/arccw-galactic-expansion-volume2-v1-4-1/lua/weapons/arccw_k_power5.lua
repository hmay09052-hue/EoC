AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1

SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. II"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "POWER-5"
SWEP.Trivia_Class = "Blaster Pistol"
SWEP.Trivia_Desc = "Blaster Pistol designed originally for military purposes, now modernized and being used by many Bounty Hunters, Civillians and even Mercenaries or Military Corporations in the galaxy."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/galexpansion_vol2/power5.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "000000000000000000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/galexpansion_vol2/v_power5.mdl"
SWEP.WorldModel = "models/arccw/kraken/galexpansion_vol2/worldmodel/w_power5.mdl"

SWEP.ViewModelFOV = 65

SWEP.WorldModelOffset = {
    pos = Vector(-3, 4, -6),
    ang = Angle(0, 0, -170),
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

SWEP.Damage = 43
SWEP.DamageMin = 22
SWEP.RangeMin = 0
SWEP.Range = 270
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 700

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 12

SWEP.Recoil = 1.2
SWEP.RecoilSide = 0.6
SWEP.RecoilRise = 0.6

SWEP.Delay = 60 / 180
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
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_POWER5_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_POWER5_Distant"
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
    Pos = Vector(-3.04, 4.897, 0.159),
    Ang = Vector(0, 0, 5),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "pistol"
SWEP.HoldtypeSights = "revolver"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL

SWEP.SprintAng = Angle(10, -15, -10)
SWEP.SprintPos = Vector(0, 4, -1.5)

SWEP.CustomizePos = Vector(10, 4, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.CrouchPos = Vector(-0.2, -0.5, -0.75)
SWEP.CrouchAng = Angle(0, 0, -7)

SWEP.ActivePos = Vector(0, 5, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, 5, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 20
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["muzzleattach"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        VMScale = Vector(1.2, 1.2, 1.2),
        WMScale = Vector(1.2, 1.2, 1.2),
        InstalledEles = {"muzzleattach"},
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        Bone = "W_Main",
        Offset = {
            vpos = Vector(0, -0.1, 6.55),
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
            vpos = Vector(0, 0.5, 6),
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
            vpos = Vector(0.43, 1.5, 1),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "W_Main",
        Offset = {
            vpos = Vector(0.3, -0.2, -0.3),
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
        Source = "idle_single",
    },
    ["draw"] = {
        Source = "idle_single", -- QC sequence source, can be {"table", "of", "strings"} or "string"
        --Time = 0.5, -- overrides the duration of the sequence
        Mult = 1, -- multiplies time
        SoundTable = {
            {s =  "gekolt_css/elite_twirl.wav" ,   t = 0 / 40},
        },
    },
    ["holster"] = {
        Source = "idle_single",
        Time = 0
    },
    ["fire"] = {
        Source = "fire_edge",
    },
    ["reload"] = {
        Source = "wet_edge",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        FireASAP = true,
        SoundTable = {
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/mauser/magout.wav" ,   t = 0.1 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/mauser/magin.wav" ,   t = 46 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/mauser/spin.wav" ,    t = 79 / 40},
        },
    },
    ["reload_empty"] = {
        Source = "dry_edge",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/mauser/magout_empty.wav" ,   t = 0.1 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/mauser/magin_empty.wav" ,   t = 40 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/mauser/bolt_empty.wav" ,   t = 76 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/mauser/spin_empty.wav" ,    t = 110 / 40},
            },
    },
}