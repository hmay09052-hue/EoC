# EoC Droids

KUS-Nextbots für Echoes of Clones. Das Addon ersetzt die beiden Addons
`summenextbots_master_v1_4_1` und `summenextbots_dlc_cis_01` (Basis: SummeNextbots von Summe).

**Wichtig:** Die alten Summe-Addons vom Server entfernen. Sie brauchen die nicht enthaltene
`SummeLibrary` und erzeugen sonst weiter Lua-Fehler.

## Was wurde behoben

- Läuft eigenständig: keine `SummeLibrary`, keine `rw_sw_*`-/TFA-Effekte mehr nötig.
- Undefinierte Funktionen (`SY_RoundedBox` im Dispenser), Zugriffe auf NULL-Entities (Gegner, Waffe,
  Türen, Timer) und fehlende Attachments behoben.
- Fehlende Models und Sounds lösen keine Fehler mehr aus: Es gibt Fallback-Models und HL2-Ersatzsounds,
  und fehlender Content wird einmalig in der Server-Konsole aufgelistet.
- Magazin-Bug behoben: Das Magazin wurde nie leer.
- Raketen fliegen auf den Gegner statt geradeaus.
- Der Krabbendroide verursacht beim Spawnen keinen Schaden mehr.
- Ein Droideka explodiert nicht mehr beim Aufräumen bzw. Undo.
- Die Netzwerk-Nachrichten der Tools konnten manipuliert werden. Die Tools lesen jetzt ihre ConVars
  serverseitig und prüfen die Admin-Rechte.

## Droiden

| Klasse | Name | Besonderheit |
|---|---|---|
| `npc_eoc_b1` | B1 Kampfdroide | Standard-Infanterie, Trupp-Verhalten, Granaten |
| `npc_eoc_b1_officer` | B1 Offiziersdroide | Repariert Droiden in der Nähe, alarmiert weit |
| `npc_eoc_b1_heavy` | B1 Schwerer Kampfdroide | Hohe Feuerrate, Panzerung |
| `npc_eoc_b1_sniper` | B1 Scharfschützendroide | Große Reichweite, sichtbarer Ziellaser vor dem Schuss |
| `npc_eoc_b1_jetpack` | B1 Jetpack-Droide | Springt mit dem Jetpack und flankiert |
| `npc_eoc_b1_breacher` | B1 Breacher-Droide | Schrotblaster, sprengt verschlossene Türen auf |
| `npc_eoc_b2` | B2 Superkampfdroide | Größer (x1.4), schwer gepanzert, Nahkampf, packt und wirft Spieler |
| `npc_eoc_b2_rocket` | B2-RP Raketen-Superkampfdroide | Raketensalven |
| `npc_eoc_b2_jetpack` | B2-X Jetpack-Superkampfdroide | Jetpack, Raketen aus der Luft |
| `npc_eoc_bx` | BX Kommandodroide | Schnell, weicht Beschuss mit Rollen aus |
| `npc_eoc_bx_captain` | BX Kommandodroide Captain | Verstärkt Droiden in der Nähe (Feuerrate, Panzerung) |
| `npc_eoc_bx_vibroblade` | BX Vibroklingen-Droide | Reiner Nahkampf mit Sprungangriff |
| `npc_eoc_droideka` | Droideka | Rollt, Deflektorschild (anfällig gegen Explosionen) |
| `npc_eoc_magnaguard` | IG-100 MagnaGuard | Elektrostab, wehrt Blaster ab, steht kopflos wieder auf |
| `npc_eoc_crab` | LM-432 Krabbendroide | Sprung mit Schockwelle |
| `npc_eoc_aqua` | Aqua-Droide | Ionen-Entladung gegen mehrere Ziele |

Die Droiden findest du im Spawnmenü (Entities und NPCs) unter **EoC Droiden**. Standardmäßig können
nur Admins sie spawnen.

## Tools (Kategorie „EoC Droiden“)

- **Droiden-Boarding-Pod**: Der Pod bohrt sich durch Decken und setzt die gewählten Droiden ab.
- **Droiden-Dispenser**: Ein Container, der wahlweise vom Himmel fällt. Modell und Lebenspunkte
  sind einstellbar.
- **Droiden: No-Target**: Macht Spieler für Droiden unsichtbar.

## Leistung (30–60 Spieler)

- Eine Waffe ist kein eigenes Entity pro Droide. Das Waffenmodell existiert nur clientseitig.
- Bolzen, Mündungsfeuer und Einschlag laufen pro Schuss als ein einziger Netzwerk-Effekt.
  Dynamische Lichter sind begrenzt (`MaxDynamicLights`).
- Die KI entscheidet alle 0,15 s und bewegt sich jeden Tick. Droiden ohne Spieler in der Nähe schlafen.
- Sprachausgabe hat ein globales Limit pro Sekunde, die Zahl aktiver Droiden ist begrenzt (`MaxDroids`).

## Einstellungen

Alles steht in `lua/eoc_droids/sh_config.lua`, zum Beispiel Schaden und Leben, Friendly Fire,
Kopfschuss-Multiplikator, Jobs, die nicht angegriffen werden (`IgnoreTeams`), NPC-Ziele, Lichter und
Sprachausgabe.

## Konsolenbefehle

- `eoc_droids_clear` (Admin): entfernt alle Droiden, Pods und Projektile
- `eoc_droids_count`: zeigt die Anzahl aktiver Droiden
- `eoc_droids_debug` (Admin, Client): zeigt Reichweiten, Ziele und Hitboxen

## Benötigter Workshop-Content

Die Models und Sounds kommen aus dem Content der Summe-Nextbots bzw. der Droiden-Models, zum Beispiel
`models/npc/b1_battledroids/...`, `models/npc/b2_battledroid/...` und `sound/summe/nextbots/...`.
Fehlt etwas, nutzt das Addon Fallbacks. Was fehlt, steht beim Start in der Server-Konsole
(`[EoC Droids] Model fehlt ...`).

Ohne Navmesh laufen die Droiden direkt auf ihre Ziele zu. Für richtige Wegfindung auf der Map einmal
`nav_generate` ausführen.
