AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 4

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DLT-19 Heavy"
SWEP.Trivia_Class = "Blaster, Heavy Rifle"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The DLT-19 heavy blaster rifle was a model of heavy blaster rifle manufactured by BlasTech Industries. They were used by regular stormtroopers and Heavy Weapons Stormtroopers of the Galactic Empire, but they also saw use by other parties, including the Alliance to Restore the Republic and certain bounty hunters."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/dlt19heavy.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_dlt19_heavy.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_dlt19h.mdl"

SWEP.ViewModelFOV = 50

SWEP.WorldModelOffset = {
    pos = Vector(-17, 0.7, -12),
    ang = Angle(0, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 0.86,
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

SWEP.Damage = 42
SWEP.DamageMin = 25
SWEP.RangeMin = 0
SWEP.Range = 599
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4500

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 250

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.45

SWEP.Delay = 60 / 900
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 2,
    },
    {
        Mode = -3,
        PostBurstDelay = 0.1,
        RunawayBurst = false,
    },
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 350
SWEP.MoveDispersion = 200
SWEP.JumpDispersion = 1000

-- Speed Mult
SWEP.SpeedMult = 0.875
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.8

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 95
SWEP.ShootPitchVariation = 0.5

SWEP.ShootSound = "ArcCW_Kraken.SW_DLT19_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DLT19_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-0.116, -11.886, 4.901),
    Ang = Vector(1.317, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "crossbow"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(3, -8, 3)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.InBipodAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(14, -10, 0)
SWEP.SprintAng = Angle(-7.036, 45.016, 0)

SWEP.CustomizePos = Vector(20, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(3, 0, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.InBipodPos = Vector(-8, -10, -2)
SWEP.InBipodMult = Vector(1, 0, 2)

SWEP.BarrelLength = 40

SWEP.ExtraSightDist = 5

-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["e11_k_splitter"] = {
        VMBodygroups = {{ind = 1, bg = 2}},
    },
    ["e11_k_supressor"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
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
    ["dlt19h_short"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["dlt19h_long"] = {
        VMBodygroups = {{ind = 2, bg = 2}},
    },
    ["dlt19_bipoddown"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["dlt19_bipodoff"] = {
        VMBodygroups = {{ind = 4, bg = 3}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        DefaultAttName = "Standard",
        Slot = {"optic", "dlt19h_iron"},
        Bone = "tag_weapon",
        InstalledEles = {"e11_scope"},
        Offset = {
            vpos = Vector(-0.2, -0.07, 2.1),
            vang = Angle(0, 0, 0),
        },
        CorrectiveAng = Angle(0, 0, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "tag_weapon",
        InstalledEles = {"e11_laser"},
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Offset = {
            vpos = Vector(23, -1.6, 0.3),
            vang = Angle(0, 0, 90),
        },
    },
    {
        PrintName = "Foregrip",
        DefaultAttName = "None",
        Bone = "tag_weapon",
        WMScale = Vector(1, 1, 1),
        Slot = {"dlt19_bipod", "foregrip"},
        Offset = {
            vpos = Vector(8, 0, -0.9),
            vang = Angle(0, 0, -0),   
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "DLT-19 Muzzle",
        Slot = {"e11_k_muzzles", "muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "tag_weapon",
        VMScale = Vector(2, 2, 2),
        WMScale = Vector(2, 2, 2),
        InstalledEles = {"muzzle_default"},
        Offset = {
            vpos = Vector(38, 0, -0.1),
            vang = Angle(0, 0, 0),
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
        Bone = "tag_weapon",
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),  
        Offset = {
            vpos = Vector(-6.7, -1.1, -1.8),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "tag_weapon",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(-10, -1.3, 0),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
        Time = 1 / 30,
    },
    ["draw"] = {
        Source = "draw",
        Time = 0.75,
        LHIK = true,
        LHIKIn = 0.25,
        LHIKOut = 0.25,
    },
    ["draw_empty"] = {
        Source = "draw_empty",
        Time = 0.5,
        LHIK = true,
        LHIKIn = 0.25,
        LHIKOut = 0.25,
    },
    ["holster"] = {
        Source = "holster",
        Time = 0.5,
        LHIK = true,
        LHIKIn = 0.25,
        LHIKOut = 0.25,
    },
    ["holster_empty"] = {
        Source = "holster_empty",
        Time = 0.5,
        LHIK = true,
        LHIKIn = 0.25,
        LHIKOut = 0.25,
    },
    ["ready"] = {
        Source = "draw",
        Time = 1,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.25,
    },
    ["fire"] = {
        Source = {"fire"},
        Time = 7 / 30,
        ShellEjectAt = false,
    },
    ["fire_iron"] = {
        Source = {"fire_ads"},
        Time = 7 / 30,
        ShellEjectAt = false,
    },
    ["fire_empty"] = {
        Source = {"fire_last"},
        Time = 7 / 30,
        ShellEjectAt = false,
    },
    ["fire_iron_empty"] = {
        Source = {"fire_last"},
        Time = 7 / 30,
        ShellEjectAt = false,
    },
    ["reload"] = {
        Source = "reload",
        Time = 150 / 35,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Framerate = 30,
        Checkpoints = {28, 38, 69},
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.5,
        SoundTable = {
            {s = "arccw/kraken/empire/dlt19/jimmy.wav", t = 10 / 35},
            {s = "arccw/kraken/empire/dlt19/out.wav", t = 20 / 35},
            {s = "arccw/kraken/empire/dlt19/jimmy.wav", t = 37 / 35},
            {s = "arccw/kraken/empire/dlt19/in.wav", t = 57 / 35},
            {s = "arccw/kraken/empire/dlt19/pull.wav", t = 100 / 35},
            {s = "arccw/kraken/empire/dlt19/charge.wav", t = 105 / 35},
        },
    },
}
