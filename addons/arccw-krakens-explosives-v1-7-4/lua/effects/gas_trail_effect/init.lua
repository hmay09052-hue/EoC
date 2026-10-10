function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local ent = data:GetEntity()
    
    local emitter = ParticleEmitter(pos)
    if not emitter then return end

    for i = 1, 3 do
        local p = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), pos)
        if p then
            local vel = VectorRand() * 25
            vel.z = vel.z + math.Rand(5, 15)
            p:SetVelocity(vel)
            p:SetDieTime(math.Rand(1.5, 2.5))
            p:SetStartAlpha(math.Rand(100, 140))
            p:SetEndAlpha(0)
            p:SetStartSize(math.Rand(18, 28))
            p:SetEndSize(math.Rand(45, 65))
            p:SetRoll(math.Rand(0, 360))
            p:SetRollDelta(math.Rand(-0.8, 0.8))
            p:SetColor(117, 143, 53)
            p:SetAirResistance(60)
            p:SetGravity(Vector(0, 0, 8))
            p:SetLighting(false)
            p:SetCollide(true)
            p:SetBounce(0.3)
        end
    end
    
    local p2 = emitter:Add("sprites/light_glow02_add", pos)
    if p2 then
        p2:SetVelocity(VectorRand() * 15)
        p2:SetDieTime(math.Rand(0.8, 1.2))
        p2:SetStartAlpha(60)
        p2:SetEndAlpha(0)
        p2:SetStartSize(25)
        p2:SetEndSize(50)
        p2:SetRoll(math.Rand(0, 360))
        p2:SetColor(161, 235, 52)
        p2:SetLighting(false)
    end
    
    if math.random() < 0.4 then
        local p3 = emitter:Add("sprites/glow04_noz", pos + VectorRand() * 5)
        if p3 then
            p3:SetVelocity(Vector(0, 0, math.Rand(20, 40)))
            p3:SetDieTime(math.Rand(0.5, 1.0))
            p3:SetStartAlpha(180)
            p3:SetEndAlpha(0)
            p3:SetStartSize(math.Rand(3, 6))
            p3:SetEndSize(math.Rand(8, 12))
            p3:SetColor(161, 235, 52)
            p3:SetGravity(Vector(0, 0, 25))
        end
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
