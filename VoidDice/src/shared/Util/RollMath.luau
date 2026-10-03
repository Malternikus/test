--!strict
-- RollMath (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Util > RollMath
--
-- Die gesamte Zufalls-Mathematik für Character-Rolls und Fishing-Loot.
-- Server UND Client nutzen dasselbe Modul: Der Server zieht, der Client zeigt
-- exakt dieselben Wahrscheinlichkeiten an. Keine Fake-Luck.
--
-- Modell:
--   Jeder Eintrag hat eine Basis-Chance "1 in X" (p = 1/X).
--   "Boosted"-Einträge (alles ab Uncommon) bekommen p = Luck / X.
--   Vergeben wird von der seltensten Stufe abwärts. Reicht die Restmasse
--   nicht mehr, bekommt der Eintrag nur den Rest (Deckelung bei sehr hoher Luck).
--   Nicht-Boosted-Einträge (Commons) teilen sich die Restmasse im Verhältnis
--   ihrer Gewichte 1/X.
--
-- Eigenschaften:
--   * Bei Luck 1 entsprechen alle Boosted-Chancen exakt dem Config-Wert.
--   * Luck L macht jede seltene Chance exakt L-mal wahrscheinlicher,
--     solange insgesamt noch Commons übrig bleiben.
--   * Die Summe ist immer genau 1.

export type Entry = {
	Key: any,
	Chance: number, -- "1 in X"
	Boosted: boolean,
}

export type Table = {
	Entries: { Entry },
	_order: { number }, -- Indizes: Boosted seltenste zuerst, dann Unboosted
	_boostedCount: number,
	_unboostedWeight: number,
	_cache: { [number]: { number } },
	_cacheSize: number,
}

local RollMath = {}

local MAX_CACHE = 64

function RollMath.newTable(entries: { Entry }): Table
	assert(#entries > 0, "RollMath: leere Tabelle")
	local boosted, unboosted = {}, {}
	local unboostedWeight = 0
	for i, e in entries do
		assert(type(e.Chance) == "number" and e.Chance >= 1, "RollMath: Chance muss >= 1 sein")
		if e.Boosted then
			table.insert(boosted, i)
		else
			table.insert(unboosted, i)
			unboostedWeight += 1 / e.Chance
		end
	end
	-- seltenste zuerst (größtes X)
	table.sort(boosted, function(a, b)
		if entries[a].Chance == entries[b].Chance then
			return a < b
		end
		return entries[a].Chance > entries[b].Chance
	end)
	local order = table.clone(boosted)
	for _, i in unboosted do
		table.insert(order, i)
	end
	return {
		Entries = entries,
		_order = order,
		_boostedCount = #boosted,
		_unboostedWeight = unboostedWeight,
		_cache = {},
		_cacheSize = 0,
	}
end

-- Wahrscheinlichkeit jedes Eintrags (gleicher Index wie Entries) bei `luck`.
function RollMath.probabilities(tbl: Table, luck: number): { number }
	luck = math.max(1, luck)
	-- Cache auf 4 Nachkommastellen (Luck ändert sich selten)
	local key = math.floor(luck * 10000 + 0.5)
	local cached = tbl._cache[key]
	if cached then
		return cached
	end

	local entries = tbl.Entries
	local probs = table.create(#entries, 0)
	local remaining = 1
	for n = 1, tbl._boostedCount do
		local i = tbl._order[n]
		local p = math.min(remaining, luck / entries[i].Chance)
		probs[i] = p
		remaining -= p
	end
	remaining = math.max(0, remaining)

	if tbl._unboostedWeight > 0 then
		for n = tbl._boostedCount + 1, #tbl._order do
			local i = tbl._order[n]
			probs[i] = remaining * (1 / entries[i].Chance) / tbl._unboostedWeight
		end
	elseif remaining > 0 then
		-- Keine Rest-Einträge: Rest proportional auf alle verteilen
		local total = 1 - remaining
		for i = 1, #entries do
			probs[i] = if total > 0 then probs[i] / total else 1 / #entries
		end
	end

	if tbl._cacheSize >= MAX_CACHE then
		tbl._cache = {}
		tbl._cacheSize = 0
	end
	tbl._cache[key] = probs
	tbl._cacheSize += 1
	return probs
end

-- Zieht einen Eintrag. `u` ist eine Zufallszahl in [0, 1).
-- Gibt Eintrag, Index und die echte Wahrscheinlichkeit zurück.
function RollMath.pick(tbl: Table, luck: number, u: number): (Entry, number, number)
	local probs = RollMath.probabilities(tbl, luck)
	local acc = 0
	for _, i in tbl._order do
		acc += probs[i]
		if u < acc then
			return tbl.Entries[i], i, probs[i]
		end
	end
	-- Rundungsfehler: häufigster Eintrag
	local last = tbl._order[#tbl._order]
	return tbl.Entries[last], last, probs[last]
end

-- "1 in X" für die Anzeige (X gerundet, inf bei p = 0)
function RollMath.oneIn(p: number): number
	if p <= 0 then
		return math.huge
	end
	return 1 / p
end

-- Summe der Wahrscheinlichkeiten aller Einträge, für die `predicate` gilt
function RollMath.sumWhere(tbl: Table, luck: number, predicate: (Entry) -> boolean): number
	local probs = RollMath.probabilities(tbl, luck)
	local sum = 0
	for i, e in tbl.Entries do
		if predicate(e) then
			sum += probs[i]
		end
	end
	return sum
end

-- Mutationen: jede Mutation hat ihren eigenen Luck-Faktor. Seltenste zuerst,
-- Rest = "Normal". entries: { { Key, Chance, Luck } }, Key des Rests = fallback
function RollMath.pickIndependent(entries: { { Key: any, Chance: number, Luck: number } }, fallback: any, u: number): (any, number)
	local sorted = table.clone(entries)
	table.sort(sorted, function(a, b)
		return a.Chance > b.Chance
	end)
	local acc = 0
	for _, e in sorted do
		local p = math.min(1 - acc, math.max(1, e.Luck) / e.Chance)
		acc += p
		if u < acc then
			return e.Key, p
		end
	end
	return fallback, 1 - acc
end

return RollMath
