AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 4 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "'Roba' M-45c"
SWEP.Trivia_Class = "Repeating Ion Blaster"
SWEP.Trivia_Desc = "The 'Roba' M-45 repeating ion blaster, manufactured by BlasTech Industries, was a heavy repeating ion blaster that saw use during the Galactic Civil War, typically pintel-mounted on UT-60D U-wing gunships."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/m45c.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000000012000000000000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/galactic/v_m45.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_m45.mdl"
SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-9, 3.5, -5),
    ang = Angle(-10, -90, 180),
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 45
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.5
SWEP.HeatFix = true

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 42
SWEP.DamageMin = 24
SWEP.RangeMin = 0
SWEP.Range = 450
SWEP.Penetration = 8
SWEP.DamageType = DMG_BLAST
SWEP.MuzzleVelocity = 9000

SWEP.HasHoloHUD1 = true

SWEP.TraceNum = 1
SWEP.Tracer = "new_tracer_red"
SWEP.TracerCol = Color(250, 0, 0)

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 100

SWEP.Recoil = 0.75
SWEP.RecoilSide = 0.35
SWEP.RecoilRise = 0.65
SWEP.RecoilPunch = 1

SWEP.Delay = 60 / 666
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
SWEP.HipDispersion = 350
SWEP.MoveDispersion = 200
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 1.10
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

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_FMWB_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_FMWB_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.BulletBones = {
    [17] = "j_b_01",
    [16] = "j_b_02",
	[15] = "j_b_03",
	[14] = "j_b_04",
	[13] = "j_b_05",
	[12] = "j_b_06",
	[11] = "j_b_07",
	[10] = "j_b_08",
	[9] = "j_b_09",
	[8] = "j_b_10",
	[7] = "j_b_11",
	[6] = "j_b_12",
	[5] = "j_b_13",
	[4] = "j_b_14",
	[3] = "j_b_15",
	[2] = "j_b_16",
	[1] = "j_b_17",
}

SWEP.MuzzleFlashColor = Color(250, 0, 0)
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.GMMuzzleEffect = false

-- Ironsight & Holdtype
SWEP.IronSightStruct = {
    Pos = Vector(-4.07, -3, 0.7),
    Ang = Angle(-0.2, 0, -1.5),
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

SWEP.ActivePos = Vector(-2, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(0, 0, 1.5)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CrouchPos = Vector(-4, 0, -1)
SWEP.CrouchAng = Angle(0, 0, -10)

SWEP.HolsterPos = Vector(3, 3, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(20, 30.7, 10.3)
SWEP.BarrelLength = 35
-- Attachments 
SWEP.AttachmentElements = {
    ["grip_attach"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["laser_attach"] = {
        VMBodygroups = {{ind = 6, bg = 1}},
    },
    ["scope_attach"] = {
        VMBodygroups = {{ind = 8, bg = 0}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "tag_attachments",
        InstalledEles = {"scope_attach"},
        Offset = {
            vpos = Vector(8, 0, 2.5),
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
            vpos = Vector(44.3, 0, 0.5),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        InstalledEles = {"laser_attach"},
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(21.1, 0.6, -0.9),
            vang = Angle(0, 0, -90),
        },
    },  
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "tag_attachments",
        InstalledEles = {"grip_attach"},
        Offset = {
            vpos = Vector(16, 0, -1.8),
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
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(6.5, -0.39, 0.85),
            vang = Angle(0, 0, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(10.4, -0.7, -0.5),
            vang = Angle(0, 0, 30),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
local path = "arccw/kraken/sw_galactic/weapons/m45/handling/"

SWEP.Animations = {
    ["fire"] = {
        Source = "shoot1",
    },
    ["fire_iron"] = {
        Source = false,
    },
    ["ready"] = {
        Source = "draw",
		MinProgress = 0.7,
        SoundTable = {
            {s = path .. "wfoly_lm_kilo121_raise_first_raise.ogg", t = 0.1/30},
            {s = path .. "wfoly_lm_kilo121_raise_first_raise_01.ogg", t = 0.1/30},
			{s = path .. "wfoly_lm_kilo121_raise_first_drop.ogg", t = 11/30},
			{s = path .. "wfoly_lm_kilo121_raise_first_rattle.ogg", t = 22/30},
			{s = path .. "wfoly_lm_kilo121_reload_boltopen_01.ogg", t = 30/30},
			{s = path .. "wfoly_lm_kilo121_reload_boltclose_01.ogg", t = 43/30},
			{s = path .. "wfoly_lm_kilo121_raise_first_cloth01.ogg", t = 51/30},
			{s = path .. "wfoly_lm_kilo121_raise_first_end.ogg", t = 59/30},
        },
    },
    ["draw"] = {
        Source = "draw_short",
		MinProgress = 0.5,
        SoundTable = {
            {s = path .. "wfoly_lm_kilo121_raise.ogg", t = 0.1/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = path .. "wfoly_lm_kilo121_reload_empty_end.ogg", t = 0.1/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["idle_sprint"] = {
        Source = "sprint",
    },
    ["exit_sprint"] = {
        Source = "sprint_out",
		Time = 1.25,
    },
    ["enter_sprint"] = {
        Source = "sprint_in",
		IKTimeLine = { { t = 0,  lhik = 1, rhik = 1} },
		Time = 1.25,
    },
    ["bash"] = {
        Source = {"melee","melee2","melee3"},
    },
    ["fix"] = {
        Source = "jam",
        Mult = 2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 0.1/30},
            {s = "ArcCW_Kraken.OverheatFix", t = 35/30},
            {s = "ArcCW_Kraken.Grab", t = 36 / 30},
        },
    },
    ["reload"] = {
        Source = "reload_short",
		MinProgress = 0.95,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
			{s = path .. "wfoly_lm_kilo121_reload_raise.ogg", t = 0.1/30},
			{s = path .. "wfoly_lm_kilo121_reload_boltopen_01.ogg", t = 23/30},
            {s = "ArcCW_Kraken.Overheat", t = 23/30},
			{s = path .. "wfoly_lm_kilo121_reload_boltclose_01.ogg", t = 37/30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 37/30},
			{s = path .. "wfoly_lm_kilo121_reload_lower.ogg", t = 44/30},
			{s = path .. "wfoly_lm_kilo121_reload_coveropen_01.ogg", t = 65/30},
			{s = path .. "wfoly_lm_kilo121_reload_magout_01.ogg", t = 86/30},
			{s = path .. "wfoly_lm_kilo121_reload_boxmag.ogg", t = 110/30},
			{s = path .. "wfoly_lm_kilo121_reload_magin_01.ogg", t = 128/30},
			{s = path .. "wfoly_lm_kilo121_reload_click_01.ogg", t = 151/30},
            {s = "ArcCW_Kraken.OverheatFix", t = 180/30},
			{s = path .. "wfoly_lm_kilo121_reload_coverclose_01.ogg", t = 174/30},
			{s = path .. "wfoly_lm_kilo121_reload_end.ogg", t = 201/30},
        },
    },
    ["reload_empty"] = {
        Source = "reload",
		MinProgress = 0.9,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
			{s = path .. "wfoly_lm_kilo121_reload_empty_lift.ogg", t = 0.1/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_boltopen_01.ogg", t = 23/30},
            {s = "ArcCW_Kraken.Overheat", t = 23/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_boltclose_01.ogg", t = 37/30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 37/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_lower.ogg", t = 44/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_coveropen_01.ogg", t = 65/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_clean.ogg", t = 83/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_inspect.ogg", t = 106/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_magout_01.ogg", t = 114/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_raise_01.ogg", t = 126/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_boxmag.ogg", t = 142/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_magin_01.ogg", t = 155/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_beltmvmnt.ogg", t = 164/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_click_01.ogg", t = 176/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_mvmnt01.ogg", t = 193/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_coverclose_01.ogg", t = 201/30},
            {s = "ArcCW_Kraken.OverheatFix", t = 210/30},
			{s = path .. "wfoly_lm_kilo121_reload_empty_end.ogg", t = 223/30},
        },
    },
    ["exit_inspect"] = {
        Source = "lookat01",
		MinProgress = 0.9,
        SoundTable = {
            {s = path .. "wfoly_lm_kilo121_inspect_01.ogg", t = 0/30},
			{s = path .. "wfoly_lm_kilo121_inspect_02.ogg", t = 55/30},
			{s = path .. "wfoly_lm_kilo121_inspect_03.ogg", t = 113/30},
        },
    },
    ["enter_bipod"] = {
        Source = "bipod_in",
    },
    ["exit_bipod"] = {
        Source = "bipod_out",
    },
}
