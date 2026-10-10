AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Battlepad"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()

    self:SetModel(SSE.Config.Battlepad["Model"]  )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
    end
    self:PhysWake()
end


if CLIENT then
    function ENT:Draw()
        self:DrawModel()



        local imgui = SSE.Imgui

        local radarSize = SSE.Config.Battlepad["Size"] -- Half of the radar size (since the radar is square)
        
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
    
        if imgui.Entity3D2D(self, Vector(0, 0, 43), Angle(0, 90, 0), 0.1, 1000, 500) then
            -- Draw filled radar square
            draw.RoundedBox(0, -radarSize, -radarSize, radarSize * 2, radarSize * 2, SSE.Config.Battlepad["BackgroundColor"])
    
            -- Draw radar center
            --draw.RoundedBox(50, -5, -5, 10, 10, Color(0, 255, 0, 200))
    

            -- Draw radar border
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawOutlinedRect(-radarSize, -radarSize, radarSize * 2, radarSize * 2)


 
            -- Draw players on the radar
            for k, v in ipairs(ents.GetAll()) do
                local good = false
                local color = Color(255, 0, 0)
                if v:IsPlayer() or table.HasValue(SSE.Config.Battlepad["FriendlyEntities"], v:GetClass()) then 
                    good = true
                    color = Color(0, 255, 0)
                end

                if v:IsNPC() or v:IsNextBot() or table.HasValue(SSE.Config.Battlepad["EnemyEntities"], v:GetClass()) then 
                    good = true
                    color = Color(255, 0, 0)
                end

              

          
                if !good then continue end
          
                local pX, pY = WorldToRadar(v:GetPos())
    
                local name = v.PrintName or ""
                -- Ensure the player dot is drawn within radar boundaries
                if math.abs(pX) <= radarSize and math.abs(pY) <= radarSize then
                    draw.RoundedBox(50, pX - 5, pY - 5, 10, 10, color)

               
                end
            end
    
            local rX, rY = WorldToRadar(self:GetPos())
            draw.RoundedBox(50, rX-5,rY-5, 10, 10, Color(255,0,255) )

            
            imgui.End3D2D()
        end

    end

end





