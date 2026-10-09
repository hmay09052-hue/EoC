local cloudMat = Material("particle/particle_smokegrenade")

function EFFECT:Init(data)
    self.Origin = data:GetOrigin()
    self.StartTime = CurTime()
    self.Duration = 30
    self.Radius = 280
    self.CloudParticles = {}
    
    for i = 1, 25 do
        local angle = math.random() * math.pi * 2
        local dist = math.Rand(20, self.Radius * 0.75)
        local height = math.Rand(10, 120)
        
        table.insert(self.CloudParticles, {
            angle = angle,
            dist = dist,
            height = height,
            size = math.Rand(100, 220),
            alpha = math.Rand(20, 45),
            rot = math.random() * 360,
            driftSpeed = math.Rand(0.05, 0.15),
            phase = math.random() * math.pi * 2
        })
    end
end

function EFFECT:Think()
    local elapsed = CurTime() - self.StartTime
    if elapsed > self.Duration then return false end
    
    local dt = FrameTime()
    for _, cloud in ipairs(self.CloudParticles) do
        cloud.angle = cloud.angle + cloud.driftSpeed * dt
        cloud.rot = cloud.rot + dt * 5
    end
    
    return true
end

function EFFECT:Render()
    local time = CurTime()
    local elapsed = time - self.StartTime
    
    local fadeIn = math.Clamp(elapsed * 1.2, 0, 1)
    local fadeOut = math.Clamp(1 - (elapsed - self.Duration + 5) / 5, 0, 1)
    local masterFade = fadeIn * fadeOut
    
    render.SetMaterial(cloudMat)
    
    for _, cloud in ipairs(self.CloudParticles) do
        local pulse = math.sin(time * 0.6 + cloud.phase) * 0.08 + 0.92
        local alpha = cloud.alpha * pulse * masterFade
        local size = cloud.size * pulse
        
        local pos = self.Origin + Vector(
            math.cos(cloud.angle) * cloud.dist,
            math.sin(cloud.angle) * cloud.dist,
            cloud.height
        )
        
        render.DrawSprite(pos, size, size, Color(100, 210, 230, alpha))
        render.DrawSprite(pos, size * 0.6, size * 0.6, Color(140, 230, 245, alpha * 0.5))
    end
end
