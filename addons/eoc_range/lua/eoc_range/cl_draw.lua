--[[
    EoC Range – Zeichnen: Ringscheibe, Silhouetten, Hologramme über den Terminals, Ranglisten-Wand, Zonen
]]

local C = EoCRange.Config
local P = EoCRange.Colors

local HOLO  = P.yellow
local TEXT  = P.white
local DIM   = P.soft
local RED   = P.red
local GREEN = P.green

---------------------------------------------------------------------------
-- Grundformen
---------------------------------------------------------------------------
local circleCache = {}

local function CirclePoly(x, y, r, seg)
    seg = seg or 48
    local key = x .. ":" .. y .. ":" .. r .. ":" .. seg
    local c = circleCache[key]
    if c then return c end
    c = { { x = x, y = y } }
    for i = 0, seg do
        local a = math.rad((i / seg) * -360)
        c[#c + 1] = { x = x + math.sin(a) * r, y = y + math.cos(a) * r }
    end
    circleCache[key] = c
    return c
end

function EoCRange.FillCircle(x, y, r, col, seg)
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly(CirclePoly(x, y, r, seg))
end

-- kleiner Pokal (für TAB und Wand)
function EoCRange.DrawTrophy(cx, cy, s, col)
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawRect(cx - s * 0.7, cy - s, s * 1.4, s * 0.9)
    EoCRange.FillCircle(cx, cy - s * 0.1, s * 0.7, col, 16)
    surface.DrawRect(cx - s * 0.15, cy + s * 0.4, s * 0.3, s * 0.35)
    surface.DrawRect(cx - s * 0.55, cy + s * 0.72, s * 1.1, s * 0.28)
end

-- 3D2D-Winkel für eine Fläche, deren Normale lokal +X ist (x nach rechts, y nach unten aus Sicht des Schützen)
local function FaceAngle(ang)
    local a = Angle(ang.p, ang.y, ang.r)
    a:RotateAroundAxis(a:Up(), 90)
    a:RotateAroundAxis(a:Forward(), 90)
    return a
end
EoCRange.FaceAngle = FaceAngle

local function BackAngle(ang)
    local a = Angle(ang.p, ang.y, ang.r)
    a:RotateAroundAxis(a:Up(), -90)
    a:RotateAroundAxis(a:Forward(), 90)
    return a
end

local function NearEnough(ent, dist)
    return EyePos():DistToSqr(ent:GetPos()) < dist * dist
end

local function HoleAlpha(h)
    local left = C.HoleLifetime - (CurTime() - h.t)
    return math.Clamp(left, 0, 1)
end

---------------------------------------------------------------------------
-- Ringscheibe
---------------------------------------------------------------------------
local PAPER = Color(226, 222, 208)
local INK   = Color(24, 26, 30)

function EoCRange.DrawRingTarget(ent)
    if not NearEnough(ent, 4000) then return end
    local scale = 0.1
    local half = ent:HalfSize()
    local center = ent:Center()
    local R = half / scale
    local ang = ent:GetAngles()

    cam.Start3D2D(ent:LocalToWorld(Vector(1.05, 0, center)), FaceAngle(ang), scale)
        -- Papier
        surface.SetDrawColor(PAPER)
        surface.DrawRect(-R, -R, R * 2, R * 2)
        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawOutlinedRect(-R, -R, R * 2, R * 2, 2)

        -- Ringe von außen nach innen; 7–10 schwarz
        for ring = 1, 10 do
            local r = R * (11 - ring) / 10
            local dark = ring >= 7
            EoCRange.FillCircle(0, 0, r, dark and INK or PAPER, 48)
            surface.DrawCircle(0, 0, r, dark and 200 or 30, dark and 200 or 30, dark and 200 or 30, 255)
        end

        -- Ringzahlen
        for ring = 1, 8 do
            local r = R * (11 - ring) / 10 - R * 0.05
            local col = ring >= 7 and PAPER or INK
            draw.SimpleText(ring, "EoCR_Ring", -r, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(ring, "EoCR_Ring", r, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        surface.SetDrawColor(PAPER)
        surface.DrawRect(-4, -0.5, 8, 1)
        surface.DrawRect(-0.5, -4, 1, 8)

        -- Einschusslöcher
        local holes = EoCRange.Holes[ent:EntIndex()]
        if holes then
            for _, h in ipairs(holes) do
                local a = HoleAlpha(h)
                local x, y = h.u * R, -h.v * R
                EoCRange.FillCircle(x, y, 5, Color(255, 190, 50, 255 * a), 12)
                EoCRange.FillCircle(x, y, 3.2, Color(10, 10, 10, 255 * a), 12)
            end
        end

        -- Ständer bis zum Boden
        local below = (center - half) / scale
        surface.SetDrawColor(70, 74, 80)
        surface.DrawRect(-R * 0.75, R, 12, below)
        surface.DrawRect(R * 0.75 - 12, R, 12, below)
    cam.End3D2D()

    cam.Start3D2D(ent:LocalToWorld(Vector(-1.05, 0, center)), BackAngle(ang), scale)
        surface.SetDrawColor(52, 56, 62)
        surface.DrawRect(-R, -R, R * 2, R * 2)
        draw.SimpleText("BAHN " .. ent:GetLane(), "EoCR_HoloSmall", 0, 0, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

---------------------------------------------------------------------------
-- Silhouetten (Maße in Units, Ursprung unten Mitte: x, z, Breite, Höhe)
---------------------------------------------------------------------------
local SHAPES = {
    b1 = {
        col = Color(196, 168, 120), dark = Color(120, 98, 66),
        rects = {
            { -6, 0, 3, 34 }, { 3, 0, 3, 34 }, { -6, 32, 12, 6 }, { -5, 38, 10, 19 }, { -10, 40, 3, 18 }, { 7, 40, 3, 18 },
            { -1, 57, 2, 5 }, { -3, 62, 6, 12 },
        },
    },
    b2 = {
        col = Color(92, 104, 122), dark = Color(52, 60, 72),
        rects = {
            { -12, 0, 8, 36 }, { 4, 0, 8, 36 }, { -14, 36, 28, 30 }, { -18, 38, 6, 26 }, { 12, 38, 6, 26 }, { -6, 66, 12, 16 },
        },
    },
    bx = {
        col = Color(62, 58, 54), dark = Color(30, 28, 26),
        rects = {
            { -7, 0, 4, 38 }, { 3, 0, 4, 38 }, { -7, 38, 14, 22 }, { -11, 40, 4, 20 }, { 7, 40, 4, 20 }, { -1.5, 60, 3, 4 }, { -4, 64, 8, 12 },
        },
    },
    clone = {
        col = Color(232, 232, 228), dark = Color(60, 110, 200),
        rects = {
            { -7, 0, 6, 34 }, { 1, 0, 6, 34 }, { -8, 34, 16, 24 }, { -12, 36, 4, 20 }, { 8, 36, 4, 20 }, { -5, 58, 10, 14 },
        },
    },
}

EoCRange.Shapes = SHAPES

local function ShapeFor(ent)
    local s = ent:Shape()
    return s, SHAPES[s.id] or SHAPES.b1
end

function EoCRange.DrawSilhouetteTarget(ent)
    if not NearEnough(ent, 4000) then return end
    local s, shape = ShapeFor(ent)
    local f = ent:UpFraction()
    local scale = 0.1
    local rot = ent:LocalToWorldAngles(Angle(-90 * (1 - f), 0, 0))   -- fällt nach hinten um
    local pos = ent:GetPos() + rot:Forward() * 1.05
    local function R2(x, z, w, h) surface.DrawRect(x / scale, -(z + h) / scale, w / scale, h / scale) end

    -- Echtes Model (z. B. B1-Droide): mit Idle-Animation zeichnen und um die Füße kippen
    if ent.UsesModel and ent:UsesModel() then
        if not ent._idleSeq then
            ent._idleSeq = 0
            for _, name in ipairs(C.TargetIdleSequences) do
                local seq = ent:LookupSequence(name)
                if seq and seq >= 0 then
                    ent._idleSeq = seq
                    break
                end
            end
            if ent._idleSeq > 0 then
                ent:ResetSequence(ent._idleSeq)
                ent:SetPlaybackRate(1)
            end
        end
        if ent._idleSeq > 0 then ent:FrameAdvance() end
        ent:SetRenderAngles(rot)
        ent:DrawModel()

        local holes = EoCRange.Holes[ent:EntIndex()]
        if holes then
            cam.Start3D2D(ent:GetPos() + rot:Forward() * 8, FaceAngle(rot), scale)
                for _, h in ipairs(holes) do
                    local a = HoleAlpha(h)
                    local x, y = h.u * (s.w / 2) / scale, -h.v * s.h / scale
                    EoCRange.FillCircle(x, y, 6, Color(255, 190, 50, 255 * a), 12)
                    EoCRange.FillCircle(x, y, 3.5, Color(10, 10, 10, 255 * a), 12)
                end
            cam.End3D2D()
        end
    else

    cam.Start3D2D(pos, FaceAngle(rot), scale)
        surface.SetDrawColor(shape.col)
        for _, r in ipairs(shape.rects) do R2(r[1], r[2], r[3], r[4]) end

        -- Kopfzone dezent markieren
        local headZ = s.h * C.HeadZone
        surface.SetDrawColor(shape.dark.r, shape.dark.g, shape.dark.b, 120)
        surface.DrawRect(-s.w / 2 / scale, -headZ / scale, s.w / scale, 2)

        if ent.IsHostage then
            -- Klonhelm mit T-Visier und blauer Markierung
            surface.SetDrawColor(20, 22, 26)
            R2(-3.5, 64, 7, 2)
            R2(-1, 59.5, 2, 5)
            surface.SetDrawColor(shape.dark)
            R2(-8, 46, 16, 3)
            draw.SimpleText("GEISEL", "EoCR_HoloSmall", 0, -42 / scale, RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            -- Optik/Fotorezeptor
            surface.SetDrawColor(shape.dark)
            R2(-1.5, s.h - 6, 3, 3)
        end

        local holes = EoCRange.Holes[ent:EntIndex()]
        if holes then
            for _, h in ipairs(holes) do
                local a = HoleAlpha(h)
                local x, y = h.u * (s.w / 2) / scale, -h.v * s.h / scale
                EoCRange.FillCircle(x, y, 5, Color(255, 190, 50, 255 * a), 12)
                EoCRange.FillCircle(x, y, 3.2, Color(10, 10, 10, 255 * a), 12)
            end
        end
    cam.End3D2D()

    cam.Start3D2D(ent:GetPos() - rot:Forward() * 1.05, BackAngle(rot), scale)
        surface.SetDrawColor(48, 52, 58)
        for _, r in ipairs(shape.rects) do surface.DrawRect(-(r[1] + r[3]) / scale, -(r[2] + r[4]) / scale, r[3] / scale, r[4] / scale) end
    cam.End3D2D()
    end

    -- Schiene des bewegten Ziels
    if ent.RangeKind == "mover" then
        local start = ent:GetRailStart()
        local dir = ent:RailDir()
        local a = start + Vector(0, 0, 1)
        local b = a + dir * ent:GetTrack()
        render.DrawLine(a, b, Color(255, 190, 50, 160), true)
        render.DrawLine(a - ent:GetForward() * 3, b - ent:GetForward() * 3, Color(255, 190, 50, 90), true)
    end
end

---------------------------------------------------------------------------
-- Hologramm über dem Terminal
---------------------------------------------------------------------------
local W = 640

local function HoloPanel(x, y, w, h, accent)
    surface.SetDrawColor(7, 9, 12, 225)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(207, 216, 228, 40)
    surface.DrawOutlinedRect(x, y, w, h, 2)
    surface.SetDrawColor(accent)
    surface.DrawRect(x, y, 26, 3)
    surface.DrawRect(x, y, 3, 26)
    surface.DrawRect(x + w - 26, y + h - 3, 26, 3)
    surface.DrawRect(x + w - 3, y + h - 26, 3, 26)
    local sl = (RealTime() * 60) % h
    surface.SetDrawColor(accent.r, accent.g, accent.b, 12)
    surface.DrawRect(x, y + sl, w, 3)
end

local function HoloHeader(x, y, w, title, sub, accent)
    surface.SetDrawColor(14, 18, 23, 235)
    surface.DrawRect(x + 3, y + 3, w - 6, 94)
    draw.SimpleText(string.upper(title), "EoCR_HoloTitle", x + 24, y + 36, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(string.upper("Schießstand // " .. (sub or "")), "EoCR_HoloSmall", x + 25, y + 74, accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(accent.r, accent.g, accent.b, 56)
    surface.DrawRect(x, y + 97, w, 2)
    surface.SetDrawColor(accent)
    surface.DrawRect(x, y + 97, 220, 3)
end

local LANE_TEXT = {
    free     = { "FREI", GREEN, "Terminal benutzen, um einen Lauf zu starten" },
    busy     = { "BELEGT", HOLO, "" },
    reserved = { "RESERVIERT", P.blue, "" },
    locked   = { "GESPERRT", RED, "" },
    exam     = { "PRÜFUNG", P.orange, "" },
    defcon   = { "GEFECHTSBEREITSCHAFT", RED, "Schießstand gesperrt" },
}

function EoCRange.DrawTerminalHolo(ent)
    local lp = LocalPlayer()
    local eye = lp:EyePos()
    local dist = eye:Distance(ent:GetPos())
    if dist > C.HoloDistance then return end

    local fade = math.Clamp((C.HoloDistance - dist) / 150, 0, 1)
    local flick = 0.94 + 0.06 * math.sin(RealTime() * 31)
    local pos = ent:LocalToWorld(Vector(0, 0, ent:OBBMaxs().z)) + Vector(0, 0, ent.HoloOffset or 14)
    local ang = Angle(0, lp:EyeAngles().y - 90, 90)
    local detail = dist < C.HoloDetailDistance and lp:GetAimVector():Dot((pos - eye):GetNormalized()) > 0.75

    local laneState = ent:GetNW2String("EoCR_Lane", "free")
    local runState = ent:GetNW2String("EoCR_State", "")
    local untilT = ent:GetNW2Float("EoCR_Until", 0)
    local now = CurTime()
    local showRun = laneState == "busy" or ((runState == "result" or runState == "aborted") and now < untilT)
    local lt = LANE_TEXT[laneState] or LANE_TEXT.free
    local accent = showRun and (runState == "aborted" and RED or HOLO) or lt[2]

    surface.SetAlphaMultiplier(fade * flick)
    cam.Start3D2D(pos, ang, 0.06)
        local x = -W / 2
        if not detail then
            local h = 150
            HoloPanel(x, -h, W, h, accent)
            draw.SimpleText("BAHN " .. ent:GetLane(), "EoCR_HoloTitle", 0, -h + 50, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            local label = showRun and (runState == "result" and ("ERGEBNIS " .. ent:GetNW2String("EoCR_Live", "")) or ent:GetNW2String("EoCR_Disc", "")) or lt[1]
            draw.SimpleText(string.upper(label), "EoCR_HoloMed", 0, -h + 108, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif showRun then
            local h = 430
            local y = -h
            HoloPanel(x, y, W, h, accent)
            HoloHeader(x, y, W, "Bahn " .. ent:GetLane(), ent:GetNW2String("EoCR_Disc", ""), accent)
            draw.SimpleText(ent:GetNW2String("EoCR_Shooter", ""), "EoCR_HoloText", x + 24, y + 132, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            if runState == "countdown" then
                local left = math.ceil(ent:GetNW2Float("EoCR_StartAt", now) - now)
                draw.SimpleText(left > 0 and tostring(left) or "LOS", "EoCR_HoloBig", 0, y + 270, HOLO, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("COUNTDOWN", "EoCR_HoloSmall", 0, y + 360, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif runState == "ready" then
                draw.SimpleText("BEREIT", "EoCR_HoloBig", 0, y + 270, GREEN, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Zeit startet beim Verlassen der Startzone", "EoCR_HoloSmall", 0, y + 360, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif runState == "result" then
                draw.SimpleText("ERGEBNIS", "EoCR_HoloSmall", 0, y + 190, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(ent:GetNW2String("EoCR_Live", ""), "EoCR_HoloBig", 0, y + 280, HOLO, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Treffer " .. ent:GetNW2Int("EoCR_Hits", 0) .. "  ·  Schüsse " .. ent:GetNW2Int("EoCR_Shots", 0), "EoCR_HoloSmall", 0, y + 370, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif runState == "aborted" then
                draw.SimpleText("ABGEBROCHEN", "EoCR_HoloMed", 0, y + 250, RED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(ent:GetNW2String("EoCR_Live", ""), "EoCR_HoloSmall", 0, y + 310, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                local t0 = ent:GetNW2Float("EoCR_T0", now)
                draw.SimpleText(ent:GetNW2String("EoCR_Live", "0"), "EoCR_HoloBig", 0, y + 260, HOLO, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(string.format("%.1f s", math.max(0, now - t0)), "EoCR_HoloText", x + 24, y + 370, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText("Treffer " .. ent:GetNW2Int("EoCR_Hits", 0) .. "  ·  Schüsse " .. ent:GetNW2Int("EoCR_Shots", 0), "EoCR_HoloText", x + W - 24, y + 370, TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            draw.SimpleText("EOC RANGE", "EoCR_Aurebesh", 0, y + h - 22, ColorAlpha(accent, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            local h = 300
            local y = -h
            HoloPanel(x, y, W, h, accent)
            HoloHeader(x, y, W, "Bahn " .. ent:GetLane(), lt[1], accent)
            draw.SimpleText(lt[1], "EoCR_HoloMed", 0, y + 150, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            local note = ent:GetNW2String("EoCR_LaneNote", "")
            local sub = lt[3]
            if laneState == "reserved" then sub = "Reserviert für " .. note
            elseif laneState == "locked" then sub = note ~= "" and note or "Von einem Ausbilder gesperrt"
            elseif laneState == "exam" then sub = "Prüfer: " .. note
            elseif laneState == "defcon" then sub = "Schießstand gesperrt (" .. note .. ")" end
            draw.SimpleText(sub, "EoCR_HoloSmall", 0, y + 205, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("EOC RANGE", "EoCR_Aurebesh", 0, y + h - 30, ColorAlpha(accent, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    cam.End3D2D()
    surface.SetAlphaMultiplier(1)
end

---------------------------------------------------------------------------
-- Ranglisten-Wand
---------------------------------------------------------------------------
local function Medal(rank)
    if rank == 1 then return HOLO end
    if rank == 2 then return Color(200, 205, 214) end
    if rank == 3 then return Color(196, 140, 90) end
    return DIM
end

function EoCRange.DrawBoard(ent)
    if not NearEnough(ent, C.BoardDistance) then return end
    local scale = 0.05
    local wu, hu = ent:Dimensions()
    local w, h = wu / scale, hu / scale
    local list = ent:DisciplineList()
    if #list == 0 then return end
    local idx = (math.floor(CurTime() / C.BoardCycle) % #list) + 1
    local discId = list[idx]
    local def = EoCRange.GetDiscipline(discId)
    local period = ent:GetPeriod()
    if not EoCRange.PeriodNames[period] then period = "week" end
    local board = EoCRange.ClientBoards[discId] or {}
    local rows = board[period] or {}
    local units = board.units or {}

    cam.Start3D2D(ent:LocalToWorld(Vector(1.1, -wu / 2, hu)), FaceAngle(ent:GetAngles()), scale)
        -- Rahmen
        surface.SetDrawColor(7, 9, 12, 245)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(207, 216, 228, 40)
        surface.DrawOutlinedRect(0, 0, w, h, 4)
        surface.SetDrawColor(HOLO)
        surface.DrawRect(0, 0, 70, 6)
        surface.DrawRect(0, 0, 6, 70)
        surface.DrawRect(w - 70, h - 6, 70, 6)
        surface.DrawRect(w - 6, h - 70, 6, 70)

        -- Kopfzeile
        local head = 210
        surface.SetDrawColor(14, 18, 23, 240)
        surface.DrawRect(6, 6, w - 12, head - 6)
        draw.SimpleText(string.upper(def and def.name or discId), "EoCR_BoardTitle", 60, 90, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("SCHIESSSTAND // RANGLISTE // " .. string.upper(EoCRange.PeriodNames[period]), "EoCR_BoardSmall", 62, 165, HOLO, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        -- Seitenpunkte
        for i = 1, #list do
            local px = w - 60 - (#list - i) * 36
            surface.SetDrawColor(i == idx and HOLO or Color(207, 216, 228, 60))
            surface.DrawRect(px - 10, 160, 20, 10)
        end
        surface.SetDrawColor(HOLO.r, HOLO.g, HOLO.b, 56)
        surface.DrawRect(0, head, w, 4)
        surface.SetDrawColor(HOLO)
        surface.DrawRect(0, head, 600, 6)

        -- Top 10
        local lx, ly, lw = 60, head + 50, w * 0.6 - 90
        local rowH = (h - head - 160) / 10
        draw.SimpleText("TOP 10", "EoCR_BoardSmall", lx, ly, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        ly = ly + 60
        if #rows == 0 then
            draw.SimpleText("Noch keine Ergebnisse", "EoCR_BoardText", lx, ly + 40, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        for i = 1, math.min(#rows, 10) do
            local r = rows[i]
            local y = ly + (i - 1) * rowH
            if i % 2 == 1 then
                surface.SetDrawColor(255, 255, 255, 6)
                surface.DrawRect(lx - 20, y - 6, lw + 40, rowH - 4)
            end
            draw.SimpleText(i .. ".", "EoCR_BoardText", lx, y, Medal(i), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(r.n or "?"), "EoCR_BoardText", lx + 110, y, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(r.un or ""), "EoCR_BoardSmall", lx + lw * 0.62, y + 6, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(EoCRange.Format(def, r.s), "EoCR_BoardText", lx + lw, y, i == 1 and HOLO or TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end

        -- Einheitenwertung (Woche)
        local rx, ry, rw = w * 0.6 + 20, head + 50, w * 0.4 - 80
        surface.SetDrawColor(207, 216, 228, 30)
        surface.DrawRect(rx - 40, head + 40, 3, h - head - 120)
        draw.SimpleText("EINHEITENWERTUNG // WOCHE", "EoCR_BoardSmall", rx, ry, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        ry = ry + 60
        for i = 1, math.min(#units, 6) do
            local u = units[i]
            local y = ry + (i - 1) * 70
            local col = EoCRange.UnitColor(u.u)
            surface.SetDrawColor(col)
            surface.DrawRect(rx, y + 8, 8, 44)
            draw.SimpleText(tostring(u.un or u.u), "EoCR_BoardText", rx + 28, y, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(EoCRange.Format(def, u.v) .. "  (" .. (u.n or 0) .. ")", "EoCR_BoardSmall", rx + rw, y + 6, i == 1 and HOLO or DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
        if #units == 0 then draw.SimpleText("Diese Woche noch keine Wertung", "EoCR_BoardSmall", rx, ry + 10, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP) end

        -- Wochenpokal
        local trophy = GetGlobal2String("EoCR_TrophyName", "")
        local ty = h - 330
        surface.SetDrawColor(14, 18, 23, 240)
        surface.DrawRect(rx - 10, ty, rw + 20, 200)
        surface.SetDrawColor(HOLO)
        surface.DrawRect(rx - 10, ty, 6, 200)
        EoCRange.DrawTrophy(rx + 70, ty + 100, 50, HOLO)
        draw.SimpleText("WOCHENPOKAL", "EoCR_BoardSmall", rx + 160, ty + 50, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(trophy ~= "" and trophy or "noch nicht vergeben", "EoCR_BoardMed", rx + 160, ty + 120, trophy ~= "" and HOLO or DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Fußzeile
        draw.SimpleText("ECHOES OF CLONES // SCHIESSSTAND", "EoCR_AurebeshBig", w / 2, h - 50, Color(255, 190, 50, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

---------------------------------------------------------------------------
-- Zonen: nur mit Physgun/Toolgun in der Hand sichtbar
---------------------------------------------------------------------------
local BUILD_TOOLS = { weapon_physgun = true, gmod_tool = true }

local function Building()
    local w = LocalPlayer():GetActiveWeapon()
    return IsValid(w) and BUILD_TOOLS[w:GetClass()] == true
end

function EoCRange.DrawZone(ent)
    if not Building() then return end
    local mins, maxs = ent:ZoneBounds()
    local col = ent.ZoneColor or HOLO
    render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), mins, maxs, col, true)
    render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), Vector(-6, -6, -6), Vector(6, 6, 6), col, true)

    local label = string.upper(ent.PrintName) .. " – BAHN " .. ent:GetLane()
    local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
    cam.Start3D2D(ent:GetPos() + Vector(0, 0, 24), ang, 0.1)
        draw.SimpleText(label, "EoCR_HoloSmall", 0, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%d x %d x %d", ent:GetSizeX(), ent:GetSizeY(), ent:GetSizeZ()), "EoCR_HoloSmall", 0, 26, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

-- Bahn-Nummern über Zielen anzeigen, solange man baut
hook.Add("PostDrawTranslucentRenderables", "EoCRange_BuildLabels", function(depth, sky)
    if depth or sky or not Building() then return end
    local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
    for _, e in ipairs(ents.FindByClass("range_*")) do
        if e.IsEoCRange and not e.IsRangeZone and e.RangeKind ~= "terminal" and e.RangeKind ~= "board" and NearEnough(e, 1200) then
            local top = e:LocalToWorld(Vector(0, 0, e:OBBMaxs().z + 8))
            local extra = (e.GetDistance and e:GetDistance() > 0) and ("  " .. e:GetDistance() .. " m") or ""
            cam.Start3D2D(top, ang, 0.08)
                draw.SimpleText("BAHN " .. e:GetLane() .. extra, "EoCR_HoloSmall", 0, 0, HOLO, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end)
