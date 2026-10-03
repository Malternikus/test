--!strict
-- Characters > Legendary
-- Ziel-Summe der Chancen: 1/500. Einzelchancen 1 in 4000..8000.
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "LakeHermit", DisplayName = "Lake Hermit", Rarity = "Legendary", RollChance = 4000,
		BaseMoneyPerSecond = 180, BasePower = 60, BaseFishingPower = 26, MaxLevel = 15, Category = "Human",
		VisualTheme = "tall old hermit with long white hair and beard, patched coat, bucket hat, rod and lantern",
		Description = "Fishing specialist. Has lived in a shack on the lake since before the Rift. Catches things from the Otherworld and throws most of them back.",
		ModelReference = "Procedural:LakeHermit", AuraReference = "LakeMist", AnimationSet = "Sit", Thumbnail = false, Source = "Original",
		Visual = { Body = "Tall", Scale = 1.05, Skin = rgb(214, 164, 120), Hair = rgb(210, 210, 210), HairStyle = "Long", Top = rgb(90, 80, 60), Bottom = rgb(70, 60, 50), Shoes = rgb(50, 40, 30), Accent = rgb(110, 90, 60), Glow = rgb(120, 240, 255), Face = "Calm", Accessories = { "Beard", "FishingRod", "Lantern", "BucketHat" } },
	},
	{
		Id = "DimensionSurvivor", DisplayName = "Dimension Survivor", Rarity = "Legendary", RollChance = 4000,
		BaseMoneyPerSecond = 185, BasePower = 64, BaseFishingPower = 17, MaxLevel = 15, Category = "Human",
		VisualTheme = "scavenger in a torn shirt and red bandana with backpack, spiked bat, rift cracks sparking around",
		Description = "Spent a whole winter on the wrong side of the Rift and fought her way back with a scavenged spiked bat. Reality still cracks around her.",
		ModelReference = "Procedural:DimensionSurvivor", AuraReference = "RiftCracks", AnimationSet = "LookAround", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1.05, Skin = rgb(176, 122, 84), Hair = rgb(40, 30, 25), HairStyle = "Messy", Top = rgb(110, 100, 90), Bottom = rgb(60, 70, 90), Shoes = rgb(60, 40, 30), Accent = rgb(150, 40, 40), Glow = rgb(170, 90, 255), Face = "Determined", Accessories = { "SpikedBat", "Bandana", "Backpack" } },
	},
	{
		Id = "VoidSheriff", DisplayName = "Void Sheriff", Rarity = "Legendary", RollChance = 4500,
		BaseMoneyPerSecond = 195, BasePower = 68, BaseFishingPower = 18, MaxLevel = 15, Category = "Human",
		VisualTheme = "broad sheriff in tan, brown hat, gold badge, violet rift lantern and Otherworld scanner",
		Description = "Milbrook's sheriff stopped pretending nothing is wrong. Now he patrols both sides of the Rift with a lantern that burns violet.",
		ModelReference = "Procedural:VoidSheriff", AuraReference = "RiftViolet", AnimationSet = "Default", Thumbnail = true, Source = "Original",
		Visual = { Body = "Bulky", Scale = 1.05, Skin = rgb(234, 192, 150), Hair = rgb(90, 60, 40), HairStyle = "Short", Top = rgb(190, 160, 110), Bottom = rgb(70, 60, 50), Shoes = rgb(60, 40, 30), Accent = rgb(120, 90, 60), Glow = rgb(150, 90, 255), Face = "Determined", Accessories = { "SheriffHat", "Badge", "Lantern", "Detector" } },
	},
	{
		Id = "Pyrokinetic", DisplayName = "Pyrokinetic", Rarity = "Legendary", RollChance = 4500,
		BaseMoneyPerSecond = 195, BasePower = 70, BaseFishingPower = 17, MaxLevel = 15, Category = "Human",
		VisualTheme = "teen with spiky red hair, orange jacket, glowing ember eyes and rising sparks",
		Description = "Gets warm when angry. Gets very warm when very angry. The fire department knows his name.",
		ModelReference = "Procedural:Pyrokinetic", AuraReference = "Ember", AnimationSet = "Psychic", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 1, Skin = rgb(240, 200, 165), Hair = rgb(220, 90, 40), HairStyle = "Spiky", Top = rgb(40, 40, 40), Bottom = rgb(60, 40, 40), Shoes = rgb(200, 60, 30), Accent = rgb(240, 120, 30), Glow = rgb(255, 160, 60), Face = "GlowEyes", Accessories = { "Jacket", "Headband" } },
	},
	{
		Id = "TheExperiment", DisplayName = "The Experiment", Rarity = "Legendary", RollChance = 5000,
		BaseMoneyPerSecond = 210, BasePower = 74, BaseFishingPower = 18, MaxLevel = 15, Category = "Human",
		VisualTheme = "white-haired teen in a grey lab gown, electrode band, glowing eyes, debris orbiting in a psychic storm",
		Description = "Level B4's most successful project, and its biggest mistake. The walls of the lab still bend where they stood.",
		ModelReference = "Procedural:TheExperiment", AuraReference = "PsionicSurge", AnimationSet = "Psychic", Thumbnail = true, Source = "Original",
		Visual = { Body = "Teen", Scale = 1, Skin = rgb(230, 215, 210), Hair = rgb(240, 240, 245), HairStyle = "Messy", Top = rgb(200, 210, 220), Bottom = rgb(180, 190, 200), Shoes = rgb(220, 220, 230), Accent = rgb(60, 70, 90), Glow = rgb(140, 200, 255), Face = "GlowEyes", Accessories = { "Headband", "OrbitDebris" } },
	},
	{
		Id = "NeonOracle", DisplayName = "Neon Oracle", Rarity = "Legendary", RollChance = 5500,
		BaseMoneyPerSecond = 220, BasePower = 78, BaseFishingPower = 19, MaxLevel = 15, Category = "Human",
		VisualTheme = "hooded seer in neon pink with a third eye and a glowing staff",
		Description = "Sees every possible tomorrow at once, color-coded. Mostly uses it to win at bingo.",
		ModelReference = "Procedural:NeonOracle", AuraReference = "Prism", AnimationSet = "Psychic", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1, Skin = rgb(128, 82, 52), Hair = rgb(250, 120, 200), HairStyle = "Long", Top = rgb(40, 20, 60), Bottom = rgb(30, 15, 50), Shoes = rgb(20, 10, 30), Accent = rgb(255, 90, 200), Glow = rgb(90, 255, 230), Face = "Calm", Accessories = { "Hood", "ThirdEye", "Staff" } },
	},
	{
		Id = "ContainmentChief", DisplayName = "Containment Chief", Rarity = "Legendary", RollChance = 6000,
		BaseMoneyPerSecond = 235, BasePower = 82, BaseFishingPower = 19, MaxLevel = 15, Category = "Human",
		VisualTheme = "armored chief with a glowing visor, shoulder pads, riot shield and flashlight, frost aura",
		Description = "Leads the cryo team that seals breaches before breakfast. Has never lost a containment. Has lost a lot of shields.",
		ModelReference = "Procedural:ContainmentChief", AuraReference = "Frost", AnimationSet = "Heavy", Thumbnail = false, Source = "Original",
		Visual = { Body = "Bulky", Scale = 1.1, Skin = rgb(198, 140, 98), Hair = rgb(30, 30, 30), HairStyle = "Buzz", Top = rgb(70, 80, 90), Bottom = rgb(50, 55, 65), Shoes = rgb(25, 25, 30), Accent = rgb(60, 180, 220), Glow = rgb(120, 230, 255), Face = "Visor", Accessories = { "Shoulderpads", "Badge", "Flashlight", "Shield" } },
	},
	{
		Id = "RiftMantis", DisplayName = "Rift Mantis", Rarity = "Legendary", RollChance = 6500,
		BaseMoneyPerSecond = 250, BasePower = 86, BaseFishingPower = 20, MaxLevel = 15, Category = "Creature",
		VisualTheme = "jade six-legged mantis with wings, antennae, mandibles and violet rift sparks",
		Description = "Cuts the air with its forelegs and leaves glowing seams behind. Patient, precise, and very hungry.",
		ModelReference = "Procedural:RiftMantis", AuraReference = "RiftCracks", AnimationSet = "Crawler", Thumbnail = false, Source = "Original",
		Visual = { Body = "Crawler", Scale = 1.3, Skin = rgb(80, 200, 140), Top = rgb(40, 120, 90), Shoes = rgb(30, 80, 60), Accent = rgb(200, 255, 200), Glow = rgb(200, 120, 255), Face = "ManyEyes", Accessories = { "Mandibles", "Wings", "Antennae" } },
	},
	{
		Id = "AbyssalEel", DisplayName = "Abyssal Eel", Rarity = "Legendary", RollChance = 7000,
		BaseMoneyPerSecond = 265, BasePower = 90, BaseFishingPower = 24, MaxLevel = 15, Category = "Creature",
		VisualTheme = "deep-blue eel rising from the water with cyan glow lines, back spines and teeth",
		Description = "Lives in the part of Milbrook Lake that is deeper than the lake. Its glow can be seen from the pier on moonless nights.",
		ModelReference = "Procedural:AbyssalEel", AuraReference = "LakeMist", AnimationSet = "Serpent", Thumbnail = false, Source = "Original",
		Visual = { Body = "Serpent", Scale = 1.3, Skin = rgb(20, 40, 60), Top = rgb(30, 60, 90), Accent = rgb(60, 200, 220), Glow = rgb(90, 255, 230), Face = "GlowEyes", Accessories = { "Spikes", "Teeth" } },
	},
	{
		Id = "StaticAlpha", DisplayName = "Static Alpha", Rarity = "Legendary", RollChance = 7500,
		BaseMoneyPerSecond = 280, BasePower = 95, BaseFishingPower = 20, MaxLevel = 15, Category = "Creature",
		VisualTheme = "huge horned static hound, white crackling mane, spiked spine, electric aura",
		Description = "Leader of the static pack. When it howls, every TV in Milbrook switches to the same dead channel.",
		ModelReference = "Procedural:StaticAlpha", AuraReference = "ElectricSparks", AnimationSet = "Creature", Thumbnail = false, Source = "Original",
		Visual = { Body = "Quadruped", Scale = 1.6, Skin = rgb(35, 40, 55), Top = rgb(230, 240, 255), Shoes = rgb(10, 10, 15), Accent = rgb(20, 20, 30), Glow = rgb(130, 230, 255), Face = "GlowEyes", Accessories = { "Spikes", "Horns" } },
	},
	{
		Id = "PaleUsher", DisplayName = "Pale Usher", Rarity = "Legendary", RollChance = 8000,
		BaseMoneyPerSecond = 300, BasePower = 100, BaseFishingPower = 22, MaxLevel = 15, Category = "Entity",
		VisualTheme = "floating white-robed guide with a blank white mask, golden halo and lantern",
		Description = "Appears at the edge of the Black Pines to guide lost travelers home. Nobody has ever asked where its home is.",
		ModelReference = "Procedural:PaleUsher", AuraReference = "Otherglow", AnimationSet = "Float", Thumbnail = false, Source = "Original",
		Visual = { Body = "Floating", Scale = 1.15, Skin = rgb(230, 230, 240), Top = rgb(220, 220, 230), Bottom = rgb(160, 160, 180), Accent = rgb(240, 240, 245), Glow = rgb(255, 240, 200), Face = "Mask", Accessories = { "Lantern", "Halo" } },
	},
}

return characters
