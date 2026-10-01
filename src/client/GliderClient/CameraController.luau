-- CameraController (ModuleScript)
-- Ort: StarterPlayerScripts > GliderClient > CameraController
--
-- Verfolgerkamera hinter dem Gleiter.
--  * Die Kamera folgt der Position exakt (kein "Zurückfallen" bei Tempo),
--    aber ihre Ausrichtung (Kurs, Nicken, Rollen) folgt leicht verzögert.
--    Dadurch schwingt sie in Kurven weich mit, ohne zu wackeln.
--  * Höheres Tempo -> etwas mehr Abstand + größeres FOV.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))
local CAM = Config.Camera
local F = Config.Flight

local RENDER_NAME = "GliderCamera"

local CameraController = {}
CameraController.__index = CameraController

local function smoothAlpha(response: number, dt: number): number
	return 1 - math.exp(-response * dt)
end

function CameraController.new()
	local self = setmetatable({}, CameraController)
	self.camera = workspace.CurrentCamera
	self.target = nil :: any -- FlightController
	self.yaw = 0
	self.pitch = 0
	self.roll = 0
	self.speedFraction = 0
	self.fov = CAM.BaseFOV
	self.shakeTime = 0
	self.shakeStrength = 0
	self.shakeDuration = 1
	self.rng = Random.new()

	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		self:_update(dt)
	end)
	return self
end

function CameraController:SetTarget(flight)
	self.target = flight
	self:Snap()
end

-- Glättung zurücksetzen (z.B. nach Respawn), damit die Kamera nicht "rüberschwenkt"
function CameraController:Snap()
	local flight = self.target
	if not flight then
		return
	end
	self.yaw = flight:GetYaw()
	self.pitch = flight:GetPitch()
	self.roll = flight:GetBank()
	self.speedFraction = 0
end

function CameraController:Shake(strength: number?, duration: number?)
	self.shakeStrength = strength or CAM.CrashShakeStrength
	self.shakeTime = duration or CAM.CrashShakeDuration
	self.shakeDuration = self.shakeTime
end

function CameraController:_update(dt: number)
	local flight = self.target
	if not flight or not flight:IsValid() then
		return
	end
	local camera = workspace.CurrentCamera
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- Verzögert nachgeführte Ausrichtung
	local rotAlpha = smoothAlpha(CAM.RotationResponse, dt)
	self.yaw += (flight:GetYaw() - self.yaw) * rotAlpha
	self.pitch += (flight:GetPitch() * CAM.PitchFactor - self.pitch) * rotAlpha
	self.roll += (flight:GetBank() * CAM.RollFactor - self.roll) * rotAlpha

	local speedFraction = math.clamp((flight:GetSpeed() - F.BaseSpeed) / (F.MaxSpeed - F.BaseSpeed), 0, 1)
	self.speedFraction += (speedFraction - self.speedFraction) * smoothAlpha(CAM.FOVResponse, dt)

	local basis = CFrame.Angles(0, self.yaw, 0) * CFrame.Angles(self.pitch, 0, 0)
	local targetPos = flight:GetPosition() + Vector3.new(0, 2, 0)
	local distance = CAM.Distance + CAM.ExtraDistanceAtMaxSpeed * self.speedFraction
	local camPos = targetPos + basis:VectorToWorldSpace(Vector3.new(0, CAM.Height, distance))
	local lookAt = targetPos + basis.LookVector * CAM.LookAhead

	local cf = CFrame.lookAt(camPos, lookAt) * CFrame.Angles(0, 0, self.roll)

	-- Kurzes Wackeln beim Crash
	if self.shakeTime > 0 then
		self.shakeTime -= dt
		local k = math.max(self.shakeTime, 0) / (self.shakeDuration or 1)
		local s = math.rad(self.shakeStrength * 4) * k
		cf *= CFrame.Angles(self.rng:NextNumber(-s, s), self.rng:NextNumber(-s, s), self.rng:NextNumber(-s, s) * 0.5)
	end

	camera.CFrame = cf

	-- FOV leicht erhöhen bei hohem Tempo
	local targetFov = CAM.BaseFOV + CAM.MaxFOVBoost * self.speedFraction
	self.fov += (targetFov - self.fov) * smoothAlpha(CAM.FOVResponse, dt)
	camera.FieldOfView = self.fov
end

function CameraController:Destroy()
	RunService:UnbindFromRenderStep(RENDER_NAME)
end

return CameraController
