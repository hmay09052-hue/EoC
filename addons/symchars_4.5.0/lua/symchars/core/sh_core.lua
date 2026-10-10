--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Kern: Hilfsfunktionen und Berechtigungen
-------------------------------------------------------------------------------------------------------------]]

symchars = symchars or {}
symchars.util = symchars.util or {}

local U = symchars.util

function symchars.print(...)
    MsgC(Color(252, 178, 73), "[SymChars] ", Color(220, 220, 220), ...)
    MsgC("\n")
end

---------------------------------------------------------------------------------------------------------------
-- Strings / Zahlen
---------------------------------------------------------------------------------------------------------------
function U.Trim(value)
    return string.Trim(tostring(value or ""))
end

function U.Lower(value)
    return string.lower(U.Trim(value))
end

function U.Clean(value, maxLen, allowNewlines)
    local text = tostring(value or "")
    if allowNewlines then
        text = string.gsub(text, "\r", "")
        text = string.gsub(text, "[%z\1-\9\11-\31]", "")
    else
        text = string.gsub(text, "[%z\1-\31]", "")
    end
    text = string.Trim(text)
    if maxLen and utf8.len(text) and utf8.len(text) > maxLen then
        local cut = utf8.offset(text, maxLen + 1)
        if cut then text = string.sub(text, 1, cut - 1) end
    elseif maxLen and #text > maxLen * 4 then
        text = string.sub(text, 1, maxLen)
    end
    return text
end

function U.Int(value, fallback, minValue, maxValue)
    local n = tonumber(value)
    if not n or n ~= n then n = fallback or 0 end
    n = math.floor(n)
    if minValue and n < minValue then n = minValue end
    if maxValue and n > maxValue then n = maxValue end
    return n
end

function U.Num(value, fallback, minValue, maxValue)
    local n = tonumber(value)
    if not n or n ~= n then n = fallback or 0 end
    if minValue and n < minValue then n = minValue end
    if maxValue and n > maxValue then n = maxValue end
    return n
end

function U.Bool(value, fallback)
    if value == nil then return fallback == true end
    return value == true or value == 1 or value == "1" or value == "true"
end

function U.ID(value)
    local id = U.Lower(value)
    id = string.gsub(id, "%s+", "_")
    id = string.gsub(id, "[^%w_%-]", "")
    return string.sub(id, 1, 48)
end

function U.NewID(prefix)
    return (prefix or "") .. string.format("%x%04x", os.time() % 0xffffff, math.random(0, 0xffff))
end

function U.StringList(list, maxItems, maxLen)
    local out, seen = {}, {}
    if isstring(list) then list = string.Explode(",", list) end
    if not istable(list) then return out end
    for _, v in ipairs(list) do
        local s = U.Clean(v, maxLen or 96)
        if s ~= "" and not seen[s] then
            seen[s] = true
            out[#out + 1] = s
            if maxItems and #out >= maxItems then break end
        end
    end
    return out
end

function U.IDList(list, maxItems)
    local out, seen = {}, {}
    if not istable(list) then return out end
    for _, v in ipairs(list) do
        local s = U.ID(v)
        if s ~= "" and not seen[s] then
            seen[s] = true
            out[#out + 1] = s
            if maxItems and #out >= maxItems then break end
        end
    end
    return out
end

function U.ToSet(list)
    local set = {}
    for _, v in ipairs(list or {}) do set[v] = true end
    return set
end

function U.InList(list, value)
    for _, v in ipairs(list or {}) do
        if v == value then return true end
    end
    return false
end

function U.Copy(value)
    if istable(value) then return table.Copy(value) end
    return value
end

---------------------------------------------------------------------------------------------------------------
-- Farben
---------------------------------------------------------------------------------------------------------------
function U.ColorToTable(col)
    if not istable(col) then return nil end
    return { r = U.Int(col.r, 255, 0, 255), g = U.Int(col.g, 255, 0, 255), b = U.Int(col.b, 255, 0, 255), a = U.Int(col.a, 255, 0, 255) }
end

function U.TableToColor(data, fallback)
    if not istable(data) then return fallback end
    return Color(U.Int(data.r, 255, 0, 255), U.Int(data.g, 255, 0, 255), U.Int(data.b, 255, 0, 255), U.Int(data.a, 255, 0, 255))
end

function U.HexToColor(hex, fallback)
    hex = string.gsub(tostring(hex or ""), "#", "")
    if #hex ~= 6 then return fallback end
    local r, g, b = tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16)
    if not r or not g or not b then return fallback end
    return Color(r, g, b)
end

function U.ColorToHex(col)
    if not istable(col) then return "#ffffff" end
    return string.format("#%02x%02x%02x", U.Int(col.r, 255, 0, 255), U.Int(col.g, 255, 0, 255), U.Int(col.b, 255, 0, 255))
end

---------------------------------------------------------------------------------------------------------------
-- Bilder (Imgur / direkte Links)
---------------------------------------------------------------------------------------------------------------
-- Akzeptiert: "abc123", "https://imgur.com/abc123", "https://i.imgur.com/abc123.png", direkte https-Bildlinks
function U.ImageURL(value)
    local url = U.Trim(value)
    if url == "" then return "" end

    if string.match(url, "^[%w]+$") and #url >= 5 and #url <= 12 then
        return "https://i.imgur.com/" .. url .. ".png"
    end

    local id = string.match(url, "^https?://i%.imgur%.com/([%w]+)%.%w+") or string.match(url, "^https?://imgur%.com/([%w]+)$")
        or string.match(url, "^https?://www%.imgur%.com/([%w]+)$") or string.match(url, "^https?://i%.imgur%.com/([%w]+)$")
    if id then
        return "https://i.imgur.com/" .. id .. ".png"
    end

    if string.match(url, "^https://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+$") and #url <= 300 then
        local lower = string.lower(url)
        if string.find(lower, "%.png") or string.find(lower, "%.jpe?g") or string.find(lower, "%.webp") then
            return url
        end
    end

    return ""
end

---------------------------------------------------------------------------------------------------------------
-- Zeit
---------------------------------------------------------------------------------------------------------------
function U.FormatDate(ts, withTime)
    ts = tonumber(ts)
    if not ts or ts <= 0 then return "-" end
    return os.date(withTime and "%d.%m.%Y %H:%M" or "%d.%m.%Y", ts)
end

function U.FormatHours(hours)
    hours = tonumber(hours) or 0
    if hours < 1 then
        return math.floor(hours * 60 + 0.5) .. " Min"
    end
    local h = math.floor(hours)
    local m = math.floor((hours - h) * 60 + 0.5)
    if m == 60 then h, m = h + 1, 0 end
    return h .. " Std " .. m .. " Min"
end

function U.FormatAgo(ts)
    ts = tonumber(ts)
    if not ts or ts <= 0 then return "-" end
    local diff = os.time() - ts
    if diff < 60 then return "gerade eben" end
    if diff < 3600 then return "vor " .. math.floor(diff / 60) .. " Min" end
    if diff < 86400 then return "vor " .. math.floor(diff / 3600) .. " Std" end
    local days = math.floor(diff / 86400)
    return "vor " .. days .. (days == 1 and " Tag" or " Tagen")
end

function U.FormatMoney(value)
    value = tonumber(value) or 0
    if DarkRP and DarkRP.formatMoney then
        return DarkRP.formatMoney(value)
    end
    return string.Comma(value) .. " Credits"
end

---------------------------------------------------------------------------------------------------------------
-- DarkRP-Jobs
---------------------------------------------------------------------------------------------------------------
function U.GetJob(command)
    command = U.Trim(command)
    if command == "" then return nil end
    if DarkRP and DarkRP.getJobByCommand then
        local job = DarkRP.getJobByCommand(command)
        if job then return job end
    end
    for _, job in pairs(RPExtraTeams or {}) do
        if job.command == command then return job end
    end
    return nil
end

function U.JobName(command)
    local job = U.GetJob(command)
    return job and job.name or U.Trim(command)
end

function U.JobModels(command)
    local job = U.GetJob(command)
    if not job then return {} end
    if istable(job.model) then
        local out = {}
        for _, m in ipairs(job.model) do out[#out + 1] = m end
        return out
    end
    if isstring(job.model) and job.model ~= "" then return { job.model } end
    return {}
end

function U.FirstModel(command)
    return U.JobModels(command)[1]
end

function symchars.GetFirstModel(command)
    return U.FirstModel(command) or false
end

function U.ValidModel(model)
    model = U.Trim(model)
    if model == "" then return false end
    if not string.match(string.lower(model), "^models/.+%.mdl$") then return false end
    if util.IsValidModel then return util.IsValidModel(model) end
    return true
end

---------------------------------------------------------------------------------------------------------------
-- Berechtigungen (CAMI)
---------------------------------------------------------------------------------------------------------------
symchars.privileges = {
    { name = "symchars_charmanage", min = "admin", desc = "Alle Charaktere in der Verwaltung sehen" },
    { name = "symchars_factioncreation", min = "superadmin", desc = "Einheiten erstellen/bearbeiten" },
    { name = "symchars_char_admin", min = "superadmin", desc = "Alle Charakter-Aktionen" },
    { name = "symchars_char_changename", min = "admin", desc = "Charakternamen ändern" },
    { name = "symchars_char_changemoney", min = "admin", desc = "Charaktergeld ändern" },
    { name = "symchars_char_changefaction", min = "admin", desc = "Einheit eines Charakters setzen" },
    { name = "symchars_char_ranksmanage", min = "admin", desc = "Ränge/RP-IDs verwalten" },
    { name = "symchars_char_kick", min = "admin", desc = "Charaktere entlassen" },
    { name = "symchars_char_customchar", min = "admin", desc = "Custom-Charaktere einrichten" },
    { name = "symchars_char_jobchange", min = "admin", desc = "Job eines Charakters setzen" },
    { name = "symchars_char_delete", min = "admin", desc = "Fremde Charaktere löschen" },
    { name = "symchars_settings", min = "superadmin", desc = "SymChars-Einstellungen ändern" },
    { name = "symchars_trainings_admin", min = "admin", desc = "Fortbildungen anlegen und überall eintragen" },
    { name = "symchars_docs_admin", min = "admin", desc = "Alle Dokumente verwalten" },
    { name = "symchars_holo", min = "admin", desc = "Holo-Anzeigen platzieren und einstellen" },
}

local privMin = {}
for _, priv in ipairs(symchars.privileges) do privMin[priv.name] = priv.min end

-- CAMI kann nach diesem Addon geladen werden (z.B. von ULib) -> zusätzlich beim Start registrieren
local function RegisterPrivileges()
    if not CAMI or not CAMI.RegisterPrivilege then return end
    for _, priv in ipairs(symchars.privileges) do
        CAMI.RegisterPrivilege({ Name = priv.name, MinAccess = priv.min, Description = priv.desc })
    end
end
RegisterPrivileges()
hook.Add("Initialize", "symchars_cami", RegisterPrivileges)
hook.Add("InitPostEntity", "symchars_cami", RegisterPrivileges)

function symchars.HasPriv(ply, name)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if ply:IsSuperAdmin() then return true end

    if CAMI and CAMI.PlayerHasAccess then
        local result = CAMI.PlayerHasAccess(ply, name)
        if result ~= nil then return result == true end
    end

    local min = privMin[name] or "superadmin"
    if min == "user" then return true end
    if min == "admin" then return ply:IsAdmin() end
    return false
end

-- ADMIN-Bereich des Menüs (Einstellungen, Einheiten, Fortbildungen, Hologramme, Whitelist): nur Superadmins
function symchars.IsSuperAdmin(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:IsSuperAdmin()
end

function symchars.IsAdmin(ply)
    return symchars.HasPriv(ply, "symchars_char_admin")
end
