AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetUseType(SIMPLE_USE)
	self:SetCollisionGroup(2)
	self:AddEFlags(33554432)
	self.phys = self:GetPhysicsObject()
	self.phys:EnableMotion(false)

	if (self.phys:IsValid()) then
		self.phys:Wake()
	end

	self:SetColor(Color(0, 161, 255, 255))
	self.isshield = true
	self:DrawShadow(false)
	self:EnableCustomCollisions(true)
end