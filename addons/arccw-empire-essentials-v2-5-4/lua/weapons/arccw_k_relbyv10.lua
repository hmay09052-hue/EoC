AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Relby V-10"
SWEP.Trivia_Class = "Blaster, Long Rifle"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The Relby-v10 micro grenade launcher, also known as the Relby-v10 mortar gun and Relby V-10 Grenade Launcher, was a model of blaster rifle/grenade launcher that was used by the Trandoshan bounty hunter Bossk. It was also used by Bossk's father, Cradossk. Aside from Bossk famously using the weapon, some marksmen of both the Rebel Alliance and the Galactic Empire used the Relby-v10. The Relby V-10 can be configurated firing grenades to firing blaster bolts."
SWEP.Trivia_Manufacturer = "Unknown"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Rebel Alliance"
SWEP.IconOverride = "entities/kraken/empire-essentials/relbyv10.png"

-- Viewmodel & Entity Properties
SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_relbyv10.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_relbyv10.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-7, 4, -3.7),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
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

SWEP.Damage = 67
SWEP.DamageMin = 29
SWEP.RangeMin = 0
SWEP.Range = 459
SWEP.Penetration = 15
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 250, 0)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_green"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 30

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.65

SWEP.Delay = 60 / 210
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
SWEP.HipDispersion = 180
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

SWEP.ShootSound = "arccw/kraken/new_empire/relbvy/v10/relbyv10_laser.wav"
SWEP.DistantShootSound = "arccw/kraken/new_empire/relbvy/v10/relbyv10_laser.wav"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_green"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 250, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.185, 0, 2.5),
    Ang = Angle(0, 0, -3.941),
    Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
    ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(0, 3, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -3)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(15, 0, -1.321)
SWEP.CustomizeAng = Angle(18.2, 39.4, 14.8)

SWEP.HolsterPos = Vector(4, -3, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 35

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
   ["muzzle"] = {
        VMElements = {
            {
                Model = "models/hunter/plates/plate.mdl",
                Bone = "E11S_CONTR",
                Scale = Vector(0, 0, 0),                
                Offset = {
                    pos = Vector(0, 14, -0.5),
                    ang = Angle(-90, -90, 0)
                },
                IsMuzzleDevice = true
            }
         }, 
    }
}

SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "Iron Sight",
        Slot = "optic",
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(-0.15, -2.5, 0.5),
            vang = Angle(0, -90, 0),
        },
        CorrectiveAng = Angle(0, 180, 0),
        CorrectivePos = Vector(0, 0, 0),
        InstalledEles = {"e11_scope"},
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(0.3, 9, -0.5),
            vang = Angle(90, -90, 0),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(-0.15, 13, -0.45),
            vang = Angle(0, -90, 0),
        },
    },  
    {
        PrintName = "Foregrip", 
        DefaultAttName = "Standard",
        Slot = "foregrip",
        Bone = "E11S_CONTR",
        VMScale = Vector(0.9, 0.9, 0.9),
        Offset = {
            vpos = Vector(-0.15, 2.2, -1.3),
            vang = Angle(0, -90, 0),
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
        VMScale = Vector(0.7, 0.7, 0.7),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(0.2, -1.25, -2),
            vang = Angle(0, -90, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        Bone = "E11S_CONTR",
        Offset = {
            vpos = Vector(0.35, -3, -0.55),
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
        Source = "idle",
    },
	["fire"] = {
        Source = "shoot",
    },
    ["fire_iron"] = {},
    ["fix"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 45 / 30},
        },
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 45 / 30},
        },
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {
                s = "ArcCW_Kraken.Draw",
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
