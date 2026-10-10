--[[
    EoC Range – Client: Schriften, Farben, Synchronisation, HUD (Countdown, Live-Wertung, Banner)
    Design wie Funksystem und ShipTech: dunkle flache Panels, gelber Akzent, Bebas Neue / Montserrat.
]]

local C = EoCRange.Config

---------------------------------------------------------------------------
-- Schriften
---------------------------------------------------------------------------
local function Bebas(name, size)
    surface.CreateFont(name, { font = "Bebas Neue", size = size, weight = 400, antialias = true, extended = true })
end
local function Mont(name, size, weight)
    surface.CreateFont(name, { font = "Montserrat", size = size, weight = weight or 500, antialias = true, extended = true })
end

Bebas("EoCR_HoloTitle", 58)
Mont("EoCR_HoloText", 26, 600)
Mont("EoCR_HoloSmall", 21, 600)
Bebas("EoCR_HoloBig", 130)
Bebas("EoCR_HoloMed", 48)
Bebas("EoCR_UITitle", 34)
Mont("EoCR_UI", 16, 500)
Mont("EoCR_UISmall", 13, 500)
Bebas("EoCR_UIBold", 22)
Bebas("EoCR_UIBig", 64)
Bebas("EoCR_UIMed", 30)
Mont("EoCR_UISub", 12, 600)
Mont("EoCR_UISection", 13, 700)
Bebas("EoCR_HUD", 30)
Bebas("EoCR_HUDBig", 96)
Mont("EoCR_HUDSmall", 14, 600)
Bebas("EoCR_BoardTitle", 110)
Bebas("EoCR_BoardMed", 72)
Mont("EoCR_BoardText", 46, 600)
Mont("EoCR_BoardSmall", 34, 600)
Mont("EoCR_Ring", 18, 700)
surface.CreateFont("EoCR_Aurebesh", { font = "Aurebesh", size = 22, weight = 400, antialias = true, extended = true })
surface.CreateFont("EoCR_AurebeshBig", { font = "Aurebesh", size = 40, weight = 400, antialias = true, extended = true })

-- Farbpalette (identisch zum Funksystem / ShipTech)
EoCRange.Colors = {
    yellow  = Color(255, 190, 50),
    yellowD = Color(255, 190, 50, 56),
    yellowF = Color(255, 190, 50, 20),
    white   = Color(244, 241, 233),
    text    = Color(216, 219, 225),
    soft    = Color(157, 163, 173),
    muted   = Color(101, 107, 117),
    bg      = Color(7, 9, 12, 240),
    panel   = Color(8, 11, 15, 220),
    panel2  = Color(14, 18, 23, 235),
    line    = Color(207, 216, 228, 38),
    lineS   = Color(207, 216, 228, 77),
    red     = Color(225, 88, 88),
    green   = Color(74, 203, 130),
    blue    = Color(90, 170, 255),
    cyan    = Color(80, 200, 220),
    orange  = Color(255, 140, 60),
}
local P = EoCRange.Colors

---------------------------------------------------------------------------
-- Zustand
---------------------------------------------------------------------------
EoCRange.ClientBoards = EoCRange.ClientBoards or {}
EoCRange.ClientOverall = EoCRange.ClientOverall or {}
EoCRange.Holes = EoCRange.Holes or {}

function EoCRange.GetBadge(ply)
    return IsValid(ply) and ply:GetNW2Int("EoCR_Badge", 0) or 0
end

function EoCRange.HasTrophy(ply)
    local unit = GetGlobal2String("EoCR_TrophyUnit", "")
    return IsValid(ply) and unit ~= "" and ply:GetNW2String("EoCR_Unit", "") == unit
end

-- Für das TAB-Menü: Abzeichen-Kürzel und Farbe (nil = kein Abzeichen)
function EoCRange.TabBadge(ply)
    local lvl = EoCRange.GetBadge(ply)
    if lvl < 1 then return nil end
    local short = { "I", "II", "III" }
    return short[lvl], C.BadgeColors[lvl], EoCRange.BadgeName(lvl)
end

-- Kleines Symbol neben dem Namen zeichnen (für EoC TAB / andere Scoreboards). Gibt die benutzte Breite zurück.
function EoCRange.DrawTabIcons(ply, x, y, size)
    size = size or 16
    local used = 0
    local short, col = EoCRange.TabBadge(ply)
    if short then
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(x, y, size + 6, size, 1)
        draw.SimpleText(short, "EoCR_UISub", x + (size + 6) / 2, y + size / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        used = used + size + 10
    end
    if EoCRange.HasTrophy(ply) then
        EoCRange.DrawTrophy(x + used + size / 2, y + size / 2, size * 0.5, P.yellow)
        used = used + size + 4
    end
    return used
end

---------------------------------------------------------------------------
-- Netzwerk
---------------------------------------------------------------------------
local R = EoCRange.Receive

R("init", function(d)
    EoCRange.ApplySettings(d.settings)
    EoCRange.Custom = d.customs or {}
    EoCRange.ClientBoards = d.boards or {}
    EoCRange.ClientOverall = d.overall or {}
    hook.Run("EoCRange_Synced")
end)

R("customs", function(d)
    EoCRange.Custom = d.customs or {}
    hook.Run("EoCRange_Synced")
end)

R("settings", function(d)
    EoCRange.ApplySettings(d)
    hook.Run("EoCRange_Synced")
end)

R("board", function(d)
    if d.d then EoCRange.ClientBoards[d.d] = d.b end
    EoCRange.ClientOverall = d.o or EoCRange.ClientOverall
    hook.Run("EoCRange_BoardUpdated", d.d)
end)

R("notify", function(d)
    local typ = d.k == 1 and NOTIFY_ERROR or (d.k == 2 and NOTIFY_GENERIC or NOTIFY_HINT)
    notification.AddLegacy(tostring(d.t or ""), typ, 5)
    surface.PlaySound(d.k == 1 and "buttons/button10.wav" or "buttons/button15.wav")
end)

R("chat", function(d)
    if d.k == "unit" then
        chat.AddText(C.ChatPrefixColor, C.ChatPrefix, P.yellow, "[Schießstand] ", P.white, tostring(d.t or ""))
    else
        chat.AddText(C.ChatPrefixColor, C.ChatPrefix, P.white, tostring(d.t or ""))
    end
    surface.PlaySound("buttons/button9.wav")
end)

R("hole", function(d)
    local list = EoCRange.Holes[d.e]
    if not list then
        list = {}
        EoCRange.Holes[d.e] = list
    end
    list[#list + 1] = { u = d.u, v = d.v, r = d.r, t = CurTime() }
    if #list > 60 then table.remove(list, 1) end
end)

R("clearholes", function(d)
    for idx in pairs(EoCRange.Holes) do
        local e = Entity(idx)
        if not IsValid(e) or (e.GetLane and e:GetLane() == d.lane) then EoCRange.Holes[idx] = nil end
    end
end)

-- Abgelaufene Löcher wegräumen
timer.Create("EoCRange_Holes", 1, 0, function()
    local limit = CurTime() - C.HoleLifetime
    for idx, list in pairs(EoCRange.Holes) do
        local keep = {}
        for _, h in ipairs(list) do
            if h.t > limit then keep[#keep + 1] = h end
        end
        EoCRange.Holes[idx] = #keep > 0 and keep or nil
    end
end)

---------------------------------------------------------------------------
-- Lauf-Zustand und HUD
---------------------------------------------------------------------------
local run          -- aktueller Lauf (eigener oder als Prüfer beobachtet)
local banner       -- { t, s, start }
local toast        -- { text, sub, start }
local lastBeep

R("runstate", function(d)
    if d.state == "aborted" then
        run = { state = "aborted", reason = d.reason, untilT = CurTime() + 4 }
        surface.PlaySound(C.Sounds.abort)
        return
    end
    if d.state == "done" then
        run = nil
        return
    end
    run = run and run.state ~= "aborted" and run or {}
    for k, v in pairs(d) do run[k] = v end
    if d.state == "running" or d.state == "ready" then
        surface.PlaySound(C.Sounds.go)
    end
end)

R("live", function(d)
    if not run then return end
    run.live, run.hits, run.shots, run.shotHits = d.live, d.hits, d.shots, d.shotHits
end)

R("result", function(d)
    run = nil
    toast = { text = d.name .. ": " .. tostring(d.valueText), sub = "Platz " .. (d.unitRank or "–") .. " in " .. (d.unitName or "der Einheit")
        .. " · Platz " .. (d.serverRank or "–") .. " auf dem Server", start = CurTime() }
    EoCRange.LastResult = d
    if EoCRange.UI and EoCRange.UI.OpenResult then EoCRange.UI.OpenResult(d) end
end)

R("banner", function(d)
    banner = { t = d.t, s = d.s, lvl = d.lvl, start = CurTime() }
    surface.PlaySound(C.Sounds.best)
end)

function EoCRange.ClientRun() return run end

local function Panel(x, y, w, h, accent)
    surface.SetDrawColor(P.bg)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(P.line)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(accent or P.yellow)
    surface.DrawRect(x, y, 14, 2)
    surface.DrawRect(x, y, 2, 14)
    surface.DrawRect(x + w - 14, y + h - 2, 14, 2)
    surface.DrawRect(x + w - 2, y + h - 14, 2, 14)
end
EoCRange.HudPanel = Panel

hook.Add("HUDPaint", "EoCRange_HUD", function()
    local now = CurTime()
    local sw = ScrW()

    if run then
        if run.state == "aborted" then
            if now > (run.untilT or 0) then
                run = nil
            else
                local w, h = 460, 70
                local x, y = sw / 2 - w / 2, 40
                Panel(x, y, w, h, P.red)
                draw.SimpleText("LAUF ABGEBROCHEN", "EoCR_HUD", sw / 2, y + 22, P.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(run.reason or ""), "EoCR_HUDSmall", sw / 2, y + 50, P.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        else
            local w, h = 420, 120
            local x, y = sw / 2 - w / 2, 30
            Panel(x, y, w, h)
            draw.SimpleText(string.upper(run.name or "Lauf"), "EoCR_HUD", x + 16, y + 20, P.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("BAHN " .. tostring(run.lane or "?") .. (run.exam and "  //  PRÜFUNG" or ""), "EoCR_UISub", x + w - 16, y + 20, P.yellow, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(P.yellowD)
            surface.DrawRect(x, y + 38, w, 1)

            if run.state == "countdown" then
                local left = math.ceil((run.startAt or now) - now)
                if left ~= lastBeep and left > 0 then
                    lastBeep = left
                    surface.PlaySound(C.Sounds.countdown)
                end
                draw.SimpleText(left > 0 and tostring(left) or "LOS", "EoCR_HUDBig", sw / 2, y + 80, P.yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif run.state == "ready" then
                draw.SimpleText("STARTZONE VERLASSEN", "EoCR_HUD", sw / 2, y + 66, P.green, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Die Zeit läuft, sobald du die Startzone verlässt.", "EoCR_HUDSmall", sw / 2, y + 96, P.soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                lastBeep = nil
                local elapsed = now - (run.t0 or now)
                local live = run.live
                if run.scoring == "time" then live = string.format("%.1f s", elapsed) end
                draw.SimpleText(tostring(live or "0"), "EoCR_HUDBig", x + 16, y + 82, P.yellow, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                local shotsLine = "Schüsse " .. (run.shots or 0)
                if run.mode == "rings" then shotsLine = "Schuss " .. (run.shots or 0) .. " / " .. (run.shotsTotal or 10) end
                draw.SimpleText(shotsLine, "EoCR_HUDSmall", x + w - 16, y + 62, P.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                draw.SimpleText("Treffer " .. (run.hits or 0) .. (run.count and run.count > 0 and (" / " .. run.count) or ""), "EoCR_HUDSmall", x + w - 16, y + 84, P.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                if run.scoring == "time" and run.live then
                    draw.SimpleText("inkl. Strafen: " .. tostring(run.live), "EoCR_HUDSmall", x + w - 16, y + 106, P.soft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText(string.format("%.1f s", elapsed), "EoCR_HUDSmall", x + w - 16, y + 106, P.soft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end
        end
    end

    -- Ergebnis kurz im HUD
    if toast then
        local t = now - toast.start
        if t > 7 then
            toast = nil
        else
            local a = math.Clamp(math.min(t * 4, (7 - t) * 2), 0, 1)
            surface.SetAlphaMultiplier(a)
            local w, h = 520, 64
            local x, y = sw / 2 - w / 2, 30
            Panel(x, y, w, h)
            draw.SimpleText(string.upper(toast.text), "EoCR_HUD", sw / 2, y + 22, P.yellow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(toast.sub, "EoCR_HUDSmall", sw / 2, y + 47, P.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetAlphaMultiplier(1)
        end
    end

    -- Banner (neue Bestleistung / Abzeichen) nur für den Schützen
    if banner then
        local t = now - banner.start
        if t > 4.5 then
            banner = nil
        else
            local a = math.Clamp(math.min(t * 3, (4.5 - t) * 2), 0, 1)
            local slide = (1 - math.min(t * 3, 1)) * 40
            surface.SetAlphaMultiplier(a)
            local w, h = 560, 96
            local x, y = sw / 2 - w / 2, ScrH() * 0.22 - slide
            local col = banner.lvl and C.BadgeColors[banner.lvl] or P.yellow
            Panel(x, y, w, h, col)
            surface.SetDrawColor(col)
            surface.DrawRect(x, y + h - 3, w, 3)
            draw.SimpleText(banner.t, "EoCR_UIBig", sw / 2, y + 38, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(banner.s or "", "EoCR_UI", sw / 2, y + 76, P.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetAlphaMultiplier(1)
        end
    end
end)
