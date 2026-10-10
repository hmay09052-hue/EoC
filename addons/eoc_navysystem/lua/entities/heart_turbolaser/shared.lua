ENT.Type = "anim";
ENT.Base = "base_anim";
ENT.PrintName = "heart_turbolaser";
ENT.Author = "drunken hearted";

ENT.Spawnable = false;

function ENT:SetupDataTables()
	self:NetworkVar( "String", "0", "ColR" );
	self:NetworkVar( "String", "1", "ColG" );
	self:NetworkVar( "String", "2", "ColB" );

	self:NetworkVar("Float", "0", "Scale");
end
