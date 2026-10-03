--!strict
-- PotionConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > PotionConfig
--
-- Potions sind zeitlich begrenzte Boosts. Die Zeit läuft nur, solange der
-- Spieler online ist (wird im Profil als Restsekunden gespeichert).
-- Gleiche Potion nochmal benutzen = Dauer wird addiert (bis MaxDuration).
-- Verschiedene Potions mit gleichem Effekt addieren ihre Amounts.
--
--   Effect: "Luck" | "Cash" | "RollSpeed" | "FishingLuck" | "FishingSpeed" | "MutationLuck"
--   Amount: +Anteil (0.25 = +25 %)

export type PotionDef = {
	Id: string,
	DisplayName: string,
	Effect: string,
	Amount: number,
	Duration: number,
	Rarity: string,
	Color: Color3,
	Description: string,
}

local PotionConfig = {}

PotionConfig.MaxDuration = 3600

PotionConfig.List = {
	{
		Id = "Luck", DisplayName = "LUCK POTION", Effect = "Luck", Amount = 0.25, Duration = 600,
		Rarity = "Common", Color = Color3.fromRGB(90, 220, 120),
		Description = "+25% Luck for 10 minutes.",
	},
	{
		Id = "SuperLuck", DisplayName = "SUPER LUCK POTION", Effect = "Luck", Amount = 0.5, Duration = 600,
		Rarity = "Rare", Color = Color3.fromRGB(60, 255, 160),
		Description = "+50% Luck for 10 minutes.",
	},
	{
		Id = "Cash", DisplayName = "CASH POTION", Effect = "Cash", Amount = 0.5, Duration = 600,
		Rarity = "Common", Color = Color3.fromRGB(255, 210, 60),
		Description = "+50% Cash for 10 minutes.",
	},
	{
		Id = "RollSpeed", DisplayName = "ROLL SPEED POTION", Effect = "RollSpeed", Amount = 0.25, Duration = 300,
		Rarity = "Common", Color = Color3.fromRGB(80, 190, 255),
		Description = "Roll 25% faster for 5 minutes.",
	},
	{
		Id = "FishingLuck", DisplayName = "FISHING LUCK POTION", Effect = "FishingLuck", Amount = 0.5, Duration = 600,
		Rarity = "Rare", Color = Color3.fromRGB(60, 230, 230),
		Description = "+50% Fishing Luck for 10 minutes.",
	},
	{
		Id = "Bait", DisplayName = "RIFT BAIT", Effect = "FishingSpeed", Amount = 0.3, Duration = 600,
		Rarity = "Common", Color = Color3.fromRGB(200, 120, 255),
		Description = "Characters catch 30% faster for 10 minutes.",
	},
	{
		Id = "Mutagen", DisplayName = "STATIC MUTAGEN", Effect = "MutationLuck", Amount = 1.0, Duration = 300,
		Rarity = "Epic", Color = Color3.fromRGB(255, 80, 200),
		Description = "Doubles mutation chances for 5 minutes. Only found, never sold.",
	},
	{
		Id = "VoidElixir", DisplayName = "VOID ELIXIR", Effect = "Luck", Amount = 1.0, Duration = 300,
		Rarity = "Legendary", Color = Color3.fromRGB(140, 60, 255),
		Description = "+100% Luck for 5 minutes.",
	},
} :: { PotionDef }

PotionConfig.ById = {} :: { [string]: PotionDef }
for _, def in PotionConfig.List do
	PotionConfig.ById[def.Id] = def
end

function PotionConfig.Get(id: string): PotionDef?
	return PotionConfig.ById[id]
end

return PotionConfig
