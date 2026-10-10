AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Live Radar Scanner"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true



if SERVER then
        
    function ENT:Initialize()

        self:SetModel( SSE.Config.LiveScanner["Model"]  )
        self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
        self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
    

     
        if SERVER then 
            self:PhysicsInit( SOLID_VPHYSICS ) 
        end
        self:PhysWake()
    end
    



end


if CLIENT then




    ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

    
    function ENT:DrawTranslucent()

        local imgui = SSE.Imgui

        local radarSize = SSE.Config.LiveScanner["Size"] -- Half of the radar size (since the radar is square)
        
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
            UI.WorldRadar(radarSize, UI.Holo(), SSE.Config.LiveScanner["BackgroundColor"], SSE.Config.LiveScanner["Title"] or "Live-Radar", self:EntIndex())

            local rX, rY = WorldToRadar(self:GetPos())
            UI.WorldBlip(rX, rY, SSE.Config.LiveScanner["SelfColor"], 7)

            -- Fahrzeuge (LVS) auf dem Radar
            local count = 0
            for k, v in ipairs(ents.GetAll()) do
                local pX, pY = WorldToRadar(v:GetPos())
                if v.LVS and math.abs(pX) <= radarSize and math.abs(pY) <= radarSize then
                    count = count + 1
                    UI.WorldBlip(pX, pY, SSE.Config.LiveScanner["Target"], 5)

                    if SSE.Config.LiveScanner["ShowNames"] then 
                        local name = v.PrintName or ""
                        draw.SimpleText(string.upper(name .. " #" .. v:EntIndex()), imgui.xFont("!Roboto Condensed@16#700"), pX, pY + 9, UI.col.text, TEXT_ALIGN_CENTER)
                    end
                end
            end

            UI.Text("KONTAKTE  " .. count, "sse.world.small", -radarSize, radarSize + 14, UI.col.text)
            UI.Aurebesh("Live", "sse.world.aure", radarSize, radarSize + 14, UI.Holo(200), TEXT_ALIGN_RIGHT)
    
            imgui.End3D2D()
        end
    end
    
    

    
end