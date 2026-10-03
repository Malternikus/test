-- gen_characters.luau (Lune)
--
-- Schreibt docs/CHARACTERS.md aus CharacterConfig (eine Quelle der Wahrheit).
-- Aufruf (aus VoidDice/tools): lune run gen_characters.luau

local fs = require("@lune/fs")
local process = require("@lune/process")
local Harness = require("../tests/harness")

local ROOT = (process.cwd :: string):gsub("/tools/?$", ""):gsub("/$", "")
local h = Harness.load(ROOT)

local CharacterConfig = h.requirePath("ReplicatedStorage.VoidDice.Config.CharacterConfig")
local RarityConfig = h.requirePath("ReplicatedStorage.VoidDice.Config.RarityConfig")
local Odds = h.requirePath("ReplicatedStorage.VoidDice.Util.Odds")
local Format = h.requirePath("ReplicatedStorage.VoidDice.Util.Format")

local out = {}
local function line(s: string?)
	table.insert(out, s or "")
end

local categories = {}
for _, def in CharacterConfig.List do
	categories[def.Category] = (categories[def.Category] or 0) + 1
end

line("# VOID DICE – Character Index")
line()
line("Automatisch erzeugt aus `src/shared/Config/Characters/*.luau` (`tools/gen_characters.luau`).")
line(string.format("**%d Characters** · Human %d · Creature %d · Entity %d · ★ = Thumbnail-Kandidat",
	#CharacterConfig.List, categories.Human or 0, categories.Creature or 0, categories.Entity or 0))
line()
line("Chance = echte Wahrscheinlichkeit bei Luck 1 (Commons normalisiert).")
line()

local probs = Odds.rarityProbabilities(1)
for _, rarity in RarityConfig.List do
	local list = CharacterConfig.ByRarity[rarity.Id] or {}
	line(string.format("## %s (%d) – Tier %s", rarity.DisplayName, #list, Format.chance(probs[rarity.Id])))
	line()
	line("| | Name | Typ | Chance | $/s | Power | Fishing | Look |")
	line("|---|---|---|---|---|---|---|---|")
	for _, def in list do
		local p = Odds.characterProbability(def.Id, 1)
		local look = (def.VisualTheme or ""):gsub("|", "/")
		line(string.format("| %s | **%s** | %s | %s | %s | %s | %s | %s |",
			if def.Thumbnail then "★" else "", def.DisplayName, def.Category, Format.chance(p),
			Format.short(def.BaseMoneyPerSecond), Format.short(def.BasePower), tostring(def.BaseFishingPower), look))
	end
	line()
	for _, def in list do
		line(string.format("- **%s** – %s *(Body: %s, Anim: %s%s)*", def.DisplayName, (def.Description or ""):gsub("\n", " "),
			def.Visual and def.Visual.Body or "?", def.AnimationSet, if def.AuraReference then ", Aura: " .. def.AuraReference else ""))
	end
	line()
end

fs.writeFile(ROOT .. "/docs/CHARACTERS.md", table.concat(out, "\n"))
print("docs/CHARACTERS.md geschrieben (" .. #CharacterConfig.List .. " Characters)")
