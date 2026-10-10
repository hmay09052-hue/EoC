--[[
    EoC Range – Geiselziel (Klon-Silhouette). Ein Treffer gibt Strafpunkte bzw. Strafsekunden.
]]
AddCSLuaFile()

ENT.Base      = "range_popup"
ENT.PrintName = "Geiselziel"
ENT.Category  = "EoC Range"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RangeKind = "hostage"
ENT.IsHostage = true

function ENT:SetupExtraVars()
    self:NetworkVar("Int", 5, "PenaltyPoints", { KeyName = "penaltypoints", Edit = { type = "Int", order = 6, min = 0, max = 1000, title = "Strafe Punkte (0 = Standard)" } })
    self:NetworkVar("Int", 6, "PenaltySecs", { KeyName = "penaltysecs", Edit = { type = "Int", order = 7, min = 0, max = 60, title = "Strafe Sekunden (0 = Standard)" } })
end

function ENT:Shape()
    return EoCRange.Config.HostageSilhouette
end

function ENT:BoxKey()
    return "hostage"
end

function ENT:PenaltyPointsValue()
    local v = self:GetPenaltyPoints()
    return v > 0 and v or EoCRange.Config.HostagePenaltyPoints
end

function ENT:PenaltySecsValue()
    local v = self:GetPenaltySecs()
    return v > 0 and v or EoCRange.Config.HostagePenaltySecs
end
