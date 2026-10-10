AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Sink"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true


        
function ENT:Initialize()

        self:SetModel( SSE.Config.Sink["Model"] )
        self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
        self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
    
 

        self.SSE_HUDName = SSE.Config.Sink["HUDName"]

     
        if SERVER then 
            self:PhysicsInit( SOLID_VPHYSICS ) 
            self:SetUseType( SIMPLE_USE )
        end
        self:PhysWake()
end
    
if SERVER then

    function ENT:Use( activator, caller )

        self:EmitSound(SSE.Config.Sink["Sound"])

        activator:SetColor( Color( 255, 255, 255 ) )
        activator:SetMaterial( "" ) 
    end


end

