AddCSLuaFile()

ENT.Base      = "garlog_structure"
ENT.PrintName = "Feld-Medbay"
ENT.Category  = "GAR Logistik"
ENT.Spawnable = false
ENT.StructID  = "medbay"
ENT.SupplyRes = "med"
ENT.UseMode   = CONTINUOUS_USE

if SERVER then
    function ENT:OnUse(ply)
        local def = self:GetDef()
        local now = CurTime()
        if (ply.GARLogMedCD or 0) > now then return end
        ply.GARLogMedCD = now + (def.tickDelay or 0.4)

        if ply:KeyDown(IN_SPEED) and self:HasRoleSupply() then
            self:RoleSupply(ply)
            ply.GARLogMedCD = now + 1
            return
        end

        local hp, max = ply:Health(), ply:GetMaxHealth()
        if hp >= max then
            GARLog.NotifyOnce(ply, "med_full", "Du bist bereits vollständig versorgt.", "info", 5)
            return
        end
        local heal = math.min(def.healPerTick or 8, max - hp)
        if not GARLog.ConsumeFrac(self:GetLocId(), "med", heal * (def.medPerHP or 0.1)) then
            GARLog.NotifyOnce(ply, "med_empty", "Medizinische Vorräte erschöpft – Nachschub anfordern!", "err")
            return
        end
        ply:SetHealth(hp + heal)
        if (self.NextSnd or 0) < now then
            self.NextSnd = now + 1.2
            self:EmitSound(GARLog.Config.Sounds.Heal, 60)
        end
    end
else
    function ENT:InfoLines()
        local C = GARLog.Col
        return {
            { "MEDIZIN: " .. GARLog.FmtNum(self:GetSupply()) .. " MED", C.text, self:GetSupply() / math.max(1, self:GetSupplyCap()), GARLog.Res.med.color },
            { "E HALTEN: BEHANDLUNG  //  SHIFT+E: SANI-MATERIAL", C.soft },
        }
    end
end
