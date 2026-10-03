--!strict
-- Characters > Supernatural
-- Ziel-Summe der Chancen: 1/10000. Einzelchancen 1 in 50000..100000.
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "LakeSovereign", DisplayName = "Lake Sovereign", Rarity = "Supernatural", RollChance = 50000,
		BaseMoneyPerSecond = 2600, BasePower = 400, BaseFishingPower = 60, MaxLevel = 15, Category = "Creature",
		VisualTheme = "colossal crowned lake serpent, teal scales, back spines and writhing tendrils",
		Description = "Fishing specialist. Ancient ruler of everything beneath Milbrook Lake. Pays tribute in fish rather than coins.",
		ModelReference = "Procedural:LakeSovereign", AuraReference = "LakeMist", AnimationSet = "Serpent", Thumbnail = false, Source = "Original",
		Visual = { Body = "Serpent", Scale = 2, Skin = rgb(20, 60, 80), Top = rgb(30, 90, 110), Accent = rgb(200, 240, 255), Glow = rgb(120, 255, 240), Face = "GlowEyes", Accessories = { "Crown", "Spikes", "Tentacles" } },
	},
	{
		Id = "BlackPinesWarden", DisplayName = "Black Pines Warden", Rarity = "Supernatural", RollChance = 55000,
		BaseMoneyPerSecond = 2800, BasePower = 430, BaseFishingPower = 44, MaxLevel = 15, Category = "Human",
		VisualTheme = "tall forest guardian in a moss cape with bone antlers, glowing eyes and a staff",
		Description = "The last ranger of the Black Pines. Somewhere along the way the forest decided to keep her, and gave her antlers.",
		ModelReference = "Procedural:BlackPinesWarden", AuraReference = "Fireflies", AnimationSet = "LookAround", Thumbnail = false, Source = "Original",
		Visual = { Body = "Tall", Scale = 1.2, Skin = rgb(176, 122, 84), Hair = rgb(40, 30, 20), HairStyle = "Long", Top = rgb(50, 70, 50), Bottom = rgb(40, 50, 35), Shoes = rgb(40, 30, 20), Accent = rgb(190, 170, 130), Glow = rgb(180, 255, 140), Face = "GlowEyes", Accessories = { "Antlers", "Cape", "Staff" } },
	},
	{
		Id = "WinterHerald", DisplayName = "Winter Herald", Rarity = "Supernatural", RollChance = 60000,
		BaseMoneyPerSecond = 3000, BasePower = 470, BaseFishingPower = 46, MaxLevel = 15, Category = "Entity",
		VisualTheme = "towering ice-blue robed spirit with an icy crown, mask and frost staff",
		Description = "Arrives one night before the first snow and walks Main Street once. Every clock it passes stops for exactly one minute.",
		ModelReference = "Procedural:WinterHerald", AuraReference = "Frost", AnimationSet = "Float", Thumbnail = false, Source = "Original",
		Visual = { Body = "Floating", Scale = 1.6, Skin = rgb(200, 230, 255), Top = rgb(160, 200, 240), Bottom = rgb(100, 140, 200), Accent = rgb(230, 250, 255), Glow = rgb(180, 240, 255), Face = "Mask", Accessories = { "Crown", "Staff" } },
	},
	{
		Id = "TheGatekeeper", DisplayName = "The Gatekeeper", Rarity = "Supernatural", RollChance = 70000,
		BaseMoneyPerSecond = 3300, BasePower = 520, BaseFishingPower = 48, MaxLevel = 15, Category = "Entity",
		VisualTheme = "stone colossus with bronze plates, horns, chains, mask and a giant glowing key",
		Description = "Guards the one door between Milbrook and the Otherworld. It has never been asked to open it. It is waiting.",
		ModelReference = "Procedural:TheGatekeeper", AuraReference = "Golden", AnimationSet = "Heavy", Thumbnail = false, Source = "Original",
		Visual = { Body = "Colossus", Scale = 1.6, Skin = rgb(60, 55, 70), Top = rgb(70, 60, 90), Bottom = rgb(50, 45, 60), Shoes = rgb(30, 25, 35), Accent = rgb(200, 160, 60), Glow = rgb(255, 170, 60), Face = "Mask", Accessories = { "GateKey", "Chains", "Horns" } },
	},
	{
		Id = "TheBroadcast", DisplayName = "The Broadcast", Rarity = "Supernatural", RollChance = 80000,
		BaseMoneyPerSecond = 3600, BasePower = 560, BaseFishingPower = 52, MaxLevel = 15, Category = "Entity",
		VisualTheme = "white static orb with a glowing screen-visor face, antennae and orbiting debris",
		Description = "A transmission that became self-aware somewhere over Milbrook. It wants everyone to stay tuned.",
		ModelReference = "Procedural:TheBroadcast", AuraReference = "Static", AnimationSet = "Pulse", Thumbnail = false, Source = "Original",
		Visual = { Body = "Orb", Scale = 2, Skin = rgb(230, 230, 240), Accent = rgb(120, 130, 150), Glow = rgb(240, 240, 255), Face = "Visor", Accessories = { "Antennae", "OrbitDebris" } },
	},
	{
		Id = "ShadowKing", DisplayName = "Shadow King", Rarity = "Supernatural", RollChance = 90000,
		BaseMoneyPerSecond = 3900, BasePower = 610, BaseFishingPower = 55, MaxLevel = 15, Category = "Entity",
		VisualTheme = "towering black shade with a violet crown, cape, shadow tendrils and burning violet eyes",
		Description = "Every shadow in Milbrook answers to it. On the longest night of the year, they all point toward its throne.",
		ModelReference = "Procedural:ShadowKing", AuraReference = "ShadowSmoke", AnimationSet = "Float", Thumbnail = true, Source = "Original",
		Visual = { Body = "Shade", Scale = 1.5, Skin = rgb(20, 15, 30), Top = rgb(25, 18, 40), Bottom = rgb(15, 10, 25), Shoes = rgb(10, 5, 15), Accent = rgb(110, 50, 200), Glow = rgb(200, 90, 255), Face = "GlowEyes", Accessories = { "Crown", "Cape", "Tentacles" } },
	},
	{
		Id = "TheObserver", DisplayName = "The Observer", Rarity = "Supernatural", RollChance = 100000,
		BaseMoneyPerSecond = 4200, BasePower = 650, BaseFishingPower = 58, MaxLevel = 15, Category = "Entity",
		VisualTheme = "giant floating eye with violet lids, cyan iris, halo and orbiting shards on tendril legs",
		Description = "Has watched Milbrook since before there was a Milbrook. It never blinks. It has started to take notes.",
		ModelReference = "Procedural:TheObserver", AuraReference = "PsychicBlue", AnimationSet = "Hover", Thumbnail = true, Source = "Original",
		Visual = { Body = "Eye", Scale = 2, Skin = rgb(240, 235, 225), Top = rgb(60, 40, 80), Accent = rgb(90, 60, 110), Glow = rgb(90, 220, 255), Face = "Blank", Accessories = { "Halo", "OrbitDebris" } },
	},
}

return characters
