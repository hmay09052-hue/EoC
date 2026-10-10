RunConsoleCommand("sv_tfa_bullet_penetration_power_mul", "0")

hook.Add( "EntityTakeDamage", "SWRPShields:Effects", function( ent, dmginfo )
    if ent.isshield then 
        local pos1 = dmginfo:GetDamagePosition()
        local pos2 =  ent.gen:GetPos()

        if SWRPShield.shootoutofshield then
            local att = dmginfo:GetAttacker()
            local rad = ent.gen.radius or 0
            if IsValid(att) and att:IsPlayer() and att:GetPos():DistToSqr(pos2) <= rad ^ 2 then return false end
        end

        local tr = util.TraceLine( {
            start = pos2,
            endpos = pos1,
            filter = {ent.gen}
        } )
        tr.HitPos = tr.HitPos - ( pos1 - pos2) * 0.05

        local effectdata = EffectData()
        effectdata:SetOrigin( tr.HitPos )
        effectdata:SetNormal( (tr.HitPos - pos2 ):GetNormalized() )
        effectdata:SetScale(dmginfo:GetDamage() * 5)
        util.Effect( "riffle", effectdata )
        sound.Play("swrpshield/shoot1.wav", tr.HitPos,100,100,1)
    end

end )

hook.Add("PhysgunPickup", "SWRPShields:Unfreeze", function(ply,ent)
    if ent.isshield or (ent.isgenerator and ent:GetSequence() == 3) then return false end
end)

/*
hook.Add("PlayerSpawnedNPC", "RDV.TURRET.HATE", function(ply, ent)
    local class = ent:GetClass()
	if class == "npc_bullseye" then return end
    if not SWRPShield.shouldtargetshield then return end
    if SWRPShield.friendlynpcs and SWRPShield.friendlynpcs[class] then return end
	ent:AddRelationship( "npc_bullseye D_HT 99 ")
end)
*/