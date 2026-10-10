hradio = hradio or {}

-- Squad-Menü auf dem Comlink (Taste G, nur Ego-Perspektive)
-- Gleicher Arm, gleiches Hologramm und gleicher Stil wie der Funk (H). Es ist immer nur eins von beiden offen.
-- Inhalt:
--   * alle Mitglieder des (Einheits-)Squads, bis zu 100, mit Rolle, Rang, Leben, Entfernung und Richtungspfeil
--   * Schnellleiste: Markieren, Feind markieren, Namensschilder an/aus
--   * Reiter: BEFEHLE (Squadführer), MELDUNGEN, SQUADS (verlassen, beitreten, erstellen, einladen), OPTIONEN
-- Die alte Squad-Liste im HUD und das Radialmenü auf G gibt es nicht mehr.

if not KrakenSquad or not KrakenSquad.GetPositions or not KrakenSquad.RequestComm then
    print("[hRadio] Squad-System (krakensquad) nicht geladen – Squad-Menü auf G ist aus.")
    return
end

local UI = hradio.ComlinkUI
if not UI or not hradio.RegisterComlinkApp then return end

local pal = UI.pal
local fillCut, outlineCut, rect = UI.fillCut, UI.outlineCut, UI.rect
local fitText, drawAurebesh, button = UI.fitText, UI.drawAurebesh, UI.button
local hovering, clicked, withAlpha = UI.hovering, UI.clicked, UI.withAlpha
local drawScrollbar, playUISound, config = UI.drawScrollbar, UI.playUISound, UI.config

local MENU_W = 380
local HEADER_H = 58
local ROW_H = 50
local ROW_GAP = 4
local QUICK_H = 34
local TAB_H = 32
local GRID_COLS = 2
local GRID_ROWS = 4
local GRID_H = 34
local GRID_GAP = 5
local SCROLL_W = UI.SCROLL_W or 8
local LIST_X = 14
local UNITS_TO_M = 0.01905

-- Zustand überlebt cl_hRadio_Reload
HRADIO_SQUAD = HRADIO_SQUAD or {}
local sq = HRADIO_SQUAD
sq.scroll = sq.scroll or 0
sq.grid = sq.grid or 0
sq.tab = sq.tab or "comms"
sq.squadList = sq.squadList or {}

local function visibleRows()
    return math.max(1, math.floor(tonumber(config().SquadVisibleMembers) or 5))
end

local function memberCount()
    local lp = LocalPlayer()
    local squad = IsValid(lp) and lp:GetKSSquad()
    return squad and #squad:GetMembers() or 0
end

-- Liste wird nur so hoch wie nötig (1 bis SquadVisibleMembers Zeilen)
local function shownRows()
    return math.Clamp(memberCount(), 1, visibleRows())
end

local function listHeight()
    local v = shownRows()
    return v * ROW_H + (v - 1) * ROW_GAP
end

local function bottomHeight()
    return 8 + QUICK_H + 8 + TAB_H + 8 + GRID_ROWS * GRID_H + (GRID_ROWS - 1) * GRID_GAP + 4
end

local function menuHeight()
    return HEADER_H + listHeight() + bottomHeight()
end

local function createFonts()
    local head = UI.fontFace("head", "BigNoodleTitling")
    local body = UI.fontFace("body", "Roboto Condensed")

    surface.CreateFont("hRadio_SQ_Name", { font = head, size = 22, weight = 400, antialias = true, extended = true })
    surface.CreateFont("hRadio_SQ_Info", { font = body, size = 13, weight = 700, antialias = true, extended = true })
    surface.CreateFont("hRadio_SQ_Dist", { font = head, size = 19, weight = 400, antialias = true, extended = true })
    -- Knöpfe/Reiter: Roboto Condensed, damit Leerzeichen gut lesbar sind (BigNoodle hat sehr schmale Leerzeichen)
    surface.CreateFont("hRadio_SQ_Grid", { font = body, size = 16, weight = 700, antialias = true, extended = true })
    surface.CreateFont("hRadio_SQ_Tab", { font = head, size = 22, weight = 400, antialias = true, extended = true })
    surface.CreateFont("hRadio_SQ_Quick", { font = head, size = 21, weight = 400, antialias = true, extended = true })
end

createFonts()

------------------
-- Daten
------------------

local function readable(col)
    if SYMUI and SYMUI.Readable then
        local ok, out = pcall(SYMUI.Readable, col, 120)
        if ok and out then return out end
    end
    return col
end

local function playerName(ply)
    if KF and KF.Integrations and KF.Integrations.GetPlayerName then
        local ok, name = pcall(KF.Integrations.GetPlayerName, ply)
        if ok and isstring(name) and name ~= "" then return name end
    end
    return ply:Nick()
end

-- SymChars: Einheitsfarbe und Rang des aktiven Charakters
local function charInfo(ply)
    if not ply.GetCharacter then return end

    local ok, char = pcall(ply.GetCharacter, ply)
    if not ok or not char then return end

    local unitCol, rank
    local faction = char.GetFaction and char:GetFaction()
    if faction and faction.GetColor then unitCol = faction:GetColor() end

    if char.GetRankData then
        local data = char:GetRankData()
        if istable(data) then rank = (isstring(data.name) and data.name ~= "") and data.name or data.short end
    end
    if not rank and char.GetRankName then rank = char:GetRankName() end

    return unitCol, isstring(rank) and rank ~= "" and rank or nil
end

local iconCache = {}

local function getIcon(path)
    if not isstring(path) or path == "" then return nil end
    if iconCache[path] ~= nil then return iconCache[path] or nil end

    local mat
    if KF and KF.Materials and KF.Materials.Get then
        mat = KF.Materials.Get(path)
    else
        mat = Material(path, "smooth mips")
    end

    iconCache[path] = (mat and not mat:IsError()) and mat or false
    return iconCache[path] or nil
end

local cache = { time = 0, list = {} }

local function buildMembers(lp)
    if RealTime() < cache.time and cache.squad == lp:GetKSSquadID() then return cache.list end

    local squad = lp:GetKSSquad()
    local positions = KrakenSquad.GetPositions()
    local list = {}

    for _, ply in ipairs(squad and squad:GetMembers() or {}) do
        if not IsValid(ply) then continue end

        local posIdx = ply:GetKSPosition()
        local pd = positions[posIdx] or positions[#positions] or {}
        local unitCol, rank = charInfo(ply)

        list[#list + 1] = {
            ply = ply,
            isMe = ply == lp,
            posIdx = posIdx,
            pd = pd,
            roleCol = KrakenSquad.GetPositionColor(pd),
            unitCol = readable(unitCol or pal.text),
            rank = rank,
            name = playerName(ply),
            icon = getIcon(pd.icon)
        }
    end

    table.sort(list, function(a, b)
        if a.isMe ~= b.isMe then return a.isMe end
        if a.posIdx ~= b.posIdx then return a.posIdx < b.posIdx end
        return a.name < b.name
    end)

    cache.list = list
    cache.squad = lp:GetKSSquadID()
    cache.time = RealTime() + 0.5

    return list
end

local function flush() cache.time = 0 end
hook.Add("KrakenSquad.MembersUpdated", "hRadio_SquadMenu", flush)
hook.Add("KrakenSquad.LeftSquad", "hRadio_SquadMenu", flush)
hook.Add("KrakenSquad.ConfigUpdated", "hRadio_SquadMenu", function() flush() iconCache = {} end)

local function localizedName(item)
    return KrakenSquad.ItemName and KrakenSquad.ItemName(item) or item.id
end

local function itemColor(item)
    local c = item.color
    if istable(c) then return Color(c[1] or c["1"] or 255, c[2] or c["2"] or 255, c[3] or c["3"] or 255) end
    return pal.accent
end

local function findPingComm(kind)
    for _, c in ipairs(KrakenSquad.GetCommunications() or {}) do
        if c.triggerPing == kind then return c end
    end
end

------------------
-- Aktionen
------------------

local function closeAndRun(fn)
    hradio.CloseComlink(true)
    timer.Simple(0, fn)
end

local function cycleRole(m)
    local positions = KrakenSquad.GetPositions()
    if #positions < 2 then return end

    -- Rolle 1 (Squadführer) wird wie im alten Radialmenü nicht vergeben
    local nextPos = m.posIdx + 1
    if nextPos > #positions or nextPos < 2 then nextPos = 2 end

    KrakenSquad.RequestPosChange(m.ply, nextPos)
    playUISound("buttons/combine_button_locked.wav")
    flush()
end

local function toggleNametags()
    KrakenSquad.ToggleNametags()
    playUISound("buttons/combine_button1.wav")
end

local function togglePref(key)
    KrakenSquad.SetClientPref(key, KrakenSquad.GetClientPref(key, true) == false)
    playUISound("buttons/combine_button1.wav")
end

local function inviteTarget()
    local ent = LocalPlayer():GetEyeTrace().Entity

    if IsValid(ent) and ent:IsPlayer() then
        KrakenSquad.RequestInvite(ent)
        playUISound("buttons/combine_button_locked.wav")
    else
        notification.AddLegacy("Schau den Spieler an, den du einladen willst.", NOTIFY_HINT, 3)
        playUISound("buttons/button10.wav")
    end
end

------------------
-- Zeichnen
------------------

local arrowPts = { { x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = 0 } }

-- Pfeil zeigt, wo das Mitglied relativ zur Blickrichtung steht (oben = vor dir)
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

local function drawHeader(lp, squad, count)
    draw.SimpleText("SQUAD", "hRadio_CL_Title", 16, 20, Color(0, 0, 0, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("SQUAD", "hRadio_CL_Title", 15, 19, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    drawAurebesh("SQUAD", 16, 42, 16, Color(pal.accent.r, pal.accent.g, pal.accent.b, 200))

    if not squad then return end

    local right = MENU_W - 16
    local title = fitText(string.upper(squad:GetTitle()), "hRadio_CL_Label", 220)
    local unitCol = pal.accent

    if squad.IsUnitSquad and squad:IsUnitSquad() then
        local f = symchars and symchars.factions and symchars.factions.Get(squad:GetUnitID())
        if f and f.GetColor then unitCol = readable(f:GetColor()) end
    end

    draw.SimpleText(title, "hRadio_CL_Label", right, 18, unitCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    draw.SimpleText(count .. " / " .. squad:GetMaxMembers() .. " MITGLIEDER", "hRadio_CL_Tag", right, 38, pal.soft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

local function drawMember(lp, m, x, y, w, isLeader, canKick)
    local h = ROW_H
    local ply = m.ply
    local dead = not ply:Alive()

    fillCut(x, y, w, h, 8, dead and pal.redBg or pal.panel)
    if m.isMe then fillCut(x, y, w, h, 8, pal.accentFaint) end
    outlineCut(x, y, w, h, 8, m.isMe and pal.accentSoft or (dead and pal.redLine or pal.line), 1)

    -- Rollenfarbe als Streifen links
    rect(x, y + 8, 3, h - 8, m.roleCol)

    -- Rollen-Symbol
    local bx, by = x + 10, y + 6
    fillCut(bx, by, 22, 22, 5, pal.panel3)

    if m.icon then
        surface.SetMaterial(m.icon)
        surface.SetDrawColor(m.roleCol.r, m.roleCol.g, m.roleCol.b, dead and 90 or 255)
        surface.DrawTexturedRect(bx + 3, by + 3, 16, 16)
        draw.NoTexture()
    else
        local letter = string.upper(string.sub(m.pd.name or "?", 1, 1))
        draw.SimpleText(letter, "hRadio_CL_Index", bx + 11, by + 12, m.roleCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- rechts: Entfernung + Richtung (bzw. DU / GEFALLEN)
    local rightX = x + w - 10
    local rightW = 66

    if canKick and not m.isMe then
        local kx = rightX - 16
        if button(kx, y + 6, 16, 16, "X", "alert", true, "hRadio_CL_Tag") then
            KrakenSquad.RequestKick(ply)
            playUISound("buttons/combine_button2.wav")
            flush()
        end
        rightX = kx - 6
        rightW = rightW + 22
    end

    if m.isMe then
        draw.SimpleText("DU", "hRadio_SQ_Dist", rightX, y + 17, pal.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    elseif dead then
        draw.SimpleText("GEFALLEN", "hRadio_CL_Tag", rightX, y + 17, pal.redText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    else
        local diff = ply:GetPos() - lp:GetPos()
        local meters = math.floor(diff:Length() * UNITS_TO_M + 0.5)
        local rel = math.NormalizeAngle(diff:Angle().y - lp:EyeAngles().y)

        draw.SimpleText(meters .. " M", "hRadio_SQ_Dist", rightX - 20, y + 17, pal.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        drawArrow(rightX - 7, y + 16, 7, rel, pal.accent)

        -- Höhenunterschied (Stockwerk drüber/drunter)
        local up = diff.z * UNITS_TO_M
        if math.abs(up) >= 3 then
            local text = (up > 0 and "+" or "") .. math.floor(up + 0.5) .. " M HÖHE"
            draw.SimpleText(text, "hRadio_CL_Hint", rightX, y + 33, pal.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    -- Name in Einheitsfarbe
    local nameX = bx + 30
    local name = fitText(string.upper(m.name), "hRadio_SQ_Name", w - (nameX - x) - rightW - 6)
    draw.SimpleText(name, "hRadio_SQ_Name", nameX, y + 17, dead and pal.muted or m.unitCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Rolle (Squadführer: anklicken = nächste Rolle) und Rang
    local role = string.upper(m.pd.name or "")
    surface.SetFont("hRadio_SQ_Info")
    local roleW = surface.GetTextSize(role)
    local ry = y + 33
    local roleCol = m.roleCol

    if isLeader and not m.isMe and m.posIdx ~= 1 then
        local hov = hovering(nameX - 3, ry - 8, roleW + 18, 16)
        if hov then
            fillCut(nameX - 3, ry - 8, roleW + 18, 16, 4, pal.accentDim)
            roleCol = pal.text
        end
        draw.SimpleText("›", "hRadio_SQ_Info", nameX + roleW + 4, ry, hov and pal.accent or pal.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if clicked(nameX - 3, ry - 8, roleW + 18, 16) then
            cycleRole(m)
        end
    end

    draw.SimpleText(role, "hRadio_SQ_Info", nameX, ry, roleCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    if m.rank then
        local rx = nameX + roleW + (isLeader and 18 or 8)
        local rank = fitText(string.upper(m.rank), "hRadio_SQ_Info", math.max(10, x + w - rightW - rx - 10))
        draw.SimpleText(rank, "hRadio_SQ_Info", rx, ry, pal.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Lebensbalken unten
    local hp = math.max(ply:Health(), 0)
    local frac = math.Clamp(hp / math.max(ply:GetMaxHealth(), 1), 0, 1)
    local barX, barW = x + 10, w - 20
    local barCol = frac < 0.3 and pal.red or (frac < 0.7 and Color(240, 200, 80) or pal.green)

    rect(barX, y + h - 5, barW, 2, Color(0, 0, 0, 150))
    if frac > 0 and not dead then rect(barX, y + h - 5, math.max(1, barW * frac), 2, barCol) end
end

-- Knopf im Raster: dunkle Platte, Farbstreifen links
local function gridButton(x, y, w, h, item)
    local enabled = item.enabled ~= false
    local hov = enabled and hovering(x, y, w, h)
    local press = hov and input.IsMouseDown(MOUSE_LEFT)
    local oy = press and 1 or 0
    local active = item.active

    withAlpha(enabled and 1 or 0.35, function()
        fillCut(x, y + oy, w, h, 6, active and pal.amberBg or (hov and pal.panel3 or pal.panel2))
        outlineCut(x, y + oy, w, h, 6, (hov or active) and pal.accent or pal.line2, 1.2)
        rect(x + 1, y + oy + 6, 3, h - 7, item.color or pal.accent)

        local tx = x + 12
        local maxW = w - 20

        if item.right then
            draw.SimpleText(item.right, "hRadio_CL_Hint", x + w - 9, y + h * 0.5 + oy, pal.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            surface.SetFont("hRadio_CL_Hint")
            maxW = maxW - surface.GetTextSize(item.right) - 6
        end

        local text = fitText(string.upper(item.label), "hRadio_SQ_Grid", maxW)
        draw.SimpleText(text, "hRadio_SQ_Grid", tx, y + h * 0.5 + oy, (hov or active) and pal.text or pal.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)

    return enabled and clicked(x, y, w, h)
end

-- Raster mit 2 Spalten, blättert per Mausrad (Maus über dem Raster), wenn mehr als 8 Einträge
local function drawGrid(items, x, y, w)
    local cellW = (w - (GRID_COLS - 1) * GRID_GAP) / GRID_COLS
    local perPage = GRID_COLS * GRID_ROWS
    local maxScroll = math.max(0, math.ceil((#items - perPage) / GRID_COLS))

    sq.grid = math.Clamp(sq.grid, 0, maxScroll)

    if #items == 0 then
        draw.SimpleText("NICHTS VERFÜGBAR", "hRadio_SQ_Tab", x + w * 0.5, y + 40, pal.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    local start = sq.grid * GRID_COLS
    for i = 1, perPage do
        local item = items[start + i]
        if not item then break end

        local col = (i - 1) % GRID_COLS
        local row = math.floor((i - 1) / GRID_COLS)
        local bx = x + col * (cellW + GRID_GAP)
        local by = y + row * (GRID_H + GRID_GAP)

        -- volle Breite für Einträge mit wide = true (nur in der linken Spalte sinnvoll)
        if gridButton(bx, by, cellW, GRID_H, item) then
            item.func()
        end
    end

    if maxScroll > 0 then
        local hint = "SEITE " .. (sq.grid + 1) .. "/" .. (maxScroll + 1) .. " · MAUSRAD"
        draw.SimpleText(hint, "hRadio_CL_Hint", x + w, y + GRID_ROWS * (GRID_H + GRID_GAP) + 2, pal.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end
end

local TABS = {
    { id = "commands", label = "BEFEHLE" },
    { id = "comms", label = "MELDUNGEN" },
    { id = "squads", label = "SQUADS" },
    { id = "options", label = "OPTIONEN" }
}

local function commandItems(isLeader)
    local items = {}
    for _, c in ipairs(KrakenSquad.GetCommands() or {}) do
        items[#items + 1] = {
            label = localizedName(c),
            color = itemColor(c),
            enabled = isLeader,
            func = function()
                KrakenSquad.RequestCommand(c.id)
                playUISound("buttons/combine_button_locked.wav")
            end
        }
    end
    return items
end

local function commItems(squad)
    local items = {}
    for _, c in ipairs(KrakenSquad.GetCommunications() or {}) do
        if c.triggerPing then continue end -- Markieren steht oben in der Schnellleiste

        items[#items + 1] = {
            label = localizedName(c),
            color = itemColor(c),
            enabled = squad ~= nil,
            func = function()
                KrakenSquad.RequestComm(c.id)
                playUISound("buttons/combine_button_locked.wav")
            end
        }
    end
    return items
end

-- Haupteinheit des eigenen Charakters (SymChars) und deren Squad
local function ownUnit(lp)
    if KrakenSquad.GetConfig("unitSquads") == false or not lp.GetCharacter then return end

    local char = lp:GetCharacter()
    local faction = char and char.GetFaction and char:GetFaction()
    if not faction then return end

    local root = faction.GetRoot and faction:GetRoot() or faction
    return root
end

local function findUnitSquad(unitID)
    for _, s in pairs(KrakenSquad.Cache) do
        if s.GetUnitID and s:GetUnitID() == unitID then return s end
    end
end

local function requestSquadList(force)
    if not force and RealTime() < (sq.nextList or 0) then return end
    sq.nextList = RealTime() + 3
    net.Start("KS.RequestSquads") net.SendToServer()
end

hook.Add("KrakenSquad.SquadListReceived", "hRadio_SquadMenu", function(data)
    sq.squadList = istable(data) and data or {}
end)

local function squadsItems(lp, squad, isLeader)
    local items = {}
    local unit = ownUnit(lp)
    local unitSquad = unit and findUnitSquad(unit:GetID())

    if squad then
        items[#items + 1] = {
            label = "Squad verlassen", color = pal.red,
            func = function()
                KrakenSquad.RequestLeave()
                playUISound("buttons/combine_button2.wav")
                flush()
                timer.Simple(0.5, function() requestSquadList(true) end)
            end
        }
    end

    if unit and squad ~= unitSquad then
        items[#items + 1] = {
            label = "Einheits-Squad beitreten",
            color = readable(unit:GetColor()),
            func = function()
                net.Start("KS.RequestJoinUnit") net.SendToServer()
                playUISound("buttons/combine_button_locked.wav")
                flush()
            end
        }
    end

    items[#items + 1] = {
        label = "Neuen Squad erstellen", color = pal.green,
        func = function() closeAndRun(KrakenSquad.OpenCreator) end
    }

    -- öffentliche Squads zum Beitreten
    local list = {}
    for _, d in ipairs(sq.squadList) do
        if d.public and (not squad or d.id ~= squad:GetID()) then list[#list + 1] = d end
    end
    table.sort(list, function(a, b) return tostring(a.name) < tostring(b.name) end)

    for _, d in ipairs(list) do
        local s = KrakenSquad.GetSquad(d.id)
        local max = s and s:GetMaxMembers() or KrakenSquad.GetConfig("maxMembers")
        local full = (d.members or 0) >= max

        items[#items + 1] = {
            label = tostring(d.name),
            right = (d.members or 0) .. "/" .. max,
            enabled = not full,
            func = function()
                KrakenSquad.RequestJoinPublic(d.id)
                playUISound("buttons/combine_button_locked.wav")
                flush()
            end
        }
    end

    if not squad or not (squad.IsUnitSquad and squad:IsUnitSquad()) then
        items[#items + 1] = {
            label = "Spieler einladen", enabled = squad ~= nil and isLeader, func = inviteTarget
        }
    end

    return items
end

local function optionItems()
    local function pref(key, label)
        local on = KrakenSquad.GetClientPref(key, true) ~= false
        return {
            label = label .. (on and ": an" or ": aus"),
            active = on,
            func = function() togglePref(key) end
        }
    end

    local tagsOn = KrakenSquad.NametagsOn ~= false

    return {
        { label = "Namensschilder" .. (tagsOn and ": an" or ": aus"), active = tagsOn, func = toggleNametags },
        pref("show_pings", "Markierungen"),
        pref("show_comm_markers", "Meldungen über Köpfen"),
        pref("show_orders", "Aufträge im HUD"),
        pref("show_squad_events", "Squad-Nachrichten im Chat"),
        { label = "Alle Einstellungen", func = function() closeAndRun(KrakenSquad.OpenContextMenu) end }
    }
end

local function drawNoSquadCard(x, y, w)
    fillCut(x, y, w, ROW_H, 8, pal.panel)
    outlineCut(x, y, w, ROW_H, 8, pal.accentDim, 1)
    draw.SimpleText("KEIN SQUAD", "hRadio_SQ_Name", x + 14, y + 17, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("Unter SQUADS beitreten oder einen neuen Squad erstellen.", "hRadio_SQ_Info", x + 14, y + 35, pal.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

local function drawSquadMenu(ply)
    local squad = ply:GetKSSquad()
    local members = squad and buildMembers(ply) or {}
    local isLeader = squad ~= nil and ply:KSIsLeader()
    local unit = squad and squad.IsUnitSquad and squad:IsUnitSquad()
    local canKick = isLeader and not unit

    drawHeader(ply, squad, #members)

    -- Mitgliederliste
    local rows = shownRows()
    local listY = HEADER_H
    local listH = listHeight()
    local cardW = MENU_W - LIST_X - SCROLL_W - 18

    sq.scroll = math.Clamp(sq.scroll, 0, math.max(0, #members - rows))

    if not squad then
        drawNoSquadCard(LIST_X, listY, cardW)
        if sq.tab == "commands" or sq.tab == "comms" then sq.tab = "squads" end
    else
        for i = 1, rows do
            local m = members[sq.scroll + i]
            if not m then break end

            if IsValid(m.ply) then
                drawMember(ply, m, LIST_X, listY + (i - 1) * (ROW_H + ROW_GAP), cardW, isLeader, canKick)
            end
        end
    end

    drawScrollbar(MENU_W - SCROLL_W - 12, listY, listH, #members, rows, sq)

    -- Schnellleiste: Markieren | Feind | Namensschilder
    local x = LIST_X
    local w = MENU_W - LIST_X * 2
    local y = listY + listH + 8
    local gap = 5
    local pingN, pingE = findPingComm("normal"), findPingComm("enemy")
    local nameW = 132
    local pingW = (w - nameW - gap * 2) * 0.5

    if button(x, y, pingW, QUICK_H, "MARKIEREN", "primary", squad ~= nil and pingN ~= nil, "hRadio_SQ_Quick") then
        KrakenSquad.RequestComm(pingN.id)
        playUISound("buttons/combine_button_locked.wav")
    end

    if button(x + pingW + gap, y, pingW, QUICK_H, "FEIND", "alert", squad ~= nil and pingE ~= nil, "hRadio_SQ_Quick") then
        KrakenSquad.RequestComm(pingE.id)
        playUISound("buttons/combine_button_locked.wav")
    end

    local tagsOn = KrakenSquad.NametagsOn ~= false
    if button(x + pingW * 2 + gap * 2, y, nameW, QUICK_H, tagsOn and "NAMEN: AN" or "NAMEN: AUS", tagsOn and "on" or nil, true, "hRadio_SQ_Quick") then
        toggleNametags()
    end

    -- Reiter
    y = y + QUICK_H + 8
    local tabW = (w - gap * (#TABS - 1)) / #TABS

    for i, tab in ipairs(TABS) do
        local tx = x + (i - 1) * (tabW + gap)
        local enabled = squad ~= nil or (tab.id ~= "commands" and tab.id ~= "comms")

        if button(tx, y, tabW, TAB_H, tab.label, sq.tab == tab.id and "on" or nil, enabled, "hRadio_SQ_Tab") and sq.tab ~= tab.id then
            sq.tab = tab.id
            sq.grid = 0
            if tab.id == "squads" then requestSquadList(true) end
            playUISound("buttons/lightswitch2.wav")
        end
    end

    -- Inhalt des Reiters
    y = y + TAB_H + 8
    local gridH = GRID_ROWS * GRID_H + (GRID_ROWS - 1) * GRID_GAP
    sq.overGrid = hovering(x, y, w, gridH)

    if sq.tab == "commands" then
        drawGrid(commandItems(isLeader), x, y, w)

        if not isLeader then
            local bw, bh = 220, 30
            fillCut(x + (w - bw) * 0.5, y + (gridH - bh) * 0.5, bw, bh, 6, pal.bg)
            outlineCut(x + (w - bw) * 0.5, y + (gridH - bh) * 0.5, bw, bh, 6, pal.accentDim, 1)
            draw.SimpleText("NUR FÜR SQUADFÜHRER", "hRadio_SQ_Tab", x + w * 0.5, y + gridH * 0.5 + 1, pal.soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    elseif sq.tab == "comms" then
        drawGrid(commItems(squad), x, y, w)
    elseif sq.tab == "squads" then
        requestSquadList(false)
        drawGrid(squadsItems(ply, squad, isLeader), x, y, w)
    else
        drawGrid(optionItems(), x, y, w)
    end
end

hradio.RegisterComlinkApp("squad", {
    width = MENU_W,
    height = menuHeight,
    draw = drawSquadMenu,
    closeOnGRN = false, -- Funkstörung betrifft nur den Funk
    onOpen = function()
        flush()
        sq.scroll = 0
        requestSquadList(true)
    end,
    onWheel = function(delta)
        local step = delta > 0 and -1 or 1
        if sq.overGrid then
            sq.grid = math.max(0, sq.grid + step)
        else
            sq.scroll = sq.scroll + step
        end
    end
})

-- Für andere Addons / Binds
function hradio.OpenSquadMenu() hradio.OpenComlink("squad") end
function hradio.ToggleSquadMenu() hradio.ToggleComlink("squad") end
KrakenSquad.OpenComlink = hradio.OpenSquadMenu
