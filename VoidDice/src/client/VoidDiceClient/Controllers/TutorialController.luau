--!strict
-- TutorialController (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > TutorialController
--
-- Erster Join: 30–60 Sekunden, 6 Schritte (GameConfig.TutorialSteps):
--   Roll -> Reveal -> Place -> Collect -> Upgrade -> Fishing
-- Jeder Schritt zeigt einen Hinweis + pulsierenden Rahmen um das Ziel und
-- wird durch die echte Aktion abgeschlossen. "SKIP" beendet sofort.
-- Fortschritt liegt im Profil (Server), ein Rejoin macht dort weiter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config"):WaitForChild("GameConfig"))

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Root = require(Client:WaitForChild("UI"):WaitForChild("Root"))
local HUD = require(script.Parent:WaitForChild("HUD"))
local WindowManager = require(script.Parent:WaitForChild("WindowManager"))

local C = UI.Colors

local TutorialController = {}

local panel: Frame
local textLabel: TextLabel
local stepLabel: TextLabel
local highlight: Frame
local target: GuiObject? = nil
local reported: { [string]: boolean } = {}

local function currentStep(): (number, any)
	local tutorial = State.data.Tutorial
	if not tutorial or tutorial.Done then
		return 0, nil
	end
	return tutorial.Step, GameConfig.TutorialSteps[tutorial.Step]
end

local function complete(stepId: string)
	local _, step = currentStep()
	if step and step.Id == stepId and not reported[stepId] then
		reported[stepId] = true
		Actions.send("TutorialStep", stepId)
	end
end

local function targetFor(stepId: string): GuiObject?
	if stepId == "Roll" then
		return HUD.RollButton
	elseif stepId == "Collect" then
		return if HUD.CollectButton and HUD.CollectButton.Visible then HUD.CollectButton else nil
	elseif stepId == "Upgrade" or stepId == "Place" then
		return HUD.MenuButtons.Inventory
	elseif stepId == "Fishing" then
		return HUD.MenuButtons.Fishing
	end
	return nil
end

local function refresh()
	local index, step = currentStep()
	if not step then
		panel.Visible = false
		highlight.Visible = false
		target = nil
		return
	end
	panel.Visible = true
	textLabel.Text = step.Text
	stepLabel.Text = string.format("TUTORIAL %d/%d", index, #GameConfig.TutorialSteps)
	target = targetFor(step.Id)
	highlight.Visible = target ~= nil

	-- Schritte, die automatisch weiterlaufen
	if step.Id == "Reveal" then
		task.delay(2.5, complete, "Reveal")
	elseif step.Id == "Place" then
		for _, char in State.data.Characters or {} do
			if char.Slot then
				task.delay(2.5, complete, "Place")
				break
			end
		end
	elseif step.Id == "Collect" and State.derived.AutoCollect then
		complete("Collect")
	elseif step.Id == "Fishing" then
		task.delay(5, complete, "Fishing")
	end
end

function TutorialController.init()
	local gui = Root.Layers.Tutorial
	panel = UI.panel({
		Name = "Tutorial",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 132),
		Size = UDim2.fromOffset(460, 84),
		StrokeColor = C.Gold,
		Visible = false,
		Parent = gui,
	})
	stepLabel = UI.label({ Text = "", TextColor3 = C.Gold, Font = UI.Fonts.Title, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -110, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 16, Parent = panel })
	textLabel = UI.label({ Text = "", Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -110, 0, 50), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 22, Parent = panel })
	UI.button({
		Text = "SKIP",
		Color = C.PanelLight,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(84, 48),
		TextSize = 20,
		Parent = panel,
		OnClick = function()
			Actions.send("SkipTutorial")
		end,
	})

	highlight = UI.new("Frame", {
		Name = "Highlight",
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 100,
		Parent = gui,
	})
	local stroke = UI.stroke(highlight, C.Gold, 4)
	UI.corner(highlight, 16)
	RunService.RenderStepped:Connect(function()
		if target and target.Parent and highlight.Visible then
			local pos = target.AbsolutePosition / Root.Scale
			local size = target.AbsoluteSize / Root.Scale
			highlight.Position = UDim2.fromOffset(pos.X - 6, pos.Y - 6)
			highlight.Size = UDim2.fromOffset(size.X + 12, size.Y + 12)
			stroke.Transparency = 0.5 + 0.5 * math.sin(os.clock() * 6)
		end
	end)

	State.Changed:Connect(function(key)
		if key == "Tutorial" then
			-- Replay: bereits gemeldete Schritte ab dem aktuellen wieder freigeben
			local index = currentStep()
			for i, step in GameConfig.TutorialSteps do
				if i >= index then
					reported[step.Id] = nil
				end
			end
		end
		if key == "Tutorial" or key == "Characters" or key == "Vault" or key == "Derived" then
			refresh()
		end
	end)
	State.on("Roll", function()
		complete("Roll")
	end)
	State.on("Collected", function()
		complete("Collect")
	end)
	State.on("Upgraded", function()
		complete("Upgrade")
	end)
	WindowManager.Opened:Connect(function(name)
		if name == "Fishing" then
			complete("Fishing")
		end
	end)
	refresh()
end

return TutorialController
