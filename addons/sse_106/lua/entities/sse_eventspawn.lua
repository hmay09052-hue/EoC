AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Eventspawnpoint"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true


if SERVER then
        
    function ENT:Initialize()

        self:SetModel( "models/hunter/plates/plate1x1.mdl" )
        self:DrawShadow( false )
        self:SetColor(Color(255,0,0))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    end

end
-- test

if CLIENT then

    function ENT:Draw()
        if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP then
            self:DrawModel() 
        end
    end

end


if SERVER then
    if SSE.Config.EventSpawn["Alternative"] then
        hook.Add( "PlayerSpawn", "SSE_EVENTSPAWN", function(ply)  
            
            timer.Simple(0, function() 
            
                local eventSpawns = ents.FindByClass("sse_eventspawn")

                if #eventSpawns > 0 then
                    ply:SetPos(eventSpawns[math.random(#eventSpawns)]:GetPos())
                end
            end)
        
        end)
    else 
        hook.Add("PlayerSelectSpawn", "SSE_EVENTSPAWN", function(ply)
            local eventSpawns = ents.FindByClass("sse_eventspawn")
        
            if #eventSpawns > 0 then
                return eventSpawns[math.random(#eventSpawns)]
            end
        end)
    end
end