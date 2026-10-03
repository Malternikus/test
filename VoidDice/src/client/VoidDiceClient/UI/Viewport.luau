--!strict
-- Viewport (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > UI > Viewport
--
-- Character-Vorschau in der UI (Reveal, Index, Inventar-Karten).
-- Models werden einmal pro Character+Mutation in LowDetail gebaut (keine
-- Partikel/Lichter) und dann nur noch geklont. Begrenzter Cache.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local UIConfig = require(Shared:WaitForChild("Config"):WaitForChild("UIConfig"))
local ModelFactory = require(Shared:WaitForChild("Visual"):WaitForChild("ModelFactory"))

local Viewport = {}

local cache: { [string]: Model } = {}
local cacheOrder: { string } = {}
local spinning: { [ViewportFrame]: number } = {}

local function template(characterId: string, mutation: string?): Model?
	local key = characterId .. "|" .. (mutation or "Normal")
	local cached = cache[key]
	if cached then
		return cached
	end
	local ok, model = pcall(ModelFactory.Build, characterId, { LowDetail = true, Mutation = mutation, Level = 1 })
	if not ok or not model then
		warn("[Viewport] Model fehlt:", characterId, model)
		return nil
	end
	model:PivotTo(CFrame.new())
	cache[key] = model
	table.insert(cacheOrder, key)
	if #cacheOrder > UIConfig.ViewportCacheSize then
		local oldest = table.remove(cacheOrder, 1) :: string
		local old = cache[oldest]
		cache[oldest] = nil
		if old then
			old:Destroy()
		end
	end
	return model
end

-- Setzt den Inhalt eines ViewportFrames auf einen Character
function Viewport.set(frame: ViewportFrame, characterId: string?, mutation: string?, silhouette: boolean?)
	for _, child in frame:GetChildren() do
		if child:IsA("Model") or child:IsA("Camera") then
			child:Destroy()
		end
	end
	if not characterId then
		return
	end
	local source = template(characterId, mutation)
	if not source then
		return
	end
	local model = source:Clone()
	if silhouette then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Color = Color3.fromRGB(10, 10, 20)
				part.Material = Enum.Material.SmoothPlastic
			end
		end
	end
	model.Parent = frame

	local cf, size = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local maxDim = math.max(size.X, size.Y, size.Z)
	local distance = maxDim * 0.5 / math.tan(math.rad(camera.FieldOfView / 2)) + size.Z * 0.6
	local center = cf.Position
	camera.CFrame = CFrame.lookAt(center + Vector3.new(distance * 0.25, size.Y * 0.08, -distance), center)
	camera.Parent = frame
	frame.CurrentCamera = camera
	frame:SetAttribute("CharacterId", characterId)
end

function Viewport.create(props: { [string]: any }): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.BackgroundTransparency = 1
	frame.Size = props.Size or UDim2.fromScale(1, 1)
	frame.Position = props.Position or UDim2.new()
	frame.AnchorPoint = props.AnchorPoint or Vector2.zero
	frame.Ambient = Color3.fromRGB(170, 170, 200)
	frame.LightColor = Color3.fromRGB(255, 240, 230)
	frame.LightDirection = Vector3.new(-0.4, -1, 0.6)
	frame.ZIndex = props.ZIndex or 2
	frame.Parent = props.Parent
	if props.CharacterId then
		Viewport.set(frame, props.CharacterId, props.Mutation, props.Silhouette)
	end
	return frame
end

-- Langsames Drehen (Reveal, Detail-Ansicht)
function Viewport.spin(frame: ViewportFrame, speed: number?)
	spinning[frame] = speed or 0.6
	frame.Destroying:Once(function()
		spinning[frame] = nil
	end)
end

function Viewport.stopSpin(frame: ViewportFrame)
	spinning[frame] = nil
end

RunService.RenderStepped:Connect(function(dt)
	for frame, speed in spinning do
		local model = frame:FindFirstChildOfClass("Model")
		if model and frame.Visible then
			model:PivotTo(model:GetPivot() * CFrame.Angles(0, speed * dt, 0))
		end
	end
end)

return Viewport
