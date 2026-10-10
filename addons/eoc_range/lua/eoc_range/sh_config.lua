--[[
    EoC Range – Einstellungen
    Alles, was Admins anpassen wollen, steht hier. Schwellen, Einheitenebene und DEFCON-Sperre
    lassen sich zusätzlich ingame im Ausbilder-Menü (Reiter Einstellungen) ändern; diese Werte
    landen in data/eoc_range/settings.json und überschreiben die Werte hier.
]]

EoCRange.Config = EoCRange.Config or {}
local C = EoCRange.Config

---------------------------------------------------------------------------
-- Rollen
---------------------------------------------------------------------------
-- DarkRP-Jobs, die als Ausbilder zählen. Erlaubt sind Team-Variablen als String ("TEAM_AUSBILDER"),
-- Job-Befehle ("ausbilder") oder Teile des Jobnamens ("Sergeant" trifft alle Sergeant-Ränge).
C.InstructorJobs = { "TEAM_AUSBILDER" }
C.InstructorJobPatterns = { "Sergeant", "Lieutenant", "Captain", "Major", "Commander", "Colonel", "General" }

-- SAM-Usergroups mit Ausbilderrechten
C.InstructorGroups = { "ausbilder", "supporter", "moderator" }

-- SAM-Usergroups mit vollen Rechten (Superadmins haben sie immer)
C.AdminGroups = { "admin", "headadmin", "superadmin", "owner" }

-- Optional: SymChars-Fortbildungen, deren Besitz ebenfalls Ausbilderrechte gibt (IDs)
C.InstructorTrainings = {}

---------------------------------------------------------------------------
-- Einheiten
---------------------------------------------------------------------------
-- "sub"  = Untereinheit aus SymChars zählt (z. B. "ARF")
-- "main" = Haupteinheit (oberste Einheit im Baum, z. B. "501st")
C.UnitLevel = "sub"

-- Wie viele beste Schützen je Einheit in die Einheitenwertung eingehen
C.UnitScoreTop = 5

---------------------------------------------------------------------------
-- Waffen (Klassen aus den ArcCW Republic Essentials)
---------------------------------------------------------------------------
-- true = JEDE ArcCW-Waffe ist in allen Disziplinen erlaubt (auch scharfe Waffen).
-- false = nur die Waffen, die eine Disziplin unten freigibt. Ingame umschaltbar (Menü → Einstellungen).
C.AllowAllArcCW = true

C.Weapons = {
    -- Sammelgruppe für eigene Disziplinen: jede Waffe, die auf ArcCW basiert
    arccw = { name = "Alle ArcCW-Waffen", any = true, classes = {} },
    dc15a = { name = "DC-15a Training", classes = { "arccw_k_dc15a_train" } },
    dc15s = { name = "DC-15s Training", classes = { "arccw_k_dc15s_train" } },
    dc17  = { name = "DC-17 Training",  classes = { "arccw_k_dc17_training" } },
    -- Trainingsvariante wird von EoC Range selbst mitgeliefert (lua/weapons/arccw_eocr_dc15x_train.lua)
    dc15x = { name = "DC-15x Training", classes = { "arccw_eocr_dc15x_train" } },
}

-- Ausnahme für die echte DC-15x im Scharfschützen-Modus (nur innerhalb der Bahnzone).
-- Standard aus: die Trainingsvariante oben macht 1 Schaden und reicht völlig.
C.AllowLiveSniper = false
C.LiveSniperClasses = { "arccw_k_dc15x" }

-- Diese "Waffen" dürfen während eines Laufs in der Hand sein, ohne dass der Lauf abbricht.
-- Ein Lauf STARTET aber nur mit einer erlaubten Trainingswaffe in der Hand.
C.HarmlessWeapons = { "keys", "pocket", "weapon_empty_hands", "weapon_hands", "perfect_hands", "weapon_physgun", "gmod_tool", "gmod_camera" }

---------------------------------------------------------------------------
-- Ablauf
---------------------------------------------------------------------------
C.Countdown        = 3      -- Sekunden Countdown vor jedem Lauf
C.MaxRunTime       = 180    -- harte Obergrenze für jeden Lauf (Sekunden)
C.TimedLimit       = 120    -- Zeitlauf / Squad-Lauf: Abbruch nach so vielen Sekunden
C.ParcoursReadyMax = 60     -- Parcours: so lange darf man in der Startzone warten
C.NoZoneRadius     = 300    -- gibt es keine Bahnzone, muss man so nah am Terminal stehen
C.PopupResetTime   = 3      -- freies Schießen: Klappziel steht nach X s wieder auf
C.PopupFlipTime    = 0.25   -- Animation Hochklappen/Fallen
C.HoleLifetime     = 10     -- Einschusslöcher bleiben X s sichtbar
C.ResultShowTime   = 10     -- Ergebnis über dem Terminal

C.SquadMin = 2
C.SquadMax = 5

-- Bewegtziel: Geschwindigkeit (Units/s) und Multiplikator je Stufe
C.MoverSpeeds      = { 70, 120, 180 }
C.MoverMultipliers = { 1.0, 1.5, 2.0 }
C.MoverDefaultTrack = 300   -- Länge der Schiene in Units, falls nichts eingestellt ist

---------------------------------------------------------------------------
-- Wertung
---------------------------------------------------------------------------
C.PopupHitPoints       = 100   -- Klappziel getroffen
C.ReactionBonusMax     = 50    -- Bonus je nach Reaktionszeit (0 .. 50)
C.HeadMultiplier       = 2     -- Kopfzone auf Silhouetten
C.HeadZone             = 0.80  -- alles oberhalb von 80 % der Silhouettenhöhe ist Kopf
C.HostagePenaltyPoints = 150
C.HostagePenaltySecs   = 5
C.MissPenaltyPoints    = 10
C.MissPenaltySecs      = 2
C.UnhitTargetSecs      = 5     -- Parcours/Zeitlauf: nicht getroffenes Ziel bei Zeitüberschreitung
C.ReactionMinMs        = 120   -- schneller = verdächtig, wird markiert und erst nach Prüfung gewertet

---------------------------------------------------------------------------
-- Schützenabzeichen
---------------------------------------------------------------------------
C.BadgeNames = { "Schütze", "Scharfschütze", "Meisterschütze" }
C.BadgeColors = { Color(176, 141, 87), Color(190, 200, 214), Color(255, 190, 50) }

-- Disziplinen der Prüfung. Für eine Stufe müssen ALLE in derselben Prüfung erreicht werden.
C.ExamDisciplines = { "precision_25", "precision_50", "timed", "rapid" }

-- Startwerte; werden nach den ersten Wochen anhand echter Ergebnisse angepasst.
-- Punkte-Disziplinen: Wert muss >= sein. Zeit-Disziplinen: Wert muss <= sein. Schnellfeuer: Treffer von 8.
C.Thresholds = {
    precision_25 = { 70, 85, 95 },
    precision_50 = { 60, 75, 88 },
    timed        = { 30, 22, 16 },
    rapid        = { 6, 7, 8 },
}

-- SymChars-Fortbildungen, die beim Bestehen eingetragen werden (stehen dann im Datapad unter Fortbildungen).
-- Werden beim Serverstart automatisch angelegt, falls sie fehlen.
C.BadgeTrainings = {
    { id = "eocr_schuetze",        name = "Schützenabzeichen – Schütze",        short = "SA I" },
    { id = "eocr_scharfschuetze",  name = "Schützenabzeichen – Scharfschütze",  short = "SA II" },
    { id = "eocr_meisterschuetze", name = "Schützenabzeichen – Meisterschütze", short = "SA III" },
}

-- Waffenkammer: Waffenklasse -> nötige Abzeichenstufe. Die Waffe muss in der Waffenkammer
-- (eoc_inventar_armory) ohnehin eingetragen sein; EoC Range blendet sie nur aus, solange die Stufe fehlt.
C.ArmoryLocks = {
    -- ["arccw_k_dc15x"] = 2,
}

---------------------------------------------------------------------------
-- DEFCON (eoc_defcon)
---------------------------------------------------------------------------
-- Ab dieser Stufe (und darunter) ist der Schießstand gesperrt. 0 = nie sperren.
C.DefconLockLevel = 2

---------------------------------------------------------------------------
-- Ranglisten
---------------------------------------------------------------------------
-- Wochen-Reset: Montag 04:00 Uhr (Serverzeit). Wochenwerte bleiben im Archiv.
C.WeekResetHour = 4
C.BoardCycle    = 12    -- Sekunden je Disziplin auf der Ranglisten-Wand

---------------------------------------------------------------------------
-- Silhouetten (Maße in Units: Breite, Höhe)
---------------------------------------------------------------------------
-- model = optionales Model statt der gezeichneten Silhouette (muss auf Server UND Client installiert sein,
-- sonst wird automatisch die gezeichnete Silhouette benutzt). Die Trefferbox bleibt w x h.
C.Silhouettes = {
    { id = "b1",    name = "B1-Kampfdroide",  w = 24, h = 76, model = "models/player/hydro/b1_battledroids/assault/b1_battledroid_assault.mdl" },
    { id = "b2",    name = "B2-Superdroide",  w = 36, h = 82 },
    { id = "bx",    name = "BX-Kommandodroide", w = 24, h = 76 },
}
C.HostageSilhouette = { id = "clone", name = "Klon", w = 24, h = 72 }

-- Idle-Animation für Ziel-Models (die erste vorhandene wird abgespielt)
C.TargetIdleSequences = { "idle_all_01", "idle_passive", "idle_ar2", "idle_all_02", "idle" }

-- Ringscheibe: halbe Kantenlänge je Größe
C.TargetSizes = { 10, 15, 22 }

---------------------------------------------------------------------------
-- Models (das erste gültige wird benutzt)
---------------------------------------------------------------------------
C.Models = {
    terminal = {
        "models/kingpommes/starwars/misc/bridge_console4.mdl",
        "models/lordtrilobite/starwars/props/kiosk_terminal.mdl",
        "models/props_lab/reciever_cart.mdl",
    },
}

---------------------------------------------------------------------------
-- Darstellung
---------------------------------------------------------------------------
C.HoloDistance       = 700
C.HoloDetailDistance = 380
C.BoardDistance      = 2000
C.ChatPrefix         = "[EoC] "
C.ChatPrefixColor    = Color(255, 170, 0)   -- wie der EoC-Announcer

C.Sounds = {
    countdown = "buttons/blip1.wav",
    go        = "buttons/button17.wav",
    hit       = "physics/metal/metal_solid_impact_bullet2.wav",
    hostage   = "buttons/button10.wav",
    best      = "buttons/button9.wav",
    abort     = "buttons/button8.wav",
    popup     = "doors/door_metal_thin_close2.wav",
}

---------------------------------------------------------------------------
-- Datenbank
---------------------------------------------------------------------------
-- Standard: SQLite (sv.db). MySQL nur mit installiertem mysqloo, wie beim Navy-System.
C.MySQL = {
    Enabled  = false,
    Host     = "127.0.0.1",
    Port     = 3306,
    User     = "root",
    Password = "",
    Database = "eoc",
}
