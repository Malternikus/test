--!strict
-- AvatarService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > AvatarService
--
-- Overhead-Schild über dem Spieler (Titel, Name, VIP, Rebirth) sowie
-- Aura und Trail aus den ausgerüsteten Cosmetics. Für alle sichtbar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local CosmeticConfig = require(Config:WaitForChild("CosmeticConfig"))
local UIConfig = require(Config:WaitForChild("UIConfig"))

local SessionService = require(script.Parent:WaitForChild("SessionService"))

local AvatarService = {}

local function clearOld(character: Model)
	for _, name in { "VD_Nameplate", "VD_Aura", "VD_Trail", "VD_TrailA0", "VD_TrailA1" } do
		local existing = character:FindFirstChild(name, true)
		while existing do
			existing:Destroy()
			existing = character:FindFirstChild(name, true)
		end
	end
end

function AvatarService.apply(session)
	local character = session.Player.Character
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not head or not root then
		return
	end
	clearOld(character)
	local profile = session.Profile
	local equipped = profile.Cosmetics.Equipped

	-- Nameplate -------------------------------------------------------------------
	local title = CosmeticConfig.Get(equipped.Title or "")
	local plate = CosmeticConfig.Get(equipped.Nameplate or "") or CosmeticConfig.Get(CosmeticConfig.Defaults.Nameplate)
	local gui = Instance.new("BillboardGui")
	gui.Name = "VD_Nameplate"
	gui.Size = UDim2.fromOffset(200, 54)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 110
	gui.LightInfluence = 0
	gui.Adornee = head :: BasePart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = if plate and plate.Color then plate.Color else UIConfig.Colors.Panel
	frame.BackgroundTransparency = 0.25
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = if plate and plate.Color2 then plate.Color2 else UIConfig.Colors.Purple
	stroke.Thickness = 2
	stroke.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, -10, 0.42, 0)
	titleLabel.Position = UDim2.fromOffset(5, 3)
	titleLabel.Font = UIConfig.Fonts.Body
	titleLabel.TextScaled = true
	titleLabel.Text = if title and title.Text then title.Text else ""
	titleLabel.TextColor3 = if title and title.Color then title.Color else UIConfig.Colors.SubText
	titleLabel.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, -10, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 5, 0.45, 0)
	nameLabel.Font = UIConfig.Fonts.Title
	nameLabel.TextScaled = true
	local vip = if profile.Passes.VIP then "★ " else ""
	nameLabel.Text = string.format("%s%s  ·  R%d", vip, session.Player.DisplayName, profile.Rebirths)
	nameLabel.TextColor3 = UIConfig.Colors.Text
	nameLabel.Parent = frame
	gui.Parent = head

	-- Aura -------------------------------------------------------------------------
	local aura = CosmeticConfig.Get(equipped.Aura or "")
	if aura and aura.Color then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "VD_Aura"
		emitter.Color = ColorSequence.new(aura.Color)
		emitter.LightEmission = 0.8
		emitter.Rate = 8
		emitter.Lifetime = NumberRange.new(0.8, 1.4)
		emitter.Speed = NumberRange.new(0.5, 1.5)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Parent = root
	end

	-- Trail ------------------------------------------------------------------------
	local trailDef = CosmeticConfig.Get(equipped.Trail or "")
	if trailDef and trailDef.Color then
		local a0 = Instance.new("Attachment")
		a0.Name = "VD_TrailA0"
		a0.Position = Vector3.new(0, 0.8, 0)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Name = "VD_TrailA1"
		a1.Position = Vector3.new(0, -0.8, 0)
		a1.Parent = root
		local trail = Instance.new("Trail")
		trail.Name = "VD_Trail"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.5
		trail.LightEmission = 0.7
		trail.Color = ColorSequence.new(trailDef.Color, trailDef.Color2 or trailDef.Color)
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Parent = root
	end
end

function AvatarService.Start()
	SessionService.onLoaded(function(session)
		session.Player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 5)
			character:WaitForChild("HumanoidRootPart", 5)
			AvatarService.apply(session)
		end)
		AvatarService.apply(session)
	end)
	SessionService.onFlush(function(session, ctx)
		if ctx.dirty.Cosmetics or ctx.dirty.Rebirths or ctx.dirty.Passes then
			AvatarService.apply(session)
		end
	end)
end

return AvatarService
