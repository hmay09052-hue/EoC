ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Inventory Item"
ENT.Category = "GRN Inventory"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ItemID")
    self:NetworkVar("Int", 0, "ItemQuantity")
end
