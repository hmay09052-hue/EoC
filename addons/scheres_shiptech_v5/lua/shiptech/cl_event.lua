--[[
    ShipTech – Event-Menü (/event)
]]

local T = ShipTech.Theme
local UI = ShipTech.UI
local Send = function(act, args) ShipTech.SendEvent(act, args) end

local function Row(parent, h)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:SetTall(h or 36)
    p:DockMargin(0, 0, 0, 6)
    p.Paint = function() end
    return p
end

-- Buttons gleichmäßig in einer Zeile verteilen
local function ButtonRow(parent, list, h)
    local row = Row(parent, h or 36)
    local btns = {}
    for _, b in ipairs(list) do
        btns[#btns + 1] = UI.Button(row, b[1], b[2], b[3])
    end
    row.PerformLayout = function(s, w, hh)
        local bw = (w - (#btns - 1) * 6) / #btns
        for i, b in ipairs(btns) do
            b:SetPos((i - 1) * (bw + 6), 0)
            b:SetSize(bw, hh)
        end
    end
    return row, btns
end

local function Slider(parent, text, min, max, val, dec)
    local s = vgui.Create("DNumSlider", parent)
    s:Dock(TOP)
    s:SetTall(32)
    s:DockMargin(0, 0, 0, 4)
    s:SetText(text)
    s:SetMin(min)
    s:SetMax(max)
    s:SetDecimals(dec or 0)
    s:SetValue(val)
    s.Label:SetTextColor(T.text)
    s.Label:SetFont("ShipTech_UIBold")
    s.Paint = function(_, w, h) ShipTech.Box(0, 0, w, h, T.panel) end
    s:GetTextArea():SetTextColor(T.text)
    return s
end

local function Combo(parent, choices, h)
    local c = UI.StyleCombo(vgui.Create("DComboBox", parent))
    c:SetTall(h or 30)
    for i, ch in ipairs(choices) do c:AddChoice(ch[1], ch[2], i == 1) end
    return c
end

local function ComboValue(c)
    local _, v = c:GetSelected()
    return v
end

local function Section(parent, title)
    UI.Header(parent, title)
end

---------------------------------------------------------------------------
function ShipTech.OpenEventMenu()
    if IsValid(ShipTech.EventFrame) then ShipTech.EventFrame:Remove() end
    local f = UI.Frame("Event-Menü", 1380, 880, "Eventsteuerung", function() return "EVENTLER", T.accent end)
    ShipTech.EventFrame = f

    -- Reiter oben rechts im Kopf (wie im Funksystem)
    local content = vgui.Create("DPanel", f)
    content:Dock(FILL)
    content.Paint = function() end
    local sheets, tabBtns = {}, {}
    local sheet = {}
    -- Reiter werden gesammelt und am Ende als Reiterleiste (wie im Charaktersystem) angelegt
    local tabDefs = {}
    function sheet:AddSheet(name, panel)
        panel:SetParent(content)
        panel:Dock(FILL)
        sheets[#sheets + 1] = panel
        panel:SetVisible(#sheets == 1)
        tabDefs[#tabDefs + 1] = { id = #sheets, name = name }
    end
    function sheet:Finish()
        local function showSheet(idx)
            for i, p in ipairs(sheets) do p:SetVisible(i == idx) end
        end
        local _, btns = UI.AddTabs(f, tabDefs, showSheet, nil, true)
        if btns[1] then btns[1].Active = true end
    end

    -----------------------------------------------------------------------
    -- Systeme
    -----------------------------------------------------------------------
    local pSys = vgui.Create("DPanel", content)
    pSys.Paint = function() end
    pSys:DockPadding(8, 8, 8, 8)
    sheet:AddSheet("Systeme", pSys)

    local sel = ShipTech.Systems[1].id
    local list = UI.Scroll(pSys)
    list:Dock(LEFT)
    list:SetWide(250)
    list:DockMargin(0, 0, 10, 0)

    local right = UI.Scroll(pSys)
    right:Dock(FILL)

    local sysBtns = {}
    for _, def in ipairs(ShipTech.Systems) do
        local b = vgui.Create("DButton", list)
        b:SetText("")
        b:Dock(TOP)
        b:SetTall(52)
        b:DockMargin(0, 0, 0, 4)
        b.Paint = function(s, w, h)
            local sys = ShipTech.Sys(def.id)
            local st = sys and ShipTech.Stages[ShipTech.StageOf(sys.health)] or ShipTech.Stages[0]
            local txt, col = ShipTech.StatusInfo(def.id)
            ShipTech.Box(0, 0, w, h, (sel == def.id) and T.panel2 or T.panel)
            surface.SetDrawColor(st.col)
            surface.DrawRect(0, 0, 4, h)
            if sel == def.id then
                surface.SetDrawColor(T.accent)
                surface.DrawOutlinedRect(0, 0, w, h)
            end
            draw.SimpleText(def.name, "ShipTech_UIBold", 14, 16, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(txt .. (sys and ("  ·  " .. math.Round(sys.health) .. " %") or ""), "ShipTech_UISmall", 14, 36, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function() sel = def.id; surface.PlaySound("buttons/lightswitch2.wav") end
        sysBtns[#sysBtns + 1] = b
    end

    -- Status des gewählten Systems
    local info = vgui.Create("DPanel", right)
    info:Dock(TOP)
    info:SetTall(92)
    info:DockMargin(0, 0, 0, 6)
    info.Paint = function(s, w, h)
        ShipTech.Box(0, 0, w, h, T.panel)
        local sys = ShipTech.Sys(sel)
        local def = ShipTech.SystemById[sel]
        if not sys then return end
        local st = ShipTech.Stages[ShipTech.StageOf(sys.health)]
        draw.SimpleText(def.name, "ShipTech_UIMed", 12, 8, T.text)
        draw.SimpleText(st.name .. "  ·  Zustand " .. math.Round(sys.health) .. " %  ·  Wartung " .. math.Round(sys.maint) .. " %  ·  Temp. " .. math.Round(sys.heat) .. " %" .. (sys.calib and ("  ·  Kalibr. " .. math.Round(sys.calib) .. " %") or ""), "ShipTech_UI", 12, 44, st.col)
        local fl = {}
        for _, ft in ipairs(sys.faults or {}) do fl[#fl + 1] = (ShipTech.FaultTypes[ft.t] and ShipTech.FaultTypes[ft.t].name or ft.t) .. (ft.k and "" or " (?)") end
        draw.SimpleText("Störungen: " .. (#fl > 0 and table.concat(fl, ", ") or "keine") .. (sys.wf and ("   ·   " .. ShipTech.WorkflowNames[sys.wf]) or ""), "ShipTech_UISmall", 12, 70, T.dim)
    end

    -- Auftrag-Optionen
    Section(right, "WARTUNGSAUFTRAG ZUM SCHADEN ERSTELLEN")
    local orderRow = Row(right, 30)
    local orderChk = vgui.Create("DCheckBoxLabel", orderRow)
    orderChk:Dock(LEFT)
    orderChk:SetWide(260)
    orderChk:SetText("Auftrag für die Techniker erstellen")
    orderChk:SetTextColor(T.text)
    orderChk:SetValue(true)
    local prioBox = Combo(orderRow, { { "Priorität: Hoch", 3 }, { "Priorität: Mittel", 2 }, { "Priorität: Niedrig", 1 } })
    prioBox:Dock(RIGHT)
    prioBox:SetWide(200)
    local orderTitle = UI.TextEntry(right, "Auftragstitel (leer = automatisch)")
    orderTitle:Dock(TOP)
    orderTitle:DockMargin(0, 0, 0, 6)
    local orderDesc = UI.TextEntry(right, "Beschreibung für die Techniker (optional)", true, 56)
    orderDesc:Dock(TOP)
    orderDesc:DockMargin(0, 0, 0, 6)

    local function sysArgs(extra)
        local a = extra or {}
        a.sys = sel
        a.order = orderChk:GetChecked()
        a.orderTitle = orderTitle:GetValue()
        a.orderDesc = orderDesc:GetValue()
        a.prio = ComboValue(prioBox)
        return a
    end

    Section(right, "SCHADENSSTUFE SETZEN")
    ButtonRow(right, {
        { "Betriebsbereit", T.green,  function() Send("stage", sysArgs({ stage = 0 })) end },
        { "Beschädigt",     T.yellow, function() Send("stage", sysArgs({ stage = 1 })) end },
        { "Kritisch",       T.orange, function() Send("stage", sysArgs({ stage = 2 })) end },
        { "Ausgefallen",    T.red,    function() Send("stage", sysArgs({ stage = 3 })) end },
    }, 40)

    Section(right, "STÖRUNG HINZUFÜGEN")
    local fRow = Row(right, 34)
    local faults = { { "Zufällige Störung (passend zum System)", "" } }
    for id, ft in SortedPairs(ShipTech.FaultTypes) do faults[#faults + 1] = { ft.name, id } end
    local faultBox = Combo(fRow, faults, 34)
    faultBox:Dock(FILL)
    local fBtn = UI.Button(fRow, "Störung auslösen", T.orange, function()
        local v = ComboValue(faultBox)
        Send("fault", sysArgs({ fault = (v ~= "" and v) or nil }))
    end)
    fBtn:Dock(RIGHT)
    fBtn:SetWide(200)
    fBtn:DockMargin(6, 0, 0, 0)

    Section(right, "WEITERE AKTIONEN")
    ButtonRow(right, {
        { "System abschalten", T.orange, function() Send("shutdown", sysArgs()) end },
        { "Überhitzen (Sicherheitsabschaltung)", T.red, function() Send("overheat", sysArgs()) end },
        { "Kalibrierung verlieren", T.yellow, function() Send("calib", sysArgs()) end },
    })
    local maintSlider = Slider(right, "Wartungszustand (%)", 0, 100, 30)
    ButtonRow(right, {
        { "Wartungszustand setzen", T.accent, function() Send("maint", { sys = sel, value = maintSlider:GetValue() }) end },
        { "Sofort reparieren", T.green, function() Send("repair", { sys = sel }) end },
    })

    -----------------------------------------------------------------------
    -- Schilde & Beschuss
    -----------------------------------------------------------------------
    local pSh = vgui.Create("DPanel", content)
    pSh.Paint = function() end
    pSh:DockPadding(8, 8, 8, 8)
    sheet:AddSheet("Schilde & Beschuss", pSh)

    local gfx = vgui.Create("DPanel", pSh)
    gfx:Dock(LEFT)
    gfx:SetWide(420)
    gfx:DockMargin(0, 0, 10, 0)
    gfx.Paint = function(s, w, h)
        ShipTech.Box(0, 0, w, h, T.panel)
        ShipTech.DrawShieldGraphic(w / 2, h / 2 - 20, math.min(w, h) * 0.36, { bigFont = "ShipTech_UIBig", smallFont = "ShipTech_UIBold" })
    end

    local shR = UI.Scroll(pSh)
    shR:Dock(FILL)
    Section(shR, "SCHILDWERTE SETZEN")
    local secs = (ShipTech.State and ShipTech.State.shields.sectors) or { 100, 100, 100, 100 }
    local sl = {}
    for i, name in ipairs(ShipTech.SectorNames) do
        sl[i] = Slider(shR, name, 0, 100, secs[i] or 0)
    end
    ButtonRow(shR, {
        { "Werte übernehmen", T.accent, function()
            Send("shields_set", { sectors = { sl[1]:GetValue(), sl[2]:GetValue(), sl[3]:GetValue(), sl[4]:GetValue() } })
        end },
        { "Alle auf 100 %", T.green, function() Send("shields_set", { sectors = { 100, 100, 100, 100 } }) end },
    })
    ButtonRow(shR, {
        { "Schilde deaktivieren", T.red, function() Send("shields_off") end },
        { "Schilde schwächen (-50 %)", T.orange, function() Send("shields_weaken", { order = orderChk:GetChecked(), prio = ComboValue(prioBox) }) end },
    })

    Section(shR, "BESCHUSS SIMULIEREN")
    local hitSector = Combo(shR, { { "Zufälliger Sektor", 0 }, { "Bug", 1 }, { "Steuerbord", 2 }, { "Heck", 3 }, { "Backbord", 4 } }, 32)
    hitSector:Dock(TOP)
    hitSector:DockMargin(0, 0, 0, 6)
    local hitAmount = Slider(shR, "Trefferstärke", 5, 120, 25)
    UI.Note(shR, "Treffer werden von den Schilden absorbiert. Ist ein Sektor leer, trifft der Rest die Hülle und beschädigt zufällige Systeme.", T.dim)
    ButtonRow(shR, {
        { "Einzeltreffer", T.orange, function() Send("hit", { sector = ComboValue(hitSector), amount = hitAmount:GetValue(), count = 1 }) end },
        { "Salve (5 Treffer)", T.red, function() Send("hit", { sector = ComboValue(hitSector), amount = hitAmount:GetValue(), count = 5 }) end },
    }, 40)

    -----------------------------------------------------------------------
    -- Störungen & Notfälle
    -----------------------------------------------------------------------
    local pEm = UI.Scroll(content)
    sheet:AddSheet("Störungen & Notfälle", pEm)
    local function emArgs() return { order = orderChk:GetChecked(), prio = ComboValue(prioBox) } end
    UI.Note(pEm, "Die Einstellung 'Auftrag erstellen' aus dem Reiter Systeme gilt auch hier.", T.dim)

    Section(pEm, "TECHNISCHE STÖRUNGEN")
    ButtonRow(pEm, {
        { "Kommunikationsausfall", T.red, function() Send("comms", emArgs()) end },
        { "Kühlmittelproblem", T.orange, function() Send("coolant", emArgs()) end },
        { "Energieüberlastung", T.orange, function() Send("overload", emArgs()) end },
    }, 40)
    ButtonRow(pEm, {
        { "Zufällige technische Störung", T.yellow, function() Send("random", emArgs()) end },
        { "REAKTORNOTFALL", T.red, function() Send("reactor_emergency", emArgs()) end },
    }, 40)
    Section(pEm, "BRAND & HYPERRAUM")
    ButtonRow(pEm, {
        { "Brand am gewählten System", T.red, function() Send("fire", { sys = sel }) end },
        { "Brand an zufälligem System", T.orange, function() Send("fire", { sys = "*" }) end },
        { "Alle Brände löschen", T.green, function() Send("extinguish_all") end },
    }, 40)
    local circChoices = { { "Zufälliger Kühlkreislauf", "" } }
    for _, c in ipairs(ShipTech.Circuits) do circChoices[#circChoices + 1] = { c.name, c.id } end
    local circRow = Row(pEm, 34)
    local circBox = Combo(circRow, circChoices, 34)
    circBox:Dock(FILL)
    local leakBtn = UI.Button(circRow, "Kühlmittelleck auslösen", T.orange, function()
        local v = ComboValue(circBox)
        Send("coolant_leak", { circuit = (v ~= "" and v) or nil })
    end)
    leakBtn:Dock(RIGHT)
    leakBtn:SetWide(240)
    leakBtn:DockMargin(6, 0, 0, 0)
    local fillBtn = UI.Button(circRow, "Alle auffüllen", T.green, function() Send("coolant_fill") end)
    fillBtn:Dock(RIGHT)
    fillBtn:SetWide(150)
    fillBtn:DockMargin(6, 0, 0, 0)    ButtonRow(pEm, {
        { "Nächsten Hyperraumsprung sabotieren", T.orange, function() Send("hyper_fail") end },
        { "Hyperraum sofort verlassen", T.accent, function() Send("hyper_exit") end },
    })

    Section(pEm, "STROMAUSFALL IN SEKTOREN")
    local secRow = Row(pEm, 34)
    local secBox = UI.StyleCombo(vgui.Create("DComboBox", secRow))
    secBox:Dock(FILL)
    secBox:SetTall(34)
    for _, n in ipairs((ShipTech.State and ShipTech.State.sectorList) or {}) do secBox:AddChoice(n, n) end
    if #((ShipTech.State and ShipTech.State.sectorList) or {}) == 0 then
        secBox:SetValue("Keine Sektor-Energieverteiler platziert")
    end
    local function selSector()
        local _, v = secBox:GetSelected()
        return v
    end
    ButtonRow(pEm, {
        { "Stromausfall auslösen", T.red, function() local v = selSector() if v then Send("outage", { sector = v }) end end },
        { "Sektor wiederherstellen", T.green, function() local v = selSector() if v then Send("restore", { sector = v }) end end },
        { "Alle Sektoren wiederherstellen", T.accent, function() Send("restore_all") end },
    })

    Section(pEm, "ALARME & NOTFALLPROTOKOLLE")
    local alarms = {}
    for id, def in SortedPairsByMemberValue(ShipTech.AlarmTypes, "prio") do alarms[#alarms + 1] = { def.name, id } end
    local alRow = Row(pEm, 34)
    local alBox = Combo(alRow, alarms, 34)
    alBox:Dock(LEFT)
    alBox:SetWide(320)
    local alInfo = UI.TextEntry(alRow, "Bereich / Zusatzinfo (z. B. Deck 3, Maschinenraum)")
    alInfo:Dock(FILL)
    alInfo:DockMargin(6, 0, 0, 0)
    ButtonRow(pEm, {
        { "Alarm auslösen", T.red, function() Send("alarm", { id = ComboValue(alBox), info = alInfo:GetValue() }) end },
        { "Alarm aufheben", T.green, function() Send("alarm_clear", { id = ComboValue(alBox) }) end },
        { "Alle Alarme aufheben", T.accent, function() Send("alarm_clear_all") end },
    })
    ButtonRow(pEm, {
        { "Gefechtsalarm AN", T.red, function() Send("combat", { on = true }) end },
        { "Gefechtsalarm AUS", T.green, function() Send("combat", { on = false }) end },
    })

    Section(pEm, "ERSATZTEILE")
    local partsSlider = Slider(pEm, "Ersatzteile an Bord", 0, 50, (ShipTech.State and ShipTech.State.parts) or 10)
    ButtonRow(pEm, {
        { "Bestand setzen", T.accent, function() Send("parts", { value = partsSlider:GetValue() }) end },
        { "Ersatzteilmangel (0)", T.red, function() Send("parts", { value = 0 }) end },
    })

    -----------------------------------------------------------------------
    -- Aufträge
    -----------------------------------------------------------------------
    local pOr = UI.Scroll(content)
    sheet:AddSheet("Aufträge", pOr)
    Section(pOr, "NEUEN AUFTRAG / TECHNISCHE SITUATION ERSTELLEN")
    local oSys = { { "– Allgemein –", "" } }
    for _, def in ipairs(ShipTech.Systems) do oSys[#oSys + 1] = { def.name, def.id } end
    local oSysBox = Combo(pOr, oSys, 32)
    oSysBox:Dock(TOP)
    oSysBox:DockMargin(0, 0, 0, 6)
    local oTitle = UI.TextEntry(pOr, "Titel, z. B. 'Ungewöhnliche Vibrationen im Maschinenraum'")
    oTitle:Dock(TOP)
    oTitle:DockMargin(0, 0, 0, 6)
    local oDesc = UI.TextEntry(pOr, "Beschreibung / Situation für die Crew", true, 100)
    oDesc:Dock(TOP)
    oDesc:DockMargin(0, 0, 0, 6)
    local oPrio = Combo(pOr, { { "Priorität: Hoch", 3 }, { "Priorität: Mittel", 2 }, { "Priorität: Niedrig", 1 } }, 32)
    oPrio:Dock(TOP)
    oPrio:DockMargin(0, 0, 0, 6)
    ButtonRow(pOr, {
        { "AUFTRAG ERSTELLEN", T.green, function()
            local s = ComboValue(oSysBox)
            Send("order", { sys = (s ~= "" and s) or nil, title = oTitle:GetValue(), desc = oDesc:GetValue(), prio = ComboValue(oPrio) })
            oTitle:SetValue("")
            oDesc:SetValue("")
        end },
    }, 42)

    Section(pOr, "OFFENE AUFTRÄGE")
    local oList = vgui.Create("DPanel", pOr)
    oList:Dock(TOP)
    oList:SetTall(10)
    oList.Paint = function() end
    local function fillOrders()
        oList:Clear()
        local n = 0
        for _, o in ipairs((ShipTech.State and ShipTech.State.orders) or {}) do
            if o.status == "open" or o.status == "accepted" then
                n = n + 1
                local r = vgui.Create("DPanel", oList)
                r:Dock(TOP)
                r:SetTall(40)
                r:DockMargin(0, 0, 0, 4)
                r.Paint = function(s, w, h)
                    ShipTech.Box(0, 0, w, h, T.panel)
                    draw.SimpleText("#" .. o.id .. "  " .. o.title .. "  ·  " .. (o.status == "accepted" and ("angenommen von " .. (o.assignee or "?")) or "offen"), "ShipTech_UIBold", 10, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                local b = UI.Button(r, "Stornieren", T.red, function() Send("order_cancel", { id = o.id }) end)
                b:Dock(RIGHT)
                b:SetWide(140)
                b:DockMargin(0, 4, 4, 4)
            end
        end
        oList:SetTall(math.max(10, n * 44))
    end
    fillOrders()
    local lastOrders = util.TableToJSON((ShipTech.State and ShipTech.State.orders) or {})
    hook.Add("ShipTech_StateUpdated", oList, function(self)
        local j = util.TableToJSON((ShipTech.State and ShipTech.State.orders) or {})
        if j ~= lastOrders then
            lastOrders = j
            fillOrders()
        end
    end)

    -----------------------------------------------------------------------
    -- Global
    -----------------------------------------------------------------------
    -----------------------------------------------------------------------
    -- Szenarien & zeitgesteuerte Abläufe
    -----------------------------------------------------------------------
    local pSeq = vgui.Create("DPanel", content)
    pSeq.Paint = function() end
    sheet:AddSheet("Abläufe", pSeq)

    local seqLeft = UI.Scroll(pSeq)
    seqLeft:Dock(LEFT)
    seqLeft:SetWide(420)
    seqLeft:DockMargin(0, 0, 14, 0)

    Section(seqLeft, "SZENARIO-VORLAGEN")
    for i, sc in ipairs(ShipTech.Scenarios) do
        local r = vgui.Create("DPanel", seqLeft)
        r:Dock(TOP)
        r:SetTall(64)
        r:DockMargin(0, 0, 6, 4)
        local last = 0
        for _, st in ipairs(sc.steps) do last = math.max(last, st[1]) end
        r.Paint = function(s, w, h)
            ShipTech.Box(0, 0, w, h, T.panel)
            surface.SetDrawColor(T.accent)
            surface.DrawRect(0, 0, 2, h)
            draw.SimpleText(string.upper(sc.name), "ShipTech_UIBold", 12, 16, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(#sc.steps .. " Schritte · " .. string.FormattedTime(last, "%02i:%02i") .. " min", "ShipTech_UISub", 12, 34, T.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(sc.desc, "ShipTech_UISub", 12, 50, T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local b = UI.Button(r, "START", T.red, function()
            Derma_Query("Szenario '" .. sc.name .. "' starten?", "Szenario", "Starten", function() Send("scenario", { index = i }) end, "Abbrechen")
        end)
        b:Dock(RIGHT)
        b:SetWide(80)
        b:DockMargin(0, 14, 10, 14)
        b:SetTooltip(sc.desc)
    end

    Section(seqLeft, "LAUFENDE ABLÄUFE")
    local running = vgui.Create("DPanel", seqLeft)
    running:Dock(TOP)
    running:SetTall(10)
    running.Paint = function() end
    local function fillRunning()
        running:Clear()
        local list = (ShipTech.State and ShipTech.State.sequences) or {}
        for _, q in ipairs(list) do
            local r = vgui.Create("DPanel", running)
            r:Dock(TOP)
            r:SetTall(46)
            r:DockMargin(0, 0, 6, 4)
            r.Paint = function(s, w, h)
                ShipTech.Box(0, 0, w, h, T.panel)
                draw.SimpleText(string.upper(q.name), "ShipTech_UIBold", 12, 14, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                local left = math.max(0, math.ceil((q.ends or 0) - CurTime()))
                draw.SimpleText(q.done .. "/" .. q.total .. " Schritte · noch " .. string.FormattedTime(left, "%02i:%02i") .. " · von " .. (q.by or "?"), "ShipTech_UISub", 12, 32, T.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            local b = UI.Button(r, "STOPP", T.red, function() Send("sequence_cancel", { id = q.id }) end)
            b.Solid = false
            b:Dock(RIGHT)
            b:SetWide(76)
            b:DockMargin(0, 8, 8, 8)
        end
        if #list == 0 then
            local l = UI.Note(running, "Keine laufenden Abläufe.", T.muted)
        end
        running:SetTall(math.max(26, #list * 50))
    end
    fillRunning()
    local lastSeq = ""
    hook.Add("ShipTech_StateUpdated", running, function()
        local j = util.TableToJSON((ShipTech.State and ShipTech.State.sequences) or {})
        if j ~= lastSeq then
            lastSeq = j
            fillRunning()
        end
    end)

    -- Ablauf-Editor
    local seqRight = UI.Scroll(pSeq)
    seqRight:Dock(FILL)
    Section(seqRight, "EIGENEN ABLAUF ERSTELLEN")
    UI.Note(seqRight, "Schritte mit Zeitpunkt (Minuten:Sekunden ab Start) hinzufügen, z. B. 2:00 Kühlmittelproblem, 5:00 Reaktornotfall.", T.muted)

    local seqName = UI.TextEntry(seqRight, "Name des Ablaufs (z. B. Angriff auf Deck 4)")
    seqName:Dock(TOP)
    seqName:DockMargin(0, 0, 0, 6)

    local addRow = Row(seqRight, 34)
    local timeEntry = UI.TextEntry(addRow, "0:00")
    timeEntry:Dock(LEFT)
    timeEntry:SetWide(80)
    local actChoices = {}
    for _, sa in ipairs(ShipTech.SequenceActions) do actChoices[#actChoices + 1] = { sa.name, sa.id } end
    local actBox = Combo(addRow, actChoices, 34)
    actBox:Dock(FILL)
    actBox:DockMargin(6, 0, 0, 0)

    local addRow2 = Row(seqRight, 34)
    local sysChoices = { { "– System (falls nötig) –", "" } }
    for _, def in ipairs(ShipTech.Systems) do sysChoices[#sysChoices + 1] = { def.name, def.id } end
    local sysBox = Combo(addRow2, sysChoices, 34)
    sysBox:Dock(FILL)
    local stageBox = Combo(addRow2, { { "Beschädigt", 1 }, { "Kritisch", 2 }, { "Ausgefallen", 3 } }, 34)
    stageBox:Dock(RIGHT)
    stageBox:SetWide(150)
    stageBox:DockMargin(6, 0, 0, 0)

    local steps = {}
    local stepList = vgui.Create("DPanel", seqRight)
    stepList:Dock(TOP)
    stepList:SetTall(10)
    stepList.Paint = function() end

    local actName = {}
    for _, sa in ipairs(ShipTech.SequenceActions) do actName[sa.id] = sa end

    local function fillSteps()
        stepList:Clear()
        table.sort(steps, function(a, b) return a.delay < b.delay end)
        for i, st in ipairs(steps) do
            local r = vgui.Create("DPanel", stepList)
            r:Dock(TOP)
            r:SetTall(36)
            r:DockMargin(0, 0, 6, 3)
            local sa = actName[st.action]
            local txt = string.FormattedTime(st.delay, "%02i:%02i") .. "   " .. (sa and sa.name or st.action)
            if st.sys and ShipTech.SystemById[st.sys] then txt = txt .. " – " .. ShipTech.SystemById[st.sys].name end
            if st.action == "stage" and st.stage then txt = txt .. " (" .. ShipTech.Stages[st.stage].name .. ")" end
            r.Paint = function(s, w, h)
                ShipTech.Box(0, 0, w, h, T.panel)
                surface.SetDrawColor(T.accent)
                surface.DrawRect(0, 0, 2, h)
                draw.SimpleText(txt, "ShipTech_UI", 12, h / 2, T.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            local del = UI.Button(r, "X", T.red, function()
                table.remove(steps, i)
                fillSteps()
            end)
            del:Dock(RIGHT)
            del:SetWide(34)
            del:DockMargin(0, 3, 3, 3)
        end
        stepList:SetTall(math.max(10, #steps * 39))
    end

    local function parseTime(t)
        local m, sec = string.match(t or "", "^(%d+):(%d+)$")
        if m then return tonumber(m) * 60 + tonumber(sec) end
        return tonumber(t) or 0
    end

    ButtonRow(seqRight, {
        { "+ SCHRITT HINZUFÜGEN", T.accent, function()
            local act = ComboValue(actBox)
            local sa = actName[act]
            if not sa then return end
            local sys = ComboValue(sysBox)
            if sa.sys and (sys == nil or sys == "") then
                notification.AddLegacy("Für diese Aktion bitte ein System wählen.", NOTIFY_ERROR, 4)
                return
            end
            if #steps >= 30 then return end
            steps[#steps + 1] = {
                delay = math.Clamp(parseTime(timeEntry:GetValue()), 0, 3600),
                action = act,
                sys = sa.sys and sys or nil,
                stage = sa.stage and ComboValue(stageBox) or nil,
            }
            fillSteps()
        end },
    })

    Section(seqRight, "ABLAUF")
    fillSteps()
    ButtonRow(seqRight, {
        { "ABLAUF STARTEN", T.red, function()
            if #steps == 0 then return end
            Send("sequence_run", { name = seqName:GetValue(), steps = steps })
        end },
        { "Leeren", T.dim, function()
            steps = {}
            fillSteps()
        end },
    }, 42)

    local pGl = UI.Scroll(content)
    sheet:AddSheet("Global", pGl)
    Section(pGl, "SCHIFF")
    ButtonRow(pGl, {
        { "Reaktor sofort ONLINE", T.green, function() Send("reactor", { on = true }) end },
        { "Reaktor sofort OFFLINE", T.red, function() Send("reactor", { on = false }) end },
    }, 40)
    ButtonRow(pGl, {
        { "Alle Systeme hochfahren (inkl. Navy-Freigaben)", T.green, function() Send("boot_all") end },
    }, 40)
    ButtonRow(pGl, {
        { "Alle Navy-Freigaben erteilen", T.accent, function() Send("navy_all", { on = true }) end },
        { "Alle Navy-Freigaben entziehen", T.orange, function() Send("navy_all", { on = false }) end },
    })
    Section(pGl, "SIMULATION")
    ButtonRow(pGl, {
        { "Zufallsstörungen AN", T.accent, function() Send("randomfaults", { on = true }) end },
        { "Zufallsstörungen AUS", T.orange, function() Send("randomfaults", { on = false }) end },
    })
    Section(pGl, "WIEDERHERSTELLEN")
    ButtonRow(pGl, {
        { "Alle Systeme reparieren", T.green, function() Send("repair_all") end },
        { "KOMPLETT ZURÜCKSETZEN", T.red, function()
            Derma_Query("Den gesamten Schiffszustand zurücksetzen? (Reaktor aus, alle Aufträge gelöscht)", "Zurücksetzen", "Ja", function() Send("reset") end, "Abbrechen")
        end },
    }, 40)
    pGl:InvalidateLayout(true)
    if LocalPlayer():IsSuperAdmin() then
        Section(pGl, "ADMINISTRATION")
        ButtonRow(pGl, {
            { "KONFIGURATION ÖFFNEN", T.accent, function() RunConsoleCommand("shiptech_admin") end },
            { "TECHNIKER-HANDBUCH", T.accent, function() ShipTech.OpenHandbook() end },
        }, 40)
    end    UI.Note(pGl, "Tipp: Die Event-Aktionen werden im Protokoll mit [EVENT] vermerkt. Konsolen speichern: shiptech_save (Konsole, Superadmin).", T.dim)

    -- weitere Addons (z. B. ShipTech EVA) können eigene Reiter ergänzen
    hook.Run("ShipTech_EventMenuTabs", sheet, content, f, Send)
    sheet:Finish()
end

net.Receive("ShipTech_OpenEvent", function()
    ShipTech.OpenEventMenu()
end)
