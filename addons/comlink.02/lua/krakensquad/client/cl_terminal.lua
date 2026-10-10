local AID    = KrakenSquad.AID
local P      = KrakenSquad.P
local SOUNDS = KrakenSquad.SOUNDS

local function F(n)  return KF.Fonts.Get(AID, n) end
local function FB(n) return KF.Fonts.GetBold(AID, n) end

local function SendOrderJSON(name, data, extra)
    net.Start(name)
        if extra then extra() end
        local json = util.TableToJSON(data) or "{}"
        net.WriteUInt(#json, 32)
        net.WriteData(json, #json)
    net.SendToServer()
end

function KrakenSquad.SendCreateOrder(data, isTerminal)
    SendOrderJSON("KS.OrderCreate", data, function() net.WriteBool(isTerminal or false) end)
end

function KrakenSquad.SendEditOrder(id, data, isTerminal)
    SendOrderJSON("KS.OrderEdit", data, function()
        net.WriteBool(isTerminal or false)
        net.WriteUInt(id, 32)
    end)
end

function KrakenSquad.SendOrderStatus(id, status)
    net.Start("KS.OrderStatus")
        net.WriteUInt(id, 32)
        net.WriteString(status)
    net.SendToServer()
end

function KrakenSquad.BuildOrderEditor(scroll, formW, opts)
    local source = opts.source or {}
    local pending = {
        title         = source.title or source.name or "",
        description   = source.description or "",
        duration      = source.duration or 300,
        objectives    = table.Copy(source.objectives or {}),
        filters       = table.Copy(source.filters or {}),
        permanent     = source.permanent or false,
        targetSquadID = source.targetSquadID,
        targetSquadName = source.targetSquadName or "",
    }

    local function Field(label, value, onChange, fieldOpts)
        fieldOpts = fieldOpts or {}; fieldOpts.width = formW
        return KrakenSquad.FormField(scroll, label, value, onChange, fieldOpts)
    end
    local function Number(label, value, onChange, fieldOpts)
        fieldOpts = fieldOpts or {}; fieldOpts.width = formW
        return KrakenSquad.FormNumber(scroll, label, value, onChange, fieldOpts)
    end
    local function Toggle(label, checked, onChange, desc)
        return KrakenSquad.FormToggle(scroll, label, checked, onChange, desc, formW)
    end

    KrakenSquad.FormHeader(scroll, KrakenSquad.L("order_details"), nil, formW)
    Field(KrakenSquad.L("order_title"),       pending.title,       function(v) pending.title = v end,       { desc = KrakenSquad.L("order_title_desc") })
    Field(KrakenSquad.L("order_description"), pending.description, function(v) pending.description = v end, { desc = KrakenSquad.L("order_description_desc") })
    Number(KrakenSquad.L("order_duration"),   pending.duration,
        function(v) pending.duration = math.Clamp(v, 30, 7200) end,
        { desc = KrakenSquad.L("order_duration_desc") })
    Toggle(KrakenSquad.L("order_permanent"), pending.permanent,
        function(v) pending.permanent = v end, KrakenSquad.L("order_permanent_desc"))

    KrakenSquad.FormSpacer(scroll, 8)
    KrakenSquad.FormHeader(scroll, KrakenSquad.L("order_objectives"), nil, formW)

    local objContainer = vgui.Create("DPanel", scroll)
    objContainer:Dock(TOP); objContainer:DockMargin(0, KF.Scale(4), 0, 0)
    objContainer:SetTall(0); objContainer.Paint = function() end
    local objPanels = {}

    local function RebuildObjectives()
        for _, op in ipairs(objPanels) do if IsValid(op) then op:Remove() end end
        objPanels = {}
        local total = 0
        for idx, obj in ipairs(pending.objectives) do
            local op, rowH = KrakenSquad.BuildObjectiveRow(objContainer, obj, idx, pending, RebuildObjectives)
            objPanels[#objPanels + 1] = op
            total = total + rowH + KF.Scale(2)
        end
        objContainer:SetTall(total)
        objContainer:InvalidateLayout(true)
    end

    KrakenSquad.MakeKFButton(scroll, "+ " .. KrakenSquad.L("order_add_objective"), "solid", function()
        if #pending.objectives >= KrakenSquad.MAX_LENGTHS.maxObjectives then return end
        table.insert(pending.objectives, { text = "", priority = "main" })
        RebuildObjectives()
    end, 34, { 6, 0 })
    if #pending.objectives > 0 then RebuildObjectives() end

    KrakenSquad.FormSpacer(scroll, 8)
    KrakenSquad.FormHeader(scroll, KrakenSquad.L("order_filters"), KrakenSquad.L("admin_filter_desc"), formW)

    local note = vgui.Create("DPanel", scroll)
    note:Dock(TOP); note:DockMargin(0, KF.Scale(2), 0, 0); note:SetTall(KF.Scale(20))
    note.Paint = function(_, _, h)
        draw.SimpleText(KrakenSquad.L("admin_filter_note"), F("tiny"), KF.Scale(6), h / 2,
            P("Warning"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local filterStore = {}
    local function BuildFilter(ftype, list)
        local items = {}
        for _, e in ipairs(list) do
            items[#items + 1] = { id = tostring(e.id), name = tostring(e.name) }
        end
        local selected = {}
        for _, f in ipairs(pending.filters) do
            if f.type == ftype then selected[#selected + 1] = tostring(f.value) end
        end
        KrakenSquad.MakeCollapsibleSection(scroll, ftype, ftype, items, selected, filterStore)
    end
    BuildFilter("job",      KF.Integrations.GetJobs())
    BuildFilter("faction",  KF.Integrations.GetFactions())
    BuildFilter("category", KF.Integrations.GetCategories())

    return {
        pending = pending,
        Collect = function()
            pending.filters = KrakenSquad.CollectFilters(filterStore)
            return pending
        end,
    }
end

function KrakenSquad.OpenTerminal(editPreset)
    if IsValid(KrakenSquad._TermFrame) then KrakenSquad._TermFrame:Remove() end
    KF.Fonts.Create(AID)
    KF.Helpers.PlaySound(SOUNDS.open)

    local sw, sh = ScrW(), ScrH()
    local fw = math.min(KF.Scale(680), math.floor(sw * 0.7))
    local fh = math.min(KF.Scale(700), math.floor(sh * 0.88))

    local frame = vgui.Create("KF.Frame")
    frame:SetSize(fw, fh); frame:Center(); frame:MakePopup()
    frame:SetAddon(AID); frame:SetFrameTitle(KrakenSquad.L("orders_terminal"))
    frame:SetHeaderHeight(42)
    KrakenSquad._TermFrame = frame
    KrakenSquad.MakeCloseButton(frame, fw - KF.Scale(42), KF.Scale(8))

    local sidebarW  = KF.Scale(140)
    local topOffset = KF.Scale(42)
    local bottomPad = KF.Scale(6)

    local sideP = vgui.Create("DPanel", frame)
    sideP:SetPos(0, topOffset); sideP:SetSize(sidebarW, fh - topOffset - bottomPad)
    sideP.Paint = function(_, w, h) KF.Draw.RoundedBox(0, 0, w, h, 0, P("PanelDark")) end

    local contentP = vgui.Create("DPanel", frame)
    contentP:SetPos(sidebarW, topOffset)
    contentP:SetSize(fw - sidebarW, fh - topOffset - bottomPad)
    contentP.Paint = function(_, w, h)
        KF.Draw.RoundedBox(0, 0, w, h, 0, KF.UI.ColorAlpha(P("Panel"), 60))
    end

    local view, editingOrderId = "editor", nil
    local function FormW() return contentP:GetWide() - KF.Scale(38) end

    local BuildEditor, BuildPresets, BuildActive, BuildSidebar
    local function Rebuild()
        for _, c in ipairs(contentP:GetChildren()) do c:Remove() end
        if view == "editor"  then BuildEditor()
        elseif view == "presets" then BuildPresets()
        elseif view == "active"  then BuildActive()
        end
    end

    BuildEditor = function()
        local scroll = KrakenSquad.MakeScroll(contentP)
        local source = (editingOrderId and KrakenSquad.ClientOrders[editingOrderId]) or editPreset or {}
        local controller = KrakenSquad.BuildOrderEditor(scroll, FormW(), { source = source })

        local saveBtn = vgui.Create("KF.Button", scroll)
        saveBtn:Dock(TOP); saveBtn:SetTall(KF.Scale(36))
        saveBtn:DockMargin(0, KF.Scale(14), 0, KF.Scale(4))
        saveBtn:SetAddon(AID)
        saveBtn:SetLabel(editPreset and KrakenSquad.L("order_update_preset") or KrakenSquad.L("admin_save_preset"))
        saveBtn:SetSolid(true)
        saveBtn.DoClick = function()
            local pending = controller.Collect()
            if #pending.title < 1 then return end
            local preset = table.Copy(pending); preset.name = pending.title
            KF.Net.SendJSON("KS.OrderPresetSave", preset)
            KF.Helpers.PlaySound(SOUNDS.success)
            timer.Simple(0.5, function()
                if not IsValid(frame) then return end
                editPreset, editingOrderId, view = nil, nil, "editor"
                Rebuild(); BuildSidebar()
            end)
        end

        local deploy = vgui.Create("KF.Button", scroll)
        deploy:Dock(TOP); deploy:SetTall(KF.Scale(40))
        deploy:DockMargin(0, KF.Scale(4), 0, KF.Scale(12))
        deploy:SetAddon(AID)
        deploy:SetLabel(editingOrderId and KrakenSquad.L("order_update") or KrakenSquad.L("admin_deploy"))
        deploy:SetStyle("success")
        deploy.DoClick = function()
            local pending = controller.Collect()
            if #pending.title < 1 then return end
            if editingOrderId then
                KrakenSquad.SendEditOrder(editingOrderId, pending, true)
            else
                KrakenSquad.SendCreateOrder(pending, true)
            end
            KF.Helpers.PlaySound(SOUNDS.success)
            if IsValid(frame) then frame:Remove() end
        end
    end

    BuildPresets = function()
        local scroll = KrakenSquad.MakeScroll(contentP)
        KrakenSquad.FormHeader(scroll, KrakenSquad.L("admin_order_presets"), nil, FormW())

        local presets = KrakenSquad.GetConfig("orderPresets") or {}
        if #presets == 0 then KrakenSquad.MakeEmptyLabel(scroll) end

        for pidx, op in ipairs(presets) do
            local p = KrakenSquad.UI.MakeListCard(scroll, {
                paint = function(_, _, h)
                    draw.SimpleText(op.name or KrakenSquad.L("unknown_player"), FB("body"),
                        KF.Scale(16), h / 2 - KF.Scale(6), P("Accent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local meta = {}
                    if op.permanent  then meta[#meta + 1] = KrakenSquad.L("order_permanent") end
                    if op.duration   then meta[#meta + 1] = op.duration .. "s" end
                    if op.objectives then meta[#meta + 1] = #op.objectives .. " obj" end
                    draw.SimpleText(table.concat(meta, " \xc2\xb7 "), F("tiny"),
                        KF.Scale(16), h / 2 + KF.Scale(10), P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end,
            })

            local del = vgui.Create("KF.Button", p)
            del:Dock(RIGHT); del:DockMargin(0, KF.Scale(10), KF.Scale(8), KF.Scale(10))
            del:SetWide(KF.Scale(40)); del:SetAddon(AID)
            del:SetLabel("x"); del:SetStyle("danger")
            del.DoClick = function()
                KF.Helpers.PlaySound(SOUNDS.click)
                net.Start("KS.OrderPresetDelete") net.WriteUInt(pidx, 16) net.SendToServer()
                timer.Simple(0.5, function() if IsValid(frame) then Rebuild() end end)
            end

            local edit = vgui.Create("KF.Button", p)
            edit:Dock(RIGHT); edit:DockMargin(0, KF.Scale(10), KF.Scale(4), KF.Scale(10))
            edit:SetWide(KF.Scale(56)); edit:SetAddon(AID)
            edit:SetLabel(KrakenSquad.L("order_edit")); edit:SetSolid(true)
            edit.DoClick = function()
                KF.Helpers.PlaySound(SOUNDS.click)
                editPreset, editingOrderId, view = table.Copy(op), nil, "editor"
                Rebuild(); BuildSidebar()
            end

            local use = vgui.Create("KF.Button", p)
            use:Dock(RIGHT); use:DockMargin(0, KF.Scale(10), KF.Scale(4), KF.Scale(10))
            use:SetWide(KF.Scale(70)); use:SetAddon(AID)
            use:SetLabel(KrakenSquad.L("admin_deploy")); use:SetStyle("success")
            use.DoClick = function()
                KF.Helpers.PlaySound(SOUNDS.success)
                KrakenSquad.SendCreateOrder(op, true)
                if IsValid(frame) then frame:Remove() end
            end
        end
    end

    BuildActive = function()
        local scroll = KrakenSquad.MakeScroll(contentP)
        local orders = KrakenSquad.ClientOrders
        local count = 0
        for _ in pairs(orders) do count = count + 1 end
        KrakenSquad.FormHeader(scroll, KrakenSquad.L("admin_active_orders", count), nil, FormW())
        if count == 0 then KrakenSquad.MakeEmptyLabel(scroll) end

        for id, order in SortedPairs(orders) do
            local rem = order.permanent and math.huge or ((order.expire or 0) - CurTime())
            if not order.permanent and rem <= 0 then continue end

            local p = KrakenSquad.UI.MakeListCard(scroll, {
                tall = 72, gap = 4,
                statusColor = function()
                    return order.status == "succeeded" and P("Success")
                        or order.status == "failed"    and P("Error")
                        or P("Accent")
                end,
                paint = function(_, w, h)
                    local cur = order.permanent and math.huge or ((order.expire or 0) - CurTime())
                    local statusCol = order.status == "succeeded" and P("Success")
                                   or order.status == "failed"    and P("Error")
                                   or P("Accent")
                    local rightPad = KF.Scale(200)
                    local timeStr = order.permanent and "\xe2\x88\x9e" or
                        ("%d:%02d"):format(math.floor(cur / 60), math.floor(cur % 60))
                    surface.SetFont(F("tiny"))
                    local timeX = w - rightPad - surface.GetTextSize(timeStr)
                    draw.SimpleText(timeStr, F("tiny"), timeX, h / 2 - KF.Scale(12),
                        (not order.permanent and cur < 60) and P("Error") or P("TextMuted"),
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local title = (order.title or KrakenSquad.L("order_fallback_title")):upper()
                    draw.SimpleText(KF.TruncateText(title, F("body"), timeX - KF.Scale(24)), FB("body"),
                        KF.Scale(16), h / 2 - KF.Scale(12), statusCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local meta = {}
                    if order.status and order.status ~= "active" then meta[#meta + 1] = order.status:upper() end
                    if order.issuer then meta[#meta + 1] = order.issuer end
                    draw.SimpleText(table.concat(meta, " \xc2\xb7 "), F("tiny"),
                        KF.Scale(16), h / 2 + KF.Scale(8), P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end,
            })

            local del = vgui.Create("KF.Button", p)
            del:Dock(RIGHT); del:DockMargin(0, KF.Scale(16), KF.Scale(4), KF.Scale(16))
            del:SetWide(KF.Scale(56)); del:SetAddon(AID)
            del:SetLabel(KrakenSquad.L("admin_delete")); del:SetStyle("danger")
            del.DoClick = function()
                KF.Helpers.PlaySound(SOUNDS.click)
                net.Start("KS.OrderDelete") net.WriteUInt(id, 32) net.SendToServer()
                timer.Simple(0.5, function() if IsValid(frame) then Rebuild() end end)
            end

            local edit = vgui.Create("KF.Button", p)
            edit:Dock(RIGHT); edit:DockMargin(0, KF.Scale(16), KF.Scale(4), KF.Scale(16))
            edit:SetWide(KF.Scale(50)); edit:SetAddon(AID)
            edit:SetLabel(KrakenSquad.L("order_edit")); edit:SetSolid(true)
            edit.DoClick = function()
                KF.Helpers.PlaySound(SOUNDS.click)
                editingOrderId, view, editPreset = id, "editor", nil
                Rebuild(); BuildSidebar()
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
                    timer.Simple(0.5, function() if IsValid(frame) then Rebuild() end end)
                end
            end
        end
    end

    BuildSidebar = function()
        for _, c in ipairs(sideP:GetChildren()) do c:Remove() end
        local sideScroll = vgui.Create("KF.ScrollPanel", sideP)
        sideScroll:Dock(FILL); sideScroll:SetAddon(AID); sideScroll.Paint = function() end

        KrakenSquad.MakeSidebarGroupLabel(sideScroll, "sidebar_orders")
        local editorLabel = (editingOrderId or editPreset)
            and KrakenSquad.L("term_edit_order") or KrakenSquad.L("term_create_order")
        for _, sec in ipairs({
            { key = "editor",  label = editorLabel },
            { key = "presets", label = KrakenSquad.L("term_order_presets") },
            { key = "active",  label = KrakenSquad.L("term_active_orders") },
        }) do
            KrakenSquad.MakeSidebarButton(sideScroll, sec.label,
                function() return view == sec.key end,
                function() view = sec.key; Rebuild() end)
        end
    end

    BuildSidebar()
    BuildEditor()

    hook.Add("KrakenSquad.OrdersUpdated", "KS.TermAutoRefresh", function()
        if not IsValid(frame) then hook.Remove("KrakenSquad.OrdersUpdated", "KS.TermAutoRefresh") return end
        if view == "active" then BuildActive() end
    end)
    hook.Add("KrakenSquad.ConfigUpdated", "KS.TermAutoRefresh", function()
        if not IsValid(frame) then hook.Remove("KrakenSquad.ConfigUpdated", "KS.TermAutoRefresh") return end
        if view == "presets" then BuildPresets() end
    end)
    frame.OnRemove = function()
        hook.Remove("KrakenSquad.OrdersUpdated", "KS.TermAutoRefresh")
        hook.Remove("KrakenSquad.ConfigUpdated", "KS.TermAutoRefresh")
    end

    frame:SetAlpha(0); frame:AlphaTo(255, 0.15)
end
