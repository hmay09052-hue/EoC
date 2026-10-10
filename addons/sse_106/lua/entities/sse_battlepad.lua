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
            local UI = SSE.UI
            UI.WorldRadar(radarSize, UI.Holo(), SSE.Config.Battlepad["BackgroundColor"], SSE.Config.Battlepad["Title"] or "Gefechtslage", self:EntIndex())

            -- Verbündete (Spieler, freundliche Fahrzeuge) und Feinde (NPCs, Nextbots, feindliche Fahrzeuge)
            local friends, enemies = 0, 0
            for k, v in ipairs(ents.GetAll()) do
                local good = false
                local enemy = false
                if v:IsPlayer() or table.HasValue(SSE.Config.Battlepad["FriendlyEntities"], v:GetClass()) then 
                    good = true
                end

                if v:IsNPC() or v:IsNextBot() or table.HasValue(SSE.Config.Battlepad["EnemyEntities"], v:GetClass()) then 
                    good = true
                    enemy = true
                end

                local pX, pY = WorldToRadar(v:GetPos())
                if good and math.abs(pX) <= radarSize and math.abs(pY) <= radarSize then
                    UI.WorldBlip(pX, pY, enemy and UI.col.red or UI.col.green, 6)
                    if enemy then enemies = enemies + 1 else friends = friends + 1 end
                end
            end
    
            local rX, rY = WorldToRadar(self:GetPos())
            UI.WorldBlip(rX, rY, UI.Accent(), 8)

            -- Legende
            local ly = radarSize + 16
            UI.Circle(-radarSize + 10, ly + 14, 7, UI.col.green, 16)
            UI.Text("VERBÜNDET  " .. friends, "sse.world.small", -radarSize + 26, ly, UI.col.text)
            UI.Circle(-radarSize + 230, ly + 14, 7, UI.col.red, 16)
            UI.Text("FEIND  " .. enemies, "sse.world.small", -radarSize + 246, ly, UI.col.text)
            UI.Circle(radarSize - UI.TextSize("POSITION", "sse.world.small") - 16, ly + 14, 7, UI.Accent(), 16)
            UI.Text("POSITION", "sse.world.small", radarSize, ly, UI.col.text, TEXT_ALIGN_RIGHT)

            imgui.End3D2D()
        end

    end

end





