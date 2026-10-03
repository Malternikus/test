--!strict
-- Quests (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Quests
--
-- Tabs: DAILY (Fortschritt + CLAIM, Reset-Countdown bis UTC-Mitternacht),
-- ACHIEVEMENTS (alle, mit Status und Belohnung), SEASON (XP-Balken, Free- und
-- Premium-Track mit CLAIM; Premium nur mit Pass "SeasonPremium").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local QuestConfig = require(Config:WaitForChild("QuestConfig"))
local AchievementConfig = require(Config:WaitForChild("AchievementConfig"))
local SeasonConfig = require(Config:WaitForChild("SeasonConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))

local C = UI.Colors
local F = UI.Fonts

local Quests = {}
Quests.Title = "QUESTS"
Quests.Icon = "📜"
Quests.Size = Vector2.new(820, 540)

local TABS = { "Daily", "Achievements", "Season" }

local pages: { [string]: Frame } = {}
local scrolls: { [string]: ScrollingFrame } = {}
local currentTab = "Daily"
local selectTab: (string) -> ()
local resetLabel: TextLabel
local watcher: Cards.Watcher
local timerToken = 0

local function secondsToReset(): number
	local now = os.time()
	return 86400 - (now % 86400)
end

local function claimButton(row: Frame, text: string, enabled: boolean, color: Color3, onClick: () -> ()): TextButton
	local button = UI.button({
		Text = text,
		Color = color,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(120, 50),
		TextSize = 20,
		Parent = row,
		OnClick = onClick,
	})
	UI.setButtonEnabled(button, enabled, color)
	return button
end

local function buildDaily()
	local scroll = scrolls.Daily
	Cards.clear(scroll)
	resetLabel = Cards.header(scroll, "", 0, C.SubText)
	resetLabel.Text = "⏰ New quests in " .. Format.duration(secondsToReset())
	local list = (State.data.Quests and State.data.Quests.List) or {}
	for i, q in list do
		local def = QuestConfig.ById[q.Id]
		if def then
			local done = q.Progress >= def.Target
			local row = Cards.row(scroll, 98, i, if q.Claimed then C.Disabled elseif done then C.Green else C.Blue)
			Cards.rowText(row, def.Text, nil, if q.Claimed then C.SubText else C.Text, 140)
			local _, setBar = UI.progress({
				Position = UDim2.fromOffset(16, 34),
				Size = UDim2.new(1, -164, 0, 20),
				Color = if done then C.Green else C.Blue,
				Parent = row,
			})
			setBar(q.Progress / def.Target, Format.commas(math.min(q.Progress, def.Target)) .. " / " .. Format.commas(def.Target))
			UI.label({
				Text = "🎁 " .. Cards.rewardText(def.Rewards),
				TextColor3 = C.Gold,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(16, 60),
				Size = UDim2.new(1, -164, 0, 32),
				MaxTextSize = 15,
				Parent = row,
			})
			local id = q.Id
			claimButton(row, if q.Claimed then "✓ DONE" else "CLAIM", done and not q.Claimed, C.Green, function()
				Actions.send("ClaimQuest", id)
			end)
		end
	end
	if #list == 0 then
		Cards.paragraph(scroll, "No quests today. Check back soon!", 1)
	end
end

local function buildAchievements()
	local scroll = scrolls.Achievements
	Cards.clear(scroll)
	local unlocked = State.data.Achievements or {}
	local count = 0
	for _, def in AchievementConfig.List do
		if unlocked[def.Id] then
			count += 1
		end
	end
	Cards.header(scroll, string.format("🏆 UNLOCKED %d / %d", count, #AchievementConfig.List), 0)
	for i, def in AchievementConfig.List do
		local done = unlocked[def.Id] ~= nil
		local row = Cards.row(scroll, 76, i, if done then C.Gold else C.Disabled)
		local _, sub = Cards.rowText(row, (if done then "🏆 " else "🔒 ") .. def.DisplayName, def.Description .. "\n🎁 " .. Cards.rewardText(def.Rewards), if done then C.Gold else C.Text, 110)
		sub.TextColor3 = if done then C.SubText else C.SubText:Lerp(C.Background, 0.2)
		UI.label({
			Text = if done then "✓ UNLOCKED" else "LOCKED",
			Font = F.Title,
			TextColor3 = if done then C.Green else C.SubText,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(100, 24),
			MaxTextSize = 17,
			Parent = row,
		})
	end
end

local function buildSeason()
	local scroll = scrolls.Season
	Cards.clear(scroll)
	local season = State.data.Season or { Xp = 0, Free = {}, Premium = {} }
	local premium = State.data.Passes and State.data.Passes.SeasonPremium == true
	local maxTier = #SeasonConfig.Tiers
	local tier = math.min(maxTier, math.floor(season.Xp / SeasonConfig.XpPerTier))

	Cards.header(scroll, "🎟 " .. SeasonConfig.DisplayName, 0, C.Red)
	local _, setXp = UI.progress({ Size = UDim2.new(1, -16, 0, 24), Color = C.Purple, LayoutOrder = 1, Parent = scroll })
	if tier >= maxTier then
		setXp(1, string.format("TIER %d / %d · MAX", tier, maxTier))
	else
		local into = season.Xp - tier * SeasonConfig.XpPerTier
		setXp(into / SeasonConfig.XpPerTier, string.format("TIER %d / %d · %d / %d XP", tier, maxTier, into, SeasonConfig.XpPerTier))
	end
	Cards.paragraph(scroll, "Earn Season XP from daily quests. Premium rewards are cosmetics, potions, gear and cash – never characters.", 2)
	if not premium then
		UI.button({
			Text = "UNLOCK PREMIUM TRACK",
			Icon = "⭐",
			Color = C.Gold:Lerp(Color3.new(0, 0, 0), 0.3),
			Size = UDim2.new(1, -16, 0, 50),
			LayoutOrder = 3,
			Parent = scroll,
			OnClick = function()
				Cards.open("Shop", { Tab = "Passes", Highlight = "SeasonPremium" })
			end,
		})
	end

	for i, rewards in SeasonConfig.Tiers do
		local reached = tier >= i
		local row = Cards.row(scroll, 92, 10 + i, if reached then C.Purple else C.Disabled)
		UI.label({
			Text = "TIER\n" .. i,
			Font = F.Title,
			TextColor3 = if reached then C.Text else C.SubText,
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(0, 50, 1, -16),
			MaxTextSize = 20,
			Parent = row,
		})
		for t, track in { "Free", "Premium" } do
			local half = UI.new("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new((t - 1) * 0.5, if t == 1 then 66 else 36, 0, 6),
				Size = UDim2.new(0.5, if t == 1 then -72 else -42, 1, -12),
				Parent = row,
			})
			local reward = rewards[track]
			UI.label({
				Text = (if track == "Free" then "FREE: " else "⭐ PREMIUM: ") .. Cards.seasonRewardText(reward),
				TextColor3 = if track == "Free" then C.Text else C.Gold,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 26),
				MaxTextSize = 15,
				Parent = half,
			})
			local claimed = (season[track] or {})[tostring(i)] == true
			local locked = track == "Premium" and not premium
			local text = if claimed then "✓ CLAIMED" elseif locked then "🔒 PREMIUM" elseif reached then "CLAIM" else "TIER " .. i
			local button = UI.button({
				Text = text,
				Color = C.Green,
				Position = UDim2.fromOffset(0, 28),
				Size = UDim2.new(1, 0, 0, 48),
				TextSize = 18,
				Parent = half,
				OnClick = function()
					Actions.send("ClaimSeason", track, i)
				end,
			})
			UI.setButtonEnabled(button, reached and not claimed and not locked, C.Green)
		end
	end
end

local BUILDERS: { [string]: () -> () } = {
	Daily = buildDaily,
	Achievements = buildAchievements,
	Season = buildSeason,
}

local DEPENDS: { [string]: { [string]: boolean } } = {
	Daily = { Quests = true },
	Achievements = { Achievements = true },
	Season = { Season = true, Passes = true },
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
	local y = scrolls[currentTab].CanvasPosition
	BUILDERS[currentTab]()
	scrolls[currentTab].CanvasPosition = y
end

function Quests.build(content: Frame)
	for _, tab in TABS do
		local page = Cards.page(content, tab)
		pages[tab] = page
		scrolls[tab] = UI.scrollList(page, 8)
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
	watcher = Cards.watch({ Quests = true, Achievements = true, Season = true, Passes = true }, refresh, 0.2)
end

function Quests.onOpen(args: any?)
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
	-- Countdown jede Sekunde (nur solange offen)
	timerToken += 1
	local token = timerToken
	task.spawn(function()
		while token == timerToken and watcher.isVisible() do
			if resetLabel and resetLabel.Parent then
				resetLabel.Text = "⏰ New quests in " .. Format.duration(secondsToReset())
			end
			task.wait(1)
		end
	end)
end

function Quests.onClose()
	timerToken += 1
	watcher.close()
end

return Quests
