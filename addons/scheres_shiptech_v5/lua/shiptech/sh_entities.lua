--[[
    ShipTech – Konsolen-Entities
    Eine Basis-Entity + alle Konsolen aus ShipTech.ConsoleTypes (sh_config.lua).
    Im Spawnmenü unter "Entities > ShipTech – Schiffstechnik".
]]

local CATEGORY = "ShipTech – Schiffstechnik"

local ENT = {}
ENT.Type        = "anim"
ENT.Base        = "base_anim"
ENT.PrintName   = "ShipTech Konsole"
ENT.Author      = "ShipTech"
ENT.Category    = CATEGORY
ENT.Spawnable   = false
ENT.AdminOnly   = true
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.IsShipTech  = true
ENT.ConsoleModel = "models/kingpommes/starwars/misc/bridge_console4.mdl"
ENT.ConsoleKind = "terminal"
ENT.HoloOffset  = 18

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "Sector", { KeyName = "sector", Edit = { type = "Generic", order = 1, title = "Sektor-Name" } })
end

if SERVER then
    function ENT:SpawnFunction(ply, tr, className)
        if not tr.Hit then return end
        local ent = ents.Create(className)
        ent:SetPos(tr.HitPos + tr.HitNormal * 2)
        ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
        ent:Spawn()
        ent:Activate()
        return ent
    end

    function ENT:Initialize()
        ShipTech.RegisterConsole(self)
        self:SetModel(self.ConsoleModel)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if not IsValid(phys) then
            self:PhysicsInitBox(self:OBBMins(), self:OBBMaxs())
            phys = self:GetPhysicsObject()
        end
        if IsValid(phys) then phys:EnableMotion(false) end

        if self.ConsoleKind == "breaker" and self:GetSector() == "" then
            self:SetSector("Sektor A")
        end
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        ShipTech.OpenFor(activator, self)
    end
else
    function ENT:Initialize()
        ShipTech.RegisterConsole(self)
        self:SetRenderBounds(self:OBBMins() - Vector(60, 60, 0), self:OBBMaxs() + Vector(60, 60, 260))
    end

    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:DrawTranslucent()
        if ShipTech.DrawConsoleHolo then
            ShipTech.DrawConsoleHolo(self)
        end
    end
end

function ENT:OnRemove()
    ShipTech.UnregisterConsole(self)
    if CLIENT and ShipTech.StopFireSound then ShipTech.StopFireSound(self) end
end

scripted_ents.Register(ENT, "shiptech_base")

-- Konsolen registrieren
for _, ct in ipairs(ShipTech.ConsoleTypes) do
    scripted_ents.Register({
        Base         = "shiptech_base",
        Type         = "anim",
        PrintName    = ct.name,
        Category     = CATEGORY,
        Spawnable    = true,
        AdminOnly    = true,
        Editable     = (ct.kind == "breaker"),
        RenderGroup  = RENDERGROUP_BOTH,
        IsShipTech   = true,
        ConsoleModel = ct.model,
        ConsoleKind  = ct.kind,
        SysId        = ct.sys,
        Purpose      = ct.purpose,
        HoloOffset   = ct.holo or 18,
        DefaultTab   = ct.tab,
    }, ct.class)
end
