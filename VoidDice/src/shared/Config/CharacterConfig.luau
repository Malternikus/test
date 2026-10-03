--!strict
-- CharacterConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > CharacterConfig
--
-- Die einzige Stelle, an der Characters registriert werden. Die eigentlichen
-- Daten stehen, nach Rarity getrennt, im Ordner Config > Characters. Neue
-- Characters (auch später lizenzierte) werden dort als weitere Tabelle
-- eingetragen. Kein anderes Script muss dafür angepasst werden.
--
-- Felder pro Character:
--   Id                  eindeutig, ohne Leerzeichen (wird gespeichert, NIE umbenennen)
--   DisplayName         Anzeigename
--   Rarity              Id aus RarityConfig
--   RollChance          "1 in X" bei Luck 1. Bei Commons ist das ein relatives
--                       Gewicht: Commons füllen die Restwahrscheinlichkeit auf
--                       (siehe Util > RollMath). Die UI zeigt immer die echte,
--                       normalisierte Chance an.
--   BaseMoneyPerSecond  $/s auf Level 1 ohne Mutation
--   BasePower           Basis-Power (Base Value, später Raid-Verteidigung)
--   BaseFishingPower    Basis-Fishing-Power
--   MaxLevel            Standard 15
--   Category            "Human" | "Creature" | "Entity"
--   VisualTheme         Kurzbeschreibung des Looks
--   Description         Index-Text
--   ModelReference      "Procedural:<Id>" = ModelFactory baut den Placeholder.
--                       Später: "Asset:<Name>" = fertiges Model aus
--                       ReplicatedStorage > VoidDiceAssets > Characters.
--   AuraReference       Id aus Visual > AuraLibrary oder nil
--   AnimationSet        Idle-Set für den BaseAnimator (siehe UIConfig.AnimationSets)
--   Thumbnail           true = als Thumbnail/Icon-Kandidat markiert
--   Source              "Original" für eigene IP. Lizenzierte Inhalte bekommen
--                       hier den Lizenzgeber und können über ReleaseEnabled
--                       ein- oder ausgeschaltet werden.
--   ReleaseEnabled      false = nicht rollbar (z. B. Testfiguren, abgelaufene Lizenz)
--   Visual              Bauplan für den ModelFactory-Placeholder

local Characters = script.Parent:WaitForChild("Characters")

export type VisualSpec = {
	Body: string,
	Scale: number?,
	Skin: Color3?,
	Hair: Color3?,
	HairStyle: string?,
	Top: Color3?,
	Bottom: Color3?,
	Shoes: Color3?,
	Accent: Color3?,
	Glow: Color3?,
	Face: string?,
	Accessories: { string }?,
}

export type CharacterDef = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	RollChance: number,
	BaseMoneyPerSecond: number,
	BasePower: number,
	BaseFishingPower: number,
	MaxLevel: number,
	Category: string,
	VisualTheme: string,
	Description: string,
	ModelReference: string,
	AuraReference: string?,
	AnimationSet: string,
	Thumbnail: boolean?,
	Source: string,
	ReleaseEnabled: boolean,
	Visual: VisualSpec,
	-- vom Loader ergänzt:
	Index: number,
}

local RARITY_FILES = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Supernatural",
	"Void",
	"Secret",
	"Anomaly",
}

local CharacterConfig = {}
CharacterConfig.DefaultMaxLevel = 15

CharacterConfig.List = {} :: { CharacterDef }
CharacterConfig.ById = {} :: { [string]: CharacterDef }
CharacterConfig.ByRarity = {} :: { [string]: { CharacterDef } }

for _, fileName in RARITY_FILES do
	local module = Characters:FindFirstChild(fileName)
	if module then
		local entries = require(module) :: any
		for _, raw in entries do
			local def = raw :: CharacterDef
			assert(type(def.Id) == "string" and def.Id ~= "", "Character ohne Id in " .. fileName)
			assert(CharacterConfig.ById[def.Id] == nil, "Doppelte Character-Id: " .. def.Id)
			def.MaxLevel = def.MaxLevel or CharacterConfig.DefaultMaxLevel
			def.ModelReference = def.ModelReference or ("Procedural:" .. def.Id)
			def.Source = def.Source or "Original"
			if def.ReleaseEnabled == nil then
				def.ReleaseEnabled = true
			end
			def.AnimationSet = def.AnimationSet or "Default"
			def.Category = def.Category or "Human"
			table.insert(CharacterConfig.List, def)
			def.Index = #CharacterConfig.List
			CharacterConfig.ById[def.Id] = def
			local bucket = CharacterConfig.ByRarity[def.Rarity]
			if not bucket then
				bucket = {}
				CharacterConfig.ByRarity[def.Rarity] = bucket
			end
			table.insert(bucket, def)
		end
	end
end

function CharacterConfig.Get(id: string): CharacterDef?
	return CharacterConfig.ById[id]
end

return CharacterConfig
