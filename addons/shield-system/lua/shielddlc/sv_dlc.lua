hook.Add("EntityTakeDamage", "SWRPShieldDLC:Effects", function(ent, dmginfo)
	if ent.ispersonalshield then
		if dmginfo:IsExplosionDamage() then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.8)

			return
		end

		local pos1 = dmginfo:GetDamagePosition()
		local ply = ent:GetShieldOwner()
		if not IsValid(ply) then return end
		local pos2 = ply:GetPos() + ply:OBBCenter()

		local tr = util.TraceLine({
			start = pos2,
			endpos = pos1,
			filter = {ply}
		})

		tr.HitPos = tr.HitPos - (pos1 - pos2) * 0.125
		local effectdata = EffectData()
		effectdata:SetOrigin(tr.HitPos)
		effectdata:SetNormal((tr.HitPos - pos2):GetNormalized())
		effectdata:SetScale(dmginfo:GetDamage() * 25)
		util.Effect("riffle", effectdata)
		sound.Play("swrpshield/shoot1.wav", tr.HitPos, 100, 100, 1)
	end

	if ent:IsPlayer() and IsValid(ent.per_shield) then
		if dmginfo:IsExplosionDamage() then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.2)
		else
			local shield = ent.per_shield
			if not ent.GetRadius then return end
			local radius = ent:GetRadius()
			local attacker = dmginfo:GetAttacker()
			if not IsValid(attacker) or not radius then return end
			local dist = attacker:GetPos():DistToSqr(shield:GetPos())

			if dist > radius ^ 2 then
				shield:TakeDamageInfo(dmginfo)

				return true
			end
		end
	end
end)

hook.Add("PlayerDeath", "SWRPShields:ResetCooldown", function(ply)
	ply.per_shieldcooldown = nil
end)

hook.Add("CanPlayerEnterVehicle", "SWRPShields:CantEnter", function(ply)
	if IsValid(ply.per_shield) then return false end
end)