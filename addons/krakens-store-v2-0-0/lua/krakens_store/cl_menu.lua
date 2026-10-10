KrakensStore.UI = KrakensStore.UI or {}
KrakensStore.UI.MainFrame = nil
KrakensStore.ClientPrefs = KrakensStore.ClientPrefs or {}
KrakensStore.Net = KrakensStore.Net or {}

local AID = KrakensStore.AID
local L = KrakensStore.L
local UI = KrakensStore.UI
local S = KF.Scale
local T = KF.T
local function C(key) return KF.UI.GetColor(key, AID) end
local function F(role) return KF.Fonts.Role(AID, role) end

local PREF_FILE = "krakens_store_client_prefs.txt"
local LAST_VIEW_PREF_KEY = "lastView"

local function RegisterTheme()
    if SYMUI then SYMUI.HookKraken() end -- SymChars-Design
    local palette = KF.UI.DefaultDarkPalette()
    for k, v in pairs(KrakensStore.Config.UI.Colors) do palette[k] = v end
    KF.UI.SetTheme(AID, palette)
    KF.Fonts.Register(AID, { prefix = "KrakensStore" })
    KF.Fonts.Create(AID)
end

RegisterTheme()

function UI.ApplySoundPref()
    KF.UI.SetSounds(AID, KrakensStore.ClientPrefs.sounds ~= false and KrakensStore.Config.UI.Sounds or {})
end

UI.ApplySoundPref()

function UI.PlaySound(key)
    KF.Helpers.PlaySound(KF.UI.GetSound(AID, key) or KF.UI.GetSound(AID, "Click"))
end

function UI.Button(parent, label, style)
    local btn = vgui.Create("KF.Button", parent)
    btn:SetAddon(AID)
    if label then btn:SetLabel(label) end
    if style then btn:SetStyle(style) end
    return btn
end

function UI.RunBusy(btn, idleLabel, delay, send)
    send()
    if not IsValid(btn) then return end
    btn._working = true
    btn:SetLabel(L("ui_loading_dots"))
    timer.Simple(delay, function()
        if not IsValid(btn) then return end
        btn._working = false
        btn:SetLabel(idleLabel)
    end)
end

function UI.ShowNotification(msg, nType)
    if not msg or msg == "" then return end
    KF.Notifications.Show(msg, nType or "info", nil, AID)
end

UI.FLAT_PANEL = { hasNotch = false, addonId = AID }

KrakensStore.ServerState = KrakensStore.ServerState or { phase = "UNINITIALIZED", failure = "" }

local trackedPopups = {}

function UI.TrackPopup(panel)
    if not IsValid(panel) then return panel end
    trackedPopups[panel] = true
    return panel
end

function UI.PopupCount()
    local count = 0
    for panel in pairs(trackedPopups) do
        if IsValid(panel) then count = count + 1 else trackedPopups[panel] = nil end
    end
    return count
end

local closingPopups = false

function UI.CloseAllPopups()
    if closingPopups then return end
    closingPopups = true
    for panel in pairs(trackedPopups) do
        trackedPopups[panel] = nil
        if IsValid(panel) then panel:Remove() end
    end
    closingPopups = false
end

function UI.CancelTransientModes()
    if KrakensStore.NPCPlacement.IsActive() then
        KrakensStore.NPCPlacement.Stop(false, true)
    end
    if KrakensStore.VehiclePreview.IsActive() then
        KrakensStore.VehiclePreview.Stop(false, true)
    end
end

function UI.ConfirmDialog(title, msg, cText, xText, onC, onX, danger)
    if IsValid(KrakensStore._activeConfirmDialog) then KrakensStore._activeConfirmDialog:Remove() end
    local dialog = KF.Dialogs.Confirm({
        addonId = AID,
        title = title or L("btn_confirm"),
        message = msg,
        confirmText = cText or L("btn_confirm"),
        cancelText = xText or L("btn_cancel"),
        danger = danger,
        onConfirm = onC,
        onCancel = onX,
    })
    KrakensStore._activeConfirmDialog = UI.TrackPopup(dialog)
    return dialog
end

function UI.OpenContextMenu(items, x, y)
    return UI.TrackPopup(KF.UI.OpenContextMenu(items, { addonId = AID, x = x, y = y }))
end

local PLACEMENT_REASON_KEYS = {
    ground = "placement_no_ground", steep = "placement_steep", obstructed = "placement_obstructed",
    far = "placement_too_far", close = "placement_too_close",
}

local function CreatePlacementValidator(opts)
    return function(pos)
        local ok, reason = KrakensStore.Utils.CheckSpawnPos(pos, opts.kind, LocalPlayer())
        if not ok then return false, L(PLACEMENT_REASON_KEYS[reason] or opts.waterKey) end
        return true, ""
    end
end

local function SetupPlacementHooks(state, validate, titleKey, stopFn)
    local titleText = L(titleKey)
    local validText = L("placement_valid")
    local controlsText = L("placement_controls")
    local surfaceText = L("placement_no_surface")
    local renderBoundsMins, renderBoundsMaxs

    state._nextTrace = 0
    state.hooks = {
        Think = function()
            if not state.active then return end
            local t = RealTime()
            if t < state._nextTrace then return end
            state._nextTrace = t + 0.05
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            local tr = ply:GetEyeTrace()
            if tr.Hit then
                state.position = tr.HitPos
                state.angle = Angle(0, ply:EyeAngles().y + state.rotation, 0)
                state.isValid, state.invalidReason = validate(tr.HitPos)
            else
                state.isValid = false
                state.invalidReason = surfaceText
            end
            if IsValid(state.clientModel) then
                state.clientModel:SetPos(state.position)
                state.clientModel:SetAngles(state.angle)
            end
        end,

        PostDrawOpaqueRenderables = function()
            if not state.active or not IsValid(state.clientModel) then return end
            local color = C(state.isValid and "Success" or "Error")
            render.SetBlend(0.5)
            render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
            state.clientModel:DrawModel()
            render.SetColorModulation(1, 1, 1)
            render.SetBlend(1)
            if not renderBoundsMins then
                renderBoundsMins, renderBoundsMaxs = state.clientModel:GetRenderBounds()
            end
            render.DrawWireframeBox(state.position, state.angle, renderBoundsMins, renderBoundsMaxs, color, true)
        end,

        HUDPaint = function()
            if not state.active then return end
            KF.Draw.PlacementHud(titleText, state.isValid and validText or state.invalidReason, state.isValid, controlsText, AID)
        end,

        PlayerBindPress = function(ply, bind, pressed)
            if not state.active or not pressed then return end
            if string.find(bind, "+attack") and not string.find(bind, "+attack2") then stopFn(true); return true end
            if string.find(bind, "+attack2") then stopFn(false); return true end
        end,

        InputMouseApply = function(cmd, x, y, ang)
            if not state.active then return end
            local wheel = cmd:GetMouseWheel()
            if wheel ~= 0 then state.rotation = (state.rotation + wheel * 15) % 360; return true end
        end,

        GUIMousePressed = function(mouseCode)
            if not state.active then return end
            if mouseCode == MOUSE_LEFT then stopFn(true); return true
            elseif mouseCode == MOUSE_RIGHT then stopFn(false); return true end
        end,

        PlayerButtonDown = function(ply, key)
            if not state.active then return end
            if key == KEY_ESCAPE then stopFn(false) end
        end,
    }
    for event, fn in pairs(state.hooks) do hook.Add(event, state.hookId, fn) end
end

function UI.DrawEntityLabel3D(ent, title, hint)
    if not IsValid(ent) then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local _, maxs = ent:GetRenderBounds()
    local pos = ent:GetPos() + Vector(0, 0, maxs.z + 14)
    local dist = ply:EyePos():Distance(pos)
    if dist > 400 then return end

    local ang = (pos - ply:EyePos()):Angle()
    ang.p, ang.r = 0, 0
    ang:RotateAroundAxis(ang:Up(), -90)
    ang:RotateAroundAxis(ang:Forward(), 90)

    local alpha = math.Clamp(1 - (dist - 250) / 150, 0, 1) * 255
    if alpha <= 0 then return end

    cam.Start3D2D(pos, ang, 0.1)
        if title and title ~= "" then
            draw.SimpleTextOutlined(title, F("PanelTitle"), 0, -16,
                KF.UI.ColorAlpha(C("TextPrimary"), alpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, KF.UI.ColorAlpha(color_black, alpha))
        end
        if hint and hint ~= "" then
            draw.SimpleTextOutlined(hint, F("Meta"), 0, 16,
                KF.UI.ColorAlpha(C("TextMuted"), alpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, KF.UI.ColorAlpha(color_black, alpha))
        end
    cam.End3D2D()
end

function UI.DrawItemIcon(item, x, y, size, opts)
    opts = opts or {}
    draw.RoundedBox(KF.UI.Tokens.Radius, x, y, size, size, C("PanelDark"))
    if opts.hasModelPanel then return end
    if item.icon and item.icon ~= "" then
        local mat = KF.Materials.ResolveIcon(item.icon)
        if mat then
            local pad = opts.texPad or S(4)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(x + pad, y + pad, size - pad * 2, size - pad * 2)
        else
            draw.SimpleText("?", F("PanelTitle"), x + size / 2, y + size / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    elseif KF.Materials.IsModelPath(item.model) then
        draw.SimpleText(L("ui_icon_3d"), F("Tiny"), x + size / 2, y + size / 2, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function UI.OpenKey()
    return KrakensStore.ClientPrefs.openKey or KrakensStore.Config.UI.OpenKey
end

local function LoadClientPrefs()
    KrakensStore.ClientPrefs = KF.Helpers.LoadClientPrefs(PREF_FILE, {})
    UI.ApplySoundPref()
end

function UI.SetClientPref(k, v)
    KrakensStore.ClientPrefs[k] = v
    if k == "sounds" then UI.ApplySoundPref() end
    timer.Create("KrakensStore_DebouncedPrefsSave", 0.5, 1, function()
        KF.Helpers.SaveClientPrefs(PREF_FILE, KrakensStore.ClientPrefs)
    end)
end

function UI.TypeName(item)
    local typeData = KrakensStore.types[item.type]
    return (typeData and typeData.name) or item.type or L("ui_item_fallback")
end

function UI.AttachModelIcon(panel, item, x, y, size)
    if not IsValid(panel) or not item or not KF.Materials.IsModelPath(item.model) then return end
    if item.icon and item.icon ~= "" and KF.Materials.ResolveIcon(item.icon) then
        KF.Helpers.ClearModelPanel(panel, "storeIcon")
        panel._hasModelPanel = false
        return
    end
    KF.Helpers.EnsureModelPanel(panel, "storeIcon", item.model, x, y, size)
    panel._hasModelPanel = true
end

local SORT_MODES = {
    { id = "name_asc", labelKey = "sort_name_asc", less = function(a, b) return (a.name or "") < (b.name or "") end },
    { id = "name_desc", labelKey = "sort_name_desc", less = function(a, b) return (a.name or "") > (b.name or "") end },
    { id = "price_asc", labelKey = "sort_price_asc", less = function(a, b) return (a.price or 0) < (b.price or 0) end },
    { id = "price_desc", labelKey = "sort_price_desc", less = function(a, b) return (a.price or 0) > (b.price or 0) end },
}

function UI.SortItems(items, mode)
    local less = SORT_MODES[1].less
    for _, sort in ipairs(SORT_MODES) do
        if sort.id == mode then less = sort.less break end
    end
    table.sort(items, less)
end

function UI.SortOptions()
    local options = {}
    for i, sort in ipairs(SORT_MODES) do options[i] = { value = sort.id, label = L(sort.labelKey) } end
    return options
end

function UI.CreateSortDropdown(parent, onSelect)
    local options = UI.SortOptions()
    local labels = {}
    for i, option in ipairs(options) do labels[i] = option.label end
    local dropdown = vgui.Create("KF.PopupDropdown", parent)
    dropdown:SetAddon(AID)
    dropdown:SetSize(math.Clamp(KF.MaxTextWidth(labels, F("Body"), S(30)), S(100), S(220)), T("InputH"))
    for _, option in ipairs(options) do dropdown:AddOption(option.value, option.label) end
    dropdown:SetValue(options[1].value)
    dropdown.OnSelect = function(_, _, _, value) onSelect(value) end
    return dropdown
end

function UI.CreateSearchBar(parent, width, placeholder, callback)
    local search = KF.Builders.Search():SetAddon(AID):SetPlaceholder(placeholder or L("ui_search_placeholder")):SetDebounce(0.2)
        :SetOnSearch(callback):Build(parent)
    search:SetWide(width)
    return search
end

function UI.PaintItemCard(self, cw, ch, item, opts)
    local hover = KF.Anim.UpdateHoverLerp(self, 10)
    local hs = KF.UI.GetSound(AID, "Hover")
    if hs then KF.Helpers.HandleHoverSound(self, hs) end
    local selected = self._selected == true
    KF.Draw.CardBase(cw, ch, math.max(hover, selected and 1 or 0), selected, opts.accent and opts.accent(self) or nil, AID)
    local pad = T("SpaceS")
    local iconSize = ch - pad * 2
    UI.DrawItemIcon(item, pad, pad, iconSize, { hasModelPanel = self._hasModelPanel })
    local textX = pad + iconSize + T("SpaceM")
    local badgeW = (opts.showBadge and opts.showBadge(self)) and S(70) or 0
    local maxNameW = cw - textX - badgeW - pad
    if not self._truncName or self._truncNameW ~= maxNameW then
        self._truncNameW = maxNameW
        self._truncName = KF.TruncateText(item.name or L("ui_unknown"), F("PanelTitle"), maxNameW)
    end
    draw.SimpleText(self._truncName, F("PanelTitle"), textX, pad, C("TextPrimary"))
    if opts.drawInfo then opts.drawInfo(self, textX, pad + S(22)) end
    self._typeName = self._typeName or UI.TypeName(item)
    draw.SimpleText(self._typeName, F("Meta"), textX, ch - pad - S(12), C("TextMuted"))
    if badgeW > 0 then
        draw.RoundedBox(KF.UI.Tokens.Radius, cw - badgeW - pad, pad, badgeW, S(18), C("Success"))
        draw.SimpleText(L("inv_equipped"), F("Tiny"), cw - badgeW / 2 - pad, pad + S(9), C("BackgroundDark"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function UI.CreateItemCard(grid, item, opts)
    local card = vgui.Create("DPanel", grid)
    card:SetSize(grid._cardW, grid._cardH)
    card._item = item
    card._invItem = opts.invItem
    card._selected = false
    card:SetCursor("hand")
    card.Paint = function(self, cw, ch) UI.PaintItemCard(self, cw, ch, self._item, opts) end
    card.OnMousePressed = function(self, code)
        if code == MOUSE_LEFT and opts.onLeft then opts.onLeft(self)
        elseif code == MOUSE_RIGHT and opts.onRight then opts.onRight(self) end
    end
    local pad = T("SpaceS")
    UI.AttachModelIcon(card, item, pad, pad, grid._cardH - pad * 2)
    return card
end

function UI.SelectCard(state, card, parent, refreshFn)
    UI.PlaySound("Click")
    if state.selectedItem and state._cardById then
        local prev = state._cardById[state.selectedItem.id]
        if IsValid(prev) then prev._selected = false end
    end
    state.selectedItem = card._item
    card._selected = true
    refreshFn(parent, state)
end

local function SectionLabel(parent, text, x, y, w)
    local label = vgui.Create("DPanel", parent)
    label:SetPos(x, y)
    label:SetSize(w, S(22))
    label.Paint = function(_, _, lh) draw.SimpleText(text, F("Value"), 0, lh / 2, C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER) end
    return y + S(26)
end

function UI.CreateDescriptionSection(parent, item, y, w, pad)
    if not item.description or item.description == "" then return y end
    y = SectionLabel(parent, L("inv_description"), pad, y, w)
    local font = F("Body")
    local lines = KF.WrapText(item.description, font, w)
    local lineH = KF.Draw.LineHeight(font) + S(2)
    local panel = vgui.Create("DPanel", parent)
    panel:SetPos(pad, y)
    panel:SetSize(w, #lines * lineH)
    panel.Paint = function()
        for i, line in ipairs(lines) do draw.SimpleText(line, font, 0, (i - 1) * lineH, C("TextSecondary")) end
    end
    return y + #lines * lineH + pad
end

function UI.CreateItemStatsSection(parent, item, y, w, pad)
    local data, kind = KrakensStore.Stats.GetItemStats(item)
    if not data then return y end
    local isWeapon = kind == "weapon"
    local bars = isWeapon and KrakensStore.Stats.WeaponBars(data) or KrakensStore.Stats.AttachmentLines(data)
    if #bars == 0 then return y end
    y = SectionLabel(parent, L(isWeapon and "stats_title" or "stats_modifiers"), pad, y, w)
    local rowH, gap = S(40), S(10)
    for _, bar in ipairs(bars) do
        local row = vgui.Create("DPanel", parent)
        row:SetPos(pad, y)
        row:SetSize(w, rowH)
        row.Paint = function(_, rw, rh) KF.Draw.StatRow(rw, rh, bar.label, bar.raw, bar.fill, nil, AID) end
        y = y + rowH + gap
    end
    return y + S(6)
end

function UI.CreateInfoRows(parent, infoItems, x, y, w)
    local rowH = S(28)
    for _, info in ipairs(infoItems) do
        local row = vgui.Create("DPanel", parent)
        row:SetPos(x, y)
        row:SetSize(w, rowH)
        row.Paint = function(_, sw, sh)
            draw.SimpleText(info.label, F("Label"), 0, sh / 2, C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(info.value, F("Value"), sw, sh / 2, C("TextPrimary"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        y = y + rowH
    end
    return y
end

function UI.GetCategoryName(catId)
    local cat = KrakensStore.Categories.Get(catId)
    return cat and cat.name or catId or L("ui_misc")
end

local STATE_MESSAGES = {
    UNINITIALIZED = "ui_state_starting",
    CONNECTING = "ui_state_connecting",
    MIGRATING = "ui_state_migrating",
    LOADING = "ui_loading",
    FAILED = "ui_state_failed",
}

function UI.DescribeServerState()
    local state = KrakensStore.ServerState
    local title = L(STATE_MESSAGES[state.phase] or "ui_loading")
    if state.phase ~= "FAILED" then return title, L("ui_please_wait") end
    local detail = L("ui_state_failed_hint")
    if state.failure ~= "" and KrakensStore.IsAdmin(LocalPlayer()) then
        detail = state.failure
    end
    return title, detail
end

function UI.BuildStatePanel(parent, rebuild)
    local title, detail = UI.DescribeServerState()
    local failed = KrakensStore.ServerState.phase == "FAILED"
    KF.Builders.StatePanel(parent, {
        addonId = AID, title = title, detail = detail, kind = failed and "error" or "loading",
        actionLabel = failed and L("ui_retry") or nil,
        onAction = function() KrakensStore.Net.RequestSync() end,
    })
    local function Rebuild()
        if not IsValid(parent) then return end
        parent:Clear()
        rebuild(parent)
    end
    hook.Add("KrakensStore_StoreDataUpdated", parent, Rebuild)
    hook.Add("KrakensStore_StoreStateChanged", parent, Rebuild)
    if not failed then KrakensStore.Net.RequestSync() end
end

function UI.BuildCategoryButtons(list, catCounts, selectedCategory, onSelect)
    list:Clear()
    local buttons = {}
    local spacer = vgui.Create("DPanel")
    spacer:SetTall(T("SpaceS"))
    spacer.Paint = KF.Helpers.NoPaint
    list:Add(spacer)
    local entries = { { id = "all", name = L("store_all_items") } }
    for _, cat in ipairs(KrakensStore.Categories.GetSorted()) do
        if (catCounts[cat.id] or 0) > 0 then entries[#entries + 1] = cat end
    end
    for _, entry in ipairs(entries) do
        local btn = vgui.Create("KF.TabButton")
        btn:SetAddon(AID)
        btn:SetFont(F("Value"))
        btn:SetLabel(KF.Upper(entry.name))
        btn:SetTall(T("TabItemH"))
        btn:SetActive(selectedCategory == entry.id)
        btn.DoClick = function()
            onSelect(entry.id)
            for id, other in pairs(buttons) do
                if IsValid(other) then other:SetActive(id == entry.id) end
            end
        end
        list:Add(btn)
        btn:DockMargin(T("SpaceS"), 0, T("SpaceS"), T("SpaceXS"))
        buttons[entry.id] = btn
    end
end

local function CreateSidebar(parent, h)
    local sidebarW, headerH, pad = T("SidebarW"), T("PaneHeaderH"), T("SpaceL")
    local sidebar = vgui.Create("DPanel", parent)
    sidebar:SetSize(sidebarW, h)
    sidebar.Paint = function(_, sw, sh) KF.Draw.Panel(0, 0, sw, sh, UI.FLAT_PANEL) end
    local header = vgui.Create("DPanel", sidebar)
    header:SetSize(sidebarW, headerH)
    header.Paint = function(_, sw, sh)
        draw.SimpleText(L("store_categories"), F("PanelTitle"), pad, sh / 2, C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C("Border"))
        surface.DrawRect(pad, sh - 1, sw - pad * 2, 1)
    end
    local scroll = vgui.Create("KF.ScrollPanel", sidebar)
    scroll:SetAddon(AID)
    scroll:SetPos(0, headerH)
    scroll:SetSize(sidebarW, h - headerH)
    local list = vgui.Create("DListLayout", scroll)
    list:SetSize(sidebarW - T("ScrollGutter"), 0)
    return list
end

local function CreateThreePane(parent)
    local w, h = parent:GetSize()
    local pad, sidebarW, detailW, headerH = T("SpaceL"), T("SidebarW"), T("DetailW"), T("PaneHeaderH")
    local listW = w - sidebarW - detailW - pad * 2
    local categories = CreateSidebar(parent, h)
    local listPanel = vgui.Create("DPanel", parent)
    listPanel:SetPos(sidebarW + pad, 0)
    listPanel:SetSize(listW, h)
    listPanel.Paint = KF.Helpers.NoPaint
    local header = vgui.Create("DPanel", listPanel)
    header:SetSize(listW, headerH)
    header.Paint = KF.Helpers.NoPaint
    local scroll = vgui.Create("KF.ScrollPanel", listPanel)
    scroll:SetAddon(AID)
    scroll:SetPos(0, headerH)
    scroll:SetSize(listW, h - headerH)
    local grid = KF.Builders.CardGrid(scroll)
    local detail = vgui.Create("DPanel", parent)
    detail:SetPos(w - detailW, 0)
    detail:SetSize(detailW, h)
    detail.Paint = function(_, dw, dh) KF.Draw.Panel(0, 0, dw, dh, { addonId = AID }) end
    return { categories = categories, header = header, grid = grid, detail = detail }
end

local function PaintDetailHeader(self, sw, sh, item, drawStatus)
    UI.DrawItemIcon(item, 0, 0, sh, { hasModelPanel = self._hasModelPanel, texPad = S(8) })
    local textX = sh + T("SpaceM")
    local sx, sy = self:LocalToScreen(0, 0)
    KF.Draw.ScrollingText("detail_" .. item.id, item.name or L("ui_unknown"), F("SectionTitle"), textX, 0, sw - textX - T("SpaceS"),
        C("TextPrimary"), TEXT_ALIGN_TOP, { useGlow = true, screenX = sx, screenY = sy })
    draw.SimpleText(UI.TypeName(item), F("Body"), textX, S(32), C("TextSecondary"))
    drawStatus(textX, S(56), S(74))
end

local function BuildDetail(state, opts)
    local panel = state._detail
    if not IsValid(panel) then return end
    panel:Clear()
    local item = state.selectedItem
    if not item then
        panel.Paint = function(_, w, h)
            KF.Draw.Panel(0, 0, w, h, { addonId = AID })
            KF.Draw.EmptyState(w, h, L("ui_select_item"), nil, { addonId = AID, showIcon = false })
        end
        return
    end
    panel.Paint = function(_, w, h) KF.Draw.Panel(0, 0, w, h, { addonId = AID }) end
    local gap, actionH = T("SpaceS"), T("ActionH")
    local bottomH = gap + S(36) + gap + (actionH + gap) * #opts.rows
    local scroll, canvas, bottom = KF.Builders.DetailPane(panel, bottomH, AID)
    local pad = T("SpaceL")
    local w = canvas:GetWide() - pad * 2
    local headerH = T("DetailHeaderH")
    local header = vgui.Create("DPanel", canvas)
    header:SetPos(pad, pad)
    header:SetSize(w, headerH)
    header.Paint = function(s, hw, hh) PaintDetailHeader(s, hw, hh, item, opts.drawStatus) end
    UI.AttachModelIcon(header, item, 0, 0, headerH)
    local y = pad + headerH + pad
    y = UI.CreateDescriptionSection(canvas, item, y, w, pad)
    y = UI.CreateItemStatsSection(canvas, item, y, w, pad)
    if opts.fill then y = opts.fill(canvas, y, w, pad) end
    canvas:SetTall(math.max(scroll:GetTall(), y + pad))

    local price = vgui.Create("DPanel", bottom)
    price:SetPos(0, gap)
    price:SetSize(bottom:GetWide(), S(36))
    price.Paint = function()
        draw.SimpleText(opts.priceLabel, F("Meta"), 0, 0, C("TextMuted"))
        draw.SimpleText(opts.priceText, F("Price"), 0, S(14), opts.priceColor)
    end
    local rowY = gap + S(36) + gap
    for _, row in ipairs(opts.rows) do
        row(bottom, rowY, actionH)
        rowY = rowY + actionH + gap
    end
end

local function ActionRow(actions)
    return function(bottom, y, actionH)
        local gap = T("SpaceS")
        local btnW = (bottom:GetWide() - gap * (#actions - 1)) / #actions
        for i, action in ipairs(actions) do
            local btn = UI.Button(bottom, action.label, action.style)
            if action.style then btn:SetSolid(true) end
            btn:SetPos((i - 1) * (btnW + gap), y)
            btn:SetSize(btnW, actionH)
            btn.DoClick = function(s)
                if not s._working then action.onClick(s, action.label) end
            end
        end
    end
end

function UI.PromptPurchase(btn, item, qty, showQty)
    if btn._working then return end
    local msg = L("dialog_purchase_prefix") .. (item.name or L("ui_unknown"))
    if showQty then msg = msg .. L("dialog_quantity_sep") .. qty end
    msg = msg .. L("dialog_for") .. KrakensStore.FormatMoney(KrakensStore:GetItemPrice(LocalPlayer(), item.id, qty)) .. L("dialog_question")
    UI.ConfirmDialog(L("dialog_purchase_item"), msg, L("btn_purchase"), L("btn_cancel"), function()
        UI.RunBusy(btn, L("btn_purchase"), 0.5, function()
            KF.Net.Send("KrakensStore_RequestPurchase", function()
                net.WriteString(item.id)
                net.WriteUInt(qty, 16)
                net.WriteString(IsValid(UI.MainFrame) and UI.MainFrame._npcId or "")
            end)
        end)
    end)
end

local function BuyRow(item, stacking)
    return function(bottom, y, actionH)
        local btnW, x = bottom:GetWide(), 0
        local quantity = 1
        if stacking then
            local qtyW, stepSize = S(100), S(28)
            local qtyPanel = vgui.Create("DPanel", bottom)
            qtyPanel:SetPos(0, y)
            qtyPanel:SetSize(qtyW, actionH)
            qtyPanel.Paint = function(_, sw, sh)
                draw.RoundedBox(KF.UI.Tokens.Radius, 0, 0, sw, sh, C("PanelDark"))
                surface.SetDrawColor(C("Border"))
                surface.DrawOutlinedRect(0, 0, sw, sh, 1)
                draw.SimpleText(tostring(quantity), F("PanelTitle"), sw / 2, sh / 2, C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            local function Stepper(glyph, px, delta)
                local step = vgui.Create("DButton", qtyPanel)
                step:SetPos(px, (actionH - stepSize) / 2)
                step:SetSize(stepSize, stepSize)
                step:SetText("")
                step:SetCursor("hand")
                step.Paint = function(s, bw, bh)
                    draw.SimpleText(glyph, F("PanelTitle"), bw / 2, bh / 2, C(s:IsHovered() and "Accent" or "TextSecondary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                step.DoClick = function()
                    local maxOwned = item.maxOwned or 0
                    local invItem = KrakensStore.Inventory.LocalCache[item.id]
                    local ownedQty = invItem and KrakensStore.GetInvQuantity(invItem) or 0
                    local maxQty = maxOwned > 0 and math.max(1, maxOwned - ownedQty) or 99
                    quantity = math.Clamp(quantity + delta, 1, maxQty)
                    UI.PlaySound("Click")
                end
            end
            Stepper("-", T("SpaceXS"), -1)
            Stepper("+", qtyW - T("SpaceXS") - stepSize, 1)
            x = qtyW + T("SpaceS")
            btnW = btnW - x
        end
        local buy = UI.Button(bottom, L("btn_purchase"), "primary")
        buy:SetSolid(true)
        buy:SetPos(x, y)
        buy:SetSize(btnW, actionH)
        buy.DoClick = function(s) UI.PromptPurchase(s, item, quantity, stacking) end
    end
end

local function OwnedActions(item, isEquipped)
    local typeData = KrakensStore.types[item.type]
    local actions = {}
    if typeData and typeData.equip == true then
        actions[#actions + 1] = { label = L(isEquipped and "btn_unequip" or "btn_equip"), style = "primary", onClick = function(s, label)
            UI.RunBusy(s, label, 0.3, function()
                KF.Net.Send("KrakensStore_RequestEquip", function()
                    net.WriteString(item.id)
                    net.WriteBool(not isEquipped)
                end)
            end)
        end }
    end
    for optionId, option in pairs(typeData and typeData.options or {}) do
        actions[#actions + 1] = { label = L("btn_option_" .. optionId), onClick = function(s, label)
            if option.usePreview then
                local data = item.data or {}
                KrakensStore.VehiclePreview.Start(data.vehicleClass, data.model, item.id, optionId)
                return
            end
            UI.RunBusy(s, label, 0.5, function()
                KF.Net.Send("KrakensStore_RequestUseOption", function()
                    net.WriteString(item.id)
                    net.WriteString(optionId)
                    net.WriteBool(false)
                end)
            end)
        end }
    end
    if KrakensStore.Inventory.CanSell(LocalPlayer(), item.id, 1) == true then
        local sellValue = KrakensStore:GetItemRefund(LocalPlayer(), item.id, 1)
        actions[#actions + 1] = { label = L("btn_sell") .. " " .. KrakensStore.FormatMoney(sellValue), onClick = function(s, label)
            UI.ConfirmDialog(L("dialog_sell_item"),
                L("dialog_sell_prefix") .. (item.name or L("ui_unknown")) .. L("dialog_for") .. KrakensStore.FormatMoney(sellValue) .. L("dialog_question"),
                L("btn_sell"), L("btn_cancel"), function()
                    UI.RunBusy(s, label, 0.3, function()
                        KF.Net.Send("KrakensStore_RequestSell", function()
                            net.WriteString(item.id)
                            net.WriteUInt(1, 16)
                        end)
                    end)
                end)
        end }
    end
    return actions
end

KrakensStore.NPCPlacement = KrakensStore.NPCPlacement or {}
KrakensStore.VehiclePreview = KrakensStore.VehiclePreview or {}

local function ResetState(state)
    state.active = false
    state.model = nil
    state.target = nil
    state.position = Vector(0, 0, 0)
    state.angle = Angle(0, 0, 0)
    state.rotation = 0
    state.isValid = false
    state.invalidReason = ""
    state.clientModel = nil
end

local function StartPlacement(state, hookId, model, target, validatorCfg, titleKey, stopFn)
    state.active = true
    state.hookId = hookId
    state.rotation = 0
    state.isValid = false
    state.invalidReason = ""
    state.model = model
    state.target = target

    if IsValid(state.clientModel) then state.clientModel:Remove() end
    state.clientModel = ClientsideModel(state.model)
    if IsValid(state.clientModel) then
        state.clientModel:SetNoDraw(true)
        state.clientModel:SetRenderMode(RENDERMODE_TRANSALPHA)
    end

    SetupPlacementHooks(state, CreatePlacementValidator(validatorCfg), titleKey, stopFn)
    UI.CloseMenu()
end

local function StopPlacement(state, confirmed, silent, cfg)
    if not state.active then return false end
    local snap = { valid = state.isValid, reason = state.invalidReason, position = state.position, angle = state.angle, target = state.target }
    state.active, state.model, state.target = false, nil, nil
    for event in pairs(state.hooks) do hook.Remove(event, state.hookId) end
    if IsValid(state.clientModel) then state.clientModel:Remove() end
    state.clientModel = nil

    if confirmed and snap.valid then
        cfg.confirm(snap)
    else
        if confirmed then UI.ShowNotification(L(cfg.invalidKey) .. (snap.reason or ""), "error") end
        if not silent then timer.Simple(0.1, function() UI.OpenMenu(nil, cfg.reopenView) end) end
    end
    return true
end

local placement = KrakensStore.NPCPlacement
ResetState(placement)

local NPC_PLACEMENT_STOP = {
    invalidKey = "npc_placement_invalid",
    reopenView = "admin",
    confirm = function(snap)
        KF.Net.Send("KrakensStore_NPCPlacement", function()
            net.WriteString(snap.target.npcId)
            net.WriteBool(true)
            net.WriteVector(snap.position)
            net.WriteAngle(snap.angle)
        end)
    end,
}

function KrakensStore.NPCPlacement.IsActive() return placement.active == true end

function KrakensStore.NPCPlacement.Start(npcId, model, skin, bodygroups)
    StartPlacement(placement, "KrakensStore_NPCPlacement", model or KrakensStore.Config.Entities.NPC.Model, { npcId = npcId },
        { kind = "NPC", waterKey = "npc_placement_water" },
        "npc_placement_title", KrakensStore.NPCPlacement.Stop)
    KF.Utils.ApplyLook(placement.clientModel, skin, bodygroups)
end

function KrakensStore.NPCPlacement.Stop(confirmed, silent)
    StopPlacement(placement, confirmed, silent, NPC_PLACEMENT_STOP)
end

local preview = KrakensStore.VehiclePreview
ResetState(preview)

local function VehicleSpawnPending()
    return (KrakensStore._vehicleSpawnPendingUntil or 0) > CurTime()
end

local VEHICLE_PREVIEW_STOP = {
    invalidKey = "vehicle_invalid_position",
    reopenView = "inventory",
    confirm = function(snap)
        KrakensStore._vehicleSpawnPendingUntil = CurTime() + 10
        KF.Net.Send("KrakensStore_RequestUseOption", function()
            net.WriteString(snap.target.itemId)
            net.WriteString(snap.target.optionID)
            net.WriteBool(true)
            net.WriteVector(snap.position)
            net.WriteAngle(snap.angle)
        end)
    end,
}

function KrakensStore.VehiclePreview.IsActive() return preview.active == true end

local function ResolveVehicleModel(vehicleClass, fallback)
    local model = fallback
    local entTable = scripted_ents.Get(vehicleClass)
    if entTable then
        model = entTable.Model or entTable.WorldModel or entTable.MDL or model
    end
    local stored = scripted_ents.GetStored(vehicleClass)
    if stored and stored.t then
        model = stored.t.Model or stored.t.WorldModel or stored.t.MDL or model
    end
    local simfphysVehicle = list.GetForEdit("simfphys_vehicles")[vehicleClass]
    return simfphysVehicle and simfphysVehicle.Model or model
end

function KrakensStore.VehiclePreview.Start(vehicleClass, model, itemId, optionID)
    local resolved = model or "models/props_vehicles/car001a_physics.mdl"
    if vehicleClass then resolved = ResolveVehicleModel(vehicleClass, resolved) end

    StartPlacement(preview, "KrakensStore_VehiclePreview", resolved, { itemId = itemId, optionID = optionID },
        { kind = "Vehicle", waterKey = "vehicle_cannot_spawn_water" },
        "vehicle_placement_title", KrakensStore.VehiclePreview.Stop)

    hook.Run("KrakensStore_VehiclePreviewStarted", vehicleClass)
end

function KrakensStore.VehiclePreview.Stop(confirmed, silent)
    if StopPlacement(preview, confirmed, silent, VEHICLE_PREVIEW_STOP) then
        hook.Run("KrakensStore_VehiclePreviewStopped", confirmed)
    end
end

local CHUNK_TIMEOUT = 30

local function ChunkReceiver(label, onComplete)
    local state
    local timerName = "KrakensStore_Chunks_" .. label
    return function()
        local index = net.ReadUInt(16)
        local total = net.ReadUInt(16)
        local part = KF.Net.ReadCompressed(32, KrakensStore.Validation.Limits.MAX_DECOMPRESSED)
        if total <= 0 or total > 512 or index <= 0 or index > total then return end
        if not part then
            KrakensStore.Log("warn", label .. ": failed to decompress chunk " .. index .. "/" .. total)
            return
        end
        if not state or state.total ~= total or index == 1 then state = { total = total, parts = {}, received = 0 } end
        if not state.parts[index] then
            state.parts[index] = part
            state.received = state.received + 1
        end
        timer.Create(timerName, CHUNK_TIMEOUT, 1, function()
            KrakensStore.Log("warn", label .. ": transfer timed out, requesting a full re-sync")
            state = nil
            KrakensStore.Net.RequestSync()
        end)
        if state.received < state.total then return end
        timer.Remove(timerName)
        local parts = state.parts
        state = nil
        onComplete(parts)
    end
end

KF.Net.Receive("KrakensStore_SyncInventory", ChunkReceiver("SyncInventory", function(parts)
    local cache = KrakensStore.Inventory.LocalCache
    table.Empty(cache)
    for _, part in ipairs(parts) do
        for itemId, invItem in pairs(part) do cache[itemId] = invItem end
    end
    if IsValid(UI.MainFrame) then
        hook.Run("KrakensStore_InventoryUpdated")
    end
end))

KF.Net.Receive("KrakensStore_UpdateItem", function()
    local itemId = net.ReadString()
    local hasData = net.ReadBool()

    if not itemId or itemId == "" then return end

    if hasData then
        local invItem = KF.Net.ReadCompressed(16)
        if invItem then
            KrakensStore.Inventory.LocalCache[itemId] = invItem
        else
            KrakensStore.Log("warn", "UpdateItem: failed to decompress item data for", tostring(itemId))
        end
    else
        KrakensStore.Inventory.LocalCache[itemId] = nil
    end

    if IsValid(UI.MainFrame) then
        timer.Create("KrakensStore_DebouncedInvUpdate", 0.1, 1, function()
            hook.Run("KrakensStore_InventoryUpdated")
        end)
    end
end)

KF.Net.Receive("KrakensStore_Notification", function()
    local message = net.ReadString()
    local notifType = net.ReadString()
    local soundKey = net.ReadString()

    UI.ShowNotification(message, notifType)
    if soundKey ~= "" then UI.PlaySound(soundKey) end

    if VehicleSpawnPending() and notifType ~= "info" then
        KrakensStore._vehicleSpawnPendingUntil = nil
        if notifType ~= "success" then
            timer.Simple(0.2, function()
                if not IsValid(UI.MainFrame) then UI.OpenMenu(nil, "inventory") end
            end)
        end
    end
end)

local function ReplaceById(cache, rows)
    table.Empty(cache)
    for id, row in pairs(rows or {}) do
        id = tostring(id)
        if id ~= "" and istable(row) then
            row.id = id
            cache[id] = row
        end
    end
end

KF.Net.Receive("KrakensStore_SyncStoreData", ChunkReceiver("SyncStoreData", function(parts)
    local items = {}
    for _, part in ipairs(parts) do
        for _, item in ipairs(part.items or {}) do items[item.id] = item end
    end
    ReplaceById(KrakensStore.Items.Cache, items)
    ReplaceById(KrakensStore.Categories.Cache, parts[1].categories)
    ReplaceById(KrakensStore.NPCs.Cache, parts[1].npcs)
    KrakensStore._initialSyncReceived = true
    timer.Remove("KrakensStore_SyncRetry")

    hook.Run("KrakensStore_StoreDataUpdated")
    hook.Run("KrakensStore_NPCsSynced")

    if IsValid(UI.MainFrame) or next(KrakensStore.Inventory.LocalCache) then
        hook.Run("KrakensStore_InventoryUpdated")
    end
end))

KF.Net.Receive("KrakensStore_StoreState", function()
    local phase = net.ReadString() or "UNINITIALIZED"
    local failure = net.ReadString() or ""
    local state = KrakensStore.ServerState
    if state.phase == phase and state.failure == failure then return end
    state.phase = phase
    state.failure = failure
    hook.Run("KrakensStore_StoreStateChanged", phase, failure)
end)

KF.Net.Receive("KrakensStore_SyncSettings", function()
    local settings = KF.Net.ReadCompressed(16, KrakensStore.Validation.Limits.MAX_DECOMPRESSED) or {}
    KrakensStore.Config.ApplySettings(settings)
    KF.Lang.SetLanguage(AID, KrakensStore.Config.General.Language)

    hook.Run("KrakensStore_SettingsUpdated", settings)
end)

local ENTITY_KINDS = {
    item = { store = KrakensStore.Items, catalog = true, updated = "KrakensStore_ItemDefinitionUpdated", deleted = "KrakensStore_ItemDefinitionDeleted" },
    category = { store = KrakensStore.Categories, catalog = true, updated = "KrakensStore_CategoryUpdated", deleted = "KrakensStore_CategoryDeleted" },
    npc = { store = KrakensStore.NPCs, updated = "KrakensStore_NPCUpdated", deleted = "KrakensStore_NPCDeleted" },
}

KF.Net.Receive("KrakensStore_EntitySync", function()
    local kindName = net.ReadString()
    local kind = ENTITY_KINDS[kindName]
    local id = net.ReadString()
    if not kind or id == "" then return end

    if net.ReadBool() then
        local entity = KF.Net.ReadCompressed(16)
        if not entity then
            KrakensStore.Log("warn", "EntitySync: failed to decompress " .. kindName .. " " .. id)
            return
        end
        kind.store.Cache[id] = entity
        hook.Run(kind.updated, id, entity)
    else
        kind.store.Cache[id] = nil
        hook.Run(kind.deleted, id)
    end
    if kind.catalog then
        timer.Create("KrakensStore_DebouncedStoreUpdate", 0.1, 1, function()
            hook.Run("KrakensStore_StoreDataUpdated")
        end)
    end
end)

function KrakensStore.GetInvQuantity(inv)
    return (type(inv) == "table" and tonumber(inv.quantity)) or 1
end

function KrakensStore.IsInvEquipped(inv)
    return type(inv) == "table" and inv.equipped == true
end

local lastSyncAt = -math.huge

function KrakensStore.Net.RequestSync()
    local wait = lastSyncAt + KrakensStore.SyncCooldown - CurTime()
    if wait > 0 then
        timer.Create("KrakensStore_DebouncedSync", wait + 0.1, 1, KrakensStore.Net.RequestSync)
        return
    end
    lastSyncAt = CurTime()
    KF.Net.Send("KrakensStore_RequestSync")
end

hook.Add("InitPostEntity", "KrakensStore_Init", function()
    LoadClientPrefs()
    timer.Simple(2, KrakensStore.Net.RequestSync)
    timer.Create("KrakensStore_SyncRetry", 15, 0, function()
        if KrakensStore._initialSyncReceived then timer.Remove("KrakensStore_SyncRetry") return end
        if KrakensStore.ServerState.phase == "READY" then
            KrakensStore.Log("warn", "Server reports READY but no catalog arrived, requesting it again")
        end
        KrakensStore.Net.RequestSync()
    end)
end)

hook.Add("KF_LanguageChanged", "KrakensStore_RefreshLanguageUI", function(addonId)
    local frame = UI.MainFrame
    if addonId ~= AID or not IsValid(frame) then return end
    UI.OpenMenu(frame._npcId, frame._currentView)
end)

local function ResolveViewId(viewId)
    if viewId ~= "store" and viewId ~= "inventory" and viewId ~= "settings" and viewId ~= "admin" then
        return "store"
    end
    if viewId == "admin" and not (IsValid(LocalPlayer()) and KrakensStore.IsAdmin(LocalPlayer())) then
        return "store"
    end
    return viewId
end

function UI.OpenMenu(npcId, view)
    if VehicleSpawnPending() or KrakensStore.VehiclePreview.IsActive() then return end

    UI.CancelTransientModes()

    if IsValid(UI.MainFrame) then UI.MainFrame:Remove() end

    if not KrakensStore._initialSyncReceived then
        KrakensStore.Net.RequestSync()
    end

    local frame = vgui.Create("EditablePanel")
    frame._addonId = AID
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(true)
    frame._open = 0
    frame.Paint = function(s, w, h)
        s._open = math.min(s._open + KF.Anim.GetFrameTime() * 5, 1)
        KF.Draw.AppBackground(s, w, h, s._open, KrakensStore.ClientPrefs.blur ~= false)
    end
    frame.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE then UI.CloseMenu() end
    end
    frame.Think = function()
        if gui.IsGameUIVisible() then
            gui.HideGameUI()
            UI.CloseMenu()
        end
    end
    frame.OnRemove = function(self)
        if UI.MainFrame == self then UI.MainFrame = nil end
        UI.CloseAllPopups()
    end

    UI.MainFrame = frame
    frame._npcId = npcId
    frame._currentView = ResolveViewId(view or KrakensStore.ClientPrefs[LAST_VIEW_PREF_KEY])

    UI.BuildMainContent(frame)
    UI.PlaySound("Open")
end

function UI.CloseMenu()
    if not IsValid(UI.MainFrame) then return end
    UI.PlaySound("Close")
    UI.MainFrame:Remove()
end

function UI.ToggleMenu()
    if IsValid(UI.MainFrame) then UI.CloseMenu() else UI.OpenMenu() end
end

KF.Net.Receive("KrakensStore_OpenMenu", function()
    local view = net.ReadString()
    local npcConfigId = net.ReadString()
    UI.OpenMenu(npcConfigId ~= "" and npcConfigId or nil, view ~= "store" and view or nil)
end)

function UI.OpenAdminToItem(item)
    KrakensStore.Admin.PendingEditItem = item
    local frame = UI.MainFrame
    if not IsValid(frame) then
        UI.OpenMenu(nil, "admin")
        return
    end
    UI.SwitchView(frame, "admin", true)
    timer.Simple(0, function()
        if IsValid(frame) then frame:MakePopup() end
    end)
end

function UI.BuildMainContent(frame)
    local tabs = {
        { id = "store", name = L("tab_store") },
        { id = "inventory", name = L("tab_inventory") },
        { id = "settings", name = L("tab_settings") },
    }
    if KrakensStore.IsAdmin(LocalPlayer()) then
        tabs[#tabs + 1] = { id = "admin", name = L("tab_admin") }
    end

    local shell = KF.Builders.Shell()
        :SetFrame(frame)
        :SetAddon(AID)
        :SetTitle(KrakensStore.Config.General.StoreName, L("ui_store_subtitle"))
        :SetClose(UI.CloseMenu)
        :SetPlayer({
            money = function(ply) return KrakensStore.FormatMoney(KF.Currency.Get(ply, KrakensStore.CurrencyKey)) end,
            labels = { credits = L("ui_credits"), player = L("ui_player"), unknown = L("ui_unknown") },
        })
        :SetTabs(tabs)
        :SetActiveTab(frame._currentView or "store")
        :SetOnSwitch(function(id) UI.SwitchView(frame, id) end)
        :Build()

    frame._tabButtons = {}
    for _, btn in ipairs(shell.tabButtons) do
        frame._tabButtons[btn._tabId] = btn
    end
    frame._contentPanel = shell.content
    UI.SwitchView(frame, frame._currentView or "store", true)
end

function UI.SwitchView(frame, viewId, isInitial)
    if not IsValid(frame) or not IsValid(frame._contentPanel) then return end
    viewId = ResolveViewId(viewId)
    if not isInitial and frame._currentView == viewId then return end
    for id, btn in pairs(frame._tabButtons or {}) do
        if btn.SetActive then btn:SetActive(id == viewId) end
    end
    UI.CloseAllPopups()
    frame._contentPanel:Clear()
    local root = vgui.Create("Panel", frame._contentPanel)
    root:SetSize(frame._contentPanel:GetSize())
    frame._currentView = viewId
    UI.SetClientPref(LAST_VIEW_PREF_KEY, viewId)
    if viewId == "store" then
        UI.BuildStoreView(root)
    elseif viewId == "inventory" then
        UI.BuildInventoryView(root)
    elseif viewId == "settings" then
        UI.BuildSettingsView(root)
    else
        UI.BuildAdminView(root)
    end
end

function UI.BuildSettingsView(parent)
    local pad = T("SpaceXL")
    local contentW = math.min(parent:GetWide() - pad * 2, S(720))
    local form = vgui.Create("DListLayout", parent)
    form:SetPos(pad, pad)
    form:SetSize(contentW, parent:GetTall() - pad * 2)
    local prefs = KrakensStore.ClientPrefs

    local function KeyName(code)
        return string.upper(input.GetKeyName(code or 0) or (L("ui_key_prefix") .. tostring(code or 0)))
    end

    local keyBtn = UI.Button(nil, KeyName(UI.OpenKey()))
    keyBtn:SetSize(S(160), T("ButtonH"))
    keyBtn:SetKeyboardInputEnabled(false)
    local function StopCapture(s)
        s._listening = false
        s:SetKeyboardInputEnabled(false)
        s:SetLabel(KeyName(UI.OpenKey()))
    end
    keyBtn.DoClick = function(s)
        s._listening = true
        s:SetKeyboardInputEnabled(true)
        s:RequestFocus()
        s:SetLabel(L("pref_press_key"))
    end
    keyBtn.OnKeyCodePressed = function(s, key)
        if not s._listening then return end
        if key ~= KEY_ESCAPE and key >= KEY_FIRST and key <= KEY_LAST and input.GetKeyName(key) then
            UI.SetClientPref("openKey", key)
        end
        StopCapture(s)
        return true
    end
    keyBtn.OnLoseFocus = function(s) if s._listening then StopCapture(s) end end
    form:Add(KF.FormBuilder.PrefRow(form, L("pref_open_key"), L("pref_open_key_desc"), keyBtn, { addonId = AID, width = contentW }))

    for _, pref in ipairs({ { key = "sounds", label = "pref_sounds" }, { key = "blur", label = "pref_blur" } }) do
        local cb = vgui.Create("KF.Checkbox")
        cb:SetAddon(AID)
        cb:SetSize(T("ButtonHSmall"), T("ButtonHSmall"))
        cb:SetChecked(prefs[pref.key] ~= false)
        cb.OnChange = function(_, checked) UI.SetClientPref(pref.key, checked) end
        form:Add(KF.FormBuilder.PrefRow(form, L(pref.label), L(pref.label .. "_desc"), cb, { addonId = AID, width = contentW }))
    end
end

function UI.GetStoreItems(npcId)
    if npcId and npcId ~= "" then
        return KrakensStore.NPCs.GetItemsForNPC(npcId)
    end
    return KrakensStore.Items.GetAll()
end

local function BindStoreRefresh(parent, refresh)
    hook.Add("KrakensStore_StoreDataUpdated", parent, refresh)
    hook.Add("KrakensStore_StoreStateChanged", parent, refresh)
    hook.Add("KrakensStore_InventoryUpdated", parent, refresh)
end

function UI.BuildStoreView(parent)
    if not KrakensStore._initialSyncReceived then
        UI.BuildStatePanel(parent, UI.BuildStoreView)
        return
    end
    local state = {
        selectedCategory = "all",
        selectedItem = nil,
        searchQuery = "",
        npcId = IsValid(UI.MainFrame) and UI.MainFrame._npcId or nil,
    }
    local panes = CreateThreePane(parent)
    state._grid, state._detail, state._categories = panes.grid, panes.detail, panes.categories
    local headerH = panes.header:GetTall()
    local search = UI.CreateSearchBar(panes.header, S(300), L("ui_search_placeholder"), function(query)
        if state.searchQuery == query then return end
        state.searchQuery = query
        UI.RefreshStoreList(parent, state)
    end)
    search:SetPos(0, math.floor((headerH - search:GetTall()) / 2))
    local sort = UI.CreateSortDropdown(panes.header, function(mode)
        state.sortMode = mode
        UI.RefreshStoreList(parent, state)
    end)
    sort:SetPos(search:GetWide() + T("SpaceS"), math.floor((headerH - sort:GetTall()) / 2))

    local function refresh()
        local catCounts = { all = 0 }
        for _, item in pairs(UI.GetStoreItems(state.npcId)) do
            if item.enabled ~= false then
                catCounts.all = catCounts.all + 1
                local cat = item.category or KrakensStore.Schema.OrphanCategoryId
                catCounts[cat] = (catCounts[cat] or 0) + 1
            end
        end
        UI.BuildCategoryButtons(state._categories, catCounts, state.selectedCategory, function(catId)
            state.selectedCategory = catId
            UI.RefreshStoreList(parent, state)
        end)
        UI.RefreshStoreList(parent, state)
        UI.RefreshStoreDetails(parent, state)
    end
    refresh()
    BindStoreRefresh(parent, refresh)
end

function UI.RefreshStoreList(parent, state)
    if not IsValid(state._grid) then return end
    state._grid:Clear()
    state._cardById = {}
    local baseItems = UI.GetStoreItems(state.npcId)
    local query = KF.NormalizeQuery(state.searchQuery)
    local hideNonPurchasable = KrakensStore.Config.General.HideNonPurchasable == true
    local filteredItems = {}
    for _, item in pairs(baseItems) do
        local visible = item.enabled ~= false
            and (state.selectedCategory == "all" or item.category == state.selectedCategory)
            and KF.MatchesQuery(item.name, query)
        if visible and hideNonPurchasable and not KrakensStore.Inventory.CanAccessItem(LocalPlayer(), item.id, item) then visible = false end
        if visible then filteredItems[#filteredItems + 1] = item end
    end
    UI.SortItems(filteredItems, state.sortMode)
    if #filteredItems == 0 then
        if state.selectedItem then
            state.selectedItem = nil
            UI.RefreshStoreDetails(parent, state)
        end
        local title = next(KrakensStore.Items.Cache) and L("store_no_items_found") or L("ui_store_empty_ready")
        KF.Builders.EmptyRow(state._grid, title, nil, { addonId = AID })
        return
    end
    if state.selectedItem then
        local live
        for _, item in ipairs(filteredItems) do
            if item.id == state.selectedItem.id then live = item break end
        end
        state.selectedItem = live
        if not live then UI.RefreshStoreDetails(parent, state) end
    end
    for _, item in ipairs(filteredItems) do
        local invItem = KrakensStore.Inventory.LocalCache[item.id]
        local priceStr = KrakensStore.FormatMoney(KrakensStore:GetItemPrice(LocalPlayer(), item.id, 1))
        local card = UI.CreateItemCard(state._grid, item, {
            showBadge = function(s) return s._equipped end,
            drawInfo = function(s, textX, y)
                if s._owned then
                    draw.SimpleText(L("store_owned"), F("Value"), textX, y, C("Success"))
                else
                    draw.SimpleText(priceStr, F("Value"), textX, y, C("TextAccent"))
                end
            end,
            onLeft = function(self) UI.SelectCard(state, self, parent, UI.RefreshStoreDetails) end,
            onRight = function(self)
                if not KrakensStore.IsAdmin(LocalPlayer()) then return end
                local editItem = item
                UI.OpenContextMenu({
                    { text = L("btn_edit"), callback = function()
                        timer.Simple(0, function() UI.OpenAdminToItem(editItem) end)
                    end },
                    { spacer = true },
                    { text = L("btn_delete"), callback = function()
                        timer.Simple(0, function()
                            KrakensStore.Admin.ConfirmDelete({
                                titleKey = "dialog_delete_item",
                                id = editItem.id, name = editItem.name,
                                action = "delete_item",
                                onSuccess = function()
                                    UI.RefreshStoreList(parent, state)
                                    UI.RefreshStoreDetails(parent, state)
                                end,
                            })
                        end)
                    end }
                })
            end,
        })
        card._owned = invItem ~= nil
        card._equipped = invItem ~= nil and invItem.equipped == true
        card._selected = state.selectedItem ~= nil and state.selectedItem.id == item.id
        state._cardById[item.id] = card
        state._grid:Add(card)
    end
end

function UI.RefreshStoreDetails(parent, state)
    local item = state.selectedItem
    if not item then BuildDetail(state, { rows = {} }) return end
    local invItem = KrakensStore.Inventory.LocalCache[item.id]
    local owned, equipped = invItem ~= nil, invItem ~= nil and invItem.equipped == true
    local typeData = KrakensStore.types[item.type]
    local stacking = typeData and typeData.stacking == true
    local rows = {}
    if owned then
        local actions = OwnedActions(item, equipped)
        if #actions > 0 then rows[#rows + 1] = ActionRow(actions) end
    end
    if stacking or not owned then rows[#rows + 1] = BuyRow(item, stacking) end
    local categoryLine = L("store_category_prefix") .. UI.GetCategoryName(item.category)
    BuildDetail(state, {
        rows = rows,
        priceLabel = L("store_price"),
        priceText = owned and L("store_owned") or KrakensStore.FormatMoney(KrakensStore:GetItemPrice(LocalPlayer(), item.id, 1)),
        priceColor = C(owned and "Success" or "TextAccent"),
        drawStatus = function(textX, y1, y2)
            if equipped then
                draw.SimpleText(L("inv_currently_equipped"), F("Meta"), textX, y1, C("Success"))
            elseif owned then
                draw.SimpleText(L("store_owned_label"), F("Meta"), textX, y1, C("Success"))
            end
            draw.SimpleText(categoryLine, F("Meta"), textX, y2, C("TextMuted"))
        end,
    })
end

function UI.BuildInventoryView(parent)
    if not KrakensStore._initialSyncReceived then
        UI.BuildStatePanel(parent, UI.BuildInventoryView)
        return
    end
    local state = { selectedCategory = "all", selectedItem = nil }
    local panes = CreateThreePane(parent)
    state._grid, state._detail, state._categories = panes.grid, panes.detail, panes.categories
    panes.header.Paint = function(_, _, sh)
        draw.SimpleText(L("inv_your_inventory"), F("SectionTitle"), 0, sh / 2 - S(10), C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local count = state._validCount or 0
        local countStr = count == 1 and L("inv_item_count_1") or string.format(L("inv_item_count_n"), count)
        draw.SimpleText(countStr, F("Meta"), 0, sh / 2 + S(12), C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local function refresh()
        local inventory = KrakensStore.Inventory.LocalCache or {}
        local catCounts = { all = 0 }
        for itemId in pairs(inventory) do
            local item = KrakensStore.Items.Get(itemId)
            if item then
                catCounts.all = catCounts.all + 1
                local cat = item.category or KrakensStore.Schema.OrphanCategoryId
                catCounts[cat] = (catCounts[cat] or 0) + 1
            end
        end
        state._validCount = catCounts.all
        UI.BuildCategoryButtons(state._categories, catCounts, state.selectedCategory, function(catId)
            state.selectedCategory = catId
            UI.RefreshInventoryList(parent, state)
        end)
        UI.RefreshInventoryList(parent, state)
        UI.RefreshInventoryDetails(parent, state)
    end
    refresh()
    BindStoreRefresh(parent, refresh)
end

function UI.RefreshInventoryList(parent, state)
    if not IsValid(state._grid) then return end
    state._grid:Clear()
    state._cardById = {}
    local items = {}
    for itemId, invItem in pairs(KrakensStore.Inventory.LocalCache or {}) do
        local item = KrakensStore.Items.Get(itemId)
        if item then
            local cat = item.category or KrakensStore.Schema.OrphanCategoryId
            if state.selectedCategory == "all" or cat == state.selectedCategory then
                items[#items + 1] = { inv = invItem, data = item, equipped = KrakensStore.IsInvEquipped(invItem) }
            end
        end
    end
    table.sort(items, function(a, b)
        if a.equipped ~= b.equipped then return a.equipped end
        return (a.data.name or "") < (b.data.name or "")
    end)
    if state.selectedItem then
        local live
        for _, entry in ipairs(items) do
            if entry.data.id == state.selectedItem.id then live = entry.data break end
        end
        state.selectedItem = live
        if not live then UI.RefreshInventoryDetails(parent, state) end
    end
    if #items == 0 then
        KF.Builders.EmptyRow(state._grid, L("store_no_items_category"), L("inv_purchase_hint"), { addonId = AID })
        return
    end
    for _, entry in ipairs(items) do
        local card = UI.CreateItemCard(state._grid, entry.data, {
            invItem = entry.inv,
            accent = function(s) return KrakensStore.IsInvEquipped(s._invItem) and C("Success") or nil end,
            showBadge = function(s) return KrakensStore.IsInvEquipped(s._invItem) end,
            drawInfo = function(s, textX, y)
                local qty = KrakensStore.GetInvQuantity(s._invItem)
                if qty > 1 then draw.SimpleText(L("ui_quantity_prefix") .. qty, F("Value"), textX, y, C("TextAccent")) end
            end,
            onLeft = function(self) UI.SelectCard(state, self, parent, UI.RefreshInventoryDetails) end,
            onRight = function(self)
                if not KrakensStore.IsAdmin(LocalPlayer()) then return end
                local editItem = entry.data
                UI.OpenContextMenu({
                    { text = L("btn_edit"), callback = function()
                        timer.Simple(0, function() UI.OpenAdminToItem(editItem) end)
                    end },
                })
            end,
        })
        card._selected = state.selectedItem ~= nil and state.selectedItem.id == entry.data.id
        state._cardById[entry.data.id] = card
        state._grid:Add(card)
    end
end

function UI.RefreshInventoryDetails(parent, state)
    local item = state.selectedItem
    if not item then BuildDetail(state, { rows = {} }) return end
    local invItem = KrakensStore.Inventory.LocalCache[item.id]
    local isEquipped = KrakensStore.IsInvEquipped(invItem)
    local actions = OwnedActions(item, isEquipped)
    local sellValue = KrakensStore:GetItemRefund(LocalPlayer(), item.id, 1)
    BuildDetail(state, {
        rows = #actions > 0 and { ActionRow(actions) } or {},
        priceLabel = L("inv_sell_value"),
        priceText = KrakensStore.FormatMoney(sellValue),
        priceColor = C("TextAccent"),
        drawStatus = function(textX, y1, y2)
            if isEquipped then draw.SimpleText(L("inv_currently_equipped"), F("Meta"), textX, y1, C("Success")) end
            local qty = KrakensStore.GetInvQuantity(invItem)
            if qty > 1 then draw.SimpleText(L("inv_quantity_prefix") .. qty, F("Meta"), textX, y2, C("TextMuted")) end
        end,
        fill = function(canvas, y, w, pad)
            y = SectionLabel(canvas, L("inv_item_info"), pad, y, w)
            local infoItems = {
                { label = L("inv_category"), value = UI.GetCategoryName(item.category) },
            }
            if item.price then infoItems[#infoItems + 1] = { label = L("inv_original_price"), value = KrakensStore.FormatMoney(item.price) } end
            if invItem and invItem.expires and invItem.expires > 0 then
                local timeLeft = invItem.expires - os.time()
                local timeStr = L("inv_expired")
                if timeLeft > 0 then
                    if timeLeft < 3600 then
                        timeStr = math.floor(timeLeft / 60) .. L("time_minutes_short")
                    elseif timeLeft < 86400 then
                        timeStr = math.floor(timeLeft / 3600) .. L("time_hours_short")
                    else
                        timeStr = math.floor(timeLeft / 86400) .. L("time_days_short")
                    end
                end
                infoItems[#infoItems + 1] = { label = L("inv_expires_in"), value = timeStr }
            end
            return UI.CreateInfoRows(canvas, infoItems, pad, y, w)
        end,
    })
end

concommand.Add("krakens_store", function()
    if not KrakensStore.Config.General.RequireEntity then UI.OpenMenu() end
end)

concommand.Add("krakens_store_toggle", function()
    if KrakensStore.Config.General.RequireEntity then
        UI.CloseMenu()
        return
    end
    UI.ToggleMenu()
end)

concommand.Add("krakens_store_inventory", function() UI.OpenMenu(nil, "inventory") end)

concommand.Add("krakens_store_admin", function()
    local ply = LocalPlayer()
    local isAdmin = IsValid(ply) and KrakensStore.IsAdmin(ply)
    if not isAdmin and KrakensStore.Config.General.RequireEntity then
        UI.ShowNotification(L("err_must_use_terminal"), "error")
        return
    end
    UI.OpenMenu(nil, "admin")
end)

concommand.Add("krakens_store_close", function() UI.CloseMenu() end)

local lastKeyPress = 0

hook.Add("PlayerButtonDown", "KrakensStore_Keybind", function(ply, key)
    if not IsFirstTimePredicted() then return end
    if gui.IsConsoleVisible() or gui.IsGameUIVisible() then return end
    if IsValid(vgui.GetKeyboardFocus()) then return end

    if key ~= UI.OpenKey() then return end

    local now = CurTime()
    if now - lastKeyPress < 0.3 then return end
    lastKeyPress = now

    if KrakensStore.Config.General.RequireEntity then
        UI.ShowNotification(L("err_must_use_terminal"), "error")
        return
    end
    UI.OpenMenu()
end)

KrakensStore._atWorkbench = false

KF.Net.Receive("KrakensStore_OpenWorkbench", function()
    local isARC9 = net.ReadBool()
    KrakensStore._atWorkbench = true
    local weapon = LocalPlayer():GetActiveWeapon()
    if not IsValid(weapon) then
        KrakensStore._atWorkbench = false
        return
    end
    if isARC9 then
        if weapon.ToggleCustomize then
            weapon:ToggleCustomize(true)
        elseif weapon.SetCustomize then
            weapon:SetCustomize(true)
        end
    else
        if weapon.ToggleCustomizeHUD then
            weapon:ToggleCustomizeHUD(true)
        end
    end
    timer.Create("KrakensStore_WorkbenchTimeout", 0.5, 0, function()
        local wpn = LocalPlayer():GetActiveWeapon()
        if not IsValid(wpn) then
            KrakensStore._atWorkbench = false
            timer.Remove("KrakensStore_WorkbenchTimeout")
            return
        end
        local inCustomize = false
        if wpn.ARC9 and wpn.GetCustomize then
            inCustomize = wpn:GetCustomize()
        elseif wpn.ArcCW and wpn.GetState and ArcCW then
            inCustomize = (wpn:GetState() == (ArcCW.STATE_CUSTOMIZE or 4))
        end
        if not inCustomize then
            KrakensStore._atWorkbench = false
            timer.Remove("KrakensStore_WorkbenchTimeout")
        end
    end)
end)

local lastBlockNotify = 0

KrakensStore.Workbench.InstallGate(function()
    if CurTime() - lastBlockNotify < 1 then return end
    lastBlockNotify = CurTime()
    UI.ShowNotification(L("err_must_use_workbench"), "error")
end)
