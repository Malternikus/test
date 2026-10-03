--!strict
-- Settings (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Settings
--
-- Schalter (SetSetting), Auto Delete bis Epic (SetAutoDelete), Sell All pro
-- Rarity (SellRarity, mit Bestätigung), Tutorial und – nur in Studio – ein
-- Debug-Bereich (Action "Debug"). Hinweis, wenn Studio ohne DataStore läuft.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))

local C = UI.Colors

local Settings = {}
Settings.Title = "SETTINGS"
Settings.Icon = "⚙"
Settings.Size = Vector2.new(780, 540)

local TOGGLES = {
	{ Key = "AutoPlace", Name = "AUTO PLACE", Text = "New characters replace the weakest one in your base if they earn more." },
	{ Key = "Music", Name = "MUSIC", Text = "Background music and ambience." },
	{ Key = "SFX", Name = "SOUND EFFECTS", Text = "Rolls, reveals, buttons." },
	{ Key = "ReducedEffects", Name = "REDUCED EFFECTS", Text = "Less flashing, shaking and particles." },
	{ Key = "ShowOthersReveals", Name = "OTHERS' BIG REVEALS", Text = "Show big reveals of other players on the server." },
}
local AUTO_DELETE = { "Common", "Uncommon", "Rare", "Epic" }
local SELL_RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

local toggleButtons: { [string]: TextButton } = {}
local autoDeleteButtons: { [string]: TextButton } = {}
local sellButtons: { [string]: { button: TextButton, setText: (string) -> () } } = {}
local ui: { [string]: any } = {}
local watcher: Cards.Watcher

local function setToggle(button: TextButton, on: boolean, onText: string?, offText: string?)
	button.Text = if on then (onText or "ON") else (offText or "OFF")
	button.BackgroundColor3 = if on then C.Green else C.Disabled
end

local function toggleRow(scroll: ScrollingFrame, order: number, title: string, sub: string, color: Color3?, onClick: () -> ()): TextButton
	local row = Cards.row(scroll, 70, order, color)
	Cards.rowText(row, title, sub, color or C.Text, 120)
	return UI.button({
		Text = "",
		Color = C.Disabled,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(108, 50),
		TextSize = 20,
		Parent = row,
		OnClick = onClick,
	})
end

-- Wie viele Characters würde SellRarity verkaufen? (gleiche Regeln wie der Server)
local function sellableCount(rarityId: string): number
	local n = 0
	for _, char in State.data.Characters or {} do
		local def = CharacterConfig.ById[char.Id]
		if def and def.Rarity == rarityId and not char.Locked and not char.Slot and not char.Fishing and char.Mutation == MutationConfig.None then
			n += 1
		end
	end
	return n
end

local function refresh(_changed: { [string]: boolean }?)
	local settings = State.data.Settings or {}
	for key, button in toggleButtons do
		setToggle(button, settings[key] == true)
	end
	local autoDelete = settings.AutoDelete or {}
	for id, button in autoDeleteButtons do
		local on = autoDelete[id] == true
		setToggle(button, on, "DELETE", "KEEP")
		button.BackgroundColor3 = if on then C.Red else C.Disabled
	end
	for id, entry in sellButtons do
		local n = sellableCount(id)
		entry.setText(if n > 0 then "SELL " .. n else "NONE")
		UI.setButtonEnabled(entry.button, n > 0, C.Red)
	end
	local tutorial = State.data.Tutorial or {}
	UI.setButtonEnabled(ui.skip, tutorial.Done ~= true, C.PanelLight)
	ui.memory.Visible = State.session.MemoryMode == true
	ui.debugHeader.Visible = State.session.IsStudio == true
	ui.debugGrid.Visible = State.session.IsStudio == true
end

function Settings.build(content: Frame)
	local scroll = UI.scrollList(content, 8)
	ui.memory = Cards.paragraph(scroll, "⚠ STUDIO: data is NOT saved – enable API access (Game Settings > Security) to test saving.", 0, C.Red)
	ui.memory.Visible = false

	Cards.header(scroll, "GAMEPLAY & SOUND", 1)
	for i, t in TOGGLES do
		local key = t.Key
		toggleButtons[key] = toggleRow(scroll, 1 + i, t.Name, t.Text, nil, function()
			local settings = State.data.Settings or {}
			Actions.send("SetSetting", key, not (settings[key] == true))
		end)
	end

	Cards.header(scroll, "AUTO DELETE", 20, C.Red)
	Cards.paragraph(scroll, "Rolled characters of these rarities are sold instantly. New discoveries and mutated characters are ALWAYS kept. Only up to Epic.", 21, C.Gold)
	for i, id in AUTO_DELETE do
		local rarity = RarityConfig.Get(id)
		autoDeleteButtons[id] = toggleRow(scroll, 21 + i, rarity.DisplayName, "Auto delete new " .. rarity.DisplayName .. " rolls", rarity.Color, function()
			local auto = (State.data.Settings and State.data.Settings.AutoDelete) or {}
			Actions.send("SetAutoDelete", id, not (auto[id] == true))
		end)
	end

	Cards.header(scroll, "SELL ALL", 40, C.Red)
	Cards.paragraph(scroll, "Sells every character of a rarity. Locked, placed, fishing and mutated characters are kept.", 41)
	for i, id in SELL_RARITIES do
		local rarity = RarityConfig.Get(id)
		local row = Cards.row(scroll, 70, 41 + i, rarity.Color)
		Cards.rowText(row, "SELL ALL " .. rarity.DisplayName, "Tap twice to confirm.", rarity.Color, 150)
		local button, setText = Cards.confirmButton({
			Text = "SELL",
			ConfirmText = "CONFIRM?",
			Color = C.Red,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(138, 50),
			TextSize = 20,
			Parent = row,
			OnConfirm = function()
				Actions.send("SellRarity", id)
			end,
		})
		sellButtons[id] = { button = button, setText = setText }
	end

	Cards.header(scroll, "TUTORIAL", 60)
	local tutorialRow = Cards.row(scroll, 70, 61)
	Cards.rowText(tutorialRow, "TUTORIAL", "Replay the tips or skip them.", nil, 240)
	UI.button({
		Text = "REPLAY",
		Color = C.Blue,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -128, 0.5, 0),
		Size = UDim2.fromOffset(108, 50),
		TextSize = 18,
		Parent = tutorialRow,
		OnClick = function()
			-- lokal: der Tutorial-Controller zeigt die Tipps erneut
			Actions.send("ReplayTutorial")
			Cards.close()
		end,
	})
	ui.skip = UI.button({
		Text = "SKIP",
		Color = C.PanelLight,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(108, 50),
		TextSize = 18,
		Parent = tutorialRow,
		OnClick = function()
			Actions.send("SkipTutorial")
		end,
	})

	-- Debug (nur Studio)
	ui.debugHeader = Cards.header(scroll, "🛠 DEBUG (STUDIO ONLY)", 80, C.CRTGreen)
	local debugGrid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 81, Parent = scroll })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(160, 50), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = debugGrid })
	ui.debugGrid = debugGrid
	local commands = {
		{ "+$1M", "Cash", 1e6 },
		{ "+$1B", "Cash", 1e9 },
		{ "REBIRTH READY", "RebirthReady", nil },
		{ "+5 ALL POTIONS", "Potions", nil },
		{ "+ALL GEAR", "Gear", nil },
		{ "UNLOCK ALL", "UnlockAll", nil },
		{ "ROLL x1000", "Roll", 1000 },
	}
	for i, cmd in commands do
		UI.button({
			Text = cmd[1],
			Color = Color3.fromRGB(20, 90, 50),
			TextSize = 18,
			LayoutOrder = i,
			Parent = debugGrid,
			OnClick = function()
				Actions.send("Debug", cmd[2], cmd[3])
			end,
		})
	end
	Cards.confirmButton({
		Text = "RESET PROFILE",
		ConfirmText = "REALLY RESET?",
		Color = C.Red,
		TextSize = 18,
		LayoutOrder = 99,
		Parent = debugGrid,
		OnConfirm = function()
			Actions.send("Debug", "Reset", nil)
		end,
	})

	watcher = Cards.watch({ Settings = true, Session = true, Tutorial = true, Characters = true }, refresh, 0.3)
end

function Settings.onOpen(_args: any?)
	watcher.open()
end

function Settings.onClose()
	watcher.close()
end

return Settings
