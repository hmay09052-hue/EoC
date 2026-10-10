include("shared.lua")

function ENT:OnSpawn()
	self:RegisterTrail( Vector(-144.79, 84.55, 62.55), 0, 20, 2, 1000, 150 )	-- top left
	self:RegisterTrail( Vector(-144.79, 84.55, -46), 0, 20, 2, 1000, 150 )		-- bottom left
	self:RegisterTrail( Vector(-144.79, -84.55, 62.55), 0, 20, 2, 1000, 150 )	-- top right
	self:RegisterTrail( Vector(-144.79, -84.55, -46), 0, 20, 2, 1000, 150 )		-- bottom right
end

ENT.EngineGlow = Material( "sprites/light_glow02_add" )

function ENT:PostDrawTranslucent()
	if not self:GetEngineActive() then return end

	local Size = 80 + self:GetThrottle() * 40 + self:GetBoost() * 0.8

	local clr = Color( 0, 255, 255, 255)

	render.SetMaterial( self.EngineGlow )
	render.DrawSprite( self:LocalToWorld( Vector( -144.79, 54.55, 62.55 ) ), Size, Size, clr )
	render.DrawSprite( self:LocalToWorld( Vector( -144.79, 54.55, -46 ) ), Size, Size, clr )
	render.DrawSprite( self:LocalToWorld( Vector( -144.79, -54.55, 62.55 ) ), Size, Size, clr )
	render.DrawSprite( self:LocalToWorld( Vector( -144.79, -54.55, -46 ) ), Size, Size, clr )
end