--!strict
-- AntiCheatService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > AntiCheatService
--
-- Grundlage gegen Exploits:
--   * Rate Limits pro Spieler und Action-Kategorie (Token Bucket)
--   * Typprüfung aller Remote-Argumente (Net.Actions)
--   * Cash-Sanity nach jeder Aktion (NaN/inf/negativ -> zurücksetzen)
--   * Verdachtszähler: bei massivem Spam wird der Spieler gekickt
--
-- Wichtig: Spielentscheidungen (Roll-Ergebnis, Kosten, Drops) trifft ohnehin
-- nur der Server. Der Client kann höchstens zu oft fragen – das fängt das
-- Rate Limit ab.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Net = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Net"))

local AntiCheatService = {}

-- Kategorie pro Action (Standard: "Default")
local CATEGORY = {
	Roll = "Roll",
	Rebirth = "Heavy",
	BuyDice = "Heavy",
	UnlockArea = "Heavy",
	Teleport = "Heavy",
	SellRarity = "Heavy",
	PlaceBest = "Heavy",
	InspectBase = "Heavy",
	TestPurchase = "Heavy",
	Debug = "Heavy",
	SetSetting = "Settings",
	SetAutoDelete = "Settings",
	SetAutoRoll = "Settings",
}

-- Rate = Tokens pro Sekunde, Burst = maximale Tokens
local LIMITS = {
	Default = { Rate = 10, Burst = 25 },
	Roll = { Rate = 6, Burst = 10 },
	Heavy = { Rate = 2, Burst = 5 },
	Settings = { Rate = 4, Burst = 12 },
}

local STRIKE_WINDOW = 60
local STRIKES_TO_KICK = 300
local MAX_ARGS = 4

type Bucket = { tokens: number, last: number }
type PlayerState = { buckets: { [string]: Bucket }, strikes: number, windowStart: number, flags: { string } }

local states: { [Player]: PlayerState } = {}

local function getState(player: Player): PlayerState
	local s = states[player]
	if not s then
		s = { buckets = {}, strikes = 0, windowStart = os.clock(), flags = {} }
		states[player] = s
	end
	return s
end

function AntiCheatService.flag(player: Player, reason: string)
	local s = getState(player)
	if #s.flags < 50 then
		table.insert(s.flags, string.format("%.0f %s", os.time(), reason))
	end
	warn(string.format("[AntiCheat] %s (%d): %s", player.Name, player.UserId, reason))
end

local function strike(player: Player, reason: string)
	local s = getState(player)
	local now = os.clock()
	if now - s.windowStart > STRIKE_WINDOW then
		s.windowStart = now
		s.strikes = 0
	end
	s.strikes += 1
	if s.strikes == 1 or s.strikes % 50 == 0 then
		AntiCheatService.flag(player, reason .. " (x" .. s.strikes .. ")")
	end
	if s.strikes >= STRIKES_TO_KICK then
		player:Kick("Too many requests. Please rejoin.")
	end
end

-- true = Aktion darf ausgeführt werden
function AntiCheatService.allow(player: Player, action: string): boolean
	local category = CATEGORY[action] or "Default"
	local limit = LIMITS[category]
	local s = getState(player)
	local now = os.clock()
	local bucket = s.buckets[category]
	if not bucket then
		bucket = { tokens = limit.Burst, last = now }
		s.buckets[category] = bucket
	end
	bucket.tokens = math.min(limit.Burst, bucket.tokens + (now - bucket.last) * limit.Rate)
	bucket.last = now
	if bucket.tokens < 1 then
		strike(player, "rate limit " .. action)
		return false
	end
	bucket.tokens -= 1
	return true
end

local function validArg(kind: string, value: any): boolean
	if kind == "string" then
		return type(value) == "string" and #value <= 64
	elseif kind == "id" then
		return type(value) == "string" and #value > 0 and #value <= 48 and value:match("^[%w_]+$") ~= nil
	elseif kind == "uid" then
		return type(value) == "string" and #value <= 12 and value:match("^[cg]%d+$") ~= nil
	elseif kind == "number" then
		return type(value) == "number" and value == value and math.abs(value) < 1e9
	elseif kind == "boolean" then
		return type(value) == "boolean"
	elseif kind == "any" then
		local t = type(value)
		return t == "boolean" or (t == "number" and value == value and math.abs(value) < 1e15) or (t == "string" and #value <= 64) or t == "nil"
	end
	return false
end

-- Prüft Action-Name und Argumente gegen Net.Actions.
function AntiCheatService.validate(player: Player, action: any, args: { any }): boolean
	if type(action) ~= "string" then
		strike(player, "action not a string")
		return false
	end
	local spec = Net.Actions[action]
	if not spec then
		strike(player, "unknown action " .. action:sub(1, 24))
		return false
	end
	if #args > MAX_ARGS then
		strike(player, "too many args " .. action)
		return false
	end
	for i, kind in spec do
		local value = args[i]
		-- "number" bei Upgrade darf fehlen
		if not (value == nil and (kind == "number" or kind == "any")) and not validArg(kind, value) then
			strike(player, "bad arg " .. i .. " for " .. action)
			return false
		end
	end
	return true
end

-- Nach jeder Aktion: Cash/Vault dürfen nie NaN, inf oder negativ sein.
function AntiCheatService.sanitize(player: Player, profile, lastGood: { Cash: number, Vault: number })
	local function bad(n: any): boolean
		return type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge or n < 0
	end
	if bad(profile.Cash) then
		AntiCheatService.flag(player, "invalid Cash " .. tostring(profile.Cash) .. ", reverted")
		profile.Cash = lastGood.Cash
	end
	if bad(profile.Vault) then
		AntiCheatService.flag(player, "invalid Vault " .. tostring(profile.Vault) .. ", reverted")
		profile.Vault = lastGood.Vault
	end
	lastGood.Cash = profile.Cash
	lastGood.Vault = profile.Vault
end

function AntiCheatService.getFlags(player: Player): { string }
	return getState(player).flags
end

function AntiCheatService.Start()
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
end

return AntiCheatService
