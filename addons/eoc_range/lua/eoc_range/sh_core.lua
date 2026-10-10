--[[
    EoC Range – gemeinsame Hilfsfunktionen: Netzwerk, Rechte, Charakter/Einheit, Waffen, Zeiträume, DEFCON
]]

local C = EoCRange.Config

---------------------------------------------------------------------------
-- Netzwerk: ein Kanal, Nachrichtentyp + komprimiertes JSON
---------------------------------------------------------------------------
local NET = "EoCR_Msg"
if SERVER then util.AddNetworkString(NET) end

EoCRange.Handlers = EoCRange.Handlers or {}

-- Server: fn(ply, data)   Client: fn(data)
function EoCRange.Receive(kind, fn, cooldown)
    EoCRange.Handlers[kind] = { fn = fn, cd = cooldown or 0.15 }
end

function EoCRange.Send(kind, data, target)
    local bin = util.Compress(util.TableToJSON(data or {}) or "{}") or ""
    net.Start(NET)
    net.WriteString(kind)
    net.WriteUInt(#bin, 32)
    net.WriteData(bin, #bin)
    if CLIENT then
        net.SendToServer()
    elseif target == nil then
        net.Broadcast()
    else
        net.Send(target)
    end
end

net.Receive(NET, function(_, ply)
    local kind = net.ReadString()
    local n = net.ReadUInt(32)
    if n > (SERVER and 65536 or 4194304) then return end
    local raw = n > 0 and net.ReadData(n) or ""
    local json = raw ~= "" and util.Decompress(raw) or "{}"
    local data = json and util.JSONToTable(json) or {}
    local h = EoCRange.Handlers[kind]
    if not h then return end

    if SERVER then
        ply.EoCR_Cool = ply.EoCR_Cool or {}
        local now = CurTime()
        if (ply.EoCR_Cool[kind] or 0) > now then return end
        ply.EoCR_Cool[kind] = now + h.cd
        local ok, err = pcall(h.fn, ply, data)
        if not ok then ErrorNoHalt("[EoC Range] Fehler in '" .. kind .. "': " .. tostring(err) .. "\n") end
    else
        h.fn(data)
    end
end)

---------------------------------------------------------------------------
-- Kleinkram
---------------------------------------------------------------------------
function EoCRange.InList(list, value)
    for _, v in ipairs(list or {}) do
        if v == value then return true end
    end
    return false
end

function EoCRange.Clean(text, max)
    text = string.Trim(tostring(text or ""))
    text = string.gsub(text, "[%c]", "")
    if max and #text > max then text = string.sub(text, 1, max) end
    return text
end

---------------------------------------------------------------------------
-- Rechte: Spieler, Ausbilder, Admin, Superadmin
---------------------------------------------------------------------------
function EoCRange.IsSuperAdmin(ply)
    return IsValid(ply) and ply:IsSuperAdmin()
end

function EoCRange.IsAdmin(ply)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    return EoCRange.InList(C.AdminGroups, ply:GetUserGroup())
end

local function JobMatches(ply)
    local t = ply:Team()
    local job = RPExtraTeams and RPExtraTeams[t]
    for _, j in ipairs(C.InstructorJobs or {}) do
        if _G[j] ~= nil and _G[j] == t then return true end
        if job and (job.command == j or job.name == j) then return true end
    end
    local name = (job and job.name) or team.GetName(t) or ""
    for _, p in ipairs(C.InstructorJobPatterns or {}) do
        if p ~= "" and string.find(name, p, 1, true) then return true end
    end
    return false
end

function EoCRange.IsInstructor(ply)
    if not IsValid(ply) then return false end
    local override = hook.Run("EoCRange_IsInstructor", ply)
    if override ~= nil then return override == true end
    if EoCRange.IsAdmin(ply) then return true end
    if EoCRange.InList(C.InstructorGroups, ply:GetUserGroup()) then return true end
    if JobMatches(ply) then return true end
    local ch = EoCRange.GetCharacter(ply)
    if ch and ch.HasTraining then
        for _, id in ipairs(C.InstructorTrainings or {}) do
            if ch:HasTraining(id) then return true end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Charakter und Einheit (SymChars)
---------------------------------------------------------------------------
function EoCRange.GetCharacter(ply)
    if not IsValid(ply) or not ply.GetCharacter then return nil end
    local ok, ch = pcall(ply.GetCharacter, ply)
    if ok and istable(ch) then return ch end
    return nil
end

local function FactionLabel(f)
    if not f then return nil end
    local short = f.GetShort and f:GetShort() or ""
    if short and short ~= "" then return short end
    return f.GetName and f:GetName() or tostring(f.uniqueID or "?")
end

function EoCRange.UnitName(id, fallback)
    if symchars and symchars.factions and symchars.factions.Get and id and id ~= "" then
        local f = symchars.factions.Get(id)
        if f then return FactionLabel(f) end
    end
    return fallback or id or "–"
end

function EoCRange.UnitColor(id)
    if symchars and symchars.factions and symchars.factions.Get and id and id ~= "" then
        local f = symchars.factions.Get(id)
        if f and f.GetColor then return f:GetColor() end
    end
    return Color(252, 178, 73)
end

-- Einheit eines Spielers: id, Anzeigename
function EoCRange.UnitOf(ply)
    local ch = EoCRange.GetCharacter(ply)
    if ch and ch.GetFaction then
        local f = ch:GetFaction()
        if f then
            if C.UnitLevel == "main" and f.GetRoot then f = f:GetRoot() or f end
            return f:GetID(), FactionLabel(f)
        end
    end
    local t = IsValid(ply) and ply:Team() or 0
    return "team_" .. t, team.GetName(t) or "Ohne Einheit"
end

function EoCRange.CharInfo(ply)
    local unit, unitName = EoCRange.UnitOf(ply)
    local ch = EoCRange.GetCharacter(ply)
    if ch then
        local display = ch.name or ply:Nick()
        if symchars and symchars.utils and symchars.utils.BuildDisplayName then
            local ok, d = pcall(symchars.utils.BuildDisplayName, ch)
            if ok and d and d ~= "" then display = d end
        end
        return {
            id = tonumber(ch.charID) or 0, name = display, unit = unit, unitName = unitName,
            rank = ch.GetRankName and ch:GetRankName() or "", steamid = ply:SteamID(), char = ch,
        }
    end
    -- Ohne SymChars: stabile negative ID aus der SteamID
    return {
        id = -(tonumber(util.CRC(ply:SteamID())) or 0), name = ply:Nick(), unit = unit, unitName = unitName,
        rank = "", steamid = ply:SteamID(),
    }
end

---------------------------------------------------------------------------
-- Waffen
---------------------------------------------------------------------------
function EoCRange.IsHarmless(class)
    return class == nil or class == "" or EoCRange.InList(C.HarmlessWeapons, class)
end

-- Basiert die Waffe auf ArcCW? (Ergebnis wird zwischengespeichert)
local arccwCache = {}
function EoCRange.IsArcCW(class)
    if not class or class == "" then return false end
    local cached = arccwCache[class]
    if cached ~= nil then return cached end
    local stored = weapons.GetStored(class)
    local result = stored ~= nil and (stored.ArcCW == true or weapons.IsBasedOn(class, "arccw_base"))
    arccwCache[class] = result
    return result
end

function EoCRange.IsWeaponAllowed(def, class)
    if not def or not class then return false end
    if C.AllowAllArcCW and EoCRange.IsArcCW(class) then return true end
    for _, g in ipairs(def.weapons or {}) do
        local grp = C.Weapons[g]
        if grp and grp.any and EoCRange.IsArcCW(class) then return true end
        if grp and EoCRange.InList(grp.classes, class) then return true end
    end
    if def.sniper and C.AllowLiveSniper and EoCRange.InList(C.LiveSniperClasses, class) then return true end
    return false
end

function EoCRange.WeaponNames(def)
    if C.AllowAllArcCW then return "alle ArcCW-Waffen" end
    local out = {}
    for _, g in ipairs(def and def.weapons or {}) do
        local grp = C.Weapons[g]
        if grp then out[#out + 1] = grp.name end
    end
    return table.concat(out, ", ")
end

---------------------------------------------------------------------------
-- Zeiträume (Wochen-Reset Montag 04:00)
---------------------------------------------------------------------------
function EoCRange.WeekKey(t)
    t = (t or os.time()) - (C.WeekResetHour or 4) * 3600
    local d = os.date("*t", t)
    local back = (d.wday + 5) % 7   -- Montag = 0
    local monday = os.time({ year = d.year, month = d.month, day = d.day - back, hour = 12 })
    return "w:" .. os.date("%Y-%m-%d", monday)
end

function EoCRange.MonthKey(t)
    return "m:" .. os.date("%Y-%m", t or os.time())
end

function EoCRange.PeriodKey(period, t)
    if period == "week" then return EoCRange.WeekKey(t) end
    if period == "month" then return EoCRange.MonthKey(t) end
    return "all"
end

EoCRange.PeriodNames = { all = "Allzeit", month = "Monat", week = "Woche" }

---------------------------------------------------------------------------
-- DEFCON (eoc_defcon)
---------------------------------------------------------------------------
function EoCRange.GetDefcon()
    local override = hook.Run("EoCRange_GetDefcon")
    if isnumber(override) then return override end
    local lvl = GetGlobalInt("GRN_Defcon_CurrentLevel", 0)
    if lvl == 0 and GRN_DEFCON and isnumber(GRN_DEFCON.CurrentLevel) then lvl = GRN_DEFCON.CurrentLevel end
    return lvl
end

function EoCRange.DefconLocked()
    local lvl = EoCRange.GetDefcon()
    local lock = tonumber(C.DefconLockLevel) or 0
    return lock > 0 and lvl > 0 and lvl <= lock, lvl
end

---------------------------------------------------------------------------
-- Wertung: Vergleich, Anzeige, Abzeichen-Stufe
---------------------------------------------------------------------------
function EoCRange.Better(def, a, b)
    if a == nil then return false end
    if b == nil then return true end
    if def and def.scoring == "time" then return a < b end
    return a > b
end

function EoCRange.Format(def, value)
    if value == nil then return "–" end
    if def and def.scoring == "time" then return string.format("%.2f s", value) end
    return tostring(math.Round(value))
end

function EoCRange.BadgeValue(discId, result)
    local def = EoCRange.GetDiscipline(discId)
    if not def or not result then return nil end
    if def.badgeValue == "hits" then return result.hits end
    return result.value
end

-- Welche Stufe (0..3) erreicht ein Wert in einer Prüfungsdisziplin?
function EoCRange.LevelFor(discId, value)
    local th = C.Thresholds[discId]
    local def = EoCRange.GetDiscipline(discId)
    if not th or not def or value == nil then return 0 end
    local lower = def.scoring == "time" and def.badgeValue ~= "hits"
    for lvl = 3, 1, -1 do
        local need = th[lvl]
        if need then
            if lower and value <= need then return lvl end
            if not lower and value >= need then return lvl end
        end
    end
    return 0
end

function EoCRange.BadgeName(level)
    return C.BadgeNames[level] or "Kein Abzeichen"
end

function EoCRange.ThresholdText(discId, level)
    local def = EoCRange.GetDiscipline(discId)
    local need = C.Thresholds[discId] and C.Thresholds[discId][level]
    if not def or not need then return "–" end
    if def.badgeValue == "hits" then
        if need >= (def.count or 8) then return need .. " von " .. (def.count or 8) end
        return "≥ " .. need .. " von " .. (def.count or 8)
    end
    if def.scoring == "time" then return "≤ " .. need .. " s" end
    return "≥ " .. need .. " Ringe"
end

-- Ingame-Einstellungen übernehmen (Server: aus settings.json, Client: per Sync)
function EoCRange.ApplySettings(t)
    if not istable(t) then return end
    if istable(t.Thresholds) then
        for disc, list in pairs(t.Thresholds) do
            if istable(list) and C.Thresholds[disc] then
                for i = 1, 3 do
                    local v = tonumber(list[i])
                    if v then C.Thresholds[disc][i] = v end
                end
            end
        end
    end
    if t.UnitLevel == "sub" or t.UnitLevel == "main" then C.UnitLevel = t.UnitLevel end
    if tonumber(t.DefconLockLevel) then C.DefconLockLevel = math.Clamp(math.floor(tonumber(t.DefconLockLevel)), 0, 5) end
    if isbool(t.AllowAllArcCW) then C.AllowAllArcCW = t.AllowAllArcCW end
end

function EoCRange.SettingsTable()
    return { Thresholds = C.Thresholds, UnitLevel = C.UnitLevel, DefconLockLevel = C.DefconLockLevel, AllowAllArcCW = C.AllowAllArcCW }
end

---------------------------------------------------------------------------
-- Bahnen und ihre Entities
---------------------------------------------------------------------------
function EoCRange.LaneEnts(lane, kind)
    local out = {}
    for _, e in ipairs(ents.FindByClass("range_*")) do
        if e.IsEoCRange and e.GetLane and e:GetLane() == lane and (not kind or e.RangeKind == kind) then
            out[#out + 1] = e
        end
    end
    return out
end

function EoCRange.Terminals()
    local out = {}
    for _, e in ipairs(ents.FindByClass("range_terminal")) do out[#out + 1] = e end
    table.sort(out, function(a, b) return a:GetLane() < b:GetLane() end)
    return out
end

function EoCRange.TerminalForLane(lane)
    for _, e in ipairs(ents.FindByClass("range_terminal")) do
        if e:GetLane() == lane then return e end
    end
end

function EoCRange.SilhouetteDef(index)
    return C.Silhouettes[index] or C.Silhouettes[1]
end
