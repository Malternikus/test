--!strict
-- RarityConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > RarityConfig
--
-- Alle Rarities in aufsteigender Reihenfolge. Die eigentlichen Roll-Chancen
-- stehen pro Character in CharacterConfig (Chance = "1 in X"). Hier stehen nur
-- Darstellung, Reveal-Verhalten und Ökonomie-Faktoren pro Rarity.
--
--   Order            Sortierung (1 = häufigste)
--   TierTarget       Ziel-Wahrscheinlichkeit der gesamten Rarity (nur zur Kontrolle,
--                    der Test "rarity_tiers" prüft, dass die Characters sie treffen)
--   LuckAffected     false = "Rest"-Tier: bekommt, was übrig bleibt (Common)
--   IncomeRange      Ziel-Bereich für BaseMoneyPerSecond der Characters dieser Rarity
--   UpgradeCostFactor  Rarere Characters sind beim Upgraden etwas teurer pro $/s
--   RevealTier       Welche Reveal-Animation der Client spielt (siehe UIConfig.Reveal)
--   RevealSeconds    Server-Pause für Auto-Roll nach diesem Ergebnis (große Reveals
--                    sollen nicht vom nächsten Roll überdeckt werden)
--   Announce         "None" | "Server" | "Global"

export type RarityDef = {
	Id: string,
	DisplayName: string,
	Order: number,
	TierTarget: number,
	LuckAffected: boolean,
	Color: Color3,
	Color2: Color3,
	IncomeRange: { number },
	UpgradeCostFactor: number,
	SellSeconds: number,
	RevealTier: number,
	RevealSeconds: number,
	Announce: string,
	PowerMultiplier: number,
}

local RarityConfig = {}

RarityConfig.List = {
	{
		Id = "Common", DisplayName = "COMMON", Order = 1, TierTarget = 0.7375,
		LuckAffected = false,
		Color = Color3.fromRGB(176, 184, 196), Color2 = Color3.fromRGB(110, 118, 132),
		IncomeRange = { 1, 3 }, UpgradeCostFactor = 1.0, SellSeconds = 20,
		RevealTier = 0, RevealSeconds = 0, Announce = "None", PowerMultiplier = 1,
	},
	{
		Id = "Uncommon", DisplayName = "UNCOMMON", Order = 2, TierTarget = 1 / 5,
		LuckAffected = true,
		Color = Color3.fromRGB(92, 214, 124), Color2 = Color3.fromRGB(34, 140, 74),
		IncomeRange = { 4, 7 }, UpgradeCostFactor = 1.0, SellSeconds = 20,
		RevealTier = 0, RevealSeconds = 0, Announce = "None", PowerMultiplier = 1,
	},
	{
		Id = "Rare", DisplayName = "RARE", Order = 3, TierTarget = 1 / 20,
		LuckAffected = true,
		Color = Color3.fromRGB(64, 156, 255), Color2 = Color3.fromRGB(28, 82, 196),
		IncomeRange = { 14, 24 }, UpgradeCostFactor = 1.05, SellSeconds = 25,
		RevealTier = 1, RevealSeconds = 0, Announce = "None", PowerMultiplier = 1,
	},
	{
		Id = "Epic", DisplayName = "EPIC", Order = 4, TierTarget = 1 / 100,
		LuckAffected = true,
		Color = Color3.fromRGB(176, 92, 255), Color2 = Color3.fromRGB(104, 34, 196),
		IncomeRange = { 50, 80 }, UpgradeCostFactor = 1.1, SellSeconds = 30,
		RevealTier = 2, RevealSeconds = 0.6, Announce = "None", PowerMultiplier = 1,
	},
	{
		Id = "Legendary", DisplayName = "LEGENDARY", Order = 5, TierTarget = 1 / 500,
		LuckAffected = true,
		Color = Color3.fromRGB(255, 188, 52), Color2 = Color3.fromRGB(214, 112, 20),
		IncomeRange = { 180, 300 }, UpgradeCostFactor = 1.15, SellSeconds = 40,
		RevealTier = 3, RevealSeconds = 1.6, Announce = "None", PowerMultiplier = 1,
	},
	{
		Id = "Mythic", DisplayName = "MYTHIC", Order = 6, TierTarget = 1 / 2500,
		LuckAffected = true,
		Color = Color3.fromRGB(255, 72, 120), Color2 = Color3.fromRGB(180, 20, 70),
		IncomeRange = { 700, 1100 }, UpgradeCostFactor = 1.2, SellSeconds = 45,
		RevealTier = 4, RevealSeconds = 2.2, Announce = "Server", PowerMultiplier = 1,
	},
	{
		Id = "Supernatural", DisplayName = "SUPERNATURAL", Order = 7, TierTarget = 1 / 10000,
		LuckAffected = true,
		Color = Color3.fromRGB(64, 236, 236), Color2 = Color3.fromRGB(20, 120, 170),
		IncomeRange = { 2600, 4200 }, UpgradeCostFactor = 1.25, SellSeconds = 50,
		RevealTier = 5, RevealSeconds = 3, Announce = "Server", PowerMultiplier = 1,
	},
	{
		Id = "Void", DisplayName = "VOID", Order = 8, TierTarget = 1 / 50000,
		LuckAffected = true,
		Color = Color3.fromRGB(140, 60, 255), Color2 = Color3.fromRGB(16, 6, 40),
		IncomeRange = { 10000, 16000 }, UpgradeCostFactor = 1.3, SellSeconds = 60,
		RevealTier = 6, RevealSeconds = 3.5, Announce = "Server", PowerMultiplier = 1,
	},
	{
		Id = "Secret", DisplayName = "SECRET", Order = 9, TierTarget = 1 / 250000,
		LuckAffected = true,
		Color = Color3.fromRGB(255, 40, 40), Color2 = Color3.fromRGB(20, 0, 0),
		IncomeRange = { 45000, 70000 }, UpgradeCostFactor = 1.35, SellSeconds = 60,
		RevealTier = 7, RevealSeconds = 4.5, Announce = "Global", PowerMultiplier = 1,
	},
	{
		Id = "Anomaly", DisplayName = "ANOMALY", Order = 10, TierTarget = 7e-7, -- 1/2.5M + 1/5M + 1/10M
		LuckAffected = true,
		Color = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(0, 255, 200),
		IncomeRange = { 220000, 400000 }, UpgradeCostFactor = 1.4, SellSeconds = 60,
		RevealTier = 8, RevealSeconds = 5.5, Announce = "Global", PowerMultiplier = 1,
	},
} :: { RarityDef }

RarityConfig.ById = {} :: { [string]: RarityDef }
for _, def in RarityConfig.List do
	RarityConfig.ById[def.Id] = def
end

function RarityConfig.Get(id: string): RarityDef
	local def = RarityConfig.ById[id]
	assert(def, "Unbekannte Rarity: " .. tostring(id))
	return def
end

function RarityConfig.Order(id: string): number
	local def = RarityConfig.ById[id]
	return if def then def.Order else 0
end

-- Für UI-Gradients: "Anomaly" bekommt einen animierten Regenbogen, den Rest
-- macht der Client über Color/Color2.
RarityConfig.RainbowRarities = { Anomaly = true, Secret = false }

return RarityConfig
