AddCSLuaFile()

ENT.Base = "npc_eoc_b2"
ENT.PrintName = "B2-X Jetpack-Superkampfdroide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- B2 mit Jetpack: springt in den Kampf und feuert aus der Luft Raketen.
ENT.HP = 280
ENT.ShootingRange = 1000
ENT.Jetpack = true
ENT.JetChance = 0.12
ENT.JetCooldown = 6
ENT.JetHeight = 300
ENT.JetMinDist = 380
ENT.GrabChance = 0.35
ENT.Tint = Color(200, 200, 225)
ENT.NameTagColor = Color(60, 110, 200, 230)

if SERVER then
    function ENT:OnDroidSpawn()
        self.loco:SetGravity(450)
    end

    function ENT:OnCombatThink(enemy, dist, visible, now)
        if not self.loco:IsOnGround() then
            if visible and now >= (self.NextRocket or 0) and math.random() < 0.25 then
                self.NextRocket = now + math.Rand(3, 5)
                self:FireRocket(enemy)
            end
            return false
        end

        return self:TryJetpack(enemy, dist)
    end

    function ENT:OnDroidKilled(dmg)
        if not self.loco:IsOnGround() then
            self:Explode(220, 45)
        end
        return false
    end
else
    function ENT:DrawExtras()
        self:DrawJetpackFlame()
    end
end
