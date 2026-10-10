-- Client-Kern: Datenempfang, Benachrichtigungen, Aktionen, Abo-Verwaltung

local cfg = GARLog.Config
local C = GARLog.UI.C

GARLog.Data    = GARLog.Data or { loc = {}, req = {}, trn = { list = {}, cont = {}, busy = 0 }, prd = { lines = {} }, rep = {}, log = {} }
GARLog.Data.rpt = GARLog.Data.rpt or {}
GARLog.Data.veh = GARLog.Data.veh or {}
GARLog.DataVer = GARLog.DataVer or {}
GARLog.LocById = GARLog.LocById or {}

---------------------------------------------------------------------------
-- Laufzeitmessung (Konsole: garlog_perf_cl / garlog_perf_cl reset)
---------------------------------------------------------------------------
GARLog.PerfCL = GARLog.PerfCL or {}
GARLog.PerfCLFrame0 = GARLog.PerfCLFrame0 or FrameNumber()

function GARLog.Timed(name, fn)
    if not isfunction(fn) then return fn end
    return function(...)
        local t0 = SysTime()
        local a, b = fn(...)
        local dt = SysTime() - t0
        local p = GARLog.PerfCL[name]
        if not p then
            p = { n = 0, sum = 0, max = 0 }
            GARLog.PerfCL[name] = p
        end
        p.n, p.sum = p.n + 1, p.sum + dt
        if dt > p.max then p.max = dt end
        return a, b
    end
end

concommand.Add("garlog_perf_cl", function(_, _, args)
    if args[1] == "reset" then
        GARLog.PerfCL = {}
        GARLog.PerfCLFrame0 = FrameNumber()
        print("[GAR Logistik] Client-Messwerte zurückgesetzt.")
        return
    end
    local frames = math.max(1, FrameNumber() - GARLog.PerfCLFrame0)
    local list = {}
    for name, p in pairs(GARLog.PerfCL) do list[#list + 1] = { name = name, p = p } end
    table.sort(list, function(a, b) return a.p.sum > b.p.sum end)
    print(string.format("%-30s %8s %12s %10s %10s", "GAR LOGISTIK (Client)", "Aufrufe", "ms/Frame", "Schnitt ms", "Max ms"))
    for _, e in ipairs(list) do
        print(string.format("%-30s %8d %12.3f %10.3f %10.3f", e.name, e.p.n, e.p.sum / frames * 1000, e.p.sum / e.p.n * 1000, e.p.max * 1000))
    end
    print(string.format("(%d Frames gemessen)", frames))
end)

---------------------------------------------------------------------------
-- Serverzeit (für ETAs und Fortschrittsbalken)
---------------------------------------------------------------------------
GARLog.ServerNow0 = GARLog.ServerNow0 or os.time()
GARLog.ServerCur0 = GARLog.ServerCur0 or CurTime()

function GARLog.Now()
    return GARLog.ServerNow0 + (CurTime() - GARLog.ServerCur0)
end

---------------------------------------------------------------------------
-- Empfang
---------------------------------------------------------------------------
net.Receive("GARLog_Sync", GARLog.Timed("Sync empfangen", function()
    local len = net.ReadUInt(32)
    local raw = net.ReadData(len)
    local json = raw and util.Decompress(raw)
    local t = json and util.JSONToTable(json)
    if not istable(t) then return end

    if t.now then
        GARLog.ServerNow0 = t.now
        GARLog.ServerCur0 = CurTime()
    end

    for sec, d in pairs(t) do
        if sec ~= "now" then
            GARLog.Data[sec] = d
            GARLog.DataVer[sec] = (GARLog.DataVer[sec] or 0) + 1
            if sec == "loc" then
                local map = {}
                for _, l in ipairs(d) do map[l.id] = l end
                GARLog.LocById = map
            end
        end
    end
    for sec in pairs(t) do
        if sec ~= "now" then hook.Run("GARLog_Data", sec) end
    end
end))

local KIND = { [0] = "info", [1] = "ok", [2] = "warn", [3] = "err" }
net.Receive("GARLog_Notify", function()
    local text = net.ReadString()
    local kind = KIND[net.ReadUInt(2)] or "info"
    local col = kind == "err" and C.red or (kind == "warn" and C.orange or (kind == "ok" and C.green or C.white))
    chat.AddText(C.yellow, cfg.ChatTag .. " ", col, text)
    if kind == "err" then
        surface.PlaySound(cfg.Sounds.Error)
    elseif kind == "warn" then
        surface.PlaySound(cfg.Sounds.Warn)
    else
        surface.PlaySound(cfg.Sounds.Notify)
    end
end)

net.Receive("GARLog_Open", function()
    local kind = net.ReadUInt(3)
    if kind == 1 then
        local app = net.ReadUInt(3)
        local tab = net.ReadUInt(4)
        local loc = net.ReadString()
        local fromEntity = net.ReadBool()
        if GARLog.OpenMenu then GARLog.OpenMenu(tab, loc ~= "" and loc or nil, app, fromEntity) end
    elseif kind == 3 then
        local ent = net.ReadEntity()
        if IsValid(ent) and GARLog.OpenContainer then GARLog.OpenContainer(ent) end
    elseif kind == 4 then
        local ent = net.ReadEntity()
        if IsValid(ent) and GARLog.Builder and GARLog.Builder.ConfirmDismantle then GARLog.Builder.ConfirmDismantle(ent) end
    end
end)

---------------------------------------------------------------------------
-- Aktionen & Abo
---------------------------------------------------------------------------
function GARLog.Action(name, args)
    net.Start("GARLog_Action")
        net.WriteString(name)
        net.WriteString(util.TableToJSON(args or {}))
    net.SendToServer()
end

-- Abo-Stufen: "ui" = Menü offen (alle Daten), "tool" = Datapad in der Hand (nur Lagerdaten)
local SUB_LEVEL = { ui = 2, tool = 1 }
local subReasons, subLevel = {}, 0
function GARLog.SetSubscribed(reason, on)
    subReasons[reason] = on and true or nil
    local level = 0
    for r in pairs(subReasons) do level = math.max(level, SUB_LEVEL[r] or 2) end
    if level ~= subLevel then
        subLevel = level
        GARLog.Action("sub", { level = level })
    end
end

---------------------------------------------------------------------------
-- Hilfen für die Oberfläche
---------------------------------------------------------------------------
function GARLog.Loc(id) return GARLog.LocById[id] end

function GARLog.LocLabel(id)
    local l = GARLog.LocById[id]
    if l then return l.n end
    local s = GARLog.StaticLoc[id]
    return s and s.name or tostring(id or "—")
end

function GARLog.LocFrac(l, res)
    local cap = l.c[res] or 0
    if cap <= 0 then return 0 end
    return (l.s[res] or 0) / cap
end

-- Schlechtester Füllstand über die Schlüssel-Ressourcen
function GARLog.LocWorst(l)
    local worst, worstRes = 1, nil
    for _, res in ipairs(cfg.KeyResources or GARLog.ResOrder) do
        if (l.c[res] or 0) > 0 then
            local f = GARLog.LocFrac(l, res)
            if f < worst then worst, worstRes = f, res end
        end
    end
    return worst, worstRes
end

-- Reichweite in Minuten (aktueller Verbrauch)
function GARLog.LocSpan(l, res)
    local rate = (l.r or {})[res] or 0
    if rate <= 0.05 then return math.huge end
    return (l.s[res] or 0) / rate
end

-- Feldbasis, in der sich eine Position befindet (aus Sync-Daten)
function GARLog.FOBAt(pos)
    local best, bestD
    for _, l in ipairs(GARLog.Data.loc or {}) do
        local f = l.f
        if f then
            local d = pos:DistToSqr(Vector(f.x, f.y, f.z))
            if d <= f.r * f.r and (not bestD or d < bestD) then best, bestD = l, d end
        end
    end
    return best
end

function GARLog.LocalCan(perm)
    return GARLog.Can(LocalPlayer(), perm)
end

-- Kompakter Füllstand eines Standorts aus den Global-Variablen (für Welt-Anzeigen)
local statusCache = {}
function GARLog.GetLocStatus(locId)
    local s = GetGlobal2String("GARLog_S_" .. locId, "")
    local c = statusCache[locId]
    if c and c.raw == s then return c.vals end
    local vals = {}
    local i = 1
    for n in string.gmatch(s, "[^,]+") do
        vals[GARLog.ResOrder[i] or i] = (tonumber(n) or 0) / 100
        i = i + 1
    end
    statusCache[locId] = { raw = s, vals = vals }
    return vals
end

---------------------------------------------------------------------------
-- Wegpunkt für übernommene Reparaturaufträge
---------------------------------------------------------------------------
GARLog.Waypoints = GARLog.Waypoints or {}

net.Receive("GARLog_Waypoint", function()
    local id = net.ReadUInt(16)
    if net.ReadBool() then
        GARLog.Waypoints[id] = { title = net.ReadString(), pos = net.ReadVector(), ent = net.ReadUInt(16), label = "R-" .. id .. "  REPARATUR" }
    else
        GARLog.Waypoints[id] = nil
    end
end)

-- Eigene Markierung (Technik-Terminal: "MARKIEREN"), wird in der Nähe automatisch entfernt
function GARLog.ToggleMark(key, title, entIndex, pos)
    key = "m_" .. tostring(key)
    if GARLog.Waypoints[key] then
        GARLog.Waypoints[key] = nil
        return false
    end
    GARLog.Waypoints[key] = { title = title or "", ent = entIndex or 0, pos = pos or vector_origin, label = "MARKIERT", auto = true }
    return true
end

function GARLog.IsMarked(key)
    return GARLog.Waypoints["m_" .. tostring(key)] ~= nil
end

---------------------------------------------------------------------------
-- Wartungsberichte (vollständiger Bericht wird bei Bedarf geholt)
---------------------------------------------------------------------------
GARLog.ReportCache = GARLog.ReportCache or {}

net.Receive("GARLog_Report", function()
    local len = net.ReadUInt(32)
    local raw = net.ReadData(len)
    local json = raw and util.Decompress(raw)
    local r = json and util.JSONToTable(json)
    if not istable(r) or not r.id then return end
    GARLog.ReportCache[r.id] = r
    hook.Run("GARLog_Report", r)
end)

-- Liefert den gecachten Bericht, wenn er mindestens Version v hat; sonst (einmal) anfordern
local pendingReport = {}
function GARLog.GetReport(id, v)
    local r = GARLog.ReportCache[id]
    if r and (r.v or 0) >= (v or 0) then return r end
    local now = CurTime()
    if (pendingReport[id] or 0) > now then return end   -- Anfrage läuft bereits
    pendingReport[id] = now + 2
    GARLog.Action("rpt.get", { id = id })
end

hook.Add("GARLog_Report", "GARLog_ReportPending", function(r) pendingReport[r.id] = nil end)
