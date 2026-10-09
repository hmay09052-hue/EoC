AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true

SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Explosives - Rocket Launchers"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "E-60r"
SWEP.Trivia_Class = "Rocket Launcher"
SWEP.Trivia_Desc = "The E-60R was a model of missile launcher utilized by B1-series battle droids of the Confederacy of Independent Systems. They could be used to pierce armor, even when fired at long-range"
SWEP.Trivia_Manufacturer = "Baktoid Armor Workshop"
SWEP.Trivia_Calibre = "Rocket"

SWEP.DefaultBodygroups = "0000000000000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_e60r.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_e60r.mdl"

SWEP.ViewModelFOV = 60

SWEP.WorldModelOffset = {
    pos = Vector(-6.5, 7, -4),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 0.9
}

SWEP.HasHoloHUD = true
SWEP.HoloHUD_Red = true

SWEP.ShootEntity = "arccw_rocket_e60r"
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
SWEP.DistantShootSound = "ArcCW_Kraken.HeavyCorebass_ROCKET"
SWEP.ShootSoundSilenced = false

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "muzzleflash_m79"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 137, 0)

SWEP.IronSightStruct = {
    Pos = Vector(-1.04, -40, 0.31),
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

SWEP.ActivePos = Vector(0, 4, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(1, 0, -2.5)
SWEP.SprintAng = Angle(0, -2, 0)

SWEP.CrouchPos = Vector(-2, -3, -1)
SWEP.CrouchAng = Angle(0, 0, -10)

SWEP.HolsterPos = Vector(0, -10, -15)
SWEP.HolsterAng = Angle(50, 0, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(12, 40, -5)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.Attachments = {
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
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "root",
        Offset = {
            vpos = Vector(0.6, 6, .8),
            vang = Angle(90, -90, -90),
        },
    }, 
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

local path = "kraken/launchers/rps/"

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["idle_empty"] = {
        Source = "idleempty",
    },
    ["draw"] = {
        Source = "draw",
    },
    ["draw_empty"] = {
        Source = "drawempty",
    },
    ["fire"] = {
        Source = "fire1",
    },
    ["fire_iron"] = {
        Source = "fire1",
    },
    ["enter_sights"] = {
        Source = "idle",
        Time = 0,
    },
    ["idle_sights"] = {
        Source = "idle",
        Time = 0,
    },
    ["exit_sights"] = {
        Source = "idle",
        Time = 0,
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {
                s = "kraken/explosives/grenade_launcher_drum_load.wav",
                t = 1
                },
            {
                s = "kraken/explosives/rocket_reload.wav",
                t = 1.5
                },
            {
                s = "kraken/explosives/bulletchain.wav",
                t = 2.2
                },
        },
    },
}
