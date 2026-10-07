include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    if GRNStore and GRNStore.DrawArmoryIcon then
        GRNStore.DrawArmoryIcon(self)
    end
end
