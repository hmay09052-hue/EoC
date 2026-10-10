AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Special Forces"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "'Dead Man's Revenge'"
SWEP.Trivia_Class = "Lever-Action Blaster"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "Galactic Lever-Action rifle. Unkown origin. 'Long, short, they all end the same way.'"
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Tibanna Capsule"
SWEP.IconOverride = "entities/kraken/sops/deadmansrevenge.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "000000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sops/new/c_dead_mans_revenge.mdl"
SWEP.WorldModel = "models/arccw/kraken/sops/world/w_dead_mans_revenge.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-11.3, 6, -3),
    ang = Angle(-15, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 0.9,
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

SWEP.ShotgunReload = true
SWEP.ShellModel = "models/shells/shell_556.mdl"
SWEP.ShellPitch = 95
SWEP.ShellScale = 2

SWEP.Damage = 102
SWEP.DamageMin = 68
SWEP.RangeMin = 0
SWEP.Range = 650
SWEP.Penetration = 10
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 0, 250)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 14

SWEP.Recoil = 1.25
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 1
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1
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


SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 100
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
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SOPS_GALACTIC_DEADMANSREVENGE"
SWEP.DistantShootSound = "ArcCW_Kraken.SOPS_GALACTIC_DEADMANSREVENGE_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 250)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-5.25, -10.363, -0.3),
    Ang = Angle(0, -0.03, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "ar2"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.SprintPos = Vector(2, -1, 0)
SWEP.SprintAng = Angle(-10, 26, 0)

SWEP.CustomizePos = Vector(10, 0, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)


SWEP.ActivePos = Vector(-3, -5, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 30
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {}

SWEP.Attachments = {     
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
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle_retracted",
    },
	["fire"] = {
        Source = "shoot",
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = "shootiron",
        ShellEjectAt = 0,
    },
    ["sgreload_start"] = {
        Source = "start reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        SoundTable = {
                        {s = "kraken/sops_new/deadmanstale/deadmansreloadstart.wav", t = 0.1},
                    },
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0,
    },
    ["sgreload_insert"] = {
        Source = "insert",
        RestoreAmmo = 1,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        SoundTable = {
                        {s = "kraken/sops_new/deadmanstale/deadmansreloadinsert.wav", t = 3/30},
                    },
        TPAnimStartTime = 0.3,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0,
    },
    ["sgreload_finish"] = {
        Source = "finish reload",
        SoundTable = {
                        {s = "kraken/sops_new/deadmanstale/deadmansreloadend.wav", t = 0.01},
                    },
        LHIK = true,
        LHIKIn = 0.4,
        LHIKOut = 0.4,
    },  
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {
                s = "kraken/sops_new/deadmanstale/deadmansdraw.wav", -- sound; can be string or table
                p = 100, -- pitch
                v = 75, -- volume
                t = 0, -- time at which to play relative to Animations.Time
                c = CHAN_ITEM, -- channel to play the sound
            },
        }
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {
                s = "kraken/sops_new/deadmanstale/deadmansdraw.wav", -- sound; can be string or table
                p = 100, -- pitch
                v = 75, -- volume
                t = 0, -- time at which to play relative to Animations.Time
                c = CHAN_ITEM, -- channel to play the sound
            },
        }
    },
}
