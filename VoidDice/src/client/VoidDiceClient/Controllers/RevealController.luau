--!strict
-- RevealController (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > RevealController
--
-- Zeigt Roll-Ergebnisse. Die Stärke hängt von RarityConfig.RevealTier ab
-- (Timings in UIConfig.Reveal):
--   0–2  kleine Karte über dem ROLL-Button (Common sehr schnell)
--   3+   Vollbild-Reveal: Flash, Spin, Zoom (FOV), Kamera-Shake
--   6+   Blackout,  7+ Glitch,  8 (Anomaly) Regenbogen
-- Antippen überspringt große Reveals. Bei Auto Roll werden alte kleine
-- Reveals verworfen, damit die Anzeige nie hinterherhinkt.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local UIConfig = require(Config:WaitForChild("UIConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))
local Odds = require(Shared:WaitForChild("Util"):WaitForChild("Odds"))

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Root = require(Client:WaitForChild("UI"):WaitForChild("Root"))
local Viewport = require(Client:WaitForChild("UI"):WaitForChild("Viewport"))
local Sound = require(script.Parent:WaitForChild("SoundController"))

local C = UI.Colors
local F = UI.Fonts
local new = UI.new

local RevealController = {}

local queue: { any } = {}
local busy = false
local skipRequested = false

-- "1 in X" wie im Index: Basis-Chance bzw. normalisiert bei Commons
local function baseChanceText(def): string
	local rarity = RarityConfig.Get(def.Rarity)
	if rarity.LuckAffected then
		return Format.oneIn(def.RollChance)
	end
	return Format.chance(Odds.characterProbability(def.Id, 1))
end

local function shake(intensity: number, duration: number)
	if intensity <= 0 or (State.data.Settings and State.data.Settings.ReducedEffects) then
		return
	end
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local started = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - started
		if t > duration then
			humanoid.CameraOffset = Vector3.zero
			connection:Disconnect()
			return
		end
		local falloff = 1 - t / duration
		local r = intensity * falloff * 0.6
		humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * r, (math.random() - 0.5) * r, 0)
	end)
end

local function zoom(amount: number, duration: number)
	local camera = workspace.CurrentCamera
	if amount <= 0 or not camera or (State.data.Settings and State.data.Settings.ReducedEffects) then
		return
	end
	local base = 70
	camera.FieldOfView = base
	UI.tween(camera, duration * 0.3, { FieldOfView = base - amount }, Enum.EasingStyle.Quad)
	task.delay(duration * 0.75, function()
		UI.tween(camera, 0.4, { FieldOfView = base })
	end)
end

-- Kleine Karte ---------------------------------------------------------------------
local smallCard: Frame
local smallViewport: ViewportFrame
local smallLabels: { [string]: TextLabel } = {}
local smallGradient: UIGradient

local function buildSmall(gui: ScreenGui)
	smallCard = UI.panel({
		Name = "SmallReveal",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -178),
		Size = UDim2.fromOffset(360, 112),
		Visible = false,
		Parent = gui,
	})
	UI.new("UIScale", { Parent = smallCard })
	smallGradient = UI.gradient(smallCard, C.Panel, C.Panel, 90)
	smallViewport = Viewport.create({ Size = UDim2.fromOffset(104, 104), Position = UDim2.fromOffset(4, 4), Parent = smallCard })
	smallLabels.Name = UI.label({ Font = F.Title, Position = UDim2.fromOffset(112, 6), Size = UDim2.new(1, -120, 0, 32), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 30, Parent = smallCard })
	smallLabels.Rarity = UI.label({ Position = UDim2.fromOffset(112, 38), Size = UDim2.new(1, -120, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, MaxTextSize = 18, Parent = smallCard })
	smallLabels.Info = UI.label({ Position = UDim2.fromOffset(112, 60), Size = UDim2.new(1, -120, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.SubText, MaxTextSize = 16, Parent = smallCard })
	smallLabels.Extra = UI.label({ Position = UDim2.fromOffset(112, 82), Size = UDim2.new(1, -120, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.Gold, MaxTextSize = 16, Parent = smallCard })
	local newTag = UI.tag({ Text = "NEW!", Color = C.Red, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, -10), Size = UDim2.fromOffset(64, 24), Parent = smallCard })
	newTag.Name = "NewTag"
end

local function showSmall(data, def, tierInfo)
	local rarity = RarityConfig.Get(def.Rarity)
	local mutation = MutationConfig.Get(data.Mutation)
	Viewport.set(smallViewport, def.Id, data.Mutation)
	smallLabels.Name.Text = def.DisplayName
	smallLabels.Name.TextColor3 = rarity.Color
	smallLabels.Rarity.Text = rarity.DisplayName .. "  ·  " .. baseChanceText(def)
	smallLabels.Rarity.TextColor3 = rarity.Color
	smallLabels.Info.Text = Format.perSecond(def.BaseMoneyPerSecond * mutation.MoneyMultiplier) .. " base"
	local extra = ""
	if mutation.Id ~= MutationConfig.None then
		extra = mutation.DisplayName .. " MUTATION  "
		smallLabels.Extra.TextColor3 = mutation.Color
	else
		smallLabels.Extra.TextColor3 = C.Gold
	end
	if data.SoldFor then
		extra ..= (if data.SoldReason == "AutoDelete" then "AUTO-DELETED " else "INVENTORY FULL ") .. "+" .. Format.cash(data.SoldFor)
	elseif data.Placed then
		extra ..= "→ PLACED IN BASE"
	elseif data.ReplacedValue then
		extra ..= "INVENTORY FULL: sold weakest +" .. Format.cash(data.ReplacedValue)
	end
	smallLabels.Extra.Text = extra
	smallCard:FindFirstChild("NewTag").Visible = data.IsNew
	local stroke = smallCard:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = rarity.Color
		stroke.Thickness = 2 + tierInfo.Flash * 3
	end
	smallGradient.Color = ColorSequence.new(rarity.Color2:Lerp(C.Panel, 0.65), C.Panel)

	smallCard.Visible = true
	local scale = smallCard:FindFirstChildOfClass("UIScale") :: UIScale
	scale.Scale = 0.7
	UI.tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
	Sound.play("Reveal" .. rarity.RevealTier)
	local token = {}
	smallCard:SetAttribute("Token", tostring(token))
	task.delay(tierInfo.Duration + 0.6, function()
		if smallCard:GetAttribute("Token") == tostring(token) then
			smallCard.Visible = false
		end
	end)
end

-- Großes Reveal -----------------------------------------------------------------------
local big: Frame
local bigParts: { [string]: any } = {}

local function buildBig(gui: ScreenGui)
	big = new("TextButton", {
		Name = "BigReveal",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = gui,
	})
	;(big :: any).Activated:Connect(function()
		skipRequested = true
	end)
	bigParts.Flash = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = big })
	bigParts.Rays = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(520, 520), Parent = big })
	for i = 1, 8 do
		local ray = new("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 26, 1, 0),
			Rotation = i * 22.5,
			Parent = bigParts.Rays,
		})
		UI.gradient(ray, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 90).Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1),
		})
	end
	bigParts.Die = UI.label({
		Text = "?", Font = F.Title, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(180, 180), BackgroundTransparency = 0, BackgroundColor3 = C.Purple, MaxTextSize = 120, ZIndex = 5, Parent = big,
	})
	UI.corner(bigParts.Die, 30)
	UI.stroke(bigParts.Die, Color3.new(1, 1, 1), 5)
	bigParts.Viewport = Viewport.create({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(340, 340), ZIndex = 6, Parent = big })
	bigParts.Name = UI.label({ Font = F.Title, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.66), Size = UDim2.new(0.9, 0, 0, 64), MaxTextSize = 64, ZIndex = 8, Parent = big })
	bigParts.Rarity = UI.label({ Font = F.Title, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.66, 66), Size = UDim2.new(0.8, 0, 0, 36), MaxTextSize = 36, ZIndex = 8, Parent = big })
	bigParts.RarityGradient = UI.gradient(bigParts.Rarity, Color3.new(1, 1, 1), Color3.new(1, 1, 1), 0)
	bigParts.Chance = UI.label({ Font = F.Title, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.66, 104), Size = UDim2.new(0.8, 0, 0, 30), TextColor3 = C.Text, MaxTextSize = 30, ZIndex = 8, Parent = big })
	bigParts.Info = UI.label({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.66, 136), Size = UDim2.new(0.8, 0, 0, 22), TextColor3 = C.SubText, MaxTextSize = 20, ZIndex = 8, Parent = big })
	bigParts.New = UI.tag({ Text = "NEW!", Color = C.Red, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 130, 0.66, 0), Size = UDim2.fromOffset(110, 40), ZIndex = 9, Parent = big })
	bigParts.Mutation = UI.tag({ Text = "", Color = C.Gold, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, -130, 0.66, 0), Size = UDim2.fromOffset(160, 40), ZIndex = 9, Parent = big })
	bigParts.Skip = UI.label({ Text = "TAP TO CONTINUE", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(300, 20), TextColor3 = C.SubText, MaxTextSize = 16, ZIndex = 8, Parent = big })
end

local function waitOrSkip(seconds: number)
	local started = os.clock()
	while os.clock() - started < seconds and not skipRequested do
		task.wait()
	end
end

local function showBig(data, def, tierInfo)
	local rarity = RarityConfig.Get(def.Rarity)
	local mutation = MutationConfig.Get(data.Mutation)
	local reduced = State.data.Settings and State.data.Settings.ReducedEffects
	skipRequested = false
	big.Visible = true
	big.BackgroundTransparency = if tierInfo.Blackout then 0.05 else 0.35
	bigParts.Viewport.Visible = false
	bigParts.Name.Visible = false
	bigParts.Rarity.Visible = false
	bigParts.Chance.Visible = false
	bigParts.Info.Visible = false
	bigParts.New.Visible = false
	bigParts.Mutation.Visible = false
	bigParts.Rays.Visible = false
	bigParts.Die.Visible = true
	bigParts.Die.BackgroundColor3 = rarity.Color2
	bigParts.Die.Rotation = 0
	bigParts.Die.Text = "?"

	-- 1) Spin
	Sound.play("RollTick")
	local spinEnd = os.clock() + tierInfo.Spin
	while os.clock() < spinEnd and not skipRequested do
		bigParts.Die.Rotation += 24
		bigParts.Die.BackgroundColor3 = if math.random() < 0.5 then rarity.Color else rarity.Color2
		if tierInfo.Glitch then
			bigParts.Die.Position = UDim2.new(0.5, math.random(-8, 8), 0.42, math.random(-8, 8))
		end
		task.wait(0.05)
	end
	bigParts.Die.Visible = false
	bigParts.Die.Position = UDim2.fromScale(0.5, 0.42)

	-- 2) Flash + Reveal
	if not reduced then
		bigParts.Flash.BackgroundTransparency = 1 - tierInfo.Flash
		UI.tween(bigParts.Flash, 0.5, { BackgroundTransparency = 1 })
	end
	Sound.play("Reveal" .. rarity.RevealTier)
	shake(tierInfo.Shake, 0.8)
	zoom(tierInfo.Zoom, tierInfo.Duration)

	Viewport.set(bigParts.Viewport, def.Id, data.Mutation)
	Viewport.spin(bigParts.Viewport, 0.8)
	bigParts.Viewport.Visible = true
	bigParts.Rays.Visible = true
	for _, ray in bigParts.Rays:GetChildren() do
		ray.BackgroundColor3 = rarity.Color
	end
	bigParts.Name.Text = def.DisplayName
	bigParts.Name.TextColor3 = rarity.Color
	bigParts.Name.Visible = true
	bigParts.Rarity.Text = rarity.DisplayName
	bigParts.Rarity.TextColor3 = Color3.new(1, 1, 1)
	bigParts.RarityGradient.Color = ColorSequence.new(rarity.Color, rarity.Color2:Lerp(Color3.new(1, 1, 1), 0.3))
	bigParts.Rarity.Visible = true
	bigParts.Chance.Text = baseChanceText(def)
	bigParts.Chance.Visible = true
	local yourOdds = if data.Probability and data.Probability > 0 then Format.chance(data.Probability) else "?"
	bigParts.Info.Text = string.format("%s  ·  your odds %s (luck %s)", Format.perSecond(def.BaseMoneyPerSecond * mutation.MoneyMultiplier), yourOdds, Format.multiplier(data.Luck or 1))
	bigParts.Info.Visible = true
	bigParts.New.Visible = data.IsNew
	if mutation.Id ~= MutationConfig.None then
		bigParts.Mutation.Text = mutation.DisplayName
		bigParts.Mutation.BackgroundColor3 = mutation.Color
		bigParts.Mutation.Visible = true
	end

	-- 3) Halten (mit Effekten)
	local holdEnd = os.clock() + math.max(0.6, tierInfo.Duration - tierInfo.Spin)
	local hue = 0
	while os.clock() < holdEnd and not skipRequested do
		local dt = task.wait()
		bigParts.Rays.Rotation += dt * 25
		if tierInfo.Rainbow then
			hue = (hue + dt * 0.5) % 1
			bigParts.Name.TextColor3 = Color3.fromHSV(hue, 0.7, 1)
			bigParts.RarityGradient.Color = ColorSequence.new(Color3.fromHSV(hue, 0.8, 1), Color3.fromHSV((hue + 0.5) % 1, 0.8, 1))
		end
		if tierInfo.Glitch and math.random() < 0.15 then
			bigParts.Name.Position = UDim2.new(0.5, math.random(-10, 10), 0.66, math.random(-4, 4))
		else
			bigParts.Name.Position = UDim2.fromScale(0.5, 0.66)
		end
	end
	if not skipRequested then
		waitOrSkip(0.4)
	end
	Viewport.stopSpin(bigParts.Viewport)
	big.Visible = false
	bigParts.Name.Position = UDim2.fromScale(0.5, 0.66)
end

local function process()
	if busy then
		return
	end
	busy = true
	while #queue > 0 do
		-- bei Rückstau alte kleine Reveals überspringen
		while #queue > 2 do
			local first = queue[1]
			local def = CharacterConfig.ById[first.Id]
			if def and RarityConfig.Get(def.Rarity).RevealTier <= 2 then
				table.remove(queue, 1)
			else
				break
			end
		end
		local data = table.remove(queue, 1)
		local def = data and CharacterConfig.ById[data.Id]
		if def then
			local rarity = RarityConfig.Get(def.Rarity)
			local tierInfo = UIConfig.Reveal[rarity.RevealTier] or UIConfig.Reveal[0]
			if rarity.RevealTier >= 3 then
				showBig(data, def, tierInfo)
			else
				showSmall(data, def, tierInfo)
				task.wait(math.min(tierInfo.Duration, 0.35))
			end
		end
	end
	busy = false
end

function RevealController.init()
	local gui = Root.Layers.Reveal
	buildSmall(gui)
	buildBig(gui)
	State.on("Roll", function(data)
		table.insert(queue, data)
		task.spawn(process)
	end)
end

return RevealController
