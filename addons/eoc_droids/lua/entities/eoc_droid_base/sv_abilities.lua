local C = EOCDroids.Config

-- ============================================================
-- PACKEN (B2): Spieler hochheben, quetschen und wegschleudern
-- ============================================================
function ENT:TryGrab(target)
    local now = CurTime()
    if not target:IsPlayer() or IsValid(self.GrabTarget) or now < (self.NextGrab or 0) then return false end
    if target:InVehicle() or IsValid(target:GetNW2Entity("EOCGrabber")) then return false end

    if math.random() > (self.GrabChance or 0.5) then
        self.NextGrab = now + 2
        return false
    end

    self.NextGrab = now + math.Rand(12, 18)
    self.GrabTarget = target
    self.GrabDamage = 0
    target:SetNW2Entity("EOCGrabber", self)

    self.MovementLocked = true
    self.WantShoot = false
    self.DisableShooting = true
    self.FacePos = nil
    self:StopMoving()

    local hold = self.GrabTime or 2.5
    self:PlayAnim("grab", hold)
    self:PlaySound("physics/metal/metal_box_strain2.wav", 85)

    local ticks = math.max(1, math.floor(hold / 0.5))
    local count = 0

    timer.Create("EOCDroids.Grab." .. self:EntIndex(), 0.5, ticks, function()
        if not IsValid(self) then return end

        local ply = self.GrabTarget
        if not IsValid(ply) or not ply:Alive() then
            self:ReleaseGrab(false)
            return
        end

        count = count + 1

        local d = DamageInfo()
        d:SetDamage((self.GrabDamagePerTick or 6) * C.DamageMultiplier)
        d:SetAttacker(self)
        d:SetInflictor(self)
        d:SetDamageType(DMG_CRUSH)
        ply:TakeDamageInfo(d)
        ply:ViewPunch(Angle(math.Rand(-4, 4), math.Rand(-4, 4), 0))
        self:PlaySound("physics/metal/metal_box_strain" .. math.random(1, 4) .. ".wav", 75)

        if count >= ticks and IsValid(self.GrabTarget) then
            self:ReleaseGrab(true)
        end
    end)

    return true
end

function ENT:ReleaseGrab(throw)
    timer.Remove("EOCDroids.Grab." .. self:EntIndex())

    local ply = self.GrabTarget
    self.GrabTarget = nil
    self.MovementLocked = false
    self.DisableShooting = false

    if not IsValid(ply) then return end
    ply:SetNW2Entity("EOCGrabber", NULL)

    -- Nicht in Waenden stecken lassen
    local pos = ply:GetPos()
    local mins, maxs = ply:GetHull()
    local tr = util.TraceHull({ start = pos, endpos = pos, mins = mins, maxs = maxs, filter = { ply, self }, mask = MASK_PLAYERSOLID })
    if tr.StartSolid then
        ply:SetPos(self:GetPos() + Vector(0, 0, self:OBBMaxs().z + 4))
    end

    if throw and ply:Alive() then
        ply:SetVelocity(self:GetForward() * (self.GrabThrowForce or 850) + Vector(0, 0, 360))

        local d = DamageInfo()
        d:SetDamage(15 * C.DamageMultiplier)
        d:SetAttacker(self)
        d:SetInflictor(self)
        d:SetDamageType(DMG_CLUB)
        ply:TakeDamageInfo(d)

        self:PlaySound("physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 85)
    end
end

-- ============================================================
-- AUSWEICHEN (BX): Seitwaertsrolle bei Beschuss
-- ============================================================
function ENT:TryDodge()
    local now = CurTime()
    if now < (self.NextDodge or 0) or self.MovementLocked or not self.loco:IsOnGround() then return false end
    if math.random() > (self.DodgeChance or 0.35) then return false end

    self.NextDodge = now + math.Rand(2.5, 4.5)

    local pos = self:GetPos()
    local mins, maxs = self:GetCollisionBounds()
    local first = math.random(0, 1) == 0 and -1 or 1

    for _, side in ipairs({ first, -first }) do
        local target = pos + self:GetRight() * side * (self.DodgeDistance or 220)
        local tr = util.TraceHull({
            start = pos + Vector(0, 0, 12),
            endpos = target + Vector(0, 0, 12),
            mins = mins, maxs = maxs,
            filter = self, mask = MASK_NPCSOLID,
        })

        if not tr.Hit then
            local ground = util.TraceLine({
                start = target + Vector(0, 0, 20),
                endpos = target - Vector(0, 0, 140),
                filter = self, mask = MASK_NPCSOLID,
            })

            if ground.Hit and not ground.StartSolid then
                self:StopMoving()
                self.loco:SetJumpHeight(40)
                self.loco:JumpAcrossGap(ground.HitPos, self:GetForward())
                self:PlayAnim("dodge", 0.6)
                self:PlaySound("npc/combine_soldier/gear" .. math.random(1, 6) .. ".wav", 70)
                return true
            end
        end
    end

    return false
end

-- Weicht auch aus, wenn ein Spieler genau auf ihn zielt
function ENT:CheckAimedAt(enemy)
    if not self.CanDodge or not enemy:IsPlayer() then return end
    local toMe = (self:WorldSpaceCenter() - enemy:EyePos()):GetNormalized()
    if enemy:GetAimVector():Dot(toMe) > 0.985 and math.random() < 0.25 then
        self:TryDodge()
    end
end

-- ============================================================
-- JETPACK: Spruenge ueber das Schlachtfeld
-- ============================================================
function ENT:TryJetpack(enemy, dist)
    local now = CurTime()
    if now < (self.NextJet or 0) or not self.loco:IsOnGround() or self.MovementLocked then return false end
    if dist < (self.JetMinDist or 350) or math.random() > (self.JetChance or 0.12) then return false end

    local cooldown = self.JetCooldown or 6
    self.NextJet = now + math.Rand(cooldown, cooldown * 1.6)

    local myPos = self:GetPos()
    local dir = enemy:GetPos() - myPos
    dir.z = 0
    local flatDist = dir:Length()
    dir:Normalize()

    local land = myPos + dir * math.min(flatDist * 0.65, 750) + Vector(math.Rand(-90, 90), math.Rand(-90, 90), 0)
    local tr = util.TraceLine({
        start = land + Vector(0, 0, 250),
        endpos = land - Vector(0, 0, 500),
        filter = self, mask = MASK_NPCSOLID_BRUSHONLY,
    })
    if not tr.Hit or tr.StartSolid then return false end

    self:StopMoving()
    self.loco:SetJumpHeight(self.JetHeight or 220)
    self.loco:JumpAcrossGap(tr.HitPos, dir)
    self:PlaySound("thrusters/jet02.wav", C.JetpackSoundLevel, 110, nil, C.JetpackVolume)
    return true
end

-- ============================================================
-- RAKETEN (B2-RP, B2-X)
-- ============================================================
function ENT:FireRocket(enemy, sideOffset)
    local scale = self:GetModelScale()
    local src = self:GetEyePos() + self:GetForward() * 22 * scale + self:GetRight() * (sideOffset or 0)
    local target = EOCDroids.TargetPos(enemy)

    local rocket = ents.Create("eoc_droid_missile")
    if not IsValid(rocket) then return end

    rocket:SetPos(src)
    rocket:SetAngles((target - src):Angle())
    rocket:SetOwner(self)
    rocket.DroidOwner = self
    rocket.Target = enemy
    rocket:Spawn()

    self:PlaySound("summe/nextbots/weapons/simple_oneshot_juggernaut_rocketlauncher_close_var_01.mp3", 95, 100, "weapons/rpg/rocketfire1.wav")
end
