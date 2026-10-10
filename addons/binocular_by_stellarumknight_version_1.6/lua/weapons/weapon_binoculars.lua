local BINO_W_MAT = CLIENT and Material("binoculars/binocular_w") or nil -- Performance: einmal laden statt jeden Frame
if SERVER then
    AddCSLuaFile()
end

SWEP.PrintName = "Binoculars"
SWEP.Author = "Stellarumknight"
SWEP.Instructions = "Secondary: Hochnehmen/Overlay\nZoom wie gewohnt"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Category = "Stellarums Star Wars RP"

SWEP.ViewModel = "" -- Kein ViewModel, damit keine falsche Waffe angezeigt wird
SWEP.WorldModel = "models/weapons/w_nvbinoculars.mdl" -- Optional: eigenes Modell
SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

if CLIENT then
    include("autorun/config.lua")

    local function setupHoloFonts()
        local size = math.max(22, ScreenScale(18))
        surface.CreateFont("SW_HoloDigits", {
            font = SYMUI and SYMUI.FontFace("body") or "Arial",
            size = size,
            weight = 800,
            italic = true,
            extended = true,
            antialias = true
        })
        surface.CreateFont("SW_HoloDigitsGlow", {
            font = SYMUI and SYMUI.FontFace("body") or "Arial",
            size = size,
            weight = 800,
            italic = true,
            extended = true,
            antialias = true,
            blursize = math.max(3, math.floor(size * 0.18))
        })
        surface.CreateFont("SW_HoloDigitsSmall", {
            font = SYMUI and SYMUI.FontFace("body") or "Arial",
            size = math.max(18, ScreenScale(14)),
            weight = 800,
            italic = true,
            extended = true,
            antialias = true
        })
        surface.CreateFont("SW_HoloDigitsGlowSmall", {
            font = SYMUI and SYMUI.FontFace("body") or "Arial",
            size = math.max(18, ScreenScale(14)),
            weight = 800,
            italic = true,
            extended = true,
            antialias = true,
            blursize = math.max(2, math.floor(math.max(18, ScreenScale(14)) * 0.2))
        })

        -- Aurabesh removed: do not create SW_Aurabesh / SW_Aurabesh* fonts here
    end
    setupHoloFonts()
    hook.Add("OnScreenSizeChanged", "WeaponBinocularsRefreshFonts", setupHoloFonts)

    local holoDigitColor = Color(0, 255, 180, 255)
    local holoDigitGlow = Color(0, 170, 140, 180)

    local function drawStarWarsDigits(x, y, w, h, value)
        local text = string.format("%03d", value)
        local cx = x + w * 0.5
        local cy = y + h * 0.4
        draw.SimpleText(text, "SW_HoloDigitsGlow", cx, cy, holoDigitGlow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(text, "SW_HoloDigits", cx, cy, holoDigitColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local compassSpan = 120
    local compassTickStep = 5
    local cardinalPoints = {
        { label = "N", angle = 0 },
        { label = "E", angle = 90 },
        { label = "S", angle = 180 },
        { label = "W", angle = 270 }
    }
    local function drawPerspectiveCompass(x, y, w, h, heading)
        surface.SetDrawColor(4, 12, 16, 215)
        surface.DrawRect(x, y, w, h)
        surface.SetDrawColor(0, 255, 150, 42)
        surface.DrawRect(x, y, w, h * 0.12)
        surface.SetDrawColor(0, 40, 28, 180)
        surface.DrawRect(x, y + h - h * 0.18, w, h * 0.18)
        surface.SetDrawColor(255, 255, 255, 12)
        surface.DrawRect(x, y + h * 0.46, w, h * 0.1)

        local centerX = x + w * 0.5
        local tickColor = Color(0, 255, 150)
        local cardinalGlow = Color(0, 70, 55)
        local cardinalText = Color(225, 255, 240)
        local bearingGlow = Color(20, 50, 45)
        local bearingText = Color(191, 173, 189)
        local cardinalFont = aurabeshSmall
        local shadowOffsetX = ScrW() * 0.001
        local shadowOffsetY = ScrH() * 0.0013

        for delta = -compassSpan, compassSpan, compassTickStep do
            local normalized = delta / compassSpan
            local eased = math.sin(normalized * (math.pi * 0.5))
            local depth = math.max(math.cos(normalized * (math.pi * 0.5)), 0)
            local offsetX = eased * (w * 0.45)
            local tickHeight = h * (0.18 + 0.38 * depth)
            local tickWidth = (delta % 15 == 0) and ScrW() * 0.0012 or ScrW() * 0.0006
            surface.SetDrawColor(ColorAlpha(tickColor, 50 + 150 * depth))
            surface.DrawRect(centerX + offsetX - tickWidth * 0.5, y + (h - tickHeight) * 0.5, tickWidth, tickHeight)

            if delta % 15 == 0 then
                local worldHeading = (heading + delta + 360) % 360
                for _, data in ipairs(cardinalPoints) do
                    if math.abs(math.AngleDifference(worldHeading, data.angle)) < 4 then
                        local textX = centerX + offsetX
                        local textY = y + h * 0.28
                        -- Aurabesh removed: draw cardinal with standard font + slight shadow
                        draw.SimpleText(data.label, (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), textX + shadowOffsetX, textY + shadowOffsetY, ColorAlpha(cardinalGlow, 140 + 80 * depth), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        draw.SimpleText(data.label, (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), textX, textY, ColorAlpha(cardinalText, 200 + 60 * depth), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end
        end

        draw.NoTexture()
        surface.SetDrawColor(245, 120, 20, 255)
        surface.DrawPoly({
            { x = centerX, y = y + h + ScrH() * 0.0021 },
            { x = centerX - ScrW() * 0.0031, y = y + h - ScrH() * 0.0065 },
            { x = centerX + ScrW() * 0.0031, y = y + h - ScrH() * 0.0065 }
        })
        surface.DrawRect(centerX - ScrW() * 0.0005, y + h * 0.14, ScrW() * 0.001, h * 0.68)
    end

    local function getKeyZoom() return _G.KEY_ZOOM or KEY_B end
    local function getKeyUnzoom() return _G.KEY_UNZOOM or KEY_G end

    hook.Add("CalcView", "WeaponBinocularsCalcView", function(ply, origin, angles, fov, znear, zfar)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_binoculars" and wep.binocularActive then
            fov = 90 / (1 + wep.zoomLevel)
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

    function SWEP:DrawHUD()
        if not self.binocularActive then return end

        -- ...existing overlay base...
        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(BINO_W_MAT)
        surface.DrawTexturedRect(0,0,ScrW(),ScrH())

        -- Zoom-Leiste (links, vertikal, Striche übereinander)
        local zoom = self.zoomLevel or 0
        local leftX = ScrW() * 0.06
        local barTop = ScrH() * 0.18
        local barBottom = ScrH() * 0.82
        local barH = barBottom - barTop
        local ticks = 12
        for i = 0, ticks do
            local frac = i / ticks
            local y = barTop + frac * barH
            local tickW = ScrW() * 0.003
            surface.SetDrawColor(191,173,189,255)
            surface.DrawRect(leftX - tickW / 2, y - 1, tickW, 2)
        end
        draw.SimpleText("ZOOM", "StarWarsFont", leftX, barTop - 18, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Pfeil am aktuellen Zoom-Level
        local zoomFraction = math.Clamp(zoom / 30, 0, 1)
        local desiredArrowY = barBottom - zoomFraction * barH
        self._arrowY = self._arrowY and Lerp(FrameTime() * 12, self._arrowY, desiredArrowY) or desiredArrowY
        local arrowY = self._arrowY
        local arrowTipX = leftX + ScrW() * 0.014
        local arrowBaseX = leftX - ScrW() * 0.004
        local arrowHalfHeight = ScrH() * 0.017

        draw.NoTexture()
        surface.SetDrawColor(0, 0, 0, 210)
        surface.DrawPoly({
            { x = arrowTipX + 1, y = arrowY + 1 },
            { x = arrowBaseX + 1, y = arrowY - arrowHalfHeight + 1 },
            { x = arrowBaseX + 1, y = arrowY + arrowHalfHeight + 1 }
        })

        surface.SetDrawColor(245, 120, 20, 255)
        surface.DrawPoly({
            { x = arrowTipX, y = arrowY },
            { x = arrowBaseX, y = arrowY - arrowHalfHeight },
            { x = arrowBaseX, y = arrowY + arrowHalfHeight }
        })

        surface.DrawRect(leftX - ScrW() * 0.007, arrowY - 1, ScrW() * 0.014, 2)

        -- Perspektivischer Kompass
        local yaw = LocalPlayer():EyeAngles().yaw
        local heading = (360 - (yaw % 360)) % 360
        local compW = ScrW() * 0.18
        local compH = ScrH() * 0.045
        local compX = (ScrW() - compW) * 0.5
        local compY = ScrH() * 0.098

        drawPerspectiveCompass(compX, compY, compW, compH, heading)

        local headingBoxY = compY + compH + ScrH() * 0.004
        local headingBoxH = ScrH() * 0.015
        local headingBoxW = ScrW() * 0.052
        draw.RoundedBox(4, compX + compW * 0.5 - headingBoxW * 0.5, headingBoxY, headingBoxW, headingBoxH, Color(6, 16, 14, 215))
        draw.SimpleText("HDG", (SYMUI and SYMUI.F("DermaDefaultBold") or "DermaDefaultBold"), compX + compW * 0.5, headingBoxY + headingBoxH * 0.42, Color(0, 255, 150, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%03d", math.floor(heading + 0.5)), "SW_HoloDigitsGlowSmall", compX + compW * 0.5, headingBoxY + headingBoxH + ScrH() * 0.006, ColorAlpha(holoDigitGlow, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%03d", math.floor(heading + 0.5)), "SW_HoloDigitsSmall", compX + compW * 0.5, headingBoxY + headingBoxH + ScrH() * 0.006, ColorAlpha(holoDigitColor, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Unten Mitte: drei 3-stellige Zahlen (000-999)
        local trace = LocalPlayer():GetEyeTrace()
        local distUnits = 0
        if trace.HitPos then
            distUnits = math.Round(trace.HitPos:Distance(LocalPlayer():GetPos()))
        end
        local rangeMeters = math.Clamp(math.floor(distUnits * 0.025 + 0.5), 0, 999) -- 000-999
        local zoomValue = math.Clamp(math.floor((zoom or 0) * 10 + 0.5), 0, 999)
        local pitchValue = math.Clamp(math.floor((math.NormalizeAngle(LocalPlayer():EyeAngles().pitch) + 360) % 360), 0, 999)

        local boxW = ScrW() * 0.06
        local boxH = ScrH() * 0.05
        local boxGap = 0
        local totalW = boxW * 3 + boxGap * 2
        local startX = (ScrW() - totalW) / 2 - ScrW() * 0.055
        local startY = ScrH() * 0.78

        local function drawBox(x, y, w, h, value, label)
            local corner = math.min(w, h) * 0.18
            local panel = {
                { x = x + corner, y = y },
                { x = x + w - corner, y = y },
                { x = x + w, y = y + corner },
                { x = x + w, y = y + h - corner },
                { x = x + w - corner, y = y + h },
                { x = x + corner, y = y + h },
                { x = x, y = y + h - corner },
                { x = x, y = y + corner }
            }

            draw.NoTexture()
            surface.SetDrawColor(10, 22, 16, 220)
            surface.DrawPoly(panel)
            surface.SetDrawColor(0, 255, 150, 20)
            surface.DrawPoly(panel)

            surface.SetDrawColor(0, 255, 150, 190)
            for i = 1, #panel do
                local p1, p2 = panel[i], panel[(i % #panel) + 1]
                surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
            end

            surface.SetDrawColor(0, 255, 150, 65)
            surface.DrawLine(x + w * 0.12, y + h * 0.28, x + w * 0.88, y + h * 0.28)
            surface.DrawLine(x + w * 0.12, y + h * 0.63, x + w * 0.88, y + h * 0.63)

            drawStarWarsDigits(x, y, w, h, value)

            draw.SimpleTextOutlined(label, (SYMUI and SYMUI.F("DermaDefaultBold") or "DermaDefaultBold"), x + w * 0.5, y + h * 0.75, Color(0, 255, 150, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(5, 24, 18, 220))
        end

        drawBox(startX, startY, boxW, boxH, rangeMeters, "RANGE")
        drawBox(startX + boxW + boxGap, startY, boxW, boxH, zoomValue, "ZOOM")
        drawBox(startX + (boxW + boxGap) * 2, startY, boxW, boxH, pitchValue, "PCH")

        -- Rechts daneben zwei kleine Textzeilen (Beschreibung der drei Felder)
        local descX = startX + totalW + ScrW() * 0.012
        local descY = startY + boxH * 0.06 - ScrH() * 0.022
        local infoPanelW = ScrW() * 0.099
        local infoPanelH = ScrH() * 0.032
        local infoGap = 0

        local function drawInfoPanel(x, y, text)
            draw.NoTexture()
            surface.SetDrawColor(10, 22, 16, 220)
            surface.DrawRect(x, y, infoPanelW, infoPanelH)
            surface.SetDrawColor(0, 255, 150, 20)
            surface.DrawRect(x + 1, y + 1, infoPanelW - 2, infoPanelH - 2)
            surface.SetDrawColor(0, 255, 150, 160)
            surface.DrawOutlinedRect(x, y, infoPanelW, infoPanelH)
            draw.SimpleText(text, (SYMUI and SYMUI.F("DermaDefault") or "DermaDefault"), x + ScrW() * 0.008, y + infoPanelH * 0.5, Color(0,255,150,230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        drawInfoPanel(descX, descY, "Range: Entfernung in Metern")
        drawInfoPanel(descX, descY + infoPanelH + infoGap, "Zoom: Vergrößerung x10   Pch: Blickneigung (Grad)")
    end

    function SWEP:AdjustFOV()
    end

    function SWEP:Think()
        if not self:IsValid() or not self.Owner or not self.Owner:IsPlayer() then return end
        if not self.Owner:KeyDown(IN_ATTACK2) then self.SecondaryPressed = false end

        if input.IsMouseDown(MOUSE_RIGHT) then
            if not self.SecondaryPressed then
                self.SecondaryPressed = true
                self.binocularActive = not self.binocularActive
            end
        else
            self.SecondaryPressed = false
        end

        if self.binocularActive and LocalPlayer():GetActiveWeapon() == self then
            if not self.zoomLevel then self.zoomLevel = 0 end
            if input.IsKeyDown(getKeyZoom()) then
                self.zoomLevel = math.min(self.zoomLevel + FrameTime() * 5, 30)
            end
            if input.IsKeyDown(getKeyUnzoom()) then
                self.zoomLevel = math.max(self.zoomLevel - FrameTime() * 5, 0)
            end
        else
            self.zoomLevel = self.zoomLevel or 0
        end
    end

    function SWEP:Holster()
        self.binocularActive = false
        self.zoomLevel = 0
        self._arrowY = nil
        return true
    end

    function SWEP:OnRemove()
        self:Holster()
        self._arrowY = nil
    end
end

function SWEP:PrimaryAttack()

end
