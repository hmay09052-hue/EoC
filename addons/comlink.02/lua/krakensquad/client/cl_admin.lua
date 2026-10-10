local AID    = KrakenSquad.AID
local P      = KrakenSquad.P
local SOUNDS = KrakenSquad.SOUNDS

local function F(n)  return KF.Fonts.Get(AID, n) end
local function FB(n) return KF.Fonts.GetBold(AID, n) end

local function SectionDesc(key) return KrakenSquad.L("admin_desc_" .. key) end
local function SendConfig(tbl) KF.Net.SendJSON("KS.AdminConfigUpdate", tbl) end

local SIDEBAR_GROUPS = {
    { labelKey = "sidebar_core",       items = { "general", "presets" } },
    { labelKey = "sidebar_gameplay",   items = { "positions", "communications", "commands", "respawns" } },
    { labelKey = "sidebar_orders",     items = { "orders", "permanent_orders" } },
    { labelKey = "sidebar_rewards",    items = { "xp", "money" } },
    { labelKey = "sidebar_appearance", items = { "colors", "sounds" } },
    { labelKey = "sidebar_system",     items = { "npcs", "binds", "language", "mrs" } },
}

local activeSection = "general"
local adminFrame
local formW = 0
local editingPreset, editingPresetIdx
local editingOrder,  editingOrderIdx, editingOrderSource

local function Rebuild()
    if adminFrame and adminFrame._rebuildContent then adminFrame._rebuildContent() end
end

local function FieldOpts(opts)
    opts = opts or {}
    if formW > 0 and not opts.width then opts.width = formW end
    return opts
end

local function FormHeader(scroll, title, desc) return KrakenSquad.FormHeader(scroll, title, desc, formW) end
local function FormSpacer(scroll, h)           return KrakenSquad.FormSpacer(scroll, h) end
local function FormField(scroll, label, value, onChange, opts)
    return KrakenSquad.FormField(scroll, label, value, onChange, FieldOpts(opts))
end
local function FormToggle(scroll, label, checked, onChange, desc)
    return KrakenSquad.FormToggle(scroll, label, checked, onChange, desc, formW)
end
local function FormNumber(scroll, label, value, onChange, opts)
    return KrakenSquad.FormNumber(scroll, label, value, onChange, FieldOpts(opts))
end
local function FormDropdown(scroll, label, value, choices, onChange, desc)
    return KrakenSquad.FormDropdown(scroll, label, value, choices, onChange, desc, formW)
end

local function SaveBtn(parent, label, onClick)
    local btn = vgui.Create("KF.Button", parent)
    btn:Dock(TOP); btn:SetTall(KF.Scale(32))
    btn:DockMargin(0, KF.Scale(10), 0, KF.Scale(14))
    btn:SetAddon(AID); btn:SetLabel(label or KrakenSquad.L("admin_save"))
    btn:SetStyle("success"); btn:SetSolid(true)
    btn.DoClick = function() KF.Helpers.PlaySound(SOUNDS.click); onClick() end
    return btn
end

local function DeleteBtn(parent, label, onClick)
    local btn = vgui.Create("KF.Button", parent)
    btn:Dock(TOP); btn:SetTall(KF.Scale(28))
    btn:DockMargin(0, KF.Scale(4), 0, KF.Scale(4))
    btn:SetAddon(AID); btn:SetLabel(label or KrakenSquad.L("admin_delete"))
    btn:SetStyle("danger"); btn:SetSolid(true)
    btn.DoClick = function() KF.Helpers.PlaySound(SOUNDS.click); onClick() end
    return btn
end

local function AdminKeyBinder(parent, label, currentKey, configKey, pending)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP); row:SetTall(KF.Scale(36))
    row:DockMargin(0, KF.Scale(2), 0, 0); row._hoverLerp = 0
    row.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.LerpColor(s._hoverLerp, P("PanelDark"), P("PanelHover")))
        draw.SimpleText(label, F("small"), KF.Scale(12), h / 2,
            P("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local b = vgui.Create("DBinder", row)
    b:Dock(RIGHT); b:DockMargin(0, KF.Scale(4), KF.Scale(12), KF.Scale(4))
    b:SetWide(KF.Scale(140)); b:SetValue(currentKey); b:SetText(""); b._hoverLerp = 0
    b.Paint = function(s, w, h)
        s._hoverLerp = KF.Anim.FastLerp(s._hoverLerp, s.Hovered and 1 or 0, 10)
        KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.LerpColor(s._hoverLerp, P("PanelDark"), P("PanelHover")))
        surface.SetDrawColor(KF.UI.LerpColor(s._hoverLerp, P("Border"), P("Accent")))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local key = s.Trapping and KrakenSquad.L("admin_press_key")
            or (input.GetKeyName(s:GetSelectedNumber()) or KrakenSquad.L("key_none"))
        draw.SimpleText(key:upper(), F("small"), w / 2, h / 2, P("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.UpdateText = function(s) s:SetText("") end
    b.OnCursorEntered = function() KF.Helpers.PlaySound(SOUNDS.hover) end
    b.DoClick = function(s)
        KF.Helpers.PlaySound(SOUNDS.click)
        s:SetText(""); input.StartKeyTrapping(); s.Trapping = true
    end
    b.OnChange = function(_, num) if num and num > 0 then pending[configKey] = num end end
end

local function BuildGeneral(scroll)
    local pending = {}
    FormHeader(scroll, KrakenSquad.L("admin_general"), SectionDesc("general"))

    FormToggle(scroll, KrakenSquad.L("admin_block_damage"),
        KrakenSquad.GetConfig("blockDamage"),
        function(v) pending.blockDamage = v end, KrakenSquad.L("admin_prevent_ff"))
    FormToggle(scroll, KrakenSquad.L("admin_show_avatars"),
        KrakenSquad.GetConfig("showAvatars"),
        function(v) pending.showAvatars = v end, KrakenSquad.L("admin_show_avatars_desc"))
    FormToggle(scroll, KrakenSquad.L("admin_comm_markers"),
        KrakenSquad.GetConfig("commMarkers") ~= false,
        function(v) pending.commMarkers = v end, KrakenSquad.L("admin_comm_markers_desc"))
    FormNumber(scroll, KrakenSquad.L("admin_max_members"),
        KrakenSquad.GetConfig("maxMembers"),
        function(v) pending.maxMembers = math.Clamp(math.floor(v), 2, KrakenSquad.MAX_LENGTHS.maxMembers) end,
        { desc = KrakenSquad.L("admin_max_members_desc") })

    FormSpacer(scroll, 8)
    FormHeader(scroll, KrakenSquad.L("admin_groups"), KrakenSquad.L("admin_groups_desc"))

    local current = KrakenSquad.GetConfig("adminGroups") or "superadmin,admin"
    local selected = {}
    for g in current:gmatch("[^,%s]+") do selected[g:lower()] = true end

    local groups = (KF.Integrations.GetUsergroups and KF.Integrations.GetUsergroups("names"))
        or { "superadmin", "admin", "operator", "moderator", "vip", "user" }
    for g in pairs(selected) do
        local found = false
        for _, kg in ipairs(groups) do if kg == g then found = true break end end
        if not found then table.insert(groups, 2, g) end
    end

    local rowH = KF.Scale(24)
    local grid = vgui.Create("DPanel", scroll)
    grid:Dock(TOP); grid:SetTall(math.ceil(#groups / 2) * rowH + KF.Scale(8))
    grid:DockMargin(0, 0, 0, KF.Scale(6))
    grid.Paint = function(_, w, h)
        KF.Draw.RoundedBox(0, 0, w, h, 4, KF.UI.ColorAlpha(P("Panel"), 60))
    end
    local groupCBs = {}
    grid.PerformLayout = function(_, w)
        local colW = math.floor((w - KF.Scale(8)) / 2)
        for i, name in ipairs(groups) do
            local cb = groupCBs[name]
            if IsValid(cb) then
                cb:SetPos(((i - 1) % 2) * colW + KF.Scale(4), math.floor((i - 1) / 2) * rowH + KF.Scale(4))
                cb:SetSize(colW, rowH - 2)
            end
        end
    end
    for _, name in ipairs(groups) do
        local cb = KrakenSquad.MakeAccessCheckbox(grid, KF.Scale(100), rowH - 2, name, selected[name] or false)
        groupCBs[name] = cb
        cb.DoClick = function(s)
            s._checked = not s._checked
            local sel = {}
            for n, c in pairs(groupCBs) do if c._checked then sel[#sel + 1] = n end end
            if #sel == 0 then sel = { "superadmin" } end
            table.sort(sel)
            pending.adminGroups = table.concat(sel, ",")
        end
    end

    SaveBtn(scroll, nil, function() SendConfig(pending) end)
end

local function BuildListEditor(scroll, configKey, fields, titleKey, desc)
    local items = table.Copy(KrakenSquad.GetConfig(configKey) or {})

    local function Reorder(idx, newIdx)
        newIdx = math.Clamp(newIdx, 1, #items)
        if newIdx == idx then return end
        local removed = table.remove(items, idx)
        table.insert(items, newIdx, removed)
    end

    local function RebuildList(rebuild)
        for _, c in ipairs(scroll:GetCanvas():GetChildren()) do c:Remove() end
        FormHeader(scroll, KrakenSquad.L(titleKey), desc)

        local badge = vgui.Create("DPanel", scroll)
        badge:Dock(TOP); badge:SetTall(KF.Scale(24))
        badge:DockMargin(0, 0, 0, KF.Scale(4))
        badge.Paint = function(_, _, h)
            draw.SimpleText(KrakenSquad.L("admin_items_configured", #items), F("tiny"),
                KF.Scale(4), h / 2, P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        for idx, item in ipairs(items) do
            local fieldH = 0
            for _, fl in ipairs(fields) do
                if fl.type == "text" or fl.type == "number" then fieldH = fieldH + KF.Scale(70)
                elseif fl.type == "color"  then fieldH = fieldH + KF.Scale(46)
                elseif fl.type == "toggle" then fieldH = fieldH + KF.Scale(44) end
            end

            local card = vgui.Create("DPanel", scroll)
            card:Dock(TOP); card:DockMargin(0, KF.Scale(4), 0, KF.Scale(4))
            card:SetTall(KF.Scale(36) + fieldH + KF.Scale(16))
            card.Paint = function(_, w, h)
                KF.Draw.RoundedBox(0, 0, w, h, 4, KF.UI.ColorAlpha(P("Panel"), 120))
                surface.SetDrawColor(P("Accent"))
                surface.DrawRect(0, 0, 3, h)
            end

            local head = vgui.Create("DPanel", card)
            head:Dock(TOP); head:SetTall(KF.Scale(34))
            head.Paint = function(_, w, h)
                KF.Draw.RoundedBox(0, 0, w, h, 0, P("PanelDark"))
                local idText = item[fields[1].key] or KrakenSquad.L("admin_item_fallback"):format(idx)
                draw.SimpleText(tostring(idText), FB("body"), KF.Scale(14), h / 2,
                    P("Accent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local del = vgui.Create("DButton", head)
            del:Dock(RIGHT); del:DockMargin(KF.Scale(4), KF.Scale(6), KF.Scale(8), KF.Scale(6))
            del:SetWide(KF.Scale(28)); del:SetText(""); del._hoverLerp = 0
            del.Paint = function(s, w, h)
                KF.Anim.UpdateHoverLerp(s)
                KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.LerpColor(s._hoverLerp, P("Error"), P("Danger")))
                draw.SimpleText("x", F("tiny"), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            del.DoClick = function()
                KF.Helpers.PlaySound(SOUNDS.click)
                table.remove(items, idx); rebuild()
            end

            local orderInput = vgui.Create("DTextEntry", head)
            orderInput:Dock(RIGHT); orderInput:DockMargin(0, KF.Scale(5), 0, KF.Scale(5))
            orderInput:SetWide(KF.Scale(34)); orderInput:SetNumeric(true)
            orderInput:SetText(tostring(idx)); orderInput:SetFont(F("small"))
            orderInput:SetTextColor(P("TextPrimary"))
            orderInput.Paint = function(s, w, h) KF.Helpers.TextEntryPaint(s, w, h, F("small"), AID) end
            local function SubmitOrder(s)
                Reorder(idx, tonumber(s:GetValue()) or idx)
                rebuild()
            end
            orderInput.OnEnter, orderInput.OnLoseFocus = SubmitOrder, SubmitOrder

            local body = vgui.Create("DPanel", card)
            body:Dock(FILL); body:DockMargin(KF.Scale(10), KF.Scale(4), KF.Scale(10), KF.Scale(8))
            body.Paint = function() end

            for _, fl in ipairs(fields) do
                if fl.type == "text" then
                    FormField(body, fl.label, item[fl.key] or "",
                        function(v) items[idx][fl.key] = v end, { desc = fl.desc })
                elseif fl.type == "number" then
                    FormNumber(body, fl.label, item[fl.key] or 0,
                        function(v) items[idx][fl.key] = v end, { desc = fl.desc })
                elseif fl.type == "color" then
                    local cv = item[fl.key] or { 255, 255, 255 }
                    local crow = vgui.Create("DPanel", body)
                    crow:Dock(TOP); crow:SetTall(KF.Scale(40))
                    crow:DockMargin(0, KF.Scale(2), 0, KF.Scale(4)); crow._hoverLerp = 0
                    crow.Paint = function(s, w, h)
                        KF.Anim.UpdateHoverLerp(s)
                        KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.LerpColor(s._hoverLerp, P("PanelDark"), P("PanelHover")))
                        draw.SimpleText(fl.label, F("body"), KF.Scale(12), h / 2,
                            P("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end
                    local prev = vgui.Create("DButton", crow)
                    prev:Dock(RIGHT); prev:DockMargin(KF.Scale(4), KF.Scale(6), KF.Scale(8), KF.Scale(6))
                    prev:SetWide(KF.Scale(60)); prev:SetText("")
                    prev._color = Color(cv[1] or 255, cv[2] or 255, cv[3] or 255)
                    prev.Paint = function(s, w, h)
                        KF.Draw.RoundedBox(0, 0, w, h, 4, s._color)
                        surface.SetDrawColor(P("Border")); surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end
                    prev.DoClick = function()
                        KF.Helpers.PlaySound(SOUNDS.click)
                        KrakenSquad.UI.OpenColorDialog(fl.label, prev._color, function(c)
                            items[idx][fl.key] = { c.r, c.g, c.b }
                            prev._color = KF.UI.ColorAlpha(c, 255)
                        end)
                    end
                elseif fl.type == "toggle" then
                    FormToggle(body, fl.label, item[fl.key],
                        function(v) items[idx][fl.key] = v end, fl.desc)
                end
            end
        end

        KrakenSquad.MakeKFButton(scroll, "+ " .. KrakenSquad.L("admin_add"), "solid", function()
            local newItem = {}
            for _, fl in ipairs(fields) do
                if fl.type == "text"   then newItem[fl.key] = ""
                elseif fl.type == "number" then newItem[fl.key] = 0
                elseif fl.type == "color"  then newItem[fl.key] = { 255, 255, 255 }
                elseif fl.type == "toggle" then newItem[fl.key] = false end
            end
            if fields[1] then newItem[fields[1].key] = "new_" .. (#items + 1) end
            table.insert(items, newItem)
            rebuild()
        end, 36, { 10, 4 })

        SaveBtn(scroll, nil, function() SendConfig({ [configKey] = items }) end)
    end

    local function rebuild() RebuildList(rebuild) end
    rebuild()
end

local function BuildPositions(scroll)
    local items = table.Copy(KrakenSquad.GetConfig("positions") or {})
    local comms = KrakenSquad.GetConfig("communications") or {}

    local function Rebuild()
        for _, c in ipairs(scroll:GetCanvas():GetChildren()) do c:Remove() end
        FormHeader(scroll, KrakenSquad.L("admin_positions"), SectionDesc("positions"))

        local badge = vgui.Create("DPanel", scroll)
        badge:Dock(TOP); badge:SetTall(KF.Scale(24))
        badge:DockMargin(0, 0, 0, KF.Scale(4))
        badge.Paint = function(_, _, h)
            draw.SimpleText(KrakenSquad.L("admin_roles_configured", #items), F("tiny"),
                KF.Scale(4), h / 2, P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        for idx, item in ipairs(items) do
            local hasMedic = item.isMedic or false
            local baseH = KF.Scale(36) + 2 * KF.Scale(70) + 3 * KF.Scale(44) + KF.Scale(42) + KF.Scale(16)
            if hasMedic then baseH = baseH + KF.Scale(34) + #comms * KF.Scale(31) end

            local roleCol = KF.UI.ColorAlpha(KrakenSquad.GetPositionColor(item), 255)

            local card = vgui.Create("DPanel", scroll)
            card:Dock(TOP); card:DockMargin(0, KF.Scale(4), 0, KF.Scale(4)); card:SetTall(baseH)
            card.Paint = function(_, w, h)
                KF.Draw.RoundedBox(0, 0, w, h, 4, KF.UI.ColorAlpha(P("Panel"), 120))
                surface.SetDrawColor(roleCol); surface.DrawRect(0, 0, 3, h)
            end

            local head = vgui.Create("DPanel", card)
            head:Dock(TOP); head:SetTall(KF.Scale(34))
            head.Paint = function(_, w, h)
                KF.Draw.RoundedBox(0, 0, w, h, 0, P("PanelDark"))
                draw.SimpleText(item.name or KrakenSquad.L("admin_role_fallback"):format(idx),
                    FB("body"), KF.Scale(14), h / 2, roleCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local del = vgui.Create("DButton", head)
            del:Dock(RIGHT); del:DockMargin(KF.Scale(4), KF.Scale(6), KF.Scale(8), KF.Scale(6))
            del:SetWide(KF.Scale(28)); del:SetText(""); del._hoverLerp = 0
            del.Paint = function(s, w, h)
                KF.Anim.UpdateHoverLerp(s)
                KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.LerpColor(s._hoverLerp, P("Error"), P("Danger")))
                draw.SimpleText("x", F("tiny"), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            del.DoClick = function() KF.Helpers.PlaySound(SOUNDS.click); table.remove(items, idx); Rebuild() end

            local body = vgui.Create("DPanel", card)
            body:Dock(FILL); body:DockMargin(KF.Scale(10), KF.Scale(4), KF.Scale(10), KF.Scale(8))
            body.Paint = function() end

            FormField(body, KrakenSquad.L("admin_name"),      item.name or "",
                function(v) items[idx].name = v end, { desc = KrakenSquad.L("admin_name_desc") })
            FormField(body, KrakenSquad.L("admin_icon_path"), item.icon or "",
                function(v) items[idx].icon = v end, { desc = KrakenSquad.L("admin_icon_path_desc") })

            local colorRow = vgui.Create("DPanel", body)
            colorRow:Dock(TOP); colorRow:SetTall(KF.Scale(36))
            colorRow:DockMargin(0, KF.Scale(2), 0, KF.Scale(4))
            colorRow.Paint = function(_, w, h)
                KF.Draw.RoundedBox(0, 0, w, h, 2, P("PanelDark"))
                draw.SimpleText(KrakenSquad.L("admin_role_color"), F("small"), KF.Scale(12), h / 2,
                    P("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            local colorBtn = vgui.Create("DButton", colorRow)
            colorBtn:Dock(RIGHT); colorBtn:DockMargin(0, KF.Scale(4), KF.Scale(12), KF.Scale(4))
            colorBtn:SetWide(KF.Scale(80)); colorBtn:SetText("")
            colorBtn.Paint = function(_, w, h)
                KF.Draw.RoundedBox(0, 0, w, h, 4, roleCol)
                surface.SetDrawColor(P("Border"))
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            colorBtn.DoClick = function()
                KF.Helpers.PlaySound(SOUNDS.click)
                KrakenSquad.UI.OpenColorDialog(KrakenSquad.L("admin_role_color"), roleCol, function(c)
                    roleCol = KF.UI.ColorAlpha(c, 255)
                    items[idx].color = { c.r, c.g, c.b }
                end)
            end

            FormToggle(body, KrakenSquad.L("admin_is_medic"), hasMedic, function(v)
                items[idx].isMedic = v
                if not v then items[idx].medicComms = nil end
                Rebuild()
            end, KrakenSquad.L("admin_medic_desc"))

            FormToggle(body, KrakenSquad.L("admin_is_marksman"), item.isMarksman or false,
                function(v) items[idx].isMarksman = v end, KrakenSquad.L("admin_marksman_desc"))

            FormToggle(body, KrakenSquad.L("admin_is_officer"), item.isOfficer or false,
                function(v) items[idx].isOfficer = v end, KrakenSquad.L("admin_officer_desc"))

            if hasMedic then
                local lbl = vgui.Create("DPanel", body)
                lbl:Dock(TOP); lbl:SetTall(KF.Scale(26))
                lbl:DockMargin(0, KF.Scale(6), 0, KF.Scale(2))
                lbl.Paint = function(_, w, h)
                    surface.SetDrawColor(P("Accent"))
                    surface.DrawRect(0, h - 1, w, 1)
                    draw.SimpleText(KrakenSquad.L("admin_medic_triggers"), F("small"),
                        KF.Scale(4), h / 2 - 2, P("Accent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                local set = {}
                for _, cid in ipairs(item.medicComms or {}) do set[cid] = true end
                for _, comm in ipairs(comms) do
                    local cb = KrakenSquad.MakeAccessCheckbox(body, 0, 0, comm.id, set[comm.id] or false)
                    cb:Dock(TOP); cb:SetTall(KF.Scale(30)); cb:DockMargin(0, 1, 0, 0)
                    cb.DoClick = function(s)
                        KF.Helpers.PlaySound(SOUNDS.click)
                        s._checked = not s._checked
                        if s._checked then set[comm.id] = true else set[comm.id] = nil end
                        local out = {}
                        for cid in pairs(set) do out[#out + 1] = cid end
                        items[idx].medicComms = out
                    end
                end
            end
        end

        KrakenSquad.MakeKFButton(scroll, "+ " .. KrakenSquad.L("admin_add"), "solid", function()
            table.insert(items, { name = KrakenSquad.L("admin_new_role"), icon = "" })
            Rebuild()
        end, 36, { 10, 4 })

        SaveBtn(scroll, nil, function() SendConfig({ positions = items }) end)
    end
    Rebuild()
end

local function BuildCommunications(scroll)
    BuildListEditor(scroll, "communications", {
        { key = "id",       label = KrakenSquad.L("admin_identifier"),       type = "text",   desc = KrakenSquad.L("admin_identifier_desc") },
        { key = "chatMsg",  label = KrakenSquad.L("admin_chat_broadcast"),   type = "text",   desc = KrakenSquad.L("admin_chat_broadcast_desc") },
        { key = "icon",     label = KrakenSquad.L("admin_icon_material"),    type = "text",   desc = KrakenSquad.L("admin_icon_material_desc") },
        { key = "color",    label = KrakenSquad.L("admin_tint"),             type = "color",  desc = KrakenSquad.L("admin_tint_desc") },
        { key = "duration", label = KrakenSquad.L("admin_display_time"),     type = "number", desc = KrakenSquad.L("admin_display_time_desc") },
    }, "admin_communications", SectionDesc("communications"))
end

local function BuildCommands(scroll)
    BuildListEditor(scroll, "commands", {
        { key = "id",      label = KrakenSquad.L("admin_identifier"),         type = "text",  desc = KrakenSquad.L("admin_identifier_desc") },
        { key = "chatMsg", label = KrakenSquad.L("admin_broadcast_message"),  type = "text",  desc = KrakenSquad.L("admin_broadcast_message_desc") },
        { key = "icon",    label = KrakenSquad.L("admin_icon_material"),      type = "text",  desc = KrakenSquad.L("admin_icon_material_desc") },
        { key = "color",   label = KrakenSquad.L("admin_tint"),               type = "color", desc = KrakenSquad.L("admin_tint_desc") },
    }, "admin_commands", SectionDesc("commands"))
end

local function BuildXP(scroll)
    local cfg = table.Copy(KrakenSquad.GetConfig("xpRewards") or {})
    FormHeader(scroll, KrakenSquad.L("admin_xp"), SectionDesc("xp"))
    FormToggle(scroll, KrakenSquad.L("admin_enabled"),   cfg.enabled,   function(v) cfg.enabled = v end, KrakenSquad.L("admin_enable_xp"))
    FormNumber(scroll, KrakenSquad.L("admin_frequency"), cfg.frequency, function(v) cfg.frequency = math.max(1, v) end, { desc = KrakenSquad.L("admin_xp_interval") })
    FormNumber(scroll, KrakenSquad.L("admin_amount"),    cfg.amount,    function(v) cfg.amount    = math.max(1, v) end, { desc = KrakenSquad.L("admin_xp_amount") })
    FormToggle(scroll, KrakenSquad.L("admin_notify"),    cfg.notify,    function(v) cfg.notify = v end, KrakenSquad.L("admin_xp_notify"))
    SaveBtn(scroll, nil, function() SendConfig({ xpRewards = cfg }) end)
end

local function BuildMoney(scroll)
    local cfg = table.Copy(KrakenSquad.GetConfig("sharedMoney") or {})
    FormHeader(scroll, KrakenSquad.L("admin_money"), SectionDesc("money"))
    FormToggle(scroll, KrakenSquad.L("admin_enabled"),    cfg.enabled,    function(v) cfg.enabled = v end, KrakenSquad.L("admin_enable_money"))
    FormNumber(scroll, KrakenSquad.L("admin_percentage"), cfg.percentage, function(v) cfg.percentage = math.Clamp(v, 1, 100) end, { desc = KrakenSquad.L("admin_money_pct") })
    SaveBtn(scroll, nil, function() SendConfig({ sharedMoney = cfg }) end)
end

local COLOR_DEFAULTS = {
    accent = { 255, 190,  50 },
    ally   = {  80, 160, 255 },
    enemy  = { 230,  85,  85 },
    health = { 255, 255, 255 },
}

local function ColorRow(parent, label, key, cfg)
    local current = cfg[key] or COLOR_DEFAULTS[key] or { 255, 255, 255 }
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP); row:SetTall(KF.Scale(40))
    row:DockMargin(0, KF.Scale(2), 0, KF.Scale(2)); row._hoverLerp = 0
    row.Paint = function(s, w, h)
        KF.Anim.UpdateHoverLerp(s)
        KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.LerpColor(s._hoverLerp, P("PanelDark"), P("PanelHover")))
        draw.SimpleText(label, F("body"), KF.Scale(12), h / 2,
            P("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local prev = vgui.Create("DButton", row)
    prev:Dock(RIGHT); prev:DockMargin(KF.Scale(4), KF.Scale(6), KF.Scale(8), KF.Scale(6))
    prev:SetWide(KF.Scale(60)); prev:SetText("")
    prev._color = Color(current[1] or 255, current[2] or 255, current[3] or 255)
    prev.Paint = function(s, w, h)
        KF.Draw.RoundedBox(0, 0, w, h, 4, s._color)
        surface.SetDrawColor(P("Border")); surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    prev.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        KrakenSquad.UI.OpenColorDialog(label, prev._color, function(c)
            cfg[key] = { c.r, c.g, c.b }
            prev._color = KF.UI.ColorAlpha(c, 255)
        end)
    end

    if COLOR_DEFAULTS[key] then
        local rb = vgui.Create("DButton", row)
        rb:Dock(RIGHT); rb:DockMargin(0, KF.Scale(8), KF.Scale(4), KF.Scale(8))
        rb:SetWide(KF.Scale(60)); rb:SetText(""); rb._hoverLerp = 0
        rb.Paint = function(s, w, h)
            KF.Anim.UpdateHoverLerp(s)
            local c = KF.UI.LerpColor(s._hoverLerp, P("TextMuted"), P("Accent"))
            KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.ColorAlpha(c, 30))
            draw.SimpleText(KrakenSquad.L("ctx_reset"), F("tiny"), w / 2, h / 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        rb.DoClick = function()
            KF.Helpers.PlaySound(SOUNDS.click)
            local def = COLOR_DEFAULTS[key]
            cfg[key] = table.Copy(def)
            prev._color = Color(def[1], def[2], def[3])
        end
    end
end

local function BuildColors(scroll)
    local cfg = table.Copy(KrakenSquad.GetConfig("colors") or {})
    FormHeader(scroll, KrakenSquad.L("admin_colors"), SectionDesc("colors"))
    ColorRow(scroll, KrakenSquad.L("admin_accent"),       "accent", cfg)
    ColorRow(scroll, KrakenSquad.L("admin_ally"),         "ally",   cfg)
    ColorRow(scroll, KrakenSquad.L("admin_enemy"),        "enemy",  cfg)
    ColorRow(scroll, KrakenSquad.L("admin_health_color"), "health", cfg)
    SaveBtn(scroll, nil, function() SendConfig({ colors = cfg }) end)
end

local function BuildSounds(scroll)
    local cfg = table.Copy(KrakenSquad.GetConfig("sounds") or {})
    FormHeader(scroll, KrakenSquad.L("admin_sounds"), SectionDesc("sounds"))
    for k, v in SortedPairs(cfg) do
        FormField(scroll, k, v, function(nv) cfg[k] = nv end, { desc = KrakenSquad.L("admin_sound_desc") })
    end
    SaveBtn(scroll, nil, function() SendConfig({ sounds = cfg }) end)
end

local function BuildNPCs(scroll)
    local models = table.Copy(KrakenSquad.GetConfig("npcModels")    or {})
    local texts  = table.Copy(KrakenSquad.GetConfig("npcTexts")     or {})
    local anims  = table.Copy(KrakenSquad.GetConfig("npcAnimations") or {})
    local term   = table.Copy(KrakenSquad.GetConfig("npcTerminal")  or {})

    for _, s in ipairs({
        { hdr = "admin_npc_creator", desc = "admin_npc_creator_desc", model = "creator",    title = "creatorTitle", anim = "creator" },
        { hdr = "admin_npc_list",    desc = "admin_npc_list_desc",    model = "publicList", title = "listTitle",    anim = "publicList" },
    }) do
        FormHeader(scroll, KrakenSquad.L(s.hdr), KrakenSquad.L(s.desc))
        FormField(scroll, KrakenSquad.L("admin_model"), models[s.model],
            function(v) models[s.model] = v end, { desc = KrakenSquad.L("admin_model_path") })
        FormField(scroll, KrakenSquad.L("admin_animation"), anims[s.anim] or "",
            function(v) anims[s.anim] = v end, { desc = KrakenSquad.L("admin_idle_seq") })
        FormField(scroll, KrakenSquad.L("admin_overhead_title"), texts[s.title] or "",
            function(v) texts[s.title] = v end, { desc = KrakenSquad.L("admin_overhead_text") })
    end

    FormHeader(scroll, KrakenSquad.L("admin_npc_terminal"), KrakenSquad.L("admin_npc_terminal_desc"))
    FormField(scroll, KrakenSquad.L("admin_model"),          term.model or "models/props_lab/monitor02.mdl",
        function(v) term.model = v end, { desc = KrakenSquad.L("admin_model_path") })
    FormField(scroll, KrakenSquad.L("admin_overhead_title"), term.title or KrakenSquad.L("orders_terminal"),
        function(v) term.title = v end, { desc = KrakenSquad.L("admin_overhead_text") })
    FormField(scroll, KrakenSquad.L("admin_animation"),      term.animation or "",
        function(v) term.animation = v end, { desc = KrakenSquad.L("admin_idle_seq") })

    SaveBtn(scroll, nil, function()
        SendConfig({ npcModels = models, npcTexts = texts, npcAnimations = anims, npcTerminal = term })
    end)

    FormHeader(scroll, KrakenSquad.L("admin_npc_management"))
    DeleteBtn(scroll, KrakenSquad.L("admin_remove_all_npcs"), function()
        KF.Menu.Query(
            KrakenSquad.L("admin_remove_all_confirm"),
            KrakenSquad.L("admin_remove_all_npcs"),
            {
                { text = KrakenSquad.L("admin_delete"), callback = function()
                    net.Start("KS.RemoveAllNPCs") net.SendToServer()
                    KF.Helpers.PlaySound(SOUNDS.success)
                end },
                { text = KrakenSquad.L("layout_cancel") },
            })
    end)
end

local function BuildBinds(scroll)
    local pending = {}
    FormHeader(scroll, KrakenSquad.L("admin_binds"), SectionDesc("binds"))
    AdminKeyBinder(scroll, KrakenSquad.L("admin_radial_key"),
        KrakenSquad.GetConfig("keybind") or KEY_G, "keybind", pending)

    FormSpacer(scroll, 8)
    FormHeader(scroll, KrakenSquad.L("admin_chat_commands"), KrakenSquad.L("admin_chat_commands_desc"))

    local cmds = table.Copy(KrakenSquad.GetConfig("chatCommands") or {})
    for _, cf in ipairs({
        { key = "create", label = "admin_create_cmd", default = "!createsquad" },
        { key = "invite", label = "admin_invite_cmd", default = "!invitesquad" },
        { key = "kick",   label = "admin_kick_cmd",   default = "!kicksquad"   },
        { key = "squads", label = "admin_squads_cmd", default = "!squads"       },
        { key = "admin",  label = "admin_admin_cmd",  default = "!squadsadmin"  },
    }) do
        FormField(scroll, KrakenSquad.L(cf.label), cmds[cf.key] or cf.default, function(v)
            local val = v:Trim()
            if val ~= "" then cmds[cf.key] = val end
        end, { desc = KrakenSquad.L(cf.label .. "_desc") })
    end

    SaveBtn(scroll, nil, function()
        if pending.keybind then SendConfig({ keybind = pending.keybind }) end
        SendConfig({ chatCommands = cmds })
    end)
end

local function BuildLanguage(scroll)
    local langs = {}
    for k in pairs(KrakenSquad.LangData) do langs[#langs + 1] = k end
    table.sort(langs)
    FormHeader(scroll, KrakenSquad.L("admin_language"), SectionDesc("language"))
    local choices = {}
    for _, lang in ipairs(langs) do
        choices[#choices + 1] = {
            name  = (KrakenSquad.LANG_NAMES[lang] or lang:upper()) .. " (" .. lang:upper() .. ")",
            value = lang,
        }
    end
    FormDropdown(scroll, KrakenSquad.L("admin_language"), KrakenSquad.LangCurrent, choices, function(val)
        KrakenSquad.LangCurrent = val
        SendConfig({ language = val })
    end, KrakenSquad.L("admin_language_desc"))
end

local function BuildPresetEditor(scroll)
    local source = editingPreset or {}
    local editIdx = editingPresetIdx
    local isEditing = editIdx ~= nil

    KrakenSquad.MakeKFButton(scroll, "\xe2\x86\x90 " .. KrakenSquad.L("admin_presets"), nil, function()
        editingPreset, editingPresetIdx = nil, nil
        activeSection = "presets"
        Rebuild()
    end, 28, { 0, 6 })

    FormHeader(scroll, isEditing and KrakenSquad.L("order_edit") or KrakenSquad.L("admin_create_preset"),
        isEditing and (source.name or "") or nil)

    local newPreset = {
        name = source.name or "", public = source.public or false,
        autoAssign = source.autoAssign or false, lockMembers = source.lockMembers or false,
        filters = table.Copy(source.filters or {}),
        roleAssignments = table.Copy(source.roleAssignments or {}),
        leaderFilter = source.leaderFilter and table.Copy(source.leaderFilter) or nil,
        commsChannels = table.Copy(source.commsChannels or {}),
    }

    FormField(scroll, KrakenSquad.L("admin_preset_name"), newPreset.name,
        function(v) newPreset.name = v end, { desc = KrakenSquad.L("admin_preset_name_desc") })
    FormToggle(scroll, KrakenSquad.L("public_squad"),       newPreset.public,
        function(v) newPreset.public = v end, KrakenSquad.L("admin_public_squad_desc"))
    FormToggle(scroll, KrakenSquad.L("admin_auto_assign"),  newPreset.autoAssign,
        function(v) newPreset.autoAssign = v end, KrakenSquad.L("admin_auto_assign_desc"))
    FormToggle(scroll, KrakenSquad.L("admin_lock_members"), newPreset.lockMembers,
        function(v) newPreset.lockMembers = v end, KrakenSquad.L("admin_lock_members_desc"))

    FormSpacer(scroll, 8)
    FormHeader(scroll, KrakenSquad.L("admin_role_assignments"), KrakenSquad.L("admin_role_assignments_desc"))

    local positions  = KrakenSquad.GetPositions()
    local jobs       = KF.Integrations.GetJobs()
    local factions   = KF.Integrations.GetFactions()
    local categories = KF.Integrations.GetCategories()

    local raChecked = {}
    for _, ra in ipairs(newPreset.roleAssignments) do
        if ra.position and ra.filter and ra.filter.type and ra.filter.value ~= nil then
            raChecked[ra.position .. ":" .. tostring(ra.filter.type) .. ":" .. tostring(ra.filter.value)] = true
        end
    end

    local raStore = {}
    for posIdx, posData in ipairs(positions) do
        local all = {}
        for _, set in ipairs({ { "job", jobs }, { "faction", factions }, { "category", categories } }) do
            local ftype, list = set[1], set[2]
            for _, e in ipairs(list) do
                all[#all + 1] = {
                    id = posIdx .. ":" .. ftype .. ":" .. tostring(e.id),
                    name = tostring(e.name),
                }
            end
        end
        local selected = {}
        for _, item in ipairs(all) do
            if raChecked[item.id] then selected[#selected + 1] = item.id end
        end
        KrakenSquad.MakeCollapsibleSection(scroll, "ra_" .. posIdx,
            "#" .. posIdx .. " " .. (posData.name or ""), all, selected, raStore)
    end

    if KComms and KComms.Channels then
        FormSpacer(scroll, 8)
        FormHeader(scroll, KrakenSquad.L("admin_comms_channels"), KrakenSquad.L("admin_comms_channels_desc"))
        local channels = {}
        for id, ch in pairs(KComms.Channels) do channels[#channels + 1] = { id = id, name = ch.name or id } end
        table.sort(channels, function(a, b) return a.name < b.name end)
        local slots = {
            { key = "active",   label = "admin_comms_active"   },
            { key = "passive1", label = "admin_comms_passive1" },
            { key = "passive2", label = "admin_comms_passive2" },
        }

        for posIdx, posData in ipairs(positions) do
            local posCh = newPreset.commsChannels[posIdx] or {}
            newPreset.commsChannels[posIdx] = posCh

            local hdr = vgui.Create("DButton", scroll)
            hdr:Dock(TOP); hdr:SetTall(KF.Scale(30))
            hdr:DockMargin(0, KF.Scale(2), 0, 0); hdr:SetText("")
            hdr._expanded = false; hdr._hoverLerp = 0
            hdr.Paint = function(s, w, h)
                KF.Anim.UpdateHoverLerp(s)
                KF.Draw.RoundedBox(0, 0, w, h, 4, KF.UI.LerpColor(s._hoverLerp, P("PanelDark"), P("PanelHover")))
                local accent = P("Accent")
                surface.SetDrawColor(accent); surface.DrawRect(0, 0, 3, h)
                draw.SimpleText("#" .. posIdx .. "  " .. (posData.name or ""), F("body"),
                    KF.Scale(12), h / 2, accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(s._expanded and "-" or "+", F("body"),
                    w - KF.Scale(16), h / 2,
                    KF.UI.LerpColor(s._hoverLerp, P("TextMuted"), accent),
                    TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            local grid = vgui.Create("DPanel", scroll)
            grid:Dock(TOP); grid:SetTall(0)
            grid:DockMargin(KF.Scale(8), 0, 0, 0); grid:SetVisible(false)
            grid.Paint = function() end

            local rowH = KF.Scale(36)

            for _, slot in ipairs(slots) do
                local row = vgui.Create("DPanel", grid)
                row:Dock(TOP); row:SetTall(rowH); row:DockMargin(0, KF.Scale(2), 0, 0)
                row.Paint = function(_, w, h)
                    KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.ColorAlpha(P("Panel"), 60))
                end
                local lbl = vgui.Create("DLabel", row)
                lbl:Dock(LEFT); lbl:SetWide(KF.Scale(120))
                lbl:DockMargin(KF.Scale(12), 0, 0, 0)
                lbl:SetText(KrakenSquad.L(slot.label))
                lbl:SetFont(F("body")); lbl:SetTextColor(P("TextPrimary"))

                local combo = vgui.Create("KF.PopupDropdown", row)
                combo:Dock(FILL); combo:DockMargin(KF.Scale(8), KF.Scale(4), KF.Scale(12), KF.Scale(4))
                combo:SetAddon(AID); combo:SetFont(F("small"))
                combo:SetSound(SOUNDS.click); combo:SetHoverSound(SOUNDS.hover)
                combo:AddOption("", KrakenSquad.L("admin_comms_none"))
                for _, ch in ipairs(channels) do combo:AddOption(ch.id, ch.name) end
                combo:SetValue(posCh[slot.key] and posCh[slot.key] ~= "" and posCh[slot.key] or "")
                combo.OnSelect = function(_, _, _, val)
                    posCh[slot.key] = val ~= "" and val or nil
                    newPreset.commsChannels[posIdx] = posCh
                end
            end

            hdr.DoClick = function()
                KF.Helpers.PlaySound(SOUNDS.click)
                hdr._expanded = not hdr._expanded
                grid:SetVisible(hdr._expanded)
                grid:SetTall(hdr._expanded and (#slots * rowH + KF.Scale(8)) or 0)
                scroll:InvalidateLayout(true)
            end
        end
    end

    FormSpacer(scroll, 8)
    FormHeader(scroll, KrakenSquad.L("admin_whitelist"), KrakenSquad.L("admin_filter_desc"))

    local filterStore = {}
    local function BuildFilter(ftype, list)
        local items = {}
        for _, e in ipairs(list) do items[#items + 1] = { id = tostring(e.id), name = tostring(e.name) } end
        local selected = {}
        for _, f in ipairs(newPreset.filters) do
            if f.type == ftype then selected[#selected + 1] = tostring(f.value) end
        end
        KrakenSquad.MakeCollapsibleSection(scroll, ftype, ftype, items, selected, filterStore)
    end
    BuildFilter("job",      jobs)
    BuildFilter("faction",  factions)
    BuildFilter("category", categories)

    local function CollectRA()
        local ra = {}
        for key, items in pairs(raStore) do
            if key:StartWith("ra_") then
                for itemId, cb in pairs(items) do
                    if IsValid(cb) and cb._checked then
                        local posIdx, fType, fVal = itemId:match("^(%d+):(.+):(.+)$")
                        posIdx = tonumber(posIdx)
                        if posIdx and fType and fVal then
                            ra[#ra + 1] = {
                                position = posIdx,
                                filter   = { type = fType, value = tonumber(fVal) or fVal },
                            }
                        end
                    end
                end
            end
        end
        return ra
    end

    SaveBtn(scroll, isEditing and KrakenSquad.L("admin_save") or KrakenSquad.L("admin_create_preset"), function()
        if #newPreset.name < 3 then return end
        newPreset.filters         = KrakenSquad.CollectFilters(filterStore)
        newPreset.roleAssignments = CollectRA()
        if isEditing then
            KF.Net.SendJSON("KS.AdminPresetUpdate", { index = editIdx, preset = newPreset })
        else
            KF.Net.SendJSON("KS.AdminPresetCreate", newPreset)
        end
        editingPreset, editingPresetIdx = nil, nil
        activeSection = "presets"
        Rebuild()
    end)

    if isEditing then
        DeleteBtn(scroll, nil, function()
            net.Start("KS.AdminPresetDelete") net.WriteUInt(editIdx, 16) net.SendToServer()
            editingPreset, editingPresetIdx = nil, nil
            activeSection = "presets"
            Rebuild()
        end)
    end
end

local function BuildPresets(scroll)
    FormHeader(scroll, KrakenSquad.L("admin_presets"), SectionDesc("presets"))
    for idx, preset in ipairs(KrakenSquad.GetConfig("presetSquads") or {}) do
        local p = KrakenSquad.UI.MakeListCard(scroll, {
            paint = function(_, _, h)
                draw.SimpleText(preset.name or KrakenSquad.L("unknown_player"), FB("body"),
                    KF.Scale(16), h / 2 - KF.Scale(8), P("Accent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                local filterText = KrakenSquad.L("admin_no_filters")
                if preset.filters and #preset.filters > 0 then
                    local parts = {}
                    for _, f in ipairs(preset.filters) do
                        parts[#parts + 1] = f.type .. ":" .. tostring(f.value)
                    end
                    filterText = table.concat(parts, ", ")
                end
                local meta = {}
                if preset.public      then meta[#meta + 1] = KrakenSquad.L("admin_public") end
                if preset.autoAssign  then meta[#meta + 1] = KrakenSquad.L("admin_auto_assign") end
                if preset.lockMembers then meta[#meta + 1] = KrakenSquad.L("admin_locked") end
                meta[#meta + 1] = filterText
                draw.SimpleText(table.concat(meta, " \xc2\xb7 "), F("tiny"),
                    KF.Scale(16), h / 2 + KF.Scale(10), P("TextMuted"),
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end,
        })

        local del = vgui.Create("KF.Button", p)
        del:Dock(RIGHT); del:DockMargin(0, KF.Scale(12), KF.Scale(16), KF.Scale(12))
        del:SetWide(KF.Scale(70)); del:SetAddon(AID)
        del:SetLabel(KrakenSquad.L("admin_delete")); del:SetStyle("danger")
        del.DoClick = function()
            KF.Helpers.PlaySound(SOUNDS.click)
            net.Start("KS.AdminPresetDelete") net.WriteUInt(idx, 16) net.SendToServer()
            activeSection = "presets"
            Rebuild()
        end

        local edit = vgui.Create("KF.Button", p)
        edit:Dock(RIGHT); edit:DockMargin(0, KF.Scale(12), KF.Scale(8), KF.Scale(12))
        edit:SetWide(KF.Scale(70)); edit:SetAddon(AID)
        edit:SetLabel(KrakenSquad.L("order_edit")); edit:SetSolid(true)
        edit.DoClick = function()
            KF.Helpers.PlaySound(SOUNDS.click)
            editingPreset, editingPresetIdx = preset, idx
            activeSection = "preset_edit"
            Rebuild()
        end
    end

    KrakenSquad.MakeKFButton(scroll, KrakenSquad.L("admin_create_preset"), "solid", function()
        KF.Helpers.PlaySound(SOUNDS.click)
        editingPreset, editingPresetIdx = nil, nil
        activeSection = "preset_edit"
        Rebuild()
    end, 38, { 12, 4 })
end

local function MakeOrderCard(scroll, id, order, source)
    local p = KrakenSquad.UI.MakeListCard(scroll, {
        tall = 72, gap = 4,
        statusColor = function()
            return order.status == "succeeded" and P("Success")
                or order.status == "failed"    and P("Error")
                or P("Accent")
        end,
        paint = function(_, w, h)
            local statusCol = order.status == "succeeded" and P("Success")
                          or order.status == "failed"    and P("Error")
                          or P("Accent")
            local rightPad = KF.Scale(280)
            local title = (order.title or KrakenSquad.L("order_fallback_title")):upper()
            draw.SimpleText(KF.TruncateText(title, F("body"), w - rightPad - KF.Scale(24)), FB("body"),
                KF.Scale(16), h / 2 - KF.Scale(12), statusCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if order.permanent then
                draw.SimpleText("\xe2\x88\x9e", F("tiny"), w - rightPad, h / 2 - KF.Scale(12),
                    P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                local rem = (order.expire or 0) - CurTime()
                local timeStr = ("%d:%02d"):format(math.floor(rem / 60), math.floor(rem % 60))
                surface.SetFont(F("tiny"))
                local timeX = w - rightPad - surface.GetTextSize(timeStr)
                draw.SimpleText(timeStr, F("tiny"), timeX, h / 2 - KF.Scale(12),
                    rem < 60 and P("Error") or P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            local meta = {}
            if order.status and order.status ~= "active" then meta[#meta + 1] = order.status:upper() end
            if order.issuer then meta[#meta + 1] = order.issuer end
            if order.targetSquadName and order.targetSquadName ~= "" then
                meta[#meta + 1] = KrakenSquad.L("squad_name") .. ":" .. order.targetSquadName
            end
            local filterText = KrakenSquad.L("admin_no_filters")
            if order.filters and #order.filters > 0 then
                local parts = {}
                for _, f in ipairs(order.filters) do parts[#parts + 1] = f.type .. ":" .. tostring(f.value) end
                filterText = table.concat(parts, ", ")
            end
            meta[#meta + 1] = filterText
            draw.SimpleText(KF.TruncateText(table.concat(meta, " \xc2\xb7 "), F("tiny"), w - rightPad - KF.Scale(16)),
                F("tiny"), KF.Scale(16), h / 2 + KF.Scale(8),
                P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end,
    })

    local del = vgui.Create("KF.Button", p)
    del:Dock(RIGHT); del:DockMargin(0, KF.Scale(16), KF.Scale(4), KF.Scale(16))
    del:SetWide(KF.Scale(56)); del:SetAddon(AID)
    del:SetLabel(KrakenSquad.L("admin_delete")); del:SetStyle("danger")
    del.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        net.Start("KS.OrderDelete") net.WriteUInt(id, 32) net.SendToServer()
        activeSection = source
        timer.Simple(0.5, Rebuild)
    end

    for _, sb in ipairs({
        { label = KrakenSquad.L("order_status_succeed"), status = "succeeded", style = "success" },
        { label = KrakenSquad.L("order_status_failed"),  status = "failed",    style = "danger"  },
    }) do
        local btn = vgui.Create("KF.Button", p)
        btn:Dock(RIGHT); btn:DockMargin(0, KF.Scale(16), KF.Scale(4), KF.Scale(16))
        surface.SetFont(F("button"))
        btn:SetWide(surface.GetTextSize(sb.label) + KF.Scale(20))
        btn:SetAddon(AID); btn:SetLabel(sb.label); btn:SetStyle(sb.style)
        btn.DoClick = function()
            KF.Helpers.PlaySound(SOUNDS.click)
            KrakenSquad.SendOrderStatus(id, sb.status)
            activeSection = source
            timer.Simple(0.5, Rebuild)
        end
    end

    local edit = vgui.Create("KF.Button", p)
    edit:Dock(RIGHT); edit:DockMargin(0, KF.Scale(16), KF.Scale(4), KF.Scale(16))
    edit:SetWide(KF.Scale(56)); edit:SetAddon(AID)
    edit:SetLabel(KrakenSquad.L("order_edit")); edit:SetSolid(true)
    edit.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        editingOrder, editingOrderIdx, editingOrderSource = table.Copy(order), nil, source
        activeSection = "order_edit"
        Rebuild()
    end
end

local function BuildOrders(scroll)
    FormHeader(scroll, KrakenSquad.L("admin_orders"), SectionDesc("orders"))
    FormHeader(scroll, KrakenSquad.L("admin_order_presets"))

    for pidx, op in ipairs(KrakenSquad.GetConfig("orderPresets") or {}) do
        local p = KrakenSquad.UI.MakeListCard(scroll, {
            paint = function(_, _, h)
                draw.SimpleText(op.name or KrakenSquad.L("unknown_player"), FB("body"),
                    KF.Scale(16), h / 2 - KF.Scale(6), P("Accent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                local meta = {}
                if op.permanent  then meta[#meta + 1] = KrakenSquad.L("order_permanent") end
                if op.duration   then meta[#meta + 1] = op.duration .. "s" end
                if op.objectives then meta[#meta + 1] = #op.objectives .. " obj" end
                draw.SimpleText(table.concat(meta, " \xc2\xb7 "), F("tiny"),
                    KF.Scale(16), h / 2 + KF.Scale(10), P("TextMuted"),
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end,
        })

        local del = vgui.Create("KF.Button", p)
        del:Dock(RIGHT); del:DockMargin(0, KF.Scale(10), KF.Scale(8), KF.Scale(10))
        del:SetWide(KF.Scale(56)); del:SetAddon(AID)
        del:SetLabel("x"); del:SetStyle("danger")
        del.DoClick = function()
            KF.Helpers.PlaySound(SOUNDS.click)
            net.Start("KS.OrderPresetDelete") net.WriteUInt(pidx, 16) net.SendToServer()
            activeSection = "orders"
            timer.Simple(0.5, Rebuild)
        end

        local edit = vgui.Create("KF.Button", p)
        edit:Dock(RIGHT); edit:DockMargin(0, KF.Scale(10), KF.Scale(4), KF.Scale(10))
        edit:SetWide(KF.Scale(56)); edit:SetAddon(AID)
        edit:SetLabel(KrakenSquad.L("order_edit")); edit:SetSolid(true)
        edit.DoClick = function()
            KF.Helpers.PlaySound(SOUNDS.click)
            editingOrder, editingOrderIdx, editingOrderSource = table.Copy(op), pidx, "orders"
            activeSection = "order_edit"
            Rebuild()
        end

        local use = vgui.Create("KF.Button", p)
        use:Dock(RIGHT); use:DockMargin(0, KF.Scale(10), KF.Scale(4), KF.Scale(10))
        use:SetWide(KF.Scale(70)); use:SetAddon(AID)
        use:SetLabel(KrakenSquad.L("admin_deploy")); use:SetStyle("success")
        use.DoClick = function()
            KF.Helpers.PlaySound(SOUNDS.success)
            KrakenSquad.SendCreateOrder(op, false)
            activeSection = "orders"
            timer.Simple(0.5, Rebuild)
        end
    end

    KrakenSquad.MakeKFButton(scroll, "+ " .. KrakenSquad.L("admin_create_order"), "solid", function()
        KF.Helpers.PlaySound(SOUNDS.click)
        editingOrder, editingOrderIdx, editingOrderSource = nil, nil, "orders"
        activeSection = "order_edit"
        Rebuild()
    end, 38, { 12, 4 })

    FormSpacer(scroll, 8)
    local count = 0
    for _ in pairs(KrakenSquad.ClientOrders) do count = count + 1 end

    local badge = vgui.Create("DPanel", scroll)
    badge:Dock(TOP); badge:SetTall(KF.Scale(28))
    badge:DockMargin(0, KF.Scale(4), 0, KF.Scale(8))
    badge.Paint = function(_, _, h)
        draw.SimpleText(KrakenSquad.L("admin_active_orders", count), F("tiny"),
            KF.Scale(4), h / 2, P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    for id, order in SortedPairs(KrakenSquad.ClientOrders) do
        local rem = order.permanent and math.huge or ((order.expire or 0) - CurTime())
        if order.permanent or rem > 0 then MakeOrderCard(scroll, id, order, "orders") end
    end
end

local function BuildPermanentOrders(scroll)
    FormHeader(scroll, KrakenSquad.L("admin_permanent_orders"), SectionDesc("permanent_orders"))
    for id, order in SortedPairs(KrakenSquad.ClientOrders) do
        if order.permanent then MakeOrderCard(scroll, id, order, "permanent_orders") end
    end
    KrakenSquad.MakeKFButton(scroll, "+ " .. KrakenSquad.L("admin_create_order"), "solid", function()
        KF.Helpers.PlaySound(SOUNDS.click)
        editingOrder = { permanent = true }
        editingOrderIdx, editingOrderSource = nil, "permanent_orders"
        activeSection = "order_edit"
        Rebuild()
    end, 38, { 12, 4 })
end

local function BuildOrderEditor(scroll)
    local source = editingOrder or {}
    local editIdx = editingOrderIdx
    local isPresetEditing = editIdx ~= nil
    local backSection = editingOrderSource or "orders"

    KrakenSquad.MakeKFButton(scroll, "\xe2\x86\x90 " .. KrakenSquad.L("admin_" .. backSection), nil, function()
        editingOrder, editingOrderIdx, editingOrderSource = nil, nil, nil
        activeSection = backSection
        Rebuild()
    end, 28, { 0, 6 })

    local headerLabel = isPresetEditing and KrakenSquad.L("order_edit_preset")
        or (source.id and KrakenSquad.L("order_update"))
        or KrakenSquad.L("admin_create_order")
    FormHeader(scroll, headerLabel, (isPresetEditing or source.id) and (source.name or source.title or "") or nil)

    local controller = KrakenSquad.BuildOrderEditor(scroll, formW, { source = source })
    local isEditingActive = source.id ~= nil

    if backSection ~= "permanent_orders" then
        SaveBtn(scroll,
            isPresetEditing and KrakenSquad.L("order_update_preset") or KrakenSquad.L("admin_save_preset"),
            function()
                local pending = controller.Collect()
                if #pending.title < 1 then return end
                local preset = table.Copy(pending); preset.name = pending.title
                KF.Net.SendJSON("KS.OrderPresetSave", preset)
                KF.Helpers.PlaySound(SOUNDS.success)
                editingOrder, editingOrderIdx, editingOrderSource = nil, nil, nil
                activeSection = backSection
                Rebuild()
            end)
    end

    KrakenSquad.MakeKFButton(scroll,
        isEditingActive and KrakenSquad.L("order_update") or KrakenSquad.L("admin_deploy"), "success",
        function()
            local pending = controller.Collect()
            if #pending.title < 1 then return end
            if isEditingActive then
                KrakenSquad.SendEditOrder(source.id, pending, false)
            else
                KrakenSquad.SendCreateOrder(pending, false)
            end
            KF.Helpers.PlaySound(SOUNDS.success)
            editingOrder, editingOrderIdx, editingOrderSource = nil, nil, nil
            activeSection = backSection
            timer.Simple(0.5, Rebuild)
        end, 36, { 4, 4 })

    if isPresetEditing then
        DeleteBtn(scroll, nil, function()
            net.Start("KS.OrderPresetDelete") net.WriteUInt(editIdx, 16) net.SendToServer()
            editingOrder, editingOrderIdx, editingOrderSource = nil, nil, nil
            activeSection = backSection
            Rebuild()
        end)
    end
end

local function BuildRespawns(scroll)
    local cfg = table.Copy(KrakenSquad.GetConfig("respawn") or {})
    FormHeader(scroll, KrakenSquad.L("admin_respawns"), SectionDesc("respawns"))
    FormToggle(scroll, KrakenSquad.L("admin_respawn_enabled"), cfg.enabled,
        function(v) cfg.enabled = v end, KrakenSquad.L("admin_respawn_enabled_desc"))
    FormToggle(scroll, KrakenSquad.L("admin_respawn_combat"), cfg.inCombatEnabled,
        function(v) cfg.inCombatEnabled = v end, KrakenSquad.L("admin_respawn_combat_desc"))
    FormNumber(scroll, KrakenSquad.L("admin_respawn_combat_time"), cfg.inCombatDuration,
        function(v) cfg.inCombatDuration = math.Clamp(math.floor(v), 1, 30) end,
        { desc = KrakenSquad.L("admin_respawn_combat_time_desc") })
    FormToggle(scroll, KrakenSquad.L("admin_respawn_timeout"), cfg.timeoutEnabled,
        function(v) cfg.timeoutEnabled = v end, KrakenSquad.L("admin_respawn_timeout_desc"))
    FormNumber(scroll, KrakenSquad.L("admin_respawn_timeout_time"), cfg.timeoutDuration,
        function(v) cfg.timeoutDuration = math.Clamp(math.floor(v), 5, 300) end,
        { desc = KrakenSquad.L("admin_respawn_timeout_time_desc") })
    FormNumber(scroll, KrakenSquad.L("admin_respawn_delay"), cfg.respawnDelay,
        function(v) cfg.respawnDelay = math.Clamp(math.floor(v), 0, 60) end,
        { desc = KrakenSquad.L("admin_respawn_delay_desc") })
    SaveBtn(scroll, nil, function() SendConfig({ respawn = cfg }) end)
end

local function BuildMRS(scroll)
    local cfg = table.Copy(KrakenSquad.GetMRSConfig())
    FormHeader(scroll, KrakenSquad.L("admin_mrs"), KrakenSquad.L("admin_desc_mrs"))
    FormToggle(scroll, KrakenSquad.L("admin_mrs_enabled"),    cfg.enabled,      function(v) cfg.enabled = v end,      KrakenSquad.L("admin_mrs_enabled_desc"))
    FormToggle(scroll, KrakenSquad.L("admin_mrs_short_name"), cfg.useShortName, function(v) cfg.useShortName = v end, KrakenSquad.L("admin_mrs_short_name_desc"))
    FormToggle(scroll, KrakenSquad.L("admin_mrs_show_icons"), cfg.showIcons,    function(v) cfg.showIcons = v end,    KrakenSquad.L("admin_mrs_show_icons_desc"))
    SaveBtn(scroll, nil, function() SendConfig({ mrs = cfg }) end)
end

local BUILDERS = {
    general = BuildGeneral,                positions = BuildPositions,
    communications = BuildCommunications,  commands = BuildCommands,
    orders = BuildOrders,                  order_edit = BuildOrderEditor,
    permanent_orders = BuildPermanentOrders,
    presets = BuildPresets,                preset_edit = BuildPresetEditor,
    xp = BuildXP,                          money = BuildMoney,
    colors = BuildColors,                  sounds = BuildSounds,
    npcs = BuildNPCs,                      binds = BuildBinds,
    language = BuildLanguage,              respawns = BuildRespawns,
    mrs = BuildMRS,
}

local function MakeSidebar(parent, w, h)
    local sidebar = vgui.Create("KF.ScrollPanel", parent)
    sidebar:SetPos(0, 0); sidebar:SetSize(w, h); sidebar:SetAddon(AID)
    sidebar.Paint = function(_, sw, sh)
        KF.Draw.RoundedBox(0, 0, sw, sh, 0, P("PanelDark"))
    end
    for _, group in ipairs(SIDEBAR_GROUPS) do
        KrakenSquad.MakeSidebarGroupLabel(sidebar, group.labelKey)
        for _, key in ipairs(group.items) do
            KrakenSquad.MakeSidebarButton(sidebar, KrakenSquad.L("admin_" .. key),
                function() return activeSection == key end,
                function() activeSection = key; Rebuild() end)
        end
    end
end

function KrakenSquad.OpenAdminMenu()
    if not KrakenSquad.IsAdmin(LocalPlayer()) then return end
    if IsValid(adminFrame) then adminFrame:Remove() end

    local sw, sh = ScrW(), ScrH()
    local fw = math.min(KF.Scale(900), math.floor(sw * 0.85))
    local fh = math.min(KF.Scale(750), math.floor(sh * 0.92))

    local frame = vgui.Create("KF.Frame")
    frame:SetSize(fw, fh); frame:Center(); frame:MakePopup()
    frame:SetAddon(AID); frame:SetFrameTitle(KrakenSquad.L("admin_title"))
    frame:SetNotchSide("right"); frame:SetHeaderHeight(42)
    adminFrame = frame
    KrakenSquad._AdminFrame = frame
    KF.Helpers.PlaySound(SOUNDS.open)

    KrakenSquad.MakeCloseButton(frame, fw - KF.Scale(52), KF.Scale(8))

    local sidebarW  = KF.Scale(170)
    local topOffset = KF.Scale(42)
    local bottomPad = KF.Scale(6)

    local sideContainer = vgui.Create("DPanel", frame)
    sideContainer:SetPos(0, topOffset)
    sideContainer:SetSize(sidebarW, fh - topOffset - bottomPad)
    sideContainer.Paint = function() end
    MakeSidebar(sideContainer, sidebarW, fh - topOffset - bottomPad)

    local layoutBtn = vgui.Create("KF.Button", sideContainer)
    layoutBtn:SetPos(KF.Scale(8), fh - topOffset - bottomPad - KF.Scale(38))
    layoutBtn:SetSize(sidebarW - KF.Scale(16), KF.Scale(30))
    layoutBtn:SetAddon(AID); layoutBtn:SetLabel(KrakenSquad.L("layout_editor"))
    layoutBtn:SetSolid(true)
    layoutBtn.DoClick = function()
        if IsValid(adminFrame) then adminFrame:Remove() end
        KrakenSquad.OpenLayoutEditor(true)
    end

    local content = vgui.Create("DPanel", frame)
    content:SetPos(sidebarW, topOffset)
    content:SetSize(fw - sidebarW, fh - topOffset - bottomPad)
    content.Paint = function(_, w, h)
        KF.Draw.RoundedBox(0, 0, w, h, 0, KF.UI.ColorAlpha(P("Panel"), 60))
    end

    frame._rebuildContent = function()
        if not IsValid(frame) then return end
        for _, c in ipairs(content:GetChildren()) do c:Remove() end
        formW = content:GetWide() - KF.Scale(44)
        local scroll = KrakenSquad.MakeScroll(content)
        local builder = BUILDERS[activeSection]
        if builder then builder(scroll) end
    end
    activeSection = "general"
    frame._rebuildContent()

    hook.Add("KrakenSquad.OrdersUpdated", "KS.AdminAutoRefresh", function()
        if not IsValid(frame) then hook.Remove("KrakenSquad.OrdersUpdated", "KS.AdminAutoRefresh") return end
        if activeSection == "orders" or activeSection == "permanent_orders" then frame._rebuildContent() end
    end)
    hook.Add("KrakenSquad.ConfigUpdated", "KS.AdminAutoRefresh", function()
        if not IsValid(frame) then hook.Remove("KrakenSquad.ConfigUpdated", "KS.AdminAutoRefresh") return end
        if activeSection == "orders" or activeSection == "presets" then frame._rebuildContent() end
    end)
    frame.OnRemove = function()
        hook.Remove("KrakenSquad.OrdersUpdated", "KS.AdminAutoRefresh")
        hook.Remove("KrakenSquad.ConfigUpdated", "KS.AdminAutoRefresh")
    end

    frame:SetAlpha(0); frame:AlphaTo(255, 0.15)
end

concommand.Add("ksquads_admin", KrakenSquad.OpenAdminMenu)

concommand.Add("krakensquad_removenpc", function()
    local lp = LocalPlayer()
    if not KrakenSquad.IsAdmin(lp) then return end
    local tr = lp:GetEyeTrace()
    if not IsValid(tr.Entity) or not tr.Entity:GetClass():StartWith("ent_krakensquad_") then return end
    net.Start("KS.RemoveNPC") net.WriteEntity(tr.Entity) net.SendToServer()
end)

concommand.Add("krakensquad_removeallnpcs", function()
    if not KrakenSquad.IsAdmin(LocalPlayer()) then return end
    net.Start("KS.RemoveAllNPCs") net.SendToServer()
end)
