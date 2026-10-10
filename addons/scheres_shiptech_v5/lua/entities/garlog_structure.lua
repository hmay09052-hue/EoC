AddCSLuaFile()

-- Basis aller Feldbasis-Strukturen (Zustand, Schaden, Strom, Anzeige)

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "GAR Struktur"
ENT.Author    = "GAR Logistik"
ENT.Category  = "GAR Logistik"
ENT.Spawnable = false

ENT.GARLogStructure = true
ENT.StructID  = "storage"   -- Schlüssel in GARLog.Config.Structures
ENT.SupplyRes = nil         -- Ressource, deren FOB-Bestand angezeigt wird
ENT.UseMode   = SIMPLE_USE

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "HP")
    self:NetworkVar("Int", 1, "MaxHP")
    self:NetworkVar("Int", 2, "Supply")
    self:NetworkVar("Int", 3, "SupplyCap")
    self:NetworkVar("Bool", 0, "Powered")
    self:NetworkVar("Bool", 1, "Destroyed")
    self:NetworkVar("Bool", 2, "On")
    self:NetworkVar("String", 0, "FOBName")
end

function ENT:GetDef()
    return GARLog.Config.Structures[self.StructID] or {}
end

function ENT:IsOperational()
    if self:GetDestroyed() then return false end
    if self:GetDef().needsPower and not self:GetPowered() then return false end
    return true
end

if SERVER then
    function ENT:Initialize()
        local def = self:GetDef()
        self:SetModel(GARLog.DefModel(def))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(self.UseMode)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end

        local hp = def.health or 1000
        self:SetMaxHP(hp)
        self:SetHP(hp)
        self:SetFOBName("")
        if self.OnInit then self:OnInit() end
    end

    function ENT:GetLocId()
        local f = GARLog.FOB.OfEnt(self)
        return f and f.locId
    end

    function ENT:SetHealthValue(v)
        v = math.Clamp(math.floor(v), 0, self:GetMaxHP())
        if v == self:GetHP() then return end
        self:SetHP(v)
        GARLog.FOB.OnHealthChanged(self)
    end

    function ENT:Repair(amount)
        self.RepairAcc = (self.RepairAcc or 0) + amount
        local whole = math.floor(self.RepairAcc)
        if whole < 1 then return end
        self.RepairAcc = self.RepairAcc - whole
        self:SetHealthValue(self:GetHP() + whole)

        if self:GetDestroyed() and self:GetHP() >= self:GetMaxHP() * GARLog.Config.Repair.OperationalAt then
            self:SetDestroyed(false)
            self:SetColor(color_white)
            self:EmitSound(GARLog.Config.Sounds.BuildDone, 70)
            GARLog.FOB.OnRestored(self)
        end
    end

    function ENT:OnTakeDamage(dmg)
        local cfg = GARLog.Config.FOB
        if not cfg.TakeDamage or self:GetDestroyed() then return end
        local amount = dmg:GetDamage()
        local att = dmg:GetAttacker()
        if IsValid(att) and att:IsPlayer() then amount = amount * cfg.PlayerDamageScale end
        if dmg:IsExplosionDamage() then amount = amount * cfg.BlastDamageScale end
        if amount <= 0 then return end

        self.DmgAcc = (self.DmgAcc or 0) + amount
        local whole = math.floor(self.DmgAcc)
        if whole < 1 then return end
        self.DmgAcc = self.DmgAcc - whole
        self:SetHealthValue(self:GetHP() - whole)
        if self:GetHP() <= 0 then self:Destroy() end
    end

    function ENT:Destroy()
        if self:GetDestroyed() then return end
        self:SetDestroyed(true)
        self:SetPowered(false)
        self:SetColor(Color(70, 70, 70))
        local fx = EffectData()
        fx:SetOrigin(self:WorldSpaceCenter())
        util.Effect("Explosion", fx)
        if self.OnDestroyedFn then self:OnDestroyedFn() end
        GARLog.FOB.OnDestroyed(self)
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        local def = self:GetDef()
        if self:GetDestroyed() then
            GARLog.NotifyOnce(activator, "destroyed", (def.name or "Struktur") .. " ist zerstört – ein Techniker muss reparieren.", "err")
            return
        end
        if def.needsPower and not self:GetPowered() then
            GARLog.NotifyOnce(activator, "nopower", "Kein Strom – Generator der Feldbasis aus oder ohne Treibstoff.", "err")
            return
        end
        if self.OnUse then self:OnUse(activator) end
    end

    function ENT:HasRoleSupply()
        local rs = self:GetDef().roleSupply
        return rs ~= nil and rs.weapons ~= nil and #rs.weapons > 0
    end

    -- Rollenmaterial (Sanitäter / Techniker) gegen Lagerbestand auffüllen
    function ENT:RoleSupply(ply)
        local rs = self:GetDef().roleSupply
        if not rs or not rs.weapons or #rs.weapons == 0 or not self.SupplyRes then return end
        local role = GARLog.Config.Roles[rs.role]
        if not GARLog.HasRole(ply, rs.role) and not GARLog.IsAdmin(ply) then
            GARLog.NotifyOnce(ply, "rolesupply", "Nur " .. (role and role.name or rs.role) .. " können hier Material auffüllen.", "err")
            return
        end
        local wait = (ply.GARLogSupplyCD or 0) - CurTime()
        if wait > 0 then
            GARLog.NotifyOnce(ply, "supplycd", string.format("Material erst wieder in %ds verfügbar.", math.ceil(wait)), "info")
            return
        end
        local locId = self:GetLocId()
        local cost = { [self.SupplyRes] = rs.cost or 10 }
        if not GARLog.HasStock(locId, cost) then
            GARLog.NotifyOnce(ply, "rolesupply_stock", "Nicht genug " .. GARLog.Res[self.SupplyRes].name .. " im Lager.", "err")
            return
        end

        local did = false
        for _, cls in ipairs(rs.weapons) do
            local w = ply:GetWeapon(cls)
            if not IsValid(w) then
                w = ply:Give(cls)
                if IsValid(w) then did = true end
            elseif w:GetMaxClip1() > 0 and w:Clip1() < w:GetMaxClip1() then
                w:SetClip1(w:GetMaxClip1())
                did = true
            end
        end
        if not did then
            GARLog.NotifyOnce(ply, "rolesupply_full", "Dein Material ist bereits vollständig.", "info")
            return
        end
        GARLog.TakeStock(locId, cost, true)
        ply.GARLogSupplyCD = CurTime() + (rs.cooldown or 30)
        GARLog.Notify(ply, "Material aufgefüllt (" .. GARLog.ItemsText(cost) .. ").", "ok")
    end

    function ENT:OnRemove()
        if self.Hum then self.Hum:Stop() end
    end
else
    function ENT:Draw()
        self:DrawModel()
        if GARLog.DrawStructure then GARLog.DrawStructure(self) end
    end

    -- Zusätzliche Zeilen für die 3D-Anzeige: { text, farbe }
    function ENT:InfoLines() return nil end
end
