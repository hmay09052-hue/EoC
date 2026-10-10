include("shared.lua")

-- Formationen als Liste von Quadraten { x, y, Größe, Offizier? } in freien Koordinaten.
-- Sie werden automatisch auf die Tafel eingepasst und zentriert.
local function Wave(a, b, speed)
	return a + (b - a) * (0.5 + 0.5 * math.sin(CurTime() * (speed or 2)))
end

local function Formation(build)
	return function(B, ent, x, y, w, h, accent)
		local squares = build()
		local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
		for _, s in ipairs(squares) do
			minX, minY = math.min(minX, s[1]), math.min(minY, s[2])
			maxX, maxY = math.max(maxX, s[1] + s[3]), math.max(maxY, s[2] + s[3])
		end
		local bw, bh = maxX - minX, maxY - minY
		local k = math.min(w / bw, (h - 60) / bh, 0.8)
		local ox = x + (w - bw * k) / 2 - minX * k
		local oy = y + (h - 60 - bh * k) / 2 - minY * k
		for _, s in ipairs(squares) do
			if s[3] > 0 then
				B.Marker(ox + s[1] * k, oy + s[2] * k, s[3] * k, s[4] and accent or B.col.steel)
			end
		end
		-- Legende
		local ly = y + h - 34
		B.Rect(x + w / 2 - 250, ly - 12, 24, 24, accent)
		B.Text("Offizier", "eocboard.hint", x + w / 2 - 216, ly, B.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		B.Rect(x + w / 2 + 40, ly - 12, 24, 24, B.col.steel)
		B.Text("Trooper", "eocboard.hint", x + w / 2 + 74, ly, B.col.dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
end

local function Column(n, xs, step)
	local t = {}
	for _, cx in ipairs(xs) do
		for i = 1, n do t[#t + 1] = { cx, i * step, 128 } end
	end
	return t
end

ENT.Pages = {
	{
		title = "Grundlagen",
		draw = function(B, ent, x, y, w, h, accent)
			local s = 120
			local top = y + 40
			B.Marker(x + 80, top, s, accent)
			B.Text("Kommandierender Offizier", "eocboard.btn", x + 80 + s + 40, top + s / 2, B.col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			B.Marker(x + 80, top + s + 40, s, B.col.steel)
			B.Text("Trooper", "eocboard.btn", x + 80 + s + 40, top + s * 1.5 + 40, B.col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			B.Rect(x + 80, top + s * 2 + 100, w - 160, 3, B.col.line)
			B.Text("Bei Formationen stellen sich die Trooper", "eocboard.p", x + w / 2, top + s * 2 + 140, B.col.text, TEXT_ALIGN_CENTER)
			B.Text("nach Rangordnung auf – der höchste zuerst.", "eocboard.p", x + w / 2, top + s * 2 + 196, B.col.text, TEXT_ALIGN_CENTER)
		end,
	},
	{
		title = "Einfache Kolonne",
		draw = Formation(function()
			local t = Column(3, { 0 }, 140)
			t[#t + 1] = { 0, 0, 128, true }
			return t
		end),
	},
	{
		title = "Erweiterte Kolonne",
		draw = Formation(function()
			local t = Column(3, { -128, 128 }, 140)
			t[#t + 1] = { 0, 0, 128, true }
			return t
		end),
	},
	{
		title = "Einfacher / Erweiterter Pfeil",
		draw = Formation(function()
			local spread = Wave(60, 120)
			local t = { { 0, 0, 110, true }, { -360, 0, 0 }, { 470, 515, 0 } }
			for i = 1, 3 do
				t[#t + 1] = { -spread * i, 135 * i, 110 }
				t[#t + 1] = { spread * i, 135 * i, 110 }
			end
			return t
		end),
	},
	{
		title = "Diamant · VIP · Gefangener",
		draw = Formation(function()
			local d = 150 + Wave(0, 100)
			return {
				{ 0, 0, 128, true },
				{ 0, d, 128 }, { 0, -d, 128 }, { d, 0, 128 }, { -d, 0, 128 },
				{ -250, -250, 0 }, { 378, 378, 0 }, -- feste Grenzen (Größe 0 = unsichtbar), damit die Animation nicht mitskaliert
			}
		end),
	},
	{
		title = "Feuerlinie",
		draw = Formation(function()
			local t = { { 300, -275, 128, true } }
			for i = 1, 5 do t[#t + 1] = { 135 * i - 525, 0, 128 } end
			return t
		end),
	},
	{
		title = "Erweiterte Feuerlinie",
		draw = Formation(function()
			local t = { { 250, -250, 128, true } }
			for i = 1, 5 do
				t[#t + 1] = { 110 * i - 475, -20, 100 }
				t[#t + 1] = { 110 * i - 475, 100, 100 }
			end
			return t
		end),
	},
	{
		title = "Empfangskolonne",
		draw = Formation(function()
			return {
				{ -314, -330, 128, true }, { 160, -330, 128 },
				{ -314, -180, 128 }, { 160, -180, 128 },
				{ -314, -30, 128 }, { 160, -30, 128 },
				{ -314, 120, 128 }, { 160, 120, 128 },
			}
		end),
	},
	{
		title = "Linke Staffel",
		draw = Formation(function()
			return { { 150, -300, 128, true }, { 0, -150, 128 }, { -150, 0, 128 }, { -300, 150, 128 } }
		end),
	},
	{
		title = "Rechte Staffel",
		draw = Formation(function()
			return { { -300, -300, 128, true }, { -150, -150, 128 }, { 0, 0, 128 }, { 150, 150, 128 } }
		end),
	},
}

function ENT:Draw()
	EOC_BOARD.Draw(self)
end
