
if SERVER then return end

matproxy.Add({
	name = "dlt_heat",
	init = function(self, mat, values)
		self.ResultTo = values.resultvar
	end,
	bind = function(self, mat, ent)
		if not IsValid(ent) then return end
		if not ent.GetHeat 
		and not (IsValid(ent:GetOwner()) and (ent:GetOwner().GetHeat
		or (ent:GetOwner().GetActiveWeapon and IsValid(ent:GetOwner():GetActiveWeapon()) and ent:GetOwner():GetActiveWeapon().GetHeat) ) )  then
			mat:SetFloat(self.ResultTo, "0")
			return
		end

		if IsValid(ent:GetOwner()) and ent:GetOwner().GetActiveWeapon and IsValid(ent:GetOwner():GetActiveWeapon()) and ent:GetOwner():GetActiveWeapon().GetHeat then
			ent = ent:GetOwner():GetActiveWeapon()
		end

		if not ent.GetHeat then
			mat:SetFloat(self.ResultTo, "0")
			return
		end

		mat:SetFloat(self.ResultTo, tostring(ent:GetHeat()))
	end
})