AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_rocket_base"
ENT.PrintName = "EMP PLX-1 Rocket"
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
ENT.LockOnPoint = nil
ENT.ShootEntData = {}
ENT.StandardExplosionEffect = "cod2019_grenade_explosion"
ENT.StandardExplosionSound = "ArcCW_Kraken.Explosives.HeavyRocketImpact"
ENT.StandardExplosionSound_Dist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_Dist"
ENT.StandardExplosionSound_FarDist = "ArcCW_Kraken.Explosives.HeavyRocketImpact_FarDist"
ENT.StandardExplosionRadius = 650

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

    if not IsValid(data.HitEntity) then return end

    local affected = {}
    local function AddIfValid(ent)
        if IsValid(ent) and not table.HasValue(affected, ent) then
            table.insert(affected, ent)
        end
    end

    AddIfValid(data.HitEntity)

    for _, child in ipairs(data.HitEntity:GetChildren()) do
        AddIfValid(child)
    end

    local constrained = constraint.GetAllConstrainedEntities(data.HitEntity)
    if constrained then
        for ent, _ in pairs(constrained) do
            AddIfValid(ent)
        end
    end

local function IsControlModule(ent)
    if not IsValid(ent) then return false end

    if ent.GetDriver and IsValid(ent:GetDriver()) then
        return true
    end

    if ent.GetPassenger then
        for i = 0, 10 do
            local p = ent:GetPassenger(i)
            if IsValid(p) then return true end
        end
    end

    if ent:IsVehicle() then return true end
    if ent:GetClass():lower():find("cockpit") then return true end

    return false
end

local mainModule = nil
for _, ent in ipairs(affected) do
    if IsControlModule(ent) then
        mainModule = ent
        break
    end
end

mainModule = mainModule or data.HitEntity

    for _, ent in ipairs(affected) do
        if ent == mainModule then
            self:ApplyPEMEffect(ent)
        else
            self:ApplyPEMEffect(ent, true)
        end
    end
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
    local dir = self:GetVelocity():GetNormalized()
    local src = self:GetPos() - dir * 64

    ArcCW_Kraken_LOSBlastDamage(self, attacker, self:GetPos(), self.Radius, 550)
    ArcCW_Kraken_LOSBlastDamage(self, attacker, self:GetPos(), 400, 120)

    self:PlayStandardExplosionFX(self:GetPos())

    for _, e in pairs(ents.FindInSphere(self:GetPos(), 32)) do
        if e:GetClass() == "npc_strider" then
            e:Fire("Explode")
        end
    end

    self.Defused = true
    SafeRemoveEntityDelayed(self, self.SmokeTrailTime or 0)
end

function ENT:ApplyPEMEffect(ent, noFX)
    if not IsValid(ent) then return end

    local duration = 30
    local entIndex = ent:EntIndex()
    ent.PEMDisabledUntil = CurTime() + duration

    local isLVS = ent.LVS or (ent:GetClass():lower():find("lvs") ~= nil)
    local wasEngineOn = false

    if ent.IsSimfphyscar and ent:EngineActive() then
        wasEngineOn = true
        ent:StopEngine()
    elseif ent.LFS and ent.GetEngineActive and ent:GetEngineActive() then
        wasEngineOn = true
        ent:SetEngineActive(false)
    elseif isLVS and ent.SetEngineActive and ent.GetEngineActive and ent:GetEngineActive() then
        wasEngineOn = true
        ent:SetEngineActive(false)
    end

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        ent._PEM_WasFrozen = true
    end

    ent._PEM_RestorePhysics = function()
        if IsValid(ent) then
            local restore_phys = ent:GetPhysicsObject()
            if IsValid(restore_phys) then
                restore_phys:EnableMotion(true)
            end
        end
        ent._PEM_RestorePhysics = nil
    end

    if isLVS then
        ent._PEM_OriginalThrottle = ent._PEM_OriginalThrottle or ent.SetThrottle
        ent.SetThrottle = function() end

        ent._PEM_OriginalSteer = ent._PEM_OriginalSteer or ent.SetSteer
        ent.SetSteer = function() end

        if ent.StartEngine then
            ent._PEM_OriginalStartEngine = ent._PEM_OriginalStartEngine or ent.StartEngine
            ent.StartEngine = function() end
        end

        if ent.CalcEngineForce then
            ent._PEM_OriginalCalcForce = ent._PEM_OriginalCalcForce or ent.CalcEngineForce
            ent.CalcEngineForce = function() return Vector(0, 0, 0) end
        end

        if ent:GetClass():lower():find("walker") then
            ent._PEM_OriginalThink = ent._PEM_OriginalThink or ent.Think
            ent.Think = function() return end

            ent._PEM_OriginalHandleControls = ent._PEM_OriginalHandleControls or ent.HandleControls
            ent.HandleControls = function() return end

            ent._PEM_OriginalAnimThink = ent._PEM_OriginalAnimThink or ent.AnimThink
            ent.AnimThink = function() return end
        end
    end

    if not noFX then
        local fx = EffectData()
        fx:SetOrigin(ent:GetPos() + Vector(0, 0, 40))
        fx:SetEntity(ent)
        fx:SetAttachment(0)
        util.Effect("electricity_raycast", fx, true, true)

        local fx2 = EffectData()
        fx2:SetOrigin(ent:GetPos() + Vector(0, 0, 40))
        fx2:SetEntity(ent)
        util.Effect("electric_explosion", fx2, true, true)

        local function LoopPEMSparks()
            if not IsValid(ent) or CurTime() > (ent.PEMDisabledUntil or 0) then return end
            local spark = EffectData()
            spark:SetOrigin(ent:GetPos() + VectorRand() * 64 + Vector(0, 0, 32))
            util.Effect("StunstickImpact", spark, true, true)
            timer.Simple(0.3, LoopPEMSparks)
        end

        local function CreateEMPArcs()
            if not IsValid(ent) or CurTime() > (ent.PEMDisabledUntil or 0) then return end
            for i = 1, 3 do
                local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                local pos = Vector(
                    math.Rand(mins.x, maxs.x),
                    math.Rand(mins.y, maxs.y),
                    math.Rand(mins.z, maxs.z)
                )
                local world = ent:LocalToWorld(pos)
                local ed = EffectData()
                ed:SetOrigin(world)
                util.Effect("ManhackSparks", ed, true, true)
            end
            timer.Simple(0.25, CreateEMPArcs)
        end

        local snd = "ambient/energy/electric_loop.wav"
        local channel = CHAN_STATIC + (entIndex % 128)
        ent:StopSound(snd)
        ent:EmitSound(snd, 75, 100, 0.6, channel)

        LoopPEMSparks()
        CreateEMPArcs()

        hook.Add("EntityRemoved", "StopPEMSound_" .. entIndex, function(removed)
            if removed == ent then
                ent:StopSound(snd)
                hook.Remove("EntityRemoved", "StopPEMSound_" .. entIndex)
            end
        end)
    end

    timer.Simple(duration, function()
        if not IsValid(ent) then return end
        if ent._PEM_RestorePhysics then ent:_PEM_RestorePhysics() end
        ent:StopSound("ambient/energy/electric_loop.wav")

        if ent._PEM_OriginalThink then ent.Think = ent._PEM_OriginalThink ent._PEM_OriginalThink = nil end
        if ent._PEM_OriginalHandleControls then ent.HandleControls = ent._PEM_OriginalHandleControls ent._PEM_OriginalHandleControls = nil end
        if ent._PEM_OriginalAnimThink then ent.AnimThink = ent._PEM_OriginalAnimThink ent._PEM_OriginalAnimThink = nil end
        if ent._PEM_OriginalThrottle then ent.SetThrottle = ent._PEM_OriginalThrottle ent._PEM_OriginalThrottle = nil end
        if ent._PEM_OriginalSteer then ent.SetSteer = ent._PEM_OriginalSteer ent._PEM_OriginalSteer = nil end
        if ent._PEM_OriginalStartEngine then ent.StartEngine = ent._PEM_OriginalStartEngine ent._PEM_OriginalStartEngine = nil end
        if ent._PEM_OriginalCalcForce then ent.CalcEngineForce = ent._PEM_OriginalCalcForce ent._PEM_OriginalCalcForce = nil end

        if wasEngineOn and ent.SetEngineActive then
            ent:SetEngineActive(true)
        end
    end)
end
