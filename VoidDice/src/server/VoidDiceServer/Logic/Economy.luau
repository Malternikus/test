--!strict
-- Economy (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Economy
--
-- Cash rein, Cash raus. Jede Änderung an profile.Cash läuft über diese
-- Funktionen (validiert gegen NaN/inf/negativ) – das ist die Grundlage der
-- Anti-Cheat-Prüfung "Cash Changes".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local Stats = require(Shared:WaitForChild("Util"):WaitForChild("Stats"))

local Logic = script.Parent
local Context = require(Logic:WaitForChild("Context"))
local Modifiers = require(Logic:WaitForChild("Modifiers"))
local QuestTracker = require(Logic:WaitForChild("QuestTracker"))

local Economy = {}

local function valid(amount: number): boolean
	return type(amount) == "number" and amount == amount and amount ~= math.huge and amount ~= -math.huge and amount >= 0
end

-- Verdientes Cash gutschreiben (zählt für TotalCashEarned)
function Economy.earn(profile, ctx: Context.Context, amount: number, source: string?)
	if not valid(amount) then
		warn("[Economy] ungültiger Betrag verworfen:", amount, source)
		return
	end
	if amount == 0 then
		return
	end
	profile.Cash += amount
	profile.Stats.TotalCashEarned += amount
	Context.mark(ctx, "Cash")
	Context.mark(ctx, "Stats")
end

-- Ausgeben. false wenn nicht genug Cash.
function Economy.spend(profile, ctx: Context.Context, amount: number): boolean
	if not valid(amount) then
		return false
	end
	if profile.Cash + 1e-6 < amount then
		return false
	end
	profile.Cash = math.max(0, profile.Cash - amount)
	profile.Stats.CashSpent += amount
	Context.mark(ctx, "Cash")
	return true
end

-- Gear-Cash-Bonus eines Characters in %
function Economy.gearCashPct(profile, char): number
	local pct = 0
	for _, gearUid in char.Gear do
		local item = profile.Gear[gearUid]
		local def = item and GearConfig.Get(item.Id)
		if def and def.CashPct then
			pct += def.CashPct
		end
	end
	return math.min(pct, EconomyConfig.MaxGearCashPctPerCharacter)
end

-- $/s eines Characters inkl. Gear und globaler Multiplikatoren
function Economy.characterIncome(profile, char, mods: Modifiers.Mods): number
	local def = CharacterConfig.ById[char.Id]
	if not def then
		return 0
	end
	local base = Stats.income(def, char.Level, char.Mutation)
	return base * (1 + Economy.gearCashPct(profile, char) / 100) * mods.CashMultiplier
end

-- Summe $/s aller Characters in der Base
function Economy.incomePerSecond(profile, mods: Modifiers.Mods): number
	local total = 0
	for _, char in profile.Characters do
		if char.Slot then
			total += Economy.characterIncome(profile, char, mods)
		end
	end
	return total
end

function Economy.vaultCapacity(incomePerSecond: number): number
	return math.max(EconomyConfig.VaultMinCapacity, incomePerSecond * EconomyConfig.VaultCapacitySeconds)
end

-- Ein Tick passives Einkommen
function Economy.tick(profile, ctx: Context.Context, mods: Modifiers.Mods, dt: number): number
	local income = Economy.incomePerSecond(profile, mods)
	local amount = income * dt
	if amount <= 0 then
		return income
	end
	if mods.AutoCollect then
		Economy.earn(profile, ctx, amount, "Income")
		QuestTracker.track(profile, ctx, "CashCollected", amount)
	else
		local cap = Economy.vaultCapacity(income)
		local before = profile.Vault
		profile.Vault = math.min(cap, profile.Vault + amount)
		if profile.Vault ~= before then
			Context.mark(ctx, "Vault")
		end
	end
	return income
end

function Economy.collect(profile, ctx: Context.Context): number
	local amount = profile.Vault
	if amount <= 0 then
		return 0
	end
	profile.Vault = 0
	Context.mark(ctx, "Vault")
	Economy.earn(profile, ctx, amount, "Collect")
	QuestTracker.track(profile, ctx, "CashCollected", amount)
	return amount
end

-- Belohnung in "Sekunden aktuelles Einkommen" (Quests, Fishing, Produkte)
function Economy.scaledAmount(profile, seconds: number, minimum: number?): number
	local mods = Modifiers.compute(profile)
	local income = math.max(EconomyConfig.ScaledReward.MinIncomePerSecond, Economy.incomePerSecond(profile, mods))
	return math.max(minimum or 0, math.floor(income * seconds))
end

-- Base Value (Flex): Summe der Power der Characters in der Base
function Economy.baseValue(profile): number
	local total = 0
	for _, char in profile.Characters do
		if char.Slot then
			local def = CharacterConfig.ById[char.Id]
			if def then
				total += Stats.power(def, char.Level, char.Mutation)
			end
		end
	end
	return total
end

-- Punkte für das "Rarest Collection" Leaderboard
function Economy.collectionScore(profile): number
	local score = 0
	for id in profile.Index do
		local def = CharacterConfig.ById[id]
		if def then
			score += EconomyConfig.CollectionPoints[def.Rarity] or 0
		end
	end
	return score
end

return Economy
