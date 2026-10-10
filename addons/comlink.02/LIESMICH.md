# Strivon Comlink

**Ein Addon** für alle Comlink-Systeme im Design von **SymChars**:

- **Helio Radio** – Sprachfunk
- **Kraken's Strike Squad** – Squad
- **Militärisches Funksystem** – Textfunk
- **Kraken's Medical System** – Medic, komplett mit drin (kein extra Medical-Addon mehr nötig)

Alle Apps laufen über dasselbe Comlink: Der linke Arm geht hoch, das Hologramm schwebt darüber.
Alle haben dieselbe Größe, dieselbe Position und denselben Stil.

## Bedienung (nur Ego-Perspektive)

| Taste | App |
|---|---|
| **H** | Funk |
| **G** | Squad |
| **J** | Textfunk |
| **K** (oder Chat-Befehl **!medical**) | Medic |
| gleiche Taste nochmal / ESC | Comlink schließen |
| andere App-Taste bei offenem Comlink | direkt umschalten – es ist immer nur **eine** App offen |

Mausrad scrollt die Liste bzw. das Raster unter der Maus. In der Third Person öffnet sich nichts,
es kommt nur ein Hinweis.

## Medic (K)

Gleicher Aufbau wie das Squad-Menü:

- **Kopf:** MEDIC + Aurebesh, rechts der Patient (du selbst oder wen du anschaust) in Einheitsfarbe,
  darunter Rang, Entfernung und Richtungspfeil. Bei dir selbst: Anzahl deiner Sanitätsmittel.
- **Zustand:** Triage, Herzstillstand/Bewusstlos, Blutet, Blutverlust, Schmerzen, Stabil, HLW.
- **Körper** (groß, links neben dem Menü) zum Anklicken, im Menü der **Befund** des gewählten Körperteils
  (Wunden, Verbände, Aderpresse, Brüche, Trauma, Infusionen, wirkende Medikamente).
- **Schnellleiste:** `PATIENT` / `ICH SELBST`, `HANDBUCH`, `VOLLES MENÜ` (altes 2D-Menü mit Einstellungen/Lager), bei Admins `ADMIN`.
- **Reiter:** Triage, Untersuchen, Behandlung, Medikamente, Erweitert, Tragen, Inventar, Protokoll.
- **Raster** (2 × 4, mehr per Mausrad, „SEITE x/y“): Behandlungen mit Vorrat (×Anzahl). Gesperrte sind
  ausgegraut, der Grund steht beim Drüberfahren im Infofeld.
- **Infofeld:** Beschreibung/Sperrgrund, während einer Behandlung Fortschrittsbalken mit Restzeit.

### Schnellbehandlung (Feld SCHNELL rechts neben dem Medic-Menü)

Startest du im Comlink eine Behandlung (Reiter Behandlung, Medikamente, Erweitert), erscheinen rechts im Feld SCHNELL die
**4 Pfeiltasten in zufälliger Reihenfolge**. Drückst du sie in der richtigen Reihenfolge (Pfeiltasten oder WASD),
ist die Behandlung **sofort fertig**. Eine falsche Taste = rot, die Folge beginnt von vorn. Ohne Pfeile läuft
die Behandlung ganz normal zu Ende (Restzeit unten im Feld).

- Die Pfeile stehen hochkant untereinander (von oben nach unten drücken), der aktuelle blinkt, darunter Richtung und `x / 4`
- nach Erfolg: `FERTIG` und wie viele Sekunden gespart wurden
- immer an (nur in der Server-Config abschaltbar)
- funktioniert unabhängig vom Stratagem-Modus im Medical-Admin

Während einer Behandlung kann man nicht laufen (Laufen bricht die Behandlung ohnehin ab).

## Squad (G) und Textfunk (J)

Unverändert, siehe Beschreibung der bisherigen Addons:
Squad = Mitgliederliste, Schnellleiste (Markieren/Feind/Namen), Reiter Befehle/Meldungen/Squads/Optionen.
Textfunk = Reiter Senden/Funklog/Befehle, Chat-Befehle `/funk`, `/vfunk`, `/lfunk`, `/vlfunk`, `/akt`, `/me`, `/eakt`, `/makt`, `/scan`.

## Einstellungen

`lua/helio_radio/sh_helio_config_general.lua`:

```lua
hradio.Config.ComlinkKey = KEY_H              -- Funk
hradio.Config.SquadEnabled = true
hradio.Config.SquadKey = KEY_G                -- Squad (wenn im Squad-Admin/Spieler-Einstellung nichts gesetzt ist)
hradio.Config.SquadVisibleMembers = 5
hradio.Config.MedicEnabled = true
hradio.Config.MedicKey = nil                  -- nil = Taste aus dem Medical-System (Standard K)
hradio.Config.MedicThirdPersonClassic = false -- true = in der Third Person das alte 2D-Medizinmenü
hradio.Config.MedicQuickTreat = true         -- Schnellbehandlung (Feld SCHNELL)
hradio.Config.MedicQuickTreatLength = 4      -- 4 = jede Pfeiltaste einmal, mehr = schwerer
hradio.Config.MenuScale = 0.021               -- Größe aller Hologramme
hradio.Config.MenuTopMargin = 0.1             -- freier Rand oben, nichts ragt in die HUD-Leiste (DEFCON)
hradio.Config.MenuUprightOffset = { Up = 1.5, Right = 0, Forward = 0 } -- Position über dem Comlink (alle Apps)
```

`lua/crypto_radio/sh_config.lua`: `ComlinkEnabled`, `ComlinkKey = KEY_J`, `ComlinkVisibleRecipients`, `ComlinkCloseAfterSend`.
Für den Textfunk wird **kein Datapad** mehr gebraucht – jeder Spieler kann senden und empfangen.

## Installation

1. Vom Server entfernen (sonst laufen Dateien doppelt):
   **Strivon Comlink + Squad** (`comlink_squad`), **Textfunk** (`comlink_textfunk`), **comlink_helio_radio**,
   **Strivon Comlink + Medic** (`strivon_comlink_medic`), alte **helio_radio**, **krakensquad** und
   **krakens-medical-system** (Lua-Teil).
2. Den Ordner `strivon_comlink` nach `garrysmod/addons/` kopieren.
3. Weiterhin nötig: **Kraken's Framework (KF)**, **VManip**, **SymChars** (Design und Einheits-Squads) und der
   Workshop-Inhalt von Squad/Medical (Icons/Sounds, wird per `resource.AddWorkshop` verteilt).

## Konsole

`hradio_comlink` (Funk), `hradio_squad` (Squad), `crypto_radio_comlink` (Textfunk), `hradio_medic` / `kms_menu` (Medic),
`hradio_comlink_debug` (Fehlersuche: zeigt Tasten, geladene Apps, Arm-Status).
