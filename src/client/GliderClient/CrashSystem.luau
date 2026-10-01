-- CrashSystem (ModuleScript)
-- Ort: StarterPlayerScripts > GliderClient > CrashSystem
--
-- Kollisionserkennung per Blockcast: Eine Box in Größe des Gleiters wird pro
-- Frame von der letzten Position entlang der Bewegung (plus etwas Vorausschau)
-- geschoben. Trifft sie ein Teil aus Map/Solid, ist das ein Crash.
-- Vorteile gegenüber Touched: kein "Durchtunneln" bei hohem Tempo, der Gleiter
-- stoppt vor der Wand statt darin zu stecken, und nur EINE Abfrage pro Frame.
--
-- Mehrfach-Auslösung verhindert der RunManager (Crash nur im Zustand "Flying").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))
local CR = Config.Crash

local CRASH_COLOR = Color3.fromRGB(255, 40, 40)

local CrashSystem = {}
CrashSystem.__index = CrashSystem

function CrashSystem.new(map: Model)
	local self = setmetatable({}, CrashSystem)
	local solid = map:WaitForChild(Config.Names.SolidFolder)
	self.params = RaycastParams.new()
	self.params.FilterType = Enum.RaycastFilterType.Include
	self.params.FilterDescendantsInstances = { solid }
	self.gliderParts = {} :: { [BasePart]: Color3 }
	return self
end

function CrashSystem:SetCharacter(character: Model)
	table.clear(self.gliderParts)
	local glider = character:FindFirstChild(Config.Names.GliderModel) or character:WaitForChild(Config.Names.GliderModel, 5)
	if glider then
		for _, part in glider:GetDescendants() do
			if part:IsA("BasePart") then
				self.gliderParts[part] = part.Color
			end
		end
	end
end

-- Prüft die Bewegung von previous zur aktuellen Root-CFrame.
-- Gibt (true, Grund) bei Crash zurück.
function CrashSystem:Check(previous: Vector3, rootCFrame: CFrame, velocity: Vector3, dt: number): (boolean, string?)
	local position = rootCFrame.Position

	if position.Y < CR.MinAltitude then
		return true, "Boden"
	end
	if position.Y > CR.MaxAltitude then
		return true, "Zu hoch!"
	end

	local speed = velocity.Magnitude
	local direction = (position - previous) + velocity * dt
	if speed > 0.01 then
		direction += velocity.Unit * CR.Lookahead
	end
	if direction.Magnitude < 0.01 then
		return false, nil
	end

	local origin = CFrame.new(previous) * rootCFrame.Rotation * CFrame.new(CR.BoxOffset)
	local result = workspace:Blockcast(origin, CR.BoxSize, direction, self.params)
	if result then
		return true, "Hindernis getroffen"
	end
	return false, nil
end

-- Kurze visuelle Rückmeldung am Gleiter
function CrashSystem:PlayEffect(position: Vector3)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 4
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.Parent = workspace

	for part in self.gliderParts do
		if part.Parent then
			part.Color = CRASH_COLOR
		end
	end
end

function CrashSystem:RestoreVisuals()
	for part, color in self.gliderParts do
		if part.Parent then
			part.Color = color
		end
	end
end

return CrashSystem
