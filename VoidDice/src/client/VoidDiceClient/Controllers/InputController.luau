--!strict
-- InputController (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > InputController
--
-- Tastatur-Shortcuts und Controller-Support.
--
--   Tastatur:   R Roll · T Auto · C Collect · I Inventory · X Index · B Shop
--               Q Quests · F Fishing · G Items · M Map · Esc schließt Fenster
--   Controller: R2 Roll · L2 Auto · X Collect · Y Inventory · R1/L1 nächstes/
--               voriges Menü · B schließt Fenster · Steuerkreuz navigiert UI
--               (Roblox-Gamepad-Navigation, alle Buttons sind Selectable)

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Client = script.Parent.Parent
local Actions = require(Client:WaitForChild("Actions"))
local HUD = require(script.Parent:WaitForChild("HUD"))
local WindowManager = require(script.Parent:WaitForChild("WindowManager"))

local InputController = {}

local KEYS: { [Enum.KeyCode]: () -> () } = {
	[Enum.KeyCode.R] = HUD.roll,
	[Enum.KeyCode.T] = HUD.toggleAuto,
	[Enum.KeyCode.C] = function()
		Actions.send("Collect")
	end,
	[Enum.KeyCode.I] = function()
		WindowManager.toggle("Inventory")
	end,
	[Enum.KeyCode.X] = function()
		WindowManager.toggle("Index")
	end,
	[Enum.KeyCode.B] = function()
		WindowManager.toggle("Shop")
	end,
	[Enum.KeyCode.Q] = function()
		WindowManager.toggle("Quests")
	end,
	[Enum.KeyCode.F] = function()
		WindowManager.toggle("Fishing")
	end,
	[Enum.KeyCode.G] = function()
		WindowManager.toggle("Items")
	end,
	[Enum.KeyCode.M] = function()
		WindowManager.toggle("Map")
	end,
	[Enum.KeyCode.Escape] = function()
		WindowManager.close()
	end,
}

local CYCLE = { "Inventory", "Index", "Shop", "Quests", "Fishing", "Items", "Map", "Settings" }

local function cycle(direction: number)
	local current = WindowManager.current
	local index = if current then (table.find(CYCLE, current) or 0) else 0
	index = (index + direction - 1) % #CYCLE + 1
	WindowManager.open(CYCLE[index])
end

local GAMEPAD: { [Enum.KeyCode]: () -> () } = {
	[Enum.KeyCode.ButtonR2] = HUD.roll,
	[Enum.KeyCode.ButtonL2] = HUD.toggleAuto,
	[Enum.KeyCode.ButtonX] = function()
		if not WindowManager.current then
			Actions.send("Collect")
		end
	end,
	[Enum.KeyCode.ButtonY] = function()
		WindowManager.toggle("Inventory")
	end,
	[Enum.KeyCode.ButtonR1] = function()
		cycle(1)
	end,
	[Enum.KeyCode.ButtonL1] = function()
		cycle(-1)
	end,
	[Enum.KeyCode.ButtonB] = function()
		if WindowManager.current then
			WindowManager.close()
		end
	end,
}

function InputController.init()
	UserInputService.InputBegan:Connect(function(input, processed)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		local gamepadFn = GAMEPAD[input.KeyCode]
		if gamepadFn and input.UserInputType.Name:find("Gamepad") then
			-- R2/L2/R1/L1 immer, Rest nur wenn nicht von der UI verarbeitet
			if not processed or input.KeyCode == Enum.KeyCode.ButtonB then
				gamepadFn()
			end
			return
		end
		if processed then
			return
		end
		local fn = KEYS[input.KeyCode]
		if fn then
			fn()
		end
	end)
	GuiService.AutoSelectGuiEnabled = true
end

return InputController
