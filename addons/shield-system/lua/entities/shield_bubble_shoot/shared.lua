ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Shield Bubble Shoot"
ENT.Author = "Joe + JackJack + Nvc"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Category = "Joe"
ENT.AutomaticFrameAdvance = true

function ENT:TestCollision(startpos, delta, isbox, extents, mask)
	local rad = self:GetRadius()
	local dist = startpos:DistToSqr(self:GetPos())

	return not (rad and dist < rad ^ 2 and bit.band(mask, CONTENTS_EMPTY) == 0)
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Radius")
end