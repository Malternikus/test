-- GliderClient (LocalScript)
-- Ort: StarterPlayer > StarterPlayerScripts > GliderClient
--
-- Einstiegspunkt auf dem Client. Erstellt alle Systeme einmal und verbindet
-- sie. Die eigentliche Logik steckt in den ModuleScripts darunter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))
local InputController = require(script.InputController)
local CameraController = require(script.CameraController)
local SpeedEffects = require(script.SpeedEffects)
local HUD = require(script.HUD)
local RunManager = require(script.RunManager)

local player = Players.LocalPlayer

-- Standard-Laufsteuerung abschalten (WASD soll nur den Gleiter lenken)
local function disableDefaultControls()
	local ok, err = pcall(function()
		local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: ModuleScript) :: any
		playerModule:GetControls():Disable()
	end)
	if not ok then
		warn("[GliderClient] Standard-Steuerung konnte nicht deaktiviert werden:", err)
	end
end

-- Warten, bis die Map komplett beim Client angekommen ist
local function waitForMap(): (Model, Folder)
	local trackData = ReplicatedStorage:WaitForChild(Config.Names.TrackData) :: Folder
	local map = workspace:WaitForChild(Config.Names.MapModel) :: Model
	local expected = map:GetAttribute("PartCount") or 0
	local deadline = os.clock() + 15
	while os.clock() < deadline do
		local count = 0
		for _, inst in map:GetDescendants() do
			if inst:IsA("BasePart") then
				count += 1
			end
		end
		if count >= expected then
			break
		end
		task.wait(0.25)
	end
	return map, trackData
end

disableDefaultControls()
local map, trackData = waitForMap()

local runManager
local hud = HUD.new(function()
	if runManager then
		runManager:StartRun()
	end
end)
local input = InputController.new(function()
	if runManager then
		runManager:StartRun()
	end
end)
local camera = CameraController.new()
local effects = SpeedEffects.new()

runManager = RunManager.new({
	map = map,
	trackData = trackData,
	hud = hud,
	input = input,
	camera = camera,
	effects = effects,
})

local function onCharacterAdded(character: Model)
	character:WaitForChild("HumanoidRootPart")
	character:WaitForChild("Humanoid")
	-- Der Gleiter wird vom Server angebaut; kurz darauf warten
	character:WaitForChild(Config.Names.GliderModel, 5)
	disableDefaultControls()
	runManager:AttachCharacter(character)
end

player.CharacterRemoving:Connect(function()
	runManager:DetachCharacter()
end)
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
