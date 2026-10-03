--!strict
-- Road (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > World > Road
--
-- Die "Signal Road": vom Nordrand der Plaza schnurgerade nach Norden durch alle
-- Gebiete. Zwischen zwei Gebieten liegt jeweils eine Brücke über dem Nichts
-- (mit Geländer und unsichtbaren Wänden, damit niemand herunterfällt).
-- Innerhalb eines Gebiets bekommt die Straße den Look des Gebiets (Farben aus
-- AreaConfig). Die Gebiete selbst halten den Straßenkorridor frei.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))
local AreaConfig = require(ConfigFolder:WaitForChild("AreaConfig"))

local Parts = require(script.Parent:WaitForChild("Parts"))
local Props = require(script.Parent:WaitForChild("Props"))

local Palette = Parts.Palette
local V3 = Vector3.new
local CF = CFrame.new
local Mat = Enum.Material

local Road = {}

local ROAD_TOP = 0.05 -- Oberkante der Straße (Gebietsböden liegen bei -0.1)
local BOUND_HEIGHT = 80

-- Straßenstil je Gebiet
local STYLES: { [string]: { Surface: Color3, Material: Enum.Material, Edge: Color3, Center: Color3, CenterNeon: boolean, Lamp: Color3 } } = {
	Suburb = { Surface = Palette.Asphalt, Material = Mat.Asphalt, Edge = Palette.White, Center = Palette.Yellow, CenterNeon = false, Lamp = Palette.Orange },
	DarkForest = { Surface = Color3.fromRGB(62, 50, 40), Material = Mat.Ground, Edge = Color3.fromRGB(90, 110, 80), Center = Color3.fromRGB(80, 200, 110), CenterNeon = true, Lamp = Color3.fromRGB(150, 255, 170) },
	SecretLab = { Surface = Color3.fromRGB(60, 62, 70), Material = Mat.Concrete, Edge = Palette.Yellow, Center = Color3.fromRGB(60, 200, 255), CenterNeon = true, Lamp = Color3.fromRGB(220, 240, 255) },
	RiftZone = { Surface = Color3.fromRGB(34, 26, 52), Material = Mat.Slate, Edge = Palette.Cyan, Center = Palette.Purple, CenterNeon = true, Lamp = Palette.Purple },
	Otherworld = { Surface = Color3.fromRGB(16, 44, 48), Material = Mat.Basalt, Edge = Palette.Magenta, Center = Palette.Teal, CenterNeon = true, Lamp = Palette.Magenta },
	Void = { Surface = Color3.fromRGB(10, 6, 18), Material = Mat.Glass, Edge = Palette.Purple, Center = Color3.fromRGB(130, 50, 255), CenterNeon = true, Lamp = Color3.fromRGB(130, 50, 255) },
}

local function sortedAreas(): { AreaConfig.AreaDef }
	local list = table.clone(AreaConfig.List)
	table.sort(list, function(a, b)
		return a.Order < b.Order
	end)
	return list
end
Road.SortedAreas = sortedAreas

-- Straßenstück von zStart (Süden, größeres Z) bis zEnd (Norden)
local function strip(model: Model, x: number, zStart: number, zEnd: number, style: any, dashed: boolean)
	local len = zStart - zEnd
	local midZ = (zStart + zEnd) / 2
	local rw = WorldConfig.RoadWidth
	Parts.Box(model, CF(x, ROAD_TOP - 0.5, midZ), V3(rw, 1, len), style.Surface, style.Material, "RoadSurface")
	for _, sx in { -1, 1 } do
		Parts.Detail(model, CF(x + sx * (rw / 2 - 1.4), ROAD_TOP + 0.02, midZ), V3(0.5, 0.06, len - 1), style.Edge, Mat.SmoothPlastic, "EdgeLine")
	end
	if dashed then
		local z = zStart - 6
		while z - 6 > zEnd do
			Parts.Detail(model, CF(x, ROAD_TOP + 0.02, z - 3), V3(0.6, 0.06, 6), style.Center, Mat.SmoothPlastic, "LaneDash")
			z -= 16
		end
	else
		Parts.Part({
			Parent = model,
			Name = "CenterLine",
			CFrame = CF(x, ROAD_TOP + 0.02, midZ),
			Size = V3(0.6, 0.06, len - 4),
			Color = style.Center,
			Material = if style.CenterNeon then Mat.Neon else Mat.SmoothPlastic,
			CanCollide = false,
		})
	end
end

local function lampPair(model: Model, x: number, z: number, color: Color3, height: number?)
	for _, sx in { -1, 1 } do
		local pos = V3(x + sx * (WorldConfig.RoadWidth / 2 + 2.5), WorldConfig.GroundY, z)
		Props.Streetlamp(model, Parts.FaceTowards(pos, V3(x, pos.Y, z)), { Height = height or 15, Color = color })
	end
end

-- Brücke zwischen zwei Gebieten (zSouth > zNorth)
local function bridge(model: Model, bounds: Folder, x: number, zSouth: number, zNorth: number, color: Color3)
	local rw = WorldConfig.RoadWidth
	local len = zSouth - zNorth + 4 -- je 2 Studs Überlappung in die Gebiete
	local midZ = (zSouth + zNorth) / 2
	Parts.Box(model, CF(x, ROAD_TOP - 1.5, midZ), V3(rw + 4, 3, len), Palette.ConcreteDark, Mat.Concrete, "BridgeDeck")
	Parts.Detail(model, CF(x, ROAD_TOP + 0.02, midZ), V3(0.6, 0.06, len - 6), Palette.Yellow, Mat.SmoothPlastic, "CenterLine")
	for _, sx in { -1, 1 } do
		local rx = x + sx * (rw / 2 + 1.2)
		Parts.Box(model, CF(rx, ROAD_TOP + 1.5, midZ), V3(1.6, 3, len), Palette.Metal, Mat.Metal, "Railing")
		Parts.Neon(model, CF(rx, ROAD_TOP + 3.1, midZ), V3(1.7, 0.25, len), color, "RailGlow")
		Parts.Invisible(bounds, CF(x + sx * (rw / 2 + 2), BOUND_HEIGHT / 2, midZ), V3(2, BOUND_HEIGHT, len), "BridgeWall", true)
		Parts.Box(model, CF(x + sx * (rw / 2 - 2), -32, midZ), V3(4, 60, 6), Palette.ConcreteDark, Mat.Concrete, "Pillar")
	end
end

-- Baut die komplette Straße. Unsichtbare Brücken-Wände landen in bounds.
function Road.Build(parent: Instance, bounds: Folder): Model
	local model = Parts.Model(nil, "SignalRoad")
	local x = WorldConfig.HubCenter.X
	local areas = sortedAreas()

	-- 1) Suburb: vom Plaza-Rand bis zum Nordrand des Suburbs
	local suburb = areas[1]
	local zSuburbNorth = suburb.Center.Z - suburb.Size.Z / 2
	local zPlaza = WorldConfig.HubCenter.Z - WorldConfig.PlazaRadius + 2
	strip(model, x, zPlaza, zSuburbNorth, STYLES.Suburb, true)
	local z = zPlaza - 26
	while z > zSuburbNorth + 10 do
		lampPair(model, x, z, STYLES.Suburb.Lamp)
		z -= 48
	end

	-- 2) Gebiete + Brücken
	for i = 2, #areas do
		local prev = areas[i - 1]
		local area = areas[i]
		local style = STYLES[area.Id] or STYLES.Suburb
		local zPrevNorth = prev.Center.Z - prev.Size.Z / 2
		local zSouth = area.Center.Z + area.Size.Z / 2
		local zNorth = area.Center.Z - area.Size.Z / 2
		bridge(model, bounds, x, zPrevNorth, zSouth, area.PrimaryColor)
		lampPair(model, x, (zPrevNorth + zSouth) / 2, area.PrimaryColor, 12)

		local isLast = i == #areas
		local zEnd = if isLast then zNorth + 40 else zNorth
		strip(model, x, zSouth, zEnd, style, false)
		-- Laternen im Gebiet (Gebiete halten diese Positionen frei)
		for _, t in { 0.3, 0.7 } do
			lampPair(model, x, zSouth - (zSouth - zEnd) * t, style.Lamp, 15)
		end
	end
	model.Parent = parent
	return model
end

return Road
