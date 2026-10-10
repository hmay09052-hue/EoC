ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Willkommens Board"
ENT.Category = "CW:RP (Ausbildungstafel)"
ENT.Spawnable = true

-- Größe der Tafel in Tafel-Pixeln (Model-Maße x 10)
ENT.BoardW = 1900
ENT.BoardH = 950
ENT.BoardLabel = "Echoes of Clones · Ausbildung"

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Page")
	self:NetworkVar("Float", 1, "Max")

	-- Anzahl der Seiten (Seiten selbst stehen in cl_init.lua)
	if SERVER then
		self:SetPage(1)
		self:SetMax(1)
	end
end
