AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Use(ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

	-- Spam-Schutz
	if (ply.BodymanNextClosetUse or 0) > CurTime() then return end
	ply.BodymanNextClosetUse = CurTime() + 1

	net.Start("bodyman_openmenu")
	net.Send(ply)

	self:EmitSound("doors/door1_move.wav", 70, math.random(75, 100))
end

function ENT:OnTakeDamage(dmginfo)
	if not BODYMAN.ClosetsCanBreak then return end

	self.ClosetHealth = (self.ClosetHealth or BODYMAN.ClosetHealth or 100) - dmginfo:GetDamage()

	if self.ClosetHealth <= 0 and not self.Destroyed then
		self.Destroyed = true

		local ed = EffectData()
		ed:SetOrigin(self:GetPos() + self:OBBCenter())
		util.Effect("Explosion", ed)

		SafeRemoveEntity(self)
	end
end
