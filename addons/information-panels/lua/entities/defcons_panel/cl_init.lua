include("shared.lua")

-- Namen und Farben kommen aus dem DEFCON-System (eoc_defcon), damit Tafel und HUD immer übereinstimmen.
local FALLBACK = {
	[5] = { "FREIGANG", Color(85, 225, 143) },
	[4] = { "BEREITSCHAFTSALARM", Color(85, 184, 255) },
	[3] = { "ANGRIFFSALARM", Color(255, 216, 90) },
	[2] = { "INFILTRATIONSALARM", Color(255, 153, 77) },
	[1] = { "EVAKUIERUNGSALARM", Color(255, 79, 94) },
}

local function Level(n)
	local cfg = GRN_DEFCON and GRN_DEFCON.Config and GRN_DEFCON.Config.Levels and GRN_DEFCON.Config.Levels[n]
	local name, col = FALLBACK[n][1], FALLBACK[n][2]
	if cfg then
		name = cfg.Name or name
		local hex = tostring(cfg.Color or ""):gsub("#", "")
		if #hex == 6 then
			col = Color(tonumber(hex:sub(1, 2), 16) or col.r, tonumber(hex:sub(3, 4), 16) or col.g, tonumber(hex:sub(5, 6), 16) or col.b)
		end
	end
	return name, col
end

local function Badge(n)
	return function(B, ent, x, y, w, h)
		local name, col = Level(n)
		local s = math.min(w * 0.7, h * 0.62)
		local bx, by = x + (w - s) / 2, y + (h - s) / 2 - 40
		B.Rect(bx, by, s, s, Color(col.r, col.g, col.b, 30))
		B.Outline(bx, by, s, s, col, 6)
		B.Corners(bx - 14, by - 14, s + 28, s + 28, col, 34, 5)
		B.Text("DEFCON", "eocboard.mark", bx + s / 2, by + s * 0.2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		B.Text(tostring(n), "eocboard.big", bx + s / 2, by + s * 0.6, B.col.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		B.Text(name, "eocboard.btn", x + w / 2, by + s + 34, col, TEXT_ALIGN_CENTER)
	end
end

local function LevelPage(n, body)
	local _, col = Level(n)
	return { title = "DEFCON " .. n, accent = col, draw = Badge(n), split = 0.30, body = body }
end

ENT.Pages = {
	{
		title = "DEFCON-Informationen",
		split = 0.36,
		draw = function(B, ent, x, y, w, h)
			local row = math.min(110, h / 5)
			local top = y + (h - row * 5) / 2
			for i = 0, 4 do
				local n = 5 - i
				local name, col = Level(n)
				local ry = top + i * row
				B.Rect(x, ry + 8, w, row - 16, B.col.card)
				B.Rect(x, ry + 8, 10, row - 16, col)
				B.Text(tostring(n), "eocboard.mark", x + 60, ry + row / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				B.Text(name, "eocboard.btn", x + 110, ry + row / 2 + 2, B.col.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end,
		body = {
			{"p", "Das DEFCON-System verkürzt die Reaktionszeit und verhindert Panik in Notsituationen."},
			{"p", "Es gibt 5 Stufen. Jede verlangt eine bestimmte Reaktion von Troopern, Einheitsleitern und der Navy."},
			{"gap", 14},
			{"b", "Die Stufen zählen herunter: DEFCON 5 ist die niedrigste Bedrohung, DEFCON 1 die höchste."},
			{"b", "Jede weitere Seite erklärt eine Stufe."},
			{"b", "Die Farben links findest du auch im HUD – dort siehst du jederzeit die aktuelle Stufe."},
		},
	},
	LevelPage(5, {
		{"p", "DEFCON 5 ist die niedrigste Stufe des DEFCON-Systems."},
		{"h", "Es gilt"},
		{"b", "Die Truppen behalten ihre Standardaufgaben bei oder nehmen sie wieder auf."},
		{"b", "Verdächtiges Verhalten wird dem kommandierenden Offizier gemeldet."},
	}),
	LevelPage(4, {
		{"p", "Gilt bei Verdacht auf feindliche Aktivitäten in oder nahe dem Schiff bzw. der Basis – oder beim Verlassen einer aktiven Kampfsituation."},
		{"h", "Es gilt"},
		{"b", "Standardaufgaben beibehalten und dabei auf verdächtige Aktivitäten achten."},
		{"b", "Starfighter-Piloten machen sich bei Bedarf einsatzbereit."},
		{"b", "Waffen dürfen gezogen werden, bleiben aber gesichert, sofern nicht anders befohlen."},
		{"b", "Verdächtiges Verhalten wird dem kommandierenden Offizier gemeldet."},
	}),
	LevelPage(3, {
		{"p", "Gilt, wenn feindliche Kontakte einen Angriff auf Basis oder Schiff begonnen haben. Einheitsleiter führen ihre Truppen zu den zugewiesenen Stationen."},
		{"h", "Es gilt"},
		{"b", "Alle Truppen im aktiven Dienst melden sich an ihren Kampfstationen."},
		{"b", "Waffen sind gezogen, die Truppen sind kampfbereit."},
		{"b", "Außerhalb des Kampfes werden keine Start- oder Landeanfragen gewährt."},
		{"b", "Verdächtiges Verhalten und feindliche Aktivitäten gehen an die Einsatzleitung."},
	}),
	LevelPage(2, {
		{"p", "Gilt, wenn feindliche Kontakte in die Basis oder das Schiff eingedrungen sind."},
		{"h", "Es gilt"},
		{"b", "Alle Einsatzkräfte melden sich in kritischen Bereichen – Kommandozentrale, Brücke, Maschinen- oder Reaktorraum – oder ziehen sich dorthin zurück."},
		{"b", "Diese Bereiche werden um jeden Preis gehalten. Ihr Verlust würde den Militär- und Navybetrieb ernsthaft stören."},
	}),
	LevelPage(1, {
		{"p", "Gilt, wenn Schlüsselbereiche zerstört oder eingenommen wurden und die Lage nicht mehr zu retten ist."},
		{"h", "Es gilt"},
		{"b", "Alle Einheiten begeben sich zum nächsten Hangar oder Transportbereich und evakuieren."},
		{"b", "Clones mit passender Pilotenlizenz starten, sobald ihr Fahrzeug mit Truppen beladen ist."},
	}),
}

function ENT:Draw()
	EOC_BOARD.Draw(self)
end
