--!strict
-- Notifications (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Notifications
--
-- Toasts (rechts unten, gestapelt) und Server-Ansagen (Banner oben):
--   "PlayerName rolled THE ENDLESS!  1 in 2,500,000"
-- Reagiert auf die Server-Events aus Logic/Services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local PotionConfig = require(Config:WaitForChild("PotionConfig"))
local GearConfig = require(Config:WaitForChild("GearConfig"))
local FishingConfig = require(Config:WaitForChild("FishingConfig"))
local CosmeticConfig = require(Config:WaitForChild("CosmeticConfig"))
local DiceConfig = require(Config:WaitForChild("DiceConfig"))
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Root = require(Client:WaitForChild("UI"):WaitForChild("Root"))
local Sound = require(script.Parent:WaitForChild("SoundController"))

local C = UI.Colors
local F = UI.Fonts

local Notifications = {}

local toastHolder: Frame
local bannerHolder: Frame
local MAX_TOASTS = 5
local toastCounter = 0

local KIND_COLORS = {
	info = C.Blue,
	success = C.Green,
	error = C.Red,
	reward = C.Gold,
	rare = C.Purple,
}

function Notifications.toast(text: string, kind: string?, color: Color3?)
	local accent = color or KIND_COLORS[kind or "info"] or C.Blue
	toastCounter += 1
	local toast = UI.panel({
		Size = UDim2.fromOffset(300, 44),
		BackgroundTransparency = 0.1,
		StrokeColor = accent,
		LayoutOrder = toastCounter,
		Parent = toastHolder,
	})
	UI.label({
		Text = text,
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -20, 1, -8),
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 18,
		Parent = toast,
	})
	local bar = UI.new("Frame", { BackgroundColor3 = accent, BorderSizePixel = 0, Size = UDim2.new(0, 4, 1, 0), Parent = toast })
	UI.corner(bar, 2)
	local children = {}
	for _, child in toastHolder:GetChildren() do
		if child:IsA("Frame") then
			table.insert(children, child)
		end
	end
	if #children > MAX_TOASTS then
		table.sort(children, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		children[1]:Destroy()
	end
	if kind == "error" then
		Sound.play("UIError")
	end
	task.delay(3.5, function()
		if toast.Parent then
			UI.tween(toast, 0.3, { BackgroundTransparency = 1 })
			task.wait(0.3)
			toast:Destroy()
		end
	end)
end

-- Großes Banner oben (Server-Ansagen)
function Notifications.banner(text: string, color: Color3, subtext: string?, big: boolean?)
	local banner = UI.panel({
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(if big then 620 else 520, if big then 74 else 56),
		BackgroundColor3 = Color3.fromRGB(10, 6, 24),
		StrokeColor = color,
		StrokeThickness = if big then 4 else 2,
		Parent = bannerHolder,
	})
	UI.gradient(banner, color:Lerp(Color3.new(0, 0, 0), 0.6), Color3.fromRGB(10, 6, 24), 0)
	UI.label({
		Text = text,
		Font = F.Title,
		TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.3),
		Position = UDim2.fromOffset(12, 4),
		Size = UDim2.new(1, -24, if subtext then 0.6 else 1, -6),
		MaxTextSize = if big then 34 else 26,
		Parent = banner,
	})
	if subtext then
		UI.label({
			Text = subtext,
			TextColor3 = C.SubText,
			Position = UDim2.new(0, 12, 0.6, 0),
			Size = UDim2.new(1, -24, 0.4, -4),
			MaxTextSize = 18,
			Parent = banner,
		})
	end
	Sound.play("Announcement")
	local scale = UI.new("UIScale", { Scale = 0.6, Parent = banner })
	UI.tween(scale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(if big then 7 else 5, function()
		if banner.Parent then
			UI.tween(scale, 0.2, { Scale = 0.01 })
			task.wait(0.2)
			banner:Destroy()
		end
	end)
end

local function lootName(kind: string, id: string?): string
	if kind == "Cash" then
		return "Cash"
	elseif kind == "Potion" then
		local def = id and PotionConfig.Get(id)
		return def and def.DisplayName or (id or "?")
	elseif kind == "Gear" then
		local def = id and GearConfig.Get(id)
		return def and def.DisplayName or (id or "?")
	elseif kind == "Relic" then
		local def = id and FishingConfig.RelicById[id]
		return def and def.DisplayName or (id or "?")
	elseif kind == "Cosmetic" then
		local def = id and CosmeticConfig.Get(id)
		return def and def.DisplayName or (id or "?")
	end
	return id or kind
end

local function grantedText(granted): string
	if type(granted) ~= "table" then
		return ""
	end
	local parts = {}
	if granted.Cash then
		table.insert(parts, "+" .. Format.cash(granted.Cash))
	end
	for id, n in granted.Potions or {} do
		local def = PotionConfig.Get(id)
		table.insert(parts, string.format("%dx %s", n, def and def.DisplayName or id))
	end
	if granted.Gear then
		table.insert(parts, lootName("Gear", granted.Gear))
	end
	if granted.Cosmetic then
		table.insert(parts, lootName("Cosmetic", granted.Cosmetic))
	end
	if granted.SeasonXp then
		table.insert(parts, "+" .. granted.SeasonXp .. " Season XP")
	end
	return table.concat(parts, ", ")
end

function Notifications.init()
	toastHolder = UI.new("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -10, 1, -170),
		Size = UDim2.fromOffset(300, 260),
		Parent = Root.Layers.Toasts,
	})
	local list = UI.list(toastHolder, 6, false, Enum.HorizontalAlignment.Right)
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom

	bannerHolder = UI.new("Frame", {
		Name = "Banners",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 130),
		Size = UDim2.fromOffset(640, 240),
		Parent = Root.Layers.Toasts,
	})
	local bannerList = UI.list(bannerHolder, 6, false, Enum.HorizontalAlignment.Center)
	bannerList.VerticalAlignment = Enum.VerticalAlignment.Top

	State.on("Toast", function(data)
		Notifications.toast(data.Text, data.Kind)
	end)
	State.on("Collected", function(data)
		Sound.play("Collect")
		Notifications.toast("💰 Collected " .. Format.cash(data.Amount), "success")
	end)
	State.on("Sold", function(data)
		Notifications.toast(string.format("Sold %d for %s", data.Count or 1, Format.cash(data.Amount or 0)), "success")
	end)
	State.on("Upgraded", function()
		Sound.play("Upgrade")
	end)
	State.on("QuestComplete", function(data)
		Sound.play("Quest")
		Notifications.toast("📜 Quest complete: " .. data.Text .. " – claim it!", "reward")
	end)
	State.on("QuestClaimed", function(data)
		Notifications.toast("Quest reward: " .. grantedText(data.Granted), "reward")
	end)
	State.on("Achievement", function(data)
		Sound.play("Achievement")
		Notifications.banner("🏆 ACHIEVEMENT: " .. data.Name, C.Gold, grantedText(data.Granted))
	end)
	State.on("Cosmetic", function(data)
		Notifications.toast("✨ New " .. string.lower(data.Kind) .. ": " .. data.Name, "reward")
	end)
	State.on("Rebirth", function(data)
		Sound.play("Rebirth")
		Notifications.banner("♻ REBIRTH " .. data.Rebirths .. "!", C.Purple, "Cash and levels reset – your collection stays. Bonuses are permanent.", true)
	end)
	State.on("DiceUnlocked", function(data)
		local def = DiceConfig.Get(data.Id)
		Sound.play("Purchase")
		Notifications.banner("🎲 " .. (def and def.DisplayName or data.Id) .. " UNLOCKED", def and def.Color or C.Blue, def and ("x" .. def.Luck .. " Luck – equipped!") or nil)
	end)
	State.on("AreaUnlocked", function(data)
		local def = AreaConfig.Get(data.Id)
		Sound.play("Purchase")
		Notifications.banner("🗺 " .. (def and def.DisplayName or data.Id) .. " UNLOCKED", def and def.PrimaryColor or C.Green, def and def.Tagline or nil)
	end)
	State.on("BoostEnded", function(data)
		local def = PotionConfig.Get(data.Id)
		Notifications.toast((def and def.DisplayName or data.Id) .. " ran out", "info")
	end)
	State.on("Catch", function(data)
		local rarity = RarityConfig.ById[data.Rarity]
		local name = lootName(data.Kind, data.Id)
		local text = "🎣 " .. name
		if data.Cash then
			text ..= " +" .. Format.cash(data.Cash)
		end
		local order = rarity and rarity.Order or 1
		Sound.play(if order >= 4 then "FishingBigCatch" else "FishingCatch")
		Notifications.toast(text, if order >= 3 then "rare" else "info", rarity and rarity.Color)
	end)
	State.on("ProductGranted", function()
		Sound.play("Purchase")
		Notifications.toast("Purchase complete. Thank you!", "success")
	end)
	State.on("SeasonClaimed", function(data)
		Notifications.toast("Season reward: " .. grantedText(data.Granted), "reward")
	end)
	State.on("TutorialDone", function()
		Notifications.banner("TUTORIAL COMPLETE", C.Green, "Here is a Luck Potion. Now go find the rarest entity.")
	end)

	-- Ansagen --------------------------------------------------------------------------
	State.on("Announcement", function(data)
		local isMe = data.UserId == Players.LocalPlayer.UserId
		local settings = State.data.Settings
		if not isMe and settings and settings.ShowOthersReveals == false then
			return
		end
		local rarity = RarityConfig.ById[data.Rarity or ""]
		local color = rarity and rarity.Color or C.Purple
		local prefix = if data.CrossServer then "🌐 " else ""
		if data.Kind == "Roll" then
			local mutation = MutationConfig.Get(data.Mutation)
			local mutText = if mutation.Id ~= MutationConfig.None then mutation.DisplayName .. " " else ""
			local title = string.format("%s%s rolled %s%s!", prefix, data.Player, mutText, string.upper(data.Name or "?"))
			if data.Double then
				title = "DOUBLE SECRET! " .. title
			end
			local def = CharacterConfig.ById[data.Id]
			local chance = if def then Format.oneIn(def.RollChance) else ""
			local big = rarity ~= nil and rarity.Order >= RarityConfig.Order("Secret")
			Notifications.banner(title, color, chance, big)
		elseif data.Kind == "Catch" then
			Notifications.banner(string.format("%s%s fished up %s!", prefix, data.Player, lootName(data.LootKind, data.Id)), color, data.Probability and Format.chance(data.Probability) or nil)
		elseif data.Kind == "MaxLevel" then
			Notifications.banner(string.format("%s maxed %s to LEVEL 15!", data.Player, data.Name), color, nil)
		end
	end)
	State.on("PlayerRebirth", function(data)
		if data.UserId ~= Players.LocalPlayer.UserId then
			Notifications.toast(string.format("♻ %s reached Rebirth %d", data.Player, data.Rebirths), "info")
		end
	end)
end

return Notifications
