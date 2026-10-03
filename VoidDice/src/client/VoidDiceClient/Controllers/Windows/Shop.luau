--!strict
-- Shop (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Shop
--
-- Tabs: DICE (Cash), PASSES (Gamepasses), PRODUCTS (Developer Products).
-- Keine Zufallsinhalte für Robux – jede Zeile zeigt genau, was man bekommt.
-- Ids = 0: "COMING SOON", in Studio optional Testkauf über Action TestPurchase.
-- args: { Tab = "Dice" | "Passes" | "Products", Highlight = Id/Name }

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local DiceConfig = require(Config:WaitForChild("DiceConfig"))
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local MonetizationConfig = require(Config:WaitForChild("MonetizationConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))
local Root = require(Client:WaitForChild("UI"):WaitForChild("Root"))

local C = UI.Colors

local Shop = {}
Shop.Title = "SHOP"
Shop.Icon = "🛒"
Shop.Size = Vector2.new(820, 540)

local TABS = { "Dice", "Passes", "Products" }
local HONEST_NOTE = "No random items for Robux. Every purchase shows exactly what you get."

local pages: { [string]: Frame } = {}
local scrolls: { [string]: ScrollingFrame } = {}
local rows: { [string]: { [string]: Frame } } = { Dice = {}, Passes = {}, Products = {} }
local diceButtons: { [string]: TextButton } = {}
local diceStatus: { [string]: TextLabel } = {}
local passButtons: { [string]: TextButton } = {}
local productButtons: { [string]: TextButton } = {}
local currentTab = "Dice"
local selectTab: (string) -> ()
local watcher: Cards.Watcher

local function sortedNames(map: { [string]: any }): { string }
	local names = {}
	for name in map do
		table.insert(names, name)
	end
	table.sort(names, function(a, b)
		if map[a].PriceHint ~= map[b].PriceHint then
			return map[a].PriceHint < map[b].PriceHint
		end
		return a < b
	end)
	return names
end

local function canTest(): boolean
	return State.session.IsStudio == true and MonetizationConfig.StudioTestPurchases == true
end

-- Robux-Button setzen (Pass oder Produkt)
local function setRobuxButton(button: TextButton, def: any, owned: boolean)
	if owned then
		button.Text = "✓ OWNED"
		UI.setButtonEnabled(button, false)
	elseif def.Id ~= 0 then
		button.Text = "R$ " .. def.PriceHint
		UI.setButtonEnabled(button, true, C.Green)
	elseif canTest() then
		button.Text = "TEST (STUDIO)"
		UI.setButtonEnabled(button, true, C.Gold:Lerp(Color3.new(0, 0, 0), 0.3))
	else
		button.Text = "COMING SOON"
		UI.setButtonEnabled(button, false)
	end
end

local function buy(kind: string, name: string, def: any)
	if kind == "Pass" and State.data.Passes and State.data.Passes[name] then
		return
	end
	if def.Id ~= 0 then
		if kind == "Pass" then
			MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, def.Id)
		else
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, def.Id)
		end
	elseif canTest() then
		Actions.send("TestPurchase", kind, name)
	end
end

local function refresh(_changed: { [string]: boolean }?)
	local dice = State.data.Dice or { Owned = {}, Equipped = DiceConfig.Default }
	local areas = State.data.Areas or {}
	local cash = State.data.Cash or 0
	for _, def in DiceConfig.List do
		local button = diceButtons[def.Id]
		local status = diceStatus[def.Id]
		local area = AreaConfig.Get(def.Area)
		local areaName = if area then area.DisplayName else def.Area
		if dice.Equipped == def.Id then
			button.Text = "EQUIPPED"
			UI.setButtonEnabled(button, false)
			status.Text = "✓ Owned"
		elseif dice.Owned[def.Id] then
			button.Text = "EQUIP"
			UI.setButtonEnabled(button, true, C.Blue)
			status.Text = "✓ Owned"
		elseif not areas[def.Area] then
			button.Text = "🔒 LOCKED"
			UI.setButtonEnabled(button, false)
			status.Text = "Unlock " .. areaName .. " first · " .. Format.cash(def.Cost)
		else
			button.Text = "BUY " .. Format.cash(def.Cost)
			UI.setButtonEnabled(button, cash >= def.Cost, C.Green)
			status.Text = "Found in " .. areaName
		end
	end
	local passes = State.data.Passes or {}
	for name, button in passButtons do
		setRobuxButton(button, MonetizationConfig.Gamepasses[name], passes[name] == true)
	end
	for name, button in productButtons do
		setRobuxButton(button, MonetizationConfig.Products[name], false)
	end
end

local function itemRow(parent: Instance, order: number, title: string, sub: string, color: Color3, onClick: () -> ()): (Frame, TextButton, TextLabel)
	local row = Cards.row(parent, 96, order, color)
	local _, subLabel = Cards.rowText(row, title, sub, color, 146)
	subLabel.Size = UDim2.new(1, -170, 0, 40)
	local status = UI.label({
		TextColor3 = C.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 16, 1, -24),
		Size = UDim2.new(1, -170, 0, 18),
		MaxTextSize = 15,
		Parent = row,
	})
	local button = UI.button({
		Text = "",
		Color = C.Green,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(136, 54),
		TextSize = 20,
		Parent = row,
		OnClick = onClick,
	})
	return row, button, status
end

function Shop.build(content: Frame)
	local _, select = UI.tabs(content, TABS, function(name: string)
		currentTab = name
		for tab, page in pages do
			page.Visible = tab == name
		end
	end)
	selectTab = select
	for _, tab in TABS do
		local page = Cards.page(content, tab)
		pages[tab] = page
		scrolls[tab] = UI.scrollList(page, 8)
	end

	-- Dice
	local diceScroll = scrolls.Dice
	Cards.paragraph(diceScroll, "Dice are permanent. Your equipped dice sets your base luck. Unlock areas to find better dice.", 0)
	for _, def in DiceConfig.List do
		local sub = string.format("x%g LUCK%s\n%s", def.Luck, if def.RollSpeed ~= 1 then string.format(" · x%g ROLL SPEED", def.RollSpeed) else "", def.Description)
		local id = def.Id
		local row, button, status = itemRow(diceScroll, def.Order, "🎲 " .. def.DisplayName, sub, def.Color, function()
			local dice = State.data.Dice
			if dice and dice.Owned[id] then
				Actions.send("EquipDice", id)
			else
				Actions.send("BuyDice", id)
			end
		end)
		rows.Dice[id] = row
		diceButtons[id] = button
		diceStatus[id] = status
	end

	-- Passes / Products
	for _, kind in { "Passes", "Products" } do
		local scroll = scrolls[kind]
		local map = if kind == "Passes" then MonetizationConfig.Gamepasses else MonetizationConfig.Products
		local note = Cards.paragraph(scroll, "✔ " .. HONEST_NOTE, 0, C.Green)
		note.Font = UI.Fonts.Title
		for i, name in sortedNames(map) do
			local def = map[name]
			local actionKind = if kind == "Passes" then "Pass" else "Product"
			local row, button, status = itemRow(scroll, i, def.DisplayName, def.Description, if kind == "Passes" then C.Purple else C.Blue, function()
				buy(actionKind, name, def)
			end)
			status.Text = "R$ " .. def.PriceHint .. (if kind == "Passes" then " · one-time, permanent" else " · fixed contents")
			rows[kind][name] = row
			if kind == "Passes" then
				passButtons[name] = button
			else
				productButtons[name] = button
			end
		end
	end

	watcher = Cards.watch({ Dice = true, Areas = true, Cash = true, Passes = true, Session = true }, refresh, 0.2)
end

local function normalizeTab(tab: any): string?
	if type(tab) ~= "string" then
		return nil
	end
	for _, name in TABS do
		if string.lower(name) == string.lower(tab) then
			return name
		end
	end
	return nil
end

-- Zur hervorgehobenen Zeile scrollen und kurz aufleuchten lassen
local function highlight(tab: string, key: string)
	local row = rows[tab][key]
	local scroll = scrolls[tab]
	if not row or not scroll then
		return
	end
	task.wait() -- Layout abwarten
	local offset = (row.AbsolutePosition.Y - scroll.AbsolutePosition.Y) / math.max(0.01, Root.Scale)
	scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.CanvasPosition.Y + offset - 8))
	local stroke = row:FindFirstChildOfClass("UIStroke")
	if stroke then
		local color, thickness = stroke.Color, stroke.Thickness
		for _ = 1, 3 do
			stroke.Color = C.Gold
			stroke.Thickness = 4
			task.wait(0.25)
			stroke.Color = color
			stroke.Thickness = thickness
			task.wait(0.2)
		end
	end
end

function Shop.onOpen(args: any?)
	local tab = if type(args) == "table" then normalizeTab(args.Tab) else nil
	local key = if type(args) == "table" and type(args.Highlight) == "string" then args.Highlight else nil
	if not tab and key then
		for _, name in TABS do
			if rows[name][key] then
				tab = name
			end
		end
	end
	selectTab(tab or currentTab)
	watcher.open()
	if key and tab then
		task.spawn(highlight, tab, key)
	end
end

function Shop.onClose()
	watcher.close()
end

return Shop
