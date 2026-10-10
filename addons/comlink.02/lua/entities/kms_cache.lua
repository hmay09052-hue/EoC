AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Kraken's Medical Supplies"
ENT.Spawnable = false
ENT.DisableDuplicator = true

function ENT:Initialize()
    self:SetModel("models/Items/HealthKit.mdl")
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
    end
end

if not SERVER then return end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if KrakensMedical and KrakensMedical.SendLoot then
        KrakensMedical.SendLoot(activator, self)
    end
end
