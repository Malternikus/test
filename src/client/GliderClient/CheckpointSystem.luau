-- CheckpointSystem (ModuleScript)
-- Ort: StarterPlayerScripts > GliderClient > CheckpointSystem
--
-- Liest die Checkpoint-Daten, die der Server in ReplicatedStorage ablegt.
-- Statt Touched-Events wird pro Frame nur geprüft, ob die Linie zwischen
-- letzter und aktueller Position die Fläche des NÄCHSTEN Checkpoints kreuzt.
-- Das ist billig und funktioniert auch bei hohem Tempo zuverlässig.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))

type Gate = {
	cframe: CFrame,
	size: Vector3,
	spawn: CFrame?,
	label: string?,
	visual: BasePart?,
}

local REACHED_COLOR = Color3.fromRGB(80, 255, 120)
local CROSS_MARGIN = 4

local CheckpointSystem = {}
CheckpointSystem.__index = CheckpointSystem

local function findVisual(map: Model, name: string): BasePart?
	local decor = map:FindFirstChild(Config.Names.DecorFolder)
	local part = decor and decor:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

function CheckpointSystem.new(trackData: Folder, map: Model)
	local self = setmetatable({}, CheckpointSystem)
	self.start = (trackData:WaitForChild("Start") :: CFrameValue).Value
	self.gates = {} :: { Gate }
	self.current = 0 -- 0 = noch kein Checkpoint (Start)

	local list = trackData:WaitForChild("Checkpoints"):GetChildren()
	table.sort(list, function(a, b)
		return (a:GetAttribute("Index") or 0) < (b:GetAttribute("Index") or 0)
	end)
	for _, entry in list do
		local index = entry:GetAttribute("Index")
		local visual = findVisual(map, "CheckpointGate_" .. tostring(index))
		table.insert(self.gates, {
			cframe = (entry:WaitForChild("Gate") :: CFrameValue).Value,
			size = entry:GetAttribute("Size"),
			spawn = (entry:WaitForChild("Spawn") :: CFrameValue).Value,
			label = entry:GetAttribute("Label"),
			visual = visual,
		})
	end

	local finishEntry = trackData:WaitForChild("Finish")
	self.finish = {
		cframe = (finishEntry:WaitForChild("Gate") :: CFrameValue).Value,
		size = finishEntry:GetAttribute("Size"),
		visual = findVisual(map, "FinishGate"),
	} :: Gate

	self.originalColors = {} :: { [BasePart]: Color3 }
	for _, gate in self.gates do
		if gate.visual then
			self.originalColors[gate.visual] = gate.visual.Color
		end
	end
	return self
end

-- Kreuzt die Strecke a -> b die Fläche des Tores (in Flugrichtung)?
local function crossed(gate: Gate, a: Vector3, b: Vector3): boolean
	local la = gate.cframe:PointToObjectSpace(a)
	local lb = gate.cframe:PointToObjectSpace(b)
	-- Vor dem Tor ist lokales Z positiv, dahinter negativ (LookVector = -Z)
	if la.Z > 0 and lb.Z <= 0 then
		local t = la.Z / (la.Z - lb.Z)
		local hit = la:Lerp(lb, t)
		return math.abs(hit.X) <= gate.size.X / 2 + CROSS_MARGIN and math.abs(hit.Y) <= gate.size.Y / 2 + CROSS_MARGIN
	end
	return false
end

function CheckpointSystem:Reset()
	self.current = 0
	for part, color in self.originalColors do
		part.Color = color
	end
end

function CheckpointSystem:GetCount(): number
	return #self.gates
end

function CheckpointSystem:GetCurrent(): number
	return self.current
end

function CheckpointSystem:GetCurrentLabel(): string?
	local gate = self.gates[self.current]
	return gate and gate.label
end

function CheckpointSystem:GetStartCFrame(): CFrame
	return self.start
end

function CheckpointSystem:GetRespawnCFrame(): CFrame
	local gate = self.gates[self.current]
	if gate and gate.spawn then
		return gate.spawn
	end
	return self.start
end

-- Gibt "checkpoint", "finish" oder nil zurück.
function CheckpointSystem:Update(previous: Vector3, current: Vector3): string?
	local nextGate = self.gates[self.current + 1]
	if nextGate then
		if crossed(nextGate, previous, current) then
			self.current += 1
			if nextGate.visual then
				nextGate.visual.Color = REACHED_COLOR
			end
			return "checkpoint"
		end
		return nil
	end
	if crossed(self.finish, previous, current) then
		return "finish"
	end
	return nil
end

return CheckpointSystem
