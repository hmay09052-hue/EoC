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
            -- Draw filled radar square
            draw.RoundedBox(0, -radarSize, -radarSize, radarSize * 2, radarSize * 2, SSE.Config.LiveScanner["BackgroundColor"])
    
            -- Draw radar center
            --draw.RoundedBox(50, -5, -5, 10, 10, Color(0, 255, 0, 200))
    

            -- Draw radar border
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawOutlinedRect(-radarSize, -radarSize, radarSize * 2, radarSize * 2)


            local rX, rY = WorldToRadar(self:GetPos())
            draw.RoundedBox(50, rX-5,rY-5, 10, 10, SSE.Config.LiveScanner["SelfColor"] )

            -- Draw players on the radar
            for k, v in ipairs(ents.GetAll()) do
                if !v.LVS then continue end
          
                local pX, pY = WorldToRadar(v:GetPos())
    
                local name = v.PrintName or ""
                -- Ensure the player dot is drawn within radar boundaries
                if math.abs(pX) <= radarSize and math.abs(pY) <= radarSize then
                    draw.RoundedBox(50, pX - 5, pY - 5, 10, 10, SSE.Config.LiveScanner["Target"])

                    if SSE.Config.LiveScanner["ShowNames"] then 
                        draw.DrawText(name  .. " # ".. v:EntIndex(), SSE.xFont("!Agency FB@15#1"), pX, pY+2, Color(255,255,255), TEXT_ALIGN_CENTER)
                    end
                end
            end
    
            imgui.End3D2D()
        end
    end
    
    

    
end