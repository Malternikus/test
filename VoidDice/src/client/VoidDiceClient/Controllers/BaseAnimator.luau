--!strict
-- BaseAnimator (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > BaseAnimator
--
-- Lässt die Characters in allen Bases leben, NUR lokal auf dem Client:
-- Walkie-Talkie benutzen, Taschenlampe schwenken, umsehen, schweben,
-- Psychic-Hover, Flügel schlagen, Orbits drehen, Fishing inkl. Fang-Ruck.
--
-- Technik: Die Models sind verankert. Pro Model werden die Teile einmal
-- relativ zur Ruhepose gecacht (Gruppen Head/ArmL/ArmR/WingL/WingR/Tail/
-- Orbit/Core mit "Joint" als Drehpunkt, siehe ModelFactory). Pro Frame wird
-- dann per workspace:BulkMoveTo bewegt (schnell, keine Physik).
--
-- Performance: nur Models innerhalb UIConfig.AnimateDistance, höchstens
-- UIConfig.MaxAnimatedModels, ~30 Updates/s. Weit entfernte Models schalten
-- ihre Partikel/Lichter lokal ab (LOD).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIConfig = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config"):WaitForChild("UIConfig"))

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))

local BaseAnimator = {}

local TAG = "VoidDiceCharacter"
local GROUPS = { Head = true, ArmL = true, ArmR = true, WingL = true, WingR = true, Tail = true, Orbit = true, Core = true }
local UPDATE_INTERVAL = 1 / 30
local EFFECT_LOD_DISTANCE = 170

local FISHING_SET = { Bob = 0.03, BobSpeed = 1.2, HeadTurn = 12, ArmSwing = 2, ArmRaise = 45 }

type Group = { jointRel: CFrame, parts: { BasePart }, rel: { CFrame } }
type Entry = {
	model: Model,
	root: BasePart,
	base: CFrame,
	bodyParts: { BasePart },
	bodyRel: { CFrame },
	groups: { [string]: Group },
	allParts: { BasePart },
	restCFrames: { CFrame },
	set: { [string]: any },
	phase: number,
	dirty: boolean,
	effects: { Instance },
	effectsOn: boolean,
	jerkUntil: number,
	connections: { RBXScriptConnection },
}

local entries: { [Model]: Entry } = {}

local function groupOf(model: Model, part: BasePart): Model?
	local node: Instance? = part.Parent
	while node and node ~= model do
		if node:IsA("Model") and GROUPS[node.Name] then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function restore(entry: Entry)
	if #entry.allParts > 0 then
		workspace:BulkMoveTo(entry.allParts, entry.restCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function cache(entry: Entry)
	local model = entry.model
	local root = entry.root
	entry.base = root.CFrame
	entry.bodyParts, entry.bodyRel = {}, {}
	entry.groups = {}
	entry.allParts, entry.restCFrames = {}, {}
	entry.effects = {}
	local inverseBase = entry.base:Inverse()
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") and inst ~= root then
			table.insert(entry.allParts, inst)
			table.insert(entry.restCFrames, inst.CFrame)
			local group = groupOf(model, inst)
			if group and group.PrimaryPart then
				local g = entry.groups[group.Name]
				if not g then
					g = { jointRel = inverseBase * group.PrimaryPart.CFrame, parts = {}, rel = {} }
					entry.groups[group.Name] = g
				end
				table.insert(g.parts, inst)
				table.insert(g.rel, group.PrimaryPart.CFrame:Inverse() * inst.CFrame)
			else
				table.insert(entry.bodyParts, inst)
				table.insert(entry.bodyRel, inverseBase * inst.CFrame)
			end
		elseif inst:IsA("ParticleEmitter") or inst:IsA("Light") or inst:IsA("Beam") then
			table.insert(entry.effects, inst)
		end
	end
	local setName = model:GetAttribute("AnimationSet") :: string?
	if model:GetAttribute("Fishing") then
		entry.set = FISHING_SET
	else
		entry.set = UIConfig.AnimationSets[setName or "Default"] or UIConfig.AnimationSets.Default
	end
	entry.dirty = false
end

local function register(model: Instance)
	if not model:IsA("Model") or entries[model] then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if not root or not root:IsA("BasePart") then
		-- Streaming: Root kommt evtl. später
		task.delay(1, function()
			if model.Parent and CollectionService:HasTag(model, TAG) then
				register(model)
			end
		end)
		return
	end
	local entry: Entry = {
		model = model,
		root = root,
		base = root.CFrame,
		bodyParts = {},
		bodyRel = {},
		groups = {},
		allParts = {},
		restCFrames = {},
		set = UIConfig.AnimationSets.Default,
		phase = math.random() * 10,
		dirty = true,
		effects = {},
		effectsOn = true,
		jerkUntil = 0,
		connections = {},
	}
	entries[model] = entry
	table.insert(entry.connections, model.DescendantAdded:Connect(function(inst)
		if inst:IsA("BasePart") or inst:IsA("ParticleEmitter") or inst:IsA("Light") then
			entry.dirty = true
		end
	end))
	table.insert(entry.connections, root:GetPropertyChangedSignal("CFrame"):Connect(function()
		entry.dirty = true
	end))
	table.insert(entry.connections, model:GetAttributeChangedSignal("AnimationSet"):Connect(function()
		entry.dirty = true
	end))
end

local function unregister(model: Instance)
	local entry = entries[model :: Model]
	if entry then
		for _, c in entry.connections do
			c:Disconnect()
		end
		entries[model :: Model] = nil
	end
end

local function setEffects(entry: Entry, on: boolean)
	if entry.effectsOn == on then
		return
	end
	entry.effectsOn = on
	for _, effect in entry.effects do
		if effect.Parent then
			if on then
				local was = effect:GetAttribute("VD_WasEnabled")
				if was ~= nil then
					(effect :: any).Enabled = was
				end
			else
				effect:SetAttribute("VD_WasEnabled", (effect :: any).Enabled)
				;(effect :: any).Enabled = false
			end
		end
	end
end

local partsBuffer: { BasePart } = {}
local cfBuffer: { CFrame } = {}

local function animate(entry: Entry, t: number)
	local set = entry.set
	local tt = t + entry.phase
	local bobSpeed = set.BobSpeed or 1.5
	local bob = (set.Bob or 0) * math.sin(tt * bobSpeed * 2)
	local hover = set.Hover or 0
	local yaw = 0
	if set.Spin then
		yaw = math.rad(set.Spin) * tt
	elseif set.Sway then
		yaw = math.rad(set.Sway) * math.sin(tt * 0.8)
	end
	local jitter = Vector3.zero
	if set.Jitter and math.random() < 0.3 then
		jitter = Vector3.new((math.random() - 0.5) * set.Jitter, 0, (math.random() - 0.5) * set.Jitter)
	end
	local sitDrop = if set.Sit then -0.5 else 0
	local modelCF = entry.base * CFrame.new(jitter.X, hover + bob + sitDrop, jitter.Z) * CFrame.Angles(0, yaw, 0)

	local n = 0
	for i, part in entry.bodyParts do
		n += 1
		partsBuffer[n] = part
		cfBuffer[n] = modelCF * entry.bodyRel[i]
	end

	local swing = math.rad(set.ArmSwing or 0) * math.sin(tt * bobSpeed * 2)
	local raise = math.rad(set.ArmRaise or 0)
	local jerk = if os.clock() < entry.jerkUntil then math.rad(40) else 0
	for name, g in entry.groups do
		local rot: CFrame
		if name == "Head" then
			local turn = math.rad(set.HeadTurn or 0) * math.sin(tt * 0.7)
			local tilt = math.rad(set.HeadTilt or 0) * math.sin(tt * 0.5)
			if set.Talk then
				tilt += math.rad(6) * math.sin(tt * 9)
			end
			rot = CFrame.Angles(tilt, turn, 0)
		elseif name == "ArmR" then
			local sweep = math.rad(set.Sweep or 0) * math.sin(tt * 0.9)
			rot = CFrame.Angles(raise + swing + jerk, sweep, 0)
		elseif name == "ArmL" then
			local leftRaise = if set.BothArms then raise else 0
			rot = CFrame.Angles(leftRaise - swing, 0, 0)
		elseif name == "WingL" then
			rot = CFrame.Angles(0, 0, math.rad(set.WingFlap or 25) * math.sin(tt * 8))
		elseif name == "WingR" then
			rot = CFrame.Angles(0, 0, -math.rad(set.WingFlap or 25) * math.sin(tt * 8))
		elseif name == "Tail" then
			rot = CFrame.Angles(0, math.rad(20) * math.sin(tt * 1.6), 0)
		elseif name == "Orbit" then
			rot = CFrame.Angles(0, tt * 1.2, 0)
		elseif name == "Core" then
			rot = CFrame.new(0, 0.15 * math.sin(tt * 2.2), 0) * CFrame.Angles(0, tt * 0.6, 0)
		else
			rot = CFrame.identity
		end
		local joint = modelCF * g.jointRel * rot
		for i, part in g.parts do
			n += 1
			partsBuffer[n] = part
			cfBuffer[n] = joint * g.rel[i]
		end
	end
	for i = #partsBuffer, n + 1, -1 do
		partsBuffer[i] = nil
		cfBuffer[i] = nil
	end
	if n > 0 then
		workspace:BulkMoveTo(partsBuffer, cfBuffer, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function splash(position: Vector3, color: Color3)
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	local TweenService = game:GetService("TweenService")
	TweenService:Create(ring, TweenInfo.new(0.6), { Size = Vector3.new(0.2, 6, 6), Transparency = 1 }):Play()
	task.delay(0.7, function()
		ring:Destroy()
	end)
end

function BaseAnimator.init()
	for _, model in CollectionService:GetTagged(TAG) do
		register(model)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(register)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(unregister)

	-- Fang-Animation am eigenen Pond
	State.on("Catch", function(data)
		for model, entry in entries do
			if model.Name == data.Uid and model:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId then
				entry.jerkUntil = os.clock() + 0.45
				local bobber = model:FindFirstChild("Bobber")
				if bobber and bobber:IsA("BasePart") then
					splash(bobber.Position, Color3.fromRGB(140, 120, 255))
				end
			end
		end
	end)

	local accumulator = 0
	local candidates: { { entry: Entry, distance: number } } = {}
	RunService.RenderStepped:Connect(function(dt)
		accumulator += dt
		if accumulator < UPDATE_INTERVAL then
			return
		end
		accumulator = 0
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local camPos = camera.CFrame.Position
		table.clear(candidates)
		for model, entry in entries do
			if not model.Parent then
				continue
			end
			if entry.dirty then
				restore(entry)
				cache(entry)
			end
			local distance = (entry.base.Position - camPos).Magnitude
			setEffects(entry, distance < EFFECT_LOD_DISTANCE)
			if distance < UIConfig.AnimateDistance then
				table.insert(candidates, { entry = entry, distance = distance })
			end
		end
		table.sort(candidates, function(a, b)
			return a.distance < b.distance
		end)
		local t = os.clock()
		local reduced = State.data.Settings and State.data.Settings.ReducedEffects
		local limit = if reduced then math.floor(UIConfig.MaxAnimatedModels / 2) else UIConfig.MaxAnimatedModels
		for i = 1, math.min(#candidates, limit) do
			animate(candidates[i].entry, t)
		end
	end)
end

return BaseAnimator
