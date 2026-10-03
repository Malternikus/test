--!strict
-- Fishing (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Fishing
--
-- Rift Fishing. Gesperrt: Erklärung + Fortschritt (insgesamt verdientes Cash).
-- Offen: Tabs SPOTS (Angler + Kandidaten), WATERS (Gewässer wählen),
-- LOOT (echte Chancen über Odds/RollMath bei aktueller Fishing Luck) und
-- CATCHES (letzte Fänge, Event "Catch" – wird auch bei geschlossenem Fenster
-- gesammelt).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local Util = Shared:WaitForChild("Util")
local FishingConfig = require(Config:WaitForChild("FishingConfig"))
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local PotionConfig = require(Config:WaitForChild("PotionConfig"))
local Format = require(Util:WaitForChild("Format"))
local Odds = require(Util:WaitForChild("Odds"))
local RollMath = require(Util:WaitForChild("RollMath"))
local Stats = require(Util:WaitForChild("Stats"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))
local Viewport = require(Client:WaitForChild("UI"):WaitForChild("Viewport"))

local C = UI.Colors
local F = UI.Fonts

local Fishing = {}
Fishing.Title = "RIFT FISHING"
Fishing.Icon = "🎣"
Fishing.Size = Vector2.new(820, 540)

local TABS = { "Spots", "Waters", "Loot", "Catches" }
local MAX_CANDIDATES = 25

local recent: { any } = {}
local pages: { [string]: Frame } = {}
local scrolls: { [string]: ScrollingFrame } = {}
local currentTab = "Spots"
local selectTab: (string) -> ()
local ui: { [string]: any } = {}
local watcher: Cards.Watcher

local function lootName(kind: string, id: string?, cash: number?): string
	if kind == "Cash" then
		return if cash then "CASH " .. Format.cash(cash) else "CASH BAG"
	elseif kind == "Potion" and id then
		local def = PotionConfig.Get(id)
		return if def then def.DisplayName else id
	elseif kind == "Gear" and id then
		return Cards.gearName(id)
	elseif kind == "Relic" and id then
		local def = FishingConfig.RelicById[id]
		return if def then def.DisplayName else id
	elseif kind == "Cosmetic" and id then
		return Cards.cosmeticName(id)
	end
	return kind
end

local function rarityColor(id: string): Color3
	local r = RarityConfig.ById[id]
	return if r then r.Color else C.Text
end

local function interval(uid: string): number
	return Stats.catchInterval(State.fishingPower(uid), State.derived.FishingSpeed or 1)
end

-- Zeilen mit Character-Vorschau werden pro Key wiederverwendet (Auto-Roll
-- ändert die Characters jede Sekunde, Viewports sollen nicht neu gebaut werden)
type CharRow = { Frame: Frame, vp: ViewportFrame, title: TextLabel, sub: TextLabel, button: TextButton, vpKey: string, action: () -> () }
local charRows: { [string]: CharRow } = {}
local usedRows: { [string]: boolean } = {}

local function getRow(key: string): CharRow
	usedRows[key] = true
	local existing = charRows[key]
	if existing then
		return existing
	end
	local frame = Cards.row(scrolls.Spots, 72, 0)
	local vp = Viewport.create({ Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(60, 60), Parent = frame })
	local title, sub = Cards.rowText(frame, "", "", C.Text, 132, 74)
	local row: CharRow
	local button = UI.button({
		Text = "",
		Color = C.Blue,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(120, 50),
		TextSize = 19,
		Parent = frame,
		OnClick = function()
			row.action()
		end,
	})
	row = { Frame = frame, vp = vp, title = title, sub = sub, button = button, vpKey = "", action = function() end }
	charRows[key] = row
	return row
end

local function setCharRow(row: CharRow, order: number, entry: any, buttonText: string, color: Color3, enabled: boolean, action: () -> ())
	local uid = entry.uid
	local def = entry.def
	local rarity = RarityConfig.Get(def.Rarity)
	row.Frame.LayoutOrder = order
	row.vp.Visible = true
	local key = entry.char.Id .. "|" .. (entry.char.Mutation or "")
	if key ~= row.vpKey then
		row.vpKey = key
		Cards.setViewport(row.vp, entry.char.Id, entry.char.Mutation)
	end
	row.title.Text = def.DisplayName
	row.title.TextColor3 = rarity.Color
	row.sub.Text = string.format("%s · Lv %d · 🎣 %.1f power · 1 catch / %s", rarity.DisplayName, entry.char.Level, State.fishingPower(uid), Format.duration(interval(uid)))
	row.button.Visible = true
	row.button.Text = buttonText
	UI.setButtonEnabled(row.button, enabled, color)
	row.action = action
end

local function buildSpots()
	local scroll = scrolls.Spots
	table.clear(usedRows)
	local slots = State.derived.FishingSlots or GameConfig.StartFishingSlots
	local bySeat: { [number]: any } = {}
	local candidates = {}
	for _, entry in State.characterList("Rarity") do
		if entry.char.Fishing then
			bySeat[entry.char.Fishing] = entry
		elseif not entry.char.Slot then
			entry.power = State.fishingPower(entry.uid)
			table.insert(candidates, entry)
		end
	end
	local used = 0
	for _ in bySeat do
		used += 1
	end
	if not ui.spotsHeader then
		ui.spotsHeader = Cards.header(scroll, "", 0, C.Luck)
		ui.spotsInfo = Cards.paragraph(scroll, "", 1)
		Cards.header(scroll, "SEND A CHARACTER", 50, C.Blue)
		Cards.paragraph(scroll, "Characters that are not in your base, best fishers first. Base characters can be sent from their detail page.", 51)
		ui.noCandidates = Cards.paragraph(scroll, "No spare characters. Roll more, or remove one from your base.", 99)
	end
	ui.spotsHeader.Text = string.format("🎣 FISHING SPOTS %d / %d", used, slots)
	ui.spotsInfo.Text = string.format("Fishing Luck %s · Speed %s · Fishing characters earn no cash, but don't need a base slot.",
		Format.multiplier(State.derived.FishingLuck or 1), Format.multiplier(State.derived.FishingSpeed or 1))

	for seat = 1, slots do
		local entry = bySeat[seat]
		if entry then
			local uid = entry.uid
			setCharRow(getRow(uid), 10 + seat, entry, "RECALL", C.Red, true, function()
				Actions.send("RecallFishing", uid)
			end)
		else
			local row = getRow("seat" .. seat)
			row.Frame.LayoutOrder = 10 + seat
			row.vp.Visible = false
			row.button.Visible = false
			row.title.Text = "SPOT " .. seat .. " · EMPTY"
			row.title.TextColor3 = C.SubText
			row.sub.Text = "Send a character from the list below."
		end
	end

	table.sort(candidates, function(a, b)
		if a.power ~= b.power then
			return a.power > b.power
		end
		return a.uid < b.uid
	end)
	local free = used < slots
	for i, entry in candidates do
		if i > MAX_CANDIDATES then
			break
		end
		local uid = entry.uid
		setCharRow(getRow(uid), 100 + i, entry, "SEND", C.Blue, free, function()
			Actions.send("SendFishing", uid)
		end)
	end
	ui.noCandidates.Visible = #candidates == 0

	for key, row in charRows do
		if not usedRows[key] then
			row.Frame:Destroy()
			charRows[key] = nil
		end
	end
end

local function buildWaters()
	local scroll = scrolls.Waters
	Cards.clear(scroll)
	local areas = State.data.Areas or {}
	local currentWaters = State.data.FishingWaters or FishingConfig.DefaultWaters
	for i, waters in FishingConfig.Waters do
		local unlocked = areas[waters.Area] == true
		local area = AreaConfig.Get(waters.Area)
		local row = Cards.row(scroll, 96, i, waters.Color)
		local sub = waters.Description .. "\n" .. (if unlocked then "Area: " else "🔒 Unlock area: ") .. (if area then area.DisplayName else waters.Area)
		Cards.rowText(row, waters.DisplayName, sub, if unlocked then waters.Color else C.SubText, 250)
		local id = waters.Id
		local tune = UI.button({
			Text = if id == currentWaters then "✓ ACTIVE" elseif unlocked then "TUNE IN" else "🔒 LOCKED",
			Color = C.Green,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(118, 50),
			TextSize = 18,
			Parent = row,
			OnClick = function()
				Actions.send("SetWaters", id)
			end,
		})
		UI.setButtonEnabled(tune, unlocked and id ~= currentWaters, C.Green)
		UI.button({
			Text = "LOOT",
			Color = C.PanelLight,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -132, 0.5, 0),
			Size = UDim2.fromOffset(104, 50),
			TextSize = 18,
			Parent = row,
			OnClick = function()
				ui.lootPreview = id
				selectTab("Loot")
			end,
		})
	end
end

local function buildLoot()
	local scroll = scrolls.Loot
	Cards.clear(scroll)
	local watersId = ui.lootPreview or State.data.FishingWaters or FishingConfig.DefaultWaters
	local waters = FishingConfig.WatersById[watersId]
	local tbl = Odds.watersTable(watersId)
	if not waters or not tbl then
		return
	end
	local luck = State.derived.FishingLuck or 1
	local probs = RollMath.probabilities(tbl, luck)
	local active = watersId == (State.data.FishingWaters or FishingConfig.DefaultWaters)
	Cards.header(scroll, "🎁 LOOT · " .. waters.DisplayName .. (if active then " (ACTIVE)" else " (PREVIEW)"), 0, waters.Color)
	Cards.paragraph(scroll, string.format("Exact chances per catch at Fishing Luck %s. Gear on a character adds its own Fishing Luck on top. Luck boosts Rare and better.", Format.multiplier(luck)), 1)
	for i, entry in tbl.Entries do
		local loot = entry.Key
		local p = probs[i]
		local row = Cards.row(scroll, 48, 10 + i, rarityColor(loot.Rarity))
		local name = lootName(loot.Kind, loot.Id, nil)
		if loot.Kind == "Cash" and loot.Seconds then
			name = string.format("CASH (≈%s)", Format.cash(Cards.cashEstimate(loot.Seconds, 25)))
		end
		UI.label({
			Text = name .. "  ·  " .. string.upper(loot.Kind),
			Font = F.Title,
			TextColor3 = rarityColor(loot.Rarity),
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(16, 6),
			Size = UDim2.new(0.62, -16, 1, -12),
			MaxTextSize = 17,
			Parent = row,
		})
		UI.label({
			Text = Format.chance(p) .. "  (" .. Format.percent(p, if p < 0.01 then 3 else 1) .. ")",
			TextColor3 = C.Luck,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 6),
			Size = UDim2.new(0.38, -10, 1, -12),
			MaxTextSize = 16,
			Parent = row,
		})
	end
end

local function buildCatches()
	local scroll = scrolls.Catches
	Cards.clear(scroll)
	Cards.header(scroll, "🧾 RECENT CATCHES", 0, C.Gold)
	for i, catch in recent do
		local def = State.def(catch.Uid)
		local row = Cards.row(scroll, 56, i, rarityColor(catch.Rarity or "Common"))
		local sub = (if def then "Caught by " .. def.DisplayName else "Caught") .. (if catch.Probability then " · " .. Format.chance(catch.Probability) else "") .. (if catch.Duplicate then " · duplicate → cash" else "")
		Cards.rowText(row, lootName(catch.Kind, catch.Id, catch.Cash), sub, rarityColor(catch.Rarity or "Common"))
	end
	if #recent == 0 then
		Cards.paragraph(scroll, "Nothing caught yet this session.", 1)
	end
end

local BUILDERS: { [string]: () -> () } = { Spots = buildSpots, Waters = buildWaters, Loot = buildLoot, Catches = buildCatches }
local DEPENDS: { [string]: { [string]: boolean } } = {
	Spots = { Characters = true, Derived = true, Gear = true },
	Waters = { FishingWaters = true, Areas = true },
	Loot = { FishingWaters = true, Derived = true },
	Catches = { Catch = true },
}

local function refresh(changed: { [string]: boolean }?)
	local unlocked = State.derived.FishingUnlocked == true
	ui.locked.Visible = not unlocked
	ui.unlocked.Visible = unlocked
	if not unlocked then
		ui.wasUnlocked = false
		local earned = (State.data.Stats and State.data.Stats.TotalCashEarned) or 0
		local goal = GameConfig.FishingUnlockCashEarned
		ui.setUnlock(earned / goal, Format.cash(math.min(earned, goal)) .. " / " .. Format.cash(goal) .. " earned")
		return
	end
	if not ui.wasUnlocked then
		-- gerade freigeschaltet: alles neu aufbauen
		ui.wasUnlocked = true
		changed = nil
	end
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
end

function Fishing.build(content: Frame)
	-- gesperrt
	local locked = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = content })
	UI.list(locked, 12, false, Enum.HorizontalAlignment.Center)
	UI.label({ Text = "🎣 RIFT FISHING IS LOCKED", Font = F.Title, TextColor3 = C.Luck, Size = UDim2.new(1, -20, 0, 36), MaxTextSize = 30, LayoutOrder = 1, Parent = locked })
	local text = Cards.paragraph(locked, string.format("Earn %s in total to unlock Rift Fishing. Characters that are not in your base can fish at your Rift Pond and pull up potions, gear, relics and rare cosmetics.", Format.cash(GameConfig.FishingUnlockCashEarned)), 2, C.Text)
	text.TextXAlignment = Enum.TextXAlignment.Center
	local _, setUnlock = UI.progress({ Size = UDim2.new(0.8, 0, 0, 28), Color = C.Luck, LayoutOrder = 3, Parent = locked })
	ui.locked = locked
	ui.setUnlock = setUnlock

	-- offen
	local unlocked = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = content })
	ui.unlocked = unlocked
	for _, tab in TABS do
		local page = Cards.page(unlocked, tab)
		pages[tab] = page
		scrolls[tab] = UI.scrollList(page, 6)
	end
	local _, select = UI.tabs(unlocked, TABS, function(name: string)
		if name ~= "Loot" then
			ui.lootPreview = nil
		end
		currentTab = name
		for tab, page in pages do
			page.Visible = tab == name
		end
		if watcher and watcher.isVisible() then
			refresh(nil)
		end
	end)
	selectTab = select

	watcher = Cards.watch({
		Characters = true,
		Gear = true,
		FishingWaters = true,
		Areas = true,
		Stats = function()
			return State.derived.FishingUnlocked ~= true
		end,
		Derived = Cards.derivedChanged({ "FishingUnlocked", "FishingSlots", "FishingLuck", "FishingSpeed" }),
	}, refresh, 0.3)
end

-- Fänge auch bei geschlossenem Fenster sammeln
State.on("Catch", function(data: any)
	if type(data) ~= "table" then
		return
	end
	table.insert(recent, 1, data)
	while #recent > FishingConfig.MaxRecentCatches do
		table.remove(recent)
	end
	if watcher then
		watcher.request("Catch")
	end
end)

function Fishing.onOpen(args: any?)
	local tab = currentTab
	if type(args) == "table" and type(args.Tab) == "string" then
		for _, name in TABS do
			if string.lower(name) == string.lower(args.Tab) then
				tab = name
			end
		end
	end
	selectTab(tab)
	watcher.open()
end

function Fishing.onClose()
	watcher.close()
end

return Fishing
