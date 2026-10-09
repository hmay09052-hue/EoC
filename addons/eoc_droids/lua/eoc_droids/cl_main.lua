local C = EOCDroids.Config

surface.CreateFont("EOCDroids.Title", {
    font = SYMUI and SYMUI.FontFace and SYMUI.FontFace("body") or "Roboto",
    size = 30,
    weight = 600,
    italic = true,
    shadow = true,
    antialias = true,
})

surface.CreateFont("EOCDroids.Debug", {
    font = "Roboto",
    size = 34,
    weight = 300,
    shadow = true,
    antialias = true,
})

-- SymChars-Design wird genutzt, wenn vorhanden
function EOCDroids.RoundedBox(radius, x, y, w, h, col)
    if SYMUI and SYMUI.RoundedBox then
        return SYMUI.RoundedBox(radius, x, y, w, h, col)
    end
    return draw.RoundedBox(radius, x, y, w, h, col)
end

-- ============================================================
-- NACHRICHTEN
-- ============================================================
local kindColors = {
    [0] = Color(120, 190, 255),
    [1] = Color(90, 255, 120),
    [2] = Color(255, 170, 40),
}

net.Receive("EOCDroids.Message", function()
    local text = net.ReadString()
    local kind = net.ReadUInt(2)
    chat.AddText(Color(255, 60, 60), "[EoC Droids] ", kindColors[kind] or color_white, text)
end)

-- ============================================================
-- DEBUG
-- ============================================================
EOCDroids.DebugEnabled = C.Debug

concommand.Add("eoc_droids_debug", function()
    if not LocalPlayer():IsAdmin() then
        chat.AddText(Color(255, 60, 60), "[EoC Droids] ", color_white, "Nur fuer Admins.")
        return
    end
    EOCDroids.DebugEnabled = not EOCDroids.DebugEnabled
    chat.AddText(Color(255, 60, 60), "[EoC Droids] ", color_white, "Debug " .. (EOCDroids.DebugEnabled and "an" or "aus") .. ".")
end)

-- ============================================================
-- DYNAMISCHE LICHTER (begrenzt, damit grosse Schlachten fluessig bleiben)
-- ============================================================
local lightIndex = 0

function EOCDroids.CanDoEffects(pos)
    return EyePos():DistToSqr(pos) < C.EffectDistance * C.EffectDistance
end

function EOCDroids.NextLightId()
    lightIndex = (lightIndex + 1) % math.max(1, C.MaxDynamicLights)
    return 61000 + lightIndex
end

function EOCDroids.Light(pos, col, size, duration, brightness, id)
    if not C.DynamicLights then return end
    if not EOCDroids.CanDoEffects(pos) then return end

    local dl = DynamicLight(id or EOCDroids.NextLightId())
    if not dl then return end

    dl.pos = pos
    dl.r = col.r
    dl.g = col.g
    dl.b = col.b
    dl.brightness = brightness or 2
    dl.size = size
    dl.decay = size / math.max(duration, 0.01)
    dl.dietime = CurTime() + duration
end

-- ============================================================
-- AQUA-DROIDE: Blitzentladung
-- ============================================================
net.Receive("EOCDroids.AquaZap", function()
    local droid = net.ReadEntity()
    local count = net.ReadUInt(4)
    local targets = {}
    for i = 1, count do
        targets[i] = net.ReadEntity()
    end

    if not IsValid(droid) then return end
    droid.ZapTargets = targets
    droid.ZapUntil = CurTime() + 1
end)

-- ============================================================
-- TOOL-MENUE: Zeile mit Icon + Regler fuer einen Droidentyp
-- ============================================================
function EOCDroids.AddDroidSlider(panel, entry, convar)
    local row = vgui.Create("DPanel")
    row:SetTall(48)
    row:SetPaintBackground(false)

    local icon = vgui.Create("SpawnIcon", row)
    icon:Dock(LEFT)
    icon:SetWide(48)
    icon:SetModel(EOCDroids.IsValidModel(entry.model) and entry.model or "models/combine_soldier.mdl")
    icon:SetTooltip(entry.name)

    local slider = vgui.Create("DNumSlider", row)
    slider:Dock(FILL)
    slider:DockMargin(6, 0, 0, 0)
    slider:SetText(entry.name)
    slider:SetMinMax(0, C.MaxPerType)
    slider:SetDecimals(0)
    slider:SetDark(true)
    slider:SetConVar(convar)

    panel:AddItem(row)
end
