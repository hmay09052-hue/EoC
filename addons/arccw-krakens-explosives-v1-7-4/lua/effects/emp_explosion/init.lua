local SmokeMats = {
    "particle/smokesprites_0001",
    "particle/smokesprites_0002",
    "particle/smokesprites_0003"
}

function EFFECT:Init(data)
    local pos = data:GetOrigin()

    sound.Play("ambient/energy/zap9.wav", pos, 80, 100, 0.6)

    local emitter = ParticleEmitter(pos, false)

    for i = 1, 15 do
        local smoke = emitter:Add(SmokeMats[math.random(#SmokeMats)], pos)
        if smoke then
            smoke:SetVelocity(VectorRand() * 60)
            smoke:SetDieTime(math.Rand(1, 2))
            smoke:SetStartAlpha(100)
            smoke:SetEndAlpha(0)
            smoke:SetStartSize(10)
            smoke:SetEndSize(40)
            smoke:SetRoll(math.Rand(-180, 180))
            smoke:SetColor(100, 150, 255)
            smoke:SetAirResistance(100)
            smoke:SetGravity(Vector(0, 0, 20))
        end
    end

    for i = 1, 6 do
        local spark = emitter:Add("effects/spark", pos)
        if spark then
            spark:SetVelocity(VectorRand() * 200)
            spark:SetDieTime(0.3)
            spark:SetStartAlpha(255)
            spark:SetEndAlpha(0)
            spark:SetStartSize(4)
            spark:SetEndSize(0)
            spark:SetColor(80, 160, 255)
            spark:SetRoll(math.Rand(-180, 180))
            spark:SetAirResistance(100)
        end
    end

    local dlight = DynamicLight(self:EntIndex() or 0)
    if dlight then
        dlight.pos = pos
        dlight.r = 100
        dlight.g = 180
        dlight.b = 255
        dlight.brightness = 3
        dlight.Decay = 1000
        dlight.Size = 300
        dlight.DieTime = CurTime() + 0.3
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
