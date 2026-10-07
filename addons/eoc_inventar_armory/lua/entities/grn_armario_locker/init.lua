AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local cfg = GRNWeaponrio and GRNWeaponrio.Config or {}
    local mdl = cfg.EntityModel or "models/eemyscifipack/props/furniture/scifi_locker.mdl"

    if not util.IsValidModel(mdl) then
        mdl = cfg.EntityFallbackModel or "models/props_c17/Lockers001a.mdl"
    end

    self:SetModel(mdl)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not GRNWeaponrio or not GRNWeaponrio.OpenLocker then return end

    GRNWeaponrio.OpenLocker(activator, self)
end
