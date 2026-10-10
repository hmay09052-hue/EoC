AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 3

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Imperial DC-17m Shotgun"
SWEP.Trivia_Class = "Blaster, Scatter"
SWEP.SubCategory = "6Shotguns"
SWEP.Trivia_Desc = "The DC-17m Interchangeable Weapon System, also known as the DC-17m Repeating Blaster Rifle, was a type of repeating blaster rifle used by Republic clone commandos during the Clone Wars. It could change between a repeating blaster rifle and grenade launcher by switching the weapon's barrel module."
SWEP.Trivia_Manufacturer = "BlasTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.Trivia_Country = "Galactic Empire, Galactic Republic"
SWEP.IconOverride = "entities/kraken/empire-essentials/dc17mi_shotgun.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0200000000"
SWEP.UseHands = true
SWEP.MirrorVMWM = true

SWEP.ViewModel = "models/arccw/kraken/empire/v_dc17m_imperial.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_dc17m.mdl"

SWEP.ViewModelFOV = 50

SWEP.WorldModelOffset = {
    pos = Vector(-13, 7.2, -4.5),
    ang = Angle(-10, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
}

-- Damage & Tracer

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

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

SWEP.Damage = 18
SWEP.DamageMin = 8
SWEP.RangeMin = 0
SWEP.Range = 200
SWEP.Penetration = 8
SWEP.DamageType = DMG_BUCKSHOT
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 100

SWEP.Recoil = 2.2
SWEP.RecoilSide = 1
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

SWEP.AccuracyMOA = 5
SWEP.HipDispersion = 100
SWEP.MoveDispersion = 75
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 1.1
SWEP.SightedSpeedMult = 0.77
SWEP.ShootSpeedMult = 1

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"

SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_SCATTER_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_SCATTER_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-6.498, -10.992, -0.6),
    Ang = Vector(-1.846, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(-2, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(7, 0, -1)
SWEP.SprintAng = Angle(-10, 40, 0)

SWEP.CustomizePos = Vector(9.824, 2, -2.897)
SWEP.CustomizeAng = Angle(12.149, 30.547, 0)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 25

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["e11_scope"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["dc17m_mag_extended"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["dc17m_mag_drum"] = {
        VMBodygroups = {{ind = 2, bg = 2}},
    },
    ["muzzle"] = {
        VMElements = {
            {
                Model = "models/hunter/plates/plate.mdl",
                Bone = "DC-17M",
                Scale = Vector(0, 0, 0),
                Offset = {
                    pos = Vector(0, -25, 0),
                    ang = Angle(0, 90, 0)
                },
                IsMuzzleDevice = true
            },
        },
    },
}

SWEP.Attachments = {
    {
        PrintName = "Optic", 
        DefaultAttName = "None", 
        Slot = "optic",
        Bone = "DC-17M",
        InstalledEles = {"scope_attach"},
        Offset = {
            vpos = Vector(0.06, -2.75, -1.6),
            vang = Angle(0, 90, 180),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0)
    }, 
    {
        PrintName = "Internal Compression",
        DefaultAttName = "DC-17m Rifle",
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
    },   
    {
        PrintName = "Mode",
        DefaultAttName = "None",
        Slot = {"sw_mode"},
    },    
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "DC-17M", 
        Offset = {
            vpos = Vector(-1.5, -13, -0.1),
            vang = Angle(0, 90, 90),
        },
    },   
    {
        PrintName = "Power Cell",
        DefaultAttName = "Standard",
        Slot = "dc17m_mag",
    },
    {
        PrintName = "Ammunition",
        DefaultAttName = "Standard",
        Slot = {"ammo", "special_ammo"}
    },
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
    },
    {
        PrintName = "Charm",
        DefaultAttName = "None",
        Slot = {"charm"},
        Bone = "DC-17M",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.94, 0.8, 2.6),
            vang = Angle(0, 90, 180),
        },
    },     
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "DC-17M",
        Offset = {
            vpos = Vector(1.48, 1.4, 1),
            vang = Angle(0, 90, 180),
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
    ["fire"] = {
        Source = {"fire"},
    },
    ["fire_iron"] = {},
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
    ["reload"] = {
        Source = "reload", 
        LHIK = true,
        Mult = 0.9,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "weapon_hand/reload_heavy/mag_eject/023d-00000080.mp3", t = 10 / 60},
            {s = "weapon_hand/reload_gentle/mag_load/023d-00000648.mp3", t = 90 / 60},
            {s = "weapon_hand/reload_gentle/mag_load/023d-00000668.mp3", t = 110 / 60},
        },
    },
}
