AddCSLuaFile()

SWEP.Base   = "weapon_summes_npcbase"

SWEP.PrintName = "#NPC Magna"
SWEP.Spawnable = true
SWEP.Author = "Summe"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/v_357.mdl"
SWEP.WorldModel = "models/tfa/comm/gg/prp_magna_guard_weapon_combined.mdl"
SWEP.Weight = 3



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
	
end

if CLIENT then

    function PrintBones( entity )
        for i = 0, entity:GetBoneCount() - 1 do
            print( i, entity:GetBoneName( i ) )
        end
    end

    local mat1 = Material("sprites/light_glow02_add")
	local mat2 = Material("particle/particle_glow_04")

	local worldSprites = {
		[1] = {
			mat = mat1,
			color = Color(255,50,193),
			x = 35,
			y = 0,
			z = 0,
			width = 50,
			height = 50,
		},
		[2] = {
			mat = mat1,
			color = Color(255,50,193),
			x = -35,
			y = 0,
			z = 0,
			width = 50,
			height = 50,
		},
		[3] = {
			mat = mat2,
			color = Color(255,255,255),
			x = 40,
			y = 0,
			z = 0,
			width = 10,
			height = 10,
		},
		[4] = {
			mat = mat2,
			color = Color(255,255,255),
			x = -40,
			y = 0,
			z = 0,
			width = 10,
			height = 10,
		},
		[5] = {
			mat = mat2,
			color = Color(255,255,255),
			x = 30,
			y = 0,
			z = 0,
			width = 10,
			height = 10,
		},
		[6] = {
			mat = mat2,
			color = Color(255,255,255),
			x = -30,
			y = 0,
			z = 0,
			width = 10,
			height = 10,
		},
		[7] = {
			mat = mat2,
			color = Color(255,255,255),
			x = 35,
			y = 0,
			z = 0,
			width = 10,
			height = 10,
		},
		[8] = {
			mat = mat2,
			color = Color(255,255,255),
			x = -35,
			y = 0,
			z = 0,
			width = 10,
			height = 10,
		},
	}

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

			local pos, ang = self.Model:GetPos(), self.Model:GetAngles()

			for k, v in pairs(worldSprites) do
				local drawpos = pos + ang:Forward() * v.x + ang:Right() * v.y + ang:Up() * v.z
				render.SetMaterial(v.mat)
				render.DrawSprite(drawpos, v.width, v.height, v.color)
			end
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