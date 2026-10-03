--!strict
-- Modifiers (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Modifiers
--
-- Berechnet alle Multiplikatoren eines Spielers aus seinem Profil:
-- Luck, Cash, Roll Speed, Fishing, Slots. Ergebnis inkl. Aufschlüsselung,
-- damit die UI exakt anzeigen kann, woher die Werte kommen.
--
-- Luck = DiceLuck * (1 + Summe aller %-Boni) * (2 mit 2X LUCK Pass)
-- Cash = (1 + Summe aller %-Boni) * (2 mit 2X CASH Pass)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local DiceConfig = require(Config:WaitForChild("DiceConfig"))
local RebirthConfig = require(Config:WaitForChild("RebirthConfig"))
local PotionConfig = require(Config:WaitForChild("PotionConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local MonetizationConfig = require(Config:WaitForChild("MonetizationConfig"))

export type Mods = {
	Luck: number,
	LuckBreakdown: { { Label: string, Value: number, Kind: string } },
	CashMultiplier: number,
	CashBreakdown: { { Label: string, Value: number, Kind: string } },
	RollSpeed: number,
	RollCooldown: number,
	FishingLuck: number,
	FishingSpeed: number,
	MutationLuck: number,
	BaseSlots: number,
	FishingSlots: number,
	GearSlots: number,
	AutoCollect: boolean,
}

local Modifiers = {}

local rebirthCache: { [number]: any } = {}

local function accumulateRebirths(rebirths: number)
	local cached = rebirthCache[rebirths]
	if not cached then
		cached = RebirthConfig.Accumulate(rebirths)
		rebirthCache[rebirths] = cached
	end
	return cached
end

function Modifiers.boostTotals(profile): { [string]: number }
	local totals = { Luck = 0, Cash = 0, RollSpeed = 0, FishingLuck = 0, FishingSpeed = 0, MutationLuck = 0 }
	for potionId, remaining in profile.Boosts do
		local def = PotionConfig.Get(potionId)
		if def and remaining > 0 then
			totals[def.Effect] = (totals[def.Effect] or 0) + def.Amount
		end
	end
	return totals
end

-- Summe der globalen Gear-Luck aller Characters, die in der Base stehen
function Modifiers.gearLuckPct(profile): number
	local total = 0
	for _, char in profile.Characters do
		if char.Slot then
			for _, gearUid in char.Gear do
				local item = profile.Gear[gearUid]
				local def = item and GearConfig.Get(item.Id)
				if def and def.LuckPct then
					total += def.LuckPct
				end
			end
		end
	end
	return math.min(total, EconomyConfig.MaxGearLuckPct)
end

function Modifiers.discovered(profile): number
	local n = 0
	for _ in profile.Index do
		n += 1
	end
	return n
end

function Modifiers.compute(profile): Mods
	local passes = profile.Passes
	local rebirth = accumulateRebirths(profile.Rebirths)
	local dice = DiceConfig.Get(profile.Dice.Equipped) or DiceConfig.Get(DiceConfig.Default)
	assert(dice, "Default-Dice fehlt")
	local boosts = Modifiers.boostTotals(profile)
	local effects = MonetizationConfig.PassEffects

	-- Luck --------------------------------------------------------------------
	local luckBreakdown = {}
	table.insert(luckBreakdown, { Label = dice.DisplayName, Value = dice.Luck, Kind = "x" })
	local luckPct = 0
	local function addLuck(label: string, pct: number)
		if pct ~= 0 then
			luckPct += pct
			table.insert(luckBreakdown, { Label = label, Value = pct, Kind = "%" })
		end
	end
	addLuck("Rebirths", rebirth.LuckPct)
	addLuck("Potions", boosts.Luck * 100)
	addLuck("Gear", Modifiers.gearLuckPct(profile))
	addLuck("Index", math.min(25, Modifiers.discovered(profile) * EconomyConfig.IndexLuckPctPerDiscovery))
	if passes.VIP then
		addLuck("VIP", effects.VIP.LuckPct)
	end
	local luck = dice.Luck * (1 + luckPct / 100)
	if passes.DoubleLuck then
		luck *= effects.DoubleLuck.LuckMultiplier
		table.insert(luckBreakdown, { Label = "2X LUCK", Value = effects.DoubleLuck.LuckMultiplier, Kind = "x" })
	end
	luck = math.clamp(luck, 1, EconomyConfig.MaxLuck)

	-- Cash --------------------------------------------------------------------
	local cashBreakdown = {}
	local cashPct = 0
	local function addCash(label: string, pct: number)
		if pct ~= 0 then
			cashPct += pct
			table.insert(cashBreakdown, { Label = label, Value = pct, Kind = "%" })
		end
	end
	addCash("Rebirths", rebirth.CashPct)
	addCash("Potions", boosts.Cash * 100)
	if passes.VIP then
		addCash("VIP", effects.VIP.CashPct)
	end
	local cash = 1 + cashPct / 100
	if passes.DoubleCash then
		cash *= effects.DoubleCash.CashMultiplier
		table.insert(cashBreakdown, { Label = "2X CASH", Value = effects.DoubleCash.CashMultiplier, Kind = "x" })
	end
	cash = math.min(cash, EconomyConfig.MaxCashMultiplier)

	-- Roll Speed ----------------------------------------------------------------
	local speedPct = boosts.RollSpeed * 100
	if passes.FastRoll then
		speedPct += effects.FastRoll.RollSpeedPct
	end
	local rollSpeed = dice.RollSpeed * (1 + speedPct / 100)
	local cooldown = math.max(GameConfig.MinRollCooldown, GameConfig.RollCooldown / rollSpeed)

	-- Slots -------------------------------------------------------------------------
	local baseSlots = GameConfig.StartBaseSlots + rebirth.BaseSlots
	if passes.ExtraSlots then
		baseSlots += effects.ExtraSlots.BaseSlots
	end

	return {
		Luck = luck,
		LuckBreakdown = luckBreakdown,
		CashMultiplier = cash,
		CashBreakdown = cashBreakdown,
		RollSpeed = rollSpeed,
		RollCooldown = cooldown,
		FishingLuck = 1 + boosts.FishingLuck,
		FishingSpeed = 1 + boosts.FishingSpeed,
		MutationLuck = 1 + boosts.MutationLuck,
		BaseSlots = math.min(GameConfig.MaxBaseSlots, baseSlots),
		FishingSlots = math.min(GameConfig.MaxFishingSlots, GameConfig.StartFishingSlots + rebirth.FishingSlots),
		GearSlots = math.min(GameConfig.MaxGearSlots, GameConfig.StartGearSlots + rebirth.GearSlots),
		AutoCollect = rebirth.AutoCollect,
	}
end

return Modifiers
