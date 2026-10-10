# EoC Range – Schießstand

## Einrichtung (Admin)

1. Ordner `eoc_range` nach `garrysmod/addons/` legen, Server neu starten.
2. Spawnmenü → Entities → **EoC Range**:
   - **Bahn-Terminal** zuerst setzen: jedes neue Terminal bekommt automatisch die nächste freie Bahn-Nr.
   - Ziele (**Zielscheibe**, **Klappziel**, **Bewegtes Ziel**, **Geiselziel**) übernehmen die Bahn des nächsten Terminals.
   - **Bahnzone** setzen und mit der Toolgun **EoC Range – Zone** aufziehen (Zone anklicken → Ecke 1 links → Ecke 2 rechts).
   - Parcours: **Startzone** und **Zielzone** mit derselben Nr. wie die Bahn.
   - **Ranglisten-Wand** an eine Wand setzen.
3. Einstellen über Rechtsklick → *Eigenschaften bearbeiten* (C-Menü): Bahn-Nr., Größe, Distanz in m
   (Präzision 25/50 m und Scharfschütze 100/150/200 m suchen ihre Ziele über die Distanz), Silhouette, Trefferpunkte,
   Reihenfolge, Strecke/Geschwindigkeit, erlaubte Disziplinen am Terminal.
4. `range_save` (Superadmin) speichert alles pro Map nach `data/eoc_range/maps/<map>.json` und in die DB.
   Beim Mapstart wird automatisch geladen. `range_load` / `range_clear` zum Neuladen/Entfernen.

Zonen und Bahn-Nummern sieht man nur mit Physgun oder Toolgun in der Hand.

## Bedienung

- **Spieler:** Terminal benutzen (E) → Disziplin wählen → *Lauf starten*. Trainingswaffe in der Hand, in der Bahnzone stehen.
- **Ausbilder/Admins:** `!range` im Chat oder `range_admin` in der Konsole.
  Reiter: Ranglisten · Bahnen · Prüfung · Disziplinen · Ergebnisse · Einstellungen.

## Konfiguration

Alles in `lua/eoc_range/sh_config.lua`. Schwellen, Einheitenebene (`UnitLevel`) und DEFCON-Sperre lassen sich
zusätzlich ingame ändern (`data/eoc_range/settings.json`).

## Schnittstellen für andere Addons

```lua
hook.Add("EoCRange_RunFinished", "x", function(ply, disziplin, ergebnis, istBestwert) end)
hook.Add("EoCRange_BadgeAwarded", "x", function(ply, stufe, ausbilder) end)
hook.Add("EoCRange_CanStart", "x", function(ply, bahn, disziplin) return false, "Grund" end)
hook.Add("EoCRange_IsInstructor", "x", function(ply) return true end)   -- Rollen überschreiben
hook.Add("EoCRange_GetSquad", "x", function(ply) return { ply, ... } end) -- anderes Squad-System
hook.Add("EoCRange_GetDefcon", "x", function() return 3 end)              -- anderes DEFCON-System

EoCRange.GetBadge(ply)              -- 0 .. 3 (Server); Client liest NW2 "EoCR_Badge"
EoCRange.GetBest(ply, disziplin)    -- Allzeit-Bestwert oder nil (Server)
EoCRange.DrawTabIcons(ply, x, y, s) -- Client: Abzeichen + Wochenpokal neben dem Namen im TAB zeichnen
```

Globale NW2-Werte: `EoCR_TrophyUnit`, `EoCR_TrophyName` (Wochenpokal). Spieler: `EoCR_Badge`, `EoCR_Unit`.

## Protokoll

`data/eoc_range/logs/JJJJ-MM-TT.txt` – jede Löschung, Vergabe, Sperre und Rücksetzung mit Name, SteamID und Grund.
