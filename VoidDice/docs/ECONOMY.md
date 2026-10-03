# VOID DICE – Economy Report

Automatisch erzeugt von `tools/simulate.luau` mit der echten Server-Logik: 24 Spieler-Simulationen à 180 Minuten (Rechenzeit 64.7s).
Bot-Verhalten: Auto Roll, Auto Place, alle 10 s einsammeln, Upgrades mit ≤ 4 min Amortisation, Dice/Gebiete sofort, Rebirth sobald bezahlbar, Fishing/Potions/Gear/Quests aktiv. Keine Gamepasses.

## Rebirth-Zeitpunkte (Minuten seit Spielstart)

| Rebirth | Ziel | Median | schnell (P10) | langsam (P90) | erreicht von |
|---|---|---|---|---|---|
| 1 | ~5 | 4.6 | 3.7 | 6.0 | 24/24 |
| 2 | ~15 | 14.2 | 8.6 | 17.9 | 24/24 |
| 3 | ~30 | 32.8 | 16.9 | 36.3 | 24/24 |
| 4 | ~50 | 54.6 | 32.7 | 63.2 | 24/24 |
| 5 | ~75 | 75.2 | 45.0 | 100.2 | 24/24 |
| 6 | ~105 | 110.4 | 63.3 | 139.4 | 24/24 |
| 7 | ~140 | 121.3 | 84.7 | 164.9 | 21/24 |
| 8 | ~180 | 132.4 | 85.7 | 172.2 | 14/24 |
| 9 | – | 151.3 | 116.2 | 162.3 | 5/24 |
| 10 | – | 148.5 | 135.0 | 148.5 | 2/24 |

## Meilensteine (Median, Minuten)

| Meilenstein | Median | P10 | P90 |
|---|---|---|---|
| Erstes Upgrade | 0.2 | 0.2 | 0.2 |
| Fishing freigeschaltet | 1.8 | 1.3 | 2.3 |
| Erstes Gear | 3.8 | 2.1 | 8.3 |
| Erster RARE | 0.2 | 0.1 | 0.6 |
| Erster EPIC | 1.6 | 0.2 | 2.8 |
| Erster LEGENDARY | 2.7 | 1.0 | 5.5 |
| Erster MYTHIC | 7.9 | 2.1 | 24.2 |
| Erster SUPERNATURAL | 24.2 | 4.5 | 58.6 |
| Erster VOID | 74.7 | 30.4 | 137.2 |
| Erster SECRET | 76.6 | 28.6 | 142.4 |
| Erster ANOMALY | 110.3 | 109.4 | 118.5 |
| Gebiet DARK FOREST | 5.3 | 4.0 | 7.8 |
| Gebiet SECRET LAB | 35.7 | 20.6 | 42.5 |
| Gebiet RIFT ZONE | 81.9 | 49.0 | 107.2 |
| Gebiet OTHERWORLD | 140.4 | 93.7 | 155.3 |
| Gebiet THE VOID | – | – | – |
| STRANGE DICE | 6.0 | 4.2 | 8.8 |
| RIFT DICE | 40.4 | 24.5 | 48.3 |
| PSYCHIC DICE | 89.2 | 53.0 | 116.5 |
| VOID DICE | 138.4 | 105.7 | 167.4 |
| ANOMALY DICE | – | – | – |

## Verlauf (Median über alle Simulationen)

| Minute | $/s | Cash verdient gesamt | Luck | Rebirths | Rolls | Index | beste Rarity | Dice | Slots | Fänge |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | $231/s | $11.5K | x1.82 | 0 | 60 | 28 | Rare | Basic | 6 | 0 |
| 2 | $746/s | $38.4K | x1.84 | 0 | 118 | 38 | Legendary | Basic | 6 | 0 |
| 3 | $1.11K/s | $101K | x1.86 | 0 | 177 | 44 | Legendary | Basic | 6 | 4 |
| 5 | $4.05K/s | $558K | x1.88 | 1 | 296 | 51 | Legendary | Basic | 8 | 10 |
| 8 | $8.72K/s | $1.7M | x3.79 | 1 | 498 | 58 | Mythic | Strange | 8 | 22 |
| 10 | $12.7K/s | $3.42M | x3.85 | 1 | 638 | 61 | Mythic | Strange | 8 | 30 |
| 15 | $17.2K/s | $8.09M | x4.04 | 2 | 936 | 65 | Mythic | Strange | 8 | 56 |
| 20 | $25.4K/s | $14.1M | x4.08 | 2 | 1,219 | 68 | Mythic | Strange | 8 | 102 |
| 30 | $45.6K/s | $35.2M | x4.14 | 2 | 1,796 | 72 | Supernatural | Strange | 8 | 205 |
| 45 | $78.1K/s | $102M | x6.23 | 3 | 2,660 | 76 | Supernatural | Rift | 10 | 350 |
| 60 | $157K/s | $264M | x6.49 | 4 | 3,543 | 77 | Supernatural | Rift | 10 | 510 |
| 90 | $345K/s | $791M | x10.76 | 5 | 5,292 | 81 | Supernatural | Psychic | 12 | 819 |
| 120 | $696K/s | $1.92B | x16.24 | 6 | 7,028 | 84 | Void | Psychic | 12 | 1262 |
| 180 | $1.09M/s | $6.48B | x18.39 | 8 | 10,432 | 87 | Secret | Psychic | 15 | 2471 |

## Cash-Quellen (Anteil, Summe aller Simulationen)

| Quelle | erste 5 Minuten | gesamt |
|---|---|---|
| Income | 33.6 % | 63.8 % |
| Fishing | 0.7 % | 25.1 % |
| GearOverflow | 0.0 % | 7.9 % |
| Reward | 34.4 % | 1.9 % |
| FishingDuplicate | 0.0 % | 1.2 % |
| AutoSell | 0.0 % | 0.0 % |
| Sell | 0.1 % | 0.0 % |
| Collect | 31.2 % | 0.0 % |

## Kosten-Tabelle (aus den Configs)

| Rebirth | Kosten |
|---|---|
| 1 | $220K |
| 2 | $5.7M |
| 3 | $32M |
| 4 | $69M |
| 5 | $280M |
| 6 | $450M |
| 7 | $1.1B |
| 8 | $2.4B |
| 9 | $6.7B |
| 10 | $19B |
| 11 | $53B |
| 12 | $150B |

| Dice | Luck | Gebiet | Kosten |
|---|---|---|---|
| BASIC DICE | x1 | Suburb | $0 |
| STRANGE DICE | x2 | DarkForest | $130K |
| RIFT DICE | x3 | SecretLab | $19M |
| PSYCHIC DICE | x5 | RiftZone | $170M |
| VOID DICE | x8 | Otherworld | $1.4B |
| ANOMALY DICE | x12 | Void | $90B |

| Gebiet | Rebirth nötig | Kosten |
|---|---|---|
| MYSTERY SUBURB | 0 | $0 |
| DARK FOREST | 1 | $77K |
| SECRET LAB | 3 | $11M |
| RIFT ZONE | 5 | $98M |
| OTHERWORLD | 8 | $840M |
| THE VOID | 12 | $53B |

Upgrade-Kosten in Sekunden Basis-Einkommen (Level 1→15): 6, 8, 10, 13, 16, 30, 40, 50, 65, 85, 140, 190, 260, 360

Level-Multiplikator: 1, 1.2, 1.4, 1.6, 1.8, 2, 2.25, 2.5, 2.75, 3, 3.3, 3.6, 4, 4.4, 5
