AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "GRN Navy Transport"
ENT.Spawnable = false

local function safeStopLoop(self)
    if self._loop then
        self._loop:Stop()
        self._loop = nil
    end
end

function ENT:Initialize()
    local cfg = self.TransportData or {}
    self:SetModel(cfg.Model or "models/blu/laat.mdl")
    self:PhysicsInit(cfg.Collision and SOLID_VPHYSICS or SOLID_NONE)
    self:SetMoveType(MOVETYPE_NOCLIP)
    self:SetSolid(cfg.Collision and SOLID_VPHYSICS or SOLID_NONE)
    if cfg.ModelScale then self:SetModelScale(cfg.ModelScale, 0) end
    if cfg.HasHealth then self:SetHealth(cfg.MaxHealth or 3000) end

    self.TargetPos = self.TargetPos or self:GetPos()
    self.ApproachDir = self.ApproachDir or self:GetForward()
    self.ApproachDir.z = 0
    if self.ApproachDir:LengthSqr() <= 0 then self.ApproachDir = Vector(1,0,0) end
    self.ApproachDir:Normalize()

    self.CruiseAltitude = cfg.CruiseAltitude or 2200
    self.Speed = cfg.Speed or 1600
    self.ExitSpeed = cfg.ExitSpeed or self.Speed
    self.LandingHeight = cfg.LandingHeight or 120
    self.GroundTime = cfg.GroundTime or 5
    self.WobbleAmp = cfg.GroundWobbleAmp or 1
    self.WobbleFreq = cfg.GroundWobbleFreq or 2
    self.PayloadClass = cfg.PayloadClass
    self.PayloadAngles = cfg.PayloadAngles or angle_zero
    self.PayloadOffset = cfg.PayloadOffset or vector_origin
    self.TransportAngles = cfg.TransportAngles or angle_zero
    self.PayloadSpawned = false
    self.Departing = false
    self.Landed = false
    self.PathIndex = 1

    self:SetAngles((self.ApproachDir:Angle() + self.TransportAngles))
    self:BuildPath()

    local snd = cfg.Sounds or {}
    self.Sounds = snd
    if snd.Arrival and snd.Arrival ~= "" then self:EmitSound(snd.Arrival, 85, 100) end
    self:NextThink(CurTime())
end

function ENT:BuildPath()
    local landPos = self.TargetPos + Vector(0,0,self.LandingHeight)
    local dir = self.ApproachDir
    local skyOrigin = landPos + Vector(0,0,self.CruiseAltitude)
    local trBack = util.TraceLine({
        start = skyOrigin,
        endpos = skyOrigin - dir * 30000,
        mask = MASK_SOLID_BRUSHONLY,
    })
    local flyStart = trBack.Hit and (trBack.HitPos + dir * 100) or (skyOrigin - dir * 30000)
    local midPoint = LerpVector(0.5, flyStart, skyOrigin) + Vector(0,0,-self.CruiseAltitude * 0.15)
    local approachPoint = landPos + Vector(0,0,self.CruiseAltitude * 0.4) - dir * 1400
    local descentPoint = landPos + Vector(0,0,self.CruiseAltitude * 0.15) - dir * 500

    self.Path = {
        { pos = flyStart, speed = self.Speed },
        { pos = midPoint, speed = self.Speed },
        { pos = approachPoint, speed = self.Speed * 0.72 },
        { pos = descentPoint, speed = self.Speed * 0.55 },
        { pos = landPos, speed = self.Speed * 0.32 },
    }

    self:SetPos(flyStart)
end

function ENT:SwitchLoop(path, level)
    safeStopLoop(self)
    if not path or path == "" then return end
    self._loop = CreateSound(self, path)
    if self._loop then
        self._loop:SetSoundLevel(level or 80)
        self._loop:Play()
    end
end

function ENT:SpawnPayload()
    if self.PayloadSpawned then return end
    self.PayloadSpawned = true
    if not self.PayloadClass or self.PayloadClass == "" then return end

    local basePos = self.TargetPos + self.PayloadOffset
    local ang = (self:GetAngles() + self.PayloadAngles)

    local ent = ents.Create(self.PayloadClass)
    if not IsValid(ent) then return end
    ent:SetPos(basePos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()

    ent.GRN_NavySpawned = true
    ent.GRN_NavyType = "supply"
    ent.GRN_NavyTeam = self.GRN_NavyTeam
    ent.GRN_NavyDefID = self.GRN_NavyDefID
    ent:SetNWString("GRN_NavyTeam", self.GRN_NavyTeam or "")

    local phys = ent.GetPhysicsObject and ent:GetPhysicsObject() or nil
    if IsValid(phys) then phys:Wake() end
end

function ENT:BeginLanding()
    self.Landed = true
    if self.Sounds.Hover and self.Sounds.Hover ~= "" then
        self:SwitchLoop(self.Sounds.Hover, 80)
    end

    timer.Simple(1.0, function()
        if IsValid(self) and not self.Departing then
            self:SpawnPayload()
        end
    end)

    timer.Simple(self.GroundTime, function()
        if IsValid(self) then self:Depart() end
    end)
end

function ENT:Depart()
    if self.Departing then return end
    self.Departing = true
    safeStopLoop(self)
    if self.Sounds.Takeoff and self.Sounds.Takeoff ~= "" then self:EmitSound(self.Sounds.Takeoff, 90, 100) end
    if self.Sounds.Depart and self.Sounds.Depart ~= "" then self:SwitchLoop(self.Sounds.Depart, 85) end

    local pos = self:GetPos()
    local dir = self.ApproachDir
    self.DepartPath = {
        { pos = pos + Vector(0,0,self.CruiseAltitude * 0.25), speed = self.ExitSpeed * 0.55 },
        { pos = pos + dir * 1500 + Vector(0,0,self.CruiseAltitude * 0.6), speed = self.ExitSpeed * 0.8 },
        { pos = pos + dir * 28000 + Vector(0,0,self.CruiseAltitude), speed = self.ExitSpeed },
    }
    self.DepartIndex = 1
end

function ENT:MaintainHover()
    local wave = math.sin(CurTime() * self.WobbleFreq) * self.WobbleAmp
    local ang = self:GetAngles()
    self:SetAngles(LerpAngle(FrameTime() * 2, ang, Angle(wave, ang.y, 0)))
end

function ENT:MoveTowards(target, speed, pitchClampMin, pitchClampMax)
    local pos = self:GetPos()
    local dist = pos:Distance(target)
    if dist <= speed * FrameTime() + 10 then
        self:SetPos(target)
        self:SetAbsVelocity(vector_origin)
        return true
    end
    local vel = (target - pos):GetNormalized() * speed
    self:SetAbsVelocity(vel)
    local toTarget = (target - pos)
    local pitch = -math.deg(math.atan2(toTarget.z, math.max(toTarget:Length2D(), 1)))
    pitch = math.Clamp(pitch, pitchClampMin or -20, pitchClampMax or 10)
    local desired = Angle(pitch, self.ApproachDir:Angle().y + self.TransportAngles.y, self.TransportAngles.r or 0)
    self:SetAngles(LerpAngle(FrameTime() * 2.5, self:GetAngles(), desired))
    return false
end

function ENT:Think()
    if self.Departing and self.DepartPath then
        local wp = self.DepartPath[self.DepartIndex]
        if not wp then self:Remove() return end
        if self:MoveTowards(wp.pos, wp.speed, -5, 20) then
            self.DepartIndex = self.DepartIndex + 1
        end
        self:NextThink(CurTime())
        return true
    end

    if not self.Landed then
        local wp = self.Path and self.Path[self.PathIndex]
        if not wp then
            self:SetPos(self.TargetPos + Vector(0,0,self.LandingHeight))
            self:SetAbsVelocity(vector_origin)
            self:BeginLanding()
            self:NextThink(CurTime())
            return true
        end

        if self.PathIndex <= 3 and self.Sounds.Flight and self.Sounds.Flight ~= "" and not self._loop then
            self:SwitchLoop(self.Sounds.Flight, 90)
        elseif self.PathIndex >= 4 and self.Sounds.Landing and self.Sounds.Landing ~= "" and (not self._landingLoopStarted) then
            self._landingLoopStarted = true
            self:SwitchLoop(self.Sounds.Landing, 82)
        end

        if self:MoveTowards(wp.pos, wp.speed, -20, 10) then
            self.PathIndex = self.PathIndex + 1
        end
    else
        self:MaintainHover()
    end

    self:NextThink(CurTime())
    return true
end

function ENT:OnRemove()
    safeStopLoop(self)
end
