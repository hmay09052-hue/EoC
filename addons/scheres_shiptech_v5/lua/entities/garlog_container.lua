AddCSLuaFile()

-- Frachtcontainer: physisch transportierbar (LAAT, Fahrzeug, Physgun), wird am Ziel entladen

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Frachtcontainer"
ENT.Author    = "GAR Logistik"
ENT.Category  = "GAR Logistik"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "ContainerID")
    self:NetworkVar("Int", 1, "Volume")
    self:NetworkVar("Int", 2, "HP")
    self:NetworkVar("Float", 0, "UnloadEnd")
    self:NetworkVar("Bool", 0, "Attached")
    self:NetworkVar("String", 0, "Summary")
    self:NetworkVar("String", 1, "SrcName")
    self:NetworkVar("String", 2, "DestName")
end

if SERVER then
    function ENT:Initialize()
        local cfg = GARLog.Config.Container
        self:SetModel(GARLog.ResolveModel(cfg.Model, cfg.Fallback))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(cfg.Mass or 300)
            phys:Wake()
        end
        self:SetHP(cfg.Health or 1500)
        self.Items = {}
    end

    function ENT:SetItems(items)
        self.Items = items or {}
        self:SetSummary(GARLog.ItemsText(self.Items))
        self:SetVolume(GARLog.ItemVolume(self.Items))
    end

    function ENT:SetCargo(id, items, src, reqId, by)
        self:SetContainerID(id)
        self.Src, self.Req, self.PackedBy = src, reqId, by
        self:SetSrcName(GARLog.LocName(src))
        local r = reqId and GARLog.Requests[reqId]
        self:SetDestName(r and (GARLog.LocName(r.from) .. "  //  ANTRAG #" .. reqId) or "")
        self:SetItems(items)
    end

    function ENT:Use(ply)
        if IsValid(ply) and ply:IsPlayer() then GARLog.OpenEntityMenu(ply, 3, self) end
    end

    function ENT:OnTakeDamage(dmg)
        local amount = dmg:GetDamage()
        if dmg:IsExplosionDamage() then amount = amount * 1.5 end
        local att = dmg:GetAttacker()
        if IsValid(att) and att:IsPlayer() then amount = amount * GARLog.Config.FOB.PlayerDamageScale end
        self:SetHP(math.max(0, self:GetHP() - math.floor(amount)))
        if self:GetHP() <= 0 and not self.GARLogDestroyed then
            self.GARLogDestroyed = true
            local fx = EffectData()
            fx:SetOrigin(self:WorldSpaceCenter())
            util.Effect("Explosion", fx)
            self:Remove()
        end
    end

    function ENT:OnRemove()
        GARLog.OnContainerRemoved(self)
    end
else
    function ENT:Draw()
        self:DrawModel()
        if GARLog.DrawContainer then GARLog.DrawContainer(self) end
    end
end
