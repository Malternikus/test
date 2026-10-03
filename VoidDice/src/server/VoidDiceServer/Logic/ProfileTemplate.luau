--!strict
-- ProfileTemplate (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > ProfileTemplate
--
-- Aufbau eines gespeicherten Spielerprofils. Neue Felder einfach hier
-- ergänzen: reconcile() füllt sie bei bestehenden Profilen automatisch auf.
--
-- Wichtig für den DataStore: nur Strings als Tabellen-Keys in Maps
-- (Characters "c12", Gear "g7"), keine gemischten Arrays.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local CosmeticConfig = require(Config:WaitForChild("CosmeticConfig"))
local DiceConfig = require(Config:WaitForChild("DiceConfig"))
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local FishingConfig = require(Config:WaitForChild("FishingConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local SeasonConfig = require(Config:WaitForChild("SeasonConfig"))

local ProfileTemplate = {}

ProfileTemplate.Version = 1

local function defaults()
	local cosmeticsOwned = {}
	local equipped = {}
	for kind, id in CosmeticConfig.Defaults do
		cosmeticsOwned[id] = true
		equipped[kind] = id
	end

	return {
		Version = ProfileTemplate.Version,
		Cash = 0,
		Vault = 0,
		Rebirths = 0,

		-- [uid] = { Id, Level, Mutation, Slot?, Fishing?, FishProgress, Gear = {gearUid}, Locked, At }
		Characters = {},
		NextCharUid = 1,
		-- [uid] = { Id, On = charUid? }
		Gear = {},
		NextGearUid = 1,

		Potions = {},
		Boosts = {}, -- [potionId] = Restsekunden
		Relics = {},

		-- [characterId] = { N = Anzahl jemals gerollt, M = { [mutation] = true } }
		Index = {},

		Dice = { Owned = { [DiceConfig.Default] = true }, Equipped = DiceConfig.Default },
		Areas = { [AreaConfig.StartArea] = true },
		FishingWaters = FishingConfig.DefaultWaters,

		Settings = {
			AutoPlace = GameConfig.DefaultAutoPlace,
			AutoDelete = {},
			Music = true,
			SFX = true,
			ReducedEffects = false,
			ShowOthersReveals = true,
		},

		Quests = { Day = -1, List = {}, FirstDay = true },
		Achievements = {},
		Season = { Id = SeasonConfig.Id, Xp = 0, Free = {}, Premium = {} },
		Cosmetics = { Owned = cosmeticsOwned, Equipped = equipped },

		Passes = {},
		Purchases = {}, -- verarbeitete Receipt-Ids (Ringpuffer)

		Tutorial = { Step = 1, Done = false, Rewarded = false },

		Stats = {
			TotalRolls = 0,
			TotalCharactersRolled = 0,
			BestRarity = "",
			BestRarityOrder = 0,
			RarestRoll = 0, -- größtes "1 in X" (Basis-Chance), das je gerollt wurde
			TotalCashEarned = 0,
			CashSpent = 0,
			Rebirths = 0,
			FishingCatches = 0,
			GearObtained = 0,
			CharactersDiscovered = 0,
			Playtime = 0,
			HighestCharacterLevel = 1,
			Upgrades = 0,
			Mutations = 0,
			Sold = 0,
		},

		FirstJoin = 0,
		LastJoin = 0,
	}
end

function ProfileTemplate.new()
	return defaults()
end

-- Fehlende Felder (rekursiv) aus dem Template ergänzen. Bestehende Werte
-- bleiben unangetastet. Maps mit dynamischen Keys werden nicht angefasst.
local DYNAMIC_MAPS = {
	Characters = true,
	Gear = true,
	Potions = true,
	Boosts = true,
	Relics = true,
	Index = true,
	Achievements = true,
	Passes = true,
	Purchases = true,
	AutoDelete = true,
	Owned = true,
	List = true,
	Free = true,
	Premium = true,
	Equipped = false,
}

local function fill(target: { [any]: any }, template: { [any]: any })
	for key, value in template do
		if target[key] == nil then
			target[key] = if type(value) == "table" then table.clone(value) else value
		elseif type(value) == "table" and type(target[key]) == "table" and not DYNAMIC_MAPS[key] then
			fill(target[key], value)
		end
	end
end

function ProfileTemplate.reconcile(profile: { [string]: any })
	fill(profile, defaults())
	-- Defaults bei Cosmetics immer besitzen
	for kind, id in CosmeticConfig.Defaults do
		profile.Cosmetics.Owned[id] = true
		if profile.Cosmetics.Equipped[kind] == nil then
			profile.Cosmetics.Equipped[kind] = id
		end
	end
	profile.Dice.Owned[DiceConfig.Default] = true
	profile.Areas[AreaConfig.StartArea] = true
	if not DiceConfig.Get(profile.Dice.Equipped) or not profile.Dice.Owned[profile.Dice.Equipped] then
		profile.Dice.Equipped = DiceConfig.Default
	end
	if not FishingConfig.WatersById[profile.FishingWaters] then
		profile.FishingWaters = FishingConfig.DefaultWaters
	end
	return profile
end

return ProfileTemplate
