--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Medizin (nur Sanitaeter-Jobs und Admins)
    Reiter: Patienten (live aus Kraken's Medical System), Krankenakten (Behandlungen, Diagnosen, Tauglichkeit)
-------------------------------------------------------------------------------------------------------------]]

local D = GAR_DP.ui
local S = D.S
local CFG = GAR_DP.Config

local TRIAGE = {
    [0] = { name = "Keine Triage", color = Color(101, 107, 117) },
    [1] = { name = "T1 Sofort", color = Color(225, 88, 88) },
    [2] = { name = "T2 Dringend", color = Color(255, 190, 50) },
    [3] = { name = "T3 Leicht", color = Color(74, 203, 130) },
    [4] = { name = "T4 Verstorben", color = Color(60, 60, 60) },
}

local PART_NAMES = { head = "Kopf", torso = "Torso", arm_l = "Linker Arm", arm_r = "Rechter Arm", leg_l = "Linkes Bein", leg_r = "Rechtes Bein" }

local function TypeData(id) return GAR_DP.ById(CFG.MedicalTypes, id) or CFG.MedicalTypes[1] end

-- Gesamtzustand eines Patienten: Text, Farbe, Dringlichkeit (hoeher = zuerst)
local function Condition(p)
    if not p.alive then return "VERSTORBEN", Color(120, 120, 120), 0 end
    if p.kms then
        if p.arrest then return "HERZSTILLSTAND", D.col.red, 100 end
        if not p.conscious then return "BEWUSSTLOS", D.col.red, 90 end
        if (p.blood or 100) < 60 or (p.bleed or 0) > 2 then return "KRITISCH", D.col.red, 80 end
        if (p.blood or 100) < 85 or (p.bleed or 0) > 0 then return "VERLETZT", D.col.yellow, 50 end
        for _, part in ipairs(p.parts or {}) do
            if part.open > 0 or part.frac then return "VERLETZT", D.col.yellow, 40 end
        end
        return "STABIL", D.col.green, 0
    end
    local frac = p.hp / math.max(1, p.maxhp)
    if frac < 0.3 then return "KRITISCH", D.col.red, 80 end
    if frac < 0.9 then return "VERLETZT", D.col.yellow, 40 end
    return "STABIL", D.col.green, 0
end

local function Bar(x, y, w, h, frac, col)
    D.Box(x, y, w, h, Color(255, 255, 255, 18))
    D.Box(x, y, w * math.Clamp(frac, 0, 1), h, col)
end

---------------------------------------------------------------------------------------------------------------
-- Koerperschema
---------------------------------------------------------------------------------------------------------------
local function PartColor(part)
    if not part then return D.Alpha(D.col.line3, 80) end
    if part.open > 0 then
        return part.worst >= 3 and D.col.red or part.worst == 2 and Color(240, 120, 60) or D.col.yellow
    end
    if part.frac and not part.splint then return Color(200, 120, 240) end
    if part.bandaged > 0 or part.splint then return D.col.blue end
    return D.Alpha(D.col.green, 170)
end

local function DrawBody(x, y, s, parts)
    local byId = {}
    for _, p in ipairs(parts or {}) do byId[p.id] = p end
    local cx = x + s / 2
    local function Shape(id, sx, sy, sw, sh)
        local col = PartColor(byId[id])
        D.Cut(sx, sy, sw, sh, D.Alpha(col, 80), S(4), "tlbr")
        D.CutOutline(sx, sy, sw, sh, col, S(4), "tlbr")
        local part = byId[id]
        if part and part.tq then D.Box(sx - S(2), sy + S(4), sw + S(4), S(3), D.col.red) end
        if part and part.frac then D.Text("✕", "gdp.small.b", sx + sw / 2, sy + sh / 2, Color(200, 120, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
    end
    local u = s / 10
    D.Circle(cx, y + u * 0.9, u * 0.8, D.Alpha(PartColor(byId.head), 80), 20)
    D.Ring(cx, y + u * 0.9, u * 0.8, PartColor(byId.head), S(2), 20)
    Shape("torso", cx - u * 1.3, y + u * 1.9, u * 2.6, u * 3.4)
    Shape("arm_r", cx - u * 2.4, y + u * 2, u * 0.95, u * 3.4)
    Shape("arm_l", cx + u * 1.45, y + u * 2, u * 0.95, u * 3.4)
    Shape("leg_r", cx - u * 1.25, y + u * 5.45, u * 1.1, u * 4.2)
    Shape("leg_l", cx + u * 0.15, y + u * 5.45, u * 1.1, u * 4.2)
end

---------------------------------------------------------------------------------------------------------------
-- Formular Krankenakte
---------------------------------------------------------------------------------------------------------------
local function OpenMedForm(char, item, onSaved)
    local card = D.Modal(item and "Eintrag bearbeiten" or ("Krankenakte  ·  " .. D.CharName(char)), S(640), S(560))
    if not card then return end
    local myLevel = GAR_DP.Clearance(LocalPlayer())
    local extra = item and item.extra or {}

    local row = vgui.Create("DPanel", card)
    row:Dock(TOP)
    row:SetTall(S(54))
    row:DockMargin(0, 0, 0, S(8))
    row.Paint = nil

    local typeField = D.Field(row, "Art", S(32), LEFT)
    typeField:SetWide(S(180))
    typeField:DockMargin(0, 0, S(10), 0)
    local typeCombo = D.Combo(typeField)
    typeCombo:Dock(FILL)
    for _, t in ipairs(CFG.MedicalTypes) do typeCombo:AddChoice(t.name, t.id, t.id == (extra.type or CFG.MedicalTypes[1].id), t.color) end

    local fitField = D.Field(row, "Tauglichkeit", S(32), LEFT)
    fitField:SetWide(S(220))
    fitField:DockMargin(0, 0, S(10), 0)
    local fitCombo = D.Combo(fitField, "Unverändert")
    fitCombo:Dock(FILL)
    fitCombo:AddChoice("Unverändert", nil, extra.fitness == nil)
    for _, f in ipairs(CFG.Fitness) do fitCombo:AddChoice(f.name, f.id, f.id == extra.fitness, f.color) end

    local levelField = D.Field(row, "Stufe", S(32), FILL)
    local levelCombo = D.LevelCombo(levelField, item and item.level or 1, myLevel)
    levelCombo:Dock(FILL)

    local titleField = D.Field(card, "Titel / Diagnose", S(34))
    local title = D.Entry(titleField, "z.B. Schussverletzung linkes Bein, versorgt", item and item.title)
    title:Dock(FILL)

    local buttons = vgui.Create("DPanel", card)
    buttons:Dock(BOTTOM)
    buttons:SetTall(S(38))
    buttons:DockMargin(0, S(8), 0, 0)
    buttons.Paint = nil

    local textField = D.Field(card, "Befund / Behandlung", S(80), FILL)
    local text = D.Entry(textField, "Verletzungen, verabreichte Medikamente, Empfehlungen…", item and item.body, true)
    text:Dock(FILL)

    local save = D.Button(buttons, "Speichern", "primary", function()
        GAR_DP.Request("save", {
            id = item and item.id, kind = "medical", target = char:GetID(),
            title = title:GetValue(), body = text:GetValue(), level = levelCombo:GetSelectedData(),
            extra = { type = typeCombo:GetSelectedData(), fitness = fitCombo:GetSelectedData() },
        }, function(res)
            if not res then return end
            card:Close()
            GAR_DP.Notify("Krankenakte gespeichert.", "info")
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
-- Reiter: Krankenakten
---------------------------------------------------------------------------------------------------------------
local function BuildRecords(parent, startChar)
    local selected
    local left = vgui.Create("DPanel", parent)
    left:Dock(LEFT)
    left:SetWide(math.floor(parent:GetWide() * 0.3))
    left:DockMargin(0, 0, S(14), 0)
    left.Paint = nil

    local right = vgui.Create("DPanel", parent)
    right:Dock(FILL)
    right.Paint = function(_, w, h) D.Panel(0, 0, w, h, { fill = Color(9, 11, 14, 200), stroke = D.col.line, cut = S(12), corners = "tlbr" }) end
    right:DockPadding(S(14), S(12), S(14), S(12))

    local function ShowChar(char)
        selected = char
        right:Clear()
        local fitness
        D.PersonHeader(right, char, function()
            if not fitness then return {} end
            return { { fitness.name, fitness.color } }
        end)
        local head = D.ColumnHeader(right, "Krankenakte", "Behandlungen, Diagnosen und Tauglichkeit")
        local scroll = D.Scroll(right)
        scroll:Dock(FILL)
        local function Load()
            GAR_DP.Request("list", { kind = "medical", target = char:GetID() }, function(data)
                if not data or not IsValid(scroll) then return end
                fitness = nil
                for _, it in ipairs(data.items or {}) do
                    if not it.redacted and it.extra and it.extra.fitness then fitness = GAR_DP.ById(CFG.Fitness, it.extra.fitness) break end
                end
                D.FillRecords(scroll, data.items, {
                    accent = function(item) return TypeData(item.extra and item.extra.type).color end,
                    chips = function(item)
                        local chips = { { TypeData(item.extra and item.extra.type).name, TypeData(item.extra and item.extra.type).color } }
                        local f = item.extra and GAR_DP.ById(CFG.Fitness, item.extra.fitness)
                        if f then chips[#chips + 1] = { f.name, f.color } end
                        return chips
                    end,
                    onEdit = function(item) OpenMedForm(char, item, Load) end,
                    onDelete = function(item)
                        D.Confirm("Eintrag löschen", "Soll der Eintrag \"" .. (item.title or "") .. "\" gelöscht werden?", function()
                            GAR_DP.Request("delete", { id = item.id }, function(res) if res then Load() end end)
                        end, "Löschen")
                    end,
                }, "Keine Einträge in der Krankenakte.")
            end)
        end
        head:AddButton("Eintrag", "primary", "plus", function() OpenMedForm(char, nil, Load) end)
        Load()
    end

    local list = D.CharList(left, {
        onSelect = ShowChar,
        isSelected = function(char) return selected and selected:GetID() == char:GetID() end,
        countLabel = "Patienten",
    })
    list:Dock(FILL)

    if startChar then ShowChar(startChar) else D.Placeholder(right, "Wähle links einen Patienten aus.", "medic") end
end

---------------------------------------------------------------------------------------------------------------
-- Reiter: Patienten (live)
---------------------------------------------------------------------------------------------------------------
local function BuildLive(parent, openRecords)
    local patients, hasKms, selectedID = {}, true, nil
    local lastScan = 0

    local left = vgui.Create("DPanel", parent)
    left:Dock(LEFT)
    left:SetWide(math.floor(parent:GetWide() * 0.46))
    left:DockMargin(0, 0, S(14), 0)
    left.Paint = nil

    local header = vgui.Create("DPanel", left)
    header:Dock(TOP)
    header:SetTall(S(30))
    header.Paint = function(_, w, h)
        local pulse = 0.5 + 0.5 * math.sin(RealTime() * 4)
        D.Circle(S(6), h / 2, S(4), D.Alpha(D.col.green, 120 + pulse * 135), 12)
        D.Text("LIVE  ·  " .. #patients .. " SOLDATEN IM SEKTOR", "gdp.h4", S(18), h / 2, D.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if not hasKms then D.Text("Kraken's Medical nicht aktiv", "gdp.tiny", w, h / 2, D.col.yellow, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
    end

    local scroll = D.Scroll(left)
    scroll:Dock(FILL)

    local right = vgui.Create("DPanel", parent)
    right:Dock(FILL)

    local function Selected()
        for _, p in ipairs(patients) do if p.key == selectedID then return p end end
    end

    local function Rebuild()
        if not IsValid(scroll) then return end
        local y = scroll:GetVBar():GetScroll()
        scroll:Clear()
        for _, p in ipairs(patients) do
            local row = vgui.Create("DButton", scroll)
            row:Dock(TOP)
            row:SetTall(S(54))
            row:DockMargin(0, 0, 0, S(4))
            row:SetText("")
            row._hover = 0
            row.Think = function(s) s._hover = D.Approach(s._hover, s:IsHovered() and 1 or 0, 14) end
            row.DoClick = function() D.Sound("click") selectedID = p.key end
            row.Paint = function(s, w, h)
                local cond, col = Condition(p)
                local sel = selectedID == p.key
                local tri = TRIAGE[p.triage or 0] or TRIAGE[0]
                D.Box(0, 0, w, h, sel and D.Accent(24) or D.Lerp(s._hover, Color(9, 11, 14, 215), Color(17, 20, 26, 235)))
                D.Outline(0, 0, w, h, sel and D.Accent() or D.Alpha(D.col.line2, 70 + s._hover * 80))
                D.Box(0, 0, S(5), h, tri.color)
                D.TextFit(p.name, "gdp.body.b", S(14), S(5), D.col.text, w * 0.55)
                D.Text(cond, "gdp.tiny.b", S(14), h - S(6), col, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                local cx = S(14) + D.TextSize(cond, "gdp.tiny.b") + S(10)
                if p.kms then
                    Bar(cx, h - S(13), S(70), S(5), (p.blood or 0) / 100, (p.blood or 0) < 60 and D.col.red or Color(200, 60, 60))
                    D.Text((p.blood or 0) .. "%", "gdp.tiny", cx + S(76), h - S(6), D.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                else
                    Bar(cx, h - S(13), S(70), S(5), p.hp / math.max(1, p.maxhp), D.col.green)
                end
                if p.medcall then
                    local blink = math.sin(RealTime() * 8) > 0
                    local cw = D.ChipSize("Notruf")
                    D.Chip("Notruf", w - cw - S(8), S(6), blink and color_white or D.col.red, blink and D.col.red or Color(70, 10, 10, 230))
                end
                D.Text(p.dist .. " m", "gdp.small", w - S(8), h - S(6), D.col.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
                return true
            end
        end
        if #patients == 0 then D.FillRecords(scroll, {}, nil, "Keine Soldaten im Sektor.") end
        timer.Simple(0, function() if IsValid(scroll) then scroll:GetVBar():SetScroll(y) end end)
    end

    local function Scan()
        lastScan = RealTime()
        GAR_DP.Request("med_scan", {}, function(data)
            if not data or not IsValid(scroll) then return end
            hasKms = data.kms
            patients = data.patients or {}
            table.sort(patients, function(a, b)
                local ma, mb = a.medcall and 1 or 0, b.medcall and 1 or 0
                if ma ~= mb then return ma > mb end
                local _, _, ua = Condition(a)
                local _, _, ub = Condition(b)
                if ua ~= ub then return ua > ub end
                return a.dist < b.dist
            end)
            if not selectedID and patients[1] then selectedID = patients[1].key end
            Rebuild()
        end)
    end

    left.Think = function()
        if RealTime() - lastScan > (CFG.MedicalRefresh or 2) then Scan() end
    end

    right.Paint = function(_, w, h)
        D.Panel(0, 0, w, h, { fill = Color(9, 11, 14, 200), stroke = D.col.line, cut = S(12), corners = "tlbr" })
        local p = Selected()
        if not p then
            D.Text("Patient auswählen", "gdp.h3", w / 2, h / 2, D.col.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        local cond, condCol = Condition(p)
        local x, cw = S(16), w - S(32)
        D.TextFit(p.name, "gdp.h2", x, S(8), D.col.text, cw)
        D.TextFit(p.unit or "", "gdp.small", x, S(40), D.col.dim, cw)
        local tri = TRIAGE[p.triage or 0] or TRIAGE[0]
        local cw1 = D.ChipSize(cond)
        D.Chip(cond, x, S(62), condCol, D.Alpha(condCol, 30), D.Alpha(condCol, 160))
        D.Chip(tri.name, x + cw1 + S(6), S(62), tri.color == TRIAGE[4].color and D.col.dim or tri.color, D.Alpha(tri.color, 40), D.Alpha(tri.color, 160))

        -- Koerper links, Werte rechts
        local bodyS = math.min(S(190), h - S(130))
        DrawBody(x, S(96), bodyS * 0.62, p.parts)
        local vx = x + bodyS * 0.62 + S(20)
        local vw = w - vx - S(16)
        local vy = S(96)
        local function Vital(label, value, col, unit)
            D.Text(string.upper(label), "gdp.tiny.b", vx, vy, D.col.muted)
            D.Text(tostring(value), "gdp.h2", vx, vy + S(12), col or D.col.text)
            if unit then D.Text(unit, "gdp.small", vx + D.TextSize(tostring(value), "gdp.h2") + S(4), vy + S(26), D.col.dim) end
            vy = vy + S(50)
        end
        if p.kms then
            local half = vw / 2
            local saveY = vy
            Vital("Blut", (p.blood or 0) .. "%", (p.blood or 0) < 60 and D.col.red or D.col.text)
            Vital("Puls", p.hr or 0, ((p.hr or 0) > 130 or (p.hr or 0) < 45) and D.col.red or D.col.text, "bpm")
            Vital("Blutverlust", p.bleed or 0, (p.bleed or 0) > 0 and D.col.red or D.col.green, "ml/s")
            vy, vx = saveY, vx + half
            Vital("Blutdruck", p.bp or "-", D.col.text, "mmHg")
            Vital("SpO2", (p.spo2 or 0) .. "%", (p.spo2 or 0) < 90 and D.col.red or D.col.text)
            Vital("Leben", p.hp .. " / " .. p.maxhp, D.col.text)
            vx = vx - half
        else
            Vital("Leben", p.hp .. " / " .. p.maxhp, D.col.text)
            Vital("Rüstung", p.armor, D.col.blue)
        end

        -- Wunden
        local ly = math.max(vy, S(96) + bodyS) + S(6)
        if p.kms and ly < h - S(40) then
            D.Section("Befund", x, ly, cw)
            ly = ly + S(28)
            local any = false
            for _, part in ipairs(p.parts or {}) do
                if part.open > 0 or part.bandaged > 0 or part.frac or part.tq then
                    any = true
                    if ly > h - S(24) then break end
                    local bits = {}
                    if part.open > 0 then bits[#bits + 1] = part.open .. " offene Wunde(n)" end
                    if part.bandaged > 0 then bits[#bits + 1] = part.bandaged .. " verbunden" end
                    if part.frac then bits[#bits + 1] = part.splint and "Fraktur (geschient)" or "Fraktur" end
                    if part.tq then bits[#bits + 1] = "Tourniquet" end
                    D.Box(x, ly + S(3), S(8), S(8), PartColor(part))
                    D.Text(PART_NAMES[part.id] or part.id, "gdp.small.b", x + S(16), ly, D.col.text)
                    D.TextFit(table.concat(bits, ", "), "gdp.small", x + S(120), ly, D.col.dim, cw - S(120))
                    ly = ly + S(20)
                end
            end
            if not any then D.Text("Keine Verletzungen festgestellt.", "gdp.small", x, ly, D.col.green) end
        end
    end

    local openBtn = D.Button(right, "Krankenakte", "default", function()
        local p = Selected()
        local char = p and symchars.chars.Get(p.charID)
        if char then openRecords(char) end
    end)
    openBtn:SetIcon("folder")
    openBtn:SetFont("gdp.h4")
    right.PerformLayout = function(_, w, h)
        openBtn:SetSize(S(170), S(34))
        openBtn:SetPos(w - S(186), S(12))
    end

    Scan()
end

---------------------------------------------------------------------------------------------------------------
-- App
---------------------------------------------------------------------------------------------------------------
GAR_DP.RegisterApp({
    id = "medical",
    name = "Medizin",
    desc = "Live-Vitalwerte aller Soldaten, Notrufe, Befunde und Krankenakten. Nur für Sanitäter.",
    icon = "medic",
    order = 3,
    build = function(parent)
        local content
        local function Show(id, char)
            content:Clear()
            if id == "live" then
                BuildLive(content, function(c) parent.tabs:SetActive("records", true) Show("records", c) end)
            else
                BuildRecords(content, char)
            end
        end
        local tabs = D.SubTabs(parent, {
            { id = "live", name = "Patienten" },
            { id = "records", name = "Krankenakten" },
        }, function(id) Show(id) end)
        tabs:Dock(TOP)
        tabs:SetTall(S(36))
        parent.tabs = tabs

        content = vgui.Create("DPanel", parent)
        content:Dock(FILL)
        content:DockMargin(0, S(10), 0, 0)
        content.Paint = nil
        parent:InvalidateLayout(true)
        Show("live")
    end,
})
