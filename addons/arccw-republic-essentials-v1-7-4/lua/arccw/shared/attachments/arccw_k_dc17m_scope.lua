att.PrintName = "DC-17m Sniper Scope"
att.Icon = Material("entities/arccw/kraken/atts/dc17mscope.png", "mips smooth")
att.AbbrevName = "DC-17m Sniper Scope"
att.Description = [[Republic Commando sniper optic with holographic HUD, rotating acquisition rings, Aurebesh data feeds, target identification, health readout, rangefinder, variable 2-20X magnification.]]
att.SortOrder = 6

att.AutoStats = true
att.Free = true

att.Slot = "kraken_holohud"

att.Model = "models/arccw/kraken/republic/atts/w_dc17m_scope.mdl"
att.ModelOffset = Vector(8, 0, 0)

att.AdditionalSights = {
    {
        Pos = Vector(0, -50, 0),
        Ang = Angle(0, 0, 0),
        Magnification = 1,
        ViewModelFOV = 45,
        ScrollFunc = ArcCW.SCROLL_ZOOM,
        ZoomLevels = 5,
        ZoomSound = "arccw/kraken/interaction/zoom-in.wav",
    }
}
att.Mult_SightTime = 1.08
att.Mult_SightedSpeedMult = 0.92

att.Holosight = true
att.HolosightMagnification = 20
att.HolosightMagnificationMin = 2
att.HolosightMagnificationMax = 20
att.HolosightNoFlare = true
att.HolosightReticle = nil
att.HolosightSize = 0

if CLIENT then
    local _aurebeshFont = "Aurebesh"

    surface.CreateFont("_KrakenAureTest", { font = "Aurebesh", size = 14, weight = 500 })
    surface.CreateFont("_KrakenFallTest", { font = SYMUI and SYMUI.FontFace("body") or "Trebuchet MS", size = 14, weight = 500 })

    timer.Simple(0, function()
        surface.SetFont("_KrakenAureTest")
        local aw = surface.GetTextSize("ABCDEFGHIJ")
        if not aw or aw < 10 then
            _aurebeshFont = "Trebuchet MS"
        end
        surface.CreateFont("KrakenAurebesh_Large",  { font = _aurebeshFont, size = 24, weight = 500, antialias = true, additive = true })
        surface.CreateFont("KrakenAurebesh_Small",  { font = _aurebeshFont, size = 16, weight = 500, antialias = true, additive = true })
        surface.CreateFont("KrakenAurebesh_Tiny",   { font = _aurebeshFont, size = 12, weight = 400, antialias = true, additive = true })
        surface.CreateFont("KrakenAurebesh_Micro",  { font = _aurebeshFont, size = 10, weight = 400, antialias = true, additive = true })
    end)

    surface.CreateFont("KrakenAurebesh_Large",  { font = _aurebeshFont, size = 24, weight = 500, antialias = true, additive = true })
    surface.CreateFont("KrakenAurebesh_Small",  { font = _aurebeshFont, size = 16, weight = 500, antialias = true, additive = true })
    surface.CreateFont("KrakenAurebesh_Tiny",   { font = _aurebeshFont, size = 12, weight = 400, antialias = true, additive = true })
    surface.CreateFont("KrakenAurebesh_Micro",  { font = _aurebeshFont, size = 10, weight = 400, antialias = true, additive = true })
    surface.CreateFont("KrakenRC_Mag",      { font = SYMUI and SYMUI.FontFace("body") or "Trebuchet MS", size = 22, weight = 700, antialias = true, additive = true })
    surface.CreateFont("KrakenRC_Ammo",     { font = SYMUI and SYMUI.FontFace("body") or "Trebuchet MS", size = 10, weight = 600, antialias = true, additive = true })
    surface.CreateFont("KrakenRC_Data",     { font = SYMUI and SYMUI.FontFace("body") or "Trebuchet MS", size = 12, weight = 600, antialias = true, additive = true })
    surface.CreateFont("KrakenRC_DataBig",  { font = SYMUI and SYMUI.FontFace("body") or "Trebuchet MS", size = 15, weight = 700, antialias = true, additive = true })

    local function DrawLabelValue(x, y, sc, labelFont, labelText, labelCol, valFont, valText, valCol, gap)
        gap = gap or (4 * sc)
        surface.SetFont(labelFont)
        surface.SetTextColor(labelCol)
        local lw, lh = surface.GetTextSize(labelText)
        surface.SetTextPos(x, y)
        surface.DrawText(labelText)
        if valFont and valText then
            surface.SetFont(valFont)
            surface.SetTextColor(valCol)
            surface.SetTextPos(x + lw + gap, y)
            surface.DrawText(valText)
        end
        return y + lh + 2 * sc
    end

    att.Hook_DrawHUD = function(wep)
        local H = KrakenHoloHUD
        if not H then return end

        local a, sw, sh, cx, cy, sc = H.SightCheck(wep)
        if not a then return end

        local col = H.Col
        local floor, clamp = math.floor, math.Clamp
        local cos, sin, rad = math.cos, math.sin, math.rad
        local fmod = math.fmod
        local t = CurTime()
        local flk = H.HoloFlicker(1)

        local cLine    = Color(180, 200, 215, floor(80 * a * flk))
        local cReticle = Color(190, 200, 210, floor(140 * a * flk))
        local cBlue    = Color(70, 145, 210, floor(180 * a * flk))
        local cBlueBr  = Color(110, 185, 245, floor(255 * a * flk))
        local cCyan    = Color(80, 190, 230, floor(200 * a * flk))
        local cCyanDim = Color(60, 150, 200, floor(60 * a * flk))
        local cAure    = Color(70, 160, 220, floor(160 * a * flk))
        local cAureDim = Color(55, 130, 190, floor(80 * a * flk))
        local cWarn    = Color(255, 80, 80, floor(255 * a))

        local R = 320 * sc
        local ringThick = 36
        local ringInner = R - ringThick

        render.ClearStencil()
        render.SetStencilEnable(true)
        render.SetStencilWriteMask(1)
        render.SetStencilTestMask(1)
        render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
        render.SetStencilPassOperation(STENCILOPERATION_KEEP)
        render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
        render.SetStencilReferenceValue(1)
        draw.NoTexture()
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawPoly(H.GetCirclePoly(cx, cy, R + ringThick * 0.5, 64))
        render.SetStencilFailOperation(STENCILOPERATION_KEEP)
        render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)
        render.SetStencilReferenceValue(1)
        surface.SetDrawColor(5, 12, 20, floor(248 * a))
        surface.DrawRect(0, 0, sw, sh)
        render.SetStencilEnable(false)

        H.DrawDashedCircle(cx, cy, R + 8*sc, 48, 0.45, t * 6, cCyanDim)

        for i = 0, ringThick - 1 do
            local frac = i / ringThick
            local ga = (1 - frac * frac) * 0.50 * flk
            local c = Color(75, 155, 225, floor(255 * ga * a))
            H.DrawCircleOutline(cx, cy, R - i, 96, c)
        end
        H.DrawCircleOutline(cx, cy, R, 96, Color(120, 195, 255, floor(110 * a * flk)))

        H.DrawTickRing(cx, cy, ringInner - 4*sc, 72, 3*sc, rad(-t * 5), cCyanDim)
        H.DrawDashedCircle(cx, cy, ringInner - 10*sc, 28, 0.5, -t * 3.5, cCyanDim)

        local textDrift = fmod(t * 1.8, 360)
        H.DrawCurvedText("dc seventeen m sniper module", "KrakenAurebesh_Tiny",
            cx, cy, ringInner - 16*sc,
            -160 + textDrift * 0.25, -20 + textDrift * 0.25, cAure)
        H.DrawCurvedText("republic commando", "KrakenAurebesh_Micro",
            cx, cy, ringInner - 28*sc,
            25 - textDrift * 0.15, 155 - textDrift * 0.15, cAureDim)
        H.DrawCurvedText("classified", "KrakenAurebesh_Micro",
            cx, cy, ringInner - 40*sc,
            -50, -20, Color(55, 130, 190, floor(50 * a * flk)))

        local retR = 35 * sc
        surface.SetDrawColor(cLine)
        surface.DrawLine(cx - ringInner + 14*sc, cy, cx - retR - 3*sc, cy)
        surface.DrawLine(cx + retR + 3*sc, cy, cx + ringInner - 14*sc, cy)
        surface.DrawLine(cx, cy - ringInner + 14*sc, cx, cy - retR - 3*sc)
        surface.DrawLine(cx, cy + retR + 3*sc, cx, cy + ringInner * 0.40)

        surface.SetDrawColor(Color(160, 175, 190, floor(45 * a * flk)))
        local tickStart = retR + 18*sc
        local tickSpacing = 28 * sc
        for i = 0, 6 do
            local tx = tickStart + i * tickSpacing
            local major = (i % 2 == 0)
            local th = major and 4*sc or 2*sc
            if cx - tx > cx - ringInner + 20*sc then
                surface.DrawLine(cx - tx, cy - th, cx - tx, cy + th)
            end
            if cx + tx < cx + ringInner - 20*sc then
                surface.DrawLine(cx + tx, cy - th, cx + tx, cy + th)
            end
        end

        H.DrawCircleOutline(cx, cy, retR, 48, cReticle)
        local crossLen = retR * 0.55
        local crossGap = 4 * sc
        surface.SetDrawColor(cReticle)
        surface.DrawLine(cx - crossLen, cy, cx - crossGap, cy)
        surface.DrawLine(cx + crossGap, cy, cx + crossLen, cy)
        surface.DrawLine(cx, cy - crossLen, cx, cy - crossGap)
        surface.DrawLine(cx, cy + crossGap, cx, cy + crossLen)
        H.DrawDot(cx, cy, 1.2*sc, Color(180, 200, 220, floor(180 * a * flk)))

        local ent, dist = H.GetAimTarget(wep)
        local meters = dist * 0.01905

        local tX = cx - R * 0.55
        local tY = cy - R * 0.55
        local rowY = tY

        surface.SetFont("KrakenAurebesh_Small")
        surface.SetTextColor(cAure)
        local hdW, hdH = surface.GetTextSize("target data")
        surface.SetTextPos(tX, rowY)
        surface.DrawText("target data")
        rowY = rowY + hdH + 2*sc

        surface.SetDrawColor(cCyanDim)
        surface.DrawLine(tX, rowY, tX + hdW + 20*sc, rowY)
        rowY = rowY + 5*sc

        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
            local hp = ent:Health()
            local maxHp = ent:GetMaxHealth()
            local hpFrac = clamp(hp / math.max(maxHp, 1), 0, 1)
            local name = ent:IsPlayer() and ent:Nick() or (ent.PrintName or ent:GetClass())
            if #name > 20 then name = name:sub(1, 18) .. ".." end

            rowY = DrawLabelValue(tX, rowY, sc,
                "KrakenAurebesh_Micro", "id", cAureDim,
                "KrakenRC_Data", name, cBlueBr)

            local classStr = ent:IsPlayer() and "HOSTILE" or (ent:IsNPC() and "NPC" or "DROID")
            rowY = DrawLabelValue(tX, rowY, sc,
                "KrakenAurebesh_Micro", "class", cAureDim,
                "KrakenRC_Data", classStr, cCyan)

            surface.SetFont("KrakenAurebesh_Micro")
            surface.SetTextColor(cAureDim)
            local hlW, hlH = surface.GetTextSize("health")
            surface.SetTextPos(tX, rowY)
            surface.DrawText("health")
            rowY = rowY + hlH + 2*sc

            local barW, barH = 90*sc, 5*sc
            surface.SetDrawColor(10, 25, 40, floor(120 * a))
            surface.DrawRect(tX, rowY, barW, barH)
            surface.SetDrawColor(cCyanDim)
            surface.DrawOutlinedRect(tX, rowY, barW, barH)
            local barCol = hpFrac > 0.5 and cBlue
                or (hpFrac > 0.25 and Color(255, 200, 50, floor(200 * a)) or cWarn)
            surface.SetDrawColor(barCol)
            surface.DrawRect(tX + 1, rowY + 1, (barW - 2) * hpFrac, barH - 2)

            surface.SetFont("KrakenRC_Data")
            surface.SetTextColor(cBlueBr)
            surface.SetTextPos(tX + barW + 5*sc, rowY - 2*sc)
            surface.DrawText(string.format("%d/%d", hp, maxHp))
            rowY = rowY + barH + 4*sc

            rowY = DrawLabelValue(tX, rowY, sc,
                "KrakenAurebesh_Micro", "distance", cAureDim,
                "KrakenRC_Data", string.format("%.1fm", meters), cCyan)

            if sin(t * 4) > 0 then
                surface.SetFont("KrakenAurebesh_Micro")
                surface.SetTextColor(cWarn)
                surface.SetTextPos(tX, rowY)
                surface.DrawText("tracking")
            end
        else
            surface.SetFont("KrakenAurebesh_Micro")
            surface.SetTextColor(cAureDim)
            surface.SetTextPos(tX, rowY)
            surface.DrawText("no target")
            rowY = rowY + 12*sc

            local scanAlpha = 0.5 + sin(t * 3) * 0.5
            surface.SetFont("KrakenRC_Data")
            surface.SetTextColor(Color(70, 150, 210, floor(120 * scanAlpha * a)))
            surface.SetTextPos(tX, rowY)
            surface.DrawText("SCANNING...")
        end

        local rX = cx - R * 0.55
        local rY = cy + 14*sc
        surface.SetFont("KrakenAurebesh_Micro")
        surface.SetTextColor(cAureDim)
        surface.SetTextPos(rX, rY)
        surface.DrawText("range")
        surface.SetFont("KrakenRC_DataBig")
        surface.SetTextColor(cCyan)
        surface.SetTextPos(rX, rY + 11*sc)
        surface.DrawText(string.format("%.1fm", meters))

        local magX = cx + R * 0.15
        local magY = cy - 14*sc

        local curZoom = 20
        local activeSight = wep:GetActiveSights()
        if activeSight and activeSight.ScopeMagnification then
            curZoom = math.Round(activeSight.ScopeMagnification, 0)
        elseif wep.SightMagnifications then
            local slot = activeSight and activeSight.Slot or 0
            if wep.SightMagnifications[slot] then
                curZoom = math.Round(wep.SightMagnifications[slot], 0)
            end
        end
        if curZoom < 1 then curZoom = 1 end

        local zoomStr = tostring(curZoom) .. "X"
        surface.SetFont("KrakenRC_Mag")
        surface.SetTextColor(cBlueBr)
        local magW, magH = surface.GetTextSize(zoomStr)
        surface.SetTextPos(magX, magY)
        surface.DrawText(zoomStr)
        surface.SetFont("KrakenAurebesh_Micro")
        surface.SetTextColor(cAureDim)
        surface.SetTextPos(magX, magY + magH + 1*sc)
        surface.DrawText("magnification")

        local sX = cx + R * 0.15
        local sY = cy + R * 0.28
        DrawLabelValue(sX, sY, sc,
            "KrakenAurebesh_Micro", "mode", cAureDim,
            "KrakenRC_Data", "SNIPER", cCyan)
        DrawLabelValue(sX, sY + 14*sc, sc,
            "KrakenAurebesh_Micro", "status", cAureDim,
            "KrakenRC_Data", "READY", Color(50, 220, 120, floor(200 * a * flk)))

        local owner = wep:GetOwner()
        if IsValid(owner) then
            local ang = owner:EyeAngles().y
            local compassY = cy + R * 0.50
            surface.SetFont("KrakenAurebesh_Micro")
            surface.SetTextColor(cAureDim)
            local bLbl = "bearing"
            local blW = surface.GetTextSize(bLbl)
            surface.SetTextPos(cx - blW / 2, compassY - 12*sc)
            surface.DrawText(bLbl)
            surface.SetFont("KrakenRC_DataBig")
            surface.SetTextColor(cCyan)
            local headStr = string.format("%03d", floor(ang % 360))
            local hw = surface.GetTextSize(headStr)
            surface.SetTextPos(cx - hw / 2, compassY)
            surface.DrawText(headStr)
        end

        H.DrawInnerGlow(cx, cy, ringInner, Color(70, 160, 220, floor(60 * a)), 4)
    end
end
