function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local ang = Angle(0, 0, 0)
    
    local emitter = ParticleEmitter(pos)
    if not emitter then return end

    for i = 1, 35 do
        local p = emitter:Add("sprites/physbeam", pos)
        if p then
            local vel = VectorRand() * math.Rand(200, 400)
            p:SetVelocity(vel)
            p:SetDieTime(math.Rand(0.3, 0.6))
            p:SetStartAlpha(255)
            p:SetEndAlpha(0)
            p:SetStartSize(math.Rand(30, 50))
            p:SetEndSize(0)
            p:SetRoll(math.Rand(0, 360))
            p:SetColor(161, 235, 52)
        end
    end
    
    for i = 1, 20 do
        local p = emitter:Add("sprites/glow04_noz", pos)
        if p then
            local vel = VectorRand() * math.Rand(100, 250)
            vel.z = vel.z + math.Rand(50, 150)
            p:SetVelocity(vel)
            p:SetDieTime(math.Rand(0.5, 1.2))
            p:SetStartAlpha(255)
            p:SetEndAlpha(0)
            p:SetStartSize(math.Rand(4, 8))
            p:SetEndSize(0)
            p:SetColor(200, 255, 100)
            p:SetGravity(Vector(0, 0, -200))
            p:SetBounce(0.5)
            p:SetCollide(true)
        end
    end

    for i = 1, 40 do
        local p = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), pos)
        if p then
            local dir = VectorRand():GetNormalized()
            local vel = dir * math.Rand(100, 280)
            vel.z = math.abs(vel.z) * 0.5 + math.Rand(30, 80)
            p:SetVelocity(vel)
            p:SetDieTime(math.Rand(3, 6))
            p:SetStartAlpha(math.Rand(140, 200))
            p:SetEndAlpha(0)
            p:SetStartSize(math.Rand(60, 100))
            p:SetEndSize(math.Rand(150, 220))
            p:SetRoll(math.Rand(0, 360))
            p:SetRollDelta(math.Rand(-1.5, 1.5))
            p:SetColor(117, 143, 53)
            p:SetAirResistance(120)
            p:SetGravity(Vector(0, 0, 15))
            p:SetCollide(true)
            p:SetBounce(0.4)
            p:SetLighting(false)
        end
    end
    
    for i = 1, 15 do
        local p = emitter:Add("effects/softglow", pos)
        if p then
            local vel = VectorRand():GetNormalized() * math.Rand(300, 500)
            p:SetVelocity(vel)
            p:SetDieTime(math.Rand(0.4, 0.8))
            p:SetStartAlpha(120)
            p:SetEndAlpha(0)
            p:SetStartSize(80)
            p:SetEndSize(200)
            p:SetRoll(math.Rand(0, 360))
            p:SetColor(161, 235, 52)
            p:SetLighting(false)
        end
    end

    emitter:Finish()
    
    sound.Play("kraken/explosives/dioxis/start" .. math.random(1, 4) .. ".wav", pos, 85, math.Rand(95, 105), 0.8)
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
