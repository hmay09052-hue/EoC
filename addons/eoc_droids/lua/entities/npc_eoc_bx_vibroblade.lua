AddCSLuaFile()

ENT.Base = "npc_eoc_bx"
ENT.PrintName = "BX Vibroklingen-Droide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Reiner Nahkaempfer: stuermt los, springt auf Gegner zu und schlitzt mit der Vibroklinge.
ENT.Weapon = "vibroblade"
ENT.HP = 170
ENT.Speed = 190
ENT.RunMultiplier = 2.4
ENT.ShootWhileMoving = false
ENT.StrafeChance = 0
ENT.ThrowGrenades = false

ENT.MeleeDamage = 45
ENT.MeleeDelay = 1.1
ENT.MeleeRange = 65
ENT.MeleeHitDelay = 0.25
ENT.MeleeKnockback = 300
ENT.MeleeDamageType = DMG_SLASH
ENT.MeleeFadeColor = Color(255, 120, 0, 80)
ENT.MeleeSounds = {
    "weapons/stunstick/stunstick_swing1.wav",
    "weapons/stunstick/stunstick_swing2.wav",
    "physics/metal/metal_sheet_impact_bullet1.wav",
}

ENT.DodgeChance = 0.5
ENT.Tint = Color(230, 200, 200)
ENT.NameTagColor = Color(230, 110, 20, 230)

if SERVER then
    function ENT:OnCombatThink(enemy, dist, visible, now)
        if visible then self:CheckAimedAt(enemy) end

        -- Sprungangriff
        if visible and dist > 140 and dist < 480 and now >= (self.NextLunge or 0) and self.loco:IsOnGround() and math.random() < 0.35 then
            self.NextLunge = now + math.Rand(3.5, 5.5)

            local dir = enemy:GetPos() - self:GetPos()
            dir.z = 0
            dir:Normalize()

            self:StopMoving()
            self.loco:SetJumpHeight(70)
            self.loco:JumpAcrossGap(enemy:GetPos() - dir * 40, dir)
            self:PlayAnim("jump", 0.5)
            self:PlaySound("npc/fast_zombie/leap1.wav", 75, 130)
            return true
        end

        return false
    end

    function ENT:OnLanded()
        local enemy = self:GetEnemy()
        if IsValid(enemy) and self:GetPos():DistToSqr(enemy:GetPos()) < 110 * 110 then
            self.NextMelee = 0
            self:TryMelee(enemy)
        end
    end
end
