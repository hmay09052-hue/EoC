AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 4

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DLT-19d"
SWEP.Trivia_Class = "Blaster, Sniper"
SWEP.SubCategory = "5Snipers"
SWEP.Trivia_Desc = "The DLT-19 heavy blaster rifle was a model of heavy blaster rifle manufactured by BlasTech Industries. They were used by regular stormtroopers and Heavy Weapons Stormtroopers of the Galactic Empire, but they also saw use by other parties, including the Alliance to Restore the Republic and certain bounty hunters."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/dlt19.png"

-- Viewmodel & Entity Properties
SWEP.ReloadInSights = true
SWEP.ReloadInSights_CloseIn = 0.25
SWEP.ReloadInSights_FOVMult = 0.875

SWEP.DefaultBodygroups = "00000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_dlt19d.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_dlt19d.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-8, 5, -6),
    ang = Angle(0, 7, 180),
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

SWEP.Damage = 102
SWEP.DamageMin = 45
SWEP.RangeMin = 0
SWEP.Range = 908
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 1200

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 20

SWEP.RecoilSide = 0.2
SWEP.RecoilRise = 0.4
SWEP.Recoil = 0.8

SWEP.Delay = 60 / 103
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
        Mode = -3,
        PostBurstDelay = 0.1,
        Mult_RPM = 5,
        RunawayBurst = false,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0.2
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 1000

-- Speed Mult
SWEP.SpeedMult = 0.875
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.8

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.3

SWEP.ShootSound = "ArcCW_Kraken.SW_DLT19D_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DLT19D_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2.86, -7, 1.3),
    Ang = Angle(1.394, 0.428, 0),
    Magnification = 1.5,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
    ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "crossbow"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, -4, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.InBipodPos = Vector(-8, 0, -4)
SWEP.InBipodMult = Vector(2, 0, 1)

SWEP.BarrelLength = 40

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["e11_k_splitter"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["e11_k_supressor"] = {
        VMBodygroups = {{ind = 3, bg = 2}},
    },
    ["dlt19_short"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["dlt19_long"] = {
        VMBodygroups = {{ind = 1, bg = 2}},
    },
    ["dlt19_bipoddown"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["dlt19_bipodoff"] = {
        VMBodygroups = {{ind = 2, bg = 2}},
    },
    ["dlt19_stock"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["muzzle"] = {
        VMElements = {
           {
               Model = "models/hunter/plates/plate.mdl",
               Bone = "DC_15X_Rifle",
               Scale = Vector(0, 0, 0),                
               Offset = {
                pos = Vector(0, 30, 0),
                ang = Angle(-90, -90, 0)
               },
               IsMuzzleDevice = true
           }
        }
    }
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        DefaultAttName = "DLT-19 Ironsight",
        Slot = {"optic", "dlt19_iron"},
        Bone = "DC_15X_Rifle",
        WMScale = Vector(1, 1, 1),
        Offset = {
            vpos = Vector(0.05, -0.55, 2),
            vang = Angle(0, -90, 0),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        Bone = "DC_15X_Rifle",
        WMScale = Vector(1, 1, 1),
        VMScale = Vector(1, 1, 1),
        Offset = {
            vpos = Vector(0.5, 20, 0.6),
            vang = Angle(0, -90, 90),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "DLT-19 Muzzle",
        Slot = {"e11_k_muzzles", "muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "DC_15X_Rifle",
        WMScale = Vector(1, 1, 1),
        Offset = {
            vpos = Vector(-0.2, 29, 0.6),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Foregrip",
        DefaultAttName = "None",
        Slot = {"dlt19_bipod", "foregrip"},
        WMScale = Vector(1, 1, 1),
        Bone = "DC_15X_Rifle",
        Offset = {
            vpos = Vector(0, 0.2, 2.5),
            vang = Angle(90, -90, -90),   
        },
        SlideAmount = {
        vmin = Vector(0, 2, 0),
        vmax = Vector(0, 6, 0),
        },    
    },
    {
        PrintName = "Stock",
        DefaultAttName = "DLT-19 Stock",
        Bone = "DC_15X_Rifle",
        InstalledEles = {"dlt19_stock"},
        Slot = {"go_stock"},
        Bone = "DC_15X_Rifle",
        VMScale = Vector(1, 1, 1),
        Offset = {
            vpos = Vector(0, -8.7, 0.6),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Energization",
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
        Bone = "DC_15X_Rifle",
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Offset = {
            vpos = Vector(0.85, -5.3, -0.75),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "DC_15X_Rifle",
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Offset = {
            vpos = Vector(1, -7, 0.7),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["fire_iron"] = {},
    ["idle"] = {
        Source = "idle",
    },
    ["fire"] = {
        Source = "fire"
    },
    ["idle_iron"] = {
        Source = false,
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
    ["reload"] = {
        Source = "reload",
        LHIK = true,
        Mult = 1.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "arccw/kraken/empire/dlt19/handling/magrelease.wav", t = 0.2 },
            {s = "arccw/kraken/empire/dlt19/handling/magout.wav", t = 0.4 },
            {s = "arccw/kraken/empire/dlt19/handling/mag_fetch.wav", t = 0.6 },   
            {s = "arccw/kraken/empire/dlt19/handling/magin.wav", t = 1.4 },   
            {s = "arccw/kraken/empire/dlt19/handling/boltback.wav", t = 1.6 },   
        },
    },
}
