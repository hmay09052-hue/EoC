--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Einstellungen

    Alles, was hier steht, wird beim Serverstart gelesen. Nach Aenderungen den Server neu starten.
    Jobs werden ueber den DarkRP-Befehl (TEAM.command, z.B. "shocktrooper") ODER den Jobnamen erkannt.
-------------------------------------------------------------------------------------------------------------]]

GAR_DP = GAR_DP or {}

GAR_DP.Config = {
    ---------------------------------------------------------------------------------------------------------
    -- Datapad (Waffe)
    ---------------------------------------------------------------------------------------------------------
    -- Das Datapad bekommt nur, wer es als Job-Waffe hat: in jobs.lua bei weapons "gar_datapad" eintragen.
    WeaponSlot = 1,                 -- Slot in der Waffenauswahl (0 = erster Slot)
    WeaponAfterClose = "keys",      -- Waffe nach dem Schliessen, falls die vorherige nicht mehr da ist
    ThirdPersonFix = true,          -- Simple Thirdperson beim Oeffnen kurz ausschalten (Bildschirm ist sonst nicht sichtbar)
    WorkshopContent = true,         -- Modelle von Easzy's Tablet (Workshop 2526015939) an Spieler verteilen

    ---------------------------------------------------------------------------------------------------------
    -- Design
    ---------------------------------------------------------------------------------------------------------
    Theme = {
        accent = Color(70, 200, 255),       -- Holo-Cyan (Linien, aktive Elemente)
        warm = Color(255, 176, 64),         -- Bernstein (Hinweise)
        danger = Color(235, 70, 70),        -- Rot (gesperrt, Fahndung)
        ok = Color(90, 220, 140),           -- Gruen (online, gespeichert)
    },
    -- Schriften (Familiennamen der TTF-Dateien). Aurebesh wird ueber SymChars als Bild gezeichnet und
    -- braucht deshalb keine installierte Schrift.
    Fonts = { head = "BigNoodleTitling", body = "Roboto Condensed", mono = "Courier New" },
    -- Workshop-Addons mit Schriften, die Spieler beim Beitritt laden sollen (IDs als Text), z.B. { "1234567890" }
    FontWorkshop = {},

    -- Diese Usergroups haben immer Stufe 6 und sehen den Bereich "Freigaben"
    AdminGroups = { superadmin = true, admin = true },

    ---------------------------------------------------------------------------------------------------------
    -- Zugriff ueber DarkRP-Jobs
    ---------------------------------------------------------------------------------------------------------
    -- Strafakten: NUR diese Jobs (auch Admins nicht, ausser PenalAdminAccess = true)
    ShockJobs = {
        "st_pvt", "st_pfc", "st_spc", "st_lcpl", "st_cpl", "st_ccpl", "st_fcpl", "st_sgt", "st_fsgt", "st_sgm", "st_lt",
        "st_foxoffizier", "st_thornoffizier",
        "stk9_pvt", "stk9_pfc", "stk9_spc", "stk9_lcpl", "stk9_cpl", "stk9_ccpl", "stk9_fcpl", "stk9_sgt", "stk9_fsgt",
        "stk9_sgm", "stk9_hound",
    },
    PenalAdminAccess = false,
    -- Ab dieser Stufe duerfen Schocktruppen Strafakten loeschen
    PenalDeleteLevel = 4,

    ---------------------------------------------------------------------------------------------------------
    -- Sicherheitsstufen
    ---------------------------------------------------------------------------------------------------------
    Levels = {
        { name = "Normale Soldatendaten",       color = Color(150, 160, 170) },
        { name = "Einheiteninformationen",      color = Color(95, 200, 120) },
        { name = "Einsatzberichte",             color = Color(80, 170, 230) },
        { name = "Geheimdienstinformationen",   color = Color(240, 200, 80) },
        { name = "Jedi-/GAR-Klassifiziert",     color = Color(235, 130, 50) },
        { name = "Oberkommando",                color = Color(205, 62, 56) },
    },

    -- Stufe ueber den Rang (Rang 1 = niedrigster Rang der Einheit, wie in symchars).
    -- "rank" darf eine Zahl ODER ein Rangname sein (z.B. "Sergeant"). Es gilt die hoechste passende Zeile.
    ClearanceByRank = {
        { rank = 1,  level = 1 },
        { rank = 5,  level = 2 },
        { rank = 8,  level = 3 },
        { rank = 11, level = 4 },
        { rank = 14, level = 5 },
    },

    -- Eigene Regeln fuer bestimmte Einheiten (symchars uniqueID). Gilt auch fuer deren Untereinheiten.
    -- Hat eine Einheit keine eigene Regel, gilt ClearanceByRank.
    ClearanceByUnit = {
        -- ["501st"] = { { rank = 1, level = 1 }, { rank = "Sergeant", level = 2 }, { rank = "Lieutenant", level = 3 }, { rank = "Captain", level = 4 } },
        -- ["oberkommando"] = { { rank = 1, level = 5 }, { rank = "Admiral", level = 6 } },
    },

    -- Mindeststufe fuer bestimmte Jobs (Job-Befehl = Stufe)
    ClearanceByJob = {
        -- ["jedi_general"] = 5,
        -- ["jedi_knight"] = 5,
        -- ["shocktrooper"] = 2,
    },

    -- Ab dieser Stufe darf man anderen Charakteren eine Stufe von Hand geben (hoechstens die eigene)
    GrantMinLevel = 6,

    ---------------------------------------------------------------------------------------------------------
    -- Personalakten
    ---------------------------------------------------------------------------------------------------------
    PersonnelUnitLevel = 2,         -- Ab dieser Stufe: Akten der eigenen Einheit (inkl. Untereinheiten)
    PersonnelAllLevel = 3,          -- Ab dieser Stufe: Akten aller Einheiten
    PersonnelWriteLevel = 4,        -- Ab dieser Stufe Vermerke schreiben (sonst nur mit Befoerderungsrecht ueber die Person)
    PersonnelTypes = {
        { id = "belobigung", name = "Belobigung", color = Color(95, 200, 120) },
        { id = "vermerk",    name = "Vermerk",    color = Color(80, 170, 230) },
        { id = "verwarnung", name = "Verwarnung", color = Color(240, 160, 60) },
        { id = "disziplin",  name = "Disziplinarmassnahme", color = Color(205, 62, 56) },
    },

    ---------------------------------------------------------------------------------------------------------
    -- Strafakten: Kodex (wird beim Anlegen als Auswahl angeboten)
    ---------------------------------------------------------------------------------------------------------
    PenalStatus = {
        { id = "offen",       name = "Offen",       color = Color(240, 200, 80) },
        { id = "vollstreckt", name = "Vollstreckt", color = Color(95, 200, 120) },
        { id = "eingestellt", name = "Eingestellt", color = Color(150, 160, 170) },
    },
    Laws = {
        { id = "1.1", title = "Befehlsverweigerung",            punishment = "10 Min. Arrest",          text = "Verweigerung eines rechtmaessigen Befehls eines Vorgesetzten." },
        { id = "1.2", title = "Respektlosigkeit",               punishment = "Verwarnung",              text = "Respektloses Verhalten gegenueber Vorgesetzten oder Kameraden." },
        { id = "1.3", title = "Unerlaubtes Entfernen",          punishment = "15 Min. Arrest",          text = "Verlassen des Postens oder der Einheit ohne Erlaubnis." },
        { id = "2.1", title = "Unerlaubter Schusswaffengebrauch", punishment = "20 Min. Arrest",        text = "Abfeuern einer Waffe ohne Befehl oder Bedrohungslage." },
        { id = "2.2", title = "Koerperverletzung",              punishment = "30 Min. Arrest",          text = "Verletzung eines Angehoerigen der Republik." },
        { id = "2.3", title = "Mord an einem Kameraden",        punishment = "Exekution / Dekommission", text = "Toetung eines Angehoerigen der Republik." },
        { id = "3.1", title = "Diebstahl von Ausruestung",      punishment = "15 Min. Arrest",          text = "Entwendung von Ausruestung der GAR." },
        { id = "3.2", title = "Sachbeschaedigung",              punishment = "10 Min. Arrest",          text = "Mutwillige Beschaedigung von Eigentum der Republik." },
        { id = "4.1", title = "Geheimnisverrat",                punishment = "Dekommission",            text = "Weitergabe klassifizierter Informationen an Unbefugte." },
        { id = "4.2", title = "Hochverrat",                     punishment = "Exekution",               text = "Zusammenarbeit mit der Konfoederation unabhaengiger Systeme." },
        { id = "4.3", title = "Desertion",                      punishment = "Dekommission",            text = "Dauerhaftes Verlassen der Grossen Armee der Republik." },
        { id = "5.1", title = "Betreten von Sperrzonen",        punishment = "10 Min. Arrest",          text = "Betreten eines Bereichs ohne ausreichende Sicherheitsfreigabe." },
    },

    ---------------------------------------------------------------------------------------------------------
    -- Dienstberichte (level = Mindeststufe des Typs)
    ---------------------------------------------------------------------------------------------------------
    ReportTypes = {
        { id = "dienst",     name = "Dienstbericht",       level = 1 },
        { id = "patrouille", name = "Patrouillenbericht",  level = 1 },
        { id = "ausbildung", name = "Ausbildungsbericht",  level = 1 },
        { id = "einheit",    name = "Einheitenbericht",    level = 2 },
        { id = "einsatz",    name = "Einsatzbericht",      level = 3 },
        { id = "vorfall",    name = "Vorfallbericht",      level = 3 },
        { id = "geheim",     name = "Geheimdienstbericht", level = 4 },
    },
    ReportDeleteLevel = 5,          -- Ab dieser Stufe fremde Berichte loeschen

    ---------------------------------------------------------------------------------------------------------
    -- Klassifizierte Daten
    ---------------------------------------------------------------------------------------------------------
    ClassifiedCreateLevel = 3,      -- Ab dieser Stufe Dokumente anlegen (hoechstens mit der eigenen Stufe)
    ClassifiedCategories = { "Allgemein", "Aufklaerung", "Technologie", "Personen", "Operationen", "Jedi-Orden", "Oberkommando" },

    ---------------------------------------------------------------------------------------------------------
    -- Galaxiekarte
    ---------------------------------------------------------------------------------------------------------
    GalaxyEditLevel = 5,            -- Ab dieser Stufe die Lage (Kontrolle/Einsatzort) von Planeten setzen
    GalaxyStatus = {
        { id = "rep",     name = "Republik",        color = Color(80, 170, 230) },
        { id = "sep",     name = "Separatisten",    color = Color(205, 62, 56) },
        { id = "contest", name = "Umkaempft",       color = Color(240, 160, 60) },
        { id = "neutral", name = "Neutral",         color = Color(150, 160, 170) },
        { id = "einsatz", name = "Aktueller Einsatz", color = Color(95, 220, 130) },
    },
    -- Startlage zur Zeit der Klonkriege (kann ingame geaendert werden)
    GalaxyDefaults = {
        ["Coruscant"] = "rep", ["Kamino"] = "rep", ["Corellia"] = "rep", ["Alderaan"] = "rep", ["Naboo"] = "rep",
        ["Kashyyyk"] = "rep", ["Mon Calamari"] = "contest", ["Christophsis"] = "contest", ["Ryloth"] = "contest",
        ["Geonosis"] = "sep", ["Raxus"] = "sep", ["Serenno"] = "sep", ["Mustafar"] = "sep", ["Utapau"] = "contest",
        ["Felucia"] = "contest", ["Umbara"] = "sep", ["Muunilinst"] = "sep", ["Saleucami"] = "contest",
        ["Cato Neimoidia"] = "sep", ["Skako"] = "sep", ["Hypori"] = "sep", ["Mygeeto"] = "contest",
        ["Tatooine"] = "neutral", ["Nal Hutta & Nar Shaddaa"] = "neutral", ["Mandalore"] = "neutral", ["Kessel"] = "neutral",
        ["Dathomir"] = "neutral", ["Lothal"] = "neutral", ["Anaxes"] = "rep", ["Kuat"] = "rep", ["Rishi"] = "rep",
    },
    -- Diese Planeten werden immer beschriftet
    KeyPlanets = {
        "Coruscant", "Kamino", "Geonosis", "Tatooine", "Naboo", "Alderaan", "Corellia", "Kashyyyk", "Mustafar",
        "Utapau", "Felucia", "Mygeeto", "Saleucami", "Cato Neimoidia", "Ryloth", "Christophsis", "Umbara",
        "Mon Calamari", "Dathomir", "Mandalore", "Serenno", "Raxus", "Lothal", "Kessel", "Nal Hutta & Nar Shaddaa", "Hoth",
        "Dagobah", "Bespin", "Endor", "Jakku", "Kuat", "Anaxes", "Rishi", "Onderon & Dxun", "Ord Mantell", "Muunilinst",
        "Hypori", "Skako", "Bothawui", "Rodia", "Ilum", "Lola Sayu", "Ringo Vinda", "Abregado-rae", "Scarif",
    },
}
