-- FlightController (ModuleScript)
-- Ort: StarterPlayerScripts > GliderClient > FlightController
--
-- Arcade-Flugmodell. Keine Aerodynamik, sondern ein paar weich geglättete Werte:
--
--   Eingabe (-1..1)  --geglättet-->  steer / climb
--   steer  -> Drehrate (Yaw) + Schräglage (Bank, nur Optik)
--   climb  -> Nick-Winkel (Pitch) -> Flugrichtung hoch/runter + Tempo-Änderung
--   Flugrichtung * Tempo  --geglättet-->  Geschwindigkeit (leichte Trägheit)
--
-- Umgesetzt wird das mit zwei Physik-Constraints am HumanoidRootPart:
--   LinearVelocity    -> setzt die Geschwindigkeit
--   AlignOrientation  -> setzt die Ausrichtung (inkl. Neigung)
-- Pro Frame werden nur deren Zielwerte geändert, das ist sehr günstig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))
local F = Config.Flight

local FlightController = {}
FlightController.__index = FlightController

-- Bildraten-unabhängige Glättung: Anteil, um den man sich dem Ziel nähert
local function smoothAlpha(response: number, dt: number): number
	return 1 - math.exp(-response * dt)
end

local DISABLED_STATES = {
	Enum.HumanoidStateType.Jumping,
	Enum.HumanoidStateType.Freefall,
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.GettingUp,
	Enum.HumanoidStateType.Climbing,
	Enum.HumanoidStateType.Swimming,
	Enum.HumanoidStateType.Seated,
}

function FlightController.new(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	local self = setmetatable({}, FlightController)
	self.character = character
	self.humanoid = humanoid
	self.root = root

	self.active = false
	self.throttle = 1 -- 1 = normal, 0 = bremst bis zum Stillstand (Ziel)
	self.yaw = 0 -- Kurs in Radiant (positiv = links)
	self.pitch = 0 -- tatsächlicher Flugwinkel
	self.bank = 0 -- sichtbare Schräglage
	self.steer = 0 -- geglättete Eingabe links/rechts
	self.climb = 0 -- geglättete Eingabe hoch/runter
	self.speed = F.BaseSpeed
	self.velocity = Vector3.zero

	-- Humanoid ruhigstellen: kein Laufen, Springen, Fallen
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	for _, state in DISABLED_STATES do
		humanoid:SetStateEnabled(state, false)
	end

	-- Standard-Animationen stoppen (Charakter soll ruhig am Gleiter hängen)
	local animate = character:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end

	-- Keine physikalische Kollision mit der Map (Crash-Erkennung übernimmt das)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			pcall(function()
				part.CollisionGroup = Config.Names.CollisionGroup
			end)
		end
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "FlightAttachment"
	attachment.Parent = root

	local linear = Instance.new("LinearVelocity")
	linear.Name = "FlightVelocity"
	linear.Attachment0 = attachment
	linear.RelativeTo = Enum.ActuatorRelativeTo.World
	linear.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linear.MaxForce = math.huge
	linear.VectorVelocity = Vector3.zero
	linear.Parent = root

	local align = Instance.new("AlignOrientation")
	align.Name = "FlightOrientation"
	align.Attachment0 = attachment
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.RigidityEnabled = true
	align.CFrame = root.CFrame.Rotation
	align.Parent = root

	self.attachment = attachment
	self.linear = linear
	self.align = align
	return self
end

function FlightController:IsValid(): boolean
	return self.root.Parent ~= nil and self.character.Parent ~= nil
end

-- Setzt den Gleiter an eine Position (Start / Checkpoint) und stoppt ihn.
function FlightController:Reset(cf: CFrame)
	local look = cf.LookVector
	self.yaw = math.atan2(-look.X, -look.Z)
	self.pitch = 0
	self.bank = 0
	self.steer = 0
	self.climb = 0
	self.speed = F.BaseSpeed
	self.velocity = Vector3.zero
	self.throttle = 1
	self.active = false

	local rotation = CFrame.Angles(0, self.yaw, 0)
	local target = CFrame.new(cf.Position) * rotation
	self.character:PivotTo(target)
	self.root.AssemblyLinearVelocity = Vector3.zero
	self.root.AssemblyAngularVelocity = Vector3.zero
	self.linear.VectorVelocity = Vector3.zero
	self.align.CFrame = rotation
end

-- true = fliegt los, false = sofort anhalten und schweben (Crash, Countdown)
function FlightController:SetActive(active: boolean)
	self.active = active
	if active then
		-- Mit etwas Schwung starten, statt aus dem Stand
		self.velocity = self:GetFlightCFrame().LookVector * (F.BaseSpeed * 0.5)
	else
		self.velocity = Vector3.zero
		self.linear.VectorVelocity = Vector3.zero
	end
end

-- Sanft bis zum Stillstand abbremsen (nach dem Ziel)
function FlightController:Brake()
	self.throttle = 0
end

function FlightController:GetFlightCFrame(): CFrame
	return CFrame.Angles(0, self.yaw, 0) * CFrame.Angles(self.pitch, 0, 0)
end

function FlightController:GetPosition(): Vector3
	return self.root.Position
end

function FlightController:GetRootCFrame(): CFrame
	return self.root.CFrame
end

function FlightController:GetVelocity(): Vector3
	return self.velocity
end

function FlightController:GetSpeed(): number
	return self.velocity.Magnitude
end

function FlightController:Update(dt: number, input: Vector2)
	if not self.active then
		self.linear.VectorVelocity = Vector3.zero
		return
	end

	-- 1) Eingabe glätten -> weiche, aber direkte Reaktion
	self.steer += (input.X - self.steer) * smoothAlpha(F.SteerResponse, dt)
	self.climb += (input.Y - self.climb) * smoothAlpha(F.PitchResponse, dt)

	-- 2) Kurs ändern (rechts lenken = Yaw nach rechts = negativer Winkel)
	self.yaw -= self.steer * math.rad(F.MaxYawRate) * dt

	-- 3) Nick- und Schräglage
	local targetPitch = self.climb * math.rad(F.MaxPitchAngle)
	self.pitch += (targetPitch - self.pitch) * smoothAlpha(F.PitchVisualResponse, dt)
	local targetBank = -self.steer * math.rad(F.MaxBankAngle)
	self.bank += (targetBank - self.bank) * smoothAlpha(F.BankResponse, dt)

	-- 4) Tempo: im Sturzflug schneller, beim Steigen langsamer
	local pitchFraction = self.pitch / math.rad(F.MaxPitchAngle)
	local targetSpeed = F.BaseSpeed
	if pitchFraction < 0 then
		targetSpeed += -pitchFraction * F.DiveSpeedBonus
	else
		targetSpeed -= pitchFraction * F.ClimbSpeedPenalty
	end
	targetSpeed = math.clamp(targetSpeed, F.MinSpeed, F.MaxSpeed) * self.throttle
	local speedResponse = self.throttle > 0 and F.SpeedResponse or (3 / F.FinishBrakeTime)
	self.speed += (targetSpeed - self.speed) * smoothAlpha(speedResponse, dt)

	-- 5) Geschwindigkeit folgt der Flugrichtung mit leichter Trägheit
	local flight = self:GetFlightCFrame()
	local desired = flight.LookVector * self.speed - Vector3.new(0, F.SinkRate * self.throttle, 0)
	self.velocity = self.velocity:Lerp(desired, smoothAlpha(F.VelocityResponse, dt))
	self.linear.VectorVelocity = self.velocity

	-- 6) Sichtbare Ausrichtung: Kurs + abgeschwächtes Nicken + Schräglage
	self.align.CFrame = CFrame.Angles(0, self.yaw, 0)
		* CFrame.Angles(self.pitch * F.VisualPitchFactor, 0, 0)
		* CFrame.Angles(0, 0, self.bank)
end

function FlightController:GetBank(): number
	return self.bank
end

function FlightController:GetYaw(): number
	return self.yaw
end

function FlightController:GetPitch(): number
	return self.pitch
end

function FlightController:Destroy()
	self.active = false
	self.linear:Destroy()
	self.align:Destroy()
	self.attachment:Destroy()
end

return FlightController
