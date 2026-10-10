AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Broadcast Console"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true


function ENT:Initialize()

    self:SetModel( SSE.Config.Broadcast["Model"] )
    self:SetMoveType( MOVETYPE_VPHYSICS )   
    self:SetSolid( SOLID_VPHYSICS )       



    self.SSE_HUDName = SSE.Config.Broadcast["HUDName"]

 
    if SERVER then 
        self:PhysicsInit( SOLID_VPHYSICS ) 
        self:SetUseType( SIMPLE_USE )
    end
    self:PhysWake()
end

if SERVER then

    function ENT:Use( activator, caller )

        if not IsValid(activator) or not activator:IsPlayer() then return end

        if activator:GetPos():DistToSqr(self:GetPos()) > 10000 then return end

        SSE_SetBroadcast(activator, !SSE_GetBroadcast(activator))
    end
end



if CLIENT then

    function ENT:Draw()
        self.BaseClass.Draw(self) 
    end

    net.Receive("SSE_Broadcast_PlaySound", function(len)
        surface.PlaySound(SSE.Config.Broadcast["Sound"])
    end)

end


if SERVER then
    util.AddNetworkString("SSE_BROADCAST_PlaySound")
end

function SSE_GetBroadcast(ply)
    return ply.SSE_BROADCAST or false
end

function SSE_SetBroadcast(ply, val)

    if not IsValid(ply) or not ply:IsPlayer() then return end

    if SERVER then
        if val then
            ply:ChatPrint("*** "..SSE.Config.Broadcast["Enabled"])

            if VoiceBox and VoiceBox.FX then
                ply:AddVoiceFX("PASystemLoud")
            end
            
            ply.SSE_BROADCAST = true

            net.Start("SSE_BROADCAST_PlaySound")
            net.Broadcast()
        else
            ply:ChatPrint("*** "..SSE.Config.Broadcast["Disabled"])

            ply.SSE_BROADCAST = false

            if VoiceBox and VoiceBox.FX then
                ply:RemoveVoiceFX("PASystemLoud")
            end

            net.Start("SSE_BROADCAST_PlaySound")
            net.Broadcast()
        end


        
    end

end



if SERVER then
    
    hook.Add("PlayerCanHearPlayersVoice", "SSE_BROADCAST_PlayerCanHearPlayersVoice", function(listener, talker)
        if SSE_GetBroadcast(talker) and listener ~= talker then
            return true
        end
    end)
end