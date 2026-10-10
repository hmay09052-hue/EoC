FCR = FCR or {}
FCR.Net = FCR.Net or {}
FCR.Session = FCR.Session or {}
FCR.Phases = FCR.Phases or {}

local C = FCR.Config
local Util = FCR.Util
local Session = FCR.Session

util.AddNetworkString("fcr_open")
util.AddNetworkString("fcr_event")
util.AddNetworkString("fcr_input")

Session.ActiveByPlayer = Session.ActiveByPlayer or {}
Session.ActiveByVehicle = Session.ActiveByVehicle or {}
Session.IdCounter = Session.IdCounter or 0

local function sendEvent(ply, eventName, payload)
    if not IsValid(ply) then return end
    net.Start("fcr_event")
        net.WriteString(eventName)
        net.WriteString(util.TableToJSON(payload or {}, false, true) or "{}")
    net.Send(ply)
end

local function sendOpen(ply, payload)
    if not IsValid(ply) then return end
    net.Start("fcr_open")
        net.WriteString(util.TableToJSON(payload or {}, false, true) or "{}")
    net.Send(ply)
end

local function logSession(session, eventName, detail)
    if not session then return end

    session.log = session.log or {}
    session.log[#session.log + 1] = {
        t = CurTime(),
        event = eventName,
        phase = session.phase or 0,
        attempts = session.attemptsLeft or 0,
        detail = detail or ""
    }

    if C.Debug then
        local prefix = string.format("[FCR][%s][P%s][A%s]", tostring(session.id), tostring(session.phase or 0), tostring(session.attemptsLeft or 0))
        print(prefix .. " " .. eventName .. (detail and detail ~= "" and (" :: " .. tostring(detail)) or ""))
    end
end

local function compactVehicleData(ent)
    local current, max = Util.GetVehicleHealth(ent)
    return {
        entIndex = IsValid(ent) and ent:EntIndex() or -1,
        label = Util.GetVehicleLabel(ent),
        health = current,
        maxHealth = max,
        integrity = Util.Round((max > 0 and current / max or 0) * 100, 1)
    }
end

local function resolveDifficultyProfile(ent)
    local diff = C.Difficulty or {}
    local maxHealth = Util.GetVehicleMaxHealth(ent)
    local levels = istable(diff.Levels) and diff.Levels or nil
    local fallback = {
        Id = "medium",
        Name = FCR.GetDifficultyLabel("medium", "MEDIUM"),
        Phase1 = {},
        Phase2 = {},
        Phase3 = {}
    }

    if not diff.Enabled or not levels then
        return fallback, maxHealth
    end

    for _, level in ipairs(levels) do
        local minHealth = tonumber(level.MinHealth) or 0
        local maxBand = level.MaxHealth
        if maxBand == nil then maxBand = math.huge end
        if maxBand == math.huge or maxBand == "inf" or maxBand == "infinite" then
            maxBand = math.huge
        else
            maxBand = tonumber(maxBand) or math.huge
        end

        local isTopBand = maxBand == math.huge
        if maxHealth >= minHealth and ((isTopBand and maxHealth >= minHealth) or (maxHealth >= minHealth and maxHealth < maxBand)) then
            return level, maxHealth
        end
    end

    return fallback, maxHealth
end

local function getPhaseCfg(session, phaseKey)
    local base = table.Copy(C[phaseKey] or {})
    local profile = session and session.difficultyProfile or nil
    local override = profile and profile[phaseKey] or nil
    if istable(override) then
        table.Merge(base, override)
    end
    return base
end

local function destroySession(session, reason, sendCancel)
    if not session or session.destroyed then return end
    session.destroyed = true

    if IsValid(session.ply) and C.FreezePlayerDuringRepair then
        session.ply:Freeze(false)
    end

    if session.vehicleId then
        Session.ActiveByVehicle[session.vehicleId] = nil
    end

    if IsValid(session.ply) then
        Session.ActiveByPlayer[session.ply] = nil
        if sendCancel then
            sendEvent(session.ply, "cancelled", {
                reason = reason or "cancelled",
                attemptsLeft = session.attemptsLeft or 0,
                phase = session.phase or 0,
                vehicle = compactVehicleData(session.vehicle)
            })
        end
    end

    logSession(session, "session_end", reason or "cleanup")
    -- Schnittstelle für andere Addons (z.B. GAR Logistik): Sitzung beendet (Erfolg, Abbruch, Fehlschlag)
    hook.Run("FCR_SessionEnded", session.ply, session.vehicle, reason or "cleanup", session)
end

local function applyRepair(session)
    if not session or not IsValid(session.vehicle) then return false end
    local _, max = Util.GetVehicleHealth(session.vehicle)
    if max <= 0 then return false end
    if C.RepairToFull then
        return Util.SetVehicleHealth(session.vehicle, max)
    end
    return false
end

local function nextSessionId()
    Session.IdCounter = Session.IdCounter + 1
    return string.format("FCR-%06d-%d", Session.IdCounter, math.random(1000, 9999))
end

local function phasePayload(session)
    return {
        sessionId = session.id,
        phase = session.phase,
        attemptsLeft = session.attemptsLeft,
        vehicle = compactVehicleData(session.vehicle),
        data = session.phaseData,
        phaseName = FCR.L(session.phaseDef.nameKey or session.phaseDef.name or ""),
        instruction = FCR.L(session.phaseDef.instructionKey or session.phaseDef.instruction or "")
    }
end

local function distanceToSegment(px, py, ax, ay, bx, by)
    local abx, aby = bx - ax, by - ay
    local apx, apy = px - ax, py - ay
    local abLenSq = abx * abx + aby * aby
    if abLenSq <= 0 then
        return math.sqrt(apx * apx + apy * apy)
    end

    local t = math.Clamp((apx * abx + apy * aby) / abLenSq, 0, 1)
    local cx = ax + abx * t
    local cy = ay + aby * t
    local dx = px - cx
    local dy = py - cy
    return math.sqrt(dx * dx + dy * dy), t
end

local function buildPathPoints(session)
    local cfg = getPhaseCfg(session, "Phase1")
    local points = {}
    local yMid = cfg.AreaH * 0.5
    local step = (cfg.AreaW - cfg.StartPadding * 2) / cfg.SegmentCount
    local lastY = yMid + math.Rand(-20, 20)

    for i = 0, cfg.SegmentCount do
        local x = cfg.StartPadding + step * i
        local y
        if i == 0 or i == cfg.SegmentCount then
            y = yMid + math.Rand(-16, 16)
        else
            y = math.Clamp(lastY + math.Rand(-cfg.VerticalVariance, cfg.VerticalVariance), 84, cfg.AreaH - 84)
        end

        points[#points + 1] = { x = Util.Round(x, 2), y = Util.Round(y, 2) }
        lastY = y
    end

    return points, cfg
end

local function buildPhase2Nodes(session)
    local cfg = getPhaseCfg(session, "Phase2")
    local nodes = {}

    for number = 1, cfg.NodeCount do
        local placed = false
        local tries = 0
        while not placed and tries < 420 do
            tries = tries + 1
            local x = math.Rand(cfg.Padding, cfg.AreaW - cfg.Padding)
            local y = math.Rand(cfg.Padding, cfg.AreaH - cfg.Padding)
            local ok = true
            for _, node in ipairs(nodes) do
                if math.Distance(x, y, node.x, node.y) < cfg.MinSpacing then
                    ok = false
                    break
                end
            end

            if ok then
                nodes[#nodes + 1] = {
                    seq = number,
                    x = Util.Round(x, 2),
                    y = Util.Round(y, 2)
                }
                placed = true
            end
        end
    end

    return nodes, cfg
end

local function buildPhase3Points(session)
    local cfg = getPhaseCfg(session, "Phase3")
    local points = {}

    for i = 1, cfg.PointCount do
        local placed = false
        local attempts = 0
        while not placed and attempts < 320 do
            attempts = attempts + 1
            local x = math.Rand(cfg.SpawnPadding, cfg.AreaW - cfg.SpawnPadding)
            local y = math.Rand(cfg.SpawnPadding, cfg.AreaH - cfg.SpawnPadding)
            local ok = true
            for _, point in ipairs(points) do
                if math.Distance(x, y, point.x, point.y) < cfg.Radius * 2.2 then
                    ok = false
                    break
                end
            end

            if ok then
                points[#points + 1] = { x = Util.Round(x, 2), y = Util.Round(y, 2) }
                placed = true
            end
        end
    end

    return points, cfg
end

local function completeRepair(session)
    logSession(session, "success_final", "repair_complete")

    if applyRepair(session) then
        sendEvent(session.ply, "success", {
            sessionId = session.id,
            vehicle = compactVehicleData(session.vehicle)
        })
        session.ply:EmitSound(C.Sounds.Success)
        -- Schnittstelle: Reparatur erfolgreich abgeschlossen
        hook.Run("FCR_RepairCompleted", session.ply, session.vehicle, session)
    else
        sendEvent(session.ply, "cancelled", {
            reason = "repair_apply_failed",
            attemptsLeft = session.attemptsLeft,
            phase = session.phase,
            vehicle = compactVehicleData(session.vehicle)
        })
    end

    destroySession(session, "success_cleanup", false)
end

local function startPhase(session, phaseId)
    if not session or session.destroyed then return end

    local def = FCR.Phases[phaseId]
    if not def then return end

    session.phase = phaseId
    session.phaseDef = def
    session.phaseStartedAt = CurTime()
    session.phaseState = {}
    session.transitionPending = false
    session.phaseData = def:Build(session)
    session.failPending = false

    logSession(session, "phase_start", def.nameKey or tostring(phaseId))
    sendEvent(session.ply, "phase", phasePayload(session))
    session.ply:EmitSound(phaseId == 1 and C.Sounds.Start or C.Sounds.PhaseAdvance)
end

local function failPhase(session, reason)
    if not session or session.destroyed or session.failPending then return end
    session.failPending = true
    session.transitionPending = false

    session.failures = (session.failures or 0) + 1
    if C.ConsumeAttemptOnPhaseFailure then
        session.attemptsLeft = math.max(0, (session.attemptsLeft or 0) - 1)
    end

    session.restarts = (session.restarts or 0) + 1
    logSession(session, "phase_fail", reason)

    session.ply:EmitSound(C.Sounds.Failure)
    sendEvent(session.ply, "phase_fail", {
        reason = reason,
        attemptsLeft = session.attemptsLeft,
        phase = session.phase,
        vehicle = compactVehicleData(session.vehicle)
    })

    if session.attemptsLeft <= 0 then
        destroySession(session, "attempts_exhausted", true)
        return
    end

    timer.Simple(C.ResetDelay, function()
        if not session or session.destroyed then return end
        startPhase(session, session.phase)
    end)
end

local function completePhase(session)
    if not session or session.destroyed or session.transitionPending then return end

    logSession(session, "phase_complete", tostring(session.phase))

    if session.phase >= 3 then
        session.transitionPending = true
        completeRepair(session)
        return
    end

    local finishedPhase = session.phase
    local nextPhase = finishedPhase + 1
    session.transitionPending = true

    sendEvent(session.ply, "phase_complete", {
        phase = finishedPhase,
        nextPhase = nextPhase,
        attemptsLeft = session.attemptsLeft,
        vehicle = compactVehicleData(session.vehicle)
    })

    timer.Simple(0.36, function()
        if not session or session.destroyed then return end
        if session.phase ~= finishedPhase then return end
        if not session.transitionPending then return end
        startPhase(session, nextPhase)
    end)
end

FCR.Phases[1] = {
    nameKey = "phase1_title",
    instructionKey = "phase1_instruction",
    Build = function(self, session)
        local points, cfg = buildPathPoints(session)
        session.phaseState.progress = 1
        session.phaseState.lastSampleAt = 0
        return {
            areaW = cfg.AreaW,
            areaH = cfg.AreaH,
            safeRadius = cfg.SafeRadius,
            maxDeviation = cfg.MaxDeviation,
            finishRadius = cfg.FinishRadius,
            points = points,
            difficultyId = session.difficultyProfile and session.difficultyProfile.Id or "medium",
            difficultyName = FCR.GetDifficultyLabel(session.difficultyProfile and session.difficultyProfile.Id or "medium", session.difficultyProfile and session.difficultyProfile.Name or "MEDIUM")
        }
    end,
    Validate = function(self, session, payload, kind)
        if kind == "release" then
            failPhase(session, "phase1_hold_lost")
            return
        end

        if not payload or payload.hold ~= true then return end

        local now = CurTime()
        local cfg = getPhaseCfg(session, "Phase1")
        if now - (session.phaseState.lastSampleAt or 0) < cfg.SampleInterval then return end
        session.phaseState.lastSampleAt = now

        local x = math.Clamp(tonumber(payload.x) or 0, 0, cfg.AreaW)
        local y = math.Clamp(tonumber(payload.y) or 0, 0, cfg.AreaH)
        local points = session.phaseData.points
        local progress = math.Clamp(session.phaseState.progress or 1, 1, #points - 1)

        local a = points[progress]
        local b = points[progress + 1]
        local dist = distanceToSegment(x, y, a.x, a.y, b.x, b.y)
        local maxDeviation = session.phaseData.maxDeviation or cfg.MaxDeviation
        if dist > maxDeviation then
            failPhase(session, "phase1_out_of_channel")
            return
        end

        local safeRadius = session.phaseData.safeRadius or cfg.SafeRadius
        if math.Distance(x, y, b.x, b.y) <= safeRadius then
            session.phaseState.progress = progress + 1
            sendEvent(session.ply, "phase1_progress", { progress = session.phaseState.progress })
            if session.phaseState.progress >= #points then
                completePhase(session)
            end
        end
    end
}

FCR.Phases[2] = {
    nameKey = "phase2_title",
    instructionKey = "phase2_instruction",
    Build = function(self, session)
        local nodes, cfg = buildPhase2Nodes(session)
        session.phaseState.expected = 1
        session.phaseState.unlockAt = CurTime() + (tonumber(cfg.StartInputLock) or 0.28)
        session.phaseState.nextInputAt = 0
        return {
            areaW = cfg.AreaW,
            areaH = cfg.AreaH,
            radius = cfg.NodeRadius,
            nodes = nodes,
            inputLock = tonumber(cfg.StartInputLock) or 0.28,
            inputCooldown = tonumber(cfg.InputCooldown) or 0.10,
            trollEnabled = cfg.TrollEnabled == true,
            trollChance = tonumber(cfg.TrollChance) or 0,
            trollMinInterval = tonumber(cfg.TrollMinInterval) or 0.95,
            trollMaxInterval = tonumber(cfg.TrollMaxInterval) or 1.75,
            trollDuration = tonumber(cfg.TrollDuration) or 0.78,
            difficultyId = session.difficultyProfile and session.difficultyProfile.Id or "medium",
            difficultyName = FCR.GetDifficultyLabel(session.difficultyProfile and session.difficultyProfile.Id or "medium", session.difficultyProfile and session.difficultyProfile.Name or "MEDIUM")
        }
    end,
    Validate = function(self, session, payload)
        local seq = tonumber(payload and payload.seq)
        if not seq then return end

        local now = CurTime()
        if now < (session.phaseState.unlockAt or 0) then return end
        if now < (session.phaseState.nextInputAt or 0) then return end
        session.phaseState.nextInputAt = now + (tonumber(session.phaseData and session.phaseData.inputCooldown) or 0.10)

        if seq ~= session.phaseState.expected then
            failPhase(session, "phase2_wrong_node")
            return
        end

        session.phaseState.expected = session.phaseState.expected + 1
        sendEvent(session.ply, "phase2_progress", {
            expected = session.phaseState.expected,
            done = seq
        })

        if session.phaseState.expected > #session.phaseData.nodes then
            completePhase(session)
        end
    end
}

FCR.Phases[3] = {
    nameKey = "phase3_title",
    instructionKey = "phase3_instruction",
    Build = function(self, session)
        local points, cfg = buildPhase3Points(session)
        session.phaseState.current = 1
        session.phaseState.expiresAt = CurTime() + cfg.PointLifetime
        return {
            areaW = cfg.AreaW,
            areaH = cfg.AreaH,
            radius = cfg.Radius,
            pointLifetime = cfg.PointLifetime,
            currentIndex = 1,
            points = points,
            difficultyId = session.difficultyProfile and session.difficultyProfile.Id or "medium",
            difficultyName = FCR.GetDifficultyLabel(session.difficultyProfile and session.difficultyProfile.Id or "medium", session.difficultyProfile and session.difficultyProfile.Name or "MEDIUM")
        }
    end,
    Validate = function(self, session, payload)
        local idx = tonumber(payload and payload.index)
        if not idx then return end
        if idx ~= session.phaseState.current then return end
        if CurTime() > (session.phaseState.expiresAt or 0) then
            failPhase(session, "phase3_timeout")
            return
        end

        local point = session.phaseData.points[idx]
        if not point then return end

        local cfg = getPhaseCfg(session, "Phase3")
        local x = math.Clamp(tonumber(payload.x) or 0, 0, cfg.AreaW)
        local y = math.Clamp(tonumber(payload.y) or 0, 0, cfg.AreaH)
        local radius = session.phaseData.radius or cfg.Radius
        if math.Distance(x, y, point.x, point.y) > radius * 1.08 then
            failPhase(session, "phase3_bad_click")
            return
        end

        session.phaseState.current = session.phaseState.current + 1
        if session.phaseState.current > #session.phaseData.points then
            completePhase(session)
            return
        end

        local pointLifetime = session.phaseData.pointLifetime or cfg.PointLifetime
        session.phaseState.expiresAt = CurTime() + pointLifetime
        sendEvent(session.ply, "phase3_progress", {
            currentIndex = session.phaseState.current,
            pointLifetime = pointLifetime
        })
    end
}

function Session.TryBegin(ply, weapon)
    local allowed, failReason = Util.CanPlayerUse(ply)
    if not allowed then
        if IsValid(ply) then ply:EmitSound(C.Sounds.Invalid) end
        return false, failReason
    end

    if Session.ActiveByPlayer[ply] then
        return false, "session_active"
    end

    local tr = Util.GetTargetTrace(ply, (C.RepairDistance or 0) + (C.RepairRangeGrace or 0))
    local ent = Util.ResolveRepairEntity(tr.Entity)
    if not Util.IsRepairTarget(ent) then
        if IsValid(ply) then ply:EmitSound(C.Sounds.Invalid) end
        return false, "target_invalid"
    end

    local vehicleId = ent:EntIndex()
    if C.SessionLockPerVehicle and Session.ActiveByVehicle[vehicleId] then
        if IsValid(ply) then ply:EmitSound(C.Sounds.Invalid) end
        return false, "vehicle_locked"
    end

    -- Schnittstelle: andere Addons können den Start verhindern (Berechtigung, Ersatzteile, ...)
    local hookOk, hookReason = hook.Run("FCR_CanBegin", ply, ent, weapon)
    if hookOk == false then
        if IsValid(ply) then ply:EmitSound(C.Sounds.Invalid) end
        return false, hookReason or "blocked"
    end

    local difficultyProfile, baseHealth = resolveDifficultyProfile(ent)
    local hpBefore, hpMax = Util.GetVehicleHealth(ent)

    local session = {
        id = nextSessionId(),
        ply = ply,
        weapon = weapon,
        vehicle = ent,
        vehicleId = vehicleId,
        attemptsLeft = C.MaxAttempts,
        failures = 0,
        restarts = 0,
        cancellations = 0,
        phase = 1,
        log = {},
        difficultyProfile = difficultyProfile,
        vehicleBaseHealth = baseHealth,
        hpBefore = hpBefore,
        hpMax = hpMax
    }

    Session.ActiveByPlayer[ply] = session
    Session.ActiveByVehicle[vehicleId] = session

    if C.FreezePlayerDuringRepair then
        ply:Freeze(true)
    end

    logSession(session, "session_start", string.format("%s | diff=%s | base=%s", Util.GetVehicleLabel(ent), tostring(difficultyProfile and difficultyProfile.Id or "medium"), tostring(baseHealth or 0)))
    sendOpen(ply, {
        sessionId = session.id,
        systemName = C.SystemName or FCR.L("system_name"),
        attemptsLeft = session.attemptsLeft,
        maxAttempts = C.MaxAttempts,
        totalPhases = 3,
        vehicle = compactVehicleData(ent),
        difficulty = {
            id = difficultyProfile and difficultyProfile.Id or "medium",
            name = FCR.GetDifficultyLabel(difficultyProfile and difficultyProfile.Id or "medium", difficultyProfile and difficultyProfile.Name or "MEDIUM"),
            baseHealth = baseHealth or 0
        }
    })

    startPhase(session, 1)
    return true
end

function Session.CancelByPlayer(ply, reason)
    local session = Session.ActiveByPlayer[ply]
    if not session then return end
    session.cancellations = (session.cancellations or 0) + 1
    logSession(session, "cancelled", reason or "user_cancel")
    if IsValid(session.ply) then
        session.ply:EmitSound(C.Sounds.Cancel)
    end
    destroySession(session, reason or "user_cancel", true)
end

timer.Create("FCR.SessionMonitor", C.MonitorInterval, 0, function()
    for ply, session in pairs(Session.ActiveByPlayer) do
        if not session or session.destroyed then
            Session.ActiveByPlayer[ply] = nil
            continue
        end

        local ok, reason = Util.SessionStillValid(session)
        if not ok then
            logSession(session, "monitor_cancel", reason)
            destroySession(session, reason, true)
            continue
        end

        if session.phase == 3 and not session.failPending and CurTime() > (session.phaseState.expiresAt or 0) then
            failPhase(session, "phase3_timeout")
        end
    end
end)

net.Receive("fcr_input", function(_, ply)
    local kind = net.ReadString()
    local json = net.ReadString()
    local payload = util.JSONToTable(json or "{}") or {}
    local session = Session.ActiveByPlayer[ply]
    if not session or session.destroyed then return end
    if payload.sessionId ~= session.id then return end

    local ok, reason = Util.SessionStillValid(session)
    if not ok then
        logSession(session, "input_cancel", reason)
        destroySession(session, reason, true)
        return
    end

    if kind == "cancel" then
        Session.CancelByPlayer(ply, "user_cancel")
        return
    end

    if session.failPending or session.transitionPending then return end

    if kind == "phase1_sample" and session.phase == 1 then
        FCR.Phases[1]:Validate(session, payload, "sample")
    elseif kind == "phase1_release" and session.phase == 1 then
        FCR.Phases[1]:Validate(session, payload, "release")
    elseif kind == "phase2_click" and session.phase == 2 then
        FCR.Phases[2]:Validate(session, payload)
    elseif kind == "phase3_click" and session.phase == 3 then
        FCR.Phases[3]:Validate(session, payload)
    end
end)
