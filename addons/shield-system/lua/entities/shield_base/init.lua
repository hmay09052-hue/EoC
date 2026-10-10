AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
util.PrecacheModel("models/jackjack/props/shieldgen.mdl")

function ENT:Initialize()
	self:SetModel("models/jackjack/props/shieldgen.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:SetModelScale(self.size)
	self:AddEFlags(EFL_DONTBLOCKLOS)
	self.phys = self:GetPhysicsObject()
	self.phys:EnableMotion(false)

	if (self.phys:IsValid()) then
		self.phys:Wake()
	end

	self:SetHealth(self.health)
	self.usecooldown = 0
	self.isgenerator = true
	SWRPShield.ents[self] = true
	self:SpawnEye()
end

function ENT:Use(ply, c)
	if self.usecooldown > CurTime() then return end
	local state = self:GetSequence()

	if state == 0 then
		self:OpenShield()
		self:EmitSound(self.ActivateSound or "buttons/button3.wav")
	elseif state == 3 then
		self:CloseShield()
		self:EmitSound(self.CloseSound or "buttons/combine_button_locked.wav")
	end
end

function ENT:Think()
	self:NextThink(CurTime())

	return true
end

function ENT:OnRemove()
	self:StopSound(self.RemoveSound or "ambient/machines/machine6.wav")

	if IsValid(self.shield) then
		self.shield:Remove()
	end

	self:RemoveEye()
	SWRPShield.ents[self] = nil
end

function ENT:OpenShield()
	self:ResetSequence(1)

	timer.Simple(1.95, function()
		if not IsValid(self) then return end
		self:EmitSound(self.StartOpening or "swrpshield/start.mp3")
	end)

	timer.Simple(self:SequenceDuration(1), function()
		if not IsValid(self) then return end
		if self.usecooldown > CurTime() then return end
		if self:GetSequence() ~= 1 then return end
		self:ResetSequence(3)

		if SWRPShield.shootoutofshield then
			self.shield = ents.Create("shield_bubble_shoot")
			self.shield:SetRadius(self.radius)
		else
			self.shield = ents.Create("shield_bubble")
		end

		self.shield:SetModel(self.shieldmodel)
		self.shield:SetPos(self:GetBonePosition(self:LookupBone("gen")))
		self.shield:Spawn()
		self.shield.gen = self
		self:EmitSound("ambient/machines/machine6.wav")
	end)
end

function ENT:SpawnEye()
	self.bullseye = ents.Create("npc_bullseye")
	self.bullseye:SetPos(self:GetBonePosition(self:LookupBone("gen")))
	self.bullseye:SetHealth(100)
	self.bullseye:SetParent(self)
	self.bullseye:Spawn()
end

function ENT:RemoveEye()
	if IsValid(self.bullseye) then
		self.bullseye:Remove()
	end
end

function ENT:SpawnFunction(ply, tr, ClassName)
	if (not tr.Hit) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * -1.5
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180
	local ent = ents.Create(ClassName)
	ent:SetPos(SpawnPos)
	ent:SetAngles(SpawnAng)
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:CloseShield()
	self:ResetSequence(2)
	self:StopSound(self.RemoveSound or "ambient/machines/machine6.wav")

	if IsValid(self.shield) then
		self.shield:Remove()
	end

	timer.Simple(self:SequenceDuration(2), function()
		if not IsValid(self) then return end
		self:ResetSequence(0)
	end)
end

function ENT:Destroyed()
	if self.destroyed then return end
	local effectdata = EffectData()
	effectdata:SetOrigin(self:GetBonePosition(self:LookupBone("gen")))
	util.Effect("HelicopterMegaBomb", effectdata)
	self:EmitSound("ambient/explosions/explode_7.wav")
	self:SetModel("models/jackjack/props/shieldgen_rekt.mdl")

	if IsValid(self.shield) then
		self.shield:Remove()
		self:StopSound(self.RemoveSound or "ambient/machines/machine6.wav")
		util.ScreenShake(self:GetPos(), 100, 100, 1, 200)
	end

	self:RemoveEye()
	self.usecooldown = CurTime() + self.disabledtime
	self.destroyed = true
end

function ENT:Repair()
	self:SetHealth(self.health)
	self:SetModel("models/jackjack/props/shieldgen.mdl")
	local effectdata = EffectData()
	effectdata:SetMagnitude(5)
	effectdata:SetScale(1)
	effectdata:SetNormal(self:GetUp():GetNormal())
	effectdata:SetRadius(1)
	effectdata:SetOrigin(self:GetPos() + Vector(0, 0, 20))
	util.Effect("Sparks", effectdata)
	self:SpawnEye()
	self.destroyed = false
end

function ENT:OnTakeDamage(dmginfo)
	if self.destroyed then return 0 end

	local tr = util.TraceLine({
		start = self:GetPos(),
		endpos = dmginfo:GetAttacker():GetPos(),
		filter = {self}
	})

	if IsValid(tr.Entity) and tr.Entity == self.shield then return 0 end
	local newhealth = self:Health() - dmginfo:GetDamage()
	self:SetHealth(newhealth)

	if newhealth <= 0 then
		self:Destroyed()

		timer.Simple(self.disabledtime, function()
			if IsValid(self) and self.destroyed then
				self:Repair()
			end
		end)
	end

	return 0
end