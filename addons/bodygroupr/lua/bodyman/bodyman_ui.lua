-- Client: UI-Bausteine im Echoes-of-Clones-Design.

BODYMAN.UI = BODYMAN.UI or {}
local UI = BODYMAN.UI

local function T() return BODYMAN.Theme end

-- SymChars-Design: Farben und Schriften des Charaktermenüs
if SYMUI and BODYMAN.Theme then
	local th, c = BODYMAN.Theme, SYMUI.col
	th.Yellow, th.YellowSoft = SYMUI.LiveAccent(), SYMUI.LiveAccent(105)
	local a = SYMUI.Accent()
	th.YellowHover = Color(math.min(255, a.r + 25), math.min(255, a.g + 25), math.min(255, a.b + 25))
	th.White, th.Text, th.Muted, th.Dim = c.text, c.text, c.dim, c.muted
	th.Panel, th.PanelSoft, th.PanelHover = Color(9, 11, 14, 248), c.panel2, c.panel3
	th.Line, th.LineStrong, th.Danger, th.Green = c.line, c.line2, c.red, c.green
end

function UI.Scale()
	return math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.62, 1.45)
end

function UI.PX(v)
	return math.max(1, math.floor(v * UI.Scale() + 0.5))
end

function UI.CreateFonts()
	local font = BODYMAN.Font or "Lato"
	local head = font
	if SYMUI then font, head = SYMUI.FontFace("body"), SYMUI.FontFace("head") end
	local function f(name, size, weight, face)
		surface.CreateFont(name, {
			font = face or font,
			size = math.max(9, math.floor(size * UI.Scale() + 0.5)),
			weight = weight,
			extended = true,
			antialias = true,
		})
	end

	f("Bodyman.Brand", SYMUI and 26 or 22, 900, head)
	f("Bodyman.Title", SYMUI and 34 or 28, 900, head)
	f("Bodyman.H2", 15, 900)
	f("Bodyman.Body", 14, 600)
	f("Bodyman.Button", 14, 800)
	f("Bodyman.Small", 12, 750)
	f("Bodyman.Tiny", 10, 800)
	-- SymChars / SSE-Schrank: große Abschnittstitel
	f("Bodyman.Section", SYMUI and 30 or 18, 700, head)
end

UI.CreateFonts()

hook.Add("OnScreenSizeChanged", "Bodyman.Fonts", function()
	UI.CreateFonts()
	if IsValid(BODYMAN.Menu) then BODYMAN.Menu:Remove() end
	if IsValid(BODYMAN.AdminPanel) then BODYMAN.AdminPanel:Remove() end
end)

function UI.Click()
	surface.PlaySound("ui/buttonclickrelease.wav")
end

function UI.FitText(text, font, maxw)
	surface.SetFont(font)
	if surface.GetTextSize(text) <= maxw then return text end

	local len = utf8.len(text) or #text
	while len > 1 do
		len = len - 1
		local stop = utf8.offset(text, len + 1) or (#text + 1)
		local short = string.sub(text, 1, stop - 1) .. "..."
		if surface.GetTextSize(short) <= maxw then return short end
	end
	return "..."
end

function UI.Pretty(name)
	name = tostring(name or "")
	name = string.gsub(name, "%.smd$", "")
	name = string.gsub(name, "%.mdl$", "")
	name = string.gsub(name, "[_%-]+", " ")
	name = string.Trim(name)
	return string.upper(name)
end

-- Zeichnen --------------------------------------------------------------------

function UI.DrawScanlines(x, y, w, h)
	surface.SetDrawColor(255, 255, 255, 4)
	for yy = y, y + h - 1, 5 do
		surface.DrawRect(x, yy, w, 1)
	end
end

function UI.DrawCorners(x, y, w, h, len, col)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, len, 1)
	surface.DrawRect(x, y, 1, len)
	surface.DrawRect(x + w - len, y, len, 1)
	surface.DrawRect(x + w - 1, y, 1, len)
	surface.DrawRect(x, y + h - 1, len, 1)
	surface.DrawRect(x, y + h - len, 1, len)
	surface.DrawRect(x + w - len, y + h - 1, len, 1)
	surface.DrawRect(x + w - 1, y + h - len, 1, len)
end

function UI.DrawSection(x, y, w, h)
	local th = T()
	surface.SetDrawColor(th.PanelSoft)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(th.Line)
	surface.DrawOutlinedRect(x, y, w, h, 1)
	surface.SetDrawColor(th.LineStrong)
	surface.DrawRect(x, y, w, math.max(1, UI.PX(2)))
end

local function StyleScrollbar(scroll)
	local bar = scroll:GetVBar()
	bar:SetWide(UI.PX(4))
	bar:SetHideButtons(true)
	function bar:Paint(w, h)
		surface.SetDrawColor(T().Line)
		surface.DrawRect(0, 0, w, h)
	end
	function bar.btnGrip:Paint(w, h)
		surface.SetDrawColor(self:IsHovered() and T().Yellow or T().YellowSoft)
		surface.DrawRect(0, 0, w, h)
	end
end
UI.StyleScrollbar = StyleScrollbar

-- Option-Button ---------------------------------------------------------------

local OPT = {}

function OPT:Init()
	self:SetText("")
	self:SetCursor("hand")
	self.Label = ""
	self.HoverFrac = 0
	self.SelectedFn = nil
end

function OPT:SetLabel(text) self.Label = tostring(text or "") end
function OPT:SetSelectedFunc(fn) self.SelectedFn = fn end

function OPT:IsActive()
	if not self.SelectedFn then return false end
	local ok, res = pcall(self.SelectedFn)
	return ok and res == true
end

function OPT:Paint(w, h)
	if SYMUI then -- Knopf wie im SSE-Schrank (SymChars)
		self._symSelected = self:IsActive()
		local tc = SYMUI.PaintButton(self, w, h, "select")
		local text = UI.FitText(self.Label, "Bodyman.Button", w - UI.PX(14))
		draw.SimpleText(text, "Bodyman.Button", w / 2, h / 2, self:IsEnabled() and tc or T().Dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return true
	end
	local th = T()
	local active = self:IsActive()
	local hovered = self:IsHovered() and self:IsEnabled()

	self.HoverFrac = Lerp(math.min(FrameTime() * 14, 1), self.HoverFrac, hovered and 1 or 0)

	local f = self.HoverFrac
	surface.SetDrawColor(
		Lerp(f, th.PanelSoft.r, th.PanelHover.r),
		Lerp(f, th.PanelSoft.g, th.PanelHover.g),
		Lerp(f, th.PanelSoft.b, th.PanelHover.b),
		th.PanelSoft.a
	)
	surface.DrawRect(0, 0, w, h)

	if active then
		surface.SetDrawColor(th.Yellow.r, th.Yellow.g, th.Yellow.b, 16)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(th.Yellow)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		surface.DrawRect(0, 0, math.max(3, UI.PX(3)), h)
	else
		surface.SetDrawColor(hovered and th.LineStrong or th.Line)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local col = active and th.Yellow or (self:IsEnabled() and (hovered and th.White or th.Text) or th.Dim)
	local text = UI.FitText(self.Label, "Bodyman.Button", w - UI.PX(14))
	draw.SimpleText(text, "Bodyman.Button", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	return true
end

vgui.Register("BodymanOption", OPT, "DButton")

-- Abschnitt mit Button-Raster ------------------------------------------------------

local SEC = {}

function SEC:Init()
	self.Title = ""
	self.Meta = ""
	self.Message = nil
	self.Buttons = {}
	self.BtnH = UI.PX(36)
	self.MinW = UI.PX(110)
	self.Pad = UI.PX(12)
	self.Head = UI.PX(36)
	if SYMUI then self.Head = UI.PX(52) self.Pad = UI.PX(2) end
	self.Gap = UI.PX(6)
end

function SEC:Setup(title, meta, btnH, minW)
	self.Title = string.upper(tostring(title or ""))
	self.Meta = string.upper(tostring(meta or ""))
	self.BtnH = btnH or self.BtnH
	self.MinW = minW or self.MinW
end

function SEC:SetMessage(text) self.Message = text end

function SEC:AddOption(label, onClick, isSelected, tooltip)
	local b = vgui.Create("BodymanOption", self)
	b:SetLabel(label)
	b:SetSelectedFunc(isSelected)
	if tooltip and tooltip ~= "" then b:SetTooltip(tooltip) end
	b.DoClick = function()
		UI.Click()
		if onClick then onClick() end
	end
	self.Buttons[#self.Buttons + 1] = b
	return b
end

function SEC:CalcHeight(w)
	if self.Message then return self.Head + UI.PX(40) end

	local inner = w - self.Pad * 2
	local cols = math.max(1, math.floor((inner + self.Gap) / (self.MinW + self.Gap)))
	cols = math.min(cols, math.max(1, #self.Buttons))
	local rows = math.ceil(#self.Buttons / cols)

	return self.Head + rows * self.BtnH + math.max(rows - 1, 0) * self.Gap + self.Pad, cols
end

function SEC:PerformLayout(w, h)
	local wanted, cols = self:CalcHeight(w)

	if cols then
		local inner = w - self.Pad * 2
		local bw = math.floor((inner - self.Gap * (cols - 1)) / cols)

		for i, b in ipairs(self.Buttons) do
			local col = (i - 1) % cols
			local row = math.floor((i - 1) / cols)
			b:SetPos(self.Pad + col * (bw + self.Gap), self.Head + row * (self.BtnH + self.Gap))
			b:SetSize(bw, self.BtnH)
		end
	end

	if h ~= wanted then self:SetTall(wanted) end
end

function SEC:Paint(w, h)
	local th = T()
	if SYMUI then -- Abschnitt wie im SSE-Schrank: großer Titel, Linie, keine Box
		surface.SetFont("Bodyman.Section")
		local tw, tth = surface.GetTextSize(self.Title)
		local ty = self.Head / 2 - UI.PX(4)
		draw.SimpleText(self.Title, "Bodyman.Section", 0, ty, th.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		SYMUI.Aurebesh(self.Title, "symchars.aure.small", w, ty - UI.PX(6), SYMUI.Alpha(th.Muted, 150), TEXT_ALIGN_RIGHT)
		if self.Meta ~= "" then draw.SimpleText(self.Meta, "Bodyman.Tiny", w, ty + UI.PX(10), th.Muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
		SYMUI.Box(0, self.Head - UI.PX(10), w, 1, th.LineStrong)
		SYMUI.Box(0, self.Head - UI.PX(11), math.min(w, tw), UI.PX(2), th.Yellow)
		if self.Message then
			draw.SimpleText(self.Message, "Bodyman.Body", 0, self.Head + UI.PX(4), th.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
		return
	end
	UI.DrawSection(0, 0, w, h)

	draw.SimpleText(self.Title, "Bodyman.Tiny", self.Pad, self.Head / 2, th.Yellow, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	if self.Meta ~= "" then
		draw.SimpleText(self.Meta, "Bodyman.Tiny", w - self.Pad, self.Head / 2, th.Muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	if self.Message then
		draw.SimpleText(self.Message, "Bodyman.Body", self.Pad, self.Head + UI.PX(10), th.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end

vgui.Register("BodymanSection", SEC, "Panel")

-- Fenster-Grundgerüst -------------------------------------------------------------

local FRAME = {}

function FRAME:Init()
	self.PageTitle = ""
	self.PageSub = ""
	self.FooterRight = ""
	self.Created = SysTime()

	self.CloseBtn = vgui.Create("DButton", self)
	self.CloseBtn:SetText("")
	self.CloseBtn.DoClick = function() UI.Click() self:Close() end
	self.CloseBtn.Paint = function(btn, w, h)
		local th = T()
		if SYMUI then
			SYMUI.Icon("close", 0, 0, w, btn:IsHovered() and th.Danger or th.Text)
			return true
		end
		local hov = btn:IsHovered()
		surface.SetDrawColor(hov and th.Danger or th.PanelSoft)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(hov and th.Danger or th.Line)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		local p = math.floor(w * 0.32)
		surface.SetDrawColor(hov and th.White or th.Text)
		for o = 0, 1 do
			surface.DrawLine(p + o, p, w - p + o, h - p)
			surface.DrawLine(w - p + o, p, p + o, h - p)
		end
		return true
	end

	self.Content = vgui.Create("Panel", self)

	self:SetAlpha(0)
	self:AlphaTo(255, 0.15, 0)
end

function FRAME:SetPage(title, sub)
	self.PageTitle = string.upper(tostring(title or ""))
	self.PageSub = string.upper(tostring(sub or ""))
end

function FRAME:SetFooterRight(text) self.FooterRight = string.upper(tostring(text or "")) end

function FRAME:Metrics()
	if SYMUI then return UI.PX(24), 0, UI.PX(100), UI.PX(34) end -- SSE-Schrank: nur großer Titel oben
	return UI.PX(24), UI.PX(66), UI.PX(66), UI.PX(34) -- pad, header, page, footer
end

function FRAME:PerformLayout(w, h)
	local pad, header, page, footer = self:Metrics()
	local cs = UI.PX(30)

	self.CloseBtn:SetSize(cs, cs)
	if SYMUI then
		self.CloseBtn:SetPos(w - pad - cs, UI.PX(22))
	else
		self.CloseBtn:SetPos(w - pad - cs, math.floor((header - cs) / 2) + UI.PX(2))
	end

	self.Content:SetPos(pad, header + page)
	self.Content:SetSize(w - pad * 2, h - header - page - footer - UI.PX(6))
end

function FRAME:Paint(w, h)
	local th = T()
	local pad, header, page, footer = self:Metrics()

	if SYMUI then -- Fenster wie der SSE-Schrank im SymChars-Design
		SYMUI.PaintWindow(w, h, nil, { header = 0, blur = self })
		local ty = UI.PX(16)
		draw.SimpleText(self.PageTitle, "Bodyman.Title", pad, ty, th.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		surface.SetFont("Bodyman.Title")
		local tw, tth = surface.GetTextSize(self.PageTitle)
		SYMUI.Aurebesh(self.PageTitle, "symchars.aure.small", pad + UI.PX(2), ty + tth - UI.PX(6), SYMUI.Alpha(th.Muted, 150))
		draw.SimpleText(self.PageSub, "Bodyman.Tiny", pad + tw + UI.PX(14), ty + tth - UI.PX(12), th.Yellow, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		SYMUI.Box(pad, page - UI.PX(14), w - pad * 2, 1, th.LineStrong)
		SYMUI.Box(pad, page - UI.PX(15), UI.PX(80), UI.PX(2), th.Yellow)
		local fy = h - footer
		draw.SimpleText(BODYMAN.FooterText or "", "Bodyman.Tiny", pad, fy + footer / 2, th.Muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(self.FooterRight, "Bodyman.Tiny", w - pad, fy + footer / 2, th.Yellow, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		return
	end

	Derma_DrawBackgroundBlur(self, self.Created)

	surface.SetDrawColor(th.Panel)
	surface.DrawRect(0, 0, w, h)
	UI.DrawScanlines(0, 0, w, h)

	surface.SetDrawColor(th.Line)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	-- Akzentlinie oben
	surface.SetDrawColor(th.Yellow)
	surface.DrawRect(0, 0, w, math.max(2, UI.PX(3)))

	-- Kopfzeile
	draw.SimpleText(string.upper(BODYMAN.ServerName), "Bodyman.Brand", pad, UI.PX(16), th.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(string.upper(BODYMAN.ServerSubtitle), "Bodyman.Tiny", pad, UI.PX(42), th.Yellow, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	if BODYMAN.HeaderRight and BODYMAN.HeaderRight ~= "" then
		draw.SimpleText(BODYMAN.HeaderRight, "Bodyman.Small", w - pad - UI.PX(44), header / 2 + UI.PX(2), th.Muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	surface.SetDrawColor(th.Line)
	surface.DrawRect(pad, header, w - pad * 2, 1)

	-- Seitentitel
	local ty = header + UI.PX(12)
	surface.SetDrawColor(th.Yellow)
	surface.DrawRect(pad, ty + UI.PX(2), math.max(2, UI.PX(3)), UI.PX(40))
	draw.SimpleText(self.PageTitle, "Bodyman.Title", pad + UI.PX(14), ty, th.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(self.PageSub, "Bodyman.Tiny", pad + UI.PX(14), ty + UI.PX(32), th.Muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	-- Fußzeile
	local fy = h - footer
	surface.SetDrawColor(255, 255, 255, 15)
	surface.DrawRect(pad, fy, w - pad * 2, 1)
	draw.SimpleText(BODYMAN.FooterText or "", "Bodyman.Tiny", pad, fy + footer / 2, Color(244, 246, 248, 56), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(self.FooterRight, "Bodyman.Tiny", w - pad, fy + footer / 2, th.Yellow, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	UI.DrawCorners(UI.PX(7), UI.PX(7), w - UI.PX(14), h - UI.PX(14), UI.PX(14), th.YellowSoft)
end

function FRAME:Think() end

function FRAME:Close()
	if self.Closing then return end
	self.Closing = true
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
	self:AlphaTo(0, 0.1, 0, function()
		if IsValid(self) then self:Remove() end
	end)
end

vgui.Register("BodymanFrame", FRAME, "EditablePanel")
UI.Frame = FRAME
