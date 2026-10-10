-- SymChars-Design: abgerundete Boxen werden zu abgeschrägten Platten (ohne SymChars wie bisher)
local function SY_RoundedBox(...) if SYMUI then return SYMUI.RoundedBox(...) end return draw.RoundedBox(...) end
local function SY_RoundedBoxEx(...) if SYMUI then return SYMUI.RoundedBoxEx(...) end return draw.RoundedBoxEx(...) end
hradio = hradio or {}

-- Sprecheranzeige: kleine Zeilen direkt unter den F-Boxen oben rechts.
-- Jede Zeile = ein Sprecher: gelber Strich + Punkt, Funkname (in Funkfarbe), Spielername rechts.
-- Mehrere Sprecher stehen untereinander, der eigene Funk steht ganz oben.

local YELLOW = SYMUI and SYMUI.LiveAccent() or Color(238, 180, 53) -- #eeb435, wie die F-Boxen
local WHITE = SYMUI and SYMUI.col.text or Color(244, 241, 233)
local MUTED = SYMUI and SYMUI.col.muted or Color(111, 118, 128)
local ROW_BG = SYMUI and Color(9, 11, 14, 215) or Color(23, 24, 27, 212) -- #17181b, wie die F-Boxen

local fontScale

local function hudScale()
    return math.Clamp(ScrH() / 1080, 0.75, 1.15)
end

local function createFonts(s)
    fontScale = s

    surface.CreateFont("hRadio_TalkerText", {
        font = SYMUI and SYMUI.FontFace("body") or "Rajdhani",
        size = math.floor(18 * s),
        weight = 700,
        antialias = true
    })
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

local function withAlpha(col, a)
    return Color(col.r, col.g, col.b, (col.a or 255) * a)
end

local function drawCircle(x, y, r, col)
    SY_RoundedBox(r, x - r, y - r, r * 2, r * 2, col)
end

local function drawTalkerRow(x, y, w, h, s, ply, chan, muted, alpha)
    local volume = math.Clamp(ply:VoiceVolume() / 0.4, 0, 1)

    SY_RoundedBox(0, x, y, w, h, withAlpha(ROW_BG, alpha))

    -- Gelber Strich vorne
    SY_RoundedBox(0, x, y, math.max(2, math.floor(3 * s)), h, withAlpha(YELLOW, alpha))

    -- Punkt (pulsiert mit der Lautstärke)
    local dotX = x + math.floor(15 * s)
    local dotR = math.max(3, math.floor((4 + volume) * s))
    drawCircle(dotX, y + h * 0.5, dotR, withAlpha(muted and MUTED or YELLOW, alpha * Lerp(volume, 0.75, 1)))

    -- Funkname links in Funkfarbe, Spielername rechts
    local textX = x + math.floor(27 * s)
    local pad = math.floor(9 * s)
    local inner = w - (textX - x) - pad

    local chanName = fitText(tostring(chan.Name or "FUNK"), "hRadio_TalkerText", inner * 0.45)
    surface.SetFont("hRadio_TalkerText")
    local chanW = surface.GetTextSize(chanName)
    local name = fitText(ply:Nick(), "hRadio_TalkerText", inner - chanW - pad)

    local chanColor = muted and MUTED or (chan.Color or YELLOW)
    draw.SimpleText(chanName, "hRadio_TalkerText", textX, y + h * 0.5, withAlpha(chanColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(name, "hRadio_TalkerText", x + w - pad, y + h * 0.5, withAlpha(muted and MUTED or WHITE, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

-- Weiches Ein-/Ausblenden pro Spieler
local function rowAlpha(ply, talking)
    ply.hradio = ply.hradio or {}
    local target = talking and 1 or 0
    local cur = ply.hradio.HudAlpha or 0
    cur = math.Approach(cur, target, FrameTime() * 8)
    ply.hradio.HudAlpha = cur
    return cur
end

hook.Add("HUDPaint", "hRadioHud", function()
    local lply = LocalPlayer()
    if not IsValid(lply) or not lply.hradio then return end

    local s = hudScale()
    if fontScale ~= s then createFonts(s) end

    local top, right
    if hradio.GetHotkeyHUDLayout then
        top, right = hradio.GetHotkeyHUDLayout()
    else
        top, right = math.floor(92 * s), ScrW() - math.floor(42 * s)
    end

    local w = math.floor(250 * s)
    local h = math.floor(28 * s)
    local gap = math.floor(4 * s)
    local x = right - w
    local y = top + math.floor(6 * s)

    -- Eigener Funk zuerst
    local ownChan = lply.hradio.ActiveChannel and hradio.Channels[lply.hradio.ActiveChannel]
    local ownTalking = ownChan ~= nil and lply.hradio.IsTalking == true
    local ownAlpha = rowAlpha(lply, ownTalking)

    if ownChan and ownAlpha > 0 then
        drawTalkerRow(x, y, w, h, s, lply, ownChan, false, ownAlpha)
        y = y + (h + gap) * ownAlpha
    end

    -- Andere Sprecher untereinander
    local muted = lply.hradio.MutedChannels or {}

    for _, transmission in ipairs(hradio.IncomingTransmissions or {}) do
        local ply, chanId = transmission[1], transmission[2]
        local chan = hradio.Channels[chanId]

        if IsValid(ply) and ply ~= lply and chan then
            local alpha = rowAlpha(ply, ply.hradio and ply.hradio.IsTalking)

            if alpha > 0 then
                drawTalkerRow(x, y, w, h, s, ply, chan, muted[chanId], alpha)
                y = y + (h + gap) * alpha
            end
        end
    end
end)
