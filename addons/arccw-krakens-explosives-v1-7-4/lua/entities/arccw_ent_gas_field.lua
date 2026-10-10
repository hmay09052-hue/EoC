AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Toxic Gas Field"
ENT.Spawnable = false

local Duration = 30
local Radius = 640

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetNoDraw(true)
    self:SetNotSolid(true)
    if not SERVER then return end
    self.DieTime = CurTime() + Duration
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    local repFil = RecipientFilter()
    repFil:AddAllPlayers()
    self.SoundLoop = CreateSound(self, "Kraken_Explosives.DioxisLoop", repFil)
    if self.SoundLoop then 
        self.SoundLoop:Play()
    end
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("custom_toxic_gas", effectdata, true, true)
    sound.EmitHint(SOUND_DANGER, self:GetPos(), Radius * 2, Duration, nil)
    self:NextThink(CurTime())
end

function ENT:Think()
    if not SERVER then return end
    if CurTime() > (self.DieTime - 2) then
        self:StopGas()
    end
    if CurTime() > (self.DieTime or 0) then
        if self.SoundLoop then self.SoundLoop:Stop() end
        self:Remove()
        return false
    end
    self:DoEffect()
    self:NextThink(CurTime() + 1)
    return true
end

ENT.bStoppedGas = false

function ENT:StopGas()
    if self.bStoppedGas then return end
    self.bStoppedGas = true
    
    if self.SoundLoop then
        self.SoundLoop:Stop()
    end
    
    self:StopParticles()
end
local string_lower = string.lower
local string_find = string.find
local math_Clamp = math.Clamp
local math_Rand = math.Rand
function ENT:DoEffect()
    local pos_self = self:GetPos()
    local entities = ents.FindInSphere(pos_self, Radius)
    local curtime = CurTime()
    for _, ent in ipairs(entities) do
        if not (ent:IsNPC() or ent:IsPlayer()) then continue end
        if ent:IsNPC() and string_find(string_lower(ent:GetClass()), "droid", 1, true) then continue end
        local dist = pos_self:Distance(ent:GetPos())
        local frac = 1 - math_Clamp(dist / Radius, 0, 1)
        if frac > 0 then
            local dmg = DamageInfo()
            dmg:SetDamage(math_Clamp(15 * frac, 3, 15))
            dmg:SetDamageType(DMG_POISON)
            dmg:SetAttacker(self)
            ent:TakeDamageInfo(dmg)
        end
        if frac > 0.25 and (not ent._LastGasCough or curtime > ent._LastGasCough) then
            ent._LastGasCough = curtime + math_Rand(4, 8) * (1 - frac) + 1
            local pitch = 90 + frac * 20
            ent:EmitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 70, pitch)
        end
    end
end

function ENT:OnRemove()
    if SERVER then
        self:StopGas()
    end
end