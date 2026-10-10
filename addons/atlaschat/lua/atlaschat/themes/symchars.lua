---------------------------------------------------------
-- SymChars-Design für den Chat: dunkle abgeschrägte Platte, Akzentkante,
-- Überschrift mit Aurebesh, Schriften des Charaktermenüs.
-- Ohne SymChars (SYMUI fehlt) sieht das Theme aus wie "Dark".
---------------------------------------------------------

theme.base = "default"
theme.unique = "symchars"
theme.name = "SymChars"

local SY = SYMUI

local function Accent(a)
	if SY then return SY.Accent(a) end
	return Color(252, 178, 73, a or 255)
end

theme.color = {}
theme.color.selection = Color(252, 178, 73, 70)
theme.color.timestamp = Color(168, 174, 180)
theme.color.privatecard_close = Color(168, 174, 180)
theme.color.privatecard_close_hover = Color(205, 62, 56)
theme.color.generic_label = Color(236, 233, 224)
theme.messageSpacing = 2

theme.color.generic_background = Color(11, 14, 18, 235)
theme.color.generic_background_dark = Color(18, 22, 28, 240)
theme.color.button = Color(18, 22, 28, 235)
theme.color.button_hovered = Color(27, 32, 40, 245)
theme.color.top = Color(18, 22, 28, 250)
theme.color.background = Color(9, 11, 14, 225)
theme.color.list_background = Color(4, 6, 8, 150)
theme.color.prefix_background = Color(4, 6, 8, 220)
theme.color.entry_background = Color(4, 6, 8, 220)
theme.color.scrollbar_background = Color(255, 255, 255, 22)
theme.color.scrollbar_grip = Color(252, 178, 73, 150)
theme.color.scrollbar_grip_hovered = Color(252, 178, 73)
theme.color.scrollbar_buttonup = Color(0, 0, 0, 0)
theme.color.scrollbar_buttonup_hovered = Color(0, 0, 0, 0)
theme.color.scrollbar_buttondown = Color(0, 0, 0, 0)
theme.color.scrollbar_buttondown_hovered = Color(0, 0, 0, 0)
theme.color.list_container_new = Color(252, 178, 73, 90)
theme.color.list_container_hover = Color(255, 255, 255, 14)
theme.color.list_container_selected = Color(252, 178, 73, 40)
theme.color.list_container_background = Color(18, 22, 28, 240)
theme.color.list_container_background_dark = Color(11, 14, 18, 240)
theme.color.icon_hold_background = Color(18, 22, 28, 240)

local function Fonts()
	local head = SY and SY.FontFace("head") or "Bebas Neue"
	local body = SY and SY.FontFace("body") or "Roboto Condensed"
	surface.CreateFont("atlaschat.theme.default.title", {font = head, size = 22, weight = 400, extended = true})
	surface.CreateFont("atlaschat.theme.prefix", 		{font = body, size = 17, weight = 700, extended = true})
	surface.CreateFont("atlaschat.theme.list.name", 	{font = body, size = 15, weight = 600, extended = true})
	surface.CreateFont("atlaschat.theme.userlist", 		{font = head, size = 20, weight = 400, extended = true})
	surface.CreateFont("atlaschat.theme.userlist.player", {font = body, size = 16, weight = 700, extended = true})
	surface.CreateFont("atlaschat.theme.row",			{font = body, size = 18, weight = 700, extended = true})
end

-- Akzentfarbe aus den SymChars-Einstellungen übernehmen
local function SyncColors(self)
	local a = Accent()
	self.color.selection = Color(a.r, a.g, a.b, 70)
	self.color.scrollbar_grip = Color(a.r, a.g, a.b, 150)
	self.color.scrollbar_grip_hovered = Color(a.r, a.g, a.b)
	self.color.list_container_new = Color(a.r, a.g, a.b, 90)
	self.color.list_container_selected = Color(a.r, a.g, a.b, 40)
end

function theme:OnThemeChange()
	Fonts()
	SyncColors(self)

	if (ValidPanel(self.panel.hostName)) then
		self.panel.hostName:SetFont("atlaschat.theme.default.title")
		self.panel.hostName:SetTextColor(self.color.generic_label)
	end

	self.panel:DockPadding(8, 41, 8, 8)
	self.panel:InvalidateLayout()
end

function theme:PaintGenericBackground(panel, w, h, text, x, y, xAlign, yAlign)
	local col = panel.dark and self.color.generic_background_dark or self.color.generic_background
	if (SY) then
		SY.Cut(0, 0, w, h, col, math.min(SY.S(8), math.floor(h / 4)), "tlbr")
		SY.CutOutline(0, 0, w, h, SY.col.line2, math.min(SY.S(8), math.floor(h / 4)), "tlbr")
	else
		draw.SimpleRect(0, 0, w, h, col)
	end

	if (text) then
		draw.SimpleText(string.upper(text), "atlaschat.theme.default.title", x or 6, y or 8, self.color.generic_label, xAlign or TEXT_ALIGN_LEFT, yAlign or TEXT_ALIGN_BOTTOM)
	end
end

function theme:PaintButton(button, w, h)
	local color = button:GetTextColor()
	if (SY) then
		color = SY.PaintButton(button, w, h, "default")
	else
		draw.SimpleRect(0, 0, w, h, button.Hovered and self.color.button_hovered or self.color.button)
	end

	draw.SimpleText(button:GetText(), button:GetFont(), w /2, h /2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function theme:PaintPanel(w, h)
	if (SY) then
		local c = SY.S(12)
		SY.Cut(0, 0, w, h, self.color.background, c, "tlbr")
		SY.Box(c, 0, w - c, 33, self.color.top)
		SY.Cut(0, 0, c + 1, 33, self.color.top, c, "tl")
		SY.Box(0, 33, w, 1, Accent(70))
		SY.Box(0, 32, SY.S(80), 2, Accent())
		SY.CutOutline(0, 0, w, h, Accent(110), c, "tlbr")
		SY.Aurebesh(GetHostName(), "symchars.aure.small", w - 10, 16, SY.Alpha(SY.col.dim, 110), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, w * 0.4)
	else
		draw.SimpleRect(0, 0, w, h, self.color.background)
	end

	local hostName = GetHostName():upper()

	if (ValidPanel(self.panel.hostName) and self.panel.hostName:GetText() != hostName) then
		self.panel.hostName:SetText(hostName)
		self.panel.hostName:SizeToContents()
	end

	self:PaintSnowFlakes(w, h)
end

function theme:PaintList(panel, w, h)
	if (ValidPanel(panel) and panel:IsVisible()) then
		draw.SimpleRect(0, 0, w, h, self.color.list_background)
		if (SY) then SY.Outline(0, 0, w, h, SY.col.line) end
	end
end

function theme:PaintPrefix(w, h)
	draw.SimpleRect(0, 0, w, h, self.color.prefix_background)
	if (SY) then SY.Outline(0, 0, w, h, SY.col.line2) end

	local prefix = self.panel.prefix:GetPrefix()

	if (prefix) then
		draw.SimpleText(string.upper(prefix), "atlaschat.theme.prefix", w /2, h /2, Accent(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function theme:PaintTextEntry(w, h, entry)
	entry = entry or self.panel.entry

	draw.SimpleRect(0, 0, w, h, self.color.entry_background)
	if (SY) then SY.Outline(0, 0, w, h, entry:HasFocus() and Accent() or SY.col.line2) end

	entry:DrawTextEntryText(self.color.generic_label, Accent(90), Accent())
end

function theme:PaintScrollbar(panel, w, h)
	if (self.panel:IsVisible()) then
		draw.SimpleRect(math.floor(w /2) -1, 0, 2, h, self.color.scrollbar_background)
	end
end

function theme:PaintScrollbarGrip(panel, w, h)
	if (self.panel:IsVisible()) then
		draw.SimpleRect(math.floor(w /4), 0, math.ceil(w /2), h, panel.Hovered and self.color.scrollbar_grip_hovered or self.color.scrollbar_grip)
	end
end

function theme:PaintScrollbarUpButton(panel, w, h)
	if (SY and self.panel:IsVisible()) then SY.Icon("arrow_up", 0, 0, math.min(w, h), panel.Hovered and SY.col.text or SY.col.muted) end
end

function theme:PaintScrollbarDownButton(panel, w, h)
	if (SY and self.panel:IsVisible()) then SY.Icon("arrow_down", 0, 0, math.min(w, h), panel.Hovered and SY.col.text or SY.col.muted) end
end

function theme:PaintChatroom(panel, w, h)
	draw.SimpleRect(0, 0, w, h, self.color.list_container_background)

	local active = atlaschat.theme.GetValue("current_chatroom")

	if (panel == active) then
		draw.SimpleRect(0, 0, w, h, self.color.list_container_selected)
		draw.SimpleRect(0, h -2, w, 2, Accent())
	end

	if (panel.Hovered) then
		draw.SimpleRect(0, 0, w, h, self.color.list_container_hover)
	end

	if (panel.new and panel.blink <= CurTime()) then
		draw.SimpleRect(0, 0, w, h, self.color.list_container_new)

		if (panel.blink +1 <= CurTime()) then
			panel.blink = CurTime() +1.5
		end
	end

	local name = panel:GetName()

	if (name) then
		draw.SimpleText(name, "atlaschat.theme.list.name", w /2, h /2, self.color.generic_label, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		draw.SimpleText("(" .. #panel.players .. ")", "atlaschat.theme.list.name", w -4, h /2, self.color.generic_label, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
end

function theme:PaintIconHolder(panel, w, h)
end
