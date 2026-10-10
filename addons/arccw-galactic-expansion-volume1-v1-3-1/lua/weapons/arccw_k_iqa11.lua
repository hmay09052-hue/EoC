AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.HasHoloHUD1 = true

SWEP.Slot = 4

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "IQA-11"
SWEP.Trivia_Class = "Blaster Rifle"
SWEP.Trivia_Desc = "The IQA-11 Blaster Rifle was a model of sniper rifle with a sleek and inexpensive design that made it a weapon of choice for mercenaries and bounty hunters who sought reliability over longer ranges. The rifle could receive modifications, such as an extended barrel and a dual zoom scope. During the Clone Wars, the bounty hunter Rumi Paramita used an IQA-11 while defending Felucian farmers from the Ohnaka Gang. A Mon Calamari also utilized the weapon during the Imperial Era."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/iqa11.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00000000000000"

SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/galactic/v_iqa11.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_iqa11.mdl"

SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(-7, 3, -3),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Damage & Tracer
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 5
SWEP.HeatDissipation = 7
SWEP.HeatLockout = true

SWEP.BodyDamageMults = {
    [HITGROUP_HEAD] = 2.5,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.1,
    [HITGROUP_LEFTARM] = 1,
    [HITGROUP_RIGHTARM] = 1,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
}

SWEP.Damage = 104
SWEP.DamageMin = 76
SWEP.RangeMin = 0
SWEP.Range = 900
SWEP.Penetration = 11
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 12

SWEP.Recoil = 1.5
SWEP.RecoilSide = 1
SWEP.RecoilRise = 2
SWEP.MaxRecoilBlowback = 2
SWEP.RecoilPunch = 1.9
SWEP.RecoilVMShake = 2

SWEP.Delay = 60 / 120
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 1,
        PostBurstDelay = 0.1,
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

SWEP.AccuracyMOA = 0
SWEP.HipDispersion = 150
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
SWEP.ShootPitch = 90
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_IQA_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_IQA_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2.283, 0, 1.1),
    Ang = Vector(0, -0.143, 3.076),
    Magnification = 1.15,
    SwitchToSound = "ArcCW_Kraken.Ironsight",
    SwitchFromSound = "ArcCW_Kraken.Ironsight",
    ViewModelFOV = 50,
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(-1, 0, 1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -1, 0)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.InBipodPos = Vector(-8, 0, -4)
SWEP.InBipodMult = Vector(2, 0, 1)
SWEP.BarrelLength = 35
-- Attachments
SWEP.AttachmentElements = {
    ["muzzle_attach"] = {
        VMBodygroups = {{ind = 3, bg = 3}},
    },
}

SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "Iron Sight",
        Slot = "optic",
        Bone = "body",
        VMScale = Vector(1,1,1),
        WMScale = Vector(1,1,1),
        Offset = {
            vpos = Vector(0.06, 0, 1.6),
            vang = Angle(90, 0, -90),
        },
        CorrectiveAng = Angle(0, 0, 0),
        CorrectivePos = Vector(0, 0, -0.01),
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "body",
        Offset = {
            vpos = Vector(0, 1.2, 20),
            vang = Angle(-90, 180, 90),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard",
        Slot = {"muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle"},
        VMScale = Vector(1.2, 1.2, 1.2),
        WMScale = Vector(1.2, 1.2, 1.2),
        InstalledEles = {"muzzle_attach"},
        Bone = "body",
        Offset = {
            vpos = Vector(0, 0.9, 32.3),
            vang = Angle(90, 0, -90),
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
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "body",
        Offset = {
            vpos = Vector(0.4, 2.7, -2.4),
            vang = Angle(90, 0, -90),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        VMScale = Vector(0.8, 0.8, 0.8),
        WMScale = Vector(0.8, 0.8, 0.8),
        Bone = "body",
        Offset = {
            vpos = Vector(0.6, 1.5, 2),
            vang = Angle(90, 0, -90),
        },
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

-- Don't touch this unless you know what you're doing
local pathRZ = "uplp_rz/awp/"
-- urbna!
local pathUT = "arccw/kraken/sw_galactic/weapons/iqa11/handling/"
local pathUTC = "uplp_urban_temp/common/"

-- Animations
SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["draw"] = {
        Source = "draw",
        MinProgress = 0.75,
        LHIK = true,
        SoundTable = {
            { s = pathUTC .. "raise.ogg", t = 0.1, v = 0.8 },
        },
    },
    ["holster"] = {
        Source = "holster",
        MinProgress = 0.5,
        LHIK = true,
        SoundTable = {
            { s = pathUTC .. "rattle2.ogg", t = 0, v = 0.8 },
        },
    },
    ["fire"] = {
        Source = {"fire"},
    },
    ["reload"] = {
        Source = "reload_ext",
        Mult = 1.1,
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,

        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 6 / 30},
            { s = pathUTC .. "cloth_2.ogg", t = 0.1 / 30, c = ca, v = 0.8 },
            { s = pathUT .. "magout.ogg", t = 5 / 30, c = ca, v = 0.8 },
            { s = pathUTC .. "magpouch.ogg", t = 13 / 30, v = 0.3 },
            {s = "ArcCW_Kraken.OverheatReplenished", t = 24 / 30},
            { s = pathUT .. "magin.ogg", t = 22.5 / 30, c = ca, v = 0.8 },
            { s = pathUTC .. "rattle2.ogg", t = 35 / 30, c = ca, v = 0.8 },

        },
    },
    -- Inspecc --
    ["exit_inspect"] = {
        Source = "inspect",
        LHIK = true,
        MinProgress = 0.925,
    },
    ["enter_bipod"] = {
        Source = "modeswitch",
    },
    ["enter_bipod_empty"] = {
        Source = "modeswitch_empty",
    },
    ["exit_bipod"] = {
        Source = "modeswitch",
    },
    ["exit_bipod_empty"] = {
        Source = "modeswitch_empty",
    },
}