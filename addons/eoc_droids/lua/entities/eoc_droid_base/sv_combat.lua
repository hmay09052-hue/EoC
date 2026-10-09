local C = EOCDroids.Config

-- ============================================================
-- BEWEGUNG
-- ============================================================
function ENT:TickMovement()
    if self.MovementLocked then
        if self.FacePos then self.loco:FaceTowards(self.FacePos) end
        return
    end

    if self.DirectGoal then
        -- Ohne Navmesh (oder wenn kein Pfad gefunden wird): direkt hinlaufen
        if self:GetPos():DistToSqr(self.DirectGoal) < 2500 then
            self.DirectGoal = nil
        else
            self.loco:Approach(self.DirectGoal, 1)
            self.loco:FaceTowards(self.DirectGoal)
        end
    elseif self.Path:IsValid() then
        self.Path:Update(self)
    elseif self.FacePos then
        self.loco:FaceTowards(self.FacePos)
    end

    if self.loco:IsStuck() then
        self:HandleStuck()
    end
end

function ENT:RunTo(pos, speed)
    if not pos or self.MovementLocked then return end

    speed = speed or self.Speed
    self.loco:SetDesiredSpeed(speed)
    self.MoveAnim = speed >= 200 and "walk_fast" or "walk_slow"

    if not EOCDroids.HasNavmesh() then
        self.DirectGoal = pos
        return
    end

    -- Pfad nicht staendig neu berechnen (teuer)
    if self.Path:IsValid() then
        if self.Path:GetAge() < 0.5 then return end
        if self.Path:GetAge() < 1.5 and self.PathGoal and self.PathGoal:DistToSqr(pos) < 8100 then return end
    end

    self.DirectGoal = nil
    self.PathGoal = pos

    if not self.Path:Compute(self, pos) and self:GetPos():DistToSqr(pos) < 360000 then
        self.DirectGoal = pos
    end
end

function ENT:StopMoving()
    if self.Path and self.Path:IsValid() then
        self.Path:Invalidate()
    end
    self.DirectGoal = nil
end

function ENT:Strafe(enemy)
    local side = math.random(0, 1) == 0 and -1 or 1
    local dir = self:GetRight() * side * math.Rand(120, 260)
    -- leicht auf das Ziel zu, wirkt aggressiver
    local toward = (enemy:GetPos() - self:GetPos()):GetNormalized() * math.Rand(-40, 120)
    self:RunTo(self:GetPos() + dir + toward, self.Speed * 1.3)
end

function ENT:HandleStuck()
    self.StuckCount = (self.StuckCount or 0) + 1
    self.loco:ClearStuck()
    self:StopMoving()

    if self.StuckCount % 3 == 0 and self.loco:IsOnGround() then
        self.loco:Jump()
    end

    if self.StuckCount >= 9 then
        self.StuckCount = 0
        self:SetPos(self:GetPos() + Vector(0, 0, 16))
    end
end

-- ============================================================
-- SCHIESSEN
-- ============================================================
function ENT:IsBuffed()
    return self.BuffUntil ~= nil and CurTime() < self.BuffUntil
end

function ENT:GetMuzzlePos()
    local scale = self:GetModelScale()

    if self.HandBone == nil then
        self.HandBone = self:LookupBone("ValveBiped.Bip01_R_Hand") or false
    end

    if self.HandBone then
        local pos = self:GetBonePosition(self.HandBone)
        if pos and pos:DistToSqr(self:GetPos()) > 400 then
            return pos + self:GetForward() * 14 * scale
        end
    end

    return self:GetPos() + Vector(0, 0, (self.MuzzleHeight or 50) * scale) + self:GetForward() * 20 * scale
end

function ENT:CancelCharge()
    if not self.ChargeEnd then return end
    self.ChargeEnd = nil
    self:SetNW2Entity("EOCAimTarget", NULL)
end

-- Scharfschuetzen zielen erst (sichtbarer Laser), dann Schuss
function ENT:TickCharge(enemy, now, w)
    if not self.ChargeEnd then
        self.ChargeEnd = now + w.ChargeTime
        self:SetNW2Entity("EOCAimTarget", enemy)
        self:PlaySound("buttons/blip1.wav", 70, 140)
        return false
    end

    if now < self.ChargeEnd then return false end

    self:CancelCharge()
    return true
end

function ENT:TickShoot(now)
    local w = self.WeaponData
    if not w or w.Melee then
        self.WantShoot = false
        return
    end

    if self.Reloading then
        if now < self.ReloadEnd then return end
        self.Reloading = false
        self.Clip = w.Clip
    end

    if self.DisableShooting or now < self.NextFire then return end

    local enemy = self:GetEnemy()
    if not IsValid(enemy) or not self.EnemyVisible then
        self:CancelCharge()
        return
    end

    if self.Clip <= 0 then
        self:StartReload(now)
        return
    end

    if w.ChargeTime and not self:TickCharge(enemy, now, w) then return end

    self:FireWeapon(enemy, w)
    self.Clip = self.Clip - 1
    self.LastShotTime = now

    local delay = w.Delay
    if self:IsBuffed() then delay = delay * 0.75 end
    self.NextFire = now + delay

    if w.Burst then
        self.BurstCount = self.BurstCount + 1
        if self.BurstCount >= w.Burst then
            self.BurstCount = 0
            self.NextFire = now + (w.BurstPause or 0.6) * math.Rand(0.7, 1.3)
        end
    end

    self:PlayAnim("shoot")
    self:Speak("attacking", 0.06)
end

function ENT:StartReload(now)
    local w = self.WeaponData
    self.Reloading = true
    self.ReloadEnd = now + w.Reload
    self.BurstCount = 0
    self:CancelCharge()
    self:PlayAnim("reload", math.min(w.Reload, 2))
    self:PlaySound("weapons/bf3/standard_reload2.ogg", 70, 100, "weapons/smg1/smg1_reload.wav")
end

function ENT:FireWeapon(enemy, w)
    local src = self:GetMuzzlePos()
    local aim = EOCDroids.TargetPos(enemy)

    local inacc = self.Inaccuracy * 100
    if inacc > 0 then
        aim = aim + VectorRand() * inacc * math.Rand(0.2, 1)
    end

    local dir = (aim - src):GetNormalized()
    local colorId = EOCDroids.LaserColorIds[w.Color or "red"] or 1
    local tracerScale = (w.TracerScale or 1) * self:GetModelScale()
    local spread = w.Spread or 0
    local sent = 0

    self:FireBullets({
        Attacker = self,
        Src = src,
        Dir = dir,
        Spread = Vector(spread, spread, 0),
        Num = w.Bullets or 1,
        Damage = (w.Damage or 10) * C.DamageMultiplier,
        Force = 2,
        Tracer = 0,
        Distance = 16000,
        IgnoreEntity = self,
        AmmoType = "AR2",
        Callback = function(_, tr)
            -- max. 3 Laser-Effekte pro Schuss (Schrotflinte) -> weniger Netzwerk-Last
            if sent >= 3 then return end
            sent = sent + 1

            local flags = 0
            if sent == 1 then flags = flags + 1 end              -- Muendungsfeuer
            if tr.Hit and not tr.HitSky then flags = flags + 2 end -- Einschlag

            local ed = EffectData()
            ed:SetOrigin(src)
            ed:SetStart(tr.HitPos)
            ed:SetNormal(tr.HitNormal)
            ed:SetColor(colorId)
            ed:SetScale(tracerScale)
            ed:SetFlags(flags)
            util.Effect("eoc_droid_laser", ed)
        end,
    })

    local snd = EOCDroids.ValidSound(w.Sound, w.FallbackSound)
    if snd then
        self:EmitSound(snd, 82, math.random(94, 106), 0.9, CHAN_WEAPON)
    end
end

-- ============================================================
-- NAHKAMPF
-- ============================================================
function ENT:TryMelee(target)
    local now = CurTime()
    if now < self.NextMelee then return end
    self.NextMelee = now + self.MeleeDelay

    self:PlayAnim("melee", 0.9)
    self.DisableShooting = true
    self.FacePos = target:GetPos()

    timer.Simple(self.MeleeHitDelay or 0.35, function()
        if not IsValid(self) then return end
        self.DisableShooting = false

        if not IsValid(target) or not self:IsValidTarget(target) then return end

        local reach = self.MeleeRange * self:GetModelScale() + 45
        if self:GetPos():DistToSqr(target:GetPos()) > reach * reach then return end

        self:DoMeleeHit(target)
    end)
end

function ENT:DoMeleeHit(target)
    local dir = target:GetPos() - self:GetPos()
    dir.z = 0
    dir:Normalize()

    local d = DamageInfo()
    d:SetDamage(self.MeleeDamage * C.DamageMultiplier)
    d:SetAttacker(self)
    d:SetInflictor(self)
    d:SetDamageType(self.MeleeDamageType or DMG_CLUB)
    d:SetDamageForce(dir * 8000)
    d:SetDamagePosition(target:WorldSpaceCenter())
    target:TakeDamageInfo(d)

    self:PlaySound(self.MeleeSounds[math.random(#self.MeleeSounds)], 80)

    if target:IsPlayer() then
        target:ScreenFade(SCREENFADE.IN, self.MeleeFadeColor, 0.3, 0)
        target:ViewPunch(Angle(-10, math.Rand(-6, 6), 0))
        target:SetVelocity(dir * self.MeleeKnockback + Vector(0, 0, 180))
    end

    self:OnMeleeHit(target)
end

function ENT:OnMeleeHit(target)
end

function ENT:OnContact(ent)
    if not self.Melee or not IsValid(ent) then return end
    if not (ent:IsPlayer() or ent:IsNPC()) then return end
    if not self:IsValidTarget(ent) then return end
    self:TryMelee(ent)
end

-- ============================================================
-- GRANATEN
-- ============================================================
function ENT:ThrowGrenade(enemy)
    self.NextGrenade = CurTime() + math.Rand(10, 16)
    self:PlayAnim("throw", 0.8)

    local target = enemy:GetPos()

    timer.Simple(0.45, function()
        if not IsValid(self) then return end

        local nade = ents.Create(self.Grenades[math.random(#self.Grenades)])
        if not IsValid(nade) then return end

        local src = self:GetMuzzlePos() + Vector(0, 0, 12)
        nade:SetPos(src)
        nade:SetOwner(self)
        nade.DroidOwner = self
        nade:Spawn()
        nade:Activate()

        local phys = nade:GetPhysicsObject()
        if not IsValid(phys) then return end

        -- ballistische Flugbahn genau auf das Ziel
        local delta = target - src
        local flat = Vector(delta.x, delta.y, 0)
        local t = math.Clamp(flat:Length() / 700, 0.5, 1.6)
        local g = physenv.GetGravity().z
        local vel = flat / t
        vel.z = (delta.z - 0.5 * g * t * t) / t

        phys:Wake()
        phys:SetVelocity(vel)
        phys:AddAngleVelocity(VectorRand() * 300)
    end)
end

-- ============================================================
-- SCHADEN / TOD
-- ============================================================
function ENT:IsHeadshot(pos)
    if not pos or pos == vector_origin then return false end
    local scale = self:GetModelScale()

    if self.HeadBone == nil then
        self.HeadBone = self:LookupBone("ValveBiped.Bip01_Head1") or false
    end

    if self.HeadBone then
        local headPos = self:GetBonePosition(self.HeadBone)
        if headPos and headPos:DistToSqr(self:GetPos()) > 400 then
            return headPos:DistToSqr(pos) < (13 * scale) ^ 2
        end
    end

    return (pos.z - self:GetPos().z) > self.HullHeight * scale * 0.85
end

-- Wird aus dem EntityTakeDamage-Hook aufgerufen (vor dem Abzug der Lebenspunkte)
function ENT:ScaleIncomingDamage(dmg)
    local scale = self.DamageScale

    if dmg:IsExplosionDamage() then
        scale = scale * self.BlastDamageScale
    elseif C.Headshots and self:IsHeadshot(dmg:GetDamagePosition()) then
        scale = scale * C.HeadshotMultiplier
    end

    if self:IsBuffed() then
        scale = scale * 0.8
    end

    dmg:ScaleDamage(scale)
end

function ENT:OnInjured(dmg)
    self:Speak("hit", 0.35)

    local attacker = dmg:GetAttacker()
    if IsValid(attacker) and not self:HasEnemy() and self:IsValidTarget(attacker) then
        self.Sleeping = false
        self:SetEnemy(attacker)
        self.LastSeenTime = CurTime()
        self.LastKnownPos = attacker:GetPos()
        self.EnemyVisible = self:CanSeeTarget(attacker)
        EOCDroids.AlertAllies(self, attacker, self.AlertRadius or C.AlertRadius)
    end

    if IsValid(self.GrabTarget) then
        self.GrabDamage = (self.GrabDamage or 0) + dmg:GetDamage()
        if self.GrabDamage > self:GetMaxHealth() * 0.25 then
            self:ReleaseGrab(false)
        end
    end

    if self.CanDodge then
        self:TryDodge()
    end

    if math.random() < 0.25 then
        local ed = EffectData()
        ed:SetOrigin(dmg:GetDamagePosition())
        ed:SetNormal(VectorRand())
        ed:SetMagnitude(1)
        ed:SetScale(1)
        ed:SetRadius(2)
        util.Effect("Sparks", ed)
    end

    self:OnDroidInjured(dmg)
end

function ENT:OnDroidInjured(dmg)
end

-- true zurueckgeben, wenn der Droide sein Entfernen selbst regelt
function ENT:OnDroidKilled(dmg)
    return false
end

function ENT:Explode(radius, damage)
    local pos = self:WorldSpaceCenter()
    local ed = EffectData()
    ed:SetOrigin(pos)
    util.Effect("Explosion", ed)
    util.ScreenShake(pos, 6, 5, 0.8, radius * 3)
    if damage > 0 then
        util.BlastDamage(self, self, pos, radius, damage * C.DamageMultiplier)
    end
end

function ENT:OnKilled(dmg)
    if self.IsDead then return end
    self.IsDead = true

    hook.Run("OnNPCKilled", self, dmg:GetAttacker(), dmg:GetInflictor())

    self:Speak("killed", 0.7, true)
    self:CancelCharge()

    if IsValid(self.GrabTarget) then
        self:ReleaseGrab(false)
    end

    if self:OnDroidKilled(dmg) then return end

    if self.ExplodeOnDeath then
        self:Explode(self.DeathExplosionRadius or 200, self.DeathExplosionDamage or 40)
    end

    local rag = self:BecomeRagdoll(dmg)
    if IsValid(rag) and C.RagdollTime > 0 then
        SafeRemoveEntityDelayed(rag, C.RagdollTime)
    end
end

-- ============================================================
-- BODEN / LUFT
-- ============================================================
function ENT:OnLeaveGround(ent)
    self:SetNW2Bool("EOCInAir", true)
end

function ENT:OnLandOnGround(ent)
    self:SetNW2Bool("EOCInAir", false)
    self:OnLanded(ent)
end

function ENT:OnLanded(ent)
end
