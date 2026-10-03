--!strict
-- HUD (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > HUD
--
-- Haupt-HUD:
--   oben Mitte   Cash, $/s, COLLECT (Vault)
--   oben links   Luck (mit exakter Aufschlüsselung), Rebirth-Fortschritt, Boosts
--   links        Menü (Inventory, Index, Shop, Quests, Fishing, Items, Map, Settings)
--   unten Mitte  großer ROLL-Button, AUTO, Dice
--   rechts       Mini-Quest-Tracker
--
-- Alle Zahlen kommen vom Server (State). Der HUD rechnet nichts selbst aus.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local DiceConfig = require(Config:WaitForChild("DiceConfig"))
local PotionConfig = require(Config:WaitForChild("PotionConfig"))
local QuestConfig = require(Config:WaitForChild("QuestConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Root = require(Client:WaitForChild("UI"):WaitForChild("Root"))
local WindowManager = require(script.Parent:WaitForChild("WindowManager"))

local C = UI.Colors
local F = UI.Fonts
local new = UI.new

local HUD = {}

HUD.RollButton = nil :: TextButton?
HUD.AutoButton = nil :: TextButton?
HUD.CollectButton = nil :: TextButton?
HUD.MenuButtons = {} :: { [string]: TextButton }

local rollCooldownEnd = 0
local rollCooldownLength = 1

local MENU = {
	{ Name = "Inventory", Icon = "🎒", Key = "I" },
	{ Name = "Index", Icon = "📖", Key = "X" },
	{ Name = "Shop", Icon = "🛒", Key = "B" },
	{ Name = "Quests", Icon = "📜", Key = "Q" },
	{ Name = "Fishing", Icon = "🎣", Key = "F" },
	{ Name = "Items", Icon = "🧪", Key = "G" },
	{ Name = "Map", Icon = "🗺", Key = "M" },
	{ Name = "Settings", Icon = "⚙", Key = "" },
}

function HUD.roll()
	if os.clock() < rollCooldownEnd - 0.05 then
		return
	end
	Actions.send("Roll")
	-- lokale Vorhersage, damit der Button sofort reagiert (Server entscheidet)
	rollCooldownEnd = os.clock() + (State.derived.RollCooldown or 1)
	rollCooldownLength = State.derived.RollCooldown or 1
end

function HUD.toggleAuto()
	Actions.send("SetAutoRoll", not State.session.AutoRoll)
end

local function buildTop(gui: ScreenGui)
	-- Cash ---------------------------------------------------------------------------
	local cashPanel = UI.panel({
		Name = "Cash",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(300, 64),
		Parent = gui,
	})
	UI.gradient(cashPanel, C.PanelLight, C.Panel, 90)
	local cashLabel = UI.label({
		Name = "Amount",
		Text = "$0",
		Font = F.Title,
		TextColor3 = C.Cash,
		Size = UDim2.new(1, -16, 0, 38),
		Position = UDim2.fromOffset(8, 2),
		MaxTextSize = 36,
		Parent = cashPanel,
	})
	local incomeLabel = UI.label({
		Name = "Income",
		Text = "+$0/s",
		TextColor3 = C.SubText,
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.fromOffset(8, 40),
		MaxTextSize = 18,
		Parent = cashPanel,
	})

	local collect = UI.button({
		Name = "Collect",
		Text = "COLLECT $0",
		Icon = "💰",
		Color = C.Green,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 76),
		Size = UDim2.fromOffset(240, 46),
		TextSize = 22,
		Visible = false,
		Parent = gui,
		OnClick = function()
			Actions.send("Collect")
		end,
	})
	HUD.CollectButton = collect

	local displayed = 0
	RunService.RenderStepped:Connect(function(dt)
		local target = State.data.Cash or 0
		-- weich hochzählen
		displayed = if math.abs(target - displayed) < 1 then target else displayed + (target - displayed) * math.min(1, dt * 10)
		cashLabel.Text = Format.cash(displayed)
	end)

	local function refreshCash()
		local d = State.derived
		incomeLabel.Text = "+" .. Format.perSecond(d.IncomePerSecond or 0) .. (if (d.CashMultiplier or 1) > 1 then "  (" .. Format.multiplier(d.CashMultiplier) .. ")" else "")
		local vault = State.data.Vault or 0
		collect.Visible = not d.AutoCollect and vault > 0
		collect.Text = "💰  COLLECT " .. Format.cash(vault)
		if d.VaultCapacity and vault >= d.VaultCapacity * 0.999 then
			collect.Text ..= " (FULL)"
		end
	end
	State.Changed:Connect(function(key)
		if key == "Derived" or key == "Vault" then
			refreshCash()
		end
	end)

	-- Luck + Rebirth (oben links, unter der Roblox-Leiste) ---------------------------
	local stack = new("Frame", {
		Name = "Stats",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.fromOffset(210, 200),
		Parent = gui,
	})
	UI.list(stack, 6)

	local luckButton = UI.button({
		Name = "Luck",
		Text = "LUCK x1",
		Icon = "🍀",
		Color = Color3.fromRGB(20, 70, 90),
		TextColor = C.Luck,
		Size = UDim2.fromOffset(200, 40),
		TextSize = 20,
		LayoutOrder = 1,
		Parent = stack,
	})
	local breakdown = UI.panel({
		Name = "LuckBreakdown",
		Visible = false,
		Position = UDim2.fromOffset(220, 8),
		Size = UDim2.fromOffset(250, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = gui,
	})
	UI.padding(breakdown, 8)
	UI.list(breakdown, 2)
	luckButton.Activated:Connect(function()
		breakdown.Visible = not breakdown.Visible
	end)

	local rebirthButton = UI.button({
		Name = "Rebirth",
		Text = "REBIRTH 0",
		Icon = "♻",
		Color = Color3.fromRGB(70, 30, 110),
		Size = UDim2.fromOffset(200, 40),
		TextSize = 20,
		LayoutOrder = 2,
		Parent = stack,
		OnClick = function()
			WindowManager.open("Rebirth")
		end,
	})
	local _, setRebirthBar = UI.progress({
		Size = UDim2.fromOffset(200, 14),
		Color = C.Purple,
		LayoutOrder = 3,
		Parent = stack,
	})

	local boosts = new("Frame", {
		Name = "Boosts",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(210, 34),
		LayoutOrder = 4,
		Parent = stack,
	})
	UI.list(boosts, 4, true)

	local function refreshLuck()
		local d = State.derived
		luckButton.Text = "🍀  LUCK " .. Format.multiplier(d.Luck or 1)
		for _, child in breakdown:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		UI.label({ Text = "YOUR LUCK: " .. Format.multiplier(d.Luck or 1), Font = F.Title, TextColor3 = C.Luck, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 0, Parent = breakdown })
		for i, entry in d.LuckBreakdown or {} do
			local text = if entry.Kind == "x" then string.format("%s  x%g", entry.Label, entry.Value) else string.format("%s  +%g%%", entry.Label, math.floor(entry.Value * 10 + 0.5) / 10)
			UI.label({ Text = text, TextColor3 = C.SubText, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i, Parent = breakdown })
		end
		UI.label({ Text = "Luck multiplies every rare chance exactly.", TextColor3 = C.SubText, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 99, Parent = breakdown })

		local rebirths = State.data.Rebirths or 0
		rebirthButton.Text = "♻  REBIRTH " .. rebirths
		local cost = d.RebirthCost or 1
		local cash = State.data.Cash or 0
		setRebirthBar(cash / cost, if cash >= cost then "REBIRTH READY!" else Format.cash(cash) .. " / " .. Format.cash(cost))
		rebirthButton.BackgroundColor3 = if cash >= cost then C.Red else Color3.fromRGB(70, 30, 110)
	end

	local function refreshBoosts()
		for _, child in boosts:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for id, remaining in State.data.Boosts or {} do
			local def = PotionConfig.Get(id)
			if def then
				local tag = UI.tag({
					Text = "🧪 " .. Format.duration(remaining),
					Color = def.Color:Lerp(Color3.new(0, 0, 0), 0.45),
					Size = UDim2.fromOffset(66, 26),
					Parent = boosts,
				})
				tag.Name = id
			end
		end
	end

	State.Changed:Connect(function(key)
		if key == "Derived" or key == "Cash" or key == "Rebirths" then
			refreshLuck()
		elseif key == "Boosts" then
			refreshBoosts()
		end
	end)
end

local function buildMenu(gui: ScreenGui)
	local menu = new("Frame", {
		Name = "Menu",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.55, 0),
		Size = UDim2.fromOffset(150, 420),
		Parent = gui,
	})
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(70, 62),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = menu,
	})
	for i, entry in MENU do
		local button = UI.button({
			Name = entry.Name,
			Text = entry.Icon .. "\n" .. string.upper(entry.Name),
			Color = C.Panel,
			StrokeColor = C.Stroke,
			LayoutOrder = i,
			TextSize = 18,
			Parent = menu,
			OnClick = function()
				WindowManager.toggle(entry.Name)
			end,
		})
		button.Font = F.Body
		HUD.MenuButtons[entry.Name] = button
		local badge = UI.tag({
			Text = "!",
			Color = C.Red,
			Size = UDim2.fromOffset(20, 20),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 4, 0, -4),
			ZIndex = 6,
			Parent = button,
		})
		badge.Name = "Badge"
		badge.Visible = false
	end

	local function refreshBadges()
		local claimable = false
		for _, q in (State.data.Quests and State.data.Quests.List) or {} do
			local def = QuestConfig.ById[q.Id]
			if def and q.Progress >= def.Target and not q.Claimed then
				claimable = true
			end
		end
		HUD.MenuButtons.Quests.Badge.Visible = claimable
		local fishers = 0
		for _, char in State.data.Characters or {} do
			if char.Fishing then
				fishers += 1
			end
		end
		HUD.MenuButtons.Fishing.Badge.Visible = (State.derived.FishingUnlocked == true) and fishers < (State.derived.FishingSlots or 1)
		local potions = 0
		for _, n in State.data.Potions or {} do
			potions += n
		end
		HUD.MenuButtons.Items.Badge.Visible = potions > 0
		HUD.MenuButtons.Items.Badge.Text = if potions > 9 then "9+" else tostring(potions)
	end
	State.Changed:Connect(function(key)
		if key == "Quests" or key == "Derived" or key == "Potions" or key == "Characters" then
			refreshBadges()
		end
	end)
end

local function buildRoll(gui: ScreenGui)
	local holder = new("Frame", {
		Name = "RollArea",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(440, 150),
		Parent = gui,
	})

	local roll = UI.button({
		Name = "Roll",
		Text = "ROLL",
		Color = C.Purple,
		StrokeColor = C.Blue,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(190, 120),
		TextSize = 54,
		Radius = 28,
		Parent = holder,
		OnClick = HUD.roll,
	})
	UI.gradient(roll, Color3.fromRGB(200, 120, 255), Color3.fromRGB(70, 30, 200), 90)
	HUD.RollButton = roll
	local fill = new("Frame", {
		Name = "Cooldown",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(0, 0.08),
		ZIndex = 3,
		Parent = roll,
	})
	UI.corner(fill, 4)

	local auto = UI.button({
		Name = "Auto",
		Text = "AUTO\nOFF",
		Color = C.PanelLight,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0.5, 105, 1, 0),
		Size = UDim2.fromOffset(100, 74),
		TextSize = 22,
		Parent = holder,
		OnClick = HUD.toggleAuto,
	})
	HUD.AutoButton = auto

	local dice = UI.button({
		Name = "Dice",
		Text = "🎲 BASIC\nx1 LUCK",
		Color = C.PanelLight,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(0.5, -105, 1, 0),
		Size = UDim2.fromOffset(100, 74),
		TextSize = 18,
		Parent = holder,
		OnClick = function()
			WindowManager.open("Shop", { Tab = "Dice" })
		end,
	})

	local function refresh()
		local on = State.session.AutoRoll == true
		auto.Text = if on then "AUTO\nON" else "AUTO\nOFF"
		auto.BackgroundColor3 = if on then C.Green else C.PanelLight
		local equipped = State.data.Dice and DiceConfig.Get(State.data.Dice.Equipped)
		if equipped then
			dice.Text = "🎲 " .. equipped.DisplayName:gsub(" DICE", "") .. "\nx" .. equipped.Luck .. " LUCK"
			dice.BackgroundColor3 = equipped.Color2
		end
	end
	State.Changed:Connect(function(key)
		if key == "Session" or key == "Dice" then
			refresh()
		end
	end)
	State.on("Roll", function(data)
		rollCooldownLength = data.Cooldown or rollCooldownLength
		rollCooldownEnd = os.clock() + rollCooldownLength
	end)
	RunService.RenderStepped:Connect(function()
		local left = rollCooldownEnd - os.clock()
		if left > 0 then
			fill.Size = UDim2.fromScale(1 - left / math.max(0.05, rollCooldownLength), 0.08)
		else
			fill.Size = UDim2.fromScale(1, 0.08)
		end
	end)
end

local function buildQuestTracker(gui: ScreenGui)
	local tracker = UI.panel({
		Name = "QuestTracker",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.45, 0),
		Size = UDim2.fromOffset(220, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.25,
		Parent = gui,
	})
	UI.padding(tracker, 8)
	UI.list(tracker, 4)
	local function refresh()
		for _, child in tracker:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		UI.label({ Text = "📜 DAILY QUESTS", Font = F.Title, TextColor3 = C.Gold, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 0, Parent = tracker })
		local shown = 0
		for i, q in (State.data.Quests and State.data.Quests.List) or {} do
			local def = QuestConfig.ById[q.Id]
			if def and not q.Claimed and shown < 3 then
				shown += 1
				local done = q.Progress >= def.Target
				UI.label({
					Text = (if done then "✅ " else "") .. def.Text,
					TextColor3 = if done then C.Green else C.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(1, 0, 0, 16),
					LayoutOrder = i * 2,
					MaxTextSize = 15,
					Parent = tracker,
				})
				local _, setProgress = UI.progress({
					Size = UDim2.new(1, 0, 0, 10),
					Color = if done then C.Green else C.Blue,
					LayoutOrder = i * 2 + 1,
					Parent = tracker,
				})
				setProgress(q.Progress / def.Target)
			end
		end
		tracker.Visible = shown > 0 and not Root.IsSmall
	end
	State.Changed:Connect(function(key)
		if key == "Quests" then
			refresh()
		end
	end)
	tracker.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			WindowManager.open("Quests")
		end
	end)
end

function HUD.init()
	local gui = Root.Layers.HUD
	buildTop(gui)
	buildMenu(gui)
	buildRoll(gui)
	buildQuestTracker(gui)
	-- Fenster blenden das Menü auf kleinen Bildschirmen aus
	WindowManager.Opened:Connect(function()
		if Root.IsSmall then
			gui.Enabled = false
		end
	end)
	WindowManager.Closed:Connect(function()
		gui.Enabled = true
	end)
end

return HUD
