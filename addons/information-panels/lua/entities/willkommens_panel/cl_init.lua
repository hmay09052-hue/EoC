include("shared.lua")

ENT.Pages = {
	{
		title = "Willkommen",
		body = {
			{"h", "Willkommen auf Echoes of Clones!"},
			{"gap", 10},
			{"p", "Schön, dass du da bist. Falls du neu bist, drücke Y und schreibe in den Chat:"},
			{"gap", 6},
			{"kv", "/ooc", "Ich benötige einen Ausbilder"},
			{"gap", 16},
			{"p", "In den nächsten Minuten wird dir ein Ausbilder oder ein Teammitglied alles Wichtige erklären, was du für das RP auf diesem Server benötigst."},
			{"p", "Hast du Fragen, stelle sie ohne Scheu – es gibt keine falschen Fragen."},
			{"gap", 16},
			{"c", "Viel Spaß!"},
		},
	},
}

function ENT:Draw()
	EOC_BOARD.Draw(self)
end
