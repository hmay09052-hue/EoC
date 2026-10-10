--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Verwaltung
    Links: Einheiten (jede Haupteinheit genau einmal) + Dropdown für Untereinheiten
    Mitte: Mitglieder   Rechts: Akte, Fortbildungen, Aktionen
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S
local U = symchars.util
local UT = symchars.utils
local F = symchars.factions
local T = symchars.trainings
local C = symchars.chars

---------------------------------------------------------------------------------------------------------------
-- Aktionen ausführen (mit Eingabe-Dialogen)
---------------------------------------------------------------------------------------------------------------
local function Send(action, target, value)
    symchars.net.SendToServer("char_action", { action = action, id = target.charID, value = value })
end

function UI.OpenCustomsEditor(target)
    local customs = istable(target.customs) and target.customs or {}
    local f = UI.Frame("Custom-Charakter: " .. UT.BuildDisplayName(target), S(760), S(800))
    local scroll = UI.Scroll(f)
    scroll:Dock(FILL)

    local jobField = UI.Field(scroll, "Job", "Eigener DarkRP-Job (leer = Job der Einheit)")
    local job = UI.Combo(jobField)
    job:Dock(FILL)
    UI.FillJobCombo(job, customs.job ~= "none" and customs.job or "", "Kein eigener Job")

    local modelField = UI.Field(scroll, "Modell", "z.B. models/player/clone_commander.mdl (leer = Modell der Einheit)")
    local model = UI.Entry(modelField, "models/...", customs.model or "")
    model:Dock(FILL)

    local hpField = UI.Field(scroll, "Zusätzliche Lebenspunkte", "")
    local hp = UI.Entry(hpField, "0", tostring(customs.hp or 0))
    hp:Dock(FILL)
    hp:SetNumeric(true)

    local apField = UI.Field(scroll, "Zusätzliche Rüstung", "")
    local ap = UI.Entry(apField, "0", tostring(customs.ap or 0))
    ap:Dock(FILL)
    ap:SetNumeric(true)

    local wepField = UI.Field(scroll, "Waffen", "Werden bei jedem Spawn gegeben", S(300))
    local weapons = vgui.Create("symchars.Picker", wepField)
    weapons:Dock(FILL)
    weapons:SetItems(UI.WeaponItems())
    weapons:SetSelected(customs.weapons or {})

    local row = vgui.Create("DPanel", f)
    row:Dock(BOTTOM)
    row:SetTall(S(48))
    row:DockMargin(0, S(10), 0, 0)
    row.Paint = nil
    if target:IsCustom() then
        local remove = UI.Button(row, "Custom entfernen", "danger", function()
            Send("customs", target, { remove = true })
            f:Close()
        end)
        remove:Dock(LEFT)
        remove:SetWide(S(240))
    end
    local save = UI.Button(row, "Speichern", "primary", function()
        Send("customs", target, {
            job = job:GetSelectedData() or "", model = string.Trim(model:GetValue()),
            hp = tonumber(hp:GetValue()) or 0, ap = tonumber(ap:GetValue()) or 0, weapons = weapons:GetSelected(),
        })
        f:Close()
    end)
    save:Dock(RIGHT)
    save:SetWide(S(240))
end

function UI.RunAction(id, target)
    local action = C.GetAction(id)
    if not action then return end
    local name = UT.BuildDisplayName(target)
    local input = action.input

    if input == "none" then
        Send(id, target)
    elseif input == "confirm" then
        UI.Confirm(action.Name, action.Name .. ": " .. name .. "?", function() Send(id, target) end, nil, action.Name)
    elseif input == "text" then
        local default = id == "changname" and target.name or (id == "rpidchange" and target.roleplayID ~= "none" and target.roleplayID or "")
        UI.Prompt(action.Name, name, default, function(v) Send(id, target, v) end, { numeric = id == "rpidchange" })
    elseif input == "number" then
        UI.Prompt(action.Name, name .. " – aktuell " .. U.FormatMoney(target.money), tostring(target.money or 0), function(v) Send(id, target, tonumber(v)) end, { numeric = true })
    elseif input == "rank" then
        local faction = target:GetFaction()
        if not faction then return end
        -- ohne Admin-Recht höchstens bis unter den eigenen Rang
        local maxRank = #faction:GetRanks()
        local actor = UI.LocalChar()
        if not (symchars.HasPriv(LocalPlayer(), "symchars_char_ranksmanage") or symchars.HasPriv(LocalPlayer(), "symchars_char_admin")) and actor then
            local _, kind, byRank = symchars.authority.CanActOn(actor, target, "promotions")
            if kind == "same" or byRank then maxRank = math.min(maxRank, actor:GetRank() - 1) end
        end
        local choices = {}
        for i = maxRank, 1, -1 do
            local r = faction:GetRank(i)
            choices[#choices + 1] = { i .. "  ·  " .. r.name, i, i == target:GetRank() and "aktueller Rang" or (r.short ~= "" and r.short or nil), color = UI.UnitColor(target) }
        end
        UI.Choose(action.Name, name, choices, function(rank) Send(id, target, rank) end)
    elseif input == "unit" or input == "transfer" then
        local actor = UI.LocalChar()
        local admin = symchars.HasPriv(LocalPlayer(), "symchars_char_changefaction") or symchars.HasPriv(LocalPlayer(), "symchars_char_admin")
        local choices = {}
        for _, item in ipairs(F.GetHierarchyList()) do
            if item.id ~= target.faction and (admin or input == "unit" or symchars.authority.HasFlag(actor, item.id, "transfer")) then
                choices[#choices + 1] = { item.label, item.id, item.data.short, depth = item.depth }
            end
        end
        if #choices == 0 then symchars.Notify("Keine Ziel-Einheit verfügbar.", "error") return end
        UI.Choose(action.Name, name .. " versetzen nach:", choices, function(unit)
            UI.Choose("Rang", "Welchen Rang soll " .. name .. " in der neuen Einheit haben?", {
                { "Aktuellen Rang behalten", true, "falls vorhanden" },
                { "Mit Rang 1 beginnen", false },
            }, function(keep)
                Send(id, target, { unit = unit, keepRank = keep })
            end)
        end)
    elseif input == "job" then
        local choices = {}
        for _, item in ipairs(UI.JobItems()) do choices[#choices + 1] = { item.text, item.id, item.sub } end
        UI.Choose(action.Name, name, choices, function(job) Send(id, target, job) end)
    elseif input == "customs" then
        UI.OpenCustomsEditor(target)
    end
end

-- Fortbildung eintragen/entziehen
function UI.GrantTraining(t, target)
    UI.Prompt("Fortbildung eintragen", t.name .. " für " .. UT.BuildDisplayName(target) .. " (Notiz optional)", "", function(note)
        symchars.net.SendToServer("training_grant", { training = t.id, id = target.charID, note = note })
    end, { placeholder = "z.B. Prüfung mit 95% bestanden" })
end

function UI.RevokeTraining(t, target)
    UI.Prompt("Fortbildung entziehen", t.name .. " von " .. UT.BuildDisplayName(target) .. " entziehen (Grund)", "", function(reason)
        symchars.net.SendToServer("training_revoke", { training = t.id, id = target.charID, reason = reason })
    end)
end

---------------------------------------------------------------------------------------------------------------
-- Spielzeit-Diagramm (letzte 14 Tage)
---------------------------------------------------------------------------------------------------------------
local function PaintChart(char, x, y, w, h)
    UI.Box(x, y, w, h, Color(12, 15, 19, 220))
    UI.Outline(x, y, w, h, UI.col.line)
    local sessions = symchars.history.Get(char.charID, "character", "sessions") or {}
    local byDay = {}
    for _, s in ipairs(sessions) do byDay[s.x] = s.y end
    local today = symchars.history.DayStamp(os.time())
    local days, max = {}, 1
    for i = 13, 0, -1 do
        local stamp = today - i * 86400
        local d = os.date("*t", stamp)
        local key = os.time({ year = d.year, month = d.month, day = d.day, hour = 0 })
        local v = byDay[key] or 0
        days[#days + 1] = { stamp = key, v = v }
        if v > max then max = v end
    end
    local pad = S(12)
    local cw = (w - pad * 2) / #days
    local top = S(30) -- Platz für "max"-Beschriftung über den Balken
    local ch = h - top - S(32)
    for i, d in ipairs(days) do
        local bh = math.max(S(2), ch * (d.v / max))
        local bx = x + pad + (i - 1) * cw + S(3)
        UI.Box(bx, y + top + ch - bh, cw - S(6), bh, d.v > 0 and UI.Accent(210) or UI.col.line)
        if i % 2 == 1 or #days <= 7 then
            UI.Text(os.date("%d.%m", d.stamp), "symchars.tiny", bx + (cw - S(6)) / 2, y + h - S(26), UI.col.muted, TEXT_ALIGN_CENTER)
        end
    end
    UI.Text("max " .. U.FormatHours(max), "symchars.tiny", x + w - pad, y + S(6), UI.col.dim, TEXT_ALIGN_RIGHT)
end

---------------------------------------------------------------------------------------------------------------
-- Akte rechts
---------------------------------------------------------------------------------------------------------------
local function BuildDossier(panel, char)
    panel:Clear()
    if not char then
        panel.Paint = function(_, w, h)
            UI.Panel(0, 0, w, h, { cut = S(16), corners = "tlbr" })
            UI.Text("WÄHLE EIN MITGLIED", "symchars.h2", w / 2, h / 2, UI.col.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return
    end
    symchars.history.Request(char.charID, true)

    local actor = UI.LocalChar()
    local ply = LocalPlayer()

    panel.Paint = function(_, w, h)
        UI.Panel(0, 0, w, h, { cut = S(16), corners = "tlbr" })
    end

    local head = vgui.Create("DPanel", panel)
    head:Dock(TOP)
    head:SetTall(S(170))
    head:DockMargin(S(16), S(12), S(16), 0)
    local portrait = UI.HoloModel(head, "solid")
    portrait:SetFraming("bust")
    portrait:SetYaw(15)
    portrait:Dock(LEFT)
    portrait:SetWide(S(150))
    portrait:SetHoloModel(char.model)
    head.Paint = function(_, w, h)
        local faction = char:GetFaction()
        local x = S(170)
        UI.TextFit(UT.BuildDisplayName(char), "symchars.name", x, S(8), UI.col.text, w - x)
        UI.Aurebesh(UT.BuildDisplayName(char), "symchars.aure.small", x + S(2), S(46), UI.Alpha(UI.col.dim, 140), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - x)
        local rank = char:GetRankData()
        UI.TextFit(rank and rank.name or "-", "symchars.h3", x, S(68), UI.Readable(UI.UnitColor(char)), w - x)
        UI.TextFit(faction and F.GetDisplayName(faction) or U.JobName(char.job), "symchars.small", x, S(98), UI.col.dim, w - x)
        local cx = x
        local online = char:IsOnline()
        local pw = UI.Chip(online and "online" or ("zuletzt " .. U.FormatAgo(char.lastActive)), "symchars.tiny.bold", cx, S(128), online and UI.col.ink or UI.col.text, online and UI.col.green or UI.col.panel3)
        cx = cx + pw + S(6)
        if char:IsCustom() then UI.Chip("custom", "symchars.tiny.bold", cx, S(128), UI.col.text, Color(70, 76, 160)) end
        UI.Box(0, h - 1, w, 1, UI.col.line2)
    end

    local tabs = vgui.Create("symchars.Tabs", panel)
    tabs:Dock(TOP)
    tabs:SetTall(S(52))
    tabs:DockMargin(S(16), S(10), S(16), 0)
    tabs:SetFont("symchars.h3")
    tabs:SetGap(S(40))

    local body = vgui.Create("DPanel", panel)
    body:Dock(FILL)
    body:DockMargin(S(16), S(6), S(16), S(16))
    body.Paint = nil

    local function ShowAkte()
        body:Clear()
        local scroll = UI.Scroll(body)
        scroll:Dock(FILL)
        local infos = vgui.Create("DPanel", scroll)
        infos:Dock(TOP)
        infos:SetTall(S(150))
        infos.Paint = function(_, w)
            local joined = symchars.history.Get(char.charID, "faction", "joined")
            local promo = symchars.history.Get(char.charID, "faction", "last_promote")
            local rows = {
                { "Erstellt", U.FormatDate(char.createdAt) },
                { "In Einheit seit", U.FormatDate(tonumber(joined)) },
                { "Letzter Rangwechsel", U.FormatDate(tonumber(promo), true) },
                { "Spielzeit gesamt", char._historyLoaded and U.FormatHours(symchars.history.TotalHours(char.charID)) or "lädt…" },
                { "RP-ID", UT.BuildRoleplayID(char) ~= "" and UT.BuildRoleplayID(char) or "-" },
                { "Credits", U.FormatMoney(char.money) },
            }
            local cw = w / 2
            for i, r in ipairs(rows) do
                local x = ((i - 1) % 2) * cw
                local y = math.floor((i - 1) / 2) * S(48)
                UI.Text(string.upper(r[1]), "symchars.tiny.bold", x, y, UI.col.muted)
                UI.TextFit(r[2], "symchars.body", x, y + S(18), UI.col.text, cw - S(10))
            end
        end
        local chart = vgui.Create("DPanel", scroll)
        chart:Dock(TOP)
        chart:SetTall(S(200))
        chart:DockMargin(0, S(6), 0, 0)
        chart.Paint = function(_, w, h)
            UI.Section("Spielzeit (14 Tage)", 0, 0, w)
            PaintChart(char, 0, S(34), w, h - S(34))
        end

        local log = vgui.Create("DPanel", scroll)
        log:Dock(TOP)
        log:DockMargin(0, S(14), 0, 0)
        log.Think = function(s)
            local entries = symchars.history.Get(char.charID, "log", "entries") or {}
            local want = S(40) + math.max(1, #entries) * S(46)
            if s:GetTall() ~= want then s:SetTall(want) end
        end
        log.Paint = function(_, w)
            UI.Section("Akte", 0, 0, w)
            local entries = symchars.history.Get(char.charID, "log", "entries") or {}
            if #entries == 0 then
                UI.Text(char._historyLoaded and "Noch keine Einträge." or "Lädt…", "symchars.small", 0, S(40), UI.col.muted)
                return
            end
            local kindCol = { rank = UI.Accent(), unit = UI.col.blue, training = UI.col.green, info = UI.col.dim }
            local y = S(40)
            for i = #entries, 1, -1 do
                local e = entries[i]
                UI.Box(0, y + S(4), S(3), S(36), kindCol[e.kind] or UI.col.dim)
                UI.TextFit(tostring(e.entry), "symchars.small.bold", S(12), y + S(2), UI.col.text, w - S(12))
                UI.TextFit(U.FormatDate(e.timestamp, true) .. (e.by and e.by ~= "" and ("  ·  " .. e.by) or ""), "symchars.tiny", S(12), y + S(22), UI.col.muted, w - S(12))
                y = y + S(46)
            end
        end
    end

    local function ShowTrainings()
        body:Clear()
        local scroll = UI.Scroll(body)
        scroll:Dock(FILL)
        local list = T.List()
        local shown = 0

        -- Hinweis, wer hier eintragen darf
        local isAdmin = symchars.HasPriv(ply, "symchars_trainings_admin")
        local freigabe = T.HasFreigabe(actor)
        local own = actor and actor.charID == char.charID
        local hint = vgui.Create("DPanel", scroll)
        hint:Dock(TOP)
        hint:SetTall(S(46))
        hint:DockMargin(0, 0, 0, S(10))
        hint.Paint = function(_, w, h)
            local ok = (isAdmin or freigabe) and (not own or isAdmin)
            local col = ok and UI.col.green or UI.Accent()
            UI.Box(0, 0, w, h, UI.Alpha(col, 22))
            UI.Box(0, 0, S(3), h, col)
            local text
            if isAdmin then text = "Admin: Du kannst alle Fortbildungen eintragen, auch die Fortbildungs-Freigabe."
            elseif own and freigabe then text = "Eigene Fortbildungen kann dir nur jemand anderes eintragen."
            elseif freigabe then text = "Fortbildungs-Freigabe: Du kannst Fortbildungen eintragen und entziehen."
            else text = "Zum Eintragen brauchst du die Fortbildungs-Freigabe (vergibt ein Admin)." end
            UI.TextFit(text, "symchars.small", S(14), h / 2, UI.col.text, w - S(24), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        for _, t in ipairs(list) do
            local has = char:HasTraining(t.id)
            local entry = char:GetTrainings()[t.id]
            local active = T.IsActiveFor(t, char)
            if active or entry then
                shown = shown + 1
                local canTeach = T.CanTeach(ply, actor, t) and (not own or isAdmin)
                local row = vgui.Create("DPanel", scroll)
                row:Dock(TOP)
                row:SetTall(S(70))
                row:DockMargin(0, 0, 0, S(8))
                row.Paint = function(_, w, h)
                    UI.Box(0, 0, w, h, Color(14, 18, 23, 230))
                    UI.Box(0, 0, S(4), h, has and UI.col.green or (entry and UI.col.red or UI.col.line2))
                    UI.TextFit(t.name, "symchars.h3", S(16), S(6), T.IsFreigabe(t) and UI.Accent() or UI.col.text, w - S(260))
                    local sub
                    if has then
                        sub = "Bestanden am " .. U.FormatDate(entry.at) .. " bei " .. (entry.byName ~= "" and entry.byName or "?")
                        if entry.exp and entry.exp > 0 then sub = sub .. "  ·  gültig bis " .. U.FormatDate(entry.exp) end
                    elseif entry then
                        sub = "Abgelaufen am " .. U.FormatDate(entry.exp)
                    else
                        sub = "Nicht bestanden"
                    end
                    UI.TextFit(sub, "symchars.tiny", S(16), S(42), has and UI.col.dim or UI.col.muted, w - S(260))
                end
                if canTeach then
                    local b
                    if has then
                        b = UI.Button(row, "Entziehen", "danger", function() UI.RevokeTraining(t, char) end)
                    else
                        b = UI.Button(row, "Eintragen", "primary", function() UI.GrantTraining(t, char) end)
                    end
                    b:SetFont("symchars.button.small")
                    b:Dock(RIGHT)
                    b:SetWide(S(170))
                    b:DockMargin(0, S(13), S(12), S(13))
                end
            end
        end
        if shown == 0 then
            local empty = vgui.Create("DLabel", scroll)
            empty:Dock(TOP)
            empty:SetTall(S(40))
            empty:SetFont("symchars.body")
            empty:SetTextColor(UI.col.muted)
            empty:SetText("Für diese Einheit gibt es keine Fortbildungen (ADMIN > Fortbildungen).")
        end
    end

    local function ShowActions(category)
        body:Clear()
        local scroll = UI.Scroll(body)
        scroll:Dock(FILL)
        local count = 0
        for _, id in ipairs(C.actionOrder) do
            local action = C.actions[id]
            if action.category == category then
                local ok, reason = C.HasActionPermission(id, ply, actor, char)
                if ok then
                    count = count + 1
                    local b = UI.Button(scroll, action.Name, "default", function() UI.RunAction(id, char) end)
                    b:Dock(TOP)
                    b:SetTall(S(52))
                    b:DockMargin(0, 0, 0, S(8))
                    b:SetAlign(TEXT_ALIGN_LEFT)
                    b:SetFont("symchars.h3")
                    if reason and reason ~= "" then b:SetSubText("Recht: " .. reason) end
                    if action.Color then b:SetAccentColor(action.Color) end
                end
            end
        end
        if count == 0 then
            local empty = vgui.Create("DLabel", scroll)
            empty:Dock(TOP)
            empty:SetTall(S(40))
            empty:SetFont("symchars.body")
            empty:SetTextColor(UI.col.muted)
            empty:SetText("Du hast hier keine Aktionen zur Verfügung.")
        end
    end

    local tabList = { { id = "akte", name = "Akte" }, { id = "trainings", name = "Fortbildungen" }, { id = "actions", name = "Aktionen" } }
    local hasAdmin = false
    for _, id in ipairs(C.actionOrder) do
        if C.actions[id].category == "admin" and C.HasActionPermission(id, ply, actor, char) then hasAdmin = true break end
    end
    if hasAdmin then tabList[#tabList + 1] = { id = "admin", name = "Admin" } end
    tabs:SetTabs(tabList)
    tabs.OnChange = function(_, id)
        if id == "akte" then ShowAkte()
        elseif id == "trainings" then ShowTrainings()
        elseif id == "actions" then ShowActions("unit")
        elseif id == "admin" then ShowActions("admin") end
    end
    tabs:SetActive(panel._lastTab or "akte")
    local oldChange = tabs.OnChange
    tabs.OnChange = function(s, id) panel._lastTab = id oldChange(s, id) end
end

---------------------------------------------------------------------------------------------------------------
-- Seite
---------------------------------------------------------------------------------------------------------------
local function Build(parent, opts)
    local page = vgui.Create("DPanel", parent)
    page:Dock(FILL)
    page.Paint = nil

    local state = { root = nil, filter = "all", selected = nil, search = "" }
    local admin = symchars.HasPriv(LocalPlayer(), "symchars_charmanage")

    -- links
    local left = vgui.Create("DPanel", page)
    left.Paint = function(_, w) UI.Text("EINHEIT", "symchars.h3", 0, 0, UI.col.dim) end
    local unitList = UI.Scroll(left)
    local subLabel = vgui.Create("DPanel", left)
    subLabel.Paint = function() UI.Text("UNTEREINHEIT", "symchars.h3", 0, 0, UI.col.dim) end
    local subCombo = UI.Combo(left, "Alle Untereinheiten")
    subCombo:SetFont("symchars.body.bold")

    -- mitte
    local middle = vgui.Create("DPanel", page)
    middle.Paint = function(_, w, h)
        UI.Panel(0, 0, w, h, { cut = S(14), corners = "tlbr" })
    end
    local search = UI.Entry(middle, admin and "Name, RP-ID oder SteamID64…" or "Mitglied suchen…")
    local count = vgui.Create("DPanel", middle)
    count.Paint = function(_, w, h) UI.Text(string.upper(count.text or ""), "symchars.h4", 0, h / 2, UI.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
    local memberList = UI.Scroll(middle)
    local inviteBtn = UI.Button(middle, "Spieler einladen", "default")
    inviteBtn:SetFont("symchars.button.small")
    inviteBtn:SetIcon("plus")

    -- rechts
    local dossier = vgui.Create("DPanel", page)

    local unitButtons = {}

    local function Members()
        local out = {}
        local q = string.lower(string.Trim(state.search))
        if admin and q ~= "" and string.len(q) >= 2 then
            for _, char in pairs(C.All()) do
                local hay = string.lower(char.name .. " " .. UT.BuildRoleplayID(char) .. " " .. tostring(char.charUser))
                if char:IsActive() and string.find(hay, q, 1, true) then out[#out + 1] = char end
            end
        elseif state.root then
            local scope = state.filter == "all" and nil or F.Get(state.filter)
            for _, char in pairs(C.All()) do
                if char:IsActive() and char.faction then
                    local ok
                    if scope then ok = char.faction == scope.uniqueID
                    else ok = F.IsInTree(char.faction, state.root) end
                    if ok and q ~= "" then
                        ok = string.find(string.lower(char.name .. " " .. UT.BuildRoleplayID(char)), q, 1, true) ~= nil
                    end
                    if ok then out[#out + 1] = char end
                end
            end
        end
        table.sort(out, function(a, b)
            local da, db = F.GetDepth(a.faction), F.GetDepth(b.faction)
            if da ~= db then return da < db end
            if a:GetRank() ~= b:GetRank() then return a:GetRank() > b:GetRank() end
            return string.lower(a.name) < string.lower(b.name)
        end)
        return out
    end

    local function ShowMembers()
        memberList:Clear()
        local list = Members()
        count.text = #list .. " Mitglieder"
        for _, char in ipairs(list) do
            local row = vgui.Create("DButton", memberList)
            row:Dock(TOP)
            row:SetTall(S(64))
            row:DockMargin(0, 0, 0, S(4))
            row:SetText("")
            row._hover = 0
            row.Think = function(s) s._hover = UI.Approach(s._hover, s:IsHovered() and 1 or 0, 14) end
            row.Paint = function(s, w, h)
                local sel = state.selected and state.selected.charID == char.charID
                UI.Box(0, 0, w, h, sel and Color(30, 26, 18, 235) or UI.Lerp(s._hover, Color(13, 16, 20, 200), Color(22, 26, 32, 230)))
                if sel then UI.Outline(0, 0, w, h, UI.Accent()) end
                local rank = char:GetRankData()
                UI.Box(0, 0, S(4), h, UI.UnitColor(char))
                UI.Circle(S(20), S(20), S(5), char:IsOnline() and UI.col.green or UI.col.faint, 12)
                UI.TextFit(UT.BuildDisplayName(char), "symchars.body.bold", S(34), S(8), UI.col.text, w - S(120))
                local faction = char:GetFaction()
                local sub = (rank and rank.name or "-")
                if faction and state.root and faction.uniqueID ~= state.root.uniqueID then sub = sub .. "  ·  " .. faction.name end
                UI.TextFit(sub, "symchars.small", S(34), S(34), UI.Readable(UI.UnitColor(char)), w - S(120))
                local tcount = 0
                for id in pairs(char:GetTrainings()) do if char:HasTraining(id) then tcount = tcount + 1 end end
                if tcount > 0 then
                    UI.Icon("medal", w - S(56), h / 2 - S(12), S(24), UI.col.dim)
                    UI.Text(tostring(tcount), "symchars.small.bold", w - S(26), h / 2, UI.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                return true
            end
            row.DoClick = function()
                UI.Sound("click")
                state.selected = char
                BuildDossier(dossier, char)
            end
        end
        if state.selected and not C.Get(state.selected.charID) then
            state.selected = nil
            BuildDossier(dossier, nil)
        end
    end

    local function FillSubCombo()
        subCombo:Clear()
        if not state.root then return end
        local subs = F.GetDescendants(state.root)
        subCombo:AddChoice("Alle (inkl. Untereinheiten)", "all", state.filter == "all", 0)
        subCombo:AddChoice(state.root.name .. " (nur Haupteinheit)", state.root.uniqueID, state.filter == state.root.uniqueID, 0)
        for _, item in ipairs(subs) do
            subCombo:AddChoice(item.data.name, item.data.uniqueID, state.filter == item.data.uniqueID, item.depth, #C.GetMembers(item.data, false) .. "")
        end
        subCombo:SetVisible(#subs > 0)
        subLabel:SetVisible(#subs > 0)
    end

    subCombo.OnSelect = function(_, _, _, data)
        state.filter = data
        ShowMembers()
    end

    local function SelectRoot(root, filter)
        state.root = root
        state.filter = filter or "all"
        for _, b in ipairs(unitButtons) do b:SetSelected(b.root == root) end
        FillSubCombo()
        ShowMembers()
    end

    local function RebuildUnits()
        unitList:Clear()
        unitButtons = {}
        local actor = UI.LocalChar()
        local managed = symchars.authority.ManagedUnits(actor)
        for _, root in ipairs(F.GetRoots()) do
            local b = UI.Button(unitList, root.name, "select")
            b.root = root
            b:Dock(TOP)
            b:SetTall(S(56))
            b:DockMargin(0, 0, S(6), S(8))
            b:SetAlign(TEXT_ALIGN_LEFT)
            b:SetFont("symchars.h3")
            local mine = managed[root.uniqueID]
            if not mine then
                for _, item in ipairs(F.GetDescendants(root)) do if managed[item.data.uniqueID] then mine = true break end end
            end
            b:SetSubText(#C.GetMembers(root, true) .. " Mitglieder" .. (mine and "  ·  Befehlsgewalt" or ""))
            b.DoClick = function() SelectRoot(root) end
            unitButtons[#unitButtons + 1] = b
        end

        local target = opts.unit and F.Get(opts.unit)
        opts.unit = nil
        if target then
            SelectRoot(F.GetRoot(target), target.uniqueID)
        elseif state.root and F.Get(state.root.uniqueID) then
            SelectRoot(F.Get(state.root.uniqueID), state.filter)
        else
            local own = actor and actor:GetFaction()
            if own then SelectRoot(F.GetRoot(own)) elseif F.GetRoots()[1] then SelectRoot(F.GetRoots()[1]) end
        end
    end

    search.OnValueChange = function(_, v)
        state.search = v or ""
        ShowMembers()
    end

    inviteBtn.DoClick = function()
        local actor = UI.LocalChar()
        if not actor then return end
        local choices = {}
        for _, p in ipairs(player.GetAll()) do
            local c = p:GetCharacter()
            if c and p ~= LocalPlayer() and C.HasActionPermission("invite", LocalPlayer(), actor, c) then
                local faction = c:GetFaction()
                choices[#choices + 1] = { UT.BuildDisplayName(c), c, faction and faction.name or "" }
            end
        end
        if #choices == 0 then symchars.Notify("Niemand online, den du einladen kannst.", "error") return end
        UI.Choose("Spieler einladen", "In deine Einheit einladen:", choices, function(c) UI.RunAction("invite", c) end)
    end

    page.PerformLayout = function(_, w, h)
        local leftW = math.min(S(380), w * 0.22)
        local midW = math.min(S(500), w * 0.29)
        left:SetPos(0, 0)
        left:SetSize(leftW, h)
        local comboH = subCombo:IsVisible() and S(110) or 0
        unitList:SetPos(0, S(36))
        unitList:SetSize(leftW, h - S(36) - comboH)
        subLabel:SetPos(0, h - S(100))
        subLabel:SetSize(leftW, S(30))
        subCombo:SetPos(0, h - S(66))
        subCombo:SetSize(leftW - S(6), S(48))

        middle:SetPos(leftW + S(16), 0)
        middle:SetSize(midW, h)
        search:SetPos(S(14), S(14))
        search:SetSize(midW - S(28), S(42))
        count:SetPos(S(14), S(60))
        count:SetSize(midW - S(28), S(30))
        local actor = UI.LocalChar()
        local canInvite = actor and actor:GetFaction() and symchars.authority.HasFlag(actor, actor.faction, "invite")
        inviteBtn:SetVisible(canInvite == true)
        local bottom = canInvite and S(64) or S(14)
        memberList:SetPos(S(14), S(94))
        memberList:SetSize(midW - S(28), h - S(94) - bottom)
        inviteBtn:SetPos(S(14), h - S(56))
        inviteBtn:SetSize(midW - S(28), S(44))

        dossier:SetPos(leftW + midW + S(32), 0)
        dossier:SetSize(w - leftW - midW - S(32), h)
    end

    hook.Add("symchars_factions_synced", page, function() RebuildUnits() end)
    hook.Add("symchars_char_updated", page, function(_, char)
        ShowMembers()
        if char and state.selected and char.charID == state.selected.charID then
            state.selected = char
            BuildDossier(dossier, char)
        end
    end)
    hook.Add("symchars_trainings_synced", page, function()
        if state.selected then BuildDossier(dossier, state.selected) end
    end)

    BuildDossier(dossier, nil)
    RebuildUnits()
end

UI.RegisterPage({
    id = "manager", name = "Verwaltung", order = 3, needsChar = true,
    visible = function() return symchars.Config("usefactions") == true end,
    build = Build,
})
