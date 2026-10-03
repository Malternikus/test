--!strict
-- Props (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > World > Props
--
-- Wiederverwendbare 80s-Mystery-Requisiten. Jede Funktion hat die Form
--   Props.X(parent, cframe, opts?) -> Model
-- cframe = Fußpunkt auf dem Boden (y = Bodenhöhe), Front = LookVector (-Z).
-- Alle Maße in Studs, Charaktere sind ~5 Studs groß.
--
-- Zufall (Steine, Trümmer ...) kommt immer aus opts.Rng, damit die Map mit
-- festem Seed jedes Mal gleich aussieht.

local Parts = require(script.Parent:WaitForChild("Parts"))

type Opts = Parts.Opts

local Palette = Parts.Palette
local V3 = Vector3.new
local CF = CFrame.new
local Mat = Enum.Material

local Props = {}

-------------------------------------------------------------------------------
-- Lokale Kurzformen: Teile relativ zu einer Basis-CFrame
-------------------------------------------------------------------------------

local function B(m: Instance, base: CFrame, x: number, y: number, z: number, sx: number, sy: number, sz: number, color: Color3, mat: Enum.Material?, name: string?): BasePart
	return Parts.Box(m, base * CF(x, y, z), V3(sx, sy, sz), color, mat, name)
end

local function N(m: Instance, base: CFrame, x: number, y: number, z: number, sx: number, sy: number, sz: number, color: Color3, name: string?): BasePart
	return Parts.Neon(m, base * CF(x, y, z), V3(sx, sy, sz), color, name)
end

local function D(m: Instance, base: CFrame, x: number, y: number, z: number, sx: number, sy: number, sz: number, color: Color3, mat: Enum.Material?, name: string?): BasePart
	return Parts.Detail(m, base * CF(x, y, z), V3(sx, sy, sz), color, mat, name)
end

local function rngOf(o: Opts): any
	return o.Rng or Random.new(7)
end

-------------------------------------------------------------------------------
-- Technik: CRT, Radio, Walkie-Talkies, Antenne, Server-Rack
-------------------------------------------------------------------------------

-- Röhrenmonitor mit leuchtendem Bildschirm. opts: ScreenColor, Text, Body
function Props.CRT(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "CRT")
	local body = o.Body or Palette.Beige
	B(m, cf, 0, 1.3, 0.2, 3, 2.6, 2.4, body, Mat.SmoothPlastic, "Body")
	B(m, cf, 0, 1.25, 1.8, 2.2, 2, 1.2, body, Mat.SmoothPlastic, "Back")
	local screen = N(m, cf, 0, 1.4, -1.02, 2.3, 1.8, 0.1, o.ScreenColor or Palette.Screen, "Screen")
	if o.Text then
		Parts.SurfaceLabel(screen, Enum.NormalId.Front, o.Text, nil, {
			Name = "ScreenGui",
			Font = Enum.Font.Code,
			TitleColor = Palette.Night,
			PixelsPerStud = 30,
		})
	end
	return m
end

function Props.Radio(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "Radio")
	B(m, cf, 0, 0.7, 0, 2.4, 1.4, 1, o.Color or Palette.MetalDark, Mat.Metal, "Body")
	D(m, cf, -0.55, 0.7, -0.52, 0.9, 0.9, 0.08, Palette.Black, Mat.DiamondPlate, "Speaker")
	N(m, cf, 0.55, 0.95, -0.52, 0.8, 0.3, 0.08, Palette.Orange, "Dial")
	D(m, cf, 0, 1.5, 0, 1.6, 0.2, 0.2, Palette.Black, nil, "Handle")
	Parts.Beam(m, cf * V3(0.9, 1.4, 0.2), cf * V3(1.5, 3.6, 0.4), 0.1, Palette.Metal, Mat.Metal, "Antenna")
	return m
end

-- Ladestation mit zwei Walkie-Talkies (Kanal-Schild)
function Props.WalkieStand(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "WalkieStand")
	B(m, cf, 0, 1.5, 0, 0.4, 3, 0.4, Palette.Metal, Mat.Metal, "Post")
	B(m, cf, 0, 0.1, 0, 1.6, 0.2, 1.6, Palette.MetalDark, Mat.Metal, "Foot")
	local tray = B(m, cf, 0, 3.15, 0, 3, 0.3, 1.4, Palette.Wood, Mat.Wood, "Tray")
	for i, x in { -0.7, 0.7 } do
		B(m, cf, x, 4, 0, 0.6, 1.4, 0.35, if i == 1 then Palette.Black else Palette.MetalDark, Mat.SmoothPlastic, "Walkie")
		D(m, cf, x + 0.15, 5.1, 0, 0.12, 0.9, 0.12, Palette.Black, nil, "Antenna")
		N(m, cf, x - 0.15, 4.55, -0.19, 0.15, 0.15, 0.05, if i == 1 then Palette.Red else Palette.Green, "Led")
	end
	Parts.SurfaceLabel(tray, Enum.NormalId.Front, o.Text or "CH 14", nil, { TitleColor = Palette.Amber, PixelsPerStud = 30 })
	return m
end

-- Funkmast mit Querstreben, Schüssel, roter Spitze und Abspannseilen
function Props.AntennaMast(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local h = o.Height or 24
	local m = Parts.Model(parent, "AntennaMast")
	B(m, cf, 0, 0.5, 0, 3, 1, 3, Palette.ConcreteDark, Mat.Concrete, "Base")
	B(m, cf, 0, h / 2, 0, 0.6, h, 0.6, Palette.Metal, Mat.Metal, "Pole")
	for i = 1, 3 do
		local y = h * (0.35 + i * 0.17)
		local w = 3.6 - i * 0.7
		D(m, cf * CFrame.Angles(0, i * 0.6, 0), 0, y, 0, w, 0.2, 0.2, Palette.Metal, Mat.Metal, "Crossbar")
	end
	Parts.Cyl(m, cf * CF(0.6, h * 0.62, -0.6) * CFrame.Angles(0, math.rad(60), math.rad(-20)), 0.3, 3.2, Palette.White, Mat.SmoothPlastic, "Dish")
	Parts.Ball(m, cf * CF(0, h + 0.4, 0), 0.9, Palette.Red, Mat.Neon, "Beacon")
	local spread = o.GuySpread or 3
	for i = 0, 2 do
		local a = i * (math.pi * 2 / 3) + 0.3
		Parts.Beam(m, cf * V3(0, h * 0.8, 0), cf * V3(math.cos(a) * spread, 0.1, math.sin(a) * spread), 0.08, Palette.MetalDark, Mat.Metal, "GuyWire")
	end
	return m
end

function Props.ServerRack(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "ServerRack")
	B(m, cf, 0, 3.5, 0, 3, 7, 2.4, Palette.MetalDark, Mat.Metal, "Body")
	D(m, cf, 0, 3.6, -1.22, 2.6, 6.4, 0.08, Palette.Black, Mat.DiamondPlate, "Panel")
	local colors = o.Colors or { Palette.Green, Palette.Cyan, Palette.Red }
	for i, c in colors do
		N(m, cf, (i - 2) * 0.7, 2 + i * 1.4, -1.28, 0.25, 1.2, 0.06, c, "Led")
	end
	return m
end

-------------------------------------------------------------------------------
-- Lichterkette ("Communication Lights")
-------------------------------------------------------------------------------

-- Kette von cf.Position nach opts.To (Vector3, Weltkoordinaten), durchhängend.
-- opts: To, Count, Sag, Colors, BulbParent (Folder für die Birnen), BulbSize
-- Jede Birne: Neon-Kugel "Bulb" mit Attribut Bulb = true und BulbIndex.
function Props.StringLights(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "StringLights")
	local a = cf.Position
	local b: Vector3 = o.To or (cf * V3(0, 0, -10))
	local count = o.Count or 10
	local sag = o.Sag or 2
	local colors = o.Colors or Parts.BulbColors
	local bulbParent = o.BulbParent or m
	local bulbSize = o.BulbSize or 0.75

	local function at(t: number): Vector3
		return a:Lerp(b, t) - V3(0, sag * 4 * t * (1 - t), 0)
	end

	local segments = math.max(2, math.ceil(count / 3))
	for i = 1, segments do
		Parts.Beam(m, at((i - 1) / segments), at(i / segments), 0.1, Palette.Black, Mat.SmoothPlastic, "Wire")
	end
	for i = 1, count do
		local t = (i - 0.5) / count
		local bulb = Parts.Ball(bulbParent, CFrame.new(at(t) - V3(0, 0.45, 0)), bulbSize, colors[(i - 1) % #colors + 1], Mat.Neon, "Bulb")
		bulb.CastShadow = false
		bulb:SetAttribute("Bulb", true)
		bulb:SetAttribute("BulbIndex", i)
	end
	return m
end

-------------------------------------------------------------------------------
-- Mystery Board, Kartentisch, Kabel, Schreibtisch, Stuhl
-------------------------------------------------------------------------------

-- Pinnwand mit Zetteln, Fotos, Nadeln und roten Fäden. opts: Width, Height
function Props.Corkboard(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local w = o.Width or 7
	local h = o.Height or 4.5
	local bottom = 2
	local m = Parts.Model(parent, "Corkboard")
	for _, x in { -w / 2 + 0.6, w / 2 - 0.6 } do
		B(m, cf, x, (bottom + h) / 2, 0.35, 0.35, bottom + h, 0.35, Palette.WoodDark, Mat.Wood, "Leg")
	end
	B(m, cf, 0, bottom + h / 2, 0.1, w + 0.4, h + 0.4, 0.3, Palette.WoodDark, Mat.Wood, "Frame")
	B(m, cf, 0, bottom + h / 2, -0.1, w, h, 0.12, Palette.Cork, Mat.Fabric, "Cork")
	-- Zettel (relative Position auf der Pinnwand, -1..1)
	local notes = {
		{ -0.7, 0.45, Palette.Paper },
		{ -0.15, 0.55, Palette.Black },
		{ 0.55, 0.4, Palette.Paper },
		{ -0.45, -0.4, Palette.Paper },
		{ 0.35, -0.35, Color3.fromRGB(250, 236, 140) },
	}
	local pins = {}
	for _, n in notes do
		local x = n[1] * (w / 2 - 0.8)
		local y = bottom + h / 2 + n[2] * (h / 2 - 0.8)
		D(m, cf, x, y, -0.19, 1.1, 1.3, 0.04, n[3], Mat.SmoothPlastic, "Note")
		local pin = cf * V3(x, y + 0.5, -0.24)
		Parts.Ball(m, CFrame.new(pin), 0.25, Palette.Red, Mat.Neon, "Pin")
		table.insert(pins, pin)
	end
	-- Rote Fäden zwischen den Nadeln
	for _, pair in { { 1, 2 }, { 2, 3 }, { 1, 4 }, { 4, 5 }, { 2, 5 } } do
		Parts.Beam(m, pins[pair[1]], pins[pair[2]], 0.06, Palette.Red, Mat.Neon, "String")
	end
	return m
end

function Props.MapTable(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "MapTable")
	B(m, cf, 0, 2.85, 0, 6, 0.3, 4, Palette.Wood, Mat.Wood, "Top")
	for _, x in { -2.5, 2.5 } do
		B(m, cf, x, 1.35, 0, 0.4, 2.7, 3.4, Palette.WoodDark, Mat.Wood, "Leg")
	end
	local map = D(m, cf * CFrame.Angles(0, 0.08, 0), 0, 3.03, 0, 5, 0.05, 3.4, Color3.fromRGB(196, 210, 170), Mat.SmoothPlastic, "Map")
	Parts.SurfaceLabel(map, Enum.NormalId.Top, o.Text or "MILBROOK COUNTY", nil, {
		TitleColor = Color3.fromRGB(60, 70, 60),
		Font = Enum.Font.SpecialElite,
		PixelsPerStud = 24,
	})
	Parts.Beam(m, cf * V3(-1.8, 3.08, 1), cf * V3(1.2, 3.08, -0.8), 0.1, Palette.Red, Mat.Neon, "Route")
	Parts.VCyl(m, cf * CF(1.3, 3.3, -0.9), 0.5, 0.3, Palette.Red, Mat.Neon, "Marker")
	Parts.VCyl(m, cf * CF(-1.9, 3.3, 1.1), 0.5, 0.3, Palette.Cyan, Mat.Neon, "Marker")
	return m
end

-- Kabel auf dem Boden von cf.Position nach opts.To. opts: To, Count, Rng
function Props.Cables(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local rng = rngOf(o)
	local m = Parts.Model(parent, "Cables")
	local a = cf.Position
	local b: Vector3 = o.To or (cf * V3(0, 0, -12))
	local side = (b - a)
	local perp = V3(-side.Z, 0, side.X)
	perp = if perp.Magnitude > 0 then perp.Unit else V3(1, 0, 0)
	local colors = { Palette.Black, Color3.fromRGB(40, 40, 60), Color3.fromRGB(80, 30, 30) }
	for i = 1, (o.Count or 3) do
		local off = perp * ((i - 2) * 0.35)
		local mid = a:Lerp(b, 0.5) + perp * rng:NextNumber(-1.2, 1.2) + off
		local y = V3(0, 0.12, 0)
		Parts.Beam(m, a + off + y, mid + y, 0.22, colors[(i - 1) % #colors + 1], Mat.Rubber, "Cable")
		Parts.Beam(m, mid + y, b + off + y, 0.22, colors[(i - 1) % #colors + 1], Mat.Rubber, "Cable")
	end
	return m
end

-- Schreibtisch. opts: Width, Depth, Height (Oberkante)
function Props.Desk(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local w, d, h = o.Width or 8, o.Depth or 3.5, o.Height or 3
	local m = Parts.Model(parent, "Desk")
	B(m, cf, 0, h - 0.15, 0, w, 0.3, d, o.Color or Palette.Wood, Mat.Wood, "Top")
	B(m, cf, -w / 2 + 0.2, (h - 0.3) / 2, 0, 0.4, h - 0.3, d - 0.2, Palette.WoodDark, Mat.Wood, "Side")
	B(m, cf, w / 2 - 1.1, (h - 0.3) / 2, 0, 2.2, h - 0.3, d - 0.2, Palette.WoodDark, Mat.Wood, "Drawers")
	D(m, cf, w / 2 - 1.1, h * 0.55, -d / 2 + 0.05, 0.8, 0.15, 0.1, Palette.Amber, Mat.Metal, "Handle")
	return m
end

function Props.Chair(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "Chair")
	local c = o.Color or Color3.fromRGB(110, 40, 40)
	B(m, cf, 0, 0.1, 0, 1.6, 0.2, 1.6, Palette.MetalDark, Mat.Metal, "Foot")
	B(m, cf, 0, 0.95, 0, 0.3, 1.5, 0.3, Palette.Metal, Mat.Metal, "Post")
	B(m, cf, 0, 1.8, 0, 1.9, 0.35, 1.8, c, Mat.Fabric, "Seat")
	B(m, cf, 0, 2.9, 0.85, 1.9, 2, 0.3, c, Mat.Fabric, "Back")
	return m
end

function Props.Bench(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local w = o.Width or 6
	local m = Parts.Model(parent, "Bench")
	B(m, cf, 0, 1.6, 0, w, 0.35, 1.8, Palette.Wood, Mat.Wood, "Seat")
	B(m, cf, 0, 2.6, 0.8, w, 1.3, 0.25, Palette.Wood, Mat.Wood, "Back")
	for _, x in { -w / 2 + 0.5, w / 2 - 0.5 } do
		B(m, cf, x, 0.75, 0.1, 0.35, 1.5, 1.6, Palette.MetalDark, Mat.Metal, "Leg")
	end
	return m
end

function Props.Crate(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local s = o.Size or 3
	local m = Parts.Model(parent, "Crate")
	B(m, cf, 0, s / 2, 0, s, s, s, o.Color or Palette.WoodLight, Mat.WoodPlanks, "Box")
	return m
end

-------------------------------------------------------------------------------
-- Straße & Vorstadt: Laterne, Briefkasten, Zaun, Haus, Van, Fahrrad, Arcade
-------------------------------------------------------------------------------

-- Straßenlaterne; Arm zeigt nach vorne (LookVector). opts: Height, Color, Light
function Props.Streetlamp(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local h = o.Height or 14
	local color = o.Color or Palette.Orange
	local m = Parts.Model(parent, "Streetlamp")
	B(m, cf, 0, 0.5, 0, 1.4, 1, 1.4, Palette.MetalDark, Mat.Metal, "Base")
	Parts.VCyl(m, cf * CF(0, h / 2, 0), h, 0.6, o.PoleColor or Palette.MetalDark, Mat.Metal, "Pole")
	B(m, cf, 0, h - 0.2, -1.6, 0.4, 0.4, 3.4, o.PoleColor or Palette.MetalDark, Mat.Metal, "Arm")
	B(m, cf, 0, h - 0.4, -3.4, 1.6, 0.6, 2.2, Palette.Black, Mat.Metal, "Head")
	local bulb = N(m, cf, 0, h - 0.8, -3.4, 1.2, 0.2, 1.6, color, "Bulb")
	if o.Light then
		Parts.Light(bulb, color, o.Range or 28, o.Brightness or 1.6, "Spot", Enum.NormalId.Bottom)
	end
	return m
end

function Props.Mailbox(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "Mailbox")
	B(m, cf, 0, 1.5, 0, 0.4, 3, 0.4, Palette.Wood, Mat.Wood, "Post")
	B(m, cf, 0, 3.5, 0, 1.2, 1.1, 2, o.Color or Color3.fromRGB(60, 80, 160), Mat.Metal, "Box")
	D(m, cf, 0.65, 3.9, 0.4, 0.1, 0.8, 0.3, Palette.Red, Mat.SmoothPlastic, "Flag")
	return m
end

-- Lattenzaun entlang der lokalen X-Achse (Mitte = cf). opts: Length, Spacing, Height, Color
function Props.PicketFence(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local len = o.Length or 12
	local spacing = o.Spacing or 2.2
	local h = o.Height or 3.4
	local color = o.Color or Palette.White
	local m = Parts.Model(parent, "PicketFence")
	B(m, cf, 0, h * 0.35, 0.15, len, 0.3, 0.15, color, Mat.Wood, "Rail")
	B(m, cf, 0, h * 0.75, 0.15, len, 0.3, 0.15, color, Mat.Wood, "Rail")
	local n = math.max(2, math.floor(len / spacing) + 1)
	for i = 0, n - 1 do
		local x = -len / 2 + 0.3 + (len - 0.6) * i / (n - 1)
		B(m, cf, x, h / 2, 0, 0.55, h, 0.15, color, Mat.Wood, "Picket")
	end
	return m
end

-- Maschendrahtzaun (Labor) entlang lokaler X-Achse. opts: Length, Height
function Props.ChainFence(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local len = o.Length or 24
	local h = o.Height or 9
	local m = Parts.Model(parent, "ChainFence")
	Parts.Part({
		Parent = m,
		Name = "Mesh",
		CFrame = cf * CF(0, h / 2, 0),
		Size = V3(len, h, 0.2),
		Color = Palette.Metal,
		Material = Mat.DiamondPlate,
		Transparency = 0.55,
	})
	local posts = math.max(2, math.floor(len / 12) + 1)
	for i = 0, posts - 1 do
		local x = -len / 2 + len * i / (posts - 1)
		B(m, cf, x, h / 2 + 0.5, 0, 0.5, h + 1, 0.5, Palette.MetalDark, Mat.Metal, "Post")
	end
	D(m, cf, 0, h + 0.8, 0, len, 0.25, 0.25, Palette.MetalDark, Mat.Metal, "Barbs")
	return m
end

-- 80er Vorstadthaus mit Satteldach. Front (Tür) zeigt nach LookVector.
-- opts: Width, Depth, Height, Color, RoofColor, Garage (bool), Lit (bool),
--       WindowColor
function Props.House(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local w, d, h = o.Width or 22, o.Depth or 16, o.Height or 10
	local color = o.Color or Parts.HouseColors[1]
	local roof = o.RoofColor or Color3.fromRGB(56, 44, 52)
	local lit = if o.Lit == nil then true else o.Lit
	local windowColor = o.WindowColor or (if lit then Palette.Amber else Palette.NavyLight)
	local m = Parts.Model(parent, "House")
	local top = 1 + h
	B(m, cf, 0, 0.5, 0, w + 1, 1, d + 1, Palette.ConcreteDark, Mat.Concrete, "Foundation")
	B(m, cf, 0, 1 + h / 2, 0, w, h, d, color, Mat.WoodPlanks, "Body")
	-- Giebel: um 45° gedrehter Quader, untere Hälfte steckt im Körper
	local s = d / math.sqrt(2)
	B(m, cf * CF(0, top, 0) * CFrame.Angles(math.rad(45), 0, 0), 0, 0, 0, w - 0.2, s, s, color, Mat.WoodPlanks, "Gable")
	-- Dachflächen
	local slopeLen = d / 2 * math.sqrt(2) + 1.6
	for _, side in { -1, 1 } do
		local peak = cf * V3(0, top + d / 2, 0)
		local eave = cf * V3(0, top, side * d / 2)
		local dir = eave - peak
		local mid = (peak + eave) / 2
		local slab = Parts.LookAlong(mid, dir) * CF(0, 0.45, -0.7)
		Parts.Box(m, slab, V3(w + 1.6, 0.8, slopeLen), roof, Mat.Slate, "Roof")
	end
	B(m, cf, w / 3, top + d / 2 - 1, d / 6, 2, 5, 2, Color3.fromRGB(120, 60, 50), Mat.Brick, "Chimney")
	-- Front: Tür, Stufe, Lampe, Fenster
	local front = -d / 2
	local doorX = if o.Garage then -w / 4 else 0
	B(m, cf, doorX, 3.6, front - 0.1, 3.2, 5.6, 0.3, Palette.WoodDark, Mat.Wood, "Door")
	B(m, cf, doorX, 0.4, front - 1.3, 5, 0.8, 2.6, Palette.Concrete, Mat.Concrete, "Step")
	N(m, cf, doorX + 2.2, 5.4, front - 0.2, 0.5, 0.7, 0.3, Palette.Amber, "PorchLight")
	local windows = if o.Garage then { -w / 4 - 3.8, -w / 4 + 3.8 } else { -w / 4 - 1, w / 4 + 1 }
	for _, x in windows do
		Parts.Part({
			Parent = m,
			Name = "Window",
			CFrame = cf * CF(x, 1 + h * 0.6, front - 0.1),
			Size = V3(2.8, 2.8, 0.2),
			Color = windowColor,
			Material = if lit then Mat.Neon else Mat.Glass,
			CanCollide = false,
		})
	end
	if o.Garage then
		B(m, cf, w / 4 + 0.5, 3.75, front - 0.1, 8, 5.5, 0.3, Palette.White, Mat.CorrodedMetal, "GarageDoor")
	end
	-- Fenster im seitlichen Giebeldreieck
	Parts.Part({
		Parent = m,
		Name = "Window",
		CFrame = cf * CF(w / 2, top + 2, 0),
		Size = V3(0.2, 2, 2.4),
		Color = windowColor,
		Material = if lit then Mat.Neon else Mat.Glass,
		CanCollide = false,
	})
	return m
end

function Props.ArcadeCabinet(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local accent = o.Color or Palette.Magenta
	local m = Parts.Model(parent, "ArcadeCabinet")
	B(m, cf, 0, 3, 0, 2.6, 6, 2.4, o.BodyColor or Palette.Navy, Mat.SmoothPlastic, "Body")
	N(m, cf * CFrame.Angles(math.rad(-12), 0, 0), 0, 4.2, -1.0, 2, 1.6, 0.1, o.ScreenColor or Palette.Cyan, "Screen")
	local marquee = N(m, cf, 0, 5.65, -1.15, 2.6, 0.8, 0.3, accent, "Marquee")
	Parts.SurfaceLabel(marquee, Enum.NormalId.Front, o.Title or "ROLL RAIDERS", nil, { TitleColor = Palette.Night, PixelsPerStud = 30 })
	B(m, cf * CFrame.Angles(math.rad(15), 0, 0), 0, 3.1, -1.45, 2.6, 0.35, 1, Palette.Black, Mat.SmoothPlastic, "Controls")
	N(m, cf, 1.32, 3, 0, 0.06, 5.6, 0.25, accent, "Stripe")
	return m
end

-- Lieferwagen, Front = LookVector. opts: Color, StripeColor
function Props.Van(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local color = o.Color or Palette.White
	local m = Parts.Model(parent, "Van")
	B(m, cf, 0, 3.6, 1.2, 7, 5.4, 12.5, color, Mat.SmoothPlastic, "Body")
	B(m, cf, 0, 2.5, -6.6, 7, 3.2, 3.2, color, Mat.SmoothPlastic, "Hood")
	Parts.Glass(m, cf * CF(0, 4.9, -5.15) * CFrame.Angles(math.rad(-25), 0, 0), V3(6.4, 2.4, 0.2), Palette.Night, 0.2, "Windshield")
	D(m, cf, 0, 3.2, 1.2, 7.1, 0.7, 12.6, o.StripeColor or Palette.Orange, Mat.SmoothPlastic, "Stripe")
	for _, x in { -3.56, 3.56 } do
		D(m, cf, x, 4.9, -2.5, 0.1, 1.6, 3.6, Palette.Night, Mat.Glass, "SideWindow")
	end
	for _, z in { -5.4, 5.2 } do
		for _, x in { -3.1, 3.1 } do
			Parts.Cyl(m, cf * CF(x, 1.4, z), 1.1, 2.8, Palette.Black, Mat.Rubber, "Wheel")
		end
	end
	B(m, cf, 0, 1.4, -8.3, 7.2, 0.7, 0.5, Palette.Metal, Mat.Metal, "Bumper")
	N(m, cf, -2.6, 2.7, -8.25, 1, 0.6, 0.1, Palette.Amber, "Headlight")
	N(m, cf, 2.6, 2.7, -8.25, 1, 0.6, 0.1, Palette.Amber, "Headlight")
	return m
end

-- Fahrrad, fährt Richtung LookVector. opts: Color, Lean (rad, kippt um Z)
function Props.Bicycle(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local base = cf * CFrame.Angles(0, 0, o.Lean or 0)
	local color = o.Color or Palette.Red
	local m = Parts.Model(parent, "Bicycle")
	for _, z in { -1.7, 1.7 } do
		Parts.Part({
			Parent = m,
			Name = "Wheel",
			Shape = Enum.PartType.Cylinder,
			CFrame = base * CF(0, 1.2, z),
			Size = V3(0.25, 2.4, 2.4),
			Color = Palette.Black,
			Material = Mat.Rubber,
			CanCollide = false,
		})
	end
	local rear, front = base * V3(0, 1.2, 1.7), base * V3(0, 1.2, -1.7)
	local seat, bar, crank = base * V3(0, 2.7, 0.6), base * V3(0, 2.9, -1.3), base * V3(0, 1.2, 0)
	Parts.Beam(m, seat, bar, 0.2, color, Mat.Metal, "Frame")
	Parts.Beam(m, crank, bar, 0.2, color, Mat.Metal, "Frame")
	Parts.Beam(m, rear, seat, 0.18, color, Mat.Metal, "Frame")
	Parts.Beam(m, front, bar, 0.18, Palette.Metal, Mat.Metal, "Fork")
	D(m, base, 0, 3.15, -1.35, 1.7, 0.15, 0.15, Palette.Black, Mat.Metal, "Handlebar")
	D(m, base, 0, 2.85, 0.65, 0.45, 0.2, 0.9, Palette.Black, Mat.Fabric, "Saddle")
	return m
end

-------------------------------------------------------------------------------
-- Natur: Bäume, Steine, Kristalle, Pilze, Büsche
-------------------------------------------------------------------------------

-- Stilisierte Tanne aus gestapelten Scheiben. opts: Height, Color, Tiers
function Props.PineTree(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local h = o.Height or 18
	local tiers = o.Tiers or 3
	local color = o.Color or Palette.Leaf
	local m = Parts.Model(parent, "PineTree")
	local trunkH = h * 0.3
	B(m, cf, 0, trunkH / 2, 0, h * 0.08, trunkH, h * 0.08, o.TrunkColor or Palette.Bark, Mat.Wood, "Trunk")
	local crownH = h - trunkH
	local tierH = crownH / tiers
	for i = 0, tiers - 1 do
		local dia = h * 0.55 * (1 - i / (tiers + 0.6))
		local y = trunkH + tierH * (i + 0.5)
		Parts.VCyl(m, cf * CF(0, y, 0) * CFrame.Angles(0, i * 0.7, 0), tierH * 1.15, dia, color, Mat.Grass, "Crown")
	end
	return m
end

function Props.DeadTree(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local h = o.Height or 14
	local color = o.Color or Palette.BarkGrey
	local m = Parts.Model(parent, "DeadTree")
	B(m, cf * CFrame.Angles(0, 0, 0.05), 0, h / 2, 0, 1.1, h, 1.1, color, Mat.Wood, "Trunk")
	local branches = {
		{ 0.55, 1, 0.6 },
		{ 0.7, -1, 2.4 },
		{ 0.85, 1, 4.2 },
	}
	for _, br in branches do
		local start = cf * V3(0, h * br[1], 0)
		local dir = (cf * CFrame.Angles(0, br[3], 0)).RightVector * br[2]
		Parts.Beam(m, start, start + dir * h * 0.3 + V3(0, h * 0.18, 0), 0.5, color, Mat.Wood, "Branch")
	end
	return m
end

-- Felsbrocken. opts: Size, Color, Rng, Parts (1 oder 2)
function Props.Rock(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local rng = rngOf(o)
	local s = o.Size or 4
	local color = o.Color or Palette.Rock
	local m = Parts.Model(parent, "Rock")
	local rot = CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, math.pi), rng:NextNumber(-0.3, 0.3))
	Parts.Box(m, cf * CF(0, s * 0.25, 0) * rot, V3(s, s * 0.7, s * 0.85), color, o.Material or Mat.Slate, "Rock")
	if (o.Parts or 2) >= 2 then
		local rot2 = CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, math.pi), rng:NextNumber(-0.5, 0.5))
		Parts.Box(m, cf * CF(s * 0.45, s * 0.15, s * 0.2) * rot2, V3(s * 0.5, s * 0.45, s * 0.5), color, o.Material or Mat.Slate, "Rock")
	end
	return m
end

-- Kristallgruppe. opts: Height, Color, Color2, Rng
function Props.Crystal(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local rng = rngOf(o)
	local h = o.Height or 8
	local color = o.Color or Palette.Purple
	local m = Parts.Model(parent, "Crystal")
	local main = cf * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, math.pi), rng:NextNumber(-0.15, 0.15))
	Parts.Part({
		Parent = m,
		Name = "Shard",
		CFrame = main * CF(0, h / 2 - 0.5, 0) * CFrame.Angles(0, math.rad(45), 0),
		Size = V3(h * 0.22, h, h * 0.22),
		Color = color,
		Material = Mat.Glass,
		Transparency = 0.15,
	})
	for i, side in { -1, 1 } do
		local tilt = main * CFrame.Angles(0, i * 2.1, side * 0.45)
		Parts.Neon(m, tilt * CF(side * h * 0.12, h * 0.25, 0), V3(h * 0.13, h * 0.55, h * 0.13), o.Color2 or color, "Shard")
	end
	return m
end

-- Leuchtpilz. opts: Height, Color
function Props.Mushroom(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local h = o.Height or 2
	local m = Parts.Model(parent, "Mushroom")
	Parts.VCyl(m, cf * CF(0, h / 2, 0), h, h * 0.25, Palette.Paper, Mat.SmoothPlastic, "Stem")
	local cap = Parts.Part({
		Parent = m,
		Name = "Cap",
		CFrame = cf * CF(0, h, 0),
		Size = V3(h * 1.1, h * 0.45, h * 1.1),
		Color = o.Color or Palette.Green,
		Material = Mat.Neon,
		CanCollide = false,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = cap
	return m
end

function Props.Bush(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local s = o.Size or 4
	local m = Parts.Model(parent, "Bush")
	Parts.Part({
		Parent = m,
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		CFrame = cf * CF(0, s * 0.35, 0),
		Size = V3(s, s, s),
		Color = o.Color or Palette.Leaf,
		Material = Mat.Grass,
	})
	return m
end

-------------------------------------------------------------------------------
-- Rift / Anomalie: Riss, Trümmer, schwebende Brocken
-------------------------------------------------------------------------------

-- Zickzack-Riss aus Neon. Liegt flach auf dem Boden (oder senkrecht mit
-- opts.Vertical = true als "Rift Tear"). opts: Length, Width, Color, Rng
function Props.RiftCrack(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local rng = rngOf(o)
	local len = o.Length or 14
	local width = o.Width or 1.2
	local color = o.Color or Palette.Purple
	local m = Parts.Model(parent, "RiftCrack")
	local base = if o.Vertical then cf * CF(0, len / 2 + 0.5, 0) * CFrame.Angles(math.rad(90), 0, 0) else cf * CF(0, 0.08, 0)
	B(m, base, 0, -0.05, 0, width * 2.4, 0.12, len * 1.02, Palette.Black, Mat.Slate, "Lip")
	local segs = 3
	local x0 = 0
	for i = 1, segs do
		local z0 = -len / 2 + len * (i - 1) / segs
		local z1 = -len / 2 + len * i / segs
		local x1 = if i == segs then 0 else rng:NextNumber(-width, width)
		local p0 = base * V3(x0, 0.05, z0)
		local p1 = base * V3(x1, 0.05, z1)
		local seg = Parts.Beam(m, p0, p1, 1, color, Mat.Neon, "Crack")
		seg.Size = V3(width * (1.1 - i * 0.2), 0.12, seg.Size.Z + 0.4)
		x0 = x1
	end
	return m
end

-- Schwebende Trümmerbrocken. opts: Count, Size, Color, Rng, Material
function Props.FloatingDebris(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local rng = rngOf(o)
	local m = Parts.Model(parent, "FloatingDebris")
	local s = o.Size or 2.5
	for _ = 1, (o.Count or 3) do
		local off = V3(rng:NextNumber(-3, 3), rng:NextNumber(-2, 2), rng:NextNumber(-3, 3))
		local rot = CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28))
		Parts.Part({
			Parent = m,
			Name = "Chunk",
			CFrame = cf * CF(off) * rot,
			Size = V3(s * rng:NextNumber(0.5, 1.4), s * rng:NextNumber(0.3, 0.8), s * rng:NextNumber(0.5, 1.4)),
			Color = o.Color or Palette.Rock,
			Material = o.Material or Mat.Slate,
			CanCollide = false,
		})
	end
	return m
end

-- Schwebende Erdscholle (oben flach, unten Felsspitze). opts: Size, Color, TopColor, Rng
function Props.FloatingIsland(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local s = o.Size or 12
	local m = Parts.Model(parent, "FloatingIsland")
	B(m, cf, 0, 0, 0, s, 1.6, s * 0.8, o.TopColor or Palette.Rock, o.Material or Mat.Slate, "Top")
	B(m, cf * CFrame.Angles(math.rad(45), 0.3, 0), 0, -s * 0.2, 0, s * 0.7, s * 0.4, s * 0.4, o.Color or Palette.Rock, Mat.Slate, "Underside")
	B(m, cf * CFrame.Angles(0.2, 1.2, math.rad(45)), 0, -s * 0.35, 0, s * 0.3, s * 0.3, s * 0.3, o.Color or Palette.Rock, Mat.Slate, "Spike")
	return m
end

-------------------------------------------------------------------------------
-- Labor: Tank, Warnschild, Fässer, Warnlicht
-------------------------------------------------------------------------------

-- Glastank mit leuchtender Flüssigkeit und Schatten darin. opts: Height, Diameter, LiquidColor
function Props.LabTank(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local h = o.Height or 10
	local dia = o.Diameter or 5
	local liquid = o.LiquidColor or Palette.Cyan
	local m = Parts.Model(parent, "LabTank")
	Parts.VCyl(m, cf * CF(0, 0.6, 0), 1.2, dia + 1.2, Palette.MetalDark, Mat.Metal, "Base")
	Parts.Part({
		Parent = m,
		Name = "Liquid",
		Shape = Enum.PartType.Cylinder,
		CFrame = cf * CF(0, 1.2 + (h - 3) / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Size = V3(h - 3.2, dia - 0.8, dia - 0.8),
		Color = liquid,
		Material = Mat.Neon,
		Transparency = 0.35,
		CanCollide = false,
	})
	D(m, cf, 0, 1.2 + (h - 3) / 2, 0, 1.1, 2.6, 0.7, Palette.Black, Mat.SmoothPlastic, "Specimen")
	Parts.Part({
		Parent = m,
		Name = "Glass",
		Shape = Enum.PartType.Cylinder,
		CFrame = cf * CF(0, 1.2 + (h - 2.4) / 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Size = V3(h - 2.4, dia, dia),
		Color = Color3.fromRGB(180, 220, 255),
		Material = Mat.Glass,
		Transparency = 0.6,
	})
	Parts.VCyl(m, cf * CF(0, h - 0.6, 0), 1.2, dia + 0.8, Palette.MetalDark, Mat.Metal, "Cap")
	Parts.Beam(m, cf * V3(0, h - 0.3, 0), cf * V3(0, h - 0.3, dia + 1), 0.6, Palette.Metal, Mat.Metal, "Pipe")
	return m
end

-- Warnschild. opts: Text, Color
function Props.WarningSign(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "WarningSign")
	B(m, cf, 0, 2.2, 0.1, 0.3, 4.4, 0.3, Palette.Metal, Mat.Metal, "Post")
	local plate = B(m, cf, 0, 4.6, -0.1, 3.4, 2.6, 0.2, o.Color or Palette.Yellow, Mat.SmoothPlastic, "Plate")
	Parts.SurfaceLabel(plate, Enum.NormalId.Front, o.Text or "DANGER", o.Subtext or "KEEP OUT", {
		TitleColor = Palette.Black,
		PixelsPerStud = 30,
	})
	return m
end

-- Fässer-Gruppe. opts: Count, Color, Toxic (Neon-Deckel)
function Props.Barrels(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "Barrels")
	local spots = { V3(0, 0, 0), V3(2.4, 0, 0.6), V3(1, 0, 2.3), V3(-1.6, 0, 1.8) }
	for i = 1, math.min(o.Count or 3, #spots) do
		local p = spots[i]
		Parts.VCyl(m, cf * CF(p.X, 1.5, p.Z), 3, 2.2, o.Color or Color3.fromRGB(150, 120, 40), Mat.CorrodedMetal, "Barrel")
		if o.Toxic then
			Parts.VCyl(m, cf * CF(p.X, 3.05, p.Z), 0.12, 1.8, Palette.Green, Mat.Neon, "Glow")
		end
	end
	return m
end

-- Drehlicht auf Sockel. opts: Color
function Props.WarningLight(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local m = Parts.Model(parent, "WarningLight")
	B(m, cf, 0, (o.Height or 0) + 0.3, 0, 1.2, 0.6, 1.2, Palette.MetalDark, Mat.Metal, "Base")
	Parts.Ball(m, cf * CF(0, (o.Height or 0) + 1, 0), 1.1, o.Color or Palette.Red, Mat.Neon, "Lamp")
	return m
end

-------------------------------------------------------------------------------
-- Würfel (Plaza-Statue, Dice-Altäre)
-------------------------------------------------------------------------------

-- Augen pro Seite (u, v in -1..1)
local PIPS = {
	[1] = { { 0, 0 } },
	[2] = { { -1, -1 }, { 1, 1 } },
	[3] = { { -1, -1 }, { 0, 0 }, { 1, 1 } },
	[4] = { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } },
	[5] = { { -1, -1 }, { 1, -1 }, { 0, 0 }, { -1, 1 }, { 1, 1 } },
	[6] = { { -1, -1 }, { -1, 0 }, { -1, 1 }, { 1, -1 }, { 1, 0 }, { 1, 1 } },
}

-- Seiten-Rotationen: dreht die Front-Fläche (-Z) auf die jeweilige Seite.
-- Gegenüberliegende Seiten ergeben zusammen 7.
local FACES = {
	{ value = 1, rot = CFrame.new() },
	{ value = 6, rot = CFrame.Angles(0, math.pi, 0) },
	{ value = 3, rot = CFrame.Angles(0, -math.pi / 2, 0) },
	{ value = 4, rot = CFrame.Angles(0, math.pi / 2, 0) },
	{ value = 2, rot = CFrame.Angles(math.pi / 2, 0, 0) },
	{ value = 5, rot = CFrame.Angles(-math.pi / 2, 0, 0) },
}

-- Würfel mit Neon-Augen. cf = MITTELPUNKT des Würfels (nicht Fußpunkt).
-- opts: Size, Color, PipColor, Name, Material, Glow (Neon-Kanten-Hülle)
-- Ergebnis: Model mit PrimaryPart "Core".
function Props.Die(parent: Instance, cf: CFrame, opts: Opts?): Model
	local o = opts or {}
	local s = o.Size or 6
	local m = Parts.Model(parent, o.Name or "Die")
	local core = Parts.Part({
		Parent = m,
		Name = "Core",
		CFrame = cf,
		Size = V3(s, s, s),
		Color = o.Color or Palette.White,
		Material = o.Material or Mat.SmoothPlastic,
		CanCollide = false,
	})
	m.PrimaryPart = core
	local pipColor = o.PipColor or Palette.Purple
	local spacing = s * 0.27
	for _, face in FACES do
		for _, uv in PIPS[face.value] do
			local pipCf = cf * face.rot * CF(uv[1] * spacing, uv[2] * spacing, -s / 2) * CFrame.Angles(0, math.pi / 2, 0)
			Parts.Part({
				Parent = m,
				Name = "Pip",
				Shape = Enum.PartType.Cylinder,
				CFrame = pipCf,
				Size = V3(s * 0.07, s * 0.18, s * 0.18),
				Color = pipColor,
				Material = Mat.Neon,
				CanCollide = false,
			})
		end
	end
	return m
end

return Props
