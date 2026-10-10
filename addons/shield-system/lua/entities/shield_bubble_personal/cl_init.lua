include('shared.lua')

function ENT:Initialize()
	self.StartTime = CurTime()
	self.height = 0
	self.buildtime = 0.75
	self.isshield = true
end

function ENT:Draw()
	local hp = self:Health() / SWRPShield.personalshieldhp
	self:SetColor(Color(255 * (1 - hp), 161 * hp, 255 * hp, 255))

	if CurTime() >= self.StartTime + self.buildtime then
		self:DrawModel()
	else
		local min, max = self:GetRenderBounds()
		self.height = (max.z * 2.5 / self.buildtime) * (CurTime() - self.StartTime)
		local normal = Vector(0, 0, -1)
		local pos = min + self:LocalToWorld(Vector(0, 0, self.height))
		local distance = normal:Dot(pos)
		render.EnableClipping(true)
		render.PushCustomClipPlane(normal, distance)
		self:DrawModel()
		render.PopCustomClipPlane()
	end
end

function ENT:Think()
	local ply = self:GetShieldOwner()
	if not IsValid(ply) or not ply:Alive() then return end
	self:SetPos(ply:GetPos() + ply:OBBCenter() + Vector(0, 0, 10))
	self:SetNextClientThink(CurTime())

	return true
end