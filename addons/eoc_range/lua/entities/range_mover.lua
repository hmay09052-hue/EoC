--[[
    EoC Range – Bewegtes Ziel
    Fährt auf einer Schiene zwischen Startpunkt und Startpunkt + Strecke (aus Sicht des Schützen nach rechts).
    Drei Geschwindigkeiten; im Bewegtziel-Lauf bestimmt die gewählte Stufe das Tempo.
]]
AddCSLuaFile()

ENT.Base      = "range_popup"
ENT.PrintName = "Bewegtes Ziel"
ENT.Category  = "EoC Range"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RangeKind = "mover"
ENT.ThinkRate = 0

function ENT:SetupExtraVars()
    self:NetworkVar("Int", 5, "Track", { KeyName = "track", Edit = { type = "Int", order = 6, min = 50, max = 3000, title = "Strecke (Units nach rechts)" } })
    self:NetworkVar("Int", 6, "Speed", { KeyName = "speed", Edit = { type = "Int", order = 7, min = 1, max = 3, title = "Geschwindigkeit (1–3)" } })
    self:NetworkVar("Bool", 1, "Moving")
    self:NetworkVar("Vector", 0, "RailStart")
end

function ENT:InitDefaults()
    if self:GetSilhouette() < 1 then self:SetSilhouette(1) end
    if self:GetHitPoints() < 1 then self:SetHitPoints(1) end
    if self:GetTrack() < 50 then self:SetTrack(EoCRange.Config.MoverDefaultTrack) end
    if self:GetSpeed() < 1 then self:SetSpeed(1) end
end

-- Fahrtrichtung: lokal +Y (für den Schützen nach rechts)
function ENT:RailDir()
    return -self:GetRight()
end

-- Position für die Speicherung (immer der Startpunkt, nicht die aktuelle Lage auf der Schiene)
function ENT:GetPersistPos()
    return self:GetMoving() and self:GetRailStart() or self:GetPos()
end

if SERVER then
    function ENT:PostInit()
        self:SetUp(true)
        self:SetFlipAt(0)
        self.HitsTaken = 0
        self:SetRailStart(self:GetPos())
    end

    function ENT:StartMoving(stage)
        local speeds = EoCRange.Config.MoverSpeeds
        self.MoveSpeed = speeds[math.Clamp(stage or self:GetSpeed(), 1, #speeds)] or speeds[1]
        self.MoveT0 = CurTime()
        self:SetRailStart(self:GetPos())
        self:SetMoving(true)
    end

    function ENT:StopMoving()
        if not self:GetMoving() then return end
        self:SetMoving(false)
        self:SetPos(self:GetRailStart())
    end

    function ENT:MoverThink()
        if not self:GetMoving() then
            -- im Ruhezustand folgt der Startpunkt der Entity (z. B. nach dem Verschieben mit der Physgun)
            if self:GetRailStart() ~= self:GetPos() then self:SetRailStart(self:GetPos()) end
            return
        end
        local track = math.max(self:GetTrack(), 1)
        local d = (CurTime() - (self.MoveT0 or CurTime())) * (self.MoveSpeed or 70)
        local p = d % (2 * track)
        if p > track then p = 2 * track - p end
        self:SetPos(self:GetRailStart() + self:RailDir() * p)
    end

    function ENT:OnRemove()
        self:SetMoving(false)
    end
end
