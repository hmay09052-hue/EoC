AddCSLuaFile()


ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName		= "Vehiclespawnpoint"
ENT.Author			= "Lt. Sammy"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Category        = "SSE"
ENT.Spawnable       = true
ENT.Editable        = true
if SERVER then
        
    function ENT:Initialize()

        self:SetModel( "models/maxofs2d/cube_tool.mdl" )
        self:DrawShadow( false )

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    end

end

function ENT:SetupDataTables()

	self:NetworkVar( "String", 0, "PlatformName", { KeyName = "platformname",	Edit = { type = "Generic",	order = 1} } ) 

	if SERVER then
		self:SetPlatformName("Unbekannt")
	end
end

if CLIENT then
    function ENT:Draw()
        if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP then
            self:DrawModel() 

            if LocalPlayer():GetPos():DistToSqr(self:GetPos()) < 1000*1000 then
                render.DrawWireframeBox( self:GetPos(), self:GetAngles(), Vector( -200, -200, -200 ), Vector( 200, 200, 200 ), Color(200,0,0,200) ) -- draws the box 
            end
        end
    end

end