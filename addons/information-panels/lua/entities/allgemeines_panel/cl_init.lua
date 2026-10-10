include("shared.lua")

ENT.Pages = {
	{
		title = "Namensgebung",
		body = {
			{"b", "Clones bekamen nach ihrer Geburt eine ID zur Identifikation."},
			{"b", "Im Laufe des Krieges änderte sich das und sie gaben sich untereinander Namen."},
			{"b", "Bitte beachte bei deiner Namensgebung folgendes Schema:"},
			{"gap", 6},
			{"kv", "Schema", "CT-[Deine Wunsch-ID] [Dein Wunsch-Name]"},
			{"kv", "Beispiel", "CT-5555 Fives"},
			{"gap", 12},
			{"p", "Achte darauf, dass dein Name ins Star-Wars-Universum passt."},
		},
	},
	{
		title = "Was ist Roleplay?",
		body = {
			{"b", "Roleplay heißt übersetzt Rollenspiel."},
			{"b", "Bei einem Rollenspiel versetzt man sich in einen Charakter – in unserem Fall in einen Clone."},
			{"b", "Im Roleplay bist du die Person im Spiel und nicht die Person vor dem Bildschirm."},
			{"b", "Verhalte dich auch so und zeige Respekt – mindestens gegenüber Offizieren."},
		},
	},
	{
		title = "Was ist PassivRP?",
		body = {
			{"b", "Manche Aktionen im Roleplay können nur in schriftlicher Form ausgeführt werden. Zum Beispiel:"},
			{"gap", 6},
			{"kv", "Lokaler Akt", "/me [Aktion deines Chars] + ggf. /roll"},
			{"kv", "Globaler Akt", "/akt [Aktion deines Chars] + ggf. /roll"},
			{"kv", "Medic-Akt", "/makt [Aktion deines Chars] + ggf. /roll"},
			{"kv", "Event-Akt", "/eakt [Aktion deines Chars] + ggf. /roll"},
			{"gap", 12},
			{"b", "Achte darauf, dass deine Aktionen realistisch sind."},
		},
	},
	{
		title = "Was ist MedicRP?",
		body = {
			{"b", "MedicRP sind Aktionen, die schriftlich und mündlich ausgeführt werden können. Zum Beispiel:"},
			{"gap", 6},
			{"kv", "Mediziner", "Führt einen Phase-I- und -II-Scan am Patienten durch."},
			{"kv", "Patient", "Hat eine Schussverletzung am rechten Arm."},
			{"kv", "Mediziner", "Desinfiziert die Wunde, trägt Synthfleisch auf und legt einen Bacta-Verband an."},
			{"gap", 12},
			{"b", "Diese Aktionen werden ausschließlich mit /makt ausgeführt."},
			{"b", "Achte darauf, dass deine Aktionen realistisch sind."},
		},
	},
	{
		title = "Regelwerk · Seite 1",
		body = {
			{"kv", "FailRP", "Unrealistische Handlungen"},
			{"kv", "FearRP", "Realistische Reaktionen"},
			{"kv", "NinjaRP", "Anderen keine Möglichkeit geben, auf RP zu reagieren"},
			{"kv", "ErotikRP", "Erotische Handlungen"},
			{"kv", "RDM", "Random Deathmatch"},
			{"kv", "VDM", "Vehicle Deathmatch"},
			{"kv", "NLR", "New Life Rule"},
		},
	},
	{
		title = "Regelwerk · Seite 2",
		body = {
			{"kv", "Ausrüstung", "Missbrauch von Ausrüstung"},
			{"kv", "Metagaming", "OOC-Wissen nutzen, um IC einen Vorteil zu bekommen"},
			{"kv", "Powergaming", "Sich selbst übermäßig stark spielen"},
			{"kv", "Offlineflucht", "Einer RP-Situation durch Verlassen des Servers entfliehen"},
			{"kv", "PTS", "Permission to Speak"},
			{"kv", "Space", "Überleben im Vakuum"},
			{"gap", 14},
			{"c", "Alle weiteren Regeln findest du auf unserem Discord."},
		},
	},
	{
		title = "Tastenbelegung",
		body = {
			{"kv", "T", "Perspektive wechseln"},
			{"kv", "^", "Lautstärke wechseln"},
			{"kv", "C", "Waffen-Interface"},
			{"kv", "H", "Funkgerät öffnen"},
			{"kv", "Shift + E", "Waffe sichern / entsichern"},
			{"kv", "F4", "Fraktionen"},
			{"kv", "F5", "Ticket-Menü"},
			{"kv", "F6", "Charakter-Menü"},
		},
	},
	{
		title = "Chatbefehle · Seite 1",
		body = {
			{"h", "OOC"},
			{"kv", "/looc [Text]", "Lokale OOC-Nachricht"},
			{"kv", "/ooc [Text]", "Globale OOC-Nachricht"},
			{"kv", "/pm [Name] [Text]", "Private OOC-Nachricht"},
			{"h", "IC"},
			{"kv", "/funk an [Name] [Text]", "Funknachricht"},
			{"kv", "/vfunk [SteamID] [Text]", "Verschlüsselte Funknachricht"},
			{"kv", "/decode [Nachricht]", "Funknachricht entschlüsseln"},
		},
	},
	{
		title = "Chatbefehle · Seite 2",
		body = {
			{"h", "PassivRP"},
			{"kv", "/id", "ID vorzeigen"},
			{"kv", "/drop", "Gegenstand fallen lassen"},
		},
	},
	{
		title = "Funkcodes · Seite 1",
		body = {
			{"kv", "10-1", "Melde mich im Dienst / Funk"},
			{"kv", "10-2", "Wiederholen / nicht verstanden"},
			{"kv", "10-3", "Negativ, lehne ab, stimme nicht zu"},
			{"kv", "10-4", "Positiv, bestätige, stimme zu"},
			{"kv", "10-5", "Benötige Verstärkung [Einheit]"},
			{"kv", "10-6", "Feind gesichtet [Himmelsrichtung]"},
			{"kv", "10-7", "Unidentifizierte Person gesichtet [Himmelsrichtung]"},
			{"kv", "10-8 / a / b", "Erbitte Starterlaubnis / erteilt / verweigert"},
			{"kv", "10-9 / a / b", "Erbitte Landeerlaubnis / erteilt / verweigert"},
		},
	},
	{
		title = "Funkcodes · Seite 2",
		body = {
			{"kv", "10-10", "Erbitte Öffnung von MH, SH, UH, MG oder SG"},
			{"kv", "10-11", "Erwarte Befehle"},
			{"kv", "10-15a", "Einheiten vorrücken"},
			{"kv", "10-15b", "Einheiten zurückziehen"},
			{"kv", "10-18a", "Melde mich vom Dienst ab"},
			{"kv", "10-20", "Standortabfrage"},
		},
	},
}

function ENT:Draw()
	EOC_BOARD.Draw(self)
end
