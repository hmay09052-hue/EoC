EoCSport = EoCSport or {}

local C = EoCSport.Config

EoCSport.StopReasons = {
    goal = "Ziel erreicht",
    user = "Beendet",
    damage = "Schaden erhalten",
    death = "Gestorben",
    job = "Jobwechsel",
    vehicle = "Fahrzeug betreten",
    pushed = "Weggeschoben",
    afk = "Keine Eingabe (AFK)",
    defcon = "Gefechtsbereitschaft",
    zone = "Trainingsbereich verlassen",
    group = "Gruppentraining beendet",
    cancel = "Vom Ausbilder abgebrochen",
    invalid = "Position ungültig",
    bar = "Klimmzugstange entfernt",
}

-- Gruppen-Netzwerk: Server -> Client
EoCSport.G_INVITE = 1
EoCSport.G_INVITE_END = 2
EoCSport.G_COUNTDOWN = 3
EoCSport.G_BEAT = 4
EoCSport.G_EARLY = 5
EoCSport.G_LIST = 6
EoCSport.G_RESULT = 7
EoCSport.G_LEADER_END = 8
EoCSport.G_PENALTY = 9
EoCSport.G_PENALTY_CLEAR = 10

-- Gruppen-Netzwerk: Client -> Server
EoCSport.GC_CREATE = 1
EoCSport.GC_BEAT = 2
EoCSport.GC_CANCEL = 3
EoCSport.GC_PENALTY = 4
EoCSport.GC_ABORT_ALL = 5

-- Teilnehmerstatus in der Gruppe
EoCSport.MemberStates = { "invited", "accepted", "active", "done", "aborted", "failed", "cancelled", "expired", "declined" }
EoCSport.MemberStateIds = {}
for i, name in ipairs(EoCSport.MemberStates) do EoCSport.MemberStateIds[name] = i end

EoCSport.MemberStateNames = {
    invited = "Eingeladen",
    accepted = "Angenommen",
    active = "Läuft",
    done = "Fertig",
    aborted = "Abgebrochen",
    failed = "Konnte nicht starten",
    cancelled = "Abgebrochen",
    expired = "Keine Antwort",
    declined = "Abgelehnt",
}

---------------------------------------------------------------------------
-- Übungen
---------------------------------------------------------------------------
function EoCSport.GetExercise(id)
    local ex = isstring(id) and EoCSport.Exercises[id]
    if not ex or ex.enabled == false then return nil end
    ex.id = id
    ex.mode = ex.mode or "reps"
    ex.duration = ex.duration or 1
    return ex
end

function EoCSport.GetExerciseList()
    local list = {}
    for id in pairs(EoCSport.Exercises) do
        local ex = EoCSport.GetExercise(id)
        if ex then list[#list + 1] = ex end
    end
    table.sort(list, function(a, b)
        local oa, ob = a.order or 100, b.order or 100
        if oa ~= ob then return oa < ob end
        return a.name < b.name
    end)
    return list
end

function EoCSport.FormatCount(ex, count, target)
    local suffix = ex and ex.mode == "hold" and " s" or ""
    if target and target > 0 then
        return count .. " / " .. target .. suffix
    end
    return count .. suffix
end

---------------------------------------------------------------------------
-- Rechte und Namen
---------------------------------------------------------------------------
local function lower(s)
    return string.lower(tostring(s or ""))
end

function EoCSport.IsAdmin(ply)
    if not IsValid(ply) then return false end
    if C.AdminGroups[lower(ply:GetUserGroup())] then return true end
    return ply:IsSuperAdmin()
end

function EoCSport.IsInstructor(ply)
    if not IsValid(ply) then return false end

    local custom = C.CustomInstructorCheck and C.CustomInstructorCheck(ply)
    if custom ~= nil then return custom == true end

    if C.InstructorGroups[lower(ply:GetUserGroup())] then return true end

    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    if job then
        if job.command and C.InstructorJobs[lower(job.command)] then return true end
        if job.name and C.InstructorJobs[lower(job.name)] then return true end
        if job.category and C.InstructorCategories[lower(job.category)] then return true end
    end

    return C.InstructorJobs[lower(team.GetName(ply:Team()))] == true
end

function EoCSport.GetName(ply)
    if not IsValid(ply) then return "?" end
    local name = C.CharacterName and C.CharacterName(ply)
    if isstring(name) and name ~= "" then return name end
    return ply:Nick()
end

---------------------------------------------------------------------------
-- Klimmzugstange und Bereiche
---------------------------------------------------------------------------
function EoCSport.BarDistance(bar, pos)
    local lp = bar:WorldToLocal(pos)
    local half = C.PullupBar.Length / 2
    local y = math.Clamp(lp.y, -half, half)
    return math.sqrt(lp.x * lp.x + (lp.y - y) * (lp.y - y))
end

function EoCSport.FindPullupBar(ply)
    local pos = ply:GetPos()
    local best, bestDist
    for _, bar in ipairs(ents.FindByClass("sport_pullup_bar")) do
        local user = bar:GetNW2Entity("EoCSport_User")
        if not IsValid(user) or user == ply then
            local d = EoCSport.BarDistance(bar, pos)
            if d <= C.PullupBar.Radius and (not bestDist or d < bestDist) then
                best, bestDist = bar, d
            end
        end
    end
    return best
end

for _, zone in ipairs(C.Zones or {}) do
    if zone.min and zone.max then OrderVectors(zone.min, zone.max) end
end

function EoCSport.InAllowedZone(pos)
    if not C.Zones or #C.Zones == 0 then return true end
    local map = game.GetMap()
    local anyForMap = false
    for _, zone in ipairs(C.Zones) do
        if not zone.map or zone.map == map then
            anyForMap = true
            if pos:WithinAABox(zone.min, zone.max) then return true end
        end
    end
    return not anyForMap
end

function EoCSport.IsActive(ply)
    return IsValid(ply) and ply:GetNW2Bool("EoCSport_Active", false)
end

---------------------------------------------------------------------------
-- Sperren während der Übung (vorhergesagt auf Client und Server)
---------------------------------------------------------------------------
local BLOCKED = bit.bor(IN_JUMP, IN_DUCK, IN_ATTACK, IN_ATTACK2, IN_SPEED, IN_WALK,
    IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT, IN_RELOAD)

hook.Add("SetupMove", "EoCSport_Lock", function(ply, mv)
    if not ply:GetNW2Bool("EoCSport_Active", false) then return end

    -- Beenden-Taste wird serverseitig aus den Bewegungsdaten gelesen,
    -- bevor sie für die Bewegung entfernt wird.
    if SERVER and mv:KeyPressed(C.EndKey) and EoCSport.OnEndKey then
        EoCSport.OnEndKey(ply)
    end

    mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(BLOCKED)))
    mv:SetForwardSpeed(0)
    mv:SetSideSpeed(0)
    mv:SetUpSpeed(0)

    local vel = mv:GetVelocity()
    mv:SetVelocity(Vector(0, 0, math.min(vel.z, 0)))
end)

hook.Add("StartCommand", "EoCSport_Lock", function(ply, cmd)
    if not ply:GetNW2Bool("EoCSport_Active", false) then return end
    cmd:RemoveKey(IN_ATTACK)
    cmd:RemoveKey(IN_ATTACK2)
end)

hook.Add("PlayerSwitchWeapon", "EoCSport_Lock", function(ply)
    if ply:GetNW2Bool("EoCSport_Active", false) then return true end
end)
