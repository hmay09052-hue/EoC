-- Technik-Kontrollterminal (Datapad, Taste R):
-- Kontrollzentrum, Reparaturaufträge, Wartungsberichte, Schiffe & Fahrzeuge

local cfg = GARLog.Config
local UI = GARLog.UI
local C = UI.C
local Menu = GARLog.Menu
local K = Menu.Kit
local Row, RowBG, ActionBar, Sig, Ago = K.Row, K.RowBG, K.ActionBar, K.Sig, K.Ago
local PrioButtons, DialogFooter, TwoCols = K.PrioButtons, K.DialogFooter, K.TwoCols
local RCFG = cfg.Reports

local REP_OPEN, REP_ASSIGNED = GARLog.REP_OPEN, GARLog.REP_ASSIGNED

local Tech = GARLog.Tech or {}
GARLog.Tech = Tech

local function D() return GARLog.Data end
local function Can(perm) return GARLog.LocalCan(perm) end
local function LocName(id) return GARLog.LocLabel(id) end
local function MySid() return LocalPlayer():SteamID() end

local function StateDef(st) return RCFG.States[st or 1] or RCFG.States[1] end

local function IntegrityStyle(frac, destroyed)
    if destroyed or frac <= 0 then return "ZERSTÖRT", C.red end
    if frac < 0.35 then return "KRITISCH", C.red end
    if frac < 0.75 then return "BESCHÄDIGT", C.orange end
    if frac < 1 then return "LEICHT BESCHÄDIGT", C.yellow end
    return "INTAKT", C.green
end

-- Schadenslage: beschädigte Strukturen (Feldbasen) + Schiffe & Fahrzeuge
function Tech.DamageList()
    local list = {}
    for _, l in ipairs(D().loc or {}) do
        for _, e in ipairs(l.f and l.f.st or {}) do
            if e.hp and (e.hp < 1 or e.d) then
                local def = GARLog.BuildDefs[e.k]
                list[#list + 1] = {
                    kind = "structure", key = "s" .. e.i, ent = e.i, frac = e.d and 0 or e.hp, d = e.d,
                    name = def and def.name or e.k, where = l.n, loc = l.id,
                    pos = Vector(l.f.x, l.f.y, l.f.z),
                }
            end
        end
    end
    for _, v in ipairs(D().veh or {}) do
        if v.mx > 0 and v.hp < v.mx then
            list[#list + 1] = {
                kind = "vehicle", key = "v" .. v.i, ent = v.i, frac = v.hp / v.mx, name = v.n, where = v.at,
                cls = v.c, fcr = v.fcr,
            }
        end
    end
    table.sort(list, function(a, b) return a.frac < b.frac end)
    return list
end

local function LocFromWhere(entry)
    if entry.loc then return entry.loc end
    local ent = Entity(entry.ent or 0)
    if IsValid(ent) then
        local f = GARLog.FOBAtPos(ent:GetPos())
        if f then return "fob_" .. f.id end
    end
    return GARLog.Loc(cfg.DefaultShip) and cfg.DefaultShip or nil
end

local function MarkButton(parent, entry)
    local b = UI.Button(parent, "", function()
        local ent = Entity(entry.ent or 0)
        local on = GARLog.ToggleMark(entry.key, entry.name, entry.ent, IsValid(ent) and ent:WorldSpaceCenter() or entry.pos)
        if on then chat.AddText(C.yellow, cfg.ChatTag .. " ", C.white, entry.name .. " im HUD markiert.") end
    end)
    b.Font = "GARLog_ButtonS"
    b.Accent = C.yellow
    b.Think = function(s)
        s.Label = GARLog.IsMarked(entry.key) and "MARKIERT" or "MARKIEREN"
        s.Active = GARLog.IsMarked(entry.key)
    end
    return b
end

---------------------------------------------------------------------------
-- Wartungsbericht erstellen / bearbeiten
-- opts: cat, obj, loc, veh, rep, st, fd, ms, edit (vollständiger Bericht)
---------------------------------------------------------------------------
function Tech.ReportDialog(opts)
    opts = opts or {}
    local edit = opts.edit
    if not edit and not Can("report.create") then
        chat.AddText(C.yellow, cfg.ChatTag .. " ", C.red, "Keine Berechtigung, Wartungsberichte zu erstellen.")
        UI.ErrorSound()
        return
    end
    local cat = edit and edit.cat or opts.cat or "vehicle"
    local st = edit and edit.st or opts.st or 1
    local loc = edit and edit.loc or opts.loc or ""
    local rep = opts.rep

    local d = UI.Dialog(edit and ("BERICHT W-" .. edit.id .. " BEARBEITEN") or "WARTUNGSBERICHT",
        edit and "TECHNIK // ÄNDERUNG" or "TECHNIK // NEUER BERICHT", 760, 800)

    local cols = TwoCols(d, 64)
    UI.Section(cols.L, "KATEGORIE")
    UI.Section(cols.R, "STANDORT")
    local catOpts = {}
    for _, c in ipairs(RCFG.Categories) do catOpts[#catOpts + 1] = { string.upper(c.name), c.id } end
    local catCombo = UI.Combo(cols.L, catOpts, cat, function(v) cat = v end)
    catCombo:Dock(TOP)
    catCombo:SetTall(34)
    local locOpts = { { "— KEIN STANDORT —", "" } }
    for _, l in ipairs(D().loc or {}) do locOpts[#locOpts + 1] = { l.n, l.id } end
    local locCombo = UI.Combo(cols.R, locOpts, loc, function(v) loc = v end)
    locCombo:Dock(TOP)
    locCombo:SetTall(34)
    locCombo:SetEnabled(not edit)

    UI.Spacer(d, 8)
    UI.Section(d, "BETROFFENES OBJEKT")
    local obj = UI.Entry(d, "z.B. LAAT/i 'Sturmvogel', Generator FOB Aurek, Hyperantrieb ...")
    obj:Dock(TOP)
    obj:SetTall(34)
    obj:SetText(edit and edit.obj or opts.obj or "")
    obj.AllowInput = function(s) return (utf8.len(s:GetText()) or 0) >= RCFG.TitleLength end

    UI.Spacer(d, 8)
    UI.Section(d, "ZUSTAND")
    local stRow = vgui.Create("DPanel", d)
    stRow:Dock(TOP)
    stRow:SetTall(38)
    stRow.Paint = nil
    local stBtns = {}
    for i, s in ipairs(RCFG.States) do
        local b = UI.Button(stRow, s.name, function()
            st = i
            for j, o in ipairs(stBtns) do o.Active = j == i end
        end)
        b.Font = "GARLog_ButtonS"
        b.Accent = s.color
        b.Active = i == st
        stBtns[i] = b
    end
    stRow.PerformLayout = function(_, w, h)
        local n = #stBtns
        local bw = math.floor((w - (n - 1) * 6) / n)
        for i, b in ipairs(stBtns) do
            b:SetPos((i - 1) * (bw + 6), 0)
            b:SetSize(bw, h)
        end
    end

    UI.Spacer(d, 8)
    UI.Section(d, "BEFUND")
    local fd = UI.Entry(d, "Was wurde festgestellt? (Schäden, Messwerte, Ursache ...)", true)
    fd:Dock(TOP)
    fd:SetTall(130)
    fd:SetText(edit and edit.fd or opts.fd or "")
    fd.AllowInput = function(s) return (utf8.len(s:GetText()) or 0) >= RCFG.TextLength end

    UI.Spacer(d, 8)
    UI.Section(d, "MASSNAHMEN")
    local ms = UI.Entry(d, "Was wurde getan / was ist noch zu tun?", true)
    ms:Dock(TOP)
    ms:SetTall(130)
    ms:SetText(edit and edit.ms or opts.ms or "")
    ms.AllowInput = function(s) return (utf8.len(s:GetText()) or 0) >= RCFG.TextLength end

    local parts
    if not edit then
        UI.Spacer(d, 8)
        local pc = TwoCols(d, 64)
        UI.Section(pc.L, "VERBRAUCHTE ERSATZTEILE (TEC)")
        UI.Section(pc.R, "VERKNÜPFTER AUFTRAG")
        parts = UI.Entry(pc.L, "0 – wird vom Standort-Lager abgebucht")
        parts:SetNumeric(true)
        parts:Dock(TOP)
        parts:SetTall(34)
        local repOpts = { { "— KEINER —", 0 } }
        for _, o in ipairs(D().rep or {}) do
            if o.st <= REP_ASSIGNED then repOpts[#repOpts + 1] = { "R-" .. o.id .. "  " .. (o.title or ""), o.id } end
        end
        local repCombo = UI.Combo(pc.R, repOpts, rep or 0, function(v) rep = v ~= 0 and v or nil end)
        repCombo:Dock(TOP)
        repCombo:SetTall(34)
    end

    DialogFooter(d, edit and "ÄNDERUNG SPEICHERN" or "BERICHT SPEICHERN", function()
        if string.Trim(obj:GetText()) == "" or (string.Trim(fd:GetText()) == "" and string.Trim(ms:GetText()) == "") then
            UI.ErrorSound()
            return
        end
        if edit then
            GARLog.Action("rpt.edit", { id = edit.id, cat = cat, obj = obj:GetText(), st = st, fd = fd:GetText(), ms = ms:GetText() })
        else
            GARLog.Action("rpt.create", {
                cat = cat, obj = obj:GetText(), loc = loc, st = st, fd = fd:GetText(), ms = ms:GetText(),
                parts = tonumber(parts:GetText()) or 0, rep = rep, veh = opts.veh,
            })
            Tech.PendingSelect = CurTime() + 5   -- neuen Bericht nach dem Speichern direkt anzeigen
        end
        d:Close()
    end)
    timer.Simple(0, function() if IsValid(obj) and obj:GetText() == "" then obj:RequestFocus() end end)
end

---------------------------------------------------------------------------
-- Tab 1: Kontrollzentrum
---------------------------------------------------------------------------
local function BuildHome(parent)
    local self = {}

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

    local cacheSig, cache
    local function Stats()
        local dv = GARLog.DataVer
        local s = (dv.loc or 0) .. ":" .. (dv.veh or 0) .. ":" .. (dv.rpt or 0)
        if s == cacheSig then return cache end
        cacheSig = s
        local c = { structs = 0, crit = 0, vehs = 0, rpt = 0 }
        for _, e in ipairs(Tech.DamageList()) do
            if e.kind == "structure" then c.structs = c.structs + 1 else c.vehs = c.vehs + 1 end
            if e.frac < 0.35 then c.crit = c.crit + 1 end
        end
        local since = GARLog.Now() - 86400
        for _, r in ipairs(D().rpt or {}) do if r.t >= since then c.rpt = c.rpt + 1 end end
        cache = c
        return c
    end

    Tile("OFFENE AUFTRÄGE", function() local s = Menu.Stats() return tostring(s.repOpen), s.repOpen > 0 and C.orange or C.soft end)
    Tile("MEINE AUFTRÄGE", function() local s = Menu.Stats() return tostring(s.mine), s.mine > 0 and C.cyan or C.soft end)
    Tile("STRUKTUREN BESCHÄDIGT", function() local s = Stats() return tostring(s.structs), s.structs > 0 and C.orange or C.green end)
    Tile("SCHIFFE / FAHRZEUGE", function() local s = Stats() return tostring(s.vehs), s.vehs > 0 and C.orange or C.green, "BESCHÄDIGT" end)
    Tile("KRITISCH", function() local s = Stats() return tostring(s.crit), s.crit > 0 and C.red or C.soft end)
    Tile("BERICHTE 24 H", function() local s = Stats() return tostring(s.rpt), C.text end)
    kpi.PerformLayout = function(_, w, h)
        local n = #tiles
        local tw = math.floor((w - (n - 1) * 8) / n)
        for i, t in ipairs(tiles) do
            t:SetPos((i - 1) * (tw + 8), 0)
            t:SetSize(tw, h)
        end
    end

    -- Rechte Spalte: meine Aufträge & letzte Berichte
    local right = vgui.Create("DPanel", parent)
    right:Dock(RIGHT)
    right:SetWide(340)
    right:DockMargin(16, 0, 0, 0)
    right.Paint = nil

    local rptWrap = vgui.Create("DPanel", right)
    rptWrap:Dock(BOTTOM)
    rptWrap:SetTall(26 + 5 * 52)
    rptWrap:DockMargin(0, 10, 0, 0)
    rptWrap.Paint = nil
    UI.Section(rptWrap, "LETZTE WARTUNGSBERICHTE")
    local rptBox = vgui.Create("DPanel", rptWrap)
    rptBox:Dock(FILL)
    rptBox.Paint = nil
    UI.Section(right, "MEINE AUFTRÄGE")
    local mineScroll = UI.Scroll(right)
    mineScroll:Dock(FILL)

    -- Links: Schadenslage
    local left = vgui.Create("DPanel", parent)
    left:Dock(FILL)
    left.Paint = nil
    local head = UI.Section(left, "SCHADENSLAGE – STRUKTUREN, SCHIFFE & FAHRZEUGE")
    local hint = UI.Label(left, "Reparieren: Datapad auf das Ziel richten. Strukturen: LMB halten. Schiffe & Fahrzeuge: LMB startet das Fusion-Cutter-Protokoll (Ersatzteile aus dem nächsten Lager).", "GARLog_Small", C.muted)
    hint:Dock(BOTTOM)
    hint:DockMargin(0, 8, 0, 0)
    local dmgScroll = UI.Scroll(left)
    dmgScroll:Dock(FILL)

    -- Zeilen nur neu bauen, wenn Einträge dazukommen/wegfallen; Zustand wird live gezeichnet
    local dmgSig
    local live = {}
    local function RebuildDamage()
        local list = Tech.DamageList()
        live = {}
        for _, e in ipairs(list) do live[e.key] = e end
        local s = Sig(list, function(e) return e.key end)
        if s == dmgSig then return end
        dmgSig = s
        dmgScroll:Clear()
        if #list == 0 then
            UI.Empty(dmgScroll, "Keine Schäden gemeldet – alle Systeme einsatzbereit.")
            return
        end
        for _, e0 in ipairs(list) do
            local key = e0.key
            local row = Row(dmgScroll, 58, function(sb, w, h)
                local e = live[key] or e0
                local state, col = IntegrityStyle(e.frac, e.d)
                RowBG(sb, w, h, false, col)
                local nw = draw.SimpleText(UI.Truncate(string.upper(e.name), "GARLog_Head", w - 520), "GARLog_Head", 12, 16, C.white, 0, 1)
                local x = 12 + nw + 8
                x = x + UI.Tag(e.kind == "vehicle" and "SCHIFF / FAHRZEUG" or "STRUKTUR", x, 16, e.kind == "vehicle" and C.blue or C.yellow) + 6
                if e.fcr then UI.Tag("IN REPARATUR", x, 16, C.cyan) end
                draw.SimpleText(UI.Truncate(string.upper(e.where or ""), "GARLog_Tiny", w - 360), "GARLog_Tiny", 12, 40, C.soft, 0, 1)
                draw.SimpleText(state .. "  " .. math.floor(e.frac * 100) .. "%", "GARLog_Tiny", w - 340, 22, col, 0, 1)
                UI.Bar(w - 340, 32, 110, 6, e.frac, col)
            end)
            local function Btn(label, accent, fn, enabled)
                local b = UI.Button(row, label, fn)
                b.Font = "GARLog_ButtonS"
                b.Accent = accent
                b:Dock(RIGHT)
                b:SetWide(80)
                b:DockMargin(0, 14, 6, 14)
                if enabled ~= nil then b:SetEnabled(enabled) end
                return b
            end
            Btn("AUFTRAG", C.cyan, function()
                local e = live[key] or e0
                Menu.RepairDialog({ loc = LocFromWhere(e), title = e.name, ent = e.ent, prio = e.frac < 0.35 and 3 or 2,
                    note = "Integrität " .. math.floor(e.frac * 100) .. " % – " .. (e.where or "") })
            end, Can("repair.create"))
            Btn("BERICHT", C.soft, function()
                local e = live[key] or e0
                Tech.ReportDialog({ cat = e.kind == "vehicle" and "vehicle" or "structure", obj = e.name, loc = LocFromWhere(e) or "",
                    st = e.frac <= 0 and 3 or 2, veh = e.cls, fd = "Integrität bei Inspektion: " .. math.floor(e.frac * 100) .. " %." })
            end, Can("report.create"))
            local mb = MarkButton(row, e0)
            mb:Dock(RIGHT)
            mb:SetWide(96)
            mb:DockMargin(0, 14, 6, 14)
        end
    end

    local mineSig
    local function RebuildMine()
        local sid = MySid()
        local list = {}
        for _, o in ipairs(D().rep or {}) do if o.st == REP_ASSIGNED and o.asid == sid then list[#list + 1] = o end end
        local s = Sig(list, function(o) return o.id end)
        if s == mineSig then return end
        mineSig = s
        mineScroll:Clear()
        if #list == 0 then UI.Empty(mineScroll, "Keine übernommenen Aufträge.") end
        for _, o in ipairs(list) do
            Row(mineScroll, 46, function(sb, w, h)
                local p = GARLog.Prio[o.pr or 2] or GARLog.Prio[2]
                RowBG(sb, w, h, false, p.color)
                draw.SimpleText("R-" .. o.id .. "  " .. UI.Truncate(string.upper(o.title or ""), "GARLog_Small", w - 70), "GARLog_Small", 12, 15, C.white, 0, 1)
                draw.SimpleText(UI.Truncate(string.upper(LocName(o.loc)), "GARLog_Tiny", w - 20), "GARLog_Tiny", 12, 32, C.soft, 0, 1)
            end, function()
                if IsValid(Menu.Frame) then Menu.Frame:ShowTab(2) end
            end)
        end
    end

    local rptSig
    local function RebuildReports()
        local list = D().rpt or {}
        local s = Sig({ list[1], list[2], list[3], list[4], list[5] }, function(r) return r.id .. ":" .. (r.v or 0) end)
        if s == rptSig then return end
        rptSig = s
        rptBox:Clear()
        if #list == 0 then UI.Empty(rptBox, "Noch keine Wartungsberichte.") end
        for i = 1, math.min(5, #list) do
            local r = list[i]
            Row(rptBox, 48, function(sb, w, h)
                local sd = StateDef(r.st)
                RowBG(sb, w, h, false, sd.color)
                draw.SimpleText("W-" .. r.id .. "  " .. UI.Truncate(string.upper(r.obj or ""), "GARLog_Small", w - 80), "GARLog_Small", 12, 15, C.white, 0, 1)
                draw.SimpleText(UI.Truncate(sd.name .. "  //  " .. string.upper(r.by or "?") .. "  //  " .. Ago(r.t), "GARLog_Tiny", w - 20), "GARLog_Tiny", 12, 33, sd.color, 0, 1)
            end, function()
                Tech.SelectReport = r.id
                if IsValid(Menu.Frame) then Menu.Frame:ShowTab(3) end
            end)
        end
    end

    RebuildDamage()
    RebuildMine()
    RebuildReports()
    function self.Refresh(sec)
        if sec == "loc" or sec == "veh" then RebuildDamage() end
        if sec == "rep" then RebuildMine() end
        if sec == "rpt" then RebuildReports() end
    end
    return self
end

---------------------------------------------------------------------------
-- Tab 2: Reparaturaufträge
---------------------------------------------------------------------------
local function BuildRepairs(parent)
    local self = {}
    local filter = "active"

    local top = vgui.Create("DPanel", parent)
    top:Dock(TOP)
    top:SetTall(36)
    top:DockMargin(0, 0, 0, 10)
    top.Paint = nil
    local filterBtns = {}
    local Rebuild
    for _, fdef in ipairs({ { "active", "AKTIV" }, { "mine", "MEINE" }, { "done", "ERLEDIGT" } }) do
        local b = UI.Button(top, fdef[2], function()
            filter = fdef[1]
            for k, o in pairs(filterBtns) do o.Active = k == filter end
            Rebuild(true)
        end)
        b.Font = "GARLog_ButtonS"
        b:Dock(LEFT)
        b:SetWide(100)
        b:DockMargin(0, 0, 6, 0)
        b.Active = fdef[1] == filter
        filterBtns[fdef[1]] = b
    end
    local newB = UI.Button(top, "+ AUFTRAG ERSTELLEN", function() Menu.RepairDialog() end)
    newB.Solid = true
    newB:Dock(RIGHT)
    newB:SetWide(200)
    newB:SetEnabled(Can("repair.create"))

    local hint = UI.Label(parent, "Übernommene Aufträge mit Ziel werden im HUD markiert. Aufträge zu Schiffen & Fahrzeugen schließen sich automatisch, sobald das Fusion-Cutter-Protokoll erfolgreich war. Strukturaufträge, sobald die Struktur wieder voll intakt ist.", "GARLog_Small", C.muted)
    hint:Dock(BOTTOM)
    hint:DockMargin(0, 8, 0, 0)

    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)

    -- Zustand (fr) & Priorität werden live gezeichnet; neu gebaut wird nur bei Status-/Zuweisungswechsel
    local sig
    local byId = {}
    Rebuild = function(force)
        local sid = MySid()
        local list = {}
        byId = {}
        for _, o in ipairs(D().rep or {}) do
            byId[o.id] = o
            local active = o.st == REP_OPEN or o.st == REP_ASSIGNED
            if (filter == "active" and active) or (filter == "done" and not active) or (filter == "mine" and o.asid == sid and active) then
                list[#list + 1] = o
            end
        end
        table.sort(list, function(a, b)
            if (a.pr or 2) ~= (b.pr or 2) then return (a.pr or 2) > (b.pr or 2) end
            return a.id > b.id
        end)
        local s = filter .. Sig(list, function(o) return o.id .. ":" .. o.st .. ":" .. (o.asid or "") end)
        if s == sig and not force then return end
        sig = s
        scroll:Clear()
        if #list == 0 then UI.Empty(scroll, filter == "done" and "Keine erledigten Aufträge." or "Keine offenen Reparaturaufträge.") end

        for _, o0 in ipairs(list) do
            local o = o0
            local row = Row(scroll, 64, function(sb, w, h)
                o = byId[o0.id] or o0
                local p = GARLog.Prio[o.pr or 2] or GARLog.Prio[2]
                local st = GARLog.RepStatus[o.st]
                RowBG(sb, w, h, o.asid == sid and o.st == REP_ASSIGNED, p.color)
                local nw = draw.SimpleText("R-" .. o.id, "GARLog_Head", 12, 16, C.yellow, 0, 1)
                local x = 12 + nw + 8
                x = x + UI.Tag(p.name, x, 16, p.color) + 6
                x = x + UI.Tag(st.name .. (o.as and (" – " .. string.upper(o.as)) or ""), x, 16, st.color) + 6
                x = x + UI.Tag(o.k == "auto" and "AUTOMATISCH" or (o.veh and "SCHIFF / FAHRZEUG" or "MANUELL"), x, 16, o.veh and C.blue or C.muted) + 6
                if o.rpt then UI.Tag("BERICHT W-" .. o.rpt, x, 16, C.soft) end
                draw.SimpleText(UI.Truncate(string.upper(o.title or ""), "GARLog_Small", w - 470), "GARLog_Small", 12, 38, C.white, 0, 1)
                local sub = string.upper(LocName(o.loc)) .. "  //  " .. Ago(o.t)
                if o.nt and o.nt ~= "" then sub = sub .. "  //  " .. o.nt end
                draw.SimpleText(UI.Truncate(sub, "GARLog_Tiny", w - 470), "GARLog_Tiny", 12, 54, C.soft, 0, 1)
                if o.fr then
                    local _, col = IntegrityStyle(o.fr)
                    draw.SimpleText("ZUSTAND " .. math.floor(o.fr * 100) .. "%", "GARLog_Tiny", w - 450, 38, col, 0, 1)
                    UI.Bar(w - 450, 48, 100, 6, o.fr, col)
                end
            end)
            local id = o.id
            local function Btn(label, accent, fn, enabled)
                local b = UI.Button(row, label, fn)
                b.Font = "GARLog_ButtonS"
                b.Accent = accent
                b:Dock(RIGHT)
                b:SetWide(104)
                b:DockMargin(0, 14, 8, 14)
                b:SetEnabled(enabled)
            end
            local function Act(action) return function() GARLog.Action(action, { id = id }) end end
            if o.st == REP_OPEN then
                Btn("ÜBERNEHMEN", C.cyan, Act("rep.accept"), Can("repair.work"))
            elseif o.st == REP_ASSIGNED then
                if o.k == "manual" then Btn("ERLEDIGT", C.green, Act("rep.done"), o.asid == sid or Can("repair.create")) end
                Btn("ABGEBEN", C.soft, Act("rep.drop"), o.asid == sid or GARLog.IsAdmin(LocalPlayer()))
            end
            if o.k == "manual" and o.st <= REP_ASSIGNED and (o.bysid == sid or GARLog.IsAdmin(LocalPlayer())) then
                Btn("ZURÜCKZIEHEN", C.red, Act("rep.cancel"), true)
            end
            if o.st <= REP_ASSIGNED then
                Btn("BERICHT", C.soft, function()
                    Tech.ReportDialog({ cat = o.veh and "vehicle" or (o.k == "auto" and "structure" or "other"), obj = o.title, loc = o.loc, rep = id })
                end, Can("report.create"))
            end
        end
    end
    Rebuild(true)

    function self.Refresh(sec)
        if sec == "rep" then Rebuild() end
    end
    return self
end

---------------------------------------------------------------------------
-- Tab 3: Wartungsberichte
---------------------------------------------------------------------------
local REPORT_FILTERS = {
    { "all", "ALLE" }, { "mine", "MEINE" }, { "vehicle", "SCHIFFE" }, { "structure", "STRUKTUREN" }, { "system", "SYSTEME" }, { "open", "NICHT EINSATZBEREIT" },
}

local function MatchReport(r, filter, query)
    if filter == "mine" and r.sid ~= MySid() then return false end
    if filter == "open" and r.st == 1 then return false end
    if (filter == "vehicle" or filter == "structure" or filter == "system") and r.cat ~= filter then return false end
    if query ~= "" then
        local hay = string.lower((r.obj or "") .. " " .. (r.by or "") .. " " .. (r.ln or "") .. " w-" .. r.id .. " " .. (r.veh or ""))
        if not hay:find(query, 1, true) then return false end
    end
    return true
end

local function BuildReports(parent, ctx)
    local self = {}
    local filter, query = "all", ""
    local selectedId = Tech.SelectReport
    Tech.SelectReport = nil

    local top = vgui.Create("DPanel", parent)
    top:Dock(TOP)
    top:SetTall(36)
    top:DockMargin(0, 0, 0, 10)
    top.Paint = nil
    local filterBtns = {}
    local RebuildList
    for _, fdef in ipairs(REPORT_FILTERS) do
        local b = UI.Button(top, fdef[2], function()
            filter = fdef[1]
            for k, o in pairs(filterBtns) do o.Active = k == filter end
            RebuildList(true)
        end)
        b.Font = "GARLog_ButtonS"
        b:Dock(LEFT)
        surface.SetFont("GARLog_ButtonS")
        b:SetWide(surface.GetTextSize(fdef[2]) + 26)
        b:DockMargin(0, 0, 6, 0)
        b.Active = fdef[1] == filter
        filterBtns[fdef[1]] = b
    end
    local newB = UI.Button(top, "+ NEUER BERICHT", function() Tech.ReportDialog() end)
    newB.Solid = true
    newB:Dock(RIGHT)
    newB:SetWide(170)
    newB:SetEnabled(Can("report.create"))

    local left = vgui.Create("DPanel", parent)
    left:Dock(LEFT)
    left:SetWide(400)
    left.Paint = nil
    local search = UI.Entry(left, "Suchen: Objekt, Verfasser, Standort, W-Nummer ...")
    search:Dock(TOP)
    search:SetTall(32)
    search:DockMargin(0, 0, 6, 8)
    search:SetUpdateOnType(true)
    search.OnValueChange = function(s, v)
        query = string.lower(string.Trim(v or ""))
        RebuildList(true)
    end
    local listScroll = UI.Scroll(left)
    listScroll:Dock(FILL)

    local detail = vgui.Create("DPanel", parent)
    detail:Dock(FILL)
    detail:DockMargin(16, 0, 0, 0)
    detail.Paint = nil

    local function FindHeader(id)
        for _, r in ipairs(D().rpt or {}) do if r.id == id then return r end end
    end

    local shown
    local function ShowDetail()
        detail:Clear()
        shown = nil
        local h = selectedId and FindHeader(selectedId)
        if not h then
            UI.Empty(detail, #(D().rpt or {}) == 0 and "Noch keine Wartungsberichte. Neuer Bericht: oben rechts." or "Bericht auswählen.")
            return
        end
        local r = GARLog.GetReport(h.id, h.v)
        if not r then
            UI.Empty(detail, "Bericht W-" .. h.id .. " wird geladen...")
            shown = { id = h.id, loading = true }
            return
        end
        shown = { id = r.id, v = r.v or 0 }
        local sd = StateDef(r.st)
        local cat = GARLog.ReportCategory(r.cat)

        local head = vgui.Create("DPanel", detail)
        head:Dock(TOP)
        head:SetTall(44)
        head.Paint = function(_, w, hh)
            local nw = draw.SimpleText("BERICHT W-" .. r.id, "GARLog_Title", 0, hh / 2, C.white, 0, 1)
            local x = nw + 12
            x = x + UI.Tag(sd.name, x, hh / 2, sd.color) + 6
            x = x + UI.Tag(string.upper(cat.name), x, hh / 2, C.soft) + 6
            if r.auto then UI.Tag("AUTOMATISCH", x, hh / 2, C.cyan) end
        end

        local info = UI.Framed(detail)
        info:Dock(TOP)
        info:SetTall(92)
        info:DockMargin(0, 6, 0, 8)
        local base = info.Paint
        info.Paint = function(s, w, hh)
            base(s, w, hh)
            local function kv(x, y, k, v, col)
                draw.SimpleText(k, "GARLog_Tiny", x, y, C.muted, 0, 1)
                draw.SimpleText(UI.Truncate(v, "GARLog_Small", w / 2 - 24), "GARLog_Small", x, y + 16, col or C.white, 0, 1)
            end
            local half = w / 2
            kv(12, 16, "OBJEKT", string.upper(r.obj or ""), C.yellow)
            kv(half, 16, "STANDORT", r.ln and string.upper(r.ln) or (r.loc ~= "" and string.upper(LocName(r.loc)) or "—"))
            kv(12, 56, "VERFASST VON", (r.by or "?") .. "  //  " .. os.date("%d.%m. %H:%M", r.t) .. (r.ed and ("  //  GEÄNDERT: " .. r.ed) or ""))
            local extra = {}
            if r.pt then extra[#extra + 1] = GARLog.FmtNum(r.pt) .. " TEC VERBRAUCHT" end
            if r.rep then extra[#extra + 1] = "AUFTRAG R-" .. r.rep end
            kv(half, 56, "ERSATZTEILE / AUFTRAG", #extra > 0 and table.concat(extra, "  //  ") or "—")
        end

        local bar = ActionBar(detail)
        local canEdit = r.sid == MySid() or Can("report.manage")
        bar:Add("NOTIZ", C.cyan, function()
            UI.Prompt("NOTIZ HINZUFÜGEN", "Ergänzung zu Bericht W-" .. r.id .. ":", "Notiz", "", function(v)
                GARLog.Action("rpt.note", { id = r.id, text = v })
            end, RCFG.NoteLength)
        end, Can("report.create") or Can("repair.work"), nil, 110)
        bar:Add("BEARBEITEN", C.yellow, function() Tech.ReportDialog({ edit = r }) end, canEdit, nil, 130)
        bar:Add("ALS AUFTRAG", C.blue, function()
            Menu.RepairDialog({ loc = r.loc ~= "" and r.loc or nil, title = r.obj, rpt = r.id, prio = r.st == 3 and 3 or 2,
                note = string.sub(r.ms ~= "" and r.ms or r.fd, 1, 190) })
        end, Can("repair.create") and r.st ~= 1, r.st == 1 and "Objekt ist einsatzbereit" or nil, 140)
        bar:Add("LÖSCHEN", C.red, function()
            UI.Confirm("BERICHT LÖSCHEN", "Wartungsbericht W-" .. r.id .. " endgültig löschen?", "LÖSCHEN", function()
                GARLog.Action("rpt.delete", { id = r.id })
            end, C.red)
        end, canEdit, nil, 110)

        local scroll = UI.Scroll(detail)
        scroll:Dock(FILL)
        local function TextBlock(title, text)
            UI.Section(scroll, title)
            local box = UI.Framed(scroll)
            box:Dock(TOP)
            box:DockMargin(0, 0, 6, 8)
            box:DockPadding(12, 10, 12, 10)
            local lbl = vgui.Create("DLabel", box)
            lbl:Dock(TOP)
            lbl:SetWrap(true)
            lbl:SetAutoStretchVertical(true)
            lbl:SetFont("GARLog_Text")
            lbl:SetTextColor(text ~= "" and C.white or C.muted)
            lbl:SetText(text ~= "" and text or "—")
            box:SetTall(44)
            -- Höhe folgt dem umbrechenden Text (nur setzen, wenn sie sich ändert -> kein Dauer-Layout)
            box.Think = function(s)
                local want = lbl:GetTall() + 20
                if s:GetTall() ~= want then s:SetTall(want) end
            end
        end
        TextBlock("BEFUND", r.fd or "")
        TextBlock("MASSNAHMEN", r.ms or "")

        UI.Section(scroll, "NOTIZEN (" .. #(r.notes or {}) .. ")")
        if #(r.notes or {}) == 0 then
            local l = UI.Label(scroll, "Noch keine Notizen.", "GARLog_Small", C.muted)
            l:DockMargin(10, 0, 0, 6)
        end
        for _, n in ipairs(r.notes or {}) do
            local box = UI.Framed(scroll)
            box:Dock(TOP)
            box:DockMargin(0, 0, 6, 4)
            box:DockPadding(12, 24, 12, 8)
            local bp = box.Paint
            box.Paint = function(s, w, hh)
                bp(s, w, hh)
                surface.SetDrawColor(C.cyan)
                surface.DrawRect(0, 0, 2, hh)
                draw.SimpleText(string.upper(n.b or "?") .. "  //  " .. os.date("%d.%m. %H:%M", n.t), "GARLog_Tiny", 12, 12, C.cyan, 0, 1)
            end
            local lbl = vgui.Create("DLabel", box)
            lbl:Dock(TOP)
            lbl:SetWrap(true)
            lbl:SetAutoStretchVertical(true)
            lbl:SetFont("GARLog_Small")
            lbl:SetTextColor(C.text)
            lbl:SetText(n.x or "")
            box:SetTall(48)
            box.Think = function(s)
                local want = lbl:GetTall() + 32
                if s:GetTall() ~= want then s:SetTall(want) end
            end
        end
    end

    local listSig
    RebuildList = function(force)
        local list = {}
        for _, r in ipairs(D().rpt or {}) do
            if MatchReport(r, filter, query) then list[#list + 1] = r end
        end
        local s = filter .. query .. Sig(list, function(r) return r.id .. ":" .. (r.v or 0) end)
        if s == listSig and not force then return end
        listSig = s
        listScroll:Clear()
        if #list == 0 then UI.Empty(listScroll, "Keine Berichte in dieser Ansicht.") end
        for _, r in ipairs(list) do
            Row(listScroll, 64, function(sb, w, h)
                local sd = StateDef(r.st)
                RowBG(sb, w, h, selectedId == r.id, sd.color)
                local nw = draw.SimpleText("W-" .. r.id, "GARLog_Head", 12, 15, C.yellow, 0, 1)
                local x = 12 + nw + 8
                x = x + UI.Tag(sd.name, x, 15, sd.color) + 6
                if r.a then UI.Tag("AUTO", x, 15, C.cyan) end
                draw.SimpleText(Ago(r.t), "GARLog_Tiny", w - 10, 15, C.muted, 2, 1)
                draw.SimpleText(UI.Truncate(string.upper(r.obj or ""), "GARLog_Small", w - 24), "GARLog_Small", 12, 36, C.white, 0, 1)
                local sub = string.upper(GARLog.ReportCategory(r.cat).name) .. "  //  " .. string.upper(r.by or "?")
                if r.ln then sub = sub .. "  //  " .. string.upper(r.ln) end
                if (r.n or 0) > 0 then sub = sub .. "  //  " .. r.n .. " NOTIZ(EN)" end
                draw.SimpleText(UI.Truncate(sub, "GARLog_Tiny", w - 24), "GARLog_Tiny", 12, 53, C.soft, 0, 1)
            end, function()
                selectedId = r.id
                ShowDetail()
            end)
        end
        if selectedId and not FindHeader(selectedId) then selectedId = nil end
        if not selectedId and list[1] then
            selectedId = list[1].id
            ShowDetail()
        end
    end

    RebuildList(true)
    ShowDetail()

    -- Vollständiger Bericht vom Server angekommen
    hook.Add("GARLog_Report", detail, function(_, r)
        if Tech.PendingSelect and Tech.PendingSelect > CurTime() then
            Tech.PendingSelect = nil
            selectedId = r.id
            RebuildList(true)
        end
        if r.id == selectedId and (not shown or shown.loading or shown.v ~= (r.v or 0)) then ShowDetail() end
    end)

    function self.Refresh(sec)
        if sec ~= "rpt" then return end
        RebuildList()
        local h = selectedId and FindHeader(selectedId)
        if not h then
            if shown then ShowDetail() end
        elseif not shown or shown.loading or (shown.v or 0) < (h.v or 0) then
            ShowDetail()
        end
    end
    return self
end

---------------------------------------------------------------------------
-- Tab 4: Schiffe & Fahrzeuge
---------------------------------------------------------------------------
local function BuildVehicles(parent)
    local self = {}
    local onlyDamaged = false

    local top = vgui.Create("DPanel", parent)
    top:Dock(TOP)
    top:SetTall(36)
    top:DockMargin(0, 0, 0, 10)
    top.Paint = nil
    local Rebuild
    local bAll = UI.Button(top, "ALLE", function() onlyDamaged = false Rebuild(true) end)
    local bDmg = UI.Button(top, "BESCHÄDIGT", function() onlyDamaged = true Rebuild(true) end)
    for _, b in ipairs({ bAll, bDmg }) do
        b.Font = "GARLog_ButtonS"
        b:Dock(LEFT)
        b:SetWide(120)
        b:DockMargin(0, 0, 6, 0)
    end
    bAll.Think = function(s) s.Active = not onlyDamaged end
    bDmg.Think = function(s) s.Active = onlyDamaged end

    local status = vgui.Create("DPanel", top)
    status:Dock(FILL)
    status.Paint = function(_, w, h)
        local fcr = GARLog.FCRAvailable() and cfg.VehicleRepair.UseFCR ~= false
        draw.SimpleText(fcr and "FUSION-CUTTER-PROTOKOLL VERFÜGBAR" or "FUSION-CUTTER NICHT INSTALLIERT – REPARATUR NUR AN TECHNIKERSTATIONEN",
            "GARLog_Section", w, h / 2, fcr and C.green or C.orange, 2, 1)
    end

    local hint = UI.Label(parent, "Reparatur: Datapad auf das Schiff / Fahrzeug richten und LMB drücken. Kosten: " .. cfg.VehicleRepair.CostPerHP * 1000 .. " TEC je 1.000 fehlende HP aus dem nächsten Lager (Feldbasis, Hangar-Terminal oder Heimatschiff). Erfolgreiche Reparaturen erzeugen automatisch einen Wartungsbericht.", "GARLog_Small", C.muted)
    hint:Dock(BOTTOM)
    hint:DockMargin(0, 8, 0, 0)

    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)

    -- Neu gebaut wird nur, wenn Fahrzeuge dazukommen/wegfallen; HP, Pilot usw. werden live gezeichnet
    local sig
    local live = {}
    local function Frac(v) return v.mx > 0 and v.hp / v.mx or 1 end
    Rebuild = function(force)
        local list = {}
        live = {}
        for _, v in ipairs(D().veh or {}) do
            live[v.i] = v
            if not onlyDamaged or (v.mx > 0 and v.hp < v.mx) then list[#list + 1] = v end
        end
        local s = tostring(onlyDamaged) .. Sig(list, function(v) return v.i end)
        if s == sig and not force then return end
        sig = s
        scroll:Clear()
        if #list == 0 then UI.Empty(scroll, onlyDamaged and "Keine beschädigten Schiffe oder Fahrzeuge." or "Keine Schiffe oder Fahrzeuge erfasst.") end
        for _, v0 in ipairs(list) do
            local v = v0
            local entry = { key = "v" .. v0.i, ent = v0.i, name = v0.n, cls = v0.c }
            local row = Row(scroll, 64, function(sb, w, h)
                v = live[v0.i] or v0
                local frac = Frac(v)
                local state, col = IntegrityStyle(frac)
                RowBG(sb, w, h, false, col)
                local nw = draw.SimpleText(UI.Truncate(v.n, "GARLog_Head", w - 560), "GARLog_Head", 12, 16, C.white, 0, 1)
                local x = 12 + nw + 8
                x = x + UI.Tag(state, x, 16, col) + 6
                if v.fcr then x = x + UI.Tag("IN REPARATUR", x, 16, C.cyan) + 6 end
                if v.d then UI.Tag("PILOT: " .. string.upper(v.d), x, 16, C.soft) end
                draw.SimpleText(UI.Truncate(string.upper(v.at or "") .. "  //  " .. v.c, "GARLog_Tiny", w - 380), "GARLog_Tiny", 12, 38, C.soft, 0, 1)
                draw.SimpleText(v.ls and ("ZULETZT INSTANDGESETZT " .. Ago(v.ls) .. " VON " .. string.upper(v.lb or "?")) or "KEINE INSTANDSETZUNG IN DIESER SITZUNG",
                    "GARLog_Tiny", 12, 53, v.ls and C.muted or C.muted, 0, 1)
                draw.SimpleText(GARLog.FmtNum(v.hp) .. " / " .. GARLog.FmtNum(v.mx) .. " HP", "GARLog_Tiny", w - 360, 22, col, 0, 1)
                UI.Bar(w - 360, 32, 120, 6, frac, col)
            end)
            local function Btn(label, accent, fn, enabled)
                local b = UI.Button(row, label, fn)
                b.Font = "GARLog_ButtonS"
                b.Accent = accent
                b:Dock(RIGHT)
                b:SetWide(80)
                b:DockMargin(0, 16, 6, 16)
                if enabled ~= nil then b:SetEnabled(enabled) end
            end
            Btn("AUFTRAG", C.cyan, function()
                local frac = Frac(v)
                Menu.RepairDialog({ loc = LocFromWhere(entry), title = v.n, ent = v.i, prio = frac < 0.35 and 3 or 2,
                    note = "Integrität " .. math.floor(frac * 100) .. " % – " .. (v.at or "") })
            end, Can("repair.create"))
            Btn("BERICHT", C.soft, function()
                local frac = Frac(v)
                Tech.ReportDialog({ cat = "vehicle", obj = v.n, loc = LocFromWhere(entry) or "", veh = v.c,
                    st = frac >= 1 and 1 or (frac <= 0 and 3 or 2), fd = "Integrität bei Inspektion: " .. math.floor(frac * 100) .. " % (" .. v.hp .. " / " .. v.mx .. " HP)." })
            end, Can("report.create"))
            local mb = MarkButton(row, entry)
            mb:Dock(RIGHT)
            mb:SetWide(96)
            mb:DockMargin(0, 16, 6, 16)
        end
    end
    Rebuild(true)

    function self.Refresh(sec)
        if sec == "veh" then Rebuild() end
    end
    return self
end

---------------------------------------------------------------------------
-- App-Registrierung
---------------------------------------------------------------------------
local function DamagedVehicles()
    local n = 0
    for _, v in ipairs(D().veh or {}) do if v.mx > 0 and v.hp < v.mx then n = n + 1 end end
    return n
end

Menu.RegisterApp(Menu.APP_TECHNIK, {
    label = "TECHNIK", title = "TECHNIK-KONTROLLTERMINAL", sub = "DATAPAD // WARTUNG & INSTANDSETZUNG",
    status = function()
        local s = Menu.Stats()
        if s.repOpen > 0 then return s.repOpen .. " OFFENE AUFTRÄGE", C.orange end
        return "ALLE AUFTRÄGE BEARBEITET", C.green
    end,
    tabs = {
        { label = "KONTROLLZENTRUM",   sub = "Schadenslage & Übersicht", build = BuildHome },
        { label = "AUFTRÄGE",          sub = "Reparaturaufträge",        build = BuildRepairs, badge = function()
            local s = Menu.Stats()
            return s.repOpen + s.mine, s.mine > 0 and C.cyan or C.orange
        end },
        { label = "WARTUNGSBERICHTE",  sub = "Lesen, erstellen, ergänzen", build = BuildReports },
        { label = "SCHIFFE & FAHRZEUGE", sub = "Register & Integrität",  build = BuildVehicles, badge = function()
            return DamagedVehicles(), C.orange
        end },
    },
})
