KrakensStore.Admin = KrakensStore.Admin or {}

local AID = KrakensStore.AID
local L = KrakensStore.L
local S, T = KF.Scale, KF.T
local function F(role) return KF.Fonts.Role(AID, role) end
local function C(key) return KF.UI.GetColor(key, AID) end

function KrakensStore.Net.AdminAction(action, data)
    KF.Net.Send("KrakensStore_AdminAction", function()
        net.WriteString(action)
        return KF.Net.WriteCompressed(data or {}, 32)
    end)
end

local AdminResponseSilentActions = {
    ["player_inventory"] = true,
    ["player_inventory_delta"] = true,
    ["watch_player_inventory"] = true,
    ["get_logs"] = true,
    ["set_stock"] = true,
}

KF.Net.Receive("KrakensStore_AdminResponse", function()
    local response = KF.Net.ReadCompressed(32, KrakensStore.Validation.Limits.MAX_DECOMPRESSED)
    hook.Run("KrakensStore_AdminResponse", response)

    if response and response.message and (not response.success or not AdminResponseSilentActions[response.action]) then
        local notifType = response.success and "success" or "error"
        KrakensStore.UI.ShowNotification(response.message, notifType)
    end
end)

function KrakensStore.Admin.SaveAction(btn, opts)
    local hookId = "KrakensStore_" .. opts.action .. "Response_" .. tostring(btn)
    local function ClearPending()
        hook.Remove("KrakensStore_AdminResponse", hookId)
        timer.Remove(hookId .. "_timeout")
    end

    btn.DoClick = function()
        if btn._saving then return end
        btn._saving = true
        btn:SetLabel(L("btn_saving"))

        local payload = opts.buildPayload()
        if not payload then
            btn._saving = false
            btn:SetLabel(opts.defaultLabel)
            return
        end
        local resolved = false

        ClearPending()
        hook.Add("KrakensStore_AdminResponse", hookId, function(response)
            if resolved then return end
            if not istable(response) or response.action ~= opts.action then return end
            resolved = true
            ClearPending()

            if IsValid(btn) then
                btn._saving = false
                btn:SetLabel(opts.defaultLabel)
            end

            if response.success == true and opts.onSuccess then opts.onSuccess(response) end
        end)

        timer.Create(hookId .. "_timeout", 8, 1, function()
            if resolved then return end
            resolved = true
            ClearPending()

            if IsValid(btn) then
                btn._saving = false
                btn:SetLabel(opts.defaultLabel)
            end

            KrakensStore.UI.ShowNotification(L("err_store_not_ready"), "error")
        end)

        KrakensStore.Net.AdminAction(opts.action, payload)
    end
end

local function WhitelistLabels()
    return {
        steamIds = L("ui_steam_ids"), usergroups = L("admin_usergroups"), jobs = L("admin_darkrp_jobs"), jobCategories = L("admin_darkrp_categories"),
        helixFactions = L("admin_helix_factions"), helixClasses = L("admin_helix_classes"), nutFactions = L("admin_nutscript_factions"), nutClasses = L("admin_nutscript_classes"),
    }
end

function KrakensStore.Admin.CreateEditorFrame(api, opts)
    if not IsValid(api.editor) then return nil end
    local entityName = opts.entityName or L("ui_unknown")
    local frame = KF.FormBuilder.Editor(api.editor, {
        addonId = AID,
        title = opts.isNew and L(opts.newHeaderKey or "admin_create_new_item") or (L("admin_edit_prefix") .. entityName),
        subtitle = (not opts.isNew and opts.entityId) and (L("admin_id_prefix") .. opts.entityId) or nil,
        showDelete = not opts.isNew,
        saveText = L("btn_save"), cancelText = L("btn_cancel"), deleteText = L("btn_delete"),
        onCancel = function() api.select(nil) end,
        onDelete = function()
            KrakensStore.Admin.ConfirmDelete({
                id = opts.entityId, name = entityName, action = opts.deleteAction,
                onSuccess = function()
                    api.refresh()
                    api.select(nil)
                end,
            })
        end,
    })
    local addWhitelist = frame.AddWhitelist
    local whitelistPanel, whitelistCheck
    function frame.AddWhitelist(entity)
        whitelistPanel, whitelistCheck = addWhitelist(entity.whitelist, {
            labels = WhitelistLabels(), toggleLabel = L("admin_requires_whitelist"), enabled = entity.requiresWhitelist == true,
        })
    end
    function frame.ReadWhitelist()
        if not whitelistCheck:GetChecked() then return false, {} end
        local whitelist = whitelistPanel:GetWhitelistData()
        if whitelist._invalidSteamIds then
            KrakensStore.UI.ShowNotification(L("admin_invalid_steamids") .. table.concat(whitelist._invalidSteamIds, ", "), "warning")
            whitelist._invalidSteamIds = nil
        end
        return true, whitelist
    end
    return frame
end

function KrakensStore.Admin.BuildManagedListTab(parent, cfg)
    return KF.Builders.MasterDetail(parent, {
        addonId = AID,
        title = L(cfg.titleKey),
        addLabel = L("btn_add"),
        searchPlaceholder = L(cfg.searchPlaceholderKey or "admin_search"),
        placeholder = L(cfg.editorPlaceholderKey),
        placeholderHint = L("admin_or_create_new"),
        emptyTitle = L(cfg.emptyKey),
        emptySearchTitle = L(cfg.emptySearchKey or "store_no_search_results"),
        emptyHint = L(cfg.emptyHintKey),
        editLabel = L("btn_edit"),
        deleteLabel = L("btn_delete"),
        sort = cfg.sort,
        fetch = cfg.fetch,
        iconOf = cfg.iconOf,
        drawRow = cfg.drawRow,
        openEditor = cfg.openEditor,
        extraMenu = cfg.extraMenuItems,
        confirmDelete = function(entry, api)
            KrakensStore.Admin.ConfirmDelete({
                titleKey = cfg.deleteDialogKey, id = entry.id, name = entry.name, action = cfg.deleteAction,
                onSuccess = function()
                    if api.selectedId == entry.id then api.select(nil) end
                    api.refresh()
                end,
            })
        end,
    })
end

local DELETED_EVENTS = {
    delete_item = "KrakensStore_ItemDefinitionDeleted",
    delete_category = "KrakensStore_CategoryDeleted",
    delete_npc = "KrakensStore_NPCDeleted",
}

function KrakensStore.Admin.ConfirmDelete(opts)
    local entityName = opts.name or opts.id or L("ui_unknown")
    KrakensStore.UI.ConfirmDialog(
        L(opts.titleKey or "dialog_confirm_delete"),
        L("dialog_delete_confirm") .. entityName .. L("dialog_delete_suffix"),
        L("btn_delete"), L("btn_cancel"),
        function()
            local event, hookId = DELETED_EVENTS[opts.action], "KrakensStore_Delete_" .. opts.id
            hook.Add(event, hookId, function(id)
                if id ~= opts.id then return end
                hook.Remove(event, hookId)
                opts.onSuccess()
            end)
            timer.Create(hookId .. "_expire", 10, 1, function() hook.Remove(event, hookId) end)
            KrakensStore.Net.AdminAction(opts.action, { id = opts.id })
        end, nil, true
    )
end

local ADMIN_SIDEBAR_GROUPS = {
    { labelKey = "admin_group_system", items = {
        { key = "settings", labelKey = "tab_settings", perm = "manage_config" },
        { key = "logs",     labelKey = "tab_logs",     perm = "view_logs" },
    }},
    { labelKey = "admin_group_content", items = {
        { key = "items",      labelKey = "tab_items",      perm = "manage_items" },
        { key = "categories", labelKey = "tab_categories", perm = "manage_categories" },
        { key = "npcs",       labelKey = "tab_npcs",       perm = "manage_npcs" },
    }},
    { labelKey = "admin_group_world", items = {
        { key = "spawn", labelKey = "tab_spawn", perm = "manage_config" },
    }},
    { labelKey = "admin_group_users", items = {
        { key = "players",   labelKey = "tab_players",   perm = "manage_players" },
        { key = "blacklist", labelKey = "tab_blacklist", perm = "manage_config" },
    }},
}

local function AllowedSidebarGroups()
    local ply = LocalPlayer()
    local allowed = {}
    for _, group in ipairs(ADMIN_SIDEBAR_GROUPS) do
        local items = {}
        for _, entry in ipairs(group.items) do
            if KrakensStore.HasActionPermission(ply, entry.perm) then
                items[#items + 1] = entry
            end
        end
        if #items > 0 then
            allowed[#allowed + 1] = { labelKey = group.labelKey, items = items }
        end
    end
    return allowed
end

local _adminActiveSection = "items"

function KrakensStore.UI.BuildAdminView(parent)
    KF.Net.Send("KrakensStore_RequestAdminData")

    if not KrakensStore._initialSyncReceived then
        KrakensStore.UI.BuildStatePanel(parent, KrakensStore.UI.BuildAdminView)
        return
    end

    local sidebarW = KF.Scale(220)
    local gap = KF.Scale(KF.FormBuilder.GetSpacing().SECTION_GAP)
    local pw, ph = parent:GetSize()

    local container = vgui.Create("DPanel", parent)
    container:SetPos(0, 0)
    container:SetSize(pw, ph)
    container.Paint = function() end

    local sidebar = vgui.Create("KF.ScrollPanel", container)
    sidebar:SetAddon(AID)
    sidebar:SetPos(0, 0)
    sidebar:SetSize(sidebarW, ph)
    sidebar.Paint = function(_, sw, sh)
        KF.Draw.Panel(0, 0, sw, sh, KrakensStore.UI.FLAT_PANEL)
        surface.SetDrawColor(C("Border"))
        surface.DrawRect(sw - 1, 0, 1, sh)
    end

    local contentX = sidebarW + gap
    local contentPanel = vgui.Create("DPanel", container)
    contentPanel:SetPos(contentX, 0)
    contentPanel:SetSize(pw - contentX, ph)
    contentPanel.Paint = function(_, cw, ch)
        KF.Draw.Panel(0, 0, cw, ch, KrakensStore.UI.FLAT_PANEL)
    end

    local tabBuilders = {
        items      = KrakensStore.Admin.BuildItemsTab,
        categories = KrakensStore.Admin.BuildCategoriesTab,
        npcs       = KrakensStore.Admin.BuildNPCsTab,
        players    = KrakensStore.Admin.BuildPlayersTab,
        spawn      = KrakensStore.Admin.BuildSpawnTab,
        blacklist  = KrakensStore.Admin.BuildBlacklistTab,
        logs       = KrakensStore.Admin.BuildLogsTab,
        settings   = KrakensStore.Admin.BuildSettingsTab,
    }

    local function SwitchSection(sectionId)
        _adminActiveSection = sectionId
        if not IsValid(contentPanel) then return end
        KrakensStore.UI.CloseAllPopups()
        contentPanel:Clear()
        local root = vgui.Create("Panel", contentPanel)
        root:SetSize(contentPanel:GetSize())
        tabBuilders[sectionId](root)
    end

    local allowedGroups = AllowedSidebarGroups()
    local navGroups = {}
    local allowedKeys = {}
    for _, group in ipairs(allowedGroups) do
        local items = {}
        for _, item in ipairs(group.items) do
            items[#items + 1] = { key = item.key, label = L(item.labelKey) }
            allowedKeys[item.key] = true
        end
        navGroups[#navGroups + 1] = { label = L(group.labelKey), items = items }
    end

    if KrakensStore.Admin.PendingEditItem then _adminActiveSection = "items" end
    if not allowedKeys[_adminActiveSection] then
        _adminActiveSection = navGroups[1] and navGroups[1].items[1] and navGroups[1].items[1].key
    end
    if _adminActiveSection ~= "items" then KrakensStore.Admin.PendingEditItem = nil end
    if not _adminActiveSection then return end

    KF.Builders.SidebarNav()
        :SetAddon(AID)
        :SetGroups(navGroups)
        :SetActiveKey(_adminActiveSection)
        :SetOnSelect(SwitchSection)
        :Build(sidebar)

    SwitchSection(_adminActiveSection)
end

local function SettingLabel(spec)
    if spec.labelKey then return L(spec.labelKey) end
    return L("setting_" .. spec.key)
end

function KrakensStore.Admin.BuildSettingsTab(parent)
    local Scale = KF.Scale
    local pad = T("SpaceXL")
    local contentW = math.min(parent:GetWide() - pad * 2 - T("ScrollGutter"), S(760))

    local scroll = vgui.Create("KF.ScrollPanel", parent)
    scroll:SetAddon(AID)
    scroll:Dock(FILL)
    scroll:DockMargin(pad, pad, pad, pad)

    local form = vgui.Create("DListLayout", scroll)
    form:SetSize(contentW, Scale(2400))
    scroll:AddItem(form)

    local fields = {}

    local function ValueOf(spec)
        local value = spec.get()
        if value == nil then value = spec.default end
        return value
    end

    local function AddControl(spec)
        local label = SettingLabel(spec)
        local value = ValueOf(spec)

        if spec.kind == "bool" then
            local row, cb = KF.FormBuilder.Checkbox(form, label, value == true, { addonId = AID, width = contentW })
            form:Add(row)
            fields[spec.key] = { control = cb, read = function() return cb:GetChecked() end }
            return
        end

        if spec.kind == "enum" then
            local choices = {}
            for code, name in pairs(spec.options()) do
                choices[#choices + 1] = { name = name, value = code }
            end
            table.sort(choices, function(a, b) return a.name < b.name end)
            local row, input = KF.FormBuilder.Dropdown(form, label, {
                addonId = AID, width = contentW, dropdownClass = "KF.PopupDropdown", choices = choices, value = value,
            })
            form:Add(row)
            fields[spec.key] = { control = input, read = function() return input:GetSelectedValue() end }
            return
        end

        if spec.kind == "model" then
            local lookSpec = spec.lookKey and KrakensStore.Config.SettingByKey[spec.lookKey]
            local look = lookSpec and ValueOf(lookSpec) or nil
            local picker = KF.FormBuilder.ModelPicker(form, label, {
                addonId = AID, width = contentW, value = value,
                skin = look and look.skin, bodygroups = look and look.bodygroups,
                skinLabel = L("admin_npc_skin"), missingText = L("admin_model_missing"), searchPlaceholder = L("admin_search_models"),
            })
            form:Add(picker)
            fields[spec.key] = { control = picker, read = picker.GetValue }
            if lookSpec then
                fields[spec.lookKey] = { control = picker, initial = look, compare = KF.Utils.LookKey, read = function()
                    local skin, bodygroups = picker.GetLook()
                    return { skin = skin, bodygroups = bodygroups }
                end }
            end
            return
        end

        if spec.kind == "list" then
            local row, input = KF.FormBuilder.TextField(form, label, {
                addonId = AID,
                value = table.concat(istable(value) and value or {}, ", "),
                placeholder = table.concat(spec.default, ", "),
                width = contentW,
            })
            form:Add(row)
            fields[spec.key] = { control = input, read = function()
                local out = {}
                for _, part in ipairs(string.Explode(",", input:GetValue() or "")) do
                    local clean = string.Trim(part)
                    if clean ~= "" then out[#out + 1] = clean end
                end
                return out
            end }
            return
        end

        local row, input = KF.FormBuilder.TextField(form, label, { addonId = AID, value = value, width = contentW })
        form:Add(row)
        fields[spec.key] = { control = input, read = function()
            local raw = input:GetValue()
            if spec.kind == "number" then return tonumber(raw) end
            return raw
        end }
    end

    local groups, groupByKey = {}, {}
    for _, spec in ipairs(KrakensStore.Config.SettingSpec) do
        if not spec.hidden and (not spec.integration or KrakensStore.Integrations.IsAvailable(spec.integration)) then
            local group = groupByKey[spec.group]
            if not group then
                group = { key = spec.group, specs = {} }
                groupByKey[spec.group] = group
                groups[#groups + 1] = group
            end
            group.specs[#group.specs + 1] = spec
        end
    end

    for _, group in ipairs(groups) do
        form:Add(KF.FormBuilder.SectionHeader(form, L(group.key), L(group.key .. "_desc"), { addonId = AID, width = contentW }))
        form:Add(KF.FormBuilder.Spacer(form, 6, contentW))
        for _, spec in ipairs(group.specs) do
            AddControl(spec)
            fields[spec.key].initial = fields[spec.key].read()
        end
        form:Add(KF.FormBuilder.Spacer(form, KF.FormBuilder.GetSpacing().SECTION_GAP, contentW))
    end

    local _, saveBtn = KF.FormBuilder.SaveRow(form, L("btn_save"), { addonId = AID, width = contentW })

    local function Changed(entry)
        local value = entry.read()
        if entry.compare then return entry.compare(value) ~= entry.compare(entry.initial), value end
        if istable(value) and istable(entry.initial) then return table.concat(value, ",") ~= table.concat(entry.initial, ","), value end
        return value ~= entry.initial, value
    end

    local savingUntil = 0

    KrakensStore.Admin.SaveAction(saveBtn, {
        action = "save_settings",
        defaultLabel = L("btn_save"),
        parent = parent,
        buildPayload = function()
            local payload = {}
            for key, entry in pairs(fields) do
                if IsValid(entry.control) then
                    local changed, value = Changed(entry)
                    if changed then payload[key] = value end
                end
            end
            if not next(payload) then return nil end
            savingUntil = RealTime() + 10
            return payload
        end,
    })

    hook.Add("KrakensStore_SettingsUpdated", parent, function()
        if RealTime() >= savingUntil then
            for _, entry in pairs(fields) do
                if IsValid(entry.control) and Changed(entry) then return end
            end
        end
        parent:Clear()
        KrakensStore.Admin.BuildSettingsTab(parent)
    end)
end

local LOG_HISTORY_MAX = 500

local _logEntries = {}
local _isWatching = false
local _logPanel   = nil
local _calendarPopup = nil

local function YmdToTimestamp(year, month, day, endOfDay)
    return os.time({
        year = year,
        month = month,
        day = day,
        hour = endOfDay and 23 or 0,
        min = endOfDay and 59 or 0,
        sec = endOfDay and 59 or 0,
    })
end

local function CloseCalendarPopup()
    if IsValid(_calendarPopup) then
        _calendarPopup:Remove()
    end
    _calendarPopup = nil
end

local function OpenCalendarPicker(anchor, selectedTs, onPick)
    CloseCalendarPopup()

    local popup = vgui.Create("DPanel")
    popup:SetSize(KF.Scale(310), KF.Scale(340))
    popup:DockPadding(T("SpaceXS"), T("SpaceXS"), T("SpaceXS"), T("SpaceXS"))
    KrakensStore.UI.TrackPopup(popup)
    popup:MakePopup()
    popup.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE then CloseCalendarPopup() end
    end
    popup.Paint = function(_, pw, ph)
        draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, pw, ph, C("PanelDark"))
        surface.SetDrawColor(C("Border"))
        surface.DrawOutlinedRect(0, 0, pw, ph, 1)
    end

    _calendarPopup = popup

    if IsValid(anchor) then
        local sx, sy = anchor:LocalToScreen(0, anchor:GetTall() + 4)
        local sw, sh = popup:GetSize()
        sx = math.Clamp(sx, 0, ScrW() - sw)
        sy = math.Clamp(sy, 0, ScrH() - sh)
        popup:SetPos(sx, sy)
    else
        popup:Center()
    end

    local selectedDate = os.date("*t", selectedTs or os.time())
    local viewYear = selectedDate.year
    local viewMonth = selectedDate.month
    local selectedKey = os.date("%Y-%m-%d", selectedTs or 0)

    local header = vgui.Create("DPanel", popup)
    header:Dock(TOP)
    header:SetTall(T("ButtonH"))
    header.Paint = function(_, hw, hh)
        draw.RoundedBoxEx(KF.UI.Tokens.Radius, 0, 0, hw, hh, C("PanelHover"), true, true, false, false)
    end

    local title = vgui.Create("DLabel", header)
    title:Dock(FILL)
    title:SetFont(F("PanelTitle"))
    title:SetTextColor(C("TextPrimary"))
    title:SetContentAlignment(5)

    local prev = KrakensStore.UI.Button(header)
    prev:Dock(LEFT)
    prev:DockMargin(S(3), S(3), 0, S(3))
    prev:SetWide(T("ButtonHSmall"))
    prev:SetAddon(AID)
    prev:SetLabel("<")

    local next = KrakensStore.UI.Button(header)
    next:Dock(RIGHT)
    next:DockMargin(0, S(3), S(3), S(3))
    next:SetWide(T("ButtonHSmall"))
    next:SetAddon(AID)
    next:SetLabel(">")

    local body = vgui.Create("DPanel", popup)
    body:Dock(FILL)
    body:DockMargin(T("SpaceS"), T("SpaceS"), T("SpaceS"), T("SpaceS"))
    body.Paint = function() end

    local weekdayNames = {
        L("logs_day_sun"),
        L("logs_day_mon"),
        L("logs_day_tue"),
        L("logs_day_wed"),
        L("logs_day_thu"),
        L("logs_day_fri"),
        L("logs_day_sat"),
    }

    local weekdayRow = vgui.Create("DPanel", body)
    weekdayRow:Dock(TOP)
    weekdayRow:SetTall(KF.Scale(18))
    weekdayRow.Paint = function() end

    local grid = vgui.Create("DPanel", body)
    grid:Dock(FILL)
    grid:DockMargin(0, KF.Scale(6), 0, 0)
    grid.Paint = function() end

    local footer = vgui.Create("DPanel", body)
    footer:Dock(BOTTOM)
    footer:SetTall(T("ButtonHSmall"))
    footer:DockMargin(0, KF.Scale(6), 0, 0)
    footer.Paint = function() end

    local todayBtn = KrakensStore.UI.Button(footer)
    todayBtn:SetAddon(AID)
    todayBtn:SetLabel(L("logs_date_today"))

    local clearBtn = KrakensStore.UI.Button(footer)
    clearBtn:SetAddon(AID)
    clearBtn:SetLabel(L("logs_date_clear"))

    local closeBtn = KrakensStore.UI.Button(footer)
    closeBtn:SetAddon(AID)
    closeBtn:SetLabel(L("logs_date_close"))

    local function LayoutFooterButtons()
        local fw, fh = footer:GetSize()
        local gap = T("SpaceS")
        local btnW = math.floor((fw - gap * 2) / 3)
        local btnH = T("ButtonHSmall")

        todayBtn:SetPos(0, 0)
        todayBtn:SetSize(btnW, btnH)

        clearBtn:SetPos(btnW + gap, 0)
        clearBtn:SetSize(btnW, btnH)

        closeBtn:SetPos(btnW * 2 + gap * 2, 0)
        closeBtn:SetSize(btnW, btnH)
    end

    local function RefreshMonth()
        if not IsValid(popup) then return end
        title:SetText(os.date("%B %Y", os.time({ year = viewYear, month = viewMonth, day = 1, hour = 12 })))

        local ww = weekdayRow:GetWide()
        local gw, gh = grid:GetSize()
        if ww <= 0 or gw <= 0 or gh <= 0 then
            timer.Simple(0, function()
                if IsValid(popup) then RefreshMonth() end
            end)
            return
        end

        LayoutFooterButtons()

        weekdayRow:Clear()
        local dayW = math.floor(ww / 7)
        for i = 1, 7 do
            local lbl = vgui.Create("DLabel", weekdayRow)
            lbl:SetPos((i - 1) * dayW, 0)
            lbl:SetSize(dayW, weekdayRow:GetTall())
            lbl:SetFont(F("Meta"))
            lbl:SetTextColor(C("TextMuted"))
            lbl:SetContentAlignment(5)
            lbl:SetText(weekdayNames[i])
        end

        grid:Clear()
        local cellW = math.floor(gw / 7)
        local cellH = math.floor(gh / 6)
        local firstWeekday = tonumber(os.date("%w", os.time({ year = viewYear, month = viewMonth, day = 1, hour = 12 }))) + 1
        local maxDay = tonumber(os.date("%d", os.time({ year = viewYear, month = viewMonth + 1, day = 0, hour = 12 })))

        local cPanel = C("Panel")
        local cAccent = C("Accent")
        local cHover = C("PanelHover")
        local cBg = C("Background")
        local cText = C("TextPrimary")

        for i = 1, 42 do
            local row = math.floor((i - 1) / 7)
            local col = (i - 1) % 7
            local day = i - firstWeekday + 1
            local valid = day >= 1 and day <= maxDay

            local btn = vgui.Create("DButton", grid)
            btn:SetPos(col * cellW, row * cellH)
            btn:SetSize(math.max(cellW - 2, 1), math.max(cellH - 2, 1))
            btn:SetText("")
            KF.Helpers.BindSounds(btn, AID)

            local dayKey = valid and string.format("%04d-%02d-%02d", viewYear, viewMonth, day) or ""
            local isSelected = valid and dayKey == selectedKey
            local dayStr = valid and tostring(day) or nil
            local dayColor = isSelected and cBg or cText
            local selectedBg = isSelected and cAccent or nil

            btn.Paint = function(s, bw, bh)
                local bg = cPanel
                if valid then
                    if selectedBg then bg = selectedBg
                    elseif s:IsHovered() then bg = cHover end
                end
                draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, bw, bh, bg)
                if dayStr then
                    draw.SimpleText(dayStr, F("Meta"), bw / 2, bh / 2,
                        dayColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            btn.DoClick = function()
                if not valid then return end
                selectedKey = dayKey
                if onPick then onPick(viewYear, viewMonth, day) end
                CloseCalendarPopup()
            end
        end
    end

    prev.DoClick = function()
        viewMonth = viewMonth - 1
        if viewMonth < 1 then
            viewMonth = 12
            viewYear = viewYear - 1
        end
        RefreshMonth()
    end

    next.DoClick = function()
        viewMonth = viewMonth + 1
        if viewMonth > 12 then
            viewMonth = 1
            viewYear = viewYear + 1
        end
        RefreshMonth()
    end

    todayBtn.DoClick = function()
        local now = os.date("*t", os.time())
        if onPick then onPick(now.year, now.month, now.day) end
        CloseCalendarPopup()
    end

    clearBtn.DoClick = function()
        if onPick then onPick(nil, nil, nil) end
        CloseCalendarPopup()
    end

    closeBtn.DoClick = CloseCalendarPopup
    popup.OnSizeChanged = RefreshMonth
    timer.Simple(0, function()
        if IsValid(popup) then RefreshMonth() end
    end)
end

local function IsAdminEntry(entry)
    return string.StartWith(entry.type or "", "admin_")
end

local function GetTypeLabel(logType)
    local key = "logs_type_" .. (logType or "unknown")
    local result = L(key)

    if result == "[" .. key .. "]" then return L("logs_type_unknown") end
    return result
end

local function GetTypeColor(entry)
    if IsAdminEntry(entry) then
        return C("Warning")
    end
    local t = entry.type
    if t == "purchase" or t == "sale" then
        return C("Success")
    end
    return C("Info")
end

local function FormatTime(ts)
    if not ts or ts == 0 then return "" end
    return os.date("%Y-%m-%d %H:%M:%S", ts)
end

local function ResolvePlayerName(entry)
    if entry.data and entry.data.playerName and entry.data.playerName ~= "" then
        return entry.data.playerName
    end
    local sid = entry.steamId
    if not sid or sid == "" then return "" end
    local ply = player.GetBySteamID64(sid)
    if IsValid(ply) then return ply:Nick() end
    return sid
end

local function BuildDescription(entry)
    local data = entry.data or {}
    local parts = {}

    local itemName = entry.itemName
    if not itemName or itemName == "" then itemName = data.itemName end
    if itemName and itemName ~= "" then parts[#parts + 1] = itemName end

    if data.categoryName and data.categoryName ~= "" then
        parts[#parts + 1] = data.categoryName
    end

    local price = data.price or data.refund or (entry.amount and entry.amount > 0 and entry.amount)
    if price and price ~= 0 then
        parts[#parts + 1] = KrakensStore.FormatMoney(price)
    end

    local qty = entry.quantity or data.quantity
    if qty and qty > 1 then parts[#parts + 1] = "x" .. qty end

    return table.concat(parts, " · ")
end

local function IsEntryInTypeGroup(entry, group)
    if group == "all" then return true end
    local t = entry.type
    if group == "trade" then
        return t == "purchase" or t == "sale"
    elseif group == "equipment" then
        return t == "equip" or t == "unequip" or t == "use_item"
    elseif group == "spawned_entities" then
        return t == "admin_create_npc"
    elseif group == "admin_changes" then
        return IsAdminEntry(entry)
    end
    return true
end

local function IsWithinDateRange(timestamp, dateRangeMode, customFromTs, customToTs)
    if dateRangeMode == "all" then return true end
    if not timestamp or timestamp <= 0 then return false end

    local now = os.time()
    local dt = os.date("*t", now)
    local startToday = os.time({ year = dt.year, month = dt.month, day = dt.day, hour = 0, min = 0, sec = 0 })

    if dateRangeMode == "today" then
        return timestamp >= startToday
    elseif dateRangeMode == "last7" then
        return timestamp >= (now - 7 * 24 * 60 * 60)
    elseif dateRangeMode == "last30" then
        return timestamp >= (now - 30 * 24 * 60 * 60)
    elseif dateRangeMode == "custom" then
        if customFromTs and timestamp < customFromTs then return false end
        if customToTs and timestamp > customToTs then return false end
        return customFromTs ~= nil or customToTs ~= nil
    end

    return true
end

local function BuildSearchHay(entry)
    return string.lower(
        (entry._playerName or "") .. " " ..
        (entry.type or "") .. " " ..
        (entry.steamId or "") .. " " ..
        (entry._desc or "")
    )
end

local function IndexEntries(entries)
    for _, entry in ipairs(entries) do
        if not entry._hay then
            entry._playerName = ResolvePlayerName(entry)
            entry._desc = BuildDescription(entry)
            entry._hay = BuildSearchHay(entry)
        end
    end
end

hook.Add("KrakensStore_AdminResponse", "KrakensStore_LogsResponse", function(response)
    if not response or response.action ~= "get_logs" then return end
    _isWatching = false
    if not (response.success and response.logs) then return end
    _logEntries = response.logs
    IndexEntries(_logEntries)
    if IsValid(_logPanel) and _logPanel._rebuildList then
        _logPanel._rebuildList()
    end
end)

local function RequestLogs()
    if _isWatching then return end
    _isWatching = true
    KrakensStore.Net.AdminAction("get_logs", { limit = LOG_HISTORY_MAX })
end

function KrakensStore.Admin.BuildLogsTab(parent)
    local w, h = parent:GetSize()
    local Scale = KF.Scale
    local padding = Scale(16)
    local contentW = w - padding * 2

    _isWatching = false
    _logPanel = parent

    local container = vgui.Create("DPanel", parent)
    container:SetPos(0, 0)
    container:SetSize(w, h)
    container.Paint = function(_, pw, ph) KF.Draw.Panel(0, 0, pw, ph, KrakensStore.UI.FLAT_PANEL) end

    local toolbar = vgui.Create("DPanel", container)
    toolbar:SetPos(padding, padding)
    toolbar:SetSize(contentW, T("TabItemH") + T("SpaceS") + T("InputH"))
    toolbar.Paint = function() end

    local filterMode = "all"
    local filterBtns = {}
    local typeGroupMode = "all"
    local sortMode = "recent"
    local dateRangeMode = "all"
    local customFromTs = nil
    local customToTs = nil
    local searchTerm = ""
    local rebuildList

    local filterNames = {
        { id = "all",    label = L("logs_filter_all") },
        { id = "admin",  label = L("logs_filter_admin") },
        { id = "player", label = L("logs_filter_player") },
    }

    local filterX = 0
    for _, f in ipairs(filterNames) do
        local btn = vgui.Create("KF.TabButton", toolbar)
        btn:SetAddon(AID)
        btn:SetFont(F("Value"))
        btn:SetLabel(f.label)
        btn:SetSize(math.max(btn:GetMinWidth(), S(80)), T("TabItemH"))
        btn:SetPos(filterX, 0)
        btn:SetActive(f.id == filterMode)
        filterBtns[f.id] = btn
        filterX = filterX + btn:GetWide() + T("SpaceXS")
    end

    local searchW = Scale(220)
    parent.OnRemove = function()
        CloseCalendarPopup()
        if _logPanel ~= parent then return end
        _logPanel = nil
        _isWatching = false
    end
    local searchBar = KrakensStore.UI.CreateSearchBar(toolbar, searchW, L("logs_search_placeholder"), function(val)
        searchTerm = string.lower(string.Trim(val or ""))
        rebuildList()
    end)
    searchBar:SetPos(contentW - searchW, math.floor((T("TabItemH") - searchBar:GetTall()) / 2))

    local statsLabel = vgui.Create("DLabel", toolbar)
    statsLabel:SetFont(F("Meta"))
    statsLabel:SetTextColor(C("TextMuted"))
    statsLabel:SetContentAlignment(6)
    statsLabel:SetSize(Scale(150), Scale(30))
    statsLabel:SetPos(contentW - searchW - Scale(160), Scale(4))

    local resetBtn = KrakensStore.UI.Button(toolbar, L("logs_reset_filters"))
    resetBtn:SizeToLabel(S(100))
    resetBtn:SetPos(math.max(0, math.min(filterX + T("SpaceS"), contentW - searchW - resetBtn:GetWide() - T("SpaceS"))), 0)

    local function CreateDropdown(parentPanel, x, y, dropW, options, defaultValue, onChanged)
        local combo = vgui.Create("KF.PopupDropdown", parentPanel)
        combo:SetPos(x, y)
        combo:SetSize(dropW, T("InputH"))
        combo:SetAddon(AID)

        for _, opt in ipairs(options) do
            combo:AddOption(opt.value, opt.label)
        end

        combo:SetValue(defaultValue)

        combo.OnSelect = function(_, _, _, data)
            onChanged(data)
        end

        return combo
    end

    local secondRowY = T("TabItemH") + T("SpaceS")
    local rowGap = Scale(8)
    local typeW = Scale(185)
    local sortW = Scale(150)
    local rangeW = Scale(165)

    local typeX = 0
    local sortX = typeX + typeW + rowGap
    local rangeX = sortX + sortW + rowGap
    local dateX = rangeX + rangeW + rowGap
    local dateBtnGap = Scale(8)
    local dateAreaW = math.max(contentW - dateX, Scale(180))
    local dateBtnW = math.max(math.floor((dateAreaW - dateBtnGap) / 2), Scale(86))

    local typeDropdown = CreateDropdown(toolbar, typeX, secondRowY, typeW, {
        { label = L("logs_type_filter_all"), value = "all" },
        { label = L("logs_type_filter_trade"), value = "trade" },
        { label = L("logs_type_filter_equipment"), value = "equipment" },
        { label = L("logs_type_filter_spawned_entities"), value = "spawned_entities" },
        { label = L("logs_type_filter_admin_changes"), value = "admin_changes" },
    }, typeGroupMode, function(value)
        typeGroupMode = value or "all"
        rebuildList()
    end)

    local sortDropdown = CreateDropdown(toolbar, sortX, secondRowY, sortW, {
        { label = L("logs_sort_recent"), value = "recent" },
        { label = L("logs_sort_oldest"), value = "oldest" },
    }, sortMode, function(value)
        sortMode = value or "recent"
        rebuildList()
    end)

    local rangeDropdown = CreateDropdown(toolbar, rangeX, secondRowY, rangeW, {
        { label = L("logs_date_range_all"), value = "all" },
        { label = L("logs_date_range_today"), value = "today" },
        { label = L("logs_date_range_last7"), value = "last7" },
        { label = L("logs_date_range_last30"), value = "last30" },
        { label = L("logs_date_range_custom"), value = "custom" },
    }, dateRangeMode, function(value)
        dateRangeMode = value or "all"
        rebuildList()
    end)

    local fromDateBtn = KrakensStore.UI.Button(toolbar)
    fromDateBtn:SetPos(dateX, secondRowY)
    fromDateBtn:SetSize(dateBtnW, T("InputH"))
    fromDateBtn:SetAddon(AID)

    local toDateBtn = KrakensStore.UI.Button(toolbar)
    toDateBtn:SetPos(dateX + dateBtnW + dateBtnGap, secondRowY)
    toDateBtn:SetSize(dateBtnW, T("InputH"))
    toDateBtn:SetAddon(AID)

    local function RefreshDateButtons()
        local fromPrefix = L("logs_date_from_short")
        local toPrefix = L("logs_date_to_short")

        if customFromTs then
            fromDateBtn:SetLabel(fromPrefix .. ": " .. os.date("%Y-%m-%d", customFromTs))
        else
            fromDateBtn:SetLabel(L("logs_date_from_placeholder"))
        end

        if customToTs then
            toDateBtn:SetLabel(toPrefix .. ": " .. os.date("%Y-%m-%d", customToTs))
        else
            toDateBtn:SetLabel(L("logs_date_to_placeholder"))
        end
    end

    local function SyncDateControlsVisibility()
        local showCustom = (dateRangeMode == "custom")
        fromDateBtn:SetVisible(showCustom)
        toDateBtn:SetVisible(showCustom)

        if not showCustom then
            customFromTs = nil
            customToTs = nil
            RefreshDateButtons()
        end
    end

    local function ApplyPickedDate(which, year, month, day)
        if not year or not month or not day then
            if which == "from" then
                customFromTs = nil
            else
                customToTs = nil
            end
        else
            if which == "from" then
                customFromTs = YmdToTimestamp(year, month, day, false)
            else
                customToTs = YmdToTimestamp(year, month, day, true)
            end
        end

        if customFromTs and customToTs and customFromTs > customToTs then
            customFromTs, customToTs = customToTs, customFromTs
        end

        RefreshDateButtons()
        rebuildList()
    end

    fromDateBtn.DoClick = function()
        OpenCalendarPicker(fromDateBtn, customFromTs, function(y, m, d)
            ApplyPickedDate("from", y, m, d)
        end)
    end

    toDateBtn.DoClick = function()
        OpenCalendarPicker(toDateBtn, customToTs, function(y, m, d)
            ApplyPickedDate("to", y, m, d)
        end)
    end

    local function ResetFilters()
        CloseCalendarPopup()

        filterMode = "all"
        typeGroupMode = "all"
        sortMode = "recent"
        dateRangeMode = "all"
        searchTerm = ""
        customFromTs = nil
        customToTs = nil

        if IsValid(searchBar) and searchBar.SetValue then
            searchBar:SetValue("")
        end

        for fid, btn in pairs(filterBtns) do
            btn:SetActive(fid == "all")
        end

        if IsValid(typeDropdown) and typeDropdown.SetValue then
            typeDropdown:SetValue("all")
        end
        if IsValid(sortDropdown) and sortDropdown.SetValue then
            sortDropdown:SetValue("recent")
        end
        if IsValid(rangeDropdown) and rangeDropdown.SetValue then
            rangeDropdown:SetValue("all")
        end

        RefreshDateButtons()
        SyncDateControlsVisibility()
        rebuildList()
    end

    resetBtn.DoClick = ResetFilters

    RefreshDateButtons()
    SyncDateControlsVisibility()

    local listTop = padding + toolbar:GetTall() + Scale(8)
    local scroll = vgui.Create("KF.ScrollPanel", container)
    scroll:SetAddon(AID)
    scroll:SetPos(padding, listTop)
    scroll:SetSize(contentW, h - listTop - padding)

    local listLayout = vgui.Create("DListLayout", scroll)
    listLayout:SetSize(contentW, 0)
    listLayout:SetPos(0, 0)
    listLayout.Paint = function() end

    local emptyLabel = vgui.Create("DPanel", container)
    emptyLabel:SetPos(padding, listTop)
    emptyLabel:SetSize(contentW, h - listTop - padding)
    emptyLabel:SetMouseInputEnabled(false)
    emptyLabel.Paint = function(s, ew, eh) KF.Draw.EmptyState(ew, eh, s._text or "", nil, { addonId = AID, showIcon = false }) end
    emptyLabel:SetVisible(false)

    rebuildList = function()
        if not IsValid(listLayout) then return end
        listLayout:Clear()
        local matched = 0
        local rowH = T("RowH")
        local avatarSize = S(32)
        local badgePadX = Scale(8)
        local textPadX = Scale(10)

        local entriesToRender = {}
        for _, entry in ipairs(_logEntries) do
            if filterMode == "admin" and not IsAdminEntry(entry) then continue end
            if filterMode == "player" and IsAdminEntry(entry) then continue end
            if not IsEntryInTypeGroup(entry, typeGroupMode) then continue end
            if not IsWithinDateRange(entry.timestamp, dateRangeMode, customFromTs, customToTs) then continue end

            if searchTerm ~= "" and not string.find(entry._hay or "", searchTerm, 1, true) then continue end

            entriesToRender[#entriesToRender + 1] = entry
        end

        table.sort(entriesToRender, function(a, b)
            local ta = a.timestamp or 0
            local tb = b.timestamp or 0

            if sortMode == "oldest" then
                if ta == tb then
                    return (a.id or 0) < (b.id or 0)
                end
                return ta < tb
            end

            if ta == tb then
                return (a.id or 0) > (b.id or 0)
            end
            return ta > tb
        end)

        for _, entry in ipairs(entriesToRender) do
            matched = matched + 1

            local row = vgui.Create("DPanel", listLayout)
            row:Dock(TOP)
            row:DockMargin(0, T("SpaceXS"), 0, 0)
            row:SetTall(rowH)

            local typeColor = GetTypeColor(entry)

            row.Paint = function(_, rw, rh)
                surface.SetDrawColor(C("CardBg"))
                surface.DrawRect(0, 0, rw, rh)

                surface.SetDrawColor(typeColor)
                surface.DrawRect(0, 0, Scale(3), rh)

                surface.SetDrawColor(C("CardBorder"))
                surface.DrawRect(0, rh - 1, rw, 1)
            end

            local avatarX = Scale(12)
            local avatarY = math.floor((rowH - avatarSize) / 2)

            if entry.steamId and entry.steamId ~= "" then
                local av = vgui.Create("AvatarImage", row)
                av:SetPos(avatarX, avatarY)
                av:SetSize(avatarSize, avatarSize)
                av:SetSteamID(entry.steamId, 32)
            else
                local sysIcon = vgui.Create("DPanel", row)
                sysIcon:SetPos(avatarX, avatarY)
                sysIcon:SetSize(avatarSize, avatarSize)
                sysIcon.Paint = function(_, iw, ih)
                    draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, iw, ih, C("PanelHover"))
                    draw.SimpleText("S", F("Value"),
                        iw / 2, ih / 2,
                        C("TextMuted"),
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            local textX = avatarX + avatarSize + textPadX
            local textW = contentW - textX - Scale(140)

            local typeLabel = GetTypeLabel(entry.type)
            local playerName = entry._playerName or ""
            local desc = entry._desc or ""
            local formattedTime = FormatTime(entry.timestamp)

            surface.SetFont(F("Value"))
            local cachedBadgeW = surface.GetTextSize(typeLabel) + badgePadX * 2

            local infoPanel = vgui.Create("DPanel", row)
            infoPanel:SetPos(textX, Scale(6))
            infoPanel:SetSize(textW, rowH - Scale(12))
            infoPanel.Paint = function(s, iw, ih)
                local sx, sy = s:LocalToScreen(0, 0)
                render.SetScissorRect(sx, sy, sx + iw, sy + ih, true)

                draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, cachedBadgeW, Scale(18), KF.UI.ColorAlpha(typeColor, 40))
                draw.SimpleText(typeLabel, F("Value"),
                    badgePadX, Scale(9),
                    typeColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                if playerName ~= "" then
                    draw.SimpleText(playerName, F("Value"),
                        cachedBadgeW + Scale(8), Scale(9),
                        C("TextPrimary"),
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                if desc ~= "" then
                    draw.SimpleText(desc, F("Meta"),
                        0, ih - Scale(4),
                        C("TextMuted"),
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
                end

                render.SetScissorRect(0, 0, 0, 0, false)
            end

            local tsPanel = vgui.Create("DPanel", row)
            tsPanel:SetPos(contentW - Scale(135), 0)
            tsPanel:SetSize(Scale(130), rowH)
            tsPanel.Paint = function(_, tw, th)
                draw.SimpleText(formattedTime, F("Meta"),
                    tw, th / 2,
                    C("TextMuted"),
                    TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end

        SyncDateControlsVisibility()
        statsLabel:SetText(string.format(L("logs_total"), matched))
        emptyLabel._text = #_logEntries == 0 and L("logs_loading") or L("logs_empty")
        emptyLabel:SetVisible(matched == 0)
        if matched == 0 then emptyLabel:MoveToFront() end
    end

    parent._rebuildList = rebuildList

    for _, f in ipairs(filterNames) do
        filterBtns[f.id].DoClick = function()
            filterMode = f.id
            for fid, btn in pairs(filterBtns) do
                btn:SetActive(fid == f.id)
            end
            rebuildList()
        end
    end

    rebuildList()

    RequestLogs()
end

function KrakensStore.Admin.BuildItemsTab(parent)
    local adminSortMode
    local api = KrakensStore.Admin.BuildManagedListTab(parent, {
        titleKey = "admin_all_items",
        editorPlaceholderKey = "admin_select_item_edit",
        emptyKey = "store_no_items_category",
        emptySearchKey = "store_no_search_results",
        emptyHintKey = "admin_or_create_new",
        deleteDialogKey = "dialog_delete_item",
        deleteAction = "delete_item",
        searchPlaceholderKey = "admin_search_items",
        sort = { options = KrakensStore.UI.SortOptions(), onChange = function(mode) adminSortMode = mode end },
        openEditor = KrakensStore.Admin.OpenItemEditor,
        fetch = function(query)
            local filtered = {}
            for _, item in pairs(KrakensStore.Items.GetAll()) do
                if KF.MatchesQuery(item.name, query) then filtered[#filtered + 1] = item end
            end
            KrakensStore.UI.SortItems(filtered, adminSortMode)
            return filtered
        end,
        iconOf = function(item) return (item.icon and item.icon ~= "") and item.icon or item.model end,
        drawRow = function(item, textX, rw, rh)
            local rowOff = S(8)
            draw.SimpleText(KF.TruncateText(item.name or L("ui_unknown"), F("Body"), rw - textX - S(30)), F("Body"), textX, rh / 2 - rowOff, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(KrakensStore.FormatMoney(item.price or 0), F("Meta"), textX, rh / 2 + rowOff, C("TextAccent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local dotSize = S(10)
            draw.RoundedBox(KF.UI.Tokens.Radius, rw - dotSize - S(5), rh / 2 - dotSize / 2, dotSize, dotSize, C(item.enabled ~= false and "Success" or "Error"))
        end,
        extraMenuItems = function(item, listApi)
            return { { text = L("btn_duplicate"), callback = function()
                local newItem = table.Copy(item)
                newItem.id = item.id .. "_copy"
                newItem.name = item.name .. L("admin_copy_suffix")
                KrakensStore.Admin.OpenItemEditor(newItem, listApi, true)
            end } }
        end,
    })
    hook.Add("KrakensStore_StoreDataUpdated", api.list, api.refresh)

    if KrakensStore.Admin.PendingEditItem then
        local pendingItem = KrakensStore.Admin.PendingEditItem
        KrakensStore.Admin.PendingEditItem = nil
        timer.Simple(0, function()
            if IsValid(parent) then api.select(pendingItem) end
        end)
    end
end

local function OptionalNumber(v, min)
    v = tonumber(v)
    return v and v >= min and tostring(v) or ""
end

function KrakensStore.Admin.OpenItemEditor(item, api, forceNew)
    local isNew = item == nil or forceNew == true
    item = item or KrakensStore.Schema.CreateItem({})

    local frame = KrakensStore.Admin.CreateEditorFrame(api, {
        isNew = isNew,
        entityName = item.name or L("ui_unknown"),
        entityId = item.id,
        deleteAction = "delete_item",
    })
    if not frame then return end

    local canvas, contentW = frame.canvas, frame.contentW
    local fields = {}
    local typeSpecificFields = {}
    local typeFieldsContainer

    local function GetFieldValue(field)
        if not IsValid(field) then return nil end
        if field.GetSelectedValue then return field:GetSelectedValue() end
        if field.GetChecked then return field:GetChecked() end
        if field.GetValue then return field:GetValue() end
        return nil
    end

    local function MakeAutoPopulateHandler(setting)
        if not setting.onChoose then return nil end
        return function(_, _, text, val)
            local result = setting.onChoose(nil, text, val or text, fields)
            if istable(result) then
                if result.name and IsValid(fields.name) then fields.name:SetValue(result.name) end
                if result.description and IsValid(fields.description) then fields.description:SetValue(result.description) end
                local display = result.model or result.icon
                if display and IsValid(fields._displayPath) then fields._displayPath:SetValue(display) end
            end
            if fields._updateStatsPreview then
                timer.Simple(0.05, function() if fields._updateStatsPreview then fields._updateStatsPreview() end end)
            end
        end
    end

    local function RebuildTypeFields(itemType)
        local preservedValues = {}
        for key, fieldData in pairs(typeSpecificFields) do preservedValues[key] = GetFieldValue(fieldData.input) end
        typeSpecificFields = {}
        typeFieldsContainer:Clear()
        local typeSettings = (itemType and itemType ~= "") and KrakensStore:GetTypeSettings(itemType) or {}
        local itemData = item.data or {}
        for _, setting in ipairs(typeSettings) do
            local value = preservedValues[setting.key]
            if value == nil then value = itemData[setting.key] end
            if value == nil then value = setting.default end
            local row, input
            if setting.type == "combo" then
                row, input = KF.FormBuilder.Dropdown(typeFieldsContainer, setting.name, { addonId = AID, width = contentW, dropdownClass = "KF.PopupDropdown" })
                input:SetSearchable(setting.searchable == true)
                input:SetSearchPlaceholder(L("ui_search_placeholder"))
                for _, opt in ipairs(setting.getOptions and setting.getOptions() or {}) do input:AddOption(opt.value, opt.name) end
                if value ~= nil then input:SetValue(value) end
                input.OnSelect = MakeAutoPopulateHandler(setting)
            else
                local isNumber = setting.type == "number"
                row, input = KF.FormBuilder.TextField(typeFieldsContainer, setting.name, {
                    addonId = AID, width = contentW, numeric = isNumber, halfWidth = isNumber,
                    value = tostring(value or (isNumber and 0 or "")), placeholder = setting.placeholder,
                })
            end
            if setting.desc and setting.desc ~= "" then KF.Tooltip.Set(input, setting.desc, { addon = AID }) end
            typeFieldsContainer:Add(row)
            typeSpecificFields[setting.key] = { input = input, setting = setting }
        end
        canvas:InvalidateLayout(true)
        timer.Simple(0.1, function() if fields._updateStatsPreview then fields._updateStatsPreview() end end)
    end

    frame.AddSection(L("admin_basic_info"))

    fields.id = frame.AddText(L("admin_item_id"), { value = item.id, placeholder = L("admin_item_id_placeholder"), required = true })
    if not isNew then fields.id:SetEnabled(false) end
    fields.name = frame.AddText(L("admin_name"), { value = item.name, placeholder = L("admin_name_placeholder"), required = true })
    fields.price = frame.AddText(L("admin_price"), { value = item.price, default = "1000", numeric = true, required = true })
    fields._displayPath = frame.AddText(L("admin_icon"), {
        value = (item.model and item.model ~= "") and item.model or (item.icon or ""),
        placeholder = L("admin_icon_placeholder"),
    })

    local categoryChoices = { { name = L("admin_none"), value = "" } }
    for _, cat in ipairs(KrakensStore.Categories.GetSorted()) do categoryChoices[#categoryChoices + 1] = { name = cat.name, value = cat.id } end
    fields.category = frame.AddDropdown(L("admin_category"), { value = item.category, choices = categoryChoices })
    fields.description = frame.AddTextarea(L("admin_description"), { value = item.description, height = 56 })

    frame.AddSection(L("admin_item_type"))

    local typeChoices = {}
    for id, typeData in pairs(KrakensStore.types or {}) do
        if id == item.type or KrakensStore:IsTypeAvailable(id) then
            typeChoices[#typeChoices + 1] = { name = typeData.name or id, value = id }
        end
    end
    table.sort(typeChoices, function(a, b) return a.name < b.name end)
    fields.type = frame.AddDropdown(L("admin_type"), { value = item.type, choices = typeChoices, required = true })

    typeFieldsContainer = vgui.Create("DListLayout")
    typeFieldsContainer:SetSize(contentW, 0)
    frame.Add(typeFieldsContainer)

    local statsPreviewContainer = vgui.Create("DPanel")
    statsPreviewContainer:SetSize(contentW, 0)
    statsPreviewContainer.Paint = KF.Helpers.NoPaint
    frame.Add(statsPreviewContainer)

    local function UpdateStatsPreview()
        if not IsValid(statsPreviewContainer) then return end
        statsPreviewContainer:Clear()
        local previewH = 0
        local kind, system = KrakensStore.Stats.ItemKind(GetFieldValue(fields.type))

        local function AddPreviewHeader(titleKey)
            local header = KF.FormBuilder.SectionHeader(statsPreviewContainer, L(titleKey), nil, { addonId = AID, width = contentW })
            header:SetPos(0, 0)
            return header:GetTall() + S(10)
        end

        if kind == "weapon" then
            local weaponClassField = typeSpecificFields.weaponClass
            local weaponClass = weaponClassField and GetFieldValue(weaponClassField.input)
            local stats = weaponClass and weaponClass ~= "" and KrakensStore.Stats.GetWeaponStatsByClass(weaponClass, system)
            if stats then
                previewH = AddPreviewHeader("stats_title")
                local rowH, gap = S(40), S(10)
                for _, bar in ipairs(KrakensStore.Stats.WeaponBars(stats)) do
                    local row = vgui.Create("DPanel", statsPreviewContainer)
                    row:SetPos(0, previewH)
                    row:SetSize(contentW, rowH)
                    row._fill = 0
                    row.Paint = function(s, rw, rh)
                        s._fill = KF.Anim.FastLerp(s._fill, bar.fill, 8, 0.002)
                        KF.Draw.StatRow(rw, rh, bar.label, bar.raw, s._fill, nil, AID)
                    end
                    previewH = previewH + rowH + gap
                end
                previewH = previewH + S(6)
            end
        elseif kind then
            local attachmentField = typeSpecificFields.attachmentId
            local attachmentId = attachmentField and GetFieldValue(attachmentField.input)
            local attData = attachmentId and attachmentId ~= "" and KrakensStore.Stats.GetAttachmentData(attachmentId, system)
            if attData and attData.props and #attData.props > 0 then
                previewH = AddPreviewHeader("stats_modifiers")
                local lineH = S(18)
                local lines = KrakensStore.Stats.AttachmentLines(attData)
                table.sort(lines, function(a, b)
                    local ra = a.buff == true and 1 or (a.buff == false and 2 or 3)
                    local rb = b.buff == true and 1 or (b.buff == false and 2 or 3)
                    return ra < rb
                end)
                local propsPanel = vgui.Create("DPanel", statsPreviewContainer)
                propsPanel:SetPos(0, previewH)
                propsPanel:SetSize(contentW, #lines * lineH)
                propsPanel.Paint = function(_, sw)
                    for i, line in ipairs(lines) do
                        local color = line.buff == true and C("Success") or (line.buff == false and C("Error") or C("TextMuted"))
                        draw.SimpleText(line.label, F("Meta"), sw / 2, (i - 1) * lineH, color, TEXT_ALIGN_CENTER)
                    end
                end
                previewH = previewH + #lines * lineH + S(6)
            end
        end

        statsPreviewContainer:SetTall(previewH)
        canvas:InvalidateLayout(true)
    end

    fields._updateStatsPreview = UpdateStatsPreview
    fields.type.OnSelect = function(_, _, _, val) RebuildTypeFields(val) end

    frame.AddSection(L("admin_duration"))
    fields.duration = frame.AddDropdown(L("admin_duration"), {
        value = item.duration or -1,
        halfWidth = true,
        choices = {
            { name = L("duration_permanent"), value = -1 },
            { name = L("duration_1_hour"), value = 3600 },
            { name = L("duration_1_day"), value = 86400 },
            { name = L("duration_1_week"), value = 604800 },
            { name = L("duration_1_month"), value = 2592000 },
        },
    })
    fields.refundPercent = frame.AddText(L("admin_refund_percent"), { value = OptionalNumber(item.refundPercent, 0), placeholder = L("admin_use_global"), numeric = true, halfWidth = true })
    fields.refundWindowHours = frame.AddText(L("admin_refund_window_hours"), { value = OptionalNumber(item.refundWindowHours, 0), placeholder = L("admin_refund_window_hours_desc"), numeric = true, halfWidth = true })
    fields.maxOwned = frame.AddText(L("admin_max_owned"), { value = OptionalNumber(item.maxOwned, 1), placeholder = L("admin_unlimited"), numeric = true, halfWidth = true })
    local initialStock = tonumber(item.stock) or -1
    fields.stock = frame.AddText(L("admin_stock"), { value = OptionalNumber(initialStock, 0), placeholder = L("admin_unlimited"), numeric = true, halfWidth = true })

    frame.AddSection(L("admin_flags_options"))
    fields.refundable = frame.AddCheckbox(L("admin_refundable"), item.refundable ~= false)
    fields.enabled = frame.AddCheckbox(L("admin_enabled"), item.enabled ~= false)

    frame.AddSection(L("admin_whitelist"))
    frame.AddWhitelist(item)

    timer.Simple(0.05, function()
        if IsValid(canvas) and item.type and item.type ~= "" then RebuildTypeFields(item.type) end
    end)

    local savedId, pendingStock

    KrakensStore.Admin.SaveAction(frame.saveBtn, {
        action = isNew and "create_item" or "update_item",
        defaultLabel = L("btn_save"),
        onSuccess = function()
            api.refresh()
            if pendingStock ~= nil then
                KrakensStore.Net.AdminAction("set_stock", { id = savedId, stock = pendingStock })
            end
            if isNew then
                local saved = KrakensStore.Items.Get(savedId)
                if saved then api.select(saved) end
            end
        end,
        buildPayload = function()
            local newItem = table.Copy(item)
            for key, field in pairs(fields) do
                if not string.StartWith(key, "_") then
                    local val = GetFieldValue(field)
                    if key == "price" then
                        val = tonumber(val) or 0
                    elseif key == "duration" then
                        val = tonumber(val) or -1
                    elseif key == "refundPercent" then
                        val = tonumber(val)
                        val = val and math.Clamp(val, 0, 100) or -1
                    elseif key == "refundWindowHours" then
                        val = tonumber(val)
                        val = val and math.max(0, val) or -1
                    elseif key == "maxOwned" then
                        val = math.max(0, tonumber(val) or 0)
                    elseif key == "stock" then
                        val = tonumber(val) or -1
                    end
                    newItem[key] = val
                end
            end
            if newItem.category == "" then newItem.category = nil end

            local displayPath = string.Trim(GetFieldValue(fields._displayPath) or "")
            newItem.icon, newItem.model = nil, nil
            if displayPath ~= "" then
                if KF.Materials.IsModelPath(displayPath) then newItem.model = displayPath else newItem.icon = displayPath end
            end

            local previousData = newItem.data or {}
            newItem.data = {}
            for _, setting in ipairs(KrakensStore:GetTypeSettings(newItem.type) or {}) do
                local meta = typeSpecificFields[setting.key]
                local val = meta and GetFieldValue(meta.input)
                if setting.type == "number" then val = tonumber(val) end
                if val == nil or val == "" then val = previousData[setting.key] end
                if val ~= nil then newItem.data[setting.key] = val end
            end

            if isstring(newItem.type) and string.StartWith(string.lower(newItem.type), "vehicle_")
                and isstring(newItem.model) and newItem.model ~= "" then
                newItem.icon = nil
            end

            newItem.requiresWhitelist, newItem.whitelist = frame.ReadWhitelist()

            local baseValid, baseErrors = KrakensStore.Schema.ValidateItem(newItem)
            if not baseValid then
                KrakensStore.UI.ShowNotification(baseErrors[1].message or L("err_invalid_item_data"), "error")
                return nil
            end
            local typeValid, typeErr = KrakensStore:ValidateTypeSettings(newItem.type, newItem.data)
            if not typeValid then
                KrakensStore.UI.ShowNotification(typeErr or L("err_invalid_item_data"), "error")
                return nil
            end

            savedId = newItem.id
            pendingStock = (not isNew and newItem.stock ~= initialStock) and newItem.stock or nil
            return newItem
        end,
    })
end

function KrakensStore.Admin.BuildCategoriesTab(parent)
    local api = KrakensStore.Admin.BuildManagedListTab(parent, {
        titleKey = "admin_categories_title",
        editorPlaceholderKey = "admin_select_category_edit",
        emptyKey = "admin_no_categories",
        emptyHintKey = "admin_create_category_hint",
        deleteDialogKey = "dialog_delete_category",
        deleteAction = "delete_category",
        openEditor = KrakensStore.Admin.OpenCategoryEditor,
        fetch = function(query)
            local out = {}
            for _, cat in ipairs(KrakensStore.Categories.GetSorted()) do
                if KF.MatchesQuery((cat.name or "") .. " " .. cat.id, query) then out[#out + 1] = cat end
            end
            return out
        end,
        iconOf = function(cat) return cat.icon end,
        drawRow = function(cat, textX, rw, rh)
            draw.SimpleText(KF.TruncateText(cat.name or cat.id, F("Body"), rw - textX - S(30)), F("Body"), textX, rh / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if cat.order and cat.order > 0 then
                draw.SimpleText("#" .. cat.order, F("Tiny"), rw - S(10), rh / 2, C("TextMuted"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end,
    })
    hook.Add("KrakensStore_StoreDataUpdated", api.list, api.refresh)
end

function KrakensStore.Admin.OpenCategoryEditor(category, api)
    local isNew = category == nil
    category = category or { id = "", name = "", icon = "", order = 0, requiresWhitelist = false }
    local originalId = category.id

    local frame = KrakensStore.Admin.CreateEditorFrame(api, {
        isNew = isNew,
        newHeaderKey = "admin_create_new_category",
        entityName = category.name or L("ui_unknown"),
        entityId = category.id,
        deleteAction = "delete_category",
    })
    if not frame then return end

    local fields = {}
    frame.AddSection(L("admin_basic_info"))
    fields.id = frame.AddText(L("admin_category_id"), { value = category.id, placeholder = L("admin_category_id_placeholder"), required = true })
    fields.name = frame.AddText(L("admin_display_name"), { value = category.name, placeholder = L("admin_category_name_placeholder"), required = true })
    fields.order = frame.AddText(L("admin_sort_order"), { value = category.order or 0, placeholder = "0", numeric = true, halfWidth = true })
    frame.Note(L("admin_sort_order_hint"))
    fields.icon = frame.AddText(L("admin_icon_path"), { value = category.icon, placeholder = L("admin_icon_placeholder") })

    frame.AddSection(L("admin_whitelist"), L("admin_whitelist_config_desc"))
    frame.AddWhitelist(category)

    frame.AddSection(L("admin_description"))
    fields.description = frame.AddTextarea(L("admin_description"), { value = category.description or "", height = 80 })

    local savedId

    KrakensStore.Admin.SaveAction(frame.saveBtn, {
        action = isNew and "create_category" or "update_category",
        defaultLabel = L("btn_save"),
        onSuccess = function()
            api.refresh()
            if isNew or savedId ~= originalId then
                local saved = KrakensStore.Categories.Get(savedId)
                if saved then api.select(saved) end
            end
        end,
        buildPayload = function()
            local requiresWhitelist, whitelist = frame.ReadWhitelist()
            local newCat = {
                id = fields.id:GetValue() or "",
                name = fields.name:GetValue() or "",
                icon = fields.icon:GetValue() or "",
                order = tonumber(fields.order:GetValue()) or 0,
                requiresWhitelist = requiresWhitelist,
                whitelist = whitelist,
                description = fields.description:GetValue() or "",
            }
            if not isNew then newCat.oldId = originalId end
            local _, err = KrakensStore.Validation.CategoryData(newCat)
            if err then
                KrakensStore.UI.ShowNotification(err, "error")
                return nil
            end
            savedId = newCat.id
            return newCat
        end,
    })
end

function KrakensStore.Admin.BuildNPCsTab(parent)
    local api = KrakensStore.Admin.BuildManagedListTab(parent, {
        titleKey = "admin_npcs_title",
        editorPlaceholderKey = "admin_select_npc_edit",
        emptyKey = "admin_no_npcs",
        emptyHintKey = "admin_create_npc_hint",
        deleteDialogKey = "dialog_delete_npc",
        deleteAction = "delete_npc",
        openEditor = KrakensStore.Admin.OpenNPCEditor,
        fetch = function(query)
            local out = {}
            for _, npc in ipairs(KrakensStore.NPCs.GetList()) do
                if KF.MatchesQuery((npc.name or "") .. " " .. npc.id, query) then out[#out + 1] = npc end
            end
            return out
        end,
        iconOf = function(npc) return npc.model end,
        drawRow = function(npc, textX, rw, rh)
            local infoStr = string.format("%d %s, %d %s", table.Count(npc.categories or {}), L("admin_categories_short"), table.Count(npc.items or {}), L("admin_items_short"))
            local rowOff = S(8)
            draw.SimpleText(KF.TruncateText(npc.name or npc.id, F("Body"), rw - textX - S(15)), F("Body"), textX, rh / 2 - rowOff, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(infoStr, F("Meta"), textX, rh / 2 + rowOff, C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end,
    })
    hook.Add("KrakensStore_NPCUpdated", api.list, api.refresh)
    hook.Add("KrakensStore_NPCDeleted", api.list, api.refresh)
end

function KrakensStore.Admin.OpenNPCEditor(npc, api)
    local isNew = npc == nil
    npc = npc or KrakensStore.NPCs.CreateNPC({})

    local frame = KrakensStore.Admin.CreateEditorFrame(api, {
        isNew = isNew,
        newHeaderKey = "admin_create_new_npc",
        entityName = npc.name or L("ui_unknown"),
        entityId = npc.id,
        deleteAction = "delete_npc",
    })
    if not frame then return end

    local contentW = frame.contentW
    local fields = {}

    frame.AddSection(L("admin_basic_info"))
    fields.id = frame.AddText(L("admin_npc_id"), { value = npc.id, placeholder = L("admin_npc_id_placeholder"), required = true })
    if not isNew then fields.id:SetEnabled(false) end
    fields.name = frame.AddText(L("admin_display_name"), { value = npc.name, placeholder = L("admin_npc_name_placeholder"), required = true })
    fields.model = KF.FormBuilder.ModelPicker(frame.canvas, L("admin_npc_model"), {
        addonId = AID, width = contentW, value = npc.model or KrakensStore.Config.Entities.NPC.Model,
        skin = npc.skin, bodygroups = npc.bodygroups, skinLabel = L("admin_npc_skin"),
        missingText = L("admin_model_missing"), searchPlaceholder = L("admin_search_models"),
    })
    frame.Add(fields.model)
    fields.floatingText = frame.AddText(L("admin_npc_floating_text"), { value = npc.floatingText, placeholder = L("admin_npc_floating_placeholder") })
    fields.idleAnim = frame.AddText(L("admin_npc_idle_anim"), { value = npc.idleAnim, placeholder = L("admin_npc_idle_anim_placeholder") })
    frame.Note(L("admin_npc_idle_anim_desc"))

    frame.AddSection(L("admin_npc_assignment"), L("admin_npc_assignment_desc"))

    local selectedCategories = table.Copy(npc.categories or {})
    local selectedItems = table.Copy(npc.items or {})
    local expandedCategories = {}

    local searchInput = frame.AddText(L("admin_search"), { placeholder = L("admin_search_items_categories") })

    local assignContainer = KF.FormBuilder.GroupContainer(frame.canvas, 250, { addonId = AID, width = contentW })
    frame.Add(assignContainer)

    local assignScroll = vgui.Create("KF.ScrollPanel", assignContainer)
    assignScroll:SetAddon(AID)
    assignScroll:Dock(FILL)
    assignScroll:DockMargin(T("SpaceS"), T("SpaceS"), T("SpaceS"), T("SpaceS"))

    local assignList = vgui.Create("DListLayout", assignScroll)
    assignList:Dock(TOP)

    local function AssignCheckbox(parentPanel, rowH, checked, onChange)
        local cb = vgui.Create("KF.Checkbox", parentPanel)
        cb:SetAddon(AID)
        cb:SetPos(0, 0)
        cb:SetSize(rowH, rowH)
        cb:SetLabel("")
        cb:SetChecked(checked)
        cb.OnChange = function(_, val) onChange(val or nil) end
        return cb
    end

    local function RefreshAssignList(query)
        assignList:Clear()
        query = KF.NormalizeQuery(query or "")
        local items = KrakensStore.Items.GetAll()
        local rowH = T("ButtonHSmall")
        local innerW = contentW - T("SpaceS") * 2 - T("ScrollGutter")

        for _, cat in ipairs(KrakensStore.Categories.GetSorted()) do
            local catMatches = query == "" or KF.MatchesQuery(cat.name or cat.id, query)
            local itemsInCat, hasMatchingItem = {}, false
            for _, item in pairs(items) do
                if item.category == cat.id then
                    itemsInCat[#itemsInCat + 1] = item
                    if query == "" or KF.MatchesQuery(item.name or item.id, query) then hasMatchingItem = true end
                end
            end

            if catMatches or hasMatchingItem then
                local catRow = vgui.Create("DPanel")
                catRow:SetSize(innerW, rowH)
                if expandedCategories[cat.id] == nil then expandedCategories[cat.id] = true end
                catRow.Paint = function(_, rw, rh) draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, rw, rh, C("PanelLight")) end
                AssignCheckbox(catRow, rowH, selectedCategories[cat.id] == true, function(val) selectedCategories[cat.id] = val end)
                local expandBtn = vgui.Create("DButton", catRow)
                expandBtn:SetPos(rowH, 0)
                expandBtn:SetSize(rowH, rowH)
                expandBtn:SetText("")
                KF.Helpers.BindSounds(expandBtn, AID)
                expandBtn.Paint = function(_, bw, bh)
                    draw.SimpleText(expandedCategories[cat.id] and "-" or "+", F("PanelTitle"), bw / 2, bh / 2, C("TextSecondary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                local catLabel = vgui.Create("DPanel", catRow)
                catLabel:SetPos(rowH * 2, 0)
                catLabel:SetSize(innerW - rowH * 2, rowH)
                catLabel.Paint = function(_, lw, lh)
                    draw.SimpleText(KF.TruncateText(cat.name or cat.id, F("PanelTitle"), lw - S(8)), F("PanelTitle"), 0, lh / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                assignList:Add(catRow)

                table.sort(itemsInCat, function(a, b) return (a.name or "") < (b.name or "") end)
                local itemsContainer = vgui.Create("DPanel")
                itemsContainer.Paint = KF.Helpers.NoPaint
                local yOffset = 0
                local indent = T("SpaceXL")
                for _, item in ipairs(itemsInCat) do
                    if query == "" or KF.MatchesQuery(item.name or item.id, query) then
                        local itemRow = vgui.Create("DPanel", itemsContainer)
                        itemRow:SetPos(indent, yOffset)
                        itemRow:SetSize(innerW - indent, rowH)
                        itemRow.Paint = function(s, iw, ih)
                            if s:IsHovered() then draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, iw, ih, C("PanelHover")) end
                            draw.SimpleText(KF.TruncateText(item.name or item.id, F("Meta"), iw - rowH - S(8)), F("Meta"), rowH, ih / 2, C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        end
                        AssignCheckbox(itemRow, rowH, selectedItems[item.id] == true, function(val) selectedItems[item.id] = val end)
                        yOffset = yOffset + rowH + T("SpaceXS")
                    end
                end
                itemsContainer:SetSize(innerW, yOffset)
                itemsContainer:SetVisible(expandedCategories[cat.id])
                assignList:Add(itemsContainer)

                expandBtn.DoClick = function()
                    expandedCategories[cat.id] = not expandedCategories[cat.id]
                    itemsContainer:SetVisible(expandedCategories[cat.id])
                    if expandedCategories[cat.id] then itemsContainer:SetSize(innerW, yOffset) end
                    assignList:InvalidateLayout(true)
                end

                local spacer = vgui.Create("DPanel")
                spacer:SetSize(innerW, T("SpaceXS"))
                spacer.Paint = KF.Helpers.NoPaint
                assignList:Add(spacer)
            end
        end
    end

    RefreshAssignList("")

    local searchTimer = "KrakensStore_NPCAssignSearch_" .. tostring(assignList)
    searchInput.OnChange = function(self)
        local query = self:GetValue()
        timer.Create(searchTimer, 0.25, 1, function()
            if IsValid(assignList) then RefreshAssignList(query) end
        end)
    end

    frame.AddSection(L("admin_whitelist"), L("admin_npc_whitelist_desc"))
    frame.AddWhitelist(npc)

    frame.AddSection(L("npc_placement_title"))

    local isPlaced = not isNew and npc.spawnPos ~= nil and npc.spawnMap ~= nil
    local statusText = isPlaced and (L("npc_currently_placed") .. " (" .. (npc.spawnMap or "") .. ")") or L("npc_not_placed")
    frame.Note(statusText)

    local placeBtnRow = vgui.Create("DPanel")
    placeBtnRow:SetSize(contentW, T("ButtonH"))
    placeBtnRow.Paint = KF.Helpers.NoPaint
    frame.Add(placeBtnRow)

    local placeBtn = KrakensStore.UI.Button(placeBtnRow, L("npc_place_in_world"))
    placeBtn:SizeToLabel(S(100))
    placeBtn.DoClick = function()
        if isNew then
            KrakensStore.UI.ShowNotification(L("npc_save_before_place"), "error")
            return
        end
        KrakensStore.NPCPlacement.Start(npc.id, fields.model.GetValue(), fields.model.GetLook())
    end

    if isPlaced then
        local removeBtn = KrakensStore.UI.Button(placeBtnRow, L("npc_remove_from_world"), "danger")
        removeBtn:SizeToLabel(S(100))
        removeBtn:SetPos(placeBtn:GetWide() + T("SpaceS"), 0)
        removeBtn.DoClick = function()
            KF.Net.Send("KrakensStore_NPCPlacement", function()
                net.WriteString(npc.id)
                net.WriteBool(false)
            end)
            api.select(nil)
        end
    end

    local savedId

    KrakensStore.Admin.SaveAction(frame.saveBtn, {
        action = isNew and "create_npc" or "update_npc",
        defaultLabel = L("btn_save"),
        onSuccess = function()
            api.refresh()
            if isNew then
                local saved = KrakensStore.NPCs.Get(savedId)
                if saved then api.select(saved) end
            end
        end,
        buildPayload = function()
            local requiresWhitelist, whitelist = frame.ReadWhitelist()
            local idleAnimVal = fields.idleAnim:GetValue() or ""
            local npcData = {
                id = fields.id:GetValue() or "",
                name = fields.name:GetValue() or "",
                model = fields.model.GetValue(),
                floatingText = fields.floatingText:GetValue() or "",
                idleAnim = idleAnimVal ~= "" and idleAnimVal or nil,
                categories = selectedCategories,
                items = selectedItems,
                requiresWhitelist = requiresWhitelist,
                whitelist = whitelist,
            }
            npcData.skin, npcData.bodygroups = fields.model.GetLook()
            if not fields.model.IsModelValid() then
                KrakensStore.UI.ShowNotification(L("err_npc_model_required"), "error")
                return nil
            end
            local _, err = KrakensStore.Validation.NPCData(npcData)
            if err then
                KrakensStore.UI.ShowNotification(err, "error")
                return nil
            end
            savedId = npcData.id
            return npcData
        end,
    })
end

KrakensStore.AdminPlayerInventories = KrakensStore.AdminPlayerInventories or {}

local function CalculateGridLayout(availW)
    local cols = math.max(3, math.floor(availW / KF.Scale(85)))
    return cols, math.floor(availW / cols)
end

local function ToggleCardSelection(cards, card, id, current)
    for _, other in pairs(cards) do
        if IsValid(other) then other._selected = false end
    end
    if current == id then return nil end
    card._selected = true
    return id
end

function KrakensStore.Admin.BuildPlayersTab(parent)
    local w, h = parent:GetSize()
    parent.Paint = function(_, pw, ph) draw.RoundedBox(0, 0, 0, pw, ph, C("Background")) end
    local padding = T("SpaceL")
    local separatorW = T("SpaceM")

    local leftW = math.floor((w - separatorW) * 0.5)
    local rightW = w - leftW - separatorW

    local selectedPlayer = nil
    local watchedSteamId = nil
    local selectedGiveItem = nil
    local selectedTakeItem = nil
    local playerInventory = {}
    local currentPage = 1
    local totalPages = 1
    local RebuildAvailableItems

    local leftPanel = vgui.Create("DPanel", parent)
    leftPanel:SetPos(0, 0)
    leftPanel:SetSize(leftW, h)
    leftPanel.Paint = function(self, pw, ph)
        KF.Draw.Panel(0, 0, pw, ph, KrakensStore.UI.FLAT_PANEL)
    end

    local playerSectionH = KF.Scale(200)

    local playerHeader = KF.FormBuilder.SectionHeader(leftPanel, L("admin_select_player"), nil, { addonId = AID, width = leftW - padding * 2 })
    playerHeader:SetPos(padding, padding)
    playerHeader:SetTall(KF.Scale(30))

    local playerScroll = vgui.Create("KF.ScrollPanel", leftPanel)
    playerScroll:SetAddon(AID)
    playerScroll:SetPos(padding, padding + KF.Scale(40))
    playerScroll:SetSize(leftW - padding * 2, playerSectionH - KF.Scale(50))

    local playerList = vgui.Create("DIconLayout", playerScroll)
    playerList:SetSize(leftW - padding * 2 - T("ScrollGutter"), playerSectionH)
    playerList:SetSpaceY(T("SpaceXS"))

    local itemsSectionTop = playerSectionH + padding

    local itemsHeader = KF.FormBuilder.SectionHeader(leftPanel, L("admin_available_items"), nil, { addonId = AID, width = leftW - padding * 2 })
    itemsHeader:SetPos(padding, itemsSectionTop)
    itemsHeader:SetTall(KF.Scale(30))

    local playersSortMode
    local itemSearchBar

    local playersSortDropdown = KrakensStore.UI.CreateSortDropdown(leftPanel, function(mode)
        playersSortMode = mode
        RebuildAvailableItems(IsValid(itemSearchBar) and itemSearchBar:GetValue() or "")
    end)
    playersSortDropdown:SetPos(leftW - padding - KF.Scale(90) - playersSortDropdown:GetWide(), itemsSectionTop + KF.Scale(40))

    itemSearchBar = KrakensStore.UI.CreateSearchBar(leftPanel, leftW - padding * 2 - KF.Scale(90) - playersSortDropdown:GetWide() - KF.Scale(5), L("admin_search_items"), function(val)
        RebuildAvailableItems(val)
    end)
    itemSearchBar:SetPos(padding, itemsSectionTop + KF.Scale(40))

    local giveBtn = KrakensStore.UI.Button(leftPanel, L("btn_give"))
    giveBtn:SizeToLabel(S(60))
    giveBtn:SetPos(leftW - padding - giveBtn:GetWide(), itemsSectionTop + KF.Scale(40))
    giveBtn:SetEnabled(false)

    local itemsGridTop = itemsSectionTop + KF.Scale(85)
    local itemsGridH = h - itemsGridTop - padding

    local itemsScroll = vgui.Create("KF.ScrollPanel", leftPanel)
    itemsScroll:SetAddon(AID)
    itemsScroll:SetPos(padding, itemsGridTop)
    itemsScroll:SetSize(leftW - padding * 2, itemsGridH)

    local itemsGrid = vgui.Create("DPanel", itemsScroll)
    itemsGrid:SetSize(leftW - padding * 2 - T("ScrollGutter"), itemsGridH)
    itemsGrid.Paint = function() end

    local rightPanel = vgui.Create("DPanel", parent)
    rightPanel:SetPos(leftW + separatorW, 0)
    rightPanel:SetSize(rightW, h)
    rightPanel.Paint = function(self, pw, ph)
        KF.Draw.Panel(0, 0, pw, ph, KrakensStore.UI.FLAT_PANEL)
    end

    local invHeader = vgui.Create("DPanel", rightPanel)
    invHeader:SetPos(padding, padding)
    invHeader:SetSize(rightW - padding * 2, KF.Scale(30))
    invHeader._playerName = L("admin_no_player_selected")
    invHeader.Paint = function(self, hw, hh)
        local headerText = string.upper(self._playerName) .. L("admin_player_inventory_suffix")
        draw.SimpleText(headerText, F("PanelTitle"), 0, hh / 2,
            C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        KF.Draw.HeaderSeparator(hw, hh, AID)
    end

    local invActionsY = padding + KF.Scale(40)

    local takeBtn = KrakensStore.UI.Button(rightPanel, L("btn_take"))
    takeBtn:SizeToLabel(S(60))
    takeBtn:SetPos(padding, invActionsY)
    takeBtn:SetEnabled(false)

    local resetBtn = KrakensStore.UI.Button(rightPanel, L("btn_reset_all"), "danger")
    resetBtn:SizeToLabel(S(60))
    resetBtn:SetPos(padding + takeBtn:GetWide() + T("SpaceS"), invActionsY)
    resetBtn:SetEnabled(false)

    local invCountLabel = vgui.Create("DLabel", rightPanel)
    invCountLabel:SetPos(resetBtn:GetX() + resetBtn:GetWide() + T("SpaceS"), invActionsY)
    invCountLabel:SetSize(KF.Scale(150), T("ButtonH"))
    invCountLabel:SetFont(F("Meta"))
    invCountLabel:SetTextColor(C("TextMuted"))
    invCountLabel:SetText("")

    local pageBtnW = T("ButtonHSmall")
    local pageBtnH = T("ButtonHSmall")
    local pageBtnY = invActionsY + math.floor((T("ButtonH") - pageBtnH) / 2)
    local nextBtn = KrakensStore.UI.Button(rightPanel)
    nextBtn:SetAddon(AID)
    nextBtn:SetPos(rightW - padding - pageBtnW, pageBtnY)
    nextBtn:SetSize(pageBtnW, pageBtnH)
    nextBtn:SetLabel(">")

    local prevBtn = KrakensStore.UI.Button(rightPanel)
    prevBtn:SetAddon(AID)
    prevBtn:SetPos(rightW - padding - pageBtnW * 2 - T("SpaceXS"), pageBtnY)
    prevBtn:SetSize(pageBtnW, pageBtnH)
    prevBtn:SetLabel("<")

    local invGridTop = invActionsY + KF.Scale(45)
    local invGridH = h - invGridTop - padding

    local invScroll = vgui.Create("KF.ScrollPanel", rightPanel)
    invScroll:SetAddon(AID)
    invScroll:SetPos(padding, invGridTop)
    invScroll:SetSize(rightW - padding * 2, invGridH)

    local invGrid = vgui.Create("DPanel", invScroll)
    invGrid:SetSize(rightW - padding * 2 - T("ScrollGutter"), invGridH)
    invGrid.Paint = function(_, gw, gh)
        if not selectedPlayer then
            KF.Draw.EmptyState(gw, gh, L("admin_select_player_view"), nil, { addonId = AID, showIcon = false })
        elseif #playerInventory == 0 then
            KF.Draw.EmptyState(gw, gh, L("admin_player_inventory_empty"), nil, { addonId = AID, showIcon = false })
        end
    end

    local function BuildItemCard(parentGrid, itemData, x, y, cellSize, onSelect)
        local card = vgui.Create("DButton", parentGrid)
        card:SetPos(x, y)
        card:SetSize(cellSize - 4, cellSize - 4)
        card:SetText("")
        card._item = itemData
        card._hoverLerp = 0
        card._selected = false
        KF.Helpers.BindSounds(card, AID, { click = false })

        KF.Tooltip.Set(card, (itemData.name or L("ui_unknown")) .. (itemData.quantity and (" " .. L("ui_quantity_prefix") .. itemData.quantity) or ""), { addon = AID })

        if not (itemData.icon and itemData.icon ~= "") and KF.Materials.IsModelPath(itemData.model) then
            local iconPad = KF.Scale(6)
            local nameBarH = KF.Scale(30)
            local initSize = math.min(cellSize - 4 - iconPad * 2, cellSize - 4 - nameBarH)
            local initX = (cellSize - 4 - initSize) / 2
            KF.Helpers.EnsureModelPanel(card, "playerIcon", itemData.model, initX, iconPad, initSize)
            card._hasModelPanel = true
        end

        card.Paint = function(self, cw, ch)
            self._hoverLerp = Lerp(FrameTime() * 10, self._hoverLerp, self:IsHovered() and 1 or 0)

            local bgColor = C("PanelDark")
            draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, cw, ch, bgColor)

            local borderColor = self._selected and C("Accent") or C("Border")
            surface.SetDrawColor(borderColor)
            surface.DrawOutlinedRect(0, 0, cw, ch, self._selected and 2 or 1)

            if self._hoverLerp > 0 and not self._selected then
                local accentColor = C("Accent")
                surface.SetDrawColor(accentColor.r, accentColor.g, accentColor.b, 40 * self._hoverLerp)
                surface.DrawRect(2, 2, cw - 4, ch - 4)
            end

            if self._selected then
                local accentColor = C("Accent")
                local pulse = math.abs(math.sin(RealTime() * 2)) * 0.3 + 0.15
                surface.SetDrawColor(accentColor.r, accentColor.g, accentColor.b, pulse * 255)
                surface.DrawRect(2, 2, cw - 4, ch - 4)
            end

            local iconPad = KF.Scale(6)
            local nameBarH = KF.Scale(30)
            local iconSize = math.min(cw - iconPad * 2, ch - nameBarH)
            local iconX = (cw - iconSize) / 2

            KrakensStore.UI.DrawItemIcon(itemData, iconX, iconPad, iconSize, {
                hasModelPanel = self._hasModelPanel,
                texPad = 0,
            })

            if itemData.quantity and itemData.quantity > 1 then
                local qtyStr = L("ui_quantity_prefix") .. itemData.quantity
                surface.SetFont(F("Tiny"))
                local qtyTextW = surface.GetTextSize(qtyStr)
                local qtyPadX = KF.Scale(6)
                local qtyW = qtyTextW + qtyPadX * 2
                local qtyH = KF.Scale(16)
                local qtyInset = KF.Scale(4)
                draw.RoundedBox(KF.UI.Tokens.Radius, cw - qtyW - qtyInset, qtyInset, qtyW, qtyH, C("Accent"))
                draw.SimpleText(qtyStr, F("Tiny"), cw - qtyW / 2 - qtyInset, qtyInset + qtyH / 2,
                    C("BackgroundDark"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            local nameStripH = KF.Scale(21)
            local nameY = ch - KF.Scale(18)
            local displayName = KF.TruncateText(itemData.name or L("ui_unknown"), F("Tiny"), cw - KF.Scale(8))

            surface.SetDrawColor(KF.UI.ColorAlpha(C("BackgroundDark"), 180))
            surface.DrawRect(0, nameY - KF.Scale(3), cw, nameStripH)

            draw.SimpleText(displayName, F("Tiny"), cw / 2, nameY + KF.Scale(5),
                C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        card.DoClick = function()
            KrakensStore.UI.PlaySound("Click")
            if onSelect then
                onSelect(card, itemData)
            end
        end

        return card
    end

    local availableItemCards = {}

    RebuildAvailableItems = function(query)
        itemsGrid:Clear()
        availableItemCards = {}
        selectedGiveItem = nil
        giveBtn:SetEnabled(false)

        query = KF.NormalizeQuery(query)

        local items = {}
        local itemCache = KrakensStore.Items.GetAll() or {}

        for id, item in pairs(itemCache) do
            if item.enabled ~= false and KF.MatchesQuery(item.name, query) then
                table.insert(items, {
                    id = id,
                    name = item.name or id,
                    icon = item.icon,
                    model = item.model,
                    price = item.price or 0,
                    type = item.type
                })
            end
        end

        KrakensStore.UI.SortItems(items, playersSortMode)

        local availW = leftW - padding * 2 - 20
        local cols, cellSize = CalculateGridLayout(availW)

        local rows = math.ceil(#items / cols)
        itemsGrid:SetTall(math.max(itemsGridH, rows * cellSize + 10))

        for i, itemData in ipairs(items) do
            local row = math.floor((i - 1) / cols)
            local col = (i - 1) % cols

            local card = BuildItemCard(itemsGrid, itemData, col * cellSize + 2, row * cellSize + 2, cellSize, function(c, data)
                selectedGiveItem = ToggleCardSelection(availableItemCards, c, data.id, selectedGiveItem)
                giveBtn:SetEnabled(selectedGiveItem ~= nil and selectedPlayer ~= nil)
            end)

            availableItemCards[itemData.id] = card
        end
    end

    local invItemCards = {}

    local function RebuildInventoryGrid()
        if not IsValid(invGrid) then return end
        invGrid:Clear()
        invItemCards = {}
        selectedTakeItem = nil
        if IsValid(takeBtn) then takeBtn:SetEnabled(false) end

        if not selectedPlayer or not IsValid(selectedPlayer) then
            if IsValid(invCountLabel) then invCountLabel:SetText("") end
            if IsValid(prevBtn) then prevBtn:SetEnabled(false) end
            if IsValid(nextBtn) then nextBtn:SetEnabled(false) end
            return
        end

        playerInventory = KrakensStore.AdminPlayerInventories[selectedPlayer:SteamID64()] or {}

        local availW = rightW - padding * 2 - 20
        local cols, cellSize = CalculateGridLayout(availW)
        local rowsVisible = math.max(1, math.floor(invGridH / cellSize))
        local itemsPerPage = math.max(1, rowsVisible * cols)
        totalPages = math.max(1, math.ceil(#playerInventory / itemsPerPage))
        currentPage = math.Clamp(currentPage, 1, totalPages)

        invCountLabel:SetText(#playerInventory .. " " .. L("inv_item_plural") .. " (" .. currentPage .. "/" .. totalPages .. ")")

        if IsValid(prevBtn) then prevBtn:SetEnabled(currentPage > 1) end
        if IsValid(nextBtn) then nextBtn:SetEnabled(currentPage < totalPages) end

        if #playerInventory == 0 then
            invGrid:SetTall(invGridH)
            return
        end

        invGrid:SetTall(math.max(invGridH, rowsVisible * cellSize + 10))

        local startIndex = (currentPage - 1) * itemsPerPage + 1
        local endIndex = math.min(#playerInventory, startIndex + itemsPerPage - 1)

        for i = startIndex, endIndex do
            local invItem = playerInventory[i]
            local localIndex = i - startIndex
            local row = math.floor(localIndex / cols)
            local col = localIndex % cols

            local itemDetails = KrakensStore.Items.Get(invItem.itemId)

            local itemData = {
                id = invItem.itemId,
                name = itemDetails and itemDetails.name or invItem.itemId,
                icon = itemDetails and itemDetails.icon,
                model = itemDetails and itemDetails.model,
                quantity = KrakensStore.GetInvQuantity(invItem)
            }

            local card = BuildItemCard(invGrid, itemData, col * cellSize + 2, row * cellSize + 2, cellSize, function(c, data)
                selectedTakeItem = ToggleCardSelection(invItemCards, c, data.id, selectedTakeItem)
                takeBtn:SetEnabled(selectedTakeItem ~= nil)
            end)

            invItemCards[invItem.itemId] = card
        end
    end

    prevBtn.DoClick = function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            RebuildInventoryGrid()
        end
    end

    nextBtn.DoClick = function()
        if currentPage < totalPages then
            currentPage = currentPage + 1
            RebuildInventoryGrid()
        end
    end

    local playerButtons = {}

    local function BuildPlayerList()
        playerList:Clear()
        playerButtons = {}

        for _, ply in ipairs(player.GetAll()) do
            local row = vgui.Create("DButton", playerList)
            row:SetSize(leftW - padding * 2 - T("ScrollGutter"), T("RowH"))
            row:SetText("")
            row._hoverLerp = 0
            row._selected = false
            KF.Helpers.BindSounds(row, AID, { click = false })

            row.Paint = function(self, rw, rh)
                self._hoverLerp = Lerp(FrameTime() * 10, self._hoverLerp, self:IsHovered() and 1 or 0)

                local bgColor = self._selected
                    and KF.UI.ColorAlpha(C("Accent"), 60)
                    or KF.UI.LerpColor(self._hoverLerp, C("Panel"), C("PanelHover"))

                draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, rw, rh, bgColor)

                local borderColor = self._selected and C("Accent") or C("Border")
                surface.SetDrawColor(borderColor)
                surface.DrawOutlinedRect(0, 0, rw, rh, self._selected and 2 or 1)

                local avatarPad = KF.Scale(8)
                draw.RoundedBox(KF.UI.Tokens.Radius, avatarPad, avatarPad, rh - avatarPad * 2, rh - avatarPad * 2, C("PanelDark"))

                local maxNameW = rw - rh - KF.Scale(15)
                local truncNick = KF.TruncateText(IsValid(ply) and ply:Nick() or L("ui_disconnected"), F("Value"), maxNameW)
                draw.SimpleText(truncNick, F("Value"), rh + KF.Scale(5), rh / 2 - KF.Scale(6),
                    C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                draw.SimpleText(IsValid(ply) and ply:SteamID() or "", F("Tiny"), rh + KF.Scale(5), rh / 2 + KF.Scale(8),
                    C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local avatarPad = KF.Scale(8)
            local avatar = vgui.Create("AvatarImage", row)
            avatar:SetPos(avatarPad, avatarPad)
            avatar:SetSize(row:GetTall() - avatarPad * 2, row:GetTall() - avatarPad * 2)
            avatar:SetPlayer(ply, 64)

            row.DoClick = function()
                KrakensStore.UI.PlaySound("Click")
                for _, btn in pairs(playerButtons) do
                    if IsValid(btn) then btn._selected = false end
                end

                row._selected = true

                selectedPlayer = ply
                invHeader._playerName = ply:Nick()

                giveBtn:SetEnabled(selectedGiveItem ~= nil)
                resetBtn:SetEnabled(true)

                watchedSteamId = ply:SteamID64()
                KrakensStore.Net.AdminAction("watch_player_inventory", {
                    targetSteamId = watchedSteamId,
                    watch = true
                })

                RebuildInventoryGrid()
            end

            playerButtons[ply:SteamID64()] = row
        end
    end

    giveBtn.DoClick = function()
        if not selectedPlayer or not IsValid(selectedPlayer) or not selectedGiveItem then
            KrakensStore.UI.ShowNotification(L("admin_select_player_item"), "warning")
            return
        end
        if giveBtn._working then return end

        KrakensStore.UI.RunBusy(giveBtn, L("btn_give"), 0.8, function()
            KrakensStore.Net.AdminAction("give_item", {
                targetSteamId = selectedPlayer:SteamID64(),
                itemId = selectedGiveItem,
                quantity = 1
            })
        end)
    end

    takeBtn.DoClick = function()
        if not selectedPlayer or not IsValid(selectedPlayer) or not selectedTakeItem then
            KrakensStore.UI.ShowNotification(L("admin_select_item_take"), "warning")
            return
        end
        if takeBtn._working then return end

        KrakensStore.UI.RunBusy(takeBtn, L("btn_take"), 0.8, function()
            KrakensStore.Net.AdminAction("take_item", {
                targetSteamId = selectedPlayer:SteamID64(),
                itemId = selectedTakeItem,
                quantity = 1
            })
        end)
    end

    resetBtn.DoClick = function()
        if not selectedPlayer or not IsValid(selectedPlayer) then
            KrakensStore.UI.ShowNotification(L("admin_select_player_first"), "warning")
            return
        end
        if resetBtn._working then return end

        KrakensStore.UI.ConfirmDialog(
            L("dialog_confirm_reset"),
            L("dialog_reset_prefix") .. selectedPlayer:Nick() .. L("dialog_reset_suffix") .. " " .. L("dialog_reset_warning"),
            L("btn_reset_all"), L("btn_cancel"),
            function()
                KrakensStore.UI.RunBusy(resetBtn, L("btn_reset_all"), 1.0, function()
                    KrakensStore.Net.AdminAction("reset_inventory", {
                        targetSteamId = selectedPlayer:SteamID64()
                    })
                end)
            end, nil, true
        )
    end

    hook.Add("KrakensStore_AdminResponse", parent, function(_, response)
        if not response then return end

        if response.action == "player_inventory" and response.data then
            if response.steamId then
                KrakensStore.AdminPlayerInventories[response.steamId] = response.data
            end

            if selectedPlayer and IsValid(selectedPlayer) and selectedPlayer:SteamID64() == response.steamId then
                currentPage = 1
                RebuildInventoryGrid()
            end
        elseif response.action == "player_inventory_delta" and response.steamId and response.itemId then
            local list = KrakensStore.AdminPlayerInventories[response.steamId] or {}

            local idx = nil
            for i, it in ipairs(list) do
                if it.itemId == response.itemId then
                    idx = i
                    break
                end
            end

            if response.invItem then
                local invItem = response.invItem
                invItem.itemId = response.itemId

                if idx then
                    list[idx] = invItem
                else
                    table.insert(list, invItem)
                end
            else
                if idx then
                    table.remove(list, idx)
                end
            end

            KrakensStore.AdminPlayerInventories[response.steamId] = list

            if IsValid(selectedPlayer) and selectedPlayer:SteamID64() == response.steamId then
                RebuildInventoryGrid()
            end
        end
    end)

    parent.OnRemove = function()
        if not watchedSteamId then return end
        KrakensStore.Net.AdminAction("watch_player_inventory", {
            targetSteamId = watchedSteamId,
            watch = false
        })
    end

    BuildPlayerList()
    RebuildAvailableItems("")
end

local AttachmentSystems = KrakensStore.Integrations.AttachmentSystems
local IsAttBlacklisted = KrakensStore.Integrations.IsAttachmentBlacklisted
local attCache, attCacheAt

local function SystemFilterOptions(allLabel)
    local options = { { "all", allLabel } }
    for key, system in SortedPairs(AttachmentSystems) do options[#options + 1] = { key, system.name } end
    return options
end

function KrakensStore.Admin.GatherAttachments(force)
    local now = CurTime()
    if not force and attCache and (now - attCacheAt) < 3 then return attCache end
    local list = {}
    for name, att in pairs(AttachmentSystems.arc9.GetAttTable() or {}) do
        list[#list + 1] = {
            system = "arc9", id = name,
            name = att.PrintName or att.TrueName or name,
            desc = att.Description or att.Desc or "",
            slot = att.Category or att.MenuCategory or att.Folder or "",
        }
    end
    for name, att in pairs(AttachmentSystems.arccw.GetAttTable() or {}) do
        list[#list + 1] = {
            system = "arccw", id = name,
            name = att.PrintName or name,
            desc = att.Description or "",
            slot = att.Slot or att.Category or att.MenuCategory or "",
        }
    end
    table.sort(list, function(a, b)
        if a.system ~= b.system then return a.system < b.system end
        return string.lower(tostring(a.name or a.id)) < string.lower(tostring(b.name or b.id))
    end)
    attCache, attCacheAt = list, now
    return list
end

local function SetAttBlacklisted(system, id, flag)
    local bucket = AttachmentSystems[system].GetBlacklist()
    bucket[id] = nil
    bucket[string.lower(string.Trim(tostring(id)))] = flag or nil
end

function KrakensStore.Admin.BuildBlacklistTab(parent)
    local w, h = parent:GetSize()
    local Scale = KF.Scale
    local padding = Scale(16)
    local contentW = w - padding * 2

    local container = vgui.Create("DPanel", parent)
    container:SetPos(0, 0)
    container:SetSize(w, h)
    container.Paint = function(_, pw, ph) KF.Draw.Panel(0, 0, pw, ph, KrakensStore.UI.FLAT_PANEL) end

    local toolbar = vgui.Create("DPanel", container)
    toolbar:SetPos(padding, padding)
    toolbar:SetSize(contentW, T("ButtonH"))
    toolbar.Paint = function() end

    local systemFilter = vgui.Create("KF.PopupDropdown", toolbar)
    systemFilter:SetAddon(AID)
    systemFilter:SetPos(0, 0)
    local filterOptions = SystemFilterOptions(L("blacklist_filter_all"))
    local filterLabels = {}
    for i, option in ipairs(filterOptions) do filterLabels[i] = option[2] end
    local sysFilterW = KF.MaxTextWidth(filterLabels, F("Body"), Scale(30))
    sysFilterW = math.Clamp(sysFilterW, Scale(120), Scale(240))
    systemFilter:SetSize(sysFilterW, T("InputH"))
    for _, option in ipairs(filterOptions) do systemFilter:AddOption(option[1], option[2]) end
    systemFilter:SetValue("all")

    local onlyBlocked = vgui.Create("KF.Checkbox", toolbar)
    onlyBlocked:SetAddon(AID)
    onlyBlocked:SetPos(sysFilterW + Scale(240), math.floor((T("ButtonH") - T("ButtonHSmall")) / 2))
    onlyBlocked:SetSize(KF.TextWidth(L("blacklist_only"), F("Body"), S(40)), T("ButtonHSmall"))
    onlyBlocked:SetLabel(L("blacklist_only"))
    onlyBlocked:SetChecked(false)

    local statsLabel = vgui.Create("DLabel", toolbar)
    statsLabel:SetPos(contentW - Scale(280), Scale(6))
    statsLabel:SetSize(Scale(180), Scale(20))
    statsLabel:SetFont(F("Meta"))
    statsLabel:SetTextColor(C("TextMuted"))
    statsLabel:SetContentAlignment(6)

    local saveBlacklistBtn = KrakensStore.UI.Button(toolbar, L("btn_save"), "success")
    saveBlacklistBtn:SetSolid(true)
    saveBlacklistBtn:SizeToLabel(S(70))
    saveBlacklistBtn:SetPos(contentW - saveBlacklistBtn:GetWide(), 0)

    local scroll = vgui.Create("KF.ScrollPanel", container)
    scroll:SetAddon(AID)
    local listTop = padding + T("ButtonH") + T("SpaceM")
    scroll:SetPos(padding, listTop)
    scroll:SetSize(contentW, h - listTop - padding)

    local listLayout = vgui.Create("DListLayout", scroll)
    listLayout:SetSize(contentW, 0)
    listLayout:SetPos(0, 0)
    listLayout.Paint = function() end

    local emptyLabel = vgui.Create("DPanel", container)
    emptyLabel:SetPos(padding, listTop)
    emptyLabel:SetSize(contentW, h - listTop - padding)
    emptyLabel:SetMouseInputEnabled(false)
    emptyLabel.Paint = function(_, ew, eh) KF.Draw.EmptyState(ew, eh, L("blacklist_none"), nil, { addonId = AID, showIcon = false }) end
    emptyLabel:SetVisible(false)

    local filterSystem = "all"
    local searchTerm = ""
    local dirty = false
    local saved = {}
    local function Snapshot()
        for key, system in pairs(AttachmentSystems) do saved[key] = table.Copy(system.GetBlacklist()) end
    end
    Snapshot()
    local rebuildList

    local function matchesFilter(entry)
        if filterSystem ~= "all" and entry.system ~= filterSystem then return false end
        if onlyBlocked:GetChecked() and not IsAttBlacklisted(entry.system, entry.id) then return false end
        if searchTerm ~= "" then
            local slotStr = istable(entry.slot) and table.concat(entry.slot, ", ") or tostring(entry.slot or "")
            local hay = string.lower((entry.name or "") .. " " .. (entry.id or "") .. " " .. slotStr .. " " .. (entry.desc or ""))
            if not string.find(hay, searchTerm, 1, true) then return false end
        end
        return true
    end

    rebuildList = function()
        listLayout:Clear()
        local entries = KrakensStore.Admin.GatherAttachments()
        local total, blocked, matched = #entries, 0, 0

        for _, entry in ipairs(entries) do
            if IsAttBlacklisted(entry.system, entry.id) then blocked = blocked + 1 end
        end
        statsLabel:SetText(string.format("%s %d / %d", L("blacklist_count"), blocked, total))

        for _, entry in ipairs(entries) do
            if not matchesFilter(entry) then continue end
            matched = matched + 1

            local row = vgui.Create("DPanel", listLayout)
            row:Dock(TOP)
            row:DockMargin(0, T("SpaceXS"), 0, 0)
            row:SetTall(T("RowH"))
            local isBlocked = IsAttBlacklisted(entry.system, entry.id)
            local rowOpts = { addonId = AID, leftColor = isBlocked and C("Error") or nil }
            row.Paint = function(_, rw, rh) KF.Draw.ListEntryBase(rw, rh, 0, rowOpts) end

            local info = vgui.Create("DPanel", row)
            info:Dock(FILL)
            info:DockMargin(T("SpaceM"), T("SpaceXS"), 0, T("SpaceXS"))
            info.Paint = function() end

            local nameLbl = vgui.Create("DLabel", info)
            nameLbl:Dock(TOP)
            nameLbl:SetFont(F("Value"))
            nameLbl:SetTextColor(C("TextPrimary"))
            nameLbl:SetText(entry.name or entry.id)
            nameLbl:SizeToContents()

            local sysTag = AttachmentSystems[entry.system].name
            local rawSlot = istable(entry.slot) and table.concat(entry.slot, ", ") or tostring(entry.slot or "")
            local slotInfo = rawSlot ~= "" and rawSlot or L("blacklist_slot_unknown")
            local descText = string.Trim(tostring(entry.desc or ""))
            if descText == "" then descText = L("blacklist_no_desc") end

            local metaLbl = vgui.Create("DLabel", info)
            metaLbl:Dock(TOP)
            metaLbl:SetFont(F("Meta"))
            metaLbl:SetTextColor(C("TextMuted"))
            metaLbl:SetText(sysTag .. " · " .. slotInfo .. " · " .. descText)
            metaLbl:SizeToContents()

            local toggleText = isBlocked and L("blacklist_action_allow") or L("blacklist_action_block")
            local toggle = KrakensStore.UI.Button(row, toggleText)
            toggle:SizeToLabel(S(80), S(200), T("ButtonHSmall"))
            toggle:Dock(RIGHT)
            local toggleMargin = math.floor((T("RowH") - T("ButtonHSmall")) / 2)
            toggle:DockMargin(0, toggleMargin, T("SpaceS"), toggleMargin)
            toggle.DoClick = function()
                SetAttBlacklisted(entry.system, entry.id, not isBlocked)
                dirty = true
                rebuildList()
            end
        end

        emptyLabel:SetVisible(matched == 0)
    end

    systemFilter.OnSelect = function(self, idx, text, val)
        filterSystem = val or "all"
        rebuildList()
    end

    local search = KrakensStore.UI.CreateSearchBar(toolbar, Scale(220), L("blacklist_search_placeholder"), function(val)
        searchTerm = string.lower(string.Trim(val or ""))
        rebuildList()
    end)
    search:SetPos(sysFilterW + T("SpaceS"), math.floor((T("ButtonH") - search:GetTall()) / 2))

    onlyBlocked.OnChange = function()
        timer.Simple(0, rebuildList)
    end

    KrakensStore.Admin.SaveAction(saveBlacklistBtn, {
        action = "save_blacklist",
        defaultLabel = L("btn_save"),
        parent = parent,
        onSuccess = function() dirty = false Snapshot() end,
        buildPayload = function()
            local payload = {}
            for key, system in pairs(AttachmentSystems) do payload[key] = system.GetBlacklist() end
            return payload
        end,
    })

    parent.OnRemove = function()
        if dirty then KrakensStore.Config.ApplyBlacklist(saved) end
    end

    rebuildList()
end

local function GetSpawnTargets()
    local labels = {
        usergroups = L("spawn_category_usergroups"), jobs = L("spawn_category_jobs"), jobCategories = L("spawn_category_job_categories"),
        helixFactions = L("spawn_category_helix_factions"), helixClasses = L("spawn_category_helix_classes"),
        nutFactions = L("spawn_category_nut_factions"), nutClasses = L("spawn_category_nut_classes"),
    }
    local targets = {}
    for _, cat in ipairs(KF.Whitelist.GetCategories({ labels = labels })) do
        for _, entry in ipairs(cat.getter() or {}) do
            targets[#targets + 1] = { type = cat.key, id = entry.uniqueID or tostring(entry.id), name = entry.name, category = cat.label }
        end
    end
    return targets
end

KF.Net.Receive("KrakensStore_AdminData", function()
    local data = KF.Net.ReadCompressed(32, KrakensStore.Validation.Limits.MAX_DECOMPRESSED)
    if not data then
        KrakensStore.Log("warn", "AdminData: failed to decompress admin data")
        return
    end

    if data.spawnAssignments then
        KrakensStore.SpawnAssignmentsCache = data.spawnAssignments
        hook.Run("KrakensStore_SpawnAssignmentsUpdated", KrakensStore.SpawnAssignmentsCache)
    end
    hook.Run("KrakensStore_AdminDataReceived", data)
end)

function KrakensStore.Admin.BuildSpawnTab(parent)
    local w, h = parent:GetSize()
    parent.Paint = function(_, pw, ph) draw.RoundedBox(0, 0, 0, pw, ph, C("Background")) end
    local pad, listW = T("SpaceM"), T("ListW")
    local rightW = w - listW - pad
    local selectedTarget
    local assignments = table.Copy(KrakensStore.SpawnAssignmentsCache or {})
    local dirty = false

    local function GetAssignment(target)
        assignments[target.type] = assignments[target.type] or {}
        assignments[target.type][target.id] = assignments[target.type][target.id] or { items = {}, attachments = {} }
        return assignments[target.type][target.id]
    end

    hook.Add("KrakensStore_SpawnAssignmentsUpdated", parent, function()
        if dirty then return end
        KrakensStore.UI.CloseAllPopups()
        parent:Clear()
        KrakensStore.Admin.BuildSpawnTab(parent)
    end)

    local leftPanel = vgui.Create("DPanel", parent)
    leftPanel:SetSize(listW, h)
    leftPanel.Paint = function(_, sw, sh) KF.Draw.Panel(0, 0, sw, sh, KrakensStore.UI.FLAT_PANEL) end

    local headerH = T("PaneHeaderH")
    local header = vgui.Create("DPanel", leftPanel)
    header:SetPos(pad, pad)
    header:SetSize(listW - pad * 2, headerH)
    header.Paint = function(_, hw, hh)
        draw.SimpleText(L("spawn_title"), F("PanelTitle"), 0, hh / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C("Border"))
        surface.DrawRect(0, hh - 1, hw, 1)
    end

    local saveBtn = KrakensStore.UI.Button(leftPanel, L("btn_save"), "success")
    saveBtn:SetSolid(true)
    saveBtn:SetSize(listW - pad * 2, T("ButtonH"))
    saveBtn:SetPos(pad, h - pad - saveBtn:GetTall())

    local listTop = pad + headerH + pad
    local leftScroll = vgui.Create("KF.ScrollPanel", leftPanel)
    leftScroll:SetAddon(AID)
    leftScroll:SetPos(pad, listTop)
    leftScroll:SetSize(listW - pad * 2, h - listTop - pad * 2 - saveBtn:GetTall())
    local leftList = vgui.Create("DListLayout", leftScroll)
    leftList:SetSize(listW - pad * 2 - T("ScrollGutter"), 0)

    local rightPanel = vgui.Create("DPanel", parent)
    rightPanel:SetPos(listW + pad, 0)
    rightPanel:SetSize(rightW, h)
    rightPanel.Paint = function(_, pw, ph)
        KF.Draw.Panel(0, 0, pw, ph, KrakensStore.UI.FLAT_PANEL)
        if not selectedTarget then KF.Draw.EmptyState(pw, ph, L("spawn_select_target"), nil, { addonId = AID, showIcon = false }) end
    end

    local rightContent = vgui.Create("DPanel", rightPanel)
    rightContent:SetPos(pad, pad)
    rightContent:SetSize(rightW - pad * 2, h - pad * 2)
    rightContent.Paint = KF.Helpers.NoPaint
    rightContent:SetVisible(false)

    local function BuildColumn(x, colW, titleKey, entries, selected, onChange, searchKey)
        local column = vgui.Create("DPanel", rightContent)
        column:SetPos(x, 0)
        column:SetSize(colW, rightContent:GetTall())
        column.Paint = KF.Helpers.NoPaint
        local title = KF.FormBuilder.SectionHeader(column, L(titleKey), nil, { addonId = AID, width = colW })
        title:SetPos(0, 0)
        local list = KF.FormBuilder.Checklist(column, {
            addonId = AID, width = colW, entries = entries, selected = selected, searchable = true,
            searchPlaceholder = L(searchKey), onChange = onChange,
        })
        list:SetPos(0, title:GetTall() + T("SpaceS"))
        list:SetTall(column:GetTall() - title:GetTall() - T("SpaceS"))
    end

    local function RebuildRight()
        rightContent:Clear()
        rightContent:SetVisible(selectedTarget ~= nil)
        if not selectedTarget then return end
        local assign = GetAssignment(selectedTarget)
        local colW = math.floor((rightContent:GetWide() - pad) / 2)

        local categories = KrakensStore.Categories.GetAll()
        local itemEntries = {}
        for id, item in pairs(KrakensStore.Items.GetAll()) do
            local cat = categories[item.category]
            itemEntries[#itemEntries + 1] = { id = id, label = item.name or id, group = cat and cat.name or item.category or L("ui_misc") }
        end
        table.sort(itemEntries, function(a, b)
            if a.group ~= b.group then return a.group < b.group end
            return a.label < b.label
        end)
        local selectedItems = {}
        for _, id in ipairs(assign.items) do selectedItems[id] = true end
        BuildColumn(0, colW, "spawn_assigned_items", itemEntries, selectedItems, function()
            assign.items = table.GetKeys(selectedItems)
            table.sort(assign.items)
            dirty = true
        end, "spawn_search_items")

        local attEntries = {}
        for _, att in ipairs(KrakensStore.Admin.GatherAttachments()) do
            attEntries[#attEntries + 1] = { id = att.system .. "|" .. att.id, label = att.name or att.id, group = AttachmentSystems[att.system].name }
        end
        table.sort(attEntries, function(a, b)
            if a.group ~= b.group then return a.group < b.group end
            return a.label < b.label
        end)
        local selectedAtts = {}
        for _, att in ipairs(assign.attachments) do selectedAtts[att.system .. "|" .. att.id] = true end
        BuildColumn(colW + pad, colW, "spawn_assigned_attachments", attEntries, selectedAtts, function()
            local out = {}
            for key in SortedPairs(selectedAtts) do
                local system, id = string.match(key, "^([^|]+)|(.+)$")
                if system then out[#out + 1] = { system = system, id = id } end
            end
            assign.attachments = out
            dirty = true
        end, "spawn_search_attachments")
    end

    local categoryExpanded = {}
    local targetRows = {}

    local function BuildLeftList()
        leftList:Clear()
        targetRows = {}
        local targets = GetSpawnTargets()
        local grouped = {}
        for _, t in ipairs(targets) do
            grouped[t.category] = grouped[t.category] or {}
            table.insert(grouped[t.category], t)
        end
        local cats = table.GetKeys(grouped)
        table.sort(cats)
        local rowH = T("ButtonHSmall")
        for _, cat in ipairs(cats) do
            if categoryExpanded[cat] == nil then categoryExpanded[cat] = true end
            local catHeader = vgui.Create("DButton", leftList)
            catHeader:Dock(TOP)
            catHeader:DockMargin(0, T("SpaceXS"), 0, 0)
            catHeader:SetTall(rowH)
            catHeader:SetText("")
            catHeader.Paint = function(s, cw, ch)
                draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, cw, ch, C(s:IsHovered() and "PanelHover" or "Panel"))
                draw.SimpleText((categoryExpanded[cat] and "-" or "+") .. "  " .. cat, F("Value"), T("SpaceS"), ch / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            catHeader.DoClick = function()
                categoryExpanded[cat] = not categoryExpanded[cat]
                BuildLeftList()
            end
            KF.Helpers.BindSounds(catHeader, AID)
            leftList:Add(catHeader)
            if categoryExpanded[cat] then
                for _, target in ipairs(grouped[cat]) do
                    local row = vgui.Create("DButton", leftList)
                    row:Dock(TOP)
                    row:DockMargin(T("SpaceL"), T("SpaceXS"), 0, 0)
                    row:SetTall(rowH)
                    row:SetText("")
                    row._selected = selectedTarget ~= nil and selectedTarget.type == target.type and selectedTarget.id == target.id
                    row.Paint = function(s, rw, rh)
                        KF.Draw.SelectableRow(s, rw, rh, s._selected, AID)
                        draw.SimpleText(target.name, F("Meta"), T("SpaceM"), rh / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end
                    row.DoClick = function()
                        for _, other in pairs(targetRows) do
                            if IsValid(other) then other._selected = false end
                        end
                        row._selected = true
                        selectedTarget = target
                        RebuildRight()
                    end
                    KF.Helpers.BindSounds(row, AID)
                    targetRows[target.type .. "_" .. target.id] = row
                    leftList:Add(row)
                end
            end
        end
        if #targets == 0 then KF.Builders.EmptyRow(leftList, L("spawn_no_targets"), nil, { addonId = AID }) end
    end

    saveBtn.DoClick = function()
        dirty = false
        KrakensStore.Net.AdminAction("save_spawn_assignments", table.Copy(assignments))
    end

    BuildLeftList()
end
