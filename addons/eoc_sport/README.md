# EoC Sport

Sportsystem für Trainings: `/sport` öffnet das Menü, man wählt eine Übung, die Kamera geht in Third Person, und jeder Druck auf **E** ist eine Wiederholung. Über dem Kopf steht der Zähler.

## Bedienung

| Was | Wie |
|---|---|
| Menü öffnen | `/sport`, `!sport` oder `eoc_sport` in der Konsole |
| Wiederholung | **E** (während einer laufenden Wiederholung ignoriert) |
| Planke | **E** halten, loslassen beendet |
| Laufen auf der Stelle | **E** startet/stoppt das Zählen |
| Beenden | **Leertaste**, erneut `/sport` oder Zielwert erreicht |
| Gruppen-Aufforderung | **E** annehmen, **R** ablehnen |
| Takt (Ausbilder) | Knopf im Reiter „Gruppe“ oder `bind <taste> eoc_sport_takt` |

## Was drin ist

- Alle acht Übungen aus dem Konzept: Liegestütze, Sit-ups, Kniebeugen, Hampelmann, Burpees, Klimmzüge, Planke, Laufen auf der Stelle.
- Third-Person-Kamera über `CalcView` mit Wand-Trace und Ein-/Ausblenden über 0,4 s. Die Maus dreht nur die Kamera.
- Der Server führt den Zustand. E wird serverseitig über `KeyPress` gelesen, die Leertaste über `SetupMove`. Die Sperrzeit ist die Animationsdauer (`CurTime()`), mehr als 10 Drücke pro Sekunde werden ignoriert.
- Sperren beim Start: Boden, Fahrzeug, Wasser, Noclip, Neigung über 25°, freie Fläche, Schaden oder Schuss in den letzten 10 s, DEFCON, Bereiche, laufende Übung.
- Automatischer Abbruch bei Schaden, Tod, Jobwechsel, Fahrzeug, Wegschieben, 60 s AFK, DEFCON und beim Verlassen des Bereichs.
- Ausbilder-Reiter: Gruppentraining mit Aufforderung (10 s), Countdown, Live-Liste, Takt, Auswertung (Burpees zählen doppelt), Strafrunde, „Alle im Umkreis abbrechen“.
- Klimmzugstange `sport_pullup_bar` (Spawnmenü → Entities → EoC, nur Admins).
- Hooks: `EoCSport_CanStart(ply, übung)`, `EoCSport_Rep(ply, übung, zähler)`, `EoCSport_Finished(ply, übung, zähler, zielErreicht)`, zusätzlich `EoCSport_GroupFinished(ausbilder, übung, ziel, ergebnisse, abgebrochen)`.

## Animationen

Gestartet wird mit Weg B/C (Bone-Posen). Jede Pose hat eine Körperneigung (Render-Winkel um einen Drehpunkt) und für Arme, Beine und Wirbelsäule eine **Zielrichtung** (`aim`, z. B. `V(0, 0, -1)` = senkrecht nach unten). Den passenden Bone-Winkel berechnet der Client in jedem Bild aus der echten Lage des Models. Dadurch hängt nichts davon ab, wie die Bones im Klon-Model ausgerichtet sind.

Feinjustieren:

1. Als Admin `eoc_sport_posetool` in die Konsole eingeben.
2. Pose und Bone wählen, dann die Richtungsregler (vorn/links/oben) bewegen. Mit „Abspielen“ läuft eine ganze Wiederholung in Schleife.
3. „Als Lua kopieren“ und den Block in `cl_poses.lua` ersetzen (`V` = `Vector`).

Für Weg A trägt man bei der Übung `sequence = "name"` ein. Hat das Model diese Sequenz, wird sie statt der Posen abgespielt (Zyklus 0 → 1 pro Wiederholung).

## Offene Fragen aus dem Konzept: aktuelle Standardwerte

Alles steht in `lua/eoc_sport/sh_config.lua`:

- **Animationen:** Bone-Posen (siehe oben).
- **Ausbilder:** zur Zeit nur die SAM-Gruppen `superadmin`/`admin`. Jobs in `C.InstructorJobs` eintragen, Unteroffiziere über `C.InstructorCategories`.
- **Zonen:** überall erlaubt (`C.Zones` leer).
- **Ergebnisse:** werden nicht gespeichert. Der Hook `EoCSport_Finished` ist der Anknüpfungspunkt für Bestwerte oder das Datapad.
- **Beenden-Taste:** Leertaste (`C.EndKey`).

## Noch anzupassen

- **DEFCON:** `C.GetDefcon` liest `EoCDefcon.GetLevel()` oder `GetGlobalInt("EoC_DEFCON")`. Falls das DEFCON-Addon anders heißt, hier anpassen.
- **SymChars:** Für Charakternamen `C.CharacterName` ausfüllen. Ohne Eintrag wird der DarkRP-Name genutzt.
- **Schriften:** Bebas Neue und Montserrat müssen auf dem Client installiert sein, sonst nutzt GMod eine Ersatzschrift.
