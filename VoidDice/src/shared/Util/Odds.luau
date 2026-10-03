--!strict
-- Odds (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Util > Odds
--
-- Baut aus den Configs die RollMath-Tabellen (einmal, dann gecacht).
-- Server nutzt sie zum Ziehen, Client für die Anzeige im Index/HUD.

local Config = script.Parent.Parent:WaitForChild("Config")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local FishingConfig = require(Config:WaitForChild("FishingConfig"))
local RollMath = require(script.Parent:WaitForChild("RollMath"))

local Odds = {}

local characterTable: RollMath.Table? = nil
local characterIndex: { [string]: number } = {}
local watersTables: { [string]: RollMath.Table } = {}

function Odds.characterTable(): RollMath.Table
	if characterTable then
		return characterTable
	end
	local entries = {}
	for _, def in CharacterConfig.List do
		if def.ReleaseEnabled then
			local rarity = RarityConfig.Get(def.Rarity)
			table.insert(entries, { Key = def.Id, Chance = def.RollChance, Boosted = rarity.LuckAffected })
			characterIndex[def.Id] = #entries
		end
	end
	local tbl = RollMath.newTable(entries)
	characterTable = tbl
	return tbl
end

-- Echte Wahrscheinlichkeit eines Characters bei `luck` (0 wenn nicht rollbar)
function Odds.characterProbability(id: string, luck: number): number
	local tbl = Odds.characterTable()
	local i = characterIndex[id]
	if not i then
		return 0
	end
	return RollMath.probabilities(tbl, luck)[i]
end

-- { [RarityId] = Wahrscheinlichkeit } bei `luck`
function Odds.rarityProbabilities(luck: number): { [string]: number }
	local tbl = Odds.characterTable()
	local probs = RollMath.probabilities(tbl, luck)
	local out = {}
	for _, r in RarityConfig.List do
		out[r.Id] = 0
	end
	for i, e in tbl.Entries do
		local def = CharacterConfig.ById[e.Key]
		out[def.Rarity] += probs[i]
	end
	return out
end

function Odds.watersTable(watersId: string): RollMath.Table?
	local cached = watersTables[watersId]
	if cached then
		return cached
	end
	local waters = FishingConfig.WatersById[watersId]
	if not waters then
		return nil
	end
	local entries = {}
	for _, loot in waters.Loot do
		-- Fishing Luck wirkt erst ab Rare (Common/Uncommon sind der "Rest")
		local order = RarityConfig.Order(loot.Rarity)
		table.insert(entries, { Key = loot, Chance = loot.Chance, Boosted = order >= 3 })
	end
	local tbl = RollMath.newTable(entries)
	watersTables[watersId] = tbl
	return tbl
end

return Odds
