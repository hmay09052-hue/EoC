local AID = BattleGrid.AID
local S = KF.Scale
local HOVER_SPEED = 10

local STATE_COLORS = {
    [BattleGrid.CPState.NEUTRAL]   = BattleGrid.C("NeutralCP"),
    [BattleGrid.CPState.CONTESTED] = BattleGrid.C("ContestedCP"),
}

function BattleGrid:GetCPOwnerColor(cp)
    if cp.state == self.CPState.CONTESTED then
        return STATE_COLORS[self.CPState.CONTESTED]
    elseif cp.owner and cp.owner ~= "" then
        local ownerFaction = self:GetFactionByID(cp.owner)
        if ownerFaction and ownerFaction.color then
            return ownerFaction.color
        end
    end
    return STATE_COLORS[self.CPState.NEUTRAL]
end

-- Capture / loss announcements are derived from ownership changes between two syncs.
local function AnnounceOwnerChanges(previous, current)
    if not BattleGrid:GetConfigBool("cp_announce_captures") then return end
    for _, cp in ipairs(current) do
        local old = BattleGrid:FindByIdentifier(previous, cp.identifier)
        if old and old.owner ~= cp.owner then
            local gained = cp.owner ~= ""
            local faction = BattleGrid:GetFactionByID(gained and cp.owner or old.owner)
            BattleGrid:ShowCPAnnouncement(cp.name, faction and faction.name or "", faction and faction.color or BattleGrid.C("Accent"), gained)
            local soundPath = BattleGrid:GetConfig(gained and "cp_capture_sound" or "cp_loss_sound")
            if soundPath ~= "" then KF.Helpers.PlaySound(soundPath) end
        end
    end
end

BattleGrid.Net:Receive("SyncCommandPosts", function()
    local data = BattleGrid.Net:ReadJSON()
    if not data then return end
    for _, cp in ipairs(data) do
        cp.pos = BattleGrid:NormalizeVector(cp.pos)
    end
    AnnounceOwnerChanges(BattleGrid.Cache.CommandPosts, data)
    BattleGrid.Cache.CommandPosts = data
    hook.Run("BattleGrid.CommandPostsUpdated")
end)


function BattleGrid:ShowCPAnnouncement(name, factionName, col, gained)
    local label = string.upper(name)
    local tagText = gained and BattleGrid:L("CP_CAPTURED_TAG") or BattleGrid:L("CP_LOST_TAG")

    local duration = 5
    local startTime = CurTime()
    local letterCount = #label
    local revealDuration = math.min(0.6, letterCount * 0.03)

    local _glowCol = BattleGrid.ColorCopy(col)
    local _blurCol = BattleGrid.ColorCopy(col)
    local _shadowCol = Color(0, 0, 0)
    local _tagCol = BattleGrid.ColorCopy(col)
    local _nameCol = BattleGrid.ColorCopy(BattleGrid.C("TextMuted"))

    local hookName = "BattleGrid.CPAnnounce"
    hook.Remove("HUDPaint", hookName)
    hook.Add("HUDPaint", hookName, function()
        local age = CurTime() - startTime
        if age > duration then hook.Remove("HUDPaint", hookName) return end

        local fadeIn = math.Clamp(age / 0.3, 0, 1)
        local holdEnd = duration - 0.8
        local fadeOut = age > holdEnd and math.Clamp((duration - age) / 0.8, 0, 1) or 1
        local alpha = fadeIn * fadeOut

        local sw, sh = ScrW(), ScrH()
        local layoutX, layoutY, annScale = BattleGrid.Layout.ToPixels("cp_announce")
        local bs = function(n) return S(n) * annScale end
        local bw = 0.25 * sw * annScale
        local bh = 0.12 * sh * annScale
        local cx = layoutX + bw / 2
        local baseY = layoutY + bh / 2

        local slideEase = 1 - math.pow(1 - math.Clamp(age / 0.5, 0, 1), 3)
        local slideY = Lerp(slideEase, bs(20), 0)
        local cy = baseY - slideY

        local revealFrac = math.Clamp(age / revealDuration, 0, 1)
        local hideStart = duration - 0.8
        local hideDuration = math.min(0.6, letterCount * 0.03)
        local hideFrac = age > hideStart and math.Clamp((age - hideStart) / hideDuration, 0, 1) or 0
        local charsToShow = math.floor(revealFrac * letterCount) - math.floor(hideFrac * letterCount)
        charsToShow = math.Clamp(charsToShow, 0, letterCount)
        local visibleText = string.sub(label, 1, charsToShow)
        local isRevealing = revealFrac < 1
        local isHiding = hideFrac > 0 and hideFrac < 1

        local cmdAlpha = math.floor(255 * alpha)
        local pulse = 1 + math.sin(CurTime() * 4) * 0.08 * alpha
        _glowCol.a = math.floor(cmdAlpha * pulse)

        local blurFont = BattleGrid.F("CPAnnounce.Bold.Blur")
        local mainFont = BattleGrid.F("CPAnnounce.Bold")
        _blurCol.a = math.floor(40 * alpha * pulse)
        draw.SimpleText(visibleText, blurFont, cx, cy, _blurCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        _blurCol.a = math.floor(60 * alpha * pulse)
        draw.SimpleText(visibleText, blurFont, cx, cy, _blurCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        _shadowCol.a = math.floor(120 * alpha)
        draw.SimpleText(visibleText, mainFont, cx + 1, cy + 1, _shadowCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(visibleText, mainFont, cx, cy, _glowCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if (isRevealing or isHiding) and charsToShow > 0 then
            surface.SetFont(mainFont)
            local partW = surface.GetTextSize(visibleText)
            local cursorX = cx + partW / 2 + bs(2)
            local cursorBlink = math.floor(math.fmod(CurTime() * 8, 1) > 0.5 and cmdAlpha or 0)
            surface.SetDrawColor(col.r, col.g, col.b, cursorBlink)
            surface.DrawRect(cursorX, cy - bs(18), bs(2), bs(36))
        end

        local lineExpand = math.Clamp((age - 0.2) / 0.4, 0, 1)
        lineExpand = 1 - math.pow(1 - lineExpand, 2)
        surface.SetFont(mainFont)
        local fullW = surface.GetTextSize(label)
        local lineHalfW = (fullW / 2 + bs(20)) * lineExpand * alpha

        local lineY = cy + bs(22)
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(100 * alpha))
        surface.DrawRect(cx - lineHalfW, lineY, lineHalfW * 2, 1)
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(40 * alpha))
        surface.DrawRect(cx - lineHalfW, lineY + 2, lineHalfW * 2, 1)

        local bracketSz = bs(8)
        local bracketW = bs(2)
        local bracketAlpha = math.floor(Lerp(math.Clamp((age - 0.15) / 0.3, 0, 1), 0, 120) * alpha)
        local bx1 = cx - lineHalfW - bs(4)
        local bx2 = cx + lineHalfW + bs(4) - bracketW
        local by = lineY - bs(2)

        surface.SetDrawColor(col.r, col.g, col.b, bracketAlpha)
        surface.DrawRect(bx1, by - bracketSz, bracketW, bracketSz * 2 + 4)
        surface.DrawRect(bx1, by - bracketSz, bracketSz, bracketW)
        surface.DrawRect(bx1, by + bracketSz + 4 - bracketW, bracketSz, bracketW)
        surface.DrawRect(bx2, by - bracketSz, bracketW, bracketSz * 2 + 4)
        surface.DrawRect(bx2 - bracketSz + bracketW, by - bracketSz, bracketSz, bracketW)
        surface.DrawRect(bx2 - bracketSz + bracketW, by + bracketSz + 4 - bracketW, bracketSz, bracketW)

        local tagY = lineY + bs(6)
        local tagFade = math.Clamp((age - 0.4) / 0.3, 0, 1) * alpha
        _tagCol.a = math.floor(100 * tagFade)
        draw.SimpleText(tagText, BattleGrid.F("CPAnnounce.Tag"), cx, tagY, _tagCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        local nameY = tagY + bs(12)
        local nameAlpha = math.floor(180 * tagFade)
        _nameCol.a = nameAlpha
        draw.SimpleText(factionName, BattleGrid.F("CPAnnounce.Sub"), cx, nameY, _nameCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        if age < 0.8 then
            local scanFrac = age / 0.8
            local scanY = cy - bs(30) + bs(80) * scanFrac
            local scanAlpha = math.floor((1 - scanFrac) * 25 * alpha)
            surface.SetDrawColor(col.r, col.g, col.b, scanAlpha)
            surface.DrawRect(cx - lineHalfW, scanY, lineHalfW * 2, 1)
        end
    end)
end


local function DrawWorldCommandPosts()
    if not BattleGrid:IsCPSystemEnabled() or not BattleGrid:GetPref("show_cp_world") then return end

    local plyPos = LocalPlayer():GetPos()
    local maxDist = BattleGrid:GetPref("cp_render_distance")
    local maxDistSqr = maxDist * maxDist
    local worldAlpha = BattleGrid:GetPref("cp_world_alpha")

    for _, cp in ipairs(BattleGrid.Cache.CommandPosts) do
        local distSqr = plyPos:DistToSqr(cp.pos)
        if distSqr > maxDistSqr then continue end

        local hudPos = cp.pos + Vector(0, 0, 200)
        local scr = hudPos:ToScreen()
        if not scr.visible then continue end

        local dist = math.sqrt(distSqr)
        local alpha = BattleGrid:DistanceFadeAlpha(dist, maxDist, worldAlpha)

        local x, y = scr.x, scr.y
        local ownerCol = BattleGrid:GetCPOwnerColor(cp)
        local prefix = cp.prefix or ""

        local hexR = S(12)
        BattleGrid:DrawHex(x, y, hexR,
            KF.UI.ColorAlpha(ownerCol, alpha),
            KF.UI.ColorAlpha(color_white, alpha * 0.5))

        if prefix ~= "" then
            draw.SimpleText(prefix, BattleGrid.FB("caption"), x, y, KF.UI.ColorAlpha(color_white, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local nameY = y + hexR + S(3)
        draw.SimpleText(cp.name, BattleGrid.F("MapLabel"), x, nameY, KF.UI.ColorAlpha(color_white, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        local stateY = nameY + S(14)
        draw.SimpleText(BattleGrid:L(BattleGrid:GetCPStateKey(cp.state)), BattleGrid.F("small"), x, stateY, KF.UI.ColorAlpha(ownerCol, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        if cp.state == BattleGrid.CPState.CONTESTED and cp.ticksRequired and cp.ticksRequired > 0 then
            local progress = math.Clamp((cp.ticks or 0) / cp.ticksRequired, 0, 1)
            local barW = S(40)
            local barH = S(4)
            local barX = x - barW / 2
            local barY = stateY + S(12)

            surface.SetDrawColor(KF.UI.ColorAlpha(color_black, math.floor(alpha * 0.6)))
            surface.DrawRect(barX, barY, barW, barH)
            surface.SetDrawColor(KF.UI.ColorAlpha(ownerCol, alpha))
            surface.DrawRect(barX, barY, barW * progress, barH)
        end

        local distStr = BattleGrid:FormatDistance(dist)
        local distY = stateY + S(12)
        if cp.state == BattleGrid.CPState.CONTESTED then
            distY = distY + S(8)
        end
        draw.SimpleText(distStr, BattleGrid.F("small"), x, distY, KF.UI.ColorAlpha(BattleGrid.C("TextMuted"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

hook.Add("HUDPaint", "BattleGrid.WorldCommandPosts", DrawWorldCommandPosts)


function BattleGrid:DrawMapCommandPosts(panel, zoom)
    if not self:IsCPSystemEnabled() or not self:GetPref("show_cp_map") then return end

    for _, cp in ipairs(self.Cache.CommandPosts) do
        if panel._zFilterZ and cp.pos.z > panel._zFilterZ then continue end
        local cx, cy = panel:WorldToScreen(cp.pos)

        local ownerCol = self:GetCPOwnerColor(cp)

        local radiusWorld = cp.radius or 512
        local edgePos = cp.pos + Vector(radiusWorld, 0, 0)
        local ex, ey = panel:WorldToScreen(edgePos)
        local radiusScreen = math.abs(ex - cx)

        surface.SetDrawColor(KF.UI.ColorAlpha(ownerCol, 15))
        draw.NoTexture()
        BattleGrid:DrawCircle(cx, cy, radiusScreen, 32)

        surface.SetDrawColor(KF.UI.ColorAlpha(ownerCol, 60))
        BattleGrid:DrawOutlinedCircleFromPoints(cx, cy, cx + radiusScreen, cy, 32, 1)

        local hexR = S(10)
        BattleGrid:DrawHex(cx, cy, hexR, ownerCol, KF.UI.ColorAlpha(color_white, 80))

        local prefix = cp.prefix or ""
        if prefix ~= "" then
            draw.SimpleText(prefix, BattleGrid.F("small"), cx, cy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText(cp.name, BattleGrid.F("MapLabel"), cx, cy + hexR + S(2), ownerCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        if cp.state == BattleGrid.CPState.CONTESTED and cp.ticksRequired and cp.ticksRequired > 0 then
            local progress = math.Clamp((cp.ticks or 0) / cp.ticksRequired, 0, 1)
            local barW = S(30)
            local barH = S(3)
            local barX = cx - barW / 2
            local barY = cy + hexR + S(14)

            surface.SetDrawColor(KF.UI.ColorAlpha(color_black, 150))
            surface.DrawRect(barX, barY, barW, barH)

            local contested = STATE_COLORS[BattleGrid.CPState.CONTESTED]
            surface.SetDrawColor(contested)
            surface.DrawRect(barX, barY, barW * progress, barH)
        end

        if zoom and zoom <= 2500 then
            local detailY = cp.state == BattleGrid.CPState.CONTESTED
                and cy + hexR + S(20)
                or cy + hexR + S(14)
            draw.SimpleText(BattleGrid:L(BattleGrid:GetCPStateKey(cp.state)), BattleGrid.F("MapLabelSmall"), cx, detailY, BattleGrid.C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end
end

function BattleGrid:AdminSaveCommandPost(data)
    BattleGrid.Net:SendJSONToServer("AdminSaveCommandPost", data)
end

function BattleGrid:AdminDeleteCommandPost(identifier)
    BattleGrid.Net:SendToServer("AdminDeleteCommandPost", function()
        net.WriteString(identifier)
    end)
end

properties.Add("battlegrid_edit_cp", {
    MenuLabel = "#battlegrid.edit_cp",
    Order     = 1,
    MenuIcon  = "icon16/cog_edit.png",

    Filter = function(self, ent, ply)
        if not IsValid(ent) then return false end
        if ent:GetClass() ~= "battlegrid_commandpost" then return false end
        if not BattleGrid:HasPermission(ply, "BattleGrid.Admin") then return false end
        return true
    end,

    Action = function(self, ent)
        local id = ent:GetCPIdentifier()
        if not id or id == "" then return end

        local cp = BattleGrid:GetCPByID(id)
        if not cp then
            cp = {
                identifier    = id,
                name          = ent:GetCPName() or "",
                prefix        = ent:GetCPPrefix() or "",
                pos           = ent:GetPos(),
                radius        = ent:GetCaptureRadius() or 512,
                ticksRequired = ent:GetCPTicksRequired() or 10,
                owner         = ent:GetOwnerFaction() or "",
                default_owner = ent:GetCPDefaultFaction() or "",
            }
        end

        BattleGrid:OpenCPPropertyEditor(cp)
    end,
})

language.Add("battlegrid.edit_cp", BattleGrid:L("CP_EDIT_PROPERTIES"))

local function LocalOverrideChoices()
    return {
        {"-1", BattleGrid:L("ADMIN_CP_NPC_USE_GLOBAL")},
        {"0",  BattleGrid:L("ADMIN_CP_NPC_DISABLED")},
        {"1",  BattleGrid:L("ADMIN_CP_NPC_ENABLED_LOCAL")},
    }
end

local function FactionChoicesWithNeutral()
    local choices = {{"", BattleGrid:L("CP_STATE_NEUTRAL")}}
    for _, f in ipairs(BattleGrid.FactionList) do
        choices[#choices + 1] = {f.id, f.name}
    end
    return choices
end

function BattleGrid:PopulateCPEditor(parent, cp)
    local edit = {
        radius        = cp.radius or 512,
        ticks         = cp.ticksRequired or 10,
        owner         = cp.default_owner or "",
        npcEnabled    = cp.npc_enabled,
        npcMax        = cp.npc_max,
        npcInterval   = cp.npc_interval,
        npcSpawnTypes = cp.npc_spawn_types or "",
        fastTravel    = cp.fast_travel_enabled,
    }

    local nameIn   = self:CreateTextInput(parent, self:L("ADMIN_CP_NAME_PH"), cp.name or "")
    local prefixIn = self:CreateTextInput(parent, self:L("ADMIN_CP_PREFIX_PH"), cp.prefix or "")
    self:CreateNumberInput(parent, self:L("ADMIN_CP_RADIUS_PH"), edit.radius, function(v) edit.radius = v end)
    self:CreateNumberInput(parent, self:L("ADMIN_CP_TICKS_PH"), edit.ticks, function(v) edit.ticks = v end)
    self:CreateDropdown(parent, self:L("ADMIN_CP_DEFAULT_OWNER"), FactionChoicesWithNeutral(), edit.owner, function(v) edit.owner = v end)
    self:CreateDropdown(parent, self:L("ADMIN_CP_FAST_TRAVEL_PER"), LocalOverrideChoices(), tostring(edit.fastTravel or -1), function(v) edit.fastTravel = tonumber(v) or -1 end)
    self:CreateDropdown(parent, self:L("ADMIN_CP_NPC_ENABLED_PER"), LocalOverrideChoices(), tostring(edit.npcEnabled or -1), function(v) edit.npcEnabled = tonumber(v) or -1 end)
    self:CreateNumberInput(parent, self:L("ADMIN_CP_NPC_MAX_LOCAL"), tonumber(edit.npcMax) or -1, function(v) edit.npcMax = v end)
    self:CreateNumberInput(parent, self:L("ADMIN_CP_NPC_INTERVAL_LOCAL"), tonumber(edit.npcInterval) or -1, function(v) edit.npcInterval = v end)
    self:CreateSpawnTypesEditor(parent, edit.npcSpawnTypes, function(json) edit.npcSpawnTypes = json end)

    return function()
        local name = nameIn:GetValue()
        if name == "" then return nil end
        return {
            identifier          = cp.identifier,
            name                = name,
            prefix              = prefixIn:GetValue(),
            pos                 = { x = cp.pos.x, y = cp.pos.y, z = cp.pos.z },
            radius              = tonumber(edit.radius) or 512,
            ticksRequired       = tonumber(edit.ticks) or 10,
            defaultOwner        = edit.owner,
            fast_travel_enabled = tonumber(edit.fastTravel) or -1,
            npc_enabled         = tonumber(edit.npcEnabled) or -1,
            npc_max             = tonumber(edit.npcMax) or -1,
            npc_interval        = tonumber(edit.npcInterval) or -1,
            npc_spawn_types     = edit.npcSpawnTypes,
        }
    end
end

function BattleGrid:OpenCPPropertyEditor(cp)
    if IsValid(self._cpPropEditor) then self._cpPropEditor:Remove() end

    local frame = self:CreateEditorFrame(self:L("CP_EDIT_PROPERTIES"), S(420), S(580))
    self._cpPropEditor = frame

    local scroll = vgui.Create("KF.ScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(S(16), S(6), S(16), S(12))
    scroll:SetAddon(AID)

    local getPayload = self:PopulateCPEditor(scroll, cp)

    self:CreateEditorActionPanel(frame, self:L("ADMIN_CP_SAVE"), function()
        local payload = getPayload()
        if not payload then return end
        self:AdminSaveCommandPost(payload)
        if IsValid(frame) then frame:Remove() end
    end)
end

BattleGrid._npcSpawnEffects = BattleGrid._npcSpawnEffects or {}

local _npcSpawnMatWireframe = Material("models/wireframe")
local _npcSpawnMatGlow = Material("particle/Particle_Glow_04")
local _npcSpawnMatLight = Material("particle/fire")
local _npcSpawnVecDown = Vector(0, 0, -1)
local _npcSpawnVecUp = Vector(0, 0, 1)
local _npcSpawnColor = BattleGrid.C("NPCSpawn")

local function _npcEaseInOutCubic(t)
    if t < 0.5 then return 4 * t * t * t end
    return 1 - math.pow(-2 * t + 2, 3) / 2
end

local function ApplyNPCSpawnEffect(ent, pos)
    if not IsValid(ent) then return end

    local entIndex = ent:EntIndex()
    local existing = BattleGrid._npcSpawnEffects[entIndex]
    if existing and existing.originalRender ~= nil then
        ent.RenderOverride = existing.originalRender
        ent._bgSpawnEffect = nil
    end

    local mins, maxs = ent:GetModelRenderBounds()
    if not mins or not maxs then
        mins = ent:OBBMins()
        maxs = ent:OBBMaxs()
    end

    local effectData = {
        entIndex = entIndex,
        startTime = CurTime(),
        duration = 2.0,
        originalRender = ent.RenderOverride,
        mins = mins,
        maxs = maxs,
    }

    BattleGrid._npcSpawnEffects[entIndex] = effectData
    ent._bgSpawnEffect = effectData

    ent.RenderOverride = function(self)
        if not IsValid(self) then return end
        local fx = self._bgSpawnEffect
        if not fx then
            self.RenderOverride = nil
            self:DrawModel()
            return
        end

        if self.GetSequenceCount and self:GetSequenceCount() <= 1 then self:DrawModel() return end

        self:InvalidateBoneCache()
        self:SetupBones()

        local elapsed = CurTime() - fx.startTime
        local progress = elapsed / fx.duration

        if progress >= 1 then
            self.RenderOverride = fx.originalRender
            self._bgSpawnEffect = nil
            BattleGrid._npcSpawnEffects[fx.entIndex] = nil
            self:DrawModel()
            return
        end

        local time = progress * 2
        local modelIn = time > 1 and _npcEaseInOutCubic(math.Clamp(time - 1, 0, 1)) or 0
        local wireIn = time < 1 and _npcEaseInOutCubic(math.Clamp(math.sqrt(time), 0, 1)) or 1

        local mypos = self:GetPos()
        local absMins = fx.mins + mypos
        local absMaxs = fx.maxs + mypos

        local vbound = LerpVector(modelIn, absMins, absMaxs)
        local vbound2 = LerpVector(wireIn, absMins, absMaxs)

        local old = render.EnableClipping(true)

        local eyeDistSqr = (LocalPlayer():EyePos() or mypos):DistToSqr(mypos)
        if eyeDistSqr < 4000000 then
            if time < 2 then
                local centered = Vector(mypos.x, mypos.y, (time > 1 and vbound or vbound2).z)
                local f = time % 1
                local parabolic = math.max(0, -4 * f * f + 4 * f)

                render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
                    render.SetMaterial(_npcSpawnMatGlow)
                    local glowSize = math.Rand(48, 72) * parabolic
                    render.DrawQuadEasy(centered, _npcSpawnVecUp, glowSize, glowSize, _npcSpawnColor)
                    render.SetMaterial(_npcSpawnMatLight)
                    render.DrawSprite(centered, 96 * parabolic, 12 * parabolic, _npcSpawnColor)
                render.OverrideBlend(false)
            end
        end

        render.PushCustomClipPlane(_npcSpawnVecDown, _npcSpawnVecDown:Dot(vbound2))
            render.PushCustomClipPlane(_npcSpawnVecUp, _npcSpawnVecUp:Dot(vbound))
                render.MaterialOverride(_npcSpawnMatWireframe)
                local mod = Lerp(math.Clamp(time - 1, 0, 1), 128, 48)
                render.SetColorModulation(_npcSpawnColor.r / mod, _npcSpawnColor.g / mod, _npcSpawnColor.b / mod)
                self:DrawModel()
                render.SetColorModulation(1, 1, 1)
                render.MaterialOverride()
            render.PopCustomClipPlane()
        render.PopCustomClipPlane()

        if modelIn > 0 then
            render.PushCustomClipPlane(_npcSpawnVecDown, _npcSpawnVecDown:Dot(vbound))
                self:DrawModel()
            render.PopCustomClipPlane()
        end

        render.EnableClipping(old)
    end

    sound.Play("ambient/fire/mtov_flame2.wav", pos, 70, 160, 0.5)
end

BattleGrid.Net:Receive("CPNPCSpawnEffect", function()
    local entIndex = net.ReadUInt(14)
    local pos = net.ReadVector()

    local ent = Entity(entIndex)

    if not IsValid(ent) then
        timer.Create("BG_SpawnRetry_" .. entIndex, 0.1, 5, function()
            local retryEnt = Entity(entIndex)
            if IsValid(retryEnt) then
                ApplyNPCSpawnEffect(retryEnt, pos)
                timer.Remove("BG_SpawnRetry_" .. entIndex)
            end
        end)
        return
    end

    ApplyNPCSpawnEffect(ent, pos)
end)

function BattleGrid:CanFastTravel(cp)
    if not self:GetConfigBool("cp_fast_travel_enabled") or not self:IsCPSystemEnabled() then return false end
    if not LocalPlayer():Alive() or LocalPlayer():GetNWBool("BG.InRespawn", false) then return false end
    if cp.fast_travel_enabled == 0 then return false end
    if cp.state ~= self.CPState.CAPTURED then return false end
    local myFaction = self:GetLocalFaction()
    return myFaction and cp.owner == myFaction.id
end

function BattleGrid:RequestFastTravel(cpID)
    if (self._fastTravelNext or 0) > CurTime() then return end
    self._fastTravelNext = CurTime() + 1.5
    BattleGrid.Net:SendToServer("FastTravel", function()
        net.WriteString(cpID)
    end)
end

BattleGrid.Net:Receive("FastTravelResult", function()
    local success = net.ReadBool()
    local reason = net.ReadString()

    if not success then
        BattleGrid:Toast(BattleGrid:L(reason) or reason, "error", 3)
        return
    end

    BattleGrid:StartFastTravelSequence()
end)

function BattleGrid:StartFastTravelSequence()
    if IsValid(self.MapFrame) then self.MapFrame:Remove() end
    LocalPlayer():EmitSound("kraken/battlegrid/laat_takeoff.wav", 60, 100, 0.4)

    local fadePanel = vgui.Create("DPanel")
    fadePanel:SetSize(ScrW(), ScrH())
    fadePanel:SetPos(0, 0)
    fadePanel:MakePopup()
    fadePanel:SetKeyBoardInputEnabled(false)
    fadePanel._startTime = SysTime()
    fadePanel._fadeInDur = 1.0
    fadePanel._holdDur = 4.5
    fadePanel._fadeOutDur = 1.5
    fadePanel._totalDur = fadePanel._fadeInDur + fadePanel._holdDur + fadePanel._fadeOutDur

    local travelFont = BattleGrid.FB("nav")

    fadePanel.Paint = function(pnl, w, h)
        local elapsed = SysTime() - pnl._startTime
        local alpha = 0

        if elapsed < pnl._fadeInDur then
            alpha = elapsed / pnl._fadeInDur
        elseif elapsed < pnl._fadeInDur + pnl._holdDur then
            alpha = 1
        elseif elapsed < pnl._totalDur then
            alpha = 1 - (elapsed - pnl._fadeInDur - pnl._holdDur) / pnl._fadeOutDur
        else
            pnl:Remove()
            return
        end

        alpha = math.Clamp(alpha, 0, 1)
        surface.SetDrawColor(KF.UI.ColorAlpha(color_black, math.floor(alpha * 255)))
        surface.DrawRect(0, 0, w, h)

        if elapsed >= pnl._fadeInDur * 0.7 and elapsed < pnl._fadeInDur + pnl._holdDur + pnl._fadeOutDur * 0.3 then
            local dots = string.rep(".", math.floor(CurTime() * 2) % 4)
            local text = string.TrimRight(string.upper(BattleGrid:L("FAST_TRAVEL_TRAVELLING")), ".") .. dots
            local textCol = ColorAlpha(color_white, math.floor(math.Clamp(alpha, 0, 1) * 220))
            draw.SimpleText(text, travelFont, w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    self._fastTravelFade = fadePanel
end

BattleGrid._RespawnActive = false
BattleGrid._RespawnSelected = nil
BattleGrid._RespawnSpectatePos = nil
local respawnSuppressed = false

local _hexFillCol = Color(0, 0, 0)
local _hexBorderCol = Color(0, 0, 0)

local function DrawHex(cx, cy, size, col, alpha)
    local borderAlpha = math.min(220, alpha + 35)
    _hexFillCol.r = col.r; _hexFillCol.g = col.g; _hexFillCol.b = col.b; _hexFillCol.a = alpha
    _hexBorderCol.r = 255; _hexBorderCol.g = 255; _hexBorderCol.b = 255; _hexBorderCol.a = borderAlpha
    BattleGrid:DrawHex(cx, cy, size, _hexFillCol, _hexBorderCol)
end

local function CloseRespawnScreen()
    BattleGrid._RespawnActive = false
    BattleGrid._RespawnSelected = nil
    BattleGrid._RespawnSpectatePos = nil
    if IsValid(BattleGrid._RespawnPanel) then
        BattleGrid._RespawnPanel:Remove()
        BattleGrid._RespawnPanel = nil
    end
    BattleGrid.Compat.SetExternalHUDHidden(false)
end

local function GetRespawnTargets()
    local faction = BattleGrid:GetLocalFaction()
    local targets = {}
    if not faction then return targets end
    for _, cp in ipairs(BattleGrid.Cache.CommandPosts) do
        if BattleGrid:CanRespawnAtCP(faction, cp) then
            targets[#targets + 1] = { identifier = cp.identifier, prefix = cp.prefix or "", name = cp.name, color = faction.color, pos = cp.pos }
        end
    end
    return targets
end

local function OpenRespawnScreen()
    if IsValid(BattleGrid._RespawnPanel) then BattleGrid._RespawnPanel:Remove() end
    BattleGrid._RespawnActive = true
    BattleGrid.Compat.SetExternalHUDHidden(true, "BattleGrid.RespawnSpectate")

    local sw, sh = ScrW(), ScrH()
    local panel = vgui.Create("DPanel")
    panel:SetPos(0, 0)
    panel:SetSize(sw, sh)
    panel:MakePopup()
    panel:SetKeyboardInputEnabled(false)
    panel._openLerp = 0
    BattleGrid._RespawnPanel = panel

    local cpCards = GetRespawnTargets()
    local cardH = S(50)
    local gap = S(6)
    local spawnSlots = 1 + #cpCards
    local maxW = sw - S(40)
    local spawnCardW = math.min(S(180), math.floor((maxW - (spawnSlots - 1) * gap) / spawnSlots))
    local spawnTotalW = spawnSlots * spawnCardW + (spawnSlots - 1) * gap
    local spawnStartX = (sw - spawnTotalW) / 2
    local cardsY = sh * 0.72

    panel.Paint = function(_, w, h)
        local accent = BattleGrid.C("Accent")
        panel._openLerp = Lerp(KF.Anim.GetFrameTime() * 6, panel._openLerp, 1)
        local a = panel._openLerp
        surface.SetDrawColor(KF.UI.ColorAlpha(color_black, math.floor(180 * a)))
        surface.DrawRect(0, 0, w, h)

        draw.SimpleText(BattleGrid:L("RESPAWN_TITLE"), BattleGrid.F("Respawn.Title"), w / 2, sh * 0.08, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if not BattleGrid._RespawnSelected then
            local pulse = 0.6 + math.sin(CurTime() * 3) * 0.4
            draw.SimpleText(BattleGrid:L("RESPAWN_SELECT_CP"), BattleGrid.F("Respawn.Hint"), w / 2, sh * 0.65, KF.UI.ColorAlpha(BattleGrid.C("TextMuted"), math.floor(255 * pulse)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        surface.SetDrawColor(KF.UI.ColorAlpha(accent, math.floor(30 * a)))
        surface.DrawRect(0, cardsY - S(20), w, cardH + S(40))
        surface.SetDrawColor(KF.UI.ColorAlpha(accent, math.floor(60 * a)))
        surface.DrawRect(0, cardsY - S(20), w, 1)
        surface.DrawRect(0, cardsY + cardH + S(20), w, 1)
    end

    local defaultCard = vgui.Create("DButton", panel)
    defaultCard:SetPos(spawnStartX, cardsY)
    defaultCard:SetSize(spawnCardW, cardH)
    defaultCard:SetText("")
    defaultCard._hoverLerp = 0

    defaultCard.Paint = function(s, w, h)
        local accent = BattleGrid.C("Accent")
        local border = BattleGrid.C("Border")
        local isSelected = BattleGrid._RespawnSelected == "__default__"
        s._hoverLerp = Lerp(KF.Anim.GetFrameTime() * HOVER_SPEED, s._hoverLerp, (s.Hovered or isSelected) and 1 or 0)
        local bgAlpha = math.floor(Lerp(s._hoverLerp, 40, 80))
        surface.SetDrawColor(KF.UI.ColorAlpha(color_black, bgAlpha))
        surface.DrawRect(0, 0, w, h)
        if isSelected then
            surface.SetDrawColor(KF.UI.ColorAlpha(accent, 40))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(accent)
            surface.DrawRect(0, h - 2, w, 2)
        end
        surface.SetDrawColor(KF.UI.ColorAlpha(border, math.floor(60 + 60 * s._hoverLerp)))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if s._hoverLerp > 0.01 then
            surface.SetDrawColor(KF.UI.ColorAlpha(accent, math.floor(100 * s._hoverLerp)))
            surface.DrawRect(0, 0, 2, h)
        end
        draw.SimpleText(BattleGrid:L("RESPAWN_DEFAULT"), BattleGrid.F("Respawn.Name"), w / 2, h / 2 - S(4), BattleGrid.C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(BattleGrid:L("RESPAWN_CP_AVAILABLE"), BattleGrid.F("Respawn.Status"), w / 2, h / 2 + S(10), BattleGrid.C("Success"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    defaultCard.DoClick = function()
        BattleGrid:PlaySound("Click")
        BattleGrid._RespawnSelected = "__default__"
        BattleGrid._RespawnSpectatePos = nil
    end
    defaultCard.OnCursorEntered = function() BattleGrid:PlaySound("Hover") end

    for cpIdx, cp in ipairs(cpCards) do
        local cpCard = vgui.Create("DButton", panel)
        cpCard:SetPos(spawnStartX + cpIdx * (spawnCardW + gap), cardsY)
        cpCard:SetSize(spawnCardW, cardH)
        cpCard:SetText("")
        cpCard._hoverLerp = 0
        cpCard._cpID = cp.identifier
        cpCard._cpPrefix = string.upper(string.sub(cp.prefix or "", 1, 2))
        cpCard._cpName = cp.name or ""
        cpCard._cpColor = cp.color or BattleGrid.C("Accent")
        cpCard._cpPos = cp.pos

        cpCard.Paint = function(s, w, h)
            local border = BattleGrid.C("Border")
            local isSelected = BattleGrid._RespawnSelected == s._cpID
            s._hoverLerp = Lerp(KF.Anim.GetFrameTime() * HOVER_SPEED, s._hoverLerp, (s.Hovered or isSelected) and 1 or 0)
            local bgAlpha = math.floor(Lerp(s._hoverLerp, 40, 80))
            surface.SetDrawColor(KF.UI.ColorAlpha(color_black, bgAlpha))
            surface.DrawRect(0, 0, w, h)
            if isSelected then
                surface.SetDrawColor(KF.UI.ColorAlpha(s._cpColor, 40))
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(s._cpColor)
                surface.DrawRect(0, h - 2, w, 2)
            end
            surface.SetDrawColor(KF.UI.ColorAlpha(border, math.floor(60 + 60 * s._hoverLerp)))
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            if s._hoverLerp > 0.01 then
                surface.SetDrawColor(KF.UI.ColorAlpha(s._cpColor, math.floor(100 * s._hoverLerp)))
                surface.DrawRect(0, 0, 2, h)
            end
            local hexR = S(12)
            local hexCX = S(6) + hexR
            local hexCY = h / 2
            DrawHex(hexCX, hexCY, hexR, s._cpColor, math.floor(Lerp(s._hoverLerp, 180, 240)))
            local prefixText = s._cpPrefix ~= "" and s._cpPrefix or "?"
            draw.SimpleText(prefixText, BattleGrid.F("Respawn.Status"), hexCX, hexCY, BattleGrid.C("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            local textX = hexCX + hexR + S(6)
            local statusFont = BattleGrid.F("Respawn.Status")
            surface.SetFont(statusFont)
            local statusW = surface.GetTextSize(BattleGrid:L("RESPAWN_CP_AVAILABLE"))
            local nameText = BattleGrid:TruncateToWidth(s._cpName, w - textX - statusW - S(12), BattleGrid.F("Respawn.Name"))
            draw.SimpleText(nameText, BattleGrid.F("Respawn.Name"), textX, S(6), s._cpColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(BattleGrid:L("RESPAWN_COMMAND_POST"), BattleGrid.F("Respawn.Role"), textX, S(22), BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(BattleGrid:L("RESPAWN_CP_AVAILABLE"), statusFont, w - S(6), S(6), BattleGrid.C("Success"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end

        cpCard.DoClick = function(s)
            BattleGrid:PlaySound("Click")
            BattleGrid._RespawnSelected = s._cpID
            BattleGrid._RespawnSpectatePos = s._cpPos
        end
        cpCard.OnCursorEntered = function() BattleGrid:PlaySound("Hover") end
    end

    local btnW = S(160)
    local btnH = S(36)
    local deploy = vgui.Create("DButton", panel)
    deploy:SetPos(sw / 2 - btnW / 2, cardsY + cardH + S(30))
    deploy:SetSize(btnW, btnH)
    deploy:SetText("")
    deploy:SetVisible(false)

    deploy.Paint = function(s, w, h)
        if not s:IsVisible() then return end
        KF.Anim.UpdateHoverLerp(s)
        local a = s._hoverLerp
        local col = KF.UI.LerpColor(a, BattleGrid.C("Accent"), BattleGrid.C("AccentHover"))
        draw.RoundedBox(4, 0, 0, w, h, col)
        draw.SimpleText(BattleGrid:L("RESPAWN_DEPLOY"), BattleGrid.F("Respawn.Btn"), w / 2, h / 2, BattleGrid.C("PanelDark"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    deploy.DoClick = function()
        if not BattleGrid._RespawnSelected then return end
        BattleGrid.Net:SendToServer("RespawnRequest", function()
            net.WriteString(BattleGrid._RespawnSelected)
        end)
        CloseRespawnScreen()
    end

    panel.Think = function()
        deploy:SetVisible(BattleGrid._RespawnSelected ~= nil)
    end
end

hook.Add("CalcView", "BattleGrid.RespawnSpectate", function(ply, pos, angles, fov)
    if not BattleGrid._RespawnActive then return end
    local fallbackPos = BattleGrid._RespawnSpectatePos
    if not fallbackPos then return end

    local targetPos = fallbackPos + Vector(0, 0, 80)
    local offset = Vector(-80, 40, 30)
    offset:Rotate(Angle(0, CurTime() * 15, 0))
    local camPos = targetPos + offset
    local tr = util.TraceLine({
        start = targetPos,
        endpos = camPos,
        filter = ply,
        mask = MASK_SOLID_BRUSHONLY,
    })
    if tr.Hit then camPos = tr.HitPos + tr.HitNormal * 5 end
    return {
        origin = camPos,
        angles = (targetPos - camPos):Angle(),
        fov = fov,
        drawviewer = false,
    }
end)

hook.Add("ShouldDrawLocalPlayer", "BattleGrid.RespawnDraw", function()
    if BattleGrid._RespawnActive then return false end
end)

hook.Add("HUDShouldDraw", "BattleGrid.RespawnHUD", function(name)
    if not BattleGrid._RespawnActive then return end
    if name == "CHudHealth" or name == "CHudAmmo" or name == "CHudSecondaryAmmo"
        or name == "CHudCrosshair" or name == "CHudWeaponSelection" then
        return false
    end
end)

-- Sent by Kraken's Strike Squad / JLTS when they take over a death; Battle Grid stays out of the way until the next spawn.
BattleGrid.Net:Receive("RespawnCancel", function()
    respawnSuppressed = true
    CloseRespawnScreen()
end)

hook.Add("Think", "BattleGrid.RespawnScreen", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    if lp:Alive() then
        respawnSuppressed = false
        if BattleGrid._RespawnActive then CloseRespawnScreen() end
        return
    end
    if BattleGrid._RespawnActive or respawnSuppressed then return end
    if not lp:GetNWBool("BG.InRespawn", false) or not KF.Integrations.PlayerInWorld(lp) then return end
    if BattleGrid.Compat.SquadHandlesRespawn(lp) or BattleGrid.Compat.IsSpectating(lp) then return end
    BattleGrid._RespawnSelected = nil
    BattleGrid._RespawnSpectatePos = nil
    OpenRespawnScreen()
end)

hook.Add("BattleGrid.CommandPostsUpdated", "BattleGrid.RespawnRefresh", function()
    if BattleGrid._RespawnActive then OpenRespawnScreen() end
end)

local _statusFillCol = Color(0, 0, 0)
local _compassFill, _compassLine, _compassText = Color(0, 0, 0), Color(0, 0, 0), Color(0, 0, 0)

hook.Add("BF2HUD.PaintCompassOverlay", "BattleGrid.CompassCommandPosts", function(px, baseY, width, yaw)
    if not BattleGrid:IsMapAllowed() or not BattleGrid:GetPref("show_cp_compass") then return end
    local plyPos = LocalPlayer():GetPos()
    local markerY = baseY - BattleGrid.Compat.HUDScale(14)
    local hexR = BattleGrid.Compat.HUDScale(8)

    for _, cp in ipairs(BattleGrid.Cache.CommandPosts) do
        local tx, fade = BattleGrid:CompassProject(cp.pos, plyPos, yaw, px, width)
        if tx then
            local col = BattleGrid:GetCPOwnerColor(cp)
            _compassFill.r, _compassFill.g, _compassFill.b, _compassFill.a = col.r, col.g, col.b, math.floor(210 * fade)
            _compassLine.a = math.floor(200 * fade)
            _compassLine.r, _compassLine.g, _compassLine.b = 255, 255, 255
            BattleGrid:DrawHex(tx, markerY, hexR, _compassFill, _compassLine)
            if cp.prefix ~= "" then
                _compassText.r, _compassText.g, _compassText.b, _compassText.a = 255, 255, 255, math.floor(245 * fade)
                draw.SimpleText(cp.prefix, "BF2HUD.compass_card", tx, markerY, _compassText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
end)

hook.Add("HUDPaint", "BattleGrid.CPStatusBar", function()
    if not BattleGrid:GetPref("show_cp_status_bar") or not BattleGrid:IsCPSystemEnabled() then return end

    local cps = BattleGrid.Cache.CommandPosts
    if #cps == 0 then return end

    local sw, sh = ScrW(), ScrH()
    local layoutX, layoutY, barScale = BattleGrid.Layout.ToPixels("cp_world")
    local bw = 0.20 * sw * barScale
    local bh = 0.15 * sh * barScale
    local hexR = math.Round(sh * 0.018 * barScale)
    local spacing = math.Round(hexR * 2.6)
    local startX = layoutX + bw / 2 - (#cps - 1) * spacing * 0.5
    local cy = layoutY + bh / 2

    for idx, cp in ipairs(cps) do
        local cx = startX + (idx - 1) * spacing
        local col = BattleGrid:GetCPOwnerColor(cp)
        _statusFillCol.r, _statusFillCol.g, _statusFillCol.b, _statusFillCol.a = col.r, col.g, col.b, 200
        BattleGrid:DrawHex(cx, cy, hexR, _statusFillCol, color_black)

        if cp.state == BattleGrid.CPState.CONTESTED and cp.ticksRequired > 0 then
            local progress = math.Clamp(cp.ticks / cp.ticksRequired, 0, 1)
            local outR = hexR + 3
            local outVerts = {}
            for i = 0, 5 do
                local angle = math.rad(60 * i - 90)
                outVerts[i + 1] = { x = cx + math.cos(angle) * outR, y = cy + math.sin(angle) * outR }
            end

            local edgeProgress = progress * 6
            local fullEdges = math.floor(edgeProgress)
            local partialFrac = edgeProgress - fullEdges

            surface.SetDrawColor(KF.UI.ColorAlpha(color_white, 220))
            for i = 1, fullEdges do
                local j = (i % 6) + 1
                surface.DrawLine(outVerts[i].x, outVerts[i].y, outVerts[j].x, outVerts[j].y)
            end
            if fullEdges < 6 and partialFrac > 0 then
                local si = fullEdges + 1
                local ei = (si % 6) + 1
                local ex = outVerts[si].x + (outVerts[ei].x - outVerts[si].x) * partialFrac
                local ey = outVerts[si].y + (outVerts[ei].y - outVerts[si].y) * partialFrac
                surface.DrawLine(outVerts[si].x, outVerts[si].y, ex, ey)
            end
        end

        if cp.prefix ~= "" then
            draw.SimpleText(cp.prefix, BattleGrid.FB("caption"), cx, cy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end)