--!strict
-- AnnouncementService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > AnnouncementService
--
-- "Clipbare Momente" für alle sichtbar machen:
--   * Rolls ab Mythic -> Server-Ansage
--   * Secret / Anomaly -> Server-Ansage + Cross-Server (MessagingService)
--   * Double Secret (zweites Secret+ in einer Session)
--   * seltene Mutationen (Golden, Void)
--   * riesige Fishing-Drops (Legendary+)
--   * Max-Level Character
--
-- Client zeigt: "PlayerName rolled THE ENDLESS! 1 in 2,500,000"

local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local FishingConfig = require(Config:WaitForChild("FishingConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))

local Services = script.Parent
local SessionService = require(Services:WaitForChild("SessionService"))

local AnnouncementService = {}

local TOPIC = "VoidDice_Announce_v1"
local JOB_ID = game.JobId
local crossServerReady = false

local function broadcast(data: { [string]: any }, global: boolean)
	SessionService.fireAll("Announcement", data)
	if global and GameConfig.CrossServerAnnouncements and crossServerReady then
		data.JobId = JOB_ID
		task.spawn(function()
			pcall(function()
				MessagingService:PublishAsync(TOPIC, data)
			end)
		end)
	end
end

function AnnouncementService.onRoll(session, result)
	local rarity = RarityConfig.Get(result.Rarity)
	local mutation = MutationConfig.Get(result.Mutation)
	local def = CharacterConfig.ById[result.Id]
	local shouldAnnounce = rarity.Announce ~= "None" or mutation.Announce
	if not shouldAnnounce then
		return
	end
	local double = rarity.Order >= RarityConfig.Order("Secret") and session.SecretRolls >= 2
	broadcast({
		Kind = "Roll",
		Player = session.Player.DisplayName,
		UserId = session.UserId,
		Id = result.Id,
		Name = def and def.DisplayName or result.Id,
		Rarity = result.Rarity,
		Mutation = result.Mutation,
		BaseChance = result.BaseChance,
		Double = double,
	}, rarity.Announce == "Global")
end

function AnnouncementService.onCatch(session, catch)
	if not FishingConfig.AnnounceRarities[catch.Rarity] then
		return
	end
	broadcast({
		Kind = "Catch",
		Player = session.Player.DisplayName,
		UserId = session.UserId,
		LootKind = catch.Kind,
		Id = catch.Id,
		Rarity = catch.Rarity,
		Probability = catch.Probability,
	}, false)
end

function AnnouncementService.onMaxLevel(session, characterId: string)
	local def = CharacterConfig.ById[characterId]
	if not def or RarityConfig.Order(def.Rarity) < RarityConfig.Order("Epic") then
		return
	end
	broadcast({
		Kind = "MaxLevel",
		Player = session.Player.DisplayName,
		UserId = session.UserId,
		Id = characterId,
		Name = def.DisplayName,
		Rarity = def.Rarity,
	}, false)
end

function AnnouncementService.Start()
	-- Fishing/MaxLevel-Events aus den Logic-Contexts mitlesen
	SessionService.onFlush(function(session, ctx)
		for _, event in ctx.events do
			if event.Kind == "Catch" then
				AnnouncementService.onCatch(session, event.Data)
			elseif event.Kind == "MaxLevel" then
				AnnouncementService.onMaxLevel(session, event.Data.Id)
			end
		end
	end)

	if GameConfig.CrossServerAnnouncements then
		task.spawn(function()
			local ok, err = pcall(function()
				MessagingService:SubscribeAsync(TOPIC, function(message)
					local data = message.Data
					if type(data) == "table" and data.JobId ~= JOB_ID then
						data.CrossServer = true
						SessionService.fireAll("Announcement", data)
					end
				end)
			end)
			crossServerReady = ok
			if not ok then
				warn("[AnnouncementService] MessagingService nicht verfügbar (in Studio normal):", err)
			end
		end)
	end
end

return AnnouncementService
