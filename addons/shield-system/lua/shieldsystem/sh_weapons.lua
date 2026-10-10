hook.Add("Initialize", "RegisterShieldSweps", function()
	for className, ent in pairs(scripted_ents.GetList()) do
		local base = ent.Base
		if base ~= "shield_base" then continue end
		local SWEP = {}
		SWEP.Base = "shield_deployer_base"
		SWEP.PrintName = ent.t.PrintName or className .. " Deployer"
		SWEP.Category = "Shields"
		SWEP.Author = "Star & Joe"
		SWEP.Purpose = "Deploy Shields"
		SWEP.Spawnable = true
		SWEP.AdminSpawnable = true
		SWEP.ENT_CLASS = className
		weapons.Register(SWEP, className .. "_deployer")

		if SERVER then
			util.PrecacheModel(ent.t.shieldmodel)
		end
	end

	if CLIENT then
		RunConsoleCommand("spawnmenu_reload")
	end
end)