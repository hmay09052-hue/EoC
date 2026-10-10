--[[
    EoC Range – Anbindung an die Server-Systeme
    Nutzt vorhandene Addons nur über deren Schnittstellen und ändert keine fremden Dateien.
    Fehlt ein optionales Addon, fällt nur die jeweilige Funktion weg.

    SymChars 4.5     Charakter, Einheit, Rang; Abzeichen als Fortbildung (Datapad -> Personalakte -> Fortbildungen)
    KrakenSquad      Squad-Mitglieder für den Squad-Lauf (Comlink)
    eoc_defcon       Sperre ab DEFCON-Stufe (sh_core.lua: EoCRange.DefconLocked)
    GRN Waffenkammer Waffen erst ab einer Abzeichenstufe
    EoC TAB / HUD    NW2-Werte "EoCR_Badge" (Spieler) und "EoCR_TrophyUnit" (global)
]]

local C = EoCRange.Config

---------------------------------------------------------------------------
-- Benachrichtigungen und Chat
---------------------------------------------------------------------------
-- typ: 0 = Info, 1 = Fehler, 2 = Erfolg
function EoCRange.Notify(ply, text, typ)
    if not IsValid(ply) and not istable(ply) then return end
    EoCRange.Send("notify", { t = text, k = typ or 0 }, ply)
end

-- Chat-Durchsage im Stil des EoC-Announcers. kind: "server" | "unit" | "info"
function EoCRange.Announce(text, targets, kind)
    EoCRange.Send("chat", { t = text, k = kind or "server" }, targets)
end

---------------------------------------------------------------------------
-- SymChars: Fortbildungen für die Schützenabzeichen
---------------------------------------------------------------------------
local function Trainings()
    return symchars and symchars.trainings
end

function EoCRange.EnsureBadgeTrainings()
    local T = Trainings()
    if not T or not T._loadedOnce or not T.Normalize or not symchars.db then return false end
    local changed = false
    for lvl, info in ipairs(C.BadgeTrainings) do
        if not T.Get(info.id) then
            local lines = {}
            for _, disc in ipairs(C.ExamDisciplines) do
                local def = EoCRange.GetDiscipline(disc)
                if def then lines[#lines + 1] = def.name .. ": " .. EoCRange.ThresholdText(disc, lvl) end
            end
            local t = T.Normalize({
                name = info.name, short = info.short, category = "Schießstand", sort = 50 + lvl,
                color = C.BadgeColors[lvl], createdBy = "EoC Range",
                description = "Vergeben nach einer beaufsichtigten Schießprüfung am Schießstand (EoC Range). Startwerte: " .. table.concat(lines, " · "),
            }, info.id)
            T.loaded[t.id] = t
            symchars.db.Replace("sc_trainings", { "id", "data" }, { symchars.db.Str(t.id), symchars.db.Str(symchars.net.Json(T.ToSave(t))) })
            changed = true
        end
    end
    if changed and T.SyncAll then
        T.SyncAll()
        MsgC(Color(255, 190, 50), "[EoC Range] ", color_white, "Fortbildungen für Schützenabzeichen in SymChars angelegt.\n")
    end
    return true
end

local function GetSymChar(charId)
    if not symchars or not symchars.chars or not symchars.chars.Get then return nil end
    return symchars.chars.Get(charId)
end

function EoCRange.GrantBadgeTraining(charId, level, actorPly, note)
    local T = Trainings()
    local info = C.BadgeTrainings[level]
    if not T or not info or not T.Grant then return end
    EoCRange.EnsureBadgeTrainings()
    local training, ch = T.Get(info.id), GetSymChar(charId)
    if not training or not ch then return end
    if ch.HasTraining and ch:HasTraining(training.id) then return end
    local ok, err = pcall(T.Grant, ch, training, actorPly, note)
    if not ok then ErrorNoHalt("[EoC Range] SymChars-Fortbildung konnte nicht eingetragen werden: " .. tostring(err) .. "\n") end
end

function EoCRange.RevokeBadgeTraining(charId, level, actorPly, reason)
    local T = Trainings()
    local info = C.BadgeTrainings[level]
    if not T or not info or not T.Revoke then return end
    local training, ch = T.Get(info.id), GetSymChar(charId)
    if not training or not ch then return end
    local ok, err = pcall(T.Revoke, ch, training, actorPly, reason)
    if not ok then ErrorNoHalt("[EoC Range] SymChars-Fortbildung konnte nicht entzogen werden: " .. tostring(err) .. "\n") end
end

-- Fortbildungen anlegen, sobald SymChars geladen ist
timer.Create("EoCRange_EnsureTrainings", 5, 0, function()
    if EoCRange.EnsureBadgeTrainings() then timer.Remove("EoCRange_EnsureTrainings") end
end)

-- Online-Spieler eines Charakters
function EoCRange.PlayerByChar(charId)
    for _, p in ipairs(player.GetAll()) do
        local ch = EoCRange.GetCharacter(p)
        if ch and tonumber(ch.charID) == charId then return p end
    end
end

---------------------------------------------------------------------------
-- Squad (KrakenSquad im Comlink)
---------------------------------------------------------------------------
function EoCRange.SquadMembers(ply)
    local custom = hook.Run("EoCRange_GetSquad", ply)
    if istable(custom) then return custom end

    if ply.GetKSSquad then
        local ok, squad = pcall(ply.GetKSSquad, ply)
        if ok and squad and squad.GetMembers then
            local members = squad:GetMembers()
            if istable(members) and #members > 0 then return members end
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Waffenkammer (eoc_inventar_armory): gesperrte Waffen bis zur Abzeichenstufe ausblenden
---------------------------------------------------------------------------
local function WrapArmory()
    if not GRNStore or not isfunction(GRNStore.BuildArmoryWeapons) or GRNStore._EoCRangeWrapped then return end
    GRNStore._EoCRangeWrapped = true
    local original = GRNStore.BuildArmoryWeapons
    GRNStore.BuildArmoryWeapons = function(ply, ...)
        local list = original(ply, ...)
        if not istable(list) or not next(C.ArmoryLocks or {}) then return list end
        local level = EoCRange.GetBadge(ply)
        local out = {}
        for _, w in ipairs(list) do
            local class = string.lower(tostring(istable(w) and w.className or ""))
            local need = 0
            for lockClass, lvl in pairs(C.ArmoryLocks) do
                if string.lower(lockClass) == class then need = lvl end
            end
            if level >= need then out[#out + 1] = w end
        end
        return out
    end
    MsgC(Color(255, 190, 50), "[EoC Range] ", color_white, "Waffenkammer gekoppelt.\n")
end

hook.Add("InitPostEntity", "EoCRange_Armory", WrapArmory)
timer.Simple(5, WrapArmory)

---------------------------------------------------------------------------
-- Öffentliche Schnittstelle
---------------------------------------------------------------------------
function EoCRange.GetBadge(ply)
    if not IsValid(ply) then return 0 end
    local info = EoCRange.CharInfo(ply)
    return EoCRange.BadgeCache[info.id] or 0
end

EoCRange.BestCache = EoCRange.BestCache or {}   -- [charId][discId] = Allzeit-Bestwert

function EoCRange.GetBest(ply, discId)
    if not IsValid(ply) then return nil end
    local info = EoCRange.CharInfo(ply)
    local t = EoCRange.BestCache[info.id]
    return t and t[discId] or nil
end

function EoCRange.LoadPlayerBests(ply, cb)
    if not IsValid(ply) then return end
    local info = EoCRange.CharInfo(ply)
    EoCRange.DB.PersonalBests(info.id, function(rows)
        local t = {}
        for _, r in ipairs(rows) do
            if r.period == "all" then t[r.discipline] = r.score end
        end
        EoCRange.BestCache[info.id] = t
        if cb then cb(rows) end
    end)
end

-- NW2-Werte für TAB/HUD aktuell halten
timer.Create("EoCRange_NW", 5, 0, function()
    for _, p in ipairs(player.GetAll()) do
        local lvl = EoCRange.GetBadge(p)
        if p:GetNW2Int("EoCR_Badge", 0) ~= lvl then p:SetNW2Int("EoCR_Badge", lvl) end
        local unit = EoCRange.UnitOf(p)
        if p:GetNW2String("EoCR_Unit", "") ~= unit then p:SetNW2String("EoCR_Unit", unit) end
    end
end)

hook.Add("symchars_selectedcharacter", "EoCRange_Char", function(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        EoCRange.LoadPlayerBests(ply)
        ply:SetNW2Int("EoCR_Badge", EoCRange.GetBadge(ply))
    end)
end)
