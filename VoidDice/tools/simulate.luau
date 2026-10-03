-- simulate.luau (Lune)
--
-- Economy-Simulation: viele simulierte Spieler (tools/SimCore.luau) mit der
-- echten Server-Logik, Auswertung als Markdown-Report.
--
-- Aufruf (aus VoidDice/tools):
--   lune run simulate.luau [minuten=180] [seeds=24] [write]
-- Mit "write" wird docs/ECONOMY.md neu geschrieben.

local fs = require("@lune/fs")
local process = require("@lune/process")
local Sim = require("./SimCore")

local h = Sim.h
local ROOT = Sim.ROOT
local Config = "ReplicatedStorage.VoidDice.Config."
local RarityConfig = h.requirePath(Config .. "RarityConfig")
local DiceConfig = h.requirePath(Config .. "DiceConfig")
local AreaConfig = h.requirePath(Config .. "AreaConfig")
local EconomyConfig = h.requirePath(Config .. "EconomyConfig")
local RebirthConfig = h.requirePath(Config .. "RebirthConfig")
local Format = h.requirePath("ReplicatedStorage.VoidDice.Util.Format")
local CHECKPOINTS = Sim.Checkpoints

local args = process.args
local MINUTES = tonumber(args[1]) or 180
local SEEDS = tonumber(args[2]) or 24
local WRITE = table.find(args, "write") ~= nil or table.find(args, "--write") ~= nil

-- Statistik-Helfer -------------------------------------------------------------
local function percentile(list: { number }, p: number): number?
	if #list == 0 then
		return nil
	end
	local sorted = table.clone(list)
	table.sort(sorted)
	local idx = math.clamp(math.floor(p * (#sorted - 1) + 1.5), 1, #sorted)
	return sorted[idx]
end

local function mins(seconds: number?): string
	if not seconds then
		return "–"
	end
	return string.format("%.1f", seconds / 60)
end

-- Lauf -----------------------------------------------------------------------------
local started = os.clock()
local logs = {}
for seed = 1, SEEDS do
	table.insert(logs, Sim.run(seed * 7919, MINUTES))
end
local elapsed = os.clock() - started

local out = {}
local function line(s: string?)
	table.insert(out, s or "")
end

line("# VOID DICE – Economy Report")
line()
line(string.format("Automatisch erzeugt von `tools/simulate.luau` mit der echten Server-Logik: %d Spieler-Simulationen à %d Minuten (Rechenzeit %.1fs).", SEEDS, MINUTES, elapsed))
line("Bot-Verhalten: Auto Roll, Auto Place, alle 10 s einsammeln, Upgrades mit ≤ 4 min Amortisation, Dice/Gebiete sofort, Rebirth sobald bezahlbar, Fishing/Potions/Gear/Quests aktiv. Keine Gamepasses.")
line()
line("## Rebirth-Zeitpunkte (Minuten seit Spielstart)")
line()
line("| Rebirth | Ziel | Median | schnell (P10) | langsam (P90) | erreicht von |")
line("|---|---|---|---|---|---|")
for i = 1, 12 do
	local times = {}
	for _, log in logs do
		if log.rebirths[i] then
			table.insert(times, log.rebirths[i])
		end
	end
	if #times == 0 then
		break
	end
	local target = EconomyConfig.RebirthTargetsMinutes[i]
	line(string.format("| %d | %s | %s | %s | %s | %d/%d |", i, if target then "~" .. target else "–",
		mins(percentile(times, 0.5)), mins(percentile(times, 0.1)), mins(percentile(times, 0.9)), #times, #logs))
end
line()
line("## Meilensteine (Median, Minuten)")
line()
line("| Meilenstein | Median | P10 | P90 |")
line("|---|---|---|---|")
local function milestone(label: string, getter)
	local times = {}
	for _, log in logs do
		local v = getter(log)
		if v then
			table.insert(times, v)
		end
	end
	line(string.format("| %s | %s | %s | %s |", label, mins(percentile(times, 0.5)), mins(percentile(times, 0.1)), mins(percentile(times, 0.9))))
end
milestone("Erstes Upgrade", function(l) return l.firstUpgrade end)
milestone("Fishing freigeschaltet", function(l) return l.fishingUnlocked end)
milestone("Erstes Gear", function(l) return l.firstGear end)
for _, r in RarityConfig.List do
	if r.Order >= 3 then
		milestone("Erster " .. r.DisplayName, function(l) return l.firstRarity[r.Id] end)
	end
end
for _, area in AreaConfig.List do
	if area.Order > 1 then
		milestone("Gebiet " .. area.DisplayName, function(l) return l.areas[area.Id] end)
	end
end
for _, dice in DiceConfig.List do
	if dice.Cost > 0 then
		milestone(dice.DisplayName, function(l) return l.dice[dice.Id] end)
	end
end
line()
line("## Verlauf (Median über alle Simulationen)")
line()
line("| Minute | $/s | Cash verdient gesamt | Luck | Rebirths | Rolls | Index | beste Rarity | Dice | Slots | Fänge |")
line("|---|---|---|---|---|---|---|---|---|---|---|")
for _, cp in CHECKPOINTS do
	if cp > MINUTES then
		break
	end
	local incomes, earned, luck, reb, rolls, disc, catches, slots = {}, {}, {}, {}, {}, {}, {}, {}
	local bestCount, diceCount = {}, {}
	for _, log in logs do
		local c = log.checkpoints[cp]
		if c then
			table.insert(incomes, c.income)
			table.insert(earned, c.earned)
			table.insert(luck, c.luck)
			table.insert(reb, c.rebirths)
			table.insert(rolls, c.rolls)
			table.insert(disc, c.discovered)
			table.insert(catches, c.catches)
			table.insert(slots, c.slots)
			bestCount[c.best] = (bestCount[c.best] or 0) + 1
			diceCount[c.dice] = (diceCount[c.dice] or 0) + 1
		end
	end
	local function mode(map)
		local best, n = "-", 0
		for k, v in map do
			if v > n then
				best, n = k, v
			end
		end
		return best
	end
	line(string.format("| %d | %s | %s | x%.2f | %d | %s | %d | %s | %s | %d | %d |", cp,
		Format.perSecond(percentile(incomes, 0.5) or 0), Format.cash(percentile(earned, 0.5) or 0),
		percentile(luck, 0.5) or 1, percentile(reb, 0.5) or 0, Format.commas(percentile(rolls, 0.5) or 0),
		percentile(disc, 0.5) or 0, mode(bestCount), mode(diceCount), percentile(slots, 0.5) or 0, percentile(catches, 0.5) or 0))
end
line()
line("## Cash-Quellen (Anteil, Summe aller Simulationen)")
line()
line("| Quelle | erste 5 Minuten | gesamt |")
line("|---|---|---|")
do
	local early, total = {}, {}
	local earlySum, totalSum = 0, 0
	for _, log in logs do
		for k, v in log.sources5 or {} do
			early[k] = (early[k] or 0) + v
			earlySum += v
		end
		for k, v in log.sources do
			total[k] = (total[k] or 0) + v
			totalSum += v
		end
	end
	local keys = {}
	for k in total do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		return total[a] > total[b]
	end)
	for _, k in keys do
		line(string.format("| %s | %.1f %% | %.1f %% |", k, 100 * (early[k] or 0) / math.max(1, earlySum), 100 * total[k] / math.max(1, totalSum)))
	end
end
line()
line("## Kosten-Tabelle (aus den Configs)")
line()
line("| Rebirth | Kosten |")
line("|---|---|")
for i = 1, 12 do
	line(string.format("| %d | %s |", i, Format.cash(RebirthConfig.GetStep(i).Cost)))
end
line()
line("| Dice | Luck | Gebiet | Kosten |")
line("|---|---|---|---|")
for _, d in DiceConfig.List do
	line(string.format("| %s | x%g | %s | %s |", d.DisplayName, d.Luck, d.Area, Format.cash(d.Cost)))
end
line()
line("| Gebiet | Rebirth nötig | Kosten |")
line("|---|---|---|")
for _, a in AreaConfig.List do
	line(string.format("| %s | %d | %s |", a.DisplayName, a.RequiredRebirths, Format.cash(a.UnlockCost)))
end
line()
line("Upgrade-Kosten in Sekunden Basis-Einkommen (Level 1→15): " .. table.concat(EconomyConfig.UpgradeCostSeconds, ", "))
line()
line("Level-Multiplikator: " .. table.concat(EconomyConfig.LevelIncomeMultiplier, ", "))

local report = table.concat(out, "\n") .. "\n"
print(report)
if WRITE then
	fs.writeFile(ROOT .. "/docs/ECONOMY.md", report)
	print("-> docs/ECONOMY.md geschrieben")
end
