-- Textfunk auf dem Comlink (Strivon Comlink)
-- Taste J hebt den linken Arm mit dem Comlink und zeigt darüber das Funksystem als Hologramm,
-- im gleichen Stil wie Funk (H) und Squad (G). Es ist immer nur eine App offen: J bei offenem
-- Funk/Squad wechselt direkt, J nochmal (oder ESC) schließt das Comlink.
-- Reiter: SENDEN (Empfänger, Nachricht, Kurz-/Langstrecke, Verschlüsselung), FUNKLOG, BEFEHLE.
-- Die Chat-Befehle (/funk, /vfunk, /lfunk, /vlfunk, /akt, ...) bleiben unverändert.
-- Kein Datapad nötig. Nur in der Ego-Perspektive, in der Third Person öffnet sich nichts.

CryptoRadio = CryptoRadio or {}

local cfg = CryptoRadio.Config
local SHORT, LONG = CryptoRadio.RANGE_SHORT, CryptoRadio.RANGE_LONG
local APP = "crypto"

local MENU_W = 380
local HEADER_H = 58
local TAB_H = 32
local PAD_X = 14
local GAP = 5
local ROW_H = 38
local ROW_GAP = 4
local LABEL_H = 22
local MSG_H = 62
local MSG_LINES = 3
local OPT_H = 30
local SEND_H = 36
local HELP_H = 32
local HELP_GAP = 3
local LOG_LINE_H = 15
local LOG_COLLAPSED_LINES = 2
local UNITS_TO_M = 0.01905

-- Zustand überlebt Lua-Refresh
CRYPTORADIO_COMLINK = CRYPTORADIO_COMLINK or {}
local st = CRYPTORADIO_COMLINK
st.tab = st.tab or "send"
st.rcp = st.rcp or { scroll = 0 }
st.log = st.log or { scroll = 0 }

local TABS = {
    { id = "send", label = "SENDEN" },
    { id = "log", label = "FUNKLOG" },
    { id = "help", label = "BEFEHLE" }
}
local TAB_BY_INDEX = { "send", "log", "help" }

local UI -- hradio.ComlinkUI, wird beim Registrieren gesetzt

local function visibleRecipients()
    return math.max(1, math.floor(tonumber(cfg.ComlinkVisibleRecipients) or 4))
end

local function listHeight()
    local v = visibleRecipients()
    return v * ROW_H + (v - 1) * ROW_GAP
end

local function contentHeight()
    local send = LABEL_H + 4 + listHeight() + 8 + LABEL_H + MSG_H + 8 + OPT_H + 8 + SEND_H
    local help = #(CryptoRadio.Help or {}) * (HELP_H + HELP_GAP) + 40
    return math.max(send, help)
end

local function menuHeight()
    return HEADER_H + TAB_H + 8 + contentHeight() + 6
end

local function createFonts()
    local head = UI.fontFace("head", "BigNoodleTitling")
    local body = UI.fontFace("body", "Roboto Condensed")

    surface.CreateFont("CryptoRadio_CL_Title", { font = head, size = 34, weight = 400, antialias = true, extended = true })
    surface.CreateFont("CryptoRadio_CL_Label", { font = head, size = 17, weight = 400, antialias = true, extended = true })
    surface.CreateFont("CryptoRadio_CL_Tab", { font = head, size = 22, weight = 400, antialias = true, extended = true })
    surface.CreateFont("CryptoRadio_CL_Btn", { font = head, size = 19, weight = 400, antialias = true, extended = true })
    surface.CreateFont("CryptoRadio_CL_Name", { font = head, size = 20, weight = 400, antialias = true, extended = true })
    surface.CreateFont("CryptoRadio_CL_Dist", { font = head, size = 18, weight = 400, antialias = true, extended = true })
    surface.CreateFont("CryptoRadio_CL_Text", { font = body, size = 15, weight = 600, antialias = true, extended = true })
    surface.CreateFont("CryptoRadio_CL_Cmd", { font = body, size = 14, weight = 700, antialias = true, extended = true })
    surface.CreateFont("CryptoRadio_CL_Tag", { font = body, size = 12, weight = 700, antialias = true, extended = true })
    surface.CreateFont("CryptoRadio_CL_Hint", { font = body, size = 11, weight = 600, antialias = true, extended = true })
end

------------------
-- Hilfen
------------------

local function notify(text, isErr)
    if CryptoRadio.ClientNotify then CryptoRadio.ClientNotify(text, isErr) end
end

local function sound(path)
    UI.playUISound(path)
end

local function readable(col)
    if SYMUI and SYMUI.Readable then
        local ok, out = pcall(SYMUI.Readable, col, 120)
        if ok and out then return out end
    end
    return col
end

-- SymChars: Einheitsfarbe des aktiven Charakters (für den Namen)
local function unitColor(ply)
    if not ply.GetCharacter then return end

    local ok, char = pcall(ply.GetCharacter, ply)
    if not ok or not char then return end

    local faction = char.GetFaction and char:GetFaction()
    if faction and faction.GetColor then return readable(faction:GetColor()) end
end

-- Bricht Text in Zeilen um, die in maxW passen (lange Wörter werden zerteilt)
local function wrapText(text, font, maxW)
    surface.SetFont(font)
    local lines, cur = {}, ""

    for word in string.gmatch(text or "", "%S+") do
        local try = cur == "" and word or (cur .. " " .. word)

        if surface.GetTextSize(try) <= maxW then
            cur = try
        else
            if cur ~= "" then lines[#lines + 1] = cur end

            if surface.GetTextSize(word) > maxW then
                local piece = ""
                for _, code in utf8.codes(word) do
                    local ch = utf8.char(code)
                    if piece ~= "" and surface.GetTextSize(piece .. ch) > maxW then
                        lines[#lines + 1] = piece
                        piece = ch
                    else
                        piece = piece .. ch
                    end
                end
                cur = piece
            else
                cur = word
            end
        end
    end

    if cur ~= "" then lines[#lines + 1] = cur end
    return lines
end

local function safeWrap(text, font, maxW)
    local ok, lines = pcall(wrapText, text, font, maxW)
    return ok and lines or { tostring(text or "") }
end

local arrowPts = { { x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = 0 } }

-- Pfeil zeigt, wo der Empfänger relativ zur Blickrichtung steht (oben = vor dir)
local function drawArrow(cx, cy, size, rel, col)
    local phi = math.rad(-rel)
    local c, s = math.cos(phi), math.sin(phi)
    local base = { { 0, -size }, { size * 0.62, size * 0.72 }, { -size * 0.62, size * 0.72 } }

    for i, p in ipairs(base) do
        arrowPts[i].x = cx + p[1] * c - p[2] * s
        arrowPts[i].y = cy + p[1] * s + p[2] * c
    end

    draw.NoTexture()
    surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
    UI.drawPoly({ arrowPts[1], arrowPts[2], arrowPts[3] })
end

-- Abschnittstitel mit Akzentstrich
local function sectionLabel(text, x, y)
    local pal = UI.pal
    UI.rect(x, y + 4, 2, LABEL_H - 10, pal.accent)
    draw.SimpleText(text, "CryptoRadio_CL_Label", x + 8, y + LABEL_H * 0.5 - 1, pal.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

------------------
-- Eingabefeld (unsichtbares DTextEntry, Text wird im Hologramm gezeichnet)
------------------

local function removeEntry()
    if IsValid(st.entryPanel) then st.entryPanel:Remove() end
    st.entryPanel = nil
    CryptoRadio.ComlinkEntry = nil
end

local sendDraft
local focusEntry

focusEntry = function()
    local draft = CryptoRadio.Draft

    if not IsValid(st.entryPanel) then
        local pnl = vgui.Create("EditablePanel")
        pnl:SetPos(-4000, -4000)
        pnl:SetSize(600, 40)
        pnl.Paint = nil

        local e = vgui.Create("DTextEntry", pnl)
        e:Dock(FILL)
        e:SetMultiline(false)
        e:SetUpdateOnType(true)
        e:SetText(draft.text or "")
        e.AllowInput = function(s, ch)
            return (utf8.len(s:GetValue()) or 0) >= cfg.MaxLength
        end
        e.OnChange = function(s)
            draft.text = s:GetValue()
        end
        e.OnValueChange = e.OnChange
        e.OnEnter = function()
            if sendDraft then sendDraft() end
            -- Senden ging nicht (z.B. kein Empfänger): weiterschreiben können
            if IsValid(st.entryPanel) then
                timer.Simple(0, function() if IsValid(st.entryPanel) then focusEntry() end end)
            end
        end

        st.entryPanel = pnl
        CryptoRadio.ComlinkEntry = e
    end

    st.entryPanel:MakePopup()
    st.entryPanel:SetMouseInputEnabled(false)
    st.entryPanel:SetKeyboardInputEnabled(true)

    local e = CryptoRadio.ComlinkEntry
    e:RequestFocus()
    e:SetCaretPos(utf8.len(e:GetValue()) or #e:GetValue())
    st.entryTime = RealTime()
end

local function entryFocused()
    local e = CryptoRadio.ComlinkEntry
    return IsValid(e) and e:HasFocus()
end

------------------
-- Senden
------------------

local function selectedTargets()
    local draft = CryptoRadio.Draft
    local uids = {}

    for _, p in ipairs(CryptoRadio.EligiblePlayers()) do
        local uid = p:UserID()
        if draft.selected[uid] and CryptoRadio.InRangeClient(p, draft.range) ~= false then
            uids[#uids + 1] = uid
        end
    end

    return uids
end

sendDraft = function()
    local draft = CryptoRadio.Draft
    local text = string.Trim(((draft.text or ""):gsub("[\r\n\t]", " ")))

    if (CryptoRadio.NextSend[draft.range] or 0) > CurTime() then
        sound(cfg.Sounds.Error)
        return
    end

    if text == "" then
        notify("Bitte zuerst eine Nachricht eingeben.", true)
        return
    end

    local uids = selectedTargets()
    if #uids == 0 then
        notify("Bitte mindestens einen Empfänger auswählen.", true)
        return
    end

    local count = math.min(#uids, 128)
    net.Start("CryptoRadio_Send")
        net.WriteUInt(draft.range, 2)
        net.WriteString(text)
        net.WriteBool(draft.encrypt)
        net.WriteUInt(count, 8)
        for i = 1, count do net.WriteUInt(uids[i], 32) end
    net.SendToServer()

    removeEntry()
    if cfg.ComlinkCloseAfterSend ~= false then
        hradio.CloseComlink()
    end
end

------------------
-- Kopf + Reiter
------------------

local function unreadCount()
    local n = 0
    for _, e in ipairs(CryptoRadio.Log) do
        if e == st.lastSeen then break end
        if e.dir == "in" then n = n + 1 end
    end
    return n
end

local function drawHeader(ply)
    local pal = UI.pal

    draw.SimpleText("TEXTFUNK", "CryptoRadio_CL_Title", 16, 20, Color(0, 0, 0, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("TEXTFUNK", "CryptoRadio_CL_Title", 15, 19, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    UI.drawAurebesh("TEXTFUNK", 16, 42, 16, Color(pal.accent.r, pal.accent.g, pal.accent.b, 200))

    local status, col
    if CryptoRadio.IsJammed(ply:GetPos()) then
        local pulse = 150 + 105 * math.abs(math.sin(CurTime() * 6))
        status, col = "STÖRSENDER ERKANNT", Color(pal.redText.r, pal.redText.g, pal.redText.b, pulse)
    elseif CryptoRadio.IsAntennaDown() then
        status, col = "LANGSTRECKE AUSGEFALLEN", pal.redText
    else
        status, col = "SIGNAL STABIL", pal.green
    end

    local right = MENU_W - 16
    draw.SimpleText(status, "CryptoRadio_CL_Label", right, 18, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    local reachable = 0
    for _, p in ipairs(CryptoRadio.EligiblePlayers()) do
        if CryptoRadio.InRangeClient(p, CryptoRadio.Draft.range) ~= false then reachable = reachable + 1 end
    end
    draw.SimpleText(reachable .. " EMPFÄNGER ERREICHBAR", "CryptoRadio_CL_Tag", right, 38, pal.soft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

local function drawTabs(x, y, w)
    local tabW = (w - GAP * (#TABS - 1)) / #TABS
    local unread = st.tab ~= "log" and unreadCount() or 0

    for i, tab in ipairs(TABS) do
        local label = tab.label
        if tab.id == "log" and unread > 0 then label = label .. " (" .. unread .. ")" end

        local tx = x + (i - 1) * (tabW + GAP)
        if UI.button(tx, y, tabW, TAB_H, label, st.tab == tab.id and "on" or nil, true, "CryptoRadio_CL_Tab") and st.tab ~= tab.id then
            st.tab = tab.id
            removeEntry()
            sound(cfg.Sounds.Click)
        end
    end
end

------------------
-- Reiter: SENDEN
------------------

local function drawRecipient(lp, p, x, y, w)
    local pal = UI.pal
    local draft = CryptoRadio.Draft
    local uid = p:UserID()
    local state = CryptoRadio.InRangeClient(p, draft.range)
    local usable = state ~= false
    local sel = draft.selected[uid] and usable
    local hov = usable and UI.hovering(x, y, w, ROW_H)

    UI.withAlpha(usable and 1 or 0.45, function()
        UI.fillCut(x, y, w, ROW_H, 7, hov and pal.panel2 or pal.panel)
        if sel then UI.fillCut(x, y, w, ROW_H, 7, pal.accentFaint) end
        UI.outlineCut(x, y, w, ROW_H, 7, sel and pal.accentSoft or (hov and pal.line2 or pal.line), 1)
        UI.rect(x, y + 7, 3, ROW_H - 7, sel and pal.accent or pal.line2)

        -- Auswahlkästchen
        local bx, by = x + 11, y + ROW_H * 0.5 - 7
        UI.outlineCut(bx, by, 14, 14, 3, sel and pal.accent or pal.line2, 1.2)
        if sel then UI.fillCut(bx + 3, by + 3, 8, 8, 2, pal.accent) end

        -- rechts: Entfernung + Richtung
        local rightX = x + w - 10
        local rightW = 0

        if not p:IsDormant() then
            local diff = p:GetPos() - lp:GetPos()
            local meters = math.floor(diff:Length() * UNITS_TO_M + 0.5)
            local rel = math.NormalizeAngle(diff:Angle().y - lp:EyeAngles().y)

            draw.SimpleText(meters .. " M", "CryptoRadio_CL_Dist", rightX - 18, y + ROW_H * 0.5, pal.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            drawArrow(rightX - 6, y + ROW_H * 0.5, 6, rel, pal.accent)
            rightW = 74
        end

        -- Name (Einheitsfarbe) + Status
        local nameX = bx + 22
        local name = UI.fitText(string.upper(CryptoRadio.GetName(p)), "CryptoRadio_CL_Name", w - (nameX - x) - rightW - 6)
        draw.SimpleText(name, "CryptoRadio_CL_Name", nameX, y + 13, sel and pal.text or (unitColor(p) or pal.text), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local status, scol
        if draft.range == LONG then
            status, scol = "LANGSTRECKE", pal.accent
        elseif state == nil then
            status, scol = "POSITION UNBEKANNT", pal.muted
        elseif state then
            status, scol = "IN REICHWEITE", pal.green
        else
            status, scol = "AUSSER REICHWEITE", pal.redText
        end
        if not p:Alive() then status, scol = "NICHT ERREICHBAR", pal.redText end
        draw.SimpleText(status, "CryptoRadio_CL_Tag", nameX, y + 28, scol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)

    if UI.clicked(x, y, w, ROW_H) then
        if not usable then
            sound(cfg.Sounds.Error)
        else
            sound(cfg.Sounds.Click)
            draft.selected[uid] = not draft.selected[uid] or nil
        end
    end
end

local function drawMessageBox(x, y, w)
    local pal = UI.pal
    local draft = CryptoRadio.Draft
    local focused = entryFocused()
    local hov = UI.hovering(x, y, w, MSG_H)

    UI.fillCut(x, y, w, MSG_H, 7, focused and pal.panel2 or pal.panel)
    UI.outlineCut(x, y, w, MSG_H, 7, focused and pal.accent or (hov and pal.accentSoft or pal.line2), focused and 1.5 or 1)

    local text = draft.text or ""
    local tx, ty = x + 10, y + 8

    if text == "" then
        local hint = focused and "Schreiben ...  ENTER = senden" or "Hier klicken und Funkspruch eingeben ..."
        draw.SimpleText(hint, "CryptoRadio_CL_Text", tx, ty + 8, pal.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if focused and math.floor(RealTime() * 2) % 2 == 0 then
            UI.rect(tx, ty, 1, 16, pal.accent)
        end
    else
        local lines = safeWrap(text, "CryptoRadio_CL_Text", w - 22)
        local first = math.max(1, #lines - MSG_LINES + 1) -- immer das Ende zeigen

        surface.SetFont("CryptoRadio_CL_Text")
        local lastW = 0
        for i = first, #lines do
            local ly = ty + (i - first) * 17
            draw.SimpleText(lines[i], "CryptoRadio_CL_Text", tx, ly + 8, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            lastW = surface.GetTextSize(lines[i])
        end

        if focused and math.floor(RealTime() * 2) % 2 == 0 then
            local ly = ty + (#lines - first) * 17
            UI.rect(tx + lastW + 2, ly, 1, 16, pal.accent)
        end
    end

    if UI.clicked(x, y, w, MSG_H) then
        focusEntry()
    end
end

local function drawSendTab(ply, x, y, w)
    local pal = UI.pal
    local draft = CryptoRadio.Draft
    local list = CryptoRadio.EligiblePlayers()
    local rows = visibleRecipients()
    local scrollW = UI.SCROLL_W or 8

    -- Empfänger
    sectionLabel("EMPFÄNGER", x, y)

    local bw, bh = 54, 20
    if UI.button(x + w - bw, y + 1, bw, bh, "KEINE", nil, true, "CryptoRadio_CL_Btn") then
        draft.selected = {}
        sound(cfg.Sounds.Click)
    end
    if UI.button(x + w - bw * 2 - GAP, y + 1, bw, bh, "ALLE", nil, #list > 0, "CryptoRadio_CL_Btn") then
        for _, p in ipairs(list) do
            if CryptoRadio.InRangeClient(p, draft.range) ~= false then draft.selected[p:UserID()] = true end
        end
        sound(cfg.Sounds.Click)
    end

    y = y + LABEL_H + 4
    local listH = listHeight()
    local cardW = w - scrollW - 8

    st.rcp.scroll = math.Clamp(st.rcp.scroll, 0, math.max(0, #list - rows))
    st.overList = UI.hovering(x, y, w, listH)

    if #list == 0 then
        UI.fillCut(x, y, cardW, ROW_H + 8, 7, pal.panel)
        UI.outlineCut(x, y, cardW, ROW_H + 8, 7, pal.accentDim, 1)
        draw.SimpleText("KEINE EMPFÄNGER", "CryptoRadio_CL_Name", x + 14, y + 15, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Gerade ist kein anderer Spieler online.", "CryptoRadio_CL_Tag", x + 14, y + 33, pal.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    else
        for i = 1, rows do
            local p = list[st.rcp.scroll + i]
            if not p then break end
            if IsValid(p) then
                drawRecipient(ply, p, x, y + (i - 1) * (ROW_H + ROW_GAP), cardW)
            end
        end
    end

    UI.drawScrollbar(x + w - scrollW, y, listH, #list, rows, st.rcp)

    -- Nachricht
    y = y + listH + 8
    sectionLabel("NACHRICHT", x, y)

    local n = utf8.len(draft.text or "") or 0
    draw.SimpleText(n .. " / " .. cfg.MaxLength, "CryptoRadio_CL_Tag", x + w, y + LABEL_H * 0.5 - 1, n >= cfg.MaxLength and pal.redText or pal.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    y = y + LABEL_H
    drawMessageBox(x, y, w)

    -- Funkart + Verschlüsselung
    y = y + MSG_H + 8
    local optW = (w - GAP * 2) / 3
    local antennaDown = CryptoRadio.IsAntennaDown()

    if UI.button(x, y, optW, OPT_H, "KURZSTRECKE", draft.range == SHORT and "on" or nil, true, "CryptoRadio_CL_Btn") and draft.range ~= SHORT then
        draft.range = SHORT
        sound(cfg.Sounds.Click)
    end

    local longStyle = draft.range == LONG and "on" or nil
    if antennaDown and cfg.LongRangeNeedsAntenna then longStyle = "alert" end
    if UI.button(x + optW + GAP, y, optW, OPT_H, "LANGSTRECKE", longStyle, true, "CryptoRadio_CL_Btn") and draft.range ~= LONG then
        draft.range = LONG
        sound(cfg.Sounds.Click)
    end

    if UI.button(x + (optW + GAP) * 2, y, optW, OPT_H, draft.encrypt and "VERSCHL.: AN" or "VERSCHL.: AUS", draft.encrypt and "on" or nil, true, "CryptoRadio_CL_Btn") then
        draft.encrypt = not draft.encrypt
        sound(cfg.Sounds.Click)
    end

    -- Senden
    y = y + OPT_H + 8
    local remain = (CryptoRadio.NextSend[draft.range] or 0) - CurTime()
    local label

    if remain > 0 then
        label = string.format("FUNKGERÄT LÄDT ... %.1fS", remain)
    else
        label = (draft.encrypt and "VERSCHLÜSSELT · " or "") .. (draft.range == LONG and "LANGSTRECKE SENDEN" or "KURZSTRECKE SENDEN")
    end

    if UI.button(x, y, w, SEND_H, label, "primary", remain <= 0, "CryptoRadio_CL_Tab") then
        sendDraft()
    end
end

------------------
-- Reiter: FUNKLOG
------------------

local function logLines(e, w)
    if e._wrapW ~= w then
        e._lines = safeWrap(e.text or "", "CryptoRadio_CL_Text", w)
        if #e._lines == 0 then e._lines = { "" } end
        e._wrapW = w
    end
    return e._lines
end

local function drawLogEntry(e, x, y, w, maxH)
    local pal = UI.pal
    local expanded = st.expanded == e
    local lines = logLines(e, w - 24)
    local shown = expanded and #lines or math.min(#lines, LOG_COLLAPSED_LINES)
    shown = math.max(1, math.min(shown, math.floor((maxH - 52) / LOG_LINE_H)))
    local h = 46 + shown * LOG_LINE_H + 6

    if h > maxH then return nil end

    local hov = UI.hovering(x, y, w, h)
    local incoming = e.dir == "in"
    local stripe = e.encrypted and pal.green or (e.range == LONG and pal.accent or pal.soft)

    UI.fillCut(x, y, w, h, 8, hov and pal.panel2 or pal.panel)
    if expanded then UI.fillCut(x, y, w, h, 8, pal.accentFaint) end
    UI.outlineCut(x, y, w, h, 8, expanded and pal.accentSoft or (e.jammed and pal.redLine or pal.line), 1)
    UI.rect(x, y + 8, 3, h - 8, stripe)

    -- EIN / AUS
    local bx, by = x + 11, y + 6
    UI.fillCut(bx, by, 32, 20, 5, incoming and pal.accent or pal.panel3)
    draw.SimpleText(incoming and "EIN" or "AUS", "CryptoRadio_CL_Label", bx + 16, by + 11, incoming and pal.ink or pal.soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Absender / Empfänger + Uhrzeit
    local time = os.date("%H:%M", e.time or 0)
    surface.SetFont("CryptoRadio_CL_Tag")
    local timeW = surface.GetTextSize(time)
    local who = incoming and e.sender or ("» " .. table.concat(e.targets or {}, ", "))
    who = UI.fitText(string.upper(who or ""), "CryptoRadio_CL_Name", w - 60 - timeW - 14)

    draw.SimpleText(who, "CryptoRadio_CL_Name", bx + 40, by + 10, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(time, "CryptoRadio_CL_Tag", x + w - 10, by + 10, pal.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    -- Kennzeichnung
    local tx, ty = x + 12, y + 35
    local function tag(text, col)
        local tw = draw.SimpleText(text, "CryptoRadio_CL_Tag", tx, ty, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        tx = tx + tw + 10
    end
    tag(e.range == LONG and "LANGSTRECKE" or "KURZSTRECKE", e.range == LONG and pal.accent or pal.soft)
    if e.encrypted then tag("VERSCHLÜSSELT", pal.green) end
    if e.jammed then tag("GESTÖRT", pal.redText) end

    if #lines > LOG_COLLAPSED_LINES then
        draw.SimpleText(expanded and "▲ WENIGER" or "▼ MEHR", "CryptoRadio_CL_Hint", x + w - 10, ty, hov and pal.accent or pal.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Nachricht
    local col = e.jammed and pal.redText or pal.text
    for i = 1, shown do
        local line = lines[i]
        if i == shown and shown < #lines then line = line .. " .." end
        draw.SimpleText(line, "CryptoRadio_CL_Text", x + 12, y + 46 + (i - 1) * LOG_LINE_H + 7, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if UI.clicked(x, y, w, h) then
        st.expanded = expanded and nil or e
        sound(cfg.Sounds.Click)
    end

    return h
end

local function drawLogTab(ply, x, y, w, areaH)
    local pal = UI.pal
    local log = CryptoRadio.Log
    local scrollW = UI.SCROLL_W or 8

    st.lastSeen = log[1]

    sectionLabel("FUNKLOG", x, y)
    draw.SimpleText(#log .. " EINTRÄGE", "CryptoRadio_CL_Tag", x + 90, y + LABEL_H * 0.5 - 1, pal.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    if UI.button(x + w - 64, y + 1, 64, 20, "LEEREN", "alert", #log > 0, "CryptoRadio_CL_Btn") then
        CryptoRadio.Log = {}
        st.log.scroll = 0
        st.expanded = nil
        st.lastSeen = nil
        sound(cfg.Sounds.Click)
        return
    end

    y = y + LABEL_H + 4
    local listH = areaH - LABEL_H - 4
    local cardW = w - scrollW - 8

    st.log.scroll = math.Clamp(st.log.scroll, 0, math.max(0, #log - 1))
    st.overList = UI.hovering(x, y, w, listH)

    if #log == 0 then
        UI.outlineCut(x, y, cardW, 58, 10, pal.accentDim, 1)
        draw.SimpleText("NOCH KEINE FUNKSPRÜCHE", "CryptoRadio_CL_Label", x + cardW * 0.5, y + 29, pal.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    local cy, shown = y, 0
    for i = st.log.scroll + 1, #log do
        local h = drawLogEntry(log[i], x, cy, cardW, y + listH - cy)
        if not h then break end
        cy = cy + h + ROW_GAP
        shown = shown + 1
    end

    UI.drawScrollbar(x + w - scrollW, y, listH, #log, math.max(1, shown), st.log)
end

------------------
-- Reiter: BEFEHLE
------------------

local function drawHelpTab(ply, x, y, w, areaH)
    local pal = UI.pal

    for i, h in ipairs(CryptoRadio.Help or {}) do
        local ry = y + (i - 1) * (HELP_H + HELP_GAP)
        UI.fillCut(x, ry, w, HELP_H, 6, pal.panel)
        UI.outlineCut(x, ry, w, HELP_H, 6, pal.line, 1)
        UI.rect(x, ry + 6, 3, HELP_H - 6, pal.accent)

        draw.SimpleText(h[1], "CryptoRadio_CL_Cmd", x + 12, ry + 10, pal.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(h[2], "CryptoRadio_CL_Tag", x + 12, ry + 23, pal.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local hy = y + #(CryptoRadio.Help or {}) * (HELP_H + HELP_GAP) + 4
    local hint = "Empfänger: Teil des Namens reicht. Mehrere mit Komma (Rex,Cody), alle erreichbaren mit *. Namen mit Leerzeichen in \"Anführungszeichen\"."
    for i, line in ipairs(safeWrap(hint, "CryptoRadio_CL_Hint", w)) do
        draw.SimpleText(line, "CryptoRadio_CL_Hint", x, hy + (i - 1) * 13 + 6, pal.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

------------------
-- App
------------------

local function drawApp(ply)
    drawHeader(ply)

    local x = PAD_X
    local w = MENU_W - PAD_X * 2
    local y = HEADER_H

    drawTabs(x, y, w)
    y = y + TAB_H + 8

    st.overList = false
    local areaH = contentHeight()

    if st.tab == "log" then
        drawLogTab(ply, x, y, w, areaH)
    elseif st.tab == "help" then
        drawHelpTab(ply, x, y, w, areaH)
    else
        drawSendTab(ply, x, y, w)
    end

    -- Klick daneben beendet die Eingabe (Tastatur gehört wieder dem Spiel)
    local down = input.IsMouseDown(MOUSE_LEFT)
    if down and not st.mouseWasDown and IsValid(st.entryPanel) and RealTime() - (st.entryTime or 0) > 0.1 then
        st.blurPending = true
    end
    st.mouseWasDown = down
end

local appDef = {
    width = MENU_W,
    height = menuHeight,
    draw = drawApp,
    closeOnGRN = false, -- Antennenausfall betrifft nur die Langstrecke
    onOpen = function()
        st.rcp.scroll = 0
        st.log.scroll = 0
        st.expanded = nil
    end,
    onWheel = function(delta)
        local step = delta > 0 and -1 or 1
        if st.tab == "log" then
            st.log.scroll = math.max(0, st.log.scroll + step)
        elseif st.tab == "send" then
            st.rcp.scroll = math.max(0, st.rcp.scroll + step)
        end
    end
}

local function comlinkAvailable()
    return cfg.ComlinkEnabled ~= false and hradio and hradio.ComlinkApps and hradio.ComlinkApps[APP] == appDef
        and hradio.OpenComlink and hradio.ToggleComlink
end

local function register()
    if not (hradio and hradio.RegisterComlinkApp and hradio.ComlinkUI and hradio.ComlinkApps) then return end
    if hradio.ComlinkApps[APP] == appDef then return end

    UI = hradio.ComlinkUI
    createFonts()
    hradio.RegisterComlinkApp(APP, appDef)
end

-- Das Comlink-Addon lädt erst bei InitPostEntity (und cl_hRadio_Reload baut alles neu): regelmäßig nachsehen
if cfg.ComlinkEnabled ~= false then
    register()
    timer.Create("CryptoRadio_ComlinkRegister", 1, 0, register)
end

function CryptoRadio.IsComlinkOpen()
    return comlinkAvailable() and hradio.IsComlinkOpen(APP) or false
end

local function comlinkMissing()
    notify("Der Textfunk braucht das Comlink-Addon (Strivon Comlink).", true)
end

-- tab: 1 = Senden, 2 = Funklog, 3 = Befehle. Nur Ego-Perspektive (das Comlink meldet sich sonst selbst)
function CryptoRadio.OpenComlink(tab)
    if not comlinkAvailable() then
        comlinkMissing()
        return false
    end

    if tab then
        st.tab = TAB_BY_INDEX[tab] or "send"
        removeEntry()
    end

    if not hradio.IsComlinkOpen(APP) then
        hradio.OpenComlink(APP)
    end

    return hradio.IsComlinkOpen(APP)
end

concommand.Add("crypto_radio_comlink", function()
    if comlinkAvailable() then
        hradio.ToggleComlink(APP)
    else
        comlinkMissing()
    end
end)

------------------
-- Taste J + Eingabefeld aufräumen
------------------

local keyWasDown = false

hook.Add("Think", "CryptoRadio_Comlink", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Eingabefeld nur, solange der Textfunk offen ist und es den Fokus hat
    if IsValid(st.entryPanel) then
        local open = comlinkAvailable() and hradio.IsComlinkOpen(APP) and st.tab == "send"
        local lost = not entryFocused() and RealTime() - (st.entryTime or 0) > 0.25

        if not open or lost or st.blurPending then
            removeEntry()
        end
    end
    st.blurPending = nil

    if cfg.ComlinkEnabled == false then return end

    local key = cfg.ComlinkKey or KEY_J
    local down = key > 0 and input.IsKeyDown(key)
    local pressed = down and not keyWasDown
    keyWasDown = down

    if not pressed then return end
    if ply:IsTyping() or gui.IsGameUIVisible() or gui.IsConsoleVisible() or IsValid(vgui.GetKeyboardFocus()) then return end

    -- In der Third Person öffnet das Comlink nicht (Hinweis kommt vom Comlink selbst)
    if comlinkAvailable() then
        hradio.ToggleComlink(APP)
    else
        comlinkMissing()
    end
end)
