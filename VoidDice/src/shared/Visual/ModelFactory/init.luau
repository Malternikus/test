--!strict
-- ModelFactory (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Visual > ModelFactory
--
-- Baut prozedurale Placeholder-Models für alle Characters aus CharacterDef.Visual.
-- Keine externen Assets: nur Parts (Block/Ball/Cylinder/Wedge), SpecialMesh mit
-- eingebautem MeshType (Ellipsoide) und Partikel mit rbxasset-Texturen.
--
-- API:
--   ModelFactory.Build(characterId, options?)      -> Model
--   ModelFactory.BuildFromDef(def, options?)       -> Model
--   ModelFactory.ApplyLevelVisual(model, level)    -- idempotent: 5 / 10 / 15 (MAX)
--   ModelFactory.ApplyMutation(model, mutationId)  -- idempotent, "Normal" setzt zurück
--   options = { Level: number?, Mutation: string?, LowDetail: boolean? }
--
-- Model-Vertrag (BaseAnimator / BaseService verlassen sich darauf):
--   * Model.Name = def.Id, Attribute: CharacterId, Rarity, Height (Studs über Root-Unterseite),
--     Width (größte horizontale Ausdehnung in Studs) (+ LowDetail,
--     VisualLevel, Mutation, Body, AnimationSet)
--   * PrimaryPart = unsichtbarer Part "Root" (2 x 0.2 x 2). Seine Unterseite ist der
--     Bodenpunkt (PivotOffset zeigt dorthin): model:PivotTo(groundCFrame) stellt die
--     Füße auf den Boden, Blickrichtung = groundCFrame.LookVector.
--   * Alle BaseParts: Anchored, CanCollide/CanTouch/CanQuery = false, Massless.
--   * Animierbare Gruppen sind Kind-Models mit PrimaryPart "Joint" (winziger,
--     unsichtbarer Part am Drehpunkt, Rotation = Model-Achsen):
--       Head, ArmL, ArmR, Held (in ArmR), WingL, WingR, Tail, Orbit, Core
--     Alles andere liegt im Kind-Model "Body". Es wird NICHT geschweißt.
--   * Effekte (ParticleEmitter, PointLight) hängen an Attachments unter Root:
--       FX_Aura, FX_Level, FX_Mutation. LowDetail = keine Emitter/Lichter.
--
-- Visual-Vokabular: siehe Bodies (Body-Typen), Accessories (Accessory-Ids und
-- HairStyles), Faces (Face-Typen).

local Shared = script.Parent.Parent
local Config = Shared:WaitForChild("Config")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))

local Bodies = require(script:WaitForChild("Bodies"))
local Accessories = require(script:WaitForChild("Accessories"))
local Faces = require(script:WaitForChild("Faces"))
local Effects = require(script:WaitForChild("Effects"))

export type BuildOptions = {
	Level: number?,
	Mutation: string?,
	LowDetail: boolean?,
}

local ModelFactory = {}

-- Für Tests / Debug-UI
ModelFactory.Bodies = Bodies
ModelFactory.Accessories = Accessories
ModelFactory.Faces = Faces
ModelFactory.Effects = Effects

ModelFactory.ROOT_SIZE = Vector3.new(2, 0.2, 2)
ModelFactory.GROUP_NAMES = { "Head", "ArmL", "ArmR", "Held", "WingL", "WingR", "Tail", "Orbit", "Core" }

-------------------------------------------------------------------------------
-- Builder: legt Parts in "unskalierten" Model-Koordinaten an (Boden = y 0,
-- vorne = -Z) und rechnet Scale ein. Zählt Parts und die Bounding-Box.
-------------------------------------------------------------------------------
local Builder = {}
Builder.__index = Builder

local SHAPES = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cyl = Enum.PartType.Cylinder,
}

function Builder.new(model: Model, scale: number, limit: number, lowDetail: boolean)
	local self = setmetatable({
		Model = model,
		S = scale,
		Limit = limit,
		LowDetail = lowDetail,
		Count = 0,
		Created = {} :: { Instance },
		MaxY = 0,
		MaxX = 0,
		MaxZ = 0,
		Body = (nil :: any) :: Model,
		Colors = {} :: { [string]: Color3 },
		Recolored = {} :: { { part: BasePart, color: Color3 } },
	}, Builder)
	return self
end

-- Skaliert eine unskalierte Model-CFrame
function Builder:CF(cf: CFrame): CFrame
	return CFrame.new(cf.Position * self.S) * cf.Rotation
end

function Builder:_track(part: BasePart, size: Vector3, cf: CFrame)
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	local rx, ry, rz = cf.XVector, cf.YVector, cf.ZVector
	local ex = math.abs(rx.X) * hx + math.abs(ry.X) * hy + math.abs(rz.X) * hz
	local ey = math.abs(rx.Y) * hx + math.abs(ry.Y) * hy + math.abs(rz.Y) * hz
	local ez = math.abs(rx.Z) * hx + math.abs(ry.Z) * hy + math.abs(rz.Z) * hz
	local p = cf.Position
	self.MaxY = math.max(self.MaxY, p.Y + ey)
	self.MaxX = math.max(self.MaxX, math.abs(p.X) + ex)
	self.MaxZ = math.max(self.MaxZ, math.abs(p.Z) + ez)
end

local function setupPart(part: BasePart, size: Vector3)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if math.max(size.X, size.Y, size.Z) < 1 then
		part.CastShadow = false
	end
end

export type PartProps = {
	Transparency: number?,
	Role: string?, -- "Eye" | "Glow" | "FX" (nicht von Mutationen eingefärbt)
	Reflectance: number?,
}

-- shape: "Block" | "Ball" (Size.X = Durchmesser) | "Cyl" (Achse = lokale X, Size = Länge, D, D)
--        | "Wedge" | "Corner" | "Sphere" (Ellipsoid per SpecialMesh) | "CylMesh" (elliptischer Zylinder)
function Builder:Part(
	parent: Instance,
	name: string,
	shape: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	props: PartProps?
): BasePart
	local part: BasePart
	if shape == "Wedge" then
		part = Instance.new("WedgePart")
	elseif shape == "Corner" then
		part = Instance.new("CornerWedgePart")
	else
		local p = Instance.new("Part")
		if shape == "Ball" then
			size = Vector3.new(size.X, size.X, size.X)
			p.Shape = Enum.PartType.Ball
		elseif shape == "Cyl" then
			local d = math.max(size.Y, size.Z)
			size = Vector3.new(size.X, d, d)
			p.Shape = Enum.PartType.Cylinder
		elseif SHAPES[shape] == nil and shape ~= "Sphere" and shape ~= "CylMesh" then
			error("[ModelFactory] Unbekannte Part-Form: " .. shape)
		end
		part = p
		if shape == "Sphere" or shape == "CylMesh" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = if shape == "Sphere" then Enum.MeshType.Sphere else Enum.MeshType.Cylinder
			mesh.Parent = part
		end
	end
	local s = self.S
	local finalSize = size * s
	local finalCF = self:CF(cf)
	part.Name = name
	part.Size = finalSize
	part.CFrame = finalCF
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	setupPart(part, finalSize)
	local pr = props
	if pr then
		if pr.Transparency then
			part.Transparency = pr.Transparency
		end
		if pr.Reflectance then
			part.Reflectance = pr.Reflectance
		end
		if pr.Role then
			part:SetAttribute("VDRole", pr.Role)
		end
	end
	if part.Material == Enum.Material.Neon and not (pr and pr.Role) then
		part:SetAttribute("VDRole", "Glow")
	end
	part.Parent = parent
	self.Count += 1
	table.insert(self.Created, part)
	if part.Transparency < 0.95 then
		self:_track(part, finalSize, finalCF)
	end
	return part
end

-- Animierbare Gruppe mit "Joint" als PrimaryPart (Drehpunkt = jointPos, unskaliert)
function Builder:Group(name: string, parent: Instance, jointPos: Vector3): Model
	local g = Instance.new("Model")
	g.Name = name
	local joint = Instance.new("Part")
	joint.Name = "Joint"
	joint.Size = Vector3.new(0.1, 0.1, 0.1)
	joint.CFrame = CFrame.new(jointPos * self.S)
	joint.Transparency = 1
	setupPart(joint, joint.Size)
	joint.Parent = g
	g.PrimaryPart = joint
	g.Parent = parent
	self.Count += 1
	table.insert(self.Created, g)
	return g
end

-- Gruppe holen oder anlegen (z. B. Orbit wird von mehreren Accessories geteilt)
function Builder:GetGroup(name: string, parent: Instance, jointPos: Vector3): Model
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Model") then
		return existing
	end
	return self:Group(name, parent, jointPos)
end

function Builder:Remaining(): number
	return self.Limit - self.Count
end

-- Checkpoint/Rollback: Accessories, die das Part-Budget sprengen, werden wieder entfernt
function Builder:Checkpoint()
	return {
		n = #self.Created,
		count = self.Count,
		maxY = self.MaxY,
		maxX = self.MaxX,
		maxZ = self.MaxZ,
		recolor = #self.Recolored,
	}
end

function Builder:Rollback(cp)
	for i = #self.Created, cp.n + 1, -1 do
		local inst = self.Created[i]
		self.Created[i] = nil
		if inst.Parent ~= nil then
			inst.Parent = nil
		end
		inst:Destroy()
	end
	for i = #self.Recolored, cp.recolor + 1, -1 do
		local r = self.Recolored[i]
		r.part.Color = r.color
		self.Recolored[i] = nil
	end
	self.Count = cp.count
	self.MaxY = cp.maxY
	self.MaxX = cp.maxX
	self.MaxZ = cp.maxZ
end

-- Bestehenden Part umfärben (z. B. Ärmel unter einem Laborkittel), rollback-fähig
function Builder:Recolor(part: Instance?, color: Color3, material: Enum.Material?)
	if part and part:IsA("BasePart") then
		table.insert(self.Recolored, { part = part, color = part.Color })
		part.Color = color
		if material then
			part.Material = material
		end
	end
end

ModelFactory.Builder = Builder

-------------------------------------------------------------------------------
-- Farben auflösen
-------------------------------------------------------------------------------
local COLOR_KEYS = { "Skin", "Hair", "Top", "Bottom", "Shoes", "Accent", "Glow" }

local function resolveColors(visual: any): { [string]: Color3 }
	local defaults = Bodies.Defaults[visual.Body] or Bodies.Defaults.Teen
	local out = {}
	for _, key in COLOR_KEYS do
		out[key] = visual[key] or defaults[key]
	end
	return out
end

-------------------------------------------------------------------------------
-- Build
-------------------------------------------------------------------------------
local function emptyModel(id: string): Model
	local model = Instance.new("Model")
	model.Name = id
	return model
end

function ModelFactory.BuildFromDef(def: any, options: BuildOptions?): Model
	local opts: BuildOptions = options or {}
	local lowDetail = opts.LowDetail == true
	local visual = def.Visual or { Body = "Teen" }
	local bodyType = visual.Body
	if Bodies.Builders[bodyType] == nil then
		warn("[ModelFactory] Unbekannter Body-Typ '" .. tostring(bodyType) .. "' bei " .. tostring(def.Id))
		bodyType = "Teen"
	end
	local scale = math.clamp(visual.Scale or 1, 0.4, 3)
	local model = emptyModel(def.Id)

	local limit = (Bodies.Budget[bodyType] or 45) - Effects.RESERVED_PARTS
	local ctx = Builder.new(model, scale, limit, lowDetail)

	-- Root: Unterseite = Boden
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = ModelFactory.ROOT_SIZE
	root.CFrame = CFrame.new(0, ModelFactory.ROOT_SIZE.Y / 2, 0)
	root.Transparency = 1
	setupPart(root, root.Size)
	root.CastShadow = false
	root.PivotOffset = CFrame.new(0, -ModelFactory.ROOT_SIZE.Y / 2, 0)
	root.Parent = model
	model.PrimaryPart = root
	ctx.Count += 1

	local body = Instance.new("Model")
	body.Name = "Body"
	body.Parent = model
	ctx.Body = body

	local colors = resolveColors(visual)
	ctx.Colors = colors

	-- 1) Körper
	local anchors = Bodies.Builders[bodyType](ctx, colors, visual)
	anchors.BodyType = bodyType

	-- 2) Gesicht
	if anchors.Face then
		local faceType = visual.Face or Bodies.DefaultFace[bodyType] or "Smile"
		Faces.Build(ctx, anchors.Face, faceType, colors)
	end

	-- 3) Haare
	local hairStyle = visual.HairStyle
	if hairStyle and hairStyle ~= "None" and anchors.Head then
		Accessories.BuildHair(ctx, anchors, hairStyle, colors)
	end

	-- 4) Accessories (jedes einzeln budgetiert, rollt bei Überschreitung zurück).
	-- Verworfene (Budget/Fehler) und übersprungene (kein passender Anker) Ids
	-- landen zur Kontrolle im Attribut "SkippedAccessories".
	local skipped = {}
	if visual.Accessories then
		for _, accessoryId in visual.Accessories do
			local before = #ctx.Created + #ctx.Recolored
			local ok = Accessories.Build(ctx, anchors, accessoryId, colors)
			if not ok or #ctx.Created + #ctx.Recolored == before then
				table.insert(skipped, accessoryId)
			end
		end
	end
	if #skipped > 0 then
		model:SetAttribute("SkippedAccessories", table.concat(skipped, ","))
	end

	-- Attribute
	local height = math.max(ctx.MaxY, 0.5 * scale)
	local width = math.max(ctx.MaxX, ctx.MaxZ, 0.5) * 2
	model:SetAttribute("CharacterId", def.Id)
	model:SetAttribute("Rarity", def.Rarity)
	model:SetAttribute("Height", math.floor(height * 100 + 0.5) / 100)
	model:SetAttribute("Width", math.floor(width * 100 + 0.5) / 100)
	model:SetAttribute("Body", bodyType)
	model:SetAttribute("AnimationSet", def.AnimationSet or "Default")
	model:SetAttribute("LowDetail", lowDetail)
	model:SetAttribute("PartCount", ctx.Count)

	-- 5) Aura, Level, Mutation
	if def.AuraReference then
		Effects.ApplyAura(model, def.AuraReference)
	end
	local level = opts.Level or 1
	if level >= 5 then
		Effects.ApplyLevel(model, level)
	end
	if opts.Mutation and opts.Mutation ~= "Normal" then
		Effects.ApplyMutation(model, opts.Mutation)
	end

	return model
end

function ModelFactory.Build(characterId: string, options: BuildOptions?): Model
	local def = CharacterConfig.Get(characterId)
	if not def then
		warn("[ModelFactory] Unbekannte Character-Id: " .. tostring(characterId))
		def = {
			Id = characterId,
			Rarity = "Common",
			AnimationSet = "Default",
			Visual = { Body = "Teen", Face = "Blank", Top = Color3.fromRGB(255, 0, 255) },
		} :: any
	end
	local fromAsset = ModelFactory.FromAsset(def, options)
	if fromAsset then
		return fromAsset
	end
	return ModelFactory.BuildFromDef(def, options)
end

-- Fertige Models statt Placeholder: ModelReference = "Asset:<Name>" sucht
-- ReplicatedStorage > VoidDiceAssets > Characters > <Name>. Das Model muss
-- denselben Vertrag erfüllen wie die Placeholder (PrimaryPart "Root" an den
-- Füßen, verankerte Teile, optionale Gruppen Head/ArmL/ArmR … mit "Joint").
-- Fehlt es, wird der Placeholder gebaut.
function ModelFactory.FromAsset(def: any, options: BuildOptions?): Model?
	local reference = def.ModelReference
	if type(reference) ~= "string" or reference:sub(1, 6) ~= "Asset:" then
		return nil
	end
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("VoidDiceAssets")
	local folder = assets and assets:FindFirstChild("Characters")
	local source = folder and folder:FindFirstChild(reference:sub(7))
	if not source or not source:IsA("Model") or not source.PrimaryPart then
		warn("[ModelFactory] Asset fehlt oder hat keinen PrimaryPart: " .. reference .. " – nutze Placeholder")
		return nil
	end
	local model = source:Clone()
	model.Name = def.Id
	local _, size = model:GetBoundingBox()
	model:SetAttribute("CharacterId", def.Id)
	model:SetAttribute("Rarity", def.Rarity)
	model:SetAttribute("Height", size.Y)
	model:SetAttribute("Width", math.max(size.X, size.Z))
	model:SetAttribute("AnimationSet", def.AnimationSet)
	local opts = options or {}
	model:SetAttribute("LowDetail", opts.LowDetail == true)
	if opts.Level then
		Effects.ApplyLevel(model, opts.Level)
	end
	if opts.Mutation then
		Effects.ApplyMutation(model, opts.Mutation)
	end
	return model
end

function ModelFactory.ApplyLevelVisual(model: Model, level: number)
	Effects.ApplyLevel(model, level)
end

function ModelFactory.ApplyMutation(model: Model, mutationId: string)
	Effects.ApplyMutation(model, mutationId)
end

return ModelFactory
