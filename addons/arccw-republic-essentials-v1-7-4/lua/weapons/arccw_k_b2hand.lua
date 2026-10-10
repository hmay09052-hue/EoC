AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "B2 Handblaster"
SWEP.Trivia_Class = "Blaster, Handblaster"
SWEP.SubCategory = "1Pistols"
SWEP.Trivia_Desc = "B2-series super battle droids, also known as B2 super battle droids, were an advanced battle droid used by the Confederacy of Independent Systems during the Clone Wars. Although one model of the B2-series was only equipped with wrist blasters on their right forearm, another was outfitted with wrist blasters on both forearms. Super battle droids were much stronger than their predecessors, and like the updated B1s used by the Confederacy, they did not require a command system to operate, which gave the droids limited independence. Another improvement was their thick armor casing, which contained their fragile sensors. However, B2s were designed with simple processors, limiting their ability to formulate strategies. As a result, they relied on organic commanders or tactical droids in order to effectively operate. The B2 was much stronger than the B1s, with enough strength to lift a clone trooper off the ground."
SWEP.Trivia_Manufacturer = "Baktoid Armor Workshop"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Confederacy of Independent Systems"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00000000000000"

SWEP.MirrorVMWM = true
SWEP.UseHands = false
SWEP.ViewModel = "models/arccw/kraken/cis/v_b2hand.mdl"
SWEP.WorldModel = "models/arccw/kraken/cis/w_b2hand.mdl"

SWEP.MirrorWorldModel = nil
SWEP.ViewModelFOV = 54


SWEP.WorldModelOffset = {
    pos = Vector(-19, 7, -4.54),
    ang = Angle(-15, 0, 200),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 20
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

SWEP.Damage = 52
SWEP.DamageMin = 34
SWEP.RangeMin = 0
SWEP.Range = 200
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.Tracer = "new_tracer_red"
SWEP.TracerCol = Color(250, 0, 0)

SWEP.HullSize = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 50

SWEP.Recoil = 0.5
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6

SWEP.Delay = 60 / 300
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
SWEP.HipDispersion = 150
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

SWEP.FirstShootSound = "ArcCW_Kraken.SW_B2HAND"
SWEP.ShootSound = "ArcCW_Kraken.SW_B2HAND"
SWEP.DistantShootSound = "ArcCW_Kraken.HeavyCorebass"
SWEP.ShootSoundSilenced = "armas/disparos/dc19.wav"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_pistol_red"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-4.851, -1.285, 0.674),
    Ang = Vector(0, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "pistol"
SWEP.HoldtypeSights = "ar2"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.SprintPos = Vector(2, -1, 0)
SWEP.SprintAng = Angle(-10, 26, 0)

SWEP.CustomizePos = Vector(10, 0, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.ActivePos = Vector(-3, -5, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 25

-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["scope_attach"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
}

SWEP.Attachments = {
    {
        PrintName = "Mode",
        Slot = {"sw_mode", "sw_mode_rifle"},
    },   
    {
        PrintName = "Internal Modifications",
        Slot = "uc_fg",
    },   
    {
        PrintName = "Ammunition", 
        Slot = "b2_ammo",
    },
    {
        PrintName = "Perk",
        Slot = "perk",
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
        Source = "idle"
    },
    ["fire"] = {
        Time = 0.6,
        Source = {"shoot"},
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
        Mult = 2.2,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
    ["fix"] = {
        Source = "overheat", 
        Mult = 2.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
}
