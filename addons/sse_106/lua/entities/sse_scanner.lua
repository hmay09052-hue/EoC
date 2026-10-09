AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Scanner"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true



if SERVER then
        
    function ENT:Initialize()

        self:SetModel( SSE.Config.Scanner["Model"]  )
        self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
        self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
    

     
        if SERVER then 
            self:PhysicsInit( SOLID_VPHYSICS ) 
        end
        self:PhysWake()
    end
    

    util.AddNetworkString("SSE_RequestScan")
    util.AddNetworkString("SSE_ScannerDoScan")

    net.Receive("SSE_RequestScan", function(len, ply)

        
        local ent = net.ReadEntity()
        local mode = net.ReadInt(8)
       
        net.Start("SSE_ScannerDoScan")
            net.WriteEntity(ent)
            net.WriteInt(mode, 8)
        net.SendPVS(ent:GetPos())
       
    end)

end

function ENT:SetupDataTables()

    self:NetworkVar( "Int", 0, "Mode" ) 

    if SERVER then
        self:SetMode(1)
    end

end



if CLIENT then

    ENT.ScanTable = {}
    function ENT:DoScan(scantype) 
        self.ScanTable = {}
        if scantype == 1 then
            for k, v in ipairs(ents.GetAll()) do
                if v.LVS then
                    table.insert(self.ScanTable, v:GetPos())
                end
            end
        end
        if scantype == 2 then
            for k, v in ipairs(player.GetAll()) do
                if v:Alive() then
                    table.insert(self.ScanTable, v:GetPos())
                end
            end
        end
        if scantype == 3 then
            for k, v in ipairs(ents.GetAll()) do
                if v:IsNPC() or v:IsNextBot() then
                    table.insert(self.ScanTable, v:GetPos())
                end
            end
        end

        self:EmitSound(SSE.Config.Scanner["Sound"] )
   
    end

    net.Receive("SSE_ScannerDoScan", function(len, ply)

        local ent = net.ReadEntity()
        local mode = net.ReadInt(8)
        ent:DoScan(mode) 
    end) 


    ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

    
    function ENT:DrawTranslucent()

        local imgui = SSE.Imgui

        local radarSize = SSE.Config.Scanner["Size"] -- Half of the radar size (since the radar is square)
        
        -- Fetch map bounds
        local world = game.GetWorld()
        local mapMinBound, mapMaxBound = world:GetModelBounds()
        
        -- Function to map world coordinates to radar coordinates
        local function WorldToRadar(worldPos)
            -- Calculate scale based on the map bounds
            local scaleX = radarSize * 2 / (mapMaxBound.x - mapMinBound.x)
            local scaleY = radarSize * 2 / (mapMaxBound.y - mapMinBound.y)
    
            -- Convert world position to radar position
            local radarX = (worldPos.x - mapMinBound.x) * scaleX - radarSize
            local radarY = (worldPos.y - mapMinBound.y) * scaleY - radarSize
    
            -- Clamp to ensure the position stays within the radar square
            radarX = math.Clamp(radarX, -radarSize, radarSize)
            radarY = math.Clamp(radarY, -radarSize, radarSize)
    
            return radarX, radarY
        end
    
        if imgui.Entity3D2D(self, Vector(0, 0, 0), Angle(0, 90, 0), 0.1, 1000, 500) then
            -- Draw filled radar square
            draw.RoundedBox(0, -radarSize, -radarSize, radarSize * 2, radarSize * 2, SSE.Config.Scanner["BackgroundColor"])
    
            -- Draw radar center
            --draw.RoundedBox(50, -5, -5, 10, 10, Color(0, 255, 0, 200))
    

            -- Draw radar border
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawOutlinedRect(-radarSize, -radarSize, radarSize * 2, radarSize * 2)
            
            if imgui.xTextButton(SSE.Config.Scanner["Vehicles"], SSE.xFont("!Agency FB@25#1000"), -radarSize + 25, radarSize - 75, 100, 50, 1, Color(145,145,145), Color(255,255,255), Color(255,205,205)) then
                net.Start("SSE_RequestScan")
                    net.WriteEntity(self)
                    net.WriteInt(1, 8)
                net.SendToServer()
            end

            if imgui.xTextButton(SSE.Config.Scanner["Lifeforms"], SSE.xFont("!Agency FB@25#1000"), -radarSize + 25, radarSize - 135, 100, 50, 1, Color(145,145,145), Color(255,255,255), Color(255,205,205)) then
                net.Start("SSE_RequestScan")
                    net.WriteEntity(self)
                    net.WriteInt(2, 8)
                net.SendToServer()
            end

            if imgui.xTextButton(SSE.Config.Scanner["Droids"], SSE.xFont("!Agency FB@25#1000"), -radarSize + 25, radarSize - 195, 100, 50, 1, Color(145,145,145), Color(255,255,255), Color(255,205,205)) then
                net.Start("SSE_RequestScan")
                    net.WriteEntity(self)
                    net.WriteInt(3, 8)
                net.SendToServer()
            end


            local rX, rY = WorldToRadar(self:GetPos())
            draw.RoundedBox(50, rX-5,rY-5, 10, 10, SSE.Config.Scanner["SelfColor"] )

            -- Draw players on the radar
            for k, v in ipairs(self.ScanTable) do

          
                local pX, pY = WorldToRadar(v)
    
                -- Ensure the player dot is drawn within radar boundaries
                if math.abs(pX) <= radarSize and math.abs(pY) <= radarSize then
                    draw.RoundedBox(50, pX - 5, pY - 5, 10, 10, SSE.Config.Scanner["Target"])
                end
            end
    
            imgui.End3D2D()
        end
    end
    
    

    
end