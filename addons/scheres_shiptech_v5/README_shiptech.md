# ShipTech – Schiffstechnik, Wartung & Event-System (Garry's Mod)

## Installation
1. Den Ordner `shiptech_wartung` nach `garrysmod/addons/` kopieren.
2. Die Model-Packs (KingPommes, LordTrilobite ISD, Reizer Props) müssen auf Server und Clients installiert sein.
3. Server neu starten.
4. Konsolen über das Spawnmenü → **Entities → ShipTech – Schiffstechnik** platzieren (nur Admins).
5. Danach in der Serverkonsole bzw. als Superadmin **`shiptech_save`** ausführen – die Konsolen werden pro Map gespeichert und beim Mapstart automatisch gespawnt.

## Konsolen (Entities)
Über **jeder** Konsole schwebt ein Hologramm mit Name, Zweck, Status und Zustandsbalken.

| Entity | Model | Zweck |
|---|---|---|
| Brücken-Kontrollterminal | bridge_console4 | Übersicht, Alarme, Navy-Freigaben, Gefechtsalarm |
| Technik-Kontrollterminal | bridge_console2 | Wartungsaufträge, Energieverteilung, Berichte, Protokoll, Fortbildungen |
| Reaktorsteuerung | console_03 | Reaktor hochfahren (Systemscan im Chat), Notabschaltung |
| Schildgenerator-Steuerung | imp_console_medium02 | Schildgrafik als Hologramm, Sektorverstärkung |
| Geschützkalibrierung | imp_console_medium03 | Kalibrierung & Reparatur der Geschütze |
| Triebwerkssteuerung | console_02_2 | Unterlichttriebwerke |
| Hyperantriebskern | console_02_2 | Hyperantrieb |
| Sensorphalanx | imp_console_medium02 | Sensortests, Kalibrierung |
| Kommunikationsrelais | imp_console_medium03 | Kommunikation |
| Kühlsystem-Steuerung | console_03 | Kühlkreislauf |
| Energieverteiler | bridge_console2 | Energienetz, Energieverteilung |
| Schildstatus-Anzeige | circle_console_wallmount | Großes Schild-Hologramm (Wanddisplay) |
| Sektor-Energieverteiler | circle_console_wallmount | Stromversorgung eines Sektors. Namen per **C-Menü → Rechtsklick → Edit Properties** setzen |

Models und Texte können in `lua/shiptech/sh_config.lua` (`ShipTech.ConsoleTypes`) geändert werden.

## Verbundene Konsolen
- **Reaktorsteuerung und Energieverteiler zeigen dasselbe**: Beide öffnen die **Energiezentrale** mit Reaktor (Leistung, Auslastung, Temperatur, Notstrom), Energieverteilung aller Systeme und Netzstatus. Auch die Hologramme darüber sind identisch. Die Energieverteilung kann an beiden Konsolen geändert werden. Nur die Aktionen rechts gehören zur jeweiligen Konsole (Reaktorstart oder Netzreparatur).
- Jede Systemkonsole zeigt ihre **Energieversorgungskette** `REAKTOR → NETZ → SYSTEM` mit animiertem Energiefluss.

## Neu in Version 2

### Werkzeuge
- **Datapad** (`st_werkzeug`): Reparatur, Diagnose, Wartung, Kalibrierung und Testlauf gehen nur mit dem Werkzeug in der Hand. Während der Arbeit gibt es Schlag-Animation, Funken und Metallgeräusche. Wer das Werkzeug wegsteckt, bricht die Arbeit ab. Linksklick bedient die Konsole, Rechtsklick ist ein Schnellscan, und beim Anvisieren erscheint eine Statusanzeige.
- **Feuerlöscher** (`st_loescher`): Linksklick halten zum Löschen. Das Löschmittel lädt sich langsam wieder auf.
- Spieler aus `C.TechnicianTeams` bekommen beides automatisch. Ist die Liste leer, holt man sie über das Spawnmenü (Weapons → ShipTech).

### Brände & Kettenreaktionen
- Kritische Schäden, Überhitzung, Hüllentreffer und fehlgeschlagene Hyperraumsprünge können Brände auslösen. Es gibt Flammen, Rauch, Licht und Knistern.
- Ein Brand beschädigt das System laufend, heizt es auf, verletzt Personen in der Nähe und kann auf Nachbarkonsolen übergreifen. Solange es brennt, ist keine Reparatur möglich.
- Ohne Kühlung heizt der Reaktor auf. Ein beschädigtes Energienetz lässt Systeme kurz ausfallen (und das Licht flackern). Ein überhitzter Reaktor (ab 95 %) verursacht Überspannungen, die das Netz beschädigen.

### Brücke
- **Startcheckliste**: 8 Schritte (Reaktor → Kühlung → Netz → Schilde → Sensoren/Kommunikation → Navy-Freigabe → Triebwerke → Geschütze). Die Navy bestätigt jeden Schritt, sobald er erfüllt ist.
- **Hyperraumsprung**: Kurs berechnen (Minigame Navigationscomputer, Dauer abhängig von den Sensoren), Energie umleiten, Countdown, Sprung mit Blitz und Sternenstreifen. Schlecht gewartete oder beschädigte Hyperantriebe können versagen. Fällt der Hyperantrieb im Hyperraum aus, folgt ein Notaustritt.
- **Schiffsstatus-Wand** (`shiptech_status_wall`): großes Wandhologramm mit allen Systemen, Schilden, Energie, Checkliste, Hyperraum und Alarmen.

### Event-Menü: Reiter „Abläufe“
- **Szenario-Vorlagen** mit einem Klick: Hinterhalt, Reaktorkrise, Sabotage, Systemkollaps, Asteroidenfeld, Brand im Maschinenraum. Eigene Vorlagen lassen sich in `ShipTech.Scenarios` ergänzen.
- **Eigene Abläufe**: Schritte mit Zeitpunkt (z. B. `2:00` Kühlmittelproblem, `5:00` Reaktornotfall) zusammenstellen und starten. Laufende Abläufe sind sichtbar und lassen sich stoppen.

### Anbindungen
- **Funksystem (crypto_radio)**: Ist die Kommunikation kritisch, werden Funksprüche gestört (Zeichensalat wie beim Störsender). Ist sie ausgefallen, fällt zusätzlich der Langstreckenfunk aus. Am Funksystem muss nichts geändert werden.
- **Beleuchtung (SSE Lightswitch, sse_106)**: Bei Totalausfall der Energie oder ausgefallenem Energienetz geht auf der ganzen Map das Licht aus. Nach der Reparatur geht es wieder an. Bei Treffern und Energieschwankungen flackert es. Ohne Energie lässt sich der Lichtschalter nicht einschalten. Dafür wurde `sse_lightswitch.lua` um `SSE.SetLights()`, `SSE.GetLights()` und den Hook `SSE_CanTurnLightsOn` erweitert. Ohne SSE schaltet ShipTech die Map-Lichter selbst.
- **Fahrzeuge (LVS/LFS/Turrets)**: Unter `C.Vehicles.ShipClasses` eingetragene Schiffs-Entities leiten Schaden zuerst auf die Sektor-Schilde (Richtung wird berechnet). Ihre Höchstgeschwindigkeit hängt an den Triebwerken. Bei `GunClasses` hängt der Schaden von Feuerbereitschaft und Zielgenauigkeit ab, ohne Energie feuern sie ins Leere.

### Bedienung & Admin
- **Lernhilfe**: Jeder Button hat einen Tooltip, der erklärt, was er tut bzw. warum er gesperrt ist. Jede Konsole zeigt den **nächsten Schritt**, und über den Button **LERNHILFE** öffnet sich das Techniker-Handbuch (auch per `shiptech_handbuch`).
- **Ingame-Konfiguration**: `!shiptechadmin` im Chat oder `shiptech_admin` in der Konsole (nur Superadmin). Rechte, Zeiten, Energie, Brände, Hyperraum, Fahrzeuge, Funk, Licht und alle Konsolen-Models lassen sich einstellen und werden sofort übernommen (gespeichert in `data/shiptech/config.json`).

### Performance
- Es werden nur noch geänderte Teile des Schiffszustands übertragen, nicht mehr alles.
- Konsolen werden in einem Register geführt, statt ständig alle Entities zu durchsuchen.
- Hologramme zeigen volle Details nur aus der Nähe und beim Hinsehen. Die Schildgrafik wird nur etwa 15x pro Sekunde als Textur gezeichnet und dann überall wiederverwendet.
- Zweistufiger Takt: Energie, Temperatur und Schilde jede Sekunde, Verschleiß und Zufallsstörungen alle 30 Sekunden.

## Design
Gleiches Design wie das Militärische Funksystem: dunkle, flache Panels, gelber Akzent, Bebas Neue / Montserrat, Kopfzeile mit gelber Linie, Eckmarkierungen, Abschnitte mit gelbem Balken.

## Schildanzeige
- **Außenring** (60 Segmente): Gesamtschildstärke in %, Farbe blau → gelb → rot.
- **Innenring**: die vier Sektoren Bug / Steuerbord / Heck / Backbord einzeln.
- Weiße Marke = maximale Kapazität bei aktueller Generator-Effizienz.
- Mitte: Sternzerstörer-Silhouette mit pulsierender Schildblase, Radar-Sweep, Trefferblitz bei Beschuss.
- Zu sehen über der Schildkonsole, an der Schildstatus-Anzeige, im Brückenterminal und im Event-Menü.

## Ablauf für Techniker
1. **Reaktor hochfahren** (Reaktorsteuerung) → Systemscan 10 % … 99 % → 100 % → „Reaktorscan abgeschlossen. Reaktorleistung stabil. Schilde werden hochgefahren.“
2. Systeme an ihren Konsolen **hochfahren**. Triebwerke und Hyperantrieb brauchen vorher eine **Navy-Startfreigabe** (Brückenterminal).
3. **Kühlsystem nicht vergessen**: Ohne Kühlung überhitzen Reaktor und Systeme, was zu einer Sicherheitsabschaltung führt.
4. Bei Störungen: **Diagnose** (Minigame „Fehlersuche“) → **Störungen einzeln beheben** (passendes Minigame + Reparaturzeit) → bei kritisch/ausgefallen **Testlauf** → **Wartungsbericht** → **Freigabe** durch einen Techniker mit Fortbildung „Systemfreigabe“.
5. **Routinewartung** und **Kalibrierung** regelmäßig durchführen, sonst steigt das Störungsrisiko. Unter 20 % Wartungszustand nimmt das System Schaden.

Schadensstufen: Betriebsbereit → Beschädigt (1 Störung, 70 % Leistung) → Kritisch (2 Störungen, 35 %) → Ausgefallen (3 Störungen, 0 %). Kritische Reparaturen verbrauchen **Ersatzteile**. Nachschub kann über das Brückenterminal angefordert werden.

### Minigames
Leitungen verbinden · Frequenzabgleich · Druckregulierung · Befehlssequenz · Synchronisation · Fehlersuche · Testlauf. Im **Gefechtsalarm** gibt es 30 % weniger Zeit.

## Auswirkungen auf das Gameplay
- Schilde: Kapazität und Regeneration hängen von Zustand und Energie ab. Treffer, die durch einen leeren Sektor gehen, beschädigen zufällige Systeme.
- Triebwerke → Geschwindigkeit, Geschütze → Feuerbereitschaft und Zielgenauigkeit (Kalibrierung), Sensoren → bei unter 50 % zeigt das Brückenterminal unzuverlässige Werte, Hyperantrieb → sprungbereit ab 60 % und mit Navy-Freigabe.
- Bei einem Kommunikationsausfall werden die Chatbefehle aus `C.CommsBlockedCommands` blockiert.
- Bei einem Stromausfall im Sektor wird es rund um den Sektor-Energieverteiler dunkel und die Konsolen dort verlieren Energie. Reparaturen bleiben im Handbetrieb möglich.
- Ohne Reaktor springt der **Notstrom** an und versorgt nur essentielle Systeme. Ist auch der Notstrom leer, fällt die Energie komplett aus.
- Automatische Notfallprotokolle: Reaktornotfall, kritisches Energieproblem, schwerer Antriebsschaden und Systemausfall, jeweils mit Sirene, HUD-Banner und rotem Bildschirmrand. Mit `shiptech_alarm_mute 1` lässt sich die Sirene stummschalten.

## Event-Menü: `/event` (oder `!event`, Konsole `shiptech_event`)
Nur für Gruppen aus `C.EventlerGroups`.
- **Systeme**: Schadensstufe wählen, Störung eines bestimmten Typs auslösen, abschalten, überhitzen, Kalibrierung verlieren, Wartungszustand setzen, sofort reparieren. Optional wird automatisch ein **Wartungsauftrag** mit eigenem Titel und eigener Beschreibung erstellt.
- **Schilde & Beschuss**: Sektorwerte setzen, Schilde deaktivieren oder schwächen, Einzeltreffer und Salven auf bestimmte Sektoren.
- **Störungen & Notfälle**: Kommunikationsausfall, Kühlmittelproblem, Energieüberlastung, Zufallsstörung, Reaktornotfall, Stromausfall pro Sektor, alle Alarme (inklusive Evakuierung mit Bereichsangabe), Gefechtsalarm, Ersatzteilmangel.
- **Aufträge**: eigene technische Situationen bzw. Aufträge für die Crew erstellen und stornieren.
- **Global**: Reaktor sofort an/aus, alle Systeme hochfahren, Navy-Freigaben, Zufallsstörungen an/aus, alles reparieren, Reset.

## Rechte & Fortbildungen
In `sh_config.lua`:
- `C.TechnicianTeams` – Jobs, die als Techniker zählen (leer = jeder).
- `C.NavyTeams` – Jobs mit Navy-Rechten (zusätzlich die Fortbildung „navy“).
- `C.EventlerGroups`, `C.AdminGroups`, `C.InstructorGroups` – Usergroups.
- `C.UseQualifications` – Fortbildungssystem an oder aus.

Fortbildungen werden im Technik-Terminal unter **Fortbildungen** vergeben (für Ausbilder und Admins). Sie werden in `data/shiptech/quals.json` gespeichert. Jeder Techniker hat automatisch die „Grundausbildung Technik“.

## Protokoll
Alle Schäden, Reparaturen, Wartungen, Freigaben, Alarme, Energieänderungen und Event-Aktionen landen
- im Terminal unter **Protokoll** (filterbar) und
- in `data/shiptech/logs/JJJJ-MM-TT.txt`.
Wartungsberichte werden in `data/shiptech/reports.json` gespeichert.

## Admin-Befehle (Serverkonsole / Superadmin)
`shiptech_save` · `shiptech_load` · `shiptech_clear` · `shiptech_reset`

## API für andere Addons
```lua
ShipTech.GetEfficiency("engines")      -- 0 .. 1.15
ShipTech.GetShieldPercent()            -- 0 .. 100
ShipTech.GetModifiers()                -- { shield, shieldCap, speed, hyper, weapons, accuracy, sensors, comms }
ShipTech.DamageShields(amount, sector) -- (Server) Sektor 1-4, nil = zufällig
ShipTech.SetHealth(id, health, grund)  -- (Server)
ShipTech.AddFault(id, typ, grund)      -- (Server)

hook.Add("ShipTech_Modifiers", ...)    -- jeder Tick, Tabelle mit Gameplay-Werten
hook.Add("ShipTech_StageChanged", ...) -- id, alteStufe, neueStufe
hook.Add("ShipTech_Alarm", ...)        -- id, aktiv
hook.Add("ShipTech_ShieldHit", ...)    -- sektor, schaden, überschuss
```

## Neu in Version 3

- **Design wie das Charaktersystem:** BigNoodleTitling-Überschriften mit Aurebesh darunter, abgeschrägte Platten, Reiterleiste oben, Bernstein-Akzent. Die Design-Bibliothek `EOCUI` (`cl_eocui.lua`) nutzen auch GAR Logistik und ShipTech EVA.
- **Navigationsstation** (`shiptech_con_nav`): Am Brücken-Kontrollterminal wird der Hyperraumsprung nur vorbereitet (Kurs, Energie). Ausgelöst wird er ausschließlich an der Navigationsstation, dort gibt es auch Countdown-Abbruch, Rücksturz und Notsprung.
- **Meldungen nur für bestimmte Jobs:** Technik-Chatmeldungen bekommen nur Engineering, Navy und AVP (`C.Notify`). Mit GAR Logistik gelten deren genaue Jobnamen. HUD-Alarme sieht weiterhin jeder.
- **GAR-Logistik-Kopplung** (`sh_logistik.lua`): Reparaturen verbrauchen echtes Material aus dem Schiffslager, z. B. Kurzschluss → Sicherungen + Leitungen, Kühlmittelleck → Kühlmittel. Auch Wartung und Kalibrierung verbrauchen Material. „Ersatzteile anfordern“ wird zu einem echten Logistik-Antrag. Ohne Logistik gilt der alte Ersatzteilzähler.
- **5 Kühlkreisläufe** (Reaktor, Triebwerke, Waffen/Türme, Hyperantrieb, Schiff) mit Füllstand, Druck, Lecks, Überdruckventilen und Nachfüllen. Dazu ein neuer Terminal-Reiter „Kühlung“.
- **Inspektionen:** Prüfschritte je System (Reaktorkern, Reaktordruck, Sicherheitsventile, Leitungen …). Sie heben die Wartung und decken versteckte Störungen auf.
- **Verschleißfaktor:** hängt ab von Betriebsstunden, Last, Gefecht, Hitze, Energieversorgung, Kühlmittel, überfälligen Inspektionen und Schäden.
- **Erweiterbar:** Hooks `ShipTech_CanJump`, `ShipTech_ShieldRegenMul` und `ShipTech_EventMenuTabs`, außerdem `ShipTech.ExtraPersist` für eigene Entities (genutzt von ShipTech EVA).