AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. II"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "EE-9"
SWEP.Trivia_Class = "Blaster Lever Action Shotgun"
SWEP.Trivia_Desc = "Blaster Lever Action Shotgun designed originally for military purposes, now modernized and being used by many Bounty Hunters, Civillians and even Mercenaries or Military Corporations in the galaxy. This weapon can switch between Scatter and Carbine mode."
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/galexpansion_vol2/ee9.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/galexpansion_vol2/v_ee9.mdl"
SWEP.WorldModel = "models/arccw/kraken/galexpansion_vol2/worldmodel/w_ee9.mdl"

SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-2, 5, -4),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 16
SWEP.DamageMin = 9
SWEP.RangeMin = 0
SWEP.Range = 120
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.Primary.ClipSize = 5
SWEP.MaxRecoilBlowback = 1.5

SWEP.Recoil = 2.5
SWEP.RecoilSide = 1
SWEP.RecoilRise = 1.5
SWEP.RecoilPunch = 2
SWEP.RecoilVMShake = 3
SWEP.VisualRecoilMult = 1

SWEP.ManualAction = true
SWEP.NoLastCycle = true -- do not cycle on last shot

SWEP.Delay = 60 / 100
SWEP.Num = 11
SWEP.Firemodes = {
    {
        Mode = 1,
    },
    {
        Mode = 0,
    }
}

SWEP.ShotgunSpreadPattern = {
    [1] = Angle(1, 0, 0),
    [2] = Angle(2, 0, 0),

    [3] = Angle(0.5, 0.866, 0), -- cos(60), sin(60)
    [4] = Angle(1, 1.732, 0),

    [5] = Angle(0.5, -0.866, 0), -- cos(300), sin(300)
    [6] = Angle(1, -1.732, 0),

    [7] = Angle(-0.766, 0.643, 0), -- cos(140), sin(140)
    [8] = Angle(-1.532, 1.287, 0),

    [9] = Angle(-0.766, -0.643, 0), -- cos(220), sin(220)
    [10] = Angle(-1.532, -1.287, 0),

    [11] = Angle(0, 0, 0),
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

SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 50
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 0.955
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 90
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_EE9_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_EE9_Distant"
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
    Pos = Vector(-4.533, 0, 0),
    Ang = Vector(1.84, 1.347, -5),
    Magnification = 1.15,
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

SWEP.CustomizePos = Vector(0,0,0)
SWEP.CustomizeAng = Angle(0,0,0)

SWEP.CrouchPos = Vector(-3, 0, 3)
SWEP.CrouchAng = Angle(0, 0, 0)

SWEP.ActivePos = Vector(-3, 0, 0)
SWEP.ActiveAng = Angle(0, 0, -8)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 25
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {}

SWEP.Attachments = {     
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        Bone = "def_c_parts",
        VMScale = Vector(1.1, 1.1, 1.1),
        WMScale = Vector(1.1, 1.1, 1.1),
        Offset = {
            vpos = Vector(-0.08, -1.05, 18),
            vang = Angle(90, 0, -90),
        },
    },  
    {
        PrintName = "Foregrip",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Bone = "def_c_parts",
        Offset = {
            vpos = Vector(0.0, 1.4, 7),
            vang = Angle(90, 0, -90),
        },
    },  
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "def_c_parts",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(-1, -0.2, 13),
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
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Bone = "def_c_parts",
        Offset = {
            vpos = Vector(1.22, 0.9, -2.1),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Bone = "def_c_parts",
        Offset = {
            vpos = Vector(1.3, 0.9, -4.2),
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
    ["ready"] = {
        Source = "draw_first",
        SoundTable = {
            -- {p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_LeverOut_2ch_v1_01.ogg", t = 7 / 30},
            -- {p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_LeverIn_2ch_v2_01.ogg", t = 16 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt5_2ch_v1.ogg", t = 1 / 30},
        },
    },
    ["draw"] = {
        Source = "draw",
        Mult = 1,
    },
    ["holster"] = {
        Source = "holster",
        Mult = 1,
    },
    ["fire"] = {
        Source = "fire",
        -- Time = 9 / 10,
        MinProgress = 0.4,
    },
    ["cycle"] = {
        Source = "rechamber",
        MinProgress = 0.875,
        SoundTable = {
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_LeverOut_2ch_v1_01.ogg", t = 7 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_LeverIn_2ch_v2_01.ogg", t = 16 / 30},
        },
    },
    ["cycle_iron"] = {
        Source = "rechamber",
        MinProgress = 0.875,
        SoundTable = {
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_LeverOut_2ch_v1_02.ogg", t = 3 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_LeverIn_2ch_v2_02.ogg", t = 15 / 30},
        },
    },
    ["enter_inspect"] = {
        Source = "inspect_in",
    },
    ["exit_inspect"] = {
        Source = "inspect_out",
        SoundTable = {
            {p = 100, s = "weapons/foley/Weapon_Inspect_Foley_Shotgun_End_V1_2ch_01.wav", t = 0 / 30},
    },
    },
    ["idle_inspect"] = {
        Source = "inspect",
        SoundTable = {
            {p = 100, s = "weapons/foley/Weapon_Inspect_Foley_Shotgun_Start_V1_2ch_01.wav", t = 1 / 30},
            {p = 100, s = "weapons/foley/Weapon_Inspect_Foley_Shotgun_Mid_V1_2ch_01.wav", t = 96 / 30},
            {p = 100, s = "weapons/foley/Weapon_Inspect_Foley_Shotgun_Mid_V1_2ch_02.wav", t = 240 / 30},
            {p = 100, s = "weapons/foley/Weapon_Inspect_Foley_Shotgun_End_V1_2ch_01.wav", t = 316 / 30}
    },
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt1_2ch_v1.ogg", t = 5 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_EnergyCrackle_2ch_v1.ogg", t = 10 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt2_2ch_v1.ogg", t = 25 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt3_2ch_v1.ogg", t = 39 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt4_2ch_v1.ogg", t = 55 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt6_2ch_v1.ogg", t = 64 / 30}
        },
    },
    ["reload_empty"] = {
        Source = "reload_empty",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt1_2ch_v1.ogg", t = 5 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_EnergyCrackle_2ch_v1.ogg", t = 10 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt2_2ch_v1.ogg", t = 25 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt3_2ch_v1.ogg", t = 39 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt4_2ch_v1.ogg", t = 58 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt5_2ch_v1.ogg", t = 72 / 30},
            {v = 0.5, p = 100, s = "weapons/peacekeeper/Wpn_Peacekeeper_Reload_1p_Pt6_2ch_v1.ogg", t = 87 / 30}
    },
},
}