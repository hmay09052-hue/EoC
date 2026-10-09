AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Valken 38x"
SWEP.Trivia_Class = "Blaster Sniper Rifle"
SWEP.SubCategory = "5Snipers"
SWEP.Trivia_Desc = "The Valken-38x was a model of longblaster that was manufactured for high precision and power over long ranges. It was utilized by the Galactic Republic during the Clone Wars."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/republic/v_valken38.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_valken38.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-8, 3.5, -4),
    ang = Angle(-10, -90, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 10
SWEP.HeatDissipation = 2
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 1
SWEP.HeatFix = true

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 98
SWEP.DamageMin = 76
SWEP.RangeMin = 0
SWEP.Range = 600
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 25

SWEP.Recoil = 1.2
SWEP.RecoilSide = 1.5
SWEP.RecoilRise = 2
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1.5
SWEP.RecoilVMShake = 1

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

SWEP.AccuracyMOA = 5
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200

-- Speed Mult
SWEP.SpeedMult = 0.85
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.30

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0

SWEP.ShootSound = "ArcCW_Kraken.SW_VALKEN"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_VALKEN_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 255)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.65, -5, 2.515),
    Ang = Vector(-0.25, 0, 9),
     Magnification = 1.2,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 60,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(-1, 4, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4, -2, -2)
SWEP.SprintAng = Angle(0, 30, -15)

SWEP.CustomizePos = Vector(15, 0, 5)
SWEP.CustomizeAng = Angle(0, 40, 30)

SWEP.HolsterPos = Vector(4, 0, -2)
SWEP.HolsterAng = Angle(0, 30, -15)

SWEP.Bipod_Integral = true
SWEP.BipodDispersion = 1
SWEP.BipodRecoil = 1 

SWEP.InBipodPos = Vector(-8, 0, -4)
SWEP.InBipodMult = Vector(2, 1, 1)

SWEP.BarrelLength = 35

-- Attachments 
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["grip_attach"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["muzzle_attach"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["vibroknife"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
    ["sw_sling"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
}


SWEP.Attachments = {
    {
        PrintName = "Optic",
        Slot = {"optic", "kraken_holohud"},
        Bone = "Weapon",
        Offset = {
            vpos = Vector(-0.05, 1, 2.15),
            vang = Angle(0, -90, 0),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol", "tac"},
        Bone = "Weapon",
        Offset = {
            vpos = Vector(-0.8, 26, 1),
            vang = Angle(0, -90, -90),
        },
    },
    {
        PrintName = "Muzzle",
        InstalledEles = {"muzzle_attach"},
        VMScale = Vector(1.6, 1.6, 1.6),
        WMScale = Vector(1.6, 1.6, 1.6),
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "Weapon",
        Offset = {
            vpos = Vector(-0.05, 28, 1.1),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_sniper"},
    },   
    {
        PrintName = "Underbarrel",
        Slot = {"vibroknife", "sw_sling"},
        Bone = "Weapon",
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
    {
        PrintName = "Ammunition",
        Slot = {"ammo"}
    },
    {
        PrintName = "Perk",
        Slot = "perk",
    },
    {
        PrintName = "Charm",
        Slot = {"charm"},
        Bone = "Weapon",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1.09, -0, -0.39),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        Bone = "Weapon",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(0.45, -5.3, 1),
            vang = Angle(0, -90, 0),
        },
    },
}


-- Animations
local path = "arccw/kraken/republic/valken38/handling/"

SWEP.Animations = {
    ["idle"] = { Source = "base_idle" },
    ["idle_empty"] = { Source = "empty_idle" },
    ["fire"] = { Mult = 0.667, Source = {
        "base_fire",
        "base_fire2",
    } },
    ["fire_iron"] = { Mult = 0.667, Source = {
        "iron_fire_1",
        "iron_fire_2",
        "iron_fire_3",
    } },
    ["fire_empty"] = { Mult = 1, Source = "base_firelast" },
    ["fire_iron_empty"] = { Mult = 1, Source = "iron_firelast" },
    ["dryfire"] = { Source = "base_dryfire" },
    ["dryfire_iron"] = { Source = "iron_dryfire" },
    ["bash"] = { Source = "base_melee_end" },
    ["bash_empty"] = { Source = "base_melee_end_empty" },
    ["reload"] = { Source = "base_reload", TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, MinProgress = 0.75, SoundTable = {
        {s = "ArcCW_Kraken.Overheat", t = 42 / 33},
        {s = "ArcCW_Kraken.OverheatReplenished", t = 120 / 33},
        {t = 35 / 33, s = path .. "magrelease.wav"},
        {t = 40 / 33, s = "weapon_hand/reload_heavy/mag_eject/023d-00000071.mp3"},
        {t = 50 / 33, s = path .. "mag_fetch.wav"},
        {t = 107 / 33, s = "weapon_hand/reload_heavy/mag_load/0215-00001ecc.mp3"},
        {t = 117 / 33, s = "weapon_hand/reload_heavy/locknload/0215-00001edb.mp3"},
        {t = 142 / 33, s = path .. "rattle.wav"},
    } },
    ["draw"] = { Source = "base_draw",         SoundTable = {
        {
            s = "ArcCW_Kraken.Draw",
            p = 100,
            v = 100,
            t = 0.1,
            c = CHAN_ITEM,
        },
    } },
    ["holster"] = { Source = "base_holster",  SoundTable = {
        {
            s = "ArcCW_Kraken.Holster",
            p = 100,
            v = 100,
            t = 0.1,
            c = CHAN_ITEM,
        },
    } },
    ["enter_bipod"] = { Source = "deployed_in", SoundTable = {
        {t = 0},
    } },
    ["exit_bipod"] = { Source = "deployed_out", SoundTable = {
        {t = 0},
    } },
    ["idle_bipod"] = { Source = "deployed_idle" },
    ["idle_iron_bipod"] = { Source = "deployed_iron_idle" },
    ["idle_bipod_empty"] = { Source = "deployed_idle_empty" },
    ["idle_iron_bipod_empty"] = { Source = "deployed_iron_idle_empty" },
    ["bipod"] = { Source = {
        "deployed_fire_1",
        "deployed_fire_2"
    } },
    ["fire_iron_bipod"] = { Source = {
        "deployed_iron_fire_1",
        "deployed_iron_fire_2"
    } },
}
