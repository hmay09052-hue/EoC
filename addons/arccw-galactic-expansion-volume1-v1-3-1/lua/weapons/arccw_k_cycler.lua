AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.HasHoloHUD1 = true
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 4 -- Change this if you want to select the weapon with other number

SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Cycler"
SWEP.Trivia_Class = "Double-Barrel Sniper"
SWEP.Trivia_Desc = "Cycler rifles were crude yet reliable slugthrower rifles designed to fire solid projectiles. They could hit targets at extreme ranges and penetrate energy shields. Used primarily by primitive cultures and hunters, they were strong enough to tear whole limbs from a body."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/cycler.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0101000000000000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/galactic/v_cycler.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_cycler.mdl"
SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-1, 0.6, -3),
    ang = Angle(-5, 0, 180),
    scale = 1,
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

SWEP.Damage = 190
SWEP.DamageMin = 95
SWEP.RangeMin = 0
SWEP.Range = 700
SWEP.Penetration = 8
SWEP.DamageType = DMG_BUCKSHOT
SWEP.MuzzleVelocity = 9000

SWEP.TraceNum = 1
SWEP.Tracer = "new_tracer_orange"
SWEP.TracerCol = Color(250, 242, 0)

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 2

SWEP.Recoil = 3
SWEP.RecoilSide = 1.5
SWEP.RecoilRise = 2
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1.5
SWEP.RecoilVMShake = 2

SWEP.Delay = 60 / 120
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
        PostBurstDelay = 0.1,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 100
SWEP.MoveDispersion = 75
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 0.85
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.30

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"

SWEP.ShootVol = 100
SWEP.ShootPitch = 100

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_TUSKENCYCLER_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_TUSKENCYCLER_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleFlashColor = Color(250, 242, 0)
SWEP.MuzzleEffect = "blaster_muzzle_orange"
SWEP.GMMuzzleEffect = false

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.05, -0, 0.1),
    Ang = Vector(0.5, 0, -3),
     Magnification = 1.5,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(-1, 2, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, 0)
SWEP.SprintAng = Angle(5, 0, 0)

SWEP.CrouchPos = Vector(-4, 0, -1)
SWEP.CrouchAng = Angle(0, 0, -10)

SWEP.HolsterPos = Vector(3, 3, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(20, 30.7, 10.3)

SWEP.GuaranteeLaser = true
SWEP.BarrelLength = 45
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["scope_attach"] = {
        VMBodygroups = {{ind = 3, bg = 0}, {ind = 5, bg = 1}},
    },
    ["grip_attach"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "tag_scope",
        InstalledEles = {"scope_attach"},
        Offset = {
            vpos = Vector(4, 0, -0.1),
            vang = Angle(0, 0, 0),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0)
    },
    {
        PrintName = "Internal Compression",
        DefaultAttName = "None",
        Slot = {"muzzle", "stealth_muzzle"},
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "tag_scope",
        Offset = {
            vpos = Vector(18, 0.4, -0.6),
            vang = Angle(0, 0, -90),
        },
    },  
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Bone = "tag_rail",
        InstalledEles = {"grip_attach"},
        Offset = {
            vpos = Vector(0, 0, -2.8),
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
        Bone = "tag_rail",
        Offset = {
            vpos = Vector(-3.4, -0.8, -1.1),
            vang = Angle(0, 0, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        Bone = "tag_rail",
        Offset = {
            vpos = Vector(0.8, -0.6, -1.1),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Animations
local path = "arccw/kraken/sw_galactic/weapons/tuskencyclerrifle/handling/"

SWEP.Animations = {
    ["fire"] = {
        Source = "shoot1",
		IKTimeLine = { { t = 0,  lhik = 1, rhik = 1} },
    },
    ["fire_sight"] = {
        Source = "shoot1_scope",
		IKTimeLine = { { t = 0,  lhik = 1, rhik = 1} },
    },
    ["reload"] = {
        Source = "reload_short",
		MinProgress = 0.8,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        LHIK = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 0.25},
			{s = path .. "wfoly_plr_sh_charlie725_reload_start.ogg", t = 0.0},
			{s = path .. "wfoly_plr_sh_charlie725_reload_open_01.ogg", t = 0.2},
            {s = path .. "wfoly_plr_sh_charlie725_reload_swing.ogg", t = 0.567},
			{s = path .. "wfoly_plr_sh_charlie725_reload_shellin_01.ogg", t = 1.267},
			{s = path .. "wfoly_plr_sh_charlie725_reload_close_01.ogg", t = 1.733},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 1.74},
			{s = path .. "wfoly_plr_sh_charlie725_reload_end.ogg", t = 2.2},
        },
    },
    ["reload_empty"] = {
        Source = "reload",
		MinProgress = 0.8,
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 0.25},
			{s = path .. "wfoly_plr_sh_charlie725_reload_empty_start.ogg", t = 0.0},
			{s = path .. "wfoly_plr_sh_charlie725_reload_empty_open_01.ogg", t = 0.2},
            {s = path .. "wfoly_plr_sh_charlie725_reload_empty_swing.ogg", t = 0.7},
			{s = path .. "wfoly_plr_sh_charlie725_reload_empty_shellsin_v2_01.ogg", t = 1.167},
			{s = path .. "wfoly_plr_sh_charlie725_reload_empty_shellsin_v2_02.ogg", t = 1.5},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 2.05},
			{s = path .. "wfoly_plr_sh_charlie725_reload_empty_close_01.ogg", t = 2.0},
			{s = path .. "wfoly_plr_sh_charlie725_reload_empty_end.ogg", t = 2.333},
        },
    },
    ["ready"] = {
        Source = "draw",
		MinProgress = 0.8,
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_plr_sh_charlie725_raise_first_start.ogg", t = 0.1},
			{s = path .. "wfoly_plr_sh_charlie725_raise_first_close_01.ogg", t = 0.25},
			{s = path .. "wfoly_plr_sh_charlie725_raise_first_end.ogg", t = 0.633},
        },
    },
    ["draw"] = {
        Source = "draw_short",
		MinProgress = 0.3,
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_plr_sh_charlie725_raise_up.ogg", t = 0/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_plr_sh_charlie725_drop_down.ogg", t = 0/30},
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
    ["exit_inspect"] = {
        Source = "lookat01",
		MinProgress = 0.9,
        SoundTable = {
            {s = path .. "wfoly_sh_charlie725_inspect_01.ogg", t = 0.033},
			{s = path .. "wfoly_sh_charlie725_inspect_02.ogg", t = 1.5},
			{s = path .. "wfoly_sh_charlie725_inspect_03.ogg", t = 2.5},
			{s = path .. "wfoly_sh_charlie725_inspect_04.ogg", t = 3.667},
			{s = path .. "wfoly_sh_charlie725_inspect_05.ogg", t = 4.367},
        },
    },
    ["bash"] = {
        Source = {"melee","melee2","melee3"},
        LHIK = true,
    },
    ["changefiremode"] = {
        Source = "firemode",
        SoundTable = {
            {s = path .. "weap_charlie725_fire_first_plr_01.ogg", t = 0/30},
        },
    },
    ["enter_bipod"] = {
        Source = "bipod_in",
    },
    ["exit_bipod"] = {
        Source = "bipod_out",
    },
}