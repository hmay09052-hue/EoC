AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.HasHoloHUD1 = true
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Galactic Expansion - Vol. I"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "CR-2"
SWEP.Trivia_Class = "Heavy Pistol"
SWEP.Trivia_Desc = "The CR-2 heavy blaster pistol, also known more simply as a CR-2 blaster pistol, was a heavy blaster pistol manufactured by Corellian Arms that was utilized by the Royal Naboo Security Forces. Small and agile, it had an extreme rate of fire and shoot ionized bolts. It also could be configured with night vision scopes or have an extended stock for reduced recoil."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Tibanna Gas"
SWEP.IconOverride = "entities/kraken/galactic/cr2.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00000000000000000"

SWEP.HideViewmodel = false
SWEP.MirrorVMWM = true
SWEP.UseHands = true

SWEP.ViewModel = "models/arccw/kraken/galactic/v_cr2.mdl"
SWEP.WorldModel = "models/arccw/kraken/galactic/worldmodels/w_cr2.mdl"
SWEP.ViewModelFOV = 70

SWEP.WorldModelOffset = {
    pos = Vector(1.2, 0.6, -3.3),
    ang = Angle(-10, 0, 180),
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

SWEP.Damage = 20
SWEP.DamageMin = 15
SWEP.RangeMin = 0
SWEP.Range = 600
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 9000

SWEP.TraceNum = 1
SWEP.Tracer = "new_tracer_green"
SWEP.TracerCol = Color(0, 250, 0)

SWEP.AmmoPerShot = 1
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 60

SWEP.Recoil = 0.75
SWEP.RecoilSide = 0.35
SWEP.RecoilRise = 0.65
SWEP.RecoilPunch = 0.5

SWEP.Delay = 60 / 680
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
SWEP.HipDispersion = 250
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 150

-- Speed Mult
SWEP.SpeedMult = 1.10
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

SWEP.ShootSound = "ArcCW_Kraken.SW_GALACTIC_CR2_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_GALACTIC_CR2_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleFlashColor = Color(0, 250, 0)
SWEP.MuzzleEffect = "blaster_muzzle_green"
SWEP.GMMuzzleEffect = false

-- Ironsight & Holdtype
SWEP.IronSightStruct = {
    Pos = Vector(-1.99, 0, 0.9),
    Ang = Vector(0, 0.2, 2),
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

SWEP.ActivePos = Vector(-1, 2, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(0, 0, 1.5)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CrouchPos = Vector(-4, 0, -1)
SWEP.CrouchAng = Angle(0, 0, -10)

SWEP.HolsterPos = Vector(3, 3, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(20, 30.7, 10.3)
SWEP.BarrelLength = 25
-- Attachments 
SWEP.DefaultElements = {}
SWEP.Attachments = {     
    {
        PrintName = "Optics", 
        DefaultAttName = "None",
        Slot = "optic",
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(1, -0.0, 1.1),
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
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(15, -0.0, -1.2),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(10, 0.8, -1.1),
            vang = Angle(0, 0, -90),
        },
    },  
    {
        PrintName = "Underbarrel",
        DefaultAttName = "None",
        Slot = {"foregrip"},
        VMScale = Vector(1, 1, 1),
        WMScale = Vector(1, 1, 1),
        Bone = "tag_attachments",
        InstalledEles = {"grip_attach"},
        Offset = {
            vpos = Vector(10, 0, -1.8),
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
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(6.5, -0.39, 0.85),
            vang = Angle(0, 0, 0),
        },
    },    
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = "killcounter",
        Bone = "tag_attachments",
        Offset = {
            vpos = Vector(10.4, -0.7, -0.5),
            vang = Angle(0, 0, 30),
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
        Source = "shoot1",
    },
    ["reload"] = {
        Source = "reload_short",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
		MinProgress = 0.925,
        SoundTable = {
            {s = path .. "wfoly_sm_secho_reload_up.ogg", t = 0.0},
            {s = "ArcCW_Kraken.Overheat", t = 0.5 },
            {s = path .. "wfoly_sm_secho_reload_magout.ogg", t = 0.433},
			{s = path .. "wfoly_sm_secho_reload_maghit.ogg", t = 0.867},
			{s = path .. "wfoly_sm_secho_reload_magin.ogg", t = 1.233},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 1.23},
			{s = path .. "wfoly_sm_secho_reload_end.ogg", t = 1.567},
        },
    },
    ["reload_empty"] = {
        Source = "reload",
		MinProgress = 0.925,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
        LHIK = true,
        SoundTable = {
			{s = path .. "wfoly_sm_secho_reload_empty_up.ogg", t = 0.033},
			{s = path .. "wfoly_sm_secho_reload_empty_magout.ogg", t = 0.467},
            {s = "ArcCW_Kraken.Overheat", t = 0.5 },
			{s = path .. "wfoly_sm_secho_reload_empty_mvmnt.ogg", t = 1.133},
			{s = path .. "wfoly_sm_secho_reload_empty_maghit.ogg", t = 1.25},
			{s = path .. "wfoly_sm_secho_reload_empty_magin.ogg", t = 1.35},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 1.36},
			{s = path .. "wfoly_sm_secho_reload_empty_charge.ogg", t = 1.64},
			{s = path .. "wfoly_sm_secho_reload_empty_end.ogg", t = 1.867},
        },
    },
    ["ready"] = {
        Source = "draw",
        LHIK = true,
		MinProgress = 0.85,
		FireASAP = true,
        SoundTable = {
            {s = path .. "wfoly_sm_secho_raise_first_up.ogg", t = 0.0},
            {s = path .. "wfoly_sm_secho_raise_first_charge.ogg", t = 0.5},
            {s = path .. "wfoly_sm_secho_raise_first_end.ogg", t = 0.667},
        },
    },
    ["draw"] = {
        Source = "draw_short",
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
        Source = "idle",
    },
    ["idle_sprint"] = {
        Source = "sprint",
    },
    ["exit_sprint"] = {
        Source = "sprint_out",
		Time = 1.25,
    },
    ["enter_sprint"] = {
        Source = "sprint_in",
		IKTimeLine = { { t = 0,  lhik = 1, rhik = 1} },
		Time = 1.25,
    },
    ["exit_inspect"] = {
        Source = "lookat01",
		MinProgress = 0.9,
		FireASAP = true,
        LHIK = true,
        SoundTable = {
            {s = path .. "wfoly_sm_secho_inspect_magout.ogg", t = 0.033},
			{s = path .. "wfoly_sm_secho_inspect_magin.ogg", t = 1.967},
			{s = path .. "wfoly_sm_secho_inspect_end.ogg", t = 3.4},
        },
    },
    ["bash"] = {
        Source = {"melee","melee2","melee3"},
        LHIK = true,
    },
    ["changefiremode"] = {
        Source = "semi_on",
        SoundTable = {
            {s = path .. "wfoly_sm_secho_selectsemi_on.ogg", t = 0/30},
        },
    },
    ["enter_bipod"] = {
        Source = "bipod_in",
    },
    ["exit_bipod"] = {
        Source = "bipod_out",
    },
}