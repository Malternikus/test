# VOID DICE — ROLL. COLLECT. SURVIVE.

Roblox-RNG-/Collection-Spiel mit eigener 80s-Mystery-/Supernatural-IP.
**ROLL CHARACTERS. BUILD YOUR COLLECTION. GET RICH. FIND THE RAREST ENTITY.**

- 100 eigene Characters in 10 Rarities (Common … Secret, Anomaly 1 in 10M)
- Base mit bis zu 25 Slots, passives Einkommen, Level 1–15
- 6 Dice, 6 Gebiete, Rebirth mit dauerhaften Boni
- Rift Fishing, Gear, Potions, Relikte, Cosmetics, Titel
- Daily Quests, Achievements, Season Pass (Free + Premium)
- Collection Index, Mutationen, globale Ansagen, Leaderboards
- Server-autoritativ, session-sicheres Speichern, Anti-Cheat-Grundlage
- Mobile-first-UI, Tastatur- und Controller-Support

Design: **[docs/DESIGN.md](docs/DESIGN.md)** · alle Characters: **[docs/CHARACTERS.md](docs/CHARACTERS.md)** ·
Economy-Simulation: **[docs/ECONOMY.md](docs/ECONOMY.md)** · Tests: **[docs/TESTING.md](docs/TESTING.md)**

---

## 1. Schnellstart

1. `build/VoidDice.rbxlx` in Roblox Studio öffnen (*File → Open from File…*).
2. **Play** drücken. Map, Bases und alles andere baut der Server beim Start auf,
   deshalb ist die Welt im Edit-Modus leer.
3. Für echtes Speichern: *Game Settings → Security → Enable Studio Access to
   API Services* (dafür muss das Place einmal veröffentlicht sein, privat
   reicht). Ohne das läuft alles im Speicher, die UI zeigt dann einen Hinweis.
4. Mehrspieler testen: *Test → Clients and Servers → 2–4 Players → Start*.
5. In den Place-Einstellungen **Max Players = 8** setzen (8 Bases auf der Map).

> Die `.rbxlx` wird mit [Rojo](https://rojo.space) aus `src/` gebaut:
> `rojo build default.project.json -o build/VoidDice.rbxlx`.
> Live-Sync beim Entwickeln: `rojo serve` + Rojo-Plugin in Studio.

### Bestehendes Place („Soccer Dice“) umbauen

Das alte Soccer-Dice-Place liegt nicht in diesem Repo. Empfehlung: VOID DICE
als neues Place starten (oben) und Assets aus Soccer Dice, die du behalten
willst (z. B. Models oder UI-Bilder), per Copy & Paste nach
`ReplicatedStorage > VoidDiceAssets` übernehmen (siehe Abschnitt 4). Alternativ
im alten Place `rojo serve` verbinden: Rojo legt die drei Ordner unten an, der
Rest des Places bleibt unangetastet. Alte Scripts, die ebenfalls Remotes,
Leaderstats oder Spawns verwalten, vorher deaktivieren.

---

## 2. Explorer-Struktur

```
ReplicatedStorage
└── VoidDice
    ├── Config/          ← ALLE Zahlen und Inhalte (datengetrieben)
    │   ├── Characters/  ← 100 Characters, eine Datei pro Rarity
    │   ├── CharacterConfig, RarityConfig, MutationConfig, DiceConfig
    │   ├── EconomyConfig, RebirthConfig, AreaConfig, WorldConfig
    │   ├── FishingConfig, GearConfig, PotionConfig, CosmeticConfig
    │   ├── QuestConfig, AchievementConfig, SeasonConfig
    │   ├── MonetizationConfig, UIConfig, SoundConfig, GameConfig
    ├── Util/            ← RollMath (Odds-Mathematik), Odds, Stats (Formeln), Format
    ├── Visual/          ← ModelFactory (Placeholder-Models), AuraLibrary
    ├── Net              ← die 3 Remotes + Liste aller erlaubten Actions
    └── Remotes/         ← zur Laufzeit erzeugt

ServerScriptService
└── VoidDiceServer (Script)
    ├── Logic/           ← reine Spiellogik (Roll, Inventar, Economy, Upgrades,
    │                      Fishing, Items, Rebirth/Dice/Gebiete, Quests …)
    ├── Services/        ← Data, Session, AntiCheat, Roll, Economy, Character,
    │                      Progression, Goals, Base, World, Avatar, Leaderboard,
    │                      Announcement, Monetization, Debug
    └── World/           ← prozedurale Map (Hub, 8 Plots, 5 Gebiete, Road)

StarterPlayer > StarterPlayerScripts
└── VoidDiceClient (LocalScript)
    ├── State, Actions, Signal
    ├── UI/              ← Components, Cards, Viewport, Root (Skalierung)
    └── Controllers/     ← HUD, Reveal, Notifications, BaseAnimator,
        │                  BaseInteraction, Area, Ambience, Tutorial, Input,
        │                  Sound, WindowManager
        └── Windows/     ← Inventory, Character, Index, Shop, Quests, Rebirth,
                           Fishing, Items, Map, Settings, Inspect
```

Die UI wird per Code gebaut (kein StarterGui-Inhalt nötig).

**Server-Autorität:** Der Client darf nur Wünsche schicken, die in `Net.Actions`
stehen. Ergebnisse (Roll, Cash, Drops, Kosten, Luck) entscheidet der Server.

---

## 3. Neuen Character hinzufügen

Nur **eine** Datei anfassen, z. B. `Config/Characters/Epic.luau`:

```lua
{
	Id = "StaticRider",               -- eindeutig, nie umbenennen (wird gespeichert)
	DisplayName = "Static Rider",
	Rarity = "Epic",
	RollChance = 1400,                -- "1 in X" bei Luck 1
	BaseMoneyPerSecond = 63,
	BasePower = 32,
	BaseFishingPower = 12,
	MaxLevel = 15,
	Category = "Human",               -- Human | Creature | Entity
	VisualTheme = "BMX rider in a static-charged jacket",
	Description = "…",
	ModelReference = "Procedural:StaticRider",  -- oder "Asset:StaticRider"
	AuraReference = "Static",         -- Id aus Visual/AuraLibrary oder nil
	AnimationSet = "Default",         -- siehe UIConfig.AnimationSets
	Source = "Original",              -- bei Lizenzinhalten: Lizenzgeber
	ReleaseEnabled = true,            -- false = nicht rollbar, Besitz bleibt
	Visual = { Body = "Adult", Top = Color3.fromRGB(40, 40, 60), Accessories = { "Jacket", "Headphones" } },
},
```

Danach `cd tests && lune run test_characters.luau`: Der Test prüft Ranges,
Tier-Summen, Vokabular und baut das Model.

---

## 4. Echte Models statt Placeholder

1. Model in Studio bauen/importieren und nach
   `ReplicatedStorage > VoidDiceAssets > Characters > <Name>` legen.
2. Vertrag: `PrimaryPart` = Part „Root“ an den Füßen, alle Teile `Anchored`,
   `CanCollide = false`. Optional animierbare Gruppen (`Head`, `ArmL`, `ArmR`,
   `WingL`, `WingR`, `Tail`, `Orbit`, `Core`) als Models mit Part „Joint“ als
   Drehpunkt.
3. Im Character `ModelReference = "Asset:<Name>"` setzen. Fehlt das Asset,
   wird automatisch der Placeholder gebaut.

---

## 5. Vor dem Release eintragen

| Was | Wo |
|---|---|
| Gamepass-/Product-Ids | `Config/MonetizationConfig.luau` (Id 0 = „Coming soon“) |
| `StudioTestPurchases`, `StudioDebugTools` | wirken nur in Studio, können an bleiben |
| Sounds (eigene/lizenzierte) | `Config/SoundConfig.luau` (Platzhalter = eingebaute Roblox-Sounds) |
| Ambience/Musik je Gebiet | `SoundConfig.Ambience` (leer = Stille) |
| Max Players 8 | Place-Einstellungen |
| Cross-Server-Ansagen | `GameConfig.CrossServerAnnouncements` |

---

## 6. Steuerung

| Aktion | PC | Controller | Mobile |
|---|---|---|---|
| Roll | R / Button | R2 | großer ROLL-Button |
| Auto Roll | T | L2 | AUTO-Button |
| Collect | C oder grünes Pad | X | COLLECT-Button |
| Menüs | I, X, B, Q, F, G, M | Y (Inventar), R1/L1 blättern | Menü links |
| Fenster schließen | Esc | B | ✕ |
| Base-Character verwalten | E am Pad | X am Pad | Prompt antippen |

---

## 7. Tests und Werkzeuge (ohne Studio)

Benötigt [Lune](https://github.com/lune-org/lune) (0.8.x). Ein kleiner Roblox-Emulator
(`tests/harness.luau`) lädt die echten Module aus dem Rojo-Baum.

```bash
cd tests
lune run test_logic.luau        # Spiellogik, RNG/Luck, Speichern, Anti-Cheat
lune run test_characters.luau   # 100 Characters + 600 Model-Builds
lune run test_world.luau        # Map: Plots, Stationen, Gebiete, Budgets

cd ../tools
lune run simulate.luau 180 24 write   # Economy-Simulation -> docs/ECONOMY.md
lune run tune.luau 6 16               # Rebirth/Dice/Gebiets-Kosten an Zielzeiten anpassen
lune run gen_characters.luau          # docs/CHARACTERS.md neu erzeugen
```

**Studio-Debug:** Settings → DEBUG (nur in Studio): Cash geben, Rebirth bereit,
alle Potions/Gear, alles freischalten, 1000 Rolls, Reset.
