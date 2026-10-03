--!strict
-- Upgrades (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Upgrades
--
-- Character-Level 1–15. Kosten kommen aus Util > Stats (EconomyConfig),
-- der Server berechnet sie immer selbst.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local CharacterConfig = require(Shared:WaitForChild("Config"):WaitForChild("CharacterConfig"))
local Stats = require(Shared:WaitForChild("Util"):WaitForChild("Stats"))

local Logic = script.Parent
local Context = require(Logic:WaitForChild("Context"))
local Economy = require(Logic:WaitForChild("Economy"))
local QuestTracker = require(Logic:WaitForChild("QuestTracker"))

local Upgrades = {}

Upgrades.MaxPerRequest = 15

function Upgrades.cost(profile, uid: string): number?
	local char = profile.Characters[uid]
	local def = char and CharacterConfig.ById[char.Id]
	if not def then
		return nil
	end
	return Stats.upgradeCost(def, char.Level, char.Mutation)
end

-- Upgradet bis zu `times` Mal (solange Cash reicht). Gibt neue Level-Anzahl zurück.
function Upgrades.upgrade(profile, ctx: Context.Context, uid: string, times: number?): (boolean, string | number)
	local char = profile.Characters[uid]
	if not char then
		return false, "Character not found"
	end
	local def = CharacterConfig.ById[char.Id]
	if not def then
		return false, "Unknown character"
	end
	local wanted = math.clamp(math.floor(times or 1), 1, Upgrades.MaxPerRequest)
	local done = 0
	for _ = 1, wanted do
		local cost = Stats.upgradeCost(def, char.Level, char.Mutation)
		if not cost then
			break
		end
		if not Economy.spend(profile, ctx, cost) then
			break
		end
		char.Level += 1
		done += 1
	end
	if done == 0 then
		if char.Level >= def.MaxLevel then
			return false, "Already max level"
		end
		return false, "Not enough cash"
	end
	local stats = profile.Stats
	stats.Upgrades += done
	if char.Level > stats.HighestCharacterLevel then
		stats.HighestCharacterLevel = char.Level
	end
	Context.markChar(ctx, uid)
	Context.mark(ctx, "Stats")
	QuestTracker.track(profile, ctx, "Upgrades", done)
	if char.Level >= def.MaxLevel then
		Context.event(ctx, "MaxLevel", { Uid = uid, Id = char.Id })
	end
	return true, done
end

return Upgrades
