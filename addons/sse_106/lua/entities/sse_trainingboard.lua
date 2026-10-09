AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Training Room Board"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true
ENT.Editable         = true
function ENT:Initialize()

    self:SetModel( SSE.Config.TrainingRoomBoard["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox




 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )

        self:SetBodygroup(1, 1)
    end
    self:PhysWake()
end

function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "RoomName", { KeyName = "roomname",	Edit = { type = "Text"  } } ) 
	self:NetworkVar( "Vector",	0, "RoomColor",	{ KeyName = "roomcolor",	Edit = { type = "VectorColor",	order = 4 } } )
    self:NetworkVar( "Entity", 0, "RoomOwner" )
    self:NetworkVar( "String", 1, "SubTitle" ) 
    self:NetworkVar( "String", 2, "SubTitle2" ) 
    self:NetworkVar( "String", 3, "SubTitle3" ) 

    if SERVER then
        self:SetRoomName("New Room")
        self:SetRoomColor(Vector(0, 0, 255))
    end

end


if SERVER then
    function ENT:UpdateTransmitState()
        return TRANSMIT_ALWAYS
    end
    
    function ENT:ResetRoomLines()
        self:SetSubTitle("")
        self:SetSubTitle2("")
        self:SetSubTitle3("")
    end

    util.AddNetworkString("SSE_TrainingRoomBoard_OpenControlPanel")
    function ENT:Use( activator, caller )

        if !IsValid(activator) then return end
        if !self:GetRoomOwner() then return end
        if self:GetRoomOwner() != activator then return end

        net.Start("SSE_TrainingRoomBoard_OpenControlPanel")
            net.WriteEntity(self)
        net.Send(activator)

    end


    util.AddNetworkString("SSE_TrainingRoomBoard_SaveData")
    net.Receive("SSE_TrainingRoomBoard_SaveData", function(len, ply)
        local roomName = net.ReadString()
        local line1 = net.ReadString()
        local line2 = net.ReadString()
        local line3 = net.ReadString()

        for k, v in ipairs(ents.GetAll()) do
            if !IsValid(v) then continue end
            if v:GetClass() != "sse_trainingboard" then continue end
            if v:GetRoomName() != roomName then continue end
            if v:GetRoomOwner() != ply then continue end
            v:SetSubTitle(line1)
            v:SetSubTitle2(line2)
            v:SetSubTitle3(line3)
        end
    end)


end


if CLIENT then
    
    function ENT:Draw()
        self:DrawModel()

        local imgui = SSE.Imgui

        if imgui.Entity3D2D(self, Vector(0, 0, 0), Angle(0, 180, 90), 0.1, 1000, 500) then

            draw.RoundedBox(0, -300, -890, 550, 735, SSE.Config.TrainingRoomBoard["BackgroundColor"])
            

            draw.DrawText(self:GetRoomName(), SSE.xFont("!Agency FB@75#1000"), -25, -850, Color(209,209,209), TEXT_ALIGN_CENTER)

         

            if IsValid(self:GetRoomOwner()) then  

                draw.RoundedBox(0, -300, -760, 550, 2, Color(255,255,255,200))

                draw.DrawText(self:GetSubTitle(), SSE.xFont("!Agency FB@60#1000"), -25, -750, Color(209,209,209), TEXT_ALIGN_CENTER)
                draw.DrawText(self:GetSubTitle2(), SSE.xFont("!Agency FB@50#1000"), -25, -690, Color(209,209,209), TEXT_ALIGN_CENTER)
                draw.DrawText(self:GetSubTitle3(), SSE.xFont("!Agency FB@35#1000"), -25, -640, Color(209,209,209), TEXT_ALIGN_CENTER)

                draw.DrawText(SSE.Config.TrainingRoomBoard["RoomOccupied"], SSE.xFont("!Agency FB@50#1000"), -25, -300, Color(199,0,0), TEXT_ALIGN_CENTER)  
                draw.DrawText(self:GetRoomOwner():Nick(), SSE.xFont("!Agency FB@50#1000"), -25, -250, Color(209,209,209), TEXT_ALIGN_CENTER)
            else 
                draw.DrawText(SSE.Config.TrainingRoomBoard["RoomAvailable"], SSE.xFont("!Agency FB@50#1000"), -25, -600, Color(53,187,0), TEXT_ALIGN_CENTER)

                draw.DrawText(SSE.Config.TrainingRoomBoard["Contact"], SSE.xFont("!Agency FB@35#1000"), -25, -550, Color(200,200,200), TEXT_ALIGN_CENTER)
            end
         

            imgui.End3D2D()
        end

    end


    net.Receive("SSE_TrainingRoomBoard_OpenControlPanel", function()

        local room = net.ReadEntity()
        if IsValid(SSE_SIMPLE_ATC_FRAME) then SSE_SIMPLE_ATC_FRAME:Remove() end
        SSE_SIMPLE_ATC_FRAME = SSE:DefaultFrame(room:GetRoomName())
        SSE_SIMPLE_ATC_FRAME:SetSize(ScrW() * 0.3, ScrH() * 0.5)
        SSE_SIMPLE_ATC_FRAME:Center()
        SSE_SIMPLE_ATC_FRAME:MakePopup()


        -- Label for ENtry
        local label = vgui.Create("DLabel", SSE_SIMPLE_ATC_FRAME)
        label:SetText(SSE.Config.TrainingRoomBoard["EditLine1"] )
        label:SetFont(SSE.xFont("!Agency FB@25#1000"))
        label:Dock(TOP)
        label:DockMargin(0, 10, 0, 2)

        local entry = SSE:TextEntry(SSE_SIMPLE_ATC_FRAME,room:GetSubTitle())
        entry:Dock(TOP)
        entry:SetTall(SSEH(50))

        local label = vgui.Create("DLabel", SSE_SIMPLE_ATC_FRAME)
        label:SetText(SSE.Config.TrainingRoomBoard["EditLine2"] )
        label:SetFont(SSE.xFont("!Agency FB@25#1000"))
        label:Dock(TOP)
        label:DockMargin(0, 10, 0, 2)

        local entry1 = SSE:TextEntry(SSE_SIMPLE_ATC_FRAME,room:GetSubTitle2())
        entry1:Dock(TOP)
        entry1:SetTall(SSEH(50))
  
        local label = vgui.Create("DLabel", SSE_SIMPLE_ATC_FRAME)
        label:SetText(SSE.Config.TrainingRoomBoard["EditLine3"] )
        label:SetFont(SSE.xFont("!Agency FB@25#1000"))
        label:Dock(TOP)
        label:DockMargin(0, 10, 0, 2)

        local entry2 = SSE:TextEntry(SSE_SIMPLE_ATC_FRAME,room:GetSubTitle3())
        entry2:Dock(TOP)
        entry2:SetTall(SSEH(50))





        -- Save btn
        local button = SSE:Button(SSE_SIMPLE_ATC_FRAME, SSE.Config.TrainingRoomBoard["Save"], function()
            net.Start("SSE_TrainingRoomBoard_SaveData")
                net.WriteString(room:GetRoomName())
                net.WriteString(entry:GetValue())
                net.WriteString(entry1:GetValue())
                net.WriteString(entry2:GetValue())
            net.SendToServer()
            SSE_SIMPLE_ATC_FRAME:Remove()
        end, "clrtb")
        button:Dock(BOTTOM)

                    -- Save btn
                    local button = SSE:Button(SSE_SIMPLE_ATC_FRAME, SSE.Config.TrainingRoomBoard["GiveUp"], function()
                        net.Start("SSE_TRAININGROOM_CONTROL_SETOWNER")
                            net.WriteString(room:GetRoomName())
                            net.WriteEntity(nil)
                        net.SendToServer()
                        SSE_SIMPLE_ATC_FRAME:Remove()
                    end, "cb")
                    button:Dock(BOTTOM)
                    button:DockMargin(0, 10, 0, 10)
    end)

end

