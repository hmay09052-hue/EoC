--[[
    EoC Range – Ranglisten-Wand
    Wanddisplay mit Top 10 und Einheitenwertung, blättert automatisch durch die Disziplinen.
]]
AddCSLuaFile()

ENT.Base      = "range_base"
ENT.PrintName = "Ranglisten-Wand"
ENT.Category  = "EoC Range"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RangeKind = "board"

function ENT:SetupRangeVars()
    self:NetworkVar("String", 0, "Disciplines", { KeyName = "disciplines", Edit = { type = "Generic", order = 2, title = "Angezeigte Disziplinen (IDs mit Komma, leer = alle)" } })
    self:NetworkVar("String", 1, "Period", { KeyName = "period", Edit = { type = "Combo", order = 3, title = "Zeitraum", values = { ["Allzeit"] = "all", ["Monat"] = "month", ["Woche"] = "week" } } })
    self:NetworkVar("Int", 1, "Width", { KeyName = "width", Edit = { type = "Int", order = 4, min = 64, max = 400, title = "Breite (Units)" } })
end

function ENT:InitDefaults()
    if self:GetPeriod() == "" then self:SetPeriod("week") end
    if self:GetWidth() < 64 then self:SetWidth(140) end
end

function ENT:BoxKey()
    return tostring(self:GetWidth())
end

function ENT:Dimensions()
    local w = math.max(self:GetWidth(), 64)
    return w, w * 0.5625
end

function ENT:GetBox()
    local w, h = self:Dimensions()
    return Vector(-1, -w / 2, 0), Vector(1, w / 2, h)
end

function ENT:DisciplineList()
    local raw = self:GetDisciplines() or ""
    local out = {}
    for id in string.gmatch(raw, "[^,%s]+") do
        if EoCRange.GetDiscipline(id) then out[#out + 1] = id end
    end
    if #out == 0 then
        for _, d in ipairs(EoCRange.AllDisciplines()) do out[#out + 1] = d.id end
    end
    return out
end

if SERVER then
    function ENT:SpawnFunction(ply, tr, className)
        if not tr.Hit then return end
        local ent = ents.Create(className)
        ent:SetWidth(140)
        local _, h = 140, 140 * 0.5625
        if math.abs(tr.HitNormal.z) > 0.7 then
            ent:SetPos(tr.HitPos)
            ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
        else
            local ang = tr.HitNormal:Angle()
            ang.p, ang.r = 0, 0
            ent:SetPos(tr.HitPos + tr.HitNormal * 2 - Vector(0, 0, h / 2))
            ent:SetAngles(ang)
        end
        ent:Spawn()
        ent:Activate()
        return ent
    end
else
    function ENT:Draw()
        if EoCRange.DrawBoard then EoCRange.DrawBoard(self) end
    end
end
