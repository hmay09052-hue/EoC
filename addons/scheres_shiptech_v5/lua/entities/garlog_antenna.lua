AddCSLuaFile()

ENT.Base      = "garlog_structure"
ENT.PrintName = "Kommunikationsantenne"
ENT.Category  = "GAR Logistik"
ENT.Spawnable = false
ENT.StructID  = "antenna"

if SERVER then
    function ENT:OnUse(ply)
        GARLog.OpenMenu(ply, 3, self:GetLocId(), self)
    end
else
    function ENT:InfoLines()
        local C = GARLog.Col
        local online = self:IsOperational()
        return {
            { online and "VERBINDUNG ZUR FLOTTE: AKTIV" or "VERBINDUNG ZUR FLOTTE: OFFLINE", online and C.green or C.red },
            { online and "SHUTTLE-LEITSIGNAL AKTIV" or "KEINE SHUTTLE-LANDUNG MÖGLICH", online and C.soft or C.orange },
            { "E: VERSORGUNG ANFORDERN", C.soft },
        }
    end
end
