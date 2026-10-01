-- MapBuilder (ModuleScript)
-- Ort: ServerScriptService > GliderServer > MapBuilder
--
-- Kleiner "Baukasten" für die Teststrecke. Die Strecke wird entlang eines
-- Cursors (CFrame) gebaut: Jeder Abschnitt startet am aktuellen Cursor und
-- schiebt ihn danach nach vorne. Lokale Koordinaten in einem Abschnitt:
--   x = links (-) / rechts (+), y = Höhe über dem Boden, d = Distanz nach vorne
--
-- Alle Teile in "Solid" lösen einen Crash aus. Teile in "Decor" sind nur Optik.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))

local WALL_THICKNESS = 20
local FLOOR_THICKNESS = 4
local WALL_HEIGHT = 200 -- höher als Config.Crash.MaxAltitude, damit man nicht drüber kommt
local RIB_SPACING = 45 -- Abstand der Wandrippen (Geschwindigkeitsgefühl)
local STRIPE_SPACING = 60 -- Abstand der Bodenstreifen

local MapBuilder = {}
MapBuilder.__index = MapBuilder

export type SectionStyle = {
	wallColor: Color3?,
	floorColor: Color3?,
	wallMaterial: Enum.Material?,
	floorMaterial: Enum.Material?,
	ribColor: Color3?,
	stripeColor: Color3?,
}

local DEFAULT_STYLE = {
	wallColor = Color3.fromRGB(110, 106, 100),
	floorColor = Color3.fromRGB(86, 120, 70),
	wallMaterial = Enum.Material.Slate,
	floorMaterial = Enum.Material.Grass,
	ribColor = Color3.fromRGB(80, 76, 72),
	stripeColor = Color3.fromRGB(235, 235, 235),
}

local function styleValue(style: SectionStyle?, key: string): any
	if style and (style :: any)[key] ~= nil then
		return (style :: any)[key]
	end
	return (DEFAULT_STYLE :: any)[key]
end

function MapBuilder.new(startCFrame: CFrame?)
	local self = setmetatable({}, MapBuilder)

	self.model = Instance.new("Model")
	self.model.Name = Config.Names.MapModel

	self.solid = Instance.new("Folder")
	self.solid.Name = Config.Names.SolidFolder
	self.solid.Parent = self.model

	self.decor = Instance.new("Folder")
	self.decor.Name = Config.Names.DecorFolder
	self.decor.Parent = self.model

	self.cursor = startCFrame or CFrame.new()
	self.distance = 0
	self.lastWidth = nil :: number?
	self.partCount = 0
	self.rng = Random.new(1337) -- fester Seed = Map sieht jedes Mal gleich aus

	self.startSpawn = nil :: CFrame?
	self.checkpoints = {} :: { { gate: CFrame, size: Vector3, spawn: CFrame, label: string } }
	self.finish = nil :: { gate: CFrame, size: Vector3 }?

	return self
end

-------------------------------------------------------------------------------
-- Basis-Bausteine
-------------------------------------------------------------------------------

function MapBuilder:_makePart(parent: Instance, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material, solid: boolean, className: string?): BasePart
	local part = Instance.new(className or "Part") :: BasePart
	part.Anchored = true
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanTouch = false -- wir nutzen kein Touched -> spart Physik-Arbeit
	part.CanCollide = solid
	part.CanQuery = solid -- nur Solid-Teile werden von den Crash-Abfragen gefunden
	if not solid then
		part.CastShadow = false
	end
	part.Parent = parent
	self.partCount += 1
	return part
end

function MapBuilder:Solid(cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?): BasePart
	return self:_makePart(self.solid, cf, size, color, material or Enum.Material.Slate, true)
end

function MapBuilder:Decor(cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	local part = self:_makePart(self.decor, cf, size, color, material or Enum.Material.SmoothPlastic, false)
	part.Transparency = transparency or 0
	return part
end

-- Block über Bereichsangaben im lokalen Raum eines Abschnitts (x, y, d).
function MapBuilder:Box(base: CFrame, x0: number, x1: number, y0: number, y1: number, d0: number, d1: number, color: Color3, material: Enum.Material?, decor: boolean?): BasePart?
	local sx, sy, sd = math.abs(x1 - x0), math.abs(y1 - y0), math.abs(d1 - d0)
	if sx < 0.05 or sy < 0.05 or sd < 0.05 then
		return nil
	end
	local cf = base * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, -(d0 + d1) / 2)
	local size = Vector3.new(sx, sy, sd)
	if decor then
		return self:Decor(cf, size, color, material)
	end
	return self:Solid(cf, size, color, material)
end

-------------------------------------------------------------------------------
-- Korridor (Boden + Wände)
-------------------------------------------------------------------------------

-- Baut ein Korridorstück zwischen d0 und d1 relativ zu "base".
-- floorDrop senkt den Boden minimal ab (gegen Flackern bei überlappenden Kurvenstücken).
function MapBuilder:_corridorPiece(base: CFrame, d0: number, d1: number, width: number, style: SectionStyle?, globalStart: number, floorDrop: number?)
	local half = width / 2
	local drop = floorDrop or 0
	local wallColor = styleValue(style, "wallColor")
	local wallMaterial = styleValue(style, "wallMaterial")

	self:Box(base, -half - WALL_THICKNESS, half + WALL_THICKNESS, -FLOOR_THICKNESS - drop, -drop, d0, d1, styleValue(style, "floorColor"), styleValue(style, "floorMaterial"))
	self:Box(base, -half - WALL_THICKNESS, -half, 0, WALL_HEIGHT, d0, d1, wallColor, wallMaterial)
	self:Box(base, half, half + WALL_THICKNESS, 0, WALL_HEIGHT, d0, d1, wallColor, wallMaterial)

	-- Wiederkehrende Details an Wand und Boden: geben dem Auge Referenzpunkte,
	-- dadurch fühlt sich die Geschwindigkeit viel stärker an.
	local ribColor = styleValue(style, "ribColor")
	local stripeColor = styleValue(style, "stripeColor")

	local firstRib = math.ceil((globalStart + d0) / RIB_SPACING) * RIB_SPACING - globalStart
	local d = firstRib
	while d < d1 do
		local ribHeight = self.rng:NextNumber(70, 160)
		self:Box(base, -half, -half + 1.5, 0, ribHeight, d, d + 6, ribColor, wallMaterial, true)
		self:Box(base, half - 1.5, half, 0, ribHeight, d + 20, d + 26, ribColor, wallMaterial, true)
		d += RIB_SPACING
	end

	local firstStripe = math.ceil((globalStart + d0) / STRIPE_SPACING) * STRIPE_SPACING - globalStart
	d = firstStripe
	while d < d1 do
		self:Box(base, -half, half, 0, 0.15, d, d + 4, stripeColor, Enum.Material.SmoothPlastic, true)
		d += STRIPE_SPACING
	end
end

-- Wenn sich die Breite ändert, wird eine Querwand gebaut, damit keine Lücke
-- zwischen breitem und schmalem Abschnitt entsteht.
function MapBuilder:_widthTransition(base: CFrame, width: number, style: SectionStyle?)
	local last = self.lastWidth
	if last and math.abs(last - width) > 0.1 then
		local inner = math.min(last, width) / 2
		local outer = math.max(last, width) / 2 + WALL_THICKNESS
		local color = styleValue(style, "wallColor")
		local material = styleValue(style, "wallMaterial")
		self:Box(base, -outer, -inner, 0, WALL_HEIGHT, -2, 2, color, material)
		self:Box(base, inner, outer, 0, WALL_HEIGHT, -2, 2, color, material)
	end
	self.lastWidth = width
end

-- Gerader Abschnitt. Gibt die Start-CFrame des Abschnitts zurück, damit
-- Hindernisse relativ dazu platziert werden können.
function MapBuilder:Corridor(length: number, width: number, style: SectionStyle?): CFrame
	local base = self.cursor
	self:_widthTransition(base, width, style)
	self:_corridorPiece(base, 0, length, width, style, self.distance)
	self.cursor = base * CFrame.new(0, 0, -length)
	self.distance += length
	return base
end

-- Kurve aus mehreren kurzen Stücken. Positiver Winkel = Linkskurve.
function MapBuilder:Turn(angleDeg: number, length: number, width: number, style: SectionStyle?)
	local steps = math.max(3, math.ceil(math.abs(angleDeg) / 5))
	local segLength = length / steps
	local stepAngle = math.rad(angleDeg) / steps
	-- Überlappung, damit an der Außenseite der Kurve keine Spalten entstehen
	local overlap = (width / 2 + WALL_THICKNESS) * math.tan(math.abs(stepAngle)) + 2

	self:_widthTransition(self.cursor, width, style)
	for i = 1, steps do
		self.cursor = self.cursor * CFrame.Angles(0, stepAngle / 2, 0)
		self:_corridorPiece(self.cursor, -overlap / 2, segLength + overlap / 2, width, style, self.distance, (i % 2) * 0.1)
		self.cursor = self.cursor * CFrame.new(0, 0, -segLength) * CFrame.Angles(0, stepAngle / 2, 0)
		self.distance += segLength
	end
end

-------------------------------------------------------------------------------
-- Hindernisse
-------------------------------------------------------------------------------

-- Querwand mit Öffnung (= Tor). holeX/holeY = Mitte der Öffnung.
-- Ist die Öffnung so breit wie der Korridor, entsteht ein waagerechter Schlitz.
function MapBuilder:WallWithHole(base: CFrame, d: number, width: number, holeW: number, holeH: number, holeX: number, holeY: number, color: Color3, frameColor: Color3?, thickness: number?)
	local t = thickness or 8
	local half = width / 2
	local h0 = math.max(-half, holeX - holeW / 2)
	local h1 = math.min(half, holeX + holeW / 2)
	local v0 = holeY - holeH / 2
	local v1 = holeY + holeH / 2
	local top = WALL_HEIGHT - 2
	local dA, dB = d - t / 2, d + t / 2

	self:Box(base, -half, h0, 0, top, dA, dB, color)
	self:Box(base, h1, half, 0, top, dA, dB, color)
	self:Box(base, h0, h1, 0, v0, dA, dB, color)
	self:Box(base, h0, h1, v1, top, dA, dB, color)

	-- Leuchtender Rahmen um die Öffnung (nur Optik)
	local fc = frameColor or Color3.fromRGB(255, 200, 40)
	local f = 1.5
	local fA, fB = dA - 0.3, dB + 0.3
	local fx0 = math.max(-half, h0 - f)
	local fx1 = math.min(half, h1 + f)
	self:Box(base, fx0, fx1, v1, v1 + f, fA, fB, fc, Enum.Material.Neon, true)
	self:Box(base, fx0, fx1, math.max(0, v0 - f), v0, fA, fB, fc, Enum.Material.Neon, true)
	if h0 > -half then
		self:Box(base, h0 - f, h0, v0, v1, fA, fB, fc, Enum.Material.Neon, true)
	end
	if h1 < half then
		self:Box(base, h1, h1 + f, v0, v1, fA, fB, fc, Enum.Material.Neon, true)
	end
end

-- Säule über die volle Höhe.
function MapBuilder:Pillar(base: CFrame, x: number, d: number, size: number, color: Color3)
	self:Box(base, x - size / 2, x + size / 2, 0, WALL_HEIGHT - 2, d - size / 2, d + size / 2, color)
end

-------------------------------------------------------------------------------
-- Start / Checkpoints / Ziel
-------------------------------------------------------------------------------

function MapBuilder:_sign(cf: CFrame, size: Vector3, text: string, color: Color3)
	local part = self:Decor(cf, size, color, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- zeigt zum anfliegenden Spieler
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 10
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = part
end

-- Startpunkt in lokalen Koordinaten eines Abschnitts.
function MapBuilder:Start(base: CFrame, d: number, height: number, platformTop: number)
	self.startSpawn = base * CFrame.new(0, height, -d)

	-- Eigener SpawnLocation auf der Startklippe, damit der Charakter nicht ins Leere fällt
	local spawnCf = base * CFrame.new(0, platformTop + 0.5, -(d - 40))
	local spawn = self:_makePart(self.decor, spawnCf, Vector3.new(12, 1, 12), Color3.fromRGB(60, 160, 255), Enum.Material.SmoothPlastic, true, "SpawnLocation") :: SpawnLocation
	spawn.CanQuery = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Name = "GliderSpawn"
end

function MapBuilder:Checkpoint(label: string, spawnHeight: number?)
	local width = self.lastWidth or 100
	local height = Config.Crash.MaxAltitude
	local index = #self.checkpoints + 1
	local gate = self.cursor * CFrame.new(0, height / 2, 0)

	table.insert(self.checkpoints, {
		gate = gate,
		size = Vector3.new(width, height, 2),
		spawn = self.cursor * CFrame.new(0, spawnHeight or 60, 0),
		label = label,
	})

	-- Sichtbare, durchfliegbare Checkpoint-Fläche
	local plane = self:Decor(gate, Vector3.new(width, height, 0.4), Color3.fromRGB(60, 200, 255), Enum.Material.Neon, 0.88)
	plane.Name = "CheckpointGate_" .. index
	local postColor = Color3.fromRGB(60, 200, 255)
	self:Decor(self.cursor * CFrame.new(-width / 2 + 1, height / 2, 0), Vector3.new(2, height, 2), postColor, Enum.Material.Neon)
	self:Decor(self.cursor * CFrame.new(width / 2 - 1, height / 2, 0), Vector3.new(2, height, 2), postColor, Enum.Material.Neon)
end

function MapBuilder:Finish(base: CFrame, d: number, width: number)
	local height = Config.Crash.MaxAltitude
	local gate = base * CFrame.new(0, height / 2, -d)
	self.finish = { gate = gate, size = Vector3.new(width, height, 2) }

	local plane = self:Decor(gate, Vector3.new(width, height, 0.4), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, 0.85)
	plane.Name = "FinishGate"
	-- Schachbrett-Streifen am Boden
	local squares = 12
	local sq = width / squares
	for i = 0, squares - 1 do
		for row = 0, 1 do
			local white = (i + row) % 2 == 0
			local x0 = -width / 2 + i * sq
			self:Box(base, x0, x0 + sq, 0, 0.2, d - sq + row * sq, d + row * sq, white and Color3.new(1, 1, 1) or Color3.new(0.1, 0.1, 0.1), Enum.Material.SmoothPlastic, true)
		end
	end
	self:_sign(base * CFrame.new(0, height - 15, -d), Vector3.new(width * 0.6, 22, 1), "ZIEL", Color3.fromRGB(30, 30, 30))
end

-------------------------------------------------------------------------------
-- Abschluss: Map in den Workspace, Streckendaten in ReplicatedStorage
-------------------------------------------------------------------------------

function MapBuilder:Finalize(): Model
	assert(self.startSpawn, "MapBuilder: Start() wurde nicht aufgerufen")
	assert(self.finish, "MapBuilder: Finish() wurde nicht aufgerufen")

	self.model:SetAttribute("PartCount", self.partCount)
	self.model:SetAttribute("TrackLength", self.distance)

	-- Map immer komplett an den Client senden (falls StreamingEnabled an ist),
	-- sonst fehlen weit entfernte Hindernisse für die Kollisionsabfrage.
	pcall(function()
		self.model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end)

	local old = workspace:FindFirstChild(Config.Names.MapModel)
	if old then
		old:Destroy()
	end
	self.model.Parent = workspace

	-- Streckendaten für den Client. Erst komplett aufbauen, dann parenten,
	-- damit der Client alles auf einmal bekommt.
	local data = Instance.new("Folder")
	data.Name = Config.Names.TrackData
	data:SetAttribute("CheckpointCount", #self.checkpoints)

	local start = Instance.new("CFrameValue")
	start.Name = "Start"
	start.Value = self.startSpawn :: CFrame
	start.Parent = data

	local cpFolder = Instance.new("Folder")
	cpFolder.Name = "Checkpoints"
	cpFolder.Parent = data
	for index, cp in self.checkpoints do
		local entry = Instance.new("Folder")
		entry.Name = "CP" .. index
		entry:SetAttribute("Index", index)
		entry:SetAttribute("Size", cp.size)
		entry:SetAttribute("Label", cp.label)
		local gate = Instance.new("CFrameValue")
		gate.Name = "Gate"
		gate.Value = cp.gate
		gate.Parent = entry
		local spawn = Instance.new("CFrameValue")
		spawn.Name = "Spawn"
		spawn.Value = cp.spawn
		spawn.Parent = entry
		entry.Parent = cpFolder
	end

	local finish = self.finish :: { gate: CFrame, size: Vector3 }
	local finishEntry = Instance.new("Folder")
	finishEntry.Name = "Finish"
	finishEntry:SetAttribute("Size", finish.size)
	local finishGate = Instance.new("CFrameValue")
	finishGate.Name = "Gate"
	finishGate.Value = finish.gate
	finishGate.Parent = finishEntry
	finishEntry.Parent = data

	local oldData = ReplicatedStorage:FindFirstChild(Config.Names.TrackData)
	if oldData then
		oldData:Destroy()
	end
	data.Parent = ReplicatedStorage

	return self.model
end

return MapBuilder
