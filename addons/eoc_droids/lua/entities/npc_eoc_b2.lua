AddCSLuaFile()

ENT.Base = "eoc_droid_base"
ENT.PrintName = "B2 Superkampfdroide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Gross, schwer gepanzert. Schlaegt im Nahkampf zu und packt Gegner, um sie wegzuschleudern.
ENT.Model = "models/npc/b2_battledroid/b2_battledroid.mdl"
ENT.FallbackModel = "models/combine_super_soldier.mdl"
ENT.Weapon = "b2_wrist"
ENT.HP = 320
ENT.Scale = 1.4
ENT.HullWidth = 15
ENT.HullHeight = 74
ENT.EyeHeight = 62
ENT.DamageScale = 0.55
ENT.BlastDamageScale = 0.8
ENT.ShootingRange = 900
ENT.LooseRadius = 2500
ENT.Inaccuracy = 0.18
ENT.Speed = 70
ENT.RunMultiplier = 2
ENT.ShootWhileMoving = true
ENT.StrafeChance = 0.03

ENT.Melee = true
ENT.MeleeDamage = 40
ENT.MeleeDelay = 2.2
ENT.MeleeRange = 62
ENT.MeleeKnockback = 900

ENT.CanGrab = true
ENT.GrabChance = 0.55
ENT.GrabTime = 2.5
ENT.GrabDamagePerTick = 7
ENT.GrabThrowForce = 950

ENT.Sounds = "b2"
ENT.NameTagColor = Color(150, 0, 0, 230)
ENT.NameTagOffset = 16

ENT.FootstepInterval = 0.55
ENT.FootstepSounds = {
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_1.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_2.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_3.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_4.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_5.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_6.mp3",
}

ENT.Anims = {
    ["idle"] = { "idle_alert_02", "idle_all_01", "idle_subtle" },
    ["shoot"] = { "idle_alert_02", "d2_coast03_Odessa_Stand_RPG" },
    ["reload"] = { "pace_all" },
    ["walk_slow"] = { "walk_all" },
    ["walk_fast"] = { "walk_all" },
    ["melee"] = { "swing", "MeleeAttack01" },
    ["grab"] = { "swing", "MeleeAttack01" },
}
