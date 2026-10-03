--!strict
-- AreaController (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > AreaController
--
-- * Erkennt, in welchem Gebiet der Spieler ist, und blendet Licht/Nebel/
--   Atmosphäre weich über (AreaConfig.Lighting).
-- * Zeigt beim Betreten den Gebietsnamen.
-- * Tore: freigeschaltete Gebiete werden LOKAL geöffnet (CanCollide aus,
--   unsichtbar). Gesperrte bleiben eine Energiebarriere. Der Server prüft
--   Teleports/Fishing trotzdem selbst.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local WorldConfig = require(Config:WaitForChild("WorldConfig"))

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Root = require(Client:WaitForChild("UI"):WaitForChild("Root"))
local Signal = require(Client:WaitForChild("Signal"))

local AreaController = {}

AreaController.current = nil :: string?
AreaController.AreaChanged = Signal.new()

local atmosphere: Atmosphere
local colorCorrection: ColorCorrectionEffect
local titleLabel: TextLabel
local subtitleLabel: TextLabel

local function applyLighting(def: AreaConfig.AreaDef)
	local l = def.Lighting
	UI.tween(Lighting, 2, {
		Ambient = l.Ambient,
		OutdoorAmbient = l.OutdoorAmbient,
		FogColor = l.FogColor,
		FogStart = l.FogStart,
		FogEnd = l.FogEnd,
		ClockTime = l.ClockTime,
		Brightness = l.Brightness,
		ColorShift_Top = l.ColorShift,
	})
	UI.tween(atmosphere, 2, {
		Color = l.FogColor,
		Decay = l.FogColor:Lerp(Color3.new(0, 0, 0), 0.4),
		Density = math.clamp(120 / l.FogEnd, 0.15, 0.55),
	})
	UI.tween(colorCorrection, 2, { TintColor = Color3.new(1, 1, 1):Lerp(def.PrimaryColor, 0.08) })
end

local function showTitle(def: AreaConfig.AreaDef)
	titleLabel.Text = def.DisplayName
	titleLabel.TextColor3 = def.PrimaryColor
	subtitleLabel.Text = def.Tagline
	titleLabel.TextTransparency = 1
	subtitleLabel.TextTransparency = 1
	titleLabel.Visible = true
	subtitleLabel.Visible = true
	UI.tween(titleLabel, 0.6, { TextTransparency = 0 })
	UI.tween(subtitleLabel, 0.6, { TextTransparency = 0.1 })
	task.delay(3, function()
		UI.tween(titleLabel, 0.8, { TextTransparency = 1 })
		UI.tween(subtitleLabel, 0.8, { TextTransparency = 1 })
	end)
end

local function areaAt(position: Vector3): string
	local best = AreaConfig.StartArea
	for _, def in AreaConfig.List do
		if def.Id ~= AreaConfig.StartArea and AreaConfig.Contains(def, position) then
			best = def.Id
		end
	end
	return best
end

-- Tore lokal öffnen/schließen
local function updateGates()
	local world = workspace:FindFirstChild(WorldConfig.WorldFolderName)
	if not world then
		return
	end
	for _, inst in world:GetDescendants() do
		if inst:IsA("BasePart") and inst.Name == "Gate" then
			local areaId = inst:GetAttribute("AreaId") :: string?
			local open = areaId ~= nil and State.data.Areas ~= nil and State.data.Areas[areaId] == true
			inst.CanCollide = not open
			inst.LocalTransparencyModifier = if open then 1 else 0
			for _, child in inst:GetChildren() do
				if child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
					child.Enabled = not open
				elseif child:IsA("ParticleEmitter") then
					child.Enabled = not open
				end
			end
		end
	end
end

function AreaController.init()
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Parent = Lighting
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "VoidDiceTint"
	colorCorrection.Saturation = 0.05
	colorCorrection.Contrast = 0.08
	colorCorrection.Parent = Lighting
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = Lighting

	titleLabel = UI.label({
		Font = UI.Fonts.Title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(700, 70),
		MaxTextSize = 64,
		Visible = false,
		Parent = Root.Layers.Toasts,
	})
	UI.stroke(titleLabel, Color3.new(0, 0, 0), 2).ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	subtitleLabel = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.3, 48),
		Size = UDim2.fromOffset(600, 26),
		TextColor3 = UI.Colors.SubText,
		MaxTextSize = 24,
		Visible = false,
		Parent = Root.Layers.Toasts,
	})

	local start = AreaConfig.Get(AreaConfig.StartArea)
	if start then
		applyLighting(start)
	end

	State.Changed:Connect(function(key)
		if key == "Areas" then
			updateGates()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(WorldConfig.AreaCheckInterval)
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local id = areaAt(root.Position)
				if id ~= AreaController.current then
					AreaController.current = id
					local def = AreaConfig.Get(id)
					if def then
						applyLighting(def)
						showTitle(def)
					end
					AreaController.AreaChanged:Fire(id)
				end
			end
		end
	end)
	-- Tore auch nach Streaming nachziehen
	task.spawn(function()
		while true do
			updateGates()
			task.wait(5)
		end
	end)
end

return AreaController
