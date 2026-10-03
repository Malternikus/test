--!strict
-- Hub (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > World > Hub
--
-- Mystery Suburb: Boden über das ganze Suburb-Gebiet, Roll Plaza mit
-- schwebendem Würfel, SpawnLocation, die fünf Stationen, die Leaderboard-Wand,
-- eine achteckige Ringstraße vor den Plot-Eingängen und 80er-Vorstadt-Deko
-- (Häuser, Zäune, Laternen, Bäume) in den Lücken zwischen den Plots.
--
-- Vertrag mit den Services:
--   Hub/PlazaDie                     Model (PrimaryPart "Core"), schwebt über der Plaza
--   Hub/SpawnLocation                Neutral, Duration 0
--   Hub/Stations/<Name>Station       ShopStation, RebirthStation, IndexStation,
--                                    QuestStation, FishingStation; je ein Part
--                                    "PromptPart" (unsichtbar, für ProximityPrompt)
--                                    und Attribut StationId (= Schlüssel in WorldConfig.Stations)
--   Hub/LeaderboardWall/Board_*      5 leere Tafeln, Front-Fläche zeigt zur Plaza

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))
local AreaConfig = require(ConfigFolder:WaitForChild("AreaConfig"))
local DiceConfig = require(ConfigFolder:WaitForChild("DiceConfig"))

local Parts = require(script.Parent:WaitForChild("Parts"))
local Props = require(script.Parent:WaitForChild("Props"))

local Palette = Parts.Palette
local V3 = Vector3.new
local CF = CFrame.new
local Mat = Enum.Material

local Hub = {}

-- Reihenfolge = Reihenfolge an der Wand (links -> rechts, von der Plaza aus gesehen)
Hub.BoardNames = {
	"Board_MostRolls",
	"Board_MostRebirths",
	"Board_TotalCash",
	"Board_RarestCollection",
	"Board_BaseValue",
}

Hub.StationModelNames = {
	Shop = "ShopStation",
	Rebirth = "RebirthStation",
	Index = "IndexStation",
	Quests = "QuestStation",
	Fishing = "FishingStation",
}

local RING_APOTHEM = 162 -- Ringstraße: Abstand Mitte -> Straßenmitte (vor den Plot-Eingängen)
local RING_WIDTH = 14

-- Liegt pos (XZ) innerhalb eines Plots (+ margin)?
function Hub.InsidePlot(pos: Vector3, margin: number): boolean
	local hx = WorldConfig.PlotSize.X / 2 + margin
	local hz = WorldConfig.PlotSize.Z / 2 + margin
	for i = 1, WorldConfig.PlotCount do
		local rel = WorldConfig.PlotCFrame(i):PointToObjectSpace(V3(pos.X, WorldConfig.GroundY, pos.Z))
		if math.abs(rel.X) < hx and math.abs(rel.Z) < hz then
			return true
		end
	end
	return false
end

-- Peilung (Grad, 0 = Norden/-Z, im Uhrzeigersinn) + Radius -> Weltposition
local function polar(bearingDeg: number, radius: number): Vector3
	local a = math.rad(bearingDeg)
	local c = WorldConfig.HubCenter
	return V3(c.X + math.sin(a) * radius, WorldConfig.GroundY, c.Z - math.cos(a) * radius)
end

-------------------------------------------------------------------------------
-- Stationen
-------------------------------------------------------------------------------

type BoothOpts = {
	Width: number,
	Depth: number,
	Height: number,
	Wall: Color3,
	WallMaterial: Enum.Material,
	Trim: Color3,
	Title: string,
	Subtitle: string?,
}

-- Grundbude: Plattform, Rück-/Seitenwände, Dach mit Neonkante, Theke vorne,
-- Schild auf dem Dach. Front (Theke) zeigt zur Plaza (-Z lokal).
local function booth(m: Model, cf: CFrame, o: BoothOpts): BasePart
	local w, d, h = o.Width, o.Depth, o.Height
	Parts.Box(m, cf * CF(0, 0.3, 0), V3(w, 0.6, d), Palette.WoodDark, Mat.WoodPlanks, "Platform")
	Parts.Box(m, cf * CF(0, h / 2, d / 2 - 0.3), V3(w, h, 0.6), o.Wall, o.WallMaterial, "BackWall")
	for _, sx in { -1, 1 } do
		Parts.Box(m, cf * CF(sx * (w / 2 - 0.3), h / 2, d * 0.15), V3(0.6, h, d * 0.7), o.Wall, o.WallMaterial, "SideWall")
		Parts.Box(m, cf * CF(sx * (w / 2 - 0.3), h / 2, -d / 2 + 0.3), V3(0.6, h, 0.6), Palette.WoodDark, Mat.Wood, "Post")
	end
	Parts.Box(m, cf * CF(0, h + 0.3, 0.3), V3(w + 2, 0.6, d + 2), Palette.Navy, Mat.Slate, "Roof")
	Parts.Neon(m, cf * CF(0, h - 0.05, -d / 2 - 0.65), V3(w + 2, 0.35, 0.3), o.Trim, "RoofTrim")
	Parts.Box(m, cf * CF(0, 1.6, -d / 2 + 1.6), V3(w - 3, 3.2, 1.6), o.Wall, o.WallMaterial, "Counter")
	local sign = Parts.Box(m, cf * CF(0, h + 2.2, -d / 2 + 0.3), V3(w * 0.85, 3, 0.4), Palette.Night, Mat.SmoothPlastic, "Sign")
	Parts.SurfaceLabel(sign, Enum.NormalId.Front, o.Title, o.Subtitle, {
		Name = "SignGui",
		TitleColor = o.Trim,
		SubtitleColor = Palette.White,
		PixelsPerStud = 20,
	})
	return sign
end

local function promptPart(m: Model, cf: CFrame): BasePart
	return Parts.Invisible(m, cf, V3(4, 4, 4), "PromptPart", false)
end

local function stationTitle(anchor: BasePart, title: string, subtitle: string, color: Color3)
	Parts.Billboard(anchor, title, subtitle, {
		Name = "TitleGui",
		Offset = V3(0, 5, 0),
		Width = 18,
		Height = 5,
		TitleColor = color,
		MaxDistance = 220,
	})
end

local function buildShop(m: Model, cf: CFrame)
	local trim = Palette.Orange
	local sign = booth(m, cf, {
		Width = 16,
		Depth = 10,
		Height = 9,
		Wall = Palette.Wood,
		WallMaterial = Mat.WoodPlanks,
		Trim = trim,
		Title = "MILBROOK SURPLUS",
		Subtitle = "TRADING POST",
	})
	stationTitle(sign, "SHOP", "DICE & GEAR", trim)
	-- Regale mit Waren an der Rückwand
	for _, y in { 4, 6.4 } do
		Parts.Box(m, cf * CF(0, y, 3.6), V3(13, 0.3, 1.4), Palette.WoodDark, Mat.Wood, "Shelf")
	end
	local wares = { Palette.Red, Palette.Yellow, Palette.Cyan, Palette.Green, Palette.Magenta, Palette.White }
	for i, c in wares do
		local x = -5 + ((i - 1) % 3) * 5
		local y = if i <= 3 then 4.75 else 7.15
		Parts.Box(m, cf * CF(x, y, 3.6), V3(1.4, 1.2, 1), c, Mat.SmoothPlastic, "Ware")
	end
	Props.Crate(m, cf * CF(10.2, 0, -2.5))
	Props.Crate(m, cf * CF(10.2, 3, -2.5) * CFrame.Angles(0, 0.3, 0), { Size = 2.6 })
	Props.Crate(m, cf * CF(10.6, 0, 1.2), { Size = 2.6 })
	Props.ArcadeCabinet(m, cf * CF(-10.5, 0, -2), { Title = "VOID RUN", Color = trim })
	local prompt = promptPart(m, cf * CF(0, 3, -7))
	Parts.Light(prompt, trim, 18, 1.3)
end

local function buildRebirth(m: Model, cf: CFrame)
	local glow = Palette.Purple
	Parts.VCyl(m, cf * CF(0, 0.5, 0), 1, 16, Palette.MetalDark, Mat.DiamondPlate, "Base")
	Parts.VCyl(m, cf * CF(0, 0.35, 0), 0.7, 16.8, glow, Mat.Neon, "BaseGlow")
	for _, sx in { -1, 1 } do
		Parts.Box(m, cf * CF(sx * 6, 6, 0), V3(2, 11, 2), Palette.Metal, Mat.Metal, "Pillar")
		for k = 1, 3 do
			Parts.VCyl(m, cf * CF(sx * 6, 2.5 + k * 2.4, 0), 0.4, 2.8, glow, Mat.Neon, "Coil")
		end
	end
	Parts.Box(m, cf * CF(0, 12, 0), V3(14.5, 1.4, 2.4), Palette.Metal, Mat.Metal, "TopBar")
	Parts.Ring(m, cf * CF(0, 6.4, 0), 4.6, 12, 0.9, 1.2, glow, Mat.Neon, "RiftRing")
	local rift = Parts.Part({
		Parent = m,
		Name = "Rift",
		Shape = Enum.PartType.Cylinder,
		CFrame = cf * CF(0, 6.4, 0) * CFrame.Angles(0, math.pi / 2, 0),
		Size = V3(0.3, 8.6, 8.6),
		Color = Color3.fromRGB(190, 90, 255),
		Material = Mat.Neon,
		Transparency = 0.15,
		CanCollide = false,
	})
	Parts.Light(rift, glow, 24, 2)
	Parts.Particles(rift, { Color = Palette.Magenta, Rate = 8, Size = 0.4 })
	local sign = Parts.Box(m, cf * CF(0, 14, 0), V3(13, 2.6, 0.4), Palette.Night, Mat.SmoothPlastic, "Sign")
	Parts.SurfaceLabel(sign, Enum.NormalId.Front, "REBIRTH CHAMBER", nil, { Name = "SignGui", TitleColor = glow })
	stationTitle(sign, "REBIRTH", "RESET FOR POWER", glow)
	-- Konsole vor der Maschine
	Parts.Box(m, cf * CF(0, 1.8, -5) * CFrame.Angles(math.rad(-15), 0, 0), V3(4, 2.4, 1.6), Palette.Navy, Mat.Metal, "Console")
	Parts.Neon(m, cf * CF(0, 3.1, -5.3) * CFrame.Angles(math.rad(-40), 0, 0), V3(3.2, 0.1, 1), Palette.Cyan, "ConsoleScreen")
	for _, sx in { -1, 1 } do
		Parts.Beam(m, cf * V3(sx * 6, 1.1, -1), cf * V3(sx * 1.6, 1.1, -5), 0.35, Palette.Black, Mat.Rubber, "Cable")
	end
	promptPart(m, cf * CF(0, 3, -8))
end

local function buildIndex(m: Model, cf: CFrame)
	local trim = Palette.Cyan
	local sign = booth(m, cf, {
		Width = 14,
		Depth = 10,
		Height = 9,
		Wall = Palette.NavyLight,
		WallMaterial = Mat.Metal,
		Trim = trim,
		Title = "COUNTY RECORDS",
		Subtitle = "ARCHIVE",
	})
	stationTitle(sign, "INDEX", "YOUR COLLECTION", trim)
	for i = 0, 3 do
		local x = -4.5 + i * 3
		Parts.Box(m, cf * CF(x, 3.1, 3.6), V3(2.6, 5, 2), Palette.Metal, Mat.Metal, "FilingCabinet")
		Parts.Neon(m, cf * CF(x, 4.6, 2.58), V3(1.6, 0.18, 0.06), if i % 2 == 0 then trim else Palette.Amber, "DrawerLabel")
	end
	Props.CRT(m, cf * CF(-2.5, 3.2, -3.4), { ScreenColor = trim, Text = "INDEX\n> LOAD" })
	Parts.Box(m, cf * CF(3, 3.6, -3.4) * CFrame.Angles(0, 0.2, 0), V3(2, 0.8, 1.5), Palette.Paper, Mat.SmoothPlastic, "Papers")
	Parts.Box(m, cf * CF(4.8, 3.45, -3.2) * CFrame.Angles(0, -0.3, 0), V3(1.6, 0.5, 1.2), Palette.Paper, Mat.SmoothPlastic, "Papers")
	local prompt = promptPart(m, cf * CF(0, 3, -7))
	Parts.Light(prompt, trim, 18, 1.2)
end

local function buildQuests(m: Model, cf: CFrame)
	local trim = Palette.Yellow
	for _, sx in { -1, 1 } do
		Parts.Box(m, cf * CF(sx * 7.5, 5.5, 0.4), V3(1, 11, 1), Palette.WoodDark, Mat.Wood, "Post")
	end
	Parts.Box(m, cf * CF(0, 6, 0.4), V3(15.4, 8.4, 0.6), Palette.WoodDark, Mat.Wood, "Frame")
	Parts.Box(m, cf * CF(0, 6, 0.05), V3(14, 7, 0.2), Palette.Cork, Mat.Fabric, "Cork")
	Parts.Box(m, cf * CF(0, 11, 0) * CFrame.Angles(math.rad(-20), 0, 0), V3(17, 0.5, 3), Palette.Navy, Mat.Slate, "Roof")
	local notes = {
		{ -5, 8, Palette.Paper },
		{ -2, 7.6, Color3.fromRGB(250, 236, 140) },
		{ 1.5, 8.1, Palette.Paper },
		{ 5, 7.7, Color3.fromRGB(255, 180, 190) },
		{ -4.2, 4.6, Palette.Paper },
		{ -0.6, 4.4, Color3.fromRGB(180, 220, 255) },
		{ 3, 4.8, Palette.Paper },
		{ 5.6, 4.2, Palette.Paper },
	}
	for i, n in notes do
		Parts.Detail(m, cf * CF(n[1], n[2], -0.1) * CFrame.Angles(0, 0, (i % 3 - 1) * 0.08), V3(2.2, 2.6, 0.05), n[3], Mat.SmoothPlastic, "Note")
		if i % 2 == 1 then
			Parts.Ball(m, cf * CF(n[1], n[2] + 1.1, -0.18), 0.3, Palette.Red, Mat.Neon, "Pin")
		end
	end
	for _, sx in { -4, 4 } do
		Parts.Neon(m, cf * CF(sx, 10.2, -1), V3(1.6, 0.4, 0.6), trim, "Lamp")
	end
	local sign = Parts.Box(m, cf * CF(0, 12.4, -0.4), V3(12, 2.4, 0.4), Palette.Night, Mat.SmoothPlastic, "Sign")
	Parts.SurfaceLabel(sign, Enum.NormalId.Front, "NOTICE BOARD", nil, { Name = "SignGui", TitleColor = trim })
	stationTitle(sign, "QUESTS", "HELP WANTED", trim)
	Props.Bench(m, cf * CF(-10.5, 0, -1) * CFrame.Angles(0, math.rad(-30), 0), { Width = 5 })
	local prompt = promptPart(m, cf * CF(0, 3, -3.5))
	Parts.Light(prompt, trim, 16, 1.2)
end

local function buildFishing(m: Model, cf: CFrame)
	local trim = Palette.Teal
	local sign = booth(m, cf, {
		Width = 14,
		Depth = 10,
		Height = 9,
		Wall = Color3.fromRGB(70, 110, 120),
		WallMaterial = Mat.WoodPlanks,
		Trim = trim,
		Title = "BAIT & TACKLE",
		Subtitle = "RIFT FISHING",
	})
	stationTitle(sign, "FISHING", "RODS & BAIT", trim)
	for i = 0, 2 do
		local x = 7.6 + i * 0.6
		Parts.Beam(m, cf * V3(x, 0.2, -2 + i * 1.4), cf * V3(x - 0.2, 8.5, -1.2 + i * 1.4), 0.15, Palette.WoodLight, Mat.Wood, "FishingRod")
	end
	Parts.Box(m, cf * CF(-9, 1.2, -2.5), V3(3, 2.4, 2), Palette.White, Mat.SmoothPlastic, "Cooler")
	Parts.Box(m, cf * CF(-9, 2.55, -2.5), V3(3.1, 0.3, 2.1), Palette.ElectricBlue, Mat.SmoothPlastic, "CoolerLid")
	Parts.VCyl(m, cf * CF(-9, 0.6, 0.4), 1.2, 1.4, Palette.Red, Mat.Metal, "BaitBucket")
	-- Leuchtfisch auf dem Dach
	local fish = Parts.Neon(m, cf * CF(0, 14.6, 0.5), V3(5, 2.2, 0.6), trim, "FishSign")
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = fish
	Parts.Neon(m, cf * CF(3.2, 14.6, 0.5) * CFrame.Angles(0, 0, math.rad(45)), V3(1.6, 1.6, 0.4), trim, "FishTail")
	Parts.Cyl(m, cf * CF(5.5, 5, 4.6) * CFrame.Angles(0, math.pi / 2, 0), 0.4, 2.6, Palette.Red, Mat.SmoothPlastic, "LifeRing")
	local prompt = promptPart(m, cf * CF(0, 3, -7))
	Parts.Light(prompt, trim, 18, 1.2)
end

local STATION_BUILDERS: { [string]: (Model, CFrame) -> () } = {
	Shop = buildShop,
	Rebirth = buildRebirth,
	Index = buildIndex,
	Quests = buildQuests,
	Fishing = buildFishing,
}

-------------------------------------------------------------------------------
-- Leaderboard-Wand
-------------------------------------------------------------------------------

local BOARD_SIZE = V3(14, 18, 1)
local BOARD_GAP = 3

local function buildLeaderboards(hub: Model, pos: Vector3): (Model, { [string]: BasePart })
	local m = Parts.Model(hub, "LeaderboardWall")
	-- Front (-Z lokal) zeigt zur Plaza
	local cf = Parts.FaceTowards(pos, WorldConfig.HubCenter)
	local n = #Hub.BoardNames
	local total = n * BOARD_SIZE.X + (n - 1) * BOARD_GAP
	Parts.Box(m, cf * CF(0, 0.5, 0.5), V3(total + 6, 1, 8), Palette.ConcreteDark, Mat.Concrete, "Base")
	Parts.Box(m, cf * CF(0, 12, 1.4), V3(total + 4, 22, 1), Palette.Navy, Mat.Slate, "Backing")
	for _, sx in { -1, 1 } do
		Parts.Box(m, cf * CF(sx * (total / 2 + 2.5), 13, 1), V3(2, 26, 2), Palette.NavyLight, Mat.Metal, "Pillar")
		Parts.Ball(m, cf * CF(sx * (total / 2 + 2.5), 26.6, 1), 1.6, Palette.Purple, Mat.Neon, "PillarCap")
	end
	local header = Parts.Box(m, cf * CF(0, 24.6, 1), V3(40, 4, 0.8), Palette.Night, Mat.SmoothPlastic, "Header")
	Parts.SurfaceLabel(header, Enum.NormalId.Front, "HALL OF RECORDS", nil, { Name = "HeaderGui", TitleColor = Palette.Amber })
	Parts.Neon(m, cf * CF(0, 22.4, 0.7), V3(total + 4, 0.4, 0.4), Palette.Purple, "HeaderTrim")

	local boards: { [string]: BasePart } = {}
	for i, name in Hub.BoardNames do
		local x = -total / 2 + BOARD_SIZE.X / 2 + (i - 1) * (BOARD_SIZE.X + BOARD_GAP)
		local y = 2 + BOARD_SIZE.Y / 2
		Parts.Neon(m, cf * CF(x, y, 0.75), V3(BOARD_SIZE.X + 0.8, BOARD_SIZE.Y + 0.8, 0.3), Palette.ElectricBlue, "BoardFrame")
		local board = Parts.Part({
			Parent = m,
			Name = name,
			CFrame = cf * CF(x, y, 0),
			Size = BOARD_SIZE,
			Color = Palette.Night,
			Material = Mat.SmoothPlastic,
		})
		boards[name] = board
	end
	return m, boards
end

-------------------------------------------------------------------------------
-- Plaza + Würfel-Statue
-------------------------------------------------------------------------------

local function buildPlaza(hub: Model, decor: Folder)
	local c = WorldConfig.HubCenter
	local r = WorldConfig.PlazaRadius
	local base = CF(c.X, WorldConfig.GroundY, c.Z)
	Parts.VCyl(decor, base * CF(0, -0.4, 0), 1, r * 2, Color3.fromRGB(54, 50, 74), Mat.Pavement, "Plaza")
	Parts.VCyl(decor, base * CF(0, -0.45, 0), 0.9, r * 2 + 2, Palette.Purple, Mat.Neon, "PlazaRing")
	Parts.VCyl(decor, base * CF(0, -0.35, 0), 1, 30, Palette.Navy, Mat.Slate, "InnerCircle")
	Parts.VCyl(decor, base * CF(0, -0.38, 0), 1, 31.4, Palette.ElectricBlue, Mat.Neon, "InnerRing")
	for k = 0, 7 do
		local a = math.rad(k * 45 + 22.5)
		local mid = (15.7 + r) / 2
		Parts.Neon(decor, base * CFrame.Angles(0, -a, 0) * CF(0, 0.12, -mid), V3(0.5, 0.06, r - 15.7), Palette.PurpleDeep, "PlazaLine")
	end
	-- Sockel mit Lichtsäule
	Parts.VCyl(decor, base * CF(0, 1, 0), 2, 12, Palette.NavyLight, Mat.Slate, "Pedestal")
	Parts.VCyl(decor, base * CF(0, 1.9, 0), 0.4, 12.6, Palette.Purple, Mat.Neon, "PedestalRing")
	Parts.Part({
		Parent = decor,
		Name = "LightColumn",
		Shape = Enum.PartType.Cylinder,
		CFrame = base * CF(0, 6, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Size = V3(8, 3, 3),
		Color = Color3.fromRGB(180, 140, 255),
		Material = Mat.Neon,
		Transparency = 0.55,
		CanCollide = false,
	})
	-- Schwebender Würfel (Basic-Dice-Farben, gekippt -> Ecke nach oben)
	local basic = DiceConfig.Get(DiceConfig.Default)
	local dieCf = base * CF(0, 17, 0) * CFrame.Angles(math.rad(35.26), 0, math.rad(45))
	local die = Props.Die(hub, dieCf, {
		Name = "PlazaDie",
		Size = 10,
		Color = if basic then basic.Color else Palette.White,
		PipColor = Palette.Purple,
	})
	Parts.Light(die.PrimaryPart :: BasePart, Palette.Purple, 30, 2)
	-- Bänke und Laternen
	for k = 0, 3 do
		local pos = polar(45 + k * 90, r - 7)
		Props.Bench(decor, Parts.FaceTowards(pos, c))
	end
	for k = 0, 5 do
		local pos = polar(30 + k * 60, r - 2.5)
		Props.Streetlamp(decor, Parts.FaceTowards(pos, c), { Height = 13, Color = Palette.Amber, Light = true, Range = 30 })
	end
end

-------------------------------------------------------------------------------
-- Ringstraße (Achteck, Kanten vor den Plot-Eingängen)
-------------------------------------------------------------------------------

local function buildRingStreet(decor: Folder)
	local segLen = 2 * RING_APOTHEM * math.tan(math.rad(22.5)) + 2
	for k = 0, 7 do
		local bearing = WorldConfig.PlotAngleOffset + k * 45
		local pos = polar(bearing, RING_APOTHEM)
		local cf = Parts.FaceTowards(pos, WorldConfig.HubCenter)
		local top = if k % 2 == 0 then 0 else 0.012
		Parts.Box(decor, cf * CF(0, top - 0.5, 0), V3(segLen, 1, RING_WIDTH), Palette.Asphalt, Mat.Asphalt, "RingStreet")
		-- Mittellinie (ein Streifen pro Segment)
		Parts.Box(decor, cf * CF(0, top + 0.02, 0), V3(segLen * 0.7, 0.06, 0.4), Palette.Yellow, Mat.SmoothPlastic, "LaneLine")
		local corner = polar(k * 45, RING_APOTHEM / math.cos(math.rad(22.5)))
		Parts.VCyl(decor, CF(corner.X, 0.02 - 0.5, corner.Z), 1, RING_WIDTH + 1.5, Palette.Asphalt, Mat.Asphalt, "RingCorner")
	end
end

-------------------------------------------------------------------------------
-- Vorstadt-Deko
-------------------------------------------------------------------------------

local function buildSuburbDecor(decor: Folder, rng: Random)
	local c = WorldConfig.HubCenter
	local houseSpots = {}
	local function addHouse(bearing: number, radius: number)
		local pos = polar(bearing, radius)
		local cf = Parts.FaceTowards(pos, c)
		local w = rng:NextInteger(20, 24)
		local d = 16
		Props.House(decor, cf, {
			Width = w,
			Depth = d,
			Height = rng:NextInteger(9, 11),
			Color = Parts.HouseColors[rng:NextInteger(1, #Parts.HouseColors)],
			Garage = rng:NextNumber() < 0.5,
			Lit = rng:NextNumber() < 0.7,
		})
		-- Vorgarten: Zaun mit Lücke, Briefkasten, zwei Tannen
		for _, sx in { -1, 1 } do
			Props.PicketFence(decor, cf * CF(sx * (w / 4 + 1.5), 0, -(d / 2 + 7)), { Length = w / 2 - 3 })
			Props.PineTree(decor, cf * CF(sx * (w / 2 + 8), 0, 2), { Height = rng:NextNumber(16, 22), Tiers = 3 })
		end
		Props.Mailbox(decor, cf * CF(w / 2 - 1, 0, -(d / 2 + 9.5)))
		table.insert(houseSpots, pos)
	end
	for _, bearing in { 45, 90, 135, 180, 225, 270, 315 } do
		addHouse(bearing, 252)
	end
	for _, bearing in { 45, 135, 225, 315 } do
		addHouse(bearing, 345)
	end
	-- Ein paar Fahrzeuge vor den Häusern
	Props.Van(decor, Parts.FaceTowards(polar(84, 226), c) * CFrame.Angles(0, math.pi / 2, 0), { Color = Palette.White, StripeColor = Palette.Red })
	Props.Bicycle(decor, Parts.FaceTowards(polar(186, 232), c) * CFrame.Angles(0, 1.2, 0), { Color = Palette.Red, Lean = 0.15 })
	Props.Bicycle(decor, Parts.FaceTowards(polar(174, 232), c) * CFrame.Angles(0, 1.6, 0), { Color = Palette.ElectricBlue, Lean = -0.15 })

	-- Laternen an den Ecken der Ringstraße (außer Norden: dort ist die Road)
	for k = 1, 7 do
		local pos = polar(k * 45, RING_APOTHEM / math.cos(math.rad(22.5)) + 10)
		Props.Streetlamp(decor, Parts.FaceTowards(pos, c), { Height = 14 })
	end

	-- Baumgürtel am Rand des Suburbs (nicht in Plots, nicht auf der Road, nicht an Häusern)
	local suburb = AreaConfig.Get("Suburb")
	assert(suburb, "AreaConfig: Suburb fehlt")
	local hx, hz = suburb.Size.X / 2 - 7, suburb.Size.Z / 2 - 7
	local roadClear = WorldConfig.RoadWidth / 2 + 12
	local function tryTree(x: number, z: number)
		local pos = V3(suburb.Center.X + x, WorldConfig.GroundY, suburb.Center.Z + z)
		if Hub.InsidePlot(pos, 6) then
			return
		end
		if z < 0 and math.abs(x) < roadClear then
			return
		end
		for _, h in houseSpots do
			if (h - pos).Magnitude < 24 then
				return
			end
		end
		local jitter = V3(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
		Props.PineTree(decor, CF(pos + jitter) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), {
			Height = rng:NextNumber(22, 32),
			Tiers = 2,
			Color = if rng:NextNumber() < 0.5 then Palette.Leaf else Palette.LeafDark,
		})
	end
	local step = 24
	local x = -hx
	while x <= hx do
		tryTree(x, -hz)
		tryTree(x, hz)
		x += step
	end
	local z = -hz + step
	while z <= hz - step do
		tryTree(-hx, z)
		tryTree(hx, z)
		z += step
	end

	-- Arcade-Ecke östlich der Plaza (Gegenstück zur Fishing-Station im Westen)
	local arcadePos = V3(c.X + 86, WorldConfig.GroundY, c.Z)
	local acf = Parts.FaceTowards(arcadePos, c)
	for i = -1, 1 do
		Props.ArcadeCabinet(decor, acf * CF(i * 3.4, 0, 1.5), {
			Title = ({ "ROLL RAIDERS", "VOID RUN", "RIFT KONG" })[i + 2],
			Color = ({ Palette.Magenta, Palette.Cyan, Palette.Yellow })[i + 2],
		})
	end
	for _, sx in { -1, 1 } do
		Parts.Box(decor, acf * CF(sx * 7, 4.5, -1.5), V3(0.6, 9, 0.6), Palette.MetalDark, Mat.Metal, "CanopyPost")
	end
	Parts.Box(decor, acf * CF(0, 9.2, 0.5), V3(16, 0.5, 7), Palette.Navy, Mat.Slate, "Canopy")
	local arcadeSign = Parts.Neon(decor, acf * CF(0, 10.4, -2.8), V3(9, 1.8, 0.3), Palette.Magenta, "ArcadeSign")
	Parts.SurfaceLabel(arcadeSign, Enum.NormalId.Front, "ARCADE", nil, { TitleColor = Palette.Night })

	-- Wegweiser an der Signal Road
	local forest = AreaConfig.Get("DarkForest")
	local signPos = V3(c.X - WorldConfig.RoadWidth / 2 - 8, WorldConfig.GroundY, c.Z - WorldConfig.PlazaRadius - 20)
	local scf = CF(signPos) * CFrame.Angles(0, math.pi, 0) -- schaut nach Süden (zur Plaza)
	for _, sx in { -4, 4 } do
		Parts.Box(decor, scf * CF(sx, 3.5, 0.2), V3(0.6, 7, 0.6), Palette.Metal, Mat.Metal, "SignPost")
	end
	local roadSign = Parts.Box(decor, scf * CF(0, 6, 0), V3(10, 3.4, 0.3), Color3.fromRGB(30, 110, 70), Mat.SmoothPlastic, "RoadSign")
	Parts.SurfaceLabel(roadSign, Enum.NormalId.Front, "SIGNAL ROAD", (if forest then forest.DisplayName else "DARK FOREST") .. "  ^", {
		Name = "RoadSignGui",
		TitleColor = Palette.White,
		Font = Enum.Font.Michroma,
	})
end

-------------------------------------------------------------------------------
-- Build
-------------------------------------------------------------------------------

export type HubResult = {
	Model: Model,
	Stations: { [string]: Model },
	Leaderboards: { [string]: BasePart },
	SpawnLocation: SpawnLocation,
	PlazaDie: Model,
}

function Hub.Build(parent: Instance, rng: Random): HubResult
	local hub = Parts.Model(nil, "Hub")
	hub:SetAttribute("AreaId", "Suburb")
	local decor = Parts.Folder(hub, "Decor")
	local stationsFolder = Parts.Folder(hub, "Stations")

	-- Boden über das gesamte Suburb-Gebiet (Oberkante knapp unter y = 0, damit
	-- Plaza, Straßen und Plots darüber nicht flackern)
	local suburb = AreaConfig.Get("Suburb")
	assert(suburb, "AreaConfig: Suburb fehlt")
	Parts.Part({
		Parent = hub,
		Name = "Ground",
		CFrame = CF(suburb.Center.X, WorldConfig.GroundY - 0.1 - 2, suburb.Center.Z),
		Size = V3(suburb.Size.X, 4, suburb.Size.Z),
		Color = suburb.GroundColor,
		Material = suburb.GroundMaterial,
	})

	buildPlaza(hub, decor)
	local plazaDie = hub:FindFirstChild("PlazaDie") :: Model

	-- SpawnLocation (Oberkante knapp über der Plaza)
	local c = WorldConfig.HubCenter
	local so = WorldConfig.SpawnOffset
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Anchored = true
	spawn.Size = V3(10, 1, 10)
	spawn.CFrame = CF(c.X + so.X, WorldConfig.GroundY + 0.18 - 0.5, c.Z + so.Z)
	spawn.Color = Palette.Purple
	spawn.Material = Mat.Neon
	spawn.Transparency = 0.35
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.AllowTeamChangeOnTouch = false
	spawn.Parent = hub
	Parts.Stats.Parts += 1

	-- Stationen
	local stations: { [string]: Model } = {}
	for stationId, modelName in Hub.StationModelNames do
		local pos = (WorldConfig.Stations :: any)[stationId] :: Vector3
		local m = Parts.Model(stationsFolder, modelName)
		m:SetAttribute("StationId", stationId)
		local cf = Parts.FaceTowards(V3(pos.X, WorldConfig.GroundY, pos.Z), c)
		STATION_BUILDERS[stationId](m, cf)
		stations[modelName] = m
	end

	local lbPos = WorldConfig.Stations.Leaderboards
	local _, boards = buildLeaderboards(hub, V3(lbPos.X, WorldConfig.GroundY, lbPos.Z))

	buildRingStreet(decor)
	buildSuburbDecor(decor, rng)

	hub.Parent = parent
	return {
		Model = hub,
		Stations = stations,
		Leaderboards = boards,
		SpawnLocation = spawn,
		PlazaDie = plazaDie,
	}
end

return Hub
