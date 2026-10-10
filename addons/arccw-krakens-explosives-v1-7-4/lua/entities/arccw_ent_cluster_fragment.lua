AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Cluster Fragment"
ENT.Spawnable = false

function ENT:Initialize()
    self:SetModel("models/Items/AR2_Grenade.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    timer.Simple(0, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE) end end)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetVelocity(VectorRand() * 300 + Vector(0, 0, 400))
    end

    self:SetNoDraw(false)
    self:SetGravity(0.6)
    self.Exploded = false
    self.PendingExplode = false

    if SERVER then
        timer.Simple(math.Rand(0.8, 1.4), function()
            if IsValid(self) and not self.Exploded and not self.PendingExplode then self.PendingExplode = true end
        end)
    end
end

function ENT:Think()
    if CLIENT or not self.PendingExplode or self.Exploded then return end
    self.PendingExplode = false
    timer.Simple(0, function()
        if not IsValid(self) then return end
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        self:SetNotSolid(true)
    end)
    self:Explode()
end

function ENT:Explode()
    if CLIENT or self.Exploded then return end
    self.Exploded = true
    local pos = self:GetPos()
    local attacker = self:GetOwner() or self

    util.BlastDamage(self, attacker, pos, 280, 85)

    local tr = util.TraceLine({start = pos, endpos = pos - Vector(0, 0, 64), filter = self})
    local hitNormal = tr.Hit and tr.HitNormal or Vector(0, 0, 1)
    ArcCW_Kraken_GrenadeExplosionFX(pos, hitNormal)

    util.ScreenShake(pos, 15, 4, 0.5, 300)
    if tr.Hit then util.Decal("Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal) end

    self:EmitSound("ArcCW_Kraken.Explosives.Explosion")
    self:EmitSound("ArcCW_Kraken.Explosives.Explosion_Distant")
    self:EmitSound("ArcCW_Kraken.Explosives.Explosion_FarDist")
    self:Remove()
end

function ENT:PhysicsCollide(data, physobj)
    if self.Exploded or self.PendingExplode then return end
    self.PendingExplode = true
end
