--!strict
-- Items (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Items
--
-- Tabs: POTIONS (benutzen, Restzeit), GEAR (Stats, ausgerüstet auf, EQUIP mit
-- Character-Auswahl, SELL), RELICS (verkaufen), COSMETICS (nach Art, EQUIP).
-- Nur der sichtbare Tab wird bei Änderungen neu aufgebaut.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local PotionConfig = require(Config:WaitForChild("PotionConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local FishingConfig = require(Config:WaitForChild("FishingConfig"))
local CosmeticConfig = require(Config:WaitForChild("CosmeticConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))

local C = UI.Colors

local Items = {}
Items.Title = "ITEMS"
Items.Icon = "🧪"
Items.Size = Vector2.new(820, 540)

local TABS = { "Potions", "Gear", "Relics", "Cosmetics" }
local MAX_PICKER = 60

local pages: { [string]: Frame } = {}
local scrolls: { [string]: ScrollingFrame } = {}
local currentTab = "Potions"
local selectTab: (string) -> ()
local potionRows: { [string]: { status: TextLabel, button: TextButton } } = {}
local picker: Cards.Popup
local pickerScroll: ScrollingFrame
local pickerGear: string? = nil
local watcher: Cards.Watcher

local function rightButton(row: Frame, text: string, color: Color3, x: number, onClick: () -> ()): TextButton
	return UI.button({
		Text = text,
		Color = color,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -x, 0.5, 0),
		Size = UDim2.fromOffset(110, 50),
		TextSize = 18,
		Parent = row,
		OnClick = onClick,
	})
end

-- Potions --------------------------------------------------------------------------

local function buildPotionRows()
	local scroll = scrolls.Potions
	Cards.paragraph(scroll, "Potions stack their time (max " .. Format.duration(PotionConfig.MaxDuration) .. "). Time only runs while you are online.", 0)
	for i, def in PotionConfig.List do
		local row = Cards.row(scroll, 84, i, def.Color)
		local _, sub = Cards.rowText(row, "🧪 " .. def.DisplayName, def.Description, def.Color, 124)
		sub.Size = UDim2.new(1, -148, 0, 26)
		local status = UI.label({
			TextColor3 = C.Gold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 16, 1, -26),
			Size = UDim2.new(1, -148, 0, 20),
			MaxTextSize = 15,
			Parent = row,
		})
		local id = def.Id
		local button = rightButton(row, "USE", C.Green, 10, function()
			Actions.send("UsePotion", id)
		end)
		potionRows[id] = { status = status, button = button }
	end
end

local function refreshPotions()
	local owned = State.data.Potions or {}
	local boosts = State.data.Boosts or {}
	for id, row in potionRows do
		local have = owned[id] or 0
		local left = boosts[id]
		row.status.Text = "Owned: " .. have .. (if left and left > 0 then "  ·  ACTIVE " .. Format.duration(left) else "")
		local maxed = left ~= nil and left >= PotionConfig.MaxDuration - 1
		row.button.Text = if maxed then "MAXED" else "USE"
		UI.setButtonEnabled(row.button, have > 0 and not maxed, C.Green)
	end
end

-- Gear -----------------------------------------------------------------------------

local function openPicker(gearUid: string)
	local item = State.data.Gear and State.data.Gear[gearUid]
	local def = item and GearConfig.Get(item.Id)
	if not def then
		return
	end
	pickerGear = gearUid
	Cards.clear(pickerScroll)
	Cards.paragraph(pickerScroll, Cards.gearStats(def), 0, Cards.gearColor(def))
	local slots = State.derived.GearSlots or GameConfig.StartGearSlots
	for i, entry in State.characterList("Rarity") do
		if i > MAX_PICKER then
			break
		end
		local uid = entry.uid
		local rarity = RarityConfig.Get(entry.def.Rarity)
		local gearCount = #(entry.char.Gear or {})
		local where = if entry.char.Slot then "🏠 In base" elseif entry.char.Fishing then "🎣 Fishing" else "Inventory"
		local row = Cards.row(pickerScroll, 64, i, rarity.Color)
		Cards.rowText(row, entry.def.DisplayName, string.format("%s · Lv %d · Gear %d/%d · %s", rarity.DisplayName, entry.char.Level, gearCount, slots, where), rarity.Color, 124)
		local here = item.On == uid
		local button = rightButton(row, if here then "EQUIPPED" else "EQUIP", C.Blue, 8, function()
			Actions.send("EquipGear", gearUid, uid)
			picker.hide()
		end)
		UI.setButtonEnabled(button, not here and gearCount < slots, C.Blue)
	end
	picker.show("EQUIP " .. def.DisplayName)
	pickerScroll.CanvasPosition = Vector2.zero
end

local function buildGear()
	local scroll = scrolls.Gear
	Cards.clear(scroll)
	local list = {}
	local count = 0
	for uid, item in State.data.Gear or {} do
		local def = GearConfig.Get(item.Id)
		count += 1
		if def then
			table.insert(list, { uid = uid, item = item, def = def, order = Cards.gearOrder(def) })
		end
	end
	table.sort(list, function(a, b)
		if a.order ~= b.order then
			return a.order > b.order
		end
		if a.def.DisplayName ~= b.def.DisplayName then
			return a.def.DisplayName < b.def.DisplayName
		end
		return a.uid < b.uid
	end)
	Cards.header(scroll, string.format("🧰 GEAR %d / %d", count, GameConfig.GearInventoryCap), 0)
	for i, entry in list do
		local def = entry.def
		local color = Cards.gearColor(def)
		local onDef = entry.item.On and State.def(entry.item.On)
		local row = Cards.row(scroll, 84, i, color)
		local _, sub = Cards.rowText(row, def.DisplayName .. "  ·  " .. string.upper(def.Rarity), Cards.gearStats(def) .. "\n" .. (if onDef then "Equipped on " .. onDef.DisplayName else "Not equipped"), color, 240)
		sub.TextColor3 = if onDef then C.Text else C.SubText
		local gearUid = entry.uid
		if entry.item.On then
			rightButton(row, "UNEQUIP", C.PanelLight, 128, function()
				Actions.send("UnequipGear", gearUid)
			end)
		else
			rightButton(row, "EQUIP", C.Blue, 128, function()
				openPicker(gearUid)
			end)
		end
		Cards.confirmButton({
			Text = "SELL",
			ConfirmText = "SURE?",
			Color = C.Red,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(110, 50),
			TextSize = 18,
			Parent = row,
			OnConfirm = function()
				Actions.send("SellGear", gearUid)
			end,
		})
	end
	if #list == 0 then
		Cards.paragraph(scroll, "No gear yet. Gear drops from fishing, quests and the season pass.", 1)
	end
end

-- Relics ---------------------------------------------------------------------------

local function buildRelics()
	local scroll = scrolls.Relics
	Cards.clear(scroll)
	local owned = State.data.Relics or {}
	local found = 0
	for _, def in FishingConfig.Relics do
		if (owned[def.Id] or 0) > 0 then
			found += 1
		end
	end
	Cards.header(scroll, string.format("🗝 RELICS %d / %d", found, #FishingConfig.Relics), 0)
	for i, def in FishingConfig.Relics do
		local have = owned[def.Id] or 0
		local color = RarityConfig.ById[def.Rarity] and RarityConfig.ById[def.Rarity].Color or C.Text
		local row = Cards.row(scroll, 76, i, color)
		local title = if have > 0 then string.format("%s  x%d", def.DisplayName, have) else "??? (" .. string.upper(def.Rarity) .. ")"
		local sub = if have > 0 then def.Description .. "\nSells for ≈" .. Format.cash(Cards.cashEstimate(def.SellSeconds, 100)) else "Not found yet. Keep fishing!"
		Cards.rowText(row, title, sub, if have > 0 then color else C.SubText, 124)
		local id = def.Id
		local button = rightButton(row, "SELL 1", C.Red, 10, function()
			Actions.send("SellRelic", id)
		end)
		UI.setButtonEnabled(button, have > 0, C.Red)
	end
end

-- Cosmetics ------------------------------------------------------------------------

local function buildCosmetics()
	local scroll = scrolls.Cosmetics
	Cards.clear(scroll)
	local cosmetics = State.data.Cosmetics or { Owned = {}, Equipped = {} }
	local order = 0
	for _, kind in CosmeticConfig.Kinds do
		local owned, missing = {}, 0
		for _, def in CosmeticConfig.List do
			if def.Kind == kind then
				if cosmetics.Owned[def.Id] then
					table.insert(owned, def)
				else
					missing += 1
				end
			end
		end
		order += 1
		Cards.header(scroll, string.upper(kind) .. (if missing > 0 then string.format("  (%d more to find)", missing) else ""), order, C.Purple)
		for _, def in owned do
			order += 1
			local equipped = cosmetics.Equipped[kind] == def.Id
			local color = def.Color or (def.Colors and def.Colors[1]) or C.Text
			local row = Cards.row(scroll, 64, order, color)
			Cards.rowText(row, def.DisplayName, "From: " .. def.Source, color, 124)
			local id = def.Id
			local button = rightButton(row, if equipped then "EQUIPPED" else "EQUIP", C.Blue, 10, function()
				Actions.send("EquipCosmetic", kind, id)
			end)
			UI.setButtonEnabled(button, not equipped, C.Blue)
		end
		if #owned == 0 then
			order += 1
			Cards.paragraph(scroll, "None yet.", order)
		end
	end
end

local BUILDERS: { [string]: () -> () } = { Potions = refreshPotions, Gear = buildGear, Relics = buildRelics, Cosmetics = buildCosmetics }
local DEPENDS: { [string]: { [string]: boolean } } = {
	Potions = { Potions = true, Boosts = true },
	Gear = { Gear = true, Derived = true },
	Relics = { Relics = true },
	Cosmetics = { Cosmetics = true },
}

local function refresh(changed: { [string]: boolean }?)
	if changed then
		local relevant = false
		for key in changed do
			if DEPENDS[currentTab][key] then
				relevant = true
			end
		end
		if not relevant then
			return
		end
	end
	local scroll = scrolls[currentTab]
	local y = scroll.CanvasPosition
	BUILDERS[currentTab]()
	scroll.CanvasPosition = y
	if picker.Frame.Visible and pickerGear and changed and changed.Gear then
		picker.hide()
	end
end

function Items.build(content: Frame)
	for _, tab in TABS do
		local page = Cards.page(content, tab)
		pages[tab] = page
		scrolls[tab] = UI.scrollList(page, 6)
	end
	local _, select = UI.tabs(content, TABS, function(name: string)
		currentTab = name
		for tab, page in pages do
			page.Visible = tab == name
		end
		if watcher and watcher.isVisible() then
			refresh(nil)
		end
	end)
	selectTab = select
	buildPotionRows()

	picker = Cards.popup(content)
	pickerScroll = UI.scrollList(picker.Body, 6)

	watcher = Cards.watch({
		Potions = true,
		Boosts = true,
		Gear = true,
		Relics = true,
		Cosmetics = true,
		Derived = Cards.derivedChanged({ "GearSlots" }),
	}, refresh, 0.2)
end

function Items.onOpen(args: any?)
	local tab = currentTab
	if type(args) == "table" and type(args.Tab) == "string" then
		for _, name in TABS do
			if string.lower(name) == string.lower(args.Tab) then
				tab = name
			end
		end
	end
	picker.hide()
	selectTab(tab)
	watcher.open()
end

function Items.onClose()
	picker.hide()
	watcher.close()
end

return Items
