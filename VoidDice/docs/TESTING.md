# VOID DICE – Tests

## 1. Automatisch (Lune, ohne Studio)

Alle Tests laden die **echten** Module über `tests/harness.luau` (Roblox-Baum
aus `default.project.json`, `script.Parent`, `require(ModuleScript)`,
Roblox-Datentypen über `@lune/roblox`).

| Datei | Prüft |
|---|---|
| `tests/test_logic.luau` (38 Tests) | RollMath: Summe = 1 bei jeder Luck, exakte Luck-Multiplikation, Tier-Ziele, 300.000-Ziehungen-Statistik, Deckelung · Roll → Inventar/Index/Stats · Auto Place/Place Best · Verkaufen/Lock · Auto Delete (nur bis Epic, Neues/Mutiertes bleibt) · volles Inventar ersetzt Schwächsten, Hard Cap · Vault/Collect/Deckel · Upgrades 1→15 mit exakten Kosten · Dice/Gebiete/Rebirth-Bedingungen · Rebirth setzt nur Cash-Progression zurück · Fishing (Sperre, Slots, Fangrate, kein Base-Cash) · Loot-Tabellen · Gear (Slots, Cash-/Luck-Effekt) · Potions (Effekt, Stapeln, Ablauf) · Quests (Tag, einmal einlösen, deterministisch) · Achievements · Season/Premium · Gamepasses/Produkte (fester Inhalt) · Profil nach 2 h DataStore-tauglich (JSON, keine gemischten Tabellen, Größe) · Reconcile alter Profile · Transfer ohne Dupe · Remote-Spam-Drosselung + Kick · Argument-Validierung · keine „Give/Grant“-Actions · Cash-Sanity · getrennte Spielerprofile · Zahlformat |
| `tests/test_characters.luau` | 100 Characters, Anzahl je Rarity/Kategorie, Ranges, Tier-Summen, Vokabular, gesperrte Fremd-Namen, 600 Model-Builds (Level 15, Mutationen, LowDetail) mit Model-Vertrag und Part-Budget |
| `tests/test_world.luau` (4055 Checks) | 8 Plots mit 25 Slots, 4 Fishing-Seats, Pond, Collector, Schild, Lichtern · 5 Stationen · 5 Leaderboards · 5 Gebiete mit Tor/Altar/Ankunft · keine Überlappungen · Road frei begehbar · Part-/Licht-Budgets · deterministisch |
| `tools/simulate.luau` | Economy über 24 Spieler à 180 min → `docs/ECONOMY.md` |

Zusätzlich statisch geprüft: `rojo build` und `luau-lsp analyze` mit den
offiziellen Roblox-Typdefinitionen (keine unbekannten Globals, keine falschen
Requires, keine Arity-Fehler).

**Nicht automatisch testbar:** Client-UI, Animationen, echte DataStores,
MessagingService, Käufe, Touch/Controller. Dafür die Checkliste unten.

---

## 2. Manuell in Studio

Vorbereitung: Place öffnen, *Enable Studio Access to API Services*, Max Players 8.

| # | Bereich | Schritte | Erwartung |
|---|---|---|---|
| 1 | Roll | ROLL drücken | kurze Animation, Karte mit Name/Rarity/„1 in X“/$/s, NEW! beim ersten Mal |
| 2 | Auto Roll | AUTO an | Server rollt ~1/s; bei Legendary+ kurze Pause für das große Reveal |
| 3 | Luck | Luck-Pill anklicken; Settings → DEBUG → Potions, Luck-Potion benutzen | Aufschlüsselung stimmt, Luck x1.25; DEBUG „Roll 1000“ zeigt mehr seltene Rolls |
| 4 | 100 Characters | Index öffnen | 100 Einträge, ??? für unentdeckte, Odds-Tabelle |
| 5 | Inventory | Inventar öffnen, sortieren, filtern | Karten mit Level, $/s, Status-Icons |
| 6 | Base Placement | eigene Base besuchen | Characters stehen auf Pads, Billboards, Rand in Rarity-Farbe |
| 7 | Money/s | warten, COLLECT oder grünes Pad | Vault füllt sich, Cash steigt |
| 8 | Upgrade 1–15 | Character → UPGRADE bis 15 (DEBUG Cash 1e9) | $/s steigt, Aura bei 5/10/15, Ansage bei Epic+ Max |
| 9 | Fishing | Fishing-Fenster, Character schicken | sitzt am Pond mit Angel, Fänge als Toast, Ruck-Animation |
| 10 | Gear | Items → Gear → EQUIP | max 2 (3 ab Rebirth 4), Werte im Character-Fenster |
| 11 | Potions | Items → USE | Boost-Timer im HUD, Effekt in Luck/Cash |
| 12 | Rebirth | DEBUG RebirthReady → Rebirth | Cash/Level 0/1, Characters bleiben, +2 Slots, Auto Collect |
| 13 | Dice | Map → Dark Forest freischalten → Shop → Strange Dice | Luck x2, Dice-Button zeigt Strange |
| 14 | Areas | zur Signal Road laufen | Tor offen nur wenn frei, Licht/Nebel wechseln, Gebietsname |
| 15 | Rejoin / Data Save | Stop, Play | alles wieder da (mit API-Zugriff) |
| 16 | Mobile | *Test → Device Emulator* (iPhone/Android quer) | ROLL groß, Menü erreichbar, Fenster passen, keine Mini-Buttons |
| 17 | Controller | Gamepad anschließen | R2 Roll, L2 Auto, Y Inventar, R1/L1 Menüs, B schließt |
| 18 | Server Authority | Command Bar (Client): `game.ReplicatedStorage.VoidDice.Remotes.Action:FireServer("Debug","Cash",1e9)` im veröffentlichten Spiel | abgelehnt (nur Studio) |
| 19 | Remote Spam | Client: `for i=1,500 do game.ReplicatedStorage.VoidDice.Remotes.Action:FireServer("Roll") end` | max. Burst wird angenommen, Warnungen im Server-Log, bei Dauer-Spam Kick |
| 20 | Multiple Players | Clients and Servers, 3–4 Spieler | jeder eigene Base, fremde Bases sichtbar, Inspect am Schild, Ansagen bei allen |
| 21 | Leaderboards | 2 min warten | Boards im Hub gefüllt (mit API-Zugriff global, sonst Server-Spieler) |
| 22 | Käufe | Shop → TEST (STUDIO) | Pass/Produkt wird gewährt, VIP-Tag/Titel erscheinen |
| 23 | Tutorial | neues Profil (DEBUG Reset) | 6 Schritte, Rahmen um Ziel, SKIP funktioniert |
