AddCSLuaFile()
SWEP.Slot = 1
SWEP.SlotPos = 0
SWEP.UseHands = false
SWEP.Category = "Shields"
SWEP.ENT_CLASS = "shield_1"
SWEP.PrintName = "Shield Deployer Base"
SWEP.Author = "Joe"
SWEP.Purpose = "Deploy Shields"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.ViewModel = "models/jackjack/props/shieldgen.mdl"
SWEP.WorldModel = "models/jackjack/props/shieldgen.mdl"
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.cooldown = 0

function SWEP:Initialize()
	self:SetWeaponHoldType("slam")
	self.Owner.placingdown = false
end

function SWEP:PrimaryAttack()
	if self.cooldown > CurTime() then return end
	self.Owner.placingdown = true

	if SERVER then
		local owner = self.Owner
		local hitpos = owner:GetEyeTrace().HitPos
		if owner:GetPos():DistToSqr(hitpos) > 20000 then return end

		if not owner.personalshield or not IsValid(owner.personalshield) then
			owner.personalshield = ents.Create(self.ENT_CLASS)
			if (not owner.personalshield:IsValid()) then return end
			owner.personalshield:SetPos(hitpos)
			local ang = owner:GetAngles()
			ang.p = 0
			owner.personalshield:SetAngles(ang)
			owner.personalshield:Spawn()
			owner:EmitSound("plats/train_use1.wav")
		end
	end

	self.cooldown = CurTime() + 10
end

function SWEP:SecondaryAttack()
	self.Owner.placingdown = false

	if SERVER then
		local owner = self.Owner

		if owner.personalshield and IsValid(owner.personalshield) then
			SafeRemoveEntity(owner.personalshield)
			owner.personalshield = nil
		end
	end
end

if CLIENT then
	function SWEP:Think()
		local ply = self.Owner

		if IsValid(self.PreviewEnt) then
			if (self.Owner:GetPos():DistToSqr(ply:GetEyeTrace().HitPos) > 30000) or (ply.placingdown) then
				self.PreviewEnt:SetNoDraw(true)
			else
				self.PreviewEnt:SetNoDraw(false)
			end
		end

		if not IsValid(self.PreviewEnt) then
			self.PreviewEnt = ents.CreateClientProp("models/jackjack/props/shieldgen.mdl")

			if not IsValid(self.PreviewEnt) then
				self.PreviewEnt = nil

				return
			end

			self.PreviewEnt:SetModel("models/jackjack/props/shieldgen.mdl")
			self.PreviewEnt:SetPos(ply:GetEyeTrace().HitPos)
			self.PreviewEnt:PhysicsInit(SOLID_VPHYSICS)
			self.PreviewEnt:SetNotSolid(true)
			self.PreviewEnt:SetRenderMode(RENDERMODE_TRANSALPHA)
			self.PreviewEnt:SetMoveType(MOVETYPE_NONE)
			self.PreviewEnt:Spawn()
			self.PreviewEnt:SetColor(Color(8, 68, 124, 200))
			self.PreviewEnt:SetMaterial("models/debug/debugwhite")
		else
			if IsValid(self.PreviewEnt) then
				self.PreviewEnt:SetPos(ply:GetEyeTrace().HitPos)
				local ang = ply:GetAngles()
				ang.p = 0
				self.PreviewEnt:SetAngles(ang)
			end
		end
	end

	function SWEP:Holster()
		timer.Simple(0.1, function()
			if IsValid(self.PreviewEnt) then
				self.PreviewEnt:Remove()
			end
		end)
	end

	function SWEP:OnRemove()
		if IsValid(self.PreviewEnt) then
			self.PreviewEnt:Remove()
		end
	end

	SWEP.ViewModelPos = Vector(30.49, 80, -42.371)
	SWEP.ViewModelAng = Vector(0, 0, 0)

	function SWEP:GetViewModelPosition(EyePos, EyeAng)
		local Mul = 0.8
		local Offset = self.ViewModelPos

		if (self.ViewModelAng) then
			EyeAng = EyeAng * 1
			EyeAng:RotateAroundAxis(EyeAng:Right(), self.ViewModelAng.x * Mul)
			EyeAng:RotateAroundAxis(EyeAng:Up(), self.ViewModelAng.y * Mul)
			EyeAng:RotateAroundAxis(EyeAng:Forward(), self.ViewModelAng.z * Mul)
		end

		local Right = EyeAng:Right()
		local Up = EyeAng:Up()
		local Forward = EyeAng:Forward()
		EyePos = EyePos + Offset.x * Right * Mul
		EyePos = EyePos + Offset.y * Forward * Mul
		EyePos = EyePos + Offset.z * Up * Mul

		return EyePos, EyeAng
	end

	local WorldModel = ClientsideModel(SWEP.WorldModel)
	-- Settings...
	WorldModel:SetSkin(1)
	WorldModel:SetModelScale(0.25)
	WorldModel:SetNoDraw(true)

	function SWEP:DrawWorldModel()
		local _Owner = self:GetOwner()

		if (IsValid(_Owner)) then
			-- Specify a good position
			local offsetVec = Vector(5, -7, -1)
			local offsetAng = Angle(10, 0, 200)
			local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
			if not boneid then return end
			local matrix = _Owner:GetBoneMatrix(boneid)
			if not matrix then return end
			local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
			WorldModel:SetPos(newPos)
			WorldModel:SetAngles(newAng)
			WorldModel:SetupBones()
		else
			WorldModel:SetPos(self:GetPos())
			WorldModel:SetAngles(self:GetAngles())
		end

		WorldModel:DrawModel()
	end
end