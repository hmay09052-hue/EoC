--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Einheiten-Übersicht (Holo-Projektor mit Beispielmodell)
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S
local U = symchars.util
local F = symchars.factions

local CYCLE = 6 -- Sekunden pro Modell

local function OnlineCount(list)
    local n = 0
    for _, char in ipairs(list) do if char:IsOnline() then n = n + 1 end end
    return n
end

-- Alle Modelle der Einheit: Beispielmodell, dann die Jobs der Ränge (niedrigster zuerst), dann der Einheits-Job
local function UnitModels(unit)
    local out, seen = {}, {}
    local function Add(model, label, sub)
        model = U.Trim(model)
        if model == "" or seen[string.lower(model)] then return end
        seen[string.lower(model)] = true
        out[#out + 1] = { model = model, label = label, sub = sub or "" }
    end
    if U.Trim(unit.model) ~= "" then Add(unit.model, unit.name, "Beispielmodell") end
    for _, r in ipairs(unit:GetRanks()) do
        local job = U.Trim(r.job) ~= "" and r.job or unit.job
        local extras = F.GetRankExtras(r)
        if extras.model ~= "" then Add(extras.model, r.name, U.JobName(job)) end
        for _, m in ipairs(U.JobModels(job)) do Add(m, r.name, U.JobName(job)) end
    end
    for _, m in ipairs(U.JobModels(unit.job)) do Add(m, unit.name, U.JobName(unit.job)) end
    if #out == 0 then Add(unit:GetModel(), unit.name, "") end
    return out
end

local function Build(parent, opts)
    local page = vgui.Create("DPanel", parent)
    page:Dock(FILL)

    local state = { root = nil, unit = nil, models = {}, idx = 1, nextSwap = 0 }

    local listPanel = vgui.Create("DPanel", page)
    listPanel.Paint = nil
    local list = UI.Scroll(listPanel)
    list:Dock(FILL)
    list:DockMargin(0, S(40), 0, 0)

    local holo = UI.HoloModel(page, "holo")
    holo:SetSpin(16)
    holo:SetFOV(30)

    -- Modell-Wechsler unter dem Hologramm (Ränge/Jobs der Einheit)
    local strip = vgui.Create("DPanel", page)
    local function Step(dir, manual)
        local n = #state.models
        if n == 0 then return end
        state.idx = (state.idx - 1 + dir) % n + 1
        holo:SetHoloModel(state.models[state.idx].model, { force = true })
        state.swapLen = CYCLE * (manual and 2 or 1)
        state.nextSwap = RealTime() + state.swapLen
    end
    local prev = UI.Button(strip, "", "default", function() Step(-1, true) end)
    prev:SetIcon("arrow_left")
    local nxt = UI.Button(strip, "", "default", function() Step(1, true) end)
    nxt:SetIcon("arrow_right")
    strip.PerformLayout = function(_, w, h)
        local bs = h - S(20)
        prev:SetSize(bs, bs)
        prev:SetPos(S(10), S(10))
        nxt:SetSize(bs, bs)
        nxt:SetPos(w - S(10) - bs, S(10))
    end
    strip.Paint = function(_, w, h)
        local cur = state.models[state.idx]
        if not cur then return end
        UI.Box(0, 0, w, h, Color(0, 0, 0, 190))
        UI.Outline(0, 0, w, h, UI.Holo(70))
        local inner = w - (h - S(20)) * 2 - S(40)
        UI.TextFit(string.upper(cur.label), "symchars.h3", w / 2, S(8), UI.col.text, inner, TEXT_ALIGN_CENTER)
        local sub = (cur.sub ~= "" and (cur.sub .. "  ·  ") or "") .. state.idx .. " / " .. #state.models
        UI.TextFit(sub, "symchars.tiny", w / 2, S(42), UI.Holo(220), inner, TEXT_ALIGN_CENTER)
        if #state.models > 1 then
            local t = math.Clamp(1 - (state.nextSwap - RealTime()) / (state.swapLen or CYCLE), 0, 1)
            UI.Box(0, h - S(3), w * t, S(3), UI.Holo(200))
        end
    end
    page.Think = function()
        if #state.models < 2 or RealTime() < state.nextSwap then return end
        if strip:IsHovered() or prev:IsHovered() or nxt:IsHovered() or holo._drag then
            state.swapLen = 1
            state.nextSwap = RealTime() + 1
            return
        end
        Step(1)
    end

    local info = vgui.Create("DPanel", page)
    local infoScroll = UI.Scroll(info)
    infoScroll:Dock(FILL)

    page.Paint = function(_, w, h)
        UI.Text("ÜBERSICHT  /  EINHEITEN", "symchars.h4", 0, 0, UI.col.dim)
        UI.Aurebesh("Übersicht Einheiten", "symchars.aure.small", 0, S(22), UI.Alpha(UI.col.dim, 90))
        if state.unit then
            local cx = holo.x + holo:GetWide() / 2
            UI.Aurebesh(state.unit.short ~= "" and state.unit.short or state.unit.name, "symchars.aure.big", cx, h - S(46), UI.Holo(160), TEXT_ALIGN_CENTER)
        end
    end

    local function ShowUnit(unit)
        local same = state.unit and state.unit.uniqueID == unit.uniqueID
        state.unit = unit
        local models = UnitModels(unit)
        local cur = state.models[state.idx]
        local keep = same and cur and models[state.idx] and models[state.idx].model == cur.model
        state.models = models
        if not keep then
            state.idx = 1
            holo:SetHoloModel(models[1] and models[1].model or unit:GetModel(), { force = true })
            state.swapLen = CYCLE
            state.nextSwap = RealTime() + CYCLE
        end
        prev:SetVisible(#models > 1)
        nxt:SetVisible(#models > 1)
        infoScroll:Clear()

        local members = symchars.chars.GetMembers(unit, true)
        local direct = symchars.chars.GetMembers(unit, false)
        local col = unit:GetColor()

        -- Banner + Logo + Name
        local top = vgui.Create("DPanel", infoScroll)
        top:Dock(TOP)
        top:SetTall(S(250))
        top.Paint = function(_, w)
            local bh = S(150)
            local root = state.root
            local banner = unit.banner ~= "" and unit.banner or (root and root.banner or "")
            if not (banner ~= "" and UI.DrawImage(banner, 0, 0, w, bh, color_white, "cover")) then
                UI.Gradient(0, 0, w, bh, UI.Alpha(col, 120), "right")
                UI.Box(0, 0, w, bh, Color(10, 12, 16, 120))
                UI.Scanlines(0, 0, w, bh, 50)
            end
            UI.Gradient(0, bh - S(70), w, S(70), Color(9, 11, 14, 245), "up")
            UI.Outline(0, 0, w, bh, UI.col.line2)
            local ls = S(110)
            UI.Circle(S(20) + ls / 2, bh - S(30) + ls / 2 - S(10), ls / 2 + S(4), Color(9, 11, 14, 250), 40)
            UI.Ring(S(20) + ls / 2, bh - S(30) + ls / 2 - S(10), ls / 2 + S(4), UI.Alpha(col, 220), S(2), 40)
            UI.DrawUnitLogo(unit, S(20) + S(10), bh - S(30), ls - S(20))
            local tx = S(150)
            UI.TextFit(string.upper(unit.name), "symchars.h1", tx, bh + S(6), UI.col.text, w - tx)
            UI.Aurebesh(unit.name, "symchars.aure.small", tx + S(2), bh + S(48), UI.Alpha(UI.col.dim, 140), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - tx)
            local path = F.GetDisplayName(unit)
            if path ~= unit.name then UI.TextFit(path, "symchars.tiny", tx, bh + S(70), UI.col.muted, w - tx) end
        end

        -- Untereinheiten-Dropdown
        local root = state.root or unit
        local subs = F.GetDescendants(root)
        if #subs > 0 then
            local field = vgui.Create("DPanel", infoScroll)
            field:Dock(TOP)
            field:SetTall(S(84))
            field:DockMargin(0, S(6), 0, 0)
            field.Paint = function() UI.Text("UNTEREINHEIT", "symchars.h4", 0, 0, UI.col.dim) end
            local combo = UI.Combo(field, "Untereinheit wählen")
            combo:SetPos(0, S(28))
            combo:SetFont("symchars.body.bold")
            field.PerformLayout = function(_, w) combo:SetSize(w, S(44)) end
            combo:AddChoice(root.name .. "  (Haupteinheit)", root.uniqueID, unit.uniqueID == root.uniqueID, 0)
            for _, item in ipairs(subs) do
                combo:AddChoice(item.data.name, item.data.uniqueID, item.data.uniqueID == unit.uniqueID, item.depth, #symchars.chars.GetMembers(item.data, false) .. " Mitgl.")
            end
            combo.OnSelect = function(_, _, _, id)
                local target = F.Get(id)
                if target then ShowUnit(target) end
            end
        end

        -- Kennzahlen
        local stats = vgui.Create("DPanel", infoScroll)
        stats:Dock(TOP)
        stats:SetTall(S(92))
        stats:DockMargin(0, S(10), 0, 0)
        stats.Paint = function(_, w, h)
            local values = {
                { "Mitglieder", tostring(#members) },
                { "Online", tostring(OnlineCount(members)) },
                { "Ränge", tostring(#unit:GetRanks()) },
                { "Untereinh.", tostring(#F.GetDescendants(unit)) },
            }
            local cw = (w - S(18)) / #values
            for i, v in ipairs(values) do
                local x = (i - 1) * (cw + S(6))
                UI.Cut(x, 0, cw, h, Color(16, 20, 26, 235), S(10), "tr")
                UI.Box(x, 0, S(3), h, i == 2 and UI.col.green or UI.Alpha(col, 220))
                UI.Text(v[2], "symchars.h1", x + S(16), S(6), UI.col.text)
                UI.Text(string.upper(v[1]), "symchars.tiny.bold", x + S(16), h - S(26), UI.col.muted)
            end
        end

        -- Beschreibung
        local desc = unit:GetDescription()
        if desc == "" then desc = "Keine Beschreibung vorhanden." end
        local descPanel = vgui.Create("DPanel", infoScroll)
        descPanel:Dock(TOP)
        descPanel:DockMargin(0, S(14), 0, 0)
        descPanel.PerformLayout = function(s, w)
            local th = UI.WrapHeight(desc, "symchars.body", w - S(4))
            s:SetTall(th + S(40))
        end
        descPanel.Paint = function(_, w)
            UI.Section("Beschreibung", 0, 0, w)
            UI.DrawWrapped(desc, "symchars.body", 0, S(34), w - S(4), UI.col.dim)
        end

        -- Beitreten
        local char = UI.LocalChar()
        if unit.isJoinable and char and char.faction ~= unit.uniqueID then
            local join = UI.Button(infoScroll, "Einheit beitreten", "primary", function()
                UI.Confirm("Beitreten", "Möchtest du der Einheit '" .. unit.name .. "' beitreten? Du verlässt deine aktuelle Einheit.", function()
                    symchars.net.SendToServer("unit_join", { id = unit.uniqueID })
                end, nil, "Beitreten")
            end)
            join:Dock(TOP)
            join:DockMargin(0, S(12), 0, 0)
            join:SetTall(S(52))
            join:SetFont("symchars.h2")
            local nat = symchars.utils.CharNationality(char)
            local natOk, why = symchars.utils.NationalityAllowsUnit(nat, unit)
            if nat and not natOk then
                join:SetStyle("default")
                join:SetLocked(why)
                join.DoClick = function() end
            end
        end

        -- Ränge
        local ranks = unit:GetRanks()
        local rankPanel = vgui.Create("DPanel", infoScroll)
        rankPanel:Dock(TOP)
        rankPanel:DockMargin(0, S(16), 0, 0)
        rankPanel:SetTall(S(36) + #ranks * S(34))
        rankPanel.Paint = function(_, w)
            UI.Section("Ränge", 0, 0, w)
            local counts = {}
            for _, m in ipairs(direct) do counts[m:GetRank()] = (counts[m:GetRank()] or 0) + 1 end
            for i = #ranks, 1, -1 do
                local r = ranks[i]
                local y = S(36) + (#ranks - i) * S(34)
                UI.Box(0, y, w, S(30), (i % 2 == 0) and Color(255, 255, 255, 6) or Color(0, 0, 0, 0))
                UI.Box(0, y + S(6), S(4), S(18), col)
                UI.Text(tostring(i), "symchars.tiny.bold", S(14), y + S(15), UI.col.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                UI.TextFit(r.name, "symchars.body", S(40), y + S(15), UI.col.text, w - S(170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if r.short ~= "" then UI.Text(r.short, "symchars.tiny.bold", w - S(80), y + S(15), UI.col.dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
                local max = F.GetRankMax(r)
                UI.Text((counts[i] or 0) .. (max > 0 and ("/" .. max) or ""), "symchars.small.bold", w - S(6), y + S(15), UI.col.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end

        -- Fortbildungen dieser Einheit
        local trainings = {}
        for _, t in ipairs(symchars.trainings.List()) do
            if #t.units > 0 and symchars.trainings.AppliesToUnit(t, unit.uniqueID) then trainings[#trainings + 1] = t end
        end
        if #trainings > 0 then
            local tp = vgui.Create("DPanel", infoScroll)
            tp:Dock(TOP)
            tp:DockMargin(0, S(16), 0, S(20))
            tp:SetTall(S(36) + math.ceil(#trainings / 2) * S(40))
            tp.Paint = function(_, w)
                UI.Section("Fortbildungen", 0, 0, w)
                local cw = (w - S(8)) / 2
                for i, t in ipairs(trainings) do
                    local x = ((i - 1) % 2) * (cw + S(8))
                    local y = S(36) + math.floor((i - 1) / 2) * S(40)
                    UI.Box(x, y, cw, S(34), Color(16, 20, 26, 230))
                    UI.Box(x, y, S(3), S(34), t.color)
                    UI.TextFit(t.name, "symchars.small.bold", x + S(12), y + S(17), UI.col.text, cw - S(20), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
        end
    end

    local buttons = {}
    local function SelectRoot(root, unit)
        state.root = root
        for _, b in ipairs(buttons) do b:SetSelected(b.root == root) end
        ShowUnit(unit or root)
    end

    local function Rebuild()
        list:Clear()
        buttons = {}
        local roots = {}
        for _, r in ipairs(F.GetRoots()) do if not r.hidden then roots[#roots + 1] = r end end
        for _, root in ipairs(roots) do
            local b = UI.Button(list, root.name, "select")
            b.root = root
            b:Dock(TOP)
            b:SetTall(S(58))
            b:DockMargin(0, 0, S(6), S(8))
            b:SetAlign(TEXT_ALIGN_LEFT)
            b:SetFont("symchars.h3")
            local subs = #F.GetDescendants(root)
            b:SetSubText((#symchars.chars.GetMembers(root, true)) .. " Mitglieder" .. (subs > 0 and ("  ·  " .. subs .. " Untereinheiten") or ""))
            b.DoClick = function() SelectRoot(root) end
            buttons[#buttons + 1] = b
        end

        local target = opts.unit and F.Get(opts.unit)
        opts.unit = nil
        if target then
            SelectRoot(F.GetRoot(target), target)
        elseif state.unit and F.Get(state.unit.uniqueID) then
            SelectRoot(F.GetRoot(state.unit), F.Get(state.unit.uniqueID))
        else
            local char = UI.LocalChar()
            local own = char and char:GetFaction()
            if own then SelectRoot(F.GetRoot(own), own) elseif roots[1] then SelectRoot(roots[1]) end
        end
    end

    page.PerformLayout = function(_, w, h)
        local leftW = math.min(S(420), w * 0.25)
        local rightW = math.min(S(560), w * 0.33)
        listPanel:SetPos(0, 0)
        listPanel:SetSize(leftW, h)
        local holoW = w - leftW - rightW - S(30)
        local stripH = S(70)
        holo:SetPos(leftW + S(10), S(10))
        holo:SetSize(holoW, h - S(60) - stripH - S(14))
        local sw = math.min(holoW - S(20), S(520))
        strip:SetSize(sw, stripH)
        strip:SetPos(leftW + S(10) + (holoW - sw) / 2, h - S(60) - stripH)
        info:SetPos(w - rightW, S(40))
        info:SetSize(rightW, h - S(40))
    end

    info.Paint = nil

    hook.Add("symchars_factions_synced", page, function() Rebuild() end)
    hook.Add("symchars_chars_synced", page, function() if state.unit then ShowUnit(state.unit) end end)
    Rebuild()
end

UI.RegisterPage({
    id = "units", name = "Einheiten", order = 2,
    visible = function() return symchars.Config("usefactions") == true end,
    build = Build,
})
