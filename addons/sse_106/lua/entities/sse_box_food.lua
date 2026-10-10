AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Food Supply"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()

    self:SetModel( SSE.Config.Foodbox["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.Foodbox["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end


if SERVER then
        

    function ENT:Use( activator, caller )

        if !DarkRP then return end
        if not DarkRP.disabledDefaults["modules"]["hungermod"] then
            if activator:IsPlayer() then
                local maxHunger = SSE.Config.Foodbox["MaxFood"] 
                local currentHunger = activator:getDarkRPVar("Energy") or 0
                local newHunger = currentHunger + SSE.Config.Foodbox["AddFood"]

                if newHunger > maxHunger then
                newHunger = maxHunger
                end

                activator:SetSelfDarkRPVar("Energy", newHunger)
            end
        end
    end


end

