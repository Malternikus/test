-- RunManager (ModuleScript)
-- Ort: StarterPlayerScripts > GliderClient > RunManager
--
-- Steuert den Ablauf eines Runs als einfache Zustandsmaschine:
--
--   Countdown -> Flying -> (Crash -> Respawning -> Flying)* -> Finished
--
-- Hier läuft die EINZIGE Frame-Schleife der Spiellogik (PreSimulation, also
-- direkt vor dem Physik-Schritt). Kamera und UI hängen sich daran.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))
local FlightController = require(script.Parent.FlightController)
local CheckpointSystem = require(script.Parent.CheckpointSystem)
local CrashSystem = require(script.Parent.CrashSystem)
local HUD = require(script.Parent.HUD)

local GREEN = Color3.fromRGB(90, 255, 130)
local RED = Color3.fromRGB(255, 70, 60)
local YELLOW = Color3.fromRGB(255, 220, 80)

-- Zustände, in denen die Zeit läuft (Crash zählt als Zeitstrafe mit)
local TIMER_STATES = { Flying = true, Crashed = true, Respawning = true }

local RunManager = {}
RunManager.__index = RunManager

export type Deps = {
	map: Model,
	trackData: Folder,
	hud: any,
	input: any,
	camera: any,
	effects: any,
}

function RunManager.new(deps: Deps)
	local self = setmetatable({}, RunManager)
	self.hud = deps.hud
	self.input = deps.input
	self.camera = deps.camera
	self.effects = deps.effects
	self.checkpoints = CheckpointSystem.new(deps.trackData, deps.map)
	self.crash = CrashSystem.new(deps.map)

	self.state = "Idle" :: string
	self.token = 0 -- wird bei jedem Neustart erhöht; alte verzögerte Aufrufe verfallen
	self.time = 0
	self.best = nil :: number?
	self.flight = nil :: any
	self.prevPos = Vector3.zero

	self._connection = RunService.PreSimulation:Connect(function(dt)
		self:_step(dt)
	end)
	return self
end

-------------------------------------------------------------------------------
-- Charakter
-------------------------------------------------------------------------------

function RunManager:AttachCharacter(character: Model)
	self:DetachCharacter()
	local flight = FlightController.new(character)
	self.flight = flight
	self.crash:SetCharacter(character)
	self.camera:SetTarget(flight)
	self:StartRun()
end

function RunManager:DetachCharacter()
	self.token += 1
	self.state = "Idle" :: string
	if self.flight then
		self.flight:Destroy()
		self.flight = nil
	end
end

-------------------------------------------------------------------------------
-- Ablauf
-------------------------------------------------------------------------------

function RunManager:_placeAt(cf: CFrame)
	self.flight:Reset(cf)
	self.crash:RestoreVisuals()
	self.camera:Snap()
	self.prevPos = cf.Position
end

function RunManager:_beginFlying()
	self.state = "Flying"
	self.prevPos = self.flight:GetPosition()
	self.flight:SetActive(true)
end

-- Neuer Run vom Start (auch für Reset-Button / R-Taste)
function RunManager:StartRun()
	if not self.flight then
		return
	end
	self.token += 1
	local token = self.token

	self.state = "Countdown"
	self.time = 0
	self.checkpoints:Reset()
	self:_placeAt(self.checkpoints:GetStartCFrame())
	self.hud:SetTime(0)
	self.hud:SetCheckpoint(0, self.checkpoints:GetCount())

	task.spawn(function()
		for i = Config.Run.CountdownSeconds, 1, -1 do
			if self.token ~= token then
				return
			end
			self.hud:ShowMessage(tostring(i), nil, YELLOW)
			task.wait(1)
		end
		if self.token ~= token then
			return
		end
		self.hud:ShowMessage("LOS!", 0.8, GREEN)
		self:_beginFlying()
	end)
end

function RunManager:_onCrash(reason: string?)
	-- Nur aus dem Flug heraus -> derselbe Crash kann nicht mehrfach auslösen
	if self.state ~= "Flying" then
		return
	end
	self.state = "Crashed"
	local token = self.token

	self.flight:SetActive(false)
	self.crash:PlayEffect(self.flight:GetPosition())
	self.camera:Shake()
	self.hud:Flash(RED)
	self.hud:ShowMessage("CRASH!", nil, RED, reason)

	task.delay(Config.Crash.RespawnDelay, function()
		if self.token ~= token or (self.state :: string) ~= "Crashed" then
			return
		end
		self:_placeAt(self.checkpoints:GetRespawnCFrame())
		self.state = "Respawning"
		self.hud:ShowMessage("Weiter...", nil, Color3.new(1, 1, 1))

		task.delay(Config.Crash.FreezeAfterRespawn, function()
			if self.token ~= token or (self.state :: string) ~= "Respawning" then
				return
			end
			self.hud:ClearMessage()
			self:_beginFlying()
		end)
	end)
end

function RunManager:_onFinish()
	self.state = "Finished"
	self.flight:Brake()

	local isBest = self.best == nil or self.time < self.best
	if isBest then
		self.best = self.time
		self.hud:SetBest(self.best)
	end
	self.hud:SetCheckpoint(self.checkpoints:GetCount(), self.checkpoints:GetCount(), "Ziel")
	self.hud:ShowMessage(
		"ZIEL!  " .. HUD.formatTime(self.time),
		nil,
		GREEN,
		(isBest and "Neue Bestzeit!  " or "") .. "R oder Reset = neuer Run"
	)
end

-------------------------------------------------------------------------------
-- Frame-Schleife
-------------------------------------------------------------------------------

function RunManager:_step(dt: number)
	local flight = self.flight
	if not flight then
		return
	end
	if not flight:IsValid() then
		self:DetachCharacter()
		return
	end

	local state = self.state
	local input = if state == "Flying" then self.input:GetMoveVector() else Vector2.zero
	flight:Update(dt, input)

	if TIMER_STATES[state] then
		self.time += dt
	end

	if state == "Flying" then
		local position = flight:GetPosition()
		local crashed, reason = self.crash:Check(self.prevPos, flight:GetRootCFrame(), flight:GetVelocity(), dt)
		if crashed then
			self:_onCrash(reason)
		else
			local event = self.checkpoints:Update(self.prevPos, position)
			if event == "checkpoint" then
				local index = self.checkpoints:GetCurrent()
				self.hud:SetCheckpoint(index, self.checkpoints:GetCount(), self.checkpoints:GetCurrentLabel())
				self.hud:ShowMessage("Checkpoint " .. index, 1, Color3.fromRGB(110, 220, 255))
			elseif event == "finish" then
				self:_onFinish()
			end
			self.prevPos = position
		end
	end

	self.hud:SetSpeed(flight:GetSpeed())
	self.hud:SetTime(self.time)
	self.effects:Update(flight:GetSpeed(), self.state == "Flying" or self.state == "Finished")
end

function RunManager:Destroy()
	self:DetachCharacter()
	self._connection:Disconnect()
end

return RunManager
