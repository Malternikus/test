--!strict
-- GearConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > GearConfig
--
-- Gear wird auf Characters ausgerüstet (2 Slots, ab Rebirth 4 drei).
-- Gear droppt vom Fishing, aus Quests und aus dem Season Pass.
--
-- Stats:
--   CashPct         +% $/s für DIESEN Character
--   FishingPower    +flat Fishing Power für diesen Character
--   FishingLuckPct  +% Fishing Luck, wenn dieser Character fischt
--   LuckPct         +% Roll-Luck GLOBAL, solange der Character in der Base steht
--                   (gedeckelt durch EconomyConfig.MaxGearLuckPct)

export type GearDef = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	CashPct: number?,
	FishingPower: number?,
	FishingLuckPct: number?,
	LuckPct: number?,
	SellValueSeconds: number,
	Color: Color3,
	Description: string,
}

local GearConfig = {}

-- Gear-Rarities (eigene, kürzere Liste als bei Characters)
GearConfig.Rarities = {
	{ Id = "Common", Order = 1, Color = Color3.fromRGB(176, 184, 196) },
	{ Id = "Rare", Order = 2, Color = Color3.fromRGB(64, 156, 255) },
	{ Id = "Epic", Order = 3, Color = Color3.fromRGB(176, 92, 255) },
	{ Id = "Legendary", Order = 4, Color = Color3.fromRGB(255, 188, 52) },
	{ Id = "Mythic", Order = 5, Color = Color3.fromRGB(255, 72, 120) },
	{ Id = "Void", Order = 6, Color = Color3.fromRGB(140, 60, 255) },
}
GearConfig.RarityById = {}
for _, r in GearConfig.Rarities do
	GearConfig.RarityById[r.Id] = r
end

GearConfig.List = {
	-- Common
	{ Id = "WalkieTalkie", DisplayName = "WALKIE-TALKIE", Rarity = "Common", FishingPower = 3, SellValueSeconds = 2,
		Color = Color3.fromRGB(60, 60, 60), Description = "Channel 7. Somebody keeps breathing on it." },
	{ Id = "PocketFlashlight", DisplayName = "POCKET FLASHLIGHT", Rarity = "Common", CashPct = 8, SellValueSeconds = 2,
		Color = Color3.fromRGB(240, 220, 120), Description = "Batteries included. Courage not." },
	{ Id = "LuckyArcadeToken", DisplayName = "LUCKY ARCADE TOKEN", Rarity = "Common", LuckPct = 2, SellValueSeconds = 2,
		Color = Color3.fromRGB(220, 180, 60), Description = "From the machine nobody could beat." },
	{ Id = "BaitTin", DisplayName = "BAIT TIN", Rarity = "Common", FishingLuckPct = 8, SellValueSeconds = 2,
		Color = Color3.fromRGB(150, 150, 160), Description = "It wriggles. The tin, not the bait." },
	-- Rare
	{ Id = "StrangeBattery", DisplayName = "STRANGE BATTERY", Rarity = "Rare", CashPct = 18, SellValueSeconds = 4,
		Color = Color3.fromRGB(80, 220, 120), Description = "Never runs out. Hums at night." },
	{ Id = "RiftDetector", DisplayName = "RIFT DETECTOR", Rarity = "Rare", FishingLuckPct = 18, FishingPower = 2, SellValueSeconds = 4,
		Color = Color3.fromRGB(80, 200, 255), Description = "Clicks faster near tears in reality." },
	{ Id = "SignalBooster", DisplayName = "SIGNAL BOOSTER", Rarity = "Rare", FishingPower = 7, SellValueSeconds = 4,
		Color = Color3.fromRGB(200, 200, 210), Description = "Picks up stations that went off air in 1983." },
	{ Id = "MoodRing", DisplayName = "MOOD RING", Rarity = "Rare", LuckPct = 4, SellValueSeconds = 4,
		Color = Color3.fromRGB(120, 80, 255), Description = "Always the same color: uneasy." },
	-- Epic
	{ Id = "PsychicAmplifier", DisplayName = "PSYCHIC AMPLIFIER", Rarity = "Epic", LuckPct = 7, CashPct = 10, SellValueSeconds = 8,
		Color = Color3.fromRGB(140, 160, 255), Description = "Headset prototype. Side effects: yes." },
	{ Id = "CreatureLure", DisplayName = "CREATURE LURE", Rarity = "Epic", FishingLuckPct = 30, FishingPower = 5, SellValueSeconds = 8,
		Color = Color3.fromRGB(255, 120, 60), Description = "Smells like the Otherworld. Unfortunately." },
	{ Id = "TapeRecorder", DisplayName = "EVIDENCE TAPE DECK", Rarity = "Epic", CashPct = 30, SellValueSeconds = 8,
		Color = Color3.fromRGB(90, 70, 60), Description = "Plays the tape backwards. Pays forwards." },
	-- Legendary
	{ Id = "VoidCompass", DisplayName = "VOID COMPASS", Rarity = "Legendary", LuckPct = 12, SellValueSeconds = 15,
		Color = Color3.fromRGB(140, 60, 255), Description = "Points to whatever you will roll next." },
	{ Id = "ContainmentRod", DisplayName = "CONTAINMENT ROD", Rarity = "Legendary", FishingPower = 14, FishingLuckPct = 25, SellValueSeconds = 15,
		Color = Color3.fromRGB(230, 236, 255), Description = "Lab-grade fishing rod. Rated for things with teeth." },
	{ Id = "GoldenCassette", DisplayName = "GOLDEN CASSETTE", Rarity = "Legendary", CashPct = 50, SellValueSeconds = 15,
		Color = Color3.fromRGB(255, 200, 50), Description = "Side B is just money sounds." },
	-- Mythic
	{ Id = "RiftLantern", DisplayName = "RIFT LANTERN", Rarity = "Mythic", LuckPct = 15, FishingLuckPct = 30, SellValueSeconds = 25,
		Color = Color3.fromRGB(170, 90, 255), Description = "Burns with light from the other side." },
	{ Id = "SignalCrown", DisplayName = "SIGNAL CROWN", Rarity = "Mythic", CashPct = 75, SellValueSeconds = 25,
		Color = Color3.fromRGB(255, 72, 120), Description = "Every radio in Milbrook tunes to its wearer." },
	-- Void
	{ Id = "NullEngine", DisplayName = "NULL ENGINE", Rarity = "Void", CashPct = 100, LuckPct = 10, SellValueSeconds = 40,
		Color = Color3.fromRGB(110, 30, 255), Description = "Runs on nothing. Produces everything." },
	{ Id = "AbyssHook", DisplayName = "ABYSS HOOK", Rarity = "Void", FishingPower = 30, FishingLuckPct = 60, SellValueSeconds = 40,
		Color = Color3.fromRGB(20, 0, 40), Description = "It has caught things that caught it back." },
} :: { GearDef }

GearConfig.ById = {} :: { [string]: GearDef }
for _, def in GearConfig.List do
	GearConfig.ById[def.Id] = def
end

function GearConfig.Get(id: string): GearDef?
	return GearConfig.ById[id]
end

return GearConfig
