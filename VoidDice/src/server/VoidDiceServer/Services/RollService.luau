--!strict
-- RollService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > RollService
--
-- Manuelles Rollen und Auto Roll. Der Server entscheidet alles:
--   * Cooldown (Roll Speed) wird mit Server-Uhr geprüft
--   * Auto Roll läuft komplett auf dem Server (kein Remote-Spam nötig)
--   * Nach großen Reveals (Legendary+) pausiert Auto Roll kurz
--     (RarityConfig.RevealSeconds), damit die Animation nicht überdeckt wird

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local Services = script.Parent
local SessionService = require(Services:WaitForChild("SessionService"))
local AnnouncementService = require(Services:WaitForChild("AnnouncementService"))

local RollService = {}

local function doRoll(session: SessionService.Session, manual: boolean): boolean
	local now = os.clock()
	local tolerance = if manual then GameConfig.RollCooldownTolerance else 0
	if now + tolerance < session.NextRollAt then
		return false
	end
	SessionService.run(session, function(profile, ctx)
		local mods = Logic.Modifiers.compute(profile)
		local result = Logic.Rolling.roll(profile, ctx, mods)
		local rarity = RarityConfig.Get(result.Rarity)
		session.NextRollAt = math.max(now, session.NextRollAt) + mods.RollCooldown + rarity.RevealSeconds

		if RarityConfig.Order(result.Rarity) >= RarityConfig.Order("Secret") then
			session.SecretRolls += 1
		end
		local def = CharacterConfig.ById[result.Id]
		SessionService.fire(session, "Roll", {
			Id = result.Id,
			Rarity = result.Rarity,
			Mutation = result.Mutation,
			Uid = result.Uid,
			IsNew = result.IsNew,
			Probability = result.Probability,
			BaseChance = result.BaseChance,
			SoldFor = result.SoldFor,
			SoldReason = result.SoldReason,
			ReplacedValue = result.ReplacedValue,
			Placed = result.Placed,
			Luck = result.Luck,
			Cooldown = mods.RollCooldown,
			Auto = not manual,
			Income = def and def.BaseMoneyPerSecond or 0,
		})
		AnnouncementService.onRoll(session, result)
	end)
	return true
end

function RollService.Start()
	SessionService.registerAction("Roll", function(session)
		if not doRoll(session, true) then
			return false, nil -- zu schnell: still ignorieren
		end
		return true
	end)

	SessionService.registerAction("SetAutoRoll", function(session, _ctx, enabled: boolean)
		if enabled and not GameConfig.AutoRollUnlocked then
			return false, "Auto Roll is locked"
		end
		session.AutoRoll = enabled
		SessionService.sendSession(session)
		return true
	end)

	-- Auto Roll: jeden Frame prüfen, wer dran ist
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, session in SessionService.all() do
			if session.AutoRoll and not session.Removing and now >= session.NextRollAt then
				doRoll(session, false)
			end
		end
	end)

	SessionService.onRemoving(function(session)
		session.AutoRoll = false
	end)
end

return RollService
