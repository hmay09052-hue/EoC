include("shared.lua")

local fontCache = {}

-- Farben passend zum Echoes of Clones HUD / Militärischen Funksystem
local P = {
    yellow  = Color(252, 178, 73),
    yellowD = Color(252, 178, 73, 56),
    white   = Color(244, 241, 233),
    soft    = Color(157, 163, 173),
    muted   = Color(101, 107, 117),
    bg      = Color(7, 9, 12, 245),
    panel   = Color(8, 11, 15, 235),
    panel2  = Color(14, 18, 23, 245),
    line    = Color(207, 216, 228, 38),
    green   = Color(74, 203, 130),
}
if SYMUI then SYMUI.ApplyEoCPalette(P) end -- SymChars-Design

local function EnsureFonts(scale)
    local key = math.max(1, math.floor(scale * 1000))
    if fontCache[key] then return fontCache[key] end

    local prefix = "GRNDefcon3D_" .. key .. "_"
    surface.CreateFont(prefix .. "Title", { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 60, weight = 400, extended = true })
    surface.CreateFont(prefix .. "Name", { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 56, weight = 400, extended = true })
    surface.CreateFont(prefix .. "Number", { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 132, weight = 400, extended = true })
    surface.CreateFont(prefix .. "Prompt", { font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue", size = 36, weight = 400, extended = true })
    surface.CreateFont(prefix .. "Sub", { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 20, weight = 600, extended = true })
    surface.CreateFont(prefix .. "Section", { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 20, weight = 700, extended = true })
    surface.CreateFont(prefix .. "Small", { font = SYMUI and SYMUI.FontFace("body") or "Montserrat", size = 20, weight = 500, extended = true })

    fontCache[key] = prefix
    return prefix
end

local function HexToColor(hex, alpha)
    local raw = string.gsub(tostring(hex or "#55b8ff"), "#", "")
    if #raw ~= 6 then raw = "55b8ff" end

    return Color(
        tonumber(string.sub(raw, 1, 2), 16) or 85,
        tonumber(string.sub(raw, 3, 4), 16) or 184,
        tonumber(string.sub(raw, 5, 6), 16) or 255,
        alpha or 255
    )
end

local function Fit(text, font, maxWidth)
    text = tostring(text or "")
    surface.SetFont(font)
    if surface.GetTextSize(text) <= maxWidth then return text end
    while #text > 0 and surface.GetTextSize(text .. "...") > maxWidth do
        text = string.sub(text, 1, (utf8.offset(text, -1) or #text) - 1)
    end
    return text .. "..."
end

function ENT:Draw()
    self:DrawModel()

    local terminalConfig = (GRN_DEFCON and GRN_DEFCON.Config and GRN_DEFCON.Config.Terminal) or {}
    local display = terminalConfig.Display or {}
    if display.Enabled == false then return end

    local drawDistance = tonumber(terminalConfig.DrawDistance) or 900
    if EyePos():DistToSqr(self:GetPos()) > drawDistance * drawDistance then return end

    local localPos = isvector(display.Pos) and display.Pos or Vector(4.2, -0.4, 86)
    local localAng = isangle(display.Ang) and display.Ang or Angle(0, 90, 90)
    local scale = math.Clamp(tonumber(display.Scale) or 0.055, 0.005, 0.5)
    local w = math.max(320, tonumber(display.Width) or 720)
    local h = math.max(220, tonumber(display.Height) or 430)
    local x = tonumber(display.OffsetX) or -95
    local y = tonumber(display.OffsetY) or 0
    local prefix = EnsureFonts(scale)

    local level = GRN_DEFCON.GetClientLevel and GRN_DEFCON.GetClientLevel() or tonumber(GRN_DEFCON.Config.DefaultLevel) or 5
    local data = GRN_DEFCON.GetClientLevelData and GRN_DEFCON.GetClientLevelData(level) or (GRN_DEFCON.Config.Levels or {})[level] or {}
    local col = HexToColor(data.Color)
    local playerClose = IsValid(LocalPlayer()) and LocalPlayer():GetPos():DistToSqr(self:GetPos()) <= math.pow(tonumber(terminalConfig.UseDistance) or 155, 2)

    cam.Start3D2D(self:LocalToWorld(localPos), self:LocalToWorldAngles(localAng), scale)
        if SYMUI then
            SYMUI.Cut(x, y, w, h, P.bg, 24, "tlbr")
        else
            surface.SetDrawColor(P.bg)
            surface.DrawRect(x, y, w, h)
        end

        -- Kopfzeile wie im HUD: dunkler Balken, gelbe Linie mit Verlauf
        local headH = 100
        surface.SetDrawColor(P.panel2)
        surface.DrawRect(x, y, w, headH)
        surface.SetDrawColor(P.yellowD)
        surface.DrawRect(x, y + headH, w, 2)
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(x, y + headH, 290, 4)

        draw.SimpleText(tostring(display.Title or "DEFCON CONTROL"), prefix .. "Title", x + 30, y + 40, P.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local subW = draw.SimpleText(string.upper(tostring(display.Subtitle or "GALACTIC REPUBLIC")), prefix .. "Sub", x + 32, y + 76, P.yellow, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("//  " .. tostring(GRN_DEFCON.Config.OnlineLabel or "ONLINE"), prefix .. "Sub", x + 32 + subW + 12, y + 76, P.green, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Abschnitt
        local sy = y + headH + 22
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(x + 30, sy + 4, 3, 22)
        draw.SimpleText("AKTIVE SICHERHEITSSTUFE", prefix .. "Section", x + 44, sy + 15, P.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Statusbox
        local bx, by = x + 30, sy + 40
        local bw, bh = w - 60, (y + h - 104) - by
        surface.SetDrawColor(P.panel)
        surface.DrawRect(bx, by, bw, bh)
        surface.SetDrawColor(col.r, col.g, col.b, 18)
        surface.DrawRect(bx, by, bw, bh)
        surface.SetDrawColor(P.line)
        surface.DrawOutlinedRect(bx, by, bw, bh, 2)
        surface.SetDrawColor(col)
        surface.DrawRect(bx, by, 4, bh)

        draw.SimpleText("DEFCON", prefix .. "Sub", bx + 24, by + 24, P.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local numW = draw.SimpleText(tostring(level), prefix .. "Number", bx + 22, by + bh / 2 + 14, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        local tx = bx + math.max(120, 22 + numW + 26)
        local maxW = bx + bw - tx - 20

        draw.SimpleText(Fit(string.upper(tostring(data.Name or "UNKNOWN")), prefix .. "Name", maxW), prefix .. "Name", tx, by + bh / 2 - 22, P.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(Fit(string.upper(tostring(data.State or "")), prefix .. "Section", maxW), prefix .. "Section", tx, by + bh / 2 + 16, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(Fit(string.upper(tostring(data.Short or "")), prefix .. "Small", maxW), prefix .. "Small", tx, by + bh / 2 + 44, P.soft, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Öffnen-Button im Stil der Funk-Buttons (gefüllt, sobald man nah genug ist)
        local px, py, pw, ph = x + 30, y + h - 84, w - 60, 56
        if playerClose then
            surface.SetDrawColor(P.yellow.r, P.yellow.g, P.yellow.b, 215)
            surface.DrawRect(px, py, pw, ph)
            surface.SetDrawColor(P.yellow.r, P.yellow.g, P.yellow.b, 185)
        else
            surface.SetDrawColor(P.panel)
            surface.DrawRect(px, py, pw, ph)
            surface.SetDrawColor(P.line)
        end
        surface.DrawOutlinedRect(px, py, pw, ph, 2)
        draw.SimpleText(tostring(display.Prompt or "PRESS [E] TO OPEN"), prefix .. "Prompt", px + pw / 2, py + ph / 2, playerClose and P.bg or P.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Ecken-Markierungen + Rahmen
        if SYMUI then
            SYMUI.CutOutline(x, y, w, h, SYMUI.Accent(120), 24, "tlbr")
            cam.End3D2D()
            return
        end
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(x, y, 28, 4)
        surface.DrawRect(x, y, 4, 28)
        surface.DrawRect(x + w - 28, y + h - 4, 28, 4)
        surface.DrawRect(x + w - 4, y + h - 28, 4, 28)
        surface.SetDrawColor(P.line)
        surface.DrawOutlinedRect(x, y, w, h, 2)
    cam.End3D2D()
end
