-- Logistik-Kern: Standorte, Bestände, Anträge, Shuttles, Produktion, Verbrauch, Sync

util.AddNetworkString("GARLog_Sync")
util.AddNetworkString("GARLog_Action")
util.AddNetworkString("GARLog_Notify")
util.AddNetworkString("GARLog_Open")
util.AddNetworkString("GARLog_Waypoint")

local cfg = GARLog.Config
local DB = GARLog.DB

GARLog.Locations  = GARLog.Locations or {}
GARLog.Requests   = GARLog.Requests or {}
GARLog.Transports = GARLog.Transports or {}
GARLog.Containers = GARLog.Containers or {}
GARLog.Repairs    = GARLog.Repairs or {}
GARLog.Production = GARLog.Production or { lines = {} }
GARLog.LogEntries = GARLog.LogEntries or {}
GARLog.Meta       = GARLog.Meta or {}
GARLog.Subs       = GARLog.Subs or {}

local Locations, Requests, Transports = GARLog.Locations, GARLog.Requests, GARLog.Transports

local REQ_OPEN, REQ_APPROVED, REQ_TRANSIT = GARLog.REQ_OPEN, GARLog.REQ_APPROVED, GARLog.REQ_TRANSIT
local REQ_DONE, REQ_REJECTED, REQ_CANCELLED = GARLog.REQ_DONE, GARLog.REQ_REJECTED, GARLog.REQ_CANCELLED
local TRN_TRANSIT, TRN_RETURN, TRN_DONE = GARLog.TRN_TRANSIT, GARLog.TRN_RETURN, GARLog.TRN_DONE

-- Laufzeitmessung je Subsystem (Konsole: garlog_perf)
GARLog.Perf = GARLog.Perf or {}
local function PerfAdd(name, dt)
    local p = GARLog.Perf[name]
    if not p then
        p = { n = 0, sum = 0, max = 0 }
        GARLog.Perf[name] = p
    end
    p.n, p.sum = p.n + 1, p.sum + dt
    if dt > p.max then p.max = dt end
end
GARLog.PerfAdd = PerfAdd

-- Isoliert Fehler einzelner Subsysteme, damit der zentrale Takt nie stirbt, und misst die Laufzeit
local function Protected(name, fn, ...)
    local t0 = SysTime()
    local ok, err = xpcall(fn, debug.traceback, ...)
    PerfAdd(name, SysTime() - t0)
    if not ok then ErrorNoHalt("[GAR Logistik] Fehler in " .. name .. ": " .. tostring(err) .. "\n") end
end
GARLog.Protected = Protected

concommand.Add("garlog_perf", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if args[1] == "reset" then
        GARLog.Perf = {}
        print("[GAR Logistik] Messwerte zurückgesetzt.")
        return
    end
    local list = {}
    for name, p in pairs(GARLog.Perf) do list[#list + 1] = { name = name, p = p } end
    table.sort(list, function(a, b) return a.p.sum > b.p.sum end)
    print(string.format("%-34s %8s %10s %10s %10s", "GAR LOGISTIK (Server)", "Aufrufe", "Gesamt ms", "Schnitt ms", "Max ms"))
    for i = 1, math.min(#list, 30) do
        local e = list[i]
        print(string.format("%-34s %8d %10.2f %10.3f %10.3f", e.name, e.p.n, e.p.sum * 1000, e.p.sum / e.p.n * 1000, e.p.max * 1000))
    end
end)

local function NextId(key)
    local id = GARLog.Meta[key] or 1
    GARLog.Meta[key] = id + 1
    DB.MarkDirty("meta")
    return id
end
GARLog.NextId = NextId

---------------------------------------------------------------------------
-- Sync (nur an Spieler mit offenem Datapad-Menü bzw. Datapad in der Hand)
---------------------------------------------------------------------------
local dirtySections = {}
local Builders = {}
GARLog.SyncBuilders = Builders

function GARLog.MarkDirty(section)
    dirtySections[section] = true
end
local MarkDirty = GARLog.MarkDirty

-- cache: pro Flush wird jeder Abschnitt nur einmal gebaut, auch bei mehreren Empfängergruppen
local function SendSections(sections, targets, cache)
    local payload = { now = os.time() }
    local any = false
    for sec in pairs(sections) do
        local data = cache and cache[sec]
        if data == nil then
            local fn = Builders[sec]
            if fn then
                local ok, res = pcall(fn)
                if ok then data = res else ErrorNoHalt("[GAR Logistik] Sync '" .. sec .. "': " .. tostring(res) .. "\n") end
                if cache then cache[sec] = data end
            end
        end
        if data ~= nil then payload[sec] = data any = true end
    end
    if not any then return end
    local comp = util.Compress(util.TableToJSON(payload))
    if not comp then return end
    net.Start("GARLog_Sync")
        net.WriteUInt(#comp, 32)
        net.WriteData(comp, #comp)
    net.Send(targets)
end

-- Stufe 2 = Datapad-Menü offen (alles), Stufe 1 = Datapad nur in der Hand (Lagerdaten für die Bauvorschau)
GARLog.FullSections = GARLog.FullSections or {}
for _, s in ipairs({ "loc", "req", "trn", "prd", "rep", "log" }) do GARLog.FullSections[s] = true end
local LITE_SECTIONS = { loc = true }

function GARLog.Subscribe(ply, level)
    level = math.Clamp(math.floor(tonumber(level) or 0), 0, 2)
    local old = tonumber(GARLog.Subs[ply]) or 0
    if level <= 0 then
        GARLog.Subs[ply] = nil
        return
    end
    GARLog.Subs[ply] = level
    if level > old then SendSections(level >= 2 and GARLog.FullSections or LITE_SECTIONS, ply) end
end

function GARLog.HasFullSubscribers()
    for ply, lvl in pairs(GARLog.Subs) do
        if (tonumber(lvl) or 2) >= 2 and IsValid(ply) then return true end
    end
    return false
end

-- Datapad nur in der Hand: Lagerdaten gesammelt und seltener (reicht für Bauvorschau)
local LITE_INTERVAL = 2.5
local liteDirty, nextLite = {}, 0

local function FlushSync()
    for sec in pairs(dirtySections) do
        if LITE_SECTIONS[sec] then liteDirty[sec] = true end
    end
    local now = CurTime()
    local liteDue = now >= nextLite and next(liteDirty) ~= nil
    if not next(dirtySections) and not liteDue then return end

    local full, lite = {}, {}
    for ply, lvl in pairs(GARLog.Subs) do
        lvl = tonumber(lvl) or 2
        if not IsValid(ply) then
            GARLog.Subs[ply] = nil
        elseif lvl >= 2 then
            full[#full + 1] = ply
        else
            lite[#lite + 1] = ply
        end
    end
    local cache = {}
    if #full > 0 and next(dirtySections) then SendSections(dirtySections, full, cache) end
    if liteDue then
        if #lite > 0 then SendSections(liteDirty, lite, cache) end
        table.Empty(liteDirty)
        nextLite = now + LITE_INTERVAL
    end
    table.Empty(dirtySections)
end
timer.Create("GARLog_Sync", cfg.SyncInterval, 0, function() Protected("Sync", FlushSync) end)

hook.Add("PlayerDisconnected", "GARLog_Subs", function(ply) GARLog.Subs[ply] = nil end)

---------------------------------------------------------------------------
-- Protokoll & Benachrichtigungen
---------------------------------------------------------------------------
function GARLog.Log(text, kind)
    table.insert(GARLog.LogEntries, 1, { t = os.time(), x = text, k = kind or "info" })
    for i = #GARLog.LogEntries, cfg.LogSize + 1, -1 do GARLog.LogEntries[i] = nil end
    MarkDirty("log")
    DB.MarkDirty("log")
    if cfg.ServerConsoleLog then MsgN("[GAR Logistik] " .. text) end
end

function GARLog.Notify(target, text, kind)
    net.Start("GARLog_Notify")
        net.WriteString(text)
        net.WriteUInt(GARLog.LogKinds[kind or "info"] or 0, 2)
    if target == nil then net.Broadcast() else net.Send(target) end
end

-- Darf der Spieler Rundmeldungen bekommen? roles = Set von Rollen-IDs (nil = cfg.NotifyRoles)
function GARLog.GetsNotify(ply, roles)
    if cfg.NotifyAdmins and GARLog.IsAdmin(ply) then return true end
    roles = roles or cfg.NotifyRoles
    if not roles then return true end
    for id in pairs(GARLog.GetRoles(ply)) do
        if roles[id] then return true end
    end
    return false
end

-- Alle Spieler mit einer Rollen-Berechtigung benachrichtigen
function GARLog.NotifyPerm(perm, text, kind, exclude)
    local list = {}
    for _, p in ipairs(player.GetHumans()) do
        if p ~= exclude and GARLog.HasPermRole(p, perm) and GARLog.GetsNotify(p) then
            list[#list + 1] = p
        elseif p ~= exclude and cfg.NotifyAdmins and GARLog.IsAdmin(p) then
            list[#list + 1] = p
        end
    end
    if #list > 0 then GARLog.Notify(list, text, kind) end
end

-- Spieler in einer Feldbasis benachrichtigen, gefiltert nach Rollen (nil = cfg.NotifyRoles)
function GARLog.NotifyInFOB(fobId, text, kind, roles)
    local list = {}
    for _, p in ipairs(player.GetHumans()) do
        if p.GARLogInFOB == fobId and GARLog.GetsNotify(p, roles) then list[#list + 1] = p end
    end
    if #list > 0 then GARLog.Notify(list, text, kind) end
end

-- Gedrosselte Meldung (z.B. "Kein Strom" beim Dauerdrücken von E)
function GARLog.NotifyOnce(ply, key, text, kind, cooldown)
    if not IsValid(ply) then return end
    ply.GARLogNotifyCD = ply.GARLogNotifyCD or {}
    local now = CurTime()
    if (ply.GARLogNotifyCD[key] or 0) > now then return end
    ply.GARLogNotifyCD[key] = now + (cooldown or 3)
    GARLog.Notify(ply, text, kind)
end

---------------------------------------------------------------------------
-- Standorte
---------------------------------------------------------------------------
function GARLog.CreateLocation(id, name, short, typ, static)
    local loc = Locations[id] or {}
    loc.id, loc.name, loc.short, loc.type, loc.static = id, name, short, typ, static
    loc.stock = loc.stock or {}
    loc.cap = loc.cap or {}
    loc.debt = loc.debt or {}
    loc.used = loc.used or {}
    loc.hist = loc.hist or {}
    loc.rate = loc.rate or {}
    Locations[id] = loc
    MarkDirty("loc")
    return loc
end

function GARLog.GetLoc(id)
    return Locations[id]
end

function GARLog.LocName(id)
    local l = Locations[id]
    if l then return l.name end
    local s = GARLog.StaticLoc[id]
    return s and s.name or tostring(id)
end

-- Reihenfolge: Zentrallager, Schiffe (Config), dann Feldbasen
function GARLog.LocOrder()
    local list = {}
    for _, def in ipairs(cfg.Locations) do
        if Locations[def.id] then list[#list + 1] = def.id end
    end
    local fobs = {}
    for id, l in pairs(Locations) do
        if l.type == "fob" then fobs[#fobs + 1] = l end
    end
    table.sort(fobs, function(a, b) return (a.fob or 0) < (b.fob or 0) end)
    for _, l in ipairs(fobs) do list[#list + 1] = l.id end
    return list
end

function GARLog.RemoveLocation(id, reason)
    if not Locations[id] then return end
    Locations[id] = nil
    for _, r in pairs(Requests) do
        if (r.from == id or r.src == id) and (r.st == REQ_OPEN or r.st == REQ_APPROVED) then
            GARLog.SetReqStatus(r, REQ_CANCELLED, nil, reason or "Standort aufgelöst")
        end
    end
    for _, o in pairs(GARLog.Repairs) do
        if o.loc == id and (o.st == GARLog.REP_OPEN or o.st == GARLog.REP_ASSIGNED) then
            GARLog.CloseRepair(o, GARLog.REP_CANCELLED)
        end
    end
    MarkDirty("loc")
end

---------------------------------------------------------------------------
-- Bestände
---------------------------------------------------------------------------
local function Touch(loc)
    MarkDirty("loc")
    if loc.static then DB.MarkDirty("stock") end
end

local function TrackUse(loc, res, n)
    loc.used[res] = (loc.used[res] or 0) + n
end

function GARLog.Stock(locId, res)
    local loc = Locations[locId]
    return loc and (loc.stock[res] or 0) or 0
end

-- Fügt hinzu (bis zur Kapazität). Rückgabe: hinzugefügt, Überlauf
function GARLog.AddStock(locId, items, ignoreCap)
    local loc = Locations[locId]
    if not loc then return {}, table.Copy(items or {}) end
    local added, over = {}, {}
    for id, n in pairs(items or {}) do
        if GARLog.Res[id] and n > 0 then
            local cur = loc.stock[id] or 0
            local can = ignoreCap and n or math.Clamp((loc.cap[id] or 0) - cur, 0, n)
            if can > 0 then
                loc.stock[id] = cur + can
                added[id] = can
            end
            if n - can > 0 then over[id] = n - can end
        end
    end
    Touch(loc)
    return added, over
end

function GARLog.HasStock(locId, items)
    local loc = Locations[locId]
    if not loc then return false end
    for id, n in pairs(items or {}) do
        if n > 0 and (loc.stock[id] or 0) < n then return false end
    end
    return true
end

-- Alles oder nichts. consume = zählt als Verbrauch (Reichweiten-Prognose)
function GARLog.TakeStock(locId, items, consume)
    if not GARLog.HasStock(locId, items) then return false end
    local loc = Locations[locId]
    for id, n in pairs(items or {}) do
        if n > 0 then
            loc.stock[id] = (loc.stock[id] or 0) - n
            if consume then TrackUse(loc, id, n) end
        end
    end
    Touch(loc)
    return true
end

function GARLog.TakeUpTo(locId, res, n, consume)
    local loc = Locations[locId]
    if not loc or n <= 0 then return 0 end
    local take = math.min(loc.stock[res] or 0, math.floor(n))
    if take <= 0 then return 0 end
    loc.stock[res] = loc.stock[res] - take
    if consume then TrackUse(loc, res, take) end
    Touch(loc)
    return take
end

-- Bruchteil-Verbrauch (z.B. 0.8 Medizin pro Heilung). false = nichts mehr da.
function GARLog.ConsumeFrac(locId, res, amount)
    local loc = Locations[locId]
    if not loc then return false end
    local stock = loc.stock[res] or 0
    if stock <= 0 then return false end
    local debt = (loc.debt[res] or 0) + amount
    local whole = math.floor(debt)
    if whole > 0 then
        whole = math.min(whole, stock)
        loc.stock[res] = stock - whole
        TrackUse(loc, res, whole)
        debt = debt - whole
        Touch(loc)
    end
    loc.debt[res] = math.min(debt, 1)
    return true
end

function GARLog.SetStock(locId, res, n)
    local loc = Locations[locId]
    if not loc or not GARLog.Res[res] then return end
    loc.stock[res] = math.Clamp(math.floor(n), 0, math.max(loc.cap[res] or 0, 0))
    Touch(loc)
end

-- Kürzt Bestände auf die Kapazität. Rückgabe: verlorene Menge
function GARLog.ClampStock(locId)
    local loc = Locations[locId]
    if not loc then return {} end
    local lost = {}
    for id, n in pairs(loc.stock) do
        local cap = loc.cap[id] or 0
        if n > cap then
            lost[id] = n - cap
            loc.stock[id] = cap
        end
    end
    Touch(loc)
    return lost
end

---------------------------------------------------------------------------
-- Anträge
---------------------------------------------------------------------------
local function ReqHist(r, text, who)
    r.h = r.h or {}
    r.h[#r.h + 1] = { t = os.time(), x = text, b = who }
    while #r.h > 12 do table.remove(r.h, 1) end
end

local function PruneClosed(map, closedFn, keep)
    local closed = {}
    for id, e in pairs(map) do
        if closedFn(e) then closed[#closed + 1] = e end
    end
    if #closed <= keep then return end
    table.sort(closed, function(a, b) return (a.closed or 0) > (b.closed or 0) end)
    for i = keep + 1, #closed do map[closed[i].id] = nil end
end

function GARLog.SetReqStatus(r, st, who, text)
    r.st = st
    r.u = os.time()
    ReqHist(r, text or GARLog.ReqStatus[st].name, who)
    if st >= REQ_DONE then
        r.closed = os.time()
        PruneClosed(Requests, function(e) return e.st >= REQ_DONE end, cfg.HistorySize)
    end
    MarkDirty("req")
    DB.MarkDirty("req")
end

local function OpenRequestsFor(locId)
    local n = 0
    for _, r in pairs(Requests) do
        if r.from == locId and r.st <= REQ_TRANSIT then n = n + 1 end
    end
    return n
end

function GARLog.CreateRequest(ply, fromId, srcId, items, prio, note)
    local from, src = Locations[fromId], Locations[srcId]
    if not from or not src then return nil, "Unbekannter Standort." end
    if fromId == srcId then return nil, "Anforderer und Lieferant müssen verschieden sein." end

    local perm = from.type == "fob" and "request.create" or "request.fleet"
    if not GARLog.Can(ply, perm) then return nil, "Keine Berechtigung, für diesen Standort anzufordern." end

    items = GARLog.SanitizeItems(items, 100000)
    if not next(items) then return nil, "Keine Güter angegeben." end
    if GARLog.ItemVolume(items) > cfg.Requests.MaxVolume then
        return nil, "Antrag zu groß (max. " .. GARLog.FmtNum(cfg.Requests.MaxVolume) .. " FE)."
    end
    if OpenRequestsFor(fromId) >= cfg.Requests.MaxOpenPerLocation then
        return nil, "Zu viele offene Anträge für " .. from.name .. "."
    end
    if from.type == "fob" and cfg.Requests.FOBNeedsAntenna and not GARLog.IsAdmin(ply) then
        local f = GARLog.FOBs and GARLog.FOBs[from.fob]
        if not (f and f.antenna) then
            return nil, "Keine Funkverbindung – die Kommunikationsantenne der Feldbasis ist offline."
        end
    end

    local r = {
        id = NextId("nextReq"), from = fromId, src = srcId, it = items,
        pr = math.Clamp(math.floor(tonumber(prio) or 2), 1, 4),
        nt = GARLog.CleanText(note, cfg.Requests.NoteLength),
        st = REQ_OPEN, by = GARLog.Name(ply), sid = ply:SteamID(), t = os.time(),
    }
    ReqHist(r, "Antrag gestellt", r.by)
    Requests[r.id] = r
    MarkDirty("req")
    DB.MarkDirty("req")

    local prio = GARLog.Prio[r.pr].name
    GARLog.Log(string.format("Antrag #%d: %s fordert %s von %s an (%s).", r.id, from.name, GARLog.ItemsText(items), src.name, prio))
    GARLog.NotifyPerm("request.approve", string.format("Neuer Versorgungsantrag #%d von %s [%s] – Genehmigung erforderlich.", r.id, from.name, prio), r.pr >= 3 and "warn" or "info", ply)
    return r
end

function GARLog.ApproveRequest(ply, r, approve, reason)
    if r.st ~= REQ_OPEN then return false, "Antrag ist nicht mehr offen." end
    local who = GARLog.Name(ply)
    if approve then
        r.ab = who
        GARLog.SetReqStatus(r, REQ_APPROVED, who, "Genehmigt")
        GARLog.Log(string.format("Antrag #%d genehmigt von %s.", r.id, who), "ok")
        GARLog.NotifyPerm("request.plan", string.format("Antrag #%d (%s) genehmigt – Lieferung planen.", r.id, GARLog.LocName(r.from)), "info", ply)
    else
        reason = GARLog.CleanText(reason, 120)
        GARLog.SetReqStatus(r, REQ_REJECTED, who, "Abgelehnt" .. (reason ~= "" and (": " .. reason) or ""))
        GARLog.Log(string.format("Antrag #%d abgelehnt von %s.", r.id, who), "warn")
    end
    local requester = player.GetBySteamID(r.sid or "")
    if IsValid(requester) and requester ~= ply then
        GARLog.Notify(requester, string.format("Dein Antrag #%d wurde %s.", r.id, approve and "genehmigt" or "abgelehnt"), approve and "ok" or "warn")
    end
    return true
end

function GARLog.CancelRequest(ply, r)
    if r.st ~= REQ_OPEN and r.st ~= REQ_APPROVED then return false, "Antrag kann nicht mehr storniert werden." end
    if r.sid ~= ply:SteamID() and not GARLog.Can(ply, "request.approve") then
        return false, "Nur der Antragsteller oder die Genehmigungsstelle kann stornieren."
    end
    GARLog.SetReqStatus(r, REQ_CANCELLED, GARLog.Name(ply), "Storniert")
    GARLog.Log(string.format("Antrag #%d storniert von %s.", r.id, GARLog.Name(ply)))
    return true
end

-- Lieferung zu einem genehmigten Antrag planen
function GARLog.PlanRequest(ply, r, mode, items)
    if r.st ~= REQ_APPROVED then return false, "Antrag ist nicht genehmigt." end
    items = GARLog.SanitizeItems(items, 100000)
    for id, n in pairs(items) do
        items[id] = math.min(n, r.it[id] or 0)
        if items[id] <= 0 then items[id] = nil end
    end
    if not next(items) then return false, "Keine Güter zur Lieferung ausgewählt." end

    local ok, err
    if mode == "container" then
        local ent
        ent, err = GARLog.PackContainer(ply, r.src, items, r.id)
        ok = IsValid(ent)
        if ok then r.cnt = ent:GetContainerID() end
    else
        local t
        t, err = GARLog.CreateShuttle(ply, r.src, r.from, items, r.id)
        ok = t ~= nil
        if ok then r.trn = t.id end
    end
    if not ok then return false, err end

    r.sh, r.via = items, mode == "container" and "container" or "shuttle"
    GARLog.SetReqStatus(r, REQ_TRANSIT, GARLog.Name(ply),
        (r.via == "container" and "Container gepackt: " or "Shuttle entsandt: ") .. GARLog.ItemsText(items))
    return true
end

-- Wird bei Ankunft einer Lieferung aufgerufen
function GARLog.DeliverRequest(reqId, delivered, toLocId, via)
    local r = Requests[reqId]
    if not r or r.st ~= REQ_TRANSIT then return end
    r.dl = delivered
    local text = "Geliefert: " .. GARLog.ItemsText(delivered)
    if toLocId and toLocId ~= r.from then text = text .. " (an " .. GARLog.LocName(toLocId) .. ")" end
    GARLog.SetReqStatus(r, REQ_DONE, via, text)
    local requester = player.GetBySteamID(r.sid or "")
    if IsValid(requester) then
        GARLog.Notify(requester, string.format("Lieferung zu Antrag #%d ist angekommen: %s", r.id, GARLog.ItemsText(delivered)), "ok")
    end
end

-- Lieferung gescheitert -> Antrag zurück auf "genehmigt", damit neu geplant werden kann
function GARLog.FailRequestDelivery(reqId, text)
    local r = Requests[reqId]
    if not r or r.st ~= REQ_TRANSIT then return end
    r.trn, r.cnt = nil, nil
    if Locations[r.from] and Locations[r.src] then
        GARLog.SetReqStatus(r, REQ_APPROVED, nil, text)
        GARLog.NotifyPerm("request.plan", string.format("Lieferung zu Antrag #%d gescheitert (%s) – neu planen.", r.id, text), "warn")
    else
        GARLog.SetReqStatus(r, REQ_CANCELLED, nil, text)
    end
end

---------------------------------------------------------------------------
-- Shuttles
---------------------------------------------------------------------------
function GARLog.ShuttlesBusy()
    local n = 0
    for _, t in pairs(Transports) do
        if t.st == TRN_TRANSIT or t.st == TRN_RETURN then n = n + 1 end
    end
    return n
end

local function FOBOfLoc(loc)
    return loc and loc.fob and GARLog.FOBs and GARLog.FOBs[loc.fob]
end

function GARLog.CreateShuttle(ply, srcId, dstId, items, reqId)
    local src, dst = Locations[srcId], Locations[dstId]
    if not src or not dst then return nil, "Unbekannter Standort." end
    if srcId == dstId then return nil, "Start und Ziel sind identisch." end
    if GARLog.ShuttlesBusy() >= cfg.Shuttle.Count then return nil, "Alle Shuttles sind im Einsatz." end

    items = GARLog.SanitizeItems(items, 100000)
    if not next(items) then return nil, "Keine Fracht ausgewählt." end
    local vol = GARLog.ItemVolume(items)
    if vol > cfg.Shuttle.Capacity then
        return nil, string.format("Fracht zu groß (%s / %s FE).", GARLog.FmtNum(vol), GARLog.FmtNum(cfg.Shuttle.Capacity))
    end
    if cfg.Shuttle.FOBNeedsAntenna then
        for _, l in ipairs({ src, dst }) do
            local f = FOBOfLoc(l)
            if l.type == "fob" and not (f and f.antenna) then
                return nil, l.name .. ": kein Leitsignal (Antenne offline) – Shuttle kann nicht landen."
            end
        end
    end
    if not GARLog.TakeStock(srcId, items) then return nil, "Nicht genug Bestand in " .. src.name .. "." end

    local now = os.time()
    local ft = GARLog.FlightTime(src.type, dst.type)
    local t = {
        id = NextId("nextTrn"), k = "shuttle", src = srcId, dst = dstId, it = items,
        st = TRN_TRANSIT, dep = now, arr = now + ft, ft = ft, req = reqId,
        by = IsValid(ply) and GARLog.Name(ply) or "AUTOMATIK",
    }
    Transports[t.id] = t
    MarkDirty("trn")
    DB.MarkDirty("trn")
    GARLog.Log(string.format("Shuttle T-%d: %s » %s mit %s (ETA %s).", t.id, src.name, dst.name, GARLog.ItemsText(items), GARLog.FmtTime(ft)))
    return t
end

-- Automatische Schiffsversorgung, wenn kein Logistiker online ist
local function ShipNeedsShuttle(shipId)
    for _, t in pairs(Transports) do
        if t.dst == shipId and t.st == TRN_TRANSIT then return false end
    end
    return true
end

function GARLog.TickAutoSupply()
    local a = cfg.AutoSupply
    if not a or not a.Enabled then return end
    if a.OnlyWithoutLogistics then
        for _, p in ipairs(player.GetHumans()) do
            if GARLog.HasRole(p, "logistik") then return end
        end
    end
    local srcId = cfg.Production.Location
    local src = Locations[srcId]
    if not src then return end

    for _, def in ipairs(cfg.Locations) do
        local loc = def.type == "ship" and Locations[def.id]
        if loc and ShipNeedsShuttle(def.id) and GARLog.ShuttlesBusy() < cfg.Shuttle.Count then
            local items = {}
            for _, res in ipairs(cfg.KeyResources) do
                local cap = loc.cap[res] or 0
                local cur = loc.stock[res] or 0
                if cap > 0 and cur / cap < a.Threshold then
                    local want = math.min(math.floor(cap * a.FillTo - cur), src.stock[res] or 0)
                    if want > 0 then items[res] = want end
                end
            end
            -- auf Shuttle-Kapazität herunterskalieren
            local vol = GARLog.ItemVolume(items)
            if vol > cfg.Shuttle.Capacity then
                local f = cfg.Shuttle.Capacity / vol
                for res, n in pairs(items) do
                    items[res] = math.floor(n * f)
                    if items[res] <= 0 then items[res] = nil end
                end
            end
            if next(items) then
                local t = GARLog.CreateShuttle(nil, srcId, def.id, items)
                if t then GARLog.Log(string.format("Automatik: Versorgungsshuttle T-%d zu %s (kein Logistiker im Dienst).", t.id, loc.name), "info") end
            end
        end
    end
end

local function CloseTransport(t, now)
    t.st, t.closed = TRN_DONE, now
    PruneClosed(Transports, function(e) return e.st == TRN_DONE end, cfg.HistorySize)
end

function GARLog.TickTransports(now)
    local changed = false
    for _, t in pairs(Transports) do
        if t.st == TRN_TRANSIT and now >= t.arr then
            local dst = Locations[t.dst]
            local f = FOBOfLoc(dst)
            local blocked = dst and dst.type == "fob" and cfg.Shuttle.FOBNeedsAntenna and not (f and f.antenna)

            if dst and not blocked then
                local added, over = GARLog.AddStock(t.dst, t.it)
                t.dl, t.ov = added, next(over) and over or nil
                t.st, t.ret = TRN_RETURN, now + math.ceil(t.ft * cfg.Shuttle.ReturnFactor)
                GARLog.Log(string.format("Shuttle T-%d in %s gelandet: %s%s", t.id, dst.name, GARLog.ItemsText(added),
                    t.ov and (" (Lager voll, Rest zurück: " .. GARLog.ItemsText(over) .. ")") or ""), "ok")
                if t.req then GARLog.DeliverRequest(t.req, added, t.dst, "Shuttle T-" .. t.id) end
                if f then
                    GARLog.NotifyInFOB(f.id, string.format("Shuttle T-%d ist in %s gelandet: %s", t.id, dst.name, GARLog.ItemsText(added)), "ok")
                end
                changed = true
            elseif blocked and (now - (t.hold or now)) < cfg.Shuttle.HoldTime then
                if not t.hold then
                    t.hold = now
                    GARLog.Log(string.format("Shuttle T-%d kreist über %s – kein Leitsignal!", t.id, dst.name), "warn")
                    changed = true
                end
            else
                -- Ziel weg oder kein Leitsignal: mit Fracht zurück
                t.ov, t.dl = t.it, {}
                t.st, t.ret = TRN_RETURN, now + math.ceil(t.ft * cfg.Shuttle.ReturnFactor)
                local why = dst and "kein Leitsignal" or "Ziel existiert nicht mehr"
                GARLog.Log(string.format("Shuttle T-%d kehrt mit Fracht zurück (%s).", t.id, why), "warn")
                if t.req then GARLog.FailRequestDelivery(t.req, "Shuttle: " .. why) end
                changed = true
            end
        elseif t.st == TRN_RETURN and now >= t.ret then
            if t.ov and next(t.ov) then
                if Locations[t.src] then
                    local _, lost = GARLog.AddStock(t.src, t.ov)
                    if next(lost) then GARLog.Log(string.format("Shuttle T-%d: Rückfracht verloren (Lager voll): %s", t.id, GARLog.ItemsText(lost)), "warn") end
                else
                    GARLog.Log(string.format("Shuttle T-%d: Heimatstandort existiert nicht mehr – Fracht verloren.", t.id), "warn")
                end
            end
            CloseTransport(t, now)
            changed = true
        end
    end
    if changed then
        MarkDirty("trn")
        DB.MarkDirty("trn")
    end
end

---------------------------------------------------------------------------
-- Produktion
---------------------------------------------------------------------------
local function ProdLines()
    local lines = GARLog.Production.lines
    for i = 1, cfg.Production.Lines do
        lines[i] = lines[i] or { orders = {} }
        lines[i].orders = lines[i].orders or {}
    end
    for i = #lines, cfg.Production.Lines + 1, -1 do lines[i] = nil end
    return lines
end

local function LineRemaining(line)
    local sum = 0
    for _, o in ipairs(line.orders) do
        local rec = cfg.Production.Recipes[o.res]
        if rec then sum = sum + (o.n - o.d) * rec.time end
    end
    return sum
end

function GARLog.AddProduction(ply, res, batches, lineIdx)
    local rec = cfg.Production.Recipes[res]
    if not rec or not GARLog.Res[res] then return false, "Unbekanntes Produkt." end
    batches = math.Clamp(math.floor(tonumber(batches) or 1), 1, cfg.Production.MaxBatches)
    local lines = ProdLines()
    lineIdx = math.floor(tonumber(lineIdx) or 0)

    if lineIdx < 1 or lineIdx > #lines then
        local best, bestT
        for i, l in ipairs(lines) do
            if #l.orders < cfg.Production.MaxQueue then
                local rem = LineRemaining(l)
                if not bestT or rem < bestT then best, bestT = i, rem end
            end
        end
        if not best then return false, "Alle Produktionslinien sind ausgelastet." end
        lineIdx = best
    end

    local line = lines[lineIdx]
    if #line.orders >= cfg.Production.MaxQueue then return false, "Warteschlange der Linie " .. lineIdx .. " ist voll." end

    line.orders[#line.orders + 1] = { id = NextId("nextOrd"), res = res, n = batches, d = 0, by = GARLog.Name(ply), t = os.time() }
    MarkDirty("prd")
    DB.MarkDirty("prod")
    GARLog.Log(string.format("Produktion: %s gibt %dx %s %s in Auftrag (Linie %d).", GARLog.Name(ply), batches, GARLog.FmtNum(rec.batch), GARLog.Res[res].name, lineIdx))
    return true
end

function GARLog.CancelProduction(ply, lineIdx, orderId)
    local line = ProdLines()[math.floor(tonumber(lineIdx) or 0)]
    if not line then return false, "Unbekannte Linie." end
    for i, o in ipairs(line.orders) do
        if o.id == orderId then
            -- laufende Charge: Rohstoffe zurück
            if o.e then
                local rec = cfg.Production.Recipes[o.res]
                if rec and rec.cost and next(rec.cost) then GARLog.AddStock(cfg.Production.Location, rec.cost) end
            end
            table.remove(line.orders, i)
            MarkDirty("prd")
            DB.MarkDirty("prod")
            GARLog.Log(string.format("Produktion: Auftrag P-%d storniert von %s.", o.id, GARLog.Name(ply)))
            return true
        end
    end
    return false, "Auftrag nicht gefunden."
end

function GARLog.TickProduction(now)
    local locId = cfg.Production.Location
    local loc = Locations[locId]
    if not loc then return end
    local changed = false

    for i, line in ipairs(ProdLines()) do
        local o = line.orders[1]
        local state = "idle"
        if o then
            local rec = cfg.Production.Recipes[o.res]
            if not rec then
                table.remove(line.orders, 1)
                changed = true
            elseif not o.e then
                if (loc.stock[o.res] or 0) + rec.batch > (loc.cap[o.res] or 0) then
                    state = "full"
                elseif rec.cost and next(rec.cost) and not GARLog.TakeStock(locId, rec.cost, true) then
                    state = "mat"
                else
                    o.s, o.e = now, now + rec.time
                    state = "run"
                    changed = true
                end
            elseif now >= o.e then
                -- fertige Charge wartet, bis im Lager Platz für die ganze Menge ist
                if (loc.stock[o.res] or 0) + rec.batch > (loc.cap[o.res] or 0) then
                    state = "full"
                else
                    GARLog.AddStock(locId, { [o.res] = rec.batch })
                    o.d, o.s, o.e = o.d + 1, nil, nil
                    changed = true
                    if o.d >= o.n then
                        table.remove(line.orders, 1)
                        GARLog.Log(string.format("Produktion abgeschlossen: %dx %s %s (P-%d).", o.n, GARLog.FmtNum(rec.batch), GARLog.Res[o.res].name, o.id), "ok")
                    end
                    state = line.orders[1] and "run" or "idle"
                end
            else
                state = "run"
            end
        end
        if line.st ~= state then
            line.st = state
            changed = true
        end
    end

    local passive = cfg.Production.Passive
    if passive and passive.Interval and passive.Interval > 0 then
        local last = GARLog.Meta.lastPassive or 0
        if now - last >= passive.Interval then
            GARLog.Meta.lastPassive = now
            DB.MarkDirty("meta")
            if last > 0 then
                local added = GARLog.AddStock(locId, passive.Amounts or {})
                if next(added) then GARLog.Log("Grundversorgung eingetroffen: " .. GARLog.ItemsText(added), "ok") end
            end
            changed = true
        end
    end

    if changed then
        MarkDirty("prd")
        DB.MarkDirty("prod")
    end
end

---------------------------------------------------------------------------
-- Reparaturaufträge (Verwaltung; automatische Aufträge entstehen in sv_fob)
---------------------------------------------------------------------------
function GARLog.CreateRepair(data)
    data.id = NextId("nextRep")
    data.st = GARLog.REP_OPEN
    data.t = os.time()
    GARLog.Repairs[data.id] = data
    MarkDirty("rep")
    if data.k == "manual" then DB.MarkDirty("rep") end
    return data
end

function GARLog.CloseRepair(o, st, who)
    if o.st == GARLog.REP_DONE or o.st == GARLog.REP_CANCELLED then return end
    local assigned = o.asid and player.GetBySteamID(o.asid)
    o.st, o.closed, o.cb = st, os.time(), who
    if IsValid(assigned) then
        net.Start("GARLog_Waypoint") net.WriteUInt(o.id, 16) net.WriteBool(false) net.Send(assigned)
        if st == GARLog.REP_DONE then GARLog.Notify(assigned, string.format("Reparaturauftrag R-%d erledigt: %s", o.id, o.title), "ok") end
    end
    PruneClosed(GARLog.Repairs, function(e) return e.st >= GARLog.REP_DONE end, cfg.HistorySize)
    MarkDirty("rep")
    DB.MarkDirty("rep")
end

function GARLog.SendWaypoint(ply, o)
    if not IsValid(ply) then return end
    local ent = o.ent and Entity(o.ent)
    net.Start("GARLog_Waypoint")
        net.WriteUInt(o.id, 16)
        net.WriteBool(true)
        net.WriteString(o.title or "")
        net.WriteVector(IsValid(ent) and ent:WorldSpaceCenter() or (o.pos or vector_origin))
        net.WriteUInt(IsValid(ent) and ent:EntIndex() or 0, 16)
    net.Send(ply)
end

---------------------------------------------------------------------------
-- Verbrauch (Rationen, Schiffs-Grundverbrauch) & Reichweiten-Prognose
---------------------------------------------------------------------------
function GARLog.TickUpkeep(now)
    local up = cfg.Upkeep
    local last = GARLog.Meta.lastUpkeep or 0
    if now - last < up.Interval then return end
    GARLog.Meta.lastUpkeep = now
    DB.MarkDirty("meta")
    if last == 0 then return end

    local crew = 0
    for _, p in ipairs(player.GetHumans()) do
        if not p.GARLogInFOB then crew = crew + 1 end
    end

    -- Feldbasen: Rationen pro anwesendem Soldat
    for _, f in pairs(GARLog.FOBs or {}) do
        local need = (f.present or 0) * up.FoodPerPlayer
        if need > 0 then
            local got = GARLog.TakeUpTo(f.locId, "food", need, true)
            if got < need then
                GARLog.Log(string.format("%s: Rationen erschöpft! (%d von %d ausgegeben)", f.name, got, need), "err")
                GARLog.NotifyInFOB(f.id, f.name .. ": Rationen erschöpft – Nachschub anfordern!", "err")
            end
        end
    end

    -- Schiffe: Grundverbrauch + Crew
    for _, def in ipairs(cfg.Locations) do
        if Locations[def.id] then
            for res, n in pairs(def.upkeep or {}) do GARLog.TakeUpTo(def.id, res, n, true) end
            if def.id == cfg.DefaultShip and up.ShipCrew and crew > 0 then
                GARLog.TakeUpTo(def.id, "food", crew * up.FoodPerPlayer, true)
            end
        end
    end
    hook.Run("GARLog_Upkeep", now)
end

-- Verbrauch der letzten 10 Minuten -> Einheiten pro Minute
local RATE_WINDOW = 10
function GARLog.TickRates()
    for _, loc in pairs(Locations) do
        for _, res in ipairs(GARLog.ResOrder) do
            local h = loc.hist[res] or {}
            table.insert(h, 1, loc.used[res] or 0)
            h[RATE_WINDOW + 1] = nil
            loc.hist[res] = h
            local sum = 0
            for _, v in ipairs(h) do sum = sum + v end
            loc.rate[res] = sum / RATE_WINDOW
        end
        table.Empty(loc.used)
    end
    MarkDirty("loc")
end

-- Kompakter Füllstand aller Standorte für Welt-Anzeigen (Terminals, Lager)
local lastGlobal = {}
function GARLog.TickGlobals()
    for id, loc in pairs(Locations) do
        local parts = {}
        for i, res in ipairs(GARLog.ResOrder) do
            local cap = loc.cap[res] or 0
            parts[i] = cap > 0 and math.floor((loc.stock[res] or 0) / cap * 100) or 0
        end
        local s = table.concat(parts, ",")
        if lastGlobal[id] ~= s then
            lastGlobal[id] = s
            SetGlobal2String("GARLog_S_" .. id, s)
        end
    end
end

---------------------------------------------------------------------------
-- Sync-Inhalte
---------------------------------------------------------------------------
local function round1(t)
    local out = {}
    for k, v in pairs(t) do out[k] = math.Round(v, 1) end
    return out
end

Builders.loc = function()
    local out = {}
    for _, id in ipairs(GARLog.LocOrder()) do
        local l = Locations[id]
        local e = { id = l.id, n = l.name, sh = l.short, t = l.type, s = l.stock, c = l.cap, r = round1(l.rate) }
        e.m = l.type == "fob" or (GARLog.LocationOnMap and GARLog.LocationOnMap(l.id)) or false
        if l.fob and GARLog.FOB and GARLog.FOB.SyncInfo then e.f = GARLog.FOB.SyncInfo(l.fob) end
        out[#out + 1] = e
    end
    return out
end

local function sortedList(map)
    local list = {}
    for _, e in pairs(map) do list[#list + 1] = e end
    table.sort(list, function(a, b) return a.id > b.id end)
    return list
end

Builders.req = function() return sortedList(Requests) end

Builders.trn = function()
    local cont = {}
    for id, c in pairs(GARLog.Containers) do
        if IsValid(c.ent) then
            cont[#cont + 1] = { id = id, it = c.ent.Items or {}, src = c.src, req = c.req, by = c.by, t = c.t, at = GARLog.DescribePos and GARLog.DescribePos(c.ent:GetPos()) or "" }
        end
    end
    table.sort(cont, function(a, b) return a.id > b.id end)
    return { list = sortedList(Transports), cont = cont, busy = GARLog.ShuttlesBusy() }
end

Builders.prd = function()
    return { lines = ProdLines(), last = GARLog.Meta.lastPassive or 0 }
end

Builders.rep = function()
    local list = sortedList(GARLog.Repairs)
    local out = {}
    for i, o in ipairs(list) do
        local e = table.Copy(o)
        e.pos = nil
        out[i] = e
    end
    return out
end

Builders.log = function()
    local out = {}
    for i = 1, math.min(80, #GARLog.LogEntries) do out[i] = GARLog.LogEntries[i] end
    return out
end

---------------------------------------------------------------------------
-- Laden & Speichern
---------------------------------------------------------------------------
DB.Register("stock", function()
    local out = {}
    for id, l in pairs(Locations) do
        if l.static then out[id] = l.stock end
    end
    return out
end)
DB.Register("meta", function() return GARLog.Meta end)
DB.Register("req", function() return sortedList(Requests) end)
DB.Register("trn", function() return sortedList(Transports) end)
DB.Register("prod", function() return { lines = ProdLines() } end)
DB.Register("log", function() return GARLog.LogEntries end)
DB.Register("rep", function()
    local out = {}
    for _, o in pairs(GARLog.Repairs) do
        if o.k == "manual" then out[#out + 1] = o end
    end
    return out
end)

local function listToMap(list, target)
    table.Empty(target)
    for _, e in ipairs(list or {}) do
        if istable(e) and tonumber(e.id) then target[tonumber(e.id)] = e end
    end
end

function GARLog.LoadAll()
    -- feste Standorte
    local saved = DB.Load("stock") or {}
    for _, def in ipairs(cfg.Locations) do
        local loc = GARLog.CreateLocation(def.id, def.name, def.short or def.id:upper(), def.type, true)
        for _, res in ipairs(GARLog.ResOrder) do loc.cap[res] = (def.capacity or {})[res] or 0 end
        local src = istable(saved[def.id]) and saved[def.id] or def.start or {}
        local start = def.start or {}
        for _, res in ipairs(GARLog.ResOrder) do
            -- neu hinzugekommene Güter (Update) bekommen ihren Startbestand statt 0
            local v = src[res]
            if v == nil then v = start[res] end
            loc.stock[res] = math.Clamp(math.floor(tonumber(v) or 0), 0, loc.cap[res])
        end
    end

    local meta = DB.Load("meta")
    if istable(meta) then table.Merge(GARLog.Meta, meta) end

    listToMap(DB.Load("req"), Requests)
    listToMap(DB.Load("trn"), Transports)

    local prod = DB.Load("prod")
    if istable(prod) and istable(prod.lines) then GARLog.Production.lines = prod.lines end
    ProdLines()

    local reps = DB.Load("rep")
    table.Empty(GARLog.Repairs)
    for _, o in ipairs(reps or {}) do
        if istable(o) and o.k == "manual" and tonumber(o.id) then GARLog.Repairs[tonumber(o.id)] = o end
    end

    local log = DB.Load("log")
    if istable(log) then GARLog.LogEntries = log end

    -- Anträge, deren Standort (z.B. alte Feldbasis) nicht mehr existiert
    for _, r in pairs(Requests) do
        if r.st <= REQ_TRANSIT and (not Locations[r.from] or not Locations[r.src]) then
            r.st, r.closed = REQ_CANCELLED, os.time()
            ReqHist(r, "Standort existiert nicht mehr")
        elseif r.st == REQ_TRANSIT and r.via == "container" then
            -- Container überleben keinen Neustart (Inhalt wurde beim Herunterfahren zurückgebucht)
            r.st, r.cnt = REQ_APPROVED, nil
            ReqHist(r, "Container nach Neustart zurückgebucht – neu planen")
        end
    end
    -- Feldbasen-Reparaturen offen zugewiesener Spieler sind hinfällig; manuelle bleiben
    GARLog.Loaded = true
    GARLog.Log("Logistiksystem online.", "info")
end

if not GARLog.Loaded then GARLog.LoadAll() end

---------------------------------------------------------------------------
-- Zentraler Takt
---------------------------------------------------------------------------
local tickN = 0
timer.Create("GARLog_Tick", cfg.TickInterval, 0, function()
    tickN = tickN + 1
    local now = os.time()
    Protected("Transporte", GARLog.TickTransports, now)
    Protected("Produktion", GARLog.TickProduction, now)
    if GARLog.FOB and GARLog.FOB.Tick then Protected("Feldbasen", GARLog.FOB.Tick, now, tickN) end
    Protected("Versorgung", GARLog.TickUpkeep, now)
    if tickN % math.max(1, math.floor(60 / cfg.TickInterval)) == 0 then Protected("Verbrauchsrate", GARLog.TickRates) end
    if tickN % 3 == 0 then Protected("Globals", GARLog.TickGlobals) end
    local auto = cfg.AutoSupply
    if auto and auto.Enabled and tickN % math.max(1, math.floor((auto.Interval or 300) / cfg.TickInterval)) == 0 then
        Protected("Automatik", GARLog.TickAutoSupply)
    end
end)
