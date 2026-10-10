AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.HasHoloHUD1 = true
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "DC-15se"
SWEP.Trivia_Class = "Blaster Carbine"
SWEP.Trivia_Desc = "Long-Range Carbine. Designed for the Galactic Republic during the Clone Wars."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/dc15se.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "01111100000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/galactic/v_dc15.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_dc15.mdl"
SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-7, 3, -6),
    ang = Angle(-5, 0, 180),
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

SWEP.Damage = 42
SWEP.DamageMin = 27
SWEP.RangeMin = 0
SWEP.Range = 900
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TraceNum = 1
SWEP.Tracer = "new_tracer_blue"
SWEP.TracerCol = Color(0, 0, 250)

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 25

SWEP.Recoil = 0.75
SWEP.RecoilSide = 0.40
SWEP.RecoilRise = 0.65
SWEP.RecoilPunch = 1.6

SWEP.Delay = 60 / 330
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
        PostBurstDelay = 0.1,
    },
    {
		Mode = 2,
        PostBurstDelay = 0.1,
    },
    {
        Mult_RPM = 2,
		Mode = -3,
        PostBurstDelay = 0.1,
    },
	{
		Mode = 0,
   	}
}

SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 1
SWEP.SightedSpeedMult = 0.75
SWEP.ShootSpeedMult = 1.05

-- Sounds & Muzzleflash
SWEP.Primary.Ammo = "ar2"

SWEP.ShootVol = 125
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.05

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

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_DC15_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_DC15_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleFlashColor = Color(0, 0, 250)
SWEP.MuzzleEffect = "blaster_muzzle_blue"
SWEP.GMMuzzleEffect = false

-- Ironsight & Holdtype
SWEP.IronSightStruct = {
    Pos = Vector(-2.78, -1, 1.5),
    Ang = Vector(0, 0, 0),
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

SWEP.ActivePos = Vector(0, -2, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CrouchPos = Vector(-4, 0, -1)
SWEP.CrouchAng = Angle(0, 0, -10)

SWEP.HolsterPos = Vector(3, 3, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(20, 30.7, 10.3)
SWEP.BarrelLength = 40
-- Attachments 
SWEP.DefaultElements = {}
SWEP.AttachmentElements = {
    ["grip_attach"] = {
        VMBodygroups = {{ind = 2, bg = 2}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "DC15",
        Offset = {
            vpos = Vector(0, -1.3, -1.5),
            vang = Angle(90, 0, -90),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0)
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "stealth_muzzle"},
        Bone = "DC15",
        Offset = {
            vpos = Vector(0, -0.45, 17.3),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "DC15",
        Offset = {
            vpos = Vector(-0.8, -0.2, 6),
            vang = Angle(90, 0, 180),
        },
    },  
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "DC15",
        InstalledEles = {"grip_attach"},
        Offset = {
            vpos = Vector(0, 0.25, 5),
            vang = Angle(90, 0, -90),
        },
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
        Bone = "DC15",
        Offset = {
            vpos = Vector(1.1, 0.15, -4.1),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        Bone = "DC15",
        Offset = {
            vpos = Vector(1.1, -0.1, -6),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
local path = "arccw/kraken/sw_galactic/weapons/cr2/handling/"

SWEP.Animations = {
    ["fire"] = {
        Source = "fire",
    },
    ["reload"] = {
        Source = "reload",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
		MinProgress = 0.925,
        SoundTable = {
            {s = path .. "wfoly_sm_secho_reload_up.ogg", t = 0.0},
            {s = path .. "wfoly_sm_secho_reload_magout.ogg", t = 0.433},
			{s = path .. "wfoly_sm_secho_reload_maghit.ogg", t = 0.867},
			{s = path .. "wfoly_sm_secho_reload_magin.ogg", t = 1.233},
        },
    },
    ["draw"] = {
        Source = "draw",
		MinProgress = 0.5,
        LHIK = true,
		FireASAP = true,
        SoundTable = {
            {s = path .. "wfoly_sm_secho_raise.ogg", t = 0/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = path .. "wfoly_sm_secho_reload_end.ogg", t = 0/30},
        },
    },
    ["idle"] = {
        Source = false,
    },
}