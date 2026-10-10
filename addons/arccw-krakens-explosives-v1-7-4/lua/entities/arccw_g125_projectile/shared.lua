AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Fuel Rod Projectile"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_impact.mdl"
ENT.FuseTime = 7
ENT.ArmTime = 0
ENT.ImpactFuse = false

function ENT:Initialize()
    if SERVER then
        ParticleEffectAttach("astw2_halo_ce_fuel_rod_trail", PATTACH_POINT_FOLLOW, self, 0)
        self:SetModel(self.Model)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
        self:DrawShadow(false)

        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:Wake()
            phys:SetMass(1)
            phys:SetBuoyancyRatio(0)
        end

        self.kt = CurTime() + self.FuseTime
        self.at = CurTime() + self.ArmTime
        self.bt = CurTime() + 1
        self.motorsound = CreateSound(self, "kraken/explosives/g125/plasma_grenade_plasma_projectile_plas_grenlp1.wav")
    else
        ParticleEffectAttach("astw2_halo_ce_fuel_rod_trail", PATTACH_POINT_FOLLOW, self, 0)
    end
end

function ENT:OnRemove()
    if SERVER and self.motorsound:IsPlaying() then self.motorsound:Stop() end
end

function ENT:Arm()
    if SERVER then self.motorsound:Play() end
end

function ENT:PhysicsCollide(data, physobj)
    if SERVER and data.Speed > 25 then self:Detonate() end
    if self.at <= CurTime() and self.ImpactFuse then self:Detonate() end
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("StunstickImpact", effectdata)
end

function ENT:ClientThink()
    self:SetAngles(self:GetVelocity():Angle() + Angle(90, 0, -90))
    return 0.3
end

function ENT:Think()
    if SERVER then self:NextThink(self:ServerThink() or 0.3) end
    if CLIENT then self:SetNextClientThink(self:ClientThink() or 0.3) end
    return true
end

function ENT:ServerThink()
    if CurTime() >= self.at then
        for _, k in ipairs(ents.FindInSphere(self:GetPos(), 16)) do
            if (k:IsPlayer() or k:IsNPC()) and self:Visible(k) and k:Health() > 0 then
                self:Detonate()
            elseif k:IsValid() and scripted_ents.IsBasedOn(k:GetClass(), "base_nextbot") then
                self:Detonate()
            end
        end
    end
    if CurTime() >= self.kt then self:Detonate() end
    return 0.2
end

function ENT:Detonate()
    if not SERVER or not self:IsValid() then return end
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())

    if self:WaterLevel() >= 1 then
        util.Effect("WaterSurfaceExplosion", effectdata)
    else
        ParticleEffect("astw2_halo_2_fuel_rod_explosion", self:GetPos(), self:GetAngles())
        self:EmitSound("kraken/explosives/g125/fuelrod_expl_" .. math.random(1, 3) .. ".ogg", 125)
        sound.Play("kraken/explosives/g125/fuelrod_expl_" .. math.random(1, 3) .. ".ogg", self:GetPos(), 155, math.random(85, 100), 1)
        util.ScreenShake(self:GetPos(), 5000, 100, 0.5, 1024)
    end

    local attacker = IsValid(self.Owner) and self.Owner or self
    util.BlastDamage(self, attacker, self:GetPos(), 400, 300)
    self:Remove()
end

function ENT:Draw()
end