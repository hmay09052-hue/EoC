AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Kraken's Field Medbay"
ENT.Category = "Kraken's Medical"
ENT.Spawnable = false
ENT.DisableDuplicator = true

function ENT:Initialize()
    if CLIENT then return end
    self:SetModel(KrakensMedical.Settings.npcModels.medbay)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        KrakensMedical.PackMedbay(activator, self)
    end

    return
end

local AID = "krakens_medical"

function ENT:Draw()
    self:DrawModel()
    if not KF then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:GetPos():DistToSqr(self:GetPos()) > 260000 then return end
    local pos = self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 12)
    local ang = Angle(0, (ply:GetPos() - pos):Angle().y + 90, 90)
    cam.Start3D2D(pos, ang, 0.1)
        draw.SimpleText(string.upper(KrakensMedical.L("medbay_title")), KF.Fonts.GetBold(AID, "header"), 0, 0, KF.UI.GetColor("Accent", AID), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local owner = self:GetNWString("kms_medbay_owner", "")
        if owner ~= "" then
            draw.SimpleText(owner, KF.Fonts.Get(AID, "body"), 0, 34, KF.UI.GetColor("TextPrimary", AID), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
end
