--[[
    ShipTech – KONFIGURATION
    Alles, was man als Serverbetreiber anpassen möchte, steht hier.
]]

ShipTech.Config = {}
local C = ShipTech.Config

---------------------------------------------------------------------------
-- Befehle
---------------------------------------------------------------------------
C.EventCommands = { "/event", "!event" }          -- öffnet das Event-Menü (nur Eventler)

---------------------------------------------------------------------------
-- Rechte
---------------------------------------------------------------------------
C.AdminGroups      = { superadmin = true, admin = true }
C.EventlerGroups   = { superadmin = true, admin = true, eventler = true, eventmanager = true, ["event-team"] = true }
C.InstructorGroups = { superadmin = true, admin = true }   -- dürfen Fortbildungen vergeben

-- Job-/Team-Namen (team.GetName), die als Techniker zählen. LEER = jeder darf als Techniker arbeiten.
-- Beispiel: C.TechnicianTeams = { ["Imperial Engineer"] = true, ["Imperial Engineer Officer"] = true }
C.TechnicianTeams = {}
-- Zusätzlich zählt jeder Job als Techniker, dessen Name einen dieser Begriffe enthält (Groß-/Kleinschreibung egal).
-- Nur Techniker (und Admins) können reparieren und bekommen Datapad + Feuerlöscher.
-- Beide Listen leer = jeder ist Techniker.
C.TechnicianTeamPatterns = { "techni", "engineer", "ingenieur", "mechani" }

-- Wer bekommt ShipTech-Meldungen im Chat (Ausfälle, Störungen, Aufträge, Reaktor, Alarme)?
-- Ist GAR Logistik installiert, gelten dessen Rollen (genaue Jobnamen aus der Logistik-Konfiguration).
-- Sonst: Jobs, deren Name einen der Begriffe enthält. Alle anderen Spieler bekommen keine Technik-Meldungen
-- (HUD-Alarme wie Evakuierung sieht trotzdem jeder).
C.Notify = {
    UseLogistikRoles = true,
    LogistikRoles    = { techniker = true, navy = true, pilot = true },
    JobPatterns      = { "Engineering Platoon", "Republic Navy" },   -- "Republic Navy" deckt auch "Republic Navy AVP" ab
    Admins           = false,                                       -- Admins zusätzlich (Spam!)
}

-- Navy-Erkennung über Namensbestandteile (zusätzlich zu C.NavyTeams und der Qualifikation "navy")
C.NavyTeamPatterns = { "Republic Navy |" }
-- Job-/Team-Namen, die automatisch Navy-Rechte haben (Startfreigaben, Gefechtsalarm, Notfallprotokolle).
-- Zusätzlich bekommt jeder mit der Qualifikation "navy" diese Rechte.
C.NavyTeams = {}

-- Qualifikationssystem (Fortbildungen). false = jeder Techniker darf alle Systeme warten.
C.UseQualifications = true
-- Qualifikationen, die jeder Techniker automatisch besitzt (können pro Spieler entzogen werden)
C.DefaultQuals = { "basis" }

---------------------------------------------------------------------------
-- Allgemeines Verhalten
---------------------------------------------------------------------------
C.FastTick       = 1        -- Sekunden: Energie, Temperatur, Schilde, Brände, Alarme
C.SlowTick       = 30       -- Sekunden: Verschleiß, Kalibrierung, Zufallsstörungen
C.AutoStart      = true     -- Reaktor & alle Systeme laufen beim Server-/Mapstart bereits (Checkliste erledigt)
C.AutoOrders     = true     -- automatisch Wartungsaufträge bei neuen Störungen erstellen
C.UseDistance    = 160      -- maximale Entfernung zur Konsole
C.HoloDistance   = 800      -- Sichtweite der Hologramme über den Konsolen
C.HoloDetailDistance = 380  -- volle Hologramm-Details nur so nah UND wenn man hinsieht
C.LogKeep        = 400      -- Protokolleinträge im Speicher (zusätzlich in data/shiptech/logs/)
C.ReportKeep     = 200
C.OrderKeep      = 60

---------------------------------------------------------------------------
-- Verschleiß & Störungen
---------------------------------------------------------------------------
C.MaintDecayPerMinute = 0.5     -- Wartungszustand sinkt pro Minute (laufendes System)
C.CalibDecayPerMinute = 0.35    -- Kalibrierung sinkt pro Minute (Geschütze / Sensoren)
C.WearBelowMaint      = 20      -- unter diesem Wartungszustand nimmt das System Schaden
C.WearPerMinute       = 2       -- Schaden pro Minute bei vernachlässigter Wartung
C.RandomFaults        = true    -- zufällige technische Störungen
C.RandomFaultBase     = 0.004   -- Grundchance pro System & Minute (steigt bei schlechter Wartung bis x5)

-- Anzahl Störungen je Schadensstufe (1 = beschädigt, 2 = kritisch, 3 = ausgefallen)
C.FaultCount    = { [1] = 1, [2] = 2, [3] = 3 }
-- Reparaturzeit (Sekunden) je Störung, abhängig von der Schadensstufe
C.RepairTime    = { [0] = 5, [1] = 6, [2] = 12, [3] = 20 }
-- Ersatzteile je behobener Störung, abhängig von der Schadensstufe
C.PartsPerFault = { [0] = 0, [1] = 0, [2] = 1, [3] = 2 }

C.SpareParts = {
    Start           = 12,
    Max             = 30,
    RequestAmount   = 8,     -- Lieferung pro Anforderung
    RequestDelay    = 90,    -- Sekunden bis zur Lieferung
    RequestCooldown = 600,   -- Sekunden zwischen Anforderungen
}

C.MaintenanceTime = 8       -- Dauer Routinewartung (nach dem Minigame)
C.CalibrationTime = 4
C.TestRunTime     = 6
C.DiagnoseTime    = 4

---------------------------------------------------------------------------
-- Minigames
---------------------------------------------------------------------------
C.MinigameTime      = 45     -- Zeitlimit in Sekunden
C.CombatTimeFactor  = 0.7    -- im Gefechtsalarm weniger Zeit (Zeitdruck)
C.MinigameMinTime   = 1.5    -- Anti-Exploit: schneller kann niemand fertig sein

---------------------------------------------------------------------------
-- Reaktor & Energie
---------------------------------------------------------------------------
C.ReactorScanSteps = { 10, 20, 30, 40, 50, 60, 70, 80, 90, 99, 100 }
C.ReactorScanDelay = 1.5    -- Sekunden zwischen den Scan-Meldungen

C.PowerBudget      = 100    -- Energieeinheiten des Reaktors bei 100 % Zustand
C.MaxAllocPerSystem = 40

-- Temperatur
C.HeatRate         = 1      -- Aufheizgeschwindigkeit aller Systeme (0.5 = halb so schnell)
C.HyperHeatFactor  = 1      -- zusätzlicher Faktor nur für den Hyperantrieb (0.5 = halb so schnell)

C.Backup = {
    Enabled           = true,
    Output            = 35,   -- Energieeinheiten im Notstrombetrieb (nur essentielle Systeme)
    DrainPerMinute    = 2,    -- Akku-Verbrauch pro Minute
    RechargePerMinute = 8,
}

---------------------------------------------------------------------------
-- Schilde
---------------------------------------------------------------------------
C.ShieldRegen    = 4        -- Regeneration pro Tick und Sektor bei 100 % Effizienz
C.ShieldDrainOff = 20       -- Abbau pro Tick wenn Schilde offline

---------------------------------------------------------------------------
-- Stromausfälle / Sektoren
---------------------------------------------------------------------------
C.BreakerRadius        = 700     -- Reichweite eines Sektor-Energieverteilers
C.GlobalBlackoutEffect = true    -- Bildschirm abdunkeln wenn das ganze Schiff ohne Strom ist


---------------------------------------------------------------------------
-- Werkzeug (Datapad) & Feuerlöscher
---------------------------------------------------------------------------
C.Tool = {
    Class       = "st_werkzeug",
    Name        = "Technisches Datapad",
    Required    = true,      -- Reparatur, Diagnose, Wartung, Kalibrierung nur mit Werkzeug in der Hand
    GiveOnSpawn = true,      -- Techniker bekommen das Werkzeug automatisch, alle anderen nicht
    ViewModel   = "models/swcw_items/sw_datapad_v.mdl",
    WorldModel  = "models/swcw_items/sw_datapad.mdl",
}
C.Extinguisher = {
    Class       = "st_loescher",
    GiveOnSpawn = true,
    Model       = "models/props/cs_office/fire_extinguisher.mdl",  -- wird in der Hand und in der Ego-Ansicht gezeichnet
    ViewOffset  = Vector(20, -9, -13),   -- Ego-Ansicht: vor / rechts(-) / oben
    ViewAngle   = Angle(0, 90, 0),
    WorldOffset = Vector(3, -2, -6),     -- in der Hand (relativ zum rechten Handknochen)
    WorldAngle  = Angle(0, 0, 180),
    Range       = 320,
    Power       = 0.06,      -- gelöschte Brandstärke pro Sprühstoß (0..1)
}

---------------------------------------------------------------------------
-- Brände
---------------------------------------------------------------------------
C.Fire = {
    Enabled          = true,
    ChanceOnCritical = 0.45,   -- Chance auf Brand, wenn ein System kritisch wird
    ChanceOnOverheat = 0.7,    -- Chance bei Sicherheitsabschaltung durch Überhitzung
    ChanceOnHullHit  = 0.25,   -- Chance bei Hüllentreffern
    GrowPerSecond    = 0.015,  -- Brand wächst pro Sekunde
    DamagePerMinute  = 6,      -- Systemschaden pro Minute bei voller Brandstärke
    PlayerDamage     = 3,      -- Schaden pro Sekunde an Spielern in der Nähe
    PlayerRadius     = 110,
    SpreadChance     = 0.004,  -- pro Sekunde bei voller Stärke auf eine Konsole in der Nähe
    SpreadRadius     = 500,
}

---------------------------------------------------------------------------
-- Kettenreaktionen
---------------------------------------------------------------------------
C.Chain = {
    Enabled        = true,
    FlickerChance  = 0.015,  -- pro Sekunde bei beschädigter Energieverteilung: ein System fällt kurz aus
    SurgeHeat      = 95,     -- Reaktortemperatur, ab der Überspannungen das Netz beschädigen
    SurgeChance    = 0.05,   -- pro Sekunde
}

---------------------------------------------------------------------------
-- Hyperraumsprung
---------------------------------------------------------------------------
C.Hyper = {
    CalcTime      = 25,     -- Sekunden Kursberechnung (länger bei schlechten Sensoren)
    MinSensors    = 0.4,    -- Mindesteffizienz der Sensoren für die Berechnung
    MinAlloc      = 25,     -- Energie für den Hyperantrieb, die vor dem Sprung umgeleitet sein muss
    MinEfficiency = 0.6,    -- Mindesteffizienz des Hyperantriebs
    Countdown     = 10,
}

---------------------------------------------------------------------------
-- Fahrzeug-Addons (LVS / LFS / Geschütz-Entities)
---------------------------------------------------------------------------
C.Vehicles = {
    Enabled           = true,
    ShipClasses       = {},    -- Entity-Klassen, die das Schiff darstellen: Schaden geht zuerst auf die Schilde
    GunClasses        = {},    -- Geschütz-/Turret-Klassen: Schaden hängt von Feuerbereitschaft & Zielgenauigkeit ab
    ShieldDamageScale = 0.05,  -- 1000 Fahrzeugschaden = 50 % Schild eines Sektors
    ScaleSpeed        = true,  -- MaxVelocity der ShipClasses an die Triebwerke koppeln
}

---------------------------------------------------------------------------
-- Militärisches Funksystem (crypto_radio)
---------------------------------------------------------------------------
C.CryptoRadio = {
    Enabled          = true,
    JamAtStage       = 2,    -- ab dieser Schadensstufe der Kommunikation sind Funksprüche gestört
    AntennaDownStage = 3,    -- ab dieser Stufe fällt der Langstreckenfunk aus
}

---------------------------------------------------------------------------
-- Beleuchtung (SSE Lightswitch aus sse_106, sonst eigene Map-Licht-Steuerung)
---------------------------------------------------------------------------
C.Lights = {
    Enabled          = true,
    OffOnBlackout    = true,   -- Licht aus bei Totalausfall der Energie
    OffOnGridFailure = true,   -- Licht aus, wenn die Energieverteilung ausgefallen ist
    Flicker          = true,   -- Licht flackert kurz bei Hüllentreffern
    FlickerCooldown  = 45,     -- Sekunden zwischen zwei Flacker-Effekten
    Fallback         = true,   -- ohne SSE: Map-Lichter (light, light_spot, light_dynamic) selbst schalten
}

---------------------------------------------------------------------------
-- Kommunikation: Diese Chat-Befehle sind bei Kommunikationsausfall blockiert
---------------------------------------------------------------------------
C.CommsBlockedCommands = { "/funk", "/radio", "/comms", "/r", "/com" }

---------------------------------------------------------------------------
-- Sounds
---------------------------------------------------------------------------
C.Sounds = {
    Alarm        = "ambient/alarms/klaxon1.wav",
    ReactorStart = "ambient/machines/thumper_startup1.wav",
    Shutdown     = "ambient/machines/thumper_shutdown1.wav",
    Spark        = "ambient/energy/spark5.wav",
    Hit          = "ambient/explosions/exp1.wav",
    ShieldHit    = "ambient/energy/zap9.wav",
    Success      = "buttons/button14.wav",
    Fail         = "buttons/button10.wav",
}
C.AlarmSoundInterval = 3.5
C.AlarmVolume        = 0.35

---------------------------------------------------------------------------
-- KÜHLKREISLÄUFE
-- Jeder Kreislauf hat einen Kühlmittel-Füllstand und Druck. Das Kühlsystem (Pumpen) treibt alle an.
-- Lecks (Störung "Kühlmittelleck") lassen den Kreislauf des betroffenen Systems leerlaufen.
---------------------------------------------------------------------------
ShipTech.Circuits = {
    { id = "reactor",    name = "Reaktorkühlung",       systems = { "reactor" } },
    { id = "engines",    name = "Triebwerkskühlung",    systems = { "engines" } },
    { id = "weapons",    name = "Waffen-/Turmkühlung",  systems = { "weapons" } },
    { id = "hyperdrive", name = "Hyperantriebskühlung", systems = { "hyperdrive" } },
    { id = "ship",       name = "Schiffskühlung",       systems = { "shields", "sensors", "comms", "coolant", "power" } },
}
C.Cooling = {
    EvaporatePerMinute = 0.15,  -- natürlicher Kühlmittelverlust (%)
    LeakPerMinute      = 2.5,   -- pro Kühlmittelleck am System des Kreislaufs (%)
    PumpLeakPerMinute  = 0.8,   -- pro Störung am Kühlsystem, in allen Kreisläufen (%)
    LowLevel           = 40,    -- darunter verliert der Kreislauf stark an Kühlleistung
    MaxPressure        = 100,   -- ab hier: Überdruck-Warnung, Sicherheitsventile öffnen
    RefillStep         = 25,    -- Nachfüllen in Schritten von x %
    RefillTime         = 5,
}

---------------------------------------------------------------------------
-- INSPEKTIONEN – einzelne Prüfschritte je System (Tool nötig, ca. 4 s)
-- Jeder Schritt hebt den Wartungszustand und kann versteckte Störungen aufdecken.
-- Überfällige Inspektionen erhöhen den Verschleiß.
---------------------------------------------------------------------------
ShipTech.Inspections = {
    reactor    = { "Reaktorkern überprüfen", "Energieausgabe kontrollieren", "Reaktordruck kontrollieren", "Sicherheitsventile testen", "Kühlkreislauf prüfen" },
    power      = { "Leitungen überprüfen", "Energieverteilung kontrollieren", "Sicherungen prüfen" },
    coolant    = { "Kühlkreislauf prüfen", "Pumpen prüfen", "Sicherheitsventile testen" },
    engines    = { "Triebwerkskühlung prüfen", "Schubdüsen prüfen", "Leitungen überprüfen" },
    hyperdrive = { "Hyperantriebskühlung prüfen", "Motivator prüfen", "Navigationsschnittstelle testen" },
    weapons    = { "Waffen-/Turmkühlung prüfen", "Ladesysteme prüfen", "Zielerfassung testen" },
    shields    = { "Emitter prüfen", "Generatorkühlung prüfen", "Leitungen überprüfen" },
    sensors    = { "Sensorphalanx testen", "Signalwege prüfen" },
    comms      = { "Relais prüfen", "Antennenverbindung testen" },
}
C.Inspection = {
    Time         = 4,      -- Sekunden je Prüfschritt
    MaintGain    = 8,      -- Wartungszustand + je Schritt
    RevealChance = 0.6,    -- Chance, eine unbekannte Störung aufzudecken
    Overdue      = 1800,   -- Sekunden – danach gilt ein Schritt als überfällig
}

-- VERSCHLEISS: Faktoren, die Wartungsverlust und Störungsrisiko erhöhen
C.Wear = {
    AgeHours     = 2,     -- je x Betriebsstunden seit der letzten Routinewartung +10 % Verschleiß
    LoadFactor   = 1.5,   -- Überlast (Energie über Normalwert)
    CombatFactor = 0.5,   -- Gefechtsalarm
    HeatFrom     = 70,    -- ab dieser Temperatur zusätzlicher Verschleiß
    PowerFactor  = 0.3,   -- instabile Energieversorgung (Versorgung unter 80 %)
    CoolFactor   = 0.5,   -- Kühlkreislauf unter dem Mindestfüllstand
    OverdueFactor = 0.25, -- je überfälliger Inspektion
    DamageFactor = 0.4,   -- Gefechtsschäden (je Schadensstufe)
    Max          = 4,
}
---------------------------------------------------------------------------
-- GAR LOGISTIK: Material für Reparaturen aus dem Schiffslager
---------------------------------------------------------------------------
C.Logistik = {
    Enabled     = true,          -- nur aktiv, wenn GAR Logistik installiert ist
    Location    = nil,           -- Lager-ID (nil = Heimatschiff der Logistik, z. B. "venator")
    RequestFrom = "central",     -- von wo Nachschub angefordert wird
    RequestPrio = 3,
    -- Material je Störungsart (wird mit der Schadensstufe multipliziert)
    FaultItems = {
        kurzschluss     = { fuse = 2, cable = 3 },
        kalibrierung    = { electronics = 2 },
        kuehlmittel     = { coolant = 15, tech = 1 },
        steuerung       = { electronics = 3 },
        energiekopplung = { module = 1, cable = 2 },
        mechanik        = { tech = 6, tools = 1 },
        default         = { tech = 4 },
    },
    StageFactor = { [0] = 1, [1] = 1, [2] = 2, [3] = 3 },
    -- Routinewartung je System
    MaintItems = {
        reactor    = { tech = 3, coolant = 10 },
        coolant    = { coolant = 20, tech = 1 },
        shields    = { electronics = 1, tech = 2 },
        weapons    = { tech = 3 },
        engines    = { tech = 3, coolant = 5 },
        hyperdrive = { electronics = 2, tech = 2 },
        power      = { fuse = 2, cable = 2 },
        default    = { tech = 2 },
    },
    CalibItems = { electronics = 1 },
    -- Kühlmittel zum Nachfüllen eines Kühlkreislaufs (pro 10 % Füllstand)
    CoolantPer10 = 6,
    -- Antrag "Ersatzteile anfordern"
    RequestItems = { tech = 200, fuse = 80, cable = 80, coolant = 300, module = 20, electronics = 60, tools = 10 },
    -- im ShipTech-Terminal angezeigte Güter
    ShownItems = { "tech", "fuse", "cable", "coolant", "module", "electronics", "tools", "hull", "cells" },
}
---------------------------------------------------------------------------
-- SYSTEME
-- nominal   = Standard-Energiezuteilung (Summe = 100)
-- essential = wird im Notstrombetrieb weiter versorgt
-- navy      = braucht eine Startfreigabe der Navy
-- calib     = besitzt einen Kalibrierungswert
-- maintGame = Minigame für die Routinewartung
-- faults    = mögliche Störungsarten
---------------------------------------------------------------------------
ShipTech.Systems = {
    { id = "reactor",    name = "Reaktor",           qual = "reaktor",      nominal = 0,  essential = true, maintGame = "valves",
      desc = "Hauptenergiequelle des Schiffs. Wird über den Systemscan hochgefahren.",
      faults = { "kuehlmittel", "energiekopplung", "steuerung", "kurzschluss" } },

    { id = "shields",    name = "Schilde",           qual = "schilde",      nominal = 20, essential = true, maintGame = "frequency",
      desc = "Deflektorschilde in vier Sektoren (Bug, Steuerbord, Heck, Backbord).",
      faults = { "kalibrierung", "kurzschluss", "energiekopplung" } },

    { id = "weapons",    name = "Geschütze",         qual = "waffen",       nominal = 20, calib = true, maintGame = "timing",
      desc = "Turbolaser- und Ionenbatterien. Benötigen regelmäßige Kalibrierung.",
      faults = { "kalibrierung", "mechanik", "kurzschluss" } },

    { id = "engines",    name = "Triebwerke",        qual = "antrieb",      nominal = 20, navy = true, maintGame = "valves",
      desc = "Unterlichttriebwerke – bestimmen die Höchstgeschwindigkeit.",
      faults = { "mechanik", "kuehlmittel", "energiekopplung" } },

    { id = "hyperdrive", name = "Hyperantrieb",      qual = "hyperantrieb", nominal = 10, navy = true, maintGame = "sequence",
      overloadHeat = 0.26, heatRate = 0.46,  -- verträgt die Sprungenergie, heizt langsamer auf als andere Systeme
      desc = "Hyperantrieb – sprungbereit ab 60 % Effizienz und mit Navy-Freigabe.",
      faults = { "steuerung", "energiekopplung", "kalibrierung" } },

    { id = "sensors",    name = "Sensoren",          qual = "basis",        nominal = 10, calib = true, essential = true, maintGame = "frequency",
      desc = "Sensorphalanx – Fehler müssen durch Tests früh erkannt werden.",
      faults = { "kalibrierung", "steuerung", "kurzschluss" } },

    { id = "comms",      name = "Kommunikation",     qual = "basis",        nominal = 8,  essential = true, maintGame = "wires",
      desc = "Holonetz- und Funkrelais. Bei Ausfall ist der Funk gestört.",
      faults = { "kurzschluss", "steuerung" } },

    { id = "coolant",    name = "Kühlsystem",        qual = "basis",        nominal = 7,  essential = true, maintGame = "valves",
      desc = "Kühlkreisläufe – ohne Kühlung überhitzen Reaktor und Systeme.",
      faults = { "kuehlmittel", "mechanik" } },

    { id = "power",      name = "Energieverteilung", qual = "basis",        nominal = 5,  essential = true, maintGame = "wires",
      desc = "Energienetz – verteilt die Reaktorleistung auf alle Systeme.",
      faults = { "energiekopplung", "kurzschluss" } },
}

---------------------------------------------------------------------------
-- STÖRUNGSARTEN  (game = Minigame zur Reparatur)
---------------------------------------------------------------------------
ShipTech.FaultTypes = {
    kurzschluss     = { name = "Kurzschluss",              game = "wires",     desc = "Beschädigte Leitungen müssen neu verbunden werden." },
    kalibrierung    = { name = "Kalibrierungsfehler",      game = "frequency", desc = "Frequenzen weichen ab und müssen neu abgeglichen werden." },
    kuehlmittel     = { name = "Kühlmittelleck",           game = "valves",    desc = "Druck im Kühlkreislauf instabil – Ventile regulieren." },
    steuerung       = { name = "Steuerungsfehler",         game = "sequence",  desc = "Steuerlogik fehlerhaft – Befehlssequenz neu einspielen." },
    energiekopplung = { name = "Energiekopplung defekt",   game = "timing",    desc = "Energiekopplung muss neu synchronisiert werden." },
    mechanik        = { name = "Mechanischer Schaden",     game = "timing",    desc = "Mechanische Komponenten müssen neu ausgerichtet werden." },
}

ShipTech.GameNames = {
    wires     = "Leitungen verbinden",
    frequency = "Frequenzabgleich",
    valves    = "Druckregulierung",
    sequence  = "Befehlssequenz",
    timing    = "Synchronisation",
    scan      = "Fehlersuche",
    testrun   = "Testlauf",
}

---------------------------------------------------------------------------
-- QUALIFIKATIONEN (Fortbildungen)
---------------------------------------------------------------------------
ShipTech.Qualifications = {
    { id = "basis",        name = "Grundausbildung Technik",     desc = "Sensoren, Kommunikation, Kühlsystem, Energieverteilung" },
    { id = "schilde",      name = "Schildtechnik",               desc = "Wartung und Reparatur der Schildgeneratoren" },
    { id = "waffen",       name = "Waffentechnik",               desc = "Kalibrierung und Reparatur der Geschütze" },
    { id = "antrieb",      name = "Antriebstechnik",             desc = "Wartung und Reparatur der Triebwerke" },
    { id = "hyperantrieb", name = "Hyperantriebstechnik",        desc = "Wartung und Reparatur des Hyperantriebs" },
    { id = "reaktor",      name = "Reaktortechnik",              desc = "Reaktorstart, Wartung und Reparatur des Reaktors" },
    { id = "freigabe",     name = "Systemfreigabe (Leitung)",    desc = "Darf reparierte Systeme wieder freigeben" },
    { id = "navy",         name = "Navy-Befugnis",               desc = "Startfreigaben, Gefechtsalarm, Notfallprotokolle" },
    { id = "ausbilder",    name = "Ausbilder",                   desc = "Darf Fortbildungen vergeben (nur durch Admins vergebbar)" },
}

---------------------------------------------------------------------------
-- KONSOLEN / ENTITIES
-- kind: system | terminal | display | breaker
-- holo: Höhe des Hologramms über dem Model
---------------------------------------------------------------------------
ShipTech.ConsoleTypes = {
    { class = "shiptech_terminal_bridge", kind = "terminal", tab = "overview", holo = 18,
      name = "Brücken-Kontrollterminal", purpose = "Systemübersicht · Alarme · Navy-Freigaben",
      model = "models/kingpommes/starwars/misc/bridge_console4.mdl" },

    { class = "shiptech_con_nav", kind = "nav", holo = 18,
      name = "Navigationsstation", purpose = "Hyperraumsprung auslösen · Countdown · Rücksturz",
      model = "models/kingpommes/starwars/misc/bridge_console4.mdl" },
    { class = "shiptech_terminal_tech", kind = "terminal", tab = "orders", holo = 18,
      name = "Technik-Kontrollterminal", purpose = "Wartungsaufträge · Energieverteilung · Berichte · Protokoll",
      model = "models/kingpommes/starwars/misc/bridge_console2.mdl" },

    { class = "shiptech_con_reactor", kind = "system", sys = "reactor", holo = 18,
      name = "Reaktorsteuerung", purpose = "Reaktor hochfahren · Systemscan · Notabschaltung · Wartung",
      model = "models/reizer_props/srsp/sci_fi/console_03/console_03.mdl" },

    { class = "shiptech_con_shields", kind = "system", sys = "shields", holo = 18,
      name = "Schildgenerator-Steuerung", purpose = "Schildstatus · Sektorverstärkung · Wartung der Schilde",
      model = "models/lordtrilobite/starwars/isd/imp_console_medium02.mdl" },

    { class = "shiptech_con_weapons", kind = "system", sys = "weapons", holo = 18,
      name = "Geschützkalibrierung", purpose = "Kalibrierung · Reparatur der Turbolaser- und Ionenbatterien",
      model = "models/lordtrilobite/starwars/isd/imp_console_medium03.mdl" },

    { class = "shiptech_con_engines", kind = "system", sys = "engines", holo = 18,
      name = "Triebwerkssteuerung", purpose = "Wartung & Reparatur der Unterlichttriebwerke",
      model = "models/reizer_props/srsp/sci_fi/console_02_2/console_02_2.mdl" },

    { class = "shiptech_con_hyperdrive", kind = "system", sys = "hyperdrive", holo = 18,
      name = "Hyperantriebskern", purpose = "Wartung & Reparatur des Hyperantriebs",
      model = "models/reizer_props/srsp/sci_fi/console_02_2/console_02_2.mdl" },

    { class = "shiptech_con_sensors", kind = "system", sys = "sensors", holo = 18,
      name = "Sensorphalanx", purpose = "Sensortests · Kalibrierung · Fehlersuche",
      model = "models/lordtrilobite/starwars/isd/imp_console_medium02.mdl" },

    { class = "shiptech_con_comms", kind = "system", sys = "comms", holo = 18,
      name = "Kommunikationsrelais", purpose = "Wartung & Reparatur der Kommunikationssysteme",
      model = "models/lordtrilobite/starwars/isd/imp_console_medium03.mdl" },

    { class = "shiptech_con_coolant", kind = "system", sys = "coolant", holo = 18,
      name = "Kühlsystem-Steuerung", purpose = "Kühlmitteldruck · Lecks beheben · Wartung",
      model = "models/reizer_props/srsp/sci_fi/console_03/console_03.mdl" },

    { class = "shiptech_con_power", kind = "system", sys = "power", holo = 18,
      name = "Energieverteiler", purpose = "Energieverteilung zwischen den Systemen · Netzwartung",
      model = "models/kingpommes/starwars/misc/bridge_console2.mdl" },

    { class = "shiptech_shield_display", kind = "display", holo = 10,
      name = "Schildstatus-Anzeige", purpose = "Live-Anzeige der Schildstärke aller Sektoren",
      model = "models/kingpommes/starwars/misc/circle_console_wallmount.mdl" },

    { class = "shiptech_breaker", kind = "breaker", holo = 10,
      name = "Sektor-Energieverteiler", purpose = "Stromversorgung dieses Sektors · Sicherungen",
      model = "models/kingpommes/starwars/misc/circle_console_wallmount.mdl" },
}

-- Große Schiffsstatus-Wand für die Brücke
table.insert(ShipTech.ConsoleTypes, {
    class = "shiptech_status_wall", kind = "wall", holo = 12,
    name = "Schiffsstatus-Wand", purpose = "Alle Systeme, Schilde, Energie, Startcheckliste und Hyperraum auf einen Blick",
    model = "models/kingpommes/starwars/misc/circle_console_wallmount.mdl",
})

---------------------------------------------------------------------------
-- STARTCHECKLISTE (Brücke) – Schritte werden der Reihe nach bestätigt
---------------------------------------------------------------------------
local function On(S, id)
    local s = S.systems[id]
    return s.on and (s.eff or 0) > 0
end
ShipTech.ChecklistSteps = {
    { name = "Reaktor hochgefahren",        hint = "Reaktorsteuerung: Reaktor hochfahren",             check = function(S) return S.systems.reactor.on end },
    { name = "Kühlsystem online",           hint = "Kühlsystem-Steuerung: System hochfahren",          check = function(S) return On(S, "coolant") end },
    { name = "Energieverteilung online",    hint = "Energieverteiler: System hochfahren",              check = function(S) return On(S, "power") end },
    { name = "Schilde aktiv (über 50 %)",   hint = "Schilde laden nach dem Reaktorstart auf",          check = function(S) return On(S, "shields") and ShipTech.GetShieldPercent() > 50 end },
    { name = "Sensoren & Kommunikation",    hint = "Sensorphalanx und Kommunikationsrelais hochfahren", check = function(S) return On(S, "sensors") and On(S, "comms") end },
    { name = "Navy-Startfreigaben erteilt", hint = "Brückenterminal: Navy / Brücke",                   check = function(S) return S.systems.engines.navyClear and S.systems.hyperdrive.navyClear end },
    { name = "Triebwerke online",           hint = "Triebwerkssteuerung: System hochfahren",           check = function(S) return On(S, "engines") end },
    { name = "Geschütze einsatzbereit",     hint = "Geschützkalibrierung: hochfahren, ggf. kalibrieren", check = function(S) return On(S, "weapons") end },
}

---------------------------------------------------------------------------
-- EVENT-SZENARIEN { Sekunden ab Start, Aktion, Werte }
-- sector = "*" -> zufälliger Sektor-Energieverteiler
---------------------------------------------------------------------------
ShipTech.Scenarios = {
    { name = "Hinterhalt", desc = "Gefechtsalarm, schwerer Beschuss, Kommunikationsausfall, Stromausfall", steps = {
        { 0,   "combat", { on = true } },
        { 2,   "hit", { sector = 0, amount = 30, count = 5 } },
        { 25,  "comms", { order = true } },
        { 45,  "outage", { sector = "*" } },
        { 60,  "hit", { sector = 1, amount = 45, count = 5 } },
        { 90,  "fire", { sys = "weapons" } },
    } },
    { name = "Reaktorkrise", desc = "Kühlmittelleck, Energieüberlastung, danach Reaktornotfall", steps = {
        { 0,   "coolant", { order = true } },
        { 120, "overload", {} },
        { 240, "reactor_emergency", { order = true } },
    } },
    { name = "Sabotage", desc = "Versteckte Steuerungsfehler, Sensor- und Kommunikationsstörung, Sicherheitsalarm", steps = {
        { 0,   "fault", { sys = "hyperdrive", fault = "steuerung" } },
        { 60,  "fault", { sys = "sensors", fault = "steuerung" } },
        { 120, "comms", {} },
        { 150, "hyper_fail", {} },
        { 180, "alarm", { id = "security", info = "Sabotageverdacht" } },
    } },
    { name = "Systemkollaps", desc = "Energieverteilung bricht zusammen, Stromausfälle, Systeme fallen nacheinander aus", steps = {
        { 0,   "stage", { sys = "power", stage = 2, order = true } },
        { 30,  "outage", { sector = "*" } },
        { 60,  "stage", { sys = "sensors", stage = 2 } },
        { 90,  "outage", { sector = "*" } },
        { 120, "stage", { sys = "shields", stage = 1 } },
    } },
    { name = "Asteroidenfeld", desc = "Dauerbeschuss auf den Bug über zwei Minuten", steps = {
        { 0,   "alarm", { id = "security", info = "Asteroidenfeld" } },
        { 5,   "hit", { sector = 1, amount = 15, count = 4 } },
        { 35,  "hit", { sector = 1, amount = 20, count = 4 } },
        { 65,  "hit", { sector = 2, amount = 20, count = 4 } },
        { 95,  "hit", { sector = 1, amount = 30, count = 5 } },
        { 125, "alarm_clear", { id = "security" } },
    } },
    { name = "Brand im Maschinenraum", desc = "Brand an den Triebwerken, Kühlmittelleck, Evakuierung", steps = {
        { 0,   "fire", { sys = "engines" } },
        { 15,  "coolant", {} },
        { 30,  "alarm", { id = "evac", info = "Maschinenraum" } },
        { 60,  "fire", { sys = "coolant" } },
    } },
}

-- Aktionen, die im Ablauf-Editor gewählt werden können
ShipTech.SequenceActions = {
    { id = "stage",             name = "Schadensstufe setzen",               sys = true, stage = true },
    { id = "fault",             name = "Störung auslösen",                   sys = true },
    { id = "shutdown",          name = "System abschalten",                  sys = true },
    { id = "overheat",          name = "System überhitzen",                  sys = true },
    { id = "fire",              name = "Brand auslösen",                     sys = true },
    { id = "comms",             name = "Kommunikationsausfall" },
    { id = "coolant",           name = "Kühlmittelproblem" },
    { id = "coolant_leak",      name = "Kühlmittelleck (zufälliger Kreislauf)" },
    { id = "overload",          name = "Energieüberlastung" },
    { id = "random",            name = "Zufällige Störung" },
    { id = "outage",            name = "Stromausfall (zufälliger Sektor)" },
    { id = "restore_all",       name = "Alle Sektoren wiederherstellen" },
    { id = "reactor_emergency", name = "Reaktornotfall" },
    { id = "hit",               name = "Beschuss (5 Treffer)" },
    { id = "shields_off",       name = "Schilde deaktivieren" },
    { id = "combat",            name = "Gefechtsalarm an" },
    { id = "hyper_fail",        name = "Nächster Hyperraumsprung schlägt fehl" },
    { id = "alarm_clear_all",   name = "Alle Alarme aufheben" },
}

---------------------------------------------------------------------------
-- INGAME-KONFIGURATION (Konsole: shiptech_admin, Chat: !shiptechadmin)
-- type: bool | number | set (Komma-Liste -> {Name = true}) | list (Komma-Liste) | model
---------------------------------------------------------------------------
local function N(cat, key, label, min, max) return { cat = cat, key = key, type = "number", label = label, min = min, max = max } end
local function B(cat, key, label) return { cat = cat, key = key, type = "bool", label = label } end
local function S(cat, key, label) return { cat = cat, key = key, type = "set", label = label } end

ShipTech.ConfigSchema = {
    S("Rechte", "TechnicianTeams", "Techniker-Jobs (genaue Namen)"),
    { cat = "Rechte", key = "TechnicianTeamPatterns", type = "list", label = "Techniker-Jobs (Namensbestandteile)" },
    S("Rechte", "NavyTeams", "Navy-Jobs"),
    S("Rechte", "EventlerGroups", "Eventler-Usergroups"),
    S("Rechte", "AdminGroups", "Admin-Usergroups"),
    S("Rechte", "InstructorGroups", "Ausbilder-Usergroups"),
    B("Rechte", "UseQualifications", "Fortbildungssystem aktiv"),

    B("Allgemein", "AutoStart", "Schiff startet bereits hochgefahren"),
    B("Allgemein", "AutoOrders", "Automatische Wartungsaufträge"),
    N("Allgemein", "UseDistance", "Benutzungsreichweite", 60, 400),
    N("Allgemein", "HoloDistance", "Hologramm-Sichtweite", 200, 3000),
    N("Allgemein", "HoloDetailDistance", "Hologramm-Detailreichweite", 100, 2000),

    N("Simulation", "FastTick", "Schneller Takt (s)", 0.5, 5),
    N("Simulation", "SlowTick", "Langsamer Takt (s)", 5, 120),
    N("Simulation", "MaintDecayPerMinute", "Wartungsverlust pro Minute", 0, 10),
    N("Simulation", "CalibDecayPerMinute", "Kalibrierungsverlust pro Minute", 0, 10),
    N("Simulation", "WearBelowMaint", "Verschleiß unter Wartung (%)", 0, 100),
    N("Simulation", "WearPerMinute", "Verschleißschaden pro Minute", 0, 30),
    B("Simulation", "RandomFaults", "Zufällige Störungen"),
    N("Simulation", "RandomFaultBase", "Grundchance Zufallsstörung", 0, 0.1),

    N("Reparatur", "MinigameTime", "Minigame-Zeitlimit (s)", 15, 200),
    N("Reparatur", "CombatTimeFactor", "Zeitfaktor im Gefecht", 0.3, 1),
    N("Reparatur", "MaintenanceTime", "Dauer Routinewartung (s)", 1, 60),
    N("Reparatur", "CalibrationTime", "Dauer Kalibrierung (s)", 1, 60),
    N("Reparatur", "TestRunTime", "Dauer Testlauf (s)", 1, 60),
    N("Reparatur", "DiagnoseTime", "Dauer Diagnose (s)", 1, 60),
    N("Reparatur", "RepairTime.1", "Reparaturzeit beschädigt (s)", 1, 120),
    N("Reparatur", "RepairTime.2", "Reparaturzeit kritisch (s)", 1, 120),
    N("Reparatur", "RepairTime.3", "Reparaturzeit ausgefallen (s)", 1, 120),
    N("Reparatur", "PartsPerFault.2", "Ersatzteile je Störung (kritisch)", 0, 10),
    N("Reparatur", "PartsPerFault.3", "Ersatzteile je Störung (ausgefallen)", 0, 10),
    N("Reparatur", "SpareParts.Start", "Ersatzteile beim Start", 0, 100),
    N("Reparatur", "SpareParts.Max", "Ersatzteile maximal", 1, 200),
    N("Reparatur", "SpareParts.RequestAmount", "Lieferumfang", 1, 100),
    N("Reparatur", "SpareParts.RequestDelay", "Lieferzeit (s)", 5, 1200),
    N("Reparatur", "SpareParts.RequestCooldown", "Abstand zwischen Anforderungen (s)", 0, 7200),

    N("Energie", "PowerBudget", "Reaktorleistung (E)", 20, 400),
    N("Energie", "MaxAllocPerSystem", "Max. Energie pro System", 5, 200),
    N("Energie", "HeatRate", "Aufheizgeschwindigkeit (alle Systeme)", 0.1, 3),
    N("Energie", "HyperHeatFactor", "Aufheizgeschwindigkeit Hyperantrieb", 0.1, 3),
    B("Energie", "Backup.Enabled", "Notstrom vorhanden"),
    N("Energie", "Backup.Output", "Notstromleistung (E)", 0, 200),
    N("Energie", "Backup.DrainPerMinute", "Notstromverbrauch pro Minute", 0, 50),
    N("Energie", "Backup.RechargePerMinute", "Notstrom-Aufladung pro Minute", 0, 100),
    N("Energie", "ShieldRegen", "Schildregeneration (pro 5 s)", 0, 50),
    N("Energie", "ShieldDrainOff", "Schildabbau offline (pro 5 s)", 0, 100),
    N("Energie", "BreakerRadius", "Reichweite Sektor-Energieverteiler", 100, 5000),
    B("Energie", "GlobalBlackoutEffect", "Abdunkeln bei Totalausfall"),

    B("Werkzeug & Brand", "Tool.Required", "Werkzeug für Reparaturen nötig"),
    B("Werkzeug & Brand", "Tool.GiveOnSpawn", "Techniker bekommen Werkzeug"),
    B("Werkzeug & Brand", "Extinguisher.GiveOnSpawn", "Techniker bekommen Feuerlöscher"),
    B("Werkzeug & Brand", "Fire.Enabled", "Brände aktiv"),
    N("Werkzeug & Brand", "Fire.ChanceOnCritical", "Brandchance bei kritischem Schaden", 0, 1),
    N("Werkzeug & Brand", "Fire.ChanceOnOverheat", "Brandchance bei Überhitzung", 0, 1),
    N("Werkzeug & Brand", "Fire.ChanceOnHullHit", "Brandchance bei Hüllentreffer", 0, 1),
    N("Werkzeug & Brand", "Fire.DamagePerMinute", "Systemschaden durch Brand pro Minute", 0, 60),
    N("Werkzeug & Brand", "Fire.PlayerDamage", "Spielerschaden durch Brand pro Sekunde", 0, 50),
    N("Werkzeug & Brand", "Fire.SpreadChance", "Ausbreitungschance pro Sekunde", 0, 0.1),
    B("Werkzeug & Brand", "Chain.Enabled", "Kettenreaktionen aktiv"),

    N("Hyperraum", "Hyper.CalcTime", "Kursberechnung (s)", 5, 300),
    N("Hyperraum", "Hyper.MinSensors", "Mindest-Sensoreffizienz", 0, 1),
    N("Hyperraum", "Hyper.MinAlloc", "Mindestenergie Hyperantrieb (E)", 0, 200),
    N("Hyperraum", "Hyper.MinEfficiency", "Mindesteffizienz Hyperantrieb", 0, 1.2),
    N("Hyperraum", "Hyper.Countdown", "Countdown (s)", 3, 60),

    B("Fahrzeuge & Funk", "Vehicles.Enabled", "Fahrzeug-Anbindung aktiv"),
    S("Fahrzeuge & Funk", "Vehicles.ShipClasses", "Schiffs-Entities (Klassen)"),
    S("Fahrzeuge & Funk", "Vehicles.GunClasses", "Geschütz-Entities (Klassen)"),
    N("Fahrzeuge & Funk", "Vehicles.ShieldDamageScale", "Schild-Schadensfaktor", 0, 1),
    B("Fahrzeuge & Funk", "Vehicles.ScaleSpeed", "Geschwindigkeit an Triebwerke koppeln"),
    B("Fahrzeuge & Funk", "CryptoRadio.Enabled", "Funksystem (crypto_radio) koppeln"),
    N("Fahrzeuge & Funk", "CryptoRadio.JamAtStage", "Funk gestört ab Schadensstufe", 1, 3),
    N("Fahrzeuge & Funk", "CryptoRadio.AntennaDownStage", "Langstrecke aus ab Schadensstufe", 1, 3),
    { cat = "Fahrzeuge & Funk", key = "CommsBlockedCommands", type = "list", label = "Gesperrte Funkbefehle bei Ausfall" },
}
-- Models jeder Konsole sind ebenfalls ingame änderbar
for _, ct in ipairs(ShipTech.ConsoleTypes) do
    table.insert(ShipTech.ConfigSchema, { cat = "Models", key = "Model:" .. ct.class, type = "model", label = ct.name })
end

---------------------------------------------------------------------------
-- LERNHILFE / TECHNIKER-HANDBUCH
---------------------------------------------------------------------------
ShipTech.Handbook = {
    { title = "Grundlagen", text = {
        "Jedes System hat einen ZUSTAND (Schaden), einen WARTUNGSZUSTAND und eine TEMPERATUR. Geschütze und Sensoren zusätzlich eine KALIBRIERUNG.",
        "Schadensstufen: Betriebsbereit → Beschädigt (70 % Leistung) → Kritisch (35 %) → Ausgefallen (0 %).",
        "Wartung sinkt mit der Zeit. Unter 40 % ist eine Routinewartung fällig, unter 20 % nimmt das System Schaden und Störungen werden häufiger.",
        "Für Reparatur, Diagnose, Wartung und Kalibrierung brauchst du den TECHNISCHE DATAPAD in der Hand.",
        "Gelbe Leitungen zeigen, welche Konsolen mit Energie versorgt werden. Rot heißt: keine Energie.",
    } },
    { title = "Schiffsstart", text = {
        "1. Reaktorsteuerung: REAKTOR HOCHFAHREN – der Systemscan läuft im Chat bis 100 %.",
        "2. Sofort das KÜHLSYSTEM hochfahren, sonst überhitzt der Reaktor.",
        "3. ENERGIEVERTEILUNG hochfahren – ohne Netz bekommen alle Systeme nur halbe Leistung.",
        "4. Schilde fahren automatisch hoch. Danach Sensoren, Kommunikation, Geschütze.",
        "5. Die Navy erteilt am Brückenterminal die Startfreigaben für Triebwerke und Hyperantrieb.",
        "6. Die Brücke bestätigt jeden Schritt in der STARTCHECKLISTE.",
    } },
    { title = "Reparaturablauf", text = {
        "1. DIAGNOSE starten (Minigame Fehlersuche). Unbekannte Störungen werden sichtbar, das System geht in Wartung.",
        "2. Jede Störung einzeln BEHEBEN – jede Störungsart hat ihr eigenes Minigame. Danach Reparaturzeit an der Konsole abwarten.",
        "3. Bei kritischen oder ausgefallenen Systemen: TESTLAUF durchführen.",
        "4. WARTUNGSBERICHT schreiben (Ursache, Maßnahmen, Bemerkungen).",
        "5. Ein leitender Techniker (Fortbildung Systemfreigabe) gibt das System FREI.",
        "Kritische Reparaturen verbrauchen Ersatzteile. Fehlen sie, fordert die Brücke Nachschub an.",
        "Brennt eine Konsole, muss zuerst gelöscht werden – vorher ist keine Reparatur möglich.",
    } },
    { title = "Energie & Hitze", text = {
        "Die Energiezentrale (Reaktor- und Energiekonsole) zeigt Reaktorleistung, Auslastung und Verteilung.",
        "Mehr Energie als der Normalwert (weiße Marke) steigert die Leistung, erzeugt aber Hitze.",
        "Übersteigt der Bedarf die Reaktorleistung, wird der Reaktor überlastet und heizt auf.",
        "Bei 100 % Temperatur folgt eine SICHERHEITSABSCHALTUNG mit Schaden – oft mit Brand.",
        "Kettenreaktionen: Ohne Kühlung heizt alles auf. Ein beschädigtes Energienetz lässt Systeme flackern. Ein überhitzter Reaktor verursacht Überspannungen im Netz.",
    } },
    { title = "Minigames", text = {
        "LEITUNGEN VERBINDEN: Quelle anklicken, dann den Anschluss gleicher Farbe. Falsche Verbindung = Zeitstrafe.",
        "FREQUENZABGLEICH: Regler ziehen, bis das weiße Signal die türkise Zielwelle deckt, und kurz halten.",
        "DRUCKREGULIERUNG: Ventile anklicken, um Druck abzulassen. Alle Anzeigen im grünen Bereich halten.",
        "BEFEHLSSEQUENZ: Die aufleuchtende Folge merken und in derselben Reihenfolge eingeben.",
        "SYNCHRONISATION / TESTLAUF: Klicken oder LEERTASTE, wenn der Zeiger im grünen Bereich ist.",
        "FEHLERSUCHE: Rot blinkende Anomalien anklicken, bevor sie verschwinden.",
        "Im Gefechtsalarm ist weniger Zeit. Eine fehlerhafte Eingabe kostet Sekunden.",
    } },
    { title = "Brand", text = {
        "Kritische Schäden, Überhitzung und Hüllentreffer können Brände auslösen.",
        "Ein Brand beschädigt das System laufend, verletzt Personen in der Nähe und kann auf Nachbarkonsolen übergreifen.",
        "Mit dem FEUERLÖSCHER (Linksklick halten) auf die brennende Konsole sprühen.",
    } },
    { title = "Hyperraum", text = {
        "Brücken-Kontrollterminal → Hyperraum: 1. Kurs berechnen (braucht funktionierende Sensoren).",
        "2. Energie umleiten (Hyperantrieb braucht genug Energie). Das Terminal bereitet NUR vor.",
        "3. Ausgelöst wird der Sprung ausschließlich an der NAVIGATIONSSTATION – Countdown läuft.",
        "Notsprung: übergeht Sperren (z. B. Techniker im Außeneinsatz) – die Brücke bekommt eine Warnung mit Namen.",
        "Schlecht gewartete oder beschädigte Hyperantriebe können beim Sprung versagen und Feuer fangen.",
    } },
    { title = "Kühlung & Verschleiß", text = {
        "Es gibt 5 Kühlkreisläufe: Reaktor, Triebwerke, Waffen/Türme, Hyperantrieb und Schiff. Jeder hat Füllstand und Druck.",
        "Kühlmittellecks lassen den Kreislauf leerlaufen. Nachfüllen an der Kühlsystem-Steuerung (verbraucht Kühlmittel aus dem Lager).",
        "Unter 40 % Füllstand bricht die Kühlleistung ein. Bei Überdruck öffnen die Sicherheitsventile und lassen Kühlmittel ab.",
        "INSPEKTIONEN (z. B. Reaktorkern, Reaktordruck, Sicherheitsventile): einzelne Prüfschritte, heben den Wartungszustand und decken versteckte Störungen auf.",
        "Der VERSCHLEISS-Faktor steigt mit Betriebsstunden, Überlast, Gefechtsalarm, Hitze, schlechter Energieversorgung, wenig Kühlmittel, überfälligen Inspektionen und Schäden.",
        "Eine Routinewartung setzt Betriebsstunden und Inspektionen zurück.",
    } },
    { title = "Material & Logistik", text = {
        "Mit GAR Logistik kommt das Material für Reparaturen aus dem Schiffslager (Venator).",
        "Kurzschluss: Sicherungen + Leitungen · Kalibrierung/Steuerung: Elektronik · Kühlmittelleck: Kühlmittel · Energiekopplung: Ersatzmodul + Leitungen · Mechanik: Ersatzteile + Werkzeug.",
        "Kritische und ausgefallene Systeme brauchen 2x bzw. 3x so viel Material.",
        "Fehlt Material, stellt die Brücke (Navy) einen Versorgungsantrag an die Logistik – die Logistik liefert per Shuttle oder Container.",
    } },
}

-- Beleuchtung ebenfalls ingame einstellbar
for _, e in ipairs({
    { cat = "Fahrzeuge & Funk", key = "Lights.Enabled",          type = "bool",   label = "Beleuchtung koppeln (SSE Lightswitch)" },
    { cat = "Fahrzeuge & Funk", key = "Lights.OffOnBlackout",    type = "bool",   label = "Licht aus bei Totalausfall" },
    { cat = "Fahrzeuge & Funk", key = "Lights.OffOnGridFailure", type = "bool",   label = "Licht aus bei ausgefallenem Energienetz" },
    { cat = "Fahrzeuge & Funk", key = "Lights.Flicker",          type = "bool",   label = "Licht flackert bei Treffern" },
    { cat = "Fahrzeuge & Funk", key = "Lights.FlickerCooldown",  type = "number", label = "Flacker-Abstand (s)", min = 3, max = 300 },
}) do
    table.insert(ShipTech.ConfigSchema, e)
end