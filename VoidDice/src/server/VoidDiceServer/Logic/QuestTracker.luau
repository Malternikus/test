--!strict
-- QuestTracker (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic > QuestTracker
--
-- Zählt Fortschritt der Daily Quests und würfelt jeden Tag neue.
-- Getrennt von Quests (Belohnungen), damit alle anderen Module Fortschritt
-- melden können, ohne zyklische requires.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local QuestConfig = require(Config:WaitForChild("QuestConfig"))

local Context = require(script.Parent:WaitForChild("Context"))

local QuestTracker = {}

local DAY = 86400

function QuestTracker.dayOf(now: number): number
	return math.floor(now / DAY)
end

-- Deterministische Auswahl: gleicher Spieler + gleicher Tag = gleiche Quests
local function pickQuests(userId: number, day: number): { string }
	local rng = Random.new((userId % 1000003) * 7919 + day * 104729 + 17)
	local pool = table.clone(QuestConfig.Pool)
	local picked = {}
	local usedCounters = {}
	while #picked < QuestConfig.DailyCount and #pool > 0 do
		local total = 0
		for _, q in pool do
			total += q.Weight
		end
		local r = rng:NextNumber() * total
		local chosenIndex = #pool
		for i, q in pool do
			r -= q.Weight
			if r <= 0 then
				chosenIndex = i
				break
			end
		end
		local q = table.remove(pool, chosenIndex) :: any
		-- höchstens zwei Quests mit demselben Zähler
		usedCounters[q.Counter] = (usedCounters[q.Counter] or 0) + 1
		if usedCounters[q.Counter] <= 2 then
			table.insert(picked, q.Id)
		end
	end
	return picked
end

function QuestTracker.ensureDaily(profile, ctx: Context.Context)
	local day = QuestTracker.dayOf(ctx.now)
	local quests = profile.Quests
	if quests.Day == day then
		return
	end
	local ids
	if quests.FirstDay then
		ids = table.clone(QuestConfig.FirstDayQuests)
		quests.FirstDay = false
	else
		ids = pickQuests(ctx.userId, day)
	end
	local list = {}
	for _, id in ids do
		if QuestConfig.ById[id] then
			table.insert(list, { Id = id, Progress = 0, Claimed = false })
		end
	end
	quests.Day = day
	quests.List = list
	Context.mark(ctx, "Quests")
end

function QuestTracker.track(profile, ctx: Context.Context, counter: string, amount: number)
	if amount <= 0 then
		return
	end
	for _, entry in profile.Quests.List do
		local def = QuestConfig.ById[entry.Id]
		if def and def.Counter == counter and entry.Progress < def.Target then
			entry.Progress = math.min(def.Target, entry.Progress + amount)
			Context.mark(ctx, "Quests")
			if entry.Progress >= def.Target then
				Context.event(ctx, "QuestComplete", { Id = def.Id, Text = def.Text })
			end
		end
	end
end

return QuestTracker
