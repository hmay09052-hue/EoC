AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_rocket_base"
ENT.PrintName = "Cluster Gas Rocket"
ENT.Spawnable = false

DEFINE_BASECLASS("arccw_rocket_base")

ENT.Model = "models/weapons/w_missile_launch.mdl"
ENT.InitialSpeed = 3000
ENT.GravityScale = 0
ENT.StandardExplosionRadius = 350
ENT.StandardExplosionDamage = 80
ENT.StandardExplosionEffect = "gas_explosion"
ENT.TailLightColor = Color(120, 255, 80)
ENT.TailLightScale = 0.5
ENT.SmokeTrail = false

local SMOKE_INTERVAL = 0.05
local glowMat = Material("sprites/light_glow02_add")

function ENT:OnInitialize()
    BaseClass.OnInitialize(self)
    if SERVER then
        self:StartGasTrail()
    end
end

function ENT:OnRemove()
    if SERVER then self:StopGasTrail() end
    BaseClass.OnRemove(self)
end

function ENT:StartGasTrail()
    self.SmokeTimer = "arc9_gas_trail_" .. self:EntIndex()
    timer.Create(self.SmokeTimer, SMOKE_INTERVAL, 0, function()
        if not IsValid(self) then timer.Remove(self.SmokeTimer) return end
        local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        fx:SetStart(self:GetVelocity())
        fx:SetScale(1)
        fx:SetEntity(self)
        util.Effect("gas_trail_effect", fx, true, true)
    end)
end

function ENT:StopGasTrail()
    if self.SmokeTimer then timer.Remove(self.SmokeTimer) self.SmokeTimer = nil end
end

function ENT:PhysicsCollide(data, physobj)
    if self.Detonated then return end
    self:PreDetonate({ HitPos = data.HitPos })
end

function ENT:Detonate(data)
    if CLIENT then return end
    local pos = (data and data.HitPos) or self:GetPos()
    self:DoStandardExplosion({ pos = pos })

    local gas = ents.Create("arccw_ent_gas_field")
    if IsValid(gas) then
        gas:SetPos(pos)
        gas:SetOwner(self:GetOwner())
        gas:Spawn()
    end

    self:StopGasTrail()
    self.Defused = true
    SafeRemoveEntityDelayed(self, self.SmokeTrailTime or 0)
end

function ENT:Draw()
    self:DrawModel()
    local pos = self:GetPos() - self:GetForward() * 10
    local pulse = 0.8 + math.sin(CurTime() * 15) * 0.2
    local glowSize = 22 * pulse
    
    render.SetMaterial(glowMat)
    render.DrawSprite(pos, glowSize * 1.5, glowSize * 1.5, Color(100, 255, 80, 200))
    render.DrawSprite(pos, glowSize * 0.7, glowSize * 0.7, Color(180, 255, 150, 255))
    
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = pos
        dlight.r, dlight.g, dlight.b = 120, 255, 80
        dlight.brightness = 3.5 * pulse
        dlight.decay = 1000
        dlight.size = 160
        dlight.dietime = CurTime() + 0.1
    end
end
