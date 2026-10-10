AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Plasma Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_plasmagrenade.mdl"
ENT.FuseTime = 3

DEFINE_BASECLASS("arccw_kraken_nade_base")

ENT.Radius = 600
ENT.Damage = 1000
ENT.ImpactDamage = 2
ENT.DamageFalloffStart = 96

local glowMat = Material("sprites/light_glow02_add")
local plasmaMat = Material("sprites/bluelaser1")
local plasmaCoreMat = Material("sprites/physg_glow1")

function ENT:Initialize()
    if SERVER then
        BaseClass.Initialize(self)
        self:SetSkin(self.Skin or 0)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:SetBuoyancyRatio(0) end
        self:SetPhysicsAttacker(self:GetOwner(), 5)
        self:EmitSound("kraken/explosives/ion/beep.wav", 90, 100, 1, CHAN_AUTO)
        util.SpriteTrail(self, 0, Color(35, 202, 228, 150), false, 8, 2, 0.3, 1 / 8, "trails/laser")
    end
end

function ENT:PhysicsCollide(data, physobj)
    if CLIENT or self.Defused then return end
    if data.Speed > 25 then
        self:EmitSound("ArcCW_Kraken.Explosives.Bounce")
        local fx = EffectData()
        fx:SetOrigin(data.HitPos)
        fx:SetNormal(data.HitNormal)
        util.Effect("StunstickImpact", fx, true, true)
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
        local fx = EffectData()
        fx:SetOrigin(pos)
        util.Effect("WaterSurfaceExplosion", fx)
        self:EmitSound("weapons/underwater_explode3.wav", 125, 100, 1, CHAN_AUTO)
    else
        local explode = ents.Create("info_particle_system")
        if IsValid(explode) then
            explode:SetKeyValue("effect_name", "cryo_explosion_large")
            explode:SetOwner(attacker)
            explode:SetPos(pos)
            explode:Spawn()
            explode:Activate()
            explode:Fire("start", "", 0)
            explode:Fire("kill", "", 30)
        end
        self:EmitSound("kraken/explosives/ion/close" .. math.random(1, 2) .. ".wav", 95, 100, 1, CHAN_AUTO)
        local interiorSounds = {1, 3}
        self:EmitSound("kraken/explosives/ion/interior" .. interiorSounds[math.random(#interiorSounds)] .. ".wav", 125, 100, 1, CHAN_AUTO)
        util.ScreenShake(pos, 25, 4, 1, 1680)
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

    util.Decal("Scorch", pos, pos - Vector(0, 0, 30))
    self:Remove()
end

function ENT:DrawTranslucent() self:Draw() end

function ENT:Draw()
    self:DrawModel()
    if not CLIENT then return end
    
    local pos = self:GetPos()
    local spawnTime = self.SpawnTime or self:GetCreationTime()
    local fuseProgress = math.Clamp((CurTime() - spawnTime) / self.FuseTime, 0, 1)
    local pulse = 0.6 + 0.4 * math.sin(CurTime() * (6 + fuseProgress * 10))
    local coreSize = (14 + fuseProgress * 12) * pulse
    
    render.SetMaterial(glowMat)
    render.DrawSprite(pos, coreSize, coreSize, Color(35, 202, 228, 200))
    
    local outerSize = (20 + fuseProgress * 8) * (0.5 + 0.5 * math.sin(CurTime() * 4 + 1.5))
    render.SetMaterial(plasmaCoreMat)
    render.DrawSprite(pos, outerSize, outerSize, Color(100, 220, 255, 100))
    
    if fuseProgress > 0.5 and math.random() < (fuseProgress - 0.5) * 0.6 then
        render.SetMaterial(plasmaMat)
        render.DrawSprite(pos + VectorRand() * 8, 4, 4, Color(200, 255, 255, 255))
    end
    
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = pos
        dlight.r, dlight.g, dlight.b = 35, 180 + fuseProgress * 40, 255
        dlight.brightness = (1.2 + fuseProgress * 1.5) * pulse
        dlight.decay = 120
        dlight.size = 90 + fuseProgress * 50
        dlight.dietime = CurTime() + 0.05
    end
end