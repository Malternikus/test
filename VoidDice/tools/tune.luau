-- tune.luau (Lune)
--
-- Passt Rebirth-Kosten automatisch an die Zielzeiten an
-- (EconomyConfig.RebirthTargetsMinutes), indem die Simulation wiederholt
-- läuft. Gebiets- und Dice-Kosten hängen fest an der Rebirth-Stufe, die sie
-- freischaltet (AREA_FACTOR / DICE_FACTOR × Rebirth-Kosten).
--
-- Ergebnis wird nur ausgegeben, NICHT in die Configs geschrieben.
-- Aufruf: lune run tune.luau [iterationen=8] [seeds=12]

local process = require("@lune/process")
local Sim = require("./SimCore")

local h = Sim.h
local Config = "ReplicatedStorage.VoidDice.Config."
local RebirthConfig = h.requirePath(Config .. "RebirthConfig")
local AreaConfig = h.requirePath(Config .. "AreaConfig")
local DiceConfig = h.requirePath(Config .. "DiceConfig")
local EconomyConfig = h.requirePath(Config .. "EconomyConfig")

local ITERATIONS = tonumber(process.args[1]) or 8
local SEEDS = tonumber(process.args[2]) or 12
local AREA_FACTOR = 0.35
local DICE_FACTOR = 0.6
local TAIL_GROWTH = 2.8

local targets = EconomyConfig.RebirthTargetsMinutes
local N = #targets
local MINUTES = targets[N] + 30

local function nice(x: number): number
	local digits = math.floor(math.log10(x))
	local scale = 10 ^ (digits - 1)
	return math.floor(x / scale + 0.5) * scale
end

local function applyDerived()
	-- Rebirths nach den Zielen: fester Wachstumsfaktor
	for i = N + 1, RebirthConfig.TableSize do
		RebirthConfig.Steps[i].Cost = nice(RebirthConfig.Steps[i - 1].Cost * TAIL_GROWTH)
	end
	for _, area in AreaConfig.List do
		if area.RequiredRebirths > 0 then
			area.UnlockCost = nice(RebirthConfig.GetStep(area.RequiredRebirths).Cost * AREA_FACTOR)
		end
	end
	for _, dice in DiceConfig.List do
		local area = AreaConfig.Get(dice.Area)
		if area and area.RequiredRebirths > 0 then
			dice.Cost = nice(RebirthConfig.GetStep(area.RequiredRebirths).Cost * DICE_FACTOR)
		end
	end
end

local function median(list: { number }): number
	table.sort(list)
	return list[math.max(1, math.ceil(#list / 2))]
end

local function measure(): { number }
	local times = {}
	for i = 1, N do
		times[i] = {}
	end
	for seed = 1, SEEDS do
		local log = Sim.run(seed * 104729, MINUTES)
		for i = 1, N do
			table.insert(times[i], (log.rebirths[i] or (MINUTES * 60 * 1.3)) / 60)
		end
	end
	local out = {}
	for i = 1, N do
		out[i] = median(times[i])
	end
	return out
end

applyDerived()
for iteration = 1, ITERATIONS do
	local measured = measure()
	local parts = {}
	local maxError = 0
	for i = 1, N do
		local ratio = targets[i] / measured[i]
		maxError = math.max(maxError, math.abs(math.log(ratio)))
		table.insert(parts, string.format("R%d %.1f/%d", i, measured[i], targets[i]))
		-- nur die erste stark abweichende Stufe voll korrigieren, spätere sanfter
		local step = RebirthConfig.Steps[i]
		local factor = math.clamp(ratio ^ 0.8, 0.5, 2)
		step.Cost = nice(step.Cost * factor)
		if i > 1 then
			step.Cost = math.max(step.Cost, nice(RebirthConfig.Steps[i - 1].Cost * 1.6))
		end
	end
	applyDerived()
	print(string.format("[%d] %s  (max Abweichung %.0f %%)", iteration, table.concat(parts, "  "), (math.exp(maxError) - 1) * 100))
end

print("\nRebirthConfig.Steps Cost:")
for i = 1, RebirthConfig.TableSize do
	print(string.format("  [%d] = %d", i, RebirthConfig.Steps[i].Cost))
end
print("AreaConfig UnlockCost:")
for _, a in AreaConfig.List do
	print(string.format("  %s = %d", a.Id, a.UnlockCost))
end
print("DiceConfig Cost:")
for _, d in DiceConfig.List do
	print(string.format("  %s = %d", d.Id, d.Cost))
end
