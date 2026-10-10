EoCSport = EoCSport or {}

local C = EoCSport.Config

for _, name in ipairs({
    "EoCSport_Start", "EoCSport_State", "EoCSport_Rep", "EoCSport_Stop",
    "EoCSport_Group", "EoCSport_GroupCmd", "EoCSport_Menu", "EoCSport_Notify",
    "EoCSport_Sync",
}) do
    util.AddNetworkString(name)
end

local Sessions = EoCSport.Sessions or {}
EoCSport.Sessions = Sessions

local Groups = EoCSport.Groups or {}
EoCSport.Groups = Groups
local nextGroupId = 0

local MAX_COUNT = 65535

---------------------------------------------------------------------------
-- Netzwerk-Helfer
---------------------------------------------------------------------------
local function Notify(target, msg)
    if not IsValid(target) and not istable(target) then return end
    net.Start("EoCSport_Notify")
    net.WriteString(msg)
    net.Send(target)
end
EoCSport.Notify = Notify

local function SendState(ply, s, target)
    net.Start("EoCSport_State")
    net.WriteEntity(ply)
    net.WriteString(s.id)
    net.WriteUInt(s.count, 16)
    net.WriteUInt(s.target, 16)
    net.WriteFloat(s.yaw)
    net.WriteFloat(s.startTime)
    net.WriteBool(s.holding)
    net.WriteBool(s.group ~= nil)
    net.WriteBool(s.done)
    if target then net.Send(target) else net.Broadcast() end
end

local function SendRep(ply, s, start, dur)
    net.Start("EoCSport_Rep")
    net.WriteEntity(ply)
    net.WriteUInt(s.count, 16)
    net.WriteFloat(start)
    net.WriteFloat(dur)
    net.Broadcast()
end

local function GroupStart(op)
    net.Start("EoCSport_Group")
    net.WriteUInt(op, 4)
end

---------------------------------------------------------------------------
-- Prüfungen
---------------------------------------------------------------------------
local function HasSpace(ply, ex)
    local space = ex.space
    if not space then return true end

    local fwd = Angle(0, ply:EyeAngles().y, 0):Forward()
    local pos = ply:GetPos()
    local from = ex.spaceFrom or 0
    local half = space.y / 2
    local mins = Vector(-half, -half, 0)
    local maxs = Vector(half, half, math.max(space.z, 16))
    local steps = math.max(1, math.ceil(space.x / space.y))

    for i = 0, steps do
        local p = pos + fwd * (from + space.x * i / steps) + Vector(0, 0, 4)
        local tr = util.TraceHull({ start = p, endpos = p, mins = mins, maxs = maxs, filter = ply, mask = MASK_PLAYERSOLID })
        if tr.Hit or tr.StartSolid then return false end

        local down = util.TraceLine({ start = p, endpos = p - Vector(0, 0, 24), filter = ply, mask = MASK_PLAYERSOLID })
        if not down.Hit then return false end
    end
    return true
end

local function DefconBlocked()
    if not C.DefconBlockLevel or not C.GetDefcon then return false end
    local level = C.GetDefcon()
    return isnumber(level) and level <= C.DefconBlockLevel
end

function EoCSport.CanStart(ply, ex)
    if not ex then return false, "Unbekannte Übung." end
    if Sessions[ply] then return false, "Du bist bereits in einer Übung." end
    if not ply:Alive() then return false, "Du bist tot." end
    if ply:InVehicle() then return false, "Nicht in einem Fahrzeug." end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return false, "Nicht im Noclip." end
    if ply:WaterLevel() >= 2 then return false, "Nicht im Wasser." end

    local now = CurTime()
    if now - (ply.EoCSportLastCombat or -999) < C.CombatCooldown then
        return false, "Du hast gerade Schaden bekommen oder geschossen."
    end
    if DefconBlocked() then return false, "Gesperrt wegen Gefechtsbereitschaft (DEFCON)." end
    if not EoCSport.InAllowedZone(ply:GetPos()) then return false, "Hier ist kein Trainingsbereich." end

    if ex.needsBar then
        if not IsValid(EoCSport.FindPullupBar(ply)) then
            return false, "Keine freie Klimmzugstange in der Nähe."
        end
    else
        if not ply:IsOnGround() then return false, "Du musst auf dem Boden stehen." end

        local tr = util.TraceLine({
            start = ply:GetPos() + Vector(0, 0, 4),
            endpos = ply:GetPos() - Vector(0, 0, 16),
            filter = ply,
            mask = MASK_PLAYERSOLID,
        })
        if not tr.Hit then return false, "Kein fester Boden." end
        if tr.HitNormal.z < math.cos(math.rad(C.MaxSlope)) then return false, "Der Boden ist zu schräg." end
        if not HasSpace(ply, ex) then return false, "Hier ist zu wenig Platz." end
    end

    local allowed, reason = hook.Run("EoCSport_CanStart", ply, ex.id)
    if allowed == false then return false, reason or "Gerade nicht möglich." end

    return true
end

---------------------------------------------------------------------------
-- Start / Stopp
---------------------------------------------------------------------------
local function Holster(ply, s)
    local wep = ply:GetActiveWeapon()
    s.prevWeapon = IsValid(wep) and wep:GetClass() or nil
    if C.HolsterWeapon and ply:HasWeapon(C.HolsterWeapon) then
        ply:SelectWeapon(C.HolsterWeapon)
    elseif IsValid(wep) then
        ply:SetActiveWeapon(NULL)
    end
end

local function MountBar(ply, s, bar)
    local cfg = C.PullupBar
    local lp = bar:WorldToLocal(ply:GetPos())
    local side = lp.x >= 0 and 1 or -1
    local half = cfg.Length / 2 - 16
    local y = math.Clamp(lp.y, -half, half)
    local hangPos = bar:LocalToWorld(Vector(side * cfg.HangOffset, y, 0)) - Vector(0, 0, cfg.HangHeight)

    s.bar = bar
    s.oldMoveType = ply:GetMoveType()
    s.yaw = bar:GetAngles().y + (side > 0 and 180 or 0)

    ply:SetMoveType(MOVETYPE_NONE)
    ply:SetLocalVelocity(vector_origin)
    ply:SetPos(hangPos)
    ply:SetEyeAngles(Angle(0, s.yaw, 0))
    bar:SetNW2Entity("EoCSport_User", ply)
end

local function UnmountBar(ply, s)
    if IsValid(s.bar) then s.bar:SetNW2Entity("EoCSport_User", NULL) end
    if IsValid(ply) and ply:GetMoveType() == MOVETYPE_NONE then
        ply:SetMoveType(s.oldMoveType ~= MOVETYPE_NONE and s.oldMoveType or MOVETYPE_WALK)
    end
end

-- opts: group, penalty, lockUntil
function EoCSport.Start(ply, id, target, opts)
    opts = opts or {}
    local ex = EoCSport.GetExercise(id)
    local ok, reason = EoCSport.CanStart(ply, ex)
    if not ok then return false, reason end

    local now = CurTime()
    local s = {
        id = ex.id,
        ex = ex,
        count = 0,
        target = math.Clamp(math.floor(tonumber(target) or 0), 0, 999),
        startTime = now,
        nextRep = math.max(now + C.EnterTime, opts.lockUntil or 0),
        lockUntil = opts.lockUntil,
        lastInput = now,
        presses = {},
        holding = false,
        holdAcc = 0,
        streak = 0,
        lastRepEnd = 0,
        usedBeat = 0,
        group = opts.group,
        penalty = opts.penalty == true,
        done = false,
        yaw = ply:EyeAngles().y,
    }

    Holster(ply, s)
    if ex.needsBar then MountBar(ply, s, EoCSport.FindPullupBar(ply)) end
    s.anchor = ply:GetPos()

    Sessions[ply] = s
    ply:SetNW2Bool("EoCSport_Active", true)
    SendState(ply, s)
    return true
end

local GroupMemberStopped

function EoCSport.Stop(ply, reason)
    local s = Sessions[ply]
    if not s then return end
    Sessions[ply] = nil

    if not IsValid(ply) then return end

    ply:SetNW2Bool("EoCSport_Active", false)
    if s.bar then UnmountBar(ply, s) end

    net.Start("EoCSport_Stop")
    net.WriteEntity(ply)
    net.WriteString(reason or "user")
    net.WriteUInt(s.count, 16)
    net.Broadcast()

    if s.prevWeapon and ply:Alive() then
        local class = s.prevWeapon
        timer.Simple(C.LeaveTime, function()
            if IsValid(ply) and ply:Alive() and not Sessions[ply] and ply:HasWeapon(class) then
                ply:SelectWeapon(class)
            end
        end)
    end

    local reached = s.target > 0 and s.count >= s.target
    hook.Run("EoCSport_Finished", ply, s.id, s.count, reached)

    if s.group then GroupMemberStopped(s.group, ply, s) end

    local pen = ply.EoCSportPenalty
    if s.penalty and pen and reached then
        ply.EoCSportPenalty = nil
        GroupStart(EoCSport.G_PENALTY_CLEAR)
        net.Send(ply)
        if IsValid(pen.byPly) then
            Notify(pen.byPly, EoCSport.GetName(ply) .. " hat die Strafrunde erledigt.")
        end
    end
end

function EoCSport.StartPenalty(ply)
    local pen = ply.EoCSportPenalty
    if not pen then return false, "Keine Strafrunde offen." end
    return EoCSport.Start(ply, pen.id, pen.count, { penalty = true })
end

function EoCSport.OnEndKey(ply)
    if not Sessions[ply] then return end
    timer.Simple(0, function()
        if IsValid(ply) and Sessions[ply] then EoCSport.Stop(ply, "user") end
    end)
end

---------------------------------------------------------------------------
-- Zählen
---------------------------------------------------------------------------
local GroupOnProgress, GroupMemberDone

local function ReachedTarget(ply, s, delay)
    s.done = true
    s.holding = false
    if s.group then
        SendState(ply, s)
        GroupMemberDone(s.group, ply, s)
        return
    end
    timer.Simple(delay or 0, function()
        if IsValid(ply) and Sessions[ply] == s then EoCSport.Stop(ply, "goal") end
    end)
end

local function CountUp(ply, s, start, dur)
    s.count = math.min(s.count + 1, MAX_COUNT)
    SendRep(ply, s, start, dur)
    hook.Run("EoCSport_Rep", ply, s.id, s.count)
    if s.group then GroupOnProgress(s.group, ply, s) end
    if s.target > 0 and s.count >= s.target then ReachedTarget(ply, s, dur) end
end

local function TempoAllows(ply, s, now)
    local g = s.group
    if not g or not g.tempo then return true end
    local ok = g.state == "running" and g.beat > 0
        and now - g.lastBeat <= C.Group.TempoWindow
        and s.usedBeat ~= g.beat
    if ok then
        s.usedBeat = g.beat
        return true
    end
    GroupStart(EoCSport.G_EARLY)
    net.Send(ply)
    return false
end

local function DoRep(ply, s, now)
    if s.done or now < s.nextRep then return end
    if not TempoAllows(ply, s, now) then return end

    local dur = s.ex.duration
    local fat = C.Fatigue
    if fat and fat.Enabled then
        if now - s.lastRepEnd <= fat.ResetAfter then
            s.streak = s.streak + 1
        else
            s.streak = 0
        end
        local extra = math.Clamp((s.streak - fat.StartAfter) * fat.PerRep, 0, fat.Max)
        dur = dur * (1 + extra)
    end

    s.nextRep = now + dur
    s.lastRepEnd = now + dur
    CountUp(ply, s, now, dur)
end

local function SetHolding(ply, s, holding, now)
    if s.holding == holding then return end
    if holding then
        s.holdTick = now
    else
        s.holdAcc = s.holdAcc + (now - (s.holdTick or now))
        s.holdTick = nil
    end
    s.holding = holding
    SendState(ply, s)
end

hook.Add("KeyPress", "EoCSport_Key", function(ply, key)
    local now = CurTime()

    local g = ply.EoCSportGroup
    if g and g.state == "invite" and g.members[ply] and g.members[ply].state == "invited" then
        if key == IN_USE then
            EoCSport.AnswerInvite(ply, true)
            return
        elseif key == C.DeclineKey then
            EoCSport.AnswerInvite(ply, false)
            return
        end
    end

    if key ~= IN_USE then return end
    local s = Sessions[ply]
    if not s then return end

    s.lastInput = now

    -- Tastenspam: mehr als X Drücke pro Sekunde werden ignoriert.
    local presses = s.presses
    for i = #presses, 1, -1 do
        if now - presses[i] > 1 then table.remove(presses, i) end
    end
    presses[#presses + 1] = now
    if #presses > C.MaxPressesPerSecond then return end

    if s.lockUntil and now < s.lockUntil then return end
    if now < s.startTime + C.EnterTime then return end

    if s.ex.mode == "hold" then
        if s.done then return end
        if s.ex.hold == "toggle" then
            SetHolding(ply, s, not s.holding, now)
        else
            SetHolding(ply, s, true, now)
        end
        return
    end

    DoRep(ply, s, now)
end)

hook.Add("KeyRelease", "EoCSport_Key", function(ply, key)
    if key ~= IN_USE then return end
    local s = Sessions[ply]
    if not s or s.ex.mode ~= "hold" or s.ex.hold == "toggle" or not s.holding then return end

    SetHolding(ply, s, false, CurTime())
    if not s.done then EoCSport.Stop(ply, "user") end
end)

-- E öffnet während der Übung (oder einer offenen Aufforderung) keine Türen.
hook.Add("PlayerUse", "EoCSport_Block", function(ply)
    if Sessions[ply] then return false end
    local g = ply.EoCSportGroup
    if g and g.state == "invite" then return false end
end)

---------------------------------------------------------------------------
-- Laufende Prüfungen
---------------------------------------------------------------------------
local function CheckSession(ply, s, now)
    if not IsValid(ply) then Sessions[ply] = nil return end
    if not ply:Alive() then return EoCSport.Stop(ply, "death") end
    if ply:InVehicle() then return EoCSport.Stop(ply, "vehicle") end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return EoCSport.Stop(ply, "invalid") end
    if now - s.lastInput > C.AfkTimeout then return EoCSport.Stop(ply, "afk") end
    if DefconBlocked() then return EoCSport.Stop(ply, "defcon") end
    if not EoCSport.InAllowedZone(ply:GetPos()) then return EoCSport.Stop(ply, "zone") end

    if s.bar then
        if not IsValid(s.bar) then return EoCSport.Stop(ply, "bar") end
    elseif ply:GetPos():DistToSqr(s.anchor) > C.MaxPushDistance * C.MaxPushDistance then
        return EoCSport.Stop(ply, "pushed")
    end
end

local GroupThink
local nextCheck = 0

hook.Add("Think", "EoCSport_Think", function()
    local now = CurTime()

    -- Haltende Übungen zählen Sekunden.
    for ply, s in pairs(Sessions) do
        if s.holding and IsValid(ply) then
            s.holdAcc = s.holdAcc + (now - (s.holdTick or now))
            s.holdTick = now
            s.lastInput = now
            local secs = math.floor(s.holdAcc)
            if secs > s.count then
                s.count = secs - 1
                CountUp(ply, s, now, 1)
            end
        end
    end

    if now < nextCheck then return end
    nextCheck = now + 0.2

    for ply, s in pairs(Sessions) do CheckSession(ply, s, now) end
    for _, g in pairs(Groups) do GroupThink(g, now) end
end)

local function MarkCombat(ply)
    if IsValid(ply) and ply:IsPlayer() then ply.EoCSportLastCombat = CurTime() end
end

hook.Add("EntityTakeDamage", "EoCSport_Damage", function(target, dmg)
    if dmg:GetDamage() <= 0 then return end
    local attacker = dmg:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= target then MarkCombat(attacker) end
    if not (IsValid(target) and target:IsPlayer()) then return end
    MarkCombat(target)
    if Sessions[target] then EoCSport.Stop(target, "damage") end
end)

hook.Add("EntityFireBullets", "EoCSport_Shot", function(ent)
    MarkCombat(ent)
end)

hook.Add("PlayerDeath", "EoCSport_Death", function(ply) EoCSport.Stop(ply, "death") end)
hook.Add("PlayerSilentDeath", "EoCSport_Death", function(ply) EoCSport.Stop(ply, "death") end)
hook.Add("PlayerSpawn", "EoCSport_Spawn", function(ply) EoCSport.Stop(ply, "invalid") end)
hook.Add("PlayerEnteredVehicle", "EoCSport_Vehicle", function(ply) EoCSport.Stop(ply, "vehicle") end)
hook.Add("OnPlayerChangedTeam", "EoCSport_Job", function(ply) EoCSport.Stop(ply, "job") end)
hook.Add("PlayerChangedTeam", "EoCSport_Job", function(ply) EoCSport.Stop(ply, "job") end)

---------------------------------------------------------------------------
-- Gruppentraining
---------------------------------------------------------------------------
local function Participants(g, includeLeader)
    local list = {}
    for _, p in ipairs(g.order) do
        local m = g.members[p]
        if IsValid(p) and m and m.state ~= "invited" and m.state ~= "declined" and m.state ~= "expired" then
            list[#list + 1] = p
        end
    end
    if includeLeader and IsValid(g.leader) then list[#list + 1] = g.leader end
    return list
end

local function SendLeaderList(g)
    if not IsValid(g.leader) then return end
    GroupStart(EoCSport.G_LIST)
    net.WriteString(g.state)
    net.WriteString(g.exId)
    net.WriteUInt(g.target, 16)
    net.WriteBool(g.tempo)
    net.WriteFloat(g.startAt or 0)
    net.WriteFloat(g.inviteEnd)
    net.WriteUInt(g.beat, 16)
    net.WriteUInt(#g.order, 8)
    for _, p in ipairs(g.order) do
        local m = g.members[p]
        net.WriteString(m.name)
        net.WriteUInt(m.count, 16)
        net.WriteUInt(EoCSport.MemberStateIds[m.state] or 0, 4)
        net.WriteFloat(m.doneTime or -1)
    end
    net.Send(g.leader)
end

local function FinishGroup(g, cancelled)
    if g.finished then return end
    g.finished = true
    Groups[g.id] = nil
    if IsValid(g.leader) and g.leader.EoCSportLead == g then g.leader.EoCSportLead = nil end

    local recipients = Participants(g, true)

    for _, p in ipairs(g.order) do
        local m = g.members[p]
        if IsValid(p) then
            if m.state == "invited" then
                GroupStart(EoCSport.G_INVITE_END)
                net.Send(p)
            end
            if p.EoCSportGroup == g then p.EoCSportGroup = nil end

            local s = Sessions[p]
            if s and s.group == g then
                m.count = s.count
                if m.state == "active" then m.state = cancelled and "cancelled" or "aborted" end
                s.group = nil
                EoCSport.Stop(p, cancelled and "cancel" or "group")
            end
        end
    end

    local weight = g.ex.groupWeight or 1
    local results = {}
    for _, p in ipairs(g.order) do
        local m = g.members[p]
        if m.state == "done" or m.state == "aborted" or m.state == "cancelled" then
            results[#results + 1] = {
                name = m.name, count = m.count, points = math.floor(m.count * weight),
                state = m.state, doneTime = m.doneTime,
            }
        end
    end
    table.sort(results, function(a, b)
        if (a.state == "done") ~= (b.state == "done") then return a.state == "done" end
        if a.state == "done" then return a.doneTime < b.doneTime end
        return a.points > b.points
    end)

    hook.Run("EoCSport_GroupFinished", g.leader, g.exId, g.target, results, cancelled)

    if #results > 0 and #recipients > 0 then
        GroupStart(EoCSport.G_RESULT)
        net.WriteString(g.exId)
        net.WriteUInt(g.target, 16)
        net.WriteBool(cancelled)
        net.WriteString(EoCSport.GetName(g.leader))
        net.WriteUInt(math.min(#results, 255), 8)
        for i = 1, math.min(#results, 255) do
            local r = results[i]
            net.WriteString(r.name)
            net.WriteUInt(r.count, 16)
            net.WriteUInt(math.min(r.points, MAX_COUNT), 16)
            net.WriteUInt(EoCSport.MemberStateIds[r.state] or 0, 4)
            net.WriteFloat(r.doneTime or -1)
        end
        net.Send(recipients)
    end

    if IsValid(g.leader) then
        GroupStart(EoCSport.G_LEADER_END)
        net.Send(g.leader)
    end
end
EoCSport.FinishGroup = FinishGroup

local function BeginCountdown(g)
    local now = CurTime()
    g.startAt = now + C.Group.Countdown

    local active = {}
    for _, p in ipairs(g.order) do
        local m = g.members[p]
        if not IsValid(p) then
            m.state = "failed"
        elseif m.state == "invited" then
            m.state = "expired"
            if p.EoCSportGroup == g then p.EoCSportGroup = nil end
            GroupStart(EoCSport.G_INVITE_END)
            net.Send(p)
        elseif m.state == "accepted" then
            local ok, reason = EoCSport.Start(p, g.exId, g.target, { group = g, lockUntil = g.startAt })
            if ok then
                m.state = "active"
                active[#active + 1] = p
            else
                m.state = "failed"
                p.EoCSportGroup = nil
                Notify(p, "Gruppentraining: " .. (reason or "Start nicht möglich."))
            end
        end
    end

    if #active == 0 then
        Notify(g.leader, "Gruppentraining abgebrochen: niemand hat angenommen oder starten können.")
        FinishGroup(g, true)
        return
    end

    g.state = "countdown"
    g.dirty = true

    active[#active + 1] = g.leader
    GroupStart(EoCSport.G_COUNTDOWN)
    net.WriteFloat(g.startAt)
    net.WriteString(g.exId)
    net.WriteUInt(g.target, 16)
    net.WriteBool(g.tempo)
    net.Send(active)
end

GroupThink = function(g, now)
    if not IsValid(g.leader) then return FinishGroup(g, true) end

    if g.state == "invite" then
        local waiting = false
        for _, p in ipairs(g.order) do
            if g.members[p].state == "invited" and IsValid(p) then waiting = true break end
        end
        if not waiting or now >= g.inviteEnd then BeginCountdown(g) end
    elseif g.state == "countdown" then
        if now >= g.startAt then
            g.state = "running"
            g.dirty = true
        end
    elseif g.state == "running" then
        if now - g.startAt > C.Group.MaxDuration then return FinishGroup(g, false) end
        local running = false
        for _, p in ipairs(g.order) do
            if g.members[p].state == "active" then running = true break end
        end
        if not running then return FinishGroup(g, false) end
    end

    if g.dirty and now >= (g.nextList or 0) then
        g.dirty = false
        g.nextList = now + C.Group.ListInterval
        SendLeaderList(g)
    end
end

GroupOnProgress = function(g, ply, s)
    local m = g.members[ply]
    if m then
        m.count = s.count
        g.dirty = true
    end
end

GroupMemberDone = function(g, ply, s)
    local m = g.members[ply]
    if not m then return end
    m.count = s.count
    m.state = "done"
    m.doneTime = CurTime() - (g.startAt or CurTime())
    g.dirty = true
end

GroupMemberStopped = function(g, ply, s)
    local m = g.members[ply]
    if not m then return end
    m.count = s.count
    if m.state == "active" then m.state = "aborted" end
    if ply.EoCSportGroup == g then ply.EoCSportGroup = nil end
    g.dirty = true
end

function EoCSport.CreateGroup(leader, id, target, radius, tempo)
    if not EoCSport.IsInstructor(leader) then return end
    if leader.EoCSportLead then
        return Notify(leader, "Du leitest bereits ein Gruppentraining.")
    end

    local ex = EoCSport.GetExercise(id)
    if not ex or ex.groupAllowed == false then
        return Notify(leader, "Diese Übung ist im Gruppenmodus nicht verfügbar.")
    end

    target = math.Clamp(math.floor(tonumber(target) or 0), 1, 999)
    radius = math.Clamp(tonumber(radius) or C.Group.DefaultRadius, 50, C.Group.MaxRadius)
    if ex.mode ~= "reps" then tempo = false end

    nextGroupId = nextGroupId + 1
    local now = CurTime()
    local g = {
        id = nextGroupId,
        leader = leader,
        exId = ex.id,
        ex = ex,
        target = target,
        radius = radius,
        tempo = tempo == true,
        state = "invite",
        inviteEnd = now + C.Group.InviteTime,
        members = {},
        order = {},
        beat = 0,
        lastBeat = -999,
        dirty = true,
    }

    local origin = leader:GetPos()
    for _, p in ipairs(player.GetAll()) do
        if p ~= leader and p:Alive() and not Sessions[p] and not p.EoCSportGroup and not p.EoCSportLead
            and p:GetPos():DistToSqr(origin) <= radius * radius then
            g.members[p] = { state = "invited", count = 0, name = EoCSport.GetName(p) }
            g.order[#g.order + 1] = p
        end
    end

    if #g.order == 0 then
        return Notify(leader, "Keine Spieler im Umkreis von " .. math.floor(radius) .. " Einheiten.")
    end

    Groups[g.id] = g
    leader.EoCSportLead = g

    for _, p in ipairs(g.order) do
        p.EoCSportGroup = g
        GroupStart(EoCSport.G_INVITE)
        net.WriteString(EoCSport.GetName(leader))
        net.WriteString(ex.id)
        net.WriteUInt(target, 16)
        net.WriteFloat(g.inviteEnd)
        net.WriteBool(g.tempo)
        net.Send(p)
    end

    Notify(leader, #g.order .. " Spieler aufgefordert: " .. EoCSport.FormatCount(ex, target) .. " " .. ex.name .. ".")
    SendLeaderList(g)
end

function EoCSport.AnswerInvite(ply, accept)
    local g = ply.EoCSportGroup
    if not g or g.state ~= "invite" then return end
    local m = g.members[ply]
    if not m or m.state ~= "invited" then return end

    GroupStart(EoCSport.G_INVITE_END)
    net.Send(ply)

    if accept then
        m.state = "accepted"
        Notify(ply, "Angenommen. Warte auf den Start.")
    else
        m.state = "declined"
        ply.EoCSportGroup = nil
    end
    g.dirty = true
end

function EoCSport.GroupBeat(leader)
    local g = leader.EoCSportLead
    if not g or not g.tempo or g.state ~= "running" then return end
    local now = CurTime()
    if now - g.lastBeat < g.ex.duration * 0.9 then return end

    g.beat = g.beat + 1
    g.lastBeat = now
    g.dirty = true

    local list = {}
    for _, p in ipairs(g.order) do
        if IsValid(p) and g.members[p].state == "active" then list[#list + 1] = p end
    end
    list[#list + 1] = leader

    GroupStart(EoCSport.G_BEAT)
    net.WriteUInt(g.beat, 16)
    net.WriteFloat(now)
    net.Send(list)
end

function EoCSport.GivePenalty(instructor, target, id, count)
    if not EoCSport.IsInstructor(instructor) then return end
    if not IsValid(target) or not target:IsPlayer() or target == instructor then return end

    local ex = EoCSport.GetExercise(id)
    if not ex then return end
    if target:GetPos():DistToSqr(instructor:GetPos()) > C.Penalty.MaxRadius * C.Penalty.MaxRadius then
        return Notify(instructor, "Der Spieler ist zu weit weg.")
    end

    count = math.Clamp(math.floor(tonumber(count) or 0), 1, C.Penalty.MaxCount)
    target.EoCSportPenalty = { id = ex.id, count = count, by = EoCSport.GetName(instructor), byPly = instructor }

    GroupStart(EoCSport.G_PENALTY)
    net.WriteString(ex.id)
    net.WriteUInt(count, 16)
    net.WriteString(EoCSport.GetName(instructor))
    net.Send(target)

    local what = EoCSport.FormatCount(ex, count) .. " " .. ex.name
    Notify(instructor, "Strafrunde für " .. EoCSport.GetName(target) .. ": " .. what .. ".")

    if Sessions[target] then
        Notify(target, "Strafrunde: " .. what .. ". Nach der aktuellen Übung über /sport starten.")
        return
    end

    local ok, reason = EoCSport.StartPenalty(target)
    if not ok then
        Notify(target, "Strafrunde: " .. what .. ". " .. (reason or "") .. " Über /sport starten, sobald es geht.")
    end
end

function EoCSport.AbortAll(instructor)
    if not EoCSport.IsInstructor(instructor) then return end
    if instructor.EoCSportLead then FinishGroup(instructor.EoCSportLead, true) end

    local origin = instructor:GetPos()
    local r2 = C.Penalty.MaxRadius * C.Penalty.MaxRadius
    local n = 0
    for p in pairs(Sessions) do
        if IsValid(p) and p:GetPos():DistToSqr(origin) <= r2 then
            EoCSport.Stop(p, "cancel")
            n = n + 1
        end
    end
    Notify(instructor, n .. " Übung(en) im Umkreis abgebrochen.")
end

hook.Add("PlayerDisconnected", "EoCSport_Cleanup", function(ply)
    EoCSport.Stop(ply, "invalid")
    Sessions[ply] = nil
    if ply.EoCSportLead then FinishGroup(ply.EoCSportLead, true) end
    local g = ply.EoCSportGroup
    if g and g.members[ply] and g.members[ply].state == "invited" then
        g.members[ply].state = "expired"
        g.dirty = true
    end
end)

---------------------------------------------------------------------------
-- Eingänge vom Client
---------------------------------------------------------------------------
local function RateLimit(ply, key, delay)
    ply.EoCSportRate = ply.EoCSportRate or {}
    local now = CurTime()
    if (ply.EoCSportRate[key] or 0) > now then return false end
    ply.EoCSportRate[key] = now + delay
    return true
end

net.Receive("EoCSport_Start", function(_, ply)
    if not RateLimit(ply, "start", 0.5) then return end
    local id = net.ReadString()
    local target = net.ReadUInt(16)
    local penalty = net.ReadBool()

    if Sessions[ply] then return end
    local g = ply.EoCSportGroup
    if g and g.state ~= "invite" then return end

    local ok, reason
    if penalty then
        ok, reason = EoCSport.StartPenalty(ply)
    else
        ok, reason = EoCSport.Start(ply, id, target)
    end
    if not ok then Notify(ply, reason or "Start nicht möglich.") end
end)

net.Receive("EoCSport_Stop", function(_, ply)
    if Sessions[ply] then EoCSport.Stop(ply, "user") end
end)

net.Receive("EoCSport_Sync", function(_, ply)
    if not RateLimit(ply, "sync", 5) then return end
    for p, s in pairs(Sessions) do
        if IsValid(p) then SendState(p, s, ply) end
    end
    local pen = ply.EoCSportPenalty
    if pen then
        GroupStart(EoCSport.G_PENALTY)
        net.WriteString(pen.id)
        net.WriteUInt(pen.count, 16)
        net.WriteString(pen.by)
        net.Send(ply)
    end
end)

net.Receive("EoCSport_GroupCmd", function(_, ply)
    if not RateLimit(ply, "group", 0.2) then return end
    if not EoCSport.IsInstructor(ply) then return end

    local op = net.ReadUInt(4)
    if op == EoCSport.GC_CREATE then
        local id = net.ReadString()
        local target = net.ReadUInt(16)
        local radius = net.ReadUInt(16)
        local tempo = net.ReadBool()
        EoCSport.CreateGroup(ply, id, target, radius, tempo)
    elseif op == EoCSport.GC_BEAT then
        EoCSport.GroupBeat(ply)
    elseif op == EoCSport.GC_CANCEL then
        if ply.EoCSportLead then FinishGroup(ply.EoCSportLead, true) end
    elseif op == EoCSport.GC_PENALTY then
        local target = net.ReadEntity()
        local id = net.ReadString()
        local count = net.ReadUInt(16)
        EoCSport.GivePenalty(ply, target, id, count)
    elseif op == EoCSport.GC_ABORT_ALL then
        EoCSport.AbortAll(ply)
    end
end)

---------------------------------------------------------------------------
-- /sport und Konsole
---------------------------------------------------------------------------
function EoCSport.ToggleMenu(ply)
    if Sessions[ply] then
        EoCSport.Stop(ply, "user")
        return
    end
    net.Start("EoCSport_Menu")
    net.Send(ply)
end

hook.Add("PlayerSay", "EoCSport_Chat", function(ply, text)
    local t = string.lower(string.Trim(text))
    for _, cmd in ipairs(C.ChatCommands) do
        if t == cmd then
            EoCSport.ToggleMenu(ply)
            return ""
        end
    end
end)

concommand.Add("eoc_sport", function(ply)
    if IsValid(ply) then EoCSport.ToggleMenu(ply) end
end)

concommand.Add("eoc_sport_takt", function(ply)
    if IsValid(ply) then EoCSport.GroupBeat(ply) end
end)
