AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 4

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DLT-19x"
SWEP.Trivia_Class = "Blaster Rifle, Long Blaster"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The DLT-19x targeting blaster was a blaster rifle, longblaster, and a variation of the DLT-19 heavy blaster rifle. Unlike the DLT-19, the DLT-19x released all of its power in one shot before it would need to cool down. The DLT-19x was an incredibly powerful weapon and could take down most enemies in one shot. The weapon had a scope that could be zoomed in farther than most scopes. This targeting blaster was silent and effective, and as such, was a weapon of choice for many snipers, and the primary weapon for some Imperial sharpshooters. The LOM-series bounty hunter 4-LOM also wielded a DLT-19x, as did agent Del Meeko of the Inferno Squad, who used it during the Battle of Endor."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/dlt19x.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/empire/v_dlt19x.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_dlt19x.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-7, 3.5, -5),
    ang = Angle(-5, -90, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.15,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 110
SWEP.DamageMin = 76
SWEP.RangeMin = 0
SWEP.Range = 900
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 12
SWEP.ExtendedClipSize = 22
SWEP.ReducedClipSize = 6

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 2
SWEP.Recoil = 1.28

SWEP.Delay = 60 / 190
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


SWEP.AccuracyMOA = 1
SWEP.HipDispersion = 100
SWEP.MoveDispersion = 200
SWEP.JumpDispersion = 1000

-- Speed Mult
SWEP.SpeedMult = 0.825
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_DLT19X_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DLT19X_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.4, -5, 1.5),
    Ang = Angle(2, 0.5, 9),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(0, 0, 2)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, -1.2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.InBipodPos = Vector(-8, 0, -1)
SWEP.InBipodMult = Vector(2, 0, 1)

SWEP.BarrelLength = 40

-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["e11_k_splitter"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["e11_k_supressor"] = {
        VMBodygroups = {{ind = 1, bg = 2}},
    },
    ["muzzle_default"] = {
        VMBodygroups = {{ind = 1, bg = 3}},
    },
    ["e11_scope"] = {
        VMBodygroups = {{ind = 2, bg = 3}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["dlt19x_short"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["dlt19x_long"] = {
        VMBodygroups = {{ind = 2, bg = 2}},
    },
    ["dlt19_bipoddown"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["dlt19_bipodoff"] = {
        VMBodygroups = {{ind = 4, bg = 3}},
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
        InstalledEles = {"e11_scope"},
        Slot = {"optic", "dlt19x_iron"},
        Bone = "Weapon",
        Offset = {
            vpos = Vector(0.1, -1.5, 2.8),
            vang = Angle(0, -90, 0),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "Weapon",
        InstalledEles = {"e11_laser"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1.1, 18, 1.3),
            vang = Angle(0, -90, 90),
        },
    },
    {
        PrintName = "Foregrip",
        DefaultAttName = "DLT-19x Bipod-Up",
        Slot = {"dlt19_bipod", "foregrip"},
        Bone = "Weapon",
        Offset = {
            vpos = Vector(0, 0.2, 2.5),
            vang = Angle(90, -90, -90),   
        },
        SlideAmount = {
        vmin = Vector(0.2, 4, 0.4),
        vmax = Vector(0.2, 6, 0.5),
        },    
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "DLT-19 Muzzle",
        Slot = {"e11_k_muzzles", "muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "Weapon",
        VMScale = Vector(1.1, 1.1, 1.1),
        WMScale = Vector(1.1, 1.1, 1.1),
        InstalledEles = {"muzzle_default"},
        Offset = {
            vpos = Vector(0, 28, 0.9),
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
        Bone = "Weapon",
        VMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1.1, -4.2, 0),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "Weapon",
        VMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(1.05, -5, 0.9),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

SWEP.Animations = {
    ["ready"] = {
        Source = "base_ready",
    },
    ["idle"] = {
        Source = "base_idle",
    },
    ["bash"] = {
        Source = "base_melee_end",
    },
    ["fire"] = {
        Source = {"base_fire", "base_fire2"},
        Mult = 1.5,
    },
    ["fire_iron"] = {
        Source = {"iron_fire_1", "iron_fire_2", "iron_fire_3"},
        Mult = 1.5,
    },
    ["fire_empty"] = {
        Source = {"base_firelast"},
        Mult = 1,
    },
    ["fire_iron_empty"] = {
        Source = {"iron_firelast"},
        Mult = 1,
    },
    ["draw"] = {
        Source = "base_draw",
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
        Source = "base_holster",
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
        Source = "base_reload",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, 
        SoundTable = {
            {s = "arccw/kraken/empire/dlt19/handling/magrelease.wav", t = 35 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/magout.wav", t = 40 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/mag_fetch.wav", t = 50 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/magin.wav", t = 107 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/matgit.wav", t = 117 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/rattle.wav", t = 142 / 33 },
        },
    },
    ["reload_empty"] = {
        LHIK = true,
        Source = "base_reloadempty",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, 
        SoundTable = {
            {s = "arccw/kraken/empire/dlt19/handling/boltback.wav", t = 30 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/magrelease.wav", t = 88 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/magout.wav", t = 93 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/mag_fetch.wav", t = 103 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/magin.wav", t = 160 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/matgit.wav", t = 166 / 33 },
            {s = "arccw/kraken/empire/dlt19/handling/rattle.wav", t = 193 / 33 },
        },
    },
}
