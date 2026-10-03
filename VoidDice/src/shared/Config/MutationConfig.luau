--!strict
-- MutationConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > MutationConfig
--
-- Nach jedem Roll würfelt der Server zusätzlich, ob der Character eine Mutation
-- bekommt. Mutationen sind NUR erspielbar (Roll, später Events). Sie werden
-- nicht gegen Robux verkauft.
--
--   Chance          "1 in X" pro Roll (unabhängig vom Character)
--   MoneyMultiplier multipliziert $/s
--   PowerMultiplier multipliziert Power
--   Tint            Farbe, mit der ModelFactory Kleidung/Körper einfärbt
--   TintStrength    0..1 (wie stark gemischt wird)
--   Material        optionales Material für Kleidung
--   Effect          Partikel-Effekt-Id (Visual > AuraLibrary)
--   LuckScaling     Anteil der Roll-Luck, der auf die Mutation wirkt
--                   (0 = gar nicht, 1 = voll). Klein halten, sonst werden
--                   Mutationen im Late Game Standard.

export type MutationDef = {
	Id: string,
	DisplayName: string,
	Order: number,
	Chance: number,
	MoneyMultiplier: number,
	PowerMultiplier: number,
	Color: Color3,
	Tint: Color3?,
	TintStrength: number,
	Material: Enum.Material?,
	Effect: string?,
	LuckScaling: number,
	Announce: boolean,
}

local MutationConfig = {}

MutationConfig.None = "Normal"

MutationConfig.List = {
	{
		Id = "Normal", DisplayName = "NORMAL", Order = 0, Chance = 1,
		MoneyMultiplier = 1, PowerMultiplier = 1,
		Color = Color3.fromRGB(200, 200, 210), Tint = nil, TintStrength = 0,
		Material = nil, Effect = nil, LuckScaling = 0, Announce = false,
	},
	{
		Id = "Electric", DisplayName = "ELECTRIC", Order = 1, Chance = 40,
		MoneyMultiplier = 1.5, PowerMultiplier = 1.25,
		Color = Color3.fromRGB(90, 200, 255), Tint = Color3.fromRGB(90, 200, 255), TintStrength = 0.35,
		Material = nil, Effect = "ElectricSparks", LuckScaling = 0.15, Announce = false,
	},
	{
		Id = "Shadow", DisplayName = "SHADOW", Order = 2, Chance = 80,
		MoneyMultiplier = 2, PowerMultiplier = 1.5,
		Color = Color3.fromRGB(70, 60, 90), Tint = Color3.fromRGB(20, 16, 30), TintStrength = 0.6,
		Material = nil, Effect = "ShadowSmoke", LuckScaling = 0.15, Announce = false,
	},
	{
		Id = "BloodMoon", DisplayName = "BLOOD MOON", Order = 3, Chance = 200,
		MoneyMultiplier = 3, PowerMultiplier = 2,
		Color = Color3.fromRGB(220, 30, 40), Tint = Color3.fromRGB(170, 20, 30), TintStrength = 0.5,
		Material = nil, Effect = "BloodMist", LuckScaling = 0.15, Announce = false,
	},
	{
		Id = "Rift", DisplayName = "RIFT", Order = 4, Chance = 400,
		MoneyMultiplier = 4, PowerMultiplier = 2.5,
		Color = Color3.fromRGB(150, 80, 255), Tint = Color3.fromRGB(120, 60, 230), TintStrength = 0.45,
		Material = Enum.Material.Glass, Effect = "RiftCracks", LuckScaling = 0.15, Announce = false,
	},
	{
		Id = "Golden", DisplayName = "GOLDEN", Order = 5, Chance = 1000,
		MoneyMultiplier = 6, PowerMultiplier = 3,
		Color = Color3.fromRGB(255, 205, 60), Tint = Color3.fromRGB(255, 196, 40), TintStrength = 0.75,
		Material = Enum.Material.Metal, Effect = "GoldSparkle", LuckScaling = 0.15, Announce = true,
	},
	{
		Id = "Void", DisplayName = "VOID", Order = 6, Chance = 5000,
		MoneyMultiplier = 10, PowerMultiplier = 5,
		Color = Color3.fromRGB(110, 30, 255), Tint = Color3.fromRGB(8, 2, 20), TintStrength = 0.85,
		Material = Enum.Material.Neon, Effect = "VoidVortex", LuckScaling = 0.15, Announce = true,
	},
} :: { MutationDef }

MutationConfig.ById = {} :: { [string]: MutationDef }
for _, def in MutationConfig.List do
	MutationConfig.ById[def.Id] = def
end

function MutationConfig.Get(id: string?): MutationDef
	return MutationConfig.ById[id or "Normal"] or MutationConfig.ById.Normal
end

return MutationConfig
