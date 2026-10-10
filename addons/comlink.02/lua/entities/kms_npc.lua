AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Kraken's Medical NPC"
ENT.Category = "Kraken's Medical"
ENT.Spawnable = true
ENT.DisableDuplicator = true

local function Record(self)
    local KMS = KrakensMedical
    if not (KMS and KMS.NPCs) then return nil end
    return KMS.NPCs[self:GetNWString("kms_npc_id", "")]
end

function ENT:Initialize()
    if CLIENT then return end
    local npc = Record(self)
    self:SetModel(npc and npc.model or "models/kleiner.mdl")
    self:PhysicsInit(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetUseType(SIMPLE_USE)
    local idle = self:LookupSequence("idle_all_01")
    if idle and idle > 0 then self:ResetSequence(idle) end
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if KrakensMedical and KrakensMedical.NPCUse then
            KrakensMedical.NPCUse(self, activator)
        end
    end

    return
end

local AID = "krakens_medical"
local TYPE_HINTS = { supply = "npc_hint_supply", billing = "npc_hint_billing", simulator = "npc_hint_simulator", exam = "npc_hint_exam" }

function ENT:Draw()
    self:DrawModel()
    local npc = Record(self)
    if not npc or not KF then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:GetPos():DistToSqr(self:GetPos()) > 260000 then return end
    local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 12)
    local ang = Angle(0, (ply:GetPos() - pos):Angle().y + 90, 90)
    cam.Start3D2D(pos, ang, 0.1)
        draw.SimpleText(string.upper(npc.name), KF.Fonts.GetBold(AID, "header"), 0, 0, KF.UI.GetColor("Accent", AID), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(KrakensMedical.L(TYPE_HINTS[npc.npcType] or "npc_hint_supply"), KF.Fonts.Get(AID, "body"), 0, 34, KF.UI.GetColor("TextPrimary", AID), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end
