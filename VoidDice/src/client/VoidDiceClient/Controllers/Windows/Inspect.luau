--!strict
-- Inspect (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Inspect
--
-- Base eines anderen Spielers ansehen (Event "InspectBase" vom Server,
-- ausgelöst durch die Action InspectBase(plotIndex)). Öffnet sich selbst,
-- sobald die Daten ankommen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local Util = Shared:WaitForChild("Util")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local CosmeticConfig = require(Config:WaitForChild("CosmeticConfig"))
local Format = require(Util:WaitForChild("Format"))
local Stats = require(Util:WaitForChild("Stats"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))

local C = UI.Colors
local F = UI.Fonts

local Inspect = {}
Inspect.Title = "BASE"
Inspect.Icon = "🔍"
Inspect.Size = Vector2.new(820, 540)

local ui: { [string]: any } = {}
local cards: { Cards.Card } = {}

local function stat(parent: Instance, order: number): TextLabel
	local label = UI.label({
		BackgroundTransparency = 0,
		BackgroundColor3 = C.Background,
		LayoutOrder = order,
		MaxTextSize = 16,
		Parent = parent,
	})
	UI.corner(label, 8)
	UI.padding(label, 4)
	return label
end

local function render(data: { [string]: any })
	local title = data.Title and CosmeticConfig.Get(data.Title)
	ui.name.Text = "🏠 " .. tostring(data.Player or "???") .. "'S BASE"
	ui.title.Text = if title then (title.Text or title.DisplayName) else ""
	ui.title.TextColor3 = if title and title.Color then title.Color else C.SubText

	local best = RarityConfig.ById[data.BestRarity or ""]
	ui.stats.Rebirths.Text = "♻ REBIRTHS\n" .. tostring(data.Rebirths or 0)
	ui.stats.Value.Text = "⚔ BASE VALUE\n" .. Format.short(data.BaseValue or 0)
	ui.stats.Income.Text = "💰 INCOME\n" .. Format.perSecond(data.Income or 0)
	ui.stats.Discovered.Text = string.format("📖 DISCOVERED\n%d / %d", data.Discovered or 0, #CharacterConfig.List)
	ui.stats.Best.Text = "🏆 BEST\n" .. (if best then best.DisplayName else "—")
	ui.stats.Best.TextColor3 = if best then best.Color else C.Text
	ui.stats.Rolls.Text = "🎲 ROLLS\n" .. Format.short(data.TotalRolls or 0)

	local chars = table.clone(data.Characters or {})
	table.sort(chars, function(a, b)
		return (a.Slot or 0) < (b.Slot or 0)
	end)
	local shown = 0
	for _, char in chars do
		local def = CharacterConfig.ById[char.Id]
		if def then
			shown += 1
			local card = cards[shown]
			if not card then
				card = Cards.characterCard(ui.grid, nil)
				cards[shown] = card
			end
			local rarity = RarityConfig.Get(def.Rarity)
			local tagText, tagColor = Cards.mutationTag(char.Mutation)
			card.Frame.LayoutOrder = shown
			card.Frame.Visible = true
			card.set({
				Id = char.Id,
				Mutation = char.Mutation,
				Title = def.DisplayName,
				TitleColor = rarity.Color,
				Lines = {
					rarity.DisplayName .. " · Lv " .. tostring(char.Level) .. "/" .. def.MaxLevel,
					"⚔ " .. Format.short(Stats.power(def, char.Level or 1, char.Mutation)),
				},
				LineColors = { rarity.Color, C.SubText },
				Tag = tagText,
				TagColor = tagColor,
				StrokeColor = rarity.Color,
			})
		end
	end
	for i = shown + 1, #cards do
		cards[i].Frame.Visible = false
	end
	ui.empty.Visible = shown == 0
	ui.grid.CanvasPosition = Vector2.zero
end

function Inspect.build(content: Frame)
	ui.name = UI.label({ Font = F.Title, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.65, 0, 0, 30), MaxTextSize = 26, Parent = content })
	ui.title = UI.label({ Font = F.Title, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.35, 0, 0, 30), MaxTextSize = 20, Parent = content })

	local statsFrame = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 44), Parent = content })
	UI.new("UIGridLayout", { CellSize = UDim2.new(1 / 6, -6, 1, 0), CellPadding = UDim2.fromOffset(6, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = statsFrame })
	ui.stats = {
		Rebirths = stat(statsFrame, 1),
		Value = stat(statsFrame, 2),
		Income = stat(statsFrame, 3),
		Discovered = stat(statsFrame, 4),
		Best = stat(statsFrame, 5),
		Rolls = stat(statsFrame, 6),
	}
	ui.stats.Income.TextColor3 = C.Cash

	local holder = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 1, -84), Parent = content })
	ui.grid = UI.grid(holder, Vector2.new(120, 150), 8)
	ui.empty = UI.label({
		Text = "No characters placed in this base yet.",
		TextColor3 = C.SubText,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.new(0.8, 0, 0, 28),
		MaxTextSize = 20,
		Visible = false,
		Parent = holder,
	})
end

function Inspect.onOpen(args: any?)
	if type(args) == "table" and args.Characters ~= nil then
		render(args)
	end
end

-- Server schickt die Daten -> Fenster öffnen
State.on("InspectBase", function(data: any)
	if type(data) == "table" then
		Cards.open("Inspect", data)
	end
end)

return Inspect
