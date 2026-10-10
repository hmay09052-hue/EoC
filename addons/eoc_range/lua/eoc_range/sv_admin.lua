--[[
    EoC Range – Ausbilder-Menü (Server), Prüfungen, Protokoll, Speichern der Entities pro Map

    !range im Chat oder range_admin in der Konsole öffnet das Menü.
    range_save / range_load / range_clear (Superadmin) speichern, laden und entfernen alle Schießstand-Entities der Map.
]]

local C = EoCRange.Config
local DB = EoCRange.DB

---------------------------------------------------------------------------
-- Protokoll: data/eoc_range/logs/JJJJ-MM-TT.txt
---------------------------------------------------------------------------
function EoCRange.Log(actor, action, text)
    local who = IsValid(actor) and (actor:Nick() .. " (" .. actor:SteamID() .. ")") or "System"
    local line = os.date("%H:%M:%S") .. " [" .. action .. "] " .. who .. ": " .. tostring(text)
    file.Append("eoc_range/logs/" .. os.date("%Y-%m-%d") .. ".txt", line .. "\n")
    MsgC(Color(255, 190, 50), "[EoC Range] ", color_white, line .. "\n")
end

local function ReadLogs(days, max)
    local out = {}
    for d = 0, days - 1 do
        local day = os.date("%Y-%m-%d", os.time() - d * 86400)
        local raw = file.Read("eoc_range/logs/" .. day .. ".txt", "DATA")
        if raw then
            local lines = string.Explode("\n", raw)
            for i = #lines, 1, -1 do
                if lines[i] ~= "" then
                    out[#out + 1] = day .. " " .. lines[i]
                    if #out >= max then return out end
                end
            end
        end
    end
    return out
end

---------------------------------------------------------------------------
-- Entities speichern und laden (wie bei ShipTech)
---------------------------------------------------------------------------
local RUNTIME_VARS = { Up = true, FlipAt = true, Moving = true, RailStart = true }

local function MapFile()
    return "eoc_range/maps/" .. game.GetMap() .. ".json"
end

function EoCRange.SaveEntities()
    local list = {}
    for _, e in ipairs(ents.FindByClass("range_*")) do
        if e.IsEoCRange and e:GetClass() ~= "range_base" then
            local vars = {}
            for k, v in pairs(e:GetNetworkVars() or {}) do
                if not RUNTIME_VARS[k] then vars[k] = v end
            end
            list[#list + 1] = { c = e:GetClass(), p = e.GetPersistPos and e:GetPersistPos() or e:GetPos(), a = e:GetAngles(), v = vars }
        end
    end
    local json = util.TableToJSON(list, true)
    file.Write(MapFile(), json)
    DB.SaveLanes(game.GetMap(), json)
    return #list
end

function EoCRange.ClearEntities()
    for _, run in pairs(EoCRange.Runs) do EoCRange.FinishRun(run, true, "Schießstand wird neu geladen.") end
    for _, e in ipairs(ents.FindByClass("range_*")) do
        if e.IsEoCRange then e:Remove() end
    end
end

local function SpawnFromList(list)
    EoCRange.ClearEntities()
    local n = 0
    for _, d in ipairs(list or {}) do
        if isstring(d.c) and string.sub(d.c, 1, 6) == "range_" and scripted_ents.GetStored(d.c) then
            local e = ents.Create(d.c)
            if IsValid(e) then
                e:SetPos(d.p)
                e:SetAngles(d.a)
                for k, v in pairs(d.v or {}) do
                    local setter = e["Set" .. k]
                    if setter and not RUNTIME_VARS[k] then setter(e, v) end
                end
                e:Spawn()
                e:Activate()
                n = n + 1
            end
        end
    end
    EoCRange.UpdateAllLaneDisplays()
    return n
end

function EoCRange.LoadEntities(cb)
    local raw = file.Read(MapFile(), "DATA")
    if raw then
        local n = SpawnFromList(util.JSONToTable(raw))
        if cb then cb(n) end
        return
    end
    DB.LoadLanes(game.GetMap(), function(json)
        local n = json and SpawnFromList(util.JSONToTable(json)) or 0
        if cb then cb(n) end
    end)
end

hook.Add("InitPostEntity", "EoCRange_Load", function()
    timer.Simple(3, function()
        EoCRange.LoadEntities(function(n)
            if n > 0 then MsgC(Color(255, 190, 50), "[EoC Range] ", color_white, n .. " Schießstand-Entities geladen.\n") end
        end)
    end)
end)

hook.Add("PostCleanupMap", "EoCRange_Load", function()
    timer.Simple(1, function() EoCRange.LoadEntities() end)
end)

local function SuperCmd(name, fn)
    concommand.Add(name, function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        fn(function(msg)
            if IsValid(ply) then EoCRange.Notify(ply, msg, 2) end
            print("[EoC Range] " .. msg)
        end, ply)
    end)
end

SuperCmd("range_save", function(reply, ply)
    local n = EoCRange.SaveEntities()
    EoCRange.Log(ply, "Speichern", n .. " Entities auf " .. game.GetMap())
    reply(n .. " Schießstand-Entities gespeichert (" .. game.GetMap() .. ").")
end)

SuperCmd("range_load", function(reply, ply)
    EoCRange.LoadEntities(function(n)
        EoCRange.Log(ply, "Laden", n .. " Entities auf " .. game.GetMap())
        reply(n .. " Schießstand-Entities geladen.")
    end)
end)

SuperCmd("range_clear", function(reply, ply)
    EoCRange.ClearEntities()
    EoCRange.Log(ply, "Entfernen", "alle Entities auf " .. game.GetMap())
    reply("Alle Schießstand-Entities entfernt (gespeicherter Stand bleibt).")
end)

---------------------------------------------------------------------------
-- Menü öffnen
---------------------------------------------------------------------------
EoCRange.Exams = EoCRange.Exams or {}   -- SteamID des Ausbilders -> Prüfung

local function LanesPayload()
    local out = {}
    for _, t in ipairs(EoCRange.Terminals()) do
        local lane = t:GetLane()
        local info = EoCRange.LaneInfo(lane)
        local run = EoCRange.LaneRuns[lane]
        out[#out + 1] = {
            lane = lane, locked = info.locked or false, lockReason = info.lockReason or "", lockedBy = info.lockedBy or "",
            reserved = info.reservedName or "", reservedSid = info.reserved or "", exam = info.examBy or "",
            busy = run and (run.shooterName .. " – " .. run.def.name) or "",
            disciplines = t:GetDisciplines(),
        }
    end
    return out
end

local function PlayersPayload()
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        local info = EoCRange.CharInfo(p)
        out[#out + 1] = { uid = p:UserID(), sid = p:SteamID(), name = info.name, unit = info.unitName, badge = EoCRange.BadgeCache[info.id] or 0 }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

local function ExamPayload(exam)
    if not exam then return nil end
    local cands = {}
    for _, c in ipairs(exam.candidates) do
        cands[#cands + 1] = { sid = c.sid, name = c.name, unit = c.unit, badge = EoCRange.BadgeCache[c.charId] or 0, results = c.results,
            online = IsValid(c.ply) }
    end
    return { lane = exam.lane, candidates = cands, disciplines = C.ExamDisciplines, current = exam.current, instructor = exam.instructorName }
end

function EoCRange.SendMenu(ply, tab)
    if not IsValid(ply) then return end
    EoCRange.Send("menu", {
        tab = tab,
        role = { instructor = EoCRange.IsInstructor(ply), admin = EoCRange.IsAdmin(ply), superadmin = ply:IsSuperAdmin() },
        lanes = LanesPayload(),
        players = EoCRange.IsInstructor(ply) and PlayersPayload() or {},
        exam = ExamPayload(EoCRange.Exams[ply:SteamID()]),
        settings = EoCRange.SettingsTable(),
        map = game.GetMap(),
        trophy = GetGlobal2String("EoCR_TrophyName", ""),
    }, ply)
end

local function PushExam(exam)
    if not exam then return end
    local payload = ExamPayload(exam)
    if IsValid(exam.instructor) then EoCRange.Send("exam", payload, exam.instructor) end
end

concommand.Add("range_admin", function(ply)
    if IsValid(ply) then EoCRange.SendMenu(ply) end
end)

hook.Add("PlayerSay", "EoCRange_Chat", function(ply, text)
    local t = string.lower(string.Trim(text))
    if t == "!range" or t == "/range" then
        EoCRange.SendMenu(ply)
        return ""
    end
end)

EoCRange.Receive("menu", function(ply, data) EoCRange.SendMenu(ply, data.tab) end, 0.5)

---------------------------------------------------------------------------
-- Bahnen reservieren / sperren
---------------------------------------------------------------------------
EoCRange.Receive("lane", function(ply, data)
    if not EoCRange.IsInstructor(ply) then return end
    local lane = math.floor(tonumber(data.lane) or 0)
    if not IsValid(EoCRange.TerminalForLane(lane)) then return end
    local info = EoCRange.LaneInfo(lane)
    local reason = EoCRange.Clean(data.reason, 120)
    local name = EoCRange.CharInfo(ply).name
    local action = data.action

    if action == "reserve" then
        info.reserved, info.reservedName = ply:SteamID(), name
        EoCRange.Log(ply, "Reservierung", "Bahn " .. lane .. " reserviert" .. (reason ~= "" and (" – " .. reason) or ""))
    elseif action == "release" then
        if info.reserved and info.reserved ~= ply:SteamID() and not EoCRange.IsAdmin(ply) then
            EoCRange.Notify(ply, "Diese Reservierung gehört " .. (info.reservedName or "jemand anderem") .. ".", 1)
            return
        end
        info.reserved, info.reservedName = nil, nil
        EoCRange.Log(ply, "Reservierung", "Bahn " .. lane .. " freigegeben")
    elseif action == "lock" then
        info.locked, info.lockReason, info.lockedBy = true, reason, name
        local run = EoCRange.LaneRuns[lane]
        if run then EoCRange.FinishRun(run, true, "Bahn wurde gesperrt.") end
        EoCRange.Log(ply, "Sperre", "Bahn " .. lane .. " gesperrt" .. (reason ~= "" and (" – " .. reason) or ""))
    elseif action == "unlock" then
        info.locked, info.lockReason, info.lockedBy = nil, nil, nil
        EoCRange.Log(ply, "Sperre", "Bahn " .. lane .. " entsperrt")
    elseif action == "abort" then
        local run = EoCRange.LaneRuns[lane]
        if run then
            EoCRange.FinishRun(run, true, "Von " .. name .. " abgebrochen.")
            EoCRange.Log(ply, "Abbruch", "Lauf auf Bahn " .. lane .. " abgebrochen")
        end
    else
        return
    end
    EoCRange.UpdateLaneDisplay(lane)
    EoCRange.SendMenu(ply, "lanes")
end, 0.3)

---------------------------------------------------------------------------
-- Prüfungsmodus
---------------------------------------------------------------------------
local function FindCandidate(exam, sid)
    for _, c in ipairs(exam.candidates) do
        if c.sid == sid then return c end
    end
end

local function AddCandidate(exam, p)
    if not IsValid(p) or FindCandidate(exam, p:SteamID()) then return end
    local info = EoCRange.CharInfo(p)
    table.insert(exam.candidates, { sid = p:SteamID(), ply = p, name = info.name, unit = info.unitName, charId = info.id, results = {} })
end

local function EndExam(exam)
    EoCRange.Exams[exam.instructorSid] = nil
    local info = EoCRange.LaneInfo(exam.lane)
    if info.exam == exam then info.exam, info.examBy = nil, nil end
    EoCRange.UpdateLaneDisplay(exam.lane)
end

EoCRange.Receive("exam_start", function(ply, data)
    if not EoCRange.IsInstructor(ply) then return end
    if EoCRange.Exams[ply:SteamID()] then
        EoCRange.Notify(ply, "Du hast bereits eine laufende Prüfung.", 1)
        return
    end
    local lane = math.floor(tonumber(data.lane) or 0)
    local term = EoCRange.TerminalForLane(lane)
    if not IsValid(term) then return end
    local info = EoCRange.LaneInfo(lane)
    if info.exam then
        EoCRange.Notify(ply, "Auf Bahn " .. lane .. " läuft bereits eine Prüfung (" .. (info.examBy or "?") .. ").", 1)
        return
    end
    if info.locked then
        EoCRange.Notify(ply, "Bahn " .. lane .. " ist gesperrt.", 1)
        return
    end

    local exam = {
        instructor = ply, instructorSid = ply:SteamID(), instructorName = EoCRange.CharInfo(ply).name,
        lane = lane, terminal = term, candidates = {}, created = os.time(),
    }
    for _, uid in ipairs(istable(data.candidates) and data.candidates or {}) do
        local p = Player(tonumber(uid) or 0)
        if IsValid(p) and p ~= ply then AddCandidate(exam, p) end
    end
    if #exam.candidates == 0 then
        EoCRange.Notify(ply, "Wähle mindestens einen Kandidaten.", 1)
        return
    end

    EoCRange.Exams[ply:SteamID()] = exam
    info.exam, info.examBy = exam, exam.instructorName
    EoCRange.UpdateLaneDisplay(lane)
    local names = {}
    for _, c in ipairs(exam.candidates) do
        names[#names + 1] = c.name
        if IsValid(c.ply) then
            EoCRange.Notify(c.ply, exam.instructorName .. " nimmt dir die Schießprüfung auf Bahn " .. lane .. " ab.", 0)
        end
    end
    EoCRange.Log(ply, "Prüfung", "Prüfung auf Bahn " .. lane .. " gestartet: " .. table.concat(names, ", "))
    EoCRange.SendMenu(ply, "exam")
end, 1)

EoCRange.Receive("exam_add", function(ply, data)
    local exam = EoCRange.Exams[ply:SteamID()]
    if not exam then return end
    local p = Player(tonumber(data.uid) or 0)
    if IsValid(p) and p ~= ply then AddCandidate(exam, p) end
    PushExam(exam)
end, 0.3)

EoCRange.Receive("exam_remove", function(ply, data)
    local exam = EoCRange.Exams[ply:SteamID()]
    if not exam then return end
    for i, c in ipairs(exam.candidates) do
        if c.sid == data.sid then table.remove(exam.candidates, i) break end
    end
    PushExam(exam)
end, 0.3)

EoCRange.Receive("exam_run", function(ply, data)
    local exam = EoCRange.Exams[ply:SteamID()]
    if not exam then return end
    local cand = FindCandidate(exam, data.sid)
    local disc = tostring(data.disc or "")
    if not cand or not EoCRange.InList(C.ExamDisciplines, disc) then return end
    if not IsValid(cand.ply) then
        EoCRange.Notify(ply, cand.name .. " ist nicht online.", 1)
        return
    end
    local cell = cand.results[disc]
    if cell and cell.status == "confirmed" then
        EoCRange.Notify(ply, "Dieser Lauf ist bereits bestätigt. Erst verwerfen, um ihn zu wiederholen.", 1)
        return
    end
    if not IsValid(exam.terminal) then exam.terminal = EoCRange.TerminalForLane(exam.lane) end
    local ok = EoCRange.StartRun(cand.ply, exam.terminal, disc, { exam = exam })
    if ok then
        exam.current = { sid = cand.sid, disc = disc }
        cand.results[disc] = { status = "live" }
        PushExam(exam)
    end
end, 1)

-- Aufruf aus sv_core, wenn ein Prüfungslauf fertig ist
function EoCRange.ExamRecord(run, p, payload)
    local exam = run.exam
    local cand = exam and FindCandidate(exam, p:SteamID())
    if not cand then return end
    local value = EoCRange.BadgeValue(run.def.id, payload)
    cand.results[run.def.id] = {
        status = "done", runId = payload.runId, value = value, text = payload.valueText,
        level = EoCRange.LevelFor(run.def.id, value), flagged = payload.flagged or false,
        hits = payload.hits, accuracy = payload.accuracy,
    }
    exam.current = nil
    PushExam(exam)
end

function EoCRange.ExamRunAborted(run, reason)
    local exam = run.exam
    for _, p in ipairs(run.players) do
        local cand = IsValid(p) and FindCandidate(exam, p:SteamID())
        if cand then cand.results[run.def.id] = { status = "aborted", note = reason } end
    end
    exam.current = nil
    PushExam(exam)
end

local function AfterRunChange(charId, discId, cb)
    DB.RecomputeBest(charId, discId, function()
        DB.RefreshDiscipline(discId, function()
            EoCRange.BroadcastBoard(discId)
            if cb then cb() end
        end)
    end)
end

EoCRange.Receive("exam_confirm", function(ply, data)
    local exam = EoCRange.Exams[ply:SteamID()]
    local cand = exam and FindCandidate(exam, data.sid)
    local cell = cand and cand.results[data.disc]
    if not cell or cell.status ~= "done" then return end
    cell.status = "confirmed"
    EoCRange.Log(ply, "Prüfung", "Lauf bestätigt: " .. cand.name .. " – " .. tostring(data.disc) .. " – " .. tostring(cell.text))
    PushExam(exam)
end, 0.3)

EoCRange.Receive("exam_discard", function(ply, data)
    local exam = EoCRange.Exams[ply:SteamID()]
    local cand = exam and FindCandidate(exam, data.sid)
    local cell = cand and cand.results[data.disc]
    if not cell or (cell.status ~= "done" and cell.status ~= "confirmed") then return end
    local reason = EoCRange.Clean(data.reason, 120)
    if cell.runId then
        DB.DeleteRun(cell.runId, function() AfterRunChange(cand.charId, data.disc) end)
    end
    EoCRange.Log(ply, "Prüfung", "Lauf verworfen: " .. cand.name .. " – " .. tostring(data.disc) .. " – " .. tostring(cell.text)
        .. (reason ~= "" and (" – Grund: " .. reason) or ""))
    cand.results[data.disc] = { status = "pending", note = "verworfen" }
    PushExam(exam)
end, 0.3)

EoCRange.Receive("exam_finish", function(ply)
    local exam = EoCRange.Exams[ply:SteamID()]
    if not exam then return end
    if EoCRange.LaneRuns[exam.lane] and EoCRange.LaneRuns[exam.lane].exam == exam then
        EoCRange.Notify(ply, "Warte, bis der laufende Prüfungslauf beendet ist.", 1)
        return
    end
    local lines = {}
    for _, c in ipairs(exam.candidates) do
        local level, complete = 3, true
        for _, disc in ipairs(C.ExamDisciplines) do
            local cell = c.results[disc]
            if not cell or cell.status ~= "confirmed" then
                complete = false
            else
                level = math.min(level, cell.level or 0)
            end
        end
        local current = EoCRange.BadgeCache[c.charId] or 0
        if not complete then
            lines[#lines + 1] = c.name .. ": unvollständig"
        elseif level < 1 then
            lines[#lines + 1] = c.name .. ": nicht bestanden"
        elseif level <= current then
            lines[#lines + 1] = c.name .. ": " .. EoCRange.BadgeName(level) .. " erreicht (hat bereits " .. EoCRange.BadgeName(current) .. ")"
        else
            lines[#lines + 1] = c.name .. ": " .. EoCRange.BadgeName(level) .. " vergeben"
            EoCRange.AwardBadge(c.charId, c.sid, c.name, level, ply)
        end
        if IsValid(c.ply) then
            EoCRange.Notify(c.ply, "Schießprüfung beendet – " .. lines[#lines]:gsub("^[^:]+: ", ""), level >= 1 and complete and 2 or 0)
        end
    end
    EoCRange.Log(ply, "Prüfung", "Prüfung auf Bahn " .. exam.lane .. " abgeschlossen: " .. table.concat(lines, "; "))
    EndExam(exam)
    EoCRange.Send("examdone", { lines = lines }, ply)
    EoCRange.SendMenu(ply, "exam")
end, 1)

EoCRange.Receive("exam_cancel", function(ply)
    local exam = EoCRange.Exams[ply:SteamID()]
    if not exam then return end
    local run = EoCRange.LaneRuns[exam.lane]
    if run and run.exam == exam then EoCRange.FinishRun(run, true, "Prüfung abgebrochen.") end
    EoCRange.Log(ply, "Prüfung", "Prüfung auf Bahn " .. exam.lane .. " abgebrochen")
    EndExam(exam)
    EoCRange.SendMenu(ply, "exam")
end, 1)

hook.Add("PlayerDisconnected", "EoCRange_Exam", function(ply)
    local exam = EoCRange.Exams[ply:SteamID()]
    if exam then
        EoCRange.Log(ply, "Prüfung", "Prüfung auf Bahn " .. exam.lane .. " beendet (Ausbilder getrennt)")
        EndExam(exam)
    end
end)

---------------------------------------------------------------------------
-- Eigene Disziplinen
---------------------------------------------------------------------------
local function SyncCustoms()
    local customs = {}
    for id, d in pairs(EoCRange.Custom) do customs[id] = d end
    EoCRange.Send("customs", { customs = customs })
end

EoCRange.Receive("disc_save", function(ply, data)
    if not EoCRange.IsInstructor(ply) then return end
    local raw = istable(data.raw) and data.raw or {}
    local id = tostring(data.id or "")
    local existing = EoCRange.Custom[id]
    if existing then
        if existing.createdBy ~= ply:SteamID() and not EoCRange.IsAdmin(ply) then
            EoCRange.Notify(ply, "Nur der Ersteller oder ein Admin darf diese Disziplin ändern.", 1)
            return
        end
    else
        local count = table.Count(EoCRange.Custom)
        if count >= 64 then
            EoCRange.Notify(ply, "Zu viele eigene Disziplinen (max. 64).", 1)
            return
        end
        id = "c_" .. os.time() .. math.random(10, 99)
    end
    raw.createdBy = existing and existing.createdBy or ply:SteamID()
    local def = EoCRange.NormalizeCustom(raw, id)
    if EoCRange.Clean(raw.name, 40) == "" then
        EoCRange.Notify(ply, "Die Disziplin braucht einen Namen.", 1)
        return
    end
    raw.id = nil
    DB.SaveCustom(id, raw, ply:SteamID(), function()
        EoCRange.Custom[id] = def
        SyncCustoms()
        DB.RefreshDiscipline(id, function() EoCRange.BroadcastBoard(id) end)
        EoCRange.Log(ply, "Disziplin", (existing and "geändert: " or "angelegt: ") .. def.name .. " (" .. id .. ")")
        EoCRange.Notify(ply, "Disziplin '" .. def.name .. "' gespeichert.", 2)
    end)
end, 1)

EoCRange.Receive("disc_delete", function(ply, data)
    local def = EoCRange.Custom[tostring(data.id or "")]
    if not def or not EoCRange.IsInstructor(ply) then return end
    if def.createdBy ~= ply:SteamID() and not EoCRange.IsAdmin(ply) then
        EoCRange.Notify(ply, "Nur der Ersteller oder ein Admin darf diese Disziplin löschen.", 1)
        return
    end
    DB.DeleteCustom(def.id, function()
        EoCRange.Custom[def.id] = nil
        EoCRange.Boards[def.id] = nil
        SyncCustoms()
        EoCRange.Log(ply, "Disziplin", "gelöscht: " .. def.name .. " (" .. def.id .. ")")
    end)
end, 1)

---------------------------------------------------------------------------
-- Ergebnisse, Freigabe, Löschen
---------------------------------------------------------------------------
EoCRange.Receive("results", function(ply, data)
    if not EoCRange.IsInstructor(ply) then return end
    local admin = EoCRange.IsAdmin(ply)
    DB.ListRuns({
        discipline = data.discipline, flagged = data.flagged == true, exam = data.exam == true,
        instructor_sid = data.mine and ply:SteamID() or nil, search = EoCRange.Clean(data.search, 40), limit = 150,
    }, function(rows)
        for _, r in ipairs(rows) do
            r.canDelete = admin or (r.exam == 1 and r.instructor_sid == ply:SteamID())
            r.canApprove = admin and r.flagged == 1
        end
        EoCRange.Send("results", { rows = rows, admin = admin }, ply)
    end)
end, 0.5)

EoCRange.Receive("result_delete", function(ply, data)
    if not EoCRange.IsInstructor(ply) then return end
    local reason = EoCRange.Clean(data.reason, 120)
    if reason == "" then
        EoCRange.Notify(ply, "Bitte einen Grund angeben.", 1)
        return
    end
    DB.GetRun(tonumber(data.id) or 0, function(r)
        if not r then return end
        local allowed = EoCRange.IsAdmin(ply) or (r.exam == 1 and r.instructor_sid == ply:SteamID())
        if not allowed then
            EoCRange.Notify(ply, "Du darfst nur Ergebnisse aus deinen eigenen Prüfungen löschen.", 1)
            return
        end
        DB.DeleteRun(r.id, function()
            AfterRunChange(r.char_id, r.discipline)
            EoCRange.Log(ply, "Löschung", "Lauf #" .. r.id .. " gelöscht: " .. r.name .. " – " .. r.discipline .. " – " .. r.score .. " – Grund: " .. reason)
            EoCRange.Notify(ply, "Lauf #" .. r.id .. " gelöscht.", 2)
        end)
    end)
end, 0.5)

EoCRange.Receive("result_approve", function(ply, data)
    if not EoCRange.IsAdmin(ply) then return end
    DB.GetRun(tonumber(data.id) or 0, function(r)
        if not r or r.flagged ~= 1 then return end
        DB.SetFlag(r.id, 0, function()
            AfterRunChange(r.char_id, r.discipline)
            EoCRange.Log(ply, "Freigabe", "Lauf #" .. r.id .. " geprüft und gewertet: " .. r.name .. " – " .. r.discipline .. " – " .. r.score)
            EoCRange.Notify(ply, "Lauf #" .. r.id .. " freigegeben.", 2)
        end)
    end)
end, 0.5)

---------------------------------------------------------------------------
-- Abzeichen ansehen / entziehen
---------------------------------------------------------------------------
EoCRange.Receive("badges", function(ply, data)
    if not EoCRange.IsInstructor(ply) then return end
    DB.ListBadges(EoCRange.Clean(data.search, 40), function(rows)
        EoCRange.Send("badges", { rows = rows }, ply)
    end)
end, 0.5)

EoCRange.Receive("badge_revoke", function(ply, data)
    if not EoCRange.IsInstructor(ply) then return end
    local reason = EoCRange.Clean(data.reason, 200)
    if reason == "" then
        EoCRange.Notify(ply, "Ein Abzeichen kann nur mit Begründung entzogen werden.", 1)
        return
    end
    DB.Query("SELECT * FROM eocr_badges WHERE id = " .. DB.Num(tonumber(data.id) or 0), function(rows)
        local b = rows[1] and DB.Row(rows[1])
        if not b or b.revoked == 1 then return end
        EoCRange.RevokeBadge(b, ply, reason)
        EoCRange.Notify(ply, "Abzeichen entzogen.", 2)
    end)
end, 1)

---------------------------------------------------------------------------
-- Einstellungen (Admin)
---------------------------------------------------------------------------
EoCRange.Receive("settings_save", function(ply, data)
    if not EoCRange.IsAdmin(ply) then return end
    EoCRange.ApplySettings(data)
    EoCRange.SaveSettings()
    EoCRange.Send("settings", EoCRange.SettingsTable())
    EoCRange.UpdateAllLaneDisplays()
    EoCRange.Log(ply, "Einstellungen", util.TableToJSON(EoCRange.SettingsTable()))
    EoCRange.Notify(ply, "Einstellungen gespeichert.", 2)
end, 1)

EoCRange.Receive("board_reset", function(ply, data)
    if not EoCRange.IsAdmin(ply) then return end
    local disc = EoCRange.GetDiscipline(data.disc) and data.disc or nil
    local period = EoCRange.PeriodNames[data.period] and data.period or "all"
    DB.ResetBoard(disc, period, function()
        DB.RefreshAll(function()
            EoCRange.SendInit()
            for id, set in pairs(EoCRange.BestCache) do EoCRange.BestCache[id] = nil end
        end)
        EoCRange.Log(ply, "Rücksetzung", "Rangliste " .. (disc or "alle Disziplinen") .. " – " .. EoCRange.PeriodNames[period])
        EoCRange.Notify(ply, "Rangliste zurückgesetzt.", 2)
    end)
end, 2)

EoCRange.Receive("logs", function(ply)
    if not EoCRange.IsInstructor(ply) then return end
    EoCRange.Send("logs", { lines = ReadLogs(7, 300) }, ply)
end, 1)

EoCRange.Receive("save_entities", function(ply)
    if not ply:IsSuperAdmin() then return end
    local n = EoCRange.SaveEntities()
    EoCRange.Log(ply, "Speichern", n .. " Entities auf " .. game.GetMap())
    EoCRange.Notify(ply, n .. " Schießstand-Entities gespeichert.", 2)
end, 2)
