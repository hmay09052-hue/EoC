AddCSLuaFile()

ENT.Base = "npc_eoc_bx"
ENT.PrintName = "BX Kommandodroide Captain"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Anfuehrer: verstaerkt Droiden in der Naehe (Feuerrate + Panzerung) und ruft weit Verstaerkung.
ENT.Model = { "models/npc/bx100_commando_droid/captain/bx100_commando_droid_captain.mdl", "models/npc/bx100_commando_droid/regular/bx100_commando_droid_regular.mdl", "models/sally/tkaro/bx_commando_droid.mdl" }
ENT.HP = 280
ENT.DamageScale = 0.85
ENT.AlertRadius = 2000
ENT.Tint = Color(255, 235, 190)
ENT.NameTagColor = Color(220, 170, 30, 230)

ENT.BuffRadius = 650

if SERVER then
    function ENT:EveryThreeSeconds()
        if not self:HasEnemy() then return end

        local buffed = 0
        EOCDroids.ForEachNear(self:GetPos(), self.BuffRadius, function(droid)
            droid.BuffUntil = CurTime() + 4
            buffed = buffed + 1
        end)

        if buffed <= 1 then return end

        self:SetNW2Bool("EOCPulse", true)
        timer.Simple(0.8, function()
            if IsValid(self) then self:SetNW2Bool("EOCPulse", false) end
        end)
    end
else
    local ringCol = Color(70, 140, 255, 90)

    function ENT:DrawExtras()
        self:DrawPulseRing(ringCol, self.BuffRadius)
    end
end
