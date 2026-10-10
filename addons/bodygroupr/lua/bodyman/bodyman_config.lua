-- ============================================================================
--  Echoes of Clones // Aussehen-System – Konfiguration
--  Wie Jobs Skins/Bodygroups bekommen, steht in README.lua.
-- ============================================================================

-- Branding --------------------------------------------------------------------
BODYMAN.ServerName     = "Echoes of Clones"
BODYMAN.ServerSubtitle = "Clone Wars Roleplay"
BODYMAN.HeaderRight    = "GALACTIC REPUBLIC"
BODYMAN.FooterText     = "ECHOES OF CLONES // SECURE TERMINAL"

-- Schriftart (gleiche wie im Charakter-Menü des Servers)
BODYMAN.Font = "Lato"

-- Farben im Server-Design
BODYMAN.Theme = {
	Yellow      = Color(252, 178, 73),
	YellowHover = Color(255, 207, 92),
	YellowSoft  = Color(252, 178, 73, 105),
	White       = Color(244, 246, 248),
	Text        = Color(215, 219, 225),
	Muted       = Color(121, 128, 139),
	Dim         = Color(76, 82, 92),
	Panel       = Color(10, 13, 17, 245),
	PanelSoft   = Color(16, 20, 25, 222),
	PanelHover  = Color(25, 30, 36, 236),
	Line        = Color(255, 255, 255, 31),
	LineStrong  = Color(255, 255, 255, 70),
	Danger      = Color(216, 81, 89),
	Green       = Color(72, 197, 126),
}

-- Sprache: "de", "en" oder "fr"
BODYMAN.Language = "de"

-- Verhalten -------------------------------------------------------------------
-- true = Spieler können ihr Aussehen NUR an einem Kleiderschrank ändern.
BODYMAN.ClosetsOnly = false

-- Wie nah (in Units) ein Spieler am Schrank sein muss (für ClosetsOnly).
BODYMAN.ClosetUseRange = 160

-- Chat-Befehle zum Öffnen des Menüs (Groß-/Kleinschreibung egal)
BODYMAN.ChatCommands = { "/bo", "!bo" }

-- Gewähltes Modell/Skin/Bodygroups pro Job merken und nach Respawn wiederherstellen.
BODYMAN.RememberAppearance = true

-- Bodygroups mit nur einer Option nicht im Menü anzeigen.
BODYMAN.HideSingleOptionGroups = true

-- Änderungen der Spieler in die Server-Konsole schreiben.
BODYMAN.LogChanges = true

-- Ränge, die das Admin-Menü benutzen dürfen (Superadmins dürfen immer).
BODYMAN.AdminGroups = {
	["superadmin"] = true,
}

-- Kleiderschrank ----------------------------------------------------------------
BODYMAN.ClosetModel         = "models/reizer_props/srsp/sci_fi/armory_02_3/armory_02_3.mdl"
BODYMAN.ClosetFallbackModel = "models/props_c17/FurnitureDresser001a.mdl" -- falls das Modell fehlt
BODYMAN.ClosetViewDistance  = 256  -- ab welcher Entfernung der Text am Schrank sichtbar ist
BODYMAN.ClosetsCanBreak     = false -- können Schränke zerschossen werden?
BODYMAN.ClosetHealth        = 3000

-- Texte -----------------------------------------------------------------------
BODYMAN.Lang = {
	de = {
		Title           = "Aussehen",
		Subtitle        = "Passe Modell, Skin und Ausrüstung deiner Einheit an",
		Preview         = "Vorschau",
		Unit            = "Einheit",
		Models          = "Modell",
		Skins           = "Skin",
		Options         = "Optionen",
		None            = "Keine",
		Variant         = "Variante",
		Help            = "LMB ziehen: drehen & zoomen  ·  Mausrad: zoomen  ·  RMB ziehen: verschieben",
		NothingToChange = "Für deine aktuelle Einheit gibt es keine anpassbaren Optionen.",
		NeedCloset      = "Du musst an einem Kleiderschrank stehen, um dein Aussehen anzupassen.",
		NoPermission    = "Dafür hast du keine Berechtigung.",
		ClosetName      = "Kleiderschrank",
		ClosetHelp      = "Drücke [E], um dein\nAussehen anzupassen.",
		AdminTitle      = "Schrank-Verwaltung",
		AdminSubtitle   = "Kleiderschränke auf dieser Karte verwalten",
		AdminSpawn      = "Schrank spawnen (Blickrichtung)",
		AdminSave       = "Schränke speichern",
		AdminLoad       = "Gespeicherte Schränke laden",
		AdminRemove     = "Alle Schränke entfernen (ohne Speichern)",
		OnMap           = "Auf der Karte",
		Saved           = "%d Schränke für %s gespeichert.",
		Loaded          = "%d Schränke geladen.",
		Removed         = "Alle Schränke entfernt. Speichere, um das dauerhaft zu machen.",
		Spawned         = "Schrank gespawnt.",
		ContextTitle    = "Aussehen",
		ContextAdmin    = "Schränke (Admin)",
	},
	en = {
		Title           = "Appearance",
		Subtitle        = "Customize your unit's model, skin and equipment",
		Preview         = "Preview",
		Unit            = "Unit",
		Models          = "Model",
		Skins           = "Skin",
		Options         = "Options",
		None            = "None",
		Variant         = "Variant",
		Help            = "LMB drag: rotate & zoom  ·  Wheel: zoom  ·  RMB drag: pan",
		NothingToChange = "Your current unit has no customizable options.",
		NeedCloset      = "You have to stand at a closet to change your appearance.",
		NoPermission    = "You don't have permission to do that.",
		ClosetName      = "Closet",
		ClosetHelp      = "Press [E] to customize\nyour appearance.",
		AdminTitle      = "Closet Management",
		AdminSubtitle   = "Manage closets on this map",
		AdminSpawn      = "Spawn closet (where you look)",
		AdminSave       = "Save closets",
		AdminLoad       = "Load saved closets",
		AdminRemove     = "Remove all closets (without saving)",
		OnMap           = "On this map",
		Saved           = "Saved %d closets for %s.",
		Loaded          = "Loaded %d closets.",
		Removed         = "Removed all closets. Save to make this permanent.",
		Spawned         = "Closet spawned.",
		ContextTitle    = "Appearance",
		ContextAdmin    = "Closets (Admin)",
	},
	fr = {
		Title           = "Apparence",
		Subtitle        = "Personnalisez le modèle, la peau et l'équipement",
		Preview         = "Aperçu",
		Unit            = "Unité",
		Models          = "Modèle",
		Skins           = "Peau",
		Options         = "Options",
		None            = "Aucun",
		Variant         = "Variante",
		Help            = "Clic gauche : pivoter & zoomer  ·  Molette : zoom  ·  Clic droit : déplacer",
		NothingToChange = "Votre unité actuelle n'a aucune option personnalisable.",
		NeedCloset      = "Vous devez être près d'une armoire pour changer votre apparence.",
		NoPermission    = "Vous n'avez pas la permission.",
		ClosetName      = "Armoire",
		ClosetHelp      = "Appuyez sur [E] pour personnaliser\nvotre apparence.",
		AdminTitle      = "Gestion des armoires",
		AdminSubtitle   = "Gérer les armoires de cette carte",
		AdminSpawn      = "Faire apparaître une armoire",
		AdminSave       = "Sauvegarder les armoires",
		AdminLoad       = "Restaurer les armoires sauvegardées",
		AdminRemove     = "Retirer toutes les armoires (sans sauvegarder)",
		OnMap           = "Sur la carte",
		Saved           = "%d armoires sauvegardées pour %s.",
		Loaded          = "%d armoires restaurées.",
		Removed         = "Armoires retirées. Sauvegardez pour rendre cela permanent.",
		Spawned         = "Armoire apparue.",
		ContextTitle    = "Apparence",
		ContextAdmin    = "Armoires (Admin)",
	},
}
