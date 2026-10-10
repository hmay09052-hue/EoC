-- Everything was coded in 1920x1080 - just Convert it
local w = 1920
local h = 1080

function SSEW(sw)
return ScrW() * ((sw or 0) / w)
end

function SSEH(sh)
return ScrH() * ((sh or 0) / h)
end



-- Taken from PixelUI
SSE_Imgur_Materials = {}

file.CreateDir("SSE")

function SSE.GetImgur(id, callback, useproxy, matSettings)
    if SSE_Imgur_Materials[id] then return callback(SSE_Imgur_Materials[id]) end

    if file.Exists("SSE/" .. id .. ".png", "DATA") then
        SSE_Imgur_Materials[id] = Material("../data/SSE/" .. id .. ".png", matSettings or "noclamp smooth mips")
        return callback(SSE_Imgur_Materials[id])
    end

    http.Fetch(useproxy and "https://proxy.duckduckgo.com/iu/?u=https://i.imgur.com" or "https://i.imgur.com/" .. id .. ".png",
        function(body, len, headers, code)
            if len > 2097152 then
                SSE_Imgur_Materials[id] = Material("nil")
                return callback(SSE_Imgur_Materials[id])
            end
            file.Write("SSE/" .. id .. ".png", body)
            SSE_Imgur_Materials[id] = Material("../data/SSE/" .. id .. ".png", matSettings or "noclamp smooth mips")

            return callback(SSE_Imgur_Materials[id])
        end,
        function(error)
            if useproxy then
                SSE_Imgur_Materials[id] = Material("nil")
                return callback(SSE_Imgur_Materials[id])
            end
            return SSE.GetImgur(id, callback, true)
        end
    )
end


function SSE.Scale(value)
    return math.max(value * (ScrH() / 1440), 1)
end

-- IMGUI FONT

-- String->Bool mappings for whether font has been created
local _createdFonts = {}

-- Cached IMGUIFontNamd->GModFontName
local _imguiFontToGmodFont = {}

local EXCLAMATION_BYTE = string.byte("!")
function SSE.xFont(font, defaultSize)
	-- special font
	if string.byte(font, 1) == EXCLAMATION_BYTE then

		local existingGFont = _imguiFontToGmodFont[font]
		if existingGFont then
			return existingGFont
		end

		-- Font not cached; parse the font
		local name, size, weight = font:match("!([^@]+)@([^#]+)#(.+)")
		if size then size = tonumber(size) end
		if weight then weight = tonumber(weight) end

		if not size and defaultSize then
			name = font:match("^!([^@]+)$")
			size = defaultSize
		end

		weight = weight or 1  -- Default weight if not specified
        print(weight)

		local fontName = string.format("SSE_%s_%d_%d", name, size, weight)
		_imguiFontToGmodFont[font] = fontName
		if not _createdFonts[fontName] then
			surface.CreateFont(fontName, {
				font = name,
				size = SSE.Scale(size),
				weight = weight
			})
			_createdFonts[fontName] = true
		end

		return fontName
	end
	return font
end



function SSE:DrawTextShadow(string, font, x, y, color, align, shadowcolor)

    if shadowcolor then 
        if !IsColor(shadowcolor) then shadowcolor = Color(0,0,0) end
    else
        shadowcolor = Color(0,0,0) 
    end

    draw.DrawText(string,font, x+1, y+1, shadowcolor, align)
    draw.DrawText(string,font, x, y, color, align)
    
end



---------------------------------------------------------------------------------------------------------------
-- Bausteine im Server-Design (siehe sse/cl_theme.lua): abgeschrägte Platten, Bernstein-Akzent,
-- BigNoodle-Überschriften mit Aurebesh-Zeile darunter.
---------------------------------------------------------------------------------------------------------------
local function UI() return SSE.UI end

function SSE:DefaultFrame(title)
    title = title or "Frame"

    local MainFrame = vgui.Create("DFrame")
    MainFrame:SetSize(600, 400)
    MainFrame:Center()
    MainFrame:SetDraggable(true)
    MainFrame:SetTitle("")
    MainFrame:ShowCloseButton(false)
    MainFrame:SetSizable(true)
    MainFrame:MakePopup()
    MainFrame:DockPadding(SSEW(28), SSEH(22), SSEW(28), SSEH(24))
    MainFrame:SetMinimumSize(400, 200)
    MainFrame.OpenTime = SysTime()

    local ui = UI()
    ui.Sound("open")

    function MainFrame:Paint(w, h)
        local u = UI()
        local c = u.S(18)
        local fade = math.Clamp((SysTime() - self.OpenTime) * 5, 0, 1)
        surface.SetAlphaMultiplier(fade)
            u.Cut(0, 0, w, h, u.col.panel, c, "tlbr")
            u.Scanlines(0, 0, w, h, 25, 5)
            u.CutOutline(0, 0, w, h, u.col.line2, c, "tlbr")
            -- Akzentkanten
            u.Box(0, c, u.S(3), h - c * 2, u.Accent())
            u.Box(c, 0, u.S(120), u.S(3), u.Accent())
            u.Box(w - c - u.S(60), h - u.S(3), u.S(60), u.S(3), u.Accent(160))
            -- Ecken-Markierung unten links
            u.Box(u.S(8), h - u.S(8) - u.S(14), 1, u.S(14), u.col.line3)
            u.Box(u.S(8), h - u.S(8), u.S(14), 1, u.col.line3)
        surface.SetAlphaMultiplier(1)
    end

    function MainFrame:Think()
        if input.IsKeyDown(KEY_ESCAPE) then
            self:Remove()
        end
    end

    local TitlePanel = vgui.Create("DPanel", MainFrame)
    TitlePanel:Dock(TOP)
    TitlePanel:DockMargin(0, 0, 0, SSEH(12))
    title = string.upper(title)

    function MainFrame:SetNewTitle(text)
        title = string.upper(text)
    end

    local function TitleHeight()
        local _, th = ui.TextSize("AG", "sse.h1")
        return th + ui.S(28)
    end
    TitlePanel:SetTall(TitleHeight())

    function TitlePanel:Paint(w, h)
        local u = UI()
        local tw, th = u.TextSize(title, "sse.h1")
        u.TextFit(title, "sse.h1", 0, 0, u.col.text, w - u.S(110))
        u.Aurebesh(title, "sse.aure", 0, th + u.S(1), u.Accent(200), nil, nil, w - u.S(110))
        u.Box(0, h - 1, w, 1, u.col.line)
        u.Box(0, h - 2, math.min(w, tw + u.S(24)), 2, u.Accent())
    end

    local CloseButton = vgui.Create("DButton", MainFrame)
    CloseButton:SetText("")

    function CloseButton:Paint(w, h)
        local u = UI()
        local hovered = self:IsHovered()
        local c = u.S(7)
        u.Cut(0, 0, w, h, hovered and u.col.red or u.col.panel3, c, "tlbr")
        u.CutOutline(0, 0, w, h, hovered and u.col.red or u.col.line2, c, "tlbr")
        local s = math.min(w, h)
        u.Icon("close", w / 2 - s / 2, h / 2 - s / 2, s, hovered and color_white or u.col.dim)
    end

    function CloseButton:OnCursorEntered()
        UI().Sound("hover")
    end

    local function ResizeButtonToFrameSize(w, h)
        local size = ui.S(40)
        CloseButton:SetPos(w - size - SSEW(22), SSEH(20))
        CloseButton:SetSize(size, size)
    end

    function CloseButton:DoClick()
        UI().Sound("click")
        MainFrame:Remove()
    end

    ResizeButtonToFrameSize(MainFrame:GetWide(), MainFrame:GetTall())

    function MainFrame:OnSizeChanged(w, h)
        ResizeButtonToFrameSize(w, h)
    end

    return MainFrame
end



-- style: Buchstaben-Kombination für Akzentkanten t (oben), b (unten), l (links), r (rechts), c (gefüllt)
-- btn.akzent / btn.akzenthover können von außen gesetzt werden (z.B. Grün/Rot für einen Status).
function SSE:Button(panel, text, func, style)
    style = style or "b"
    local DButton = vgui.Create("DButton",panel)
    local ui = UI()

    DButton:SetText("")
    DButton.textfont = SSE.xFont(SSE.Config.ButtonFont)
    surface.SetFont(DButton.textfont)
    local textW, textH = surface.GetTextSize(tostring(text))

    DButton:SetTall(textH+SSEH(14))
    DButton:SetWide(textW+SSEW(36))

    function DButton:SetNewText(text)
        self.printtext = text

        surface.SetFont(DButton.textfont)
        local textW, textH = surface.GetTextSize(tostring(text))
    
        DButton:SetTall(textH+SSEH(14))
        DButton:SetWide(textW+SSEW(36))
    end

    DButton.printtext = text
    DButton.akzent = ui.Accent(170)
    DButton.akzenthover = ui.Accent()
    DButton.textcolor = ui.col.dim
    DButton.textcolorhover = ui.col.text
    DButton.akcl = DButton.akzent
    DButton.txtcl = DButton.textcolor
    DButton.akzentsize = ui.S(3)
    DButton.fillcolor = ui.col.panel2
    DButton.hoverAnim = 0
    local top = string.find(style, "t")
    local bot = string.find(style, "b")
    local left = string.find(style, "l")
    local right = string.find(style, "r")
    local fill = string.find(style, "c")
    
    function DButton:Paint(w,h)
        local u = UI()
        local enabled = self:IsEnabled()
        local hovered = enabled and self:IsHovered()
        self.hoverAnim = u.Approach(self.hoverAnim, hovered and 1 or 0, 14)
        self.akcl = hovered and self.akzenthover or self.akzent
        self.txtcl = hovered and self.textcolorhover or self.textcolor

        local c = math.min(u.S(9), math.floor(h * 0.3))
        local a = self.akcl
        local s = self.akzentsize

        if fill then
            u.Cut(0, 0, w, h, self.fillcolor, c, "tlbr")
        end
        if self.hoverAnim > 0.01 then
            u.Cut(0, 0, w, h, u.Alpha(a, 45 * self.hoverAnim), c, "tlbr")
        end
        u.CutOutline(0, 0, w, h, hovered and u.Alpha(a, 200) or u.col.line2, c, "tlbr")

        if top then u.Box(c, 0, w - c, s, a) end
        if bot then u.Box(0, h - s, w - c, s, a) end
        if left then u.Box(0, c, s, h - c, a) end
        if right then u.Box(w - s, 0, s, h - c, a) end

        local col = enabled and self.txtcl or u.col.muted
        draw.SimpleText(string.upper(tostring(self.printtext or "")), self.textfont, w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function DButton:OnCursorEntered()
        if self:IsEnabled() then UI().Sound("hover") end
    end

    function DButton:DoClick()
        UI().Sound("click")
        func(self)
    end
    
    return DButton
end


function SSE:TextEntry(panel,placeholder)
	local TextEntry = vgui.Create( "DTextEntry", panel ) -- create the form as a child of frame
    local ui = UI()

    TextEntry:SetFont("sse.input")
    TextEntry:SetPlaceholderText(placeholder)
    TextEntry:SetTextColor(ui.col.text)
    TextEntry:SetPlaceholderColor(ui.col.muted)
    TextEntry:SetCursorColor(ui.Accent())
    TextEntry:SetHighlightColor(ui.Accent(90))
    TextEntry:SetPaintBackground(false)

    function TextEntry:Paint(w, h)
        local u = UI()
        local focus = self:HasFocus()
        u.Cut(0, 0, w, h, u.col.ink, u.S(7), "tlbr")
        u.CutOutline(0, 0, w, h, focus and u.Accent(200) or u.col.line2, u.S(7), "tlbr")
        u.Box(0, h - u.S(2), w - u.S(7), u.S(2), focus and u.Accent() or u.col.line)
        self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
        if self:GetText() == "" and not focus and self:GetPlaceholderText() then
            draw.SimpleText(self:GetPlaceholderText(), self:GetFont(), u.S(4), h / 2, self:GetPlaceholderColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
	return TextEntry
end

function SSE:ScrollBar(parent) 
    local DScrollPanel = vgui.Create("DScrollPanel", parent)

    local sbar = DScrollPanel:GetVBar()
    sbar:SetHideButtons(true)
    sbar:SetWide(SSEW(14))
    function sbar:Paint(w, h)
        UI().Box(w / 2 - 1, 0, 2, h, UI().col.line)
    end
    function sbar.btnGrip:Paint(w, h)
        local u = UI()
        u.Cut(w / 2 - u.S(3), 0, u.S(6), h, self:IsHovered() and u.Accent() or u.Accent(170), u.S(3), "tlbr")
    end

    return DScrollPanel
end










-- Blick-HUD: Name des Objekts mit Aurebesh-Zeile und Taste zum Benutzen
local interactbind = input.LookupBinding( "use" ) or "E"
function SSE:TraceEntityHUD()

    local ent = LocalPlayer():GetEyeTrace().Entity
    if !IsValid(ent) then return end
    if ent:IsWorld() then return end
    if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) > SSE.Config.HUDDistance*SSE.Config.HUDDistance then return end
    if not ent.SSE_HUDName then return end

    local u = UI()
    if not u then return end

    local cx, cy = ScrW() / 2, ScrH() / 2 + u.S(40)
    local name = string.upper(ent.SSE_HUDName or "")
    local key = string.upper(interactbind)
    local hint = string.format(SSE.Config.HUDInteractLang, key)

    local nw, nh = u.TextSize(name, "sse.h2")
    local hw = u.TextSize(hint, "sse.small")
    local w = math.max(nw, hw) + u.S(56)
    local h = nh + u.S(58)
    local x, y = cx - w / 2, cy
    local c = u.S(10)

    u.Cut(x, y, w, h, u.col.panel, c, "tlbr")
    u.CutOutline(x, y, w, h, u.col.line2, c, "tlbr")
    u.Box(x, y + c, u.S(3), h - c * 2, u.Accent())

    u.TextShadow(name, "sse.h2", cx, y + u.S(6), u.col.text, TEXT_ALIGN_CENTER)
    u.Aurebesh(name, "sse.aure.small", cx, y + u.S(6) + nh, u.Accent(200), TEXT_ALIGN_CENTER)
    u.Text(hint, "sse.small", cx, y + h - u.S(10), u.col.dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end

hook.Add("HUDPaint", "SSE.HudPaint", function()
    SSE:TraceEntityHUD()
end)
