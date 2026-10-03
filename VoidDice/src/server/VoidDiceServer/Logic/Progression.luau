--!strict
-- Progression (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Progression
--
-- Rebirth, Dice kaufen/ausrüsten und Gebiete freischalten.
--
-- Rebirth setzt NUR Cash-Progression zurück (Cash, Vault, Character-Level).
-- Characters, Gear, Potions, Dice, Gebiete, Index, Cosmetics, Käufe bleiben.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local RebirthConfig = require(Config:WaitForChild("RebirthConfig"))
local DiceConfig = require(Config:WaitForChild("DiceConfig"))
local AreaConfig = require(Config:WaitForChild("AreaConfig"))

local Logic = script.Parent
local Context = require(Logic:WaitForChild("Context"))
local Economy = require(Logic:WaitForChild("Economy"))
local Cosmetics = require(Logic:WaitForChild("Cosmetics"))
local QuestTracker = require(Logic:WaitForChild("QuestTracker"))

local Progression = {}

-- Rebirth --------------------------------------------------------------------------

function Progression.rebirthCost(profile): number
	return RebirthConfig.GetStep(profile.Rebirths + 1).Cost
end

function Progression.canRebirth(profile): boolean
	return profile.Cash >= Progression.rebirthCost(profile)
end

function Progression.rebirth(profile, ctx: Context.Context): (boolean, string?)
	local cost = Progression.rebirthCost(profile)
	if profile.Cash < cost then
		return false, "Not enough cash"
	end
	local nextRebirth = profile.Rebirths + 1
	local step = RebirthConfig.GetStep(nextRebirth)

	profile.Stats.CashSpent += profile.Cash
	profile.Cash = 0
	profile.Vault = 0
	for uid, char in profile.Characters do
		if char.Level ~= 1 then
			char.Level = 1
			Context.markChar(ctx, uid)
		end
	end
	profile.Rebirths = nextRebirth
	profile.Stats.Rebirths = nextRebirth

	if step.Rewards.Title then
		Cosmetics.grant(profile, ctx, step.Rewards.Title)
	end

	Context.mark(ctx, "Cash")
	Context.mark(ctx, "Vault")
	Context.mark(ctx, "Rebirths")
	Context.mark(ctx, "Stats")
	Context.mark(ctx, "Base")
	QuestTracker.track(profile, ctx, "Rebirths", 1)
	Context.event(ctx, "Rebirth", { Rebirths = nextRebirth, Rewards = step.Rewards })
	return true, nil
end

-- Dice -----------------------------------------------------------------------------

function Progression.buyDice(profile, ctx: Context.Context, diceId: string): (boolean, string?)
	local def = DiceConfig.Get(diceId)
	if not def then
		return false, "Unknown dice"
	end
	if profile.Dice.Owned[diceId] then
		return false, "Already owned"
	end
	if not profile.Areas[def.Area] then
		local area = AreaConfig.Get(def.Area)
		return false, "Unlock " .. (if area then area.DisplayName else def.Area) .. " first"
	end
	if not Economy.spend(profile, ctx, def.Cost) then
		return false, "Not enough cash"
	end
	profile.Dice.Owned[diceId] = true
	profile.Dice.Equipped = diceId
	Context.mark(ctx, "Dice")
	Context.event(ctx, "DiceUnlocked", { Id = diceId })
	return true, nil
end

function Progression.equipDice(profile, ctx: Context.Context, diceId: string): (boolean, string?)
	if not DiceConfig.Get(diceId) or not profile.Dice.Owned[diceId] then
		return false, "Dice not owned"
	end
	profile.Dice.Equipped = diceId
	Context.mark(ctx, "Dice")
	return true, nil
end

-- Gebiete --------------------------------------------------------------------------

function Progression.canUnlockArea(profile, areaId: string): (boolean, string?)
	local def = AreaConfig.Get(areaId)
	if not def then
		return false, "Unknown area"
	end
	if profile.Areas[areaId] then
		return false, "Already unlocked"
	end
	for _, other in AreaConfig.List do
		if other.Order == def.Order - 1 and not profile.Areas[other.Id] then
			return false, "Unlock " .. other.DisplayName .. " first"
		end
	end
	if profile.Rebirths < def.RequiredRebirths then
		return false, "Requires Rebirth " .. def.RequiredRebirths
	end
	if profile.Cash < def.UnlockCost then
		return false, "Not enough cash"
	end
	return true, nil
end

function Progression.unlockArea(profile, ctx: Context.Context, areaId: string): (boolean, string?)
	local ok, err = Progression.canUnlockArea(profile, areaId)
	if not ok then
		return false, err
	end
	local def = AreaConfig.Get(areaId) :: AreaConfig.AreaDef
	if not Economy.spend(profile, ctx, def.UnlockCost) then
		return false, "Not enough cash"
	end
	profile.Areas[areaId] = true
	Context.mark(ctx, "Areas")
	Context.event(ctx, "AreaUnlocked", { Id = areaId })
	return true, nil
end

return Progression
