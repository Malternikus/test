--!strict
-- BaseInteraction (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > BaseInteraction
--
-- ProximityPrompts, die nur dieser Client sieht:
--   * eigene Base: auf jedem belegten Pad "Manage" (öffnet Character-Fenster
--     mit Level, $/s, Power, Fishing Power, Gear, UPGRADE), auf leeren Pads
--     "Place Best"
--   * fremde Bases: am Schild "Inspect Base" (Social Flex)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local CharacterConfig = require(Shared:WaitForChild("Config"):WaitForChild("CharacterConfig"))

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local WindowManager = require(script.Parent:WaitForChild("WindowManager"))

local BaseInteraction = {}

local prompts: { ProximityPrompt } = {}
local signPrompts: { [Model]: ProximityPrompt } = {}

local function clearPrompts()
	for _, p in prompts do
		p:Destroy()
	end
	table.clear(prompts)
end

local function makePrompt(parent: Instance, action: string, object: string, onTrigger: () -> ()): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = parent
	prompt.Triggered:Connect(onTrigger)
	return prompt
end

local function world(): Instance?
	return workspace:FindFirstChild(WorldConfig.WorldFolderName)
end

local function findPlot(index: number): Model?
	local w = world()
	if not w then
		return nil
	end
	local plot = w:FindFirstChild("Plot" .. index, true)
	return if plot and plot:IsA("Model") then plot else nil
end

local function refreshOwnBase()
	clearPrompts()
	local plotIndex = State.session.Plot
	local plot = plotIndex and findPlot(plotIndex)
	local slots = plot and plot:FindFirstChild("Slots")
	if not slots then
		return
	end
	local bySlot = {}
	for uid, char in State.data.Characters or {} do
		if char.Slot then
			bySlot[char.Slot] = uid
		end
	end
	for _, pad in slots:GetChildren() do
		if pad:IsA("BasePart") then
			local index = (pad:GetAttribute("SlotIndex") :: number?) or tonumber(pad.Name:match("%d+")) or 0
			local uid = bySlot[index]
			if uid then
				local char = State.data.Characters[uid]
				local def = CharacterConfig.ById[char.Id]
				table.insert(prompts, makePrompt(pad, "Manage", def and def.DisplayName or "Character", function()
					WindowManager.open("Character", { Uid = uid })
				end))
			elseif index <= (State.derived.BaseSlots or 0) then
				table.insert(prompts, makePrompt(pad, "Place Best", "Empty Slot", function()
					Actions.send("PlaceBest")
				end))
			end
		end
	end
	local pond = plot and plot:FindFirstChild("PondWater", true)
	if pond then
		table.insert(prompts, makePrompt(pond, "Rift Fishing", "Rift Pond", function()
			WindowManager.open("Fishing")
		end))
	end
end

local function refreshSigns()
	local w = world()
	if not w then
		return
	end
	for i = 1, WorldConfig.PlotCount do
		local plot = findPlot(i)
		local sign = plot and plot:FindFirstChild("SignBoard", true)
		if plot and sign and not signPrompts[plot] and i ~= State.session.Plot then
			signPrompts[plot] = makePrompt(sign, "Inspect Base", "Base " .. i, function()
				Actions.send("InspectBase", i)
			end)
		elseif plot and signPrompts[plot] and i == State.session.Plot then
			signPrompts[plot]:Destroy()
			signPrompts[plot] = nil
		end
	end
end

function BaseInteraction.init()
	local pending = false
	local function schedule()
		if pending then
			return
		end
		pending = true
		task.delay(0.3, function()
			pending = false
			refreshOwnBase()
			refreshSigns()
		end)
	end
	State.Changed:Connect(function(key)
		if key == "Characters" or key == "Session" or key == "Derived" then
			schedule()
		end
	end)
	-- Plots können durch Streaming später ankommen
	task.spawn(function()
		while true do
			task.wait(10)
			refreshSigns()
		end
	end)
	schedule()
end

return BaseInteraction
