--!strict
-- Fishing (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Fishing
--
-- Rift Fishing. Fortschritt läuft im Server-Tick (nur online). Der Server
-- entscheidet Zeitpunkt und Inhalt jedes Fangs; der Client sieht nur das
-- Ergebnis (Event "Catch").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local FishingConfig = require(Config:WaitForChild("FishingConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local Util = Shared:WaitForChild("Util")
local Stats = require(Util:WaitForChild("Stats"))
local RollMath = require(Util:WaitForChild("RollMath"))
local Odds = require(Util:WaitForChild("Odds"))

local Logic = script.Parent
local Context = require(Logic:WaitForChild("Context"))
local Modifiers = require(Logic:WaitForChild("Modifiers"))
local Economy = require(Logic:WaitForChild("Economy"))
local Items = require(Logic:WaitForChild("Items"))
local Cosmetics = require(Logic:WaitForChild("Cosmetics"))
local QuestTracker = require(Logic:WaitForChild("QuestTracker"))

local Fishing = {}

Fishing.DuplicateCosmeticCashSeconds = 60
Fishing.MaxCatchesPerTick = 3 -- Schutz, falls ein Tick sehr lang war

function Fishing.isUnlocked(profile): boolean
	return profile.Rebirths > 0 or profile.Stats.TotalCashEarned >= GameConfig.FishingUnlockCashEarned
end

function Fishing.fishers(profile): { [number]: string }
	local bySeat = {}
	for uid, char in profile.Characters do
		if char.Fishing then
			bySeat[char.Fishing] = uid
		end
	end
	return bySeat
end

function Fishing.characterStats(profile, char): (number, number)
	local def = CharacterConfig.ById[char.Id]
	if not def then
		return 0, 0
	end
	local power = Stats.fishingPower(def, char.Level)
	local luckPct = 0
	for _, gearUid in char.Gear do
		local item = profile.Gear[gearUid]
		local g = item and GearConfig.Get(item.Id)
		if g then
			power += g.FishingPower or 0
			luckPct += g.FishingLuckPct or 0
		end
	end
	return power, luckPct
end

function Fishing.interval(profile, char, mods: Modifiers.Mods): number
	local power = Fishing.characterStats(profile, char)
	return Stats.catchInterval(power, mods.FishingSpeed)
end

function Fishing.send(profile, ctx: Context.Context, uid: string, mods: Modifiers.Mods): (boolean, string?)
	if not Fishing.isUnlocked(profile) then
		return false, "Fishing is locked"
	end
	local char = profile.Characters[uid]
	if not char then
		return false, "Character not found"
	end
	if char.Fishing then
		return true, nil
	end
	local bySeat = Fishing.fishers(profile)
	local seat = nil
	for i = 1, mods.FishingSlots do
		if not bySeat[i] then
			seat = i
			break
		end
	end
	if not seat then
		return false, "All fishing spots are taken"
	end
	if char.Slot then
		char.Slot = nil
		Context.mark(ctx, "Base")
	end
	char.Fishing = seat
	char.FishProgress = 0
	Context.markChar(ctx, uid)
	Context.mark(ctx, "Fishers")
	return true, nil
end

function Fishing.recall(profile, ctx: Context.Context, uid: string): boolean
	local char = profile.Characters[uid]
	if not char or not char.Fishing then
		return false
	end
	char.Fishing = nil
	char.FishProgress = 0
	Context.markChar(ctx, uid)
	Context.mark(ctx, "Fishers")
	return true
end

function Fishing.setWaters(profile, ctx: Context.Context, watersId: string): (boolean, string?)
	local waters = FishingConfig.WatersById[watersId]
	if not waters then
		return false, "Unknown waters"
	end
	if not profile.Areas[waters.Area] then
		local area = AreaConfig.Get(waters.Area)
		return false, "Unlock " .. (if area then area.DisplayName else waters.Area) .. " first"
	end
	profile.FishingWaters = watersId
	Context.mark(ctx, "FishingWaters")
	return true, nil
end

-- Einen Fang ausführen und gutschreiben
function Fishing.catch(profile, ctx: Context.Context, uid: string, mods: Modifiers.Mods)
	local char = profile.Characters[uid]
	local tbl = Odds.watersTable(profile.FishingWaters) or Odds.watersTable(FishingConfig.DefaultWaters)
	assert(tbl, "Fishing: keine Loot-Tabelle")
	local _, gearLuckPct = Fishing.characterStats(profile, char)
	local luck = mods.FishingLuck * (1 + gearLuckPct / 100)
	local entry, _, probability = RollMath.pick(tbl, luck, ctx.rng:NextNumber())
	local loot = entry.Key

	local result = {
		Uid = uid,
		Kind = loot.Kind,
		Id = loot.Id,
		Rarity = loot.Rarity,
		Probability = probability,
		Amount = 1,
		Cash = nil :: number?,
		Waters = profile.FishingWaters,
	}

	if loot.Kind == "Cash" then
		local amount = Economy.scaledAmount(profile, loot.Seconds or 10, 25)
		Economy.earn(profile, ctx, amount, "Fishing")
		result.Cash = amount
	elseif loot.Kind == "Potion" then
		Items.addPotion(profile, ctx, loot.Id, 1)
	elseif loot.Kind == "Gear" then
		local gearUid, overflowCash = Items.addGear(profile, ctx, loot.Id)
		result.GearUid = gearUid
		result.Cash = overflowCash
	elseif loot.Kind == "Relic" then
		Items.addRelic(profile, ctx, loot.Id)
	elseif loot.Kind == "Cosmetic" then
		if not Cosmetics.grant(profile, ctx, loot.Id) then
			local amount = Economy.scaledAmount(profile, Fishing.DuplicateCosmeticCashSeconds, 500)
			Economy.earn(profile, ctx, amount, "FishingDuplicate")
			result.Cash = amount
			result.Duplicate = true
		end
	end

	profile.Stats.FishingCatches += 1
	Context.mark(ctx, "Stats")
	QuestTracker.track(profile, ctx, "FishingCatches", 1)
	Context.event(ctx, "Catch", result)
	return result
end

function Fishing.tick(profile, ctx: Context.Context, mods: Modifiers.Mods, dt: number)
	for uid, char in profile.Characters do
		if char.Fishing then
			if char.Fishing > mods.FishingSlots then
				Fishing.recall(profile, ctx, uid)
			else
				char.FishProgress = (char.FishProgress or 0) + dt
				local interval = Fishing.interval(profile, char, mods)
				local catches = 0
				while char.FishProgress >= interval and catches < Fishing.MaxCatchesPerTick do
					char.FishProgress -= interval
					catches += 1
					Fishing.catch(profile, ctx, uid, mods)
				end
				if catches >= Fishing.MaxCatchesPerTick then
					char.FishProgress = 0
				end
			end
		end
	end
end

return Fishing
