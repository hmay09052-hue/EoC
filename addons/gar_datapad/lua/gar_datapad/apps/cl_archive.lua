--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Dienstberichte und Klassifizierte Daten
    Beide sind Archive: Liste links, Leseansicht rechts. Alles ueber der eigenen Stufe bleibt geschwaerzt.
-------------------------------------------------------------------------------------------------------------]]

local D = GAR_DP.ui
local S = D.S
local CFG = GAR_DP.Config

local function ReportType(id) return GAR_DP.ById(CFG.ReportTypes, id) or CFG.ReportTypes[1] end

-- Textblock, der seine Hoehe selbst bestimmt; scramble = Entschluesselungs-Effekt
local GLYPHS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#%&*+=<>/"
local function TextBlock(parent, text, scramble)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p.start = RealTime()
    p.lines = {}
    p.PerformLayout = function(s, w)
        s.lines = D.Wrap(text or "", "gdp.body", w - S(4))
        local _, lh = D.TextSize("Ag", "gdp.body")
        local need = #s.lines * (lh + S(3)) + S(10)
        if s:GetTall() ~= need then s:SetTall(need) end
    end
    p.Paint = function(s, w, h)
        local _, lh = D.TextSize("Ag", "gdp.body")
        local t = scramble and math.Clamp((RealTime() - s.start) / 1.1, 0, 1) or 1
        local total = 0
        for _, l in ipairs(s.lines) do total = total + #l end
        local revealed = math.floor(total * t)
        local count = 0
        for i, line in ipairs(s.lines) do
            local out = line
            if count + #line > revealed then
                local keep = math.max(0, revealed - count)
                local tail = {}
                for c = keep + 1, #line do
                    local ch = string.sub(line, c, c)
                    if ch == " " then tail[#tail + 1] = " " else
                        local r = math.random(1, #GLYPHS)
                        tail[#tail + 1] = string.sub(GLYPHS, r, r)
                    end
                end
                out = string.sub(line, 1, keep) .. table.concat(tail)
            end
            count = count + #line
            draw.SimpleText(out, "gdp.body", 0, (i - 1) * (lh + S(3)), count > revealed and D.Accent(200) or D.col.text)
        end
    end
    return p
end

---------------------------------------------------------------------------------------------------------------
-- Formular
---------------------------------------------------------------------------------------------------------------
local function OpenForm(kind, item, onSaved)
    local isReport = kind == "report"
    local card = D.Modal(item and "Bearbeiten" or (isReport and "Neuer Bericht" or "Neue Akte"), S(700), S(640))
    if not card then return end
    local myLevel = GAR_DP.Clearance(LocalPlayer())
    local extra = item and item.extra or {}

    local row = vgui.Create("DPanel", card)
    row:Dock(TOP)
    row:SetTall(S(54))
    row:DockMargin(0, 0, 0, S(8))
    row.Paint = nil

    local typeField = D.Field(row, isReport and "Berichtstyp" or "Kategorie", S(32), LEFT)
    typeField:SetWide(S(300))
    typeField:DockMargin(0, 0, S(10), 0)
    local typeCombo = D.Combo(typeField)
    typeCombo:Dock(FILL)

    local levelField = D.Field(row, "Sicherheitsstufe", S(32), FILL)
    local levelCombo

    local function FillLevels()
        local minLevel = 1
        if isReport then minLevel = ReportType(typeCombo:GetSelectedData()).level end
        local current = levelCombo and levelCombo:GetSelectedData() or (item and item.level) or minLevel
        if IsValid(levelCombo) then levelCombo:Remove() end
        levelCombo = D.LevelCombo(levelField, math.max(current, minLevel), myLevel, math.min(minLevel, myLevel))
        levelCombo:Dock(FILL)
    end

    if isReport then
        for _, t in ipairs(CFG.ReportTypes) do
            if t.level <= myLevel then typeCombo:AddChoice(t.name .. "  (ab Stufe " .. t.level .. ")", t.id, t.id == (extra.type or CFG.ReportTypes[1].id)) end
        end
        if not typeCombo:GetSelectedData() then typeCombo:ChooseData(CFG.ReportTypes[1].id) end
        typeCombo.OnSelect = function() FillLevels() end
    else
        for _, c in ipairs(CFG.ClassifiedCategories) do typeCombo:AddChoice(c, c, c == (extra.category or CFG.ClassifiedCategories[1])) end
    end
    FillLevels()

    local titleField = D.Field(card, "Titel", S(34))
    local title = D.Entry(titleField, isReport and "z.B. Patrouille Sektor 7, Feindkontakt" or "z.B. Droidenfabrik auf Geonosis", item and item.title)
    title:Dock(FILL)

    local location, participants
    if isReport then
        local row2 = vgui.Create("DPanel", card)
        row2:Dock(TOP)
        row2:SetTall(S(54))
        row2:DockMargin(0, 0, 0, S(8))
        row2.Paint = nil
        local locField = D.Field(row2, "Ort", S(32), LEFT)
        locField:SetWide(S(250))
        locField:DockMargin(0, 0, S(10), 0)
        location = D.Entry(locField, "Planet / Sektor", extra.location)
        location:Dock(FILL)
        local partField = D.Field(row2, "Beteiligte", S(32), FILL)
        participants = D.Entry(partField, "z.B. 501st Torrent Company, CT-7567", extra.participants)
        participants:Dock(FILL)
    end

    local buttons = vgui.Create("DPanel", card)
    buttons:Dock(BOTTOM)
    buttons:SetTall(S(44))
    buttons:DockMargin(0, S(8), 0, 0)
    buttons.Paint = nil

    local textField = D.Field(card, isReport and "Bericht" or "Inhalt", S(80), FILL)
    local text = D.Entry(textField, isReport and "Ablauf, Ergebnisse, Verluste, Empfehlungen…" or "Inhalt der Akte…", item and item.body, true)
    text:Dock(FILL)

    local save = D.Button(buttons, "Speichern", "primary", function()
        local ex = isReport and { type = typeCombo:GetSelectedData(), location = location:GetValue(), participants = participants:GetValue() }
            or { category = typeCombo:GetSelectedData() }
        GAR_DP.Request("save", {
            id = item and item.id, kind = kind, title = title:GetValue(), body = text:GetValue(),
            level = levelCombo:GetSelectedData(), extra = ex,
        }, function(res)
            if not res then return end
            card:Close()
            GAR_DP.Notify(isReport and "Bericht gespeichert." or "Akte gespeichert.", "info")
            if onSaved then onSaved(res.id) end
        end)
    end)
    save:Dock(RIGHT)
    save:SetWide(S(200))
    local cancel = D.Button(buttons, "Abbrechen", "default", function() card:Close() end)
    cancel:Dock(LEFT)
    cancel:SetWide(S(160))
end

---------------------------------------------------------------------------------------------------------------
-- Archiv-Ansicht
---------------------------------------------------------------------------------------------------------------
local function BuildArchive(parent, kind)
    local isReport = kind == "report"
    local myLevel = GAR_DP.Clearance(LocalPlayer())
    local items, selectedID = {}, nil
    local filter, levelFilter = nil, 0

    local left = vgui.Create("DPanel", parent)
    left:Dock(LEFT)
    left:SetWide(math.floor(parent:GetWide() * 0.42))
    left:DockMargin(0, 0, S(14), 0)
    left.Paint = nil

    local right = vgui.Create("DPanel", parent)
    right:Dock(FILL)
    right.Paint = function(_, w, h) D.Frame(0, 0, w, h) end
    right:DockPadding(S(16), S(12), S(16), S(12))

    local canCreate = isReport or myLevel >= CFG.ClassifiedCreateLevel
    local head = D.ColumnHeader(left, isReport and "Dienstberichte" or "Archiv", function() return #items .. " Einträge  ·  deine Freigabe: Stufe " .. myLevel end)
    local reload

    if canCreate then
        head:AddButton(isReport and "Bericht" or "Akte", "primary", "plus", function() OpenForm(kind, nil, function(id) selectedID = id reload() end) end)
    end

    local tools = vgui.Create("DPanel", left)
    tools:Dock(TOP)
    tools:SetTall(S(34))
    tools:DockMargin(0, 0, 0, S(6))
    tools.Paint = nil

    local combo = D.Combo(tools, isReport and "Alle Typen" or "Alle Kategorien")
    combo:Dock(LEFT)
    combo:SetWide(S(190))
    combo:DockMargin(0, 0, S(6), 0)
    combo:AddChoice(isReport and "Alle Typen" or "Alle Kategorien", nil, true)
    if isReport then
        for _, t in ipairs(CFG.ReportTypes) do combo:AddChoice(t.name, t.id) end
    else
        for _, c in ipairs(CFG.ClassifiedCategories) do combo:AddChoice(c, c) end
    end

    local search = D.Entry(tools, "Suchen…")
    search:Dock(FILL)

    -- Stufenfilter (0 = alle)
    local levels = vgui.Create("DPanel", left)
    levels:Dock(TOP)
    levels:SetTall(S(26))
    levels:DockMargin(0, 0, 0, S(6))
    levels.Paint = nil
    for lvl = 0, 6 do
        local b = vgui.Create("DButton", levels)
        b:SetText("")
        b:Dock(LEFT)
        b:SetWide(lvl == 0 and S(54) or S(38))
        b:DockMargin(0, 0, S(4), 0)
        b:SetCursor("hand")
        b.Paint = function(s, w, h)
            local on = levelFilter == lvl
            local col = lvl == 0 and D.Accent() or GAR_DP.LevelData(lvl).color
            local locked = lvl > myLevel
            D.Box(0, 0, w, h, on and D.Alpha(col, 50) or Color(8, 10, 13, 220))
            D.Outline(0, 0, w, h, D.Alpha(col, on and 255 or (s:IsHovered() and 170 or 70)))
            D.Text(lvl == 0 and "ALLE" or ("S" .. lvl), "gdp.tiny.b", w / 2, h / 2, locked and D.Alpha(col, 110) or col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return true
        end
        b.DoClick = function() D.Sound("click") levelFilter = lvl reload(true) end
    end

    local scroll = D.Scroll(left)
    scroll:Dock(FILL)

    local placeholderText = isReport and "Wähle links einen Bericht aus" or "Wähle links eine Akte aus"
    local function ShowItem(id)
        selectedID = id
        right:Clear()
        -- Zurueck: erst die Leseansicht schliessen
        if IsValid(GAR_DP.tablet) then
            GAR_DP.tablet:SetBackHandler(function()
                if not IsValid(right) then return false end
                selectedID = nil
                right:Clear()
                D.Placeholder(right, placeholderText, isReport and "doc" or "lock")
                reload(true)
            end)
        end
        GAR_DP.Request("get", { id = id }, function(item)
            if not item or not IsValid(right) then return end
            right:Clear()
            local ld = GAR_DP.LevelData(item.level)

            local stamp = vgui.Create("DPanel", right)
            stamp:Dock(TOP)
            stamp:SetTall(S(30))
            stamp:DockMargin(0, 0, 0, S(10))
            stamp.Paint = function(_, w, h)
                D.Box(0, 0, w, h, D.Alpha(ld.color, 30))
                D.Outline(0, 0, w, h, D.Alpha(ld.color, 170))
                for sx = -h, w, S(18) do
                    surface.SetDrawColor(ld.color.r, ld.color.g, ld.color.b, 22)
                    surface.DrawLine(sx, h, sx + h, 0)
                end
                local label = item.redacted and "ZUGRIFF VERWEIGERT" or ((item.level >= 4 and "KLASSIFIZIERT" or "VERTRAULICH") .. "  ·  STUFE " .. item.level .. "  ·  " .. string.upper(ld.name))
                D.Text(label, "gdp.h4", w / 2, h / 2, ld.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            if item.redacted then
                local p = vgui.Create("DPanel", right)
                p:Dock(FILL)
                p.Paint = function(_, w, h)
                    D.Icon("lock", w / 2 - S(30), h * 0.3 - S(30), S(60), D.col.red)
                    D.Text("FREIGABE STUFE " .. item.level .. " ERFORDERLICH", "gdp.h2", w / 2, h * 0.3 + S(44), D.col.red, TEXT_ALIGN_CENTER)
                    D.Text("Deine Freigabe: Stufe " .. myLevel, "gdp.body", w / 2, h * 0.3 + S(80), D.col.dim, TEXT_ALIGN_CENTER)
                    for i = 0, 5 do D.Redacted(S(40), h * 0.55 + i * S(26), w - S(80), S(16), item.id * 7 + i) end
                end
                return
            end

            local top = vgui.Create("DPanel", right)
            top:Dock(TOP)
            top:SetTall(S(108))
            top.Paint = function(_, w, h)
                D.TextFit(item.title, "gdp.h1", 0, -S(4), D.col.text, w - S(80))
                D.Aurebesh(item.title, "gdp.aure", S(1), S(34), D.Alpha(D.col.dim, 110), nil, nil, w - S(80))
                local colW = (w - S(20)) / 3
                local ex = item.extra or {}
                local y = S(56)
                if isReport then
                    D.KeyValue("Typ", ReportType(ex.type).name, 0, y, colW - S(10))
                    D.KeyValue("Ort", (ex.location and ex.location ~= "") and ex.location or "-", colW + S(10), y, colW - S(10))
                else
                    D.KeyValue("Kategorie", ex.category or "-", 0, y, colW - S(10))
                    D.KeyValue("Aktualisiert", GAR_DP.FormatDate(item.updated, true), colW + S(10), y, colW - S(10))
                end
                D.KeyValue("Verfasser  ·  " .. GAR_DP.FormatDate(item.created, true), item.authorName or "-", colW * 2 + S(20), y, colW - S(10))
            end

            if isReport and item.extra and item.extra.participants and item.extra.participants ~= "" then
                local part = vgui.Create("DPanel", right)
                part:Dock(TOP)
                part:SetTall(S(26))
                part.Paint = function(_, w, h)
                    D.Text("BETEILIGTE", "gdp.tiny.b", 0, h / 2, D.col.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    D.TextFit(item.extra.participants, "gdp.small", S(80), h / 2, D.col.dim, w - S(80), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end

            local line = vgui.Create("DPanel", right)
            line:Dock(TOP)
            line:SetTall(S(12))
            line.Paint = function(_, w, h) D.Box(0, h / 2, w, 1, D.col.line2) D.Box(0, h / 2, S(60), S(2), D.Accent()) end

            local bodyScroll = D.Scroll(right)
            bodyScroll:Dock(FILL)
            bodyScroll:DockMargin(0, S(6), 0, 0)
            TextBlock(bodyScroll, item.body ~= "" and item.body or "(kein Inhalt)", not isReport or item.level >= 4)

            -- Knoepfe oben rechts
            local x = 0
            local function Btn(icon, fn)
                local b = D.Button(right, "", "icon", fn)
                b:SetIcon(icon)
                b:SetSize(S(32), S(32))
                local baseThink = b.Think
                b.Think = function(s)
                    baseThink(s)
                    s:SetPos(right:GetWide() - S(16) - S(34) * (s.slot or 1), S(50))
                end
                x = x + 1
                b.slot = x
                return b
            end
            if item.canDelete then
                Btn("trash", function()
                    D.Confirm("Löschen", "Soll \"" .. item.title .. "\" endgültig gelöscht werden?", function()
                        GAR_DP.Request("delete", { id = item.id }, function(res)
                            if not res then return end
                            selectedID = nil
                            right:Clear()
                            reload()
                        end)
                    end, "Löschen")
                end)
            end
            if item.canEdit then
                Btn("edit", function() OpenForm(kind, item, function() reload() ShowItem(item.id) end) end)
            end
        end)
    end

    function reload(localOnly)
        local function Fill()
            if not IsValid(scroll) then return end
            scroll:Clear()
            local q = string.lower(string.Trim(search:GetValue() or ""))
            local f = combo:GetSelectedData()
            local shown = {}
            for _, item in ipairs(items) do
                local ok = levelFilter == 0 or item.level == levelFilter
                if ok and f then
                    local ex = item.extra or {}
                    ok = (isReport and ex.type == f) or (not isReport and ex.category == f)
                end
                if ok and q ~= "" then
                    ok = not item.redacted and string.find(string.lower((item.title or "") .. " " .. (item.authorName or "") .. " " .. (item.preview or "")), q, 1, true) ~= nil
                end
                if ok then shown[#shown + 1] = item end
            end
            D.FillRecords(scroll, shown, {
                maxLines = 2,
                accent = function(item) return GAR_DP.LevelData(item.level).color end,
                chips = function(item)
                    if isReport then local t = ReportType(item.extra and item.extra.type) return { { t.name, D.col.dim } } end
                    return { { (item.extra and item.extra.category) or "-", D.col.dim } }
                end,
                onClick = function(item) ShowItem(item.id) end,
            }, isReport and "Keine Berichte gefunden." or "Keine Akten gefunden.")
            for _, child in ipairs(scroll:GetCanvas():GetChildren()) do
                if child.item and child.item.id == selectedID then
                    local old = child.Paint
                    child.Paint = function(s, w, h) old(s, w, h) D.Outline(0, 0, w, h, D.Accent(), S(2)) end
                end
            end
        end
        if localOnly then Fill() return end
        GAR_DP.Request("list", { kind = kind }, function(data)
            if not data then return end
            items = data.items or {}
            Fill()
        end)
    end

    search.OnValueChange = function() reload(true) end
    combo.OnSelect = function() reload(true) end

    reload()
    D.Placeholder(right, placeholderText, isReport and "doc" or "lock")
end

GAR_DP.RegisterApp({
    id = "reports",
    short = "Berichte",
    name = "Dienstberichte",
    desc = "Dienst-, Patrouillen-, Einsatz- und Vorfallberichte schreiben und lesen.",
    icon = "doc",
    order = 4,
    build = function(parent) BuildArchive(parent, "report") end,
})

GAR_DP.RegisterApp({
    id = "classified",
    short = "Klassifiziert",
    name = "Klassifiziert",
    desc = "Geheimdienst-, Jedi- und Oberkommando-Akten. Sichtbar nur mit passender Freigabe.",
    icon = "lock",
    order = 5,
    build = function(parent) BuildArchive(parent, "classified") end,
})
