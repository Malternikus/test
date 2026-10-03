--!strict
-- Rolling (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Rolling
--
-- Ein Roll: Character ziehen (RollMath + Luck), Mutation ziehen, Index/Stats/
-- Quests aktualisieren, dann behalten, auto-verkaufen oder auto-platzieren.
-- Der Client erfährt das Ergebnis erst NACHDEM es hier feststeht.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local Util = Shared:WaitForChild("Util")
local RollMath = require(Util:WaitForChild("RollMath"))
local Odds = require(Util:WaitForChild("Odds"))
local Stats = require(Util:WaitForChild("Stats"))

local Logic = script.Parent
local Context = require(Logic:WaitForChild("Context"))
local Modifiers = require(Logic:WaitForChild("Modifiers"))
local Economy = require(Logic:WaitForChild("Economy"))
local Inventory = require(Logic:WaitForChild("Inventory"))
local QuestTracker = require(Logic:WaitForChild("QuestTracker"))

export type RollResult = {
	Id: string,
	Rarity: string,
	Mutation: string,
	Uid: string?,
	IsNew: boolean,
	Probability: number, -- echte Wahrscheinlichkeit bei der aktuellen Luck
	BaseChance: number, -- "1 in X" aus der Config (Luck 1)
	SoldFor: number?, -- gesetzt, wenn automatisch verkauft
	SoldReason: string?,
	ReplacedValue: number?, -- Inventar voll: schwächster freier Character wurde dafür verkauft
	Placed: boolean,
	Luck: number,
}

local Rolling = {}

-- Höchste Rarity, die per Auto Delete gelöscht werden darf (Schutz vor Fehlklicks)
Rolling.MaxAutoDeleteOrder = RarityConfig.Order("Epic")

local function rollMutation(ctx: Context.Context, mods: Modifiers.Mods): (string, number)
	local entries = {}
	for _, m in MutationConfig.List do
		if m.Id ~= MutationConfig.None then
			local luck = mods.MutationLuck * (1 + (mods.Luck - 1) * m.LuckScaling)
			table.insert(entries, { Key = m.Id, Chance = m.Chance, Luck = luck })
		end
	end
	local id, p = RollMath.pickIndependent(entries, MutationConfig.None, ctx.rng:NextNumber())
	return id, p
end

function Rolling.roll(profile, ctx: Context.Context, mods: Modifiers.Mods?): RollResult
	local m = mods or Modifiers.compute(profile)
	local tbl = Odds.characterTable()
	local entry, _, probability = RollMath.pick(tbl, m.Luck, ctx.rng:NextNumber())
	local def = CharacterConfig.ById[entry.Key]
	local rarity = RarityConfig.Get(def.Rarity)
	local mutation = rollMutation(ctx, m)

	local stats = profile.Stats
	stats.TotalRolls += 1
	if rarity.Order > stats.BestRarityOrder then
		stats.BestRarityOrder = rarity.Order
		stats.BestRarity = rarity.Id
	end
	if def.RollChance > stats.RarestRoll and rarity.LuckAffected then
		stats.RarestRoll = def.RollChance
	end
	if mutation ~= MutationConfig.None then
		stats.Mutations += 1
		QuestTracker.track(profile, ctx, "Mutations", 1)
	end
	Context.mark(ctx, "Stats")

	-- Index
	local indexEntry = profile.Index[def.Id]
	local isNew = indexEntry == nil
	if isNew then
		indexEntry = { N = 0, M = {} }
		profile.Index[def.Id] = indexEntry
		stats.CharactersDiscovered += 1
	end
	indexEntry.N += 1
	indexEntry.M[mutation] = true
	Context.mark(ctx, "Index")

	-- Quests
	QuestTracker.track(profile, ctx, "Rolls", 1)
	if rarity.Order >= RarityConfig.Order("Rare") then
		QuestTracker.track(profile, ctx, "RareRolls", 1)
	end
	if rarity.Order >= RarityConfig.Order("Epic") then
		QuestTracker.track(profile, ctx, "EpicRolls", 1)
	end

	local result: RollResult = {
		Id = def.Id,
		Rarity = rarity.Id,
		Mutation = mutation,
		Uid = nil,
		IsNew = isNew,
		Probability = probability,
		BaseChance = def.RollChance,
		SoldFor = nil,
		SoldReason = nil,
		ReplacedValue = nil,
		Placed = false,
		Luck = m.Luck,
	}

	-- Behalten oder automatisch verkaufen?
	local count = Inventory.count(profile)
	local keepOverCap = isNew
		or mutation ~= MutationConfig.None
		or rarity.Order >= RarityConfig.Order(GameConfig.KeepRarityOverCap)
	local autoDelete = profile.Settings.AutoDelete[rarity.Id] == true
		and rarity.Order <= Rolling.MaxAutoDeleteOrder
		and not isNew
		and mutation == MutationConfig.None

	-- Bei vollem Inventar: den wertlosesten freien Character ersetzen, wenn der
	-- neue mehr wert ist. Sonst den neuen verkaufen (außer er ist besonders).
	local sellReason: string? = nil
	if autoDelete then
		sellReason = "AutoDelete"
	elseif count >= GameConfig.InventorySoftCap then
		local worstUid, worstValue = Inventory.worstSellable(profile)
		if worstUid and worstValue <= Stats.sellValue(def, 1, mutation) then
			local ok, value = Inventory.sell(profile, ctx, worstUid)
			if ok then
				result.ReplacedValue = value :: number
			end
		elseif not keepOverCap or count >= GameConfig.InventoryHardCap then
			sellReason = "InventoryFull"
		end
	end

	if sellReason then
		local value = Stats.sellValue(def, 1, mutation)
		Economy.earn(profile, ctx, value, "AutoSell")
		stats.Sold += 1
		result.SoldFor = value
		result.SoldReason = sellReason
	else
		stats.TotalCharactersRolled += 1
		local uid = Inventory.add(profile, ctx, def.Id, mutation)
		result.Uid = uid
		if profile.Settings.AutoPlace then
			result.Placed = Inventory.autoPlace(profile, ctx, uid, m)
		end
	end

	return result
end

return Rolling
