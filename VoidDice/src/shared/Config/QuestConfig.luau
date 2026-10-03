--!strict
-- QuestConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > QuestConfig
--
-- Daily Quests: Jeden Tag (UTC) werden DailyCount Quests aus dem Pool gezogen.
-- Die Auswahl ist pro Spieler und Tag deterministisch (Seed = UserId + Tag),
-- damit ein Rejoin keine neuen Quests würfelt.
--
--   Counter  Name des Zählers, den die Logik hochzählt (siehe Logic > Quests)
--   Target   benötigte Menge
--   Rewards  CashSeconds (Sekunden aktuelles Einkommen), Potions, SeasonXp, Gear

export type QuestDef = {
	Id: string,
	Text: string,
	Counter: string,
	Target: number,
	Rewards: {
		CashSeconds: number?,
		Potions: { [string]: number }?,
		Gear: string?,
		SeasonXp: number?,
	},
	Weight: number,
}

local QuestConfig = {}

QuestConfig.DailyCount = 5

-- Gültige Zähler (Logic zählt nur diese)
QuestConfig.Counters = {
	Rolls = true,
	RareRolls = true, -- Rare oder besser
	EpicRolls = true, -- Epic oder besser
	Upgrades = true,
	FishingCatches = true,
	Rebirths = true,
	GearEquips = true,
	CashCollected = true,
	PotionsUsed = true,
	Mutations = true,
}

QuestConfig.Pool = {
	{ Id = "Roll50", Text = "Roll 50 times", Counter = "Rolls", Target = 50,
		Rewards = { CashSeconds = 15, SeasonXp = 20 }, Weight = 10 },
	{ Id = "Roll200", Text = "Roll 200 times", Counter = "Rolls", Target = 200,
		Rewards = { CashSeconds = 30, Potions = { Luck = 1 }, SeasonXp = 40 }, Weight = 10 },
	{ Id = "Roll1000", Text = "Roll 1,000 times", Counter = "Rolls", Target = 1000,
		Rewards = { CashSeconds = 75, Potions = { SuperLuck = 1 }, SeasonXp = 80 }, Weight = 4 },
	{ Id = "ObtainRare", Text = "Obtain a Rare+ character", Counter = "RareRolls", Target = 1,
		Rewards = { CashSeconds = 15, SeasonXp = 20 }, Weight = 10 },
	{ Id = "ObtainRare10", Text = "Obtain 10 Rare+ characters", Counter = "RareRolls", Target = 10,
		Rewards = { CashSeconds = 30, Potions = { Cash = 1 }, SeasonXp = 40 }, Weight = 6 },
	{ Id = "ObtainEpic", Text = "Obtain an Epic+ character", Counter = "EpicRolls", Target = 1,
		Rewards = { CashSeconds = 30, Potions = { Luck = 1 }, SeasonXp = 40 }, Weight = 6 },
	{ Id = "Upgrade5", Text = "Upgrade characters 5 times", Counter = "Upgrades", Target = 5,
		Rewards = { CashSeconds = 15, SeasonXp = 20 }, Weight = 10 },
	{ Id = "Upgrade25", Text = "Upgrade characters 25 times", Counter = "Upgrades", Target = 25,
		Rewards = { CashSeconds = 45, Potions = { Cash = 1 }, SeasonXp = 40 }, Weight = 6 },
	{ Id = "Catch10", Text = "Catch 10 fishing items", Counter = "FishingCatches", Target = 10,
		Rewards = { CashSeconds = 22, Potions = { Bait = 1 }, SeasonXp = 30 }, Weight = 8 },
	{ Id = "Catch40", Text = "Catch 40 fishing items", Counter = "FishingCatches", Target = 40,
		Rewards = { CashSeconds = 60, Potions = { FishingLuck = 1 }, SeasonXp = 60 }, Weight = 4 },
	{ Id = "Rebirth1", Text = "Complete a Rebirth", Counter = "Rebirths", Target = 1,
		Rewards = { CashSeconds = 45, Potions = { SuperLuck = 1 }, SeasonXp = 80 }, Weight = 6 },
	{ Id = "EquipGear", Text = "Equip gear on a character", Counter = "GearEquips", Target = 1,
		Rewards = { CashSeconds = 15, SeasonXp = 20 }, Weight = 6 },
	{ Id = "UsePotion", Text = "Use 2 potions", Counter = "PotionsUsed", Target = 2,
		Rewards = { CashSeconds = 15, Potions = { RollSpeed = 1 }, SeasonXp = 20 }, Weight = 5 },
	{ Id = "Mutation", Text = "Roll a mutated character", Counter = "Mutations", Target = 1,
		Rewards = { CashSeconds = 30, Potions = { Luck = 1 }, SeasonXp = 40 }, Weight = 5 },
} :: { QuestDef }

QuestConfig.ById = {} :: { [string]: QuestDef }
for _, q in QuestConfig.Pool do
	QuestConfig.ById[q.Id] = q
end

-- Für neue Spieler: diese Quests sind am ersten Tag garantiert dabei
QuestConfig.FirstDayQuests = { "Roll50", "ObtainRare", "Upgrade5", "Catch10", "Rebirth1" }

return QuestConfig
