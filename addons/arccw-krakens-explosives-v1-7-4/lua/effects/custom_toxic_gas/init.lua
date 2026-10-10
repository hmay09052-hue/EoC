function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local emitter = ParticleEmitter(pos)
    local radius = 640
    local gasLifetime = 30

    for i = 1, 140 do
        local particle = emitter:Add("csgo/particle/particle_smokegrenade", pos)

        if particle then
            local spread = VectorRand():GetNormalized() * math.Rand(radius * 0.3, radius * 0.8)
            spread.z = math.abs(spread.z) * 0.5 + math.Rand(20, 80)

            particle:SetVelocity(spread)
            particle:SetDieTime(math.Rand(gasLifetime * 0.7, gasLifetime))
            particle:SetStartAlpha(math.Rand(120, 160))
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(140, 180))
            particle:SetEndSize(math.Rand(200, 240))
            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(math.Rand(-0.5, 0.5))
            particle:SetColor(119, 150, 74)
            particle:SetAirResistance(100)
            particle:SetCollide(true)
            particle:SetBounce(1)
            particle:SetLighting(false)
        end
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
