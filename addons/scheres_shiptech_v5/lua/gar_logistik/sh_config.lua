--[[
    GAR Logistik – Kriegslogistik & Feldbasen (Echoes of Clones)
    Konfiguration

    Kreislauf:
      Produktion -> Zentrallager -> (Shuttle) -> Venator-Lager -> (Container / Shuttle) -> Feldbasis
      Navy & Kommando genehmigen Anträge, Logistik stellt Fracht zusammen,
      Piloten fliegen Container, Techniker & Medics verbrauchen und fordern nach.
]]

GARLog = GARLog or {}
GARLog.Config = GARLog.Config or {}
local C = GARLog.Config

---------------------------------------------------------------------------
-- Allgemein
---------------------------------------------------------------------------
C.ChatTag      = "[LOGISTIK]"
C.AdminGroups  = { superadmin = true, admin = true }   -- dürfen alles (+ Admin-Funktionen)
C.NotifyAdmins = false   -- Admins bekommen alle Rollen-Benachrichtigungen (Spam!)

C.TickInterval = 1       -- Zentraler Server-Takt in Sekunden (nicht unter 0.5 setzen)
C.SyncInterval = 0.75    -- Wie oft offene Datapads höchstens aktualisiert werden (Sekunden)
C.SaveInterval = 30      -- Speichern der Daten in SQLite (Sekunden)
C.LogSize      = 200     -- Einträge im Logistik-Protokoll
C.HistorySize  = 60      -- Erledigte Anträge / Transporte / Reparaturen, die behalten werden
C.ServerConsoleLog = false

-- EIN Werkzeug für alles: Logistik, Feldbasis bauen/reparieren, Schiffe & Fahrzeuge
-- reparieren (Fusion-Cutter-Protokoll) und Technik-Kontrollterminal.
--   LMB auf Schiff/Fahrzeug  -> Fusion-Cutter-Reparaturprotokoll
--   LMB halten auf Baustelle -> bauen / beschädigte Struktur reparieren
--   LMB sonst                -> Logistik
--   RMB                      -> Bauplanung (auf Struktur: abbauen)
--   R                        -> Technik-Kontrollterminal
C.DatapadClass = "weapon_garlog_datapad"
C.DatapadModel = "models/lt_c/sci_fi/holo_tablet.mdl"

---------------------------------------------------------------------------
-- Ressourcen
-- volume = Frachteinheiten (FE) pro Einheit (Container- & Shuttle-Kapazität)
---------------------------------------------------------------------------
-- Die 7 Hauptgüter (ammo, med, tech, fuel, food, build, special) bleiben für Depot, Generator, Medbay,
-- Technikerstation und bestehende Spielstände erhalten. Dazu kommen die feineren Güter je Lager.
C.Resources = {
    -- Munitionslager
    { id = "ammo",        name = "Blastermunition",  short = "MUN", storage = "Munitionslager",      color = Color(252, 178,  73), volume = 1 },
    { id = "heavy",       name = "Schwere Waffen",   short = "SWM", storage = "Munitionslager",      color = Color(240, 150,  60), volume = 2 },
    { id = "rocket",      name = "Raketen",          short = "RAK", storage = "Munitionslager",      color = Color(235, 120,  60), volume = 3 },
    { id = "torpedo",     name = "Torpedos",         short = "TRP", storage = "Munitionslager",      color = Color(220,  95,  60), volume = 5 },
    { id = "turret",      name = "Geschützmunition", short = "GSM", storage = "Munitionslager",      color = Color(245, 200,  90), volume = 2 },
    -- Medizinisches Lager
    { id = "med",         name = "Medkits",          short = "MED", storage = "Medizinisches Lager", color = Color(205,  62,  56), volume = 1 },
    -- Technisches Lager (Technikerstation)
    { id = "tech",        name = "Ersatzteile",      short = "TEC", storage = "Technisches Lager",   color = Color( 80, 170, 230), volume = 1 },
    { id = "fuse",        name = "Sicherungen",      short = "SIC", storage = "Technisches Lager",   color = Color(110, 190, 240), volume = 1 },
    { id = "cable",       name = "Leitungen",        short = "LTG", storage = "Technisches Lager",   color = Color( 70, 150, 210), volume = 1 },
    { id = "coolant",     name = "Kühlmittel",       short = "KMT", storage = "Technisches Lager",   color = Color( 64, 196, 255), volume = 1 },
    { id = "module",      name = "Ersatzmodule",     short = "MOD", storage = "Technisches Lager",   color = Color( 90, 130, 220), volume = 2 },
    { id = "electronics", name = "Elektronik",       short = "ELK", storage = "Technisches Lager",   color = Color(120, 160, 255), volume = 1 },
    { id = "tools",       name = "Werkzeug",         short = "WKZ", storage = "Technisches Lager",   color = Color(150, 170, 190), volume = 2 },
    { id = "hull",        name = "Hüllenplatten",    short = "HPL", storage = "Technisches Lager",   color = Color(170, 180, 195), volume = 4 },
    -- Treibstofflager
    { id = "fuel",        name = "Treibstoff",       short = "TRB", storage = "Treibstofflager",     color = Color(240, 140,  60), volume = 1 },
    { id = "cells",       name = "Energiezellen",    short = "EZL", storage = "Treibstofflager",     color = Color(250, 220, 100), volume = 1 },
    -- Rationenlager (Versorgung)
    { id = "food",        name = "Rationen",         short = "RAT", storage = "Rationenlager",       color = Color( 95, 200, 120), volume = 1 },
    { id = "water",       name = "Wasser",           short = "H2O", storage = "Rationenlager",       color = Color( 90, 200, 210), volume = 1 },
    -- Material & Spezial
    { id = "build",       name = "Baumaterial",      short = "MAT", storage = "Materiallager",       color = Color(175, 180, 190), volume = 2 },
    { id = "special",     name = "Spezialgüter",     short = "SPZ", storage = "Speziallager",        color = Color(190, 120, 255), volume = 3 },
}

-- Diese Ressourcen bestimmen die Gesamt-Versorgungslage eines Standorts
C.KeyResources = { "ammo", "med", "tech", "fuel", "food", "water", "coolant" }

-- In der kompakten Standort-Übersicht angezeigt (alle Güter stehen in der Detailansicht)
C.OverviewResources = { "ammo", "turret", "med", "tech", "coolant", "fuel", "food", "water", "build" }

-- Kleine HUD-Anzeige, wenn man sich in einer Feldbasis befindet
C.FOBHud = true

-- Versorgungslage (Füllstand) -> Anzeige
C.SupplyStatus = {
    { min = 0.60, name = "STABIL",     color = Color( 74, 203, 130) },
    { min = 0.30, name = "ANGESPANNT", color = Color(255, 190,  50) },
    { min = 0.10, name = "KRITISCH",   color = Color(235, 135,  60) },
    { min = 0.00, name = "ERSCHÖPFT",  color = Color(225,  88,  88) },
}

---------------------------------------------------------------------------
-- Feste Standorte (Zentrallager & Flotte)
-- type = "central" (Zentrallager, Produktion) oder "ship" (Venator)
-- Feldbasen (FOBs) entstehen dynamisch im Spiel.
-- Auf der Map werden Standorte über "Logistik-Terminal" und "Frachtrampe"
-- (Spawnmenü -> GAR Logistik, nur Admins) verankert und automatisch gespeichert.
---------------------------------------------------------------------------
C.Locations = {
    {
        id = "central", name = "Zentrallager Coruscant", short = "ZL", type = "central",
        capacity = { ammo = 30000, heavy = 8000, rocket = 3000, torpedo = 1000, turret = 12000, med = 15000,
                     tech = 15000, fuse = 6000, cable = 6000, coolant = 12000, module = 2000, electronics = 5000, tools = 1500, hull = 2000,
                     fuel = 30000, cells = 8000, food = 25000, water = 25000, build = 25000, special = 5000 },
        start    = { ammo = 10000, heavy = 3000, rocket = 1000, torpedo =  300, turret =  4000, med =  5000,
                     tech =  5000, fuse = 2000, cable = 2000, coolant =  4000, module =  600, electronics = 1600, tools =  500, hull =  600,
                     fuel = 10000, cells = 3000, food =  8000, water =  8000, build =  8000, special = 1500 },
    },
    {
        id = "venator", name = "Venator 'Resolute'", short = "VEN", type = "ship",
        capacity = { ammo = 8000, heavy = 2000, rocket = 600, torpedo = 200, turret = 3000, med = 4000,
                     tech = 4000, fuse = 1500, cable = 1500, coolant = 3000, module = 400, electronics = 1200, tools = 300, hull = 400,
                     fuel = 12000, cells = 2000, food = 6000, water = 6000, build = 6000, special = 1500 },
        start    = { ammo = 3000, heavy =  800, rocket = 250, torpedo =  80, turret = 1500, med = 1500,
                     tech = 1500, fuse =  600, cable =  600, coolant = 1500, module = 150, electronics =  500, tools = 120, hull = 150,
                     fuel = 6000, cells =  900, food = 3000, water = 3000, build = 2000, special =  400 },
        upkeep   = { fuel = 10, water = 4 },   -- Grundverbrauch pro Versorgungstakt (Reaktor, Bereitschaft, Crew)
    },
    -- Weiteres Schiff:
    -- { id = "venator2", name = "Venator 'Negotiator'", short = "NEG", type = "ship", capacity = {...}, start = {...} },
}

C.DefaultShip = "venator"   -- Heimatschiff: Crew-Verbrauch & SSE-Ausrüstung auf der Map

-- SSE-Verbrauchsgüter, die NICHT zu einer Feldbasis gehören (z.B. Munitionskisten
-- auf dem Venator), ziehen ihren Verbrauch aus diesem Schiffslager.
C.ShipSSELink = { Enabled = true, Location = "venator" }

---------------------------------------------------------------------------
-- Verbrauch (Versorgungstakt)
---------------------------------------------------------------------------
C.Upkeep = {
    Interval      = 300,   -- Sekunden
    FoodPerPlayer = 1,     -- Rationen pro Spieler und Takt (FOB: Anwesende, Schiff: Crew)
    ShipCrew      = true,  -- Spieler außerhalb einer Feldbasis zählen als Crew des Heimatschiffs
}

---------------------------------------------------------------------------
-- Rollen
-- Erkennung über DarkRP-Jobnamen, Job-Kategorien, Usergroups oder
-- Schlüsselwörter im Jobnamen (Groß-/Kleinschreibung egal).
---------------------------------------------------------------------------
C.UseKeywords = true

local ENGINEER_JOBS = {
    "501st Engineering Platoon | Private",
    "501st Engineering Platoon | Private First Class",
    "501st Engineering Platoon | Specialist",
    "501st Engineering Platoon | Lance Corporal",
    "501st Engineering Platoon | Corporal",
    "501st Engineering Platoon | Chief Corporal",
    "501st Engineering Platoon | First Corporal",
    "501st Engineering Platoon | Sergeant",
    "501st Engineering Platoon | First Sergeant",
    "501st Engineering Platoon | Sergeant Major",
    "501st Engineering Platoon | Lieutenant",
}

local NAVY_JOBS = {
    "Republic Navy | Crewman",
    "Republic Navy | Petty Officer",
    "Republic Navy | Senior Petty Officer",
    "Republic Navy | Chief Petty Officer",
    "Republic Navy | Warrant Officer",
    "Republic Navy | Senior Warrant Officer",
    "Republic Navy | Chief Warrant Officer",
    "Republic Navy | Sub Lieutenant",
    "Republic Navy | Lieutenant",
    "Republic Navy | Lieutenant Commander",
    "Republic Navy | Commander",
    "Republic Navy | Captain",
    "Republic Navy | Vize Admiral",
    "Republic Navy | Admiral",
    "Republic Navy | Fleet Admiral",
}

local AVP_JOBS = {
    "Republic Navy AVP | Private",
    "Republic Navy AVP | Private First Class",
    "Republic Navy AVP | Specialist",
    "Republic Navy AVP | Lance Corporal",
    "Republic Navy AVP | Corporal",
    "Republic Navy AVP | Chief Corporal",
    "Republic Navy AVP | First Corporal",
    "Republic Navy AVP | Sergeant",
    "Republic Navy AVP | First Sergeant",
    "Republic Navy AVP | Sergeant Major",
}

-- Techniker, Navy und Piloten nur über die genauen Jobnamen (keine Schlüsselwörter / Kategorien),
-- damit kein anderer Job versehentlich dazugezählt wird (AVP liegt auch in der Kategorie "Republic Navy").
C.Roles = {
    logistik  = { name = "Logistik",  color = Color(255, 190,  50), jobs = {},            categories = { "Logistik" },         usergroups = {}, keywords = { "logist", "quartiermeister", "versorgung", "nachschub" } },
    navy      = { name = "Navy",      color = Color( 90, 170, 255), jobs = NAVY_JOBS,     categories = {},                     usergroups = {}, keywords = {} },
    kommando  = { name = "Kommando",  color = Color(190, 120, 255), jobs = {},            categories = { "Kommando", "Jedi" }, usergroups = {}, keywords = { "commander", "kommandant", "general", "marshal", "offizier", "jedi" } },
    techniker = { name = "Techniker", color = Color( 80, 200, 220), jobs = ENGINEER_JOBS, categories = {},                     usergroups = {}, keywords = {} },
    medic     = { name = "Sanitäter", color = Color(225,  88,  88), jobs = {},            categories = {},                     usergroups = {}, keywords = { "medic", "sani", "arzt", "doctor" } },
    pilot     = { name = "Pilot",     color = Color( 74, 203, 130), jobs = AVP_JOBS,      categories = {},                     usergroups = {}, keywords = {} },
}

-- Benachrichtigungen: Rundmeldungen (neue Anträge, Reparaturaufträge, Shuttle-Landungen, Rationen leer)
-- bekommen NUR Spieler mit einer dieser Rollen. Antworten auf eigene Aktionen bekommt weiterhin jeder.
C.NotifyRoles   = { techniker = true, navy = true, pilot = true }
-- Ausfälle in einer Feldbasis (Stromausfall, Struktur zerstört/einsatzbereit, Lager ausgefallen): nur Techniker
C.FOBAlertRoles = { techniker = true }

-- Eigene Prüfung (z.B. Rangsystem). Rückgabe true/false überschreibt, nil = normale Erkennung.
C.CustomRoleCheck = nil
-- C.CustomRoleCheck = function(ply, roleId)
--     if roleId == "kommando" and MRS and MRS.GetActiveRankData then ... end
-- end

-- Berechtigungen: Liste von Rollen-IDs, "*" = jeder. Admins dürfen immer alles.
C.Permissions = {
    ["view"]             = { "*" },                                       -- Datapad / Lage einsehen
    ["request.create"]   = { "*" },                                       -- Antrag für eine Feldbasis stellen
    ["request.fleet"]    = { "navy", "logistik" },                        -- Antrag für Schiff / Zentrallager stellen
    ["request.approve"]  = { "navy", "kommando" },                        -- Anträge genehmigen / ablehnen
    ["request.plan"]     = { "logistik" },                                -- Lieferung planen (Shuttle / Container)
    ["transport.create"] = { "logistik" },                                -- Shuttle direkt entsenden
    ["container.pack"]   = { "logistik" },                                -- Frachtcontainer packen
    ["container.unload"] = { "logistik", "pilot", "techniker", "kommando", "navy" },
    ["container.move"]   = { "logistik", "pilot", "techniker", "kommando", "navy" }, -- an Fahrzeug koppeln
    ["production"]       = { "logistik" },                                -- Produktionsaufträge
    ["repair.work"]      = { "techniker" },                               -- Reparaturaufträge annehmen
    ["repair.create"]    = { "techniker", "kommando", "navy", "logistik" },
    ["build"]            = { "techniker", "kommando" },                   -- In Feldbasis bauen / reparieren
    ["build.found"]      = { "techniker", "kommando" },                   -- Neue Feldbasis gründen
    ["build.dismantle"]  = { "techniker", "kommando" },                   -- Strukturen abbauen
    ["fob.manage"]       = { "kommando", "techniker" },                   -- Generator schalten, FOB umbenennen/auflösen
    ["repair.vehicle"]   = { "techniker" },                               -- Schiffe & Fahrzeuge reparieren (Fusion-Cutter)
    ["report.create"]    = { "techniker", "navy", "pilot", "kommando" },  -- Wartungsberichte / Schadensmeldungen schreiben
    ["report.manage"]    = { "kommando" },                                -- fremde Berichte bearbeiten / löschen
}

---------------------------------------------------------------------------
-- Technik: Schiffs- & Fahrzeugreparatur (Fusion-Cutter-Addon)
---------------------------------------------------------------------------
C.VehicleRepair = {
    UseFCR       = true,    -- Fusion-Cutter-Minispiel nutzen (falls das Addon installiert ist)
    CostPerHP    = 0.03,    -- Ersatzteile pro fehlendem HP (2000 HP fehlen = 60 TEC)
    RequireStock = true,    -- ohne genug Ersatzteile im Lager keine Reparatur
    AnchorRange  = 4000,    -- Lager in diesem Umkreis (Terminal/Frachtrampe) zahlt; sonst Feldbasis bzw. Heimatschiff
}

---------------------------------------------------------------------------
-- Technik: Wartungsberichte
---------------------------------------------------------------------------
C.Reports = {
    MaxStored   = 300,     -- ältere Berichte werden automatisch archiviert (gelöscht)
    TitleLength = 60,
    TextLength  = 900,     -- Befund / Maßnahmen
    NoteLength  = 300,
    MaxNotes    = 15,
    MaxParts    = 500,     -- Ersatzteile, die ein Bericht abbuchen darf
    AutoFromFCR = true,    -- erfolgreiche Fusion-Cutter-Reparaturen erzeugen automatisch einen Bericht
    Categories = {
        { id = "vehicle",   name = "Schiff / Fahrzeug" },
        { id = "structure", name = "Feldbasis-Struktur" },
        { id = "system",    name = "Schiffssystem" },
        { id = "equipment", name = "Ausrüstung" },
        { id = "other",     name = "Sonstiges" },
    },
    States = {
        { name = "EINSATZBEREIT",  color = Color( 74, 203, 130) },
        { name = "EINGESCHRÄNKT",  color = Color(255, 190,  50) },
        { name = "AUSSER BETRIEB", color = Color(225,  88,  88) },
        { name = "IN WARTUNG",     color = Color( 80, 200, 220) },
    },
}

---------------------------------------------------------------------------
-- Anträge
---------------------------------------------------------------------------
C.Requests = {
    MaxOpenPerLocation = 10,    -- offene Anträge pro Standort
    MaxVolume          = 6000,  -- FE pro Antrag
    NoteLength         = 200,
    FOBNeedsAntenna    = true,  -- Feldbasen können nur mit funktionierender Antenne anfordern
}

---------------------------------------------------------------------------
-- Shuttles (abstrakte Transporte mit Flugzeit)
---------------------------------------------------------------------------
C.Shuttle = {
    Count           = 3,      -- Anzahl Shuttles (gleichzeitige Transporte)
    Capacity        = 1200,   -- FE pro Flug
    ReturnFactor    = 0.6,    -- Rückflug = Flugzeit * Faktor (Shuttle danach wieder frei)
    FOBNeedsAntenna = true,   -- Landung in einer Feldbasis braucht das Leitsignal der Antenne
    HoldTime        = 120,    -- So lange kreist ein Shuttle ohne Leitsignal, dann Rückflug
    DefaultTime     = 120,
    FlightTime = {            -- Sekunden je Route ("von>nach")
        ["central>ship"] = 150, ["ship>central"] = 150,
        ["central>fob"]  = 240, ["fob>central"]  = 240,
        ["ship>fob"]     =  75, ["fob>ship"]     =  75,
        ["ship>ship"]    = 120, ["fob>fob"]      =  90,
    },
}

-- Automatische Schiffsversorgung: Ist KEIN Logistiker online, schickt das Zentrallager
-- selbstständig Shuttles zu Schiffen, deren Schlüssel-Ressourcen knapp werden.
-- Feldbasen werden nie automatisch versorgt (das bleibt RP).
C.AutoSupply = {
    Enabled              = true,
    OnlyWithoutLogistics = true,
    Interval             = 300,   -- Sekunden zwischen Prüfungen
    Threshold            = 0.25,  -- unter 25 % Füllstand ...
    FillTo               = 0.5,   -- ... bis 50 % auffüllen (begrenzt durch Shuttle-Kapazität)
}

---------------------------------------------------------------------------
-- Frachtcontainer (physisch, per LAAT / Fahrzeug transportieren)
---------------------------------------------------------------------------
C.Container = {
    Model       = "models/reizer_props/srsp/sci_fi/crate_04/crate_04.mdl",
    Fallback    = "models/props_junk/wood_crate002a.mdl",
    Capacity    = 600,    -- FE
    Mass        = 300,
    Health      = 1500,
    MaxActive   = 12,     -- Container gleichzeitig im Umlauf
    PackRange   = 1200,   -- Abstand zu Terminal / Frachtrampe / Feldbasis zum Packen
    UnloadRange = 650,    -- Abstand Container <-> Versorgungslager / Frachtrampe zum Entladen
    UnloadTime  = 4,      -- Sekunden
    AttachRange = 400,    -- Fahrzeug (LAAT, AT-TE, ...) in diesem Umkreis kann den Container ankoppeln
    AttachedMass = 30,    -- Masse während des Transports (damit Flugzeuge normal fliegen)
}

---------------------------------------------------------------------------
-- Produktion (Zentrallager)
---------------------------------------------------------------------------
C.Production = {
    Location   = "central",
    Lines      = 3,       -- Produktionslinien (parallel)
    MaxQueue   = 6,       -- Aufträge pro Linie
    MaxBatches = 10,      -- Chargen pro Auftrag
    Recipes = {           -- batch = Menge pro Charge, time = Sekunden, cost = Rohstoffe pro Charge
        ammo    = { batch = 400, time = 120, cost = { build = 30 } },
        heavy   = { batch = 120, time = 150, cost = { build = 30 } },
        rocket  = { batch =  40, time = 180, cost = { build = 40 } },
        torpedo = { batch =  10, time = 240, cost = { build = 60, electronics = 10 } },
        turret  = { batch = 200, time = 150, cost = { build = 40 } },
        fuse    = { batch = 150, time = 100, cost = { build = 10 } },
        cable   = { batch = 150, time = 100, cost = { build = 15 } },
        coolant = { batch = 300, time = 120, cost = {} },
        module  = { batch =  30, time = 200, cost = { build = 30, electronics = 10 } },
        electronics = { batch = 100, time = 160, cost = { build = 20 } },
        tools   = { batch =  30, time = 150, cost = { build = 25 } },
        hull    = { batch =  40, time = 200, cost = { build = 60 } },
        cells   = { batch = 200, time = 140, cost = { build = 10 } },
        water   = { batch = 500, time =  90, cost = {} },
        med     = { batch = 200, time = 150, cost = { build = 10 } },
        tech    = { batch = 200, time = 150, cost = { build = 40 } },
        fuel    = { batch = 500, time = 120, cost = {} },
        food    = { batch = 400, time = 100, cost = {} },
        build   = { batch = 300, time = 180, cost = {} },
        special = { batch =  60, time = 240, cost = { build = 40 } },
    },
    Passive = {           -- Grundversorgung
        Interval = 600,
        Amounts  = { ammo = 200, turret = 60, med = 100, tech = 100, fuse = 40, cable = 40, coolant = 80, electronics = 30,
                     fuel = 300, cells = 50, food = 250, water = 250, build = 300, special = 20 },
    },
}

---------------------------------------------------------------------------
-- Feldbasis
---------------------------------------------------------------------------
C.FOB = {
    Radius          = 2200,   -- Units (~42 m) um das erste Versorgungslager
    MinDistance     = 4500,   -- Mindestabstand zwischen zwei Feldbasen
    MaxFOBs         = 5,
    DisabledMaps    = {},     -- z.B. { ["rp_venator_extensive_v1_4"] = true }
    BuildRange      = 450,    -- Max. Abstand Spieler <-> Bauplatz
    WorkRange       = 140,    -- Reichweite Bauen / Reparieren mit dem Datapad
    MaxSlope        = 32,     -- Grad
    NameLength      = 24,
    InstantBuild    = false,  -- true = Baustellen sind sofort fertig
    TechnicianBonus = 2.0,    -- Bau-/Reparaturgeschwindigkeit für Techniker
    DismantleRefund = 0.5,    -- Rückerstattung beim Abbau fertiger Strukturen
    BaseCapacity    = { ammo = 100, heavy = 40, rocket = 20, turret = 0, med = 100, tech = 100, fuse = 40, cable = 40, coolant = 80,
                        module = 10, electronics = 30, tools = 20, hull = 0, fuel = 100, cells = 60, food = 100, water = 150, build = 300, special = 50 },
    -- Pionierpaket: wird eingelagert, sobald das erste Versorgungslager fertig ist
    -- (reicht für Generator + Antenne, danach muss die Logistik liefern). {} = nichts
    StartStock      = { build = 300, tech = 150, fuel = 120, food = 40 },

    TakeDamage        = true,
    PlayerDamageScale = 0.3,  -- Schaden durch Spieler (Friendly Fire abschwächen)
    BlastDamageScale  = 1.5,  -- Explosionsschaden
}

C.Repair = {
    Threshold     = 0.75,   -- unter diesem Zustand entsteht automatisch ein Reparaturauftrag
    Rate          = 40,     -- HP pro Sekunde (Grundwert)
    CostPerHP     = 0.05,   -- Ersatzteile pro HP (1000 HP = 50 TEC)
    OperationalAt = 0.5,    -- zerstörte Strukturen laufen ab diesem Zustand wieder
    VehicleRange  = 900,    -- LVS-Fahrzeuge in diesem Radius um eine Technikerstation reparierbar
    VehicleRate   = 1.0,
    VehicleCost   = 0.03,
}

---------------------------------------------------------------------------
-- Strukturen der Feldbasis
---------------------------------------------------------------------------
C.StructureOrder = { "storage", "generator", "antenna", "ammodepot", "medbay", "techstation" }

C.Structures = {
    storage = {
        class = "garlog_storage", name = "Versorgungslager",
        desc  = "Herz der Feldbasis. Erstes Lager gründet die FOB. Nimmt Container auf, jedes weitere Lager erhöht die Kapazität.",
        model = "models/reizer_props/srsp/sci_fi/armory_01/armory_01.mdl", fallback = "models/props_junk/wood_crate002a.mdl",
        health = 2000, buildTime = 45, max = 3, core = true,
        cost = { build = 200 },   -- erstes Lager (Gründung) ist kostenlos
        capacity = { ammo = 1500, heavy = 400, rocket = 150, torpedo = 0, turret = 0, med = 800, tech = 800, fuse = 300, cable = 300,
                     coolant = 500, module = 80, electronics = 200, tools = 100, hull = 60, fuel = 1500, cells = 400, food = 1000,
                     water = 1500, build = 1500, special = 300 },
    },
    generator = {
        class = "garlog_generator", name = "Generator",
        desc  = "Versorgt die Feldbasis mit Strom. Verbraucht Treibstoff, solange er läuft.",
        model = "models/props_vehicles/generatortrailer01.mdl", fallback = "models/props_c17/trappropeller_engine.mdl",
        health = 1000, buildTime = 30, max = 2,
        cost = { build = 150, tech = 50 },
        fuelPerMin = 4,
    },
    antenna = {
        class = "garlog_antenna", name = "Kommunikationsantenne",
        desc  = "Verbindung zur Flotte: Versorgungsanträge aus der FOB und Leitsignal für Shuttle-Landungen.",
        model = "models/props_rooftop/roof_dish001.mdl", fallback = "models/props_lab/reciever01b.mdl",
        health = 700, buildTime = 35, max = 1, needsPower = true,
        cost = { build = 120, tech = 80 },
    },
    ammodepot = {
        class = "garlog_ammodepot", name = "Munitionsdepot",
        desc  = "Munitionsausgabe für die Truppen. Verbraucht Munition aus dem Versorgungslager.",
        model = "models/reizer_props/srsp/sci_fi/crate_01/crate_01.mdl", fallback = "models/items/ammocrate_ar2.mdl",
        health = 1200, buildTime = 30, max = 2,
        cost = { build = 150 },
        refillClips = 4,      -- Reserve wird auf X Magazine aufgefüllt
        fallbackAmmo = 120,   -- Reserve für Waffen ohne Magazin
        roundsPerUnit = 20,   -- Schuss pro Einheit Munition
        cooldown = 1.5,
    },
    medbay = {
        class = "garlog_medbay", name = "Feld-Medbay",
        desc  = "Behandlung Verwundeter (E halten). Sanitäter füllen hier ihr Material auf (Shift + E).",
        model = "models/reizer_props/srsp/sci_fi/crate_03/crate_03.mdl", fallback = "models/props_combine/health_charger001.mdl",
        health = 1000, buildTime = 40, max = 2, needsPower = true,
        cost = { build = 150, med = 50, tech = 30 },
        healPerTick = 8, tickDelay = 0.4, medPerHP = 0.1,
        roleSupply = { role = "medic", weapons = { "weapon_medkit" }, cost = 15, cooldown = 30 },
    },
    techstation = {
        class = "garlog_techstation", name = "Technikerstation",
        desc  = "Plastoid-Reparatur (E halten), Reparatur von Fahrzeugen in der Nähe. Techniker füllen hier auf (Shift + E).",
        model = "models/reizer_props/srsp/sci_fi/console_02_1/console_02_1.mdl", fallback = "models/props_combine/suit_charger001.mdl",
        health = 1200, buildTime = 40, max = 1, needsPower = true,
        cost = { build = 150, tech = 80 },
        armorPerTick = 8, tickDelay = 0.4, techPerArmor = 0.1,
        roleSupply = { role = "techniker", weapons = {}, cost = 10, cooldown = 30 },
    },
}

---------------------------------------------------------------------------
-- SSE-Ausstattung für Feldbasen
-- model: "@Schlüssel" = Modell aus SSE.Config[Schlüssel].Model
-- power: braucht Strom der Feldbasis
---------------------------------------------------------------------------
C.SSE = {
    { class = "sse_box_ammo",       name = "Munitionskiste",        model = "@AmmoBox",            cost = { build = 40 },              time = 10, max = 3 },
    { class = "sse_box_heal",       name = "Med. Ressourcen",       model = "@Healbox",            cost = { build = 40, med = 20 },    time = 12, max = 2 },
    { class = "sse_box_food",       name = "Essenskiste",           model = "@Foodbox",            cost = { build = 30 },              time = 8,  max = 2 },
    { class = "sse_heal_canister",  name = "Medidroide",            model = "@HealCanister",       cost = { build = 30, tech = 20 },   time = 12, max = 2, power = true },
    { class = "sse_armor_canister", name = "Plastoiddroide",        model = "@ArmorCanister",      cost = { build = 30, tech = 20 },   time = 12, max = 2, power = true },
    { class = "sse_holotable",      name = "Holotisch",             model = "@Holotable",          cost = { build = 80, tech = 40 },   time = 25, max = 1, power = true },
    { class = "sse_battlepad",      name = "Gefechtstisch",         model = "@Battlepad",          cost = { build = 80, tech = 50 },   time = 25, max = 1, power = true },
    { class = "sse_liveradar",      name = "Radar",                 model = "@LiveScanner",        cost = { build = 60, tech = 60 },   time = 20, max = 1, power = true },
    { class = "sse_scanner",        name = "Scanner",               model = "@Scanner",            cost = { build = 60, tech = 60 },   time = 20, max = 1, power = true },
    { class = "sse_vehreq",         name = "Fahrzeugterminal",      model = "@VehicleRequisition", cost = { build = 80, tech = 60 },   time = 25, max = 1, power = true },
    { class = "sse_vehspawn",       name = "Fahrzeug-Landeplatz",   model = "models/maxofs2d/cube_tool.mdl", cost = { build = 60 }, time = 15, max = 3, platform = true },
    { class = "sse_broadcast",      name = "Ankündigungskonsole",   model = "@Broadcast",          cost = { build = 40, tech = 30 },   time = 15, max = 1, power = true },
    { class = "sse_weaponbox",      name = "Waffenkiste",           model = "models/lordtrilobite/starwars/props/kyber_crate_phys.mdl", cost = { build = 50, special = 10 }, time = 12, max = 1 },
    { class = "sse_restriced_area", name = "Sperrzonen-Schild",     model = "@RestrictedSign",     cost = { build = 10 },              time = 5,  max = 4 },
    { class = "sse_unitsign",       name = "Einheitsschild",        model = "models/reizer_props/alysseum_project/clones/misc_props/misc_stuff_01/misc_stuff_01.mdl", cost = { build = 10 }, time = 5, max = 2 },
}

-- Verbrauch der SSE-Entities (FOB-Lager bzw. Schiffslager)
-- measure: was gemessen wird, per: Effekt pro 1 Einheit Ressource
C.SSEConsume = {
    sse_box_ammo       = { res = "ammo", measure = "ammo",        per = 20 },
    sse_takebox_ammo   = { res = "ammo", measure = "ammo",        per = 20 },
    sse_box_heal       = { res = "med",  measure = "healtharmor", per = 10 },
    sse_heal_canister  = { res = "med",  measure = "health",      per = 10 },
    sse_armor_canister = { res = "tech", measure = "armor",       per = 10 },
    sse_box_food       = { res = "food", measure = "energy",      per = 10 },
}

---------------------------------------------------------------------------
-- Map-Entities
---------------------------------------------------------------------------
C.TerminalModel  = "models/reizer_props/srsp/sci_fi/console_02_2/console_02_2.mdl"
C.TerminalFallback = "models/props_combine/combine_interface001.mdl"
C.CargoPadModel  = "models/hunter/plates/plate3x3.mdl"

---------------------------------------------------------------------------
-- Sounds (Standard-HL2, auf jedem Server vorhanden)
---------------------------------------------------------------------------
C.Sounds = {
    Click     = "buttons/lightswitch2.wav",
    Error     = "buttons/button10.wav",
    Notify    = "buttons/button9.wav",
    Warn      = "buttons/button17.wav",
    Place     = "buttons/button14.wav",
    BuildTick = "physics/metal/metal_box_impact_soft2.wav",
    BuildDone = "buttons/button3.wav",
    Unload    = "items/ammocrate_open.wav",
    Ammo      = "items/ammo_pickup.wav",
    Heal      = "items/medshot4.wav",
    Armor     = "items/battery_pickup.wav",
    PowerOn   = "buttons/button1.wav",
    PowerOff  = "buttons/button18.wav",
    GeneratorLoop = "ambient/machines/combine_terminal_loop1.wav",
    Destroyed = "ambient/explosions/explode_4.wav",
}
