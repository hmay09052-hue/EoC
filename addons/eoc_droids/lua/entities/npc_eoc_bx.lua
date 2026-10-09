AddCSLuaFile()

ENT.Base = "eoc_droid_base"
ENT.PrintName = "BX Kommandodroide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Schneller, taktischer Droide mit agilen Bewegungen und Ausweichrollen.
ENT.Model = { "models/npc/bx100_commando_droid/regular/bx100_commando_droid_regular.mdl", "models/sally/tkaro/bx_commando_droid.mdl" }
ENT.Weapon = "e5_bx"
ENT.HP = 150
ENT.ShootingRange = 1100
ENT.LooseRadius = 2800
ENT.Inaccuracy = 0.1
ENT.Speed = 170
ENT.RunMultiplier = 2.1
ENT.ShootWhileMoving = true
ENT.StrafeChance = 0.12

ENT.Melee = true
ENT.MeleeDamage = 25
ENT.MeleeDelay = 1.6

ENT.CanDodge = true
ENT.DodgeChance = 0.4
ENT.DodgeDistance = 230

ENT.ThrowGrenades = true
ENT.Grenades = { "eoc_droid_impactgrenade" }

ENT.NameTagColor = Color(120, 120, 120, 230)

ENT.Anims = {
    ["idle"] = { "idle_alert_smg1_1", "Idle_Relaxed_SMG1_1", "idle_all_01" },
    ["shoot"] = { "shoot_smg1" },
    ["reload"] = { "reload_shotgun1", "reload_smg1" },
    ["walk_slow"] = { "walk_aiming_SMG1_all", "walk_hold_smg1", "walk_all" },
    ["walk_fast"] = { "run_all", "run_alert_aiming_ar2_all" },
    ["melee"] = { "swing", "MeleeAttack01" },
    ["dodge"] = { "roll_right", "roll_left", "jump_holding_jump" },
}

if SERVER then
    function ENT:OnCombatThink(enemy, dist, visible)
        if visible then self:CheckAimedAt(enemy) end
        return false
    end
end
