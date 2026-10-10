AddCSLuaFile()

ENT.Base      = "garlog_structure"
ENT.PrintName = "Generator"
ENT.Category  = "GAR Logistik"
ENT.Spawnable = false
ENT.StructID  = "generator"
ENT.SupplyRes = "fuel"

function ENT:IsOperational()
    return not self:GetDestroyed() and self:GetOn()
end

if SERVER then
    function ENT:OnInit()
        self:SetOn(true)
        self:NetworkVarNotify("Powered", function(ent, _, _, new) ent:UpdateHum(new) end)
    end

    function ENT:UpdateHum(running)
        if not self.Hum then self.Hum = CreateSound(self, GARLog.Config.Sounds.GeneratorLoop) end
        if running then self.Hum:PlayEx(0.45, 100) else self.Hum:Stop() end
    end

    function ENT:Toggle(ply)
        if self:GetDestroyed() then return end
        if not (GARLog.Can(ply, "fob.manage") or GARLog.HasRole(ply, "techniker")) then
            GARLog.NotifyOnce(ply, "gen_perm", "Nur Techniker oder Kommando können den Generator schalten.", "err")
            return
        end
        if (self.NextToggle or 0) > CurTime() then return end
        self.NextToggle = CurTime() + 1
        self:SetOn(not self:GetOn())
        self:EmitSound(self:GetOn() and GARLog.Config.Sounds.PowerOn or GARLog.Config.Sounds.PowerOff, 70)
        local f = GARLog.FOB.OfEnt(self)
        GARLog.Log(string.format("%s: Generator %s von %s.", f and f.name or "?", self:GetOn() and "gestartet" or "abgeschaltet", GARLog.Name(ply)))
    end

    function ENT:OnUse(ply)
        self:Toggle(ply)
    end

    function ENT:OnDestroyedFn()
        if self.Hum then self.Hum:Stop() end
    end
else
    function ENT:InfoLines()
        local C = GARLog.Col
        local state, col
        if not self:GetOn() then
            state, col = "ABGESCHALTET", C.muted
        elseif self:GetPowered() then
            state, col = "IN BETRIEB", C.green
        else
            state, col = "KEIN TREIBSTOFF", C.red
        end
        return {
            { "STATUS: " .. state, col },
            { "TREIBSTOFF: " .. GARLog.FmtNum(self:GetSupply()) .. " TRB", C.text, self:GetSupply() / math.max(1, self:GetSupplyCap()), GARLog.Res.fuel.color },
            { "E: EIN / AUS (TECHNIKER)", C.soft },
        }
    end
end
