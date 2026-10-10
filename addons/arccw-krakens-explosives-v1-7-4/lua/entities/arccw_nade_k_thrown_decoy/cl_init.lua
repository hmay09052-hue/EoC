include('shared.lua')

local glowMat = Material("sprites/light_glow02_add")
local decoyMat = Material("sprites/orangeflare1")

function ENT:Draw()
    self:DrawModel()
    if not self.Defused then
        local pos = self:GetPos()
        local pulse = 0.7 + math.sin(CurTime() * 8) * 0.3
        local glowSize = 15 * pulse
        
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, glowSize, glowSize, Color(255, 200, 100, 180 * pulse))
        
        render.SetMaterial(decoyMat)
        render.DrawSprite(pos, glowSize * 0.6, glowSize * 0.6, Color(255, 220, 150, 200))
        
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 200
            dlight.b = 100
            dlight.brightness = 2 * pulse
            dlight.decay = 1000
            dlight.size = 100
            dlight.dietime = CurTime() + 0.1
        end
    end
end

function ENT:IsTranslucent()
	return true
end

