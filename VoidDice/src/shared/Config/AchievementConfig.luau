--!strict
-- AchievementConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > AchievementConfig
--
-- Einmalige Erfolge. Die Logik prüft nach jeder relevanten Aktion alle noch
-- offenen Achievements (Check-Typen siehe Logic > Achievements).
--
--   Check = { Type = "Stat", Stat = "TotalRolls", Value = 1000 }
--           { Type = "BestRarity", Rarity = "Legendary" }
--           { Type = "Discovered", Value = 50 }
--           { Type = "MaxLevelCharacter" }
--           { Type = "Mutation" }

export type AchievementDef = {
	Id: string,
	DisplayName: string,
	Description: string,
	Check: { [string]: any },
	Rewards: {
		CashSeconds: number?,
		Potions: { [string]: number }?,
		Cosmetic: string?,
		SeasonXp: number?,
	},
}

local AchievementConfig = {}

AchievementConfig.List = {
	{ Id = "FirstRoll", DisplayName = "FIRST ROLL", Description = "Roll your first character.",
		Check = { Type = "Stat", Stat = "TotalRolls", Value = 1 }, Rewards = { CashSeconds = 0, Potions = { Luck = 1 } } },
	{ Id = "FirstRare", DisplayName = "SOMETHING STRANGE", Description = "Roll a Rare character.",
		Check = { Type = "BestRarity", Rarity = "Rare" }, Rewards = { CashSeconds = 0 } },
	{ Id = "FirstEpic", DisplayName = "EPIC FIND", Description = "Roll an Epic character.",
		Check = { Type = "BestRarity", Rarity = "Epic" }, Rewards = { CashSeconds = 0, Potions = { Luck = 1 } } },
	{ Id = "FirstLegendary", DisplayName = "FIRST LEGENDARY", Description = "Roll a Legendary character.",
		Check = { Type = "BestRarity", Rarity = "Legendary" }, Rewards = { CashSeconds = 0, Potions = { SuperLuck = 1 }, Cosmetic = "MysteryHunter" } },
	{ Id = "FirstMythic", DisplayName = "FIRST MYTHIC", Description = "Roll a Mythic character.",
		Check = { Type = "BestRarity", Rarity = "Mythic" }, Rewards = { CashSeconds = 30, Potions = { SuperLuck = 2 } } },
	{ Id = "FirstSupernatural", DisplayName = "BEYOND NATURE", Description = "Roll a Supernatural character.",
		Check = { Type = "BestRarity", Rarity = "Supernatural" }, Rewards = { CashSeconds = 60, Potions = { VoidElixir = 1 } } },
	{ Id = "FirstVoid", DisplayName = "FIRST VOID", Description = "Roll a Void character.",
		Check = { Type = "BestRarity", Rarity = "Void" }, Rewards = { CashSeconds = 90, Potions = { VoidElixir = 2 } } },
	{ Id = "FirstSecret", DisplayName = "FIRST SECRET", Description = "Roll a Secret character.",
		Check = { Type = "BestRarity", Rarity = "Secret" }, Rewards = { CashSeconds = 180, Potions = { VoidElixir = 3 } } },
	{ Id = "FirstAnomaly", DisplayName = "IT FOUND YOU", Description = "Roll an Anomaly.",
		Check = { Type = "BestRarity", Rarity = "Anomaly" }, Rewards = { CashSeconds = 600, Cosmetic = "AnomalyHunter" } },
	{ Id = "Rolls1000", DisplayName = "1,000 ROLLS", Description = "Roll 1,000 times.",
		Check = { Type = "Stat", Stat = "TotalRolls", Value = 1000 }, Rewards = { CashSeconds = 0, Potions = { Luck = 2 } } },
	{ Id = "Rolls10000", DisplayName = "10,000 ROLLS", Description = "Roll 10,000 times.",
		Check = { Type = "Stat", Stat = "TotalRolls", Value = 10000 }, Rewards = { CashSeconds = 60, Potions = { SuperLuck = 3 } } },
	{ Id = "Rolls100000", DisplayName = "100,000 ROLLS", Description = "Roll 100,000 times.",
		Check = { Type = "Stat", Stat = "TotalRolls", Value = 100000 }, Rewards = { CashSeconds = 300, Potions = { VoidElixir = 3 } } },
	{ Id = "Rebirth1", DisplayName = "BORN AGAIN", Description = "Complete your first Rebirth.",
		Check = { Type = "Stat", Stat = "Rebirths", Value = 1 }, Rewards = { Potions = { Luck = 2 } } },
	{ Id = "Rebirth10", DisplayName = "REBIRTH 10", Description = "Reach Rebirth 10.",
		Check = { Type = "Stat", Stat = "Rebirths", Value = 10 }, Rewards = { Potions = { VoidElixir = 2 } } },
	{ Id = "MaxCharacter", DisplayName = "MAX CHARACTER", Description = "Upgrade a character to level 15.",
		Check = { Type = "MaxLevelCharacter" }, Rewards = { CashSeconds = 30, Cosmetic = "MaxedOut" } },
	{ Id = "FirstMutation", DisplayName = "MUTATED", Description = "Roll a character with a mutation.",
		Check = { Type = "Mutation" }, Rewards = { CashSeconds = 0, Potions = { Mutagen = 1 } } },
	{ Id = "Index25", DisplayName = "CASE FILES I", Description = "Discover 25 characters.",
		Check = { Type = "Discovered", Value = 25 }, Rewards = { CashSeconds = 0, Potions = { SuperLuck = 1 } } },
	{ Id = "Index50", DisplayName = "CASE FILES II", Description = "Discover 50 characters.",
		Check = { Type = "Discovered", Value = 50 }, Rewards = { CashSeconds = 30, Cosmetic = "Collector" } },
	{ Id = "Index100", DisplayName = "THE COMPLETE ARCHIVE", Description = "Discover all 100 characters.",
		Check = { Type = "Discovered", Value = 100 }, Rewards = { CashSeconds = 300, Potions = { VoidElixir = 5 } } },
	{ Id = "Catch100", DisplayName = "RIFT ANGLER", Description = "Catch 100 items while fishing.",
		Check = { Type = "Stat", Stat = "FishingCatches", Value = 100 }, Rewards = { CashSeconds = 0, Cosmetic = "DeepAngler" } },
	{ Id = "Gear10", DisplayName = "GEARED UP", Description = "Obtain 10 gear items.",
		Check = { Type = "Stat", Stat = "GearObtained", Value = 10 }, Rewards = { CashSeconds = 0, Potions = { FishingLuck = 1 } } },
} :: { AchievementDef }

AchievementConfig.ById = {} :: { [string]: AchievementDef }
for _, a in AchievementConfig.List do
	AchievementConfig.ById[a.Id] = a
end

return AchievementConfig
