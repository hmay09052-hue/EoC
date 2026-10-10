AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Special Forces"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Empire '773 Short-Firepuncher"
SWEP.Trivia_Class = "Blaster-Experimental Sniper Rifle"
SWEP.SubCategory = "5Snipers"
SWEP.Trivia_Desc = "The 773 Firepuncher rifle, also known as the 773 Firepuncher, was a model of sniper rifle manufactured by Merr-Sonn Munitions, Inc. that featured ablative coating and a wide-beam 'burning' mode."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/sops/shortypuncher_imperio.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00111000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sops/new/v_firepuncher_empire.mdl"
SWEP.WorldModel = "models/arccw/kraken/sops/world/w_firepuncher_empire.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-4, 7.4, -9.5),
    ang = Angle(-30, 50, -180),
    bone = "ValveBiped.Bip01_R_Hand",
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

SWEP.Damage = 97
SWEP.DamageMin = 67
SWEP.RangeMin = 0
SWEP.Range = 550
SWEP.Penetration = 10
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 25

SWEP.Recoil = 1.25
SWEP.RecoilSide = 0.55
SWEP.RecoilRise = 0.90
SWEP.MaxRecoilBlowback = 1
SWEP.RecoilPunch = 1.45
SWEP.RecoilVMShake = 1.5

SWEP.Delay = 60 / 120
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


SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 250
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

SWEP.ShootSound = "ArcCW_Kraken.SOPS_EMPIRE_SHORTFIREPUNCHER"
SWEP.DistantShootSound = "ArcCW_Kraken.SOPS_EMPIRE_SHORTFIREPUNCHER_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-1.629, -0.181, 0),
    Ang = Angle(3, 0.4, 7.5),
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

SWEP.ActivePos = Vector(0, 2, 0)
SWEP.ActiveAng = Angle(0, 0, 7.5)

SWEP.HolsterPos = Vector(4, -3, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 30
-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["scope_attach"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "Crossair_rifle",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(0.1, 9, 2),
                   ang = Angle(0, -90, 0),
               },
               IsMuzzleDevice = true,
           }
        }, 
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Sight", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "Crossair_rifle",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        InstalledEles = {"scope_attach"},
        Offset = {
            vpos = Vector(0.1, -4.3, 2.86),
            vang = Angle(0, -90, 0),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 180, 0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        Bone = "Crossair_rifle",
        VMScale = Vector(1.5,1.5,1.5),
        WMScale = Vector(1.5,1.5,1.5),
        Offset = {
            vpos = Vector(0.1, 8, 2),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "Crossair_rifle",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(-0.6, 2, 1.5),
            vang = Angle(-90, -90, 0),
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
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Bone = "Crossair_rifle",
        Offset = {
            vpos = Vector(1, 3, 1.6),
            vang = Angle(90, -90, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Bone = "Crossair_rifle",
        Offset = {
            vpos = Vector(1, 0, 1.6),
            vang = Angle(90, -90, -90),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["idle_iron"] = {
        Source = false,
    },
	["fire"] = {
        Source = {"fire"},
    },
    ["fire_iron"] = {},
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        Mult = 1.1,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 25 / 30},
            {s = "kraken/sops_new/firepuncher/reload.wav", t = 0.1 / 30},
        },
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {
                s = "ArcCW_Kraken.Draw",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {
                s = "ArcCW_Kraken.Holster",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
}
