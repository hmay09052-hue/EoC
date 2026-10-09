AddCSLuaFile()

SWEP.Base = "arccw_masita_base_updated"
SWEP.Spawnable = true

SWEP.Slot = 3

SWEP.Category = "[ArcCW] Kraken's Explosives - Weapons"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "G-125"
SWEP.Trivia_Class = "Projectile Launcher"
SWEP.Trivia_Desc = "The G125 projectile launcher was a weapon used by First Order jet troopers in combat during the First Order-Resistance War"
SWEP.Trivia_Manufacturer = "Sonn-Blas Corporation"
SWEP.Trivia_Calibre = "Plasma"

SWEP.DefaultBodygroups = "0000000000000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_g125.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_g125.mdl"

SWEP.ViewModelFOV = 60

SWEP.WorldModelOffset = {
    pos = Vector(-8.6, 5.5, -4),
    ang = Angle(-15, 0, 180),
    bone = "ValveBiped.Bip01_R_Hand",
    scale = 1,
}

SWEP.Jamming = true
SWEP.HeatGain = 1
SWEP.HeatCapacity = 17
SWEP.HeatDissipation = 2
SWEP.HeatLockout = true
SWEP.HeatDelayTime = 0.5
SWEP.HeatFix = true

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
SWEP.DamageMin = 32
SWEP.RangeMin = 0
SWEP.Range = 320
SWEP.Penetration = 10
SWEP.DamageType = DMG_BULLET
SWEP.MuzzleVelocity = 2000

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 29

SWEP.TracerNum = 1
SWEP.TracerCol = Color(250, 0, 0)
SWEP.TracerWidth = 1
SWEP.Tracer = "new_tracer_red"
SWEP.HullSize = 1

SWEP.Recoil = 1.2
SWEP.RecoilSide = 0.4
SWEP.RecoilRise = 0.6
SWEP.MaxRecoilBlowback = 1
SWEP.RecoilPunch = 1
SWEP.RecoilVMShake = 1

SWEP.Delay = 60 / 430
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
		Mode = -3,
        PostBurstDelay = 0.1,
    },
}

SWEP.AccuracyMOA = 0.5
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 100
SWEP.JumpDispersion = 500

SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.30

SWEP.Primary.Ammo = "ar2"
SWEP.ShootVol = 120
SWEP.ShootPitch = 95
SWEP.ShootPitchVariation = 0.2

SWEP.FirstShootSound = "kraken/explosives/g125/g125.wav"
SWEP.ShootSound = "kraken/explosives/g125/g125.wav"
SWEP.DistantShootSound = "ArcCW_Kraken.HeavyCorebass_GL"
SWEP.ShootSoundSilenced = false

SWEP.NoFlash = nil
SWEP.MuzzleEffect = "blaster_muzzle_red"
SWEP.FastMuzzleEffect = false
SWEP.GMMuzzleEffect = false
SWEP.MuzzleFlashColor = Color(250, 0, 0)

SWEP.IronSightStruct = {
    Pos = Vector(-4.761, 0, 1.199),
    Ang = Vector(0, 0, 0),
     Magnification = 1.5,
     SwitchToSound = "kraken/launchers/rps/wfoly_la_rpapa7_ads_up.ogg",
     SwitchFromSound = "kraken/launchers/rps/wfoly_la_rpapa7_ads_down.ogg",
     ViewModelFOV = 55,
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.SprintPos = Vector(2, -1, 0)
SWEP.SprintAng = Angle(-10, 26, 0)

SWEP.CustomizePos = Vector(10, 0, 2)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.CrouchPos = Vector(-3, 0, 3)
SWEP.CrouchAng = Angle(0, 0, 0)

SWEP.ActivePos = Vector(-3, 2, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.DefaultElements = {"muzzle"}
SWEP.AttachmentElements = {
    ["muzzle"] = {
        VMElements = {
            {
                Model = "models/hunter/plates/plate.mdl",
                Bone = "dlt34",
                Scale = Vector(0, 0, 0),                
                Offset = {
                    pos = Vector(-2, 2, 17),
                    ang = Angle(90, 0, 0),
                },
                IsMuzzleDevice = true,
            }
         }, 
    },
}

SWEP.Attachments = {
    {
        PrintName = "Tactical",
        DefaultAttName = "None",
        Slot = {"tactical", "tac_pistol", "tac"},
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "dlt34", 
        Offset = {
            vpos = Vector(-0.8, 0, 10),
            vang = Angle(90, 0, -180),
        },
    },   
    {
        PrintName = "Internal Modifications",
        DefaultAttName = "None",
        Slot = "uc_fg",
    },  
    {
        PrintName = "Mode", 
        DefaultAttName = "Blaster",
        Slot = "g125_mode",
    }, 
    {
        PrintName = "Ammunition", 
        DefaultAttName = "Standard",
        Slot = "ammo",
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
        VMScale = Vector(0.7, 0.7, 0.7),
        WMScale = Vector(0.7, 0.7, 0.7),
        Bone = "dlt34",
        Offset = {
            vpos = Vector(0.85, -0.05, 4.3),
            vang = Angle(90, 0, -90),
        },
    },         
    {
        PrintName = "Camouflage",
        Slot = "universal_camo",
    },
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
        Mult = 9,
    },
    ["fire"] = {
        Time = 0.6,
        Source = {"fire"},
    },
    ["fire_iron"] = {
        Time = 0.6,
        Source = {"fire"},
    },
    ["draw"] = {
        Source = "draw",
        SoundTable = {
            {
                s = "arccw/kraken/empire/draw_rifle.wav",
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
                s = "arccw/kraken/empire/draw_rifle.wav",
                p = 100,
                v = 100,
                t = 0.1,
                c = CHAN_ITEM,
            },
        }
    },
    ["reload"] = {
        Source = "overheat", 
        Mult = 2.2,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
    ["fix"] = {
        Source = "overheat", 
        Mult = 2.5,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        SoundTable = {
            {s = "ArcCW_Kraken.Overheat", t = 1 / 30},
            {s = "ArcCW_Kraken.OverheatReplenished", t = 55 / 30},
            {s = "ArcCW_Kraken.Grab", t = 53 / 30},
        },
    },
}
