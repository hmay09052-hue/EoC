AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/jackjack/props/fullsphere.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetUseType(SIMPLE_USE)
	self:SetCollisionGroup(20)
	self:AddEFlags(33554432)
	self.phys = self:GetPhysicsObject()
	self.phys:EnableMotion(false)

	if (self.phys:IsValid()) then
		self.phys:Wake()
	end

	self:SetColor(Color(0, 161, 255, 255))
	self.ispersonalshield = true
	self:EnableCustomCollisions(true)
	self:DrawShadow(false)
end

function ENT:Think()
	local ply = self:GetShieldOwner()

	if not IsValid(ply) or not ply:Alive() then
		self:Remove()

		return
	end

	self:SetPos(ply:GetPos() + ply:OBBCenter() + Vector(0, 0, 10))
	self:NextThink(CurTime())

	return true
end

function ENT:OnTakeDamage(dmginfo)
	self:SetHealth(self:Health() - dmginfo:GetDamage())

	if self:Health() <= 0 then
		local ply = self:GetShieldOwner()
		if not IsValid(ply) or not ply:Alive() then return end
		ply.per_shieldcooldown = CurTime() + SWRPShield.personalshieldcooldown
		self:Remove()

		return
	end

	return false
end