--[[-------------------------------------------------------------------------
    Echoes of Clones – Escape Menu
    Konfiguration
---------------------------------------------------------------------------]]

EOC_ESC = EOC_ESC or {}
local CFG = {}
EOC_ESC.Config = CFG

-- Logo
-- Pfad relativ zum materials-Ordner (hier aus dem eoc_serverpack).
-- Fehlt die Datei beim Spieler, wird das eingebettete Ersatz-Logo genutzt.
CFG.Logo        = "vgui/hradio/eoc_logo.png"
CFG.LogoMaxH    = 260                -- maximale Logo-Höhe bei 1080p
CFG.Subtitle    = ""                 -- Text unter dem Logo (leer = kein Text)

-- Breite des Menüs relativ zur Bildschirmbreite (0.25 = ein Viertel)
CFG.WidthFrac   = 0.25
CFG.MinWidth    = 400
CFG.Margin      = 28                 -- Abstand des Panels zum Bildschirmrand (bei 1080p)

-- Farben (SymChars-Palette; der Akzent kommt live aus SymChars, dieser Wert ist nur der Ersatz)
CFG.Accent      = Color(252, 178, 73)
CFG.Background  = Color(11, 14, 18, 228)   -- Panel-Hintergrund (Alpha = Transparenz)
CFG.Border      = Color(255, 255, 255, 22) -- feiner Rahmen ums Panel
CFG.ScreenDim   = Color(0, 0, 0, 90)       -- Abdunklung des restlichen Bildschirms
CFG.Text        = Color(236, 233, 224)     -- normale Menüpunkte
CFG.TextActive  = Color(255, 255, 255)     -- Menüpunkt unter der Maus
CFG.TextDim     = Color(168, 174, 180)
CFG.Danger      = Color(225, 90, 84)

-- Mit gedrückter SHIFT-Taste + ESC das normale GMod-Menü öffnen (für Admins/Notfälle)
CFG.ShiftOpensLegacyMenu = true

-- Links (leer lassen = Menüpunkt wird ausgeblendet)
CFG.Discord     = "https://discord.gg/e7uRPw5m2m"
CFG.Workshop    = "https://steamcommunity.com/sharedfiles/filedetails/?id=3531701132"
CFG.Website     = ""

-- Zusätzliche Einstellungen im "Einstellungen"-Menü.
-- type: "checkbox" oder "slider" | convar: Client-ConVar die gesetzt wird
CFG.Settings = {
    { type = "checkbox", label = "FPS anzeigen",           convar = "cl_showfps" },
    { type = "checkbox", label = "Multicore Rendering",    convar = "gmod_mcore_test" },
    { type = "slider",   label = "Sichtfeld (FOV)",        convar = "fov_desired", min = 75, max = 100, decimals = 0 },
}
