GRNSerials = GRNSerials or {}
GRNSerials.Config = GRNSerials.Config or {}
local C = GRNSerials.Config

-- =========================================================
-- Waffen mit Seriennummer & Geschichte (Echoes of Clones)
-- Jede ausgegebene Inventar-Waffe ist ein einzelnes Objekt mit
-- Seriennummer, Verschleiß, Besitzerkette und Akte.
-- Alle Zahlen sind Startwerte fürs Balancing.
-- =========================================================

C.Enabled = true

-- ---------------------------------------------------------
-- Seriennummer: HERSTELLER-JAHR-LAUFNUMMER-PRÜFZIFFER
-- ---------------------------------------------------------
-- Hersteller-Kürzel nach Waffenklasse (erster Treffer gewinnt, Teilstring
-- der Klasse). Rein atmosphärisch.
C.ManufacturerPrefixes = {
    { "dc15", "BTA" },     -- BlasTech
    { "dc17", "BTA" },
    { "dp2", "BTA" },
    { "dlt", "BTA" },
    { "e11", "BTA" },
    { "a280", "BTA" },
    { "dh17", "BTA" },
    { "e5", "BAK" },       -- Baktoid
    { "b2", "BAK" },
    { "z6", "MRS" },       -- Merr-Sonn
    { "smartlauncher", "MRS" },
    { "westar", "CNC" },   -- Concordia
    { "cr2", "CRL" },      -- Corellian
    { "valken", "CSA" },
    { "stw", "MRS" },
    { "rx21", "MRS" },
    { "a180", "BTA" },
    { "tl50", "BTA" },
}
C.DefaultPrefix = "REP"

-- Nur diese Waffenklassen bekommen eine Nummer (Teilstring). Leer = alle
-- Inventar-Waffen. Granaten, Schilde usw. werden über C.ExcludeClasses
-- ausgenommen.
C.IncludeClasses = { "arccw_" }
C.ExcludeClasses = { "nade", "shield", "grenade", "cuff", "deployer", "medkit", "bacta", "jet_", "recondroid", "flamethrower", "lscs" }

-- ---------------------------------------------------------
-- Verschleiß
-- ---------------------------------------------------------
C.Wear = {
    DirtPerShot = 0.05,
    DirtWaterMud = 5,             -- beim Betreten von Wasser/Schlamm (Bodenmaterial per Trace)
    DirtPerMinuteDown = 2,        -- pro Minute "am Boden" (Träger tot, nicht wiederbelebt)
    ConditionPerShot = 0.01,      -- Prozentpunkte pro Schuss
    DirtyThreshold = 60,          -- ab dieser Verschmutzung doppelter Verschleiß
    DirtyMultiplier = 2,
    -- Zustand -> Auswirkung (von oben nach unten geprüft)
    Tiers = {
        { Min = 80, Spread = 1.00, JamEvery = 0,   Label = "EINWANDFREI" },
        { Min = 50, Spread = 1.05, JamEvery = 0,   Label = "GEBRAUCHT" },
        { Min = 25, Spread = 1.05, JamEvery = 150, Label = "VERSCHLISSEN" },
        { Min = 1,  Spread = 1.08, JamEvery = 40,  Label = "KRITISCH" },
        { Min = 0,  Spread = 1.08, JamEvery = 0,   Label = "BLOCKIERT", Blocked = true },
    },
    -- Eine gepflegte Waffe hemmt nie: unter diesem Schmutzwert gibt es auch
    -- bei 25-49 % Zustand keine Ladehemmung.
    NoJamBelowDirt = 30,
}

-- ---------------------------------------------------------
-- Pflege & Logistik (Inventar-Items)
-- ---------------------------------------------------------
C.CleaningKitItem = "ws_cleaning_kit"
C.CleaningTime = 10               -- Sekunden, Spieler muss die Waffe halten
C.SparePartsItem = "ws_spare_parts"
C.RepairPartsPer25 = 1            -- Ersatzteile je angefangene 25 % Schaden
C.BarrelChangeParts = 2
C.BarrelChangeClasses = { "z6", "dlt", "chaingun", "dc15le", "cr2" }

-- Waffenmeister: Job-Commands (Präfix oder genauer Command). Admins dürfen immer.
C.ArmorerJobs = { "501steng_" }
C.ArmorerUserGroups = { superadmin = true, admin = true }

-- ---------------------------------------------------------
-- Historie
-- ---------------------------------------------------------
C.History = {
    KillDetail = 50,
    DeathDetail = 50,
    ServiceDetail = 20,           -- Reparatur / Reinigung
    SaveInterval = 60,            -- Sekunden, gebündeltes Speichern
    CleanupHour = 4,              -- nächtlicher Aufräum-Job (Serverzeit)
}

-- Meilensteine. Type: kills / rounds / longshot / holders / homecoming
C.Milestones = {
    { ID = "kills_100",  Type = "kills",  Value = 100,   Name = "Erste Kerbe",       Engraving = "I",      Icon = "fa-grip-lines-vertical" },
    { ID = "kills_500",  Type = "kills",  Value = 500,   Name = "Fünf Kerben",       Engraving = "V",      Icon = "fa-grip-lines-vertical" },
    { ID = "kills_1000", Type = "kills",  Value = 1000,  Name = "Tausend Kerben",    Engraving = "M",      Icon = "fa-grip-lines-vertical" },
    { ID = "rounds_10k", Type = "rounds", Value = 10000, Name = "Veteran",           Engraving = "VETERAN", Icon = "fa-award" },
    { ID = "longshot",   Type = "longshot", Value = 300, Name = "Weitschuss",        Engraving = nil,      Icon = "fa-bullseye" },
    { ID = "survivor",   Type = "holders", Value = 3,    Name = "Drei Träger überlebt", Engraving = nil,   Icon = "fa-people-group", KillfeedName = true },
    { ID = "homecoming", Type = "homecoming", Value = 1, Name = "Heimgekehrt",       Engraving = "HEIMGEKEHRT", Icon = "fa-house-flag" },
}
-- Hammer-Einheiten pro Meter (Source: ~52.49 HU = 1 m)
C.UnitsPerMeter = 52.49

-- ---------------------------------------------------------
-- Anti-Missbrauch
-- ---------------------------------------------------------
C.AntiFarm = {
    CountNPCKills = true,
    SameVictimPerHour = 3,
    IdleSeconds = 60,             -- Opfer ohne Bewegung so lange -> zählt nicht
    TransferCooldown = 600,       -- Sekunden zwischen Besitzerwechseln derselben Waffe
}

-- Fraktion eines Spielers. Kills zählen nur zwischen verschiedenen
-- Fraktionen; gleiche Fraktion = Teamkill (Vorfall in der Akte).
-- Standard: alle Jobs aus C.Regiments gelten als "republic", sonst die
-- DarkRP-Kategorie bzw. das Team.
C.FactionOverrides = {
    -- ["Separatisten"] = "cis",
}

-- ---------------------------------------------------------
-- Spitzname
-- ---------------------------------------------------------
C.Nickname = {
    MaxLength = 24,
    Cooldown = 3600,
    BlockedWords = { "nigger", "nazi", "hitler", "fuck", "hure", "fotze", "admin" },
}

-- ---------------------------------------------------------
-- Regimenter (Einheiten) und Ränge
-- ---------------------------------------------------------
-- Ohne eigene Liste werden die Einheiten aus der Rüstung genommen
-- (GRNInventory.Config.Armor.UnitJobs). Name = Anzeige.
C.RegimentNames = {
    T501 = "501st Torrent Company",
    HEAVY = "501st Heavy",
    ARF = "501st ARF",
    BARC = "501st BARC",
    AB = "501st Airborne",
    MED = "501st Medical",
    ENG = "501st Engineering",
    ST = "Schocktruppen",
    NAVY = "Republic Navy",
}

-- Rangreihenfolge (Ende des Job-Commands, z. B. 501st_sgt -> sgt).
C.RankOrder = { "pvt", "pfc", "spc", "cpl", "fcpl", "sgt", "ssgt", "fsgt", "sgm", "2lt", "lt", "1lt", "cpt", "maj", "col", "cmd" }
C.TraditionProposeRank = "lt"     -- ab diesem Rang vorschlagen / Übergabe starten
C.TraditionConfirmRank = "cpt"    -- ab diesem Rang bestätigen (Regimentsführung)
C.TraditionAdminGroups = { superadmin = true, admin = true }

-- ---------------------------------------------------------
-- Traditionswaffen
-- ---------------------------------------------------------
C.Tradition = {
    MaxPerRegiment = 3,
    MinAgeDays = 30,
    MinMilestones = 1,
    MinCondition = 50,
    CeremonyRadius = 3,           -- Meter
    AnnounceServerWide = true,    -- sonst nur Regiment
    -- Weniger Risiko: nach so vielen Sekunden automatisch zurück in die
    -- Vitrine (0 = aus).
    AutoReturnSeconds = 1800,
}

-- ---------------------------------------------------------
-- Waffenpass / UI
-- ---------------------------------------------------------
C.PassKey = KEY_F                 -- gedrückt halten
C.PassHoldTime = 0.5
C.PassCommand = "ws_waffenpass"
C.PassChatCommands = { "!waffenpass", "/waffenpass" }
C.RequestCooldown = 0.5           -- Rate-Limit pro Spieler
C.ShowHUD = true
C.AdminGroups = { superadmin = true, admin = true }
