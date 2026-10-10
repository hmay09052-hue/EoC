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

	self:SetModel("models/props_borealis/bluebarrel001.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    self:SetPos(self:GetPos() + Vector(0, 0, 5000))

end

function ENT:PhysicsUpdate( phys )
    phys:ApplyForceCenter( Vector( 0, 0, -100000000 ) )
end

function ENT:PhysicsCollide( data, phys )
    if 20 < data.Speed and 0.25 < data.DeltaTime then
        self:SetLanded(true)

        local BoomBoom4 = ents.Create("env_explosion")
        BoomBoom4:SetKeyValue("spawnflags", 144)
        BoomBoom4:SetKeyValue("iMagnitude", 0)
        BoomBoom4:SetKeyValue("iRadiusOverride", 10)
        BoomBoom4:SetPos(self:GetPos())
        BoomBoom4:Spawn()
        BoomBoom4:Fire("explode", "", 0)

        self:SetPos(self:GetPos() + Vector(0, 0, -45))

        local pod = ents.Create("summe_dispenser_landed")
        pod:SetPos(self:GetPos())
        pod.NPCList = self.NPCList
        pod:Spawn()
        pod:SetModel(self:GetModel())
        pod:SetMaxHealth(self:GetMaxHealth())
        pod:SetHealth(self:Health())

        self:Remove()
    end
end


--[[function ENT:Think()

    if not self:GetLanded() then
        local velocity = self:GetVelocity()
        velocity = velocity:LengthSqr()

        if velocity > 35521500 then return end

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        self:SetLanded(true)

        local BoomBoom4 = ents.Create("env_explosion")
        BoomBoom4:SetKeyValue("spawnflags", 144)
        BoomBoom4:SetKeyValue("iMagnitude", 0)
        BoomBoom4:SetKeyValue("iRadiusOverride", 10)
        BoomBoom4:SetPos(self:GetPos())
        BoomBoom4:Spawn()
        BoomBoom4:Fire("explode", "", 0)

        local pod = ents.Create("summe_dispenser_landed")
        pod:SetPos(self:GetPos())
        pod.NPCList = self.NPCList
        pod:Spawn()
        pod:SetModel(self:GetModel())
        pod:SetMaxHealth(self:GetMaxHealth())
        pod:SetHealth(self:Health())

        self:Remove()
    end
end]]--