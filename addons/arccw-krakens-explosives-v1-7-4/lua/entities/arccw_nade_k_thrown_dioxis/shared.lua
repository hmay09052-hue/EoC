AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Dioxis Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_grenade_dioxis.mdl"
ENT.FuseTime = 2
DEFINE_BASECLASS("arccw_kraken_nade_base")

local glowMat = Material("sprites/light_glow02_add")
local toxicMat = Material("sprites/glow04_noz")

function ENT:Initialize()
    if SERVER then
        BaseClass.Initialize(self)
        self:SetModel(self.Model)
        self:DrawShadow(true)
        local phys = self:GetPhysicsObject()
        if phys:IsValid() then phys:SetBuoyancyRatio(0) end
        timer.Simple(self.FuseTime, function() if IsValid(self) then self:Detonate() end end)
        self:EmitSound("kraken/explosives/dioxis/beep.wav")
        util.SpriteTrail(self, 0, Color(255, 80, 80, 150), false, 8, 2, 0.3, 1 / 8, "trails/laser")
    end
    self.GasReleased = false
end

function ENT:PhysicsCollide(data, physobj)
    if not SERVER then return end
    if data.Speed > 45 then self:EmitSound("ArcCW_Kraken.Explosives.Bounce") end
end

function ENT:Think()
    ArcCW_Kraken_GrenadeEntitySweep(self)
end

function ENT:Detonate()
    if self.Defused then return end
    self.Defused = true
    self.GasReleased = true
    self:SetNWBool("GasReleased", true)
    if self:WaterLevel() >= 1 then
        self:EmitSound("kraken/explosives/dioxis/start" .. math.random(1, 4) .. ".wav", 75, 100, 0.3, CHAN_AUTO)
        self:Remove()
    else
        self:DoDetonate()
    end
end

function ENT:DoDetonate()
    if self:WaterLevel() > 0 then self:Remove() return end
    local attacker = self.Attacker or self:GetOwner() or self
    local cloud = ents.Create("arccw_dioxis_spawned")
    if IsValid(cloud) then
        cloud:SetPos(self:GetPos())
        cloud:SetAngles(self:GetAngles())
        cloud:SetOwner(attacker)
        cloud:Spawn()
        cloud:EmitSound("kraken/explosives/dioxis/start" .. math.random(1, 4) .. ".wav", 125, 100, 0.3, CHAN_AUTO)
        cloud:SetParent(self)
        cloud.NoIgnite = self
    end
    self:EmitSound("kraken/explosives/dioxis/start" .. math.random(1, 4) .. ".wav", 125, 100, 0.3, CHAN_AUTO)
    ParticleEffectAttach("AC_nade_gas_ejection", PATTACH_POINT_FOLLOW, self, 0)
    SafeRemoveEntityDelayed(self, 18)
end

function ENT:Draw()
    if CLIENT then
        self:DrawModel()
        local gasReleased = self:GetNWBool("GasReleased", false)
        if gasReleased then
            local pulse = 0.6 + math.sin(CurTime() * 6) * 0.4
            local glowSize = 25 * pulse
            
            render.SetMaterial(toxicMat)
            render.DrawSprite(self:GetPos(), glowSize * 2, glowSize * 2, Color(100, 180, 80, 100 * pulse))
            
            render.SetMaterial(glowMat)
            render.DrawSprite(self:GetPos(), glowSize, glowSize, Color(100, 180, 80, 150 * pulse))
            
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                dlight.pos = self:GetPos()
                dlight.r = 100
                dlight.g = 180
                dlight.b = 80
                dlight.brightness = 2 * pulse
                dlight.decay = 500
                dlight.size = 150
                dlight.dietime = CurTime() + 0.1
            end
        else
            local pulse = 0.8 + math.sin(CurTime() * 10) * 0.2
            local glowSize = 12 * pulse
            
            render.SetMaterial(glowMat)
            render.DrawSprite(self:GetPos(), glowSize, glowSize, Color(100, 180, 80, 150 * pulse))
            
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                dlight.pos = self:GetPos()
                dlight.r = 100
                dlight.g = 180
                dlight.b = 80
                dlight.brightness = 1.5 * pulse
                dlight.decay = 1000
                dlight.size = 80
                dlight.dietime = CurTime() + 0.1
            end
        end
    end
end