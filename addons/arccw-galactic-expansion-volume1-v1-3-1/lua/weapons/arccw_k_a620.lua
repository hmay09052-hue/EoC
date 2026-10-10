AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.HasHoloHUD1 = true

SWEP.Slot = 3 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "A-620"
SWEP.Trivia_Class = "Blaster Carbine"
SWEP.Trivia_Desc = "The A280 blaster rifle was a type of blaster rifle mostly used by Rebel Alliance troopers and New Republic soldiers. There existed two variants of the A280 blaster, the A280C and the A280-CFE, both of which were favored by commandos and special force of the Rebel Alliance."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/a620.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0110101000000000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/galactic/v_a280c.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_a280c.mdl"
SWEP.ViewModelFOV = 65

SWEP.WorldModelOffset = {
    pos = Vector(0.9, 0.5, -2.9),
    ang = Angle(-10, 0, 180),
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 15
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

SWEP.Damage = 48
SWEP.DamageMin = 28
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
SWEP.Primary.ClipSize = 45

SWEP.Recoil = 1.15
SWEP.RecoilSide = 0.45
SWEP.RecoilRise = 0.78
SWEP.RecoilPunch = 1.1

SWEP.Delay = 60 / 320
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
SWEP.HipDispersion = 200
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
    Pos = Vector(-3.05, -4, 1.1),
    Ang = Angle(0, 0, 2.5),
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
SWEP.AttachmentElements = {
    ["optic_attach"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["laser_attach"] = {
        VMBodygroups = {{ind = 4, bg = 0}},
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
        Bone = "tag_sling",
        InstalledEles = {"optic_attach"},
        Offset = {
            vpos = Vector(4, 0, 1.5),
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
        Bone = "tag_sling",
        Offset = {
            vpos = Vector(30.5, -0.05, 0.05),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        InstalledEles = {"laser_attach"},
        Bone = "tag_sling",
        Offset = {
            vpos = Vector(13.4, 0.8, 0.3),
            vang = Angle(0, 0, -90),
        },
    },  
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "tag_sling",
        InstalledEles = {"foregrip_attach"},
        Offset = {
            vpos = Vector(13, 0.1, -0.38),
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
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Bone = "tag_sling",
        Offset = {
            vpos = Vector(6.6, -0.6, -1.3),
            vang = Angle(0, 0, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        Bone = "tag_sling",
        Offset = {
            vpos = Vector(2.5, -0.6, 0),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
local path = "arccw/kraken/sw_galactic/weapons/a280/handling/"

SWEP.Animations = {
    ["fire"] = {
        Source = "shoot1",
		IKTimeLine = { { t = 0,  lhik = 1, rhik = 1} },
    },
    ["reload"] = {
        Source = "reload_short",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
		MinProgress = 0.9,
        SoundTable = {
			{s = path .. "wpfoly_mike4_reload_lift_v2.ogg", t = 0.1/30},
            {s = "ArcCW_Kraken.Overheat", t = 19/30},
			{s = path .. "wpfoly_mike4_reload_magout_v2.ogg", t = 18/30},
			{s = path .. "wpfoly_mike4_reload_magin_01.ogg", t = 28/30},
			{s = path .. "wpfoly_mike4_reload_magin_v2.ogg", t = 31/30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 32/30},
			{s = path .. "wpfoly_mike4_reload_end_v2.ogg", t = 52/30},
        },
    },
    ["reload_empty"] = {
        Source = "reload",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
		MinProgress = 0.9,
        SoundTable = {
			{s = path .. "wpfoly_mike4_reload_empty_lift_v2.ogg", t = 0.1/30},
			{s = path .. "wpfoly_mike4_reload_empty_magout_v2.ogg", t = 5/30},
            {s = "ArcCW_Kraken.Overheat", t = 6/30},
			{s = path .. "wpfoly_mike4_reload_empty_magin_v2.ogg", t = 31/30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 32/30},
			{s = path .. "wpfoly_mike4_reload_empty_chamber_v2.ogg", t = 53/30},
			{s = path .. "wpfoly_mike4_reload_empty_end_v2.ogg", t = 63/30},
        },
    },
    ["ready"] = {
        Source = "draw",
		MinProgress = 0.6,
        SoundTable = {
            {s = path .. "wpfoly_mike4_raise_first_01.ogg", t = 0.2},
            {s = path .. "wpfoly_mike4_raise_first_02.ogg", t = 0.85},
            {s = path .. "wpfoly_mike4_raise_first_03.ogg", t = 1.3},
        },
    },
    ["draw"] = {
        Source = "draw_short",
		MinProgress = 0.5,
        SoundTable = {
            {s = path .. "wpfoly_mike4_raise_v2.ogg", t = 0.1/30},
        },
    },
    ["holster"] = {
        Source = "holster",
		--Mult = 0.8,
        SoundTable = {
            {s = path .. "wpfoly_mike4_drop_v2.ogg", t = 0.1/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["inspect"] = {
        Source = "lookat01",
        LHIK = true,
		MinProgress = 0.9,
        SoundTable = {
            {s = path .. "wfoly_ar_mike4_inspect_01.ogg", t = 0},
			{s = path .. "wfoly_ar_mike4_inspect_02.ogg", t = 1.3},
			{s = path .. "wfoly_ar_mike4_inspect_03.ogg", t = 2.36},
			{s = path .. "wfoly_ar_mike4_inspect_04.ogg", t = 3.6},
			{s = path .. "wfoly_ar_mike4_inspect_05.ogg", t = 4.2},
        },
    },
    ["bash"] = {
        Source = {"melee", "melee2", "melee3"},
    },
    ["changefiremode"] = {
        Source = "semi_on",
        SoundTable = {
            {s = path .. "weap_m4_selector_semi_on_03.ogg", t = 0.1/30},
        },
    },
    ["fix"] = {
        Source = "unjam",
        MinProgress = 0.4,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        FireASAP = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 5/30},
			{s = path .. "wpfoly_mike4_reload_empty_lift_v2.ogg", t = 5/30},
            {s = path .. "wpfoly_mike4_jam_bolt.ogg", t = 10/30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 34/30},
			{s = path .. "wpfoly_mike4_reload_empty_chamber_v2.ogg", t = 25/30},
			{s = path .. "wpfoly_mike4_reload_empty_end_v2.ogg", t = 34/30},
        },
    },
    ["enter_bipod"] = {
        Source = "bipod_in",
    },
    ["exit_bipod"] = {
        Source = "bipod_out",
    },
}