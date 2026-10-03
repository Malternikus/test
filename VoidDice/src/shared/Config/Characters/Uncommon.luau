--!strict
-- Characters > Uncommon
-- Ziel-Summe der Chancen: 1/5. Einzelchancen 1 in 50..120.
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "CreekAngler", DisplayName = "Creek Angler", Rarity = "Uncommon", RollChance = 55,
		BaseMoneyPerSecond = 4, BasePower = 4, BaseFishingPower = 6, MaxLevel = 15, Category = "Human",
		VisualTheme = "flannel teen with khaki bucket hat, fishing vest and rod",
		Description = "Fishing specialist. Knows every bend of Milbrook Creek, including the one that only appears after rain. Low income, huge catches.",
		ModelReference = "Procedural:CreekAngler", AuraReference = nil, AnimationSet = "Sit", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 1, Skin = rgb(214, 164, 120), Hair = rgb(120, 70, 30), HairStyle = "Short", Top = rgb(150, 60, 50), Bottom = rgb(70, 80, 100), Shoes = rgb(90, 70, 50), Accent = rgb(190, 170, 110), Face = "Calm", Accessories = { "FishingRod", "BucketHat", "Vest" } },
	},
	{
		Id = "SignalHunter", DisplayName = "Signal Hunter", Rarity = "Uncommon", RollChance = 55,
		BaseMoneyPerSecond = 4, BasePower = 4, BaseFishingPower = 3, MaxLevel = 15, Category = "Human",
		VisualTheme = "teen with a huge radio backpack, tall antenna, headphones and a signal detector",
		Description = "Built a radio rig taller than himself to chase a signal that repeats every 47 minutes. It is getting closer.",
		ModelReference = "Procedural:SignalHunter", AuraReference = nil, AnimationSet = "Walkie", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 1, Skin = rgb(240, 200, 165), Hair = rgb(40, 30, 20), HairStyle = "Messy", Top = rgb(60, 70, 90), Bottom = rgb(50, 50, 60), Shoes = rgb(200, 200, 200), Accent = rgb(200, 120, 40), Glow = rgb(90, 255, 140), Face = "Determined", Accessories = { "RadioPack", "Headphones", "Detector" } },
	},
	{
		Id = "NightWatcher", DisplayName = "Night Watcher", Rarity = "Uncommon", RollChance = 60,
		BaseMoneyPerSecond = 4, BasePower = 5, BaseFishingPower = 3, MaxLevel = 15, Category = "Human",
		VisualTheme = "olive tactical vest, night-vision goggles, flashlight and monster tracker",
		Description = "Sits on the water tower every night with night-vision goggles and a homemade monster tracker. Has a list. The list is long.",
		ModelReference = "Procedural:NightWatcher", AuraReference = nil, AnimationSet = "Flashlight", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1, Skin = rgb(128, 82, 52), Hair = rgb(20, 20, 20), HairStyle = "Buzz", Top = rgb(40, 50, 40), Bottom = rgb(50, 50, 45), Shoes = rgb(30, 30, 30), Accent = rgb(80, 90, 60), Glow = rgb(120, 255, 120), Face = "Determined", Accessories = { "Flashlight", "NightVision", "Vest", "Detector" } },
	},
	{
		Id = "ForestTracker", DisplayName = "Forest Tracker", Rarity = "Uncommon", RollChance = 60,
		BaseMoneyPerSecond = 4, BasePower = 5, BaseFishingPower = 4, MaxLevel = 15, Category = "Human",
		VisualTheme = "red-haired teen in a green field jacket with walkie and creature detector",
		Description = "Reads footprints like other kids read comics. Some of the tracks in the Black Pines start in the middle of nowhere.",
		ModelReference = "Procedural:ForestTracker", AuraReference = nil, AnimationSet = "LookAround", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 1, Skin = rgb(234, 192, 150), Hair = rgb(180, 90, 40), HairStyle = "Ponytail", Top = rgb(200, 180, 140), Bottom = rgb(70, 80, 60), Shoes = rgb(100, 70, 40), Accent = rgb(60, 100, 60), Glow = rgb(255, 140, 60), Face = "Determined", Accessories = { "Jacket", "WalkieTalkie", "Detector" } },
	},
	{
		Id = "GymCoach", DisplayName = "Gym Coach", Rarity = "Uncommon", RollChance = 65,
		BaseMoneyPerSecond = 5, BasePower = 6, BaseFishingPower = 3, MaxLevel = 15, Category = "Human",
		VisualTheme = "broad coach in a red tracksuit, white headband, whistle and clipboard",
		Description = "Makes the whole class run laps around the football field at dusk. Nobody runs alone. Nobody asks why.",
		ModelReference = "Procedural:GymCoach", AuraReference = nil, AnimationSet = "Talk", Thumbnail = false, Source = "Original",
		Visual = { Body = "Bulky", Scale = 1, Skin = rgb(198, 140, 98), Hair = rgb(40, 30, 20), HairStyle = "Buzz", Top = rgb(200, 40, 40), Bottom = rgb(180, 35, 35), Shoes = rgb(240, 240, 240), Accent = rgb(240, 240, 240), Face = "Determined", Accessories = { "Headband", "Whistle", "Clipboard" } },
	},
	{
		Id = "DinerWaitress", DisplayName = "Diner Waitress", Rarity = "Uncommon", RollChance = 70,
		BaseMoneyPerSecond = 5, BasePower = 5, BaseFishingPower = 4, MaxLevel = 15, Category = "Human",
		VisualTheme = "mint diner uniform, white apron, blonde bun, coffee pot in hand",
		Description = "Pours coffee at the all-night Moonlite Diner. Hears every rumor in Milbrook first, and keeps a few of them.",
		ModelReference = "Procedural:DinerWaitress", AuraReference = nil, AnimationSet = "Talk", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 0.95, Skin = rgb(255, 226, 200), Hair = rgb(230, 180, 80), HairStyle = "Bun", Top = rgb(120, 200, 190), Bottom = rgb(110, 185, 175), Shoes = rgb(245, 245, 245), Accent = rgb(250, 250, 250), Face = "Smile", Accessories = { "Apron", "CoffeePot" } },
	},
	{
		Id = "VideoStoreClerk", DisplayName = "Video Store Clerk", Rarity = "Uncommon", RollChance = 70,
		BaseMoneyPerSecond = 5, BasePower = 5, BaseFishingPower = 3, MaxLevel = 15, Category = "Human",
		VisualTheme = "spiky hair, blue polo, yellow store vest, glasses and a VHS tape",
		Description = "Works the late shift at Rewind Video. One tape on the horror shelf keeps rewinding itself.",
		ModelReference = "Procedural:VideoStoreClerk", AuraReference = nil, AnimationSet = "Investigate", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 1, Skin = rgb(176, 122, 84), Hair = rgb(30, 25, 20), HairStyle = "Spiky", Top = rgb(40, 60, 150), Bottom = rgb(40, 40, 40), Shoes = rgb(40, 40, 40), Accent = rgb(250, 200, 40), Face = "Calm", Accessories = { "Vest", "Cassette", "Glasses" } },
	},
	{
		Id = "StaticPup", DisplayName = "Static Pup", Rarity = "Uncommon", RollChance = 75,
		BaseMoneyPerSecond = 5, BasePower = 6, BaseFishingPower = 3, MaxLevel = 15, Category = "Creature",
		VisualTheme = "blue-grey puppy with a crackling white static mane and spiky back",
		Description = "A puppy-shaped knot of static. Its fur crackles when the Rift is near. Still wants belly rubs.",
		ModelReference = "Procedural:StaticPup", AuraReference = nil, AnimationSet = "Creature", Thumbnail = false, Source = "Original",
		Visual = { Body = "Quadruped", Scale = 0.72, Skin = rgb(60, 70, 90), Top = rgb(200, 210, 230), Shoes = rgb(20, 20, 30), Accent = rgb(40, 40, 55), Glow = rgb(130, 220, 255), Face = "GlowEyes", Accessories = { "Spikes" } },
	},
	{
		Id = "MallSecurityGuard", DisplayName = "Mall Security Guard", Rarity = "Uncommon", RollChance = 80,
		BaseMoneyPerSecond = 5, BasePower = 6, BaseFishingPower = 4, MaxLevel = 15, Category = "Human",
		VisualTheme = "broad guard in light-blue uniform, navy cap, gold badge, flashlight and walkie",
		Description = "Night guard at the Milbrook Galleria. The escalators run by themselves at 3 a.m. He has stopped writing it down.",
		ModelReference = "Procedural:MallSecurityGuard", AuraReference = nil, AnimationSet = "Flashlight", Thumbnail = false, Source = "Original",
		Visual = { Body = "Bulky", Scale = 1, Skin = rgb(240, 200, 165), Hair = rgb(90, 60, 40), HairStyle = "Short", Top = rgb(110, 130, 170), Bottom = rgb(40, 45, 70), Shoes = rgb(20, 20, 20), Accent = rgb(40, 45, 70), Face = "Calm", Accessories = { "Cap", "Badge", "Flashlight", "WalkieTalkie" } },
	},
	{
		Id = "SwampLeech", DisplayName = "Swamp Leech", Rarity = "Uncommon", RollChance = 85,
		BaseMoneyPerSecond = 6, BasePower = 6, BaseFishingPower = 5, MaxLevel = 15, Category = "Creature",
		VisualTheme = "coiled brown-black leech-serpent with a red belly and a ring of teeth",
		Description = "Rises out of the Milbrook marsh when the moon is low. Drinks electricity from fence wires instead of blood.",
		ModelReference = "Procedural:SwampLeech", AuraReference = nil, AnimationSet = "Serpent", Thumbnail = false, Source = "Original",
		Visual = { Body = "Serpent", Scale = 0.7, Skin = rgb(70, 60, 50), Top = rgb(90, 80, 45), Accent = rgb(170, 60, 60), Glow = rgb(255, 90, 90), Face = "GlowEyes", Accessories = { "Teeth" } },
	},
	{
		Id = "Mechanic", DisplayName = "Mechanic", Rarity = "Uncommon", RollChance = 90,
		BaseMoneyPerSecond = 6, BasePower = 7, BaseFishingPower = 4, MaxLevel = 15, Category = "Human",
		VisualTheme = "blue coveralls, red bandana, tool belt and a giant wrench",
		Description = "Fixes anything with an engine. The tow truck she rebuilt still starts on its own when the Rift opens.",
		ModelReference = "Procedural:Mechanic", AuraReference = nil, AnimationSet = "Heavy", Thumbnail = false, Source = "Original",
		Visual = { Body = "Bulky", Scale = 0.98, Skin = rgb(141, 85, 54), Hair = rgb(20, 15, 10), HairStyle = "Short", Top = rgb(60, 90, 140), Bottom = rgb(55, 85, 130), Shoes = rgb(40, 30, 20), Accent = rgb(220, 60, 40), Face = "Grin", Accessories = { "Bandana", "Wrench", "Toolbelt" } },
	},
	{
		Id = "SmallTownReporter", DisplayName = "Small-Town Reporter", Rarity = "Uncommon", RollChance = 95,
		BaseMoneyPerSecond = 6, BasePower = 6, BaseFishingPower = 4, MaxLevel = 15, Category = "Human",
		VisualTheme = "curly-haired reporter in a tan blazer with press camera and notebook",
		Description = "The Milbrook Herald's only reporter. Her best story was pulled from print the night before it ran.",
		ModelReference = "Procedural:SmallTownReporter", AuraReference = nil, AnimationSet = "Investigate", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1, Skin = rgb(234, 192, 150), Hair = rgb(70, 40, 25), HairStyle = "Curly", Top = rgb(230, 225, 210), Bottom = rgb(120, 90, 70), Shoes = rgb(110, 40, 40), Accent = rgb(150, 110, 80), Face = "Worried", Accessories = { "Jacket", "Camera", "Notebook" } },
	},
	{
		Id = "GlowbugSwarm", DisplayName = "Glowbug Swarm", Rarity = "Uncommon", RollChance = 100,
		BaseMoneyPerSecond = 6, BasePower = 7, BaseFishingPower = 4, MaxLevel = 15, Category = "Creature",
		VisualTheme = "mossy bug nest with a glowing heart and fireflies circling around it",
		Description = "Thousands of glowbugs that move like one body. On summer nights they spell words over the Black Pines.",
		ModelReference = "Procedural:GlowbugSwarm", AuraReference = nil, AnimationSet = "Pulse", Thumbnail = false, Source = "Original",
		Visual = { Body = "Hive", Scale = 0.62, Skin = rgb(60, 70, 40), Top = rgb(80, 90, 50), Accent = rgb(110, 120, 60), Glow = rgb(230, 255, 90), Face = "ManyEyes", Accessories = {} },
	},
	{
		Id = "ComicShopOwner", DisplayName = "Comic Shop Owner", Rarity = "Uncommon", RollChance = 110,
		BaseMoneyPerSecond = 7, BasePower = 7, BaseFishingPower = 4, MaxLevel = 15, Category = "Human",
		VisualTheme = "big bearded guy with long hair, glasses, purple vest and a sketchbook",
		Description = "Runs Panel Nine Comics. Claims half the monsters in his back issues were drawn from life.",
		ModelReference = "Procedural:ComicShopOwner", AuraReference = nil, AnimationSet = "Talk", Thumbnail = false, Source = "Original",
		Visual = { Body = "Bulky", Scale = 1.02, Skin = rgb(255, 224, 189), Hair = rgb(60, 40, 30), HairStyle = "Long", Top = rgb(40, 40, 40), Bottom = rgb(70, 80, 110), Shoes = rgb(200, 200, 200), Accent = rgb(130, 50, 150), Face = "Smile", Accessories = { "Glasses", "Beard", "Vest", "Notebook" } },
	},
	{
		Id = "AtticCrawler", DisplayName = "Attic Crawler", Rarity = "Uncommon", RollChance = 115,
		BaseMoneyPerSecond = 7, BasePower = 8, BaseFishingPower = 4, MaxLevel = 15, Category = "Creature",
		VisualTheme = "dusty purple-grey six-legged crawler with spiked back and red eyes",
		Description = "The thing behind the boxes in every attic. It sorts your old toys by how scared you were of them.",
		ModelReference = "Procedural:AtticCrawler", AuraReference = nil, AnimationSet = "Crawler", Thumbnail = false, Source = "Original",
		Visual = { Body = "Crawler", Scale = 0.7, Skin = rgb(90, 80, 90), Top = rgb(60, 50, 65), Shoes = rgb(30, 25, 30), Accent = rgb(200, 190, 170), Glow = rgb(255, 60, 90), Face = "ManyEyes", Accessories = { "Mandibles", "Spikes" } },
	},
	{
		Id = "BogLurker", DisplayName = "Bog Lurker", Rarity = "Uncommon", RollChance = 120,
		BaseMoneyPerSecond = 7, BasePower = 8, BaseFishingPower = 5, MaxLevel = 15, Category = "Creature",
		VisualTheme = "moss-covered swamp blob with hollow eyes and dangling tentacles",
		Description = "Looks like a mossy rock until it blinks. Pulls fishing lures under just to see who follows them.",
		ModelReference = "Procedural:BogLurker", AuraReference = nil, AnimationSet = "Pulse", Thumbnail = false, Source = "Original",
		Visual = { Body = "Blob", Scale = 0.8, Skin = rgb(70, 90, 60), Top = rgb(50, 70, 45), Bottom = rgb(40, 60, 40), Accent = rgb(140, 170, 80), Glow = rgb(200, 255, 120), Face = "Hollow", Accessories = { "Tentacles" } },
	},
}

return characters
