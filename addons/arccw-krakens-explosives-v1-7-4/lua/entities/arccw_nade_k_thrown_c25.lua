AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "C-25 Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_c25.mdl"
ENT.FuseTime = 2
DEFINE_BASECLASS("arccw_kraken_nade_base")

ENT.Radius = 600
ENT.Damage = 750
ENT.ImpactDamage = 2
ENT.DamageFalloffStart = 96

local glowMat = Material("sprites/light_glow02_add")
local chargeMat = Material("sprites/physbeam")

function ENT:Initialize()
    if not SERVER then return end
    BaseClass.Initialize(self)
    self:SetSkin(self.Skin or 0)
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then phys:SetBuoyancyRatio(0) end
    self:SetPhysicsAttacker(self:GetOwner(), 5)
    self:EmitSound("kraken/explosives/thermalimploder/beeps.wav", 90, 100, 1, CHAN_AUTO)
    util.SpriteTrail(self, 0, Color(35, 202, 228, 150), false, 8, 2, 0.3, 1 / 8, "trails/laser")
end

function ENT:PhysicsCollide(data, physobj)
    if not SERVER or self.Defused then return end
    local tgt, speed = data.HitEntity, data.Speed

    if speed < 15 and (not IsValid(tgt) or tgt:IsWorld()) then
        timer.Simple(0, function() if IsValid(self) then self:SetMoveType(MOVETYPE_NONE) end end)
        self:EmitSound("kraken/shared/therm_gren_charge.wav")
        return
    end

    if speed > 25 then self:EmitSound("ArcCW_Kraken.Explosives.Bounce") end

    if speed > 75 and IsValid(tgt) and not tgt:IsWorld() and (self.NextHit or 0) < CurTime() then
        self.NextHit = CurTime() + 0.1
        local dmginfo = DamageInfo()
        dmginfo:SetDamageType(DMG_GENERIC)
        dmginfo:SetDamage(self.ImpactDamage)
        dmginfo:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamageForce(data.OurOldVelocity * 0.5)
        tgt:TakeDamageInfo(dmginfo)
    end
end

function ENT:Think()
    if self.Defused or not SERVER then return end
    ArcCW_Kraken_GrenadeEntitySweep(self)
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
        local effectdata = EffectData()
        effectdata:SetOrigin(pos)
        util.Effect("WaterSurfaceExplosion", effectdata)
        self:EmitSound("weapons/underwater_explode3.wav", 125, 100, 1, CHAN_AUTO)
    else
        local explode = ents.Create("info_particle_system")
        if IsValid(explode) then
            explode:SetKeyValue("effect_name", "vpr_nade_blast")
            explode:SetOwner(attacker)
            explode:SetPos(pos)
            explode:Spawn()
            explode:Activate()
            explode:Fire("start", "", 0)
            explode:Fire("kill", "", 30)
        end
        self:EmitSound("kraken/shared/beeps2.wav", 90, 100, 1, CHAN_AUTO)
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
    end

    util.Decal("Scorch", pos, pos - Vector(0, 0, 30))
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
        
        local pulse = 0.7 + math.sin(CurTime() * (8 + fuseProgress * 12)) * 0.3
        local glowSize = (14 + fuseProgress * 14) * pulse
        
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, glowSize, glowSize, Color(35, 202, 228, 180 * pulse))
        
        if fuseProgress > 0.6 then
            local chargeIntensity = (fuseProgress - 0.6) / 0.4
            render.SetMaterial(chargeMat)
            render.DrawSprite(pos, glowSize * 1.4 * chargeIntensity, glowSize * 1.4 * chargeIntensity, Color(100, 220, 255, 200 * chargeIntensity))
        end
        
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 35
            dlight.g = 202
            dlight.b = 228
            dlight.brightness = 2 + fuseProgress * 2
            dlight.decay = 1000
            dlight.size = 90 + fuseProgress * 50
            dlight.dietime = CurTime() + 0.05
        end
    end
end