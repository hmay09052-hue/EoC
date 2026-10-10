AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "EMP Field"
ENT.Spawnable = false

local Duration = 30
local Radius = 500

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetNoDraw(true)
    self:SetNotSolid(true)

    if SERVER then
        self.DieTime = CurTime() + Duration
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self.SoundLoop = CreateSound(self, "ambient/energy/electric_loop.wav")
        if self.SoundLoop then self.SoundLoop:PlayEx(0.4, 100) end
        self:NextThink(CurTime())
    end

    if CLIENT then self.NextVisual, self.NextLightning = 0, 0 end
end

function ENT:Think()
    if SERVER then
        if CurTime() > (self.DieTime or 0) then
            if self.SoundLoop then self.SoundLoop:Stop() end
            self:Remove()
            return false
        end
        self:DoEffect()
        self:NextThink(CurTime() + 0.5)
        return true
    end

    if CLIENT then
        if CurTime() > (self.NextVisual or 0) then self:CreateSmokeCloud() self.NextVisual = CurTime() + 0.3 end
        if CurTime() > (self.NextLightning or 0) then self:CreateElectricBolts() self.NextLightning = CurTime() + 0.15 end
    end
    return true
end

function ENT:CreateSmokeCloud()
    local emitter = ParticleEmitter(self:GetPos())
    if not emitter then return end

    for i = 1, 10 do
        local pos = self:GetPos() + VectorRand() * Radius
        local p = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), pos)
        if p then
            p:SetVelocity(VectorRand() * 10)
            p:SetDieTime(4)
            p:SetStartAlpha(50)
            p:SetEndAlpha(0)
            p:SetStartSize(60)
            p:SetEndSize(120)
            p:SetColor(100, 180, 255)
            p:SetAirResistance(60)
            p:SetLighting(false)
        end
    end

    emitter:Finish()
end

function ENT:CreateElectricBolts()
    local emitter = ParticleEmitter(self:GetPos())
    if not emitter then return end

    for _ = 1, 6 do
        local startPos = self:GetPos() + VectorRand() * Radius
        local endPos = startPos + VectorRand() * 60

        local beam = emitter:Add("sprites/physbeam", startPos)
        if beam then
            beam:SetDieTime(0.12)
            beam:SetStartAlpha(255)
            beam:SetEndAlpha(0)
            beam:SetStartSize(6)
            beam:SetEndSize(0)
            beam:SetColor(100, 200, 255)
            beam:SetVelocity(Vector(0, 0, 0))
        end

        local spark = EffectData()
        spark:SetOrigin(endPos)
        util.Effect("ManhackSparks", spark, true, true)
    end

    emitter:Finish()
end

local string_lower = string.lower
local string_find = string.find

function ENT:DoEffect()
    local attacker = IsValid(self:GetOwner()) and self:GetOwner() or self
    local pos_self = self:GetPos()

    for _, ent in ipairs(ents.FindInSphere(pos_self, Radius)) do
        if not ent:IsNPC() then continue end

        local name = string_lower(ent:GetClass())
        if string_find(name, "droid", 1, true) then
            if not ent._IsRagdolled then
                local pos = ent:GetPos() + Vector(0, 0, 40)
                hook.Run("OnNPCKilled", ent, attacker, self)

                local ed = EffectData()
                ed:SetOrigin(pos)
                ed:SetNormal(Vector(0, 0, 1))
                ed:SetMagnitude(2)
                ed:SetScale(2)
                ed:SetColor(0)
                util.Effect("WheelDust", ed)
                util.Decal("Scorch", pos + Vector(0, 0, 10), pos - Vector(0, 0, 10), self)

                local rag = ents.Create("prop_ragdoll")
                rag:SetModel(ent:GetModel())
                rag:SetPos(ent:GetPos())
                rag:SetAngles(ent:GetAngles())
                rag:Spawn()
                rag._IsRagdolled = true
                rag:SetNWBool("Electrified", true)

                timer.Simple(5, function()
                    if IsValid(rag) then
                        rag:SetNWBool("Electrified", false)
                    end
                end)

                ent:Remove()
            end
        else
            local dmg = DamageInfo()
            dmg:SetDamage(5)
            dmg:SetDamageType(DMG_SHOCK)
            dmg:SetAttacker(attacker)
            ent:TakeDamageInfo(dmg)
        end
    end
end

function ENT:OnRemove()
    if SERVER and self.SoundLoop then
        self.SoundLoop:Stop()
    end
end
