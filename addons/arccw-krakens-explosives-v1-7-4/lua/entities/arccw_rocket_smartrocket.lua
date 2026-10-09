AddCSLuaFile()

ENT.Base = "arccw_rocket_base"
ENT.PrintName = "Smart Rocket (Guided)"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Model = "models/arccw/kraken/sw/explosives/world/hh12_missile.mdl"

ENT.IsRocket = true
ENT.ExplodeOnImpact = true
ENT.ExplodeUnderwater = true
ENT.FuseTime = 0
ENT.StandardExplosionRadius = 600
ENT.StandardExplosionEffect = "cod2019_grenade_explosion"
ENT.StandardExplosionSound = "ArcCW_Kraken.Explosives.HeavyRocketImpact"
ENT.StandardExplosionSound_Dist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_Dist"
ENT.StandardExplosionSound_FarDist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_FarDist"

-- SACLOS guidance: rocket follows owner's crosshair (Strela-like)
-- Switches to fire-and-forget if the weapon passes a locked target
ENT.SACLOS = true
ENT.FireAndForget = false
ENT.SeekerAngle = math.cos(math.rad(60))
ENT.SteerSpeed = 7000
ENT.NoReacquire = true
ENT.Boost = 2500
ENT.Lift = 0
ENT.GravityScale = 0
ENT.LifeTime = 15
ENT.ShootEntData = {}
ENT.IsProjectile = true

function ENT:OnInitialize()
    if self.BaseClass and self.BaseClass.OnInitialize then
        self.BaseClass.OnInitialize(self)
    end
    self:EmitSound("kraken/explosives/heat_burn.wav", 75, 100, 1, CHAN_AUTO)
end

-- Called each tick by the base Think(). If the weapon passed a locked target
-- via Hook_PostFireRocket, switch from SACLOS to fire-and-forget homing.
function ENT:OnThink()
    if self.SACLOS and self.ShootEntData and IsValid(self.ShootEntData.Target) then
        self.SACLOS = false
        self.FireAndForget = true
    end
end

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

function ENT:Detonate(impact)
    impact = impact or {}
    if not self:IsValid() or self.Defused then return end
    self.Defused = true

    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self
    local pos = self:GetPos()
    local dir = (self.HitVelocity or self:GetVelocity() or vector_origin):GetNormalized()
    local src = pos - dir * 64

    ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, self.StandardExplosionRadius, 500)
    ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, 350, 120)

    self:FireBullets({Attacker = attacker, Damage = 750, Tracer = 0, Src = src, Dir = dir, HullSize = 16, Distance = 256, IgnoreEntity = self, Callback = function(atk, btr, dmginfo)
        if IsValid(btr.Entity) and btr.Entity.LVS then
            dmginfo:ScaleDamage(5)
            dmginfo:SetDamageType(DMG_AIRBOAT + DMG_SNIPER + DMG_BLAST)
            dmginfo:SetDamageForce(self:GetForward() * 100000)
        end
    end})

    self:PlayStandardExplosionFX(pos)

    for _, e in ipairs(ents.FindInSphere(pos, 32)) do
        if e:GetClass() == "npc_strider" then e:Fire("Explode") end
    end

    timer.Simple(0, function()
        if not IsValid(self) then return end
        SafeRemoveEntityDelayed(self, self.SmokeTrailTime or 0)
        self:SetRenderMode(RENDERMODE_NONE)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    end)
end

if CLIENT then
    killicon.Add("arccw_rocket_smartrocket", "HUD/killicons/default", Color(255, 255, 255, 255))
end
