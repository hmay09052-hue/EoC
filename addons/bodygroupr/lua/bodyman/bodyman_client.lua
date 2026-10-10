-- Client: Aussehen-Menü und Admin-Menü.

local UI = BODYMAN.UI
local function L(key) return BODYMAN:L(key) end

function BODYMAN:Chat(msg)
	chat.AddText(self.Theme.Yellow, "[" .. self.ServerName .. "] ", self.Theme.Text, tostring(msg))
end

net.Receive("bodyman_chatprint", function() BODYMAN:Chat(net.ReadString()) end)
net.Receive("bodyman_openmenu", function() BODYMAN:OpenMenu() end)

-- 3D-Vorschau -----------------------------------------------------------------

local IDLE_SEQUENCES = { "idle_all_01", "idle_all_02", "pose_standing_01", "idle_subtle", "idle" }

local PREVIEW = {}

function PREVIEW:Init()
	self.Yaw = 20
	self.Zoom = 1
	self.PanX = 0
	self.PanZ = 0

	self:SetFOV(30)
	self:SetAnimated(true)
	self:SetAmbientLight(Color(40, 44, 52))
	self:SetDirectionalLight(BOX_TOP, Color(245, 180, 70))
	self:SetDirectionalLight(BOX_FRONT, Color(165, 170, 180))
	self:SetDirectionalLight(BOX_RIGHT, Color(70, 75, 85))
	self:SetDirectionalLight(BOX_LEFT, Color(40, 44, 52))
end

function PREVIEW:SetPreviewModel(path)
	if not isstring(path) or path == "" then return end
	if self.ModelPath == string.lower(path) and IsValid(self.Entity) then return end

	self:SetModel(path)
	self.ModelPath = string.lower(path)

	local ent = self.Entity
	if not IsValid(ent) then return end

	for _, seq in ipairs(IDLE_SEQUENCES) do
		local id = ent:LookupSequence(seq)
		if id and id > 0 then
			ent:ResetSequence(id)
			break
		end
	end

	function ent:GetPlayerColor()
		local ply = LocalPlayer()
		return IsValid(ply) and ply:GetPlayerColor() or Vector(1, 1, 1)
	end
end

function PREVIEW:OnMousePressed(code)
	if code ~= MOUSE_LEFT and code ~= MOUSE_RIGHT then return end
	self.Drag = code
	self.LastX, self.LastY = input.GetCursorPos()
	self:MouseCapture(true)
	self:SetCursor("sizeall")
end

function PREVIEW:StopDrag()
	self.Drag = nil
	self:MouseCapture(false)
	self:SetCursor("arrow")
end

function PREVIEW:OnMouseReleased(code)
	if self.Drag == code then self:StopDrag() end
end

function PREVIEW:OnMouseWheeled(delta)
	self.Zoom = math.Clamp(self.Zoom - delta * 0.08, 0.3, 1.25)
	return true
end

function PREVIEW:Think()
	if not self.Drag then return end

	if not input.IsMouseDown(self.Drag) then
		self:StopDrag()
		return
	end

	local x, y = input.GetCursorPos()
	local dx, dy = x - self.LastX, y - self.LastY
	self.LastX, self.LastY = x, y

	if self.Drag == MOUSE_LEFT then
		self.Yaw = self.Yaw + dx * 0.5
		self.Zoom = math.Clamp(self.Zoom - dy * 0.004, 0.3, 1.25)
	else
		self.PanX = math.Clamp(self.PanX - dx * 0.08, -24, 24)
		self.PanZ = math.Clamp(self.PanZ + dy * 0.08, -30, 30)
	end
end

function PREVIEW:LayoutEntity(ent)
	if self.bAnimated then self:RunAnimation() end

	ent:SetAngles(Angle(0, self.Yaw, 0))

	local mn, mx = ent:GetModelBounds()
	local height = math.Clamp((mx and mx.z or 72) - (mn and mn.z or 0), 24, 200)

	-- Beim Reinzoomen langsam Richtung Kopf schauen
	local headFrac = math.Clamp(BODYMAN.InverseLerp(self.Zoom, 0.9, 0.3), 0, 1)
	local target = Vector(0, self.PanX, Lerp(headFrac, height * 0.52, height * 0.88) + self.PanZ)
	local camPos = target + Vector(height * 2.4 * self.Zoom, 0, height * 0.04)

	self:SetLookAt(target)
	self:SetCamPos(camPos)
	ent:SetEyeTarget(camPos)
end

vgui.Register("BodymanPreview", PREVIEW, "DModelPanel")

-- Aussehen-Menü ---------------------------------------------------------------

local gradient = Material("vgui/gradient-u")
local MENU = {}

function MENU:Init()
	local w = math.min(ScrW() - 40, math.max(ScrW() * 0.74, 900), 1500)
	local h = math.min(ScrH() - 40, math.max(ScrH() * 0.84, 560), 960)
	self:SetSize(w, h)
	self:Center()
	self:MakePopup()
	self:SetPage(L("Title"), L("Subtitle"))

	self.Stage = vgui.Create("Panel", self.Content)
	self.Stage.Paint = function(_, pw, ph) self:PaintStage(pw, ph) end

	self.Preview = vgui.Create("BodymanPreview", self.Stage)
	self.Preview:Dock(FILL)
	self.Preview:DockMargin(UI.PX(10), UI.PX(36), UI.PX(10), UI.PX(40))

	self.List = vgui.Create("DScrollPanel", self.Content)
	UI.StyleScrollbar(self.List)

	if SYMUI then self:BuildClosetExtras() end

	self.Content.PerformLayout = function(_, cw, ch)
		local gap = UI.PX(14)
		local sw = math.floor(cw * (SYMUI and 0.48 or 0.55))
		if SYMUI then gap = cw - sw * 2 end -- wie der SSE-Schrank: zwei gleich breite Hälften
		self.Stage:SetPos(0, 0)
		self.Stage:SetSize(sw, ch)
		self.List:SetPos(sw + gap, 0)
		self.List:SetSize(cw - sw - gap, ch)
	end

	self:Rebuild()
end

-- Wie der SSE-Schrank: "Speichern" / "Laden" über der Vorschau, Trennlinie vor der Liste
local function SaveKey()
	local ply = LocalPlayer()
	return "Bodyman-Closet-" .. string.lower(IsValid(ply) and ply:GetModel() or "")
end

local function MakeClosetButton(parent, label, fn)
	local b = vgui.Create("DButton", parent)
	b:SetText("")
	b:Dock(RIGHT)
	b:DockMargin(UI.PX(8), 0, 0, 0)
	surface.SetFont("Bodyman.Button")
	b:SetWide(surface.GetTextSize(string.upper(label)) + UI.PX(36))
	b.Paint = function(s, w, h)
		local tc = SYMUI.PaintButton(s, w, h, "primary")
		draw.SimpleText(string.upper(label), "Bodyman.Button", w / 2, h / 2, tc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return true
	end
	b.DoClick = function() UI.Click() fn() end
	return b
end

function MENU:BuildClosetExtras()
	self.Preview:DockMargin(0, UI.PX(8), 0, UI.PX(28))

	local bar = vgui.Create("Panel", self.Stage)
	bar:Dock(TOP)
	bar:SetTall(UI.PX(38))
	bar:SetZPos(-1)

	local de = BODYMAN.Language == "de"

	self.LoadBtn = MakeClosetButton(bar, de and "Laden" or "Load", function() self:LoadSavedState() end)
	self.SaveBtn = MakeClosetButton(bar, de and "Speichern" or "Save", function() self:SaveCurrentState() end)
	self.LoadBtn:SetVisible(cookie.GetString(SaveKey(), "") ~= "")

	-- senkrechte Linie links neben der Liste (wie im SSE-Schrank)
	self.List.Paint = function(_, w, h)
		surface.SetDrawColor(BODYMAN.Theme.LineStrong)
		surface.DrawRect(0, 0, 1, h)
	end
	self.List:GetCanvas():DockPadding(UI.PX(12), UI.PX(4), 0, UI.PX(4))
end

function MENU:SaveCurrentState()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	local data = { skin = ply:GetSkin(), bodygroups = {} }
	for _, bg in ipairs(ply:GetBodyGroups() or {}) do
		data.bodygroups[#data.bodygroups + 1] = { bg.id, ply:GetBodygroup(bg.id) }
	end
	cookie.Set(SaveKey(), util.TableToJSON(data))
	if IsValid(self.LoadBtn) then self.LoadBtn:SetVisible(true) self.LoadBtn:GetParent():InvalidateLayout() end
	BODYMAN:Chat(BODYMAN.Language == "de" and "Aussehen gespeichert." or "Appearance saved.")
end

function MENU:LoadSavedState()
	local data = util.JSONToTable(cookie.GetString(SaveKey(), "") or "")
	if not istable(data) then return end

	local ent = self.Preview.Entity
	local queue = {}
	if isnumber(data.skin) then
		if IsValid(ent) then ent:SetSkin(data.skin) end
		queue[#queue + 1] = function()
			net.Start("bodyman_skin_change")
			net.WriteUInt(data.skin, 8)
			net.SendToServer()
		end
	end
	for _, pair in ipairs(data.bodygroups or {}) do
		local id, v = tonumber(pair[1]), tonumber(pair[2])
		if id and v then
			if IsValid(ent) then ent:SetBodygroup(id, v) end
			queue[#queue + 1] = function()
				net.Start("bodyman_bodygroup_change")
				net.WriteUInt(id, 8)
				net.WriteUInt(v, 8)
				net.SendToServer()
			end
		end
	end

	-- der Server lässt nur alle 0,06 s (Bodygroup) bzw. 0,1 s (Skin) eine Änderung zu -> nacheinander senden
	self:MarkInteraction(#queue * 0.12 + 1)
	for i, fn in ipairs(queue) do
		timer.Simple((i - 1) * 0.12, fn)
	end
end

function MENU:PaintStage(w, h)
	local th = BODYMAN.Theme

	if SYMUI then -- SSE-Schrank: Modell frei im Fenster, nur Hilfetext unten
		local help = UI.FitText(L("Help"), "Bodyman.Small", w - UI.PX(32))
		draw.SimpleText(help, "Bodyman.Small", w / 2, h - UI.PX(14), th.Muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return
	end

	UI.DrawSection(0, 0, w, h)

	surface.SetMaterial(gradient)
	surface.SetDrawColor(th.Yellow.r, th.Yellow.g, th.Yellow.b, 14)
	surface.DrawTexturedRect(0, h * 0.45, w, h * 0.55)

	UI.DrawCorners(UI.PX(6), UI.PX(6), w - UI.PX(12), h - UI.PX(12), UI.PX(12), th.YellowSoft)

	draw.SimpleText(string.upper(L("Preview")), "Bodyman.Tiny", UI.PX(16), UI.PX(20), th.Yellow, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(string.upper(self.JobName or ""), "Bodyman.Tiny", w - UI.PX(16), UI.PX(20), th.Muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	local help = UI.FitText(L("Help"), "Bodyman.Small", w - UI.PX(32))
	draw.SimpleText(help, "Bodyman.Small", w / 2, h - UI.PX(20), th.Muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Vorschau kurz nicht mit dem Server abgleichen, damit Klicks nicht "zurückspringen"
function MENU:MarkInteraction(duration)
	self.HoldSyncUntil = RealTime() + (duration or 0.6)
end

-- Vorschau an den echten Zustand des Spielers angleichen
function MENU:SyncPreview(force)
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if not force and RealTime() < (self.HoldSyncUntil or 0) then return end

	local prev = self.Preview
	if prev.ModelPath ~= string.lower(ply:GetModel() or "") then
		prev:SetPreviewModel(ply:GetModel())
	end

	local ent = prev.Entity
	if not IsValid(ent) then return end

	if ent:GetSkin() ~= ply:GetSkin() then ent:SetSkin(ply:GetSkin()) end

	for _, bg in ipairs(ply:GetBodyGroups() or {}) do
		local v = ply:GetBodygroup(bg.id)
		if ent:GetBodygroup(bg.id) ~= v then ent:SetBodygroup(bg.id, v) end
	end
end

function MENU:Rebuild()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	self.Team = ply:Team()
	self.Model = string.lower(ply:GetModel() or "")
	self.JobName = team.GetName(self.Team) or ""
	self:SetFooterRight(L("Unit") .. ": " .. self.JobName)

	self.Preview:SetPreviewModel(ply:GetModel())
	self:SyncPreview(true)
	if IsValid(self.LoadBtn) then self.LoadBtn:SetVisible(cookie.GetString(SaveKey(), "") ~= "") end

	local scroll = self.List:GetVBar():GetScroll()
	self.List:Clear()
	self:InvalidateLayout(true)
	self.Content:InvalidateLayout(true)

	local width = self.List:GetWide() - UI.PX(10)
	local job = BODYMAN:GetJob(ply)
	local any = false

	local function Section(title, meta, btnH, minW)
		local sec = self.List:Add("BodymanSection")
		sec:Setup(title, meta, btnH, minW)
		sec:Dock(TOP)
		sec:DockMargin(0, 0, UI.PX(10), UI.PX(10))
		return sec
	end

	local function Finish(sec)
		sec:SetTall((sec:CalcHeight(width)))
	end

	-- Modelle
	local models = BODYMAN:GetJobModels(ply)
	if #models > 1 then
		any = true
		local sec = Section(L("Models"), #models .. " " .. L("Options"), UI.PX(40), UI.PX(150))

		for i, path in ipairs(models) do
			local lower = string.lower(path)
			sec:AddOption(UI.Pretty(string.GetFileFromFilename(path)), function()
				self:MarkInteraction(1.5)
				self.Preview:SetPreviewModel(path)
				net.Start("bodyman_model_change")
				net.WriteUInt(i, 8)
				net.SendToServer()
			end, function()
				return self.Preview.ModelPath == lower
			end, path)
		end
		Finish(sec)
	end

	-- Skins
	local skins = BODYMAN:GetAllowedSkins(ply, job)
	if #skins > 1 then
		any = true
		local sec = Section(L("Skins"), #skins .. " " .. L("Options"), UI.PX(36), UI.PX(64))

		for _, s in ipairs(skins) do
			sec:AddOption(tostring(s), function()
				self:MarkInteraction()
				local ent = self.Preview.Entity
				if IsValid(ent) then ent:SetSkin(s) end
				net.Start("bodyman_skin_change")
				net.WriteUInt(s, 8)
				net.SendToServer()
			end, function()
				local ent = self.Preview.Entity
				return IsValid(ent) and ent:GetSkin() == s
			end)
		end
		Finish(sec)
	end

	-- Bodygroups
	for _, g in ipairs(BODYMAN:GetAllowedBodygroups(ply, job, false)) do
		any = true
		local sec = Section(UI.Pretty(g.name), #g.options .. " " .. L("Options"), UI.PX(36), UI.PX(118))

		for _, v in ipairs(g.options) do
			local raw = g.submodels[v]
			local label
			if not isstring(raw) or raw == "" or string.lower(raw) == "blank" then
				label = L("None")
			else
				label = UI.Pretty(raw)
			end

			sec:AddOption(label, function()
				self:MarkInteraction()
				local ent = self.Preview.Entity
				if IsValid(ent) then ent:SetBodygroup(g.id, v) end
				net.Start("bodyman_bodygroup_change")
				net.WriteUInt(g.id, 8)
				net.WriteUInt(v, 8)
				net.SendToServer()
			end, function()
				local ent = self.Preview.Entity
				return IsValid(ent) and ent:GetBodygroup(g.id) == v
			end, "#" .. v .. (isstring(raw) and raw ~= "" and ("  " .. raw) or ""))
		end
		Finish(sec)
	end

	if not any then
		local sec = Section(L("Title"), "")
		sec:SetMessage(L("NothingToChange"))
		Finish(sec)
	end

	timer.Simple(0, function()
		if IsValid(self) and IsValid(self.List) then self.List:GetVBar():SetScroll(scroll) end
	end)
end

function MENU:Think()
	UI.Frame.Think(self)
	if self.Closing then return end

	local now = RealTime()
	if now < (self.NextCheck or 0) then return end
	self.NextCheck = now + 0.25

	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() or not BODYMAN:CanUseMenu(ply) then
		self:Close()
		return
	end

	-- Job oder Modell hat sich geändert -> Liste neu aufbauen
	if ply:Team() ~= self.Team or string.lower(ply:GetModel() or "") ~= self.Model then
		self:Rebuild()
		return
	end

	self:SyncPreview(false)
end

function MENU:OnRemove()
	if BODYMAN.Menu == self then BODYMAN.Menu = nil end
end

vgui.Register("BodymanMenu", MENU, "BodymanFrame")

function BODYMAN:OpenMenu()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	if not self:CanUseMenu(ply) then
		self:Chat(self:L("NeedCloset"))
		return
	end

	if IsValid(self.Menu) then self.Menu:Remove() end
	self.Menu = vgui.Create("BodymanMenu")
end

-- Alter Name, falls noch irgendwo benutzt
function BODYMAN:RefreshAppearanceMenu()
	if IsValid(self.Menu) then self.Menu:Rebuild() end
end

-- Admin-Menü ------------------------------------------------------------------

local ADMIN_COMMANDS = {
	{ "AdminSpawn", "bodyman_spawncloset" },
	{ "AdminSave", "bodyman_saveclosets" },
	{ "AdminLoad", "bodyman_loadclosets" },
	{ "AdminRemove", "bodyman_removeclosets" },
}

function BODYMAN:OpenAdminMenu()
	if not self:IsAdmin(LocalPlayer()) then
		self:Chat(self:L("NoPermission"))
		return
	end

	if IsValid(self.AdminPanel) then self.AdminPanel:Remove() end

	local f = vgui.Create("BodymanFrame")
	f:SetPage(L("AdminTitle"), L("AdminSubtitle"))
	f:SetFooterRight(game.GetMap())
	self.AdminPanel = f

	local sec = vgui.Create("BodymanSection", f.Content)
	sec:Setup(L("ClosetName"), "", UI.PX(40), 100000) -- ein Button pro Zeile
	sec:Dock(TOP)

	function sec:Think()
		if RealTime() < (self.NextCount or 0) then return end
		self.NextCount = RealTime() + 0.5
		self.Meta = string.upper(L("OnMap") .. ": " .. #ents.FindByClass("bodyman_closet"))
	end

	for _, entry in ipairs(ADMIN_COMMANDS) do
		local cmd = entry[2]
		sec:AddOption(L(entry[1]), function() RunConsoleCommand(cmd) end)
	end

	local fw = math.min(UI.PX(560), ScrW() - 40)
	local secH = sec:CalcHeight(fw - UI.PX(48))
	sec:SetTall(secH)

	f:SetSize(fw, UI.PX(66 + 66 + 34 + 6) + secH + UI.PX(4))
	f:Center()
	f:MakePopup()
end

function BODYMAN:AdminMenu() self:OpenAdminMenu() end

-- Befehle & Kontextmenü -------------------------------------------------------------

concommand.Add("bodyman_openmenu", function() BODYMAN:OpenMenu() end)
concommand.Add("bodyman_adminmenu", function() BODYMAN:OpenAdminMenu() end)

list.Set("DesktopWindows", "BodyManEditor", {
	icon = "icon16/user_gray.png",
	title = L("ContextTitle"),
	width = 100,
	height = 100,
	onewindow = true,
	init = function(icon, window)
		window:Close()
		RunConsoleCommand("bodyman_openmenu")
	end
})

list.Set("DesktopWindows", "BodyManAdmin", {
	icon = "icon16/shield.png",
	title = L("ContextAdmin"),
	width = 100,
	height = 100,
	onewindow = true,
	init = function(icon, window)
		window:Close()
		RunConsoleCommand("bodyman_adminmenu")
	end
})
