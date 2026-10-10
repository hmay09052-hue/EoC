if not CLIENT then return end

Tarnnetz = Tarnnetz or {}

local C = Tarnnetz.Config
local L = C.Lang

local SND_CLICK = 'buttons/lightswitch2.wav'

-- Farben passend zum Echoes of Clones HUD (werden mit SymChars auf das Server-Design umgestellt)
local P = {
    yellow  = Color(252, 178, 73),
    yellowD = Color(252, 178, 73, 56),
    white   = Color(244, 241, 233),
    text    = Color(216, 219, 225),
    soft    = Color(157, 163, 173),
    muted   = Color(101, 107, 117),
    bg      = Color(7, 9, 12, 240),
    panel   = Color(8, 11, 15, 220),
    panel2  = Color(14, 18, 23, 235),
    line    = Color(207, 216, 228, 38),
    lineS   = Color(207, 216, 228, 77),
    red     = Color(225, 88, 88),
    green   = Color(74, 203, 130),
}
Tarnnetz.UIColors = P
if SYMUI then SYMUI.ApplyEoCPalette(P) end -- SymChars-Design

local function Face(kind, fallback) return SYMUI and SYMUI.FontFace(kind) or fallback end
surface.CreateFont('Tarnnetz_Title',  { font = Face('head', 'Bebas Neue'), size = 34, weight = 400, extended = true })
surface.CreateFont('Tarnnetz_Head',   { font = Face('head', 'Bebas Neue'), size = 26, weight = 400, extended = true })
surface.CreateFont('Tarnnetz_Button', { font = Face('head', 'Bebas Neue'), size = 22, weight = 400, extended = true })
surface.CreateFont('Tarnnetz_Sub',    { font = Face('body', 'Montserrat'), size = 12, weight = 600, extended = true })
surface.CreateFont('Tarnnetz_Text',   { font = Face('body', 'Montserrat'), size = 14, weight = 500, extended = true })
surface.CreateFont('Tarnnetz_Small',  { font = Face('body', 'Montserrat'), size = 12, weight = 500, extended = true })

local function PlayClick() surface.PlaySound(SND_CLICK) end

---------------------------------------------------------------------------------------------------------------
-- Vorschau der Tarnmuster (VertexLitGeneric -> UnlitGeneric, damit es im Menü sauber gezeichnet wird)
---------------------------------------------------------------------------------------------------------------
local previews = {}

local function GetPreview(index)
    if previews[index] ~= nil then return previews[index] or nil end

    local camo = C.Camos[index]
    local src = camo and Material(camo.mat)
    if not src or src:IsError() then
        previews[index] = false
        return nil
    end

    local mat = CreateMaterial('tarnnetz_preview_' .. index, 'UnlitGeneric', { ['$basetexture'] = 'color/white' })
    local tex = src:GetTexture('$basetexture')
    if tex and not tex:IsError() then mat:SetTexture('$basetexture', tex) end

    previews[index] = mat
    return mat
end

---------------------------------------------------------------------------------------------------------------
-- UI Bausteine
---------------------------------------------------------------------------------------------------------------
local function MakeButton(parent, label, onClick)
    local b = vgui.Create('DButton', parent)
    b:SetText('')
    b.Label = label
    b.Accent = P.yellow
    b.Paint = function(s, w, h)
        if SYMUI then
            local tc = SYMUI.PaintEoCButton(s, w, h, P.red)
            draw.SimpleText(s.Label, 'Tarnnetz_Button', w / 2, h / 2, tc, 1, 1)
            return
        end
        local hov = s:IsHovered()
        surface.SetDrawColor(hov and P.panel2 or P.panel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(hov and P.lineS or P.line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(s.Label, 'Tarnnetz_Button', w / 2, h / 2, P.white, 1, 1)
    end
    b.DoClick = function(s)
        PlayClick()
        if onClick then onClick(s) end
    end
    return b
end

local function MakeCamoCard(parent, index, onPick)
    local camo = C.Camos[index]
    local card = vgui.Create('DButton', parent)
    card:SetText('')
    card.DoClick = function()
        PlayClick()
        onPick(index)
    end
    card.Paint = function(s, w, h)
        local hov = s:IsHovered()
        s._hov = Lerp(FrameTime() * 12, s._hov or 0, hov and 1 or 0)

        -- Fläche + Rahmen
        if SYMUI then
            SYMUI.PaintButton(s, w, h, 'card')
        else
            surface.SetDrawColor(hov and P.panel2 or P.panel)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(hov and ColorAlpha(P.yellow, 185) or P.line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        -- Mustervorschau
        local pad = 8
        local pw, ph = w - pad * 2, h - 92
        local mat = GetPreview(index)
        if mat then
            surface.SetDrawColor(255, 255, 255)
            surface.SetMaterial(mat)
            surface.DrawTexturedRectUV(pad, pad, pw, ph, 0, 0, pw / 128, ph / 128)
        else
            surface.SetDrawColor(P.panel2)
            surface.DrawRect(pad, pad, pw, ph)
            draw.SimpleText('MATERIAL FEHLT', 'Tarnnetz_Sub', w / 2, pad + ph / 2, P.red, 1, 1)
        end
        surface.SetDrawColor(0, 0, 0, 120 - s._hov * 90)
        surface.DrawRect(pad, pad, pw, ph)
        surface.SetDrawColor(P.line)
        surface.DrawOutlinedRect(pad, pad, pw, ph, 1)

        -- Kennung oben links im Bild
        surface.SetFont('Tarnnetz_Sub')
        local tw = surface.GetTextSize(camo.short or '')
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(pad, pad, tw + 12, 18)
        draw.SimpleText(camo.short or '', 'Tarnnetz_Sub', pad + 6, pad + 9, P.yellow, 0, 1)

        -- Texte
        local ty = pad + ph + 8
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(pad, ty + 3, 2, 22)
        draw.SimpleText(string.upper(camo.name), 'Tarnnetz_Head', pad + 10, ty, hov and P.yellow or P.white)
        draw.SimpleText(camo.desc or '', 'Tarnnetz_Small', pad + 10, ty + 30, P.soft)
        draw.SimpleText(hov and 'AKTIVIEREN  >' or camo.mat, 'Tarnnetz_Sub', pad + 10, ty + 52, hov and P.green or P.muted)
    end
    return card
end

---------------------------------------------------------------------------------------------------------------
-- Auswahlmenü
---------------------------------------------------------------------------------------------------------------
local FRAME

function Tarnnetz.OpenMenu()
    if IsValid(FRAME) then FRAME:Remove() end

    local count = #C.Camos
    local cardW, cardH, gap = 210, 260, 12
    local w = math.min(ScrW() - 40, count * cardW + (count - 1) * gap + 40)
    local h = cardH + 170

    FRAME = vgui.Create('DFrame')
    FRAME:SetTitle('')
    FRAME:SetSize(w, h)
    FRAME:Center()
    FRAME:ShowCloseButton(false)
    FRAME:SetDraggable(false)
    FRAME:MakePopup()
    FRAME:DockPadding(20, 76, 20, 20)
    FRAME._start = SysTime()
    FRAME.Paint = function(s, pw, ph)
        Derma_DrawBackgroundBlur(s, s._start)
        if SYMUI then
            SYMUI.PaintWindow(pw, ph, nil, { header = 66 })
            SYMUI.PaintEoCHeader(L.title, L.sub, 'Tarnnetz_Title', 'Tarnnetz_Sub', nil, 'BEREIT', P.green)
            return
        end
        surface.SetDrawColor(P.bg)
        surface.DrawRect(0, 0, pw, ph)
        surface.SetDrawColor(P.line)
        surface.DrawOutlinedRect(0, 0, pw, ph, 1)
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(0, 0, pw, 2)
        surface.SetDrawColor(P.line)
        surface.DrawRect(20, 64, pw - 40, 1)
        draw.SimpleText(string.upper(L.title), 'Tarnnetz_Title', 20, 24, P.white, 0, 1)
        local subW = draw.SimpleText(L.sub, 'Tarnnetz_Sub', 21, 46, P.yellow, 0, 1)
        draw.SimpleText('//  BEREIT', 'Tarnnetz_Sub', 21 + subW + 8, 46, P.green, 0, 1)
    end
    FRAME.OnKeyCodePressed = function(s, key)
        if key == KEY_ESCAPE then s:Remove() end
    end

    -- Überschrift
    local section = vgui.Create('DPanel', FRAME)
    section:Dock(TOP)
    section:SetTall(26)
    section.Paint = function(_, pw, ph)
        local text = string.upper(L.choose)
        local tw = draw.SimpleText(text, 'Tarnnetz_Sub', 10, ph / 2, P.soft, 0, 1)
        surface.SetDrawColor(P.yellow)
        surface.DrawRect(0, 6, 2, ph - 12)
        surface.SetDrawColor(P.line)
        surface.DrawRect(tw + 20, ph / 2, pw - tw - 20, 1)
    end

    -- Karten
    local row = vgui.Create('DPanel', FRAME)
    row:Dock(TOP)
    row:DockMargin(0, 6, 0, 0)
    row:SetTall(cardH)
    row.Paint = nil

    local function Pick(index)
        net.Start('tarnnetz_select')
            net.WriteUInt(index, 8)
        net.SendToServer()
        if IsValid(FRAME) then FRAME:Remove() end
    end

    local cw = math.floor((w - 40 - (count - 1) * gap) / count)
    for i = 1, count do
        local card = MakeCamoCard(row, i, Pick)
        card:Dock(LEFT)
        card:SetWide(cw)
        if i < count then card:DockMargin(0, 0, gap, 0) end
    end

    -- Fußzeile
    local foot = vgui.Create('DPanel', FRAME)
    foot:Dock(BOTTOM)
    foot:SetTall(38)
    foot.Paint = function(_, pw, ph)
        draw.SimpleText(L.hint, 'Tarnnetz_Small', 0, ph / 2, P.muted, 0, 1)
        draw.SimpleText(string.format('Enttarnung ab %d m Droiden-Abstand', Tarnnetz.Meters(C.Radius)), 'Tarnnetz_Small', 0, ph / 2 + 16, P.soft, 0, 1)
    end

    local cancel = MakeButton(foot, string.upper(L.cancel), function()
        if IsValid(FRAME) then FRAME:Remove() end
    end)
    cancel:Dock(RIGHT)
    cancel:SetWide(150)
end

net.Receive('tarnnetz_open', function()
    Tarnnetz.OpenMenu()
end)

net.Receive('tarnnetz_notify', function()
    local msg = net.ReadString()
    local kind = net.ReadUInt(2)
    local icon = kind == 2 and NOTIFY_ERROR or (kind == 1 and NOTIFY_GENERIC or NOTIFY_HINT)
    notification.AddLegacy(msg, icon, 4)
    surface.PlaySound(kind == 2 and 'buttons/button10.wav' or 'buttons/button15.wav')
end)

net.Receive('tarnnetz_chat', function()
    local ply = net.ReadEntity()
    if not IsValid(ply) then return end
    chat.AddText(P.yellow, '[' .. L.title .. '] ', team.GetColor(ply:Team()), ply:Nick(), P.white, ' ' .. L.chat)
end)
