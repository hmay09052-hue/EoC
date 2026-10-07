AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local function wardrobeEntityConfig()
    local W = GRNStore and GRNStore.Config and GRNStore.Config.Armory and GRNStore.Config.Armory.Wardrobe
    return istable(W) and istable(W.Entity) and W.Entity or {}
end

function ENT:Initialize()
    local cfg = wardrobeEntityConfig()
    local model = tostring(cfg.Model or "")
    if model == "" or not util.IsValidModel(model) then
        model = tostring(cfg.FallbackModel or "models/props_c17/Lockers001a.mdl")
    end

    self:SetModel(model)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    if not IsValid(self:GetPhysicsObject()) then
        self:SetSolid(SOLID_BBOX)
        local mins, maxs = self:GetModelBounds()
        if mins and maxs then self:SetCollisionBounds(mins, maxs) end
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not GRNStore or not GRNStore.OpenArmoryForPlayer then return end
    GRNStore.OpenArmoryForPlayer(activator, self)
end

function ENT:OnTakeDamage()
    return 0
end
