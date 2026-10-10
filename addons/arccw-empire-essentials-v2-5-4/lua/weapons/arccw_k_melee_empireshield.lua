SWEP.Base = "arccw_base_melee"
SWEP.Spawnable = true
SWEP.Category = "[ArcCW] Kraken's Empire Essentials"
SWEP.Credits = "Kraken (Discord: @elbestiamasita)"
SWEP.AdminOnly = false

SWEP.PrintName = "Imperial Shield"
SWEP.Trivia_Class = "Anti-ballistic Shield"
SWEP.SubCategory = "7Melee"
SWEP.Trivia_Desc = "Shield for the Galactic Empire. Anti-ballistic shield for entry teams. Stops bullets. Riot shields are made of flimsy plastic and designed to stop rocks and bricks, not bullets. This is a ballistic shield. Do not call it a riot shield."
SWEP.Trivia_Manufacturer = "BlasTech Industries"
SWEP.Trivia_Country = "Galactic Empire"
SWEP.IconOverride = "entities/kraken/empire-essentials/empireshield.png"

SWEP.Slot = 0

SWEP.NotForNPCs = true
SWEP.UseHands = true
SWEP.ViewModel = "models/arccw/kraken/empire/v_empire_shield.mdl"
SWEP.WorldModel = "models/arccw/kraken/empire/v_empire_shield.mdl"

SWEP.ViewModelFOV = 54

SWEP.WorldModelOffset = {
    pos = Vector(0, 15, -12),
    ang = Angle(0, 0, 180 - 15)
}

SWEP.ShieldProps = {
    {
        Model = "models/arccw/kraken/empire/v_empire_shield.mdl",
        Pos = Vector(0, -15, -12),
        Ang = Angle(0, 0, 180 - 15),
        Resistance = 100 -- basically nothing can go through the shield
    }
}

SWEP.PrimaryBash = true

SWEP.SpeedMult = 0.85

SWEP.MeleeDamage = 35
SWEP.MeleeRange = 32
SWEP.MeleeDamageType = DMG_CLUB
SWEP.MeleeTime = 1
SWEP.MeleeGesture = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE
SWEP.MeleeAttackTime = 0

SWEP.MeleeSwingSound = {
    "arccw/kraken/new_empire/shield/shield_swing_01.wav",
}
SWEP.MeleeHitSound = {
    "arccw/kraken/new_empire/shield/melee_hit_flesh_01.wav",
}
SWEP.MeleeHitNPCSound = {
    "arccw/kraken/new_empire/shield/melee_hit_flesh_04.wav",
}

SWEP.Firemodes = {
    {
        Mode = 1,
        PrintName = "MELEE"
    },
}

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "melee2"
SWEP.HoltypeCustomize = "slam"
SWEP.Primary.ClipSize = -1

SWEP.IronSightStruct = false

SWEP.ActivePos = Vector(0, 0, -0.5)

SWEP.BashPreparePos = Vector(0, 0, 0)
SWEP.BashPrepareAng = Angle(0, 5, 0)

SWEP.CustomizePos = Vector(15, 5, 0)
SWEP.CustomizeAng = Angle(0, 60, 0)

SWEP.BashPos = Vector(0, 0, 0)
SWEP.BashAng = Angle(10, -10, 0)

SWEP.HolsterPos = Vector(0, -1, 2)
SWEP.HolsterAng = Angle(-15, 0, 0)

SWEP.Attachments = {     
    {
        PrintName = "Perk",
        DefaultAttName = "None",
        Slot = "perk",
    },   
}

SWEP.Animations = {
    ["blowback"] = {
        Source = "blowback",
    },
    ["idle"] = {
        Source = "idle1",
    },
    ["ready"] = {
        Source = "draw",
        SoundTable = {
            {
                s = "arccw/kraken/new_empire/shield/shield_equip_02.wav", -- sound; can be string or table
                p = 100, -- pitch
                v = 75, -- volume
                t = 0, -- time at which to play relative to Animations.Time
                c = CHAN_ITEM, -- channel to play the sound
            },
        }
    },
    ["draw"] = {
        Source = {"draw_short"},
        SoundTable = {
            {
                s = "arccw/kraken/new_empire/shield/shield_equip_02.wav", -- sound; can be string or table
                p = 100, -- pitch
                v = 75, -- volume
                t = 0, -- time at which to play relative to Animations.Time
                c = CHAN_ITEM, -- channel to play the sound
            },
        }
    },
    ["holster"] = {
        Source = "holster",
        SoundTable = {
            {
                s = "arccw/kraken/new_empire/shield/shield_equip_02.wav", -- sound; can be string or table
                p = 100, -- pitch
                v = 75, -- volume
                t = 0, -- time at which to play relative to Animations.Time
                c = CHAN_ITEM, -- channel to play the sound
            },
        }
    },
    ["bash"] = {
        Source = {"bash1","bash2","bash3"},
		MinProgress = 0.7,
    },
    ["idle_sprint"] = {
        Source = "sprint",
    },
    ["enter_sprint"] = {
        Source = "sprint_in",
        Time = 1,
    },
    ["exit_sprint"] = {
        Source = "sprint_out",
        Time = 1,
    },
        -- Inspect --
    ["exit_inspect"] = {
        Source = "lookat01",
        FireASAP = true,
        LHIK = true,
        SoundTable = {
            {s = "arccw/kraken/interaction/movement1.wav", t = 2/30},
            {s = "arccw/kraken/interaction/movement2.wav", t = 92/30},
            {s = "arccw/kraken/interaction/movement3.wav", t = 116/30},
            -- {hide = 1, t = 0},
        },
    },
}
