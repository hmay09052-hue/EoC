AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 2 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Purge DC-17"
SWEP.Trivia_Class = "Blaster, Pistol"
SWEP.SubCategory = "1Pistols"
SWEP.Trivia_Desc = "The DC-17 hand blaster, also known as DC-17 blaster pistol, was a heavy blaster pistol wielded by the clone troopers of the Grand Army of the Galactic Republic during the Clone Wars. An advanced firearm, it was fielded to elite soldiers in the army, most notably Advanced Recon Commandos, clone trooper commanders, and clone jet troopers."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Galactic Republic"
SWEP.IconOverride = "entities/kraken/empire-essentials/purge_dc17.png"

-- Viewmodel & Entity Properties
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.DefaultBodygroups = "00000000000"

SWEP.ViewModel = "models/arccw/kraken/empire/v_dc17i.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_dc17i.mdl"

SWEP.ViewModelFOV = 54
SWEP.WorldModelOffset = {
    pos = Vector(-16, 5, -3.4),
    ang = Angle(-10, 0, 180),
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

SWEP.Damage = 22
SWEP.DamageMin = 19
SWEP.RangeMin = 0
SWEP.Range = 220
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 35

SWEP.Recoil = 0.8
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.55

SWEP.Delay = 60 / 250
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

SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200



-- Speed Mult
SWEP.SpeedMult = 0.955
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0

SWEP.ShootSound = "ArcCW_Kraken.SW_DC17_EMPIRE_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DC17_EMPIRE_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_pistol_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.79, -6.251, 1.05),
    Ang = Vector(0, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
}

-- Holdtype
SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "pistol"
SWEP.HoldtypeSights = "revolver"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL

SWEP.SprintPos = Vector(0, -6, -9)
SWEP.SprintAng = Angle(40, 0, 0)

SWEP.CustomizePos = Vector(10, -5, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)


SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 20

-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["e11_laser"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["e11_scope"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        Slot = "optic",
        Bone = "frame",
        InstalledEles = {"scope_attach"},
        DefaultAttName = "DC-17 Holosight",
        Offset = {
            vpos = Vector(-2, 4.2, 0.13),
            vang = Angle(180,0,90),
        },
        VMScale = Vector(1.25, 1.25, 1.25),
    },
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol", "tac"},
        Bone = "frame",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(-6, 1, 0.15),
            vang = Angle(180,0,90),
        },
        ExtraSightDist = 9,
        CorrectivePos = Vector(1, 0, -1),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        VMScale = Vector(1.2, 1.2, 1.2),
        WMScale = Vector(1.2, 1.2, 1.2),
        Bone = "frame",
        Offset = {
            vpos = Vector(-7.88, 2.35, 0.11),
            vang = Angle(180,0,90),
        },
    },
    {
        PrintName = "Left Hand",
        Slot = {"mifl_fas2_akimbo", "akimbotest"},
        Bone = "Akimbo_Base",
        DefaultAttName = "None",
        Offset = {
            vpos = Vector(6, -2.8, 0.2),
            vang = Angle(0, 0, 0),
        },
        InstalledEles = {"akimbo"},
    },
    {
        PrintName = "Mode",
        DefaultAttName = "None",
        Slot = {"sw_mode", "sw_mode_pistol"},
    },   
    {
        PrintName = "Ammunition",
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
        Bone = "frame",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.3, -1, -0.45),
            vang = Angle(180,0,90),
        },
    },     
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "frame",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(-5.5, 1.7, -0.75),
            vang = Angle(180,0,90),
        },
    },     
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
SWEP.Animations = {
    ["idle"] = {
        Source = "idle"
    },
    ["draw"] = {
        Source = "draw",
    },
    ["holster"] = {
        Source = "holster",
    },
    ["ready"] = {
        Source = "draw",
    },
    ["fire"] = {
        Source = "fire1",
        ShellEjectAt = false,
    },
    ["fire_iron"] = {
        Source = "fire_scoped2",
        ShellEjectAt = false,
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        LHIK = true,
        LHIKIn = 0.4,
        LHIKOut = 0.8,
        LHIKEaseOut = 0.5,
        SoundTable = {
            {s = "arccw/kraken/empire/dc17/handling/magout.wav", t = 5 / 30},
            {s = "arccw/kraken/empire/dc17/handling/magin_partial.wav", t = 30 / 30},
            {s = "arccw/kraken/empire/dc17/handling/magin.wav", t = 40 / 30},
        },
    },
--------------------------------------------------------
    ["reload_akimbo"] = {
        Source = "reload_akimbo",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
    },
    ["reload_empty_akimbo"] = {
        Source = "reload_empty_akimbo",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
    },
    ["reload_nomen_akimbo"] = {
        Source = "reload_nomen_akimbo",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
    },
    ["reload_nomen_empty_akimbo"] = {
        Source = "reload_empty_nomen_akimbo",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
    },

    ["fix"] = {
        Source = "overheat", 
        Mult = 1.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 75 / 30},
            {s = "ArcCW_Kraken.Grab", t = 78 / 30},
        },
    },
}
