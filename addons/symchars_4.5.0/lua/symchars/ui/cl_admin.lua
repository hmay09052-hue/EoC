--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Admin: Einstellungen, Einheiten, Fortbildungen, Hologramme, Whitelist
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S
local U = symchars.util
local UT = symchars.utils
local F = symchars.factions
local T = symchars.trainings
local H = symchars.holo

local function Has(priv) return symchars.HasPriv(LocalPlayer(), priv) end

---------------------------------------------------------------------------------------------------------------
-- kleine Bausteine
---------------------------------------------------------------------------------------------------------------
local function TextField(parent, label, desc, value, opts)
    opts = opts or {}
    local field = UI.Field(parent, label, desc, opts.height)
    local e = UI.Entry(field, opts.placeholder or "", value ~= nil and tostring(value) or "")
    e:Dock(FILL)
    if opts.numeric then e:SetNumeric(true) end
    if opts.multiline then e:SetMultiline(true) e:SetFont("symchars.body") end
    return e
end

local function CheckField(parent, label, value)
    local c = UI.Check(parent, label, value)
    c:Dock(TOP)
    c:SetTall(S(40))
    c:DockMargin(0, 0, 0, S(10))
    c:SetFont("symchars.h4")
    return c
end

local function ColorField(parent, label, value)
    local field = UI.Field(parent, label, "")
    local c = vgui.Create("symchars.ColorButton", field)
    c:Dock(LEFT)
    c:SetWide(S(220))
    c:SetColor(value or Color(255, 255, 255))
    return c
end

local function PickerField(parent, label, desc, items, selected, height, single)
    local field = UI.Field(parent, label, desc, height or S(240))
    local p = vgui.Create("symchars.Picker", field)
    p:Dock(FILL)
    p:SetSingle(single == true)
    p:SetItems(items)
    p:SetSelected(selected or {})
    return p
end

local function ImageField(parent, label, desc, value)
    local field = UI.Field(parent, label, desc, S(42))
    local preview = vgui.Create("DPanel", field)
    preview:Dock(RIGHT)
    preview:SetWide(S(80))
    preview:DockMargin(S(8), 0, 0, 0)
    local e = UI.Entry(field, "https://i.imgur.com/… oder Imgur-ID", value or "")
    e:Dock(FILL)
    preview.Paint = function(_, w, h)
        UI.Box(0, 0, w, h, Color(4, 6, 8, 230))
        local url = U.ImageURL(e:GetValue())
        if url ~= "" then UI.DrawImage(url, S(2), S(2), w - S(4), h - S(4), color_white, "contain") end
        UI.Outline(0, 0, w, h, UI.col.line2)
    end
    return e
end

local function Lines(text)
    local out = {}
    for _, line in ipairs(string.Explode("\n", text or "")) do
        line = string.Trim(line)
        if line ~= "" then out[#out + 1] = line end
    end
    return out
end

local function SaveBar(frame, onSave, onDelete, deleteText)
    local row = vgui.Create("DPanel", frame)
    row:Dock(BOTTOM)
    row:SetTall(S(50))
    row:DockMargin(0, S(12), 0, 0)
    row.Paint = nil
    if onDelete then
        local del = UI.Button(row, deleteText or "Löschen", "danger", onDelete)
        del:Dock(LEFT)
        del:SetWide(S(200))
        del:SetIcon("trash")
    end
    local save = UI.Button(row, "Speichern", "primary", onSave)
    save:Dock(RIGHT)
    save:SetWide(S(260))
    return row
end

---------------------------------------------------------------------------------------------------------------
-- Einstellungen
---------------------------------------------------------------------------------------------------------------
local function BuildSettings(parent)
    local SET = symchars.settings
    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)
    local getters = {}

    for _, cat in ipairs(SET.categories) do
        local head = vgui.Create("DPanel", scroll)
        head:Dock(TOP)
        head:SetTall(S(48))
        head:DockMargin(0, S(14), S(10), S(6))
        head.Paint = function(_, w) UI.Section(cat.name, 0, S(8), w, UI.Accent()) end

        for _, key in ipairs(SET.order) do
            local meta = SET.meta[key]
            if meta.category == cat.id then
                local value = symchars.Config(key)
                local t = meta.type
                if t == "bool" then
                    local c = CheckField(scroll, meta.label, value == true)
                    c:SetTooltip(meta.desc)
                    getters[key] = function() return c:GetChecked() end
                elseif t == "number" then
                    local e = TextField(scroll, meta.label, meta.desc, value, { numeric = true })
                    getters[key] = function() return tonumber(e:GetValue()) end
                elseif t == "string" or t == "image" then
                    local e = t == "image" and ImageField(scroll, meta.label, meta.desc, value) or TextField(scroll, meta.label, meta.desc, value)
                    getters[key] = function() return e:GetValue() end
                elseif t == "color" then
                    local c = ColorField(scroll, meta.label, value)
                    getters[key] = function() return c:GetColor() end
                elseif t == "key" then
                    local field = UI.Field(scroll, meta.label, meta.desc)
                    local binder = vgui.Create("DBinder", field)
                    binder:Dock(LEFT)
                    binder:SetWide(S(220))
                    binder:SetValue(value or 0)
                    binder:SetFont("symchars.body.bold")
                    getters[key] = function() return binder:GetValue() end
                elseif t == "stringlist" then
                    local e = TextField(scroll, meta.label, meta.desc .. " (ein Eintrag pro Zeile)", table.concat(value or {}, "\n"), { multiline = true, height = S(110) })
                    getters[key] = function() return Lines(e:GetValue()) end
                elseif t == "slots" then
                    local lines = {}
                    for g, n in pairs(value or {}) do lines[#lines + 1] = g .. "=" .. n end
                    table.sort(lines)
                    local e = TextField(scroll, meta.label, meta.desc .. " Format: usergroup=anzahl, eine Zeile pro Gruppe", table.concat(lines, "\n"), { multiline = true, height = S(110) })
                    getters[key] = function()
                        local out = {}
                        for _, line in ipairs(Lines(e:GetValue())) do
                            local g, n = string.match(line, "^([^=]+)=(%d+)$")
                            if g then out[string.Trim(g)] = tonumber(n) end
                        end
                        return out
                    end
                elseif t == "rpidrules" then
                    local lines = {}
                    for _, r in ipairs(value or {}) do
                        lines[#lines + 1] = r.prefix .. ";" .. r.length .. ";" .. table.concat(r.units or {}, ",") .. ";" .. table.concat(r.jobs or {}, ",")
                    end
                    local e = TextField(scroll, meta.label, "Format: PRÄFIX;ZIFFERN;einheit1,einheit2;job1,job2  (eine Regel pro Zeile)", table.concat(lines, "\n"), { multiline = true, height = S(110) })
                    getters[key] = function()
                        local out = {}
                        for _, line in ipairs(Lines(e:GetValue())) do
                            local parts = string.Explode(";", line)
                            out[#out + 1] = {
                                prefix = parts[1] or "", length = tonumber(parts[2]) or 4,
                                units = string.Explode(",", parts[3] or ""), jobs = string.Explode(",", parts[4] or ""),
                            }
                        end
                        return out
                    end
                elseif t == "nationalities" then
                    local lines = {}
                    for _, n in ipairs(value or {}) do
                        lines[#lines + 1] = n.id .. ";" .. n.name .. ";" .. table.concat(n.blockedjobs or {}, ",")
                    end
                    local e = TextField(scroll, meta.label, "Format: ID;Name;gesperrte Jobs (Befehle, mit Komma)  z.B. sep;Separatistisch;cadetss", table.concat(lines, "\n"), { multiline = true, height = S(110) })
                    getters[key] = function()
                        local out = {}
                        for _, line in ipairs(Lines(e:GetValue())) do
                            local parts = string.Explode(";", line)
                            local jobs = {}
                            for _, j in ipairs(string.Explode(",", parts[3] or "")) do
                                j = string.Trim(j)
                                if j ~= "" then jobs[#jobs + 1] = j end
                            end
                            out[#out + 1] = { id = string.Trim(parts[1] or ""), name = string.Trim(parts[2] or ""), blockedjobs = jobs }
                        end
                        return out
                    end
                elseif t == "faction" then
                    local field = UI.Field(scroll, meta.label, meta.desc)
                    local c = UI.Combo(field)
                    c:Dock(FILL)
                    UI.FillUnitCombo(c, value, { none = "(keine)" })
                    getters[key] = function() return c:GetSelectedData() or value end
                elseif t == "job" then
                    local field = UI.Field(scroll, meta.label, meta.desc)
                    local c = UI.Combo(field)
                    c:Dock(FILL)
                    UI.FillJobCombo(c, value)
                    getters[key] = function() return c:GetSelectedData() or value end
                end
            end
        end
    end

    local bar = vgui.Create("DPanel", parent)
    bar:Dock(BOTTOM)
    bar:SetTall(S(54))
    bar:DockMargin(0, S(10), 0, 0)
    bar.Paint = nil
    local save = UI.Button(bar, "Einstellungen speichern", "primary", function()
        local values = {}
        for key, get in pairs(getters) do
            local v = get()
            if v ~= nil then values[key] = v end
        end
        symchars.net.SendToServer("settings_save", { values = values })
    end)
    save:Dock(RIGHT)
    save:SetWide(S(320))
    save:SetFont("symchars.h3")
end

---------------------------------------------------------------------------------------------------------------
-- Rang-Editor (Dialog)
---------------------------------------------------------------------------------------------------------------
local function OpenRankEditor(rank, index, onDone)
    local f = UI.Frame("Rang " .. index .. ": " .. (rank.name or ""), S(820), S(900))
    local scroll = UI.Scroll(f)
    scroll:Dock(FILL)

    local name = TextField(scroll, "Name", "", rank.name)
    local short = TextField(scroll, "Kürzel", "Kurzform für Listen, z.B. CPL (steht nicht im Namen)", rank.short)
    local col = ColorField(scroll, "Farbe", rank.color)
    local icon = ImageField(scroll, "Rangabzeichen", "Imgur-Link oder Materialpfad (optional, über dem Kopf)", rank.icon)
    local jobField = UI.Field(scroll, "Eigener Job", "Leer = Job der Einheit")
    local job = UI.Combo(jobField)
    job:Dock(FILL)
    UI.FillJobCombo(job, rank.job, "(Job der Einheit)")
    local max = TextField(scroll, "Maximale Anzahl", "0 = unbegrenzt", rank.max or 0, { numeric = true })

    local flagHead = vgui.Create("DPanel", scroll)
    flagHead:Dock(TOP)
    flagHead:SetTall(S(36))
    flagHead.Paint = function(_, w) UI.Section("Rechte", 0, 0, w) end
    local flagHint = vgui.Create("DLabel", scroll)
    flagHint:Dock(TOP)
    flagHint:SetTall(S(40))
    flagHint:SetWrap(true)
    flagHint:SetFont("symchars.tiny")
    flagHint:SetTextColor(UI.col.muted)
    flagHint:SetText("Zusätzlich gelten Befördern, Aufnehmen, Entlassen und Versetzen automatisch ab dem Rang, der unter \"Rechte ab Rang\" bei der Einheit eingestellt ist. Hier nur anhaken, was ein Rang darüber hinaus darf.")
    local flagChecks = {}
    local flagSet = U.ToSet(rank.flags or {})
    -- alte Flags umrechnen ("member" = Aufnehmen + Entlassen + Versetzen)
    for legacy, covers in pairs(F.LEGACY_FLAGS) do
        if flagSet[legacy] then for _, fl in ipairs(covers) do flagSet[fl] = true end end
    end
    for _, flag in ipairs(F.FLAGS) do
        local c = CheckField(scroll, flag.name .. "  –  " .. flag.desc, flagSet[flag.id] == true)
        flagChecks[flag.id] = c
    end
    local shared = {}
    for _, fl in ipairs(rank.flags or {}) do
        local known = F.LEGACY_FLAGS[fl] ~= nil
        for _, def in ipairs(F.FLAGS) do if def.id == fl then known = true end end
        -- "trainer" gibt es nicht mehr (Fortbildungen laufen über die Fortbildungs-Freigabe)
        if not known and not string.match(fl, "_trainer$") then shared[#shared + 1] = fl end
    end
    local sharedEntry = TextField(scroll, "Rechte in anderen Einheiten", "Format: einheitid_recht, eine Zeile pro Recht (z.B. 212th_promotions)", table.concat(shared, "\n"), { multiline = true, height = S(90) })

    local extras = F.GetRankExtras(rank)
    local exHead = vgui.Create("DPanel", scroll)
    exHead:Dock(TOP)
    exHead:SetTall(S(36))
    exHead.Paint = function(_, w) UI.Section("Extras", 0, 0, w) end
    local hp = TextField(scroll, "Lebenspunkte", "0 = Standard des Jobs", extras.health, { numeric = true })
    local ar = TextField(scroll, "Rüstung", "0 = Standard des Jobs", extras.armor, { numeric = true })
    local sp = TextField(scroll, "Tempo-Bonus", "-250 bis 250", extras.speed, { numeric = true })
    local mdl = TextField(scroll, "Modell", "Eigenes Modell für diesen Rang (optional)", extras.model, { placeholder = "models/..." })
    local weapons = PickerField(scroll, "Waffen", "Werden bei jedem Spawn gegeben", UI.WeaponItems(), extras.weapons, S(260))

    SaveBar(f, function()
        local flags = {}
        for id, c in pairs(flagChecks) do if c:GetChecked() then flags[#flags + 1] = id end end
        for _, line in ipairs(Lines(sharedEntry:GetValue())) do flags[#flags + 1] = string.lower(line) end
        onDone({
            name = name:GetValue(), short = short:GetValue(), color = col:GetColor(), icon = icon:GetValue(),
            job = job:GetSelectedData() or "", max = tonumber(max:GetValue()) or 0, flags = flags,
            extras = { health = tonumber(hp:GetValue()) or 0, armor = tonumber(ar:GetValue()) or 0, speed = tonumber(sp:GetValue()) or 0, model = mdl:GetValue(), weapons = weapons:GetSelected() },
        })
        f:Close()
    end)
end

---------------------------------------------------------------------------------------------------------------
-- Einheiten-Editor
---------------------------------------------------------------------------------------------------------------
local function BuildFactionEditor(parent)
    local left = vgui.Create("DPanel", parent)
    left:Dock(LEFT)
    left:SetWide(S(420))
    left.Paint = function(_, w, h) UI.Panel(0, 0, w, h, { cut = S(12), corners = "tlbr" }) end
    left:DockPadding(S(12), S(12), S(12), S(12))
    local list = UI.Scroll(left)
    list:Dock(FILL)
    local newBtn = UI.Button(left, "Neue Einheit", "primary")
    newBtn:Dock(BOTTOM)
    newBtn:SetTall(S(46))
    newBtn:DockMargin(0, S(10), 0, 0)
    newBtn:SetIcon("plus")
    newBtn:SetFont("symchars.button.small")

    local right = vgui.Create("DPanel", parent)
    right:Dock(FILL)
    right:DockMargin(S(16), 0, 0, 0)
    right.Paint = function(_, w, h) UI.Panel(0, 0, w, h, { cut = S(14), corners = "tlbr" }) end
    right:DockPadding(S(20), S(16), S(16), S(16))

    local selectedID
    local Edit

    local function RebuildList()
        list:Clear()
        for _, item in ipairs(F.GetHierarchyList()) do
            local b = UI.Button(list, item.label, "select", function() Edit(item.data) end)
            b:Dock(TOP)
            b:SetTall(S(44))
            b:DockMargin(item.depth * S(20), 0, S(4), S(4))
            b:SetAlign(TEXT_ALIGN_LEFT)
            b:SetFont("symchars.h4")
            b:SetAccentColor(item.data:GetColor())
            b:SetSubText(item.id .. (item.data.isDefault and "  ·  Start" or "") .. (item.data.isJoinable and "  ·  frei" or ""))
            b:SetSelected(item.id == selectedID)
        end
    end

    Edit = function(faction)
        right:Clear()
        local data = faction and F.ToSaveTable(faction) or {
            uniqueID = "", name = "", short = "", description = "", subfaction_of = "", color = { r = 252, g = 178, b = 73 },
            job = "", logo = "", banner = "", model = "", sort = 0, isDefault = false, isJoinable = false, hidden = false,
            startGroups = {}, lockedText = "", nationalities = {}, ranks = { { name = "Rekrut", short = "REK", flags = {}, max = 0 } },
        }
        selectedID = faction and faction.uniqueID or nil
        RebuildList()
        local previousID = data.uniqueID
        local ranks = table.Copy(data.ranks or {})

        local body = vgui.Create("DPanel", right)
        body:Dock(FILL)
        body.Paint = nil
        local preview = UI.HoloModel(body, "holo")
        preview:Dock(RIGHT)
        preview:SetWide(S(300))
        preview:SetSpin(20)
        local scroll = UI.Scroll(body)
        scroll:Dock(FILL)

        local name = TextField(scroll, "Name", "", data.name)
        local id = TextField(scroll, "ID", "Eindeutig, nur a-z 0-9 _ - (Änderung verschiebt alle Mitglieder mit)", data.uniqueID)
        local short = TextField(scroll, "Kürzel", "z.B. 501st", data.short)
        local parentField = UI.Field(scroll, "Obereinheit", "Leer = Haupteinheit. Untereinheiten erscheinen im Dropdown unter der Haupteinheit.")
        local parentCombo = UI.Combo(parentField)
        parentCombo:Dock(FILL)
        UI.FillUnitCombo(parentCombo, data.subfaction_of, { none = "(keine – Haupteinheit)", filter = function(f) return f.uniqueID ~= previousID and not F.IsDescendant(f, previousID) end })
        local color = ColorField(scroll, "Farbe", U.TableToColor(data.color, Color(255, 255, 255)))
        local jobField = UI.Field(scroll, "DarkRP-Job", "Job der Mitglieder (Ränge können einen eigenen Job haben)")
        local job = UI.Combo(jobField)
        job:Dock(FILL)
        UI.FillJobCombo(job, data.job)
        local model = TextField(scroll, "Beispielmodell", "Wird in der Einheiten-Übersicht als Hologramm gezeigt (leer = erstes Job-Modell)", data.model, { placeholder = "models/..." })
        local logo = ImageField(scroll, "Logo", "Imgur-Link (quadratisch, transparent)", data.logo ~= "" and data.logo or data.icon)
        local banner = ImageField(scroll, "Banner", "Imgur-Link (breit, ca. 16:5)", data.banner)
        local desc = TextField(scroll, "Beschreibung", "", data.description, { multiline = true, height = S(140) })
        local sort = TextField(scroll, "Sortierung", "Kleinere Zahl = weiter oben", data.sort, { numeric = true })
        local isDefault = CheckField(scroll, "Starteinheit (bei der Charaktererstellung wählbar)", data.isDefault)
        local isJoinable = CheckField(scroll, "Frei beitretbar (Knopf in der Übersicht)", data.isJoinable)
        local hidden = CheckField(scroll, "In der Übersicht verstecken", data.hidden)
        local groups = TextField(scroll, "Start nur für Usergroups", "Eine pro Zeile, leer = alle (z.B. vip)", table.concat(data.startGroups or {}, "\n"), { multiline = true, height = S(80) })
        local locked = TextField(scroll, "Sperrtext", "z.B. 'Benötigt VIP' – wird bei gesperrter Startklasse gezeigt", data.lockedText)
        local natItems = {}
        for _, n in ipairs(UT.Nationalities()) do natItems[#natItems + 1] = { id = n.id, text = n.name, sub = n.id } end
        local nats = PickerField(scroll, "Erlaubte Nationalitäten", "Leer = alle. Gilt für Start, Beitritt und Einladungen.", natItems, data.nationalities, S(150))

        local function UpdatePreview()
            local m = string.Trim(model:GetValue())
            if m == "" then m = U.FirstModel(job:GetSelectedData() or data.job) or "models/player/kleiner.mdl" end
            preview:SetHoloModel(m)
        end
        model.OnValueChange = UpdatePreview
        job.OnSelect = function() UpdatePreview() end
        UpdatePreview()

        -- Ränge
        local rankHead = vgui.Create("DPanel", scroll)
        rankHead:Dock(TOP)
        rankHead:SetTall(S(44))
        rankHead:DockMargin(0, S(10), S(10), 0)
        rankHead.Paint = function(_, w) UI.Section("Ränge (1 = niedrigster)", 0, S(4), w, UI.Accent()) end
        local rankList = vgui.Create("DPanel", scroll)
        rankList:Dock(TOP)
        rankList.Paint = nil

        local RefreshRights
        local function RebuildRanks()
            rankList:Clear()
            rankList:SetTall(#ranks * S(50) + S(54))
            for i, rank in ipairs(ranks) do
                local row = vgui.Create("DPanel", rankList)
                row:Dock(TOP)
                row:SetTall(S(46))
                row:DockMargin(0, 0, S(10), S(4))
                row.Paint = function(_, w, h)
                    UI.Box(0, 0, w, h, Color(14, 18, 23, 230))
                    local c = U.TableToColor(rank.color, Color(255, 255, 255))
                    UI.Box(0, 0, S(4), h, c)
                    UI.Text(tostring(i), "symchars.h4", S(16), h / 2, UI.col.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    UI.TextFit(rank.name .. (rank.short ~= "" and ("  [" .. rank.short .. "]") or ""), "symchars.body.bold", S(50), h / 2, UI.col.text, w - S(420), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local flags = table.concat(rank.flags or {}, ", ")
                    UI.TextFit(flags, "symchars.tiny", w - S(200), h / 2, UI.col.dim, S(150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                local function Btn(icon, fn, style)
                    local b = UI.Button(row, "", style or "default", fn)
                    b:SetIcon(icon)
                    b:Dock(RIGHT)
                    b:SetWide(S(40))
                    b:DockMargin(S(4), S(4), 0, S(4))
                end
                Btn("trash", function()
                    if #ranks <= 1 then return end
                    table.remove(ranks, i)
                    RebuildRanks()
                end, "danger")
                Btn("arrow_down", function() if i > 1 then ranks[i], ranks[i - 1] = ranks[i - 1], ranks[i] RebuildRanks() end end)
                Btn("arrow_up", function() if i < #ranks then ranks[i], ranks[i + 1] = ranks[i + 1], ranks[i] RebuildRanks() end end)
                Btn("edit", function()
                    OpenRankEditor(rank, i, function(newRank)
                        ranks[i] = newRank
                        RebuildRanks()
                    end)
                end)
            end
            local add = UI.Button(rankList, "+ Rang hinzufügen", "default", function()
                ranks[#ranks + 1] = { name = "Neuer Rang", short = "", flags = {}, max = 0, color = data.color }
                RebuildRanks()
            end)
            add:Dock(TOP)
            add:SetTall(S(44))
            add:DockMargin(0, S(4), S(10), 0)
            add:SetFont("symchars.button.small")
            if RefreshRights then RefreshRights() end
        end

        -- Rechte ab Rang (Befördern ab Sergeant, Aufnehmen ab Corporal …)
        local rightsFrom = table.Copy(data.rightsFrom or {})
        local rightsHead = vgui.Create("DPanel", scroll)
        rightsHead:Dock(TOP)
        rightsHead:SetTall(S(70))
        rightsHead:DockMargin(0, S(14), S(10), 0)
        rightsHead.Paint = function(_, w)
            UI.Section("Rechte ab Rang", 0, S(4), w, UI.Accent())
            UI.TextFit("Gilt für diesen und alle höheren Ränge, nur gegenüber niedrigeren Rängen. Standard kommt aus ADMIN > Einstellungen > Rechte.", "symchars.tiny", 0, S(44), UI.col.muted, w)
        end
        local rightNames = { promotions = "Befördern / Degradieren", invite = "Aufnehmen", kick = "Entlassen", transfer = "Versetzen" }
        local rightCombos = {}
        for _, flag in ipairs(F.RANK_RIGHTS) do
            local field = UI.Field(scroll, rightNames[flag] or flag, "")
            field:DockMargin(0, 0, S(10), S(8))
            local combo = UI.Combo(field)
            combo:Dock(FILL)
            combo.OnSelect = function(_, _, _, v) rightsFrom[flag] = v end
            rightCombos[flag] = combo
        end
        RefreshRights = function()
            for flag, combo in pairs(rightCombos) do
                if IsValid(combo) then
                    local cur = tonumber(rightsFrom[flag]) or 0
                    if cur > #ranks then cur = 0 rightsFrom[flag] = 0 end
                    local setting = symchars.Config("right" .. flag) or ""
                    local def = F.FindRankByName({ ranks = ranks }, setting)
                    combo:Clear()
                    combo:AddChoice(def and ("Standard: ab " .. def .. " · " .. ranks[def].name) or ("Standard: kein Rang \"" .. setting .. "\" gefunden"), 0, cur == 0, 0, "Einstellungen")
                    combo:AddChoice("Niemand automatisch (nur angehakte Rang-Rechte)", -1, cur == -1)
                    for i, r in ipairs(ranks) do combo:AddChoice("ab " .. i .. " · " .. r.name, i, cur == i, 0, r.short) end
                end
            end
        end
        RebuildRanks()

        local function Collect()
            return {
                uniqueID = string.lower(string.Trim(id:GetValue())), name = name:GetValue(), short = short:GetValue(),
                description = desc:GetValue(), subfaction_of = parentCombo:GetSelectedData() or "", color = color:GetColor(),
                job = job:GetSelectedData() or "", model = model:GetValue(), logo = logo:GetValue(), banner = banner:GetValue(),
                icon = data.icon, sort = tonumber(sort:GetValue()) or 0, isDefault = isDefault:GetChecked(), isJoinable = isJoinable:GetChecked(),
                hidden = hidden:GetChecked(), startGroups = Lines(groups:GetValue()), lockedText = locked:GetValue(),
                nationalities = nats:GetSelected(), rightsFrom = rightsFrom, ranks = ranks,
            }
        end

        SaveBar(right, function()
            symchars.net.SendToServer("faction_save", { previousID = previousID, faction = Collect() })
            selectedID = string.lower(string.Trim(id:GetValue()))
        end, faction and function()
            UI.Confirm("Einheit löschen", "'" .. faction.name .. "' löschen? Mitglieder werden in die Standard-Einheit verschoben.", function()
                symchars.net.SendToServer("faction_delete", { id = faction.uniqueID })
                selectedID = nil
                right:Clear()
            end, nil, "Löschen")
        end or nil)
    end

    newBtn.DoClick = function() Edit(nil) end
    hook.Add("symchars_factions_synced", parent, function()
        RebuildList()
        if selectedID and F.Get(selectedID) then Edit(F.Get(selectedID)) end
    end)
    RebuildList()
end

---------------------------------------------------------------------------------------------------------------
-- Fortbildungs-Editor (Dialog)
---------------------------------------------------------------------------------------------------------------
function UI.OpenTrainingEditor(t)
    local data = t and T.ToSave(t) or {
        id = "", name = "", short = "", description = "", category = "", icon = "", color = { r = 252, g = 178, b = 73 }, sort = 0,
        units = {}, includeSubunits = true, jobs = {},
        trainerNeedsTraining = false, requires = {}, vehicles = {}, weapons = {}, validDays = 0,
    }
    local isFreigabe = T.IsFreigabe(t)
    local previousID = data.id
    local f = UI.Frame(t and ("Fortbildung: " .. t.name) or "Neue Fortbildung", S(980), ScrH() - S(80))
    local scroll = UI.Scroll(f)
    scroll:Dock(FILL)

    local hint = vgui.Create("DPanel", scroll)
    hint:Dock(TOP)
    hint:SetTall(S(58))
    hint:DockMargin(0, 0, S(10), S(12))
    hint.Paint = function(_, w, h)
        UI.Box(0, 0, w, h, UI.Accent(22))
        UI.Box(0, 0, S(3), h, UI.Accent())
        local text = isFreigabe
            and "Das ist die Fortbildungs-Freigabe: Wer sie hat, darf anderen Fortbildungen eintragen. Vergeben können sie nur Admins."
            or "Eingetragen wird unter VERWALTUNG > Mitglied > Fortbildungen – von Admins und allen mit der Fortbildungs-Freigabe."
        UI.DrawWrapped(text, "symchars.small", S(14), S(8), w - S(24), UI.col.text, 2)
    end

    local name = TextField(scroll, "Name", "z.B. LAAT-Pilot", data.name)
    local id = TextField(scroll, "ID", isFreigabe and "Wird in den Einstellungen festgelegt" or "Eindeutig, z.B. laat", data.id)
    if isFreigabe then id:SetEnabled(false) end
    local short = TextField(scroll, "Kürzel", "Kurz für Abzeichen, z.B. LAAT", data.short)
    local category = TextField(scroll, "Kategorie", "z.B. Fahrzeuge, Waffen, Sanitäter", data.category)
    local color = ColorField(scroll, "Farbe", U.TableToColor(data.color, Color(252, 178, 73)))
    local icon = ImageField(scroll, "Abzeichen", "Imgur-Link (optional)", data.icon)
    local desc = TextField(scroll, "Beschreibung", "", data.description, { multiline = true, height = S(120) })
    local sort = TextField(scroll, "Sortierung", "", data.sort, { numeric = true })

    local units = PickerField(scroll, "Gültig für Einheiten", "Leer = alle Einheiten", UI.UnitItems(), data.units)
    local includeSub = CheckField(scroll, "Gilt auch für Untereinheiten", data.includeSubunits)
    local jobs = PickerField(scroll, "Gültig für Jobs", "Optional – zusätzlich oder statt Einheiten", UI.JobItems(), data.jobs, S(200))

    local needs = CheckField(scroll, "Wer einträgt, muss die Fortbildung selbst bestanden haben", data.trainerNeedsTraining)

    local others = {}
    for _, other in ipairs(T.List()) do if other.id ~= data.id then others[#others + 1] = { id = other.id, text = other.name, sub = other.id } end end
    local requires = PickerField(scroll, "Voraussetzungen", "Andere Fortbildungen, die vorher bestanden sein müssen", others, data.requires, S(180))

    local vehicles = PickerField(scroll, "Fahrzeuge (SSE-Terminal)", "Werden nach dem Bestehen im Fahrzeugterminal freigeschaltet", UI.VehicleItems(), data.vehicles, S(280))
    local extraVeh = TextField(scroll, "Weitere Fahrzeug-Klassen", "Falls nicht in der Liste: eine Entity-Klasse pro Zeile", "", { multiline = true, height = S(80) })
    local weaponsPick = PickerField(scroll, "Waffen", "Werden beim Spawn gegeben", UI.WeaponItems(), data.weapons, S(260))
    local valid = TextField(scroll, "Gültigkeit in Tagen", "0 = unbegrenzt", data.validDays, { numeric = true })

    SaveBar(f, function()
        local veh = vehicles:GetSelected()
        for _, line in ipairs(Lines(extraVeh:GetValue())) do veh[#veh + 1] = line end
        symchars.net.SendToServer("training_save", { previousID = previousID, training = {
            id = id:GetValue() ~= "" and id:GetValue() or U.ID(name:GetValue()), name = name:GetValue(), short = short:GetValue(),
            category = category:GetValue(), color = color:GetColor(), icon = icon:GetValue(), description = desc:GetValue(),
            sort = tonumber(sort:GetValue()) or 0, units = units:GetSelected(), includeSubunits = includeSub:GetChecked(), jobs = jobs:GetSelected(),
            trainerNeedsTraining = needs:GetChecked(), requires = requires:GetSelected(), vehicles = veh, weapons = weaponsPick:GetSelected(),
            validDays = tonumber(valid:GetValue()) or 0,
        } })
        f:Close()
    end, (t and not isFreigabe) and function()
        UI.Confirm("Fortbildung löschen", "'" .. t.name .. "' löschen? Alle Eintragungen gehen verloren.", function()
            symchars.net.SendToServer("training_delete", { id = t.id })
            f:Close()
        end, nil, "Löschen")
    end or nil)
end

local function BuildTrainingList(parent)
    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)
    local function Rebuild()
        scroll:Clear()
        local add = UI.Button(scroll, "+ Neue Fortbildung", "primary", function() UI.OpenTrainingEditor(nil) end)
        add:Dock(TOP)
        add:SetTall(S(48))
        add:DockMargin(0, 0, S(10), S(10))
        add:SetFont("symchars.button.small")
        for _, t in ipairs(T.List()) do
            local b = UI.Button(scroll, t.name, "select", function() UI.OpenTrainingEditor(t) end)
            b:Dock(TOP)
            b:SetTall(S(56))
            b:DockMargin(0, 0, S(10), S(6))
            b:SetAlign(TEXT_ALIGN_LEFT)
            b:SetFont("symchars.h3")
            b:SetAccentColor(UI.Readable(t.color))
            if T.IsFreigabe(t) then
                b:SetSubText(t.id .. "  ·  berechtigt zum Eintragen  ·  nur Admins vergeben")
            else
                b:SetSubText(t.id .. "  ·  " .. #t.vehicles .. " Fahrzeuge  ·  " .. #t.weapons .. " Waffen")
            end
        end
    end
    hook.Add("symchars_trainings_synced", parent, Rebuild)
    Rebuild()
end

---------------------------------------------------------------------------------------------------------------
-- Hologramme
---------------------------------------------------------------------------------------------------------------
function UI.OpenHoloConfig(ent)
    if not IsValid(ent) then return end
    local class = ent:GetClass()
    local cfg = table.Copy(H.GetConfig(ent))
    local f = UI.Frame(H.CLASSES[class] or "Holo", S(760), S(820))
    local scroll = UI.Scroll(f)
    scroll:Dock(FILL)
    local get = {}

    local function UnitCombo(label, value)
        local field = UI.Field(scroll, label, "")
        local c = UI.Combo(field)
        c:Dock(FILL)
        UI.FillUnitCombo(c, value, { none = "(keine)" })
        return c
    end

    if class == "symchars_holo_display" then
        local modeField = UI.Field(scroll, "Anzeige", "Was das Hologramm zeigt")
        local mode = UI.Combo(modeField)
        mode:Dock(FILL)
        for _, m in ipairs(H.DISPLAY_MODES) do mode:AddChoice(m.name, m.id, m.id == cfg.mode) end
        local unit = UnitCombo("Einheit", cfg.unit)
        local docField = UI.Field(scroll, "Dokument", "Nur bei Anzeige 'Dokument'")
        local doc = UI.Combo(docField)
        doc:Dock(FILL)
        doc:AddChoice("(keins)", 0, cfg.doc == 0)
        for _, d in ipairs(UI.docState and UI.docState.list or {}) do doc:AddChoice(d.title, d.id, d.id == cfg.doc) end
        if cfg.doc > 0 and not doc:GetSelectedData() then doc:AddChoice("Dokument #" .. cfg.doc, cfg.doc, true) end
        local title = TextField(scroll, "Titel", "Optional, sonst automatisch", cfg.title)
        local text = TextField(scroll, "Text", "Für 'Freier Text' oder als Zusatz", cfg.text, { multiline = true, height = S(120) })
        local width = TextField(scroll, "Breite (Einheiten)", "30 – 400", cfg.width, { numeric = true })
        local color = ColorField(scroll, "Farbe", cfg.color)
        local flicker = CheckField(scroll, "Flackern", cfg.flicker)
        local range = TextField(scroll, "Sichtweite", "", cfg.range, { numeric = true })
        get = function()
            return { mode = mode:GetSelectedData(), unit = unit:GetSelectedData() or "", doc = doc:GetSelectedData() or 0,
                title = title:GetValue(), text = text:GetValue(), width = tonumber(width:GetValue()), color = color:GetColor(), flicker = flicker:GetChecked(), range = tonumber(range:GetValue()) }
        end
        symchars.net.SendToServer("doc_list", {})
    elseif class == "symchars_holo_projector" then
        local unit = UnitCombo("Einheit", cfg.unit)
        local model = TextField(scroll, "Eigenes Modell", "Leer = Beispielmodell der Einheit", cfg.model, { placeholder = "models/..." })
        local size = TextField(scroll, "Größe", "0.1 – 4", cfg.size)
        local color = ColorField(scroll, "Farbe", cfg.color)
        local spin = TextField(scroll, "Drehung (Grad/s)", "0 = steht still", cfg.spin, { numeric = true })
        local label = CheckField(scroll, "Namen der Einheit anzeigen", cfg.label)
        local range = TextField(scroll, "Sichtweite", "", cfg.range, { numeric = true })
        get = function()
            return { unit = unit:GetSelectedData() or "", model = model:GetValue(), size = tonumber(size:GetValue()), color = color:GetColor(),
                spin = tonumber(spin:GetValue()), label = label:GetChecked(), range = tonumber(range:GetValue()) }
        end
    else
        local tabField = UI.Field(scroll, "Öffnet", "Welcher Bereich des Menüs geöffnet wird")
        local tab = UI.Combo(tabField)
        tab:Dock(FILL)
        for _, t in ipairs(H.TERMINAL_TABS) do tab:AddChoice(t.name, t.id, t.id == cfg.tab) end
        local unit = UnitCombo("Einheit", cfg.unit)
        local title = TextField(scroll, "Titel", "", cfg.title)
        get = function() return { tab = tab:GetSelectedData(), unit = unit:GetSelectedData() or "", title = title:GetValue() } end
    end

    local saved = ent:GetSymSaved()
    local row = vgui.Create("DPanel", f)
    row:Dock(BOTTOM)
    row:SetTall(S(50))
    row:DockMargin(0, S(10), 0, 0)
    row.Paint = nil
    local persist = UI.Button(row, saved and "Nicht mehr speichern" or "Dauerhaft speichern", saved and "danger" or "default", function()
        symchars.net.SendToServer("holo_config", { ent = ent:EntIndex(), cfg = get(), persist = not saved })
        f:Close()
    end)
    persist:Dock(LEFT)
    persist:SetWide(S(300))
    local apply = UI.Button(row, "Übernehmen", "primary", function()
        symchars.net.SendToServer("holo_config", { ent = ent:EntIndex(), cfg = get() })
        f:Close()
    end)
    apply:Dock(RIGHT)
    apply:SetWide(S(240))
end

local holoList = {}
local function BuildHoloList(parent)
    local scroll = UI.Scroll(parent)
    scroll:Dock(FILL)
    local info = vgui.Create("DLabel", parent)
    info:Dock(TOP)
    info:SetTall(S(54))
    info:SetWrap(true)
    info:SetFont("symchars.small")
    info:SetTextColor(UI.col.dim)
    info:SetText("Spawnen über Q-Menü > Entities > SymChars. Einstellen per Rechtsklick im C-Menü ('Holo einstellen') oder hier. 'Dauerhaft speichern' lässt das Objekt nach Kartenwechsel wieder erscheinen.")

    local function Rebuild()
        if not IsValid(scroll) then return end
        scroll:Clear()
        for _, entry in ipairs(holoList) do
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:SetTall(S(58))
            row:DockMargin(0, 0, S(10), S(6))
            row.Paint = function(_, w, h)
                UI.Box(0, 0, w, h, Color(14, 18, 23, 230))
                UI.Box(0, 0, S(3), h, entry.persistent and UI.col.green or UI.col.line2)
                UI.Text(entry.name .. "  #" .. entry.ent, "symchars.body.bold", S(14), S(8), UI.col.text)
                local unit = F.Get(entry.unit)
                UI.Text((entry.mode ~= "" and entry.mode or "-") .. (unit and ("  ·  " .. unit.name) or "") .. "  ·  " .. (entry.persistent and "gespeichert" or "nicht gespeichert"), "symchars.tiny", S(14), S(34), UI.col.muted)
            end
            local function Btn(text, fn, style)
                local b = UI.Button(row, text, style or "default", fn)
                b:SetFont("symchars.button.small")
                b:Dock(RIGHT)
                b:SetWide(S(130))
                b:DockMargin(S(4), S(8), S(8), S(8))
            end
            Btn("Entfernen", function()
                UI.Confirm("Holo entfernen", "Dieses Holo-Objekt löschen?", function()
                    symchars.net.SendToServer("holo_action", { ent = entry.ent, action = "remove" })
                    timer.Simple(0.3, function() symchars.net.SendToServer("holo_list", {}) end)
                end, nil, "Entfernen")
            end, "danger")
            Btn("Hingehen", function() symchars.net.SendToServer("holo_action", { ent = entry.ent, action = "goto" }) end)
            Btn("Einstellen", function()
                local ent = Entity(entry.ent)
                if IsValid(ent) then UI.OpenHoloConfig(ent) else symchars.Notify("Objekt ist zu weit weg (nicht geladen). Erst hingehen.", "error") end
            end)
        end
        if #holoList == 0 then
            local l = vgui.Create("DLabel", scroll)
            l:Dock(TOP)
            l:SetTall(S(40))
            l:SetFont("symchars.body")
            l:SetTextColor(UI.col.muted)
            l:SetText("Keine Holo-Objekte auf dieser Karte.")
        end
    end
    UI.holoListRebuild = Rebuild
    symchars.net.SendToServer("holo_list", {})
    Rebuild()
end

symchars.net.Receive("holo_list", function(data)
    holoList = istable(data) and data or {}
    if UI.holoListRebuild then UI.holoListRebuild() end
end)

---------------------------------------------------------------------------------------------------------------
-- Whitelist (nur ohne Einheitensystem)
---------------------------------------------------------------------------------------------------------------
local function BuildWhitelist(parent)
    local top = vgui.Create("DPanel", parent)
    top:Dock(TOP)
    top:SetTall(S(48))
    top.Paint = nil
    local sid = UI.Entry(top, "SteamID64 des Spielers")
    sid:Dock(FILL)
    local players = UI.Button(top, "Online-Spieler", "default", function()
        local choices = {}
        for _, p in ipairs(player.GetAll()) do choices[#choices + 1] = { p:Nick(), p:SteamID64(), p:SteamID64() } end
        UI.Choose("Spieler", "", choices, function(v) sid:SetValue(v) sid:OnValueChange(v) end)
    end)
    players:Dock(RIGHT)
    players:SetWide(S(200))
    players:DockMargin(S(8), 0, 0, 0)
    players:SetFont("symchars.button.small")

    local list = UI.Scroll(parent)
    list:Dock(FILL)
    list:DockMargin(0, S(10), 0, 0)

    local function Rebuild()
        list:Clear()
        local id = string.Trim(sid:GetValue())
        if not string.match(id, "^%d+$") then return end
        local entry = symchars.whitelist.loaded[id] or {}
        for _, item in ipairs(UI.JobItems()) do
            local c = UI.Check(list, item.text .. "  (" .. item.id .. ")", entry[item.id] == true, function(v)
                symchars.net.SendToServer("whitelist_set", { steamid = id, job = item.id, state = v })
            end)
            c:Dock(TOP)
            c:SetTall(S(36))
            c:SetFont("symchars.body")
        end
    end
    sid.OnValueChange = Rebuild
    hook.Add("symchars_whitelist_sync", parent, Rebuild)
end

---------------------------------------------------------------------------------------------------------------
-- Seite
---------------------------------------------------------------------------------------------------------------
local function AdminTabs()
    local tabs = {}
    if not symchars.IsSuperAdmin(LocalPlayer()) then return tabs end
    if Has("symchars_settings") then tabs[#tabs + 1] = { id = "settings", name = "Einstellungen", build = BuildSettings } end
    if Has("symchars_factioncreation") then tabs[#tabs + 1] = { id = "factions", name = "Einheiten", build = BuildFactionEditor } end
    if T.CanCreate(LocalPlayer()) then tabs[#tabs + 1] = { id = "trainings", name = "Fortbildungen", build = BuildTrainingList } end
    if Has("symchars_holo") then tabs[#tabs + 1] = { id = "holo", name = "Hologramme", build = BuildHoloList } end
    if Has("symchars_charmanage") and not symchars.Config("usefactions") then tabs[#tabs + 1] = { id = "whitelist", name = "Whitelist", build = BuildWhitelist } end
    return tabs
end

local function Build(parent)
    local page = vgui.Create("DPanel", parent)
    page:Dock(FILL)
    page.Paint = nil
    local defs = AdminTabs()
    local tabs = vgui.Create("symchars.Tabs", page)
    tabs:Dock(TOP)
    tabs:SetTall(S(54))
    tabs:SetFont("symchars.h2")
    tabs:SetGap(S(48))
    local body = vgui.Create("DPanel", page)
    body:Dock(FILL)
    body:DockMargin(0, S(10), 0, 0)
    body.Paint = nil

    local byId = {}
    for _, d in ipairs(defs) do byId[d.id] = d end
    tabs:SetTabs(defs)
    tabs.OnChange = function(_, id)
        body:Clear()
        UI.lastAdminTab = id
        local holder = vgui.Create("DPanel", body)
        holder:Dock(FILL)
        holder.Paint = nil
        byId[id].build(holder)
    end
    local first = (UI.lastAdminTab and byId[UI.lastAdminTab]) and UI.lastAdminTab or (defs[1] and defs[1].id)
    if first then tabs:SetActive(first) end
end

UI.RegisterPage({
    id = "admin", name = "Admin", order = 9,
    visible = function() return #AdminTabs() > 0 end,
    build = Build,
})
