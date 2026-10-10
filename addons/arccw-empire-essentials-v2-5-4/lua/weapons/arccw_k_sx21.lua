AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "SX-21"
SWEP.Trivia_Class = "Blaster, Scatter"
SWEP.SubCategory = "6Shotguns"
SWEP.Trivia_Desc = "The SX-21 pump-action scatter blaster, also known as the SX-21 scatterblaster, or the SX-21 blaster rifle, was a model of pump-action scatter blaster rifle made by Merr-Sonn Munitions, Inc., and proved invaluable to Imperial mudtroopers during the heavy fighting with the Mimbanese during the Mimban Campaign."
SWEP.Trivia_Manufacturer = "Merr-Sonn Munitions, Inc"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.IconOverride = "entities/kraken/empire-essentials/sx21.png"

-- Viewmodel & Entity Properties
SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_sx21.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_sx21.mdl"
SWEP.ViewModelFOV = 54
SWEP.WorldModelOffset = {
    pos = Vector(-18, 7.5, -8.2),
    ang = Angle(-5, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1
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

SWEP.Damage = 40
SWEP.DamageMin = 15
SWEP.RangeMin = 0
SWEP.Range = 270
SWEP.Penetration = 8
SWEP.DamageType = DMG_BUCKSHOT
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 250, 0)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_green"
SWEP.HullSize = 0.2

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 5
SWEP.ExtendedClipSize = 10

SWEP.Recoil = 2
SWEP.RecoilSide = 1.2
SWEP.RecoilRise = 2.5

SWEP.Delay = 60 / 190
SWEP.Num = 6
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
        Mode = -3,
        RunawayBurst = true,
        Mult_RPM = 5,
        PostBurstDelay = 0.1, 
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 20
SWEP.HipDispersion = 300
SWEP.MoveDispersion = 100 
SWEP.SightsDispersion = 0 
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 0.78
SWEP.SightedSpeedMult = 0.77
SWEP.ShootSpeedMult = 1

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_SX21_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_SCATTER_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_green"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 250, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-6.264, -14.316, 3.45),
    Ang = Angle(1, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "shotgun"
SWEP.HoldtypeSights = "ar2"
SWEP.HoldtypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN

SWEP.ActivePos = Vector(-2, -8, 3)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(0, 0, 3)
SWEP.SprintAng = Angle(-5, 0, 5)

SWEP.CustomizePos = Vector(10, -10, 4)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 25

-- Attachments
SWEP.AttachmentElements = {
    ["e11_scope"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Sight", 
        DefaultAttName = "Iron Sight",
        Slot = "optic",
        Bone = "v_weapon.mag7_parent",
        InstalledEles = {"e11_scope"},
        Offset = {
            vpos = Vector(0.03, -5.05, 0.5),
            vang = Angle(90, 0, -90),
        },
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        Bone = "v_weapon.mag7_parent",
        Offset = {
            vpos = Vector(1, -3.7, 9),
            vang = Angle(90, 0, 0),
        },
    },
    {
        PrintName = "Internal Compression",
        DefaultAttName = "None",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "muzzle_shotgun"},
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
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "v_weapon.mag7_parent",
        Offset = {
            vpos = Vector(0.5, -2.24, 2),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.9, 0.9, 0.9),
        WMScale = Vector(0.9, 0.9, 0.9),
        Bone = "v_weapon.mag7_parent",
        Offset = {
            vpos = Vector(0.5, -2.7, 0),
            vang = Angle(90, 0, -90),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
local path = "arccw/kraken/empire/sx21/handling/"

SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["fire_iron"] = {},
    ["fire"] = {
        Source = {"shoot1", "shoot2", "shoot3"},
        SoundTable = {
            {s = path .. "slideback.wav", t = 1/30},
            {s = path .. "slideforward.wav", t = 4/30},
        },
    },
    ["fire_sights"] = {
        Source = "shoot1_ads",
         SoundTable = {
             {s = path .. "slideback.wav", t = 1/30},
             {s = path .. "slideforward.wav", t = 4/30},
         },
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        SoundTable = {
            {s = path .. "clipout.wav", t = 7/30},
            {s = path .. "clipin.wav", t = 26/30},
        },
    },
    ["reload_empty"] = {
        Source = "reload_empty",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        SoundTable = {
            {s = path .. "clipout.wav", t = 7/30},
            {s = path .. "clipin.wav", t = 26/30},
            {s = path .. "slideback.wav", t = 54/30},
            {s = path .. "slideforward.wav", t = 60/30},
        },
    },
    ["ready"] = {
        Source = {"draw"},
        SoundTable = {
            {s = path .. "draw.wav", t = 0/30},
            {s = path .. "slideback.wav", t = 11/30},
            {s = path .. "slideforward.wav", t = 14/30},
        },
    },
    ["draw"] = {
        Source = "draw_short",
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = "CSGO.Item.Movement", t = 0/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["enter_sights"] = {
        Source = "idle",
    },
    ["idle_sprint"] = {
        Source = "sprint",
    },
    ["exit_sprint"] = {
        Source = "sprint_out",
        Time = 1,
    },
    ["enter_sprint"] = {
        Source = "sprint_in",
        Time = 1,
    },
    ["exit_inspect"] = {
        Source = "lookat01",
        MinProgress = 0.1,
        FireASAP = true,
        SoundTable = {
            {s = "weapons/csgo/movement1.wav", t = 2/30},
            {s = "weapons/csgo/movement2.wav", t = 52/30},
            {s = "weapons/csgo/movement3.wav", t = 70/30},
        },
    },
    ["bash"] = {
        Source = {"melee", "melee2", "melee3", "melee4"},
    },
}
