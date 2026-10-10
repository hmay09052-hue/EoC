AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 5

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Special Forces"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "ZX-6"
SWEP.Trivia_Class = "Blaster-Experimental Heavy Canon"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The Zx-6 rotary blaster cannon was a blaster cannon used by the Galactic Republic during the Clone Wars. Later, during the reign of the Galactic Empire, these weapons were used by both the Imperial Army's Heavy Weapons Stormtroopers and Rebel Alliance's Heavy Soldiers during the Galactic Civil War."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/sops/z6x.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "010000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sops/new/v_zx6.mdl"
SWEP.WorldModel = "models/arccw/kraken/sops/world/w_zx6.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-9, 5, -5.75),
    ang = Angle(-10, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 75
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

SWEP.Damage = 30
SWEP.DamageMin = 22
SWEP.RangeMin = 0
SWEP.Range = 500
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
SWEP.Primary.ClipSize = 100

SWEP.Recoil = 0.76
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.90
SWEP.MaxRecoilBlowback = 1
SWEP.RecoilPunch = 1.4
SWEP.RecoilVMShake = 1.5

SWEP.Delay = 60 / 225
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
        Mode = 2,
    },
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

SWEP.ShootSound = "ArcCW_Kraken.SOPS_REPUBLIC_Z6X"
SWEP.DistantShootSound = "ArcCW_Kraken.SOPS_REPUBLIC_Z6X_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 250)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-4.849, -6.351, -1),
    Ang = Angle(4.8, 0, 0),
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

SWEP.SprintPos = Vector(2.019, -5.226, -2)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(10, 0, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.ActivePos = Vector(-3, -8, 1.5)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, -3, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 45

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "dlt34",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(0, 0, 38),
                   ang = Angle(90, 0, 0),
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
        Bone = "dlt34",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(-0.13, -4.7, 11.5),
            vang = Angle(90, 0, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Internal Compression",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "dlt34",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(-0.9, -1.5, 19.8),
            vang = Angle(90, 0, 180),
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
        Bone = "dlt34",
        Offset = {
            vpos = Vector(0.6, -1.2, 2),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Bone = "dlt34",
        Offset = {
            vpos = Vector(1, -2.4, -2.5),
            vang = Angle(90, 0, -90),
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
        Source = {"shoot"},
    },
    ["fire_iron"] = {},
    ["fix"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        Mult = 0.3,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatFix", t = 60 / 30},
            {s = "ArcCW_Kraken.Grab", t = 65 / 30},
        },
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        Mult = 0.5,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 110 / 30},
            {s = "ArcCW_Kraken.Grab", t = 115 / 30},
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

-- Special properties
SWEP.Hook_ModifyRPM = function(wep, delay)
    return delay / Lerp(wep:GetBurstCount() / 15, 1, 3)
end
