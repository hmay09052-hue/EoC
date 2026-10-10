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
    self.ThinkCooldown = 0

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    self:SetAngles(self:GetAngles(math.random(0, 50),math.random(0, 50),math.random(0, 50)))

    self:SetHealth(1000)
    self:SetMaxHealth(1000)
   
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("HelicopterMegaBomb", effectdata)
end

function ENT:Think()
    if self.ThinkCooldown >= CurTime() then return end

    self.ThinkCooldown = CurTime() + 10

    if #self.NPCList < 1 then return end

    local npcClass = table.Random(self.NPCList)
    table.RemoveByValue(self.NPCList, npcClass)

    local droid = ents.Create(npcClass)
    droid:SetPos(self:GetPos() + Vector(math.random(0, 30), math.random(0, 30), -350))
    droid:Spawn()
end

function ENT:OnTakeDamage( dmg )
	self:TakePhysicsDamage( dmg )
    if ( self:Health() <= 0 ) then return end
    self:SetHealth( math.Clamp( self:Health() - dmg:GetDamage(), 0, self:GetMaxHealth() ) )

	if ( self:Health() <= 0 ) then
        local BoomBoom4 = ents.Create( "env_explosion" )
        BoomBoom4:SetKeyValue( "spawnflags", 144 )
        BoomBoom4:SetKeyValue( "iMagnitude", 50 )
        BoomBoom4:SetKeyValue( "iRadiusOverride", 512 )
        BoomBoom4:SetPos( self:GetPos() )
        BoomBoom4:Spawn()
        BoomBoom4:Fire( "explode", "", 0 )

		self:Remove()
	end
end