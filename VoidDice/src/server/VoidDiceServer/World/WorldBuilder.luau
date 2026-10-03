--!strict
-- WorldBuilder (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > World > WorldBuilder
--
-- Baut die komplette Map prozedural unter `parent` (im Spiel: workspace).
-- Fester Seed -> die Map sieht bei jedem Serverstart identisch aus.
--
-- Struktur:
--   VoidDiceWorld (Folder, Name aus WorldConfig.WorldFolderName)
--     Hub          Model (Plaza, PlazaDie, SpawnLocation, Stations/*, LeaderboardWall)
--     Plots        Folder mit Plot1..Plot8
--     Areas        Folder mit DarkForest, SecretLab, RiftZone, Otherworld, Void
--     SignalRoad   Model (Straße, Brücken, Laternen)
--     Bounds       Folder mit unsichtbaren Wänden (Weltgrenze)
--
-- Rückgabe von Build: siehe Typ World unten.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))
local AreaConfig = require(ConfigFolder:WaitForChild("AreaConfig"))

local Parts = require(script.Parent:WaitForChild("Parts"))
local Hub = require(script.Parent:WaitForChild("Hub"))
local Plot = require(script.Parent:WaitForChild("Plot"))
local Areas = require(script.Parent:WaitForChild("Areas"))
local Road = require(script.Parent:WaitForChild("Road"))

local V3 = Vector3.new
local CF = CFrame.new

local WorldBuilder = {}

WorldBuilder.Seed = 1985
WorldBuilder.BoundHeight = 100

export type World = {
	Root: Folder,
	Hub: Model,
	Plots: { [number]: Model },
	Areas: { [string]: Model },
	Stations: { [string]: Model },
	Leaderboards: { [string]: BasePart },
	SpawnLocation: SpawnLocation,
	PlazaDie: Model,
	Road: Model,
	PartCount: number,
	LightCount: number,
}

-- Unsichtbare Wand als achsenparalleles Rechteck (x0..x1, z0..z1)
local function wall(bounds: Folder, x0: number, x1: number, z0: number, z1: number)
	local sx = math.max(math.abs(x1 - x0), 2)
	local sz = math.max(math.abs(z1 - z0), 2)
	local h = WorldBuilder.BoundHeight
	Parts.Invisible(bounds, CF((x0 + x1) / 2, WorldConfig.GroundY + h / 2 - 10, (z0 + z1) / 2), V3(sx, h, sz), "Boundary", true)
end

-- Grenzen um jedes Gebiet. Öffnungen nur dort, wo Straße/Brücke/Tor liegen.
local function buildBounds(bounds: Folder)
	local areas = Road.SortedAreas()
	local roadX = WorldConfig.HubCenter.X
	local roadHalf = WorldConfig.RoadWidth / 2 + 1 -- trifft die Brückenwände
	local gateHalf = WorldConfig.GateWidth / 2
	for i, def in areas do
		local c, hx, hz = def.Center, def.Size.X / 2, def.Size.Z / 2
		local w, e, s, n = c.X - hx, c.X + hx, c.Z + hz, c.Z - hz
		wall(bounds, w - 1, w + 1, s, n)
		wall(bounds, e - 1, e + 1, s, n)
		-- Süden: Suburb geschlossen, sonst Öffnung für das Tor
		if i == 1 then
			wall(bounds, w, e, s - 1, s + 1)
		else
			wall(bounds, w, roadX - gateHalf, s - 1, s + 1)
			wall(bounds, roadX + gateHalf, e, s - 1, s + 1)
		end
		-- Norden: letztes Gebiet geschlossen, sonst Öffnung für die Brücke
		if i == #areas then
			wall(bounds, w, e, n - 1, n + 1)
		else
			wall(bounds, w, roadX - roadHalf, n - 1, n + 1)
			wall(bounds, roadX + roadHalf, e, n - 1, n + 1)
		end
	end
end

function WorldBuilder.Build(parent: Instance): World
	Parts.ResetStats()
	local seed = WorldBuilder.Seed

	local root = Instance.new("Folder")
	root.Name = WorldConfig.WorldFolderName

	local bounds = Parts.Folder(root, "Bounds")

	local hub = Hub.Build(root, Random.new(seed + 1))

	local plotsFolder = Parts.Folder(root, "Plots")
	local plots: { [number]: Model } = {}
	for i = 1, WorldConfig.PlotCount do
		plots[i] = Plot.Build(i, WorldConfig.PlotCFrame(i), plotsFolder)
	end

	local areasFolder = Parts.Folder(root, "Areas")
	local areas: { [string]: Model } = {}
	for _, def in Road.SortedAreas() do
		if def.Id ~= AreaConfig.StartArea then
			areas[def.Id] = Areas.Build(def, areasFolder, Random.new(seed + 100 + def.Order))
		end
	end

	local road = Road.Build(root, bounds)
	buildBounds(bounds)

	if Parts.Stats.SkippedLights > 0 then
		warn(string.format("[WorldBuilder] %d Lichter wegen Limit (%d) ausgelassen", Parts.Stats.SkippedLights, Parts.MaxLights))
	end

	root.Parent = parent
	return {
		Root = root,
		Hub = hub.Model,
		Plots = plots,
		Areas = areas,
		Stations = hub.Stations,
		Leaderboards = hub.Leaderboards,
		SpawnLocation = hub.SpawnLocation,
		PlazaDie = hub.PlazaDie,
		Road = road,
		PartCount = Parts.CountParts(root),
		LightCount = Parts.Stats.Lights,
	}
end

return WorldBuilder
