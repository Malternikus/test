--!strict
-- Characters > Common
-- RollChance ist auch bei Commons "1 in X" (8..40), wird aber normalisiert: Commons füllen die
-- Restwahrscheinlichkeit auf. Größeres X = seltener = etwas mehr $/s (wie bei allen Rarities).
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "MysteryKid", DisplayName = "Mystery Kid", Rarity = "Common", RollChance = 8,
		BaseMoneyPerSecond = 1, BasePower = 1, BaseFishingPower = 1, MaxLevel = 15, Category = "Human",
		VisualTheme = "80s kid, orange tee, red backpack, flashlight and walkie-talkie",
		Description = "Rides out after curfew with a flashlight and a walkie-talkie tuned to channel 9. Swears something in the Black Pines blinked back.",
		ModelReference = "Procedural:MysteryKid", AuraReference = nil, AnimationSet = "Flashlight", Thumbnail = true, Source = "Original",
		Visual = { Body = "Kid", Scale = 0.9, Skin = rgb(240, 200, 165), Hair = rgb(90, 55, 30), HairStyle = "Messy", Top = rgb(230, 120, 40), Bottom = rgb(60, 80, 140), Shoes = rgb(235, 235, 235), Accent = rgb(200, 50, 50), Glow = rgb(255, 240, 180), Face = "Determined", Accessories = { "Flashlight", "WalkieTalkie", "Backpack" } },
	},
	{
		Id = "PierKid", DisplayName = "Pier Kid", Rarity = "Common", RollChance = 12,
		BaseMoneyPerSecond = 1, BasePower = 1, BaseFishingPower = 3, MaxLevel = 15, Category = "Human",
		VisualTheme = "small kid in a tank top and green bucket hat with a fishing rod",
		Description = "Fishing specialist. Spends every summer on the Milbrook pier and knows which ripples are not fish. Earns little, catches a lot.",
		ModelReference = "Procedural:PierKid", AuraReference = nil, AnimationSet = "Sit", Thumbnail = false, Source = "Original",
		Visual = { Body = "Kid", Scale = 0.85, Skin = rgb(176, 122, 84), Hair = rgb(30, 22, 18), HairStyle = "Buzz", Top = rgb(90, 170, 210), Bottom = rgb(230, 200, 120), Shoes = rgb(200, 60, 60), Accent = rgb(60, 120, 80), Face = "Smile", Accessories = { "FishingRod", "BucketHat" } },
	},
	{
		Id = "ArcadeKid", DisplayName = "Arcade Kid", Rarity = "Common", RollChance = 14,
		BaseMoneyPerSecond = 1, BasePower = 1, BaseFishingPower = 1, MaxLevel = 15, Category = "Human",
		VisualTheme = "neon-teal arcade tee, backwards pink cap, pink vest, walkie-talkie",
		Description = "Holds the high score on every cabinet at the Milbrook arcade. Lately there is static between the bleeps, and it sounds like words.",
		ModelReference = "Procedural:ArcadeKid", AuraReference = nil, AnimationSet = "Walkie", Thumbnail = false, Source = "Original",
		Visual = { Body = "Kid", Scale = 0.9, Skin = rgb(255, 224, 189), Hair = rgb(200, 140, 60), HairStyle = "Short", Top = rgb(40, 200, 220), Bottom = rgb(40, 40, 60), Shoes = rgb(255, 80, 160), Accent = rgb(255, 80, 160), Face = "Grin", Accessories = { "CapBackward", "Vest", "WalkieTalkie" } },
	},
	{
		Id = "BikeScout", DisplayName = "Bike Scout", Rarity = "Common", RollChance = 16,
		BaseMoneyPerSecond = 1, BasePower = 1, BaseFishingPower = 1, MaxLevel = 15, Category = "Human",
		VisualTheme = "scout shirt, yellow bike helmet, mystery notebook and backpack",
		Description = "Maps every strange light in Milbrook from the seat of a BMX. The notebook is full; the map has a hole in the middle.",
		ModelReference = "Procedural:BikeScout", AuraReference = nil, AnimationSet = "LookAround", Thumbnail = false, Source = "Original",
		Visual = { Body = "Kid", Scale = 0.92, Skin = rgb(214, 164, 120), Hair = rgb(60, 40, 25), HairStyle = "Curly", Top = rgb(70, 140, 70), Bottom = rgb(110, 90, 60), Shoes = rgb(90, 60, 40), Accent = rgb(240, 200, 40), Face = "Determined", Accessories = { "BikeHelmet", "Backpack", "Notebook" } },
	},
	{
		Id = "LabAssistant", DisplayName = "Lab Assistant", Rarity = "Common", RollChance = 18,
		BaseMoneyPerSecond = 1, BasePower = 1, BaseFishingPower = 1, MaxLevel = 15, Category = "Human",
		VisualTheme = "young scientist in a white lab coat with glasses and clipboard",
		Description = "Summer intern at the Milbrook research site. Was told to stop asking about Level B4. Keeps asking.",
		ModelReference = "Procedural:LabAssistant", AuraReference = nil, AnimationSet = "Investigate", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 0.95, Skin = rgb(255, 226, 200), Hair = rgb(40, 30, 25), HairStyle = "Ponytail", Top = rgb(120, 170, 220), Bottom = rgb(60, 60, 70), Shoes = rgb(40, 40, 40), Accent = rgb(230, 230, 230), Face = "Worried", Accessories = { "LabCoat", "Glasses", "Clipboard" } },
	},
	{
		Id = "Paperboy", DisplayName = "Paperboy", Rarity = "Common", RollChance = 20,
		BaseMoneyPerSecond = 2, BasePower = 1, BaseFishingPower = 1, MaxLevel = 15, Category = "Human",
		VisualTheme = "red tee, canvas cap and a shoulder bag stuffed with newspapers",
		Description = "Delivers the Milbrook Herald before sunrise. Lately some houses on his route are on the wrong side of the street.",
		ModelReference = "Procedural:Paperboy", AuraReference = nil, AnimationSet = "Default", Thumbnail = false, Source = "Original",
		Visual = { Body = "Kid", Scale = 0.88, Skin = rgb(128, 82, 52), Hair = rgb(25, 20, 18), HairStyle = "Short", Top = rgb(220, 60, 60), Bottom = rgb(60, 70, 110), Shoes = rgb(240, 240, 240), Accent = rgb(225, 205, 160), Face = "Smile", Accessories = { "Cap", "PaperBag" } },
	},
	{
		Id = "AVClubNerd", DisplayName = "AV Club Nerd", Rarity = "Common", RollChance = 22,
		BaseMoneyPerSecond = 2, BasePower = 2, BaseFishingPower = 1, MaxLevel = 15, Category = "Human",
		VisualTheme = "bowl cut, brown sweater, glasses, camera on a strap and a VHS tape",
		Description = "Runs the school's only camcorder. Every tape he records at night has three extra seconds he never filmed.",
		ModelReference = "Procedural:AVClubNerd", AuraReference = nil, AnimationSet = "Investigate", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 0.92, Skin = rgb(240, 200, 165), Hair = rgb(150, 90, 40), HairStyle = "Bowl", Top = rgb(170, 120, 60), Bottom = rgb(90, 80, 70), Shoes = rgb(60, 40, 30), Accent = rgb(70, 70, 80), Face = "Smile", Accessories = { "Glasses", "Camera", "Cassette" } },
	},
	{
		Id = "Babysitter", DisplayName = "Babysitter", Rarity = "Common", RollChance = 24,
		BaseMoneyPerSecond = 2, BasePower = 2, BaseFishingPower = 1, MaxLevel = 15, Category = "Human",
		VisualTheme = "pink sweater, long hair, headband and a curly-cord phone handset",
		Description = "Keeps the kids inside after dark and the phone line open. The calls after midnight never have a caller.",
		ModelReference = "Procedural:Babysitter", AuraReference = nil, AnimationSet = "Talk", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 1, Skin = rgb(198, 140, 98), Hair = rgb(60, 30, 20), HairStyle = "Long", Top = rgb(240, 160, 190), Bottom = rgb(70, 90, 150), Shoes = rgb(240, 240, 240), Accent = rgb(230, 60, 90), Face = "Worried", Accessories = { "PhoneHandset", "Headband" } },
	},
	{
		Id = "CampCounselor", DisplayName = "Camp Counselor", Rarity = "Common", RollChance = 26,
		BaseMoneyPerSecond = 2, BasePower = 2, BaseFishingPower = 2, MaxLevel = 15, Category = "Human",
		VisualTheme = "green camp tee, orange cap, whistle and a camping lantern",
		Description = "Counts heads at Camp Pinewood every night. The number is always one too high.",
		ModelReference = "Procedural:CampCounselor", AuraReference = nil, AnimationSet = "LookAround", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 1, Skin = rgb(234, 192, 150), Hair = rgb(210, 170, 90), HairStyle = "Short", Top = rgb(60, 130, 70), Bottom = rgb(200, 180, 130), Shoes = rgb(120, 80, 50), Accent = rgb(240, 140, 40), Glow = rgb(255, 200, 100), Face = "Smile", Accessories = { "Cap", "Whistle", "Lantern" } },
	},
	{
		Id = "PorchCritter", DisplayName = "Porch Critter", Rarity = "Common", RollChance = 28,
		BaseMoneyPerSecond = 2, BasePower = 2, BaseFishingPower = 1, MaxLevel = 15, Category = "Creature",
		VisualTheme = "small grey four-legged critter with a pale snout and lantern eyes",
		Description = "Lives under every porch in Milbrook at once. Steals batteries, never food.",
		ModelReference = "Procedural:PorchCritter", AuraReference = nil, AnimationSet = "Creature", Thumbnail = false, Source = "Original",
		Visual = { Body = "Quadruped", Scale = 0.6, Skin = rgb(110, 105, 100), Top = rgb(70, 65, 60), Shoes = rgb(40, 35, 30), Accent = rgb(200, 195, 185), Glow = rgb(255, 220, 90), Face = "GlowEyes", Accessories = {} },
	},
	{
		Id = "CrossingGuard", DisplayName = "Crossing Guard", Rarity = "Common", RollChance = 30,
		BaseMoneyPerSecond = 2, BasePower = 2, BaseFishingPower = 2, MaxLevel = 15, Category = "Human",
		VisualTheme = "older lady in safety orange, yellow vest, whistle and stop sign",
		Description = "Has guarded the corner of Elm and Fifth for forty years. Some of the kids she waves across never reach the other side.",
		ModelReference = "Procedural:CrossingGuard", AuraReference = nil, AnimationSet = "Default", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 0.95, Skin = rgb(176, 122, 84), Hair = rgb(200, 200, 200), HairStyle = "Bun", Top = rgb(250, 140, 30), Bottom = rgb(60, 60, 80), Shoes = rgb(40, 40, 40), Accent = rgb(230, 230, 60), Face = "Calm", Accessories = { "Vest", "StopSign", "Whistle" } },
	},
	{
		Id = "PorchlightMoth", DisplayName = "Porchlight Moth", Rarity = "Common", RollChance = 32,
		BaseMoneyPerSecond = 3, BasePower = 2, BaseFishingPower = 1, MaxLevel = 15, Category = "Creature",
		VisualTheme = "cream-colored moth the size of a cat with glowing wing spots",
		Description = "Drawn to porch lights, TV screens and anything that hums. Leaves glittering dust shaped like fingerprints.",
		ModelReference = "Procedural:PorchlightMoth", AuraReference = nil, AnimationSet = "Hover", Thumbnail = false, Source = "Original",
		Visual = { Body = "Winged", Scale = 0.6, Skin = rgb(200, 190, 160), Top = rgb(220, 210, 170), Shoes = rgb(90, 80, 60), Accent = rgb(160, 140, 110), Glow = rgb(255, 240, 150), Face = "GlowEyes", Accessories = { "Antennae" } },
	},
	{
		Id = "RollerRinkTeen", DisplayName = "Roller Rink Teen", Rarity = "Common", RollChance = 34,
		BaseMoneyPerSecond = 3, BasePower = 2, BaseFishingPower = 1, MaxLevel = 15, Category = "Human",
		VisualTheme = "afro, neon-pink top, teal pants, glowing roller skates and a boombox",
		Description = "Queen of the Saturday night skate at Galaxy Rollerway. Her boombox picks up a station that does not exist.",
		ModelReference = "Procedural:RollerRinkTeen", AuraReference = nil, AnimationSet = "Default", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 1, Skin = rgb(141, 85, 54), Hair = rgb(30, 20, 15), HairStyle = "Afro", Top = rgb(255, 90, 170), Bottom = rgb(60, 220, 220), Shoes = rgb(245, 245, 245), Accent = rgb(255, 230, 60), Face = "Grin", Accessories = { "Rollerskates", "Boombox" } },
	},
	{
		Id = "DitchCroaker", DisplayName = "Ditch Croaker", Rarity = "Common", RollChance = 36,
		BaseMoneyPerSecond = 3, BasePower = 3, BaseFishingPower = 2, MaxLevel = 15, Category = "Creature",
		VisualTheme = "round green frog-blob with eyes on stalks sitting in a puddle",
		Description = "Croaks in perfect Morse code. Nobody in Milbrook has bothered to decode it yet.",
		ModelReference = "Procedural:DitchCroaker", AuraReference = nil, AnimationSet = "Pulse", Thumbnail = false, Source = "Original",
		Visual = { Body = "Blob", Scale = 0.65, Skin = rgb(90, 140, 70), Top = rgb(70, 110, 55), Bottom = rgb(60, 90, 60), Accent = rgb(200, 220, 120), Glow = rgb(255, 200, 60), Face = "Grin", Accessories = { "Eyestalks" } },
	},
	{
		Id = "SkaterKid", DisplayName = "Skater Kid", Rarity = "Common", RollChance = 40,
		BaseMoneyPerSecond = 3, BasePower = 3, BaseFishingPower = 1, MaxLevel = 15, Category = "Human",
		VisualTheme = "mullet, black band tee, green bandana and a skateboard under the arm",
		Description = "Found a drained pool behind the old motel. The graffiti at the bottom rearranges itself.",
		ModelReference = "Procedural:SkaterKid", AuraReference = nil, AnimationSet = "LookAround", Thumbnail = false, Source = "Original",
		Visual = { Body = "Kid", Scale = 0.94, Skin = rgb(255, 224, 189), Hair = rgb(230, 190, 90), HairStyle = "Mullet", Top = rgb(40, 40, 40), Bottom = rgb(80, 100, 140), Shoes = rgb(220, 40, 40), Accent = rgb(60, 200, 120), Face = "Grin", Accessories = { "Skateboard", "Bandana" } },
	},
	{
		Id = "PineBeetle", DisplayName = "Pine Beetle", Rarity = "Common", RollChance = 40,
		BaseMoneyPerSecond = 3, BasePower = 3, BaseFishingPower = 1, MaxLevel = 15, Category = "Creature",
		VisualTheme = "glossy dark-green six-legged beetle with mandibles and many tiny eyes",
		Description = "Chews tunnels through Black Pines bark in shapes that look a lot like maps.",
		ModelReference = "Procedural:PineBeetle", AuraReference = nil, AnimationSet = "Crawler", Thumbnail = false, Source = "Original",
		Visual = { Body = "Crawler", Scale = 0.6, Skin = rgb(40, 60, 45), Top = rgb(30, 90, 60), Shoes = rgb(20, 30, 20), Accent = rgb(160, 220, 90), Glow = rgb(180, 255, 120), Face = "ManyEyes", Accessories = { "Mandibles" } },
	},
}

return characters
