AddCSLuaFile()

-- Logistik-Terminal: verankert einen festen Standort (Zentrallager / Venator) auf der Map.
-- Admins: spawnen, mit Kontextmenü -> "Eigenschaften bearbeiten" den Standort wählen.
-- Position wird pro Map automatisch gespeichert.

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Logistik-Terminal"
ENT.Author    = "GAR Logistik"
ENT.Category  = "GAR Logistik"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Editable  = true

function ENT:SetupDataTables()
    local values = {}
    for _, l in ipairs(GARLog.Config.Locations) do values[l.name] = l.id end
    self:NetworkVar("String", 0, "LocationID", { KeyName = "locationid", Edit = { type = "Combo", order = 1, values = values } })

    if SERVER then
        self:NetworkVarNotify("LocationID", function()
            GARLog.MarkDirty("loc")
            GARLog.QueueSaveStatics()
        end)
    end
end

if SERVER then
    function ENT:SpawnFunction(ply, tr, class)
        if not tr.Hit then return end
        local ent = ents.Create(class)
        ent:SetPos(tr.HitPos)
        ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
        ent:Spawn()
        ent:Activate()
        ent:SetPos(tr.HitPos - Vector(0, 0, ent:OBBMins().z))
        return ent
    end

    function ENT:Initialize()
        local cfg = GARLog.Config
        self:SetModel(GARLog.ResolveModel(cfg.TerminalModel, cfg.TerminalFallback))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        if self:GetLocationID() == "" then self:SetLocationID(cfg.DefaultShip) end

        GARLog.RegisterStatic(self)
        GARLog.QueueSaveStatics()
    end

    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() or not GARLog.Can(ply, "view") then return end
        GARLog.OpenMenu(ply, 2, self:GetLocationID(), self)
    end

    function ENT:OnRemove()
        GARLog.UnregisterStatic(self)
        if not self.GARLogRemoving then GARLog.QueueSaveStatics() end
    end
else
    function ENT:Draw()
        self:DrawModel()
        if GARLog.DrawTerminal then GARLog.DrawTerminal(self) end
    end
end
