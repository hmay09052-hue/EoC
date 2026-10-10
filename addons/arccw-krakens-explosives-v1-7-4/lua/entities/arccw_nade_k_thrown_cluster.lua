AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Cluster Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_impact.mdl"
ENT.FuseTime = 3.5

DEFINE_BASECLASS("arccw_kraken_nade_base")

ENT.Radius = 320
ENT.Damage = 700
ENT.ImpactDamage = 2
ENT.DamageFalloffStart = 64
ENT.FragmentCount = 8
ENT.FragmentSpreadRadius = 350

local glowMat = Material("sprites/light_glow02_add")
local warningMat = Material("sprites/orangeflare1")

function ENT:Initialize()
    if SERVER then
        BaseClass.Initialize(self)
        self:SetModel(self.Model)
        self:SetSkin(self.Skin or 0)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:SetBuoyancyRatio(0) end
        self:SetPhysicsAttacker(self:GetOwner(), 5)
        util.SpriteTrail(self, 0, Color(255, 150, 50, 180), false, 12, 3, 0.4, 1 / 12, "sprites/orangeflare1")
        self.SpawnTime = CurTime()
        self.LastBeepTime = 0
        self.BeepInterval = 0.8
    end
    
    self:EmitSound("kraken/explosives/impact/beep.wav", 75, 90, 0.8, CHAN_AUTO)
end

function ENT:PhysicsCollide(data, physobj)
    if CLIENT or self.Defused then return end
    if IsValid(data.HitEntity) and not data.HitEntity:IsWorld() then
        local dmg = DamageInfo()
        dmg:SetDamageType(DMG_GENERIC)
        dmg:SetDamage(self.ImpactDamage)
        dmg:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
        dmg:SetInflictor(self)
        dmg:SetDamageForce(data.OurOldVelocity * 0.5)
        data.HitEntity:TakeDamageInfo(dmg)
    end
    if data.Speed > 50 then
        self:EmitSound("physics/metal/metal_grenade_impact_hard" .. math.random(1, 3) .. ".wav", 70, math.random(95, 105), 0.6)
    end
end

function ENT:Think()
    if CLIENT or self.Defused then return end
    ArcCW_Kraken_GrenadeEntitySweep(self)
    local timeAlive = CurTime() - (self.SpawnTime or CurTime())
    local timeRemaining = self.FuseTime - timeAlive
    if timeRemaining > 0 then
        local beepInterval = math.max(0.1, timeRemaining / self.FuseTime * 0.8)
        
        if CurTime() - self.LastBeepTime >= beepInterval then
            self.LastBeepTime = CurTime()
            local pitch = math.Clamp(100 + (1 - timeRemaining / self.FuseTime) * 40, 100, 140)
            self:EmitSound("kraken/explosives/impact/beep.wav", 75, pitch, 0.9, CHAN_AUTO)
        end
    end
    if self.SpawnTime and timeAlive >= self.FuseTime then
        self:Detonate()
        return
    end
    
    self:NextThink(CurTime() + 0.05)
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
        self:EmitSound("weapons/underwater_explode3.wav", 110, 100, 1, CHAN_AUTO)
    else
        local explode = ents.Create("info_particle_system")
        if IsValid(explode) then
            explode:SetKeyValue("effect_name", "grenade_final")
            explode:SetOwner(attacker)
            explode:SetPos(pos)
            explode:Spawn()
            explode:Activate()
            explode:Fire("start", "", 0)
            explode:Fire("kill", "", 30)
        end
        self:EmitSound("ArcCW_Kraken.Explosives.Explosion")
    end

    for i = 1, self.FragmentCount do
        local frag = ents.Create("arccw_ent_cluster_fragment")
        if IsValid(frag) then
            local spreadAngle = Angle(math.Rand(-60, -20), math.Rand(0, 360), 0)
            local spreadDir = spreadAngle:Forward()
            
            frag:SetPos(pos + Vector(0, 0, 10) + VectorRand() * 15)
            frag:SetAngles(AngleRand())
            frag:SetOwner(self:GetOwner())
            frag.Attacker = attacker
            frag:Spawn()
            local phys = frag:GetPhysicsObject()
            if IsValid(phys) then
                local launchVel = spreadDir * math.Rand(280, 450) + Vector(0, 0, math.Rand(200, 350))
                phys:SetVelocity(launchVel)
                phys:AddAngleVelocity(VectorRand() * 500)
            end
        end
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
        dmg:SetDamageForce((targetPos - pos):GetNormalized() * 6000 * f)
        dmg:SetInflictor(self)
        ent:TakeDamageInfo(dmg)
    end

    util.Decal("Scorch", pos, pos - Vector(0, 0, 16))
    util.ScreenShake(pos, 20, 5, 0.8, 800)
    self:EmitSound("ArcCW_Kraken.Explosives.Explosion_Distant")
    self:EmitSound("ArcCW_Kraken.Explosives.Explosion_FarDist")
    self:Remove()
end

function ENT:DrawTranslucent() self:Draw() end

local warningMat = Material("sprites/orangeflare1")

function ENT:Draw()
    self:DrawModel()
    if not CLIENT then return end
    
    local pos = self:GetPos()
    local spawnTime = self.SpawnTime or self:GetCreationTime()
    local timeAlive = CurTime() - spawnTime
    local timeRemaining = math.max(0, self.FuseTime - timeAlive)
    local urgency = 1 - (timeRemaining / self.FuseTime)
    
    local pulseSpeed = 8 + urgency * 20
    local pulse = 0.5 + math.sin(CurTime() * pulseSpeed) * 0.5
    local glowSize = (12 + urgency * 8) * pulse
    
    local r = 255
    local g = Lerp(urgency, 150, 50)
    local b = Lerp(urgency, 50, 20)
    
    render.SetMaterial(glowMat)
    render.DrawSprite(pos, glowSize, glowSize, Color(r, g, b, 200 * pulse))
    render.SetMaterial(warningMat)
    render.DrawSprite(pos, glowSize * 0.6, glowSize * 0.6, Color(255, 200, 100, 220 * pulse))
    
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = pos
        dlight.r, dlight.g, dlight.b = r, g, b
        dlight.brightness = (2 + urgency * 2) * pulse
        dlight.decay = 1000
        dlight.size = 80 + urgency * 60
        dlight.dietime = CurTime() + 0.1
    end
end