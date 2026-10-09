local WS = GRNSerials
local C = WS.Config
local DB = WS.DB
local ST = WS.STATUS

util.AddNetworkString("ws_req")
util.AddNetworkString("ws_data")
util.AddNetworkString("ws_msg")

local STATION_DISTANCE = 160

local function sid(ply) return IsValid(ply) and ply:SteamID64() or nil end

local function send(ply, payload)
    local json = util.TableToJSON(payload, false) or "{}"
    local data = util.Compress(json) or ""
    net.Start("ws_data")
        net.WriteUInt(#data, 32)
        net.WriteData(data, #data)
    net.Send(ply)
end

local function msg(ply, ok, text)
    net.Start("ws_msg")
        net.WriteBool(ok == true)
        net.WriteString(tostring(text or ""))
    net.Send(ply)
end

-- ---------------------------------------------------------
-- Ansichten
-- ---------------------------------------------------------
function WS.Summary(rec)
    local owner = rec.owner_sid64 and player.GetBySteamID64(rec.owner_sid64)
    return {
        serial = rec.serial,
        name = WS.DisplayName(rec),
        label = WS.WeaponLabel(rec),
        class = rec.class,
        status = rec.status,
        statusLabel = WS.StatusLabels[rec.status] or rec.status,
        condition = math.Round(rec.condition, 1),
        dirt = math.Round(rec.dirt, 1),
        kills = rec.kills_total,
        rounds = rec.rounds_fired,
        tradition = rec.is_tradition,
        honor = rec.honor_name,
        nickname = rec.nickname,
        owner = rec.owner_name,
        ownerOnline = IsValid(owner),
        ownerAlive = IsValid(owner) and owner:Alive(),
        created = rec.created_at,
        regiment = rec.regiment_id,
        regimentName = WS.RegimentName(rec.regiment_id),
        tier = WS.TierFor(rec.condition).Label,
        locked = rec.locked,
        canBarrel = WS.CanBarrelChange(rec),
        repairCost = WS.RepairCost(rec),
    }
end

local function events(serial, types, limit)
    local list = {}
    local placeholders = {}
    for i = 1, #types do placeholders[i] = "?" end
    local rows = DB.Rows("SELECT * FROM ws_events WHERE serial = ? AND type IN (" .. table.concat(placeholders, ",") .. ") ORDER BY id DESC LIMIT " .. math.floor(limit),
        serial, unpack(types))
    for _, r in ipairs(rows) do
        list[#list + 1] = { type = r.type, ts = tonumber(r.ts) or 0, data = util.JSONToTable(r.data or "") or {} }
    end
    return list
end

function WS.Dossier(rec, viewer)
    WS.Flush()
    local d = WS.Summary(rec)
    d.valid = WS.IsValidSerial(rec.serial)
    d.longest = rec.longest_kill
    d.holderCount = rec.holders
    d.barrelRounds = rec.barrel_rounds
    d.batch = rec.batch
    d.statusSince = rec.status_since

    d.holders = {}
    for _, h in ipairs(DB.Rows("SELECT * FROM ws_holders WHERE serial = ? ORDER BY from_ts ASC", rec.serial)) do
        d.holders[#d.holders + 1] = {
            name = h.holder_name, from = tonumber(h.from_ts) or 0, to = tonumber(h.to_ts) or nil,
            kills = tonumber(h.kills) or 0, ended = h.ended ~= "NULL" and h.ended or nil,
        }
    end

    d.milestones = {}
    local got = {}
    for _, m in ipairs(DB.Rows("SELECT * FROM ws_milestones WHERE serial = ? ORDER BY ts ASC", rec.serial)) do got[m.milestone] = m end
    for _, def in ipairs(C.Milestones or {}) do
        local m = got[def.ID]
        d.milestones[#d.milestones + 1] = {
            id = def.ID, name = def.Name, icon = def.Icon, engraving = def.Engraving,
            reached = m ~= nil, ts = m and tonumber(m.ts) or nil, holder = m and m.holder_name ~= "NULL" and m.holder_name or nil,
        }
    end

    d.killLog = events(rec.serial, { "kill" }, C.History.KillDetail)
    d.deaths = events(rec.serial, { "death", "recovered" }, C.History.DeathDetail)
    d.service = events(rec.serial, { "repair", "clean", "barrel" }, C.History.ServiceDetail)
    d.log = events(rec.serial, { "created", "issue", "return", "auto_return", "owner", "dropped", "broken", "teamkill", "nickname",
        "tradition", "tradition_proposed", "tradition_rejected", "ceremony", "retired", "admin", "milestone" }, 60)

    local isOwner = rec.owner_sid64 and rec.owner_sid64 == sid(viewer)
    d.canNick = isOwner and not rec.is_tradition
    d.nickReadyAt = (rec.nick_changed_at or 0) + C.Nickname.Cooldown
    d.isAdmin = WS.IsAdmin(viewer)
    d.now = os.time()
    local prop = DB.Row("SELECT * FROM ws_tradition_proposals WHERE serial = ?", rec.serial)
    d.proposal = prop and { honor = prop.honor_name, by = prop.proposer_name, ts = tonumber(prop.ts) } or nil
    return d
end

local function canViewDossier(ply, rec)
    if WS.IsAdmin(ply) then return true end
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and WS.GetWeaponSerial(wep) == rec.serial then return true end
    if rec.owner_sid64 == sid(ply) then return true end
    -- Am Boden liegend und angeschaut
    local tr = ply:GetEyeTrace()
    if IsValid(tr.Entity) and tr.Entity.GRNSerial == rec.serial and tr.HitPos:DistToSqr(ply:EyePos()) < 200 * 200 then return true end
    -- Am Terminal: Akten des eigenen Regiments
    local st = ply.WSStation
    if st and IsValid(st.ent) and ply:GetPos():DistToSqr(st.ent:GetPos()) < STATION_DISTANCE * STATION_DISTANCE
            and (rec.regiment_id == WS.GetRegiment(ply) or st.kind == "vitrine") then
        return true
    end
    return false
end

local function regimentRows(regiment, where)
    return DB.Rows("SELECT * FROM ws_weapons WHERE (regiment_id = ? OR (? IS NULL AND regiment_id IS NULL)) AND " .. where .. " ORDER BY class ASC, condition DESC", regiment, regiment)
end

local function chronicle(regiment, limit)
    local out = {}
    for _, r in ipairs(DB.Rows("SELECT * FROM ws_regiment_chronicle WHERE regiment_id = ? ORDER BY id DESC LIMIT " .. (limit or 40), regiment or "")) do
        out[#out + 1] = { text = r.text, ts = tonumber(r.ts) or 0, serial = r.serial }
    end
    return out
end

local function summaries(rows)
    local out = {}
    for _, row in ipairs(rows) do
        local rec = WS.Get(row.serial)
        if rec then out[#out + 1] = WS.Summary(rec) end
    end
    return out
end

local function nearbyPlayers(ply)
    local out = {}
    local radius = (C.Tradition.CeremonyRadius or 3) * (C.UnitsPerMeter or 52.49) * 2
    for _, p in ipairs(player.GetAll()) do
        if p ~= ply and p:Alive() and p:GetPos():DistToSqr(ply:GetPos()) <= radius * radius then
            out[#out + 1] = { sid = p:SteamID64(), name = p:Nick() }
        end
    end
    return out
end

local function issuableClasses(ply)
    local out = {}
    if GRNStore and isfunction(GRNStore.WeaponMapFor) then
        local ok, map = pcall(GRNStore.WeaponMapFor, ply)
        if ok and istable(map) then
            for _, data in pairs(map) do
                if istable(data) and data.className then out[data.className] = true end
            end
        end
    end
    return out
end

function WS.TerminalView(ply, regiment)
    WS.Flush()
    regiment = regiment or WS.GetRegiment(ply)
    local proposals = {}
    for _, p in ipairs(DB.Rows("SELECT * FROM ws_tradition_proposals WHERE regiment_id = ? ORDER BY ts DESC", regiment)) do
        local rec = WS.Get(p.serial)
        if rec then
            local s = WS.Summary(rec)
            s.proposedHonor, s.proposedBy, s.proposedAt = p.honor_name, p.proposer_name, tonumber(p.ts)
            proposals[#proposals + 1] = s
        end
    end
    local regiments = {}
    if WS.IsAdmin(ply) then
        for id, name in SortedPairs(C.RegimentNames or {}) do regiments[#regiments + 1] = { id = id, name = name } end
    end
    return {
        mode = "terminal",
        regiment = regiment,
        regimentName = WS.RegimentName(regiment),
        regiments = regiments,
        stored = summaries(regimentRows(regiment, "status IN ('STORED','BROKEN') AND is_tradition = 0")),
        issued = summaries(regimentRows(regiment, "status IN ('ISSUED','DROPPED','CAPTURED')")),
        tradition = summaries(regimentRows(regiment, "is_tradition = 1 AND status != 'RETIRED'")),
        archive = summaries(regimentRows(regiment, "status = 'RETIRED'")),
        proposals = proposals,
        chronicle = chronicle(regiment, 40),
        issuable = issuableClasses(ply),
        nearby = nearbyPlayers(ply),
        canPropose = WS.CanPropose(ply),
        canConfirm = WS.CanConfirm(ply),
        isAdmin = WS.IsAdmin(ply),
        maxTradition = C.Tradition.MaxPerRegiment,
        now = os.time(),
    }
end

function WS.BenchView(ply)
    WS.Flush()
    local regiment = WS.GetRegiment(ply)
    local wep = ply:GetActiveWeapon()
    local inHand = IsValid(wep) and WS.Get(WS.GetWeaponSerial(wep))
    local parts = 0
    local state = GRNInventory and GRNInventory.GetState(ply)
    for _, item in ipairs(state and state.items or {}) do
        if item.id == C.SparePartsItem then parts = parts + item.qty end
    end
    return {
        mode = "bench",
        regiment = regiment,
        regimentName = WS.RegimentName(regiment),
        inHand = inHand and WS.Summary(inHand) or nil,
        -- Der Waffenmeister arbeitet für alle Regimenter, andere sehen nur ihr eigenes.
        queue = summaries(WS.IsArmorer(ply)
            and DB.Rows("SELECT serial FROM ws_weapons WHERE status IN ('STORED','BROKEN') AND condition < 100 ORDER BY condition ASC LIMIT 200")
            or regimentRows(regiment, "status IN ('STORED','BROKEN') AND condition < 100")),
        isArmorer = WS.IsArmorer(ply),
        isAdmin = WS.IsAdmin(ply),
        parts = parts,
        barrelParts = C.BarrelChangeParts,
        now = os.time(),
    }
end

function WS.VitrineView(ply, ent)
    local regiment = IsValid(ent) and ent:GetNW2String("ws_regiment", "") or ""
    if regiment == "" then regiment = WS.GetRegiment(ply) end
    return {
        mode = "vitrine",
        regiment = regiment,
        regimentName = WS.RegimentName(regiment),
        tradition = summaries(regimentRows(regiment, "is_tradition = 1")),
        chronicle = chronicle(regiment, 80),
        now = os.time(),
    }
end

function WS.OpenStation(ply, ent, kind)
    ply.WSStation = { ent = ent, kind = kind }
    if kind == "terminal" then send(ply, WS.TerminalView(ply))
    elseif kind == "bench" then send(ply, WS.BenchView(ply))
    elseif kind == "vitrine" then send(ply, WS.VitrineView(ply, ent)) end
end

local function atStation(ply, kind)
    local st = ply.WSStation
    if not st or not IsValid(st.ent) or (kind and st.kind ~= kind) then return false end
    return ply:GetPos():DistToSqr(st.ent:GetPos()) < STATION_DISTANCE * STATION_DISTANCE
end

local function refresh(ply)
    local st = ply.WSStation
    if st and atStation(ply) then WS.OpenStation(ply, st.ent, st.kind) end
end

-- ---------------------------------------------------------
-- Anfragen
-- ---------------------------------------------------------
local handlers = {}

handlers.pass = function(ply, data)
    local rec
    if isstring(data.serial) and data.serial ~= "" then
        rec = WS.Get(data.serial)
    else
        local wep = ply:GetActiveWeapon()
        rec = IsValid(wep) and WS.Get(WS.GetWeaponSerial(wep))
        if not rec then
            local tr = ply:GetEyeTrace()
            if IsValid(tr.Entity) and tr.Entity.GRNSerial then rec = WS.Get(tr.Entity.GRNSerial) end
        end
    end
    if not rec then return msg(ply, false, "Diese Waffe hat keine Seriennummer.") end
    if not canViewDossier(ply, rec) then return msg(ply, false, "Du kannst diese Akte nicht einsehen.") end
    local d = WS.Dossier(rec, ply)
    d.mode = "dossier"
    d.back = data.back
    send(ply, d)
end

handlers.station = function(ply, data)
    if atStation(ply) then refresh(ply) end
end

handlers.terminal_regiment = function(ply, data)
    if not WS.IsAdmin(ply) or not atStation(ply, "terminal") then return end
    send(ply, WS.TerminalView(ply, tostring(data.regiment or "")))
end

handlers.take = function(ply, data)
    if not atStation(ply, "terminal") then return msg(ply, false, "Du stehst nicht am Waffenkammer-Terminal.") end
    local rec = WS.Get(tostring(data.serial or ""))
    if not rec or rec.status ~= ST.STORED then return msg(ply, false, "Diese Waffe ist nicht eingelagert.") end
    if rec.is_tradition then return msg(ply, false, "Traditionswaffen werden per Übergabe-Zeremonie ausgegeben.") end
    if rec.locked then return msg(ply, false, "Diese Waffe ist gesperrt.") end
    if rec.regiment_id ~= WS.GetRegiment(ply) and not WS.IsAdmin(ply) then return msg(ply, false, "Die Waffe gehört einem anderen Regiment.") end
    local lastHolder = DB.Value("SELECT holder_sid64 FROM ws_holders WHERE serial = ? ORDER BY id DESC LIMIT 1", rec.serial)
    if lastHolder and lastHolder ~= sid(ply) and os.time() - (rec.last_transfer or 0) < C.AntiFarm.TransferCooldown then
        return msg(ply, false, "Besitzerwechsel-Sperre: diese Waffe hat eben erst den Träger gewechselt.")
    end
    local map = GRNStore and GRNStore.WeaponMapFor and GRNStore.WeaponMapFor(ply) or {}
    local weaponData
    for _, d in pairs(map) do
        if istable(d) and d.className == rec.class then weaponData = d break end
    end
    if not weaponData or not GRNStore.IssueWeapon then return msg(ply, false, "Diese Waffenart ist für deinen Job nicht freigegeben.") end
    ply.WSWantedSerial = { serial = rec.serial, class = rec.class }
    local ok, text = GRNStore.IssueWeapon(ply, weaponData)
    ply.WSWantedSerial = nil
    msg(ply, ok, text)
    refresh(ply)
end

handlers.nick = function(ply, data)
    local rec = WS.Get(tostring(data.serial or ""))
    if not rec then return end
    local ok, text = WS.SetNickname(ply, rec, data.nick)
    msg(ply, ok, text)
    if ok then handlers.pass(ply, { serial = rec.serial }) end
end

handlers.propose = function(ply, data)
    if not atStation(ply, "terminal") and not WS.IsAdmin(ply) then return end
    local rec = WS.Get(tostring(data.serial or ""))
    if not rec then return end
    local ok, text = WS.Propose(ply, rec, data.honor)
    msg(ply, ok, text)
    refresh(ply)
end

handlers.confirm = function(ply, data)
    if not atStation(ply, "terminal") and not WS.IsAdmin(ply) then return end
    local rec = WS.Get(tostring(data.serial or ""))
    if not rec then return end
    local ok, text = WS.Confirm(ply, rec, data.accept == true)
    msg(ply, ok, text)
    refresh(ply)
end

handlers.ceremony = function(ply, data)
    local rec = WS.Get(tostring(data.serial or ""))
    local target = player.GetBySteamID64(tostring(data.target or ""))
    if not rec then return end
    local ok, text = WS.Ceremony(ply, rec, target)
    msg(ply, ok, text)
    refresh(ply)
end

handlers.repair = function(ply, data)
    if not atStation(ply, "bench") then return msg(ply, false, "Dafür brauchst du eine Werkbank.") end
    local rec = WS.Get(tostring(data.serial or ""))
    if not rec then return end
    if rec.status == ST.ISSUED and rec.owner_sid64 ~= sid(ply) then
        local holder = player.GetBySteamID64(rec.owner_sid64 or "")
        if not IsValid(holder) or holder:GetPos():DistToSqr(ply:GetPos()) > STATION_DISTANCE * STATION_DISTANCE then
            return msg(ply, false, "Der Träger muss mit der Waffe an der Werkbank stehen.")
        end
    end
    local ok, text = WS.Repair(ply, rec)
    msg(ply, ok, text)
    refresh(ply)
end

handlers.barrel = function(ply, data)
    if not atStation(ply, "bench") then return end
    local rec = WS.Get(tostring(data.serial or ""))
    if not rec then return end
    local ok, text = WS.BarrelChange(ply, rec)
    msg(ply, ok, text)
    refresh(ply)
end

handlers.retire = function(ply, data)
    if not atStation(ply, "bench") and not WS.IsAdmin(ply) then return end
    local rec = WS.Get(tostring(data.serial or ""))
    if not rec then return end
    local ok, text = WS.Retire(ply, rec)
    msg(ply, ok, text)
    refresh(ply)
end

handlers.admin_search = function(ply, data)
    if not WS.IsAdmin(ply) then return end
    local q = string.Trim(tostring(data.query or ""))
    local like = "%" .. q .. "%"
    local rows = DB.Rows([[SELECT serial FROM ws_weapons WHERE serial LIKE ? OR nickname LIKE ? OR honor_name LIKE ?
        OR owner_name LIKE ? OR owner_sid64 = ? OR class LIKE ? ORDER BY created_at DESC LIMIT 60]], like, like, like, like, q, like)
    WS.Flush()
    send(ply, { mode = "admin", query = q, results = summaries(rows), statuses = table.GetKeys(WS.STATUS), now = os.time() })
end

handlers.admin_edit = function(ply, data)
    if not WS.IsAdmin(ply) then return end
    local rec = WS.Get(tostring(data.serial or ""))
    if not rec then return end
    local ok, text = WS.AdminEdit(ply, rec, istable(data.fields) and data.fields or {})
    msg(ply, ok, text)
    handlers.pass(ply, { serial = rec.serial, back = "admin" })
end

handlers.admin_rollback = function(ply, data)
    if not WS.IsAdmin(ply) then return end
    local target = tostring(data.sid64 or "")
    if not string.match(target, "^%d+$") then
        local p = player.GetBySteamID(target)
        target = IsValid(p) and p:SteamID64() or target
    end
    local hours = math.Clamp(tonumber(data.hours) or 1, 0, 24 * 90)
    local ok, text = WS.Rollback(ply, target, os.time() - hours * 3600)
    msg(ply, ok, text)
end

handlers.chronicle = function(ply, data)
    local regiment = tostring(data.regiment or "")
    if regiment ~= WS.GetRegiment(ply) and not WS.IsAdmin(ply) and not atStation(ply, "vitrine") then return end
    send(ply, { mode = "chronicle", regiment = regiment, regimentName = WS.RegimentName(regiment), chronicle = chronicle(regiment, 200), now = os.time() })
end

net.Receive("ws_req", function(_, ply)
    if not C.Enabled then return end
    if (ply.WSNextReq or 0) > CurTime() then return end
    ply.WSNextReq = CurTime() + (C.RequestCooldown or 0.5)
    local action = net.ReadString()
    local raw = net.ReadString()
    local data = util.JSONToTable(raw or "") or {}
    local fn = handlers[action]
    if not fn then return end
    local ok, err = pcall(fn, ply, data)
    if not ok then ErrorNoHalt("[GRN Serials] " .. action .. ": " .. tostring(err) .. "\n") end
end)

-- Admin-Panel per Konsole / Chat
concommand.Add("ws_admin", function(ply)
    if IsValid(ply) and WS.IsAdmin(ply) then handlers.admin_search(ply, { query = "" }) end
end)

hook.Add("PlayerSay", "GRNSerials_Chat", function(ply, text)
    local lower = string.lower(string.Trim(text))
    for _, cmd in ipairs(C.PassChatCommands or {}) do
        if lower == cmd then
            ply.WSNextReq = 0
            handlers.pass(ply, {})
            return ""
        end
    end
    if lower == "!waffenadmin" and WS.IsAdmin(ply) then
        handlers.admin_search(ply, { query = "" })
        return ""
    end
end)
