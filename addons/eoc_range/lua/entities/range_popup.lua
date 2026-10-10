--[[
    EoC Range – Klappziel (Droiden-Silhouette B1, B2, BX)
    Klappt hoch, fällt bei Treffer, setzt sich zurück. Kopfzone zählt doppelt.
    Basis für Geiselziel (range_hostage) und Bewegtes Ziel (range_mover).
]]
AddCSLuaFile()

ENT.Base      = "range_base"
ENT.PrintName = "Klappziel"
ENT.Category  = "EoC Range"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RangeKind = "popup"

function ENT:SetupRangeVars()
    self:NetworkVar("Int", 1, "Silhouette", { KeyName = "silhouette", Edit = { type = "Int", order = 2, min = 1, max = 3, title = "Silhouette (1 B1, 2 B2, 3 BX)" } })
    self:NetworkVar("Int", 2, "HitPoints", { KeyName = "hitpoints", Edit = { type = "Int", order = 3, min = 1, max = 5, title = "Trefferpunkte" } })
    self:NetworkVar("Int", 3, "Distance", { KeyName = "distance", Edit = { type = "Int", order = 4, min = 0, max = 500, title = "Distanz in m (0 = egal)" } })
    self:NetworkVar("Int", 4, "Order", { KeyName = "order", Edit = { type = "Int", order = 5, min = 0, max = 99, title = "Reihenfolge (feste Abläufe)" } })
    self:NetworkVar("Bool", 0, "Up")
    self:NetworkVar("Float", 0, "FlipAt")
    if self.SetupExtraVars then self:SetupExtraVars() end
end

function ENT:InitDefaults()
    if self:GetSilhouette() < 1 then self:SetSilhouette(1) end
    if self:GetHitPoints() < 1 then self:SetHitPoints(1) end
end

function ENT:Shape()
    return EoCRange.SilhouetteDef(self:GetSilhouette())
end

function ENT:BoxKey()
    return tostring(self:GetSilhouette())
end

-- Model der Silhouette, falls eingestellt und installiert
function ENT:PickModel()
    local m = self:Shape().model
    if m and m ~= "" and util.IsValidModel(m) then return m end
    return self.BoxModel
end

-- Wird gerade ein echtes Model statt der gezeichneten Silhouette benutzt?
function ENT:UsesModel()
    local m = self:Shape().model
    return m ~= nil and m ~= "" and self:GetModel() == m
end

function ENT:GetBox()
    local s = self:Shape()
    return Vector(-1, -s.w / 2, 0), Vector(1, s.w / 2, s.h)
end

-- Weltposition -> Kopf?, horizontale Lage (-1..1), Höhe (0..1)
function ENT:Evaluate(pos)
    local s = self:Shape()
    local lp = self:WorldToLocal(pos)
    local z = math.Clamp(lp.z / s.h, 0, 1)
    return z >= EoCRange.Config.HeadZone, lp.y / (s.w / 2), z
end

-- Wie weit ist das Ziel aufgerichtet? (0 = liegt, 1 = steht) – für die Animation
function ENT:UpFraction()
    local t = math.Clamp((CurTime() - self:GetFlipAt()) / EoCRange.Config.PopupFlipTime, 0, 1)
    return self:GetUp() and t or (1 - t)
end

if SERVER then
    function ENT:PostInit()
        self:SetUp(true)
        self:SetFlipAt(0)
        self.HitsTaken = 0
    end

    function ENT:OnBoxBuilt()
        if not self:GetUp() then self:SetNotSolid(true) end
    end

    function ENT:Raise(silent)
        self.HitsTaken = 0
        self.HeadHit = false
        self.RaisedAt = CurTime()
        self.ResetAt = nil
        if not self:GetUp() then
            self:SetUp(true)
            self:SetFlipAt(CurTime())
            if not silent then self:EmitSound(EoCRange.Config.Sounds.popup, 65, 115, 0.6) end
        end
        self:SetNotSolid(false)
    end

    function ENT:Lower(resetAfter)
        if self:GetUp() then
            self:SetUp(false)
            self:SetFlipAt(CurTime())
        end
        self:SetNotSolid(true)
        self.ResetAt = resetAfter and (CurTime() + resetAfter) or nil
    end

    function ENT:RangeThink()
        if self.ResetAt and CurTime() >= self.ResetAt then
            self.ResetAt = nil
            if not (EoCRange.LaneBusy and EoCRange.LaneBusy(self:GetLane())) then self:Raise() end
        end
        if self.MoverThink then self:MoverThink() end
    end

    function ENT:OnTakeDamage(dmg)
        if not self:GetUp() then return end
        if EoCRange.OnTargetDamage then EoCRange.OnTargetDamage(self, dmg) end
    end
else
    function ENT:Draw()
        if EoCRange.DrawSilhouetteTarget then EoCRange.DrawSilhouetteTarget(self) end
    end
end
