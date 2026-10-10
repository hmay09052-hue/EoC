--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Grundeinstellungen

    Fast alles hier kann auch ingame im Menue unter ADMIN > EINSTELLUNGEN geaendert werden.
    Ingame-Aenderungen werden in der Datenbank gespeichert und ueberschreiben die Werte aus dieser Datei.
    Diese Datei liefert also nur die Startwerte.

    Datenbank (SQLite / MySQL) wird in symchars/sv_config.lua eingestellt (nur Server).
-------------------------------------------------------------------------------------------------------------]]

symchars.defaults = {
    ---------------------------------------------------------------------------------------------------------
    -- Allgemein
    ---------------------------------------------------------------------------------------------------------
    openkey = KEY_F4,                    -- Taste zum Oeffnen des Menues (0 = keine Taste, nur /chars). Ingame: ADMIN > EINSTELLUNGEN > Allgemein > Menü-Taste
    chatcommands = { "/chars", "/characters", "/symchars", "!chars" },
    forcemenuondeath = false,           -- Menue nach jedem Tod oeffnen
    changesonpos = false,               -- Bei Einheiten-/Jobwechsel an Ort und Stelle bleiben (kein Respawn)
    communityName = "",                 -- Community-Name (klein in Aurebesh links in der Menüleiste)

    ---------------------------------------------------------------------------------------------------------
    -- Design
    ---------------------------------------------------------------------------------------------------------
    accentcolor = Color(252, 178, 73),  -- Akzentfarbe (Bernstein wie in den Kraken-Scripts)
    hologramcolor = Color(90, 190, 255),
    backgroundurl = "",                 -- Hintergrundbild (Imgur-Link oder direkter https-Link), leer = Spielwelt
    blurbackground = true,
    darkoverlay = 205,                  -- 0-255 Abdunklung ueber dem Hintergrund
    usemusic = false,
    musicurl = "",                      -- Direkter Link zu einer mp3/ogg (sound.PlayURL) oder Sound-Pfad
    musicvolume = 25,

    ---------------------------------------------------------------------------------------------------------
    -- Charaktere
    ---------------------------------------------------------------------------------------------------------
    usefactions = true,                 -- Einheitensystem verwenden (sonst nur DarkRP-Jobs + Whitelist)
    useroleplayid = true,               -- RP-ID (z.B. CT-1011) verwenden
    usesurnamefield = false,            -- Zweites Namensfeld (Nachname)
    minnamechars = 3,
    maxnamechars = 24,
    slotsdefault = 2,                   -- Charakter-Slots fuer alle
    slotsbygroup = {                    -- Mehr Slots fuer bestimmte Usergroups (hoechster Wert zaehlt)
        vip = 3,
        admin = 4,
        superadmin = 6,
    },
    designateddefaultfaction = "citizen", -- Einheit, in die entlassene Charaktere kommen (uniqueID)
    defaultjob = "teamzivilisten",      -- Job-Befehl fuer Charaktere ohne Einheit (TEAM_ZIVILIST)
    blockjobchange = false,             -- DarkRP-Jobwechsel (F4) auf die Jobs der eigenen Einheit beschraenken
    savemoney = true,                   -- Geld pro Charakter speichern

    rpidprefix = "CT-",                 -- Standard-Praefix der RP-ID
    rpidlength = 4,                     -- Anzahl Ziffern
    rpidrules = {                       -- Abweichende Praefixe fuer Einheiten oder Jobs
        -- { prefix = "CC-", length = 4, units = { "kommando" }, jobs = {} },
    },

    forbiddennames = {
        "Nazi", "Hitler", "Fascist", "ISIS", "Fuck", "Shit", "Bitch", "Asshole", "Bastard", "Cunt", "Dick",
        "Pussy", "Slut", "Whore", "Motherfucker", "Porn", "Sex", "Nude", "Nigga", "Nigger", "Faggot",
        "Hurensohn", "Wichser", "Fotze", "Schlampe", "Missgeburt", "Spast", "Admin", "Moderator", "Owner",
        "Developer", "Console", "Server", "Support",
    },

    disabledvariables = {},             -- Zusatzfelder (z.B. "nationality") deaktivieren

    -- Nationalitäten bei der Charaktererstellung.
    -- blockedjobs: diese DarkRP-Jobs (Befehle) kann man mit der Nationalität nicht nehmen (Erstellung + F4)
    -- Zusätzlich kann jede Einheit im Einheiten-Editor auf bestimmte Nationalitäten beschränkt werden.
    nationalities = {
        { id = "rep", name = "Republikanisch", blockedjobs = {} },
        { id = "sep", name = "Separatistisch", blockedjobs = { "cadetss" } },
    },

    ---------------------------------------------------------------------------------------------------------
    -- Rechte in den Einheiten: ab welchem Rang (Name) etwas automatisch erlaubt ist.
    -- Gilt in jeder Einheit ab dem Rang mit diesem Namen aufwärts, nur gegenüber niedrigeren Rängen.
    -- Mehrere Namen mit Komma, z.B. "Sergeant, Feldwebel". Leer = nur über angehakte Rang-Rechte.
    -- Pro Einheit im Einheiten-Editor überschreibbar.
    ---------------------------------------------------------------------------------------------------------
    rightpromotions = "Sergeant",       -- Befördern, Degradieren, Rang setzen
    rightkick = "Sergeant",             -- aus der Einheit entlassen
    rightinvite = "Corporal",           -- Spieler in die Einheit aufnehmen (einladen)
    righttransfer = "Sergeant",         -- in Untereinheiten versetzen

    ---------------------------------------------------------------------------------------------------------
    -- Anzeige
    ---------------------------------------------------------------------------------------------------------
    useoverheadhud = true,              -- Namensschild ueber Spielern (zeigt NUR Name + Rang, keine Einheit)
    overheaddistance = 220,
    displayroleplayid = true,           -- RP-ID im DarkRP-Namen (z.B. "CT-7567 Rex"), der Rang steht nie im Namen

    ---------------------------------------------------------------------------------------------------------
    -- Fortbildungen
    ---------------------------------------------------------------------------------------------------------
    trainingsse = true,                 -- Fortbildungen schalten Fahrzeuge im SSE-Fahrzeugterminal frei
    trainingssefilter = true,           -- Fahrzeuge, die zu einer Fortbildung gehoeren, ohne Fortbildung sperren
    trainingannounce = true,            -- Bestandene Fortbildung im Chat der Einheit bekanntgeben
    trainingfreigabe = "fortbildungsfreigabe", -- ID der Fortbildung, die zum Eintragen von Fortbildungen berechtigt

    ---------------------------------------------------------------------------------------------------------
    -- Dokumente
    ---------------------------------------------------------------------------------------------------------
    docsmaxblocks = 400,                -- Maximale Bloecke pro Dokument
    docsallowimages = true,             -- Bilder (Imgur) in Dokumenten erlauben
}
