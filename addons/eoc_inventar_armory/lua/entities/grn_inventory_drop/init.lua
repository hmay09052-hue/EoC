AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local id = self:GetItemID()
    local def = GRNInventory and GRNInventory.GetItemDefinition and GRNInventory.GetItemDefinition(id) or nil
    local model = def and def.DropModel or "models/props_junk/cardboard_box004a.mdl"

    if not util.IsValidModel(model) then
        model = "models/props_junk/cardboard_box004a.mdl"
    end

    self:SetModel(model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if not IsValid(phys) then
        -- Armor parts / some world models ship without a collision model.
        local mins, maxs = self:OBBMins(), self:OBBMaxs()
        if (maxs - mins):Length() < 2 then
            mins, maxs = Vector(-6, -6, -6), Vector(6, 6, 6)
        end
        self:PhysicsInitBox(mins, maxs)
        self:SetSolid(SOLID_BBOX)
        phys = self:GetPhysicsObject()
    end
    if IsValid(phys) then
        phys:Wake()
    end

    if GRNInventory and GRNInventory.Config and GRNInventory.Config.DropLifetime > 0 then
        timer.Simple(GRNInventory.Config.DropLifetime, function()
            if IsValid(self) then self:Remove() end
        end)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self.GRNPickupLockedUntil and CurTime() < self.GRNPickupLockedUntil and self.GRNDropOwner == activator then return end

    if activator:GetPos():DistToSqr(self:GetPos()) > ((GRNInventory.Config.DropDistance or 92) ^ 2) then
        return
    end

    if not GRNInventory or not GRNInventory.PickupWorldEntity then return end
    GRNInventory.PickupWorldEntity(activator, self)
end
