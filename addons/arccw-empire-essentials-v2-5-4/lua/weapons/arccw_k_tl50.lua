AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "TL-50"
SWEP.Trivia_Class = "Blaster, Repeater"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The TL-50 Heavy Repeater, also known as the TL-50 Heavy Blaster, was a model of heavy repeating blaster rifle that was manufactured for the special forces of the Galactic Empire. In addition to sending storms of blaster bolts from its multiple barrels, the rifle could gather its energy into a powerful concussion blast. It could also be modified with an extended barrel for reduced spread and with a power cell for increased cooling power. During the Galactic Civil War against the Rebel Alliance, Commander Iden Versio of the Empire's elite Inferno Squad carried a TL-50 Heavy Repeater."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.IconOverride = "entities/kraken/empire-essentials/tl50.png"

-- Viewmodel & Entity Properties
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 35
SWEP.HeatDissipation = 2
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.5
SWEP.HeatFix = true

SWEP.DefaultBodygroups = "00000000000000"

SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.NoHideLeftHandInCustomization = true

SWEP.ViewModel = "models/arccw/kraken/empire/v_tl50.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_tl50.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-13, 4, -4.5),
    ang = Angle(-10, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}


-- Damage & Tracer
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2,
    [HITGROUP_CHEST] = 1.5,
    [HITGROUP_STOMACH] = 1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 45
SWEP.RangeMin = 0
SWEP.DamageMin = 24
SWEP.Range = 340

SWEP.Penetration = 10
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 800

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_red"
SWEP.TracerCol = Color(250, 0, 0)
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 70

SWEP.Recoil = 0.6
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.5
SWEP.RecoilPunch = 1

SWEP.Delay = 60 / 700

SWEP.Num = 1
SWEP.Firemodes = {
	{
		Mode = 2
	},
    {
        Mode = 1
    },
    {
        Mode = -3,
        RunawayBurst = true,
        Mult_RPM = 3,
        PostBurstDelay = 0.1, 
	},
    {
        Mode = 0
    },            
}



SWEP.AccuracyMOA = 1 
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 350

-- Speed Mult
SWEP.SpeedMult = 1.1
SWEP.SightedSpeedMult = 0.77
SWEP.ShootSpeedMult = 1

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0

SWEP.ShootSound = "ArcCW_Kraken.SW_TL50_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_TL50_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.36, -8.549, 0.7),
    Ang = Angle(0, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "smg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1

SWEP.ActivePos = Vector(0, -2, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 30

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["tl50_muzzle_repeater"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["tl50_muzzle_extended"] = {
        VMBodygroups = {{ind = 1, bg = 2}},
    },
    ["sw_scope_mount"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["sw_laser_mount"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "weapon",
               Scale = Vector(0, 0, 0),                
               Offset = {
                   pos = Vector(-0.46, -2.7, -12.5),
                   ang = Angle(-90, 0, -90),
               },
               IsMuzzleDevice = true
           }
        }, 
    }
}

SWEP.Attachments = {
    {
        PrintName = "Optic", 
        DefaultAttName = "Standard", 
        Slot = "optic",
        Bone = "weapon",
        Offset = {
            vpos = Vector(-0.5, -4.1, -1),
            vang = Angle(-90, 0, -90),
        },
        InstalledEles = {"sw_scope_mount"},
    },    
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),     
        Bone = "weapon", 
        InstalledEles = {"sw_laser_mount"},
        Offset = {
            vpos = Vector(-1.9, -3.1, -9),
            vang = Angle(-90, 0, 0),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"tl50_muzzle_repeater", "tl50_muzzle_extended", "muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "weapon",
        Offset = {
            vpos = Vector(-0.46, -2.7, -12.5),
            vang = Angle(-90, 0, -90),
        },
    },   
    {
        PrintName = "Ammo",
        DefaultAttName = "Standard",
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
        Slot = "uc_fg",
    },
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = {"charm"},
        Bone = "weapon",
        VMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(-1.4, -1.5, 3),
            vang = Angle(-90, 0, -90),
        },
    },     
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "weapon",
        Offset = {
            vpos = Vector(-1.2, -3.1, -1.6),
            vang = Angle(-90, 0, -65),
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
        Source = false,
    },
    ["fire"] = {
        Time = 0.625,
        Source = "fire",
    },
    ["fire_iron"] = {},
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {
                s = "armasclasicas/wpn_empire_lgequip.wav",
                p = 100, 
                v = 75,
                t = 0, 
                c = CHAN_ITEM,
            },
        }
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {
                s = "armasclasicas/wpn_empire_medequip.wav",
                p = 100,
                v = 75,
                t = 0,
                c = CHAN_ITEM,
            },
        }
    },
    ["fix"] = {
        Source = "overheat",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "arccw/kraken/cooling/overheat.mp3", t = 1 / 30},
            {s = "arccw/kraken/cooling/cooling.mp3", t = 70 / 30},
        },
    },
    ["reload"] = {
        Source = "reload", 
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "weapon_hand/reload_gentle/hits_and_grabs/023d-000006f5.mp3", t = 0.1 },
            {s = "weapon_hand/reload_gentle/mag_eject/023d-0000085b.mp3", t = 0.6 },
            {s = "weapon_hand/reload_gentle/mag_load/023d-00000648.mp3", t = 1.5 },
            {s = "weapon_hand/reload_gentle/hits_and_grabs/023d-0000078d.mp3", t = 2 },
            {s = "weapon_hand/reload_gentle/hits_and_grabs/023d-000006e3.mp3", t = 2.5 },
        },
    },
    ["exit_inspect"] = {
        Source = "overview",
        Time = 7,
        SoundTable = {
            {p = 100, s = "weapon_hand/reload_gentle/other/023d-00000adb.mp3", t = 1 / 30 },
            {p = 100, s = "weapon_hand/reload_gentle/other/023d-00000adb.mp3", t = 96 / 30 },
            {p = 100, s = "weapon_hand/reload_gentle/other/023d-00000adb.mp3", t = 170 / 30},
    },
    },
}
