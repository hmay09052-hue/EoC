AddCSLuaFile()

ENT.Base = "eoc_droid_base"
ENT.PrintName = "LM-432 Krabbendroide"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Schwerer Angriffsdroide: springt auf Gegner und erzeugt eine Schockwelle bei der Landung.
ENT.Model = "models/npc/starwars/crabby/crabdroid.mdl"
ENT.FallbackModel = "models/antlion_guard.mdl"
ENT.Weapon = "crab"
ENT.HP = 500
ENT.HullWidth = 34
ENT.HullHeight = 60
ENT.EyeHeight = 50
ENT.MuzzleHeight = 40
ENT.DamageScale = 0.75
ENT.ShootingRange = 850
ENT.LooseRadius = 2400
ENT.Inaccuracy = 0.2
ENT.Speed = 120
ENT.RunMultiplier = 2.2

ENT.Melee = true
ENT.MeleeDamage = 45
ENT.MeleeDelay = 2.5
ENT.MeleeRange = 80

ENT.ExplodeOnDeath = true
ENT.DeathExplosionRadius = 250
ENT.DeathExplosionDamage = 45

ENT.SlamRadius = 300
ENT.SlamDamage = 55

ENT.FootstepInterval = 0.3
ENT.FootstepSounds = {
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_7.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_8.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_9.mp3",
    "summe/nextbots/droids/b2/droids_b2_foley_movement_1p_sprint_var_01_10.mp3",
}

ENT.NameTagOffset = 20

-- Eigene Skelette: Sequenz-Namen haben Vorrang vor Aktivitaeten
ENT.PreferSequences = true

ENT.Anims = {
    ["idle"] = { 0 },
    ["shoot"] = { 0 },
    ["reload"] = { 0 },
    ["walk_slow"] = { "walk" },
    ["walk_fast"] = { "walk" },
    ["melee"] = { "walk" },
    ["jump"] = { 0 },
}

if SERVER then
    function ENT:OnDroidSpawn()
        self.loco:SetStepHeight(40)
    end

    function ENT:OnCombatThink(enemy, dist, visible, now)
        if dist < 320 or not self.loco:IsOnGround() then return false end
        if now < (self.NextSlam or 0) or math.random() > 0.25 then return false end

        self.NextSlam = now + math.Rand(6, 9)
        self.IsSlamming = true

        local dir = enemy:GetPos() - self:GetPos()
        dir.z = 0
        dir:Normalize()

        self:StopMoving()
        self.loco:SetJumpHeight(180)
        self.loco:JumpAcrossGap(enemy:GetPos() - dir * 60, dir)
        self:PlaySound("npc/antlion_guard/angry" .. math.random(1, 3) .. ".wav", 85, 70)
        return true
    end

    function ENT:OnLanded()
        if not self.IsSlamming then return end
        self.IsSlamming = false

        local pos = self:GetPos()
        util.ScreenShake(pos, 20, 5, 1, self.SlamRadius * 2.5)

        local ed = EffectData()
        ed:SetOrigin(pos)
        ed:SetScale(self.SlamRadius)
        util.Effect("ThumperDust", ed)
        self:PlaySound("physics/concrete/boulder_impact_hard" .. math.random(1, 4) .. ".wav", 90)

        for _, ply in ipairs(EOCDroids.PlayersInSphere(pos, self.SlamRadius)) do
            if self:IsValidTarget(ply) then
                local d = DamageInfo()
                d:SetDamage(self.SlamDamage * EOCDroids.Config.DamageMultiplier)
                d:SetAttacker(self)
                d:SetInflictor(self)
                d:SetDamageType(DMG_CLUB)
                ply:TakeDamageInfo(d)
                ply:ScreenFade(SCREENFADE.IN, Color(255, 0, 0, 100), 0.3, 0)
                ply:SetVelocity((ply:GetPos() - pos):GetNormalized() * 400 + Vector(0, 0, 250))
            end
        end
    end
end
