AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.
include('shared.lua')
function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
	self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
	self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
	self:SetUseType(SIMPLE_USE)

	self:SetCollisionGroup(2) -- 15
	self:AddEFlags(33554432) -- make NPC see through it

	self.phys = self:GetPhysicsObject()
	self.phys:EnableMotion(false)
	if (self.phys:IsValid()) then
		self.phys:Wake()
	end
	
	self:SetColor(Color(0, 161, 255, 255))
	self.isshield = true
	self:DrawShadow(false)
end