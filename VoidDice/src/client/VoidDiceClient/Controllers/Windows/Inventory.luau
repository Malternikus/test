--!strict
-- Inventory (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Inventory
--
-- Raster aller eigenen Characters: Vorschau, Rarity, Level, Mutation, $/s,
-- Status-Icons (🏠 Base, 🎣 Fishing, 🔒 Locked). Sortierung, Rarity-Filter,
-- PLACE BEST. Karten werden pro uid wiederverwendet (Auto-Roll ändert die
-- Characters jede Sekunde), Viewports nur bei neuer Id/Mutation neu gesetzt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))

local C = UI.Colors
local F = UI.Fonts

local Inventory = {}
Inventory.Title = "INVENTORY"
Inventory.Icon = "🎒"
Inventory.Size = Vector2.new(880, 560)

local MAX_CARDS = 120
local SORTS = { "Rarity", "Income", "Level", "Newest" }

local sortIndex = 1
local filter: string? = nil
local cards: { [string]: Cards.Card } = {}
local chipButtons: { [string]: TextButton } = {}

local grid: ScrollingFrame
local countLabel: TextLabel
local slotsLabel: TextLabel
local sortButton: TextButton
local emptyLabel: TextLabel
local watcher: Cards.Watcher

local function openCharacter(uid: string)
	Cards.open("Character", { Uid = uid })
end

local function refresh(_changed: { [string]: boolean }?)
	local filterFn = nil
	if filter then
		local wanted = filter
		filterFn = function(_char: any, def: any): boolean
			return def.Rarity == wanted
		end
	end
	local list = State.characterList(SORTS[sortIndex], filterFn)
	local shown: { [string]: boolean } = {}
	for i, entry in list do
		if i > MAX_CARDS then
			break
		end
		local uid: string = entry.uid
		local card = cards[uid]
		if not card then
			card = Cards.characterCard(grid, function()
				openCharacter(uid)
			end)
			cards[uid] = card
		end
		card.Frame.LayoutOrder = i
		card.Frame.Visible = true
		card.set(Cards.ownedInfo(uid, entry.char, entry.def, entry.income))
		shown[uid] = true
	end
	-- nicht angezeigte Karten verstecken, verschwundene Characters entfernen
	local owned = State.data.Characters or {}
	for uid, card in cards do
		if not shown[uid] then
			if owned[uid] then
				card.Frame.Visible = false
			else
				card.Frame:Destroy()
				cards[uid] = nil
			end
		end
	end

	local total = 0
	local placed = 0
	for _, char in owned do
		total += 1
		if char.Slot then
			placed += 1
		end
	end
	local cap = GameConfig.InventorySoftCap
	countLabel.Text = string.format("📦 %d / %d", total, cap) .. (if #list > MAX_CARDS then string.format("  (top %d shown)", MAX_CARDS) else "")
	countLabel.TextColor3 = if total >= cap then C.Red elseif total >= cap * 0.9 then C.Gold else C.Text
	slotsLabel.Text = string.format("🏠 %d / %d in base", placed, State.derived.BaseSlots or GameConfig.StartBaseSlots)
	emptyLabel.Visible = #list == 0
	emptyLabel.Text = if total == 0 then "No characters yet. Press ROLL!" else "No characters of this rarity."
end

local function setFilter(rarityId: string?)
	filter = rarityId
	for id, button in chipButtons do
		local active = (id == "All" and rarityId == nil) or id == rarityId
		button.BackgroundColor3 = if active then C.Purple else C.PanelLight
	end
	refresh(nil)
end

function Inventory.build(content: Frame)
	local bar = UI.new("Frame", { Name = "Toolbar", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), Parent = content })
	countLabel = UI.label({
		Font = F.Title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.34, -6, 0, 26),
		MaxTextSize = 22,
		Parent = bar,
	})
	slotsLabel = UI.label({
		TextColor3 = C.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(0.34, -6, 0, 20),
		MaxTextSize = 16,
		Parent = bar,
	})
	sortButton = UI.button({
		Text = "SORT: RARITY",
		Color = C.PanelLight,
		Position = UDim2.fromScale(0.34, 0),
		Size = UDim2.new(0.33, -6, 1, 0),
		TextSize = 20,
		Parent = bar,
		OnClick = function()
			sortIndex = sortIndex % #SORTS + 1
			sortButton.Text = "SORT: " .. string.upper(SORTS[sortIndex])
			refresh(nil)
			grid.CanvasPosition = Vector2.zero
		end,
	})
	UI.button({
		Text = "PLACE BEST",
		Icon = "⭐",
		Color = C.Green,
		Position = UDim2.fromScale(0.67, 0),
		Size = UDim2.new(0.33, 0, 1, 0),
		TextSize = 20,
		Parent = bar,
		OnClick = function()
			Actions.send("PlaceBest")
		end,
	})

	-- Rarity-Filter (horizontal scrollbar)
	local chips = UI.new("ScrollingFrame", {
		Name = "Filter",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 0, 56),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.Purple,
		Selectable = false,
		Parent = content,
	})
	UI.list(chips, 6, true)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), Parent = chips })
	chipButtons.All = UI.button({
		Text = "ALL",
		Color = C.Purple,
		Size = UDim2.fromOffset(80, 48),
		TextSize = 18,
		LayoutOrder = 0,
		Parent = chips,
		OnClick = function()
			setFilter(nil)
		end,
	})
	for _, rarity in RarityConfig.List do
		local button = UI.button({
			Text = rarity.DisplayName,
			Color = C.PanelLight,
			TextColor = rarity.Color,
			StrokeColor = rarity.Color2,
			Size = UDim2.fromOffset(math.max(96, #rarity.DisplayName * 11 + 24), 48),
			TextSize = 17,
			LayoutOrder = rarity.Order,
			Parent = chips,
			OnClick = function()
				setFilter(rarity.Id)
			end,
		})
		chipButtons[rarity.Id] = button
	end

	local holder = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 116), Size = UDim2.new(1, 0, 1, -116), Parent = content })
	grid = UI.grid(holder, Vector2.new(120, 150), 8)
	emptyLabel = UI.label({
		Text = "",
		TextColor3 = C.SubText,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.new(0.8, 0, 0, 30),
		MaxTextSize = 22,
		Visible = false,
		Parent = holder,
	})

	watcher = Cards.watch({
		Characters = true,
		Gear = true,
		Derived = Cards.derivedChanged({ "CashMultiplier", "BaseSlots" }),
	}, refresh, 0.25)
end

function Inventory.onOpen(_args: any?)
	watcher.open()
end

function Inventory.onClose()
	watcher.close()
end

return Inventory
