--[[
    EoC Range – Zielscheibe (Ringscheibe mit 10 Ringen)
    Einschusslöcher bleiben einige Sekunden sichtbar. Treffer werden über OnTakeDamage ausgewertet.
]]
AddCSLuaFile()

ENT.Base      = "range_base"
ENT.PrintName = "Zielscheibe"
ENT.Category  = "EoC Range"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RangeKind = "rings"

function ENT:SetupRangeVars()
    self:NetworkVar("Int", 1, "Size", { KeyName = "size", Edit = { type = "Int", order = 2, min = 1, max = 3, title = "Größe (1–3)" } })
    self:NetworkVar("Int", 2, "Distance", { KeyName = "distance", Edit = { type = "Int", order = 3, min = 0, max = 500, title = "Distanz in m (0 = egal)" } })
    self:NetworkVar("Int", 3, "CenterHeight", { KeyName = "centerheight", Edit = { type = "Int", order = 4, min = 10, max = 120, title = "Höhe der Mitte" } })
end

function ENT:InitDefaults()
    if self:GetSize() < 1 then self:SetSize(2) end
    if self:GetCenterHeight() < 10 then self:SetCenterHeight(56) end
end

function ENT:HalfSize()
    local C = EoCRange.Config
    return C.TargetSizes[math.Clamp(self:GetSize(), 1, 3)] or 15
end

function ENT:Center()
    return math.max(self:GetCenterHeight(), self:HalfSize() + 2)
end

function ENT:BoxKey()
    return self:GetSize() .. ":" .. self:GetCenterHeight()
end

function ENT:GetBox()
    local h, c = self:HalfSize(), self:Center()
    return Vector(-1, -h, c - h), Vector(1, h, c + h)
end

-- Weltposition -> Ring (0..10) und Trefferpunkt relativ zur Mitte
function ENT:Evaluate(pos)
    local lp = self:WorldToLocal(pos)
    local u, v = lp.y, lp.z - self:Center()
    local half = self:HalfSize()
    local dist = math.sqrt(u * u + v * v) / half
    local ring = 0
    if dist <= 1 then ring = math.Clamp(10 - math.floor(dist * 10), 1, 10) end
    return ring, u / half, v / half
end

if SERVER then
    function ENT:OnTakeDamage(dmg)
        if EoCRange.OnTargetDamage then EoCRange.OnTargetDamage(self, dmg) end
    end
else
    function ENT:Draw()
        if EoCRange.DrawRingTarget then EoCRange.DrawRingTarget(self) end
    end
end
