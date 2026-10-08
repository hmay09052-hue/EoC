AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Teleporter"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true
ENT.Editable       = true

function ENT:Initialize()

    self:SetModel( SSE.Config.Teleporter["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.Teleporter["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end


function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "TeleporterName", { KeyName = "teleportername",	Edit = { type = "Text"  } } ) 
	self:NetworkVar( "Int",	0, "Price",	{ KeyName = "price",	Edit = { type = "Int",	order = 4, min = 0, max = 9999999 } } )

    if SERVER then
        self:SetTeleporterName("Point A")
        self:SetPrice(0)
    end

end


if SERVER then 

    util.AddNetworkString("SSE_TELEPORTER_MENU")
    function ENT:Use( activator, caller )
        net.Start("SSE_TELEPORTER_MENU")
        net.WriteString(self:GetTeleporterName())
        net.Send(activator)
    end

    util.AddNetworkString("SSE_TELEPORTER_TELEPORT")

    net.Receive("SSE_TELEPORTER_TELEPORT", function(len, ply)
        local name = net.ReadString()
        local target = net.ReadEntity()

        if !IsValid(target) then return end
        if !IsValid(ply) then return end
        if target:GetClass() != "sse_teleporter" then return end

        local addVector = target:GetForward() * 50

        -- Set the vector to be 50 unit in front of the target entity


        if target:GetPrice() == 0 then
            ply:SetPos(target:GetPos() + addVector)
            return
        end

        if ply:canAfford(target:GetPrice()) then
            ply:addMoney(-target:GetPrice())
            ply:SetPos(target:GetPos() + addVector)
        else
            ply:ChatPrint(SSE.Config.Teleporter["PoorAsFuck"])
            return
        end

   
    end)


    function ENT:UpdateTransmitState()
        return TRANSMIT_ALWAYS
    end
end

if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self)
    end

    function SSE_TELEPORTER_MENU(currentName)
        if IsValid(SSE_TELEPORTER_FRAME) then SSE_TELEPORTER_FRAME:Remove() end
        SSE_TELEPORTER_FRAME = SSE:DefaultFrame(SSE.Config.Teleporter["FrameTitle"])
        SSE_TELEPORTER_FRAME:SetSize(ScrW() * 0.3, ScrH() * 0.8)
        SSE_TELEPORTER_FRAME:Center()
        SSE_TELEPORTER_FRAME:MakePopup()

        local scrollPanel = SSE:ScrollBar(SSE_TELEPORTER_FRAME)
        scrollPanel:Dock( FILL )

        local function fetchEntities(parent)
            for k, v in pairs(ents.GetAll()) do
                if !IsValid(v) then continue end
                if v:GetClass() != "sse_teleporter" then continue end

                if v:GetTeleporterName() == currentName then continue end
               
                local name = v:GetTeleporterName()

                if v:GetPrice() != 0 then
                    name = name .. " - " .. DarkRP.formatMoney(v:GetPrice())
                end

                local button = SSE:Button(parent, name, function()

                    if !LocalPlayer():canAfford(v:GetPrice()) then
                        LocalPlayer():ChatPrint(SSE.Config.Teleporter["PoorAsFuck"])
                        return 
                    end

                    surface.PlaySound(SSE.Config.Teleporter["Sound"])
                    LocalPlayer():ScreenFade(SCREENFADE.OUT, Color(0, 0, 0), 0.1, SSE.Config.Teleporter["BlackscreenTime"])

                    timer.Simple(0.5, function() 
                        net.Start("SSE_TELEPORTER_TELEPORT")
                            net.WriteString(v:GetTeleporterName())
                            net.WriteEntity(v)
                        net.SendToServer()
                    end )

              

                    SSE_TELEPORTER_FRAME:Close()
                end)
                button:Dock(TOP)
            end
        end

        fetchEntities(scrollPanel)

        local bottomPanel = vgui.Create("DPanel", SSE_TELEPORTER_FRAME)
        bottomPanel:Dock(BOTTOM)
        bottomPanel:SetTall(SSEH(40))
        bottomPanel:SetPaintBackground(false)

        local refreshButton = SSE:Button(bottomPanel, SSE.Config.RadarConsole["Rescan"], function()
            scrollPanel:Clear()
            fetchEntities(scrollPanel)
        end, "bctlr")
        refreshButton:Dock(FILL)

    end


    net.Receive("SSE_TELEPORTER_MENU", function()
        local name = net.ReadString()
        SSE_TELEPORTER_MENU(name)
    end)


end

