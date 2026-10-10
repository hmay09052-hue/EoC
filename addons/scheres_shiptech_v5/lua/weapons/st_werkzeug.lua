--[[
    ShipTech – Technisches Datapad (Techniker-Werkzeug)
    Linksklick: Konsole bedienen · Rechtsklick: Schnellscan der Konsole
    Reparaturen, Diagnose, Wartung und Kalibrierung sind nur mit diesem Werkzeug in der Hand möglich.
]]

AddCSLuaFile()

local TC = ShipTech and ShipTech.Config and ShipTech.Config.Tool or {}

SWEP.PrintName    = TC.Name or "Technisches Datapad"
SWEP.Author       = "ShipTech"
SWEP.Category     = "ShipTech – Schiffstechnik"
SWEP.Purpose      = "Werkzeug für Reparaturen, Wartung und Kalibrierung"
SWEP.Instructions = "Linksklick: Konsole bedienen · Rechtsklick: Schnellscan"
SWEP.Spawnable    = true
SWEP.AdminOnly    = true   -- Techniker bekommen es automatisch über ihren Job

SWEP.ViewModel    = TC.ViewModel or "models/swcw_items/sw_datapad_v.mdl"
SWEP.WorldModel   = TC.WorldModel or "models/swcw_items/sw_datapad.mdl"
SWEP.UseHands     = true
SWEP.ViewModelFOV = 58
SWEP.Slot         = 5
SWEP.SlotPos      = 1
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"
SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

function SWEP:Initialize()
    self:SetHoldType("slam")
end

local function AimConsole(owner)
    local tr = owner:GetEyeTrace()
    local ent = tr.Entity
    if IsValid(ent) and ent.IsShipTech and tr.HitPos:DistToSqr(owner:GetShootPos()) < 150 * 150 then
        return ent, tr
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.6)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    self:SendWeaponAnim(ACT_VM_HITCENTER)
    owner:SetAnimation(PLAYER_ATTACK1)
    if SERVER then
        local ent = AimConsole(owner)
        if ent then
            ent:EmitSound("physics/metal/metal_solid_impact_hard" .. math.random(1, 5) .. ".wav", 65, math.random(95, 110), 0.6)
            ShipTech.OpenFor(owner, ent)
        else
            owner:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 60, 100, 0.5)
        end
    end
end

-- Schnellscan: Zustand der anvisierten Konsole als Meldung
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1)
    if not SERVER then return end
    local owner = self:GetOwner()
    local ent = AimConsole(owner)
    if not ent then return end
    owner:EmitSound("buttons/blip1.wav", 60, 120, 0.5)
    if ent.SysId then
        local s = ShipTech.State.systems[ent.SysId]
        local def = ShipTech.SystemById[ent.SysId]
        local st = ShipTech.Stages[ShipTech.StageOf(s.health)]
        ShipTech.Notify(owner, def.name .. ": " .. st.name .. " · Zustand " .. math.Round(s.health) .. " % · Wartung " .. math.Round(s.maint) .. " % · Temp. " .. math.Round(s.heat) .. " % · Störungen: " .. #s.faults, 0)
    else
        ShipTech.Notify(owner, ent.PrintName .. ": keine Systemdaten.", 0)
    end
end

if CLIENT then
    -- kleine Anzeige der anvisierten Konsole
    function SWEP:DrawHUD()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local ent = AimConsole(owner)
        if not ent then return end
        local P = ShipTech.Colors
        local x, y, w, h = ScrW() / 2 + 30, ScrH() / 2 + 20, 280, 74
        ShipTech.Box(x, y, w, h, P.bg)
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(x, y, 2, h)
        draw.SimpleText(string.upper(ent.PrintName), "ShipTech_UIBold", x + 12, y + 16, P.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if ent.SysId then
            local txt, col = ShipTech.StatusInfo(ent.SysId)
            local s = ShipTech.Sys(ent.SysId)
            draw.SimpleText(txt, "ShipTech_UISub", x + 12, y + 36, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if s then
                draw.SimpleText("ZUSTAND " .. math.Round(s.health) .. " %  ·  STÖRUNGEN " .. #(s.faults or {}), "ShipTech_UISub", x + 12, y + 54, P.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
        if ent:GetNW2Float("ST_Fire", 0) > 0 then
            draw.SimpleText("BRAND!", "ShipTech_UIBold", x + w - 10, y + 16, P.red, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        draw.SimpleText("LMB BEDIENEN · RMB SCAN", "ShipTech_UISub", x + w - 10, y + 54, P.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end
