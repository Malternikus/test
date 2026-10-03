-- test_characters.luau (Lune)
--
-- Prüft die 100 Characters (Config > Characters) und baut jeden mit der
-- ModelFactory. Bricht mit error() ab (Exit-Code != 0), sobald etwas nicht stimmt.
--
-- Aufruf:  cd VoidDice/tests && lune run test_characters.luau

local Harness = require("./harness")

local h = Harness.load("/home/user/test/VoidDice")
local CharacterConfig = h.requirePath("ReplicatedStorage.VoidDice.Config.CharacterConfig")
local RarityConfig = h.requirePath("ReplicatedStorage.VoidDice.Config.RarityConfig")
local MutationConfig = h.requirePath("ReplicatedStorage.VoidDice.Config.MutationConfig")
local AuraLibrary = h.requirePath("ReplicatedStorage.VoidDice.Visual.AuraLibrary")
local ModelFactory = h.requirePath("ReplicatedStorage.VoidDice.Visual.ModelFactory")
local Bodies = ModelFactory.Bodies
local Accessories = ModelFactory.Accessories
local Faces = ModelFactory.Faces

local failures = {}
local function check(cond: any, msg: string)
	if not cond then
		table.insert(failures, msg)
	end
end

-------------------------------------------------------------------------------
-- Erwartungen
-------------------------------------------------------------------------------
local EXPECTED_COUNT = {
	Common = 16, Uncommon = 16, Rare = 15, Epic = 13, Legendary = 11,
	Mythic = 9, Supernatural = 7, Void = 6, Secret = 4, Anomaly = 3,
}
local TIER_SUM = {
	Uncommon = 1 / 5, Rare = 1 / 20, Epic = 1 / 100, Legendary = 1 / 500,
	Mythic = 1 / 2500, Supernatural = 1 / 10000, Void = 1 / 50000, Secret = 1 / 250000,
}
local CHANCE_RANGE = {
	Common = { 8, 40 }, Uncommon = { 50, 120 }, Rare = { 200, 450 }, Epic = { 900, 1900 },
	Legendary = { 4000, 8000 }, Mythic = { 16000, 32000 }, Supernatural = { 50000, 100000 },
	Void = { 220000, 400000 }, Secret = { 750000, 1300000 }, Anomaly = { 2500000, 10000000 },
}
local ANOMALY_EXACT = { TheEndless = 2500000, TheNullChild = 5000000, TheWatcherBeyond = 10000000 }
local POWER_RANGE = {
	Common = { 1, 3 }, Uncommon = { 4, 8 }, Rare = { 10, 18 }, Epic = { 25, 40 }, Legendary = { 60, 100 },
	Mythic = { 150, 250 }, Supernatural = { 400, 650 }, Void = { 1000, 1600 }, Secret = { 2500, 4000 }, Anomaly = { 7000, 12000 },
}
local FISH_RANGE = {
	Common = { 1, 3 }, Uncommon = { 3, 6 }, Rare = { 6, 10 }, Epic = { 10, 16 }, Legendary = { 16, 26 },
	Mythic = { 26, 40 }, Supernatural = { 40, 60 }, Void = { 60, 90 }, Secret = { 90, 130 }, Anomaly = { 130, 200 },
}
local CATEGORY_RANGE = { Human = { 55, 65 }, Creature = { 25, 30 }, Entity = { 10, 15 } }
local ANIMATION_SETS = {
	Default = true, Flashlight = true, Walkie = true, LookAround = true, Sit = true, Investigate = true,
	Talk = true, Psychic = true, Float = true, Creature = true, Crawler = true, Hover = true,
	Pulse = true, Serpent = true, Heavy = true,
}
-- Fremd-IP darf nirgends auftauchen (ganze Wörter bzw. Phrasen, klein geschrieben)
local BANNED_WORDS = {
	"eleven", "vecna", "dustin", "steve", "mike", "hopper", "joyce", "demogorgon", "hawkins", "byers",
	"eddie", "robin", "erica", "murray", "brenner", "eggo", "pennywise", "xenomorph", "freddy", "jason",
	"slenderman", "gremlin", "gremlins", "mogwai", "ghostbusters",
}
local BANNED_PHRASES = { "mind flayer", "upside down", "hellfire", "starcourt", "demodog", "lab 8", "scp-", "slender man", "five nights" }

local RARITY_ORDER = {}
for _, r in RarityConfig.List do
	table.insert(RARITY_ORDER, r.Id)
end

-------------------------------------------------------------------------------
-- 1) Daten
-------------------------------------------------------------------------------
local list = CharacterConfig.List
check(#list == 100, "Erwartet 100 Characters, gefunden " .. #list)

local ids, names = {}, {}
local perRarity: { [string]: { any } } = {}
local categories = { Human = 0, Creature = 0, Entity = 0 }
local thumbnails = 0
local accessoryUse: { [string]: number } = {}
local bodyUse: { [string]: number } = {}

for _, def in list do
	local id = def.Id
	check(type(id) == "string" and not id:find("%s"), "Ungültige Id: " .. tostring(id))
	check(not ids[id], "Doppelte Id: " .. tostring(id))
	ids[id] = true
	check(type(def.DisplayName) == "string" and def.DisplayName ~= "", id .. ": DisplayName fehlt")
	check(not names[def.DisplayName], "Doppelter DisplayName: " .. tostring(def.DisplayName))
	names[def.DisplayName] = true
	check(RarityConfig.ById[def.Rarity] ~= nil, id .. ": unbekannte Rarity " .. tostring(def.Rarity))
	perRarity[def.Rarity] = perRarity[def.Rarity] or {}
	table.insert(perRarity[def.Rarity], def)

	check(categories[def.Category] ~= nil, id .. ": unbekannte Category " .. tostring(def.Category))
	if categories[def.Category] then
		categories[def.Category] += 1
	end
	check(def.MaxLevel == 15, id .. ": MaxLevel muss 15 sein")
	check(def.ModelReference == "Procedural:" .. id, id .. ": ModelReference falsch")
	check(def.Source == "Original", id .. ": Source muss 'Original' sein")
	check(def.ReleaseEnabled == true, id .. ": ReleaseEnabled")
	check(type(def.VisualTheme) == "string" and #def.VisualTheme > 10, id .. ": VisualTheme fehlt")
	check(type(def.Description) == "string" and #def.Description > 20, id .. ": Description fehlt")
	check(ANIMATION_SETS[def.AnimationSet], id .. ": unbekanntes AnimationSet " .. tostring(def.AnimationSet))
	if def.Thumbnail then
		thumbnails += 1
	end

	-- Zahlen
	local range = RarityConfig.ById[def.Rarity] and RarityConfig.ById[def.Rarity].IncomeRange
	local money = def.BaseMoneyPerSecond
	check(type(money) == "number" and money == math.floor(money), id .. ": $/s muss ganzzahlig sein")
	if range then
		check(money >= range[1] and money <= range[2], string.format("%s: $/s %s außerhalb %d..%d", id, tostring(money), range[1], range[2]))
	end
	local pr = POWER_RANGE[def.Rarity]
	check(pr and def.BasePower >= pr[1] and def.BasePower <= pr[2], id .. ": BasePower außerhalb des Bereichs")
	local fr = FISH_RANGE[def.Rarity]
	check(fr and def.BaseFishingPower >= fr[1] and def.BaseFishingPower <= fr[2], id .. ": BaseFishingPower außerhalb des Bereichs")
	local cr = CHANCE_RANGE[def.Rarity]
	check(cr and def.RollChance >= cr[1] and def.RollChance <= cr[2], id .. ": RollChance außerhalb des Bereichs")
	if def.Rarity == "Anomaly" then
		check(ANOMALY_EXACT[id] == def.RollChance, id .. ": Anomaly-Chance falsch")
	end

	-- Visual
	local v = def.Visual
	check(type(v) == "table", id .. ": Visual fehlt")
	if type(v) == "table" then
		check(Bodies.Builders[v.Body] ~= nil, id .. ": unbekannter Body " .. tostring(v.Body))
		bodyUse[v.Body] = (bodyUse[v.Body] or 0) + 1
		check(v.Scale == nil or (v.Scale >= 0.6 and v.Scale <= 2.6), id .. ": Scale außerhalb 0.6..2.6")
		check(v.Face == nil or Faces.Has(v.Face), id .. ": unbekanntes Face " .. tostring(v.Face))
		check(v.HairStyle == nil or Accessories.HasHairStyle(v.HairStyle), id .. ": unbekannter HairStyle " .. tostring(v.HairStyle))
		for _, key in { "Skin", "Hair", "Top", "Bottom", "Shoes", "Accent", "Glow" } do
			check(v[key] == nil or typeof(v[key]) == "Color3", id .. ": Visual." .. key .. " ist keine Color3")
		end
		for _, acc in v.Accessories or {} do
			check(Accessories.Has(acc), id .. ": unbekanntes Accessory " .. tostring(acc))
			accessoryUse[acc] = (accessoryUse[acc] or 0) + 1
		end
	end
	if def.AuraReference ~= nil then
		check(AuraLibrary.Has(def.AuraReference), id .. ": unbekannte AuraReference " .. tostring(def.AuraReference))
	end

	-- Fremd-IP
	local text = (def.Id .. " " .. def.DisplayName .. " " .. def.VisualTheme .. " " .. def.Description):lower()
	for _, w in BANNED_WORDS do
		check(not text:find("%f[%a]" .. w .. "%f[%A]"), id .. ": verbotenes Wort '" .. w .. "'")
	end
	for _, p in BANNED_PHRASES do
		check(not text:find(p, 1, true), id .. ": verbotene Phrase '" .. p .. "'")
	end
end

-- Anzahl pro Rarity
for rarity, n in EXPECTED_COUNT do
	local got = perRarity[rarity] and #perRarity[rarity] or 0
	check(got == n, string.format("%s: erwartet %d, gefunden %d", rarity, n, got))
end

-- Kategorien
for cat, r in CATEGORY_RANGE do
	check(categories[cat] >= r[1] and categories[cat] <= r[2], string.format("Category %s: %d nicht in %d..%d", cat, categories[cat], r[1], r[2]))
end

-- Thumbnails
check(thumbnails >= 12, "Mindestens 12 Thumbnails erwartet, gefunden " .. thumbnails)

-- Tier-Summen
local tierSums = {}
for rarity, target in TIER_SUM do
	local sum = 0
	for _, def in perRarity[rarity] or {} do
		sum += 1 / def.RollChance
	end
	tierSums[rarity] = sum / target
	check(math.abs(sum / target - 1) <= 0.08, string.format("%s: Chance-Summe %.4f%% vom Ziel", rarity, (sum / target) * 100))
end

-- Zusammenhängende, nicht überlappende Bereiche (ohne Common = Gewichte)
local prevMax = 0
for _, rarity in RARITY_ORDER do
	if rarity ~= "Common" then
		local lo, hi = math.huge, 0
		for _, def in perRarity[rarity] or {} do
			lo = math.min(lo, def.RollChance)
			hi = math.max(hi, def.RollChance)
		end
		check(lo > prevMax, string.format("%s: Chancen überlappen mit der vorherigen Rarity (%d <= %d)", rarity, lo, prevMax))
		prevMax = hi
	end
end

-- Innerhalb einer Rarity: seltener (größeres "1 in X") => mehr $/s, auch bei Commons
for rarity, defs in perRarity do
	for _, a in defs do
		for _, b in defs do
			local aRarer = a.RollChance > b.RollChance
			if aRarer then
				check(a.BaseMoneyPerSecond >= b.BaseMoneyPerSecond, string.format("%s: %s ist seltener als %s, verdient aber weniger", rarity, a.Id, b.Id))
			end
		end
	end
end

-- Fishing-Spezialisten: höchste Fishing Power und niedrigstes Einkommen ihrer Rarity
local specialists = 0
for rarity, defs in perRarity do
	for _, a in defs do
		if a.Description:find("Fishing specialist", 1, true) then
			specialists += 1
			for _, b in defs do
				check(a.BaseFishingPower >= b.BaseFishingPower, a.Id .. ": Fishing-Spezialist hat nicht die höchste Fishing Power")
				check(a.BaseMoneyPerSecond <= b.BaseMoneyPerSecond, a.Id .. ": Fishing-Spezialist verdient nicht am wenigsten")
			end
		end
	end
end
check(specialists >= 8, "Zu wenige Fishing-Spezialisten: " .. specialists)

-- Vokabular-Abdeckung
local accessoryCount = #Accessories.Ids
check(accessoryCount >= 40, "Mindestens 40 Accessories erwartet, gefunden " .. accessoryCount)
for _, body in Bodies.Types() do
	check((bodyUse[body] or 0) > 0, "Body-Typ wird von keinem Character benutzt: " .. body)
end
for _, mut in MutationConfig.List do
	if mut.Effect then
		check(AuraLibrary.Has(mut.Effect), "AuraLibrary fehlt Mutations-Effekt " .. mut.Effect)
	end
end
for _, lvl in { "LevelGlow1", "LevelGlow2", "LevelMax" } do
	check(AuraLibrary.Has(lvl), "AuraLibrary fehlt " .. lvl)
end

if #failures > 0 then
	for _, f in failures do
		print("  FEHLER: " .. f)
	end
	error(string.format("%d Fehler in den Character-Daten (siehe oben)", #failures))
end

-------------------------------------------------------------------------------
-- 2) Models bauen
-------------------------------------------------------------------------------
local GROUPS = {}
for _, g in ModelFactory.GROUP_NAMES do
	GROUPS[g] = true
end

local function countParts(model: Instance): number
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

local function countClass(model: Instance, class: string): number
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA(class) then
			n += 1
		end
	end
	return n
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-3
end

local function checkModel(def: any, model: Model, label: string, lowDetail: boolean)
	local tag = def.Id .. " [" .. label .. "]"
	check(model.Name == def.Id, tag .. ": Model.Name")
	local root = model.PrimaryPart
	check(root ~= nil and root.Name == "Root", tag .. ": PrimaryPart muss 'Root' sein")
	if root then
		check(near(root.Size.X, 2) and near(root.Size.Y, 0.2) and near(root.Size.Z, 2), tag .. ": Root-Größe")
		check(root.Transparency == 1, tag .. ": Root muss unsichtbar sein")
	end
	check(model:GetAttribute("CharacterId") == def.Id, tag .. ": Attribut CharacterId")
	check(model:GetAttribute("Rarity") == def.Rarity, tag .. ": Attribut Rarity")
	local height = model:GetAttribute("Height")
	local width = model:GetAttribute("Width")
	check(type(height) == "number" and height > 1 and height < 40, tag .. ": Attribut Height " .. tostring(height))
	check(type(width) == "number" and width > 0.5 and width < 40, tag .. ": Attribut Width " .. tostring(width))
	check(model:FindFirstChild("Body") ~= nil, tag .. ": Body-Gruppe fehlt")

	local body = def.Visual.Body
	local budget = Bodies.Budget[body]
	if def.Category == "Human" then
		budget = math.min(budget, 45)
	end
	local parts = countParts(model)
	check(parts <= budget, string.format("%s: %d Parts > Budget %d", tag, parts, budget))

	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			check(d.Anchored == true, tag .. ": " .. d.Name .. " nicht Anchored")
			check(d.CanCollide == false and d.CanTouch == false and d.CanQuery == false, tag .. ": " .. d.Name .. " kollidiert/touch/query")
			check(d.Massless == true, tag .. ": " .. d.Name .. " nicht Massless")
			if math.max(d.Size.X, d.Size.Y, d.Size.Z) < 1 then
				check(d.CastShadow == false, tag .. ": kleiner Part " .. d.Name .. " wirft Schatten")
			end
			check(d:FindFirstChildWhichIsA("Weld") == nil and d:FindFirstChildWhichIsA("WeldConstraint") == nil, tag .. ": Welds sind verboten")
		elseif d:IsA("Model") then
			if GROUPS[d.Name] then
				local pp = d.PrimaryPart
				check(pp ~= nil and pp.Name == "Joint" and pp.Parent == d, tag .. ": Gruppe " .. d.Name .. " ohne Joint-PrimaryPart")
				if pp then
					check(pp.Transparency == 1, tag .. ": Joint von " .. d.Name .. " sichtbar")
				end
				if d.Name == "Held" then
					check(d.Parent ~= nil and d.Parent.Name == "ArmR", tag .. ": Held muss in ArmR liegen")
				else
					check(d.Parent == model, tag .. ": Gruppe " .. d.Name .. " muss direkt im Model liegen")
				end
			else
				check(d.Name == "Body" and d.Parent == model, tag .. ": unerwartetes Kind-Model " .. d.Name)
			end
		elseif d:IsA("ParticleEmitter") or d:IsA("PointLight") or d:IsA("Beam") or d:IsA("Trail") then
			check(d.Parent ~= nil and d.Parent:IsA("Attachment"), tag .. ": Effekt " .. d.Name .. " nicht unter einem Attachment")
			if d:IsA("ParticleEmitter") then
				check(d.Rate <= 20, tag .. ": Emitter-Rate zu hoch")
			end
		elseif d:IsA("Decal") or d:IsA("Texture") or d:IsA("MeshPart") then
			check(false, tag .. ": verbotene Klasse " .. d.ClassName)
		elseif d:IsA("SpecialMesh") then
			check(d.MeshId == "" and d.TextureId == "", tag .. ": SpecialMesh mit Asset-Id")
		end
	end

	local skipped = model:GetAttribute("SkippedAccessories")
	check(skipped == nil, tag .. ": Accessories verworfen/übersprungen: " .. tostring(skipped))

	local emitters = countClass(model, "ParticleEmitter")
	local lights = countClass(model, "PointLight")
	if lowDetail then
		check(emitters == 0 and lights == 0, tag .. ": LowDetail darf keine Emitter/Lichter haben")
	else
		check(emitters <= 3, tag .. ": mehr als 3 ParticleEmitter (" .. emitters .. ")")
		check(lights <= 3, tag .. ": mehr als 3 Lichter (" .. lights .. ")")
	end

	-- Gruppen, die der Body-Typ garantiert
	local humanoidBody = Bodies.Humanoid[body]
	if humanoidBody or body == "Quadruped" or body == "Crawler" or body == "Serpent" or body == "Winged" or body == "Floating" then
		check(model:FindFirstChild("Head") ~= nil, tag .. ": Head-Gruppe fehlt")
	end
	if humanoidBody or body == "Floating" then
		check(model:FindFirstChild("ArmL") ~= nil and model:FindFirstChild("ArmR") ~= nil, tag .. ": Arm-Gruppen fehlen")
	end
	if body == "Winged" then
		check(model:FindFirstChild("WingL") ~= nil and model:FindFirstChild("WingR") ~= nil, tag .. ": Wing-Gruppen fehlen")
	end
	if body == "Blob" or body == "Orb" or body == "Eye" or body == "Hive" then
		check(model:FindFirstChild("Core") ~= nil, tag .. ": Core-Gruppe fehlt")
	end
	if body == "Orb" or body == "Hive" then
		check(model:FindFirstChild("Orbit") ~= nil, tag .. ": Orbit-Gruppe fehlt")
	end
	return parts
end

local partStats: { [string]: { n: number, sum: number, max: number } } = {}
local heightById: { [string]: number } = {}
local MUTATION_CYCLE = { "Electric", "Shadow", "BloodMoon", "Rift" }
local builds = 0

for i, def in list do
	-- Normal: Level 1, keine Mutation
	local m0 = ModelFactory.Build(def.Id)
	local base = checkModel(def, m0, "Lv1", false)
	heightById[def.Id] = m0:GetAttribute("Height")
	local stats = partStats[def.Rarity] or { n = 0, sum = 0, max = 0 }
	stats.n += 1
	stats.sum += base
	stats.max = math.max(stats.max, base)
	partStats[def.Rarity] = stats
	builds += 1

	-- Level 15 mit Void / Golden / wechselnder Mutation
	for _, mutation in { "Void", "Golden", MUTATION_CYCLE[(i % #MUTATION_CYCLE) + 1] } do
		local m = ModelFactory.Build(def.Id, { Level = 15, Mutation = mutation })
		checkModel(def, m, "Lv15 " .. mutation, false)
		check(m:GetAttribute("Mutation") == mutation, def.Id .. ": Mutation-Attribut")
		check(m:GetAttribute("VisualLevel") == 15, def.Id .. ": VisualLevel-Attribut")
		builds += 1
	end

	-- LowDetail
	local low = ModelFactory.Build(def.Id, { Level = 15, Mutation = "Void", LowDetail = true })
	checkModel(def, low, "LowDetail", true)
	builds += 1

	-- Idempotenz: Level und Mutation mehrfach anwenden
	local m = ModelFactory.Build(def.Id, { Level = 5 })
	ModelFactory.ApplyLevelVisual(m, 10)
	ModelFactory.ApplyLevelVisual(m, 15)
	local partsA, emA = countParts(m), countClass(m, "ParticleEmitter")
	ModelFactory.ApplyLevelVisual(m, 15)
	check(countParts(m) == partsA and countClass(m, "ParticleEmitter") == emA, def.Id .. ": ApplyLevelVisual nicht idempotent")
	local torso: BasePart? = nil
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 and d:GetAttribute("VDRole") == nil then
			torso = d
			break
		end
	end
	local color0 = torso and torso.Color
	ModelFactory.ApplyMutation(m, "Golden")
	ModelFactory.ApplyMutation(m, "Void")
	ModelFactory.ApplyMutation(m, "Void")
	check(countClass(m, "ParticleEmitter") <= 3, def.Id .. ": Emitter-Limit nach Mutationen")
	ModelFactory.ApplyMutation(m, "Normal")
	if torso and color0 then
		check(torso.Color == color0, def.Id .. ": Mutation 'Normal' stellt Farbe nicht wieder her")
	end
	ModelFactory.ApplyLevelVisual(m, 1)
	check(countClass(m, "ParticleEmitter") <= 1, def.Id .. ": Level 1 sollte nur die Aura behalten")
	checkModel(def, m, "Reapply", false)
	builds += 1
end

-------------------------------------------------------------------------------
-- 3) Zusammenfassung
-------------------------------------------------------------------------------
print("")
print(string.format("%-13s %5s %6s %9s %7s %9s %9s", "Rarity", "Count", "Human", "Creature", "Entity", "AvgParts", "MaxParts"))
for _, rarity in RARITY_ORDER do
	local defs = perRarity[rarity] or {}
	local cats = { Human = 0, Creature = 0, Entity = 0 }
	for _, d in defs do
		cats[d.Category] += 1
	end
	local s = partStats[rarity] or { n = 1, sum = 0, max = 0 }
	print(string.format("%-13s %5d %6d %9d %7d %9.1f %9d", rarity, #defs, cats.Human, cats.Creature, cats.Entity, s.sum / math.max(1, s.n), s.max))
end
print(string.format("%-13s %5d %6d %9d %7d", "TOTAL", #list, categories.Human, categories.Creature, categories.Entity))
local sums = {}
for _, rarity in RARITY_ORDER do
	if tierSums[rarity] then
		table.insert(sums, string.format("%s %.1f%%", rarity, tierSums[rarity] * 100))
	end
end
print("Chance-Summen vs. Ziel: " .. table.concat(sums, ", "))
print(string.format("Thumbnails: %d | Fishing-Spezialisten: %d | Accessories: %d | Auren: %d | Builds: %d", thumbnails, specialists, accessoryCount, #AuraLibrary.Ids(), builds))

if #failures > 0 then
	for i = 1, math.min(#failures, 80) do
		print("  FEHLER: " .. failures[i])
	end
	error(string.format("%d Fehler beim Model-Bau (siehe oben)", #failures))
end

print("test_characters: OK")
