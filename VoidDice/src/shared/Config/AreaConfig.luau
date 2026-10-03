--!strict
-- AreaConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > AreaConfig
--
-- Die sechs Gebiete. Das erste (Suburb) ist der Hub mit Spawn und Bases.
-- Die anderen liegen hintereinander an der "Signal Road" nach Norden (-Z).
--
-- Freischalten: RequiredRebirths erreicht UND UnlockCost bezahlt.
-- Ein freigeschaltetes Gebiet bringt:
--   * seine Dice (DiceConfig.Area)
--   * sein Fishing-Gewässer (FishingConfig.Waters[...].Area)
--   * Teleport im Menü
--
-- Position/Size beschreiben die Zone (für Licht/Ambience am Client und für
-- Server-Checks). Lighting wird vom Client weich überblendet.

export type AreaDef = {
	Id: string,
	DisplayName: string,
	Order: number,
	Tagline: string,
	RequiredRebirths: number,
	UnlockCost: number,
	Center: Vector3,
	Size: Vector3,
	PrimaryColor: Color3,
	SecondaryColor: Color3,
	GroundColor: Color3,
	GroundMaterial: Enum.Material,
	Lighting: {
		Ambient: Color3,
		OutdoorAmbient: Color3,
		FogColor: Color3,
		FogStart: number,
		FogEnd: number,
		ClockTime: number,
		Brightness: number,
		ColorShift: Color3,
	},
	Ambience: string,
}

local AreaConfig = {}

AreaConfig.List = {
	{
		Id = "Suburb",
		DisplayName = "MYSTERY SUBURB",
		Order = 1,
		Tagline = "A quiet 80s town. Too quiet.",
		RequiredRebirths = 0,
		UnlockCost = 0,
		Center = Vector3.new(0, 0, 0),
		Size = Vector3.new(560, 200, 560),
		PrimaryColor = Color3.fromRGB(255, 120, 60),
		SecondaryColor = Color3.fromRGB(70, 110, 255),
		GroundColor = Color3.fromRGB(46, 66, 44),
		GroundMaterial = Enum.Material.Grass,
		Lighting = {
			Ambient = Color3.fromRGB(70, 64, 100),
			OutdoorAmbient = Color3.fromRGB(86, 80, 120),
			FogColor = Color3.fromRGB(30, 26, 60),
			FogStart = 180,
			FogEnd = 900,
			ClockTime = 20.6,
			Brightness = 1.6,
			ColorShift = Color3.fromRGB(255, 160, 110),
		},
		Ambience = "Suburb",
	},
	{
		Id = "DarkForest",
		DisplayName = "DARK FOREST",
		Order = 2,
		Tagline = "Something moves between the trees.",
		RequiredRebirths = 1,
		UnlockCost = 77000,
		Center = Vector3.new(0, 0, -470),
		Size = Vector3.new(260, 200, 240),
		PrimaryColor = Color3.fromRGB(80, 200, 110),
		SecondaryColor = Color3.fromRGB(30, 60, 40),
		GroundColor = Color3.fromRGB(30, 44, 28),
		GroundMaterial = Enum.Material.Grass,
		Lighting = {
			Ambient = Color3.fromRGB(40, 56, 46),
			OutdoorAmbient = Color3.fromRGB(46, 64, 52),
			FogColor = Color3.fromRGB(20, 34, 26),
			FogStart = 40,
			FogEnd = 420,
			ClockTime = 0,
			Brightness = 1,
			ColorShift = Color3.fromRGB(120, 255, 160),
		},
		Ambience = "Forest",
	},
	{
		Id = "SecretLab",
		DisplayName = "SECRET LAB",
		Order = 3,
		Tagline = "Level B4 does not officially exist.",
		RequiredRebirths = 3,
		UnlockCost = 11000000,
		Center = Vector3.new(0, 0, -750),
		Size = Vector3.new(260, 200, 240),
		PrimaryColor = Color3.fromRGB(230, 236, 255),
		SecondaryColor = Color3.fromRGB(60, 200, 255),
		GroundColor = Color3.fromRGB(70, 74, 82),
		GroundMaterial = Enum.Material.Concrete,
		Lighting = {
			Ambient = Color3.fromRGB(90, 100, 120),
			OutdoorAmbient = Color3.fromRGB(80, 90, 110),
			FogColor = Color3.fromRGB(40, 50, 70),
			FogStart = 120,
			FogEnd = 700,
			ClockTime = 22,
			Brightness = 1.4,
			ColorShift = Color3.fromRGB(160, 220, 255),
		},
		Ambience = "Lab",
	},
	{
		Id = "RiftZone",
		DisplayName = "RIFT ZONE",
		Order = 4,
		Tagline = "Reality is coming apart at the seams.",
		RequiredRebirths = 5,
		UnlockCost = 98000000,
		Center = Vector3.new(0, 0, -1030),
		Size = Vector3.new(260, 240, 240),
		PrimaryColor = Color3.fromRGB(150, 80, 255),
		SecondaryColor = Color3.fromRGB(60, 220, 255),
		GroundColor = Color3.fromRGB(40, 30, 60),
		GroundMaterial = Enum.Material.Slate,
		Lighting = {
			Ambient = Color3.fromRGB(80, 50, 120),
			OutdoorAmbient = Color3.fromRGB(90, 60, 140),
			FogColor = Color3.fromRGB(50, 20, 90),
			FogStart = 60,
			FogEnd = 600,
			ClockTime = 0,
			Brightness = 1.2,
			ColorShift = Color3.fromRGB(180, 110, 255),
		},
		Ambience = "Rift",
	},
	{
		Id = "Otherworld",
		DisplayName = "OTHERWORLD",
		Order = 5,
		Tagline = "The mirror side. Everything is almost right.",
		RequiredRebirths = 8,
		UnlockCost = 840000000,
		Center = Vector3.new(0, 0, -1310),
		Size = Vector3.new(260, 240, 240),
		PrimaryColor = Color3.fromRGB(40, 230, 190),
		SecondaryColor = Color3.fromRGB(255, 90, 170),
		GroundColor = Color3.fromRGB(16, 40, 44),
		GroundMaterial = Enum.Material.Basalt,
		Lighting = {
			Ambient = Color3.fromRGB(30, 80, 80),
			OutdoorAmbient = Color3.fromRGB(30, 90, 90),
			FogColor = Color3.fromRGB(10, 50, 50),
			FogStart = 30,
			FogEnd = 380,
			ClockTime = 3,
			Brightness = 0.9,
			ColorShift = Color3.fromRGB(60, 255, 210),
		},
		Ambience = "Otherworld",
	},
	{
		Id = "Void",
		DisplayName = "THE VOID",
		Order = 6,
		Tagline = "Nothing ends here. Nothing begins.",
		RequiredRebirths = 12,
		UnlockCost = 53000000000,
		Center = Vector3.new(0, 0, -1590),
		Size = Vector3.new(260, 300, 240),
		PrimaryColor = Color3.fromRGB(130, 50, 255),
		SecondaryColor = Color3.fromRGB(10, 0, 20),
		GroundColor = Color3.fromRGB(8, 4, 16),
		GroundMaterial = Enum.Material.Glass,
		Lighting = {
			Ambient = Color3.fromRGB(40, 20, 70),
			OutdoorAmbient = Color3.fromRGB(30, 10, 60),
			FogColor = Color3.fromRGB(6, 0, 14),
			FogStart = 20,
			FogEnd = 500,
			ClockTime = 0,
			Brightness = 0.6,
			ColorShift = Color3.fromRGB(140, 60, 255),
		},
		Ambience = "Void",
	},
} :: { AreaDef }

AreaConfig.ById = {} :: { [string]: AreaDef }
for _, def in AreaConfig.List do
	AreaConfig.ById[def.Id] = def
end

AreaConfig.StartArea = "Suburb"

function AreaConfig.Get(id: string): AreaDef?
	return AreaConfig.ById[id]
end

-- Liegt eine Position in dieser Zone? (Achsen-ausgerichtete Box)
function AreaConfig.Contains(def: AreaDef, position: Vector3): boolean
	local d = position - def.Center
	local h = def.Size / 2
	return math.abs(d.X) <= h.X and math.abs(d.Z) <= h.Z and d.Y >= -20 and d.Y <= def.Size.Y
end

return AreaConfig
