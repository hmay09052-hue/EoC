--[[
    ShipTech – Zeichnen: Schild-Grafik, Ringe, Hologramme über den Konsolen
]]

local C = ShipTech.Config

-- Farben wie im Funksystem
local HOLO      = Color(252, 178, 73)
local TEXT      = Color(236, 233, 224)
local DIM       = Color(157, 163, 173)
local RED       = Color(225, 88, 88)
local GREEN     = Color(74, 203, 130)
local ORANGE    = Color(255, 140, 60)
local CYAN      = Color(80, 200, 220)

function ShipTech.PctColor(f)
    if f >= 0.6 then return CYAN end
    if f >= 0.3 then return HOLO end
    return RED
end

function ShipTech.HeatColor(h)
    if h >= 85 then return RED end
    if h >= 65 then return ORANGE end
    return GREEN
end

function ShipTech.DrawCircleFilled(x, y, r, col)
    draw.RoundedBox(r, x - r, y - r, r * 2, r * 2, col)
end

---------------------------------------------------------------------------
-- Bögen (Polygone, im Uhrzeigersinn)
---------------------------------------------------------------------------
local arcCache, arcCount = {}, 0

function ShipTech.ArcPolys(cx, cy, r1, r2, a1, a2, steps)
    local key = cx .. ":" .. cy .. ":" .. r1 .. ":" .. r2 .. ":" .. a1 .. ":" .. a2 .. ":" .. steps
    local c = arcCache[key]
    if c then return c end
    local polys, step = {}, (a2 - a1) / steps
    for i = 0, steps - 1 do
        local s, e = math.rad(a1 + step * i), math.rad(a1 + step * (i + 1))
        polys[#polys + 1] = {
            { x = cx + math.cos(s) * r2, y = cy + math.sin(s) * r2 },
            { x = cx + math.cos(e) * r2, y = cy + math.sin(e) * r2 },
            { x = cx + math.cos(e) * r1, y = cy + math.sin(e) * r1 },
            { x = cx + math.cos(s) * r1, y = cy + math.sin(s) * r1 },
        }
    end
    arcCount = arcCount + 1
    if arcCount > 3000 then arcCache, arcCount = {}, 0 end
    arcCache[key] = polys
    return polys
end

function ShipTech.DrawArc(cx, cy, r1, r2, a1, a2, col, steps)
    draw.NoTexture()
    surface.SetDrawColor(col)
    for _, p in ipairs(ShipTech.ArcPolys(cx, cy, r1, r2, a1, a2, steps or 8)) do
        surface.DrawPoly(p)
    end
end

-- Segmentierter Ring: frac (0..1) der Segmente leuchtet
function ShipTech.DrawSegRing(cx, cy, r1, r2, startA, span, count, gap, frac, colOn, colOff)
    local seg = span / count
    local lit = math.floor(frac * count + 0.5)
    for i = 0, count - 1 do
        local a = startA + i * seg
        ShipTech.DrawArc(cx, cy, r1, r2, a + gap * 0.5, a + seg - gap * 0.5, (i < lit) and colOn or colOff, 1)
    end
end

---------------------------------------------------------------------------
-- SCHILD-GRAFIK
-- Außenring = Gesamtschildstärke, Innenring = 4 Sektoren, Mitte = Sternzerstörer
---------------------------------------------------------------------------
function ShipTech.DrawShieldGraphic(cx, cy, r, opts)
    opts = opts or {}
    local S = ShipTech.State
    local secs = (S and S.shields and S.shields.sectors) or { 0, 0, 0, 0 }
    local total = ShipTech.GetShieldPercent() / 100
    local col = ShipTech.PctColor(total)
    local t = opts.static and 0 or RealTime()
    local sh = ShipTech.Sys("shields")
    local online = sh and (sh.eff or 0) > 0
    local focus = (S and S.shields and S.shields.focus) or 0

    -- Hintergrund
    ShipTech.DrawCircleFilled(cx, cy, r * 1.05, Color(7, 9, 12, 220))
    surface.DrawCircle(cx, cy, r * 1.05, col.r, col.g, col.b, 60)

    -- Außenring: Gesamt
    ShipTech.DrawSegRing(cx, cy, r * 0.88, r, -90, 360, 60, 1.8, total, col, Color(207, 216, 228, 28))

    -- Kapazitätsmarke (maximal mögliche Stärke bei aktueller Effizienz)
    local cap = ((S and S.mods and S.mods.shieldCap) or 0) / 100
    if cap > 0 and cap < 1 then
        local a = -90 + 360 * cap
        ShipTech.DrawArc(cx, cy, r * 0.86, r * 1.02, a - 1, a + 1, Color(255, 255, 255, 200), 1)
    end

    -- Innenring: Sektoren (Bug oben, Steuerbord rechts, Heck unten, Backbord links)
    for i = 1, 4 do
        local start = -135 + (i - 1) * 90
        local f = (secs[i] or 0) / 100
        local c = ShipTech.PctColor(f)
        ShipTech.DrawSegRing(cx, cy, r * 0.72, r * 0.82, start + 4, 82, 12, 1.6, f, c, Color(207, 216, 228, 28))
        if focus == i then
            ShipTech.DrawArc(cx, cy, r * 0.69, r * 0.705, start + 4, start + 86, Color(255, 255, 255, opts.static and 200 or (120 + 100 * math.abs(math.sin(t * 4)))), 12)
        end
    end

    -- Schildblase um das Schiff
    if online and total > 0 then
        local pulse = opts.static and 1 or (0.5 + 0.5 * math.sin(t * 2))
        local a = 40 + 140 * total * (0.6 + 0.4 * pulse)
        surface.DrawCircle(cx, cy, r * 0.6, col.r, col.g, col.b, a)
        surface.DrawCircle(cx, cy, r * 0.6 - 2, col.r, col.g, col.b, a * 0.6)
        surface.DrawCircle(cx, cy, r * 0.6 - 4, col.r, col.g, col.b, a * 0.3)
    end

    -- Radar-Sweep (nicht im ruhigen Hologramm)
    if not opts.static then
        local sa = math.rad((t * 90) % 360)
        surface.SetDrawColor(col.r, col.g, col.b, 70)
        surface.DrawLine(cx, cy, cx + math.cos(sa) * r * 0.68, cy + math.sin(sa) * r * 0.68)
    end

    -- Sternzerstörer-Silhouette
    local sw, shh = r * 0.25, r * 0.5
    local top = cy - r * 0.38
    draw.NoTexture()
    surface.SetDrawColor(185, 195, 210, 235)
    surface.DrawPoly({ { x = cx, y = top }, { x = cx + sw, y = top + shh }, { x = cx - sw, y = top + shh } })
    surface.SetDrawColor(120, 130, 145, 255)
    surface.DrawRect(cx - 1, top + shh * 0.15, 2, shh * 0.8)
    surface.DrawRect(cx - sw * 0.28, top + shh * 0.68, sw * 0.56, shh * 0.12)
    surface.DrawRect(cx - sw * 0.5, top + shh * 0.82, sw * 1.0, shh * 0.08)
    local glow = opts.static and 200 or (120 + 100 * math.abs(math.sin(t * 3)))
    surface.SetDrawColor(120, 200, 255, online and glow or 40)
    surface.DrawRect(cx - sw * 0.7, top + shh + 1, sw * 1.4, math.max(2, r * 0.02))

    -- Prozentanzeige
    draw.SimpleText(math.Round(total * 100) .. "%", opts.bigFont or "ShipTech_HoloBig", cx, cy + r * 0.36, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    if not online then
        draw.SimpleText("OFFLINE", opts.smallFont or "ShipTech_HoloSmall", cx, cy + r * 0.56, RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Sektorbeschriftung
    if opts.labels ~= false then
        local lf = opts.smallFont or "ShipTech_HoloSmall"
        local function lbl(i, x, y, ax, ay, name)
            local f = (secs[i] or 0) / 100
            draw.SimpleText(name .. " " .. math.Round(f * 100) .. "%", lf, x, y, ShipTech.PctColor(f), ax, ay)
        end
        lbl(1, cx, cy - r * 1.1, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, "BUG")
        lbl(3, cx, cy + r * 1.1, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, "HECK")
        lbl(2, cx + r * 1.1, cy, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, "STB")
        lbl(4, cx - r * 1.1, cy, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, "BB")
    end

    -- Trefferblitz
    local fl = opts.static and 99 or (RealTime() - (ShipTech.ShieldFlash or 0))
    if fl < 0.6 then
        local a = 255 * (1 - fl / 0.6)
        surface.DrawCircle(cx, cy, r * (1 + fl * 0.4), 255, 255, 255, a)
        surface.DrawCircle(cx, cy, r * (0.95 + fl * 0.4), 150, 220, 255, a * 0.7)
    end
end

-- horizontaler Balken mit Segmenten
function ShipTech.DrawSegBar(x, y, w, h, frac, col, segs)
    segs = segs or 20
    local sw = w / segs
    local lit = math.floor(math.Clamp(frac, 0, 1) * segs + 0.5)
    for i = 0, segs - 1 do
        local c = (i < lit) and col or Color(207, 216, 228, 28)
        surface.SetDrawColor(c)
        surface.DrawRect(x + i * sw + 1, y, sw - 2, h)
    end
end

---------------------------------------------------------------------------
-- HOLOGRAMME
---------------------------------------------------------------------------
local W = 640

-- Panel im Stil des Funksystems: dunkel, flach, dünner Rahmen, gelbe Ecken
local function Panel(x, y, w, h, accent)
    surface.SetDrawColor(7, 9, 12, 225)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(207, 216, 228, 40)
    surface.DrawOutlinedRect(x, y, w, h, 2)
    surface.SetDrawColor(accent)
    surface.DrawRect(x, y, 26, 3)
    surface.DrawRect(x, y, 3, 26)
    surface.DrawRect(x + w - 26, y + h - 3, 26, 3)
    surface.DrawRect(x + w - 3, y + h - 26, 3, 26)

end

local function Header(x, y, w, title, purpose, accent)
    surface.SetDrawColor(14, 18, 23, 235)
    surface.DrawRect(x + 3, y + 3, w - 6, 94)
    draw.SimpleText(string.upper(title), "ShipTech_HoloTitle", x + 24, y + 36, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(string.upper("Schiffstechnik // " .. (purpose or "")), "ShipTech_HoloSmall", x + 25, y + 74, accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(accent.r, accent.g, accent.b, 56)
    surface.DrawRect(x, y + 97, w, 2)
    surface.SetDrawColor(accent)
    surface.DrawRect(x, y + 97, 220, 3)
    return y + 108
end

local function MiniBar(x, y, w, label, frac, col, value)
    draw.SimpleText(string.upper(label), "ShipTech_HoloSmall", x, y, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(value, "ShipTech_HoloSmall", x + w, y, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    ShipTech.DrawSegBar(x, y + 28, w, 10, frac, col, 24)
end

local function Footer(x, y, w, text, col)
    draw.SimpleText(text, "ShipTech_HoloSmall", x + w / 2, y, col or HOLO, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

-- Hologramm einer System-Konsole
local function DrawSystemHolo(ent, accent, noPow)
    local id = ent.SysId
    local sys = ShipTech.Sys(id)
    local def = ShipTech.SystemById[id]
    local hasCalib = def and def.calib
    local h = 108 + 52 + (hasCalib and 4 or 3) * 50 + 36 + 44
    local x, y = -W / 2, -h
    Panel(x, y, W, h, accent)
    local cy = Header(x, y, W, ent.PrintName, ent.Purpose, accent)

    if not sys then
        draw.SimpleText("Verbinde ...", "ShipTech_HoloText", 0, cy + 30, DIM, TEXT_ALIGN_CENTER)
        return h
    end

    local stage = ShipTech.StageOf(sys.health)
    local st = ShipTech.Stages[stage]
    local txt, col = ShipTech.StatusInfo(id)
    draw.SimpleText(txt, "ShipTech_HoloText", x + 20, cy + 22, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(st.short, "ShipTech_HoloText", x + W - 20, cy + 22, st.col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    cy = cy + 52

    local bw = W - 40
    MiniBar(x + 20, cy, bw, "ZUSTAND", sys.health / 100, st.col, math.Round(sys.health) .. " %")
    cy = cy + 50
    MiniBar(x + 20, cy, bw, "WARTUNG", sys.maint / 100, ShipTech.PctColor(sys.maint / 100), math.Round(sys.maint) .. " %")
    cy = cy + 50
    if hasCalib then
        MiniBar(x + 20, cy, bw, "KALIBRIERUNG", (sys.calib or 0) / 100, ShipTech.PctColor((sys.calib or 0) / 100), math.Round(sys.calib or 0) .. " %")
        cy = cy + 50
    end
    MiniBar(x + 20, cy, bw, "TEMPERATUR", sys.heat / 100, ShipTech.HeatColor(sys.heat), math.Round(sys.heat) .. " %")
    cy = cy + 50

    local info
    local known, unknown = 0, 0
    for _, f in ipairs(sys.faults or {}) do
        if f.k then known = known + 1 else unknown = unknown + 1 end
    end
    if #(sys.faults or {}) > 0 then
        info = "! " .. #sys.faults .. " Störung(en)" .. (unknown > 0 and " – Diagnose erforderlich" or " – Reparatur erforderlich")
        draw.SimpleText(info, "ShipTech_HoloSmall", 0, cy + 4, ORANGE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    elseif sys.wf then
        draw.SimpleText(ShipTech.WorkflowNames[sys.wf] or "", "ShipTech_HoloSmall", 0, cy + 4, ORANGE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    elseif sys.maint < 40 then
        draw.SimpleText("Wartung fällig", "ShipTech_HoloSmall", 0, cy + 4, HOLO, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    elseif sys.calib and sys.calib < 50 then
        draw.SimpleText("Kalibrierung fällig", "ShipTech_HoloSmall", 0, cy + 4, HOLO, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    cy = cy + 36

    if noPow then
        local a = 255
        Footer(x, cy + 6, W, "KEINE ENERGIE – NUR HANDBETRIEB", ColorAlpha(RED, a))
    else
        Footer(x, cy + 6, W, "[E] KONSOLE BENUTZEN")
    end
    return h
end

local function DrawTerminalHolo(ent, accent, noPow)
    local S = ShipTech.State
    local h = 108 + 4 * 40 + 50
    local x, y = -W / 2, -h
    Panel(x, y, W, h, accent)
    local cy = Header(x, y, W, ent.PrintName, ent.Purpose, accent) + 8

    if S then
        local r = S.systems.reactor
        local rt, rc = ShipTech.StatusInfo("reactor")
        if S.backup and S.backup.active then rt, rc = "NOTSTROM " .. math.Round(S.backup.charge) .. " %", HOLO end
        local open, alarms = 0, 0
        for _, o in ipairs(S.orders or {}) do
            if o.status == "open" or o.status == "accepted" then open = open + 1 end
        end
        for _ in pairs(S.alarms or {}) do alarms = alarms + 1 end
        local sp = ShipTech.GetShieldPercent() / 100

        local function row(label, value, col)
            draw.SimpleText(label, "ShipTech_HoloText", x + 24, cy + 16, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(value, "ShipTech_HoloText", x + W - 24, cy + 16, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            cy = cy + 40
        end
        row("Reaktor", rt .. (r.on and (" · " .. math.Round(S.supply.output or 0) .. " E") or ""), rc)
        row("Schilde", math.Round(sp * 100) .. " %", ShipTech.PctColor(sp))
        row("Offene Wartungsaufträge", tostring(open), open > 0 and HOLO or GREEN)
        row("Aktive Alarme", tostring(alarms), alarms > 0 and RED or GREEN)
    end

    if noPow then
        Footer(x, cy + 8, W, "KEINE ENERGIE", RED)
    else
        Footer(x, cy + 8, W, "[E] TERMINAL ÖFFNEN")
    end
    return h
end

local function DrawBreakerHolo(ent, accent)
    local name = ent:GetSector()
    local out = ShipTech.IsOutage(name)
    local h = 108 + 110
    local x, y = -W / 2, -h
    Panel(x, y, W, h, out and RED or accent)
    local cy = Header(x, y, W, ent.PrintName, ent.Purpose, out and RED or accent)
    draw.SimpleText("SEKTOR: " .. string.upper(name ~= "" and name or "?"), "ShipTech_HoloText", 0, cy + 20, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    if out then
        local a = 255
        draw.SimpleText("STROMAUSFALL – [E] INSTANDSETZEN", "ShipTech_HoloText", 0, cy + 62, ColorAlpha(RED, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("VERSORGT", "ShipTech_HoloText", 0, cy + 62, GREEN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return h
end

-- Reaktor- und Energiekonsole sind verbunden und zeigen dasselbe Hologramm
local function DrawEnergyHolo(ent, accent, noPow)
    local S = ShipTech.State
    local consumers = #ShipTech.Systems - 1
    local h = 108 + 52 + 4 * 50 + 40 + consumers * 32 + 20 + 50
    local x, y = -W / 2, -h
    Panel(x, y, W, h, accent)
    local cy = Header(x, y, W, ent.PrintName, "Energiezentrale – Reaktor + Netz verbunden", accent)
    if not S then return h end

    local r = S.systems.reactor
    local txt, col = ShipTech.StatusInfo("reactor")
    if S.backup and S.backup.active then txt, col = "NOTSTROMBETRIEB", ORANGE end
    draw.SimpleText("REAKTOR: " .. txt, "ShipTech_HoloText", x + 20, cy + 22, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local st = ShipTech.Stages[ShipTech.StageOf(r.health)]
    draw.SimpleText(st.short, "ShipTech_HoloText", x + W - 20, cy + 22, st.col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    cy = cy + 52

    local bw = W - 40
    local out, dem = S.supply.output or 0, S.supply.demand or 0
    local load = out > 0 and dem / out or 0
    MiniBar(x + 20, cy, bw, "Energieabgabe", out / C.PowerBudget, HOLO, math.Round(out) .. " / " .. C.PowerBudget .. " E")
    cy = cy + 50
    MiniBar(x + 20, cy, bw, "Auslastung", math.min(1, load / 1.5), load > 1 and RED or (load > 0.85 and ORANGE or GREEN), math.Round(load * 100) .. " %")
    cy = cy + 50
    MiniBar(x + 20, cy, bw, "Reaktortemperatur", r.heat / 100, ShipTech.HeatColor(r.heat), math.Round(r.heat) .. " %")
    cy = cy + 50
    local b = S.backup or {}
    MiniBar(x + 20, cy, bw, "Notstrom" .. (b.active and " (aktiv)" or ""), (b.charge or 0) / 100, b.active and ORANGE or GREEN, math.Round(b.charge or 0) .. " %")
    cy = cy + 50

    local pw = S.systems.power
    local ptxt, pcol = ShipTech.StatusInfo("power")
    draw.SimpleText("ENERGIENETZ", "ShipTech_HoloSmall", x + 20, cy + 14, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(ptxt .. "  //  VERSORGUNG " .. math.Round((S.supply.ratio or 0) * 100) .. " %", "ShipTech_HoloSmall", x + W - 20, cy + 14, pcol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    cy = cy + 40

    for _, def in ipairs(ShipTech.Systems) do
        if def.id ~= "reactor" then
            local s = S.systems[def.id]
            local on = (s.power or 0) > 0
            draw.SimpleText(string.upper(def.name), "ShipTech_HoloSmall", x + 20, cy + 12, on and TEXT or DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            ShipTech.DrawSegBar(x + 250, cy + 7, W - 450, 10, s.alloc / C.MaxAllocPerSystem, s.alloc > def.nominal * 1.2 and ORANGE or (on and HOLO or Color(207, 216, 228, 60)), 20)
            draw.SimpleText(s.alloc .. " E", "ShipTech_HoloSmall", x + W - 20, cy + 12, on and GREEN or RED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            cy = cy + 32
        end
    end
    cy = cy + 14

    if noPow then
        Footer(x, cy, W, "KEINE ENERGIE – NUR HANDBETRIEB", RED)
    else
        Footer(x, cy, W, "[E] ENERGIEZENTRALE ÖFFNEN")
    end
    return h
end

---------------------------------------------------------------------------
-- Schildgrafik als Textur (Render-Target): wird nur ~15x pro Sekunde neu gezeichnet,
-- alle Hologramme zeigen danach nur noch das fertige Bild.
---------------------------------------------------------------------------
local RT_SIZE, RT_R = 1024, 400
local shieldRT, shieldMat
local rtWanted, rtLast = 0, 0

surface.CreateFont("ShipTech_RTBig", { font = "Bebas Neue", size = 190, weight = 400, antialias = true, extended = true })
surface.CreateFont("ShipTech_RTSmall", { font = "Bebas Neue", size = 52, weight = 400, antialias = true, extended = true })

local function EnsureRT()
    if shieldRT then return true end
    shieldRT = GetRenderTargetEx("ShipTech_ShieldRT", RT_SIZE, RT_SIZE, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE, 2, 0, IMAGE_FORMAT_RGBA8888)
    shieldMat = CreateMaterial("ShipTech_ShieldRTMat", "UnlitGeneric", {
        ["$basetexture"] = shieldRT:GetName(),
        ["$translucent"] = 1,
        ["$vertexalpha"] = 1,
        ["$vertexcolor"] = 1,
    })
    return true
end

hook.Add("PostRender", "ShipTech_ShieldRT", function()
    if rtWanted < RealTime() or RealTime() - rtLast < 1 / 15 or not ShipTech.State then return end
    if not EnsureRT() then return end
    rtLast = RealTime()
    render.PushRenderTarget(shieldRT)
    render.OverrideAlphaWriteEnable(true, true)
    render.ClearDepth()
    render.Clear(0, 0, 0, 0)
    cam.Start2D()
        ShipTech.DrawShieldGraphic(RT_SIZE / 2, RT_SIZE / 2, RT_R, { bigFont = "ShipTech_RTBig", smallFont = "ShipTech_RTSmall", static = true })
    cam.End2D()
    render.OverrideAlphaWriteEnable(false)
    render.PopRenderTarget()
end)

-- gecachte Schildgrafik zeichnen (Mittelpunkt, Radius wie DrawShieldGraphic)
function ShipTech.DrawShieldCached(cx, cy, r)
    rtWanted = RealTime() + 0.5
    if not EnsureRT() then return end
    local size = RT_SIZE * (r / RT_R)
    surface.SetMaterial(shieldMat)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(cx - size / 2, cy - size / 2, size, size)
end

-- Navigationsstation: Sprungstatus
local PHASE_TXT = { idle = "BEREITSCHAFT", calc = "KURS WIRD BERECHNET", ready = "KURS BERECHNET", routed = "SPRUNGBEREIT", countdown = "COUNTDOWN", hyperspace = "IM HYPERRAUM" }
local function DrawNavHolo(ent, accent, noPow)
    local S = ShipTech.State
    local h = 108 + 3 * 40 + 50
    local x, y = -W / 2, -h
    Panel(x, y, W, h, accent)
    local cy = Header(x, y, W, ent.PrintName, ent.Purpose, accent) + 8
    local H = (S and S.hyper) or {}
    local ph = H.phase or "idle"
    local col = (ph == "routed" and GREEN) or (ph == "hyperspace" and CYAN) or (ph == "countdown" and ORANGE) or TEXT
    local function row(label, value, c)
        draw.SimpleText(label, "ShipTech_HoloText", x + 24, cy + 16, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(value, "ShipTech_HoloText", x + W - 24, cy + 16, c, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        cy = cy + 40
    end
    row("Status", PHASE_TXT[ph] or ph, col)
    row("Ziel", (H.dest and H.dest ~= "") and string.upper(H.dest) or "–", TEXT)
    local hd = S and S.systems and S.systems.hyperdrive
    row("Hyperantrieb", hd and (math.Round((hd.eff or 0) * 100) .. " %") or "–", hd and (hd.eff or 0) >= C.Hyper.MinEfficiency and GREEN or RED)
    Footer(x, cy + 8, W, noPow and "KEINE ENERGIE" or (ph == "routed" and "[E] SPRUNG AUSLÖSEN" or "[E] NAVIGATIONSSTATION"), noPow and RED or HOLO)
    return h
end
local function DrawShieldHolo(baseY, accent, title)
    local r = 200
    local labelPad = 46
    local top = baseY - (r * 2 + labelPad * 2 + 70)
    local cx, cy = 0, top + 70 + labelPad + r
    Panel(-W / 2, top, W, baseY - top - 14, accent)
    draw.SimpleText(title, "ShipTech_HoloTitle", 0, top + 36, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    ShipTech.DrawShieldCached(cx, cy, r)
end

---------------------------------------------------------------------------
-- Vereinfachtes Hologramm (weit weg oder nicht angesehen)
---------------------------------------------------------------------------
local function DrawSimpleHolo(ent, accent, noPow)
    local h = 108 + 56
    local x, y = -W / 2, -h
    Panel(x, y, W, h, accent)
    local cy = Header(x, y, W, ent.PrintName, ent.Purpose, accent)
    local txt, col
    if ent.SysId then
        txt, col = ShipTech.StatusInfo(ent.SysId)
    elseif ent.ConsoleKind == "breaker" then
        local out = ShipTech.IsOutage(ent:GetSector())
        txt, col = out and "STROMAUSFALL" or "VERSORGT", out and RED or GREEN
    else
        txt, col = "BEREIT", GREEN
    end
    if noPow then txt, col = "KEINE ENERGIE", RED end
    draw.SimpleText(txt, "ShipTech_HoloText", 0, cy + 22, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

---------------------------------------------------------------------------
-- Große Schiffsstatus-Wand
---------------------------------------------------------------------------
local WW = 1500
local function DrawWallHolo(ent, accent, detail)
    local S = ShipTech.State
    local h = 860
    local x, y = -WW / 2, -h
    Panel(x, y, WW, h, accent)
    local cy = Header(x, y, WW, "Schiffsstatus", "Brücke – Gesamtübersicht", accent)
    if not S then return end

    -- links: Schilde
    ShipTech.DrawShieldCached(x + 260, cy + 290, 200)

    -- Mitte: Systeme
    local gx, gy = x + 540, cy + 10
    local cw, ch = 300, 120
    for i, def in ipairs(ShipTech.Systems) do
        local s = S.systems[def.id]
        local cx = gx + ((i - 1) % 3) * (cw + 14)
        local yy = gy + math.floor((i - 1) / 3) * (ch + 14)
        local st = ShipTech.Stages[ShipTech.StageOf(s.health)]
        local txt, col = ShipTech.StatusInfo(def.id)
        surface.SetDrawColor(14, 18, 23, 235)
        surface.DrawRect(cx, yy, cw, ch)
        surface.SetDrawColor(st.col)
        surface.DrawRect(cx, yy, 4, ch)
        draw.SimpleText(string.upper(def.name), "ShipTech_HoloMed", cx + 16, yy + 26, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(txt, "ShipTech_HoloSmall", cx + 16, yy + 60, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if detail then
            ShipTech.DrawSegBar(cx + 16, yy + 84, cw - 32, 10, s.health / 100, st.col, 16)
            if #(s.faults or {}) > 0 then
                draw.SimpleText("!" .. #s.faults, "ShipTech_HoloSmall", cx + cw - 12, yy + 26, ORANGE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end
    end

    -- unten: Energie, Hyperraum, Checkliste, Alarme
    local by = cy + 430
    local out = S.supply.output or 0
    local b = S.backup or {}
    draw.SimpleText("ENERGIE", "ShipTech_HoloSmall", x + 40, by, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(b.active and ("NOTSTROM " .. math.Round(b.charge or 0) .. " %") or (math.Round(out) .. " / " .. C.PowerBudget .. " E"), "ShipTech_HoloMed", x + 40, by + 30, b.active and ORANGE or (out > 0 and HOLO or RED), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local H = S.hyper or {}
    local hyperTxt = ({ idle = "BEREITSCHAFT", calc = "KURS WIRD BERECHNET", ready = "KURS BERECHNET", routed = "SPRUNGBEREIT", countdown = "SPRUNG LÄUFT", hyperspace = "IM HYPERRAUM" })[H.phase or "idle"] or "–"
    draw.SimpleText("HYPERRAUM", "ShipTech_HoloSmall", x + 400, by, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(hyperTxt .. ((H.dest and H.dest ~= "" and H.phase ~= "idle") and (" → " .. string.upper(H.dest)) or ""), "ShipTech_HoloMed", x + 400, by + 30, H.phase == "hyperspace" and CYAN or TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local steps = ShipTech.ChecklistSteps
    local n = (S.checklist and S.checklist.n) or 0
    draw.SimpleText("STARTCHECKLISTE", "ShipTech_HoloSmall", x + 40, by + 110, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    for i, st in ipairs(steps) do
        local col = (i <= n) and GREEN or ((i == n + 1) and HOLO or Color(207, 216, 228, 60))
        local sx = x + 40 + (i - 1) * ((WW - 80) / #steps)
        surface.SetDrawColor(col)
        surface.DrawRect(sx, by + 146, (WW - 80) / #steps - 10, 8)
        if detail then
            draw.SimpleText(i .. ". " .. st.name, "ShipTech_HoloSmall", sx, by + 166, (i <= n) and TEXT or DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    local list = {}
    for id in pairs(S.alarms or {}) do
        local def = ShipTech.AlarmTypes[id]
        if def then list[#list + 1] = def.name end
    end
    local alarmTxt = #list > 0 and ("ALARM: " .. table.concat(list, " · ")) or "KEINE AKTIVEN ALARME"
    local ac = #list > 0 and RED or GREEN
    draw.SimpleText(alarmTxt, "ShipTech_HoloMed", 0, by + 240, ac, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    return h
end

---------------------------------------------------------------------------
-- Hologramm über einer Konsole zeichnen
---------------------------------------------------------------------------
function ShipTech.DrawConsoleHolo(ent)
    local lp = LocalPlayer()
    local eye = lp:EyePos()
    local dist = eye:Distance(ent:GetPos())
    if dist > C.HoloDistance then return end

    local fade = math.Clamp((C.HoloDistance - dist) / 150, 0, 1)
    local noPow = ent:GetNW2Bool("ST_NoPow")
    local flick = noPow and 0.8 or 1

    local pos = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z)) + Vector(0, 0, ent.HoloOffset or 18)
    local ang = Angle(0, lp:EyeAngles().y - 90, 90)
    local kind = ent.ConsoleKind
    local accent = noPow and RED or HOLO
    if ent.SysId then
        local sys = ShipTech.Sys(ent.SysId)
        if sys and ShipTech.StageOf(sys.health) >= 2 then accent = ORANGE end
    end

    -- Detailstufe: nah genug UND man schaut ungefähr hin
    local toHolo = (pos - eye):GetNormalized()
    -- Hysterese: verhindert ständiges Umschalten an der Grenze
    local dot = lp:GetAimVector():Dot(toHolo)
    local near = C.HoloDetailDistance or 380
    local detail = ent.ST_Detail
    if detail then
        if dist > near * 1.2 or dot < 0.6 then detail = false end
    else
        if dist < near and dot > 0.8 then detail = true end
    end
    ent.ST_Detail = detail

    local fire = ent:GetNW2Float("ST_Fire", 0)
    local topY

    surface.SetAlphaMultiplier(fade * flick)
    -- Ebenen des Hologramms liegen in derselben Tiefe -> ohne Tiefenschreiben zeichnen, sonst flimmern sie gegeneinander
    render.OverrideDepthEnable(true, false)
    cam.Start3D2D(pos, ang, 0.06)
        if kind == "wall" then
            topY = -DrawWallHolo(ent, accent, detail)
        elseif not detail then
            DrawSimpleHolo(ent, accent, noPow)
            topY = -164
            if ent.SysId == "shields" or kind == "display" then
                ShipTech.DrawShieldCached(0, topY - 180, 150)
                topY = topY - 340
            end
        elseif kind == "system" and (ent.SysId == "reactor" or ent.SysId == "power") then
            topY = -DrawEnergyHolo(ent, accent, noPow)
        elseif kind == "system" then
            local h = DrawSystemHolo(ent, accent, noPow)
            topY = -h
            if ent.SysId == "shields" then
                DrawShieldHolo(-h - 10, accent, "SCHILDSTATUS")
                topY = -h - 10 - 562
            end
        elseif kind == "terminal" then
            topY = -DrawTerminalHolo(ent, accent, noPow)        elseif kind == "nav" then
            topY = -DrawNavHolo(ent, accent, noPow)
        elseif kind == "breaker" then
            topY = -DrawBreakerHolo(ent, accent)
        elseif kind == "display" then
            local h = 116
            Panel(-W / 2, -h, W, h, accent)
            Header(-W / 2, -h, W, ent.PrintName, ent.Purpose, accent)
            DrawShieldHolo(-h - 10, accent, "SCHILDE " .. math.Round(ShipTech.GetShieldPercent()) .. " %")
            topY = -h - 10 - 562
        end

        -- Brandwarnung über dem Hologramm
        if fire > 0 and topY then
            local a = 255
            surface.SetDrawColor(7, 9, 12, 230)
            surface.DrawRect(-W / 2, topY - 70, W, 60)
            surface.SetDrawColor(ColorAlpha(RED, a))
            surface.DrawRect(-W / 2, topY - 70, 4, 60)
            draw.SimpleText("BRAND – " .. math.Round(fire * 100) .. " %  ·  FEUERLÖSCHER BENUTZEN", "ShipTech_HoloSmall", 0, topY - 40, ColorAlpha(RED, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
    render.OverrideDepthEnable(false, false)
    surface.SetAlphaMultiplier(1)
end
