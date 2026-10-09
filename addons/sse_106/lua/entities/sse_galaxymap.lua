AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Galaxymap"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true


function ENT:Initialize()

    self:SetModel( SSE.Config.GalaxyMap["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.GalaxyMap["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end


if SERVER then
        
    util.AddNetworkString("SSE_GalaxyMap")
    function ENT:Use( activator, caller )
        net.Start("SSE_GalaxyMap")
        net.Send(activator)
    end




end



if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self) 
    end

    net.Receive("SSE_GalaxyMap", function()
        local frame =  SSE:DefaultFrame("The Galaxy")
        frame:SetSize(ScrW() * 0.8, ScrH() * 0.8)
        frame:Center()

        local html = vgui.Create("DHTML", frame)
        html:Dock(FILL)
        html:OpenURL("https://hbernberg.carto.com/builder/6650a85d-b115-4680-ab97-721bf8a41a90/embed")
    end)

end



