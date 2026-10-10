--[[
    EoC Range – Basis aller Schießstand-Entities
    Jede Entity gehört zu einer Bahn (Bahn-Nr.). Einstellbar über Rechtsklick -> "Eigenschaften bearbeiten" (C-Menü).
]]
AddCSLuaFile()

ENT.Type        = "anim"
ENT.Base        = "base_anim"
ENT.PrintName   = "EoC Range Basis"
ENT.Author      = "EoC"
ENT.Category    = "EoC Range"
ENT.Spawnable   = false
ENT.AdminOnly   = true
ENT.Editable    = true
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.IsEoCRange  = true
ENT.RangeKind   = "base"
ENT.BoxModel    = "models/hunter/blocks/cube025x025x025.mdl"
ENT.ThinkRate   = 0.05

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Lane", { KeyName = "lane", Edit = { type = "Int", order = 1, min = 1, max = 32, title = "Bahn-Nr." } })
    if self.SetupRangeVars then self:SetupRangeVars() end
end

-- Kollisionsbox in lokalen Koordinaten. Vorderseite = lokal +X (zeigt zum Schützen).
function ENT:GetBox()
    return Vector(-1, -12, 0), Vector(1, 12, 24)
end

-- Ändert sich dieser Schlüssel (z. B. Größe im Eigenschaften-Fenster), wird die Box neu gebaut
function ENT:BoxKey()
    return ""
end

function ENT:BuildBox()
    -- Sichtbares Model (z. B. B1-Droide); die Kollision bleibt die Box unten
    if SERVER and self.PickModel then
        local m = self:PickModel()
        if m and self:GetModel() ~= m then self:SetModel(m) end
    end
    local mins, maxs = self:GetBox()
    self:PhysicsInitBox(mins, maxs)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:EnableCustomCollisions(true)
    self:SetCollisionBounds(mins, maxs)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    if self.OnBoxBuilt then self:OnBoxBuilt() end
    if CLIENT then self:SetRenderBounds(mins - Vector(8, 8, 8), maxs + Vector(8, 8, 60)) end
end

function ENT:Think()
    local key = self:BoxKey()
    if key ~= self._boxKey then
        self._boxKey = key
        self:BuildBox()
    end
    if self.RangeThink then self:RangeThink() end
    if SERVER then
        self:NextThink(CurTime() + self.ThinkRate)
        return true
    end
end

if SERVER then
    function ENT:SpawnFunction(ply, tr, className)
        if not tr.Hit then return end
        local ent = ents.Create(className)
        ent:SetPos(tr.HitPos)
        ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
        ent:Spawn()
        ent:Activate()

        -- Bahn vom nächsten Terminal übernehmen
        local best, bestDist = nil, math.huge
        for _, t in ipairs(ents.FindByClass("range_terminal")) do
            local d = t:GetPos():DistToSqr(ent:GetPos())
            if t ~= ent and d < bestDist then best, bestDist = t, d end
        end
        if IsValid(best) and ent.SetLane then ent:SetLane(best:GetLane()) end
        return ent
    end

    function ENT:Initialize()
        self:SetModel(self.BoxModel)
        if self:GetLane() < 1 then self:SetLane(1) end
        if self.InitDefaults then self:InitDefaults() end
        self._boxKey = self:BoxKey()
        self:BuildBox()
        self:DrawShadow(false)
        if self.PostInit then self:PostInit() end
    end
else
    function ENT:Initialize()
        self._boxKey = self:BoxKey()
        self:BuildBox()
        if self.PostInit then self:PostInit() end
    end

    function ENT:Draw() end
end
