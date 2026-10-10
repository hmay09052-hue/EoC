--[[-------------------------------------------------------------------------------------------------------------
                         bKeypads - Battlefront Theme (Keypad-Bildschirm + Keycards)
          Design wie Symchars 2 (Battlefront-Menue), aber komplett eigenstaendig (braucht Symchars nicht).
          Schriften kommen aus dem Serverpaket: BigNoodleTitling, Roboto Condensed, Aurebesh
-------------------------------------------------------------------------------------------------------------]]

bKeypads.SymTheme = bKeypads.SymTheme or {}

local T = bKeypads.SymTheme
local Color = Color
local math = math
local surface = surface
local draw = draw
local string = string

--## Texte (hier anpassen) ##--

T.Strings = {
	TitlePIN      = "PIN-EINGABE",
	TitleKeycard  = "KEYCARD",
	TitleFaceID   = "GESICHTSSCAN",

	EnterPIN      = "CODE EINGEBEN",
	Keycard       = "KEYCARD SCANNEN",
	KeycardHint   = "Keycard in die Hand nehmen",
	FaceID        = "SCAN STARTEN",
	Scanning      = "SCANNE",
	Loading       = "INITIALISIERE",
	Broken        = "SYSTEMFEHLER",
	Hacked        = "UEBERBRUECKT",
	Granted       = "ZUGANG GEWAEHRT",
	Denied        = "ZUGANG VERWEIGERT",

	-- Hinweis, wenn jemand mit E auf ein Keycard-Keypad drueckt, ohne die Karte in der Hand zu haben
	HoldKeycard   = "Nimm deine Keycard in die Hand und klicke mit Linksklick auf das Keypad.",

	Level         = "STUFE"
}

--## Farben (wie Symchars 2) ##--

T.fonts = {
	head = "BigNoodleTitling",
	body = "Roboto Condensed",
	aure = "Aurebesh"
}

-- Akzentfarbe (Bernstein wie im Menue)
T.AccentColor = Color(252, 178, 73)

T.col = {
	bg     = Color(11, 14, 18),
	panel  = Color(18, 22, 28),
	panel2 = Color(27, 32, 40),
	foot   = Color(8, 10, 13),
	line   = Color(255, 255, 255, 22),
	line2  = Color(255, 255, 255, 50),
	line3  = Color(255, 255, 255, 95),
	text   = Color(236, 233, 224),
	dim    = Color(168, 174, 180),
	muted  = Color(112, 119, 127),
	cream  = Color(231, 225, 213),
	ink    = Color(18, 21, 25),
	steel  = Color(43, 101, 133),
	red    = Color(205, 62, 56),
	green  = Color(95, 200, 120),
	yellow = Color(240, 200, 80)
}

-- Bildschirm-Hintergruende je Zustand
T.ScreenColors = {
	Idle     = Color(11, 14, 18),
	Scanning = Color(14, 18, 23),
	Granted  = Color(12, 22, 16),
	Denied   = Color(24, 12, 12),
	Hacked   = Color(24, 12, 12)
}

-- Alle Keycards haben dieselbe Farbe
T.KeycardColor = Color(231, 225, 213)

function T.Accent(alpha)
	local c = T.AccentColor
	if alpha then return Color(c.r, c.g, c.b, alpha) end
	return c
end

function T.Color(name, alpha)
	local c = T.col[name] or T.col.text
	if alpha then return Color(c.r, c.g, c.b, alpha) end
	return c
end

function T.Alpha(c, a)
	return Color(c.r, c.g, c.b, a)
end

-- Eigene Keypad-Hintergrundfarbe nur ganz leicht einmischen
function T.ScreenTint(c)
	local base = T.ScreenColors.Idle
	return Color(Lerp(0.12, base.r, c.r), Lerp(0.12, base.g, c.g), Lerp(0.12, base.b, c.b))
end

function T.LCDColor()
	local c = T.AccentColor
	return Color(c.r * 0.35, c.g * 0.35, c.b * 0.35)
end

--## Schriften ##--

local function Font(name, font, size, weight)
	surface.CreateFont(name, { font = font, size = size, weight = weight or 500, antialias = true, extended = true })
end

-- Ueberschriften werden automatisch kleiner, wenn der Text nicht passt
T.HeadSizes = { 44, 38, 32, 28, 24 }
T.StatusSizes = { 30, 26, 22, 19 }

function T.CreateFonts()
	local f = T.fonts
	for _, s in ipairs(T.HeadSizes) do Font("bKeypads.BF.Head." .. s, f.head, s) end
	for _, s in ipairs(T.StatusSizes) do Font("bKeypads.BF.Status." .. s, f.head, s) end

	Font("bKeypads.BF.Aure", f.aure, 18)
	Font("bKeypads.BF.Aure.Small", f.aure, 14)
	Font("bKeypads.BF.Body", f.body, 24, 500)
	Font("bKeypads.BF.PIN", f.head, 46)

	-- Keycard-Textur
	Font("bKeypads.BF.Card.Name.46", f.head, 46)
	Font("bKeypads.BF.Card.Name.38", f.head, 38)
	Font("bKeypads.BF.Card.Name.30", f.head, 30)
	Font("bKeypads.BF.Card.Aure", f.aure, 18)
	Font("bKeypads.BF.Card.Sub", f.body, 25, 700)
	Font("bKeypads.BF.Card.Chip", f.head, 30)
	Font("bKeypads.BF.Card.Level", f.head, 26)
end
T.CreateFonts()

--## Text ##--

-- Aurebesh kennt keine Umlaute/Sonderzeichen
function T.ToAurebesh(text)
	text = string.upper(tostring(text or ""))
	text = text:gsub("Ä", "AE"):gsub("Ö", "OE"):gsub("Ü", "UE"):gsub("ß", "SS")
	text = text:gsub("[^A-Z0-9 %-]", " "):gsub("%s+", " ")
	return string.Trim(text)
end

function T.Trim(text, font, maxW)
	text = tostring(text or "")
	surface.SetFont(font)
	if surface.GetTextSize(text) <= maxW then return text end
	while #text > 0 and surface.GetTextSize(text .. "...") > maxW do
		text = string.sub(text, 1, #text - 1)
	end
	return text .. "..."
end

-- groesste Schrift aus der Liste, in die der Text passt
function T.FitFont(text, prefix, sizes, maxW)
	for _, s in ipairs(sizes) do
		local font = prefix .. s
		surface.SetFont(font)
		if surface.GetTextSize(text) <= maxW then return font end
	end
	return prefix .. sizes[#sizes]
end

-- Ueberschrift + Aurebesh-Zeile darunter (wie im Battlefront-Menue). aureSize = Hoehe der Aurebesh-Zeile
function T.Heading(text, prefix, sizes, x, y, maxW, col, aureSize, ax)
	text = string.upper(tostring(text or ""))
	local font = T.FitFont(text, prefix, sizes, maxW)
	text = T.Trim(text, font, maxW)
	surface.SetFont(font)
	local _, th = surface.GetTextSize(text)
	draw.SimpleText(text, font, x, y, col or T.Color("text"), ax or TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	-- BigNoodle hat viel Leerraum unter den Buchstaben, daher etwas hoeher ansetzen
	local ay = y + th * 0.86
	local ah = T.DrawAurebesh(text, aureSize, x, ay, T.Alpha(col or T.Color("text"), 130), ax or TEXT_ALIGN_LEFT, maxW)
	return (ay - y) + ah
end

--## Formen ##--

function T.Box(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, w, h)
end

function T.Outline(x, y, w, h, col, thick)
	thick = thick or 1
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, w, thick)
	surface.DrawRect(x, y + h - thick, w, thick)
	surface.DrawRect(x, y + thick, thick, h - thick * 2)
	surface.DrawRect(x + w - thick, y + thick, thick, h - thick * 2)
end

-- Dreieck, um eine Ecke "abzuschraegen" (in Hintergrundfarbe uebermalen)
function T.CornerCut(x, y, size, corner, col)
	draw.NoTexture()
	surface.SetDrawColor(col)
	local p
	if corner == "tr" then
		p = { { x = x - size, y = y }, { x = x, y = y }, { x = x, y = y + size } }
	elseif corner == "bl" then
		p = { { x = x, y = y - size }, { x = x + size, y = y }, { x = x, y = y } }
	elseif corner == "br" then
		p = { { x = x, y = y - size }, { x = x, y = y }, { x = x - size, y = y } }
	else
		p = { { x = x, y = y }, { x = x + size, y = y }, { x = x, y = y + size } }
	end
	surface.DrawPoly(p)
end

function T.Circle(cx, cy, r, col, seg)
	seg = seg or 40
	local pts = {}
	for i = 0, seg - 1 do
		local a = math.rad(i / seg * -360)
		pts[#pts + 1] = { x = cx + math.sin(a) * r, y = cy + math.cos(a) * r }
	end
	draw.NoTexture()
	surface.SetDrawColor(col)
	surface.DrawPoly(pts)
end

-- kleine Markierungen am Rand (wie bei den Karten im Menue)
function T.EdgeMarks(x, y, h, col)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, 4, 4)
	surface.DrawRect(x, y + 14, 4, h * 0.3)
	surface.DrawRect(x, y + 22 + h * 0.3, 4, 4)
end

--## Keypad-Bildschirm ##--

-- Der Rahmen des Keypad-Modells verdeckt oben und unten einen Teil des Bildschirms.
-- Alles Wichtige liegt innerhalb dieses sichtbaren Bereichs.
T.SAFE_TOP    = 50
T.SAFE_BOTTOM = 36

T.HEADER_H = 120   -- Kopf endet hier (inkl. verdecktem Bereich oben)
T.FOOTER_H = 90    -- Fuss beginnt bei ui_h - FOOTER_H (inkl. verdecktem Bereich unten)

-- Hintergrund + feine Rasterlinien
function T.ScreenBackground(w, h, bg)
	T.Box(0, 0, w, h, bg or T.ScreenColors.Idle)

	surface.SetDrawColor(255, 255, 255, 5)
	for y = 0, h, 6 do surface.DrawRect(0, y, w, 1) end
end

-- Kopf (Titel + Aurebesh), Fuss (Status + Aurebesh), Akzentleiste
function T.ScreenFrame(w, h, title, status, statusColor)
	local accent = statusColor or T.Accent()
	local pad = 24

	-- Kopf
	T.Heading(title, "bKeypads.BF.Head.", T.HeadSizes, pad, T.SAFE_TOP, w - pad * 2, T.Color("text"), 16)
	T.Box(pad, T.HEADER_H - 6, w - pad * 2, 1, T.Color("line2"))
	T.Box(pad, T.HEADER_H - 7, 60, 3, accent)

	-- Fuss
	local fy = h - T.FOOTER_H
	T.Box(0, fy, w, T.FOOTER_H, T.Color("foot", 235))
	T.Box(0, fy, w, 1, T.Color("line2"))
	if status then
		local sy = h - T.SAFE_BOTTOM - 46
		T.Box(pad - 2, sy + 4, 6, 22, accent)
		T.Heading(status, "bKeypads.BF.Status.", T.StatusSizes, pad + 14, sy, w - pad * 2 - 18, T.Color("text"), 13)
	end

	-- Akzentleiste links + Randmarkierungen rechts
	T.Box(0, 0, 6, h, accent)
	T.EdgeMarks(w - 16, T.HEADER_H + 24, 110, T.Alpha(accent, 200))
end

-- PIN-Taste. kind: nil = Ziffer, "cancel", "confirm"
function T.PINButton(x, y, size, hovered, pressed, kind)
	if pressed then x, y, size = x + 4, y + 4, size - 8 end

	if kind == "cancel" or kind == "confirm" then
		local c = kind == "cancel" and T.Color("red") or T.Color("green")
		if hovered then
			T.Box(x, y, size, size, c)
		else
			T.Box(x, y, size, size, Color(c.r * 0.14, c.g * 0.14, c.b * 0.14, 240))
			T.Outline(x, y, size, size, T.Alpha(c, 170), 2)
		end
		return hovered and T.Color("ink") or c
	end

	if hovered then
		T.Box(x, y, size, size, T.Accent())
		return T.Color("ink")
	end

	T.Box(x, y, size, size, T.Color("panel", 235))
	T.Outline(x, y, size, size, T.Color("line2"), 2)
	return T.Color("dim")
end
