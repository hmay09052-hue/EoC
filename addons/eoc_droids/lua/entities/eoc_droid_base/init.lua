AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local C = EOCDroids.Config

-- ============================================================
-- SPAWN
-- ============================================================
function ENT:Initialize()
    self:SetModel(EOCDroids.PickModel(self.Model, self.FallbackModel))

    local scale = self.Scale or 1
    if scale ~= 1 then
        self:SetModelScale(scale, 0)
    end

    local w = self.HullWidth * scale
    self:SetCollisionBounds(Vector(-w, -w, 0), Vector(w, w, self.HullHeight * scale))

    local hp = math.max(1, math.Round(self.HP * C.HealthMultiplier))
    self:SetHealth(hp)
    self:SetMaxHealth(hp)

    if self.Tint then
        self:SetColor(self.Tint)
    end

    self:DrawShadow(false)
    self:SetNW2String("EOCWeapon", self.Weapon or "")
    self:SetNW2Entity("EOCEnemy", NULL)

    -- Gemeinsame Sprachpakete ("b1" / "b2")
    if self.Sounds == "b1" then
        self.Sounds = self.B1Sounds
    elseif self.Sounds == "b2" then
        self.Sounds = self.B2Sounds
    end

    self.WeaponData = EOCDroids.Weapons[self.Weapon or ""]
    self.Clip = self.WeaponData and self.WeaponData.Clip or 0

    self.loco:SetStepHeight(18 + 14 * scale)
    self.loco:SetJumpHeight(60 * scale)
    self.loco:SetDeathDropHeight(600)
    self.loco:SetAcceleration(500)
    self.loco:SetDeceleration(600)
    self.loco:SetMaxYawRate(300)
    self.loco:SetDesiredSpeed(self.Speed)

    -- Interne Zustaende
    self.NextAIThink = 0
    self.NextEnemySearch = 0
    self.NextSlowThink = CurTime() + math.Rand(0, 3)
    self.NextFire = 0
    self.NextMelee = 0
    self.NextGrenade = CurTime() + math.Rand(4, 10)
    self.NextVoice = CurTime() + math.Rand(1, 5)
    self.NextWander = CurTime() + math.Rand(2, 6)
    self.NextDoorCheck = 0
    self.BurstCount = 0
    self.LastShotTime = 0
    self.LastSeenTime = 0
    self.ForcedAnimUntil = 0
    self.Sleeping = false
    self.SeqCache = {}

    EOCDroids.Register(self)

    if EOCDroids.Count() > C.MaxDroids then
        timer.Simple(0, function()
            if IsValid(self) then self:Remove() end
        end)
        EOCDroids.MessageAdmins("Droiden-Limit erreicht (" .. C.MaxDroids .. "). Droide wurde nicht gespawnt.", 2)
        return
    end

    self:PlayAnim("idle")
    self:OnDroidSpawn()
end

-- Fuer eigene Anpassungen in den einzelnen Droiden
function ENT:OnDroidSpawn()
end

function ENT:OnRemove()
    EOCDroids.Unregister(self)
    if IsValid(self.GrabTarget) then
        self:ReleaseGrab(false)
    end
    timer.Remove("EOCDroids.Grab." .. self:EntIndex())
    self:OnDroidRemoved()
end

function ENT:OnDroidRemoved()
end

-- ============================================================
-- SOUNDS
-- ============================================================
function ENT:Speak(category, chance, ignoreCooldown)
    if not C.Voices or not istable(self.Sounds) then return end

    local list = self.Sounds[category]
    if not istable(list) or #list == 0 then return end
    if math.random() > (chance or 1) then return end
    if not ignoreCooldown and CurTime() < self.NextVoice then return end
    if not ignoreCooldown and not EOCDroids.TakeVoiceSlot() then return end

    local snd = EOCDroids.ValidSound(list[math.random(#list)])
    if not snd then return end

    self:EmitSound(snd, 80, math.random(97, 103), 1, CHAN_VOICE)
    self.NextVoice = CurTime() + math.Rand(C.VoiceCooldown[1], C.VoiceCooldown[2])
end

function ENT:PlaySound(path, level, pitch, fallback)
    local snd = EOCDroids.ValidSound(path, fallback)
    if not snd then return end
    self:EmitSound(snd, level or 80, pitch or 100, 1, CHAN_AUTO)
end

-- ============================================================
-- ANIMATION
-- ============================================================
local actFallback = {
    idle = ACT_IDLE,
    walk_slow = ACT_WALK,
    walk_fast = ACT_RUN,
    shoot = ACT_RANGE_ATTACK1,
    reload = ACT_RELOAD,
    melee = ACT_MELEE_ATTACK1,
    grab = ACT_MELEE_ATTACK1,
    throw = ACT_RANGE_ATTACK2,
    jump = ACT_JUMP,
    dodge = ACT_JUMP,
}

-- Kategorien ohne eigene Liste nutzen eine verwandte Liste
local animAliases = {
    grab = "melee",
    throw = "melee",
    dodge = "jump",
}

-- Sucht die gueltigen Sequenzen einer Kategorie (ungueltige Namen werden ignoriert)
function ENT:ResolveSequences(category)
    local cached = self.SeqCache[category]
    if cached then return cached end

    local valid = {}
    local list = self.Anims[category]
    if not list and animAliases[category] then list = self.Anims[animAliases[category]] end

    for _, name in ipairs(list or {}) do
        local id = isnumber(name) and name or self:LookupSequence(name)
        if id and id >= 0 then valid[#valid + 1] = id end
    end

    if #valid == 0 and actFallback[category] then
        local id = self:SelectWeightedSequence(actFallback[category])
        if id and id >= 0 then valid[1] = id end
    end

    self.SeqCache[category] = valid
    return valid
end

-- duration: Animation fuer X Sekunden erzwingen (z.B. Nahkampf, Nachladen)
function ENT:PlayAnim(category, duration)
    local now = CurTime()

    if duration then
        self.ForcedAnimUntil = now + duration
    elseif now < self.ForcedAnimUntil then
        return
    end

    if self.CurrentAnimCat == category and not duration then
        -- Einmalige Animationen (z.B. Schuss) neu starten wenn sie fertig sind
        if self:GetCycle() >= 0.98 then self:SetCycle(0) end
        return
    end

    local seqs = self:ResolveSequences(category)
    if #seqs == 0 then return end

    self.CurrentAnimCat = category
    self:ResetSequence(seqs[math.random(#seqs)])
    self:SetCycle(0)
    self:SetPlaybackRate(1)
end

function ENT:IsMovingNow()
    return self.loco:GetVelocity():Length2DSqr() > 400
end

function ENT:UpdateAnimation()
    if CurTime() < self.ForcedAnimUntil then return end

    if not self.loco:IsOnGround() and #self:ResolveSequences("jump") > 0 then
        self:PlayAnim("jump")
    elseif self:IsMovingNow() then
        self:PlayAnim(self.MoveAnim or "walk_slow")
    elseif self.WantShoot and CurTime() - self.LastShotTime < 1.2 then
        self:PlayAnim("shoot")
    else
        self:PlayAnim("idle")
    end
end

function ENT:BodyUpdate()
    local cat = self.CurrentAnimCat
    if (cat == "walk_slow" or cat == "walk_fast") and self:IsMovingNow()
        and self:GetSequenceGroundSpeed(self:GetSequence()) > 1 then
        self:BodyMoveXY()
    else
        self:FrameAdvance()
    end
end

include("sv_ai.lua")
include("sv_combat.lua")
include("sv_abilities.lua")
