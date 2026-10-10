AddCSLuaFile()

ENT.Base      = "garlog_structure"
ENT.PrintName = "Versorgungslager"
ENT.Category  = "GAR Logistik"
ENT.Spawnable = false
ENT.StructID  = "storage"
ENT.ShowSupplyBars = true   -- 3D-Anzeige: Füllstand aller Ressourcen

if SERVER then
    function ENT:OnUse(ply)
        GARLog.OpenMenu(ply, 2, self:GetLocId(), self)
    end
else
    function ENT:InfoLines()
        local C = GARLog.Col
        return { { "E: LAGERBESTAND  //  CONTAINER HIER ENTLADEN", C.soft } }
    end
end
