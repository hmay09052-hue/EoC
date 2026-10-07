AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local C = GRNStore and GRNStore.Config

function ENT:Initialize()
    if not C then return end

    self:SetModel(C.Entity.Model)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetUseType(SIMPLE_USE)
    self:SetCollisionGroup(COLLISION_GROUP_NPC)

    local mins, maxs = self:GetModelBounds()
    if mins and maxs then
        self:SetCollisionBounds(mins, maxs)
    end

    self:ResetIdleSequence()
end

function ENT:ResetIdleSequence()
    if not C then return end

    local seq = self:LookupSequence(C.Entity.IdleSequence or "")
    if seq and seq >= 0 then
        self:ResetSequence(seq)
        self:SetCycle(0)
        self:SetPlaybackRate(C.Entity.PlaybackRate or 1)
        return
    end

    local fallback = self:SelectWeightedSequence(ACT_IDLE)
    if fallback and fallback >= 0 then
        self:ResetSequence(fallback)
        self:SetCycle(0)
        self:SetPlaybackRate(C.Entity.PlaybackRate or 1)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not GRNStore or not GRNStore.OpenForPlayer then return end
    GRNStore.OpenForPlayer(activator, self)
end

function ENT:Think()
    if not C then return end

    if self:GetSequence() < 0 or self:GetCycle() >= 0.995 then
        self:ResetIdleSequence()
    end

    self:NextThink(CurTime() + 0.1)
    return true
end

function ENT:OnTakeDamage()
    return 0
end
