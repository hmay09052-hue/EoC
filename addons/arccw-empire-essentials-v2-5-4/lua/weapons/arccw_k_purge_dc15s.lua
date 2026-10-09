AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Purge DC-15s"
SWEP.Trivia_Class = "Blaster, Carbine"
SWEP.SubCategory = "2Carbines"
SWEP.Trivia_Desc = "The DC-15S was the blaster carbine variant of BlasTech's DC-15A blaster rifle, not to be confused with the DC-15A itself. This weapon was carried by the clone troopers of the Galactic Republic during the Clone Wars. It was also in service in the earlier years of the Galactic Empire."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.IconOverride = "entities/kraken/empire-essentials/purge_dc15s.png"

-- Viewmodel & Entity Properties
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 35
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.5
SWEP.HeatFix = true

SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.NoHideLeftHandInCustomization = false

SWEP.ViewModel = "models/arccw/kraken/empire/v_dc15si.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_dc15si.mdl"
SWEP.ViewModelFOV = 54
SWEP.WorldModelOffset = {
    pos = Vector(-9, 3.5, -4.5),
    ang = Angle(-10, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
}

-- Damage & Tracer
SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2,
    [HITGROUP_CHEST] = 1.5,
    [HITGROUP_STOMACH] = 1,
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
SWEP.Tracer = "new_tracer_red"
SWEP.TracerCol = Color(250, 0, 0)
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 40

SWEP.Recoil = 0.65
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.55

SWEP.Delay = 60 / 250
SWEP.Num = 1
SWEP.Firemode = 1
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



-- Sounds & Muzzleflash
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 125
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_DC15_EMPIRE_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_DC15_EMPIRE_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = nil
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight & Holdtype
SWEP.IronSightStruct = {
    Pos = Vector(-2.92, -3.138, 1.858),
    Ang = Vector(0.4, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
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
    ["grip"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Sight", 
        DefaultAttName = "DC-15 Holosight",
        Slot = "optic",
        Bone = "DC15",
        InstalledEles = {"scope_attach"},
        Offset = {
            vpos = Vector(-0.1, -1.35, 4.9),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "DC15",
        Offset = {
            vpos = Vector(0.02, -0.442, 11.638),
            vang = Angle(90, 0, -90),

        },
    },  
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "DC15", 
        Offset = {
            vpos = Vector(-0.8, -0.5, 7),
            vang = Angle(90, 0, 180),
        },
    },  
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        Bone = "DC15",
        InstalledEles = {"grip"},
        Offset = {
            vpos = Vector(-0.101, 0.15, 5),
            vang = Angle(90, 0, -90),
        },       
    },
    {
        PrintName = "Mode",
        DefaultAttName = "None",
        Slot = {"sw_mode", "sw_mode_rifle"},
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
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "DC15",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(1, -0.2, -7),
            vang = Angle(90, 0, -90),
        },
    },      
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
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
