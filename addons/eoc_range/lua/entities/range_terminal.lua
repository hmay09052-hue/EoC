--[[
    EoC Range – Bahn-Terminal
    Disziplin wählen, starten, Countdown; Live-Wertung als Hologramm darüber.
    Steuert nur die Ziele seiner eigenen Bahn.
]]
AddCSLuaFile()

ENT.Base      = "range_base"
ENT.PrintName = "Bahn-Terminal"
ENT.Category  = "EoC Range"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RangeKind = "terminal"
ENT.HoloOffset = 14

function ENT:SetupRangeVars()
    self:NetworkVar("String", 0, "Disciplines", { KeyName = "disciplines", Edit = { type = "Generic", order = 2, title = "Erlaubte Disziplinen (IDs mit Komma, leer = alle)" } })
end

function ENT:InitDefaults()
    for _, m in ipairs(EoCRange.Config.Models.terminal) do
        if util.IsValidModel(m) then
            self:SetModel(m)
            break
        end
    end
end

function ENT:BuildBox()
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if not IsValid(phys) then
            self:PhysicsInitBox(self:OBBMins(), self:OBBMaxs())
            phys = self:GetPhysicsObject()
        end
        if IsValid(phys) then phys:EnableMotion(false) end
        self:SetUseType(SIMPLE_USE)
    else
        self:SetRenderBounds(self:OBBMins() - Vector(60, 60, 0), self:OBBMaxs() + Vector(60, 60, 320))
    end
end

-- Erlaubte Disziplinen als Liste von IDs (leer = alle)
function ENT:AllowedSet()
    local raw = self:GetDisciplines() or ""
    local set, any = {}, false
    for id in string.gmatch(raw, "[^,%s]+") do
        set[id] = true
        any = true
    end
    return any and set or nil
end

function ENT:Allows(id)
    local set = self:AllowedSet()
    return set == nil or set[id] == true
end

if SERVER then
    function ENT:SpawnFunction(ply, tr, className)
        if not tr.Hit then return end
        local ent = ents.Create(className)
        ent:SetPos(tr.HitPos)
        ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
        ent:Spawn()
        ent:Activate()
        -- neue Terminals bekommen die nächste freie Bahn
        local used = {}
        for _, t in ipairs(ents.FindByClass("range_terminal")) do
            if t ~= ent then used[t:GetLane()] = true end
        end
        local lane = 1
        while used[lane] do lane = lane + 1 end
        ent:SetLane(lane)
        return ent
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if EoCRange.OpenTerminal then EoCRange.OpenTerminal(activator, self) end
    end
else
    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:DrawTranslucent()
        if EoCRange.DrawTerminalHolo then EoCRange.DrawTerminalHolo(self) end
    end
end
