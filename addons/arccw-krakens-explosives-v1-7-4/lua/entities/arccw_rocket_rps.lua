AddCSLuaFile()

ENT.Base = "arccw_rocket_base"
ENT.PrintName = "RPS-6 Rocket"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Model = "models/arccw/kraken/sw/explosives/world/hh12_missile.mdl"

ENT.Ticks = 0
ENT.FuseTime = 0
ENT.Defused = false
ENT.SphereSize = 1
ENT.PhysMat = "grenade"
ENT.Boost = 14000
ENT.LifeTime = 20
ENT.GravityScale = 0
ENT.ExplodeOnImpact = true
ENT.StandardExplosionEffect = "cod2019_grenade_explosion"
ENT.StandardExplosionRadius = 650
ENT.StandardExplosionSound = "ArcCW_Kraken.Explosives.HeavyRocketImpact"
ENT.StandardExplosionSound_Dist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_Dist"
ENT.StandardExplosionSound_FarDist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_FarDist"

function ENT:PhysicsCollide(colData, physobj)
    if not self:IsValid() then return end
    self.LastHitNormal = colData.HitNormal
    self.HitPos = colData.HitPos
    self.HitVelocity = colData.OurOldVelocity

    if not self.ExplodeOnImpact then return end
    
    if CurTime() - (self.SpawnTime or 0) < (self.FuseTime or 0) then
        if IsValid(colData.HitEntity) then
            local dmg = DamageInfo()
            dmg:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
            dmg:SetInflictor(self)
            dmg:SetDamageType(DMG_CRUSH)
            dmg:SetDamage(colData.OurOldVelocity:Length() ^ 0.5)
            dmg:SetDamagePosition(colData.HitPos)
            dmg:SetDamageForce(colData.OurOldVelocity)
            colData.HitEntity:TakeDamageInfo(dmg)
            if SERVER then self:EmitSound("weapons/rpg/shotdown.wav", 125, math.random(95, 105), 1, CHAN_WEAPON) end
        end
        timer.Simple(0, function() if IsValid(self) and self.Defuse then self:Defuse() end end)
        return
    end

    timer.Simple(0, function()
        if not IsValid(self) then return end
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    end)
    timer.Simple(0, function() if IsValid(self) then self:Detonate({HitNormal = colData.HitNormal, TheirSurfaceProps = colData.TheirSurfaceProps}) end end)
end

local function ComputeFallbackNormal(self, impact)
    if self.LastHitNormal and isvector(self.LastHitNormal) then return self.LastHitNormal end
    if impact and impact.HitNormal and isvector(impact.HitNormal) then return impact.HitNormal end
    local tr = util.TraceLine({start = self:GetPos(), endpos = self:GetPos() - Vector(0, 0, 64), filter = self, mask = MASK_SOLID_BRUSHONLY})
    if tr.Hit and tr.HitNormal and isvector(tr.HitNormal) then return tr.HitNormal end
    local vel = self.HitVelocity or self:GetVelocity()
    if isvector(vel) and vel:LengthSqr() > 1 then return (-vel:GetNormalized()) end
    return Vector(0, 0, 1)
end

function ENT:Detonate(impact)
    impact = impact or {}
    if not self:IsValid() or self.Defused then return end
    self.Defused = true

    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self
    local pos = self:GetPos()

    self:PlayStandardExplosionFX(pos)

    if self:WaterLevel() > 0 then
        ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, 350, 350)
    else
        ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, 128, 280)
        ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, 650, 180)
    end

    if SERVER then
        self:FireBullets({Attacker = attacker, Damage = 250, Tracer = 0, Distance = 256, Dir = (self.HitVelocity or self:GetVelocity() or vector_origin), Src = pos, Callback = function(att, tr, dmg) if self.Scorch then util.Decal("Scorch", tr.StartPos, tr.HitPos - (tr.HitNormal * 16), self) end end})
    end

    timer.Simple(0, function()
        if not IsValid(self) then return end
        SafeRemoveEntityDelayed(self, self.SmokeTrailTime or 0)
        self:SetRenderMode(RENDERMODE_NONE)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    end)
end
