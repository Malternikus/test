-- test_logic.luau (Lune)
--
-- Tests der kompletten Spiellogik mit den echten Modulen (über den Harness):
-- RNG/Luck, Inventar, Base, Einkommen, Upgrades 1–15, Dice, Rebirth, Fishing,
-- Gear, Potions, Quests, Achievements, Season, Speichern (Profil-Format),
-- Anti-Cheat (Rate Limits, Argumente), mehrere Spieler.
--
-- Aufruf: cd VoidDice/tests && lune run test_logic.luau

local serde = require("@lune/serde")
local process = require("@lune/process")
local Harness = require("./harness")

local ROOT = (process.cwd :: string):gsub("/tests/?$", ""):gsub("/$", "")
local h = Harness.load(ROOT)

local Logic = h.requirePath("ServerScriptService.VoidDiceServer.Logic")
local AntiCheat = h.requirePath("ServerScriptService.VoidDiceServer.Services.AntiCheatService")
local function cfg(name)
	return h.requirePath("ReplicatedStorage.VoidDice.Config." .. name)
end
local RollMath = h.requirePath("ReplicatedStorage.VoidDice.Util.RollMath")
local Odds = h.requirePath("ReplicatedStorage.VoidDice.Util.Odds")
local Stats = h.requirePath("ReplicatedStorage.VoidDice.Util.Stats")
local Format = h.requirePath("ReplicatedStorage.VoidDice.Util.Format")
local Net = h.requirePath("ReplicatedStorage.VoidDice.Net")
local CharacterConfig = cfg("CharacterConfig")
local RarityConfig = cfg("RarityConfig")
local EconomyConfig = cfg("EconomyConfig")
local GameConfig = cfg("GameConfig")
local RebirthConfig = cfg("RebirthConfig")
local DiceConfig = cfg("DiceConfig")
local AreaConfig = cfg("AreaConfig")
local PotionConfig = cfg("PotionConfig")
local GearConfig = cfg("GearConfig")
local QuestConfig = cfg("QuestConfig")
local SeasonConfig = cfg("SeasonConfig")
local FishingConfig = cfg("FishingConfig")

local Context = Logic.Context

-- Mini-Testframework ------------------------------------------------------------------
local passed, failed = 0, 0
local failures = {}

local function test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print("  ✓ " .. name)
	else
		failed += 1
		table.insert(failures, name .. ": " .. tostring(err))
		print("  ✗ " .. name .. "\n      " .. tostring(err))
	end
end

local function expect(cond: any, msg: string?)
	if not cond then
		error(msg or "expectation failed", 2)
	end
end

local function near(a: number, b: number, tolerance: number, msg: string?)
	if math.abs(a - b) > tolerance then
		error(string.format("%s: %.6g vs %.6g (tol %.3g)", msg or "near", a, b, tolerance), 2)
	end
end

local T0 = 1_800_000_000
local function newProfile(seed: number?)
	local rng = Harness.Random.new(seed or 1)
	local profile = Logic.ProfileTemplate.new()
	local ctx = Context.new({ now = T0, rng = rng, userId = 42 })
	Logic.onLoad(profile, ctx)
	return profile, rng
end
local function ctxFor(rng, now: number?)
	return Context.new({ now = now or T0, rng = rng, userId = 42 })
end
local function firstOfRarity(rarity: string)
	return CharacterConfig.ByRarity[rarity][1]
end

-- 1) RollMath ------------------------------------------------------------------------
print("\nRollMath")
test("Wahrscheinlichkeiten summieren sich zu 1 (Luck 1 … 1e6)", function()
	local tbl = Odds.characterTable()
	for _, luck in { 1, 1.5, 2, 5, 12, 100, 1e4, 1e6 } do
		local sum = 0
		for _, p in RollMath.probabilities(tbl, luck) do
			expect(p >= 0, "negative Wahrscheinlichkeit")
			sum += p
		end
		near(sum, 1, 1e-9, "Summe bei Luck " .. luck)
	end
end)

test("Luck 1 = exakt Config-Chance, Luck L = exakt L-fach (seltene Characters)", function()
	for _, def in CharacterConfig.List do
		if RarityConfig.Get(def.Rarity).LuckAffected then
			local p1 = Odds.characterProbability(def.Id, 1)
			near(p1, 1 / def.RollChance, 1e-12, def.Id)
			-- Luck 2: alle seltenen Chancen zusammen < 100 %, also keine Deckelung
			local p2 = Odds.characterProbability(def.Id, 2)
			near(p2, 2 / def.RollChance, 1e-12, def.Id .. " @2")
		end
	end
end)

test("Rarity-Tiers treffen die Zielwerte (±10 %)", function()
	local probs = Odds.rarityProbabilities(1)
	for _, r in RarityConfig.List do
		if r.LuckAffected then
			local ratio = probs[r.Id] / r.TierTarget
			expect(ratio > 0.9 and ratio < 1.1, string.format("%s: %.4g vs Ziel %.4g", r.Id, probs[r.Id], r.TierTarget))
		end
	end
end)

test("Mehr Luck = seltenere Rarities wahrscheinlicher, Commons weniger", function()
	local a, b = Odds.rarityProbabilities(1), Odds.rarityProbabilities(3)
	expect(b.Common < a.Common, "Common sinkt")
	for _, r in RarityConfig.List do
		if r.LuckAffected then
			expect(b[r.Id] > a[r.Id], r.Id .. " steigt")
		end
	end
end)

test("Empirische Verteilung passt zur Theorie (300k Ziehungen, Luck 1 und 8)", function()
	local tbl = Odds.characterTable()
	for _, luck in { 1, 8 } do
		local rng = Harness.Random.new(99 + luck)
		local counts = {}
		local N = 300000
		for _ = 1, N do
			local e = RollMath.pick(tbl, luck, rng:NextNumber())
			local rarity = CharacterConfig.ById[e.Key].Rarity
			counts[rarity] = (counts[rarity] or 0) + 1
		end
		local probs = Odds.rarityProbabilities(luck)
		for _, r in RarityConfig.List do
			local expected = probs[r.Id] * N
			if expected >= 50 then
				local observed = counts[r.Id] or 0
				-- 5 Standardabweichungen
				local sd = math.sqrt(expected * (1 - probs[r.Id]))
				expect(math.abs(observed - expected) <= 5 * sd, string.format("%s @%d: %d vs %.1f", r.Id, luck, observed, expected))
			end
		end
	end
end)

test("Deckelung bei extremer Luck: Commons verschwinden, Summe bleibt 1", function()
	local probs = Odds.rarityProbabilities(1e6)
	near(probs.Common, 0, 1e-12, "Common")
	local sum = 0
	for _, p in probs do
		sum += p
	end
	near(sum, 1, 1e-9, "Summe")
end)

-- 2) Characters ------------------------------------------------------------------------
print("\nCharacters")
test("100 Characters, eindeutige Ids, Werte gültig", function()
	expect(#CharacterConfig.List == 100, "Anzahl: " .. #CharacterConfig.List)
	local names = {}
	for _, def in CharacterConfig.List do
		expect(not names[def.DisplayName], "doppelter Name " .. def.DisplayName)
		names[def.DisplayName] = true
		expect(def.MaxLevel == 15, def.Id .. " MaxLevel")
		expect(def.BaseMoneyPerSecond > 0 and def.BasePower > 0 and def.BaseFishingPower > 0, def.Id .. " Stats")
		expect(RarityConfig.ById[def.Rarity], def.Id .. " Rarity")
	end
end)

test("Keine geschützten Namen aus fremden Marken", function()
	local banned = { "eleven", "vecna", "dustin", "demogorgon", "hawkins", "upside down", "mind flayer", "hopper", "byers", "hellfire", "starcourt", "pennywise", "xenomorph", "ghostbuster", "slender" }
	for _, def in CharacterConfig.List do
		local text = string.lower(def.DisplayName .. " " .. def.Description .. " " .. def.VisualTheme)
		for _, word in banned do
			expect(not text:find(word, 1, true), def.Id .. " enthält '" .. word .. "'")
		end
	end
end)

-- 3) Roll + Inventar + Base ---------------------------------------------------------
print("\nRoll, Inventar, Base")
test("Roll: Server-Ergebnis landet im Inventar, Index und Stats", function()
	local profile, rng = newProfile(1)
	local ctx = ctxFor(rng)
	local r = Logic.Rolling.roll(profile, ctx)
	expect(r.Uid and profile.Characters[r.Uid], "im Inventar")
	expect(profile.Index[r.Id] and profile.Index[r.Id].N == 1, "Index")
	expect(r.IsNew, "neu")
	expect(profile.Stats.TotalRolls == 1, "TotalRolls")
	expect(ctx.dirtyChars[r.Uid], "Sync markiert")
end)

test("Auto Place füllt 6 Start-Slots und ersetzt den Schwächsten", function()
	local profile, rng = newProfile(2)
	local ctx = ctxFor(rng)
	local common = firstOfRarity("Common")
	local mods = Logic.Modifiers.compute(profile)
	expect(mods.BaseSlots == GameConfig.StartBaseSlots, "6 Slots")
	for _ = 1, 6 do
		local uid = Logic.Inventory.add(profile, ctx, common.Id)
		Logic.Inventory.autoPlace(profile, ctx, uid, mods)
	end
	local placed = 0
	for _, c in profile.Characters do
		if c.Slot then
			placed += 1
		end
	end
	expect(placed == 6, "6 platziert")
	local legendary = firstOfRarity("Legendary")
	local uid = Logic.Inventory.add(profile, ctx, legendary.Id)
	expect(Logic.Inventory.autoPlace(profile, ctx, uid, mods), "Legendary ersetzt Common")
	expect(profile.Characters[uid].Slot ~= nil, "Legendary in Base")
	local stillPlaced = 0
	for _, c in profile.Characters do
		if c.Slot then
			stillPlaced += 1
		end
	end
	expect(stillPlaced == 6, "weiterhin 6")
end)

test("Place Best wählt die besten $/s", function()
	local profile, rng = newProfile(3)
	local ctx = ctxFor(rng)
	profile.Settings.AutoPlace = false
	local ids = {}
	for _, rarity in { "Common", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Common" } do
		table.insert(ids, Logic.Inventory.add(profile, ctx, firstOfRarity(rarity).Id))
	end
	Logic.Inventory.placeBest(profile, ctx, Logic.Modifiers.compute(profile))
	local placedRarities = {}
	for _, c in profile.Characters do
		if c.Slot then
			table.insert(placedRarities, CharacterConfig.ById[c.Id].Rarity)
		end
	end
	expect(#placedRarities == 6, "6 platziert")
	expect(table.find(placedRarities, "Mythic") and table.find(placedRarities, "Legendary"), "die Besten sind drin")
end)

test("Verkaufen: Cash rein, gesperrte Characters geschützt", function()
	local profile, rng = newProfile(4)
	local ctx = ctxFor(rng)
	local uid = Logic.Inventory.add(profile, ctx, firstOfRarity("Rare").Id)
	Logic.Inventory.setLocked(profile, ctx, uid, true)
	local ok = Logic.Inventory.sell(profile, ctx, uid)
	expect(not ok, "gesperrt")
	Logic.Inventory.setLocked(profile, ctx, uid, false)
	local ok2, value = Logic.Inventory.sell(profile, ctx, uid)
	expect(ok2 and value > 0 and profile.Cash == value, "verkauft")
	expect(profile.Characters[uid] == nil, "weg")
end)

test("Auto Delete: nur bis Epic, neue Entdeckungen und Mutationen bleiben", function()
	local profile, rng = newProfile(5)
	local ctx = ctxFor(rng)
	expect(not Logic.setAutoDelete(profile, ctx, "Legendary", true), "Legendary nicht erlaubt")
	expect(Logic.setAutoDelete(profile, ctx, "Common", true), "Common erlaubt")
	local kept, deleted = 0, 0
	for _ = 1, 400 do
		local r = Logic.Rolling.roll(profile, ctx)
		if r.Rarity == "Common" then
			if r.SoldReason == "AutoDelete" then
				deleted += 1
				expect(not r.IsNew and r.Mutation == "Normal", "nur bekannte, normale Commons")
			else
				kept += 1
				expect(r.IsNew or r.Mutation ~= "Normal", "behalten nur wenn neu/mutiert")
			end
		end
	end
	expect(deleted > 0, "es wurde gelöscht")
end)

test("Inventar voll: schwächster freier Character wird ersetzt, Hard Cap hält", function()
	local profile, rng = newProfile(6)
	local ctx = ctxFor(rng)
	local common = firstOfRarity("Common")
	for _ = 1, GameConfig.InventoryHardCap do
		Logic.Inventory.add(profile, ctx, common.Id)
	end
	profile.Index[common.Id] = { N = 1, M = {} }
	for _ = 1, 200 do
		Logic.Rolling.roll(profile, ctx)
	end
	expect(Logic.Inventory.count(profile) <= GameConfig.InventoryHardCap, "Hard Cap eingehalten")
	-- ein Rare ersetzt einen Common statt verkauft zu werden
	local rares = 0
	for _, c in profile.Characters do
		if CharacterConfig.ById[c.Id].Rarity ~= "Common" then
			rares += 1
		end
	end
	expect(rares > 0, "bessere Rolls wurden behalten")
end)

-- 4) Economy -----------------------------------------------------------------------------
print("\nEconomy")
test("Passives Einkommen: Vault füllt sich, Collect bucht auf Cash, Deckel greift", function()
	local profile, rng = newProfile(7)
	local ctx = ctxFor(rng)
	local def = firstOfRarity("Epic")
	local uid = Logic.Inventory.add(profile, ctx, def.Id)
	Logic.Inventory.place(profile, ctx, uid, Logic.Modifiers.compute(profile))
	Logic.tick(profile, ctx, 10)
	near(profile.Vault, def.BaseMoneyPerSecond * 10, 1e-6, "Vault nach 10 s")
	local got = Logic.Economy.collect(profile, ctx)
	near(got, def.BaseMoneyPerSecond * 10, 1e-6, "Collect")
	near(profile.Cash, got, 1e-6, "Cash")
	Logic.tick(profile, ctx, 1e6)
	local cap = Logic.Economy.vaultCapacity(def.BaseMoneyPerSecond)
	near(profile.Vault, cap, 1e-6, "Vault gedeckelt")
end)

test("Upgrades 1→15: exakte Kosten, wachsendes Einkommen, kein Overflow über Max", function()
	local profile, rng = newProfile(8)
	local ctx = ctxFor(rng)
	local def = firstOfRarity("Rare")
	local uid = Logic.Inventory.add(profile, ctx, def.Id)
	local total = 0
	local lastIncome = Stats.income(def, 1, "Normal")
	for level = 1, 14 do
		local cost = Stats.upgradeCost(def, level, "Normal")
		expect(cost and cost > 0, "Kosten L" .. level)
		total += cost
	end
	Logic.Economy.earn(profile, ctx, total, "Test")
	for level = 1, 14 do
		local ok = Logic.Upgrades.upgrade(profile, ctx, uid, 1)
		expect(ok, "Upgrade auf " .. level + 1)
		local income = Stats.income(def, level + 1, "Normal")
		expect(income > lastIncome, "Einkommen steigt")
		lastIncome = income
	end
	near(profile.Cash, 0, 1e-6, "genau alles ausgegeben")
	expect(profile.Characters[uid].Level == 15, "Level 15")
	local ok, err = Logic.Upgrades.upgrade(profile, ctx, uid, 1)
	expect(not ok and err == "Already max level", "Max-Level")
	near(Stats.income(def, 15, "Normal") / Stats.income(def, 1, "Normal"), EconomyConfig.LevelIncomeMultiplier[15], 1e-9, "x5 bei Max")
	expect(profile.Stats.HighestCharacterLevel == 15, "Stat")
end)

test("Upgrade ohne Cash schlägt fehl und kostet nichts", function()
	local profile, rng = newProfile(9)
	local ctx = ctxFor(rng)
	local uid = Logic.Inventory.add(profile, ctx, firstOfRarity("Epic").Id)
	local ok, err = Logic.Upgrades.upgrade(profile, ctx, uid, 1)
	expect(not ok and err == "Not enough cash" and profile.Characters[uid].Level == 1, "abgelehnt")
end)

test("Upgrade-Kosten: Stufe 1–5 günstig, 6–10 mittel, 11–15 teuer", function()
	local s = EconomyConfig.UpgradeCostSeconds
	expect(s[1] < s[6] and s[6] < s[11] and s[11] < s[14], "Stufung")
end)

-- 5) Dice, Gebiete, Rebirth -------------------------------------------------------------
print("\nDice, Gebiete, Rebirth")
test("Dice kaufen braucht Gebiet, Gebiet braucht Rebirth + Cash", function()
	local profile, rng = newProfile(10)
	local ctx = ctxFor(rng)
	Logic.Economy.earn(profile, ctx, 1e12, "Test")
	local ok = Logic.Progression.buyDice(profile, ctx, "Strange")
	expect(not ok, "Gebiet fehlt")
	local okArea, err = Logic.Progression.unlockArea(profile, ctx, "DarkForest")
	expect(not okArea and err:find("Rebirth"), "Rebirth fehlt")
	profile.Rebirths = 1
	expect(Logic.Progression.unlockArea(profile, ctx, "DarkForest"), "Gebiet frei")
	expect(not Logic.Progression.unlockArea(profile, ctx, "RiftZone"), "Reihenfolge")
	expect(Logic.Progression.buyDice(profile, ctx, "Strange"), "Dice gekauft")
	expect(profile.Dice.Equipped == "Strange", "ausgerüstet")
	near(Logic.Modifiers.compute(profile).Luck, 2 * (1 + (RebirthConfig.Accumulate(1).LuckPct) / 100), 1e-9, "Luck x2")
end)

test("Rebirth: nur Cash-Progression wird zurückgesetzt", function()
	local profile, rng = newProfile(11)
	local ctx = ctxFor(rng)
	local uid = Logic.Inventory.add(profile, ctx, firstOfRarity("Epic").Id)
	Logic.Inventory.place(profile, ctx, uid, Logic.Modifiers.compute(profile))
	Logic.Economy.earn(profile, ctx, 1e6, "Test")
	Logic.Upgrades.upgrade(profile, ctx, uid, 5)
	local gearUid = Logic.Items.addGear(profile, ctx, "WalkieTalkie")
	Logic.Items.addPotion(profile, ctx, "Luck", 2)
	profile.Vault = 500
	local cost = Logic.Progression.rebirthCost(profile)
	Logic.Economy.earn(profile, ctx, cost, "Test")
	local charCount = Logic.Inventory.count(profile)
	local indexBefore = profile.Index
	expect(Logic.Progression.rebirth(profile, ctx), "Rebirth ok")
	expect(profile.Cash == 0 and profile.Vault == 0, "Cash/Vault weg")
	expect(profile.Characters[uid].Level == 1, "Level 1")
	expect(Logic.Inventory.count(profile) == charCount, "Characters bleiben")
	expect(profile.Gear[gearUid] and profile.Potions.Luck == 2, "Gear/Potions bleiben")
	expect(profile.Index == indexBefore, "Index bleibt")
	local mods = Logic.Modifiers.compute(profile)
	expect(mods.BaseSlots == GameConfig.StartBaseSlots + 2, "+2 Slots")
	near(mods.CashMultiplier, 1.1, 1e-9, "+10 % Cash")
	expect(mods.AutoCollect, "Auto Collect")
	expect(not Logic.Progression.rebirth(profile, ctx), "zweiter Rebirth ohne Cash geht nicht")
end)

test("Rebirth-Kosten steigen streng, auch nach der Tabelle", function()
	local last = 0
	for i = 1, 25 do
		local c = RebirthConfig.GetStep(i).Cost
		expect(c > last, "Rebirth " .. i)
		last = c
	end
end)

-- 6) Fishing, Gear, Potions ---------------------------------------------------------------
print("\nFishing, Gear, Potions")
test("Fishing: gesperrt bis Schwelle, dann Fänge mit Loot", function()
	local profile, rng = newProfile(12)
	local ctx = ctxFor(rng)
	local uid = Logic.Inventory.add(profile, ctx, firstOfRarity("Rare").Id)
	local mods = Logic.Modifiers.compute(profile)
	expect(not Logic.Fishing.send(profile, ctx, uid, mods), "gesperrt")
	Logic.Economy.earn(profile, ctx, GameConfig.FishingUnlockCashEarned, "Test")
	expect(Logic.Fishing.send(profile, ctx, uid, mods), "gesendet")
	local uid2 = Logic.Inventory.add(profile, ctx, firstOfRarity("Rare").Id)
	expect(not Logic.Fishing.send(profile, ctx, uid2, mods), "nur 1 Slot am Start")
	local before = profile.Stats.FishingCatches
	for _ = 1, 600 do
		Logic.tick(profile, ctx, 1)
	end
	local catches = profile.Stats.FishingCatches - before
	local interval = Logic.Fishing.interval(profile, profile.Characters[uid], mods)
	expect(math.abs(catches - math.floor(600 / interval)) <= 1, string.format("Fänge %d bei Intervall %.1f", catches, interval))
	expect(Logic.Economy.incomePerSecond(profile, mods) == 0, "Fischer verdienen kein Base-Cash")
	expect(Logic.Fishing.recall(profile, ctx, uid), "zurückgerufen")
end)

test("Fishing-Loot-Tabellen: alle Ids existieren, Summe 1", function()
	for _, waters in FishingConfig.Waters do
		for _, loot in waters.Loot do
			if loot.Kind == "Potion" then
				expect(PotionConfig.Get(loot.Id), "Potion " .. tostring(loot.Id))
			elseif loot.Kind == "Gear" then
				expect(GearConfig.Get(loot.Id), "Gear " .. tostring(loot.Id))
			elseif loot.Kind == "Relic" then
				expect(FishingConfig.RelicById[loot.Id], "Relic " .. tostring(loot.Id))
			elseif loot.Kind == "Cosmetic" then
				expect(cfg("CosmeticConfig").Get(loot.Id), "Cosmetic " .. tostring(loot.Id))
			end
		end
		local tbl = Odds.watersTable(waters.Id)
		local sum = 0
		for _, p in RollMath.probabilities(tbl, 3) do
			sum += p
		end
		near(sum, 1, 1e-9, waters.Id)
		expect(AreaConfig.Get(waters.Area), "Area " .. waters.Area)
	end
end)

test("Gear: max 2 Slots, Cash-Gear erhöht $/s, Luck-Gear nur in der Base", function()
	local profile, rng = newProfile(13)
	local ctx = ctxFor(rng)
	local def = firstOfRarity("Epic")
	local uid = Logic.Inventory.add(profile, ctx, def.Id)
	local mods = Logic.Modifiers.compute(profile)
	local g1 = Logic.Items.addGear(profile, ctx, "StrangeBattery")
	local g2 = Logic.Items.addGear(profile, ctx, "MoodRing")
	local g3 = Logic.Items.addGear(profile, ctx, "WalkieTalkie")
	expect(Logic.Items.equipGear(profile, ctx, g1, uid, mods), "1")
	expect(Logic.Items.equipGear(profile, ctx, g2, uid, mods), "2")
	expect(not Logic.Items.equipGear(profile, ctx, g3, uid, mods), "3. Slot gesperrt")
	expect(Logic.Modifiers.compute(profile).Luck == 1, "nicht platziert -> keine Luck")
	Logic.Inventory.place(profile, ctx, uid, mods)
	local m2 = Logic.Modifiers.compute(profile)
	near(m2.Luck, 1 + GearConfig.Get("MoodRing").LuckPct / 100, 1e-9, "Luck-Gear")
	near(Logic.Economy.characterIncome(profile, profile.Characters[uid], m2), def.BaseMoneyPerSecond * 1.18, 1e-6, "Cash-Gear +18 %")
	expect(Logic.Items.sellGear(profile, ctx, g1), "verkauft (auch wenn ausgerüstet)")
	expect(#profile.Characters[uid].Gear == 1, "Slot frei")
end)

test("Potions: Effekt, Stapeln bis Max, Ablauf nur online", function()
	local profile, rng = newProfile(14)
	local ctx = ctxFor(rng)
	Logic.Items.addPotion(profile, ctx, "Luck", 10)
	expect(Logic.Items.usePotion(profile, ctx, "Luck"), "benutzt")
	near(Logic.Modifiers.compute(profile).Luck, 1.25, 1e-9, "+25 %")
	for _ = 1, 9 do
		Logic.Items.usePotion(profile, ctx, "Luck")
	end
	expect(profile.Boosts.Luck <= PotionConfig.MaxDuration, "Max-Dauer")
	expect((profile.Potions.Luck or 0) >= 3, "über Max wird nicht verbraucht")
	Logic.tick(profile, ctx, PotionConfig.MaxDuration + 1)
	expect(profile.Boosts.Luck == nil, "abgelaufen")
	near(Logic.Modifiers.compute(profile).Luck, 1, 1e-9, "Luck zurück")
	expect(not Logic.Items.usePotion(profile, ctx, "VoidElixir"), "nicht besessen")
end)

-- 7) Quests, Achievements, Season --------------------------------------------------------
print("\nQuests, Achievements, Season")
test("Daily Quests: erster Tag fest, Fortschritt, einmal einlösen, neuer Tag deterministisch", function()
	local profile, rng = newProfile(15)
	local ctx = ctxFor(rng)
	expect(#profile.Quests.List == #QuestConfig.FirstDayQuests, "erster Tag")
	for _ = 1, 50 do
		Logic.Rolling.roll(profile, ctx)
	end
	expect(Logic.Goals.claimQuest(profile, ctx, "Roll50"), "eingelöst")
	expect(not Logic.Goals.claimQuest(profile, ctx, "Roll50"), "nicht doppelt")
	local nextDay = ctxFor(rng, T0 + 86400)
	Logic.QuestTracker.ensureDaily(profile, nextDay)
	local ids1 = {}
	for _, q in profile.Quests.List do
		table.insert(ids1, q.Id)
	end
	local copy = Logic.ProfileTemplate.new()
	copy.Quests.FirstDay = false
	Logic.QuestTracker.ensureDaily(copy, nextDay)
	local ids2 = {}
	for _, q in copy.Quests.List do
		table.insert(ids2, q.Id)
	end
	expect(table.concat(ids1, ",") == table.concat(ids2, ","), "deterministisch")
	expect(#ids1 == QuestConfig.DailyCount, "Anzahl")
end)

test("Achievements: einmalig, mit Belohnung", function()
	local profile, rng = newProfile(16)
	local ctx = ctxFor(rng)
	Logic.Rolling.roll(profile, ctx)
	local unlocked = Logic.Goals.evaluateAchievements(profile, ctx)
	expect(table.find(unlocked, "FirstRoll"), "FirstRoll")
	expect(#Logic.Goals.evaluateAchievements(profile, ctx) == 0, "nicht doppelt")
	expect((profile.Potions.Luck or 0) >= 1, "Belohnung")
end)

test("Season: Tier braucht XP, Premium braucht Pass", function()
	local profile, rng = newProfile(17)
	local ctx = ctxFor(rng)
	expect(not Logic.Goals.claimSeason(profile, ctx, "Free", 1), "keine XP")
	profile.Season.Xp = SeasonConfig.XpPerTier
	expect(Logic.Goals.claimSeason(profile, ctx, "Free", 1), "Free 1")
	expect(not Logic.Goals.claimSeason(profile, ctx, "Free", 1), "doppelt")
	expect(not Logic.Goals.claimSeason(profile, ctx, "Premium", 1), "Premium gesperrt")
	Logic.grantPass(profile, ctx, "SeasonPremium")
	expect(Logic.Goals.claimSeason(profile, ctx, "Premium", 1), "Premium 1")
end)

-- 8) Monetization -------------------------------------------------------------------------------
print("\nMonetization")
test("Gamepasses wirken, Produkte haben festen Inhalt", function()
	local profile, rng = newProfile(18)
	local ctx = ctxFor(rng)
	Logic.grantPass(profile, ctx, "DoubleLuck")
	Logic.grantPass(profile, ctx, "VIP")
	local mods = Logic.Modifiers.compute(profile)
	near(mods.Luck, 2 * 1.1, 1e-9, "2X LUCK + VIP")
	near(mods.CashMultiplier, 1.1, 1e-9, "VIP Cash")
	expect(profile.Cosmetics.Owned.TitleVIP, "VIP-Titel")
	expect(Logic.grantProduct(profile, ctx, "PotionPack"), "Potion Pack")
	expect(profile.Potions.Luck == 3 and profile.Potions.Cash == 3, "fester Inhalt")
	for name, def in cfg("MonetizationConfig").Products do
		expect(def.Kind == "Cash" or def.Kind == "Potion", name .. ": keine Zufallsprodukte")
	end
end)

-- 9) Speichern ------------------------------------------------------------------------------
print("\nSpeichern")
local function checkDataStoreSafe(value, path: string)
	if type(value) == "table" then
		local n = #value
		local count = 0
		for key, v in value do
			count += 1
			if n > 0 then
				expect(type(key) == "number" and key >= 1 and key <= n, path .. ": gemischte Tabelle")
			else
				expect(type(key) == "string", path .. ": Key muss String sein (" .. tostring(key) .. ")")
			end
			checkDataStoreSafe(v, path .. "." .. tostring(key))
		end
	else
		local t = type(value)
		expect(t == "string" or t == "number" or t == "boolean", path .. ": Typ " .. t)
		if t == "number" then
			expect(value == value and value ~= math.huge, path .. ": NaN/inf")
		end
	end
end

test("Profil nach 2 h Spielzeit ist DataStore-tauglich (JSON, keine gemischten Tabellen)", function()
	local profile, rng = newProfile(19)
	for t = 1, 7200 do
		local ctx = ctxFor(rng, T0 + t)
		Logic.Rolling.roll(profile, ctx)
		Logic.tick(profile, ctx, 1)
		if t % 10 == 0 then
			Logic.Economy.collect(profile, ctx)
		end
		if t == 200 then
			for _, def in GearConfig.List do
				Logic.Items.addGear(profile, ctx, def.Id)
			end
			Logic.Items.addPotion(profile, ctx, "Luck", 2)
			Logic.Items.usePotion(profile, ctx, "Luck")
		end
	end
	checkDataStoreSafe(profile, "Profile")
	local json = serde.encode("json", profile)
	expect(#json < 3_500_000, "Größe " .. #json)
	local back = serde.decode("json", json)
	expect(back.Stats.TotalRolls == profile.Stats.TotalRolls, "Roundtrip")
	print(string.format("      Profilgröße nach 2 h: %.1f KB, %d Characters", #json / 1024, Logic.Inventory.count(profile)))
end)

test("Reconcile ergänzt fehlende Felder alter Profile ohne Daten zu verlieren", function()
	local old = { Cash = 123, Rebirths = 2, Characters = { c1 = { Id = firstOfRarity("Rare").Id, Level = 4, Mutation = "Normal", Gear = {}, Locked = false } }, NextCharUid = 2 }
	Logic.ProfileTemplate.reconcile(old)
	expect(old.Cash == 123 and old.Rebirths == 2 and old.Characters.c1.Level == 4, "Daten bleiben")
	expect(old.Stats and old.Settings and old.Dice.Equipped == "Basic" and old.Quests, "Felder ergänzt")
end)

test("Transfer (Raid-Vorbereitung) dupliziert nicht", function()
	local a, rngA = newProfile(20)
	local b, rngB = newProfile(21)
	local ctxA, ctxB = ctxFor(rngA), ctxFor(rngB)
	local uid = Logic.Inventory.add(a, ctxA, firstOfRarity("Mythic").Id)
	local newUid = Logic.Inventory.transfer(a, ctxA, b, ctxB, uid)
	expect(newUid and b.Characters[newUid] and not a.Characters[uid], "verschoben, nicht kopiert")
	local locked = Logic.Inventory.add(a, ctxA, firstOfRarity("Mythic").Id)
	Logic.Inventory.setLocked(a, ctxA, locked, true)
	expect(Logic.Inventory.transfer(a, ctxA, b, ctxB, locked) == nil, "gesperrt bleibt")
end)

-- 10) Anti-Cheat ------------------------------------------------------------------------------
print("\nAnti-Cheat")
local function fakePlayer(id: number)
	return { Name = "Tester" .. id, UserId = id, Kicked = false, Kick = function(self)
		self.Kicked = true
	end }
end

test("Remote-Spam wird gedrosselt, extremer Spam führt zum Kick", function()
	local p = fakePlayer(1)
	local allowed = 0
	for _ = 1, 100 do
		if AntiCheat.allow(p :: any, "Roll") then
			allowed += 1
		end
	end
	expect(allowed <= 12, "max Burst, erlaubt: " .. allowed)
	for _ = 1, 400 do
		AntiCheat.allow(p :: any, "Rebirth")
	end
	expect(p.Kicked, "gekickt")
end)

test("Argumente werden geprüft (Typen, Längen, unbekannte Actions)", function()
	local p = fakePlayer(2)
	expect(AntiCheat.validate(p :: any, "UpgradeCharacter", { "c12", 1 }), "gültig")
	expect(not AntiCheat.validate(p :: any, "UpgradeCharacter", { { evil = true } }), "Tabelle statt uid")
	expect(not AntiCheat.validate(p :: any, "UpgradeCharacter", { "c12; drop", 1 }), "kaputte uid")
	expect(not AntiCheat.validate(p :: any, "GiveMeSecret", {}), "unbekannte Action")
	expect(not AntiCheat.validate(p :: any, "Roll", { 1, 2, 3, 4, 5 }), "zu viele Argumente")
	expect(not AntiCheat.validate(p :: any, "BuyDice", { string.rep("a", 200) }), "zu lang")
	expect(not AntiCheat.validate(p :: any, "Debug", { "Cash", 0 / 0 }), "NaN")
end)

test("Server-Autorität: keine Action, mit der der Client Ergebnisse vorgibt", function()
	for name in Net.Actions do
		local lower = string.lower(name)
		expect(not lower:find("give") and not lower:find("setcash") and not lower:find("grant"), name)
	end
end)

test("Cash-Sanity setzt NaN/negatives Cash zurück", function()
	local p = fakePlayer(3)
	local profile = { Cash = 0 / 0, Vault = -5 }
	AntiCheat.sanitize(p :: any, profile, { Cash = 100, Vault = 0 })
	expect(profile.Cash == 100 and profile.Vault == 0, "zurückgesetzt")
end)

test("Mehrere Spieler: Profile sind vollständig getrennt", function()
	local a, rngA = newProfile(30)
	local b = newProfile(31)
	local ctx = ctxFor(rngA)
	for _ = 1, 100 do
		Logic.Rolling.roll(a, ctx)
	end
	Logic.Economy.earn(a, ctx, 1000, "Test")
	expect(b.Stats.TotalRolls == 0 and b.Cash == 0 and next(b.Characters) == nil, "B unberührt")
end)

-- 11) Format ---------------------------------------------------------------------------------
print("\nFormat")
test("Zahlen-/Chance-Format", function()
	expect(Format.cash(1234567) == "$1.23M", Format.cash(1234567))
	expect(Format.oneIn(2500000) == "1 in 2.5M", Format.oneIn(2500000))
	expect(Format.oneIn(2500) == "1 in 2,500", Format.oneIn(2500))
	expect(Format.duration(305) == "5m 05s", Format.duration(305))
end)

print(string.format("\n%d bestanden, %d fehlgeschlagen", passed, failed))
if failed > 0 then
	for _, f in failures do
		print(" - " .. f)
	end
	process.exit(1)
end
