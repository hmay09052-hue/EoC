--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Personalakten
    Stufe 1: eigene Akte  ·  ab PersonnelUnitLevel: eigene Einheit  ·  ab PersonnelAllLevel: alle
    Reiter: Akte, Vermerke (Belobigungen, Verwarnungen ...), Fortbildungen, Verlauf (aus SymChars)
-------------------------------------------------------------------------------------------------------------]]

local D = GAR_DP.ui
local S = D.S
local CFG = GAR_DP.Config

-- Kopf einer Akte: Holo-Buste, Name + Aurebesh, Rang, Einheit, Chips (wird auch in den Strafakten benutzt)
function D.PersonHeader(parent, char, extraChips)
    local head = vgui.Create("DPanel", parent)
    head:Dock(TOP)
    head:SetTall(S(128))
    head:DockMargin(0, 0, 0, S(10))

    local mdl = D.HoloModel(head, char.model, "bust")
    mdl:SetPos(0, 0)
    mdl:SetSize(S(112), S(128))

    head.Paint = function(_, w, h)
        local x = S(128)
        local cw = w - x
        local name = D.CharName(char)
        D.TextFit(string.upper(name), "gdp.h1", x, -S(4), D.col.text, cw * 0.62)
        local _, nh = D.TextSize("Ag", "gdp.h1")
        D.Aurebesh(name, "gdp.aure", x + S(1), nh - S(8), D.Alpha(D.Accent(), 150), nil, nil, cw * 0.62)
        local y = nh - S(8) + D.AurebeshHeight("gdp.aure") + S(4)
        local rank, rankCol = D.CharRank(char)
        local unit, unitCol = D.CharUnit(char)
        D.TextFit(string.upper(rank ~= "" and rank or "Ohne Rang"), "gdp.h3", x, y, rankCol, cw)
        local _, rh = D.TextSize("Ag", "gdp.h3")
        D.Aurebesh(rank ~= "" and rank or "Ohne Rang", "gdp.aure.small", x + S(1), y + rh - S(5), D.Alpha(rankCol, 120), nil, nil, cw)
        D.TextFit(unit, "gdp.small", x, h - S(4), unitCol, cw * 0.6, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

        local chips = {}
        local online = char:IsOnline()
        chips[#chips + 1] = { online and "Im Dienst" or "Nicht im Dienst", online and D.col.green or D.col.muted }
        local tp = char:GetPlayer()
        local level = IsValid(tp) and GAR_DP.Clearance(tp) or GAR_DP.CharClearance(char)
        chips[#chips + 1] = { "Stufe " .. level, GAR_DP.LevelData(level).color }
        for _, c in ipairs(extraChips and extraChips() or {}) do chips[#chips + 1] = c end
        local px = w
        for i = #chips, 1, -1 do
            local cwid = D.ChipSize(chips[i][1])
            px = px - cwid
            D.Chip(chips[i][1], px, S(4), chips[i][2])
            px = px - S(6)
        end
        D.Text("ID #" .. char:GetID(), "gdp.mono", w, h - S(4), D.Alpha(D.Accent(), 160), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        D.Box(x, h - 1, w - x, 1, D.col.line2)
    end
    return head
end

local function TypeData(id) return GAR_DP.ById(CFG.PersonnelTypes, id) or CFG.PersonnelTypes[1] end

local function NationalityName(char)
    local id = char.GetData and char:GetData("nationality")
    if not id or id == "" then return "-" end
    for _, n in ipairs(symchars.Config("nationalities") or {}) do
        if n.id == id then return n.name end
    end
    return tostring(id)
end

---------------------------------------------------------------------------------------------------------------
-- Formular: Vermerk anlegen / bearbeiten
---------------------------------------------------------------------------------------------------------------
local function OpenNoteForm(char, item, onSaved)
    local card = D.Modal(item and "Vermerk bearbeiten" or "Neuer Vermerk", S(620), S(560))
    if not card then return end
    local myLevel = GAR_DP.Clearance(LocalPlayer())
    local extra = item and item.extra or {}

    local row = vgui.Create("DPanel", card)
    row:Dock(TOP)
    row:SetTall(S(54))
    row:DockMargin(0, 0, 0, S(8))
    row.Paint = nil
    local typeField = D.Field(row, "Art", S(32), LEFT)
    typeField:SetWide(S(270))
    typeField:DockMargin(0, 0, S(10), 0)
    local typeCombo = D.Combo(typeField)
    typeCombo:Dock(FILL)
    for _, t in ipairs(CFG.PersonnelTypes) do typeCombo:AddChoice(t.name, t.id, t.id == (extra.type or CFG.PersonnelTypes[1].id), t.color) end

    local levelField = D.Field(row, "Sicherheitsstufe", S(32), FILL)
    local levelCombo = D.LevelCombo(levelField, item and item.level or 1, myLevel)
    levelCombo:Dock(FILL)

    local titleField = D.Field(card, "Titel", S(34))
    local title = D.Entry(titleField, "z.B. Hervorragende Führung bei Operation Geonosis", item and item.title)
    title:Dock(FILL)

    local buttons = vgui.Create("DPanel", card)
    buttons:Dock(BOTTOM)
    buttons:SetTall(S(44))
    buttons:DockMargin(0, S(8), 0, 0)
    buttons.Paint = nil

    local textField = D.Field(card, "Text", S(100), FILL)
    local text = D.Entry(textField, "Begründung / Beschreibung…", item and item.body, true)
    text:Dock(FILL)

    local save = D.Button(buttons, "Speichern", "primary", function()
        GAR_DP.Request("save", {
            id = item and item.id, kind = "personnel", target = char:GetID(),
            title = title:GetValue(), body = text:GetValue(), level = levelCombo:GetSelectedData(),
            extra = { type = typeCombo:GetSelectedData() },
        }, function(res)
            if not res then return end
            card:Close()
            GAR_DP.Notify("Vermerk gespeichert.", "info")
            if onSaved then onSaved() end
        end)
    end)
    save:Dock(RIGHT)
    save:SetWide(S(200))
    local cancel = D.Button(buttons, "Abbrechen", "default", function() card:Close() end)
    cancel:Dock(LEFT)
    cancel:SetWide(S(160))
end

---------------------------------------------------------------------------------------------------------------
-- Detailansicht
---------------------------------------------------------------------------------------------------------------
local function BuildDetail(parent, char)
    parent:Clear()
    D.PersonHeader(parent, char)

    local content

    local function ShowAkte()
        content:Clear()
        local hist = symchars.history
        if hist and hist.Request then hist.Request(char:GetID()) end
        local p = vgui.Create("DPanel", content)
        p:Dock(FILL)
        p.Paint = function(_, w, h)
            local colW = math.floor((w - S(24)) / 2)
            local x1, x2 = 0, colW + S(24)
            local rank, rankCol = D.CharRank(char)
            local unit, unitCol = D.CharUnit(char)
            local tp = char:GetPlayer()
            local level = IsValid(tp) and GAR_DP.Clearance(tp) or GAR_DP.CharClearance(char)
            local ld = GAR_DP.LevelData(level)
            local manual = GAR_DP.manual[char:GetID()]

            local y1 = 0
            y1 = y1 + D.KeyValue("Name", char.name or "-", x1, y1, colW)
            y1 = y1 + D.KeyValue("RP-ID", char.roleplayID or "-", x1, y1, colW)
            y1 = y1 + D.KeyValue("Einheit", unit, x1, y1, colW, unitCol)
            y1 = y1 + D.KeyValue("Rang", rank ~= "" and rank or "-", x1, y1, colW, rankCol)
            y1 = y1 + D.KeyValue("Nationalität", NationalityName(char), x1, y1, colW)

            local y2 = 0
            y2 = y2 + D.KeyValue("Sicherheitsfreigabe", "Stufe " .. level .. "  ·  " .. ld.name, x2, y2, colW, ld.color)
            y2 = y2 + D.KeyValue("Freigabe vergeben", manual and ("Von Hand (" .. (manual.by or "?") .. ")") or "Automatisch (Rang)", x2, y2, colW)
            local hours = (hist and hist.TotalHours and char._historyLoaded) and hist.TotalHours(char:GetID()) or nil
            y2 = y2 + D.KeyValue("Dienstzeit", hours and (string.format("%.1f", hours) .. " Std.") or "…", x2, y2, colW)
            y2 = y2 + D.KeyValue("Status", char:IsOnline() and "Im Dienst" or "Nicht im Dienst", x2, y2, colW, char:IsOnline() and D.col.green or D.col.muted)
            y2 = y2 + D.KeyValue("Personalnummer", "#" .. char:GetID(), x2, y2, colW)

            local y = math.max(y1, y2) + S(10)
            local faction = char:GetFaction()
            local desc = faction and faction:GetDescription() or ""
            if desc ~= "" and y < h - S(60) then
                D.Section("Einheit", 0, y, w)
                D.DrawWrapped(desc, "gdp.small", 0, y + S(30), w, D.col.dim, math.floor((h - y - S(30)) / S(18)))
            end
        end
    end

    local function ShowNotes()
        content:Clear()
        local head = D.ColumnHeader(content, "Vermerke", "Belobigungen, Verwarnungen und Notizen")
        local scroll = D.Scroll(content)
        scroll:Dock(FILL)
        local function Load()
            GAR_DP.Request("list", { kind = "personnel", target = char:GetID() }, function(data)
                if not data or not IsValid(scroll) then return end
                D.FillRecords(scroll, data.items, {
                    accent = function(item) return TypeData(item.extra and item.extra.type).color end,
                    chips = function(item) local t = TypeData(item.extra and item.extra.type) return { { t.name, t.color } } end,
                    onEdit = function(item) OpenNoteForm(char, item, Load) end,
                    onDelete = function(item)
                        D.Confirm("Vermerk löschen", "Soll der Vermerk \"" .. (item.title or "") .. "\" endgültig gelöscht werden?", function()
                            GAR_DP.Request("delete", { id = item.id }, function(res) if res then Load() end end)
                        end, "Löschen")
                    end,
                }, "Keine Vermerke in dieser Akte.")
            end)
        end
        if GAR_DP.CanWritePersonnel(LocalPlayer(), char) then
            head:AddButton("Vermerk", "primary", "plus", function() OpenNoteForm(char, nil, Load) end)
        end
        Load()
    end

    local function ShowTrainings()
        content:Clear()
        D.ColumnHeader(content, "Fortbildungen", "Eingetragen über SymChars (Verwaltung)")
        local scroll = D.Scroll(content)
        scroll:Dock(FILL)
        local list = {}
        for id, t in pairs(char:GetTrainings()) do
            local def = symchars.trainings and symchars.trainings.Get(id)
            list[#list + 1] = { id = id, def = def, data = t }
        end
        table.sort(list, function(a, b) return (a.data.at or 0) > (b.data.at or 0) end)
        if #list == 0 then
            D.FillRecords(scroll, {}, nil, "Keine Fortbildungen eingetragen.")
            return
        end
        for _, t in ipairs(list) do
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:SetTall(S(50))
            row:DockMargin(0, 0, 0, S(4))
            row.Paint = function(_, w, h)
                local col = t.def and t.def.color or D.Accent()
                local expired = t.data.exp and t.data.exp > 0 and t.data.exp < os.time()
                D.Box(0, 0, w, h, D.col.panel2)
                D.Outline(0, 0, w, h, D.col.line2)
                D.Box(0, 0, S(3), h, expired and D.col.red or col)
                D.Icon("medal", S(12), h / 2 - S(12), S(24), expired and D.col.muted or col)
                D.TextFit(t.def and t.def.name or t.id, "gdp.body.b", S(46), S(6), expired and D.col.muted or D.col.text, w * 0.6)
                D.TextFit("Eingetragen " .. GAR_DP.FormatDate(t.data.at) .. (t.data.byName and ("  ·  von " .. t.data.byName) or ""), "gdp.tiny", S(46), h - S(6), D.col.muted, w * 0.7, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                if expired then
                    local cw = D.ChipSize("Abgelaufen")
                    D.Chip("Abgelaufen", w - cw - S(10), h / 2 - S(9), D.col.red, Color(60, 10, 10, 200))
                elseif t.data.exp and t.data.exp > 0 then
                    D.Text("gültig bis " .. GAR_DP.FormatDate(t.data.exp), "gdp.tiny", w - S(10), h / 2, D.col.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end
        end
    end

    local function ShowHistory()
        content:Clear()
        D.ColumnHeader(content, "Verlauf", "Beförderungen, Versetzungen und Einträge aus SymChars")
        local scroll = D.Scroll(content)
        scroll:Dock(FILL)
        local hist = symchars.history
        local function Fill()
            if not IsValid(scroll) then return end
            scroll:Clear()
            local entries = hist and hist.Get and hist.Get(char:GetID(), "log", "entries") or {}
            if not char._historyLoaded then
                D.FillRecords(scroll, {}, nil, "Verlauf wird geladen…")
                return
            end
            local list = {}
            for _, e in ipairs(entries or {}) do list[#list + 1] = e end
            table.sort(list, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
            if #list == 0 then D.FillRecords(scroll, {}, nil, "Kein Verlauf vorhanden.") return end
            for i, e in ipairs(list) do
                if i > 80 then break end
                local row = vgui.Create("DPanel", scroll)
                row:Dock(TOP)
                row:SetTall(S(42))
                row:DockMargin(0, 0, 0, S(3))
                row.Paint = function(_, w, h)
                    local col = e.kind == "rank" and D.Accent() or e.kind == "unit" and D.col.blue or e.kind == "training" and D.col.green or D.col.dim
                    D.Box(S(6), 0, S(3), h, col)
                    D.TextFit(tostring(e.entry or ""), "gdp.body.b", S(18), S(3), D.col.text, w - S(24))
                    D.TextFit(GAR_DP.FormatDate(e.timestamp, true) .. ((e.by and e.by ~= "") and ("  ·  " .. e.by) or ""), "gdp.tiny", S(18), h - S(4), D.col.muted, w - S(24), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                end
            end
        end
        if hist and hist.Request then hist.Request(char:GetID()) end
        hook.Add("symchars_history_updated", scroll, function(_, c) if c and c:GetID() == char:GetID() then Fill() end end)
        Fill()
    end

    local tabs = D.SubTabs(parent, {
        { id = "akte", name = "Akte" },
        { id = "notes", name = "Vermerke" },
        { id = "trainings", name = "Fortbildungen" },
        { id = "history", name = "Verlauf" },
    }, function(id)
        if id == "akte" then ShowAkte() elseif id == "notes" then ShowNotes() elseif id == "trainings" then ShowTrainings() else ShowHistory() end
    end)
    tabs:Dock(TOP)
    tabs:SetTall(S(36))

    content = vgui.Create("DPanel", parent)
    content:Dock(FILL)
    content:DockMargin(0, S(8), 0, 0)
    content.Paint = nil
    ShowAkte()
end

---------------------------------------------------------------------------------------------------------------
-- App
---------------------------------------------------------------------------------------------------------------
GAR_DP.RegisterApp({
    id = "personnel",
    short = "Akten",
    name = "Personalakten",
    desc = "Akten der Soldaten: Rang, Einheit, Freigabe, Vermerke, Fortbildungen und Verlauf.",
    icon = "user",
    order = 1,
    build = function(parent, tablet, opts)
        local ply = LocalPlayer()
        local own = D.LocalChar()
        local selected = opts.char and symchars.chars.Get(opts.char) or own

        local left = vgui.Create("DPanel", parent)
        left:Dock(LEFT)
        left:SetWide(math.floor(parent:GetWide() * 0.3))
        left:DockMargin(0, 0, S(14), 0)
        left.Paint = nil

        local right = vgui.Create("DPanel", parent)
        right:Dock(FILL)
        right.Paint = function(_, w, h) D.Frame(0, 0, w, h) end
        right:DockPadding(S(14), S(12), S(14), S(12))

        local level = GAR_DP.Clearance(ply)
        local scope = GAR_DP.IsAdmin(ply) and "Alle Einheiten" or level >= CFG.PersonnelAllLevel and "Alle Einheiten" or level >= CFG.PersonnelUnitLevel and "Eigene Einheit" or "Nur eigene Akte"

        local list
        list = D.CharList(left, {
            filter = function(char) return GAR_DP.CanViewPersonnel(ply, char) end,
            onSelect = function(char)
                selected = char
                BuildDetail(right, char)
            end,
            isSelected = function(char) return selected and selected:GetID() == char:GetID() end,
            countLabel = "Akten  ·  " .. scope,
        })
        list:Dock(FILL)

        if selected and GAR_DP.CanViewPersonnel(ply, selected) then
            BuildDetail(right, selected)
        else
            D.Placeholder(right, "Wähle links eine Akte aus.", "user")
        end
    end,
})
