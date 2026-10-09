AddCSLuaFile()

ENT.Base = "eoc_droid_base"
ENT.PrintName = "B1 Kampfdroide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Standard-Infanterie der KUS. Allein schwach, in Gruppen gefaehrlich.
ENT.Model = "models/npc/b1_battledroids/assault/b1_battledroid_assault.mdl"
ENT.Weapon = "e5"
ENT.HP = 60
ENT.ShootingRange = 1200
ENT.LooseRadius = 2600
ENT.Inaccuracy = 0.22
ENT.Speed = 100
ENT.ShootWhileMoving = true
ENT.StrafeChance = 0.05

ENT.Melee = true
ENT.MeleeDamage = 15
ENT.MeleeDelay = 2.5

ENT.ThrowGrenades = true
ENT.Grenades = { "eoc_droid_grenade" }

ENT.Sounds = "b1"

ENT.Anims = {
    ["idle"] = { "idle_all_01", "Idle_Relaxed_SMG1_1", "idle_alert_smg1_1", "idle_subtle" },
    ["shoot"] = { "shoot_shotgun", "shootp1", "crouch_shoot_smg1" },
    ["reload"] = { "reload_ar2", "reload_smg1", "reload_shotgun1", "crouch_reload_smg1" },
    ["walk_slow"] = { "walk_all", "walkAIMALL1", "walkHOLDALL1_ar2", "walk_holding_RPG_all" },
    ["walk_fast"] = { "run_protected_all", "run_all", "run_alert_holding_all", "run_alert_aiming_ar2_all" },
    ["melee"] = { "swing" },
    ["throw"] = { "grenThrow", "throw1" },
}
