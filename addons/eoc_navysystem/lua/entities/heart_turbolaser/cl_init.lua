include("shared.lua");
util.PrecacheModel("models/heart/turbolaser_bolt.mdl");
util.PrecacheModel("models/heart/turbolaser_glow.mdl");

function ENT:Initialize()
	self.model = ClientsideModel("models/heart/turbolaser_bolt.mdl");
	self.model:SetModelScale(self:GetScale(), 0);

	self.glow = ClientsideModel("models/heart/turbolaser_glow.mdl");
	self.glow:SetModelScale(self:GetScale(), 0);
	self.glow:SetColor(Color(self:GetColR(),self:GetColG(),self:GetColB()));
end

function ENT:Draw()
end

function ENT:Think()
	if not self:IsValid() then
		self.model:Remove();
		self.glow:Remove();
	end

	self.model:SetPos(self:GetPos());
	self.model:SetAngles(self:GetAngles());

	self.glow:SetPos(self:GetPos());
	self.glow:SetAngles(self:GetAngles());
end

function ENT:OnRemove()
	self.model:Remove();
	self.glow:Remove();
end

language.Add("heart_turbolaser", "Turbolaser");