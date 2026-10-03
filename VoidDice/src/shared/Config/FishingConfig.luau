--!strict
-- FishingConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > FishingConfig
--
-- RIFT FISHING: Jede Base hat einen Rift Pond. Characters, die nicht in der
-- Base stehen, können dort "fischen" und ziehen bizarre Dinge aus dem Riss.
-- Fischende Characters verdienen KEIN Cash (sie belegen aber auch keinen
-- Base-Slot). Der Pond kann auf jedes freigeschaltete Gewässer "getunt" werden.
--
-- Fang-Intervall pro Character:
--   Sekunden = BaseCatchSeconds / (1 + FishingPower / PowerScale)
--   (geteilt durch (1 + FishingSpeed-Boni)), mindestens MinCatchSeconds
--
-- Loot nutzt dieselbe Mathematik wie das Rollen (Util > RollMath):
--   Chance = "1 in X". Einträge mit Rarity "Common" sind Restwahrscheinlichkeit,
--   alle anderen werden mit der Fishing Luck multipliziert.
--
-- Loot-Arten:
--   Cash      Seconds = so viele Sekunden des aktuellen Base-Einkommens
--   Potion    Id aus PotionConfig
--   Gear      Id aus GearConfig
--   Relic     Id aus FishingConfig.Relics (Sammelobjekte, verkaufbar)
--   Cosmetic  Id aus CosmeticConfig

export type LootEntry = {
	Kind: string,
	Id: string?,
	Seconds: number?,
	Chance: number,
	Rarity: string,
}

export type WatersDef = {
	Id: string,
	DisplayName: string,
	Area: string,
	Description: string,
	Color: Color3,
	Loot: { LootEntry },
}

local FishingConfig = {}

FishingConfig.BaseCatchSeconds = 30
FishingConfig.MinCatchSeconds = 5
FishingConfig.PowerScale = 20
FishingConfig.MaxRecentCatches = 12 -- für die UI-Liste

-- Sammel-Relikte ("rare items")
FishingConfig.Relics = {
	{ Id = "BentSpoon", DisplayName = "BENT SPOON", Rarity = "Common", SellSeconds = 3, Description = "Someone thought really hard at it." },
	{ Id = "MeltedCassette", DisplayName = "MELTED CASSETTE", Rarity = "Common", SellSeconds = 3, Description = "Still plays. Only static." },
	{ Id = "GlowingPebble", DisplayName = "GLOWING PEBBLE", Rarity = "Uncommon", SellSeconds = 6, Description = "Warm. Pulses at 3:33 AM." },
	{ Id = "MissingPoster", DisplayName = "MISSING POSTER", Rarity = "Uncommon", SellSeconds = 6, Description = "The face changes every time you look." },
	{ Id = "RiftShard", DisplayName = "RIFT SHARD", Rarity = "Rare", SellSeconds = 12, Description = "A splinter of a broken dimension." },
	{ Id = "LabBadge", DisplayName = "LAB BADGE #000", Rarity = "Rare", SellSeconds = 12, Description = "Clearance level: none of your business." },
	{ Id = "StaticJar", DisplayName = "JAR OF STATIC", Rarity = "Epic", SellSeconds = 25, Description = "Do not open during thunderstorms." },
	{ Id = "OtherworldCompass", DisplayName = "MIRROR COMPASS", Rarity = "Legendary", SellSeconds = 60, Description = "Points away from home." },
	{ Id = "VoidPearl", DisplayName = "VOID PEARL", Rarity = "Mythic", SellSeconds = 180, Description = "Darker than the space around it." },
	{ Id = "EndlessKey", DisplayName = "THE ENDLESS KEY", Rarity = "Void", SellSeconds = 600, Description = "Opens a door that is not there yet." },
}
FishingConfig.RelicById = {}
for _, r in FishingConfig.Relics do
	FishingConfig.RelicById[r.Id] = r
end

local function L(kind: string, id: string?, chance: number, rarity: string, seconds: number?): LootEntry
	return { Kind = kind, Id = id, Chance = chance, Rarity = rarity, Seconds = seconds }
end

FishingConfig.Waters = {
	{
		Id = "SuburbPond", DisplayName = "MILBROOK RIFT POND", Area = "Suburb",
		Description = "A shallow tear behind the base. Mostly junk. Mostly.",
		Color = Color3.fromRGB(90, 120, 255),
		Loot = {
			L("Cash", nil, 3, "Common", 1),
			L("Relic", "BentSpoon", 6, "Common"),
			L("Relic", "MeltedCassette", 6, "Common"),
			L("Potion", "Luck", 7, "Uncommon"),
			L("Potion", "Cash", 9, "Uncommon"),
			L("Potion", "Bait", 10, "Uncommon"),
			L("Gear", "WalkieTalkie", 25, "Uncommon"),
			L("Gear", "PocketFlashlight", 30, "Uncommon"),
			L("Gear", "BaitTin", 35, "Uncommon"),
			L("Gear", "LuckyArcadeToken", 40, "Uncommon"),
			L("Relic", "GlowingPebble", 25, "Uncommon"),
			L("Potion", "RollSpeed", 25, "Uncommon"),
			L("Cash", nil, 40, "Rare", 5),
			L("Potion", "SuperLuck", 60, "Rare"),
			L("Gear", "StrangeBattery", 200, "Rare"),
			L("Gear", "MoodRing", 250, "Rare"),
			L("Relic", "RiftShard", 150, "Rare"),
			L("Cosmetic", "TrailStatic", 600, "Epic"),
			L("Gear", "PsychicAmplifier", 2250, "Epic"),
		},
	},
	{
		Id = "BlackPinesLake", DisplayName = "BLACK PINES LAKE", Area = "DarkForest",
		Description = "The lake the town stopped swimming in.",
		Color = Color3.fromRGB(70, 200, 120),
		Loot = {
			L("Cash", nil, 3, "Common", 1),
			L("Relic", "MeltedCassette", 7, "Common"),
			L("Potion", "Luck", 6, "Uncommon"),
			L("Potion", "Cash", 8, "Uncommon"),
			L("Potion", "Bait", 9, "Uncommon"),
			L("Gear", "PocketFlashlight", 30, "Uncommon"),
			L("Gear", "BaitTin", 30, "Uncommon"),
			L("Relic", "MissingPoster", 18, "Uncommon"),
			L("Potion", "FishingLuck", 20, "Uncommon"),
			L("Gear", "StrangeBattery", 75, "Rare"),
			L("Gear", "RiftDetector", 87, "Rare"),
			L("Gear", "SignalBooster", 100, "Rare"),
			L("Potion", "SuperLuck", 40, "Rare"),
			L("Cash", nil, 45, "Rare", 6),
			L("Relic", "RiftShard", 80, "Rare"),
			L("Gear", "CreatureLure", 750, "Epic"),
			L("Gear", "TapeRecorder", 875, "Epic"),
			L("Cosmetic", "FishingSporeSplash", 500, "Epic"),
			L("Potion", "Mutagen", 700, "Epic"),
		},
	},
	{
		Id = "CoolantPool", DisplayName = "LAB COOLANT POOL", Area = "SecretLab",
		Description = "Glows. Should not glow.",
		Color = Color3.fromRGB(80, 230, 255),
		Loot = {
			L("Cash", nil, 3, "Common", 2),
			L("Relic", "LabBadge", 9, "Common"),
			L("Potion", "Luck", 6, "Uncommon"),
			L("Potion", "RollSpeed", 9, "Uncommon"),
			L("Potion", "FishingLuck", 12, "Uncommon"),
			L("Gear", "SignalBooster", 37, "Uncommon"),
			L("Gear", "RiftDetector", 37, "Uncommon"),
			L("Gear", "StrangeBattery", 37, "Uncommon"),
			L("Potion", "SuperLuck", 25, "Rare"),
			L("Gear", "PsychicAmplifier", 150, "Rare"),
			L("Gear", "TapeRecorder", 175, "Rare"),
			L("Relic", "StaticJar", 90, "Rare"),
			L("Cash", nil, 50, "Rare", 7),
			L("Potion", "Mutagen", 250, "Epic"),
			L("Gear", "ContainmentRod", 2250, "Legendary"),
			L("Gear", "VoidCompass", 3000, "Legendary"),
			L("Cosmetic", "AuraLabGlow", 1500, "Legendary"),
		},
	},
	{
		Id = "RiftTear", DisplayName = "THE TEAR", Area = "RiftZone",
		Description = "Fishing directly in a hole in the sky.",
		Color = Color3.fromRGB(160, 90, 255),
		Loot = {
			L("Cash", nil, 3, "Common", 2),
			L("Relic", "RiftShard", 6, "Common"),
			L("Potion", "SuperLuck", 8, "Uncommon"),
			L("Potion", "FishingLuck", 8, "Uncommon"),
			L("Potion", "Bait", 8, "Uncommon"),
			L("Gear", "PsychicAmplifier", 50, "Uncommon"),
			L("Gear", "CreatureLure", 55, "Uncommon"),
			L("Gear", "TapeRecorder", 55, "Uncommon"),
			L("Relic", "StaticJar", 40, "Rare"),
			L("Cash", nil, 50, "Rare", 8),
			L("Potion", "Mutagen", 90, "Rare"),
			L("Gear", "VoidCompass", 750, "Epic"),
			L("Gear", "ContainmentRod", 750, "Epic"),
			L("Gear", "GoldenCassette", 875, "Epic"),
			L("Relic", "OtherworldCompass", 800, "Legendary"),
			L("Potion", "VoidElixir", 900, "Legendary"),
			L("Cosmetic", "RiftEffectFracture", 2000, "Legendary"),
		},
	},
	{
		Id = "MirrorLake", DisplayName = "OTHERWORLD LAKE", Area = "Otherworld",
		Description = "Your reflection fishes back.",
		Color = Color3.fromRGB(40, 230, 190),
		Loot = {
			L("Cash", nil, 3, "Common", 2),
			L("Relic", "StaticJar", 8, "Common"),
			L("Potion", "SuperLuck", 6, "Uncommon"),
			L("Potion", "Mutagen", 20, "Uncommon"),
			L("Gear", "VoidCompass", 100, "Rare"),
			L("Gear", "ContainmentRod", 100, "Rare"),
			L("Gear", "GoldenCassette", 100, "Rare"),
			L("Relic", "OtherworldCompass", 120, "Rare"),
			L("Cash", nil, 60, "Rare", 9),
			L("Potion", "VoidElixir", 200, "Epic"),
			L("Gear", "RiftLantern", 2250, "Mythic"),
			L("Gear", "SignalCrown", 2750, "Mythic"),
			L("Relic", "VoidPearl", 2500, "Mythic"),
			L("Cosmetic", "AuraMirror", 3000, "Mythic"),
		},
	},
	{
		Id = "AbyssWell", DisplayName = "THE ABYSS WELL", Area = "Void",
		Description = "There is no bottom. There is something at the bottom.",
		Color = Color3.fromRGB(130, 50, 255),
		Loot = {
			L("Cash", nil, 3, "Common", 2),
			L("Relic", "VoidPearl", 30, "Uncommon"),
			L("Potion", "VoidElixir", 12, "Uncommon"),
			L("Potion", "Mutagen", 12, "Uncommon"),
			L("Gear", "RiftLantern", 300, "Rare"),
			L("Gear", "SignalCrown", 300, "Rare"),
			L("Cash", nil, 60, "Rare", 10),
			L("Gear", "NullEngine", 6250, "Void"),
			L("Gear", "AbyssHook", 6250, "Void"),
			L("Relic", "EndlessKey", 10000, "Void"),
			L("Cosmetic", "TitleAbyssAngler", 5000, "Void"),
		},
	},
} :: { WatersDef }

FishingConfig.WatersById = {} :: { [string]: WatersDef }
FishingConfig.WatersByArea = {} :: { [string]: WatersDef }
for _, w in FishingConfig.Waters do
	FishingConfig.WatersById[w.Id] = w
	FishingConfig.WatersByArea[w.Area] = w
end

FishingConfig.DefaultWaters = "SuburbPond"

-- Rarities mit Server-Ansage bei einem Fang ("riesiger Fishing Drop")
FishingConfig.AnnounceRarities = { Legendary = true, Mythic = true, Void = true }

return FishingConfig
