# ShipTech EVA – Außenhülle (v2, vereinfacht)

Benötigt **ShipTech**. GAR Logistik ist optional und liefert dann die Hüllenplatten.

## Einrichten
1. Über das Spawnmenü unter **Entities → ShipTech – Außeneinsatz** platzieren:
   - **EVA-Ankerpunkte** an der Außenhülle: pro Sektor ein paar Stück. Den Sektor stellst du per C-Menü → Edit Properties ein (1 Bug, 2 Steuerbord, 3 Heck, 4 Backbord). Hier entstehen die Schadensstellen.
   - **EVA-Spind** in der Luftschleuse: gibt das Hüllenschweißgerät und Hüllenplatten aus und zeigt alle Schadensstellen.
   - **EVA-Versorgungspunkte** an der Hülle: mit E eine Hüllenplatte aufnehmen.
2. `shiptech_save` speichert alles zusammen mit den ShipTech-Konsolen.

## Ablauf
- Treffer durch leere Schildsektoren können **Hüllenbrüche** auslösen (Riss, Leck, Bresche). Eventler lösen sie im `/event`-Reiter **Außenhülle** aus.
- Solange ein Bruch offen ist:
  - Systeme im Sektor sind höchstens bis „Beschädigt“ reparierbar.
  - Die Schildregeneration ist halbiert.
  - Nach 5 Minuten wird der Bruch eine Stufe schlimmer.
- **Reparatur alleine** mit dem Hüllenschweißgerät: auf den Ankerpunkt zielen und Linksklick.
  1. Freilegen (nur Leck/Bresche)
  2. Hüllenplatte setzen (Leck 1, Bresche 2)
  3. Verschweißen (Minigame „Schweißpunkte“: Maustaste halten, Hitze steigt, im grünen Bereich loslassen)
  4. Leitungen prüfen (nur bei einer Störung im Sektor)

  Danach wird automatisch ein Wartungsbericht erstellt.
- Man kann bis zu **10 Hüllenplatten** tragen. Beim Tod gehen sie zurück ins Lager.
- Anzug und Sauerstoff werden nur per passivem RP ausgespielt.

## Einstellungen
In `lua/shiptech_eva/sh_config.lua` (`ShipTech.Config.EVA`) oder ingame unter `!shiptechadmin` → EVA:
- `MaxPlates`: Platten pro Person (Standard 10)
- `RequireQual`: zusätzlich die Fortbildung „Außeneinsatz (EVA)“ verlangen (Standard: aus, alle Techniker dürfen)
- `WorsenAfter`: Zeit, bis sich ein Bruch verschlimmert (0 = nie)
- `SectorSystems`: welche Systeme zu welchem Sektor gehören
