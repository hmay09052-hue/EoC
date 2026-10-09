AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "A-280"
SWEP.Trivia_Class = "Blaster, Rifle"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "The A280C blaster rifle was a modified variant of the popular A280 blaster rifle and was the preferred weapon of Rebel Alliance commandos. It featured a high rate of fire and was known for its excellent firepower and sturdy design."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Rebel Alliance"
SWEP.IconOverride = "entities/kraken/empire-essentials/a280c.png"

-- Viewmodel & Entity Properties
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.DefaultBodygroups = "0000000000"
SWEP.ViewModel = "models/arccw/kraken/empire/v_a280.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_a280.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-4, 3, -2.9),
    ang = Angle(-15, 0, 180),
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

SWEP.Damage = 39
SWEP.DamageMin = 23
SWEP.RangeMin = 0
SWEP.Range = 400
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 35

SWEP.Recoil = 0.9
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6

SWEP.Delay = 60 / 450
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
        Mult_RPM = 2,
    },
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0.2
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 150
SWEP.JumpDispersion = 500

-- Speed Mult
SWEP.SpeedMult = 0.925
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_EMPIRE_A280_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_EMPIRE_A280_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2.820, 0, 0.86),
    Ang = Angle(0, 0.025, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 54,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 4, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(0, 3, 0)
SWEP.SprintAng = Angle(0, 0, 0)


SWEP.CustomizePos = Vector(10, 5, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, 0, 1)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 25

SWEP.ExtraSightDist = 5

-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["a280_rifle_barrel"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
        NameChange = "A280 Extended",
        AttPosMods = {
            [3] = {
                vpos = Vector(21, 0, 2.7),
            },
            [4] = {
                vpos = Vector(13, 0, 1.3),
            },
        }
    },
    ["a280_stock_carbine"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
        NameChange = "A280 Extended",
    },
    ["e11_scope"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Sight",
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "tag_weapon",
        InstalledEles = {"e11_scope"},
        Offset = {
            vpos = Vector(2.8, -0.01, 3.9),
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
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(11, -1.2, 3.3),
            vang = Angle(0, 0, 90),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(16, 0, 2.7),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Foregrip",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        Bone = "tag_weapon",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(11, 0, 1.3),
            vang = Angle(0, 0, 0),   
        },    
    },
    {
        PrintName = "Barrel",
        DefaultAttName = "A-280 Barrel",
        Slot = {"a280_rifle_barrel"},
    },
    {
        PrintName = "Stock",
        DefaultAttName = "Skeleton A-280 Stock",
        Slot = {"a280_stock_carbine"},
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
        VMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(-3.5, -0.7, 2),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "tag_weapon",
        VMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(0, -0.6, 2.6),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
        Time = 1 / 30,
    },
    ["draw"] = {
        Source = "draw",
        Time = 1,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 1,
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
        Time = 0.75,
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 1,
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
    ["ready"] = {
        Source = "first_draw",
        Time = 1.25,
        LHIK = true,
        LHIKIn = 0.1,
        LHIKOut = 1.25,
        SoundTable = {
            {
                s = "arccw/kraken/empire/a280/chamber.wav",
                p = 100,
                v = 100,
                t = 0.15,
                c = CHAN_ITEM,
            },
        }
    },
    ["fire"] = {
        Source = {"fire"},
        Time = 0.5,
    },
    ["fire_iron"] = {},
    ["reload"] = {
        Source = "reload",
        Time = 2,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Framerate = 37,
        Checkpoints = {28, 38, 69},
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.5,
        SoundTable = {
            {s = "arccw/kraken/empire/a280/in.wav", t = 0.15},
            {s = "arccw/kraken/empire/a280/out.wav", t = 1.1}
        },
    },
    ["reload_empty"] = {
        Source = "reload_empty",
        Time = 2.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Framerate = 37,
        Checkpoints = {28, 38, 69},
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.5,
        SoundTable = {
            {s = "arccw/kraken/empire/a280/in.wav", t = 0.15},
            {s = "arccw/kraken/empire/a280/out.wav", t = 1.1},
            {s = "arccw/kraken/empire/a280/chamber.wav", t = 1.65}
        },
    },
    ["enter_sprint"] = {
        Source = "sprint_in",
        Time = 10 / 30
    },
    ["idle_sprint"] = {
        Source = "sprint_loop",
        Time = 30 / 40
    },
    ["exit_sprint"] = {
        Source = "sprint_out",
        Time = 10 / 30
    },
}
