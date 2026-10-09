AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "CA-87"
SWEP.Trivia_Class = "Blaster, Rifle"
SWEP.SubCategory = "6Shotguns"
SWEP.Trivia_Desc = "Old weapon. Multiple blaster shoots. Destructive at short-range battles."
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.IconOverride = "entities/kraken/empire-essentials/c88.png"

-- Viewmodel & Entity Properties
SWEP.ManualAction = true -- pump/bolt action
SWEP.NoLastCycle = false -- do not cycle on last shot
SWEP.HybridReload = true -- reload normally when empty, reload like shotgun when part full
SWEP.ReloadInSights = true
SWEP.HideViewmodel = false
SWEP.UseHands = true
SWEP.DefaultBodygroups = "010"
SWEP.ViewModel = "models/arccw/kraken/empire/w_ca88.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_ca88.mdl"
SWEP.WMOverride = "models/arccw/kraken/empire/w_ca88.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 0.009
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

SWEP.Damage = 30
SWEP.DamageMin = 15
SWEP.RangeMin = 0
SWEP.Range = 250
SWEP.Penetration = 8
SWEP.DamageType = DMG_BUCKSHOT
SWEP.MuzzleVelocity = 900

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 250, 0)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_green"
SWEP.HullSize = 0.2

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 5

SWEP.Recoil = 1.2
SWEP.RecoilSide = 0.2
SWEP.RecoilRise = 0.76
SWEP.RecoilPunch = 1.7

SWEP.Delay = 60 / 80
SWEP.Num = 3
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
        PrintName = "SINGLE-PLASMA",
    },
	{
		Mode = 0,
   	}
}

SWEP.AccuracyMOA = 15
SWEP.HipDispersion = 500
SWEP.MoveDispersion = 125
SWEP.SightsDispersion = 0
SWEP.JumpDispersion = 200

-- Speed Mult
SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.77
SWEP.ShootSpeedMult = 0.80

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_SCATTER_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_SCATTER_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_green"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 250, 0)
SWEP.MuzzleEffectAttachment = 1
SWEP.CaseEffectAttachment = 2
SWEP.ShellModel = "models/shells/shell_556.mdl"

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.3, -3, 0.9),
    Ang = Angle(0, -0.5, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 4, 2)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 4, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 20

-- Attachments
SWEP.DefaultElements = {"dc15"}
SWEP.AttachmentElements = {
    ["dc15"] = {
        WMElements = {
            {
                Model = "models/arccw/kraken/empire/w_ca88.mdl",
                Bone = "ValveBiped.Bip01_R_Hand",
                Scale = Vector(1.1, 1.1, 1.1),
                WBodygroups = {{ind = 0, bg = 0}},
                Offset = {
                    pos = Vector(-700, 500, -400),
                    ang = Angle(-15, 0, 180)
                }
            },
            {
                Model = "models/hunter/plates/plate.mdl",
                Bone = "ValveBiped.Bip01_R_Hand",
                Scale = Vector(0, 0, 0),
                Offset = {
                    pos = Vector(4150, 0, -1100),
                    ang = Angle(-15, 0, 100)
                },
                IsMuzzleDevice = true
            },
        },
    },
}

SWEP.Attachments = {
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        WMScale = Vector(111, 111, 111),
        VMScale = Vector(0.7, 0.7, 0.7),
        Bone = "Weapon",
        Offset = {
            vpos = Vector(6, 0.3, -0.7),
            vang = Angle(0, 0, 0),
            wpos = Vector(2200, 190, -740),
            wang = Angle(-15, 0, -90)
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
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(111, 111, 111),
        Bone = "Weapon",
        Offset = {
            vpos = Vector(-1, 0.5, -0.9),
            vang = Angle(0, 0, -90),
            wpos = Vector(1700, 180, -600),
            wang = Angle(-15, 0, 180)
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(111, 111, 111),
        Bone = "Weapon",
        Offset = {
            vpos = Vector(-5, 0.5, -0.9),
            vang = Angle(0, 0, -90),
            wpos = Vector(800, 200, -300),
            wang = Angle(-15, 0, 180)
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
SWEP.BulletBones = {
    [1] = "Bullet_1",
    [2] = "Bullet_2",
}

local path = "arccw/kraken/empire/ca88/handling/"

local bulletin = {
    path .. "bulletin_1.wav",
    path .. "bulletin_2.wav",
    path .. "bulletin_3.wav",
    path .. "bulletin_4.wav",
}

SWEP.Animations = {
    ["idle"] = { Source = "idle" },
    ["idle_empty"] = { Source = "empty_idle" },
    ["idle_uncycled"] = { Source = "empty_idle" },
    ["fire"] = { Source = "base_fire_start" },
    ["fire_empty"] = { Source = "base_fire_last" },
    ["fire_iron"] = { Source = "iron_fire_start" },
    ["fire_iron_empty"] = { Source = "iron_fire_last" },
    ["dryfire"] = { Source = "base_dryfire" },
    ["dryfire_iron"] = { Source = "iron_dryfire" },
    ["bash"] = { Source = "base_melee_bash" },
    ["cycle"] = { Source = "base_fire_end", ShellEjectAt = false, MinProgress = 0.5, SoundTable = {
        {t = 13 / 38, s = path .. "boltrelease.wav"},
        {t = 14 / 38, s = path .. "boltback.wav"},
        {t = 22 / 38, s = path .. "boltforward.wav"},
        {t = 26 / 38, s = path .. "boltlatch.wav"},
    } },
    ["cycle_iron"] = { Source = "iron_fire_end", ShellEjectAt = false, MinProgress = 0.5, SoundTable = {
        {t = 13 / 38, s = path .. "boltrelease.wav"},
        {t = 14 / 38, s = path .. "boltback.wav"},
        {t = 22 / 38, s = path .. "boltforward.wav"},
        {t = 26 / 38, s = path .. "boltlatch.wav"},
    } },
    ["ready"] = { Source = "base_ready", MinProgress = 0.65, FireASAP = true, SoundTable = {
        {t = 0 / 33, s = "arccw/kraken/empire/draw_pistol.wav"},
        {t = 27 / 33, s = path .. "boltrelease.wav"},
        {t = 36 / 33, s = path .. "boltback.wav"},
        {t = 52 / 33, s = path .. "boltforward.wav"},
        {t = 60 / 33, s = path .. "boltlatch.wav"},
        {t = 86 / 33, s = path .. "rattle.wav"},
    } },
    ["draw"] = { Source = "base_draw", SoundTable = {
        {t = 0, s = "arccw/kraken/empire/draw_pistol.wav"},
    } },
    ["holster"] = { Source = "base_holster", SoundTable = {
        {t = 0, s = "arccw/kraken/empire/draw_pistol.wav"},
    } },
    ["draw_empty"] = { Source = "base_draw_empty", SoundTable = {
        {t = 0, s = "arccw/kraken/empire/draw_pistol.wav"},
    } },
    ["holster_empty"] = { Source = "base_holster_empty", SoundTable = {
        {t = 0, s = "arccw/kraken/empire/draw_pistol.wav"},
    } },
    ["reload"] = { Source = "base_reload_full_clip", TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, SoundTable = {
        {t = 2 / 35, s = path .. "boltrelease.wav"},
        {t = 12 / 35, s = path .. "boltback.wav"},
        {t = 50 / 35, s = path .. "magfetch.wav"},
        {t = 65 / 35, s = path .. "magin.wav"},
        {t = 80 / 35, s = path .. "roundsin.wav"},
        {t = 100 / 35, s = path .. "clipremove.wav"},
        {t = 125 / 35, s = path .. "boltforward.wav"},
        {t = 135 / 35, s = path .. "boltlatch.wav"},
    } },
    ["sgreload_start"] = { Source = "base_reload_start_empty", Mult = 1, ShellEjectAt = 0.85, SoundTable = {
        {t = 19 / 38.5, s = path .. "boltrelease.wav"},
        {t = 27 / 38.5, s = path .. "boltback.wav"},
    } },
    ["sgreload_insert"] = { Source = "base_reload_insert", MinProgress = 0.5, SoundTable = {
        {t = 14 / 40.2, s = bulletin},
    } },
    ["sgreload_finish"] = { Source = "base_reload_end", SoundTable = {
        {t = 12 / 38.5, s = path .. "boltforward.wav"},
        {t = 21 / 38.5, s = path .. "boltlatch.wav"},
    } },
}
