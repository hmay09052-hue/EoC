AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Web Console"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true
ENT.Editable = true

if SERVER then
        
    function ENT:Initialize()

        self:SetModel( SSE.Config.URLConsole["Model"] )
        self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
        self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
        self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
    
        self:SetUseType( SIMPLE_USE )


            local phys = self:GetPhysicsObject()
        if (phys:IsValid()) then
            phys:Wake()
        end
    end
    
    util.AddNetworkString("SSE_URL_CONSOLE")
    function ENT:Use( activator, caller )
        net.Start("SSE_URL_CONSOLE")
            net.WriteString(self:GetURL())
            net.WriteString(self:GetTitle())
        net.Send(activator)
    end




end

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "URL", { KeyName = "URL",	Edit = { type = "Text"  } } ) 
    self:NetworkVar( "String", 1, "Title", { KeyName = "Title",	Edit = { type = "Text"  } }  ) 


    if SERVER then
        self:SetURL("www.google.de")
        self:SetTitle("Google")
    end

end

if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self)
    end

end


if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self) 

        
        self.SSE_HUDName = self:GetTitle()
    end

    net.Receive("SSE_URL_CONSOLE", function()

        local url = net.ReadString()
        local title = net.ReadString()
        local frame =  SSE:DefaultFrame(title)
        frame:SetSize(ScrW() * 0.8, ScrH() * 0.8)
        frame:Center()

        local html = vgui.Create("DHTML", frame)
        html:Dock(FILL)
        html:OpenURL(url)
    end)

end