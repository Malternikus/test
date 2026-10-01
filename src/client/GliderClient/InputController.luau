-- InputController (ModuleScript)
-- Ort: StarterPlayerScripts > GliderClient > InputController
--
-- Sammelt alle Eingabequellen und liefert EINEN Steuer-Vektor:
--   X = -1 (links) .. +1 (rechts)
--   Y = -1 (runter) .. +1 (hoch)
--
-- Der Rest des Spiels kennt nur diesen Vektor. Neue Eingabearten (Mobile-
-- Joystick, Neigungssensor, ...) müssen nur SetExternalInput() aufrufen oder
-- hier eine weitere Quelle ergänzen; FlightController bleibt unverändert.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))

local KEYS_LEFT = { Enum.KeyCode.A, Enum.KeyCode.Left }
local KEYS_RIGHT = { Enum.KeyCode.D, Enum.KeyCode.Right }
local KEYS_UP = { Enum.KeyCode.W, Enum.KeyCode.Up }
local KEYS_DOWN = { Enum.KeyCode.S, Enum.KeyCode.Down }

local InputController = {}
InputController.__index = InputController

function InputController.new(onRestart: () -> ())
	local self = setmetatable({}, InputController)
	self._gamepad = Vector2.zero
	self._external = Vector2.zero
	self._connections = {} :: { RBXScriptConnection }

	-- Gamepad-Stick (Controller funktioniert damit schon jetzt)
	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			if p.Magnitude < Config.Input.GamepadDeadzone then
				p = Vector2.zero
			end
			self._gamepad = p
		end
	end))
	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			self._gamepad = Vector2.zero
		end
	end))

	-- Neustart: R-Taste oder Y/Select am Controller
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Config.Run.RestartKey or input.KeyCode == Enum.KeyCode.ButtonY or input.KeyCode == Enum.KeyCode.ButtonSelect then
			onRestart()
		end
	end))

	return self
end

local function anyDown(keys: { Enum.KeyCode }): boolean
	for _, key in keys do
		if UserInputService:IsKeyDown(key) then
			return true
		end
	end
	return false
end

function InputController:_keyboard(): Vector2
	-- Während im Chat getippt wird, nicht lenken
	if UserInputService:GetFocusedTextBox() then
		return Vector2.zero
	end
	local x, y = 0, 0
	if anyDown(KEYS_LEFT) then
		x -= 1
	end
	if anyDown(KEYS_RIGHT) then
		x += 1
	end
	if anyDown(KEYS_UP) then
		y += 1
	end
	if anyDown(KEYS_DOWN) then
		y -= 1
	end
	return Vector2.new(x, y)
end

-- Für spätere Mobile-/Touch-Steuerung: Wert -1..1 pro Achse setzen.
function InputController:SetExternalInput(value: Vector2)
	self._external = value
end

-- Wird einmal pro Frame vom RunManager abgefragt.
function InputController:GetMoveVector(): Vector2
	local sum = self:_keyboard() + self._gamepad + self._external
	local x = math.clamp(sum.X, -1, 1)
	local y = math.clamp(sum.Y, -1, 1)
	if Config.Input.InvertPitch then
		y = -y
	end
	return Vector2.new(x, y)
end

function InputController:Destroy()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

return InputController
