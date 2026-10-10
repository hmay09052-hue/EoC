local KMS = KrakensMedical
local AID = KMS.AID
local L = KMS.L
local Scale = KF.Scale

KMS.UI = KMS.UI or {}

local function C(key)
    return KF.UI.GetColor(key, AID)
end

local function F(name)
    return KF.Fonts.Get(AID, name)
end

local function FB(name)
    return KF.Fonts.GetBold(AID, name)
end

local Btn = KMS.Button

local function DockAdd(panel, top, bot)
    panel:Dock(TOP)
    panel:DockMargin(0, top or 0, 0, bot or Scale(6))
    return panel
end

local function HoverSound(panel)
    panel.OnCursorEntered = function() KMS.PlaySound("Hover") end
    return panel
end

local function RowBackground(s, w, h, selected)
    local hoverLerp = KF.Anim.UpdateHoverLerp(s, 10)
    surface.SetDrawColor(KF.UI.ColorAlpha(C("PanelDark"), 200 + 30 * hoverLerp))
    surface.DrawRect(0, 0, w, h)
    if selected then
        surface.SetDrawColor(C("AccentSubtle"))
        surface.DrawRect(0, 0, w, h)
    end
    return hoverLerp
end

local function CloseButton(frame)
    local btn = KF.Menu.CloseButton(frame, frame:GetWide() - Scale(44), Scale(8), FB("header"), nil)
    btn:SetSize(Scale(24), Scale(24))
    btn.DoClick = function()
        KMS.PlaySound("Click")
        frame:Remove()
    end
    return HoverSound(btn)
end

local tooltipState = { text = nil, panel = nil }

local function StyleTooltip(panel, text)
    panel.OnCursorEntered = function()
        tooltipState.text = text
        tooltipState.panel = panel
    end
    panel.OnCursorExited = function()
        if tooltipState.panel == panel then
            tooltipState.text = nil
            tooltipState.panel = nil
        end
    end
end

hook.Add("PostRenderVGUI", "KMS_MenuTooltip", function()
    local panel = tooltipState.panel
    if not tooltipState.text or not IsValid(panel) or not panel:IsHovered() then
        tooltipState.text = nil
        return
    end
    local font = F("small")
    surface.SetFont(font)
    local _, lineH = surface.GetTextSize("A")
    local isList = istable(tooltipState.text)
    local lines
    if isList then
        lines = {}
        for _, entry in ipairs(tooltipState.text) do
            local color = entry.good == true and C("Success") or entry.good == false and C("Error") or C("TextPrimary")
            for i, line in ipairs(KF.WrapText(entry.text, font, Scale(300))) do
                lines[#lines + 1] = { text = i == 1 and "·  " .. line or "    " .. line, color = color }
            end
        end
    else
        lines = KF.WrapText(tooltipState.text, font, Scale(280))
    end
    local textW = 0
    for _, line in ipairs(lines) do
        local lineW = surface.GetTextSize(isList and line.text or line)
        if lineW > textW then textW = lineW end
    end
    local padX, padY = Scale(10), Scale(6)
    local w = textW + padX * 2
    local h = #lines * lineH + padY * 2
    local px, py = panel:LocalToScreen(0, 0)
    local pw = panel:GetWide()
    local x = math.Clamp(px + pw / 2 - w / 2, Scale(4), ScrW() - w - Scale(4))
    local y = py - h - Scale(8)
    if y < Scale(4) then y = py + panel:GetTall() + Scale(8) end
    KF.Draw.NotchedBox(x, y, w, h, Scale(6), C("Panel"), C("BorderAccent"), 1, "left")
    for i, line in ipairs(lines) do
        if isList then
            draw.SimpleText(line.text, font, x + padX, y + padY + (i - 1) * lineH, line.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        else
            draw.SimpleText(line, font, x + w / 2, y + padY + (i - 1) * lineH, C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end
end)

function KMS.DescribeItem(itemId)
    local lines = {}
    local function add(text, good)
        lines[#lines + 1] = { text = text, good = good }
    end
    local def
    for _, treatment in ipairs(KMS.Treatments) do
        if treatment.item == itemId then
            def = treatment
            break
        end
    end
    local handbook = KMS.HandbookByItem and KMS.HandbookByItem[itemId]
    if handbook then
        add(L("hb_line_effect", L("hb_eff_" .. handbook.key)))
        add(L("hb_line_use", L("hb_use_" .. handbook.key)))
        add(L("hb_line_dose", L("hb_dose_" .. handbook.key)))
    end
    local stats = KMS.BandageStats[itemId]
    local med = KMS.Meds[itemId]
    if stats then
        local ranked, best = {}, {}
        for woundType, entry in pairs(stats) do
            if KMS.Wounds[woundType].bleed > 0 then
                ranked[#ranked + 1] = { t = woundType, eff = entry.eff[2] }
            elseif entry.eff[2] >= 2.5 then
                best[#best + 1] = L("wound_" .. woundType)
            end
        end
        table.sort(ranked, function(a, b) return a.eff > b.eff end)
        for i = 1, math.min(3, #ranked) do
            if #best >= 3 then break end
            best[#best + 1] = L("wound_" .. ranked[i].t)
        end
        add(L("wiki_bandage_best", table.concat(best, ", ")), true)
        add(L("wiki_bandage_worst", L("wound_" .. ranked[#ranked].t)), false)
        if KMS.Settings.reopenEnabled and stats.cut.reopen[2] > 0 then
            local reopen = math.min(100, math.Round(stats.cut.reopen[2] * 100 * KMS.Coef("woundReopenChance")))
            add(L("wiki_reopen", reopen, KF.FormatTime(stats.cut.delay[1]), KF.FormatTime(stats.cut.delay[2])), false)
        end
        local side = def and def.sideMed and KMS.Meds[def.sideMed]
        if side then
            add(L("wiki_sw_side", math.Round(side.painReduce * 100)), true)
        end
        add(L("wiki_bandage_use"))
    elseif med then
        if med.stasis then
            add(L("wiki_sw_stasis", KF.FormatTime(med.duration)), true)
        elseif med.sedate then
            add(L("wiki_sw_sedate", KF.FormatTime(med.sedate)))
        end
        if med.wake then add(L("wiki_sw_wake"), true) end
        if med.shock then add(L("wiki_sw_shock"), true) end
        if def and def.healsFracture then add(L("wiki_sw_fracture"), true) end
        if med.radShield then add(L("wiki_sw_rad"), true) end
        if med.toxShield then add(L("wiki_sw_tox"), true) end
        if med.purge then
            local names = {}
            for i, medId in ipairs(med.purge) do
                names[i] = L("item_" .. medId)
            end
            add(L("wiki_sw_purge", table.concat(names, ", ")), true)
        end
        if med.verax then add(L("wiki_sw_verax", KF.FormatTime(med.verax)), false) end
        if med.arrest then add(L("wiki_sw_arrest"), false) end
        if med.viscosity >= 5 then
            add(L("wiki_sw_thick"))
        elseif med.viscosity <= -5 then
            add(L("wiki_sw_thin"))
        end
        if med.painReduce > 0 then
            add(L("wiki_med_pain", math.Round(med.painReduce * 100)), true)
        end
        if (med.heal or 0) > 0 then
            add(L("wiki_med_heal", math.Round(med.heal * 100)), true)
        end
        if (med.stamina or 0) > 0 then
            add(L("wiki_med_stamina", math.Round(med.stamina * 100)), true)
        end
        local hr = med.hr[2][2]
        if hr > 2 then
            add(L("wiki_med_hr_up", math.Round(hr)))
        elseif hr < -2 then
            add(L("wiki_med_hr_down", math.Round(-hr)))
        end
        add(L("wiki_med_duration", KF.FormatTime(med.timeKey and KMS.Settings[med.timeKey] or med.duration)))
        add(L("wiki_med_maxdose", med.maxDose), false)
    elseif def and (def.ivMl or def.ivScale) then
        local ml = def.ivMl or math.Round(KMS.Settings.ivVolume * def.ivScale)
        add(L("wiki_iv", ml, KF.FormatTime(math.ceil(ml / (KMS.IVDripRate * KMS.Coef("ivFlowRate"))))), true)
        add(L("wiki_iv_use"))
    elseif def and def.rp then
        add(L("wiki_sw_rp"))
    else
        local fixed = ({ tourniquet = "wiki_tourniquet", splint = "wiki_splint", surgical_kit = "wiki_surgical", pak = "wiki_pak" })[itemId]
        if fixed then add(L(fixed)) end
    end
    local tier = def and KMS.TreatmentTier(def.id) or 0
    if tier > 0 then
        add(L("wiki_tier", tier))
    end
    return lines
end

local function WikiText(itemId)
    local parts = {}
    for _, entry in ipairs(KMS.DescribeItem(itemId)) do
        parts[#parts + 1] = entry.text
    end
    return table.concat(parts, " ")
end

local menuState = {
    frame = nil,
    patient = nil,
    part = "torso",
    cat = "examine",
}

local TAB_ICONS = KMS.MenuIcons

local TAB_CATS = { "examine", "bandage", "meds", "advanced", "drag" }

local function MenuOpen()
    return IsValid(menuState.frame) and menuState.frame.KMSRefs ~= nil
end

-- Strivon: das Comlink-Medic-Menü (linker Arm, wie Funk/Squad/Textfunk) zählt auch als offenes Medizinmenü
KMS.ComlinkAware = true

function KMS.UI.ClassicMenuPatient()
    return MenuOpen() and menuState.patient or nil
end

function KMS.UI.MenuPatient()
    local comlinkPatient = KMS.ComlinkMenuPatient and KMS.ComlinkMenuPatient() or nil
    if comlinkPatient then return comlinkPatient end
    return MenuOpen() and menuState.patient or nil
end

local function Snapshot()
    return menuState.patient and KMS.PatientSnapshots[menuState.patient] or nil
end

local function PatientName(patient)
    if patient == LocalPlayer() then return L("ui_self") end
    return KMS.PatientName(patient)
end

local function SectionLabel(parent, textKey, showLine)
    local label = vgui.Create("DPanel", parent)
    label:Dock(TOP)
    label:SetTall(Scale(34))
    label.Paint = function(_, w, h)
        draw.SimpleText(L(textKey), FB("subheader"), w / 2, h / 2, C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if showLine ~= false then
            local inset = Scale(20)
            surface.SetDrawColor(C("BorderAccent"))
            surface.DrawRect(inset, h - 1, w - inset * 2, 1)
        end
    end
    return label
end

local function PanelBase(parent, notchSide)
    local panel = vgui.Create("DPanel", parent)
    panel.Paint = function(_, w, h)
        KF.Draw.Panel(0, 0, w, h, { addonId = AID, notchSide = notchSide, hasNotch = notchSide ~= false })
    end
    return panel
end

local function EntryList(parent, titleKey, notchSide)
    local panel = PanelBase(parent, notchSide)
    SectionLabel(panel, titleKey)
    local leftNotch = isstring(notchSide) and string.find(notchSide, "Left")
    local leftInset = leftNotch and Scale(24) or Scale(10)
    local scroll = vgui.Create("KF.ScrollPanel", panel)
    scroll:SetAddon(AID)
    scroll:Dock(FILL)
    scroll:DockMargin(leftInset, Scale(6), Scale(10), Scale(8))
    panel.SetEntries = function(_, entries)
        scroll:Clear()
        for _, entry in ipairs(entries or {}) do
            local row = vgui.Create("DPanel", scroll)
            row:Dock(TOP)
            row:SetTall(Scale(20))
            row.Paint = function(_, w, h)
                draw.SimpleText(KMS.FormatEntry(entry), F("small"), 0, h / 2, C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    end
    return panel
end

local function SnapshotPart(partId)
    local snapshot = Snapshot()
    return snapshot and snapshot.parts and snapshot.parts[partId]
end

local function ActionButton(scroll, label)
    local btn = Btn(scroll, label)
    btn:Dock(TOP)
    btn:DockMargin(0, 0, 0, Scale(4))
    btn:SetTall(Scale(30))
    return btn
end

local function ConfigRow(parent, labelKey)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(Scale(40))
    row:DockMargin(0, 0, 0, Scale(2))
    row.Paint = function(_, w, h)
        draw.SimpleText(L(labelKey), F("body"), 0, h / 2, C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    return row
end

local function ConfigChoiceRow(parent, labelKey, convar, values, wide, labelFor)
    local row = ConfigRow(parent, labelKey)
    for i = #values, 1, -1 do
        local value = values[i]
        local btn = Btn(row, labelFor(value))
        btn:Dock(RIGHT)
        btn:DockMargin(Scale(4), Scale(4), 0, Scale(4))
        btn:SetWide(wide)
        btn.Think = function(s)
            s:SetSolid(GetConVar(convar):GetInt() == value)
        end
        btn.DoClick = function()
            RunConsoleCommand(convar, tostring(value))
        end
    end
end

local function ConfigCheckRow(parent, labelKey, convar)
    local row = ConfigRow(parent, labelKey)
    local check = vgui.Create("KF.Checkbox", row)
    check:Dock(RIGHT)
    check:DockMargin(0, Scale(6), 0, Scale(6))
    check:SetWide(Scale(30))
    check:SetAddon(AID)
    check:SetSound(KMS.Sounds.Click)
    check:SetHoverSound(KMS.Sounds.Hover)
    check:SetChecked(GetConVar(convar):GetInt() ~= 0)
    check.OnChange = function(_, checked)
        RunConsoleCommand(convar, checked and "1" or "0")
    end
end

local function KeyBinder(row, value, onChange)
    local binder = vgui.Create("DBinder", row)
    binder:Dock(RIGHT)
    binder:DockMargin(0, Scale(4), 0, Scale(4))
    binder:SetWide(Scale(160))
    binder:SetValue(value)
    binder:SetText("")
    binder.UpdateText = function(s) s:SetText("") end
    binder.Paint = function(s, w, h)
        local lerp = KF.Anim.UpdateHoverLerp(s, 10)
        draw.RoundedBox(4, 0, 0, w, h, KF.UI.LerpColor(lerp, C("PanelDark"), C("PanelLight")))
        surface.SetDrawColor(KF.UI.LerpColor(lerp, C("Border"), C("Accent")))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local key = s.Trapping and L("cfg_press_key") or string.upper(input.GetKeyName(s:GetSelectedNumber()) or L("cfg_key_none"))
        draw.SimpleText(key, F("small"), w / 2, h / 2, C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    binder.OnCursorEntered = function() KMS.PlaySound("Hover") end
    binder.DoClick = function(s)
        KMS.PlaySound("Click")
        input.StartKeyTrapping()
        s.Trapping = true
    end
    binder.OnChange = function(_, keyCode)
        if keyCode and keyCode > 0 then onChange(keyCode) end
    end
    return binder
end

local function ConfigKeyRow(parent, labelKey, convar, settingKey)
    local row = ConfigRow(parent, labelKey)
    KeyBinder(row, KMS.BindKey(GetConVar(convar), settingKey), function(keyCode)
        RunConsoleCommand(convar, tostring(keyCode))
    end)
end

local DROPDOWN_W = 320

local function StyleDropdown(dropdown, options, selected)
    dropdown:SetAddon(AID)
    dropdown:SetSound(KMS.Sounds.Click)
    dropdown:SetHoverSound(KMS.Sounds.Hover)
    for _, option in ipairs(options) do
        dropdown:AddOption(option.value, option.label)
    end
    dropdown:SetValue(selected)
end

local function BuildActions(scroll)
    scroll:Clear()
    local snapshot = Snapshot()
    if menuState.cat == "triage" then
        local current = snapshot and snapshot.states and snapshot.states.triage or 0
        for _, level in ipairs(KMS.TriageLevels) do
            if level.id ~= 4 then
                local btn = ActionButton(scroll, L(level.key))
                btn:SetAccent(level.color)
                btn:SetSolid(level.id == current)
                btn.DoClick = function()
                    KMS.SendTriage(menuState.patient, level.id)
                end
            end
        end
        return
    end
    if menuState.cat == "drag" then
        local ply = LocalPlayer()
        local isPlayerPatient = menuState.patient ~= ply and menuState.patient:IsPlayer()
        local hauling = ply:GetNWString("kms_hauling", "") ~= ""
        local unconscious = snapshot and snapshot.states and snapshot.states.conscious == false
        local canHaul = isPlayerPatient and unconscious and not hauling
        local options = {
            { label = L("int_drag"), enabled = canHaul },
            { label = L("int_carry"), enabled = canHaul, carry = true },
        }
        for _, option in ipairs(options) do
            local btn = ActionButton(scroll, option.label)
            btn:SetEnabled(option.enabled == true)
            btn.DoClick = function()
                KMS.LastTreatSource = "menu"
                net.Start("KMS_Drag")
                net.WriteEntity(menuState.patient)
                net.WriteBool(option.carry == true)
                net.SendToServer()
            end
        end
        local root = KMS.FindVehicleRoot()
        local loadedIn = isPlayerPatient and menuState.patient:GetNWEntity("kms_loaded_in") or NULL
        local unconsciousTarget = isPlayerPatient and unconscious
        local loadBtn = ActionButton(scroll, L("int_load_vehicle"))
        local canLoad = unconsciousTarget and IsValid(root) and not IsValid(loadedIn)
        loadBtn:SetEnabled(canLoad)
        if not canLoad then
            StyleTooltip(loadBtn, not unconsciousTarget and L("err_target_conscious")
                or not IsValid(root) and L("err_no_vehicle")
                or IsValid(loadedIn) and L("err_already_loaded")
                or L("err_invalid"))
        end
        loadBtn.DoClick = function()
            net.Start("KMS_VehicleLoad")
            net.WriteEntity(menuState.patient)
            net.WriteEntity(root)
            net.SendToServer()
        end
        local unloadBtn = ActionButton(scroll, L("int_unload_vehicle"))
        unloadBtn:SetEnabled(IsValid(loadedIn))
        unloadBtn.DoClick = function()
            net.Start("KMS_VehicleLoad")
            net.WriteEntity(menuState.patient)
            net.WriteEntity(NULL)
            net.SendToServer()
        end
        local invBtn = ActionButton(scroll, L("int_veh_inventory"))
        local canInv = IsValid(root) and KMS.IsMedVehicle(root) and KMS.VehInvAccess(ply)
            and KMS.Settings.itemSharing and not KMS.Settings.infiniteSupplies
        invBtn:SetEnabled(canInv)
        if not canInv then
            StyleTooltip(invBtn, not IsValid(root) and L("err_no_vehicle")
                or not KMS.IsMedVehicle(root) and L("err_not_medvehicle")
                or (not KMS.Settings.itemSharing or KMS.Settings.infiniteSupplies) and L("err_sharing_off")
                or L("err_npc_denied"))
        end
        invBtn.DoClick = function()
            KMS.OpenVehicleInventory(root)
        end
        return
    end
    if menuState.cat == "inventory" and KMS.Settings.infiniteSupplies then
        menuState.cat = "examine"
    end
    if menuState.cat == "inventory" then
        KMS.BuildInventory(scroll)
        return
    end
    local sharing = KMS.Settings.itemSharing and not KMS.Settings.infiniteSupplies
        and menuState.patient ~= LocalPlayer() and menuState.patient:IsPlayer()
    if sharing then
        local toggle = Btn(scroll, menuState.usePatient and L("treat_use_patient") or L("treat_use_own"))
        toggle:Dock(TOP)
        toggle:DockMargin(0, 0, 0, Scale(4))
        toggle:SetTall(Scale(30))
        toggle.DoClick = function()
            menuState.usePatient = not menuState.usePatient
            KMS.UI.Refresh()
        end
    end
    local usePatient = sharing and menuState.usePatient == true
    local shown = 0
    for _, def in ipairs(KMS.Treatments) do
        if def.cat == menuState.cat and KMS.CanShowTreatment(def)
            and not KMS.LacksItem(def, snapshot, usePatient) then
            shown = shown + 1
            local btn = ActionButton(scroll, KMS.ActionLabel(def, usePatient and snapshot and snapshot.inv or nil))
            local reason = KMS.TreatmentBlockReason(def, snapshot, menuState.patient, menuState.part, usePatient)
            btn:SetEnabled(reason == nil)
            if reason then
                StyleTooltip(btn, reason)
            elseif def.item then
                local wiki = KMS.DescribeItem(def.item)
                if wiki[1] then StyleTooltip(btn, wiki) end
            end
            btn.DoClick = function()
                KMS.SendTreat(menuState.patient, def.id, menuState.part, usePatient, "menu")
            end
        end
    end
    if shown == 0 then
        local msg = vgui.Create("DPanel", scroll)
        msg:Dock(TOP)
        msg:SetTall(Scale(40))
        msg.Paint = function(_, w, h)
            draw.SimpleText(L("menu_no_supplies"), F("body"), w / 2, h / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

local function OverviewLines()
    local snapshot = Snapshot()
    local partState = SnapshotPart(menuState.part)
    local lines = { { text = KMS.PartLabel(menuState.part), color = C("TextPrimary"), bold = true } }
    local partLines = KMS.PartLines(partState, menuState.part)
    if #partLines == 0 then
        lines[#lines + 1] = { text = L("ov_no_injuries"), color = C("TextMuted") }
    else
        for _, line in ipairs(partLines) do
            lines[#lines + 1] = line
        end
    end
    lines[#lines + 1] = { text = "", color = C("TextMuted") }
    local states = snapshot and snapshot.states
    if states then
        if KMS.SnapshotBleeding(snapshot) then
            lines[#lines + 1] = { text = L("int_bleeding"), color = KMS.StatusColors.critical, bold = true }
        end
        if states.bloodClass and states.bloodClass > 1 then
            lines[#lines + 1] = KMS.BloodClassLine(states.bloodClass)
        end
        for _, line in ipairs(KMS.IVLines(states)) do
            lines[#lines + 1] = line
        end
        local hideVitals = KMS.Settings.diagnosisMode == "examine"
        if states.arrest and not hideVitals then
            lines[#lines + 1] = { text = L("st_arrest"), color = KMS.StatusColors.critical, bold = true }
        elseif not states.conscious then
            lines[#lines + 1] = { text = L("st_unconscious"), color = KMS.StatusColors.open }
        end
        if states.stable and not hideVitals then
            lines[#lines + 1] = { text = L("st_stable"), color = C("Success") }
        end
        if states.painBand and states.painBand > 0 then
            lines[#lines + 1] = KMS.PainLine(states.painBand)
        end
        for medId, count in pairs(snapshot.meds or {}) do
            lines[#lines + 1] = { text = L("ov_meds", count, L("item_" .. medId)), color = C("TextSecondary") }
        end
        if states.triage and states.triage > 0 then
            local triage = KMS.TriageById[states.triage]
            lines[#lines + 1] = { text = L(triage.key), color = triage.color, bold = true }
        end
    end
    return lines
end

function KMS.UI.Refresh()
    if not MenuOpen() then return end
    local refs = menuState.frame.KMSRefs
    local config = menuState.cat == "config"
    local guide = menuState.cat == "guide"
    local titleKey = guide and "guide_title" or config and "cfg_title"
    menuState.frame:SetFrameTitle(titleKey and string.upper(L(titleKey)) or menuState.frame.KMSTitle)
    menuState.frame:SetSubtitle(config and "" or L("ui_subtitle"))
    refs.settings:SetVisible(config)
    refs.guide:SetVisible(guide)
    for _, panel in ipairs(refs.patient) do
        panel:SetVisible(not config and not guide)
    end
    refs.settings:GetParent():InvalidateLayout(true)
    if config or guide then return end
    if not IsValid(menuState.patient) then return end
    local snapshot = Snapshot()
    BuildActions(refs.actions)
    refs.overview.SetLines(OverviewLines())
    refs.activity:SetEntries(snapshot and snapshot.log)
    refs.quick:SetEntries(snapshot and snapshot.quick)
end

local function GearPoly(cx, cy, outer, inner, teeth)
    local poly = {}
    local steps = teeth * 2
    for i = 0, steps - 1 do
        local ang = (i / steps) * math.pi * 2 - math.pi / 2
        local r = i % 2 == 0 and outer or inner
        poly[#poly + 1] = { x = cx + math.cos(ang) * r, y = cy + math.sin(ang) * r }
    end
    return poly
end

local function DrawGear(cx, cy, r, color)
    draw.NoTexture()
    surface.SetDrawColor(color.r, color.g, color.b, color.a or 255)
    surface.DrawPoly(GearPoly(cx, cy, r, r * 0.74, 8))
    local hole = math.max(2, math.Round(r * 0.42))
    surface.SetDrawColor(C("Background"))
    draw.NoTexture()
    surface.DrawPoly(GearPoly(cx, cy, hole, hole, 16))
end

local function DrawShield(cx, cy, r, color)
    surface.SetDrawColor(color)
    draw.NoTexture()
    surface.DrawPoly({
        { x = cx - r * 0.85, y = cy - r * 0.7 },
        { x = cx + r * 0.85, y = cy - r * 0.7 },
        { x = cx + r * 0.85, y = cy + r * 0.1 },
        { x = cx, y = cy + r },
        { x = cx - r * 0.85, y = cy + r * 0.1 },
    })
end

local function BuildMenu(patient)
    local frame = vgui.Create("KF.Frame")
    frame:SetAddon(AID)
    frame:SetSize(Scale(1180), Scale(780))
    frame:Center()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame.KMSTitle = string.upper(PatientName(patient))
    frame.KMSLang = KF.Lang.GetCurrent(AID)
    frame:SetFrameTitle(frame.KMSTitle)
    frame:SetSubtitle(L("ui_subtitle"))
    frame:SetHeaderHeight(52)
    frame:SetHeaderLine(false)
    frame:SetTitleFont("header")
    frame:SetSubtitleFont("body")
    menuState.frame = frame

    CloseButton(frame)

    if KMS.IsAdmin(LocalPlayer()) then
        local admin = HoverSound(vgui.Create("DButton", frame))
        admin:SetText("")
        admin:SetSize(Scale(24), Scale(24))
        admin:SetPos(frame:GetWide() - Scale(44) - Scale(32) * 3, Scale(8))
        StyleTooltip(admin, L("adm_title"))
        admin.Paint = function(s, w, h)
            local lerp = KF.Anim.UpdateHoverLerp(s, 10)
            DrawShield(w / 2, h / 2, Scale(8), KF.UI.LerpColor(lerp, C("TextMuted"), C("TextPrimary")))
        end
        admin.DoClick = function()
            KMS.PlaySound("Click")
            frame:Remove()
            net.Start("KMS_RequestSync")
            net.WriteBool(true)
            net.SendToServer()
        end
    end

    local guide = HoverSound(vgui.Create("DButton", frame))
    guide:SetText("")
    guide:SetSize(Scale(24), Scale(24))
    guide:SetPos(frame:GetWide() - Scale(44) - Scale(32) * 2, Scale(8))
    StyleTooltip(guide, L("guide_title"))
    guide.Paint = function(s, w, h)
        local lerp = KF.Anim.UpdateHoverLerp(s, 10)
        local active = menuState.cat == "guide"
        surface.SetDrawColor(active and C("Accent") or KF.UI.LerpColor(lerp, C("TextMuted"), C("TextPrimary")))
        local t = Scale(2)
        local arm = Scale(14)
        surface.DrawRect(w / 2 - t / 2, (h - arm) / 2, t, arm)
        surface.DrawRect((w - arm) / 2, h / 2 - t / 2, arm, t)
    end
    guide.DoClick = function()
        KMS.PlaySound("Click")
        KMS.OpenGuide()
    end

    local config = HoverSound(vgui.Create("DButton", frame))
    config:SetText("")
    config:SetSize(Scale(24), Scale(24))
    config:SetPos(frame:GetWide() - Scale(44) - Scale(32), Scale(8))
    StyleTooltip(config, L("cfg_title"))
    config.Paint = function(s, w, h)
        local lerp = KF.Anim.UpdateHoverLerp(s, 10)
        local active = menuState.cat == "config"
        local color = active and C("Accent") or KF.UI.LerpColor(lerp, C("TextMuted"), C("TextPrimary"))
        if KMS.MenuIcons.config then
            local size = Scale(14)
            KMS.DrawIcon(KMS.MenuIcons.config, (w - size) / 2, (h - size) / 2, size, size, color)
        else
            DrawGear(w / 2, h / 2, Scale(7), color)
        end
    end
    config.DoClick = function()
        KMS.PlaySound("Click")
        if menuState.cat == "config" then
            menuState.cat = menuState.lastCat or "examine"
        else
            if menuState.cat ~= "guide" then menuState.lastCat = menuState.cat end
            menuState.cat = "config"
        end
        KMS.UI.Refresh()
    end

    frame.OnRemove = function()
        if KMS.Treating and KMS.Treating.source == "menu" and CurTime() < KMS.Treating.endsAt then
            net.Start("KMS_CancelTreat")
            net.SendToServer()
        end
        if menuState.frame == frame then
            menuState.frame = nil
            KMS.SendWatch(patient, false)
            KMS.PlaySound("Close")
            tooltipState.text = nil
            tooltipState.panel = nil
        elseif menuState.patient ~= patient then
            KMS.SendWatch(patient, false)
        end
    end

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body:DockMargin(Scale(12), Scale(60), Scale(12), Scale(12))
    body.Paint = nil

    local bottom = vgui.Create("DPanel", body)
    bottom:Dock(BOTTOM)
    bottom:SetTall(Scale(230))
    bottom.Paint = nil

    local activity = EntryList(bottom, "menu_activity", "bottomLeft")
    activity:Dock(LEFT)
    activity:SetWide(Scale(570))
    activity:DockMargin(0, Scale(10), Scale(10), 0)

    local quick = EntryList(bottom, "menu_quickview", "bottomRight")
    quick:Dock(FILL)
    quick:DockMargin(0, Scale(10), 0, 0)

    local left = PanelBase(body, "left")
    left:Dock(LEFT)
    left:SetWide(Scale(340))
    SectionLabel(left, "menu_examine_treatment")

    if menuState.cat == "config" or menuState.cat == "guide" then menuState.cat = "examine" end

    local tabs = vgui.Create("DPanel", left)
    tabs:Dock(TOP)
    tabs:SetTall(Scale(46))
    tabs:DockMargin(Scale(10), Scale(6), Scale(10), Scale(2))
    local slots = {}
    tabs.Paint = function(_, w, h)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Border"), 180))
        for _, slot in ipairs(slots) do
            if slot.divider and slot.x then
                surface.DrawRect(slot.x, Scale(8), 1, h - Scale(16))
            end
        end
    end
    tabs.PerformLayout = function(s, w, h)
        local icons, dividers = 0, 0
        for _, slot in ipairs(slots) do
            if slot.divider then dividers = dividers + 1 else icons = icons + 1 end
        end
        if icons == 0 or w <= 0 then return end
        local minGap = Scale(3)
        local dividerW = Scale(7)
        local avail = w - dividers * dividerW - (icons - 1) * minGap
        local size = math.Clamp(math.floor(avail / icons), 1, Scale(36))
        local total = icons * size + (icons - 1) * minGap + dividers * dividerW
        local x = math.max(0, (w - total) / 2)
        local y = (h - size) / 2
        for _, slot in ipairs(slots) do
            if slot.divider then
                slot.x = math.floor(x + dividerW / 2)
                x = x + dividerW
            else
                slot.btn:SetPos(x, y)
                slot.btn:SetSize(size, size)
                x = x + size + minGap
            end
        end
    end

    local function AddTabIcon(mat, tooltip, isActive, onClick)
        local btn = HoverSound(vgui.Create("DButton", tabs))
        btn:SetText("")
        StyleTooltip(btn, tooltip)
        btn.Paint = function(s, w, h)
            local hoverLerp = KF.Anim.UpdateHoverLerp(s, 10)
            local active = isActive ~= nil and isActive()
            local color = active and C("Accent") or KF.UI.LerpColor(hoverLerp, C("TextSecondary"), C("TextPrimary"))
            local pad = math.Round(w * 0.12)
            if mat then
                KMS.DrawIcon(mat, pad, pad, w - pad * 2, h - pad * 2, color, 140)
            else
                draw.SimpleText(string.upper(string.sub(tooltip, 1, 1)), FB("header"), w / 2, h / 2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            if active then
                surface.SetDrawColor(C("Accent"))
                surface.DrawRect(math.Round(w * 0.14), h - Scale(2), w - math.Round(w * 0.28), Scale(2))
            end
        end
        btn.DoClick = function()
            KMS.PlaySound("Click")
            onClick()
        end
        slots[#slots + 1] = { btn = btn }
    end

    local function AddTabDivider()
        slots[#slots + 1] = { divider = true }
    end

    local function SelectCat(cat)
        if menuState.cat ~= "config" then menuState.lastCat = menuState.cat end
        menuState.cat = cat
        KMS.UI.Refresh()
    end

    AddTabIcon(TAB_ICONS.triage, L("cat_triage"), function() return menuState.cat == "triage" end, function() SelectCat("triage") end)
    AddTabDivider()
    for _, cat in ipairs(TAB_CATS) do
        AddTabIcon(TAB_ICONS[cat], L("cat_" .. cat), function() return menuState.cat == cat end, function() SelectCat(cat) end)
    end
    AddTabDivider()
    if not KMS.Settings.infiniteSupplies then
        AddTabIcon(TAB_ICONS.inventory, L("cat_inventory"), function() return menuState.cat == "inventory" end, function() SelectCat("inventory") end)
    end
    AddTabIcon(TAB_ICONS.toggle, L("menu_toggle"), nil, function()
        local ply = LocalPlayer()
        local target = menuState.patient == ply and KMS.FindPatient() or ply
        if target == menuState.patient then
            KMS.PlaySound("Error")
            return
        end
        frame:Remove()
        KMS.OpenMenuOn(target)
    end)

    local actions = vgui.Create("KF.ScrollPanel", left)
    actions:SetAddon(AID)
    actions:Dock(FILL)
    actions:DockMargin(Scale(8), Scale(4), Scale(8), Scale(8))

    local right = PanelBase(body)
    right:Dock(RIGHT)
    right:SetWide(Scale(400))
    SectionLabel(right, "menu_overview")

    local overviewScroll = vgui.Create("KF.ScrollPanel", right)
    overviewScroll:SetAddon(AID)
    overviewScroll:Dock(FILL)
    overviewScroll:DockMargin(Scale(14), Scale(8), Scale(14), Scale(8))
    local overview = { }
    overview.SetLines = function(lines)
        overviewScroll:Clear()
        for _, line in ipairs(lines) do
            local row = vgui.Create("DPanel", overviewScroll)
            row:Dock(TOP)
            row:SetTall(Scale(22))
            row.Paint = function(_, w, h)
                draw.SimpleText(line.text, line.bold and FB("body") or F("body"), 0, h / 2, line.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
    end

    local center = PanelBase(body, false)
    center:Dock(FILL)
    center:DockMargin(Scale(10), 0, Scale(10), 0)
    SectionLabel(center, "menu_status", false)

    local progress = vgui.Create("DPanel", center)
    progress:Dock(BOTTOM)
    progress:SetTall(Scale(62))
    progress:DockMargin(Scale(60), 0, Scale(60), Scale(10))
    progress.Paint = function(_, w, h)
        local treating = KMS.Treating
        if not treating or CurTime() >= treating.endsAt then return end
        local strat = KMS.StratagemState()
        local barH = Scale(30)
        local barY = strat and (h - barH) or (h - barH) / 2
        if strat then
            KMS.DrawStratagemRow(0, 0, w, barY - Scale(2))
        end
        surface.SetDrawColor(C("PanelDark"))
        surface.DrawRect(0, barY, w, barH)
        local frac = 1 - (treating.endsAt - CurTime()) / treating.duration
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), 120))
        surface.DrawRect(0, barY, w * math.Clamp(frac, 0, 1), barH)
        local label = string.find(treating.id, "haul_", 1, true) == 1 and L("int_" .. string.sub(treating.id, 6)) or L("treat_" .. treating.id)
        draw.SimpleText(label, FB("small"), w / 2, barY + barH / 2, C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C("Border"))
        surface.DrawOutlinedRect(0, barY, w, barH, 1)
    end

    local figure = KMS.BodyPanel(center)
    figure:Dock(FILL)
    figure:DockMargin(Scale(30), Scale(10), Scale(30), Scale(6))
    figure.GetPartState = function(_, partId)
        return SnapshotPart(partId)
    end
    figure.GetSelected = function()
        return menuState.part
    end
    figure.OnPartClick = function(_, partId)
        menuState.part = partId
        KMS.PlaySound("Click")
        KMS.UI.Refresh()
    end

    local settings = vgui.Create("DPanel", body)
    settings:Dock(FILL)
    settings:DockMargin(Scale(20), Scale(6), Scale(20), Scale(6))
    settings:SetVisible(false)
    settings.Paint = nil

    local settingsFoot = vgui.Create("DPanel", settings)
    settingsFoot:Dock(BOTTOM)
    settingsFoot:SetTall(Scale(46))
    settingsFoot:DockMargin(0, Scale(8), 0, 0)
    settingsFoot.Paint = function(_, w)
        surface.SetDrawColor(C("Border"))
        surface.DrawRect(0, 0, w, 1)
    end

    local settingsBack = Btn(settingsFoot, L("cfg_back"))
    settingsBack:Dock(LEFT)
    settingsBack:SetWide(Scale(170))
    settingsBack:DockMargin(0, Scale(8), 0, 0)
    settingsBack.DoClick = function()
        menuState.cat = menuState.lastCat or "examine"
        KMS.UI.Refresh()
    end

    local layoutBtn = Btn(settingsFoot, L("btn_layout"), "primary", true)
    layoutBtn:Dock(RIGHT)
    layoutBtn:SetWide(Scale(230))
    layoutBtn:DockMargin(0, Scale(8), 0, 0)
    layoutBtn.DoClick = function()
        frame:Remove()
        KMS.OpenLayoutEditor()
    end

    local settingsRows = vgui.Create("KF.ScrollPanel", settings)
    settingsRows:SetAddon(AID)
    settingsRows:Dock(FILL)
    settingsRows:DockMargin(0, Scale(4), 0, 0)
    settingsRows:GetCanvas():DockPadding(0, 0, Scale(8), Scale(12))

    local function ConfigSection(titleKey)
        DockAdd(KF.FormBuilder.SectionHeader(settingsRows, L(titleKey), nil, { addonId = AID }), Scale(12), Scale(10))
    end

    ConfigSection("cfg_grp_controls")
    ConfigKeyRow(settingsRows, "cfg_menu_key", "kms_menu_key", "keyMenu")
    ConfigKeyRow(settingsRows, "cfg_interact_key", "kms_interact_key", "keyInteract")
    if KMS.Settings.quickUseEnabled then
        ConfigKeyRow(settingsRows, "cfg_quickuse_key", "kms_quickuse_key", "keyQuickUse")
    end
    ConfigSection("cfg_grp_feedback")
    ConfigChoiceRow(settingsRows, "cfg_effects", "kms_effects_mode", { 0, 1, 2 }, Scale(110), function(mode)
        return L("opt_fx_" .. mode)
    end)
    if KMS.Settings.downedIndicator then
        ConfigSection("cfg_grp_downed")
        ConfigChoiceRow(settingsRows, "cfg_downed_range", "kms_downed_range", { 750, 1500, 2000, 3000 }, Scale(70), function(units)
            return math.Round(units / KMS.DisplayUnitsPerMeter) .. "m"
        end)
        ConfigCheckRow(settingsRows, "cfg_downed_outline", "kms_downed_outline")
    end

    local guidePanel = vgui.Create("DPanel", body)
    guidePanel:Dock(FILL)
    guidePanel:DockMargin(Scale(20), Scale(6), Scale(20), Scale(6))
    guidePanel:SetVisible(false)
    guidePanel.Paint = nil

    local guideFoot = vgui.Create("DPanel", guidePanel)
    guideFoot:Dock(BOTTOM)
    guideFoot:SetTall(Scale(40))
    guideFoot:DockMargin(0, Scale(6), 0, 0)
    guideFoot.Paint = nil

    local guideBack = Btn(guideFoot, L("cfg_back"))
    guideBack:Dock(LEFT)
    guideBack:SetWide(Scale(160))
    guideBack:DockMargin(0, Scale(3), 0, Scale(3))
    guideBack.DoClick = function()
        menuState.cat = menuState.lastCat or "examine"
        KMS.UI.Refresh()
    end

    local guideBody = vgui.Create("DPanel", guidePanel)
    guideBody:Dock(FILL)
    guideBody.Paint = nil

    local guideSidebar = vgui.Create("KF.ScrollPanel", guideBody)
    guideSidebar:SetAddon(AID)
    guideSidebar:Dock(LEFT)
    guideSidebar:SetWide(Scale(230))

    local guideContent = vgui.Create("DPanel", guideBody)
    guideContent:Dock(FILL)
    guideContent:DockMargin(Scale(14), 0, 0, 0)
    guideContent.Paint = function(_, w, h)
        KF.Draw.Panel(0, 0, w, h, { addonId = AID })
    end

    local guideScroll = vgui.Create("KF.ScrollPanel", guideContent)
    guideScroll:SetAddon(AID)
    guideScroll:Dock(FILL)
    guideScroll:DockMargin(Scale(18), Scale(12), Scale(10), Scale(12))

    guidePanel.KMSShow = function()
        KMS.BuildGuide(guideSidebar, guideScroll)
    end

    frame.KMSRefs = {
        actions = actions,
        overview = overview,
        activity = activity,
        quick = quick,
        settings = settings,
        guide = guidePanel,
        patient = { bottom, left, right, center },
    }

    KMS.UI.Refresh()
end

function KMS.OpenMenuOn(target)
    if not KMS.Settings.enabled then return end
    if MenuOpen() then
        menuState.frame:Remove()
        return
    end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or KMS.Self.conscious == false then return end
    if not KF.Integrations.PlayerInWorld(ply) then return end
    if not IsValid(target) then return end
    menuState.patient = target
    menuState.part = "torso"
    menuState.usePatient = false
    KMS.PlaySound("Open")
    BuildMenu(target)
    KMS.SendWatch(target, true)
end

-- Altes 2D-Menü (Third Person, "Volles Menü" im Comlink)
KMS.OpenClassicMenuOn = KMS.OpenMenuOn

function KMS.OpenClassicMenu()
    if KMS.InteractActive() or KMS.Exempt(LocalPlayer()) then return end
    KMS.OpenMenuOn(KMS.FindPatient())
end

-- Chat-Befehl / kms_menu: Medic-Hologramm über dem Comlink am linken Arm (Strivon Comlink). Ohne Comlink-Addon das alte Menü.
function KMS.OpenMenu()
    if KMS.InteractActive() or KMS.Exempt(LocalPlayer()) then return end
    if KMS.OpenComlinkMenu and KMS.OpenComlinkMenu() then return end
    KMS.OpenMenuOn(KMS.FindPatient())
end

hook.Add("KMS_PatientUpdated", "KMS_MenuPatientRefresh", function(patient)
    if MenuOpen() and patient == menuState.patient then
        KMS.UI.Refresh()
    end
end)

KF.Net.Receive("KMS_OpenMenu", function()
    if net.ReadBool() then
        KMS.OpenAdmin()
    else
        KMS.OpenMenu()
    end
end)

hook.Add("KMS_SelfUpdated", "KMS_MenuSelfRefresh", function()
    if MenuOpen() then KMS.UI.Refresh() end
end)

hook.Add("KMS_ConfigUpdated", "KMS_MenuLanguage", function()
    if not MenuOpen() or menuState.frame.KMSLang == KF.Lang.GetCurrent(AID) then return end
    local patient = menuState.patient
    menuState.frame:Remove()
    KMS.OpenMenuOn(patient)
end)

hook.Add("Think", "KMS_MenuValidate", function()
    if not MenuOpen() then return end
    local ply = LocalPlayer()
    local patient = menuState.patient
    if not IsValid(patient) or not ply:Alive() or KMS.Self.conscious == false then
        menuState.frame:Remove()
        return
    end
    if gui.IsGameUIVisible() and KMS.Treating and CurTime() < KMS.Treating.endsAt then
        gui.HideGameUI()
        net.Start("KMS_CancelTreat")
        net.SendToServer()
        return
    end
    if patient ~= ply and not KMS.SameVehicle(ply, patient)
        and KMS.PatientDisplayEnt(patient):GetPos():Distance(ply:GetPos()) > KMS.Settings.maxTreatDistance * KMS.WatchMargin then
        menuState.frame:Remove()
    end
end)

concommand.Add("kms_menu", function()
    KMS.OpenMenu()
end)

local invState = { storage = nil, storageAt = 0 }
local vehInv = { frame = nil, root = nil, inv = {}, synced = false }

KF.Net.Receive("KMS_StorageSync", function()
    invState.storage = KF.Net.ReadCompressed(16) or {}
    invState.storageAt = CurTime()
    hook.Run("KMS_InventoryUpdated")
end)

KF.Net.Receive("KMS_VehInvSync", function()
    local root = net.ReadEntity()
    local inv = KF.Net.ReadCompressed(16) or {}
    if not IsValid(vehInv.frame) or root ~= vehInv.root then return end
    vehInv.inv = inv
    vehInv.synced = true
    vehInv.frame.KMSRebuild()
end)

local function StorageOpen()
    return invState.storage ~= nil and CurTime() - invState.storageAt < 4
end

function KMS.RequestStorage()
    net.Start("KMS_StorageOpen")
    net.SendToServer()
end

local function SendMove(itemId, count, deposit)
    net.Start("KMS_StoreItem")
    net.WriteString(itemId)
    net.WriteUInt(count, 8)
    net.WriteBool(deposit)
    net.SendToServer()
end

local function DrawItemIcon(mat, label, x, y, size, color)
    if mat then
        KMS.DrawIcon(mat, x, y, size, size, color)
    else
        surface.SetDrawColor(KF.UI.ColorAlpha(C("PanelDark"), 200))
        surface.DrawRect(x, y, size, size)
        draw.SimpleText(string.sub(label, 1, 2), FB("small"), x + size / 2, y + size / 2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function ItemRow(scroll, itemId, count, reserved)
    local label = KMS.ItemLabel(itemId)
    local row = vgui.Create("DPanel", scroll)
    row:Dock(TOP)
    row:SetTall(Scale(38))
    row:DockMargin(0, 0, 0, Scale(3))
    local wiki = KMS.DescribeItem(itemId)
    if wiki[1] then StyleTooltip(row, wiki) end
    local iconSize = Scale(28)
    row.Paint = function(_, w, h)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("PanelDark"), 140))
        surface.DrawRect(0, 0, w, h)
        DrawItemIcon(KMS.ItemIcons[itemId], label, Scale(5), (h - iconSize) / 2, iconSize, C("TextPrimary"))
        local rightLimit = w - (reserved or 0) - Scale(6)
        local countText = "x" .. count
        surface.SetFont(FB("body"))
        local labelMaxW = rightLimit - surface.GetTextSize(countText) - Scale(10) - Scale(42)
        if labelMaxW < Scale(24) then
            if rightLimit > Scale(42) then
                draw.SimpleText(KMS.Ellipsize(label, F("body"), rightLimit - Scale(42)), F("body"), Scale(42), h / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        else
            draw.SimpleText(KMS.Ellipsize(label, F("body"), labelMaxW), F("body"), Scale(42), h / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(countText, FB("body"), rightLimit, h / 2, C("TextAccent"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    return row
end

local function ActionMini(row, label, style, onClick)
    local btn = Btn(row, label, style)
    btn:Dock(RIGHT)
    btn:DockMargin(Scale(4), Scale(5), 0, Scale(5))
    btn:SetWide(Scale(76))
    btn.DoClick = onClick
    return btn
end

local function MoveButtons(row, itemId, deposit)
    local defs = {
        { label = L("inv_all"), count = 255, wide = 56 },
        { label = "x5", count = 5, wide = 46 },
        { label = deposit and L("inv_deposit") or L("inv_withdraw"), count = 1, wide = 76, style = deposit and nil or "primary" },
    }
    for _, def in ipairs(defs) do
        local btn = ActionMini(row, def.label, def.style, function()
            SendMove(itemId, def.count, deposit)
        end)
        btn:SetWide(Scale(def.wide))
    end
end

local function GroupInventory(inv)
    local byCat = {}
    for _, item in ipairs(KMS.Items) do
        local count = inv[item.id] or 0
        if count > 0 then
            local cat = KMS.ItemCategory(item.id)
            byCat[cat] = byCat[cat] or {}
            byCat[cat][#byCat[cat] + 1] = { id = item.id, count = count }
        end
    end
    return byCat
end

local function InvHeader(scroll, text)
    local header = vgui.Create("DPanel", scroll)
    header:Dock(TOP)
    header:SetTall(Scale(26))
    header:DockMargin(0, Scale(10), 0, Scale(2))
    header.Paint = function(_, w, h)
        draw.SimpleText(text, FB("body"), 0, h / 2, C("TextAccent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C("BorderAccent"))
        surface.DrawRect(0, h - 1, w, 1)
    end
end

local function CatHeader(scroll, cat)
    local header = vgui.Create("DPanel", scroll)
    header:Dock(TOP)
    header:SetTall(Scale(24))
    header:DockMargin(0, Scale(6), 0, Scale(2))
    header.Paint = function(_, w, h)
        draw.SimpleText(L("cat_" .. cat), FB("small"), 0, h / 2, C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Border"), 150))
        surface.DrawRect(0, h - 1, w, 1)
    end
end

local function NearStorageNPC()
    local pos = LocalPlayer():GetPos()
    for _, ent in ipairs(ents.FindByClass("kms_npc")) do
        local npc = KMS.NPCs[ent:GetNWString("kms_npc_id", "")]
        if npc and npc.npcType == "supply" and ent:GetPos():DistToSqr(pos) <= KMS.FacilityRangeSqr then
            return true
        end
    end
    return false
end

function KMS.BuildInventory(scroll)
    local inv = KMS.Self.inv or {}
    local ply = LocalPlayer()
    local target = KMS.UI.MenuPatient()
    local canGive = IsValid(target) and target ~= ply
    local storageOpen = StorageOpen()
    if not storageOpen and NearStorageNPC() then KMS.RequestStorage() end
    local reserved = (storageOpen and Scale(190) or 0) + (canGive and Scale(80) or 0)

    local byCat = GroupInventory(inv)

    local empty = true
    for _, cat in ipairs(KMS.InvCategories) do
        local items = byCat[cat]
        if items then
            empty = false
            CatHeader(scroll, cat)
            for _, entry in ipairs(items) do
                local row = ItemRow(scroll, entry.id, entry.count, reserved)
                if storageOpen then
                    MoveButtons(row, entry.id, true)
                end
                if canGive then
                    ActionMini(row, L("inv_give"), "primary", function()
                        net.Start("KMS_GiveItem")
                        net.WriteEntity(target)
                        net.WriteString(entry.id)
                        net.WriteUInt(1, 8)
                        net.SendToServer()
                    end)
                end
            end
        end
    end

    if storageOpen and next(invState.storage) ~= nil then
        InvHeader(scroll, L("inv_storage"))
        for _, item in ipairs(KMS.Items) do
            local count = invState.storage[item.id] or 0
            if count > 0 then
                local row = ItemRow(scroll, item.id, count, Scale(190))
                MoveButtons(row, item.id, false)
            end
        end
    end

    local snapshot = Snapshot()
    if KMS.Settings.invLootDowned and not KMS.Settings.infiniteSupplies and canGive and KMS.IsDowned(target)
        and snapshot and snapshot.inv and next(snapshot.inv) ~= nil then
        InvHeader(scroll, L("inv_patient"))
        for _, item in ipairs(KMS.Items) do
            local count = snapshot.inv[item.id] or 0
            if count > 0 then
                local row = ItemRow(scroll, item.id, count, Scale(80))
                ActionMini(row, L("inv_withdraw"), "primary", function()
                    net.Start("KMS_LootItem")
                    net.WriteEntity(target)
                    net.WriteString(item.id)
                    net.WriteUInt(1, 8)
                    net.SendToServer()
                end)
            end
        end
    end

    if empty and not storageOpen then
        local msg = vgui.Create("DPanel", scroll)
        msg:Dock(TOP)
        msg:SetTall(Scale(40))
        msg.Paint = function(_, w, h)
            draw.SimpleText(L("inv_empty"), F("body"), w / 2, h / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

hook.Add("KMS_InventoryUpdated", "KMS_InvRefresh", function()
    if KMS.UI and KMS.UI.Refresh then KMS.UI.Refresh() end
end)

local function VehInvValid()
    local root = vehInv.root
    if not IsValid(root) or not KMS.IsMedVehicle(root) then return false end
    local ply = LocalPlayer()
    if not ply:Alive() or KMS.Self.conscious == false then return false end
    if not KMS.Settings.itemSharing or KMS.Settings.infiniteSupplies then return false end
    if KMS.VehicleBase(ply:GetVehicle()) == root then return true end
    local pos = ply:GetPos()
    if root:NearestPoint(pos):Distance(pos) > KMS.Settings.maxTreatDistance * KMS.ReachMargin then return false end
    return KMS.ClearSight(ply, root)
end

local function VehTransferCount()
    if input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL) then return 255 end
    if input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) then return 5 end
    return 1
end

local function SendVehMove(itemId, count, deposit)
    if not IsValid(vehInv.root) then return end
    net.Start("KMS_VehInvMove")
    net.WriteEntity(vehInv.root)
    net.WriteString(itemId)
    net.WriteUInt(count, 8)
    net.WriteBool(deposit)
    net.SendToServer()
end

local function VehItemRow(scroll, itemId, count, deposit)
    local label = KMS.ItemLabel(itemId)
    local row = HoverSound(vgui.Create("DButton", scroll))
    row:SetText("")
    row:Dock(TOP)
    row:SetTall(Scale(40))
    row:DockMargin(0, 0, 0, Scale(3))
    local iconSize = Scale(28)
    row.Paint = function(s, w, h)
        local hover = KF.Anim.UpdateHoverLerp(s, 10)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("PanelDark"), 150 + 60 * hover))
        surface.DrawRect(0, 0, w, h)
        if hover > 0.01 then
            surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), math.floor(220 * hover)))
            surface.DrawRect(deposit and (w - Scale(3)) or 0, 0, Scale(3), h)
        end
        DrawItemIcon(KMS.ItemIcons[itemId], label, Scale(6), (h - iconSize) / 2, iconSize, C("TextPrimary"))
        draw.SimpleText(label, F("body"), Scale(42), h / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local countText = "x" .. count
        surface.SetFont(FB("body"))
        local cw = surface.GetTextSize(countText)
        draw.SimpleText(countText, FB("body"), w - Scale(10), h / 2, C("TextAccent"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        if hover > 0.01 then
            local n = VehTransferCount()
            local hint = (deposit and "» " or "« ") .. (n >= 255 and L("inv_all") or ("x" .. math.min(n, count)))
            draw.SimpleText(hint, FB("small"), w - Scale(18) - cw, h / 2, KF.UI.ColorAlpha(C("TextAccent"), math.floor(255 * hover)), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    row.DoClick = function()
        KMS.PlaySound("Click")
        SendVehMove(itemId, VehTransferCount(), deposit)
    end
    return row
end

local function FillVehPane(scroll, inv, deposit, emptyKey, showEmpty)
    scroll:Clear()
    local byCat = GroupInventory(inv)
    local any = next(byCat) ~= nil
    for _, cat in ipairs(KMS.InvCategories) do
        local items = byCat[cat]
        if items then
            CatHeader(scroll, cat)
            for _, entry in ipairs(items) do
                VehItemRow(scroll, entry.id, entry.count, deposit)
            end
        end
    end
    if not any and showEmpty then
        local msg = vgui.Create("DPanel", scroll)
        msg:Dock(TOP)
        msg:SetTall(Scale(40))
        msg.Paint = function(_, w, h)
            draw.SimpleText(L(emptyKey), F("body"), w / 2, h / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

local function VehPane(parent, titleKey, notchSide)
    local pane = PanelBase(parent, notchSide)
    SectionLabel(pane, titleKey)
    local scroll = vgui.Create("KF.ScrollPanel", pane)
    scroll:SetAddon(AID)
    scroll:Dock(FILL)
    scroll:DockMargin(Scale(12), Scale(6), Scale(12), Scale(30))
    return pane, scroll
end

function KMS.OpenVehicleInventory(root)
    if not IsValid(root) then return end
    if IsValid(vehInv.frame) then vehInv.frame:Remove() end
    if MenuOpen() then menuState.frame:Remove() end
    vehInv.root = root
    vehInv.inv = {}
    vehInv.synced = false

    local frame = vgui.Create("KF.Frame")
    frame:SetAddon(AID)
    frame:SetSize(Scale(940), Scale(620))
    frame:Center()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(false)
    frame:SetFrameTitle(string.upper(KMS.VehicleDisplayName(root)))
    frame:SetSubtitle(L("int_veh_inventory"))
    frame:SetHeaderHeight(52)
    frame:SetHeaderLine(false)
    frame:SetTitleFont("header")
    frame:SetSubtitleFont("body")
    vehInv.frame = frame

    CloseButton(frame)

    frame.OnRemove = function()
        if vehInv.frame ~= frame then return end
        KMS.PlaySound("Close")
        timer.Remove("KMS_VehInvPoll")
        vehInv.frame = nil
        vehInv.root = nil
        vehInv.synced = false
    end

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body:DockMargin(Scale(12), Scale(60), Scale(12), Scale(10))
    body.Paint = nil

    local footer = vgui.Create("DPanel", body)
    footer:Dock(BOTTOM)
    footer:SetTall(Scale(24))
    footer.Paint = function(_, w, h)
        draw.SimpleText(L("vehinv_hint"), F("small"), w / 2, h / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local left, leftScroll = VehPane(body, "vehinv_yours", "bottomLeft")
    left:Dock(LEFT)
    left:SetWide(Scale(446))
    left:DockMargin(0, 0, 0, Scale(6))

    local right, rightScroll = VehPane(body, "inv_vehicle", "bottomRight")
    right:Dock(FILL)
    right:DockMargin(Scale(12), 0, 0, Scale(6))

    frame.KMSRebuild = function()
        if not IsValid(frame) then return end
        FillVehPane(leftScroll, KMS.Self.inv or {}, true, "inv_empty", true)
        FillVehPane(rightScroll, vehInv.inv, false, "inv_vehicle_empty", vehInv.synced)
    end

    net.Start("KMS_VehInvOpen")
    net.WriteEntity(root)
    net.SendToServer()
    timer.Create("KMS_VehInvPoll", 2, 0, function()
        if not IsValid(vehInv.frame) or not IsValid(vehInv.root) then
            timer.Remove("KMS_VehInvPoll")
            return
        end
        net.Start("KMS_VehInvOpen")
        net.WriteEntity(vehInv.root)
        net.SendToServer()
    end)
    KMS.PlaySound("Open")
    frame.KMSRebuild()
end

hook.Add("Think", "KMS_VehInvValidate", function()
    if not IsValid(vehInv.frame) then return end
    if not VehInvValid() then vehInv.frame:Remove() end
end)

hook.Add("KMS_SelfUpdated", "KMS_VehInvSelf", function()
    if IsValid(vehInv.frame) then vehInv.frame.KMSRebuild() end
end)

local pendingActions = {}
local pendingOrder = {}
local lastActionAt = 0

local function FlushActions()
    local key = table.remove(pendingOrder, 1)
    if not key then return end
    local entry = pendingActions[key]
    pendingActions[key] = nil
    lastActionAt = CurTime()
    net.Start("KMS_AdminAction")
    net.WriteString(entry.action)
    KF.Net.WriteCompressed(entry.payload or {}, 32)
    net.SendToServer()
    if #pendingOrder > 0 then
        timer.Create("KMS_AdminFlush", 0.2, 1, FlushActions)
    end
end

local function SendAction(action, payload)
    local key = action .. "|" .. tostring(payload and (payload.key or payload.id or (payload.npc and payload.npc.id)) or "")
    if not pendingActions[key] then
        pendingOrder[#pendingOrder + 1] = key
    end
    pendingActions[key] = { action = action, payload = payload }
    if CurTime() - lastActionAt >= 0.2 then
        FlushActions()
    elseif not timer.Exists("KMS_AdminFlush") then
        timer.Create("KMS_AdminFlush", 0.2 - (CurTime() - lastActionAt), 1, FlushActions)
    end
end

local refreshers = {}
local refreshing = false

local function RegisterRefresher(fn)
    refreshers[#refreshers + 1] = fn
end

local function DependsOn(input, predicate)
    local row = input:GetParent()
    local function apply()
        if not IsValid(input) then return end
        local on = predicate() and true or false
        input:SetEnabled(on)
        if IsValid(row) then row:SetAlpha(on and 255 or 110) end
    end
    RegisterRefresher(apply)
    apply()
    return input
end

local function BoolOn(key)
    return function() return KMS.Settings[key] == true end
end

local function ShowIf(predicate, ...)
    local panels = { ... }
    local function apply()
        local on = predicate() and true or false
        for _, panel in ipairs(panels) do
            if IsValid(panel) then panel:SetVisible(on) end
        end
    end
    RegisterRefresher(apply)
    apply()
end

local lootState = {}

KF.Net.Receive("KMS_LootOpen", function()
    local ent = net.ReadEntity()
    local inv = KF.Net.ReadCompressed(16) or {}
    if not IsValid(ent) or next(inv) == nil then
        if IsValid(lootState.frame) then lootState.frame:Remove() end
        return
    end
    if not IsValid(lootState.frame) then
        local frame = vgui.Create("KF.Frame")
        frame:SetAddon(AID)
        frame:SetSize(Scale(460), Scale(520))
        frame:Center()
        frame:MakePopup()
        frame:SetKeyboardInputEnabled(false)
        frame:SetFrameTitle(string.upper(L("loot_dropped")))
        frame:SetSubtitle(L("ui_subtitle"))
        frame:SetHeaderHeight(52)
        lootState.frame = frame
        CloseButton(frame)
        frame.OnRemove = function()
            if lootState.frame ~= frame then return end
            lootState.frame = nil
            KMS.PlaySound("Close")
        end
        local hint = vgui.Create("DPanel", frame)
        hint:Dock(BOTTOM)
        hint:SetTall(Scale(24))
        hint:DockMargin(Scale(14), 0, Scale(14), Scale(8))
        hint.Paint = function(_, w, h)
            draw.SimpleText(L("vehinv_hint"), F("small"), w / 2, h / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        local scroll = vgui.Create("KF.ScrollPanel", frame)
        scroll:SetAddon(AID)
        scroll:Dock(FILL)
        scroll:DockMargin(Scale(14), Scale(60), Scale(14), Scale(6))
        frame.KMSScroll = scroll
        frame.Think = function()
            if not IsValid(lootState.ent) or LocalPlayer():GetPos():DistToSqr(lootState.ent:GetPos()) > KMS.InteractRangeSqr * 4 then
                frame:Remove()
            end
        end
        KMS.PlaySound("Open")
    end
    lootState.ent = ent
    local scroll = lootState.frame.KMSScroll
    scroll:Clear()
    for _, item in ipairs(KMS.Items) do
        local count = inv[item.id] or 0
        if count > 0 then
            local row = ItemRow(scroll, item.id, count, Scale(96))
            ActionMini(row, L("inv_withdraw"), "primary", function()
                net.Start("KMS_LootItem")
                net.WriteEntity(ent)
                net.WriteString(item.id)
                net.WriteUInt(VehTransferCount(), 8)
                net.SendToServer()
            end)
        end
    end
end)

KF.Net.Receive("KMS_AdminResponse", function()
    local payload = KF.Net.ReadCompressed(16)
    if not istable(payload) then return end
    local args = {}
    for i, arg in ipairs(KF.Utils.EnsureTable(payload.args)) do
        args[i] = KMS.TArg(arg)
    end
    KF.Notifications.Show(L(payload.key, unpack(args)), payload.success and "success" or "error", 4, AID)
    if not payload.success then KMS.PlaySound("Error") end
end)

function KMS.UI.Confirm(text, onYes)
    local blocker = vgui.Create("DPanel")
    blocker:SetSize(ScrW(), ScrH())
    blocker:MakePopup()
    blocker:SetKeyboardInputEnabled(true)
    blocker.Paint = function(_, w, h)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Background"), 200))
        surface.DrawRect(0, 0, w, h)
    end
    blocker.OnKeyCodePressed = function(s, key)
        if key == KEY_ESCAPE then s:Remove() end
    end
    local boxW = Scale(480)
    local lines = KF.WrapText(text, F("body"), boxW - Scale(48))
    local boxH = Scale(120) + #lines * Scale(22)
    local box = vgui.Create("DPanel", blocker)
    box:SetSize(boxW, boxH)
    box:Center()
    box.Paint = function(_, w, h)
        KF.Menu.MenuNotchedBox(0, 0, w, h, C("Panel"))
        KF.Menu.MenuNotchedOutline(0, 0, w, h, C("BorderAccent"))
        draw.SimpleText(L("confirm_title"), FB("subheader"), w / 2, Scale(26), C("TextAccent"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        for i, line in ipairs(lines) do
            draw.SimpleText(line, F("body"), w / 2, Scale(50) + i * Scale(22), C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    local function MakeButton(label, xFrac, style, callback)
        local btn = Btn(box, label, style, style == "primary")
        btn:SetSize(Scale(160), Scale(34))
        btn:SetPos(boxW * xFrac - Scale(80), boxH - Scale(48))
        btn.DoClick = function()
            blocker:Remove()
            if callback then callback() end
        end
    end
    MakeButton(L("btn_yes"), 0.3, "primary", onYes)
    MakeButton(L("btn_no"), 0.7, "default", nil)
end

local function WireApply(input, apply)
    input.OnEnter = apply
    input.OnLoseFocus = function(s)
        apply(s)
        vgui.GetControlTable("DTextEntry").OnLoseFocus(s)
    end
end

local adminFrame

local function ButtonRow(canvas)
    local row = vgui.Create("DPanel", canvas)
    row.Paint = nil
    row:SetTall(Scale(36))
    row:Dock(TOP)
    row:DockMargin(0, Scale(6), 0, Scale(8))
    return row
end

local function RowButton(row, label, style, solid, wide)
    local btn = Btn(row, label, style, solid)
    btn:Dock(LEFT)
    btn:DockMargin(0, 0, Scale(8), 0)
    btn:SetWide(wide or Scale(190))
    return btn
end

local function Scroll(parent)
    local scroll = vgui.Create("KF.ScrollPanel", parent)
    scroll:SetAddon(AID)
    scroll:Dock(FILL)
    scroll:DockMargin(Scale(24), Scale(12), Scale(24), Scale(12))
    scroll:GetCanvas():DockPadding(0, 0, Scale(8), Scale(20))
    return scroll
end

local function SyncWorking(working, key, deep)
    table.Empty(working)
    for k, v in pairs(KMS.Settings[key] or {}) do
        working[k] = (deep and istable(v)) and table.Copy(v) or v
    end
end

local guideState = { chapter = nil }

local GUIDE = {
    { group = "hb_grp", chapters = {
        { id = "hb_important", title = "hb_ch_important", entries = {
            { text = "hb_important_1" },
        } },
        { id = "hb_medlist", title = "hb_ch_medlist", handbook = true, entries = {} },
    } },
    { group = "guide_grp_wounded", chapters = {
        { id = "basics", title = "guide_ch_basics", entries = {
            { text = "guide_basics_1" },
            { text = "guide_basics_2" },
        } },
        { id = "bleeding", title = "guide_ch_bleeding", entries = {
            { text = "guide_bleeding_1" },
            { item = "bandage_field", text = "guide_it_bandage_field" },
            { item = "bandage_elastic", text = "guide_it_bandage_elastic" },
            { item = "bandage_packing", text = "guide_it_bandage_packing" },
            { item = "bandage_quickclot", text = "guide_it_bandage_quickclot" },
            { item = "tourniquet", text = "guide_it_tourniquet" },
            { item = "surgical_kit", text = "guide_it_surgical" },
        } },
        { id = "downed", title = "guide_ch_downed", entries = {
            { text = "guide_downed_1" },
            { text = "guide_downed_call", when = function() return KMS.Settings.medicCallEnabled end },
            { text = "guide_downed_2" },
            { text = "guide_downed_3" },
        } },
        { id = "fractures", title = "guide_ch_fractures", when = function() return KMS.Settings.fractureMode ~= "disabled" end, entries = {
            { text = "guide_fractures_1" },
            { text = "guide_fractures_2", when = function() return KMS.Settings.disarmEnabled end },
            { item = "splint", text = "guide_it_splint" },
        } },
    } },
    { group = "guide_grp_medic", chapters = {
        { id = "wiki", title = "guide_ch_items", wiki = true, entries = {} },
        { id = "meds", title = "guide_ch_meds", entries = {
            { text = "guide_meds_1" },
            { item = "painkillers", text = "guide_it_painkillers" },
            { item = "morphine", text = "guide_it_morphine" },
            { item = "epinephrine", text = "guide_it_epinephrine" },
            { item = "adenosine", text = "guide_it_adenosine" },
            { text = "guide_ivs_1" },
        } },
        { id = "medics", title = "guide_ch_medics", entries = {
            { text = "guide_medics_1" },
            { item = "pak", text = "guide_it_pak" },
            { text = "guide_medics_2" },
            { text = "guide_medics_3" },
            { text = "guide_medics_4" },
            { text = "guide_medics_5" },
        } },
    } },
}

local function GuideVisible(entry)
    if entry.when and not entry.when() then return false end
    return true
end

local GUIDE_W = 790

local function GuideHeading(canvas, chapter)
    local panel = vgui.Create("DPanel", canvas)
    panel:SetTall(Scale(46))
    DockAdd(panel, 0, Scale(12))
    panel.Paint = function(_, w, h)
        draw.SimpleText(string.upper(L(chapter.title)), FB("subheader"), 0, Scale(6), C("TextAccent"))
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), 120))
        surface.DrawRect(0, h - Scale(6), Scale(180), Scale(2))
    end
end

local function GuideText(canvas, key)
    local lines = KF.WrapText(L(key), F("body"), Scale(GUIDE_W))
    local panel = vgui.Create("DPanel", canvas)
    panel:SetTall(#lines * Scale(21))
    DockAdd(panel, Scale(2), Scale(14))
    panel.Paint = function()
        for i, line in ipairs(lines) do
            draw.SimpleText(line, F("body"), 0, (i - 1) * Scale(21), C("TextSecondary"))
        end
    end
end

-- text: one paragraph, or a list of paragraphs that each start on a new line
local function GuideItem(canvas, itemId, text, label)
    label = label or KMS.ItemLabel(itemId)
    local iconSize = Scale(34)
    local textX = iconSize + Scale(16)
    local lines = {}
    for _, paragraph in ipairs(istable(text) and text or { text }) do
        for _, line in ipairs(KF.WrapText(paragraph, F("small"), Scale(GUIDE_W) - textX)) do
            lines[#lines + 1] = line
        end
    end
    local panel = vgui.Create("DPanel", canvas)
    panel:SetTall(math.max(iconSize + Scale(14), Scale(28) + #lines * Scale(18) + Scale(8)))
    DockAdd(panel, 0, Scale(8))
    panel.Paint = function(_, w, h)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("PanelDark"), 120))
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), 90))
        surface.DrawRect(0, 0, Scale(2), h)
        DrawItemIcon(KMS.ItemIcons[itemId], label, Scale(10), (h - iconSize) / 2, iconSize, C("TextPrimary"))
        draw.SimpleText(label, FB("small"), textX, Scale(6), C("TextPrimary"))
        for i, line in ipairs(lines) do
            draw.SimpleText(line, F("small"), textX, Scale(28) + (i - 1) * Scale(18), C("TextSecondary"))
        end
    end
end

function KMS.BuildGuide(sidebar, scroll)
    sidebar:Clear()
    scroll:Clear()
    local byKey, firstKey = {}, nil
    local groups = {}
    for _, group in ipairs(GUIDE) do
        local items = {}
        for _, chapter in ipairs(group.chapters) do
            if GuideVisible(chapter) then
                byKey[chapter.id] = chapter
                firstKey = firstKey or chapter.id
                items[#items + 1] = { key = chapter.id, label = L(chapter.title) }
            end
        end
        if items[1] then
            groups[#groups + 1] = { label = L(group.group), items = items }
        end
    end

    local function ShowChapter(key)
        guideState.chapter = key
        scroll:Clear()
        local chapter = byKey[key]
        if not chapter then return end
        GuideHeading(scroll, chapter)
        if chapter.handbook then
            GuideText(scroll, "hb_medlist_intro")
            for _, entry in ipairs(KMS.Handbook or {}) do
                if not KMS.ItemDisabled[entry.item] then
                    local paragraphs = {}
                    for _, line in ipairs(KMS.DescribeItem(entry.item)) do
                        paragraphs[#paragraphs + 1] = line.text
                    end
                    GuideItem(scroll, entry.item, paragraphs, L("hb_name_" .. entry.key))
                end
            end
            return
        end
        if chapter.wiki then
            for _, item in ipairs(KMS.Items) do
                if not KMS.ItemDisabled[item.id] then
                    local text = WikiText(item.id)
                    if text ~= "" then GuideItem(scroll, item.id, text) end
                end
            end
            return
        end
        for _, entry in ipairs(chapter.entries) do
            if GuideVisible(entry) then
                if entry.item then
                    GuideItem(scroll, entry.item, L(entry.text))
                else
                    GuideText(scroll, entry.text)
                end
            end
        end
    end

    local active = (guideState.chapter and byKey[guideState.chapter]) and guideState.chapter or firstKey
    KF.Builders.SidebarNav()
        :SetAddon(AID)
        :SetGroups(groups)
        :SetActiveKey(active)
        :SetSoundHover(KMS.Sounds.Hover)
        :SetSoundClick(KMS.Sounds.Click)
        :SetOnSelect(ShowChapter)
        :Build(sidebar)

    ShowChapter(active)
end

function KMS.OpenGuide()
    -- Handbuch lebt im alten 2D-Menü (auch aus dem Comlink-Medic-Menü heraus)
    if not MenuOpen() then KMS.OpenClassicMenu() end
    if not MenuOpen() or menuState.cat == "guide" then return end
    if menuState.cat ~= "config" then menuState.lastCat = menuState.cat end
    menuState.cat = "guide"
    KMS.UI.Refresh()
    local refs = menuState.frame.KMSRefs
    if refs and refs.guide then refs.guide.KMSShow() end
end

concommand.Add("kms_guide", function()
    KMS.OpenGuide()
end)

local CONTENT_W = 900

local function ContentW()
    return Scale(CONTENT_W)
end

local function Header(canvas, titleKey, descKey)
    return DockAdd(KF.FormBuilder.SectionHeader(canvas, L(titleKey), descKey and L(descKey) or nil, { addonId = AID, width = ContentW() }), Scale(10), Scale(8))
end

local function Check(canvas, key)
    local _, cb = KF.FormBuilder.Checkbox(canvas, L("set_" .. key), KMS.Settings[key] == true, { addonId = AID, width = ContentW() })
    DockAdd(cb:GetParent())
    cb:SetSound(KMS.Sounds.Click)
    cb:SetHoverSound(KMS.Sounds.Hover)
    cb.OnChange = function(_, checked)
        if refreshing then return end
        SendAction("update_setting", { key = key, value = checked == true })
    end
    RegisterRefresher(function()
        if IsValid(cb) and cb:GetChecked() ~= (KMS.Settings[key] == true) then
            cb:SetChecked(KMS.Settings[key] == true)
        end
    end)
    return cb
end

local function BoundsSuffix(minValue, maxValue)
    return "  (" .. minValue .. " - " .. maxValue .. ")"
end

local function NumberField(canvas, key)
    local bounds = KMS.SettingBounds[key]
    local label = L("set_" .. key) .. (bounds and BoundsSuffix(bounds[1], bounds[2]) or "")
    local _, input = KF.FormBuilder.TextField(canvas, label, { addonId = AID, width = ContentW(), numeric = true, value = tostring(KMS.Settings[key] or 0) })
    DockAdd(input:GetParent())
    input:SetWide(Scale(140))
    local function apply(s)
        local entered = tonumber(s:GetValue())
        local value = math.Clamp(math.floor(entered or (KMS.Settings[key] or 0)), bounds and bounds[1] or 0, bounds and bounds[2] or KMS.MaxCost)
        s:SetText(tostring(value))
        if bounds and entered ~= nil and math.floor(entered) ~= value then
            KF.Notifications.Show(L("adm_clamped", bounds[1], bounds[2]), "info", 4, AID)
        end
        if value ~= KMS.Settings[key] then
            SendAction("update_setting", { key = key, value = value })
        end
    end
    WireApply(input, apply)
    RegisterRefresher(function()
        if IsValid(input) and not input:HasFocus() then
            input:SetText(tostring(KMS.Settings[key] or 0))
        end
    end)
    return input
end

local function TextSetting(canvas, key, placeholder)
    local _, input = KF.FormBuilder.TextField(canvas, L("set_" .. key), { addonId = AID, width = ContentW(), value = tostring(KMS.Settings[key] or ""), placeholder = placeholder })
    DockAdd(input:GetParent())
    input:SetWide(Scale(220))
    local function apply(s)
        local value = string.Trim(s:GetValue() or "")
        if value == "" then
            s:SetText(tostring(KMS.Settings[key] or ""))
            return
        end
        if value ~= KMS.Settings[key] then
            SendAction("update_setting", { key = key, value = value })
        end
    end
    WireApply(input, apply)
    RegisterRefresher(function()
        if IsValid(input) and not input:HasFocus() then
            input:SetText(tostring(KMS.Settings[key] or ""))
        end
    end)
    return input
end

local function Dropdown(canvas, label, options, selected, onSelect, width)
    local _, dropdown = KF.FormBuilder.Dropdown(canvas, label, { addonId = AID, width = width or ContentW(), choices = {}, dropdownClass = "KF.PopupDropdown" })
    DockAdd(dropdown:GetParent())
    dropdown:SetWide(Scale(DROPDOWN_W))
    StyleDropdown(dropdown, options, selected)
    dropdown.OnSelect = function(_, _, _, value)
        if refreshing then return end
        onSelect(value)
    end
    return dropdown
end

local function EnumDropdown(canvas, key, values, labelPrefix)
    local options = {}
    for _, value in ipairs(values) do
        options[#options + 1] = { value = value, label = L(labelPrefix .. value) }
    end
    local dropdown = Dropdown(canvas, L("set_" .. key), options, KMS.Settings[key], function(value)
        SendAction("update_setting", { key = key, value = value })
    end)
    RegisterRefresher(function()
        if IsValid(dropdown) then dropdown:SetValue(KMS.Settings[key]) end
    end)
    return dropdown
end

local function SettingKeyRow(canvas, key)
    local row = ConfigRow(canvas, "set_" .. key)
    local binder = KeyBinder(row, KMS.Settings[key] or 0, function(keyCode)
        SendAction("update_setting", { key = key, value = keyCode })
    end)
    RegisterRefresher(function()
        if IsValid(binder) then binder:SetValue(KMS.Settings[key] or 0) end
    end)
end

local function InfoText(canvas, textKey, wrapW, ...)
    local panel = vgui.Create("DPanel", canvas)
    local lines = KF.WrapText(L(textKey, ...), F("small"), wrapW or ContentW())
    panel:SetTall(#lines * Scale(18))
    DockAdd(panel, Scale(2), Scale(10))
    panel.Paint = function(_, w, h)
        for i, line in ipairs(lines) do
            draw.SimpleText(line, F("small"), 0, (i - 1) * Scale(18), C("TextSecondary"))
        end
    end
    return panel
end

local BuildMapsSection

local function BuildPresetsTab(canvas)
    Header(canvas, "adm_presets_title", "adm_presets_desc")
    if KMS.FirstRunClient then
        InfoText(canvas, "firstrun_text")
        local dismiss = RowButton(ButtonRow(canvas), L("btn_dismiss_firstrun"), "default", false, Scale(300))
        dismiss.DoClick = function()
            SendAction("dismiss_firstrun", {})
        end
    end
    local active = vgui.Create("DPanel", canvas)
    active:SetTall(Scale(34))
    DockAdd(active, 0, Scale(12))
    active.Paint = function(_, w, h)
        local preset = KMS.PresetById[KMS.ActivePresetClient]
        local label, color
        if preset then
            label, color = L("preset_" .. preset.id), C("Success")
        elseif KMS.ActivePresetClient == "custom" then
            label, color = L("adm_preset_custom"), C("Warning")
        else
            label, color = L("adm_preset_none"), C("TextSecondary")
        end
        draw.SimpleText(L("adm_preset_active", label), FB("body"), 0, h / 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local lastGroup
    for _, preset in ipairs(KMS.Presets) do
        if preset.group ~= lastGroup then
            lastGroup = preset.group
            Header(canvas, "adm_h_presets_" .. preset.group)
        end
        local nameKey = "preset_" .. preset.id
        local descLines = KF.WrapText(L(nameKey .. "_desc"), F("body"), ContentW() - Scale(240))
        local card = vgui.Create("DPanel", canvas)
        card:SetTall(math.max(Scale(96), #descLines * Scale(20) + Scale(56)))
        DockAdd(card, 0, Scale(12))
        card.Paint = function(_, w, h)
            local isActive = KMS.ActivePresetClient == preset.id
            KF.Menu.MenuNotchedBox(0, 0, w, h, C("PanelDark"))
            KF.Menu.MenuNotchedOutline(0, 0, w, h, isActive and C("Accent") or C("Border"))
            draw.SimpleText(L(nameKey), FB("header"), Scale(20), Scale(16), isActive and C("TextAccent") or C("TextPrimary"))
            for i, line in ipairs(descLines) do
                draw.SimpleText(line, F("body"), Scale(20), Scale(44) + (i - 1) * Scale(20), C("TextSecondary"))
            end
        end
        local apply = Btn(card, L("btn_apply_preset"), "primary", true)
        apply.PerformLayout = function(s)
            s:SetSize(Scale(180), Scale(36))
            s:SetPos(card:GetWide() - Scale(200), (card:GetTall() - Scale(36)) / 2)
        end
        apply.DoClick = function()
            KMS.UI.Confirm(L("confirm_preset", L(nameKey)), function()
                SendAction("apply_preset", { id = preset.id })
            end)
        end
    end
    Check(canvas, "blasterMode")
    local tools = vgui.Create("DPanel", canvas)
    tools:SetTall(Scale(38))
    tools.Paint = nil
    DockAdd(tools, Scale(10), Scale(8))
    local resetBtn = Btn(tools, L("btn_reset_defaults"), "danger")
    resetBtn:Dock(LEFT)
    resetBtn:SetWide(Scale(280))
    resetBtn.DoClick = function()
        KMS.UI.Confirm(L("confirm_reset_defaults"), function()
            SendAction("reset_defaults", {})
        end)
    end
    BuildMapsSection(canvas)
end

local function BuildGeneralTab(canvas)
    Header(canvas, "adm_h_general")
    Check(canvas, "enabled")
    InfoText(canvas, "desc_enabled")
    local languages = {}
    for _, entry in ipairs(KF.Lang.GetAvailableList(AID)) do
        languages[#languages + 1] = { value = entry.value, label = entry.name }
    end
    local langDropdown = Dropdown(canvas, L("cfg_language"), languages, KMS.Settings.language, function(value)
        SendAction("update_setting", { key = "language", value = value })
    end)
    RegisterRefresher(function()
        if IsValid(langDropdown) then langDropdown:SetValue(KMS.Settings.language) end
    end)
    Header(canvas, "adm_h_feedback")
    Check(canvas, "hudEnabled")
    Check(canvas, "notifySounds")
    Check(canvas, "bloodEffects")
    Check(canvas, "arrestTimerVisible")
    Check(canvas, "interactEnabled")
    InfoText(canvas, "desc_interactKey")
    Check(canvas, "downedIndicator")
    DependsOn(Check(canvas, "downedIndicatorAll"), BoolOn("downedIndicator"))
    Header(canvas, "adm_h_keys")
    InfoText(canvas, "desc_keys")
    SettingKeyRow(canvas, "keyMenu")
    SettingKeyRow(canvas, "keyInteract")
    SettingKeyRow(canvas, "keyQuickUse")
    Header(canvas, "adm_h_command")
    InfoText(canvas, "adm_open_hint")
    Check(canvas, "commandEnabled")
    DependsOn(TextSetting(canvas, "chatCommand", "!medical"), BoolOn("commandEnabled"))
    InfoText(canvas, "adm_heal_hint")
    TextSetting(canvas, "reviveCommand", "!revive")
    TextSetting(canvas, "healCommand", "!heal")
end

local function WeaponChoices()
    local seen, out = {}, {}
    local function add(class, printName, category)
        if not isstring(class) or class == "" or seen[class] then return end
        seen[class] = true
        out[#out + 1] = {
            class = class,
            label = (isstring(printName) and printName ~= "" and printName) or class,
            category = isstring(category) and category or (istable(category) and tostring(category[1] or "")) or "",
        }
    end
    for _, wep in ipairs(weapons.GetList() or {}) do
        add(wep.ClassName or wep.Classname, wep.PrintName, wep.Category)
    end
    for class, data in pairs(list.Get("Weapon") or {}) do
        add(class, istable(data) and data.PrintName or nil, istable(data) and data.Category or nil)
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end

local function BuildKoPicker(canvas)
    local working = table.Copy(KMS.Settings.koWeapons or {})
    RegisterRefresher(function() SyncWorking(working, "koWeapons") end)
    local choices = WeaponChoices()
    local search = vgui.Create("KF.TextInput", canvas)
    search:SetAddon(AID)
    search:SetPlaceholderText(L("search_placeholder"))
    search:SetUpdateOnType(true)
    search:SetTall(Scale(30))
    DockAdd(search, 0, Scale(6))
    search:SetWide(Scale(320))
    local scroll = vgui.Create("KF.ScrollPanel", canvas)
    scroll:SetAddon(AID)
    scroll:SetTall(Scale(280))
    DockAdd(scroll, 0, Scale(12))
    local function Rebuild(filter)
        scroll:Clear()
        for _, choice in ipairs(choices) do
            if filter == "" or KF.MatchesQuery(choice.label, filter) or KF.MatchesQuery(choice.class, filter) then
                local row = HoverSound(vgui.Create("DButton", scroll))
                row:SetText("")
                row:Dock(TOP)
                row:SetTall(Scale(28))
                row:DockMargin(0, 0, 0, Scale(2))
                row.Paint = function(s, w, h)
                    local selected = table.HasValue(working, choice.class)
                    local hoverLerp = RowBackground(s, w, h, selected)
                    KF.Draw.Checkbox(Scale(6), (h - Scale(16)) / 2, Scale(16), hoverLerp, selected and 1 or 0, AID)
                    draw.SimpleText(choice.label, F("small"), Scale(30), h / 2, selected and C("TextAccent") or C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    if choice.category ~= "" then
                        draw.SimpleText(choice.category, F("tiny"), w - Scale(10), h / 2, C("TextMuted"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                end
                row.DoClick = function()
                    if table.HasValue(working, choice.class) then
                        table.RemoveByValue(working, choice.class)
                    elseif #working >= 128 then
                        KMS.PlaySound("Error")
                        return
                    else
                        working[#working + 1] = choice.class
                    end
                    KMS.PlaySound("Click")
                    SendAction("update_setting", { key = "koWeapons", value = working })
                end
            end
        end
    end
    search.OnValueChange = function(_, value)
        Rebuild(KF.NormalizeQuery(value or ""))
    end
    Rebuild("")
    return search, scroll
end

local function BuildVitalsTab(canvas)
    Header(canvas, "adm_h_damage")
    NumberField(canvas, "damageScale")
    InfoText(canvas, "desc_damageScale")
    NumberField(canvas, "directDamage")
    InfoText(canvas, "desc_directDamage")
    NumberField(canvas, "bleedCoef")
    NumberField(canvas, "painCoef")
    NumberField(canvas, "maxBlood")
    Header(canvas, "adm_h_fractures")
    EnumDropdown(canvas, "fractureMode", KMS.FractureModes, "opt_fracture_")
    DependsOn(NumberField(canvas, "fractureChance"), function() return KMS.Settings.fractureMode ~= "disabled" end)
    DependsOn(NumberField(canvas, "fractureThreshold"), function() return KMS.Settings.fractureMode ~= "disabled" end)
    Check(canvas, "limpingEnabled")
    DependsOn(Check(canvas, "disarmEnabled"), function() return KMS.Settings.fractureMode ~= "disabled" end)
    Header(canvas, "adm_h_vitals")
    InfoText(canvas, "desc_death_pipeline")
    NumberField(canvas, "painKoChance")
    EnumDropdown(canvas, "fatalMode", KMS.FatalModes, "opt_fatal_")
    DependsOn(NumberField(canvas, "deathChance"), function() return KMS.Settings.fatalMode ~= "never" end)
    DependsOn(Check(canvas, "limbTrauma"), function() return KMS.Settings.fatalMode ~= "never" end)
    DependsOn(NumberField(canvas, "limbTraumaThreshold"), function() return KMS.Settings.limbTrauma and KMS.Settings.fatalMode ~= "never" end)
    NumberField(canvas, "arrestTime")
    NumberField(canvas, "arrestStableTimeScale")
    InfoText(canvas, "desc_arrestStable")
    Check(canvas, "arrestBleedout")
    Check(canvas, "reviveEnabled")
    NumberField(canvas, "wakeChance")
    NumberField(canvas, "wakeHealth")
    NumberField(canvas, "wakeInterval")
    NumberField(canvas, "wakeEpiBoost")
    NumberField(canvas, "cprChanceMin")
    NumberField(canvas, "cprChance")
    Check(canvas, "medicCallEnabled")
    DependsOn(NumberField(canvas, "medicCallRange"), BoolOn("medicCallEnabled"))
    InfoText(canvas, "desc_giveUp")
    Check(canvas, "giveUpEnabled")
    DependsOn(NumberField(canvas, "giveUpDelay"), BoolOn("giveUpEnabled"))
    Header(canvas, "adm_h_ko")
    InfoText(canvas, "adm_ko_desc")
    Check(canvas, "koEnabled")
    DependsOn(NumberField(canvas, "koTime"), BoolOn("koEnabled"))
    local search, scroll = BuildKoPicker(canvas)
    ShowIf(BoolOn("koEnabled"), search, scroll)
end

local ProfileSection
local dmgProfState = { selected = nil }

local function BuildTreatmentsTab(canvas)
    Header(canvas, "adm_h_rules")
    Check(canvas, "selfTreatment")
    Check(canvas, "quickUseEnabled")
    InfoText(canvas, "desc_quickUse")
    EnumDropdown(canvas, "diagnosisMode", KMS.DiagnosisModes, "opt_diag_")
    InfoText(canvas, "desc_diagnosis")
    Check(canvas, "holsterToTreat")
    InfoText(canvas, "desc_holster")
    NumberField(canvas, "maxTreatDistance")
    NumberField(canvas, "treatTimeCoef")
    InfoText(canvas, "desc_trained")
    NumberField(canvas, "trainedTimeTourniquet")
    NumberField(canvas, "trainedTimeSplint")
    NumberField(canvas, "trainedTimeInjector")
    NumberField(canvas, "trainedTimeIV")
    NumberField(canvas, "untrainedTimeTourniquet")
    NumberField(canvas, "untrainedTimeSplint")
    NumberField(canvas, "untrainedTimeInjector")
    NumberField(canvas, "untrainedTimeIV")
    NumberField(canvas, "bandageEffectiveness")
    Check(canvas, "bandageRollover")
    Check(canvas, "reopenEnabled")
    DependsOn(NumberField(canvas, "woundReopenChance"), BoolOn("reopenEnabled"))
    NumberField(canvas, "tourniquetWarnTime")
    EnumDropdown(canvas, "surgicalLocation", KMS.LocationModes, "opt_loc_")
    EnumDropdown(canvas, "pakLocation", KMS.LocationModes, "opt_loc_")
    Check(canvas, "medbayEnabled")
    DependsOn(NumberField(canvas, "medbayDeployTime"), BoolOn("medbayEnabled"))
    Check(canvas, "locationsBoostTraining")
    Check(canvas, "pakRequireStable")
    Check(canvas, "consumePak")
    Header(canvas, "adm_h_haul")
    InfoText(canvas, "adm_haul_desc")
    NumberField(canvas, "dragTime")
    NumberField(canvas, "carryTime")
    NumberField(canvas, "releaseTime")
    Header(canvas, "adm_h_meds")
    NumberField(canvas, "morphineCooldown")
    NumberField(canvas, "morphineTime")
    NumberField(canvas, "epiTime")
    NumberField(canvas, "adenosineTime")
    NumberField(canvas, "painkillersTime")
    InfoText(canvas, "desc_iv")
    NumberField(canvas, "ivVolume")
    NumberField(canvas, "ivFlowRate")
    Header(canvas, "adm_h_stratagem")
    InfoText(canvas, "adm_stratagem_desc")
    Check(canvas, "stratagemMode")
    DependsOn(EnumDropdown(canvas, "stratagemDifficulty", KMS.StratagemDifficulties, "opt_diff_"), BoolOn("stratagemMode"))
    DependsOn(EnumDropdown(canvas, "stratagemDifficultyMedic", KMS.StratagemRoleModes, "opt_diff_"), BoolOn("stratagemMode"))
    DependsOn(EnumDropdown(canvas, "stratagemDifficultyDoctor", KMS.StratagemRoleModes, "opt_diff_"), BoolOn("stratagemMode"))
    Header(canvas, "adm_h_tiers")
    InfoText(canvas, "adm_tiers_desc")
    local overrides = table.Copy(KMS.Settings.tierOverrides or {})
    RegisterRefresher(function() SyncWorking(overrides, "tierOverrides") end)
    local tierOptions = {}
    for tier = 0, 2 do
        tierOptions[#tierOptions + 1] = { value = tier, label = L("tier_" .. tier) }
    end
    for _, def in ipairs(KMS.Treatments) do
        if def.cat ~= "examine" or (def.tier or 0) > 0 then
            local dropdown = Dropdown(canvas, L("treat_" .. def.id), tierOptions, KMS.TreatmentTier(def.id), function(value)
                overrides[def.id] = value
                SendAction("update_setting", { key = "tierOverrides", value = overrides })
            end)
            RegisterRefresher(function()
                if IsValid(dropdown) then dropdown:SetValue(KMS.TreatmentTier(def.id)) end
            end)
        end
    end
    ProfileSection(canvas, {
        settingKey = "damageProfiles",
        state = dmgProfState,
        defaults = KMS.DamageProfileDefaults,
        bounds = KMS.DamageProfileBounds,
        header = "adm_h_dmgprofiles",
        desc = "adm_dmgprofiles_desc",
        confirmDelete = "confirm_dmg_delete",
        editorTall = 890,
        fields = {
            { "adm_stam_priority", "priority" },
            { "dmgprof_damage", "damage" },
            { "dmgprof_bleed", "bleed" },
            { "dmgprof_pain", "pain" },
            { "dmgprof_fracture", "fracture" },
            { "dmgprof_healing", "healing" },
        },
    })
end

local function WhitelistLabels()
    return {
        steamIds = L("wl_cat_steamIds"),
        steamPlaceholder = L("wl_steamid_placeholder"),
        usergroups = L("wl_cat_usergroups"),
        jobs = L("wl_cat_jobs"),
        jobCategories = L("wl_cat_jobCategories"),
        helixFactions = L("wl_cat_helixFactions"),
        helixClasses = L("wl_cat_helixClasses"),
        nutFactions = L("wl_cat_nutFactions"),
        nutClasses = L("wl_cat_nutClasses"),
    }
end

local function BuildWhitelistBlock(canvas, whitelist, onChange)
    local panel, _, container = KF.FormBuilder.WhitelistBlock(canvas, {
        addonId = AID,
        width = ContentW(),
        whitelist = whitelist,
        labels = WhitelistLabels(),
        onChange = onChange,
    })
    DockAdd(container, 0, Scale(12))
    return panel, container
end

local function BuildWhitelistEditor(canvas, settingKey, collect)
    local warning = InfoText(canvas, "adm_wl_warning")
    ShowIf(function()
        return KMS.Settings.medicMode == "whitelist" and not KMS.WhitelistHasEntries(KMS.Settings[settingKey])
    end, warning)
    local panel, container
    panel, container = BuildWhitelistBlock(canvas, KMS.Settings[settingKey], function()
        SendAction("update_setting", { key = settingKey, value = panel:GetWhitelistData() })
    end)
    if collect then collect[#collect + 1] = container end
end

local function BuildAccessTab(canvas)
    Header(canvas, "adm_sec_access", "adm_wl_desc")
    EnumDropdown(canvas, "medicMode", KMS.MedicModes, "opt_medic_")
    ShowIf(function() return KMS.Settings.medicMode ~= "whitelist" end, InfoText(canvas, "adm_wl_everyone"))
    local wlPanels = {}
    wlPanels[#wlPanels + 1] = Header(canvas, "adm_h_medic_wl")
    BuildWhitelistEditor(canvas, "medicWhitelist", wlPanels)
    wlPanels[#wlPanels + 1] = Header(canvas, "adm_h_doctor_wl")
    BuildWhitelistEditor(canvas, "doctorWhitelist", wlPanels)
    ShowIf(function() return KMS.Settings.medicMode == "whitelist" end, unpack(wlPanels))
    Header(canvas, "adm_h_admin_wl")
    InfoText(canvas, "adm_admin_wl_desc")
    local adminPanel
    adminPanel = BuildWhitelistBlock(canvas, KMS.Settings.adminWhitelist, function()
        SendAction("update_setting", { key = "adminWhitelist", value = adminPanel:GetWhitelistData() })
    end)
    Header(canvas, "adm_h_immunity")
    InfoText(canvas, "adm_immunity_desc")
    local imPanel
    imPanel = BuildWhitelistBlock(canvas, KMS.Settings.immuneWhitelist, function()
        SendAction("update_setting", { key = "immuneWhitelist", value = imPanel:GetWhitelistData() })
    end)
end

local function BuildItemGrid(canvas, working, Push, gridW)
    gridW = gridW or ContentW()
    local items = {}
    for _, item in ipairs(KMS.Items) do
        if not KMS.ItemDisabled[item.id] then items[#items + 1] = item end
    end
    local inputs = {}
    local iconSize = Scale(30)
    local iconPad = iconSize + Scale(8)
    local row
    for i, item in ipairs(items) do
        if i % 2 == 1 then
            row = vgui.Create("DPanel", canvas)
            row:SetTall(Scale(58))
            row.KMSIcons = {}
            row.Paint = function(s, _, h)
                for _, icon in ipairs(s.KMSIcons) do
                    DrawItemIcon(icon.mat, icon.label, icon.x, (h - iconSize) / 2, iconSize, C("TextPrimary"))
                end
            end
            DockAdd(row, 0, Scale(2))
        end
        local colW = math.floor(gridW / 2) - Scale(10)
        local baseX = (i % 2 == 1) and 0 or (colW + Scale(20))
        local label = KMS.ItemLabel(item.id)
        row.KMSIcons[#row.KMSIcons + 1] = { mat = KMS.ItemIcons[item.id], label = label, x = baseX }
        local _, input = KF.FormBuilder.TextField(row, label, { addonId = AID, width = colW - iconPad, numeric = true, value = tostring(working[item.id] or 0) })
        local container = input:GetParent()
        container:SetPos(baseX + iconPad, 0)
        input:SetWide(Scale(90))
        inputs[item.id] = input
        local function apply(s)
            local value = math.Clamp(math.floor(tonumber(s:GetValue()) or 0), 0, 999)
            s:SetText(tostring(value))
            if value ~= (working[item.id] or 0) then
                working[item.id] = value
                Push()
            end
        end
        WireApply(input, apply)
    end
    return inputs
end

local function BuildLoadoutEditor(canvas, settingKey)
    local working = table.Copy(KMS.Settings[settingKey] or {})
    local inputs = BuildItemGrid(canvas, working, function()
        SendAction("update_setting", { key = settingKey, value = working })
    end)
    RegisterRefresher(function()
        SyncWorking(working, settingKey)
        for id, input in pairs(inputs) do
            if IsValid(input) and not input:HasFocus() then
                input:SetText(tostring(working[id] or 0))
            end
        end
    end)
end

local function BuildInvGeneralTab(canvas)
    Header(canvas, "adm_sec_invgeneral", "adm_loadouts_desc")
    Check(canvas, "infiniteSupplies")
    InfoText(canvas, "desc_infiniteSupplies")
    DependsOn(NumberField(canvas, "crateCooldown"), function() return not KMS.Settings.infiniteSupplies end)
    Header(canvas, "adm_h_sharing")
    InfoText(canvas, "adm_sharing_desc")
    Check(canvas, "itemSharing")
    Header(canvas, "adm_h_loadout_default")
    ShowIf(function() return KMS.Settings.medicMode == "everyone" end, InfoText(canvas, "adm_loadout_default_note"))
    BuildLoadoutEditor(canvas, "loadoutDefault")
    Header(canvas, "adm_h_loadout_medic")
    BuildLoadoutEditor(canvas, "loadoutMedic")
    Header(canvas, "adm_h_loadout_doctor")
    BuildLoadoutEditor(canvas, "loadoutDoctor")
end

local function DetectedFramework()
    if ix then return "Helix" end
    if nut then return "NutScript" end
    if DarkRP then return "DarkRP" end
    return engine.ActiveGamemode()
end

local function BuildInvGamemodeTab(canvas)
    Header(canvas, "adm_sec_invgamemode", "desc_invMode")
    InfoText(canvas, "adm_inv_framework", nil, DetectedFramework())
    DependsOn(EnumDropdown(canvas, "invMode", KMS.InvModes, "opt_invmode_"), function() return not KMS.Settings.infiniteSupplies end)
end

local function BuildInvDeathTab(canvas)
    Header(canvas, "adm_sec_invdeath", "desc_invDeath")
    DependsOn(EnumDropdown(canvas, "invDeath", KMS.InvDeathModes, "opt_invdeath_"), KMS.PersistentInv)
    DependsOn(NumberField(canvas, "invDropExpiry"), function() return KMS.PersistentInv() and KMS.Settings.invDeath == "drop" end)
    Check(canvas, "invLootDowned")
    InfoText(canvas, "desc_invLootDowned")
end

local placement = {}

local function PlacementCleanup()
    hook.Remove("Think", "KMS_NPCPlaceThink")
    hook.Remove("HUDPaint", "KMS_NPCPlaceHUD")
    hook.Remove("KeyPress", "KMS_NPCPlaceKeys")
    if IsValid(placement.ghost) then placement.ghost:Remove() end
    placement.ghost = nil
end

local function PlacementStop(confirmed)
    if not placement.active then return end
    placement.active = false
    PlacementCleanup()
    if confirmed and placement.valid and placement.id then
        KMS.PlaySound("Click")
        net.Start("KMS_NPCPlace")
        net.WriteString(placement.id)
        net.WriteVector(placement.position)
        net.WriteAngle(placement.angle)
        net.SendToServer()
    end
    local onDone = placement.onDone
    placement.onDone = nil
    if onDone then onDone() end
end

local function PlacementValidate(pos, normal, ply)
    if bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER then
        return false, L("ui_placement_in_water")
    end
    if normal:Dot(Vector(0, 0, 1)) < 0.7 then
        return false, L("ui_placement_steep")
    end
    local dist = pos:Distance(ply:GetPos())
    if dist > 500 then return false, L("ui_placement_too_far") end
    if dist < 30 then return false, L("ui_placement_too_close") end
    local trace = util.TraceHull({
        start = pos + Vector(0, 0, 36),
        endpos = pos + Vector(0, 0, 36),
        mins = Vector(-16, -16, -36),
        maxs = Vector(16, 16, 36),
        mask = MASK_SOLID,
        filter = ply,
    })
    if trace.Hit then return false, L("ui_placement_obstructed") end
    return true, ""
end

local function PlacementStart(npc, onDone)
    PlacementStop(false)
    placement.active = true
    placement.id = npc.id
    placement.rotation = 0
    placement.valid = false
    placement.reason = ""
    placement.position = vector_origin
    placement.angle = Angle(0, 0, 0)
    placement.onDone = onDone
    placement.ghost = ClientsideModel(npc.model, RENDERGROUP_TRANSLUCENT)
    if IsValid(placement.ghost) then
        placement.ghost:SetRenderMode(RENDERMODE_TRANSCOLOR)
        placement.ghost:SetColor(Color(120, 255, 160, 130))
    end
    placement.nextTrace = 0
    hook.Add("Think", "KMS_NPCPlaceThink", function()
        if not placement.active then return end
        local now = RealTime()
        if now < placement.nextTrace then return end
        placement.nextTrace = now + 0.05
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local tr = ply:GetEyeTrace()
        if tr.Hit then
            placement.position = tr.HitPos
            placement.angle = Angle(0, ply:EyeAngles().y + placement.rotation + 180, 0)
            placement.valid, placement.reason = PlacementValidate(tr.HitPos, tr.HitNormal, ply)
        else
            placement.valid = false
            placement.reason = L("ui_placement_no_surface")
        end
        if IsValid(placement.ghost) then
            placement.ghost:SetPos(placement.position)
            placement.ghost:SetAngles(placement.angle)
            placement.ghost:SetColor(placement.valid and Color(120, 255, 160, 130) or Color(255, 80, 80, 130))
        end
    end)
    hook.Add("HUDPaint", "KMS_NPCPlaceHUD", function()
        if not placement.active then return end
        local sw, sh = ScrW(), ScrH()
        local panelW, panelH = Scale(420), Scale(90)
        local px, py = (sw - panelW) / 2, sh - panelH - Scale(60)
        KF.Menu.MenuNotchedBox(px, py, panelW, panelH, C("Panel"))
        KF.Menu.MenuNotchedOutline(px, py, panelW, panelH, C("BorderAccent"))
        draw.SimpleText(L("ui_placement_title"), FB("subheader"), px + panelW / 2, py + Scale(14), C("TextAccent"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        local status = placement.valid and L("ui_placement_valid") or (L("ui_placement_invalid_prefix") .. placement.reason)
        draw.SimpleText(status, FB("small"), px + panelW / 2, py + Scale(40), placement.valid and C("Success") or C("Error"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(L("ui_placement_hint"), F("tiny"), px + panelW / 2, py + panelH - Scale(14), C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end)
    hook.Add("KeyPress", "KMS_NPCPlaceKeys", function(ply, key)
        if not placement.active or ply ~= LocalPlayer() then return end
        if key == IN_ATTACK then
            PlacementStop(true)
        elseif key == IN_ATTACK2 or key == IN_USE then
            PlacementStop(false)
        elseif key == IN_RELOAD then
            placement.rotation = (placement.rotation + 45) % 360
        end
    end)
end

local npcState = { working = nil }

local function NewNPCRecord()
    local npc = KF.Sanitize.Apply({ id = "npc_" .. os.time(), model = KMS.Settings.npcModels.supply }, KMS.NPCSchema)
    npc.supplies = {}
    npc.storage = {}
    return npc
end

local function RecordNumber(canvas, labelKey, working, field, schemaSource)
    local schema = (schemaSource or KMS.NPCSchema)[field]
    local minValue, maxValue = schema.min or 0, schema.max or KMS.MaxCost
    local label = L(labelKey) .. BoundsSuffix(minValue, maxValue)
    local _, input = KF.FormBuilder.TextField(canvas, label, { addonId = AID, width = ContentW(), numeric = true, value = tostring(working[field] or 0) })
    DockAdd(input:GetParent())
    input:SetWide(Scale(140))
    WireApply(input, function(s)
        local value = math.Clamp(math.floor(tonumber(s:GetValue()) or (working[field] or 0)), minValue, maxValue)
        s:SetText(tostring(value))
        working[field] = value
    end)
end

local function RecordText(canvas, labelKey, working, field, placeholder)
    local _, input = KF.FormBuilder.TextField(canvas, L(labelKey), { addonId = AID, width = ContentW(), value = tostring(working[field] or ""), placeholder = placeholder })
    DockAdd(input:GetParent())
    input:SetWide(Scale(320))
    WireApply(input, function(s)
        working[field] = string.Trim(s:GetValue() or "")
    end)
end

local function BuildNPCEditor(canvas, editorPanel, refreshList, worldEnt)
    local working = npcState.working
    canvas:Clear()
    if not working then return end
    local isNew = KMS.NPCs[working.id] == nil
    local w = Scale(600)

    Header(canvas, "adm_h_npc_basic")
    RecordText(canvas, "npc_name", working, "name", working.id)
    RecordText(canvas, "npc_model", working, "model", KMS.Settings.npcModels[working.npcType])
    local typeOptions = {}
    for _, npcType in ipairs(KMS.NPCTypes) do
        typeOptions[#typeOptions + 1] = { value = npcType, label = L("npc_type_" .. npcType) }
    end
    Dropdown(canvas, L("npc_type"), typeOptions, working.npcType, function(value)
        if working.model == KMS.Settings.npcModels[working.npcType] then
            working.model = KMS.Settings.npcModels[value]
        end
        working.npcType = value
        BuildNPCEditor(canvas, editorPanel, refreshList, worldEnt)
    end)

    if working.npcType == "supply" then
        Header(canvas, "adm_h_npc_supplies")
        InfoText(canvas, "npc_supplies_desc", w)
        BuildItemGrid(canvas, working.supplies, function() end, w)
        Header(canvas, "adm_h_npc_storage")
        InfoText(canvas, "npc_storage_desc", w)
        working.storage = working.storage or {}
        BuildItemGrid(canvas, working.storage, function() end, w)
    elseif working.npcType == "simulator" then
        InfoText(canvas, "npc_simulator_desc", w)
    elseif working.npcType == "exam" then
        Header(canvas, "adm_h_npc_exam")
        InfoText(canvas, "npc_exam_desc", w)
        local rewardOptions = {}
        for _, reward in ipairs(KMS.ExamRewards) do
            rewardOptions[#rewardOptions + 1] = { value = reward, label = L("opt_reward_" .. reward) }
        end
        Dropdown(canvas, L("npc_exam_reward"), rewardOptions, working.rewardType or "tier", function(value)
            working.rewardType = value
            BuildNPCEditor(canvas, editorPanel, refreshList, worldEnt)
        end)
        if working.rewardType == "tier" or not working.rewardType then
            Dropdown(canvas, L("npc_exam_tier"), {
                { value = 1, label = L("tier_1") },
                { value = 2, label = L("tier_2") },
            }, working.examTier or 1, function(value)
                working.examTier = value
            end)
        else
            InfoText(canvas, "npc_reward_" .. working.rewardType .. "_desc", w)
            RecordText(canvas, "npc_reward_value_" .. working.rewardType, working, "rewardValue", "")
        end
        local diffOptions = {}
        for _, difficulty in ipairs(KMS.StratagemDifficulties) do
            diffOptions[#diffOptions + 1] = { value = difficulty, label = L("opt_diff_" .. difficulty) }
        end
        Dropdown(canvas, L("npc_exam_difficulty"), diffOptions, working.examDifficulty or "medium", function(value)
            working.examDifficulty = value
        end)
        RecordNumber(canvas, "npc_exam_questions", working, "examQuestions")
        RecordNumber(canvas, "npc_exam_passpct", working, "examPass")
        RecordNumber(canvas, "npc_exam_seconds", working, "examSeconds")
        RecordNumber(canvas, "npc_exam_cooldown", working, "examCooldown")
    else
        Header(canvas, "adm_h_npc_billing")
        InfoText(canvas, "npc_billing_desc", w)
        RecordNumber(canvas, "npc_heal_time", working, "healTime")
        RecordNumber(canvas, "npc_base_cost", working, "baseCost")
        RecordNumber(canvas, "npc_wound_cost", working, "woundCost")
        RecordNumber(canvas, "npc_fracture_cost", working, "fractureCost")
        RecordNumber(canvas, "npc_blood_cost", working, "bloodCost")
    end

    Header(canvas, "adm_h_npc_wl", "adm_wl_desc")
    working.whitelist = working.whitelist or {}
    local wlPanel
    wlPanel = BuildWhitelistBlock(canvas, working.whitelist, function()
        working.whitelist = wlPanel:GetWhitelistData()
    end)

    Header(canvas, "adm_h_npc_placement")
    local placed = working.spawnMap ~= ""
    local statusRow = vgui.Create("DPanel", canvas)
    statusRow:SetTall(Scale(26))
    DockAdd(statusRow, 0, Scale(6))
    statusRow.Paint = function(_, w, h)
        local text = placed and (L("npc_placed") .. " (" .. working.spawnMap .. ")") or L("npc_not_placed")
        draw.SimpleText(text, F("small"), 0, h / 2, placed and C("Success") or C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local placeRow = ButtonRow(canvas)
    local place = RowButton(placeRow, L(placed and "btn_move_npc" or "btn_place_npc"), "secondary", false, Scale(200))
    place.DoClick = function()
        if isNew then
            KMS.PlaySound("Error")
            KF.Notifications.Show(L("npc_save_before_place"), "error", 4, AID)
            return
        end
        working.whitelist = wlPanel:GetWhitelistData()
        SendAction("save_npc", { npc = working })
        local reopen = worldEnt and function() KMS.OpenNPCConfig(worldEnt) end or KMS.OpenAdmin
        local host = worldEnt and editorPanel or adminFrame
        if IsValid(host) then host:Remove() end
        PlacementStart(working, reopen)
    end
    if placed and not worldEnt then
        local unplace = RowButton(placeRow, L("btn_unplace_npc"), "danger", false, Scale(200))
        unplace.DoClick = function()
            KMS.UI.Confirm(L("confirm_unplace_npc"), function()
                SendAction("unplace_npc", { id = working.id })
            end)
        end
    end

    editorPanel.KMSSave = function()
        working.whitelist = wlPanel:GetWhitelistData()
        SendAction("save_npc", { npc = working })
    end
    editorPanel.KMSDelete = isNew and nil or function()
        KMS.UI.Confirm(L("confirm_delete_npc"), function()
            npcState.working = nil
            SendAction("delete_npc", { id = working.id })
            refreshList()
        end)
    end
end

local npcConfigFrame

function KMS.OpenNPCConfig(ent)
    if not IsValid(ent) then return end
    if not KMS.IsAdmin(LocalPlayer()) then
        KMS.PlaySound("Error")
        KF.Notifications.Show(L("err_admin_only"), "error", 4, AID)
        return
    end
    local record = (KMS.NPCs or {})[ent:GetNWString("kms_npc_id", "")]
    if not record then
        KMS.PlaySound("Error")
        KF.Notifications.Show(L("npc_config_missing"), "error", 4, AID)
        return
    end
    if IsValid(npcConfigFrame) then npcConfigFrame:Remove() end
    npcState.working = table.Copy(record)
    KMS.PlaySound("Open")

    local frame = vgui.Create("KF.Frame")
    frame:SetAddon(AID)
    frame:SetSize(Scale(900), Scale(840))
    frame:Center()
    frame:MakePopup()
    frame:SetFrameTitle(string.upper(L("npc_config_title")))
    frame:SetSubtitle(record.name)
    frame:SetHeaderHeight(52)
    npcConfigFrame = frame

    frame.OnRemove = function()
        if npcConfigFrame ~= frame then return end
        npcConfigFrame = nil
        npcState.working = nil
        KMS.PlaySound("Close")
    end

    CloseButton(frame)

    local footer = vgui.Create("DPanel", frame)
    footer:Dock(BOTTOM)
    footer:SetTall(Scale(56))
    footer:DockMargin(Scale(20), 0, Scale(20), Scale(12))
    footer.Paint = function(_, w)
        surface.SetDrawColor(C("Border"))
        surface.DrawRect(0, 0, w, 1)
    end

    local scroll = vgui.Create("KF.ScrollPanel", frame)
    scroll:SetAddon(AID)
    scroll:Dock(FILL)
    scroll:DockMargin(Scale(20), Scale(62), Scale(20), Scale(6))
    scroll:GetCanvas():DockPadding(0, 0, Scale(8), Scale(20))

    BuildNPCEditor(scroll, frame, function() frame:Remove() end, ent)

    local save = Btn(footer, L("btn_save_npc"), "primary", true)
    save:Dock(RIGHT)
    save:SetWide(Scale(230))
    save:DockMargin(Scale(8), Scale(12), 0, 0)
    save.DoClick = function()
        if frame.KMSSave then frame.KMSSave() end
        frame:Remove()
    end

    local delete = Btn(footer, L("btn_delete_npc"), "danger")
    delete:Dock(LEFT)
    delete:SetWide(Scale(210))
    delete:DockMargin(0, Scale(12), 0, 0)
    delete.DoClick = function()
        if frame.KMSDelete then frame.KMSDelete() end
    end
end

properties.Add("kms_vehicle_persist", {
    MenuLabel = "Medical vehicle",
    Order = 2,
    MenuIcon = "icon16/lorry.png",
    Filter = function(self, ent, ply)
        local root = KMS.VehicleBase(ent)
        if not KMS.IsMedVehicle(root) or not KMS.IsAdmin(ply) then return false end
        self.MenuLabel = L(root:GetNWBool("kms_vehsaved", false) and "veh_persist_off" or "veh_persist_on")
        return true
    end,
    Action = function(_, ent)
        KMS.PlaySound("Click")
        SendAction("vehicle_persist", { id = KMS.VehicleBase(ent):EntIndex() })
    end,
})

properties.Add("kms_npc_config", {
    MenuLabel = "Config NPC",
    Order = 1,
    MenuIcon = "icon16/cog.png",
    Filter = function(self, ent, ply)
        if not IsValid(ent) or ent:GetClass() ~= "kms_npc" then return false end
        if not KMS.IsAdmin(ply) then return false end
        self.MenuLabel = L("npc_config_title")
        return true
    end,
    Action = function(_, ent)
        KMS.OpenNPCConfig(ent)
    end,
})

properties.Add("kms_medbay_config", {
    MenuLabel = "Config Medbay",
    Order = 1,
    MenuIcon = "icon16/cog.png",
    Filter = function(self, ent, ply)
        if not IsValid(ent) or ent:GetClass() ~= "kms_medbay" then return false end
        if not KMS.IsAdmin(ply) then return false end
        self.MenuLabel = L("medbay_config_title")
        return true
    end,
    Action = function()
        KMS.UI.AdminSection = "models"
        net.Start("KMS_RequestSync")
        net.WriteBool(true)
        net.SendToServer()
    end,
})

local function BuildNPCsTab(content)
    local listPane = vgui.Create("DPanel", content)
    listPane:Dock(LEFT)
    listPane:SetWide(Scale(340))
    listPane.Paint = function(_, w, h)
        surface.SetDrawColor(C("Border"))
        surface.DrawRect(w - 1, 0, 1, h)
    end

    local listHeader = vgui.Create("DPanel", listPane)
    listHeader:Dock(TOP)
    listHeader:SetTall(Scale(50))
    listHeader:DockMargin(Scale(12), Scale(8), Scale(12), 0)
    listHeader.Paint = function(_, w, h)
        draw.SimpleText(L("adm_sec_npcs"), FB("subheader"), 0, h / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local addBtn = Btn(listHeader, L("btn_create_npc"), "primary", true)
    addBtn:Dock(RIGHT)
    addBtn:SetWide(Scale(110))
    addBtn:DockMargin(0, Scale(8), 0, Scale(8))

    local listScroll = vgui.Create("KF.ScrollPanel", listPane)
    listScroll:SetAddon(AID)
    listScroll:Dock(FILL)
    listScroll:DockMargin(Scale(8), Scale(8), Scale(8), Scale(8))

    local editorPanel = vgui.Create("DPanel", content)
    editorPanel:Dock(FILL)
    editorPanel:DockMargin(Scale(14), 0, 0, 0)
    editorPanel.Paint = function(self, w, h)
        KF.Draw.Panel(0, 0, w, h, { addonId = AID })
        if not npcState.working then
            draw.SimpleText(L("adm_npc_placeholder"), F("body"), w / 2, h / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local RebuildEditor, RebuildList

    RebuildEditor = function()
        editorPanel:Clear()
        editorPanel.KMSSave = nil
        editorPanel.KMSDelete = nil
        if not npcState.working then return end

        local header = vgui.Create("DPanel", editorPanel)
        header:Dock(TOP)
        header:SetTall(Scale(54))
        header:DockMargin(Scale(16), Scale(12), Scale(16), 0)
        header.Paint = function(_, w, h)
            local working = npcState.working
            local isNew = KMS.NPCs[working.id] == nil
            draw.SimpleText(isNew and L("adm_npc_new") or (working.name ~= "" and working.name or working.id), FB("subheader"), 0, Scale(4), C("TextAccent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(L("adm_npc_id_prefix") .. " " .. working.id, F("small"), 0, Scale(30), C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), 200))
            surface.DrawRect(0, h - 1, w, 1)
        end

        local footer = vgui.Create("DPanel", editorPanel)
        footer:Dock(BOTTOM)
        footer:SetTall(Scale(56))
        footer:DockMargin(Scale(16), 0, Scale(16), Scale(8))
        footer.Paint = function(_, w)
            surface.SetDrawColor(C("Border"))
            surface.DrawRect(0, 0, w, 1)
        end
        local save = Btn(footer, L("btn_save_npc"), "primary", true)
        save:Dock(LEFT)
        save:SetWide(Scale(200))
        save:DockMargin(0, Scale(10), Scale(10), Scale(6))
        save.DoClick = function()
            if editorPanel.KMSSave then editorPanel.KMSSave() end
        end
        if KMS.NPCs[npcState.working.id] ~= nil then
            local delete = Btn(footer, L("btn_delete_npc"), "danger")
            delete:Dock(RIGHT)
            delete:SetWide(Scale(200))
            delete:DockMargin(Scale(10), Scale(10), 0, Scale(6))
            delete.DoClick = function()
                if editorPanel.KMSDelete then editorPanel.KMSDelete() end
            end
        end

        local scroll = vgui.Create("KF.ScrollPanel", editorPanel)
        scroll:SetAddon(AID)
        scroll:Dock(FILL)
        scroll:DockMargin(Scale(20), Scale(10), Scale(20), Scale(6))
        scroll:GetCanvas():DockPadding(0, 0, Scale(8), Scale(20))
        BuildNPCEditor(scroll, editorPanel, RebuildList)
    end

    RebuildList = function()
        listScroll:Clear()
        local sorted = {}
        for _, npc in pairs(KMS.NPCs or {}) do
            sorted[#sorted + 1] = npc
        end
        table.sort(sorted, function(a, b) return a.name < b.name end)
        for _, npc in ipairs(sorted) do
            local row = HoverSound(vgui.Create("DButton", listScroll))
            row:SetText("")
            row:Dock(TOP)
            row:SetTall(Scale(48))
            row:DockMargin(0, 0, 0, Scale(3))
            row.Paint = function(s, w, h)
                local selected = npcState.working and npcState.working.id == npc.id
                RowBackground(s, w, h, selected)
                if selected then
                    surface.SetDrawColor(C("Accent"))
                    surface.DrawRect(0, 0, Scale(3), h)
                end
                local placedFlag = npc.spawnMap ~= ""
                draw.RoundedBox(4, Scale(12), Scale(10), Scale(8), Scale(8), placedFlag and C("Success") or C("TextDisabled"))
                draw.SimpleText(npc.name ~= "" and npc.name or npc.id, FB("small"), Scale(28), Scale(9), C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(L("npc_type_" .. npc.npcType) .. (placedFlag and ("  -  " .. npc.spawnMap) or ""), F("tiny"), Scale(28), Scale(28), C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            row.DoClick = function()
                KMS.PlaySound("Click")
                npcState.working = table.Copy(npc)
                RebuildEditor()
                RebuildList()
            end
        end
    end

    addBtn.DoClick = function()
        KMS.PlaySound("Click")
        npcState.working = NewNPCRecord()
        RebuildEditor()
        RebuildList()
    end

    RebuildList()
    RebuildEditor()
end

local function VehicleChoices()
    local seen, out = {}, {}
    local function add(class, name, category, model, base)
        class = string.lower(tostring(class or ""))
        if class == "" or seen[class] then return end
        seen[class] = true
        out[#out + 1] = {
            class = class,
            name = isstring(name) and name ~= "" and name or class,
            category = isstring(category) and category or "",
            model = isstring(model) and model ~= "" and file.Exists(model, "GAME") and model or nil,
            base = base,
        }
    end
    for name, row in pairs(list.Get("Vehicles") or {}) do
        if istable(row) and isstring(row.Class) then
            add(row.Class, row.Name or name, row.Category, row.Model, row.Class == "prop_vehicle_prisoner_pod" and "pod" or "source")
        end
    end
    local anySimfphys = false
    for _, row in pairs(list.Get("simfphys_vehicles") or {}) do
        if istable(row) then
            if isstring(row.Class) and row.Class ~= "" then
                add(row.Class, row.Name, row.Category, row.Model, "simfphys")
            else
                anySimfphys = true
            end
        end
    end
    if anySimfphys then
        add("gmod_sent_vehicle_fphysics_base", L("veh_all_simfphys"), "", nil, "simfphys")
    end
    for class, stored in pairs(scripted_ents.GetList() or {}) do
        local t = istable(stored) and (stored.t or stored) or nil
        if istable(t) and (t.Spawnable or t.AdminSpawnable) then
            local base = tostring(t.Base or "")
            local tag
            if t.LVS or base:find("lvs_", 1, true) == 1 or class:find("lvs_", 1, true) == 1 then
                tag = "LVS"
            elseif t.LFS or base:find("lfs_", 1, true) == 1 or class:find("lfs_", 1, true) == 1 then
                tag = "LFS"
            elseif t.IsSimfphyscar then
                tag = "simfphys"
            elseif t.Type == "vehicle" then
                tag = "vehicle"
            end
            if tag then
                add(class, t.PrintName, t.Category, t.MDL or t.Mdl or t.Model, tag)
            end
        end
    end
    for class in pairs(KMS.Settings.medVehicles or {}) do
        add(class, nil, nil, nil, "saved")
    end
    table.sort(out, function(a, b)
        if a.category ~= b.category then return a.category < b.category end
        return a.name < b.name
    end)
    return out
end

local function OpenVehicleEditor()
    local parent = adminFrame
    if not IsValid(parent) then return end
    if IsValid(parent.KMSVehEditor) then parent.KMSVehEditor:Remove() end

    local working = table.Copy(KMS.Settings.medVehicles or {})
    local choices = VehicleChoices()
    local choiceByClass = {}
    for _, choice in ipairs(choices) do
        choiceByClass[choice.class] = choice
    end
    local curClass
    for _, choice in ipairs(choices) do
        if working[choice.class] then
            curClass = choice.class
            break
        end
    end

    local fw, fh = parent:GetSize()
    local backdrop = vgui.Create("DPanel", parent)
    backdrop:SetSize(fw, fh)
    backdrop:SetZPos(100)
    backdrop:MoveToFront()
    backdrop:SetMouseInputEnabled(true)
    backdrop.FadeIn = 0
    backdrop.Paint = function(s, w, h)
        s.FadeIn = math.min(s.FadeIn + KF.Anim.GetFrameTime() * 5, 1)
        surface.SetDrawColor(0, 0, 0, 200 * s.FadeIn)
        surface.DrawRect(0, 0, w, h)
    end
    parent.KMSVehEditor = backdrop

    local frame = vgui.Create("DPanel", backdrop)
    frame:SetSize(fw, fh)
    frame.Paint = function(_, w, h)
        local a = math.floor(255 * backdrop.FadeIn)
        draw.RoundedBox(8, 0, 0, w, h, KF.UI.ColorAlpha(C("Background"), a))
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Border"), a))
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), a))
        surface.DrawRect(2, 2, w - 4, 3)
    end

    local pad = Scale(16)
    local headerH = Scale(56)
    local footerH = Scale(64)

    local header = vgui.Create("DPanel", frame)
    header:SetPos(pad, pad)
    header:SetSize(fw - pad * 2, headerH)
    header.Paint = function(_, w, h)
        draw.SimpleText(L("adm_sec_vehicles"), FB("subheader"), Scale(8), Scale(4), C("TextPrimary"))
        draw.SimpleText(L("adm_veh_classes_desc"), F("small"), Scale(8), Scale(32), C("TextMuted"))
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Border"), 80))
        surface.DrawRect(0, h - 1, w, 1)
    end

    local contentY = pad + headerH + Scale(8)
    local contentH = fh - contentY - footerH - pad * 2
    local content = vgui.Create("DPanel", frame)
    content:SetPos(pad, contentY)
    content:SetSize(fw - pad * 2, contentH)
    content.Paint = nil

    local leftW = math.floor(content:GetWide() * 0.32)
    local gap = Scale(12)
    local rightW = content:GetWide() - leftW - gap
    local innerPad = Scale(10)

    local leftPanel = vgui.Create("DPanel", content)
    leftPanel:SetSize(leftW, contentH)
    leftPanel.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C("PanelDark"))
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Border"), 60))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local leftHeader = vgui.Create("DPanel", leftPanel)
    leftHeader:Dock(TOP)
    leftHeader:SetTall(Scale(32))
    leftHeader:DockMargin(innerPad, innerPad, innerPad, 0)
    leftHeader.Paint = function(_, w, h)
        draw.SimpleText(L("adm_h_veh_classes"), FB("small"), 0, h / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local instruction = vgui.Create("DPanel", leftPanel)
    instruction:Dock(TOP)
    instruction:SetTall(Scale(20))
    instruction:DockMargin(innerPad, 0, innerPad, 0)
    instruction.Paint = function(_, w, h)
        draw.SimpleText(L("veh_ed_instruction"), F("tiny"), 0, h / 2, KF.UI.ColorAlpha(C("TextMuted"), 160), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local search = vgui.Create("KF.TextInput", leftPanel)
    search:SetAddon(AID)
    search:SetPlaceholderText(L("search_placeholder"))
    search:SetUpdateOnType(true)
    search:Dock(TOP)
    search:SetTall(Scale(32))
    search:DockMargin(innerPad, Scale(6), innerPad, Scale(8))

    local modelScroll = vgui.Create("KF.ScrollPanel", leftPanel)
    modelScroll:SetAddon(AID)
    modelScroll:Dock(FILL)
    modelScroll:DockMargin(innerPad, 0, Scale(4), innerPad)

    local rightPanel = vgui.Create("DPanel", content)
    rightPanel:SetPos(leftW + gap, 0)
    rightPanel:SetSize(rightW, contentH)
    rightPanel.Paint = nil

    local previewH = math.floor(contentH * 0.55)
    local previewContainer = vgui.Create("DPanel", rightPanel)
    previewContainer:Dock(TOP)
    previewContainer:SetTall(previewH)
    previewContainer.Paint = function(_, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C("PanelDark"))
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, KF.UI.ColorAlpha(C("Accent"), 12))
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), 50))
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        local choice = curClass and choiceByClass[curClass]
        if not choice then
            draw.SimpleText(L("veh_ed_instruction"), F("body"), w / 2, h / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        draw.SimpleText(L("veh_ed_preview") .. " " .. choice.name, F("small"), Scale(10), Scale(8), KF.UI.ColorAlpha(C("TextMuted"), 200))
        if not choice.model then
            draw.SimpleText(L("veh_ed_nomodel"), F("body"), w / 2, h / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local modelPanel = vgui.Create("DModelPanel", previewContainer)
    modelPanel:Dock(FILL)
    modelPanel:DockMargin(Scale(6), Scale(6), Scale(6), Scale(6))
    modelPanel:SetFOV(40)
    modelPanel.KMSZoom = 1
    function modelPanel:LayoutEntity(ent)
        ent:SetAngles(Angle(0, RealTime() * 25 % 360, 0))
    end
    modelPanel.KMSApplyCam = function()
        local ent = modelPanel:GetEntity()
        if not IsValid(ent) then return end
        local mn, mx = ent:GetRenderBounds()
        local center = (mn + mx) * 0.5
        local dist = math.max((mx - mn):Length(), 80) * modelPanel.KMSZoom
        modelPanel:SetCamPos(center + Vector(dist * 0.75, dist * 0.55, dist * 0.3))
        modelPanel:SetLookAt(center)
    end
    modelPanel.OnMouseWheeled = function(s, delta)
        s.KMSZoom = math.Clamp(s.KMSZoom - delta * 0.08, 0.45, 2)
        s.KMSApplyCam()
        return true
    end

    local configScroll = vgui.Create("KF.ScrollPanel", rightPanel)
    configScroll:SetAddon(AID)
    configScroll:Dock(FILL)
    configScroll:DockMargin(0, Scale(10), 0, 0)

    local RefreshList, RefreshConfig

    local function SetPreview(class)
        curClass = class
        local choice = class and choiceByClass[class] or nil
        modelPanel:SetVisible(choice ~= nil and choice.model ~= nil)
        if choice and choice.model then
            modelPanel:SetModel(choice.model)
            modelPanel.KMSZoom = 1
            modelPanel.KMSApplyCam()
        end
        RefreshConfig()
    end

    RefreshConfig = function()
        configScroll:Clear()
        if not curClass then return end
        local choice = choiceByClass[curClass]
        local entry = working[curClass]
        local title = vgui.Create("DPanel", configScroll)
        title:Dock(TOP)
        title:SetTall(Scale(28))
        title.Paint = function(_, w, h)
            draw.SimpleText(L("adm_veh_editing", choice and choice.name or curClass), FB("body"), 0, h / 2, C("TextAccent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        if not entry then
            local hint = vgui.Create("DPanel", configScroll)
            hint:Dock(TOP)
            hint:SetTall(Scale(26))
            hint.Paint = function(_, w, h)
                draw.SimpleText(L("veh_ed_not_medical"), F("small"), 0, h / 2, C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            return
        end
        local mode = vgui.Create("DPanel", configScroll)
        mode:Dock(TOP)
        mode:SetTall(Scale(22))
        mode.Paint = function(_, w, h)
            draw.SimpleText(entry.inv and L("adm_veh_custom_inv") or L("adm_veh_global_inv"), F("small"), 0, h / 2, entry.inv and C("Warning") or C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local buttons = vgui.Create("DPanel", configScroll)
        buttons:Dock(TOP)
        buttons:SetTall(Scale(36))
        buttons:DockMargin(0, Scale(4), 0, Scale(6))
        buttons.Paint = nil
        local globalBtn = RowButton(buttons, L("btn_veh_use_global"), nil, false, Scale(210))
        globalBtn.DoClick = function()
            entry.inv = nil
            RefreshConfig()
        end
        local editBtn = RowButton(buttons, L("btn_veh_edit_inv"), "primary", false, Scale(210))
        editBtn.DoClick = function()
            if not entry.inv then
                entry.inv = table.Copy(KMS.Settings.medVehicleInvDefault or {})
            end
            RefreshConfig()
        end
        local copyOptions = { { value = "", label = L("adm_veh_copy_pick") } }
        for otherClass, otherEntry in pairs(working) do
            if otherClass ~= curClass and otherEntry.inv then
                copyOptions[#copyOptions + 1] = { value = otherClass, label = otherClass }
            end
        end
        if #copyOptions > 1 then
            Dropdown(configScroll, L("adm_veh_copy_from"), copyOptions, "", function(value)
                if value == "" or not working[value] or not working[value].inv then return end
                entry.inv = table.Copy(working[value].inv)
                RefreshConfig()
            end, rightW - Scale(30))
        end
        if entry.inv then
            BuildItemGrid(configScroll, entry.inv, function() end, rightW - Scale(30))
        end
    end

    RefreshList = function(filter)
        modelScroll:Clear()
        filter = KF.NormalizeQuery(filter or "")
        for _, choice in ipairs(choices) do
            if filter == "" or KF.MatchesQuery(choice.name, filter) or KF.MatchesQuery(choice.class, filter) then
                local item = HoverSound(vgui.Create("DButton", modelScroll))
                item:SetText("")
                item:Dock(TOP)
                item:DockMargin(0, 0, Scale(4), Scale(3))
                item:SetTall(Scale(42))
                item:SetCursor("hand")
                item.Paint = function(s, w, h)
                    local hover = KF.Anim.UpdateHoverLerp(s, 10)
                    local checked = working[choice.class] ~= nil
                    local base = C("PanelDark")
                    local add = math.floor(25 * hover + (checked and 15 or 0))
                    draw.RoundedBox(4, 0, 0, w, h, Color(math.min(base.r + add, 255), math.min(base.g + add, 255), math.min(base.b + add, 255)))
                    if checked then
                        surface.SetDrawColor(C("Accent"))
                        surface.DrawRect(0, 0, Scale(3), h)
                    end
                    KF.Draw.Checkbox(Scale(8), (h - Scale(16)) / 2, Scale(16), hover, checked and 1 or 0, AID)
                    local textX = Scale(32)
                    draw.SimpleText(choice.name, F("small"), textX, h * 0.35, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local path = KMS.Ellipsize(choice.class, F("tiny"), w - textX - Scale(30), true)
                    draw.SimpleText(path, F("tiny"), textX, h * 0.7, KF.UI.ColorAlpha(C("TextMuted"), 160), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local isPreview = curClass == choice.class
                    draw.SimpleText(isPreview and "●" or "○", F("small"), w - Scale(12), h / 2, isPreview and C("Accent") or KF.UI.ColorAlpha(C("TextMuted"), math.floor(40 + 80 * hover)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                item.OnMousePressed = function(s, code)
                    KMS.PlaySound("Click")
                    if code == MOUSE_RIGHT then
                        SetPreview(choice.class)
                        return
                    end
                    if code ~= MOUSE_LEFT then return end
                    local mx = s:ScreenToLocal(gui.MouseX(), 0)
                    if mx >= s:GetWide() - Scale(28) then
                        SetPreview(choice.class)
                    elseif working[choice.class] then
                        working[choice.class] = nil
                        if curClass == choice.class then SetPreview(nil) end
                    else
                        working[choice.class] = {}
                        SetPreview(choice.class)
                    end
                end
            end
        end
    end

    search.OnValueChange = function(_, value)
        RefreshList(value)
    end

    local footer = vgui.Create("DPanel", frame)
    footer:SetPos(pad, fh - footerH - pad)
    footer:SetSize(fw - pad * 2, footerH)
    footer.Paint = function(_, w, h)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Border"), 80))
        surface.DrawRect(0, 0, w, 1)
        draw.SimpleText(L("veh_ed_summary", table.Count(working)), F("small"), Scale(8), h / 2, C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local btnH = Scale(38)
    local saveBtn = Btn(footer, L("btn_save"), "primary", true)
    saveBtn:Dock(RIGHT)
    saveBtn:SetWide(Scale(160))
    saveBtn:DockMargin(Scale(10), (footerH - btnH) / 2, 0, (footerH - btnH) / 2)
    saveBtn.DoClick = function()
        SendAction("update_setting", { key = "medVehicles", value = working })
        backdrop:Remove()
    end
    local cancelBtn = Btn(footer, L("btn_cancel"))
    cancelBtn:Dock(RIGHT)
    cancelBtn:SetWide(Scale(140))
    cancelBtn:DockMargin(0, (footerH - btnH) / 2, 0, (footerH - btnH) / 2)
    cancelBtn.DoClick = function()
        backdrop:Remove()
    end

    hook.Add("PlayerButtonDown", "KMS_VehEditorEsc", function(_, key)
        if key == KEY_ESCAPE and IsValid(backdrop) then
            backdrop:Remove()
        end
    end)
    backdrop.OnRemove = function()
        hook.Remove("PlayerButtonDown", "KMS_VehEditorEsc")
    end

    RefreshList("")
    if curClass then
        SetPreview(curClass)
    else
        modelPanel:SetVisible(false)
    end
end

local function BuildVehiclesTab(canvas)
    Header(canvas, "adm_sec_vehicles", "adm_vehicles_desc")
    EnumDropdown(canvas, "medVehicleAccess", KMS.MedVehicleAccessModes, "opt_vehacc_")
    InfoText(canvas, "desc_medVehicleSave")
    EnumDropdown(canvas, "medVehicleLoss", KMS.VehicleLossModes, "opt_vehloss_")
    DependsOn(NumberField(canvas, "medVehicleRespawnTime"), function() return KMS.Settings.medVehicleLoss == "respawn" end)
    InfoText(canvas, "adm_vehacc_desc")
    Header(canvas, "adm_h_veh_wl")
    local wlPanel
    wlPanel = BuildWhitelistBlock(canvas, KMS.Settings.medVehicleWhitelist, function()
        SendAction("update_setting", { key = "medVehicleWhitelist", value = wlPanel:GetWhitelistData() })
    end)
    Header(canvas, "adm_h_veh_default_inv")
    InfoText(canvas, "adm_veh_default_desc")
    BuildLoadoutEditor(canvas, "medVehicleInvDefault")
    Header(canvas, "adm_h_veh_classes")
    InfoText(canvas, "adm_veh_classes_desc")
    local summary = vgui.Create("DPanel", canvas)
    summary:SetTall(Scale(24))
    DockAdd(summary, 0, Scale(4))
    summary.Paint = function(_, w, h)
        draw.SimpleText(L("veh_ed_summary", table.Count(KMS.Settings.medVehicles or {})), FB("small"), 0, h / 2, C("TextAccent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local configure = RowButton(ButtonRow(canvas), L("btn_veh_configure"), "primary", true, Scale(320))
    configure.DoClick = OpenVehicleEditor
end

ProfileSection = function(canvas, opts)
    Header(canvas, opts.header, opts.desc)
    local working = table.Copy(KMS.Settings[opts.settingKey] or {})
    RegisterRefresher(function() SyncWorking(working, opts.settingKey, true) end)
    local state = opts.state
    local function Push()
        SendAction("update_setting", { key = opts.settingKey, value = working })
    end

    local listPanel = vgui.Create("DPanel", canvas)
    listPanel.Paint = nil
    DockAdd(listPanel, 0, Scale(8))

    local editor = vgui.Create("DPanel", canvas)
    editor.Paint = nil
    DockAdd(editor, 0, Scale(10))

    local RebuildProfiles, RebuildEditor

    local function ProfileField(parent, labelKey, id, field)
        local bounds = opts.bounds[field]
        local profile = working[id]
        local _, input = KF.FormBuilder.TextField(parent, L(labelKey) .. BoundsSuffix(bounds[1], bounds[2]), { addonId = AID, width = ContentW(), numeric = true, value = tostring(profile[field] or 100) })
        DockAdd(input:GetParent())
        input:SetWide(Scale(140))
        WireApply(input, function(s)
            local prof = working[id]
            if not prof then return end
            local value = math.Clamp(math.floor(tonumber(s:GetValue()) or (prof[field] or 100)), bounds[1], bounds[2])
            s:SetText(tostring(value))
            if value ~= prof[field] then
                prof[field] = value
                Push()
            end
        end)
    end

    RebuildEditor = function()
        editor:Clear()
        local id = state.selected
        local profile = id and working[id] or nil
        if not profile then
            editor:SetTall(Scale(1))
            return
        end
        editor:SetTall(Scale(opts.editorTall))
        local header = vgui.Create("DPanel", editor)
        header:Dock(TOP)
        header:SetTall(Scale(30))
        header.Paint = function(_, w, h)
            draw.SimpleText(L("adm_stam_editing", profile.name or id), FB("body"), 0, h / 2, C("TextAccent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local _, nameInput = KF.FormBuilder.TextField(editor, L("adm_stam_name"), { addonId = AID, width = ContentW(), value = tostring(profile.name or id) })
        DockAdd(nameInput:GetParent())
        nameInput:SetWide(Scale(240))
        WireApply(nameInput, function(s)
            local prof = working[id]
            if not prof then return end
            local value = string.sub(string.Trim(s:GetValue() or ""), 1, 48)
            if value ~= "" and value ~= prof.name then
                prof.name = value
                Push()
                RebuildProfiles()
            end
        end)
        for _, field in ipairs(opts.fields) do
            ProfileField(editor, field[1], id, field[2])
        end
        if opts.line then
            local effective = vgui.Create("DPanel", editor)
            effective:Dock(TOP)
            effective:SetTall(Scale(24))
            effective.Paint = function(_, w, h)
                draw.SimpleText(opts.line(profile), F("small"), 0, h / 2, C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
        local wlPanel
        wlPanel = BuildWhitelistBlock(editor, profile.whitelist or {}, function()
            local prof = working[id]
            if not prof then return end
            prof.whitelist = wlPanel:GetWhitelistData()
            Push()
        end)
        local deleteBtn = RowButton(ButtonRow(editor), L("btn_stam_delete"), "danger", false, Scale(220))
        deleteBtn.DoClick = function()
            KMS.UI.Confirm(L(opts.confirmDelete), function()
                working[id] = nil
                state.selected = nil
                Push()
                RebuildProfiles()
                RebuildEditor()
            end)
        end
    end

    RebuildProfiles = function()
        listPanel:Clear()
        local sorted = {}
        for id, profile in pairs(working) do
            sorted[#sorted + 1] = { id = id, profile = profile }
        end
        table.sort(sorted, function(a, b)
            if a.profile.priority ~= b.profile.priority then return a.profile.priority > b.profile.priority end
            return a.id < b.id
        end)
        listPanel:SetTall(#sorted * Scale(40) + Scale(44))
        for _, entry in ipairs(sorted) do
            local row = HoverSound(vgui.Create("DButton", listPanel))
            row:SetText("")
            row:Dock(TOP)
            row:SetTall(Scale(36))
            row:DockMargin(0, 0, 0, Scale(3))
            row.Paint = function(s, w, h)
                local selected = state.selected == entry.id
                RowBackground(s, w, h, selected)
                draw.SimpleText((entry.profile.name or entry.id) .. "  (" .. entry.profile.priority .. ")", FB("small"), Scale(10), h / 2, selected and C("TextAccent") or C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if opts.line then
                    draw.SimpleText(opts.line(entry.profile), F("tiny"), w - Scale(10), h / 2, C("TextMuted"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end
            row.DoClick = function()
                KMS.PlaySound("Click")
                state.selected = entry.id
                RebuildEditor()
                RebuildProfiles()
            end
        end
        local createBtn = RowButton(ButtonRow(listPanel), L("btn_stam_create"), "primary", true, Scale(240))
        createBtn.DoClick = function()
            local id = "profile_" .. os.time()
            local profile = table.Copy(opts.defaults)
            profile.name = id
            profile.whitelist = {}
            working[id] = profile
            state.selected = id
            Push()
            RebuildProfiles()
            RebuildEditor()
        end
    end

    RebuildProfiles()
    RebuildEditor()
end

local stamState = { selected = nil }

local function EffectiveLine(profile)
    local function eff(field, globalKey)
        return math.Round((profile[field] or 100) * (KMS.Settings[globalKey] or 100) / 100)
    end
    return L("adm_stam_effective", eff("capacity", "staminaCapacity"), eff("drain", "sprintDrain"), eff("recovery", "staminaRecovery"), profile.stability or 100)
end

local function BuildStaminaTab(canvas)
    Header(canvas, "adm_sec_stamina", "adm_stamina_desc")
    Check(canvas, "staminaEnabled")
    local stamOn = BoolOn("staminaEnabled")
    DependsOn(NumberField(canvas, "staminaCapacity"), stamOn)
    DependsOn(NumberField(canvas, "staminaRecovery"), stamOn)
    DependsOn(NumberField(canvas, "sprintDrain"), stamOn)
    DependsOn(NumberField(canvas, "fatigueAccum"), stamOn)
    Header(canvas, "adm_h_stam_medical")
    DependsOn(NumberField(canvas, "painSway"), stamOn)
    DependsOn(NumberField(canvas, "fractureSway"), stamOn)
    DependsOn(NumberField(canvas, "bloodEndurance"), stamOn)
    DependsOn(NumberField(canvas, "weaponSway"), stamOn)
    Header(canvas, "adm_h_stam_weapons")
    InfoText(canvas, "adm_stam_weapons_desc")
    DependsOn(Check(canvas, "arc9Integration"), stamOn)
    DependsOn(Check(canvas, "arccwIntegration"), stamOn)
    DependsOn(Check(canvas, "staminaEncumbrance"), stamOn)
    DependsOn(EnumDropdown(canvas, "staminaFeedback", KMS.StaminaFeedbackModes, "opt_stamfb_"), stamOn)

    ProfileSection(canvas, {
        settingKey = "staminaProfiles",
        state = stamState,
        defaults = KMS.StaminaProfileDefaults,
        bounds = KMS.StaminaProfileBounds,
        header = "adm_h_stam_profiles",
        desc = "adm_stam_profiles_desc",
        confirmDelete = "confirm_stam_delete",
        editorTall = 912,
        line = EffectiveLine,
        fields = {
            { "adm_stam_priority", "priority" },
            { "adm_stam_capacity", "capacity" },
            { "adm_stam_drain", "drain" },
            { "adm_stam_recovery", "recovery" },
            { "adm_stam_fatigueres", "fatigueRes" },
            { "adm_stam_stability", "stability" },
        },
    })
end

BuildMapsSection = function(canvas)
    Header(canvas, "adm_h_maps", "adm_maps_desc")
    local working = table.Copy(KMS.Settings.mapPresets or {})
    RegisterRefresher(function() SyncWorking(working, "mapPresets") end)
    local presetOptions = {}
    for _, preset in ipairs(KMS.Presets) do
        presetOptions[#presetOptions + 1] = { value = preset.id, label = L("preset_" .. preset.id) }
    end
    local currentMap = string.lower(game.GetMap())
    local function Push()
        SendAction("update_setting", { key = "mapPresets", value = working })
    end
    local search = vgui.Create("KF.TextInput", canvas)
    search:SetAddon(AID)
    search:SetPlaceholderText(L("search_placeholder"))
    search:SetUpdateOnType(true)
    search:SetTall(Scale(30))
    DockAdd(search, 0, Scale(6))
    search:SetWide(Scale(320))
    local scroll = vgui.Create("KF.ScrollPanel", canvas)
    scroll:SetAddon(AID)
    scroll:SetTall(Scale(460))
    DockAdd(scroll, 0, Scale(12))
    local function Rebuild(filter)
        scroll:Clear()
        for _, map in ipairs(KMS.ServerMaps or {}) do
            if filter == "" or KF.MatchesQuery(map, filter) then
                local row = HoverSound(vgui.Create("DButton", scroll))
                row:SetText("")
                row:Dock(TOP)
                row:SetTall(Scale(30))
                row:DockMargin(0, 0, 0, Scale(2))
                row.Paint = function(s, w, h)
                    local assigned = working[map] ~= nil
                    local hoverLerp = RowBackground(s, w, h, assigned)
                    KF.Draw.Checkbox(Scale(6), (h - Scale(16)) / 2, Scale(16), hoverLerp, assigned and 1 or 0, AID)
                    draw.SimpleText(map, F("small"), Scale(30), h / 2, assigned and C("TextAccent") or C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    if map == currentMap then
                        draw.SimpleText(L("adm_maps_current"), F("tiny"), w - Scale(220), h / 2, C("Warning"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                    end
                end
                row.DoClick = function()
                    working[map] = not working[map] and KMS.Presets[1].id or nil
                    KMS.PlaySound("Click")
                    Push()
                    Rebuild(filter)
                end
                if working[map] then
                    local dropdown = vgui.Create("KF.PopupDropdown", row)
                    dropdown:Dock(RIGHT)
                    dropdown:DockMargin(0, Scale(3), Scale(4), Scale(3))
                    dropdown:SetWide(Scale(200))
                    StyleDropdown(dropdown, presetOptions, working[map])
                    dropdown.OnSelect = function(_, _, _, value)
                        working[map] = value
                        Push()
                    end
                end
            end
        end
    end
    search.OnValueChange = function(_, value)
        Rebuild(KF.NormalizeQuery(value or ""))
    end
    Rebuild("")
end

local function BuildModelsTab(canvas)
    Header(canvas, "adm_h_models", "adm_models_desc")
    local working = table.Copy(KMS.Settings.npcModels or {})
    RegisterRefresher(function() SyncWorking(working, "npcModels") end)
    local keys = {}
    for _, npcType in ipairs(KMS.NPCTypes) do
        keys[#keys + 1] = npcType
    end
    keys[#keys + 1] = "medbay"
    for _, typeKey in ipairs(keys) do
        local label = typeKey == "medbay" and L("medbay_title") or L("npc_type_" .. typeKey)
        local _, input = KF.FormBuilder.TextField(canvas, label, { addonId = AID, width = ContentW(), value = working[typeKey] or "" })
        DockAdd(input:GetParent())
        input:SetWide(Scale(420))
        WireApply(input, function(s)
            local value = string.Trim(s:GetValue() or "")
            if value == "" or value == working[typeKey] then
                s:SetText(working[typeKey] or "")
                return
            end
            working[typeKey] = value
            SendAction("update_setting", { key = "npcModels", value = working })
        end)
        RegisterRefresher(function()
            if IsValid(input) and not input:HasFocus() then input:SetText(working[typeKey] or "") end
        end)
    end
end

local itemState = { selected = nil }

local function BuildItemsTab(content)
    local listPane = vgui.Create("DPanel", content)
    listPane:Dock(LEFT)
    listPane:SetWide(Scale(340))
    listPane.Paint = function(_, w, h)
        surface.SetDrawColor(C("Border"))
        surface.DrawRect(w - 1, 0, 1, h)
    end

    local createRow = vgui.Create("DPanel", listPane)
    createRow:Dock(TOP)
    createRow:SetTall(Scale(34))
    createRow:DockMargin(Scale(10), Scale(10), Scale(12), Scale(4))
    createRow.Paint = nil

    local search = vgui.Create("KF.TextInput", listPane)
    search:SetAddon(AID)
    search:SetPlaceholderText(L("search_placeholder"))
    search:SetUpdateOnType(true)
    search:Dock(TOP)
    search:SetTall(Scale(30))
    search:DockMargin(Scale(10), Scale(4), Scale(12), Scale(4))

    local listScroll = vgui.Create("KF.ScrollPanel", listPane)
    listScroll:SetAddon(AID)
    listScroll:Dock(FILL)
    listScroll:DockMargin(Scale(10), Scale(4), Scale(12), Scale(10))

    local editorScroll = Scroll(content)

    local working
    local RebuildList, RebuildEditor

    local createBtn = Btn(createRow, L("btn_item_new"), "primary")
    createBtn:Dock(FILL)
    createBtn.DoClick = function()
        itemState.selected = "custom_" .. os.time()
        working = KF.Sanitize.Apply({ id = itemState.selected }, KMS.ItemSchema)
        RebuildEditor()
    end

    RebuildList = function(filter)
        filter = filter or KF.NormalizeQuery(search:GetValue() or "")
        listScroll:Clear()
        local config = KMS.ItemConfig
        for _, item in ipairs(KMS.Items) do
            local id = item.id
            local label = KMS.ItemLabel(id)
            if filter == "" or KF.MatchesQuery(label, filter) or KF.MatchesQuery(id, filter) then
                local row = HoverSound(vgui.Create("DButton", listScroll))
                row:SetText("")
                row:Dock(TOP)
                row:SetTall(Scale(30))
                row:DockMargin(0, 0, 0, Scale(2))
                row.Paint = function(s, w, h)
                    local selected = itemState.selected == id
                    local disabled = KMS.ItemDisabled[id]
                    RowBackground(s, w, h, selected)
                    local iconSize = Scale(20)
                    local color = disabled and C("TextMuted") or C("TextPrimary")
                    DrawItemIcon(KMS.ItemIcons[id], label, Scale(6), (h - iconSize) / 2, iconSize, color)
                    draw.SimpleText(label .. (disabled and ("  -  " .. L("item_disabled")) or ""), F("small"), Scale(32), h / 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local badge = item.custom and config.custom[id] and L("item_kind_" .. config.custom[id].kind) or L("item_core")
                    draw.SimpleText(badge, F("tiny"), w - Scale(8), h / 2, item.custom and C("TextAccent") or C("TextMuted"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
                row.DoClick = function()
                    KMS.PlaySound("Click")
                    itemState.selected = id
                    working = nil
                    RebuildEditor()
                end
            end
        end
    end

    RebuildEditor = function()
        editorScroll:Clear()
        local id = itemState.selected
        local config = KMS.ItemConfig
        if not id then
            Header(editorScroll, "adm_h_items", "adm_items_desc")
            return
        end
        local isCore = KMS.BaseItemIds[id]
        local saved = KMS.ItemById[id] ~= nil
        local title = saved and KMS.ItemLabel(id) or L("btn_item_create", L("item_kind_" .. (working and working.kind or "bandage")))
        DockAdd(KF.FormBuilder.SectionHeader(editorScroll, title, nil, { addonId = AID, width = ContentW() }), Scale(10), Scale(8))
        if saved then
            local text = WikiText(id)
            if text ~= "" then GuideItem(editorScroll, id, text) end
        end
        if isCore then
            local _, input = KF.FormBuilder.TextField(editorScroll, L("item_f_name"), { addonId = AID, width = ContentW(), value = config.renames[id] or "", placeholder = KMS.ItemLabel(id) })
            DockAdd(input:GetParent(), Scale(10))
            input:SetWide(Scale(320))
            WireApply(input, function(s)
                SendAction("rename_item", { id = id, name = string.Trim(s:GetValue() or "") })
            end)
            local _, cb = KF.FormBuilder.Checkbox(editorScroll, L("item_enabled"), not config.disabled[id], { addonId = AID, width = ContentW() })
            DockAdd(cb:GetParent())
            cb:SetSound(KMS.Sounds.Click)
            cb:SetHoverSound(KMS.Sounds.Hover)
            cb.OnChange = function(_, checked)
                if refreshing then return end
                SendAction("toggle_item", { id = id, disabled = not checked })
            end
        else
            working = working or (config.custom[id] and table.Copy(config.custom[id])) or KF.Sanitize.Apply({ id = id }, KMS.ItemSchema)
            local kindOptions = {}
            for _, kind in ipairs(KMS.ItemKinds) do
                kindOptions[#kindOptions + 1] = { value = kind, label = L("item_kind_" .. kind) }
            end
            Dropdown(editorScroll, L("item_f_kind"), kindOptions, working.kind, function(value)
                working.kind = value
                RebuildEditor()
            end)
            local _, input = KF.FormBuilder.TextField(editorScroll, L("item_f_name"), { addonId = AID, width = ContentW(), value = working.name })
            DockAdd(input:GetParent(), Scale(10))
            input:SetWide(Scale(320))
            WireApply(input, function(s)
                working.name = string.Trim(s:GetValue() or "")
            end)
            local _, iconInput = KF.FormBuilder.TextField(editorScroll, L("item_f_icon"), { addonId = AID, width = ContentW(), value = working.icon })
            DockAdd(iconInput:GetParent())
            iconInput:SetWide(Scale(420))
            WireApply(iconInput, function(s)
                working.icon = string.Trim(s:GetValue() or "")
            end)
            local iconOptions = { { value = "", label = "-" } }
            for _, base in ipairs(KMS.Items) do
                if KMS.BaseItemIds[base.id] then
                    iconOptions[#iconOptions + 1] = { value = base.id, label = KMS.ItemLabel(base.id) }
                end
            end
            Dropdown(editorScroll, L("item_f_icon_pick"), iconOptions, "", function(value)
                if value ~= "" then
                    working.icon = value
                    RebuildEditor()
                end
            end)
            RecordNumber(editorScroll, "item_f_tier", working, "tier", KMS.ItemSchema)
            if working.kind == "bandage" then
                RecordNumber(editorScroll, "item_f_power", working, "power", KMS.ItemSchema)
                RecordNumber(editorScroll, "item_f_stability", working, "stability", KMS.ItemSchema)
            elseif working.kind == "med" then
                RecordNumber(editorScroll, "item_f_pain", working, "painReduce", KMS.ItemSchema)
                RecordNumber(editorScroll, "item_f_hr", working, "hrEffect", KMS.ItemSchema)
                RecordNumber(editorScroll, "item_f_heal", working, "heal", KMS.ItemSchema)
                RecordNumber(editorScroll, "item_f_stamina", working, "stamina", KMS.ItemSchema)
                RecordNumber(editorScroll, "item_f_duration", working, "duration", KMS.ItemSchema)
                RecordNumber(editorScroll, "item_f_maxdose", working, "maxDose", KMS.ItemSchema)
                RecordNumber(editorScroll, "item_f_time", working, "applyTime", KMS.ItemSchema)
            else
                RecordNumber(editorScroll, "item_f_volume", working, "volume", KMS.ItemSchema)
                RecordNumber(editorScroll, "item_f_time", working, "applyTime", KMS.ItemSchema)
            end
            local btnRow = ButtonRow(editorScroll)
            local save = RowButton(btnRow, L("btn_item_save"), "primary", false, Scale(220))
            save.DoClick = function()
                SendAction("save_item", { record = working })
            end
            if config.custom[id] then
                local del = RowButton(btnRow, L("btn_item_delete"), "danger", false, Scale(220))
                del.DoClick = function()
                    KMS.UI.Confirm(L("confirm_item_delete", KMS.ItemLabel(id)), function()
                        itemState.selected = nil
                        SendAction("delete_item", { id = id })
                    end)
                end
            end
        end
    end

    search.OnValueChange = function(_, value)
        RebuildList(KF.NormalizeQuery(value or ""))
    end
    RebuildList()
    RebuildEditor()
end

local SECTION_BUILDERS = {
    presets = BuildPresetsTab,
    general = BuildGeneralTab,
    models = BuildModelsTab,
    items = BuildItemsTab,
    vitals = BuildVitalsTab,
    treatments = BuildTreatmentsTab,
    access = BuildAccessTab,
    invgeneral = BuildInvGeneralTab,
    invgamemode = BuildInvGamemodeTab,
    invdeath = BuildInvDeathTab,
    npcs = BuildNPCsTab,
    vehicles = BuildVehiclesTab,
    stamina = BuildStaminaTab,
}

function KMS.OpenAdmin(toPresets)
    if not KMS.IsAdmin(LocalPlayer()) then
        KMS.PlaySound("Error")
        KF.Notifications.Show(L("err_admin_only"), "error", 4, AID)
        return
    end
    if IsValid(adminFrame) then adminFrame:Remove() end
    local frame = vgui.Create("KF.Frame")
    frame:SetAddon(AID)
    frame:SetSize(Scale(1300), Scale(860))
    frame:Center()
    frame:MakePopup()
    frame:SetFrameTitle(L("adm_title"))
    frame:SetSubtitle(L("ui_subtitle"))
    frame:SetHeaderHeight(52)
    adminFrame = frame

    frame.OnRemove = function()
        if adminFrame ~= frame then return end
        adminFrame = nil
        KMS.PlaySound("Close")
    end

    CloseButton(frame)

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body:DockMargin(Scale(12), Scale(60), Scale(12), Scale(12))
    body.Paint = nil

    local sidebar = vgui.Create("KF.ScrollPanel", body)
    sidebar:SetAddon(AID)
    sidebar:Dock(LEFT)
    sidebar:SetWide(Scale(230))

    local content = vgui.Create("DPanel", body)
    content:Dock(FILL)
    content:DockMargin(Scale(14), 0, 0, 0)
    content.Paint = function(_, w, h)
        KF.Draw.Panel(0, 0, w, h, { addonId = AID })
    end

    local activeSection = toPresets and "presets" or (KMS.UI.AdminSection or "presets")

    local function SwitchSection(key)
        activeSection = key
        KMS.UI.AdminSection = key
        table.Empty(refreshers)
        content:Clear()
        local builder = SECTION_BUILDERS[key]
        if key == "npcs" or key == "items" then
            if builder then builder(content) end
        else
            local scroll = Scroll(content)
            if builder then builder(scroll) end
        end
    end

    KF.Builders.SidebarNav()
        :SetAddon(AID)
        :SetGroups({
            {
                label = L("adm_group_setup"),
                items = {
                    { key = "presets", label = L("adm_sec_presets") },
                    { key = "general", label = L("adm_sec_general") },
                    { key = "access", label = L("adm_sec_access") },
                },
            },
            {
                label = L("adm_group_gameplay"),
                items = {
                    { key = "vitals", label = L("adm_sec_vitals") },
                    { key = "treatments", label = L("adm_sec_treatments") },
                    { key = "stamina", label = L("adm_sec_stamina") },
                },
            },
            {
                label = L("adm_group_inventory"),
                items = {
                    { key = "invgeneral", label = L("adm_sec_invgeneral") },
                    { key = "invgamemode", label = L("adm_sec_invgamemode") },
                    { key = "invdeath", label = L("adm_sec_invdeath") },
                },
            },
            {
                label = L("adm_group_supplies"),
                items = {
                    { key = "npcs", label = L("adm_sec_npcs") },
                    { key = "vehicles", label = L("adm_sec_vehicles") },
                    { key = "models", label = L("adm_sec_models") },
                    { key = "items", label = L("adm_sec_items") },
                },
            },
        })
        :SetActiveKey(activeSection)
        :SetSoundHover(KMS.Sounds.Hover)
        :SetSoundClick(KMS.Sounds.Click)
        :SetOnSelect(SwitchSection)
        :Build(sidebar)

    SwitchSection(activeSection)
    KMS.PlaySound("Open")

    hook.Add("KMS_ConfigUpdated", frame, function()
        if not IsValid(frame) then return end
        if activeSection == "presets" or activeSection == "npcs" or activeSection == "items" then
            SwitchSection(activeSection)
            return
        end
        if #pendingOrder > 0 then return end
        refreshing = true
        for _, refresher in ipairs(refreshers) do
            refresher()
        end
        refreshing = false
    end)
end

concommand.Add("kms_admin", function()
    net.Start("KMS_RequestSync")
    net.WriteBool(true)
    net.SendToServer()
end)

local simFrame

KF.Net.Receive("KMS_SimSetup", function()
    local ent = net.ReadEntity()
    if IsValid(ent) then KMS.OpenSimSetup(ent) end
end)

function KMS.OpenSimSetup(ent)
    if IsValid(simFrame) then simFrame:Remove() end
    local frame = vgui.Create("KF.Frame")
    frame:SetAddon(AID)
    frame:SetSize(Scale(780), Scale(560))
    frame:Center()
    frame:MakePopup()
    frame:SetFrameTitle(L("sim_title"))
    frame:SetSubtitle(L("ui_subtitle"))
    frame:SetHeaderHeight(52)
    simFrame = frame

    CloseButton(frame)

    frame.OnRemove = function()
        if simFrame ~= frame then return end
        simFrame = nil
        KMS.PlaySound("Close")
    end

    frame.KMSTerminal = ent

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body:DockMargin(Scale(14), Scale(60), Scale(14), Scale(14))
    body.Paint = nil

    local chosen = { model = nil, difficulty = "medium", timed = false }

    local footer = vgui.Create("DPanel", body)
    footer:Dock(BOTTOM)
    footer:SetTall(Scale(44))
    footer:DockMargin(0, Scale(10), 0, 0)
    footer.Paint = nil

    local start = Btn(footer, L("btn_sim_start"), "primary", true)
    start:Dock(RIGHT)
    start:SetWide(Scale(230))
    start.DoClick = function()
        if not chosen.model or not IsValid(ent) then return end
        net.Start("KMS_SimStart")
        net.WriteEntity(ent)
        net.WriteString(chosen.model)
        net.WriteString(chosen.difficulty)
        net.WriteBool(chosen.timed)
        net.SendToServer()
        frame:Remove()
    end

    local timed = HoverSound(vgui.Create("DButton", footer))
    timed:SetText("")
    timed:Dock(LEFT)
    timed:SetWide(Scale(260))
    timed:SetCursor("hand")
    timed.Paint = function(s, w, h)
        KF.Draw.Checkbox(0, (h - Scale(18)) / 2, Scale(18), KF.Anim.UpdateHoverLerp(s, 10), chosen.timed and 1 or 0, AID)
        draw.SimpleText(L("sim_timed"), F("body"), Scale(28), h / 2, C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    timed.DoClick = function()
        KMS.PlaySound("Click")
        chosen.timed = not chosen.timed
    end

    local diffRow = vgui.Create("DPanel", body)
    diffRow:Dock(BOTTOM)
    diffRow:SetTall(Scale(38))
    diffRow:DockMargin(0, Scale(10), 0, 0)
    diffRow.Paint = function(_, w, h)
        draw.SimpleText(L("sim_difficulty"), F("body"), 0, h / 2, C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    for i = #KMS.SimDifficulties, 1, -1 do
        local difficulty = KMS.SimDifficulties[i]
        local btn = Btn(diffRow, L("opt_diff_" .. difficulty))
        btn:Dock(RIGHT)
        btn:DockMargin(Scale(4), Scale(2), 0, Scale(2))
        btn:SetWide(Scale(104))
        btn.Think = function(s)
            s:SetSolid(chosen.difficulty == difficulty)
        end
        btn.DoClick = function()
            KMS.PlaySound("Click")
            chosen.difficulty = difficulty
        end
    end

    local right = vgui.Create("DPanel", body)
    right:Dock(RIGHT)
    right:SetWide(Scale(300))
    right:DockMargin(Scale(12), 0, 0, 0)
    right.Paint = function(_, w, h)
        KF.Draw.Panel(0, 0, w, h, { addonId = AID })
    end

    local preview = vgui.Create("DModelPanel", right)
    preview:Dock(FILL)
    preview:DockMargin(Scale(6), Scale(6), Scale(6), Scale(6))
    preview:SetFOV(38)
    preview.LayoutEntity = function(_, mdlEnt)
        mdlEnt:SetAngles(Angle(0, RealTime() * 40 % 360, 0))
    end

    local function SetModel(model)
        chosen.model = model
        preview:SetModel(model)
        local mdlEnt = preview:GetEntity()
        if not IsValid(mdlEnt) then return end
        local mn, mx = mdlEnt:GetRenderBounds()
        local size = math.max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z, 1)
        preview:SetCamPos(Vector(size * 1.2, size * 1.2, (mn.z + mx.z) * 0.6))
        preview:SetLookAt(Vector(0, 0, (mn.z + mx.z) * 0.5))
    end

    local left = vgui.Create("DPanel", body)
    left:Dock(FILL)
    left.Paint = nil

    local modelLabel = vgui.Create("DPanel", left)
    modelLabel:Dock(TOP)
    modelLabel:SetTall(Scale(24))
    modelLabel.Paint = function(_, w, h)
        draw.SimpleText(L("sim_model"), FB("small"), 0, h / 2, C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local search = vgui.Create("KF.TextInput", left)
    search:SetAddon(AID)
    search:SetPlaceholderText(L("search_placeholder"))
    search:SetUpdateOnType(true)
    search:Dock(TOP)
    search:SetTall(Scale(30))
    search:DockMargin(0, Scale(4), 0, Scale(6))

    local scroll = vgui.Create("KF.ScrollPanel", left)
    scroll:SetAddon(AID)
    scroll:Dock(FILL)

    local models = {}
    for name, model in pairs(player_manager.AllValidModels()) do
        models[#models + 1] = { label = name, model = model }
    end
    table.sort(models, function(a, b) return a.label < b.label end)

    local function Rebuild(filter)
        scroll:Clear()
        for _, entry in ipairs(models) do
            if filter == "" or KF.MatchesQuery(entry.label, filter) then
                local row = HoverSound(vgui.Create("DButton", scroll))
                row:SetText("")
                row:Dock(TOP)
                row:SetTall(Scale(26))
                row:DockMargin(0, 0, 0, Scale(2))
                row.Paint = function(s, w, h)
                    local selected = chosen.model == entry.model
                    RowBackground(s, w, h, selected)
                    draw.SimpleText(entry.label, F("small"), Scale(8), h / 2, selected and C("TextAccent") or C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                row.DoClick = function()
                    KMS.PlaySound("Hover")
                    SetModel(entry.model)
                end
            end
        end
    end
    search.OnValueChange = function(_, value)
        timer.Create("KMS_SimFilter", 0.15, 1, function()
            if IsValid(scroll) then Rebuild(KF.NormalizeQuery(value or "")) end
        end)
    end

    if models[1] then SetModel(models[1].model) end
    Rebuild("")
    KMS.PlaySound("Open")
end

hook.Add("Think", "KMS_SimValidate", function()
    if not IsValid(simFrame) then return end
    local ent = simFrame.KMSTerminal
    if not IsValid(ent) or LocalPlayer():GetPos():DistToSqr(ent:GetPos()) > KMS.InteractRangeSqr then
        simFrame:Remove()
    end
end)

local examFrame
local examBlockUntil = 0
local ANSWER_SETTLE = 0.25

function KMS.ShowExamQuestion(index, total, question, opts, seconds)
    if not IsValid(examFrame) then
        local frame = vgui.Create("KF.Frame")
        frame:SetAddon(AID)
        frame:SetSize(Scale(720), Scale(500))
        frame:Center()
        frame:MakePopup()
        frame:SetKeyboardInputEnabled(false)
        frame:SetFrameTitle(L("exam_title"))
        frame:SetSubtitle(L("ui_subtitle"))
        frame:SetHeaderHeight(52)
        examFrame = frame
        CloseButton(frame)
        frame.OnRemove = function()
            if examFrame ~= frame then return end
            examFrame = nil
            if not frame.KMSDone then
                examBlockUntil = CurTime() + 1
                net.Start("KMS_ExamAnswer")
                net.WriteUInt(frame.KMSIndex or 0, 5)
                net.WriteUInt(0, 3)
                net.SendToServer()
            end
        end
        local body = vgui.Create("DPanel", frame)
        body:Dock(FILL)
        body:DockMargin(Scale(26), Scale(64), Scale(26), Scale(20))
        body.Paint = nil
        frame.KMSBody = body
    end
    local frame = examFrame
    local body = frame.KMSBody
    body:Clear()
    frame.KMSDeadline = seconds > 0 and (CurTime() + seconds) or nil
    frame.KMSAnswered = false
    frame.KMSIndex = index
    frame.KMSReadyAt = CurTime() + ANSWER_SETTLE

    local lines = KF.WrapText(question, FB("body"), frame:GetWide() - Scale(52))
    local header = vgui.Create("DPanel", body)
    header:Dock(TOP)
    header:SetTall(Scale(46) + #lines * Scale(22))
    header:DockMargin(0, 0, 0, Scale(12))
    header.Paint = function(_, w, h)
        draw.SimpleText(L("exam_progress", index, total), FB("small"), 0, 0, C("TextAccent"))
        for i, line in ipairs(lines) do
            draw.SimpleText(line, FB("body"), 0, Scale(26) + (i - 1) * Scale(22), C("TextPrimary"))
        end
        if frame.KMSDeadline and not frame.KMSAnswered then
            local frac = math.Clamp((frame.KMSDeadline - CurTime()) / seconds, 0, 1)
            surface.SetDrawColor(C("PanelDark"))
            surface.DrawRect(0, h - Scale(8), w, Scale(6))
            surface.SetDrawColor(frac < 0.25 and C("Error") or C("Accent"))
            surface.DrawRect(0, h - Scale(8), w * frac, Scale(6))
        end
    end

    for i, opt in ipairs(opts) do
        local btn = Btn(body, opt)
        btn:Dock(TOP)
        btn:SetTall(Scale(42))
        btn:DockMargin(0, 0, 0, Scale(8))
        btn.DoClick = function()
            if frame.KMSAnswered or CurTime() < frame.KMSReadyAt then return end
            frame.KMSAnswered = true
            KMS.PlaySound("Click")
            net.Start("KMS_ExamAnswer")
            net.WriteUInt(index, 5)
            net.WriteUInt(i, 3)
            net.SendToServer()
        end
    end
end

KF.Net.Receive("KMS_ExamQ", function()
    local index = net.ReadUInt(5)
    if index == 0 then
        local passed = net.ReadBool()
        local pct = net.ReadUInt(7)
        local needed = net.ReadUInt(7)
        local reward = net.ReadString()
        if IsValid(examFrame) then
            examFrame.KMSDone = true
            examFrame:Remove()
        end
        if passed then
            KF.Notifications.Show(L("exam_result_pass", pct, KMS.TArg(reward)), "success", 6, AID)
        else
            KF.Notifications.Show(L("exam_result_fail", pct, needed), "error", 6, AID)
        end
        KMS.PlaySound(passed and "Click" or "Error")
        return
    end
    local total = net.ReadUInt(5)
    local qKey = net.ReadString()
    local args = {}
    for i = 1, net.ReadUInt(3) do
        args[i] = KMS.TArg(net.ReadString())
    end
    local opts = {}
    for i = 1, net.ReadUInt(3) do
        opts[i] = KMS.TArg(net.ReadString())
    end
    local seconds = net.ReadUInt(8)
    if CurTime() < examBlockUntil then return end
    KMS.ShowExamQuestion(index, total, L(qKey, unpack(args)), opts, seconds)
end)
