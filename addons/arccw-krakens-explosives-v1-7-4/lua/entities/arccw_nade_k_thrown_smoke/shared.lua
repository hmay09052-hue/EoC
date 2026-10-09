AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Smoke Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.BounceSound = "ArcCW_Kraken.Explosives.Bounce"
ENT.ExplodeSound = "kraken/explosives/smoke/start" .. math.random(1, 5) .. ".wav"
ENT.WithinSmoke = {}
DEFINE_BASECLASS("arccw_kraken_nade_base")

local glowMat = Material("sprites/light_glow02_add")
local smokeMat = Material("particle/particle_smokegrenade")

function ENT:DrawTranslucent()
    self:Draw()
end

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos()
    local isActive = self:GetNWBool("IsDetonated", false)
    
    if isActive then
        local pulse = 0.5 + math.sin(CurTime() * 3) * 0.5
        local glowSize = 30 * pulse
        
        render.SetMaterial(smokeMat)
        render.DrawSprite(pos, glowSize * 2, glowSize * 2, Color(200, 200, 200, 80 * pulse))
    else
        local pulse = 0.8 + math.sin(CurTime() * 8) * 0.2
        local glowSize = 10 * pulse
        
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, glowSize, glowSize, Color(180, 180, 180, 150 * pulse))
        
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 180
            dlight.g = 180
            dlight.b = 180
            dlight.brightness = 1 * pulse
            dlight.decay = 1000
            dlight.size = 60
            dlight.dietime = CurTime() + 0.1
        end
    end
end
function ENT:Initialize()
    if not SERVER then return end
    BaseClass.Initialize(self)
    self:SetModel("models/arccw/kraken/sw/explosives/world/w_grenade_smoke.mdl")
    self:DrawShadow(false)
    self.Delay = CurTime() + 3
    self.NextParticle = 0
    self.ParticleCount = 0
    self.First = true
    self.IsDetonated = false
    util.SpriteTrail(self, 0, Color(180, 180, 180, 100), false, 8, 1, 0.3, 1 / 8, "particle/particle_smokegrenade")
end
function ENT:PhysicsCollide(data, physobj)
    if not SERVER or self.Defused then return end
    self.HitP = data.HitPos
    self.HitN = data.HitNormal
    if self:GetVelocity():Length() > 60 then self:EmitSound(self.BounceSound) end
    if self:GetVelocity():Length() < 5 then
        timer.Simple(0, function() if IsValid(self) then self:SetMoveType(MOVETYPE_NONE) end end)
    end
    local tgt = data.HitEntity
    if IsValid(tgt) and not tgt:IsWorld() and (self.NextHit or 0) < CurTime() then
        self.NextHit = CurTime() + 0.1
        local dmginfo = DamageInfo()
        dmginfo:SetDamageType(DMG_GENERIC)
        dmginfo:SetDamage(2)
        dmginfo:SetAttacker(self:GetOwner())
        dmginfo:SetInflictor(self)
        dmginfo:SetDamageForce(data.OurOldVelocity * 0.5)
        tgt:TakeDamageInfo(dmginfo)
    end
    for _, v in ipairs(ents.FindInSphere(self:GetPos(), 155)) do
        if (v:GetClass() == "arccw_fire_spawned1" or v:GetClass() == "arccw_fire_spawned2") and not self.IsDetonated then
            self:Detonate(self, self:GetPos())
            self.IsDetonated = true
        end
    end
end
function ENT:Think()
    if not SERVER then return end
    ArcCW_Kraken_GrenadeEntitySweep(self)
    if not self.IsDetonated and CurTime() > self.Delay then
        self:Detonate(self, self:GetPos())
        self.IsDetonated = true
    end
    if self.IsDetonated then
        for ent, _ in pairs(self.WithinSmoke or {}) do
            if IsValid(ent) and ent:GetPos():DistToSqr(self:GetPos()) >= 155 * 155 then
                self.WithinSmoke[ent] = nil
                if ent:IsPlayer() then ent:RemoveFlags(FL_NOTARGET)
                else ent:SetCurrentWeaponProficiency(ent.OldProfiecency or WEAPON_PROFICIENCY_AVERAGE) end
            end
        end
        for _, v in ipairs(ents.FindInSphere(self:GetPos(), 155)) do
            if (v:GetClass() == "arccw_fire_spawned1" or v:GetClass() == "arccw_fire_spawned2") and IsValid(v) then
                v:SetNWBool("extinguished", true)
                ParticleEffect("extinguish_fire", self:GetPos(), self:GetAngles())
            end
            if not self.WithinSmoke[v] then
                if v:IsPlayer() then self.WithinSmoke[v] = true v:SetNoTarget(true)
                elseif v:IsNPC() or v:IsNextBot() then
                    v:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_POOR)
                    v.OldProfiecency = v:GetCurrentWeaponProficiency()
                end
            end
        end
        self:NextThink(CurTime() + 0.5)
        return true
    end
end
function ENT:Detonate(self, pos)
    self.ParticleCreated = false
    self.ExtinguishParticleCreated = false
    if SERVER then
        if not self:IsValid() then return end
        self:SetNWBool("IsDetonated", true)
        self:EmitSound(self.ExplodeSound)
    end
    if self.ParticleCreated ~= true then
        ParticleEffectAttach("explosion_child_smoke03e", PATTACH_ABSORIGIN_FOLLOW, self, 0)
        ParticleEffectAttach("explosion_child_core06b", PATTACH_POINT_FOLLOW, self, 0)
        ParticleEffectAttach("explosion_child_smoke07b", PATTACH_ABSORIGIN_FOLLOW, self, 0)
        ParticleEffectAttach("explosion_child_smoke07c", PATTACH_POINT_FOLLOW, self, 0)
        ParticleEffectAttach("explosion_child_distort01c", PATTACH_POINT_FOLLOW, self, 0)
        self.ParticleCreated = true
    end
    for k, v in pairs(ents.FindInSphere(self:GetPos(), 155)) do
        if (v:GetClass() == "arccw_fire_spawned1" or v:GetClass() == "arccw_fire_spawned2") and v:IsValid() then
            v:SetNWBool("extinguished", true)
            if not self.ExtinguishParticleCreated then
                ParticleEffect("extinguish_fire", self:GetPos(), self:GetAngles())
                self.ExtinguishParticleCreated = true
            end
        end
    end
    self:SetMoveType(MOVETYPE_NONE)
    if SERVER then
        SafeRemoveEntityDelayed(self, 15)
    end
end
function ENT:OnRemove()
    for ent, _ in pairs(self.WithinSmoke or {}) do
        if IsValid(ent) then
            if ent:IsPlayer() then
                ent:RemoveFlags(FL_NOTARGET)
            else
                ent:SetCurrentWeaponProficiency(ent.OldProfiecency or WEAPON_PROFICIENCY_AVERAGE)
            end
        end
    end
end