--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Charaktere (Server)
    Tabelle sy_characters bleibt unverändert -> bestehende Charaktere und IDs bleiben erhalten.
-------------------------------------------------------------------------------------------------------------]]

local C = symchars.chars
local F = symchars.factions
local U = symchars.util
local UT = symchars.utils
local A = symchars.authority
local DB = symchars.db

local Json, Unjson = symchars.net.Json, symchars.net.Unjson

---------------------------------------------------------------------------------------------------------------
-- Hilfen
---------------------------------------------------------------------------------------------------------------
local function ActorName(ply)
    if IsValid(ply) then return ply:Nick() end
    return "console"
end

local function Snapshot(char)
    if not char then return nil end
    return {
        charActive = char.charActive, name = char.name, model = char.model, job = char.job, faction = char.faction,
        rank = char.rank, money = char.money, roleplayID = char.roleplayID, data = U.Copy(char.data or {}),
        customs = U.Copy(char.customs),
    }
end

local function Equal(a, b)
    if istable(a) or istable(b) then return Json(a or {}) == Json(b or {}) end
    return a == b
end

-- Löst die alten symchars_* Hooks aus (für Logs, z.B. GAS)
local function FireChanges(ply, char, old)
    if not char or not old then return end
    local new = Snapshot(char)
    local actor, target, id = ActorName(ply), tostring(char.name or "unknown"), char.charID
    local pairsToCheck = {
        { "faction", "symchars_factionchanged" }, { "job", "symchars_jobchanged" }, { "rank", "symchars_rankchanged" },
        { "model", "symchars_modelchanged" }, { "name", "symchars_namechanged" }, { "money", "symchars_moneychanged" },
        { "roleplayID", "symchars_roleplayidchanged" }, { "customs", "symchars_customschanged" },
        { "charActive", "symchars_charactivechanged" },
    }
    for _, entry in ipairs(pairsToCheck) do
        if not Equal(old[entry[1]], new[entry[1]]) then
            hook.Run(entry[2], actor, target, id, U.Copy(old[entry[1]]), U.Copy(new[entry[1]]))
        end
    end
end
C.FireChanges = FireChanges
C.Snapshot = Snapshot

local function OnlinePlayer(char)
    if not char then return nil end
    local ok, ply = UT.CharPlayed(char.charID)
    return ok and ply or nil
end
C.OnlinePlayer = OnlinePlayer

local function Update(char, fields)
    local sets = {}
    for col, value in pairs(fields) do
        local quoted = col == "rank" and "`rank`" or col
        if isnumber(value) then
            sets[#sets + 1] = quoted .. " = " .. DB.Num(value)
        else
            sets[#sets + 1] = quoted .. " = " .. DB.Str(value)
        end
    end
    if #sets == 0 then return end
    DB.Query("UPDATE sy_characters SET " .. table.concat(sets, ", ") .. " WHERE charID = " .. DB.Num(char.charID))
end
C.Update = Update

local function CustomsToDB(char)
    return istable(char.customs) and Json(char.customs) or "none"
end

---------------------------------------------------------------------------------------------------------------
-- Laden & Sync
---------------------------------------------------------------------------------------------------------------
local function FromRow(row)
    local data = Unjson(row.data or "")
    local customs = row.customs
    if isstring(customs) and customs ~= "" and customs ~= "none" and customs ~= "NULL" then
        customs = Unjson(customs)
    else
        customs = nil
    end
    return C.Create({
        charID = tonumber(row.charID),
        charActive = tonumber(row.charActive) or 1,
        charUser = tostring(row.charUser or ""),
        name = tostring(row.name or ""),
        model = tostring(row.model or ""),
        job = tostring(row.job or ""),
        createdAt = tonumber(row.createdAt) or 0,
        lastActive = tonumber(row.lastActive) or 0,
        faction = tostring(row.faction or "none"),
        rank = tonumber(row.rank) or 1,
        money = tonumber(row.money) or 0,
        data = istable(data) and data or {},
        roleplayID = tostring(row.roleplayID or "none"),
        customs = istable(customs) and customs or nil,
    })
end
C.FromRow = FromRow

function C.LoadAll(done)
    DB.Query("SELECT * FROM sy_characters WHERE charActive <> 0", function(rows)
        C.loaded = {}
        for _, row in ipairs(rows) do FromRow(row) end
        symchars.print(#rows .. " Charaktere geladen.")
        if done then done() end
    end, function() if done then done() end end)
end

function C.Sync(char, ply)
    if not char then return end
    if not char:IsActive() then
        symchars.net.Send("char_removed", { id = char.charID }, ply)
        return
    end
    symchars.net.Send("char", char:ToTable({ excludeHistory = true }), ply)
end

function C.SyncAll(ply)
    local list = {}
    for _, char in pairs(C.loaded) do
        if char:IsActive() then list[#list + 1] = char:ToTable({ excludeHistory = true }) end
    end
    symchars.net.Send("chars_full", list, ply)
end

---------------------------------------------------------------------------------------------------------------
-- Ränge / Limits
---------------------------------------------------------------------------------------------------------------
function C.CountPlayersInRank(factionID, rank, excludeCharID)
    local count, users = 0, {}
    for _, char in pairs(C.loaded) do
        if char:IsActive() and char.faction == factionID and char:GetRank() == rank and char.charID ~= excludeCharID then
            local user = tostring(char.charUser)
            if not users[user] then users[user] = true count = count + 1 end
        end
    end
    return count, users
end

function C.CanUseFactionRank(charUser, factionID, rank, excludeCharID)
    local faction = F.Get(factionID)
    if not faction then return false end
    local rankData = faction:GetRank(rank)
    if not rankData then return false end
    local max = F.GetRankMax(rankData)
    if max <= 0 then return true, max, rankData end
    local count, users = C.CountPlayersInRank(factionID, rank, excludeCharID)
    if users[tostring(charUser)] then return true, max, rankData end
    return count < max, max, rankData
end

local function RankFullText(faction, rank)
    local r = faction and faction:GetRank(rank)
    return "Der Rang " .. (r and r.name or tostring(rank)) .. " ist voll (" .. F.GetRankMax(r) .. " Plätze)."
end

---------------------------------------------------------------------------------------------------------------
-- Spieler anwenden (Name, Job, Modell, Werte)
---------------------------------------------------------------------------------------------------------------
function C.ResolveJob(char)
    if istable(char.customs) and U.Trim(char.customs.job) ~= "" and char.customs.job ~= "none" and U.GetJob(char.customs.job) then
        return char.customs.job
    end
    if symchars.Config("usefactions") then
        local rank = char:GetRankData()
        if rank and U.Trim(rank.job) ~= "" and U.GetJob(rank.job) then return rank.job end
        local faction = char:GetFaction()
        if faction and U.GetJob(faction.job) then return faction.job end
    end
    if U.GetJob(char.job) then return char.job end
    return symchars.Config("defaultjob") or "teamzivilisten"
end

function C.ResolveModel(char)
    if istable(char.customs) and U.ValidModel(char.customs.model) then return char.customs.model end
    local rank = char:GetRankData()
    local extras = rank and F.GetRankExtras(rank)
    if extras and U.ValidModel(extras.model) then return extras.model end
    local models = U.JobModels(char.job)
    if U.Trim(char.model) ~= "" then
        for _, m in ipairs(models) do
            if string.lower(m) == string.lower(char.model) then return char.model end
        end
        if #models == 0 then return char.model end
    end
    return models[1] or char.model
end

local function ChangeTeam(ply, command)
    local job = U.GetJob(command)
    if not job or not ply.changeTeam then return false end
    if ply:Team() == job.team then return false end
    ply.symchars_allowteam = true
    ply:changeTeam(job.team, true, true, true)
    ply.symchars_allowteam = nil
    return true
end

function C.ApplyName(ply, char)
    char = char or ply:GetCharacter()
    if not char then return end
    local name = UT.BuildPlayerName(char)
    if name and name ~= "" and ply.setDarkRPVar then ply:setDarkRPVar("rpname", name) end
end

-- Wendet Job + Modell + Name an.
-- respawn = true erzwingt einen Respawn, auch wenn der Job gleich bleibt.
-- keepPos = Position nach dem Respawn beibehalten (Standard: Einstellung "Wechsel ohne Respawn")
function C.RefreshPlayer(ply, respawn, keepPos)
    local char = IsValid(ply) and ply:GetCharacter()
    if not char then return end
    if keepPos == nil then keepPos = symchars.Config("changesonpos") == true end

    local job = C.ResolveJob(char)
    if job ~= char.job then
        char.job = job
        Update(char, { job = job })
    end

    local model = C.ResolveModel(char)
    if model and model ~= "" and model ~= char.model then
        char.model = model
        Update(char, { model = model })
    end

    C.ApplyName(ply, char)

    local wasAlive = ply:Alive()
    local pos, ang = ply:GetPos(), ply:EyeAngles()
    local changed = ChangeTeam(ply, job)

    if respawn and not changed and ply:Alive() then ply:KillSilent() end

    if changed or respawn then
        timer.Simple(0, function()
            if not IsValid(ply) then return end
            if not ply:Alive() then
                ply:Spawn()
            else
                -- DarkRP mit "norespawn": Spieler lebt noch -> Modell/Werte direkt setzen
                local current = ply:GetCharacter()
                local mdl = current and C.ResolveModel(current)
                if mdl and mdl ~= "" then ply:SetModel(mdl) end
                C.ApplyExtras(ply, true)
            end
            if keepPos and wasAlive then
                ply:SetPos(pos)
                ply:SetEyeAngles(ang)
            end
        end)
    else
        if model and ply:GetModel() ~= model then ply:SetModel(model) end
        C.ApplyExtras(ply, false)
    end

    C.Sync(char)
end

-- HP/Rüstung/Tempo/Waffen aus Rang, Custom-Charakter und Fortbildungen
function C.ApplyExtras(ply, fresh)
    local char = IsValid(ply) and ply:GetCharacter()
    if not char then return end

    if fresh or not ply.symchars_base then
        ply.symchars_base = {
            hp = ply:GetMaxHealth(), ap = ply:GetMaxArmor(), walk = ply:GetWalkSpeed(), run = ply:GetRunSpeed(),
            slow = ply.GetSlowWalkSpeed and ply:GetSlowWalkSpeed() or nil,
        }
    end
    local base = ply.symchars_base

    local extras = symchars.Config("usefactions") and F.GetRankExtras(char:GetRankData()) or F.NormalizeRankExtras()
    local customs = istable(char.customs) and char.customs or {}
    local addHP, addAP = U.Int(customs.hp, 0, 0, 5000), U.Int(customs.ap, 0, 0, 5000)

    local maxHP = math.max(1, (extras.health > 0 and extras.health or base.hp) + addHP)
    local maxAP = math.max(0, (extras.armor > 0 and extras.armor or base.ap) + addAP)
    local oldMaxHP, oldMaxAP = ply:GetMaxHealth(), ply:GetMaxArmor()

    ply:SetMaxHealth(maxHP)
    if fresh or maxHP > oldMaxHP then ply:SetHealth(maxHP) else ply:SetHealth(math.min(ply:Health(), maxHP)) end
    ply:SetMaxArmor(maxAP)
    if fresh or maxAP > oldMaxAP then ply:SetArmor(maxAP) else ply:SetArmor(math.min(ply:Armor(), maxAP)) end

    local speed = extras.speed or 0
    ply:SetWalkSpeed(math.max(1, base.walk + speed))
    ply:SetRunSpeed(math.max(1, base.run + speed))
    if base.slow and ply.SetSlowWalkSpeed then ply:SetSlowWalkSpeed(math.max(1, base.slow + speed)) end

    local give = {}
    for _, w in ipairs(extras.weapons or {}) do give[#give + 1] = w end
    for _, w in ipairs(istable(customs.weapons) and customs.weapons or {}) do give[#give + 1] = w end
    for _, w in ipairs(symchars.trainings.UnlockedWeapons(char)) do give[#give + 1] = w end
    for _, class in ipairs(give) do
        if isstring(class) and class ~= "" and not ply:HasWeapon(class) then ply:Give(class) end
    end
end

hook.Add("PlayerSetModel", "symchars_model", function(ply)
    local char = ply:GetCharacter()
    if not char then return end
    local model = C.ResolveModel(char)
    if model and model ~= "" then
        ply:SetModel(model)
        return true
    end
end)

hook.Add("PlayerSpawn", "symchars_spawn", function(ply)
    if not ply:GetCharacter() then return end
    timer.Simple(0.15, function()
        if not IsValid(ply) or not ply:Alive() then return end
        local char = ply:GetCharacter()
        if not char then return end
        local model = C.ResolveModel(char)
        if model and model ~= "" and ply:GetModel() ~= model then ply:SetModel(model) end
        C.ApplyExtras(ply, true)
    end)
end)

hook.Add("playerCanChangeTeam", "symchars_jobs", function(ply, team, force)
    if ply.symchars_allowteam or force then return end
    local char = ply:GetCharacter()

    -- Nationalität sperrt Jobs (z.B. Separatisten -> kein Cadet), gilt immer
    local job = RPExtraTeams and RPExtraTeams[team]
    local nat = UT.CharNationality(char)
    if job and nat and UT.NationalityBlocksJob(nat, job.command) then
        return false, "Als " .. UT.NationalityName(nat) .. " kannst du diesen Job nicht nehmen."
    end

    if not symchars.Config("blockjobchange") then return end
    if not char or not symchars.Config("usefactions") then return end
    if symchars.HasPriv(ply, "symchars_char_admin") then return end

    local allowed = {}
    local faction = char:GetFaction()
    if faction then
        allowed[faction.job] = true
        for i, rank in ipairs(faction:GetRanks()) do
            if i <= char:GetRank() and U.Trim(rank.job) ~= "" then allowed[rank.job] = true end
        end
    end
    if istable(char.customs) and char.customs.job then allowed[char.customs.job] = true end
    allowed[symchars.Config("defaultjob") or ""] = true

    if job and not allowed[job.command] then
        return false, "Dieser Job gehört nicht zu deiner Einheit."
    end
end)

---------------------------------------------------------------------------------------------------------------
-- Geld pro Charakter
---------------------------------------------------------------------------------------------------------------
function C.SaveMoney(char, ply)
    if not char or not symchars.Config("savemoney") then return end
    if not IsValid(ply) or not ply.getDarkRPVar then return end
    local money = tonumber(ply:getDarkRPVar("money"))
    if not money or money == char.money then return end
    char.money = math.floor(money)
    Update(char, { money = char.money })
end

hook.Add("playerWalletChanged", "symchars_money", function(ply)
    if not symchars.Config("savemoney") then return end
    local id = "symchars_money_" .. ply:UserID()
    timer.Create(id, 2, 1, function()
        if not IsValid(ply) then return end
        local char = ply:GetCharacter()
        if char then C.SaveMoney(char, ply) end
    end)
end)

---------------------------------------------------------------------------------------------------------------
-- Erstellen
---------------------------------------------------------------------------------------------------------------
local function RPIDTaken(rpid, excludeID, prefix)
    for _, char in pairs(C.loaded) do
        if char:IsActive() and char.charID ~= excludeID and tostring(char.roleplayID) == rpid then
            local p = UT.GetRPIDRule(char.job, char.faction)
            if p == prefix then return true end
        end
    end
    return false
end
C.RPIDTaken = RPIDTaken

function C.CreateCharacter(ply, payload, callback)
    payload = istable(payload) and payload or {}
    local steamid = ply:SteamID64()
    local useFactions = symchars.Config("usefactions")

    if #C.GetByOwner(steamid) >= UT.GetSlots(ply) then
        return false, "Du hast keinen freien Charakter-Slot."
    end

    local name = U.Clean(payload.name, 64)
    if symchars.Config("usesurnamefield") then
        local surname = U.Clean(payload.surname, 64)
        if surname ~= "" then name = name .. " " .. surname end
    end
    local okName, nameErr = UT.ValidateName(name)
    if not okName then return false, nameErr end

    local data, dataErr = C.SanitizeData(payload.data)
    if not data then return false, dataErr end
    local nat = UT.VarIsEnabled("nationality") and data.nationality or nil
    if nat == "" then nat = nil end

    local factionID, job, rank = "none", nil, 1
    if useFactions then
        local faction = F.Get(U.Lower(payload.faction))
        if not faction or not F.CanStartIn(ply, faction) then
            return false, "Diese Starteinheit ist für dich nicht verfügbar."
        end
        if nat and not UT.NationalityAllowsUnit(nat, faction) then
            return false, "Als " .. UT.NationalityName(nat) .. " kannst du nicht in " .. faction.name .. " starten."
        end
        local okRank = C.CanUseFactionRank(steamid, faction.uniqueID, 1)
        if not okRank then return false, RankFullText(faction, 1) end
        factionID = faction.uniqueID
        local r1 = faction:GetRank(1)
        job = (r1 and U.Trim(r1.job) ~= "" and U.GetJob(r1.job)) and r1.job or faction.job
    else
        job = U.Trim(payload.job)
        if not U.GetJob(job) then return false, "Dieser Job existiert nicht." end
        if not symchars.whitelist.Has(ply, job) then return false, "Du bist für diesen Job nicht freigeschaltet." end
        if nat and UT.NationalityBlocksJob(nat, job) then
            return false, "Als " .. UT.NationalityName(nat) .. " kannst du diesen Job nicht nehmen."
        end
    end

    local models = U.JobModels(job)
    local model = U.Trim(payload.model)
    local valid = false
    for _, m in ipairs(models) do if string.lower(m) == string.lower(model) then valid = true model = m break end end
    if not valid then model = models[1] or "models/player/kleiner.mdl" end

    local rpid = "none"
    if symchars.Config("useroleplayid") then
        local prefix, length = UT.GetRPIDRule(job, factionID)
        rpid = U.Trim(payload.rpid)
        if not UT.IsValidRPIDNumber(rpid, length) then
            return false, "Die RP-ID muss genau " .. length .. " Ziffern haben."
        end
        if RPIDTaken(rpid, nil, prefix) then
            return false, "Die RP-ID " .. prefix .. rpid .. " ist bereits vergeben."
        end
    end

    local money = (GAMEMODE and GAMEMODE.Config and tonumber(GAMEMODE.Config.startingmoney)) or 0
    local now = os.time()

    local q = "INSERT INTO sy_characters (charActive, charUser, name, model, job, createdAt, lastActive, faction, `rank`, money, data, roleplayID, customs) VALUES (1, "
        .. DB.Str(steamid) .. ", " .. DB.Str(name) .. ", " .. DB.Str(model) .. ", " .. DB.Str(job) .. ", " .. DB.Str(now) .. ", "
        .. DB.Str(now) .. ", " .. DB.Str(factionID) .. ", " .. DB.Num(rank) .. ", " .. DB.Num(money) .. ", " .. DB.Str(Json(data)) .. ", "
        .. DB.Str(rpid) .. ", 'none')"

    DB.Query(q, function(_, lastId)
        local function Finish(row)
            if not row then return end
            local char = FromRow(row)
            C.Sync(char)
            if factionID ~= "none" then
                symchars.history.Add(char.charID, "faction", "joined", tostring(now))
                symchars.history.Add(char.charID, "faction", "faction_history", F.Get(factionID) and F.Get(factionID).name or factionID)
            end
            symchars.history.Log(char.charID, "info", "Charakter erstellt", ply:Nick())
            hook.Run("symchars_created", ActorName(ply), char.name, char.charID, nil, Snapshot(char))
            if callback then callback(char) end
        end

        if lastId and lastId > 0 then
            DB.Query("SELECT * FROM sy_characters WHERE charID = " .. DB.Num(lastId), function(rows) Finish(rows[1]) end)
        else
            DB.Query("SELECT * FROM sy_characters WHERE charUser = " .. DB.Str(steamid) .. " ORDER BY charID DESC LIMIT 1", function(rows) Finish(rows[1]) end)
        end
    end, function() symchars.Notify(ply, "Datenbankfehler beim Erstellen.", "error") end)

    return true
end

symchars.net.Receive("char_create", function(ply, data)
    local ok, err = C.CreateCharacter(ply, data, function(char)
        if not IsValid(ply) then return end
        symchars.net.Send("char_created", { id = char.charID }, ply)
        symchars.Notify(ply, "Charakter '" .. char.name .. "' wurde erstellt.", "succ")
    end)
    if not ok then
        symchars.net.Send("char_create_failed", { msg = err }, ply)
        symchars.Notify(ply, err, "error")
    end
end, 2)

---------------------------------------------------------------------------------------------------------------
-- Auswählen
---------------------------------------------------------------------------------------------------------------
function C.SelectCharacter(ply, id)
    local char = C.Get(id)
    if not char or not char:IsActive() then return false, "Charakter nicht gefunden." end
    if tostring(char.charUser) ~= ply:SteamID64() then return false, "Das ist nicht dein Charakter." end

    local old = ply:GetCharacter()
    if old and old.charID == char.charID then return true end

    if old then
        C.SaveMoney(old, ply)
        old.lastActive = os.time()
        Update(old, { lastActive = tostring(old.lastActive) })
    end

    if symchars.Config("usefactions") and not char:GetFaction() then
        local fallbackID = F.FindFallback()
        if fallbackID then C.SetFaction(char.charID, fallbackID, { ignoreRankLimit = true, silent = true }) end
    end

    ply:SetNW2Int("symchars_charid", char.charID)
    ply.symchars_char = char
    ply.symchars_base = nil

    char.lastActive = os.time()
    Update(char, { lastActive = tostring(char.lastActive) })

    if symchars.Config("savemoney") and ply.setDarkRPVar then
        ply:setDarkRPVar("money", char.money or 0)
    end

    if symchars.history.LoadAndSync then symchars.history.LoadAndSync(char.charID, ply) end

    hook.Run("symchars_selectedcharacter", ply, char, old)

    -- neuer Charakter: immer frisch am Spawnpunkt
    C.RefreshPlayer(ply, true, false)

    symchars.print(ply:Nick() .. " spielt jetzt " .. char.name .. " (#" .. char.charID .. ")")
    return true
end

symchars.net.Receive("char_select", function(ply, data)
    if (ply.symchars_selectcd or 0) > CurTime() then
        symchars.Notify(ply, "Bitte warte kurz, bevor du wechselst.", "error")
        return
    end
    ply.symchars_selectcd = CurTime() + 4
    local ok, err = C.SelectCharacter(ply, istable(data) and data.id)
    if not ok then symchars.Notify(ply, err, "error") return end
    symchars.net.Send("char_selected", { id = istable(data) and data.id }, ply)
end, 1)

concommand.Add("symchars_choosecharacter", function(ply, _, args)
    if not IsValid(ply) then return end
    if (ply.symchars_selectcd or 0) > CurTime() then return end
    ply.symchars_selectcd = CurTime() + 4
    C.SelectCharacter(ply, tonumber(args[1]))
end)

---------------------------------------------------------------------------------------------------------------
-- Löschen
---------------------------------------------------------------------------------------------------------------
function C.DeleteCharacter(id, actor)
    local char = C.Get(id)
    if not char then return false end
    local old = Snapshot(char)

    local ply = OnlinePlayer(char)
    if IsValid(ply) then
        ply:SetNW2Int("symchars_charid", 0)
        ply.symchars_char = nil
        symchars.net.Send("menu_open", { tab = "characters", force = true }, ply)
    end

    char.charActive = 0
    Update(char, { charActive = 0 })
    C.loaded[char.charID] = nil
    symchars.net.Send("char_removed", { id = char.charID })

    FireChanges(actor, char, old)
    hook.Run("symchars_deleted", ActorName(actor), char.name, char.charID, old, Snapshot(char))
    return true
end

symchars.net.Receive("char_delete", function(ply, data)
    local char = C.Get(istable(data) and data.id)
    if not char then return end
    local own = tostring(char.charUser) == ply:SteamID64()
    if not own and not C.HasActionPermission("deletechar", ply, ply:GetCharacter(), char) then
        symchars.Notify(ply, "Dir fehlt die Berechtigung.", "error")
        return
    end
    if own and ply:GetCharacterID() == char.charID then
        symchars.Notify(ply, "Du kannst den Charakter, den du gerade spielst, nicht löschen.", "error")
        return
    end
    C.DeleteCharacter(char.charID, ply)
    symchars.Notify(ply, "Charakter '" .. char.name .. "' wurde gelöscht.", "succ")
end, 1)

---------------------------------------------------------------------------------------------------------------
-- Ändern
---------------------------------------------------------------------------------------------------------------
function C.SaveData(char)
    Update(char, { data = Json(UT.GetEnabledDataPayload(char.data or {})) })
    C.Sync(char)
end
C.DBSetData = function(id, data)
    local char = C.Get(id)
    if not char then return end
    char.data = data
    C.SaveData(char)
end

function C.SetName(id, name, actor)
    local char = C.Get(id)
    if not char then return false end
    local old = Snapshot(char)
    char.name = U.Clean(name, 64)
    Update(char, { name = char.name })
    local ply = OnlinePlayer(char)
    if IsValid(ply) then
        C.ApplyName(ply, char)
        symchars.Notify(ply, "Dein Charakter heißt jetzt " .. char.name .. ".", "info")
    end
    symchars.history.Log(char.charID, "info", "Name geändert: " .. tostring(old.name) .. " -> " .. char.name, ActorName(actor))
    C.Sync(char)
    FireChanges(actor, char, old)
    return true
end

function C.SetJob(id, job, actor)
    local char = C.Get(id)
    if not char or not U.GetJob(job) then return false end
    if not symchars.Config("usefactions") and not symchars.whitelist.Has(char.charUser, job) then return false, "whitelist" end
    local old = Snapshot(char)
    char.job = job
    char.model = C.ResolveModel(char)
    Update(char, { job = job, model = char.model })
    local ply = OnlinePlayer(char)
    if IsValid(ply) then C.RefreshPlayer(ply, not symchars.Config("changesonpos")) end
    C.Sync(char)
    FireChanges(actor, char, old)
    return true
end

-- opts: ignoreRankLimit, rank, silent, actor, keepRank, reason
function C.SetFaction(id, factionID, opts)
    opts = opts or {}
    local char = C.Get(id)
    local faction = F.Get(factionID)
    if not char or not faction then return false, "Einheit nicht gefunden." end

    local rank = 1
    if opts.keepRank then rank = math.Clamp(char:GetRank(), 1, #faction:GetRanks()) end
    if opts.rank then rank = math.Clamp(U.Int(opts.rank, 1), 1, #faction:GetRanks()) end

    if not opts.ignoreRankLimit then
        local ok = C.CanUseFactionRank(char.charUser, faction.uniqueID, rank, char.charID)
        if not ok then return false, RankFullText(faction, rank) end
    end

    local old = Snapshot(char)
    local oldFaction = char:GetFaction()
    char.faction = faction.uniqueID
    char.rank = rank
    char.job = C.ResolveJob(char)
    char.model = C.ResolveModel(char)
    Update(char, { faction = char.faction, rank = rank, job = char.job, model = char.model })

    symchars.history.Add(char.charID, "faction", "joined", tostring(os.time()))
    symchars.history.Add(char.charID, "faction", "faction_history", faction.name)
    symchars.history.Log(char.charID, "unit", (oldFaction and (oldFaction.name .. " -> ") or "") .. faction.name .. (opts.reason and (" (" .. opts.reason .. ")") or ""), ActorName(opts.actor))

    local ply = OnlinePlayer(char)
    if IsValid(ply) then
        C.RefreshPlayer(ply, not symchars.Config("changesonpos"))
        if not opts.silent then
            symchars.Notify(ply, "Du bist jetzt in " .. F.GetDisplayName(faction) .. ".", "info")
        end
    end

    C.Sync(char)
    FireChanges(opts.actor, char, old)
    return true
end

function C.SetRank(id, rank, opts)
    opts = opts or {}
    local char = C.Get(id)
    if not char then return false end
    local faction = char:GetFaction()
    if not faction then return false, "Keine Einheit." end
    rank = U.Int(rank, 1)
    if not faction:GetRank(rank) then return false, "Diesen Rang gibt es nicht." end
    if rank == char:GetRank() then return false, "Der Charakter hat diesen Rang bereits." end

    local ok = C.CanUseFactionRank(char.charUser, faction.uniqueID, rank, char.charID)
    if not ok then return false, RankFullText(faction, rank) end

    local old = Snapshot(char)
    local up = rank > char:GetRank()
    char.rank = rank
    char.job = C.ResolveJob(char)
    char.model = C.ResolveModel(char)
    Update(char, { rank = rank, job = char.job, model = char.model })

    local rankName = faction:GetRank(rank).name
    symchars.history.Add(char.charID, "faction", "last_promote", os.time())
    symchars.history.Add(char.charID, "faction", "promotions", { entry = rankName, by = ActorName(opts.actor), up = up })
    symchars.history.Log(char.charID, "rank", (up and "Befördert zu " or "Degradiert zu ") .. rankName, ActorName(opts.actor))

    local ply = OnlinePlayer(char)
    if IsValid(ply) then
        C.RefreshPlayer(ply, false)
        symchars.Notify(ply, (up and "Du wurdest befördert: " or "Du wurdest degradiert: ") .. rankName, up and "succ" or "error")
    end

    C.Sync(char)
    FireChanges(opts.actor, char, old)
    return true
end

function C.Kick(id, actor)
    local char = C.Get(id)
    local faction = char and char:GetFaction()
    if not faction then return false, "Keine Einheit." end
    local fallbackID = F.FindFallback(faction.uniqueID)
    if not fallbackID or fallbackID == faction.uniqueID then return false, "Keine Ausweich-Einheit vorhanden." end
    local old = Snapshot(char)
    local ok, err = C.SetFaction(id, fallbackID, { ignoreRankLimit = true, actor = actor, reason = "entlassen" })
    if ok then hook.Run("symchars_kicked", ActorName(actor), char.name, char.charID, old.faction, char.faction) end
    return ok, err
end

function C.SetRoleplayID(id, rpid, actor)
    local char = C.Get(id)
    if not char then return false end
    rpid = U.Trim(rpid)
    local prefix, length = UT.GetRPIDRule(char.job, char.faction)
    if not UT.IsValidRPIDNumber(rpid, length) then return false, "Die RP-ID muss genau " .. length .. " Ziffern haben." end
    if RPIDTaken(rpid, char.charID, prefix) then return false, "Diese RP-ID ist bereits vergeben." end
    local old = Snapshot(char)
    char.roleplayID = rpid
    Update(char, { roleplayID = rpid })
    local ply = OnlinePlayer(char)
    if IsValid(ply) then
        C.ApplyName(ply, char)
        symchars.Notify(ply, "Deine RP-ID ist jetzt " .. prefix .. rpid .. ".", "info")
    end
    symchars.history.Log(char.charID, "info", "RP-ID geändert zu " .. prefix .. rpid, ActorName(actor))
    C.Sync(char)
    FireChanges(actor, char, old)
    return true
end

function C.SetMoney(id, amount, actor)
    local char = C.Get(id)
    if not char then return false end
    local old = Snapshot(char)
    char.money = U.Int(amount, 0, 0, 2000000000)
    Update(char, { money = char.money })
    local ply = OnlinePlayer(char)
    if IsValid(ply) and ply.setDarkRPVar then
        ply:setDarkRPVar("money", char.money)
        symchars.Notify(ply, "Dein Guthaben wurde auf " .. U.FormatMoney(char.money) .. " gesetzt.", "info")
    end
    C.Sync(char)
    FireChanges(actor, char, old)
    return true
end

function C.ApplyCustoms(id, data, actor)
    local char = C.Get(id)
    if not char then return false end
    data = istable(data) and data or {}

    local customs
    if data.remove ~= true then
        local job = U.Trim(data.job)
        if job ~= "" and job ~= "none" and not U.GetJob(job) then return false, "Dieser Job existiert nicht." end
        local model = U.Trim(data.model)
        if model ~= "" and not U.ValidModel(model) then return false, "Dieses Modell existiert nicht auf dem Server." end
        customs = {
            job = job ~= "" and job or "none",
            model = model,
            hp = U.Int(data.hp, 0, 0, 5000),
            ap = U.Int(data.ap, 0, 0, 5000),
            weapons = U.StringList(data.weapons, 64, 96),
        }
    end

    local old = Snapshot(char)
    char.customs = customs
    char.job = C.ResolveJob(char)
    char.model = C.ResolveModel(char)
    Update(char, { customs = CustomsToDB(char), job = char.job, model = char.model })
    symchars.history.Log(char.charID, "info", customs and "Custom-Charakter eingerichtet" or "Custom-Charakter entfernt", ActorName(actor))

    local ply = OnlinePlayer(char)
    if IsValid(ply) then
        C.RefreshPlayer(ply, true)
        symchars.Notify(ply, customs and "Dein Charakter ist jetzt ein Custom-Charakter." or "Dein Custom-Charakter wurde entfernt.", "info")
    end
    C.Sync(char)
    FireChanges(actor, char, old)
    return true
end

---------------------------------------------------------------------------------------------------------------
-- Einladungen
---------------------------------------------------------------------------------------------------------------
local invites = {}

function C.Invite(targetID, inviterChar, inviterPly)
    local target = C.Get(targetID)
    local faction = inviterChar and inviterChar:GetFaction()
    if not target or not faction then return false, "Ungültige Einladung." end
    if target.faction == faction.uniqueID then return false, target.name .. " ist bereits in deiner Einheit." end
    local targetPly = OnlinePlayer(target)
    if not IsValid(targetPly) then return false, target.name .. " ist nicht online." end
    if not C.CanUseFactionRank(target.charUser, faction.uniqueID, 1, target.charID) then return false, RankFullText(faction, 1) end
    local nat = UT.CharNationality(target)
    if nat and not UT.NationalityAllowsUnit(nat, faction) then
        return false, target.name .. " ist " .. UT.NationalityName(nat) .. " und kann dieser Einheit nicht beitreten."
    end

    invites[target.charID] = { faction = faction.uniqueID, by = inviterChar.charID, byName = UT.BuildDisplayName(inviterChar), expires = CurTime() + 60 }
    symchars.net.Send("invite", { id = target.charID, unit = faction.uniqueID, by = UT.BuildDisplayName(inviterChar), time = 60 }, targetPly)
    hook.Run("symchars_invited", ActorName(inviterPly), target.name, target.charID, nil, inviterChar.charID)
    return true
end

symchars.net.Receive("invite_answer", function(ply, data)
    local char = ply:GetCharacter()
    if not char or not istable(data) then return end
    local invite = invites[char.charID]
    if not invite or invite.expires < CurTime() then
        invites[char.charID] = nil
        return
    end
    invites[char.charID] = nil

    local inviter = C.Get(invite.by)
    local inviterPly = inviter and OnlinePlayer(inviter)

    if data.accept ~= true then
        if IsValid(inviterPly) then symchars.Notify(inviterPly, char.name .. " hat die Einladung abgelehnt.", "error") end
        return
    end

    local ok, err = C.SetFaction(char.charID, invite.faction, { actor = inviterPly, reason = "Einladung von " .. invite.byName })
    if not ok then
        symchars.Notify(ply, err, "error")
        return
    end
    if IsValid(inviterPly) then symchars.Notify(inviterPly, char.name .. " hat die Einladung angenommen.", "succ") end
end, 1)

---------------------------------------------------------------------------------------------------------------
-- Einheit beitreten (frei beitretbare Einheiten)
---------------------------------------------------------------------------------------------------------------
symchars.net.Receive("unit_join", function(ply, data)
    local char = ply:GetCharacter()
    local faction = F.Get(U.Lower(istable(data) and data.id))
    if not char or not faction then return end
    if not faction.isJoinable then symchars.Notify(ply, "Dieser Einheit kann man nicht frei beitreten.", "error") return end
    if char.faction == faction.uniqueID then return end
    local nat = UT.CharNationality(char)
    if nat and not UT.NationalityAllowsUnit(nat, faction) then
        symchars.Notify(ply, "Als " .. UT.NationalityName(nat) .. " kannst du dieser Einheit nicht beitreten.", "error")
        return
    end
    local ok, err = C.SetFaction(char.charID, faction.uniqueID, { actor = ply, reason = "beigetreten" })
    if not ok then symchars.Notify(ply, err, "error") end
end, 3)

---------------------------------------------------------------------------------------------------------------
-- Aktionen aus der Verwaltung
---------------------------------------------------------------------------------------------------------------
local actions = C.actions

actions.promote.Execute = function(ply, actor, target)
    return C.SetRank(target.charID, target:GetRank() + 1, { actor = ply })
end

actions.demote.Execute = function(ply, actor, target)
    return C.SetRank(target.charID, target:GetRank() - 1, { actor = ply })
end

actions.setrank.Execute = function(ply, actor, target, value)
    local rank = U.Int(value, 0)
    local faction = target:GetFaction()
    if not faction or not faction:GetRank(rank) then return false, "Ungültiger Rang." end
    if not (symchars.HasPriv(ply, "symchars_char_ranksmanage") or symchars.HasPriv(ply, "symchars_char_admin")) then
        local _, kind, byRank = A.CanActOn(actor, target, "promotions")
        if (kind == "same" or byRank) and rank >= actor:GetRank() then
            return false, "Du kannst höchstens bis unter deinen eigenen Rang befördern."
        end
    end
    return C.SetRank(target.charID, rank, { actor = ply })
end

actions.transfer.Execute = function(ply, actor, target, value)
    value = istable(value) and value or {}
    local dest = F.Get(U.Lower(value.unit))
    if not dest then return false, "Einheit nicht gefunden." end
    if dest.uniqueID == target.faction then return false, "Der Charakter ist bereits in dieser Einheit." end
    if not symchars.HasPriv(ply, "symchars_char_changefaction") and not symchars.HasPriv(ply, "symchars_char_admin") then
        if not A.HasFlag(actor, dest.uniqueID, "transfer") then
            return false, "Du hast keine Befehlsgewalt über die Ziel-Einheit."
        end
    end
    return C.SetFaction(target.charID, dest.uniqueID, { actor = ply, keepRank = value.keepRank == true, reason = "versetzt" })
end

actions.kick.Execute = function(ply, actor, target)
    return C.Kick(target.charID, ply)
end

actions.invite.Execute = function(ply, actor, target)
    return C.Invite(target.charID, actor, ply)
end

actions.changname.Execute = function(ply, actor, target, value)
    local name = U.Clean(value, 64)
    if name == "" then return false, "Der Name darf nicht leer sein." end
    return C.SetName(target.charID, name, ply)
end

actions.rpidchange.Execute = function(ply, actor, target, value)
    return C.SetRoleplayID(target.charID, value, ply)
end

actions.changemoney.Execute = function(ply, actor, target, value)
    if not tonumber(value) then return false, "Bitte eine Zahl angeben." end
    return C.SetMoney(target.charID, tonumber(value), ply)
end

actions.changefact.Execute = function(ply, actor, target, value)
    local id = istable(value) and value.unit or value
    return C.SetFaction(target.charID, U.Lower(id), { actor = ply, ignoreRankLimit = true, keepRank = istable(value) and value.keepRank == true, reason = "Admin" })
end

actions.jobchange.Execute = function(ply, actor, target, value)
    return C.SetJob(target.charID, U.Trim(value), ply)
end

actions.customs.Execute = function(ply, actor, target, value)
    return C.ApplyCustoms(target.charID, value, ply)
end

actions.deletechar.Execute = function(ply, actor, target)
    return C.DeleteCharacter(target.charID, ply)
end

symchars.net.Receive("char_action", function(ply, data)
    if not istable(data) then return end
    local action = C.GetAction(data.action)
    local target = C.Get(data.id)
    if not action or not action.Execute or not target then return end
    local actor = ply:GetCharacter()

    local allowed = C.HasActionPermission(data.action, ply, actor, target)
    if not allowed then
        symchars.Notify(ply, "Dir fehlt die Berechtigung für diese Aktion.", "error")
        return
    end

    local ok, err = action.Execute(ply, actor, target, data.value)
    if ok == false then
        symchars.Notify(ply, err or "Die Aktion ist fehlgeschlagen.", "error")
    elseif ok ~= nil then
        symchars.Notify(ply, action.Name .. ": " .. UT.BuildDisplayName(target), "succ")
    end
end, 0.4)

---------------------------------------------------------------------------------------------------------------
-- Verbindung
---------------------------------------------------------------------------------------------------------------
hook.Add("PlayerDisconnected", "symchars_disconnect", function(ply)
    local char = ply:GetCharacter()
    if not char then return end
    C.SaveMoney(char, ply)
    char.lastActive = os.time()
    Update(char, { lastActive = tostring(char.lastActive) })
    invites[char.charID] = nil
end)

hook.Add("PlayerDeath", "symchars_deathmenu", function(ply)
    if symchars.Config("forcemenuondeath") then
        symchars.net.Send("menu_open", { tab = "characters" }, ply)
    end
end)
