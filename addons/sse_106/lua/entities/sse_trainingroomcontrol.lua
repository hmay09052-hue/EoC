AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Training Room Control Panel"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true


        
function ENT:Initialize()

        self:SetModel( SSE.Config.TrainingRoomControlPanel["Model"] )
        self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
        self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
    
 

        self.SSE_HUDName = SSE.Config.TrainingRoomControlPanel["HUDName"]

     
        if SERVER then 
            self:PhysicsInit( SOLID_VPHYSICS ) 
            self:SetUseType( SIMPLE_USE )
        end
        self:PhysWake()
end
    
if SERVER then


    util.AddNetworkString("SSE_OPEN_TRAININGROOMCONTROL")
    function ENT:Use( activator, caller )

        net.Start("SSE_OPEN_TRAININGROOMCONTROL")
        net.Send(activator)

    end

    util.AddNetworkString("SSE_TRAININGROOM_CONTROL_SETOWNER")
    net.Receive("SSE_TRAININGROOM_CONTROL_SETOWNER", function(len, ply)
        local roomName = net.ReadString()
        local ent = net.ReadEntity()

        if ply == ent then return end

        for k, v in ipairs(ents.GetAll()) do
            if !IsValid(v) then continue end
            if v:GetClass() != "sse_trainingboard" then continue end
            if v:GetRoomName() != roomName then continue end
            v:SetRoomOwner(ent)

            if !IsValid(ent) then
                v:ResetRoomLines()
            end
        end

        if IsValid(ent) then
            ent:ChatPrint(SSE.Config.TrainingRoomControlPanel["NewOwner"]..roomName)
        end
    end)


end



if CLIENT then
    function SSE_TRAININGROOM_CONTROl_SELECTOWNER(roomName)
        if IsValid(SSE_SIMPLE_ATC_FRAME) then SSE_SIMPLE_ATC_FRAME:Remove() end
        SSE_SIMPLE_ATC_FRAME = SSE:DefaultFrame(SSE.Config.TrainingRoomControlPanel["SelectOwner"]..roomName)
        SSE_SIMPLE_ATC_FRAME:SetSize(ScrW() * 0.3, ScrH() * 0.8)
        SSE_SIMPLE_ATC_FRAME:Center()
        SSE_SIMPLE_ATC_FRAME:MakePopup()

        local scrollPanel = SSE:ScrollBar(SSE_SIMPLE_ATC_FRAME)
        scrollPanel:Dock( FILL )

        local button = SSE:Button(scrollPanel, SSE.Config.TrainingRoomControlPanel["SetToFree"], function()
            net.Start("SSE_TRAININGROOM_CONTROL_SETOWNER")
                net.WriteString(roomName)
                net.WriteEntity(nil)
            net.SendToServer()
            SSE_SIMPLE_ATC_FRAME:Remove()
        end)
        button:Dock(TOP)


        for k, v in ipairs(player.GetAll()) do
            local button = SSE:Button(scrollPanel, v:Nick(), function()
                net.Start("SSE_TRAININGROOM_CONTROL_SETOWNER")
                    net.WriteString(roomName)
                    net.WriteEntity(v)
                net.SendToServer()
                SSE_SIMPLE_ATC_FRAME:Remove()
            end)
            button:Dock(TOP)
        end
    end 

    function SSE_TRAININGROOM_CONTROL()
        if IsValid(SSE_SIMPLE_ATC_FRAME) then SSE_SIMPLE_ATC_FRAME:Remove() end
        SSE_SIMPLE_ATC_FRAME = SSE:DefaultFrame(SSE.Config.TrainingRoomControlPanel["FrameTitle"])
        SSE_SIMPLE_ATC_FRAME:SetSize(ScrW() * 0.3, ScrH() * 0.8)
        SSE_SIMPLE_ATC_FRAME:Center()
        SSE_SIMPLE_ATC_FRAME:MakePopup()

        local scrollPanel = SSE:ScrollBar(SSE_SIMPLE_ATC_FRAME)
        scrollPanel:Dock( FILL )

        local function fetchEntities(parent)

            local roomNames = {}
            for k, v in ipairs(ents.GetAll()) do
                if !IsValid(v) then continue end
                if v:GetClass() != "sse_trainingboard" then continue end
                if table.HasValue(roomNames, v:GetRoomName()) then continue end

   

                table.insert(roomNames, v:GetRoomName())

                local owner = SSE.Config.TrainingRoomControlPanel["Free"]

                if IsValid(v:GetRoomOwner()) then
                    owner = v:GetRoomOwner():Nick()
                end

                local button = SSE:Button(parent, v:GetRoomName() .. " - ".. owner, function()
                    SSE_TRAININGROOM_CONTROl_SELECTOWNER(v:GetRoomName())
                end)
                button:Dock(TOP)
            end
        end

        fetchEntities(scrollPanel)

    end




    net.Receive("SSE_OPEN_TRAININGROOMCONTROL", function()
        SSE_TRAININGROOM_CONTROL()
    end)
end