AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "A-280CFE Sniper"
SWEP.Trivia_Class = "Blaster, Sniper"
SWEP.SubCategory = "5Snipers"
SWEP.Trivia_Desc = "The A280-CFE (covert field edition) convertible heavy blaster pistol, also known as an A280-CFE blaster rifle or simply a A280-CFE blaster, was a modular version of the A280 blaster rifle. It featured a core pistol that could be reconfigured into an assault rifle or sniper rifle. Captain Cassian Andor used an A280-CFE during the Battle on Jedha, the mission to Eadu, and the Battle of Scarif."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Rebel Alliance"
SWEP.IconOverride = "entities/kraken/empire-essentials/a280cfe_sniper.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00210000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.NoHideLeftHandInCustomization = false
SWEP.ViewModel = "models/arccw/kraken/empire/v_a280cfe.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_a280cfe_sniper.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-4, 3, -4.5),
    ang = Angle(-10, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
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

SWEP.Damage = 85
SWEP.DamageMin = 32
SWEP.RangeMin = 0
SWEP.Range = 1700
SWEP.Penetration = 15
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 250, 0)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_green"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 15

SWEP.RecoilSide = 0.35
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.98

SWEP.Delay = 60 / 300
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


SWEP.AccuracyMOA = 0.1
SWEP.HipDispersion = 100
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 500

-- Speed Mult
SWEP.SpeedMult = 0.85 + 0.05
SWEP.SightedSpeedMult = 0.7 / 0.85
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult =  0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_A280CFE_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_A280CFE_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_green"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 250, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2.312, -1.443, 1.25),
    Ang = Angle(0, -0.542, 2.799),
     Magnification = 1.15,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 0, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 45

SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["e11_scope"] = {
        VMBodygroups = {{ind = 5, bg = 1}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 6, bg = 1}},
    },
}

-- Attachments
SWEP.Attachments = {
    {
        PrintName = "Optic",
        DefaultAttName = "Standard",
        Slot = "optic",
        InstalledEles = {"e11_scope"},
        Bone = "body",
        Offset = {
            vpos = Vector(0, -0.43, 1.5),
            vang = Angle(90, 0, -90),
        },
        CorrectiveAng = Angle(0, 0, 0),
        CorrectivePos = Vector(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "body",
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        InstalledEles = {"e11_laser"},
        Offset = {
            vpos = Vector(0.8, -0.15, 13.5),
            vang = Angle(90, 0, 0),
        },
    },
    {
        PrintName = "Internal Compression",
        DefaultAttName = "Sniper A-280CFE",
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
    },
    {
        PrintName = "Foregrip",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        Bone = "body",
        Offset = {
            vpos = Vector(0.1, 2.1, 11),
            vang = Angle(90, 0, -90),
        },    
    },
    {
        PrintName = "Energization",
        DefaultAttName = "Green Tibanna",
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
        Bone = "body",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.55, 1.8, -3.5),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "body",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(0.6, 2.2, 5.5),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Animations
local path = "arccw/kraken/empire/a280cfe/handling/"

SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["fire_iron"] = {},
    ["idle"] = {
        Source = "idle",
        LHIK = false,
    },
    ["ready"] = {
        Source = "ready",
        LHIK = false,
        SoundTable = {
            { s = path .. "raise.ogg", t = 0 / 30, c = ca, v = 0.8 },
            { s = path .. "chback.ogg", t = 3 / 30, c = ca, v = 0.8 },
            { s = path .. "chamber.ogg", t = 9 / 30, c = ca, v = 0.8 },
            { s = path .. "cloth_4.ogg", t = 32 / 60, c = ca },
        },
    },
    ["draw"] = {
        Source = "draw",
		FireASAP = true,
        LHIK = false,
        SoundTable = {
            { s = path .. "raise.ogg", t = 0 / 30, c = ca, v = 0.8 },
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            { s = path .. "rattle2.ogg", t = 0 / 30, c = ca, v = 0.8 },
        },
    },
    ["draw_empty"] = {
        Source = "draw_empty",
        LHIK = false,
		FireASAP = true,
        SoundTable = {
            { s = path .. "raise.ogg", t = 0 / 30, c = ca, v = 0.8 },
        },
    },
    ["holster_empty"] = {
        Source = "holster_empty",
        LHIK = false,
        SoundTable = {
            { s = path .. "rattle2.ogg", t = 0 / 30, c = ca, v = 0.8 },
        },
        IKTimeLine = { { t = 0, lhik = 1 } },
    },
    ["fire"] = {
        Source = {"fire_01","fire_02","fire_03"},
        LHIK = false,
        ShellEjectAt = false,
        SoundTable = { { s = mechh, t = 0 } },
    },
    ["fire_empty"] = {
        Source = "fire_empty",
        LHIK = false,
        ShellEjectAt = false,
        SoundTable = { { s = path .. "mech_last.ogg", t = 0 } },
    },

    -- Reloads --
    ["reload"] = {
        Source = "reload",
        LHIK = true,
		FireASAP = true,
        Mult = 1.1,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            { s = path .. "magpouch.ogg", t = 4 / 30, v = 0.4 },
            { s = path .. "movement-rifle-04.ogg", t = 0 / 30, c = ca, v = 0.8 },
            { s = path .. "magout.ogg", t = 5 / 30, c = ca, v = 0.8 },
            { s = path .. "magin.ogg", t = 20 / 30 - 0.25, c = ca, v = 0.8 },
            { s = path .. "cloth_4.ogg", t = 25 / 30, c = ca, v = 0.8 },
            { s = path .. "cloth_4.ogg", t = 32 / 30 - 0.07, c = ca, v = 0.3 },
        },
    },
    ["reload_empty"] = {
        Source = "reload_empty",
		FireASAP = true,
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Mult = 1.1,
        SoundTable = {
            { s = path .. "magpouch.ogg", t = 4 / 30, v = 0.4 },
            { s = path .. "movement-rifle-04.ogg", t = 0 / 30, c = ca, v = 0.8 },
            { s = path .. "magout.ogg", t = 5 / 30, c = ca, v = 0.8 },
            { s = path .. "magin.ogg", t = 20 / 30 - 0.3, c = ca, v = 0.8 },
            { s = path .. "cloth_1.ogg", t = 25 / 30, c = ca, v = 0.8 },
            { s = path .. "boltdrop.ogg", t = 32 / 30, c = ca, v = 0.8 },
            { s = path .. "cloth_4.ogg", t = 42 / 30 - 0.07, c = ca, v = 0.3 },
        },
    },
    -- Inspect --
    ["exit_inspect"] = {
        Source = "inspect",
        FireASAP = true,
        LHIK = true,
        MinProgress = 0.925,
        Mult = 1.2,
        SoundTable = {
            { s = path .. "cloth_4.ogg", t = 0 / 30, c = ca, v = 0.8 },
            { s = path .. "movement-rifle-03.ogg", t = 5 / 30, c = ca, v = 0.8 },
            { s = path .. "cloth_2.ogg", t = 37 / 30, c = ca, v = 0.8 },
            { s = path .. "movement-rifle-04.ogg", t = 45 / 30, c = ca, v = 0.8 },
            { s = path .. "movement-rifle-02.ogg", t = 90 / 30, c = ca, v = 0.8 },
        },
    },
}
