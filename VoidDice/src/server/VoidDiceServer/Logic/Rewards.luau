--!strict
-- Rewards (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Rewards
--
-- Einheitliches Ausschütten von Belohnungen (Quests, Achievements, Season,
-- Produkte). Format:
--   { CashSeconds = n, Cash = n, Potions = { Id = n }, Gear = "Id",
--     Cosmetic = "Id", SeasonXp = n }

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SeasonConfig = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config"):WaitForChild("SeasonConfig"))

local Logic = script.Parent
local Context = require(Logic:WaitForChild("Context"))
local Economy = require(Logic:WaitForChild("Economy"))
local Items = require(Logic:WaitForChild("Items"))
local Cosmetics = require(Logic:WaitForChild("Cosmetics"))

local Rewards = {}

Rewards.MinCashReward = 100

function Rewards.grant(profile, ctx: Context.Context, rewards: { [string]: any }): { [string]: any }
	local granted = {}
	if rewards.CashSeconds and rewards.CashSeconds > 0 then
		local amount = Economy.scaledAmount(profile, rewards.CashSeconds, Rewards.MinCashReward)
		Economy.earn(profile, ctx, amount, "Reward")
		granted.Cash = amount
	end
	if rewards.Cash and rewards.Cash > 0 then
		Economy.earn(profile, ctx, rewards.Cash, "Reward")
		granted.Cash = (granted.Cash or 0) + rewards.Cash
	end
	if rewards.Potions then
		for id, amount in rewards.Potions do
			Items.addPotion(profile, ctx, id, amount)
		end
		granted.Potions = rewards.Potions
	end
	if rewards.Gear then
		Items.addGear(profile, ctx, rewards.Gear)
		granted.Gear = rewards.Gear
	end
	if rewards.Cosmetic then
		Cosmetics.grant(profile, ctx, rewards.Cosmetic)
		granted.Cosmetic = rewards.Cosmetic
	end
	if rewards.SeasonXp and rewards.SeasonXp > 0 and SeasonConfig.Enabled then
		profile.Season.Xp += rewards.SeasonXp
		Context.mark(ctx, "Season")
		granted.SeasonXp = rewards.SeasonXp
	end
	return granted
end

-- Season-Tier-Belohnung ({ Kind = ... }) in das obige Format übersetzen
function Rewards.fromSeasonReward(reward: { [string]: any }): { [string]: any }
	if reward.Kind == "Cash" then
		return { CashSeconds = reward.Seconds }
	elseif reward.Kind == "Potion" then
		return { Potions = { [reward.Id] = reward.Amount or 1 } }
	elseif reward.Kind == "Cosmetic" then
		return { Cosmetic = reward.Id }
	elseif reward.Kind == "Gear" then
		return { Gear = reward.Id }
	end
	return {}
end

return Rewards
