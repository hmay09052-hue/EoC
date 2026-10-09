AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.HasHoloHUD1 = true

SWEP.Slot = 3 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "A-287"
SWEP.Trivia_Class = "Blaster Rifle"
SWEP.Trivia_Desc = "The A280 blaster rifle was a type of blaster rifle mostly used by Rebel Alliance troopers and New Republic soldiers. There existed two variants of the A280 blaster, the A280C and the A280-CFE, both of which were favored by commandos and special force of the Rebel Alliance."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/a287.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "001000000000000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/galactic/v_a280.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_a280.mdl"
SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(0.9, 0.5, -2.9),
    ang = Angle(-10, 0, 180),
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 25
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
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
SWEP.DamageMin = 25
SWEP.RangeMin = 0
SWEP.Range = 540
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TraceNum = 1
SWEP.Tracer = "new_tracer_red"
SWEP.TracerCol = Color(250, 0, 0)

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 26

SWEP.Recoil = 0.65
SWEP.RecoilSide = 0.45
SWEP.RecoilRise = 0.75
SWEP.RecoilPunch = 1.1

SWEP.Delay = 60 / 430
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
        PostBurstDelay = 0.1,
    },
    {
		Mode = 2,
        PostBurstDelay = 0.1,
    },
    {
        Mult_RPM = 2,
		Mode = -3,
        PostBurstDelay = 0.1,
    },
	{
		Mode = 0,
   	}
}

SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 250
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 0.9
SWEP.SightedSpeedMult = 0.75
SWEP.ShootSpeedMult = 1.05

-- Sounds & Muzzleflash
SWEP.Primary.Ammo = "ar2"

SWEP.ShootVol = 125
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.05

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

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_A280_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_A280_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleFlashColor = Color(250, 0, 0)
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.GMMuzzleEffect = false

-- Ironsight & Holdtype
SWEP.IronSightStruct = {
    Pos = Vector(-2.373, -3, 0),
    Ang = Vector(0, 0.1, -3),
     Magnification = 1.5,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CrouchPos = Vector(-4, 0, 0)
SWEP.CrouchAng = Angle(0, 0, -10)

SWEP.HolsterPos = Vector(3, -3, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(20, 30.7, 10.3)

SWEP.BarrelLength = 30
-- Attachments 
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["optic_attach"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["laser_attach"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["foregrip_attach"] = {
        VMBodygroups = {{ind = 5, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "tag_attachments",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        InstalledEles = {"optic_attach"},
        Offset = {
            vpos = Vector(8.5, -0, 2),
            vang = Angle(0, 0, 0),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0)
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "stealth_muzzle"},
        VMScale = Vector(1.2, 1.2, 1.2),
        WMScale = Vector(1.2, 1.2, 1.2),
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(26, -0.1, 0.25),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        InstalledEles = {"laser_attach"},
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(13.5, 0.6, 0.5),
            vang = Angle(0, 0, -90),
        },
    },  
    {
        PrintName = "Underbarrel",
        DefaultAttName = "A-280 Foregrip",
        Slot = {"foregrip"},
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        InstalledEles = {"foregrip_attach"},
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(13.4, 0.1, -0.3),
            vang = Angle(0, 0, 0),
        },
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
            vpos = Vector(5.55, -1.0, -1.34),
            vang = Angle(0, 0, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(2.5, -0.5, 0.09),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
local path = "arccw/kraken/sw_galactic/weapons/a280/handling_2/"

SWEP.Animations = {
    ["fire"] = {
        Source = "shoot1",
    },
    ["reload"] = {
        Source = "reload_short",
        LHIK = true,
		MinProgress = 0.9,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = path .. "wfoly_plr_ar_falima_reload_start.ogg", t = 0.033},
            {s = "ArcCW_Kraken.Overheat", t = 0.67},
            {s = path .. "wfoly_plr_ar_falima_reload_magout_01.ogg", t = 0.65},
            {s = path .. "wfoly_plr_ar_falima_reload_arm.ogg", t = 0.75},
            {s = path .. "wfoly_plr_ar_falima_reload_elbow.ogg", t = 1.45},
			{s = path .. "wfoly_plr_ar_falima_reload_magin_v2_01.ogg", t = 1.5},
			{s = path .. "wfoly_plr_ar_falima_reload_magin_v2_02.ogg", t = 1.75},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 1.6},
			{s = path .. "wfoly_plr_ar_falima_reload_end.ogg", t = 2.06},
        },
    },
    ["reload_empty"] = {
        Source = "reload",
        LHIK = true,
		MinProgress = 0.9,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = path .. "wfoly_plr_ar_falima_reload_empty_start.ogg", t = 0},
            {s = path .. "wfoly_plr_ar_falima_reload_empty_rotate.ogg", t = 0.46},
            {s = path .. "wfoly_plr_ar_falima_reload_empty_magout_01.ogg", t = 0.73},
            {s = path .. "wfoly_plr_ar_falima_reload_empty_shake.ogg", t = 0.93},
            {s = path .. "wfoly_plr_ar_falima_reload_empty_arm.ogg", t = 1.63},
			{s = path .. "wfoly_plr_ar_falima_reload_empty_magin_v2_01.ogg", t = 1.83},
			{s = path .. "wfoly_plr_ar_falima_reload_empty_magin_v2_02.ogg", t = 2.1},
            {s = path .. "wfoly_plr_ar_falima_reload_empty_elbow.ogg", t = 2.2},
			{s = path .. "wfoly_plr_ar_falima_reload_empty_boltopen_01.ogg", t = 2.66},
            {s = path .. "wfoly_plr_ar_falima_reload_empty_boltclose_01.ogg", t = 2.96},
            {s = path .. "wfoly_plr_ar_falima_reload_empty_end.ogg", t = 3},
        },
    },
    ["ready"] = {
        Source = "draw_short",
        LHIK = true,
		MinProgress = 0.5,
        SoundTable = {
            {s = path .. "wfoly_plr_ar_falima_raise_start.ogg", t = 0/30},
			{s = path .. "wfoly_plr_ar_falima_raise_settle.ogg", t = 0/30},
        },
    },
    ["draw"] = {
        Source = "draw_short",
        LHIK = true,
		MinProgress = 0.5,
        SoundTable = {
            {s = path .. "wfoly_plr_ar_falima_raise_start.ogg", t = 0/30},
			{s = path .. "wfoly_plr_ar_falima_raise_settle.ogg", t = 0/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_plr_ar_falima_drop_down.ogg", t = 0/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["exit_inspect"] = {
        Source = "lookat01",
		MinProgress = 0.9,
        SoundTable = {
            {s = path .. "wfoly_ar_falima_inspect_01.ogg", t = 0},
			{s = path .. "wfoly_ar_falima_inspect_02.ogg", t = 1.3},
			{s = path .. "wfoly_ar_falima_inspect_03.ogg", t = 2.36},
			{s = path .. "wfoly_ar_falima_inspect_04.ogg", t = 3.6},
			{s = path .. "wfoly_ar_falima_inspect_05.ogg", t = 4.1},
        },
    },
    ["bash"] = {
        Source = {"melee","melee2","melee3"},
    },
    ["changefiremode"] = {
        Source = "semi_on",
        SoundTable = {
            {s = path .. "weap_ar_falima_selector_off.ogg", t = 0/30},
        },
    },
    ["enter_bipod"] = {
        Source = "bipod_in",
    },
    ["exit_bipod"] = {
        Source = "bipod_out",
    },
}
