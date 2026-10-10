AddCSLuaFile()

-- Baustelle: Hologramm der Zielstruktur, wird mit dem GAR-Datapad aufgebaut

ENT.Type        = "anim"
ENT.Base        = "base_anim"
ENT.PrintName   = "Baustelle"
ENT.Author      = "GAR Logistik"
ENT.Category    = "GAR Logistik"
ENT.Spawnable   = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "Progress")
    self:NetworkVar("Int", 0, "HP")
    self:NetworkVar("Int", 1, "MaxHP")
    self:NetworkVar("String", 0, "Title")
    self:NetworkVar("String", 1, "BuildKey")
    self:NetworkVar("String", 2, "FOBName")
end

if SERVER then
    function ENT:SetupSite(def, model, paid, ply)
        self.Def = def
        self.TargetModel = model
        self.Paid = paid or {}
        self.BuilderName = GARLog.Name(ply)
    end

    function ENT:Initialize()
        self:SetModel(self.TargetModel or "models/props_junk/wood_crate002a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR) -- Spieler laufen durch, Datapad-Strahl trifft
        self:SetUseType(SIMPLE_USE)
        self:DrawShadow(false)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end

        local def = self.Def or {}
        local hp = math.max(50, math.floor((def.health or 500) * 0.3))
        self:SetMaxHP(hp)
        self:SetHP(hp)
        self:SetProgress(0)
        self:SetTitle(def.name or "Baustelle")
        self:SetBuildKey(def.key or "")
    end

    function ENT:AddProgress(ply, dt)
        if self.Completing then return end
        local t = math.max(1, (self.Def and self.Def.time) or 20)
        local p = math.min(1, self:GetProgress() + dt / t)
        self:SetProgress(p)
        self.LastBuilder = GARLog.Name(ply)

        local now = CurTime()
        if (self.NextFX or 0) < now then
            self.NextFX = now + 0.6
            self:EmitSound(GARLog.Config.Sounds.BuildTick, 65, math.random(90, 110), 0.6)
        end
        if (self.NextSync or 0) < now then
            self.NextSync = now + 1
            GARLog.MarkDirty("loc")
        end

        if p >= 1 then
            self.Completing = true
            GARLog.FOB.CompleteSite(self, self.LastBuilder)
        end
    end

    function ENT:OnTakeDamage(dmg)
        if not GARLog.Config.FOB.TakeDamage then return end
        local amount = dmg:GetDamage()
        local att = dmg:GetAttacker()
        if IsValid(att) and att:IsPlayer() then amount = amount * GARLog.Config.FOB.PlayerDamageScale end
        self:SetHP(math.max(0, self:GetHP() - math.floor(amount)))
        if self:GetHP() <= 0 and not self.GARLogDestroyed then
            self.GARLogDestroyed = true
            local f = GARLog.FOB.OfEnt(self)
            GARLog.Log(string.format("%s: Baustelle '%s' zerstört.", f and f.name or "?", self:GetTitle()), "err")
            local fx = EffectData()
            fx:SetOrigin(self:WorldSpaceCenter())
            util.Effect("Explosion", fx)
            self:Remove()
        end
    end

    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        GARLog.NotifyOnce(ply, "site_info", string.format("Baustelle %s: %d%% – mit dem Datapad aufbauen (LMB halten).",
            self:GetTitle(), math.floor(self:GetProgress() * 100)), "info", 4)
    end
else
    function ENT:DrawTranslucent()
        if GARLog.DrawSite then GARLog.DrawSite(self) end
    end
end
