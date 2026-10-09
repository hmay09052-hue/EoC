AddCSLuaFile()

ENT.Base = "npc_eoc_b1"
ENT.PrintName = "B1 Jetpack-Droide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Springt mit dem Jetpack ueber das Schlachtfeld und flankiert.
ENT.HP = 75
ENT.Speed = 110
ENT.Jetpack = true
ENT.JetChance = 0.15
ENT.JetCooldown = 5
ENT.JetHeight = 260
ENT.JetMinDist = 300
ENT.Tint = Color(175, 195, 235)
ENT.NameTagColor = Color(60, 110, 200, 230)

if SERVER then
    function ENT:OnDroidSpawn()
        self.loco:SetGravity(500)
    end

    function ENT:OnCombatThink(enemy, dist, visible)
        if self:TryJetpack(enemy, dist) then return true end
        return false
    end

    function ENT:OnDroidKilled(dmg)
        if not self.loco:IsOnGround() then
            self:Explode(160, 30)
        end
        return false
    end
else
    function ENT:DrawExtras()
        self:DrawJetpackFlame()
    end
end
