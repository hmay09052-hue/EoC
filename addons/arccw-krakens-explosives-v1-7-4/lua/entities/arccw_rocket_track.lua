AddCSLuaFile()

ENT.Base = "arccw_rocket_base"
ENT.PrintName = "RPS-6 Tracking Rocket"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Model = "models/arccw/kraken/sw/explosives/world/hh12_missile.mdl"
ENT.IsRocket = true
ENT.ExplodeOnImpact = true
ENT.Defused = false
ENT.SphereSize = 1
ENT.PhysMat = "grenade"
ENT.SACLOS = true
ENT.SeekerAngle = math.cos(math.rad(89.5))
ENT.SteerSpeed = 40000
ENT.TurnBoostTime = 1.25
ENT.MaxSpeed = 1500
ENT.Lift = 0
ENT.FuseTime = 0
ENT.LifeTime = 20
ENT.GravityScale = 0
ENT.FailsafeDetonate = 15
ENT.StandardExplosionEffect = "cod2019_grenade_explosion"
ENT.StandardExplosionRadius = 650
ENT.StandardExplosionSound = "ArcCW_Kraken.Explosives.HeavyRocketImpact"
ENT.StandardExplosionSound_Dist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_Dist"
ENT.StandardExplosionSound_FarDist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_FarDist"
ENT.LastHitNormal = Vector(0, 0, 1)
DEFINE_BASECLASS("arccw_rocket_base")
function ENT:OnInitialize()
    BaseClass.OnInitialize(self)
    self.SpawnTime  = CurTime()
    self.KillTime   = self.SpawnTime + self.FailsafeDetonate
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetBuoyancyRatio(0)
        phys:SetVelocityInstantaneous(self:GetForward() * self.MaxSpeed)
    end
    local owner = self:GetOwner()
    if IsValid(owner) then
        self.Launcher = owner:GetActiveWeapon()
    end
    self.LostLock = false
    self:EmitSound("kraken/explosives/heat_burn.wav", 75, 100, 1, CHAN_AUTO)
end
function ENT:PhysicsCollide(colData, physobj)
    if not self:IsValid() then return end
    self.LastHitNormal = colData.HitNormal or self.LastHitNormal
    if not self.ExplodeOnImpact then return end
    timer.Simple(0, function()
        if not IsValid(self) then return end
        self.HitVelocity = colData.OurOldVelocity
        self:Detonate({
            HitPos            = colData.HitPos,
            HitNormal         = colData.HitNormal,
            TheirSurfaceProps = colData.TheirSurfaceProps
        })
    end)
end
function ENT:Impact(data, collider)
    util.Decal("Scorch", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
end
local function LOSPoint(self)
    local owner = self:GetOwner()
    if not IsValid(owner) then
        return self:GetPos() + self:GetForward() * 100000
    end
    local start = owner:EyePos()
    local dir   = owner:EyeAngles():Forward()
    local tr = util.TraceLine({
        start  = start,
        endpos = start + dir * 100000,
        filter = { self, owner },
        mask   = MASK_SHOT
    })
    return tr.HitPos
end
local function angle_error(a, b)
    local dp = math.Clamp(a:Dot(b), -1, 1)
    return math.deg(math.acos(dp))
end
local function IsTrackingAllowed(self)
    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:Alive() then return false end
    local curwep = owner:GetActiveWeapon()
    if not IsValid(curwep) then return false end
    if IsValid(self.Launcher) and curwep ~= self.Launcher then
        self.LostLock = true
    end
    if self.LostLock then return false end
    if not curwep.ARC9 or not curwep.GetSightAmount then return false end
    return curwep:GetSightAmount() >= 0.95
end
function ENT:OnThink()
    if not SERVER or self.Defused then return end
    if CurTime() >= (self.KillTime or 0) then
        if not self.LastHitNormal then
            local v = self:GetVelocity()
            self.LastHitNormal = (v:LengthSqr() > 1) and (-v):GetNormalized() or Vector(0,0,1)
        end
        self:Detonate()
        return
    end
    if self.SACLOS and IsTrackingAllowed(self) then
        local tpos       = LOSPoint(self)
        local desiredDir = (tpos - self:GetPos()):GetNormalized()
        local fwd        = self:GetForward()
        local dot        = math.Clamp(desiredDir:Dot(fwd), -1, 1)
        local errMul = 1.2 + (1 - dot) * 12.0
        if CurTime() - (self.SpawnTime or 0) <= self.TurnBoostTime then
            errMul = errMul * 2.0
        end
        local errDeg = angle_error(desiredDir, fwd)
        local want   = desiredDir:Angle()
        local cur    = self:GetAngles()
        if errDeg > 8 then
            local huge = FrameTime() * self.SteerSpeed * errMul * 4.0
            local p = math.ApproachAngle(cur.p, want.p, huge)
            local y = math.ApproachAngle(cur.y, want.y, huge)
            self:SetAngles(Angle(p, y, 0))
        else
            local step = FrameTime() * self.SteerSpeed * errMul
            local p = math.ApproachAngle(cur.p, want.p, step)
            local y = math.ApproachAngle(cur.y, want.y, step)
            self:SetAngles(Angle(p, y, 0))
        end
    end
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocityInstantaneous(self:GetForward() * self.MaxSpeed + Vector(0, 0, self.Lift or 0))
    end
    self:NextThink(CurTime())
    return true
end
local function SafeHitNormal(self, impact)
    if self.LastHitNormal and isvector(self.LastHitNormal) then
        return self.LastHitNormal
    end
    if impact and impact.HitNormal then
        return impact.HitNormal
    end
    local v = self:GetVelocity()
    if v:LengthSqr() > 1 then
        return (-v):GetNormalized()
    end
    return Vector(0, 0, 1)
end
function ENT:Detonate(impact)
    impact = impact or {}
    if not self:IsValid() or self.Defused then return end
    self.Defused = true

    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self
    local pos = self:GetPos()

    self:PlayStandardExplosionFX(pos)

    if self:WaterLevel() > 0 then
        ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, 350, 350)
    else
        ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, 128, 280)
        ArcCW_Kraken_LOSBlastDamage(self, attacker, pos, 650, 180)
    end

    self:FireBullets({Attacker = attacker, Damage = 0, Tracer = 0, Distance = 256, Dir = self:GetVelocity():GetNormalized(), Src = pos, Callback = function(att, tr, dmg)
        if self.Scorch then util.Decal("Scorch", tr.StartPos, tr.HitPos - (tr.HitNormal * 16), self) end
    end})

    timer.Simple(0, function()
        if not IsValid(self) then return end
        SafeRemoveEntityDelayed(self, self.SmokeTrailTime or 0)
        self:SetRenderMode(RENDERMODE_NONE)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    end)
end