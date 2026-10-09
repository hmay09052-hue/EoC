AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Incendiary Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.SphereSize = 8
DEFINE_BASECLASS("arccw_kraken_nade_base")

local glowMat = Material("sprites/light_glow02_add")
local fireMat = Material("sprites/orangeflare1")

function ENT:Draw()
    self:DrawModel()
    if CLIENT and not self._detonated then
        local pos = self:GetPos()
        local pulse = 0.7 + math.sin(CurTime() * 10) * 0.3
        local glowSize = 15 * pulse
        
        render.SetMaterial(glowMat)
        render.DrawSprite(pos, glowSize, glowSize, Color(255, 120, 40, 180 * pulse))
        
        render.SetMaterial(fireMat)
        render.DrawSprite(pos, glowSize * 0.6, glowSize * 0.6, Color(255, 200, 100, 200))
        
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            dlight.pos = pos
            dlight.r = 255
            dlight.g = 120
            dlight.b = 40
            dlight.brightness = 2 * pulse
            dlight.decay = 1000
            dlight.size = 100
            dlight.dietime = CurTime() + 0.1
        end
    end
end
function ENT:Initialize()
    if SERVER then
        BaseClass.Initialize(self)
        self:SetModel("models/arccw/kraken/sw/explosives/world/w_thermalimploder.mdl")
        self:SetCollisionGroup(COLLISION_GROUP_NONE)
        self:DrawShadow(false)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(2)
            phys:SetBuoyancyRatio(0)
            phys:EnableDrag(true)
            phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
            phys:AddGameFlag(FVPHYSICS_NO_NPC_IMPACT_DMG)
        end
        util.SpriteTrail(self, 0, Color(255, 120, 40, 150), false, 12, 2, 0.4, 1 / 12, "sprites/orangeflare1")
    end
    self:EmitSound("kraken/explosives/incgrenade/beep.wav")
    self.ActiveTimer = CurTime() + 1.5
    self.IgniteEnd = 0
    self.IgniteEndTimer = CurTime()
    self.IgniteStage = 0
    self.IgniteStageTimer = CurTime()
end
function ENT:Detonate()
    if self._detonated then return end
    self._detonated = true
    if SERVER then
        local f2 = ents.Create("arccw_fire_spawned2")
        if IsValid(f2) then
            f2:SetPos(self:GetPos())
            f2:SetOwner(IsValid(self.Owner) and self.Owner or self)
            f2:Spawn()
            SafeRemoveEntityDelayed(f2, 8)
        end
        local f1 = ents.Create("arccw_fire_spawned1")
        if IsValid(f1) then
            f1:SetPos(self:GetPos())
            f1:SetOwner(IsValid(self.Owner) and self.Owner or self)
            f1:SetCreator(self)
            f1:Spawn()
            SafeRemoveEntityDelayed(f1, 8)
        end
        self:SetRenderMode(RENDERMODE_TRANSALPHA)
        self:SetColor(Color(255, 255, 255, 0))
        self:DrawShadow(false)
        self:StopParticles()
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        timer.Simple(0, function()
            if not IsValid(self) then return end
            self:SetMoveType(MOVETYPE_NONE)
            self:SetSolid(SOLID_NONE)
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then phys:EnableCollisions(false) phys:EnableMotion(false) phys:Sleep() end
        end)
    end
    self:EmitSound("ArcCW_Kraken.Explosives.IncendiaryExpl")
    self.IgniteEnd = 1
    self.IgniteEndTimer = CurTime() + 7
    self.IgniteStage = 1
    self.IgniteStageTimer = CurTime() + 0.1
    SafeRemoveEntityDelayed(self, 8)
end
function ENT:PhysicsCollide(data, phys)
    if self.Defused then return end
    if SERVER and (self.ActiveTimer > CurTime() or data.Speed >= 150) then
        self:EmitSound("ArcCW_Kraken.Explosives.Bounce")
    end
    local ang = data.HitNormal:Angle()
    ang.p = math.abs(ang.p); ang.y = math.abs(ang.y); ang.r = math.abs(ang.r)
    if ang.p > 90 or ang.p < 60 then
        self:EmitSound("ArcCW_Kraken.Explosives.Bounce")
        local impulse = (data.OurOldVelocity - 2 * data.OurOldVelocity:Dot(data.HitNormal) * data.HitNormal) * 0.25
        phys:ApplyForceCenter(impulse)
    else
        timer.Simple(0, function()
            if IsValid(self) then self:Detonate() end
        end)
    end
end
function ENT:Think()
    if self.Defused then return end
    if SERVER and ArcCW_Kraken_GrenadeEntitySweep(self) then self:Detonate() return end
    if SERVER then
        local pos = self:GetPos()
        if not util.IsInWorld(pos) then
            self:EmitSound("ArcCW_Kraken.Explosives.IncendiaryExtinguish")
            SafeRemoveEntity(self)
            return
        end
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            local v = phys:GetVelocity()
            if v:LengthSqr() > (4000 * 4000) then
                phys:SetVelocityInstantaneous(v:GetNormalized() * 4000)
            end
            local av = phys:GetAngleVelocity()
            if av:LengthSqr() > (1200 * 1200) then
                phys:AddAngleVelocity(-av * 0.5)
            end
        end
    end
    self:NextThink(CurTime() + 0.05)
    return true
end