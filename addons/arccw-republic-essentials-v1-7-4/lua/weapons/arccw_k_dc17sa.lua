AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DC-17sa"
SWEP.Trivia_Class = "Hand Blaster"
SWEP.SubCategory = "1Pistols"
SWEP.Trivia_Desc = "The DC-17 repeater hand blaster, also known more simply as the DC-17 hand blaster or DC-17 blaster pistol, was a model of heavy blaster pistol and the Grand Army of the Republic's standard-issue sidearm. Produced by BlasTech Industries, the DC-17 was usually given to weapon teams, the crews of vehicles, and officers. The weapon was one of the most reliable and toughest models of blaster pistols created, as well as having remarkable stopping power in its small design. The weapon was also well balanced, possessed a respectable rate of fire, and lightweight."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00011000000"
SWEP.DefaultWMBodygroups = "00011000000"

SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.NoHideLeftHandInCustomization = false

SWEP.ViewModel = "models/arccw/kraken/republic/v_dc17s.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_dc17s.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-16, 5, -3.4),
    ang = Angle(-10, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 15
SWEP.HeatDissipation = 2
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.5
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

SWEP.Damage = 22
SWEP.DamageMin = 19
SWEP.RangeMin = 0
SWEP.Range = 180
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 25

SWEP.Recoil = 0.9
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.55

SWEP.Delay = 60 / 250
SWEP.Num = 1
SWEP.Firemode = 2
SWEP.Firemodes = {
    {
		Mode = 2,
    },
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
SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.30

-- Ammo, Sounds & MuzzleEffect

SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0

SWEP.ShootSound = "ArcCW_Kraken.SW_DC17"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DC17_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_pistol_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 255)

-- Ironsight & Holdtype
SWEP.IronSightStruct = {
    Pos = Vector(-3.79, -6.251, 0.86),
    Ang = Vector(0, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
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

SWEP.BarrelLength = 25

SWEP.AttachmentElements = {
    ["dc17_powerpack"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["dc17_cooling"] = {
        VMBodygroups = {{ind = 4, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        Slot = {"optic", "kraken_holohud"},
        Bone = "Slide",
        InstalledEles = {"scope_attach"},
        Offset = {
            vpos = Vector(-2, 4.8, 0.13),
            vang = Angle(180,0,90),
        },
        VMScale = Vector(1.25, 1.25, 1.25),
    },
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol", "tac"},
        Bone = "frame",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(-6, 1.56, 0.15),
            vang = Angle(180,0,90),
        },
        ExtraSightDist = 9,
        CorrectivePos = Vector(1, 0, -1),
    },
    {
        PrintName = "Muzzle",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        VMScale = Vector(1.2, 1.2, 1.2),
        WMScale = Vector(1.2, 1.2, 1.2),
        Bone = "frame",
        Offset = {
            vpos = Vector(-9.3, 2.8, 0.11),
            vang = Angle(180,0,90),
        },
    },
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_pistol"},
    },   
    {
        PrintName = "Ammunition",
        Slot = {"ammo"},
    },
    {
        PrintName = "Powerpack",
        Slot = {"dc17_powerpack"},
    },
    {
        PrintName = "Cooling System",
        Slot = {"dc17_cooling"},
    },
    {
        PrintName = "Perk",
        Slot = "perk",
    },
    {
        PrintName = "Internal Modifications",
        Slot = "uc_fg",
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
    {
        PrintName = "Charm",
        Slot = {"charm"},
        Bone = "frame",
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Offset = {
            vpos = Vector(-7, 3.05, -0.5),
            vang = Angle(180,0,90),
        },
    },     
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        Bone = "frame",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(0.2, 2.18, -0.75),
            vang = Angle(180,0,90),
        },
    },     
}


SWEP.Animations = {
    ["idle"] = {
        Source = "idle"
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {s = "weapon_hand/reload_gentle/hits_and_grabs/023d-00000b29.mp3", t = 0.1 / 10},
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = "weapon_hand/reload_heavy/mag_load/023d-00000f0b.mp3", t = 0.1 / 10},
        },
    },
    ["ready"] = {
        Source = "draw",
        SoundTable = {
            {s = "weapon_hand/reload_gentle/hits_and_grabs/023d-00000b29.mp3", t = 0.1 / 10},
        },
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
            {s = "weapon_hand/reload_gentle/mag_eject/023d-000005d8.mp3", t = 5 / 30},
            {s = "weapon_hand/reload_gentle/mag_eject/023d-000006a5.mp3", t = 30 / 30},
            {s = "weapon_hand/reload_gentle/mag_load/023d-00000607.mp3", t = 40 / 30},
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 50 / 30},
        },
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
