-- Blaster-Laser der Droiden: Bolzen + Muendungsfeuer + Einschlag in EINEM Effekt
-- (nur eine Netzwerk-Nachricht pro Schuss). Beleuchtet die Umgebung mit Dynamic Lights.
--
-- EffectData: Origin = Muendung, Start = Treffpunkt, Normal = Trefferflaeche,
--             Color = Farbindex (EOCDroids.LaserColors), Scale = Groesse,
--             Flags: 1 = Muendungsfeuer, 2 = Einschlag

local beamMaterials = { "effects/laser1", "trails/laser", "sprites/physbeam" }
local matBeam
for _, name in ipairs(beamMaterials) do
    local mat = Material(name)
    if not mat:IsError() then
        matBeam = mat
        break
    end
end
matBeam = matBeam or Material("sprites/light_glow02_add")

local matGlow = Material("sprites/light_glow02_add")
local fallbackColor = Color(255, 45, 45)
local white = Color(255, 255, 255)

EFFECT.Speed = 7500

function EFFECT:Init(data)
    self.StartPos = data:GetOrigin()
    self.EndPos = data:GetStart()
    self.HitNormal = data:GetNormal()
    self.Flags = data:GetFlags()
    self.Scale = math.Clamp(data:GetScale(), 0.3, 4)

    local colors = EOCDroids and EOCDroids.LaserColors
    self.Col = colors and colors[data:GetColor()] or fallbackColor

    local diff = self.EndPos - self.StartPos
    self.Dist = diff:Length()
    self.Dir = diff:GetNormalized()
    self.Length = 85 * self.Scale
    self.Life = 0
    self.TravelTime = (self.Dist + self.Length) / self.Speed
    self.Impacted = false

    self.NearMuzzle = EOCDroids and EOCDroids.CanDoEffects and EOCDroids.CanDoEffects(self.StartPos)
    self.NearImpact = EOCDroids and EOCDroids.CanDoEffects and EOCDroids.CanDoEffects(self.EndPos)

    self:SetRenderBoundsWS(self.StartPos, self.EndPos, Vector(32, 32, 32))

    if bit.band(self.Flags, 1) ~= 0 and self.NearMuzzle then
        self.FlashUntil = CurTime() + 0.06
        EOCDroids.Light(self.StartPos, self.Col, 110 * self.Scale, 0.08, 2)
    end

    -- Wandernder Lichtschein am Bolzen (nur nahe am Spieler)
    if self.NearMuzzle and EyePos():DistToSqr(self.StartPos) < 1500 * 1500 then
        self.BoltLight = EOCDroids.NextLightId()
    end
end

function EFFECT:Impact()
    if bit.band(self.Flags, 2) == 0 or not self.NearImpact then return end

    local pos = self.EndPos
    local normal = self.HitNormal
    if normal:IsZero() then normal = -self.Dir end

    EOCDroids.Light(pos, self.Col, 140 * self.Scale, 0.25, 3)

    local emitter = ParticleEmitter(pos)
    if emitter then
        for _ = 1, 6 do
            local p = emitter:Add("effects/spark", pos)
            if p then
                p:SetVelocity((normal + VectorRand() * 0.7) * math.Rand(80, 220))
                p:SetDieTime(math.Rand(0.2, 0.45))
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(math.Rand(1.5, 3) * self.Scale)
                p:SetEndSize(0)
                p:SetStartLength(8)
                p:SetEndLength(1)
                p:SetColor(self.Col.r, self.Col.g, self.Col.b)
                p:SetGravity(Vector(0, 0, -500))
                p:SetCollide(true)
                p:SetBounce(0.3)
            end
        end

        local smoke = emitter:Add("particle/particle_smokegrenade", pos + normal * 2)
        if smoke then
            smoke:SetVelocity(normal * 25)
            smoke:SetDieTime(0.8)
            smoke:SetStartAlpha(70)
            smoke:SetEndAlpha(0)
            smoke:SetStartSize(3 * self.Scale)
            smoke:SetEndSize(14 * self.Scale)
            smoke:SetColor(90, 90, 90)
            smoke:SetRoll(math.Rand(0, 360))
        end

        emitter:Finish()
    end

    if EOCDroids.Config.ImpactDecals then
        util.Decal("FadingScorch", pos + normal * 2, pos - normal * 2)
    end
end

function EFFECT:Think()
    self.Life = self.Life + FrameTime()

    if not self.Impacted and self.Life * self.Speed >= self.Dist then
        self.Impacted = true
        self.ImpactTime = CurTime()
        self:Impact()
    end

    if self.BoltLight and not self.Impacted then
        local head = self.StartPos + self.Dir * math.min(self.Life * self.Speed, self.Dist)
        EOCDroids.Light(head, self.Col, 90 * self.Scale, 0.05, 1, self.BoltLight)
    end

    return self.Life < self.TravelTime + 0.15
end

function EFFECT:Render()
    local headDist = math.min(self.Life * self.Speed, self.Dist)
    local tailDist = math.max(headDist - self.Length, 0)
    local scale = self.Scale

    if tailDist < self.Dist then
        local head = self.StartPos + self.Dir * headDist
        local tail = self.StartPos + self.Dir * tailDist

        render.SetMaterial(matBeam)
        render.DrawBeam(tail, head, 9 * scale, 0, 1, self.Col)
        render.DrawBeam(tail, head, 3 * scale, 0, 1, white)

        render.SetMaterial(matGlow)
        render.DrawSprite(head, 22 * scale, 22 * scale, self.Col)
    end

    if self.FlashUntil and CurTime() < self.FlashUntil then
        render.SetMaterial(matGlow)
        render.DrawSprite(self.StartPos, 46 * scale, 46 * scale, self.Col)
        render.DrawSprite(self.StartPos, 16 * scale, 16 * scale, white)
    end

    if self.ImpactTime and bit.band(self.Flags, 2) ~= 0 then
        local frac = 1 - math.Clamp((CurTime() - self.ImpactTime) / 0.15, 0, 1)
        if frac > 0 then
            render.SetMaterial(matGlow)
            local size = 40 * scale * frac
            render.DrawSprite(self.EndPos, size, size, self.Col)
        end
    end
end
