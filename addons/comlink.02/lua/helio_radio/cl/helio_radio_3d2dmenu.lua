hradio = hradio or {}

-- Comlink am linken Arm (nur Ego-Perspektive)
-- Der Spieler hebt seinen linken Arm mit dem Comlink (eigene Animation aus c_vmaniphradio_comlink.mdl,
-- mit den Händen des Spielermodells, kein VManip nötig) und über dem Comlink erscheint ein Hologramm
-- im SymChars-Design. Auf dem Comlink laufen "Apps":
--   H = Funk      (dieses File)
--   G = Squad     (helio_radio_squadmenu.lua)
--   J = Textfunk  (crypto_radio/cl_comlink.lua)
--   K = Medic     (helio_radio_medicmenu.lua), zusätzlich Chat-Befehl !medical
-- Es ist immer nur eine App offen: Drückt man eine andere App-Taste, während das Comlink offen ist,
-- wechselt es direkt zu dieser App. Dieselbe Taste nochmal (oder ESC) schließt das Comlink.
-- In der Third Person wird nichts angezeigt.

local MENU_W = 320
local HEADER_H = 56
local CARD_H = 74
local CARD_GAP = 6
local SCROLL_W = 8

-- Zustand überlebt cl_hRadio_Reload, damit kein altes Eingabe-Panel hängen bleibt
HRADIO_COMLINK = HRADIO_COMLINK or {}
local state = HRADIO_COMLINK

state.open = false
state.app = nil
state.openTime = 0
state.scroll = state.scroll or 0
state.click = false
state.animMissingSince = nil

if IsValid(state.panel) then state.panel:Remove() end
state.panel = nil

local function config()
    return hradio.Config or {}
end

-- Konsolenbefehle ganz oben, damit sie immer registriert sind
concommand.Add("hradio_comlink", function()
    if hradio.ToggleComlink then hradio.ToggleComlink("radio") end
end)

concommand.Add("hradio_squad", function()
    if hradio.ToggleComlink then hradio.ToggleComlink("squad") end
end)

concommand.Add("hradio_medic", function()
    if hradio.ToggleComlink and hradio.ComlinkApps and hradio.ComlinkApps.medic then
        hradio.ToggleComlink("medic")
    end
end)

concommand.Add("hradio_comlink_debug", function()
    if hradio.ComlinkDebug then
        hradio.ComlinkDebug()
    else
        print("[hRadio] Comlink-Datei nicht vollständig geladen – bitte Lua-Fehler in der Konsole prüfen.")
    end
end)

local function visibleCount()
    return math.max(1, math.floor(tonumber(config().ComlinkVisibleChannels) or 4))
end

local function playUISound(path)
    if config().UISounds then
        surface.PlaySound(path)
    end
end

-------------------
-- Farben/Fonts --
-------------------

local pal = {}

local function updatePalette()
    local accent = SYMUI and SYMUI.LiveAccent and SYMUI.LiveAccent() or Color(252, 178, 73)
    local col = SYMUI and SYMUI.col or {}

    pal.accent = accent
    pal.accentHi = Color(math.min(accent.r + 20, 255), math.min(accent.g + 20, 255), math.min(accent.b + 30, 255))
    pal.accentSoft = Color(accent.r, accent.g, accent.b, 170)
    pal.accentDim = Color(accent.r, accent.g, accent.b, 56)
    pal.accentFaint = Color(accent.r, accent.g, accent.b, 22)
    pal.amberBg = Color(40, 30, 14, 240)

    pal.bg = Color(9, 11, 14, 245)
    pal.panel = Color(11, 14, 18, 230)
    pal.panel2 = Color(18, 22, 28, 240)
    pal.panel3 = Color(27, 32, 40, 245)
    pal.strip = Color(0, 0, 0, 150)
    pal.scan = Color(0, 0, 0, 40)

    pal.text = col.text or Color(236, 233, 224)
    pal.soft = col.dim or Color(168, 174, 180)
    pal.muted = col.muted or Color(112, 119, 127)
    pal.ink = Color(18, 21, 25)
    pal.line = Color(255, 255, 255, 22)
    pal.line2 = Color(255, 255, 255, 51)

    pal.red = col.red or Color(205, 62, 56)
    pal.redText = Color(224, 122, 116)
    pal.redBg = Color(90, 18, 18, 210)
    pal.redLine = Color(205, 62, 56, 200)
    pal.green = col.green or Color(94, 200, 121)
end

local function fontFace(kind, fallback)
    if SYMUI and SYMUI.FontFace then
        local ok, face = pcall(SYMUI.FontFace, kind)
        if ok and isstring(face) and face ~= "" then return face end
    end

    return fallback
end

-- Schriftgrößen sind 3D2D-Einheiten (werden mit MenuScale skaliert), nicht Bildschirmpixel
local function createFonts()
    local head = fontFace("head", "BigNoodleTitling")
    local body = fontFace("body", "Roboto Condensed")

    surface.CreateFont("hRadio_CL_Kicker", { font = body, size = 12, weight = 700, antialias = true })
    surface.CreateFont("hRadio_CL_Title", { font = head, size = 34, weight = 400, antialias = true })
    surface.CreateFont("hRadio_CL_Label", { font = head, size = 17, weight = 400, antialias = true })
    surface.CreateFont("hRadio_CL_Name", { font = head, size = 23, weight = 400, antialias = true })
    surface.CreateFont("hRadio_CL_Index", { font = head, size = 17, weight = 400, antialias = true })
    surface.CreateFont("hRadio_CL_Tag", { font = body, size = 12, weight = 700, antialias = true })
    surface.CreateFont("hRadio_CL_Btn", { font = head, size = 16, weight = 400, antialias = true })
    surface.CreateFont("hRadio_CL_Key", { font = head, size = 20, weight = 400, antialias = true })
    surface.CreateFont("hRadio_CL_Hint", { font = body, size = 11, weight = 600, antialias = true })
end

createFonts()

---------------------------------
-- Zeichnen: abgeschrägte Platten
---------------------------------

-- surface.DrawPoly zeichnet nur im Uhrzeigersinn, daher bei Bedarf umdrehen
local function drawPoly(pts)
    local a, b, c = pts[1], pts[2], pts[3]
    local cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x)

    if cross < 0 then
        local rev = {}
        for i = #pts, 1, -1 do rev[#rev + 1] = pts[i] end
        pts = rev
    end

    surface.DrawPoly(pts)
end

-- Ecken oben links und unten rechts abgeschrägt (wie SymChars "tlbr")
local function cutPoints(x, y, w, h, c)
    c = math.min(c, w * 0.5, h * 0.5)

    return {
        { x = x + c, y = y },
        { x = x + w, y = y },
        { x = x + w, y = y + h - c },
        { x = x + w - c, y = y + h },
        { x = x, y = y + h },
        { x = x, y = y + c }
    }
end

local function fillCut(x, y, w, h, c, col)
    draw.NoTexture()
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    drawPoly(cutPoints(x, y, w, h, c))
end

local function thickLine(x1, y1, x2, y2, t)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 0 then return end

    local nx, ny = -dy / len * t * 0.5, dx / len * t * 0.5

    drawPoly({
        { x = x1 + nx, y = y1 + ny },
        { x = x2 + nx, y = y2 + ny },
        { x = x2 - nx, y = y2 - ny },
        { x = x1 - nx, y = y1 - ny }
    })
end

local function outlineCut(x, y, w, h, c, col, t)
    t = t or 1

    -- Linie liegt komplett innerhalb der Platte
    local half = t * 0.5
    local pts = cutPoints(x + half, y + half, w - t, h - t, math.max(c - half, 0))

    draw.NoTexture()
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)

    for i = 1, #pts do
        local a = pts[i]
        local b = pts[i % #pts + 1]
        thickLine(a.x, a.y, b.x, b.y, t)
    end
end

local function rect(x, y, w, h, col)
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    surface.DrawRect(x, y, w, h)
end

local function fitText(text, font, maxWidth)
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxWidth then return text end

    while #text > 1 do
        text = string.sub(text, 1, -2)
        if surface.GetTextSize(text .. "..") <= maxWidth then
            return text .. ".."
        end
    end

    return text
end

local function aurebeshText(text)
    local out = string.upper(tostring(text or ""))
        :gsub("Ä", "AE"):gsub("Ö", "OE"):gsub("Ü", "UE")
        :gsub("ä", "AE"):gsub("ö", "OE"):gsub("ü", "UE"):gsub("ß", "SS")

    return out
end

-- Aurebesh als Bild-Atlas (Schriften aus resource/fonts lädt GMod erst nach einem Spielneustart,
-- ein Bild dagegen sofort). Atlas aus resource/fonts/symchars_aurebesh.ttf erzeugt.
local AUREBESH = include("helio_radio/cl/helio_radio_aurebesh_atlas.lua")
local aurebeshMat -- nil = noch nicht geladen, false = nicht verfügbar

local function usable(mat)
    return mat ~= nil and not mat:IsError()
end

-- 1. Bild vom Server (materials/vgui/hradio/aurebesh_atlas.png)
-- 2. fehlt es (Server verteilt keine Downloads): eingebettetes Bild in data/ schreiben und von dort laden
-- 3. geht beides nicht: Aurebesh weglassen statt Karomuster (fehlende Textur) zu zeigen
local function getAurebeshMaterial()
    if aurebeshMat ~= nil then return aurebeshMat end

    local mat = Material("vgui/hradio/aurebesh_atlas.png", "smooth mips")

    if not usable(mat) and AUREBESH.png then
        local path = "hradio/aurebesh_atlas_" .. #AUREBESH.png .. ".png"

        if not file.Exists(path, "DATA") then
            file.CreateDir("hradio")
            file.Write(path, util.Base64Decode(AUREBESH.png))
        end

        mat = Material("../data/" .. path, "smooth mips")
        if not usable(mat) then mat = Material("data/" .. path, "smooth mips") end
    end

    aurebeshMat = usable(mat) and mat or false

    if not aurebeshMat then
        print("[hRadio] Aurebesh-Bild konnte nicht geladen werden, Aurebesh-Zeilen werden ausgeblendet.")
    end

    return aurebeshMat
end
local AURE_SPACING = 0.08

local function aurebeshWidth(text, h)
    local w = 0
    for i = 1, #text do
        local ch = string.sub(text, i, i)
        local g = AUREBESH.glyphs[ch]
        if g then
            w = w + (g[3] + AURE_SPACING) * h
        elseif ch == " " then
            w = w + AUREBESH.space * h
        end
    end
    return w
end

-- h = Zellhöhe; die Zeichen selbst sind etwa 60 % davon hoch. y = vertikale Mitte
local function drawAurebesh(text, x, y, h, col, maxWidth)
    local mat = getAurebeshMaterial()
    if not mat then return end

    text = aurebeshText(text)

    if maxWidth then
        while #text > 0 and aurebeshWidth(text, h) > maxWidth do
            text = string.sub(text, 1, -2)
        end
    end

    local size, cell = AUREBESH.size, AUREBESH.cell
    surface.SetMaterial(mat)
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)

    local pen = x
    for i = 1, #text do
        local ch = string.sub(text, i, i)
        local g = AUREBESH.glyphs[ch]

        if g then
            local adv = g[3] * h
            local u0, v0 = g[1] / size, g[2] / size
            local u1, v1 = (g[1] + cell) / size, (g[2] + cell) / size
            surface.DrawTexturedRectUV(pen + adv * 0.5 - h * 0.5, y - h * 0.5, h, h, u0, v0, u1, v1)
            pen = pen + adv + AURE_SPACING * h
        elseif ch == " " then
            pen = pen + AUREBESH.space * h
        end
    end

    draw.NoTexture()
end

------------------
-- Maus / Klicks
------------------

local cursorX, cursorY

local function hovering(x, y, w, h)
    return cursorX ~= nil and cursorX >= x and cursorX <= x + w and cursorY >= y and cursorY <= y + h
end

local function clicked(x, y, w, h)
    if state.click and hovering(x, y, w, h) then
        state.click = false
        return true
    end

    return false
end

-- Projiziert die Mausposition auf die Ebene des Menüs (gleiche Kamera wie die Hände)
local function updateCursor(view, pos, ang, scale)
    cursorX, cursorY = nil, nil
    if not vgui.CursorVisible() then return end

    local mx, my = input.GetCursorPos()
    local dir = util.AimVector(view.angles, view.fov, mx, my, ScrW(), ScrH())
    local hit = util.IntersectRayWithPlane(view.origin, dir, pos, ang:Up())
    if not hit then return end

    local diff = hit - pos
    cursorX = diff:Dot(ang:Forward()) / scale
    cursorY = diff:Dot(ang:Right()) / scale
end

local function withAlpha(mult, fn)
    local prev = surface.GetAlphaMultiplier()
    surface.SetAlphaMultiplier(prev * mult)
    fn()
    surface.SetAlphaMultiplier(prev)
end

-- style: "primary", "alert", "on", "taken" oder nil (Standard)
local function button(x, y, w, h, label, style, enabled, font)
    local hov = enabled and hovering(x, y, w, h)
    local press = hov and input.IsMouseDown(MOUSE_LEFT)
    local bg, border, fg

    if style == "primary" then
        bg = hov and pal.accentHi or pal.accent
        fg = pal.ink
    elseif style == "alert" then
        bg, border, fg = pal.redBg, hov and pal.red or pal.redLine, pal.text
    elseif style == "on" then
        bg, border, fg = pal.amberBg, pal.accent, pal.accent
    else
        bg = hov and pal.panel3 or pal.panel2
        border = hov and pal.accent or pal.line2
        fg = hov and pal.text or (style == "taken" and pal.muted or (style == "key" and pal.text or pal.soft))
    end

    withAlpha(enabled and 1 or 0.3, function()
        local oy = press and 1 or 0
        fillCut(x, y + oy, w, h, 5, bg)
        if border then outlineCut(x, y + oy, w, h, 5, border, 1.2) end
        draw.SimpleText(label, font or "hRadio_CL_Btn", x + w * 0.5, y + h * 0.5 + 1 + oy, fg, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    return enabled and clicked(x, y, w, h)
end

------------------
-- Funk-Daten
------------------

local function buildChannels(ply)
    local list = {}
    local talking = {}

    for _, transmission in ipairs(hradio.IncomingTransmissions or {}) do
        local from, chanId = transmission[1], transmission[2]
        if IsValid(from) and from.hradio and from.hradio.IsTalking then
            talking[chanId] = true
        end
    end

    for index, channel in pairs(hradio.Channels or {}) do
        local valid = channel.Name and channel.Talkers and channel.Listeners and
            channel.GetTalkers and channel.GetListeners and channel.Mutable ~= nil and channel.Color

        if valid and (channel.GetListeners(ply) or channel.Listeners[ply:Team()]) then
            list[#list + 1] = {
                id = tonumber(index) or 0,
                name = tostring(channel.Name),
                color = channel.Color,
                mutable = channel.Mutable == true,
                muted = ply.hradio.MutedChannels[index] == true,
                active = ply.hradio.ActiveChannel == index,
                canTalk = (channel.GetTalkers(ply) or channel.Talkers[ply:Team()]) and true or false,
                joined = hradio.IsChannelJoined and hradio.IsChannelJoined(index) or false,
                receiving = talking[index] == true
            }
        end
    end

    table.sort(list, function(a, b) return a.id < b.id end)

    return list
end

------------------
-- Aktionen
------------------

local function toggleMute(ply, ch)
    if not ch.mutable then return end

    local muted = not ch.muted

    if muted and ch.active then
        hradio.ChangeActiveChannel(0)
    end

    ply.hradio.MutedChannels[ch.id] = muted
    hradio.ChangeMuteStatus(ch.id, muted)
end

local function toggleActive(ply, ch)
    if not ch.canTalk or ch.muted then return end

    if ch.active then
        if ply.hradio.RadioTalkStarted then RunConsoleCommand("-hradio_talk") end
        hradio.ChangeActiveChannel(0)
        playUISound("buttons/combine_button2.wav")
    else
        if ply.hradio.RadioTalkStarted then RunConsoleCommand("-hradio_talk") end
        hradio.ChangeActiveChannel(ch.id)
        playUISound("buttons/combine_button_locked.wav")
    end
end

------------------
-- Menü zeichnen
------------------

local function drawStatusTag(ply, ch, x, y)
    local text, col = "NICHT BEIGETRETEN", pal.muted

    if ch.muted then
        text, col = "STUMM", pal.redText
    elseif ch.active and ply.hradio.IsTalking then
        local pulse = 150 + 105 * math.abs(math.sin(CurTime() * 6))
        text, col = "DU SENDEST", Color(pal.text.r, pal.text.g, pal.text.b, pulse)
    elseif ch.active then
        text, col = "AKTIV", pal.accent
    elseif ch.receiving then
        text, col = "EMPFANG", pal.green
    elseif ch.joined and ch.canTalk then
        text, col = "BEREIT", pal.soft
    elseif ch.joined then
        text, col = "NUR HÖREN", pal.soft
    end

    draw.SimpleText(text, "hRadio_CL_Tag", x, y, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

local function drawCard(ply, ch, x, y, w, slots)
    local h = CARD_H
    local chanCol = ch.color or pal.accent

    -- Platte
    local bg = pal.panel
    if ch.muted then bg = pal.redBg end
    fillCut(x, y, w, h, 10, bg)

    if ch.active then
        fillCut(x, y, w, h, 10, pal.accentDim)
    end

    local border = pal.line
    if ch.active then border = pal.accent elseif ch.muted then border = pal.redLine end
    outlineCut(x, y, w, h, 10, border, ch.active and 1.5 or 1)

    -- Farbstreifen des Funks (pulsiert bei Empfang)
    local stripeA = 255
    if ch.receiving then stripeA = 140 + 115 * math.abs(math.sin(CurTime() * 5)) end
    rect(x, y + 10, 3, h - 10, Color(chanCol.r, chanCol.g, chanCol.b, stripeA))

    if ch.active then
        rect(x + 10, y + h - 2, w - 20, 2, pal.accent)
    end

    -- Nummer
    local ix, iy = x + 12, y + 7
    fillCut(ix, iy, 24, 22, 5, ch.active and pal.accent or pal.panel3)
    draw.SimpleText(string.format("%02d", ch.id), "hRadio_CL_Index", ix + 12, iy + 12, ch.active and pal.ink or pal.soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Name in Funkfarbe + Status rechts
    local nameX = ix + 32
    local name = fitText(string.upper(ch.name), "hRadio_CL_Name", w - (nameX - x) - 92)
    draw.SimpleText(name, "hRadio_CL_Name", nameX, iy + 12, ch.muted and pal.muted or chanCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    drawStatusTag(ply, ch, x + w - 10, iy + 11)

    -- Name in Aurebesh darunter
    local aureCol = ch.muted and pal.muted or chanCol
    drawAurebesh(ch.name, nameX + 1, iy + 28, 13, Color(aureCol.r, aureCol.g, aureCol.b, 150), w - (nameX - x) - 12)

    -- Knöpfe: Stumm | Einschalten | F1 F2 F3
    local by = y + 45
    local bh = 22
    local bx = x + 12
    local gap = 4
    local keyW = 32
    local inner = w - 22
    local keysW = #slots > 0 and (#slots * keyW + #slots * gap) or 0
    local muteW = math.floor((inner - keysW - gap) * 0.45)
    local actW = inner - keysW - gap - muteW

    if button(bx, by, muteW, bh, ch.muted and "TON AN" or "STUMM", ch.muted and "alert" or nil, ch.mutable) then
        toggleMute(ply, ch)
    end
    bx = bx + muteW + gap

    if button(bx, by, actW, bh, ch.active and "AUSSCHALTEN" or "EINSCHALTEN", ch.active and nil or "primary", ch.canTalk and not ch.muted) then
        toggleActive(ply, ch)
    end
    bx = bx + actW + gap

    for _, sl in ipairs(slots) do
        local bound = hradio.GetHotkeyChannel(sl.slot)
        local style = bound == ch.id and "on" or (bound and "taken" or "key")

        if button(bx, by, keyW, bh, sl.label, style, true, "hRadio_CL_Key") then
            hradio.ToggleHotkeyBinding(sl.slot, ch.id)
        end

        bx = bx + keyW + gap
    end
end

-- holder = Tabelle mit Feld "scroll" (jede App hat ihre eigene Scrollposition)
local function drawScrollbar(x, y, h, total, visible, holder)
    holder = holder or state
    local arrowH = 14
    local canUp = holder.scroll > 0
    local canDown = holder.scroll < total - visible

    -- Pfeile
    local upHov = canUp and hovering(x - 4, y, SCROLL_W + 8, arrowH)
    local downHov = canDown and hovering(x - 4, y + h - arrowH, SCROLL_W + 8, arrowH)

    draw.SimpleText("▲", "hRadio_CL_Tag", x + SCROLL_W * 0.5, y + arrowH * 0.5, upHov and pal.accent or (canUp and pal.soft or pal.line2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("▼", "hRadio_CL_Tag", x + SCROLL_W * 0.5, y + h - arrowH * 0.5, downHov and pal.accent or (canDown and pal.soft or pal.line2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if canUp and clicked(x - 4, y, SCROLL_W + 8, arrowH) then holder.scroll = holder.scroll - 1 end
    if canDown and clicked(x - 4, y + h - arrowH, SCROLL_W + 8, arrowH) then holder.scroll = holder.scroll + 1 end

    -- Schiene + Griff
    local trackY = y + arrowH + 2
    local trackH = h - arrowH * 2 - 4
    rect(x + SCROLL_W * 0.5 - 1, trackY, 2, trackH, pal.line)

    if total > visible then
        local thumbH = math.max(14, trackH * visible / total)
        local thumbY = trackY + (trackH - thumbH) * (holder.scroll / (total - visible))
        rect(x + 1, thumbY, SCROLL_W - 2, thumbH, pal.accentSoft)
    else
        rect(x + 1, trackY, SCROLL_W - 2, trackH, pal.accentDim)
    end
end

local function menuHeight()
    local visible = visibleCount()
    return HEADER_H + visible * CARD_H + (visible - 1) * CARD_GAP
end

local function drawMenu(ply)
    local channels = buildChannels(ply)
    local visible = visibleCount()
    local listH = visible * CARD_H + (visible - 1) * CARD_GAP
    local menuH = menuHeight()
    local blocked = hradio.IsGRNCommsBlocked and hradio.IsGRNCommsBlocked()

    state.scroll = math.Clamp(state.scroll, 0, math.max(0, #channels - visible))

    -- Kopf: nur COMLINK + Aurebesh darunter (kein Hintergrund)
    draw.SimpleText("COMLINK", "hRadio_CL_Title", 16, 20, Color(0, 0, 0, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("COMLINK", "hRadio_CL_Title", 15, 19, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    drawAurebesh("COMLINK", 16, 42, 16, Color(pal.accent.r, pal.accent.g, pal.accent.b, 200))

    if blocked then
        draw.SimpleText("FUNK AUSGEFALLEN", "hRadio_CL_Tag", MENU_W - 26, 20, pal.redText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Liste
    local listX = 14
    local listY = HEADER_H
    local cardW = MENU_W - listX - SCROLL_W - 18
    local slots = {}

    if config().HotkeysEnabled ~= false and hradio.GetHotkeySlots then
        for slot, def in ipairs(hradio.GetHotkeySlots()) do
            slots[#slots + 1] = { slot = slot, label = tostring(def.Label) }
        end
    end

    if #channels == 0 then
        outlineCut(listX, listY, cardW, 58, 10, pal.accentDim, 1)
        draw.SimpleText("KEINE FUNKS VERFÜGBAR", "hRadio_CL_Label", listX + cardW * 0.5, listY + 29, pal.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        for i = 1, visible do
            local ch = channels[state.scroll + i]
            if not ch then break end

            drawCard(ply, ch, listX, listY + (i - 1) * (CARD_H + CARD_GAP), cardW, slots)
        end
    end

    drawScrollbar(MENU_W - SCROLL_W - 12, listY, listH, #channels, visible)
end

---------------------------------
-- Apps auf dem Comlink
---------------------------------

-- Zeichenwerkzeuge für andere Apps (Squad, Textfunk, Medic), damit alles gleich aussieht
hradio.ComlinkUI = {
    pal = pal,
    SCROLL_W = SCROLL_W,
    updatePalette = updatePalette,
    fontFace = fontFace,
    fillCut = fillCut,
    outlineCut = outlineCut,
    thickLine = thickLine,
    drawPoly = drawPoly,
    rect = rect,
    fitText = fitText,
    drawAurebesh = drawAurebesh,
    hovering = hovering,
    clicked = clicked,
    withAlpha = withAlpha,
    button = button,
    drawScrollbar = drawScrollbar,
    playUISound = playUISound,
    config = config
}

hradio.ComlinkApps = {}

-- app = { width = number, height = function() -> number, draw = function(ply),
--         onWheel = function(delta), canOpen = function(ply) -> bool, onOpen = function(), onClose = function(),
--         closeOnGRN = bool, key = function() -> KEY_*,
--         onThirdPerson = function(ply) -> bool (true = selbst erledigt, z.B. 2D-Menü geöffnet) }
function hradio.RegisterComlinkApp(name, app)
    hradio.ComlinkApps[name] = app
end

hradio.RegisterComlinkApp("radio", {
    width = MENU_W,
    height = menuHeight,
    draw = drawMenu,
    closeOnGRN = true,
    canOpen = function()
        if hradio.IsGRNCommsBlocked and hradio.IsGRNCommsBlocked() then
            if hradio.ShowGRNCommsBlocked then hradio.ShowGRNCommsBlocked() end
            return false
        end

        return true
    end,
    onWheel = function(delta)
        state.scroll = state.scroll - (delta > 0 and 1 or -1)
    end
})

local function currentApp()
    return state.app and hradio.ComlinkApps[state.app] or hradio.ComlinkApps.radio
end

local function appWidth()
    return currentApp().width or MENU_W
end

local function appHeight()
    local app = currentApp()
    return app.height and app.height() or menuHeight()
end

---------------------------------
-- Arm mit Comlink (eigene Animation)
---------------------------------

local ARM_MODEL = "models/weapons/c_vmaniphradio_comlink.mdl"
local ARM_SLIDE = 0.18 -- Sekunden, in denen der Arm von unten rein-/rausgleitet

util.PrecacheModel(ARM_MODEL)

-- Alte Modelle nach cl_hRadio_Reload entfernen
state.arm = state.arm or {}
local arm = state.arm

if IsValid(arm.ent) then arm.ent:Remove() end
if IsValid(arm.hands) then arm.hands:Remove() end
arm.ent, arm.hands, arm.phase = nil, nil, nil

local function handsInfo(ply)
    local custom = config().ComlinkHandsModel
    if isstring(custom) and custom ~= "" then
        return custom, nil
    end

    local hands = ply:GetHands()

    if IsValid(hands) and isstring(hands:GetModel()) and hands:GetModel() ~= "" then
        return hands:GetModel(), hands
    end

    return "models/weapons/c_arms_citizen.mdl", nil
end

local function ensureArm(ply)
    local model = config().ComlinkArmModel or ARM_MODEL

    if not IsValid(arm.ent) or arm.ent:GetModel() ~= model then
        if IsValid(arm.ent) then arm.ent:Remove() end

        arm.ent = ClientsideModel(model, RENDERGROUP_OPAQUE)
        if not IsValid(arm.ent) then return false end

        arm.ent:SetNoDraw(true)
    end

    -- Hände des Spielermodells per Bonemerge an den Comlink-Arm hängen
    local handsModel, src = handsInfo(ply)

    if not IsValid(arm.hands) or arm.hands:GetModel() ~= handsModel then
        if IsValid(arm.hands) then arm.hands:Remove() end

        arm.hands = ClientsideModel(handsModel, RENDERGROUP_OPAQUE)
        if not IsValid(arm.hands) then return false end

        arm.hands:SetNoDraw(true)
        arm.hands:SetParent(arm.ent)
        arm.hands:AddEffects(EF_BONEMERGE)
        arm.hands:AddEffects(EF_BONEMERGE_FASTCULL)

        -- Spielerfarbe auf den Handschuhen (PlayerColor-Materialproxy)
        arm.hands.GetPlayerColor = function()
            local lp = LocalPlayer()
            return IsValid(lp) and lp:GetPlayerColor() or Vector(1, 1, 1)
        end
    end

    if IsValid(src) then
        arm.hands:SetSkin(src:GetSkin())
        for i = 0, src:GetNumBodyGroups() - 1 do
            arm.hands:SetBodygroup(i, src:GetBodygroup(i))
        end
    end

    return true
end

local function playArm(seqName, startCycle)
    local seq = arm.ent:LookupSequence(seqName or "")
    if not seq or seq < 0 then return false end

    arm.ent:ResetSequence(seq)
    arm.seq = seq
    arm.dur = math.max(arm.ent:SequenceDuration(seq), 0.05)
    arm.startCycle = startCycle or 0
    arm.start = RealTime()

    return true
end

local function armCycle()
    return math.min(arm.startCycle + (RealTime() - arm.start) / arm.dur, 1)
end

-- Zeit, ab der der Arm oben ist und das Menü erscheint
local function menuDelay()
    return math.max(config().OpenDelay or 0.4, (arm.dur or 0.5) * 0.75)
end

local function getViewFOV(setup)
    local fov = tonumber(config().ComlinkViewModelFOV) or 0
    if fov > 0 then return fov end

    fov = setup.fovviewmodel
    if not fov or fov < 1 then fov = 62 end

    return fov
end

-- Arm vor der Kamera zeichnen, gibt false zurück wenn nichts gezeichnet wurde
local function drawArm(view)
    if not arm.phase or not IsValid(arm.ent) or not IsValid(arm.hands) then return false end

    local t = RealTime() - arm.start
    local cycle = armCycle()
    local drop = 0

    if arm.phase == "open" then
        drop = math.max(0, 1 - t / ARM_SLIDE)
    elseif arm.phase == "closing" then
        if cycle >= 1 then
            local out = (t - arm.dur * (1 - arm.startCycle)) / ARM_SLIDE
            if out >= 1 then
                arm.phase = nil
                return false
            end
            drop = out
        end
    end

    drop = drop * drop * 12

    arm.ent:SetPos(view.origin - view.angles:Up() * drop)
    arm.ent:SetAngles(view.angles)
    arm.ent:SetCycle(cycle)
    arm.ent:InvalidateBoneCache()
    arm.ent:SetupBones()
    arm.hands:InvalidateBoneCache()

    cam.Start3D(view.origin, view.angles, view.fov, 0, 0, ScrW(), ScrH(), 1, 4096)
        render.ClearDepth()
        arm.ent:DrawModel()
        arm.hands:DrawModel()
    cam.End3D()

    return true
end

---------------------------------
-- Position am Comlink (Handgelenk)
---------------------------------

local function getBoneIndex(ent)
    local cfg = config()

    if cfg.OverrideIndexWithBoneName and cfg.BoneName then
        local bone = ent:LookupBone(cfg.BoneName)
        if bone then return bone end
    end

    local individual = cfg.IndividualBoneIndexes or {}
    return individual[ent:GetModel()] or cfg.BoneIndex or 4
end

-- Aufrecht zur Kamera, unten mittig über dem Handgelenk (wandert mit dem Arm mit)
local function getUprightTransform(view, wrist, scale)
    local cfg = config()
    local off = cfg.MenuUprightOffset or {}
    local cam = view.angles

    local anchor = wrist + cam:Up() * (off.Up or 1.5) + cam:Right() * (off.Right or 0) + cam:Forward() * (off.Forward or 0)

    local ang = Angle(cam.p, cam.y, cam.r)
    ang:RotateAroundAxis(ang:Up(), -90)
    ang:RotateAroundAxis(ang:Forward(), 90)

    -- leicht nach hinten kippen (Grad), 0 = genau gerade
    local tilt = tonumber(cfg.MenuUprightTilt) or 0
    if tilt ~= 0 then ang:RotateAroundAxis(ang:Forward(), -tilt) end

    -- 3D2D beginnt oben links: von der Ankerstelle (unten mittig) zurückrechnen
    local pos = anchor - ang:Forward() * (appWidth() * 0.5 * scale) - ang:Right() * (appHeight() * scale)

    return pos, ang
end

-- Mitte des Comlink-Geräts: hängt am Unterarm, Lage aus dem Modell ausgelesen
local function getComlinkCenter()
    local cfg = config()
    local bone = arm.ent:LookupBone(cfg.ComlinkBone or "ValveBiped.Bip01_L_Forearm")
    if not bone then return end

    local matrix = arm.ent:GetBoneMatrix(bone)
    if not matrix then return end

    local localPos = cfg.ComlinkLocalPos or Vector(10.48, -0.13, 1.64)
    local pos = LocalToWorld(localPos, Angle(0, 0, 0), matrix:GetTranslation(), matrix:GetAngles())

    return pos
end

local function getMenuTransform(view, scale)
    if not IsValid(arm.ent) then return nil, nil, "kein Arm-Modell" end

    if config().MenuUpright ~= false then
        local center = getComlinkCenter()
        if center then
            local pos, ang = getUprightTransform(view, center, scale)
            return pos, ang, "über dem Comlink (gerade)"
        end
    end

    local bone = getBoneIndex(arm.ent)
    local matrix = arm.ent:GetBoneMatrix(bone)
    if not matrix then return nil, nil, "Knochen nicht gefunden (" .. tostring(bone) .. ")" end

    if config().MenuUpright ~= false then
        local pos, ang = getUprightTransform(view, matrix:GetTranslation(), scale)
        return pos, ang, "Handgelenk (gerade)"
    end

    local cfgPos = config().MenuPosition or {}
    local pos = matrix:GetTranslation()
    local ang = matrix:GetAngles()

    pos = pos + ang:Up() * (cfgPos.Up or 0) + ang:Forward() * (cfgPos.Forward or 0) + ang:Right() * (cfgPos.Right or 0)

    ang:RotateAroundAxis(ang:Up(), cfgPos.UpRot or 0)
    ang:RotateAroundAxis(ang:Forward(), cfgPos.FwdRot or 0)
    ang:RotateAroundAxis(ang:Right(), cfgPos.RgtRot or 0)

    return pos, ang, "Handgelenk"
end

-- Ersatz, wenn das Handgelenk nicht gefunden wird: Menü links vor der Kamera
local function getFallbackTransform(view)
    local ang = Angle(view.angles.p, view.angles.y, view.angles.r)
    local pos = view.origin + ang:Forward() * 18 - ang:Right() * 10 + ang:Up() * 6

    ang:RotateAroundAxis(ang:Up(), -90)
    ang:RotateAroundAxis(ang:Forward(), 90)

    return pos, ang
end

-- Hologramm im Bild halten: oben nicht in die HUD-Leiste (DEFCON usw.) ragen, unten nicht aus dem Bild.
-- Ist das Menü höher als der freie Platz, wird es (um die Mitte unten) verkleinert, danach nach unten geschoben.
local function keepOnScreen(view, pos, ang, scale)
    local cfg = config()
    local top = ScrH() * (tonumber(cfg.MenuTopMargin) or 0.1)
    local bottom = ScrH() * (1 - (tonumber(cfg.MenuBottomMargin) or 0.02))
    local w, h = appWidth(), appHeight()

    local function project(p, s)
        cam.Start3D(view.origin, view.angles, view.fov, 0, 0, ScrW(), ScrH(), 1, 4096)
            local a = p:ToScreen()
            local b = (p + ang:Right() * (h * s)):ToScreen()
        cam.End3D()
        return a, b
    end

    local a, b = project(pos, scale)
    if not (a.visible and b.visible) or b.y - a.y <= 1 then return pos, scale end

    -- zu hoch für den freien Platz: verkleinern, Ankerpunkt (unten mittig) bleibt
    local px = b.y - a.y
    if px > bottom - top then
        local anchor = pos + ang:Forward() * (w * 0.5 * scale) + ang:Right() * (h * scale)
        scale = scale * (bottom - top) / px
        pos = anchor - ang:Forward() * (w * 0.5 * scale) - ang:Right() * (h * scale)
        a, b = project(pos, scale)
        px = b.y - a.y
        if px <= 1 then return pos, scale end
    end

    -- oben zu weit raus: nach unten schieben (Pixel -> Einheiten über die Menühöhe)
    local unitsPerPx = (h * scale) / px
    if a.y < top then
        pos = pos + ang:Right() * ((top - a.y) * unitsPerPx)
    elseif b.y > bottom then
        pos = pos - ang:Right() * (math.min(b.y - bottom, a.y - top) * unitsPerPx)
    end

    return pos, scale
end

------------------
-- Öffnen / Schließen
------------------

-- Kameraposition aus dem Hauptbild merken (Beine-/Körper-Addons lassen ShouldDrawLocalPlayer
-- auch in der Ego-Perspektive true liefern, deshalb zählt der echte Kamera-Abstand zum Kopf)
hook.Add("PostDrawOpaqueRenderables", "hRadio_ComlinkView", function(depth, skybox)
    if skybox or render.GetRenderTarget() ~= nil then return end
    state.viewOrigin = EyePos()
    state.viewTime = RealTime()
end)

local function isThirdPerson(ply)
    if ply:GetViewEntity() ~= ply then return true end

    if state.viewOrigin and state.viewTime and RealTime() - state.viewTime < 1 then
        return state.viewOrigin:DistToSqr(ply:EyePos()) > 24 * 24
    end

    return ply:ShouldDrawLocalPlayer()
end

hradio.ComlinkIsThirdPerson = isThirdPerson

local function removeInputPanel()
    if IsValid(state.panel) then
        state.panel:Remove()
    end

    state.panel = nil
    state.click = false
    gui.EnableScreenClicker(false)
end

-- Unsichtbares Panel fängt Mausklicks und Mausrad ab (Tastatur bleibt beim Spiel: Laufen, H, F1–F3)
local function createInputPanel()
    removeInputPanel()

    local pnl = vgui.Create("EditablePanel")
    pnl:SetPos(0, 0)
    pnl:SetSize(ScrW(), ScrH())
    pnl:SetMouseInputEnabled(true)
    pnl:SetKeyboardInputEnabled(false)
    pnl.Paint = nil

    pnl.OnMousePressed = function(_, code)
        if code == MOUSE_LEFT then state.click = true end
    end

    pnl.OnMouseWheeled = function(_, delta)
        local app = currentApp()
        if app.onWheel then app.onWheel(delta) end
        return true
    end

    state.panel = pnl
    gui.EnableScreenClicker(true)
end

function hradio.IsComlinkOpen(appName)
    if appName then return state.open == true and state.app == appName end
    return state.open == true
end

function hradio.GetComlinkApp()
    return state.open and state.app or nil
end

local function runOnClose(appName)
    local app = appName and hradio.ComlinkApps[appName]
    if not app or not app.onClose then return end

    local ok, err = pcall(app.onClose)
    if not ok then ErrorNoHalt("[hRadio] Comlink-App '" .. tostring(appName) .. "' onClose: " .. tostring(err) .. "\n") end
end

function hradio.CloseComlink(skipAnim)
    local wasOpen = state.open
    state.open = false
    removeInputPanel()

    if not wasOpen then return end

    runOnClose(state.app)

    local cfg = config()

    if skipAnim or not IsValid(arm.ent) then
        arm.phase = nil
        return
    end

    -- Arm wieder runter
    if cfg.UseCloseAnim ~= false and playArm(cfg.AnimClose or "hradio_sw_comlink_close", 0.8) then
        arm.phase = "closing"
    else
        arm.phase = "closing"
        arm.startCycle, arm.dur, arm.start = 1, 0.05, RealTime()
    end

    playUISound("buttons/combine_button2.wav")
end

-- Schließt das Comlink nur, wenn gerade diese App offen ist (z.B. Funk-Störung schließt nicht Squad/Medic)
function hradio.CloseComlinkApp(appName, skipAnim)
    if state.open and state.app == appName then
        hradio.CloseComlink(skipAnim)
    end
end

local function canOpenApp(ply, appName)
    local app = hradio.ComlinkApps[appName]
    if not app then return false end
    if app.canOpen and not app.canOpen(ply) then return false end
    return true
end

-- Bei offenem Comlink direkt zur anderen App wechseln (Arm bleibt oben)
local function switchApp(appName)
    local ply = LocalPlayer()
    if not IsValid(ply) or not canOpenApp(ply, appName) then return end

    runOnClose(state.app)
    state.app = appName
    state.click = false

    local app = hradio.ComlinkApps[appName]
    if app.onOpen then app.onOpen() end

    playUISound("buttons/combine_button1.wav")
end

function hradio.OpenComlink(appName)
    appName = appName or "radio"

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    ply.hradio = ply.hradio or {}
    ply.hradio.MutedChannels = ply.hradio.MutedChannels or {}

    if state.open then
        if state.app ~= appName then switchApp(appName) end
        return
    end

    if not canOpenApp(ply, appName) then return end

    local app = hradio.ComlinkApps[appName]

    -- Nur in der Ego-Perspektive
    if isThirdPerson(ply) then
        if app.onThirdPerson and app.onThirdPerson(ply) then return end

        if RealTime() > (state.nextNotice or 0) then
            state.nextNotice = RealTime() + 3
            notification.AddLegacy("Das Comlink geht nur in der Ego-Perspektive.", NOTIFY_HINT, 3)
            playUISound("buttons/button10.wav")
        end
        return
    end

    local cfg = config()

    if appName == "radio" and cfg.AlwaysUse3PMenu then
        if hradio.OpenMenu2D and not IsValid(ply.hradio.RadioMenu) then
            ply.hradio.RadioMenu = hradio.OpenMenu2D()
        end
        return
    end

    if not ensureArm(ply) or not playArm(cfg.AnimName or "hradio_sw_comlink", 0) then
        print("[hRadio] Comlink-Arm konnte nicht geladen werden (" .. ARM_MODEL .. " fehlt beim Client?)")
        notification.AddLegacy("Comlink-Modell fehlt. Bitte Server-Inhalte herunterladen.", NOTIFY_ERROR, 4)
        return
    end

    if IsValid(ply.hradio.RadioMenu) then
        ply.hradio.RadioMenu:Remove()
    end

    arm.phase = "open"
    state.open = true
    state.app = appName
    state.openTime = RealTime()

    if app.onOpen then app.onOpen() end

    createInputPanel()
    playUISound("buttons/combine_button1.wav")
end

-- appName: "radio" (H), "squad" (G), "crypto" (J) oder "medic" (K). Gleiche Taste schließt, andere wechselt die App.
function hradio.ToggleComlink(appName)
    appName = appName or "radio"

    -- Ein Tastendruck kann mehrfach ankommen (H zusätzlich gebunden, Befehl + Taste): nur einmal reagieren
    if RealTime() - (state.lastToggle or 0) < 0.3 then return end
    state.lastToggle = RealTime()

    if state.open and state.app == appName then
        hradio.CloseComlink()
    else
        hradio.OpenComlink(appName)
    end
end

-- Alte Namen, falls andere Addons sie aufrufen
hradio.OpenFirstPersonMenu = function() hradio.OpenComlink("radio") end
hradio.CloseFirstPersonMenu = hradio.CloseComlink

------------------
-- Hooks
------------------

-- Tasten (Standard H = Funk, G = Squad, K = Medic; J = Textfunk prüft crypto_radio/cl_comlink.lua): über Think, damit sie auch bei sichtbarem Mauszeiger zuverlässig gehen
local keysDown = {}

-- Squad-Taste: Spieler-Einstellung bzw. Server-Einstellung des Squad-Systems, sonst Config (Standard G)
local function squadKey()
    if KrakenSquad and KrakenSquad.GetClientPref then
        local key = KrakenSquad.GetClientPref("radial_key", nil) or KrakenSquad.GetConfig("keybind")
        if isnumber(key) and key > 0 then return key end
    end

    return config().SquadKey or KEY_G
end

hradio.ComlinkSquadKey = squadKey

local function pressed(id, key)
    local down = key and key > 0 and input.IsKeyDown(key) or false
    local was = keysDown[id]
    keysDown[id] = down
    return down and not was
end

hook.Add("Think", "hRadio_Comlink", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local typing = ply:IsTyping() or gui.IsGameUIVisible() or gui.IsConsoleVisible() or IsValid(vgui.GetKeyboardFocus())

    local radioPressed = pressed("radio", config().ComlinkKey or KEY_H)
    local squadPressed = config().SquadEnabled ~= false and hradio.ComlinkApps.squad and pressed("squad", squadKey())
    local medicApp = config().MedicEnabled ~= false and hradio.ComlinkApps.medic
    local medicPressed = medicApp and pressed("medic", medicApp.key and medicApp.key() or KEY_K)

    if not typing then
        if radioPressed then
            hradio.ToggleComlink("radio")
        elseif squadPressed then
            hradio.ToggleComlink("squad")
        elseif medicPressed then
            hradio.ToggleComlink("medic")
        end
    end

    if not state.open then return end

    -- ESC schließt das Comlink statt das Spielmenü zu öffnen
    if gui.IsGameUIVisible() then
        gui.HideGameUI()
        hradio.CloseComlink()
        return
    end

    local app = currentApp()

    if not ply:Alive() or isThirdPerson(ply) or (app.closeOnGRN and hradio.IsGRNCommsBlocked and hradio.IsGRNCommsBlocked()) then
        hradio.CloseComlink(true)
        return
    end
end)

-- Nicht schießen, solange das Comlink offen ist
hook.Add("CreateMove", "hRadio_Comlink", function(cmd)
    if not state.open then return end

    cmd:RemoveKey(IN_ATTACK)
    cmd:RemoveKey(IN_ATTACK2)
end)

-- Nach den Viewmodels: erst den Arm, dann das Menü über dem Comlink
hook.Add("PreDrawHUD", "hRadio_Comlink", function()
    if not arm.phase then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or isThirdPerson(ply) then return end

    local setup = render.GetViewSetup()
    local view = {
        origin = setup.origin,
        angles = setup.angles,
        fov = getViewFOV(setup)
    }

    local armDrawn = drawArm(view)
    if not state.open then return end

    local alpha = math.Clamp((RealTime() - state.openTime - menuDelay()) / 0.15, 0, 1)
    if alpha <= 0 then
        state.click = false
        return
    end

    local pos, ang, where
    local scale = config().MenuScale or 0.02

    if armDrawn then
        pos, ang, where = getMenuTransform(view, scale)
    end

    if not pos then
        pos, ang = getFallbackTransform(view)
        where = "Ersatzposition vor der Kamera (" .. tostring(where or "Arm nicht gezeichnet") .. ")"
    end

    -- Zeigt die Rückseite zur Kamera: umdrehen, damit das Menü sichtbar und lesbar ist
    if (pos - view.origin):Dot(ang:Up()) > 0 then
        ang:RotateAroundAxis(ang:Right(), 180)
        where = where .. ", gedreht"
    end

    pos, scale = keepOnScreen(view, pos, ang, scale)

    state.lastWhere = where
    state.lastDraw = RealTime()

    updatePalette()
    updateCursor(view, pos, ang, scale)

    cam.Start3D(view.origin, view.angles, view.fov, 0, 0, ScrW(), ScrH(), 1, 4096)
        cam.IgnoreZ(true)
        cam.Start3D2D(pos, ang, scale)
            surface.SetAlphaMultiplier(alpha)
            local app = currentApp()
            local ok, err = pcall(app.draw, ply)
            if not ok then ErrorNoHalt("[hRadio] Comlink-App '" .. tostring(state.app) .. "': " .. tostring(err) .. "\n") end
            surface.SetAlphaMultiplier(1)
        cam.End3D2D()
        cam.IgnoreZ(false)
    cam.End3D()

    -- Klick, der keinen Knopf getroffen hat, verfällt
    state.click = false
end)

------------------
-- Konsolenbefehle
------------------

-- hradio_comlink_debug: zeigt in der Konsole, woran es hängt
function hradio.ComlinkDebug()
    local ply = LocalPlayer()
    local cfg = config()
    local line = function(k, v) MsgC(Color(252, 178, 73), "[hRadio] ", color_white, k .. ": " .. tostring(v) .. "\n") end

    line("Comlink offen", state.open == true)
    line("App", state.app or "-")
    line("Taste Funk", input.GetKeyName(cfg.ComlinkKey or KEY_H))
    line("Taste Squad", input.GetKeyName(squadKey()) or "-")
    line("Taste Textfunk", CryptoRadio and CryptoRadio.Config and input.GetKeyName(CryptoRadio.Config.ComlinkKey or KEY_J) or "-")
    local medic = hradio.ComlinkApps.medic
    line("Taste Medic", medic and medic.key and input.GetKeyName(medic.key()) or "-")
    line("Apps", table.concat(table.GetKeys(hradio.ComlinkApps), ", "))
    line("Arm-Phase", arm.phase or "aus")
    line("Arm-Modell", IsValid(arm.ent) and arm.ent:GetModel() or "nicht geladen")
    line("Arm-Modell auf Platte", file.Exists(ARM_MODEL, "GAME"))
    line("Arm-Animation", IsValid(arm.ent) and arm.ent:LookupSequence(cfg.AnimName or "hradio_sw_comlink") or "?")
    line("Hände-Modell", IsValid(arm.hands) and arm.hands:GetModel() or (IsValid(ply) and handsInfo(ply)) or "?")
    line("Third Person (erkannt)", IsValid(ply) and isThirdPerson(ply))
    line("ShouldDrawLocalPlayer", IsValid(ply) and ply:ShouldDrawLocalPlayer())
    line("Funk ausgefallen (GRN)", hradio.IsGRNCommsBlocked and hradio.IsGRNCommsBlocked())
    line("Zuletzt gezeichnet vor (s)", state.lastDraw and string.format("%.2f", RealTime() - state.lastDraw) or "nie")
    line("Position", state.lastWhere or "-")
    line("Kamera-Abstand zum Kopf", state.viewOrigin and IsValid(ply) and string.format("%.1f", state.viewOrigin:Distance(ply:EyePos())) or "?")
end
