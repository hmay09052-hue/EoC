-- Logistik-Datapad: Lage, Lager & Standorte, Anträge, Transporte, Produktion, Technik, Protokoll

local cfg = GARLog.Config
local UI = GARLog.UI
local C = UI.C

local Menu = GARLog.Menu or {}
GARLog.Menu = Menu

local REQ_OPEN, REQ_APPROVED, REQ_TRANSIT = GARLog.REQ_OPEN, GARLog.REQ_APPROVED, GARLog.REQ_TRANSIT
local REP_OPEN, REP_ASSIGNED = GARLog.REP_OPEN, GARLog.REP_ASSIGNED

local function D() return GARLog.Data end
local function Can(perm) return GARLog.LocalCan(perm) end
local function LocName(id) return GARLog.LocLabel(id) end

local function Ago(t)
    local s = math.max(0, GARLog.Now() - (t or 0))
    if s < 60 then return "GERADE EBEN" end
    if s < 3600 then return "VOR " .. math.floor(s / 60) .. " MIN" end
    if s < 86400 then return "VOR " .. math.floor(s / 3600) .. " H" end
    return os.date("%d.%m. %H:%M", t)
end

local function Sig(list, fn)
    local t = {}
    for i, e in ipairs(list or {}) do t[i] = fn(e) end
    return table.concat(t, ",")
end

local function TypeColor(t)
    if t == "central" then return C.purple end
    if t == "ship" then return C.blue end
    return C.yellow
end

-- Klickbare Listenzeile
local function Row(parent, tall, paint, click)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:Dock(TOP)
    b:SetTall(tall)
    b:DockMargin(0, 0, 6, 4)
    b.Paint = paint
    b.DoClick = function(s)
        if click then UI.Click() click(s) end
    end
    if not click then b:SetCursor("arrow") end
    return b
end

local function RowBG(s, w, h, selected, stripe)
    surface.SetDrawColor(selected and C.yellowF or (s:IsHovered() and C.panel2 or C.panel))
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(selected and ColorAlpha(C.yellow, 150) or C.line)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    if stripe then
        surface.SetDrawColor(stripe)
        surface.DrawRect(0, 0, 2, h)
    end
end

local function ActionBar(parent)
    local bar = vgui.Create("DPanel", parent)
    bar:Dock(BOTTOM)
    bar:SetTall(42)
    bar:DockMargin(0, 10, 0, 0)
    bar.Paint = nil
    function bar:Add(label, accent, fn, enabled, tooltip, wide)
        local b = UI.Button(self, label, fn)
        b.Accent = accent or C.yellow
        b:Dock(LEFT)
        b:SetWide(wide or 190)
        b:DockMargin(0, 0, 8, 0)
        b:SetEnabled(enabled ~= false)
        if tooltip then b:SetTooltip(tooltip) end
        return b
    end
    return bar
end

local function DefaultSource(fromId)
    local l = GARLog.Loc(fromId)
    if l and l.t == "fob" then
        return GARLog.Loc(cfg.DefaultShip) and cfg.DefaultShip or "central"
    elseif l and l.t == "ship" then
        return "central"
    end
    return cfg.DefaultShip
end

---------------------------------------------------------------------------
-- Kennzahlen (gecacht pro Datenversion)
---------------------------------------------------------------------------
local statsSig, stats = nil, {}
function Menu.Stats()
    local v = D()
    local dv = GARLog.DataVer
    local s = (dv.req or 0) .. ":" .. (dv.trn or 0) .. ":" .. (dv.rep or 0) .. ":" .. (dv.prd or 0)
    if s == statsSig then return stats end
    statsSig = s
    local st = { open = 0, approved = 0, transit = 0, crit = 0, repOpen = 0, repAssigned = 0, lines = 0, mine = 0 }
    for _, r in ipairs(v.req or {}) do
        if r.st == REQ_OPEN then
            st.open = st.open + 1
            if r.pr >= 3 then st.crit = st.crit + 1 end
        elseif r.st == REQ_APPROVED then
            st.approved = st.approved + 1
        elseif r.st == REQ_TRANSIT then
            st.transit = st.transit + 1
        end
    end
    local sid = LocalPlayer():SteamID()
    for _, o in ipairs(v.rep or {}) do
        if o.st == REP_OPEN then st.repOpen = st.repOpen + 1 end
        if o.st == REP_ASSIGNED then
            st.repAssigned = st.repAssigned + 1
            if o.asid == sid then st.mine = st.mine + 1 end
        end
    end
    for _, l in ipairs((v.prd or {}).lines or {}) do
        if l.st == "run" then st.lines = st.lines + 1 end
    end
    st.busy = (v.trn or {}).busy or 0
    st.cont = #((v.trn or {}).cont or {})
    stats = st
    return st
end

---------------------------------------------------------------------------
-- Dialoge
---------------------------------------------------------------------------
local function PrioButtons(parent, value, onChange)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(38)
    row.Paint = nil
    local btns = {}
    for i, p in ipairs(GARLog.Prio) do
        local b = UI.Button(row, p.name, function()
            value = i
            for j, o in ipairs(btns) do o.Active = j == i end
            onChange(i)
        end)
        b.Accent = p.color
        b.Font = "GARLog_ButtonS"
        b.Active = i == value
        btns[i] = b
    end
    row.PerformLayout = function(_, w, h)
        local bw = math.floor((w - 18) / 4)
        for i, b in ipairs(btns) do
            b:SetPos((i - 1) * (bw + 6), 0)
            b:SetSize(bw, h)
        end
    end
    return row
end

local function DialogFooter(d, okLabel, onOk, accent)
    local row = vgui.Create("DPanel", d)
    row:Dock(BOTTOM)
    row:SetTall(44)
    row:DockMargin(0, 10, 0, 0)
    row.Paint = nil
    local no = UI.Button(row, "ABBRECHEN", function() d:Close() end)
    no:Dock(LEFT)
    no:SetWide(160)
    local ok = UI.Button(row, okLabel, onOk)
    ok.Solid = true
    ok.Accent = accent or C.yellow
    ok:Dock(RIGHT)
    ok:SetWide(260)
    return ok
end

local function TwoCols(parent, tall)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(tall)
    row.Paint = nil
    row.L = vgui.Create("DPanel", row)
    row.L.Paint = nil
    row.R = vgui.Create("DPanel", row)
    row.R.Paint = nil
    row.PerformLayout = function(s, w, h)
        local half = math.floor((w - 12) / 2)
        s.L:SetPos(0, 0) s.L:SetSize(half, h)
        s.R:SetPos(w - half, 0) s.R:SetSize(half, h)
    end
    return row
end

-- Neuer Versorgungsantrag
function Menu.RequestDialog(opts)
    opts = opts or {}
    local options = {}
    for _, l in ipairs(D().loc or {}) do
        local perm = l.t == "fob" and "request.create" or "request.fleet"
        if Can(perm) then options[#options + 1] = { l.n, l.id } end
    end
    if #options == 0 then
        chat.AddText(C.yellow, cfg.ChatTag .. " ", C.red, "Du darfst für keinen Standort Versorgung anfordern.")
        UI.ErrorSound()
        return
    end

    local from = opts.from
    if not from then
        local f = GARLog.FOBAtPos(LocalPlayer():GetPos())
        from = f and ("fob_" .. f.id) or cfg.DefaultShip
    end
    local valid = false
    for _, o in ipairs(options) do if o[2] == from then valid = true end end
    if not valid then from = options[1][2] end
    local src = DefaultSource(from)
    local prio = 2

    local d = UI.Dialog("VERSORGUNGSANTRAG", "NEUER ANTRAG", 680, 760)
    local cols = TwoCols(d, 64)
    UI.Section(cols.L, "ANFORDERNDER STANDORT")
    UI.Section(cols.R, "LIEFERANT")

    local picker, srcCombo
    local function srcOptions()
        local out = {}
        for _, l in ipairs(D().loc or {}) do
            if l.id ~= from then out[#out + 1] = { l.n, l.id } end
        end
        return out
    end
    local function updateHint()
        local l = GARLog.Loc(src)
        if IsValid(picker) then picker.Hint = l and l.s or {} end
    end

    local fromCombo = UI.Combo(cols.L, options, from, function(v)
        from = v
        if src == from then src = DefaultSource(from) end
        srcCombo:SetOptions(srcOptions(), src)
        updateHint()
    end)
    fromCombo:Dock(TOP)
    fromCombo:SetTall(34)
    srcCombo = UI.Combo(cols.R, srcOptions(), src, function(v) src = v updateHint() end)
    srcCombo:Dock(TOP)
    srcCombo:SetTall(34)

    UI.Spacer(d, 8)
    UI.Section(d, "PRIORITÄT")
    PrioButtons(d, prio, function(v) prio = v end)
    UI.Spacer(d, 8)
    UI.Section(d, "GÜTER  (SHIFT = ±100, STRG = ±1)")

    local volLabel
    picker = UI.ItemPicker(d, {
        onChange = function(items)
            if IsValid(volLabel) then volLabel.Volume = GARLog.ItemVolume(items) end
        end,
    })
    picker:Dock(TOP)
    updateHint()

    volLabel = vgui.Create("DPanel", d)
    volLabel:Dock(TOP)
    volLabel:SetTall(22)
    volLabel.Volume = 0
    volLabel.Paint = function(s, w, h)
        local over = s.Volume > cfg.Requests.MaxVolume
        draw.SimpleText(GARLog.FmtNum(s.Volume) .. " / " .. GARLog.FmtNum(cfg.Requests.MaxVolume) .. " FE", "GARLog_Section", w, h / 2, over and C.red or C.soft, 2, 1)
    end

    UI.Section(d, "BEGRÜNDUNG / NOTIZ")
    local note = UI.Entry(d, "z.B. Gefecht am Nordhang, hoher Verbrauch...", true)
    note:Dock(FILL)
    note.AllowInput = function(s) return (utf8.len(s:GetText()) or 0) >= cfg.Requests.NoteLength end

    DialogFooter(d, "ANTRAG STELLEN", function()
        local items = picker:GetItems()
        if not next(items) then UI.ErrorSound() return end
        GARLog.Action("req.create", { from = from, src = src, items = items, prio = prio, note = note:GetText() })
        d:Close()
    end)
    return d
end

-- Lieferung zu einem genehmigten Antrag planen
function Menu.PlanDialog(r)
    local srcLoc = GARLog.Loc(r.src)
    if not srcLoc then return end
    local mode = "shuttle"
    local canContainer = srcLoc.m and Can("container.pack")

    local d = UI.Dialog("LIEFERUNG PLANEN", "ANTRAG #" .. r.id .. "  //  " .. string.upper(LocName(r.src) .. " » " .. LocName(r.from)), 680, 640)

    UI.Section(d, "TRANSPORTART")
    local modeRow = vgui.Create("DPanel", d)
    modeRow:Dock(TOP)
    modeRow:SetTall(56)
    modeRow.Paint = nil

    local capBar, hint, picker
    local function capacity() return mode == "container" and cfg.Container.Capacity or cfg.Shuttle.Capacity end

    local fromLoc = GARLog.Loc(r.from)
    local ft = GARLog.FlightTime(srcLoc.t, fromLoc and fromLoc.t or "fob")
    local bShuttle = UI.Button(modeRow, "SHUTTLE")
    local free = cfg.Shuttle.Count - (D().trn.busy or 0)
    bShuttle.Sub = string.format("%d/%d FREI  //  FLUGZEIT %s", free, cfg.Shuttle.Count, GARLog.FmtTime(ft))
    local bCont = UI.Button(modeRow, "FRACHTCONTAINER")
    bCont.Sub = canContainer and ("PHYSISCH  //  MAX. " .. GARLog.FmtNum(cfg.Container.Capacity) .. " FE") or "NUR AM STANDORT (TERMINAL / RAMPE)"
    bCont:SetEnabled(canContainer and true or false)

    local function updateMode()
        bShuttle.Active = mode == "shuttle"
        bCont.Active = mode == "container"
        if IsValid(capBar) then capBar.Capacity = capacity() end
        if IsValid(hint) then
            hint:SetText(mode == "container"
                and ("Der Container wird an einer Frachtrampe / am Terminal von " .. LocName(r.src) .. " bereitgestellt. Du musst dich dort befinden. Danach per LAAT / Fahrzeug zu " .. LocName(r.from) .. " bringen und am Versorgungslager entladen.")
                or ("Ein Shuttle fliegt die Fracht automatisch nach " .. LocName(r.from) .. ". Feldbasen brauchen eine aktive Kommunikationsantenne als Leitsignal."))
        end
    end
    bShuttle.DoClick = function() UI.Click() mode = "shuttle" updateMode() end
    bCont.DoClick = function() UI.Click() mode = "container" updateMode() end
    modeRow.PerformLayout = function(_, w, h)
        local half = math.floor((w - 8) / 2)
        bShuttle:SetPos(0, 0) bShuttle:SetSize(half, h)
        bCont:SetPos(w - half, 0) bCont:SetSize(half, h)
    end

    UI.Spacer(d, 8)
    UI.Section(d, "FRACHT  (MAX. ANGEFORDERT / VERFÜGBAR)")
    local list, max, init = {}, {}, {}
    for _, res in ipairs(GARLog.ResOrder) do
        local want = r.it[res]
        if want and want > 0 then
            list[#list + 1] = res
            max[res] = math.min(want, srcLoc.s[res] or 0)
            init[res] = max[res]
        end
    end
    picker = UI.ItemPicker(d, {
        items = init, max = max, list = list,
        onChange = function(items) if IsValid(capBar) then capBar.Volume = GARLog.ItemVolume(items) end end,
    })
    picker:Dock(TOP)
    UI.Spacer(d, 6)
    capBar = UI.CapacityBar(d, capacity())
    capBar.Volume = GARLog.ItemVolume(init)

    hint = UI.Label(d, "", "GARLog_Small", C.muted)
    hint:DockMargin(0, 6, 0, 0)
    updateMode()

    DialogFooter(d, "LIEFERUNG STARTEN", function()
        local items = picker:GetItems()
        if not next(items) or GARLog.ItemVolume(items) > capacity() then UI.ErrorSound() return end
        GARLog.Action("req.plan", { id = r.id, mode = mode, items = items })
        d:Close()
    end)
end

-- Shuttle direkt entsenden
function Menu.ShuttleDialog(opts)
    opts = opts or {}
    local locs = D().loc or {}
    if #locs < 2 then return end
    local src = opts.src or "central"
    local dst = opts.dst or (src == cfg.DefaultShip and "central" or cfg.DefaultShip)
    if dst == src then dst = locs[1].id ~= src and locs[1].id or locs[2].id end

    local d = UI.Dialog("SHUTTLE ENTSENDEN", "DIREKTTRANSPORT", 680, 680)
    local cols = TwoCols(d, 64)
    UI.Section(cols.L, "START")
    UI.Section(cols.R, "ZIEL")

    local picker, capBar, info
    local function allOptions()
        local out = {}
        for _, l in ipairs(D().loc or {}) do out[#out + 1] = { l.n, l.id } end
        return out
    end
    local function refreshMax()
        local l = GARLog.Loc(src)
        if IsValid(picker) then picker:SetMax(l and table.Copy(l.s) or {}) end
    end
    local srcCombo = UI.Combo(cols.L, allOptions(), src, function(v) src = v refreshMax() end)
    srcCombo:Dock(TOP)
    srcCombo:SetTall(34)
    local dstCombo = UI.Combo(cols.R, allOptions(), dst, function(v) dst = v end)
    dstCombo:Dock(TOP)
    dstCombo:SetTall(34)

    UI.Spacer(d, 8)
    UI.Section(d, "FRACHT")
    picker = UI.ItemPicker(d, {
        max = {},
        onChange = function(items) if IsValid(capBar) then capBar.Volume = GARLog.ItemVolume(items) end end,
    })
    picker:Dock(TOP)
    refreshMax()
    UI.Spacer(d, 6)
    capBar = UI.CapacityBar(d, cfg.Shuttle.Capacity)

    info = vgui.Create("DPanel", d)
    info:Dock(TOP)
    info:SetTall(24)
    info.Paint = function(_, w, h)
        local a, b = GARLog.Loc(src), GARLog.Loc(dst)
        local free = cfg.Shuttle.Count - (D().trn.busy or 0)
        local text = string.format("SHUTTLES FREI: %d/%d", free, cfg.Shuttle.Count)
        if a and b and a.id ~= b.id then text = text .. "   //   FLUGZEIT " .. GARLog.FmtTime(GARLog.FlightTime(a.t, b.t)) end
        draw.SimpleText(text, "GARLog_Section", 0, h / 2, free > 0 and C.soft or C.red, 0, 1)
    end

    DialogFooter(d, "SHUTTLE STARTEN", function()
        local items = picker:GetItems()
        if src == dst or not next(items) or GARLog.ItemVolume(items) > cfg.Shuttle.Capacity then UI.ErrorSound() return end
        GARLog.Action("trn.create", { src = src, dst = dst, items = items })
        d:Close()
    end)
end

-- Frachtcontainer packen
function Menu.PackDialog(locId)
    local l = GARLog.Loc(locId)
    if not l then return end
    local d = UI.Dialog("CONTAINER PACKEN", string.upper(l.n), 640, 600)
    local capBar
    UI.Section(d, "FRACHT")
    local picker = UI.ItemPicker(d, {
        max = table.Copy(l.s),
        onChange = function(items) if IsValid(capBar) then capBar.Volume = GARLog.ItemVolume(items) end end,
    })
    picker:Dock(TOP)
    UI.Spacer(d, 6)
    capBar = UI.CapacityBar(d, cfg.Container.Capacity)
    local hint = UI.Label(d, "Der Container erscheint an einer freien Frachtrampe des Standorts oder neben dem Terminal / Versorgungslager. Du musst dich am Standort befinden.", "GARLog_Small", C.muted)
    hint:DockMargin(0, 6, 0, 0)
    DialogFooter(d, "CONTAINER BEREITSTELLEN", function()
        local items = picker:GetItems()
        if not next(items) or GARLog.ItemVolume(items) > cfg.Container.Capacity then UI.ErrorSound() return end
        GARLog.Action("cnt.pack", { loc = locId, items = items })
        d:Close()
    end)
end

-- Manueller Reparaturauftrag. opts: loc, title, note, prio, ent (Schiff/Fahrzeug/Struktur), rpt (Bericht)
function Menu.RepairDialog(opts)
    opts = opts or {}
    local options = {}
    for _, l in ipairs(D().loc or {}) do options[#options + 1] = { l.n, l.id } end
    if #options == 0 then return end
    local loc = opts.loc
    if not GARLog.Loc(loc or "") then
        local f = GARLog.FOBAtPos(LocalPlayer():GetPos())
        loc = f and ("fob_" .. f.id) or (GARLog.Loc(cfg.DefaultShip) and cfg.DefaultShip or options[1][2])
    end
    local prio = opts.prio or 2

    local sub = "NEUER AUFTRAG FÜR TECHNIKER"
    if opts.ent then sub = sub .. "  //  ZIEL MARKIERT" end
    if opts.rpt then sub = sub .. "  //  BERICHT W-" .. opts.rpt end
    local d = UI.Dialog("REPARATURAUFTRAG", sub, 600, 470)
    UI.Section(d, "STANDORT")
    local combo = UI.Combo(d, options, loc, function(v) loc = v end)
    combo:Dock(TOP)
    combo:SetTall(34)
    UI.Spacer(d, 8)
    UI.Section(d, "BEZEICHNUNG")
    local title = UI.Entry(d, "z.B. Hangartor 2 klemmt")
    title:Dock(TOP)
    title:SetTall(34)
    title:SetText(opts.title or "")
    title.AllowInput = function(s) return (utf8.len(s:GetText()) or 0) >= 60 end
    UI.Spacer(d, 8)
    UI.Section(d, "PRIORITÄT")
    PrioButtons(d, prio, function(v) prio = v end)
    UI.Spacer(d, 8)
    UI.Section(d, "DETAILS")
    local note = UI.Entry(d, "Beschreibung...", true)
    note:Dock(FILL)
    note:SetText(opts.note or "")
    note.AllowInput = function(s) return (utf8.len(s:GetText()) or 0) >= 200 end
    DialogFooter(d, "AUFTRAG ERSTELLEN", function()
        if string.Trim(title:GetText()) == "" then UI.ErrorSound() return end
        GARLog.Action("rep.create", { loc = loc, title = title:GetText(), note = note:GetText(), prio = prio, ent = opts.ent, rpt = opts.rpt })
        d:Close()
    end)
end

---------------------------------------------------------------------------
-- Tab 1: Lageübersicht
---------------------------------------------------------------------------
local function ComputeAlerts()
    local list = {}
    -- tab: Zahl = Tab der Logistik-App, "t1"/"t2" = Tab des Technik-Terminals
    local function add(prio, col, title, sub, tab, loc)
        local app = 1
        if isstring(tab) then app, tab = 3, tonumber(tab:sub(2)) or 1 end
        list[#list + 1] = { p = prio, c = col, t = title, s = sub, tab = tab, loc = loc, app = app }
    end
    for _, l in ipairs(D().loc or {}) do
        for _, res in ipairs(cfg.KeyResources) do
            if (l.c[res] or 0) > 0 then
                local frac = GARLog.LocFrac(l, res)
                local idx, st = GARLog.SupplyStatus(frac)
                if idx >= 3 then
                    local span = GARLog.LocSpan(l, res)
                    add(idx, st.color, string.upper(l.n) .. ": " .. GARLog.Res[res].name:upper() .. " " .. st.name,
                        math.floor(frac * 100) .. "%  //  REICHWEITE " .. GARLog.FmtSpan(span), 2, l.id)
                end
            end
        end
        local f = l.f
        if f then
            if not f.pw then add(3, C.red, string.upper(l.n) .. ": KEIN STROM", "Generator prüfen / Treibstoff liefern", 2, l.id) end
            if not f.an then add(2, C.orange, string.upper(l.n) .. ": KEINE FUNKVERBINDUNG", "Keine Anträge & Shuttle-Landungen möglich", 2, l.id) end
            local destroyed = 0
            for _, e in ipairs(f.st or {}) do if e.d then destroyed = destroyed + 1 end end
            if destroyed > 0 then add(3, C.red, string.upper(l.n) .. ": " .. destroyed .. " STRUKTUR(EN) ZERSTÖRT", "Techniker anfordern", "t1", l.id) end
        end
    end
    local st = Menu.Stats()
    if st.open > 0 and Can("request.approve") then
        add(st.crit > 0 and 3 or 2, C.yellow, st.open .. " ANTRÄGE WARTEN AUF GENEHMIGUNG", st.crit > 0 and (st.crit .. " davon hoch / kritisch") or "Navy / Kommando", 3)
    end
    if st.approved > 0 and Can("request.plan") then
        add(2, C.blue, st.approved .. " GENEHMIGTE ANTRÄGE OHNE LIEFERUNG", "Lieferung planen", 3)
    end
    if st.repOpen > 0 and Can("repair.work") then
        add(2, C.cyan, st.repOpen .. " OFFENE REPARATURAUFTRÄGE", "Technik-Kontrollterminal (R)", "t2")
    end
    table.sort(list, function(a, b) return a.p > b.p end)
    return list
end

local function BuildDashboard(parent)
    local self = {}

    -- Kennzahlen
    local kpi = vgui.Create("DPanel", parent)
    kpi:Dock(TOP)
    kpi:SetTall(68)
    kpi:DockMargin(0, 0, 0, 14)
    kpi.Paint = nil
    local tiles = {}
    local function Tile(label, fn)
        local p = vgui.Create("DPanel", kpi)
        p.Paint = function(_, w, h)
            local v, col, sub = fn()
            surface.SetDrawColor(C.panel)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(C.line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            surface.SetDrawColor(col)
            surface.DrawRect(0, 0, 2, h)
            draw.SimpleText(v, "GARLog_Big", 14, h / 2 - 8, col, 0, 1)
            draw.SimpleText(label, "GARLog_Tiny", 14, h - 13, C.soft, 0, 1)
            if sub then draw.SimpleText(sub, "GARLog_Tiny", w - 10, 14, C.muted, 2, 1) end
        end
        tiles[#tiles + 1] = p
    end
    Tile("ANTRÄGE OFFEN", function() local s = Menu.Stats() return tostring(s.open), s.crit > 0 and C.red or (s.open > 0 and C.yellow or C.soft), s.crit > 0 and (s.crit .. " KRIT.") or nil end)
    Tile("ZU PLANEN", function() local s = Menu.Stats() return tostring(s.approved), s.approved > 0 and C.blue or C.soft end)
    Tile("IM TRANSPORT", function() local s = Menu.Stats() return tostring(s.transit), s.transit > 0 and C.cyan or C.soft end)
    Tile("SHUTTLES FREI", function() local s = Menu.Stats() local f = cfg.Shuttle.Count - s.busy return f .. "/" .. cfg.Shuttle.Count, f > 0 and C.green or C.red end)
    Tile("PRODUKTION", function() local s = Menu.Stats() return s.lines .. "/" .. cfg.Production.Lines, s.lines > 0 and C.green or C.soft, "LINIEN" end)
    Tile("REPARATUREN", function() local s = Menu.Stats() return tostring(s.repOpen + s.repAssigned), s.repOpen > 0 and C.orange or C.soft, s.mine > 0 and (s.mine .. " DEINE") or nil end)
    kpi.PerformLayout = function(_, w, h)
        local n = #tiles
        local tw = math.floor((w - (n - 1) * 8) / n)
        for i, t in ipairs(tiles) do
            t:SetPos((i - 1) * (tw + 8), 0)
            t:SetSize(tw, h)
        end
    end

    -- Rechte Spalte: Warnungen & Ereignisse
    local right = vgui.Create("DPanel", parent)
    right:Dock(RIGHT)
    right:SetWide(340)
    right:DockMargin(16, 0, 0, 0)
    right.Paint = nil

    local events = vgui.Create("DPanel", right)
    events:Dock(BOTTOM)
    events:SetTall(196)
    events:DockMargin(0, 10, 0, 0)
    events.Paint = function(_, w, h)
        surface.SetDrawColor(C.yellow)
        surface.DrawRect(0, 8, 2, 12)
        draw.SimpleText("LETZTE EREIGNISSE", "GARLog_Section", 10, 14, C.soft, 0, 1)
        local y = 34
        for i = 1, 6 do
            local e = (D().log or {})[i]
            if not e then break end
            draw.SimpleText(os.date("%H:%M", e.t), "GARLog_Tiny", 0, y + 8, C.muted, 0, 1)
            draw.SimpleText(UI.Truncate(e.x, "GARLog_Small", w - 46), "GARLog_Small", 42, y + 8, GARLog.LogKindColor[e.k] or C.text, 0, 1)
            y = y + 26
        end
    end

    UI.Section(right, "WARNUNGEN")
    local alertScroll = UI.Scroll(right)
    alertScroll:Dock(FILL)

    -- Neu gebaut wird nur, wenn Warnungen dazukommen/wegfallen; Prozente & Reichweite werden live gezeichnet
    local alertSig
    local alertLive = {}
    local function RebuildAlerts()
        local alerts = ComputeAlerts()
        alertLive = {}
        for _, a in ipairs(alerts) do alertLive[a.t] = a end
        local s = Sig(alerts, function(a) return a.t end)
        if s == alertSig then return end
        alertSig = s
        alertScroll:Clear()
        if #alerts == 0 then
            UI.Empty(alertScroll, "Keine Warnungen – Versorgung stabil.")
            return
        end
        for _, a0 in ipairs(alerts) do
            local a = a0
            Row(alertScroll, 46, function(sb, w, h)
                a = alertLive[a0.t] or a0
                RowBG(sb, w, h, false, a.c)
                draw.SimpleText(UI.Truncate(a.t, "GARLog_Small", w - 20), "GARLog_Small", 12, 15, C.white, 0, 1)
                draw.SimpleText(UI.Truncate(a.s or "", "GARLog_Tiny", w - 20), "GARLog_Tiny", 12, 32, C.soft, 0, 1)
            end, function()
                if IsValid(Menu.Frame) then Menu.Frame:ShowApp(a.app or 1, a.tab, a.loc) end
            end)
        end
    end

    -- Versorgungslage aller Standorte
    local left = vgui.Create("DPanel", parent)
    left:Dock(FILL)
    left.Paint = nil
    UI.Section(left, "VERSORGUNGSLAGE")
    local locScroll = UI.Scroll(left)
    locScroll:Dock(FILL)

    local locSig
    local function RebuildLocs()
        local s = Sig(D().loc, function(l) return l.id end)
        if s == locSig then return end
        locSig = s
        locScroll:Clear()
        if #(D().loc or {}) == 0 then
            UI.Empty(locScroll, "Daten werden geladen...")
            return
        end
        for _, l0 in ipairs(D().loc) do
            local id = l0.id
            Row(locScroll, 96, function(sb, w, h)
                local l = GARLog.Loc(id)
                if not l then return end
                local worst = GARLog.LocWorst(l)
                local _, st = GARLog.SupplyStatus(worst)
                RowBG(sb, w, h, false, st.color)

                local nw = draw.SimpleText(string.upper(l.n), "GARLog_Head", 14, 18, C.white, 0, 1)
                local x = 14 + nw + 10
                x = x + UI.Tag(GARLog.LocTypeName[l.t] or l.t, x, 18, TypeColor(l.t)) + 6
                if l.f then
                    x = x + UI.Tag(l.f.pw and "STROM" or "KEIN STROM", x, 18, l.f.pw and C.green or C.red) + 6
                    x = x + UI.Tag(l.f.an and "FUNK" or "KEIN FUNK", x, 18, l.f.an and C.green or C.orange) + 6
                    UI.Tag(l.f.pr .. " ANWESEND", x, 18, C.soft)
                end
                UI.Tag(st.name, w - 10, 18, st.color, nil, true)

                local list = cfg.OverviewResources or GARLog.ResOrder
                local n = #list
                local bw = (w - 28 - (n - 1) * 8) / n
                for i, res in ipairs(list) do
                    local bx = 14 + (i - 1) * (bw + 8)
                    local cap = l.c[res] or 0
                    local frac = cap > 0 and (l.s[res] or 0) / cap or 0
                    local _, rs = GARLog.SupplyStatus(frac)
                    draw.SimpleText(GARLog.Res[res].short, "GARLog_Tiny", bx, 46, C.soft, 0, 1)
                    draw.SimpleText(GARLog.FmtNum(l.s[res] or 0), "GARLog_Tiny", bx + bw, 46, C.text, 2, 1)
                    UI.Bar(bx, 56, bw, 8, frac, cap > 0 and rs.color or C.muted)
                    draw.SimpleText(cap > 0 and (math.floor(frac * 100) .. "%") or "—", "GARLog_Tiny", bx, 76, cap > 0 and rs.color or C.muted, 0, 1)
                end
            end, function()
                if IsValid(Menu.Frame) then Menu.Frame:ShowApp(1, 2, id) end
            end)
        end
    end

    RebuildLocs()
    RebuildAlerts()
    function self.Refresh(sec)
        if sec == "loc" then RebuildLocs() end
        RebuildAlerts()
    end
    return self
end

---------------------------------------------------------------------------
-- Tab 2: Lager & Standorte
---------------------------------------------------------------------------
local function BuildLocations(parent, ctx)
    local self = {}
    local onlyFob = ctx.onlyFob
    local function Visible(l) return l and (not onlyFob or l.t == "fob") end
    local function FirstVisible()
        for _, l in ipairs(D().loc or {}) do if Visible(l) then return l.id end end
    end
    local selected = ctx.loc or (onlyFob and Menu.LastFob or Menu.LastLoc)
    if not Visible(GARLog.Loc(selected or "")) then selected = FirstVisible() end

    local left = vgui.Create("DPanel", parent)
    left:Dock(LEFT)
    left:SetWide(250)
    left.Paint = nil
    UI.Section(left, onlyFob and "FELDBASEN" or "STANDORTE")
    local listScroll = UI.Scroll(left)
    listScroll:Dock(FILL)

    local detail = vgui.Create("DPanel", parent)
    detail:Dock(FILL)
    detail:DockMargin(16, 0, 0, 0)
    detail.Paint = nil

    local ShowDetail

    local listSig
    local function RebuildList()
        local s = Sig(D().loc, function(l) return l.id .. l.n end)
        if s == listSig then return end
        listSig = s
        listScroll:Clear()
        local groups = onlyFob and { { "fob", "FELDBASEN" } } or { { "central", "ZENTRALLAGER" }, { "ship", "FLOTTE" }, { "fob", "FELDBASEN" } }
        for _, g in ipairs(groups) do
            local any = false
            for _, l0 in ipairs(D().loc or {}) do
                if l0.t == g[1] then
                    if not any then
                        any = true
                        local hdr = vgui.Create("DPanel", listScroll)
                        hdr:Dock(TOP)
                        hdr:SetTall(22)
                        hdr.Paint = function(_, w, h) draw.SimpleText(g[2], "GARLog_Tiny", 2, h / 2, C.muted, 0, 1) end
                    end
                    local id = l0.id
                    Row(listScroll, 52, function(sb, w, h)
                        local l = GARLog.Loc(id)
                        if not l then return end
                        local worst = GARLog.LocWorst(l)
                        local _, st = GARLog.SupplyStatus(worst)
                        RowBG(sb, w, h, selected == id, st.color)
                        draw.SimpleText(UI.Truncate(string.upper(l.n), "GARLog_ButtonS", w - 20), "GARLog_ButtonS", 12, 17, C.white, 0, 1)
                        local sub = st.name
                        if l.f then sub = sub .. (l.f.pw and "  //  STROM" or "  //  KEIN STROM") end
                        draw.SimpleText(sub, "GARLog_Tiny", 12, 36, st.color, 0, 1)
                    end, function()
                        selected = id
                        if onlyFob then Menu.LastFob = id else Menu.LastLoc = id end
                        ShowDetail()
                    end)
                end
            end
        end
        if #(D().loc or {}) == 0 then
            UI.Empty(listScroll, "Daten werden geladen...")
        elseif onlyFob and not FirstVisible() then
            UI.Empty(listScroll, "Keine Feldbasis aktiv.")
        end
    end

    local detailSig
    ShowDetail = function()
        detail:Clear()
        local l = GARLog.Loc(selected or "")
        detailSig = l and (l.id .. "|" .. (l.f and Sig(l.f.st, function(e) return e.k .. e.i end) or "")) or ""
        if not l then
            UI.Empty(detail, onlyFob and "Keine Feldbasis ausgewählt. Gründe eine mit dem Datapad (RMB > Versorgungslager)." or "Standort auswählen.")
            return
        end
        local id = l.id

        -- Kopf
        local head = vgui.Create("DPanel", detail)
        head:Dock(TOP)
        head:SetTall(70)
        head.Paint = function(_, w, h)
            local cur = GARLog.Loc(id)
            if not cur then return end
            local nw = draw.SimpleText(string.upper(cur.n), "GARLog_Title", 0, 20, C.white, 0, 1)
            UI.Tag(GARLog.LocTypeName[cur.t] or cur.t, nw + 12, 22, TypeColor(cur.t))
            local worst = GARLog.LocWorst(cur)
            local _, st = GARLog.SupplyStatus(worst)
            UI.Tag("VERSORGUNG: " .. st.name, w, 22, st.color, "GARLog_Tiny", true)
            local x = 0
            if cur.f then
                local f = cur.f
                x = x + UI.Tag(f.pw and "STROM AKTIV" or "KEIN STROM", x, 54, f.pw and C.green or C.red) + 6
                x = x + UI.Tag(f.an and "FUNK ZUR FLOTTE" or "KEIN FUNK", x, 54, f.an and C.green or C.orange) + 6
                x = x + UI.Tag(f.pr .. " SOLDATEN ANWESEND", x, 54, C.soft) + 6
                x = x + UI.Tag(f.sto .. " VERSORGUNGSLAGER", x, 54, C.soft) + 6
                if f.fd then UI.Tag("GEGRÜNDET VON " .. string.upper(f.fd), x, 54, C.muted) end
            else
                x = x + UI.Tag(cur.m and "AUF DER KARTE VERANKERT" or "NICHT AUF DIESER KARTE", x, 54, cur.m and C.green or C.muted) + 6
            end
        end

        -- Aktionen
        local bar = ActionBar(detail)
        bar:Add("CONTAINER PACKEN", C.yellow, function() Menu.PackDialog(id) end,
            Can("container.pack") and l.m, l.m and "Frachtcontainer aus diesem Lager bereitstellen" or "Standort ist auf dieser Karte nicht verankert", 180)
        bar:Add("ANFORDERN", C.blue, function() Menu.RequestDialog({ from = id }) end,
            Can(l.t == "fob" and "request.create" or "request.fleet"), nil, 140)
        bar:Add("SHUTTLE", C.cyan, function() Menu.ShuttleDialog({ src = id }) end, Can("transport.create"), "Shuttle von hier entsenden", 120)
        if l.f then
            local fobId = l.f.id
            bar:Add("UMBENENNEN", C.soft, function()
                UI.Prompt("FELDBASIS UMBENENNEN", "Neuer Name der Feldbasis:", "Name", l.n, function(v)
                    GARLog.Action("fob.rename", { fob = fobId, name = v })
                end, cfg.FOB.NameLength)
            end, Can("fob.manage"), nil, 130)
            bar:Add("AUFLÖSEN", C.red, function()
                UI.Confirm("FELDBASIS AUFLÖSEN", "Alle Strukturen von " .. l.n .. " werden entfernt. Restbestände gehen verloren – vorher in Container packen!", "AUFLÖSEN", function()
                    GARLog.Action("fob.dissolve", { fob = fobId })
                end, C.red)
            end, Can("fob.manage"), nil, 110)
        end

        local scroll = UI.Scroll(detail)
        scroll:Dock(FILL)
        scroll:DockMargin(0, 8, 0, 0)

        UI.Section(scroll, "LAGERBESTAND")
        local isAdmin = GARLog.IsAdmin(LocalPlayer())
        local lastStorage
        for _, res in ipairs(GARLog.ResOrder) do
            local r = GARLog.Res[res]
            -- Lager-Gruppe mit Gesamtkapazität (z. B. "TECHNISCHES LAGER 7.420 / 10.000")
            if r.storage ~= lastStorage then
                lastStorage = r.storage
                local storage = r.storage
                local head = vgui.Create("DPanel", scroll)
                head:Dock(TOP)
                head:SetTall(34)
                head:DockMargin(0, 8, 6, 4)
                head.Paint = function(_, w, h)
                    local cur = GARLog.Loc(id)
                    if not cur then return end
                    local sum, cap = 0, 0
                    for _, rid in ipairs(GARLog.ResOrder) do
                        if GARLog.Res[rid].storage == storage then
                            sum = sum + (cur.s[rid] or 0) * (GARLog.Res[rid].volume or 1)
                            cap = cap + (cur.c[rid] or 0) * (GARLog.Res[rid].volume or 1)
                        end
                    end
                    local frac = cap > 0 and sum / cap or 0
                    local _, st = GARLog.SupplyStatus(frac)
                    draw.SimpleText(string.upper(storage), "GARLog_Head", 0, 13, C.white, 0, 1)
                    draw.SimpleText(GARLog.FmtNum(sum) .. " / " .. GARLog.FmtNum(cap) .. " FE", "GARLog_Small", w, 13, cap > 0 and st.color or C.muted, 2, 1)
                    UI.Bar(0, 28, w, 4, frac, cap > 0 and st.color or C.muted)
                end
            end
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:SetTall(46)
            row:DockMargin(0, 0, 6, 4)
            row.Paint = function(_, w, h)
                local cur = GARLog.Loc(id)
                if not cur then return end
                local v, cap = cur.s[res] or 0, cur.c[res] or 0
                local frac = cap > 0 and v / cap or 0
                local _, st = GARLog.SupplyStatus(frac)
                surface.SetDrawColor(C.panel)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(C.line)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                surface.SetDrawColor(r.color)
                surface.DrawRect(0, 0, 2, h)

                draw.SimpleText(r.name:upper(), "GARLog_ButtonS", 12, 15, C.white, 0, 1)
                local storage = cur.t == "ship" and r.storage or (cur.t == "fob" and "FELDLAGER" or "ZENTRALLAGER")
                draw.SimpleText(string.upper(storage), "GARLog_Tiny", 12, 33, C.muted, 0, 1)

                local right = isAdmin and 70 or 0
                local bx, bw = 170, math.max(80, w - 170 - 230 - right)
                draw.SimpleText(GARLog.FmtNum(v) .. " / " .. GARLog.FmtNum(cap), "GARLog_Small", bx, 14, C.text, 0, 1)
                draw.SimpleText(cap > 0 and (math.floor(frac * 100) .. "%") or "—", "GARLog_Small", bx + bw, 14, st.color, 2, 1)
                UI.Bar(bx, 26, bw, 8, frac, cap > 0 and st.color or C.muted)

                local rate = (cur.r or {})[res] or 0
                local rx = bx + bw + 20
                draw.SimpleText("VERBRAUCH", "GARLog_Tiny", rx, 14, C.muted, 0, 1)
                draw.SimpleText(rate > 0.05 and ("-" .. math.Round(rate, 1) .. " / MIN") or "—", "GARLog_Small", rx, 31, rate > 0.05 and C.text or C.muted, 0, 1)
                local span = GARLog.LocSpan(cur, res)
                local sx = rx + 105
                draw.SimpleText("REICHWEITE", "GARLog_Tiny", sx, 14, C.muted, 0, 1)
                draw.SimpleText(GARLog.FmtSpan(span), "GARLog_Small", sx, 31, span < 30 and C.red or (span < 90 and C.orange or C.text), 0, 1)
            end
            if isAdmin then
                local set = UI.Button(row, "SETZEN", function()
                    local cur = GARLog.Loc(id)
                    UI.Prompt("BESTAND SETZEN", "Admin: neuer Bestand für " .. r.name .. " (max. " .. GARLog.FmtNum(cur and cur.c[res] or 0) .. ")", "Menge",
                        tostring(cur and cur.s[res] or 0), function(v)
                            GARLog.Action("admin.setstock", { loc = id, res = res, n = tonumber(v) or 0 })
                        end, 9, true)
                end)
                set.Font = "GARLog_ButtonS"
                set.Accent = C.red
                set:Dock(RIGHT)
                set:SetWide(62)
                set:DockMargin(0, 8, 8, 8)
            end
        end

        if l.f then
            UI.Spacer(scroll, 8)
            UI.Section(scroll, "STRUKTUREN DER FELDBASIS")
            if #(l.f.st or {}) == 0 then UI.Empty(scroll, "Keine Strukturen.") end
            for _, e in ipairs(l.f.st or {}) do
                local def = GARLog.BuildDefs[e.k]
                local entIndex = e.i
                local row = vgui.Create("DPanel", scroll)
                row:Dock(TOP)
                row:SetTall(34)
                row:DockMargin(0, 0, 6, 3)
                row.Paint = function(_, w, h)
                    local cur = GARLog.Loc(id)
                    local info
                    for _, x in ipairs(cur and cur.f and cur.f.st or {}) do if x.i == entIndex then info = x break end end
                    if not info then return end
                    surface.SetDrawColor(C.panel)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(C.line)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    draw.SimpleText(string.upper(def and def.name or e.k), "GARLog_ButtonS", 12, h / 2, C.white, 0, 1)
                    local state, col, frac
                    if info.b then
                        state, col, frac = "IM BAU " .. math.floor(info.b * 100) .. "%", C.cyan, info.b
                    elseif info.d then
                        state, col, frac = "ZERSTÖRT", C.red, info.hp
                    elseif info.hp then
                        local needs = def and def.needsPower
                        if needs and not info.p then state, col = "KEIN STROM", C.orange
                        elseif info.hp < 0.5 then state, col = "BESCHÄDIGT", C.orange
                        else state, col = "EINSATZBEREIT", C.green end
                        frac = info.hp
                    else
                        state, col = def and def.sse and "AUSSTATTUNG" or "AKTIV", C.soft
                    end
                    UI.Tag(state, w - 10, h / 2, col, nil, true)
                    if frac then
                        local _, hs = GARLog.SupplyStatus(frac)
                        UI.Bar(240, h / 2 - 3, math.max(40, w - 420), 6, frac, info.b and C.cyan or hs.color)
                    end
                end
            end
        end
    end

    RebuildList()
    ShowDetail()

    function self.Refresh(sec)
        if sec ~= "loc" then return end
        RebuildList()
        local l = GARLog.Loc(selected or "")
        if not Visible(l) then
            selected = FirstVisible()
            ShowDetail()
            return
        end
        local s = l.id .. "|" .. (l.f and Sig(l.f.st, function(e) return e.k .. e.i end) or "")
        if s ~= detailSig then ShowDetail() end
    end
    function self.Select(id)
        if GARLog.Loc(id or "") then selected = id ShowDetail() end
    end
    return self
end

---------------------------------------------------------------------------
-- Tab 3: Versorgungsanträge
---------------------------------------------------------------------------
local function ReqFilter(r, filter)
    if filter == "active" then return r.st <= REQ_TRANSIT end
    if filter == "open" then return r.st == REQ_OPEN end
    if filter == "done" then return r.st > REQ_TRANSIT end
    return true
end

local function BuildRequests(parent, ctx)
    local self = {}
    local filter = "active"
    local selectedId

    local top = vgui.Create("DPanel", parent)
    top:Dock(TOP)
    top:SetTall(36)
    top:DockMargin(0, 0, 0, 10)
    top.Paint = nil

    local filterBtns = {}
    local RebuildList
    for _, fdef in ipairs({ { "active", "AKTIV" }, { "open", "ZUR GENEHMIGUNG" }, { "done", "ERLEDIGT" }, { "all", "ALLE" } }) do
        local b = UI.Button(top, fdef[2], function()
            filter = fdef[1]
            for k, o in pairs(filterBtns) do o.Active = k == filter end
            RebuildList(true)
        end)
        b.Font = "GARLog_ButtonS"
        b:Dock(LEFT)
        b:SetWide(fdef[1] == "open" and 150 or 100)
        b:DockMargin(0, 0, 6, 0)
        b.Active = fdef[1] == filter
        filterBtns[fdef[1]] = b
    end
    local newB = UI.Button(top, "+ NEUER ANTRAG", function() Menu.RequestDialog() end)
    newB.Solid = true
    newB:Dock(RIGHT)
    newB:SetWide(170)

    local left = vgui.Create("DPanel", parent)
    left:Dock(LEFT)
    left:SetWide(420)
    left.Paint = nil
    local listScroll = UI.Scroll(left)
    listScroll:Dock(FILL)

    local detail = vgui.Create("DPanel", parent)
    detail:Dock(FILL)
    detail:DockMargin(16, 0, 0, 0)
    detail.Paint = nil

    local function FindReq(id)
        for _, r in ipairs(D().req or {}) do if r.id == id then return r end end
    end

    local detailSig
    local function ShowDetail()
        detail:Clear()
        local r = selectedId and FindReq(selectedId)
        detailSig = r and (r.id .. ":" .. r.st .. ":" .. (r.u or 0)) or ""
        if not r then
            UI.Empty(detail, #(D().req or {}) == 0 and "Noch keine Versorgungsanträge." or "Antrag auswählen.")
            return
        end
        local rid = r.id

        local head = vgui.Create("DPanel", detail)
        head:Dock(TOP)
        head:SetTall(44)
        head.Paint = function(_, w, h)
            local st = GARLog.ReqStatus[r.st]
            local nw = draw.SimpleText("ANTRAG #" .. r.id, "GARLog_Title", 0, h / 2, C.white, 0, 1)
            local x = nw + 12
            x = x + UI.Tag(st.name, x, h / 2, st.color) + 6
            local p = GARLog.Prio[r.pr] or GARLog.Prio[2]
            UI.Tag(p.name, x, h / 2, p.color)
        end

        local info = UI.Framed(detail)
        info:Dock(TOP)
        info:SetTall(92)
        info:DockMargin(0, 6, 0, 8)
        local base = info.Paint
        info.Paint = function(s, w, h)
            base(s, w, h)
            local function kv(x, y, k, v, col)
                draw.SimpleText(k, "GARLog_Tiny", x, y, C.muted, 0, 1)
                draw.SimpleText(v, "GARLog_Small", x, y + 16, col or C.white, 0, 1)
            end
            local half = w / 2
            kv(12, 16, "ANFORDERER", string.upper(LocName(r.from)), C.yellow)
            kv(half, 16, "LIEFERANT", string.upper(LocName(r.src)))
            kv(12, 56, "GESTELLT VON", (r.by or "?") .. "  //  " .. Ago(r.t))
            local via = r.via == "container" and ("CONTAINER" .. (r.cnt and (" C-" .. r.cnt) or "")) or (r.via == "shuttle" and ("SHUTTLE" .. (r.trn and (" T-" .. r.trn) or "")) or "—")
            kv(half, 56, r.ab and ("GENEHMIGT VON " .. string.upper(r.ab)) or "VERSAND", via)
        end

        -- Aktionen
        local bar = ActionBar(detail)
        if r.st == REQ_OPEN then
            bar:Add("GENEHMIGEN", C.green, function() GARLog.Action("req.approve", { id = rid, ok = true }) end, Can("request.approve"), nil, 150)
            bar:Add("ABLEHNEN", C.red, function()
                UI.Confirm("ANTRAG ABLEHNEN", "Antrag #" .. rid .. " von " .. LocName(r.from) .. " wirklich ablehnen?", "ABLEHNEN", function()
                    GARLog.Action("req.approve", { id = rid, ok = false })
                end, C.red)
            end, Can("request.approve"), nil, 130)
        elseif r.st == REQ_APPROVED then
            bar:Add("LIEFERUNG PLANEN", C.yellow, function() Menu.PlanDialog(r) end, Can("request.plan"), nil, 200)
        end
        if r.st == REQ_OPEN or r.st == REQ_APPROVED then
            local own = r.sid == LocalPlayer():SteamID()
            bar:Add("STORNIEREN", C.soft, function()
                UI.Confirm("ANTRAG STORNIEREN", "Antrag #" .. rid .. " stornieren?", "STORNIEREN", function()
                    GARLog.Action("req.cancel", { id = rid })
                end, C.red)
            end, own or Can("request.approve"), nil, 130)
        end

        local scroll = UI.Scroll(detail)
        scroll:Dock(FILL)

        UI.Section(scroll, "GÜTER")
        for _, res in ipairs(GARLog.ResOrder) do
            local want = r.it[res]
            if want and want > 0 then
                local rr = GARLog.Res[res]
                local row = vgui.Create("DPanel", scroll)
                row:Dock(TOP)
                row:SetTall(34)
                row:DockMargin(0, 0, 6, 3)
                row.Paint = function(_, w, h)
                    surface.SetDrawColor(C.panel)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(C.line)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    surface.SetDrawColor(rr.color)
                    surface.DrawRect(0, 0, 2, h)
                    draw.SimpleText(rr.name:upper(), "GARLog_ButtonS", 12, h / 2, C.white, 0, 1)
                    local col = math.floor(w / 4)
                    draw.SimpleText("ANGEFORDERT " .. GARLog.FmtNum(want), "GARLog_Tiny", col + 20, h / 2, C.text, 0, 1)
                    if r.st <= REQ_APPROVED then
                        local src = GARLog.Loc(r.src)
                        local have = src and (src.s[res] or 0) or 0
                        draw.SimpleText("LIEFERANT HAT " .. GARLog.FmtNum(have), "GARLog_Tiny", col * 2 + 20, h / 2, have >= want and C.green or C.orange, 0, 1)
                    elseif r.sh and r.sh[res] then
                        draw.SimpleText("VERSANDT " .. GARLog.FmtNum(r.sh[res]), "GARLog_Tiny", col * 2 + 20, h / 2, C.cyan, 0, 1)
                    end
                    if r.dl then
                        draw.SimpleText("GELIEFERT " .. GARLog.FmtNum(r.dl[res] or 0), "GARLog_Tiny", w - 12, h / 2, C.green, 2, 1)
                    end
                end
            end
        end

        if r.nt and r.nt ~= "" then
            UI.Spacer(scroll, 6)
            UI.Section(scroll, "BEGRÜNDUNG")
            local nl = UI.Label(scroll, r.nt, "GARLog_Text", C.text)
            nl:DockMargin(10, 0, 10, 6)
        end

        UI.Spacer(scroll, 6)
        UI.Section(scroll, "VERLAUF")
        for i = #(r.h or {}), 1, -1 do
            local e = r.h[i]
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:SetTall(24)
            row.Paint = function(_, w, h)
                draw.SimpleText(os.date("%d.%m. %H:%M", e.t), "GARLog_Tiny", 10, h / 2, C.muted, 0, 1)
                draw.SimpleText(UI.Truncate(e.x .. (e.b and ("  –  " .. e.b) or ""), "GARLog_Small", w - 110), "GARLog_Small", 96, h / 2, C.text, 0, 1)
            end
        end
    end

    local listSig
    RebuildList = function(force)
        local list = {}
        for _, r in ipairs(D().req or {}) do
            if ReqFilter(r, filter) then list[#list + 1] = r end
        end
        local s = filter .. Sig(list, function(r) return r.id .. ":" .. r.st .. ":" .. (r.u or 0) end)
        if s == listSig and not force then return end
        listSig = s
        listScroll:Clear()
        if #list == 0 then UI.Empty(listScroll, "Keine Anträge in dieser Ansicht.") end
        for _, r in ipairs(list) do
            Row(listScroll, 66, function(sb, w, h)
                local st = GARLog.ReqStatus[r.st]
                local p = GARLog.Prio[r.pr] or GARLog.Prio[2]
                RowBG(sb, w, h, selectedId == r.id, p.color)
                local nw = draw.SimpleText("#" .. r.id, "GARLog_Head", 12, 15, C.yellow, 0, 1)
                UI.Tag(p.name, 12 + nw + 8, 15, p.color)
                UI.Tag(st.name, w - 10, 15, st.color, nil, true)
                draw.SimpleText(UI.Truncate(string.upper(LocName(r.from)) .. "  «  " .. string.upper(LocName(r.src)), "GARLog_Small", w - 24), "GARLog_Small", 12, 36, C.white, 0, 1)
                draw.SimpleText(UI.Truncate(GARLog.ItemsText(r.it), "GARLog_Tiny", w - 130), "GARLog_Tiny", 12, 53, C.soft, 0, 1)
                draw.SimpleText(Ago(r.t), "GARLog_Tiny", w - 10, 53, C.muted, 2, 1)
            end, function()
                selectedId = r.id
                ShowDetail()
            end)
        end
        if selectedId and not FindReq(selectedId) then selectedId = nil end
        if not selectedId and list[1] then
            selectedId = list[1].id
            ShowDetail()
        end
    end

    RebuildList(true)
    ShowDetail()

    if ctx.loc and ctx.fromEntity then
        timer.Simple(0.05, function() Menu.RequestDialog({ from = ctx.loc }) end)
    end

    function self.Refresh(sec)
        if sec ~= "req" then return end
        RebuildList()
        local r = selectedId and FindReq(selectedId)
        local s = r and (r.id .. ":" .. r.st .. ":" .. (r.u or 0)) or ""
        if s ~= detailSig then ShowDetail() end
    end
    return self
end

---------------------------------------------------------------------------
-- Tab 4: Transporte
---------------------------------------------------------------------------
local function BuildTransports(parent)
    local self = {}

    local head = UI.Section(parent, "SHUTTLE-HANGAR")
    local newB = UI.Button(head, "+ SHUTTLE ENTSENDEN", function() Menu.ShuttleDialog() end)
    newB.Font = "GARLog_ButtonS"
    newB:Dock(RIGHT)
    newB:SetWide(180)
    newB:DockMargin(0, 1, 0, 1)
    newB:SetEnabled(Can("transport.create"))
    UI.Spacer(parent, 6)

    local hangar = vgui.Create("DPanel", parent)
    hangar:Dock(TOP)
    hangar:SetTall(92)
    hangar.Paint = nil
    local cards = {}
    for i = 1, cfg.Shuttle.Count do
        local card = vgui.Create("DPanel", hangar)
        card.Paint = function(_, w, h)
            local active = {}
            for _, t in ipairs((D().trn or {}).list or {}) do
                if t.st == GARLog.TRN_TRANSIT or t.st == GARLog.TRN_RETURN then active[#active + 1] = t end
            end
            table.sort(active, function(a, b) return a.id < b.id end)
            local t = active[i]
            surface.SetDrawColor(C.panel)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(C.line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            local st = t and GARLog.TrnStatus[t.st]
            surface.SetDrawColor(t and st.color or C.green)
            surface.DrawRect(0, 0, 2, h)
            draw.SimpleText("SHUTTLE " .. i, "GARLog_Head", 12, 16, C.white, 0, 1)
            if not t then
                UI.Tag("BEREIT", w - 10, 16, C.green, nil, true)
                draw.SimpleText("Im Hangar – bereit für den nächsten Einsatz.", "GARLog_Tiny", 12, 42, C.muted, 0, 1)
                return
            end
            UI.Tag((t.hold and t.st == GARLog.TRN_TRANSIT) and "KREIST – KEIN LEITSIGNAL" or st.name, w - 10, 16, t.hold and C.orange or st.color, nil, true)
            local route = t.st == GARLog.TRN_RETURN and (LocName(t.dst) .. " » " .. LocName(t.src)) or (LocName(t.src) .. " » " .. LocName(t.dst))
            draw.SimpleText(UI.Truncate(string.upper(route), "GARLog_Small", w - 24), "GARLog_Small", 12, 38, C.text, 0, 1)
            draw.SimpleText(UI.Truncate("T-" .. t.id .. "  //  " .. GARLog.ItemsText(t.st == GARLog.TRN_RETURN and (t.ov or {}) or t.it), "GARLog_Tiny", w - 24), "GARLog_Tiny", 12, 56, C.soft, 0, 1)
            local now = GARLog.Now()
            local s, e = t.dep, t.arr
            if t.st == GARLog.TRN_RETURN then s, e = t.arr, t.ret end
            local frac = math.Clamp((now - s) / math.max(1, e - s), 0, 1)
            UI.Bar(12, 70, w - 90, 8, frac, st.color)
            draw.SimpleText(GARLog.FmtTime(math.max(0, e - now)), "GARLog_Section", w - 10, 74, C.white, 2, 1)
        end
        cards[i] = card
    end
    hangar.PerformLayout = function(_, w, h)
        local n = #cards
        local cw = math.floor((w - (n - 1) * 8) / n)
        for i, c in ipairs(cards) do
            c:SetPos((i - 1) * (cw + 8), 0)
            c:SetSize(cw, h)
        end
    end

    UI.Spacer(parent, 10)
    local cols = vgui.Create("DPanel", parent)
    cols:Dock(FILL)
    cols.Paint = nil

    local right = vgui.Create("DPanel", cols)
    right:Dock(RIGHT)
    right:SetWide(400)
    right:DockMargin(16, 0, 0, 0)
    right.Paint = nil
    UI.Section(right, "VERLAUF")
    local histScroll = UI.Scroll(right)
    histScroll:Dock(FILL)

    local left = vgui.Create("DPanel", cols)
    left:Dock(FILL)
    left.Paint = nil
    UI.Section(left, "FRACHTCONTAINER IM EINSATZ")
    local contScroll = UI.Scroll(left)
    contScroll:Dock(FILL)

    local contSig, histSig
    local function Rebuild()
        local trn = D().trn or {}
        local s = Sig(trn.cont, function(c) return c.id .. GARLog.ItemsText(c.it) .. (c.at or "") end)
        if s ~= contSig then
            contSig = s
            contScroll:Clear()
            if #(trn.cont or {}) == 0 then UI.Empty(contScroll, "Keine Container im Umlauf.") end
            for _, c in ipairs(trn.cont or {}) do
                Row(contScroll, 62, function(sb, w, h)
                    RowBG(sb, w, h, false, C.yellow)
                    draw.SimpleText("C-" .. c.id, "GARLog_Head", 12, 16, C.yellow, 0, 1)
                    UI.Tag(string.upper(c.at or "?"), w - 10, 16, C.cyan, nil, true)
                    draw.SimpleText(UI.Truncate(GARLog.ItemsText(c.it), "GARLog_Small", w - 24), "GARLog_Small", 12, 36, C.white, 0, 1)
                    local sub = "AUS " .. string.upper(LocName(c.src)) .. "  //  GEPACKT VON " .. string.upper(c.by or "?")
                    if c.req then sub = sub .. "  //  ANTRAG #" .. c.req end
                    draw.SimpleText(UI.Truncate(sub, "GARLog_Tiny", w - 24), "GARLog_Tiny", 12, 52, C.soft, 0, 1)
                end)
            end
        end

        local hist = {}
        for _, t in ipairs(trn.list or {}) do if t.st == GARLog.TRN_DONE then hist[#hist + 1] = t end end
        local hs = Sig(hist, function(t) return t.id end)
        if hs ~= histSig then
            histSig = hs
            histScroll:Clear()
            if #hist == 0 then UI.Empty(histScroll, "Noch keine abgeschlossenen Flüge.") end
            for i = 1, math.min(#hist, 30) do
                local t = hist[i]
                Row(histScroll, 50, function(sb, w, h)
                    RowBG(sb, w, h, false, C.green)
                    draw.SimpleText("T-" .. t.id .. "  " .. UI.Truncate(string.upper(LocName(t.src) .. " » " .. LocName(t.dst)), "GARLog_Small", w - 90), "GARLog_Small", 12, 15, C.white, 0, 1)
                    draw.SimpleText(os.date("%H:%M", t.closed or t.arr), "GARLog_Tiny", w - 10, 15, C.muted, 2, 1)
                    local delivered = t.dl and next(t.dl) and GARLog.ItemsText(t.dl) or "NICHT ZUGESTELLT"
                    draw.SimpleText(UI.Truncate(delivered, "GARLog_Tiny", w - 24), "GARLog_Tiny", 12, 34, t.dl and next(t.dl) and C.soft or C.orange, 0, 1)
                end)
            end
        end
    end
    Rebuild()

    function self.Refresh(sec)
        if sec == "trn" then Rebuild() end
    end
    return self
end

---------------------------------------------------------------------------
-- Tab 5: Produktion
---------------------------------------------------------------------------
local LINE_STATE = {
    idle = { "LEERLAUF", C.muted },
    run  = { "PRODUZIERT", C.green },
    mat  = { "WARTET AUF ROHSTOFFE", C.orange },
    full = { "LAGER VOLL", C.red },
}

local function BuildProduction(parent)
    local self = {}
    local canProd = Can("production")

    -- Rechts: neuer Auftrag
    local right = vgui.Create("DPanel", parent)
    right:Dock(RIGHT)
    right:SetWide(360)
    right:DockMargin(16, 0, 0, 0)
    right.Paint = nil

    UI.Section(right, "NEUER PRODUKTIONSAUFTRAG")
    local res, batches, line = GARLog.ResOrder[1], 1, 0
    local grid = vgui.Create("DPanel", right)
    grid:Dock(TOP)
    grid.Paint = nil
    local btns = {}
    for _, id in ipairs(GARLog.ResOrder) do
        local rec = cfg.Production.Recipes[id]
        if rec then
            local r = GARLog.Res[id]
            local b = UI.Button(grid, r.name:upper(), function()
                res = id
                for k, o in pairs(btns) do o.Active = k == id end
            end)
            b.Font = "GARLog_ButtonS"
            b.Accent = r.color
            b.Sub = GARLog.FmtNum(rec.batch) .. " / " .. GARLog.FmtTime(rec.time)
            b.Active = id == res
            btns[id] = b
        end
    end
    local order = {}
    for _, id in ipairs(GARLog.ResOrder) do if btns[id] then order[#order + 1] = btns[id] end end
    grid:SetTall(math.ceil(#order / 2) * 52)
    grid.PerformLayout = function(_, w)
        local bw = math.floor((w - 6) / 2)
        for i, b in ipairs(order) do
            local c, r = (i - 1) % 2, math.floor((i - 1) / 2)
            b:SetPos(c * (bw + 6), r * 52)
            b:SetSize(bw, 46)
        end
    end

    UI.Spacer(right, 8)
    UI.Section(right, "CHARGEN")
    local bRow = vgui.Create("DPanel", right)
    bRow:Dock(TOP)
    bRow:SetTall(38)
    bRow.Paint = function(_, w, h)
        draw.SimpleText(batches .. "x", "GARLog_Big", w / 2, h / 2, C.white, 1, 1)
    end
    local minus = UI.Button(bRow, "-", function() batches = math.max(1, batches - 1) end)
    minus:Dock(LEFT)
    minus:SetWide(60)
    local plus = UI.Button(bRow, "+", function() batches = math.min(cfg.Production.MaxBatches, batches + 1) end)
    plus:Dock(RIGHT)
    plus:SetWide(60)

    UI.Spacer(right, 8)
    UI.Section(right, "PRODUKTIONSLINIE")
    local lineOpts = { { "AUTOMATISCH (KÜRZESTE WARTESCHLANGE)", 0 } }
    for i = 1, cfg.Production.Lines do lineOpts[#lineOpts + 1] = { "LINIE " .. i, i } end
    local lineCombo = UI.Combo(right, lineOpts, 0, function(v) line = v end)
    lineCombo:Dock(TOP)
    lineCombo:SetTall(34)

    local summary = vgui.Create("DPanel", right)
    summary:Dock(TOP)
    summary:SetTall(64)
    summary:DockMargin(0, 8, 0, 0)
    summary.Paint = function(_, w, h)
        local rec = cfg.Production.Recipes[res]
        if not rec then return end
        draw.SimpleText("ERGEBNIS", "GARLog_Tiny", 0, 10, C.muted, 0, 1)
        draw.SimpleText(GARLog.FmtNum(rec.batch * batches) .. " " .. GARLog.Res[res].short .. "  //  " .. GARLog.FmtTime(rec.time * batches), "GARLog_Small", 0, 26, C.white, 0, 1)
        local cost = {}
        for k, v in pairs(rec.cost or {}) do cost[k] = v * batches end
        draw.SimpleText("ROHSTOFFE", "GARLog_Tiny", 0, 44, C.muted, 0, 1)
        draw.SimpleText(next(cost) and GARLog.ItemsText(cost) or "KEINE", "GARLog_Small", 0, 58, C.text, 0, 1)
    end

    local go = UI.Button(right, "AUFTRAG ERTEILEN", function()
        GARLog.Action("prd.add", { res = res, n = batches, line = line })
    end)
    go.Solid = true
    go:Dock(TOP)
    go:SetTall(44)
    go:DockMargin(0, 10, 0, 0)
    go:SetEnabled(canProd)

    local passive = vgui.Create("DPanel", right)
    passive:Dock(FILL)
    passive:DockMargin(0, 14, 0, 0)
    passive.Paint = function(_, w, h)
        local p = cfg.Production.Passive
        if not p or not p.Interval or p.Interval <= 0 then return end
        surface.SetDrawColor(C.yellow)
        surface.DrawRect(0, 8, 2, 12)
        draw.SimpleText("GRUNDVERSORGUNG", "GARLog_Section", 10, 14, C.soft, 0, 1)
        local last = (D().prd or {}).last or 0
        local remain = math.max(0, last + p.Interval - GARLog.Now())
        draw.SimpleText("NÄCHSTE LIEFERUNG IN " .. GARLog.FmtTime(remain), "GARLog_Small", 0, 40, C.white, 0, 1)
        UI.Bar(0, 54, w, 6, 1 - remain / p.Interval, C.yellow)
        local y = 76
        for _, id in ipairs(GARLog.ResOrder) do
            local n = (p.Amounts or {})[id]
            if n and n > 0 then
                draw.SimpleText("+" .. GARLog.FmtNum(n) .. " " .. GARLog.Res[id].name, "GARLog_Tiny", 0, y, C.soft, 0, 1)
                y = y + 16
            end
        end
    end

    -- Links: Produktionslinien
    local left = vgui.Create("DPanel", parent)
    left:Dock(FILL)
    left.Paint = nil
    UI.Section(left, "PRODUKTIONSLINIEN – " .. string.upper(LocName(cfg.Production.Location)))
    local scroll = UI.Scroll(left)
    scroll:Dock(FILL)

    local sig
    local function Rebuild()
        local lines = (D().prd or {}).lines or {}
        local s = Sig(lines, function(l) return Sig(l.orders, function(o) return o.id .. ":" .. o.d end) end)
        if s == sig then return end
        sig = s
        scroll:Clear()
        for li = 1, cfg.Production.Lines do
            local lineIdx = li
            local card = vgui.Create("DPanel", scroll)
            card:Dock(TOP)
            card:DockMargin(0, 0, 6, 8)
            local l = lines[li] or { orders = {} }
            local queued = math.max(0, #(l.orders or {}) - 1)
            card:SetTall(96 + queued * 30)
            card.Paint = function(_, w, h)
                local cur = ((D().prd or {}).lines or {})[lineIdx] or { orders = {} }
                local st = LINE_STATE[cur.st or "idle"] or LINE_STATE.idle
                surface.SetDrawColor(C.panel)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(C.line)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
                surface.SetDrawColor(st[2])
                surface.DrawRect(0, 0, 2, h)
                draw.SimpleText("LINIE " .. lineIdx, "GARLog_Head", 12, 16, C.white, 0, 1)
                UI.Tag(st[1], w - 10, 16, st[2], nil, true)
                local o = (cur.orders or {})[1]
                if not o then
                    draw.SimpleText("Keine Aufträge.", "GARLog_Small", 12, 48, C.muted, 0, 1)
                    return
                end
                local rec = cfg.Production.Recipes[o.res] or { batch = 0, time = 1 }
                local r = GARLog.Res[o.res]
                draw.SimpleText(string.format("P-%d  //  %s  //  CHARGE %d / %d", o.id, string.upper(r and r.name or o.res), math.min(o.d + 1, o.n), o.n), "GARLog_Small", 12, 42, C.text, 0, 1)
                draw.SimpleText("VON " .. string.upper(o.by or "?"), "GARLog_Tiny", w - 44, 42, C.muted, 2, 1)
                local frac, remain = 0, rec.time
                if o.e then
                    local now = GARLog.Now()
                    frac = math.Clamp((now - (o.s or now)) / math.max(1, o.e - (o.s or now)), 0, 1)
                    remain = math.max(0, o.e - now)
                end
                UI.Bar(12, 58, w - 100, 8, frac, r and r.color or C.yellow)
                draw.SimpleText(GARLog.FmtTime(remain), "GARLog_Section", w - 10, 62, C.white, 2, 1)
            end

            -- Warteschlange inkl. laufendem Auftrag (stornierbar)
            local cancelHead = UI.Button(card, "X", function()
                local o = (l.orders or {})[1]
                if o then GARLog.Action("prd.cancel", { line = lineIdx, id = o.id }) end
            end)
            cancelHead.Accent = C.red
            cancelHead.Font = "GARLog_ButtonS"
            cancelHead:SetSize(26, 22)
            cancelHead:SetVisible(canProd and (l.orders or {})[1] ~= nil)
            cancelHead:SetTooltip("Laufenden Auftrag stornieren (Rohstoffe der Charge zurück)")
            card.PerformLayout = function(s, w)
                cancelHead:SetPos(w - 36, 31)
            end

            for qi = 2, #(l.orders or {}) do
                local q = l.orders[qi]
                local qr = vgui.Create("DPanel", card)
                qr:SetPos(12, 84 + (qi - 2) * 30)
                qr:SetSize(10, 26)
                qr.Paint = function(_, w, h)
                    surface.SetDrawColor(C.panel2)
                    surface.DrawRect(0, 0, w, h)
                    local rec = cfg.Production.Recipes[q.res] or { batch = 0 }
                    draw.SimpleText(string.format("P-%d   %dx %s %s", q.id, q.n, GARLog.FmtNum(rec.batch), GARLog.Res[q.res] and GARLog.Res[q.res].name or q.res), "GARLog_Small", 8, h / 2, C.soft, 0, 1)
                end
                local x = UI.Button(qr, "X", function() GARLog.Action("prd.cancel", { line = lineIdx, id = q.id }) end)
                x.Accent = C.red
                x.Font = "GARLog_ButtonS"
                x:Dock(RIGHT)
                x:SetWide(26)
                x:SetVisible(canProd)
                local basePL = card.PerformLayout
                card.PerformLayout = function(s, w, h)
                    basePL(s, w, h)
                    qr:SetWide(w - 24)
                end
            end
        end
    end
    Rebuild()

    function self.Refresh(sec)
        if sec == "prd" then Rebuild() end
    end
    return self
end

---------------------------------------------------------------------------
-- Tab 7: Protokoll
---------------------------------------------------------------------------
local function BuildLog(parent)
    local self = {}
    UI.Section(parent, "LOGISTIK-PROTOKOLL")
    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)
    local sig
    local function Rebuild()
        local log = D().log or {}
        local s = (log[1] and (log[1].t .. log[1].x) or "") .. #log
        if s == sig then return end
        sig = s
        scroll:Clear()
        if #log == 0 then UI.Empty(scroll, "Protokoll ist leer.") end
        for _, e in ipairs(log) do
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:SetTall(28)
            row:DockMargin(0, 0, 6, 2)
            row.Paint = function(_, w, h)
                surface.SetDrawColor(C.panel)
                surface.DrawRect(0, 0, w, h)
                local col = GARLog.LogKindColor[e.k] or C.text
                surface.SetDrawColor(col)
                surface.DrawRect(0, 0, 2, h)
                draw.SimpleText(os.date("%d.%m. %H:%M", e.t), "GARLog_Tiny", 12, h / 2, C.muted, 0, 1)
                draw.SimpleText(UI.Truncate(e.x, "GARLog_Small", w - 120), "GARLog_Small", 104, h / 2, col, 0, 1)
            end
            row:SetTooltip(e.x)
        end
    end
    Rebuild()
    function self.Refresh(sec)
        if sec == "log" then Rebuild() end
    end
    return self
end

---------------------------------------------------------------------------
-- Hauptfenster
---------------------------------------------------------------------------
-- Rollen einmalig alphabetisch sortieren (nicht in jedem Frame)
Menu.RoleOrder = {}
for id in pairs(cfg.Roles) do Menu.RoleOrder[#Menu.RoleOrder + 1] = id end
table.sort(Menu.RoleOrder, function(a, b) return cfg.Roles[a].name < cfg.Roles[b].name end)

-- Apps des Datapads: 1 = Logistik, 2 = Feldbasis (cl_builder.lua), 3 = Technik (cl_tech.lua)
Menu.APP_LOGISTIK, Menu.APP_FELDBASIS, Menu.APP_TECHNIK = 1, 2, 3
Menu.Apps = Menu.Apps or {}

-- def = { label, title, sub, status = fn() -> text, col, tabs = { { label, sub, build, badge = fn() } } }
function Menu.RegisterApp(id, def)
    Menu.Apps[id] = def
end

Menu.RegisterApp(Menu.APP_LOGISTIK, {
    label = "LOGISTIK", title = "GAR LOGISTIKKOMMANDO", sub = "DATAPAD // KRIEGSLOGISTIK",
    tabs = {
        { label = "LAGE",       sub = "Übersicht & Warnungen", build = BuildDashboard },
        { label = "LAGER",      sub = "Standorte & Bestände",  build = BuildLocations },
        { label = "ANTRÄGE",    sub = "Versorgungsanträge",    build = BuildRequests, badge = function()
            local s, n = Menu.Stats(), 0
            if Can("request.approve") then n = n + s.open end
            if Can("request.plan") then n = n + s.approved end
            return n, s.crit > 0 and C.red or C.yellow
        end },
        { label = "TRANSPORTE", sub = "Shuttles & Container",  build = BuildTransports, badge = function()
            local s = Menu.Stats()
            return s.busy + s.cont, C.cyan
        end },
        { label = "PRODUKTION", sub = "Zentrallager",          build = BuildProduction },
        { label = "PROTOKOLL",  sub = "Ereignisse",            build = BuildLog },
    },
})

-- Öffnet das Datapad in einer App / einem Tab. fromEntity = über eine Struktur / ein Terminal geöffnet
function GARLog.OpenMenu(tab, locId, app, fromEntity)
    app = Menu.Apps[app or 1] and (app or 1) or 1
    local def = Menu.Apps[app]
    tab = math.Clamp(tab or 1, 1, #def.tabs)
    if fromEntity == nil then fromEntity = locId ~= nil end
    if IsValid(Menu.Frame) then
        Menu.Frame:ShowApp(app, tab, locId, fromEntity)
        return
    end

    local f = UI.Frame(def.title, def.sub, 1240, 760, function()
        if #(D().loc or {}) == 0 then return "VERBINDE...", C.yellow end
        local cur = Menu.Apps[Menu.Frame and Menu.Frame.App or 1]
        if cur and cur.status then return cur.status() end
        return "VERBINDUNG STABIL", C.green
    end)
    Menu.Frame = f
    GARLog.SetSubscribed("ui", true)
    f.OnRemoved = function()
        GARLog.SetSubscribed("ui", false)
        Menu.Current = nil
    end

    -- App-Umschalter oben rechts (neben Schließen)
    local appBtns = {}
    local order = {}
    for id in SortedPairs(Menu.Apps) do order[#order + 1] = id end
    local bx = f:GetWide() - 48 - 10 - #order * 126 + 6
    for i, id in ipairs(order) do
        local b = UI.Button(f, Menu.Apps[id].label, function() f:ShowApp(id, 1) end)
        b:SetSize(120, 34)
        b:SetPos(bx + (i - 1) * 126, 14)
        appBtns[id] = b
    end

    local side = vgui.Create("DPanel", f)
    side:Dock(LEFT)
    side:SetWide(196)
    side.Paint = nil

    local content = vgui.Create("DPanel", f)
    content:Dock(FILL)
    content:DockMargin(18, 0, 0, 0)
    content.Paint = nil

    local info = vgui.Create("DPanel", side)
    info:Dock(BOTTOM)
    info:SetTall(92)
    info.Paint = function(_, w, h)
        local lp = LocalPlayer()
        surface.SetDrawColor(C.line)
        surface.DrawRect(0, 0, w, 1)
        draw.SimpleText(UI.Truncate(string.upper(lp:Nick()), "GARLog_ButtonS", w), "GARLog_ButtonS", 0, 18, C.white, 0, 1)
        local here = GARLog.FOBAtPos(lp:GetPos())
        draw.SimpleText(here and ("IN " .. string.upper(here.name)) or "KEINE FELDBASIS", "GARLog_Tiny", 0, 36, here and C.yellow or C.muted, 0, 1)
        local x, y = 0, 58
        if GARLog.IsAdmin(lp) then x = x + UI.Tag("ADMIN", x, y, C.red) + 4 end
        local roles = GARLog.GetRoles(lp)
        for _, id in ipairs(Menu.RoleOrder) do
            local r = cfg.Roles[id]
            if roles[id] then
                surface.SetFont("GARLog_Tiny")
                if x + surface.GetTextSize(r.name) + 16 > w then x, y = 0, y + 20 end
                x = x + UI.Tag(string.upper(r.name), x, y, r.color) + 4
            end
        end
    end

    local tabBtns = {}
    function f:ShowApp(id, tabIdx, loc, fromEnt)
        local a = Menu.Apps[id]
        if not a then return end
        if self.App ~= id then
            self.App = id
            self.TitleText, self.SubText = a.title, a.sub
            for k, b in pairs(appBtns) do b.Active = k == id end
            for _, b in ipairs(tabBtns) do b:Remove() end
            tabBtns = {}
            for i, t in ipairs(a.tabs) do
                local b = UI.Button(side, t.label, function() f:ShowTab(i) end)
                b.Sub = string.upper(t.sub)
                b.AlignLeft = true
                b.SideMark = true
                b:Dock(TOP)
                b:SetTall(50)
                b:DockMargin(0, 0, 0, 6)
                if t.badge then
                    local basePaint = b.Paint
                    b.Paint = function(s, w, h)
                        s.Badge, s.BadgeColor = t.badge()
                        basePaint(s, w, h)
                    end
                end
                tabBtns[i] = b
            end
        end
        self:ShowTab(math.Clamp(tabIdx or 1, 1, #a.tabs), loc, fromEnt)
    end

    function f:ShowTab(i, locId, fromEntity)
        local a = Menu.Apps[self.App]
        self.Tab = i
        for k, b in ipairs(tabBtns) do b.Active = k == i end
        content:Clear()
        Menu.Current = a.tabs[i].build(content, { loc = locId, fromEntity = fromEntity })
    end

    f:ShowApp(app, tab, locId, fromEntity)
end

hook.Add("GARLog_Data", "GARLog_Menu", function(sec)
    if not IsValid(Menu.Frame) then return end
    local cur = Menu.Current
    if cur and cur.Refresh then cur.Refresh(sec) end
end)

concommand.Add("garlog_menu", function() GARLog.OpenMenu(1, nil, 1) end)
concommand.Add("garlog_technik", function() GARLog.OpenMenu(1, nil, 3) end)
concommand.Add("garlog_bau", function() GARLog.OpenMenu(1, nil, 2) end)

-- Bausteine für die anderen Apps (cl_builder.lua, cl_tech.lua)
Menu.Kit = {
    Row = Row, RowBG = RowBG, ActionBar = ActionBar, Sig = Sig, Ago = Ago, TypeColor = TypeColor,
    PrioButtons = PrioButtons, DialogFooter = DialogFooter, TwoCols = TwoCols,
}
Menu.BuildLocations = BuildLocations

---------------------------------------------------------------------------
-- Frachtcontainer (E auf Container)
---------------------------------------------------------------------------
function GARLog.OpenContainer(ent)
    if IsValid(Menu.ContainerFrame) then Menu.ContainerFrame:Close() end
    local d = UI.Frame("FRACHTCONTAINER C-" .. ent:GetContainerID(), "FRACHT // " .. string.upper(ent:GetSrcName()), 520, 470)
    d:DockPadding(18, 78, 18, 18)
    Menu.ContainerFrame = d

    local info = UI.Framed(d)
    info:Dock(TOP)
    info:SetTall(70)
    local base = info.Paint
    info.Paint = function(s, w, h)
        base(s, w, h)
        if not IsValid(ent) then return end
        draw.SimpleText("HERKUNFT", "GARLog_Tiny", 12, 14, C.muted, 0, 1)
        draw.SimpleText(string.upper(ent:GetSrcName()), "GARLog_Small", 12, 30, C.white, 0, 1)
        draw.SimpleText("ZIEL", "GARLog_Tiny", w / 2, 14, C.muted, 0, 1)
        draw.SimpleText(ent:GetDestName() ~= "" and string.upper(ent:GetDestName()) or "FREIE LIEFERUNG", "GARLog_Small", w / 2, 30, C.yellow, 0, 1)
        local vol = ent:GetVolume()
        draw.SimpleText(GARLog.FmtNum(vol) .. " / " .. GARLog.FmtNum(cfg.Container.Capacity) .. " FE", "GARLog_Tiny", 12, 52, C.soft, 0, 1)
        UI.Bar(120, 49, w - 132, 6, vol / math.max(1, cfg.Container.Capacity), C.yellow)
    end

    UI.Spacer(d, 8)
    UI.Section(d, "INHALT")
    local list = vgui.Create("DPanel", d)
    list:Dock(FILL)
    list.Paint = function(_, w, h)
        if not IsValid(ent) then return end
        local y = 0
        for part in string.gmatch(ent:GetSummary(), "[^·]+") do
            part = string.Trim(part)
            local amount, short = part:match("^([%d%.]+)%s+(%a+)$")
            local res
            for _, r in ipairs(cfg.Resources) do if r.short == short then res = r end end
            surface.SetDrawColor(C.panel)
            surface.DrawRect(0, y, w, 30)
            surface.SetDrawColor(res and res.color or C.soft)
            surface.DrawRect(0, y, 2, 30)
            draw.SimpleText(res and res.name:upper() or part, "GARLog_ButtonS", 12, y + 15, C.white, 0, 1)
            draw.SimpleText(amount or "", "GARLog_Head", w - 12, y + 15, C.white, 2, 1)
            y = y + 34
        end
    end

    local hint = UI.Label(d, "Transport: LAAT / Fahrzeug neben den Container stellen und ankoppeln. Entladen: in die Nähe eines Versorgungslagers, einer Frachtrampe oder eines Terminals bringen (max. " .. math.floor(cfg.Container.UnloadRange * 0.01905) .. " m).", "GARLog_Small", C.muted)
    hint:Dock(BOTTOM)
    hint:DockMargin(0, 8, 0, 0)

    local btnRow = vgui.Create("DPanel", d)
    btnRow:Dock(BOTTOM)
    btnRow:SetTall(46)
    btnRow.Paint = nil

    local unload = UI.Button(btnRow, "ENTLADEN", function()
        if IsValid(ent) then GARLog.Action("cnt.unload", { ent = ent:EntIndex() }) end
        d:Close()
    end)
    unload.Solid = true
    unload:SetEnabled(GARLog.LocalCan("container.unload"))
    if not GARLog.LocalCan("container.unload") then unload.Label = "KEINE BERECHTIGUNG" end

    local attach = UI.Button(btnRow, "", function()
        if not IsValid(ent) then return end
        GARLog.Action(ent:GetAttached() and "cnt.detach" or "cnt.attach", { ent = ent:EntIndex() })
        d:Close()
    end)
    attach.Accent = C.cyan
    attach:SetEnabled(GARLog.LocalCan("container.move"))
    attach.Think = function(s)
        s.Label = (IsValid(ent) and ent:GetAttached()) and "VOM FAHRZEUG ABKOPPELN" or "AN FAHRZEUG KOPPELN"
    end

    btnRow.PerformLayout = function(_, w, h)
        local half = math.floor((w - 8) / 2)
        attach:SetPos(0, 0) attach:SetSize(half, h)
        unload:SetPos(w - half, 0) unload:SetSize(half, h)
    end

    d.Think = function(s)
        if not IsValid(ent) or LocalPlayer():GetPos():DistToSqr(ent:GetPos()) > 400 * 400 then s:Close() end
    end
end
