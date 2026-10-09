AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "E-5s"
SWEP.Trivia_Class = "Blaster, Longblaster"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "E-5s sniper rifles were a model of sniper rifle and longblaster used by sharpshooters of the Confederacy of Independent Systems and the Galactic Empire. They saw action under the Separatist Droid Army during the Clone Wars on the planet Felucia. To target opponents attempting to take cover, a B1-series battle droid took up position and used the rifle from a distance. A tubular device was used to connected the rifle's targeting scope to a battle droid's photoreceptors, which saw through red electrobinoculars."
SWEP.Trivia_Manufacturer = "Baktoid Armor Workshop"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Confederacy of Independent Systems"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/cis/v_e5s.mdl"
SWEP.WorldModel = "models/arccw/kraken/cis/world/w_e5s.mdl"

SWEP.MirrorWorldModel = nil
SWEP.ViewModelFOV = 54


SWEP.WorldModelOffset = {
    pos = Vector(-9, 4, -3),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1.2,
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

SWEP.Damage = 143
SWEP.DamageMin = 98
SWEP.RangeMin = 0
SWEP.Range = 700
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_red"
SWEP.TracerCol = Color(250, 0, 0)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 10

SWEP.Recoil = 1.8
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 2
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1.5
SWEP.RecoilVMShake = 2

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

SWEP.AccuracyMOA = 1
SWEP.HipDispersion = 100
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

SWEP.ShootSound = "ArcCW_Kraken.SW_E5S"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_E5S_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.8, -9.875, 0.4),
    Ang = Vector(2.8, 0, -0.21),
     Magnification = 2,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(-2, -4, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4, -3, -1)
SWEP.SprintAng = Angle(0, 30, -15)

SWEP.CustomizePos = Vector(15, -5, 5)
SWEP.CustomizeAng = Angle(0, 40, 30)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Angle(0, 30, -15)

SWEP.BarrelLength = 45

-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        Slot = {"optic"}, 
        Bone = "v_weapon.awp_parent",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.15, -4.7, 6.9),
            vang = Angle(90, 0, -90),
        },
        CorrectiveAng = Angle(0, 0, 0),
        CorrectivePos = Vector(0, 0, 0),
    },          
    {
        PrintName = "Internal Compression",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
    },  
    {
        PrintName = "Tactical",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "v_weapon.awp_parent", 
        Offset = {
            vpos = Vector(0.15, -2.7, 30),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Internal Modifications",
        Slot = "uc_fg",
    },  
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_sniper"},
    },    
    {
        PrintName = "Ammunition", 
        Slot = "ammo",
    },
    {
        PrintName = "Perk",
        Slot = "perk",
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
    {
        PrintName = "Charms",
        Slot = {"charm"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "v_weapon.awp_parent",
        Offset = {
            vpos = Vector(0.65, -2, 2),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        Slot = {"killcounter"},
        Bone = "v_weapon.awp_parent",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(0.7, -2, 7),
            vang = Angle(90, 0, -90),
        },
    },         
}

-- Don't touch this unless you know what you're doing
local path = "arccw/kraken/republic/e5s/handling/"

SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["fire_iron"] = {},
    ["fire"] = {
        Source = {"shoot1"},
    },
    ["fire_sights"] = {
        Source = {"shoot1_ads"},
    },
    ["reload"] = {
        Source = "reload_short2",
		MinProgress = 0.65,
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = path .. "clipout.ogg", t = 7/30},
            {s = path .. "clipin.ogg", t = 40/30},
            {s = path .. "cliphit.ogg", t = 45/30},
        },
    },
    ["draw"] = {
        Source = "draw_short",
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
    ["idle"] = {
        Source = "idle",
    },
    ["enter_sights"] = {
        Source = "idle",
    },
    ["exit_inspect"] = {
        Source = "lookat01",
        MinProgress = 0.9,
        FireASAP = true,
        SoundTable = {
            {s = "arccw/kraken/republic/movement1.wav", t = 5/30},
            {s = "arccw/kraken/republic/movement2.wav", t = 91/30},
            {s = "arccw/kraken/republic/movement3.wav", t = 116/30},
        },
    },
    ["bash"] = {
        Source = {"melee", "melee2", "melee3"},
    },
}
