# GAR Logistik 2.0 – Kriegslogistik & Feldbasen (Echoes of Clones)

## Neu in 2.0
- **Design wie das Charaktersystem** (gemeinsame Bibliothek `EOCUI` mit ShipTech): abgeschrägte Platten, BigNoodleTitling-Überschriften mit Aurebesh, Bernstein-Akzent.
- **Feinere Güter in 7 Lagern** (die 7 bisherigen Güter bleiben erhalten, bestehende Spielstände funktionieren weiter):
  - **Munitionslager:** Blastermunition, Schwere Waffen, Raketen, Torpedos, Geschützmunition
  - **Medizinisches Lager:** Medkits
  - **Technisches Lager:** Ersatzteile, Sicherungen, Leitungen, Kühlmittel, Ersatzmodule, Elektronik, Werkzeug, Hüllenplatten
  - **Treibstofflager:** Treibstoff, Energiezellen
  - **Rationenlager:** Rationen, Wasser
  - **Material- und Speziallager**
- In der Detailansicht eines Standorts wird **jedes Lager mit Gesamtkapazität** angezeigt, z. B. „TECHNISCHES LAGER 7.420 / 10.000 FE“. Die Übersicht zeigt nur die wichtigsten Güter.
- Neue Güter in bestehenden Spielständen starten automatisch mit ihrem Startbestand.
- **ShipTech** bucht Material für Reparaturen, Wartung, Kalibrierung und Kühlmittel direkt aus dem Venator-Lager ab und stellt bei Mangel echte Versorgungsanträge. **ShipTech EVA** holt Hüllenplatten aus dem Lager.

Alle anderen Funktionen (Anträge, Genehmigung, Shuttles, Container, Produktion, Feldbasis mit Bauplan-Hologramm, SSE-Ausstattung, Rollen über genaue Jobnamen) sind unverändert. Die Einstellungen stehen in `lua/gar_logistik/sh_config.lua`.