AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Dioxis Gas Cloud"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Radius = 300
ENT.DamagePerTick = 8
ENT.TickRate = 0.5

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

        self.DamageTimer = CurTime() + 1
        self.NoIgnite = NULL

        ParticleEffectAttach("AC_nade_gas_dust", PATTACH_ABSORIGIN_FOLLOW, self, 0)
        ParticleEffect("AC_nade_gas_explode", self:GetPos(), self:GetAngles(), self)

        self:EmitSound("kraken/explosives/dioxis/loop.wav", 100, 100, 0.6, CHAN_STATIC)
    end
end

function ENT:Think()
    if not SERVER then return end

    if CurTime() < self.DamageTimer then return end
    self.DamageTimer = CurTime() + self.TickRate

    local pos = self:GetPos()
    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self

    for _, ent in ipairs(ents.FindInSphere(pos, self.Radius)) do
        if not IsValid(ent) then continue end
        if ent == self or ent == self.NoIgnite then continue end
        if not (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then continue end
        if ent:IsPlayer() and not ent:Alive() then continue end

        local tr = util.TraceLine({
            start = pos,
            endpos = ent:WorldSpaceCenter(),
            filter = {self, self.NoIgnite},
            mask = MASK_SOLID_BRUSHONLY,
        })
        if tr.Hit and tr.Fraction < 0.95 then continue end

        local dist = ent:GetPos():Distance(pos)
        local falloff = 1 - math.Clamp(dist / self.Radius, 0, 1)

        local dmg = DamageInfo()
        dmg:SetAttacker(attacker)
        dmg:SetInflictor(self)
        dmg:SetDamage(self.DamagePerTick * falloff)
        dmg:SetDamageType(DMG_NERVEGAS)
        dmg:SetDamagePosition(ent:WorldSpaceCenter())
        ent:TakeDamageInfo(dmg)
    end

    self:NextThink(CurTime() + self.TickRate)
    return true
end

function ENT:OnRemove()
    if SERVER then
        self:StopSound("kraken/explosives/dioxis/loop.wav")
    end
end

if CLIENT then
    local toxicMat = Material("sprites/glow04_noz")
    local glowMat = Material("sprites/light_glow02_add")

    function ENT:Draw()
    end

    function ENT:DrawTranslucent()
        local pos = self:GetPos()
        local pulse = 0.5 + math.sin(CurTime() * 3) * 0.5
        local size = 180 * pulse

        render.SetMaterial(toxicMat)
        render.DrawSprite(pos, size, size, Color(100, 180, 80, 80 * pulse))
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, size * 0.4, size * 0.4, Color(100, 200, 80, 120))

        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 100
            dlight.g = 180
            dlight.b = 80
            dlight.brightness = 2 * pulse
            dlight.decay = 500
            dlight.size = 250
            dlight.dietime = CurTime() + 0.1
        end
    end
end
