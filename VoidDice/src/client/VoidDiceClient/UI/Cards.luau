--!strict
-- Cards (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > UI > Cards
--
-- Gemeinsame Bausteine für die Menü-Fenster:
--   Cards.characterCard   Karte mit Viewport (Inventory, Index, Inspect)
--   Cards.ownedInfo       Karten-Info für einen eigenen Character
--   Cards.watch           Refresh nur wenn sichtbar (sonst "dirty" merken)
--   Cards.row / header / paragraph / popup / confirmButton
--   Cards.rewardText / seasonRewardText / gearStats / baseChanceText
--
-- Viewports werden über eine Warteschlange gesetzt (wenige pro Frame), damit
-- das Öffnen eines großen Fensters nicht ruckelt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local Util = Shared:WaitForChild("Util")
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local PotionConfig = require(Config:WaitForChild("PotionConfig"))
local CosmeticConfig = require(Config:WaitForChild("CosmeticConfig"))
local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local Format = require(Util:WaitForChild("Format"))
local Odds = require(Util:WaitForChild("Odds"))

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Sound = require(Client:WaitForChild("Controllers"):WaitForChild("SoundController"))
local UI = require(script.Parent:WaitForChild("Components"))
local Viewport = require(script.Parent:WaitForChild("Viewport"))

local C = UI.Colors
local F = UI.Fonts

local Cards = {}

export type CardInfo = {
	Id: string?,
	Mutation: string?,
	Silhouette: boolean?,
	Title: string,
	TitleColor: Color3?,
	Lines: { string }?,
	LineColors: { Color3 }?,
	Badges: string?,
	Tag: string?,
	TagColor: Color3?,
	StrokeColor: Color3?,
}

export type Card = { Frame: TextButton, set: (CardInfo) -> () }

export type Watcher = {
	request: (key: string?) -> (),
	open: () -> (),
	close: () -> (),
	isVisible: () -> boolean,
}

export type Popup = { Frame: Frame, Body: Frame, show: (title: string) -> (), hide: () -> () }

-- Fenster öffnen ohne zirkuläres require (WindowManager lädt die Fenster)
function Cards.open(name: string, args: any?)
	local WindowManager = require(Client:WaitForChild("Controllers"):WaitForChild("WindowManager")) :: any
	WindowManager.open(name, args)
end

function Cards.close()
	local WindowManager = require(Client:WaitForChild("Controllers"):WaitForChild("WindowManager")) :: any
	WindowManager.close()
end

-- Viewport-Warteschlange ---------------------------------------------------------

local vpQueue: { ViewportFrame } = {}
local vpArgs: { [ViewportFrame]: { any } } = {}

function Cards.setViewport(frame: ViewportFrame, id: string?, mutation: string?, silhouette: boolean?)
	if not vpArgs[frame] then
		table.insert(vpQueue, frame)
	end
	vpArgs[frame] = { id, mutation, silhouette }
end

RunService.Heartbeat:Connect(function()
	local done = 0
	while done < 6 and #vpQueue > 0 do
		local frame = table.remove(vpQueue, 1) :: ViewportFrame
		local args = vpArgs[frame]
		vpArgs[frame] = nil
		if args and frame.Parent then
			Viewport.set(frame, args[1], args[2], args[3])
			done += 1
		end
	end
end)

-- Sichtbarkeits-Watcher ------------------------------------------------------------
-- keys: State-Keys -> true oder Prüf-Funktion (true = relevant).
-- refresh(changed) bekommt die gesammelten Keys (nil = alles neu, z. B. beim Öffnen).

function Cards.watch(keys: { [string]: any }, refresh: ({ [string]: boolean }?) -> (), delay: number?): Watcher
	local visible = false
	local scheduled = false
	local changed: { [string]: boolean } = {}
	local function run()
		scheduled = false
		if not visible then
			return
		end
		local batch = changed
		changed = {}
		refresh(batch)
	end
	local function request(key: string?)
		if key then
			changed[key] = true
		end
		if visible and not scheduled then
			scheduled = true
			task.delay(delay or 0.15, run)
		end
	end
	State.Changed:Connect(function(key: string)
		local check = keys[key]
		if check == true or (type(check) == "function" and (check :: any)()) then
			request(key)
		end
	end)
	return {
		request = request,
		open = function()
			visible = true
			changed = {}
			refresh(nil)
		end,
		close = function()
			visible = false
		end,
		isVisible = function()
			return visible
		end,
	}
end

-- true, wenn sich eines der Derived-Felder seit dem letzten Aufruf geändert hat
function Cards.derivedChanged(fields: { string }): () -> boolean
	local last: { [string]: any } = {}
	return function()
		local any = false
		for _, f in fields do
			local v = State.derived[f]
			if v ~= last[f] then
				last[f] = v
				any = true
			end
		end
		return any
	end
end

-- Character-Karte ------------------------------------------------------------------

function Cards.characterCard(parent: Instance, onClick: (() -> ())?): Card
	local button = UI.new("TextButton", {
		Name = "Card",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = C.PanelLight,
		BorderSizePixel = 0,
		Selectable = onClick ~= nil,
		Parent = parent,
	})
	UI.corner(button, 10)
	local stroke = UI.stroke(button, C.Stroke, 2)
	local gradient = UI.gradient(button, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 90)
	local vp = Viewport.create({ Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0.55, -4), Parent = button })
	local badges = UI.label({ Position = UDim2.fromOffset(6, 4), Size = UDim2.new(0.6, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, MaxTextSize = 18, Parent = button })
	local tag = UI.tag({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(62, 18), Parent = button })
	tag.Visible = false
	local title = UI.label({ Position = UDim2.new(0, 4, 0.55, 2), Size = UDim2.new(1, -8, 0, 20), Font = F.Title, MaxTextSize = 18, Parent = button })
	local lines: { TextLabel } = {}
	for i = 1, 3 do
		lines[i] = UI.label({ Position = UDim2.new(0, 4, 0.55, 22 + (i - 1) * 16), Size = UDim2.new(1, -8, 0, 15), TextColor3 = C.SubText, MaxTextSize = 14, Parent = button })
	end
	if onClick then
		button.Activated:Connect(function()
			Sound.play("UIClick")
			onClick()
		end)
		button.MouseEnter:Connect(function()
			stroke.Thickness = 3
		end)
		button.MouseLeave:Connect(function()
			stroke.Thickness = 2
		end)
	end

	local vpKey = ""
	local function set(info: CardInfo)
		title.Text = info.Title
		title.TextColor3 = info.TitleColor or C.Text
		for i, label in lines do
			local text = info.Lines and info.Lines[i]
			label.Text = text or ""
			label.Visible = text ~= nil
			label.TextColor3 = (info.LineColors and info.LineColors[i]) or C.SubText
		end
		badges.Text = info.Badges or ""
		if info.Tag then
			tag.Text = info.Tag
			tag.BackgroundColor3 = info.TagColor or C.Red
			tag.Visible = true
		else
			tag.Visible = false
		end
		local accent = info.StrokeColor or C.Stroke
		stroke.Color = accent
		gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), accent:Lerp(Color3.new(1, 1, 1), 0.55))
		local key = (info.Id or "") .. "|" .. (info.Mutation or "") .. "|" .. tostring(info.Silhouette)
		if key ~= vpKey then
			vpKey = key
			Cards.setViewport(vp, info.Id, info.Mutation, info.Silhouette)
		end
	end
	return { Frame = button, set = set }
end

function Cards.mutationTag(mutation: string?): (string?, Color3?)
	if not mutation or mutation == MutationConfig.None then
		return nil, nil
	end
	local m = MutationConfig.Get(mutation)
	return m.DisplayName, m.Color:Lerp(Color3.new(0, 0, 0), 0.25)
end

-- Karten-Info für einen eigenen Character (uid)
function Cards.ownedInfo(uid: string, char: any, def: any, income: number?): CardInfo
	local rarity = RarityConfig.Get(def.Rarity)
	local badges = ""
	if char.Slot then
		badges ..= "🏠"
	end
	if char.Fishing then
		badges ..= "🎣"
	end
	if char.Locked then
		badges ..= "🔒"
	end
	local tagText, tagColor = Cards.mutationTag(char.Mutation)
	local inc = income or State.income(uid)
	return {
		Id = char.Id,
		Mutation = char.Mutation,
		Title = def.DisplayName,
		TitleColor = rarity.Color,
		Lines = { rarity.DisplayName .. " · Lv " .. char.Level .. "/" .. def.MaxLevel, Format.perSecond(inc) },
		LineColors = { rarity.Color, if char.Slot then C.Cash else C.SubText },
		Badges = badges,
		Tag = tagText,
		TagColor = tagColor,
		StrokeColor = rarity.Color,
	}
end

-- Basis-Chance als Text. Commons: echte, normalisierte Chance (Luck 1).
function Cards.baseChanceText(def: any): string
	if not def.ReleaseEnabled then
		return "Not in rotation"
	end
	local rarity = RarityConfig.Get(def.Rarity)
	if rarity.LuckAffected then
		return Format.oneIn(def.RollChance)
	end
	return Format.chance(Odds.characterProbability(def.Id, 1))
end

-- Layout-Helfer --------------------------------------------------------------------

function Cards.clear(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function Cards.row(parent: Instance, height: number, order: number?, accent: Color3?): Frame
	local row = UI.panel({
		Name = "Row",
		BackgroundColor3 = C.PanelLight,
		Size = UDim2.new(1, -16, 0, height),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	if accent then
		local bar = UI.new("Frame", { BackgroundColor3 = accent, BorderSizePixel = 0, Size = UDim2.new(0, 6, 1, -12), Position = UDim2.fromOffset(4, 6), Parent = row })
		UI.corner(bar, 3)
	end
	return row
end

-- Titel + Untertitel in einer Row. right/left = reservierte Pixel.
function Cards.rowText(row: Frame, title: string, sub: string?, titleColor: Color3?, right: number?, left: number?): (TextLabel, TextLabel)
	local l = left or 16
	local r = right or 0
	local titleLabel = UI.label({
		Text = title,
		Font = F.Title,
		TextColor3 = titleColor or C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(l, 6),
		Size = UDim2.new(1, -(l + r + 8), 0, 22),
		MaxTextSize = 20,
		Parent = row,
	})
	local subLabel = UI.label({
		Text = sub or "",
		TextColor3 = C.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(l, 30),
		Size = UDim2.new(1, -(l + r + 8), 1, -36),
		MaxTextSize = 15,
		Parent = row,
	})
	return titleLabel, subLabel
end

function Cards.header(parent: Instance, text: string, order: number?, color: Color3?): TextLabel
	return UI.label({
		Name = "Header",
		Text = text,
		Font = F.Title,
		TextColor3 = color or C.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -16, 0, 28),
		LayoutOrder = order or 0,
		MaxTextSize = 22,
		Parent = parent,
	})
end

function Cards.paragraph(parent: Instance, text: string, order: number?, color: Color3?): TextLabel
	return UI.label({
		Text = text,
		TextScaled = false,
		TextSize = 15,
		TextColor3 = color or C.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -16, 0, 0),
		LayoutOrder = order or 0,
		Parent = parent,
	})
end

-- Seite unter einer Tab-Leiste
function Cards.page(parent: Instance, name: string, top: number?): Frame
	return UI.new("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, top or 56),
		Size = UDim2.new(1, 0, 1, -(top or 56)),
		Visible = false,
		Parent = parent,
	})
end

-- Button mit Bestätigung: erster Tap "scharf", zweiter innerhalb von 3 s führt aus.
-- Gibt Button und setText(normalText) zurück.
function Cards.confirmButton(props: { [string]: any }): (TextButton, (string) -> ())
	local normalText: string = props.Text or ""
	local armedUntil = 0
	local button: TextButton
	local onConfirm = props.OnConfirm
	props.OnClick = function()
		if os.clock() < armedUntil then
			armedUntil = 0
			button.Text = normalText
			onConfirm()
		else
			armedUntil = os.clock() + 3
			button.Text = props.ConfirmText or "TAP AGAIN TO CONFIRM"
			task.delay(3.05, function()
				if os.clock() >= armedUntil then
					button.Text = normalText
				end
			end)
		end
	end
	button = UI.button(props)
	local function setText(text: string)
		normalText = text
		if os.clock() >= armedUntil then
			button.Text = text
		end
	end
	return button, setText
end

-- Overlay-Popup im Fenster-Content (blockiert Klicks dahinter)
function Cards.popup(parent: Instance): Popup
	local overlay = UI.new("Frame", {
		Name = "Popup",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Active = true,
		Visible = false,
		Parent = parent,
	})
	local panel = UI.panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -16, 1, -16),
		StrokeColor = C.Purple,
		Active = true,
		Parent = overlay,
	})
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(640, 440), Parent = panel })
	local title = UI.label({
		Font = F.Title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -80, 0, 32),
		MaxTextSize = 26,
		Parent = panel,
	})
	local body = UI.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 52),
		Size = UDim2.new(1, -20, 1, -60),
		Parent = panel,
	})
	local function hide()
		overlay.Visible = false
	end
	UI.button({
		Text = "✕",
		Color = C.Red,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 6),
		Size = UDim2.fromOffset(52, 40),
		Parent = panel,
		OnClick = hide,
	})
	return {
		Frame = overlay,
		Body = body,
		show = function(text: string)
			title.Text = text
			overlay.Visible = true
		end,
		hide = hide,
	}
end

-- Texte ------------------------------------------------------------------------------

-- Schätzung für "Sekunden Einkommen"-Belohnungen (gleiche Formel wie der Server)
function Cards.cashEstimate(seconds: number, minimum: number?): number
	local income = math.max(EconomyConfig.ScaledReward.MinIncomePerSecond, State.derived.IncomePerSecond or 0)
	return math.max(minimum or 0, math.floor(income * seconds))
end

local function potionName(id: string): string
	local def = PotionConfig.Get(id)
	return if def then def.DisplayName else id
end

function Cards.gearName(id: string): string
	local def = GearConfig.Get(id)
	return if def then def.DisplayName else id
end

function Cards.cosmeticName(id: string): string
	local def = CosmeticConfig.Get(id)
	return if def then def.DisplayName .. " (" .. string.upper(def.Kind) .. ")" else id
end

-- Quest-/Achievement-Belohnungen
function Cards.rewardText(r: { [string]: any }): string
	local parts = {}
	if r.CashSeconds and r.CashSeconds > 0 then
		table.insert(parts, "≈" .. Format.cash(Cards.cashEstimate(r.CashSeconds, 100)))
	end
	if r.Cash and r.Cash > 0 then
		table.insert(parts, Format.cash(r.Cash))
	end
	if r.Potions then
		local ids = {}
		for id in r.Potions do
			table.insert(ids, id)
		end
		table.sort(ids)
		for _, id in ids do
			table.insert(parts, tostring(r.Potions[id]) .. "x " .. potionName(id))
		end
	end
	if r.Gear then
		table.insert(parts, Cards.gearName(r.Gear))
	end
	if r.Cosmetic then
		table.insert(parts, Cards.cosmeticName(r.Cosmetic))
	end
	if r.SeasonXp and r.SeasonXp > 0 then
		table.insert(parts, "+" .. r.SeasonXp .. " Season XP")
	end
	return if #parts > 0 then table.concat(parts, " · ") else "—"
end

-- Season-Tier-Belohnung ({ Kind = ... })
function Cards.seasonRewardText(r: { [string]: any }): string
	if r.Kind == "Cash" then
		return "≈" .. Format.cash(Cards.cashEstimate(r.Seconds or 0, 100))
	elseif r.Kind == "Potion" then
		return (r.Amount or 1) .. "x " .. potionName(r.Id)
	elseif r.Kind == "Gear" then
		return Cards.gearName(r.Id)
	elseif r.Kind == "Cosmetic" then
		return Cards.cosmeticName(r.Id)
	end
	return "?"
end

function Cards.gearStats(def: any): string
	local parts = {}
	if def.CashPct then
		table.insert(parts, "+" .. def.CashPct .. "% Cash")
	end
	if def.LuckPct then
		table.insert(parts, "+" .. def.LuckPct .. "% Luck (in base)")
	end
	if def.FishingPower then
		table.insert(parts, "+" .. def.FishingPower .. " Fishing Power")
	end
	if def.FishingLuckPct then
		table.insert(parts, "+" .. def.FishingLuckPct .. "% Fishing Luck")
	end
	return table.concat(parts, " · ")
end

function Cards.gearColor(def: any): Color3
	local r = GearConfig.RarityById[def.Rarity]
	return if r then r.Color else C.Text
end

function Cards.gearOrder(def: any): number
	local r = GearConfig.RarityById[def.Rarity]
	return if r then r.Order else 0
end

return Cards
