surface.CreateFont("KrakenAurebesh_Large", {
    font = "Aurebesh",
    size = 24,
    weight = 500,
    antialias = true,
    additive = true,
})
surface.CreateFont("KrakenAurebesh_Small", {
    font = "Aurebesh",
    size = 16,
    weight = 500,
    antialias = true,
    additive = true,
})
surface.CreateFont("KrakenAurebesh_Tiny", {
    font = "Aurebesh",
    size = 12,
    weight = 400,
    antialias = true,
    additive = true,
})

local colCyan = {
    Main = (SYMUI and SYMUI.Holo(255) or Color(50,180,220,255)),
    Dim = (SYMUI and SYMUI.Holo(150) or Color(50,180,220,150)),
    Bright = Color(100, 220, 255, 255),
    Dot = Color(255, 50, 50, 255),
    Cross = Color(200, 220, 240, 255),
}
local colRed = {
    Main = Color(220, 50, 50, 255),
    Dim = Color(220, 50, 50, 150),
    Bright = Color(255, 100, 100, 255),
    Dot = Color(255, 255, 50, 255),
    Cross = Color(240, 200, 200, 255),
}
local colLocked = Color(50, 255, 50, 255)
local colTracking = Color(255, 200, 50, 255)

local sin, cos, rad = math.sin, math.cos, math.rad
local floor, clamp = math.floor, math.Clamp
local pi2 = math.pi * 2

local MAT_TRACK = Material("VGUI/lockon.png")

local circleCache = {}
local function getCircleVerts(cx, cy, radius, numSegs)
    local key = floor(radius * 10)
    local cached = circleCache[key]
    if cached and cached.cx == cx and cached.cy == cy then
        return cached.verts
    end
    local verts = {}
    local step = pi2 / numSegs
    for i = 0, numSegs do
        local ang = i * step
        verts[i + 1] = {x = cx + cos(ang) * radius, y = cy + sin(ang) * radius}
    end
    circleCache[key] = {cx = cx, cy = cy, verts = verts}
    return verts
end

local function col(c, a) return Color(c.r, c.g, c.b, floor(c.a * a)) end

local function semicircles(cx, cy, r, thickness, gapDeg, rot, c)
    surface.SetDrawColor(c)
    local segs = 32
    local arcLen = 180 - gapDeg
    local rInner = r - thickness
    local invSegs = 1 / segs
    local arcLenRad = rad(arcLen)
    for arc = 0, 1 do
        local baseAngle = rad(rot + arc * 180)
        local c1, s1 = cos(baseAngle), sin(baseAngle)
        local x1o, y1o = cx + c1 * r, cy + s1 * r
        local x1i, y1i = cx + c1 * rInner, cy + s1 * rInner
        for i = 1, segs do
            local a2 = baseAngle + (i * invSegs) * arcLenRad
            local c2, s2 = cos(a2), sin(a2)
            local x2o, y2o = cx + c2 * r, cy + s2 * r
            local x2i, y2i = cx + c2 * rInner, cy + s2 * rInner
            surface.DrawLine(x1o, y1o, x2o, y2o)
            surface.DrawLine(x1i, y1i, x2i, y2i)
            x1o, y1o, x1i, y1i = x2o, y2o, x2i, y2i
        end
        local startA = baseAngle
        local endA = baseAngle + arcLenRad
        local csS, snS = cos(startA), sin(startA)
        local csE, snE = cos(endA), sin(endA)
        surface.DrawLine(cx + csS * rInner, cy + snS * rInner, cx + csS * r, cy + snS * r)
        surface.DrawLine(cx + csE * rInner, cy + snE * rInner, cx + csE * r, cy + snE * r)
    end
end

local function dashes(cx, cy, r, segs, gap, rot, c)
    surface.SetDrawColor(c)
    local step = 360 / segs
    local len = step * (1 - gap)
    local lenStep = len * 0.2
    local rotRad = rad(rot)
    local cs, sn = cos(rotRad), sin(rotRad)
    for i = 0, segs - 1 do
        local st = rad(i * step)
        local c1, s1 = cos(st), sin(st)
        local x1, y1 = c1 * r, s1 * r
        local px1, py1 = cx + x1 * cs - y1 * sn, cy + x1 * sn + y1 * cs
        for j = 1, 5 do
            local a2 = st + rad(j * lenStep)
            local c2, s2 = cos(a2), sin(a2)
            local x2, y2 = c2 * r, s2 * r
            local px2, py2 = cx + x2 * cs - y2 * sn, cy + x2 * sn + y2 * cs
            surface.DrawLine(px1, py1, px2, py2)
            px1, py1 = px2, py2
        end
    end
end

local function grid(cx, cy, w, h, nx, ny, c)
    surface.SetDrawColor(c)
    local hw, hh, cw, ch = w / 2, h / 2, w / nx, h / ny
    for i = 0, nx do surface.DrawLine(cx - hw + i * cw, cy - hh, cx - hw + i * cw, cy + hh) end
    for i = 0, ny do surface.DrawLine(cx - hw, cy - hh + i * ch, cx + hw, cy - hh + i * ch) end
end

local function bracket(cx, cy, sz, cl, c)
    surface.SetDrawColor(c)
    local h = sz / 2
    surface.DrawLine(cx - h, cy - h, cx - h + cl, cy - h)
    surface.DrawLine(cx - h, cy - h, cx - h, cy - h + cl)
    surface.DrawLine(cx + h - cl, cy - h, cx + h, cy - h)
    surface.DrawLine(cx + h, cy - h, cx + h, cy - h + cl)
    surface.DrawLine(cx - h, cy + h - cl, cx - h, cy + h)
    surface.DrawLine(cx - h, cy + h, cx - h + cl, cy + h)
    surface.DrawLine(cx + h, cy + h - cl, cx + h, cy + h)
    surface.DrawLine(cx + h - cl, cy + h, cx + h, cy + h)
end

local function cardinals(cx, cy, ri, ro, c)
    surface.SetDrawColor(c)
    surface.DrawLine(cx, cy - ri, cx, cy - ro)
    surface.DrawLine(cx, cy + ri, cx, cy + ro)
    surface.DrawLine(cx - ri, cy, cx - ro, cy)
    surface.DrawLine(cx + ri, cy, cx + ro, cy)
end

local scaleAngles = {}
for _, ang in ipairs({-90, -45, 0, 45, 90, 135, 180, -135}) do
    local a = rad(ang)
    scaleAngles[#scaleAngles + 1] = {c = cos(a), s = sin(a)}
end

local function scale(cx, cy, r, tl, c)
    surface.SetDrawColor(c)
    local rInner = r - tl
    for i = 1, 8 do
        local sa = scaleAngles[i]
        surface.DrawLine(cx + sa.c * rInner, cy + sa.s * rInner, cx + sa.c * r, cy + sa.s * r)
    end
end

local function rangeBars(cx, cy, d, c)
    surface.SetDrawColor(c)
    for i = -5, 5 do
        if i ~= 0 then
            local y, l = cy + i * 15, (6 - math.abs(i)) * 5
            surface.DrawLine(cx - d, y, cx - d - l, y)
            surface.DrawLine(cx + d, y, cx + d + l, y)
        end
    end
end

local function corners(cx, cy, d, l, c)
    surface.SetDrawColor(c)
    surface.DrawLine(cx - d, cy - d, cx - d + l, cy - d)
    surface.DrawLine(cx - d, cy - d, cx - d, cy - d + l)
    surface.DrawLine(cx + d - l, cy - d, cx + d, cy - d)
    surface.DrawLine(cx + d, cy - d, cx + d, cy - d + l)
    surface.DrawLine(cx - d, cy + d - l, cx - d, cy + d)
    surface.DrawLine(cx - d, cy + d, cx - d + l, cy + d)
    surface.DrawLine(cx + d, cy + d - l, cx + d, cy + d)
    surface.DrawLine(cx + d - l, cy + d, cx + d, cy + d)
end

hook.Add("HUDPaint", "KrakenExplosives_HoloHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep.HasHoloHUD then return end

    -- ArcCW: GetSightDelta() returns 0 when fully sighted, 1 when hip
    local sightDelta = 1
    if wep.GetSightDelta then
        sightDelta = wep:GetSightDelta()
    end
    local delta = 1 - sightDelta -- Convert to 0=hip, 1=fully sighted

    if delta < (wep.HoloHUD_MinSight or 0.75) then return end

    local a = clamp((delta - 0.5) * 2, 0, 1)
    if a < 0.01 then return end

    local easeIn = a * a
    local easeOut = 1 - (1 - a) * (1 - a)
    local zoomFactor = easeOut

    local sw, sh = ScrW(), ScrH()
    local cx, cy, sc = sw / 2, sh / 2, sh / 1080
    local t = CurTime()

    local scheme = wep.HoloHUD_Red and colRed or colCyan
    local cM, cD, cB = col(scheme.Main, a), col(scheme.Dim, a), col(scheme.Bright, a)
    local cR, cW = col(scheme.Dot, a), col(scheme.Cross, a)

    local baseRadius = 320 * sc
    local scopeRadius = baseRadius * (0.5 + 0.5 * zoomFactor)
    local vignetteAlpha = floor(180 * easeIn)

    -- Stencil vignette: darken everything outside the scope circle
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
    local circleVerts = getCircleVerts(cx, cy, scopeRadius, 64)
    surface.DrawPoly(circleVerts)

    render.SetStencilFailOperation(STENCILOPERATION_KEEP)
    render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)
    render.SetStencilReferenceValue(1)

    surface.SetDrawColor(0, 0, 0, vignetteAlpha)
    surface.DrawRect(0, 0, sw, sh)

    render.SetStencilEnable(false)

    -- HoloHUD elements
    local z = zoomFactor
    semicircles(cx, cy, 300 * sc * z, 15 * sc * z, 30, t * 25, cM)
    semicircles(cx, cy, 280 * sc * z, 10 * sc * z, 40, -t * 18, cD)
    dashes(cx, cy, 265 * sc * z, 20, 0.35, -t * 3.5, cD)
    dashes(cx, cy, 225 * sc * z, 14, 0.30, -t * 2.1, cD)
    cardinals(cx, cy, 233 * sc * z, 257 * sc * z, cM)
    scale(cx, cy, 260 * sc * z, 10 * sc * z, cD)
    grid(cx, cy, 220 * sc * z, 160 * sc * z, 10, 8, cD)
    rangeBars(cx, cy, 130 * sc * z, cD)
    corners(cx, cy, 130 * sc * z, 22 * sc * z, cM)
    bracket(cx, cy, 32 * sc * z, 10 * sc * z, cB)
    bracket(cx, cy, 36 * sc * z, 12 * sc * z, cD)

    -- Center crosshair
    local cl, cg = 7 * sc * z, 4 * sc * z
    surface.SetDrawColor(cW)
    surface.DrawLine(cx - cl - cg, cy, cx - cg, cy)
    surface.DrawLine(cx + cg, cy, cx + cl + cg, cy)
    surface.DrawLine(cx, cy - cl - cg, cx, cy - cg)
    surface.DrawLine(cx, cy + cg, cx, cy + cl + cg)

    -- Center dot
    local ds = 3 * sc
    surface.SetDrawColor(cR)
    surface.DrawRect(cx - ds / 2, cy - ds / 2, ds, ds)

    -- Lock-on overlay (for weapons with HasLockOn)
    if wep.HasLockOn then
        local trackFrac = 0
        if wep.StartTrackTime and wep.StartTrackTime > 0 then
            trackFrac = clamp((CurTime() - wep.StartTrackTime) / (wep.LockTime or 1), 0, 1)
        end

        local modeText = (wep.LockOnType == "stinger") and "AA" or "GND"
        local modeAurebesh = (wep.LockOnType == "stinger") and "anti air" or "ground"

        surface.SetFont((SYMUI and SYMUI.F("TargetIDSmall") or "TargetIDSmall"))
        surface.SetTextColor(col(scheme.Main, a))
        local tw, th = surface.GetTextSize(modeText)
        surface.SetTextPos(cx - tw / 2, cy + 170 * sc * z - th / 2)
        surface.DrawText(modeText)

        surface.SetFont("KrakenAurebesh_Tiny")
        surface.SetTextColor(cD)
        local maw, mah = surface.GetTextSize(modeAurebesh)
        surface.SetTextPos(cx - maw / 2, cy + 185 * sc * z)
        surface.DrawText(modeAurebesh)

        local statusText, statusColor, statusAurebesh
        if wep:Clip1() <= 0 then
            statusText = "NO AMMO"
            statusAurebesh = "no ammo"
            statusColor = col(Color(255, 50, 50, 200), a)
        elseif trackFrac >= 1 and IsValid(wep.TargetEntity) then
            statusText = "LOCKED"
            statusAurebesh = "locked"
            statusColor = col(colLocked, a)
        elseif trackFrac > 0 and IsValid(wep.TargetEntity) then
            statusText = "TRACKING"
            statusAurebesh = "tracking"
            statusColor = col(colTracking, a)
        else
            statusText = "SCANNING"
            statusAurebesh = "scanning"
            statusColor = col(scheme.Dim, a)
        end

        surface.SetFont((SYMUI and SYMUI.F("TargetIDSmall") or "TargetIDSmall"))
        surface.SetTextColor(statusColor)
        local stw, sth = surface.GetTextSize(statusText)
        surface.SetTextPos(cx - stw / 2, cy - 170 * sc * z - sth / 2)
        surface.DrawText(statusText)

        surface.SetFont("KrakenAurebesh_Small")
        local saw, sah = surface.GetTextSize(statusAurebesh)
        surface.SetTextPos(cx - saw / 2, cy - 190 * sc * z - sah / 2)
        surface.DrawText(statusAurebesh)

        -- Target reticle
        if IsValid(wep.TargetEntity) and wep:Clip1() > 0 then
            local toscreen = wep.TargetEntity:WorldSpaceCenter():ToScreen()
            local lockCol = (trackFrac >= 1) and col(colLocked, a) or col(colTracking, a)
            local reticleSize = 80 * sc
            if trackFrac >= 1 then
                reticleSize = reticleSize * (1 + sin(t * 15) * 0.08)
            end

            surface.SetMaterial(MAT_TRACK)
            surface.SetDrawColor(lockCol)
            surface.DrawTexturedRect(toscreen.x - reticleSize / 2, toscreen.y - reticleSize / 2, reticleSize, reticleSize)

            if trackFrac < 1 then
                local barW, barH = 80 * sc, 4 * sc
                local barX = toscreen.x - barW / 2
                local barY = toscreen.y + reticleSize / 2 + 8 * sc
                surface.SetDrawColor(0, 0, 0, 150 * a)
                surface.DrawRect(barX - 2, barY - 2, barW + 4, barH + 4)
                surface.SetDrawColor(col(colTracking, a))
                surface.DrawRect(barX, barY, barW * trackFrac, barH)
            end

            if trackFrac >= 1 then
                surface.SetFont("KrakenAurebesh_Large")
                surface.SetTextColor(col(colLocked, a))
                local lw, lh = surface.GetTextSize("fire")
                surface.SetTextPos(toscreen.x - lw / 2, toscreen.y + reticleSize / 2 + 10 * sc)
                surface.DrawText("fire")
            end
        end
    else
        -- Non-lock-on weapons: show "ready" text
        surface.SetFont("KrakenAurebesh_Tiny")
        surface.SetTextColor(cD)
        local readyText = "ready"
        local rtw, rth = surface.GetTextSize(readyText)
        surface.SetTextPos(cx - rtw / 2, cy + 185 * sc * z)
        surface.DrawText(readyText)
    end
end)
