AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Purge DC-15a"
SWEP.Trivia_Class = "Blaster, Rifle"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "The DC-15A blaster rifle was a long heavy blaster rifle that was capable of firing blue-colored blaster bolts. It weighed 4.15 kilograms and was almost fully black in color. It had a magnatomic adhesion grip and a nonconducting stock, which was weighted to improve the weapon's overall balance and to help reduce recoil."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Galactic Republic"
SWEP.IconOverride = "entities/kraken/empire-essentials/purge_dc15a.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "000"

SWEP.UseHands = true
SWEP.MirrorVMWM = true

SWEP.HideBones = {"Mag_Ball"}
SWEP.ReloadHideBoneTables = {[1] = {}}

SWEP.NoHideLeftHandInCustomization = false
SWEP.ViewModel = "models/arccw/kraken/empire/v_dc15ai.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_dc15ai.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-13, 5, -5),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
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

SWEP.Damage = 36
SWEP.DamageMin = 24
SWEP.RangeMin = 0
SWEP.Range = 300
SWEP.Penetration = 1
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.PhysTracerProfile = 1
SWEP.Tracer = "new_tracer_red"
SWEP.TracerCol = Color(250, 0, 0)

SWEP.HullSize = 0.2
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 50

SWEP.Recoil = 0.2
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.4

SWEP.Delay = 60 / 300
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


SWEP.AccuracyMOA = 5
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 150 
SWEP.JumpDispersion = 200


-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
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

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-4.665, -20, 2.8),
    Ang = Vector(0, 0, 0),
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

SWEP.ActivePos = Vector(0, 0, 2)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4, -3, -1)
SWEP.SprintAng = Angle(0, 30, -15)

SWEP.CustomizePos = Vector(15, -5, 5)
SWEP.CustomizeAng = Angle(0, 40, 30)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Angle(0, 30, -15)

SWEP.BarrelLength = 40

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMElements = {
            {
                Model = "models/hunter/plates/plate.mdl",
                Bone = "Barrel",
                Scale = Vector(0, 0, 0),
                Offset = {
                    pos = Vector(0, 30, 0),
                    ang = Angle(0, -90, 0)
                },
                IsMuzzleDevice = true
            },
        },
    },
    ["grip_attach"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
}

SWEP.Attachments = {         
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "Barrel",
        Offset = {
            vpos = Vector(0.66, 29, 0.5),
            vang = Angle(0, -90, 0),
        },
    },  
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "Barrel", 
        Offset = {
            vpos = Vector(-0.5, 25, 0.6),
            vang = Angle(-90, -90, 0),
        },
    },  
    {
        PrintName = "Foregrip",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        Bone = "Barrel",
        InstalledEles = {"grip_attach"},
        Offset = {
            vpos = Vector(0.66, 6, -0.7),
            vang = Angle(0, -90, 0),
        },
    },    
    {
        PrintName = "Mode",
        DefaultAttName = "None",
        Slot = {"sw_mode", "sw_mode_rifle"},
    },   
    {
        PrintName = "Internal Modifications",
        DefaultAttName = "None",
        Slot = "uc_fg",
    },   
    {
        PrintName = "Ammunition", 
        DefaultAttName = "Standard",
        Slot = "ammo",
    },
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
    },
    {
        PrintName = "Charms",
        DefaultAttName = "None",
        Slot = {"charm"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "Barrel",
        Offset = {
            vpos = Vector(1.59, 6.2, 1.4),
            vang = Angle(0, -90, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "dc15a_DC15_mat",
        Offset = {
            vpos = Vector(1.2, -9, 0.6),
            vang = Angle(0, -90, 0),
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
        Time = 1,
        Source = {"shoot", "shoot2"},
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
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.7,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {hide = 1, t = 0},
            {s = "weapon_hand/023d-00000d8a.mp3", t = 1 / 30},
            {s = "weapon_hand/reload_heavy/mag_eject/0215-00001ec8.mp3", t = 5 / 30},
            {s = "weapon_hand/reload_heavy/mag_eject/0215-00001ed0.mp3", t = 27 / 30},
            {s = "weapon_hand/reload_heavy/mag_eject/023d-00000071.mp3", t = 30 / 30},
            {s = "weapon_hand/reload_heavy/mag_load/023d-0000059a.mp3", t = 55 / 30},
            {s = "ArcCW_Kraken.Overheat", t = 5 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 65 / 30},
            {s = "ArcCW_Kraken.Grab", t = 70 / 30},
            {hide = 0, t = 70 / 30},
        },
    },
    ["fix"] = {
        Source = "overheat", 
        Mult = 4.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
}
