AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "C14 Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_c14.mdl"
ENT.FuseTime = 60

DEFINE_BASECLASS("arccw_kraken_nade_base")

ENT.Radius = 550
ENT.Damage = 900
ENT.ImpactDamage = 2
ENT.DamageFalloffStart = 96

local glowMat = Material("sprites/light_glow02_add")
local warningMat = Material("sprites/orangeflare1")

function ENT:Initialize()
    if not SERVER then return end
    BaseClass.Initialize(self)
    self:SetModel(self.Model)
    self:SetSkin(self.Skin or 0)
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:SetBuoyancyRatio(0) end
    self:SetPhysicsAttacker(self:GetOwner(), 5)
    util.SpriteTrail(self, 0, Color(255, 140, 60, 150), false, 10, 2, 0.3, 1 / 10, "sprites/orangeflare1")
    self:EmitSound("kraken/shared/beeps4.wav")
end

function ENT:PhysicsCollide(data, physobj)
    if not SERVER or self.Defused then return end
    local tgt = data.HitEntity
    if IsValid(tgt) and not tgt:IsWorld() then
        local dmginfo = DamageInfo()
        dmginfo:SetDamageType(DMG_GENERIC)
        dmginfo:SetDamage(self.ImpactDamage)
        dmginfo:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamageForce(data.OurOldVelocity * 0.5)
        tgt:TakeDamageInfo(dmginfo)
    end
    self:Detonate()
end

function ENT:Think()
    if self.Defused or not SERVER then return end
    if ArcCW_Kraken_GrenadeEntitySweep(self) then self:Detonate() return end
    if self.SpawnTime and CurTime() - self.SpawnTime >= self.FuseTime then self:Detonate() return end
    self:NextThink(CurTime() + 0.1)
    return true
end

function ENT:Detonate()
    if not SERVER or self.Defused then return end
    self.Defused = true

    local pos = self:GetPos()
    local attacker = IsValid(self.Owner) and self.Owner or self
    local radius = self.Radius
    local radiusSqr = radius * radius
    local falloffStartSqr = self.DamageFalloffStart * self.DamageFalloffStart
    local falloffRangeSqr = radiusSqr - falloffStartSqr

    if self:WaterLevel() >= 1 then
        ArcCW_Kraken_WaterExplosionFX(pos)
        self:EmitSound("weapons/underwater_explode3.wav", 125, 100, 1, CHAN_AUTO)
    else
        ArcCW_Kraken_HeavyExplosionFX(pos)
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
        local f = distSqr > falloffStartSqr and (1 - (distSqr - falloffStartSqr) / falloffRangeSqr * 0.75) or 1
        f = math.max(f, 0.25)

        local dmginfo = DamageInfo()
        dmginfo:SetDamageType(DMG_BLAST)
        dmginfo:SetAttacker(attacker)
        dmginfo:SetDamage(self.Damage * f)
        dmginfo:SetDamageForce((targetPos - pos):GetNormalized() * 9001 * f)
        dmginfo:SetInflictor(self)
        ent:TakeDamageInfo(dmginfo)

        if ent.LFS or ent.LVS then
            if ent.StopEngine then ent:StopEngine() end
            if ent.SetShield then ent:SetShield(0) end
            if ent.GetHP and ent.SetHP then ent:SetHP(ent:GetHP() / 4) end
        end
    end

    util.Decal("Scorch", pos, pos - Vector(0, 0, 16))
    util.ScreenShake(pos, 25, 4, 1, 1600)
    self:Remove()
end

function ENT:DrawTranslucent()
    self:Draw()
end

function ENT:Draw()
    self:DrawModel()
    
    if CLIENT then
        local pos = self:GetPos()
        local spawnTime = self.SpawnTime or self:GetCreationTime()
        local fuseProgress = (CurTime() - spawnTime) / self.FuseTime
        fuseProgress = math.Clamp(fuseProgress, 0, 1)
        
        local pulse = 0.7 + math.sin(CurTime() * (10 + fuseProgress * 15)) * 0.3
        local glowSize = (12 + fuseProgress * 10) * pulse
        
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, glowSize, glowSize, Color(255, 140, 60, 180 * pulse))
        
        if fuseProgress > 0.7 then
            local warningPulse = math.sin(CurTime() * 30) > 0 and 1 or 0.4
            render.SetMaterial(warningMat)
            render.DrawSprite(pos, glowSize * 1.2 * warningPulse, glowSize * 1.2 * warningPulse, Color(255, 200, 100, 255 * warningPulse))
        end
        
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 140
            dlight.b = 60
            dlight.brightness = 2 + fuseProgress * 3
            dlight.decay = 1000
            dlight.size = 80 + fuseProgress * 40
            dlight.dietime = CurTime() + 0.05
        end
    end
end