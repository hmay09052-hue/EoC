AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Decoy Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true
ENT.Zombies = {}
ENT.VJExists = false
ENT.HasShot = false
DEFINE_BASECLASS("arccw_kraken_nade_base")

function ENT:OnRemove() end
function ENT:PhysicsUpdate() end

function ENT:PhysicsCollide(data, phys)
	if self.Defused or data.Speed <= 60 then return end
	
	local tgt = data.HitEntity
	if IsValid(tgt) and not tgt:IsWorld() and (self.NextHit or 0) < CurTime() then
		self.NextHit = CurTime() + 0.1
		local dmginfo = DamageInfo()
		dmginfo:SetDamageType(DMG_GENERIC)
		dmginfo:SetDamage(2)
		dmginfo:SetAttacker(self:GetOwner())
		dmginfo:SetInflictor(self)
		dmginfo:SetDamageForce(data.OurOldVelocity * 0.5)
		tgt:TakeDamageInfo(dmginfo)
	end

	self:EmitSound("ArcCW_Kraken.Explosives.Bounce")
	phys:ApplyForceCenter((data.OurOldVelocity - 2 * data.OurOldVelocity:Dot(data.HitNormal) * data.HitNormal) * 0.25)
end
