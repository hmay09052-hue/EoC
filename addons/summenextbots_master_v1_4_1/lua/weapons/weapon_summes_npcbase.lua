AddCSLuaFile()

SWEP.PrintName = "#HL2_357"
SWEP.Spawnable = true
SWEP.Author = "Summe"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/v_357.mdl"
--SWEP.WorldModel = "models/kuro/sw_battlefront/weapons/e5c_blaster.mdl"
SWEP.Weight = 3

SWEP.NextShoot = 3

SWEP.Delay_ = 0

SWEP.Primary = {
	Ammo = "SMG1",
	ClipSize = SWEP.ClipSize or 40,
	DefaultClip = 20,
	Automatic = true
}

SWEP.Secondary = {
	Ammo = "None",
	ClipSize = -1,
	DefaultClip = -1,
}

function SWEP:Initialize()
	self:SetHoldType("smg")
	
end

function SWEP:CanPrimaryAttack()
	return CurTime()>=self:GetNextPrimaryFire() and self:Clip1()>0
end

function SWEP:CanSecondaryAttack()
	return false
end

local MAX_TRACE_LENGTH	= 56756
local vec3_origin		= vector_origin

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	
	local owner = self:GetOwner()

	local enemy = owner:GetEnemy()
	local headBone = enemy:LookupBone("ValveBiped.Bip01_Spine") or 0

	local weaponPos = owner:GetPos() + Vector(0, 0, 55)
	local enemyPos = enemy:GetBonePosition(headBone) or enemy:GetPos()

	local prof = (owner.Proficiency or 1) * 100

	enemyPos = Vector(math.random(enemyPos.x - prof, enemyPos.x + prof), math.random(enemyPos.y - prof, enemyPos.y + prof), enemyPos.z)

	math.randomseed(CurTime() * 1000)

	local direction = enemyPos - weaponPos

	local spread = self.Spread or 0
	
	self:FireBullets({
		Num = self.Bullets or 1,
		Src = weaponPos,
		Dir = direction:GetNormalized(),
		Spread = Vector(spread, spread, 0),
		Distance = MAX_TRACE_LENGTH,
		AmmoType = self:GetPrimaryAmmoType(),
		Damage = self.Damage or 10,
		Force = 0,
		Attacker = owner,
		TracerName = self.Tracer or "rw_sw_laser_red",
		Callback = self.BulletCallback,
	})
	
	self:EmitSound(self.Sound or "w/e5.wav", 85, 100, 1, CHAN_WEAPON)
	
	self:SetClip1(self.ClipSize - 1)
	self:SetNextPrimaryFire(CurTime()+self.NextShoot)
	self:SetLastShootTime()
end

function SWEP:BulletCallback(tr, dmgInfo)

	local shootEffect = {}

	local effect = EffectData()
	effect:SetEntity(self)
	effect:SetStart(tr.HitPos)
	effect:SetOrigin(tr.HitPos)
	effect:SetNormal(tr.HitNormal)
	effect:SetAngles(tr.HitNormal:Angle())
	effect:SetScale(1)
	effect:SetRadius(4)
	effect:SetMagnitude(1)
	effect:SetAttachment(1)
	util.Effect(self.ImpactEffect or "rw_sw_impact_red", effect)
end

function SWEP:SecondaryAttack()
	if !self:CanSecondaryAttack() then return end
end

function SWEP:Reload()
	//self:EmitSound("Weapon_357.NPC_Reload")
	self:SetClip1(self.Primary.ClipSize)
end

if CLIENT then
	function SWEP:DrawWorldModel()

		if not self.WorldModel then return end

		if not IsValid(self.Model) then
			self.Model = ClientsideModel(self.WorldModel)
		end

		local _Owner = self:GetOwner()

		if (IsValid(_Owner)) then
            -- Specify a good position
			local offsetVec = Vector(5, -2.7, 0)
			local offsetAng = Angle(180, 180, 0)
			
			local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
			if !boneid then return end

			local matrix = _Owner:GetBoneMatrix(boneid)
			if !matrix then return end

			local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())

			self.Model:SetPos(newPos)
			self.Model:SetAngles(newAng)

            self.Model:SetupBones()
		else
			self.Model:SetPos(self:GetPos())
			self.Model:SetAngles(self:GetAngles())
		end

		self.Model:DrawModel()
	end

	function SWEP:OnRemove()
		if not IsValid(self.Model) then return end
		self.Model:Remove()
	end
end