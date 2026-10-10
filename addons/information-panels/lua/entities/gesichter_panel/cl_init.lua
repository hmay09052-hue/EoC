include("shared.lua")

-- Drehrichtungen: 8 "Ticks" für eine volle Drehung, gedreht wird immer nach rechts (Uhrzeigersinn)
local TICKS = {
	[0] = "Ausgangsposition",
	[1] = "Steigung · 1 Tick",
	[2] = "Rechts um · 2 Ticks",
	[3] = "Gefälle · 3 Ticks",
	[4] = "Kehrt um · 4 Ticks",
}

local function Diagram(B, ent, x, y, w, h, accent)
	local cx, cy = x + w * 0.36, y + h / 2 + 10
	local r = math.min(w * 0.26, h / 2 - 90)

	-- Drehrichtung: Punktlinie von 0 bis 180 Grad im Uhrzeigersinn
	for a = 4, 176, 4 do
		local rad = math.rad(a - 90)
		B.Rect(cx + math.cos(rad) * (r + 46) - 4, cy + math.sin(rad) * (r + 46) - 4, 8, 8, Color(accent.r, accent.g, accent.b, 120))
	end

	for i = 0, 7 do
		local rad = math.rad(i * 45 - 90)
		local dx, dy = math.cos(rad), math.sin(rad)
		local labelled = TICKS[i] ~= nil
		local col = labelled and accent or B.col.muted

		for d = 90, r - 40, 26 do
			B.Rect(cx + dx * d - 3, cy + dy * d - 3, 6, 6, B.col.line)
		end

		local s = labelled and 64 or 40
		B.Marker(cx + dx * r - s / 2, cy + dy * r - s / 2, s, col)
		B.Text(tostring(i), "eocboard.hint", cx + dx * (r - 70), cy + dy * (r - 70), B.col.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if labelled then
			local lx, ly = cx + dx * (r + 60), cy + dy * (r + 60)
			local ax = (i == 0 or i == 4) and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT
			if i == 0 then ly = ly - 30 elseif i == 4 then ly = ly + 30 else lx = lx + 30 end
			B.Text(TICKS[i], "eocboard.btn", lx, ly, B.col.text, ax, TEXT_ALIGN_CENTER)
		end
	end

	B.Marker(cx - 60, cy - 60, 120, B.col.steel)
	B.Rect(cx - 4, cy - 110, 8, 46, B.col.steel) -- Blickrichtung
end

ENT.Pages = {
	{
		title = "Gesichter",
		split = 0.6,
		draw = Diagram,
		body = {
			{"p", "Gesichter (Drehungen) sind für alle Truppen relevant."},
			{"p", "Das Diagramm links dient dabei als Hilfe."},
			{"gap", 20},
			{"b", "Eine volle Drehung besteht aus 8 Ticks."},
			{"b", "Gedreht wird immer nach rechts."},
			{"b", "Die genauen Erklärungen stehen auf Seite 2."},
		},
	},
	{
		title = "Gesichter erklärt",
		body = {
			{"b", "In der Third Person dreht sich dein Charakter in 8 Schritten einmal um 360 Grad. Jeder dieser Schritte gilt als „Tick“ (siehe Diagramm auf Seite 1)."},
			{"gap", 8},
			{"kv", "Steigung", "1 Tick"},
			{"kv", "Rechts um", "2 Ticks"},
			{"kv", "Gefälle", "3 Ticks"},
			{"kv", "Kehrt um", "4 Ticks"},
			{"gap", 8},
			{"b", "Beginne immer in der Ausgangsposition – sie ist der Person zugewandt, die die Gesichter anordnet."},
			{"b", "Drehe dich bei „Rechts um“ und „Kehrt um“ immer nach rechts."},
		},
	},
}

function ENT:Draw()
	EOC_BOARD.Draw(self)
end
