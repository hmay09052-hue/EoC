AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1

SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. II"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "E-5r"
SWEP.Trivia_Class = "Blaster Revolver"
SWEP.Trivia_Desc = "Blaster Revolver designed originally for military purposes, now modernized and being used by many Bounty Hunters, Civillians and even Mercenaries or Military Corporations in the galaxy."
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/galexpansion_vol2/e5r.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "001000000000000000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/galexpansion_vol2/v_whistler.mdl"
SWEP.WorldModel = "models/arccw/kraken/galexpansion_vol2/worldmodel/w_whistler.mdl"

SWEP.ViewModelFOV = 65

SWEP.WorldModelOffset = {
    pos = Vector(-10.5, 3, -5),
    ang = Angle(0, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
}

-- Damage & Tracer
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.15,
    [HITGROUP_CHEST] = 1,
    [HITGROUP_STOMACH] = 1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.9,
    [HITGROUP_RIGHTLEG] = 0.9,
}

SWEP.Damage = 33
SWEP.DamageMin = 23
SWEP.RangeMin = 0
SWEP.Range = 100
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 18

SWEP.Recoil = 1.3
SWEP.RecoilSide = 1.25
SWEP.RecoilRise = 0.1
SWEP.RecoilPunch = 2

SWEP.Delay = 60 / 140
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
SWEP.HipDispersion = 200
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

SWEP.ShootSound = "ArcCW_Kraken.SW_E5R_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_E5R_Distant"
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
    Pos = Vector(-0.11, 0, -1.8),
    Ang = Vector(0, 0, 0),
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

SWEP.CrouchPos = Vector(-4.5, -3, 1.5)
SWEP.CrouchAng = Angle(1.569, 0.88, -50.458)

SWEP.SprintPos = Vector(0, 0, 0)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(0, -2, 1)
SWEP.CustomizeAng = Angle(0, 0, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)
SWEP.BarrelOffsetCrouch = Vector(0, 0, -2)

SWEP.BarrelLength = 25
-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "def_c_base",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(0, -3.7, 22),
                   ang = Angle(90, 0, -90),
               },
               IsMuzzleDevice = false,
           }
        }, 
    },
    ["integrated_holosight"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["muzzleattach"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        InstalledEles = {"muzzleattach"},
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        Bone = "def_c_base",
        Offset = {
            vpos = Vector(0, -3.7, 15.5),
            vang = Angle(90, 0, -90),
        },
    },  
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "def_c_base",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0, -1.5, 12.3),
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
        Bone = "def_c_base",
        Offset = {
            vpos = Vector(1.1, -2.65, 4.5),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Bone = "def_c_base",
        Offset = {
            vpos = Vector(1.4, -1.9, 9.3),
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
    ["idle_sprint"] = {Source = "sprint", Mult = 0.9},
    ["enter_sprint"] = {Source = "sprint_in", Mult = 1},
    ["exit_sprint"] = {Source = "sprint_out", Mult = 1},
    ["ready"] = {
        Source = "draw_first",
        SoundTable = {
            {p = 100, s = "weapons/wingman/Weapon_Wingman_FirstPullout_V1_2ch.ogg", t = 0 / 30},
    },
    },
    ["draw"] = {
        Source = "draw",
    },
    ["holster"] = {
        Source = "holster",
    },
    ["idle_iron"] = {
        Source = "iron_idle",
    },
    ["fire"] = {
        Source = {"fire", "fire2"},
    },
    ["enter_sight"] = {
        Source = "iron_in",
        SoundTable = {
            {p = 100, s = "Apex_Ads_In_Wingman", t = 0 / 30},
    },
    },
    ["fire_sight"] = {
        Source = "iron_fire",
    },
    ["exit_sight"] = {
        Source = "iron_out",
        SoundTable = {
            {p = 100, s = "Apex_Ads_In_Wingman", t = 0 / 30},
    },
    },
    ["enter_inspect"] = {
        Source = "inspect_in",
    },
    ["exit_inspect"] = {
        Source = "inspect_out",
        SoundTable = {
            {p = 100, s = "weapons/wingman/Weapon_Wingman_Inspect_End_Fr160_V1_2ch_01.ogg", t = 0 / 30},
    },
    },
    ["idle_inspect"] = {
        Source = "inspect",
        SoundTable = {
            {p = 100, s = "weapons/wingman/Weapon_Wingman_Inspect_Part1_Fr01_V1_2ch_01.ogg", t = 1 / 30},
            {p = 100, s = "weapons/wingman/Weapon_Wingman_Inspect_Part2_Fr27_V1_2ch_01.ogg", t = 27 / 30},
            {p = 100, s = "weapons/wingman/Weapon_Wingman_Inspect_Part3_Fr79_V1_2ch_01.ogg", t = 79 / 30},
            {p = 100, s = "weapons/wingman/Weapon_Wingman_Inspect_Part4_Fr132_V1_2ch_01.ogg", t = 132 / 30},
            {p = 100, s = "weapons/wingman/Weapon_Wingman_Inspect_End_Fr160_V1_2ch_01.ogg", t = 160 / 30}
    },
    },
    ["reload"] = {
        Source = "overheat",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        LHIK = true,
        Mult = 1.5,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatFix", t = 70 / 30},
            {s = "ArcCW_Kraken.Grab", t = 60 / 30},
        },
    },
}