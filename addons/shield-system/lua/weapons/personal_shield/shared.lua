AddCSLuaFile()
SWEP.Slot = 2
SWEP.SlotPos = 2
SWEP.UseHands = true
SWEP.Category = "Shields"
SWEP.PrintName = "Personal Shield Base"
SWEP.Author = "Joe"
SWEP.Purpose = ""
SWEP.ViewModelFOV = 800
SWEP.ViewModelFlip = false
SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.health = SWRPShield.personalshieldhp
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

function SWEP:PrimaryAttack()
	if not SERVER then return end
	local ply = self:GetOwner()
	if not IsValid(ply) then return end
	if ply.per_shieldcooldown and ply.per_shieldcooldown >= CurTime() then return end

	if IsValid(ply.per_shield) then
		self:CloseShield()
	else
		self:OpenShield()
		ply.per_shieldcooldown = CurTime() + 1
	end
end

function SWEP:OpenShield()
	local ply = self:GetOwner()
	local ent = ents.Create("shield_bubble_personal")
	ent:SetModel("models/jackjack/props/fullsphere.mdl")
	ent:SetRadius(45)
	ent:SetShieldOwner(ply)
	ent:SetPos(ply:GetPos() + ply:OBBCenter() + Vector(0, 0, 10))
	ent:SetHealth(self.health)
	ent:Spawn()
	ply:EmitSound("hl1/fvox/activated.wav")
	ply.per_shield = ent
end

function SWEP:CloseShield()
	local ply = self:GetOwner()
	ply.per_shield:Remove()
	ply.per_shield = nil
	ply:EmitSound("hl1/fvox/deactivated.wav")
	ply.per_shieldcooldown = CurTime() + SWRPShield.personalshieldcooldown
end

function SWEP:SecondaryAttack()
	if IsValid(self:GetOwner().per_shield) then
		self:CloseShield()
	end
end

function SWEP:Reload()
end

function SWEP:Initialize()
	self:SetHoldType("normal")
	self.health = SWRPShield.personalshieldhp
end