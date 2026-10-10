local AID = "krakensquad"
KrakenSquad.AID = AID
if SYMUI then SYMUI.HookKraken() end -- SymChars-Design (Farben/Schriften/Formen)

KF.RegisterAddon(AID, "Kraken's Strike Squad", {
    version = KrakenSquad.VERSION,
    prefix  = "KS",
})

KF.Fonts.Register(AID, {
    prefix    = "KS",
    primary   = "Roboto Condensed",
    secondary = "Roboto",
    accent    = "Aurebesh",
    sizes = {
        title = 48, header = 32, subheader = 24, body = 18,
        button = 20, small = 14, tiny = 12, stat = 16,
        value = 24, label = 14, micro = 10,
        radial = 28, radialSub = 20, ping = 15, pingSm = 12,
        sidebar_title = 38, sidebar_name = 22, sidebar_detail = 16, sidebar_ctx = 19,
        invite_title = 72, invite_text = 60, hint = 22, cmd_title = 60,
        section = 13, item = 14, btn = 13,
    },
    extras = {
        { name = "radial.title",       font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 15, weight = 700 },
        { name = "radial.sub",         font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 12, weight = 400 },
        { name = "radial.item",        font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 12, weight = 600 },
        { name = "radial.icon",        font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 10, weight = 500 },
        { name = "respawn.deploy",     font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 28, weight = 700 },
        { name = "respawn.deploy.blur",font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 28, weight = 700, blursize = 4 },
        { name = "respawn.name",       font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 16, weight = 700 },
        { name = "respawn.role",       font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 11, weight = 400 },
        { name = "respawn.status",     font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 10, weight = 700 },
        { name = "respawn.timer",      font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 22, weight = 700 },
        { name = "respawn.hint",       font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 13, weight = 400 },
        { name = "respawn.btn",        font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 14, weight = 700 },
        { name = "respawn.select",     font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 12, weight = 500 },
        { name = "orders.title",       font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 22, weight = 700 },
        { name = "orders.sub",         font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 12, weight = 400 },
        { name = "orders.section",     font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 13, weight = 700 },
        { name = "orders.item",        font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 14, weight = 500 },
        { name = "orders.small",       font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 12, weight = 400 },
        { name = "orders.btn",         font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 13, weight = 700 },
        { name = "orders.desc",        font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 11, weight = 400 },
        { name = "orders.hud",         font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 14, weight = 700 },
        { name = "orders.hudMain",     font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 13, weight = 700 },
        { name = "orders.hudSm",       font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 12, weight = 500 },
        { name = "orders.hudSec",      font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 11, weight = 500 },
        { name = "layout.title",       font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 22, weight = 700 },
        { name = "layout.sub",         font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 11, weight = 400 },
        { name = "layout.block",       font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 12, weight = 700 },
        { name = "layout.anchor",      font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size =  9, weight = 400 },
        { name = "layout.btn",         font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 12, weight = 700 },
        { name = "layout.hint",        font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 11, weight = 400 },
        { name = "invite.title",       font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 22, weight = 700 },
        { name = "invite.sub",         font = SYMUI and SYMUI.FontFace("body") or "Roboto",           size = 12, weight = 400 },
        { name = "invite.item",        font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 14, weight = 500 },
        { name = "invite.btn",         font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 13, weight = 700 },
        { name = "cmd_title.bold.blur",font = SYMUI and SYMUI.FontFace("body") or "Roboto Condensed", size = 60, weight = 700, blursize = 4 },
    },
})

local pal = KF.UI.DefaultDarkPalette()
local function setRGB(c, r, g, b) c.r, c.g, c.b = r, g, b end

pal.AccentHover  = KF.UI.ColorAlpha(pal.Accent, 255); setRGB(pal.AccentHover, 255, 210, 100)
pal.AccentDim    = KF.UI.ColorAlpha(pal.Accent, 60)
pal.AccentGlow   = KF.UI.ColorAlpha(pal.Accent, 50)
pal.BG           = pal.Background
pal.PanelSolid   = pal.Panel
pal.PanelDark    = KF.UI.ColorAlpha(pal.PanelDark, 200)
pal.Header       = KF.UI.ColorAlpha(pal.PanelElevated, 255); setRGB(pal.Header, 14, 16, 20)
pal.Row          = KF.UI.ColorAlpha(pal.PanelElevated, 230); setRGB(pal.Row, 16, 18, 22)
pal.RowHover     = KF.UI.ColorAlpha(pal.PanelHover, 245);    setRGB(pal.RowHover, 22, 26, 34)
pal.RowAlt       = KF.UI.ColorAlpha(pal.PanelElevated, 230); setRGB(pal.RowAlt, 14, 16, 20)
pal.TextPrimary  = KF.UI.ColorAlpha(pal.TextPrimary, 255);   setRGB(pal.TextPrimary, 240, 242, 248)
pal.TextBright   = KF.UI.ColorAlpha(pal.TextBright,  255);   setRGB(pal.TextBright,  240, 242, 248)
pal.Text         = pal.TextSecondary
pal.Shadow       = KF.UI.ColorAlpha(pal.Shadow, 180)
pal.SuccessHover = KF.UI.ColorAlpha(pal.Success, 255); setRGB(pal.SuccessHover, 100, 220, 140)
pal.ErrorHover   = KF.UI.ColorAlpha(pal.Error,   255); setRGB(pal.ErrorHover,   245, 110, 110)
pal.Health       = KF.UI.ColorAlpha(color_white, 230)
pal.Ally         = pal.Info
pal.Enemy        = pal.Error
pal.BarBG        = KF.UI.ColorAlpha(color_white, 15)
pal.Highlight    = KF.UI.ColorAlpha(color_white, 6)
pal.InputBG      = KF.UI.ColorAlpha(pal.BackgroundDark, 255); setRGB(pal.InputBG, 10, 12, 16)
pal.ScrollTrack  = KF.UI.ColorAlpha(pal.Panel, 255)
pal.ToggleTrack  = KF.UI.ColorAlpha(pal.PanelHover, 255); setRGB(pal.ToggleTrack, 30, 32, 38)
pal.Disabled     = KF.UI.ColorAlpha(pal.Border,       255); setRGB(pal.Disabled, 50, 52, 58)
pal.DisabledText = KF.UI.ColorAlpha(pal.TextDisabled, 255); setRGB(pal.DisabledText, 70, 72, 80)
pal.BadgeJob      = KF.UI.ColorAlpha(pal.Info,     50)
pal.BadgeFaction  = KF.UI.ColorAlpha(pal.Warning,  50); setRGB(pal.BadgeFaction,  255, 160,  50)
pal.BadgeCategory = KF.UI.ColorAlpha(pal.Success,  50); setRGB(pal.BadgeCategory, 120, 220, 120)
pal.BadgeSquad    = KF.UI.ColorAlpha(pal.Accent,   50); setRGB(pal.BadgeSquad,    220, 180,  60)
pal.BadgeFallback = KF.UI.ColorAlpha(pal.TextMuted,50); setRGB(pal.BadgeFallback, 120, 120, 120)
pal.OverheadBG    = KF.UI.ColorAlpha(pal.BackgroundDark, 217); setRGB(pal.OverheadBG,   12,  12,  16)
pal.OverheadHint  = KF.UI.ColorAlpha(pal.TextSecondary,  204); setRGB(pal.OverheadHint, 180, 180, 190)
pal.MedicCritical = KF.UI.ColorAlpha(pal.Error,   255); setRGB(pal.MedicCritical, 230,  50,  50)
pal.MedicLow      = KF.UI.ColorAlpha(pal.Warning, 255); setRGB(pal.MedicLow,      255, 140,  50)
pal.MedicMid      = KF.UI.ColorAlpha(pal.Warning, 255); setRGB(pal.MedicMid,      255, 220,  60)
pal.MedicHigh     = KF.UI.ColorAlpha(pal.Success, 255); setRGB(pal.MedicHigh,      80, 220, 120)
pal.MarkGreen     = KF.UI.ColorAlpha(pal.Success, 255); setRGB(pal.MarkGreen,      80, 220, 120)
pal.MarkRed       = pal.Error
pal.LayoutCancel  = KF.UI.ColorAlpha(pal.Border,  200); setRGB(pal.LayoutCancel,  80,  85, 100)
KF.UI.SetTheme(AID, pal)

function KrakenSquad.P(key) return KF.UI.GetColor(key, AID) end
local P = KrakenSquad.P

KrakenSquad.UI = KrakenSquad.UI or {}
KrakenSquad.UI.HOVER_SPEED = 12

KrakenSquad.SOUNDS = {
    hover   = "kraken/sw_squadrons/ux/navigation/navigation_slider_02.mp3",
    click   = "kraken/sw_squadrons/ux/navigation/navigation_activate_01.mp3",
    success = "buttons/button14.wav",
    error   = "buttons/button10.wav",
    deny    = "buttons/button10.wav",
    open    = "kraken/sw_squadrons/ux/navigation/navigation_activate_01.mp3",
    close   = "kraken/sw_squadrons/ux/navigation/navigation_activate_01.mp3",
}

KrakenSquad.Draw = KrakenSquad.Draw or {}
local Draw = KrakenSquad.Draw
local NOTCH = 6

function Draw.Panel(x, y, w, h, opts)
    opts = opts or {}
    KF.Draw.Panel(x, y, w, h, {
        bgColor   = opts.bg, borderColor = opts.border,
        notch     = opts.notch or NOTCH, hasNotch = true,
        notchSide = "right", addonId = AID,
    })
    if opts.accent then
        local ac = opts.accentColor or P("Accent")
        surface.SetDrawColor(ac)
        if opts.accent == "top" then
            surface.DrawRect(x, y, w - (opts.notch or NOTCH), 2)
        elseif opts.accent == "left" then
            surface.DrawRect(x, y, 2, h)
        end
    end
    if opts.highlight ~= false then
        surface.SetDrawColor(P("Highlight"))
        surface.DrawRect(x + 3, y + 1, w - 6 - (opts.notch or NOTCH), 1)
    end
end

function Draw.TextShadow(text, font, x, y, col, ax, ay, offset)
    KF.Draw.ShadowText(text, font, x, y, col or color_white, ax, ay, offset, P("Shadow"))
end

function Draw.PanelBG(x, y, w, h, opts)
    opts = opts or {}
    surface.SetDrawColor(0, 0, 0, opts.alpha or 55)
    surface.DrawRect(x, y, w, h)
    if opts.frost ~= false then
        surface.SetDrawColor(255, 255, 255, 10)
        surface.DrawRect(x, y, w, 1)
    end
    if opts.accentLine then
        local ac = opts.accentColor or P("Accent")
        surface.SetDrawColor(ac.r, ac.g, ac.b, opts.accentAlpha or 80)
        if opts.accentSide == "left" then
            surface.DrawRect(x, y, KF.Scale(2), h)
        else
            surface.DrawRect(x, y, w, 1)
        end
    end
end

function KrakenSquad.WrapText(text, font, maxW)
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxW then return { text } end
    local words = string.Explode(" ", text)
    if #words <= 1 then return { KF.TruncateText(text, font, maxW) } end
    local lines, cur = {}, ""
    for _, w in ipairs(words) do
        local test = cur == "" and w or (cur .. " " .. w)
        if surface.GetTextSize(test) > maxW and cur ~= "" then
            lines[#lines + 1] = cur
            cur = w
        else
            cur = test
        end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    return lines
end

function KrakenSquad.ClientNPCThink(ent)
    local seqName = ent:GetNWString("KSAnim", "")
    local sig = (ent:GetModel() or "") .. "|" .. seqName
    if ent._ksAnimSig == sig and (not ent._ksTargetSeq or ent:GetSequence() == ent._ksTargetSeq) then
        return
    end
    local seq = seqName ~= "" and ent:LookupSequence(seqName) or -1
    if seq < 0 then seq = ent:LookupSequence("idle_all_01") end
    if seq < 0 then seq = ent:SelectWeightedSequence(ACT_IDLE) end
    if seq < 0 then return end
    ent:ResetSequence(seq)
    ent:SetPlaybackRate(1)
    ent:SetCycle(0)
    ent._ksAnimSig, ent._ksTargetSeq = sig, seq
end

function Draw.EntityOverhead(ent, fallbackText)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local entPos = ent:GetPos()
    local dist = entPos:Distance(ply:GetPos())
    if dist > 300 then return end

    local maxs = ent:OBBMaxs()
    local pos  = entPos + Vector(0, 0, (maxs and maxs.z or 30) + 12)
    local ang  = Angle(0, ply:EyeAngles().y - 90, 90)
    local alpha = math.Clamp(255 - (dist / 300) * 200, 55, 255)
    local text = ent.GetDisplayText and ent:GetDisplayText() or fallbackText
    if not text or text == "" then text = fallbackText end

    local accent = P("Accent")
    cam.Start3D2D(pos, ang, 0.1)
        KF.Draw.RoundedBox(-100, -15, 200, 50, 4, KF.UI.ColorAlpha(P("OverheadBG"), math.floor(alpha * 0.85)))
        surface.SetDrawColor(accent.r, accent.g, accent.b, alpha)
        surface.DrawRect(-100, -15, 3, 50)
        draw.SimpleText(text, "KS.small.bold", 0, 0, KF.UI.ColorAlpha(color_white, alpha),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(KrakenSquad.L("npc_press_interact"), "KS.small.light", 0, 18,
            KF.UI.ColorAlpha(P("OverheadHint"), math.floor(alpha * 0.8)),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

function KrakenSquad.ShowFullscreenNotify(label, col, issuerName, hookName, duration)
    duration = duration or 5
    local Scaled = KF.Scale
    local startTime   = CurTime()
    local letterCount = #label
    local revealDur   = math.min(0.6, letterCount * 0.03)

    hook.Add("HUDPaint", hookName, function()
        local age = CurTime() - startTime
        if age > duration then hook.Remove("HUDPaint", hookName) return end

        local fadeIn  = math.Clamp(age / 0.3, 0, 1)
        local fadeOut = age > duration - 0.8 and math.Clamp((duration - age) / 0.8, 0, 1) or 1
        local alpha   = fadeIn * fadeOut

        local sw, sh = ScrW(), ScrH()
        local cx     = sw / 2
        local slideEase = 1 - (1 - math.Clamp(age / 0.5, 0, 1)) ^ 3
        local cy = sh * 0.27 - Lerp(slideEase, Scaled(20), 0)

        local revealFrac = math.Clamp(age / revealDur, 0, 1)
        local hideStart  = duration - 0.8
        local hideDur    = math.min(0.6, letterCount * 0.03)
        local hideFrac   = age > hideStart and math.Clamp((age - hideStart) / hideDur, 0, 1) or 0
        local chars   = math.Clamp(math.floor(revealFrac * letterCount) - math.floor(hideFrac * letterCount), 0, letterCount)
        local visible = label:sub(1, chars)

        local cmdAlpha = math.floor(255 * alpha)
        local pulse    = 1 + math.sin(CurTime() * 4) * 0.08 * alpha
        local glow     = KF.UI.ColorAlpha(col, math.floor(cmdAlpha * pulse))

        draw.SimpleText(visible, "KS.cmd_title.bold.blur", cx, cy, KF.UI.ColorAlpha(col, math.floor(40 * alpha * pulse)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(visible, "KS.cmd_title.bold.blur", cx, cy, KF.UI.ColorAlpha(col, math.floor(60 * alpha * pulse)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(visible, "KS.cmd_title.bold", cx + 1, cy + 1, KF.UI.ColorAlpha(color_black, math.floor(120 * alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(visible, "KS.cmd_title.bold", cx, cy, glow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if (revealFrac < 1 or (hideFrac > 0 and hideFrac < 1)) and chars > 0 then
            surface.SetFont("KS.cmd_title.bold")
            local partW = surface.GetTextSize(visible)
            local cursorX = cx + partW / 2 + Scaled(2)
            local blink = math.fmod(CurTime() * 8, 1) > 0.5 and cmdAlpha or 0
            surface.SetDrawColor(col.r, col.g, col.b, blink)
            surface.DrawRect(cursorX, cy - Scaled(18), Scaled(2), Scaled(36))
        end

        local lineExpand = 1 - (1 - math.Clamp((age - 0.2) / 0.4, 0, 1)) ^ 2
        surface.SetFont("KS.cmd_title.bold")
        local lineHalfW = (surface.GetTextSize(label) / 2 + Scaled(20)) * lineExpand * alpha
        local lineY = cy + Scaled(22)
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(100 * alpha))
        surface.DrawRect(cx - lineHalfW, lineY, lineHalfW * 2, 1)
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(40 * alpha))
        surface.DrawRect(cx - lineHalfW, lineY + 2, lineHalfW * 2, 1)

        local tagY    = lineY + Scaled(6)
        local tagFade = math.Clamp((age - 0.4) / 0.3, 0, 1) * alpha
        draw.SimpleText(KrakenSquad.L("squad_order"), "KS.micro.bold", cx, tagY,
            KF.UI.ColorAlpha(col, math.floor(100 * tagFade)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(issuerName, "KS.small", cx, tagY + Scaled(12),
            KF.UI.ColorAlpha(P("TextSecondary"), math.floor(180 * tagFade)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end)
end

local PREFIX = "krakensquad_"
KrakenSquad.ClientPrefs = KrakenSquad.ClientPrefs or {}

local raw = cookie.GetString(PREFIX .. "prefs", "")
if raw ~= "" then
    local t = util.JSONToTable(raw)
    if istable(t) then KrakenSquad.ClientPrefs = t end
end

function KrakenSquad.GetClientPref(key, default)
    local v = KrakenSquad.ClientPrefs[key]
    if v ~= nil then return v end
    return default
end

function KrakenSquad.SetClientPref(key, value)
    KrakenSquad.ClientPrefs[key] = value
    cookie.Set(PREFIX .. "prefs", util.TableToJSON(KrakenSquad.ClientPrefs))
    hook.Run("KrakenSquad.ClientPrefsChanged", key, value)
end

function KrakenSquad.ResetAllClientPrefs()
    KrakenSquad.ClientPrefs = {}
    cookie.Set(PREFIX .. "prefs", "")
    if KrakenSquad.Layout and KrakenSquad.Layout.ResetClientLayout then
        KrakenSquad.Layout.ResetClientLayout()
    end
    hook.Run("KrakenSquad.ClientPrefsChanged")
end

local function InitTheme()
    KF.Fonts.Create(AID)
    local ac = KrakenSquad.GetConfig("colors").accent or { 252, 178, 73 }
    KF.UI.ApplyAccentColor(AID, Color(ac[1], ac[2], ac[3]))
end

hook.Add("KrakenSquad.Loaded",  "KS.InitTheme",    InitTheme)
hook.Add("InitPostEntity",      "KS.EarlyTheme",   InitTheme)
hook.Add("OnScreenSizeChanged", "KS.RebuildFonts", function() KF.Fonts.Create(AID) end)

hook.Add("KrakenSquad.ConfigUpdated", "KS.SyncPalette", function()
    local colors = KrakenSquad.GetConfig("colors")
    if not colors then return end
    local theme = KF.UI.GetThemeColors(AID)
    local function rgb(t) return t[1] or t["1"], t[2] or t["2"], t[3] or t["3"] end
    if colors.accent then
        local r, g, b = rgb(colors.accent)
        KF.UI.ApplyAccentColor(AID, Color(r, g, b))
        theme.Accent.r, theme.Accent.g, theme.Accent.b = r, g, b
        theme.AccentHover.r = math.min(r + 20, 255)
        theme.AccentHover.g = math.min(g + 20, 255)
        theme.AccentHover.b = math.min(b + 50, 255)
    end
    if colors.ally   then theme.Ally.r,   theme.Ally.g,   theme.Ally.b   = rgb(colors.ally)   end
    if colors.enemy  then theme.Enemy.r,  theme.Enemy.g,  theme.Enemy.b  = rgb(colors.enemy)  end
    if colors.health then theme.Health.r, theme.Health.g, theme.Health.b = rgb(colors.health) end
end)
