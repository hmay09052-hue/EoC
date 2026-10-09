AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Lightswitch"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true

function ENT:Initialize()

    self:SetModel( SSE.Config.Lightswitch["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
    self:SetSolid( SOLID_VPHYSICS )         -- Toolbox



    self.SSE_HUDName = SSE.Config.Lightswitch["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end

if CLIENT then
    net.Receive("SSE_RedownloadLightmaps", function()
        render.RedownloadAllLightmaps(SSE.Config.Lightswitch["RenderModels"], SSE.Config.Lightswitch["RenderModels"])
    end)
    
end


if SERVER then
        -- Function to toggle all lights on or off

    util.AddNetworkString("SSE_RedownloadLightmaps")

    SSE_LIGHTS_STATUS = true
    local function ToggleAllLights(state)
        -- Define a list of light entity class names
        local lightClasses = {
            "light",
            "light_spot",
            "gmod_light",
            "env_projectedtexture",
            "point_tesla",
            "prop_dynamic_light",
            "spotlight_end",
            "point_spotlight",
            "light_dynamic",
        }

        if table.HasValue(SSE.Config.Lightswitch["EngineLightstyle"], game.GetMap() ) then
           
            if state then
                engine.LightStyle(0, "m")
            else
                engine.LightStyle(0, "a")
            end
            net.Start("SSE_RedownloadLightmaps")
            net.Broadcast()

        end

        -- Iterate over all entities on the map
        for _, ent in pairs(ents.GetAll()) do
            -- Check if the entity is a light by comparing its class name
            if table.HasValue(lightClasses, ent:GetClass()) then
                -- Set the light state based on the input parameter
                if state then
                    ent:Fire("TurnOn")
                else
                    ent:Fire("TurnOff")
                end
       
            end
        end
    end




    -- Öffentliche Schnittstelle (z. B. für die Schiffstechnik / ShipTech)
    SSE = SSE or {}
    function SSE.SetLights(state)
        state = state and true or false
        if SSE_LIGHTS_STATUS == state then return end
        ToggleAllLights(state)
        SSE_LIGHTS_STATUS = state
    end
    function SSE.GetLights()
        return SSE_LIGHTS_STATUS
    end

    function ENT:Use( activator, caller )

        -- Andere Addons können das Einschalten verhindern (z. B. bei Stromausfall)
        if not SSE_LIGHTS_STATUS and hook.Run("SSE_CanTurnLightsOn", activator, self) == false then
            activator:EmitSound("buttons/button10.wav")
            return
        end

        if CurTime() - (self.LastUseTime or 0) >= SSE.Config.Lightswitch["Delay"] then
            ToggleAllLights(not SSE_LIGHTS_STATUS)
            SSE_LIGHTS_STATUS = not SSE_LIGHTS_STATUS
            self.LastUseTime = CurTime()

            -- Emit Electric Shutdown Sound 
            activator:EmitSound("ambient/levels/labs/electric_explosion1.wav")

        else
            -- Emit Error Sound
            activator:EmitSound("buttons/button10.wav")
        end

    end


end

