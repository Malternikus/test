-- SpeedEffects (ModuleScript)
-- Ort: StarterPlayerScripts > GliderClient > SpeedEffects
--
-- Kleine Wind-Partikel, die vor der Kamera entstehen und in der Welt stehen
-- bleiben. Weil man mit hohem Tempo hindurchfliegt, ziehen sie vorbei und
-- verstärken das Geschwindigkeitsgefühl. Nur lokal, ein einziger Emitter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))
local F = Config.Flight
local FX = Config.Effects

local SpeedEffects = {}
SpeedEffects.__index = SpeedEffects

function SpeedEffects.new()
	local self = setmetatable({}, SpeedEffects)
	self.enabled = FX.SpeedParticlesEnabled
	if not self.enabled then
		return self
	end

	local part = Instance.new("Part")
	part.Name = "GliderWindEmitter"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(50, 30, 10)
	part.Parent = workspace.CurrentCamera -- wird nicht repliziert

	local emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Speed = NumberRange.new(0)
	emitter.Lifetime = NumberRange.new(0.9, 1.3)
	emitter.Size = NumberSequence.new(0.12)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 1
	emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
	emitter.Rate = 0
	emitter.Parent = part

	self.part = part
	self.emitter = emitter
	self._lastRate = 0
	return self
end

function SpeedEffects:Update(speed: number, active: boolean)
	if not self.enabled then
		return
	end
	local camera = workspace.CurrentCamera
	self.part.CFrame = camera.CFrame * CFrame.new(0, 0, -70)

	local rate = 0
	if active then
		local fraction = math.clamp((speed - F.MinSpeed) / (F.MaxSpeed - F.MinSpeed), 0, 1)
		rate = math.floor(FX.SpeedParticlesMaxRate * (0.3 + 0.7 * fraction))
	end
	if rate ~= self._lastRate then
		self._lastRate = rate
		self.emitter.Rate = rate
	end
end

function SpeedEffects:Destroy()
	if self.part then
		self.part:Destroy()
	end
end

return SpeedEffects
