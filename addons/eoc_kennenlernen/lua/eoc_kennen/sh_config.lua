-- Kennenlernen-System (SymChars)
-- Fremde Spieler sieht man nur als Rang + RP-ID (z.B. "Sergeant CT-3274").
-- Erst nach /f (Spieler anschauen) sieht man den vollen Namen ("CT-3274 Gold").
-- Gespeichert wird pro Charakter: ein zweiter Charakter kennt niemanden.

EOC_KENNEN.Config = {
    -- Chat-Befehle zum Kennenlernen (man muss den Spieler dabei anschauen)
    Commands = { "/f", "!f" },

    -- Maximale Entfernung zum Spieler (Units, ~52 Units = 1 Meter)
    MaxDistance = 150,

    -- true = beide lernen sich gegenseitig kennen, false = nur wer /f eingibt
    Mutual = true,

    -- Anzeige für Unbekannte. {rank} = Rang, {rpid} = RP-ID (z.B. CT-3274)
    UnknownFormat = "{rank} {rpid}",

    -- Namensschild über dem Kopf: Rang steht dort schon darunter, also nur die RP-ID
    UnknownOverheadFormat = "{rpid}",

    -- Falls jemand keine RP-ID hat
    UnknownFallback = "Unbekannt",

    -- Diese Benutzergruppen sehen immer alle Namen, z.B. { superadmin = true }
    -- Standardmäßig leer, sonst sieht man beim Testen als Superadmin alle Namen.
    SeeAllGroups = {},
}
