AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 4

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. II"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Z-1p"
SWEP.Trivia_Class = "Blaster Hand-Repeater"
SWEP.Trivia_Desc = "Blaster Hand-Repeater designed originally for military purposes, now modernized and being used by many Bounty Hunters, Civillians and even Mercenaries or Military Corporations in the galaxy."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/galexpansion_vol2/z1.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00000000000000"

SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/galexpansion_vol2/v_evo.mdl"
SWEP.WorldModel = "models/arccw/kraken/galexpansion_vol2/worldmodel/w_evo.mdl"

SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-10, 3, -3.5),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 45
SWEP.HeatDissipation = 7
SWEP.HeatLockout = true
SWEP.HeatFix = true
SWEP.HeatDelayTime = 0.5

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 25
SWEP.DamageMin = 22
SWEP.RangeMin = 0
SWEP.Range = 380
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
SWEP.Primary.ClipSize = 75

SWEP.Recoil = 0.5
SWEP.RecoilSide = 0.4
SWEP.RecoilRise = 1
SWEP.MaxRecoilBlowback = 1
SWEP.RecoilPunch = 1
SWEP.RecoilVMShake = 1.5

SWEP.Delay = 60 / 220
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

SWEP.ShootSound = "ArcCW_Kraken.SW_Z1_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_Z1_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.HasHoloHUD1 = true
SWEP.IronSightStruct = {
    Pos = Vector(-2.804, 0, -1.2),
    Ang = Vector(4.737, 0, 0),
    Magnification = 1.15,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
    ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "ar2"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 0, -2)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.CrouchPos = Vector(0, 0, 0)
SWEP.CrouchAng = Angle(0, 0, -4)

SWEP.SprintPos = Vector(0, 0, -2)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -1, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.InBipodPos = Vector(-8, 0, -4)
SWEP.InBipodMult = Vector(2, 0, 1)

SWEP.BarrelLength = 40
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {}

SWEP.Attachments = {     
    {
        PrintName = "Sight", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "j_gun",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(7.1, 0.1, 3.9),
            vang = Angle(0, 0, 0),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "j_gun",
        Offset = {
            vpos = Vector(15, 0, -0.9),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Internal Compression",
        DefaultAttName = "Standard",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
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
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Bone = "j_gun",
        Offset = {
            vpos = Vector(-7.1, -1.2, 2.4),
            vang = Angle(0, 0, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "j_gun",
        Offset = {
            vpos = Vector(-2.8, -0.6, 3),
            vang = Angle(0, 0, 40),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
SWEP.TriggerDelay = true 
SWEP.Animations = {
    ["trigger"] = {
        Source = "fire",
        Mult = 0.9,
        SoundTable = {
            {
                s = "arccw/kraken/galexpansion_vol2/reloadsounds/minigun/weap_dblmg_spinup_plr_01.ogg",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["untrigger"] = {
        Source = "fire",
        Mult = 0.9,
        SoundTable = {
            {
                s = "arccw/kraken/galexpansion_vol2/reloadsounds/minigun/weap_dblmg_spindown_plr_01.ogg",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["idle"] = {
        Source = "idle",
        Time = 1 / 30,
    },
    ["draw"] = {
        Source = "draw",
        Time = 1,
        SoundTable = {
            {
                s = "arccw/kraken/empire/draw_pistol.wav",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["holster"] = {
        Source = "holster",
        Time = 0.75,
        SoundTable = {
            {
                s = "arccw/kraken/empire/draw_pistol.wav",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["fire"] = {
        Source = {"fire"},
        Time = 0.5,
    },
    ["fire_iron"] = {
        Source = {"fire"},
        Time = 0.5,
    },
    ["reload"] = {
        Source = "overheat",
        Time = 2.6,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 50 / 30},
        },
    },
    ["fix"] = {
        Source = "overheat",
        Time = 2.9,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 50 / 30},
        },
    },
    ["enter_sprint"] = {
        Source = "sprint_in",
        Time = 1,
    },
    ["idle_sprint"] = {
        Source = "sprint_loop",
        Time = 30 / 40
    },
    ["exit_sprint"] = {
        Source = "sprint_out",
        Time = 1,
    },
}

-- Special properties
SWEP.Hook_ModifyRPM = function(wep, delay)
    return delay / Lerp(wep:GetBurstCount() / 15, 1, 3)
end