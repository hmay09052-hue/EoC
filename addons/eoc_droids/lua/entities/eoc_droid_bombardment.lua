AddCSLuaFile()

-- Markierung fuer ein Raketen-Bombardement (Event-Werkzeug fuer Admins)
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Droiden-Bombardement"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.Rockets = 15
ENT.Spread = 700

function ENT:Initialize()
    if CLIENT then return end

    self:SetModel("models/props_borealis/bluebarrel001.mdl")
    self:SetNoDraw(true)
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)

    local pos = self:GetPos()
    for i = 1, self.Rockets do
        timer.Simple(i * 0.2, function()
            local target = pos + Vector(math.Rand(-self.Spread, self.Spread), math.Rand(-self.Spread, self.Spread), 0)
            local tr = util.TraceLine({ start = target + Vector(0, 0, 50), endpos = target + Vector(0, 0, 4000), mask = MASK_SOLID_BRUSHONLY })
            local start = tr.Hit and tr.HitPos - Vector(0, 0, 40) or target + Vector(0, 0, 4000)

            local rocket = ents.Create("eoc_droid_missile")
            if not IsValid(rocket) then return end
            rocket:SetPos(start)
            rocket:SetAngles((target - start):Angle())
            rocket:Spawn()
        end)
    end

    SafeRemoveEntityDelayed(self, self.Rockets * 0.2 + 1)
end
