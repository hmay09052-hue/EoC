AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Radar Console"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true


function ENT:Initialize()

    self:SetModel( SSE.Config.RadarConsole["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.RadarConsole["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end


if SERVER then 

    util.AddNetworkString("SSE_SIMPLE_ATC")
    function ENT:Use( activator, caller )
        net.Start("SSE_SIMPLE_ATC")
        net.Send(activator)
    end

end

if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self)
    end

    function SSE_SIMPLE_ATC_MENU()
        if IsValid(SSE_SIMPLE_ATC_FRAME) then SSE_SIMPLE_ATC_FRAME:Remove() end
        SSE_SIMPLE_ATC_FRAME = SSE:DefaultFrame(SSE.Config.RadarConsole["FrameTitle"])
        SSE_SIMPLE_ATC_FRAME:SetSize(ScrW() * 0.3, ScrH() * 0.8)
        SSE_SIMPLE_ATC_FRAME:Center()
        SSE_SIMPLE_ATC_FRAME:MakePopup()

        local scrollPanel = SSE:ScrollBar(SSE_SIMPLE_ATC_FRAME)
        scrollPanel:Dock( FILL )

        local function fetchEntities(parent)
            for k, v in pairs(ents.GetAll()) do
                if !IsValid(v) then continue end
                if !v.LVS then continue end
                if !v.PrintName then continue end
                if table.HasValue(SSE.Config.RadarConsole["IgnoreClasses"], v:GetClass()) then continue end
    
                local button = SSE:Button(parent, v.PrintName .. " #"..v:GetCreationID(), function()
                end)
                button:Dock(TOP)
            end
        end

        fetchEntities(scrollPanel)

        local bottomPanel = vgui.Create("DPanel", SSE_SIMPLE_ATC_FRAME)
        bottomPanel:Dock(BOTTOM)
        bottomPanel:SetTall(SSEH(40))
        bottomPanel:SetPaintBackground(false)

        local refreshButton = SSE:Button(bottomPanel, SSE.Config.RadarConsole["Rescan"], function()
            scrollPanel:Clear()
            fetchEntities(scrollPanel)
        end, "bctlr")
        refreshButton:Dock(FILL)

    end


    net.Receive("SSE_SIMPLE_ATC", function()
        SSE_SIMPLE_ATC_MENU()
    end)


end

