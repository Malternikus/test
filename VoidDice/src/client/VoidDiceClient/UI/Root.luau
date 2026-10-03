--!strict
-- Root (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > UI > Root
--
-- Legt die ScreenGuis an (Ebenen) und skaliert die UI passend zur
-- Bildschirmgröße (UIScale). Auf Touch-Geräten etwas größer, damit Buttons
-- gut treffbar bleiben.
--
--   HUD (1)  ->  Windows (5)  ->  Reveal (10)  ->  Toasts (15)  ->  Tutorial (20)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config"):WaitForChild("UIConfig"))

local Root = {}

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local scales: { UIScale } = {}

Root.Layers = {} :: { [string]: ScreenGui }
Root.Scale = 1
Root.IsTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
Root.IsSmall = false

local function makeLayer(name: string, order: number): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "VoidDice_" .. name
	gui.DisplayOrder = order
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = false
	gui.Parent = playerGui
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	table.insert(scales, scale)
	Root.Layers[name] = gui
	return gui
end

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local size = camera.ViewportSize
	local ref = UIConfig.ReferenceResolution
	local s = math.min(size.X / ref.X, size.Y / ref.Y)
	local minScale = if Root.IsTouch then 0.7 else UIConfig.MinScale
	s = math.clamp(s, minScale, UIConfig.MaxScale)
	Root.Scale = s
	Root.IsSmall = size.Y < 500 or size.X < 900
	for _, scale in scales do
		scale.Scale = s
	end
end

-- Pixelgröße des Bildschirms in UI-Einheiten (nach UIScale)
function Root.screenSize(): Vector2
	local camera = workspace.CurrentCamera
	local size = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	return size / Root.Scale
end

function Root.init()
	makeLayer("HUD", 1)
	makeLayer("Windows", 5)
	makeLayer("Reveal", 10)
	makeLayer("Toasts", 15)
	makeLayer("Tutorial", 20)
	updateScale()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		updateScale()
		if workspace.CurrentCamera then
			workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		end
	end)
end

return Root
