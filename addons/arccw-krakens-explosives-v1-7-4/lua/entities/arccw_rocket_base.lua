AddCSLuaFile()

ENT.Base = "arccw_kraken_proj_base"
DEFINE_BASECLASS("arccw_kraken_proj_base")
ENT.PrintName = "ARC9 Rocket Base"
ENT.Spawnable = false

ENT.IsRocket = true
ENT.AudioLoop = "kraken/explosives/heat_burn.wav"

-- DOI-style trail: SpriteTrail smoke + base flare + dynamic light
ENT.RocketTrail = false
ENT.SmokeTrail = false
ENT.SmokeTrailTime = 1
ENT.Flare = true
ENT.FlareColor = Color(255, 200, 100)
ENT.FlareSizeMin = 80
ENT.FlareSizeMax = 120

ENT.SpriteTrailEnabled = true
ENT.SpriteTrailColor = Color(200, 200, 200)
ENT.SpriteTrailLength = 1
ENT.SpriteTrailWidth = 6
ENT.SpriteTrailEndWidth = 0
ENT.SpriteTrailTexture = "effects/fas_smoke_beam"

ENT.DynamicLightEnabled = true
ENT.DynamicLightColor = Color(255, 150, 50)
ENT.DynamicLightBrightness = 2
ENT.DynamicLightSize = 150
ENT.DynamicLightPulse = true
ENT.DynamicLightPulseSpeed = 8

ENT.InitialSpeed = 0

ENT.StandardExplosionRadius = 500
ENT.StandardExplosionDamage = 200
ENT.StandardExplosionEffect = "cod2019_grenade_explosion"
ENT.StandardExplosionSound = "ArcCW_Kraken.Explosives.RocketImpact"
ENT.StandardExplosionSound_Dist = "ArcCW_Kraken.Explosives.RocketImpact_Dist"
ENT.StandardExplosionSound_FarDist = "ArcCW_Kraken.Explosives.RocketImpact_FarDist"

ENT.TailLightSprite = "sprites/glow04_noz.vmt"
ENT.TailLightScale = 0.5
ENT.TailLightColor = Color(255, 150, 50)

ENT.GravityScale = 0

function ENT:OnInitialize()
    if BaseClass.OnInitialize then
        BaseClass.OnInitialize(self)
    end
    self:ApplyGravityScale()
    self:ApplyInitialVelocity()
    self:SetupTailLight()
end

function ENT:OnRemove()
    if SERVER then
        if IsValid(self.TailLightEnt) then
            self.TailLightEnt:Remove()
        end
        self:StopMotorLoop()
    end

    if BaseClass.OnRemove then
        BaseClass.OnRemove(self)
    end
end

function ENT:StopMotorLoop()
    if self.LoopSound then
        self.LoopSound:Stop()
        self.LoopSound = nil
    end
end

function ENT:ApplyGravityScale()
    if CLIENT then return end
    local phys = self:GetPhysicsObject()
    if not IsValid(phys) then return end

    local grav = tonumber(self.GravityScale or 0) or 0

    if grav <= 0 then
        phys:EnableGravity(false)
        if self.SetGravity then
            self:SetGravity(0)
        end
        return
    end

    phys:EnableGravity(true)
    if self.SetGravity then
        self:SetGravity(grav)
    end
end

function ENT:ApplyInitialVelocity()
    if CLIENT then return end
    if not self.InitialSpeed or self.InitialSpeed <= 0 then return end

    local phys = self:GetPhysicsObject()
    if not IsValid(phys) then return end
    phys:SetVelocityInstantaneous(self:GetForward() * self.InitialSpeed)
end

function ENT:SetupTailLight()
    if CLIENT then return end
    if not self.TailLightColor or self.TailLightColor == false then return end

    local light = ents.Create("env_sprite")
    if not IsValid(light) then return end

    light:SetKeyValue("model", self.TailLightSprite or "sprites/glow04_noz.vmt")
    local c = self.TailLightColor
    light:SetKeyValue("rendercolor", string.format("%d %d %d", c.r or 255, c.g or 255, c.b or 255))
    light:SetKeyValue("scale", tostring(self.TailLightScale or 0.4))
    light:SetPos(self:GetPos())
    light:SetParent(self)
    light:Spawn()
    light:Activate()

    self.TailLightEnt = light
end

function ENT:GetExplosionPosition()
    return self:GetPos()
end

function ENT:GetExplosionAttacker()
    if IsValid(self:GetOwner()) then return self:GetOwner() end
    if IsValid(self.Attacker) then return self.Attacker end
    return self
end

function ENT:DoStandardBlastDamage(attacker, pos, radius, damage)
    if CLIENT then return end
    attacker = attacker or self:GetExplosionAttacker()
    pos = pos or self:GetExplosionPosition()
    radius = radius or self.StandardExplosionRadius
    damage = damage or self.StandardExplosionDamage

    if not radius or not damage or radius <= 0 or damage <= 0 then return end

    local falloffStart = radius * 0.15
    local radiusSqr = radius * radius
    local falloffStartSqr = falloffStart * falloffStart
    local falloffRangeSqr = radiusSqr - falloffStartSqr

    for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
        if not IsValid(ent) or ent == self then continue end
        local targetPos = ent:WorldSpaceCenter()
        local tr = util.TraceLine({
            start = pos,
            endpos = targetPos,
            filter = {self, ent},
            mask = MASK_SOLID_BRUSHONLY,
        })
        if tr.Hit and tr.Fraction < 0.98 then continue end

        local distSqr = ent:GetPos():DistToSqr(pos)
        local f = 1
        if distSqr > falloffStartSqr and falloffRangeSqr > 0 then
            f = math.max(1 - (distSqr - falloffStartSqr) / falloffRangeSqr * 0.75, 0.15)
        end

        local dmg = DamageInfo()
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetAttacker(attacker)
        dmg:SetDamage(damage * f)
        dmg:SetDamageForce((targetPos - pos):GetNormalized() * damage * 5 * f)
        dmg:SetDamagePosition(pos)
        dmg:SetInflictor(self)
        ent:TakeDamageInfo(dmg)
    end
end

function ENT:PlayStandardExplosionFX(pos, effect)
    if CLIENT then return end
    self:StopMotorLoop()
    pos = pos or self:GetExplosionPosition()

    if self:WaterLevel() > 0 then
        ArcCW_Kraken_WaterExplosionFX(pos)
        self:EmitSound("weapons/underwater_explode3.wav", 100, 100, 1, CHAN_AUTO)
        sound.Play("weapons/underwater_explode3.wav", pos, 130, math.random(95, 105), 1)
    else
        ArcCW_Kraken_HeavyExplosionFX(pos, self.LastHitNormal)

        util.ScreenShake(pos, 25, 4, 1, self.StandardExplosionRadius or 350)

        -- DOI-style triple-layer: near (125dB) + dist (150dB) + far_dist (175dB)
        self:EmitSound(self.StandardExplosionSound or "ArcCW_Kraken.Explosives.RocketImpact")
        self:EmitSound(self.StandardExplosionSound_Dist or "ArcCW_Kraken.Explosives.RocketImpact_Dist")
        self:EmitSound(self.StandardExplosionSound_FarDist or "ArcCW_Kraken.Explosives.RocketImpact_FarDist")
    end
    
    util.Decal("Scorch", pos, pos - Vector(0, 0, 64))
end

function ENT:DoStandardExplosion(opts)
    opts = opts or {}
    local pos = opts.pos or self:GetExplosionPosition()
    local attacker = opts.attacker or self:GetExplosionAttacker()
    local radius = opts.radius or self.StandardExplosionRadius
    local damage = opts.damage or self.StandardExplosionDamage
    local effect = opts.effect

    self:StopMotorLoop()
    if damage and radius then
        self:DoStandardBlastDamage(attacker, pos, radius, damage)
    end
    self:PlayStandardExplosionFX(pos, effect)
end
