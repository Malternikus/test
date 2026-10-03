--!strict
-- Parts (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > World > Parts
--
-- Kleiner Baukasten für die prozedurale Map. Alle Builder (Props, Hub, Plot,
-- Areas, Road) erzeugen ihre Teile ausschließlich über diese Helfer, damit
--   * Defaults (Anchored, Smooth Surfaces, CanTouch aus ...) überall gleich sind,
--   * die Farbpalette zentral bleibt,
--   * Lichter global gedeckelt werden (Performance auf Mobile).
--
-- Konvention für CFrames: "Front" eines Teils = LookVector (lokal -Z).
-- Zylinder liegen in Roblox entlang der lokalen X-Achse; für stehende
-- Zylinder gibt es VCyl/Disc.

local Parts = {}

export type Opts = { [string]: any }

-------------------------------------------------------------------------------
-- Palette (80s Mystery: Navy, Lila, Elektrisch-Blau, warmes Orange, Rot)
-------------------------------------------------------------------------------
Parts.Palette = {
	Navy = Color3.fromRGB(20, 22, 48),
	NavyLight = Color3.fromRGB(38, 42, 82),
	Night = Color3.fromRGB(12, 12, 26),
	Asphalt = Color3.fromRGB(38, 38, 50),
	AsphaltDark = Color3.fromRGB(26, 26, 36),
	Concrete = Color3.fromRGB(98, 100, 112),
	ConcreteDark = Color3.fromRGB(64, 66, 78),
	Wood = Color3.fromRGB(116, 78, 50),
	WoodDark = Color3.fromRGB(72, 48, 34),
	WoodLight = Color3.fromRGB(170, 128, 86),
	Metal = Color3.fromRGB(86, 90, 104),
	MetalDark = Color3.fromRGB(42, 44, 56),
	Black = Color3.fromRGB(14, 12, 20),
	White = Color3.fromRGB(232, 230, 238),
	Beige = Color3.fromRGB(198, 186, 158),
	Paper = Color3.fromRGB(238, 228, 198),
	Cork = Color3.fromRGB(176, 130, 82),
	Bark = Color3.fromRGB(64, 46, 36),
	BarkGrey = Color3.fromRGB(78, 74, 72),
	Leaf = Color3.fromRGB(30, 62, 44),
	LeafDark = Color3.fromRGB(20, 42, 32),
	Rock = Color3.fromRGB(72, 70, 84),
	Purple = Color3.fromRGB(150, 70, 255),
	PurpleDeep = Color3.fromRGB(70, 30, 140),
	ElectricBlue = Color3.fromRGB(60, 140, 255),
	Cyan = Color3.fromRGB(70, 230, 255),
	Orange = Color3.fromRGB(255, 150, 60),
	Amber = Color3.fromRGB(255, 196, 90),
	Red = Color3.fromRGB(236, 40, 52),
	Yellow = Color3.fromRGB(255, 212, 70),
	Green = Color3.fromRGB(70, 224, 110),
	Magenta = Color3.fromRGB(255, 70, 190),
	Teal = Color3.fromRGB(40, 230, 190),
	Screen = Color3.fromRGB(90, 255, 150),
}

-- Farben der Lichterketten ("Communication Lights")
Parts.BulbColors = {
	Color3.fromRGB(255, 60, 60),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(60, 160, 255),
	Color3.fromRGB(80, 230, 110),
	Color3.fromRGB(255, 120, 40),
	Color3.fromRGB(230, 90, 255),
}

-- Hausfarben (80er Holzverkleidung, leicht entsättigt)
Parts.HouseColors = {
	Color3.fromRGB(150, 120, 96),
	Color3.fromRGB(96, 116, 140),
	Color3.fromRGB(140, 140, 112),
	Color3.fromRGB(122, 96, 112),
	Color3.fromRGB(104, 128, 108),
	Color3.fromRGB(170, 150, 120),
}

-------------------------------------------------------------------------------
-- Statistik / Limits
-------------------------------------------------------------------------------
Parts.MaxLights = 60
Parts.Stats = { Parts = 0, Lights = 0, SkippedLights = 0 }

function Parts.ResetStats()
	Parts.Stats.Parts = 0
	Parts.Stats.Lights = 0
	Parts.Stats.SkippedLights = 0
end

-------------------------------------------------------------------------------
-- Grundbausteine
-------------------------------------------------------------------------------

-- Universeller Part-Konstruktor. Felder in props:
--   Class, Name, Parent, CFrame, Size, Color, Material, Transparency,
--   Reflectance, Shape, CanCollide, CanQuery, CastShadow, Attributes
function Parts.Part(props: Opts): BasePart
	local part = Instance.new(props.Class or "Part") :: any
	part.Name = props.Name or "Part"
	part.Anchored = true
	if props.Shape ~= nil then
		part.Shape = props.Shape
	end
	part.Size = props.Size or Vector3.new(4, 1, 4)
	part.CFrame = props.CFrame or CFrame.new()
	part.Color = props.Color or Parts.Palette.Concrete
	local material = props.Material or Enum.Material.SmoothPlastic
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanTouch = false -- niemand nutzt Touched auf Map-Teilen
	local canCollide = if props.CanCollide == nil then true else props.CanCollide
	part.CanCollide = canCollide
	part.CanQuery = if props.CanQuery == nil then canCollide else props.CanQuery
	if props.CastShadow ~= nil then
		part.CastShadow = props.CastShadow
	elseif material == Enum.Material.Neon or not canCollide then
		part.CastShadow = false
	end
	if props.Transparency then
		part.Transparency = props.Transparency
	end
	if props.Reflectance then
		part.Reflectance = props.Reflectance
	end
	if props.Attributes then
		for key, value in props.Attributes do
			part:SetAttribute(key, value)
		end
	end
	part.Parent = props.Parent
	Parts.Stats.Parts += 1
	return part
end

function Parts.Box(parent: Instance, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, name: string?): BasePart
	return Parts.Part({ Parent = parent, CFrame = cf, Size = size, Color = color, Material = material, Name = name })
end

-- Leuchtendes Deko-Teil (ohne Kollision, ohne Schatten)
function Parts.Neon(parent: Instance, cf: CFrame, size: Vector3, color: Color3, name: string?, transparency: number?): BasePart
	return Parts.Part({
		Parent = parent,
		CFrame = cf,
		Size = size,
		Color = color,
		Material = Enum.Material.Neon,
		Name = name or "Neon",
		CanCollide = false,
		Transparency = transparency,
	})
end

function Parts.Glass(parent: Instance, cf: CFrame, size: Vector3, color: Color3, transparency: number?, name: string?): BasePart
	return Parts.Part({
		Parent = parent,
		CFrame = cf,
		Size = size,
		Color = color,
		Material = Enum.Material.Glass,
		Transparency = transparency or 0.5,
		Name = name or "Glass",
	})
end

-- Deko ohne Kollision (Kabel, Papiere, Schnüre ...)
function Parts.Detail(parent: Instance, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?, name: string?): BasePart
	return Parts.Part({
		Parent = parent,
		CFrame = cf,
		Size = size,
		Color = color,
		Material = material,
		Name = name or "Detail",
		CanCollide = false,
	})
end

-- Unsichtbares Hilfsteil (PromptPart, SpawnPoint, ArrivalPoint, Grenzen)
function Parts.Invisible(parent: Instance, cf: CFrame, size: Vector3, name: string, canCollide: boolean?): BasePart
	return Parts.Part({
		Parent = parent,
		CFrame = cf,
		Size = size,
		Name = name,
		Transparency = 1,
		CanCollide = canCollide == true,
		CanQuery = canCollide == true,
		CastShadow = false,
		Color = Parts.Palette.White,
	})
end

-- Zylinder entlang der lokalen X-Achse von cf
function Parts.Cyl(parent: Instance, cf: CFrame, length: number, diameter: number, color: Color3, material: Enum.Material?, name: string?): BasePart
	return Parts.Part({
		Parent = parent,
		CFrame = cf,
		Size = Vector3.new(length, diameter, diameter),
		Color = color,
		Material = material,
		Shape = Enum.PartType.Cylinder,
		Name = name or "Cylinder",
	})
end

-- Stehender Zylinder; cf = Mittelpunkt
function Parts.VCyl(parent: Instance, cf: CFrame, height: number, diameter: number, color: Color3, material: Enum.Material?, name: string?): BasePart
	return Parts.Cyl(parent, cf * CFrame.Angles(0, 0, math.pi / 2), height, diameter, color, material, name)
end

-- Kugel (Shape Ball -> Größe immer gleichmäßig)
function Parts.Ball(parent: Instance, cf: CFrame, diameter: number, color: Color3, material: Enum.Material?, name: string?): BasePart
	return Parts.Part({
		Parent = parent,
		CFrame = cf,
		Size = Vector3.new(diameter, diameter, diameter),
		Color = color,
		Material = material,
		Shape = Enum.PartType.Ball,
		Name = name or "Ball",
		CanCollide = false,
	})
end

-- CFrame, dessen LookVector entlang dir zeigt (robust auch bei senkrechtem dir;
-- CFrame.lookAt ist bei parallelem Up-Vektor undefiniert und im Lune-Emulator
-- fehlerhaft, deshalb fromMatrix).
function Parts.LookAlong(pos: Vector3, dir: Vector3): CFrame
	local look = dir.Unit
	local upRef = if math.abs(look.Y) > 0.98 then Vector3.new(1, 0, 0) else Vector3.new(0, 1, 0)
	local right = look:Cross(upRef).Unit
	local up = right:Cross(look).Unit
	return CFrame.fromMatrix(pos, right, up, -look)
end

-- Quader von p0 nach p1 (Schnüre, Kabel, Streben, Rohre)
function Parts.Beam(parent: Instance, p0: Vector3, p1: Vector3, thickness: number, color: Color3, material: Enum.Material?, name: string?, collide: boolean?): BasePart
	local delta = p1 - p0
	local len = math.max(delta.Magnitude, 0.05)
	return Parts.Part({
		Parent = parent,
		CFrame = Parts.LookAlong((p0 + p1) / 2, if delta.Magnitude > 0.001 then delta else Vector3.new(0, 0, -1)),
		Size = Vector3.new(thickness, thickness, len),
		Color = color,
		Material = material,
		Name = name or "Beam",
		CanCollide = collide == true,
	})
end

-- Ring aus Quader-Segmenten in der lokalen XY-Ebene von cf (Normale = lokale Z).
function Parts.Ring(parent: Instance, cf: CFrame, radius: number, segments: number, thickness: number, depth: number, color: Color3, material: Enum.Material?, name: string?): { BasePart }
	local out = {}
	local segLen = 2 * radius * math.tan(math.pi / segments) + thickness * math.tan(math.pi / segments) + 0.05
	for i = 0, segments - 1 do
		local a = (i / segments) * math.pi * 2
		local segCf = cf * CFrame.Angles(0, 0, a) * CFrame.new(0, radius, 0)
		local p = Parts.Part({
			Parent = parent,
			CFrame = segCf,
			Size = Vector3.new(segLen, thickness, depth),
			Color = color,
			Material = material or Enum.Material.Neon,
			Name = name or "RingSegment",
			CanCollide = false,
		})
		table.insert(out, p)
	end
	return out
end

function Parts.Model(parent: Instance?, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Parts.Folder(parent: Instance?, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-------------------------------------------------------------------------------
-- Lichter (global gedeckelt)
-------------------------------------------------------------------------------

-- kind: "Point" (Default), "Spot", "Surface"
function Parts.Light(part: BasePart, color: Color3, range: number, brightness: number?, kind: string?, face: Enum.NormalId?): Light?
	if Parts.Stats.Lights >= Parts.MaxLights then
		Parts.Stats.SkippedLights += 1
		return nil
	end
	local light: any
	if kind == "Spot" then
		light = Instance.new("SpotLight")
		light.Face = face or Enum.NormalId.Bottom
		light.Angle = 100
	elseif kind == "Surface" then
		light = Instance.new("SurfaceLight")
		light.Face = face or Enum.NormalId.Front
		light.Angle = 120
	else
		light = Instance.new("PointLight")
	end
	light.Color = color
	light.Range = range
	light.Brightness = brightness or 1.5
	light.Shadows = false
	light.Parent = part
	Parts.Stats.Lights += 1
	return light
end

-------------------------------------------------------------------------------
-- Text (SurfaceGui / BillboardGui)
-------------------------------------------------------------------------------

local function makeLabel(parent: Instance, name: string, text: string, pos: UDim2, size: UDim2, color: Color3, font: Enum.Font, stroke: Color3?)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = pos
	label.Size = size
	label.Font = font
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	if stroke then
		label.TextStrokeColor3 = stroke
		label.TextStrokeTransparency = 0.35
	else
		label.TextStrokeTransparency = 1
	end
	label.Parent = parent
	return label
end

-- Schild auf einer Fläche: TextLabels "Title" (+ optional "Subtitle") direkt
-- unter dem SurfaceGui. opts: Name, Font, SubFont, TitleColor, SubtitleColor,
-- Background (Color3), PixelsPerStud, Stroke (Color3)
function Parts.SurfaceLabel(part: BasePart, face: Enum.NormalId, title: string, subtitle: string?, opts: Opts?): SurfaceGui
	local o = opts or {}
	local gui = Instance.new("SurfaceGui")
	gui.Name = o.Name or "LabelGui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = o.PixelsPerStud or 20
	gui.LightInfluence = 0
	gui.MaxDistance = o.MaxDistance or 400
	if o.Background then
		local bg = Instance.new("Frame")
		bg.Name = "Background"
		bg.BorderSizePixel = 0
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = o.Background
		bg.BackgroundTransparency = o.BackgroundTransparency or 0
		bg.ZIndex = 0
		bg.Parent = gui
	end
	local font = o.Font or Enum.Font.Arcade
	local titleColor = o.TitleColor or Parts.Palette.White
	if subtitle then
		makeLabel(gui, "Title", title, UDim2.fromScale(0.04, 0.06), UDim2.fromScale(0.92, 0.56), titleColor, font, o.Stroke)
		makeLabel(gui, "Subtitle", subtitle, UDim2.fromScale(0.06, 0.64), UDim2.fromScale(0.88, 0.3), o.SubtitleColor or titleColor, o.SubFont or font, o.Stroke)
	else
		makeLabel(gui, "Title", title, UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.92, 0.84), titleColor, font, o.Stroke)
	end
	gui.Parent = part
	return gui
end

-- Schwebender Titel über einem Teil. opts: Name, Width, Height (Studs),
-- Offset (Vector3), MaxDistance, TitleColor, SubtitleColor, Font
function Parts.Billboard(part: BasePart, title: string, subtitle: string?, opts: Opts?): BillboardGui
	local o = opts or {}
	local gui = Instance.new("BillboardGui")
	gui.Name = o.Name or "TitleGui"
	gui.Size = UDim2.fromScale(o.Width or 16, o.Height or 4.5)
	gui.StudsOffset = o.Offset or Vector3.new(0, 6, 0)
	gui.MaxDistance = o.MaxDistance or 160
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	local font = o.Font or Enum.Font.Arcade
	local titleColor = o.TitleColor or Parts.Palette.White
	local stroke = o.Stroke or Parts.Palette.Night
	if subtitle then
		makeLabel(gui, "Title", title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.62), titleColor, font, stroke)
		makeLabel(gui, "Subtitle", subtitle, UDim2.fromScale(0.1, 0.64), UDim2.fromScale(0.8, 0.34), o.SubtitleColor or titleColor, font, stroke)
	else
		makeLabel(gui, "Title", title, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), titleColor, font, stroke)
	end
	gui.Parent = part
	return gui
end

-------------------------------------------------------------------------------
-- Partikel (Sporen, Nebel, Funken)
-------------------------------------------------------------------------------

-- opts: Color (Color3), Rate, Size, Lifetime, Speed, LightEmission, Transparency
function Parts.Particles(part: BasePart, opts: Opts?): ParticleEmitter
	local o = opts or {}
	local pe = Instance.new("ParticleEmitter")
	pe.Name = o.Name or "Particles"
	pe.Color = ColorSequence.new(o.Color or Parts.Palette.Purple)
	pe.Rate = o.Rate or 6
	pe.Lifetime = NumberRange.new(o.Lifetime or 5, (o.Lifetime or 5) * 1.6)
	pe.Speed = NumberRange.new(o.Speed or 0.6, (o.Speed or 0.6) * 2)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, o.Size or 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, o.Transparency or 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.LightEmission = o.LightEmission or 1
	pe.Acceleration = o.Acceleration or Vector3.new(0, 0.4, 0)
	pe.Parent = part
	return pe
end

-------------------------------------------------------------------------------
-- Geometrie-Hilfen
-------------------------------------------------------------------------------

-- Teile (BasePart) unter einer Instanz zählen
function Parts.CountParts(root: Instance): number
	local n = 0
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

-- Flache CFrame an Position, die zu target "schaut" (nur Y-Rotation).
-- Über CFrame.Angles statt CFrame.lookAt (lookAt ist im Lune-Emulator fehlerhaft).
function Parts.FaceTowards(pos: Vector3, target: Vector3): CFrame
	local dx, dz = target.X - pos.X, target.Z - pos.Z
	if dx * dx + dz * dz < 1e-6 then
		return CFrame.new(pos)
	end
	-- Angles(0, a, 0) dreht (0,0,-1) auf (-sin a, 0, -cos a)
	return CFrame.new(pos) * CFrame.Angles(0, math.atan2(-dx, -dz), 0)
end

return Parts
