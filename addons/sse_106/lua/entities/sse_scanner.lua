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

        self.ScanMode = scantype
        self.ScanTime = CurTime()
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
            local UI = SSE.UI
            local holo = UI.Holo()
            UI.WorldRadar(radarSize, holo, SSE.Config.Scanner["BackgroundColor"], SSE.Config.Scanner["Title"] or "Scanner", self:EntIndex())

            local rX, rY = WorldToRadar(self:GetPos())
            UI.WorldBlip(rX, rY, SSE.Config.Scanner["SelfColor"], 7)

            -- Ergebnisse des letzten Scans
            for k, v in ipairs(self.ScanTable) do
                local pX, pY = WorldToRadar(v)
                if math.abs(pX) <= radarSize and math.abs(pY) <= radarSize then
                    UI.WorldBlip(pX, pY, SSE.Config.Scanner["Target"], 6)
                end
            end

            -- Scan-Knöpfe
            local bx, bw, bh = -radarSize + 25, 230, 54
            local modes = { { SSE.Config.Scanner["Droids"], 3 }, { SSE.Config.Scanner["Lifeforms"], 2 }, { SSE.Config.Scanner["Vehicles"], 1 } }
            for i, mode in ipairs(modes) do
                local by = radarSize - 25 - bh * (4 - i) - 10 * (3 - i)
                local active = self.ScanMode == mode[2]
                if UI.WorldButton(imgui, mode[1], bx, by, bw, bh, active and UI.Accent() or holo) then
                    net.Start("SSE_RequestScan")
                        net.WriteEntity(self)
                        net.WriteInt(mode[2], 8)
                    net.SendToServer()
                end
            end

            UI.Text("KONTAKTE  " .. #self.ScanTable, "sse.world.small", -radarSize, radarSize + 14, UI.col.text)
            if self.ScanTime then
                local ago = math.floor(CurTime() - self.ScanTime)
                UI.Text("LETZTER SCAN VOR " .. ago .. " S", "sse.world.small", radarSize, radarSize + 14, UI.col.dim, TEXT_ALIGN_RIGHT)
            end
    
            imgui.End3D2D()
        end
    end
    
    

    
end