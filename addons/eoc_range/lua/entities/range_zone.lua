--[[
    EoC Range – Bahnzone (unsichtbarer Bereich)
    Nur wer darin steht, kann einen Lauf starten; wer sie verlässt, bricht den Lauf ab.
    Sichtbar nur mit Physgun/Toolgun in der Hand. Größe über die Toolgun "EoC Range – Zone" oder die Eigenschaften.
    Basis für Start- und Zielzone des Parcours.
]]
AddCSLuaFile()

ENT.Base      = "range_base"
ENT.PrintName = "Bahnzone"
ENT.Category  = "EoC Range"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RangeKind = "zone"
ENT.IsRangeZone = true
ENT.ZoneColor = Color(255, 190, 50)
ENT.DefaultSize = Vector(160, 240, 110)

function ENT:SetupRangeVars()
    self:NetworkVar("Float", 0, "SizeX", { KeyName = "sizex", Edit = { type = "Float", order = 2, min = 16, max = 4000, title = "Tiefe" } })
    self:NetworkVar("Float", 1, "SizeY", { KeyName = "sizey", Edit = { type = "Float", order = 3, min = 16, max = 4000, title = "Breite" } })
    self:NetworkVar("Float", 2, "SizeZ", { KeyName = "sizez", Edit = { type = "Float", order = 4, min = 16, max = 1000, title = "Höhe" } })
end

function ENT:InitDefaults()
    if self:GetSizeX() < 16 then self:SetSizeX(self.DefaultSize.x) end
    if self:GetSizeY() < 16 then self:SetSizeY(self.DefaultSize.y) end
    if self:GetSizeZ() < 16 then self:SetSizeZ(self.DefaultSize.z) end
end

function ENT:ZoneBounds()
    local x, y = self:GetSizeX() / 2, self:GetSizeY() / 2
    return Vector(-x, -y, 0), Vector(x, y, self:GetSizeZ())
end

function ENT:BoxKey()
    return self:GetSizeX() .. ":" .. self:GetSizeY() .. ":" .. self:GetSizeZ()
end

-- Kleiner Griff am Ursprung, damit man die Zone mit der Physgun greifen kann
function ENT:BuildBox()
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WORLD)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
    else
        local mins, maxs = self:ZoneBounds()
        self:SetRenderBounds(mins, maxs)
    end
end

function ENT:Contains(pos)
    local l = self:WorldToLocal(pos)
    return math.abs(l.x) <= self:GetSizeX() / 2 and math.abs(l.y) <= self:GetSizeY() / 2 and l.z >= -24 and l.z <= self:GetSizeZ()
end

if CLIENT then
    function ENT:Draw()
        if EoCRange.DrawZone then EoCRange.DrawZone(self) end
    end
end
