local KMS = KrakensMedical

local BASE_HR = 80
local ATTRIBUTION_WINDOW = 120

local function ProfileCoef(ply, field)
    if not ply:IsPlayer() then return 1 end
    local profile = KMS.DamageProfile(ply)
    local mult = profile and profile[field] / 100 or 1
    local mods = ply.KMSDamageMods
    return mods and mods[field] and mult * mods[field] or mult
end

local function PartCoef(ply, partId)
    local mods = ply.KMSDamageMods
    local parts = mods and mods.parts
    return parts and parts[partId] or 1
end

local function NewParts()
    local parts = {}
    for _, part in ipairs(KMS.Parts) do
        parts[part.id] = { wounds = {}, frac = false, splint = false, tq = false, tqAt = 0 }
    end
    return parts
end

function KMS.ResetState(ply)
    ply.KMSState = {
        blood = KMS.Settings.maxBlood,
        pain = 0,
        hr = BASE_HR,
        spo2 = KMS.NormalSpO2,
        parts = NewParts(),
        meds = {},
        lastMorphine = 0,
        conscious = true,
        arrest = false,
        arrestLeft = 0,
        nextWake = 0,
        nextTqWarn = 0,
        triage = 0,
        log = {},
        quick = {},
        dirty = true,
    }
    ply:SetNWInt("kms_mobility", 0)
    ply:SetNWBool("kms_noarms", false)
    ply:SetNWBool("kms_treatlock", false)
    ply:SetNWBool("kms_arrest", false)
    ply:SetNWInt("kms_triage", 0)
end

function KMS.RestoreJump(ply)
    if not ply.KMSJumpPower then return end
    ply:SetJumpPower(ply.KMSJumpPower)
    ply.KMSJumpPower = nil
end

local function RestoreBody(ply)
    ply:UnSpectate()
    ply:SetNoDraw(false)
    ply:SetNotSolid(false)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetSaveValue("m_takedamage", 2)
end

function KMS.Detach(ply)
    if KMS.Draggers[ply] then KMS.StopDrag(ply) end
    for dragger, patient in pairs(KMS.Draggers) do
        if patient == ply then
            KMS.StopDrag(dragger)
            break
        end
    end
    for _, other in ipairs(player.GetAll()) do
        if other.KMSJob and (other == ply or other.KMSJob.patient == ply) then
            KMS.CancelTreatment(other, true)
        end
    end
    if ply:Alive() and ply.KMSState and not ply.KMSState.conscious then KMS.WakePlayer(ply) end
    KMS.RestoreJump(ply)
    KMS.ResetStamina(ply)
    KMS.ResetState(ply)
    KMS.SyncSelf(ply)
end

function KMS.MarkDirty(ply)
    local state = ply.KMSState
    if state then state.dirty = true end
end

function KMS.AddLog(ply, key, ...)
    local state = ply.KMSState
    if not state then return end
    table.insert(state.log, 1, { t = os.time(), k = key, a = { ... } })
    if #state.log > 20 then table.remove(state.log) end
    state.dirty = true
end

function KMS.AddQuick(ply, key, ...)
    local state = ply.KMSState
    if not state then return end
    table.insert(state.quick, 1, { t = os.time(), k = key, a = { ... } })
    if #state.quick > 10 then table.remove(state.quick) end
    state.dirty = true
end

function KMS.ActiveMeds(state, id)
    local doses = state.meds[id]
    if not doses then return 0 end
    local now = CurTime()
    local active = 0
    for i = #doses, 1, -1 do
        if not doses[i].occluded then
            if doses[i].untilT <= now then
                table.remove(doses, i)
            else
                active = active + 1
            end
        end
    end
    if #doses == 0 then
        state.meds[id] = nil
    end
    return active
end

-- True while any active medication carries the flag (stasis, shock, radShield, toxShield).
function KMS.MedFlag(state, flag)
    for medId in pairs(state.meds) do
        local def = KMS.Meds[medId]
        if def and def[flag] and KMS.ActiveMeds(state, medId) > 0 then return true end
    end
    return false
end

local function DoseRatio(def, dose, now)
    local age = now - dose.at
    local total = dose.untilT - dose.at
    return math.min((age / def.rampTime) ^ 2, 1) * math.max(0, (total - age) / total)
end

function KMS.MedRatio(state, id)
    local doses = state.meds[id]
    if not doses then return 0 end
    local def = KMS.Meds[id]
    local now = CurTime()
    local total = 0
    for _, dose in ipairs(doses) do
        if not dose.occluded and dose.untilT > now then
            total = total + DoseRatio(def, dose, now)
        end
    end
    return math.min(1, total)
end

function KMS.MedEffects(state)
    local now = CurTime()
    if state.medFx and state.medFx.at == now then return state.medFx end
    local hr, painSuppress, viscosity = 0, 0, 0
    for id, def in pairs(KMS.Meds) do
        local doses = state.meds[id]
        if doses then
            for i = #doses, 1, -1 do
                local dose = doses[i]
                if dose.untilT <= now and not dose.occluded then
                    table.remove(doses, i)
                elseif not dose.occluded then
                    local ratio = DoseRatio(def, dose, now)
                    hr = hr + dose.hrAdj * ratio
                    painSuppress = painSuppress + def.painReduce * ratio
                    viscosity = viscosity + def.viscosity * ratio
                end
            end
            if #doses == 0 then state.meds[id] = nil end
        end
    end
    state.medFx = { at = now, hr = hr, pain = painSuppress, visc = viscosity }
    return state.medFx
end

local BODY_BLEED_CAP = KMS.BodyBleedCap

local function BloodRamp(frac)
    return math.Clamp((frac - 0.5) * 2, 0, 1)
end

local function BloodResist(state)
    return (100 + KMS.MedEffects(state).visc) / 100
end

function KMS.ComputeBP(state)
    local frac = state.blood / KMS.Settings.maxBlood
    local resist = math.max(0.01, BloodResist(state))
    local sys = math.Round(math.Clamp(120 * (state.hr / BASE_HR) * BloodRamp(frac) * resist, 0, 300))
    return sys, math.Round(sys * 2 / 3)
end

function KMS.PerceivedPain(state)
    return math.Clamp(state.pain - KMS.MedEffects(state).pain, 0, 1)
end

local function StableVitals(state)
    if state.arrest then return false end
    if state.blood / KMS.Settings.maxBlood < 0.85 then return false end
    if state.hr < 40 then return false end
    local sys, dia = KMS.ComputeBP(state)
    return sys >= 60 and dia >= 50
end

function KMS.IsStable(ply)
    local state = ply.KMSState
    if not state or not state.conscious or not StableVitals(state) then return false end
    for _, partState in pairs(state.parts) do
        if not partState.tq and KMS.PartHasBleedingWound(partState) then return false end
    end
    return true
end

function KMS.CPRProvider(patient)
    local state = patient.KMSState
    local provider = state and state.cprBy
    if IsValid(provider) and provider:Alive()
        and provider.KMSJob and provider.KMSJob.treatId == "cpr" and provider.KMSJob.patient == patient then
        return provider
    end
    if state then state.cprBy = nil end
    return nil
end

function KMS.AddWound(ply, partId, woundType, size, count, woundSize)
    local state = ply.KMSState
    local partState = state and state.parts[partId]
    if not partState then return end
    size = math.Clamp(size, 1, 3)
    count = count or 1
    woundSize = woundSize or KMS.CategorySize[size]
    for _, wound in ipairs(partState.wounds) do
        if wound.t == woundType and wound.s == size and not wound.b then
            local total = wound.n + count
            wound.w = (wound.n * (wound.w or woundSize) + woundSize * count) / total
            wound.n = total
            state.dirty = true
            return
        end
    end
    partState.wounds[#partState.wounds + 1] = { t = woundType, s = size, n = count, w = woundSize, d = woundSize }
    state.dirty = true
end

local PART_BLEED_CAP = {
    head = BODY_BLEED_CAP * 0.9,
    torso = BODY_BLEED_CAP,
    arm_l = BODY_BLEED_CAP * 0.3,
    arm_r = BODY_BLEED_CAP * 0.3,
    leg_l = BODY_BLEED_CAP * 0.5,
    leg_r = BODY_BLEED_CAP * 0.5,
}

function KMS.CardiacOutput(state, blood)
    local frac = (blood or state.blood) / KMS.Settings.maxBlood
    return math.max(KMS.MinCardiacOutput, BloodRamp(frac) * (state.hr / BASE_HR))
end

function KMS.BleedBand(flow, state)
    if flow <= 0 then return 0 end
    local knockOut = 0.5 * KMS.CardiacOutput(state) * KMS.BodyBleedCap
    if flow < knockOut * 0.1 then return 1 end
    if flow < knockOut * 0.5 then return 2 end
    if flow < knockOut then return 3 end
    return 4
end

local function BleedFlow(state, raw, blood)
    return raw * KMS.CardiacOutput(state, blood) * KMS.Coef("bleedCoef") * (state.bleedCoef or 1) / math.max(0.01, BloodResist(state))
end

function KMS.BleedRate(state)
    if KMS.MedFlag(state, "stasis") then return 0, 0 end
    local body, limbs = 0, 0
    for partId, partState in pairs(state.parts) do
        if not partState.tq then
            local partFlow = 0
            for _, wound in ipairs(partState.wounds) do
                if not wound.b then
                    partFlow = partFlow + KMS.WoundFlow(wound)
                end
            end
            partFlow = math.min(partFlow, PART_BLEED_CAP[partId])
            if partId == "head" or partId == "torso" then
                body = body + partFlow
            else
                limbs = limbs + partFlow
            end
        end
    end
    body = math.min(body, BODY_BLEED_CAP)
    local raw = body + math.min(limbs, BODY_BLEED_CAP) * (1 - body / BODY_BLEED_CAP)
    if raw <= 0 then return 0, 0 end
    return BleedFlow(state, raw, state.blood), raw
end

local BleedRate = KMS.BleedRate

local ARREST_BLOOD, BLEEDOUT_BLOOD = 0.6, 0.5

local function BleedingParts(state)
    local parts = {}
    for partId, partState in pairs(state.parts) do
        if not partState.tq then
            for _, wound in ipairs(partState.wounds) do
                if not wound.b and KMS.Wounds[wound.t].bleed > 0 then
                    parts[#parts + 1] = partId
                    break
                end
            end
        end
    end
    return parts
end

local function EmitBlood(ply, state, flow)
    local now = CurTime()
    if now < (state.nextBloodFx or 0) then return end
    state.nextBloodFx = now + math.Clamp(8 / flow, 0.5, 3)
    local parts = BleedingParts(state)
    if #parts == 0 then return end
    local partId = parts[math.random(#parts)]
    local displayEnt = IsValid(ply.KMSRagdoll) and ply.KMSRagdoll or ply
    local pos = displayEnt:WorldSpaceCenter()
    local boneName = KMS.PartById[partId].bone
    local boneIndex = boneName and displayEnt:LookupBone(boneName)
    if boneIndex then
        local bonePos = displayEnt:GetBonePosition(boneIndex)
        if bonePos then pos = bonePos end
    end
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetNormal(Vector(0, 0, -1))
    effect:SetColor(0)
    effect:SetFlags(3)
    effect:SetScale(math.Clamp(flow, 2, 8))
    util.Effect("bloodspray", effect)
    state.bloodFxCount = (state.bloodFxCount or 0) + 1
    if state.bloodFxCount % 2 == 0 then
        util.Decal("Blood", pos, pos - Vector(0, 0, 96), displayEnt)
    end
end

local function UpdateMobility(ply, state)
    if not ply:IsPlayer() then return end
    local broken, degraded, nojog = 0, 0, false
    local armsBroken = 0
    for _, part in ipairs(KMS.Parts) do
        if part.leg then
            local partState = state.parts[part.id]
            if partState.frac and not partState.splint and KMS.Settings.fractureMode ~= "disabled" then
                broken = broken + 1
            elseif partState.frac and partState.splint and KMS.Settings.fractureMode == "splint_nojog" then
                nojog = true
            elseif partState.frac and partState.splint and KMS.Settings.fractureMode == "splint_nosprint" then
                degraded = degraded + 1
            elseif KMS.Settings.limpingEnabled then
                for _, wound in ipairs(partState.wounds) do
                    if not wound.b and (wound.d or 0) > KMS.LimpDamage and KMS.Wounds[wound.t].limp then
                        degraded = degraded + 1
                        break
                    end
                end
            end
        elseif part.limb then
            local partState = state.parts[part.id]
            if partState.frac and not partState.splint and KMS.Settings.fractureMode ~= "disabled" then
                armsBroken = armsBroken + 1
            end
        end
    end
    local mobility = (broken >= 2 or nojog) and 2 or ((broken > 0 or degraded > 0) and 1 or 0)
    if ply:GetNWInt("kms_mobility", 0) ~= mobility then
        ply:SetNWInt("kms_mobility", mobility)
    end
    local noArms = KMS.Settings.disarmEnabled and armsBroken >= 2
    if ply:GetNWBool("kms_noarms", false) ~= noArms then
        ply:SetNWBool("kms_noarms", noArms)
        if noArms then KMS.Notify(ply, "warn", "msg_arms_broken") end
    end
    if broken == 1 and mobility == 1 then
        if not ply.KMSJumpPower then ply.KMSJumpPower = ply:GetJumpPower() end
        ply:SetJumpPower(ply.KMSJumpPower * 0.55)
    else
        KMS.RestoreJump(ply)
    end
end

local function SpawnStateRagdoll(ply)
    if not ply:Alive() then return nil end
    local ragdoll = ents.Create("prop_ragdoll")
    if not IsValid(ragdoll) then return nil end
    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(ply:GetAngles())
    ragdoll:SetSkin(ply:GetSkin())
    ragdoll:Spawn()
    ragdoll:Activate()
    ragdoll.KMSOwner = ply
    ragdoll.PhysgunDisabled = true
    local velocity = ply:GetVelocity()
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            local bone = ragdoll:TranslatePhysBoneToBone(i)
            if bone >= 0 then
                local pos, ang = ply:GetBonePosition(bone)
                if pos then phys:SetPos(pos) end
                if ang then phys:SetAngles(ang) end
            end
            phys:SetVelocity(velocity)
        end
    end
    ply.KMSRagdoll = ragdoll
    ply:SetNWEntity("kms_ragdoll", ragdoll)
    ply:SetNoDraw(true)
    ply:SetNotSolid(true)
    ply:SetMoveType(MOVETYPE_NONE)
    ply:Spectate(OBS_MODE_CHASE)
    ply:SpectateEntity(ragdoll)
    ply:SetSaveValue("m_takedamage", 2)
    return ragdoll
end

local function PlaceBesideVehicle(ply, root)
    local center = root:WorldSpaceCenter()
    local radius = root:BoundingRadius() * 0.6 + 24
    for _, dir in ipairs({ root:GetRight(), -root:GetRight(), root:GetForward(), -root:GetForward() }) do
        local target = center + dir * radius
        local ground = util.TraceLine({ start = target, endpos = target - Vector(0, 0, 128), mask = MASK_PLAYERSOLID, filter = { ply, root } })
        local pos = ground.Hit and (ground.HitPos + Vector(0, 0, 4)) or target
        local hull = util.TraceHull({
            start = pos + Vector(0, 0, 4),
            endpos = pos + Vector(0, 0, 4),
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 64),
            mask = MASK_PLAYERSOLID,
            filter = { ply, root },
        })
        if not hull.Hit then
            ply:SetPos(pos)
            return
        end
    end
    ply:SetPos(center + Vector(0, 0, root:OBBMaxs().z + 8))
end

function KMS.DownPlayer(ply)
    local state = ply.KMSState
    if not state or not state.conscious then return end
    if ply.KMSSim then
        state.conscious = false
        state.dirty = true
        return
    end
    if not ply:Alive() then return end
    if IsValid(ply.KMSRagdoll) then return end
    if IsValid(ply:GetVehicle()) then ply:ExitVehicle() end
    state.conscious = false
    state.dirty = true
    state.downPos = ply:GetPos()
    state.downAt = CurTime()
    state.nextWake = CurTime() + KMS.Settings.wakeInterval
    ply:SetNWFloat("kms_medcall", 0)
    if not SpawnStateRagdoll(ply) then
        state.conscious = true
        return
    end
    if ply.KMSJob then KMS.CancelTreatment(ply, true) end
    hook.Run("KMS_PlayerDowned", ply)
end

function KMS.WakePlayer(ply)
    local state = ply.KMSState
    if not state or state.conscious then return end
    if ply.KMSSim then
        KMS.FinishSim(ply, "passed")
        return
    end
    if not ply:Alive() then return end
    ply:SetNWBool("kms_treatlock", false)
    state.conscious = true
    state.koUntil = nil
    state.dirty = true
    local pos, yaw = ply:GetPos(), ply:EyeAngles().yaw
    if state.loadedIn then
        local root = state.loadedIn
        state.loadedIn = nil
        ply:SetNWEntity("kms_loaded_in", NULL)
        if IsValid(root) then PlaceBesideVehicle(ply, root) end
        pos = ply:GetPos()
    end
    local ragdoll = ply.KMSRagdoll
    ply.KMSRagdoll = nil
    ply:SetNWEntity("kms_ragdoll", NULL)
    if IsValid(ragdoll) then
        local target = ragdoll:GetPos() + Vector(0, 0, 8)
        ragdoll:Remove()
        local trace = util.TraceHull({
            start = target,
            endpos = target,
            mins = Vector(-16, -16, 0),
            maxs = Vector(16, 16, 72),
            mask = MASK_PLAYERSOLID,
            filter = player.GetAll(),
        })
        pos = trace.Hit and (state.downPos or target) or target
    end
    RestoreBody(ply)
    local wakeHp = math.floor(ply:GetMaxHealth() * KMS.Coef("wakeHealth"))
    if ply:Health() < wakeHp then ply:SetHealth(wakeHp) end
    ply:SetPos(pos)
    ply:SetEyeAngles(Angle(0, yaw, 0))
    ply:SetVelocity(-ply:GetVelocity())
    KMS.Notify(ply, "success", "msg_wake")
    hook.Run("KMS_PlayerWoke", ply)
end

function KMS.FullHeal(patient)
    local state = patient.KMSState
    if not state then return end
    for _, partState in pairs(state.parts) do
        if partState.tq then KMS.GiveItem(patient, "tourniquet") end
        partState.wounds = {}
        partState.st = nil
        partState.frac = false
        partState.splint = false
        partState.tq = false
        partState.tqAt = 0
        partState.dmg = 0
    end
    state.blood = KMS.Settings.maxBlood
    state.pain = 0
    state.veraxAt = nil
    state.drownDmg = nil
    state.hr = BASE_HR
    state.spo2 = KMS.NormalSpO2
    state.meds = {}
    state.medFx = nil
    state.arrest = false
    state.cprBy = nil
    state.triage = 0
    state.ivBags = nil
    state.lastAttacker = nil
    state.lastInflictor = nil
    state.lastAttackerAt = nil
    patient:SetHealth(patient:GetMaxHealth())
    state.lastBloodFrac, state.hpCarry = 1, nil
    KMS.RestoreJump(patient)
    patient:SetNWInt("kms_mobility", 0)
    patient:SetNWBool("kms_noarms", false)
    patient:SetNWBool("kms_arrest", false)
    patient:SetNWInt("kms_triage", 0)
    if not state.conscious then KMS.WakePlayer(patient) end
    KMS.MarkDirty(patient)
end

local function DamageProtected(ply, attacker)
    if ply:HasGodMode() then return true end
    return hook.Run("PlayerShouldTakeDamage", ply, IsValid(attacker) and attacker or ply) == false
end

function KMS.KillPatient(ply, reason)
    if ply.KMSSim then
        KMS.FinishSim(ply, "dead")
        return
    end
    local state = ply.KMSState
    if not state or not ply:Alive() then return end
    local attacker = (CurTime() - (state.lastAttackerAt or 0) <= ATTRIBUTION_WINDOW) and state.lastAttacker or nil
    if DamageProtected(ply, attacker) then return end
    if state.loadedIn then
        state.loadedIn = nil
        ply:SetNWEntity("kms_loaded_in", NULL)
    end
    ply.KMSSuppress = true
    local ragdoll = ply.KMSRagdoll
    if IsValid(ragdoll) then
        ply:SetPos(ragdoll:GetPos())
        ragdoll:Remove()
    end
    ply.KMSRagdoll = nil
    ply:SetNWEntity("kms_ragdoll", NULL)
    RestoreBody(ply)
    if IsValid(attacker) then
        local dmg = DamageInfo()
        dmg:SetDamage(ply:Health() + 100)
        dmg:SetAttacker(attacker)
        dmg:SetInflictor(IsValid(state.lastInflictor) and state.lastInflictor or attacker)
        dmg:SetDamageType(DMG_GENERIC)
        ply:TakeDamageInfo(dmg)
    end
    if ply:Alive() then ply:Kill() end
    ply.KMSSuppress = nil
    if ply:Alive() then return end
    state.triage = 4
    ply:SetNWInt("kms_triage", 4)
    local credit = IsValid(attacker) and attacker:IsPlayer()
        and string.format(" by %s [%s]", attacker:Nick(), attacker:SteamID()) or ""
    KMS.Log("info", string.format("%s died of %s%s", ply:Nick(), reason or "unknown", credit))
    hook.Run("KMS_PlayerDied", ply, IsValid(attacker) and attacker or nil, reason or "unknown")
end

KMS.Draggers = KMS.Draggers or {}
KMS.SimPatients = KMS.SimPatients or {}

function KMS.ValidPatient(ent)
    return IsValid(ent) and (ent:IsPlayer() or ent.KMSSim ~= nil) and ent.KMSState ~= nil
end

function KMS.CallMedic(ply)
    if not KMS.Settings.enabled or not KMS.Settings.medicCallEnabled then return end
    local state = ply.KMSState
    if not state or state.conscious or not ply:Alive() then return end
    local now = CurTime()
    local last = ply:GetNWFloat("kms_medcall", 0)
    if last > 0 and now - last < KMS.MedCallCooldown then return end
    ply:SetNWFloat("kms_medcall", now)
    local origin = KMS.BodyEnt(ply):GetPos()
    local rangeSqr = KMS.Settings.medicCallRange * KMS.Settings.medicCallRange
    local name = KF.Integrations.GetPlayerName(ply) or ply:Nick()
    for _, medic in ipairs(player.GetAll()) do
        if medic ~= ply and medic:Alive() and not KMS.Exempt(medic) and KMS.MedicTier(medic) >= 1 then
            local dist = medic:GetPos():DistToSqr(origin)
            if dist <= rangeSqr then
                KMS.Notify(medic, "warn", "msg_medic_call", name, math.Round(math.sqrt(dist) / KMS.DisplayUnitsPerMeter))
            end
        end
    end
    KMS.Notify(ply, "success", "msg_call_sent")
end

function KMS.GiveUp(ply)
    if not KMS.Settings.giveUpEnabled then return end
    local state = ply.KMSState
    if not state or state.conscious or not ply:Alive() then return end
    if CurTime() - (state.downAt or 0) < KMS.Settings.giveUpDelay then return end
    KMS.KillPatient(ply, "gave up")
end

local HAUL_MODES = {
    drag = {
        grips = {
            { match = "Pelvis", pos = Vector(26, 0, 17), ang = Angle(-50, 180, 180) },
            { match = "Spine2", pos = Vector(11, 0, 35), ang = Angle(-50, 180, 180) },
            { match = "Spine", pos = Vector(18, 0, 26), ang = Angle(-50, 180, 180) },
            { match = "Head", pos = Vector(5, 0, 42), ang = Angle(-30, 180, 180) },
            { match = "R_UpperArm", pos = Vector(13, -9, 33), ang = Angle(55, -150, 180) },
            { match = "L_UpperArm", pos = Vector(13, 9, 33), ang = Angle(55, 150, 180) },
            { match = "R_Thigh", pos = Vector(26, -5, 17), ang = Angle(25, -4, 180) },
            { match = "L_Thigh", pos = Vector(26, 5, 17), ang = Angle(25, 4, 180) },
            { match = "R_Calf", pos = Vector(42, -6, 9), ang = Angle(10, -4, 180) },
            { match = "L_Calf", pos = Vector(42, 6, 9), ang = Angle(10, 4, 180) },
        },
    },
    carry = {
        grips = {
            { match = "Pelvis", pos = Vector(-9, -13, 64), ang = Angle(0, 90, 0) },
            { match = "Spine2", pos = Vector(-8, 6, 65), ang = Angle(0, 90, 0) },
            { match = "Spine", pos = Vector(-9, -4, 65), ang = Angle(0, 90, 0) },
            { match = "Head", pos = Vector(3, 15, 57), ang = Angle(45, 80, 0) },
            { match = "R_UpperArm", pos = Vector(-4, 10, 63), ang = Angle(53, 35, 0) },
            { match = "L_UpperArm", pos = Vector(-10, 9, 62), ang = Angle(65, 45, 0) },
            { match = "R_Forearm", pos = Vector(2, 14, 52), ang = Angle(71, 27, 0) },
            { match = "L_Forearm", pos = Vector(-6, 13, 50), ang = Angle(82, 45, 0) },
            { match = "R_Thigh", pos = Vector(-4, -13, 63), ang = Angle(45, -9, 0) },
            { match = "L_Thigh", pos = Vector(-10, -14, 63), ang = Angle(48, -10, 0) },
            { match = "R_Calf", pos = Vector(7, -13, 50), ang = Angle(80, -15, 0) },
            { match = "L_Calf", pos = Vector(4, -14, 49), ang = Angle(82, -20, 0) },
        },
    },
}

local function ResolveGrips(ragdoll, modeId)
    local defs = HAUL_MODES[modeId].grips
    local used, grips = {}, {}
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local bone = ragdoll:TranslatePhysBoneToBone(i)
        local name = bone >= 0 and (ragdoll:GetBoneName(bone) or "") or ""
        for _, def in ipairs(defs) do
            if not used[def] and string.find(name, def.match, 1, true) then
                used[def] = true
                grips[#grips + 1] = { phys = i, def = def }
                break
            end
        end
    end
    if #grips == 0 then
        grips[1] = { phys = 0, def = defs[1] }
    end
    return grips
end

function KMS.StopDrag(ply)
    local patient = IsValid(ply) and ply.KMSDragging or KMS.Draggers[ply]
    if not patient then return end
    if IsValid(ply) then
        ply.KMSDragging = nil
        ply.KMSDragMode = nil
        ply:SetNWString("kms_hauling", "")
    end
    if IsValid(patient) then
        patient.KMSDraggedBy = nil
        local ragdoll = patient.KMSRagdoll
        if IsValid(ragdoll) then
            ragdoll.KMSGrips = nil
            if ragdoll.KMSOldGroup then
                ragdoll:SetCollisionGroup(ragdoll.KMSOldGroup)
                ragdoll.KMSOldGroup = nil
            end
            if patient.KMSState then
                patient.KMSState.downPos = ragdoll:GetPos()
            end
        end
    end
    KMS.Draggers[ply] = nil
end

local function CanHaul(ply, patient)
    if not IsValid(patient) or not patient:IsPlayer() or patient == ply then return false end
    local state = patient.KMSState
    if not state or state.conscious or not IsValid(patient.KMSRagdoll) then return false end
    if not ply:Alive() or not (ply.KMSState and ply.KMSState.conscious) then return false end
    if IsValid(patient.KMSDraggedBy) and patient.KMSDraggedBy ~= ply then return false end
    return true
end

local function ExecuteHaul(ply, patient, modeId)
    KMS.StopDrag(ply)
    local ragdoll = patient.KMSRagdoll
    ragdoll.KMSGrips = ResolveGrips(ragdoll, modeId)
    ragdoll.KMSOldGroup = ragdoll.KMSOldGroup or ragdoll:GetCollisionGroup()
    ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    ply.KMSDragging = patient
    ply.KMSDragMode = modeId
    ply:SetNWString("kms_hauling", modeId)
    patient.KMSDraggedBy = ply
    KMS.Draggers[ply] = patient
end

function KMS.ReleaseHaul(ply)
    if not ply.KMSDragging then return end
    if ply.KMSJob then
        KMS.Notify(ply, "error", "err_busy")
        return
    end
    local duration = KMS.Settings.releaseTime
    if duration <= 0 then
        KMS.StopDrag(ply)
        return
    end
    KMS.StartChannel(ply, "haul_release", duration, {
        patient = ply.KMSDragging,
        complete = function(actor)
            KMS.StopDrag(actor)
        end,
    })
end

function KMS.StartDrag(ply, patient, modeId)
    if not KMS.Settings.enabled then return end
    modeId = HAUL_MODES[modeId] and modeId or "drag"
    if not CanHaul(ply, patient) then return end
    if ply.KMSJob then
        KMS.Notify(ply, "error", "err_busy")
        return
    end
    if not KMS.CanReach(ply, patient) then
        KMS.Notify(ply, "error", "err_too_far")
        return
    end
    local duration = KMS.Settings[modeId == "carry" and "carryTime" or "dragTime"]
    if duration <= 0 then
        ExecuteHaul(ply, patient, modeId)
        return
    end
    KMS.StartChannel(ply, "haul_" .. modeId, duration, {
        patient = patient,
        mode = modeId,
        complete = function(actor, job)
            if not CanHaul(actor, job.patient) or not KMS.CanReach(actor, job.patient) then return end
            ExecuteHaul(actor, job.patient, job.mode)
        end,
    })
end

function KMS.LoadPatient(actor, patient, vehicle)
    if not KMS.Settings.enabled then return end
    local root = KMS.VehicleBase(vehicle)
    if not root then return end
    local state = patient.KMSState
    if not state or state.loadedIn then return end
    if not CanHaul(actor, patient) then return end
    if root:NearestPoint(actor:GetPos()):Distance(actor:GetPos()) > KMS.Settings.maxTreatDistance * KMS.ReachMargin
        or not KMS.CanReach(actor, patient, KMS.ReachMargin) then
        KMS.Notify(actor, "error", "err_too_far")
        return
    end
    if IsValid(patient.KMSDraggedBy) then KMS.StopDrag(patient.KMSDraggedBy) end
    state.loadedIn = root
    patient:SetNWEntity("kms_loaded_in", root)
    local ragdoll = patient.KMSRagdoll
    patient.KMSRagdoll = nil
    patient:SetNWEntity("kms_ragdoll", NULL)
    if IsValid(ragdoll) then ragdoll:Remove() end
    patient:SetPos(root:WorldSpaceCenter())
    patient:SpectateEntity(root)
    state.dirty = true
end

function KMS.UnloadPatient(actor, patient)
    local state = patient.KMSState
    local root = state and state.loadedIn
    if not root then return end
    if IsValid(actor) then
        if not actor:Alive() or not (actor.KMSState and actor.KMSState.conscious) then return end
        if not KMS.CanReach(actor, patient, 1.5) then
            KMS.Notify(actor, "error", "err_too_far")
            return
        end
    end
    state.loadedIn = nil
    patient:SetNWEntity("kms_loaded_in", NULL)
    if IsValid(root) then
        PlaceBesideVehicle(patient, root)
        state.downPos = patient:GetPos()
    end
    if not state.conscious and not IsValid(patient.KMSRagdoll) then
        local ragdoll = SpawnStateRagdoll(patient)
        if IsValid(ragdoll) then patient:SpectateEntity(ragdoll) end
    end
    state.dirty = true
end

local shadow = {
    secondstoarrive = 0.1,
    maxangular = 1500,
    maxangulardamp = 2000,
    maxspeed = 1500,
    maxspeeddamp = 2500,
    dampfactor = 0.8,
    teleportdistance = 32,
}

hook.Add("Think", "KMS_DragThink", function()
    for ply, patient in pairs(KMS.Draggers) do
        local ragdoll = IsValid(patient) and patient.KMSRagdoll or nil
        if not IsValid(ply) or not ply:Alive() or not (ply.KMSState and ply.KMSState.conscious)
            or not IsValid(ragdoll) or (patient.KMSState and patient.KMSState.conscious)
            or ply:GetPos():DistToSqr(ragdoll:GetPos()) > KMS.InteractRangeSqr then
            KMS.StopDrag(ply)
        else
            local base = ply:GetPos()
            local yaw = Angle(0, ply:EyeAngles().yaw, 0)
            local heightScale = ply:OBBMaxs().z / 72
            shadow.deltatime = FrameTime()
            for _, grip in ipairs(ragdoll.KMSGrips or {}) do
                local phys = ragdoll:GetPhysicsObjectNum(grip.phys)
                if IsValid(phys) then
                    local def = grip.def
                    local pos, ang = LocalToWorld(Vector(def.pos.x, def.pos.y, def.pos.z * heightScale), def.ang, base, yaw)
                    shadow.pos = pos
                    shadow.angle = ang
                    phys:Wake()
                    phys:ComputeShadowControl(shadow)
                end
            end
        end
    end
end)

hook.Add("KeyPress", "KMS_UseCancel", function(ply, key)
    if key ~= IN_USE then return end
    if ply.KMSJob then
        if CurTime() - (ply.KMSJob.startedAt or 0) > 0.2 then
            KMS.CancelTreatment(ply)
        end
        return
    end
    KMS.CallMedic(ply)
end)

local function Jitter()
    return 0.9 + (math.random() + math.random()) * 0.1
end

local function RollFracture(ply, state, partId, woundType, woundDamage, multiplier)
    if KMS.Settings.fractureMode == "disabled" then return end
    if not KMS.Wounds[woundType].frac then return end
    local part = KMS.PartById[partId]
    if not part or not part.limb then return end
    if woundDamage <= KMS.Settings.fractureThreshold / KMS.DamageDomain then return end
    if math.random() * 100 > KMS.Settings.fractureChance * (multiplier or 1) * ProfileCoef(ply, "fracture") then return end
    local partState = state.parts[partId]
    partState.frac = true
    partState.splint = false
    state.dirty = true
    ply:EmitSound("physics/flesh/flesh_bloody_break.wav", 75, math.random(90, 100))
end

local function CreateWound(ply, state, partId, entry, aceDamage)
    local partState = state.parts[partId]
    if not partState then return 0, 0 end
    local woundDamage = aceDamage * (entry.damage or 1) * Jitter()
    local units = math.min(1, woundDamage / KMS.WoundUnitDamage)
    local woundSize = KMS.WoundSize(woundDamage * (entry.size or 1))
    local category = KMS.WoundCategory(woundSize)
    local merged
    for _, wound in ipairs(partState.wounds) do
        if wound.t == entry.t and wound.s == category and not wound.b then
            merged = wound
            break
        end
    end
    if merged then
        local total = merged.n + units
        merged.w = (merged.n * merged.w + woundSize * units) / total
        merged.d = (merged.n * merged.d + woundDamage * units) / total
        merged.n = total
    else
        partState.wounds[#partState.wounds + 1] = { t = entry.t, s = category, n = units, w = woundSize, d = woundDamage }
    end
    partState.dmg = (partState.dmg or 0) + woundDamage
    state.dirty = true
    RollFracture(ply, state, partId, entry.t, woundDamage, entry.frac)
    return woundSize * (entry.pain or 1) * KMS.Wounds[entry.t].pain, woundDamage
end

local function ApplyWoundClass(ply, state, partId, class, aceDamage)
    local count = KMS.InterpolatePoints(aceDamage, class.thresholds, true)
    if count < 1 then return 0, 0 end
    local per = aceDamage / count
    local entries, weights, total = {}, {}, 0
    for _, entry in ipairs(class.wounds) do
        local weight = KMS.InterpolatePoints(per, entry.weight, false)
        if weight > 0 then
            entries[#entries + 1] = entry
            weights[#weights + 1] = weight
            total = total + weight
        end
    end
    if total <= 0 then return 0, 0 end
    local pain, worst = 0, 0
    for _ = 1, count do
        local entry = KMS.SelectWeighted(entries, weights, total)
        local woundPain, woundDamage = CreateWound(ply, state, partId, entry, per)
        pain = pain + woundPain
        worst = math.max(worst, woundDamage)
    end
    return pain, worst
end

local function SpreadShares(class, partId, aceDamage)
    if not class.spread then return { { partId, aceDamage } } end
    local shares = {}
    for _, entry in ipairs(class.spread) do
        shares[#shares + 1] = { entry[1], aceDamage * math.min(1, entry[2] + (entry[1] == partId and 0.4 or 0)) }
    end
    return shares
end

-- Explicit wound/blood healing for KMS items and integrations. Health itself is engine-owned:
-- an external heal that only raises health stays as health, it is not folded back into wounds.
local FRACTURE_LOAD = 0.05

local function WoundLoad(wound)
    return (wound.w or KMS.WoundSizeFloor) * 3 * (wound.b and 0.02 or 0.05)
end

function KMS.ExternalHeal(ply, gainFrac)
    local state = ply.KMSState
    if not state or gainFrac <= 0 then return end
    local budget = gainFrac
    for _, partState in pairs(state.parts) do
        for i = #partState.wounds, 1, -1 do
            if budget <= 0 then break end
            local wound = partState.wounds[i]
            local events = KMS.WoundEvents(wound)
            local eventLoad = WoundLoad(wound)
            local healedEvents = math.min(events, budget / eventLoad)
            wound.n = wound.n - wound.n * healedEvents / events
            partState.dmg = math.max(0, (partState.dmg or 0) - (wound.d or 0) * healedEvents)
            budget = budget - healedEvents * eventLoad
            if wound.n <= KMS.WoundEpsilon then table.remove(partState.wounds, i) end
        end
        if partState.frac and budget >= FRACTURE_LOAD then
            partState.frac = false
            partState.splint = false
            budget = budget - FRACTURE_LOAD
        end
    end
    state.blood = math.min(KMS.Settings.maxBlood, state.blood + budget * KMS.Settings.maxBlood)
    state.pain = math.max(0, state.pain - gainFrac)
    if gainFrac >= 0.02 and CurTime() >= (state.nextHealLog or 0) then
        state.nextHealLog = CurTime() + 10
        local tag = ply.KMSHealSource
        local name = tag and tag.untilT > CurTime() and tag.name or "#src_external"
        KMS.AddLog(ply, "log_ext_heal", name)
    end
    state.dirty = true
end

function KMS.TagHealSource(ply, name)
    ply.KMSHealSource = { name = tostring(name), untilT = CurTime() + 3 }
end

function KMS.RelievePain(ply, frac)
    local state = ply.KMSState
    if not state then return end
    state.pain = math.max(0, state.pain - frac)
    state.dirty = true
end

function KMS.HasPain(ply)
    local state = ply.KMSState
    return state ~= nil and state.pain > 0.01
end

local ENERGY_TYPES = bit.bor(DMG_ENERGYBEAM, DMG_PLASMA, DMG_SHOCK, DMG_DISSOLVE)
local ENERGY_MASK = bit.bor(ENERGY_TYPES, DMG_BURN)
local INTERNAL_MASK = bit.bor(DMG_DROWN, DMG_POISON, DMG_NERVEGAS, DMG_RADIATION)
local DOMAIN_SCALE = 2.5

local ENERGY_WEAPON_BASES = {
    arccw_masita_base_updated = true,
    arc9_kraken_base_updated = true,
}

local function DamageClassName(dmginfo)
    local inflictor = dmginfo:GetInflictor()
    if IsValid(inflictor) and inflictor.LSCS == true then return "plasma" end
    local damageType = dmginfo:GetDamageType()
    if dmginfo:IsBulletDamage() then
        if KMS.Settings.blasterMode or bit.band(damageType, ENERGY_MASK) ~= 0
            or ENERGY_WEAPON_BASES[IsValid(inflictor) and inflictor.Base or ""] then
            return "plasma"
        end
        return "bullet"
    end
    if bit.band(damageType, ENERGY_TYPES) ~= 0 then return "plasma" end
    if dmginfo:IsDamageType(DMG_BLAST) then
        local class = IsValid(inflictor) and inflictor:GetClass() or ""
        if string.find(class, "nade", 1, true) or string.find(class, "ubgl", 1, true) then return "grenade" end
        if string.find(class, "rocket", 1, true) or string.find(class, "missile", 1, true) then return "shell" end
        return "explosive"
    end
    if dmginfo:IsDamageType(DMG_BURN) or dmginfo:IsDamageType(DMG_SLOWBURN) then return "burn" end
    if dmginfo:IsDamageType(DMG_SLASH) then return "stab" end
    if dmginfo:IsDamageType(DMG_FALL) then return "falling" end
    if dmginfo:IsDamageType(DMG_VEHICLE) then return "vehiclecrash" end
    if dmginfo:IsDamageType(DMG_CLUB) then return "punch" end
    if dmginfo:IsDamageType(DMG_CRUSH) then return "collision" end
    return "unknown"
end

function KMS.EnterArrest(ply, state)
    if state.arrest then return end
    KMS.DownPlayer(ply)
    if state.conscious then return end
    state.arrest = true
    state.hr = 0
    state.arrestLeft = KMS.Settings.arrestTime * (0.9 + 0.1 * (math.random() + math.random()))
    state.dirty = true
    ply:SetNWBool("kms_arrest", true)
end

local EnterArrest = KMS.EnterArrest

local function ApplyDamageWounds(ply, partId, dmginfo, damage, rawScaled)
    if damage <= 0 then return end
    local state = ply.KMSState
    if bit.band(dmginfo:GetDamageType(), INTERNAL_MASK) ~= 0 then
        if (dmginfo:IsDamageType(DMG_RADIATION) and KMS.MedFlag(state, "radShield"))
            or ((dmginfo:IsDamageType(DMG_POISON) or dmginfo:IsDamageType(DMG_NERVEGAS)) and KMS.MedFlag(state, "toxShield")) then
            return
        end
        local maxHp = math.max(1, ply:GetMaxHealth())
        state.drownDmg = (state.drownDmg or 0) + rawScaled
        state.pain = math.max(state.pain, math.min(0.6, state.drownDmg / maxHp * 0.6))
        state.dirty = true
        if state.drownDmg >= maxHp then
            EnterArrest(ply, state)
        end
        return
    end
    local class = KMS.DamageClasses[DamageClassName(dmginfo)]
    local aceDamage = damage / math.max(1, ply:GetMaxHealth())
    local pain, worst, critical = 0, 0, false
    for _, share in ipairs(SpreadShares(class, partId, aceDamage)) do
        local sharePain, shareWorst = ApplyWoundClass(ply, state, share[1], class, share[2] * PartCoef(ply, share[1]))
        pain = pain + sharePain
        worst = math.max(worst, shareWorst)
        if shareWorst > 0 and (share[1] == "head" or (share[1] == "torso" and shareWorst > KMS.PenetrationDamage)) then
            critical = true
        end
    end
    if worst <= 0 then return 0 end
    local hitPain = pain * KMS.Coef("painCoef") * ProfileCoef(ply, "pain")
    state.pain = math.Clamp(math.max(state.pain, hitPain), 0, 1)
    if state.conscious and (critical or hitPain > KMS.PainUnconscious)
        and KMS.PerceivedPain(state) >= KMS.PainUnconscious
        and math.random(100) <= KMS.Settings.painKoChance
        and not KMS.MedFlag(state, "shock") then
        KMS.DownPlayer(ply)
    end
    local size = KMS.WoundCategory(KMS.WoundSize(worst))
    if state.conscious then
        ply:ViewPunch(Angle(-math.Rand(1.5, 3) * size, math.Rand(-1.5, 1.5) * size, 0))
    end
    if size >= 3 then
        ply:SetNWFloat("kms_stagger", CurTime() + 0.6)
    end
    return worst
end

local function PenetratingDamage(partState)
    local total = partState.dmg or 0
    for _, wound in ipairs(partState.wounds) do
        if (wound.d or 1) < KMS.PenetrationDamage then
            total = total - (wound.d or 0) * KMS.WoundEvents(wound)
        end
    end
    return math.max(0, total)
end

function KMS.BodyEnt(ply)
    return IsValid(ply.KMSRagdoll) and ply.KMSRagdoll or ply
end

function KMS.CanReach(actor, patient, rangeMult)
    if patient:IsPlayer() then
        if KMS.Exempt(actor) or KMS.Exempt(patient) or KMS.Cloaked(patient) then return false end
        if KMS.SameVehicle(actor, patient) then return true end
    end
    local target = KMS.BodyEnt(patient)
    if actor:GetPos():Distance(target:GetPos()) > KMS.Settings.maxTreatDistance * (rangeMult or 1) then return false end
    return KMS.ClearSight(actor, target)
end

hook.Add("ScalePlayerDamage", "KMS_TrackHitgroup", function(ply, hitgroup, dmginfo)
    if not KMS.Settings.enabled then return end
    if ply.KMSHitgroupTime ~= CurTime() then
        ply.KMSHitgroupTime = CurTime()
        ply.KMSHitDamage = {}
    end
    ply.KMSHitDamage[hitgroup] = (ply.KMSHitDamage[hitgroup] or 0) + dmginfo:GetDamage()
end)

hook.Add("GetFallDamage", "KMS_FallDamage", function(ply, speed)
    if not KMS.Settings.enabled or not ply.KMSState then return end
    if KMS.Exempt(ply) or ply:HasGodMode() then return end
    return math.max(0, (speed - 526.5) * (100 / 396))
end, HOOK_LOW)

local RAGDOLL_BONE_PARTS = {
    { match = "Head", part = "head" },
    { match = "Neck", part = "head" },
    { match = "L_UpperArm", part = "arm_l" },
    { match = "L_Forearm", part = "arm_l" },
    { match = "L_Hand", part = "arm_l" },
    { match = "R_UpperArm", part = "arm_r" },
    { match = "R_Forearm", part = "arm_r" },
    { match = "R_Hand", part = "arm_r" },
    { match = "L_Thigh", part = "leg_l" },
    { match = "L_Calf", part = "leg_l" },
    { match = "L_Foot", part = "leg_l" },
    { match = "R_Thigh", part = "leg_r" },
    { match = "R_Calf", part = "leg_r" },
    { match = "R_Foot", part = "leg_r" },
}

local function PartFromRagdoll(ragdoll, pos)
    local bestPart, bestDist
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            local bone = ragdoll:TranslatePhysBoneToBone(i)
            local name = bone >= 0 and (ragdoll:GetBoneName(bone) or "") or ""
            local part = "torso"
            for _, entry in ipairs(RAGDOLL_BONE_PARTS) do
                if string.find(name, entry.match, 1, true) then
                    part = entry.part
                    break
                end
            end
            local dist = phys:GetPos():DistToSqr(pos)
            if not bestDist or dist < bestDist then
                bestDist = dist
                bestPart = part
            end
        end
    end
    return bestPart or "torso"
end

local function PartFromHull(ply, pos)
    local height = ply:OBBMaxs().z
    if height <= 0 then return "torso" end
    local localPos = WorldToLocal(pos, angle_zero, ply:GetPos(), Angle(0, ply:GetAngles().yaw, 0))
    local zf = localPos.z / height
    if zf >= 0.82 then return "head" end
    if zf <= 0.5 then return localPos.y >= 0 and "leg_l" or "leg_r" end
    if math.abs(localPos.y) >= height * 0.16 then return localPos.y >= 0 and "arm_l" or "arm_r" end
    return "torso"
end

local BURN_PARTS = { "torso", "leg_l", "leg_r" }
local SCATTER_MASK = bit.bor(DMG_CRUSH, DMG_CLUB, DMG_VEHICLE)

function KMS.PartFromDamage(ply, dmginfo)
    if dmginfo:IsDamageType(DMG_FALL) then return math.random(2) == 1 and "leg_l" or "leg_r" end
    if dmginfo:IsDamageType(DMG_BURN) or dmginfo:IsDamageType(DMG_SLOWBURN) then
        return BURN_PARTS[math.random(#BURN_PARTS)]
    end
    local pos = dmginfo:GetDamagePosition()
    if isvector(pos) and not pos:IsZero() then
        return PartFromHull(ply, pos)
    end
    if bit.band(dmginfo:GetDamageType(), SCATTER_MASK) ~= 0 then
        return KMS.Parts[math.random(#KMS.Parts)].id
    end
    return "torso"
end

-- Health is owned by the engine. KMS never writes a health value it computed from the medical
-- state; it lets the effective damage through, keeps the engine from killing a revivable patient,
-- and adds the medical consequences (wounds, bleeding, pain, collapse) of what actually landed.
--
-- EntityTakeDamage runs before the engine applies damage, at whatever position other addons leave
-- it: it only records the hit context and applies KMS's own rules (direct damage share, revive
-- floor). It never cancels a hit on behalf of another system.
-- PostEntityTakeDamage runs after every EntityTakeDamage hook and the engine: blocked, cancelled
-- or zeroed hits arrive with took=false and are ignored, everything else is processed with the
-- damage that survived the whole pipeline, whatever the hook order was.

local function Patient(ent)
    if not ent:IsPlayer() or ent.KMSSuppress or not ent:Alive() or KMS.Exempt(ent) then return nil end
    return ent.KMSState
end

local function Trace(ent, fmt, ...)
    local msg = string.format("[KMS TRACE] %s | " .. fmt, ent:Nick(), ...)
    print(msg)
    local admin = ent.KMSTrace
    if isentity(admin) and IsValid(admin) then admin:PrintMessage(HUD_PRINTCONSOLE, msg) end
end

local function CountWounds(state)
    local n = 0
    for _, partState in pairs(state.parts) do n = n + #partState.wounds end
    return n
end

-- effective: the damage this hit represents for the medical model (after every other addon's
-- modifications, before KMS's own direct-damage share). applied: what the engine took off health.
local function MedicalConsequences(ent, state, dmginfo, ctx, effective, applied)
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker ~= ent and not attacker:IsWorld() then
        state.lastAttacker = attacker
        state.lastInflictor = dmginfo:GetInflictor()
        state.lastAttackerAt = CurTime()
    end
    if IsValid(attacker) and attacker ~= ent and attacker:IsPlayer() then
        local sourceEnt = dmginfo:GetInflictor()
        local key
        if IsValid(sourceEnt) and sourceEnt.LSCS then
            key = "log_saber_hurt"
        else
            local held = attacker:GetActiveWeapon()
            if IsValid(held) and held.LSCS then key = "log_force_hurt" end
        end
        if key then
            local hurtLog = state.nextHurtLog or {}
            state.nextHurtLog = hurtLog
            if CurTime() >= (hurtLog[key] or 0) then
                hurtLog[key] = CurTime() + 5
                KMS.AddLog(ent, key, KF.Integrations.GetPlayerName(attacker) or attacker:Nick())
            end
        end
    end
    hook.Run("KMS_PlayerDamaged", ent, dmginfo)
    local partId = ctx and ctx.part or KMS.PartFromDamage(ent, dmginfo)
    local hpBefore = ctx and ctx.hp or ent:Health() + math.floor(applied)
    local rawScaled = effective * KMS.Coef("damageScale") * ProfileCoef(ent, "damage")
    local med = rawScaled * DOMAIN_SCALE
    -- Armour is the engine's business; what it kept from health shows up as a smaller health loss.
    local healthFrac = 1
    if ctx and applied > 0 and ent:Armor() < ctx.armor then
        healthFrac = math.Clamp((ctx.hp - ent:Health()) / applied, 0.2, 1)
        med = med * math.max(0.5, healthFrac)
    end
    local tracing = ent.KMSTrace ~= nil
    local woundsBefore = tracing and CountWounds(state) or 0
    local worst = ApplyDamageWounds(ent, partId, dmginfo, med, rawScaled) or 0
    local verdict = "wounded"
    local maxHp = ent:GetMaxHealth()
    if bit.band(dmginfo:GetDamageType(), INTERNAL_MASK) == 0 then
        local headDmg = state.parts.head.dmg or 0
        local torsoDmg = PenetratingDamage(state.parts.torso)
        local fatalCore = false
        if maxHp > 0 and math.random(100) <= KMS.Settings.deathChance then
            fatalCore = (partId == "head" and worst >= 1)
                or (partId == "torso" and worst >= 0.6 and math.random(100) <= 5)
            if not fatalCore and (partId == "head" or partId == "torso" or KMS.Settings.limbTrauma) then
                local vitalDamage = math.max(0, headDmg - KMS.TraumaThresholds.head) + math.max(0, torsoDmg - KMS.TraumaThresholds.torso)
                if KMS.Settings.limbTrauma then
                    for _, part in ipairs(KMS.Parts) do
                        if part.limb then
                            vitalDamage = vitalDamage + math.max(0, (state.parts[part.id].dmg or 0) - KMS.Settings.limbTraumaThreshold)
                        end
                    end
                end
                if vitalDamage > 0 then
                    fatalCore = math.random() < 1 - math.exp(-((vitalDamage / 0.7045) ^ 6.56))
                end
            end
        end
        if fatalCore and KMS.Settings.fatalMode == "never" then fatalCore = false end
        local lethal = effective * healthFrac >= hpBefore
        if fatalCore and (KMS.Settings.fatalMode == "always" or state.arrest) then
            verdict = "killed (fatal wound)"
            KMS.KillPatient(ent, "fatal wound")
        elseif fatalCore and not state.conscious then
            verdict = "arrest"
            EnterArrest(ent, state)
        elseif state.conscious then
            local traumaKo = (partId == "head" or partId == "torso") and (headDmg > 0.5 or torsoDmg > 1)
            if not KMS.Settings.reviveEnabled then
                if lethal then
                    verdict = "killed (lethal)"
                    KMS.KillPatient(ent, "lethal damage")
                end
            elseif lethal or fatalCore or traumaKo then
                verdict = "downed"
                KMS.DownPlayer(ent)
                local core = partId == "head" or partId == "torso"
                if (fatalCore or (lethal and core)) and KMS.Settings.fatalMode == "arrest" then
                    verdict = "downed + arrest"
                    EnterArrest(ent, state)
                end
            end
        end
    end
    if tracing then
        Trace(ent, "result: engine took %.1f | medical damage %.1f (armor kept %.0f%%) | part %s | wounds %d -> %d | blood %.0f mL | pain %.2f | hp %d -> %d | %s",
            applied, effective, (1 - healthFrac) * 100, partId, woundsBefore, CountWounds(state), state.blood, state.pain,
            hpBefore, IsValid(ent) and ent:Health() or 0, verdict)
    end
end

local function PreDamage(ent, dmginfo)
    if not KMS.Settings.enabled then return end
    if ent:IsPlayer() then
        local accum, accumTime = ent.KMSHitDamage, ent.KMSHitgroupTime
        ent.KMSHitDamage, ent.KMSHitgroupTime = nil, nil
        local state = Patient(ent)
        if not state or DamageProtected(ent, dmginfo:GetAttacker()) then return end
        if dmginfo:GetDamage() <= 0 or dmginfo:GetDamageType() == DMG_REMOVENORAGDOLL then return end
        if IsValid(ent.KMSRagdoll) and not ent.KMSForwarding
            and bit.band(dmginfo:GetDamageType(), INTERNAL_MASK) == 0 then
            dmginfo:SetDamage(0)
            return true
        end
        local sourceWep = dmginfo:GetInflictor()
        if IsValid(sourceWep) and string.EndsWith(sourceWep:GetClass(), "_training") then
            local sting = math.min(0.35, dmginfo:GetDamage() * DOMAIN_SCALE / math.max(1, ent:GetMaxHealth()) + 0.1)
            state.pain = math.max(state.pain, sting)
            state.dirty = true
            dmginfo:SetDamage(0)
            return true
        end
        local hitPart
        if not ent.KMSForcePart and accumTime == CurTime() and accum then
            local bestDamage
            for hitgroup, damage in pairs(accum) do
                local part = KMS.HitgroupToPart[hitgroup]
                if part and (not bestDamage or damage > bestDamage) then
                    hitPart, bestDamage = part, damage
                end
            end
        end
        local partId = ent.KMSForcePart or hitPart or KMS.PartFromDamage(ent, dmginfo)
        if KMS.Settings.koEnabled and partId == "head" and state.conscious then
            local attacker = dmginfo:GetAttacker()
            if IsValid(attacker) and attacker:IsPlayer() and attacker ~= ent then
                local weapon = attacker:GetActiveWeapon()
                if IsValid(weapon) and table.HasValue(KMS.Settings.koWeapons, weapon:GetClass()) then
                    KMS.DownPlayer(ent)
                    state.koUntil = CurTime() + KMS.Settings.koTime
                    state.nextWake = state.koUntil
                    return true
                end
            end
        end
        local damage = dmginfo:GetDamage()
        local ctx = { time = CurTime(), part = partId, hp = ent:Health(), armor = ent:Armor() }
        -- KMS's own damage rule, applied like any other modifier: only directDamage% of the hit
        -- reaches health, while the whole hit drives the medical consequences (ctx.scale undoes
        -- the share in PostEntityTakeDamage, so multipliers applied after us still compose).
        local direct = damage * KMS.Coef("directDamage")
        if KMS.Settings.reviveEnabled then direct = math.min(direct, ent:Health() - 1) end
        if direct < 1 then
            -- The engine truncates damage to whole points, so nothing of this hit could be applied
            -- (health is already at the revive floor, or the hit is below one point): consume it
            -- here and process the consequences directly.
            if ent.KMSTrace then
                Trace(ent, "pre-hook: %s by %s | type %d | damage %.1f | hp %d | nothing left for the engine, processing here",
                    IsValid(sourceWep) and sourceWep:GetClass() or "world", IsValid(dmginfo:GetAttacker()) and tostring(dmginfo:GetAttacker()) or "world",
                    dmginfo:GetDamageType(), damage, ctx.hp)
            end
            MedicalConsequences(ent, state, dmginfo, ctx, damage, 0)
            dmginfo:SetDamage(0)
            return
        end
        ctx.scale = damage / direct
        ent.KMSHit = ctx
        dmginfo:SetDamage(direct)
        if ent.KMSTrace then
            Trace(ent, "pre-hook: %s by %s | type %d | damage %.1f -> %.1f to engine (direct %d%%) | hp %d | armor %d",
                IsValid(sourceWep) and sourceWep:GetClass() or "world", IsValid(dmginfo:GetAttacker()) and tostring(dmginfo:GetAttacker()) or "world",
                dmginfo:GetDamageType(), damage, direct, KMS.Settings.directDamage, ctx.hp, ctx.armor)
            timer.Simple(0, function()
                if IsValid(ent) and ent.KMSHit == ctx then
                    ent.KMSHit = nil
                    Trace(ent, "result: cancelled after KMS pre-hook (a later hook or the engine refused it) | no medical consequences")
                end
            end)
        end
    elseif ent.KMSSim ~= nil and ent.KMSState then
        if dmginfo:GetDamage() <= 0 then return true end
        local pos = dmginfo:GetDamagePosition()
        local partId = (isvector(pos) and not pos:IsZero()) and PartFromRagdoll(ent, pos) or "torso"
        local rawScaled = dmginfo:GetDamage() * KMS.Coef("damageScale")
        ApplyDamageWounds(ent, partId, dmginfo, rawScaled * DOMAIN_SCALE, rawScaled)
        ent.KMSState.dirty = true
        return true
    elseif ent.KMSOwner ~= nil then
        local owner = ent.KMSOwner
        if dmginfo:IsDamageType(DMG_CRUSH) then
            local attacker = dmginfo:GetAttacker()
            if not (IsValid(attacker) and attacker:IsPlayer()) then return true end
        end
        if IsValid(owner) and owner.KMSState then
            local copy = DamageInfo()
            copy:SetDamage(dmginfo:GetDamage())
            copy:SetDamageType(dmginfo:GetDamageType())
            copy:SetDamagePosition(dmginfo:GetDamagePosition())
            copy:SetAttacker(dmginfo:GetAttacker())
            copy:SetInflictor(IsValid(dmginfo:GetInflictor()) and dmginfo:GetInflictor() or ent)
            local pos = dmginfo:GetDamagePosition()
            owner.KMSForcePart = (isvector(pos) and not pos:IsZero()) and PartFromRagdoll(ent, pos) or "torso"
            owner.KMSForwarding = true
            owner:TakeDamageInfo(copy)
            owner.KMSForwarding = nil
            owner.KMSForcePart = nil
        end
        return true
    end
end

-- HOOK_LOW only exists where a priority-aware hook library (ULib) is installed; correctness does
-- not depend on it, it just lets the revive floor see the final damage more often.
hook.Add("EntityTakeDamage", "KMS_Damage", PreDamage, HOOK_LOW)

hook.Add("PostEntityTakeDamage", "KMS_Damage", function(ent, dmginfo, took)
    local ctx = ent.KMSHit
    if ctx then
        ent.KMSHit = nil
        if ctx.time ~= CurTime() then ctx = nil end
    end
    if not took then
        if ctx and ent.KMSTrace then Trace(ent, "result: blocked, the engine took nothing | no medical consequences") end
        return
    end
    if not KMS.Settings.enabled then return end
    local state = Patient(ent)
    if not state then return end
    local applied = dmginfo:GetDamage()
    if applied <= 0 then return end
    MedicalConsequences(ent, state, dmginfo, ctx, applied * (ctx and ctx.scale or 1), applied)
end)

local function CheckArrest(state, sys, dia)
    if state.arrest then return false end
    if state.blood / KMS.Settings.maxBlood < ARREST_BLOOD then return true end
    if state.hr < 20 or state.hr > 220 then return true end
    if sys < 50 and dia < 40 and state.hr < 40 then return true end
    if dia >= 190 then return true end
    return false
end

local HYPOXIA_HR_CAP = 60

local function TargetHR(state, frac)
    local target = BASE_HR
    local pp = KMS.PerceivedPain(state)
    if pp > 0.2 then target = math.max(target, BASE_HR + 50 * pp) end
    if frac < 0.7 then
        local sys, dia = KMS.ComputeBP(state)
        target = math.max(target, state.hr * ((107 * frac) / math.max(45, (2 * sys + dia) / 3)))
    end
    return math.Clamp(target + KMS.MedEffects(state).hr + math.min((KMS.NormalSpO2 - state.spo2) * 2, HYPOXIA_HR_CAP), 0, 250)
end

local ETA_STEP, ETA_HORIZON = 2, 3600

local function ArrestDrain(state)
    for _, partState in pairs(state.parts) do
        if KMS.PartHasBleedingWound(partState) then return 1 end
    end
    return KMS.Coef("arrestStableTimeScale")
end

local function BleedoutETA(state, threshold)
    local _, raw = BleedRate(state)
    if raw <= 0 then return nil end
    local target = KMS.Settings.maxBlood * threshold
    if state.blood <= target then return 0 end
    local blood, elapsed = state.blood, 0
    while blood > target and elapsed < ETA_HORIZON do
        blood = blood - BleedFlow(state, raw, blood) * ETA_STEP
        elapsed = elapsed + ETA_STEP
    end
    if blood > target then return nil end
    return elapsed
end

local function ArrestETA(state)
    local _, raw = BleedRate(state)
    local ivLeft = 0
    for _, bag in ipairs(state.ivBags or {}) do
        ivLeft = ivLeft + bag.left
    end
    if raw <= 0 then return nil end
    local sim = { blood = state.blood, hr = state.hr, pain = state.pain, spo2 = state.spo2 or KMS.NormalSpO2,
        meds = state.meds, parts = state.parts, bleedCoef = state.bleedCoef }
    local ivRate = KMS.IVDripRate * KMS.Coef("ivFlowRate") * ETA_STEP
    local maxBlood = KMS.Settings.maxBlood
    local elapsed = 0
    while elapsed < ETA_HORIZON do
        local drip = math.min(ivLeft, ivRate)
        ivLeft = ivLeft - drip
        sim.blood = math.Clamp(sim.blood - BleedFlow(sim, raw, sim.blood) * ETA_STEP + drip, 0, maxBlood)
        local frac = sim.blood / maxBlood
        sim.spo2 = math.Clamp(sim.spo2 + (KMS.OxygenUse + sim.hr * KMS.OxygenIntake) * ETA_STEP, 0, 100)
        local target = TargetHR(sim, frac)
        if frac <= ARREST_BLOOD then
            sim.hr = math.max(0, sim.hr - ETA_STEP * sim.hr / 10)
        else
            sim.hr = sim.hr + (target - sim.hr) / 2 * ETA_STEP
        end
        elapsed = elapsed + ETA_STEP
        local sys, dia = KMS.ComputeBP(sim)
        if CheckArrest(sim, sys, dia) then return elapsed end
    end
    return nil
end

function KMS.DeathETA(ply)
    local state = ply.KMSState
    if not state or KMS.MedFlag(state, "stasis") then return nil end
    if state.arrest then
        local drain = ArrestDrain(state) * (KMS.CPRProvider(ply) and 0.5 or 1)
        local eta = math.max(0, state.arrestLeft) / math.max(0.01, drain)
        if KMS.Settings.arrestBleedout then
            local bleed = BleedoutETA(state, BLEEDOUT_BLOOD)
            if bleed then eta = math.min(eta, bleed) end
        end
        return eta
    end
    local arrestIn = ArrestETA(state)
    if not arrestIn then return nil end
    return arrestIn + KMS.Settings.arrestTime / math.max(0.01, ArrestDrain(state))
end

local function TickReopen(ply, state, partId, partState, now)
    local reopened = false
    for _, wound in ipairs(partState.wounds) do
        if wound.b and wound.ro then
            for i = #wound.ro, 1, -1 do
                local wave = wound.ro[i]
                if now >= wave.at then
                    table.remove(wound.ro, i)
                    local units = math.min(wave.n, wound.n)
                    if units > 0 then
                        wound.n = wound.n - units
                        KMS.AddWound(ply, partId, wound.t, wound.s, units, wound.w)
                        reopened = true
                    end
                end
            end
            if not wound.ro[1] then wound.ro = nil end
        end
    end
    if not reopened then return end
    for i = #partState.wounds, 1, -1 do
        if partState.wounds[i].n <= 0 then table.remove(partState.wounds, i) end
    end
    KMS.Notify(ply, "warn", "msg_reopened", "#part_" .. partId)
end

local function EnforceDowned(ply, target)
    if ply:GetNoDraw() ~= true then ply:SetNoDraw(true) end
    if ply:GetMoveType() ~= MOVETYPE_NONE then ply:SetMoveType(MOVETYPE_NONE) end
    ply:SetNotSolid(true)
    ply:SetSaveValue("m_takedamage", 2)
    if ply:GetObserverMode() == OBS_MODE_NONE and IsValid(target) then
        ply:Spectate(OBS_MODE_CHASE)
        ply:SpectateEntity(target)
    end
end

local function TickPlayer(ply, state, dt)
    local now = CurTime()
    local maxBlood = KMS.Settings.maxBlood
    state.bleedCoef = ProfileCoef(ply, "bleed")

    local flow, rawFlow = BleedRate(state)
    state.blood = math.max(0, state.blood - flow * dt)
    if flow > 0 and KMS.Settings.bloodEffects then
        EmitBlood(ply, state, flow)
    end
    if state.ivBags then
        local rate = KMS.IVDripRate * KMS.Coef("ivFlowRate") * dt
        for i = #state.ivBags, 1, -1 do
            local bag = state.ivBags[i]
            if not state.parts[bag.part].tq then
                local drip = math.min(bag.left, rate)
                bag.left = bag.left - drip
                state.blood = math.min(maxBlood, state.blood + drip)
                if bag.left <= 0 then table.remove(state.ivBags, i) end
            end
        end
        if #state.ivBags == 0 then state.ivBags = nil end
    end
    local frac = state.blood / maxBlood

    state.spo2 = math.Clamp((state.spo2 or KMS.NormalSpO2) + (KMS.OxygenUse + state.hr * KMS.OxygenIntake) * dt, 0, 100)
    state.pain = math.max(0, state.pain - dt / 900)

    if (state.drownDmg or 0) > 0 and ply:WaterLevel() < 3 then
        state.drownDmg = state.drownDmg - dt * 10
        if state.drownDmg <= 0 then state.drownDmg = nil end
    end

    if state.loadedIn then
        if IsValid(state.loadedIn) then
            ply:SetPos(state.loadedIn:WorldSpaceCenter())
        else
            state.loadedIn = nil
            ply:SetNWEntity("kms_loaded_in", NULL)
            if not state.conscious and not IsValid(ply.KMSRagdoll) then
                local ragdoll = SpawnStateRagdoll(ply)
                if IsValid(ragdoll) then ply:SpectateEntity(ragdoll) end
            end
        end
    end

    if not state.conscious then
        if now >= (state.nextDownSync or 0) then
            state.nextDownSync = now + 2
            state.dirty = true
        end
        if ply:IsPlayer() then
            local ragdoll = ply.KMSRagdoll
            EnforceDowned(ply, IsValid(state.loadedIn) and state.loadedIn or ragdoll)
            if IsValid(ragdoll) then
                local bodyPos = ragdoll:GetPos()
                if ply:GetPos():DistToSqr(bodyPos) > 4096 then
                    ply:SetPos(bodyPos)
                end
            end
        end
    end

    local stasis = KMS.MedFlag(state, "stasis")
    if state.veraxAt and now >= state.veraxAt and not stasis then
        state.veraxAt = nil
        EnterArrest(ply, state)
    end

    if stasis then
        -- Cryogen stasis: heart rate, arrest timer and waking stay frozen until it wears off
    elseif state.arrest then
        local cprActive = KMS.CPRProvider(ply) ~= nil
        if cprActive then
            state.hr = 25 + (math.random() + math.random()) * 5
        else
            state.hr = 0
        end
        state.arrestLeft = state.arrestLeft - dt * (cprActive and 0.5 or 1) * ArrestDrain(state)
        if state.arrestLeft <= 0 or (KMS.Settings.arrestBleedout and frac <= BLEEDOUT_BLOOD) then
            KMS.KillPatient(ply, state.arrestLeft <= 0 and "cardiac arrest" or "blood loss")
            return
        end
    else
        local target = TargetHR(state, frac)
        if frac <= 0.6 then
            state.hr = math.max(0, state.hr - dt * state.hr / 10)
        else
            state.hr = state.hr + (target - state.hr) / 2 * dt
        end

        local sys, dia = KMS.ComputeBP(state)
        local goArrest = CheckArrest(state, sys, dia)
        if not goArrest and state.hr < 30 and now >= (state.nextLowHr or 0) then
            state.nextLowHr = now + 5
            if math.random() < 0.4 + 0.6 * (30 - state.hr) / 10 then
                goArrest = true
            elseif state.conscious then
                KMS.DownPlayer(ply)
            end
        end
        if goArrest then
            EnterArrest(ply, state)
        elseif state.conscious then
            if rawFlow > BODY_BLEED_CAP * 0.5 and not KMS.MedFlag(state, "shock") then
                KMS.DownPlayer(ply)
            end
        else
            local stable = StableVitals(state) and rawFlow < BODY_BLEED_CAP * 0.25
            if not stable then
                state.nextWake = math.max(state.nextWake, now + KMS.Settings.wakeInterval)
            elseif ply:IsPlayer() and now >= state.nextWake then
                local boost = KMS.LinearConversion(0, 1, KMS.MedRatio(state, "epinephrine"), 1, 1 / KMS.Settings.wakeEpiBoost)
                state.nextWake = now + KMS.Settings.wakeInterval * boost
                local forced = state.koUntil ~= nil and now >= state.koUntil
                if forced or math.random(100) <= KMS.Settings.wakeChance then
                    KMS.WakePlayer(ply)
                end
            end
        end
    end

    local oldestTq
    for _, part in ipairs(KMS.Parts) do
        local partState = state.parts[part.id]
        if partState.tq then
            oldestTq = math.min(oldestTq or partState.tqAt, partState.tqAt)
            if now >= (state.nextTqWarn or 0) and now - partState.tqAt > KMS.Settings.tourniquetWarnTime then
                state.nextTqWarn = now + 60
                KMS.Notify(ply, "warn", "msg_tq_warning", KF.FormatTime(KMS.Settings.tourniquetWarnTime))
            end
        end
        TickReopen(ply, state, part.id, partState, now)
    end
    if oldestTq and now - oldestTq > 120 then
        state.pain = math.max(state.pain, math.min(1, (now - oldestTq - 120) * 0.001 * KMS.Coef("painCoef")))
    end

    UpdateMobility(ply, state)

    -- Blood is KMS's own vital: its changes reach health as deltas, so health lost or gained through
    -- any other system is left where that system put it.
    local maxHp = ply:GetMaxHealth()
    if ply:IsPlayer() and maxHp > 0 then
        local delta = maxHp * (frac - (state.lastBloodFrac or frac)) + (state.hpCarry or 0)
        local whole = delta < 0 and math.ceil(delta) or math.floor(delta)
        state.lastBloodFrac, state.hpCarry = frac, delta - whole
        if whole ~= 0 then
            ply:SetHealth(math.Clamp(ply:Health() + whole, 1, maxHp))
        end
    end

    local sys = KMS.ComputeBP(state)
    local bands = table.concat({
        KMS.PainBand(KMS.PerceivedPain(state)),
        KMS.BloodClass(state.blood / maxBlood),
        KMS.BleedBand(flow, state),
        sys < 50 and 1 or 0,
        KMS.IsStable(ply) and 1 or 0,
        (state.hr > KMS.HRNormalHigh or (state.hr > 0 and state.hr < KMS.HRNormalLow)) and math.Round(state.hr / 10) or 0,
    }, "|")
    if bands ~= state.lastBands then
        state.lastBands = bands
        state.dirty = true
    end
end

local function StateActive(ply, state)
    if state.arrest or not state.conscious then return true end
    if state.ivBags ~= nil or (state.drownDmg or 0) > 0 then return true end
    if (state.spo2 or KMS.NormalSpO2) < KMS.NormalSpO2 then return true end
    if state.pain > 0.01 or state.blood < KMS.Settings.maxBlood then return true end
    if math.abs(state.hr - BASE_HR) > 1 then return true end
    for _, partState in pairs(state.parts) do
        if #partState.wounds > 0 or partState.frac or partState.tq then return true end
    end
    return false
end

local function SimWorkDone(state)
    if state.arrest then return false end
    for _, partState in pairs(state.parts) do
        if (partState.frac and not partState.splint) or partState.tq then return false end
        for _, wound in ipairs(partState.wounds) do
            if not wound.b then return false end
        end
    end
    return true
end

local function SpawnReset(ply)
    if IsValid(ply.KMSRagdoll) then ply.KMSRagdoll:Remove() end
    ply.KMSRagdoll = nil
    KMS.RestoreJump(ply)
    ply:SetNWEntity("kms_ragdoll", NULL)
    ply:SetNWEntity("kms_loaded_in", NULL)
    RestoreBody(ply)
    ply:SetNWFloat("kms_stagger", 0)
    KMS.ResetState(ply)
    timer.Simple(0, function()
        if IsValid(ply) then
            KMS.SyncAccess(ply)
            KMS.GiveLoadout(ply)
            KMS.SyncSelf(ply)
        end
    end)
end

hook.Add("PlayerSpawn", "KMS_Spawn", SpawnReset)

local lastTick = 0

timer.Create("KMS_Tick", 0.5, 0, function()
    local dt = math.min(CurTime() - lastTick, 10)
    lastTick = CurTime()
    if dt <= 0 then return end
    local enabled = KMS.Settings.enabled
    for _, ply in ipairs(player.GetAll()) do
        KMS.TickExam(ply)
        local exempt = KMS.SyncAccess(ply)
        if exempt ~= (ply.KMSExempt == true) then
            ply.KMSExempt = exempt
            if exempt then KMS.Detach(ply) end
        end
        local state = ply.KMSState
        if state and state.triage == 4 and ply:Alive() then
            SpawnReset(ply)
            state = ply.KMSState
        end
        if enabled and state and ply:Alive() and not exempt and not ply:HasGodMode() then
            KMS.TickStamina(ply, dt)
            if StateActive(ply, state) then
                TickPlayer(ply, state, dt)
            elseif ply.KMSJumpPower or ply:GetNWInt("kms_mobility", 0) ~= 0 or ply:GetNWBool("kms_noarms", false) then
                UpdateMobility(ply, state)
            end
        elseif ply.KMSStam then
            KMS.ResetStamina(ply)
        end
    end
    for ragdoll in pairs(KMS.SimPatients) do
        local sim = IsValid(ragdoll) and ragdoll.KMSSim or nil
        if not sim or not ragdoll.KMSState then
            KMS.SimPatients[ragdoll] = nil
        elseif not enabled then
            KMS.FinishSim(ragdoll, "aborted")
        elseif SimWorkDone(ragdoll.KMSState) then
            KMS.FinishSim(ragdoll, "passed")
        elseif sim.deadline and CurTime() >= sim.deadline then
            KMS.FinishSim(ragdoll, "time")
        else
            TickPlayer(ragdoll, ragdoll.KMSState, dt)
        end
    end
end)

timer.Create("KMS_SyncTick", 0.5, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local state = ply.KMSState
        if state and state.dirty then
            state.dirty = nil
            KMS.SyncSelf(ply)
            KMS.SyncPatient(ply)
        end
    end
    for ragdoll in pairs(KMS.SimPatients) do
        local state = IsValid(ragdoll) and ragdoll.KMSState or nil
        if state and state.dirty then
            state.dirty = nil
            KMS.SyncPatient(ragdoll)
        end
    end
end)

local function DropInventory(ply)
    if not KMS.PersistentInv() or KMS.Settings.invDeath == "keep" or KMS.Exempt(ply) then return end
    local inv = ply.KMSInv
    if not inv or not next(inv) then return end
    if KMS.Settings.invDeath == "drop" then
        local cache = ents.Create("kms_cache")
        if IsValid(cache) then
            cache:SetPos(ply:GetPos() + Vector(0, 0, 8))
            cache:Spawn()
            cache.KMSCache = table.Copy(inv)
            SafeRemoveEntityDelayed(cache, KMS.Settings.invDropExpiry)
        end
    end
    table.Empty(inv)
    KMS.PersistInv(ply)
end

local function DeathCleanup(ply)
    DropInventory(ply)
    if IsValid(ply.KMSRagdoll) then ply.KMSRagdoll:Remove() end
    ply.KMSRagdoll = nil
    ply.KMSJumpPower = nil
    ply:SetNWEntity("kms_ragdoll", NULL)
    ply:SetNWEntity("kms_loaded_in", NULL)
    RestoreBody(ply)
    local state = ply.KMSState
    if state then
        state.loadedIn = nil
        state.triage = 4
        ply:SetNWInt("kms_triage", 4)
    end
end

hook.Add("PlayerDeath", "KMS_Death", DeathCleanup)
hook.Add("PlayerSilentDeath", "KMS_Death", DeathCleanup)

hook.Add("PlayerDisconnected", "KMS_Disconnect", function(ply)
    KMS.StopDrag(ply)
    if IsValid(ply.KMSRagdoll) then ply.KMSRagdoll:Remove() end
    if IsValid(ply.KMSMedbay) then ply.KMSMedbay:Remove() end
    timer.Remove("KMS_Job_" .. ply:EntIndex())
    for _, other in ipairs(player.GetAll()) do
        if other.KMSWatchers then other.KMSWatchers[ply] = nil end
    end
    for ragdoll in pairs(KMS.SimPatients) do
        local sim = IsValid(ragdoll) and ragdoll.KMSSim or nil
        if sim and sim.trainee == ply then
            KMS.FinishSim(ragdoll, "aborted")
        end
    end
end)

hook.Add("CanPlayerSuicide", "KMS_Suicide", function(ply)
    if not KMS.Settings.enabled then return end
    local state = ply.KMSState
    if state and not state.conscious then return false end
end)

hook.Add("EntityRemoved", "KMS_RagdollRemoved", function(ent)
    local owner = ent.KMSOwner
    if not IsValid(owner) or owner.KMSRagdoll ~= ent then return end
    owner.KMSRagdoll = nil
    owner:SetNWEntity("kms_ragdoll", NULL)
    local halting = KMS.Halting == true
    timer.Simple(0, function()
        if not IsValid(owner) or not owner:Alive() or IsValid(owner.KMSRagdoll) then return end
        local state = owner.KMSState
        if not state or state.conscious or state.loadedIn then return end
        if state.arrest or halting then
            local ragdoll = SpawnStateRagdoll(owner)
            if IsValid(ragdoll) then owner:SpectateEntity(ragdoll) end
        else
            KMS.WakePlayer(owner)
        end
    end)
end)

local function ProtectedEnt(ent)
    return ent.KMSOwner ~= nil or ent.KMSSim ~= nil or ent.KMSCache ~= nil or ent.KMSMedbayOwner ~= nil
end

hook.Add("PhysgunPickup", "KMS_ProtectRagdoll", function(_, ent)
    if ProtectedEnt(ent) then return false end
end)

hook.Add("GravGunPickupAllowed", "KMS_ProtectRagdoll", function(_, ent)
    if ProtectedEnt(ent) then return false end
end)

hook.Add("CanTool", "KMS_ProtectRagdoll", function(_, trace)
    local ent = trace.Entity
    if IsValid(ent) and ProtectedEnt(ent) then return false end
end)

local function Say(ply, text)
    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, text) else print(text) end
end

local function FindTarget(ply, name)
    if isstring(name) then
        name = string.lower(name)
        local partial
        for _, other in ipairs(player.GetAll()) do
            local nick = string.lower(other:Nick())
            if nick == name then return other end
            if not partial and string.find(nick, name, 1, true) then partial = other end
        end
        return partial
    end
    if not IsValid(ply) then return nil end
    local ent = ply:GetEyeTrace().Entity
    if IsValid(ent) then
        if ent:IsPlayer() then return ent end
        if IsValid(ent.KMSOwner) then return ent.KMSOwner end
    end
    return ply
end

local USAGE = [[kms_debug — herramienta de pruebas del sistema medico
  wound <parte> <tipo> [tamano 1-3] [cantidad]   parte: head/torso/arm_l/arm_r/leg_l/leg_r
  frac <parte>          fractura una extremidad       tq <parte>    aplica torniquete
  blood <ml>            fija el volumen de sangre     pain <0-1>    fija el dolor
  arrest                fuerza paro cardiaco          ko            fuerza inconsciencia
  wake                  fuerza despertar
  tier [0-2]            fija el tier ganado por examen y borra sus enfriamientos
  heal                  curacion total                state         vuelca el estado a consola
  trace                 alterna la traza de daño por golpe (consola del que la activa)
  stam [0-1]            fija las reservas de estamina (sin valor: vuelca estamina)
  pose <carry|drag> [save]  save: captura la pose desde un ragdoll poseado con physgun sobre el objetivo; sin save: vuelca la tabla
  Anade @nombre al final para elegir jugador (si no: al que miras, o tu).]]

local ACTIONS = {}

ACTIONS.wound = function(target, args)
    local part = args[1]
    local woundType = args[2]
    if not KMS.PartById[part or ""] then return "parte invalida (head/torso/arm_l/arm_r/leg_l/leg_r)" end
    if not KMS.Wounds[woundType or ""] then return "tipo invalido (abrasion/avulsion/burn/contusion/crush/cut/laceration/puncture/velocity)" end
    local size = math.Clamp(math.floor(tonumber(args[3]) or 2), 1, 3)
    local count = math.max(1, math.floor(tonumber(args[4]) or 1))
    KMS.AddWound(target, part, woundType, size, count)
    local state = target.KMSState
    local pain = KMS.CategorySize[size] * KMS.Wounds[woundType].pain * count * KMS.Coef("painCoef")
    state.pain = math.Clamp(math.max(state.pain, pain), 0, 1)
end

ACTIONS.frac = function(target, args)
    local part = KMS.PartById[args[1] or ""]
    if not part or not part.limb then return "parte invalida (arm_l/arm_r/leg_l/leg_r)" end
    local partState = target.KMSState.parts[part.id]
    partState.frac = true
    partState.splint = false
end

ACTIONS.tq = function(target, args)
    local part = KMS.PartById[args[1] or ""]
    if not part or not part.limb then return "parte invalida (arm_l/arm_r/leg_l/leg_r)" end
    local partState = target.KMSState.parts[part.id]
    partState.tq = true
    partState.tqAt = CurTime()
end

ACTIONS.blood = function(target, args)
    local ml = tonumber(args[1])
    if not ml then return "uso: kms_debug blood <ml>" end
    target.KMSState.blood = math.Clamp(ml, 0, KMS.Settings.maxBlood)
end

ACTIONS.pain = function(target, args)
    local pain = tonumber(args[1])
    if not pain then return "uso: kms_debug pain <0-1>" end
    target.KMSState.pain = math.Clamp(pain, 0, 1)
end

ACTIONS.pose = function(target, args, ply)
    local mode = HAUL_MODES[args[1] or ""]
    if not mode then return "uso: kms_debug pose <carry|drag> [save]" end
    if args[2] ~= "save" then
        for _, def in ipairs(mode.grips) do
            Say(ply, string.format("{ match = %q, pos = Vector(%.1f, %.1f, %.1f), ang = Angle(%.1f, %.1f, %.1f) },",
                def.match, def.pos.x, def.pos.y, def.pos.z, def.ang.p, def.ang.y, def.ang.r))
        end
        return
    end
    local ragdoll = IsValid(ply) and ply:GetEyeTrace().Entity
    if not IsValid(ragdoll) or ragdoll:GetClass() ~= "prop_ragdoll" then
        ragdoll = nil
        local bestDist
        for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
            local dist = ent:GetPos():DistToSqr(target:GetPos())
            if dist <= 62500 and (not bestDist or dist < bestDist) then
                ragdoll, bestDist = ent, dist
            end
        end
    end
    if not IsValid(ragdoll) then return "posa un ragdoll con la physgun sobre el portador de referencia (miralo o dejalo a menos de 250 uds)" end
    local base = target:GetPos()
    local yaw = Angle(0, target:EyeAngles().yaw, 0)
    local heightScale = math.max(0.1, target:OBBMaxs().z / 72)
    local used, captured = {}, 0
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local bone = ragdoll:TranslatePhysBoneToBone(i)
        local name = bone >= 0 and (ragdoll:GetBoneName(bone) or "") or ""
        for _, def in ipairs(mode.grips) do
            if not used[def] and string.find(name, def.match, 1, true) then
                used[def] = true
                local phys = ragdoll:GetPhysicsObjectNum(i)
                if IsValid(phys) then
                    local pos, ang = WorldToLocal(phys:GetPos(), phys:GetAngles(), base, yaw)
                    def.pos = Vector(pos.x, pos.y, pos.z / heightScale)
                    def.ang = ang
                    captured = captured + 1
                end
                break
            end
        end
    end
    Say(ply, string.format("pose %s: %d huesos capturados relativos a %s y aplicados en vivo; 'kms_debug pose %s' vuelca la tabla para pegarla en HAUL_MODES", args[1], captured, target:Nick(), args[1]))
end

ACTIONS.arrest = function(target)
    KMS.EnterArrest(target, target.KMSState)
end

ACTIONS.ko = function(target)
    KMS.DownPlayer(target)
end

ACTIONS.wake = function(target)
    KMS.WakePlayer(target)
end

ACTIONS.heal = function(target)
    KMS.FullHeal(target)
end

ACTIONS.tier = function(target, args)
    local record = KMS.PlayerRecord(target)
    if not args[1] then return "tier ganado por examen: " .. record.tier end
    record.tier = math.Clamp(math.floor(tonumber(args[1]) or 0), 0, 2)
    record.exams = {}
    KMS.SavePlayer(target)
    KMS.ClearAccessCache(target)
    KMS.SyncSelf(target)
    KMS.MarkDirty(target)
end

ACTIONS.stam = function(target, args, ply)
    local s = KMS.StaminaState(target)
    if not s then return "estamina desactivada" end
    local value = tonumber(args[1])
    if value then
        value = math.Clamp(value, 0, 1)
        s.an = 2300 * value
        s.ae2 = 84000 * value
        s.anFat = (1 - value) * 0.6
        s.resp = 1 - value
        return
    end
    Say(ply, string.format("== estamina %s ==", target:Nick()))
    Say(ply, string.format("an %.0f%% | ae2 %.0f%% | ae1 %.0f%% | acidosis %.2f | musculo %.3f | resp %.2f | fatiga %.2f",
        s.an / 2300 * 100, s.ae2 / 84000 * 100, s.ae1 / 4000000 * 100, s.anFat, s.dmg, s.resp, s.fatigue or 0))
    Say(ply, string.format("tier %d | handling %.2f | exhaust %.2f",
        target:GetNWInt("kms_stam_tier", 0), target:GetNWFloat("kms_handling", 1), target:GetNWFloat("kms_exhaust", 0)))
end

ACTIONS.trace = function(target, _, ply)
    if target.KMSTrace then
        target.KMSTrace = nil
        return
    end
    target.KMSTrace = IsValid(ply) and ply or true
end

ACTIONS.state = function(target, _, ply)
    local state = target.KMSState
    local sys, dia = KMS.ComputeBP(state)
    Say(ply, string.format("== %s ==", target:Nick()))
    Say(ply, string.format("sangre %.0f/%d mL | HR %.0f | BP %d/%d | dolor %.2f (percibido %.2f) | ahogo %.0f",
        state.blood, KMS.Settings.maxBlood, state.hr, sys, dia, state.pain, KMS.PerceivedPain(state), state.drownDmg or 0))
    Say(ply, string.format("consciente %s | paro %s (%.0fs) | estable %s | triage %d | HP %d | armadura %d | cargado en %s",
        tostring(state.conscious), tostring(state.arrest), state.arrest and state.arrestLeft or 0,
        tostring(KMS.IsStable(target)), state.triage, target:Health(), target:Armor(), tostring(state.loadedIn)))
    for _, part in ipairs(KMS.Parts) do
        local partState = state.parts[part.id]
        local bits = {}
        for _, wound in ipairs(partState.wounds) do
            bits[#bits + 1] = string.format("%.1fx %s s%d%s", wound.n, wound.t, wound.s, wound.b and (" [" .. wound.b .. "]") or "")
        end
        if partState.frac then bits[#bits + 1] = partState.splint and "ferula" or "FRACTURA" end
        if partState.tq then bits[#bits + 1] = "torniquete" end
        if (partState.dmg or 0) > 0 then bits[#bits + 1] = string.format("trauma %.2f", partState.dmg) end
        if #bits > 0 then
            Say(ply, string.format("  %s: %s", part.id, table.concat(bits, ", ")))
        end
    end
    for medId in pairs(state.meds) do
        Say(ply, string.format("  med: %s x%d", medId, KMS.ActiveMeds(state, medId)))
    end
end

concommand.Add("kms_debug", function(ply, _, args)
    if not KMS.CanDebug(ply) then return end
    local actionName = string.lower(args[1] or "")
    local action = ACTIONS[actionName]
    if not action then
        Say(ply, USAGE)
        return
    end
    table.remove(args, 1)
    local name
    if #args > 0 and string.sub(args[#args], 1, 1) == "@" then
        name = string.sub(table.remove(args), 2)
    end
    local target = FindTarget(ply, name)
    if not IsValid(target) or not target.KMSState then
        Say(ply, "kms_debug: objetivo no encontrado")
        return
    end
    local err = action(target, args, ply)
    if err then
        Say(ply, "kms_debug: " .. err)
        return
    end
    KMS.MarkDirty(target)
    if actionName ~= "state" then
        Say(ply, string.format("kms_debug: %s -> %s", actionName, target:Nick()))
    end
end)

function KMS.AdminHeal(actor, name, revive)
    if not IsValid(actor) or not KMS.CanHeal(actor) then return end
    local target = FindTarget(actor, isstring(name) and name ~= "" and name or nil)
    if not IsValid(target) then
        KMS.Notify(actor, "error", "err_target_not_found")
        return
    end
    if not target:Alive() then
        if not revive then
            KMS.Notify(actor, "error", "err_target_dead")
            return
        end
        target:Spawn()
    end
    if target.KMSState then KMS.FullHeal(target) end
    KMS.Notify(target, "success", revive and "msg_admin_revived" or "msg_admin_healed")
    if target ~= actor then
        KMS.Notify(actor, "success", revive and "msg_admin_revived_other" or "msg_admin_healed_other", target:Nick())
    end
end

function KMS.TierLoadout(ply)
    local loadout = {}
    for itemId, amount in pairs(KMS.LoadoutFor(KMS.MedicTier(ply))) do
        loadout[itemId] = (KMS.ItemById[itemId] and not KMS.ItemDisabled[itemId]) and amount or 0
    end
    return loadout
end

function KMS.GiveLoadout(ply)
    ply.KMSInv = KMS.PersistentInv() and KMS.LoadInventory(ply) or KMS.TierLoadout(ply)
    KMS.MarkDirty(ply)
end

function KMS.HasItem(ply, itemId)
    if KMS.Settings.infiniteSupplies then return true end
    return (ply.KMSInv and ply.KMSInv[itemId] or 0) > 0
end

function KMS.TakeItem(ply, itemId)
    if KMS.Settings.infiniteSupplies then return end
    if ply.KMSInv and (ply.KMSInv[itemId] or 0) > 0 then
        ply.KMSInv[itemId] = ply.KMSInv[itemId] - 1
        KMS.MarkDirty(ply)
        KMS.PersistInv(ply)
    end
end

function KMS.GiveItem(ply, itemId)
    if KMS.Settings.infiniteSupplies then return end
    ply.KMSInv = ply.KMSInv or {}
    ply.KMSInv[itemId] = (ply.KMSInv[itemId] or 0) + 1
    KMS.MarkDirty(ply)
    KMS.PersistInv(ply)
end

function KMS.RestockPlayer(ply, supplies)
    local now = CurTime()
    if (ply.KMSNextRestock or 0) > now then
        KMS.Notify(ply, "warn", "msg_restock_cooldown", KF.FormatTime(math.ceil(ply.KMSNextRestock - now)))
        return
    end
    ply.KMSNextRestock = now + KMS.Settings.crateCooldown
    ply.KMSInv = ply.KMSInv or {}
    for itemId, amount in pairs(supplies or KMS.LoadoutFor(KMS.MedicTier(ply))) do
        if KMS.ItemById[itemId] and not KMS.ItemDisabled[itemId] then
            ply.KMSInv[itemId] = math.max(ply.KMSInv[itemId] or 0, amount)
        end
    end
    KMS.MarkDirty(ply)
    KMS.PersistInv(ply)
    KMS.Notify(ply, "success", "msg_restocked")
end

function KMS.NearCrate(ply)
    local origin = KMS.BodyEnt(ply):GetPos()
    for _, ent in ipairs(ents.FindByClass("kms_npc")) do
        local npc = KMS.NPCs[ent:GetNWString("kms_npc_id", "")]
        if npc and KMS.FacilityTypes[npc.npcType] and ent:GetPos():DistToSqr(origin) <= KMS.FacilityRangeSqr then
            return true
        end
    end
    for _, ent in ipairs(ents.FindByClass("kms_medbay")) do
        if ent:GetPos():DistToSqr(origin) <= KMS.FacilityRangeSqr then return true end
    end
    return KMS.NearMedVehicle(ply)
end

local function MedbaySpot(ply)
    local dir = Angle(0, ply:EyeAngles().yaw, 0):Forward()
    local target = ply:GetPos() + dir * 70
    local ground = util.TraceLine({ start = target + Vector(0, 0, 40), endpos = target - Vector(0, 0, 128), mask = MASK_PLAYERSOLID, filter = ply })
    if not ground.Hit or ground.HitNormal.z < 0.7 then return nil end
    local pos = ground.HitPos + Vector(0, 0, 2)
    local hull = util.TraceHull({
        start = pos + Vector(0, 0, 4),
        endpos = pos + Vector(0, 0, 4),
        mins = Vector(-24, -24, 0),
        maxs = Vector(24, 24, 40),
        mask = MASK_PLAYERSOLID,
        filter = ply,
    })
    if hull.Hit then return nil end
    return pos
end

local function PlaceMedbay(ply)
    local pos = MedbaySpot(ply)
    if not pos then
        KMS.Notify(ply, "error", "err_medbay_space")
        return
    end
    if IsValid(ply.KMSMedbay) then ply.KMSMedbay:Remove() end
    local ent = ents.Create("kms_medbay")
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(Angle(0, ply:EyeAngles().yaw + 180, 0))
    ent:Spawn()
    ent.KMSMedbayOwner = ply
    ent:SetNWString("kms_medbay_owner", KF.Integrations.GetPlayerName(ply) or ply:Nick())
    ply.KMSMedbay = ent
    KMS.Notify(ply, "success", "msg_medbay_deployed")
end

KF.Net.Receive("KMS_MedbayDeploy", function(_, ply)
    if not KMS.Settings.enabled or not KMS.Settings.medbayEnabled then return end
    if not ply:Alive() or not (ply.KMSState and ply.KMSState.conscious) or KMS.Exempt(ply) then return end
    if KMS.MedicTier(ply) < 1 then return end
    if ply.KMSJob then
        KMS.Notify(ply, "error", "err_busy")
        return
    end
    if not MedbaySpot(ply) then
        KMS.Notify(ply, "error", "err_medbay_space")
        return
    end
    local duration = KMS.Settings.medbayDeployTime
    if duration <= 0 then
        PlaceMedbay(ply)
        return
    end
    KMS.StartChannel(ply, "medbay_deploy", duration, {
        patient = ply,
        complete = PlaceMedbay,
    })
end, { rateLimit = 1 })

function KMS.PackMedbay(ply, ent)
    if not KMS.Settings.enabled then return end
    if ply ~= ent.KMSMedbayOwner and not KMS.IsAdmin(ply) then return end
    if ply.KMSJob then
        KMS.Notify(ply, "error", "err_busy")
        return
    end
    local function finish(actor)
        if not IsValid(ent) then return end
        KMS.Notify(actor, "info", "msg_medbay_removed")
        ent:Remove()
    end
    local duration = KMS.Settings.medbayDeployTime
    if duration <= 0 then
        finish(ply)
        return
    end
    KMS.StartChannel(ply, "medbay_pack", duration, {
        patient = ply,
        complete = finish,
    })
end

function KMS.EffectiveTier(ply)
    return KMS.BoostTier(KMS.MedicTier(ply), KMS.NearCrate(ply))
end

local function WorstOpenWound(partState)
    local worst, worstScore
    for _, wound in ipairs(partState.wounds) do
        if not wound.b then
            local score = KMS.WoundScore(wound)
            if not worstScore or score > worstScore then
                worst, worstScore = wound, score
            end
        end
    end
    return worst
end

local function FindTargetWounds(partState, bandageId, remaining)
    local stats = KMS.BandageStats[bandageId]
    remaining = remaining or KMS.Coef("bandageEffectiveness")
    local targets, taken = {}, {}
    repeat
        local best, bestScore, bestEff
        for _, wound in ipairs(partState.wounds) do
            if not wound.b and not taken[wound] then
                local eff = stats[wound.t].eff[wound.s] * remaining
                local score = eff * KMS.WoundFlow(wound)
                if score > (bestScore or 0) then
                    best, bestScore, bestEff = wound, score, eff
                end
            end
        end
        if not best then break end
        taken[best] = true
        targets[#targets + 1] = { wound = best, eff = bestEff, impact = math.min(best.n, bestEff) }
        remaining = remaining - targets[#targets].impact / bestEff
    until not KMS.Settings.bandageRollover or remaining <= 0
    if not targets[1] then
        local wound = WorstOpenWound(partState)
        if wound then
            local eff = stats[wound.t].eff[wound.s] * remaining
            targets[1] = { wound = wound, eff = eff, impact = math.min(wound.n, eff) }
        end
    end
    return targets
end

local function AddStitched(partState, woundType, size, count)
    if count <= 0 then return end
    partState.st = partState.st or {}
    for _, wound in ipairs(partState.st) do
        if wound.t == woundType and wound.s == size then
            wound.n = wound.n + count
            return
        end
    end
    partState.st[#partState.st + 1] = { t = woundType, s = size, n = count }
end

local function ApplyBandage(actor, patient, def, partId)
    local partState = patient.KMSState.parts[partId]
    local targets = FindTargetWounds(partState, def.id, KMS.Coef("bandageEffectiveness") * ProfileCoef(patient, "healing"))
    if not targets[1] then return false, "err_no_wound" end
    for _, target in ipairs(targets) do
        local wound = target.wound
        local stats = KMS.BandageStats[def.id][wound.t]
        wound.n = wound.n - target.impact
        local bandaged
        for _, other in ipairs(partState.wounds) do
            if other.b == def.id and other.t == wound.t and other.s == wound.s then
                bandaged = other
                break
            end
        end
        if bandaged then
            bandaged.n = bandaged.n + target.impact
        else
            bandaged = { t = wound.t, s = wound.s, n = target.impact, w = wound.w, d = wound.d, b = def.id }
            partState.wounds[#partState.wounds + 1] = bandaged
        end
        if KMS.Settings.reopenEnabled and stats.reopen[wound.s] > 0
            and math.random() < stats.reopen[wound.s] * KMS.Coef("woundReopenChance") then
            bandaged.ro = bandaged.ro or {}
            bandaged.ro[#bandaged.ro + 1] = { at = CurTime() + math.Rand(stats.delay[1], stats.delay[2]), n = target.impact }
        end
    end
    for i = #partState.wounds, 1, -1 do
        local wound = partState.wounds[i]
        if not wound.b and wound.n <= KMS.WoundEpsilon then
            table.remove(partState.wounds, i)
        end
    end
    return true
end

local function RollHrAdj(state, def)
    local band = math.Clamp(math.floor(math.Clamp(state.hr, 0, 110) / 55) + 1, 1, 3)
    local range = def.hr[band]
    return math.Rand(math.min(range[1], range[2]), math.max(range[1], range[2]))
end

local function CheckOverdose(patient, state, id)
    if KMS.ActiveMeds(state, id) > KMS.Meds[id].maxDose + math.random(0, 2) then
        KMS.DownPlayer(patient)
    end
end

-- One-shot effects of the Star Wars medications, applied once a dose reaches the bloodstream.
local function MedSpecial(patient, state, id)
    local def = KMS.Meds[id]
    if not def or patient.KMSSim ~= nil then return end
    local now = CurTime()
    if def.wake then
        for medId in pairs(state.meds) do
            local other = KMS.Meds[medId]
            if other and (other.sedate or other.stasis) then state.meds[medId] = nil end
        end
        state.medFx = nil
        state.koUntil = nil
        if not state.conscious and not state.arrest then
            if StableVitals(state) then
                KMS.WakePlayer(patient)
            else
                state.nextWake = now
            end
        end
    end
    local hold = def.sedate or (def.stasis and def.duration)
    if hold then
        KMS.DownPlayer(patient)
        if not state.conscious then
            state.koUntil = math.max(state.koUntil or 0, now + hold)
            state.nextWake = math.max(state.nextWake or 0, state.koUntil)
        end
    end
    if def.purge then
        for _, medId in ipairs(def.purge) do
            if KMS.Meds[medId] and KMS.Meds[medId].verax then state.veraxAt = nil end
            state.meds[medId] = nil
        end
        state.medFx = nil
    end
    if def.verax then
        state.pain = 1
        state.veraxAt = now + def.verax
    end
    if def.arrest then
        KMS.EnterArrest(patient, state)
    end
    state.dirty = true
end

local function GiveMed(patient, id, partId)
    local state = patient.KMSState
    local def = KMS.Meds[id]
    local partState = partId and state.parts[partId]
    local occluded = (partState and partState.tq) and partId or nil
    state.meds[id] = state.meds[id] or {}
    table.insert(state.meds[id], {
        at = CurTime(),
        untilT = CurTime() + (def.timeKey and KMS.Settings[def.timeKey] or def.duration),
        hrAdj = RollHrAdj(state, def),
        occluded = occluded,
    })
    state.medFx = nil
    CheckOverdose(patient, state, id)
    if not occluded then MedSpecial(patient, state, id) end
end

local TreatmentEffects = {
    tourniquet = function(actor, patient, def, partId)
        local partState = patient.KMSState.parts[partId]
        partState.tq = true
        partState.tqAt = CurTime()
        return true
    end,
    remove_tourniquet = function(actor, patient, def, partId)
        local state = patient.KMSState
        local partState = state.parts[partId]
        partState.tq = false
        partState.tqAt = 0
        for medId, doses in pairs(state.meds) do
            local released = false
            for _, dose in ipairs(doses) do
                if dose.occluded == partId then
                    local duration = dose.untilT - dose.at
                    dose.at = CurTime()
                    dose.untilT = dose.at + duration
                    dose.hrAdj = RollHrAdj(state, KMS.Meds[medId])
                    dose.occluded = nil
                    released = true
                end
            end
            if released then
                CheckOverdose(patient, state, medId)
                MedSpecial(patient, state, medId)
            end
        end
        state.medFx = nil
        return true
    end,
    splint = function(actor, patient, def, partId)
        local partState = patient.KMSState.parts[partId]
        partState.splint = true
        if KMS.Settings.fractureMode == "splint_heal" then
            partState.frac = false
            partState.splint = false
        end
        return true
    end,
    painkillers = function(actor, patient, def, partId)
        GiveMed(patient, "painkillers", partId)
        return true
    end,
    morphine = function(actor, patient, def, partId)
        patient.KMSState.lastMorphine = CurTime()
        GiveMed(patient, "morphine", partId)
        return true
    end,
    epinephrine = function(actor, patient, def, partId)
        GiveMed(patient, "epinephrine", partId)
        return true
    end,
    adenosine = function(actor, patient, def, partId)
        GiveMed(patient, "adenosine", partId)
        return true
    end,
    iv_saline = function(actor, patient, def, partId)
        local state = patient.KMSState
        state.ivBags = state.ivBags or {}
        state.ivBags[#state.ivBags + 1] = { left = def.ivMl or (KMS.Settings.ivVolume * (def.ivScale or 1)), part = partId, kind = string.match(def.item, "^iv_(%a+)") or "saline" }
        return true
    end,
    cpr = function(actor, patient)
        local state = patient.KMSState
        if state.cprBy == actor then state.cprBy = nil end
        if not state.arrest then
            if KMS.Settings.diagnosisMode == "examine" then
                KMS.AddLog(patient, "log_cpr", actor:Nick())
                return true, nil, true
            end
            return false, "err_not_arrest"
        end
        local chance = KMS.LinearConversion(KMS.Settings.maxBlood * 0.6, KMS.Settings.maxBlood * 0.85,
            state.blood, KMS.Settings.cprChanceMin, KMS.Settings.cprChance)
        if math.random(100) <= chance then
            state.arrest = false
            state.hr = 40
            state.nextWake = CurTime() + 5
            patient:SetNWBool("kms_arrest", false)
        end
        KMS.AddLog(patient, "log_cpr", actor:Nick())
        return true, nil, true
    end,
    surgical = function(actor, patient, def, partId, job)
        local partState = patient.KMSState.parts[partId]
        local removed = false
        for i = #partState.wounds, 1, -1 do
            local wound = partState.wounds[i]
            if wound.b then
                AddStitched(partState, wound.t, wound.s, wound.n)
                partState.dmg = math.max(0, (partState.dmg or 0) - (wound.d or 0) * KMS.WoundEvents(wound))
                table.remove(partState.wounds, i)
                removed = true
            end
        end
        if not removed and not (job and job.stitched) then return false, "err_no_wound" end
        KMS.AddLog(patient, "log_surgical", actor:Nick(), "#part_" .. partId)
        return true, nil, true
    end,
    pak = function(actor, patient)
        KMS.FullHeal(patient)
        KMS.AddLog(patient, "log_pak", actor:Nick())
        return true, nil, true
    end,
    check_pulse = function(actor, patient, def, partId)
        local state = patient.KMSState
        if state.parts[partId] and state.parts[partId].tq then
            KMS.AddQuick(patient, "qv_masked", actor:Nick())
        elseif KMS.WhitelistTier(actor) < 1 then
            local word = state.hr <= 0 and "#pulse_none"
                or state.hr <= 45 and "#pulse_weak"
                or state.hr < 120 and "#pulse_normal"
                or "#pulse_fast"
            KMS.AddQuick(patient, "qv_pulse", actor:Nick(), word)
        else
            KMS.AddQuick(patient, "qv_pulse", actor:Nick(), math.Round(state.hr))
        end
        return true, nil, true
    end,
    check_bp = function(actor, patient, def, partId)
        local state = patient.KMSState
        if state.parts[partId] and state.parts[partId].tq then
            KMS.AddQuick(patient, "qv_masked", actor:Nick())
        elseif KMS.WhitelistTier(actor) < 1 then
            local sys = KMS.ComputeBP(state)
            local word = sys <= 20 and "#bp_none"
                or sys < 100 and "#bp_low"
                or sys <= 160 and "#bp_normal"
                or "#bp_high"
            KMS.AddQuick(patient, "qv_bp_q", actor:Nick(), word)
        else
            local sys, dia = KMS.ComputeBP(state)
            KMS.AddQuick(patient, "qv_bp", actor:Nick(), sys, dia)
        end
        return true, nil, true
    end,
    check_response = function(actor, patient)
        local state = patient.KMSState
        local key = state.conscious and "qv_response_yes" or (state.arrest and "qv_response_arrest" or "qv_response_no")
        KMS.AddQuick(patient, key, actor:Nick())
        return true, nil, true
    end,
}

for _, ivId in ipairs({ "iv_saline_500", "iv_saline_1500", "iv_plasma", "iv_plasma_500", "iv_plasma_250", "iv_blood", "iv_blood_500", "iv_blood_250" }) do
    TreatmentEffects[ivId] = TreatmentEffects.iv_saline
end

local function CustomMedEffect(actor, patient, def, partId)
    GiveMed(patient, def.id, partId)
    if def.healsFracture then
        local partState = patient.KMSState.parts[partId]
        partState.frac = false
        partState.splint = false
    end
    local med = KMS.Meds[def.id]
    if (med.heal or 0) > 0 then
        KMS.TagHealSource(patient, "#item_" .. def.item)
        KMS.ExternalHeal(patient, med.heal)
    end
    if (med.stamina or 0) > 0 then
        KMS.RestoreStamina(patient, med.stamina)
    end
    return true
end

local function BandageWithMed(actor, patient, def, partId)
    local ok, errKey = ApplyBandage(actor, patient, def, partId)
    if ok then GiveMed(patient, def.sideMed, partId) end
    return ok, errKey
end

-- Roleplay medications only leave their entry in the patient log.
local function RecordOnly()
    return true
end

local function BindItemEffects()
    for _, bandageId in ipairs(KMS.Bandages) do
        local def = KMS.TreatmentById[bandageId]
        TreatmentEffects[bandageId] = (def and def.sideMed and KMS.Meds[def.sideMed]) and BandageWithMed or ApplyBandage
    end
    for _, def in ipairs(KMS.Treatments) do
        if not TreatmentEffects[def.id] then
            if def.med then
                TreatmentEffects[def.id] = CustomMedEffect
            elseif def.ivMl then
                TreatmentEffects[def.id] = TreatmentEffects.iv_saline
            elseif def.rp then
                TreatmentEffects[def.id] = RecordOnly
            end
        end
    end
end

BindItemEffects()
hook.Add("KMS_ItemsApplied", "KMS_BindItemEffects", BindItemEffects)

function KMS.ItemHolder(actor, patient, usePatient)
    return (usePatient and KMS.Settings.itemSharing and IsValid(patient)) and patient or actor
end

function KMS.ValidateTreatment(actor, patient, def, partId, usePatient)
    if not KMS.Settings.enabled then return false, "err_invalid" end
    if not IsValid(actor) or not actor:Alive() or not (actor.KMSState and actor.KMSState.conscious) then return false, "err_invalid" end
    if not IsValid(patient) or not (patient.KMSSim ~= nil or (patient:IsPlayer() and patient:Alive())) then return false, "err_dead" end
    local state = patient.KMSState
    if not state then return false, "err_invalid" end
    if KMS.Exempt(actor) or (patient:IsPlayer() and (KMS.Exempt(patient) or KMS.Cloaked(patient))) then return false, "err_invalid" end
    if state.triage == 4 then return false, "err_dead" end
    if actor == patient then
        if def.noSelf or not KMS.Settings.selfTreatment then return false, "err_self" end
    elseif not KMS.CanReach(actor, patient) then
        return false, "err_too_far"
    end
    if KMS.TreatmentTier(def.id) > KMS.EffectiveTier(actor) then return false, "err_tier" end
    if def.item and not KMS.HasItem(KMS.ItemHolder(actor, patient, usePatient), def.item) then return false, "err_no_item" end
    if def.locationKey and KMS.Settings[def.locationKey] == "crate" and not (KMS.NearCrate(actor) or KMS.NearCrate(patient)) then
        return false, "err_location"
    end
    if def.id == "pak" and KMS.Settings.pakRequireStable and not KMS.IsStable(patient) then return false, "err_pak_stable" end
    if def.id == "morphine" and CurTime() - state.lastMorphine < KMS.Settings.morphineCooldown then return false, "err_morphine_cd" end
    if def.id == "cpr" then
        if not state.arrest and KMS.Settings.diagnosisMode ~= "examine" then return false, "err_not_arrest" end
        local provider = KMS.CPRProvider(patient)
        if provider and provider ~= actor then return false, "err_cpr_taken" end
    end
    if not KMS.TreatmentAvailable(def, { parts = state.parts, states = { arrest = state.arrest, conscious = state.conscious } }, partId) then
        return false, "err_no_wound"
    end
    return true
end

local function StitchTick(actor, job)
    local patient = job.patient
    if not IsValid(patient) or not patient.KMSState then return end
    local partState = patient.KMSState.parts[job.partId]
    for _, wound in ipairs(partState.wounds) do
        if wound.b then
            AddStitched(partState, wound.t, wound.s, wound.n)
            partState.dmg = math.max(0, (partState.dmg or 0) - (wound.d or 0) * wound.n)
            table.RemoveByValue(partState.wounds, wound)
            job.stitched = true
            KMS.MarkDirty(patient)
            return
        end
    end
end

local function PlayTreatGesture(actor, isSelf)
    actor:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, isSelf and ACT_GMOD_GESTURE_ITEM_PLACE or ACT_GMOD_GESTURE_ITEM_GIVE, true)
end

function KMS.SendProgress(actor, treatId, endsAt, duration)
    KF.Net.Send("KMS_Progress", function()
        net.WriteString(treatId)
        net.WriteFloat(endsAt)
        net.WriteFloat(duration)
    end, actor)
end

local SendProgress = KMS.SendProgress

local function ClearTreatedTag(actor, patient)
    if IsValid(patient) and patient ~= actor and patient:IsPlayer() and patient:GetNWEntity("kms_treated_by") == actor then
        patient:SetNWEntity("kms_treated_by", NULL)
    end
end

function KMS.CancelTreatment(actor, silent)
    local job = actor.KMSJob
    if not job then return end
    ClearTreatedTag(actor, job.patient)
    if job.treatId == "cpr" and IsValid(job.patient) then
        local state = job.patient.KMSState
        if state and state.cprBy == actor then
            state.cprBy = nil
            KMS.MarkDirty(job.patient)
        end
    end
    actor.KMSJob = nil
    timer.Remove("KMS_Job_" .. actor:EntIndex())
    actor:SetNWBool("kms_treatlock", false)
    SendProgress(actor, "", 0, 0)
    KMS.ClearStratagem(actor)
    if not silent then
        KMS.Notify(actor, "warn", "err_moved")
    end
end

function KMS.StartChannel(actor, progressId, duration, job)
    job.endsAt = CurTime() + duration
    job.startedAt = CurTime()
    job.startPos = actor:GetPos()
    job.nextGesture = 0
    actor.KMSJob = job
    local timerName = "KMS_Job_" .. actor:EntIndex()
    job.finish = function()
        if actor.KMSJob ~= job then return end
        timer.Remove(timerName)
        actor.KMSJob = nil
        ClearTreatedTag(actor, job.patient)
        SendProgress(actor, "", 0, 0)
        KMS.ClearStratagem(actor)
        job.complete(actor, job)
    end
    SendProgress(actor, progressId, job.endsAt, duration)
    timer.Create(timerName, 0.25, 0, function()
        if not IsValid(actor) or not actor.KMSJob then
            timer.Remove(timerName)
            return
        end
        local moved = not IsValid(actor:GetVehicle()) and actor:GetPos():Distance(job.startPos) > 20
        if not actor:Alive() or moved or not IsValid(job.patient)
            or (job.patient ~= actor and not KMS.CanReach(actor, job.patient)) then
            KMS.CancelTreatment(actor)
            return
        end
        if CurTime() >= job.nextGesture then
            job.nextGesture = CurTime() + 1.6
            PlayTreatGesture(actor, actor == job.patient)
        end
        if job.onInterval and CurTime() >= (job.nextInterval or 0) and CurTime() < job.endsAt then
            job.nextInterval = CurTime() + job.interval
            job.onInterval(actor, job)
        end
        if CurTime() >= job.endsAt then job.finish() end
    end)
end

local function CompleteTreatment(actor, job)
    actor:SetNWBool("kms_treatlock", false)
    local patient = job.patient
    local def = KMS.TreatmentById[job.treatId]
    local ok, errKey = KMS.ValidateTreatment(actor, patient, def, job.partId, job.usePatient)
    if not ok then
        KMS.Notify(actor, errKey == "err_not_arrest" and "info" or "error", errKey, def.item and ("#item_" .. def.item) or "")
        return
    end
    local effect = TreatmentEffects[def.id]
    local wasSim = patient.KMSSim ~= nil
    local success, failKey, ownLog = effect(actor, patient, def, job.partId, job)
    if not success then
        KMS.Notify(actor, "error", failKey or "err_invalid")
        return
    end
    local holder = KMS.ItemHolder(actor, patient, job.usePatient)
    if def.item and not wasSim and (def.id ~= "pak" or KMS.Settings.consumePak) then KMS.TakeItem(holder, def.item) end
    if def.returnsItem and not wasSim then KMS.GiveItem(def.returnsToPatient and patient or holder, def.returnsItem) end
    if not ownLog then
        KMS.AddLog(patient, "log_apply", actor:Nick(), "#treat_" .. def.id, "#part_" .. job.partId)
    end
    if def.cat == "examine" then
        local entry = patient.KMSState.quick[1]
        if entry then
            KMS.Notify(actor, "info", entry.k, unpack(entry.a))
        end
    else
        KMS.Notify(actor, "success", "msg_applied", "#treat_" .. def.id,
            wasSim and "#sim_patient" or KF.Integrations.GetPlayerName(patient) or patient:Nick(), "#part_" .. job.partId)
    end
    if actor ~= patient and def.cat ~= "examine" then
        KMS.Notify(patient, "info", "msg_treated_you", actor:Nick(), "#treat_" .. def.id)
    end
    KMS.MarkDirty(patient)
    hook.Run("KMS_TreatmentDone", actor, patient, def.id, job.partId)
end

function KMS.StartTreatment(actor, patient, treatId, partId, usePatient)
    local def = KMS.TreatmentById[treatId]
    if not def or not KMS.PartById[partId] then
        KMS.Notify(actor, "error", "err_invalid")
        return
    end
    if actor.KMSJob then
        KMS.Notify(actor, "error", "err_busy")
        return
    end
    local ok, errKey = KMS.ValidateTreatment(actor, patient, def, partId, usePatient)
    if not ok then
        KMS.Notify(actor, "error", errKey, def.item and ("#item_" .. def.item) or "")
        return
    end
    KMS.StopDrag(actor)
    local tier = KMS.EffectiveTier(actor)
    local base
    local stitchCount
    if def.needsWound then
        local targets = FindTargetWounds(patient.KMSState.parts[partId], def.id, 1)
        if targets[1] then
            base = 0
            for _, target in ipairs(targets) do
                base = base + ({ 4, 6, 8 })[target.wound.s] * (0.666 + 0.334 * math.min(1, target.impact / math.max(0.001, target.eff)))
            end
            if #targets > 1 then
                base = base - 2 * #targets
            end
        end
    elseif def.id == "surgical" then
        local entries = 0
        for _, wound in ipairs(patient.KMSState.parts[partId].wounds) do
            if wound.b then entries = entries + 1 end
        end
        stitchCount = math.max(1, entries)
        base = stitchCount * 5
    elseif def.id == "pak" then
        local total = 0
        for _, partState in pairs(patient.KMSState.parts) do
            total = total + (partState.dmg or 0)
        end
        base = math.min(total * 5, 180)
    end
    if def.trainedKey then
        base = KMS.Settings[tier > KMS.TreatmentTier(def.id) and def.trainedKey
            or (def.trainedKey:gsub("^trained", "untrained"))]
    end
    local duration = KMS.TreatTime(def, tier, actor == patient, base)
    local job = {
        patient = patient,
        treatId = treatId,
        partId = partId,
        usePatient = usePatient == true,
        complete = CompleteTreatment,
    }
    if stitchCount then
        job.interval = duration / stitchCount
        job.nextInterval = CurTime() + job.interval
        job.onInterval = StitchTick
    end
    KMS.StartChannel(actor, treatId, duration, job)
    if KMS.Settings.holsterToTreat and def.cat ~= "examine" then
        actor:SetNWBool("kms_treatlock", true)
    end
    if def.id == "cpr" then
        patient.KMSState.cprBy = actor
        KMS.MarkDirty(patient)
    end
    if actor ~= patient and patient:IsPlayer() then
        patient:SetNWEntity("kms_treated_by", actor)
    end
    if actor ~= patient then
        KMS.Notify(patient, "info", "msg_treating_you", actor:Nick(), "#treat_" .. treatId)
    end
    KMS.StartStratagem(actor, def, duration)
end

local QUICK_IVS = { "iv_blood", "iv_blood_500", "iv_blood_250", "iv_plasma", "iv_plasma_500", "iv_plasma_250", "iv_saline_1500", "iv_saline", "iv_saline_500" }

local function QuickUsable(ply, tier, id)
    local def = KMS.TreatmentById[id]
    if not def then return nil end
    if KMS.TreatmentTier(id) > tier then return nil end
    if def.item and not KMS.HasItem(ply, def.item) then return nil end
    return def
end

local function QuickBandage(ply, tier, wound)
    local bestId, bestEff
    for _, id in ipairs(KMS.Bandages) do
        if QuickUsable(ply, tier, id) then
            local stats = KMS.BandageStats[id][wound.t]
            local eff = stats and stats.eff[wound.s] or 0
            if eff > (bestEff or 0) then bestId, bestEff = id, eff end
        end
    end
    return bestId
end

local function QuickChoice(ply, state, tier)
    local flows, worstWound, worstPart = {}, nil, nil
    for _, part in ipairs(KMS.Parts) do
        local partState = state.parts[part.id]
        local flow = 0
        for _, wound in ipairs(partState.wounds) do
            if not wound.b then
                flow = flow + KMS.WoundFlow(wound)
                if not worstWound or KMS.WoundScore(wound) > KMS.WoundScore(worstWound) then
                    worstWound, worstPart = wound, part.id
                end
            end
        end
        flows[part.id] = flow
    end
    if QuickUsable(ply, tier, "tourniquet") then
        for _, part in ipairs(KMS.Parts) do
            if part.limb and not state.parts[part.id].tq and KMS.BleedBand(flows[part.id], state) >= 2 then
                return "tourniquet", part.id
            end
        end
    end
    if worstWound then
        local bandage = QuickBandage(ply, tier, worstWound)
        if bandage then return bandage, worstPart end
    end
    for _, part in ipairs(KMS.Parts) do
        local partState = state.parts[part.id]
        if partState.tq and not KMS.PartHasBleedingWound(partState) then
            return "remove_tourniquet", part.id
        end
    end
    if QuickUsable(ply, tier, "splint") then
        for _, part in ipairs(KMS.Parts) do
            local partState = state.parts[part.id]
            if part.limb and partState.frac and not partState.splint then
                return "splint", part.id
            end
        end
    end
    if KMS.BloodClass(state.blood / KMS.Settings.maxBlood) >= 3 then
        for _, id in ipairs(QUICK_IVS) do
            if QuickUsable(ply, tier, id) then
                for _, part in ipairs(KMS.Parts) do
                    if part.limb and not state.parts[part.id].tq then
                        return id, part.id
                    end
                end
            end
        end
    end
    local freeLimb
    for _, part in ipairs(KMS.Parts) do
        if part.limb and not state.parts[part.id].tq then
            freeLimb = part.id
            break
        end
    end
    if not freeLimb then return end
    if KMS.PainBand(KMS.PerceivedPain(state)) >= 2 and KMS.ActiveMeds(state, "painkillers") == 0
        and QuickUsable(ply, tier, "painkillers") then
        return "painkillers", freeLimb
    end
    if (state.pain > 0.1 or state.blood < KMS.Settings.maxBlood * 0.9) and KMS.ActiveMeds(state, "stimpack") == 0
        and QuickUsable(ply, tier, "stimpack") then
        return "stimpack", freeLimb
    end
end

function KMS.QuickUse(ply)
    if not KMS.Settings.enabled or not KMS.Settings.quickUseEnabled or KMS.Exempt(ply) then return end
    if not KMS.Settings.selfTreatment then
        KMS.Notify(ply, "error", "err_self")
        return
    end
    local state = ply.KMSState
    if not state or not state.conscious or not ply:Alive() then return end
    if ply.KMSJob then
        KMS.Notify(ply, "error", "err_busy")
        return
    end
    local treatId, partId = QuickChoice(ply, state, KMS.EffectiveTier(ply))
    if not treatId then
        KMS.Notify(ply, "info", "qu_nothing")
        return
    end
    KMS.StartTreatment(ply, ply, treatId, partId, false)
end

function KMS.SendLoot(ply, ent)
    KF.Net.Send("KMS_LootOpen", function()
        net.WriteEntity(ent)
        KF.Net.WriteCompressed(ent.KMSCache or {}, 16)
    end, ply)
end

KF.Net.Receive("KMS_LootItem", function(_, ply)
    local ent = net.ReadEntity()
    local itemId = net.ReadString()
    local count = net.ReadUInt(8)
    if not KMS.Settings.enabled or KMS.Settings.infiniteSupplies then return end
    if not KMS.ItemById[itemId] or count <= 0 then return end
    if not IsValid(ent) or not ply:Alive() then return end
    if ent:IsPlayer() then
        if not KMS.Settings.invLootDowned or ent == ply then return end
        if not KMS.IsDowned(ent) or not ent:Alive() or not KMS.CanReach(ply, ent) then return end
        local moved = math.min(count, ent.KMSInv and ent.KMSInv[itemId] or 0)
        if moved <= 0 then return end
        for _ = 1, moved do
            KMS.TakeItem(ent, itemId)
            KMS.GiveItem(ply, itemId)
        end
        KMS.AddLog(ent, "log_loot", ply:Nick(), moved, "#item_" .. itemId)
    elseif ent.KMSCache then
        if ent:GetPos():DistToSqr(ply:GetPos()) > KMS.InteractRangeSqr then return end
        if KMS.MoveStorageItem(ply, ent.KMSCache, itemId, count, false) > 0 then
            if next(ent.KMSCache) then KMS.SendLoot(ply, ent) else ent:Remove() end
        end
    end
end, { rateLimit = 0.2 })


local STRATAGEM_CATS = { bandage = true, meds = true, advanced = true }

-- Strivon: Schnellbehandlung im Comlink-Medic-Menü (hradio.Config.MedicQuickTreat). Gilt auch, wenn der
-- Stratagem-Modus im Medical-Admin aus ist. Standard: die 4 Pfeiltasten je einmal in zufälliger Reihenfolge.
local function QuickTreatConfig()
    local cfg = hradio and hradio.Config
    if not cfg or cfg.MedicQuickTreat == false then return nil end
    return math.Clamp(math.floor(tonumber(cfg.MedicQuickTreatLength) or 4), 2, 12)
end

local function ShuffledArrows(length)
    local sequence = {}
    -- erst alle 4 Richtungen gemischt, bei längeren Folgen wieder von vorn (nie zweimal dieselbe hintereinander)
    while #sequence < length do
        local block = { 1, 2, 3, 4 }
        for i = 4, 2, -1 do
            local j = math.random(1, i)
            block[i], block[j] = block[j], block[i]
        end
        if block[1] == sequence[#sequence] then
            block[1], block[4] = block[4], block[1]
        end
        for _, dir in ipairs(block) do
            if #sequence < length then sequence[#sequence + 1] = dir end
        end
    end
    return sequence
end

function KMS.StartStratagem(actor, def, duration)
    if not STRATAGEM_CATS[def.cat] or duration < 1 then return end

    local quickLength = actor.KMSQuickTreat and QuickTreatConfig()
    local sequence

    if quickLength then
        sequence = ShuffledArrows(quickLength)
    else
        if not KMS.Settings.stratagemMode then return end
        local tuning = KMS.StratagemTuning[KMS.StratagemDifficultyFor(KMS.MedicTier(actor))]
        if not tuning then return end
        sequence = {}
        for i = 1, tuning.length do
            sequence[i] = math.random(1, 4)
        end
    end
    actor.KMSStratagem = { sequence = sequence, index = 1 }
    KF.Net.Send("KMS_Stratagem", function()
        net.WriteUInt(#sequence, 5)
        for _, dir in ipairs(sequence) do
            net.WriteUInt(dir, 3)
        end
    end, actor)
end

function KMS.ClearStratagem(actor)
    if IsValid(actor) and actor.KMSStratagem then
        actor.KMSStratagem = nil
        KF.Net.Send("KMS_Stratagem", function()
            net.WriteUInt(0, 5)
        end, actor)
    end
end

KF.Net.Receive("KMS_StratagemStep", function(_, ply)
    local dir = net.ReadUInt(3)
    local strat = ply.KMSStratagem
    local job = ply.KMSJob
    if not strat or not job then return end
    if strat.sequence[strat.index] == dir then
        strat.index = strat.index + 1
    else
        strat.index = 1
    end
    if strat.index > #strat.sequence then
        job.finish()
    end
end, { rateLimit = 0.03 })

hook.Add("KMS_TreatmentDone", "KMS_StratagemClear", function(actor)
    KMS.ClearStratagem(actor)
end)

function KMS.NearestStorageNPC(ply)
    local best, bestDist
    local origin = KMS.BodyEnt(ply):GetPos()
    for _, ent in ipairs(ents.FindByClass("kms_npc")) do
        local npc = KMS.NPCs[ent:GetNWString("kms_npc_id", "")]
        if npc and npc.npcType == "supply" then
            local dist = ent:GetPos():DistToSqr(origin)
            if dist <= KMS.FacilityRangeSqr and (not bestDist or dist < bestDist) then
                best, bestDist = { ent = ent, npc = npc }, dist
            end
        end
    end
    return best
end

function KMS.CanTrade(ply)
    return KMS.Settings.enabled and not KMS.Settings.infiniteSupplies and KMS.Settings.itemSharing
        and IsValid(ply) and ply:Alive() and ply.KMSState and ply.KMSState.conscious
end

local CanTrade = KMS.CanTrade

function KMS.MoveStorageItem(ply, storage, itemId, count, deposit)
    if deposit then
        local moved = math.min(count, (ply.KMSInv and ply.KMSInv[itemId]) or 0)
        if moved <= 0 then
            KMS.Notify(ply, "error", "err_no_item", "#item_" .. itemId)
            return 0
        end
        for _ = 1, moved do KMS.TakeItem(ply, itemId) end
        storage[itemId] = (storage[itemId] or 0) + moved
        return moved
    end
    local moved = math.min(count, storage[itemId] or 0)
    if moved <= 0 then
        KMS.Notify(ply, "error", "inv_none_stored", "#item_" .. itemId)
        return 0
    end
    storage[itemId] = (storage[itemId] or 0) - moved
    if storage[itemId] <= 0 then storage[itemId] = nil end
    for _ = 1, moved do KMS.GiveItem(ply, itemId) end
    return moved
end

KF.Net.Receive("KMS_GiveItem", function(_, ply)
    local target = net.ReadEntity()
    local itemId = net.ReadString()
    local count = net.ReadUInt(8)
    if not CanTrade(ply) or not IsValid(target) or not target:IsPlayer() or target == ply then return end
    if not target:Alive() then return end
    if not KMS.ItemById[itemId] or count <= 0 then return end
    if not KMS.CanReach(ply, target) then
        KMS.Notify(ply, "error", "err_too_far")
        return
    end
    local have = (ply.KMSInv and ply.KMSInv[itemId]) or 0
    local moved = math.min(count, have)
    if moved <= 0 then
        KMS.Notify(ply, "error", "err_no_item", "#item_" .. itemId)
        return
    end
    for _ = 1, moved do
        KMS.TakeItem(ply, itemId)
        KMS.GiveItem(target, itemId)
    end
    KMS.Notify(ply, "success", "inv_gave", moved, "#item_" .. itemId, KF.Integrations.GetPlayerName(target) or target:Nick())
    KMS.Notify(target, "info", "inv_received", moved, "#item_" .. itemId, KF.Integrations.GetPlayerName(ply) or ply:Nick())
end, { rateLimit = 0.3 })

local function SyncStorage(ply, npc)
    KF.Net.Send("KMS_StorageSync", function()
        KF.Net.WriteCompressed(npc.storage or {}, 16)
    end, ply)
end

KF.Net.Receive("KMS_StoreItem", function(_, ply)
    local itemId = net.ReadString()
    local count = net.ReadUInt(8)
    local deposit = net.ReadBool()
    if not CanTrade(ply) or not KMS.ItemById[itemId] or count <= 0 then return end
    local near = KMS.NearestStorageNPC(ply)
    if not near then
        KMS.Notify(ply, "error", "err_location")
        return
    end
    if not KMS.NPCAccess(ply, near.npc) then
        KMS.Notify(ply, "error", "err_npc_denied")
        return
    end
    local storage = near.npc.storage or {}
    near.npc.storage = storage
    if KMS.MoveStorageItem(ply, storage, itemId, count, deposit) <= 0 then return end
    if not timer.Exists("KMS_SaveNPCs") then
        timer.Create("KMS_SaveNPCs", 1, 1, KMS.Data.SaveNPCs)
    end
    SyncStorage(ply, near.npc)
end, { rateLimit = 0.2 })

KF.Net.Receive("KMS_StorageOpen", function(_, ply)
    if not CanTrade(ply) then return end
    local near = KMS.NearestStorageNPC(ply)
    if near and KMS.NPCAccess(ply, near.npc) then
        SyncStorage(ply, near.npc)
    end
end, { rateLimit = 0.5 })

KMS.MedVehicleEnts = KMS.MedVehicleEnts or {}

local function ResolveTemplate(class)
    local template = KMS.MedVehicleTemplate(class)
    if not template then return nil end
    local inv = {}
    for itemId, amount in pairs(template) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 and KMS.ItemById[itemId] and not KMS.ItemDisabled[itemId] then
            inv[itemId] = math.min(amount, 999)
        end
    end
    return inv
end

local function MarkVehicle(ent)
    if KMS.MedVehicleEnts[ent] then return end
    local class = ent:GetClass()
    if not KMS.MedVehicleEntry(class) then return end
    if KMS.VehicleBase(ent) ~= ent then return end
    ent.KMSVehInv = ent.KMSVehInv or ResolveTemplate(class) or {}
    ent:SetNWBool("kms_medvehicle", true)
    KMS.MedVehicleEnts[ent] = true
end

local function UnmarkVehicle(ent)
    if not KMS.MedVehicleEnts[ent] then return end
    KMS.MedVehicleEnts[ent] = nil
    if IsValid(ent) then
        ent:SetNWBool("kms_medvehicle", false)
        ent.KMSVehInv = nil
    end
end

function KMS.RescanMedVehicles()
    for ent in pairs(KMS.MedVehicleEnts) do
        if not IsValid(ent) or not KMS.MedVehicleEntry(ent:GetClass()) then
            UnmarkVehicle(ent)
        end
    end
    if not KMS.Settings.enabled or next(KMS.Settings.medVehicles) == nil then return end
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) then MarkVehicle(ent) end
    end
end

hook.Add("OnEntityCreated", "KMS_MedVehicle", function(ent)
    if not IsValid(ent) or not KMS.Settings.enabled then return end
    if not KMS.MedVehicleEntry(ent:GetClass()) then return end
    timer.Simple(0, function()
        if IsValid(ent) then MarkVehicle(ent) end
    end)
end)

hook.Add("EntityRemoved", "KMS_MedVehicle", function(ent)
    UnmarkVehicle(ent)
end)

hook.Add("InitPostEntity", "KMS_MedVehicleScan", function()
    KMS.RescanMedVehicles()
end)

if KMS.WorldReady then KMS.RescanMedVehicles() end

KMS.SavedVehicles = KMS.SavedVehicles or {}

local function NextVehicleId()
    local index = 1
    while KMS.SavedVehicles["veh_" .. index] do
        index = index + 1
    end
    return "veh_" .. index
end

function KMS.SaveVehiclesSoon()
    if timer.Exists("KMS_SaveVehicles") then return end
    timer.Create("KMS_SaveVehicles", 1, 1, KMS.Data.SaveVehicles)
end

local function ClearVehicleTimers(id)
    timer.Remove("KMS_VehRespawn_" .. id)
    timer.Remove("KMS_VehForget_" .. id)
end

local function LiveVehicle(id)
    for ent in pairs(KMS.MedVehicleEnts) do
        if IsValid(ent) and ent.KMSVehId == id then return ent end
    end
    return nil
end

local function BindSavedVehicle(ent, record)
    ent.KMSVehId = record.id
    ent.KMSVehInv = table.Copy(record.inv or {})
    ent:SetNWBool("kms_vehsaved", true)
    MarkVehicle(ent)
end

local function SpawnSavedVehicle(record)
    if record.map ~= game.GetMap() then return end
    if LiveVehicle(record.id) then return end
    ClearVehicleTimers(record.id)
    local ent
    if record.dupe ~= "" then
        local data = util.JSONToTable(record.dupe)
        if istable(data) then
            local ok, created = pcall(duplicator.CreateEntityFromTable, nil, data)
            if ok and IsValid(created) then ent = created end
        end
    end
    if not IsValid(ent) then
        ent = ents.Create(record.class)
        if not IsValid(ent) then return end
        ent:SetPos(Vector(record.pos.x, record.pos.y, record.pos.z))
        ent:SetAngles(Angle(record.ang.p, record.ang.y, record.ang.r))
        ent:Spawn()
        ent:Activate()
    end
    BindSavedVehicle(ent, record)
end

function KMS.RespawnSavedVehicles()
    if not KMS.WorldReady then return end
    for _, record in pairs(KMS.SavedVehicles) do
        SpawnSavedVehicle(record)
    end
end

function KMS.PersistVehicle(ent)
    local root = KMS.VehicleBase(ent)
    if not IsValid(root) or not KMS.MedVehicleEnts[root] or root.KMSVehId then return false end
    local pos, ang = root:GetPos(), root:GetAngles()
    local dupe = ""
    local ok, data = pcall(duplicator.CopyEntTable, root)
    if ok and istable(data) then
        local json = util.TableToJSON(data)
        if isstring(json) and #json <= 65536 then dupe = json end
    end
    local id = NextVehicleId()
    local record = KMS.SanitizeVehicle({
        id = id,
        class = root:GetClass(),
        map = game.GetMap(),
        dupe = dupe,
        pos = { x = pos.x, y = pos.y, z = pos.z },
        ang = { p = ang.p, y = ang.y, r = ang.r },
        inv = root.KMSVehInv,
    })
    if not record then return false end
    KMS.SavedVehicles[id] = record
    root.KMSVehId = id
    root:SetNWBool("kms_vehsaved", true)
    KMS.Data.SaveVehicles()
    return true
end

function KMS.ForgetVehicle(ent)
    local root = KMS.VehicleBase(ent)
    local id = IsValid(root) and root.KMSVehId
    if not id then return false end
    ClearVehicleTimers(id)
    KMS.SavedVehicles[id] = nil
    root.KMSVehId = nil
    root:SetNWBool("kms_vehsaved", false)
    KMS.Data.SaveVehicles()
    return true
end

hook.Add("EntityRemoved", "KMS_MedVehicleSaved", function(ent)
    local id = ent.KMSVehId
    if not id or not KMS.SavedVehicles[id] or KMS.Halting then return end
    if KMS.Settings.medVehicleLoss == "remove" then
        timer.Create("KMS_VehForget_" .. id, 1, 1, function()
            if KMS.Halting or not KMS.SavedVehicles[id] then return end
            KMS.SavedVehicles[id] = nil
            KMS.Data.SaveVehicles()
        end)
        return
    end
    timer.Create("KMS_VehRespawn_" .. id, KMS.Settings.medVehicleRespawnTime, 1, function()
        local record = not KMS.Halting and KMS.SavedVehicles[id]
        if record then SpawnSavedVehicle(record) end
    end)
end)

hook.Add("PreCleanupMap", "KMS_MedVehicleSaved", function()
    KMS.Halting = true
end)

hook.Add("PostCleanupMap", "KMS_MedVehicleSaved", function()
    KMS.Halting = false
    KMS.RespawnSavedVehicles()
end)

hook.Add("ShutDown", "KMS_MedVehicleSaved", function()
    KMS.Halting = true
    if timer.Exists("KMS_SaveNPCs") then KMS.Data.SaveNPCs() end
    if timer.Exists("KMS_SaveVehicles") then KMS.Data.SaveVehicles() end
end)

hook.Add("KMS_DataLoaded", "KMS_MedVehicleSaved", function()
    KMS.RespawnSavedVehicles()
end)

KMS.AdminActions = KMS.AdminActions or {}

KMS.AdminActions.vehicle_persist = function(_, payload)
    local root = KMS.VehicleBase(Entity(tonumber(payload.id) or 0))
    if not IsValid(root) or not KMS.MedVehicleEnts[root] then return false, "err_not_medvehicle" end
    if root.KMSVehId then
        KMS.ForgetVehicle(root)
        return true, "msg_veh_forgotten"
    end
    if not KMS.PersistVehicle(root) then return false, "adm_err_invalid" end
    return true, "msg_veh_persisted"
end

function KMS.NearMedVehicle(ply)
    if next(KMS.MedVehicleEnts) == nil then return false end
    if KMS.InsideMedVehicle(ply) then return true end
    local pos = KMS.BodyEnt(ply):GetPos()
    for ent in pairs(KMS.MedVehicleEnts) do
        if IsValid(ent) then
            if ent:NearestPoint(pos):DistToSqr(pos) <= KMS.FacilityRangeSqr then return true end
        else
            KMS.MedVehicleEnts[ent] = nil
        end
    end
    return false
end

local function VehInvTarget(ply, ent)
    if not KMS.CanTrade(ply) then return nil end
    local root = KMS.VehicleBase(ent)
    if not IsValid(root) or not KMS.MedVehicleEnts[root] or not istable(root.KMSVehInv) then
        KMS.Notify(ply, "error", "err_not_medvehicle")
        return nil
    end
    if not KMS.VehInvAccess(ply) then
        KMS.Notify(ply, "error", "err_npc_denied")
        return nil
    end
    if KMS.VehicleBase(ply:GetVehicle()) ~= root then
        local pos = ply:GetPos()
        if root:NearestPoint(pos):Distance(pos) > KMS.Settings.maxTreatDistance * KMS.ReachMargin or not KMS.ClearSight(ply, root) then
            KMS.Notify(ply, "error", "err_too_far")
            return nil
        end
    end
    return root
end

local function SyncVehInv(ply, root)
    KF.Net.Send("KMS_VehInvSync", function()
        net.WriteEntity(root)
        KF.Net.WriteCompressed(root.KMSVehInv or {}, 16)
    end, ply)
end

KF.Net.Receive("KMS_VehInvOpen", function(_, ply)
    local root = VehInvTarget(ply, net.ReadEntity())
    if root then SyncVehInv(ply, root) end
end, { rateLimit = 0.5 })

KF.Net.Receive("KMS_VehInvMove", function(_, ply)
    local ent = net.ReadEntity()
    local itemId = net.ReadString()
    local count = net.ReadUInt(8)
    local deposit = net.ReadBool()
    if not KMS.ItemById[itemId] or count <= 0 then return end
    local root = VehInvTarget(ply, ent)
    if not root then return end
    if KMS.MoveStorageItem(ply, root.KMSVehInv, itemId, count, deposit) > 0 then
        local record = root.KMSVehId and KMS.SavedVehicles[root.KMSVehId]
        if record then
            record.inv = table.Copy(root.KMSVehInv)
            KMS.SaveVehiclesSoon()
        end
        SyncVehInv(ply, root)
    end
end, { rateLimit = 0.2 })

KMS.SpawnedNPCs = KMS.SpawnedNPCs or {}

local spawned = KMS.SpawnedNPCs

function KMS.DespawnNPC(id)
    local ent = spawned[id]
    if IsValid(ent) then
        if IsValid(ent.KMSDrill) then KMS.FinishSim(ent.KMSDrill, "aborted") end
        ent:Remove()
    end
    spawned[id] = nil
end

function KMS.SpawnNPC(npc)
    KMS.DespawnNPC(npc.id)
    if not KMS.WorldReady or npc.spawnMap ~= game.GetMap() then return end
    local ent = ents.Create("kms_npc")
    if not IsValid(ent) then return end
    ent:SetPos(Vector(npc.spawnPos.x, npc.spawnPos.y, npc.spawnPos.z))
    ent:SetAngles(Angle(npc.spawnAng.p, npc.spawnAng.y, npc.spawnAng.r))
    ent:SetNWString("kms_npc_id", npc.id)
    ent:Spawn()
    spawned[npc.id] = ent
end

function KMS.RespawnAllNPCs()
    for id in pairs(spawned) do
        KMS.DespawnNPC(id)
    end
    for _, npc in pairs(KMS.NPCs) do
        KMS.SpawnNPC(npc)
    end
end

hook.Add("InitPostEntity", "KMS_SpawnNPCs", function()
    KMS.WorldReady = true
    KMS.RespawnAllNPCs()
    KMS.RespawnSavedVehicles()
end)

hook.Add("PostCleanupMap", "KMS_RespawnNPCs", function()
    KMS.RespawnAllNPCs()
end)

hook.Add("KMS_DataLoaded", "KMS_SpawnNPCs", function()
    KMS.RespawnAllNPCs()
end)

local function NextNPCId()
    local index = 1
    while KMS.NPCs["npc_" .. index] do
        index = index + 1
    end
    return "npc_" .. index
end

hook.Add("PlayerSpawnSENT", "KMS_NPCSpawnGate", function(ply, class)
    if class ~= "kms_npc" then return end
    if KMS.IsAdmin(ply) then return end
    KMS.Notify(ply, "error", "err_admin_only")
    return false
end)

hook.Add("PlayerSpawnedSENT", "KMS_NPCPlaced", function(ply, ent)
    if not IsValid(ent) or ent:GetClass() ~= "kms_npc" then return end
    if ent:GetNWString("kms_npc_id", "") ~= "" then return end
    if not KMS.IsAdmin(ply) then
        ent:Remove()
        KMS.Notify(ply, "error", "err_admin_only")
        return
    end
    local id = NextNPCId()
    local npc = KMS.SanitizeNPC({ id = id, npcType = "supply", model = KMS.Settings.npcModels.supply })
    if not npc then
        ent:Remove()
        return
    end
    local pos, ang = ent:GetPos(), ent:GetAngles()
    npc.spawnMap = game.GetMap()
    npc.spawnPos = { x = pos.x, y = pos.y, z = pos.z }
    npc.spawnAng = { p = 0, y = ang.y, r = 0 }
    KMS.NPCs[id] = npc
    ent:Remove()
    KMS.SpawnNPC(npc)
    KMS.Data.SaveNPCs()
    KMS.SyncConfig(nil)
    KMS.Notify(ply, "success", "npc_created")
end)

local function ProtectedNPC(ent)
    return IsValid(ent) and ent:GetClass() == "kms_npc"
end

hook.Add("CanTool", "KMS_NPCProtect", function(ply, tr, tool)
    if tool ~= "remover" or not ProtectedNPC(tr.Entity) then return end
    KMS.Notify(ply, "warn", "npc_remove_hint")
    return false
end)

hook.Add("CanProperty", "KMS_NPCProtect", function(ply, property, ent)
    if property ~= "remove" or not ProtectedNPC(ent) then return end
    KMS.Notify(ply, "warn", "npc_remove_hint")
    return false
end)

hook.Add("PhysgunPickup", "KMS_NPCProtect", function(_, ent)
    if ProtectedNPC(ent) then return false end
end)

function KMS.NPCQuoteFor(npc, patient)
    local state = patient.KMSState
    local units, fractures = 0, 0
    for _, partState in pairs(state.parts) do
        for _, wound in ipairs(partState.wounds) do
            units = units + wound.s * KMS.WoundEvents(wound)
        end
        if partState.frac then fractures = fractures + 1 end
    end
    local bloodLost = 1 - state.blood / KMS.Settings.maxBlood
    local cost = math.min(npc.baseCost + units * npc.woundCost + fractures * npc.fractureCost + math.Round(bloodLost * npc.bloodCost), KMS.MaxCost)
    local injured = units > 0 or fractures > 0 or bloodLost > 0.01
        or not state.conscious or patient:Health() < patient:GetMaxHealth()
    return cost, injured
end

local function StopNPCHeal(ply, healed)
    timer.Remove("KMS_NPCHeal_" .. ply:EntIndex())
    local cost = ply.KMSNPCHeal
    if not cost then return end
    ply.KMSNPCHeal = nil
    ply:Freeze(false)
    KMS.SendProgress(ply, "", 0, 0)
    if healed and ply:Alive() then
        KMS.FullHeal(ply)
        KMS.Notify(ply, "success", "msg_npc_healed")
    else
        KF.Integrations.AddMoney(ply, cost)
    end
end

local function StartNPCHeal(ply, npc, cost)
    ply.KMSNPCHeal = cost
    ply:Freeze(true)
    KMS.SendProgress(ply, "npc", CurTime() + npc.healTime, npc.healTime)
    timer.Create("KMS_NPCHeal_" .. ply:EntIndex(), npc.healTime, 1, function()
        if IsValid(ply) then StopNPCHeal(ply, true) end
    end)
end

function KMS.NPCUse(ent, ply)
    if not KMS.Settings.enabled then return end
    local npc = KMS.NPCs[ent:GetNWString("kms_npc_id", "")]
    if not npc or not ply.KMSState then return end
    if not KMS.NPCAccess(ply, npc) then
        KMS.Notify(ply, "error", "err_npc_denied")
        return
    end
    if npc.npcType == "supply" then
        KMS.RestockPlayer(ply, npc.supplies)
    elseif npc.npcType == "simulator" then
        local drill = ent.KMSDrill
        if IsValid(drill) then
            local sim = drill.KMSSim
            if sim and sim.trainee == ply then
                KMS.FinishSim(drill, "aborted")
            else
                KMS.Notify(ply, "warn", "sim_active")
            end
            return
        end
        if not ply.KMSState.conscious then return end
        KF.Net.Send("KMS_SimSetup", function()
            net.WriteEntity(ent)
        end, ply)
    elseif npc.npcType == "exam" then
        KMS.StartExam(ent, npc, ply)
    elseif npc.npcType == "billing" then
        if ply.KMSNPCHeal or not ply.KMSState.conscious then return end
        local cost, injured = KMS.NPCQuoteFor(npc, ply)
        if not injured then
            KMS.Notify(ply, "info", "msg_npc_healthy")
            return
        end
        KF.Net.Send("KMS_NPCQuote", function()
            net.WriteEntity(ent)
            net.WriteUInt(cost, 32)
            net.WriteUInt(npc.healTime, 16)
        end, ply)
    end
end

KF.Net.Receive("KMS_NPCAccept", function(_, ply)
    if not KMS.Settings.enabled then return end
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "kms_npc" then return end
    local npc = KMS.NPCs[ent:GetNWString("kms_npc_id", "")]
    if not npc or npc.npcType ~= "billing" or not ply.KMSState then return end
    if ply.KMSNPCHeal or not ply.KMSState.conscious or not ply:Alive() then return end
    if not KMS.NPCAccess(ply, npc) then return end
    if ply:GetPos():DistToSqr(ent:GetPos()) > KMS.InteractRangeSqr then return end
    local cost, injured = KMS.NPCQuoteFor(npc, ply)
    if not injured then return end
    if (KF.Integrations.GetMoney(ply) or 0) < cost then
        KMS.Notify(ply, "error", "err_no_money")
        return
    end
    KF.Integrations.RemoveMoney(ply, cost)
    KMS.StopDrag(ply)
    KMS.CancelTreatment(ply, true)
    StartNPCHeal(ply, npc, cost)
end, { rateLimit = 0.5 })

KF.Net.Receive("KMS_NPCPlace", function(_, ply)
    if not KMS.IsAdmin(ply) then return end
    local id = net.ReadString()
    local pos = net.ReadVector()
    local ang = net.ReadAngle()
    local npc = KMS.NPCs[id]
    if not npc then return end
    if not KF.Sanitize.IsFiniteVector(pos) or not KF.Sanitize.IsFiniteNumber(ang.y) then return end
    npc.spawnMap = game.GetMap()
    npc.spawnPos = { x = pos.x, y = pos.y, z = pos.z }
    npc.spawnAng = { p = 0, y = ang.y, r = 0 }
    KMS.Data.SaveNPCs()
    KMS.SpawnNPC(npc)
    KMS.SyncConfig(nil)
end, { rateLimit = 0.5 })

KMS.AdminActions.save_npc = function(ply, payload)
    local npc = KMS.SanitizeNPC(payload.npc)
    if not npc then return false, "adm_err_invalid" end
    local existing = KMS.NPCs[npc.id]
    if npc.rewardType == "command" and not ply:IsSuperAdmin()
        and not (existing and existing.rewardType == "command" and existing.rewardValue == npc.rewardValue) then
        return false, "adm_err_superadmin"
    end
    if existing then
        npc.spawnMap = existing.spawnMap
        npc.spawnPos = existing.spawnPos
        npc.spawnAng = existing.spawnAng
    end
    KMS.NPCs[npc.id] = npc
    KMS.Data.SaveNPCs()
    KMS.SpawnNPC(npc)
    KMS.SyncConfig(nil)
    if npc.npcType == "supply" then
        local empty = true
        for _, amount in pairs(npc.supplies) do
            if amount > 0 then
                empty = false
                break
            end
        end
        if empty then return true, "adm_npc_saved_empty" end
    end
    return true, "adm_ok_setting"
end

KMS.AdminActions.delete_npc = function(ply, payload)
    local id = tostring(payload.id or "")
    if not KMS.NPCs[id] then return false, "adm_err_invalid" end
    KMS.DespawnNPC(id)
    KMS.NPCs[id] = nil
    KMS.Data.SaveNPCs()
    KMS.SyncConfig(nil)
    return true, "adm_ok_setting"
end

KMS.AdminActions.unplace_npc = function(ply, payload)
    local npc = KMS.NPCs[tostring(payload.id or "")]
    if not npc then return false, "adm_err_invalid" end
    npc.spawnMap = ""
    KMS.DespawnNPC(npc.id)
    KMS.Data.SaveNPCs()
    KMS.SyncConfig(nil)
    return true, "adm_ok_setting"
end

hook.Add("KMS_PlayerDowned", "KMS_NPCHealCancel", function(ply)
    StopNPCHeal(ply, false)
end)

hook.Add("PlayerDeath", "KMS_NPCHealCancel", function(ply)
    StopNPCHeal(ply, false)
end)

hook.Add("PlayerDisconnected", "KMS_NPCHealCancel", function(ply)
    StopNPCHeal(ply, false)
end)

local SIM_BLEEDERS = { "velocity", "laceration", "puncture", "cut", "avulsion", "crush" }
local SIM_WOUND_POOL = { "velocity", "laceration", "puncture", "cut", "avulsion", "crush", "contusion", "burn" }
local SIM_LIMBS = { "arm_l", "arm_r", "leg_l", "leg_r" }

local function SimModelValid(model)
    local target = string.lower(model or "")
    for _, mdl in pairs(player_manager.AllValidModels()) do
        if string.lower(mdl) == target then return true end
    end
    return false
end

function KMS.FinishSim(ragdoll, result)
    local sim = ragdoll.KMSSim
    if not sim then return end
    ragdoll.KMSSim = nil
    KMS.SimPatients[ragdoll] = nil
    if IsValid(sim.terminal) then sim.terminal.KMSDrill = nil end
    for _, other in ipairs(player.GetAll()) do
        if other.KMSJob and other.KMSJob.patient == ragdoll then
            KMS.CancelTreatment(other, true)
        end
    end
    if IsValid(sim.trainee) then
        if result == "passed" then
            KMS.Notify(sim.trainee, "success", "sim_passed", KF.FormatTime(math.ceil(CurTime() - sim.startedAt)))
        elseif result == "dead" then
            KMS.Notify(sim.trainee, "error", "sim_failed_dead")
        elseif result == "time" then
            KMS.Notify(sim.trainee, "error", "sim_failed_time")
        else
            KMS.Notify(sim.trainee, "warn", "sim_aborted")
        end
    end
    if IsValid(ragdoll) then SafeRemoveEntityDelayed(ragdoll, 3) end
end

hook.Add("EntityRemoved", "KMS_SimRemoved", function(ent)
    if ent.KMSSim then KMS.FinishSim(ent, "aborted") end
end)

KF.Net.Receive("KMS_SimStart", function(_, ply)
    local ent = net.ReadEntity()
    local model = net.ReadString()
    local difficulty = net.ReadString()
    local timed = net.ReadBool()
    if not KMS.Settings.enabled then return end
    local tuning = KMS.SimTuning[difficulty]
    if not tuning or not SimModelValid(model) then return end
    if not IsValid(ent) or ent:GetClass() ~= "kms_npc" then return end
    local npc = KMS.NPCs[ent:GetNWString("kms_npc_id", "")]
    if not npc or npc.npcType ~= "simulator" then return end
    if not ply:Alive() or not (ply.KMSState and ply.KMSState.conscious) then return end
    if ply:GetPos():DistToSqr(ent:GetPos()) > KMS.InteractRangeSqr then return end
    if not KMS.NPCAccess(ply, npc) then return end
    if IsValid(ent.KMSDrill) then
        KMS.Notify(ply, "warn", "sim_active")
        return
    end
    local ragdoll = ents.Create("prop_ragdoll")
    if not IsValid(ragdoll) then return end
    ragdoll:SetModel(model)
    local target = ent:GetPos() + ent:GetForward() * 60
    local ground = util.TraceLine({ start = target + Vector(0, 0, 40), endpos = target - Vector(0, 0, 128), mask = MASK_PLAYERSOLID, filter = { ent, ply } })
    ragdoll:SetPos(ground.Hit and (ground.HitPos + Vector(0, 0, 8)) or target)
    ragdoll:SetAngles(Angle(0, ent:GetAngles().yaw, 0))
    ragdoll:Spawn()
    ragdoll:Activate()
    ragdoll.PhysgunDisabled = true
    ragdoll:SetNWBool("kms_sim", true)
    KMS.ResetState(ragdoll)
    local state = ragdoll.KMSState
    state.conscious = false
    local count = math.random(tuning.wounds[1], tuning.wounds[2])
    local pain = 0
    for i = 1, count do
        local pool = i == 1 and SIM_BLEEDERS or SIM_WOUND_POOL
        local woundType = pool[math.random(#pool)]
        local size = math.random(1, tuning.maxSize)
        KMS.AddWound(ragdoll, KMS.Parts[math.random(#KMS.Parts)].id, woundType, size, 1)
        pain = math.max(pain, KMS.CategorySize[size] * KMS.Wounds[woundType].pain)
    end
    if tuning.fracture > 0 and math.random(100) <= tuning.fracture then
        state.parts[SIM_LIMBS[math.random(#SIM_LIMBS)]].frac = true
    end
    state.blood = KMS.Settings.maxBlood * tuning.blood
    state.pain = math.Clamp(pain * KMS.Coef("painCoef"), 0, 1)
    if tuning.arrest then
        KMS.EnterArrest(ragdoll, state)
    end
    ragdoll.KMSSim = {
        terminal = ent,
        trainee = ply,
        startedAt = CurTime(),
        deadline = timed and (CurTime() + tuning.time) or nil,
    }
    KMS.SimPatients[ragdoll] = true
    ent.KMSDrill = ragdoll
    state.dirty = true
    if timed then
        KMS.Notify(ply, "info", "sim_started_timed", KF.FormatTime(tuning.time))
    else
        KMS.Notify(ply, "info", "sim_started")
    end
end, { rateLimit = 1 })

local EXAM_BANK

local function ExamShuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

local EXAM_MEDS = { "morphine", "epinephrine", "adenosine", "painkillers" }

local function MedOptions()
    local opts = {}
    for i, id in ipairs(EXAM_MEDS) do
        opts[i] = "#item_" .. id
    end
    return opts
end

local function MedExtreme(field, wantMax)
    local best, bestValue
    for i, id in ipairs(EXAM_MEDS) do
        local value = field(KMS.Meds[id])
        if not bestValue or (wantMax and value > bestValue) or (not wantMax and value < bestValue) then
            best, bestValue = i, value
        end
    end
    return best
end

-- The exam net message carries at most 7 options, so only four random bandages compete.
local function BandageExtreme(woundType, pickValue, wantMin)
    local opts, best, bestValue = {}, 1, nil
    local pool = ExamShuffle(table.Copy(KMS.Bandages))
    for i = 1, math.min(4, #pool) do
        local bandage = pool[i]
        opts[i] = "#item_" .. bandage
        local value = pickValue(KMS.BandageStats[bandage][woundType])
        if not bestValue or (wantMin and value < bestValue) or (not wantMin and value > bestValue) then
            best, bestValue = i, value
        end
    end
    return opts, best
end

local function BuildExamBank()
    if EXAM_BANK then return EXAM_BANK end
    EXAM_BANK = {
        { pool = "data", gen = function()
            local groups = { { "velocity" }, { "avulsion" }, { "crush", "laceration", "puncture" }, { "cut" }, { "abrasion" }, { "burn", "contusion" } }
            ExamShuffle(groups)
            local opts, correct, bestFlow = {}, 1, -1
            for i = 1, 4 do
                local woundType = groups[i][math.random(#groups[i])]
                opts[i] = "#wound_" .. woundType
                local flow = KMS.Wounds[woundType].bleed
                if flow > bestFlow then bestFlow, correct = flow, i end
            end
            return "exq_bleed_worst", {}, opts, correct
        end },
        { pool = "data", gen = function()
            local pool = { "cut", "laceration", "abrasion", "avulsion", "velocity", "burn", "crush" }
            local woundType = pool[math.random(#pool)]
            local opts, correct = BandageExtreme(woundType, function(stats) return stats.reopen[2] end, true)
            return "exq_reopen_least", { "#wound_" .. woundType }, opts, correct
        end },
        { pool = "data", gen = function()
            local pool = { "cut", "laceration", "abrasion", "avulsion", "velocity", "crush", "puncture" }
            local woundType = pool[math.random(#pool)]
            local opts, correct = BandageExtreme(woundType, function(stats) return stats.eff[1] end, false)
            return "exq_eff_best", { "#wound_" .. woundType }, opts, correct
        end },
        { pool = "data", gen = function()
            local id = EXAM_MEDS[math.random(#EXAM_MEDS)]
            local dose = KMS.Meds[id].maxDose
            local opts = {}
            for i = 1, 4 do
                opts[i] = tostring(dose + i - 2)
            end
            return "exq_maxdose", { "#item_" .. id }, opts, 2
        end },
        { pool = "data", gen = function()
            return "exq_hr_up", {}, MedOptions(), MedExtreme(function(def) return def.hr[1][1] end, true)
        end },
        { pool = "data", gen = function()
            return "exq_pain_strong", {}, MedOptions(), MedExtreme(function(def) return def.painReduce end, true)
        end },
        { pool = "doctrine", gen = function()
            return "exq_hr_down", {}, MedOptions(), 3
        end },
        { pool = "doctrine", gen = function()
            return "exq_tq_iv", {}, { "#btn_yes", "#btn_no" }, 1
        end },
        { pool = "doctrine", gen = function()
            return "exq_cpr_when", {}, { "#st_arrest", "#st_unconscious", "#ov_severe_pain", "#blood_3" }, 1
        end },
        { pool = "doctrine", gen = function()
            return "exq_triage_first", {}, { "#triage_t1", "#triage_t2", "#triage_t3", "#triage_t4" }, 1
        end },
        { pool = "doctrine", gen = function()
            return "exq_perm_close", {}, { "#treat_surgical", "#treat_bandage_elastic", "#treat_tourniquet", "#treat_bandage_quickclot" }, 1
        end },
        { pool = "doctrine", gen = function()
            return "exq_fracture", {}, { "#treat_splint", "#treat_bandage_field", "#treat_morphine", "#treat_cpr" }, 1
        end },
        { pool = "doctrine", gen = function()
            return "exq_tq_where", {}, { "#part_leg_r", "#part_torso", "#part_head" }, 1
        end },
        { pool = "doctrine", gen = function()
            return "exq_overdose", {}, { "#btn_yes", "#btn_no" }, 1
        end },
        { pool = "doctrine", gen = function()
            return "exq_wake", {}, { "#st_stable", "#st_arrest", "#ov_severe_pain", "#blood_4" }, 1
        end },
    }
    return EXAM_BANK
end

local function ComposeQuestion(gen)
    local key, args, options, correct = gen()
    local order = {}
    for i = 1, #options do order[i] = i end
    ExamShuffle(order)
    local shuffled, correctIdx = {}, 1
    for pos, src in ipairs(order) do
        shuffled[pos] = options[src]
        if src == correct then correctIdx = pos end
    end
    return { k = key, a = args, opts = shuffled, correct = correctIdx }
end

local function SendExamQuestion(ply, exam, npc)
    exam.index = exam.index + 1
    local question = exam.questions[exam.index]
    exam.deadline = npc.examSeconds > 0 and (CurTime() + npc.examSeconds) or nil
    KF.Net.Send("KMS_ExamQ", function()
        net.WriteUInt(exam.index, 5)
        net.WriteUInt(#exam.questions, 5)
        net.WriteString(question.k)
        net.WriteUInt(#question.a, 3)
        for _, arg in ipairs(question.a) do
            net.WriteString(tostring(arg))
        end
        net.WriteUInt(#question.opts, 3)
        for _, opt in ipairs(question.opts) do
            net.WriteString(tostring(opt))
        end
        net.WriteUInt(npc.examSeconds, 8)
    end, ply)
end

local function ResolveJob(value)
    if not istable(RPExtraTeams) then return nil end
    local wanted = string.lower(value)
    for teamId, job in pairs(RPExtraTeams) do
        if string.lower(job.command or "") == wanted or string.lower(job.name or "") == wanted then
            return teamId
        end
    end
    return nil
end

local function RunRewardCommand(ply, value)
    local args = string.Explode(" ", value)
    local command = table.remove(args, 1)
    if not command or command == "" then return false end
    for i, arg in ipairs(args) do
        arg = string.Replace(arg, "{steamid64}", ply:SteamID64() or "")
        arg = string.Replace(arg, "{steamid}", ply:SteamID())
        arg = string.Replace(arg, "{userid}", tostring(ply:UserID()))
        args[i] = string.Replace(arg, "{nick}", ply:Nick())
    end
    RunConsoleCommand(command, unpack(args))
    return true
end

local function GrantExamReward(ply, npc)
    local value = npc.rewardValue or ""
    if npc.rewardType == "usergroup" then
        if value == "" then return false end
        local previous = ply:GetUserGroup()
        if previous == value then return true end
        ply:SetUserGroup(value)
        if CAMI then CAMI.SignalUserGroupChanged(ply, previous, value, AID) end
        return true
    end
    if npc.rewardType == "job" then
        local teamId = ResolveJob(value)
        if not teamId or not ply.changeTeam then return false end
        return ply:changeTeam(teamId, true, true) ~= false
    end
    if npc.rewardType == "command" then
        return RunRewardCommand(ply, value)
    end
    local record = KMS.PlayerRecord(ply)
    if record.tier < npc.examTier then
        record.tier = npc.examTier
        KMS.SavePlayer(ply)
        KMS.ClearAccessCache(ply)
        KMS.SyncSelf(ply)
        KMS.MarkDirty(ply)
    end
    return true
end

local function FinishExam(ply, exam, npc)
    ply.KMSExam = nil
    local pct = math.Round(exam.right / #exam.questions * 100)
    local passed = pct >= npc.examPass
    KF.Net.Send("KMS_ExamQ", function()
        net.WriteUInt(0, 5)
        net.WriteBool(passed)
        net.WriteUInt(pct, 7)
        net.WriteUInt(npc.examPass, 7)
        net.WriteString(npc.rewardType == "tier" and ("#tier_" .. npc.examTier) or npc.rewardValue)
    end, ply)
    if not passed then return end
    if not GrantExamReward(ply, npc) then
        KMS.Notify(ply, "error", "exam_reward_failed")
        KMS.Log("warn", string.format("%s [%s] passed exam '%s' but the %s reward '%s' could not be granted",
            ply:Nick(), ply:SteamID(), npc.id, npc.rewardType, npc.rewardValue))
        return
    end
    KMS.Log("info", string.format("%s [%s] passed exam '%s' -> %s '%s'",
        ply:Nick(), ply:SteamID(), npc.id, npc.rewardType, npc.rewardType == "tier" and npc.examTier or npc.rewardValue))
end

local EXAM_GRACE = 1

local function AdvanceExam(ply, exam, npc)
    if exam.index >= #exam.questions then
        FinishExam(ply, exam, npc)
    else
        SendExamQuestion(ply, exam, npc)
    end
end

function KMS.TickExam(ply)
    local exam = ply.KMSExam
    if not exam or not exam.deadline or CurTime() < exam.deadline + EXAM_GRACE then return end
    local npc = KMS.NPCs[exam.npcId]
    if not npc then
        ply.KMSExam = nil
        return
    end
    AdvanceExam(ply, exam, npc)
end

function KMS.StartExam(ent, npc, ply)
    local active = ply.KMSExam
    if active and CurTime() - (active.touched or 0) < 300 then
        KMS.Notify(ply, "warn", "exam_busy")
        return
    end
    if not ply.KMSState.conscious then return end
    if npc.rewardType == "tier" and KMS.WhitelistTier(ply) >= npc.examTier then
        KMS.Notify(ply, "info", "exam_already")
        return
    end
    local record = KMS.PlayerRecord(ply)
    local readyAt = record.exams[npc.id] or 0
    if readyAt > os.time() then
        KMS.Notify(ply, "warn", "exam_cd", KF.FormatTime(readyAt - os.time()))
        return
    end
    local preferred = npc.examDifficulty == "hard" and "data" or "doctrine"
    local mixed = npc.examDifficulty == "medium"
    local pool, rest = {}, {}
    for _, entry in ipairs(BuildExamBank()) do
        local list = (mixed or entry.pool == preferred) and pool or rest
        list[#list + 1] = entry
    end
    ExamShuffle(pool)
    ExamShuffle(rest)
    for _, entry in ipairs(rest) do pool[#pool + 1] = entry end
    local questions = {}
    for i = 1, math.min(npc.examQuestions, #pool) do
        questions[i] = ComposeQuestion(pool[i].gen)
    end
    if #questions == 0 then return end
    record.exams[npc.id] = os.time() + npc.examCooldown
    KMS.SavePlayer(ply)
    ply.KMSExam = { npcId = npc.id, ent = ent, questions = questions, index = 0, right = 0, touched = CurTime() }
    SendExamQuestion(ply, ply.KMSExam, npc)
end

KF.Net.Receive("KMS_ExamAnswer", function(_, ply)
    local qIndex = net.ReadUInt(5)
    local idx = net.ReadUInt(3)
    local exam = ply.KMSExam
    if not exam then return end
    local npc = KMS.NPCs[exam.npcId]
    if not npc then
        ply.KMSExam = nil
        return
    end
    if idx == 0 then
        ply.KMSExam = nil
        KMS.Notify(ply, "warn", "exam_abandoned")
        return
    end
    if not ply:Alive() or not ply.KMSState.conscious or not IsValid(exam.ent) then
        ply.KMSExam = nil
        KMS.Notify(ply, "warn", "exam_abandoned")
        return
    end
    local question = exam.questions[exam.index]
    if not question or qIndex ~= exam.index or idx > #question.opts then return end
    exam.touched = CurTime()
    if idx == question.correct then
        exam.right = exam.right + 1
    end
    AdvanceExam(ply, exam, npc)
end, { rateLimit = 0.15 })

