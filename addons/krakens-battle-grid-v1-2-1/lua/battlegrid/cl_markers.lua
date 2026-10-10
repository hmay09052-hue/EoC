local AID = BattleGrid.AID
local S = KF.Scale
local T = BattleGrid.Theme

BattleGrid.Net:Receive("SyncWaypoints", function()
    local data = BattleGrid.Net:ReadJSON()
    if not data then return end
    for _, wp in ipairs(data) do
        wp.pos   = BattleGrid:NormalizeVector(wp.pos)
        wp.color = BattleGrid:NormalizeColor(wp.color)
    end
    BattleGrid.Cache.Waypoints = data
    BattleGrid.Cache._wpSynced = true
    hook.Run("BattleGrid.WaypointsUpdated")
end)

local function SendWaypointData(messageName, data)
    local payload = {
        identifier = data.identifier or BattleGrid:GenerateUID(data.name),
        name = data.name or BattleGrid:L("WP_SINGULAR"),
        color = data.color,
        pos = data.pos,
        state = data.state,
        icon = data.icon,
        description = data.description,
    }

    BattleGrid.Net:SendSchemaToServer(messageName, payload, BattleGrid.WaypointSchema)
end

function BattleGrid:RequestCreateWaypoint(data)
    SendWaypointData("CreateWaypoint", data)
end

function BattleGrid:RequestDeleteWaypoint(uid)
    if IsValid(self.WaypointEditorFrame) and self.WaypointEditorFrame._editIdentifier == uid then
        self.WaypointEditorFrame:Remove()
        self.WaypointEditorFrame = nil
    end

    BattleGrid.Net:SendToServer("DeleteWaypoint", function()
        net.WriteString(uid)
    end)
end

local _wpCol = Color(0, 0, 0)
local _wpMuted = Color(0, 0, 0)
local _descTruncCache = {}

local function GetTruncatedDesc(wp)
    local cached = _descTruncCache[wp.identifier]
    if cached and cached.src == wp.description and cached.scrW == ScrW() then
        return cached.text
    end
    local text = BattleGrid:TruncateToWidth(wp.description, ScrW() * 0.3, BattleGrid.F("small"))
    _descTruncCache[wp.identifier] = { src = wp.description, scrW = ScrW(), text = text }
    return text
end

local function DrawWorldWaypoints()
    if not BattleGrid:IsMapAllowed() or not BattleGrid:GetPref("show_world_waypoints") then return end

    local plyPos = LocalPlayer():GetPos()
    local maxDist = BattleGrid:GetPref("waypoint_render_distance")
    local showDesc = BattleGrid:GetPref("show_wp_descriptions")
    local maxDistSqr = maxDist * maxDist

    for _, wp in ipairs(BattleGrid.Cache.Waypoints) do
        if not wp.pos then continue end
        local distSqr = plyPos:DistToSqr(wp.pos)
        if distSqr > maxDistSqr then continue end

        local scr = wp.pos:ToScreen()
        if not scr.visible then continue end

        local dist = math.sqrt(distSqr)
        local alpha = BattleGrid:DistanceFadeAlpha(dist, maxDist, 255)

        _wpCol.r, _wpCol.g, _wpCol.b, _wpCol.a = wp.color.r, wp.color.g, wp.color.b, alpha
        local x, y = scr.x, scr.y

        local iconSize = S(24)
        if wp.icon and wp.icon ~= "" then
            BattleGrid:DrawIcon(wp.icon, x - iconSize / 2, y - iconSize / 2, iconSize, iconSize, _wpCol)
        else
            surface.SetDrawColor(_wpCol)
            draw.NoTexture()
            BattleGrid:DrawCircle(x, y, S(6), 12)
        end

        draw.SimpleText(wp.name, BattleGrid.F("MapLabel"), x, y - iconSize / 2 - S(4), _wpCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

        local _textMuted = BattleGrid.C("TextMuted")
        _wpMuted.r, _wpMuted.g, _wpMuted.b, _wpMuted.a = _textMuted.r, _textMuted.g, _textMuted.b, alpha

        local descOffset = 0
        if showDesc and wp.description ~= "" then
            draw.SimpleText(GetTruncatedDesc(wp), BattleGrid.F("small"), x, y + iconSize / 2 + S(2), _wpMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            descOffset = S(14)
        end
        local distStr = BattleGrid:FormatDistance(dist)
        draw.SimpleText(distStr, BattleGrid.F("small"), x, y + iconSize / 2 + S(2) + descOffset, _wpMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        _wpCol.a = alpha * 0.4
        surface.SetDrawColor(_wpCol)
        surface.DrawLine(x, y + iconSize / 2, x, y + iconSize / 2 + S(8))
    end
end

hook.Add("HUDPaint", "BattleGrid.WorldWaypoints", DrawWorldWaypoints)

local _compassCol = Color(0, 0, 0)

hook.Add("BF2HUD.PaintCompassOverlay", "BattleGrid.CompassWaypoints", function(px, baseY, width, yaw)
    if not BattleGrid:IsMapAllowed() or not BattleGrid:GetPref("show_wp_compass") then return end
    local plyPos = LocalPlayer():GetPos()
    local iconSize = BattleGrid.Compat.HUDScale(16)
    local markerY = baseY - BattleGrid.Compat.HUDScale(14)

    for _, wp in ipairs(BattleGrid.Cache.Waypoints) do
        local tx, fade = BattleGrid:CompassProject(wp.pos, plyPos, yaw, px, width)
        if tx then
            _compassCol.r, _compassCol.g, _compassCol.b, _compassCol.a = wp.color.r, wp.color.g, wp.color.b, math.floor(230 * fade)
            if wp.icon ~= "" then
                BattleGrid:DrawIcon(wp.icon, tx - iconSize / 2, markerY - iconSize / 2, iconSize, iconSize, _compassCol)
            else
                draw.NoTexture()
                surface.SetDrawColor(_compassCol)
                BattleGrid:DrawCircle(tx, markerY, iconSize * 0.25, 10)
            end
        end
    end
end)



BattleGrid.Net:Receive("SyncAreas", function()
    local data = BattleGrid.Net:ReadJSON()
    if not data then return end
    for _, area in ipairs(data) do
        area.pos1  = BattleGrid:NormalizeVector(area.pos1)
        area.pos2  = BattleGrid:NormalizeVector(area.pos2)
        area.color = BattleGrid:NormalizeColor(area.color)
        area.type  = area.type or BattleGrid.AreaTypes.RECTANGULAR
    end
    BattleGrid.Cache.Areas = data
    BattleGrid.Cache._areaSynced = true
    hook.Run("BattleGrid.AreasUpdated")
end)

function BattleGrid:RequestCreateArea(data)
    local payload = {
        identifier = data.identifier or BattleGrid:GenerateUID(data.name),
        name = data.name or BattleGrid:L("AREA_SINGULAR"),
        color = data.color,
        pos1 = data.pos1,
        pos2 = data.pos2,
        state = data.state,
        type = data.type,
    }

    BattleGrid.Net:SendSchemaToServer("CreateArea", payload, BattleGrid.AreaSchema)
end

function BattleGrid:RequestDeleteArea(uid)
    if IsValid(self.AreaEditorFrame) and self.AreaEditorFrame._editIdentifier == uid then
        self.AreaEditorFrame:Remove()
        self.AreaEditorFrame = nil
    end

    BattleGrid.Net:SendToServer("DeleteArea", function()
        net.WriteString(uid)
    end)
end

function BattleGrid:OpenWaypointEditor(existing, worldPos)
    local isEdit = existing ~= nil
    local panel, closeEditor = BattleGrid:OpenAdaptiveEditor(
        "WaypointEditorFrame",
        isEdit and BattleGrid:L("WP_EDIT") or BattleGrid:L("WP_CREATE"),
        S(340), S(420), S(520),
        existing and existing.identifier or nil
    )

    local parentW = panel:GetWide()

    local content = vgui.Create("KF.ScrollPanel", panel)
    content:Dock(FILL)
    content:DockMargin(S(16), S(6), S(16), S(12))
    content:SetAddon(AID)

    local data = {
        identifier  = existing and existing.identifier or nil,
        name        = existing and existing.name or "",
        description = existing and existing.description or "",
        pos         = existing and existing.pos or (worldPos or Vector(0, 0, 0)),
        icon        = existing and existing.icon or BattleGrid.DefaultIcons[1],
        color       = existing and existing.color or BattleGrid.C("TextPrimary"),
        state       = existing and existing.state or BattleGrid.States.NORMAL,
    }

    BattleGrid.FormHeader(content, BattleGrid:L("WP_NAME"))
    BattleGrid:CreateTextInput(content, BattleGrid:L("WP_NAME"), data.name, function(v) data.name = v end, BattleGrid.Limits.NAME)

    BattleGrid.FormHeader(content, BattleGrid:L("WP_DESCRIPTION"))
    local descInput = BattleGrid:CreateTextInput(content, BattleGrid:L("WP_DESCRIPTION_HINT"), data.description, function(v) data.description = v end, BattleGrid.Limits.DESCRIPTION)
    local function DescCounter(text) return (utf8.len(text) or #text) .. " / " .. BattleGrid.Limits.DESCRIPTION end

    local descCounter = vgui.Create("DLabel", content)
    descCounter:Dock(TOP)
    descCounter:DockMargin(0, 0, S(6), S(2))
    descCounter:SetTall(S(14))
    descCounter:SetFont(BattleGrid.F("tiny"))
    descCounter:SetContentAlignment(6)
    descCounter:SetTextColor(BattleGrid.C("TextMuted"))
    descCounter:SetText(DescCounter(data.description))

    descInput.Entry._origOnChange = descInput.Entry.OnChange
    function descInput.Entry:OnChange()
        self:_origOnChange()
        descCounter:SetText(DescCounter(self:GetValue()))
    end

    BattleGrid.FormHeader(content, BattleGrid:L("WP_POSITION"))
    local posInput = BattleGrid:CreatePositionInput(content, data.pos)

    BattleGrid.FormHeader(content, BattleGrid:L("WP_ICON"))

    local iconGrid = vgui.Create("DPanel", content)
    iconGrid:SetTall(S(80))
    iconGrid:Dock(TOP)
    iconGrid:DockMargin(0, 0, 0, S(6))
    iconGrid.Paint = function() end

    local iconBtns = {}
    local iconSize = S(28)
    local iconPad = S(4)
    local cols = math.floor((parentW - S(32)) / (iconSize + iconPad))

    for idx, iconPath in ipairs(BattleGrid.AllIcons) do
        local ibtn = vgui.Create("DButton", iconGrid)
        ibtn:SetText("")
        ibtn:SetSize(iconSize, iconSize)
        ibtn:SetCursor("hand")

        local row = math.floor((idx - 1) / cols)
        local col = (idx - 1) % cols
        ibtn:SetPos(col * (iconSize + iconPad), row * (iconSize + iconPad))
        ibtn._selected = (iconPath == data.icon)

        ibtn.Paint = function(_, w, h)
            if ibtn._selected then
                draw.RoundedBox(4, 0, 0, w, h, KF.UI.ColorAlpha(BattleGrid.C("Accent"), 40))
                surface.SetDrawColor(BattleGrid.C("Accent"))
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            elseif ibtn:IsHovered() then
                draw.RoundedBox(4, 0, 0, w, h, BattleGrid.C("PanelHover"))
            end
            BattleGrid:DrawIcon(iconPath, 4, 4, w - 8, h - 8, BattleGrid.C("TextPrimary"))
        end

        ibtn.DoClick = function()
            for _, b in ipairs(iconBtns) do b._selected = false end
            ibtn._selected = true
            data.icon = iconPath
        end

        iconBtns[#iconBtns + 1] = ibtn
    end

    iconGrid:SetTall(math.ceil(#BattleGrid.AllIcons / cols) * (iconSize + iconPad) + iconPad)

    BattleGrid.FormHeader(content, BattleGrid:L("WP_COLOR"))
    BattleGrid:CreateColorPresets(content, T.PresetColors, data)

    BattleGrid:CreateDropdown(content, BattleGrid:L("WP_STATE"), BattleGrid:GetStateChoices(), data.state, function(v) data.state = v end)

    BattleGrid:CreateEditorActionPanel(panel, isEdit and BattleGrid:L("WP_SAVE") or BattleGrid:L("WP_CREATE_BTN"), function()
        data.pos = posInput:GetVector()
        if data.name == "" then data.name = BattleGrid:L("WP_SINGULAR") end
        BattleGrid:RequestCreateWaypoint(data)
        closeEditor()
    end)
end

function BattleGrid:OpenAreaEditor(existing, pos1, pos2, areaType)
    local isEdit = existing ~= nil
    local panel, closeEditor = BattleGrid:OpenAdaptiveEditor(
        "AreaEditorFrame",
        isEdit and BattleGrid:L("AREA_EDIT") or BattleGrid:L("AREA_CREATE"),
        S(340), S(420), S(520),
        existing and existing.identifier or nil
    )

    local content = vgui.Create("KF.ScrollPanel", panel)
    content:Dock(FILL)
    content:DockMargin(S(16), S(6), S(16), S(12))
    content:SetAddon(AID)

    local data = {
        identifier = existing and existing.identifier or nil,
        name       = existing and existing.name or "",
        pos1       = existing and existing.pos1 or (pos1 or Vector(0, 0, 0)),
        pos2       = existing and existing.pos2 or (pos2 or Vector(0, 0, 0)),
        color      = existing and existing.color or BattleGrid.C("AreaDefine"),
        state      = existing and existing.state or BattleGrid.States.NORMAL,
        type       = existing and existing.type or (areaType or BattleGrid.AreaTypes.RECTANGULAR),
    }

    BattleGrid.FormHeader(content, BattleGrid:L("AREA_NAME"))
    BattleGrid:CreateTextInput(content, BattleGrid:L("AREA_NAME"), data.name, function(v) data.name = v end, BattleGrid.Limits.NAME)

    local types = {}
    for _, v in pairs(BattleGrid.AreaTypes) do
        types[#types + 1] = {v, BattleGrid:GetAreaTypeDisplay(v)}
    end
    BattleGrid:CreateDropdown(content, BattleGrid:L("AREA_TYPE"), types, data.type, function(v) data.type = v end)

    BattleGrid.FormHeader(content, BattleGrid:L("AREA_POS1"))
    local pos1Input = BattleGrid:CreatePositionInput(content, data.pos1)

    BattleGrid.FormHeader(content, BattleGrid:L("AREA_POS2"))
    local pos2Input = BattleGrid:CreatePositionInput(content, data.pos2)

    BattleGrid.FormHeader(content, BattleGrid:L("AREA_COLOR"))
    BattleGrid:CreateColorPresets(content, T.PresetColors, data)

    BattleGrid:CreateDropdown(content, BattleGrid:L("AREA_STATE"), BattleGrid:GetStateChoices(), data.state, function(v) data.state = v end)

    BattleGrid:CreateEditorActionPanel(panel, isEdit and BattleGrid:L("AREA_SAVE") or BattleGrid:L("AREA_CREATE_BTN"), function()
        data.pos1 = pos1Input:GetVector()
        data.pos2 = pos2Input:GetVector()
        if data.name == "" then data.name = BattleGrid:L("AREA_SINGULAR") end
        BattleGrid:RequestCreateArea(data)
        closeEditor()
    end)
end
