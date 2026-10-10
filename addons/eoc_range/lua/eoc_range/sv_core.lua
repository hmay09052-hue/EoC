--[[
    EoC Range – Läufe, Wertung, Anti-Cheat
    Der Server misst alles selbst; der Client zeigt nur an.
]]

local C = EoCRange.Config
local DB = EoCRange.DB

EoCRange.Runs       = EoCRange.Runs or {}        -- id -> Lauf
EoCRange.LaneRuns   = EoCRange.LaneRuns or {}    -- Bahn -> Lauf
EoCRange.PlayerRuns = EoCRange.PlayerRuns or {}  -- Spieler -> Lauf
EoCRange.Lanes      = EoCRange.Lanes or {}       -- Bahn -> { locked, lockReason, lockedBy, reserved, reservedName, exam }

local nextRunId = 0

function EoCRange.LaneBusy(lane)
    return EoCRange.LaneRuns[lane] ~= nil
end

function EoCRange.LaneInfo(lane)
    local l = EoCRange.Lanes[lane]
    if not l then
        l = {}
        EoCRange.Lanes[lane] = l
    end
    return l
end

---------------------------------------------------------------------------
-- Terminal-Anzeige (NW2 auf dem Terminal, das Hologramm liest sie)
---------------------------------------------------------------------------
function EoCRange.UpdateLaneDisplay(lane)
    local term = EoCRange.TerminalForLane(lane)
    if not IsValid(term) then return end
    local info = EoCRange.LaneInfo(lane)
    local locked, lvl = EoCRange.DefconLocked()
    local state, note = "free", ""
    if locked then
        state, note = "defcon", "DEFCON " .. lvl
    elseif info.locked then
        state, note = "locked", info.lockReason or ""
    elseif EoCRange.LaneRuns[lane] then
        state = "busy"
    elseif info.exam then
        state, note = "exam", info.examBy or ""
    elseif info.reserved then
        state, note = "reserved", info.reservedName or ""
    end
    term:SetNW2String("EoCR_Lane", state)
    term:SetNW2String("EoCR_LaneNote", note)
end

function EoCRange.UpdateAllLaneDisplays()
    for _, t in ipairs(EoCRange.Terminals()) do EoCRange.UpdateLaneDisplay(t:GetLane()) end
end

local function SetTermRun(run, state)
    local term = run.terminal
    if not IsValid(term) then return end
    term:SetNW2String("EoCR_State", state)
    term:SetNW2String("EoCR_Disc", run.def.name)
    term:SetNW2String("EoCR_Shooter", run.shooterName or "")
    term:SetNW2Float("EoCR_T0", run.t0 or run.startAt or 0)
    term:SetNW2Float("EoCR_StartAt", run.startAt or 0)
end

-- Schützen plus beobachtender Prüfer
local function Watchers(run)
    local out, seen = {}, {}
    for _, p in ipairs(run.players) do
        if IsValid(p) and not seen[p] then
            seen[p] = true
            out[#out + 1] = p
        end
    end
    local inst = run.exam and run.exam.instructor
    if IsValid(inst) and not seen[inst] then out[#out + 1] = inst end
    return out
end
EoCRange.RunWatchers = Watchers

local function LiveUpdate(run)
    local term = run.terminal
    local live = EoCRange.LiveValue(run)
    if IsValid(term) then
        term:SetNW2String("EoCR_Live", live)
        term:SetNW2Int("EoCR_Hits", run.kills)
        term:SetNW2Int("EoCR_Shots", run.shots)
    end
    EoCRange.Send("live", { live = live, hits = run.kills, shots = run.shots, shotHits = run.shotHits, state = run.state }, Watchers(run))
end

---------------------------------------------------------------------------
-- Zonen
---------------------------------------------------------------------------
local function Zones(lane, kind)
    local out = {}
    for _, e in ipairs(ents.FindByClass("range_*")) do
        if e.IsRangeZone and e:GetLane() == lane and (not kind or e.RangeKind == kind) then out[#out + 1] = e end
    end
    return out
end

function EoCRange.InZone(ply, lane, kind)
    local pos = ply:GetPos()
    for _, z in ipairs(Zones(lane, kind)) do
        if z:Contains(pos) then return true end
    end
    return false
end

-- Im Bereich der Bahn (Bahn-, Start- oder Zielzone). Ohne Zonen: Nähe zum Terminal.
function EoCRange.InLaneArea(ply, lane)
    if #Zones(lane) == 0 then
        local term = EoCRange.TerminalForLane(lane)
        return IsValid(term) and ply:GetPos():Distance(term:GetPos()) <= C.NoZoneRadius
    end
    return EoCRange.InZone(ply, lane)
end

---------------------------------------------------------------------------
-- Ziele einer Bahn
---------------------------------------------------------------------------
local function Targets(lane, kind)
    return EoCRange.LaneEnts(lane, kind)
end

-- Nach dem Lauf: alles wieder aufstellen. Einschusslöcher bleiben bis zum Ablauf sichtbar.
local function ResetLane(lane)
    for _, e in ipairs(EoCRange.LaneEnts(lane)) do
        if e.StopMoving then e:StopMoving() end
        if e.Raise then e:Raise(true) end
    end
end
EoCRange.ResetLane = ResetLane

local function LowerAll(lane)
    for _, e in ipairs(EoCRange.LaneEnts(lane)) do
        if e.StopMoving then e:StopMoving() end
        if e.Lower then e:Lower() end
    end
    EoCRange.Send("clearholes", { lane = lane })
end

---------------------------------------------------------------------------
-- Start-Prüfung
---------------------------------------------------------------------------
local function WeaponOK(p, def)
    local w = p:GetActiveWeapon()
    return IsValid(w) and EoCRange.IsWeaponAllowed(def, w:GetClass())
end

local function ModeRequirements(def, lane)
    if def.mode == "rings" then
        if #Targets(lane, "rings") == 0 then return false, "Auf dieser Bahn steht keine Zielscheibe." end
    elseif def.mode == "sequence" or def.mode == "all" or def.mode == "parcours" then
        if #Targets(lane, "popup") == 0 then return false, "Auf dieser Bahn stehen keine Klappziele." end
    elseif def.mode == "moving" then
        if #Targets(lane, "mover") == 0 then return false, "Auf dieser Bahn gibt es keine bewegten Ziele." end
    end
    if def.mode == "parcours" and (#Zones(lane, "start") == 0 or #Zones(lane, "finish") == 0) then
        return false, "Für den Parcours fehlen Start- oder Zielzone (Parcours-Nr. = Bahn-Nr.)."
    end
    return true
end

function EoCRange.CanStart(ply, terminal, def, shooters, opts)
    opts = opts or {}
    if not def then return false, "Unbekannte Disziplin." end
    local lane = terminal:GetLane()
    if not terminal:Allows(def.id) then return false, "Diese Disziplin ist an dieser Bahn nicht freigegeben." end

    local locked, lvl = EoCRange.DefconLocked()
    if locked then return false, "Gefechtsbereitschaft (DEFCON " .. lvl .. ") – der Schießstand ist gesperrt." end

    local hookOk, hookReason = hook.Run("EoCRange_CanStart", ply, lane, def.id)
    if hookOk == false then return false, hookReason or "Start nicht erlaubt." end

    if EoCRange.LaneRuns[lane] then return false, "Die Bahn ist gerade belegt." end
    local info = EoCRange.LaneInfo(lane)
    if info.locked and not EoCRange.IsAdmin(ply) then
        return false, "Bahn gesperrt" .. ((info.lockReason and info.lockReason ~= "") and (": " .. info.lockReason) or ".")
    end
    if info.exam and not opts.exam then return false, "Auf dieser Bahn läuft gerade eine Prüfung." end
    if info.reserved and not opts.exam and info.reserved ~= ply:SteamID() and not EoCRange.IsAdmin(ply) then
        return false, "Bahn reserviert für " .. (info.reservedName or "einen Ausbilder") .. "."
    end

    local ok, why = ModeRequirements(def, lane)
    if not ok then return false, why end

    for _, p in ipairs(shooters) do
        local name = p == ply and "Du" or p:Nick()
        if EoCRange.PlayerRuns[p] then return false, name .. (p == ply and " hast" or " hat") .. " bereits einen Lauf." end
        if not p:Alive() then return false, name .. " – nicht am Leben." end
        if p:GetMoveType() == MOVETYPE_NOCLIP then return false, "Kein Lauf im Noclip." end
        if not EoCRange.InLaneArea(p, lane) then
            return false, (p == ply and "Du stehst" or (p:Nick() .. " steht")) .. " nicht in der Bahnzone von Bahn " .. lane .. "."
        end
        if def.mode == "parcours" and not EoCRange.InZone(p, lane, "start") then
            return false, "Für den Parcours musst du in der Startzone stehen."
        end
        if not WeaponOK(p, def) then
            return false, (p == ply and "Nimm" or (p:Nick() .. " muss")) .. " eine erlaubte Waffe in die Hand: " .. EoCRange.WeaponNames(def)
        end
    end
    return true
end

-- Squad-Lauf: Squad-Mitglieder in der Bahnzone; ohne Squad-Addon alle in der Bahnzone
local function SquadShooters(ply, lane)
    local members = EoCRange.SquadMembers(ply)
    local out = { ply }
    local pool = members or player.GetAll()
    for _, p in ipairs(pool) do
        if IsValid(p) and p ~= ply and p:Alive() and EoCRange.InLaneArea(p, lane) and not EoCRange.PlayerRuns[p] then
            out[#out + 1] = p
            if #out >= C.SquadMax then break end
        end
    end
    return out
end

---------------------------------------------------------------------------
-- Lauf starten
---------------------------------------------------------------------------
function EoCRange.StartRun(ply, terminal, discId, opts)
    opts = opts or {}
    local def = EoCRange.GetDiscipline(discId)
    if not IsValid(terminal) or not def then return false end
    local lane = terminal:GetLane()

    local shooters = { ply }
    if def.squad then
        shooters = SquadShooters(ply, lane)
        if #shooters < C.SquadMin then
            local msg = "Für den Squad-Lauf müssen mindestens " .. C.SquadMin .. " Squad-Mitglieder in der Bahnzone stehen."
            EoCRange.Notify(ply, msg, 1)
            return false, msg
        end
    end

    local ok, why = EoCRange.CanStart(ply, terminal, def, shooters, opts)
    if not ok then
        EoCRange.Notify(ply, why, 1)
        if opts.exam and IsValid(opts.exam.instructor) and opts.exam.instructor ~= ply then EoCRange.Notify(opts.exam.instructor, why, 1) end
        return false, why
    end

    nextRunId = nextRunId + 1
    local now = CurTime()
    local names = {}
    for _, p in ipairs(shooters) do names[#names + 1] = EoCRange.CharInfo(p).name end

    local run = {
        id = nextRunId, lane = lane, terminal = terminal, def = def, owner = ply, players = shooters, playerSet = {},
        shooterName = table.concat(names, ", "), state = "countdown", created = now, startAt = now + C.Countdown,
        stage = math.Clamp(math.floor(tonumber(opts.stage) or 1), 1, 3), exam = opts.exam,
        shots = 0, shotHits = 0, kills = 0, points = 0, ringHits = 0, penaltySecs = 0, penaltyPoints = 0, hostageHits = 0,
        reactions = {}, holes = {}, per = {}, respawn = {}, flagged = false,
    }
    for _, p in ipairs(shooters) do
        run.playerSet[p] = true
        local w = p:GetActiveWeapon()
        run.per[p] = { fb = 0, clip = IsValid(w) and w:Clip1() or nil, weapon = IsValid(w) and w or nil }
        EoCRange.PlayerRuns[p] = run
    end
    EoCRange.Runs[run.id] = run
    EoCRange.LaneRuns[lane] = run

    LowerAll(lane)
    SetTermRun(run, "countdown")
    EoCRange.UpdateLaneDisplay(lane)

    local payload = { state = "countdown", disc = def.id, name = def.name, startAt = run.startAt, lane = lane, scoring = def.scoring,
        mode = def.mode, shotsTotal = def.shots, count = def.count, exam = run.exam ~= nil }
    EoCRange.Send("runstate", payload, Watchers(run))
    return true
end

---------------------------------------------------------------------------
-- Hilfen für die Modi
---------------------------------------------------------------------------
local function Gap(def)
    local g = def.gap or { 0.8, 1.4 }
    return math.Rand(g[1] or 0.8, g[2] or g[1] or 1.4)
end

local function Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function Pick(pool, n, fixed)
    local out = {}
    if #pool == 0 then return out end
    if fixed then
        table.sort(pool, function(a, b) return a:GetOrder() < b:GetOrder() end)
        for i = 1, n do out[i] = pool[((i - 1) % #pool) + 1] end
        return out
    end
    local last
    for i = 1, n do
        local e = pool[math.random(#pool)]
        if #pool > 1 then
            local tries = 0
            while e == last and tries < 6 do
                e = pool[math.random(#pool)]
                tries = tries + 1
            end
        end
        out[i] = e
        last = e
    end
    return out
end

local function FilterDistance(pool, dist)
    if not dist or dist <= 0 then return pool end
    local out = {}
    for _, e in ipairs(pool) do
        if e.GetDistance and e:GetDistance() == dist then out[#out + 1] = e end
    end
    return #out > 0 and out or pool
end

local function MissValue(def)
    if def.missValue then return def.missValue end
    return def.scoring == "time" and C.MissPenaltySecs or C.MissPenaltyPoints
end

local function HostagePenalty(run, ent)
    local def = run.def
    if def.scoring == "time" then
        local v = ent.GetPenaltySecs and ent:GetPenaltySecs() > 0 and ent:GetPenaltySecs() or def.hostageValue or C.HostagePenaltySecs
        run.penaltySecs = run.penaltySecs + v
    else
        local v = ent.GetPenaltyPoints and ent:GetPenaltyPoints() > 0 and ent:GetPenaltyPoints() or def.hostageValue or C.HostagePenaltyPoints
        run.penaltyPoints = run.penaltyPoints + v
    end
    run.hostageHits = run.hostageHits + 1
    for _, p in ipairs(run.players) do
        if IsValid(p) then p:EmitSound(C.Sounds.hostage, 60, 100, 0.7) end
    end
end

-- Laufender Wert für HUD und Hologramm
function EoCRange.LiveValue(run)
    local def = run.def
    if def.mode == "rings" then return run.points .. " / " .. (def.shots * 10) end
    if def.scoring == "time" then
        local t = run.t0 and (CurTime() - run.t0) or 0
        if run.state ~= "running" then t = 0 end
        local extra = run.penaltySecs + math.max(0, run.shots - run.shotHits) * MissValue(def)
        return string.format("%.1f s", t) .. (extra > 0 and string.format(" +%d", extra) or "")
    end
    local pts = run.points - run.penaltyPoints
    if def.missPenalty then pts = pts - math.max(0, run.shots - run.shotHits) * MissValue(def) end
    return tostring(math.max(0, math.Round(pts)))
end

-- Einschussloch an alle in der Nähe
local function SendHole(ent, u, v, extra)
    local rf = RecipientFilter()
    rf:AddPVS(ent:GetPos())
    EoCRange.Send("hole", { e = ent:EntIndex(), u = math.Round(u, 3), v = math.Round(v, 3), r = extra }, rf)
end

---------------------------------------------------------------------------
-- Modi
---------------------------------------------------------------------------
local Modes = {}

-- Ringscheibe
Modes.rings = {
    begin = function(run)
        local pool = FilterDistance(Targets(run.lane, "rings"), run.def.distance)
        run.target = pool[1]
    end,
    hit = function(run, ent, p, pos)
        if ent ~= run.target then return end
        local ring, u, v = ent:Evaluate(pos)
        run.points = run.points + ring
        run.shotHits = run.shotHits + 1
        if ring > 0 then
            run.ringHits = run.ringHits + 1
            run.kills = run.ringHits
        end
        run.holes[#run.holes + 1] = { u = math.Round(u, 3), v = math.Round(v, 3), r = ring }
        SendHole(ent, u, v, ring)
    end,
    tick = function(run, now)
        if run.finishAt and now >= run.finishAt then EoCRange.FinishRun(run) end
    end,
}

-- Klappziele nacheinander
Modes.sequence = {
    begin = function(run, now)
        local def = run.def
        local pool = Targets(run.lane, "popup")
        local queue = {}
        if def.distances then
            for _, d in ipairs(def.distances) do
                for _, e in ipairs(Pick(FilterDistance(pool, d), def.perDistance or 2)) do queue[#queue + 1] = e end
            end
        else
            queue = Pick(FilterDistance(pool, def.distance), def.count or 8, def.order == "fixed")
        end
        run.queue = queue
        run.hostagePool = def.hostages and Targets(run.lane, "hostage") or {}
        run.step = 0
        run.nextAt = now + Gap(def)
        run.total = #queue
    end,
    hit = function(run, ent, p, pos)
        local def = run.def
        if ent.IsHostage then
            if not run.current or ent ~= run.current.hostage then return end
            local _, u, z = ent:Evaluate(pos)
            run.shotHits = run.shotHits + 1
            SendHole(ent, u, z)
            HostagePenalty(run, ent)
            ent:Lower()
            run.current.hostage = nil
            return
        end
        local cur = run.current
        if not cur or ent ~= cur.ent then return end
        local head, u, z = ent:Evaluate(pos)
        run.shotHits = run.shotHits + 1
        run.holes[#run.holes + 1] = { u = math.Round(u, 3), v = math.Round(z, 3), h = head and 1 or 0, s = ent:GetSilhouette() }
        SendHole(ent, u, z)
        if head then cur.head = true end
        cur.hits = (cur.hits or 0) + 1
        if cur.hits < ent:GetHitPoints() then return end

        local now = CurTime()
        local rt = now - cur.shownAt
        run.reactions[#run.reactions + 1] = rt
        if rt * 1000 < C.ReactionMinMs then run.flagged = true end
        local pts = C.PopupHitPoints * ((def.headDouble and cur.head) and C.HeadMultiplier or 1)
        if def.reactionBonus then
            pts = pts + math.Round(C.ReactionBonusMax * math.Clamp(1 - rt / (def.visible or 1.5), 0, 1))
        end
        run.points = run.points + pts
        run.kills = run.kills + 1
        ent:Lower()
        if IsValid(cur.hostage) then cur.hostage:Lower() end
        run.current = nil
        run.nextAt = now + Gap(def)
    end,
    tick = function(run, now)
        local def = run.def
        local cur = run.current
        if cur and now >= cur.untilT then
            if IsValid(cur.ent) then cur.ent:Lower() end
            if IsValid(cur.hostage) then cur.hostage:Lower() end
            run.current = nil
            run.nextAt = now + Gap(def)
        end
        if not run.current and not run.finishAt and now >= run.nextAt then
            run.step = run.step + 1
            local ent = run.queue[run.step]
            if not ent then
                run.finishAt = now + 0.4
            elseif IsValid(ent) then
                ent:Raise()
                local h
                if #run.hostagePool > 0 and math.random() < 0.35 then
                    h = run.hostagePool[math.random(#run.hostagePool)]
                    if IsValid(h) then h:Raise(true) else h = nil end
                end
                run.current = { ent = ent, shownAt = now, untilT = now + (def.visible or 1.5), hostage = h }
            else
                run.nextAt = now
            end
        end
        if run.finishAt and now >= run.finishAt then EoCRange.FinishRun(run) end
    end,
}

-- Alle Ziele gleichzeitig (Zeitlauf, Squad-Lauf, eigene "alle"-Disziplinen) und Parcours
local function AllBegin(run, now)
    run.remaining = {}
    run.remainingCount = 0
    for _, e in ipairs(Targets(run.lane, "popup")) do
        e:Raise(true)
        run.remaining[e] = true
        run.remainingCount = run.remainingCount + 1
    end
    if run.def.hostages then
        for _, h in ipairs(Targets(run.lane, "hostage")) do h:Raise(true) end
    end
    run.total = run.remainingCount
end

local function AllHit(run, ent, p, pos)
    if ent.IsHostage then
        local _, u, z = ent:Evaluate(pos)
        run.shotHits = run.shotHits + 1
        SendHole(ent, u, z)
        HostagePenalty(run, ent)
        ent:Lower()
        return
    end
    if not run.remaining or not run.remaining[ent] then return end
    local head, u, z = ent:Evaluate(pos)
    run.shotHits = run.shotHits + 1
    run.holes[#run.holes + 1] = { u = math.Round(u, 3), v = math.Round(z, 3), h = head and 1 or 0, s = ent:GetSilhouette() }
    SendHole(ent, u, z)
    ent.HitsTaken = (ent.HitsTaken or 0) + 1
    if ent.HitsTaken < ent:GetHitPoints() then return end
    run.remaining[ent] = nil
    run.remainingCount = run.remainingCount - 1
    run.kills = run.kills + 1
    run.lastKill = CurTime()
    ent:Lower()
    if run.remainingCount <= 0 and run.def.mode ~= "parcours" then EoCRange.FinishRun(run) end
end

Modes.all = {
    begin = AllBegin,
    hit = AllHit,
    tick = function(run, now)
        local limit = run.def.timeLimit or C.TimedLimit
        if now - run.t0 >= limit then
            run.timedOut = true
            EoCRange.FinishRun(run)
        end
    end,
}

Modes.parcours = {
    begin = function(run, now)
        AllBegin(run, now)
        run.state = "ready"
        run.readySince = now
    end,
    hit = AllHit,
    tick = function(run, now)
        local p = run.owner
        if run.state == "ready" then
            if not EoCRange.InZone(p, run.lane, "start") then
                run.state = "running"
                run.t0 = now
                SetTermRun(run, "running")
                EoCRange.Send("runstate", { state = "running", t0 = run.t0, disc = run.def.id, name = run.def.name, scoring = run.def.scoring, mode = "parcours" }, Watchers(run))
            elseif now - run.readySince > C.ParcoursReadyMax then
                EoCRange.FinishRun(run, true, "Startzone nicht verlassen.")
            end
            return
        end
        if EoCRange.InZone(p, run.lane, "finish") then
            run.finishedAt = now
            EoCRange.FinishRun(run)
            return
        end
        if now - run.t0 >= (run.def.timeLimit or C.TimedLimit) then
            run.timedOut = true
            EoCRange.FinishRun(run)
        end
    end,
}

-- Bewegtziele
Modes.moving = {
    begin = function(run, now)
        run.movers = Targets(run.lane, "mover")
        for _, m in ipairs(run.movers) do
            m:Raise(true)
            m:StartMoving(run.stage)
        end
        run.endAt = now + (run.def.duration or 30)
    end,
    hit = function(run, ent, p, pos)
        if ent.RangeKind ~= "mover" then return end
        local head, u, z = ent:Evaluate(pos)
        run.shotHits = run.shotHits + 1
        run.holes[#run.holes + 1] = { u = math.Round(u, 3), v = math.Round(z, 3), h = head and 1 or 0, s = ent:GetSilhouette() }
        SendHole(ent, u, z)
        ent.HitsTaken = (ent.HitsTaken or 0) + 1
        if head then ent.HeadHit = true end
        if ent.HitsTaken < ent:GetHitPoints() then return end
        local mult = C.MoverMultipliers[run.stage] or 1
        local pts = C.PopupHitPoints * ((run.def.headDouble and ent.HeadHit) and C.HeadMultiplier or 1) * mult
        run.points = run.points + math.Round(pts)
        run.kills = run.kills + 1
        ent:Lower()
        run.respawn[ent] = CurTime() + 1
    end,
    tick = function(run, now)
        for ent, t in pairs(run.respawn) do
            if now >= t then
                run.respawn[ent] = nil
                if IsValid(ent) then ent:Raise() end
            end
        end
        if now >= run.endAt then EoCRange.FinishRun(run) end
    end,
}

---------------------------------------------------------------------------
-- Treffer
---------------------------------------------------------------------------
function EoCRange.OnTargetDamage(ent, dmg)
    local att = dmg:GetAttacker()
    if IsValid(att) and att:IsWeapon() then att = att:GetOwner() end
    if not IsValid(att) or not att:IsPlayer() then return end

    local pos = dmg:GetDamagePosition()
    if pos == vector_origin then pos = att:GetEyeTrace().HitPos end
    local lane = ent:GetLane()
    local run = EoCRange.LaneRuns[lane]

    if run then
        -- Belegte Bahn: nur Treffer des Schützen zählen, alles andere wird ignoriert
        if not run.playerSet[att] or run.state ~= "running" or run.blockHits then return end
        local w = att:GetActiveWeapon()
        if not IsValid(w) or not EoCRange.IsWeaponAllowed(run.def, w:GetClass()) then return end
        local mode = Modes[run.def.mode]
        if mode and mode.hit then mode.hit(run, ent, att, pos) end
        LiveUpdate(run)
        return
    end

    -- Freies Schießen: Löcher zeigen, Klappziele fallen und stehen wieder auf
    if ent.RangeKind == "rings" then
        local ring, u, v = ent:Evaluate(pos)
        SendHole(ent, u, v, ring)
    elseif ent.Evaluate and ent.Lower then
        local _, u, z = ent:Evaluate(pos)
        SendHole(ent, u, z)
        ent.HitsTaken = (ent.HitsTaken or 0) + 1
        if ent.HitsTaken >= ent:GetHitPoints() then ent:Lower(C.PopupResetTime) end
    end
end

local function AddShots(run, p, n)
    if run.state ~= "running" then return end
    run.shots = run.shots + n
    if run.def.mode == "rings" then
        if run.shots > run.def.shots then
            run.blockHits = true
        end
        if run.shots >= run.def.shots and not run.finishAt then run.finishAt = CurTime() + 0.6 end
    end
    LiveUpdate(run)
end

-- Schüsse zählen (Fehlschüsse = Schüsse - Treffer auf Bahnziele, nur während eines aktiven Laufs)
hook.Add("EntityFireBullets", "EoCRange_Shots", function(ent)
    if IsValid(ent) and ent:IsWeapon() then ent = ent:GetOwner() end
    if not IsValid(ent) or not ent:IsPlayer() then return end
    local run = EoCRange.PlayerRuns[ent]
    if not run or run.state ~= "running" then return end
    local per = run.per[ent]
    if per then per.fb = per.fb + 1 end
    AddShots(run, ent, 1)
end)

-- Ersatzzählung über das Magazin (z. B. bei ArcCW-Physikgeschossen, die FireBullets erst beim Aufprall auslösen)
local function ClipCheck(run, p)
    local per = run.per[p]
    if not per then return end
    local w = p:GetActiveWeapon()
    if not IsValid(w) then return end
    local clip = w:Clip1()
    if per.weapon ~= w then
        per.weapon, per.clip, per.fb = w, clip, 0
        return
    end
    if per.clip and clip >= 0 and clip < per.clip then
        local extra = (per.clip - clip) - per.fb
        if extra > 0 then AddShots(run, p, extra) end
    end
    per.clip = clip
    per.fb = 0
end

---------------------------------------------------------------------------
-- Ablauf (Tick) und Abbruchgründe
---------------------------------------------------------------------------
local function AbortReason(run)
    local locked, lvl = EoCRange.DefconLocked()
    if locked then return "Gefechtsbereitschaft (DEFCON " .. lvl .. ")." end
    if not IsValid(run.terminal) then return "Terminal entfernt." end
    for _, p in ipairs(run.players) do
        if not IsValid(p) then return "Ein Schütze hat den Server verlassen." end
        if not p:Alive() then return p:Nick() .. " ist gestorben." end
        if p:GetMoveType() == MOVETYPE_NOCLIP then return "Noclip ist während eines Laufs verboten." end
        local w = p:GetActiveWeapon()
        local class = IsValid(w) and w:GetClass() or ""
        if not EoCRange.IsWeaponAllowed(run.def, class) and not EoCRange.IsHarmless(class) then
            return "Nicht erlaubte Waffe: " .. (IsValid(w) and (w:GetPrintName() or class) or class)
        end
        if not EoCRange.InLaneArea(p, run.lane) then
            return #run.players > 1 and (p:Nick() .. " hat die Bahnzone verlassen.") or "Bahnzone verlassen."
        end
    end
    if CurTime() - run.created > C.MaxRunTime + C.Countdown + C.ParcoursReadyMax then return "Zeitüberschreitung." end
end

local function Begin(run, now)
    run.state = "running"
    run.t0 = now
    local mode = Modes[run.def.mode]
    if mode and mode.begin then mode.begin(run, now) end
    SetTermRun(run, run.state)
    for _, p in ipairs(run.players) do
        local per = run.per[p]
        local w = IsValid(p) and p:GetActiveWeapon()
        if per and IsValid(w) then per.weapon, per.clip, per.fb = w, w:Clip1(), 0 end
    end
    EoCRange.Send("runstate", { state = run.state, t0 = run.t0, disc = run.def.id, name = run.def.name, scoring = run.def.scoring, mode = run.def.mode,
        shotsTotal = run.def.shots, count = run.total }, Watchers(run))
    LiveUpdate(run)
end

timer.Create("EoCRange_Tick", 0.05, 0, function()
    local now = CurTime()
    for _, run in pairs(EoCRange.Runs) do
        if not run.done then
            local why = AbortReason(run)
            if why then
                EoCRange.FinishRun(run, true, why)
            elseif run.state == "countdown" then
                if now >= run.startAt then Begin(run, now) end
            else
                for _, p in ipairs(run.players) do ClipCheck(run, p) end
                local mode = Modes[run.def.mode]
                if mode and mode.tick then mode.tick(run, now) end
                if not run.done and run.def.scoring == "time" and run.state == "running" then
                    run.nextLive = run.nextLive or 0
                    if now >= run.nextLive then
                        run.nextLive = now + 0.5
                        local term = run.terminal
                        if IsValid(term) then term:SetNW2String("EoCR_Live", EoCRange.LiveValue(run)) end
                    end
                end
            end
        end
    end
end)

-- Sofortige Abbrüche
hook.Add("PlayerDeath", "EoCRange_Abort", function(p)
    local run = EoCRange.PlayerRuns[p]
    if run then EoCRange.FinishRun(run, true, p:Nick() .. " ist gestorben.") end
end)

hook.Add("PlayerDisconnected", "EoCRange_Abort", function(p)
    local run = EoCRange.PlayerRuns[p]
    if run then EoCRange.FinishRun(run, true, "Ein Schütze hat den Server verlassen.") end
end)

hook.Add("PlayerSwitchWeapon", "EoCRange_Abort", function(p, _, new)
    local run = EoCRange.PlayerRuns[p]
    if not run or not IsValid(new) then return end
    local class = new:GetClass()
    if not EoCRange.IsWeaponAllowed(run.def, class) and not EoCRange.IsHarmless(class) then
        timer.Simple(0, function()
            if not run.done then EoCRange.FinishRun(run, true, "Waffenwechsel auf eine nicht erlaubte Waffe.") end
        end)
    end
end)

---------------------------------------------------------------------------
-- Ergebnis berechnen
---------------------------------------------------------------------------
local function Avg(list)
    if #list == 0 then return nil end
    local s = 0
    for _, v in ipairs(list) do s = s + v end
    return s / #list
end

function EoCRange.ComputeResult(run)
    local def = run.def
    local now = CurTime()
    local misses = math.max(0, run.shots - run.shotHits)
    local r = {
        disc = def.id, name = def.name, scoring = def.scoring, mode = def.mode, stage = run.stage,
        shots = run.shots, shotHits = run.shotHits, misses = misses, hostageHits = run.hostageHits,
        hits = run.kills, total = run.total, flagged = run.flagged,
        accuracy = run.shots > 0 and math.Round(math.min(run.shotHits / run.shots, 1) * 100, 1) or 0,
        react = Avg(run.reactions), holes = run.holes, lane = run.lane,
        time = math.Round(now - (run.t0 or now), 2), penalties = {},
    }

    if def.mode == "rings" then
        r.value = run.points
        r.hits = run.ringHits
        r.total = def.shots
    elseif def.scoring == "time" then
        local endT = run.finishedAt or run.lastKill or now
        if run.timedOut then endT = now end
        local t = endT - (run.t0 or endT)
        local missSecs = def.missPenalty and misses * MissValue(def) or 0
        local unhit = (run.remainingCount or 0) * C.UnhitTargetSecs
        if def.mode ~= "parcours" and not run.timedOut then unhit = 0 end
        r.rawTime = math.Round(t, 2)
        r.value = math.Round(t + missSecs + run.penaltySecs + unhit, 2)
        r.time = r.rawTime
        if missSecs > 0 then r.penalties[#r.penalties + 1] = misses .. " Fehlschüsse +" .. missSecs .. " s" end
        if run.penaltySecs > 0 then r.penalties[#r.penalties + 1] = run.hostageHits .. " Geisel +" .. run.penaltySecs .. " s" end
        if unhit > 0 then r.penalties[#r.penalties + 1] = run.remainingCount .. " Ziele offen +" .. unhit .. " s" end
    else
        local missPts = def.missPenalty and misses * MissValue(def) or 0
        r.value = math.max(0, math.Round(run.points - missPts - run.penaltyPoints))
        r.rawPoints = run.points
        if missPts > 0 then r.penalties[#r.penalties + 1] = misses .. " Fehlschüsse −" .. missPts end
        if run.penaltyPoints > 0 then r.penalties[#r.penalties + 1] = run.hostageHits .. " Geisel −" .. run.penaltyPoints end
    end
    if def.mode == "moving" then r.multiplier = C.MoverMultipliers[run.stage] end
    return r
end

---------------------------------------------------------------------------
-- Lauf beenden
---------------------------------------------------------------------------
function EoCRange.FinishRun(run, aborted, reason)
    if run.done then return end
    run.done = true

    EoCRange.Runs[run.id] = nil
    if EoCRange.LaneRuns[run.lane] == run then EoCRange.LaneRuns[run.lane] = nil end
    for _, p in ipairs(run.players) do
        if EoCRange.PlayerRuns[p] == run then EoCRange.PlayerRuns[p] = nil end
    end
    ResetLane(run.lane)

    local term = run.terminal
    local watchers = Watchers(run)

    if aborted then
        if IsValid(term) then
            term:SetNW2String("EoCR_State", "aborted")
            term:SetNW2String("EoCR_Live", reason or "Abgebrochen")
            term:SetNW2Float("EoCR_Until", CurTime() + 5)
        end
        EoCRange.Send("runstate", { state = "aborted", reason = reason or "Abgebrochen" }, watchers)
        if run.exam and EoCRange.ExamRunAborted then EoCRange.ExamRunAborted(run, reason) end
        EoCRange.UpdateLaneDisplay(run.lane)
        return
    end

    local result = EoCRange.ComputeResult(run)
    local inst = run.exam and run.exam.instructor
    if IsValid(inst) and not run.playerSet[inst] then EoCRange.Send("runstate", { state = "done" }, inst) end
    if IsValid(term) then
        term:SetNW2String("EoCR_State", "result")
        term:SetNW2String("EoCR_Live", EoCRange.Format(run.def, result.value))
        term:SetNW2Float("EoCR_Until", CurTime() + C.ResultShowTime)
    end
    EoCRange.UpdateLaneDisplay(run.lane)

    for _, p in ipairs(run.players) do
        if IsValid(p) then EoCRange.StoreResult(run, p, result) end
    end
end

---------------------------------------------------------------------------
-- Ergebnis speichern, Ränge, Rückmeldungen
---------------------------------------------------------------------------
local function BroadcastBoard(discId)
    EoCRange.Send("board", { d = discId, b = EoCRange.Boards[discId], o = EoCRange.UnitOverall })
end
EoCRange.BroadcastBoard = BroadcastBoard

function EoCRange.StoreResult(run, p, result)
    local def = run.def
    local info = EoCRange.CharInfo(p)
    local now = os.time()
    local exam = run.exam
    local row = {
        char_id = info.id, steamid = info.steamid, name = info.name, unit = info.unit, unit_name = info.unitName,
        discipline = def.id, score = result.value, time = result.time, hits = result.hits, shots = result.shots,
        accuracy = result.accuracy, react = result.react or 0, created = now, week = EoCRange.WeekKey(now), month = EoCRange.MonthKey(now),
        flagged = result.flagged and 1 or 0, exam = exam and 1 or 0,
        instructor = exam and exam.instructorName or "", instructor_sid = exam and exam.instructorSid or "",
        lane = run.lane, map = game.GetMap(),
        data = util.TableToJSON({ holes = result.holes, penalties = result.penalties, stage = result.stage, shotHits = result.shotHits,
            hostageHits = result.hostageHits, total = result.total, squad = #run.players > 1 and run.shooterName or nil }),
    }

    DB.BestOf(info.id, def.id, "all", function(pb)
        DB.Top(def, "all", 1, nil, function(serverTop)
            DB.Top(def, "all", 1, info.unit, function(unitTop)
                DB.LaneRecord(def, run.lane, game.GetMap(), function(laneRec)
                    DB.InsertRun(row, function(runId)
                        row.run_id = runId or 0
                        local function After()
                            local valid = not result.flagged
                            local isPB = valid and EoCRange.Better(def, result.value, pb)
                            local isUnit = isPB and EoCRange.Better(def, result.value, unitTop[1] and unitTop[1].score)
                            local isServer = isPB and EoCRange.Better(def, result.value, serverTop[1] and serverTop[1].score)
                            local isLane = valid and EoCRange.Better(def, result.value, laneRec)

                            if isPB then
                                EoCRange.BestCache[info.id] = EoCRange.BestCache[info.id] or {}
                                EoCRange.BestCache[info.id][def.id] = result.value
                            end

                            DB.Rank(def, "all", result.value, info.unit, function(unitRank)
                                DB.Rank(def, "all", result.value, nil, function(serverRank)
                                    local payload = table.Copy(result)
                                    payload.runId = runId
                                    payload.valueText = EoCRange.Format(def, result.value)
                                    payload.unitRank = unitRank
                                    payload.serverRank = serverRank
                                    payload.unitName = info.unitName
                                    payload.pb = pb
                                    payload.isPB = isPB
                                    payload.laneRecord = laneRec
                                    payload.isLaneRecord = isLane
                                    payload.serverRecord = serverTop[1] and serverTop[1].score
                                    payload.exam = exam ~= nil
                                    if IsValid(p) then EoCRange.Send("result", payload, p) end

                                    -- Rückmeldungen
                                    local valueText = EoCRange.Format(def, result.value)
                                    if isServer then
                                        EoCRange.Announce(info.name .. " (" .. info.unitName .. ") stellt einen neuen Serverrekord auf: " .. def.name .. " – " .. valueText .. "!")
                                    elseif isUnit then
                                        local mates = {}
                                        for _, o in ipairs(player.GetAll()) do
                                            if EoCRange.UnitOf(o) == info.unit then mates[#mates + 1] = o end
                                        end
                                        EoCRange.Announce(info.name .. " hat einen neuen Einheitenrekord für " .. info.unitName .. " aufgestellt: " .. def.name .. " – " .. valueText, mates, "unit")
                                    end
                                    if isPB and IsValid(p) then
                                        EoCRange.Send("banner", { t = "NEUE BESTLEISTUNG", s = def.name .. " – " .. valueText }, p)
                                    end
                                    if result.flagged and IsValid(p) then
                                        EoCRange.Notify(p, "Reaktionszeit unter " .. C.ReactionMinMs .. " ms – der Lauf wird erst nach Prüfung durch einen Admin gewertet.", 1)
                                        EoCRange.Log(nil, "Verdacht", info.name .. " (" .. info.steamid .. ") – " .. def.name .. " " .. valueText .. " markiert (Reaktionszeit). Lauf #" .. tostring(runId))
                                    end

                                    hook.Run("EoCRange_RunFinished", p, def.id, payload, isPB)
                                    if exam and EoCRange.ExamRecord then EoCRange.ExamRecord(run, p, payload) end
                                end)
                            end)

                            if valid then DB.RefreshDiscipline(def.id, function() BroadcastBoard(def.id) end) end
                        end

                        if result.flagged then After() else DB.UpdateBest(def, row, After) end
                    end)
                end)
            end)
        end)
    end)
end

---------------------------------------------------------------------------
-- Abzeichen vergeben / entziehen
---------------------------------------------------------------------------
function EoCRange.AwardBadge(charId, steamid, name, level, instructor)
    local instName = IsValid(instructor) and EoCRange.CharInfo(instructor).name or "System"
    local instSid = IsValid(instructor) and instructor:SteamID() or ""
    DB.InsertBadge({ char_id = charId, steamid = steamid, name = name, level = level, instructor = instName, instructor_sid = instSid }, function()
        if (EoCRange.BadgeCache[charId] or 0) < level then EoCRange.BadgeCache[charId] = level end
        EoCRange.GrantBadgeTraining(charId, level, instructor, "Schießprüfung bei " .. instName)
        local p = EoCRange.PlayerByChar(charId)
        if IsValid(p) then
            p:SetNW2Int("EoCR_Badge", EoCRange.BadgeCache[charId])
            EoCRange.Send("banner", { t = "SCHÜTZENABZEICHEN", s = EoCRange.BadgeName(level) .. " – bestanden", lvl = level }, p)
        end
        EoCRange.Log(instructor, "Abzeichen", name .. " (" .. steamid .. ") erhält " .. EoCRange.BadgeName(level))
        hook.Run("EoCRange_BadgeAwarded", p, level, instructor)
    end)
end

function EoCRange.RevokeBadge(badgeRow, actor, reason)
    local by = IsValid(actor) and EoCRange.CharInfo(actor).name or "System"
    DB.RevokeBadge(badgeRow.id, by, reason, function()
        DB.LoadBadges(function()
            local p = EoCRange.PlayerByChar(badgeRow.char_id)
            if IsValid(p) then p:SetNW2Int("EoCR_Badge", EoCRange.BadgeCache[badgeRow.char_id] or 0) end
        end)
        EoCRange.RevokeBadgeTraining(badgeRow.char_id, badgeRow.level, actor, reason)
        EoCRange.Log(actor, "Abzeichen entzogen", badgeRow.name .. " – " .. EoCRange.BadgeName(badgeRow.level) .. " – Grund: " .. reason)
    end)
end

---------------------------------------------------------------------------
-- Terminal öffnen
---------------------------------------------------------------------------
function EoCRange.OpenTerminal(ply, term)
    local info = EoCRange.CharInfo(ply)
    local allowed = {}
    for _, d in ipairs(EoCRange.AllDisciplines()) do
        if term:Allows(d.id) then allowed[#allowed + 1] = d.id end
    end
    EoCRange.LoadPlayerBests(ply, function(rows)
        local bests = {}
        for _, r in ipairs(rows) do
            bests[r.discipline] = bests[r.discipline] or {}
            local key = r.period == "all" and "all" or (string.sub(r.period, 1, 1) == "w" and "week" or "month")
            bests[r.discipline][key] = r.score
        end
        local locked, lvl = EoCRange.DefconLocked()
        local lane = EoCRange.LaneInfo(term:GetLane())
        EoCRange.Send("terminal", {
            ent = term:EntIndex(), lane = term:GetLane(), allowed = allowed, bests = bests,
            badge = EoCRange.BadgeCache[info.id] or 0, unit = info.unit, unitName = info.unitName, name = info.name,
            instructor = EoCRange.IsInstructor(ply), defcon = locked and lvl or nil,
            locked = lane.locked and (lane.lockReason or "") or nil, reserved = lane.reserved and (lane.reservedName or "") or nil,
            exam = lane.exam and true or nil, busy = EoCRange.LaneRuns[term:GetLane()] ~= nil,
        }, ply)
    end)
end

---------------------------------------------------------------------------
-- Anfragen vom Client
---------------------------------------------------------------------------
EoCRange.Receive("start", function(ply, data)
    local term = Entity(tonumber(data.ent) or 0)
    if not IsValid(term) or term:GetClass() ~= "range_terminal" then return end
    if ply:GetPos():Distance(term:GetPos()) > 400 then
        EoCRange.Notify(ply, "Du bist zu weit vom Terminal entfernt.", 1)
        return
    end
    EoCRange.StartRun(ply, term, tostring(data.disc or ""), { stage = data.stage })
end, 1)

EoCRange.Receive("abort", function(ply)
    local run = EoCRange.PlayerRuns[ply]
    if run then EoCRange.FinishRun(run, true, "Vom Schützen abgebrochen.") end
end, 0.5)

-- Rangliste anfordern: { disc, period = all|month|week, unit = true }
EoCRange.Receive("board", function(ply, data)
    local def = EoCRange.GetDiscipline(data.disc)
    if not def then return end
    local period = EoCRange.PeriodNames[data.period] and data.period or "all"
    if data.unit then
        local unit = EoCRange.UnitOf(ply)
        DB.Top(def, EoCRange.PeriodKey(period), 10, unit, function(rows)
            local list = {}
            for _, r in ipairs(rows) do list[#list + 1] = { c = r.char_id, n = r.name, u = r.unit, un = EoCRange.UnitName(r.unit, r.unit_name), s = r.score } end
            EoCRange.Send("boardreply", { disc = def.id, period = period, unit = true, list = list }, ply)
        end)
        return
    end
    local b = EoCRange.Boards[def.id]
    EoCRange.Send("boardreply", { disc = def.id, period = period, list = b and b[period] or {}, units = b and b.units or {} }, ply)
end, 0.3)

-- Persönliche Werte (Bestwerte, letzte Läufe, Abzeichen)
EoCRange.Receive("personal", function(ply)
    local info = EoCRange.CharInfo(ply)
    DB.PersonalBests(info.id, function(bests)
        DB.ListRuns({ char_id = info.id, limit = 25 }, function(runs)
            DB.CharBadges(info.id, function(badges)
                EoCRange.Send("personal", { bests = bests, runs = runs, badges = badges, badge = EoCRange.BadgeCache[info.id] or 0, name = info.name }, ply)
            end)
        end)
    end)
end, 1)

-- Trefferbild eines Laufs nachträglich ansehen
EoCRange.Receive("rundetail", function(ply, data)
    DB.GetRun(tonumber(data.id) or 0, function(r)
        if not r then return end
        local own = r.steamid == ply:SteamID()
        if not own and not EoCRange.IsInstructor(ply) then return end
        r.data = util.JSONToTable(r.data or "") or {}
        EoCRange.Send("rundetail", r, ply)
    end)
end, 0.5)

---------------------------------------------------------------------------
-- Start: Datenbank, Caches, Wochen-Reset
---------------------------------------------------------------------------
EoCRange.CurrentWeek = EoCRange.CurrentWeek or EoCRange.WeekKey()

local function SetTrophy(unit, name)
    SetGlobal2String("EoCR_TrophyUnit", unit or "")
    SetGlobal2String("EoCR_TrophyName", name or "")
end

function EoCRange.CheckTrophy(announce)
    local prev = EoCRange.WeekKey(os.time() - 7 * 86400)
    DB.EnsureTrophy(prev, function(unit, name)
        SetTrophy(unit, name)
        if announce and unit then
            EoCRange.Announce("Der Wochenpokal am Schießstand geht an " .. (name or unit) .. "! Glückwunsch.")
        end
    end)
end

local function LoadSettings()
    local raw = file.Read("eoc_range/settings.json", "DATA")
    if raw then EoCRange.ApplySettings(util.JSONToTable(raw) or {}) end
end

function EoCRange.SaveSettings()
    file.Write("eoc_range/settings.json", util.TableToJSON(EoCRange.SettingsTable(), true))
end

function EoCRange.SendInit(target)
    local customs = {}
    for id, d in pairs(EoCRange.Custom) do customs[id] = d end
    EoCRange.Send("init", { settings = EoCRange.SettingsTable(), customs = customs, boards = EoCRange.Boards, overall = EoCRange.UnitOverall }, target)
end

hook.Add("Initialize", "EoCRange_DB", function()
    LoadSettings()
    DB.Init(function()
        DB.LoadCustom(function()
            DB.LoadBadges(function()
                DB.RefreshAll(function()
                    EoCRange.CheckTrophy(false)
                    EoCRange.Ready = true
                    EoCRange.SendInit()
                    MsgC(Color(252, 178, 73), "[EoC Range] ", color_white, "Datenbank bereit (" .. (DB.IsMySQL() and "MySQL" or "SQLite") .. ").\n")
                end)
            end)
        end)
    end)
end)

hook.Add("PlayerInitialSpawn", "EoCRange_Init", function(ply)
    timer.Simple(6, function()
        if not IsValid(ply) then return end
        EoCRange.SendInit(ply)
        EoCRange.LoadPlayerBests(ply)
    end)
end)

-- Wochen-Reset (Montag 04:00): Wochenwerte wandern ins Archiv, Pokal wird vergeben
timer.Create("EoCRange_Week", 60, 0, function()
    local wk = EoCRange.WeekKey()
    if wk ~= EoCRange.CurrentWeek then
        EoCRange.CurrentWeek = wk
        DB.RefreshAll(function()
            EoCRange.SendInit()
            EoCRange.CheckTrophy(true)
        end)
    end
end)

-- DEFCON-Änderungen auf den Terminals sichtbar machen
timer.Create("EoCRange_LaneDisplay", 3, 0, function()
    EoCRange.UpdateAllLaneDisplays()
end)
