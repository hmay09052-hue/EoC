ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Formationen Board"
ENT.Category = "CW:RP (Ausbildungstafel)"
ENT.Spawnable = true

-- Größe der Tafel in Tafel-Pixeln (Model-Maße x 10)
ENT.BoardW = 950
ENT.BoardH = 950
ENT.BoardLabel = "Formationen"

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Page")
	self:NetworkVar("Float", 1, "Max")

	-- Anzahl der Seiten (Seiten selbst stehen in cl_init.lua)
	if SERVER then
		self:SetPage(1)
		self:SetMax(8)
	end
end
