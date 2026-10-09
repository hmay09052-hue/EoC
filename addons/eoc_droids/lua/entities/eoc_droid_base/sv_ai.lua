local C = EOCDroids.Config

-- ============================================================
-- HAUPTSCHLEIFE
-- Bewegung/Zielen/Schiessen laufen jeden Tick (fluessig),
-- Entscheidungen nur alle C.AIInterval Sekunden (Leistung bei 30-60 Spielern).
-- ============================================================
function ENT:RunBehaviour()
    self.Path = Path("Follow")
    self.Path:SetMinLookAheadDistance(80)
    self.Path:SetGoalTolerance(35)

    while true do
        local now = CurTime()

        if now >= self.NextAIThink then
            self.NextAIThink = now + (self.Sleeping and 1 or C.AIInterval) + math.Rand(0, 0.05)
            self:AIThink(now)
        end

        if self.WantShoot and not self.Sleeping then
            self:TickShoot(now)
        end

        self:TickMovement()

        coroutine.yield()
    end
end

function ENT:AIThink(now)
    if now >= self.NextSlowThink then
        self.NextSlowThink = now + 3
        self:UpdateSleep()
        if not self.Sleeping then
            self:EveryThreeSeconds()
        end
    end

    if self.Sleeping then
        self:StopMoving()
        self.WantShoot = false
        return
    end

    if now >= self.NextEnemySearch then
        self.NextEnemySearch = now + C.EnemySearchInterval + math.Rand(0, 0.1)
        self:UpdateEnemy(now)
    end

    local enemy = self:GetEnemy()
    if IsValid(enemy) and not self.MovementLocked then
        self:DoConfrontEnemy(enemy, now)
    elseif not IsValid(enemy) then
        self.WantShoot = false
        self.FacePos = nil
        self:DoNormal(now)
    end

    if not self.WantShoot then
        self:CancelCharge()
    end

    self:OpenDoors(now)
    self:UpdateFootsteps(now)
    self:OnAIThink(now)
    self:UpdateAnimation()
end

-- Fuer die einzelnen Droiden (wird bei jedem KI-Tick aufgerufen)
function ENT:OnAIThink(now)
end

function ENT:UpdateFootsteps(now)
    if not self.FootstepSounds or now < (self.NextFootstep or 0) then return end
    if not self:IsMovingNow() or not self.loco:IsOnGround() then return end

    self.NextFootstep = now + (self.FootstepInterval or 0.45)
    self:PlaySound(self.FootstepSounds[math.random(#self.FootstepSounds)], 75, math.random(90, 105))
end

-- Wird alle drei Sekunden aufgerufen (Offizier-Reparatur, Captain-Buff, ...)
function ENT:EveryThreeSeconds()
end

-- Kein Spieler in der Naehe -> KI schlaeft
function ENT:UpdateSleep()
    local pos = self:GetPos()
    local limit = C.AISleepDistance * C.AISleepDistance
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(pos) < limit then
            self.Sleeping = false
            return
        end
    end
    self.Sleeping = not self:HasEnemy()
end

-- ============================================================
-- ZIELE
-- ============================================================
function ENT:SetEnemy(ent)
    if IsValid(ent) then
        self:SetNW2Entity("EOCEnemy", ent)
    else
        self:SetNW2Entity("EOCEnemy", NULL)
    end
end

function ENT:IsValidTarget(ent)
    if not IsValid(ent) or ent == self then return false end

    if ent:IsPlayer() then
        if not ent:Alive() or ent:HasGodMode() or ent:IsFlagSet(FL_NOTARGET) then return false end
        if ent:GetObserverMode() ~= OBS_MODE_NONE then return false end
        if C.IgnoreNoclip and ent:GetMoveType() == MOVETYPE_NOCLIP then return false end
        if C.IgnoreTeams[team.GetName(ent:Team())] then return false end
    elseif ent:IsNPC() or ent:IsNextBot() then
        if not C.TargetNPCs or ent.IsEOCDroid then return false end
        if ent:Health() <= 0 or ent:IsFlagSet(FL_NOTARGET) then return false end
        if C.FriendlyNPCClasses[ent:GetClass()] then return false end
    else
        return false
    end

    if hook.Run("EOCDroids.CannotTarget", ent, self) then return false end
    return true
end

function ENT:GetEyePos()
    return self:GetPos() + Vector(0, 0, self.EyeHeight * self:GetModelScale())
end

-- Sichtlinie zum Ziel (auch Spieler in Fahrzeugen)
function ENT:CanSeeTarget(ent)
    local tr = util.TraceLine({
        start = self:GetEyePos(),
        endpos = EOCDroids.TargetPos(ent),
        filter = self,
        mask = MASK_SHOT,
    })

    if not tr.Hit or tr.Entity == ent then return true end

    local hit = tr.Entity
    if IsValid(hit) then
        if ent:IsPlayer() and ent:InVehicle() and (hit == ent:GetVehicle() or hit == ent:GetVehicle():GetParent()) then
            return true
        end
        -- Verbuendete blockieren die Sicht nicht (sie stehen nur im Weg)
        if hit.IsEOCDroid then return true end
    end

    return false
end

function ENT:UpdateEnemy(now)
    local current = self:GetEnemy()
    local myPos = self:GetPos()
    local currentDistSqr

    if IsValid(current) then
        if not self:IsValidTarget(current) then
            self:SetEnemy(NULL)
            current = nil
        elseif self:CanSeeTarget(current) then
            self.EnemyVisible = true
            self.LastSeenTime = now
            self.LastKnownPos = current:GetPos()
            currentDistSqr = myPos:DistToSqr(current:GetPos())
        else
            self.EnemyVisible = false
            if now - self.LastSeenTime > C.LoseTargetTime then
                self:SetEnemy(NULL)
                current = nil
            end
        end
    end

    -- Kandidaten sammeln (Spieler + gecachte NPCs)
    local looseSqr = self.LooseRadius * self.LooseRadius
    local candidates = {}

    for _, ply in ipairs(player.GetAll()) do
        local d = myPos:DistToSqr(ply:GetPos())
        if d < looseSqr then candidates[#candidates + 1] = { ply, d } end
    end

    if C.TargetNPCs then
        for _, npc in ipairs(EOCDroids.NPCTargets) do
            if IsValid(npc) then
                local d = myPos:DistToSqr(npc:GetPos())
                if d < looseSqr then candidates[#candidates + 1] = { npc, d } end
            end
        end
    end

    if #candidates == 0 then return end
    table.sort(candidates, function(a, b) return a[2] < b[2] end)

    -- Nur die naechsten Ziele per Trace pruefen (Leistung)
    local checks = 0
    for _, cand in ipairs(candidates) do
        local ent, distSqr = cand[1], cand[2]
        -- Aktuelles sichtbares Ziel nur wechseln, wenn das neue deutlich naeher ist
        if currentDistSqr and (ent == current or distSqr > currentDistSqr * 0.35) then break end

        if ent ~= current and self:IsValidTarget(ent) then
            checks = checks + 1
            if self:CanSeeTarget(ent) then
                local hadEnemy = IsValid(current)
                self:SetEnemy(ent)
                self.EnemyVisible = true
                self.LastSeenTime = now
                self.LastKnownPos = ent:GetPos()
                if not hadEnemy then
                    self:OnEnemyFound(ent)
                end
                return
            end
            if checks >= 3 then break end
        end
    end
end

function ENT:OnEnemyFound(ent)
    self:Speak("attacking", 0.5)
    EOCDroids.AlertAllies(self, ent, self.AlertRadius or C.AlertRadius)
end

-- ============================================================
-- KAMPFVERHALTEN
-- ============================================================
function ENT:GetShootingRange()
    if not EOCDroids.HasNavmesh() then
        -- Ohne Navmesh koennen sie sich schlecht naehern, also weiter schiessen
        return math.max(self.ShootingRange, self.LooseRadius * 0.8)
    end
    return self.ShootingRange
end

function ENT:DoConfrontEnemy(enemy, now)
    local enemyPos = enemy:GetPos()
    local dist = self:GetPos():Distance(enemyPos)
    local visible = self.EnemyVisible
    local scale = self:GetModelScale()

    if visible then
        self.FacePos = enemyPos
    end

    -- Nahkampf / Packen
    if visible and dist < (self.MeleeRange * scale + 25) then
        if self.CanGrab and self:TryGrab(enemy) then return end
        if self.Melee then self:TryMelee(enemy) end
    end

    if self:OnCombatThink(enemy, dist, visible, now) then return end

    if visible and self.WeaponData and not self.WeaponData.Melee and dist <= self:GetShootingRange() then
        self.WantShoot = true

        if self.ShootWhileMoving and self.StrafeChance > 0 and math.random() < self.StrafeChance then
            self:Strafe(enemy)
        elseif not self.ShootWhileMoving or not self.Path:IsValid() then
            self:StopMoving()
        end

        if self.ThrowGrenades and now >= self.NextGrenade and dist > 250 and dist < 1100 and math.random() < 0.06 then
            self:ThrowGrenade(enemy)
        end
    else
        self.WantShoot = false
        local goal = visible and enemyPos or self.LastKnownPos or enemyPos
        local speed = self.Speed * self.RunMultiplier
        -- Nahkaempfer laufen bis direkt ans Ziel
        local meleeOnly = self.WeaponData == nil or self.WeaponData.Melee
        if meleeOnly and dist < self.MeleeRange * scale then
            self:StopMoving()
            return
        end
        self:RunTo(goal, speed)
    end
end

-- Fuer Spezialfaehigkeiten. true zurueckgeben = normales Verhalten ueberspringen
function ENT:OnCombatThink(enemy, dist, visible, now)
    return false
end

-- Ohne Ziel: patrouillieren
function ENT:DoNormal(now)
    if not C.Wander or now < self.NextWander then return end
    self.NextWander = now + math.Rand(6, 14)

    if not EOCDroids.HasNavmesh() then return end

    local areas = navmesh.Find(self:GetPos(), 700, 60, 60)
    if #areas == 0 then return end

    local area = areas[math.random(#areas)]
    if not IsValid(area) then return end

    self:RunTo(area:GetRandomPoint(), self.Speed)
end

-- ============================================================
-- TUEREN
-- ============================================================
local doorClasses = {
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true,
}

function ENT:OpenDoors(now)
    if not C.CanOpenDoors or now < self.NextDoorCheck then return end
    self.NextDoorCheck = now + 1

    if not self:IsMovingNow() then return end

    for _, door in ipairs(ents.FindInSphere(self:GetPos() + self:GetForward() * 30, 70 * self:GetModelScale())) do
        if doorClasses[door:GetClass()] and not door.EOCDroidOpen then
            self:TryOpenDoor(door)
        end
    end
end

function ENT:TryOpenDoor(door)
    local locked = door:GetInternalVariable("m_bLocked") == true
    if locked and not (C.OpenLockedDoors or self.CanBreach) then return end

    if locked then
        self:BreachDoor(door)
    end

    door:Fire("Open")
    door.EOCDroidOpen = true

    timer.Simple(5, function()
        if not IsValid(door) then return end
        door.EOCDroidOpen = nil
        door:Fire("Close")
    end)
end

function ENT:BreachDoor(door)
    door:Fire("Unlock")
    local ed = EffectData()
    ed:SetOrigin(door:WorldSpaceCenter())
    ed:SetMagnitude(3)
    ed:SetScale(2)
    ed:SetRadius(4)
    util.Effect("Sparks", ed)
    self:PlaySound("physics/metal/metal_box_break1.wav", 85)
end
