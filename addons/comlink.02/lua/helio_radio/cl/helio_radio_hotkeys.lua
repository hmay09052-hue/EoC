-- SymChars-Design: abgerundete Boxen werden zu abgeschrägten Platten (ohne SymChars wie bisher)
local function SY_RoundedBox(...) if SYMUI then return SYMUI.RoundedBox(...) end return draw.RoundedBox(...) end
local function SY_RoundedBoxEx(...) if SYMUI then return SYMUI.RoundedBoxEx(...) end return draw.RoundedBoxEx(...) end
hradio = hradio or {}

-- Funk-Schnellwahl (standardmäßig F1 / F2 / F3, siehe hradio.Config.HotkeySlots).
-- Einen Funk auf eine Taste legen = dem Funk beitreten (erst dann hört man ihn).
-- Die Taste schaltet den Funk zum Sprechen an/aus. Stummschalten ist eine zusätzliche Option.
-- Bei jedem Join auf den Server ist nichts belegt: alle Funks müssen neu ausgewählt werden.

local OLD_COOKIE_PREFIX = "hradio_hotkey_" -- Früher gespeicherte Belegungen, werden beim Laden gelöscht

-- Alte Feldnamen, die andere Addons (z.B. landas_hud) noch auslesen
local LEGACY_FIELDS = { "PrimaryChannel", "SecondaryChannel", "F3Channel" }

local YELLOW = SYMUI and SYMUI.LiveAccent() or Color(238, 180, 53) -- #eeb435, Rahmenfarbe der F-Boxen
local WHITE = SYMUI and SYMUI.col.text or Color(244, 241, 233)
local SOFT = SYMUI and SYMUI.col.dim or Color(191, 197, 205)
local MUTED = SYMUI and SYMUI.col.muted or Color(111, 118, 128)
local RED = Color(225, 88, 88)
local BOX_BG = SYMUI and Color(9, 11, 14, 215) or Color(23, 24, 27, 212) -- #17181b, 83 % sichtbar
local BOX_ACTIVE = SYMUI and SYMUI.LiveAccent(30) or Color(238, 180, 53, 30)

local function localState()
    local ply = LocalPlayer()
    if not IsValid(ply) then return nil end

    ply.hradio = ply.hradio or {}
    ply.hradio.MutedChannels = ply.hradio.MutedChannels or {}
    ply.hradio.Hotkeys = ply.hradio.Hotkeys or {}

    return ply
end

local function playUISound(path)
    if hradio.Config and hradio.Config.UISounds then
        surface.PlaySound(path)
    end
end

local function syncLegacyFields(ply)
    for slot, field in ipairs(LEGACY_FIELDS) do
        ply.hradio[field] = ply.hradio.Hotkeys[slot]
    end
end

-- Dem Server mitteilen, welchen Funks wir beigetreten sind
local function sendJoinedChannels(ply)
    local ids = {}

    for _, id in pairs(ply.hradio.Hotkeys) do
        if hradio.Channels[id] then
            ids[#ids + 1] = id
        end
    end

    net.Start("hRadio_PlyJoinedChannels")
    net.WriteUInt(#ids, 5)
    for _, id in ipairs(ids) do
        net.WriteUInt(id, hradio.ChannelMaxBitSize)
    end
    net.SendToServer()
end

function hradio.GetHotkeySlots()
    return (hradio.Config and hradio.Config.HotkeySlots) or {}
end

function hradio.CanTalkOnChannel(id, ply)
    ply = ply or LocalPlayer()

    local chan = hradio.Channels and hradio.Channels[id]
    if not chan or not IsValid(ply) then return false end

    if chan.GetTalkers(ply) then return true end
    return chan.Talkers[ply:Team()] == true
end

-- Hört man diesen Funk? (beigetreten, gerade aktiv, oder nicht stummschaltbar wie Ankündigung)
function hradio.IsChannelJoined(id)
    local ply = localState()
    local chan = hradio.Channels and hradio.Channels[id]
    if not ply or not chan then return false end

    if not chan.Mutable then return true end
    if ply.hradio.ActiveChannel == id then return true end

    return hradio.GetChannelHotkey(id) ~= nil
end

-- Beim Laden ist nichts belegt: jeder Join startet frisch
function hradio.LoadHotkeys()
    local ply = localState()
    if not ply then return end

    ply.hradio.Hotkeys = {}

    for slot = 1, 9 do
        cookie.Delete(OLD_COOKIE_PREFIX .. slot)
    end

    syncLegacyFields(ply)
    sendJoinedChannels(ply)
end

function hradio.GetHotkeyChannel(slot)
    local ply = localState()
    if not ply then return nil end

    local id = ply.hradio.Hotkeys[slot]
    if id and hradio.Channels[id] then return id end
end

function hradio.GetChannelHotkey(id)
    for slot in ipairs(hradio.GetHotkeySlots()) do
        if hradio.GetHotkeyChannel(slot) == id then return slot end
    end
end

function hradio.SetHotkeyChannel(slot, id)
    local ply = localState()
    if not ply or not hradio.GetHotkeySlots()[slot] then return end

    id = tonumber(id) or 0
    if id <= 0 or not hradio.Channels[id] then id = nil end

    -- Ein Funk kann immer nur auf einer Taste liegen
    if id then
        for other, bound in pairs(ply.hradio.Hotkeys) do
            if bound == id and other ~= slot then
                ply.hradio.Hotkeys[other] = nil
            end
        end
    end

    ply.hradio.Hotkeys[slot] = id
    syncLegacyFields(ply)
    sendJoinedChannels(ply)

    hook.Run("hRadio_HotkeysChanged", slot, id)
end

-- Wird vom Funkmenü benutzt: legt den Funk auf die Taste, oder löst ihn, wenn er dort schon liegt
function hradio.ToggleHotkeyBinding(slot, id)
    local def = hradio.GetHotkeySlots()[slot]
    if not def then return end

    local chan = hradio.Channels[id]
    if not chan then return end

    if hradio.GetHotkeyChannel(slot) == id then
        hradio.SetHotkeyChannel(slot, nil)
        notification.AddLegacy("Funk „" .. chan.Name .. "“ verlassen. " .. def.Label .. " ist jetzt frei.", NOTIFY_GENERIC, 3)
        playUISound("buttons/button5.wav")
        return
    end

    hradio.SetHotkeyChannel(slot, id)

    if hradio.CanTalkOnChannel(id) then
        notification.AddLegacy("Funk „" .. chan.Name .. "“ beigetreten (" .. def.Label .. "). " .. def.Label .. " drücken = sprechen an/aus.", NOTIFY_GENERIC, 4)
    else
        notification.AddLegacy("Funk „" .. chan.Name .. "“ beigetreten (" .. def.Label .. "). Hier kannst du nur zuhören.", NOTIFY_GENERIC, 4)
    end

    playUISound("buttons/combine_button1.wav")
end

function hradio.UseHotkey(slot)
    local ply = localState()
    if not ply then return end

    local def = hradio.GetHotkeySlots()[slot]
    if not def then return end

    if hradio.IsGRNCommsBlocked and hradio.IsGRNCommsBlocked() then
        if hradio.ShowGRNCommsBlocked then hradio.ShowGRNCommsBlocked() end
        return
    end

    local id = hradio.GetHotkeyChannel(slot)

    if not id then
        notification.AddLegacy(def.Label .. " ist noch frei. Öffne das Funkmenü und lege einen Funk auf " .. def.Label .. ".", NOTIFY_HINT, 4)
        playUISound("buttons/button10.wav")
        return
    end

    local chan = hradio.Channels[id]

    if ply.hradio.ActiveChannel == id then
        if ply.hradio.RadioTalkStarted then
            RunConsoleCommand("-hradio_talk")
        end

        hradio.ChangeActiveChannel(0)
        notification.AddLegacy("Funk aus: " .. chan.Name, NOTIFY_GENERIC, 2)
        playUISound("buttons/combine_button2.wav")
    else
        if not hradio.CanTalkOnChannel(id, ply) then
            notification.AddLegacy("Auf „" .. chan.Name .. "“ darfst du nicht sprechen.", NOTIFY_ERROR, 3)
            playUISound("buttons/button10.wav")
            return
        end

        if ply.hradio.RadioTalkStarted then
            RunConsoleCommand("-hradio_talk")
        end

        if ply.hradio.MutedChannels[id] then
            ply.hradio.MutedChannels[id] = false
            hradio.ChangeMuteStatus(id, false)
        end

        hradio.ChangeActiveChannel(id)
        notification.AddLegacy("Funk an: " .. chan.Name, NOTIFY_GENERIC, 2)
        playUISound("buttons/combine_button_locked.wav")
    end

    ply.hradio.HotkeyFlash = { slot = slot, time = SysTime() }
end

hook.Add("PlayerButtonDown", "hRadio_Hotkeys", function(ply, button)
    if not IsFirstTimePredicted() then return end
    if ply ~= LocalPlayer() then return end
    if hradio.Config.HotkeysEnabled == false then return end
    if gui.IsGameUIVisible() or ply:IsTyping() then return end

    for slot, def in ipairs(hradio.GetHotkeySlots()) do
        if def.Key == button then
            hradio.UseHotkey(slot)
            return
        end
    end
end)

---------------------------------------------
-- HUD: F-Boxen oben rechts (nur belegte) --
---------------------------------------------

local hudFontScale

local function createHudFonts(s)
    hudFontScale = s

    surface.CreateFont("hRadio_HudKey", {
        font = SYMUI and SYMUI.FontFace("body") or "Rajdhani",
        size = math.floor(13 * s),
        weight = 700,
        antialias = true
    })

    surface.CreateFont("hRadio_HudName", {
        font = SYMUI and SYMUI.FontFace("head") or "Rajdhani",
        size = math.floor(21 * s),
        weight = 700,
        antialias = true
    })
end

local function hudScale()
    return math.Clamp(ScrH() / 1080, 0.75, 1.15)
end

-- Position der F-Boxen, damit die Sprecheranzeige direkt darunter sitzen kann
function hradio.GetHotkeyHUDLayout()
    local s = hudScale()
    local top = math.floor(ScrH() * (hradio.Config.HotkeyHUDY or 0) + (hradio.Config.HotkeyHUDOffset or 50) * s)
    local right = ScrW() - math.floor((hradio.Config.HotkeyHUDOffsetX or 42) * s)

    if hradio.Config.HotkeysEnabled == false or hradio.Config.ShowHotkeyHUD == false then
        return top, right
    end

    return top + math.floor(42 * s), right
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

local function drawBoxFrame(x, y, w, h, active, flashAlpha)
    if SYMUI then
        -- SymChars-Look: abgeschrägte Platte, Akzentrahmen
        local c = math.min(SYMUI.S(8), math.floor(h / 3))
        SYMUI.Cut(x, y, w, h, BOX_BG, c, "tlbr")
        if active then SYMUI.Cut(x, y, w, h, BOX_ACTIVE, c, "tlbr") end
        if flashAlpha and flashAlpha > 0 then SYMUI.Cut(x, y, w, h, Color(YELLOW.r, YELLOW.g, YELLOW.b, flashAlpha), c, "tlbr") end
        SYMUI.CutOutline(x, y, w, h, Color(YELLOW.r, YELLOW.g, YELLOW.b, active and 255 or 120), c, "tlbr")
        if active then SYMUI.Glow(x, y, w, h, SYMUI.Accent(160), SYMUI.S(6), 0.6) end
        return
    end
    SY_RoundedBox(0, x, y, w, h, BOX_BG)

    if active then
        SY_RoundedBox(0, x, y, w, h, BOX_ACTIVE)
    end

    if flashAlpha and flashAlpha > 0 then
        SY_RoundedBox(0, x, y, w, h, Color(238, 180, 53, flashAlpha))
    end

    surface.SetDrawColor(YELLOW.r, YELLOW.g, YELLOW.b, active and 255 or 190)
    surface.DrawOutlinedRect(x, y, w, h, active and 2 or 1)
end

hook.Add("HUDPaint", "hRadioHotkeyHud", function()
    if hradio.Config.HotkeysEnabled == false or hradio.Config.ShowHotkeyHUD == false then return end

    local ply = localState()
    if not ply or not ply:Alive() then return end

    local s = hudScale()
    if hudFontScale ~= s then createHudFonts(s) end
    local margin = math.floor((hradio.Config.HotkeyHUDOffsetX or 42) * s)
    local gap = math.floor(6 * s)
    local boxW = math.floor(142 * s)
    local boxH = math.floor(42 * s)
    local top = math.floor(ScrH() * (hradio.Config.HotkeyHUDY or 0) + (hradio.Config.HotkeyHUDOffset or 50) * s)

    local blocked = hradio.IsGRNCommsBlocked and hradio.IsGRNCommsBlocked()

    -- Nur die Tasten zeigen, auf denen ein Funk liegt
    local visible = {}
    for slot, def in ipairs(hradio.GetHotkeySlots()) do
        local id = hradio.GetHotkeyChannel(slot)
        if id then
            visible[#visible + 1] = { slot = slot, def = def, id = id, chan = hradio.Channels[id] }
        end
    end

    -- Noch nichts belegt: oben rechts bleibt alles leer
    if #visible == 0 then return end

    local total = #visible * boxW + (#visible - 1) * gap
    local x = ScrW() - margin - total
    local flash = ply.hradio.HotkeyFlash

    for _, entry in ipairs(visible) do
        local id, chan, label = entry.id, entry.chan, entry.def.Label
        local active = ply.hradio.ActiveChannel == id
        local muted = ply.hradio.MutedChannels[id]
        local canTalk = hradio.CanTalkOnChannel(id, ply)

        local flashAlpha = 0
        if flash and flash.slot == entry.slot then
            local t = SysTime() - flash.time
            if t < 0.35 then flashAlpha = 70 * (1 - t / 0.35) end
        end

        drawBoxFrame(x, top, boxW, boxH, active, flashAlpha)

        -- Text in Weiß-Grau wie der Funkname
        local nameColor = active and WHITE or SOFT
        if muted or not canTalk then nameColor = MUTED end

        -- Obere Zeile: Taste + Status
        local status, statusColor = label, nameColor

        if blocked then
            status, statusColor = label .. "  ·  OFFLINE", RED
        elseif active and ply.hradio.IsTalking then
            local pulse = 150 + 105 * math.abs(math.sin(CurTime() * 6))
            status, statusColor = label .. "  ·  DU SENDEST", Color(WHITE.r, WHITE.g, WHITE.b, pulse)
        elseif active then
            status = label .. "  ·  AKTIV"
        elseif muted then
            status, statusColor = label .. "  ·  STUMM", RED
        elseif not canTalk then
            status, statusColor = label .. "  ·  KEIN ZUGRIFF", RED
        end

        draw.SimpleText(status, "hRadio_HudKey", x + boxW * 0.5, top + math.floor(10 * s), statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Funkname (statt "-/-")
        local name = fitText(chan.Name, "hRadio_HudName", boxW - math.floor(12 * s))
        draw.SimpleText(name, "hRadio_HudName", x + boxW * 0.5, top + math.floor(25 * s), nameColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Farbstreifen des Funks unten
        local c = chan.Color
        surface.SetDrawColor(c.r, c.g, c.b, active and 255 or 170)
        surface.DrawRect(x + math.floor(5 * s), top + boxH - math.floor(4 * s), boxW - math.floor(10 * s), math.max(2, math.floor(2 * s)))

        x = x + boxW + gap
    end
end)

hradio.LoadHotkeys()
