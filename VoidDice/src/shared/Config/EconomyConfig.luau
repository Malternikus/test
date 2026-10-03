--!strict
-- EconomyConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > EconomyConfig
--
-- Das "Spreadsheet" der Economy. Alle Formeln stehen in Util > Stats, alle
-- Zahlen hier. Die Simulation (tools/simulate.luau) spielt mit genau diesen
-- Werten und der echten Server-Logik durch und schreibt docs/ECONOMY.md.
--
-- Grundidee: Upgrade-Kosten sind in "Sekunden Basis-Einkommen" angegeben.
-- Dadurch ist die Amortisationszeit eines Upgrades für jeden Character gleich,
-- egal wie selten er ist. Seltene Characters sind trotzdem besser, weil sie
-- absolut viel mehr bringen.

local EconomyConfig = {}

-- Multiplikator auf $/s je Level (Index = Level). Linear-ish, max 5x.
-- Kein exponentielles Scaling.
EconomyConfig.LevelIncomeMultiplier = {
	1.0, 1.2, 1.4, 1.6, 1.8, -- 1–5
	2.0, 2.25, 2.5, 2.75, 3.0, -- 6–10
	3.3, 3.6, 4.0, 4.4, 5.0, -- 11–15
}

-- Kosten für Level L -> L+1 in Sekunden Basis-$/s (Level 1, ohne Mutation).
-- 1–5 sehr günstig, 6–10 mittel, 11–15 teuer.
EconomyConfig.UpgradeCostSeconds = {
	6, 8, 10, 13, 16, -- 1->2 … 5->6
	30, 40, 50, 65, 85, -- 6->7 … 10->11
	140, 190, 260, 360, -- 11->12 … 14->15
}
EconomyConfig.MinUpgradeCost = 10

-- Fishing Power und Power wachsen nur leicht mit dem Level
EconomyConfig.FishingPowerPerLevel = 0.04 -- +4 % pro Level
EconomyConfig.PowerPerLevel = 0.10 -- +10 % pro Level

-- Verkaufswert = Basis-$/s * SellSeconds (aus RarityConfig) * Level-Faktor
EconomyConfig.SellLevelBonus = 0.5 -- Level 15 verkauft sich für +50 % * (Level-1)/14

-- Vault: Einkommen sammelt sich hier, bis der Spieler einsammelt.
-- Ab Rebirth 1 gibt es Auto-Collect.
EconomyConfig.VaultCapacitySeconds = 900
EconomyConfig.VaultMinCapacity = 2000

-- Belohnungen in "Sekunden aktuelles Einkommen" + Mindestbetrag.
-- So bleiben Quests/Fishing/Produkte in jeder Phase relevant, ohne zu eskalieren.
EconomyConfig.ScaledReward = {
	MinIncomePerSecond = 5, -- falls der Spieler fast nichts verdient
}

-- Globale Grenzen für Boni (Schutz vor Stacking-Exploits)
EconomyConfig.MaxCashMultiplier = 50
EconomyConfig.MaxLuck = 500
EconomyConfig.MaxGearLuckPct = 100 -- Summe Gear-Luck aller platzierten Characters
EconomyConfig.MaxGearCashPctPerCharacter = 150

-- Index-Bonus: dauerhafte Luck für entdeckte Characters
EconomyConfig.IndexLuckPctPerDiscovery = 0.25 -- +0.25 % Luck pro entdecktem Character (max +25 %)

-- Base Value (Flex-Anzeige): Summe Power der platzierten Characters
-- Leaderboard "Rarest Collection": Summe Punkte der entdeckten Characters
EconomyConfig.CollectionPoints = {
	Common = 1, Uncommon = 2, Rare = 5, Epic = 15, Legendary = 50, Mythic = 200,
	Supernatural = 800, Void = 4000, Secret = 25000, Anomaly = 150000,
}

-- Simulations-Zielwerte (Minuten seit Spielstart) für den Economy-Report
EconomyConfig.RebirthTargetsMinutes = { 5, 15, 30, 50, 75, 105, 140, 180 }

return EconomyConfig
