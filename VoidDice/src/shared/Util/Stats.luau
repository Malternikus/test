--!strict
-- Stats (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Util > Stats
--
-- Alle Formeln für Character-Werte an EINER Stelle (Server, Client, Simulation).
-- Die Zahlen kommen aus EconomyConfig / RarityConfig / MutationConfig.

local Config = script.Parent.Parent:WaitForChild("Config")
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local FishingConfig = require(Config:WaitForChild("FishingConfig"))

local Stats = {}

function Stats.levelMultiplier(level: number): number
	local list = EconomyConfig.LevelIncomeMultiplier
	return list[math.clamp(level, 1, #list)]
end

-- $/s eines Characters ohne globale Multiplikatoren und ohne Gear
function Stats.income(def: any, level: number, mutationId: string?): number
	local mutation = MutationConfig.Get(mutationId)
	return def.BaseMoneyPerSecond * Stats.levelMultiplier(level) * mutation.MoneyMultiplier
end

-- Kosten für das nächste Level, nil = schon Max-Level
function Stats.upgradeCost(def: any, level: number, mutationId: string?): number?
	if level >= def.MaxLevel then
		return nil
	end
	local seconds = EconomyConfig.UpgradeCostSeconds[level]
	if not seconds then
		return nil
	end
	local mutation = MutationConfig.Get(mutationId)
	local rarity = RarityConfig.Get(def.Rarity)
	local cost = def.BaseMoneyPerSecond * mutation.MoneyMultiplier * seconds * rarity.UpgradeCostFactor
	return math.max(EconomyConfig.MinUpgradeCost, math.floor(cost))
end

function Stats.power(def: any, level: number, mutationId: string?): number
	local mutation = MutationConfig.Get(mutationId)
	local rarity = RarityConfig.Get(def.Rarity)
	return math.floor(def.BasePower * (1 + EconomyConfig.PowerPerLevel * (level - 1)) * mutation.PowerMultiplier * rarity.PowerMultiplier)
end

function Stats.fishingPower(def: any, level: number): number
	return def.BaseFishingPower * (1 + EconomyConfig.FishingPowerPerLevel * (level - 1))
end

function Stats.sellValue(def: any, level: number, mutationId: string?): number
	local rarity = RarityConfig.Get(def.Rarity)
	local levelBonus = 1 + EconomyConfig.SellLevelBonus * (level - 1) / math.max(1, def.MaxLevel - 1)
	return math.floor(Stats.income(def, 1, mutationId) * rarity.SellSeconds * levelBonus)
end

-- Sekunden pro Fang
function Stats.catchInterval(fishingPower: number, speedMultiplier: number): number
	local seconds = FishingConfig.BaseCatchSeconds / (1 + fishingPower / FishingConfig.PowerScale)
	seconds /= math.max(0.1, speedMultiplier)
	return math.max(FishingConfig.MinCatchSeconds, seconds)
end

return Stats
