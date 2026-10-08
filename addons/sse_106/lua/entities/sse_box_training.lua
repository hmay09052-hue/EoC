AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Trainingsbox"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()

    self:SetModel( SSE.Config.Trainingsbox["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.Trainingsbox["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end


if SERVER then
        

    function ENT:Use( activator, caller )

        activator:SetHealth(activator:GetMaxHealth())
        activator:SetArmor(activator:GetMaxArmor())
        wep = activator:GetActiveWeapon()
        if wep then
            activator:GiveAmmo(SSE.Config.AmmoBox["Amount"], wep:GetPrimaryAmmoType())
            activator:GiveAmmo(SSE.Config.AmmoBox["Amount"], wep:GetSecondaryAmmoType())
        end
    end


end
