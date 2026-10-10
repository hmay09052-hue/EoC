-- Welt-Anzeigen: Strukturen, Baustellen, Container, Terminals, Wegpunkte, FOB-HUD
-- Infotafeln nur für die angeschauten/nächsten Objekte, Drahtgitter nur bis 600 Units.

local cfg = GARLog.Config
local UI = GARLog.UI
local C = UI.C

local DIST, FADE = 520, 380
local DIST2 = DIST * DIST
local panelBG = Color(7, 9, 12, 225)

local function FadeAlpha(pos)
    local d2 = EyePos():DistToSqr(pos)
    if d2 > DIST2 then return nil end
    local d = math.sqrt(d2)
    if d <= FADE then return 1 end
    return 1 - (d - FADE) / (DIST - FADE)
end

local function FaceAngle()
    return Angle(0, EyeAngles().y - 90, 90)
end

---------------------------------------------------------------------------
-- Fokus: nur die (max. 3) Objekte, die man anschaut oder vor denen man steht,
-- zeichnen eine Infotafel. Auswahl 10x pro Sekunde statt Arbeit in jedem Frame.
---------------------------------------------------------------------------
GARLog.PanelEnts  = GARLog.PanelEnts or {}   -- Entities mit Infotafel (melden sich beim Zeichnen an)
GARLog.PanelFocus = GARLog.PanelFocus or {}
local PanelEnts = GARLog.PanelEnts
local FOCUS_DIST2, FOCUS_NEAR2, FOCUS_DOT, FOCUS_MAX = DIST * DIST, 170 * 170, 0.94, 3
local nextFocus = 0
local candidates = {}

hook.Add("Think", "GARLog_PanelFocus", function()
    local now = CurTime()
    if now < nextFocus then return end
    nextFocus = now + 0.1
    if not next(PanelEnts) then
        if next(GARLog.PanelFocus) then GARLog.PanelFocus = {} end
        return
    end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local eye, aim = lp:EyePos(), lp:GetAimVector()
    local n = 0
    for ent in pairs(PanelEnts) do
        if not IsValid(ent) then
            PanelEnts[ent] = nil
        else
            local dir = ent:WorldSpaceCenter() - eye
            local d2 = dir:LengthSqr()
            if d2 < FOCUS_DIST2 then
                local dot = aim:Dot(dir) / math.max(math.sqrt(d2), 1)
                if d2 < FOCUS_NEAR2 or dot > FOCUS_DOT then
                    n = n + 1
                    candidates[n] = { ent = ent, score = d2 * (2 - dot) }
                end
            end
        end
    end
    for i = n + 1, #candidates do candidates[i] = nil end
    table.sort(candidates, function(a, b) return a.score < b.score end)
    local focus = {}
    for i = 1, math.min(n, FOCUS_MAX) do focus[candidates[i].ent] = true end
    GARLog.PanelFocus = focus
end)

-- true = Infotafel zeichnen
local function WantsPanel(ent)
    PanelEnts[ent] = true
    return GARLog.PanelFocus[ent] == true
end

-- Gemeinsames Panel: Kopf, Statuszeile, Balken, Zeilen
local function DrawPanel(pos, alpha, title, subtitle, status, statusCol, hpFrac, hpCol, lines, bars)
    local w = 600
    local h = 118 + (hpFrac and 34 or 0) + #lines * 38 + (bars and 118 or 0)
    surface.SetAlphaMultiplier(alpha)
    cam.Start3D2D(pos, FaceAngle(), 0.06)
        local x, y = -w / 2, -h
        surface.SetDrawColor(panelBG)
        surface.DrawRect(x, y, w, h)
        surface.SetDrawColor(C.line)
        surface.DrawOutlinedRect(x, y, w, h, 2)
        surface.SetDrawColor(C.yellow)
        surface.DrawRect(x, y, 22, 3)
        surface.DrawRect(x, y, 3, 22)
        surface.DrawRect(x, y + h - 3, w, 3)

        draw.SimpleText(title, "GARLog_W_Head", x + 22, y + 34, C.white, 0, 1)
        if subtitle and subtitle ~= "" then
            draw.SimpleText(subtitle, "GARLog_W_Small", x + 22, y + 68, C.yellow, 0, 1)
        end
        if status then
            surface.SetFont("GARLog_W_Small")
            local tw = surface.GetTextSize(status)
            local bx = x + w - tw - 44
            surface.SetDrawColor(statusCol.r, statusCol.g, statusCol.b, 30)
            surface.DrawRect(bx, y + 18, tw + 24, 34)
            surface.SetDrawColor(statusCol.r, statusCol.g, statusCol.b, 170)
            surface.DrawOutlinedRect(bx, y + 18, tw + 24, 34, 2)
            draw.SimpleText(status, "GARLog_W_Small", bx + 12, y + 35, statusCol, 0, 1)
        end

        local cy = y + 100
        if hpFrac then
            UI.Bar(x + 22, cy, w - 44, 14, hpFrac, hpCol or C.green)
            cy = cy + 34
        end
        for _, ln in ipairs(lines) do
            if ln[3] then
                draw.SimpleText(ln[1], "GARLog_W_Small", x + 22, cy + 6, ln[2] or C.text, 0, 1)
                UI.Bar(x + w - 222, cy, 200, 12, ln[3], ln[4] or C.yellow)
            else
                draw.SimpleText(ln[1], "GARLog_W_Small", x + 22, cy + 6, ln[2] or C.text, 0, 1)
            end
            cy = cy + 38
        end
        if bars then
            local n = #GARLog.ResOrder
            local bw = (w - 44 - (n - 1) * 10) / n
            for i, res in ipairs(GARLog.ResOrder) do
                local r = GARLog.Res[res]
                local bx = x + 22 + (i - 1) * (bw + 10)
                local frac = bars[res] or 0
                local _, st = GARLog.SupplyStatus(frac)
                surface.SetDrawColor(C.barBG)
                surface.DrawRect(bx, cy, bw, 70)
                local fh = math.floor(70 * math.Clamp(frac, 0, 1))
                surface.SetDrawColor(st.color.r, st.color.g, st.color.b, 200)
                surface.DrawRect(bx, cy + 70 - fh, bw, fh)
                draw.SimpleText(r.short, "GARLog_W_Small", bx + bw / 2, cy + 90, C.soft, 1, 1)
            end
        end
    cam.End3D2D()
    surface.SetAlphaMultiplier(1)
end

---------------------------------------------------------------------------
-- Strukturen
---------------------------------------------------------------------------
function GARLog.DrawStructure(ent)
    if not WantsPanel(ent) then return end
    local a = FadeAlpha(ent:GetPos())
    if not a then return end
    local def = ent:GetDef()
    local hp = ent:GetHP() / math.max(1, ent:GetMaxHP())

    local status, scol
    if ent:GetDestroyed() then
        status, scol = "ZERSTÖRT", C.red
    elseif def.needsPower and not ent:GetPowered() then
        status, scol = "KEIN STROM", C.orange
    elseif hp < 0.5 then
        status, scol = "BESCHÄDIGT", C.orange
    else
        status, scol = "EINSATZBEREIT", C.green
    end

    local lines = ent:InfoLines() or {}
    local bars
    if ent.ShowSupplyBars then
        local id = ent:GetNW2Int("GARLogFOB", 0)
        if id > 0 then bars = GARLog.GetLocStatus("fob_" .. id) end
    end
    local _, hpSt = GARLog.SupplyStatus(hp)
    DrawPanel(ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z + 20), a, string.upper(def.name or "Struktur"),
        ent:GetFOBName(), status, scol, hp, hpSt.color, lines, bars)
end

---------------------------------------------------------------------------
-- Baustellen (Hologramm)
---------------------------------------------------------------------------
local wire = Material("models/wireframe")

function GARLog.DrawSite(ent)
    local p = ent:GetProgress()
    local d2 = EyePos():DistToSqr(ent:GetPos())

    render.SetColorModulation(0.35, 0.65, 1)
    render.SetBlend(0.2 + p * 0.45)
    ent:DrawModel()
    if d2 < 600 * 600 then
        render.MaterialOverride(wire)
        render.SetBlend(0.5)
        ent:DrawModel()
        render.MaterialOverride()
    end
    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)

    if not WantsPanel(ent) then return end
    local a = FadeAlpha(ent:GetPos())
    if not a then return end
    DrawPanel(ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z + 20), a, "BAUSTELLE: " .. string.upper(ent:GetTitle()),
        ent:GetNW2Int("GARLogFOB", 0) > 0 and GARLog.FOBName(ent:GetNW2Int("GARLogFOB", 0)) or "",
        math.floor(p * 100) .. "%", C.cyan, p, C.cyan,
        { { "DATAPAD: LMB HALTEN ZUM AUFBAUEN", C.soft } })
end

---------------------------------------------------------------------------
-- Frachtcontainer
---------------------------------------------------------------------------
function GARLog.DrawContainer(ent)
    if not WantsPanel(ent) then return end
    local a = FadeAlpha(ent:GetPos())
    if not a then return end
    local lines = {
        { GARLog.UI.Truncate(ent:GetSummary(), "GARLog_W_Small", 556), C.white },
        { "VON: " .. ent:GetSrcName(), C.soft },
    }
    if ent:GetDestName() ~= "" then lines[#lines + 1] = { "ZIEL: " .. ent:GetDestName(), C.yellow } end

    local status, scol = "BEREIT", C.green
    if ent:GetAttached() then status, scol = "GEKOPPELT", C.cyan end
    local unload = ent:GetUnloadEnd()
    if unload > CurTime() then
        local frac = 1 - (unload - CurTime()) / cfg.Container.UnloadTime
        status, scol = "ENTLADEN " .. math.floor(frac * 100) .. "%", C.cyan
        lines[#lines + 1] = { "WIRD ENTLADEN...", C.cyan, frac, C.cyan }
    else
        lines[#lines + 1] = { "E: INHALT / ENTLADEN", C.soft }
    end
    local vol = ent:GetVolume() / math.max(1, cfg.Container.Capacity)
    DrawPanel(ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z + 20), a, "FRACHTCONTAINER C-" .. ent:GetContainerID(),
        GARLog.FmtNum(ent:GetVolume()) .. " / " .. GARLog.FmtNum(cfg.Container.Capacity) .. " FE",
        status, scol, vol, C.yellow, lines)
end

---------------------------------------------------------------------------
-- Terminal & Frachtrampe
---------------------------------------------------------------------------
function GARLog.DrawTerminal(ent)
    if not WantsPanel(ent) then return end
    local a = FadeAlpha(ent:GetPos())
    if not a then return end
    local id = ent:GetLocationID()
    local def = GARLog.StaticLoc[id]
    DrawPanel(ent:GetPos() + Vector(0, 0, ent:OBBMaxs().z + 20), a, "LOGISTIK-TERMINAL",
        def and string.upper(def.name) or "KEIN STANDORT ZUGEWIESEN", nil, nil, nil, nil,
        { { "E: LOGISTIKKONSOLE ÖFFNEN", C.soft } }, GARLog.GetLocStatus(id))
end

local padYellow = Color(252, 178, 73, 200)
function GARLog.DrawCargoPad(ent)
    if EyePos():DistToSqr(ent:GetPos()) > 800 * 800 then return end
    local mi, ma = ent:OBBMins(), ent:OBBMaxs()
    local scale = 0.25
    local w, h = (ma.x - mi.x) / scale, (ma.y - mi.y) / scale
    local pos = ent:LocalToWorld(Vector(mi.x, ma.y, ma.z + 0.3))
    local ang = ent:LocalToWorldAngles(Angle(0, 0, 0))
    cam.Start3D2D(pos, ang, scale)
        surface.SetDrawColor(padYellow)
        for i = 0, 5 do surface.DrawOutlinedRect(i, i, w - i * 2, h - i * 2, 1) end
        for i = 0, 3 do
            local o = i * 26
            surface.DrawRect(o + 16, 16, 14, 40)
            surface.DrawRect(w - o - 30, h - 56, 14, 40)
        end
        draw.SimpleText("FRACHTRAMPE", "GARLog_W_Title", w / 2, h / 2 - 26, padYellow, 1, 1)
        local def = GARLog.StaticLoc[ent:GetLocationID()]
        draw.SimpleText(def and string.upper(def.name) or "—", "GARLog_W_Text", w / 2, h / 2 + 30, C.white, 1, 1)
    cam.End3D2D()
end

---------------------------------------------------------------------------
-- Feldbasen-Liste (Global, immer verfügbar)
---------------------------------------------------------------------------
local fobCache = { raw = nil, list = {} }
function GARLog.FOBList()
    local raw = GetGlobal2String("GARLog_FOBs", "")
    if raw == fobCache.raw then return fobCache.list end
    local list = {}
    for part in string.gmatch(raw, "[^;]+") do
        local id, x, y, z, r, pw, an, name = part:match("^(%d+)|([%-%d]+)|([%-%d]+)|([%-%d]+)|(%d+)|(%d)|(%d)|(.*)$")
        if id then
            list[#list + 1] = {
                id = tonumber(id), pos = Vector(tonumber(x), tonumber(y), tonumber(z)), r = tonumber(r),
                pw = pw == "1", an = an == "1", name = name,
            }
        end
    end
    fobCache.raw, fobCache.list = raw, list
    return list
end

function GARLog.FOBName(id)
    for _, f in ipairs(GARLog.FOBList()) do
        if f.id == id then return f.name end
    end
    return ""
end

function GARLog.FOBAtPos(pos)
    local best, bd
    for _, f in ipairs(GARLog.FOBList()) do
        local d = pos:DistToSqr(f.pos)
        if d <= f.r * f.r and (not bd or d < bd) then best, bd = f, d end
    end
    return best
end

---------------------------------------------------------------------------
-- HUD: aktuelle Feldbasis & Wegpunkte
---------------------------------------------------------------------------
local curFOB, nextCheck = nil, 0

hook.Add("HUDPaint", "GARLog_HUD", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    -- Wegpunkte (übernommene Reparaturaufträge & eigene Markierungen)
    if next(GARLog.Waypoints) then
        for id, wp in pairs(GARLog.Waypoints) do
            local ent = (wp.ent or 0) > 0 and Entity(wp.ent) or nil
            local pos = IsValid(ent) and ent:WorldSpaceCenter() or wp.pos
            local dist = lp:GetPos():Distance(pos)
            if wp.auto and dist < 180 then
                GARLog.Waypoints[id] = nil   -- Markierung erreicht
            else
                local sp = pos:ToScreen()
                if sp.visible then
                    local x, y = sp.x, sp.y
                    local col = wp.auto and C.yellow or C.cyan
                    local pulse = 6 + math.sin(CurTime() * 5) * 2
                    surface.SetDrawColor(col)
                    draw.NoTexture()
                    surface.DrawPoly({ { x = x, y = y - pulse - 6 }, { x = x + pulse + 6, y = y }, { x = x, y = y + pulse + 6 }, { x = x - pulse - 6, y = y } })
                    draw.SimpleTextOutlined(wp.label or ("R-" .. tostring(id)), "GARLog_Section", x, y - 26, col, 1, 1, 1, color_black)
                    draw.SimpleTextOutlined((wp.title or "") .. "  –  " .. math.floor(dist * 0.01905) .. " M", "GARLog_Small", x, y + 24, C.white, 1, 1, 1, color_black)
                end
            end
        end
    end

    if not cfg.FOBHud then return end
    local now = CurTime()
    if now > nextCheck then
        nextCheck = now + 0.5
        curFOB = GARLog.FOBAtPos(lp:GetPos())
    end
    if not curFOB then return end

    local w, h = 250, 66
    local x, y = ScrW() - w - 20, math.floor(ScrH() * 0.28)
    surface.SetDrawColor(C.bg)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(C.line)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(C.yellow)
    surface.DrawRect(x, y, 2, h)
    draw.SimpleText(string.upper(curFOB.name), "GARLog_Head", x + 12, y + 16, C.white, 0, 1)
    draw.SimpleText("FELDBASIS", "GARLog_Tiny", x + w - 10, y + 16, C.yellow, 2, 1)

    local tx = x + 12
    tx = tx + UI.Tag(curFOB.pw and "STROM" or "KEIN STROM", tx, y + 44, curFOB.pw and C.green or C.red) + 6
    tx = tx + UI.Tag(curFOB.an and "FUNK" or "KEIN FUNK", tx, y + 44, curFOB.an and C.green or C.orange) + 6
    local st = GARLog.GetLocStatus("fob_" .. curFOB.id)
    local worst = 1
    for _, res in ipairs(cfg.KeyResources) do worst = math.min(worst, st[res] or 0) end
    local _, sd = GARLog.SupplyStatus(worst)
    UI.Tag(sd.name, tx, y + 44, sd.color)
end)

---------------------------------------------------------------------------
-- Laufzeitmessung (garlog_perf_cl)
---------------------------------------------------------------------------
for _, name in ipairs({ "DrawStructure", "DrawSite", "DrawContainer", "DrawTerminal", "DrawCargoPad" }) do
    GARLog[name] = GARLog.Timed("3D: " .. name, GARLog[name])
end
do
    local hooks = hook.GetTable()
    hook.Add("HUDPaint", "GARLog_HUD", GARLog.Timed("HUD (Feldbasis/Wegpunkte)", hooks.HUDPaint.GARLog_HUD))
    hook.Add("Think", "GARLog_PanelFocus", GARLog.Timed("Infotafel-Fokus", hooks.Think.GARLog_PanelFocus))
end