ENT.Base = "base_nextbot"
ENT.Type = "nextbot"
ENT.PrintName = "EoC Droiden-Basis"
ENT.Author = "Echoes of Clones (Basis: Summe)"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.IsEOCDroid = true

-- ============================================================
-- STANDARDWERTE (werden von den einzelnen Droiden ueberschrieben)
-- ============================================================
ENT.Model = "models/npc/b1_battledroids/assault/b1_battledroid_assault.mdl" -- String oder Liste
ENT.FallbackModel = "models/combine_soldier.mdl"
ENT.Weapon = "e5"                 -- Schluessel aus EOCDroids.Weapons ("" = keine Fernkampfwaffe)
ENT.HP = 100
ENT.Scale = 1
ENT.HullWidth = 13                -- halbe Breite der Kollisionsbox (vor Skalierung)
ENT.HullHeight = 70
ENT.EyeHeight = 60
ENT.Tint = nil                    -- Color(...) zum Einfaerben

ENT.ShootingRange = 1100
ENT.LooseRadius = 2500
ENT.Inaccuracy = 0.2              -- 0 = trifft immer, hoeher = ungenauer
ENT.Speed = 100
ENT.RunMultiplier = 2.4
ENT.ShootWhileMoving = false
ENT.StrafeChance = 0              -- Chance pro KI-Tick, beim Schiessen die Position zu wechseln

ENT.DamageScale = 1               -- erlittener Schaden (Panzerung < 1)
ENT.BlastDamageScale = 1          -- erlittener Explosionsschaden

ENT.Melee = false
ENT.MeleeDamage = 20
ENT.MeleeDelay = 2
ENT.MeleeRange = 70
ENT.MeleeKnockback = 500
ENT.MeleeFadeColor = Color(255, 0, 0, 90)
ENT.MeleeSounds = {
    "physics/metal/metal_canister_impact_hard1.wav",
    "physics/metal/metal_canister_impact_hard2.wav",
    "physics/metal/metal_canister_impact_hard3.wav",
    "physics/metal/metal_box_strain1.wav",
}

ENT.ThrowGrenades = false
ENT.Grenades = { "eoc_droid_grenade" }

ENT.CanDodge = false
ENT.Jetpack = false
ENT.CanGrab = false

ENT.NameTagColor = Color(150, 0, 0, 230)
ENT.NameTagOffset = 12

ENT.Sounds = nil

ENT.Anims = {
    ["idle"] = { "idle_all_01", "idle_subtle", "Idle_Relaxed_SMG1_1", "idle_alert_smg1_1", "idle1" },
    ["shoot"] = { "shoot_smg1", "shoot_shotgun", "shootp1" },
    ["reload"] = { "reload_smg1", "reload_ar2", "reload_shotgun1" },
    ["walk_slow"] = { "walk_all", "walkAIMALL1", "walkHOLDALL1_ar2" },
    ["walk_fast"] = { "run_all", "run_protected_all", "run_alert_holding_all" },
    ["melee"] = { "swing", "MeleeAttack01", "meleeattack01" },
    ["jump"] = { "jump_holding_jump", "jump_holding_glide", "jump" },
}

-- Gemeinsame Sprachausgabe der B1-Familie
ENT.B1Sounds = {
    ["hit"] = {
        "summe/nextbots/droids/b1/clonewars/huh.mp3",
        "summe/nextbots/droids/b1/clonewars/no.mp3",
        "summe/nextbots/droids/b1/clonewars/oh-no.mp3",
        "summe/nextbots/droids/b1/clonewars/problem.mp3",
        "summe/nextbots/droids/b1/clonewars/uh-oh.mp3",
        "summe/nextbots/droids/b1/clonewars/ouch.mp3",
    },
    ["killed"] = {
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_01.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_02.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_03.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_04.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_05.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_06.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_07.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_08.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_09.mp3",
        "summe/nextbots/droids/b1/clonewars/scream.mp3",
    },
    ["attacking"] = {
        "summe/nextbots/droids/b1/clonewars/blast-em.mp3",
        "summe/nextbots/droids/b1/clonewars/charge.mp3",
        "summe/nextbots/droids/b1/clonewars/cut-chatter.mp3",
        "summe/nextbots/droids/b1/clonewars/hold-it.mp3",
        "summe/nextbots/droids/b1/clonewars/my-programming.mp3",
        "summe/nextbots/droids/b1/clonewars/prepare-fire.mp3",
        "summe/nextbots/droids/b1/clonewars/roger-roger.mp3",
        "summe/nextbots/droids/b1/clonewars/said-hold-it.mp3",
        "summe/nextbots/droids/b1/clonewars/surrender-jedi.mp3",
        "summe/nextbots/droids/b1/clonewars/what-was-that.mp3",
        "summe/nextbots/droids/b1/clonewars/youre-welcome.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_012.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_013.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_014.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_015.mp3",
    },
}

ENT.B2Sounds = {
    ["hit"] = {
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_01.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_02.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_03.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_04.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_05.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_06.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_07.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_08.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_09.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_10.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_11.mp3",
        "summe/nextbots/droids/b1/hit/mp_core_separatist_inworld_assaultspecialist_soldierhit_12.mp3",
    },
    ["killed"] = {
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_01.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_04.mp3",
        "summe/nextbots/droids/b1/hit_grunts/shared_emotes_deathscream_separatist_trooper_07.mp3",
    },
    ["attacking"] = {
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_01.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_02.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_03.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_04.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_05.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_06.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_07.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_08.mp3",
        "summe/nextbots/droids/b1/enemy_hit/mp_core_separatist_inworld_assaultspecialist_enemyhit_09.mp3",
    },
}

-- ============================================================
-- GETEILTE FUNKTIONEN
-- ============================================================
function ENT:GetEnemy()
    return self:GetNW2Entity("EOCEnemy")
end

function ENT:HasEnemy()
    return IsValid(self:GetEnemy())
end

function ENT:GetWeaponData()
    local key = self:GetNW2String("EOCWeapon", "")
    if key == "" then return nil end
    return EOCDroids.Weapons[key]
end
