--!strict
-- Character (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Character
--
-- Detailansicht eines eigenen Characters (args.Uid): drehende Vorschau,
-- Werte, Upgrade, Base/Fishing, Lock, Verkaufen (mit Bestätigung) und Gear.
-- Alle Kosten/Werte nur zur Anzeige – der Server rechnet selbst.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local Util = Shared:WaitForChild("Util")
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local Format = require(Util:WaitForChild("Format"))
local Stats = require(Util:WaitForChild("Stats"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))
local Viewport = require(Client:WaitForChild("UI"):WaitForChild("Viewport"))

local C = UI.Colors
local F = UI.Fonts

local Character = {}
Character.Title = "CHARACTER"
Character.Icon = "👤"
Character.Size = Vector2.new(860, 560)

local currentUid: string? = nil
local lastChar: any = nil
local vpKey = ""

local ui: { [string]: any } = {}
local watcher: Cards.Watcher

local function cash(): number
	return State.data.Cash or 0
end

-- Summe der nächsten n Upgrade-Stufen
local function multiCost(def: any, char: any, n: number): (number, number)
	local total, levels = 0, 0
	for i = 0, n - 1 do
		local cost = Stats.upgradeCost(def, char.Level + i, char.Mutation)
		if not cost then
			break
		end
		total += cost
		levels += 1
	end
	return total, levels
end

local function gearRow(parent: Instance, gearUid: string, item: any, order: number, equipped: boolean, canEquip: boolean)
	local def = GearConfig.Get(item.Id)
	if not def then
		return
	end
	local row = Cards.row(parent, 64, order, Cards.gearColor(def))
	Cards.rowText(row, def.DisplayName, Cards.gearStats(def), Cards.gearColor(def), 126)
	local button = UI.button({
		Text = if equipped then "UNEQUIP" else "EQUIP",
		Color = if equipped then C.Red else C.Blue,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(116, 48),
		TextSize = 18,
		Parent = row,
		OnClick = function()
			if equipped then
				Actions.send("UnequipGear", gearUid)
			elseif currentUid then
				Actions.send("EquipGear", gearUid, currentUid)
			end
		end,
	})
	if not equipped then
		UI.setButtonEnabled(button, canEquip, C.Blue)
	end
end

local function rebuildGear(char: any)
	Cards.clear(ui.gearList)
	local slots = State.derived.GearSlots or 2
	local gear = State.data.Gear or {}
	local order = 0
	for _, gearUid in char.Gear or {} do
		local item = gear[gearUid]
		if item then
			order += 1
			gearRow(ui.gearList, gearUid, item, order, true, false)
		end
	end
	if order == 0 then
		order += 1
		Cards.paragraph(ui.gearList, "No gear equipped. Gear drops from fishing, quests and the season pass.", order)
	end
	ui.gearHeader.Text = string.format("🧰 GEAR  %d / %d SLOTS", #(char.Gear or {}), slots)

	-- freie Gear-Items (beste zuerst)
	local free = {}
	for gearUid, item in gear do
		local def = GearConfig.Get(item.Id)
		if def and not item.On then
			table.insert(free, { uid = gearUid, item = item, order = Cards.gearOrder(def), name = def.DisplayName })
		end
	end
	table.sort(free, function(a, b)
		if a.order ~= b.order then
			return a.order > b.order
		end
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.uid < b.uid
	end)
	local canEquip = #(char.Gear or {}) < slots
	order += 1
	Cards.header(ui.gearList, "EQUIP GEAR", order, C.Blue)
	for i, entry in free do
		if i > 30 then
			break
		end
		order += 1
		gearRow(ui.gearList, entry.uid, entry.item, order, false, canEquip)
	end
	if #free == 0 then
		order += 1
		Cards.paragraph(ui.gearList, "No unequipped gear in your inventory.", order)
	end
end

local function refresh(changed: { [string]: boolean }?)
	local uid = currentUid
	local char = uid and State.character(uid)
	local def = char and CharacterConfig.ById[char.Id]
	if not uid or not char or not def then
		-- verkauft oder ungültig: zurück ins Inventar (verzögert, wir sind evtl. mitten in open())
		task.defer(function()
			if watcher.isVisible() then
				Cards.open("Inventory")
			end
		end)
		return
	end
	local charChanged = char ~= lastChar
	lastChar = char
	local rarity = RarityConfig.Get(def.Rarity)
	local mutation = MutationConfig.Get(char.Mutation)

	local key = char.Id .. "|" .. (char.Mutation or "")
	if key ~= vpKey then
		vpKey = key
		Viewport.set(ui.viewport, char.Id, char.Mutation)
	end
	ui.stroke.Color = rarity.Color
	ui.name.Text = def.DisplayName
	ui.name.TextColor3 = rarity.Color
	ui.rarity.Text = rarity.DisplayName .. " · Base chance " .. Cards.baseChanceText(def) .. " · " .. string.upper(def.Category or "")
	ui.rarity.TextColor3 = rarity.Color
	if char.Mutation and char.Mutation ~= MutationConfig.None then
		ui.mutation.Text = string.format("MUTATION: %s  (x%g cash, x%g power)", mutation.DisplayName, mutation.MoneyMultiplier, mutation.PowerMultiplier)
		ui.mutation.TextColor3 = mutation.Color
		ui.mutation.Visible = true
	else
		ui.mutation.Visible = false
	end
	ui.description.Text = def.Description or ""

	local maxLevel = def.MaxLevel
	ui.setLevel(char.Level / maxLevel, string.format("LEVEL %d / %d", char.Level, maxLevel))
	local nextLook = nil
	for _, lv in { 5, 10, 15 } do
		if char.Level < lv and lv <= maxLevel then
			nextLook = lv
			break
		end
	end
	ui.levelHint.Text = if nextLook then string.format("✨ New look at Lv %d (looks change at 5 / 10 / 15)", nextLook) else "✨ MAX LEVEL look unlocked!"

	local income = State.income(uid)
	ui.stats.Income.Text = "💰 " .. Format.perSecond(income) .. (if char.Slot then "" else "\n(only in base)")
	ui.stats.Power.Text = "⚔ POWER\n" .. Format.short(Stats.power(def, char.Level, char.Mutation))
	ui.stats.Fishing.Text = string.format("🎣 FISHING POWER\n%.1f", State.fishingPower(uid))
	local sellValue = Stats.sellValue(def, char.Level, char.Mutation)
	ui.stats.Sell.Text = "🏷 SELL VALUE\n" .. Format.cash(sellValue)

	-- Buttons
	local cost = State.upgradeCost(uid)
	if cost then
		ui.upgrade.Text = "⬆ UPGRADE\n" .. Format.cash(cost)
		UI.setButtonEnabled(ui.upgrade, cash() >= cost, C.Green)
		local total, levels = multiCost(def, char, 5)
		ui.upgrade5.Text = string.format("⬆ x%d\n%s", levels, Format.cash(total))
		UI.setButtonEnabled(ui.upgrade5, cash() >= cost, C.Green)
	else
		ui.upgrade.Text = "MAX LEVEL"
		UI.setButtonEnabled(ui.upgrade, false)
		ui.upgrade5.Text = "MAX LEVEL"
		UI.setButtonEnabled(ui.upgrade5, false)
	end
	ui.place.Text = if char.Slot then "REMOVE FROM BASE" else "🏠 PLACE IN BASE"
	ui.place.BackgroundColor3 = if char.Slot then C.PanelLight else C.Blue
	local fishingUnlocked = State.derived.FishingUnlocked == true
	ui.fish.Visible = fishingUnlocked
	ui.fish.Text = if char.Fishing then "RECALL FROM POND" else "🎣 SEND FISHING"
	ui.fish.BackgroundColor3 = if char.Fishing then C.PanelLight else Color3.fromRGB(30, 120, 140)
	ui.lock.Text = if char.Locked then "🔓 UNLOCK" else "🔒 LOCK"
	ui.lock.BackgroundColor3 = if char.Locked then C.Gold:Lerp(Color3.new(0, 0, 0), 0.4) else C.PanelLight
	ui.setSellText("SELL " .. Format.cash(sellValue))
	UI.setButtonEnabled(ui.sell, not char.Locked, C.Red)

	if changed == nil or charChanged or changed.Gear or changed.Derived then
		rebuildGear(char)
	end
end

local function statBox(parent: Instance, order: number): TextLabel
	local box = UI.label({
		BackgroundTransparency = 0,
		BackgroundColor3 = C.Background,
		TextColor3 = C.Text,
		LayoutOrder = order,
		MaxTextSize = 17,
		Parent = parent,
	})
	UI.corner(box, 8)
	UI.padding(box, 4)
	return box
end

function Character.build(content: Frame)
	-- links: Vorschau + Zurück
	local left = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.38, -6, 1, 0), Parent = content })
	local preview = UI.panel({ BackgroundColor3 = C.Background, Size = UDim2.new(1, 0, 1, -56), Parent = left })
	ui.stroke = preview:FindFirstChildOfClass("UIStroke")
	ui.viewport = Viewport.create({ Parent = preview })
	Viewport.spin(ui.viewport, 0.7)
	UI.button({
		Text = "◀ BACK",
		Color = C.PanelLight,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 48),
		TextSize = 20,
		Parent = left,
		OnClick = function()
			Cards.open("Inventory")
		end,
	})

	-- rechts: Infos + Aktionen + Gear
	local holder = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.38, 4, 0, 0), Size = UDim2.new(0.62, -4, 1, 0), Parent = content })
	local scroll = UI.scrollList(holder, 6)
	ui.name = UI.label({ Font = F.Title, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -16, 0, 32), MaxTextSize = 30, LayoutOrder = 1, Parent = scroll })
	ui.rarity = UI.label({ TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -16, 0, 20), MaxTextSize = 16, LayoutOrder = 2, Parent = scroll })
	ui.mutation = UI.label({ Font = F.Title, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -16, 0, 20), MaxTextSize = 17, LayoutOrder = 3, Parent = scroll })
	ui.description = Cards.paragraph(scroll, "", 4)
	local levelBar, setLevel = UI.progress({ Size = UDim2.new(1, -16, 0, 22), Color = C.Purple, LayoutOrder = 5, Parent = scroll })
	ui.levelBar = levelBar
	ui.setLevel = setLevel
	ui.levelHint = UI.label({ TextColor3 = C.Gold, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -16, 0, 18), MaxTextSize = 15, LayoutOrder = 6, Parent = scroll })

	local statsGrid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 7, Parent = scroll })
	UI.new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 46), CellPadding = UDim2.fromOffset(8, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = statsGrid })
	ui.stats = {
		Income = statBox(statsGrid, 1),
		Power = statBox(statsGrid, 2),
		Fishing = statBox(statsGrid, 3),
		Sell = statBox(statsGrid, 4),
	}
	ui.stats.Income.TextColor3 = C.Cash

	local actions = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 8, Parent = scroll })
	UI.new("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 54), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = actions })
	local function action(order: number, text: string, color: Color3, onClick: () -> ()): TextButton
		return UI.button({ Text = text, Color = color, TextSize = 18, LayoutOrder = order, Parent = actions, OnClick = onClick })
	end
	ui.upgrade = action(1, "UPGRADE", C.Green, function()
		if currentUid then
			Actions.send("UpgradeCharacter", currentUid, 1)
		end
	end)
	ui.upgrade5 = action(2, "UPGRADE x5", C.Green, function()
		if currentUid then
			Actions.send("UpgradeCharacter", currentUid, 5)
		end
	end)
	ui.place = action(3, "PLACE IN BASE", C.Blue, function()
		local char = currentUid and State.character(currentUid)
		if char and currentUid then
			Actions.send(if char.Slot then "RemoveCharacter" else "PlaceCharacter", currentUid)
		end
	end)
	ui.fish = action(4, "SEND FISHING", C.Blue, function()
		local char = currentUid and State.character(currentUid)
		if char and currentUid then
			Actions.send(if char.Fishing then "RecallFishing" else "SendFishing", currentUid)
		end
	end)
	ui.lock = action(5, "LOCK", C.PanelLight, function()
		local char = currentUid and State.character(currentUid)
		if char and currentUid then
			Actions.send("LockCharacter", currentUid, not char.Locked)
		end
	end)
	local sell, setSellText = Cards.confirmButton({
		Text = "SELL",
		ConfirmText = "TAP AGAIN TO SELL",
		Color = C.Red,
		TextSize = 18,
		LayoutOrder = 6,
		Parent = actions,
		OnConfirm = function()
			if currentUid then
				Actions.send("SellCharacter", currentUid)
			end
		end,
	})
	ui.sell = sell
	ui.setSellText = setSellText

	ui.gearHeader = Cards.header(scroll, "🧰 GEAR", 9, C.Blue)
	ui.gearList = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 10, Parent = scroll })
	UI.list(ui.gearList, 6, false, Enum.HorizontalAlignment.Center)
	ui.scroll = scroll

	watcher = Cards.watch({
		Characters = function()
			return currentUid ~= nil and State.character(currentUid) ~= lastChar
		end,
		Cash = true,
		Gear = true,
		Derived = Cards.derivedChanged({ "GearSlots", "CashMultiplier", "FishingUnlocked" }),
	}, refresh, 0.1)
end

function Character.onOpen(args: any?)
	local uid = type(args) == "table" and args.Uid or nil
	if type(uid) == "string" then
		if uid ~= currentUid then
			ui.scroll.CanvasPosition = Vector2.zero
		end
		currentUid = uid
	end
	lastChar = nil
	watcher.open()
end

function Character.onClose()
	watcher.close()
end

return Character
