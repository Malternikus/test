--!strict
-- Characters > Epic
-- Ziel-Summe der Chancen: 1/100. Einzelchancen 1 in 900..1900.
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "DeepLakeDiver", DisplayName = "Deep Lake Diver", Rarity = "Epic", RollChance = 900,
		BaseMoneyPerSecond = 50, BasePower = 25, BaseFishingPower = 16, MaxLevel = 15, Category = "Human",
		VisualTheme = "navy wetsuit, yellow fins, dive goggles on the forehead, lantern and rod",
		Description = "Fishing specialist. Dives where Milbrook Lake has no bottom and comes back with fish that glow. Poor pay, legendary hauls.",
		ModelReference = "Procedural:DeepLakeDiver", AuraReference = "LakeMist", AnimationSet = "LookAround", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1.05, Skin = rgb(176, 122, 84), Hair = rgb(30, 20, 15), HairStyle = "Buzz", Top = rgb(20, 30, 50), Bottom = rgb(20, 30, 50), Shoes = rgb(240, 200, 40), Accent = rgb(240, 200, 40), Glow = rgb(90, 230, 255), Face = "Determined", Accessories = { "Goggles", "FishingRod", "Lantern" } },
	},
	{
		Id = "ShadowHunter", DisplayName = "Shadow Hunter", Rarity = "Epic", RollChance = 1000,
		BaseMoneyPerSecond = 52, BasePower = 26, BaseFishingPower = 10, MaxLevel = 15, Category = "Human",
		VisualTheme = "dark 80s hunter: long black coat, goggles, tool belt and a glowing crossbow",
		Description = "Hunts what the flashlight kids are too young to see. Her crossbow bolts are wired to glow in the Otherworld.",
		ModelReference = "Procedural:ShadowHunter", AuraReference = "ShadowSmoke", AnimationSet = "Heavy", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1.1, Skin = rgb(198, 140, 98), Hair = rgb(20, 20, 25), HairStyle = "Long", Top = rgb(30, 30, 40), Bottom = rgb(25, 25, 30), Shoes = rgb(20, 20, 20), Accent = rgb(40, 35, 55), Glow = rgb(190, 120, 255), Face = "Determined", Accessories = { "Trenchcoat", "Crossbow", "Goggles", "Toolbelt" } },
	},
	{
		Id = "Telekinetic", DisplayName = "Telekinetic", Rarity = "Epic", RollChance = 1000,
		BaseMoneyPerSecond = 52, BasePower = 27, BaseFishingPower = 11, MaxLevel = 15, Category = "Human",
		VisualTheme = "curly-haired girl in a teal windbreaker and orange headband, rocks orbiting her",
		Description = "When she concentrates, bottle caps, pebbles and the occasional bicycle start to orbit her. She is still learning to put them down gently.",
		ModelReference = "Procedural:Telekinetic", AuraReference = "PsychicBlue", AnimationSet = "Psychic", Thumbnail = true, Source = "Original",
		Visual = { Body = "Teen", Scale = 0.95, Skin = rgb(141, 85, 54), Hair = rgb(30, 20, 15), HairStyle = "Curly", Top = rgb(40, 180, 170), Bottom = rgb(80, 70, 140), Shoes = rgb(240, 240, 240), Accent = rgb(250, 120, 60), Glow = rgb(130, 210, 255), Face = "Determined", Accessories = { "Headband", "OrbitDebris" } },
	},
	{
		Id = "RiftWalker", DisplayName = "Rift Walker", Rarity = "Epic", RollChance = 1100,
		BaseMoneyPerSecond = 55, BasePower = 28, BaseFishingPower = 11, MaxLevel = 15, Category = "Human",
		VisualTheme = "tall white-haired wanderer in a violet hood and scarf, rift crystal, blue-violet energy",
		Description = "Steps through hairline cracks in the air as if they were doors. Always comes back with frost on the shoulders.",
		ModelReference = "Procedural:RiftWalker", AuraReference = "RiftViolet", AnimationSet = "Float", Thumbnail = true, Source = "Original",
		Visual = { Body = "Tall", Scale = 1, Skin = rgb(220, 200, 190), Hair = rgb(230, 230, 240), HairStyle = "Long", Top = rgb(40, 30, 80), Bottom = rgb(30, 25, 60), Shoes = rgb(20, 20, 30), Accent = rgb(120, 60, 220), Glow = rgb(90, 200, 255), Face = "GlowEyes", Accessories = { "Hood", "Scarf", "Crystal" } },
	},
	{
		Id = "HeadResearcher", DisplayName = "Head Researcher", Rarity = "Epic", RollChance = 1200,
		BaseMoneyPerSecond = 57, BasePower = 29, BaseFishingPower = 12, MaxLevel = 15, Category = "Human",
		VisualTheme = "scientist with a dark bun, lab coat, amber goggles, ID badge and clipboard",
		Description = "Runs the night shift on Level B4. Her reports are written in two versions: the official one and the true one.",
		ModelReference = "Procedural:HeadResearcher", AuraReference = "Static", AnimationSet = "Investigate", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1, Skin = rgb(255, 226, 200), Hair = rgb(60, 40, 30), HairStyle = "Bun", Top = rgb(90, 110, 140), Bottom = rgb(60, 60, 70), Shoes = rgb(30, 30, 30), Accent = rgb(210, 120, 40), Glow = rgb(120, 255, 200), Face = "Calm", Accessories = { "LabCoat", "Goggles", "Badge", "Clipboard" } },
	},
	{
		Id = "Sleepwalker", DisplayName = "Sleepwalker", Rarity = "Epic", RollChance = 1250,
		BaseMoneyPerSecond = 58, BasePower = 29, BaseFishingPower = 12, MaxLevel = 15, Category = "Human",
		VisualTheme = "kid in blue pajamas, eyes closed, floating with a lavender nightlight",
		Description = "Floats out of bed every full moon and drifts toward the Black Pines. Never wakes up. Always comes home with pine needles.",
		ModelReference = "Procedural:Sleepwalker", AuraReference = "PsychicBlue", AnimationSet = "Float", Thumbnail = false, Source = "Original",
		Visual = { Body = "Kid", Scale = 0.95, Skin = rgb(240, 200, 165), Hair = rgb(120, 70, 40), HairStyle = "Messy", Top = rgb(140, 170, 230), Bottom = rgb(130, 160, 220), Shoes = rgb(230, 230, 230), Accent = rgb(250, 250, 250), Glow = rgb(200, 180, 255), Face = "Calm", Accessories = { "Lantern" } },
	},
	{
		Id = "MidnightMedium", DisplayName = "Midnight Medium", Rarity = "Epic", RollChance = 1300,
		BaseMoneyPerSecond = 60, BasePower = 30, BaseFishingPower = 12, MaxLevel = 15, Category = "Human",
		VisualTheme = "fortune teller in a plum shawl and gold scarf holding a glowing crystal",
		Description = "Reads palms at the county fair. Her crystal shows the Otherworld version of whoever is looking into it.",
		ModelReference = "Procedural:MidnightMedium", AuraReference = "Prism", AnimationSet = "Psychic", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1, Skin = rgb(86, 56, 38), Hair = rgb(20, 15, 15), HairStyle = "Long", Top = rgb(110, 40, 90), Bottom = rgb(60, 20, 50), Shoes = rgb(40, 20, 30), Accent = rgb(220, 180, 60), Glow = rgb(200, 120, 255), Face = "Calm", Accessories = { "Crystal", "Scarf", "Headband" } },
	},
	{
		Id = "StaticRider", DisplayName = "Static Rider", Rarity = "Epic", RollChance = 1400,
		BaseMoneyPerSecond = 63, BasePower = 31, BaseFishingPower = 11, MaxLevel = 15, Category = "Human",
		VisualTheme = "biker in a black jacket and helmet with a glowing visor, chains and electric sparks",
		Description = "Rides the Signal Road at midnight with the headlight off. The sparks are enough.",
		ModelReference = "Procedural:StaticRider", AuraReference = "ElectricSparks", AnimationSet = "Default", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1.05, Skin = rgb(234, 192, 150), Hair = rgb(30, 30, 30), HairStyle = "Mullet", Top = rgb(30, 30, 30), Bottom = rgb(40, 40, 60), Shoes = rgb(20, 20, 20), Accent = rgb(40, 40, 45), Glow = rgb(120, 220, 255), Face = "Visor", Accessories = { "Jacket", "BikeHelmet", "Chains" } },
	},
	{
		Id = "MoonMoth", DisplayName = "Moon Moth", Rarity = "Epic", RollChance = 1500,
		BaseMoneyPerSecond = 66, BasePower = 32, BaseFishingPower = 13, MaxLevel = 15, Category = "Creature",
		VisualTheme = "big pale silver-blue moth with frost-glowing wing eyes and long antennae",
		Description = "Only flies on cloudless nights. Where it lands, the grass freezes in the shape of its wings.",
		ModelReference = "Procedural:MoonMoth", AuraReference = "Frost", AnimationSet = "Hover", Thumbnail = false, Source = "Original",
		Visual = { Body = "Winged", Scale = 1.1, Skin = rgb(210, 215, 235), Top = rgb(190, 200, 240), Shoes = rgb(60, 60, 80), Accent = rgb(120, 130, 200), Glow = rgb(160, 220, 255), Face = "GlowEyes", Accessories = { "Antennae" } },
	},
	{
		Id = "ShadowProwler", DisplayName = "Shadow Prowler", Rarity = "Epic", RollChance = 1600,
		BaseMoneyPerSecond = 70, BasePower = 34, BaseFishingPower = 13, MaxLevel = 15, Category = "Creature",
		VisualTheme = "gaunt long-limbed shadow creature with a spiked spine, tail and red eyes",
		Description = "Lives in the gap between streetlights. If you count the shadows on your block and get one too many, it is visiting.",
		ModelReference = "Procedural:ShadowProwler", AuraReference = "ShadowSmoke", AnimationSet = "Creature", Thumbnail = false, Source = "Original",
		Visual = { Body = "Shade", Scale = 0.95, Skin = rgb(25, 20, 35), Top = rgb(20, 16, 30), Bottom = rgb(18, 14, 26), Shoes = rgb(10, 8, 16), Accent = rgb(60, 40, 90), Glow = rgb(255, 60, 90), Face = "GlowEyes", Accessories = { "Spikes", "Tail" } },
	},
	{
		Id = "SporeHive", DisplayName = "Spore Hive", Rarity = "Epic", RollChance = 1700,
		BaseMoneyPerSecond = 73, BasePower = 35, BaseFishingPower = 14, MaxLevel = 15, Category = "Creature",
		VisualTheme = "fungal hive of tan cells with green tendrils, glowing core and spore cloud",
		Description = "Grew overnight in the school boiler room. Its spores make everyone in the building dream the same dream.",
		ModelReference = "Procedural:SporeHive", AuraReference = "Spores", AnimationSet = "Pulse", Thumbnail = false, Source = "Original",
		Visual = { Body = "Hive", Scale = 0.9, Skin = rgb(130, 100, 70), Top = rgb(160, 120, 80), Accent = rgb(90, 160, 90), Glow = rgb(190, 255, 120), Face = "ManyEyes", Accessories = {} },
	},
	{
		Id = "RiftStalker", DisplayName = "Rift Stalker", Rarity = "Epic", RollChance = 1800,
		BaseMoneyPerSecond = 76, BasePower = 37, BaseFishingPower = 14, MaxLevel = 15, Category = "Creature",
		VisualTheme = "large violet parallel-world beast with many glowing eyes, spikes and fangs",
		Description = "A predator from the Otherworld that hunts by sound. Milbrook's car alarms drive it absolutely wild.",
		ModelReference = "Procedural:RiftStalker", AuraReference = "RiftViolet", AnimationSet = "Creature", Thumbnail = false, Source = "Original",
		Visual = { Body = "Quadruped", Scale = 1.35, Skin = rgb(40, 30, 60), Top = rgb(90, 50, 150), Shoes = rgb(15, 10, 20), Accent = rgb(25, 20, 35), Glow = rgb(180, 100, 255), Face = "ManyEyes", Accessories = { "Spikes", "Teeth" } },
	},
	{
		Id = "BogHydra", DisplayName = "Bog Hydra", Rarity = "Epic", RollChance = 1900,
		BaseMoneyPerSecond = 80, BasePower = 40, BaseFishingPower = 15, MaxLevel = 15, Category = "Creature",
		VisualTheme = "mossy green swamp serpent with horns and extra writhing tendrils",
		Description = "Every time the county drains the bog, it comes back with one more tendril.",
		ModelReference = "Procedural:BogHydra", AuraReference = "Spores", AnimationSet = "Serpent", Thumbnail = false, Source = "Original",
		Visual = { Body = "Serpent", Scale = 1.2, Skin = rgb(50, 90, 70), Top = rgb(40, 70, 55), Accent = rgb(150, 190, 90), Glow = rgb(255, 220, 80), Face = "GlowEyes", Accessories = { "Horns", "Tentacles" } },
	},
}

return characters
