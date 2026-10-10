--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Anfragen vom Datapad (laeuft ueber das Netzwerk von SymChars)
    Jede Anfrage traegt eine rid, die Antwort kommt als "gdp_reply" zurueck.
    Alle Rechte werden hier geprueft, der Client zeigt nur an.
-------------------------------------------------------------------------------------------------------------]]

local CFG = GAR_DP.Config
local DB = GAR_DP.db

local MAX_TITLE, MAX_BODY, MAX_FIELD = 120, 12000, 300

---------------------------------------------------------------------------------------------------------------
-- Helfer
---------------------------------------------------------------------------------------------------------------
local function Clean(text, max)
    text = tostring(text or "")
    text = string.gsub(text, "[%z\1-\8\11\12\14-\31]", "")
    if #text > max then text = string.sub(text, 1, max) end
    return string.Trim(text)
end

local function CharName(char)
    if not char then return "Unbekannt" end
    return symchars.utils.BuildDisplayName(char)
end

local function Notify(ply, text, kind)
    symchars.net.Send("gdp_notify", { text = text, kind = kind or "info" }, ply)
end
GAR_DP.Notify = Notify

-- einfache Begrenzung: hoechstens 25 Anfragen pro Sekunde und Spieler
local function RateOk(ply)
    local now = CurTime()
    if (ply.gdp_rateT or 0) < now then ply.gdp_rateT, ply.gdp_rateN = now + 1, 0 end
    ply.gdp_rateN = (ply.gdp_rateN or 0) + 1
    return ply.gdp_rateN <= 25
end

local function Handle(action, fn)
    symchars.net.Receive("gdp_" .. action, function(ply, data)
        data = istable(data) and data or {}
        local rid = tonumber(data.rid) or 0
        if not RateOk(ply) then
            symchars.net.Send("gdp_reply", { rid = rid, ok = false, err = "Zu viele Anfragen" }, ply)
            return
        end
        local ok, result = fn(ply, data)
        if ok == false then
            symchars.net.Send("gdp_reply", { rid = rid, ok = false, err = tostring(result or "Keine Berechtigung") }, ply)
        else
            symchars.net.Send("gdp_reply", { rid = rid, ok = true, data = result }, ply)
        end
    end)
end

local function IsAuthor(ply, rec)
    local char = GAR_DP.Char(ply)
    return char ~= nil and rec.author == char:GetID()
end

---------------------------------------------------------------------------------------------------------------
-- Sichtbarkeit
---------------------------------------------------------------------------------------------------------------
-- Darf ply diese Art von Eintraegen (fuer dieses Ziel) ueberhaupt oeffnen?
local function CanOpenKind(ply, kind, target)
    if kind == "penal" then return GAR_DP.CanUse(ply, "penal") end
    if kind == "personnel" then
        local char = symchars.chars.Get(target)
        if not char then return false, "Charakter nicht gefunden" end
        return GAR_DP.CanViewPersonnel(ply, char), "Keine Freigabe fuer diese Akte"
    end
    if kind == "report" or kind == "classified" then return GAR_DP.Char(ply) ~= nil or GAR_DP.IsAdmin(ply), "Kein Charakter" end
    return false, "Unbekannt"
end

-- Eintrag fuer den Client verpacken; zu hoch eingestufte Eintraege nur geschwaerzt
local function Pack(ply, rec, withBody)
    local level = GAR_DP.Clearance(ply)
    if rec.level > level and not IsAuthor(ply, rec) then
        return { id = rec.id, kind = rec.kind, target = rec.target, level = rec.level, created = rec.created, redacted = true,
                 extra = { type = rec.extra and rec.extra.type } }
    end
    local out = {
        id = rec.id, kind = rec.kind, target = rec.target, author = rec.author, authorName = rec.authorName,
        title = rec.title, level = rec.level, status = rec.status, extra = rec.extra, created = rec.created, updated = rec.updated,
    }
    if withBody then
        out.body = rec.body
    else
        out.preview = string.sub(string.gsub(rec.body, "%s+", " "), 1, 160)
    end
    return out
end

local function CanEdit(ply, rec)
    local admin = GAR_DP.IsAdmin(ply)
    local level = GAR_DP.Clearance(ply)
    if rec.kind == "penal" then return GAR_DP.CanUse(ply, "penal") and level >= rec.level end
    return admin or IsAuthor(ply, rec)
end

local function CanDelete(ply, rec)
    local level = GAR_DP.Clearance(ply)
    if rec.kind == "penal" then return GAR_DP.CanUse(ply, "penal") and level >= math.max(rec.level, CFG.PenalDeleteLevel) end
    if GAR_DP.IsAdmin(ply) then return true end
    if level < rec.level and not IsAuthor(ply, rec) then return false end
    if rec.kind == "report" then return IsAuthor(ply, rec) or level >= CFG.ReportDeleteLevel end
    if rec.kind == "classified" then return IsAuthor(ply, rec) or level >= 6 end
    return IsAuthor(ply, rec)
end

---------------------------------------------------------------------------------------------------------------
-- Liste / Einzelner Eintrag
---------------------------------------------------------------------------------------------------------------
Handle("list", function(ply, data)
    local kind = tostring(data.kind or "")
    local target = tonumber(data.target)
    local ok, reason = CanOpenKind(ply, kind, target)
    if not ok then return false, reason end

    local wantedOnly = kind == "penal" and data.wanted == true
    local perTarget = (kind == "penal" or kind == "personnel") and not wantedOnly
    if perTarget and not target then return false, "Kein Ziel" end

    local list = DB.List(kind, perTarget and target or nil)
    local out = {}
    for _, rec in ipairs(list) do
        if not wantedOnly or (rec.extra.wanted and rec.status == "offen") then
            local packed = Pack(ply, rec, perTarget or wantedOnly)
            packed.canEdit = not packed.redacted and CanEdit(ply, rec)
            packed.canDelete = CanDelete(ply, rec)
            out[#out + 1] = packed
        end
    end
    return true, { kind = kind, target = target, items = out }
end)

Handle("get", function(ply, data)
    local rec = DB.Get(data.id)
    if not rec then return false, "Eintrag nicht gefunden" end
    local ok, reason = CanOpenKind(ply, rec.kind, rec.target)
    if not ok then return false, reason end
    local packed = Pack(ply, rec, true)
    packed.canEdit = not packed.redacted and CanEdit(ply, rec)
    packed.canDelete = CanDelete(ply, rec)
    return true, packed
end)

---------------------------------------------------------------------------------------------------------------
-- Speichern
---------------------------------------------------------------------------------------------------------------
local function CleanExtra(kind, extra, level)
    extra = istable(extra) and extra or {}
    local out = {}
    if kind == "penal" then
        out.law = Clean(extra.law, 20)
        out.punishment = Clean(extra.punishment, MAX_FIELD)
        out.wanted = extra.wanted == true
    elseif kind == "personnel" then
        out.type = GAR_DP.ById(CFG.PersonnelTypes, extra.type) and extra.type or CFG.PersonnelTypes[1].id
    elseif kind == "report" then
        out.type = GAR_DP.ById(CFG.ReportTypes, extra.type) and extra.type or CFG.ReportTypes[1].id
        out.location = Clean(extra.location, MAX_FIELD)
        out.participants = Clean(extra.participants, MAX_FIELD)
    elseif kind == "classified" then
        out.category = Clean(extra.category, 60)
    end
    return out
end

Handle("save", function(ply, data)
    local char = GAR_DP.Char(ply)
    local admin = GAR_DP.IsAdmin(ply)
    if not char and not admin then return false, "Kein Charakter" end
    local level = GAR_DP.Clearance(ply)

    local existing = data.id and DB.Get(data.id)
    if data.id and not existing then return false, "Eintrag nicht gefunden" end
    local kind = existing and existing.kind or tostring(data.kind or "")
    local target = existing and existing.target or math.floor(tonumber(data.target) or 0)

    local rec = existing or { kind = kind, target = target, author = char and char:GetID() or 0, authorName = char and CharName(char) or ply:Nick() }
    rec.title = Clean(data.title, MAX_TITLE)
    rec.body = Clean(data.body, MAX_BODY)
    rec.level = math.Clamp(math.floor(tonumber(data.level) or 1), 1, 6)
    rec.extra = CleanExtra(kind, data.extra, rec.level)
    rec.status = ""

    if rec.title == "" then return false, "Bitte einen Titel angeben" end
    if rec.level > level then return false, "Die Stufe ist hoeher als deine eigene Freigabe" end

    local targetChar = target > 0 and symchars.chars.Get(target) or nil

    if existing then
        if not CanEdit(ply, existing) then return false, "Du darfst diesen Eintrag nicht bearbeiten" end
    elseif kind == "penal" then
        if not GAR_DP.CanUse(ply, "penal") then return false, "Nur Schocktruppen" end
        if not targetChar then return false, "Charakter nicht gefunden" end
    elseif kind == "personnel" then
        if not GAR_DP.CanWritePersonnel(ply, targetChar) then return false, "Du darfst in diese Akte nicht schreiben" end
    elseif kind == "report" then
        rec.target = 0
        local rtype = GAR_DP.ById(CFG.ReportTypes, rec.extra.type)
        if rtype and rtype.level > level then return false, "Fuer diesen Berichtstyp fehlt dir die Freigabe" end
    elseif kind == "classified" then
        rec.target = 0
        if level < CFG.ClassifiedCreateLevel then return false, "Ab Stufe " .. CFG.ClassifiedCreateLevel end
    else
        return false, "Unbekannte Art"
    end

    if kind == "penal" then
        rec.status = GAR_DP.ById(CFG.PenalStatus, data.status) and data.status or CFG.PenalStatus[1].id
    elseif kind == "report" then
        local rtype = GAR_DP.ById(CFG.ReportTypes, rec.extra.type)
        if rtype then rec.level = math.max(rec.level, rtype.level) end
    end

    local isNew = not existing
    if existing then
        DB.Update(rec)
    else
        rec.id = DB.Insert(rec)
    end

    -- Meldungen
    if isNew and kind == "penal" and rec.extra.wanted then
        for _, p in ipairs(player.GetAll()) do
            if p ~= ply and GAR_DP.IsShock(p) and GAR_DP.Clearance(p) >= rec.level then
                Notify(p, "Neue Fahndung: " .. CharName(targetChar) .. " - " .. rec.title, "warn")
            end
        end
    elseif isNew and kind == "personnel" and targetChar then
        local tp = targetChar:GetPlayer()
        if IsValid(tp) and tp ~= ply and GAR_DP.Clearance(tp) >= rec.level then
            local t = GAR_DP.ById(CFG.PersonnelTypes, rec.extra.type)
            Notify(tp, "Neuer Eintrag in deiner Personalakte: " .. (t and t.name or "Vermerk"), "info")
        end
    end

    hook.Run("gar_datapad_saved", ply, rec, isNew)
    return true, { id = rec.id }
end)

Handle("delete", function(ply, data)
    local rec = DB.Get(data.id)
    if not rec then return false, "Eintrag nicht gefunden" end
    if not CanDelete(ply, rec) then return false, "Du darfst diesen Eintrag nicht loeschen" end
    DB.Delete(rec.id)
    hook.Run("gar_datapad_deleted", ply, rec)
    return true, { id = rec.id }
end)

---------------------------------------------------------------------------------------------------------------
-- Sicherheitsstufen von Hand
---------------------------------------------------------------------------------------------------------------
local function ManualList()
    local list = {}
    for id, m in pairs(GAR_DP.manual) do list[#list + 1] = { id = id, level = m.level, by = m.by, at = m.at } end
    return list
end

function GAR_DP.SyncManual(ply)
    symchars.net.Send("gdp_manual", ManualList(), ply)
end

Handle("clearance_set", function(ply, data)
    local maxGrant = GAR_DP.MaxGrant(ply)
    if maxGrant <= 0 then return false, "Keine Berechtigung" end
    local target = symchars.chars.Get(data.charID)
    if not target then return false, "Charakter nicht gefunden" end
    local admin = GAR_DP.IsAdmin(ply)
    local own = GAR_DP.Char(ply)
    if not admin and own and own:GetID() == target:GetID() then return false, "Du kannst dir selbst keine Stufe geben" end

    local tp = target:GetPlayer()
    local current = IsValid(tp) and GAR_DP.Clearance(tp) or GAR_DP.CharClearance(target)
    if not admin and current > maxGrant then return false, "Die Person hat eine hoehere Stufe als du" end

    local level = math.floor(tonumber(data.level) or 0)
    if level < 0 or level > maxGrant then return false, "Diese Stufe darfst du nicht vergeben" end

    DB.SetClearance(target:GetID(), level, own and CharName(own) or ply:Nick())
    GAR_DP.SyncManual()
    if IsValid(tp) then
        Notify(tp, level > 0 and ("Deine Sicherheitsfreigabe wurde auf Stufe " .. level .. " gesetzt.") or "Deine Sicherheitsfreigabe richtet sich wieder nach deinem Rang.", "info")
    end
    return true, { charID = target:GetID(), level = level }
end)

---------------------------------------------------------------------------------------------------------------
-- Galaxiekarte
---------------------------------------------------------------------------------------------------------------
local function GalaxyList()
    local list = {}
    for planet, s in pairs(GAR_DP.galaxyState or {}) do
        list[#list + 1] = { planet = planet, status = s.status, note = s.note, by = s.by, at = s.at }
    end
    return list
end

function GAR_DP.SyncGalaxy(ply)
    symchars.net.Send("gdp_galaxy", GalaxyList(), ply)
end

Handle("galaxy_set", function(ply, data)
    if GAR_DP.Clearance(ply) < CFG.GalaxyEditLevel then return false, "Ab Stufe " .. CFG.GalaxyEditLevel end
    local planet = GAR_DP.galaxy.Find(data.planet)
    if not planet then return false, "Planet nicht gefunden" end
    local status = tostring(data.status or "")
    if status ~= "" and not GAR_DP.ById(CFG.GalaxyStatus, status) then return false, "Unbekannter Status" end
    local own = GAR_DP.Char(ply)
    DB.SetGalaxy(planet.name, status, Clean(data.note, MAX_FIELD), own and CharName(own) or ply:Nick())
    GAR_DP.SyncGalaxy()
    return true, { planet = planet.name }
end)

---------------------------------------------------------------------------------------------------------------
-- Startseite: kleine Lagezahlen
---------------------------------------------------------------------------------------------------------------
Handle("home", function(ply)
    local level = GAR_DP.Clearance(ply)
    local out = { level = level }

    if GAR_DP.CanUse(ply, "penal") then
        local n = 0
        for _, rec in ipairs(DB.List("penal")) do
            if rec.extra.wanted and rec.status == "offen" then n = n + 1 end
        end
        out.wanted = n
    end

    local since = os.time() - 86400
    local reports = 0
    for _, rec in ipairs(DB.List("report")) do
        if rec.created >= since and rec.level <= level then reports = reports + 1 end
    end
    out.reports = reports

    local docs = 0
    for _, rec in ipairs(DB.List("classified")) do
        if rec.level <= level then docs = docs + 1 end
    end
    out.classified = docs
    return true, out
end)

---------------------------------------------------------------------------------------------------------------
-- Beim Betreten: Freigaben und Lage schicken
---------------------------------------------------------------------------------------------------------------
hook.Add("PlayerInitialSpawn", "gar_datapad_sync", function(ply)
    timer.Simple(5, function()
        if not IsValid(ply) then return end
        GAR_DP.SyncManual(ply)
        GAR_DP.SyncGalaxy(ply)
    end)
end)

-- nach "lua_openscript"/Neuladen allen schicken
timer.Simple(1, function()
    GAR_DP.SyncManual()
    GAR_DP.SyncGalaxy()
end)

GAR_DP.Handle = Handle
