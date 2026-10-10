hradio = hradio or {}

-- Medic-Menü auf dem Comlink (Taste K, nur Ego-Perspektive)
-- Gleicher linker Arm, gleiches Hologramm, gleiche Größe und gleicher Aufbau wie Funk (H), Squad (G)
-- und Textfunk (J). Es ist immer nur eine App offen, eine andere App-Taste wechselt direkt.
-- Öffnen/Schließen: K, Chat-Befehl des Medical-Systems (Standard !medical) oder Konsole (kms_menu / hradio_medic).
-- Aufbau (wie beim Squad: Kopf, Liste, Schnellleiste, Reiter, Raster):
--   * Kopf: MEDIC + Aurebesh, rechts Patient in Einheitsfarbe mit Entfernung und Richtungspfeil
--   * Zustand des Patienten (Triage, Herzstillstand/Bewusstlos, Blutung, Blutverlust, Schmerzen, Stabil, HLW)
--   * Körper zum Anklicken + Befund des gewählten Körperteils
--   * Schnellleiste: Patient <-> Ich selbst, Handbuch, Volles Menü (+ Admin)
--   * Reiter: TRIAGE, UNTERSUCHEN, BEHANDLUNG, MEDIKAMENTE, ERWEITERT, TRAGEN, INVENTAR, PROTOKOLL
--   * Raster mit Behandlungen (×Vorrat), darunter Infofeld (Beschreibung, Sperrgrund, Fortschritt)
--   * rechts daneben SCHNELL: Pfeiltasten-Folge in zufälliger Reihenfolge, richtig = Behandlung sofort fertig
-- In der Third Person geht das Menü nicht auf (wie Funk/Squad/Textfunk).

local KMS = KrakensMedical

if not KMS or not KMS.Treatments or not KMS.FindPatient or not KMS.SendTreat then
    MsgC(Color(255, 90, 90), "[hRadio] Medical-System (krakens_medical) nicht geladen – Medic-Menü auf K ist aus.\n")
    return
end

local UI = hradio.ComlinkUI
if not UI or not hradio.RegisterComlinkApp then return end

if (hradio.Config or {}).MedicEnabled == false then
    print("[hRadio] Medic-Menü ist in der Config ausgeschaltet (MedicEnabled = false).")
    return
end

local pal = UI.pal
local fillCut, outlineCut, rect = UI.fillCut, UI.outlineCut, UI.rect
local fitText, drawAurebesh, button = UI.fitText, UI.drawAurebesh, UI.button
local hovering, clicked, withAlpha = UI.hovering, UI.clicked, UI.withAlpha
local drawScrollbar, playUISound, config = UI.drawScrollbar, UI.playUISound, UI.config

local L = KMS.L

-- gleiche Maße wie Squad (380 breit, Raster 2 × 4, Knöpfe 34 hoch)
local MENU_W = 380
local HEADER_H = 58
local PAD = 14
local INNER_W = MENU_W - PAD * 2
local CHIP_H = 20
local DETAIL_H = 116 -- Befund (volle Breite)
-- Körperbild links neben dem Menü (ragt nur nach links raus, das Menü bleibt mittig über dem Comlink)
local BODY_GAP = 10
local BODY_W = 168
local BODY_H = 340
local BODY_X = PAD - BODY_GAP - BODY_W
-- Figur im Körperbild (quadratische Textur): waagrechte Mitte und Höhe, damit sie das Feld ausfüllt
local BODY_FIG_CX = 0.5065
local BODY_FIG_H = 0.98
local QUICK_H = 34
local TAB_H = 26
local TAB_GAP = 5
local TAB_ROWS = 2
local CAT_H = 22
local GRID_COLS = 2
local GRID_ROWS = 4
local GRID_H = 34
local GRID_GAP = 5
local HINT_H = 14
local INFO_H = 44
local GAP = 8
local SCROLL_W = UI.SCROLL_W or 8
local LINE_H = 17
local UNITS_TO_M = 0.01905

-- Zustand überlebt cl_hRadio_Reload
HRADIO_MEDIC = HRADIO_MEDIC or {}
local md = HRADIO_MEDIC
md.part = md.part or "torso"
md.cat = md.cat or "examine"
md.grid = md.grid or 0
md.detail = md.detail or 0
md.usePatient = md.usePatient or false

local function isOpen()
    return hradio.IsComlinkOpen and hradio.IsComlinkOpen("medic") or false
end

local function gridHeight()
    return GRID_ROWS * GRID_H + (GRID_ROWS - 1) * GRID_GAP
end

local function tabsHeight()
    return TAB_ROWS * TAB_H + (TAB_ROWS - 1) * TAB_GAP
end

local function menuHeight()
    return HEADER_H + CHIP_H + 6 + DETAIL_H + GAP + QUICK_H + GAP + tabsHeight() + GAP
        + CAT_H + 4 + gridHeight() + HINT_H + INFO_H + 4
end

local function createFonts()
    local head = UI.fontFace("head", "BigNoodleTitling")
    local body = UI.fontFace("body", "Roboto Condensed")

    -- gleiche Größen wie im Squad-Menü (hRadio_SQ_*) und Textfunk
    surface.CreateFont("hRadio_MD_Line", { font = body, size = 15, weight = 600, antialias = true, extended = true })
    surface.CreateFont("hRadio_MD_LineB", { font = body, size = 15, weight = 800, antialias = true, extended = true })
    surface.CreateFont("hRadio_MD_Info", { font = body, size = 13, weight = 700, antialias = true, extended = true })
    surface.CreateFont("hRadio_MD_Grid", { font = body, size = 16, weight = 700, antialias = true, extended = true })
    surface.CreateFont("hRadio_MD_Count", { font = head, size = 19, weight = 400, antialias = true, extended = true })
    surface.CreateFont("hRadio_MD_Part", { font = head, size = 22, weight = 400, antialias = true, extended = true })
    surface.CreateFont("hRadio_MD_Tab", { font = head, size = 20, weight = 400, antialias = true, extended = true })
    surface.CreateFont("hRadio_MD_Quick", { font = head, size = 21, weight = 400, antialias = true, extended = true })
end

createFonts()

------------------
-- Hilfen
------------------

local function snapshot()
    return md.patient and KMS.PatientSnapshots[md.patient] or nil
end

local function partState(partId)
    local snap = snapshot()
    return snap and snap.parts and snap.parts[partId] or nil
end

local function patientName(patient)
    if patient == LocalPlayer() then return L("ui_self") end
    return KMS.PatientName(patient)
end

local function upper(text)
    local out = string.upper(tostring(text or ""))
        :gsub("ä", "Ä"):gsub("ö", "Ö"):gsub("ü", "Ü")
    return out
end

local function wrapText(text, font, maxW)
    surface.SetFont(font)
    local lines, line = {}, ""

    for word in string.gmatch(tostring(text or ""), "%S+") do
        local test = line == "" and word or (line .. " " .. word)
        if surface.GetTextSize(test) > maxW and line ~= "" then
            lines[#lines + 1] = line
            line = word
        else
            line = test
        end
    end

    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

local function readable(col)
    if SYMUI and SYMUI.Readable then
        local ok, out = pcall(SYMUI.Readable, col, 120)
        if ok and out then return out end
    end
    return col
end

-- SymChars: Einheitsfarbe und Rang des aktiven Charakters (wie im Squad-Menü)
local function charInfo(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply.GetCharacter then return end

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

    return unitCol and readable(unitCol) or nil, isstring(rank) and rank ~= "" and rank or nil
end

local ROUTE_COLORS = {
    inject = Color(90, 170, 255),
    infusion = Color(120, 200, 255),
    oral = Color(94, 200, 121),
    topical = Color(190, 140, 255)
}

local CAT_COLORS = {
    examine = Color(168, 174, 180),
    bandage = Color(225, 88, 88),
    meds = Color(90, 170, 255),
    advanced = Color(255, 190, 50),
    drag = Color(154, 162, 173)
}

local function closeAndRun(fn)
    hradio.CloseComlink(true)
    timer.Simple(0, fn)
end

------------------
-- Patient wechseln / beobachten
------------------

local function setPatient(target)
    local old = md.patient
    if old == target then return end

    md.patient = target
    md.part = "torso"
    md.usePatient = false
    md.grid = 0
    md.detail = 0

    if IsValid(old) then
        local interactPatient = KMS.InteractPatient and KMS.InteractPatient() or nil
        if old ~= interactPatient then KMS.SendWatch(old, false) end
    end

    if IsValid(target) then KMS.SendWatch(target, true) end
end

local function togglePatient()
    local ply = LocalPlayer()
    local target = md.patient == ply and KMS.FindPatient() or ply

    if target == md.patient then
        playUISound("buttons/button10.wav")
        notification.AddLegacy("Kein anderer Patient in Reichweite. Schau ihn an.", NOTIFY_HINT, 3)
        return
    end

    setPatient(target)
    playUISound("buttons/combine_button1.wav")
end

local function cancelMenuTreatment()
    local t = KMS.Treating
    if t and t.source == "menu" and CurTime() < t.endsAt then
        net.Start("KMS_CancelTreat")
        net.SendToServer()
    end
end

-- Damit Watch-Keepalive, Bewegungssperre und HUD wie beim alten Menü funktionieren:
-- KMS.UI.MenuPatient() muss auch den Patienten im Comlink liefern.
function KMS.ComlinkMenuPatient()
    if isOpen() and IsValid(md.patient) then return md.patient end
    return nil
end

-- Angepasstes Medical-Addon fragt KMS.ComlinkMenuPatient selbst ab, sonst hier einhängen
KMS.UI = KMS.UI or {}
if not KMS.ComlinkAware then
    local classicMenuPatient = KMS.UI.ClassicMenuPatient or KMS.UI.MenuPatient
    KMS.UI.ClassicMenuPatient = classicMenuPatient

    KMS.UI.MenuPatient = function()
        return KMS.ComlinkMenuPatient() or (classicMenuPatient and classicMenuPatient() or nil)
    end
end

------------------
-- Daten für die Anzeige
------------------

local function statusChips(snap)
    local chips = {}
    local states = snap and snap.states
    if not states then return chips end

    local colors = KMS.StatusColors or {}
    local hideVitals = KMS.Settings.diagnosisMode == "examine"

    if states.triage and states.triage > 0 then
        local triage = KMS.TriageById[states.triage]
        if triage then chips[#chips + 1] = { text = L(triage.key), col = triage.color, solid = true } end
    end

    if states.arrest and not hideVitals then
        chips[#chips + 1] = { text = L("st_arrest"), col = colors.critical or pal.red }
    elseif states.conscious == false then
        chips[#chips + 1] = { text = L("st_unconscious"), col = colors.open or pal.accent }
    end

    if KMS.SnapshotBleeding and KMS.SnapshotBleeding(snap) then
        chips[#chips + 1] = { text = L("int_bleeding"), col = colors.critical or pal.red }
    end

    if states.bloodClass and states.bloodClass > 1 then
        local line = KMS.BloodClassLine(states.bloodClass)
        chips[#chips + 1] = { text = line.text, col = line.color }
    end

    if states.painBand and states.painBand > 0 then
        chips[#chips + 1] = { text = states.painBand >= 3 and L("ov_severe_pain") or L("ov_in_pain"), col = colors.warning or pal.accent }
    end

    if states.stable and not hideVitals then
        chips[#chips + 1] = { text = L("st_stable"), col = pal.green }
    end

    if states.cpr then
        chips[#chips + 1] = { text = "HLW: " .. tostring(states.cpr), col = colors.treated or pal.text }
    end

    return chips
end

local function detailLines(snap)
    local lines = {}
    local partLines = KMS.PartLines(partState(md.part), md.part)

    if #partLines == 0 then
        lines[#lines + 1] = { text = L("ov_no_injuries"), color = pal.muted }
    else
        for _, line in ipairs(partLines) do lines[#lines + 1] = line end
    end

    local states = snap and snap.states
    if states then
        local extra = KMS.IVLines(states)
        for medId, count in pairs(snap.meds or {}) do
            extra[#extra + 1] = { text = L("ov_meds", count, L("item_" .. medId)), color = pal.soft }
        end

        if #extra > 0 then
            lines[#lines + 1] = { text = "", color = pal.muted }
            for _, line in ipairs(extra) do lines[#lines + 1] = line end
        end
    end

    return lines
end

local function canUseSharing()
    return KMS.Settings.itemSharing and not KMS.Settings.infiniteSupplies
        and md.patient ~= LocalPlayer() and IsValid(md.patient) and md.patient:IsPlayer()
end

local function describe(itemId)
    local out = {}
    for _, entry in ipairs(KMS.DescribeItem and KMS.DescribeItem(itemId) or {}) do
        local col = entry.good == true and pal.green or (entry.good == false and pal.redText or pal.soft)
        out[#out + 1] = { text = entry.text, color = col }
    end
    return out
end

-- Einträge des Rasters: { label, count, color, enabled, active, passive, info = {{text,color}}, func }
local function treatmentItems(snap)
    local items = {}
    local usePatient = canUseSharing() and md.usePatient == true
    local inv = usePatient and snap and snap.inv or nil

    for _, def in ipairs(KMS.Treatments) do
        if def.cat == md.cat and KMS.CanShowTreatment(def) and not KMS.LacksItem(def, snap, usePatient) then
            local reason = KMS.TreatmentBlockReason(def, snap, md.patient, md.part, usePatient)
            local count

            if def.item and not KMS.Settings.infiniteSupplies then
                count = (inv or KMS.Self.inv or {})[def.item] or 0
            end

            local info
            if reason then
                info = { { text = reason, color = pal.redText } }
            elseif def.item then
                info = describe(def.item)
            end

            items[#items + 1] = {
                label = L("treat_" .. def.id),
                count = count,
                color = ROUTE_COLORS[def.routeGroup or ""] or CAT_COLORS[def.cat] or pal.accent,
                enabled = reason == nil,
                info = info,
                icon = def.item and KMS.ItemIcons and KMS.ItemIcons[def.item] or nil,
                func = function()
                    KMS.SendTreat(md.patient, def.id, md.part, usePatient, "menu")
                    playUISound("buttons/combine_button_locked.wav")
                end
            }
        end
    end

    return items
end

local function triageItems(snap)
    local items = {}
    local current = snap and snap.states and snap.states.triage or 0

    for _, level in ipairs(KMS.TriageLevels) do
        if level.id ~= 4 then
            items[#items + 1] = {
                label = L(level.key),
                color = level.color,
                active = level.id == current,
                enabled = snap ~= nil,
                func = function()
                    KMS.SendTriage(md.patient, level.id)
                    playUISound("buttons/combine_button_locked.wav")
                end
            }
        end
    end

    return items
end

local function dragItems(snap)
    local ply = LocalPlayer()
    local patient = md.patient
    local items = {}
    local isPlayerPatient = patient ~= ply and patient:IsPlayer()
    local hauling = ply:GetNWString("kms_hauling", "") ~= ""
    local unconscious = snap and snap.states and snap.states.conscious == false
    local canHaul = isPlayerPatient and unconscious and not hauling

    local function haul(carry)
        return function()
            KMS.LastTreatSource = "menu"
            net.Start("KMS_Drag")
            net.WriteEntity(patient)
            net.WriteBool(carry)
            net.SendToServer()
            playUISound("buttons/combine_button_locked.wav")
        end
    end

    local haulInfo = (not canHaul) and { { text = not isPlayerPatient and L("err_invalid") or (hauling and L("err_busy") or L("err_target_conscious")), color = pal.redText } } or nil

    items[#items + 1] = { label = L("int_drag"), enabled = canHaul == true, info = haulInfo, func = haul(false) }
    items[#items + 1] = { label = L("int_carry"), enabled = canHaul == true, info = haulInfo, func = haul(true) }

    local root = KMS.FindVehicleRoot and KMS.FindVehicleRoot() or NULL
    local loadedIn = isPlayerPatient and patient:GetNWEntity("kms_loaded_in") or NULL
    local canLoad = isPlayerPatient and unconscious and IsValid(root) and not IsValid(loadedIn)

    items[#items + 1] = {
        label = L("int_load_vehicle"),
        enabled = canLoad == true,
        info = (not canLoad) and { { text = not (isPlayerPatient and unconscious) and L("err_target_conscious")
            or not IsValid(root) and L("err_no_vehicle")
            or IsValid(loadedIn) and L("err_already_loaded")
            or L("err_invalid"), color = pal.redText } } or nil,
        func = function()
            net.Start("KMS_VehicleLoad")
            net.WriteEntity(patient)
            net.WriteEntity(root)
            net.SendToServer()
            playUISound("buttons/combine_button_locked.wav")
        end
    }

    items[#items + 1] = {
        label = L("int_unload_vehicle"),
        enabled = IsValid(loadedIn),
        func = function()
            net.Start("KMS_VehicleLoad")
            net.WriteEntity(patient)
            net.WriteEntity(NULL)
            net.SendToServer()
            playUISound("buttons/combine_button_locked.wav")
        end
    }

    local canInv = IsValid(root) and KMS.IsMedVehicle(root) and KMS.VehInvAccess(ply)
        and KMS.Settings.itemSharing and not KMS.Settings.infiniteSupplies

    items[#items + 1] = {
        label = L("int_veh_inventory"),
        enabled = canInv == true,
        info = (not canInv) and { { text = not IsValid(root) and L("err_no_vehicle")
            or not KMS.IsMedVehicle(root) and L("err_not_medvehicle")
            or (not KMS.Settings.itemSharing or KMS.Settings.infiniteSupplies) and L("err_sharing_off")
            or L("err_npc_denied"), color = pal.redText } } or nil,
        func = function()
            closeAndRun(function() KMS.OpenVehicleInventory(root) end)
        end
    }

    return items
end

local function inventoryItems()
    local items = {}
    local inv = KMS.Self.inv or {}

    for _, item in ipairs(KMS.Items) do
        local count = inv[item.id] or 0
        if count > 0 and not (KMS.ItemDisabled and KMS.ItemDisabled[item.id]) then
            items[#items + 1] = {
                label = KMS.ItemLabel(item.id),
                count = count,
                color = CAT_COLORS[KMS.ItemCategory(item.id)] or pal.accent,
                enabled = true,
                passive = true,
                icon = KMS.ItemIcons and KMS.ItemIcons[item.id] or nil,
                info = describe(item.id)
            }
        end
    end

    return items
end

-- Anzahl eigener Sanitätsmittel (für den Kopf)
local function supplyCount()
    local total = 0
    for _, count in pairs(KMS.Self.inv or {}) do
        if isnumber(count) and count > 0 then total = total + count end
    end
    return total
end

------------------
-- Reiter
------------------

-- Kurze Beschriftungen, damit vier Reiter nebeneinander passen (Rest per Sprachdatei)
local TAB_LABELS = {
    triage = "TRIAGE",
    examine = "UNTERSUCHEN",
    bandage = "BEHANDLUNG",
    meds = "MEDIKAMENTE",
    advanced = "ERWEITERT",
    drag = "TRAGEN",
    inventory = "INVENTAR",
    log = "PROTOKOLL"
}

local function tabs()
    local ids = { "triage", "examine", "bandage", "meds", "advanced", "drag" }
    if not KMS.Settings.infiniteSupplies then ids[#ids + 1] = "inventory" end
    ids[#ids + 1] = "log"

    local list = {}
    for _, id in ipairs(ids) do
        local full = id == "log" and L("menu_activity") or L("cat_" .. id)
        list[#list + 1] = { id = id, label = TAB_LABELS[id] or upper(full), full = full }
    end

    return list
end

------------------
-- Zeichnen
------------------

local hoverInfo

local arrowPts = { { x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = 0 } }

-- Pfeil zeigt, wo der Patient relativ zur Blickrichtung liegt (oben = vor dir), wie im Squad-Menü
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

-- Kopf wie Squad/Textfunk: Titel + Aurebesh links, rechts Patient (Einheitsfarbe) und darunter Entfernung
local function drawHeader(ply)
    draw.SimpleText("MEDIC", "hRadio_CL_Title", 16, 20, Color(0, 0, 0, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("MEDIC", "hRadio_CL_Title", 15, 19, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    drawAurebesh("MEDIC", 16, 42, 16, Color(pal.accent.r, pal.accent.g, pal.accent.b, 200))

    local right = MENU_W - 16
    local patient = md.patient
    local isSelf = patient == ply
    local unitCol, rank = charInfo(patient)

    local name = fitText(upper(patientName(patient)), "hRadio_CL_Label", 230)
    draw.SimpleText(name, "hRadio_CL_Label", right, 18, isSelf and pal.accent or (unitCol or pal.text), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    local sub
    if isSelf then
        sub = KMS.Settings.infiniteSupplies and "SELBSTBEHANDLUNG · VORRAT UNBEGRENZT"
            or ("SELBSTBEHANDLUNG · " .. supplyCount() .. " MITTEL")
        draw.SimpleText(sub, "hRadio_CL_Tag", right, 38, pal.soft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        return
    end

    local ent = KMS.PatientDisplayEnt(patient)
    local diff = ent:GetPos() - ply:GetPos()
    local meters = math.floor(diff:Length() * UNITS_TO_M + 0.5)
    local rel = math.NormalizeAngle(diff:Angle().y - ply:EyeAngles().y)

    sub = (rank and (upper(rank) .. " · ") or "PATIENT · ") .. meters .. " M"
    draw.SimpleText(sub, "hRadio_CL_Tag", right - 16, 38, pal.soft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    drawArrow(right - 5, 38, 5, rel, pal.accent)
end

local function drawChips(snap, x, y, w)
    local chips = statusChips(snap)

    if not snap then
        draw.SimpleText("WARTE AUF PATIENTENDATEN ...", "hRadio_CL_Tag", x, y + CHIP_H * 0.5, pal.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        return
    end

    if #chips == 0 then
        draw.SimpleText("KEINE AUFFÄLLIGKEITEN", "hRadio_CL_Tag", x, y + CHIP_H * 0.5, pal.green, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        return
    end

    local cx = x
    surface.SetFont("hRadio_CL_Tag")

    for _, chip in ipairs(chips) do
        local text = upper(chip.text)
        local tw = surface.GetTextSize(text)
        local cw = tw + 14

        if cx + cw > x + w then
            local left = x + w - cx
            if left < 40 then break end
            text = fitText(text, "hRadio_CL_Tag", left - 14)
            cw = left
        end

        local col = chip.col or pal.text
        if chip.solid then
            fillCut(cx, y, cw, CHIP_H, 4, Color(col.r, col.g, col.b, 230))
            local ink = (col.r * 0.299 + col.g * 0.587 + col.b * 0.114) > 140 and pal.ink or pal.text
            draw.SimpleText(text, "hRadio_CL_Tag", cx + cw * 0.5, y + CHIP_H * 0.5, ink, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            fillCut(cx, y, cw, CHIP_H, 4, Color(col.r, col.g, col.b, 34))
            outlineCut(cx, y, cw, CHIP_H, 4, Color(col.r, col.g, col.b, 170), 1)
            draw.SimpleText(text, "hRadio_CL_Tag", cx + cw * 0.5, y + CHIP_H * 0.5, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        cx = cx + cw + 4
        if cx >= x + w then break end
    end
end

local function drawBody(x, y, w, h)
    -- Kopf wie bei den anderen Feldern (KÖRPER + Aurebesh)
    draw.SimpleText("KÖRPER", "hRadio_CL_Title", x + 1, 20, Color(0, 0, 0, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("KÖRPER", "hRadio_CL_Title", x, 19, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    drawAurebesh("KOERPER", x + 1, 42, 16, Color(pal.accent.r, pal.accent.g, pal.accent.b, 200))

    fillCut(x, y, w, h, 8, pal.panel)
    outlineCut(x, y, w, h, 8, pal.line, 1)
    rect(x, y + 8, 3, h - 8, pal.accentSoft)

    -- Name des gewählten Körperteils unten
    local labelH = 22
    draw.SimpleText(upper(KMS.PartLabel(md.part)), "hRadio_CL_Label", x + w * 0.5, y + h - labelH * 0.5 - 2, pal.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Die Figur füllt nur die Mitte der quadratischen Textur: so groß zeichnen, dass sie das ganze Feld
    -- hoch ist (der durchsichtige Rand links/rechts darf über das Feld hinausragen)
    local size = (h - labelH - 14) / BODY_FIG_H
    local bx = x + w * 0.5 - size * BODY_FIG_CX
    local by = y + 8

    -- Körperteil unter der Maus (kleinste Fläche gewinnt, wie im alten Menü)
    local hover, hoverArea
    for _, region in ipairs(KMS.BodyRegions or {}) do
        local r = region.rect
        local rx, ry, rw, rh = bx + r[1] * size, by + r[2] * size, r[3] * size, r[4] * size
        if hovering(rx, ry, rw, rh) then
            local area = r[3] * r[4]
            if not hoverArea or area < hoverArea then
                hover, hoverArea = region, area
            end
        end
    end

    if KMS.DrawBodyImage then
        KMS.DrawBodyImage(bx, by, size, partState, md.part, hover and hover.id or nil)
        draw.NoTexture()
    end

    if hover then
        local r = hover.rect
        if clicked(bx + r[1] * size, by + r[2] * size, r[3] * size, r[4] * size) and md.part ~= hover.id then
            md.part = hover.id
            md.detail = 0
            playUISound("buttons/lightswitch2.wav")
        end
    end

    -- Name nur beim Drüberfahren (der gewählte Körperteil steht schon im Befund daneben)
    if hover then
        hoverInfo = { { text = upper(KMS.PartLabel(hover.id)) .. " – anklicken für Befund und Behandlung", color = pal.text } }
    end
end

-- Befund wie eine Karte im Funk/Squad: Platte, Farbstreifen links, Name + Aurebesh, darunter Zeilen
local function drawDetails(snap, x, y, w, h)
    local stateCol = KMS.PartStateColor and KMS.PartStateColor(partState(md.part)) or pal.text

    fillCut(x, y, w, h, 8, pal.panel)
    outlineCut(x, y, w, h, 8, pal.line, 1)
    rect(x, y + 8, 3, h - 8, stateCol)

    draw.SimpleText(upper(KMS.PartLabel(md.part)), "hRadio_MD_Part", x + 12, y + 15, stateCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    drawAurebesh(KMS.PartLabel(md.part), x + 13, y + 31, 12, Color(stateCol.r, stateCol.g, stateCol.b, 150), w - 24)

    -- Befund (umgebrochen, scrollbar)
    local textW = w - 24 - SCROLL_W
    local wrapped = {}
    for _, line in ipairs(detailLines(snap)) do
        if line.text == "" then
            wrapped[#wrapped + 1] = { text = "", color = pal.muted }
        else
            for i, part in ipairs(wrapText(line.text, line.bold and "hRadio_MD_LineB" or "hRadio_MD_Line", textW - 8)) do
                wrapped[#wrapped + 1] = { text = (i == 1 and "· " or "  ") .. part, color = line.color or pal.soft, bold = line.bold }
            end
        end
    end

    local listY = y + 42
    local listH = h - 46
    local visible = math.max(1, math.floor(listH / LINE_H))

    md.detail = math.Clamp(md.detail, 0, math.max(0, #wrapped - visible))
    md.overDetail = hovering(x, y, w, h)

    for i = 1, visible do
        local line = wrapped[md.detail + i]
        if not line then break end
        draw.SimpleText(line.text, line.bold and "hRadio_MD_LineB" or "hRadio_MD_Line", x + 12, listY + (i - 1) * LINE_H + LINE_H * 0.5, line.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if #wrapped > visible then
        local holder = { scroll = md.detail }
        drawScrollbar(x + w - SCROLL_W - 6, listY, listH, #wrapped, visible, holder)
        md.detail = holder.scroll
    end
end

-- Schnellleiste wie beim Squad (MARKIEREN | FEIND | NAMEN): Patient wechseln | Handbuch | Volles Menü (| Admin)
local function drawQuickBar(ply, x, y, w)
    local list = {
        { label = md.patient == ply and "PATIENT" or "ICH SELBST", style = "primary", func = togglePatient,
          info = "Zwischen dir selbst und dem Patienten, den du anschaust, wechseln." },
        { label = "HANDBUCH", func = function() closeAndRun(KMS.OpenGuide) end, info = L("guide_title") },
        { label = "VOLLES MENÜ", func = function()
            local target = md.patient
            closeAndRun(function()
                if KMS.OpenClassicMenuOn then KMS.OpenClassicMenuOn(target) else KMS.OpenMenuOn(target) end
            end)
        end, info = "Altes Medizinmenü (Einstellungen, Lager, Handbuch) öffnen." }
    }

    if KMS.IsAdmin and KMS.IsAdmin(ply) then
        list[#list + 1] = { label = "ADMIN", style = "alert", func = function()
            closeAndRun(function()
                net.Start("KMS_RequestSync")
                net.WriteBool(true)
                net.SendToServer()
            end)
        end, info = L("adm_title") }
    end

    local gap = 5
    local bw = (w - gap * (#list - 1)) / #list

    for i, b in ipairs(list) do
        local bx = x + (i - 1) * (bw + gap)
        if hovering(bx, y, bw, QUICK_H) and b.info then hoverInfo = { { text = b.info, color = pal.soft } } end
        if button(bx, y, bw, QUICK_H, b.label, b.style, true, "hRadio_MD_Quick") then
            b.func()
        end
    end
end

-- Reiter wie beim Squad (Text, aktiver Reiter amber), hier in zwei Reihen
local function drawTabs(x, y, w)
    local list = tabs()
    local perRow = math.ceil(#list / TAB_ROWS)

    for i, tab in ipairs(list) do
        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow
        local inRow = math.min(perRow, #list - row * perRow)
        local tw = (w - TAB_GAP * (inRow - 1)) / inRow
        local tx = x + col * (tw + TAB_GAP)
        local ty = y + row * (TAB_H + TAB_GAP)

        if hovering(tx, ty, tw, TAB_H) and tab.full then hoverInfo = { { text = upper(tab.full), color = pal.text } } end

        local label = fitText(tab.label, "hRadio_MD_Tab", tw - 8)
        if button(tx, ty, tw, TAB_H, label, md.cat == tab.id and "on" or nil, true, "hRadio_MD_Tab") and md.cat ~= tab.id then
            md.cat = tab.id
            md.grid = 0
            playUISound("buttons/lightswitch2.wav")
        end
    end
end

-- Knopf im Raster wie beim Squad: dunkle Platte, Farbstreifen links, rechts Anzahl (×Vorrat)
local function gridButton(x, y, w, h, item)
    local enabled = item.enabled ~= false
    local hov = hovering(x, y, w, h)
    local live = enabled and not item.passive
    local press = live and hov and input.IsMouseDown(MOUSE_LEFT)
    local oy = press and 1 or 0
    local lit = (hov and live) or item.active

    if hov and item.info and item.info[1] then hoverInfo = item.info end

    withAlpha(enabled and 1 or 0.35, function()
        fillCut(x, y + oy, w, h, 6, item.active and pal.amberBg or (lit and pal.panel3 or pal.panel2))
        outlineCut(x, y + oy, w, h, 6, lit and pal.accent or pal.line2, 1.2)
        rect(x + 1, y + oy + 6, 3, h - 7, item.color or pal.accent)

        local tx = x + 12
        local maxW = w - 20

        if item.icon and not item.icon:IsError() then
            local isz = h - 12
            KMS.DrawIcon(item.icon, tx - 2, y + 6 + oy, isz, isz, Color(255, 255, 255, lit and 255 or 210))
            draw.NoTexture()
            tx = tx + isz + 3
            maxW = maxW - isz - 3
        end

        if item.count then
            local text = "×" .. item.count
            surface.SetFont("hRadio_MD_Count")
            maxW = maxW - surface.GetTextSize(text) - 6
            draw.SimpleText(text, "hRadio_MD_Count", x + w - 9, y + h * 0.5 + 1 + oy, item.count > 0 and pal.accent or pal.redText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        local text = fitText(upper(item.label), "hRadio_MD_Grid", maxW)
        draw.SimpleText(text, "hRadio_MD_Grid", tx, y + h * 0.5 + oy, lit and pal.text or pal.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end)

    return live and item.func and clicked(x, y, w, h)
end

-- Raster mit 2 Spalten, blättert seitenweise (8 Einträge) per Mausrad oder Pfeilen, wenn mehr als 8 Einträge
local function drawGrid(items, x, y, w, emptyText)
    local gh = gridHeight()
    local cellW = (w - (GRID_COLS - 1) * GRID_GAP) / GRID_COLS
    local perPage = GRID_COLS * GRID_ROWS
    local maxPage = math.max(0, math.ceil(#items / perPage) - 1)

    md.grid = math.Clamp(md.grid, 0, maxPage)
    md.overGrid = hovering(x, y, w, gh + HINT_H)

    if #items == 0 then
        draw.SimpleText(upper(emptyText or L("menu_no_supplies")), "hRadio_MD_Tab", x + w * 0.5, y + 40, pal.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    local start = md.grid * perPage
    for i = 1, perPage do
        local item = items[start + i]
        if not item then break end

        local col = (i - 1) % GRID_COLS
        local row = math.floor((i - 1) / GRID_COLS)

        if gridButton(x + col * (cellW + GRID_GAP), y + row * (GRID_H + GRID_GAP), cellW, GRID_H, item) then
            item.func()
        end
    end

    if maxPage > 0 then
        -- Seitenanzeige mit Pfeilen: ◄ SEITE 1/3 ►
        local hy = y + gh + 2
        local hint = "SEITE " .. (md.grid + 1) .. "/" .. (maxPage + 1) .. " · MAUSRAD"
        local canPrev, canNext = md.grid > 0, md.grid < maxPage
        local nextX, prevX = x + w - 12, x + w - 12

        surface.SetFont("hRadio_CL_Hint")
        local hintW = surface.GetTextSize(hint)
        prevX = nextX - hintW - 22

        local prevHov = canPrev and hovering(prevX - 4, hy - 2, 16, HINT_H)
        local nextHov = canNext and hovering(nextX - 4, hy - 2, 16, HINT_H)

        draw.SimpleText("◄", "hRadio_CL_Tag", prevX + 4, hy + 5, prevHov and pal.accent or (canPrev and pal.soft or pal.line2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(hint, "hRadio_CL_Hint", nextX - 10, hy, pal.soft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText("►", "hRadio_CL_Tag", nextX + 4, hy + 5, nextHov and pal.accent or (canNext and pal.soft or pal.line2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if canPrev and clicked(prevX - 4, hy - 2, 16, HINT_H) then
            md.grid = md.grid - 1
            playUISound("buttons/lightswitch2.wav")
        elseif canNext and clicked(nextX - 4, hy - 2, 16, HINT_H) then
            md.grid = md.grid + 1
            playUISound("buttons/lightswitch2.wav")
        end
    end
end

local function drawLog(snap, x, y, w)
    local gh = gridHeight()
    fillCut(x, y, w, gh, 8, pal.panel)
    outlineCut(x, y, w, gh, 8, pal.line, 1)
    rect(x, y + 8, 3, gh - 8, pal.accent)

    local lines = {}
    local function section(title, entries)
        lines[#lines + 1] = { text = title, color = pal.accent, bold = true }
        if not entries or #entries == 0 then
            lines[#lines + 1] = { text = "  –", color = pal.muted }
            return
        end
        -- neueste Einträge stehen vorne
        for _, entry in ipairs(entries) do
            lines[#lines + 1] = { text = KMS.FormatEntry(entry), color = pal.soft }
        end
    end

    section(upper(L("menu_activity")), snap and snap.log)
    lines[#lines + 1] = { text = "", color = pal.muted }
    section(upper(L("menu_quickview")), snap and snap.quick)

    local wrapped = {}
    for _, line in ipairs(lines) do
        if line.text == "" then
            wrapped[#wrapped + 1] = line
        else
            for _, part in ipairs(wrapText(line.text, line.bold and "hRadio_MD_LineB" or "hRadio_MD_Line", w - SCROLL_W - 28)) do
                wrapped[#wrapped + 1] = { text = part, color = line.color, bold = line.bold }
            end
        end
    end

    local visible = math.floor((gh - 12) / LINE_H)
    md.grid = math.Clamp(md.grid, 0, math.max(0, #wrapped - visible))
    md.overGrid = hovering(x, y, w, gh)

    for i = 1, visible do
        local line = wrapped[md.grid + i]
        if not line then break end
        draw.SimpleText(line.text, line.bold and "hRadio_MD_LineB" or "hRadio_MD_Line", x + 12, y + 6 + (i - 1) * LINE_H + LINE_H * 0.5, line.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local holder = { scroll = md.grid }
    drawScrollbar(x + w - SCROLL_W - 6, y + 4, gh - 8, #wrapped, visible, holder)
    md.grid = holder.scroll
end

local function drawCategory(snap, x, y, w)
    -- Kopfzeile des Reiters: Name links, Vorrat-Umschalter bzw. Körperteil rechts
    local label = md.cat == "log" and L("menu_activity") or L("cat_" .. md.cat)
    draw.SimpleText(upper(label), "hRadio_CL_Label", x + 2, y + CAT_H * 0.5, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local isTreatCat = md.cat == "examine" or md.cat == "bandage" or md.cat == "meds" or md.cat == "advanced"

    if isTreatCat and canUseSharing() then
        local text = md.usePatient and "VORRAT: PATIENT" or "VORRAT: EIGENER"
        if button(x + w - 140, y + 1, 140, CAT_H - 2, text, md.usePatient and "on" or nil, true, "hRadio_CL_Btn") then
            md.usePatient = not md.usePatient
            md.grid = 0
            playUISound("buttons/lightswitch2.wav")
        end
    elseif isTreatCat or md.cat == "triage" then
        draw.SimpleText(upper(KMS.PartLabel(md.part)), "hRadio_CL_Tag", x + w - 2, y + CAT_H * 0.5, pal.soft, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    local gy = y + CAT_H + 4

    if md.cat == "log" then
        drawLog(snap, x, gy, w)
        return
    end

    if not snap and md.cat ~= "inventory" then
        drawGrid({}, x, gy, w, "Warte auf Patientendaten ...")
        return
    end

    if md.cat == "triage" then
        drawGrid(triageItems(snap), x, gy, w)
    elseif md.cat == "drag" then
        drawGrid(dragItems(snap), x, gy, w)
    elseif md.cat == "inventory" then
        drawGrid(inventoryItems(), x, gy, w, "Dein Inventar ist leer.")
    else
        drawGrid(treatmentItems(snap), x, gy, w)
    end
end

local function drawInfo(x, y, w)
    fillCut(x, y, w, INFO_H, 8, pal.panel)
    outlineCut(x, y, w, INFO_H, 8, pal.line, 1)

    -- Laufende Behandlung hat Vorrang: Fortschrittsbalken (die Pfeil-Eingabe steht im Feld SCHNELL rechts)
    local t = KMS.Treating
    if t and CurTime() < t.endsAt then
        local bx, bw = x + 6, w - 12
        local by, bh = y + 5, INFO_H - 10
        local frac = math.Clamp(1 - (t.endsAt - CurTime()) / math.max(t.duration, 0.01), 0, 1)

        fillCut(bx, by, bw, bh, 5, pal.panel2)
        if frac > 0 then fillCut(bx, by, math.max(10, bw * frac), bh, 5, pal.accentSoft) end
        outlineCut(bx, by, bw, bh, 5, pal.accent, 1.2)

        local label = string.find(t.id, "haul_", 1, true) == 1 and L("int_" .. string.sub(t.id, 6)) or L("treat_" .. t.id)
        local font = "hRadio_MD_Quick"
        label = fitText(upper(label), font, bw - 80)
        draw.SimpleText(label, font, bx + 10, by + bh * 0.5 + 1, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%.1f S", math.max(0, t.endsAt - CurTime())), font, bx + bw - 10, by + bh * 0.5 + 1, pal.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        return
    end

    rect(x, y + 8, 3, INFO_H - 8, pal.accentSoft)

    local lines = {}
    if hoverInfo then
        for _, entry in ipairs(hoverInfo) do
            for _, part in ipairs(wrapText(entry.text, "hRadio_MD_Info", w - 24)) do
                lines[#lines + 1] = { text = part, color = entry.color or pal.soft }
                if #lines >= 2 then break end
            end
            if #lines >= 2 then break end
        end
    else
        lines[1] = { text = "Körperteil anklicken, dann Behandlung wählen.", color = pal.muted }
        lines[2] = { text = "Mausrad scrollt · K oder ESC schließt", color = pal.muted }
    end

    for i, line in ipairs(lines) do
        draw.SimpleText(line.text, "hRadio_MD_Info", x + 12, y + 6 + (i - 1) * 16 + 8, line.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

------------------
-- Schnellbehandlung (Feld rechts neben dem Medic-Menü)
------------------

-- Läuft eine Behandlung aus dem Comlink (Behandlung, Medikamente, Erweitert), schickt der Server eine
-- Folge aus den 4 Pfeiltasten in zufälliger Reihenfolge. Richtig eingegeben = Behandlung sofort fertig,
-- falsche Taste = Folge von vorn. Eingabe: Pfeiltasten (oder WASD), die Eingabe selbst macht cl_hud.lua.

local QT_GAP = 10
local QT_W = 96 -- schmal: die Pfeile stehen untereinander, damit das Feld rechts kompakt bleibt
local QT_X = MENU_W - PAD + QT_GAP
local QT_CAP = 40
local QT_CAP_GAP = 6
local QT_COL_H = 4 * QT_CAP + 3 * QT_CAP_GAP -- Höhe der Pfeil-Spalte (längere Folgen werden kleiner)
local QT_H = 30 + QT_COL_H + 78
local QT_DIR_REL = { 0, 180, 90, -90 } -- 1 = hoch, 2 = runter, 3 = links, 4 = rechts (für drawArrow)
local QT_DIR_NAME = { "HOCH", "RUNTER", "LINKS", "RECHTS" }

-- Immer an (nur über die Server-Config abschaltbar)
local function quickEnabled()
    return config().MedicQuickTreat ~= false
end

-- Fragt cl_hud.lua (KMS.SendTreat) beim Start einer Behandlung ab
function KMS.ComlinkQuickTreatOn()
    return isOpen() and quickEnabled()
end

-- Merkt sich die laufende Folge, um „geschafft“ zu erkennen (die Folge wird beim letzten Pfeil sofort beendet)
local function trackQuick()
    local s = KMS.StratagemState and KMS.StratagemState()

    if s then
        md.qtRef = s
        md.qtLen = #s.sequence
        md.qtRemain = KMS.Treating and math.max(0, KMS.Treating.endsAt - CurTime()) or 0
        return s
    end

    if md.qtRef then
        if md.qtRef.index > (md.qtLen or 0) then
            md.qtDone = { at = RealTime(), saved = md.qtRemain or 0 }
        end
        md.qtRef = nil
    end
end

local function drawKeyCap(x, y, s, dir, mode)
    -- mode: "done", "current", "wrong", "next", "idle"
    local bg, border, arrowCol = pal.panel2, pal.line2, pal.muted

    if mode == "done" then
        bg, border, arrowCol = Color(pal.green.r, pal.green.g, pal.green.b, 40), pal.green, pal.green
    elseif mode == "current" then
        local pulse = 0.6 + 0.4 * math.abs(math.sin(RealTime() * 5))
        bg, border, arrowCol = pal.amberBg, Color(pal.accent.r, pal.accent.g, pal.accent.b, 255 * pulse), pal.accent
    elseif mode == "wrong" then
        bg, border, arrowCol = pal.redBg, pal.red, pal.redText
    elseif mode == "next" then
        arrowCol = pal.soft
    end

    fillCut(x, y, s, s, math.max(3, s * 0.14), bg)
    outlineCut(x, y, s, s, math.max(3, s * 0.14), border, mode == "current" and 1.6 or 1.1)

    if dir then
        drawArrow(x + s * 0.5, y + s * 0.52, s * 0.26, QT_DIR_REL[dir] or 0, arrowCol)
    else
        draw.SimpleText("?", "hRadio_MD_Count", x + s * 0.5, y + s * 0.5 + 1, arrowCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- Feld SCHNELL rechts neben dem Menü: Pfeile hochkant untereinander, darunter Status und Restzeit
local function drawQuickPanel(ply)
    local x, y, w, h = QT_X, HEADER_H, QT_W, QT_H
    local cx = x + w * 0.5 + 1

    -- Kopf wie bei den anderen Apps
    draw.SimpleText("SCHNELL", "hRadio_CL_Title", x + 1, 20, Color(0, 0, 0, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("SCHNELL", "hRadio_CL_Title", x, 19, pal.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    drawAurebesh("SCHNELL", x + 1, 42, 16, Color(pal.accent.r, pal.accent.g, pal.accent.b, 200), w)

    fillCut(x, y, w, h, 8, pal.panel)
    outlineCut(x, y, w, h, 8, pal.line, 1)

    local s = trackQuick()
    local t = KMS.Treating
    local running = t and CurTime() < t.endsAt
    local done = md.qtDone and RealTime() - md.qtDone.at < 1.6 and md.qtDone or nil
    local wrong = s and CurTime() < (s.flashAt or 0)

    local stripe = pal.accentSoft
    if done then stripe = pal.green elseif wrong then stripe = pal.red end
    rect(x, y + 8, 3, h - 8, stripe)

    draw.SimpleText("PFEILE", "hRadio_CL_Label", cx, y + 15, pal.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Pfeil-Spalte (hochkant): oben der erste, unten der letzte
    local seq = s and s.sequence or nil
    local n = seq and #seq or 4
    local cap = math.min(QT_CAP, (QT_COL_H - QT_CAP_GAP * (n - 1)) / n)
    local colY = y + 30 + (QT_COL_H - (n * cap + (n - 1) * QT_CAP_GAP)) * 0.5

    for i = 1, n do
        local mode, dir = "idle", nil
        if seq then
            dir = seq[i]
            if i < s.index then mode = "done"
            elseif i == s.index then mode = wrong and "wrong" or "current"
            else mode = "next" end
        elseif done then
            mode = "done"
        end

        local cy = colY + (i - 1) * (cap + QT_CAP_GAP)
        drawKeyCap(cx - cap * 0.5, cy, cap, dir, mode)

        -- Nummer links neben dem Pfeil
        local numCol = mode == "current" and pal.accent or (mode == "done" and pal.green or pal.muted)
        draw.SimpleText(tostring(i), "hRadio_CL_Hint", cx - cap * 0.5 - 7, cy + cap * 0.5, numCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Status
    local status, statusCol, sub
    if done then
        status, statusCol = "FERTIG", pal.green
        sub = done.saved >= 0.1 and string.format("+%.1f S", done.saved) or "SOFORT"
    elseif s then
        if wrong then
            status, statusCol, sub = "FALSCH", pal.redText, "VON VORN"
        else
            status, statusCol = QT_DIR_NAME[seq[s.index]] or "", pal.accent
            sub = math.min(s.index, n) .. " / " .. n
        end
    elseif running then
        status, statusCol, sub = "NORMAL", pal.soft, "OHNE FOLGE"
    else
        status, statusCol, sub = "BEREIT", pal.soft, "BEHANDLUNG"
    end

    local sy = y + 30 + QT_COL_H + 14
    draw.SimpleText(fitText(status, "hRadio_MD_Tab", w - 12), "hRadio_MD_Tab", cx, sy, statusCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(fitText(sub, "hRadio_CL_Tag", w - 12), "hRadio_CL_Tag", cx, sy + 17, pal.soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Restzeit: so lange dauert es ohne Pfeile
    local bx, bw = x + 10, w - 18
    local barY = y + h - 30
    fillCut(bx, barY, bw, 8, 3, pal.panel2)
    if running then
        local frac = math.Clamp(1 - (t.endsAt - CurTime()) / math.max(t.duration, 0.01), 0, 1)
        if frac > 0 then fillCut(bx, barY, math.max(6, bw * frac), 8, 3, s and pal.accentSoft or pal.accentDim) end
        draw.SimpleText(string.format("%.1f S", math.max(0, t.endsAt - CurTime())), "hRadio_CL_Hint", cx, barY + 18, pal.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("RICHTIG = SOFORT", "hRadio_CL_Hint", cx, barY + 18, pal.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    outlineCut(bx, barY, bw, 8, 3, pal.line2, 1)

    if hovering(x, y, w, h) then
        hoverInfo = {
            { text = "Schnellbehandlung: Pfeiltasten (oder WASD) von oben nach unten drücken – dann ist die Behandlung sofort fertig. Falsche Taste = von vorn.", color = pal.text }
        }
    end
end

local function drawMedicMenu(ply)
    if not IsValid(md.patient) then return end

    local snap = snapshot()
    hoverInfo = nil

    drawHeader(ply)

    local x, w = PAD, INNER_W
    local y = HEADER_H

    drawChips(snap, x, y, w)
    y = y + CHIP_H + 6

    -- Körper links neben dem Menü (ab Höhe des Zustands), Befund über die volle Breite
    drawBody(BODY_X, HEADER_H, BODY_W, BODY_H)
    drawDetails(snap, x, y, w, DETAIL_H)
    y = y + DETAIL_H + GAP

    drawQuickBar(ply, x, y, w)
    y = y + QUICK_H + GAP

    drawTabs(x, y, w)
    y = y + tabsHeight() + GAP

    drawCategory(snap, x, y, w)
    y = y + CAT_H + 4 + gridHeight() + HINT_H

    if config().MedicQuickTreat ~= false then drawQuickPanel(ply) end

    drawInfo(x, y, w)
end

------------------
-- Öffnen / Schließen
------------------

local function pickPatient()
    local ply = LocalPlayer()
    if not IsValid(ply) then return nil end
    return KMS.FindPatient()
end

local function deny(text)
    if RealTime() < (md.nextDeny or 0) then return false end
    md.nextDeny = RealTime() + 2
    notification.AddLegacy(text, NOTIFY_HINT, 3)
    playUISound("buttons/button10.wav")
    print("[hRadio] Medic-Menü: " .. text)
    return false
end

local function canOpen(ply)
    if not KMS.Settings.enabled then return deny("Das Medical-System ist auf dem Server ausgeschaltet.") end
    if not ply:Alive() or KMS.Self.conscious == false then return deny("Du bist bewusstlos.") end
    if KMS.Exempt and KMS.Exempt(ply) then return deny("Dein Job ist vom Medical-System ausgenommen.") end
    if KF and KF.Integrations and KF.Integrations.PlayerInWorld and not KF.Integrations.PlayerInWorld(ply) then
        return deny("Das Medic-Menü geht gerade nicht (nicht in der Welt).")
    end

    local target = pickPatient()
    if not IsValid(target) then return deny("Kein Patient gefunden.") end

    md.nextPatient = target
    return true
end

-- Taste: MedicKey aus der Config, sonst die Menü-Taste des Medical-Systems (Spieler-/Server-Einstellung), sonst K
local function medicKey()
    local key = tonumber(config().MedicKey)
    if key and key > 0 then return key end

    local cv = GetConVar("kms_menu_key")
    if cv and KMS.BindKey then
        key = KMS.BindKey(cv, "keyMenu")
        if isnumber(key) and key > 0 then return key end
    end

    return KEY_K
end

hradio.RegisterComlinkApp("medic", {
    width = MENU_W,
    height = menuHeight,
    draw = drawMedicMenu,
    closeOnGRN = false, -- Funkstörung betrifft nur den Funk
    key = medicKey,
    canOpen = canOpen,
    onOpen = function()
        md.grid = 0
        md.detail = 0
        md.patient = nil
        setPatient(md.nextPatient or LocalPlayer())
        md.nextPatient = nil
        if md.cat == "inventory" and KMS.Settings.infiniteSupplies then md.cat = "examine" end
    end,
    onClose = function()
        cancelMenuTreatment()
        setPatient(nil)
        md.overGrid, md.overDetail = nil, nil
    end,
    onThirdPerson = function(ply)
        -- Standard: nur Ego-Perspektive (Hinweis wie beim Funk). MedicThirdPersonClassic = true -> altes 2D-Menü
        if config().MedicThirdPersonClassic ~= true then return false end

        local target = md.nextPatient or pickPatient()
        md.nextPatient = nil
        if KMS.OpenClassicMenuOn then KMS.OpenClassicMenuOn(target) else KMS.OpenMenuOn(target) end
        return true
    end,
    onWheel = function(delta)
        local step = delta > 0 and -1 or 1
        if md.overDetail then
            md.detail = math.max(0, md.detail + step)
        else
            md.grid = math.max(0, md.grid + step)
        end
    end
})

-- Patient prüfen wie beim alten Menü: weg, zu weit oder du selbst bewusstlos -> schließen
hook.Add("Think", "hRadio_MedicValidate", function()
    if not isOpen() then return end

    local ply = LocalPlayer()
    local patient = md.patient

    if not IsValid(patient) or not ply:Alive() or KMS.Self.conscious == false or not KMS.Settings.enabled then
        hradio.CloseComlink(true)
        return
    end

    if patient ~= ply and not KMS.SameVehicle(ply, patient)
        and KMS.PatientDisplayEnt(patient):GetPos():Distance(ply:GetPos()) > KMS.Settings.maxTreatDistance * KMS.WatchMargin then
        notification.AddLegacy("Patient außer Reichweite.", NOTIFY_HINT, 3)
        hradio.CloseComlink()
    end
end)

------------------
-- Anbindung an das Medical-System
------------------

-- Liefert true, wenn das Comlink-Medic-Menü das Öffnen übernommen hat (auch: schon offen -> schließen)
function KMS.OpenComlinkMenu()
    if not hradio.ComlinkApps or not hradio.ComlinkApps.medic then return false end
    hradio.ToggleComlink("medic")
    return true
end

-- Altes Medical-Addon (ohne Comlink-Anpassung): Chat-Befehl / kms_menu trotzdem auf das Comlink legen.
if not KMS.OpenClassicMenuOn then
    KMS.OpenClassicMenuOn = KMS.OpenMenuOn

    function KMS.OpenMenu()
        if KMS.InteractActive and KMS.InteractActive() then return end
        if KMS.Exempt and KMS.Exempt(LocalPlayer()) then return end
        if KMS.OpenComlinkMenu() then return end
        KMS.OpenClassicMenuOn(KMS.FindPatient())
    end
end

-- Die alte Menü-Taste des Medical-Systems wird abgeschaltet, K läuft über das Comlink (medicKey)
hook.Remove("PlayerButtonDown", "KMS_MenuKey")

-- Für andere Addons / Binds
function hradio.OpenMedicMenu() hradio.OpenComlink("medic") end
function hradio.ToggleMedicMenu() hradio.ToggleComlink("medic") end
