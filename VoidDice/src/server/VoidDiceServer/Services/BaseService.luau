--!strict
-- BaseService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > BaseService
--
-- Jeder Spieler bekommt beim Join einen Plot (Base). Der Server stellt die
-- platzierten Characters dort als Models auf (für ALLE sichtbar = Social
-- Flex), dazu Billboards mit Name, Rarity, Level, Mutation, $/s, sowie die
-- fischenden Characters am Rift Pond.
--
-- Die Models sind verankert und werden vom Client nur lokal animiert
-- (Controllers > BaseAnimator). Aktualisiert wird per Diff, nicht neu gebaut.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local CharacterConfig = require(Config:WaitForChild("CharacterConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))
local MutationConfig = require(Config:WaitForChild("MutationConfig"))
local CosmeticConfig = require(Config:WaitForChild("CosmeticConfig"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local UIConfig = require(Config:WaitForChild("UIConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))
local ModelFactory = require(Shared:WaitForChild("Visual"):WaitForChild("ModelFactory"))

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))
local WorldService = require(script.Parent:WaitForChild("WorldService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local BaseService = {}

BaseService.CharacterTag = "VoidDiceCharacter"

local plotOwners: { [number]: SessionService.Session } = {}
local EMPTY_PAD = Color3.fromRGB(40, 42, 70)
local LOCKED_PAD = Color3.fromRGB(70, 20, 30)

local function plotOf(session): Model?
	return WorldService.plot(session.Plot)
end

local function setSign(plot: Model, title: string, subtitle: string)
	local board = plot:FindFirstChild("SignBoard", true)
	local gui = board and board:FindFirstChild("SignGui", true)
	if gui then
		local t = gui:FindFirstChild("Title", true)
		local s = gui:FindFirstChild("Subtitle", true)
		if t and t:IsA("TextLabel") then
			t.Text = title
		end
		if s and s:IsA("TextLabel") then
			s.Text = subtitle
		end
	end
end

-- Billboard über einem Character-Model
local function makeBillboard(model: Model): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromOffset(170, 58)
	gui.MaxDistance = 85
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	local height = (model:GetAttribute("Height") :: number?) or 6
	gui.StudsOffset = Vector3.new(0, height + 1.4, 0)
	gui.Adornee = model.PrimaryPart

	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = gui

	local function label(name: string, order: number, size: number, font: Enum.Font)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.LayoutOrder = order
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, 0, 0, size)
		l.Font = font
		l.TextScaled = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextStrokeTransparency = 0.35
		l.Text = ""
		l.Parent = gui
		return l
	end
	label("Mutation", 1, 13, UIConfig.Fonts.Body)
	label("Name", 2, 20, UIConfig.Fonts.Title)
	label("Stats", 3, 15, UIConfig.Fonts.Body)
	gui.Parent = model
	return gui
end

local function updateBillboard(model: Model, profile, char, mods)
	local gui = model:FindFirstChild("Info") :: BillboardGui?
	if not gui then
		gui = makeBillboard(model)
	end
	assert(gui)
	local def = CharacterConfig.ById[char.Id]
	local rarity = RarityConfig.Get(def.Rarity)
	local mutation = MutationConfig.Get(char.Mutation)
	local nameLabel = gui:FindFirstChild("Name") :: TextLabel
	local statsLabel = gui:FindFirstChild("Stats") :: TextLabel
	local mutLabel = gui:FindFirstChild("Mutation") :: TextLabel
	nameLabel.Text = def.DisplayName
	nameLabel.TextColor3 = rarity.Color
	if char.Fishing then
		statsLabel.Text = string.format("Lv %d · FISHING", char.Level)
	else
		local income = Logic.Economy.characterIncome(profile, char, mods)
		statsLabel.Text = string.format("Lv %d · %s", char.Level, Format.perSecond(income))
	end
	if mutation.Id ~= MutationConfig.None then
		mutLabel.Text = mutation.DisplayName
		mutLabel.TextColor3 = mutation.Color
		mutLabel.Visible = true
	else
		mutLabel.Text = rarity.DisplayName
		mutLabel.TextColor3 = rarity.Color
		mutLabel.Visible = rarity.Order >= RarityConfig.Order("Epic")
	end
end

local function buildModel(session, uid: string, char): Model?
	local ok, model = pcall(ModelFactory.Build, char.Id, { Level = char.Level, Mutation = char.Mutation })
	if not ok or not model then
		warn("[BaseService] Model konnte nicht gebaut werden:", char.Id, model)
		return nil
	end
	local def = CharacterConfig.ById[char.Id]
	model.Name = uid
	model:SetAttribute("Uid", uid)
	model:SetAttribute("CharacterId", char.Id)
	model:SetAttribute("Mutation", char.Mutation)
	model:SetAttribute("Level", char.Level)
	model:SetAttribute("OwnerUserId", session.UserId)
	model:SetAttribute("AnimationSet", def and def.AnimationSet or "Default")
	model:SetAttribute("Rarity", def and def.Rarity or "Common")
	CollectionService:AddTag(model, BaseService.CharacterTag)
	return model
end

-- Angel + Schnur an einen fischenden Character hängen
local function addFishingRod(model: Model, waterPoint: Vector3)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local armR = model:FindFirstChild("ArmR")
	local height = (model:GetAttribute("Height") :: number?) or 5
	local base = root.CFrame * CFrame.new(1.2, height * 0.55, -0.6)
	local rod = Instance.new("Part")
	rod.Name = "FishingRod"
	rod.Anchored = true
	rod.CanCollide = false
	rod.CanQuery = false
	rod.CanTouch = false
	rod.Material = Enum.Material.Metal
	rod.Color = Color3.fromRGB(60, 60, 70)
	rod.Size = Vector3.new(0.18, 0.18, 6)
	rod.CFrame = base * CFrame.Angles(math.rad(35), 0, 0) * CFrame.new(0, 0, -3)
	rod.Parent = if armR then armR else model

	local tip = Instance.new("Attachment")
	tip.Name = "RodTip"
	tip.Position = Vector3.new(0, 0, -3)
	tip.Parent = rod

	local waterAnchor = Instance.new("Part")
	waterAnchor.Name = "Bobber"
	waterAnchor.Anchored = true
	waterAnchor.CanCollide = false
	waterAnchor.CanQuery = false
	waterAnchor.CanTouch = false
	waterAnchor.Shape = Enum.PartType.Ball
	waterAnchor.Size = Vector3.new(0.6, 0.6, 0.6)
	waterAnchor.Material = Enum.Material.Neon
	waterAnchor.Color = Color3.fromRGB(255, 70, 90)
	waterAnchor.Position = waterPoint
	waterAnchor.Parent = model
	local bob = Instance.new("Attachment")
	bob.Name = "BobberAttachment"
	bob.Parent = waterAnchor

	local beam = Instance.new("Beam")
	beam.Attachment0 = tip
	beam.Attachment1 = bob
	beam.Width0 = 0.06
	beam.Width1 = 0.06
	beam.Color = ColorSequence.new(Color3.fromRGB(230, 230, 255))
	beam.FaceCamera = true
	beam.Segments = 6
	beam.CurveSize0 = -1
	beam.Parent = rod
end

local function syncFolder(session, folderName: string, wanted: { [string]: CFrame }, fishing: boolean, mods)
	local plot = plotOf(session)
	if not plot then
		return
	end
	local folder = plot:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = plot
	end
	assert(folder)
	local profile = session.Profile
	local pond = plot:FindFirstChild("PondWater", true)
	local pondCenter = if pond and pond:IsA("BasePart") then pond.Position else Vector3.zero

	-- Entfernen / ersetzen
	for _, model in folder:GetChildren() do
		local uid = model.Name
		local char = profile.Characters[uid]
		if not wanted[uid] or not char or model:GetAttribute("CharacterId") ~= char.Id or model:GetAttribute("Mutation") ~= char.Mutation then
			model:Destroy()
		end
	end
	-- Hinzufügen / aktualisieren
	for uid, cf in wanted do
		local char = profile.Characters[uid]
		local model = folder:FindFirstChild(uid) :: Model?
		if not model then
			model = buildModel(session, uid, char)
			if model then
				model:PivotTo(cf)
				if fishing then
					model:SetAttribute("Fishing", true)
					model:SetAttribute("AnimationSet", "Fishing")
					local toWater = (pondCenter - cf.Position) * Vector3.new(1, 0, 1)
					local waterPoint = cf.Position + (if toWater.Magnitude > 0 then toWater.Unit * math.min(7, toWater.Magnitude) else Vector3.zero)
					addFishingRod(model, Vector3.new(waterPoint.X, pondCenter.Y + 0.3, waterPoint.Z))
				end
				model.Parent = folder
			end
		else
			if (model:GetPivot().Position - cf.Position).Magnitude > 0.1 then
				model:PivotTo(cf)
			end
			if model:GetAttribute("Level") ~= char.Level then
				model:SetAttribute("Level", char.Level)
				pcall(ModelFactory.ApplyLevelVisual, model, char.Level)
			end
		end
		if model then
			updateBillboard(model, profile, char, mods)
		end
	end
end

local function updatePads(session, mods, bySlot)
	local plot = plotOf(session)
	local slots = plot and plot:FindFirstChild("Slots")
	if not slots then
		return
	end
	for _, pad in slots:GetChildren() do
		if pad:IsA("BasePart") then
			local index = pad:GetAttribute("SlotIndex") :: number? or tonumber(pad.Name:match("%d+")) or 0
			local rim = pad:FindFirstChild("Rim")
			local color = EMPTY_PAD
			local transparency = 0
			local uid = bySlot[index]
			if index > mods.BaseSlots then
				color = LOCKED_PAD
				transparency = 0.6
			elseif uid then
				local char = session.Profile.Characters[uid]
				local def = char and CharacterConfig.ById[char.Id]
				color = if def then RarityConfig.Get(def.Rarity).Color else EMPTY_PAD
			end
			if rim and rim:IsA("BasePart") then
				rim.Color = color
				rim.Transparency = transparency
			end
			pad:SetAttribute("Unlocked", index <= mods.BaseSlots)
			pad:SetAttribute("Uid", uid or "")
		end
	end
end

local function applyTheme(session)
	local plot = plotOf(session)
	local lights = plot and plot:FindFirstChild("Lights", true)
	if not lights then
		return
	end
	local themeId = session.Profile.Cosmetics.Equipped.BaseTheme
	local theme = CosmeticConfig.Get(themeId) or CosmeticConfig.Get(CosmeticConfig.Defaults.BaseTheme)
	local colors = theme and theme.Colors or { Color3.new(1, 1, 1) }
	local i = 0
	for _, bulb in lights:GetDescendants() do
		if bulb:IsA("BasePart") then
			i += 1
			bulb.Color = colors[(i - 1) % #colors + 1]
		end
	end
end

local function updateSign(session)
	local plot = plotOf(session)
	if not plot then
		return
	end
	local profile = session.Profile
	local value = Logic.Economy.baseValue(profile)
	setSign(plot, string.upper(session.Player.DisplayName) .. "'S BASE",
		string.format("BASE VALUE %s  ·  REBIRTH %d", Format.short(value), profile.Rebirths))
	plot:SetAttribute("BaseValue", value)
	plot:SetAttribute("Rebirths", profile.Rebirths)
	plot:SetAttribute("BestRarity", profile.Stats.BestRarity)
end

-- Anzeige über dem Collector-Pad: Inhalt des Vaults
local function updateCollector(session)
	local plot = plotOf(session)
	local collector = plot and plot:FindFirstChild("Collector", true)
	local gui = collector and collector:FindFirstChild("CollectorGui")
	if not gui then
		return
	end
	local title = gui:FindFirstChild("Title", true)
	local subtitle = gui:FindFirstChild("Subtitle", true)
	local autoCollect = Logic.Modifiers.compute(session.Profile).AutoCollect
	if title and title:IsA("TextLabel") then
		title.Text = if autoCollect then "AUTO" else Format.cash(session.Profile.Vault)
	end
	if subtitle and subtitle:IsA("TextLabel") then
		subtitle.Text = if autoCollect then "Cash goes straight to you" else "Step here to collect"
	end
end

function BaseService.refresh(session)
	if not session.Plot then
		return
	end
	local profile = session.Profile
	local mods = Logic.Modifiers.compute(profile)
	local plot = plotOf(session)
	if not plot then
		return
	end
	local slots = plot:FindFirstChild("Slots")
	local seats = plot:FindFirstChild("FishingSeats", true)

	local wantedBase: { [string]: CFrame } = {}
	local wantedFish: { [string]: CFrame } = {}
	local bySlot = {}
	for uid, char in profile.Characters do
		if char.Slot and slots then
			local pad = slots:FindFirstChild("Slot" .. char.Slot)
			if pad and pad:IsA("BasePart") then
				wantedBase[uid] = pad.CFrame * CFrame.new(0, pad.Size.Y / 2, 0)
				bySlot[char.Slot] = uid
			end
		elseif char.Fishing and seats then
			local seat = seats:FindFirstChild("Seat" .. char.Fishing)
			if seat and seat:IsA("BasePart") then
				wantedFish[uid] = seat.CFrame * CFrame.new(0, seat.Size.Y / 2, 0)
			end
		end
	end
	syncFolder(session, "Characters", wantedBase, false, mods)
	syncFolder(session, "Fishers", wantedFish, true, mods)
	updatePads(session, mods, bySlot)
	updateSign(session)
end

local function assignPlot(session)
	for index = 1, WorldService.plotCount() do
		if not plotOwners[index] then
			plotOwners[index] = session
			session.Plot = index
			local plot = WorldService.plot(index) :: Model
			plot:SetAttribute("OwnerUserId", session.UserId)
			plot:SetAttribute("OwnerName", session.Player.DisplayName)
			return index
		end
	end
	warn("[BaseService] Kein freier Plot! MaxPlayers in den Place-Einstellungen auf", GameConfig.MaxPlayers, "setzen.")
	return nil
end

local function clearPlot(index: number)
	local plot = WorldService.plot(index)
	if not plot then
		return
	end
	for _, folderName in { "Characters", "Fishers" } do
		local folder = plot:FindFirstChild(folderName)
		if folder then
			folder:ClearAllChildren()
		end
	end
	plot:SetAttribute("OwnerUserId", nil)
	plot:SetAttribute("OwnerName", nil)
	plot:SetAttribute("BaseValue", nil)
	setSign(plot, "EMPTY BASE", "Waiting for an investigator…")
	local slots = plot:FindFirstChild("Slots")
	if slots then
		for _, pad in slots:GetChildren() do
			local rim = pad:FindFirstChild("Rim")
			if rim and rim:IsA("BasePart") then
				rim.Color = EMPTY_PAD
				rim.Transparency = 0
			end
		end
	end
end

local function spawnAtBase(session, character: Model)
	task.defer(function()
		local cf = WorldService.plotSpawn(session.Plot)
		if cf and character.Parent then
			character:PivotTo(cf + Vector3.new(0, 3, 0))
		end
	end)
end

-- Für den "Inspect"-Dialog anderer Bases
function BaseService.summary(plotIndex: number)
	local session = plotOwners[plotIndex]
	if not session then
		return nil
	end
	local profile = session.Profile
	local chars = {}
	for uid, char in profile.Characters do
		if char.Slot then
			table.insert(chars, { Id = char.Id, Level = char.Level, Mutation = char.Mutation, Slot = char.Slot })
		end
	end
	return {
		Plot = plotIndex,
		Player = session.Player.DisplayName,
		UserId = session.UserId,
		Rebirths = profile.Rebirths,
		BaseValue = Logic.Economy.baseValue(profile),
		Income = Logic.Economy.incomePerSecond(profile, Logic.Modifiers.compute(profile)),
		Discovered = profile.Stats.CharactersDiscovered,
		BestRarity = profile.Stats.BestRarity,
		TotalRolls = profile.Stats.TotalRolls,
		Title = profile.Cosmetics.Equipped.Title,
		Characters = chars,
	}
end

function BaseService.Start()
	for index = 1, WorldService.plotCount() do
		clearPlot(index)
		local plot = WorldService.plot(index) :: Model
		local collector = plot:FindFirstChild("Collector", true)
		if collector and collector:IsA("BasePart") then
			local debounce: { [Player]: number } = {}
			collector.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				local player = character and Players:GetPlayerFromCharacter(character)
				if not player then
					return
				end
				local session = SessionService.get(player)
				if not session or session.Plot ~= index then
					return
				end
				local now = os.clock()
				if (debounce[player] or 0) > now then
					return
				end
				debounce[player] = now + 1
				EconomyService.collect(session)
			end)
		end
	end

	SessionService.onLoaded(function(session)
		assignPlot(session)
		BaseService.refresh(session)
		applyTheme(session)
		local player = session.Player
		player.CharacterAdded:Connect(function(character)
			spawnAtBase(session, character)
		end)
		if player.Character then
			spawnAtBase(session, player.Character)
		end
	end)

	SessionService.onRemoving(function(session)
		if session.Plot then
			plotOwners[session.Plot] = nil
			clearPlot(session.Plot)
		end
	end)

	SessionService.onFlush(function(session, ctx)
		local dirty = ctx.dirty
		if dirty.Base or dirty.Fishers or dirty.Rebirths or dirty.Derived or next(ctx.dirtyChars) then
			BaseService.refresh(session)
		end
		if dirty.Cosmetics then
			applyTheme(session)
		end
		if dirty.Vault or dirty.Derived or dirty.Rebirths then
			updateCollector(session)
		end
	end)

	SessionService.registerAction("InspectBase", function(session, _ctx, plotIndex: number)
		local summary = BaseService.summary(math.floor(plotIndex))
		if not summary then
			return false, "Nobody lives here (yet)"
		end
		SessionService.fire(session, "InspectBase", summary)
		return true
	end)

	-- Billboards gelegentlich auffrischen ($/s ändert sich durch Potions)
	task.spawn(function()
		while true do
			task.wait(5)
			for _, session in SessionService.all() do
				if not session.Removing then
					pcall(BaseService.refresh, session)
				end
			end
		end
	end)
end

return BaseService
