AddCSLuaFile()

ENT.Base = "npc_eoc_b2"
ENT.PrintName = "B2-RP Raketen-Superkampfdroide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- B2 mit Handgelenk-Raketenwerfer: feuert Raketensalven auf mittlere Distanz.
ENT.HP = 300
ENT.ShootingRange = 1400
ENT.LooseRadius = 2800
ENT.GrabChance = 0.3
ENT.Tint = Color(185, 175, 200)
ENT.NameTagColor = Color(190, 60, 0, 230)

ENT.RocketVolley = 2
ENT.RocketCooldown = { 5, 8 }

if SERVER then
    function ENT:OnCombatThink(enemy, dist, visible, now)
        if not visible or dist < 280 or dist > 1700 then return false end
        if now < (self.NextRocket or 0) or math.random() > 0.2 then return false end

        self.NextRocket = now + math.Rand(self.RocketCooldown[1], self.RocketCooldown[2])
        self:StopMoving()
        self.FacePos = enemy:GetPos()
        self:PlayAnim("shoot", 0.4 * self.RocketVolley + 0.3)

        for i = 1, self.RocketVolley do
            timer.Simple((i - 1) * 0.35, function()
                if not IsValid(self) or not IsValid(enemy) then return end
                self:FireRocket(enemy, (i % 2 == 0) and 10 or -10)
            end)
        end

        return true
    end
end
