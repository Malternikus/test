-- SimCore.luau (Lune-Modul)
--
-- Der simulierte Spieler für simulate.luau und tune.luau. Spielt mit der
-- ECHTEN Server-Logik (Logic-Module) und den echten Configs.
--   * Auto Roll durchgehend, Auto Place an
--   * sammelt alle 10 s ein (bis Auto-Collect freigeschaltet ist)
--   * kauft Upgrades mit guter Amortisation, Dice und Gebiete sobald möglich
--   * Rebirth sobald bezahlbar
--   * schickt Characters zum Fishing, benutzt Potions, rüstet Gear aus,
--     löst Quests ein

local fs = require("@lune/fs")
local process = require("@lune/process")

local Harness = require("../tests/harness")
local ROOT = (process.cwd :: string):gsub("/tools/?$", ""):gsub("/$", "")
if not fs.isFile(ROOT .. "/default.project.json") then
	ROOT = ROOT .. "/VoidDice"
end
local h = Harness.load(ROOT)

local Logic = h.requirePath("ServerScriptService.VoidDiceServer.Logic")
local Config = "ReplicatedStorage.VoidDice.Config."
local CharacterConfig = h.requirePath(Config .. "CharacterConfig")
local RarityConfig = h.requirePath(Config .. "RarityConfig")
local DiceConfig = h.requirePath(Config .. "DiceConfig")
local AreaConfig = h.requirePath(Config .. "AreaConfig")
local GearConfig = h.requirePath(Config .. "GearConfig")
local PotionConfig = h.requirePath(Config .. "PotionConfig")
local Stats = h.requirePath("ReplicatedStorage.VoidDice.Util.Stats")

local Context = Logic.Context

-- Cash-Quellen mitschreiben (für den Report)
local currentSources: { [string]: number } = {}
local originalEarn = Logic.Economy.earn
Logic.Economy.earn = function(profile, ctx, amount, source)
	local key = source or "?"
	currentSources[key] = (currentSources[key] or 0) + amount
	return originalEarn(profile, ctx, amount, source)
end

local CHECKPOINTS: { number } = { 1, 2, 3, 5, 8, 10, 15, 20, 30, 45, 60, 90, 120, 180 }

-- Spielerverhalten -------------------------------------------------------------
local BOT = {
	CollectEvery = 10, -- Sekunden
	ShopEvery = 5, -- wie oft der Bot Käufe prüft
	MaxPaybackSeconds = 240, -- Upgrades kaufen, wenn sie sich so schnell lohnen
	ReactionSeconds = 3, -- Verzögerung bis Rebirth/Kauf nach Erreichen
}

local function newCtx(now: number, rng)
	return Context.new({ now = now, rng = rng, userId = 12345 })
end

local function upgradeCandidates(profile, mods)
	local list = {}
	for uid, char in profile.Characters do
		if char.Slot then
			local def = CharacterConfig.ById[char.Id]
			local cost = Stats.upgradeCost(def, char.Level, char.Mutation)
			if cost then
				local now = Stats.income(def, char.Level, char.Mutation)
				local nextIncome = Stats.income(def, char.Level + 1, char.Mutation)
				local gain = (nextIncome - now) * (1 + Logic.Economy.gearCashPct(profile, char) / 100) * mods.CashMultiplier
				table.insert(list, { uid = uid, cost = cost, payback = cost / math.max(1e-9, gain) })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.payback < b.payback
	end)
	return list
end

local function equipGear(profile, ctx, mods)
	for gearUid, item in profile.Gear do
		if not item.On then
			local def = GearConfig.Get(item.Id)
			local isFishing = (def.FishingPower or 0) > 0 or (def.FishingLuckPct or 0) > 0
			local isCash = (def.CashPct or 0) > 0 or (def.LuckPct or 0) > 0
			local best, bestScore = nil, -1
			for uid, char in profile.Characters do
				if #char.Gear < mods.GearSlots then
					local score
					if isCash and char.Slot then
						score = Logic.Economy.characterIncome(profile, char, mods)
					elseif isFishing and char.Fishing then
						score = 1
					end
					if score and score > bestScore then
						best, bestScore = uid, score
					end
				end
			end
			if best then
				Logic.Items.equipGear(profile, ctx, gearUid, best, mods)
			end
		end
	end
end

local function manageFishing(profile, ctx, mods)
	if not Logic.Fishing.isUnlocked(profile) then
		return
	end
	-- beste Fishing-Power unter den Characters, die nicht in der Base stehen
	local fishers = Logic.Fishing.fishers(profile)
	local count = 0
	for _ in fishers do
		count += 1
	end
	if count >= mods.FishingSlots then
		return
	end
	local candidates = {}
	for uid, char in profile.Characters do
		if not char.Slot and not char.Fishing then
			local def = CharacterConfig.ById[char.Id]
			table.insert(candidates, { uid = uid, fp = def.BaseFishingPower })
		end
	end
	table.sort(candidates, function(a, b)
		return a.fp > b.fp
	end)
	for i = 1, math.min(#candidates, mods.FishingSlots - count) do
		Logic.Fishing.send(profile, ctx, candidates[i].uid, mods)
	end
	-- bestes freigeschaltetes Gewässer
	local bestArea, bestOrder = nil, 0
	for areaId in profile.Areas do
		local area = AreaConfig.Get(areaId)
		if area.Order > bestOrder then
			bestArea, bestOrder = areaId, area.Order
		end
	end
	local FishingConfig = h.requirePath(Config .. "FishingConfig")
	local waters = FishingConfig.WatersByArea[bestArea]
	if waters and profile.FishingWaters ~= waters.Id then
		Logic.Fishing.setWaters(profile, ctx, waters.Id)
	end
end

local function usePotions(profile, ctx)
	for id, n in profile.Potions do
		local def = PotionConfig.Get(id)
		if n > 0 and (profile.Boosts[id] or 0) < 60 and def.Effect ~= "MutationLuck" then
			Logic.Items.usePotion(profile, ctx, id)
		end
	end
end

local function shop(profile, ctx, t, log)
	local mods = Logic.Modifiers.compute(profile)
	-- 1) Rebirth
	if Logic.Progression.canRebirth(profile) then
		local ok = Logic.Progression.rebirth(profile, ctx)
		if ok then
			table.insert(log.rebirths, t)
			return
		end
	end
	-- 2) Gebiete und Dice
	for _, area in AreaConfig.List do
		if not profile.Areas[area.Id] and Logic.Progression.canUnlockArea(profile, area.Id) then
			if Logic.Progression.unlockArea(profile, ctx, area.Id) then
				log.areas[area.Id] = t
			end
		end
	end
	for _, dice in DiceConfig.List do
		if not profile.Dice.Owned[dice.Id] and profile.Areas[dice.Area] and profile.Cash >= dice.Cost then
			if Logic.Progression.buyDice(profile, ctx, dice.Id) then
				log.dice[dice.Id] = t
			end
		end
	end
	-- 3) Upgrades: nicht kaufen, wenn Rebirth fast bezahlbar ist
	local rebirthCost = Logic.Progression.rebirthCost(profile)
	local income = Logic.Economy.incomePerSecond(profile, mods)
	local secondsToRebirth = (rebirthCost - profile.Cash) / math.max(1, income)
	for _ = 1, 30 do
		local list = upgradeCandidates(profile, mods)
		local best = list[1]
		if not best then
			break
		end
		local limit = math.min(BOT.MaxPaybackSeconds, math.max(30, secondsToRebirth))
		if best.payback > limit or profile.Cash < best.cost then
			break
		end
		Logic.Upgrades.upgrade(profile, ctx, best.uid, 1)
	end
	-- 4) Quests einlösen
	for _, q in profile.Quests.List do
		Logic.Goals.claimQuest(profile, ctx, q.Id)
	end
	usePotions(profile, ctx)
	equipGear(profile, ctx, mods)
	manageFishing(profile, ctx, mods)
end

local function bestPlaced(profile)
	local best, bestOrder = nil, -1
	for _, char in profile.Characters do
		local def = CharacterConfig.ById[char.Id]
		local order = RarityConfig.Order(def.Rarity)
		if order > bestOrder then
			best, bestOrder = def, order
		end
	end
	return best
end

local function runOnce(seed: number, MINUTES: number)
	local rng = Harness.Random.new(seed)
	local profile = Logic.ProfileTemplate.new()
	local t0 = 1_800_000_000
	Logic.onLoad(profile, newCtx(t0, rng))

	currentSources = {}
	local log = { sources = currentSources, sources5 = nil, rebirths = {}, areas = {}, dice = {}, firstRarity = {}, checkpoints = {}, firstUpgrade = nil, fishingUnlocked = nil, firstGear = nil }
	local rollBudget = 0
	local nextCheckpoint = 1
	local totalSeconds = MINUTES * 60

	for t = 1, totalSeconds do
		local now = t0 + t
		local ctx = newCtx(now, rng)
		local mods = Logic.Modifiers.compute(profile)
		rollBudget += 1 / mods.RollCooldown
		while rollBudget >= 1 do
			rollBudget -= 1
			local r = Logic.Rolling.roll(profile, ctx, mods)
			if not log.firstRarity[r.Rarity] then
				log.firstRarity[r.Rarity] = t
			end
			-- große Reveals pausieren Auto Roll (wie auf dem Server)
			local pause = RarityConfig.Get(r.Rarity).RevealSeconds
			if pause > 0 then
				rollBudget -= pause / mods.RollCooldown
			end
		end
		Logic.tick(profile, ctx, 1)
		if t % BOT.CollectEvery == 0 then
			Logic.Economy.collect(profile, ctx)
		end
		if t % BOT.ShopEvery == 0 then
			shop(profile, ctx, t, log)
		end
		if not log.firstUpgrade and profile.Stats.Upgrades > 0 then
			log.firstUpgrade = t
		end
		if not log.fishingUnlocked and Logic.Fishing.isUnlocked(profile) then
			log.fishingUnlocked = t
		end
		if not log.firstGear and profile.Stats.GearObtained > 0 then
			log.firstGear = t
		end
		if t == 300 then
			log.sources5 = table.clone(currentSources)
		end
		local cp = CHECKPOINTS[nextCheckpoint]
		if cp and t == cp * 60 then
			local m = Logic.Modifiers.compute(profile)
			local best = bestPlaced(profile)
			log.checkpoints[cp] = {
				income = Logic.Economy.incomePerSecond(profile, m),
				cash = profile.Cash + profile.Vault,
				earned = profile.Stats.TotalCashEarned,
				luck = m.Luck,
				rebirths = profile.Rebirths,
				rolls = profile.Stats.TotalRolls,
				discovered = profile.Stats.CharactersDiscovered,
				best = best and best.Rarity or "-",
				dice = profile.Dice.Equipped,
				catches = profile.Stats.FishingCatches,
				slots = m.BaseSlots,
			}
			nextCheckpoint += 1
		end
	end
	return log
end

return {
	run = runOnce,
	Checkpoints = CHECKPOINTS,
	Bot = BOT,
	h = h,
	ROOT = ROOT,
	Logic = Logic,
}
