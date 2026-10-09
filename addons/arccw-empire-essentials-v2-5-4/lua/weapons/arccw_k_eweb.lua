AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "E-WEB"
SWEP.Trivia_Class = "Blaster, Heavy Repeater"
SWEP.SubCategory = "4Heavy"
SWEP.Trivia_Desc = "The E-Web was a heavy repeating blaster manufactured by BlasTech Industries. It was one of the most powerful repeating blasters in the Imperial arsenal, and had an optimum range of one-hundred and fifty meters with a maximum range of seven-hundred and fifty meters. The full name is Emplacement Weapon, Heavy Blaster, but many users shortened this to E-Web.[7] The original weapon was designed in a joint effort with Merr-Sonn Munitions, which produced the predecessor to the modern E-Web, the EWHB-10. Members of the Stormtrooper Corps were trained to utilize the weapon, although its mass made it being carried by a single stormtrooper impossible, mandating that it be operated by two stormtroopers: one for firing the E-Web, and another monitoring and adjusting the generator's power feed to prevent overheating."
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/eweb.png"

-- Viewmodel & Entity Properties
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.NoHideLeftHandInCustomization = false
SWEP.ViewModel = "models/arccw/kraken/empire/v_eweb.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_eweb.mdl"
SWEP.ViewModelFOV = 54
SWEP.HideViewmodel = false
SWEP.WorldModelOffset = {
    pos = Vector(-10, 8, -12),
    ang = Angle(0, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

-- Special Properties
SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 70
SWEP.HeatDissipation = 10
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.5

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

SWEP.Damage = 38
SWEP.DamageMin = 23
SWEP.RangeMin = 0
SWEP.Range = 400
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 8000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 5
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 125

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.5
SWEP.Recoil = 0.5

SWEP.Delay = 60 / 180
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
SWEP.HipDispersion = 300
SWEP.MoveDispersion = 200
SWEP.JumpDispersion = 500

-- Speed Mult
SWEP.SpeedMult = 0.875
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.8

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 100
SWEP.ShootPitch = 90
SWEP.ShootPitchVariation = 0.1

SWEP.ShootSound = "ArcCW_Kraken.SW_EWEB_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_EWEB_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.379, -6.961, 2.2),
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

SWEP.ActivePos = Vector(0, -2, 2)
SWEP.ActiveAng = Angle(0, 0, 0)


SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 45

-- Attachments
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

SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["fire_iron"] = {},
    ["idle"] = {
        Source = "idle",
    },
    ["exit_inspect"] = {
        Source = "overview", 
    },
    ["fire"] = {
        Source = "fire"
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
    ["fix"] = {
        Source = "overheat",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "arccw/kraken/cooling/overheat.mp3", t = 0.1 },
            {s = "arccw/kraken/cooling/cooling.mp3", t = 2.8 },
        },
    },
    ["reload"] = {
        Source = "reload",
        LHIK = true,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2, 
        SoundTable = {
            {s = "arccw/kraken/cooling/overheat.mp3", t = 0.1 },
            {s = "weapon_hand/reload_gentle/other/023d-00000ee3.mp3", t = 0.3 },
            {s = "weapon_hand/reload_gentle/mag_eject/023d-0000045e.mp3", t = 2 },
            {s = "weapon_hand/reload_gentle/mag_load/023d-00000638.mp3", t = 3.5 },
            {s = "weapon_hand/reload_gentle/other/023d-00000ee3.mp3", t = 4.5 },        
        },
    },
}


-- Special properties
SWEP.Hook_ModifyRPM = function(wep, delay)
    return delay / Lerp(wep:GetBurstCount() / 15, 1, 3)
end
