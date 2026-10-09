AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Bacta Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_grenade_bacta.mdl"
DEFINE_BASECLASS("arccw_kraken_nade_base")

ENT.HealRadius = 300
ENT.HealInterval = 0.05
ENT.HealDuration = 30
ENT.HealAmount = 0.05
ENT.FuseTime = 2.5
ENT.ImpactDamage = 1

local glowMat = Material("sprites/light_glow02_add")
local healMat = Material("sprites/glow04_noz")

function ENT:Initialize()
    self.Delay = CurTime() + self.FuseTime
    self.IsDetonated = false
    if not SERVER then return end
    BaseClass.Initialize(self)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() phys:SetBuoyancyRatio(0) end
    self.AffectedPlayers = {}
    self:EmitSound("kraken/explosives/bactagrenade/bacta_beep.wav")
    util.SpriteTrail(self, 0, Color(35, 202, 228, 150), false, 8, 2, 0.3, 1 / 8, "trails/laser")
end
function ENT:PhysicsCollide(data)
    if not SERVER then return end
    local tgt, speed = data.HitEntity, data.Speed

    if IsValid(tgt) and not tgt:IsWorld() and (self.NextHit or 0) < CurTime() then
        self.NextHit = CurTime() + 0.1
        local dmginfo = DamageInfo()
        dmginfo:SetDamageType(DMG_CRUSH)
        dmginfo:SetDamage(self.ImpactDamage)
        dmginfo:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
        dmginfo:SetInflictor(self)
        dmginfo:SetDamageForce(data.OurOldVelocity * 0.5)
        tgt:TakeDamageInfo(dmginfo)
    end

    if speed > 25 then self:EmitSound("ArcCW_Kraken.Explosives.Bounce")
    elseif speed < 5 and (not IsValid(tgt) or tgt:IsWorld()) then
        timer.Simple(0, function() if IsValid(self) then self:SetMoveType(MOVETYPE_NONE) end end)
    end
end
local function RegeneratePlayer(ply, ent)
    if not IsValid(ply) or not ply:Alive() then return end
    if not IsValid(ent) then return end
    
    local id = "HealthRegen_" .. ply:EntIndex() .. "_" .. ent:EntIndex()
    if timer.Exists(id) then return end
    
    local interval = ent.HealInterval
    local reps = ent.HealDuration / interval
    local amount = ent.HealAmount
    
    timer.Create(id, interval, reps, function()
        if not IsValid(ply) or not ply:Alive() then
            timer.Remove(id)
            return
        end
        local maxHP = ply:GetMaxHealth()
        local curHP = ply:Health()
        if curHP < maxHP then
            ply:SetHealth(math.min(curHP + maxHP * amount, maxHP))
        end
    end)
end
function ENT:Think()
    if not SERVER then return end
    ArcCW_Kraken_GrenadeEntitySweep(self)
    
    if not self.IsDetonated then
        if CurTime() >= self.Delay then
            self:Detonate()
            self.IsDetonated = true
        end
        self:NextThink(CurTime() + 0.1)
        return true
    end
    
    local myPos = self:GetPos()
    local r2 = self.HealRadius * self.HealRadius
    local players = player.GetAll()
    
    for i = 1, #players do
        local ply = players[i]
        if not self.AffectedPlayers[ply] and IsValid(ply) and ply:Alive() then
            if ply:GetPos():DistToSqr(myPos) <= r2 then
                self.AffectedPlayers[ply] = true
                RegeneratePlayer(ply, self)
            end
        end
    end
    
    self:NextThink(CurTime() + 0.2)
    return true
end
function ENT:Detonate()
    if not SERVER or not IsValid(self) or self.Defused then return end
    self.Defused = true
    self:SetNWBool("IsDetonated", true)
    self:EmitSound("kraken/explosives/bactagrenade/bacta_grenade.mp3", 125)
    local gas = EffectData()
    gas:SetOrigin(self:GetPos())
    gas:SetEntity(IsValid(self:GetOwner()) and self:GetOwner() or self)
    util.Effect("arccw_bacta_cloud", gas)
    self:SetMoveType(MOVETYPE_NONE)
    SafeRemoveEntityDelayed(self, self.HealDuration + 2)
end
function ENT:OnRemove()
    if not SERVER then return end
    
    local entIdx = self:EntIndex()
    local players = player.GetAll()
    
    for i = 1, #players do
        local ply = players[i]
        local tid = "HealthRegen_" .. ply:EntIndex() .. "_" .. entIdx
        if timer.Exists(tid) then
            timer.Remove(tid)
        end
    end
end
function ENT:DrawTranslucent()
    self:Draw()
end
function ENT:Draw()
    self:DrawModel()
    if CLIENT then
        local isActive = self:GetNWBool("IsDetonated", false)
        if isActive then
            local pulse = 0.6 + 0.4 * math.sin(CurTime() * 4)
            render.SetMaterial(healMat)
            local healSize = 35 * pulse
            render.DrawSprite(self:GetPos(), healSize, healSize, Color(0, 220, 180, 150 * pulse))
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                dlight.pos = self:GetPos()
                dlight.r = 0
                dlight.g = 220
                dlight.b = 180
                dlight.brightness = 3 * pulse
                dlight.decay = 500
                dlight.size = 200
                dlight.dietime = CurTime() + 0.1
            end
        else
            local pulse = 0.8 + 0.2 * math.sin(CurTime() * 8)
            render.SetMaterial(glowMat)
            local coreSize = 12 * pulse
            render.DrawSprite(self:GetPos(), coreSize, coreSize, Color(0, 200, 180, 150 * pulse))
            local dlight = DynamicLight(self:EntIndex())
            if dlight then
                dlight.pos = self:GetPos()
                dlight.r = 0
                dlight.g = 200
                dlight.b = 180
                dlight.brightness = 1.5 * pulse
                dlight.decay = 1000
                dlight.size = 80
                dlight.dietime = CurTime() + 0.1
            end
        end
    end
end