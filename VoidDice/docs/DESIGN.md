# VOID DICE – Game Design

**Arbeitstitel:** VOID DICE
**Untertitel:** ROLL. COLLECT. SURVIVE.
**Pitch (5 Sekunden):** ROLL CHARACTERS. BUILD YOUR COLLECTION. GET RICH. FIND THE RAREST ENTITY.

Eigene Mystery-/Supernatural-IP im Stil von 80s-Kleinstadt-Mystery, Sci-Fi-Labor,
Parallelwelt und Creature-Horror. Die Stimmung spricht Fans solcher Serien an,
ohne fremde Figuren, Namen, Orte, Logos oder Musik zu verwenden.

---

## 1. Eigene Welt (IP)

| Element | Unser Name | Bewusst NICHT |
|---|---|---|
| Kleinstadt | **Milbrook** (Mystery Suburb) | keine reale/fremde Serienstadt |
| Wald | **Black Pines** (Dark Forest) | – |
| Labor | **Secret Lab, Level B4** | keine Nummern-Labore aus Serien |
| Riss in der Realität | **the Rift** / Rift Zone | – |
| Parallelwelt | **the Otherworld**: Türkis/Magenta, kristallin, gespiegelt | kein grau-aschiges „verkehrtes“ Abbild mit Ranken |
| Endgame | **the Void**: schwarzes Glas, violettes Gitter | – |
| Phänomen | **the Signal** / Static | – |

Die Characters sind eigene Archetypen (Mystery Kid, Arcade Kid, Monster Hunter,
Psychic Subject, Void Sheriff …) mit eigenen Namen, Silhouetten, Farben,
Ausrüstungen und Beschreibungen. Ein automatischer Test (`tests/test_logic.luau`)
prüft, dass keine bekannten fremden Namen in Character-Texten vorkommen.

**Lizenzierte Inhalte später:** Characters tragen `Source` und `ReleaseEnabled`.
Lizenzierte Figuren werden als normale Einträge in `Config/Characters/*.luau`
ergänzt (eigene Datei möglich), mit `Source = "<Lizenzgeber>"`. Ausschalten
(Lizenzende) = `ReleaseEnabled = false`: nicht mehr rollbar, Besitz bleibt.

---

## 2. Core Loop

```
ROLL → Character erhalten → in die Base stellen (Auto Place)
  → Base produziert Cash/s → einsammeln (später Auto Collect)
  → Characters upgraden (Level 1–15)
  → bessere Dice / Gebiete freischalten → seltenere Characters
  → REBIRTH (nur Cash-Progression zurück, dauerhafte Boni)
  → neue Gebiete, Dice, Fishing-Gewässer, Gear-Tiers → REPEAT
```

Nebenschleifen: **Rift Fishing** (Characters ohne Base-Platz fischen Potions,
Gear, Relikte, Cosmetics) · **Gear** (2–3 Slots) · **Potions** · **Daily Quests**
· **Achievements** · **Season Pass** · **Index** (+Luck pro Entdeckung) ·
**Social Flex** (Bases, Billboards, Ansagen, Leaderboards).

---

## 3. Systeme (wo im Code)

| System | Daten (Config) | Logik (Server) | Anbindung |
|---|---|---|---|
| Rarities | `RarityConfig` | – | – |
| 100 Characters | `CharacterConfig` + `Characters/*.luau` | `Logic/Rolling` | `RollService` |
| Roll / Luck | `DiceConfig`, `RebirthConfig`, `PotionConfig` | `Util/RollMath`, `Util/Odds`, `Logic/Modifiers` | `RollService` |
| Mutationen | `MutationConfig` | `Logic/Rolling` | – |
| Inventar/Base | `GameConfig` | `Logic/Inventory` | `CharacterService`, `BaseService` |
| Einkommen | `EconomyConfig` | `Logic/Economy`, `Util/Stats` | `EconomyService` |
| Upgrades 1–15 | `EconomyConfig` | `Logic/Upgrades` | `CharacterService` |
| Dice, Gebiete, Rebirth | `DiceConfig`, `AreaConfig`, `RebirthConfig` | `Logic/Progression` | `ProgressionService` |
| Fishing | `FishingConfig` | `Logic/Fishing` | `ProgressionService`, `BaseService` |
| Gear, Potions, Relikte | `GearConfig`, `PotionConfig` | `Logic/Items` | `CharacterService` |
| Quests, Achievements, Season | `QuestConfig`, `AchievementConfig`, `SeasonConfig` | `Logic/QuestTracker`, `Logic/Goals` | `GoalsService` |
| Cosmetics/Titel | `CosmeticConfig` | `Logic/Cosmetics` | `AvatarService`, `BaseService` |
| Monetarisierung | `MonetizationConfig` | `Logic/init` (grantPass/grantProduct) | `MonetizationService` |
| Speichern | – | `Logic/ProfileTemplate` | `DataService`, `SessionService` |
| Anti-Cheat | – | Economy-Validierung | `AntiCheatService` |
| Ansagen | `RarityConfig.Announce` | – | `AnnouncementService` |
| Leaderboards | `EconomyConfig.CollectionPoints` | `Logic/Economy` | `LeaderboardService` |
| Welt | `WorldConfig`, `AreaConfig` | – | `World/*`, `WorldService` |
| Models | `Characters` (`Visual`-Bauplan) | – | `Visual/ModelFactory` |

**Server-Autorität:** Der Client schickt nur Wünsche (`Net.Actions`, feste
Liste mit Argumenttypen). Roll-Ergebnis, Cash, Kosten, Drops, Upgrades,
Rebirth, Luck und Inventar entscheidet ausschließlich der Server.

---

## 4. Rarities und Odds

| Rarity | Tier-Chance (Luck 1) | $/s Basis | Reveal | Ansage |
|---|---|---|---|---|
| Common | Rest (~73,8 %) | 1–3 | instant | – |
| Uncommon | 1/5 | 4–7 | instant | – |
| Rare | 1/20 | 14–24 | klein | – |
| Epic | 1/100 | 50–80 | Flash | – |
| Legendary | 1/500 | 180–300 | Screen-Reveal | – |
| Mythic | 1/2,500 | 700–1.1K | + Zoom | Server |
| Supernatural | 1/10,000 | 2.6K–4.2K | große Sequenz | Server |
| Void | 1/50,000 | 10K–16K | Blackout | Server |
| Secret | 1/250,000 | 45K–70K | Glitch | **Global** |
| Anomaly | 1 in 2.5M / 5M / 10M | 220K–400K | Regenbogen | **Global** |

**Luck-Mathematik (ehrlich):** Jede seltene Chance wird exakt mit der Luck
multipliziert (`p = Luck / X`); Commons bekommen die Restwahrscheinlichkeit.
Bei extremer Luck wird von der seltensten Stufe abwärts gedeckelt, die Summe
bleibt immer 1. Die UI zeigt dieselben Zahlen, die der Server zieht
(`Util/Odds`). Getestet mit 300.000 Ziehungen gegen die Theorie.

Luck = DiceLuck × (1 + Rebirth% + Potion% + Gear% + Index% + VIP%) × (2 mit 2X LUCK)

---

## 5. Progression (Ziele)

| Zeit | Ziel |
|---|---|
| 0:00 | erster Roll |
| 0:20–0:30 | erster Character steht in der Base |
| ~1:00 | erstes Upgrade |
| ~2:00 | erster Rare |
| ~3:00 | Fishing frei |
| ~4:00 | erstes Gear / stärkerer Character |
| ~5:00 | **Rebirth 1** (+10 % Cash, +2 Slots, Auto Collect, Dark Forest) |
| ~8:00 | Strange Dice (x2 Luck) |
| ~15:00 | **Rebirth 2** |
| ~30:00 | Rebirth 3 → Secret Lab, Rift Dice |
| ~50:00 | Rebirth 4 (3. Gear-Slot) |
| ~75:00 | Rebirth 5 → Rift Zone, Psychic Dice |

Die tatsächlichen, simulierten Werte stehen in **[ECONOMY.md](ECONOMY.md)**.

---

## 6. Monetarisierung (fair)

Gamepasses: 2X CASH, 2X LUCK, FAST ROLL, +3 BASE SLOTS, VIP (+10 % Cash/Luck,
Tag, Gold-Lichter, Aura), SEASON PREMIUM.
Developer Products: Luck Boost (feste Potions), Cash Pack (Sekunden
Einkommen), Potion Pack (feste Anzahl).

**Nie:** bezahlte zufällige Characters, Robux-Lootboxen, Mystery Crates,
bezahlte Random-Mutationen. Käufe sind idempotent (Receipt-Ids im Profil).

---

## 7. Virale / clipbare Momente

- Vollbild-Reveal ab Legendary mit Flash, Zoom, Kamera-Shake; Glitch ab Secret, Regenbogen bei Anomaly
- Server-Ansage ab Mythic, Global (alle Server) bei Secret/Anomaly: „Player rolled THE ENDLESS! 1 in 2.5M“
- **DOUBLE SECRET**-Ansage beim zweiten Secret+ in einer Session
- Golden/Void-Mutation wird angesagt
- Riesige Fishing-Drops (Legendary+) werden angesagt
- Max-Level (15) eines Epic+ wird angesagt
- Bases zeigen jedem: Name, Rarity, Level, Mutation, $/s, Base Value, Rebirth

**Thumbnail-Kandidaten** sind in CharacterConfig mit `Thumbnail = true`
markiert (siehe [CHARACTERS.md](CHARACTERS.md)).

---

## 8. Art Direction

Roblox-stylized, übertriebene Silhouetten, auf Thumbnail-Größe unterscheidbar.
Menschen (Kids, Teens, Erwachsene, Lange, Kräftige) mit 80s-Ausrüstung;
Creatures (Vierbeiner, Krabbler, Blobs, Schlangen, Flieger, Schwärme);
High-Tier-Entities (schwebend, Kolosse, Orbs, Augen) mit Auren und Orbits.

UI: Dark Navy / Schwarz / Lila / Electric Blue / rote Akzente, dezente
CRT-Scanlines, moderne lesbare Schriften (keine Pixelschrift).

Die aktuellen Models sind **prozedurale Placeholder** aus Parts
(`Visual/ModelFactory`). Ein fertiges Model ersetzt den Placeholder über
`ModelReference = "Asset:<Name>"` (siehe README, Abschnitt „Echte Models“).

---

## 9. Später (vorbereitet, nicht in V1)

- **Steal/Raid:** `Logic/Inventory.transfer` (atomar, gesperrte Characters
  geschützt), `BasePower` je Character, Base Value. Fehlt: Spielregeln + Action.
- **Fuse:** Duplikate werden schon gezählt (Index.N).
- **Fast Roll** als Gamepass ist drin; „Instant Reveal“ ist eine UI-Option.
- **Offline-Einkommen:** bewusst aus (Vault-Deckel), leicht nachrüstbar in `Logic.onLoad`.
- **Weitere Seasons:** `SeasonConfig.Id` ändern, Tiers tauschen.
