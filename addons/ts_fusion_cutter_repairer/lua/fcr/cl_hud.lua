FCR = FCR or {}
FCR.Runtime = FCR.Runtime or {}

local C = FCR.Config
local Util = FCR.Util
local Runtime = FCR.Runtime
local L = FCR.L

Runtime.HUDFade = Runtime.HUDFade or 0
Runtime.LastHUDSnapshot = Runtime.LastHUDSnapshot or nil

local function getRuntimeAttempts(ent)
    local active = Runtime.ActiveSession
    if not active or not active.vehicle then return C.MaxAttempts end
    if active.vehicle.entIndex ~= ent:EntIndex() then return C.MaxAttempts end
    return active.attemptsLeft or C.MaxAttempts
end

local function getActiveRepairTarget(ply)
    if not C.HUD.Enabled or not IsValid(ply) then return end
    local wep = ply:GetActiveWeapon()
    if not Util.IsRepairTool(wep) then return end

    local tr = Util.GetTargetTrace(ply, (C.RepairDistance or 0) + (C.RepairRangeGrace or 0))
    local ent = Util.ResolveRepairEntity(tr.Entity)
    if not Util.IsSupportedVehicle(ent) then return end

    local current, max = Util.GetVehicleHealth(ent)
    if max <= 0 or current >= max then return end

    return ent, current, max
end

local function getIntegrityStyle(pct)
    local col = C.Colors
    if pct <= 0.28 then
        return col.Danger, L("hud_state_critical")
    elseif pct <= 0.65 then
        return col.Warm, L("hud_state_damaged")
    end

    return col.Success, L("hud_state_stable")
end

local function withAlpha(col, a)
    return Color(col.r, col.g, col.b, a)
end

local function drawCoreIcon(x, y, size, accent, fade)
    local col = C.Colors
    local cx, cy = math.floor(x + size * 0.5), math.floor(y + size * 0.5)
    local r = math.floor(size * 0.22)

    surface.SetDrawColor(withAlpha(col.Surface, math.floor(235 * fade)))
    surface.DrawRect(x, y, size, size)
    surface.SetDrawColor(withAlpha(col.Stroke, math.floor(col.Stroke.a * fade)))
    surface.DrawOutlinedRect(x, y, size, size, 1)

    -- Eckmarkierungen
    local c = 6
    surface.SetDrawColor(withAlpha(accent, math.floor(220 * fade)))
    surface.DrawRect(x, y, c, 1)
    surface.DrawRect(x, y, 1, c)
    surface.DrawRect(x + size - c, y + size - 1, c, 1)
    surface.DrawRect(x + size - 1, y + size - c, 1, c)

    draw.NoTexture()
    surface.DrawCircle(cx, cy, r + 6, accent.r, accent.g, accent.b, math.floor(110 * fade))
    surface.DrawCircle(cx, cy, r, col.Text.r, col.Text.g, col.Text.b, math.floor(220 * fade))
    surface.SetDrawColor(withAlpha(accent, math.floor(230 * fade)))
    surface.DrawRect(cx - r - 9, cy, 6, 1)
    surface.DrawRect(cx + r + 4, cy, 6, 1)
    surface.DrawRect(cx, cy - r - 9, 1, 6)
    surface.DrawRect(cx, cy + r + 4, 1, 6)
    surface.DrawRect(cx - 1, cy - 1, 3, 3)
end

hook.Add("HUDPaint", "FCR.DrawWeaponHUD", function()
    local ply = LocalPlayer()
    local ent, current, max = getActiveRepairTarget(ply)
    local targetVisible = IsValid(ent)
    if targetVisible then
        Runtime.LastHUDSnapshot = { ent = ent, current = current, max = max }
    end

    Runtime.HUDFade = Lerp(FrameTime() * (C.HUD.FadeSpeed or 8), Runtime.HUDFade or 0, targetVisible and 1 or 0)
    local fade = Runtime.HUDFade or 0
    if fade <= 0.01 then return end

    local snap = Runtime.LastHUDSnapshot
    if not targetVisible then
        if not snap or not IsValid(snap.ent) then return end
        ent, current, max = snap.ent, snap.current, snap.max
    end

    local width = C.HUD.Width
    local height = C.HUD.Height
    local x = math.floor((ScrW() * 0.5) - (width * 0.5))
    local y = math.floor(ScrH() - C.HUD.OffsetY - height)

    local col = C.Colors
    local pct = math.Clamp(max > 0 and current / max or 0, 0, 1)
    local integrityCol, stateText = getIntegrityStyle(pct)
    local protocolCol = pct >= 1 and col.Dim or col.Warm
    local protocolText = pct >= 1 and L("hud_protocol_locked") or L("hud_protocol_available")
    local attempts = getRuntimeAttempts(ent)
    local alpha = math.floor(245 * fade)

    -- Panel
    surface.SetDrawColor(withAlpha(col.BgSoft, math.floor(220 * fade)))
    surface.DrawRect(x, y, width, height)
    surface.SetDrawColor(withAlpha(col.Stroke, math.floor(col.Stroke.a * fade)))
    surface.DrawOutlinedRect(x, y, width, height, 1)
    surface.SetDrawColor(withAlpha(col.Warm, alpha))
    surface.DrawRect(x, y, 64, 2)
    surface.DrawRect(x, y + 10, 2, height - 22)

    drawCoreIcon(x + 14, y + 14, 44, col.Warm, fade)

    local textX = x + 70
    draw.SimpleText(Util.GetVehicleLabel(ent), "FCR.HUDTitle", textX, y + 10, withAlpha(col.Text, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(L("hud_protocol_word") .. " " .. protocolText, "FCR.HUDTiny", textX, y + 36, withAlpha(protocolCol, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local rightX = x + width - 14
    draw.SimpleText(stateText, "FCR.HUDValue", rightX, y + 10, withAlpha(integrityCol, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    draw.SimpleText(string.format(L("hud_integrity_short"), pct * 100), "FCR.HUDBody", rightX, y + 34, withAlpha(col.TextSoft, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    local bottomY = y + 56
    local attemptsLabel = L("hud_attempts")
    draw.SimpleText(attemptsLabel, "FCR.HUDTiny", textX, bottomY, withAlpha(col.Muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    surface.SetFont("FCR.HUDTiny")
    local labelW = surface.GetTextSize(attemptsLabel)
    local chipX = textX + labelW + 8
    for i = 1, C.MaxAttempts do
        local cx = chipX + (i - 1) * 13
        if i <= attempts then
            surface.SetDrawColor(withAlpha(col.Warm, math.floor(230 * fade)))
            surface.DrawRect(cx, bottomY + 2, 8, 8)
        else
            surface.SetDrawColor(withAlpha(col.StrokeStrong, math.floor(col.StrokeStrong.a * fade)))
            surface.DrawOutlinedRect(cx, bottomY + 2, 8, 8, 1)
        end
    end

    draw.SimpleText(Util.GetVehicleBaseId(ent), "FCR.HUDValue", rightX, bottomY - 4, withAlpha(col.Warm, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    -- Integritätsbalken
    local barX, barY, barW = x + 1, y + height - 3, width - 2
    surface.SetDrawColor(withAlpha(col.Stroke, math.floor(col.Stroke.a * fade)))
    surface.DrawRect(barX, barY, barW, 2)
    surface.SetDrawColor(withAlpha(integrityCol, alpha))
    surface.DrawRect(barX, barY, math.floor(barW * pct), 2)
end)
