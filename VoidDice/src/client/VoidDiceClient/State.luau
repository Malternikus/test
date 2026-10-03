--!strict
-- State (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > State
--
-- Spiegel des eigenen Profils auf dem Client (nur Anzeige!). Der Server
-- schickt Patches über das Remote "Sync". Alle UI-Module lesen hier und
-- hören auf State.Changed(key).
--
-- Zusätzlich: Server-Events ("Roll", "Toast", ...) über State.on(kind, fn).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local Net = require(Shared:WaitForChild("Net"))
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local Stats = require(Shared:WaitForChild("Util"):WaitForChild("Stats"))
local Signal = require(script.Parent:WaitForChild("Signal"))

local State = {}

State.data = {} :: { [string]: any }
State.derived = {} :: { [string]: any }
State.session = {} :: { [string]: any }
State.ready = false

State.Changed = Signal.new() -- (key)
State.Ready = Signal.new()

local eventSignals: { [string]: Signal.Signal } = {}

function State.on(kind: string, fn: (any) -> ()): Signal.Connection
	local signal = eventSignals[kind]
	if not signal then
		signal = Signal.new()
		eventSignals[kind] = signal
	end
	return signal:Connect(fn)
end

-- Lokale Events (z. B. UI -> UI), gleicher Kanal wie Server-Events
function State.emit(kind: string, data: any?)
	local signal = eventSignals[kind]
	if signal then
		signal:Fire(data)
	end
end

local function applyPatch(patch: { [string]: any })
	local data = State.data
	if patch.Full then
		data.Characters = {}
		data.Gear = {}
	end
	for key, value in patch do
		if key == "Full" then
			continue
		elseif key == "Derived" then
			State.derived = value
		elseif key == "Session" then
			State.session = value
		elseif (key == "Characters" or key == "Gear") and not patch.Full then
			local target = data[key] or {}
			data[key] = target
			for uid, entry in value do
				if entry == false then
					target[uid] = nil
				else
					target[uid] = entry
				end
			end
		else
			data[key] = value
		end
	end
	for key in patch do
		if key ~= "Full" then
			State.Changed:Fire(key)
		end
	end
	if patch.Full and not State.ready then
		State.ready = true
		State.Ready:Fire()
	end
end

function State.start()
	Net.get("Sync").OnClientEvent:Connect(applyPatch)
	Net.get("Event").OnClientEvent:Connect(function(kind: string, data: any)
		State.emit(kind, data)
	end)
end

function State.waitReady()
	if not State.ready then
		local done = false
		State.Ready:Once(function()
			done = true
		end)
		while not done do
			task.wait()
		end
	end
end

-- Helfer ---------------------------------------------------------------------------

function State.character(uid: string)
	return State.data.Characters and State.data.Characters[uid]
end

function State.def(uid: string)
	local char = State.character(uid)
	return char and CharacterConfig.ById[char.Id]
end

function State.gearCashPct(char): number
	local pct = 0
	for _, gearUid in char.Gear or {} do
		local item = State.data.Gear and State.data.Gear[gearUid]
		local def = item and GearConfig.Get(item.Id)
		if def and def.CashPct then
			pct += def.CashPct
		end
	end
	return math.min(pct, EconomyConfig.MaxGearCashPctPerCharacter)
end

-- Gleiche Formel wie Logic.Economy.characterIncome
function State.income(uid: string): number
	local char = State.character(uid)
	local def = char and CharacterConfig.ById[char.Id]
	if not def then
		return 0
	end
	return Stats.income(def, char.Level, char.Mutation) * (1 + State.gearCashPct(char) / 100) * (State.derived.CashMultiplier or 1)
end

function State.upgradeCost(uid: string): number?
	local char = State.character(uid)
	local def = char and CharacterConfig.ById[char.Id]
	return def and Stats.upgradeCost(def, char.Level, char.Mutation)
end

function State.fishingPower(uid: string): number
	local char = State.character(uid)
	local def = char and CharacterConfig.ById[char.Id]
	if not def then
		return 0
	end
	local power = Stats.fishingPower(def, char.Level)
	for _, gearUid in char.Gear or {} do
		local item = State.data.Gear and State.data.Gear[gearUid]
		local g = item and GearConfig.Get(item.Id)
		if g and g.FishingPower then
			power += g.FishingPower
		end
	end
	return power
end

-- Characters als sortierte Liste: { uid, char, def }
-- sort: "Rarity" (Standard), "Income", "Level", "Newest"
function State.characterList(sort: string?, filter: ((any, any) -> boolean)?)
	local list = {}
	for uid, char in State.data.Characters or {} do
		local def = CharacterConfig.ById[char.Id]
		if def and (not filter or filter(char, def)) then
			table.insert(list, { uid = uid, char = char, def = def, income = State.income(uid) })
		end
	end
	local mode = sort or "Rarity"
	table.sort(list, function(a, b)
		if mode == "Income" and a.income ~= b.income then
			return a.income > b.income
		elseif mode == "Level" and a.char.Level ~= b.char.Level then
			return a.char.Level > b.char.Level
		elseif mode == "Newest" and a.char.At ~= b.char.At then
			return (a.char.At or 0) > (b.char.At or 0)
		end
		local ra, rb = RarityConfig.Order(a.def.Rarity), RarityConfig.Order(b.def.Rarity)
		if ra ~= rb then
			return ra > rb
		end
		if a.income ~= b.income then
			return a.income > b.income
		end
		return a.uid < b.uid
	end)
	return list
end

return State
