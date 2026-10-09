AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Explosives - Weapons"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "K-43"
SWEP.Trivia_Class = "Rifle, Anti-Material Rifle"
SWEP.Trivia_Desc = "Developed by a weapons firm during the First Galactic Civil War, the K-43 is an anti-vehicle cannon that is based upon an early model of the Beam-tube laser rifle. As testing of the prototypes progressed, a tresle duopod, long range scope, and stabilizing brace were added. The K-43 is not for sentients with poor skill or strength. The weapon utilizes a complicated reloading mechanism which results in a long downtime between shots. This delay is compensated for by the powerful blast of the cannon, which can wound or even cripple military vehicles. Sentients with miserable accuracy will suffer even more, as each shot is bound to reveal the shooter to its target."
SWEP.Trivia_Calibre = "Shell"
SWEP.Trivia_Manufacturer = "Galactic Empire"

SWEP.DefaultBodygroups = "0000000000"
SWEP.UseHands = true
SWEP.MirrorVMWM = true

SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_sw_antimaterial.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_sw_antimaterial.mdl"
SWEP.ViewModelFOV = 56

SWEP.WorldModelOffset = {
    pos = Vector(-9.5, 8, -6),
    ang = Angle(-5, 0, 180)
}

SWEP.TriggerDelay = true
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.ShellModel = "models/misc/88mm_shell.mdl"
SWEP.ShellPitch = 55
SWEP.ShellScale = 0.7
SWEP.ShellTime = 1
SWEP.ShellRotateAngle = Angle(0, 90, 0)

SWEP.Damage = 700
SWEP.DamageMin = 350
SWEP.RangeMin = 0
SWEP.Range = 1300
SWEP.Penetration = 8
SWEP.DamageType = DMG_BLAST
SWEP.MuzzleVelocity = 9000

SWEP.Tracer = "railgun_tracer_green"
SWEP.TracerCol = Color(0, 250, 0)
SWEP.TracerNum = 1
SWEP.TracerWidth = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 8

SWEP.Recoil = 4
SWEP.RecoilSide = 4
SWEP.RecoilRise = 4
SWEP.RecoilPunch = 5
SWEP.RecoilVMShake = 4
SWEP.VisualRecoilMult = 4

SWEP.ManualAction = true
SWEP.NoLastCycle = true

SWEP.Delay = 60 / 60
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

SWEP.AccuracyMOA = 0.1
SWEP.HipDispersion = 300
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 500

SWEP.SpeedMult = 0.85
SWEP.SightedSpeedMult = 0.35
SWEP.ShootSpeedMult = 1

SWEP.Primary.Ammo = "ar2"

SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0

SWEP.FirstShootSound = "kraken/explosives/torpedo/close1.wav"
SWEP.ShootSound = "kraken/explosives/torpedo/close2.wav"
SWEP.ShootSoundSilenced = false

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "nio_charge"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(0, 250, 0)

SWEP.HasHoloHUD = true
SWEP.IronSightStruct = {
    Pos = Vector(0, -90, 0),
    Ang = Vector(0, 0, 0),
     Magnification = 8,
     SwitchToSound = "weapon_hand/ads/0242-00001a46.mp3",
     SwitchFromSound = "weapon_hand/ads/0242-00001a43.mp3",
     ViewModelFOV = 55,
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(-1, 0, -2)
SWEP.ActiveAng = Angle(0, 0, -3)

SWEP.SprintPos = Vector(0,0,0)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(0, 5, 0)
SWEP.CustomizeAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, -3, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.DefaultElements = {}
SWEP.AttachmentElements = {}

SWEP.Attachments = {     
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "def_c_base",
        Offset = {
            vpos = Vector(0.8, -4.4, 35),
            vang = Angle(90, 0, 0),
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
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "def_c_base",
        Offset = {
            vpos = Vector(1.15, -6.7, 21.3),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        Bone = "def_c_base",
        Offset = {
            vpos = Vector(1.65, -4.6, -3),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["trigger"] = {
        Source = "idle",
        Mult = 0.12,
        SoundTable = {
            {p = 100, s = "kraken/explosives/torpedo/chargeup.wav", t = 0.01 },
        },
    },
    ["idle_sprint"] = {Source = "sprint", Mult = 1},
    ["enter_sprint"] = {
        Source = "sprint_in",
        MinProgress = 0.1,
    },
    ["exit_sprint"] = {
        Source = "sprint_out",
        MinProgress = 0.1,
    },
    ["ready"] = {
        Source = "draw_first",
        SoundTable = {
            {p = 100, s = "kraken/weapons/antimaterial/mech_kraber_ads_in_2ch_v1_01.wav", t = 0 / 30},
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_boltback_2ch_v1_01.wav", t = 18 / 30},
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_boltforward_2ch_v1_01.wav", t = 27 / 30}
        },
    },
    ["draw"] = {
        Source = "draw",
        Mult = 1,
        SoundTable = {
            {p = 100, s = "kraken/weapons/antimaterial/mech_kraber_ads_in_2ch_v1_02.wav", t = 0 / 30},
        },
    },
    ["holster"] = {
        Source = "holster",
        Mult = 1,
        SoundTable = {
            {p = 100, s = "kraken/weapons/antimaterial/mech_kraber_ads_in_2ch_v1_03.wav", t = 0 / 30},
        },
    },
    ["idle_sight"] = {
        Source = false,
    },
    ["fire"] = {
        Source = "fire",
        MinProgress = 0.8,
    },
    ["cycle"] = {
        Source = "rechamber",
        ShellEjectAt = 0.5,
        MinProgress = 1.5,
        SoundTable = {
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_boltback_2ch_v1_01.wav", t = 15 / 30},
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_boltforward_2ch_v1_01.wav", t = 24 / 30}
        },
    },
    ["enter_sight"] = {
        Source = false,
        MinProgress = 0.1,
    },
    ["fire_sight"] = {
        Source = "fire",
        MinProgress = 0.8,
    },
    ["cycle_sight"] = {
        Source = "rechamber",
        ShellEjectAt = 0.5,
        MinProgress = 1.5,
        SoundTable = {
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_boltback_2ch_v1_01.wav", t = 16 / 30},
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_boltforward_2ch_v1_01.wav", t = 22 / 30}
        },
    },
    ["exit_sight"] = {
        Source = "iron_out",
        MinProgress = 0.1,
    },
    ["bash"] = {
        Source = {"melee"},
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.6,
        LHIKEaseOut = 0.4,
        SoundTable = {
            {s = "ArcCW_APEX.Melee.Swing.Punch", t = 0 / 30},
    },
    },
    ["enter_inspect"] = {
        Source = "inspect_in",
    },
    ["exit_inspect"] = {
        Source = "inspect_out",
    },
    ["idle_inspect"] = {
        Source = "inspect",
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_magout_2ch_v1_01.wav", t = 15 / 30},
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_magin_2ch_v1_01.wav", t = 53 / 30}
        },
    },
    ["reload_empty"] = {
        Source = "reload_empty",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_magout_2ch_v1_01.wav", t = 15 / 30},
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_magin_2ch_v1_01.wav", t = 53 / 30},
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_boltback_2ch_v1_01.wav", t = 83 / 30},
            {p = 100, s = "kraken/weapons/antimaterial/wpn_krabersniper_1p_reload_boltforward_2ch_v1_01.wav", t = 96 / 30}
    },
},
}
