AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.HasHoloHUD1 = true

SWEP.Slot = 4 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DLT-19h"
SWEP.Trivia_Class = "Prototype Heavy Rifle"
SWEP.Trivia_Desc = "Before the DLT-19, the DLT-16 existed as a prototype of a Heavy Rifle for Infantry usage. This weapon, like many others, continued to use bullet casings, however, it had a special system that when they were hammered, the explosion of the tibanna gas was compressed and transformed into a blaster projectile. The DLT-19 heavy blaster rifle was a model of heavy blaster rifle manufactured by BlasTech Industries. They were used by regular stormtroopers and Heavy Weapons Stormtroopers of the Galactic Empire, but they also saw use by other parties, including the Alliance to Restore the Republic and certain bounty hunters."
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.IconOverride = "entities/kraken/galactic/dlt19h.png"

-- Base
SWEP.DefaultBodygroups = "010010000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/galactic/v_dlt19.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_dlt19.mdl"

SWEP.ViewModelFOV = 65

SWEP.WorldModelOffset = {
    pos = Vector(-1, 1, -2.4),
    ang = Angle(-5, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 75
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

SWEP.Damage = 44
SWEP.DamageMin = 29
SWEP.RangeMin = 0
SWEP.Range = 400
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
SWEP.Primary.ClipSize = 150

SWEP.Recoil = 0.79
SWEP.RecoilSide = 0.34
SWEP.RecoilRise = 0.98
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1
SWEP.RecoilVMShake = 2

SWEP.Delay = 60 / 600
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
        Mode = -3,
        PostBurstDelay = 0.1,
        RunawayBurst = false,
        Mult_RPM = 2,
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

SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 250
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200

-- Speed Mult
SWEP.SpeedMult = 0.86
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_DLT19_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_DLT19_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.65, -2, 0.6),
    Ang = Angle(1.8, 0.3 , 4.25),
     Magnification = 1.5,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "shotgun"
SWEP.HoldtypeSights = "ar2"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(-2, 2, -0.5)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(8, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.CrouchPos = Vector(-3, 0, 2)
SWEP.CrouchAng = Angle(0, 0, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.HolsterPos = Vector(4, -3, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)
SWEP.BarrelLength = 40
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["muzzle_attach"] = {
        VMBodygroups = {{ind = 3, bg = 3}},
    },
    ["laser_attach"] = {
        VMBodygroups = {{ind = 6, bg = 1}},
    },
    ["grip_attach"] = {
        VMBodygroups = {{ind = 5, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Sight", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "j_lever",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(2.5, -0.5, -0),
            vang = Angle(180, 0, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        Bone = "tag_attachments",
        InstalledEles = {"muzzle_attach"},
        Offset = {
            vpos = Vector(36, -0.05, 0),
            vang = Angle(0, 0, 0),
        },
    },  
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "tag_attachments",
        InstalledEles = {"laser_attach"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(27, 1, 0),
            vang = Angle(0, 0, -90),
        },
    },
    {
        PrintName = "Foregrip", 
        DefaultAttName = "None",
        Slot = "foregrip",
        Bone = "tag_attachments",
        InstalledEles = {"grip_attach"},
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(15.8, 0, -0.8),
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
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(0.2, 0.1, -2.3),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(0.45, -0.65, -2.5),
            vang = Angle(90, 0, -90),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
local path = "arccw/kraken/sw_galactic/weapons/dlt19/handling/"

SWEP.Animations = {
    ["fire"] = {
        Source = "shoot1",
		IKTimeLine = { { t = 0,  lhik = 1, rhik = 1} },
    },
    ["reload"] = {
        Source = "jam_fix",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, 
        SoundTable = {
			{s = path .. "wfoly_plr_lm_mgolf34_reload_empty_start.ogg", t = 0.1/30},
            {s = "ArcCW_Kraken.Overheat", t = 12/30},
			{s = path .. "wfoly_plr_lm_mgolf34_reload_empty_boltopen_01.ogg", t = 12/30},
			{s = path .. "wfoly_plr_lm_mgolf34_reload_empty_boltclose_01.ogg", t = 24/30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 24/30},
            {s = path .. "wfoly_plr_lm_mgolf34_reload_fast_end.ogg", t = 24/30},
        },
    },
    ["ready"] = {
        Source = "draw",
        LHIK = true,
		MinProgress = 0.7,
        SoundTable = {
            {s = path .. "wfoly_plr_lm_mgolf34_raise_first_pull.ogg", t = 0.1/30},
            {s = path .. "wfoly_plr_lm_mgolf34_raise_first_start.ogg", t = 6/30},
			{s = path .. "wfoly_plr_lm_mgolf34_raise_first_boltopen_01.ogg", t = 31/30},
			{s = path .. "wfoly_plr_lm_mgolf34_raise_first_boltclose_01.ogg", t = 40/30},
			{s = path .. "wfoly_plr_lm_mgolf34_raise_first_end.ogg", t = 56/30},
        },
    },
    ["draw"] = {
        Source = "draw_short",
        LHIK = true,
		MinProgress = 0.5,
        SoundTable = {
            {s = path .. "wfoly_plr_lm_mgolf34_raise_up.ogg", t = 10/30},
            {s = path .. "wfoly_plr_lm_mgolf34_raise_settle.ogg", t = 34/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_plr_lm_mgolf34_reload_raise.ogg", t = 0.1/30},
            {s = path .. "wfoly_plr_lm_mgolf34_reload_open.ogg", t = 10/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["exit_inspect"] = {
        Source = "lookat01",
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_lm_mgolf34_inspect_01.ogg", t = 0.1/30},
			{s = path .. "wfoly_lm_mgolf34_inspect_02.ogg", t = 54/30},
			{s = path .. "wfoly_lm_mgolf34_inspect_03.ogg", t = 120/30},
        },
    },
    ["bash"] = {
        LHIK = true,
        Source = {"melee","melee2","melee3"},
    },
    ["fix"] = {
        Mult = 2,
        LHIK = true,
        Source = "jam",
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 0.1/30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 10/30},
            {s = "ArcCW_Kraken.Grab", t = 11 / 30},
        },
    },
    ["enter_bipod"] = {
        Source = "bipod_in",
    },
    ["exit_bipod"] = {
        Source = "bipod_out",
    },
}
