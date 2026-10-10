AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.HasHoloHUD1 = true

SWEP.Slot = 3 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "EE-3k"
SWEP.Trivia_Class = "Blaster Short-Range Carabine"
SWEP.Trivia_Desc = "Blaster Long-Range Carabine designed originally for military purposes, now modernized and being used by many Bounty Hunters, Civillians and even Mercenaries or Military Corporations in the galaxy."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/ee3k.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00100000000000"

SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/galactic/v_ee3r.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_ee3.mdl"

SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(1, 0.8, 0),
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

SWEP.Damage = 47
SWEP.DamageMin = 20
SWEP.RangeMin = 0
SWEP.Range = 500
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 20

SWEP.Recoil = 1
SWEP.RecoilSide = 0.4
SWEP.RecoilRise = 0.65

SWEP.Delay = 60 / 180
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
        Mode = -3,
        Mult_RPM = 4,
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
SWEP.ShootPitch = 90
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_EE3VARIANT_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_EE3_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.45, 5, -0.115),
    Ang = Vector(0, 0, -3),
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

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.InBipodPos = Vector(-8, 0, -4)
SWEP.InBipodMult = Vector(2, 0, 1)
SWEP.BarrelLength = 30
-- Attachments
SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "Iron Sight",
        Slot = "optic",
        Bone = "tag_sling",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(8.2, -0.05, 3.2),
            vang = Angle(0, 0, 0),
        },
        CorrectiveAng = Angle(0, 0, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "tag_sling",
        Offset = {
            vpos = Vector(20, 0.7, 1.5),
            vang = Angle(0, 0, -90),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "tag_sling",
        Offset = {
            vpos = Vector(26.6, -0.1, 1.65),
            vang = Angle(0, 0, 0),
        },
    },  
    {
        PrintName = "Foregrip", 
        DefaultAttName = "None",
        Slot = "foregrip",
        Bone = "tag_sling",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(14, -0.1, 0.9),
            vang = Angle(0, -0, 0),
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
        Bone = "tag_sling",
        Offset = {
            vpos = Vector(8.5, -0.62, 0.1),
            vang = Angle(0, 0, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "tag_sling",
        Offset = {
            vpos = Vector(14, -1.15, 1.8),
            vang = Angle(0, 0, 0),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
local path = "arccw/kraken/sw_galactic/weapons/ee3r/handling/"

SWEP.Animations = {
    ["fire"] = {
        Source = "shoot1",
    },
    ["dryfire"] = {
        Source = "dryfire",
		MinProgress = 0.01,
    },
    ["reload"] = {
        Source = "reload_xmag",
		MinProgress = 0.8,
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_sn_mike14_reload_mvmnt.ogg", t = 0/30},
            {s = path .. "wfoly_sn_mike14_reload_magout.ogg", t = 4/30},
			{s = path .. "wfoly_sn_mike14_reload_arm.ogg", t = 25/30},
			{s = path .. "wfoly_sn_mike14_reload_magin_v2_01.ogg", t = 32/30},
			{s = path .. "wfoly_sn_mike14_reload_magin_v2_02.ogg", t = 38/30},
			{s = path .. "wfoly_sn_mike14_reload_end.ogg", t = 38/30},
        },
    },
    ["ready"] = {
        Source = "draw_short",
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_sn_mike14_raise.ogg", t = 0/30},
        },
    },
    ["draw"] = {
        Source = "draw_short",
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_sn_mike14_raise.ogg", t = 0/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_sn_mike14_drop.ogg", t = 0/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["exit_inspect"] = {
        Source = "lookat01",
		MinProgress = 0.9,
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_sn_mike14_inspect_01.ogg", t = 0.0},
            {s = path .. "wfoly_sn_mike14_inspect_02.ogg", t = 1.367},
            {s = path .. "wfoly_sn_mike14_inspect_03.ogg", t = 2.333},
			{s = path .. "wfoly_sn_mike14_inspect_04.ogg", t = 4.2},
        },
    },
    ["bash"] = {
        Source = {"melee","melee2","melee3"},
        LHIK = true,
    },
    ["enter_bipod"] = {
        Source = "bipod_in",
    },
    ["exit_bipod"] = {
        Source = "bipod_out",
    },
}