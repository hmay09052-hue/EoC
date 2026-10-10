--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Strafakten (nur Schocktruppen-Jobs und Admins)
    Reiter: Akten (pro Person), Fahndung (alle offenen Fahndungen), Kodex (Gesetze aus der Config)
    Jeder Eintrag hat eine Sicherheitsstufe; hoeher eingestufte Eintraege sieht man nur geschwaerzt.
-------------------------------------------------------------------------------------------------------------]]

local D = GAR_DP.ui
local S = D.S
local CFG = GAR_DP.Config

local function StatusData(id) return GAR_DP.ById(CFG.PenalStatus, id) or CFG.PenalStatus[1] end

local function LawText(id)
    local law = GAR_DP.ById(CFG.Laws, id)
    return law and ("§" .. law.id .. " " .. law.title) or nil
end

local function PenalChips(item)
    local st = StatusData(item.status)
    local chips = { { st.name, st.color } }
    if item.extra and item.extra.wanted and item.status == "offen" then table.insert(chips, 1, { "Fahndung", D.col.red }) end
    return chips
end

local function PenalMeta(item)
    local parts = {}
    local law = item.extra and LawText(item.extra.law)
    if law then parts[#parts + 1] = law end
    if item.extra and item.extra.punishment and item.extra.punishment ~= "" then parts[#parts + 1] = "Strafe: " .. item.extra.punishment end
    parts[#parts + 1] = (item.authorName or "") .. "  ·  " .. GAR_DP.FormatDate(item.created, true)
    return table.concat(parts, "   ·   ")
end

---------------------------------------------------------------------------------------------------------------
-- Formular
---------------------------------------------------------------------------------------------------------------
local function OpenPenalForm(char, item, onSaved)
    local card = D.Modal(item and "Eintrag bearbeiten" or ("Strafakte  ·  " .. D.CharName(char)), S(680), S(640))
    if not card then return end
    local myLevel = GAR_DP.Clearance(LocalPlayer())
    local extra = item and item.extra or {}

    local row1 = vgui.Create("DPanel", card)
    row1:Dock(TOP)
    row1:SetTall(S(54))
    row1:DockMargin(0, 0, 0, S(8))
    row1.Paint = nil

    local lawField = D.Field(row1, "Paragraph (Kodex)", S(32), LEFT)
    lawField:SetWide(S(340))
    lawField:DockMargin(0, 0, S(10), 0)
    local lawCombo = D.Combo(lawField, "Kein Paragraph")
    lawCombo:Dock(FILL)
    lawCombo:AddChoice("Kein Paragraph", "", (extra.law or "") == "")
    for _, law in ipairs(CFG.Laws) do lawCombo:AddChoice("§" .. law.id .. "  " .. law.title, law.id, law.id == extra.law) end

    local statusField = D.Field(row1, "Status", S(32), FILL)
    local statusCombo = D.Combo(statusField)
    statusCombo:Dock(FILL)
    for _, st in ipairs(CFG.PenalStatus) do statusCombo:AddChoice(st.name, st.id, st.id == (item and item.status or CFG.PenalStatus[1].id), st.color) end

    local titleField = D.Field(card, "Vergehen", S(34))
    local title = D.Entry(titleField, "z.B. Befehlsverweigerung im Einsatz", item and item.title)
    title:Dock(FILL)

    local row2 = vgui.Create("DPanel", card)
    row2:Dock(TOP)
    row2:SetTall(S(54))
    row2:DockMargin(0, 0, 0, S(8))
    row2.Paint = nil
    local punField = D.Field(row2, "Strafe", S(32), LEFT)
    punField:SetWide(S(340))
    punField:DockMargin(0, 0, S(10), 0)
    local punishment = D.Entry(punField, "z.B. 10 Min. Arrest", extra.punishment)
    punishment:Dock(FILL)
    local levelField = D.Field(row2, "Sicherheitsstufe", S(32), FILL)
    local levelCombo = D.LevelCombo(levelField, item and item.level or 1, myLevel)
    levelCombo:Dock(FILL)

    lawCombo.OnSelect = function(_, id)
        local law = GAR_DP.ById(CFG.Laws, id)
        if not law then return end
        if string.Trim(title:GetValue()) == "" then title:SetValue(law.title) end
        if string.Trim(punishment:GetValue()) == "" then punishment:SetValue(law.punishment or "") end
    end

    local wanted = D.Check(card, "Zur Fahndung ausschreiben", extra.wanted == true)
    wanted:Dock(TOP)
    wanted:SetTall(S(30))
    wanted:DockMargin(0, 0, 0, S(8))

    local buttons = vgui.Create("DPanel", card)
    buttons:Dock(BOTTOM)
    buttons:SetTall(S(44))
    buttons:DockMargin(0, S(8), 0, 0)
    buttons.Paint = nil

    local textField = D.Field(card, "Sachverhalt", S(80), FILL)
    local text = D.Entry(textField, "Was ist passiert? Zeugen, Ort, Zeit…", item and item.body, true)
    text:Dock(FILL)

    local save = D.Button(buttons, "Speichern", "primary", function()
        GAR_DP.Request("save", {
            id = item and item.id, kind = "penal", target = char:GetID(),
            title = title:GetValue(), body = text:GetValue(), level = levelCombo:GetSelectedData(),
            status = statusCombo:GetSelectedData(),
            extra = { law = lawCombo:GetSelectedData() or "", punishment = punishment:GetValue(), wanted = wanted:GetChecked() },
        }, function(res)
            if not res then return end
            card:Close()
            GAR_DP.Notify("Strafakte gespeichert.", "info")
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
-- Reiter: Akten
---------------------------------------------------------------------------------------------------------------
local function BuildFiles(parent, startChar)
    local selected
    local list
    local left = vgui.Create("DPanel", parent)
    left:Dock(LEFT)
    left:SetWide(math.floor(parent:GetWide() * 0.3))
    left:DockMargin(0, 0, S(14), 0)
    left.Paint = nil

    local right = vgui.Create("DPanel", parent)
    right:Dock(FILL)
    right.Paint = function(_, w, h) D.Frame(0, 0, w, h) end
    right:DockPadding(S(14), S(12), S(14), S(12))

    local counts = {}

    local function ShowChar(char)
        selected = char
        right:Clear()
        if IsValid(GAR_DP.tablet) then
            GAR_DP.tablet:SetBackHandler(function()
                if not IsValid(right) then return false end
                selected = nil
                right:Clear()
                D.Placeholder(right, "Person auswählen", "shield")
                list:Refresh()
            end)
        end
        local items = {}
        D.PersonHeader(right, char, function()
            local open, total = 0, 0
            for _, it in ipairs(items) do
                total = total + 1
                if it.status == "offen" then open = open + 1 end
            end
            return { { total .. " Einträge", D.col.dim }, { open .. " offen", open > 0 and D.col.yellow or D.col.muted } }
        end)
        local head = D.ColumnHeader(right, "Strafregister", "Einträge mit höherer Stufe als deiner sind geschwärzt")
        local scroll = D.Scroll(right)
        scroll:Dock(FILL)
        local function Load()
            GAR_DP.Request("list", { kind = "penal", target = char:GetID() }, function(data)
                if not data or not IsValid(scroll) then return end
                items = data.items or {}
                counts[char:GetID()] = #items
                D.FillRecords(scroll, items, {
                    accent = function(item) return StatusData(item.status).color end,
                    chips = PenalChips,
                    meta = PenalMeta,
                    onEdit = function(item) OpenPenalForm(char, item, Load) end,
                    onDelete = function(item)
                        D.Confirm("Eintrag löschen", "Soll der Eintrag \"" .. (item.title or "") .. "\" aus der Strafakte gelöscht werden?", function()
                            GAR_DP.Request("delete", { id = item.id }, function(res) if res then Load() end end)
                        end, "Löschen")
                    end,
                }, "Keine Einträge. Weste ist sauber.")
            end)
        end
        head:AddButton("Eintrag", "primary", "plus", function() OpenPenalForm(char, nil, Load) end)
        Load()
    end

    list = D.CharList(left, {
        onSelect = ShowChar,
        isSelected = function(char) return selected and selected:GetID() == char:GetID() end,
        countLabel = "Personen",
    })
    list:Dock(FILL)

    if startChar then ShowChar(startChar) else D.Placeholder(right, "Person auswählen", "shield") end
end

---------------------------------------------------------------------------------------------------------------
-- Reiter: Fahndung
---------------------------------------------------------------------------------------------------------------
local function BuildWanted(parent, openFile)
    D.ColumnHeader(parent, "Fahndungsliste", "Alle offenen Fahndungen  ·  online gesuchte Personen stehen oben")
    local scroll = D.Scroll(parent)
    scroll:Dock(FILL)
    GAR_DP.Request("list", { kind = "penal", wanted = true }, function(data)
        if not data or not IsValid(scroll) then return end
        local items = data.items or {}
        table.sort(items, function(a, b)
            local ca, cb = symchars.chars.Get(a.target), symchars.chars.Get(b.target)
            local oa, ob = ca and ca:IsOnline() or false, cb and cb:IsOnline() or false
            if oa ~= ob then return oa end
            return (a.created or 0) > (b.created or 0)
        end)
        scroll:Clear()
        if #items == 0 then D.FillRecords(scroll, {}, nil, "Keine offenen Fahndungen.") return end
        for _, item in ipairs(items) do
            local char = symchars.chars.Get(item.target)
            local row = vgui.Create("DButton", scroll)
            row:Dock(TOP)
            row:SetTall(S(70))
            row:DockMargin(0, 0, 0, S(5))
            row:SetText("")
            row._hover = 0
            row.Think = function(s) s._hover = D.Approach(s._hover, s:IsHovered() and 1 or 0, 14) end
            row.DoClick = function() if char then D.Sound("click") openFile(char) end end
            row.Paint = function(s, w, h)
                local online = char and char:IsOnline()
                local pulse = online and (0.5 + 0.5 * math.sin(RealTime() * 5)) or 0
                D.Box(0, 0, w, h, D.Lerp(s._hover, Color(24, 8, 8, 220), Color(40, 12, 12, 235)))
                D.Outline(0, 0, w, h, D.Alpha(D.col.red, 90 + s._hover * 100 + pulse * 60))
                D.Box(0, 0, S(4), h, D.col.red)
                D.Icon("target", S(14), h / 2 - S(18), S(36), D.Alpha(D.col.red, 160 + pulse * 95))
                if item.redacted then
                    D.Redacted(S(62), S(12), S(260), S(16), item.id)
                    D.Text("GESCHWÄRZT  ·  STUFE " .. item.level, "gdp.tiny.b", S(62), h - S(10), D.col.red, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                    return true
                end
                D.TextFit(char and D.CharName(char) or "Unbekannt", "gdp.h3", S(62), S(4), D.col.text, w * 0.5)
                local rank = char and D.CharRank(char) or ""
                D.TextFit((rank ~= "" and (rank .. "  ·  ") or "") .. (char and D.CharUnit(char) or ""), "gdp.small", S(62), S(30), D.col.dim, w * 0.5)
                D.TextFit(item.title .. ((item.extra and item.extra.punishment ~= "") and ("   ·   " .. item.extra.punishment) or ""), "gdp.small.b", S(62), h - S(6), D.col.red, w - S(80), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                local status = online and "AKTIV IM SEKTOR" or "NICHT ONLINE"
                local cw = D.ChipSize(status)
                D.Chip(status, w - cw - S(12), S(10), online and D.col.red or D.col.muted, online and Color(70, 10, 10, 230) or D.col.panel3)
                D.LevelChip(item.level, w - cw - S(12) - D.ChipSize("Stufe " .. item.level) - S(6), S(10))
                D.Text(GAR_DP.FormatDate(item.created, true), "gdp.tiny", w - S(12), h - S(8), D.col.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
                return true
            end
        end
    end)
end

---------------------------------------------------------------------------------------------------------------
-- Reiter: Kodex
---------------------------------------------------------------------------------------------------------------
local function BuildCodex(parent)
    D.ColumnHeader(parent, "Militärkodex der GAR", "Paragraphen und empfohlene Strafen")
    local scroll = D.Scroll(parent)
    scroll:Dock(FILL)
    for _, law in ipairs(CFG.Laws) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, S(5))
        row:SetTall(S(60))
        row.PerformLayout = function(s, w)
            local need = S(34) + #D.Wrap(law.text or "", "gdp.small", w - S(120)) * S(18) + S(8)
            if s:GetTall() ~= need then s:SetTall(need) end
        end
        row.Paint = function(_, w, h)
            D.Box(0, 0, w, h, D.col.panel2)
            D.Outline(0, 0, w, h, D.col.line2)
            D.Text("§" .. law.id, "gdp.h2", S(14), S(6), D.Accent())
            D.TextFit(law.title, "gdp.body.b", S(96), S(8), D.col.text, w * 0.55)
            local cw = D.ChipSize(law.punishment or "")
            if law.punishment and law.punishment ~= "" then D.Chip(law.punishment, w - cw - S(12), S(9), D.col.yellow, Color(50, 40, 10, 220), D.Alpha(D.col.yellow, 140)) end
            D.DrawWrapped(law.text or "", "gdp.small", S(96), S(32), w - S(120), D.col.dim)
        end
    end
end

---------------------------------------------------------------------------------------------------------------
-- App
---------------------------------------------------------------------------------------------------------------
GAR_DP.RegisterApp({
    id = "penal",
    short = "Strafakten",
    name = "Strafakten",
    desc = "Strafregister, Fahndungsliste und Militärkodex. Zugriff nur für Schocktruppen.",
    icon = "shield",
    order = 2,
    build = function(parent, tablet, opts)
        local content
        local function Show(id, char)
            content:Clear()
            if id == "files" then BuildFiles(content, char)
            elseif id == "wanted" then BuildWanted(content, function(c) parent.tabs:SetActive("files", true) Show("files", c) end)
            else BuildCodex(content) end
        end
        local tabs = D.SubTabs(parent, {
            { id = "files", name = "Akten" },
            { id = "wanted", name = "Fahndung" },
            { id = "codex", name = "Kodex" },
        }, function(id) Show(id) end)
        tabs:Dock(TOP)
        tabs:SetTall(S(36))
        parent.tabs = tabs

        content = vgui.Create("DPanel", parent)
        content:Dock(FILL)
        content:DockMargin(0, S(10), 0, 0)
        content.Paint = nil
        parent:InvalidateLayout(true)
        content:InvalidateLayout(true)
        Show("files")
    end,
})
