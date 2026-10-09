AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Slot = 4

SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Z-6i"
SWEP.Trivia_Class = "Blaster, Rotatory Cannon"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The Z-6 rotary blaster cannon was a blaster cannon used by the Galactic Republic during the Clone Wars. Later, during the reign of the Galactic Empire, these weapons were used by both the Imperial Army's Heavy Weapons Stormtroopers and Rebel Alliance's Heavy Soldiers during the Galactic Civil War."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/z6.png"

-- Viewmodel & Entity Properties
SWEP.HideViewmodel = false
SWEP.MirrorVMWM = false
SWEP.UseHands = true
SWEP.NoHideLeftHandInCustomization = false
SWEP.ViewModel = "models/arccw/kraken/empire/v_z6i.mdl"
SWEP.WorldModel = "models/arccw/kraken/w_dlt19.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 0.09
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


SWEP.Damage = 22
SWEP.DamageMin = 18
SWEP.RangeMin = 0
SWEP.Range = 300
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 1200

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 200
SWEP.ExtendedClipSize = 250
SWEP.ReducedClipSize = 100

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.3
SWEP.Recoil = 0.5

SWEP.Delay = 60 / 270
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


SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 200
SWEP.JumpDispersion = 1000

-- Speed Mult
SWEP.SpeedMult = 0.875
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.8

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_Z6I_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_Z6I_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2, -2, 1),
    Ang = Angle(0, 0, 0),
    Magnification = 1.4,
    ViewModelFOV = 44,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
}

-- Holdtype
SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "shotgun"
SWEP.HoldtypeSights = "rpg"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(1, 0, -1)
SWEP.SprintAng = Angle(0, 0, 15)


SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(3, 0, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelLength = 45

-- Attachments
SWEP.DefaultElements = {"z6"}
SWEP.AttachmentElements = {
    ["z6"] = {
        WMElements = {
            {
                Model = "models/arccw/kraken/empire/v_z6i.mdl",
                Bone = "ValveBiped.Bip01_R_Hand",
                Scale = Vector(1.1, 1.1, 1.1),
                WBodygroups = {{ind = 0, bg = 0}},
                Offset = {
                    pos = Vector(250, 0, 600),
                    ang = Angle(-15, 0, 180)
                }
            },
            {
                Model = "models/hunter/plates/plate.mdl",
                Bone = "ValveBiped.Bip01_R_Hand",
                Scale = Vector(0, 0, 0),
                Offset = {
                    pos = Vector(450, 0, -100),
                    ang = Angle(-15, 0, 100)
                },
                IsMuzzleDevice = true
            },
        },
    },
}
SWEP.WMOverride = "models/arccw/kraken/empire/v_z6i.mdl"

SWEP.Attachments = {
    {
        PrintName = "Energization",
        DefaultAttName = "Standard",
        Slot = {"ammo", "special_ammo"}
    },
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
    },
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

local path = "arccw/kraken/empire/z6/handling/"


SWEP.TriggerDelay = true

SWEP.Animations = {
    ["fire_iron"] = {
        Source = "shoot1",
        SoundTable = {
            {s = path .. "weap_dblmg_spin_plr.ogg", v = 0.2, t = 0/30},
			{s = path .. "weap_dblmg_spindown_plr_01.ogg", v = 0.3, t = 4/30},
        },
    },
    ["fire"] = {
        Source = "shoot1",
        SoundTable = {
            {s = path .. "weap_dblmg_spin_plr.ogg", v = 0.2, t = 0/30},
			{s = path .. "weap_dblmg_spindown_plr_01.ogg", v = 0.3, t = 4/30},
        },
    },
    ["trigger"] = {
        Source = {"windup"},
        SoundTable = {
            {s = "arccw/kraken/empire/z6/start/blasters_z6rotaryblaster_start_short_var_0" .. math.random(1,4) .. ".mp3", t = 0.1},
        },
    },
    ["reload"] = {
        Source = "jam_fix",
		MinProgress = 0.8,
        Mult = 2,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PHYSGUN,
        SoundTable = {
			{s = "ArcCW_Kraken.Overheat", t = 0.01},
			{s = "ArcCW_Kraken.OverheatReplenished", t = 1.5},
        },
    },
    ["draw"] = {
        Source = "draw",
		MinProgress = 0.7,
		FireASAP = true,
        SoundTable = {
            {s = path .. "wfoly_lm_sierrax_raise.ogg", t = 5/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {s = path .. "wfoly_lm_sierrax_raise.ogg", t = 0.01},
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
		Mult = 3,
    },
    ["enter_sprint"] = {
        Source = "sprint_in",
		IKTimeLine = { { t = 0,  lhik = 1, rhik = 1} },
		Mult = 3,
    },
    ["exit_inspect"] = {
        Source = "lookat01",
		MinProgress = 0.9,
		FireASAP = true,
        IKTimeLine = {
            { t = 0, lhik = 1, rhik = 0 },
            { t = 0.2, lhik = 0, rhik = 0 },
            { t = 0.7, lhik = 0, rhik = 0 },
            { t = 1.1, lhik = 1, rhik = 1 },
        },
        SoundTable = {
            {s = path .. "wfoly_lm_dblmg_inspect_01.ogg", t = 18/30},
			{s = path .. "wfoly_lm_dblmg_inspect_02.ogg", t = 56/30},
			{s = path .. "wfoly_lm_dblmg_inspect_03.ogg", t = 109/30},
        },
    },
    ["bash"] = {
        Source = "melee",
    },
}

-- Special properties
SWEP.Hook_ModifyRPM = function(wep, delay)
    return delay / Lerp(wep:GetBurstCount() / 15, 1, 3)
end
