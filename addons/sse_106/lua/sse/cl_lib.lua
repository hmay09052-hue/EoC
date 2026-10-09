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
        draw.RoundedBox(0, 0, 0, textW + textPadding, h - 3, Color(255, 255, 255))
        draw.DrawText(title, currentFont, 10, 0, Color(0, 0, 0), TEXT_ALIGN_LEFT)
    end

    local CloseButton = vgui.Create("DButton", MainFrame)
    CloseButton:SetText("")

    function CloseButton:Paint(w, h)
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
        draw.RoundedBox(0, SSEW(5), 0, SSEW(10), h, Color(255, 255, 255))
    end

    return DScrollPanel
end










local hudAurebesh
local function HUDAurebeshFont()
    if hudAurebesh == nil then
        hudAurebesh = false
        if SSE.Config.HUDShowAurebesh and file.Exists("resource/fonts/" .. (SSE.Config.HUDAurebeshFile or ""), "GAME") then
            hudAurebesh = SSE.xFont("!" .. SSE.Config.HUDAurebeshFont .. "@22#500")
        end
    end
    return hudAurebesh
end

local function HUDGradientBox(x, y, w, h, col)
    local steps = 12
    local stepH = h / steps
    for i = 0, steps - 1 do
        -- oben kräftiger, nach unten etwas heller
        surface.SetDrawColor(col.r, col.g, col.b, col.a * (1 - i / steps * 0.35))
        surface.DrawRect(x, math.floor(y + i * stepH), w, math.ceil(stepH))
    end
end

function SSE:TraceEntityHUD()

    local ent = LocalPlayer():GetEyeTrace().Entity
    if !IsValid(ent) then return end
    if ent:IsWorld() then return end
    if ent:GetPos():DistToSqr(LocalPlayer():GetPos()) > SSE.Config.HUDDistance*SSE.Config.HUDDistance then return end
    if !ent.SSE_HUDName then return end

    local name = string.upper(ent.SSE_HUDName)
    local key = string.upper(input.LookupBinding("use") or "E")
    local prompt = string.format(SSE.Config.HUDInteractLang, key)

    local nameFont = SSE.xFont("!Agency FB@52#1000")
    local promptFont = SSE.xFont("!Roboto Condensed@22#700")
    local aureFont = HUDAurebeshFont()

    surface.SetFont(nameFont)
    local nameW, nameH = surface.GetTextSize(name)
    local aureW, aureH = 0, 0
    if aureFont then
        surface.SetFont(aureFont)
        aureW, aureH = surface.GetTextSize(name)
    end
    surface.SetFont(promptFont)
    local promptW, promptH = surface.GetTextSize(prompt)

    local cx = ScrW() / 2
    local padX, padY = SSEW(14), SSEH(4)

    -- Name (+ Aurebesh) auf dunklem Kasten
    local boxW = math.max(nameW, aureW) + padX * 2
    local boxH = nameH + aureH + padY * 2
    local boxY = ScrH() / 2 - SSEH(40)
    HUDGradientBox(cx - boxW / 2, boxY, boxW, boxH, SSE.Config.HUDBoxColor)
    SSE:DrawTextShadow(name, nameFont, cx, boxY + padY, color_white, TEXT_ALIGN_CENTER)
    if aureFont then
        draw.SimpleText(name, aureFont, cx, boxY + padY + nameH, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    -- "Drücke [E] zum Interagieren!" mit orangem Rand
    local pW, pH = promptW + padX * 2, promptH + SSEH(10)
    local pX, pY = cx - pW / 2, boxY + boxH + SSEH(6)
    surface.SetDrawColor(SSE.Config.HUDPromptColor)
    surface.DrawRect(pX, pY, pW, pH)
    surface.SetDrawColor(SSE.Config.HUDAccentColor)
    surface.DrawOutlinedRect(pX, pY, pW, pH, 1)
    SSE:DrawTextShadow(prompt, promptFont, cx, pY + (pH - promptH) / 2, color_white, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "SSE.HudPaint", function()
    SSE:TraceEntityHUD()
end)




















