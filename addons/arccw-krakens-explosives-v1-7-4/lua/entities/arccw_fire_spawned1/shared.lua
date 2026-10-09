AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Incendiary Fire (Primary)"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.Radius = 200
ENT.DamagePerTick = 12
ENT.TickRate = 0.25

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

        self.DamageTimer = CurTime()
        self.Creator = NULL

        self:EmitSound("ArcCW_Kraken.Explosives.IncendiaryLoop", 125)

        local pos = self:GetPos()
        for i = 1, 20 do
            local fire = ents.Create("info_particle_system")
            if not IsValid(fire) then continue end
            fire:SetKeyValue("effect_name", (i < 2) and "molotov_fire_main_gm" or "molotov_fire_child_gm")
            fire:SetPos(Vector(pos.x + math.Rand(0, 144) * math.sin(math.rad(i * math.Rand(0, 180))), pos.y + math.Rand(0, 144) * math.cos(math.rad(i * math.Rand(0, 180))), pos.z))
            fire:SetAngles(self:GetAngles())
            fire:SetParent(self)
            fire:Spawn()
            fire:Activate()
            fire:Fire("Start", "", 0)
            fire:Fire("Kill", "", 8)
        end
    end
end

function ENT:SetCreator(ent)
    self.Creator = ent
end

function ENT:Think()
    if not SERVER then return end

    if CurTime() < self.DamageTimer then return end
    self.DamageTimer = CurTime() + self.TickRate

    local pos = self:GetPos()
    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self

    for _, ent in ipairs(ents.FindInSphere(pos, self.Radius)) do
        if not IsValid(ent) then continue end
        if ent == self or ent == self.Creator then continue end
        if not (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then continue end
        if ent:IsPlayer() and not ent:Alive() then continue end

        local tr = util.TraceLine({
            start = pos,
            endpos = ent:WorldSpaceCenter(),
            filter = {self, self.Creator},
            mask = MASK_SOLID_BRUSHONLY,
        })
        if tr.Hit and tr.Fraction < 0.95 then continue end

        local dmg = DamageInfo()
        dmg:SetAttacker(attacker)
        dmg:SetInflictor(self)
        dmg:SetDamage(self.DamagePerTick)
        dmg:SetDamageType(DMG_BURN)
        dmg:SetDamagePosition(ent:WorldSpaceCenter())
        ent:TakeDamageInfo(dmg)

        if ent:IsPlayer() or ent:IsNPC() then
            ent:Ignite(2, 0)
        end
    end

    self:NextThink(CurTime() + self.TickRate)
    return true
end

function ENT:OnRemove()
    if SERVER then
        self:StopSound("ArcCW_Kraken.Explosives.IncendiaryLoop")
        self:EmitSound("ArcCW_Kraken.Explosives.IncendiaryFadeOut", 125)
    end
end

if CLIENT then
    local fireMat = Material("sprites/orangeflare1")
    local glowMat = Material("sprites/light_glow02_add")

    function ENT:Draw()
    end

    function ENT:DrawTranslucent()
        local pos = self:GetPos()
        local pulse = 0.6 + math.sin(CurTime() * 8) * 0.4
        local size = 120 * pulse

        render.SetMaterial(fireMat)
        render.DrawSprite(pos, size, size, Color(255, 120, 30, 180 * pulse))
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, size * 0.5, size * 0.5, Color(255, 200, 80, 220))

        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 120
            dlight.b = 30
            dlight.brightness = 4 * pulse
            dlight.decay = 1000
            dlight.size = 300
            dlight.dietime = CurTime() + 0.1
        end
    end
end
