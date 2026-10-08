AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Turbolaser Console"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()

    self:SetModel( SSE.Config.TurbolaserConsole["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.TurbolaserConsole["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end

if SERVER then


    util.AddNetworkString("SSE_WEAPONCONSOLE")

    function ENT:Use( activator, caller )
        net.Start("SSE_WEAPONCONSOLE")
        net.Send(activator)
    end
end



if CLIENT then



    function ENT:Draw()
        self.BaseClass.Draw(self)  -- We want to override rendering, so don't call baseclass.
                                    -- Use this when you need to add to the rendering.
        --self:DrawEntityOutline( 1.0 ) -- Draw an outline of 1 world unit.
        --self:DrawModel()       -- Draw the model.


    end

end




if SERVER then
     
    util.AddNetworkString( "SSE_WEAPONCONSOLE_SELECT" )
   
    
    
    net.Receive( "SSE_WEAPONCONSOLE_SELECT", function( len, ply )
        local ent = net.ReadEntity()

        if !table.HasValue(SSE.Config.TurbolaserConsole["TurbolaserClass"], ent:GetClass()) then return end

        ply.SSE_returnPos = ply:GetPos()
        ent:Use(ply)

    end)

    hook.Add( "PlayerLeaveVehicle", "SSE_RETURN_PLAYER", function( ply, veh )
        
        if ply.SSE_returnPos != nil then 
        
            timer.Simple(0, function() ply:SetPos(ply.SSE_returnPos) ply.SSE_returnPos = nil end)
    
        end
    end )

    
end
        
    
    if CLIENT then
    
        function SSE_WEAPON_CONSOLE_PANEL() 
            if ValidPanel(TLCFrame) then TLCFrame:Remove() end
            TLCFrame = SSE:DefaultFrame()
            TLCFrame:SetSize(SSEW(500),SSEH(600))
            TLCFrame:Center()
            TLCFrame:SetNewTitle(SSE.Config.TurbolaserConsole["FrameTitle"])
            TLCFrame:SetSizable(false)
            TLCFrame:SetDraggable(false)
    
            local content = SSE:ScrollBar(TLCFrame) 
            content:Dock(FILL)
            local newTable = {}

            for k, v in ipairs(ents.GetAll()) do
                if !table.HasValue(SSE.Config.TurbolaserConsole["TurbolaserClass"], v:GetClass()) then
                    continue
                end

                local btn = SSE:Button(content, SSE.Config.TurbolaserConsole["TurbolaserName"].." #"..v:EntIndex(), function() 
                    if ValidPanel(TLCFrame) then TLCFrame:Remove() end
                    if !IsValid(v:GetDriver()) then
                        net.Start("SSE_WEAPONCONSOLE_SELECT")
                        net.WriteEntity(v)
                        net.SendToServer()
                    end
                end, "lc")

                btn:Dock(TOP)
                btn:DockMargin(5,10,5,0)


    
    
            end        
        end
        net.Receive( "SSE_WEAPONCONSOLE", function( len, ply )
            SSE_WEAPON_CONSOLE_PANEL()
        end)

    end

    