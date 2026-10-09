AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Incendiary Fire (Secondary)"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Radius = 150

function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_junk/flare.mdl")
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        self:DrawShadow(false)
        self:SetRenderMode(RENDERMODE_TRANSALPHA)
        self:SetColor(Color(255, 255, 255, 0))
        self:SetNoDraw(false)

        ParticleEffect("molotov_explosion", self:GetPos(), self:GetAngles())
    end
end

function ENT:Think()
    return false
end

function ENT:OnRemove()
end

if CLIENT then
    local fireMat = Material("sprites/orangeflare1")
    local glowMat = Material("sprites/light_glow02_add")

    function ENT:Draw()
    end

    function ENT:DrawTranslucent()
        local pos = self:GetPos()
        local pulse = 0.5 + math.sin(CurTime() * 6 + 1) * 0.5
        local size = 80 * pulse

        render.SetMaterial(fireMat)
        render.DrawSprite(pos, size, size, Color(255, 80, 20, 140 * pulse))
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, size * 0.4, size * 0.4, Color(255, 160, 60, 180))

        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 80
            dlight.b = 20
            dlight.brightness = 2.5 * pulse
            dlight.decay = 800
            dlight.size = 200
            dlight.dietime = CurTime() + 0.1
        end
    end
end
