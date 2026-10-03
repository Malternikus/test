--!strict
-- Index (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Index
--
-- Alle Characters nach Rarity. Unentdeckte als schwarze Silhouette ("???").
-- Ehrliche Zahlen: Basis-Chance, DEINE Chance bei aktueller Luck (Odds) und
-- oben eine Tabelle "Your odds" pro Rarity. Klick auf eine entdeckte Karte
-- öffnet ein Detail-Popup.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local Util = Shared:WaitForChild("Util")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local Format = require(Util:WaitForChild("Format"))
local Odds = require(Util:WaitForChild("Odds"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))
local Viewport = require(Client:WaitForChild("UI"):WaitForChild("Viewport"))

local C = UI.Colors
local F = UI.Fonts

local Index = {}
Index.Title = "INDEX"
Index.Icon = "📖"
Index.Size = Vector2.new(900, 560)

local cards: { [string]: Cards.Card } = {}
local oddsCells: { [string]: TextLabel } = {}
local sectionCounts: { [string]: TextLabel } = {}
local ui: { [string]: any } = {}
local watcher: Cards.Watcher
local lastLuck = -1
local lastIndex: any = nil

local function luck(): number
	return State.derived.Luck or 1
end

local function chanceText(p: number): string
	if p <= 0 then
		return "—"
	end
	return Format.chance(p)
end

local function showDetail(def: any)
	local entry = (State.data.Index or {})[def.Id]
	if not entry then
		return
	end
	local rarity = RarityConfig.Get(def.Rarity)
	Viewport.set(ui.detailViewport, def.Id, nil)
	Cards.clear(ui.detailList)
	local order = 0
	local function line(text: string, color: Color3?)
		order += 1
		Cards.paragraph(ui.detailList, text, order, color or C.Text)
	end
	line(rarity.DisplayName .. " · " .. string.upper(def.Category or "?"), rarity.Color)
	line(def.Description or "", C.Text)
	line("Look: " .. (def.VisualTheme or "?"), C.SubText)
	line("Base chance: " .. Cards.baseChanceText(def), C.SubText)
	line("Your chance: " .. chanceText(Odds.characterProbability(def.Id, luck())) .. " (Luck " .. Format.multiplier(luck()) .. ")", C.Luck)
	line("Base income: " .. Format.perSecond(def.BaseMoneyPerSecond) .. " · Max level " .. def.MaxLevel, C.Cash)
	line("Times rolled: " .. Format.commas(entry.N or 0), C.SubText)
	local found = {}
	for _, m in MutationConfig.List do
		if (entry.M or {})[m.Id] then
			table.insert(found, m.DisplayName)
		end
	end
	line("Mutations found: " .. (if #found > 0 then table.concat(found, ", ") else "none"), C.Gold)
	ui.popup.show(def.DisplayName)
	ui.detailScroll.CanvasPosition = Vector2.zero
end

local function refresh(changed: { [string]: boolean }?)
	local index = State.data.Index or {}
	local l = luck()
	local indexChanged = changed == nil or changed.Index or index ~= lastIndex
	local luckChanged = math.abs(l - lastLuck) > 1e-6
	if not indexChanged and not luckChanged then
		return
	end
	lastIndex = index
	lastLuck = l

	local discovered = 0
	local perRarity: { [string]: number } = {}
	for _, def in CharacterConfig.List do
		local entry = index[def.Id]
		local rarity = RarityConfig.Get(def.Rarity)
		local card = cards[def.Id]
		if entry then
			discovered += 1
			perRarity[def.Rarity] = (perRarity[def.Rarity] or 0) + 1
		end
		if card then
			local yours = Odds.characterProbability(def.Id, l)
			if entry then
				local muts = 0
				for m in entry.M or {} do
					if m ~= MutationConfig.None then
						muts += 1
					end
				end
				card.set({
					Id = def.Id,
					Title = def.DisplayName,
					TitleColor = rarity.Color,
					Lines = {
						"Base " .. Cards.baseChanceText(def),
						"You " .. chanceText(yours),
						Format.perSecond(def.BaseMoneyPerSecond) .. " · x" .. Format.short(entry.N or 0) .. (if muts > 0 then " · " .. muts .. "🧬" else ""),
					},
					LineColors = { C.SubText, C.Luck, C.Cash },
					StrokeColor = rarity.Color,
				})
			else
				card.set({
					Id = def.Id,
					Silhouette = true,
					Title = "???",
					TitleColor = C.SubText,
					Lines = { rarity.DisplayName, "Base " .. Cards.baseChanceText(def), "You " .. chanceText(yours) },
					LineColors = { rarity.Color, C.SubText, C.Luck },
					StrokeColor = rarity.Color2,
				})
			end
		end
	end
	for id, label in sectionCounts do
		label.Text = string.format("%d / %d", perRarity[id] or 0, #(CharacterConfig.ByRarity[id] or {}))
	end

	local total = #CharacterConfig.List
	local bonus = math.min(50, discovered * EconomyConfig.IndexLuckPctPerDiscovery)
	ui.discovered.Text = string.format("📖 DISCOVERED %d / %d", discovered, total)
	ui.bonus.Text = string.format("Index bonus: +%g%% Luck (+%g%% per discovery)", bonus, EconomyConfig.IndexLuckPctPerDiscovery)

	local probs = Odds.rarityProbabilities(l)
	for id, cell in oddsCells do
		cell.Text = string.format("%s\n%s", RarityConfig.Get(id).DisplayName, chanceText(probs[id] or 0))
	end
	ui.oddsHeader.Text = "🎲 YOUR ODDS PER ROLL  (Luck " .. Format.multiplier(l) .. ")"
end

function Index.build(content: Frame)
	local top = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = content })
	ui.discovered = UI.label({ Font = F.Title, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 26), MaxTextSize = 24, Parent = top })
	ui.bonus = UI.label({ TextColor3 = C.Luck, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 18), MaxTextSize = 15, Parent = top })

	local holder = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50), Parent = content })
	local scroll = UI.scrollList(holder, 8)

	-- Odds-Tabelle
	ui.oddsHeader = Cards.header(scroll, "🎲 YOUR ODDS", 1, C.Luck)
	local odds = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = scroll })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(104, 46), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = odds })
	for _, rarity in RarityConfig.List do
		local cell = UI.label({
			BackgroundTransparency = 0,
			BackgroundColor3 = C.Background,
			TextColor3 = rarity.Color,
			Font = F.Title,
			LayoutOrder = rarity.Order,
			MaxTextSize = 15,
			Parent = odds,
		})
		UI.corner(cell, 8)
		UI.stroke(cell, rarity.Color2, 1)
		UI.padding(cell, 3)
		oddsCells[rarity.Id] = cell
	end
	Cards.paragraph(scroll, "These are the exact odds the server uses. Luck multiplies every chance from Uncommon up; Commons get what is left.", 3)

	-- Abschnitte pro Rarity
	local order = 10
	for _, rarity in RarityConfig.List do
		local list = table.clone(CharacterConfig.ByRarity[rarity.Id] or {})
		if #list > 0 then
			table.sort(list, function(a, b)
				if a.RollChance ~= b.RollChance then
					return a.RollChance < b.RollChance
				end
				return a.Index < b.Index
			end)
			order += 1
			local header = Cards.header(scroll, rarity.DisplayName, order, rarity.Color)
			sectionCounts[rarity.Id] = UI.label({
				TextColor3 = C.SubText,
				TextXAlignment = Enum.TextXAlignment.Right,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0.4, 0, 1, 0),
				MaxTextSize = 16,
				Parent = header,
			})
			order += 1
			local gridFrame = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = scroll })
			UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(124, 162), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = gridFrame })
			for i, def in list do
				local card = Cards.characterCard(gridFrame, function()
					showDetail(def)
				end)
				card.Frame.LayoutOrder = i
				cards[def.Id] = card
			end
		end
	end

	-- Detail-Popup
	local popup = Cards.popup(content)
	ui.popup = popup
	local vpFrame = UI.panel({ BackgroundColor3 = C.Background, Size = UDim2.new(0.36, -6, 1, 0), Parent = popup.Body })
	ui.detailViewport = Viewport.create({ Parent = vpFrame })
	Viewport.spin(ui.detailViewport, 0.6)
	local listHolder = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.36, 4, 0, 0), Size = UDim2.new(0.64, -4, 1, 0), Parent = popup.Body })
	ui.detailScroll = UI.scrollList(listHolder, 6)
	ui.detailList = ui.detailScroll

	watcher = Cards.watch({
		Index = true,
		Derived = function()
			return math.abs((State.derived.Luck or 1) - lastLuck) > 1e-6
		end,
	}, refresh, 0.3)
end

function Index.onOpen(_args: any?)
	ui.popup.hide()
	watcher.open()
end

function Index.onClose()
	watcher.close()
end

return Index
