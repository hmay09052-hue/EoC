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

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

-- FUNCTION
-- Initialize the base entity
--
function ENT:Initialize()
	self.SummeNextbot = true

	self:CheckForNav()

	self:SetModel(self.Model)

	if self.Weapon and self.Weapon ~= "" then
    	self:SetWeapon(self.Weapon)
	end

	if self.Scale then
		self:SetModelScale(self.Scale, 0)
	end

	self:SetHealth(self.HP)
	self:SetMaxHealth(self.HP)

	self:SetFOV(130)

	self:DrawShadow(false)

	self.loco:SetStepHeight(30)

	self:SetPos(self:GetPos() + Vector(0, 0, 100))

	self.HeadPosZ = self:OBBMaxs().z
	self:OnNPCSpawn()
end

-- FUNCTION/HOOK
-- Gets called after the nextbot is spawned and initialized, to override things etc.
--
function ENT:OnNPCSpawn()
end

-- FUNCTION
-- Checks whether the map has a valid navmesh
--
function ENT:CheckForNav()
	if not SummeNextbots.NavMap and SummeNextbots.Config.DespawnIfNoNavmap then
		self:Remove()
		for k, v in pairs(player.GetAll()) do
			if not v:IsAdmin() then continue end
			SummeLibrary:Chat(v, "nextbots", string.format("No navmap for %s was found.", game.GetMap()))
		end
	end
end


-- FUNCTION
-- Internal function to sync animations etc.
--
function ENT:BodyUpdate()
    self:FrameAdvance()
end

-- FUNCTION/HOOK
-- Gets called every three seconds
--
function ENT:EveryThreeSeconds()
end

include("actions.lua")
include("weapons.lua")
include("enemies.lua")
include("movement.lua")