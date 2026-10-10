AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 4

SWEP.Category = "[ArcCW] Kraken's Special Forces"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Amban Pulse Rifle"
SWEP.Trivia_Class = "Blaster Rifle"
SWEP.SubCategory = "3Rifles"
SWEP.Trivia_Desc = "The Amban phase-pulse blaster, also known as an Amban sniper rifle, was a type of disruptor sniper rifle used by the Mandalorian bounty hunter Din Djarin. The weapon was capable of electrocuting opponents as well as completely disintegrating targets. It was also capable of listening to conversations at least a house away. Djarin used the deadly weapon to great effect during his bounty hunting career."
SWEP.IconOverride = "entities/kraken/sops/mandorifle.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "000000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sops/new/v_mandalorianrifle.mdl"
SWEP.WorldModel = "models/arccw/kraken/sops/world/w_mandalorianrifle.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-6, 5, -3.5),
    ang = Angle(-10, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1.2,
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

SWEP.Damage = 150
SWEP.DamageMin = 50
SWEP.RangeMin = 0
SWEP.Range = 900
SWEP.Penetration = 10
SWEP.DamageType = DMG_DISSOLVE
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 250, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "nio_tracer"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 2

SWEP.Recoil = 1.5
SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 1.5
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

SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 100
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
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SOPS_GALACTIC_MANDORIFLE"
SWEP.DistantShootSound = "ArcCW_Kraken.SOPS_GALACTIC_MANDORIFLE_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_green"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 250, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-4.398, 0, 0.938),
    Ang = Angle(0, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "ar2"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.SprintPos = Vector(2, -1, 0)
SWEP.SprintAng = Angle(-10, 26, 0)

SWEP.CustomizePos = Vector(10, 0, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)


SWEP.ActivePos = Vector(-3, 0, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 45
-- Attachments
SWEP.Attachments = {     
    {
        PrintName = "Internal Compression",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
        Bone = "weapon",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Offset = {
            vpos = Vector(20, -1.4, 0.2),
            vang = Angle(0, 0, 180),
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
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.6, 0.6, 0.6),
        Bone = "weapon",
        Offset = {
            vpos = Vector(2.3, -1.2, -0.55),
            vang = Angle(0, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Bone = "weapon",
        Offset = {
            vpos = Vector(9.5, -1.5, -0.5),
            vang = Angle(0, 0, -90),
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
        Source = "idle",
    },
    ["idle_iron"] = {
        Source = false,
    },
	["fire"] = {
        Source = {"shoot"},
        Mult = 2,
    },
    ["fire_iron"] = {},
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0,
		SoundTable = {
                        {s = "ArcCW_Kraken.Overheat", t = 0.50 },
						{s = "kraken/sops_new/mandorifle/draw.wav", t = 0},
						{s = "kraken/sops_new/mandorifle/leverdown_i.wav", t = 0.48},
						{s = "kraken/sops_new/mandorifle/insert_i.wav", t = 0.83},
                        {s = "ArcCW_Kraken.OverheatReplenished", t = 2 },
						{s = "kraken/sops_new/mandorifle/leverup_i.wav", t = 1.7},
					},
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {
                s = "kraken/sops_new/mandorifle/draw.wav",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {
                s = "ArcCW_Kraken.Holster",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
}
