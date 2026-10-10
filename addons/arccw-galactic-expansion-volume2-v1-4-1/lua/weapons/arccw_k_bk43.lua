AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. II"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "BK-43"
SWEP.Trivia_Class = "Blaster Rifle"
SWEP.Trivia_Desc = "The BK-43 blaster rifle was a blaster rifle that was used by Vel Sartha. It had a collapsible stock."
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/galexpansion_vol2/bk43.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00100000000000"

SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/galexpansion_vol2/v_bk43.mdl"
SWEP.WorldModel = "models/arccw/kraken/galexpansion_vol2/worldmodel/w_bk43.mdl"

SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-1, 2.5, -5),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 22
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

SWEP.Damage = 47
SWEP.DamageMin = 22
SWEP.RangeMin = 0
SWEP.Range = 340
SWEP.Penetration = 10
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.Recoil = 1.2
SWEP.RecoilSide = 0.4
SWEP.RecoilRise = 0.7
SWEP.MaxRecoilBlowback = 0.5
SWEP.RecoilPunch = 0.6
SWEP.RecoilVMShake = 0.8

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 40

SWEP.Delay = 60 / 450
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

SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 300 
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

SWEP.ShootSound = "ArcCW_Kraken.SW_BK43_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_BK43_Distant"
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
    Pos = Vector(-2.51, 3.026, 0.3),
    Ang = Vector(0, 0, -5),
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
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.SprintPos = Vector(2, -1, 0)
SWEP.SprintAng = Angle(-10, 26, 0)

SWEP.CustomizePos = Vector(10, 5, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.CrouchPos = Vector(-0.2, -0.5, -1.5)
SWEP.CrouchAng = Angle(0, 0, -7)

SWEP.ActivePos = Vector(0.5, 5, 0)
SWEP.ActiveAng = Angle(0, 0, -5)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BipodDispersion = 1
SWEP.BipodRecoil = 1

SWEP.InBipodPos = Vector(-8, 0, -4)
SWEP.InBipodMult = Vector(2, 1, 1)

SWEP.BarrelLength = 30
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["integrated_holosight"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Sight", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "W_Main",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        InstalledEles = {"integrated_holosight"},
        Offset = {
            vpos = Vector(-0., -1.9, 7.6),
            vang = Angle(90, 0, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        VMScale = Vector(1.5,1.5,1.5),
        WMScale = Vector(1.5,1.5,1.5),
        Bone = "W_Main",
        Offset = {
            vpos = Vector(-0.1, 0.1, 29),
            vang = Angle(90, 0, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "W_Main",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Offset = {
            vpos = Vector(-0.1, 0.15, 20),
            vang = Angle(90, 0, 180),
        },
    },
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        Bone = "W_Main",
        Offset = {
            vpos = Vector(-0.1, 1.2, 16),
            vang = Angle(90, 0, -90),
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
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "W_Main",
        Offset = {
            vpos = Vector(1.05, 0.95, -0.54),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Bone = "W_Main",
        Offset = {
            vpos = Vector(0.8, 0.5, 3),
            vang = Angle(90, 0, -90),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing

SWEP.Animations = {
    ["fire"] = {
        Source = {"fire"},
    },
    ["fire_iron"] = {
        Source = {"fire_iron"},
    },
    ["reload"] = {
        Source = "wet56",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/ump45_clipout.wav" ,   t = 18 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/mp5_clipin.wav" ,    t = 63 / 40},
        },
    },
    ["reload_empty"] = {
        Source = "dry_56",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/ump45_clipout.wav" ,   t = 18 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/mp5_clipin.wav" ,    t = 61 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/ump45_boltslap.wav" ,    t = 85 / 40},
        },
    },
    ["fix"] = {
        Source = "overheat",
        LHIK = false,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 45 / 30},
            {s = "ArcCW_Kraken.Grab", t = 43 / 30},
        },
    },
    ["draw"] = {
        Source = "draw",
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
        Source = "idle",
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
    ["idle"] = {
        Source = "idle",
    },
    ["firemode"] = {
        Source = "firemode",
    },
    ["idle_empty"] = {
        Source = "idle",
    },
    ["fire_empty"] = {
        Source = {"fire"},
    },
}