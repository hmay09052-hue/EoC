AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
include("shared.lua");

function ENT:Initialize()
	self.timerName = "Turbolaser Spawner " .. self:EntIndex();

	self:Spawner();
end

function ENT:Turbolaser()
	local laser = ents.Create("heart_turbolaser");
	laser:SetVar("speed", self:GetVar("speed"));
	laser:SetVar("damage", self:GetVar("damage"));
	laser:SetVar("radius", self:GetVar("radius"));

	laser:SetVar("scale", self:GetVar("scale"));
	laser:SetVar("r", self:GetVar("r"));
	laser:SetVar("g", self:GetVar("g"));
	laser:SetVar("b", self:GetVar("b"));

	return laser;
end

function ENT:Spawner()
	timer.Create(self.timerName, self:GetVar("delay", 0.5), self:GetVar("shots", 3), function()
		if not IsValid(self) then return end

		local laser = self:Turbolaser();

		laser:SetOwner(self:GetOwner());
		laser:SetPos(self:GetPos());
		laser:SetAngles(self:GetAngles());

		local spread = tonumber(self:GetVar("spread", 0));

		local spreadCon = math.random(0,1);
		if spreadCon == 1 then
			laser:SetAngles(self:GetAngles() + Angle(math.random(0, spread), math.random(0, spread), 0));
		else
			laser:SetAngles(self:GetAngles() - Angle(math.random(0, spread), math.random(0, spread), 0));
		end

		laser:Spawn();
		laser:Activate();
	end)
end

function ENT:Think()
	if not timer.Exists(self.timerName) then self:Remove() end
end

function ENT:OnRemove()
	timer.Remove(self.timerName);
end