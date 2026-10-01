-- GliderRig (ModuleScript)
-- Ort: ServerScriptService > GliderServer > GliderRig
--
-- Baut ein einfaches Hängegleiter-Modell aus Parts und schweißt es an den
-- HumanoidRootPart. Läuft auf dem Server, damit es später auch andere Spieler
-- sehen. Alle Teile sind Massless und ohne Kollision -> keine Physik-Kosten.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))

local SAIL_COLOR = Color3.fromRGB(255, 120, 30)
local SAIL_COLOR_2 = Color3.fromRGB(255, 200, 60)
local FRAME_COLOR = Color3.fromRGB(45, 45, 50)

-- Maße (relativ zum HumanoidRootPart, vorne = -Z)
local SPAN = 14 -- Spannweite
local CHORD = 7 -- Länge von Nase bis Hinterkante
local SAIL_Y = 5.8
local SAIL_Z = -1.0 -- Flächenschwerpunkt liegt ungefähr über dem Piloten
local BAR_Y = 3.3
local BAR_Z = -1.0

local GliderRig = {}

local function setupPart(part: BasePart, color: Color3, material: Enum.Material?)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

local function attach(root: BasePart, part: BasePart, offset: CFrame, parent: Instance)
	part.CFrame = root.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = part
	weld.C0 = offset
	weld.C1 = CFrame.identity
	weld.Parent = part
	part.Parent = parent
end

-- Dünnes Rohr zwischen zwei Punkten (im Raum des RootParts)
local function rod(root: BasePart, parent: Instance, a: Vector3, b: Vector3, thickness: number)
	local part = Instance.new("Part")
	setupPart(part, FRAME_COLOR, Enum.Material.Metal)
	part.Size = Vector3.new(thickness, thickness, (b - a).Magnitude)
	part.Name = "Rod"
	attach(root, part, CFrame.lookAt((a + b) / 2, b), parent)
end

local function buildGlider(root: BasePart): Model
	local model = Instance.new("Model")
	model.Name = Config.Names.GliderModel

	-- Segel: zwei flache Keile ergeben ein Delta (Nase vorne, Spitzen hinten)
	-- Ein WedgePart, um -90° um Z gedreht, liegt flach; seine Ecken passen dann
	-- genau auf Nase / hintere Mitte / Flügelspitze.
	for side = -1, 1, 2 do
		local wedge = Instance.new("WedgePart")
		setupPart(wedge, side < 0 and SAIL_COLOR or SAIL_COLOR_2, Enum.Material.Fabric)
		wedge.Name = side < 0 and "SailLeft" or "SailRight"
		wedge.Size = Vector3.new(0.3, SPAN / 2, CHORD)
		local offset = CFrame.new(side * SPAN / 4, SAIL_Y, SAIL_Z) * CFrame.Angles(0, 0, -side * math.rad(90))
		attach(root, wedge, offset, model)
	end

	-- Rahmen: Kiel, Querrohr, A-Rahmen mit Steuerbügel, Aufhängung
	local hang = Vector3.new(0, SAIL_Y - 0.3, SAIL_Z + 0.8)
	rod(root, model, Vector3.new(0, SAIL_Y - 0.2, SAIL_Z - CHORD / 2), Vector3.new(0, SAIL_Y - 0.2, SAIL_Z + CHORD / 2 + 0.3), 0.3)
	rod(root, model, Vector3.new(-SPAN / 2 + 0.8, SAIL_Y - 0.25, SAIL_Z + 1.2), Vector3.new(SPAN / 2 - 0.8, SAIL_Y - 0.25, SAIL_Z + 1.2), 0.25)
	local barLeft = Vector3.new(-1.7, BAR_Y, BAR_Z)
	local barRight = Vector3.new(1.7, BAR_Y, BAR_Z)
	rod(root, model, hang, barLeft, 0.2)
	rod(root, model, hang, barRight, 0.2)
	rod(root, model, barLeft, barRight, 0.25)
	rod(root, model, hang, Vector3.new(0, 1.4, 0.35), 0.15) -- Gurt zum Piloten

	return model
end

-- Arme nach oben an den Steuerbügel (nur R15). Wird ggf. mehrfach aufgerufen,
-- weil das Avatar-Aussehen die Gelenke beim Laden neu erzeugen kann.
local function poseArms(character: Model)
	for _, info in { { "RightUpperArm", "RightShoulder" }, { "LeftUpperArm", "LeftShoulder" } } do
		local arm = character:FindFirstChild(info[1])
		local motor = arm and arm:FindFirstChild(info[2])
		if motor and motor:IsA("Motor6D") and not motor:GetAttribute("GliderPosed") then
			motor.C0 = motor.C0 * CFrame.Angles(math.rad(165), 0, 0)
			motor:SetAttribute("GliderPosed", true)
		end
	end
end

function GliderRig.Attach(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not root:IsA("BasePart") then
		warn("[GliderRig] Kein HumanoidRootPart gefunden")
		return
	end

	local old = character:FindFirstChild(Config.Names.GliderModel)
	if old then
		old:Destroy()
	end

	local glider = buildGlider(root)
	glider.Parent = character
	poseArms(character)
end

function GliderRig.PoseArms(character: Model)
	poseArms(character)
end

return GliderRig
