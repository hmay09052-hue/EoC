AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_gmodentity"
ENT.PrintName = "Funk-Störsender"
ENT.Author    = "Militärisches Funksystem"
ENT.Category  = "Militärisches Funksystem"
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Active")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/props_lab/reciever01b.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end

        self:SetMaxHealth(CryptoRadio.Config.JammerHealth)
        self:SetHealth(CryptoRadio.Config.JammerHealth)
        self:SetActive(true)
        self:UpdateHum()
    end

    function ENT:UpdateHum()
        if not self.Hum then
            self.Hum = CreateSound(self, "ambient/machines/combine_terminal_loop1.wav")
        end
        if self:GetActive() then
            self.Hum:PlayEx(0.35, 100)
        else
            self.Hum:Stop()
        end
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        self:SetActive(not self:GetActive())
        self:EmitSound(self:GetActive() and "buttons/button1.wav" or "buttons/button18.wav")
        self:UpdateHum()
    end

    function ENT:OnTakeDamage(dmg)
        self:SetHealth(self:Health() - dmg:GetDamage())
        if self:Health() <= 0 and not self.Destroyed then
            self.Destroyed = true
            local fx = EffectData()
            fx:SetOrigin(self:GetPos())
            util.Effect("Explosion", fx)
            self:Remove()
        end
    end

    function ENT:OnRemove()
        if self.Hum then self.Hum:Stop() end
    end
else
    local red, green = Color(225, 88, 88), Color(74, 203, 130)
    local yellow = Color(252, 178, 73)

    function ENT:Draw()
        self:DrawModel()

        if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > 600 * 600 then return end

        local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 12)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)

        cam.Start3D2D(pos, ang, 0.1)
            local active = self:GetActive()
            surface.SetDrawColor(7, 9, 12, 230)
            surface.DrawRect(-130, -34, 260, 68)
            surface.SetDrawColor(yellow)
            surface.DrawRect(-130, 32, 260, 2)
            draw.SimpleText("STÖRSENDER", "CryptoRadio_Title", 0, -12, Color(244, 241, 233), 1, 1)
            draw.SimpleText(active and "AKTIV" or "AUS", "CryptoRadio_Button", 0, 16, active and red or green, 1, 1)
        cam.End3D2D()
    end
end
