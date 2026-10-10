AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Thermal Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_thermal.mdl"
ENT.FuseTime = 2

DEFINE_BASECLASS("arccw_kraken_nade_base")

ENT.Radius = 500
ENT.Damage = 450
ENT.ImpactDamage = 2
ENT.DamageFalloffStart = 96

local glowMat = Material("sprites/light_glow02_add")
local flareMat = Material("sprites/orangeflare1")

function ENT:Initialize()
    if SERVER then
        BaseClass.Initialize(self)
        self:SetSkin(self.Skin or 0)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:SetBuoyancyRatio(0) end
        self:SetPhysicsAttacker(self:GetOwner(), 5)
        self:EmitSound("kraken/explosives/thermaldetonator/beeps.wav", 80, 100, 1, CHAN_AUTO)
        util.SpriteTrail(self, 0, Color(255, 60, 60, 150), false, 8, 2, 0.3, 1 / 8, "trails/laser")
    end
end

function ENT:PhysicsCollide(data, physobj)
    if CLIENT or self.Defused then return end
    if data.Speed > 25 then
        self:EmitSound("ArcCW_Kraken.Explosives.Bounce")
    end
    if data.Speed > 75 and IsValid(data.HitEntity) and not data.HitEntity:IsWorld() and (self.NextHit or 0) < CurTime() then
        self.NextHit = CurTime() + 0.1
        local dmg = DamageInfo()
        dmg:SetDamageType(DMG_GENERIC)
        dmg:SetDamage(self.ImpactDamage)
        dmg:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
        dmg:SetInflictor(self)
        dmg:SetDamageForce(data.OurOldVelocity * 0.5)
        data.HitEntity:TakeDamageInfo(dmg)
    end
end

function ENT:Think()
    if CLIENT or self.Defused then return end
    ArcCW_Kraken_GrenadeEntitySweep(self)
    if self.SpawnTime and CurTime() - self.SpawnTime >= self.FuseTime then
        self:Detonate()
        return
    end
    self:NextThink(CurTime() + 0.1)
    return true
end

function ENT:Detonate()
    if CLIENT or self.Defused then return end
    self.Defused = true

    local pos = self:GetPos()
    local attacker = IsValid(self.Owner) and self.Owner or self
    local radius, falloffStart = self.Radius, self.DamageFalloffStart
    local radiusSqr, falloffStartSqr = radius * radius, falloffStart * falloffStart
    local falloffRangeSqr = radiusSqr - falloffStartSqr

    if self:WaterLevel() >= 1 then
        ArcCW_Kraken_WaterExplosionFX(pos)
        self:EmitSound("weapons/underwater_explode3.wav", 125, 100, 1, CHAN_AUTO)
    else
        ArcCW_Kraken_GrenadeExplosionFX(pos)
        util.ScreenShake(pos, 25, 4, 1, 1400)
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion")
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion_Distant")
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion_FarDist")
    end

    for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
        if not IsValid(ent) then continue end
        local targetPos = ent:WorldSpaceCenter()
        local tr = util.TraceLine({start = pos, endpos = targetPos, filter = {self, ent}, mask = MASK_SOLID_BRUSHONLY})
        if tr.Hit and tr.Fraction < 0.98 then continue end
        local distSqr = ent:GetPos():DistToSqr(pos)
        local f = math.max(distSqr > falloffStartSqr and (1 - (distSqr - falloffStartSqr) / falloffRangeSqr * 0.75) or 1, 0.25)
        local dmg = DamageInfo()
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetAttacker(attacker)
        dmg:SetDamage(self.Damage * f)
        dmg:SetDamageForce((targetPos - pos):GetNormalized() * 9001 * f)
        dmg:SetInflictor(self)
        ent:TakeDamageInfo(dmg)
    end

    util.Decal("Scorch", pos, pos - Vector(0, 0, 16))
    self:Remove()
end

function ENT:DrawTranslucent() self:Draw() end

function ENT:Draw()
    self:DrawModel()
    if not CLIENT then return end
    
    local pos = self:GetPos()
    local spawnTime = self.SpawnTime or self:GetCreationTime()
    local fuseProgress = math.Clamp((CurTime() - spawnTime) / self.FuseTime, 0, 1)
    local pulse = 0.5 + 0.5 * math.sin(CurTime() * (4 + fuseProgress * 12))
    local intensity = 0.3 + fuseProgress * 0.7
    local glowSize = (12 + fuseProgress * 16) * pulse
    
    render.SetMaterial(glowMat)
    render.DrawSprite(pos, glowSize, glowSize, Color(255, 150 - fuseProgress * 80, 50, 200 * intensity))
    
    if fuseProgress > 0.7 then
        render.SetMaterial(flareMat)
        render.DrawSprite(pos, (fuseProgress - 0.7) * 50 * pulse, (fuseProgress - 0.7) * 50 * pulse, Color(255, 100, 30, 150))
    end
    
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = pos
        dlight.r, dlight.g, dlight.b = 255, 150 - fuseProgress * 50, 50
        dlight.brightness = 1.5 * intensity * pulse
        dlight.decay = 100
        dlight.size = 80 + fuseProgress * 40
        dlight.dietime = CurTime() + 0.05
    end
end