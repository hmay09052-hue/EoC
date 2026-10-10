ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Kleiderschrank"
ENT.Author = "Echoes of Clones"
ENT.Purpose = "Öffnet das Aussehen-Menü"
ENT.Category = "Echoes of Clones"

ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:Initialize()
	if CLIENT then return end

	local mdl = BODYMAN and BODYMAN.ClosetModel or "models/props_c17/FurnitureDresser001a.mdl"
	if not util.IsValidModel(mdl) then
		mdl = BODYMAN and BODYMAN.ClosetFallbackModel or "models/props_c17/FurnitureDresser001a.mdl"
	end

	self:SetModel(mdl)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(50)
		phys:Wake()
	end

	self.ClosetHealth = BODYMAN and BODYMAN.ClosetHealth or 100
end
