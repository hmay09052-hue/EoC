--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - TAB-Menü: Einstellungen
-------------------------------------------------------------------------------------------------------------]]

EOCSB = EOCSB or {}
EOCSB.Config = EOCSB.Config or {}

local CFG = EOCSB.Config

---------------------------------------------------------------------------------------------------------------
-- Allgemein
---------------------------------------------------------------------------------------------------------------
-- Server-Logo oben in der Mitte. Das Echoes-of-Clones-Logo ist eingebaut (cl_logo.lua) und braucht keinen Download.
-- Anderes Logo: direkten https-Link zu einem PNG eintragen (z.B. https://i.imgur.com/xxxx.png), leer = eingebautes Logo
CFG.LogoURL = ""
CFG.Blur = true                                -- Hintergrund unscharf (ein einziger Blur)
CFG.DarkOverlay = 215                          -- 0-255 gleichmäßige Abdunklung des Hintergrunds

-- Farben, Schriften und Formen kommen aus SymChars (Einstellungen > Design, Akzentfarbe).

---------------------------------------------------------------------------------------------------------------
-- Ränge (wie auf der Rangtafel). Reihenfolge = von oben nach unten, die Farbe zeigt die Rangstufe.
-- Der Rang kommt aus SymChars. Hat ein Spieler keinen SymChars-Rang, wird der Rang im DarkRP-Jobnamen gesucht
-- (z.B. "501st | Sergeant Major" -> Sergeant Major). Weitere Schreibweisen: { "Name", "Alias1", "Alias2" }
---------------------------------------------------------------------------------------------------------------
local PURPLE, RED, YELLOW, GREEN = Color(150, 80, 255), Color(255, 60, 60), Color(255, 225, 40), Color(60, 230, 90)

CFG.RankBranches = {
    {
        id = "army", name = "Militär",
        ranks = {
            { "General", PURPLE },
            { "Marshal Commander", PURPLE },
            { "Senior Commander", PURPLE },
            { "Commander", PURPLE },
            { "Captain", PURPLE },
            { "First Lieutenant", RED },
            { "Lieutenant", RED },
            { "Sergeant Major", YELLOW },
            { "First Sergeant", YELLOW },
            { "Sergeant", YELLOW },
            { "First Corporal", GREEN },
            { "Chief Corporal", GREEN },
            { "Corporal", GREEN },
            { "Lance Corporal", GREEN },
            { "Specialist", GREEN },
            { "Private First Class", GREEN },
            { "Private", GREEN },
        },
    },
    {
        id = "navy", name = "Navy",
        match = { "Navy" },   -- Einheit oder Job mit diesem Text -> Navy-Ränge zuerst prüfen
        ranks = {
            { "Fleet Admiral", PURPLE },
            { "Admiral", PURPLE },
            { "Vize Admiral", PURPLE, "Vize Amiral", "Vice Admiral" },
            { "Captain", PURPLE },
            { "Commander", PURPLE },
            { "Lieutenant Commander", PURPLE },
            { "Lieutenant", RED },
            { "Sub Lieutenant", RED },
            { "Chief Warrant Officer", YELLOW },
            { "Senior Warrant Officer", YELLOW },
            { "Warrant Officer", YELLOW },
            { "Chief Petty Officer", GREEN },
            { "Senior Petty Officer", GREEN },
            { "Petty Officer", GREEN },
            { "Crewman", GREEN },
        },
    },
}

-- true = Maus ist beim Öffnen sofort frei (Klick auf Spieler / Officer-Posten möglich)
CFG.MouseOnOpen = true

-- Usergroups mit Admin-Rechten (Officer entfernen/ersetzen, Admin-Befehle im Rechtsklick-Menü)
CFG.AdminGroups = { "superadmin", "admin" }

-- Name der Gruppe für Spieler ohne SymChars-Einheit (sie werden darunter nach DarkRP-Job sortiert)
CFG.OtherGroupName = "Weitere Kräfte"

-- Ping rechts in der Zeile anzeigen
CFG.ShowPing = true

-- Admin-Menü (Klick auf einen Spieler). ULX, SAM, xAdmin, ServerGuard und FAdmin werden automatisch erkannt,
-- jeder Befehl erscheint nur, wenn man im Admin-Mod die Berechtigung dafür hat.
CFG.Commands = {
    { id = "goto",     name = "Hinteleportieren", color = Color(80, 160, 255) },
    { id = "bring",    name = "Herholen",         color = Color(80, 200, 120) },
    { id = "freeze",   name = "Einfrieren",       color = Color(100, 180, 255) },
    { id = "unfreeze", name = "Auftauen",         color = Color(200, 220, 255) },
    { id = "kick",     name = "Kicken",           color = Color(255, 180, 60) },
    { id = "ban",      name = "Bannen",           color = Color(230, 85, 85) },
    { id = "jail",     name = "Einsperren",       color = Color(200, 160, 80) },
    { id = "slay",     name = "Töten",            color = Color(220, 60, 60) },
    { id = "gag",      name = "Voice sperren",    color = Color(200, 120, 255) },
    { id = "strip",    name = "Waffen abnehmen",  color = Color(180, 160, 100) },
    { id = "god",      name = "Godmode",          color = Color(255, 220, 80) },
    { id = "spectate", name = "Beobachten",       color = Color(100, 200, 255) },
    { id = "slap",     name = "Schlagen",         color = Color(255, 150, 80) },
}

---------------------------------------------------------------------------------------------------------------
-- Informationen (rechte Spalte)
---------------------------------------------------------------------------------------------------------------
CFG.DefaultLocation = "Venator - Hangar"       -- Aktueller Standort beim Serverstart (wird gespeichert)
CFG.LocationCommand = "/standort"              -- /standort Felucia  -> setzt den Standort
CFG.LocationGroups = { "superadmin", "admin", "moderator" } -- wer den Standort setzen darf (zusätzlich alle Officer)
CFG.OfficersCanSetLocation = true

CFG.GalacticYear = "22 VSY"                    -- steht vor der Uhrzeit: "22 VSY · 21:43"

-- Sicherheitssoldaten: gezählt werden Spieler in diesen SymChars-Einheiten (uniqueID, inkl. Untereinheiten)
-- ODER mit einem Job, dessen Name diesen Text enthält
CFG.SecurityUnits = {}
CFG.SecurityJobs = { "Schocktruppen" }

---------------------------------------------------------------------------------------------------------------
-- Officer-System (/officer)
---------------------------------------------------------------------------------------------------------------
-- Jeder Posten kann nur von einem Spieler gleichzeitig besetzt sein und jeder Spieler hat höchstens einen Posten.
-- Die id nicht ändern (name/short/color/Regeln schon).
--
-- Wer einen Posten nehmen darf (eine Regel reicht, leer = alle):
--   minRank = SymChars-Rangname. Erlaubt ab diesem Rang aufwärts in der eigenen Einheit
--             (genau wie "Rechte ab Rang" in SymChars). Hat die Einheit keinen Rang mit dem Namen, zählt die Regel nicht.
--   units   = SymChars-Einheiten (uniqueID), Untereinheiten zählen mit
--   jobs    = Text, der im DarkRP-Jobnamen vorkommen muss (Groß/Klein beachten)
-- hint = kurzer Hinweis im Menü, wer den Posten nehmen kann.

local JOBS_CPL_PLUS = {
    "| Corporal", "| Chief Corporal", "| First Corporal",
}
local JOBS_SGT_PLUS = {
    "| Sergeant", "| First Sergeant", "| Sergeant Major",
    "| Lieutenant", "| First Lieutenant", "| Captain",
    "501st | Rex", "Schocktruppen | Fox", "Schocktruppen | Thorn",
    "Schocktruppen K9 | Hound", "501st | Coric",
    "Republic Navy | Commander", "Republic Navy | Vize Admiral",
    "Republic Navy | Admiral", "Republic Navy | Fleet Admiral",
}
for _, j in ipairs(JOBS_SGT_PLUS) do JOBS_CPL_PLUS[#JOBS_CPL_PLUS + 1] = j end

CFG.OfficerRanks = {
    { id = "co", name = "Commanding Officer",     short = "CO", color = Color(255, 190, 50),
      hint = "Sergeant+", minRank = "Sergeant", jobs = JOBS_SGT_PLUS },
    { id = "xo", name = "Executive Officer",      short = "XO", color = Color(230, 140, 60),
      hint = "Corporal+", minRank = "Corporal", jobs = JOBS_CPL_PLUS },
    { id = "ao", name = "Administrative Officer", short = "AO", color = Color(120, 170, 255),
      hint = "Republic Navy", jobs = { "Republic Navy" } },
    { id = "so", name = "Security Officer",       short = "SO", color = Color(225, 80, 80),
      hint = "Schocktruppen", jobs = { "Schocktruppen" } },
    { id = "mo", name = "Medical Officer",        short = "MO", color = Color(90, 210, 130),
      hint = "Medics", jobs = { "Medical Platoon", "501st | Kix", "501st | Coric" } },
    { id = "to", name = "Technical Officer",      short = "TO", color = Color(190, 140, 255),
      hint = "Engineering", jobs = { "Engineering Platoon" } },
}

-- Chatnachricht + Sound an alle, wenn jemand einen Posten übernimmt/abgibt (announce = false am Posten schaltet es ab)
CFG.OfficerAnnounceSound = "ambient/alarms/warningbell1.wav"

-- Chatbefehle für das Officer-Menü
CFG.OfficerChatCommands = { "/officer", "!officer" }

-- true  = Spieler können sich selbst und andere (mit passendem Rang/Job) in FREIE Posten eintragen.
--         Ersetzen/Entfernen anderer ist nur für Admins.
-- false = nur Admins tragen ein.
CFG.OfficerSelfAssign = true

-- Usergroups, die das Menü zum Eintragen nutzen dürfen (leer = alle)
CFG.OfficerAllowedGroups = {}

-- Admins dürfen jeden auf jeden Posten setzen (Regeln oben werden ignoriert)
CFG.OfficerAdminIgnoresJobs = true

-- true = Officer verliert den Posten bei Job-/Rang-/Einheitswechsel, wenn er die Regel nicht mehr erfüllt
CFG.OfficerRemoveOnJobChange = false

---------------------------------------------------------------------------------------------------------------
-- Texte
---------------------------------------------------------------------------------------------------------------
CFG.Lang = {
    page_title = "Übersicht  /  Truppenliste",
    command = "Kommandostruktur",
    command_kicker = "Führung",
    info = "Informationen",
    info_kicker = "Lagebericht",
    list = "Truppenliste",
    list_kicker = "Personalübersicht",
    list_online = "Soldaten im Einsatz",
    list_hint = "Klick auf einen Soldaten für Optionen",
    soldiers = "Soldaten",
    defcon = "Alarmstufe",
    online = "Online",
    cmd_kicker = "Soldatenakte",
    cmd_admin = "Admin",
    cmd_officer = "Officer",
    cmd_general = "Allgemein",
    vacant = "- / -",
    defcon_unknown = "KEIN STATUS",
    location = "Aktueller Standort",
    time = "Galaktische Standardzeit (GSZ)",
    troops = "Truppenstärke",
    security = "Sicherheitssoldaten",
    optime = "Einsatzzeit",
    manage = "Officer verwalten",

    officer_tag = "Officer",
    officer_is_now = "ist jetzt",
    officer_no_longer = "ist nicht mehr",
    officer_title = "OFFICER-POSTEN",
    officer_sub = "Kommandostruktur der Einheit",
    officer_players = "Soldaten",
    officer_posts = "Posten",
    officer_vacant = "Unbesetzt",
    officer_offline = "offline",
    officer_hint = "Soldat links auswählen, um ihn einzutragen",
    btn_join = "ÜBERNEHMEN",
    btn_leave = "ABGEBEN",
    btn_assign = "EINTRAGEN",
    btn_remove = "ENTFERNEN",
}
