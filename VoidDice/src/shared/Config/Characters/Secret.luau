--!strict
-- Characters > Secret
-- Ziel-Summe der Chancen: 1/250000. Einzelchancen 1 in 750000..1300000.
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "TheMirrorTwin", DisplayName = "The Mirror Twin", Rarity = "Secret", RollChance = 750000,
		BaseMoneyPerSecond = 45000, BasePower = 2500, BaseFishingPower = 100, MaxLevel = 15, Category = "Human",
		VisualTheme = "Otherworld copy of the Mystery Kid: inverted colors, cyan skin, hollow eyes, floating shards",
		Description = "The Mystery Kid's reflection from the Otherworld. Same flashlight, same walkie, same channel 9. It answers before you speak.",
		ModelReference = "Procedural:TheMirrorTwin", AuraReference = "Prism", AnimationSet = "Flashlight", Thumbnail = false, Source = "Original",
		Visual = { Body = "Kid", Scale = 1, Skin = rgb(160, 200, 210), Hair = rgb(20, 60, 60), HairStyle = "Messy", Top = rgb(40, 120, 200), Bottom = rgb(200, 160, 90), Shoes = rgb(20, 20, 20), Accent = rgb(40, 200, 200), Glow = rgb(60, 255, 220), Face = "Hollow", Accessories = { "Flashlight", "WalkieTalkie", "Backpack", "OrbitDebris" } },
	},
	{
		Id = "TheLostOne", DisplayName = "The Lost One", Rarity = "Secret", RollChance = 900000,
		BaseMoneyPerSecond = 52000, BasePower = 2900, BaseFishingPower = 110, MaxLevel = 15, Category = "Human",
		VisualTheme = "pale kid with long overgrown hair, faded 80s jacket and scarf, carrying a teal Otherworld lantern",
		Description = "Wandered into the Black Pines during the summer of '86 and walked out yesterday without having aged a day. Insists it was only one night.",
		ModelReference = "Procedural:TheLostOne", AuraReference = "Otherglow", AnimationSet = "LookAround", Thumbnail = true, Source = "Original",
		Visual = { Body = "Kid", Scale = 0.95, Skin = rgb(220, 225, 235), Hair = rgb(90, 70, 50), HairStyle = "Long", Top = rgb(150, 120, 90), Bottom = rgb(70, 80, 110), Shoes = rgb(120, 110, 100), Accent = rgb(150, 60, 60), Glow = rgb(90, 255, 210), Face = "Worried", Accessories = { "Lantern", "Jacket", "Scarf" } },
	},
	{
		Id = "RedSignal", DisplayName = "Red Signal", Rarity = "Secret", RollChance = 1100000,
		BaseMoneyPerSecond = 61000, BasePower = 3400, BaseFishingPower = 120, MaxLevel = 15, Category = "Entity",
		VisualTheme = "blazing red signal orb with antennae and a spinning red ring",
		Description = "The signal every radio in Milbrook has been picking up. It was never a message. It was a location, and now it is here.",
		ModelReference = "Procedural:RedSignal", AuraReference = "RedSignal", AnimationSet = "Pulse", Thumbnail = true, Source = "Original",
		Visual = { Body = "Orb", Scale = 2.3, Skin = rgb(255, 80, 80), Accent = rgb(140, 0, 0), Glow = rgb(255, 30, 30), Face = "Blank", Accessories = { "Antennae", "OrbitRing" } },
	},
	{
		Id = "TheFirstSubject", DisplayName = "The First Subject", Rarity = "Secret", RollChance = 1300000,
		BaseMoneyPerSecond = 70000, BasePower = 4000, BaseFishingPower = 130, MaxLevel = 15, Category = "Human",
		VisualTheme = "tall pale figure in a grey lab gown with broken restraint chains, red halo and red glowing eyes",
		Description = "The very first patient of Level B4, sealed away before the program had a name. The restraints broke years ago. It stayed to listen.",
		ModelReference = "Procedural:TheFirstSubject", AuraReference = "RedSignal", AnimationSet = "Psychic", Thumbnail = true, Source = "Original",
		Visual = { Body = "Tall", Scale = 1.25, Skin = rgb(235, 225, 225), HairStyle = "None", Top = rgb(200, 200, 210), Bottom = rgb(170, 170, 185), Shoes = rgb(200, 200, 210), Accent = rgb(180, 30, 40), Glow = rgb(255, 50, 60), Face = "GlowEyes", Accessories = { "Chains", "Halo", "OrbitDebris" } },
	},
}

return characters
