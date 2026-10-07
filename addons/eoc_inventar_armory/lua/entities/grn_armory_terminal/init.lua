AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local A = GRNStore and GRNStore.Config and GRNStore.Config.Armory

function ENT:Initialize()
    if not A or not A.Entity then return end

    local model = tostring(A.Entity.Model or "models/reizer_props/srsp/sci_fi/armory_02/armory_02.mdl")
    if util.IsValidModel and not util.IsValidModel(model) then
        model = "models/reizer_props/srsp/sci_fi/armory_02/armory_02.mdl"
    end

    self:SetModel(model)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetUseType(SIMPLE_USE)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)

    local mins, maxs = self:GetModelBounds()
    if mins and maxs then self:SetCollisionBounds(mins, maxs) end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not GRNStore or not GRNStore.OpenArmoryForPlayer then return end
    GRNStore.OpenArmoryForPlayer(activator, self)
end

function ENT:OnTakeDamage()
    return 0
end
