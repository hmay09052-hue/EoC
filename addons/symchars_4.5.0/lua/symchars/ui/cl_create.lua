--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Charaktererstellung
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S
local U = symchars.util
local UT = symchars.utils
local F = symchars.factions

-- Starteinheiten unterhalb (oder gleich) einer Obereinheit
local function StartUnits(root)
    local out = {}
    if root.isDefault then out[#out + 1] = root end
    for _, item in ipairs(F.GetDescendants(root)) do
        if item.data.isDefault then out[#out + 1] = item.data end
    end
    return out
end

local function Roots()
    local out = {}
    for _, root in ipairs(F.GetRoots()) do
        if not root.hidden and #StartUnits(root) > 0 then out[#out + 1] = root end
    end
    return out
end

local function UnitJob(unit)
    local r1 = unit:GetRank(1)
    if r1 and U.Trim(r1.job) ~= "" and U.GetJob(r1.job) then return r1.job end
    return unit.job
end

---------------------------------------------------------------------------------------------------------------
-- runder Fraktions-Knopf (Logo)
---------------------------------------------------------------------------------------------------------------
local ROOTBTN = {}

function ROOTBTN:Init()
    self:SetText("")
    self._hover = 0
end

function ROOTBTN:OnCursorEntered() UI.Sound("hover") end

function ROOTBTN:Think()
    self._hover = UI.Approach(self._hover, self:IsHovered() and 1 or 0, 12)
end

function ROOTBTN:Paint(w, h)
    local r = math.min(w, h) / 2 - S(4)
    local cx, cy = w / 2, h / 2
    local locked = self.locked
    local sel = self.selected
    local accent = UI.Accent()
    UI.Circle(cx, cy, r, locked and Color(25, 28, 32, 220) or Color(10, 12, 15, 235), 40)
    UI.Ring(cx, cy, r, sel and accent or UI.Lerp(self._hover, UI.col.line3, UI.col.text), sel and S(4) or S(2), 48)
    UI.DrawUnitLogo(self.faction, cx - r * 0.68, cy - r * 0.68, r * 1.36, locked and 70 or 255)
    if locked then UI.Icon("lock", cx + r * 0.3, cy + r * 0.3, r * 0.6, UI.col.dim) end
    return true
end

vgui.Register("symchars.RootButton", ROOTBTN, "DButton")

---------------------------------------------------------------------------------------------------------------
-- Seite
---------------------------------------------------------------------------------------------------------------
local function Build(parent)
    local useFactions = symchars.Config("usefactions")
    local state = { root = nil, unit = nil, job = nil, model = nil, data = {}, nat = nil }

    -- Darf mit der gewählten Nationalität in dieser Einheit gestartet werden? -> erlaubt, Sperrgrund
    local function UnitAllowed(unit)
        if not F.CanStartIn(LocalPlayer(), unit) then
            return false, unit.lockedText ~= "" and unit.lockedText or "Gesperrt"
        end
        if state.nat then
            local ok, why = UT.NationalityAllowsUnit(state.nat, unit)
            if not ok then return false, why end
        end
        return true
    end

    local page = vgui.Create("DPanel", parent)
    page:Dock(FILL)
    page.Paint = nil

    local left = UI.Scroll(page)
    local model = UI.HoloModel(page, "solid")
    model:SetSpin(0)

    local right = vgui.Create("DPanel", page)
    right.Paint = function(_, w, h)
        if state.error then
            UI.DrawWrapped(state.error, "symchars.small", 0, h - S(52), w, UI.col.red, 2)
        end
    end

    local done = UI.Check(right, "Bist du fertig?", false)
    done:SetFont("symchars.h2")
    local create = UI.Button(right, "Charakter erstellen", "default")
    create:SetFont("symchars.h1")
    create:SetEnabled(false)
    done.OnChange = function(_, v)
        create:SetEnabled(v)
        create:SetStyle(v and "primary" or "default")
    end

    local back = UI.Button(page, "Zurück", "default", function()
        UI.menu:ShowPage("characters", { autoCreate = false })
    end)
    back:SetIcon("arrow_left")
    back:SetFont("symchars.h3")

    -- Kopf
    local head = vgui.Create("DPanel", left)
    head:Dock(TOP)
    head:SetTall(S(96))
    head.Paint = function(_, w)
        UI.Text("CHARAKTERERSTELLUNG", "symchars.title", 0, 0, UI.col.text)
        UI.Aurebesh("Charaktererstellung", "symchars.aure", S(4), S(64), UI.Alpha(UI.col.dim, 160))
    end

    local function Section(title, tall)
        local p = vgui.Create("DPanel", left)
        p:Dock(TOP)
        p:DockMargin(S(24), S(12), S(10), 0)
        p:SetTall(tall)
        p:DockPadding(0, S(42), 0, 0)
        p.Paint = function()
            UI.Text(string.upper(title), "symchars.h2", 0, 0, UI.col.text)
        end
        return p
    end

    -- Modell / Vorschau aktualisieren
    local modelWrap
    local function UpdateModels()
        if IsValid(modelWrap) then modelWrap:Remove() end
        local models = U.JobModels(state.job)
        if not table.HasValue(models, state.model) then state.model = models[1] end
        model:SetHoloModel(state.model or "", { force = true })
        model:SetLabel(state.unit and (state.unit.short ~= "" and state.unit.name or state.unit.name) or (state.job and U.JobName(state.job)) or "")
        if #models <= 1 then return end

        local size = S(72)
        local perRow = math.max(1, math.floor((S(560)) / (size + S(8))))
        local rows = math.ceil(#models / perRow)
        modelWrap = Section("Aussehen", S(42) + rows * (size + S(8)))
        local grid = vgui.Create("DIconLayout", modelWrap)
        grid.Paint = nil
        grid:Dock(FILL)
        grid:SetSpaceX(S(8))
        grid:SetSpaceY(S(8))
        for _, mdl in ipairs(models) do
            local icon = grid:Add("SpawnIcon")
            icon:SetSize(size, size)
            icon:SetModel(mdl)
            icon:SetTooltip(false)
            icon.PaintOver = function(_, w, h)
                if state.model == mdl then
                    UI.Outline(0, 0, w, h, UI.Accent(), S(2))
                else
                    UI.Outline(0, 0, w, h, UI.col.line2)
                end
            end
            icon.DoClick = function()
                UI.Sound("click")
                state.model = mdl
                model:SetHoloModel(mdl)
            end
        end
        modelWrap:MoveToAfter(UI.createAnchor)
    end

    -- Fraktion & Startklasse
    local unitSection, unitList
    local function ShowUnits()
        if not IsValid(unitList) then return end
        unitList:Clear()
        local units = state.root and StartUnits(state.root) or {}
        unitSection:SetTall(S(42) + math.max(1, #units) * S(62))
        if state.unit and not UnitAllowed(state.unit) then state.unit = nil end
        for _, unit in ipairs(units) do
            local b = UI.Button(unitList, unit.name, "select")
            b:Dock(TOP)
            b:SetTall(S(54))
            b:DockMargin(0, 0, 0, S(8))
            b:SetAlign(TEXT_ALIGN_LEFT)
            b:SetFont("symchars.h2")
            b:SetAccentColor(UI.Accent())
            local allowed, why = UnitAllowed(unit)
            if not allowed then b:SetLocked(why) end
            b:SetSelected(state.unit and state.unit.uniqueID == unit.uniqueID)
            b.DoClick = function()
                if not allowed then
                    symchars.Notify(why or "Diese Startklasse ist für dich gesperrt.", "error")
                    return
                end
                state.unit = unit
                state.job = UnitJob(unit)
                for _, child in ipairs(unitList:GetChildren()) do if child.SetSelected then child:SetSelected(false) end end
                b:SetSelected(true)
                UpdateModels()
            end
            if not state.unit and allowed then b:DoClick() end
        end
        if not state.unit then
            state.job = nil
            if IsValid(modelWrap) then modelWrap:Remove() end
            model:SetHoloModel("", { force = true })
            model:SetLabel("")
            unitSection:SetTall(S(42) + S(62))
            local empty = vgui.Create("DLabel", unitList)
            empty:Dock(TOP)
            empty:SetTall(S(40))
            empty:SetFont("symchars.small")
            empty:SetTextColor(UI.col.red)
            empty:SetText(state.nat and ("Für " .. UT.NationalityName(state.nat) .. " gibt es hier keine freie Startklasse.") or "Keine freie Startklasse.")
        end
    end

    -- Nationalität (vor Fraktion/Startklasse, filtert die Startklassen)
    local RefreshRoots
    local nats = UT.VarIsEnabled("nationality") and UT.Nationalities() or {}
    if #nats > 0 then
        state.nat = nats[1].id
        local natSection = Section("Nationalität", S(42) + S(54) + S(26))
        local info = vgui.Create("DLabel", natSection)
        info:Dock(BOTTOM)
        info:SetTall(S(24))
        info:SetFont("symchars.tiny")
        info:SetTextColor(UI.col.muted)
        info:SetText("Bestimmt, welche Startklassen und Jobs dir offenstehen.")
        local row = vgui.Create("DPanel", natSection)
        row:Dock(FILL)
        row.Paint = nil
        local natButtons = {}
        if #nats <= 3 then
            for _, n in ipairs(nats) do
                local b = UI.Button(row, n.name, "select")
                b:SetFont("symchars.h2")
                b:SetAurebesh(true)
                b:SetSelected(n.id == state.nat)
                b.DoClick = function()
                    state.nat = n.id
                    for _, o in ipairs(natButtons) do o:SetSelected(o == b) end
                    if RefreshRoots then RefreshRoots() end
                end
                natButtons[#natButtons + 1] = b
            end
            row.PerformLayout = function(_, w, h)
                local gap = S(8)
                local bw = math.floor((w - gap * (#natButtons - 1)) / #natButtons)
                for i, b in ipairs(natButtons) do
                    b:SetPos((i - 1) * (bw + gap), 0)
                    b:SetSize(bw, h - S(4))
                end
            end
        else
            local combo = UI.Combo(row, "Nationalität wählen…")
            combo:Dock(FILL)
            combo:DockMargin(0, 0, 0, S(4))
            combo:SetFont("symchars.body.bold")
            for _, n in ipairs(nats) do combo:AddChoice(n.name, n.id, n.id == state.nat) end
            combo.OnSelect = function(_, _, _, id)
                state.nat = id
                if RefreshRoots then RefreshRoots() end
            end
        end
    end

    if useFactions then
        local roots = Roots()
        local rootSection = Section("Fraktion", S(42) + S(96))
        local rootRow = vgui.Create("DPanel", rootSection)
        rootRow:Dock(FILL)
        rootRow.Paint = nil
        local tip = vgui.Create("DPanel", rootRow)
        tip:SetVisible(false)
        tip.Paint = function(_, w, h)
            UI.Box(0, 0, w, h, Color(4, 6, 8, 235))
            UI.Outline(0, 0, w, h, UI.col.line3)
            UI.DrawWrapped(tip.text or "", "symchars.small", S(10), S(8), w - S(20), UI.col.dim, 2)
        end

        local function RootLock(root)
            local reason
            for _, unit in ipairs(StartUnits(root)) do
                local ok, why = UnitAllowed(unit)
                if ok then return false end
                reason = reason or why
            end
            return true, reason
        end

        for i, root in ipairs(roots) do
            local b = vgui.Create("symchars.RootButton", rootRow)
            b.faction = root
            b.locked, b.lockReason = RootLock(root)
            b:SetSize(S(92), S(92))
            b:SetPos((i - 1) * S(104), 0)
            b.OnCursorEntered = function()
                UI.Sound("hover")
                local lockText = root.lockedText ~= "" and root.lockedText or (root.name .. " ist für dich gesperrt.")
                if b.lockReason and b.lockReason ~= "Gesperrt" then lockText = root.name .. ": " .. b.lockReason end
                tip.text = b.locked and lockText or root.name
                local tw = math.min(S(420), math.max(S(160), UI.TextSize(tip.text, "symchars.small") + S(24)))
                tip:SetSize(tw, b.locked and S(56) or S(36))
                tip:SetPos(b.x + S(100), S(24))
                tip:SetVisible(true)
                tip:MoveToFront()
            end
            b.OnCursorExited = function() tip:SetVisible(false) end
            b.DoClick = function()
                if b.locked then UI.Sound("error") return end
                UI.Sound("click")
                for _, other in ipairs(rootRow:GetChildren()) do other.selected = false end
                b.selected = true
                state.root = root
                state.unit = nil
                ShowUnits()
            end
        end

        if #roots == 0 then
            rootSection.Paint = function()
                UI.Text("FRAKTION", "symchars.h2", 0, 0, UI.col.text)
                UI.Text("Es gibt keine Starteinheiten. Ein Admin muss eine Einheit als Starteinheit markieren.", "symchars.small", 0, S(46), UI.col.red)
            end
        end

        -- Sperren nach Nationalitätswechsel neu berechnen
        RefreshRoots = function()
            if not IsValid(rootRow) then return end
            local current
            for _, b in ipairs(rootRow:GetChildren()) do
                if b.faction then
                    b.locked, b.lockReason = RootLock(b.faction)
                    if b.selected then current = b end
                end
            end
            if current and not current.locked then
                ShowUnits()
                return
            end
            if current then current.selected = false end
            state.root, state.unit = nil, nil
            for _, b in ipairs(rootRow:GetChildren()) do
                if b.faction and not b.locked then b:DoClick() return end
            end
            ShowUnits()
        end

        -- erste freie Fraktion auswählen
        timer.Simple(0, function()
            if not IsValid(rootRow) then return end
            for _, b in ipairs(rootRow:GetChildren()) do
                if b.faction and not b.locked then b:DoClick() break end
            end
        end)
    end

    -- Name
    local nameSection = Section("Name", S(42) + (symchars.Config("usesurnamefield") and S(104) or S(52)))
    local nameEntry = UI.Entry(nameSection, "Name deines Charakters")
    nameEntry:Dock(TOP)
    nameEntry:SetTall(S(50))
    nameEntry:SetFont("symchars.h2")
    local surnameEntry
    if symchars.Config("usesurnamefield") then
        surnameEntry = UI.Entry(nameSection, "Nachname")
        surnameEntry:Dock(TOP)
        surnameEntry:DockMargin(0, S(6), 0, 0)
        surnameEntry:SetTall(S(46))
    end

    -- RP-ID
    local rpidEntry
    if symchars.Config("useroleplayid") then
        local rpidSection = Section("RP-ID", S(42) + S(80))
        local row = vgui.Create("DPanel", rpidSection)
        row:Dock(TOP)
        row:SetTall(S(50))
        row.Paint = nil
        local prefixLabel = vgui.Create("DPanel", row)
        prefixLabel:Dock(LEFT)
        prefixLabel:SetWide(S(90))
        prefixLabel.Paint = function(_, w, h)
            local prefix = UT.GetRPIDRule(state.job, state.unit and state.unit.uniqueID)
            UI.Box(0, 0, w, h, UI.col.panel3)
            UI.Outline(0, 0, w, h, UI.col.line2)
            UI.Text(prefix ~= "" and prefix or "#", "symchars.h2", w / 2, h / 2, UI.Accent(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        rpidEntry = UI.Entry(row, "Ziffern")
        rpidEntry:Dock(FILL)
        rpidEntry:DockMargin(S(6), 0, 0, 0)
        rpidEntry:SetFont("symchars.h2")
        rpidEntry:SetNumeric(true)
        local hint = vgui.Create("DPanel", rpidSection)
        hint:Dock(TOP)
        hint:SetTall(S(26))
        hint.Paint = function(_, w)
            local prefix, length = UT.GetRPIDRule(state.job, state.unit and state.unit.uniqueID)
            local digits = rpidEntry:GetValue()
            local preview = prefix .. digits .. string.rep("X", math.max(0, length - #digits))
            UI.Text(length .. " Ziffern  ·  Vorschau: " .. preview, "symchars.small", 0, S(6), UI.col.muted)
        end
    end

    -- Startklasse (Einheiten) oder Job
    if useFactions then
        unitSection = Section("Startklasse", S(42) + S(62))
        unitList = vgui.Create("DPanel", unitSection)
        unitList:Dock(FILL)
        unitList.Paint = nil
        UI.createAnchor = unitSection
    else
        local jobs = {}
        for _, job in pairs(RPExtraTeams or {}) do
            if symchars.whitelist.Has(LocalPlayer(), job.command) then jobs[#jobs + 1] = job end
        end
        local jobSection = Section("Job", S(42) + math.max(1, #jobs) * S(58))
        UI.createAnchor = jobSection
        for _, job in ipairs(jobs) do
            local b = UI.Button(jobSection, job.name, "select")
            b:Dock(TOP)
            b:SetTall(S(50))
            b:DockMargin(0, 0, 0, S(8))
            b:SetAlign(TEXT_ALIGN_LEFT)
            b:SetFont("symchars.h3")
            b.DoClick = function()
                state.job = job.command
                for _, child in ipairs(jobSection:GetChildren()) do if child.SetSelected then child:SetSelected(false) end end
                b:SetSelected(true)
                UpdateModels()
            end
            if not state.job then b:DoClick() end
        end
        if #jobs == 0 then
            jobSection.Paint = function()
                UI.Text("JOB", "symchars.h2", 0, 0, UI.col.text)
                UI.Text("Du bist für keinen Job freigeschaltet.", "symchars.small", 0, S(46), UI.col.red)
            end
        end
    end

    -- Zusatzfelder
    local dataControls = {}
    for _, var in ipairs(symchars.chars.dataOrder) do
        local def = symchars.chars.data[var]
        if var == "nationality" and #nats > 0 then
            dataControls[var] = function() return state.nat end
        elseif def and def.IsField and UT.VarIsEnabled(var) then
            local tall = def.type == "text" and S(150) or S(52)
            local sec = Section(def.FieldName or var, S(42) + tall + (def.FieldInfo and S(26) or 0))
            if def.FieldInfo then
                local info = vgui.Create("DLabel", sec)
                info:Dock(BOTTOM)
                info:SetTall(S(24))
                info:SetFont("symchars.tiny")
                info:SetTextColor(UI.col.muted)
                info:SetText(def.FieldInfo)
            end
            if def.type == "choice" then
                local combo = UI.Combo(sec, "Auswählen…")
                combo:Dock(FILL)
                local default = symchars.chars.DataDefault(def)
                for _, choice in ipairs(symchars.chars.DataChoices(def)) do combo:AddChoice(choice[1], choice[2], choice[2] == default) end
                dataControls[var] = function() return combo:GetSelectedData() or default end
            else
                local entry = UI.Entry(sec, def.FieldName or var)
                entry:Dock(FILL)
                if def.type == "text" then entry:SetMultiline(true) entry:SetFont("symchars.body") end
                dataControls[var] = function() return entry:GetValue() end
            end
        end
    end

    local spacer = vgui.Create("DPanel", left)
    spacer:Dock(TOP)
    spacer:SetTall(S(40))
    spacer.Paint = nil

    -- Erstellen
    create.DoClick = function()
        state.error = nil
        local name = string.Trim(nameEntry:GetValue())
        local full = name .. (surnameEntry and string.Trim(surnameEntry:GetValue()) ~= "" and (" " .. string.Trim(surnameEntry:GetValue())) or "")
        local ok, err = UT.ValidateName(full)
        if not ok then state.error = err nameEntry:SetError(true) UI.Sound("error") return end
        nameEntry:SetError(false)

        if useFactions and not state.unit then
            state.error = state.nat and ("Für " .. UT.NationalityName(state.nat) .. " gibt es hier keine freie Startklasse.") or "Wähle eine Startklasse."
            UI.Sound("error")
            return
        end
        if not useFactions and not state.job then state.error = "Wähle einen Job." UI.Sound("error") return end
        if not useFactions and state.nat and UT.NationalityBlocksJob(state.nat, state.job) then
            state.error = "Als " .. UT.NationalityName(state.nat) .. " kannst du diesen Job nicht nehmen."
            UI.Sound("error")
            return
        end

        local rpid
        if rpidEntry then
            local _, length = UT.GetRPIDRule(state.job, state.unit and state.unit.uniqueID)
            rpid = string.Trim(rpidEntry:GetValue())
            if not UT.IsValidRPIDNumber(rpid, length) then
                state.error = "Die RP-ID muss genau " .. length .. " Ziffern haben."
                rpidEntry:SetError(true)
                UI.Sound("error")
                return
            end
            rpidEntry:SetError(false)
        end

        local data = {}
        for var, get in pairs(dataControls) do data[var] = get() end
        for var in pairs(dataControls) do
            local def = symchars.chars.data[var]
            local valid, msg = def.OnValidate(data[var])
            if valid == false then state.error = msg or ((def.FieldName or var) .. " ist ungültig.") UI.Sound("error") return end
        end

        create:SetEnabled(false)
        create:SetText("Wird erstellt…")
        symchars.net.SendToServer("char_create", {
            name = name, surname = surnameEntry and surnameEntry:GetValue() or nil, model = state.model,
            faction = state.unit and state.unit.uniqueID, job = state.job, rpid = rpid, data = data,
        })
        timer.Simple(5, function()
            if IsValid(create) and not create:IsEnabled() then
                create:SetEnabled(true)
                create:SetText("Charakter erstellen")
            end
        end)
    end

    page.PerformLayout = function(_, w, h)
        local leftW = math.min(S(680), w * 0.42)
        left:SetPos(0, 0)
        left:SetSize(leftW, h - S(70))
        back:SetSize(S(200), S(52))
        back:SetPos(S(24), h - S(52))
        local rightW = math.min(S(400), w * 0.25)
        model:SetPos(leftW + S(10), 0)
        model:SetSize(w - leftW - rightW - S(20), h)
        right:SetPos(w - rightW, h * 0.32)
        right:SetSize(rightW, S(260))
        done:SetPos(0, 0)
        done:SetSize(rightW, S(56))
        create:SetPos(0, S(74))
        create:SetSize(rightW, S(72))
    end

    symchars.net.Receive("char_create_failed", function(data)
        state.error = istable(data) and data.msg or "Fehler beim Erstellen."
        if IsValid(create) then
            create:SetEnabled(true)
            create:SetText("Charakter erstellen")
        end
    end)

    nameEntry:RequestFocus()
end

UI.RegisterPage({ id = "create", name = "Erstellen", order = 99, visible = function() return false end, build = Build })

symchars.net.Receive("char_created", function()
    if IsValid(UI.menu) then
        timer.Simple(0.2, function()
            if IsValid(UI.menu) then UI.menu:ShowPage("characters", { autoCreate = false }) end
        end)
    end
end)
