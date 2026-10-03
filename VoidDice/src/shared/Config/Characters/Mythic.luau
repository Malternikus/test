--!strict
-- Characters > Mythic
-- Ziel-Summe der Chancen: 1/2500. Einzelchancen 1 in 16000..32000.
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "AbyssAngler", DisplayName = "Abyss Angler", Rarity = "Mythic", RollChance = 16000,
		BaseMoneyPerSecond = 700, BasePower = 150, BaseFishingPower = 40, MaxLevel = 15, Category = "Human",
		VisualTheme = "hulking grey-blue fisherman in a dripping coat, hollow eyes and a glowing lure on his head",
		Description = "Fishing specialist. Fished the Rift itself for so long that he grew his own lure. Earns the least of his kind, lands the impossible.",
		ModelReference = "Procedural:AbyssAngler", AuraReference = "LakeMist", AnimationSet = "Sit", Thumbnail = false, Source = "Original",
		Visual = { Body = "Bulky", Scale = 1.2, Skin = rgb(90, 110, 120), Hair = rgb(20, 30, 40), HairStyle = "Long", Top = rgb(30, 50, 60), Bottom = rgb(20, 30, 40), Shoes = rgb(15, 20, 25), Accent = rgb(40, 70, 80), Glow = rgb(90, 255, 230), Face = "Hollow", Accessories = { "Antennae", "FishingRod", "Trenchcoat" } },
	},
	{
		Id = "RiftCommander", DisplayName = "Rift Commander", Rarity = "Mythic", RollChance = 18000,
		BaseMoneyPerSecond = 740, BasePower = 165, BaseFishingPower = 27, MaxLevel = 15, Category = "Human",
		VisualTheme = "armored commander with a violet cape, glowing visor, shoulder pads and command staff",
		Description = "Leads the Milbrook Rift Brigade from the front. The violet cape is cut from a tear in reality she personally sewed shut.",
		ModelReference = "Procedural:RiftCommander", AuraReference = "RiftViolet", AnimationSet = "Heavy", Thumbnail = true, Source = "Original",
		Visual = { Body = "Bulky", Scale = 1.25, Skin = rgb(176, 122, 84), Hair = rgb(40, 40, 40), HairStyle = "Buzz", Top = rgb(40, 40, 60), Bottom = rgb(30, 30, 45), Shoes = rgb(20, 20, 25), Accent = rgb(140, 70, 255), Glow = rgb(180, 110, 255), Face = "Visor", Accessories = { "Cape", "Shoulderpads", "Badge", "Staff" } },
	},
	{
		Id = "StormCaller", DisplayName = "Storm Caller", Rarity = "Mythic", RollChance = 20000,
		BaseMoneyPerSecond = 780, BasePower = 175, BaseFishingPower = 28, MaxLevel = 15, Category = "Human",
		VisualTheme = "white-spiked hair, blue cape, lightning staff and storm debris whirling around him",
		Description = "Pulls lightning out of clear skies. Milbrook's weatherman has given up predicting anything.",
		ModelReference = "Procedural:StormCaller", AuraReference = "ElectricSparks", AnimationSet = "Psychic", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1.12, Skin = rgb(141, 85, 54), Hair = rgb(230, 240, 255), HairStyle = "Spiky", Top = rgb(40, 60, 110), Bottom = rgb(30, 40, 70), Shoes = rgb(20, 20, 30), Accent = rgb(90, 170, 255), Glow = rgb(150, 230, 255), Face = "GlowEyes", Accessories = { "Cape", "Staff", "OrbitDebris" } },
	},
	{
		Id = "Voidborn", DisplayName = "Voidborn", Rarity = "Mythic", RollChance = 22000,
		BaseMoneyPerSecond = 830, BasePower = 190, BaseFishingPower = 30, MaxLevel = 15, Category = "Human",
		VisualTheme = "tall figure with violet-black skin, long dark hair, cape and orbiting void shards",
		Description = "Born in Milbrook the night the Rift first opened. Their shadow points toward the Void no matter where the light is.",
		ModelReference = "Procedural:Voidborn", AuraReference = "VoidVortex", AnimationSet = "Float", Thumbnail = false, Source = "Original",
		Visual = { Body = "Tall", Scale = 1.15, Skin = rgb(40, 25, 70), Hair = rgb(10, 5, 20), HairStyle = "Long", Top = rgb(15, 10, 30), Bottom = rgb(12, 8, 24), Shoes = rgb(5, 5, 10), Accent = rgb(130, 60, 255), Glow = rgb(210, 170, 255), Face = "GlowEyes", Accessories = { "Cape", "OrbitDebris" } },
	},
	{
		Id = "PsionicZero", DisplayName = "Psionic Zero", Rarity = "Mythic", RollChance = 24000,
		BaseMoneyPerSecond = 880, BasePower = 205, BaseFishingPower = 31, MaxLevel = 15, Category = "Human",
		VisualTheme = "kid in a white uniform with white hair, glowing blue eyes, energy ring and floating debris",
		Description = "The program's file just says 'Zero'. Lifts cars without blinking and hums the same lullaby while doing it.",
		ModelReference = "Procedural:PsionicZero", AuraReference = "PsionicSurge", AnimationSet = "Float", Thumbnail = true, Source = "Original",
		Visual = { Body = "Kid", Scale = 1, Skin = rgb(240, 215, 200), Hair = rgb(235, 235, 245), HairStyle = "Short", Top = rgb(230, 235, 245), Bottom = rgb(210, 215, 225), Shoes = rgb(240, 240, 250), Accent = rgb(90, 140, 255), Glow = rgb(120, 190, 255), Face = "GlowEyes", Accessories = { "Headband", "OrbitRing", "OrbitDebris" } },
	},
	{
		Id = "ThunderMoth", DisplayName = "Thunder Moth", Rarity = "Mythic", RollChance = 26000,
		BaseMoneyPerSecond = 930, BasePower = 215, BaseFishingPower = 33, MaxLevel = 15, Category = "Creature",
		VisualTheme = "giant storm-blue moth with golden lightning wing eyes and many glowing eyes",
		Description = "Its wingbeats are the thunder you hear on clear nights. Lightning follows it like moths follow a lamp.",
		ModelReference = "Procedural:ThunderMoth", AuraReference = "ElectricSparks", AnimationSet = "Hover", Thumbnail = false, Source = "Original",
		Visual = { Body = "Winged", Scale = 1.5, Skin = rgb(40, 40, 60), Top = rgb(60, 80, 160), Shoes = rgb(20, 20, 30), Accent = rgb(230, 220, 90), Glow = rgb(255, 240, 100), Face = "ManyEyes", Accessories = { "Antennae" } },
	},
	{
		Id = "HiveMother", DisplayName = "Hive Mother", Rarity = "Mythic", RollChance = 28000,
		BaseMoneyPerSecond = 980, BasePower = 225, BaseFishingPower = 34, MaxLevel = 15, Category = "Creature",
		VisualTheme = "crowned magenta flesh-hive with tentacles, glowing core and a swarm",
		Description = "The source of every drone under the Black Pines. Wears the old Milbrook water tower bell as a crown.",
		ModelReference = "Procedural:HiveMother", AuraReference = "Spores", AnimationSet = "Pulse", Thumbnail = false, Source = "Original",
		Visual = { Body = "Hive", Scale = 1.4, Skin = rgb(150, 60, 90), Top = rgb(120, 40, 70), Accent = rgb(220, 120, 160), Glow = rgb(255, 90, 180), Face = "ManyEyes", Accessories = { "Crown", "Tentacles" } },
	},
	{
		Id = "StaticPhantom", DisplayName = "Static Phantom", Rarity = "Mythic", RollChance = 30000,
		BaseMoneyPerSecond = 1040, BasePower = 240, BaseFishingPower = 36, MaxLevel = 15, Category = "Entity",
		VisualTheme = "floating grey robe made of TV static with hollow glowing eyes and trailing tendrils",
		Description = "Lives in the snow between TV channels. Steps out when someone falls asleep with the set still on.",
		ModelReference = "Procedural:StaticPhantom", AuraReference = "Static", AnimationSet = "Float", Thumbnail = false, Source = "Original",
		Visual = { Body = "Floating", Scale = 1.3, Skin = rgb(200, 210, 230), Top = rgb(150, 160, 180), Bottom = rgb(90, 100, 120), Accent = rgb(230, 240, 255), Glow = rgb(230, 240, 255), Face = "Hollow", Accessories = { "Tentacles" } },
	},
	{
		Id = "SignalChoir", DisplayName = "Signal Choir", Rarity = "Mythic", RollChance = 32000,
		BaseMoneyPerSecond = 1100, BasePower = 250, BaseFishingPower = 38, MaxLevel = 15, Category = "Entity",
		VisualTheme = "glass orb with a pink core, many eyes, double rings and orbiting eyeballs",
		Description = "A chorus of a thousand radio voices sealed in one glowing orb. It sings every song that was ever lost to static.",
		ModelReference = "Procedural:SignalChoir", AuraReference = "Prism", AnimationSet = "Hover", Thumbnail = false, Source = "Original",
		Visual = { Body = "Orb", Scale = 1.6, Skin = rgb(220, 240, 255), Accent = rgb(90, 220, 255), Glow = rgb(255, 120, 200), Face = "ManyEyes", Accessories = { "OrbitEyes" } },
	},
}

return characters
