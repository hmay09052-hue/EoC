include('shared.lua')

function ENT:Initialize()
	self.StartTime = CurTime()
	self.height = 0
	self.buildtime = 1.5
	self.isshield = true
end

function ENT:Draw()
	if CurTime() >= self.StartTime + self.buildtime then
		self:DrawModel()
	else
		local min,max = self:GetRenderBounds()
		local center = self:GetPos() + self:OBBCenter()
		self.height = ( max.z / self.buildtime ) * ( CurTime() - self.StartTime )
		local normal = Vector(0,0,1)
		local pos = min + self:LocalToWorld(Vector(0, 0,max.z - self.height))
		local distance = normal:Dot(pos)
		
		render.EnableClipping(true)
		render.PushCustomClipPlane(normal, distance)
		self:DrawModel()
		render.PopCustomClipPlane()
	end
end