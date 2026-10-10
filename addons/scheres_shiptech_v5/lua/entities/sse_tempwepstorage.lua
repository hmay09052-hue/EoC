AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Temporary Weapon Storage"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()

    self:SetModel( SSE.Config.TempWepStorage["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.TempWepStorage["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end


if SERVER then
        
 
    ENT.WeaponStorage = {}
    
    function ENT:Use( activator, caller )

        if self.WeaponStorage[activator:EntIndex()] then 

            for k, v in pairs(self.WeaponStorage[activator:EntIndex()]) do 
                activator:Give(v)
            end

            self.WeaponStorage[activator:EntIndex()] = nil
        else 
    
            local waffen = activator:GetWeapons()

            local classTbl = {}

            for k, v in pairs(waffen) do
                table.insert(classTbl, v:GetClass())
            end 

            self.WeaponStorage[activator:EntIndex()] = classTbl

            activator:StripWeapons()

            for k, v in pairs(SSE.Config.TempWepStorage["KeepWeapons"]) do
                activator:Give(v)
            end
        end


    end


end



if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self)
    end

end