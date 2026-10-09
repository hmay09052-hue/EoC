AddCSLuaFile()

ENT.Base = "npc_eoc_b1"
ENT.PrintName = "B1 Scharfschuetzendroide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Fernkampf-Spezialist. Zielt sichtbar mit einem roten Laser, dann praeziser Schuss.
ENT.Weapon = "e5_sniper"
ENT.HP = 45
ENT.ShootingRange = 3500
ENT.LooseRadius = 4200
ENT.Inaccuracy = 0.02
ENT.Speed = 90
ENT.ShootWhileMoving = false
ENT.StrafeChance = 0
ENT.ThrowGrenades = false
ENT.Tint = Color(190, 215, 160)

ENT.Anims = {
    ["idle"] = { "crouch_idleD", "Crouch_idleD", "idle_alert_smg1_1" },
    ["shoot"] = { "crouch_shoot_smg1" },
    ["reload"] = { "crouch_reload_smg1", "reload_smg1" },
    ["walk_slow"] = { "walk_all", "walkAIMALL1", "walkHOLDALL1_ar2" },
    ["walk_fast"] = { "run_protected_all", "run_all", "run_alert_holding_all" },
    ["melee"] = { "swing" },
}

if CLIENT then
    function ENT:DrawExtras()
        self:DrawAimLaser()
    end
end
