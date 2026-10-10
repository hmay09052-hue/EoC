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

		local fontName = string.format("SSE_%s_%d_%d", name, size, weight)
		_imguiFontToGmodFont[font] = fontName
		if not _createdFonts[fontName] then
			-- Server-Design: Agency FB -> SymChars-Überschrift, Roboto -> SymChars-Text
			local face = name
			if SYMUI then
				if name == "Agency FB" then face = SYMUI.FontFace("head")
				elseif string.find(string.lower(name), "roboto", 1, true) then face = SYMUI.FontFace("body") end
			end
			surface.CreateFont(fontName, {
				font = face,
				extended = true,
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
    MainFrame:DockPadding(25, 25, 25, 25)
    MainFrame:SetMinimumSize(400, 200)

    local btnWide = 70
    local btnHeight = 25
    local lineColor = Color(255, 255, 255)

    function MainFrame:Paint(w, h)
        if SYMUI then -- Server-Design (SymChars)
            SYMUI.PaintWindow(w, h, nil, { header = 0 })
            return
        end
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 210))
        draw.RoundedBox(0, 10, 10, 5, h - 20, lineColor)
        draw.RoundedBox(0, 10, 10, w - btnWide - 30, 5, lineColor)
        draw.RoundedBox(0, 10, h - 15, w - 20, 5, lineColor)
        draw.RoundedBox(0, w - 15, 10 + btnHeight + 10, 5, h - 20 - btnHeight - 10, lineColor)
    end

    

    function MainFrame:Think()
        if input.IsKeyDown(KEY_ESCAPE) then
            self:Remove()
        end
    end

    local TitlePanel = vgui.Create("DPanel", MainFrame)
    TitlePanel:Dock(TOP)
    TitlePanel:SetTall(55)
    TitlePanel:DockMargin(0, 0, 0, 5)
    local textPadding = 20
    title = string.upper(title)

    function MainFrame:SetNewTitle(text)
        title = string.upper(text)
    end

    local currentFont = SSE.xFont(SSE.Config.FrameTitleFont)

    function TitlePanel:Paint(w, h)
        surface.SetFont(currentFont)
        local textW, textH = surface.GetTextSize(title)
        self:SetTall(textH)
        if SYMUI then
            draw.DrawText(title, currentFont, 0, 0, SYMUI.col.text, TEXT_ALIGN_LEFT)
            surface.SetDrawColor(SYMUI.Accent())
            surface.DrawRect(0, h - 3, math.min(80, w), 2)
            surface.SetDrawColor(SYMUI.col.line2)
            surface.DrawRect(math.min(80, w), h - 3, math.max(0, w - 80), 1)
            return
        end
        draw.RoundedBox(0, 0, 0, textW + textPadding, h - 3, Color(255, 255, 255))
        draw.DrawText(title, currentFont, 10, 0, Color(0, 0, 0), TEXT_ALIGN_LEFT)
    end

    local CloseButton = vgui.Create("DButton", MainFrame)
    CloseButton:SetText("")

    function CloseButton:Paint(w, h)
        if SYMUI then
            local col = SYMUI.PaintButton(self, w, h, "danger")
            draw.SimpleText("X", "symchars.small.bold", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        draw.RoundedBox(0, 0, 0, w, h, Color(155, 0, 0, 255))
    end

    function ResizeButtonToFrameSize(w, h)
        CloseButton:SetPos(w - btnWide - 10, 10)
        CloseButton:SetSize(btnWide, btnHeight)
    end

    function CloseButton:DoClick()
        MainFrame:Remove()
    end

    ResizeButtonToFrameSize(MainFrame:GetWide(), MainFrame:GetTall())

    function MainFrame:OnSizeChanged(w, h)
        ResizeButtonToFrameSize(w, h)
    end

    return MainFrame
end



function SSE:Button(panel, text, func, style)
    style = style or "b"
    local DButton = vgui.Create("DButton",panel)

    DButton:SetText("")
    DButton.textfont = SSE.xFont(SSE.Config.ButtonFont)
    surface.SetFont(DButton.textfont)
    local textW, textH = surface.GetTextSize(text)

    DButton:SetTall(textH+SSEH(10))
    DButton:SetWide(textW+SSEW(30))

    function DButton:SetNewText(text)
        self.printtext = text

        surface.SetFont(DButton.textfont)
        local textW, textH = surface.GetTextSize(text)
    
        DButton:SetTall(textH+SSEH(10))
        DButton:SetWide(textW+SSEW(30))
    end

    DButton.printtext = text
    DButton.btncolor = Color(0,0,0,210)
    DButton.akzent = Color(200,200,200,255)
    DButton.akzenthover = Color(255,255,255,255)
    DButton.textcolor = Color(200,200,200,255)
    DButton.textcolorhover = Color(255,255,255,255)
    DButton.akcl = DButton.akzent
    DButton.txtcl = DButton.textcolor
    DButton.akzentsize = 3
    DButton.fillcolor = Color(0,0,0,200)
    if SYMUI then -- Server-Design: dunkle Fläche, Akzent beim Überfahren
        DButton.akzent = SYMUI.col.line3
        DButton.akzenthover = SYMUI.LiveAccent()
        DButton.textcolor = SYMUI.col.dim
        DButton.textcolorhover = SYMUI.col.text
        DButton.fillcolor = SYMUI.col.panel2
    end
    local top = string.find(style, "t")
    local bot = string.find(style, "b")
    local left = string.find(style, "l")
    local right = string.find(style, "r")
    local fill = string.find(style, "c")
    
    function DButton:Paint(w,h)
        self.akcl = self:IsHovered() and self.akzenthover or self.akzent
        self.txtcl = self:IsHovered() and self.textcolorhover or self.textcolor
        
        if fill then
            draw.RoundedBox(0, 0, 0, w, h, DButton.fillcolor)
        end
        
        if top then
            draw.RoundedBox(0, 0, 0, w, self.akzentsize, DButton.akcl)
        end
        
        if bot then
            draw.RoundedBox(0, 0, h-self.akzentsize, w, self.akzentsize, DButton.akcl)
        end   

        if left then
            draw.RoundedBox(0, 0, 0, self.akzentsize, h, DButton.akcl)
        end

        if right then
            draw.RoundedBox(0, w-self.akzentsize, 0, self.akzentsize, h, DButton.akcl)
        end
    
        surface.SetFont(self.textfont)
        local txtW, txtH = surface.GetTextSize(text)

        draw.DrawText(self.printtext, self.textfont, w/2, h/2-txtH/2, self.txtcl, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function DButton:DoClick()
        func(self)
    end
    
    return DButton
end


function SSE:TextEntry(panel,placeholder)
	local TextEntry = vgui.Create( "DTextEntry", panel ) -- create the form as a child of frame

    TextEntry:SetFont(SSE.xFont("!Agency FB@35#1"))
    TextEntry:SetPlaceholderText(placeholder)
    TextEntry:SetTextColor(Color(255,255,255,255))
    TextEntry:SetPlaceholderColor(Color(200,200,200))
    TextEntry:SetCursorColor(Color(255,255,255,255))
    TextEntry:SetDrawBackground(false)
    TextEntry:SetDrawBorder(true)
    function TextEntry:PaintOver(w,h) 
        if SYMUI then
            surface.SetDrawColor(self:HasFocus() and SYMUI.Accent() or SYMUI.col.line2)
            surface.DrawOutlinedRect(0,0,w,h,1)
            return
        end
        surface.SetDrawColor( 255, 255, 255, 128 )
        surface.DrawOutlinedRect(0,0,w,h,1)
        return
    end
	return TextEntry
end

function SSE:ScrollBar(parent) 
    local DScrollPanel = vgui.Create("DScrollPanel", parent)
    --DScrollPanel:SetSize(400, 250)
    --DScrollPanel:Center()

    local sbar = DScrollPanel:GetVBar()
    function sbar:Paint(w, h)
        draw.RoundedBox(0, SSEW(5), 0, SSEW(10), h, Color(0, 0, 0, 100))
    end
    function sbar.btnUp:Paint(w, h)
        --draw.RoundedBox(0, SSEW(5), 0, SSEW(10), h, Color(175, 175, 175))
    end
    function sbar.btnDown:Paint(w, h)
        --draw.RoundedBox(0, SSEW(5), 0, SSEW(10), h, Color(175, 175, 175))
    end
    function sbar.btnGrip:Paint(w, h)
        if SYMUI then draw.RoundedBox(0, SSEW(5), 0, SSEW(10), h, SYMUI.Accent(self:IsHovered() and 255 or 150)) return end
        draw.RoundedBox(0, SSEW(5), 0, SSEW(10), h, Color(255, 255, 255))
    end

    return DScrollPanel
end










local matGradUp = Material("gui/gradient_up")
local matGradCenter = Material("gui/center_gradient")

local hudAlpha = 0
local hudEnt

local function drawShadowText(text, font, x, y, col, alpha)
    draw.SimpleText(text, font, x + 2, y + 2, Color(0, 0, 0, 200 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(text, font, x, y, ColorAlpha(col, col.a * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

function SSE:TraceEntityHUD()

    local ent = LocalPlayer():GetEyeTrace().Entity
    local visible = IsValid(ent) and !ent:IsWorld() and ent.SSE_HUDName
        and ent:GetPos():DistToSqr(LocalPlayer():GetPos()) <= SSE.Config.HUDDistance*SSE.Config.HUDDistance

    if visible then hudEnt = ent end
    hudAlpha = math.Approach(hudAlpha, visible and 1 or 0, FrameTime() * 6)
    if hudAlpha <= 0 or !IsValid(hudEnt) then return end

    local cfg = SSE.Config.HUD
    local name = hudEnt.SSE_HUDName or ""
    local interactbind = string.upper(input.LookupBinding("use") or "E")
    local interactText = string.format(SSE.Config.HUDInteractLang, interactbind)

    local titleFont = SSE.xFont(cfg.TitleFont)
    local aureFont = SSE.xFont(cfg.AurebeshFont)
    local interactFont = SSE.xFont(cfg.InteractFont)

    surface.SetFont(titleFont)
    local tw, th = surface.GetTextSize(name)
    surface.SetFont(aureFont)
    local aw, ah = surface.GetTextSize(name)
    surface.SetFont(interactFont)
    local iw, ih = surface.GetTextSize(interactText)

    local padX, padY, gap = SSEW(14), SSEH(8), SSEH(2)
    local w = math.max(tw, aw, iw) + padX * 2
    local h = th + ah + ih + gap * 2 + padY * 2
    local x = math.floor(ScrW() / 2 - w / 2)
    local y = math.floor(ScrH() / 2 - SSEH(30))

    -- Hintergrund
    surface.SetDrawColor(ColorAlpha(cfg.Background, cfg.Background.a * hudAlpha))
    surface.DrawRect(x, y, w, h)
    surface.SetMaterial(matGradUp)
    surface.SetDrawColor(0, 0, 0, 120 * hudAlpha)
    surface.DrawTexturedRect(x, y, w, h)

    -- Akzentlinie unten
    surface.SetMaterial(matGradCenter)
    surface.SetDrawColor(ColorAlpha(cfg.Accent, cfg.Accent.a * hudAlpha))
    surface.DrawTexturedRect(x, y + h - 2, w, 2)

    local cx = ScrW() / 2
    local cy = y + padY
    drawShadowText(name, titleFont, cx, cy, cfg.TitleColor, hudAlpha)
    cy = cy + th + gap
    drawShadowText(name, aureFont, cx, cy, cfg.AurebeshColor, hudAlpha)
    cy = cy + ah + gap
    drawShadowText(interactText, interactFont, cx, cy, cfg.InteractColor, hudAlpha)
end

hook.Add("HUDPaint", "SSE.HudPaint", function()
    SSE:TraceEntityHUD()
end)





















