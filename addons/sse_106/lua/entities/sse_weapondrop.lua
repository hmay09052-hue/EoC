AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Weapondrop"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true
ENT.Editable = true

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "WeaponClass", { KeyName = "WeaponClass",	Edit = { type = "Text"  } } ) 


    if SERVER then
        self:SetWeaponClass("weapon_crowbar")
    end

end

function ENT:Initialize()

    self:SetModel( SSE.Config.WeaponDrop["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.WeaponDrop["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end

if SERVER then
        

    
    function ENT:Use( activator, caller )
       
        if activator:HasWeapon(self:GetWeaponClass()) then 
            activator:StripWeapon(self:GetWeaponClass())
        else 
            activator:Give(self:GetWeaponClass())
            activator:SelectWeapon(self:GetWeaponClass())
        end
    end


end



if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self)
    end

end