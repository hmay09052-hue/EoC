local T = BattleGrid.Theme
local AID = BattleGrid.AID
local S = KF.Scale

local SIDEBAR_GROUPS = {
    {labelKey = "ADMIN_GROUP_SYSTEM", items = {
        {key = "general",     labelKey = "ADMIN_NAV_GENERAL"},
        {key = "permissions", labelKey = "ADMIN_NAV_PERMISSIONS"},
        {key = "jammers",     labelKey = "ADMIN_NAV_JAMMERS"},
    }},
    {labelKey = "ADMIN_GROUP_DATA", items = {
        {key = "waypoints", labelKey = "ADMIN_NAV_WAYPOINTS"},
        {key = "areas",     labelKey = "ADMIN_NAV_AREAS"},
        {key = "icons",     labelKey = "ADMIN_NAV_ICONS"},
    }},
    {labelKey = "ADMIN_GROUP_FACTIONS", items = {
        {key = "factions",     labelKey = "ADMIN_NAV_FACTIONS"},
        {key = "commandposts", labelKey = "ADMIN_NAV_COMMANDPOSTS"},
    }},
}

local function GetAvailableUsergroups(exclude)
    local groups = {}
    local seen = {}
    for _, ply in ipairs(player.GetAll()) do
        local g = ply:GetUserGroup()
        if g and g ~= "" and not seen[g] and not exclude[g] then
            seen[g] = true
            table.insert(groups, g)
        end
    end
    for _, g in ipairs({"superadmin", "admin", "operator", "user"}) do
        if not seen[g] and not exclude[g] then
            seen[g] = true
            table.insert(groups, g)
        end
    end
    table.sort(groups)
    return groups
end

local function GetCfg(key) return BattleGrid:GetConfig(key) end
local function GetCfgNum(key) return BattleGrid:GetConfigNumber(key) end
local function GetCfgBool(key) return BattleGrid:GetConfigBool(key) end

local function SetCfg(key, value)
    BattleGrid._pendingCfg[key] = tostring(value)
    timer.Create("BattleGrid.CfgDebounce", 0.35, 1, function()
        for k, v in pairs(BattleGrid._pendingCfg) do
            BattleGrid.Net:SendJSONToServer("AdminSetConfig", { key = k, value = v })
        end
        table.Empty(BattleGrid._pendingCfg)
    end)
end

local function ConfirmDialog(text, onYes)
    KF.Menu.Query(text, BattleGrid:L("ADMIN_CONFIRM"), {
        titleFont = BattleGrid.F("section"),
        textFont = BattleGrid.F("body"),
        btnFont = BattleGrid.FB("small"),
        yesText = BattleGrid:L("ADMIN_YES"),
        noText = BattleGrid:L("ADMIN_NO"),
        colors = {
            Accent = BattleGrid.C("Accent"),
            AccentHover = BattleGrid.C("AccentHover"),
            BG = BattleGrid.C("Background"),
            Border = BattleGrid.C("Border"),
            Text = BattleGrid.C("TextPrimary"),
            Error = BattleGrid.C("Error"),
            ErrorHover = BattleGrid.C("ErrorHover"),
            TextBright = BattleGrid.C("TextPrimary"),
        },
        onYes = onYes,
    })
end

local _activeSection = "general"
local _adminFrame = nil
local _rebuildContent = nil
local _sidebarButtons = {}

local MakeScroll = BattleGrid.MakeScroll
local FormHeader = BattleGrid.FormHeader
local FormSpacer = BattleGrid.FormSpacer

local function AdminButton(parent, label, style, onClick, tall, margin)
    return BattleGrid:CreateButton(parent, label, style, onClick, {
        tall = tall or 32,
        dock = TOP,
        margin = { 0, margin and margin[1] or 10, 0, margin and margin[2] or 6 },
    })
end

local function NavigateTo(section)
    _activeSection = section
    for key, btn in pairs(_sidebarButtons) do
        if IsValid(btn) then btn._isActive = (key == section) end
    end
    if _rebuildContent then _rebuildContent() end
end

local function BackButton(parent, targetSection, label)
    local btn = AdminButton(parent, "← " .. label, "ghost", function()
        NavigateTo(targetSection)
    end, 28, {0, 6})
    return btn
end

local function PaintCategoryHeader(s, w, h, group, items, assignedSet)
    KF.Anim.UpdateHoverLerp(s)
    draw.RoundedBox(4, 0, 0, w, h,
        KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("PanelDark"), BattleGrid.C("PanelHover")))

    local ax, ay = S(14), h / 2
    surface.SetDrawColor(KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("TextMuted"), BattleGrid.C("Accent")))
    draw.NoTexture()
    if s._expanded then
        surface.DrawPoly({{x = ax - 4, y = ay - 2}, {x = ax + 4, y = ay - 2}, {x = ax, y = ay + 4}})
    else
        surface.DrawPoly({{x = ax - 2, y = ay - 4}, {x = ax + 3, y = ay}, {x = ax - 2, y = ay + 4}})
    end

    draw.SimpleText(group.name .. " (" .. #items .. ")", BattleGrid.F("small"), S(28), h / 2,
        BattleGrid.C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local assigned = 0
    for _, item in ipairs(items) do
        if assignedSet[item.id] then assigned = assigned + 1 end
    end
    draw.SimpleText(assigned .. "/" .. #items, BattleGrid.F("small"), w - S(8), h / 2,
        assigned > 0 and BattleGrid.C("Accent") or BattleGrid.C("TextMuted"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

local function BuildItemCheckbox(parent, item, assignedSet, targetList, onSave)
    local cb = vgui.Create("KF.Checkbox", parent)
    if cb.SetAddon then cb:SetAddon(AID) end
    cb:SetLabel(item.name)
    DButton.SetText(cb, "")
    cb:SetChecked(assignedSet[item.id] or false)
    cb._checked = assignedSet[item.id] or false
    cb.OnChange = function(s, val)
        BattleGrid:PlaySound("Click")
        s._checked = val
        if val then
            if not assignedSet[item.id] then
                targetList[#targetList + 1] = item.id
                assignedSet[item.id] = true
            end
        else
            for k, id in ipairs(targetList) do
                if id == item.id then table.remove(targetList, k); break end
            end
            assignedSet[item.id] = nil
        end
        if onSave then onSave() end
    end
    return cb
end

local function BuildItemFlowPanel(parentCard, groups, itemsKey, assignedSet, targetList, onSave)
    for _, group in ipairs(groups) do
        local items = group[itemsKey]
        local rowH = S(24)
        local contentH = math.ceil(#items / 2) * rowH + S(8)

        local catHeader = vgui.Create("DButton", parentCard)
        catHeader:Dock(TOP)
        catHeader:SetTall(S(30))
        catHeader:DockMargin(0, S(2), 0, 0)
        catHeader:SetText("")
        catHeader:SetCursor("hand")
        catHeader._expanded = false
        catHeader.Paint = function(s, w, h) PaintCategoryHeader(s, w, h, group, items, assignedSet) end
        catHeader.OnCursorEntered = function() KF.Helpers.PlaySound(BattleGrid.Sounds.Hover) end

        local grid = vgui.Create("DPanel", parentCard)
        grid:Dock(TOP)
        grid:SetTall(0)
        grid:DockMargin(S(4), 0, 0, 0)
        grid:SetVisible(false)
        grid.Paint = function(_, w, h)
            draw.RoundedBox(0, 0, 0, w, h, KF.UI.ColorAlpha(BattleGrid.C("Panel"), 60))
        end

        local checkboxes = {}
        for i, item in ipairs(items) do
            checkboxes[i] = BuildItemCheckbox(grid, item, assignedSet, targetList, onSave)
        end

        grid.PerformLayout = function(_, w)
            local colW = math.floor((w - S(8)) / 2)
            for i, cb in ipairs(checkboxes) do
                local col = (i - 1) % 2
                local row = math.floor((i - 1) / 2)
                cb:SetPos(col * colW + S(4), row * rowH + S(4))
                cb:SetSize(colW, rowH - 2)
            end
        end

        catHeader.DoClick = function()
            BattleGrid:PlaySound("Click")
            catHeader._expanded = not catHeader._expanded
            grid:SetVisible(catHeader._expanded)
            grid:SetTall(catHeader._expanded and contentH or 0)
            grid:InvalidateParent(true)
            parentCard:InvalidateLayout(true)
        end
    end
end

local function BuildGeneral(scroll)
    local languages = {}
    for _, lang in ipairs(KF.Lang.GetAvailableList(AID)) do
        languages[#languages + 1] = { lang.value, lang.name }
    end
    BattleGrid:CreateDropdown(scroll, BattleGrid:L("ADMIN_LANGUAGE"), languages, GetCfg("language"), function(v) SetCfg("language", v) end)

    FormHeader(scroll, BattleGrid:L("ADMIN_OPEN_KEY"))
    BattleGrid:CreateKeybindCapture(scroll, GetCfgNum("open_key"), "M", function(key) SetCfg("open_key", tostring(key)) end, BattleGrid:L("ADMIN_OPEN_KEY"))

    FormHeader(scroll, BattleGrid:L("ADMIN_BLOCKED_MAPS"), BattleGrid:L("ADMIN_BLOCKED_MAPS_DESC"))
    BattleGrid:CreateTextInput(scroll, BattleGrid:L("ADMIN_BLOCKED_MAPS_PH"), GetCfg("blocked_maps"), function(v) SetCfg("blocked_maps", v) end)

    FormHeader(scroll, BattleGrid:L("ADMIN_ANNOUNCEMENTS"))
    BattleGrid:CreateToggle(scroll, BattleGrid:L("ADMIN_ANNOUNCE_MARKERS"), GetCfgBool("announce_public_markers"), function(v) SetCfg("announce_public_markers", v and "1" or "0") end)

    FormHeader(scroll, BattleGrid:L("ADMIN_MAP_CAMERA"))
    BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_CAM_DISTANCE"), GetCfgNum("map_camera_distance"), function(v) SetCfg("map_camera_distance", tostring(math.floor(v))) end)
    BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_DEFAULT_ZOOM"), GetCfgNum("map_default_zoom"), function(v) SetCfg("map_default_zoom", tostring(math.floor(v))) end)
    BattleGrid:CreateSlider(scroll, BattleGrid:L("ADMIN_OVERLAY_ALPHA"), 0, 255, 0, GetCfgNum("map_overlay_alpha"), function(v) SetCfg("map_overlay_alpha", tostring(math.floor(v))) end)

    FormHeader(scroll, BattleGrid:L("ADMIN_RADAR_MAP"), BattleGrid:L("ADMIN_RADAR_MAP_DESC"))
    BattleGrid:CreateToggle(scroll, BattleGrid:L("ADMIN_RADAR_MAP_ENABLED"), GetCfgBool("radar_map_enabled"), function(v) SetCfg("radar_map_enabled", v and "1" or "0") end)
end

local function BuildPermissions(scroll)
    FormHeader(scroll, BattleGrid:L("ADMIN_DEFAULT_LIMITS"))
    BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_PUBLIC_WP_LIMIT"), GetCfgNum("default_public_waypoints"), function(v) SetCfg("default_public_waypoints", tostring(math.floor(v))) end)
    BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_PUBLIC_AREA_LIMIT"), GetCfgNum("default_public_areas"), function(v) SetCfg("default_public_areas", tostring(math.floor(v))) end)

    FormHeader(scroll, BattleGrid:L("ADMIN_GROUP_LIMITS"), BattleGrid:L("ADMIN_GROUP_LIMITS_DESC"))

    local groupLimitsRaw = GetCfg("group_limits")
    local groupLimits = util.JSONToTable(groupLimitsRaw) or {}

    local groupList = vgui.Create("DPanel", scroll)
    groupList:Dock(TOP)
    groupList.Paint = function() end
    groupList.PerformLayout = function(s) s:SizeToChildren(false, true) end

    local groupDropdown, addGroupWP, addGroupArea

    local function GetSelectedGroup()
        return IsValid(groupDropdown) and groupDropdown:GetSelectedValue() or nil
    end

    local function SetSelectedGroup(grp)
        if IsValid(groupDropdown) then
            if grp then
                groupDropdown:SetValue(grp)
            else
                groupDropdown._selectedIdx = 0
                groupDropdown._selectedText = ""
                groupDropdown._selectedValue = nil
            end
        end
    end

    local function RebuildGroupRows()
        groupList:Clear()
        local hasGroups = false

        for groupName, limits in SortedPairs(groupLimits) do
            hasGroups = true
            local row = vgui.Create("DButton", groupList)
            row:Dock(TOP)
            row:SetTall(S(T.Size.ROW_H))
            row:DockMargin(0, 0, 0, S(2))
            row:SetText("")
            row:SetCursor("hand")

            row.Paint = function(s, w, h)
                KF.Anim.UpdateHoverLerp(s)
                draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelLight"))
                if s._hoverLerp > 0.05 then
                    surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("Accent"), s._hoverLerp * 30))
                    surface.DrawRect(0, 0, w, h)
                end
                if GetSelectedGroup() == groupName then
                    surface.SetDrawColor(BattleGrid.C("Accent"))
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
                draw.SimpleText(groupName, BattleGrid.F("body"), S(12), h / 2, BattleGrid.C("TextAccent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(BattleGrid:L("ADMIN_GROUP_LIMITS_FMT", limits.waypoints or 5, limits.areas or 4), BattleGrid.F("small"), w * 0.55, h / 2, BattleGrid.C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            row.DoClick = function()
                SetSelectedGroup(groupName)
                if IsValid(addGroupWP) then addGroupWP:SetValue(tostring(limits.waypoints or 5)) end
                if IsValid(addGroupArea) then addGroupArea:SetValue(tostring(limits.areas or 4)) end
            end

            local delBtn = BattleGrid:CreateIconButton(row, "×", BattleGrid.C("Error"), function()
                groupLimits[groupName] = nil
                SetCfg("group_limits", util.TableToJSON(groupLimits))
                if IsValid(addGroupWP) then addGroupWP:SetValue("") end
                if IsValid(addGroupArea) then addGroupArea:SetValue("") end
                RebuildGroupRows()
            end)
        end

        if not hasGroups then
            BattleGrid:CreateEmptyState(groupList, BattleGrid:L("ADMIN_NO_GROUPS"))
        end

        groupList:SizeToChildren(false, true)
    end

    local function DoAddGroup()
        local grp = GetSelectedGroup()
        if not grp or grp == "" then return end
        groupLimits[grp] = {
            waypoints = math.max(0, tonumber(IsValid(addGroupWP) and addGroupWP:GetValue() or "") or 5),
            areas = math.max(0, tonumber(IsValid(addGroupArea) and addGroupArea:GetValue() or "") or 4),
        }
        SetCfg("group_limits", util.TableToJSON(groupLimits))
        SetSelectedGroup(nil)
        if IsValid(addGroupWP) then addGroupWP:SetValue("") end
        if IsValid(addGroupArea) then addGroupArea:SetValue("") end
        RebuildGroupRows()
    end

    RebuildGroupRows()

    FormSpacer(scroll)

    local addContainer = vgui.Create("DPanel", scroll)
    addContainer:Dock(TOP)
    addContainer:DockMargin(0, S(6), 0, 0)
    addContainer.Paint = function() end

    groupDropdown = vgui.Create("KF.PopupDropdown", addContainer)
    groupDropdown:Dock(TOP)
    groupDropdown:SetTall(S(T.Size.INPUT_H))
    groupDropdown:SetAddon(AID)
    groupDropdown:SetPlaceholder(BattleGrid:L("ADMIN_GROUP_NAME"))
    groupDropdown:SetSound(BattleGrid.Sounds.Click)
    groupDropdown:SetHoverSound(BattleGrid.Sounds.Hover)

    local baseOpenMenu = groupDropdown.OpenMenu
    groupDropdown.OpenMenu = function(self)
        self:Clear()
        local available = GetAvailableUsergroups(groupLimits)
        for _, gname in ipairs(available) do
            self:AddChoice(gname, gname)
        end
        if #available == 0 then return end
        baseOpenMenu(self)
    end

    groupDropdown.OnSelect = function(_, idx, text, val)
        SetSelectedGroup(val or text)
    end

    local limitsRow = vgui.Create("DPanel", addContainer)
    limitsRow:Dock(TOP)
    limitsRow:SetTall(S(T.Size.INPUT_H))
    limitsRow:DockMargin(0, S(6), 0, 0)
    limitsRow.Paint = function() end

    addGroupWP = vgui.Create("KF.TextInput", limitsRow)
    addGroupWP:SetAddon(AID)
    addGroupWP:Dock(LEFT)
    addGroupWP:SetWide(S(120))
    addGroupWP:SetPlaceholderText(BattleGrid:L("ADMIN_GROUP_WP"))
    addGroupWP:SetNumeric(true)
    addGroupWP.OnEnter = function() DoAddGroup() end

    addGroupArea = vgui.Create("KF.TextInput", limitsRow)
    addGroupArea:SetAddon(AID)
    addGroupArea:Dock(LEFT)
    addGroupArea:SetWide(S(120))
    addGroupArea:DockMargin(S(6), 0, 0, 0)
    addGroupArea:SetPlaceholderText(BattleGrid:L("ADMIN_GROUP_AREAS"))
    addGroupArea:SetNumeric(true)
    addGroupArea.OnEnter = function() DoAddGroup() end

    local addGroupBtn = vgui.Create("DButton", limitsRow)
    addGroupBtn:Dock(LEFT)
    addGroupBtn:SetWide(S(60))
    addGroupBtn:DockMargin(S(6), 0, 0, 0)
    addGroupBtn:SetText("")
    addGroupBtn:SetCursor("hand")
    addGroupBtn.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        local bg = KF.UI.LerpColor(s._hoverLerp, BattleGrid.C("Accent"), BattleGrid.C("AccentHover"))
        draw.RoundedBox(4, 0, 0, w, h, bg)
        draw.SimpleText("+", BattleGrid.FB("button"), w / 2, h / 2, BattleGrid.C("PanelDark"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    addGroupBtn.DoClick = function() BattleGrid:PlaySound("Click"); DoAddGroup() end

    addContainer:SetTall(S(T.Size.INPUT_H) + S(6) + S(T.Size.INPUT_H))
end

local function BuildJammers(scroll)
    FormHeader(scroll, BattleGrid:L("ADMIN_JAMMER"), BattleGrid:L("ADMIN_JAMMER_MODEL_DESC"))
    BattleGrid:CreateTextInput(scroll, BattleGrid:L("ADMIN_MODEL_PATH_PH"), GetCfg("jammer_model"), function(v) SetCfg("jammer_model", v) end)
    BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_JAMMER_HEALTH"), GetCfgNum("jammer_default_health"), function(v) SetCfg("jammer_default_health", tostring(math.floor(v))) end)
    BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_JAMMER_RADIUS"), GetCfgNum("jammer_default_radius"), function(v) SetCfg("jammer_default_radius", tostring(math.floor(v))) end)
    BattleGrid:CreateToggle(scroll, BattleGrid:L("ADMIN_JAMMER_HACKABLE"), GetCfgBool("jammer_hackable"), function(v) SetCfg("jammer_hackable", v and "1" or "0") end)
    BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_JAMMER_HACK_TIME"), GetCfgNum("jammer_hack_time"), function(v) SetCfg("jammer_hack_time", tostring(math.floor(v))) end)
    BattleGrid:CreateNumberInput(scroll, BattleGrid:L("ADMIN_JAMMER_SHOCK_DMG"), GetCfgNum("jammer_shock_damage"), function(v) SetCfg("jammer_shock_damage", tostring(math.floor(v))) end)
    BattleGrid:CreateDropdown(scroll, BattleGrid:L("ADMIN_JAMMER_DIFF_LABEL"), BattleGrid:JammerDifficultyChoices(), GetCfg("jammer_default_difficulty"), function(v) SetCfg("jammer_default_difficulty", v) end)

    FormHeader(scroll, BattleGrid:L("ADMIN_JAMMER_HACK_WHITELIST"), BattleGrid:L("ADMIN_JAMMER_HACK_WL_DESC"))

    local hackWhitelist = util.JSONToTable(GetCfg("jammer_hack_whitelist")) or {}
    local hackWLSet = {}
    for _, jid in ipairs(hackWhitelist) do hackWLSet[jid] = true end

    local hackWLPanel = vgui.Create("DPanel", scroll)
    hackWLPanel:Dock(TOP)
    hackWLPanel:DockMargin(0, S(6), 0, 0)
    hackWLPanel.Paint = function() end
    hackWLPanel.PerformLayout = function(s) s:SizeToChildren(false, true) end

    local function RebuildHackWhitelist()
        hackWLPanel:Clear()
        local groups = BattleGrid:GetFrameworkJobs()
        if #groups == 0 then
            BattleGrid:CreateEmptyState(hackWLPanel, BattleGrid:L("ADMIN_JAMMER_HACK_WL_EMPTY"))
            hackWLPanel:SizeToChildren(false, true)
            return
        end
        BuildItemFlowPanel(hackWLPanel, groups, "jobs", hackWLSet, hackWhitelist, function()
            SetCfg("jammer_hack_whitelist", util.TableToJSON(hackWhitelist))
        end)
        hackWLPanel:SizeToChildren(false, true)
        timer.Simple(0, function()
            if IsValid(hackWLPanel) then hackWLPanel:InvalidateLayout(true); hackWLPanel:SizeToChildren(false, true) end
        end)
    end

    RebuildHackWhitelist()

    FormHeader(scroll, BattleGrid:L("ADMIN_JAMMER_LIST"), BattleGrid:L("ADMIN_JAMMER_LIST_DESC"))

    local jammerListPanel = vgui.Create("DPanel", scroll)
    jammerListPanel:Dock(TOP)
    jammerListPanel:DockMargin(0, S(6), 0, 0)
    jammerListPanel.Paint = function() end
    jammerListPanel.PerformLayout = function(s) s:SizeToChildren(false, true) end

    local function RebuildJammerList()
        jammerListPanel:Clear()
        local jammers = BattleGrid.Cache.Jammers or {}
        if #jammers == 0 then
            BattleGrid:CreateEmptyState(jammerListPanel, BattleGrid:L("ADMIN_JAMMER_NONE"))
            jammerListPanel:SetTall(S(80))
        else
            for _, j in ipairs(jammers) do
                local row = vgui.Create("DPanel", jammerListPanel)
                row:Dock(TOP)
                row:SetTall(S(48))
                row:DockMargin(0, 0, 0, S(2))
                row.Paint = function(_, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelLight"))
                    draw.SimpleText(BattleGrid:L("ADMIN_JAMMER") .. " #" .. (j.entIndex or "?"), BattleGrid.F("body"), S(8), h / 2 - S(6), BattleGrid.C("TextAccent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local posStr = string.format("%.0f, %.0f, %.0f", j.pos.x, j.pos.y, j.pos.z)
                    local infoStr = BattleGrid:L("ADMIN_JAMMER_RADIUS_SHORT") .. math.floor(j.radius or 0)
                    if j.hackable then infoStr = infoStr .. "  •  " .. BattleGrid:L("ADMIN_JAMMER_HACKABLE_PH") end
                    draw.SimpleText(infoStr .. "  •  " .. posStr, BattleGrid.F("small"), S(8), h / 2 + S(8), BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                if j.entIndex then
                    BattleGrid:CreateIconButton(row, "✎", BattleGrid.C("Accent"), function()
                        local ent = Entity(j.entIndex)
                        if IsValid(ent) then BattleGrid:OpenJammerPropertyEditor(ent) end
                    end)
                end
            end
            jammerListPanel:SetTall(#jammers * (S(48) + S(2)))
        end
    end

    RebuildJammerList()

    hook.Add("BattleGrid.JammersUpdated", "BattleGrid.AdminJammerRefresh", function()
        if not IsValid(jammerListPanel) then hook.Remove("BattleGrid.JammersUpdated", "BattleGrid.AdminJammerRefresh") return end
        RebuildJammerList()
    end)
end

local function BuildWaypoints(scroll)
    FormHeader(scroll, BattleGrid:L("ADMIN_WP_LIST"))

    local RebuildAdminWaypointList
    local wpAdminFilter = ""
    BattleGrid:CreateTextInput(scroll, BattleGrid:L("ADMIN_SEARCH"), "", function(v) wpAdminFilter = string.lower(v); RebuildAdminWaypointList() end)
    FormSpacer(scroll)

    local wpAdminList = vgui.Create("DPanel", scroll)
    wpAdminList:Dock(TOP)
    wpAdminList.Paint = function() end
    wpAdminList.PerformLayout = function(s) s:SizeToChildren(false, true) end

    RebuildAdminWaypointList = function()
        wpAdminList:Clear()
        local filtered = {}
        for _, wp in ipairs(BattleGrid.Cache.Waypoints) do
            if wpAdminFilter == "" or string.find(string.lower(wp.name or ""), wpAdminFilter, 1, true) or string.find(string.lower(wp.state or ""), wpAdminFilter, 1, true) then
                table.insert(filtered, wp)
            end
        end
        if #filtered == 0 then
            BattleGrid:CreateEmptyState(wpAdminList, BattleGrid:L("ADMIN_NO_WAYPOINTS"))
        else
            for _, wp in ipairs(filtered) do
                local row = vgui.Create("DPanel", wpAdminList)
                row:Dock(TOP)
                row:SetTall(S(40))
                row:DockMargin(0, 0, 0, S(2))
                row.Paint = function(_, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelLight"))
                    if wp.icon and wp.icon ~= "" then BattleGrid:DrawIcon(wp.icon, S(8), (h - S(20)) / 2, S(20), S(20), wp.color) end
                    draw.SimpleText(wp.name, BattleGrid.F("body"), S(36), h / 2 - S(6), wp.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local stateStr = wp.state or ""
                    local posStr = string.format("%.0f, %.0f, %.0f", wp.pos.x, wp.pos.y, wp.pos.z)
                    draw.SimpleText(stateStr .. "  •  " .. posStr, BattleGrid.F("small"), S(36), h / 2 + S(8), BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                BattleGrid:CreateIconButton(row, "×", BattleGrid.C("Error"), function() if wp.identifier then BattleGrid:RequestDeleteWaypoint(wp.identifier) end end)
                local editBtn = BattleGrid:CreateIconButton(row, "✎", BattleGrid.C("Accent"), function() BattleGrid:OpenWaypointEditor(wp) end)
                editBtn:DockMargin(0, 0, S(2), 0)
            end
        end
        wpAdminList:SizeToChildren(false, true)
    end

    RebuildAdminWaypointList()

    hook.Add("BattleGrid.WaypointsUpdated", "BattleGrid.AdminWPMgmtRefresh", function()
        if not IsValid(wpAdminList) then hook.Remove("BattleGrid.WaypointsUpdated", "BattleGrid.AdminWPMgmtRefresh") return end
        RebuildAdminWaypointList()
    end)

    FormSpacer(scroll)
    AdminButton(scroll, BattleGrid:L("ADMIN_DELETE_ALL_WP"), "danger", function()
        ConfirmDialog(BattleGrid:L("ADMIN_CONFIRM_DELETE_WP"), function()
            BattleGrid.Net:SendToServer("AdminDeleteAll", function() net.WriteString("waypoints") end)
        end)
    end, 32, {6, 10})
end

local function BuildAreas(scroll)
    FormHeader(scroll, BattleGrid:L("ADMIN_AREAS"))

    local RebuildAreaList
    local searchFilter = ""
    BattleGrid:CreateTextInput(scroll, BattleGrid:L("ADMIN_SEARCH"), "", function(v) searchFilter = string.lower(v); RebuildAreaList() end)
    FormSpacer(scroll)

    local areaList = vgui.Create("DPanel", scroll)
    areaList:Dock(TOP)
    areaList.Paint = function() end
    areaList.PerformLayout = function(s) s:SizeToChildren(false, true) end

    RebuildAreaList = function()
        areaList:Clear()
        local filtered = {}
        for _, area in ipairs(BattleGrid.Cache.Areas) do
            if searchFilter == "" or string.find(string.lower(area.name), searchFilter, 1, true) or string.find(string.lower(area.type or ""), searchFilter, 1, true) then
                table.insert(filtered, area)
            end
        end
        if #filtered == 0 then
            BattleGrid:CreateEmptyState(areaList, BattleGrid:L("ADMIN_NO_AREAS"))
        else
            for _, area in ipairs(filtered) do
                local row = vgui.Create("DPanel", areaList)
                row:Dock(TOP)
                row:SetTall(S(36))
                row:DockMargin(0, 0, 0, S(2))
                row.Paint = function(_, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelLight"))
                    draw.RoundedBox(2, S(6), (h - S(12)) / 2, S(12), S(12), area.color)
                    local nameText = BattleGrid:TruncateToWidth(area.name, w * 0.5 - S(28) - S(8), BattleGrid.F("body"))
                    draw.SimpleText(nameText, BattleGrid.F("body"), S(28), h / 2, area.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(area.type or "", BattleGrid.F("small"), w * 0.5, h / 2, BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(area.state or "", BattleGrid.F("small"), w * 0.7, h / 2, BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                BattleGrid:CreateIconButton(row, "×", BattleGrid.C("Error"), function() if area.identifier then BattleGrid:RequestDeleteArea(area.identifier) end end)
            end
        end
        areaList:SizeToChildren(false, true)
    end

    RebuildAreaList()

    hook.Add("BattleGrid.AreasUpdated", "BattleGrid.AdminAreaRefresh", function()
        if not IsValid(areaList) then hook.Remove("BattleGrid.AreasUpdated", "BattleGrid.AdminAreaRefresh") return end
        RebuildAreaList()
    end)

    FormSpacer(scroll)
    AdminButton(scroll, BattleGrid:L("ADMIN_DELETE_ALL_AREAS"), "danger", function()
        ConfirmDialog(BattleGrid:L("ADMIN_CONFIRM_DELETE_AREAS"), function()
            BattleGrid.Net:SendToServer("AdminDeleteAll", function() net.WriteString("areas") end)
        end)
    end, 32, {6, 10})
end

local function BuildIcons(scroll)
    FormHeader(scroll, BattleGrid:L("ADMIN_CUSTOM_ICONS"), BattleGrid:L("ADMIN_CUSTOM_ICONS_DESC"))

    local customIconsRaw = GetCfg("custom_icons")
    local customIcons = util.JSONToTable(customIconsRaw) or {}

    local customIconList = vgui.Create("DPanel", scroll)
    customIconList:Dock(TOP)
    customIconList.Paint = function() end
    customIconList.PerformLayout = function(s) s:SizeToChildren(false, true) end

    local function RebuildCustomIconList()
        customIconList:Clear()
        if #customIcons == 0 then
            BattleGrid:CreateEmptyState(customIconList, BattleGrid:L("ADMIN_NO_CUSTOM_ICONS"))
        else
            for idx, iconPath in ipairs(customIcons) do
                local row = vgui.Create("DPanel", customIconList)
                row:Dock(TOP)
                row:SetTall(S(36))
                row:DockMargin(0, 0, 0, S(2))
                row.Paint = function(_, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelLight"))
                    BattleGrid:DrawIcon(iconPath, S(6), (h - S(20)) / 2, S(20), S(20), BattleGrid.C("TextPrimary"))
                    local pathText = BattleGrid:TruncateToWidth(iconPath, w - S(32) - S(40), BattleGrid.F("small"))
                    draw.SimpleText(pathText, BattleGrid.F("small"), S(32), h / 2, BattleGrid.C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                BattleGrid:CreateIconButton(row, "×", BattleGrid.C("Error"), function()
                    table.remove(customIcons, idx)
                    SetCfg("custom_icons", util.TableToJSON(customIcons))
                    if BattleGrid.SyncCustomIcons then BattleGrid:SyncCustomIcons() end -- Funktion fehlt in v1.2.1, Icons kommen direkt aus der Config
                    RebuildCustomIconList()
                end)
            end
        end
        customIconList:SizeToChildren(false, true)
    end

    RebuildCustomIconList()

    FormSpacer(scroll)

    local iconPathInput = BattleGrid:CreateTextInput(scroll, BattleGrid:L("ADMIN_ICON_PATH"), "", function() end)

    AdminButton(scroll, BattleGrid:L("ADMIN_ICON_ADD"), "primary", function()
        local path = iconPathInput:GetValue()
        if not path or path == "" then return end
        path = string.Trim(path)
        if #path > 256 then return end
        for _, existing in ipairs(customIcons) do
            if existing == path then return end
        end
        table.insert(customIcons, path)
        SetCfg("custom_icons", util.TableToJSON(customIcons))
        if BattleGrid.SyncCustomIcons then BattleGrid:SyncCustomIcons() end -- Funktion fehlt in v1.2.1, Icons kommen direkt aus der Config
        iconPathInput:SetValue("")
        RebuildCustomIconList()
    end, 32, {6, 6})

    FormHeader(scroll, BattleGrid:L("ADMIN_FACTORY_ICONS"), BattleGrid:L("ADMIN_FACTORY_ICONS_DESC"))

    local factoryGrid = vgui.Create("DPanel", scroll)
    factoryGrid:Dock(TOP)
    factoryGrid.Paint = function() end

    local sidebarW = S(200)
    local scrW = ScrW()
    local fIconSize = S(28)
    local fIconPad = S(4)
    local fCols = math.floor((scrW - sidebarW - S(24)) / (fIconSize + fIconPad))
    if fCols < 1 then fCols = 8 end

    for idx, iconPath in ipairs(BattleGrid.DefaultIcons) do
        local ibtn = vgui.Create("DPanel", factoryGrid)
        ibtn:SetSize(fIconSize, fIconSize)
        local r = math.floor((idx - 1) / fCols)
        local c = (idx - 1) % fCols
        ibtn:SetPos(c * (fIconSize + fIconPad), r * (fIconSize + fIconPad))
        ibtn.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelLight"))
            BattleGrid:DrawIcon(iconPath, 4, 4, w - 8, h - 8, BattleGrid.C("TextPrimary"))
        end
    end

    local totalRows = math.ceil(#BattleGrid.DefaultIcons / fCols)
    factoryGrid:SetTall(totalRows * (fIconSize + fIconPad) + fIconPad)
end

local _editFactions = {}
local _editingFactionData = nil

local function SyncEditFactions()
    _editFactions = {}
    for _, f in ipairs(BattleGrid.FactionList) do
        table.insert(_editFactions, {
            id = f.id, name = f.name, desc = f.desc or "",
            icon = f.icon or "", color = BattleGrid.ColorCopy(f.color),
            jobs = table.Copy(f.jobs or {}), npcs = table.Copy(f.npcs or {}),
        })
    end
end

local function SaveFactions()
    local payload = {}
    for _, f in ipairs(_editFactions) do
        table.insert(payload, { id = f.id, name = f.name, desc = f.desc, icon = f.icon, color = { r = f.color.r, g = f.color.g, b = f.color.b }, jobs = f.jobs, npcs = f.npcs })
    end
    SetCfg("factions_data", util.TableToJSON(payload))
end

local function BuildFactions(scroll)
    FormHeader(scroll, BattleGrid:L("ADMIN_FACTION_SYSTEM"), BattleGrid:L("ADMIN_FACTION_SYSTEM_DESC"))

    local factionEnabled = GetCfgBool("factions_enabled")
    local factionBody

    BattleGrid:CreateToggle(scroll, BattleGrid:L("ADMIN_FACTION_ENABLED"), factionEnabled, function(v)
        SetCfg("factions_enabled", v and "1" or "0")
        if IsValid(factionBody) then
            factionBody:SetVisible(v)
            factionBody:InvalidateParent(true)
        end
    end)

    factionBody = vgui.Create("DPanel", scroll)
    factionBody:Dock(TOP)
    factionBody.Paint = function() end
    factionBody.PerformLayout = function(s) s:SizeToChildren(false, true) end
    factionBody:SetVisible(factionEnabled)

    SyncEditFactions()

    FormHeader(factionBody, BattleGrid:L("ADMIN_FACTION_LIST"))

    if #_editFactions == 0 then
        BattleGrid:CreateEmptyState(factionBody, BattleGrid:L("ADMIN_FACTION_NONE"))
    else
        for idx, faction in ipairs(_editFactions) do
            local row = vgui.Create("DPanel", factionBody)
            row:Dock(TOP)
            row:SetTall(S(48))
            row:DockMargin(0, 0, 0, S(2))
            row.Paint = function(_, w, h)
                draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelLight"))
                surface.SetDrawColor(faction.color or BattleGrid.C("Accent"))
                surface.DrawRect(0, 0, 3, h)
                if faction.icon and faction.icon ~= "" then
                    BattleGrid:DrawIcon(faction.icon, S(12), (h - S(20)) / 2, S(20), S(20), faction.color or BattleGrid.C("TextPrimary"))
                else
                    draw.RoundedBox(S(4), S(12), (h - S(20)) / 2, S(20), S(20), faction.color or BattleGrid.C("TextMuted"))
                end
                draw.SimpleText(faction.name, BattleGrid.F("body"), S(40), h / 2 - S(6), faction.color or BattleGrid.C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                local info = string.format(BattleGrid:L("ADMIN_FACTION_JOB_COUNT"), #faction.jobs)
                if faction.desc ~= "" then info = faction.desc end
                draw.SimpleText(info, BattleGrid.F("small"), S(40), h / 2 + S(8), BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            BattleGrid:CreateIconButton(row, "×", BattleGrid.C("Error"), function()
                table.remove(_editFactions, idx)
                SaveFactions()
                NavigateTo("factions")
            end)

            BattleGrid:CreateEditButton(row, function()
                _editingFactionData = { idx = idx, faction = faction }
                NavigateTo("faction_edit")
            end)
        end
    end

    FormSpacer(factionBody)

    AdminButton(factionBody, BattleGrid:L("ADMIN_FACTION_ADD"), "primary", function()
        _editingFactionData = nil
        NavigateTo("faction_edit")
    end, 32, {6, 4})

    if BattleGrid.Compat.HasBF2F4() then
        AdminButton(factionBody, BattleGrid:L("ADMIN_FACTION_IMPORT_F4"), "success", function()
            local imported = BattleGrid.Compat.ImportBF2F4Factions()
            if not imported or #imported == 0 then
                BattleGrid:Toast(BattleGrid:L("ADMIN_FACTION_IMPORT_EMPTY"), "warning", 3)
                return
            end
            SyncEditFactions()
            local existing = {}
            for _, f in ipairs(_editFactions) do existing[string.lower(f.name)] = true end
            local added = 0
            for _, f in ipairs(imported) do
                if not existing[string.lower(f.name)] then
                    table.insert(_editFactions, {
                        id = f.id, name = f.name, desc = f.desc,
                        icon = f.icon, color = BattleGrid.ColorCopy(f.color),
                        jobs = f.jobs, npcs = {},
                    })
                    added = added + 1
                end
            end
            SaveFactions()
            NavigateTo("factions")
            BattleGrid:Toast(string.format(BattleGrid:L("ADMIN_FACTION_IMPORT_OK"), added), "success", 3)
        end, 32, {4, 6})
    end

    hook.Add("BattleGrid.FactionsUpdated", "BattleGrid.AdminFactionRefresh", function()
        if not IsValid(_adminFrame) then hook.Remove("BattleGrid.FactionsUpdated", "BattleGrid.AdminFactionRefresh") return end
        if _activeSection == "factions" and table.IsEmpty(BattleGrid._pendingCfg) then NavigateTo("factions") end
    end)
end

local function BuildFactionEditor(scroll)
    SyncEditFactions()

    local isEditing = _editingFactionData ~= nil
    local faction
    if isEditing then
        faction = _editFactions[_editingFactionData.idx]
        if not faction then NavigateTo("factions"); return end
    end

    BackButton(scroll, "factions", BattleGrid:L("ADMIN_NAV_FACTIONS"))

    local title = isEditing and (BattleGrid:L("ADMIN_FACTION_EDIT") .. ": " .. faction.name) or BattleGrid:L("ADMIN_FACTION_CREATE")
    FormHeader(scroll, title)

    local editName = isEditing and faction.name or ""
    local editDesc = isEditing and (faction.desc or "") or ""
    local editIcon = isEditing and (faction.icon or "") or ""
    local colorData = { color = BattleGrid.ColorCopy(isEditing and faction.color or BattleGrid.C("TextPrimary")) }

    local nameInput = BattleGrid:CreateTextInput(scroll, BattleGrid:L("ADMIN_FACTION_NAME_PH"), editName, function(v) editName = v end)
    local descInput = BattleGrid:CreateTextInput(scroll, BattleGrid:L("ADMIN_FACTION_DESC_PH"), editDesc, function(v) editDesc = v end)
    local iconInput = BattleGrid:CreateTextInput(scroll, BattleGrid:L("ADMIN_FACTION_ICON_PH"), editIcon, function(v) editIcon = v end)

    BattleGrid:CreateColorPresets(scroll, BattleGrid.Theme.PresetColors, colorData)

    if isEditing then
        FormHeader(scroll, BattleGrid:L("ADMIN_FACTION_JOBS"), BattleGrid:L("ADMIN_FACTION_JOBS_DESC"))

        local jobAssignPanel = vgui.Create("DPanel", scroll)
        jobAssignPanel:Dock(TOP)
        jobAssignPanel.Paint = function() end
        jobAssignPanel.PerformLayout = function(s) s:SizeToChildren(false, true) end

        local groups = BattleGrid:GetFrameworkJobs()
        if #groups == 0 then
            BattleGrid:CreateEmptyState(jobAssignPanel, BattleGrid:L("ADMIN_FACTION_NO_JOBS"))
        else
            local assignedSet = {}
            for _, jid in ipairs(faction.jobs) do assignedSet[jid] = true end
            BuildItemFlowPanel(jobAssignPanel, groups, "jobs", assignedSet, faction.jobs, SaveFactions)
        end
        jobAssignPanel:SizeToChildren(false, true)

        FormHeader(scroll, BattleGrid:L("ADMIN_FACTION_NPC_ASSIGN"), BattleGrid:L("ADMIN_FACTION_NPC_DESC"))

        local npcAssignPanel = vgui.Create("DPanel", scroll)
        npcAssignPanel:Dock(TOP)
        npcAssignPanel.Paint = function() end
        npcAssignPanel.PerformLayout = function(s) s:SizeToChildren(false, true) end

        if not faction.npcs then faction.npcs = {} end
        local npcGroups = BattleGrid:GetServerNPCs()
        if #npcGroups == 0 then
            BattleGrid:CreateEmptyState(npcAssignPanel, BattleGrid:L("ADMIN_FACTION_NPC_NONE"))
        else
            local npcSet = {}
            for _, nid in ipairs(faction.npcs) do npcSet[nid] = true end
            BuildItemFlowPanel(npcAssignPanel, npcGroups, "npcs", npcSet, faction.npcs, SaveFactions)
        end
        npcAssignPanel:SizeToChildren(false, true)
    end

    FormSpacer(scroll)

    AdminButton(scroll, isEditing and BattleGrid:L("ADMIN_FACTION_SAVE") or BattleGrid:L("ADMIN_FACTION_ADD"), "success", function()
        editName = IsValid(nameInput) and nameInput:GetValue() or editName
        editDesc = IsValid(descInput) and descInput:GetValue() or editDesc
        editIcon = IsValid(iconInput) and iconInput:GetValue() or editIcon
        if editName == "" then return end

        if isEditing and faction then
            faction.name = editName
            faction.desc = editDesc
            faction.icon = editIcon
            faction.color = BattleGrid.ColorCopy(colorData.color)
        else
            SyncEditFactions()
            local id = string.sub(string.lower(string.gsub(editName, "%s+", "_")), 1, 27) .. "_" .. string.sub(tostring(SysTime()), -4)
            table.insert(_editFactions, {
                id = id, name = editName, desc = editDesc,
                icon = editIcon, color = BattleGrid.ColorCopy(colorData.color),
                jobs = {}, npcs = {},
            })
        end

        SaveFactions()
        NavigateTo("factions")
    end, 32, {6, 2})

    if isEditing then
        AdminButton(scroll, BattleGrid:L("ADMIN_DELETE"), "danger", function()
            ConfirmDialog(BattleGrid:L("ADMIN_CONFIRM") .. "?", function()
                table.remove(_editFactions, _editingFactionData.idx)
                SaveFactions()
                NavigateTo("factions")
            end)
        end, 32, {4, 6})
    end
end

local _editingCP = nil

local function BuildCommandPosts(scroll)
    FormHeader(scroll, BattleGrid:L("ADMIN_CP_SYSTEM"), BattleGrid:L("ADMIN_CP_SYSTEM_DESC"))

    local cpEnabled = GetCfgBool("cp_enabled")
    local cpBody

    BattleGrid:CreateToggle(scroll, BattleGrid:L("ADMIN_CP_ENABLED"), cpEnabled, function(v)
        SetCfg("cp_enabled", v and "1" or "0")
        if IsValid(cpBody) then
            cpBody:SetVisible(v)
            cpBody:InvalidateParent(true)
        end
    end)

    cpBody = vgui.Create("DPanel", scroll)
    cpBody:Dock(TOP)
    cpBody.Paint = function() end
    cpBody.PerformLayout = function(s) s:SizeToChildren(false, true) end
    cpBody:SetVisible(cpEnabled)

    BattleGrid:CreateToggle(cpBody, BattleGrid:L("ADMIN_CP_RESPAWN_ENABLED"), GetCfgBool("cp_respawn_enabled"), function(v) SetCfg("cp_respawn_enabled", v and "1" or "0") end)
    BattleGrid:CreateToggle(cpBody, BattleGrid:L("ADMIN_CP_FAST_TRAVEL_ENABLED"), GetCfgBool("cp_fast_travel_enabled"), function(v) SetCfg("cp_fast_travel_enabled", v and "1" or "0") end)

    FormHeader(cpBody, BattleGrid:L("ADMIN_CP_FT_COST_HEADER"))
    BattleGrid:CreateNumberInput(cpBody, BattleGrid:L("ADMIN_CP_FT_COST"), GetCfgNum("cp_fast_travel_cost"), function(v) SetCfg("cp_fast_travel_cost", tostring(math.floor(v))) end)
    BattleGrid:CreateToggle(cpBody, BattleGrid:L("ADMIN_CP_FT_DIST_SCALE"), GetCfgBool("cp_fast_travel_dist_scale"), function(v) SetCfg("cp_fast_travel_dist_scale", v and "1" or "0") end)
    BattleGrid:CreateSlider(cpBody, BattleGrid:L("ADMIN_CP_FT_DIST_MULT"), 0.01, 1, 2, GetCfgNum("cp_fast_travel_dist_mult"), function(v) SetCfg("cp_fast_travel_dist_mult", tostring(math.Round(v, 2))) end)

    BattleGrid:CreateToggle(cpBody, BattleGrid:L("ADMIN_CP_ANNOUNCE"), GetCfgBool("cp_announce_captures"), function(v) SetCfg("cp_announce_captures", v and "1" or "0") end)

    FormHeader(cpBody, BattleGrid:L("ADMIN_CP_CAPTURE_CONFIG"))
    BattleGrid:CreateSlider(cpBody, BattleGrid:L("ADMIN_CP_TICK_RATE"), 0.1, 10, 1, GetCfgNum("cp_tick_rate"), function(v) SetCfg("cp_tick_rate", tostring(math.Round(v, 1))) end)
    BattleGrid:CreateSlider(cpBody, BattleGrid:L("ADMIN_CP_TICKS_TO_CAPTURE"), 1, 100, 0, GetCfgNum("cp_ticks_to_capture"), function(v) SetCfg("cp_ticks_to_capture", tostring(math.Round(v))) end)
    BattleGrid:CreateNumberInput(cpBody, BattleGrid:L("ADMIN_CP_CAPTURE_RADIUS"), GetCfgNum("cp_capture_radius"), function(v) SetCfg("cp_capture_radius", tostring(math.Round(v))) end)
    BattleGrid:CreateNumberInput(cpBody, BattleGrid:L("ADMIN_CP_SPAWN_OFFSET"), GetCfgNum("cp_spawn_offset"), function(v) SetCfg("cp_spawn_offset", tostring(math.Round(v))) end)
    BattleGrid:CreateTextInput(cpBody, BattleGrid:L("ADMIN_CP_DEFAULT_OWNER_PH"), GetCfg("cp_default_owner"), function(v) SetCfg("cp_default_owner", v) end)

    FormHeader(cpBody, BattleGrid:L("ADMIN_CP_CAPTURE_SOUND"))
    BattleGrid:CreateTextInput(cpBody, BattleGrid:L("ADMIN_CP_CAPTURE_SOUND_PH"), GetCfg("cp_capture_sound"), function(v) SetCfg("cp_capture_sound", v) end)
    BattleGrid:CreateTextInput(cpBody, BattleGrid:L("ADMIN_CP_LOSS_SOUND_PH"), GetCfg("cp_loss_sound"), function(v) SetCfg("cp_loss_sound", v) end)

    FormHeader(cpBody, BattleGrid:L("ADMIN_CP_NPC_SYSTEM"), BattleGrid:L("ADMIN_CP_NPC_SYSTEM_DESC"))
    BattleGrid:CreateToggle(cpBody, BattleGrid:L("ADMIN_CP_NPC_ENABLED"), GetCfgBool("cp_npc_enabled"), function(v) SetCfg("cp_npc_enabled", v and "1" or "0") end)
    BattleGrid:CreateNumberInput(cpBody, BattleGrid:L("ADMIN_CP_NPC_MAX"), GetCfgNum("cp_npc_max_per_cp"), function(v) SetCfg("cp_npc_max_per_cp", tostring(math.Round(v))) end)
    BattleGrid:CreateNumberInput(cpBody, BattleGrid:L("ADMIN_CP_NPC_INTERVAL"), GetCfgNum("cp_npc_spawn_interval"), function(v) SetCfg("cp_npc_spawn_interval", tostring(math.Round(v, 1))) end)

    FormHeader(cpBody, BattleGrid:L("ADMIN_CP_NPC_SPAWN_TYPES_GLOBAL"), BattleGrid:L("ADMIN_CP_NPC_SPAWN_TYPES_DESC"))
    BattleGrid:CreateSpawnTypesEditor(cpBody, GetCfg("cp_npc_spawn_types"), function(json)
        SetCfg("cp_npc_spawn_types", json)
    end)

    FormHeader(cpBody, BattleGrid:L("ADMIN_CP_LIST"), BattleGrid:L("ADMIN_CP_LIST_DESC"))

    local cpListPanel = vgui.Create("DPanel", cpBody)
    cpListPanel:Dock(TOP)
    cpListPanel:DockMargin(0, S(6), 0, 0)
    cpListPanel.Paint = function() end
    cpListPanel.PerformLayout = function(s) s:SizeToChildren(false, true) end

    local function RebuildCPList()
        cpListPanel:Clear()
        local posts = BattleGrid.Cache.CommandPosts or {}
        if #posts == 0 then
            BattleGrid:CreateEmptyState(cpListPanel, BattleGrid:L("ADMIN_CP_NONE"))
            cpListPanel:SetTall(S(80))
        else
            for _, cp in ipairs(posts) do
                local ownerCol = BattleGrid:GetCPOwnerColor(cp)
                local row = vgui.Create("DPanel", cpListPanel)
                row:Dock(TOP)
                row:SetTall(S(48))
                row:DockMargin(0, 0, 0, S(2))
                row.Paint = function(_, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelLight"))
                    surface.SetDrawColor(ownerCol)
                    surface.DrawRect(0, 0, 3, h)
                    draw.SimpleText(BattleGrid:GetCPDisplayName(cp), BattleGrid.F("body"), S(12), h / 2 - S(6), ownerCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(BattleGrid:L(BattleGrid:GetCPStateKey(cp.state)), BattleGrid.F("small"), S(12), h / 2 + S(8), BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                BattleGrid:CreateIconButton(row, "×", BattleGrid.C("Error"), function()
                    BattleGrid:AdminDeleteCommandPost(cp.identifier)
                end)

                BattleGrid:CreateEditButton(row, function()
                    _editingCP = cp
                    NavigateTo("cp_edit")
                end)
            end
            cpListPanel:SetTall(#posts * (S(48) + S(2)))
        end
    end

    RebuildCPList()

    hook.Add("BattleGrid.CommandPostsUpdated", "BattleGrid.AdminCPRefresh", function()
        if not IsValid(cpListPanel) then hook.Remove("BattleGrid.CommandPostsUpdated", "BattleGrid.AdminCPRefresh") return end
        if _activeSection == "commandposts" then RebuildCPList() end
    end)
end

local function BuildCPEditor(scroll)
    local cp = _editingCP
    if not cp then NavigateTo("commandposts"); return end

    BackButton(scroll, "commandposts", BattleGrid:L("ADMIN_NAV_COMMANDPOSTS"))
    FormHeader(scroll, BattleGrid:L("ADMIN_CP_EDIT") .. ": " .. (cp.name or ""))

    local getPayload = BattleGrid:PopulateCPEditor(scroll, cp)

    FormSpacer(scroll)

    AdminButton(scroll, BattleGrid:L("ADMIN_CP_SAVE"), "success", function()
        local payload = getPayload()
        if not payload then return end
        BattleGrid:AdminSaveCommandPost(payload)
        NavigateTo("commandposts")
    end, 32, {6, 2})

    AdminButton(scroll, BattleGrid:L("ADMIN_DELETE"), "danger", function()
        ConfirmDialog(BattleGrid:L("ADMIN_CONFIRM") .. "?", function()
            BattleGrid:AdminDeleteCommandPost(cp.identifier)
            NavigateTo("commandposts")
        end)
    end, 32, {4, 6})
end

local SECTION_BUILDERS = {
    general      = BuildGeneral,
    permissions  = BuildPermissions,
    jammers      = BuildJammers,
    waypoints    = BuildWaypoints,
    areas        = BuildAreas,
    icons        = BuildIcons,
    factions     = BuildFactions,
    faction_edit = BuildFactionEditor,
    commandposts = BuildCommandPosts,
    cp_edit      = BuildCPEditor,
}

function BattleGrid:OpenAdminMenu()
    if IsValid(self.AdminFrame) then self.AdminFrame:Remove() end

    if not BattleGrid:HasPermission(LocalPlayer(), "BattleGrid.Admin") then
        chat.AddText(BattleGrid.C("Error"), BattleGrid:GetPrefixText(), BattleGrid.C("TextPrimary"), BattleGrid:L("ADMIN_NO_ACCESS"))
        return
    end
    table.Empty(BattleGrid._pendingCfg)

    local scrW, scrH = ScrW(), ScrH()

    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(scrW, scrH)
    frame:SetPos(0, 0)
    frame:MakePopup()
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:DockPadding(0, 0, 0, 0)
    frame:SetKeyboardInputEnabled(true)
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.15)

    self.AdminFrame = frame
    _adminFrame = frame

    frame.Paint = function(s, w, h)
        KF.Materials.DrawBlur(s, 3)
        surface.SetDrawColor(BattleGrid.C("Background"))
        surface.DrawRect(0, 0, w, h)
    end

    function frame:OnRemove()
        hook.Remove("BattleGrid.JammersUpdated",      "BattleGrid.AdminJammerRefresh")
        hook.Remove("BattleGrid.WaypointsUpdated",    "BattleGrid.AdminWPMgmtRefresh")
        hook.Remove("BattleGrid.AreasUpdated",        "BattleGrid.AdminAreaRefresh")
        hook.Remove("BattleGrid.FactionsUpdated",     "BattleGrid.AdminFactionRefresh")
        hook.Remove("BattleGrid.CommandPostsUpdated", "BattleGrid.AdminCPRefresh")
        hook.Remove("BattleGrid.ConfigUpdated",       "BattleGrid.AdminLangRefresh")
        _adminFrame = nil
        _editingCP = nil
        _editingFactionData = nil
        BattleGrid.AdminFrame = nil
    end

    BattleGrid:CreateHeaderPanel(frame, {
        title = string.upper(BattleGrid:L("ADMIN_TITLE")),
        subtitle = BattleGrid:L("ADMIN_SUBTITLE"),
        titleFont = BattleGrid.F("title"),
        subtitleFont = BattleGrid.F("small"),
        titleColor = BattleGrid.C("Accent"),
        subtitleColor = BattleGrid.C("TextMuted"),
        height = S(T.Size.HEADER_H),
        margin = S(12),
        borderColor = BattleGrid.C("Accent"),
        backgroundColor = BattleGrid.C("PanelDark"),
    })

    local closeBtn = BattleGrid:CreateCloseButton(frame, function()
        frame:AlphaTo(0, 0.1, 0, function()
            if IsValid(frame) then frame:Remove() end
        end)
    end)
    closeBtn:SetPos(scrW - S(52), S(8))

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body.Paint = function() end

    local sidebarW = S(200)
    local sidebar = vgui.Create("KF.ScrollPanel", body)
    sidebar:Dock(LEFT)
    sidebar:SetWide(sidebarW)
    sidebar:SetAddon(AID)
    sidebar.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, BattleGrid.C("PanelDark"))
        surface.SetDrawColor(BattleGrid.C("BorderSubtle"))
        surface.DrawRect(w - 1, 0, 1, h)
        draw.SimpleText("v" .. BattleGrid.Version, BattleGrid.F("tiny"), w / 2, h - S(16), BattleGrid.C("TextDisabled"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local contentArea = vgui.Create("DPanel", body)
    contentArea:Dock(FILL)
    contentArea.Paint = function() end

    _activeSection = "general"

    local navGroups = {}
    for _, group in ipairs(SIDEBAR_GROUPS) do
        local items = {}
        for _, item in ipairs(group.items) do
            table.insert(items, {key = item.key, label = BattleGrid:L(item.labelKey)})
        end
        table.insert(navGroups, {label = BattleGrid:L(group.labelKey), items = items})
    end

    local nav = KF.Builders.SidebarNav()
        :SetAddon(AID)
        :SetGroups(navGroups)
        :SetActiveKey("general")
        :SetSoundHover(BattleGrid.Sounds.Hover)
        :SetSoundClick(BattleGrid.Sounds.Click)
        :SetOnSelect(function(key) NavigateTo(key) end)
        :Build(sidebar)

    _sidebarButtons = nav.buttons

    _rebuildContent = function()
        if not IsValid(contentArea) then return end
        for _, child in ipairs(contentArea:GetChildren()) do child:Remove() end

        BattleGrid._formWidth = contentArea:GetWide() - S(24)

        local scroll = MakeScroll(contentArea)

        local builder = SECTION_BUILDERS[_activeSection]
        if builder then builder(scroll) end
    end

    timer.Simple(0.01, function()
        if IsValid(contentArea) then
            _rebuildContent()
        end
    end)

    local _lastLang = GetCfg("language")
    hook.Add("BattleGrid.ConfigUpdated", "BattleGrid.AdminLangRefresh", function()
        if not IsValid(_adminFrame) then
            hook.Remove("BattleGrid.ConfigUpdated", "BattleGrid.AdminLangRefresh")
            return
        end
        local newLang = GetCfg("language")
        if newLang ~= _lastLang then
            _lastLang = newLang
            local savedSection = _activeSection
            BattleGrid:OpenAdminMenu()
            timer.Simple(0.02, function()
                if IsValid(_adminFrame) then NavigateTo(savedSection) end
            end)
        end
    end)
end

concommand.Add("battlegrid_admin", function()
    BattleGrid:OpenAdminMenu()
end)
