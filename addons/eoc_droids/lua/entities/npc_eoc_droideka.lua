AddCSLuaFile()

DEFINE_BASECLASS("eoc_droid_base")

ENT.Base = "eoc_droid_base"
ENT.PrintName = "Droideka"
ENT.Category = EOCDroids.Config.Category
ENT.Spawnable = true
ENT.AdminOnly = EOCDroids.Config.AdminOnlySpawn

-- Rollt schnell heran, entfaltet sich und feuert mit aktivem Deflektorschild.
-- Schild haelt Blaster gut ab, Explosionen sind die Schwaeche.
ENT.Model = "models/npc/starwars/droidekas/droideka.mdl"
ENT.FallbackModel = "models/combine_soldier.mdl"
ENT.Weapon = "droideka"
ENT.HP = 300
ENT.HullWidth = 18
ENT.HullHeight = 52
ENT.EyeHeight = 42
ENT.MuzzleHeight = 36
ENT.ShootingRange = 900
ENT.LooseRadius = 2200
ENT.Inaccuracy = 0.15
ENT.Speed = 120
ENT.RunMultiplier = 2.4
ENT.ShootWhileMoving = false

ENT.ShieldDamageScale = 0.25
ENT.ShieldBlastScale = 0.7

ENT.ExplodeOnDeath = true
ENT.DeathExplosionRadius = 200
ENT.DeathExplosionDamage = 35

ENT.Anims = {
    ["idle"] = { "idle" },
    ["shoot"] = { "range_attack1" },
    ["reload"] = { "idle" },
    ["walk_slow"] = { "walk" },
    ["walk_fast"] = { "walk" },
}

local rollSound = "summe/nextbots/droids/droideka/droids_droideka_roll_main_loop_01.mp3"

function ENT:HasShield()
    return self:GetNW2Bool("EOCShield", false)
end

if SERVER then
    function ENT:OnAIThink()
        local moving = self:IsMovingNow()

        if moving and self:HasShield() then
            self:SetNW2Bool("EOCShield", false)
            self:StopSound(rollSound)
            if EOCDroids.ValidSound(rollSound) then
                self:EmitSound(rollSound, 85)
            end
        elseif not moving and not self:HasShield() then
            self:SetNW2Bool("EOCShield", true)
            self:StopSound(rollSound)
            self:PlaySound("buttons/combine_button_locked.wav", 70, 80)
        end
    end

    function ENT:ScaleIncomingDamage(dmg)
        if self:HasShield() then
            if dmg:IsExplosionDamage() then
                dmg:ScaleDamage(self.ShieldBlastScale)
            else
                dmg:ScaleDamage(self.ShieldDamageScale)
                local ed = EffectData()
                ed:SetOrigin(dmg:GetDamagePosition())
                ed:SetNormal((dmg:GetDamagePosition() - self:WorldSpaceCenter()):GetNormalized())
                util.Effect("AR2Impact", ed)
            end
            return
        end
        BaseClass.ScaleIncomingDamage(self, dmg)
    end

    function ENT:OnDroidRemoved()
        self:StopSound(rollSound)
    end
else
    local shieldMat = Material("models/effects/splodearc_sheet")
    local shieldInner = Color(0, 175, 175, 30)
    local shieldOuter = Color(83, 255, 255, 40)

    function ENT:DrawExtras()
        if not self:HasShield() then return end

        local frac = math.Clamp(self:Health() / math.max(self:GetMaxHealth(), 1), 0.25, 1)
        local pos = self:GetPos() + Vector(0, 0, 30)

        shieldInner.a = 40 * frac
        shieldOuter.a = 70 * frac

        render.SetColorMaterial()
        render.DrawSphere(pos, 52, 24, 24, shieldInner)
        if not shieldMat:IsError() then
            render.SetMaterial(shieldMat)
            render.DrawSphere(pos, 51, 24, 24, shieldOuter)
        end
    end
end
