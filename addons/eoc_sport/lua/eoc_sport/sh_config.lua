EoCSport = EoCSport or {}
EoCSport.Config = EoCSport.Config or {}
EoCSport.Exercises = EoCSport.Exercises or {}

local C = EoCSport.Config

---------------------------------------------------------------------------
-- Bedienung
---------------------------------------------------------------------------
C.ChatCommands = { "/sport", "!sport" }   -- öffnen/beenden; Konsole: eoc_sport

C.RepKeyName = "E"                         -- Wiederholung ist immer IN_USE (E)
C.EndKey = IN_JUMP                         -- Übung beenden
C.EndKeyName = "Leertaste"
C.DeclineKey = IN_RELOAD                   -- Gruppen-Aufforderung ablehnen
C.DeclineKeyName = "R"

-- Waffe, die beim Start gezogen wird (DarkRP: "keys"). Fehlt sie, wird die
-- Waffe nur weggesteckt.
C.HolsterWeapon = "keys"

C.EnterTime = 0.5   -- Sekunden in die Startposition
C.LeaveTime = 0.5   -- Sekunden zum Aufstehen

---------------------------------------------------------------------------
-- Rechte (SAM-Usergroups, DarkRP-Jobs)
---------------------------------------------------------------------------
-- Wer den Reiter "Gruppe" sieht und Strafrunden geben darf.
-- Jobs per DarkRP-Command oder Jobname, alles klein geschrieben.
C.InstructorJobs = {
    -- ["ausbilder"] = true,
}

-- Ganze DarkRP-Kategorien, z. B. für Unteroffiziere.
C.InstructorCategories = {
    -- ["unteroffiziere"] = true,
}

-- SAM-Usergroups, die immer als Ausbilder zählen.
C.InstructorGroups = {
    ["superadmin"] = true,
    ["admin"] = true,
}

-- Klimmzugstange spawnen, Posen-Werkzeug (eoc_sport_posetool).
C.AdminGroups = {
    ["superadmin"] = true,
    ["admin"] = true,
}

-- Eigene Regel: true/false entscheidet, nil = normale Prüfung.
C.CustomInstructorCheck = function(ply)
    return nil
end

-- Anzeigename. Standard: DarkRP-Name (Nick). Für SymChars hier den
-- Charakternamen zurückgeben, z. B. return ply:GetNW2String("SymChars_Name")
C.CharacterName = function(ply)
    return nil
end

---------------------------------------------------------------------------
-- Regeln und Sperren
---------------------------------------------------------------------------
C.MaxSlope = 25              -- Grad
C.CombatCooldown = 10        -- Sekunden nach Schaden / Schuss
C.AfkTimeout = 60            -- Sekunden ohne Eingabe
C.MaxPushDistance = 20       -- Einheiten, ab denen "weggeschoben" abbricht
C.MaxPressesPerSecond = 10   -- mehr E-Drücke pro Sekunde werden ignoriert

-- DEFCON: Sport gesperrt, wenn die Stufe <= diesem Wert ist (1 = höchste
-- Bereitschaft). nil schaltet die Sperre ab.
C.DefconBlockLevel = 2

-- Liefert die aktuelle DEFCON-Stufe oder nil, wenn EoC DEFCON fehlt.
-- An die API des DEFCON-Addons anpassen, falls sie anders heißt.
C.GetDefcon = function()
    if EoCDefcon and isfunction(EoCDefcon.GetLevel) then
        return EoCDefcon.GetLevel()
    end
    local level = GetGlobalInt("EoC_DEFCON", 0)
    if level > 0 then return level end
    return nil
end

-- Bereiche, in denen Sport erlaubt ist. Leer = überall.
-- Bereiche ohne passende Map werden ignoriert; hat die aktuelle Map gar
-- keinen Bereich, ist Sport dort überall erlaubt.
C.Zones = {
    -- { name = "Trainingsraum", map = "rp_venator", min = Vector(-500, -500, -100), max = Vector(500, 500, 200) },
}

---------------------------------------------------------------------------
-- Ausdauer (optisch): viele schnelle Wiederholungen machen die Animation
-- langsamer. Die Sperrzeit wächst mit, damit nichts abgeschnitten wird.
---------------------------------------------------------------------------
C.Fatigue = {
    Enabled = true,
    StartAfter = 10,   -- ab so vielen Wiederholungen am Stück
    PerRep = 0.03,     -- +3 % Dauer pro weiterer Wiederholung
    Max = 0.5,         -- höchstens +50 %
    ResetAfter = 3,    -- Pause in Sekunden, nach der die Serie neu zählt
}

---------------------------------------------------------------------------
-- Kamera und Anzeige
---------------------------------------------------------------------------
C.Camera = {
    Distance = 90,
    Side = 22,
    Up = 6,
    BlendTime = 0.4,
    MinPitch = -50,
    MaxPitch = 70,
}

C.Overhead = {
    MaxDistance = 500,
    Scale = 0.08,
}

---------------------------------------------------------------------------
-- Ausbilder
---------------------------------------------------------------------------
C.Group = {
    DefaultRadius = 600,
    MaxRadius = 1500,
    InviteTime = 10,        -- Sekunden zum Annehmen
    Countdown = 3,
    MaxDuration = 900,      -- Sicherheitsgrenze in Sekunden
    TempoWindow = 1.5,      -- so lange nach "Eins!" darf gedrückt werden
    ResultTime = 12,        -- Auswertung sichtbar in Sekunden
    ListInterval = 0.5,
}

C.Penalty = {
    MaxRadius = 1500,
    MaxCount = 100,
}

---------------------------------------------------------------------------
-- Klimmzugstange
---------------------------------------------------------------------------
C.PullupBar = {
    Model = "models/hunter/blocks/cube025x2x025.mdl",
    Material = "phoenix_storms/metalset_1-2",
    PostModel = "models/hunter/blocks/cube025x025x025.mdl",
    Height = 100,        -- Höhe der Stange über dem Boden beim Spawnen
    Length = 95,         -- Länge der Stange (lokale Y-Achse)
    Radius = 80,         -- so nah muss man davorstehen
    HangHeight = 80,     -- Abstand Stange -> Füße beim Hängen
    HangOffset = 4,      -- Abstand vor der Stange
}

---------------------------------------------------------------------------
-- Übungen
--
-- mode      "reps" (ein E = eine Wiederholung) oder "hold" (Sekunden)
-- hold      bei mode "hold": "hold" = E gedrückt halten, loslassen beendet;
--           "toggle" = E startet/stoppt das Zählen
-- duration  Sekunden pro Wiederholung (= Sperrzeit)
-- sequence  Name einer echten Animationssequenz (Weg A), sonst nil
-- poses     Bone-Posen aus cl_poses.lua: start = Startposition,
--           low = Umkehrpunkt (start -> low -> start pro Wiederholung)
-- cycle     statt "low": eigene Abfolge { {Zeit 0-1, "pose"}, ... }
-- loop      bei "hold": Bewegung, solange gezählt wird { dur = s, frames = {...} }
-- space     benötigte freie Fläche (Länge nach vorn, Breite)
-- spaceFrom Beginn der Fläche relativ zu den Füßen (negativ = nach hinten)
-- needsBar  nur an einer Klimmzugstange
-- groupWeight  Faktor für die Gruppenwertung
-- camHeight / signHeight  Kamera-Zielpunkt und Schild über dem Kopf
---------------------------------------------------------------------------
local E = EoCSport.Exercises

E["pushups"] = {
    name = "Liegestütze",
    desc = "Stütz auf den Händen. Runter und hoch.",
    short = "LS",
    order = 1,
    mode = "reps",
    duration = 1.0,
    sequence = nil,
    poses = { start = "pushup_up", low = "pushup_down" },
    space = Vector(80, 40, 0),
    camHeight = 24,
    signHeight = 50,
}

E["situps"] = {
    name = "Sit-ups",
    desc = "Rückenlage, Knie angewinkelt. Hoch und zurück.",
    short = "SU",
    order = 2,
    mode = "reps",
    duration = 1.2,
    poses = { start = "situp_down", low = "situp_up" },
    space = Vector(80, 40, 0),
    spaceFrom = -40,
    camHeight = 22,
    signHeight = 50,
}

E["squats"] = {
    name = "Kniebeugen",
    desc = "Aus dem Stand runter und hoch.",
    short = "KB",
    order = 3,
    mode = "reps",
    duration = 1.0,
    poses = { start = "stand", low = "squat_down" },
    camHeight = 48,
    signHeight = 88,
}

E["jumpingjacks"] = {
    name = "Hampelmann",
    desc = "Arme und Beine auf und zu. Schnellste Übung.",
    short = "HM",
    order = 4,
    mode = "reps",
    duration = 0.7,
    poses = { start = "stand", low = "jack_open" },
    camHeight = 50,
    signHeight = 92,
}

E["burpees"] = {
    name = "Burpees",
    desc = "Runter, Stütz, hoch, Sprung. Zählt doppelt in der Gruppe.",
    short = "BP",
    order = 5,
    mode = "reps",
    duration = 2.0,
    groupWeight = 2,
    poses = { start = "stand" },
    cycle = {
        { 0.00, "stand" },
        { 0.20, "squat_down" },
        { 0.42, "pushup_up" },
        { 0.62, "squat_down" },
        { 0.80, "burpee_jump" },
        { 1.00, "stand" },
    },
    space = Vector(80, 40, 0),
    camHeight = 40,
    signHeight = 88,
}

E["pullups"] = {
    name = "Klimmzüge",
    desc = "An der Klimmzugstange hoch und runter.",
    short = "KZ",
    order = 6,
    mode = "reps",
    duration = 1.3,
    needsBar = true,
    poses = { start = "pullup_hang", low = "pullup_top" },
    camHeight = 60,
    signHeight = 100,
}

E["plank"] = {
    name = "Planke",
    desc = "Unterarmstütz. E halten, loslassen beendet.",
    short = "PL",
    order = 7,
    mode = "hold",
    hold = "hold",
    poses = { start = "plank" },
    space = Vector(80, 40, 0),
    camHeight = 22,
    signHeight = 48,
}

E["running"] = {
    name = "Laufen auf der Stelle",
    desc = "E startet und stoppt das Zählen.",
    short = "LA",
    order = 8,
    mode = "hold",
    hold = "toggle",
    poses = { start = "stand" },
    loop = {
        dur = 0.7,
        frames = {
            { 0.00, "run_mid" },
            { 0.25, "run_a" },
            { 0.50, "run_mid" },
            { 0.75, "run_b" },
            { 1.00, "run_mid" },
        },
    },
    camHeight = 50,
    signHeight = 90,
}
