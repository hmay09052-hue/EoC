AddCSLuaFile()

SWEP.Base = "weapon_lscs"
DEFINE_BASECLASS( "weapon_lscs" )

SWEP.Category			= "[LSCS]"
SWEP.PrintName		= "Asajj's Lichtschwert"
SWEP.Author			= "Amin"

SWEP.Slot				= 0
SWEP.SlotPos			= 3

SWEP.Spawnable		= true
SWEP.AdminOnly		= false

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables( self )

	if SERVER then
		self:SetHiltR("common")
		--self:SetHiltL("vibrosword")

		self:SetHiltR("commonr")

		self:SetBladeR("rubin")
		--self:SetBladeL("nanoparticles")

		self:SetBladeL("rubin")

		self:SetStance("butterfly") 
	end
end


if CLIENT then return end -- NUR CLIENT SIDE BELOW

function SWEP:ForcePowersGive( ply )
	ply:lscsWipeInventory() 

	-- give forcepowers:
	ply:lscsAddInventory( "item_force_jump", true )
	ply:lscsAddInventory( "item_force_pull", true )
	ply:lscsAddInventory( "item_force_push", true )
	ply:lscsAddInventory( "item_force_throw", true )
	--ply:lscsAddInventory( "item_force_lightning", true)

end

function SWEP:ForcePowersRemove( ply )
	ply:lscsWipeInventory()
end

function SWEP:Equip( newOwner ) 
	BaseClass.Equip( self, newOwner ) 

	if not IsValid( newOwner ) then return end

	self:ForcePowersGive( newOwner )
end

function SWEP:OnDrop()
	BaseClass.OnDrop( self )

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	self:ForcePowersRemove( ply )
end

function SWEP:OnRemove()
	BaseClass.OnRemove( self )

	local ply = self:GetOwner()

	if not IsValid( ply ) then return end

	self:ForcePowersRemove( ply )
end

