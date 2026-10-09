AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 4 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "T-21b"
SWEP.Trivia_Class = "Blaster, Heavy Blaster Repeater"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The T-21B heavy blaster was a long-range version of the T-21 heavy blaster. It boasted two optics which the T-21 lacked, making it deadly at greater distances, but not useful for close quarters combat."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/t21b.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/empire/v_t21b.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_t21b.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-3, 3, -8),
    ang = Angle(0, -90, 180),
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

SWEP.Damage = 50
SWEP.DamageMin = 40
SWEP.RangeMin = 0
SWEP.Range = 400
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 55

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.85

SWEP.Delay = 60 / 260
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 2,
    },
    {
        Mode = -3,
        PostBurstDelay = 0.1,
        Mult_RPM = 3,
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
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 200
SWEP.JumpDispersion = 500

-- Speed Mult
SWEP.SpeedMult = 0.875
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.8

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_T21B_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_T21B_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-4.3, -2, 2.7),
    Ang = Angle(0, 0, 0),
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
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(0, 1, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 35

-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["e11_scope"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "Weapon",
        InstalledEles = {"e11_scope"},
        Offset = {
            vpos = Vector(0.04, -7.3, 3.6),
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
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        InstalledEles = {"e11_laser"},
        Offset = {
            vpos = Vector(1.8, 22.1, 1),
            vang = Angle(0, -90, 90),
        },
    },
    {
        PrintName = "Foregrip",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        Bone = "Weapon",
        Offset = {
            vpos = Vector(-0, 0.2, 2.6),
            vang = Angle(90, -90, -90),   
        },
        SlideAmount = {
        vmin = Vector(0, 8, -0.5),
        vmax = Vector(0, 10, -0.5),
        },    
    },
    {
        PrintName = "Internal Compression",
        DefaultAttName = "None",
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
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
        VMScale = Vector(1, 1, 1),
        Offset = {
            vpos = Vector(0.4, -0.4, -2),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "Weapon",
        VMScale = Vector(1, 1, 1),
        Offset = {
            vpos = Vector(0.5, 1.4, -0.7),
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
        SoundTable = {
            {s = "arccw/kraken/empire/t21/handling/deploy.wav", t = 0.1 / 31 },
            {s = "arccw/kraken/empire/t21/handling/boltback.wav", t = 33 / 31 },
            {s = "arccw/kraken/empire/t21/handling/rattle.wav", t = 40 / 31 },
            {s = "arccw/kraken/empire/t21/handling/shoulderweapon.wav", t = 50 / 31 },
        },
    },
    ["idle"] = {
        Source = "base_idle",
    },
    ["bash"] = {
        Source = "base_melee_end",
    },
    ["fire"] = {
        Source = {"base_fire_1", "base_fire_2"},
    },
    ["fire_iron"] = {
        Source = {"iron_fire_1", "iron_fire_2"},
    },
    ["fire_empty"] = {
        Source = {"base_fire_last"},
    },
    ["fire_iron_empty"] = {
        Source = {"iron_fire_last"},
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
        Source = "base_reload",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, 
        SoundTable = {
            {s = "arccw/kraken/empire/t21/handling/magrelease.wav", t = 26 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/magoutfull.wav", t = 40 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/fetchmag.wav", t = 53 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/fiddle.wav", t = 134 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/magin.wav", t = 140 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/maghit.wav", t = 169 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/rattle.wav", t = 198 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/shoulderweapon.wav", t = 208 / 34.5 },
        },
    },
    ["reload_empty"] = {
        LHIK = true,
        Source = "base_reloadempty",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, 
        SoundTable = {
            {s = "arccw/kraken/empire/t21/handling/magrelease.wav", t = 26 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/magout.wav", t = 40 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/fetchmag.wav", t = 53 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/fiddle.wav", t = 119 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/magin.wav", t = 127 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/maghit.wav", t = 157 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/boltback.wav", t = 197 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/rattle.wav", t = 225 / 34.5 },
            {s = "arccw/kraken/empire/t21/handling/shoulderweapon.wav", t = 239 / 34.5 },
        },
    },
}
