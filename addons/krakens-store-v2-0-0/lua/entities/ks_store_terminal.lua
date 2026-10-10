AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Kraken's Store Terminal"
ENT.Author = "Kraken"
ENT.Category = "Kraken's Store"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "TerminalName")
end

local L = KrakensStore.L

if SERVER then
    function ENT:Initialize()
        local cfg = KrakensStore.Config.Entities.Terminal
        KrakensStore.Utils.SetupEntityPhysics(self, cfg.Model, cfg.Look)
        self:SetTerminalName(L("entity_store_terminal_default_name"))
    end

    function ENT:Use(activator, caller)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if not KrakensStore.Utils.UseDebounce(activator, 1) then return end
        KrakensStore.OpenStoreFor(activator)
    end

    ENT.SpawnFunction = KrakensStore.Utils.EntitySpawnFunction
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:DrawTranslucent()
        local name = self:GetTerminalName()
        if name == "" then name = L("entity_store_terminal_default_name") end
        KrakensStore.UI.DrawEntityLabel3D(self, name, L("entity_press_e_open"))
    end
end
