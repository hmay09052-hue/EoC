AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Kraken's Workbench"
ENT.Author = "Kraken"
ENT.Category = "Kraken's Store"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "WorkbenchName")
end

local L = KrakensStore.L

if SERVER then
    function ENT:Initialize()
        local cfg = KrakensStore.Config.Entities.Workbench
        KrakensStore.Utils.SetupEntityPhysics(self, cfg.Model, cfg.Look)
        self:SetWorkbenchName(L("entity_workbench_default_name"))
    end

    function ENT:Use(activator, caller)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if not KrakensStore.Utils.UseDebounce(activator, 1) then return end

        local weapon = activator:GetActiveWeapon()
        if not IsValid(weapon) then
            activator:ChatPrint(L("entity_need_weapon"))
            return
        end

        local system = KrakensStore.Integrations.DetectWeaponSystem(weapon)
        if not system then
            activator:ChatPrint(L("entity_weapon_not_compatible"))
            return
        end

        KF.Net.Send("KrakensStore_OpenWorkbench", function()
            net.WriteBool(system == "arc9")
        end, activator)
    end

    ENT.SpawnFunction = KrakensStore.Utils.EntitySpawnFunction
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:DrawTranslucent()
        local name = self:GetWorkbenchName()
        if name == "" then name = L("entity_workbench_default_name") end
        KrakensStore.UI.DrawEntityLabel3D(self, name, L("entity_press_e_customize"))
    end
end
