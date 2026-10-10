local KMS = KrakensMedical
local AID = KMS.AID
local L = KMS.L
local Scale = KF.Scale

local function C(key)
    return KF.UI.GetColor(key, AID)
end

function KMS.Button(parent, label, style, solid)
    local btn = vgui.Create("KF.Button", parent)
    btn:SetAddon(AID)
    btn:SetLabel(label)
    if style then btn:SetStyle(style) end
    if solid then btn:SetSolid(true) end
    btn:SetSound(KMS.Sounds.Click)
    btn:SetHoverSound(KMS.Sounds.Hover)
    return btn
end

KMS.Self = KMS.Self or {
    painBand = 0, bloodClass = 1, bleedBand = 0, hr = 80, spo2 = 97,
    tq = false, frac = false, splint = false,
    conscious = true, arrest = false, tier = 0, inv = {},
}
KMS.Treating = nil
KMS.ActivePresetClient = ""
KMS.FirstRunClient = false

local menuKeyConVar = CreateClientConVar("kms_menu_key", "-1", true, false)
local effectsModeConVar = CreateClientConVar("kms_effects_mode", "0", true, false)
local quickUseKeyConVar = CreateClientConVar("kms_quickuse_key", "-1", true, false)

function KMS.BindKey(convar, settingKey)
    local value = convar:GetInt()
    if value < 0 then return KMS.Settings[settingKey] or 0 end
    return value
end

hook.Add("PlayerButtonDown", "KMS_QuickUseKey", function(ply, key)
    if not IsFirstTimePredicted() then return end
    if ply ~= LocalPlayer() or key == 0 or key ~= KMS.BindKey(quickUseKeyConVar, "keyQuickUse") then return end
    if vgui.CursorVisible() or not KMS.Settings.enabled or not KMS.Settings.quickUseEnabled then return end
    if not ply:Alive() or KMS.Self.conscious == false then return end
    net.Start("KMS_QuickUse")
    net.SendToServer()
end)

-- Strivon: Ist das Comlink-Addon da, öffnet die Menü-Taste (Standard K) das Medic-Menü auf dem Comlink.
-- Das Comlink entfernt diesen Hook und fragt die Taste selbst ab (auch bei sichtbarem Mauszeiger).
hook.Add("PlayerButtonDown", "KMS_MenuKey", function(ply, key)
    if not IsFirstTimePredicted() then return end
    if ply ~= LocalPlayer() or key == 0 or key ~= KMS.BindKey(menuKeyConVar, "keyMenu") then return end
    if vgui.CursorVisible() or not KMS.Settings.enabled then return end
    if not KF.Integrations.PlayerInWorld(ply) then return end
    KMS.OpenMenu()
end)

function KMS.TArg(arg)
    if isstring(arg) and string.sub(arg, 1, 1) == "#" then
        return L(string.sub(arg, 2))
    end
    return arg
end

function KMS.FormatEntry(entry)
    local args = {}
    for i, arg in ipairs(entry.a or {}) do
        args[i] = KMS.TArg(arg)
    end
    return os.date("%H:%M", entry.t) .. "  " .. L(entry.k, unpack(args))
end

KF.Net.Receive("KMS_SyncConfig", function()
    local payload = KF.Net.ReadCompressed(32)
    if not istable(payload) then return end
    KMS.ApplyItemConfig(payload.items)
    KMS.ApplySettings(payload.settings)
    KMS.ActivePresetClient = tostring(payload.preset or "")
    KMS.FirstRunClient = payload.firstRun == true
    KMS.NPCs = istable(payload.npcs) and payload.npcs or {}
    if istable(payload.maps) then KMS.ServerMaps = payload.maps end
    if KMS.Settings.language ~= KF.Lang.GetCurrent(AID) then
        KF.Lang.SetLanguage(AID, KMS.Settings.language)
    end
    hook.Run("KMS_ConfigUpdated")
end)

KF.Net.Receive("KMS_SyncSelf", function()
    local payload = KF.Net.ReadCompressed(32)
    if not istable(payload) then return end
    KMS.Self = payload
    KMS.DeathAt = payload.deathIn and (CurTime() + payload.deathIn) or nil
    KMS.DownedAt = payload.downFor and (CurTime() - payload.downFor) or nil
    hook.Run("KMS_SelfUpdated")
end)

KF.Net.Receive("KMS_Notify", function()
    local msgType = net.ReadString()
    local key = net.ReadString()
    local count = net.ReadUInt(3)
    local args = {}
    for i = 1, count do
        args[i] = KMS.TArg(net.ReadString())
    end
    KF.Notifications.Show(L(key, unpack(args)), msgType, 4, AID)
    if KMS.Settings.notifySounds and msgType == "error" then
        KMS.PlaySound("Error")
    end
end)

KF.Net.Receive("KMS_Progress", function()
    local treatId = net.ReadString()
    local endsAt = net.ReadFloat()
    local duration = net.ReadFloat()
    local source = KMS.LastTreatSource
    KMS.LastTreatSource = nil
    if treatId == "" then
        KMS.Treating = nil
    else
        KMS.Treating = { id = treatId, endsAt = CurTime() + math.max(0, endsAt - CurTime()), duration = duration, source = source }
    end
    if KMS.UI and KMS.UI.Refresh then KMS.UI.Refresh() end
end)

KMS.PatientSnapshots = KMS.PatientSnapshots or {}

KF.Net.Receive("KMS_SyncPatient", function()
    local patient = net.ReadEntity()
    local snapshot = KF.Net.ReadCompressed(32)
    if not istable(snapshot) or not IsValid(patient) then return end
    snapshot.receivedAt = CurTime()
    KMS.PatientSnapshots[patient] = snapshot
    hook.Run("KMS_PatientUpdated", patient)
end)

hook.Add("InitPostEntity", "KMS_RequestSync", function()
    timer.Simple(3, function()
        net.Start("KMS_RequestSync")
        net.WriteBool(false)
        net.SendToServer()
    end)
end)

local watchDesired = {}
local watchLastSent = 0

local function FlushWatch()
    for patient, watching in pairs(watchDesired) do
        if CurTime() - watchLastSent < 0.3 then
            timer.Create("KMS_WatchFlush", 0.31 - (CurTime() - watchLastSent), 1, FlushWatch)
            return
        end
        watchDesired[patient] = nil
        if IsValid(patient) then
            watchLastSent = CurTime()
            net.Start("KMS_Watch")
            net.WriteEntity(patient)
            net.WriteBool(watching)
            net.SendToServer()
        end
    end
end

function KMS.SendWatch(patient, watching)
    if not IsValid(patient) then return end
    watchDesired[patient] = watching
    if not watching then
        KMS.PatientSnapshots[patient] = nil
    end
    FlushWatch()
end

timer.Create("KMS_WatchKeepalive", 2, 0, function()
    for patient in pairs(KMS.PatientSnapshots) do
        if not IsValid(patient) then
            KMS.PatientSnapshots[patient] = nil
        end
    end
    local menuPatient = KMS.UI and KMS.UI.MenuPatient and KMS.UI.MenuPatient() or nil
    if IsValid(menuPatient) then
        KMS.SendWatch(menuPatient, true)
    end
    local interactPatient = KMS.InteractPatient and KMS.InteractPatient() or nil
    if IsValid(interactPatient) and interactPatient ~= menuPatient then
        KMS.SendWatch(interactPatient, true)
    end
    if KMS.InteractReassertWatch then KMS.InteractReassertWatch() end
end)

function KMS.RagdollOwner(ent)
    if not IsValid(ent) or ent:GetClass() ~= "prop_ragdoll" then return nil end
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetNWEntity("kms_ragdoll") == ent then return ply end
    end
end

function KMS.PatientName(patient)
    if not IsValid(patient) then return L("ui_unknown") end
    if patient:IsPlayer() then return KF.Integrations.GetPlayerName(patient) or patient:Nick() end
    if patient:GetNWBool("kms_sim", false) then return L("sim_patient") end
    return L("ui_unknown")
end

function KMS.PatientDisplayEnt(patient)
    local ragdoll = patient:GetNWEntity("kms_ragdoll")
    return IsValid(ragdoll) and ragdoll or patient
end

function KMS.FindPatient()
    local ply = LocalPlayer()
    local trace = ply:GetEyeTrace()
    local maxDist = KMS.Settings.maxTreatDistance
    local function OnFoot(other)
        return not IsValid(other:GetVehicle()) and not IsValid(other:GetNWEntity("kms_loaded_in"))
    end
    local function Targetable(other)
        return other:Alive() and not KMS.Exempt(other) and not KMS.Cloaked(other)
    end
    local ent = trace.Entity
    if IsValid(ent) then
        if ent:GetNWBool("kms_sim", false) and ent:GetPos():Distance(ply:GetPos()) <= maxDist * 1.5 then return ent end
        local owner = KMS.RagdollOwner(ent)
        if owner and Targetable(owner) and ent:GetPos():Distance(ply:GetPos()) <= maxDist * 1.5 then return owner end
        if ent:IsPlayer() and OnFoot(ent) and Targetable(ent) and ent:GetPos():Distance(ply:GetPos()) <= maxDist then return ent end
    end
    local best, bestDist
    for _, other in ipairs(player.GetAll()) do
        if other ~= ply and OnFoot(other) and Targetable(other) then
            local body = KMS.PatientDisplayEnt(other)
            local dist = body:GetPos():Distance(trace.HitPos)
            if dist <= maxDist and (not bestDist or dist < bestDist) and body:GetPos():Distance(ply:GetPos()) <= maxDist * 1.5 then
                best, bestDist = other, dist
            end
        end
    end
    return best or ply
end

local WOUND_RED_SCORE = 4

function KMS.PartWoundScores(partState)
    local open, bandaged = 0, 0
    for _, wound in ipairs(partState and partState.wounds or {}) do
        local score = wound.s * KMS.WoundEvents(wound)
        if wound.b then
            bandaged = bandaged + score
        else
            open = open + score
        end
    end
    return open, bandaged
end

local STATE_CLEAR = KMS.StatusColors.clear
local STATE_CRITICAL = KMS.StatusColors.critical
local STATE_OPEN = KMS.StatusColors.open
local STATE_TREATED = KMS.StatusColors.treated

local function WoundLine(wound)
    local name = L("size_" .. wound.s) .. " " .. L("wound_" .. wound.t)
    if wound.n < 1 then
        return L("wound_line_partial", name)
    end
    return L("wound_line", math.ceil(wound.n), L("size_" .. wound.s), L("wound_" .. wound.t))
end

function KMS.PartStateColor(partState)
    if not partState then return STATE_CLEAR end
    local open, bandaged = KMS.PartWoundScores(partState)
    if (partState.frac and not partState.splint) or open >= WOUND_RED_SCORE then return STATE_CRITICAL end
    if open > 0 then return STATE_OPEN end
    if bandaged > 0 or partState.frac then return STATE_TREATED end
    return STATE_CLEAR
end

local TRAUMA_COLORS = { Color(150, 190, 255), Color(95, 150, 245), Color(70, 90, 250), Color(160, 60, 230) }

function KMS.TraumaBand(partId, dmg)
    local norm = (dmg or 0) / (KMS.TraumaThresholds[partId] or 2)
    if norm >= 1 then return 4 end
    if norm >= 0.75 then return 3 end
    if norm >= 0.5 then return 2 end
    if norm >= 0.25 then return 1 end
    return 0
end

function KMS.PartLines(partState, partId)
    local lines = {}
    for _, wound in ipairs(partState and partState.wounds or {}) do
        local text = WoundLine(wound)
        if wound.b then
            lines[#lines + 1] = { text = text .. "  -  " .. L("ov_bandaged", L("item_" .. wound.b)), color = STATE_TREATED }
        else
            lines[#lines + 1] = { text = text, color = STATE_CRITICAL }
        end
    end
    for _, wound in ipairs(partState and partState.st or {}) do
        lines[#lines + 1] = { text = "[S] " .. WoundLine(wound) .. "  -  " .. L("ov_stitched"), color = Color(150, 150, 150) }
    end
    if partState then
        if partState.tq then
            lines[#lines + 1] = { text = L("ov_tourniquet"), color = Color(90, 120, 240) }
        end
        if partState.frac then
            lines[#lines + 1] = { text = partState.splint and L("ov_splinted") or L("ov_fractured"), color = partState.splint and STATE_TREATED or STATE_CRITICAL }
        end
        local trauma = KMS.TraumaBand(partId, partState.dmg)
        if trauma > 0 then
            lines[#lines + 1] = { text = L("ov_trauma_" .. trauma), color = TRAUMA_COLORS[trauma] }
        end
    end
    return lines
end

local IV_FAMILIES = { "blood", "plasma", "saline" }
local IV_COLOR = KMS.StatusColors.treated

function KMS.IVLines(states)
    local lines = {}
    local ivs = states and states.ivs
    if istable(ivs) then
        for _, fam in ipairs(IV_FAMILIES) do
            local ml = ivs[fam]
            if ml and ml > 0 then
                lines[#lines + 1] = { text = L("int_iv_typed", L("ivfam_" .. fam), ml), color = IV_COLOR }
            end
        end
    end
    return lines
end

function KMS.BloodClassLine(bloodClass)
    return { text = L("blood_" .. bloodClass), color = bloodClass >= 3 and KMS.StatusColors.critical or KMS.StatusColors.warning }
end

function KMS.PainLine(painBand)
    return { text = painBand >= 3 and L("ov_severe_pain") or L("ov_in_pain"), color = C("TextPrimary") }
end

local facilityPos, facilityVehicles, facilityFrame = {}, {}, -1

local function FacilityPositions()
    if facilityFrame == FrameNumber() then return facilityPos, facilityVehicles end
    facilityFrame = FrameNumber()
    facilityPos = {}
    facilityVehicles = {}
    for _, facility in ipairs(ents.FindByClass("kms_npc")) do
        local npc = (KMS.NPCs or {})[facility:GetNWString("kms_npc_id", "")]
        if npc and KMS.FacilityTypes[npc.npcType] then
            facilityPos[#facilityPos + 1] = facility:GetPos()
        end
    end
    for _, facility in ipairs(ents.FindByClass("kms_medbay")) do
        facilityPos[#facilityPos + 1] = facility:GetPos()
    end
    local ply = LocalPlayer()
    if IsValid(ply) and next(KMS.Settings.medVehicles) ~= nil then
        for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 800)) do
            if ent:GetNWBool("kms_medvehicle", false) then
                facilityVehicles[#facilityVehicles + 1] = ent
            end
        end
    end
    return facilityPos, facilityVehicles
end

local function NearFacility(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() and KMS.InsideMedVehicle(ent) then return true end
    local origin = ent:GetPos()
    local positions, vehicles = FacilityPositions()
    for _, pos in ipairs(positions) do
        if pos:DistToSqr(origin) <= KMS.FacilityRangeSqr then return true end
    end
    for _, veh in ipairs(vehicles) do
        if IsValid(veh) and veh:NearestPoint(origin):DistToSqr(origin) <= KMS.FacilityRangeSqr then return true end
    end
    return false
end

function KMS.ClientTier()
    return KMS.BoostTier(KMS.Self.tier or 0, NearFacility(LocalPlayer()))
end

function KMS.CanShowTreatment(def)
    return KMS.TreatmentTier(def.id) <= KMS.ClientTier()
end

local function MorphineBlocked(snapshot)
    local states = snapshot and snapshot.states
    if not states or not states.morphineIn then return false end
    return states.morphineIn - (CurTime() - (snapshot.receivedAt or CurTime())) > 0
end

local function LocationBlocked(def, patient)
    if not def.locationKey or KMS.Settings[def.locationKey] ~= "crate" then return false end
    return not (NearFacility(LocalPlayer()) or NearFacility(KMS.PatientDisplayEnt(patient)))
end

function KMS.HolderInv(snapshot, usePatient)
    if usePatient and KMS.Settings.itemSharing and snapshot and snapshot.inv then
        return snapshot.inv
    end
    return KMS.Self.inv or {}
end

function KMS.LacksItem(def, snapshot, usePatient)
    if not def.item or KMS.Settings.infiniteSupplies then return false end
    return (KMS.HolderInv(snapshot, usePatient)[def.item] or 0) <= 0
end

function KMS.TreatmentBlockReason(def, snapshot, patient, partId, usePatient)
    if not snapshot then return L("err_invalid") end
    if snapshot.states and snapshot.states.triage == 4 then return L("err_dead") end
    if KMS.Treating and CurTime() < KMS.Treating.endsAt then return L("err_busy") end
    if patient == LocalPlayer() and (def.noSelf or not KMS.Settings.selfTreatment) then
        return L("err_self")
    end
    if KMS.LacksItem(def, snapshot, usePatient) then
        return L("err_no_item", L("item_" .. def.item))
    end
    if def.id == "morphine" and MorphineBlocked(snapshot) then return L("err_morphine_cd") end
    if def.id == "cpr" and snapshot.states and snapshot.states.cpr then return L("err_cpr_taken") end
    if def.id == "pak" and KMS.Settings.pakRequireStable and not (snapshot.states and snapshot.states.stable) then
        return L("err_pak_stable")
    end
    if LocationBlocked(def, patient) then return L("err_location") end
    if KMS.TreatmentAvailable(def, snapshot, partId) then return nil end
    local part = KMS.PartById[partId]
    if def.limbsOnly and part and not part.limb then return L("err_limb_only") end
    if def.torsoOnly and partId ~= "torso" then return L("err_torso_only") end
    if def.headOnly and partId ~= "head" then return L("err_head_only") end
    if def.id == "cpr" then return L("err_not_arrest") end
    local partState = snapshot.parts and snapshot.parts[partId]
    if def.id == "surgical" and partState and KMS.PartHasBleedingWound(partState) then return L("err_stitch_bleeding") end
    return L("err_no_wound")
end

function KMS.ActionLabel(def, inv)
    local label = L("treat_" .. def.id)
    if def.item and not KMS.Settings.infiniteSupplies then
        label = label .. "  (" .. ((inv or KMS.Self.inv or {})[def.item] or 0) .. ")"
    end
    return label
end

function KMS.SendTreat(patient, treatId, partId, usePatient, source)
    KMS.LastTreatSource = source or "interact"
    net.Start("KMS_Treat")
    net.WriteEntity(patient)
    net.WriteString(treatId)
    net.WriteString(partId)
    net.WriteBool(usePatient == true)
    -- Strivon: Schnellbehandlung (Pfeiltasten) nur aus dem offenen Comlink-Medic-Menü
    net.WriteBool(source == "menu" and KMS.ComlinkQuickTreatOn ~= nil and KMS.ComlinkQuickTreatOn() == true)
    net.SendToServer()
end

function KMS.SendTriage(patient, level)
    net.Start("KMS_Triage")
    net.WriteEntity(patient)
    net.WriteUInt(level, 3)
    net.SendToServer()
end

local function BodyMat(name)
    local path = "medical_system/body/" .. name .. ".png"
    if file.Exists("materials/" .. path, "GAME") then
        return Material(path, "smooth")
    end
end

KMS.BodyRegions = {
    { id = "arm_l", rect = { 0.564, 0.168, 0.133, 0.424 }, body = BodyMat("left_arm"), frac = BodyMat("left_arm_fractured"), tq = BodyMat("left_arm_torniquet") },
    { id = "arm_r", rect = { 0.316, 0.166, 0.133, 0.424 }, body = BodyMat("right_arm"), frac = BodyMat("right_arm_fractured"), tq = BodyMat("right_arm_torniquet") },
    { id = "leg_l", rect = { 0.512, 0.428, 0.102, 0.551 }, body = BodyMat("left_leg"), frac = BodyMat("left_leg_fractured"), tq = BodyMat("left_leg_torniquet") },
    { id = "leg_r", rect = { 0.4, 0.426, 0.102, 0.551 }, body = BodyMat("right_leg"), frac = BodyMat("right_leg_fractured"), tq = BodyMat("right_leg_torniquet") },
    { id = "torso", rect = { 0.41, 0.104, 0.197, 0.412 }, body = BodyMat("torso") },
    { id = "head", rect = { 0.457, 0, 0.098, 0.135 }, body = BodyMat("head") },
}

local BLOOD_COLORS = {
    Color(255, 242, 163), Color(255, 222, 117), Color(255, 200, 78),
    Color(255, 176, 52), Color(253, 150, 34), Color(247, 122, 22),
    Color(234, 92, 20), Color(210, 58, 28), Color(176, 26, 38),
}

local DAMAGE_COLORS = {
    Color(191, 242, 255), Color(158, 219, 255), Color(138, 196, 255),
    Color(122, 171, 255), Color(107, 145, 255), Color(94, 120, 255),
    Color(79, 92, 255), Color(56, 59, 255), Color(0, 0, 255),
}

local function GradeColor(colors, score)
    return colors[math.Clamp(math.ceil(math.min(score / WOUND_RED_SCORE, 1) * #colors), 1, #colors)]
end

local function PartBodyColor(partState)
    if not partState then return color_white end
    local open, bandaged = KMS.PartWoundScores(partState)
    if open > 0 then return GradeColor(BLOOD_COLORS, open) end
    if bandaged > 0 then return GradeColor(DAMAGE_COLORS, bandaged) end
    return color_white
end

local function DrawBodyLayers(getPartState, region, x, y, size)
    local partState = getPartState(region.id)
    surface.SetDrawColor(PartBodyColor(partState))
    if not region.body then
        local rect = region.rect
        surface.DrawRect(x + rect[1] * size, y + rect[2] * size, rect[3] * size, rect[4] * size)
        return
    end
    surface.SetMaterial(region.body)
    surface.DrawTexturedRect(x, y, size, size)
    if not partState then return end
    if partState.frac and not partState.splint and region.frac then
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(region.frac)
        surface.DrawTexturedRect(x, y, size, size)
    end
    if partState.tq and region.tq then
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(region.tq)
        surface.DrawTexturedRect(x, y, size, size)
    end
end

local OUTLINE_DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

local function DrawBodyOutline(region, x, y, size, color)
    local off = math.max(1, math.Round(Scale(2)))
    surface.SetDrawColor(color)
    if not region.body then
        local rect = region.rect
        surface.DrawOutlinedRect(x + rect[1] * size - off, y + rect[2] * size - off, rect[3] * size + off * 2, rect[4] * size + off * 2, off)
        return
    end
    surface.SetMaterial(region.body)
    for _, dir in ipairs(OUTLINE_DIRS) do
        surface.DrawTexturedRect(x + dir[1] * off, y + dir[2] * off, size, size)
    end
end

function KMS.DrawBodyImage(x, y, size, getPartState, selectedId, hoverId)
    for _, region in ipairs(KMS.BodyRegions) do
        DrawBodyLayers(getPartState, region, x, y, size)
    end
    for _, region in ipairs(KMS.BodyRegions) do
        local outline
        if region.id == selectedId then
            outline = C("Accent")
        elseif region.id == hoverId then
            outline = KF.UI.ColorAlpha(C("TextPrimary"), 150)
        end
        if outline then
            DrawBodyOutline(region, x, y, size, outline)
            DrawBodyLayers(getPartState, region, x, y, size)
        end
    end
end

function KMS.BodyPanel(parent)
    local panel = vgui.Create("DPanel", parent)
    local getPartState = function(partId)
        return panel.GetPartState and panel:GetPartState(partId) or nil
    end
    local labelH = Scale(22)
    panel.Paint = function(self, w, h)
        local size = math.min(w, h - labelH)
        if size <= 0 then return end
        local x, y = (w - size) / 2, (h - labelH - size) / 2
        local hover, hoverArea
        if self:IsHovered() then
            local mx, my = self:CursorPos()
            local u, v = (mx - x) / size, (my - y) / size
            for _, region in ipairs(KMS.BodyRegions) do
                local rect = region.rect
                if u >= rect[1] and u <= rect[1] + rect[3] and v >= rect[2] and v <= rect[2] + rect[4] then
                    local area = rect[3] * rect[4]
                    if not hoverArea or area < hoverArea then
                        hover, hoverArea = region.id, area
                    end
                end
            end
        end
        self.KMSHover = hover
        self:SetCursor(hover and "hand" or "arrow")
        KMS.DrawBodyImage(x, y, size, getPartState, self.GetSelected and self:GetSelected() or nil, hover)
        if hover then
            draw.SimpleText(KMS.PartLabel(hover), KF.Fonts.Get(AID, "small"), w / 2, h - Scale(4), C("TextSecondary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    end
    panel.OnMousePressed = function(self, code)
        if code == MOUSE_LEFT and self.KMSHover and self.OnPartClick then
            self:OnPartClick(self.KMSHover)
        end
    end
    return panel
end

local BLOCKS = {
    { id = "alerts", w = 0.24, h = 0.09, labelKey = "hud_block_alerts" },
    { id = "triage", w = 0.14, h = 0.2, labelKey = "hud_block_triage" },
}

local DEFAULTS = {
    alerts = { x = 0.38, y = 0.76, anchor = "left", yAnchor = "bottom", scale = 1 },
    triage = { x = 0.99, y = 0.3, anchor = "right", yAnchor = "top", scale = 1 },
}

local layout

local function GetLayout()
    if not layout then
        layout = KF.LayoutEditor.LoadCookieLayout("kms", BLOCKS)
        for id, def in pairs(DEFAULTS) do
            layout[id] = layout[id] or table.Copy(def)
        end
    end
    return layout
end

function KMS.OpenLayoutEditor()
    KF.LayoutEditor.Open({
        blocks = BLOCKS,
        defaults = DEFAULTS,
        isAdmin = false,
        L = L,
        resolveLayout = function(id)
            return GetLayout()[id]
        end,
        onSave = function(data)
            KF.LayoutEditor.SaveCookieLayout("kms", BLOCKS, data)
            layout = nil
        end,
        onReset = function()
            KF.LayoutEditor.ResetCookieLayout("kms", BLOCKS)
            layout = nil
        end,
    })
end

local function BlockRect(id)
    local lay = GetLayout()[id]
    local block
    for _, b in ipairs(BLOCKS) do
        if b.id == id then block = b end
    end
    local bw = block.w * ScrW() * (lay.scale or 1)
    local bh = block.h * ScrH() * (lay.scale or 1)
    local bx, by = KF.LayoutEditor.NormToScreen(lay.x, lay.y, bw, bh, lay.anchor, lay.yAnchor)
    return bx, by, bw, bh
end

local function DrawAlertsBlock()
    local treating = KMS.Treating
    if not treating then return end
    if CurTime() >= treating.endsAt then
        KMS.Treating = nil
        return
    end
    if KMS.UI and KMS.UI.MenuPatient and KMS.UI.MenuPatient() then return end
    local x, y, w, h = BlockRect("alerts")
    local strat = KMS.StratagemState()
    local extra = strat and math.floor(h * 0.65) or 0
    KF.HUD.PanelBG(x, y - extra, w, h + extra, { alpha = 200, accentLine = true, accentSide = "bottom", addonId = AID })
    if strat then
        KMS.DrawStratagemRow(x + Scale(12), y - extra + Scale(4), w - Scale(24), extra - Scale(16))
        draw.SimpleText(L("strat_hint"), KF.Fonts.Get(AID, "tiny"), x + w / 2, y - Scale(4), C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end
    local frac = 1 - (treating.endsAt - CurTime()) / treating.duration
    local isHaul = string.find(treating.id, "haul_", 1, true) == 1
    local label = isHaul and string.upper(L("int_" .. string.sub(treating.id, 6))) or L("hud_treating", L("treat_" .. treating.id))
    draw.SimpleText(label, KF.Fonts.GetBold(AID, "small"), x + w / 2, y + h * 0.26, C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    KF.HUD.NotchedBar(x + Scale(12), y + h * 0.48, w - Scale(24), Scale(10), math.Clamp(frac, 0, 1), C("Accent"), C("PanelDark"))
    if treating.id ~= "npc" then
        draw.SimpleText(L("hud_cancel_hint"), KF.Fonts.Get(AID, "tiny"), x + w / 2, y + h * 0.82, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local TRIAGE_TEXT_DARK = Color(15, 15, 15)
local TRIAGE_TEXT_LIGHT = Color(220, 220, 220)

local function TriageOrder(a, b)
    if a.triage ~= b.triage then return a.triage < b.triage end
    return a.dist < b.dist
end

local function DrawTriageBlock()
    if (KMS.Self.tier or 0) < 1 then return end
    local ply = LocalPlayer()
    local myPos = ply:GetPos()
    local rows = {}
    for _, other in ipairs(player.GetAll()) do
        if other ~= ply then
            local triage = other:GetNWInt("kms_triage", 0)
            if (triage > 0 or KMS.IsDowned(other)) and not KMS.Exempt(other) and not KMS.Cloaked(other) then
                rows[#rows + 1] = { ply = other, triage = triage, dist = KMS.PatientDisplayEnt(other):GetPos():Distance(myPos) }
            end
        end
    end
    if #rows == 0 then return end
    table.sort(rows, TriageOrder)
    local x, y, w, h = BlockRect("triage")
    local headerH = Scale(24)
    local rowH = Scale(20)
    local count = math.min(#rows, math.max(1, math.floor((h - headerH) / rowH)))
    local smallFont = KF.Fonts.Get(AID, "small")
    KF.HUD.PanelBG(x, y, w, headerH + count * rowH + Scale(8), { alpha = 175, accentLine = true, accentSide = "left", addonId = AID })
    draw.SimpleText(L("cat_triage"), KF.Fonts.GetBold(AID, "small"), x + Scale(12), y + headerH / 2 + Scale(2), C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    for i = 1, count do
        local row = rows[i]
        local level = KMS.TriageById[row.triage]
        local ry = y + headerH + (i - 1) * rowH + Scale(2)
        surface.SetDrawColor(level.color)
        surface.DrawRect(x + Scale(12), ry + Scale(3), Scale(24), rowH - Scale(8))
        draw.SimpleText(row.triage > 0 and ("T" .. row.triage) or "?", KF.Fonts.GetBold(AID, "tiny"), x + Scale(24), ry + rowH / 2 - Scale(2),
            row.triage == 4 and TRIAGE_TEXT_LIGHT or TRIAGE_TEXT_DARK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local distText = math.Round(row.dist / KMS.DisplayUnitsPerMeter) .. "m"
        surface.SetFont(smallFont)
        local dw = surface.GetTextSize(distText)
        draw.SimpleText(distText, smallFont, x + w - Scale(12), ry + rowH / 2 - Scale(2), C("TextSecondary"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        draw.SimpleText(KMS.Ellipsize(KMS.PatientName(row.ply), smallFont, w - Scale(64) - dw), smallFont, x + Scale(44), ry + rowH / 2 - Scale(2), C("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

local pulsePhase = 0
local pulseWave = 0
local nextHeartbeat = 0

local function DrawStatusIndicators()
    if not KMS.Settings.staminaEnabled or KMS.Settings.staminaFeedback ~= "bar" then return end
    local exhaust = LocalPlayer():GetNWFloat("kms_exhaust", 0)
    if exhaust <= 0.02 then return end
    local x, y, w, h = BlockRect("alerts")
    local bw, bh = math.floor(w * 0.6), Scale(6)
    local bx = x + math.floor((w - bw) / 2)
    local by = y + h + Scale(6)
    local alpha = math.Clamp(80 + exhaust * 400, 80, 235)
    surface.SetDrawColor(18, 22, 26, alpha * 0.7)
    surface.DrawRect(bx, by, bw, bh)
    surface.SetDrawColor(120 + 115 * exhaust, 200 - 140 * exhaust * exhaust, 60, alpha)
    surface.DrawRect(bx, by, math.floor(bw * math.Clamp(1 - exhaust, 0, 1)), bh)
end

local VIGNETTE_MAT = CreateMaterial("KMS_RadialVignette", "UnlitGeneric", {
    ["$basetexture"] = "vgui/white",
    ["$vertexcolor"] = 1,
    ["$vertexalpha"] = 1,
    ["$translucent"] = 1,
    ["$nocull"] = 1,
})

local vignetteMeshes = {}

local function VignetteMesh(depth)
    local w, h = ScrW(), ScrH()
    local key = math.Round(depth * 50) .. ":" .. w .. "x" .. h
    local cached = vignetteMeshes[key]
    if cached then return cached end
    local cx, cy = w / 2, h / 2
    local maxR = math.sqrt(cx * cx + cy * cy)
    local innerR = maxR * math.Clamp(1 - depth * 2.05, 0.4, 0.92)
    local outerR = maxR * 1.02
    local segments = 48
    local rings = {}
    for i = 0, 5 do
        local t = i / 5
        rings[i + 1] = { innerR + (outerR - innerR) * t, math.Round(255 * t * t * (3 - 2 * t)) }
    end
    local m = Mesh(VIGNETTE_MAT)
    mesh.Begin(m, MATERIAL_QUADS, segments * (#rings - 1))
    for band = 1, #rings - 1 do
        local r1, a1 = rings[band][1], rings[band][2]
        local r2, a2 = rings[band + 1][1], rings[band + 1][2]
        for i = 0, segments - 1 do
            local ang1 = (i / segments) * math.pi * 2
            local ang2 = ((i + 1) / segments) * math.pi * 2
            local c1, s1 = math.cos(ang1), math.sin(ang1)
            local c2, s2 = math.cos(ang2), math.sin(ang2)
            mesh.Position(Vector(cx + c1 * r1, cy + s1 * r1, 0))
            mesh.Color(255, 255, 255, a1)
            mesh.TexCoord(0, 0, 0)
            mesh.AdvanceVertex()
            mesh.Position(Vector(cx + c2 * r1, cy + s2 * r1, 0))
            mesh.Color(255, 255, 255, a1)
            mesh.TexCoord(0, 1, 0)
            mesh.AdvanceVertex()
            mesh.Position(Vector(cx + c2 * r2, cy + s2 * r2, 0))
            mesh.Color(255, 255, 255, a2)
            mesh.TexCoord(0, 1, 1)
            mesh.AdvanceVertex()
            mesh.Position(Vector(cx + c1 * r2, cy + s1 * r2, 0))
            mesh.Color(255, 255, 255, a2)
            mesh.TexCoord(0, 0, 1)
            mesh.AdvanceVertex()
        end
    end
    mesh.End()
    vignetteMeshes[key] = m
    return m
end

hook.Add("OnScreenSizeChanged", "KMS_VignetteFlush", function()
    for _, m in pairs(vignetteMeshes) do
        if m.Destroy then m:Destroy() end
    end
    vignetteMeshes = {}
end)

local vignetteTint = Vector(1, 1, 1)

local function DrawVignette(depth, r, g, b, alpha)
    alpha = math.Clamp(alpha, 0, 255)
    if alpha < 1 then return end
    vignetteTint:SetUnpacked(r / 255, g / 255, b / 255)
    VIGNETTE_MAT:SetVector("$color", vignetteTint)
    VIGNETTE_MAT:SetFloat("$alpha", alpha / 255)
    render.SetMaterial(VIGNETTE_MAT)
    VignetteMesh(depth):Draw()
end

local consciousWas = true
local unconSince, wakeAt = 0, 0

hook.Add("KMS_SelfUpdated", "KMS_ConsciousTransition", function()
    local nowConscious = KMS.Self.conscious ~= false
    if consciousWas and not nowConscious then
        unconSince = CurTime()
    elseif not consciousWas and nowConscious then
        wakeAt = CurTime()
    end
    consciousWas = nowConscious
end)

local function DownedFade()
    if unconSince <= 0 then return 1 end
    return math.Clamp((CurTime() - unconSince) / 1.5, 0, 1)
end

local function DrawUnconsciousOverlay(frac)
    surface.SetDrawColor(5, 5, 8, math.floor(215 * frac))
    surface.DrawRect(0, 0, ScrW(), ScrH())
    DrawVignette(0.26, 0, 0, 0, 90 * frac)
end

local downedScreen
local deathPeak = 0

local function GiveUpIn()
    if not KMS.DownedAt then return KMS.Settings.giveUpDelay end
    return math.max(0, KMS.Settings.giveUpDelay - (CurTime() - KMS.DownedAt))
end

local function CallMedicIn()
    local callAt = LocalPlayer():GetNWFloat("kms_medcall", 0)
    if callAt <= 0 then return 0 end
    return math.max(0, KMS.MedCallCooldown - (CurTime() - callAt))
end

local function SendDowned(giveUp)
    net.Start("KMS_Downed")
    net.WriteBool(giveUp)
    net.SendToServer()
end

local function DownedLines()
    local state = KMS.Self
    local lines = {}
    local bleedBand = state.bleedBand or 0
    if bleedBand > 0 then
        lines[#lines + 1] = { text = L("bleed_rate" .. bleedBand),
            color = bleedBand >= 3 and KMS.StatusColors.critical or KMS.StatusColors.warning }
    end
    if (state.bloodClass or 1) > 1 then
        lines[#lines + 1] = KMS.BloodClassLine(state.bloodClass)
    end
    if (state.painBand or 0) > 0 then
        lines[#lines + 1] = KMS.PainLine(state.painBand)
    end
    if (state.spo2 or KMS.NormalSpO2) < 90 then
        lines[#lines + 1] = { text = L("hud_hypoxia"), color = KMS.StatusColors.critical }
    end
    if not lines[1] then
        lines[1] = { text = L("st_stable"), color = C("Success") }
    end
    return lines
end

local function SelfPartState(partId)
    local snapshot = KMS.PatientSnapshots[LocalPlayer()]
    return snapshot and snapshot.parts and snapshot.parts[partId]
end

local function OpenDownedScreen()
    local sw, sh = ScrW(), ScrH()
    local showTimer = KMS.Settings.arrestTimerVisible
    local titleY = sh * 0.16
    local ruleY = sh * 0.225
    local ruleW = math.min(sw * 0.34, Scale(640))
    local timerY = sh * 0.295
    local barW = math.min(sw * 0.26, Scale(500))
    local barY = sh * 0.455
    local linesY = showTimer and sh * 0.535 or sh * 0.33
    local lineH = Scale(28)
    local btnW, btnH, gap = Scale(270), Scale(48), Scale(18)
    local bandH = btnH + Scale(64)
    local bandY = sh * 0.735
    local btnY = bandY + (bandH - btnH) / 2
    deathPeak = 0

    local actions = {}
    if KMS.Settings.giveUpEnabled then
        actions[#actions + 1] = { key = "hud_btn_giveup", style = "danger", left = GiveUpIn,
            click = function() KMS.UI.Confirm(L("confirm_giveup"), function() SendDowned(true) end) end }
    end
    if KMS.Settings.medicCallEnabled then
        actions[#actions + 1] = { key = "hud_btn_call", style = "primary", solid = true, left = CallMedicIn,
            click = function() SendDowned(false) end }
    end

    local screen = vgui.Create("DPanel")
    screen:SetPos(0, 0)
    screen:SetSize(sw, sh)
    screen:MakePopup()
    screen:SetKeyboardInputEnabled(false)
    downedScreen = screen
    KMS.SendWatch(LocalPlayer(), true)

    screen.Think = function(s)
        s:SetAlpha(math.floor(255 * DownedFade()))
        if (s.nextWatch or 0) <= CurTime() then
            s.nextWatch = CurTime() + 2
            KMS.SendWatch(LocalPlayer(), true)
        end
    end

    screen.OnRemove = function()
        local menuPatient = KMS.UI and KMS.UI.MenuPatient and KMS.UI.MenuPatient() or nil
        if menuPatient ~= LocalPlayer() then
            KMS.SendWatch(LocalPlayer(), false)
        end
    end

    screen.Paint = function(_, w)
        local arrest = KMS.Self.arrest
        local accent = arrest and C("Error") or C("Accent")
        KF.Draw.GlowText(arrest and L("hud_arrest") or L("hud_unconscious"), KF.Fonts.GetBold(AID, "header"),
            w / 2, titleY, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        KF.HUD.HoloSeparator(w / 2 - ruleW / 2, ruleY, ruleW, { addonId = AID, color = accent, thickness = 1 })

        if showTimer then
            local left = KMS.DeathAt and math.max(0, KMS.DeathAt - CurTime()) or nil
            draw.SimpleText(L("hud_life_left"), KF.Fonts.Get(AID, "small"), w / 2, timerY, C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            if left then
                deathPeak = math.max(deathPeak, left)
                local frac = math.Clamp(left / math.max(1, deathPeak), 0, 1)
                local urgent = frac <= 0.25 or left <= 30
                local col = urgent and C("Error") or C("TextPrimary")
                KF.Draw.GlowText(KF.FormatTimeClock(left), KF.Fonts.GetBold(AID, "display"), w / 2, timerY + Scale(28),
                    col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                KF.HUD.NotchedBar(w / 2 - barW / 2, barY, barW, Scale(8), frac, col, C("PanelDark"))
            else
                local safe = (KMS.Self.bleedBand or 0) == 0
                draw.SimpleText(L(safe and "hud_no_eta" or "hud_eta_long"), KF.Fonts.GetBold(AID, "title"),
                    w / 2, timerY + Scale(34), safe and C("Success") or C("Warning"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end

        local bodySize = math.min(bandY - linesY - Scale(8), Scale(340))
        local lines = DownedLines()
        local bodyX = w / 2 - (bodySize + Scale(220)) / 2
        KMS.DrawBodyImage(bodyX, linesY, bodySize, SelfPartState)
        local textX = bodyX + bodySize + Scale(28)
        local textY = linesY + bodySize / 2 - (#lines * lineH) / 2
        for i, line in ipairs(lines) do
            draw.SimpleText(line.text, KF.Fonts.Get(AID, "body"), textX, textY + (i - 1) * lineH, line.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        if not actions[1] then return end
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), 18))
        surface.DrawRect(0, bandY, w, bandH)
        surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), 55))
        surface.DrawRect(0, bandY, w, 1)
        surface.DrawRect(0, bandY + bandH - 1, w, 1)
    end

    local totalW = #actions * btnW + math.max(0, #actions - 1) * gap
    for i, action in ipairs(actions) do
        local btn = KMS.Button(screen, L(action.key), action.style, action.solid)
        btn:SetSize(btnW, btnH)
        btn:SetPos(sw / 2 - totalW / 2 + (i - 1) * (btnW + gap), btnY)
        btn.Think = function(s)
            local left = action.left()
            s:SetEnabled(left <= 0)
            s:SetLabel(left <= 0 and L(action.key) or L("hud_available_in", KF.FormatTimeClock(left)))
        end
        btn.DoClick = action.click
    end
end

hook.Add("Think", "KMS_DownedScreen", function()
    local ply = LocalPlayer()
    local want = KMS.Settings.enabled and IsValid(ply) and ply:Alive()
        and KMS.Self.conscious == false and not KMS.Exempt(ply)
        and not ply:GetNWBool("KS.InRespawn", false)
    if want then
        if not IsValid(downedScreen) then OpenDownedScreen() end
    elseif IsValid(downedScreen) then
        downedScreen:Remove()
    end
end)

local function RebuildDownedScreen()
    if IsValid(downedScreen) then downedScreen:Remove() end
end

hook.Add("OnScreenSizeChanged", "KMS_DownedScreen", RebuildDownedScreen)
hook.Add("KMS_ConfigUpdated", "KMS_DownedScreen", RebuildDownedScreen)

local function UpdatePulse(extraBand)
    local state = KMS.Self
    local rate = 0.6 + math.max(state.painBand or 0, (state.bloodClass or 1) - 1, state.bleedBand or 0, extraBand or 0) * 0.35
    pulsePhase = (pulsePhase + KF.Anim.GetFrameTime() * rate) % 1
    pulseWave = math.sin(pulsePhase * math.pi * 2)
    pulseWave = pulseWave * pulseWave
end

local painPhase = 0
local stamFlashAt = -10
local stamTierWas = 0

local function PainFlashEnvelope(band)
    painPhase = (painPhase + KF.Anim.GetFrameTime() / (2.4 - band * 0.4)) % 1
    local wave
    if painPhase < 0.15 then
        wave = 0.5 - 0.5 * math.cos(painPhase / 0.15 * math.pi)
    else
        wave = 0.5 + 0.5 * math.cos((painPhase - 0.15) / 0.85 * math.pi)
    end
    return 0.3 + 0.7 * wave
end

local PAIN_PEAK = { 40, 70, 105 }
local PAIN_DEPTH = { 0.11, 0.14, 0.17 }
local BLEED_BASE = { 50, 80, 115, 145 }
local BLEED_DEPTH = { 0.14, 0.19, 0.25, 0.3 }
local BLEED_ADD = { 0.03, 0.06, 0.1, 0.15 }
local BLEED_OVERLAY
if file.Exists("materials/medical_system/effects/blood_overlay.png", "GAME") then
    BLEED_OVERLAY = Material("medical_system/effects/blood_overlay.png", "smooth")
end

local function DrawPainEffects()
    local state = KMS.Self
    local ply = LocalPlayer()
    local hurt = math.Clamp((0.35 - ply:Health() / math.max(1, ply:GetMaxHealth())) / 0.25, 0, 1)
    UpdatePulse(math.ceil(hurt * 3))
    local mode = effectsModeConVar:GetInt()
    local scale = mode >= 2 and 0.5 or 1
    local throb = mode == 0 and pulseWave or 0.5
    local painBand = state.painBand or 0
    if painBand > 0 then
        local flash = mode == 0 and PainFlashEnvelope(painBand) or 0.45
        DrawVignette(PAIN_DEPTH[painBand], 255, 255, 255, PAIN_PEAK[painBand] * flash * scale)
    else
        painPhase = 0
    end
    local bleedBand = state.bleedBand or 0
    local redAlpha, redDepth = 0, 0
    if bleedBand > 0 then
        local bleedAlpha = BLEED_BASE[bleedBand] * (0.55 + 0.45 * throb)
        if BLEED_OVERLAY then
            local w, h = ScrW(), ScrH()
            local fade = math.abs(math.sin(CurTime() * math.pi / 3))
            surface.SetMaterial(BLEED_OVERLAY)
            surface.SetDrawColor(255, 255, 255, bleedAlpha * 1.4 * fade * scale)
            surface.DrawTexturedRect(0, 0, w, h)
            surface.SetDrawColor(255, 255, 255, bleedAlpha * 1.4 * (1 - fade) * scale)
            surface.DrawTexturedRectUV(0, 0, w, h, 1, 0, 0, 1)
        else
            redAlpha = bleedAlpha
            redDepth = BLEED_DEPTH[bleedBand]
        end
    end
    if hurt > 0 then
        redAlpha = math.max(redAlpha, hurt * 95 * (0.75 + 0.25 * throb))
        redDepth = math.max(redDepth, 0.13 + hurt * 0.07)
    end
    if redAlpha > 0 then
        DrawVignette(redDepth, 190, 18, 12, redAlpha * scale)
    end
    if KMS.Settings.staminaEnabled then
        local stamTier = ply:GetNWInt("kms_stam_tier", 0)
        if stamTier > stamTierWas and stamTier >= 1 then
            stamFlashAt = CurTime()
        end
        stamTierWas = stamTier
        local effort = math.Clamp((ply:GetNWFloat("kms_exhaust", 0) - 0.5) / 0.5, 0, 1)
        if effort > 0 or stamTier >= 1 then
            local strain = mode == 0 and (0.5 + 0.5 * math.sin(CurTime() * 1.4)) or 0.5
            local alpha = effort * (30 + 14 * stamTier) * (0.7 + 0.3 * strain)
            if stamTier >= 1 then
                alpha = math.max(alpha, 40 + 12 * stamTier)
            end
            if mode == 0 then
                alpha = alpha + 70 * math.max(0, 1 - (CurTime() - stamFlashAt) / 0.8)
            end
            DrawVignette(0.1 + 0.08 * effort, 25, 27, 32, alpha * scale)
        end
    end
    local bloodClass = state.bloodClass or 1
    if bloodClass >= 3 then
        DrawVignette(0.22, 0, 0, 0, (bloodClass - 2) * (45 + 55 * throb) * scale)
    end
end

local function DrawReleaseHint()
    if LocalPlayer():GetNWString("kms_hauling", "") == "" then return end
    if KMS.Treating and KMS.Treating.id == "haul_release" and CurTime() < KMS.Treating.endsAt then return end
    local label = L("hud_release")
    local font = KF.Fonts.GetBold(AID, "small")
    surface.SetFont(font)
    local textW = surface.GetTextSize(label)
    local iconW, iconH = Scale(15), Scale(22)
    local gap = Scale(8)
    local x = (ScrW() - iconW - gap - textW) / 2
    local y = ScrH() / 2 + Scale(46)
    local radius = math.max(3, math.Round(iconW / 3))
    draw.RoundedBox(radius, x - 1, y - 1, iconW + 2, iconH + 2, KF.UI.ColorAlpha(color_white, 210))
    draw.RoundedBox(radius, x + 1, y + 1, iconW - 2, iconH - 2, Color(24, 26, 30, 240))
    draw.RoundedBoxEx(radius, x + 1, y + 1, math.ceil(iconW / 2), math.ceil(iconH / 2), color_white, true, false, false, false)
    draw.SimpleTextOutlined(label, font, x + iconW + gap, y + iconH / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, KF.UI.ColorAlpha(color_black, 200))
end

local downedRange = CreateClientConVar("kms_downed_range", "1500", true, false)
local downedOutline = CreateClientConVar("kms_downed_outline", "1", true, false)
local downedCache = { at = 0 }

local function DownedTargets()
    if RealTime() - downedCache.at > 0.2 then
        downedCache.at = RealTime()
        downedCache.list = nil
        local ply = LocalPlayer()
        if KMS.Settings.enabled and KMS.Settings.downedIndicator and KMS.Settings.hudEnabled
            and (KMS.Settings.downedIndicatorAll or (KMS.Self.tier or 0) >= 1)
            and IsValid(ply) and ply:Alive() and not KMS.Exempt(ply) then
            local range = math.Clamp(downedRange:GetInt(), 250, 5000)
            local list = {}
            for _, other in ipairs(player.GetAll()) do
                if other ~= ply and not KMS.Exempt(other) and not KMS.Cloaked(other) then
                    local body = other:GetNWEntity("kms_ragdoll")
                    if IsValid(body) then
                        local callAt = other:GetNWFloat("kms_medcall", 0)
                        local called = KMS.Settings.medicCallEnabled and callAt > 0 and CurTime() - callAt < 60
                        if called or body:GetPos():Distance(ply:GetPos()) <= range then
                            list[#list + 1] = { ply = other, body = body, called = called }
                        end
                    end
                end
            end
            if list[1] then downedCache.list = list end
        end
    end
    return downedCache.list
end

local function DrawDownedMarkers()
    local targets = DownedTargets()
    if not targets then return end
    local myPos = LocalPlayer():GetPos()
    for _, target in ipairs(targets) do
        if IsValid(target.body) and IsValid(target.ply) then
            local pos = (target.body:GetPos() + Vector(0, 0, 20)):ToScreen()
            if pos.visible then
                local arrest = KMS.Settings.diagnosisMode ~= "examine" and target.ply:GetNWBool("kms_arrest", false)
                local triage = target.ply:GetNWInt("kms_triage", 0)
                local color = arrest and C("Error") or (target.called and C("Warning")) or (triage > 0 and KMS.TriageById[triage].color or C("TextPrimary"))
                local alpha = (arrest or target.called) and math.floor(170 + 85 * math.sin(CurTime() * 6)) or 220
                local tinted = KF.UI.ColorAlpha(color, alpha)
                local arm = Scale(6)
                local thick = math.max(2, Scale(2))
                surface.SetDrawColor(KF.UI.ColorAlpha(color_black, alpha * 0.6))
                surface.DrawRect(pos.x - thick / 2 + 1, pos.y - arm + 1, thick, arm * 2)
                surface.DrawRect(pos.x - arm + 1, pos.y - thick / 2 + 1, arm * 2, thick)
                surface.SetDrawColor(tinted)
                surface.DrawRect(pos.x - thick / 2, pos.y - arm, thick, arm * 2)
                surface.DrawRect(pos.x - arm, pos.y - thick / 2, arm * 2, thick)
                draw.SimpleTextOutlined(target.ply:Nick(), KF.Fonts.GetBold(AID, "small"), pos.x, pos.y + arm + Scale(2), tinted, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, KF.UI.ColorAlpha(color_black, alpha))
                local meters = math.Round(target.body:GetPos():Distance(myPos) / KMS.DisplayUnitsPerMeter)
                local status = (arrest and L("st_arrest") or target.called and L("hud_assist") or L("st_unconscious")) .. "  ·  " .. meters .. " m"
                draw.SimpleTextOutlined(status, KF.Fonts.Get(AID, "tiny"), pos.x, pos.y + arm + Scale(20), KF.UI.ColorAlpha(C("TextSecondary"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, KF.UI.ColorAlpha(color_black, alpha))
                local healer = target.ply:GetNWEntity("kms_treated_by")
                if IsValid(healer) then
                    draw.SimpleTextOutlined(L("hud_being_treated", KF.Integrations.GetPlayerName(healer) or healer:Nick()), KF.Fonts.Get(AID, "tiny"), pos.x, pos.y + arm + Scale(36), KF.UI.ColorAlpha(C("Success"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, KF.UI.ColorAlpha(color_black, alpha))
                end
            end
        end
    end
end

hook.Add("PreDrawHalos", "KMS_DownedHalos", function()
    if downedOutline:GetInt() == 0 then return end
    local targets = DownedTargets()
    if not targets then return end
    local hideArrest = KMS.Settings.diagnosisMode == "examine"
    local arrestBodies, downBodies = {}, {}
    for _, target in ipairs(targets) do
        if IsValid(target.body) and IsValid(target.ply) then
            local list = (not hideArrest and target.ply:GetNWBool("kms_arrest", false)) and arrestBodies or downBodies
            list[#list + 1] = target.body
        end
    end
    if arrestBodies[1] then halo.Add(arrestBodies, C("Error"), 2, 2, 1, true, true) end
    if downBodies[1] then halo.Add(downBodies, C("Warning"), 2, 2, 1, true, true) end
end)

hook.Add("PrePlayerDraw", "KMS_HideDowned", function(ply)
    if KMS.IsDowned(ply) then return true end
end)

hook.Add("HUDPaint", "KMS_HUD", function()
    if not KMS.Settings.enabled then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or KMS.Exempt(ply) then return end
    local state = KMS.Self
    if state.conscious == false then
        local t = CurTime() - unconSince
        local frac = DownedFade()
        if t > 4 then
            local cycle = (t - 4) % 17
            if cycle < 1.2 then
                frac = frac * (1 - 0.15 * math.sin(cycle / 1.2 * math.pi))
            end
        end
        DrawUnconsciousOverlay(frac)
        return
    end
    DrawPainEffects()
    if wakeAt > 0 then
        local since = CurTime() - wakeAt
        if since < 2 then
            DrawUnconsciousOverlay(1 - since / 2)
        end
    end
    DrawReleaseHint()
    if not KMS.Settings.hudEnabled then return end
    DrawStatusIndicators()
    DrawAlertsBlock()
    DrawDownedMarkers()
    DrawTriageBlock()
end)

local function Downed()
    return KMS.Settings.enabled and KMS.Self.conscious == false
end

local WEAPON_HUD = {
    CHudWeaponSelection = true, CHudAmmo = true, CHudSecondaryAmmo = true,
    CHudCrosshair = true, CHudDamageIndicator = true,
}

hook.Add("PreDrawViewModel", "KMS_HideViewModel", function()
    if Downed() then return true end
end)

hook.Add("HUDShouldDraw", "KMS_HideWeaponHUD", function(name)
    if WEAPON_HUD[name] and Downed() then return false end
end)

hook.Add("RenderScreenspaceEffects", "KMS_Effects", function()
    if not KMS.Settings.enabled then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local state = KMS.Self
    local painBand = state.painBand or 0
    if painBand >= 3 and state.conscious ~= false and effectsModeConVar:GetInt() == 0 then
        DrawMotionBlur(0.3, 0.04 * pulseWave, 0.01)
    end
    local bleedBand = state.bleedBand or 0
    local bloodClass = state.bloodClass or 1
    if bloodClass > 1 or bleedBand > 0 then
        local mode = effectsModeConVar:GetInt()
        local scale = mode >= 2 and 0.5 or 1
        local pulse = mode == 0 and math.abs(math.sin(CurTime() * 2)) or 0.5
        DrawColorModify({
            ["$pp_colour_addr"] = bleedBand > 0 and BLEED_ADD[bleedBand] * (0.35 + 0.65 * pulse) * scale or 0,
            ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = bloodClass >= 4 and -0.05 * scale or 0, ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1 - (bloodClass - 1) * 0.28 * scale,
            ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
        })
    end
end)

hook.Add("Think", "KMS_Heartbeat", function()
    if not KMS.Settings.enabled then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if effectsModeConVar:GetInt() >= 2 then return end
    local hr = KMS.Self.hr or 80
    if hr <= 0 or (hr >= KMS.HRNormalLow and hr <= KMS.HRNormalHigh) then return end
    if CurTime() < nextHeartbeat then return end
    nextHeartbeat = CurTime() + 60 / hr
    surface.PlaySound("player/heartbeat1.wav")
end)

KF.Net.Receive("KMS_NPCQuote", function()
    local ent = net.ReadEntity()
    local cost = net.ReadUInt(32)
    local healTime = net.ReadUInt(16)
    if not IsValid(ent) then return end
    KMS.UI.Confirm(L("npc_quote", KF.Integrations.FormatMoney(cost), KF.FormatTime(healTime)), function()
        if not IsValid(ent) then return end
        net.Start("KMS_NPCAccept")
        net.WriteEntity(ent)
        net.SendToServer()
    end)
end)

local limpPhase = 0
local limpAmp = 0

hook.Add("CalcView", "KMS_LimpShake", function(ply, pos, angles, fov)
    if not KMS.Settings.enabled then return end
    local target = 0
    if ply:GetNWInt("kms_mobility", 0) == 2 and ply:OnGround() and ply:GetVelocity():Length2D() > 20 then
        target = 1
    end
    limpAmp = KF.Anim.FastLerp(limpAmp, target, 5)
    if limpAmp < 0.01 then return end
    limpPhase = limpPhase + KF.Anim.GetFrameTime() * 5.5
    local wave = math.sin(limpPhase * math.pi)
    pos.z = pos.z - math.abs(wave) * 2.6 * limpAmp
    angles.r = angles.r + wave * 1.4 * limpAmp
end)

hook.Add("KMS_ConfigUpdated", "KMS_FirstRunPrompt", function()
    if not KMS.FirstRunClient then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    if KMS.FirstRunPrompted then return end
    KMS.FirstRunPrompted = true
    timer.Simple(3, function()
        if KMS.FirstRunClient and IsValid(LocalPlayer()) then
            KMS.OpenAdmin(true)
        end
    end)
end)

local strat = { active = false, sequence = {}, index = 1, flashAt = 0 }

local KEY_DIRS = {
    [KEY_UP] = 1, [KEY_DOWN] = 2, [KEY_LEFT] = 3, [KEY_RIGHT] = 4,
    [KEY_W] = 1, [KEY_S] = 2, [KEY_A] = 3, [KEY_D] = 4,
}

local ARROW_ANGLE = { [1] = -90, [2] = 90, [3] = 180, [4] = 0 }

KF.Net.Receive("KMS_Stratagem", function()
    local count = net.ReadUInt(5)
    if count == 0 then
        strat.active = false
        return
    end
    local sequence = {}
    for i = 1, count do
        sequence[i] = net.ReadUInt(3)
    end
    strat.sequence = sequence
    strat.index = 1
    strat.flashAt = 0
    strat.active = true
end)

function KMS.StratagemState()
    if not strat.active then return nil end
    if not KMS.Treating or CurTime() >= KMS.Treating.endsAt then
        strat.active = false
        return nil
    end
    return strat
end

local function DrawArrow(cx, cy, size, angle, color)
    local rad = math.rad(angle)
    local cos, sin = math.cos(rad), math.sin(rad)
    local function pt(px, py)
        return cx + (px * cos - py * sin), cy + (px * sin + py * cos)
    end
    local h = size * 0.5
    local x1, y1 = pt(h, 0)
    local x2, y2 = pt(-h, h)
    local x3, y3 = pt(-h * 0.35, 0)
    local x4, y4 = pt(-h, -h)
    surface.SetDrawColor(color)
    draw.NoTexture()
    surface.DrawPoly({ { x = x1, y = y1 }, { x = x2, y = y2 }, { x = x3, y = y3 }, { x = x4, y = y4 } })
end

function KMS.DrawStratagemRow(x, y, w, h, alpha)
    local state = KMS.StratagemState()
    if not state then return false end
    alpha = alpha or 255
    local n = #state.sequence
    local size = math.min(h * 0.7, (w / n) * 0.66)
    local gap = size * 0.45
    local total = n * size + (n - 1) * gap
    local cx = x + (w - total) / 2 + size / 2
    local cy = y + h / 2
    local flash = CurTime() < state.flashAt
    for i, dir in ipairs(state.sequence) do
        local color
        if i < state.index then
            color = C("Accent")
        elseif i == state.index then
            color = flash and C("Error") or C("TextPrimary")
        else
            color = C("TextDisabled")
        end
        local drawSize = i == state.index and size * 1.2 or size
        DrawArrow(cx + (i - 1) * (size + gap), cy, drawSize, ARROW_ANGLE[dir], KF.UI.ColorAlpha(color, alpha))
    end
    return true
end

hook.Add("PlayerButtonDown", "KMS_ReleaseHaul", function(ply, key)
    if not IsFirstTimePredicted() then return end
    if ply ~= LocalPlayer() or key ~= MOUSE_LEFT then return end
    if vgui.CursorVisible() or ply:GetNWString("kms_hauling", "") == "" then return end
    net.Start("KMS_Release")
    net.SendToServer()
end)

hook.Add("PlayerButtonDown", "KMS_StratagemInput", function(ply, key)
    if not IsFirstTimePredicted() then return end
    if ply ~= LocalPlayer() or not KMS.StratagemState() then return end
    local dir = KEY_DIRS[key]
    if not dir then return end
    net.Start("KMS_StratagemStep")
    net.WriteUInt(dir, 3)
    net.SendToServer()
    if dir == strat.sequence[strat.index] then
        strat.index = strat.index + 1
        if strat.index > #strat.sequence then
            strat.active = false
            KMS.PlaySound("Click")
        else
            KMS.PlaySound("Hover")
        end
    else
        strat.index = 1
        strat.flashAt = CurTime() + 0.25
        KMS.PlaySound("Error")
    end
end)

local MOVE_BUTTONS = bit.bnot(bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT, IN_JUMP))

hook.Add("CreateMove", "KMS_StratagemMove", function(cmd)
    -- Strivon: nur das alte 2D-Menü sperrt das Laufen, im Comlink kann man laufen wie bei Funk/Squad
    local menuOpen = KMS.UI and (KMS.UI.ClassicMenuPatient or KMS.UI.MenuPatient)
        and (KMS.UI.ClassicMenuPatient or KMS.UI.MenuPatient)() ~= nil
    if not menuOpen and not KMS.StratagemState() and not KMS.InteractActive() then return end
    cmd:SetForwardMove(0)
    cmd:SetSideMove(0)
    cmd:SetUpMove(0)
    cmd:SetButtons(bit.band(cmd:GetButtons(), MOVE_BUTTONS))
end)

local keyConVar = CreateClientConVar("kms_interact_key", "-1", true, false)

KMS.Interact = KMS.Interact or {
    active = false,
    patient = nil,
    selfMode = false,
    tree = nil,
    builtHauling = false,
    path = {},
    pendingPath = nil,
    pendingSince = 0,
    hoverNode = nil,
    lastHover = nil,
    anim = {},
    openedAt = 0,
    watched = {},
}
local interact = KMS.Interact
if interact.active then
    interact.active = false
    gui.EnableScreenClicker(false)
end

local HOVER_DWELL = 0.18

function KMS.InteractActive()
    return interact.active
end

function KMS.InteractPatient()
    return interact.active and interact.patient or nil
end

function KMS.InteractReassertWatch()
    if not interact.active then return end
    for occupant in pairs(interact.watched) do
        if IsValid(occupant) then KMS.SendWatch(occupant, true) end
    end
end

local function Snapshot()
    return interact.patient and KMS.PatientSnapshots[interact.patient] or nil
end

local function MenuPatient()
    return KMS.UI.MenuPatient and KMS.UI.MenuPatient() or nil
end

local function Ease(startedAt, duration)
    if startedAt <= 0 then return 0 end
    return KF.Anim.Ease(math.Clamp((CurTime() - startedAt) / duration, 0, 1), "ease_out")
end

local function IsHauling()
    return LocalPlayer():GetNWString("kms_hauling", "") ~= ""
end

local function CanHaulPatient(snapshot)
    return not interact.selfMode and IsValid(interact.patient) and interact.patient:IsPlayer()
        and snapshot ~= nil and snapshot.states ~= nil and not snapshot.states.conscious
end

local CATEGORY_ICONS = KMS.MenuIcons

function KMS.FindVehicleRoot()
    local ply = LocalPlayer()
    local own = KMS.VehicleBase(ply:GetVehicle())
    if own then return own end
    local origin = ply:GetPos()
    local maxDist = KMS.Settings.maxTreatDistance * KMS.ReachMargin
    local trace = ply:GetEyeTrace()
    local aimed = KMS.VehicleBase(trace.Entity)
    if aimed and trace.HitPos:Distance(origin) <= maxDist then return aimed end
    local best, bestDist
    for _, ent in ipairs(ents.FindInSphere(origin, maxDist)) do
        local root = KMS.VehicleBase(ent)
        if root then
            local dist = origin:DistToSqr(ent:GetPos())
            if not bestDist or dist < bestDist then
                best, bestDist = root, dist
            end
        end
    end
    return best
end

local function VehicleOccupants(root)
    local list = {}
    for _, other in ipairs(player.GetAll()) do
        if other ~= LocalPlayer() then
            local veh = other:GetVehicle()
            if (IsValid(veh) and KMS.VehicleBase(veh) == root) or other:GetNWEntity("kms_loaded_in") == root then
                list[#list + 1] = other
            end
        end
    end
    return list
end

local function TreatmentLeaf(def, partId, target)
    return { id = "treat_" .. def.id, label = KMS.ActionLabel(def), treat = def.id, partId = partId, target = target }
end

local ROUTE_GROUPS = { "inject", "infusion", "oral", "topical" }
local ROUTE_GROUP_MIN = 8

-- Long medication lists are split by how they are given so the radial stays readable.
local function GroupByRoute(leaves, cat, partId)
    local groups, count, loose = {}, 0, {}
    for _, leaf in ipairs(leaves) do
        local group = leaf.routeGroup
        if group then
            if not groups[group] then
                groups[group] = {}
                count = count + 1
            end
            table.insert(groups[group], leaf)
        else
            loose[#loose + 1] = leaf
        end
    end
    if count < 2 then return leaves end
    local out = {}
    for _, group in ipairs(ROUTE_GROUPS) do
        local list = groups[group]
        if list then
            out[#out + 1] = #list == 1 and list[1]
                or { id = "route_" .. cat .. "_" .. group .. "_" .. partId, label = L("route_grp_" .. group), icon = CATEGORY_ICONS[cat], children = list }
        end
    end
    for _, leaf in ipairs(loose) do
        out[#out + 1] = leaf
    end
    return out
end

local function CategoryNodes(partId, target, snapshot)
    target = target or interact.patient
    if snapshot == nil and target == interact.patient then snapshot = Snapshot() end
    if not snapshot then return {} end
    local byCat = {}
    for _, def in ipairs(KMS.Treatments) do
        if def.cat ~= "triage" and KMS.CanShowTreatment(def) and KMS.TreatmentAvailable(def, snapshot, partId)
            and not KMS.LacksItem(def, snapshot) then
            local leaf = TreatmentLeaf(def, partId, target)
            leaf.blocked = KMS.TreatmentBlockReason(def, snapshot, target, partId)
            leaf.routeGroup = def.routeGroup
            byCat[def.cat] = byCat[def.cat] or {}
            byCat[def.cat][#byCat[def.cat] + 1] = leaf
        end
    end
    local nodes = {}
    for _, cat in ipairs(KMS.Categories) do
        local leaves = byCat[cat]
        if leaves then
            if #leaves == 1 then
                nodes[#nodes + 1] = leaves[1]
            else
                if #leaves > ROUTE_GROUP_MIN then leaves = GroupByRoute(leaves, cat, partId) end
                nodes[#nodes + 1] = { id = "cat_" .. cat .. "_" .. partId, label = L("cat_" .. cat), icon = CATEGORY_ICONS[cat], children = leaves }
            end
        end
    end
    return nodes
end

local function OccupantMedicalNode(occupant)
    local snapshot = KMS.PatientSnapshots[occupant]
    local parts = {}
    for _, part in ipairs(KMS.Parts) do
        parts[#parts + 1] = {
            id = "opart_" .. occupant:EntIndex() .. "_" .. part.id,
            label = KMS.PartLabel(part.id),
            partId = part.id,
            target = occupant,
            children = CategoryNodes(part.id, occupant, snapshot),
        }
    end
    return { id = "omed_" .. occupant:EntIndex(), label = L("int_medical"), cross = true, children = parts }
end

local vehicleNames

function KMS.VehicleDisplayName(root)
    if isstring(root.PrintName) and root.PrintName ~= "" and root.PrintName ~= "Base" then
        return root.PrintName
    end
    if not vehicleNames then
        vehicleNames = {}
        for name, row in pairs(list.Get("Vehicles") or {}) do
            if istable(row) and isstring(row.Class) then
                vehicleNames[string.lower(row.Class)] = row.Name or name
            end
        end
        for key, row in pairs(list.Get("simfphys_vehicles") or {}) do
            if istable(row) and isstring(row.Class) then
                vehicleNames[string.lower(row.Class)] = row.Name or key
            end
        end
    end
    return vehicleNames[string.lower(root:GetClass())] or root:GetClass()
end

local function VehicleNode(root)
    local isMed = KMS.IsMedVehicle(root)
    local people = {}
    for _, occupant in ipairs(VehicleOccupants(root)) do
        if occupant ~= interact.patient and not interact.watched[occupant] then
            interact.watched[occupant] = true
            KMS.SendWatch(occupant, true)
        end
        local actions = {}
        if occupant:GetNWEntity("kms_loaded_in") == root then
            actions[#actions + 1] = { id = "unload_" .. occupant:EntIndex(), label = L("int_unload_vehicle"), icon = CATEGORY_ICONS.drag, unload = occupant }
        end
        actions[#actions + 1] = OccupantMedicalNode(occupant)
        actions[#actions + 1] = { id = "omenu_" .. occupant:EntIndex(), label = L("int_open_menu"), cross = true, menuTarget = occupant }
        people[#people + 1] = {
            id = "occ_" .. occupant:EntIndex(),
            label = KF.Integrations.GetPlayerName(occupant) or occupant:Nick(),
            children = actions,
        }
    end
    for _, other in ipairs(player.GetAll()) do
        if other ~= LocalPlayer() and IsValid(other:GetNWEntity("kms_ragdoll")) and not IsValid(other:GetNWEntity("kms_loaded_in")) then
            local body = KMS.PatientDisplayEnt(other)
            if root:NearestPoint(body:GetPos()):Distance(body:GetPos()) <= KMS.Settings.maxTreatDistance * KMS.ReachMargin then
                people[#people + 1] = {
                    id = "occ_" .. other:EntIndex(),
                    label = KF.Integrations.GetPlayerName(other) or other:Nick(),
                    children = {
                        { id = "loadact_" .. other:EntIndex(), label = L("int_load_vehicle"), load = other },
                    },
                }
            end
        end
    end
    local children = {
        { id = "veh_occ", label = L("int_vehicle"), children = people },
    }
    if isMed and KMS.VehInvAccess(LocalPlayer()) and KMS.Settings.itemSharing and not KMS.Settings.infiniteSupplies then
        children[#children + 1] = { id = "vehinv", label = L("int_veh_inventory"), icon = CATEGORY_ICONS.inventory, vehinv = true }
    end
    return {
        id = "vehicle",
        vehAnchor = true,
        label = isMed and (KMS.VehicleDisplayName(root) .. "  -  " .. L("int_med_vehicle")) or KMS.VehicleDisplayName(root),
        color = isMed and C("Success") or nil,
        children = children,
    }
end

local function TriageNodes()
    local nodes = {}
    for _, level in ipairs(KMS.TriageLevels) do
        if level.id ~= 4 then
            nodes[#nodes + 1] = { id = "triage_" .. level.id, label = L(level.key), color = level.color, triage = level.id }
        end
    end
    return nodes
end

local function PartNodes()
    local nodes = {}
    for _, part in ipairs(KMS.Parts) do
        nodes[#nodes + 1] = { id = "part_" .. part.id, label = KMS.PartLabel(part.id), partId = part.id, bone = part.bone, children = CategoryNodes(part.id) }
    end
    return nodes
end

local function UtilityNodes()
    local nodes = {}
    if CanHaulPatient(Snapshot()) and not IsValid(interact.patient:GetNWEntity("kms_loaded_in")) then
        nodes[#nodes + 1] = { id = "drag", label = L("int_drag"), icon = CATEGORY_ICONS.drag, haul = "drag" }
        nodes[#nodes + 1] = { id = "carry", label = L("int_carry"), icon = CATEGORY_ICONS.drag, haul = "carry" }
    end
    nodes[#nodes + 1] = { id = "triage", label = L("cat_triage"), icon = CATEGORY_ICONS.triage, children = TriageNodes() }
    if KMS.Settings.medbayEnabled and (KMS.Self.tier or 0) >= 1 then
        nodes[#nodes + 1] = { id = "medbay", label = L("int_deploy_medbay"), cross = true, deploy = true }
    end
    nodes[#nodes + 1] = { id = "menu", label = L("int_open_menu"), cross = true, menu = true }
    return nodes
end

local function LinkParents(nodes, parent)
    for _, node in ipairs(nodes) do
        node.parent = parent
        if node.children then LinkParents(node.children, node) end
    end
end

local function BuildTree()
    local ply = LocalPlayer()
    local roots
    if interact.selfMode then
        interact.vehicleRoot = KMS.FindVehicleRoot()
        local children = { { id = "medical", label = L("int_medical"), cross = true, medical = true, children = PartNodes() } }
        for _, node in ipairs(UtilityNodes()) do
            children[#children + 1] = node
        end
        roots = { { id = "self", label = L("int_self"), children = children } }
        if IsValid(interact.vehicleRoot)
            and (KMS.VehicleBase(ply:GetVehicle()) == interact.vehicleRoot or KMS.ClearSight(ply, interact.vehicleRoot)) then
            roots[#roots + 1] = VehicleNode(interact.vehicleRoot)
        end
    else
        roots = PartNodes()
        local vehRoot = KMS.FindVehicleRoot()
        local loadedIn = interact.patient:GetNWEntity("kms_loaded_in")
        if not IsValid(vehRoot) and IsValid(loadedIn) then vehRoot = loadedIn end
        interact.vehicleRoot = vehRoot
        if IsValid(vehRoot)
            and (KMS.VehicleBase(ply:GetVehicle()) == vehRoot or KMS.ClearSight(ply, vehRoot)) then
            roots[#roots + 1] = VehicleNode(vehRoot)
        end
        roots[#roots + 1] = { id = "interactions", label = L("int_interactions"), icon = CATEGORY_ICONS.interactions, children = UtilityNodes() }
    end
    LinkParents(roots, nil)
    interact.tree = roots
    interact.builtHauling = IsHauling()
end

local function Deactivate()
    if not interact.active then return end
    interact.active = false
    gui.EnableScreenClicker(false)
    local patient = interact.patient
    local menuPatient = MenuPatient()
    if IsValid(patient) and patient ~= menuPatient then
        KMS.SendWatch(patient, false)
    end
    for target in pairs(interact.watched) do
        if IsValid(target) and target ~= menuPatient and target ~= patient then
            KMS.SendWatch(target, false)
        end
    end
    interact.watched = {}
    interact.patient = nil
    interact.tree = nil
    interact.path = {}
    interact.pendingPath = nil
    interact.hoverNode = nil
    interact.lastHover = nil
    interact.anim = {}
    interact.hoverActive = 0
    interact.lastHoverDepth = nil
end

local function ValidTarget(ply, patient)
    if not IsValid(patient) then return false end
    if patient:IsPlayer() and not patient:Alive() then return false end
    if KMS.SameVehicle(ply, patient) then return true end
    return KMS.PatientDisplayEnt(patient):GetPos():Distance(ply:GetPos()) <= KMS.Settings.maxTreatDistance * KMS.WatchMargin
end

local function Activate()
    local ply = LocalPlayer()
    if vgui.CursorVisible() then return end
    if not KF.Integrations.PlayerInWorld(ply) then return end
    if CurTime() < (interact.nextTry or 0) then return end
    local patient = KMS.FindPatient()
    if not ValidTarget(ply, patient) then
        interact.nextTry = CurTime() + 0.25
        return
    end
    interact.nextTry = 0
    interact.patient = patient
    interact.selfMode = patient == ply
    interact.active = true
    interact.watched = {}
    interact.path = {}
    interact.pendingPath = nil
    interact.hoverNode = nil
    interact.lastHover = nil
    interact.anim = {}
    interact.hoverActive = 0
    interact.lastHoverDepth = nil
    interact.losFade = 1
    interact.openedAt = CurTime()
    interact.nextRefresh = CurTime() + 0.5
    BuildTree()
    gui.EnableScreenClicker(true)
    KMS.SendWatch(interact.patient, true)
    KMS.PlaySound("Open")
end

hook.Add("Think", "KMS_InteractKey", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local enabled = KMS.Settings.enabled and KMS.Settings.interactEnabled
        and ply:Alive() and KMS.Self.conscious ~= false and not KMS.Exempt(ply)
    local interactKey = KMS.BindKey(keyConVar, "keyInteract")
    local keyDown = enabled and interactKey > 0 and input.IsKeyDown(interactKey)
    if keyDown and not interact.active then
        Activate()
    elseif interact.active then
        if not keyDown or not ValidTarget(ply, interact.patient) then
            Deactivate()
        elseif CurTime() >= (interact.nextRefresh or 0) then
            interact.nextRefresh = CurTime() + 0.5
            BuildTree()
        end
    end
end)

local function OutwardDir(x)
    return (ScrW() - x) >= x and 1 or -1
end

local function VehicleAnchor(fallbackX, fallbackY)
    local root = interact.vehicleRoot
    if not IsValid(root) then return nil end
    local pos = root:WorldSpaceCenter():ToScreen()
    if pos.visible then
        return { x = pos.x, y = pos.y }
    end
    if KMS.VehicleBase(LocalPlayer():GetVehicle()) == root then
        return { x = fallbackX, y = fallbackY }
    end
    return nil
end

local function LayoutRoots()
    local list = {}
    local anchorX = ScrW() / 2
    if interact.selfMode then
        local cx, cy = ScrW() / 2, ScrH() * 0.6
        local vehIndex, vehPos = 0, nil
        for _, node in ipairs(interact.tree) do
            if node.vehAnchor then
                if not vehPos then
                    vehPos = VehicleAnchor(cx, cy - Scale(200))
                end
                if vehPos then
                    list[#list + 1] = { node = node, x = vehPos.x, y = vehPos.y + vehIndex * Scale(34), dirX = OutwardDir(vehPos.x), dirY = 0.25 }
                    vehIndex = vehIndex + 1
                end
            else
                list[#list + 1] = { node = node, x = cx, y = cy, dirX = 0, dirY = -1 }
            end
        end
        return list
    end
    local displayEnt = KMS.PatientDisplayEnt(interact.patient)
    local positions = {}
    for _, node in ipairs(interact.tree) do
        if node.bone then
            local pos
            local boneIndex = displayEnt:LookupBone(node.bone)
            if boneIndex then
                local matrix = displayEnt:GetBoneMatrix(boneIndex)
                pos = matrix and matrix:GetTranslation()
            end
            if not pos and node.partId == "torso" then
                pos = displayEnt:WorldSpaceCenter()
            end
            if pos then
                local screen = pos:ToScreen()
                if screen.visible then
                    positions[node.id] = screen
                    if node.partId == "torso" then anchorX = screen.x end
                end
            end
        end
    end
    local torso = positions.part_torso
    local baseX = torso and torso.x or ScrW() / 2
    local baseY = torso and (torso.y + Scale(120)) or ScrH() * 0.62
    local utilX, utilY, utilDirX, utilDirY = baseX, baseY, OutwardDir(baseX), 0.45
    local pelvisIndex = displayEnt:LookupBone("ValveBiped.Bip01_Pelvis")
    if pelvisIndex then
        local matrix = displayEnt:GetBoneMatrix(pelvisIndex)
        local pos = matrix and matrix:GetTranslation()
        local screen = pos and pos:ToScreen()
        if screen and screen.visible then
            utilX, utilY = screen.x, screen.y
            if torso then
                local dx, dy = screen.x - torso.x, screen.y - torso.y
                local len = math.sqrt(dx * dx + dy * dy)
                if len > 1 then
                    utilDirX, utilDirY = dx / len, dy / len
                end
            end
        end
    end
    local vehIndex, vehPos = 0, nil
    for _, node in ipairs(interact.tree) do
        if node.bone then
            local pos = positions[node.id]
            if pos then
                local dirX, dirY = 0, 0
                if node.partId == "head" then
                    dirY = -1
                elseif node.partId == "torso" then
                    dirX = OutwardDir(pos.x)
                else
                    local dx = pos.x - anchorX
                    dirX = math.abs(dx) < 1 and OutwardDir(pos.x) or (dx > 0 and 1 or -1)
                end
                list[#list + 1] = { node = node, x = pos.x, y = pos.y, dirX = dirX, dirY = dirY }
            end
        elseif node.vehAnchor then
            if not vehPos then
                vehPos = VehicleAnchor(baseX, baseY + Scale(30))
            end
            if vehPos then
                list[#list + 1] = { node = node, x = vehPos.x, y = vehPos.y + vehIndex * Scale(34), dirX = OutwardDir(vehPos.x), dirY = 0.25 }
                vehIndex = vehIndex + 1
            end
        elseif node.id == "interactions" then
            list[#list + 1] = { node = node, x = utilX, y = utilY, dirX = OutwardDir(utilX), dirY = 0 }
        end
    end
    return list
end

local function LayoutVisible()
    local labelFont = KF.Fonts.Get(AID, "small")
    local visible = LayoutRoots()
    for _, item in ipairs(visible) do
        item.pinKey = item.node.id
        if item.node.vehAnchor then
            item.listMode = true
            item.colDir = OutwardDir(item.x)
        end
    end
    local pathItems = {}
    local levelItems = visible
    for _, id in ipairs(interact.path) do
        local found
        for _, item in ipairs(levelItems) do
            if item.node.id == id then
                found = item
                break
            end
        end
        if not found then break end
        pathItems[#pathItems + 1] = found
        local children = found.node.children
        if not children or #children == 0 then break end
        local childItems = {}
        local n = #children
        if found.listMode then
            local colDir = found.colDir
            local colX = math.Clamp(found.x + colDir * Scale(150), Scale(70), ScrW() - Scale(70))
            local rowH = Scale(34)
            local topY = found.y - (n - 1) * rowH * 0.5
            for i, child in ipairs(children) do
                local item = {
                    node = child,
                    pinKey = found.pinKey .. "/" .. child.id,
                    x = colX,
                    y = math.Clamp(topY + (i - 1) * rowH, Scale(40), ScrH() - Scale(70)),
                    dirX = colDir,
                    dirY = 0,
                    listMode = true,
                    colDir = colDir,
                }
                visible[#visible + 1] = item
                childItems[#childItems + 1] = item
            end
        else
            local baseAngle = math.atan2(found.dirY, found.dirX)
            local spread = math.min(math.rad(30) * (n - 1), math.rad(160))
            local radius = Scale(120) + n * Scale(8)
            for i, child in ipairs(children) do
                local frac = n == 1 and 0.5 or (i - 1) / (n - 1)
                local ang = baseAngle + (frac - 0.5) * spread
                local item = {
                    node = child,
                    pinKey = found.pinKey .. "/" .. child.id,
                    x = math.Clamp(found.x + math.cos(ang) * radius, Scale(70), ScrW() - Scale(70)),
                    y = math.Clamp(found.y + math.sin(ang) * radius, Scale(40), ScrH() - Scale(70)),
                    dirX = math.cos(ang),
                    dirY = math.sin(ang),
                }
                visible[#visible + 1] = item
                childItems[#childItems + 1] = item
            end
        end
        levelItems = childItems
    end
    surface.SetFont(labelFont)
    for _, item in ipairs(visible) do
        item.textW = surface.GetTextSize(item.node.label)
    end
    return visible, pathItems
end

local function DrawCross(x, y, r, color)
    local th = math.max(2, math.Round(r * 0.66))
    surface.SetDrawColor(color)
    surface.DrawRect(x - th / 2, y - r, th, r * 2)
    surface.DrawRect(x - r, y - th / 2, r * 2, th)
end

local function NodeColor(node, hovered)
    if node.partId and not node.treat then
        local snapshot = node.target and KMS.PatientSnapshots[node.target] or (not node.target and Snapshot())
        return KMS.PartStateColor(snapshot and snapshot.parts and snapshot.parts[node.partId])
    end
    if node.cross then return color_white end
    if node.icon then return KF.UI.LerpColor(hovered, color_white, C("TextAccent")) end
    return node.color or color_white
end

local function DrawNodeIcon(node, x, y, grow, color)
    if (node.partId and not node.treat) or node.cross then
        DrawCross(x, y, Scale(9) * grow, color)
    elseif node.icon then
        local r = Scale(11) * grow
        KMS.DrawIcon(node.icon, x - r, y - r, r * 2, r * 2, color)
    else
        local r = Scale(5) * grow
        draw.RoundedBox(r, x - r, y - r, r * 2, r * 2, color)
    end
end

local function DrawHoverRing(x, y, r, frac)
    if frac <= 0.01 then return end
    surface.SetDrawColor(225, 45, 35, math.floor(255 * frac))
    local spin = CurTime() * 90 % 360
    local rr = r * (0.7 + 0.3 * frac)
    for i = 0, 11 do
        local a1 = math.rad(i * 30 + spin)
        local a2 = a1 + math.rad(19)
        surface.DrawLine(x + math.cos(a1) * rr, y + math.sin(a1) * rr, x + math.cos(a2) * rr, y + math.sin(a2) * rr)
    end
end

local function DrawNode(item, alpha, hovered, labelFont)
    if alpha <= 0.004 then return end
    local node = item.node
    if node.blocked then alpha = alpha * 0.7 end
    local grow = 1 + 0.35 * hovered
    local fade = math.floor(255 * alpha)
    local width = math.max(2, math.Round(Scale(2)))
    local outline = KF.UI.ColorAlpha(color_black, fade)
    for _, dir in ipairs(OUTLINE_DIRS) do
        DrawNodeIcon(node, item.x + dir[1] * width, item.y + dir[2] * width, grow, outline)
    end
    DrawNodeIcon(node, item.x, item.y, grow, KF.UI.ColorAlpha(NodeColor(node, hovered), fade))
    local labelColor = KF.UI.LerpColor(hovered, node.color or C("TextPrimary"), C("TextAccent"))
    local labelX, labelY, align = item.x, item.y + Scale(15), TEXT_ALIGN_CENTER
    if item.listMode then
        local dir = item.colDir or 1
        labelX = item.x + Scale(16) * dir
        labelY = item.y - Scale(7)
        align = dir >= 0 and TEXT_ALIGN_LEFT or TEXT_ALIGN_RIGHT
    end
    draw.SimpleTextOutlined(node.label, labelFont, labelX, labelY, KF.UI.ColorAlpha(labelColor, fade),
        align, TEXT_ALIGN_TOP, width, outline)
    if node.blocked and hovered > 0.5 then
        draw.SimpleTextOutlined(node.blocked, KF.Fonts.Get(AID, "tiny"), labelX, labelY + Scale(17),
            KF.UI.ColorAlpha(KMS.StatusColors.warning, fade), align, TEXT_ALIGN_TOP, width, outline)
    end
end

local infoSnapshot

local function InfoPartState(partId)
    local parts = infoSnapshot and infoSnapshot.parts
    return parts and parts[partId]
end

function KMS.SnapshotBleeding(snapshot)
    for _, partState in pairs(snapshot and snapshot.parts or {}) do
        if KMS.PartHasBleedingWound(partState) then return true end
    end
    return false
end

local function DrawPatientInfo(partId, alpha)
    local snapshot = Snapshot()
    if not snapshot then return end
    infoSnapshot = snapshot
    local smallFont = KF.Fonts.Get(AID, "small")
    local boldFont = KF.Fonts.GetBold(AID, "small")
    local tinyFont = KF.Fonts.Get(AID, "tiny")
    local x = Scale(20)
    local y = ScrH() * 0.08
    local w = Scale(250)
    local bodySize = Scale(180)
    KMS.DrawBodyImage(x - bodySize * 0.3, y, bodySize, InfoPartState, nil, partId)
    local yy = y + bodySize + Scale(6)
    surface.SetDrawColor(KF.UI.ColorAlpha(C("Accent"), math.floor(235 * alpha)))
    surface.DrawRect(x, yy, w, Scale(20))
    draw.SimpleText(L("hud_injuries"), boldFont, x + Scale(8), yy + Scale(10), KF.UI.ColorAlpha(Color(18, 18, 18), math.floor(255 * alpha)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(interact.selfMode and L("ui_self") or KMS.PatientName(interact.patient), tinyFont, x + w - Scale(8), yy + Scale(10), KF.UI.ColorAlpha(Color(18, 18, 18), math.floor(255 * alpha)), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    yy = yy + Scale(22)
    local states = snapshot.states or {}
    local lines = {}
    if KMS.SnapshotBleeding(snapshot) then
        lines[#lines + 1] = { text = L("int_bleeding"), color = KMS.StatusColors.critical }
    else
        lines[#lines + 1] = { text = L("int_no_bleeding"), color = C("TextMuted") }
    end
    local bloodClass = states.bloodClass or 1
    if bloodClass > 1 then
        lines[#lines + 1] = KMS.BloodClassLine(bloodClass)
    else
        lines[#lines + 1] = { text = L("int_no_bloodloss"), color = C("TextMuted") }
    end
    local ivLines = KMS.IVLines(states)
    if #ivLines > 0 then
        for _, line in ipairs(ivLines) do
            lines[#lines + 1] = line
        end
    else
        lines[#lines + 1] = { text = L("int_no_iv"), color = C("TextMuted") }
    end
    local painBand = states.painBand or 0
    if painBand > 0 then
        lines[#lines + 1] = KMS.PainLine(painBand)
    else
        lines[#lines + 1] = { text = L("int_no_pain"), color = C("TextMuted") }
    end
    if partId then
        lines[#lines + 1] = { text = "" }
        lines[#lines + 1] = { text = KMS.PartLabel(partId), color = C("TextPrimary"), bold = true }
        local partLines = KMS.PartLines(InfoPartState(partId), partId)
        if #partLines == 0 then
            lines[#lines + 1] = { text = L("ov_no_injuries"), color = C("TextMuted") }
        else
            for _, line in ipairs(partLines) do
                lines[#lines + 1] = line
            end
        end
    end
    local lineH = Scale(17)
    local textX = x + Scale(8)
    local wrapW = w - Scale(16)
    local wrapped = {}
    for _, line in ipairs(lines) do
        local font = line.bold and boldFont or smallFont
        if line.text == "" then
            wrapped[#wrapped + 1] = { text = "", font = font }
        else
            surface.SetFont(font)
            for _, piece in ipairs(KF.WrapText(line.text, font, wrapW)) do
                wrapped[#wrapped + 1] = { text = piece, font = font, color = line.color }
            end
        end
    end
    local listH = #wrapped * lineH + Scale(10)
    surface.SetDrawColor(8, 8, 10, math.floor(150 * alpha))
    surface.DrawRect(x, yy, w, listH)
    for i, line in ipairs(wrapped) do
        draw.SimpleText(line.text, line.font, textX, yy + Scale(5) + (i - 1) * lineH, KF.UI.ColorAlpha(line.color or C("TextSecondary"), math.floor(255 * alpha)))
    end
    yy = yy + listH + Scale(4)
    local triage = KMS.TriageById[states.triage or 0]
    surface.SetDrawColor(10, 10, 12, math.floor(225 * alpha))
    surface.DrawRect(x, yy, w, Scale(18))
    draw.SimpleText(L(triage.key), boldFont, x + Scale(8), yy + Scale(9), KF.UI.ColorAlpha(triage.id == 0 and C("TextSecondary") or triage.color, math.floor(255 * alpha)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    yy = yy + Scale(24)
    for i = 1, math.min(4, #(snapshot.log or {})) do
        draw.SimpleText(KMS.Ellipsize(KMS.FormatEntry(snapshot.log[i]), tinyFont, wrapW), tinyFont, textX, yy, KF.UI.ColorAlpha(C("TextSecondary"), math.floor(255 * alpha)))
        yy = yy + Scale(15)
    end
end

local function SamePath(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end

local function IsPrefix(prefix, full)
    if #prefix > #full then return false end
    for i = 1, #prefix do
        if prefix[i] ~= full[i] then return false end
    end
    return true
end

local function SetPath(chain)
    interact.path = chain
    interact.pendingPath = nil
end

hook.Add("HUDPaint", "KMS_InteractDraw", function()
    if not interact.active or not IsValid(interact.patient) then return end
    if interact.builtHauling ~= IsHauling() then BuildTree() end
    local ply = LocalPlayer()
    local displayEnt = KMS.PatientDisplayEnt(interact.patient)
    local maxDist = KMS.Settings.maxTreatDistance
    local sameVeh = not interact.selfMode and KMS.SameVehicle(ply, interact.patient)
    local dist = displayEnt:GetPos():Distance(ply:GetPos())
    local distFade = sameVeh and 1 or (1 - math.Clamp((dist - maxDist) / maxDist, 0, 1))
    local clear = interact.selfMode or sameVeh or KMS.ClearSight(ply, displayEnt)
    interact.losFade = KF.Anim.FastLerp(interact.losFade or 1, clear and 1 or 0, 6)
    local globalAlpha = Ease(interact.openedAt, 0.18) * distFade * interact.losFade
    if globalAlpha < 0.02 and (not clear or distFade <= 0) then
        Deactivate()
        return
    end
    local smallFont = KF.Fonts.Get(AID, "small")
    local visible, pathItems = LayoutVisible()
    if #pathItems < #interact.path then
        for i = #interact.path, #pathItems + 1, -1 do
            table.remove(interact.path, i)
        end
    end

    local activeParent = pathItems[#pathItems] and pathItems[#pathItems].node or nil
    local onPath = {}
    for _, item in ipairs(pathItems) do
        onPath[item.node] = true
    end

    local mx, my = gui.MousePos()
    local hoverItem, hoverDist
    for _, item in ipairs(visible) do
        local d = math.Distance(mx, my, item.x, item.y)
        local hit = d <= Scale(26)
        if not hit and item.listMode then
            local off = Scale(16)
            local x1, x2
            if (item.colDir or 1) >= 0 then
                x1, x2 = item.x + off, item.x + off + item.textW
            else
                x1, x2 = item.x - off - item.textW, item.x - off
            end
            hit = mx >= x1 and mx <= x2 and math.abs(my - item.y) <= Scale(12)
        elseif not hit then
            hit = math.abs(mx - item.x) <= item.textW / 2 + Scale(4) and my >= item.y + Scale(14) and my <= item.y + Scale(34)
        end
        if hit then
            local dist = d * ((onPath[item.node] or item.node.parent == activeParent) and 0.7 or 1)
            if not hoverDist or dist < hoverDist then
                hoverItem, hoverDist = item, dist
            end
        end
    end
    interact.hoverNode = hoverItem and hoverItem.node or nil
    local hoverKey = hoverItem and hoverItem.pinKey or nil
    if hoverKey and interact.lastHover ~= hoverKey then
        KMS.PlaySound("Hover")
    end
    interact.lastHover = hoverKey

    if hoverItem then
        local chain = {}
        local node = hoverItem.node
        while node do
            table.insert(chain, 1, node.id)
            node = node.parent
        end
        if not hoverItem.node.children then
            table.remove(chain)
        end
        if SamePath(chain, interact.path) then
            interact.pendingPath = nil
        elseif IsPrefix(interact.path, chain) then
            SetPath(chain)
        elseif interact.pendingPath and SamePath(chain, interact.pendingPath) then
            if CurTime() - interact.pendingSince >= HOVER_DWELL then
                SetPath(chain)
            end
        else
            interact.pendingPath = chain
            interact.pendingSince = CurTime()
        end
    else
        interact.pendingPath = nil
    end

    local lastDepth = #pathItems
    local function NodeDepth(node)
        local depth = 0
        node = node.parent
        while node do
            depth = depth + 1
            node = node.parent
        end
        return depth
    end
    local hoverDepth = hoverItem and NodeDepth(hoverItem.node) or interact.lastHoverDepth
    interact.lastHoverDepth = hoverDepth
    interact.hoverActive = KF.Anim.FastLerp(interact.hoverActive or 0, hoverItem and 1 or 0, 10)
    local seen = {}
    for _, item in ipairs(visible) do
        local depth = NodeDepth(item.node)
        local isHover = item == hoverItem
        local isOnPath = onPath[item.node]
        local base
        if isOnPath then
            base = 1
        elseif depth == lastDepth then
            base = 1
        elseif depth == lastDepth - 1 then
            base = 0.5
        else
            base = 0.3
        end
        if hoverDepth and depth == hoverDepth and not isHover and not isOnPath then
            base = base * (1 - 0.6 * interact.hoverActive)
        end
        local key = item.pinKey
        seen[key] = true
        local anim = interact.anim[key] or { alpha = 0, hover = 0 }
        anim.alpha = KF.Anim.FastLerp(anim.alpha, base, 14)
        anim.hover = KF.Anim.FastLerp(anim.hover, isHover and 1 or 0, 16)
        interact.anim[key] = anim
        item.animAlpha = anim.alpha * globalAlpha
        item.animHover = anim.hover
    end
    for key in pairs(interact.anim) do
        if not seen[key] then interact.anim[key] = nil end
    end
    for _, item in ipairs(visible) do
        if item ~= hoverItem then
            DrawNode(item, item.animAlpha, item.animHover, smallFont)
            DrawHoverRing(item.x, item.y, Scale(16), item.animHover * item.animAlpha)
        end
    end
    if hoverItem then
        DrawNode(hoverItem, hoverItem.animAlpha, hoverItem.animHover, smallFont)
        DrawHoverRing(hoverItem.x, hoverItem.y, Scale(16), hoverItem.animHover * globalAlpha)
    end

    local infoPart
    local showInfo = not interact.selfMode and lastDepth > 0
    for _, item in ipairs(pathItems) do
        if item.node.partId then infoPart = item.node.partId end
        if item.node.medical then showInfo = true end
    end
    if infoPart then showInfo = true end
    if showInfo then
        DrawPatientInfo(infoPart, globalAlpha)
    end

    local keyName = string.upper(input.GetKeyName(KMS.BindKey(keyConVar, "keyInteract")) or "ALT")
    draw.SimpleText(L("int_hint", keyName), smallFont, ScrW() / 2, ScrH() - Scale(48), KF.UI.ColorAlpha(C("TextSecondary"), math.floor(255 * globalAlpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("GUIMousePressed", "KMS_InteractClick", function(mouseCode)
    if not interact.active then return end
    if mouseCode == MOUSE_RIGHT then
        if #interact.path > 0 then
            table.remove(interact.path)
            interact.pendingPath = nil
            KMS.PlaySound("Click")
        end
        return
    end
    if mouseCode ~= MOUSE_LEFT then return end
    local node = interact.hoverNode
    if not node or node.children then return end
    if node.menu then
        local patient = interact.patient
        KMS.PlaySound("Click")
        KMS.OpenMenuOn(patient)
        Deactivate()
    elseif node.menuTarget then
        local target = node.menuTarget
        if IsValid(target) then
            KMS.PlaySound("Click")
            KMS.OpenMenuOn(target)
            Deactivate()
        end
    elseif node.load then
        KMS.PlaySound("Click")
        net.Start("KMS_VehicleLoad")
        net.WriteEntity(node.load)
        net.WriteEntity(interact.vehicleRoot)
        net.SendToServer()
    elseif node.unload then
        KMS.PlaySound("Click")
        net.Start("KMS_VehicleLoad")
        net.WriteEntity(node.unload)
        net.WriteEntity(NULL)
        net.SendToServer()
    elseif node.vehinv then
        KMS.PlaySound("Click")
        local root = interact.vehicleRoot
        Deactivate()
        KMS.OpenVehicleInventory(root)
    elseif node.haul then
        KMS.PlaySound("Click")
        KMS.LastTreatSource = "interact"
        net.Start("KMS_Drag")
        net.WriteEntity(interact.patient)
        net.WriteBool(node.haul == "carry")
        net.SendToServer()
    elseif node.deploy then
        KMS.PlaySound("Click")
        net.Start("KMS_MedbayDeploy")
        net.SendToServer()
        Deactivate()
    elseif node.triage then
        KMS.PlaySound("Click")
        KMS.SendTriage(interact.patient, node.triage)
    elseif node.treat then
        if node.blocked then
            KMS.PlaySound("Error")
            return
        end
        KMS.PlaySound("Click")
        KMS.SendTreat(node.target or interact.patient, node.treat, node.partId)
    end
end)

local function RefreshTree()
    if not interact.active then return end
    if not IsValid(interact.patient) then
        Deactivate()
        return
    end
    BuildTree()
end

hook.Add("KMS_PatientUpdated", "KMS_InteractTree", function(patient)
    if patient == interact.patient or interact.watched[patient] then
        RefreshTree()
    end
end)

hook.Add("KMS_ConfigUpdated", "KMS_InteractTree", RefreshTree)

hook.Add("KMS_SelfUpdated", "KMS_InteractConsciousness", function()
    if not interact.active then return end
    if KMS.Self.conscious == false then
        Deactivate()
        return
    end
    RefreshTree()
end)
