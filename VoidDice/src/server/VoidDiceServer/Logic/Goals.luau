--!strict
-- Goals (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > Goals
--
-- Quests einlösen, Achievements prüfen, Season-Tiers einlösen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local QuestConfig = require(Config:WaitForChild("QuestConfig"))
local AchievementConfig = require(Config:WaitForChild("AchievementConfig"))
local SeasonConfig = require(Config:WaitForChild("SeasonConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))

local Logic = script.Parent
local Context = require(Logic:WaitForChild("Context"))
local Rewards = require(Logic:WaitForChild("Rewards"))

local Goals = {}

-- Quests ---------------------------------------------------------------------------

function Goals.claimQuest(profile, ctx: Context.Context, questId: string): (boolean, string?)
	for _, entry in profile.Quests.List do
		if entry.Id == questId then
			local def = QuestConfig.ById[questId]
			if not def then
				return false, "Unknown quest"
			end
			if entry.Claimed then
				return false, "Already claimed"
			end
			if entry.Progress < def.Target then
				return false, "Quest not complete"
			end
			entry.Claimed = true
			Context.mark(ctx, "Quests")
			local granted = Rewards.grant(profile, ctx, def.Rewards)
			Context.event(ctx, "QuestClaimed", { Id = questId, Granted = granted })
			return true, nil
		end
	end
	return false, "Quest not active"
end

-- Achievements ---------------------------------------------------------------------

local function check(profile, def): boolean
	local c = def.Check
	if c.Type == "Stat" then
		return (profile.Stats[c.Stat] or 0) >= c.Value
	elseif c.Type == "BestRarity" then
		return profile.Stats.BestRarityOrder >= RarityConfig.Order(c.Rarity)
	elseif c.Type == "Discovered" then
		return profile.Stats.CharactersDiscovered >= math.min(c.Value, #CharacterConfig.List)
	elseif c.Type == "MaxLevelCharacter" then
		return profile.Stats.HighestCharacterLevel >= CharacterConfig.DefaultMaxLevel
	elseif c.Type == "Mutation" then
		return profile.Stats.Mutations > 0
	end
	return false
end

-- Prüft alle offenen Achievements, schaltet erreichte frei (inkl. Belohnung)
function Goals.evaluateAchievements(profile, ctx: Context.Context): { string }
	local unlocked = {}
	for _, def in AchievementConfig.List do
		if not profile.Achievements[def.Id] and check(profile, def) then
			profile.Achievements[def.Id] = ctx.now
			Context.mark(ctx, "Achievements")
			local granted = Rewards.grant(profile, ctx, def.Rewards)
			Context.event(ctx, "Achievement", { Id = def.Id, Name = def.DisplayName, Granted = granted })
			table.insert(unlocked, def.Id)
		end
	end
	return unlocked
end

-- Season ---------------------------------------------------------------------------

function Goals.ensureSeason(profile, ctx: Context.Context)
	if profile.Season.Id ~= SeasonConfig.Id then
		profile.Season = { Id = SeasonConfig.Id, Xp = 0, Free = {}, Premium = {} }
		Context.mark(ctx, "Season")
	end
end

function Goals.seasonTier(profile): number
	return math.min(#SeasonConfig.Tiers, math.floor(profile.Season.Xp / SeasonConfig.XpPerTier))
end

function Goals.claimSeason(profile, ctx: Context.Context, track: string, tier: number): (boolean, string?)
	if not SeasonConfig.Enabled then
		return false, "No active season"
	end
	if track ~= "Free" and track ~= "Premium" then
		return false, "Unknown track"
	end
	tier = math.floor(tier)
	local def = SeasonConfig.Tiers[tier]
	if not def then
		return false, "Unknown tier"
	end
	if Goals.seasonTier(profile) < tier then
		return false, "Tier not reached"
	end
	if track == "Premium" and not profile.Passes.SeasonPremium then
		return false, "Premium track locked"
	end
	local claimed = profile.Season[track]
	local key = tostring(tier)
	if claimed[key] then
		return false, "Already claimed"
	end
	claimed[key] = true
	Context.mark(ctx, "Season")
	local granted = Rewards.grant(profile, ctx, Rewards.fromSeasonReward(def[track]))
	Context.event(ctx, "SeasonClaimed", { Track = track, Tier = tier, Granted = granted })
	return true, nil
end

-- Hilfsfunktion für Tests/UI
function Goals.hasMutation(profile): boolean
	for _, char in profile.Characters do
		if char.Mutation ~= MutationConfig.None then
			return true
		end
	end
	return false
end

return Goals
