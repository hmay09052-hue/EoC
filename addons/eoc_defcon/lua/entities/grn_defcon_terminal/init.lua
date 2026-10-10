AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local terminalConfig = (GRN_DEFCON and GRN_DEFCON.Config and GRN_DEFCON.Config.Terminal) or {}
    local model = tostring(terminalConfig.Model or "models/lordtrilobite/starwars/isd/imp_console_medium01.mdl")

    if not util.IsValidModel(model) then
        model = "models/props_combine/combine_interface001.mdl"
    end

    self:SetModel(model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local physics = self:GetPhysicsObject()
    if IsValid(physics) then
        physics:Wake()
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if (self.GRNNextUse or 0) > CurTime() then return end
    self.GRNNextUse = CurTime() + 0.45

    local terminalConfig = (GRN_DEFCON and GRN_DEFCON.Config and GRN_DEFCON.Config.Terminal) or {}
    local useDistance = tonumber(terminalConfig.UseDistance) or 155
    if activator:GetPos():DistToSqr(self:GetPos()) > math.pow(useDistance + 32, 2) then return end

    if GRN_DEFCON and GRN_DEFCON.OpenTerminal then
        GRN_DEFCON.OpenTerminal(activator, self)
    end
end

function ENT:SpawnFunction(player, trace, className)
    if not trace.Hit then return end

    local entity = ents.Create(className)
    if not IsValid(entity) then return end

    entity:SetPos(trace.HitPos + trace.HitNormal * 4)
    entity:SetAngles(Angle(0, player:EyeAngles().y + 180, 0))
    entity:Spawn()
    entity:Activate()

    return entity
end
