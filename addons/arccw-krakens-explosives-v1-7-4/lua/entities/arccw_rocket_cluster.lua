AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_rocket_base"
ENT.PrintName = "Cluster Rocket"
ENT.Spawnable = false
ENT.Model = "models/weapons/w_missile_launch.mdl"
ENT.InitialSpeed = 3000
ENT.GravityScale = 0
ENT.StandardExplosionRadius = 550
ENT.StandardExplosionDamage = 220
ENT.FragmentCount = 10

function ENT:PhysicsCollide(data, physobj)
    if self.Detonated then return end
    self:PreDetonate({ HitPos = data.HitPos })
end

function ENT:Detonate(data)
    if CLIENT then return end
    local pos = (data and data.HitPos) or self:GetPos()
    self:DoStandardExplosion({ pos = pos })

    for i = 1, self.FragmentCount do
        local frag = ents.Create("arccw_ent_cluster_fragment")
        if IsValid(frag) then
            frag:SetPos(pos + VectorRand() * 20)
            frag:SetAngles(AngleRand())
            frag:SetOwner(self:GetOwner())
            frag:Spawn()
        end
    end

    self.Defused = true
    SafeRemoveEntityDelayed(self, self.SmokeTrailTime or 0)
end
