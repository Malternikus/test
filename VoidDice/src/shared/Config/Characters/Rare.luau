--!strict
-- Characters > Rare
-- Ziel-Summe der Chancen: 1/20. Einzelchancen 1 in 200..450.
-- Felder: siehe CharacterConfig. Visual-Vokabular: siehe Visual > ModelFactory.

local rgb = Color3.fromRGB

local characters: { any } = {
	{
		Id = "LighthouseKeeper", DisplayName = "Lighthouse Keeper", Rarity = "Rare", RollChance = 200,
		BaseMoneyPerSecond = 14, BasePower = 10, BaseFishingPower = 10, MaxLevel = 15, Category = "Human",
		VisualTheme = "broad old sailor, navy sweater, white beard, yellow rain hat, lantern and rod",
		Description = "Fishing specialist. Keeps the light on at Milbrook Lake although no ship has come in fifty years. Something out there still needs it.",
		ModelReference = "Procedural:LighthouseKeeper", AuraReference = "LakeMist", AnimationSet = "Sit", Thumbnail = false, Source = "Original",
		Visual = { Body = "Bulky", Scale = 1, Skin = rgb(240, 200, 165), Hair = rgb(225, 225, 225), HairStyle = "Short", Top = rgb(30, 50, 90), Bottom = rgb(60, 60, 70), Shoes = rgb(30, 30, 30), Accent = rgb(240, 200, 60), Glow = rgb(255, 220, 140), Face = "Calm", Accessories = { "Beard", "FishingRod", "Lantern", "BucketHat" } },
	},
	{
		Id = "MonsterHunter", DisplayName = "Monster Hunter", Rarity = "Rare", RollChance = 220,
		BaseMoneyPerSecond = 15, BasePower = 11, BaseFishingPower = 6, MaxLevel = 15, Category = "Human",
		VisualTheme = "army-surplus teen, red bandana, backpack and a homemade glowing Signal Bat",
		Description = "Built the Signal Bat in his garage: aluminum, a copper coil and a car battery's worth of static. Creatures hate the hum.",
		ModelReference = "Procedural:MonsterHunter", AuraReference = "Static", AnimationSet = "Default", Thumbnail = true, Source = "Original",
		Visual = { Body = "Teen", Scale = 1.02, Skin = rgb(234, 192, 150), Hair = rgb(60, 40, 25), HairStyle = "Messy", Top = rgb(70, 80, 60), Bottom = rgb(50, 50, 60), Shoes = rgb(40, 30, 25), Accent = rgb(170, 40, 40), Glow = rgb(90, 220, 255), Face = "Determined", Accessories = { "SignalBat", "Bandana", "Backpack" } },
	},
	{
		Id = "PsychicSubject", DisplayName = "Psychic Subject", Rarity = "Rare", RollChance = 240,
		BaseMoneyPerSecond = 15, BasePower = 12, BaseFishingPower = 6, MaxLevel = 15, Category = "Human",
		VisualTheme = "long-haired teen in pale-blue lab scrubs with a monitor band and soft blue aura",
		Description = "Signed up for a paid 'sleep study' at the Milbrook research site and woke up able to nudge things with a thought. Light objects drift when they get nervous.",
		ModelReference = "Procedural:PsychicSubject", AuraReference = "PsychicBlue", AnimationSet = "Psychic", Thumbnail = true, Source = "Original",
		Visual = { Body = "Teen", Scale = 0.95, Skin = rgb(255, 226, 200), Hair = rgb(60, 40, 30), HairStyle = "Long", Top = rgb(170, 200, 220), Bottom = rgb(160, 190, 210), Shoes = rgb(240, 240, 240), Accent = rgb(120, 140, 170), Glow = rgb(120, 200, 255), Face = "Calm", Accessories = { "Headband" } },
	},
	{
		Id = "VoidDetective", DisplayName = "Void Detective", Rarity = "Rare", RollChance = 250,
		BaseMoneyPerSecond = 16, BasePower = 12, BaseFishingPower = 7, MaxLevel = 15, Category = "Human",
		VisualTheme = "investigator in a violet-grey trench coat and fedora with magnifier and case notes",
		Description = "Private eye who only takes cases the sheriff won't touch. Every clue she follows leads one step closer to the Rift.",
		ModelReference = "Procedural:VoidDetective", AuraReference = "RiftViolet", AnimationSet = "Investigate", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1.04, Skin = rgb(198, 140, 98), Hair = rgb(30, 25, 20), HairStyle = "Short", Top = rgb(220, 220, 210), Bottom = rgb(60, 55, 70), Shoes = rgb(40, 30, 30), Accent = rgb(90, 70, 110), Glow = rgb(170, 110, 255), Face = "Determined", Accessories = { "Trenchcoat", "DetectiveHat", "Magnifier", "Notebook" } },
	},
	{
		Id = "HamRadioGrandma", DisplayName = "Ham-Radio Grandma", Rarity = "Rare", RollChance = 260,
		BaseMoneyPerSecond = 16, BasePower = 12, BaseFishingPower = 7, MaxLevel = 15, Category = "Human",
		VisualTheme = "small grandma with silver bun, rose cardigan, glasses, radio pack and microphone",
		Description = "Has talked to every ham operator from here to Alaska, and lately to one who answers from the Otherworld.",
		ModelReference = "Procedural:HamRadioGrandma", AuraReference = "Static", AnimationSet = "Walkie", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 0.85, Skin = rgb(234, 192, 150), Hair = rgb(230, 230, 235), HairStyle = "Bun", Top = rgb(170, 90, 120), Bottom = rgb(100, 80, 90), Shoes = rgb(90, 60, 50), Accent = rgb(140, 170, 150), Glow = rgb(255, 180, 60), Face = "Smile", Accessories = { "RadioPack", "Glasses", "Jacket", "Microphone" } },
	},
	{
		Id = "PowerlineBat", DisplayName = "Powerline Bat", Rarity = "Rare", RollChance = 280,
		BaseMoneyPerSecond = 17, BasePower = 13, BaseFishingPower = 7, MaxLevel = 15, Category = "Creature",
		VisualTheme = "dark violet bat-thing with big ears, fangs and sparking wing spots",
		Description = "Roosts on high-voltage lines and makes the whole street flicker when it yawns.",
		ModelReference = "Procedural:PowerlineBat", AuraReference = "ElectricSparks", AnimationSet = "Hover", Thumbnail = false, Source = "Original",
		Visual = { Body = "Winged", Scale = 0.8, Skin = rgb(40, 35, 50), Top = rgb(60, 50, 80), Shoes = rgb(20, 20, 20), Accent = rgb(30, 25, 40), Glow = rgb(120, 220, 255), Face = "GlowEyes", Accessories = { "Ears", "Teeth" } },
	},
	{
		Id = "ParkRanger", DisplayName = "Park Ranger", Rarity = "Rare", RollChance = 300,
		BaseMoneyPerSecond = 18, BasePower = 14, BaseFishingPower = 8, MaxLevel = 15, Category = "Human",
		VisualTheme = "khaki ranger uniform, olive campaign hat, badge and glowing lantern",
		Description = "Patrols the Black Pines trails at night. Officially, she has never filed a strange report. Unofficially, there is a whole cabinet.",
		ModelReference = "Procedural:ParkRanger", AuraReference = "Fireflies", AnimationSet = "LookAround", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1.04, Skin = rgb(176, 122, 84), Hair = rgb(40, 30, 20), HairStyle = "Ponytail", Top = rgb(190, 170, 120), Bottom = rgb(80, 90, 60), Shoes = rgb(80, 60, 40), Accent = rgb(90, 110, 70), Glow = rgb(255, 210, 120), Face = "Determined", Accessories = { "RangerHat", "Badge", "Lantern" } },
	},
	{
		Id = "HazmatTech", DisplayName = "Hazmat Tech", Rarity = "Rare", RollChance = 300,
		BaseMoneyPerSecond = 18, BasePower = 14, BaseFishingPower = 7, MaxLevel = 15, Category = "Human",
		VisualTheme = "yellow hazmat suit with clear visor, gas mask and spore detector",
		Description = "Cleans up after the things that crawl out of the lab vents. The spores never come off the suit completely.",
		ModelReference = "Procedural:HazmatTech", AuraReference = "Spores", AnimationSet = "Investigate", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1, Skin = rgb(240, 200, 165), HairStyle = "None", Top = rgb(240, 200, 40), Bottom = rgb(240, 200, 40), Shoes = rgb(30, 30, 30), Accent = rgb(60, 60, 60), Glow = rgb(120, 255, 120), Face = "Worried", Accessories = { "HazmatSuit", "GasMask", "Detector" } },
	},
	{
		Id = "BasementInventor", DisplayName = "Basement Inventor", Rarity = "Rare", RollChance = 320,
		BaseMoneyPerSecond = 19, BasePower = 15, BaseFishingPower = 7, MaxLevel = 15, Category = "Human",
		VisualTheme = "teen genius with amber goggles, antenna headband, tool belt and wrench",
		Description = "Turned a toaster, two TVs and a garage door opener into a Rift detector. It works. Mostly.",
		ModelReference = "Procedural:BasementInventor", AuraReference = nil, AnimationSet = "Investigate", Thumbnail = false, Source = "Original",
		Visual = { Body = "Teen", Scale = 0.95, Skin = rgb(128, 82, 52), Hair = rgb(20, 15, 10), HairStyle = "Short", Top = rgb(200, 200, 190), Bottom = rgb(70, 60, 50), Shoes = rgb(150, 40, 40), Accent = rgb(210, 120, 40), Glow = rgb(90, 255, 200), Face = "Grin", Accessories = { "Goggles", "Antennae", "Toolbelt", "Wrench" } },
	},
	{
		Id = "TunnelWorm", DisplayName = "Tunnel Worm", Rarity = "Rare", RollChance = 340,
		BaseMoneyPerSecond = 20, BasePower = 15, BaseFishingPower = 8, MaxLevel = 15, Category = "Creature",
		VisualTheme = "eyeless pink segmented worm rearing up, teeth and bony back ridges",
		Description = "Burrows under Milbrook in perfect circles. The town's sinkholes line up with the old mine map.",
		ModelReference = "Procedural:TunnelWorm", AuraReference = nil, AnimationSet = "Serpent", Thumbnail = false, Source = "Original",
		Visual = { Body = "Serpent", Scale = 0.95, Skin = rgb(200, 140, 130), Top = rgb(170, 110, 100), Accent = rgb(240, 200, 180), Glow = rgb(255, 240, 200), Face = "Blank", Accessories = { "Teeth", "Spikes" } },
	},
	{
		Id = "ConspiracyDJ", DisplayName = "Conspiracy DJ", Rarity = "Rare", RollChance = 360,
		BaseMoneyPerSecond = 21, BasePower = 16, BaseFishingPower = 7, MaxLevel = 15, Category = "Human",
		VisualTheme = "afro, shades, loud orange shirt, microphone and boombox",
		Description = "Hosts 'Static After Midnight' on pirate radio. Half his callers are cranks. The other half call from numbers that do not exist.",
		ModelReference = "Procedural:ConspiracyDJ", AuraReference = nil, AnimationSet = "Talk", Thumbnail = false, Source = "Original",
		Visual = { Body = "Adult", Scale = 1, Skin = rgb(86, 56, 38), Hair = rgb(20, 15, 15), HairStyle = "Afro", Top = rgb(240, 100, 40), Bottom = rgb(60, 40, 30), Shoes = rgb(220, 200, 150), Accent = rgb(80, 200, 200), Glow = rgb(255, 60, 60), Face = "Grin", Accessories = { "Shades", "Microphone", "Boombox" } },
	},
	{
		Id = "GovernmentAgent", DisplayName = "Government Agent", Rarity = "Rare", RollChance = 380,
		BaseMoneyPerSecond = 21, BasePower = 16, BaseFishingPower = 7, MaxLevel = 15, Category = "Human",
		VisualTheme = "tall agent in a grey suit, dark-red tie, earpiece, sunglasses and ID badge",
		Description = "Arrived in Milbrook the day the power went out and never left. Writes everything down, explains nothing.",
		ModelReference = "Procedural:GovernmentAgent", AuraReference = nil, AnimationSet = "LookAround", Thumbnail = false, Source = "Original",
		Visual = { Body = "Tall", Scale = 1, Skin = rgb(240, 200, 165), Hair = rgb(30, 30, 30), HairStyle = "Short", Top = rgb(85, 90, 100), Bottom = rgb(70, 75, 85), Shoes = rgb(15, 15, 15), Accent = rgb(150, 30, 40), Face = "Calm", Accessories = { "Shades", "Earpiece", "Tie", "Badge" } },
	},
	{
		Id = "MailboxMimic", DisplayName = "Mailbox Mimic", Rarity = "Rare", RollChance = 400,
		BaseMoneyPerSecond = 22, BasePower = 17, BaseFishingPower = 8, MaxLevel = 15, Category = "Creature",
		VisualTheme = "mailbox-blue blob with a toothy grin and grabbing tentacles",
		Description = "Looks exactly like a blue mailbox until you reach for the handle. Has eaten 312 letters and one bicycle.",
		ModelReference = "Procedural:MailboxMimic", AuraReference = nil, AnimationSet = "Pulse", Thumbnail = false, Source = "Original",
		Visual = { Body = "Blob", Scale = 0.85, Skin = rgb(60, 90, 170), Top = rgb(50, 75, 140), Bottom = rgb(30, 40, 70), Accent = rgb(230, 230, 230), Glow = rgb(255, 80, 80), Face = "Grin", Accessories = { "Teeth", "Tentacles" } },
	},
	{
		Id = "StaticHound", DisplayName = "Static Hound", Rarity = "Rare", RollChance = 425,
		BaseMoneyPerSecond = 23, BasePower = 17, BaseFishingPower = 9, MaxLevel = 15, Category = "Creature",
		VisualTheme = "dark hound with a white static mane, spiked spine and electric-blue eyes",
		Description = "Grown-up Static Pup. Runs along power lines faster than the current and howls in dial tone.",
		ModelReference = "Procedural:StaticHound", AuraReference = "Static", AnimationSet = "Creature", Thumbnail = false, Source = "Original",
		Visual = { Body = "Quadruped", Scale = 1, Skin = rgb(40, 45, 60), Top = rgb(220, 230, 255), Shoes = rgb(15, 15, 20), Accent = rgb(25, 25, 35), Glow = rgb(110, 210, 255), Face = "GlowEyes", Accessories = { "Spikes" } },
	},
	{
		Id = "HiveDrone", DisplayName = "Hive Drone", Rarity = "Rare", RollChance = 450,
		BaseMoneyPerSecond = 24, BasePower = 18, BaseFishingPower = 9, MaxLevel = 15, Category = "Creature",
		VisualTheme = "amber wasp-crawler with dark stripes, translucent wings and mandibles",
		Description = "Worker of something much bigger under the Black Pines. Carries glowing pollen nobody can identify.",
		ModelReference = "Procedural:HiveDrone", AuraReference = nil, AnimationSet = "Crawler", Thumbnail = false, Source = "Original",
		Visual = { Body = "Crawler", Scale = 0.85, Skin = rgb(200, 160, 40), Top = rgb(50, 40, 20), Shoes = rgb(40, 30, 20), Accent = rgb(230, 200, 60), Glow = rgb(255, 170, 40), Face = "ManyEyes", Accessories = { "Wings", "Mandibles" } },
	},
}

return characters
