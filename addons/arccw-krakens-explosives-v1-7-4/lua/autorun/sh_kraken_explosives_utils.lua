AddCSLuaFile()

function ArcCW_Kraken_HeavyExplosionFX(pos, hitNormal)
    if CLIENT then return end
    local ang = (hitNormal and isvector(hitNormal)) and (-hitNormal):Angle() or Angle(0, 0, 0)
    ParticleEffect("claymore_dustwave", pos, ang, nil)
    ParticleEffect("claymore_fastsmoke", pos, ang, nil)
    ParticleEffect("claymore_shockwave", pos, ang, nil)
    ParticleEffect("claymore_smoke", pos, ang, nil)
    ParticleEffect("claymore_smoke_b", pos, ang, nil)
    ParticleEffect("explosion_he_m79", pos, ang, nil)
    ParticleEffect("explosion_mortarb", pos, ang, nil)
end

function ArcCW_Kraken_GrenadeExplosionFX(pos, hitNormal)
    if CLIENT then return end
    local ang = (hitNormal and isvector(hitNormal)) and (-hitNormal):Angle() or Angle(0, 0, 0)
    ParticleEffect("m79_shrapnel", pos, ang, nil)
    ParticleEffect("m79_smoke_e", pos, ang, nil)
    ParticleEffect("m79_trails_c", pos, ang, nil)
    ParticleEffect("m79_shockwave", pos, ang, nil)
    ParticleEffect("m79_flash", pos, ang, nil)
    ParticleEffect("smoke_plume", pos, ang, nil)
    ParticleEffect("explosion_lensflare", pos, ang, nil)
end


function ArcCW_Kraken_WaterExplosionFX(pos)
    if CLIENT then return end
    ParticleEffect("water_explosion", pos + Vector(0, 0, 8), Angle(0, 0, 0), nil)
end

if not ArcCW_Kraken_LOSBlastDamage then
    function ArcCW_Kraken_LOSBlastDamage(inflictor, attacker, pos, radius, damage)
        if CLIENT then return end
        if not pos or not radius or not damage then return end
        if radius <= 0 or damage <= 0 then return end

        local radiusSqr = radius * radius

        for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
            if not IsValid(ent) then continue end
            if ent == inflictor then continue end

            local targetPos = ent:WorldSpaceCenter()
            local tr = util.TraceLine({
                start = pos,
                endpos = targetPos,
                filter = {inflictor, ent},
                mask = MASK_SOLID_BRUSHONLY,
            })

            if tr.Hit and tr.Fraction < 0.98 then continue end

            local distSqr = targetPos:DistToSqr(pos)
            local f = 1 - math.Clamp(distSqr / radiusSqr, 0, 1)
            f = math.max(f, 0.05)

            local dmg = DamageInfo()
            dmg:SetDamageType(DMG_BLAST)
            dmg:SetAttacker(IsValid(attacker) and attacker or (IsValid(inflictor) and inflictor or game.GetWorld()))
            dmg:SetDamage(damage * f)
            dmg:SetDamageForce((targetPos - pos):GetNormalized() * damage * 5 * f)
            dmg:SetDamagePosition(pos)
            dmg:SetInflictor(IsValid(inflictor) and inflictor or game.GetWorld())
            ent:TakeDamageInfo(dmg)
        end
    end
end

if not ArcCW_Kraken_GrenadeEntitySweep then
    function ArcCW_Kraken_GrenadeEntitySweep(ent)
        if CLIENT then return false end
        if not IsValid(ent) then return false end

        local vel = ent:GetVelocity()
        if vel:LengthSqr() < 2500 then return false end

        local sweepDist = math.max(vel:Length() * engine.TickInterval() * 3, 32)
        local tr = util.TraceHull({
            start = ent:GetPos(),
            endpos = ent:GetPos() + vel:GetNormalized() * sweepDist,
            filter = {ent, ent:GetOwner()},
            mins = Vector(-4, -4, -4),
            maxs = Vector(4, 4, 4),
            mask = MASK_SHOT,
        })

        if tr.Hit and IsValid(tr.Entity) and not tr.Entity:IsWorld() then
            local hitEnt = tr.Entity
            if hitEnt:IsPlayer() or hitEnt:IsNPC() or hitEnt:IsNextBot() or hitEnt:IsVehicle() or hitEnt.LVS or hitEnt.LFS then
                return true
            end
        end

        return false
    end
end
