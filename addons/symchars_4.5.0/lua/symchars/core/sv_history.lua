--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Verlauf (Server): Spielzeit, Einheiten, Beförderungen, Akte
    Gespeichert in sc_history. Alte Dateien data/symchars/history/<id>.json werden beim ersten Laden übernommen.
-------------------------------------------------------------------------------------------------------------]]

local H = symchars.history
local C = symchars.chars
local DB = symchars.db
local Json, Unjson = symchars.net.Json, symchars.net.Unjson

local MAX_LOG = 150
local MAX_PROMOTIONS = 100
local MAX_SESSIONS = 400

local function Trim(history)
    local log = history.log and history.log.entries
    if istable(log) and #log > MAX_LOG then
        while #log > MAX_LOG do table.remove(log, 1) end
    end
    local promos = history.faction and history.faction.promotions
    if istable(promos) and #promos > MAX_PROMOTIONS then
        while #promos > MAX_PROMOTIONS do table.remove(promos, 1) end
    end
    local sessions = history.character and history.character.sessions
    if istable(sessions) and #sessions > MAX_SESSIONS then
        while #sessions > MAX_SESSIONS do table.remove(sessions, 1) end
    end
end

-- Lädt den Verlauf (async bei MySQL). callback(history)
function H.EnsureLoaded(charID, callback)
    local char = C.Get(charID)
    if not char then if callback then callback(nil) end return end
    if char._historyLoaded then
        if callback then callback(char.history) end
        return
    end

    DB.Query("SELECT data FROM sc_history WHERE charID = " .. DB.Num(charID), function(rows)
        local data
        if rows[1] and rows[1].data then
            data = Unjson(rows[1].data)
        else
            local path = "symchars/history/" .. charID .. ".json"
            if file.Exists(path, "DATA") then data = Unjson(file.Read(path, "DATA") or "") end
        end
        char.history = H.ApplyDefaults(data)
        char._historyLoaded = true
        if callback then callback(char.history) end
    end, function()
        char.history = H.ApplyDefaults(nil)
        char._historyLoaded = true
        if callback then callback(char.history) end
    end)
end

function H.Save(charID)
    local char = C.Get(charID)
    if not char or not char._historyLoaded then return end
    Trim(char.history)
    DB.Replace("sc_history", { "charID", "data" }, { DB.Num(charID), DB.Str(Json(char.history)) })
end

-- Sendet an den Besitzer und alle, die die Akte gerade angefordert haben
function H.Sync(charID, ply)
    local char = C.Get(charID)
    if not char or not char._historyLoaded then return end
    local targets = {}
    if IsValid(ply) then
        targets[1] = ply
    else
        local owner = C.OnlinePlayer(char)
        if IsValid(owner) then targets[#targets + 1] = owner end
        for p, untilTime in pairs(char._historyWatchers or {}) do
            if IsValid(p) and untilTime > CurTime() and p ~= owner then targets[#targets + 1] = p end
        end
    end
    if #targets == 0 then return end
    symchars.net.Send("history", { id = charID, history = char.history }, targets)
end

function H.LoadAndSync(charID, ply)
    H.EnsureLoaded(charID, function() H.Sync(charID, ply) end)
end

local function Mutate(charID, fn)
    H.EnsureLoaded(charID, function(history)
        if not history then return end
        fn(history)
        H.Save(charID)
        H.Sync(charID)
    end)
end

function H.Set(charID, category, index, value)
    Mutate(charID, function(history)
        history[category] = history[category] or {}
        if category == "character" and index == "sessions" then
            history[category][index] = H.NormalizeSessions(value)
        else
            history[category][index] = symchars.util.Copy(value)
        end
    end)
end

function H.Add(charID, category, index, value)
    if category == "character" and index == "sessions" then return H.Set(charID, category, index, value) end
    Mutate(charID, function(history)
        history[category] = history[category] or {}
        local current = history[category][index]
        local template = H._filelist[category] and H._filelist[category][index]
        if istable(template) or istable(current) then
            if not istable(current) then current = {} end
            if istable(value) and value.entry ~= nil then
                value = table.Copy(value)
                value.timestamp = tonumber(value.timestamp) or os.time()
                current[#current + 1] = value
            else
                current[#current + 1] = { entry = symchars.util.Copy(value), timestamp = os.time() }
            end
            history[category][index] = current
        else
            history[category][index] = symchars.util.Copy(value)
        end
    end)
end

-- Eintrag in die Akte
function H.Log(charID, kind, text, by)
    Mutate(charID, function(history)
        history.log = history.log or {}
        history.log.entries = history.log.entries or {}
        table.insert(history.log.entries, { entry = tostring(text or ""), kind = kind or "info", by = by or "", timestamp = os.time() })
    end)
end

---------------------------------------------------------------------------------------------------------------
-- Spielzeit
---------------------------------------------------------------------------------------------------------------
local SAVE_INTERVAL = 300

local function AddSession(char, seconds, endTime)
    if seconds <= 0 then return end
    Mutate(char.charID, function(history)
        local data = H.NormalizeSessions(history.character.sessions)
        local cur = endTime - seconds
        while cur < endTime do
            local day = H.DayStamp(cur)
            local chunkEnd = math.min(endTime, day + 86400)
            local found
            for _, v in ipairs(data) do if v.x == day then found = v break end end
            if not found then found = { x = day, y = 0 } data[#data + 1] = found end
            found.y = found.y + (chunkEnd - cur) / 3600
            cur = chunkEnd
        end
        table.sort(data, function(a, b) return a.x < b.x end)
        history.character.sessions = data
    end)
end

local CHAR = C.Meta()

function CHAR:StartSession()
    if self._sessionStart then return end
    self._sessionStart = os.time()
    self._sessionSaved = self._sessionStart
end

function CHAR:SaveSession(force)
    if not self._sessionStart then return end
    local now = os.time()
    local elapsed = now - (self._sessionSaved or now)
    if elapsed <= 0 or (not force and elapsed < SAVE_INTERVAL) then return end
    AddSession(self, elapsed, now)
    self._sessionSaved = now
end

function CHAR:EndSession()
    if not self._sessionStart then return end
    self:SaveSession(true)
    self._sessionStart, self._sessionSaved = nil, nil
end

function CHAR:GetSessions()
    return H.NormalizeSessions(H.Get(self.charID, "character", "sessions") or {})
end

timer.Create("symchars_session_save", 60, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        local char = ply:GetCharacter()
        if char then char:SaveSession(false) end
    end
end)

hook.Add("symchars_selectedcharacter", "symchars_sessions", function(ply, char, old)
    if old then old:EndSession() end
    if char then char:StartSession() end
end)

hook.Add("PlayerDisconnected", "symchars_sessions", function(ply)
    local char = ply:GetCharacter()
    if char then char:EndSession() end
end)

hook.Add("ShutDown", "symchars_sessions", function()
    for _, ply in ipairs(player.GetAll()) do
        local char = ply:GetCharacter()
        if char then char:EndSession() end
    end
end)

---------------------------------------------------------------------------------------------------------------
-- Anfragen (Akte ansehen)
---------------------------------------------------------------------------------------------------------------
symchars.net.Receive("history_request", function(ply, data)
    local char = C.Get(istable(data) and data.id)
    if not char then return end
    local own = tostring(char.charUser) == ply:SteamID64()
    local actor = ply:GetCharacter()
    local allowed = own or symchars.HasPriv(ply, "symchars_charmanage")
    if not allowed and actor and char:GetFaction() then
        for _, f in ipairs(symchars.factions.FLAGS) do
            if symchars.authority.HasFlag(actor, char.faction, f.id) then allowed = true break end
        end
        -- Mitglieder derselben Einheit dürfen die Akte ebenfalls sehen
        if not allowed and actor.faction == char.faction then allowed = true end
    end
    if not allowed then return end

    char._historyWatchers = char._historyWatchers or {}
    char._historyWatchers[ply] = CurTime() + 120
    H.LoadAndSync(char.charID, ply)
end, 0.3)
