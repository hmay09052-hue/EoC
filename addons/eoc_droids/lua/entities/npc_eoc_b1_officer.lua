AddCSLuaFile()

ENT.Base = "npc_eoc_b1"
ENT.PrintName = "B1 Offiziersdroide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Unterstuetzung: repariert beschaedigte Droiden in der Naehe und koordiniert den Trupp.
ENT.Model = "models/npc/b1_battledroids/officer/b1_battledroid_officer.mdl"
ENT.Weapon = "rg4d"
ENT.HP = 85
ENT.ShootingRange = 900
ENT.Inaccuracy = 0.18
ENT.AlertRadius = 1600
ENT.ThrowGrenades = false
ENT.StrafeChance = 0.03
ENT.NameTagColor = Color(200, 120, 0, 230)

ENT.RepairRadius = 500
ENT.RepairAmount = 0.2   -- Anteil der Max-HP pro Puls

if SERVER then
    function ENT:EveryThreeSeconds()
        local repaired = 0

        EOCDroids.ForEachNear(self:GetPos(), self.RepairRadius, function(droid)
            if droid == self or droid.IsDead then return end
            local hp, maxHp = droid:Health(), droid:GetMaxHealth()
            if hp <= 0 or hp >= maxHp then return end

            droid:SetHealth(math.min(hp + maxHp * self.RepairAmount, maxHp))

            local ed = EffectData()
            ed:SetOrigin(droid:WorldSpaceCenter())
            util.Effect("ManhackSparks", ed)
            droid:EmitSound("items/ammo_pickup.wav", 65)

            repaired = repaired + 1
        end)

        if repaired <= 0 then return end

        self:Speak("attacking", 0.3)
        self:SetNW2Bool("EOCPulse", true)
        timer.Simple(0.8, function()
            if IsValid(self) then self:SetNW2Bool("EOCPulse", false) end
        end)
    end
else
    local ringCol = Color(255, 160, 40, 90)

    function ENT:DrawExtras()
        self:DrawPulseRing(ringCol, self.RepairRadius)
    end
end
