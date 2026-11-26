# 🎤 Musik Tycoon – „Vom Keller zur Legende“

Ein Roblox-Tycoon, in dem du dich vom Laptop-Beat im Keller bis zur Pop-Legende hocharbeitest.
Die komplette Map wird beim Start per Skript gebaut.

## Öffnen in Roblox Studio

1. `MusikTycoon.rbxlx` herunterladen
2. Roblox Studio → **Datei → Öffnen** → `MusikTycoon.rbxlx`
3. ▶ **Play** drücken

Zum Speichern im Studio: *Game Settings → Security → Enable Studio Access to API Services*.
Für das veröffentlichte Spiel: *Game Settings → Places → Max Players* auf **6** stellen (= Anzahl Studios).

## Projektaufbau

| Datei | Inhalt |
|---|---|
| `MusikTycoon.rbxlx` | Fertiger Place zum Öffnen in Studio (wird aus `src/` gebaut) |
| `src/server/MusikTycoonServer.server.lua` | Map-Aufbau + Spiellogik (ServerScriptService) |
| `src/client/MusikTycoonClient.client.lua` | GUI, Animationen, Wegweiser (StarterPlayerScripts) |
| `build.py` | `python3 build.py` baut die `.rbxlx` neu aus `src/` |
| `default.project.json` | Optional für [Rojo](https://rojo.space) |
| `original/` | Deine ursprüngliche Version (zum Vergleichen) |

## v4 – Behobene Bugs 🐛

1. **Spieler ohne Studio blieben für immer ohne Studio.** Kamen mehr als 6 Spieler auf den Server, bekamen sie auch dann kein Studio, wenn eines frei wurde. Jetzt gibt es eine Warteschlange, und das nächste freie Studio wird automatisch zugewiesen.
2. **Doppeltes Speichern beim Server-Ende.** `PlayerRemoving` und `BindToClose` haben beide gespeichert. Außerdem hat `BindToClose` nicht auf das Ende des Speicherns gewartet, sodass Daten verloren gehen konnten. Jetzt speichert jeder Spieler genau einmal, mit `UpdateAsync`, bis zu 3 Versuchen und einer Wartezeit von bis zu 25 s.
3. **Verdiente Beträge beim Verlassen gingen verloren.** Während gespeichert wurde, lief das Studio weiter. Jetzt wird zuerst das Studio freigegeben und danach gespeichert.
4. **Stiller Datenverlust bei einem DataStore-Ausfall.** Konnte der Spielstand nicht geladen werden, wurde er auch nicht gespeichert, und der Spieler erfuhr davon nichts. Jetzt gibt es 3 Ladeversuche und eine Warnung im Spiel.
5. **Kaputte Spielstände** (NaN, ∞, negative Werte, falsche Typen) konnten das Spiel zerstören. Alle geladenen Werte werden jetzt geprüft.
6. **Die Gesangskabine war rundum zu**, man kam nicht hinein. Sie hat jetzt eine Tür.
7. **Das Poolwasser schwebte über dem Rand.** Der Pool hat jetzt einen echten Rahmen, und das Wasser liegt darin.
8. **Unsichtbare Hitboxen bei tanzenden Figuren.** Die Figuren tanzen nur auf dem Client, ihre Kollision blieb aber an der alten Stelle stehen. Figuren haben jetzt keine Kollision mehr, die Podeste schon.
9. **Passives Einkommen gab Fans ohne Multiplikator.** Das war uneinheitlich zu den Droppern und ist jetzt behoben.
10. **Lag-Schutz:** höchstens 120 Tracks pro Studio.
11. **Autosave gestaffelt**, damit das DataStore-Limit bei vollem Server nicht überschritten wird.
12. **Doppelte Map**, falls das Skript zweimal eingefügt wird, wird abgefangen.

Alte Spielstände bleiben erhalten (gleicher `SAVE_KEY`).

## v4 – Neues Design ✨ („Neon Nights“)

- **Abendstimmung** mit Atmosphere, Bloom, Farbkorrektur und Sonnenstrahlen
- **Studios:** Neon-Wände in einer eigenen Farbe pro Studio, Eingangstor mit beidseitigem Namensschild, roter Teppich, Lautsprechertürme mit pulsierendem Licht, Pfeile für die Laufrichtung an den Fließbändern, Kassen mit Dach
- **Kauf-Buttons** mit Rahmen, Icon (🎵 Dropper, ✨ Deko, 💸 passiv), Preis und Nutzen (z. B. „+$6/s“)
- **Boulevard:** Eingangsbogen „MUSIK TYCOON“, Walk of Fame mit Sternen, Gehweg mit Neon-Bordstein, Palmen zwischen den Studios, Neon-Rahmen ums große Schild, Spotlights auf jedem Musiker-Podest
- **Animationen** (nur auf dem Client, ohne Server-Last): drehende Schallplatte, CD, Diamant und Hubschrauber-Rotor, pulsierende Neon-Lichter
- **Neues GUI:** Karriere-Panel mit Fortschrittsbalken (Fans und Geld bis zum nächsten Feature) und Einkommen pro Sekunde; skaliert automatisch auf dem Handy
- **Musiker-Status** über jedem Musiker: ✅ gefeatured / 🎯 als Nächstes / 🎯 JETZT FEATUREN! / 🔒
- **Wegweiser-Strahl:** Ein leuchtender Strahl zeigt dir den Weg zum Mega-Feature, zum Presswerk oder zum nächsten Musiker, sobald du ihn bezahlen kannst

## Einstellungen

Oben im Server-Skript unter `EINSTELLUNGEN`: Startgeld, Anzahl Studios, Fließband-Tempo, Mega-Feature-Intervall (zum Testen z. B. `60`), Boost, Album-Bonus. Auch alle Upgrades und Musiker lassen sich dort anpassen.
