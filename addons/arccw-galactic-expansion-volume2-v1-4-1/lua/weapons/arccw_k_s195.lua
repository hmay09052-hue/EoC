AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1

SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. II"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "S-195"
SWEP.Trivia_Class = "Blaster Double Barrel Pistol"
SWEP.Trivia_Desc = "Blaster Double Barrel Pistol designed originally for military purposes, now modernized and being used by many Bounty Hunters, Civillians and even Mercenaries or Military Corporations in the galaxy."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/galexpansion_vol2/s195.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "000000000000000000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/galexpansion_vol2/v_s195.mdl"
SWEP.WorldModel = "models/arccw/kraken/galexpansion_vol2/worldmodel/w_s195.mdl"

SWEP.ViewModelFOV = 65

SWEP.WorldModelOffset = {
    pos = Vector(-9, 3.8, -5),
    ang = Angle(0, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
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

SWEP.Damage = 26
SWEP.DamageMin = 16
SWEP.RangeMin = 0
SWEP.Range = 70
SWEP.Penetration = 8
SWEP.DamageType = DMG_BUCKSHOT
SWEP.MuzzleVelocity = 700

SWEP.NoRandSpread = true
SWEP.CanBash = true

SWEP.ShotgunSpreadPattern = {
    [1] = Angle(0, 0, 0),
    [2] = Angle(0, 1, 0),
    [3] = Angle(0, -1, 0),
    [4] = Angle(2.1, 0, 0),
    [5] = Angle(-2.1, 0, 0),
    [6] = Angle(1.4, 1.2, 0),
    [7] = Angle(-1.4, 1.2, 0),
    [8] = Angle(1.4, -1.2, 0),
    [9] = Angle(-1.4, -1.2, 0),
}

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 2

SWEP.Recoil = 2
SWEP.RecoilSide = 2
SWEP.RecoilRise = 2
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1.5
SWEP.RecoilVMShake = 2

SWEP.Delay = 60 / 180
SWEP.Num = 9
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}

SWEP.AccuracyMOA = 25
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 75
SWEP.JumpDispersion = 150

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

SWEP.ShootSound = "ArcCW_Kraken.SW_S195_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_S195_Distant"
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
    Pos = Vector(-2.625, -4.117, 0.05),
    Ang = Vector(2.703, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "pistol"
SWEP.HoldtypeSights = "revolver"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL

SWEP.SprintPos = Vector(2, -1, 0)
SWEP.SprintAng = Angle(-10, 26, 0)

SWEP.CustomizePos = Vector(9, 1, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.CrouchPos = Vector(0, 0, 0)
SWEP.CrouchAng = Angle(0, 0, 0)

SWEP.ActivePos = Vector(0, 0, -1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, 2, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 20
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["muzzleattach"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Internal Compression",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
    },  
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "W_Open2",
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Offset = {
            vpos = Vector(-0.3, -0.2, 2),
            vang = Angle(90, 0, -180),
        },
    },
    {
        PrintName = "Foregrip",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        Bone = "W_Open2",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0, -0.2, 1),
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
        VMScale = Vector(0.5, 0.5, 0.5),
        WMScale = Vector(0.5, 0.5, 0.5),
        Bone = "W_Main",
        Offset = {
            vpos = Vector(0.43, -1.5, 0),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "W_Main",
        Offset = {
            vpos = Vector(0.43, -2.03, 2),
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
    ["holster"] = {
        Source = "idle",
        Time = 0,
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
    ["holster_empty"] = {
        Source = "idle_emp",
        Time = 0,
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
        Source = "idle_sld",
    },
    ["idle_empty"] = {
        Source = "idle_emp_sld",
    },
    ["draw"] = {
        Source = "draw_sld",
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
    ["draw_empty"] = {
        Source = "draw_emp_sld",
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
        Source = "fire_sld",
    },
    ["fire_empty"] = {
        Source = "fire_emp_sld",
    },
    ["reload"] = {
        Source = "wet_sld",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        SoundTable = {
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_open.wav" ,	t = 10 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_remove.wav" ,	t = 22 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_insert.wav" ,	t = 70 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_close.wav" ,	t = 98 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_cock.wav" ,	t = 110 / 40},
        },
    },
    ["reload_empty"] = {
        Source = "dry_sld",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        SoundTable = {
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_open.wav" ,	t = 10 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_remove.wav" ,	t = 22 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_insert.wav" ,	t = 70 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_close.wav" ,	t = 98 / 40},
            {s =  "arccw/kraken/galexpansion_vol2/reloadsounds/flare_cock.wav" ,	t = 110 / 40},
            },
    },
}