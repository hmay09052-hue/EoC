--[[
   _____ _    _ __  __ __  __ ______                   
  / ____| |  | |  \/  |  \/  |  ____|                  
 | (___ | |  | | \  / | \  / | |__                     
  \___ \| |  | | |\/| | |\/| |  __|                    
  ____) | |__| | |  | | |  | | |____                   
 |_____/_\____/|_| _|_|_|__|_|______|___ _______ _____ 
 | \ | |  ____\ \ / /__   __|  _ \ / __ \__   __/ ____|
 |  \| | |__   \ V /   | |  | |_) | |  | | | | | (___  
 | . ` |  __|   > <    | |  |  _ <| |  | | | |  \___ \ 
 | |\  | |____ / . \   | |  | |_) | |__| | | |  ____) |
 |_| \_|______/_/ \_\  |_|  |____/ \____/  |_| |_____/ 
                                                       
    Created by Summe: https://steamcommunity.com/id/DerSumme/ 
    Purchased content: https://discord.gg/k6YdMwj9w2
]]--

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
 
include("shared.lua")

function ENT:Initialize()
 
    self:SetModel("models/summe/drochclass/pod.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    self:SetPos(self:GetPos() + Vector(0, 0, 10000))
    self:SetLanded(false)
    self.NextParticleTime = CurTime()
end

function ENT:Think()
    if self:GetLanded() then
        local ents_ = ents.FindInSphere(self.TargetPos, 20)
        if table.HasValue(ents_, self) then
            local pod = ents.Create("summe_boarding_pod_landed")
            pod:SetPos(self:GetPos())
            pod:SetAngles(self:GetAngles())
            pod.NPCList = self.NPCList or {}

            self:Remove()

            pod:Spawn()
            return 
        end
        self:SetPos(self:GetPos() + Vector(0, 0, -10))
        self:EmitSound("summe/officer_boost/drill.mp3", 140, 100, 1, CHAN_AUTO)

        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        util.Effect("ManhackSparks", effectdata)
    else
        -- Flying effects
        if CurTime() > self.NextParticleTime then
            local effectdata = EffectData()
            effectdata:SetOrigin(self:GetPos() + self:GetForward() * -100)
            util.Effect("cball_explode", effectdata)
            
            self:EmitSound("ambient/wind/wind_hit3.wav", 75, 100, 1, CHAN_AUTO)
            self.NextParticleTime = CurTime() + 0.1
        end
    end

    self:NextThink(CurTime())
    return true
end

function ENT:PhysicsCollide(data, phys)
    if 20 < data.Speed and 0.25 < data.DeltaTime then

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        self:SetLanded(true)
        self:EmitSound("phx/explode05.wav", 140, 100, 1, CHAN_AUTO)

        -- Improved landing effects
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        util.Effect("HelicopterMegaBomb", effectdata)

        local explosion = ents.Create("env_explosion")
        explosion:SetPos(self:GetPos())
        explosion:SetKeyValue("iMagnitude", "100")
        explosion:Spawn()
        explosion:Fire("Explode", 0, 0)
        explosion:EmitSound("ambient/explosions/explode_4.wav", 140, 100, 1, CHAN_AUTO)
    end
end

function ENT:PhysicsUpdate(phys)
    if not self:GetLanded() then
        phys:ApplyForceCenter(Vector(0, 0, -50000)) -- Adjust force as needed for a more dramatic effect

        -- Trailing effects during fall
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        util.Effect("cball_explode", effectdata)
    end
end
