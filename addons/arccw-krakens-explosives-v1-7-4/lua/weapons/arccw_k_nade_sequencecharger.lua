AddCSLuaFile()

SWEP.Base = "arccw_k_nade_base"
SWEP.Spawnable = true

SWEP.Slot = 4

SWEP.Category = "[ArcCW] Kraken's Explosives - Grenades"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Sequencer Charge"
SWEP.Trivia_Class = "Mine"
SWEP.Trivia_Desc = "Sequencer Charges are military mines specially developed by Holowan Laboratories to destroy ships and facilities by targeting the vulnerable power structure. When placed precisely at key exhaust ports and power junctions, the Sequencer Charge interrupts critical regulating processes which can destabilize the core in a cascade of system failures, resulting in a catastrophic explosion. These charges can be planted offensively by raiding parties conducting boarding actions, or defensively to prevent facilities and wrecks from being captured. The intensity of the detonation can be useful for a variety of other tactical purposes as well, and these mines are frequently deployed as breaching charges to blast holes in reinforced doors or duracrete walls."
SWEP.Trivia_Manufacturer = "Holowan Laboratories"
SWEP.Trivia_Calibre = "High Explosive"
SWEP.Trivia_Mechanism = "Explosive"
SWEP.Trivia_Country = "Universal"

SWEP.DefaultBodygroups = "0000000000"
SWEP.MirrorVMWM = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/sw/explosives/v_sequencecharge.mdl"
SWEP.WorldModel = "models/arccw/kraken/sw/explosives/world/w_sequencer_charge.mdl"

SWEP.ViewModelFOV = 60

SWEP.WorldModelOffset = {
    pos = Vector(-10, 5, -4),
    ang = Angle(-10, 0, -180),
    scale = 0.9,
    bone = "ValveBiped.Bip01_R_Hand",
}

SWEP.ShootEntity = "arccw_nade_k_thrown_sequencecharger"

SWEP.MuzzleVelocity = 800
SWEP.MuzzleVelocityAlt = 700

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 1

SWEP.FuseTime = 3.5
SWEP.PullPinTime = 0.5

SWEP.Num = 1
SWEP.Firemodes = {
    {
        Mode = 1,
    },
}

SWEP.SpeedMult = 0.925
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.35
SWEP.ShootSpeedMult = 0.9

SWEP.Primary.Ammo = "grenade"

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "slam"
SWEP.HoldtypeSights = "slam"
SWEP.HoltypeCustomize = "slam"
SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(0,0,0)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CrouchPos = Vector(-4.5, -2, -1)
SWEP.CrouchAng = Angle(0, 0, -29)

SWEP.CustomizePos = Vector(10, 0, 0)
SWEP.CustomizeAng = Angle(6.8, 30.7, 10.3)

SWEP.HolsterPos = Vector(4, -3, 2)
SWEP.HolsterAng = Vector(-15, 30, -15)

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["draw"] = {
        Source = "deploy",
        EventTable = {
            {s = "ArcCW_Kraken.Explosives.Draw", t = 0.1/30},
        },
    },
    ["holster"] = {
        Source = "holster",
        EventTable = {
            {s = "ArcCW_Kraken.Explosives.Holster", t = 0.1/30},
        },
    },
    ["throw"] = {
        Source = "throw",
        EventTable = {
            {s = "ArcCW_Kraken.Explosives.Throw", t = 0.1/30},
        },
        MinProgress = 0.4
    },
    ["bash"] = {
        Source = {"melee","melee2","melee3"}
    },
}
