AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Droiden-Thermaldetonator"
ENT.Spawnable = false
ENT.EOCDroidProjectile = true

ENT.Models = { "models/weapons/tfa_starwars/w_thermal.mdl", "models/weapons/w_grenade.mdl" }
ENT.FuseTime = 2.5
ENT.ExplodeOnImpact = false
ENT.Radius = nil  -- nil = Config
ENT.Damage = nil
ENT.GlowColor = Color(255, 60, 40)

function ENT:Initialize()
    if SERVER then
        self:SetModel(EOCDroids.PickModel(self.Models, "models/weapons/w_grenade.mdl"))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(2)
            phys:Wake()
        end

        self.ExplodeTime = CurTime() + (self.ExplodeOnImpact and 8 or self.FuseTime)

        local beep = EOCDroids.ValidSound("weapons/tfa_starwars/ThermalDetonator_Beeps_01.wav", "weapons/grenade/tick1.wav")
        if beep then self:EmitSound(beep, 75) end
    end
end

if SERVER then
    function ENT:Think()
        if CurTime() >= self.ExplodeTime then
            self:Explode()
            return
        end
        self:NextThink(CurTime() + 0.1)
        return true
    end

    function ENT:PhysicsCollide(data)
        if self.ExplodeOnImpact and data.Speed > 40 and CurTime() > (self.ArmTime or 0) then
            self.ExplodeTime = 0
            self:NextThink(CurTime())
        elseif data.Speed > 150 then
            self:EmitSound("physics/metal/metal_grenade_impact_hard" .. math.random(1, 3) .. ".wav", 70)
        end
    end

    function ENT:Explode()
        if self.Exploded then return end
        self.Exploded = true

        local C = EOCDroids.Config
        local pos = self:GetPos()
        local attacker = IsValid(self.DroidOwner) and self.DroidOwner or self

        local ed = EffectData()
        ed:SetOrigin(pos)
        util.Effect("Explosion", ed)
        util.ScreenShake(pos, 8, 5, 0.8, 800)

        util.BlastDamage(self, attacker, pos, self.Radius or C.GrenadeRadius, (self.Damage or C.GrenadeDamage) * C.DamageMultiplier)

        local tr = util.TraceLine({ start = pos + Vector(0, 0, 32), endpos = pos - Vector(0, 0, 64), filter = self })
        util.Decal("Scorch", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)

        self:Remove()
    end
else
    local matGlow = Material("sprites/light_glow02_add")

    function ENT:Draw()
        self:DrawModel()
        local pulse = math.abs(math.sin(CurTime() * 10))
        render.SetMaterial(matGlow)
        render.DrawSprite(self:GetPos(), 20 + pulse * 14, 20 + pulse * 14, self.GlowColor)
    end
end
