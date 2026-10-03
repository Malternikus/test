--!strict
-- Inventory (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Inventory
--
-- Besitz von Characters: hinzufügen, entfernen, in die Base stellen,
-- verkaufen, sperren. Ein Character ist immer genau in EINEM Zustand:
--   Inventar (Slot = nil, Fishing = nil)
--   Base     (Slot = 1..BaseSlots)
--   Fishing  (Fishing = Sitzplatz 1..FishingSlots)
--
-- Vorbereitung Steal/Raid: Inventory.transfer() verschiebt einen Character
-- atomar zwischen zwei geladenen Profilen (beide liegen auf demselben Server).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local Stats = require(Shared:WaitForChild("Util"):WaitForChild("Stats"))

local Logic = script.Parent
local Context = require(Logic:WaitForChild("Context"))
local Modifiers = require(Logic:WaitForChild("Modifiers"))
local Economy = require(Logic:WaitForChild("Economy"))

local Inventory = {}

function Inventory.count(profile): number
	local n = 0
	for _ in profile.Characters do
		n += 1
	end
	return n
end

function Inventory.add(profile, ctx: Context.Context, id: string, mutation: string?, level: number?): string
	local uid = "c" .. profile.NextCharUid
	profile.NextCharUid += 1
	profile.Characters[uid] = {
		Id = id,
		Level = level or 1,
		Mutation = mutation or MutationConfig.None,
		Slot = nil,
		Fishing = nil,
		FishProgress = 0,
		Gear = {},
		Locked = false,
		At = ctx.now,
	}
	Context.markChar(ctx, uid)
	return uid
end

-- Entfernt einen Character. Ausgerüstetes Gear geht zurück ins Gear-Inventar.
function Inventory.remove(profile, ctx: Context.Context, uid: string)
	local char = profile.Characters[uid]
	if not char then
		return
	end
	for _, gearUid in char.Gear do
		local item = profile.Gear[gearUid]
		if item then
			item.On = nil
			Context.markGear(ctx, gearUid)
		end
	end
	profile.Characters[uid] = nil
	Context.markChar(ctx, uid)
end

function Inventory.placed(profile): { [number]: string }
	local bySlot = {}
	for uid, char in profile.Characters do
		if char.Slot then
			bySlot[char.Slot] = uid
		end
	end
	return bySlot
end

function Inventory.freeSlot(profile, mods: Modifiers.Mods): number?
	local bySlot = Inventory.placed(profile)
	for slot = 1, mods.BaseSlots do
		if not bySlot[slot] then
			return slot
		end
	end
	return nil
end

function Inventory.place(profile, ctx: Context.Context, uid: string, mods: Modifiers.Mods, slot: number?): (boolean, string?)
	local char = profile.Characters[uid]
	if not char then
		return false, "Character not found"
	end
	if char.Slot then
		return true, nil
	end
	local target = slot or Inventory.freeSlot(profile, mods)
	if not target then
		return false, "Base is full"
	end
	if char.Fishing then
		char.Fishing = nil
		char.FishProgress = 0
	end
	char.Slot = target
	Context.markChar(ctx, uid)
	Context.mark(ctx, "Base")
	return true, nil
end

function Inventory.unplace(profile, ctx: Context.Context, uid: string): boolean
	local char = profile.Characters[uid]
	if not char or not char.Slot then
		return false
	end
	char.Slot = nil
	Context.markChar(ctx, uid)
	Context.mark(ctx, "Base")
	return true
end

-- Neuer Character: freien Slot nehmen oder den schwächsten ersetzen,
-- wenn der neue mehr $/s bringt.
function Inventory.autoPlace(profile, ctx: Context.Context, uid: string, mods: Modifiers.Mods): boolean
	local char = profile.Characters[uid]
	if not char or char.Slot or char.Fishing then
		return false
	end
	local free = Inventory.freeSlot(profile, mods)
	if free then
		Inventory.place(profile, ctx, uid, mods, free)
		return true
	end
	local newIncome = Economy.characterIncome(profile, char, mods)
	local weakestUid, weakestIncome = nil, math.huge
	for otherUid, other in profile.Characters do
		if other.Slot then
			local inc = Economy.characterIncome(profile, other, mods)
			if inc < weakestIncome then
				weakestUid, weakestIncome = otherUid, inc
			end
		end
	end
	if weakestUid and newIncome > weakestIncome then
		local slot = profile.Characters[weakestUid].Slot
		Inventory.unplace(profile, ctx, weakestUid)
		Inventory.place(profile, ctx, uid, mods, slot)
		return true
	end
	return false
end

-- Stellt die besten Characters (nach aktuellem $/s) in die Base.
-- Fischende Characters bleiben am Pond.
function Inventory.placeBest(profile, ctx: Context.Context, mods: Modifiers.Mods)
	local candidates = {}
	for uid, char in profile.Characters do
		if not char.Fishing then
			table.insert(candidates, { uid = uid, income = Economy.characterIncome(profile, char, mods) })
		end
	end
	table.sort(candidates, function(a, b)
		if a.income == b.income then
			return a.uid < b.uid
		end
		return a.income > b.income
	end)
	local keep = {}
	for i = 1, math.min(mods.BaseSlots, #candidates) do
		keep[candidates[i].uid] = true
	end
	-- erst raus, dann rein (stabile Slot-Nummern für die, die bleiben)
	for uid, char in profile.Characters do
		if char.Slot and not keep[uid] then
			Inventory.unplace(profile, ctx, uid)
		end
	end
	for uid in keep do
		if not profile.Characters[uid].Slot then
			Inventory.place(profile, ctx, uid, mods)
		end
	end
end

-- Slots außerhalb des erlaubten Bereichs freimachen (z. B. Pass entfernt)
function Inventory.validateSlots(profile, ctx: Context.Context, mods: Modifiers.Mods)
	local seen = {}
	for uid, char in profile.Characters do
		if char.Slot then
			if char.Slot > mods.BaseSlots or char.Slot < 1 or seen[char.Slot] then
				char.Slot = nil
				Context.markChar(ctx, uid)
			else
				seen[char.Slot] = true
			end
		end
	end
end

function Inventory.sellValue(profile, uid: string): number
	local char = profile.Characters[uid]
	local def = char and CharacterConfig.ById[char.Id]
	if not def then
		return 0
	end
	return Stats.sellValue(def, char.Level, char.Mutation)
end

-- Der am wenigsten werte "freie" Character (nicht gesperrt, nicht in der
-- Base, nicht beim Fishing, ohne Mutation). Wird bei vollem Inventar ersetzt.
function Inventory.worstSellable(profile): (string?, number)
	local worstUid, worstValue = nil, math.huge
	for uid, char in profile.Characters do
		if not char.Locked and not char.Slot and not char.Fishing and char.Mutation == MutationConfig.None then
			local value = Inventory.sellValue(profile, uid)
			if value < worstValue then
				worstUid, worstValue = uid, value
			end
		end
	end
	return worstUid, worstValue
end

function Inventory.sell(profile, ctx: Context.Context, uid: string): (boolean, number | string)
	local char = profile.Characters[uid]
	if not char then
		return false, "Character not found"
	end
	if char.Locked then
		return false, "Character is locked"
	end
	local value = Inventory.sellValue(profile, uid)
	Inventory.remove(profile, ctx, uid)
	Economy.earn(profile, ctx, value, "Sell")
	profile.Stats.Sold += 1
	return true, value
end

-- Alle "freien" Characters einer Rarity verkaufen: nicht gesperrt, nicht in
-- der Base, nicht beim Fishing, ohne Mutation.
function Inventory.sellRarity(profile, ctx: Context.Context, rarityId: string): (number, number)
	if not RarityConfig.ById[rarityId] then
		return 0, 0
	end
	local count, total = 0, 0
	local uids = {}
	for uid, char in profile.Characters do
		local def = CharacterConfig.ById[char.Id]
		if def and def.Rarity == rarityId and not char.Locked and not char.Slot and not char.Fishing
			and char.Mutation == MutationConfig.None then
			table.insert(uids, uid)
		end
	end
	for _, uid in uids do
		local ok, value = Inventory.sell(profile, ctx, uid)
		if ok then
			count += 1
			total += value :: number
		end
	end
	return count, total
end

function Inventory.setLocked(profile, ctx: Context.Context, uid: string, locked: boolean): boolean
	local char = profile.Characters[uid]
	if not char then
		return false
	end
	char.Locked = locked
	Context.markChar(ctx, uid)
	return true
end

-- Steal/Raid-Vorbereitung (noch nicht ans Netz angeschlossen):
-- verschiebt einen Character zwischen zwei Profilen. Gear bleibt beim
-- ursprünglichen Besitzer. Gesperrte Characters können nicht verschoben werden.
function Inventory.transfer(fromProfile, fromCtx: Context.Context, toProfile, toCtx: Context.Context, uid: string): string?
	local char = fromProfile.Characters[uid]
	if not char or char.Locked then
		return nil
	end
	local id, mutation, level = char.Id, char.Mutation, char.Level
	Inventory.remove(fromProfile, fromCtx, uid)
	return Inventory.add(toProfile, toCtx, id, mutation, level)
end

return Inventory
