local MAT_GLOW = Material("sprites/light_glow02_add") -- Performance: Materialien gecacht
local MAT_BEAM = Material("trails/beam_electrical")
function EFFECT:Render()
    if not IsValid(self.Ent) then return end

    for i = 1, self.numRays do
        local start = self:GetRandomPointInHitbox(self.Ent)
        local target = self:GetRandomPointInHitbox(self.Ent)

        render.SetMaterial(MAT_GLOW)
        render.DrawSprite(start, 32, 32, Color(0, 80, 255))
        render.DrawSprite(target, 16, 16, Color(255, 255, 255))

        render.SetMaterial(MAT_BEAM)
        render.DrawBeam(start, target, 12, 0, 1, Color(255, 255, 255, 255))

        local midpoint = (start + target) / 2
        for b = 1, 2 do
            local branchEnd = midpoint + VectorRand() * 25
            render.DrawBeam(midpoint, branchEnd, 6, 0, 1, Color(150, 150, 255, 255))
        end

        if (self.HitFX or 0) < CurTime() then
            self.HitFX = CurTime() + 0.05

            local ed = EffectData()
            ed:SetOrigin(target)
            ed:SetNormal((target - start):GetNormalized())
            util.Effect("StunstickImpact", ed)

            local dlight = DynamicLight(self.Ent:EntIndex() + math.random(100, 9999))
            if dlight then
                dlight.pos = target
                dlight.r = 160
                dlight.g = 180
                dlight.b = 255
                dlight.brightness = 2
                dlight.Decay = 1500
                dlight.Size = 128
                dlight.DieTime = CurTime() + 0.1
            end

            self:EmitSound("ambient/energy/zap" .. math.random(5, 9) .. ".wav", 70, 100)
        end
    end
end
