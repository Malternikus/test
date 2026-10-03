--!strict
-- Items (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Items
--
-- Potions (benutzen, Laufzeit), Gear (bekommen, ausrüsten, verkaufen) und
-- Relikte (verkaufen).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local PotionConfig = require(Config:WaitForChild("PotionConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local FishingConfig = require(Config:WaitForChild("FishingConfig"))

local Logic = script.Parent
local Context = require(Logic:WaitForChild("Context"))
local Modifiers = require(Logic:WaitForChild("Modifiers"))
local Economy = require(Logic:WaitForChild("Economy"))
local QuestTracker = require(Logic:WaitForChild("QuestTracker"))

local Items = {}

-- Potions ------------------------------------------------------------------------

function Items.addPotion(profile, ctx: Context.Context, id: string, amount: number)
	if not PotionConfig.Get(id) or amount <= 0 then
		return
	end
	profile.Potions[id] = (profile.Potions[id] or 0) + math.floor(amount)
	Context.mark(ctx, "Potions")
end

function Items.usePotion(profile, ctx: Context.Context, id: string): (boolean, string?)
	local def = PotionConfig.Get(id)
	if not def then
		return false, "Unknown potion"
	end
	local have = profile.Potions[id] or 0
	if have <= 0 then
		return false, "No potion left"
	end
	local remaining = profile.Boosts[id] or 0
	if remaining >= PotionConfig.MaxDuration - 1 then
		return false, "Already at max duration"
	end
	profile.Potions[id] = have - 1
	if profile.Potions[id] <= 0 then
		profile.Potions[id] = nil
	end
	profile.Boosts[id] = math.min(PotionConfig.MaxDuration, remaining + def.Duration)
	Context.mark(ctx, "Potions")
	Context.mark(ctx, "Boosts")
	QuestTracker.track(profile, ctx, "PotionsUsed", 1)
	return true, nil
end

-- Restzeit aller Boosts verringern (läuft nur online)
function Items.tickBoosts(profile, ctx: Context.Context, dt: number)
	local changed = false
	for id, remaining in profile.Boosts do
		local left = remaining - dt
		if left <= 0 then
			profile.Boosts[id] = nil
			Context.event(ctx, "BoostEnded", { Id = id })
		else
			profile.Boosts[id] = left
		end
		changed = true
	end
	if changed then
		Context.mark(ctx, "Boosts")
	end
end

-- Gear ---------------------------------------------------------------------------

function Items.gearCount(profile): number
	local n = 0
	for _ in profile.Gear do
		n += 1
	end
	return n
end

-- Gibt neue Gear-Uid zurück, oder nil + verkaufter Wert wenn Inventar voll
function Items.addGear(profile, ctx: Context.Context, id: string): (string?, number?)
	local def = GearConfig.Get(id)
	if not def then
		return nil, nil
	end
	profile.Stats.GearObtained += 1
	Context.mark(ctx, "Stats")
	if Items.gearCount(profile) >= GameConfig.GearInventoryCap then
		-- Gear-Inventar voll: halber Verkaufswert
		local value = Economy.scaledAmount(profile, def.SellValueSeconds * 0.5, 25)
		Economy.earn(profile, ctx, value, "GearOverflow")
		return nil, value
	end
	local uid = "g" .. profile.NextGearUid
	profile.NextGearUid += 1
	profile.Gear[uid] = { Id = id, On = nil }
	Context.markGear(ctx, uid)
	return uid, nil
end

function Items.unequipGear(profile, ctx: Context.Context, gearUid: string): boolean
	local item = profile.Gear[gearUid]
	if not item or not item.On then
		return false
	end
	local char = profile.Characters[item.On]
	if char then
		local index = table.find(char.Gear, gearUid)
		if index then
			table.remove(char.Gear, index)
		end
		Context.markChar(ctx, item.On)
	end
	item.On = nil
	Context.markGear(ctx, gearUid)
	Context.mark(ctx, "Derived")
	return true
end

function Items.equipGear(profile, ctx: Context.Context, gearUid: string, charUid: string, mods: Modifiers.Mods?): (boolean, string?)
	local item = profile.Gear[gearUid]
	if not item then
		return false, "Gear not found"
	end
	local char = profile.Characters[charUid]
	if not char then
		return false, "Character not found"
	end
	if item.On == charUid then
		return true, nil
	end
	local m = mods or Modifiers.compute(profile)
	if #char.Gear >= m.GearSlots then
		return false, "No free gear slot"
	end
	if item.On then
		Items.unequipGear(profile, ctx, gearUid)
	end
	table.insert(char.Gear, gearUid)
	item.On = charUid
	Context.markGear(ctx, gearUid)
	Context.markChar(ctx, charUid)
	Context.mark(ctx, "Derived")
	QuestTracker.track(profile, ctx, "GearEquips", 1)
	return true, nil
end

function Items.sellGear(profile, ctx: Context.Context, gearUid: string): (boolean, number | string)
	local item = profile.Gear[gearUid]
	if not item then
		return false, "Gear not found"
	end
	local def = GearConfig.Get(item.Id)
	if item.On then
		Items.unequipGear(profile, ctx, gearUid)
	end
	profile.Gear[gearUid] = nil
	Context.markGear(ctx, gearUid)
	local value = if def then Economy.scaledAmount(profile, def.SellValueSeconds, 50) else 0
	Economy.earn(profile, ctx, value, "SellGear")
	return true, value
end

-- Relikte ------------------------------------------------------------------------

function Items.addRelic(profile, ctx: Context.Context, id: string)
	if not FishingConfig.RelicById[id] then
		return
	end
	profile.Relics[id] = (profile.Relics[id] or 0) + 1
	Context.mark(ctx, "Relics")
end

function Items.sellRelic(profile, ctx: Context.Context, id: string): (boolean, number | string)
	local def = FishingConfig.RelicById[id]
	local have = profile.Relics[id] or 0
	if not def or have <= 0 then
		return false, "No relic"
	end
	profile.Relics[id] = if have > 1 then have - 1 else nil
	Context.mark(ctx, "Relics")
	local value = Economy.scaledAmount(profile, def.SellSeconds, 100)
	Economy.earn(profile, ctx, value, "SellRelic")
	return true, value
end

return Items
