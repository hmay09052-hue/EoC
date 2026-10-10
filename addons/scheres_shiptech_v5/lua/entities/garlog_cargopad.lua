AddCSLuaFile()

-- Frachtrampe: Bereitstellungs- und Entladeplatz für Frachtcontainer eines Standorts.
-- Admins: spawnen, mit Kontextmenü -> "Eigenschaften bearbeiten" den Standort wählen.

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Frachtrampe"
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
        ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
        ent:Spawn()
        ent:Activate()
        ent:SetPos(tr.HitPos - Vector(0, 0, ent:OBBMins().z) + Vector(0, 0, 0.5))
        return ent
    end

    function ENT:Initialize()
        self:SetModel(GARLog.Config.CargoPadModel)
        self:SetMaterial("phoenix_storms/metalset_1-2")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:DrawShadow(false)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        if self:GetLocationID() == "" then self:SetLocationID(GARLog.Config.DefaultShip) end

        GARLog.RegisterStatic(self)
        GARLog.QueueSaveStatics()
    end

    function ENT:OnRemove()
        GARLog.UnregisterStatic(self)
        if not self.GARLogRemoving then GARLog.QueueSaveStatics() end
    end
else
    function ENT:Draw()
        self:DrawModel()
        if GARLog.DrawCargoPad then GARLog.DrawCargoPad(self) end
    end
end
