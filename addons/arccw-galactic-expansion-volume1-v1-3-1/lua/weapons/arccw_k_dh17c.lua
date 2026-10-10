AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.HasHoloHUD1 = true
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DH-17c"
SWEP.Trivia_Class = "Blaster Pistol-Carbine"
SWEP.Trivia_Desc = "The DH-17 blaster pistol was commonly used by soldiers of the Rebel Alliance for conflicts aboard starships, and sometimes the officers of the Galactic Empire carried it instead of the standard E-11 medium blaster rifles. The DH-17 blaster rifle was a rifle version that featured a shoulder stock, and a hand-calibrated macroscopes. The rifles were black and silver in color."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/dh17c.png"

-- Base
SWEP.DefaultBodygroups = "011110000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/galactic/v_dh17c.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_dh17c.mdl"

SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-11, 4, -6),
    ang = Angle(-5, 0, 180)
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 18
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
SWEP.HeatFix = true
SWEP.HeatDelayTime = 0.5

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 30
SWEP.DamageMin = 23
SWEP.RangeMin = 0
SWEP.Range = 600
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 2000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 32

SWEP.Recoil = 0.55
SWEP.RecoilSide = 0.2
SWEP.RecoilRise = 0.2

SWEP.Delay = 60 / 345
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
    },
    {
        Mode = -3,
        PostBurstDelay = 0.1,
        RunawayBurst = false,
        Mult_RPM = 2,
    },
	{
		Mode = 0,
   	}
}

local s = "ArcCW_Kraken.OverheatWarn"
local p = {
    [5] = 70,
    [4] = 70,
    [3] = 70,
    [2] = 80,
    [1] = 90,
    [0] = 100,
}
SWEP.Hook_AddShootSound = function(wep, data)
    local pitch = p[wep:Clip1()]
    if pitch then
        wep:MyEmitSound(s, 100, pitch, 0.5, CHAN_AUTO)
    end
end

SWEP.AccuracyMOA = 0.5
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

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_DH17C_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_DL44_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.27, -5.361, 2),
    Ang = Vector(0, 0.128, -1),
     Magnification = 1.5,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
}

-- Holdtype
SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "smg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.CrouchPos = Vector(-3, 0, 2)
SWEP.CrouchAng = Angle(0, 0, 0)

SWEP.ActivePos = Vector(-2, 0, 0)
SWEP.ActiveAng = Angle(0, -1, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)
SWEP.BarrelLength = 30
-- Attachments
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["muzzle_attach"] = {
        VMBodygroups = {{ind = 1, bg = 2}, {ind = 2, bg = 2}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "v_weapon.parent",
        Offset = {
            vpos = Vector(0.52, -6, 2),
            vang = Angle(90, 0, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0,0,0)
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"stealth_muzzle", "muzzle"},
        InstalledEles = {"muzzle_attach"},
        Bone = "v_weapon.parent",
        VMScale = Vector(1.7, 1.7, 1.7),
        WMScale = Vector(1.7, 1.7, 1.7),
        Offset = {
            vpos = Vector(0.51, -5, 9.83),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        Bone = "v_weapon.parent",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Offset = {
            vpos = Vector(-0.1, -5.55, 7),
            vang = Angle(90, 0, -220),
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
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "v_weapon.parent",
        Offset = {
            vpos = Vector(1.29, -3.9, -2),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        Bone = "v_weapon.parent",
        Offset = {
            vpos = Vector(1.6, -4.7, 1),
            vang = Angle(90, 0, -90),
        },
    }, 
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing

-- Anims
local path = "arccw/kraken/sw_galactic/handling/pistol/"

SWEP.Animations = {
    ["fire"] = {
        Source = {"shoot1", "shoot2", "shoot3"},
    },
    ["fire_sights"] = {
        Source = "shoot1_ads",
    },
    ["reload"] = {
        Source = "reload_short",
		MinProgress = 0.725,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 11 / 50},
            {s = path .. "clipout.wav", t = 10/50},
            {s = path .. "clipin.wav", t = 62/50},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 63 / 50},
            {s = "wfoly_ar_scharlie_raise_movment.ogg", t = 39/50},
        },
    },
    ["ready"] = {
        Source = "draw_short",
    },
    ["draw"] = {
        Source = "draw_short",
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = "wfoly_ar_scharlie_raise_movment.ogg", t = 0.1/30},
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
        MinProgress = 0.9,
        SoundTable = {
            {s = "wfoly_ar_scharlie_raise_movment.ogg", t = 7/40},
            {s = "wfoly_ar_scharlie_raise_movment.ogg", t = 59/40},
            {s = "wfoly_ar_scharlie_raise_movment.ogg", t = 135/40},
            {s = "wfoly_ar_scharlie_raise_movment.ogg", t = 166/40},
        },
    },
    ["bash"] = {
        Source = {"melee", "melee2"},
    },
}