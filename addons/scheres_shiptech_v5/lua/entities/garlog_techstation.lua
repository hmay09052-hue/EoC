AddCSLuaFile()

ENT.Base      = "garlog_structure"
ENT.PrintName = "Technikerstation"
ENT.Category  = "GAR Logistik"
ENT.Spawnable = false
ENT.StructID  = "techstation"
ENT.SupplyRes = "tech"
ENT.UseMode   = CONTINUOUS_USE

if SERVER then
    function ENT:OnUse(ply)
        local def = self:GetDef()
        local now = CurTime()
        if (ply.GARLogTechCD or 0) > now then return end
        ply.GARLogTechCD = now + (def.tickDelay or 0.4)

        if ply:KeyDown(IN_SPEED) and self:HasRoleSupply() then
            self:RoleSupply(ply)
            ply.GARLogTechCD = now + 1
            return
        end

        local ar, max = ply:Armor(), ply:GetMaxArmor()
        if ar >= max then
            GARLog.NotifyOnce(ply, "tech_full", "Deine Plastoidpanzerung ist intakt.", "info", 5)
            return
        end
        local add = math.min(def.armorPerTick or 8, max - ar)
        if not GARLog.ConsumeFrac(self:GetLocId(), "tech", add * (def.techPerArmor or 0.1)) then
            GARLog.NotifyOnce(ply, "tech_empty", "Ersatzteile erschöpft – Nachschub anfordern!", "err")
            return
        end
        ply:SetArmor(ar + add)
        if (self.NextSnd or 0) < now then
            self.NextSnd = now + 1.2
            self:EmitSound(GARLog.Config.Sounds.Armor, 60)
        end
    end
else
    function ENT:InfoLines()
        local C = GARLog.Col
        return {
            { "ERSATZTEILE: " .. GARLog.FmtNum(self:GetSupply()) .. " TEC", C.text, self:GetSupply() / math.max(1, self:GetSupplyCap()), GARLog.Res.tech.color },
            { "E HALTEN: PANZERUNG  //  FAHRZEUGE IN DER NÄHE REPARIERBAR", C.soft },
        }
    end
end
