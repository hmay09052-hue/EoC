AddCSLuaFile()

DEFINE_BASECLASS("eoc_droid_base")

ENT.Base = "eoc_droid_base"
ENT.PrintName = "IG-100 MagnaGuard"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Elite-Leibwache mit Elektrostab. Wehrt Blasterfeuer von vorne ab und
-- steht manchmal kopflos wieder auf.
ENT.Model = { "models/tfa/comm/gg/npc_reb_magna_guard_combined.mdl", "models/npc_mag_base/npc_droid_mag_base_f.mdl" }
ENT.FallbackModel = "models/combine_super_soldier.mdl"
ENT.Weapon = "magnastaff"
ENT.HP = 500
ENT.Scale = 1.05
ENT.DamageScale = 0.8
ENT.LooseRadius = 2500
ENT.Speed = 140
ENT.RunMultiplier = 2.4

ENT.Melee = true
ENT.MeleeDamage = 45
ENT.MeleeDelay = 1.4
ENT.MeleeRange = 72
ENT.MeleeKnockback = 1100
ENT.MeleeDamageType = DMG_SHOCK
ENT.MeleeFadeColor = Color(234, 72, 255, 60)
ENT.MeleeSounds = {
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_01.mp3",
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_02.mp3",
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_03.mp3",
    "summe/nextbots/droids/magna/damage_recieved_lightning_killed_var_04.mp3",
}

ENT.CanDodge = true
ENT.DodgeChance = 0.2
ENT.DeflectChance = 0.35
ENT.ResurrectChance = 0.3

ENT.NameTagColor = Color(150, 0, 0, 230)

ENT.Anims = {
    ["idle"] = { "idle_all_01", "idle_alert_smg1_1", "idle_subtle" },
    ["shoot"] = { "idle_alert_smg1_1" },
    ["reload"] = { "idle_all_01" },
    ["walk_slow"] = { "walk_all", "walkAIMALL1", "walkHOLDALL1_ar2" },
    ["walk_fast"] = { "run_protected_all", "run_all", "run_alert_holding_all" },
    ["melee"] = { "MeleeAttack01", "swing" },
}

if SERVER then
    function ENT:OnDroidSpawn()
        if self.Resurrected then
            self:SetNW2Bool("EOCResurrected", true)
            self:SetHealth(math.ceil(self:GetMaxHealth() * 0.5))
            self:SetBodygroup(1, 0)
        else
            self:SetBodygroup(1, 1)
        end
    end

    -- Blasterfeuer von vorne mit dem Stab abwehren
    function ENT:ScaleIncomingDamage(dmg)
        if not dmg:IsExplosionDamage() and math.random() < self.DeflectChance then
            local attacker = dmg:GetAttacker()
            if IsValid(attacker) then
                local toAttacker = (attacker:GetPos() - self:GetPos()):GetNormalized()
                if self:GetForward():Dot(toAttacker) > 0.6 then
                    dmg:ScaleDamage(0)
                    local ed = EffectData()
                    ed:SetOrigin(self:GetMuzzlePos())
                    ed:SetNormal(toAttacker)
                    ed:SetMagnitude(2)
                    ed:SetScale(1)
                    ed:SetRadius(3)
                    util.Effect("Sparks", ed)
                    self:PlaySound("weapons/stunstick/stunstick_impact" .. math.random(1, 2) .. ".wav", 75)
                    return
                end
            end
        end
        BaseClass.ScaleIncomingDamage(self, dmg)
    end

    function ENT:OnDroidKilled(dmg)
        if self:GetNW2Bool("EOCResurrected", false) or math.random() > self.ResurrectChance then
            return false
        end

        -- Faellt um ... und steht ohne Kopf wieder auf
        local rag = ents.Create("prop_ragdoll")
        if not IsValid(rag) then return false end

        rag:SetModel(self:GetModel())
        rag:SetPos(self:GetPos())
        rag:SetAngles(self:GetAngles())
        rag:SetModelScale(self:GetModelScale(), 0)
        rag:Spawn()
        rag:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

        local class = self:GetClass()
        self:Remove()

        timer.Simple(3, function()
            if not IsValid(rag) then return end

            local pos = rag:GetPos()
            local ed = EffectData()
            ed:SetOrigin(pos)
            ed:SetMagnitude(4)
            ed:SetScale(2)
            ed:SetRadius(6)
            util.Effect("Sparks", ed)
            rag:EmitSound("ambient/energy/zap" .. math.random(1, 9) .. ".wav", 80)

            local droid = ents.Create(class)
            if IsValid(droid) then
                droid.Resurrected = true
                droid:SetPos(pos + Vector(0, 0, 10))
                droid:Spawn()
                droid:Activate()
            end

            rag:Remove()
        end)

        return true
    end
else
    local purple = Color(148, 0, 148, 230)

    function ENT:GetNameTagColor()
        if self:GetNW2Bool("EOCResurrected", false) then return purple end
        return self.NameTagColor
    end
end
