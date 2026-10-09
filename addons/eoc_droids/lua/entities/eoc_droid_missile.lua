AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Droiden-Rakete"
ENT.Spawnable = false
ENT.EOCDroidProjectile = true

ENT.Models = { "models/cs574/ammo/reworked_rocket.mdl", "models/weapons/w_missile_launch.mdl" }
ENT.Speed = 1500
ENT.TurnRate = 1.6     -- leichte Zielsuche
ENT.LifeTime = 6

function ENT:Initialize()
    if CLIENT then return end

    self:SetModel(EOCDroids.PickModel(self.Models, "models/weapons/w_missile_launch.mdl"))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:DrawShadow(false)

    self.Velocity = self:GetForward() * self.Speed
    self.DieTime = CurTime() + self.LifeTime

    util.SpriteTrail(self, 0, Color(200, 200, 200, 160), false, 10, 0, 0.5, 1 / 10 * 0.5, "trails/smoke")
    self:EmitSound("weapons/rpg/rocket1.wav", 75, 120)
end

if SERVER then
    function ENT:Think()
        local now = CurTime()
        if now >= self.DieTime then
            self:Explode(self:GetPos())
            return
        end

        local dt = FrameTime()
        local pos = self:GetPos()

        -- leicht in Richtung Ziel lenken
        if IsValid(self.Target) then
            local wanted = (EOCDroids.TargetPos(self.Target) - pos):GetNormalized() * self.Speed
            self.Velocity = LerpVector(math.Clamp(self.TurnRate * dt, 0, 1), self.Velocity, wanted)
            self.Velocity = self.Velocity:GetNormalized() * self.Speed
        end

        local nextPos = pos + self.Velocity * dt
        local tr = util.TraceLine({
            start = pos,
            endpos = nextPos,
            filter = { self, self.DroidOwner },
            mask = MASK_SHOT,
        })

        if tr.HitSky then
            self:StopSound("weapons/rpg/rocket1.wav")
            self:Remove()
            return
        end

        if tr.Hit then
            self:Explode(tr.HitPos + tr.HitNormal * 4, tr.HitNormal)
            return
        end

        self:SetPos(nextPos)
        self:SetAngles(self.Velocity:Angle())
        self:NextThink(now)
        return true
    end

    function ENT:Explode(pos, normal)
        if self.Exploded then return end
        self.Exploded = true

        local C = EOCDroids.Config
        local attacker = IsValid(self.DroidOwner) and self.DroidOwner or self

        local ed = EffectData()
        ed:SetOrigin(pos)
        util.Effect("Explosion", ed)
        util.ScreenShake(pos, 10, 5, 1, 1200)
        util.BlastDamage(self, attacker, pos, C.RocketRadius, C.RocketDamage * C.DamageMultiplier)

        if normal then
            util.Decal("Scorch", pos + normal, pos - normal * 8)
        end

        self:StopSound("weapons/rpg/rocket1.wav")
        self:Remove()
    end
else
    local matGlow = Material("sprites/light_glow02_add")
    local glowCol = Color(255, 150, 60)

    function ENT:Draw()
        self:DrawModel()
        local pos = self:GetPos() - self:GetForward() * 12
        render.SetMaterial(matGlow)
        render.DrawSprite(pos, 60, 60, glowCol)
        EOCDroids.Light(pos, glowCol, 200, 0.1, 2, self.LightId)
        self.LightId = self.LightId or EOCDroids.NextLightId()
    end
end
