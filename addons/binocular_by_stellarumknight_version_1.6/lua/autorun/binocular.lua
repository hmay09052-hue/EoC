-- Performance: Wärmebild durchsucht nur Spieler + (gecachte) NPCs statt jeden Frame ents.GetAll()
local BINO_FLATWHITE_MAT = CLIENT and Material("models/debug/debugwhite") or nil
local binoNPCCache, binoNPCCacheTime, binoTargets = {}, 0, {}
local function BinoThermalTargets()
    local now = RealTime()
    if now >= binoNPCCacheTime then
        binoNPCCache = ents.FindByClass("npc_*")
        binoNPCCacheTime = now + 0.5
    end
    local list, n = binoTargets, 0
    for _, ply in ipairs(player.GetAll()) do n = n + 1 list[n] = ply end
    for _, npc in ipairs(binoNPCCache) do n = n + 1 list[n] = npc end
    for i = #list, n + 1, -1 do list[i] = nil end
    return list
end
local BINO_OVERLAY_MAT = CLIENT and Material("binoculars/overlay") or nil -- Performance: einmal laden statt jeden Frame
if SERVER then
    util.AddNetworkString("UpdateZoomLevel")
    util.AddNetworkString("ToggleBinoculars")
    util.AddNetworkString("PlayerInCrosshair")
    util.AddNetworkString("UpdateBodygroup")
    util.AddNetworkString("ToggleRangefinder")

    AddCSLuaFile("autorun/config.lua")
    include("autorun/config.lua")

    local function getBodygroupIndexByName(ply, groupName)
        for i = 0, ply:GetNumBodyGroups() - 1 do
            if string.lower(ply:GetBodygroupName(i)) == string.lower(groupName) then
                return i
            end
        end
        return nil
    end

    net.Receive("UpdateZoomLevel", function(len, ply)
        local zoomLevel = net.ReadFloat()
        net.Start("UpdateZoomLevel")
        net.WriteEntity(ply)
        net.WriteFloat(zoomLevel)
        net.Broadcast()
    end)

    net.Receive("ToggleBinoculars", function(len, ply)
        local active = net.ReadBool()
        net.Start("ToggleBinoculars")
        net.WriteEntity(ply)
        net.WriteBool(active)
        net.Broadcast()
        
        net.Start("UpdateBodygroup")
        net.WriteEntity(ply)
        net.WriteBool(active)
        net.Broadcast()

        local model = ply:GetModel()
        local bodygroupData = active and bodygroupOn or bodygroupOff
        for _, group in ipairs(bodygroupData) do
            if table.HasValue(group.models, model) then
                local idx = getBodygroupIndexByName(ply, group.name)
                if idx then
                    ply:SetBodygroup(idx, group.value)
                end
                break
            end
        end
    end)

    net.Receive("UpdateBodygroup", function()
        local ply = net.ReadEntity()
        local active = net.ReadBool()

        local model = ply:GetModel()
        local bodygroupData = active and bodygroupOn or bodygroupOff
        for _, group in ipairs(bodygroupData) do
            if table.HasValue(group.models, model) then
                local idx = getBodygroupIndexByName(ply, group.name)
                if idx then
                    ply:SetBodygroup(idx, group.value)
                end
                break
            end
        end
    end)

    net.Receive("ToggleRangefinder", function(len, ply)
        local active = net.ReadBool()
        local model = ply:GetModel()
        local data = active and rbodygroupOn or rbodygroupOff
        for _, group in ipairs(data) do
            if table.HasValue(group.models, model) then
                local idx = getBodygroupIndexByName(ply, group.name)
                if idx then
                    ply:SetBodygroup(idx, group.value)
                end
                break
            end
        end
        net.Start("ToggleRangefinder")
        net.WriteEntity(ply)
        net.WriteBool(active)
        net.Broadcast()
    end)

    return
end

include("autorun/config.lua")

local binocularActive = false
local zoomLevel = 0
local nightVisionActive = false
local lamp = nil
local rangefinderActive = false
local lastRangefinderPress = 0
local rangefinderLockCandidate = nil
local rangefinderLockStart = 0
local rangefinderLockedNPC = nil
local rangefinderLockEnabled = RangefinderNPCLockEnabled ~= false
local rangefinderLockHoldTime = tonumber(RangefinderNPCLockHoldTime) or 0.7
local rangefinderLockMaxDistanceUnits = math.max(0, (tonumber(RangefinderNPCLockMaxDistanceMeters) or 0) / 0.025)
local rangefinderLockAimDotThreshold = math.Clamp(tonumber(RangefinderNPCLockAimDotThreshold) or 0.992, 0, 1)
local rangefinderLockBreakGraceTime = math.max(0, tonumber(RangefinderNPCLockBreakGraceTime) or 0.35)
local rangefinderLockAimAssist = RangefinderNPCLockAimAssist ~= false
local rangefinderLockedLostSince = 0
local rangefinderLockKeyWasDown = false
local rangefinderLockToggleReady = false
local rangefinderLockConsumePress = false

local lastTogglePress = 0
local lastZoomPress = 0
local lastNightPress = 0
local lastUnzoomPress = 0
local lastThermalPress = 0

local zoomInSound = nil
local zoomOutSound = nil

-- wieder lokale Materialien/RT-Namen definieren, damit alles wie früher funktioniert
local rangefinderMaterial = Material("rangefinder/rangefinder")
local wireframeMaterial   = Material("models/wireframe")
local playerViewRTName    = "PlayerViewWindow"
local playerViewMaterial  = CreateMaterial(playerViewRTName .. "_Material", "UnlitGeneric", {
    ["$basetexture"] = playerViewRTName,
    ["$vertexcolor"] = 1,
    ["$vertexalpha"] = 1
})

-- zoom indicator vars, playerInCrosshair etc.
local zoomIndicatorX = ScrW() * 0.05
local zoomIndicatorY = ScrH() * 0.85
local zoomIndicatorWidth = ScrW() * 0.3
local zoomIndicatorHeight = ScrH() * 0.02

local movingBarOffset = 0
local playerInCrosshair = nil

local function getBodygroupIndexByName(ply, groupName)
    for i = 0, ply:GetNumBodyGroups() - 1 do
        if string.lower(ply:GetBodygroupName(i)) == string.lower(groupName) then
            return i
        end
    end
    return nil
end

local function SetPlayerBodygroup(ply, active)
    local model = ply:GetModel()
    local bodygroupData = active and bodygroupOn or bodygroupOff

    for _, group in ipairs(bodygroupData) do
        if table.HasValue(group.models, model) then
            local idx = getBodygroupIndexByName(ply, group.name)
            if idx then
                ply:SetBodygroup(idx, group.value)
            end
            break
        end
    end

    ply:SetupBones()
    ply:InvalidateBoneCache()
end

local function SetRangefinderBodygroup(ply, active)
    local model = ply:GetModel()
    local data = active and rbodygroupOn or rbodygroupOff
    for _, group in ipairs(data) do
        if table.HasValue(group.models, model) then
            local idx = getBodygroupIndexByName(ply, group.name)
            if idx then
                ply:SetBodygroup(idx, group.value)
            end
            break
        end
    end
    ply:SetupBones()
    ply:InvalidateBoneCache()
end

local function isJobAllowedToMark(ply)
    local job = team.GetName(ply:Team())
    return allowedJobs[job]
end

local function CanUseBinoculars(ply)
    if BinocularMode == "all" then
        return true
    elseif BinocularMode == "model" then
        return table.HasValue(AllowedModels, ply:GetModel())
    elseif BinocularMode == "modelbodygroup" then
        local model = ply:GetModel()
        for _, group in ipairs(RequiredBodygroups) do
            if table.HasValue(group.models, model) then
                local idx = getBodygroupIndexByName(ply, group.name)
                if idx then
                    local currentValue = ply:GetBodygroup(idx)
                    if table.HasValue(group.values, currentValue) then
                        return true
                    end
                end
            end
        end
        return false
    end
    return false
end

local function CanUseRangefinder(ply)
    if BinocularMode == "all" then
        -- wieder wie vorher: Rangefinder im Modus "all" nicht nutzbar
        return false
    elseif BinocularMode == "model" then
        return table.HasValue(RangefinderModels, ply:GetModel())
    elseif BinocularMode == "modelbodygroup" then
        local model = ply:GetModel()
        for _, group in ipairs(RequiredRangefinderBodygroups) do
            if table.HasValue(group.models, model) then
                local idx = getBodygroupIndexByName(ply, group.name)
                if idx then
                    local currentValue = ply:GetBodygroup(idx)
                    if table.HasValue(group.values, currentValue) then
                        return true
                    end
                end
            end
        end
        return false
    end
    return false
end

local customOverlayActive = false
local lastCustomOverlayPress = 0

local function CanUseSunvisor(ply)
    if BinocularMode == "model" then
        return table.HasValue(SunvisorModels, ply:GetModel())
    elseif BinocularMode == "modelbodygroup" then
        local model = ply:GetModel()
        for _, group in ipairs(RequiredSunvisorBodygroups) do
            if table.HasValue(group.models, model) then
                local idx = getBodygroupIndexByName(ply, group.name)
                if idx then
                    local currentValue = ply:GetBodygroup(idx)
                    if table.HasValue(group.values, currentValue) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function ResetRangefinderLock()
    rangefinderLockCandidate = nil
    rangefinderLockStart = 0
    rangefinderLockedNPC = nil
    rangefinderLockedLostSince = 0
    rangefinderLockToggleReady = false
end

local function IsValidRangefinderNPCTarget(ply, target)
    if not IsValid(ply) or not IsValid(target) or not target:IsNPC() or target:Health() <= 0 then
        return false
    end

    local eyePos = ply:EyePos()
    local targetPos = target:WorldSpaceCenter()
    local distance = eyePos:Distance(targetPos)
    if rangefinderLockMaxDistanceUnits > 0 and distance > rangefinderLockMaxDistanceUnits then
        return false
    end

    local toTarget = (targetPos - eyePos):GetNormalized()
    local dot = ply:EyeAngles():Forward():Dot(toTarget)
    if dot < rangefinderLockAimDotThreshold then
        return false
    end

    local tr = util.TraceLine({
        start = eyePos,
        endpos = targetPos,
        filter = ply,
        mask = MASK_SHOT
    })

    return tr.Entity == target or tr.Fraction > 0.99
end

local function FindBestRangefinderNPCTarget(ply)
    if not IsValid(ply) then
        return nil
    end

    local eyePos = ply:EyePos()
    local forward = ply:EyeAngles():Forward()
    local bestTarget = nil
    local bestScore = -1

    local candidates
    if rangefinderLockMaxDistanceUnits > 0 then
        candidates = ents.FindInSphere(eyePos, rangefinderLockMaxDistanceUnits)
    else
        candidates = ents.GetAll()
    end

    for _, ent in ipairs(candidates) do
        if IsValidRangefinderNPCTarget(ply, ent) then
            local targetPos = ent:WorldSpaceCenter()
            local toTarget = (targetPos - eyePos):GetNormalized()
            local dot = forward:Dot(toTarget)
            local dist = eyePos:Distance(targetPos)
            local distanceWeight = 0
            if rangefinderLockMaxDistanceUnits > 0 then
                distanceWeight = dist / rangefinderLockMaxDistanceUnits
            else
                distanceWeight = math.min(dist / 20000, 1)
            end

            local score = dot - (distanceWeight * 0.05)
            if score > bestScore then
                bestScore = score
                bestTarget = ent
            end
        end
    end

    return bestTarget
end

if CLIENT then
    local function CanUseAnyFeature(ply)
        return CanUseBinoculars(ply) or CanUseRangefinder(ply) or CanUseSunvisor(ply)
    end

    local function IsEntityVisibleToOptics(ent, observer)
        if not IsValid(ent) then
            return false
        end

        if ent:GetNoDraw() or ent:IsEffectActive(EF_NODRAW) then
            return false
        end

        local entColor = ent:GetColor()
        if entColor and entColor.a <= 0 then
            return false
        end

        if ent:IsPlayer() then
            if ent == observer then
                return false
            end
        end

        return true
    end

    local function IsLineOfSightClearToEntity(observer, ent)
        if not IsValid(observer) or not IsValid(ent) then
            return false
        end

        local tr = util.TraceLine({
            start = observer:EyePos(),
            endpos = ent:WorldSpaceCenter(),
            filter = { observer },
            mask = MASK_VISIBLE_AND_NPCS
        })

        return tr.Entity == ent or tr.Fraction > 0.99
    end

    local function DrawEntitySunvisorHitbox(ent, observer)
        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
        local corners = {
            Vector(mins.x, mins.y, mins.z),
            Vector(mins.x, mins.y, maxs.z),
            Vector(mins.x, maxs.y, mins.z),
            Vector(mins.x, maxs.y, maxs.z),
            Vector(maxs.x, mins.y, mins.z),
            Vector(maxs.x, mins.y, maxs.z),
            Vector(maxs.x, maxs.y, mins.z),
            Vector(maxs.x, maxs.y, maxs.z)
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        local onScreen = false

        for _, corner in ipairs(corners) do
            local screen = ent:LocalToWorld(corner):ToScreen()
            if screen.visible then
                onScreen = true
                minX = math.min(minX, screen.x)
                minY = math.min(minY, screen.y)
                maxX = math.max(maxX, screen.x)
                maxY = math.max(maxY, screen.y)
            end
        end

        if not onScreen then
            return
        end

        local width = maxX - minX
        local height = maxY - minY
        if width < 2 or height < 2 then
            return
        end

        local boxColor = ent:IsPlayer() and (SYMUI and SYMUI.Accent(220) or Color(255, 190, 90, 220)) or Color(255, 90, 90, 220)
        surface.SetDrawColor(boxColor)
        surface.DrawOutlinedRect(minX, minY, width, height, 1)

        local cornerLen = math.min(width, height) * 0.18
        cornerLen = math.Clamp(cornerLen, 6, 22)

        surface.DrawLine(minX, minY, minX + cornerLen, minY)
        surface.DrawLine(minX, minY, minX, minY + cornerLen)
        surface.DrawLine(maxX, minY, maxX - cornerLen, minY)
        surface.DrawLine(maxX, minY, maxX, minY + cornerLen)
        surface.DrawLine(minX, maxY, minX + cornerLen, maxY)
        surface.DrawLine(minX, maxY, minX, maxY - cornerLen)
        surface.DrawLine(maxX, maxY, maxX - cornerLen, maxY)
        surface.DrawLine(maxX, maxY, maxX, maxY - cornerLen)

        local label = ent:IsPlayer() and ent:Nick() or string.upper(ent:GetClass())
        local distanceMeters = observer:GetPos():Distance(ent:WorldSpaceCenter()) * 0.025
        draw.SimpleText(label, (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), minX + width * 0.5, minY - 16, boxColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(string.format("%.0fm", distanceMeters), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), minX + width * 0.5, maxY + 4, Color(255, 255, 255, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    hook.Add("Think", "BinocularControls", function()
        if vgui.GetKeyboardFocus() then return end

        if not KEY_TOGGLE then
            return
        end

        if input.IsKeyDown(KEY_TOGGLE) and CurTime() - lastTogglePress > 0.5 then
            lastTogglePress = CurTime()
            if not CanUseBinoculars(LocalPlayer()) then
                if not CanUseAnyFeature(LocalPlayer()) then
                    surface.PlaySound("common/wpn_denyselect.wav")
                end
                return
            end
            binocularActive = not binocularActive
            surface.PlaySound("zoom/Bino_down.wav")
            net.Start("ToggleBinoculars")
            net.WriteBool(binocularActive)
            net.SendToServer()
            net.Start("UpdateBodygroup")
            net.WriteBool(binocularActive)
            net.SendToServer()
            SetPlayerBodygroup(LocalPlayer(), binocularActive)
            if binocularActive then
                hook.Add("HUDPaint", "BinocularOverlay", function()
                    surface.SetDrawColor(255, 255, 255, 255)
                    surface.SetMaterial(BINO_OVERLAY_MAT)
                    surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
                    local zoomFraction = zoomLevel / 30
                    surface.SetDrawColor(0, 0, 0, 150)
                    surface.DrawRect(zoomIndicatorX, zoomIndicatorY, zoomIndicatorWidth, zoomIndicatorHeight)
                    surface.SetDrawColor(SYMUI and SYMUI.Accent() or Color(191, 173, 189, 255))
                    surface.DrawRect(zoomIndicatorX, zoomIndicatorY, zoomIndicatorWidth * zoomFraction, zoomIndicatorHeight)
                    draw.SimpleText("Zoom Level: " .. string.format("%.1f", zoomLevel), "StarWarsFont", zoomIndicatorX + zoomIndicatorWidth / 2, zoomIndicatorY + zoomIndicatorHeight / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    local movingBarY = zoomIndicatorY - ScrH() * 0.05
                    local movingBarX = zoomIndicatorX + (math.sin(CurTime() * 2) + 1) / 2 * (zoomIndicatorWidth - ScrW() * 0.02)
                    surface.SetDrawColor(SYMUI and SYMUI.Accent() or Color(191, 173, 189, 255))
                    surface.DrawRect(movingBarX, movingBarY, ScrW() * 0.02, zoomIndicatorHeight)
                    
                    local movingBarFraction = (math.sin(CurTime() * 2) + 1) / 2
                    surface.SetDrawColor(SYMUI and SYMUI.Accent() or Color(191, 173, 189, 255))
                    surface.DrawRect(zoomIndicatorX, movingBarY, zoomIndicatorWidth * movingBarFraction, zoomIndicatorHeight)
                    
                    local squareSize = ScrH() * 0.038
                    local squareSpacing = ScrH() * 0.01
                    local startX = ScrW() - 5 * (squareSize + squareSpacing) - ScrW() * 0.1
                    local startY = ScrH() * 0.11
                    for i = 0, 4 do
                        surface.SetDrawColor(SYMUI and SYMUI.Accent() or Color(191, 173, 189, 255))
                        surface.DrawRect(startX + i * (squareSize + squareSpacing), startY, squareSize, squareSize)
                    end

                    local squareSize = ScrH() * 0.038
                    local startY = ScrH() * 0.11
                    local indicatorW = squareSize * 2.2
                    local indicatorH = squareSize
                    local indicatorX = ScrW() * 0.07
                    local indicatorY = startY

                    local function drawRoundedBoxEx(radius, x, y, w, h, col)
                        draw.RoundedBox(radius, x, y, w, h, col)
                    end

                    if nightVisionActive or thermalVisionActive then
                        local bgColor, iconColor, iconText, labelText
                        if nightVisionActive then
                            bgColor = Color(30, 80, 30, 220)
                            iconColor = Color(0, 255, 0, 255)
                            iconText = "👁"
                            labelText = "NVD"
                        else
                            bgColor = Color(80, 40, 0, 220)
                            iconColor = Color(255, 140, 0, 255)
                            iconText = "🌡"
                            labelText = "Thermal"
                        end

                        drawRoundedBoxEx(8, indicatorX, indicatorY, indicatorW, indicatorH, bgColor)

                        surface.SetDrawColor(iconColor)
                        draw.SimpleText(iconText, (SYMUI and SYMUI.F("DermaLarge") or "DermaLarge"), indicatorX + indicatorH * 0.38, indicatorY + indicatorH / 2, iconColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                        draw.SimpleText(labelText, (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), indicatorX + indicatorH * 1.1, indicatorY + indicatorH / 2, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end

                    if playerInCrosshair then
                        draw.SimpleText(playerInCrosshair:Nick(), "StarWarsFont", ScrW() / 2, ScrH() / 2 + 50, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end)
            else
                hook.Remove("HUDPaint", "BinocularOverlay")
                LocalPlayer():SetFOV(0, 0.1)
                if thermalVisionActive then
                    thermalVisionActive = false
                    hook.Remove("RenderScreenspaceEffects", "ThermalVisionEffect")
                end
            end
        end

        -- Toggle thermal vision (O)
        if input.IsKeyDown(KEY_THERMAL) and CurTime() - lastThermalPress > 0.5 then
            lastThermalPress = CurTime()
            if not binocularActive then
                surface.PlaySound("common/wpn_denyselect.wav")
                return
            end
            if nightVisionActive then
                surface.PlaySound("common/wpn_denyselect.wav")
                return
            end
            thermalVisionActive = not thermalVisionActive

            if thermalVisionActive and nightVisionActive then
                nightVisionActive = false
                hook.Remove("RenderScreenspaceEffects", "NightVisionEffect")
                if lamp then
                    lamp:Remove()
                    lamp = nil
                end
            end

            if thermalVisionActive then
                hook.Add("RenderScreenspaceEffects", "ThermalVisionEffect", function()
                    DrawColorModify({
                        ["$pp_colour_addr"] = 0,
                        ["$pp_colour_addg"] = 0,
                        ["$pp_colour_addb"] = 0,
                        ["$pp_colour_brightness"] = -0.2,
                        ["$pp_colour_contrast"] = 1,
                        ["$pp_colour_colour"] = 0,
                        ["$pp_colour_mulr"] = 0,
                        ["$pp_colour_mulg"] = 0,
                        ["$pp_colour_mulb"] = 0
                    })

                    local flatWhite = BINO_FLATWHITE_MAT
                    cam.Start3D(EyePos(), EyeAngles())
                    render.SuppressEngineLighting(true)
                    for _, ent in ipairs(BinoThermalTargets()) do
                        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) and IsEntityVisibleToOptics(ent, LocalPlayer()) then
                            render.MaterialOverride(flatWhite)
                            render.SetColorModulation(2, 2, 2)
                            render.SetBlend(1)
                            ent:DrawModel()
                            render.MaterialOverride(nil)
                        end
                    end
                    render.SetColorModulation(1, 1, 1)
                    render.SuppressEngineLighting(false)
                    cam.End3D()
                end)
            else
                hook.Remove("RenderScreenspaceEffects", "ThermalVisionEffect")
            end
        end

        if input.IsKeyDown(KEY_NIGHT) and (not KEY_THERMAL_MODIFIER or not input.IsKeyDown(KEY_THERMAL_MODIFIER)) and CurTime() - lastNightPress > 0.5 then
            lastNightPress = CurTime()
            if thermalVisionActive then
                surface.PlaySound("common/wpn_denyselect.wav")
                return
            end
            nightVisionActive = not nightVisionActive

            if nightVisionActive then
                surface.PlaySound("nvg/NVIII.wav")
                hook.Add("RenderScreenspaceEffects", "NightVisionEffect", function()
                    DrawColorModify({
                        ["$pp_colour_addr"] = 0,
                        ["$pp_colour_addg"] = 0.3,
                        ["$pp_colour_addb"] = 0,
                        ["$pp_colour_brightness"] = -0.6,
                        ["$pp_colour_contrast"] = 1,
                        ["$pp_colour_colour"] = 0.1,
                        ["$pp_colour_mulr"] = 0,
                        ["$pp_colour_mulg"] = 1,
                        ["$pp_colour_mulb"] = 0
                    })
                end)
            else
                surface.PlaySound("nvg/NVOff.wav")
                hook.Remove("RenderScreenspaceEffects", "NightVisionEffect")
            end
        end

        if binocularActive then
            if input.IsKeyDown(KEY_ZOOM) then
                zoomLevel = math.min(zoomLevel + FrameTime() * 10, 30)
                net.Start("UpdateZoomLevel")
                net.WriteFloat(zoomLevel)
                net.SendToServer()
                if not zoomInSound then
                    zoomInSound = CreateSound(LocalPlayer(), "zoom/ZoomInZ.wav")
                    zoomInSound:Play()
                    zoomInSound:ChangeVolume(1, 0)
                elseif not zoomInSound:IsPlaying() then
                    zoomInSound:Play()
                end
            else
                if zoomInSound then
                    zoomInSound:Stop()
                    zoomInSound = nil
                end
            end

            if input.IsKeyDown(KEY_UNZOOM) then
                zoomLevel = math.max(zoomLevel - FrameTime() * 10, 0)
                net.Start("UpdateZoomLevel")
                net.WriteFloat(zoomLevel)
                net.SendToServer()
                if not zoomOutSound then
                    zoomOutSound = CreateSound(LocalPlayer(), "zoom/ZoomOutZ.wav")
                    zoomOutSound:Play()
                    zoomOutSound:ChangeVolume(1, 0)
                elseif not zoomOutSound:IsPlaying() then
                    zoomOutSound:Play()
                end
            else
                if zoomOutSound then
                    zoomOutSound:Stop()
                    zoomOutSound = nil
                end
            end

            if input.IsKeyDown(KEY_NIGHT) and CurTime() - lastNightPress > 0.5 then
                lastNightPress = CurTime()
                nightVisionActive = not nightVisionActive
                if nightVisionActive then
                    surface.PlaySound("nvg/NVIII.wav")
                    hook.Add("RenderScreenspaceEffects", "NightVisionEffect", function()
                        DrawColorModify({
                            ["$pp_colour_addr"] = 0,
                            ["$pp_colour_addg"] = 0.3,
                            ["$pp_colour_addb"] = 0,
                            ["$pp_colour_brightness"] = -0.6,
                            ["$pp_colour_contrast"] = 1,
                            ["$pp_colour_colour"] = 0.1,
                            ["$pp_colour_mulr"] = 0,
                            ["$pp_colour_mulg"] = 1,
                            ["$pp_colour_mulb"] = 0
                        })
                    end)
                else
                    hook.Remove("RenderScreenspaceEffects", "NightVisionEffect")
                end
            end

            if nightVisionActive then
                if not lamp then
                    lamp = ProjectedTexture()
                    lamp:SetTexture("effects/flashlight001")
                    lamp:SetNearZ(10)
                    lamp:SetFarZ(999999)
                    lamp:SetFOV(160)
                    lamp:SetBrightness(999)
                end
                lamp:SetBrightness(10)
                local ply = LocalPlayer()
                lamp:SetPos(ply:EyePos() + ply:GetForward() * 10)
                lamp:SetAngles(ply:EyeAngles())
                lamp:Update()
            else
                if lamp then
                    lamp:Remove()
                    lamp = nil
                end
            end

            local trace = LocalPlayer():GetEyeTrace()
            if trace.Entity and trace.Entity:IsPlayer() and IsEntityVisibleToOptics(trace.Entity, LocalPlayer()) then
                playerInCrosshair = trace.Entity
            else
                playerInCrosshair = nil
            end
        else
            LocalPlayer():SetFOV(0, 0.1)
            nightVisionActive = false
            hook.Remove("RenderScreenspaceEffects", "NightVisionEffect")
            if lamp then
                lamp:Remove()
                lamp = nil
            end
            if zoomInSound then
                zoomInSound:Stop()
                zoomInSound = nil
            end
            if zoomOutSound then
                zoomOutSound:Stop()
                zoomOutSound = nil
            end
            if nightVisionActive then
                nightVisionActive = false
                hook.Remove("RenderScreenspaceEffects", "NightVisionEffect")
            end
        end
    end)

    hook.Add("CalcView", "BinocularCalcView", function(ply, origin, angles, fov, znear, zfar)
        if binocularActive then
            fov = 90 / (1 + zoomLevel)
            return {
                origin = origin,
                angles = angles,
                fov = fov,
                znear = znear,
                zfar = zfar,
                drawviewer = false
            }
        end
    end)

    net.Receive("UpdateZoomLevel", function()
        local ply = net.ReadEntity()
        local zoomLevel = net.ReadFloat()
        if IsValid(ply) and ply == LocalPlayer() and binocularActive then
            LocalPlayer():SetFOV(90 / (1 + zoomLevel), 0.1)
        end
    end)

    net.Receive("ToggleBinoculars", function()
        local ply = net.ReadEntity()
        local active = net.ReadBool()
        if IsValid(ply) and ply == LocalPlayer() then
            binocularActive = active
            SetPlayerBodygroup(ply, active)
            if not active then
                LocalPlayer():SetFOV(0, 0.1)
            end
        end
    end)

    net.Receive("UpdateBodygroup", function()
        local ply = net.ReadEntity()
        local active = net.ReadBool()
        if IsValid(ply) then
            -- Update bodygroup for both binocular and rangefinder
            SetPlayerBodygroup(ply, active)
        end
    end)

    hook.Add("PlayerBindPress", "OverrideZoomBind", function(ply, bind, pressed)
        if string.find(bind, "+zoom") then
            return true
        end
    end)

    hook.Add("Think", "RangefinderControls", function()
        if vgui.GetKeyboardFocus() then return end

        if input.IsKeyDown(KEY_RANGEFINDER) and CurTime() - lastRangefinderPress > 0.5 then
            lastRangefinderPress = CurTime()
            if not CanUseRangefinder(LocalPlayer()) then
                if not CanUseAnyFeature(LocalPlayer()) then
                    surface.PlaySound("common/wpn_denyselect.wav")
                end
                return
            end
            rangefinderActive = not rangefinderActive
            surface.PlaySound("buttons/button14.wav")

            if not rangefinderActive then
                ResetRangefinderLock()
            end

            SetRangefinderBodygroup(LocalPlayer(), rangefinderActive)

            net.Start("ToggleRangefinder")
            net.WriteBool(rangefinderActive)
            net.SendToServer()
        end
    end)

    net.Receive("ToggleRangefinder", function()
        local ply = net.ReadEntity()
        local active = net.ReadBool()
        if IsValid(ply) and ply == LocalPlayer() then
            rangefinderActive = active
            SetRangefinderBodygroup(ply, active)
            if not active then
                ResetRangefinderLock()
            end
        end
    end)

    hook.Add("HUDPaint", "RangefinderOverlay", function()
        if rangefinderActive then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(rangefinderMaterial)
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        end
    end)

    local rangefinderZoomLevel = 1
    local maxRangefinderZoom = 15

    hook.Add("Think", "RangefinderNPCLock", function()
        if not rangefinderActive or not rangefinderLockEnabled then
            if rangefinderLockCandidate or rangefinderLockStart ~= 0 or rangefinderLockedNPC then
                ResetRangefinderLock()
            end
            rangefinderLockKeyWasDown = false
            rangefinderLockConsumePress = false
            return
        end

        local ply = LocalPlayer()
        if not IsValid(ply) then
            ResetRangefinderLock()
            return
        end

        if rangefinderLockedNPC and not IsValid(rangefinderLockedNPC) then
            rangefinderLockedNPC = nil
            rangefinderLockedLostSince = 0
        end

        if IsValid(rangefinderLockedNPC) then
            if IsValidRangefinderNPCTarget(ply, rangefinderLockedNPC) then
                rangefinderLockedLostSince = 0
            else
                if rangefinderLockedLostSince == 0 then
                    rangefinderLockedLostSince = CurTime()
                elseif CurTime() - rangefinderLockedLostSince >= rangefinderLockBreakGraceTime then
                    surface.PlaySound("buttons/combine_button_locked.wav")
                    rangefinderLockedNPC = nil
                    rangefinderLockedLostSince = 0
                end
            end
        end

        if not input.IsKeyDown(RangefinderNPCLockKey or KEY_E) then
            if rangefinderLockKeyWasDown and IsValid(rangefinderLockedNPC) then
                -- If a lock exists and the key was released, arm the next key press to clear the lock.
                rangefinderLockToggleReady = true
            end
            rangefinderLockKeyWasDown = false
            rangefinderLockConsumePress = false
            rangefinderLockCandidate = nil
            rangefinderLockStart = 0
            return
        end

        if not rangefinderLockKeyWasDown then
            rangefinderLockKeyWasDown = true
            if rangefinderLockToggleReady and IsValid(rangefinderLockedNPC) then
                ResetRangefinderLock()
                rangefinderLockConsumePress = true
                surface.PlaySound("buttons/button19.wav")
                return
            end
            rangefinderLockToggleReady = false
        end

        if rangefinderLockConsumePress then
            return
        end

        local target = FindBestRangefinderNPCTarget(ply)

        if not target then
            rangefinderLockCandidate = nil
            rangefinderLockStart = 0
            return
        end

        if target ~= rangefinderLockCandidate then
            rangefinderLockCandidate = target
            rangefinderLockStart = CurTime()
            return
        end

        if CurTime() - rangefinderLockStart >= rangefinderLockHoldTime and rangefinderLockedNPC ~= target then
            rangefinderLockedNPC = target
            rangefinderLockedLostSince = 0
            surface.PlaySound("buttons/lightswitch2.wav")
        end
    end)

    hook.Add("Think", "RangefinderZoomControls", function()
        if rangefinderActive then
            if input.IsKeyDown(KEY_ZOOM) then
                rangefinderZoomLevel = math.min(rangefinderZoomLevel + FrameTime() * 5, maxRangefinderZoom)
            end
            if input.IsKeyDown(KEY_UNZOOM) then
                rangefinderZoomLevel = math.max(rangefinderZoomLevel - FrameTime() * 5, 1)
            end
        end
    end)

    hook.Add("CreateMove", "RangefinderNPCLockAimAssist", function(cmd)
        if not rangefinderLockAimAssist or not rangefinderActive or not rangefinderLockEnabled then
            return
        end

        local ply = LocalPlayer()
        if not IsValid(ply) or not IsValid(rangefinderLockedNPC) then
            return
        end

        if not IsValidRangefinderNPCTarget(ply, rangefinderLockedNPC) then
            return
        end

        local targetPos = rangefinderLockedNPC:WorldSpaceCenter()
        local desiredAngles = (targetPos - ply:EyePos()):Angle()
        cmd:SetViewAngles(desiredAngles)
    end)

    local function DrawZoomLevelIndicator()
        if rangefinderActive then
            local indicatorX = ScrW() * 0.922
            local indicatorY = ScrH() * 0.3
            local indicatorHeight = ScrH() * 0.2
            local stepHeight = indicatorHeight / 8

            -- Draw the ticks and labels
            for i = 0, 8 do
                local y = indicatorY + i * stepHeight
                local tickWidth = (i % 4 == 0) and ScrW() * 0.005 or ScrW() * 0.0025
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawRect(indicatorX, y - 1, tickWidth, 2)

                if i == 0 then
                    draw.SimpleText("200", "StarWarsFont", indicatorX + tickWidth + 5, y, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                elseif i == 8 then
                    draw.SimpleText("0", "StarWarsFont", indicatorX + tickWidth + 5, y, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end

            -- Draw triangle on the zoom indicator
            local zoomFraction = rangefinderZoomLevel / maxRangefinderZoom
            local triangleX = indicatorX - ScrW() * 0.005
            local triangleY = indicatorY + indicatorHeight * (1 - zoomFraction)
            local triangleSize = ScrW() * 0.005
            surface.SetDrawColor(255, 255, 255, 255)
            draw.NoTexture()
            surface.DrawPoly({
                { x = triangleX, y = triangleY - triangleSize },
                { x = triangleX + triangleSize, y = triangleY },
                { x = triangleX, y = triangleY + triangleSize }
            })
        end
    end

    local function DrawWireframeEntitiesInWindow(ply, zoom, w, h)
        cam.Start3D(ply:EyePos(), ply:EyeAngles(), 90 / zoom, 0, 0, w, h)
            for _, ent in ipairs(ents.GetAll()) do
                if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) and ent:Health() > 0 and IsEntityVisibleToOptics(ent, ply) then
                    render.MaterialOverride(wireframeMaterial)
                    render.SetColorModulation(1, 0, 0)
                    ent:DrawModel()
                    render.SetColorModulation(1, 1, 1)
                    render.MaterialOverride(nil)
                end
            end
        cam.End3D()
    end

    local function DrawPlayerViewWindow(x, y, width, height, maskVertices)
        local rtWidth, rtHeight = ScrW(), ScrH()
        local rt = GetRenderTarget(playerViewRTName, rtWidth, rtHeight, false)

        render.PushRenderTarget(rt)
            render.Clear(0, 0, 0, 255, true, true)
            render.RenderView({
                origin = LocalPlayer():EyePos(),
                angles = LocalPlayer():EyeAngles(),
                x = 0,
                y = 0,
                w = rtWidth,
                h = rtHeight,
                fov = 90 / rangefinderZoomLevel,
                drawviewmodel = false
            })
            DrawWireframeEntitiesInWindow(LocalPlayer(), rangefinderZoomLevel, rtWidth, rtHeight)
        render.PopRenderTarget()

        playerViewMaterial:SetTexture("$basetexture", rt)

        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(playerViewMaterial)

        if maskVertices then
            render.SetStencilEnable(true)
            render.ClearStencil()
            render.SetStencilWriteMask(1)
            render.SetStencilTestMask(1)
            render.SetStencilFailOperation(STENCILOPERATION_KEEP)
            render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
            render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
            render.SetStencilReferenceValue(1)

            surface.SetDrawColor(255, 255, 255, 255)
            draw.NoTexture()
            surface.DrawPoly(maskVertices)

            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
            render.SetStencilPassOperation(STENCILOPERATION_KEEP)

            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(playerViewMaterial)
            surface.DrawTexturedRect(x, y, width, height)

            render.SetStencilEnable(false)
        end
    end

    local function DrawCompass()
        if rangefinderActive then
            local compassRadius = ScrH() * 0.03
            local compassX = ScrW() * 0.952
            local compassY = ScrH() * 0.397

            surface.SetDrawColor(0, 0, 0, 150)
            draw.NoTexture()
            surface.DrawCircle(compassX, compassY, compassRadius, Color(0, 0, 0, 150))

            local ply = LocalPlayer()
            local yaw = (-ply:EyeAngles().yaw) % 360

            local directions = {
                { label = "O", angle = 0 },
                { label = "S", angle = 90 },
                { label = "W", angle = 180 },
                { label = "N", angle = 270 }
            }

            for _, dir in ipairs(directions) do
                local angleRad = math.rad(dir.angle - yaw)
                local dirX = compassX + math.cos(angleRad) * compassRadius
                local dirY = compassY + math.sin(angleRad) * compassRadius
                draw.SimpleText(dir.label, "StarWarsFont", dirX, dirY, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            for i = 0, 359, 15 do
                local angleRad = math.rad(i - yaw)
                local tickX = compassX + math.cos(angleRad) * (compassRadius - 5)
                local tickY = compassY + math.sin(angleRad) * (compassRadius - 5)
                local tickEndX = compassX + math.cos(angleRad) * compassRadius
                local tickEndY = compassY + math.sin(angleRad) * compassRadius

                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawLine(tickX, tickY, tickEndX, tickEndY)
            end

            draw.SimpleText(string.format("%.2f�", yaw), "StarWarsFont", compassX, compassY + compassRadius + 15, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Function to calculate "mil" based on distance in meters
    local function CalculateMil(distanceMeters)
        local milTable = {
            { mil = 800, meters = 550 },
            { mil = 1115, meters = 500 },
            { mil = 1270, meters = 400 },
            { mil = 1420, meters = 300 },
            { mil = 1550, meters = 200 },
            { mil = 1640, meters = 150 },
            { mil = 1750, meters = 100 },
            { mil = 1800, meters = 75 },
            { mil = 1975, meters = 30 }
        }

        for i = 1, #milTable - 1 do
            local current = milTable[i]
            local next = milTable[i + 1]

            if distanceMeters <= current.meters and distanceMeters >= next.meters then
                local ratio = (distanceMeters - next.meters) / (current.meters - next.meters)
                return math.Round(next.mil + ratio * (current.mil - next.mil))
            end
        end

    return distanceMeters > 550 and 800 or 1975
    end

    hook.Add("HUDPaint", "PlayerViewWindowOverlay", function()
        if rangefinderActive then
            local windowWidth = ScrW() * 0.475
            local windowHeight = ScrH() * 0.55
            local windowX = (ScrW() - windowWidth) / 2 + ScrW() * 0.28
            local windowY = (ScrH() - windowHeight) / 2 - ScrH() * 0.1

            local topFlat = ScrW() * 0.05
            local bottomFlat = ScrW() * 0.05
            local sideIndent = ScrH() * 0.2
            local leftIndent = ScrW() * 0.02
            local rightIndent = ScrW() * 0.02

            local maskVertices = {
                { x = windowX + (windowWidth / 2) - (topFlat / 2), y = windowY },
                { x = windowX + (windowWidth / 2) + (topFlat / 2), y = windowY },
                { x = windowX + windowWidth - rightIndent, y = windowY + (windowHeight / 2) - (sideIndent / 2) },
                { x = windowX + windowWidth - rightIndent, y = windowY + (windowHeight / 2) + (sideIndent / 2) },
                { x = windowX + (windowWidth / 2) + (bottomFlat / 2), y = windowY + windowHeight },
                { x = windowX + (windowWidth / 2) - (bottomFlat / 2), y = windowY + windowHeight },
                { x = windowX + leftIndent, y = windowY + (windowHeight / 2) + (sideIndent / 2) },
                { x = windowX + leftIndent, y = windowY + (windowHeight / 2) - (sideIndent / 2) },
            }

            DrawPlayerViewWindow(windowX, windowY, windowWidth, windowHeight, maskVertices)

            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(rangefinderMaterial)
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

            DrawZoomLevelIndicator()

            DrawCompass()

            local trace = LocalPlayer():GetEyeTrace()
            if trace.HitPos then
                local distanceUnits = math.Round(trace.HitPos:Distance(LocalPlayer():GetPos()))
                local distanceMeters = distanceUnits * 0.025
                local distanceInches = distanceUnits * 0.75
                local milValue = CalculateMil(distanceMeters)

                local screenPos = trace.HitPos:ToScreen()

                draw.SimpleText(tostring(distanceUnits) .. " Units", "StarWarsFont", screenPos.x + ScrW() * 0.1, screenPos.y - ScrH() * 0.05, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                draw.SimpleText(string.format("%.2f m", distanceMeters), "StarWarsFont", screenPos.x + ScrW() * 0.1, screenPos.y - ScrH() * 0.04, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                draw.SimpleText(string.format("(%.1f in)", distanceInches), "StarWarsFont", screenPos.x + ScrW() * 0.1, screenPos.y - ScrH() * 0.03, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                draw.SimpleText(string.format("Mil: %d", milValue), "StarWarsFont", screenPos.x + ScrW() * 0.1, screenPos.y - ScrH() * 0.02, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            local targetX = windowX + windowWidth / 2
            local targetY = windowY + windowHeight / 2
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(targetX - 2, targetY - 2, 4, 4)

            if IsValid(rangefinderLockedNPC) then
                local lockDistanceMeters = math.Round(rangefinderLockedNPC:GetPos():Distance(LocalPlayer():GetPos()) * 0.025)
                draw.SimpleText("LOCK: " .. string.upper(rangefinderLockedNPC:GetClass()), "StarWarsFont", targetX, targetY + ScrH() * 0.05, Color(255, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(string.format("%dm", lockDistanceMeters), "StarWarsFont", targetX, targetY + ScrH() * 0.08, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif rangefinderLockEnabled and input.IsKeyDown(RangefinderNPCLockKey or KEY_E) and IsValid(rangefinderLockCandidate) and rangefinderLockStart > 0 then
                local progress = math.Clamp((CurTime() - rangefinderLockStart) / rangefinderLockHoldTime, 0, 1)
                draw.SimpleText(string.format("Aufschalten... %d%%", math.Round(progress * 100)), "StarWarsFont", targetX, targetY + ScrH() * 0.05, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end)

    hook.Add("Think", "SunvisorControls", function()
        if vgui.GetKeyboardFocus() then return end

        -- wieder nur KEY_TOGGLE wie im ursprünglichen Script
        if input.IsKeyDown(KEY_TOGGLE) and CurTime() - lastCustomOverlayPress > 0.5 then
            lastCustomOverlayPress = CurTime()
            if not CanUseSunvisor(LocalPlayer()) then
                if not CanUseAnyFeature(LocalPlayer()) then
                    surface.PlaySound("common/wpn_denyselect.wav")
                end
                return
            end
            customOverlayActive = not customOverlayActive
            surface.PlaySound("buttons/button14.wav")
        end
    end)

    hook.Add("HUDPaint", "SunvisorOverlay", function()
        if not customOverlayActive then return end

        -- nur rote Tönung (keine externe Textur -> kein Missing Texture)
        surface.SetDrawColor(255, 0, 0, 80)
        surface.DrawRect(0, 0, ScrW(), ScrH())

        local observer = LocalPlayer()
        if not IsValid(observer) then
            return
        end

        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent)
                and (ent:IsPlayer() or ent:IsNPC())
                and ent:Health() > 0
                and ent ~= observer
                and IsEntityVisibleToOptics(ent, observer)
                and IsLineOfSightClearToEntity(observer, ent) then
                DrawEntitySunvisorHitbox(ent, observer)
            end
        end
    end)

end
