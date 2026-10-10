AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Thermal Imploder"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_thermalimploder.mdl"
ENT.FuseTime = 5

DEFINE_BASECLASS("arccw_kraken_nade_base")

ENT.Radius = 800
ENT.Damage = 5000
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
        self:EmitSound("kraken/explosives/thermalimploder/beeps.wav", 90, 100, 1, CHAN_AUTO)
        util.SpriteTrail(self, 0, Color(255, 120, 40, 150), false, 15, 3, 0.5, 1/15, "sprites/orangecore1")
    end
    self.ChargePhase = false
end

function ENT:PhysicsCollide(data, physobj)
    if CLIENT or self.Defused then return end

    local tgt, speed = data.HitEntity, data.Speed

    if speed < 15 and (not IsValid(tgt) or tgt:IsWorld()) then
        timer.Simple(0, function() if IsValid(self) then self:SetMoveType(MOVETYPE_NONE) end end)
        self:EmitSound("kraken/explosives/thermalimploder/charged.wav", 80, 100, 1, CHAN_AUTO)
        self.ChargePhase = true
        self:SetNWBool("Charging", true)
        return
    end

    if speed > 25 then
        self:EmitSound("ArcCW_Kraken.Explosives.Bounce")
    end

    if speed > 75 and IsValid(tgt) and not tgt:IsWorld() and (self.NextHit or 0) < CurTime() then
        self.NextHit = CurTime() + 0.1
        local dmg = DamageInfo()
        dmg:SetDamageType(DMG_GENERIC)
        dmg:SetDamage(self.ImpactDamage)
        dmg:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
        dmg:SetInflictor(self)
        dmg:SetDamageForce(data.OurOldVelocity * 0.5)
        tgt:TakeDamageInfo(dmg)
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
            explode:SetKeyValue("effect_name", "pyro_explode")
            explode:SetOwner(attacker)
            explode:SetPos(pos)
            explode:Spawn()
            explode:Activate()
            explode:Fire("start", "", 0)
            explode:Fire("kill", "", 30)
        end
        util.ScreenShake(pos, 25, 6, 2, 3000)
        self:EmitSound("kraken/explosives/thermalimploder/pre_explosion_a01.wav", 130, 100, 1, CHAN_AUTO)
        self:EmitSound("kraken/explosives/thermalimploder/explosion_cercana_0" .. math.random(1, 3) .. "_a01.wav", 125, 100, 1, CHAN_AUTO)
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

    util.Decal("Scorch", pos, pos - Vector(0, 0, 100))
    self:Remove()
end

function ENT:DrawTranslucent() self:Draw() end

function ENT:Draw()
    self:DrawModel()
    if not CLIENT then return end
    
    local pos = self:GetPos()
    local spawnTime = self.SpawnTime or self:GetCreationTime()
    local fuseProgress = math.Clamp((CurTime() - spawnTime) / self.FuseTime, 0, 1)
    local isCharging = self:GetNWBool("Charging", false)
    local pulse = 0.5 + 0.5 * math.sin(CurTime() * (2 + fuseProgress * 8))
    local coreColor = Color(255, 220 - fuseProgress * 120, 180 - fuseProgress * 130)
    local coreSize = (16 + fuseProgress * 24) * pulse
    
    render.SetMaterial(glowMat)
    render.DrawSprite(pos, coreSize, coreSize, ColorAlpha(coreColor, 220))
    
    if isCharging or fuseProgress > 0.6 then
        local chargeIntensity = isCharging and 1 or ((fuseProgress - 0.6) / 0.4)
        local ringSize = 40 * chargeIntensity * (0.5 + 0.5 * math.sin(CurTime() * 15))
        render.SetMaterial(flareMat)
        render.DrawSprite(pos, ringSize, ringSize, Color(255, 150, 80, 150 * chargeIntensity))
    end
    
    if fuseProgress > 0.85 and math.sin(CurTime() * 25) > 0.5 then
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, 60, 60, Color(255, 255, 255, 200))
    end
    
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = pos
        dlight.r, dlight.g, dlight.b = coreColor.r, coreColor.g, coreColor.b
        local dlightIntensity = (1 + fuseProgress * 2) * (isCharging and 1.5 or 1)
        dlight.brightness = dlightIntensity * pulse
        dlight.decay = 150
        dlight.size = 100 + fuseProgress * 80
        dlight.dietime = CurTime() + 0.05
    end
end