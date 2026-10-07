include("shared.lua")

local C = GRNStore and GRNStore.Config

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    self:DrawModel()

    if not C or not GRNStore or not GRNStore.DrawVendorIcon then return end
    GRNStore.DrawVendorIcon(self)
end
