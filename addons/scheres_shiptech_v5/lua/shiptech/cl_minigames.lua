--[[
    ShipTech – Minigames
    wires     Leitungen verbinden       (Kurzschluss, Kommunikation, Sicherungen)
    frequency Frequenzabgleich          (Kalibrierung, Schilde, Sensoren)
    valves    Druckregulierung          (Kühlmittel, Reaktor, Triebwerke)
    sequence  Befehlssequenz            (Steuerungsfehler, Hyperantrieb)
    timing    Synchronisation           (Energiekopplung, Mechanik, Geschütze)
    scan      Fehlersuche               (Diagnose)
    testrun   Testlauf                  (nach schweren Schäden)
]]

local C = ShipTech.Config

-- Farben wie im Funksystem
local BG     = Color(6, 8, 11)
local PANEL  = Color(11, 14, 18)
local LINE   = Color(50, 55, 63)
local ACCENT = Color(252, 178, 73)
local TEXT   = Color(236, 233, 224)
local DIM    = Color(157, 163, 173)
local GREEN  = Color(74, 203, 130)
local RED    = Color(225, 88, 88)
local YELLOW = Color(252, 178, 73)

-- flache Box statt abgerundeter Ecken
local function FlatBox(_, x, y, w, h, col)
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, w, h)
end

local Games = {}
ShipTech.Minigames = Games

local function Dot(x, y, r, col) ShipTech.DrawCircleFilled(x, y, r, col) end

local function ThickLine(x1, y1, x2, y2, col, t)
    surface.SetDrawColor(col)
    for o = -t, t do
        surface.DrawLine(x1, y1 + o, x2, y2 + o)
        surface.DrawLine(x1 + o, y1, x2 + o, y2)
    end
end

local function Hint(p, text, w)
    draw.SimpleText(text, "ShipTech_UISmall", w / 2, p:GetTall() - 12, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end

---------------------------------------------------------------------------
-- Leitungen verbinden
---------------------------------------------------------------------------
Games.wires = function(p, diff, finish, fr)
    local n = math.min(3 + diff, 6)
    local cols = { Color(235, 60, 60), Color(60, 140, 255), Color(250, 210, 60), Color(80, 220, 110), Color(220, 90, 230), Color(255, 140, 40) }
    local right = {}
    for i = 1, n do right[i] = i end
    for i = n, 2, -1 do
        local j = math.random(i)
        right[i], right[j] = right[j], right[i]
    end
    local links, sel, errT, done = {}, nil, 0, 0

    local function pos(side, i)
        local w, h = p:GetSize()
        local y = 40 + (i - 0.5) * (h - 100) / n
        return (side == 1) and 110 or (w - 110), y
    end

    p.Paint = function(s, w, h)
        FlatBox(6, 0, 0, w, h, PANEL)
        draw.SimpleText("QUELLE", "ShipTech_UIBold", 110, 18, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("ZIEL", "ShipTech_UIBold", w - 110, 18, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        for i = 1, n do
            if links[i] then
                for j = 1, n do
                    if right[j] == i then
                        local x1, y1 = pos(1, i)
                        local x2, y2 = pos(2, j)
                        ThickLine(x1, y1, x2, y2, cols[i], 2)
                    end
                end
            end
        end
        if sel then
            local x1, y1 = pos(1, sel)
            local mx, my = s:CursorPos()
            ThickLine(x1, y1, mx, my, Color(cols[sel].r, cols[sel].g, cols[sel].b, 160), 1)
        end
        for i = 1, n do
            local x, y = pos(1, i)
            Dot(x, y, 18, (sel == i) and TEXT or LINE)
            Dot(x, y, 14, cols[i])
            surface.SetDrawColor(cols[i])
            surface.DrawRect(20, y - 4, x - 34, 8)
            local x2, y2 = pos(2, i)
            Dot(x2, y2, 18, LINE)
            Dot(x2, y2, 14, cols[right[i]])
            surface.SetDrawColor(cols[right[i]])
            surface.DrawRect(x2 + 14, y2 - 4, w - x2 - 34, 8)
        end
        if RealTime() - errT < 0.4 then
            surface.SetDrawColor(255, 0, 0, 60)
            surface.DrawRect(0, 0, w, h)
        end
        Hint(s, "Klicke eine Quelle und danach den Anschluss mit derselben Farbe. Falsche Verbindung = Zeitstrafe.", w)
    end

    p.OnMousePressed = function(s)
        if fr.Done then return end
        local mx, my = s:CursorPos()
        for i = 1, n do
            local x, y = pos(1, i)
            if not links[i] and (mx - x) ^ 2 + (my - y) ^ 2 < 24 ^ 2 then
                sel = i
                surface.PlaySound("buttons/lightswitch2.wav")
                return
            end
        end
        if sel then
            for j = 1, n do
                local x, y = pos(2, j)
                if (mx - x) ^ 2 + (my - y) ^ 2 < 24 ^ 2 then
                    if right[j] == sel then
                        links[sel] = true
                        done = done + 1
                        surface.PlaySound("buttons/button9.wav")
                        if done >= n then finish(true) end
                    else
                        errT = RealTime()
                        fr:Penalty(3)
                        surface.PlaySound(C.Sounds.Spark)
                    end
                    sel = nil
                    return
                end
            end
            sel = nil
        end
    end
end

---------------------------------------------------------------------------
-- Frequenzabgleich
---------------------------------------------------------------------------
Games.frequency = function(p, diff, finish, fr)
    local names = { "AMPLITUDE", "FREQUENZ", "PHASE" }
    local target, val = {}, {}
    for i = 1, 3 do
        target[i] = math.Rand(0.12, 0.88)
        repeat val[i] = math.Rand(0, 1) until math.abs(val[i] - target[i]) > 0.25
    end
    local tol = 0.05 - diff * 0.008
    local hold, need, drag = 0, 1.5, nil

    local function wave(v, x)
        local amp = 0.2 + 0.8 * v[1]
        local fq = 1 + 4 * v[2]
        local ph = v[3] * math.pi * 2
        return amp * math.sin(x * fq * math.pi * 2 + ph)
    end

    local function sliderRect(i, w)
        return 150, 250 + (i - 1) * 42, w - 300, 12
    end

    local function err()
        local e = 0
        for i = 1, 3 do e = math.max(e, math.abs(val[i] - target[i])) end
        return e
    end

    p.Think = function(s)
        if fr.Done then return end
        if drag then
            if input.IsMouseDown(MOUSE_LEFT) then
                local sx, _, sw = sliderRect(drag, s:GetWide())
                local mx = s:CursorPos()
                val[drag] = math.Clamp((mx - sx) / sw, 0, 1)
            else
                drag = nil
            end
        end
        if err() < tol then hold = hold + FrameTime() else hold = math.max(0, hold - FrameTime() * 2) end
        if hold >= need then finish(true) end
    end

    p.OnMousePressed = function(s)
        local mx, my = s:CursorPos()
        for i = 1, 3 do
            local sx, sy, sw = sliderRect(i, s:GetWide())
            if mx >= sx - 15 and mx <= sx + sw + 15 and math.abs(my - (sy + 6)) < 16 then drag = i return end
        end
    end

    p.Paint = function(s, w, h)
        FlatBox(6, 0, 0, w, h, PANEL)
        local ox, oy, ow, oh = 20, 14, w - 40, 200
        FlatBox(4, ox, oy, ow, oh, BG)
        surface.SetDrawColor(30, 50, 65)
        for i = 1, 9 do surface.DrawRect(ox + ow * i / 10, oy, 1, oh) end
        for i = 1, 3 do surface.DrawRect(ox, oy + oh * i / 4, ow, 1) end
        local mid, amp = oy + oh / 2, oh * 0.42
        local lx, ly1, ly2
        for k = 0, 160 do
            local x = k / 160
            local px = ox + x * ow
            local y1 = mid - wave(target, x) * amp
            local y2 = mid - wave(val, x) * amp
            if lx then
                if k % 2 == 0 then
                    surface.SetDrawColor(80, 200, 220)
                    surface.DrawLine(lx, ly1, px, y1)
                end
                surface.SetDrawColor(244, 241, 233)
                surface.DrawLine(lx, ly2, px, y2)
                surface.DrawLine(lx, ly2 + 1, px, y2 + 1)
            end
            lx, ly1, ly2 = px, y1, y2
        end
        draw.SimpleText("ZIEL", "ShipTech_UISub", ox + 8, oy + 6, Color(80, 200, 220))
        draw.SimpleText("SIGNAL", "ShipTech_UISub", ox + 8, oy + 24, TEXT)

        for i = 1, 3 do
            local sx, sy, sw, sh = sliderRect(i, w)
            draw.SimpleText(names[i], "ShipTech_UIBold", sx - 16, sy + 6, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            FlatBox(4, sx, sy, sw, sh, LINE)
            FlatBox(4, sx, sy, sw * val[i], sh, TEXT)
            Dot(sx + sw * val[i], sy + 6, 11, TEXT)
            local d = math.abs(val[i] - target[i])
            draw.SimpleText(d < tol and "OK" or "--", "ShipTech_UIBold", sx + sw + 20, sy + 6, d < tol and GREEN or DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local sync = math.Clamp(1 - err() * 2.5, 0, 1)
        draw.SimpleText("SYNCHRONITÄT " .. math.floor(sync * 100) .. " %", "ShipTech_UIBold", w / 2, h - 52, sync > 0.9 and GREEN or TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        FlatBox(3, w / 2 - 150, h - 40, 300, 8, LINE)
        FlatBox(3, w / 2 - 150, h - 40, 300 * math.Clamp(hold / need, 0, 1), 8, GREEN)
        Hint(s, "Ziehe die Regler, bis das Signal (weiß) mit dem Ziel (türkis) übereinstimmt, und halte es.", w)
    end
end

---------------------------------------------------------------------------
-- Druckregulierung
---------------------------------------------------------------------------
Games.valves = function(p, diff, finish, fr)
    local n = (diff >= 2) and 4 or 3
    local pr, rate = {}, {}
    for i = 1, n do
        pr[i] = math.Rand(30, 60)
        rate[i] = math.Rand(5, 8) + diff * 1.5
    end
    local zoneLo, zoneHi = 35, 70
    local prog, need = 0, 8

    local function gauge(i, w)
        local gw = 70
        local total = n * gw + (n - 1) * 60
        local x = w / 2 - total / 2 + (i - 1) * (gw + 60)
        return x, 40, gw, 220
    end

    p.Think = function(s)
        if fr.Done then return end
        local dt = FrameTime()
        local all = true
        for i = 1, n do
            pr[i] = pr[i] + rate[i] * dt * (0.6 + 0.9 * math.abs(math.sin(RealTime() * 0.7 + i * 2)))
            if pr[i] >= 100 then
                finish(false)
                return
            end
            if pr[i] < zoneLo or pr[i] > zoneHi then all = false end
        end
        if all then prog = prog + dt else prog = math.max(0, prog - dt * 0.5) end
        if prog >= need then finish(true) end
    end

    p.OnMousePressed = function(s)
        if fr.Done then return end
        local mx, my = s:CursorPos()
        for i = 1, n do
            local x, y, gw, gh = gauge(i, s:GetWide())
            local bx, by = x + gw / 2, y + gh + 40
            if (mx - bx) ^ 2 + (my - by) ^ 2 < 28 ^ 2 then
                pr[i] = math.max(0, pr[i] - 14)
                surface.PlaySound("ambient/machines/steam_release_2.wav")
                return
            end
        end
    end

    p.Paint = function(s, w, h)
        FlatBox(6, 0, 0, w, h, PANEL)
        for i = 1, n do
            local x, y, gw, gh = gauge(i, w)
            FlatBox(4, x, y, gw, gh, BG)
            local zy1 = y + gh * (1 - zoneHi / 100)
            local zy2 = y + gh * (1 - zoneLo / 100)
            surface.SetDrawColor(40, 120, 70, 120)
            surface.DrawRect(x, zy1, gw, zy2 - zy1)
            surface.SetDrawColor(120, 30, 30, 120)
            surface.DrawRect(x, y, gw, gh * 0.12)
            local v = pr[i] / 100
            local col = (pr[i] > 88) and RED or ((pr[i] >= zoneLo and pr[i] <= zoneHi) and GREEN or YELLOW)
            surface.SetDrawColor(col)
            surface.DrawRect(x + 10, y + gh * (1 - v), gw - 20, gh * v)
            draw.SimpleText(math.floor(pr[i]) .. " bar", "ShipTech_UIBold", x + gw / 2, y - 14, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            local bx, by = x + gw / 2, y + gh + 40
            Dot(bx, by, 26, LINE)
            Dot(bx, by, 22, Color(170, 50, 40))
            draw.SimpleText("V" .. i, "ShipTech_UIBold", bx, by, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        draw.SimpleText("DRUCKSTABILITÄT", "ShipTech_UIBold", w / 2, h - 58, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        FlatBox(3, w / 2 - 200, h - 44, 400, 10, LINE)
        FlatBox(3, w / 2 - 200, h - 44, 400 * math.Clamp(prog / need, 0, 1), 10, GREEN)
        Hint(s, "Halte alle Drücke im grünen Bereich – Ventile anklicken lässt Druck ab. 100 bar = Fehlschlag.", w)
    end
end

---------------------------------------------------------------------------
-- Befehlssequenz (Merkspiel)
---------------------------------------------------------------------------
Games.sequence = function(p, diff, finish, fr)
    local len = 3 + diff
    local codes = { "A1", "B7", "C3", "D9", "E4", "F2", "G8", "H5", "K6" }
    local seq = {}
    for i = 1, len do seq[i] = math.random(9) end
    local phase, showStart, idx, errors, flash = "show", RealTime() + 0.8, 1, 0, {}
    local step = 0.65

    local function cell(i, w)
        local cs, gap = 96, 14
        local total = cs * 3 + gap * 2
        local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
        return w / 2 - total / 2 + col * (cs + gap), 46 + row * (cs + gap), cs
    end

    local function restart()
        phase, showStart, idx = "show", RealTime() + 0.9, 1
        for i = 1, len do seq[i] = math.random(9) end
    end

    p.Think = function()
        if phase == "show" and RealTime() - showStart > len * step then phase = "input" end
    end

    p.OnMousePressed = function(s)
        if fr.Done or phase ~= "input" then return end
        local mx, my = s:CursorPos()
        for i = 1, 9 do
            local x, y, cs = cell(i, s:GetWide())
            if mx >= x and mx <= x + cs and my >= y and my <= y + cs then
                flash[i] = RealTime()
                if seq[idx] == i then
                    idx = idx + 1
                    surface.PlaySound("buttons/blip1.wav")
                    if idx > len then finish(true) end
                else
                    errors = errors + 1
                    surface.PlaySound(C.Sounds.Fail)
                    if errors >= 2 then finish(false) else fr:Penalty(4) restart() end
                end
                return
            end
        end
    end

    p.Paint = function(s, w, h)
        FlatBox(6, 0, 0, w, h, PANEL)
        local lit
        if phase == "show" then
            local t = RealTime() - showStart
            local k = math.floor(t / step) + 1
            if t >= 0 and k <= len and (t % step) < step * 0.7 then lit = seq[k] end
        end
        for i = 1, 9 do
            local x, y, cs = cell(i, w)
            local on = (lit == i) or (flash[i] and RealTime() - flash[i] < 0.2)
            FlatBox(6, x, y, cs, cs, on and ACCENT or BG)
            surface.SetDrawColor(LINE)
            surface.DrawOutlinedRect(x, y, cs, cs)
            draw.SimpleText(codes[i], "ShipTech_UIMed", x + cs / 2, y + cs / 2, on and BG or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        local status = (phase == "show") and "SEQUENZ WIRD ÜBERTRAGEN ..." or ("EINGABE " .. (idx - 1) .. " / " .. len)
        draw.SimpleText(status, "ShipTech_UIBold", w / 2, 20, phase == "show" and YELLOW or GREEN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        Hint(s, "Merke dir die aufleuchtende Befehlsfolge und gib sie in derselben Reihenfolge ein. (2 Fehler = Abbruch)", w)
    end
end

---------------------------------------------------------------------------
-- Synchronisation (Timing)
---------------------------------------------------------------------------
Games.timing = function(p, diff, finish, fr, opts)
    opts = opts or {}
    local need = opts.hits or (2 + diff)
    local speed = 130 + diff * 35
    local zone = 42 - diff * 7
    local angle, zoneStart = 0, math.random(30, 300)
    local hits, misses, flashOk, flashBad = 0, 0, 0, 0

    local function press()
        if fr.Done then return end
        local a = (angle - zoneStart) % 360
        if a >= 0 and a <= zone then
            hits = hits + 1
            flashOk = RealTime()
            surface.PlaySound("buttons/button9.wav")
            if hits >= need then finish(true) return end
            zoneStart = math.random(0, 359)
            speed = speed * 1.08
        else
            misses = misses + 1
            flashBad = RealTime()
            surface.PlaySound(C.Sounds.Fail)
            fr:Penalty(2)
            if misses >= 3 then finish(false) end
        end
    end

    p.Think = function()
        if fr.Done then return end
        angle = (angle + speed * FrameTime()) % 360
    end
    p.OnMousePressed = function() press() end
    p.OnKey = function(_, key) if key == KEY_SPACE then press() end end

    p.Paint = function(s, w, h)
        FlatBox(6, 0, 0, w, h, PANEL)
        local cx, cy, r = w / 2, h / 2 - 10, 130
        ShipTech.DrawCircleFilled(cx, cy, r + 8, BG)
        ShipTech.DrawArc(cx, cy, r - 18, r, 0, 360, LINE, 48)
        ShipTech.DrawArc(cx, cy, r - 22, r + 4, zoneStart - 90, zoneStart - 90 + zone, GREEN, 8)
        local a = math.rad(angle - 90)
        ThickLine(cx, cy, cx + math.cos(a) * (r + 6), cy + math.sin(a) * (r + 6), TEXT, 2)
        Dot(cx, cy, 10, ACCENT)
        local fcol = (RealTime() - flashOk < 0.25) and GREEN or ((RealTime() - flashBad < 0.25) and RED or nil)
        if fcol then surface.DrawCircle(cx, cy, r + 14, fcol.r, fcol.g, fcol.b, 255) end
        draw.SimpleText((opts.label or "SYNCHRONISATION") .. "  " .. hits .. " / " .. need, "ShipTech_UIBold", w / 2, 18, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Fehlversuche: " .. misses .. " / 3", "ShipTech_UISmall", w / 2, 40, misses > 0 and RED or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        Hint(s, "Klicke oder drücke LEERTASTE, wenn der Zeiger im grünen Bereich ist.", w)
    end
end

Games.testrun = function(p, diff, finish, fr)
    return Games.timing(p, diff, finish, fr, { hits = 3 + diff, label = "TESTLAUF" })
end

---------------------------------------------------------------------------
-- Fehlersuche (Diagnose)
---------------------------------------------------------------------------
Games.scan = function(p, diff, finish, fr)
    local cols, rows = 8, 5
    local need = 4 + diff
    local found, errors = 0, 0
    local active, nextSpawn = {}, RealTime() + 0.6
    local life = 1.7 - diff * 0.25

    local function cellRect(i, w)
        local cw, ch, gap = 70, 52, 8
        local total = cols * cw + (cols - 1) * gap
        local c, r = (i - 1) % cols, math.floor((i - 1) / cols)
        return w / 2 - total / 2 + c * (cw + gap), 50 + r * (ch + gap), cw, ch
    end

    p.Think = function()
        if fr.Done then return end
        local now = RealTime()
        for i, exp in pairs(active) do
            if now > exp then active[i] = nil end
        end
        if now >= nextSpawn then
            local i = math.random(cols * rows)
            if not active[i] then active[i] = now + life end
            nextSpawn = now + math.Rand(0.45, 0.85)
        end
    end

    p.OnMousePressed = function(s)
        if fr.Done then return end
        local mx, my = s:CursorPos()
        for i = 1, cols * rows do
            local x, y, cw, ch = cellRect(i, s:GetWide())
            if mx >= x and mx <= x + cw and my >= y and my <= y + ch then
                if active[i] then
                    active[i] = nil
                    found = found + 1
                    surface.PlaySound("buttons/blip1.wav")
                    if found >= need then finish(true) end
                else
                    errors = errors + 1
                    surface.PlaySound(C.Sounds.Fail)
                    fr:Penalty(2)
                    if errors >= 4 then finish(false) end
                end
                return
            end
        end
    end

    p.Paint = function(s, w, h)
        FlatBox(6, 0, 0, w, h, PANEL)
        local now = RealTime()
        for i = 1, cols * rows do
            local x, y, cw, ch = cellRect(i, w)
            if active[i] then
                local pulse = math.abs(math.sin(now * 12))
                FlatBox(4, x, y, cw, ch, Color(200, 40 + 40 * pulse, 40, 255))
                draw.SimpleText("!", "ShipTech_UIMed", x + cw / 2, y + ch / 2, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                local n = 20 + math.random(0, 18)
                FlatBox(4, x, y, cw, ch, Color(n, n + 12, n + 22))
                draw.SimpleText(string.format("%02X", math.random(0, 255)), "ShipTech_UISmall", x + cw / 2, y + ch / 2, Color(60, 90, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        local sweep = (now * 160) % w
        surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 40)
        surface.DrawRect(sweep, 44, 3, rows * 60)
        draw.SimpleText("ANOMALIEN ISOLIERT: " .. found .. " / " .. need, "ShipTech_UIBold", w / 2, 22, GREEN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Fehlklicks: " .. errors .. " / 4", "ShipTech_UISmall", w - 20, 22, errors > 0 and RED or DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        Hint(s, "Klicke die rot aufblinkenden Anomalien an, bevor sie verschwinden.", w)
    end
end

---------------------------------------------------------------------------
-- Rahmen
---------------------------------------------------------------------------
net.Receive("ShipTech_Minigame", function()
    local token = net.ReadUInt(32)
    local game = net.ReadString()
    local title = net.ReadString()
    local diff = net.ReadUInt(3)
    local limit = net.ReadUInt(8)
    ShipTech.OpenMinigame(token, game, title, diff, limit)
end)

function ShipTech.OpenMinigame(token, game, title, diff, limit)
    if IsValid(ShipTech.MGFrame) then ShipTech.MGFrame:Remove() end

    local fr = vgui.Create("DFrame")
    ShipTech.MGFrame = fr
    fr:SetSize(math.min(780, ScrW() - 20), math.min(560, ScrH() - 20))
    fr:Center()
    fr:SetTitle("")
    fr:ShowCloseButton(false)
    fr:SetDraggable(false)
    fr:MakePopup()
    fr.Start = RealTime()
    fr.Limit = limit
    fr.Done = false

    function fr:Penalty(sec) self.Start = self.Start - sec end
    function fr:Remaining() return self.Limit - (RealTime() - self.Start) end

    local function finish(ok)
        if fr.Done then return end
        fr.Done = true
        fr.Result = ok
        fr.ResultTime = RealTime()
        net.Start("ShipTech_MinigameResult")
        net.WriteUInt(token, 32)
        net.WriteBool(ok)
        net.SendToServer()
        surface.PlaySound(ok and C.Sounds.Success or C.Sounds.Fail)
        timer.Simple(1.1, function() if IsValid(fr) then fr:Remove() end end)
    end
    fr.Finish = finish

    fr.Paint = function(s, w, h)
        local rem = math.max(0, s:Remaining())
        local f = rem / s.Limit
        local col = f > 0.35 and ACCENT or RED
        EOCUI.Cut(0, 0, w, h, Color(6, 8, 11, 248), 20, "tlbr")
        EOCUI.CutOutline(0, 0, w, h, ColorAlpha(ACCENT, 90), 20, "tlbr")
        surface.SetDrawColor(11, 14, 18, 232)
        surface.DrawRect(20, 1, w - 21, 62)
        -- Kopflinie = verbleibende Zeit
        surface.SetDrawColor(ACCENT.r, ACCENT.g, ACCENT.b, 56)
        surface.DrawRect(0, 63, w, 1)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 63, w * f, 2)

        draw.SimpleText(string.upper(title), "ShipTech_UIMed", 22, 6, TEXT)
        EOCUI.Aurebesh(title, "eocui.aure.small", 24, 34, ColorAlpha(TEXT, 100))
        draw.SimpleText("SCHIFFSTECHNIK // " .. string.upper(ShipTech.GameNames[game] or "MINIGAME"), "ShipTech_UISub", 24, 50, ACCENT)
        draw.SimpleText(string.format("%.1f S", rem), "ShipTech_UIMed", w - 140, 31, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    fr.PaintOver = function(s, w, h)
        if s.Result == nil then return end
        local a = math.Clamp((RealTime() - s.ResultTime) * 600, 0, 200)
        surface.SetDrawColor(0, 0, 0, a)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(s.Result and "ERFOLGREICH" or "FEHLGESCHLAGEN", "ShipTech_UIBig", w / 2, h / 2, s.Result and GREEN or RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local oldThink = fr.Think
    fr.Think = function(s)
        if oldThink then oldThink(s) end
        if not s.Done and s:Remaining() <= 0 then finish(false) end
    end

    fr.OnRemove = function(s)
        if not s.Done then
            s.Done = true
            net.Start("ShipTech_MinigameResult")
            net.WriteUInt(token, 32)
            net.WriteBool(false)
            net.SendToServer()
        end
    end

    local cancel = vgui.Create("DButton", fr)
    cancel:SetText("")
    cancel:SetSize(110, 34)
    cancel:SetPos(fr:GetWide() - 124, 14)
    cancel.Paint = function(s, w, h)
        local hov = s:IsHovered()
        surface.SetDrawColor(hov and Color(14, 18, 23) or Color(8, 11, 15))
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(hov and Color(225, 88, 88, 185) or Color(207, 216, 228, 38))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.SetDrawColor(RED)
        surface.DrawRect(0, 0, 2, h)
        draw.SimpleText("ABBRECHEN", "ShipTech_UIBold", w / 2, h / 2, hov and RED or TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    cancel.DoClick = function() finish(false) end

    local area = vgui.Create("DPanel", fr)
    area:SetPos(20, 80)
    area:SetSize(fr:GetWide() - 40, fr:GetTall() - 100)
    area:SetMouseInputEnabled(true)

    local builder = Games[game] or Games.timing
    builder(area, math.Clamp(diff, 1, 3), finish, fr)

    fr.OnKeyCodePressed = function(_, key) if area.OnKey then area:OnKey(key) end end
    area.OnKeyCodePressed = function(_, key) if area.OnKey then area:OnKey(key) end end
end
