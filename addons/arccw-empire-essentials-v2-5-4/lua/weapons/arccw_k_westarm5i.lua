AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3 -- Change this if you want to select the weapon with other number

-- Trivia
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Westar M5i"
SWEP.Trivia_Class = "Blaster, Carbine"
SWEP.SubCategory = "2Carbines"
SWEP.Trivia_Desc = "The WESTAR-M5 blaster rifle was a blaster rifle used during the Clone Wars by the Grand Army of the Republic. They were mainly used by the Alpha-class Advanced Recon Commandos during the later years of the conflict. The blaster rifle could be calibrated to fire in semi-automatic, automatic, and burst-fire modes, and could be equipped with a variety of attachments, including an under-barrel grenade launcher that could be used against "
SWEP.Trivia_Manufacturer = "BlastTech Industries"
SWEP.Trivia_Calibre = "Condensed Tibanna-Gas"
SWEP.Trivia_Country = "Galactic Empire, Galactic Republic"
SWEP.IconOverride = "entities/kraken/empire-essentials/westarm6.png"

-- Viewmodel & Entity Properties
SWEP.DefaultBodygroups = "00000"
SWEP.DefaultWMBodygroups = "00000"
SWEP.DefaultSkin = 4
SWEP.DefaultWMSkin = 4

SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_westar_imperial.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/worldmodel/w_westar_imperial.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-8, 3.5, -7),
    ang = Angle(0, 0, -180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1.4,
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

SWEP.Damage = 34
SWEP.DamageMin = 23
SWEP.RangeMin = 0
SWEP.Range = 400
SWEP.Penetration = 8
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 4000

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 0.2

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 50

SWEP.RecoilSide = 0.1
SWEP.RecoilRise = 0.6
SWEP.Recoil = 0.7

SWEP.Delay = 60 / 450
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
        Mult_RPM = 2,
    },
    {
		Mode = 1,
    },
	{
		Mode = 0,
   	}
}


SWEP.AccuracyMOA = 0.2
SWEP.HipDispersion = 225
SWEP.MoveDispersion = 150
SWEP.JumpDispersion = 500

-- Speed Mult
SWEP.SpeedMult = 0.925
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

-- Ammo, Sounds & MuzzleEffect
SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 100
SWEP.ShootPitchVariation = 0.2

SWEP.ShootSound = "ArcCW_Kraken.SW_WESTAR_Close"
SWEP.DistantShootSound = "ArcCW_Kraken.SW_WESTAR_Distant"
SWEP.DistantShootSoundSilenced = "ArcCW_Kraken.SW_Silenced_Distant"
SWEP.ShootSoundSilenced = "ArcCW_Kraken.SW_Silenced"

SWEP.MuzzleEffect = "arccw_kraken_sw_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = true
SWEP.MuzzleFlashColor = Color(250, 0, 0)

-- Ironsight
SWEP.IronSightStruct = {
    Pos = Vector(-3.1, -0, 1.2),
    Ang = Angle(5, 0, 0),
     Magnification = 1.5,
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

SWEP.ActivePos = Vector(0, 2, 2)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(4.019, -5.226, -0.805)
SWEP.SprintAng = Angle(5, 40, 0)


SWEP.CustomizePos = Vector(10, 4, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.BarrelLength = 25

-- Attachments
SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["e11_scope"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["e11_laser"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["e11_muzzle"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
    },
    ["muzzle"] = {
        WMElements = {
            {
                Model = "models/hunter/plates/plate.mdl",
                Bone = "ValveBiped.Bip01_R_Hand",
                Scale = Vector(0, 0, 0),
                Offset = {
                    pos = Vector(15, 0.5, -8),
                    ang = Angle(0, 0, 0)
                },
                IsMuzzleDevice = true
            }
        }, 
    },
}

SWEP.Attachments = {
	{
		PrintName = "Sight",
		DefaultAttName = "None",
		Slot = "optic",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
		Bone = "weapon",
        InstalledEles = {"e11_scope"},
		Offset = {
            vpos = Vector(0.06, -3, 0.5),
            vang = Angle(90, 0, -90),
        },
	},
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol"},
		Bone = "weapon",
        InstalledEles = {"e11_laser"},
        VMScale = Vector(0.5, 0.5, 0.5),
        WMScale = Vector(0.5, 0.5, 0.5),
        Offset = {
            vpos = Vector(1.2, -1.15, 4.3),
            vang = Angle(90, 0, -0),
        },
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "None",
        Slot = {"muzzle", "dlt19_muzzle", "dc15a_muzzle", "cr2_muzzle", "cr2c_muzzle", "stealth_muzzle", "b1120_muzzle"},
        Bone = "weapon",
        InstalledEles = {"e11_muzzle"},
        Offset = {
            vpos = Vector(0.06, -1.1, 5.7),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Foregrip",
        DefaultAttName = "No Attachment", 
        Slot = "foregrip",
        Bone = "weapon",
        Offset = {
            vpos = Vector(0, 2.2, 2.5),
            vang = Angle(90, 0, -90),      
        },
        NoWM = true,
        NoVM = true,    
    },
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
        PrintName = "Charms", 
        DefaultAttName = "None",
        Slot = {"charm"},
		Bone = "weapon",
        VMScale = Vector(0.6, 0.6, 0.6),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.89, 0.2, -0.2),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Killcounter",
        DefaultAttName = "None",
        Slot = {"killcounter"},
        Bone = "weapon",
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Offset = {
            vpos = Vector(0.45, -1.5, -6.5),
            vang = Angle(90, 0, -90),
        },
    },                         
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

SWEP.ProceduralIronFire = true

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
	["fire"] = {
        Source = "fire",
    },
    ["fire_iron"] = {},
	["idle_sights"] = {
        Source = false,
    },
	["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
		SoundTable = {
	        {s = "arccw/kraken/empire/westar/westar_reload.mp3", t = 0.1 }
        },
    },
    ["reload_empty"] = {
        Source = "reload_empty",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
		SoundTable = {
	        {s = "arccw/kraken/empire/westar/westar_reload.mp3", t = 0.1 }
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
