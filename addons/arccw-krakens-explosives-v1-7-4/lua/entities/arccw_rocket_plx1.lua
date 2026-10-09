AddCSLuaFile()

ENT.Base = "arccw_rocket_base"
ENT.PrintName = "PLX-1 Rocket"
ENT.Spawnable = false
ENT.Model = "models/items/ar2_grenade.mdl"
DEFINE_BASECLASS("arccw_rocket_base")

ENT.IsRocket = true
ENT.InstantFuse = false
ENT.RemoteFuse = false
ENT.ImpactFuse = true
ENT.ExplodeOnDamage = true
ENT.ExplodeUnderwater = true
ENT.Delay = 0
ENT.SafetyFuse = 0.02
ENT.Radius = 650
ENT.StandardExplosionRadius = 650
ENT.SeekerAngle = math.cos(math.rad(55))
ENT.SteerSpeed = 5000
ENT.FuseTime = 0
ENT.Boost = 2200
ENT.Lift = 0
ENT.DragCoefficient = 0.05
ENT.LifeTime = 20
ENT.GravityScale = 0
ENT.FireAndForget = true
ENT.TopAttack = true
ENT.TopAttackHeight = 5000
ENT.SuperSeeker = false
ENT.SuperSteerTime = 0
ENT.SuperSteerBoostTime = 100
ENT.NoReacquire = true
ENT.ShootEntData = {}
ENT.IsProjectile = true
ENT.LockOnPoint = nil
ENT.StandardExplosionEffect = "cod2019_grenade_explosion"
ENT.StandardExplosionSound = "ArcCW_Kraken.Explosives.HeavyRocketImpact"
ENT.StandardExplosionSound_Dist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_Dist"
ENT.StandardExplosionSound_FarDist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_FarDist"

function ENT:OnInitialize()
    BaseClass.OnInitialize(self)
    
    local weapon = self:GetWeapon()
    if IsValid(weapon) and weapon.RunHook then
        local data = weapon:RunHook("Hook_GetShootEntData", {})
        if data and IsValid(data.Target) then
            self.ShootEntData = data
        end
    end

    if self.ShootEntData and self.ShootEntData.TopAttack ~= nil then
        self.TopAttack = self.ShootEntData.TopAttack
    end
    
    if not self.ShootEntData or not IsValid(self.ShootEntData.Target) then
        local tr = util.TraceLine({
            start = self:GetPos(),
            endpos = self:GetPos() + self:GetForward() * 100000,
            filter = {self, self:GetOwner()},
            mask = MASK_SHOT
        })
        self.LockOnPoint = tr.HitPos
    end
    
    self:EmitSound("kraken/explosives/heat_burn.wav", 75, 100, 1, CHAN_AUTO)
    
    local owner = self:GetOwner()
    if IsValid(owner) then
        self.LastAimPos = owner:GetEyeTrace().HitPos
    end
end

function ENT:Impact(data, collider)
    util.Decal("Scorch", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
end

function ENT:OnThink()
    if not SERVER then return end
    
    if self.FireAndForget then
        local tpos = self.LockOnPoint
        
        if self.ShootEntData and self.ShootEntData.Target and IsValid(self.ShootEntData.Target) then
            local target = self.ShootEntData.Target
            if target.UnTrackable then
                self.ShootEntData.Target = nil
            else
                tpos = target:EyePos()
            end
        end
        
        if not tpos then
            self:GetPhysicsObject():AddVelocity(self:GetForward() * self.Boost)
            return
        end
        
        if self.TopAttack and not self.TopAttackReached then
            tpos = tpos + Vector(0, 0, self.TopAttackHeight)
            local dist = (tpos - self:GetPos()):Length()
            if dist <= 3000 then
                self.TopAttackReached = true
                self.SuperSteerTime = CurTime() + self.SuperSteerBoostTime
            end
        end
        
        local dir = (tpos - self:GetPos()):GetNormalized()
        local dot = dir:Dot(self:GetAngles():Forward())
        local ang = dir:Angle()
        
        if self.SuperSeeker or dot >= self.SeekerAngle or not self.TopAttackReached or (self.SuperSteerTime and self.SuperSteerTime >= CurTime()) then
            local p = self:GetAngles().p
            local y = self:GetAngles().y
            p = math.ApproachAngle(p, ang.p, FrameTime() * self.SteerSpeed)
            y = math.ApproachAngle(y, ang.y, FrameTime() * self.SteerSpeed)
            self:SetAngles(Angle(p, y, 0))
        elseif self.NoReacquire then
            self.ShootEntData.Target = nil
        end
    end
    
    self:GetPhysicsObject():AddVelocity(Vector(0, 0, self.Lift) + self:GetForward() * self.Boost)
end
function ENT:Detonate()
    if not SERVER then return end
    local attacker = self:GetExplosionAttacker()
    local pos = self:GetPos()
    local dir = self:GetVelocity():GetNormalized()
    local src = pos - dir * 64

    ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, self.Radius, 550)
    ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, 400, 120)

    self:FireBullets({Attacker = attacker, Damage = 900, Tracer = 0, Src = src, Dir = dir, HullSize = 16, Distance = 256, IgnoreEntity = self, Callback = function(atk, btr, dmginfo)
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

    self.Defused = true
    SafeRemoveEntityDelayed(self, self.SmokeTrailTime or 0)
end
