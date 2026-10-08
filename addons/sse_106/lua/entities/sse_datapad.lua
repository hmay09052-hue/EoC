AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Datapad"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

if SERVER then
        
    function ENT:Initialize()

        self:SetModel( SSE.Config.Datapad["Model"] )
        self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
        self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
        self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
    
        self:SetUseType( SIMPLE_USE )


            local phys = self:GetPhysicsObject()
        if (phys:IsValid()) then
            phys:Wake()
        end
    end
    
    util.AddNetworkString("SSE_DataPad")
    function ENT:Use( activator, caller )

        self.DataPadData = self.DataPadData or "Nothing..."

     
        net.Start("SSE_DataPad")
            net.WriteEntity(self)
            net.WriteString(self.DataPadData)
        net.Send(activator)
    end

    util.AddNetworkString("SSE_RecieveDatapad_Data")
    net.Receive("SSE_RecieveDatapad_Data", function(len, ply)
        local ent = net.ReadEntity()
        local data = net.ReadString()
        ent.DataPadData = data

    end)


end



if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self)
    end




    net.Receive("SSE_DataPad", function()

        local ent = net.ReadEntity()
        local text = net.ReadString()
        
        if ValidPanel(SSE_DataPadFrame) then SSE_DataPadFrame:Remove() end
        SSE_DataPadFrame = SSE:DefaultFrame(SSE.Config.Datapad["FrameTitle"])
        SSE_DataPadFrame:SetSize(SSEW(600), SSEH(900))
        SSE_DataPadFrame:Center()

        local MultiLine = vgui.Create("DTextEntry", SSE_DataPadFrame)
        MultiLine:Dock(FILL)
        MultiLine:SetMultiline(true)
        MultiLine:SetEditable(true)
        MultiLine:SetFont(SSE.xFont(SSE.Config.Datapad["Font"]))
        MultiLine:SetTextColor(Color(255, 255, 255))
        MultiLine:SetDrawBackground(false)
        MultiLine:SetDrawBorder(false)
        MultiLine:SetCursorColor(Color(255, 255, 255))
        MultiLine:SetVerticalScrollbarEnabled(true)
        MultiLine:SetValue(text)
        

        local bottomPanel = vgui.Create("DPanel", SSE_DataPadFrame)
        bottomPanel:Dock(BOTTOM)
        bottomPanel:SetTall(SSEH(50))
        bottomPanel:DockMargin(0, 0, 0, 0)
        bottomPanel.Paint = nil 

        local btnSave = SSE:Button(bottomPanel, SSE.Config.Datapad["Save"], function() 
            net.Start("SSE_RecieveDatapad_Data")
            net.WriteEntity(ent)
            net.WriteString(MultiLine:GetValue())
            net.SendToServer()

            SSE_DataPadFrame:Remove()
        
        end, "bc")
        btnSave:Dock(FILL)
        btnSave:DockMargin(0, 0, 0, 0)



    end)


end

