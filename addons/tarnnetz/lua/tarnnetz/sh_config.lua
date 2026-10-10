Tarnnetz = Tarnnetz or {}

Tarnnetz.Config = {
    -- Klasse der Waffe (lua/weapons/weapon_tarnnetz.lua)
    WeaponClass = 'weapon_tarnnetz',

    -- Ab dieser Entfernung zu einem Droiden bricht die Tarnung (in Units, 1 m ~ 52.5 Units -> 10 m = 525)
    Radius = 525,

    -- Wie oft der Server die Entfernung zu Droiden prüft (Sekunden)
    CheckInterval = 0.25,

    -- Was passiert, wenn ein Droide zu nah kommt:
    --   'break' = Tarnung bricht komplett ab (Muster weg, NoTarget weg, Abklingzeit startet)
    --   'pause' = NoTarget ist nur weg, solange ein Droide in der Nähe ist, Muster bleibt
    ProximityMode = 'break',

    -- Abklingzeit nach einer Enttarnung durch Droiden (Sekunden, 0 = aus)
    Cooldown = 15,

    -- Abklingzeit nach manuellem Deaktivieren (Sekunden, 0 = aus)
    ManualCooldown = 3,

    -- Was als Droide zählt
    DroidBases = { 'summe_nextbot' },   -- Entities, die auf dieser Basis aufbauen
    DroidPrefixes = { 'npc_summe_' },   -- Entity-Klassen mit diesem Anfang
    AllNPCs = false,                     -- true = jeder NPC / Nextbot zählt als Droide

    -- Tarnmuster (mat = Materialpfad ohne "materials/" und ohne ".vmt")
    Camos = {
        { name = 'Urban Schnee', short = 'URB-S1', desc = 'Schnee- und Eisgebiete, urbane Ruinen', mat = 'camo_urban_snow_1' },
        { name = 'Wüste',        short = 'DST-01', desc = 'Sand, Fels und trockene Ebenen',       mat = 'camo_desert_1' },
        { name = 'Wald',         short = 'MHW-05', desc = 'Dichte Vegetation und Dschungel',      mat = 'camo_mohw_5' },
        { name = 'Nacht',        short = 'MHW-12', desc = 'Dunkle Anlagen und Nachteinsätze',      mat = 'camo_mohw_12' },
        { name = 'Gelände',      short = 'MHW-14', desc = 'Gemischtes Gelände und Einsatzgebiete', mat = 'camo_mohw_14' },
    },

    -- Chatnachricht beim Aktivieren ("<Name> aktiviert das Tarnnetz.")
    -- ChatRange: nur Spieler in diesem Umkreis sehen sie (Units), 0 = alle Spieler
    ChatMessage = true,
    ChatRange = 0,

    -- Texte
    Lang = {
        title       = 'Tarnnetz',
        sub         = 'Optisches Tarnsystem',
        choose      = 'Tarnmuster wählen',
        cancel      = 'Abbrechen',
        hint        = 'Linksklick: Aktivieren   //   Rechtsklick: Deaktivieren',
        chat        = 'aktiviert das Tarnnetz.',
        activated   = 'Tarnnetz aktiv: %s. Droiden erkennen dich erst auf %d m.',
        deactivated = 'Tarnnetz deaktiviert.',
        detected    = 'Enttarnt! Ein Droide ist zu nah gekommen.',
        paused      = 'Droide in der Nähe – Tarnnetz gestört!',
        resumed     = 'Tarnnetz wiederhergestellt.',
        alreadyOn   = 'Das Tarnnetz ist bereits aktiv.',
        notActive   = 'Das Tarnnetz ist nicht aktiv.',
        cooldown    = 'Tarnnetz lädt noch (%d s).',
        tooClose    = 'Ein Droide ist zu nah, Tarnnetz nicht möglich.',
        hudActive   = 'Tarnnetz aktiv',
        hudPaused   = 'Tarnnetz gestört',
        hudCooldown = 'Tarnnetz lädt',
        hudDroid    = 'Nächster Droide',
        hudNone     = 'Kein Droide in Reichweite',
    },
}
