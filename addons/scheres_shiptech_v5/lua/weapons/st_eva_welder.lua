--[[
    ShipTech EVA – Hüllenschweißgerät
    Linksklick auf einen Ankerpunkt mit Schadensstelle: nächsten Reparaturschritt ausführen.
    Ausgabe am EVA-Spind (nur Techniker).
]]

AddCSLuaFile()

SWEP.PrintName    = "Hüllenschweißgerät"
SWEP.Author       = "ShipTech EVA"
SWEP.Category     = "ShipTech – Außeneinsatz"
SWEP.Purpose      = "Hüllenbrüche an der Außenhülle reparieren"
SWEP.Instructions = "Linksklick auf den Ankerpunkt: nächster Reparaturschritt"
SWEP.Spawnable    = true
SWEP.AdminOnly    = true

SWEP.ViewModel    = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel   = "models/weapons/w_stunbaton.mdl"
SWEP.UseHands     = true
SWEP.Slot         = 5
SWEP.SlotPos      = 3
SWEP.DrawAmmo     = false

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

function SWEP:Initialize()
    self:SetHoldType("pistol")
end

local function Aim(owner)
    local tr = owner:GetEyeTrace()
    local e = tr.Entity
    if IsValid(e) and e:GetClass() == "shiptech_eva_anchor" and tr.HitPos:DistToSqr(owner:GetShootPos()) < 160 * 160 then return e end
    -- großzügig: Ankerpunkt in der Nähe des Fadenkreuzes
    for _, a in ipairs(ents.FindInSphere(tr.HitPos, 60)) do
        if a:GetClass() == "shiptech_eva_anchor" and a:GetPos():DistToSqr(owner:GetShootPos()) < 180 * 180 then return a end
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.6)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    self:SendWeaponAnim(ACT_VM_HITCENTER)
    owner:SetAnimation(PLAYER_ATTACK1)
    if CLIENT then return end
    local a = Aim(owner)
    if not a then return end
    a:EmitSound(ShipTech.Config.EVA.Sounds.Weld, 60, math.random(95, 110), 0.6)
    ShipTech.EVA.WorkOnBreach(owner, a)
end

function SWEP:SecondaryAttack() end

if CLIENT then
    function SWEP:DrawHUD()
        local owner = self:GetOwner()
        local a = IsValid(owner) and Aim(owner)
        if not a then return end
        local P = ShipTech.Colors
        local x, y, w, h = ScrW() / 2 + 30, ScrH() / 2 + 20, 320, 64
        EOCUI.Cut(x, y, w, h, P.bg, 8, "br")
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(x, y, 3, h)
        local b = ShipTech.EVA.BreachAt and ShipTech.EVA.BreachAt(a:EntIndex())
        draw.SimpleText(b and ("HÜLLENBRUCH · " .. string.upper(ShipTech.EVA.SectorName(b.s))) or "ANKERPUNKT · INTAKT", "ShipTech_UIBold", x + 12, y + 16, b and P.red or P.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local sub = "Kein Schaden"
        if b then
            local steps = ShipTech.EVA.Steps({ stage = b.g, wires = b.w })
            local nxt = steps[b.d + 1]
            sub = "LMB: " .. (nxt and ShipTech.EVA.StepNames[nxt] or "abschließen") .. "  ·  " .. b.d .. "/" .. #steps
        end
        draw.SimpleText(sub, "ShipTech_UISub", x + 12, y + 42, P.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end
