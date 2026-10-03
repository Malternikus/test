--!strict
-- WorldService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > WorldService
--
-- Baut beim Serverstart die Map (World > WorldBuilder) und verbindet die
-- Stationen im Hub und die Dice-Altäre mit der UI (ProximityPrompt ->
-- Client öffnet das passende Menü).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local DiceConfig = require(Config:WaitForChild("DiceConfig"))

local Server = script.Parent.Parent
local WorldBuilder = require(Server:WaitForChild("World"):WaitForChild("WorldBuilder"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local WorldService = {}

-- Station -> Menü im Client
local STATIONS = {
	ShopStation = { Panel = "Shop", Text = "Open Shop", Object = "SURPLUS SHOP" },
	RebirthStation = { Panel = "Rebirth", Text = "Rebirth", Object = "RIFT MACHINE" },
	IndexStation = { Panel = "Index", Text = "Open Index", Object = "CASE ARCHIVE" },
	QuestStation = { Panel = "Quests", Text = "Quests", Object = "NOTICE BOARD" },
	FishingStation = { Panel = "Fishing", Text = "Fishing", Object = "BAIT SHOP" },
}

local world: any = nil

function WorldService.get()
	return world
end

function WorldService.plot(index: number?): Model?
	if not world or not index then
		return nil
	end
	return world.Plots[index]
end

function WorldService.plotCount(): number
	return if world then #world.Plots else 0
end

function WorldService.plotSpawn(index: number?): CFrame?
	local plot = WorldService.plot(index)
	local spawn = plot and plot:FindFirstChild("SpawnPoint")
	return if spawn and spawn:IsA("BasePart") then spawn.CFrame else nil
end

function WorldService.hubSpawn(): CFrame?
	return if world and world.SpawnLocation then world.SpawnLocation.CFrame else nil
end

function WorldService.areaArrival(areaId: string): CFrame?
	if areaId == AreaConfig.StartArea then
		return WorldService.hubSpawn()
	end
	local area = world and world.Areas[areaId]
	local point = area and area:FindFirstChild("ArrivalPoint", true)
	return if point and point:IsA("BasePart") then point.CFrame else nil
end

local function addPrompt(part: BasePart, actionText: string, objectText: string, onTriggered: (Player) -> ())
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = part
	prompt.Triggered:Connect(onTriggered)
end

local function openUI(player: Player, data: { [string]: any })
	local session = SessionService.get(player)
	if session then
		SessionService.fire(session, "OpenUI", data)
	end
end

function WorldService.Init()
	local started = os.clock()
	world = WorldBuilder.Build(workspace)
	print(string.format("[VoidDice] Welt gebaut: %d Parts in %.0f ms", world.PartCount or 0, (os.clock() - started) * 1000))
end

function WorldService.Start()
	for name, station in world.Stations do
		local info = STATIONS[name]
		local promptPart = station:FindFirstChild("PromptPart", true)
		if info and promptPart and promptPart:IsA("BasePart") then
			addPrompt(promptPart, info.Text, info.Object, function(player)
				openUI(player, { Panel = info.Panel })
			end)
		end
	end
	for areaId, area in world.Areas do
		local altar = area:FindFirstChild("DiceAltar", true)
		local promptPart = altar and altar:FindFirstChild("PromptPart", true)
		local dice = nil
		for _, d in DiceConfig.List do
			if d.Area == areaId then
				dice = d
			end
		end
		if promptPart and promptPart:IsA("BasePart") and dice then
			addPrompt(promptPart, "View Dice", dice.DisplayName, function(player)
				openUI(player, { Panel = "Shop", Tab = "Dice", Highlight = dice.Id })
			end)
		end
	end
end

return WorldService
