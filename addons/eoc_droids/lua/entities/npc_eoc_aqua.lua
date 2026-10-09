AddCSLuaFile()

ENT.Base = "eoc_droid_base"
ENT.PrintName = "Aqua-Droide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Amphibischer Droide mit Mehrfachblaster und Ionen-Entladung, die mehrere Gegner trifft.
ENT.Model = "models/player/valley/aquadroid/aquadroid.mdl"
ENT.Weapon = "aqua"
ENT.HP = 180
ENT.Scale = 1.15
ENT.ShootingRange = 1000
ENT.LooseRadius = 2400
ENT.Inaccuracy = 0.2
ENT.Speed = 100

ENT.MaxZapTargets = 5
ENT.ZapDamage = 13
ENT.ZapTicks = 10

ENT.NameTagColor = Color(0, 140, 200, 230)

-- Eigene Skelette: Sequenz-Namen haben Vorrang vor Aktivitaeten
ENT.PreferSequences = true

ENT.Anims = {
    ["idle"] = { "idlepackage", "idle_all_01" },
    ["shoot"] = { "idlepackage" },
    ["reload"] = { "takepackage" },
    ["walk_slow"] = { "walk_holding_package_all", "walk_all_Moderate", "walk_all" },
    ["walk_fast"] = { "run_all" },
}

if SERVER then
    function ENT:OnCombatThink(enemy, dist, visible, now)
        self.NextZap = self.NextZap or now + math.Rand(4, 8)
        if not visible or now < self.NextZap or math.random() > 0.08 then return false end

        self.NextZap = now + math.Rand(10, 16)
        self:IonDischarge()
        return false
    end

    function ENT:IonDischarge()
        self.DisableShooting = true
        self:StopMoving()
        self:PlaySound("summe/nextbots/weapons/aqua/blasters_relby-v10_bossk_charge_var_02.mp3", 90, 100, "ambient/energy/whiteflash.wav")

        timer.Simple(1, function()
            if not IsValid(self) then return end

            local origin = self:GetPos() + Vector(0, 0, 160 * self:GetModelScale() / 1.15)
            local targets = {}

            for _, ply in RandomPairs(EOCDroids.PlayersInSphere(self:GetPos(), self.ShootingRange)) do
                if #targets >= self.MaxZapTargets then break end
                if self:IsValidTarget(ply) then
                    local tr = util.TraceLine({ start = origin, endpos = EOCDroids.TargetPos(ply), filter = self, mask = MASK_SHOT })
                    if tr.Entity == ply or not tr.Hit then
                        targets[#targets + 1] = ply
                        ply:ScreenFade(SCREENFADE.IN, color_white, 0.6, 0.4)
                    end
                end
            end

            self:PlaySound("summe/nextbots/weapons/aqua/blaster_iondisruptor_laser_addon_close_var_0" .. math.random(4, 8) .. ".mp3", 95, 100, "ambient/energy/zap" .. math.random(1, 9) .. ".wav")

            local timerName = "EOCDroids.AquaZap." .. self:EntIndex()
            timer.Create(timerName, 0.1, self.ZapTicks, function()
                if not IsValid(self) then
                    timer.Remove(timerName)
                    return
                end
                for _, ply in ipairs(targets) do
                    if IsValid(ply) and ply:Alive() then
                        local d = DamageInfo()
                        d:SetDamage(self.ZapDamage * EOCDroids.Config.DamageMultiplier)
                        d:SetAttacker(self)
                        d:SetInflictor(self)
                        d:SetDamageType(DMG_SHOCK)
                        ply:TakeDamageInfo(d)
                    end
                end
            end)

            net.Start("EOCDroids.AquaZap")
            net.WriteEntity(self)
            net.WriteUInt(#targets, 4)
            for _, ply in ipairs(targets) do
                net.WriteEntity(ply)
            end
            net.SendPVS(self:GetPos())

            timer.Simple(2, function()
                if not IsValid(self) then return end
                self.DisableShooting = false
                self:PlaySound("summe/nextbots/weapons/aqua/blasters_deathray_charge_start_var_01.mp3", 80)
            end)
        end)
    end

    function ENT:OnDroidRemoved()
        timer.Remove("EOCDroids.AquaZap." .. self:EntIndex())
    end
else
    local matBeam = Material("cable/physbeam")
    local matSmall = Material("cable/blue_elec")
    local matGlow = Material("sprites/light_glow02_add")
    local glow = Color(0, 217, 255)

    function ENT:DrawExtras()
        if not self.ZapUntil or CurTime() > self.ZapUntil then return end

        local scale = self:GetModelScale() / 1.15
        local bottom = self:LocalToWorld(Vector(0, 0, 50 * scale))
        local top = self:LocalToWorld(Vector(0, 0, 160 * scale))

        render.SetMaterial(matBeam)
        render.DrawBeam(bottom, top, 40, 1, 2, color_white)
        render.SetMaterial(matGlow)
        render.DrawSprite(top, 200, 200, glow)

        EOCDroids.Light(top, glow, 300, 0.1, 3, self.ZapLight)
        self.ZapLight = self.ZapLight or EOCDroids.NextLightId()

        for _, ply in ipairs(istable(self.ZapTargets) and self.ZapTargets or {}) do
            if IsValid(ply) and ply:Alive() then
                local hit = ply:GetPos() + Vector(0, 0, math.random(10, 70))
                render.SetMaterial(matSmall)
                render.DrawBeam(top, hit, 10, 1, 5, color_white)
                render.SetMaterial(matGlow)
                render.DrawSprite(hit, 50, 50, glow)
            end
        end
    end
end
