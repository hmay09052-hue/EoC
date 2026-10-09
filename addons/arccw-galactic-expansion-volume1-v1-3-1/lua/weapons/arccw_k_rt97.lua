AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.HasHoloHUD1 = true
SWEP.AdminOnly = false

SWEP.Slot = 4

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "RT-97"
SWEP.Trivia_Class = "Heavy Blaster Rifle"
SWEP.Trivia_Desc = "The RT-97C heavy blaster rifle was a model of heavy blaster rifle that saw use during the Galactic Civil War. It was a versatile heavy rifle, fitted with optics that allowed use at long range. Imperial sandtroopers were known to use them, as were jumptroopers."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/rt97.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "0100000000000000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/galactic/v_rt97c.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_rt97c.mdl"
SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-9, 7, 2),
    ang = Angle(-10, 0, 180),
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 75
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

SWEP.Damage = 32
SWEP.DamageMin = 19
SWEP.RangeMin = 0
SWEP.Range = 600
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TraceNum = 1
SWEP.Tracer = "new_tracer_red"
SWEP.TracerCol = Color(250, 0, 0)

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 100

SWEP.Recoil = 0.86
SWEP.RecoilSide = 0.45
SWEP.RecoilRise = 0.75
SWEP.RecoilPunch = 0.8

SWEP.Delay = 60 / 550
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
SWEP.HipDispersion = 300
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 0.9
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

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_RT97_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_RT97_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleFlashColor = Color(25, 0, 0)
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.GMMuzzleEffect = false

-- Ironsight & Holdtype
SWEP.IronSightStruct = {
    Pos = Vector(-6.133, -10.502, -7.042),
    Ang = Vector(2.184, 0, 0),
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

SWEP.ActivePos = Vector(-1, 0, -8)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(0, -2, -8)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CrouchPos = Vector(-4, 0, -11)
SWEP.CrouchAng = Angle(0, 0, -10)

SWEP.HolsterPos = Vector(3, -3, -8)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.CustomizePos = Vector(10, 0, -9)
SWEP.CustomizeAng = Angle(20, 30.7, 10.3)
SWEP.BarrelLength = 35
-- Attachments 
SWEP.DefaultElements = {}
SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(1.9, -0, 5.6),
            vang = Angle(0, 0, 0),
        },
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(0, 0, 0)
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "stealth_muzzle"},
        VMScale = Vector(1.2, 1.2, 1.2),
        WMScale = Vector(1.2, 1.2, 1.2),
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(40, -0.1, 4.8),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(25, 0.4, 4.7),
            vang = Angle(0, 0, -90),
        },
    },  
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "tag_weapon",
        InstalledEles = {"grip_attach"},
        Offset = {
            vpos = Vector(8, 0.1, 3.8),
            vang = Angle(0, 0, 0),
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
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(2, -1.1, 4.75),
            vang = Angle(0, 0, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(-3, -1.1, 4.65),
            vang = Angle(0, 0, 0),
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
        Mult = 0.9,
        SoundTable = {
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/raise_start.wav", t = 0.1},
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/empty_charge.wav", t = 1.1},
			{s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/mag_out.wav", t = 3.5},
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/raise_charge.wav", t = 4.5},
			{s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/mag_in.wav", t = 4.5},
        },
    },
    ["reload_empty"] = {
        Source = "reload_empty",
		MinProgress = 0.925,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        LHIK = true,
        SoundTable = {
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/empty_charge.wav", t = 0.1},
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/raise_start.wav", t = 0.5},
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/empty_charge.wav", t = 1.1},
			{s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/mag_out.wav", t = 3.5},
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/raise_charge.wav", t = 4.5},
			{s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/mag_in.wav", t = 4.5},
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/mag_in.wav", t = 7},
        },
    },
    ["ready"] = {
        Source = "pullout_first",
        LHIK = true,
		MinProgress = 0.85,
		FireASAP = true,
        SoundTable = {
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/raise_start.wav", t = 0.0},
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/raise_charge.wav", t = 0.5},
        },
    },
    ["holster"] = {
        Source = "putaway",
        SoundTable = {
            {s = "wfoly_sm_secho_reload_end.ogg", t = 0/30},
        },
    },
    ["draw"] = {
        Source = "pullout",
        SoundTable = {
            {s = "wfoly_sm_secho_reload_end.ogg", t = 0/30},
        },
    },
    ["idle"] = {
        Source = "idle",
    },
    ["fix"] = {
        Source = "pullout_first",
        SoundTable = {
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/raise_start.wav", t = 0.1},
            {s = "arccw/kraken/sw_galactic/weapons/rt97c/handling/raise_charge.wav", t = 0.6},
            {s = "ArcCW_Kraken.Overheat", t = 0.1},
            {s = "ArcCW_Kraken.OverheatFix", t = 0.9},
        },
    },
    ["idle_sprint"] = {
        Source = "base_sprint_loop",
    },
    ["exit_sprint"] = {
        Source = "base_sprint_out",
		Time = 1.25,
    },
    ["enter_sprint"] = {
        Source = "base_sprint_in",
		Time = 1.25,
    },
}