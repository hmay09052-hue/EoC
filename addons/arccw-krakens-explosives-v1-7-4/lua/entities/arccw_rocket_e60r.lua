AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_rocket_base"
ENT.PrintName = "E-60R Rocket"
ENT.Model = "models/arccw/kraken/sw/explosives/world/hh12_missile.mdl"
DEFINE_BASECLASS("arccw_rocket_base")

ENT.GravityScale = 0
ENT.LifeTime = 20
ENT.StandardExplosionRadius = 600
ENT.StandardExplosionDamage = 200
ENT.StandardExplosionEffect = "cod2019_grenade_explosion"
ENT.StandardExplosionSound = "ArcCW_Kraken.Explosives.RocketImpact"
ENT.StandardExplosionSound_Dist = "ArcCW_Kraken.Explosives.RocketImpact_Dist"
ENT.StandardExplosionSound_FarDist = "ArcCW_Kraken.Explosives.RocketImpact_FarDist"
ENT.Scorch = true
ENT.DragCoefficient = 0.05
ENT.Boost = 12000

function ENT:PhysicsCollide(colData, collider)
    if self.Detonated then return end
    self.LastHitNormal = colData.HitNormal
    self.HitVelocity = colData.OurOldVelocity
    self:PreDetonate({HitPos = colData.HitPos, HitNormal = colData.HitNormal})
end

function ENT:Detonate(data)
    if not SERVER then return end
    local pos = self:GetPos()
    self:DoStandardExplosion({pos = pos})

    local attacker = self:GetExplosionAttacker()
    self:FireBullets({Attacker = attacker, Damage = 200, Tracer = 0, Src = pos, Dir = self:GetForward(), HullSize = 16, Distance = 128, IgnoreEntity = self, Callback = function(atk, btr, dmginfo)
        if IsValid(btr.Entity) and btr.Entity.LVS then
            dmginfo:ScaleDamage(4)
            dmginfo:SetDamageType(DMG_AIRBOAT + DMG_BLAST)
            dmginfo:SetDamageForce(self:GetForward() * 15000)
        end
    end})

    self.Defused = true
    SafeRemoveEntityDelayed(self, self.SmokeTrailTime or 0)
    self:SetRenderMode(RENDERMODE_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    timer.Simple(0, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_DEBRIS) end end)
end
