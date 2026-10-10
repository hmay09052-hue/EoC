# GAR Datapad

Klon-Datapad für Star-Wars-RP im Easzy-Tablet. Wer das Datapad über seinen Job hat, wählt es im Inventar aus. Der Klon nimmt das Tablet hoch, und die ganze Oberfläche läuft **auf dem Bildschirm des Tablets in der Hand**. Es gibt dafür keinen Befehl und keine Taste.

## Voraussetzungen

| Was | Wofür |
|---|---|
| **SymChars** (getestet gegen 2.0 und 4.5) | Charaktere, Einheiten, Ränge, Fortbildungen, Aurebesh, Netzwerk (Pflicht) |
| **Easzy's Tablet F4**, Inhalte (Workshop `2526015939`) | Modell und Animationen des Tablets (Pflicht) |
| DarkRP | Jobs (Datapad als Job-Waffe, Schocktruppen) |

## Installation

1. Den Ordner `gar_datapad` nach `garrysmod/addons/` kopieren.
2. Das alte `datapad_system` entfernen.
3. Bei Easzy's Tablet nur den Lua-Teil entfernen oder das Addon ganz löschen. Die Modelle lädt das Datapad selbst über den Workshop.
4. **Datapad in die Jobs eintragen.** Nur wer es als Job-Waffe hat, bekommt es. Beispiel in `jobs.lua`:
   ```lua
   weapons = { "mvp_perfecthands", "weapon_fists", "gar_datapad" },
   ```
5. `lua/gar_datapad/sh_config.lua` prüfen und den Server neu starten.

## Bedienung

- **Öffnen:** Datapad in der Waffenauswahl wählen. Es öffnet sich automatisch.
- **Zurück:** Knopf **ZURÜCK** oben links oder `ESC`. Das geht immer genau einen Schritt zurück: offener Dialog → geöffneter Eintrag / Systemdaten → vorheriger Bereich → Startseite.
- **Schließen:** `ESC` auf der Startseite oder das X oben rechts. Danach kommt die vorherige Waffe zurück.
- Die Bereiche wechselt man über die **Reiter oben**.
- Laufen geht weiter, solange kein Textfeld aktiv ist. `ESC` in einem Textfeld beendet nur die Eingabe.

## Bereiche

| Bereich | Zugriff | Inhalt |
|---|---|---|
| **Personalakten** | alle | Stufe 1: eigene Akte, ab Stufe 2: eigene Einheit, ab Stufe 3: alle. Reiter Akte, Vermerke, Fortbildungen und Verlauf (aus SymChars) |
| **Strafakten** | **nur Schocktruppen-Jobs** (`ShockJobs`) | Strafregister mit Paragraph, Strafe, Status und Fahndung, dazu Fahndungsliste und Kodex. Admins haben nur mit `PenalAdminAccess = true` Zugriff |
| **Dienstberichte** | alle | Berichte schreiben und lesen. Jeder Typ hat eine Mindeststufe (Einsatzbericht = Stufe 3) |
| **Klassifiziert** | alle (anlegen ab Stufe 3) | Archiv nach Stufe 1–6 mit Entschlüsselungseffekt |
| **Galaxiekarte** | alle | 2.173 echte Systeme, Regionen, Raster, Hyperraumrouten, Suche, Lage der Klonkriege. Die Lage setzen kann man ab Stufe 5 |
| **Freigaben** | Admins / Stufe 6 | Sicherheitsstufen von Hand vergeben |

Einträge mit einer höheren Stufe als der eigenen sieht man nur geschwärzt. Der Server schickt den Inhalt dann gar nicht erst mit.

## Design

Gleicher Look wie das Charaktermenü (SymChars): schwarze Kopfleiste mit Reitern und Aurebesh, Bernstein-Akzent (`accentcolor` aus der SymChars-Config), cremefarbenes „AKTE“-Etikett, abgeschrägte Platten. Die Fußzeile ist in Aurebesh.

**Aurebesh** wird über SymChars als **Bild** gezeichnet (`cl_aurebesh.lua` in SymChars 4.5). Dafür muss beim Spieler keine Schrift installiert sein. Weitere Schriften aus dem Workshop trägst du unter `FontWorkshop` ein (Workshop-IDs). Die Schriftnamen stehen unter `Fonts`.

## Sicherheitsstufen

1. Normale Soldatendaten · 2. Einheiteninformationen · 3. Einsatzberichte · 4. Geheimdienstinformationen · 5. Jedi-/GAR-Klassifiziert · 6. Oberkommando

Die Stufe ist das Maximum aus `ClearanceByRank` (Rangnummer oder Rangname), `ClearanceByUnit` (pro SymChars-Einheit, gilt auch für Untereinheiten) und `ClearanceByJob`. Eine von Hand vergebene Stufe ersetzt die automatische. Admins haben immer Stufe 6.

## Daten

SQLite (`sv.db`): Tabellen `gdp_records`, `gdp_clearance` und `gdp_galaxy`.
