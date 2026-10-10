--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Verlauf eines Charakters (Spielzeit, Einheitenwechsel, Beförderungen, Akte)
    Kompatibel zum alten Format (data/symchars/history/<id>.json wird beim ersten Laden übernommen)
-------------------------------------------------------------------------------------------------------------]]

symchars.history = symchars.history or {}

local H = symchars.history

H._filelist = H._filelist or {}
H._pendingRequests = H._pendingRequests or {}

local function DayStamp(ts)
    ts = tonumber(ts)
    if not ts then return nil end
    local d = os.date("*t", ts)
    if not d then return nil end
    return os.time({ year = d.year, month = d.month, day = d.day, hour = 0, min = 0, sec = 0 })
end
H.DayStamp = DayStamp

function H.NormalizeSessions(data)
    local days = {}
    local function ingest(value)
        if not istable(value) then return end
        local stamp = DayStamp(value.x)
        if stamp then
            days[stamp] = (days[stamp] or 0) + (tonumber(value.y) or 0)
            return
        end
        if value.entry ~= nil then ingest(value.entry) return end
        for _, v in pairs(value) do
            if istable(v) then ingest(v) end
        end
    end
    ingest(data)
    local out = {}
    for stamp, hours in pairs(days) do out[#out + 1] = { x = stamp, y = hours } end
    table.sort(out, function(a, b) return a.x < b.x end)
    return out
end

function H.RegisterCategory(index)
    H._filelist[index] = H._filelist[index] or {}
end

function H.CreateValue(category, index, default)
    H._filelist[category] = H._filelist[category] or {}
    H._filelist[category][index] = default ~= nil and symchars.util.Copy(default) or ""
end

function H.BuildDefault()
    local data = {}
    for category, values in pairs(H._filelist) do data[category] = table.Copy(values) end
    return data
end

function H.ApplyDefaults(data)
    local merged = H.BuildDefault()
    if not istable(data) then return merged end
    for category, values in pairs(data) do
        if istable(values) and istable(merged[category]) then
            for index, value in pairs(values) do merged[category][index] = symchars.util.Copy(value) end
        else
            merged[category] = symchars.util.Copy(values)
        end
    end
    merged.character = merged.character or {}
    merged.character.sessions = H.NormalizeSessions(merged.character.sessions)
    return merged
end

function H.Get(id, category, index)
    local char = symchars.chars.Get(id)
    if not char then return nil end
    char.history = H.ApplyDefaults(char.history)
    if category == nil then return char.history end
    local cat = char.history[category]
    if cat == nil then return nil end
    if index == nil then return cat end
    return cat[index]
end

function H.TotalHours(id)
    local total = 0
    for _, v in ipairs(H.Get(id, "character", "sessions") or {}) do total = total + (tonumber(v.y) or 0) end
    return total
end

H.RegisterCategory("character")
H.CreateValue("character", "sessions", {})

H.RegisterCategory("faction")
H.CreateValue("faction", "last_promote", "none")
H.CreateValue("faction", "promotions", {})
H.CreateValue("faction", "joined", "none")
H.CreateValue("faction", "faction_history", {})

-- Akte: { { entry = "Text", timestamp = os.time(), by = "Name", kind = "rank" | "unit" | "training" | "info" } }
H.RegisterCategory("log")
H.CreateValue("log", "entries", {})

if CLIENT then
    function H.Request(charID, force)
        charID = tonumber(charID)
        if not charID then return false end
        local char = symchars.chars.Get(charID)
        if char and char._historyLoaded and not force then return true end
        if H._pendingRequests[charID] and H._pendingRequests[charID] > CurTime() and not force then return false end
        H._pendingRequests[charID] = CurTime() + 5
        symchars.net.SendToServer("history_request", { id = charID })
        return true
    end

    symchars.net.Receive("history", function(data)
        if not istable(data) then return end
        local id = tonumber(data.id)
        local char = id and symchars.chars.Get(id)
        if not char then return end
        H._pendingRequests[id] = nil
        char.history = H.ApplyDefaults(data.history)
        char._historyLoaded = true
        hook.Run("symchars_history_updated", char)
    end)
end
