AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true

SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Explosives - Rocket Launchers"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Republic RPS-6"
SWEP.Trivia_Class = "Rocket Launcher"
SWEP.Trivia_Desc = "The RPS-6 rocket launcher, also known as the Sienar shoulder-launched missile, was a model of missile launcher manufactured by Merr-Sonn Munitions, Inc. and Sienar Fleet Systems."
SWEP.Trivia_Manufacturer = "Sienar Fleet Systems, Merr-Sonn Munitions Inc"
SWEP.Trivia_Calibre = "Rocket"

SWEP.DefaultBodygroups = "0000000000000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_rps6_republic.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_rps6_republic.mdl"

SWEP.ViewModelFOV = 60

SWEP.WorldModelOffset = {
    pos = Vector(-15, 0, 49),
    ang = Angle(0, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
}

SWEP.HasHoloHUD = true

SWEP.ShootEntity = "arccw_rocket_rps"
SWEP.MuzzleVelocity = 6000

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 1

SWEP.Recoil = 4
SWEP.RecoilSide = 4
SWEP.RecoilRise = 4
SWEP.RecoilPunch = 5
SWEP.RecoilVMShake = 4
SWEP.VisualRecoilMult = 4

SWEP.Delay = 60 / 60
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
}

SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 500

SWEP.SpeedMult = 0.725
SWEP.SightedSpeedMult = 0.70
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.70

SWEP.Primary.Ammo = "RPG_Round"
SWEP.ShootVol = 120
SWEP.ShootPitch = 95
SWEP.ShootPitchVariation = 0.2

SWEP.FirstShootSound = "kraken/launchers/rps/weap_rpapa7_fire_plr_01.ogg"
SWEP.ShootSound = "kraken/launchers/rps/weap_rpapa7_fire_plr_01.ogg"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "muzzleflash_m79"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 137, 0)

SWEP.IronSightStruct = {
    Pos = Vector(-0, -40, 0),
    Ang = Vector(0, 0, 0),
    Magnification = 8,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
    ViewModelFOV = 55,
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "rpg"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(16, 0, -5)

SWEP.SprintPos = Vector(4.019, -5.226, -2)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CrouchPos = Vector(-4.5, -7, -3)
SWEP.CrouchAng = Angle(0, 0, -29)

SWEP.CustomizePos = Vector(10, 0, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.Attachments = {
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Bone = "tag_launcher_offset",
        Offset = {
            vpos = Vector(10, -1.4, 0.25),
            vang = Angle(0, 0, 90),
        },
    }, 
    {
        PrintName = "Ammunition",
        DefaultAttName = "Rocket",
        Slot = {"k_rocket_ammo"}
    },
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
    },
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = "charm",
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "tag_launcher_offset",
        Offset = {
            vpos = Vector(1.9, -0.42, -2),
            vang = Angle(0, 0, 0),
        },
    }, 
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

local path = "kraken/launchers/rps/"

SWEP.BulletBones = {
    [1] = "j_mag1",
}

SWEP.Animations = {
	["enter_sights"] = {
		Source = "idle",
	},
    ["fire"] = {
        Source = "shoot1",
    },
    ["dryfire"] = {
        Source = "firemode",
		MinProgress = 0.01,
		FireASAP = true,
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
		MinProgress = 0.95,
        SoundTable = {
			{s = path .. "wfoly_la_rpapa7_reload_raise.ogg", t = 0.1},
			{s = path .. "wfoly_la_rpapa7_reload_load.ogg", t = 0.333},
			{s = path .. "wfoly_la_rpapa7_reload_lower.ogg", t = 1.033},
			{s = path .. "wfoly_la_rpapa7_reload_fast_hip_safetyclick.ogg", t = 1.7},
			{s = path .. "wfoly_la_rpapa7_reload_end.ogg", t = 1.9},
        },
    },
    ["ready"] = {
        Source = "draw",
        SoundTable = {
            {s = path .. "wfoly_la_rpapa7_raise_first.ogg", t = 9/30},
        },
    },
    ["draw"] = {
        Source = "draw_short",
		MinProgress = 0.5,
        SoundTable = {
            {s = path .. "wfoly_la_rpapa7_raise.ogg", t = 0/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = path .. "wfoly_la_rpapa7_drop_hip_rattle.ogg", t = 0/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["enter_customize"] = {
        Source = "lookat01",
        SoundTable = {
            {s = path .. "wfoly_la_rpapa7_inspect_01.ogg", t = 5/30},
			{s = path .. "wfoly_la_rpapa7_inspect_02.ogg", t = 88/30},
			{s = path .. "wfoly_la_rpapa7_inspect_03.ogg", t = 165/30},
        },
    },
    ["idle_customize"] = {
        Source = "lookat01",
        SoundTable = {
            {s = path .. "wfoly_la_rpapa7_inspect_01.ogg", t = 5/30},
			{s = path .. "wfoly_la_rpapa7_inspect_02.ogg", t = 88/30},
			{s = path .. "wfoly_la_rpapa7_inspect_03.ogg", t = 165/30},
        },
    },
    ["exit_customize"] = {
        Source = "lookat01",
        SoundTable = {
            {s = path .. "wfoly_la_rpapa7_inspect_01.ogg", t = 5/30},
			{s = path .. "wfoly_la_rpapa7_inspect_02.ogg", t = 88/30},
			{s = path .. "wfoly_la_rpapa7_inspect_03.ogg", t = 165/30},
        },
    },
    ["bash"] = {
        Source = "melee_01",
    },
}
