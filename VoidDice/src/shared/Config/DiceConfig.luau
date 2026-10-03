--!strict
-- DiceConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > DiceConfig
--
-- Dice sind dauerhafte Freischaltungen (bleiben bei Rebirth erhalten).
-- Voraussetzung: Gebiet (Area) freigeschaltet. Dann einmalig mit Cash kaufen.
-- Der Spieler rollt immer mit dem ausgerüsteten Dice.
--
--   Luck        Multiplikator auf die Grund-Luck (siehe Logic > Modifiers)
--   RollSpeed   Multiplikator auf die Roll-Geschwindigkeit (1 = normal)
--   Cost        Cash-Preis (wird nach Economy-Simulation angepasst)

export type DiceDef = {
	Id: string,
	DisplayName: string,
	Order: number,
	Area: string,
	Luck: number,
	RollSpeed: number,
	Cost: number,
	Color: Color3,
	Color2: Color3,
	Description: string,
}

local DiceConfig = {}

DiceConfig.Default = "Basic"

DiceConfig.List = {
	{
		Id = "Basic", DisplayName = "BASIC DICE", Order = 1, Area = "Suburb",
		Luck = 1, RollSpeed = 1, Cost = 0,
		Color = Color3.fromRGB(230, 230, 240), Color2 = Color3.fromRGB(120, 120, 140),
		Description = "A scratched game-night die. Everyone starts somewhere.",
	},
	{
		Id = "Strange", DisplayName = "STRANGE DICE", Order = 2, Area = "DarkForest",
		Luck = 2, RollSpeed = 1, Cost = 130000,
		Color = Color3.fromRGB(80, 220, 120), Color2 = Color3.fromRGB(20, 80, 40),
		Description = "Found in the forest. It is always warm.",
	},
	{
		Id = "Rift", DisplayName = "RIFT DICE", Order = 3, Area = "SecretLab",
		Luck = 3, RollSpeed = 1.05, Cost = 19000000,
		Color = Color3.fromRGB(80, 200, 255), Color2 = Color3.fromRGB(30, 60, 160),
		Description = "Lab property. Do not roll near the containment field.",
	},
	{
		Id = "Psychic", DisplayName = "PSYCHIC DICE", Order = 4, Area = "RiftZone",
		Luck = 5, RollSpeed = 1.1, Cost = 170000000,
		Color = Color3.fromRGB(170, 90, 255), Color2 = Color3.fromRGB(60, 20, 140),
		Description = "Lands on the face you were thinking of. Usually.",
	},
	{
		Id = "Void", DisplayName = "VOID DICE", Order = 5, Area = "Otherworld",
		Luck = 8, RollSpeed = 1.15, Cost = 1400000000,
		Color = Color3.fromRGB(110, 40, 230), Color2 = Color3.fromRGB(8, 0, 20),
		Description = "It has more faces than it should.",
	},
	{
		Id = "Anomaly", DisplayName = "ANOMALY DICE", Order = 6, Area = "Void",
		Luck = 12, RollSpeed = 1.2, Cost = 90000000000,
		Color = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(0, 255, 200),
		Description = "Nobody remembers who made it. It remembers you.",
	},
} :: { DiceDef }

DiceConfig.ById = {} :: { [string]: DiceDef }
for _, def in DiceConfig.List do
	DiceConfig.ById[def.Id] = def
end

function DiceConfig.Get(id: string): DiceDef?
	return DiceConfig.ById[id]
end

return DiceConfig
