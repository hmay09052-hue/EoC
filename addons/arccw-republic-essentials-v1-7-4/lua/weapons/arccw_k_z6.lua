AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 1 

SWEP.Category = "[ArcCW] Kraken's Republic Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Z-6"
SWEP.Trivia_Class = "Blaster, Rotatory Cannon"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The Z-6 rotary blaster cannon was a blaster cannon used by the Galactic Republic during the Clone Wars. Later, during the reign of the Galactic Empire, these weapons were used by both the Imperial Army's Heavy Weapons Stormtroopers and Rebel Alliance's Heavy Soldiers during the Galactic Civil War."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Republic"

-- Base
SWEP.MirrorVMWM = false
SWEP.UseHands = true
SWEP.NoHideLeftHandInCustomization = false
SWEP.ViewModel = "models/arccw/kraken/republic/v_z6.mdl"
SWEP.WorldModel = "models/arccw/kraken/republic/world/w_z6.mdl"
SWEP.ViewModelFOV = 54

SWEP.HideViewmodel = false

SWEP.WorldModelOffset = {
    pos = Vector(0, 0, 0),
    ang = Angle(0, 0, 0),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 0.09
}

-- Special properties
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 85
SWEP.HeatDissipation = 5
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.5

SWEP.TriggerDelay = true 

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

SWEP.Damage = 28
SWEP.DamageMin = 22
SWEP.RangeMin = 0
SWEP.Range = 300
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 1200

SWEP.TracerNum = 1
SWEP.TracerCol = Color(0, 0, 250)
SWEP.TracerWidth = 10
SWEP.Tracer = "new_tracer_blue"
SWEP.HullSize = 1

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 200
SWEP.ExtendedClipSize = 250
SWEP.ReducedClipSize = 100

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.3
SWEP.Recoil = 0.5
SWEP.RecoilPunch = 1.25

SWEP.Delay = 60 / 270
SWEP.Num = 1
SWEP.Firemode = 1
SWEP.Firemodes = {
    {
		Mode = 2,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 2.5
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

SWEP.ShootSound = "ArcCW_Kraken.SW_Z6"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_Z6_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_blue"
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(0, 0, 250)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-2, -2, 1),
    Ang = Angle(0, 0, 0),
     Magnification = 1,
     SwitchToSound = "ArcCW_Kraken.Ironsight",
     SwitchFromSound = "ArcCW_Kraken.Ironsight",
     ViewModelFOV = 55,
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

SWEP.BarrelLength = 40

-- Attachments
SWEP.DefaultElements = {"z6"}
SWEP.AttachmentElements = {
    ["z6"] = {
        WMElements = {
            {
                Model = "models/arccw/kraken/republic/v_z6.mdl",
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
SWEP.WMOverride = "models/arccw/kraken/republic/v_z6.mdl"

SWEP.Attachments = {
    {
        PrintName = "Energization",
        Slot = {"ammo", "special_ammo"}
    },
    {
        PrintName = "Mode",
        Slot = {"sw_mode"},
    },   
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
    {
        PrintName = "Perk",
        Slot = "perk",
    },
}

local path = "arccw/kraken/republic/z6rotaryblaster/handling/"


SWEP.TriggerDelay = true

SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["fire_iron"] = {
        Source = "shoot1",
        SoundTable = {
            {s = path .. "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_gunner_loop_01.wav", v = 0.2, t = 0.01},
			{s = path .. "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_start_short_var_01_04.wav", v = 0.3, t = 4/30},
        },
    },
    ["fire"] = {
        Source = "shoot1",
        SoundTable = {
            {s = path .. "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_gunner_loop_01.wav", v = 0.2, t = 0.01},
			{s = path .. "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_start_short_var_01_04.wav", v = 0.3, t = 4/30},
        },
    },
    ["trigger"] = {
        Source = "windup",
        SoundTable = {
            {
                s = "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_start_short_var_01_04.wav",
                p = 100,
                v = 100,
                t = 0.01,
                c = CHAN_ITEM,
            },
        }
    },
    ["untrigger"] = {
        Source = "windup",
        SoundTable = {
            {
                s = "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_gunner_stop_01.wav",
                p = 100,
                v = 100,
                t = 0.05,
                c = CHAN_ITEM,
            },
        }
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
