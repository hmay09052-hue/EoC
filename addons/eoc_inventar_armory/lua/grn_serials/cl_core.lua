local WS = GRNSerials
local C = WS.Config

WS.Frame = WS.Frame or nil
WS.HTMLPanel = WS.HTMLPanel or nil
WS.HTMLReady = false
WS.Pending = nil

local ACCENT = Color(255, 190, 50)
local TEXT = Color(236, 233, 224)
local MUTED = Color(150, 160, 175)
local GOOD = Color(119, 196, 170)
local BAD = Color(224, 122, 106)
local PANEL = Color(8, 11, 15, 215)

surface.CreateFont("WS_Title", { font = "Roboto Condensed", size = ScreenScale(9), weight = 800, extended = true })
surface.CreateFont("WS_Text", { font = "Roboto Condensed", size = ScreenScale(6), weight = 700, extended = true })
surface.CreateFont("WS_Small", { font = "Roboto Condensed", size = ScreenScale(5), weight = 700, extended = true })
surface.CreateFont("WS_3D", { font = "Roboto Condensed", size = 56, weight = 800, extended = true })
surface.CreateFont("WS_3DSub", { font = "Roboto Condensed", size = 24, weight = 600, extended = true })

local function playSound(kind)
    if GRNInventory and isfunction(GRNInventory.PlayUISound) then GRNInventory.PlayUISound(kind) end
end

-- ---------------------------------------------------------
-- Oberfläche
-- ---------------------------------------------------------
function WS.Request(action, data)
    net.Start("ws_req")
        net.WriteString(action)
        net.WriteString(util.TableToJSON(data or {}, false) or "{}")
    net.SendToServer()
end

local function push(data)
    if not IsValid(WS.HTMLPanel) or not WS.HTMLReady then
        WS.Pending = data
        return
    end
    local json = util.TableToJSON(data, false) or "{}"
    WS.HTMLPanel:QueueJavascript("if(window.UI)UI.setData(" .. json .. ");")
end

function WS.CloseUI()
    if IsValid(WS.Frame) then
        WS.Frame:Remove()
        playSound("Close")
    end
    WS.Frame, WS.HTMLPanel, WS.HTMLReady, WS.Pending = nil, nil, false, nil
end

function WS.OpenUI(data)
    if IsValid(WS.Frame) then
        push(data)
        return
    end
    if GRNArcCW and IsValid(GRNArcCW.Frame) then GRNArcCW.CloseMenu(false) end

    local frame = vgui.Create("EditablePanel")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(true)

    local html = vgui.Create("DHTML", frame)
    html:Dock(FILL)
    html:SetAllowLua(false)
    html:AddFunction("grnWS", "ready", function()
        WS.HTMLReady = true
        if WS.Pending then
            local p = WS.Pending
            WS.Pending = nil
            push(p)
        end
    end)
    html:AddFunction("grnWS", "close", function() WS.CloseUI() end)
    html:AddFunction("grnWS", "uiSound", function(kind) playSound(kind) end)
    html:AddFunction("grnWS", "request", function(action, json)
        net.Start("ws_req")
            net.WriteString(tostring(action or ""))
            net.WriteString(tostring(json or "{}"))
        net.SendToServer()
    end)
    html.OnDocumentReady = function()
        timer.Simple(0.05, function()
            if not IsValid(html) then return end
            WS.HTMLReady = true
            if WS.Pending then
                local p = WS.Pending
                WS.Pending = nil
                push(p)
            end
        end)
    end
    html:SetHTML(WS.HTML)

    WS.Frame, WS.HTMLPanel, WS.HTMLReady, WS.Pending = frame, html, false, data
    playSound("Open")
end

net.Receive("ws_data", function()
    local len = net.ReadUInt(32)
    local raw = len > 0 and net.ReadData(len) or ""
    local json = util.Decompress(raw) or "{}"
    local data = util.JSONToTable(json)
    if istable(data) then WS.OpenUI(data) end
end)

-- ---------------------------------------------------------
-- HUD-Hinweise, Ankündigungen, Killfeed
-- ---------------------------------------------------------
local notices, banners, feed = {}, {}, {}
local cleaning = nil

local function addNotice(kind, text)
    table.insert(notices, 1, { kind = kind, text = text, t = CurTime() })
    while #notices > 4 do table.remove(notices) end
end

net.Receive("ws_msg", function()
    local ok, text = net.ReadBool(), net.ReadString()
    if IsValid(WS.HTMLPanel) and WS.HTMLReady then
        WS.HTMLPanel:QueueJavascript("if(window.UI)UI.toast(" .. (ok and "true" or "false") .. "," .. util.TableToJSON({ text }):sub(2, -2) .. ");")
    else
        addNotice(ok and "ok" or "warn", text)
    end
end)

net.Receive("ws_hud", function()
    local kind, text = net.ReadString(), net.ReadString()
    addNotice(kind, text)
    if kind == "milestone" then surface.PlaySound("buttons/bell1.wav") end
end)

net.Receive("ws_announce", function()
    local kind, text = net.ReadString(), net.ReadString()
    table.insert(banners, { kind = kind, text = text, t = CurTime() })
    chat.AddText(ACCENT, "[Waffenkammer] ", TEXT, text)
    if kind == "tradition" then surface.PlaySound("ambient/alarms/warningbell1.wav") end
end)

net.Receive("ws_killfeed", function()
    local attacker, victim, name, tradition = net.ReadString(), net.ReadString(), net.ReadString(), net.ReadBool()
    table.insert(feed, 1, { a = attacker, v = victim, n = name, trad = tradition, t = CurTime() })
    while #feed > 5 do table.remove(feed) end
end)

net.Receive("ws_jam", function()
    local wep = net.ReadEntity()
    if IsValid(wep) and wep.SetMalfunctionJam then wep:SetMalfunctionJam(true) end
    local key = input.LookupBinding("+reload") or "R"
    addNotice("jam", "Ladehemmung! [" .. string.upper(key) .. "] zum Beheben")
    surface.PlaySound("weapons/pistol/pistol_empty.wav")
end)

net.Receive("ws_clean", function()
    local dur = net.ReadFloat()
    cleaning = dur > 0 and { start = CurTime(), dur = dur } or nil
end)

local KIND_COLOR = { ok = GOOD, warn = ACCENT, critical = BAD, jam = BAD, milestone = ACCENT, info = TEXT }

hook.Add("HUDPaint", "GRNSerials_HUD", function()
    if not C.ShowHUD then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local sw, sh = ScrW(), ScrH()
    local now = CurTime()

    -- Hinweise (oben Mitte)
    local y = sh * 0.16
    for i = #notices, 1, -1 do
        local n = notices[i]
        local age = now - n.t
        if age > 4 then table.remove(notices, i) end
    end
    for _, n in ipairs(notices) do
        local a = math.Clamp(4 - (now - n.t), 0, 1)
        surface.SetFont("WS_Text")
        local tw, th = surface.GetTextSize(n.text)
        local w, h = tw + 36, th + 14
        local x = sw / 2 - w / 2
        surface.SetDrawColor(PANEL.r, PANEL.g, PANEL.b, PANEL.a * a)
        surface.DrawRect(x, y, w, h)
        local col = KIND_COLOR[n.kind] or TEXT
        surface.SetDrawColor(col.r, col.g, col.b, 255 * a)
        surface.DrawRect(x, y, 3, h)
        draw.SimpleText(n.text, "WS_Text", sw / 2 + 2, y + h / 2, Color(TEXT.r, TEXT.g, TEXT.b, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + h + 6
    end

    -- Meilenstein-/Traditions-Einblendung (Mitte oben)
    local b = banners[1]
    if b then
        local age = now - b.t
        if age > 7 then
            table.remove(banners, 1)
        else
            local a = math.Clamp(math.min(age * 3, 7 - age), 0, 1)
            surface.SetFont("WS_Title")
            local tw, th = surface.GetTextSize(b.text)
            local w, h = math.min(sw * 0.8, tw + 60), th + 34
            local x, by = sw / 2 - w / 2, sh * 0.07
            surface.SetDrawColor(PANEL.r, PANEL.g, PANEL.b, PANEL.a * a)
            surface.DrawRect(x, by, w, h)
            surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 255 * a)
            surface.DrawRect(x, by + h - 2, w, 2)
            draw.SimpleText(b.kind == "tradition" and "REGIMENTSCHRONIK" or "MEILENSTEIN", "WS_Small", sw / 2, by + 9, Color(ACCENT.r, ACCENT.g, ACCENT.b, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText(b.text, "WS_Title", sw / 2, by + h - 8, Color(TEXT.r, TEXT.g, TEXT.b, 255 * a), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    end

    -- Killfeed mit Waffennamen (rechts oben, unter dem normalen Killfeed)
    local fy = sh * 0.2
    for i = #feed, 1, -1 do if now - feed[i].t > 8 then table.remove(feed, i) end end
    for _, f in ipairs(feed) do
        local text = f.a .. "  ›  " .. f.v
        local tag = (f.trad and "★ " or "") .. "„" .. f.n .. "“"
        surface.SetFont("WS_Small")
        local w1 = surface.GetTextSize(text)
        local w2 = surface.GetTextSize(tag)
        local w = w1 + w2 + 34
        local x = sw - w - 24
        surface.SetDrawColor(PANEL)
        surface.DrawRect(x, fy, w, 22)
        draw.SimpleText(text, "WS_Small", x + 10, fy + 11, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(tag, "WS_Small", x + 20 + w1, fy + 11, f.trad and ACCENT or GOOD, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        fy = fy + 26
    end

    -- Reinigungsbalken
    if cleaning then
        local p = math.Clamp((now - cleaning.start) / cleaning.dur, 0, 1)
        if p >= 1 then cleaning = nil end
        local w, h = sw * 0.18, 8
        local x, cy = sw / 2 - w / 2, sh * 0.62
        draw.SimpleText("WAFFE WIRD GEREINIGT", "WS_Small", sw / 2, cy - 6, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        surface.SetDrawColor(PANEL)
        surface.DrawRect(x, cy, w, h)
        surface.SetDrawColor(ACCENT)
        surface.DrawRect(x, cy, w * p, h)
    end

    -- Zustand der eigenen Waffe (unten rechts, über der Munition)
    local wep = ply:GetActiveWeapon()
    local serial = IsValid(wep) and wep:GetNW2String("ws_serial", "") or ""
    if serial ~= "" and ply:Alive() and not IsValid(WS.Frame) then
        local cond = wep:GetNW2Float("ws_cond", 100)
        local dirt = wep:GetNW2Float("ws_dirt", 0)
        local name = wep:GetNW2String("ws_name", "")
        local w = sw * 0.12
        local x, by = sw - w - sw * 0.02, sh * 0.80
        draw.SimpleText(serial .. (name ~= "" and ("  „" .. name .. "“") or ""), "WS_Small", x + w, by - 4, wep:GetNW2Bool("ws_tradition") and ACCENT or MUTED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        local cc = cond >= 80 and GOOD or (cond >= 25 and ACCENT or BAD)
        surface.SetDrawColor(255, 255, 255, 20) surface.DrawRect(x, by, w, 3)
        surface.SetDrawColor(cc) surface.DrawRect(x, by, w * math.Clamp(cond / 100, 0, 1), 3)
        local dc = dirt < 30 and GOOD or (dirt < 60 and ACCENT or BAD)
        surface.SetDrawColor(255, 255, 255, 20) surface.DrawRect(x, by + 6, w, 2)
        surface.SetDrawColor(dc) surface.DrawRect(x, by + 6, w * math.Clamp(dirt / 100, 0, 1), 2)
        if cond < 25 then
            draw.SimpleText(cond <= 0 and "BLOCKIERT – WERKBANK" or "KRITISCHER ZUSTAND", "WS_Small", x + w, by + 12, BAD, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
    end
end)

-- ---------------------------------------------------------
-- Waffenpass: Taste gedrückt halten, Konsole, Chat
-- ---------------------------------------------------------
concommand.Add(C.PassCommand or "ws_waffenpass", function() WS.Request("pass", {}) end)

local holdStart, fired = nil, false
hook.Add("Think", "GRNSerials_PassKey", function()
    local key = C.PassKey
    if not key or key == 0 then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:IsTyping() or gui.IsGameUIVisible() or vgui.GetKeyboardFocus() or IsValid(WS.Frame) then
        holdStart, fired = nil, false
        return
    end
    if input.IsKeyDown(key) then
        holdStart = holdStart or RealTime()
        if not fired and RealTime() - holdStart >= (C.PassHoldTime or 0.5) then
            fired = true
            local wep = ply:GetActiveWeapon()
            local tr = ply:GetEyeTrace()
            if (IsValid(wep) and wep:GetNW2String("ws_serial", "") ~= "") or (IsValid(tr.Entity) and tr.Entity:GetNW2String("ws_serial", "") ~= "") then
                WS.Request("pass", {})
            end
        end
    else
        holdStart, fired = nil, false
    end
end)

-- Seriennummer und Zustand auch in der Aufsatz-Werkbank (ArcCW-Menü) zeigen.
hook.Add("GRNArcCW_DecorateWeapon", "GRNSerials_Decorate", function(wep, data)
    local serial = wep:GetNW2String("ws_serial", "")
    if serial == "" then return end
    local name = wep:GetNW2String("ws_name", "")
    data.serial = "SN · " .. serial .. (name ~= "" and ("  ·  „" .. name .. "“") or "")
    data.wear = {
        { label = "ZUSTAND", value = wep:GetNW2Float("ws_cond", 100) },
        { label = "SAUBERKEIT", value = 100 - wep:GetNW2Float("ws_dirt", 0), color = "#ffbe32" },
    }
end)
