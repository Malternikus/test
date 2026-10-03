--!strict
-- Characters > Void
-- Ziel-Summe der Chancen: 1/50000. Einzelchancen 1 in 220000..400000.
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "RiftFerryman", DisplayName = "Rift Ferryman", Rarity = "Void", RollChance = 220000,
		BaseMoneyPerSecond = 10000, BasePower = 1000, BaseFishingPower = 90, MaxLevel = 15, Category = "Human",
		VisualTheme = "tall grey-skinned boatman in a dark hood with a teal lantern and long fishing rod",
		Description = "Fishing specialist. Rows lost things back across the Rift for a fee of one memory each. Fishes the in-between while he waits.",
		ModelReference = "Procedural:RiftFerryman", AuraReference = "Otherglow", AnimationSet = "Sit", Thumbnail = false, Source = "Original",
		Visual = { Body = "Tall", Scale = 1.3, Skin = rgb(150, 140, 170), Hair = rgb(20, 20, 30), HairStyle = "None", Top = rgb(30, 25, 45), Bottom = rgb(20, 15, 35), Shoes = rgb(10, 10, 20), Accent = rgb(40, 30, 60), Glow = rgb(120, 255, 220), Face = "Hollow", Accessories = { "Hood", "Lantern", "FishingRod" } },
	},
	{
		Id = "TheSwarmBelow", DisplayName = "The Swarm Below", Rarity = "Void", RollChance = 250000,
		BaseMoneyPerSecond = 11000, BasePower = 1100, BaseFishingPower = 64, MaxLevel = 15, Category = "Creature",
		VisualTheme = "giant dark hive with crimson glowing core, tentacles, swarm and orbiting rubble",
		Description = "Every hive under Milbrook is one organ of something far larger. This is the part that finally surfaced.",
		ModelReference = "Procedural:TheSwarmBelow", AuraReference = "Abyss", AnimationSet = "Pulse", Thumbnail = false, Source = "Original",
		Visual = { Body = "Hive", Scale = 2, Skin = rgb(40, 30, 40), Top = rgb(70, 40, 60), Accent = rgb(120, 60, 90), Glow = rgb(255, 60, 120), Face = "ManyEyes", Accessories = { "OrbitDebris", "Tentacles" } },
	},
	{
		Id = "AbyssWalker", DisplayName = "Abyss Walker", Rarity = "Void", RollChance = 280000,
		BaseMoneyPerSecond = 12200, BasePower = 1250, BaseFishingPower = 68, MaxLevel = 15, Category = "Entity",
		VisualTheme = "towering pitch-black shade with horns, hollow violet eyes, back tendrils and orbiting void rocks",
		Description = "Walks the floor of the Void where there is no floor. Each step it takes leaves a hole in the world for a second.",
		ModelReference = "Procedural:AbyssWalker", AuraReference = "Abyss", AnimationSet = "Float", Thumbnail = true, Source = "Original",
		Visual = { Body = "Shade", Scale = 1.7, Skin = rgb(10, 10, 20), Top = rgb(15, 12, 30), Bottom = rgb(10, 8, 20), Shoes = rgb(5, 5, 10), Accent = rgb(60, 30, 120), Glow = rgb(150, 80, 255), Face = "Hollow", Accessories = { "Horns", "Tentacles", "OrbitDebris" } },
	},
	{
		Id = "StarfallColossus", DisplayName = "Starfall Colossus", Rarity = "Void", RollChance = 320000,
		BaseMoneyPerSecond = 13400, BasePower = 1380, BaseFishingPower = 72, MaxLevel = 15, Category = "Entity",
		VisualTheme = "cosmic indigo giant with starlight plates, glowing core, halo and a ring of light",
		Description = "Fell out of the night sky over the Black Pines and never stopped glowing. The stars in its chest are not ours.",
		ModelReference = "Procedural:StarfallColossus", AuraReference = "Starfield", AnimationSet = "Heavy", Thumbnail = false, Source = "Original",
		Visual = { Body = "Colossus", Scale = 1.9, Skin = rgb(30, 30, 70), Top = rgb(40, 30, 90), Bottom = rgb(30, 20, 70), Shoes = rgb(20, 15, 50), Accent = rgb(240, 230, 255), Glow = rgb(255, 240, 180), Face = "GlowEyes", Accessories = { "Halo", "OrbitRing" } },
	},
	{
		Id = "DimensionEater", DisplayName = "Dimension Eater", Rarity = "Void", RollChance = 360000,
		BaseMoneyPerSecond = 14700, BasePower = 1500, BaseFishingPower = 80, MaxLevel = 15, Category = "Creature",
		VisualTheme = "enormous purple maw-blob with many eyes, fangs, mandibles, tentacles and swirling debris",
		Description = "Swallows pocket dimensions whole. The debris orbiting it is what is left of the last three.",
		ModelReference = "Procedural:DimensionEater", AuraReference = "VoidVortex", AnimationSet = "Pulse", Thumbnail = true, Source = "Original",
		Visual = { Body = "Blob", Scale = 2.2, Skin = rgb(50, 20, 70), Top = rgb(90, 30, 120), Bottom = rgb(20, 5, 30), Accent = rgb(255, 80, 160), Glow = rgb(255, 120, 220), Face = "ManyEyes", Accessories = { "Teeth", "Mandibles", "Tentacles", "OrbitDebris" } },
	},
	{
		Id = "TheUnknown", DisplayName = "The Unknown", Rarity = "Void", RollChance = 400000,
		BaseMoneyPerSecond = 16000, BasePower = 1600, BaseFishingPower = 85, MaxLevel = 15, Category = "Entity",
		VisualTheme = "featureless black robed silhouette with a white light ring and orbiting white shards",
		Description = "Nobody who has seen it can describe it afterward. Every photo of it comes out as a perfect black rectangle.",
		ModelReference = "Procedural:TheUnknown", AuraReference = "Static", AnimationSet = "Float", Thumbnail = false, Source = "Original",
		Visual = { Body = "Floating", Scale = 2, Skin = rgb(10, 10, 10), Top = rgb(8, 8, 12), Bottom = rgb(20, 20, 30), Accent = rgb(255, 255, 255), Glow = rgb(255, 255, 255), Face = "Blank", Accessories = { "OrbitRing", "OrbitDebris" } },
	},
}

return characters
