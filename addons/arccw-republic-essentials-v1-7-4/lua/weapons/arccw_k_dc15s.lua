AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DC-15s"
SWEP.Trivia_Class = "Blaster Carbine"
SWEP.SubCategory = "2Carbines"
SWEP.Trivia_Desc = "The DC-15S Blaster Carbine, produced by BlasTech Industries, is a semi-automatic and rapid fire blaster which also has a stun feature. As well as a unique fully-foldable stalk. The rifle was used by clone troopers throughout the Clone Wars and became the more favored weapon amongst its more powerful counterpart, the DC-15A Blaster Rifle, due to its compact size and usefulness in close quarter engagements."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Viewmodel & Entity Properties
SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.NoHideLeftHandInCustomization = false

SWEP.ViewModel = "models/arccw/kraken/republic/v_dc15s.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_dc15s.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-9, 3.5, -4.5),
    ang = Angle(-10, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 18
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.2
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

SWEP.Damage = 44
SWEP.DamageMin = 28
SWEP.RangeMin = 0
SWEP.Range = 230
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 40

SWEP.Recoil = 0.65
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

SWEP.AccuracyMOA = 0.25
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

SWEP.ShootSound = "ArcCW_Kraken.SW_DC15S"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DC15A_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 255)

-- Ironsight & Holdtype
SWEP.IronSightStruct = {
    Pos = Vector(-2.816, -1.966, 1.894),
    Ang = Vector(0, 0, 1.513),
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

SWEP.ActivePos = Vector(0, 2, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4, -3, -1)
SWEP.SprintAng = Angle(0, 30, -15)

SWEP.CustomizePos = Vector(15, 0, 5)
SWEP.CustomizeAng = Angle(0, 40, 30)

SWEP.HolsterPos = Vector(4, -3, -1)
SWEP.HolsterAng = Angle(0, 30, -15)

SWEP.BarrelLength = 30


-- Attachments 
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["vibroknife"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["grip_attach"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Sight", 
        Slot = {"optic", "kraken_holohud"},
        Bone = "DC15",
        Offset = {
            vpos = Vector(0.02, -1.1, 4.9),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Muzzle",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "DC15",
        Offset = {
            vpos = Vector(0.02, -0.442, 11.638),
            vang = Angle(90, 0, -90),

        },
    },  
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "DC15", 
        Offset = {
            vpos = Vector(-0.8, -0.5, 10.5),
            vang = Angle(90, 0, 180),
        },
    },  
    {
        PrintName = "Foregrip",
        Slot = {"foregrip", "vibroknife"},
        Bone = "DC15",
        InstalledEles = {"grip_attach"},
        Offset = {
            vpos = Vector(-0.101, 0.15, 5),
            vang = Angle(90, 0, -90),
        },       
    },
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_rifle"},
    },   
    {
        PrintName = "Ammunition",
        Slot = {"ammo", "stunmode_ammo"},
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
        Bone = "DC15",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.95, 0.05, -3.55),
            vang = Angle(90, 0, -90),
        },
    },     
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        Bone = "DC15",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1, -0.2, -7),
            vang = Angle(90, 0, -90),
        },
    },      
}

-- Don't touch this unless you know what you're doing
SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["idle"] = {
        Time = 9,
        Source = "idle",
    },
    ["fire"] = {
        Source = "fire"
    },
    ["fire_iron"] = {},
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
    ["reload"] = {
        Source = "reload", 
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
        Mult = 1.2,
        SoundTable = {
            {s = "weapon_hand/reload_heavy/mag_eject/0215-00001ece.mp3", t = 11 / 10},
            {s = "weapon_hand/reload_heavy/mag_eject/0215-00001ec8.mp3", t = 1 / 30},
            {s = "ArcCW_Kraken.Overheat", t = 5 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 37 / 30},
            {s = "ArcCW_Kraken.Grab", t = 37 / 30},
        },
    },
    ["fix"] = {
        Source = "overheat", 
        Mult = 1.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
}
