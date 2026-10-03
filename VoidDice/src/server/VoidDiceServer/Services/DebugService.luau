--!strict
-- DebugService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > DebugService
--
-- Test-Befehle NUR in Roblox Studio (RunService:IsStudio() + GameConfig.
-- StudioDebugTools). Im veröffentlichten Spiel lehnt der Server alles ab.
-- Im Client: Settings > DEBUG.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local GameConfig = require(Config:WaitForChild("GameConfig"))
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local PotionConfig = require(Config:WaitForChild("PotionConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local DiceConfig = require(Config:WaitForChild("DiceConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local DebugService = {}

local COMMANDS: { [string]: (session: any, ctx: any, arg: any) -> (boolean, string?) } = {}

COMMANDS.Cash = function(session, ctx, amount)
	local n = tonumber(amount) or 1e6
	Logic.Economy.earn(session.Profile, ctx, math.clamp(n, 0, 1e18), "Debug")
	return true, nil
end

COMMANDS.RebirthReady = function(session, ctx)
	local profile = session.Profile
	local need = Logic.Progression.rebirthCost(profile) - profile.Cash
	if need > 0 then
		Logic.Economy.earn(profile, ctx, need, "Debug")
	end
	return true, nil
end

COMMANDS.Potions = function(session, ctx)
	for _, def in PotionConfig.List do
		Logic.Items.addPotion(session.Profile, ctx, def.Id, 5)
	end
	return true, nil
end

COMMANDS.Gear = function(session, ctx)
	for _, def in GearConfig.List do
		Logic.Items.addGear(session.Profile, ctx, def.Id)
	end
	return true, nil
end

COMMANDS.UnlockAll = function(session, ctx)
	local profile = session.Profile
	for _, area in AreaConfig.List do
		profile.Areas[area.Id] = true
	end
	for _, dice in DiceConfig.List do
		profile.Dice.Owned[dice.Id] = true
	end
	profile.Stats.TotalCashEarned = math.max(profile.Stats.TotalCashEarned, GameConfig.FishingUnlockCashEarned)
	Logic.Context.mark(ctx, "Areas")
	Logic.Context.mark(ctx, "Dice")
	Logic.Context.mark(ctx, "Stats")
	return true, nil
end

-- n Rolls sofort (Statistik-Test für Luck), Ergebnis als Toast
COMMANDS.Roll = function(session, ctx, amount)
	local n = math.clamp(math.floor(tonumber(amount) or 1000), 1, 20000)
	local counts = {}
	local mods = Logic.Modifiers.compute(session.Profile)
	for _ = 1, n do
		local r = Logic.Rolling.roll(session.Profile, ctx, mods)
		counts[r.Rarity] = (counts[r.Rarity] or 0) + 1
	end
	local parts = {}
	for _, r in RarityConfig.List do
		if counts[r.Id] then
			table.insert(parts, string.format("%s %d", r.Id, counts[r.Id]))
		end
	end
	SessionService.toast(session, string.format("%d rolls @ luck %.2f: %s", n, mods.Luck, table.concat(parts, ", ")), "info")
	return true, nil
end

COMMANDS.Character = function(session, ctx, id)
	if type(id) ~= "string" or not CharacterConfig.ById[id] then
		return false, "Unknown character id"
	end
	Logic.Inventory.add(session.Profile, ctx, id, nil)
	return true, nil
end

COMMANDS.Reset = function(session, ctx)
	local fresh = Logic.ProfileTemplate.new()
	for key in session.Profile do
		session.Profile[key] = nil
	end
	for key, value in fresh do
		session.Profile[key] = value
	end
	Logic.onLoad(session.Profile, ctx)
	SessionService.sendFull(session)
	return true, nil
end

function DebugService.Start()
	SessionService.registerAction("Debug", function(session, ctx, command: string, arg: any)
		if not (RunService:IsStudio() and GameConfig.StudioDebugTools) then
			return false, "Debug tools are disabled"
		end
		local fn = COMMANDS[command]
		if not fn then
			return false, "Unknown debug command"
		end
		return fn(session, ctx, arg)
	end)
end

return DebugService
