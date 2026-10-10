AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
include("shared.lua")

ENT.SpawnNormalOffset = 80
local hatch = true

function ENT:OnSpawn( PObj )
	PObj:SetMass( 1000 )

	self:AddDriverSeat( Vector(75, 0, -31), Angle(0,-90,0) )

	local seat_bl = self:AddPassengerSeat( Vector( -1.35, 33.35, -33.35 ), Angle(0,-135,0) )
	local seat_br = self:AddPassengerSeat( Vector( -1.35, -33.35, -33.35 ), Angle(0,-45,0) ) 
	local seat_fl = self:AddPassengerSeat( Vector( 49.0, 33.35, -33.35 ), Angle(0,180,0) ) 
	local seat_fr = self:AddPassengerSeat( Vector( 49.0, -33.35, -33.35 ), Angle(0,0,0) ) 
	
	seat_bl.ExitPos = Vector( -80, 0, -30 ) 
	seat_br.ExitPos = Vector( -80, 0, -30 ) 
	seat_fl.ExitPos = Vector( -80, 0, -30 ) 
	seat_fr.ExitPos = Vector( -80, 0, -30 )  
	self:SetSkin(1)
	self:SetBodygroup(4,1)
	hatch = false

	self:AddEngine( Vector( -144.79, 54.55, 62.55 ) )
	self:AddEngine( Vector( -144.79, 54.55, -46 ) ) 
	self:AddEngine( Vector( -144.79, -54.55, 62.55 ) ) 
	self:AddEngine( Vector( -144.79, -54.55, -46 ) ) 

	self:AddEngineSound( Vector(100,0,0) )
end

function ENT:OnEngineActiveChanged( Active )
	if Active then
		self:SetSkin(0)
		self:SetBodygroup(4,0)
		hatch = true
	else
		self:SetSkin(1)
	end
end

function ENT:OnVehicleSpecificToggled( new )
	if self:GetEngineActive() then return end
	print(bOn)
	hatch = bOn
	print(hatch)
	if hatch then
		self:SetBodygroup(4,0)
	else 
		self:SetBodygroup(4,1) 
	end
end