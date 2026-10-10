AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_rocket_base"
ENT.PrintName = "APCR Rocket"
ENT.Model = "models/arccw/kraken/sw/explosives/world/hh12_missile.mdl"
DEFINE_BASECLASS("arccw_rocket_base")

ENT.GravityScale = 0
ENT.LifeTime = 15
ENT.StandardExplosionRadius = 350
ENT.StandardExplosionDamage = 150
ENT.StandardExplosionEffect = "cod2019_grenade_explosion"
ENT.StandardExplosionSound = "ArcCW_Kraken.Explosives.RocketImpact"
ENT.StandardExplosionSound_Dist = "ArcCW_Kraken.Explosives.RocketImpact_Dist"
ENT.StandardExplosionSound_FarDist = "ArcCW_Kraken.Explosives.RocketImpact_FarDist"
ENT.Scorch = true
ENT.DragCoefficient = 0.05
ENT.Boost = 16000

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

    -- APCR: High penetration damage in a narrow cone
    self:FireBullets({Attacker = attacker, Damage = 800, Tracer = 0, Src = pos, Dir = self:GetForward(), HullSize = 8, Distance = 256, IgnoreEntity = self, Callback = function(atk, btr, dmginfo)
        dmginfo:SetDamageType(DMG_AIRBOAT + DMG_SNIPER + DMG_BLAST)
        if IsValid(btr.Entity) and btr.Entity.LVS then
            dmginfo:ScaleDamage(6)
            dmginfo:SetDamageForce(self:GetForward() * 25000)
        end
    end})

    for _, e in ipairs(ents.FindInSphere(pos, 32)) do
        if e:GetClass() == "npc_strider" then e:Fire("Explode") end
    end

    self.Defused = true
    SafeRemoveEntityDelayed(self, self.SmokeTrailTime or 0)
    self:SetRenderMode(RENDERMODE_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    timer.Simple(0, function() if IsValid(self) then self:SetCollisionGroup(COLLISION_GROUP_DEBRIS) end end)
end