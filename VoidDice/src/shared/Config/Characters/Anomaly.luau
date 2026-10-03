--!strict
-- Characters > Anomaly
-- Feste Chancen: The Endless 1 in 2.5M, The Null Child 1 in 5M, The Watcher Beyond 1 in 10M.
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "TheEndless", DisplayName = "The Endless", Rarity = "Anomaly", RollChance = 2500000,
		BaseMoneyPerSecond = 220000, BasePower = 7000, BaseFishingPower = 150, MaxLevel = 15, Category = "Entity",
		VisualTheme = "blinding white orb inside endless rings of light, halo and drifting starlit shards",
		Description = "It has no beginning, so it cannot end. The rings around it are every loop time has ever made in Milbrook.",
		ModelReference = "Procedural:TheEndless", AuraReference = "Starfield", AnimationSet = "Hover", Thumbnail = true, Source = "Original",
		Visual = { Body = "Orb", Scale = 2.6, Skin = rgb(255, 255, 255), Accent = rgb(0, 255, 200), Glow = rgb(255, 255, 255), Face = "Blank", Accessories = { "OrbitRing", "OrbitDebris", "Halo" } },
	},
	{
		Id = "TheNullChild", DisplayName = "The Null Child", Rarity = "Anomaly", RollChance = 5000000,
		BaseMoneyPerSecond = 300000, BasePower = 9500, BaseFishingPower = 170, MaxLevel = 15, Category = "Human",
		VisualTheme = "all-white child with cyan glowing eyes, a halo and floating shards over a ring of light",
		Description = "A child made of the space where the Void used to be. When it laughs, the Rift closes a little.",
		ModelReference = "Procedural:TheNullChild", AuraReference = "NullLight", AnimationSet = "Float", Thumbnail = true, Source = "Original",
		Visual = { Body = "Kid", Scale = 1.05, Skin = rgb(250, 250, 255), Hair = rgb(255, 255, 255), HairStyle = "Bowl", Top = rgb(250, 250, 255), Bottom = rgb(240, 240, 250), Shoes = rgb(255, 255, 255), Accent = rgb(0, 255, 200), Glow = rgb(0, 255, 200), Face = "GlowEyes", Accessories = { "Halo", "OrbitDebris" } },
	},
	{
		Id = "TheWatcherBeyond", DisplayName = "The Watcher Beyond", Rarity = "Anomaly", RollChance = 10000000,
		BaseMoneyPerSecond = 400000, BasePower = 12000, BaseFishingPower = 200, MaxLevel = 15, Category = "Entity",
		VisualTheme = "colossal void eye with magenta iris, halo, ring of light and a circle of lesser eyes",
		Description = "The Observer was only its reflection. It looks at Milbrook from beyond the Void, and today, Milbrook looked back.",
		ModelReference = "Procedural:TheWatcherBeyond", AuraReference = "Abyss", AnimationSet = "Hover", Thumbnail = true, Source = "Original",
		Visual = { Body = "Eye", Scale = 2.6, Skin = rgb(255, 250, 240), Top = rgb(20, 10, 40), Accent = rgb(60, 20, 90), Glow = rgb(255, 40, 200), Face = "Blank", Accessories = { "OrbitEyes", "OrbitRing", "Halo" } },
	},
}

return characters
