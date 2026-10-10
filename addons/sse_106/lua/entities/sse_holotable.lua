AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Holotable"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true



if SERVER then
        
    function ENT:Initialize()

        self:SetModel( SSE.Config.Holotable["Model"] )
        self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
        self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
    


     
        if SERVER then 
            self:PhysicsInit( SOLID_VPHYSICS ) 
            self:SetUseType( SIMPLE_USE )
        end
        self:PhysWake()
    end
    
    function ENT:Use( activator, caller )
        if ( !activator.IsHologram ) then
            activator.IsHologram = true
            activator:SetMaterial( "ace/sw/hologram") 
        else
            activator.IsHologram = false
            activator:SetMaterial( "") 
        end
    end


end



if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self) 
    end

end