include('shared.lua')

function ENT:Initialize()
	self.laserend = nil
	SWRPShield.ents[self] = true
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:OnRemove()
	SWRPShield.ents[self] = nil
end