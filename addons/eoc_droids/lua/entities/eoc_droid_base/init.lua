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

    self:SetBaseAnim("idle")
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

function ENT:PlaySound(path, level, pitch, fallback, volume)
    local snd = EOCDroids.ValidSound(path, fallback)
    if not snd then return end
    self:EmitSound(snd, level or 80, pitch or 100, volume or 1, CHAN_AUTO)
end

-- ============================================================
-- ANIMATION
-- Basis-Animation (Stehen/Laufen) kommt aus den Waffen-Aktivitaeten des Models
-- (z.B. ACT_RUN_AIM_RIFLE), Schuss/Nachladen laufen als Geste darueber.
-- So wird die Laufanimation nicht bei jedem Schuss abgebrochen.
-- ============================================================
local function A(...)
    local list = {}
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v then list[#list + 1] = v end
    end
    return list
end

local HOLD_ACTS = {
    smg = {
        idle = A(ACT_IDLE_SMG1, ACT_IDLE_RIFLE, ACT_IDLE),
        idle_combat = A(ACT_IDLE_ANGRY_SMG1, ACT_IDLE_AIM_RIFLE_STIMULATED, ACT_IDLE_SMG1, ACT_IDLE_ANGRY, ACT_IDLE),
        walk = A(ACT_WALK_RIFLE, ACT_WALK),
        run = A(ACT_RUN_RIFLE, ACT_RUN),
        walk_combat = A(ACT_WALK_AIM_RIFLE, ACT_WALK_RIFLE, ACT_WALK),
        run_combat = A(ACT_RUN_AIM_RIFLE, ACT_RUN_RIFLE, ACT_RUN),
        reload = A(ACT_RELOAD_SMG1, ACT_RELOAD),
        g_shoot = A(ACT_GESTURE_RANGE_ATTACK_SMG1, ACT_GESTURE_RANGE_ATTACK_AR2, ACT_GESTURE_RANGE_ATTACK1),
        g_reload = A(ACT_GESTURE_RELOAD_SMG1, ACT_GESTURE_RELOAD),
    },
    pistol = {
        idle = A(ACT_IDLE_PISTOL, ACT_IDLE),
        idle_combat = A(ACT_IDLE_ANGRY_PISTOL, ACT_IDLE_PISTOL, ACT_IDLE_ANGRY, ACT_IDLE),
        walk = A(ACT_WALK_PISTOL, ACT_WALK),
        run = A(ACT_RUN_PISTOL, ACT_RUN),
        walk_combat = A(ACT_WALK_AIM_PISTOL, ACT_WALK_PISTOL, ACT_WALK),
        run_combat = A(ACT_RUN_AIM_PISTOL, ACT_RUN_PISTOL, ACT_RUN),
        reload = A(ACT_RELOAD_PISTOL, ACT_RELOAD),
        g_shoot = A(ACT_GESTURE_RANGE_ATTACK_PISTOL, ACT_GESTURE_RANGE_ATTACK1),
        g_reload = A(ACT_GESTURE_RELOAD_PISTOL, ACT_GESTURE_RELOAD),
    },
    shotgun = {
        idle = A(ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_SMG1, ACT_IDLE),
        idle_combat = A(ACT_IDLE_ANGRY_SHOTGUN, ACT_IDLE_ANGRY_SMG1, ACT_IDLE_SMG1, ACT_IDLE_ANGRY, ACT_IDLE),
        walk = A(ACT_WALK_RIFLE, ACT_WALK),
        run = A(ACT_RUN_RIFLE, ACT_RUN),
        walk_combat = A(ACT_WALK_AIM_SHOTGUN, ACT_WALK_AIM_RIFLE, ACT_WALK_RIFLE, ACT_WALK),
        run_combat = A(ACT_RUN_AIM_SHOTGUN, ACT_RUN_AIM_RIFLE, ACT_RUN_RIFLE, ACT_RUN),
        reload = A(ACT_RELOAD_SHOTGUN, ACT_RELOAD_SMG1, ACT_RELOAD),
        g_shoot = A(ACT_GESTURE_RANGE_ATTACK_SHOTGUN, ACT_GESTURE_RANGE_ATTACK_SMG1, ACT_GESTURE_RANGE_ATTACK1),
        g_reload = A(ACT_GESTURE_RELOAD_SHOTGUN, ACT_GESTURE_RELOAD_SMG1, ACT_GESTURE_RELOAD),
    },
    melee = {
        idle = A(ACT_IDLE),
        idle_combat = A(ACT_IDLE_ANGRY_MELEE, ACT_IDLE_ANGRY, ACT_IDLE),
        walk = A(ACT_WALK),
        run = A(ACT_RUN),
        walk_combat = A(ACT_WALK),
        run_combat = A(ACT_RUN),
    },
}

local COMMON_ACTS = {
    jump = A(ACT_JUMP, ACT_GLIDE),
    dodge = A(ACT_JUMP, ACT_GLIDE),
    melee = A(ACT_MELEE_ATTACK_SWING, ACT_MELEE_ATTACK1),
    grab = A(ACT_MELEE_ATTACK_SWING, ACT_MELEE_ATTACK1),
    throw = A(ACT_RANGE_ATTACK_THROW),
    g_melee = A(ACT_GESTURE_MELEE_ATTACK_SWING, ACT_GESTURE_MELEE_ATTACK1),
    g_throw = A(ACT_GESTURE_RANGE_ATTACK_THROW),
}

-- Letzter Ausweg, wenn ein Model gar nichts Passendes hat
local GENERIC_ACTS = {
    idle = ACT_IDLE, idle_combat = ACT_IDLE, walk = ACT_WALK, run = ACT_RUN,
    walk_combat = ACT_WALK, run_combat = ACT_RUN, jump = ACT_JUMP, dodge = ACT_JUMP,
    melee = ACT_MELEE_ATTACK1, grab = ACT_MELEE_ATTACK1, throw = ACT_MELEE_ATTACK1, reload = ACT_RELOAD,
}

-- Namen aus ENT.Anims, die zu einer Kategorie passen (aeltere Listen-Namen bleiben gueltig)
local NAME_KEYS = {
    idle = { "idle" },
    idle_combat = { "idle_combat", "idle" },
    walk = { "walk_slow" },
    run = { "walk_fast" },
    walk_combat = { "walk_slow" },
    run_combat = { "walk_fast" },
    reload = { "reload" },
    melee = { "melee" },
    grab = { "grab", "melee" },
    throw = { "throw", "melee" },
    jump = { "jump" },
    dodge = { "dodge", "jump" },
    g_shoot = { "gesture_shoot" },
    g_reload = { "gesture_reload" },
    g_melee = { "gesture_melee" },
    g_throw = { "gesture_throw" },
}

-- Fuer "Sequenz-Droiden" (Droideka, Krabbe, Aqua) darf die Schuss-Sequenz die Kampfhaltung sein
local PREFER_NAME_KEYS = {
    idle_combat = { "idle_combat", "shoot", "idle" },
}

function ENT:GetHoldType()
    local w = self.WeaponData
    return (w and w.HoldType) or (w and w.Melee and "melee") or self.HoldType or "smg"
end

local function seqFromActs(ent, acts)
    for _, act in ipairs(acts or {}) do
        local seq = ent:SelectWeightedSequence(act)
        if seq and seq > 0 then return seq end
    end
end

local function seqFromNames(ent, keys)
    for _, key in ipairs(keys or {}) do
        for _, name in ipairs(ent.Anims[key] or {}) do
            local seq = isnumber(name) and name or ent:LookupSequence(name)
            if seq and seq >= 0 then return seq end
        end
    end
end

-- Liefert EINE feste Sequenz pro Kategorie (gecacht) -> kein Flackern durch Zufallsauswahl
function ENT:ResolveSequence(category)
    local cached = self.SeqCache[category]
    if cached ~= nil then return cached or nil end

    local holdActs = HOLD_ACTS[self:GetHoldType()] or HOLD_ACTS.smg
    local acts = (self.AnimActs and self.AnimActs[category]) or holdActs[category] or COMMON_ACTS[category]
    local names = (self.PreferSequences and PREFER_NAME_KEYS[category]) or NAME_KEYS[category] or { category }

    local seq
    if self.PreferSequences then
        seq = seqFromNames(self, names) or seqFromActs(self, acts)
    else
        seq = seqFromActs(self, acts) or seqFromNames(self, names)
    end

    if not seq and GENERIC_ACTS[category] then
        local id = self:SelectWeightedSequence(GENERIC_ACTS[category])
        if id and id >= 0 then seq = id end
    end

    self.SeqCache[category] = seq or false
    return seq
end

-- Grundhaltung (Stehen/Laufen/Springen). Startet nur neu, wenn sich die Sequenz wirklich aendert.
function ENT:SetBaseAnim(category)
    local seq = self:ResolveSequence(category)
    if not seq then return end
    self.BaseAnimCat = category
    if self:GetSequence() == seq and not self.BaseAnimDirty then return end
    self.BaseAnimDirty = false
    self:ResetSequence(seq)
    self:SetPlaybackRate(1)
end

-- Geste ueber der Grundhaltung (Schuss, Nachladen, ...). true = abgespielt
function ENT:PlayGesture(category, restartFraction)
    if not self.AddGestureSequence then return false end

    local seq = self:ResolveSequence("g_" .. category)
    if not seq then return false end

    local now = CurTime()
    local duration = math.max(self:SequenceDuration(seq), 0.05)

    if self.GestureCat == category and now < (self.GestureStart or 0) + duration * (restartFraction or 1) then
        return true
    end

    self:RemoveAllGestures()
    self:AddGestureSequence(seq, true)
    self.GestureCat = category
    self.GestureStart = now
    return true
end

-- Ganzkoerper-Animation fuer eine feste Zeit (Nahkampf, Ausweichen, ...)
function ENT:PlayForcedAnim(category, duration)
    local seq = self:ResolveSequence(category)
    if not seq then return false end
    self.ForcedAnimUntil = CurTime() + (duration or math.max(self:SequenceDuration(seq), 0.3))
    self.BaseAnimDirty = true
    self:ResetSequence(seq)
    self:SetCycle(0)
    self:SetPlaybackRate(1)
    return true
end

-- Einheitlicher Einstieg, wie bisher genutzt
function ENT:PlayAnim(category, duration)
    if category == "shoot" then
        -- Sequenz-Droiden ohne Gesten bleiben einfach in ihrer Kampfhaltung
        self:PlayGesture("shoot", 0.4)
        return
    end

    if category == "reload" or category == "throw" then
        if self:PlayGesture(category) then return end
        if self:IsMovingNow() then return end
        self:PlayForcedAnim(category, duration)
        return
    end

    if category == "melee" and self:IsMovingNow() and self:PlayGesture("melee") then return end

    if category == "idle" then
        self:SetBaseAnim(self:HasEnemy() and "idle_combat" or "idle")
        return
    end

    self:PlayForcedAnim(category, duration)
end

function ENT:IsMovingNow()
    return self.loco:GetVelocity():Length2DSqr() > 400
end

function ENT:UpdateAnimation()
    local now = CurTime()
    if now < self.ForcedAnimUntil then return end

    -- kurze Bodenverluste (Treppen, Kanten) nicht als Sprung zeigen
    if self.loco:IsOnGround() then
        self.AirSince = nil
    else
        self.AirSince = self.AirSince or now
    end

    local speedSqr = self.loco:GetVelocity():Length2DSqr()
    -- Hysterese gegen Flackern zwischen Stehen und Laufen
    if self.AnimMoving then
        self.AnimMoving = speedSqr > 100
    else
        self.AnimMoving = speedSqr > 900
    end

    local combat = self:HasEnemy()
    local category

    if self.AirSince and now - self.AirSince > 0.25 then
        category = "jump"
    elseif self.AnimMoving then
        if self.MoveRun then
            category = combat and "run_combat" or "run"
        else
            category = combat and "walk_combat" or "walk"
        end
    else
        category = combat and "idle_combat" or "idle"
    end

    self:SetBaseAnim(category)
end

-- Zielt mit Oberkoerper/Waffe ueber die Pose-Parameter auf den Gegner
function ENT:UpdateAim()
    if self.AimParams == nil then
        self.AimParams = self:LookupPoseParameter("aim_yaw") >= 0
        self.AimPitchParam = self:LookupPoseParameter("aim_pitch") >= 0
    end
    if not self.AimParams then return end

    local targetYaw, targetPitch = 0, 0
    local enemy = self:GetEnemy()
    if IsValid(enemy) and self.EnemyVisible then
        local dir = (EOCDroids.TargetPos(enemy) - self:GetEyePos()):Angle()
        targetYaw = math.Clamp(math.NormalizeAngle(dir.y - self:GetAngles().y), -60, 60)
        targetPitch = math.Clamp(math.NormalizeAngle(dir.p), -45, 45)
    end

    local yaw = math.ApproachAngle(self.AimYaw or 0, targetYaw, 6)
    local pitch = math.ApproachAngle(self.AimPitch or 0, targetPitch, 4)

    if yaw ~= self.AimYaw then
        self.AimYaw = yaw
        self:SetPoseParameter("aim_yaw", yaw)
    end
    if self.AimPitchParam and pitch ~= self.AimPitch then
        self.AimPitch = pitch
        self:SetPoseParameter("aim_pitch", pitch)
    end
end

function ENT:BodyUpdate()
    if self.AnimMoving and CurTime() >= self.ForcedAnimUntil
        and self:GetSequenceGroundSpeed(self:GetSequence()) > 1 then
        self:BodyMoveXY()
    else
        self:FrameAdvance()
    end
end

include("sv_ai.lua")
include("sv_combat.lua")
include("sv_abilities.lua")
