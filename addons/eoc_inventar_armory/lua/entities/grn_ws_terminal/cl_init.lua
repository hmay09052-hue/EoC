include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    if GRNSerials and GRNSerials.DrawStationExtras then GRNSerials.DrawStationExtras(self) end
end

function ENT:DrawTranslucent()
    if GRNSerials and GRNSerials.DrawStationLabel then GRNSerials.DrawStationLabel(self) end
end
