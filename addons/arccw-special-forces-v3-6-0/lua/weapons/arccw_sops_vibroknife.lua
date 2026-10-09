SWEP.Base = "arccw_base_melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Category = "[ArcCW] Kraken's Special Forces"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.PrintName = "Vibroknife"
SWEP.Trivia_Class = "Knife"
SWEP.SubCategory = "7Melee"
SWEP.Trivia_Desc = "A vibroknife, or vibro-knife, was a blade that used an internal generator to make the blade vibrate. These vibrations could make even a glancing blow into a huge, gruesome slash, thus making it a far more effective weapon in close combat, or as a tool. These small weapons were openly used by all denizens of the Galactic Republic, from clone commandos to regular citizens."
SWEP.IconOverride = "entities/kraken/sops/vibroknife.png"

SWEP.Slot = 0

SWEP.NotForNPCs = true
SWEP.UseHands = true
SWEP.MirrorVMWM = true
SWEP.ViewModel = "models/arccw/kraken/sops/new/v_vibroknife.mdl"
SWEP.WorldModel = "models/arccw/kraken/sops/world/w_vibroknife.mdl"
SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(-6.5, -18, -3),
    ang = Angle(-20, -20, -90 + 0)
}

SWEP.PrimaryBash = true

SWEP.MeleeDamage = 30
SWEP.MeleeRange = 32
SWEP.MeleeDamageType = DMG_SLASH
SWEP.MeleeTime = 0.5
SWEP.MeleeGesture = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
SWEP.MeleeAttackTime = 0.1

SWEP.Melee2 = true
SWEP.Melee2Damage = 50
SWEP.Melee2Range = 32
SWEP.Melee2Time = 1
SWEP.Melee2Gesture = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
SWEP.Melee2AttackTime = 0.1

SWEP.NotForNPCs = true

SWEP.MeleeSwingSound = {
    "kraken/sops_new/csgo_knife/knife_slash1.wav",
    "kraken/sops_new/csgo_knife/knife_slash2.wav"
}
SWEP.MeleeHitSound = {
    "kraken/sops_new/csgo_knife/knife_hitwall1.wav",
    "kraken/sops_new/csgo_knife/knife_hitwall2.wav",
    "kraken/sops_new/csgo_knife/knife_hitwall3.wav",
    "kraken/sops_new/csgo_knife/knife_hitwall4.wav"
}
SWEP.MeleeHitNPCSound = {
    "kraken/sops_new/csgo_knife/knife_hit1.wav",
    "kraken/sops_new/csgo_knife/knife_hit2.wav",
    "kraken/sops_new/csgo_knife/knife_hit3.wav",
    "kraken/sops_new/csgo_knife/knife_hit4.wav",
}

SWEP.Firemodes = {
    {
        Mode = 1,
    },
}

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "knife"

SWEP.Primary.ClipSize = -1

SWEP.Animations = {
    ["idle"] = {
        Source = {"idle1", "idle2"},
    },
    ["draw"] = {
        Source = "draw",
        Time = 0.5,
    },
    ["bash"] = {
        Source = {"light_hit1", "light_hit2", "light_backstab", "light_backstab2"},
        Time = 1,
    },
    ["bash2"] = {
        Source = {"heavy_hit1", "heavy_backstab"},
        Time = 1.75
    }
}

SWEP.IronSightStruct = false

SWEP.ActivePos = Vector(0, -2, 0)

SWEP.BashPreparePos = Vector(0, 0, 0)
SWEP.BashPrepareAng = Angle(0, 5, 0)

SWEP.BashPos = Vector(0, 0, 0)
SWEP.BashAng = Angle(10, -10, 0)

SWEP.HolsterPos = Vector(0, -1, 2)
SWEP.HolsterAng = Angle(-15, 0, 0)

SWEP.AttachmentElements = {
    ["wepcamo-hyper"]		= { VMSkin = 1 },
    ["wepcamo-tiger"]		= { VMSkin = 2 },
    ["wepcamo-us"]	= { VMSkin = 3 },
    ["wepcamo-uk"]		= { VMSkin = 4 },
    ["wepcamo-disarray"]		= { VMSkin = 5 },
    ["wepcamo-camo"]	= { VMSkin = 6 },
    ["wepcamo-digital"]	= { VMSkin = 7 },
    ["wepcamo-asimov"]		= { VMSkin = 8 },
}

SWEP.Attachments = {
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
    },
    {
        PrintName = "Camouflage",
        DefaultAttName = "Standard",
        Slot = "rep_vibrocamo",
    },
}
