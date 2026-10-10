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
            local UI = SSE.UI
            local holo = UI.Holo()
            local x, y, w, h = -300, -890, 550, 735
            local cx = x + w / 2

            UI.WorldPanel(x, y, w, h, holo, { fill = SSE.Config.TrainingRoomBoard["BackgroundColor"], seed = self:EntIndex() })
            local hy = y + 30
            hy = hy + UI.WorldHeading(self:GetRoomName(), cx, hy, holo, TEXT_ALIGN_CENTER)

            local owner = self:GetRoomOwner()
            local occupied = IsValid(owner)
            local stateCol = occupied and UI.col.red or UI.col.green

            -- Status-Plakette
            local sw, sh = w - 80, 56
            UI.Cut(x + 40, hy, sw, sh, UI.Alpha(stateCol, 50), 12, "tlbr")
            UI.CutOutline(x + 40, hy, sw, sh, stateCol, 12, "tlbr")
            UI.Box(x + 40, hy + 12, 5, sh - 24, stateCol)
            UI.Text(occupied and "BELEGT" or string.upper(SSE.Config.TrainingRoomBoard["RoomAvailable"]), "sse.world.h", cx, hy + sh / 2, stateCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            hy = hy + sh + 28

            if occupied then
                UI.Text(string.upper(self:GetSubTitle()), "sse.world.h", cx, hy, UI.col.text, TEXT_ALIGN_CENTER)
                UI.Text(self:GetSubTitle2(), "sse.world.body", cx, hy + 58, UI.col.text, TEXT_ALIGN_CENTER)
                UI.Text(self:GetSubTitle3(), "sse.world.small", cx, hy + 102, UI.col.dim, TEXT_ALIGN_CENTER)

                local oy = y + h - 150
                UI.Box(x + 40, oy, w - 80, 2, UI.Alpha(holo, 120))
                UI.Text(string.upper(SSE.Config.TrainingRoomBoard["RoomOccupied"]), "sse.world.small", cx, oy + 18, UI.col.dim, TEXT_ALIGN_CENTER)
                UI.TextFit(owner:Nick(), "sse.world.h", cx, oy + 52, color_white, w - 80, TEXT_ALIGN_CENTER)
            else
                local lines = UI.Wrap(SSE.Config.TrainingRoomBoard["Contact"], "sse.world.body", w - 80)
                for i, line in ipairs(lines) do
                    UI.Text(line, "sse.world.body", cx, hy + (i - 1) * 40, UI.col.dim, TEXT_ALIGN_CENTER)
                end
            end

            UI.Aurebesh("Training", "sse.world.aure", cx, y + h - 40, UI.Alpha(holo, 160), TEXT_ALIGN_CENTER)

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
        label:SetFont("sse.small.bold")
        label:SetTextColor(SSE.UI.col.dim)
        label:Dock(TOP)
        label:DockMargin(0, 10, 0, 2)

        local entry = SSE:TextEntry(SSE_SIMPLE_ATC_FRAME,room:GetSubTitle())
        entry:Dock(TOP)
        entry:SetTall(SSEH(50))

        local label = vgui.Create("DLabel", SSE_SIMPLE_ATC_FRAME)
        label:SetText(SSE.Config.TrainingRoomBoard["EditLine2"] )
        label:SetFont("sse.small.bold")
        label:SetTextColor(SSE.UI.col.dim)
        label:Dock(TOP)
        label:DockMargin(0, 10, 0, 2)

        local entry1 = SSE:TextEntry(SSE_SIMPLE_ATC_FRAME,room:GetSubTitle2())
        entry1:Dock(TOP)
        entry1:SetTall(SSEH(50))
  
        local label = vgui.Create("DLabel", SSE_SIMPLE_ATC_FRAME)
        label:SetText(SSE.Config.TrainingRoomBoard["EditLine3"] )
        label:SetFont("sse.small.bold")
        label:SetTextColor(SSE.UI.col.dim)
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

