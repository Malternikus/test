-- test_world.luau (Lune)
--
-- Baut die komplette Map über den Harness in einen Folder und prüft den
-- Vertrag mit den Services (Namen, Attribute), Teile-Budgets und dass sich
-- Plots, Stationen und die Signal Road nicht in die Quere kommen.
--
-- Aufruf: cd VoidDice/tests && lune run test_world.luau

local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Harness = require("./harness")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3

local h = Harness.load("/home/user/test/VoidDice")
local WorldConfig = h.requirePath("ReplicatedStorage.VoidDice.Config.WorldConfig")
local AreaConfig = h.requirePath("ReplicatedStorage.VoidDice.Config.AreaConfig")
local DiceConfig = h.requirePath("ReplicatedStorage.VoidDice.Config.DiceConfig")
local WorldBuilder = h.requirePath("ServerScriptService.VoidDiceServer.World.WorldBuilder")

local PLOT_BUDGET = 330
local AREA_BUDGET = 450
local WORLD_BUDGET = 7000
local LIGHT_BUDGET = 60

local failures = 0
local checks = 0

local function check(cond: any, msg: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL: " .. msg)
	end
end

local function countParts(root): number
	local n = 0
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

local function child(parent, name: string)
	if parent == nil then
		return nil
	end
	return parent:FindFirstChild(name)
end

-------------------------------------------------------------------------------
-- 2D-Geometrie (XZ): konvexe Polygone + Separating Axis Test
-------------------------------------------------------------------------------

local function plotPolygon(cf): { Vector3 }
	local hx, hz = WorldConfig.PlotSize.X / 2, WorldConfig.PlotSize.Z / 2
	return {
		cf * Vector3.new(-hx, 0, -hz),
		cf * Vector3.new(hx, 0, -hz),
		cf * Vector3.new(hx, 0, hz),
		cf * Vector3.new(-hx, 0, hz),
	}
end

local function rectPolygon(x0: number, x1: number, z0: number, z1: number): { Vector3 }
	return { Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z0), Vector3.new(x1, 0, z1), Vector3.new(x0, 0, z1) }
end

local function project(poly, ax: number, az: number): (number, number)
	local lo, hi = math.huge, -math.huge
	for _, p in poly do
		local d = p.X * ax + p.Z * az
		lo = math.min(lo, d)
		hi = math.max(hi, d)
	end
	return lo, hi
end

local function overlaps(a, b): boolean
	for _, poly in { a, b } do
		for i = 1, #poly do
			local p0, p1 = poly[i], poly[i % #poly + 1]
			local ax, az = -(p1.Z - p0.Z), p1.X - p0.X
			local aLo, aHi = project(a, ax, az)
			local bLo, bHi = project(b, ax, az)
			if aHi <= bLo or bHi <= aLo then
				return false
			end
		end
	end
	return true
end

-- Ecken eines Teils (Weltkoordinaten)
local function corners(part): { Vector3 }
	local cf, s = part.CFrame, part.Size / 2
	local out = {}
	for _, x in { -1, 1 } do
		for _, y in { -1, 1 } do
			for _, z in { -1, 1 } do
				table.insert(out, cf * Vector3.new(x * s.X, y * s.Y, z * s.Z))
			end
		end
	end
	return out
end

-- Achsenparallele Hülle aller Teile eines Modells (XZ) als Polygon
local function footprint(model): { Vector3 }
	local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			for _, c in corners(d) do
				x0, x1 = math.min(x0, c.X), math.max(x1, c.X)
				z0, z1 = math.min(z0, c.Z), math.max(z1, c.Z)
			end
		end
	end
	return rectPolygon(x0, x1, z0, z1)
end

local function flatDir(from: Vector3, to: Vector3): Vector3
	local d = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	return d.Unit
end

local function flatLook(cf): Vector3
	local l = cf.LookVector
	return Vector3.new(l.X, 0, l.Z).Unit
end

-------------------------------------------------------------------------------
-- Bauen
-------------------------------------------------------------------------------

local t0 = os.clock()
local container = Instance.new("Folder")
local world = WorldBuilder.Build(container)
local buildTime = os.clock() - t0

check(world.Root and world.Root.Name == WorldConfig.WorldFolderName, "Root heißt WorldConfig.WorldFolderName")
check(world.Root.Parent == container, "Root hängt am übergebenen Parent")

-------------------------------------------------------------------------------
-- Plots
-------------------------------------------------------------------------------

local hubCenter = WorldConfig.HubCenter
local plotCounts = {}
for i = 1, WorldConfig.PlotCount do
	local plot = world.Plots[i]
	local tag = "Plot" .. i
	check(plot ~= nil and plot.Name == tag, tag .. " existiert")
	if plot then
		check(plot:GetAttribute("PlotIndex") == i, tag .. ": Attribut PlotIndex")
		check(plot.ModelStreamingMode == roblox.Enum.ModelStreamingMode.Persistent, tag .. ": ModelStreamingMode Persistent")
		local slots = child(plot, "Slots")
		check(slots ~= nil, tag .. ": Slots")
		local slotCount = WorldConfig.SlotColumns * WorldConfig.SlotRows
		for s = 1, slotCount do
			local slot = child(slots, "Slot" .. s)
			check(slot ~= nil and slot:IsA("BasePart"), tag .. ": Slot" .. s)
			if slot then
				check(slot:GetAttribute("SlotIndex") == s, tag .. ": Slot" .. s .. " SlotIndex")
				check(child(slot, "Rim") ~= nil, tag .. ": Slot" .. s .. " hat Rim")
				local lookDot = flatLook(slot.CFrame):Dot(flatDir(slot.CFrame.Position, hubCenter))
				check(lookDot > 0.8, tag .. ": Slot" .. s .. " schaut Richtung Hub (" .. lookDot .. ")")
				local top = slot.CFrame.Position.Y + slot.Size.Y / 2
				check(top >= 0 and top <= 0.6, tag .. ": Slot" .. s .. " Oberkante knapp über Boden")
			end
		end
		check(slots and #slots:GetChildren() == slotCount, tag .. ": genau " .. slotCount .. " Slots")

		local water = child(plot, "PondWater")
		check(water ~= nil, tag .. ": PondWater")
		local seats = child(plot, "FishingSeats")
		for s = 1, WorldConfig.MaxFishingSeats do
			local seat = child(seats, "Seat" .. s)
			check(seat ~= nil, tag .. ": Seat" .. s)
			if seat and water then
				local dot = flatLook(seat.CFrame):Dot(flatDir(seat.CFrame.Position, water.CFrame.Position))
				check(dot > 0.99, tag .. ": Seat" .. s .. " schaut zur Teichmitte")
			end
		end
		local collector = child(plot, "Collector")
		check(collector ~= nil and collector:GetAttribute("IsCollector") == true, tag .. ": Collector mit IsCollector")
		local spawnPoint = child(plot, "SpawnPoint")
		check(spawnPoint ~= nil and spawnPoint.CanCollide == false and spawnPoint.Transparency == 1, tag .. ": SpawnPoint unsichtbar, ohne Kollision")
		if spawnPoint then
			local plotCf = WorldConfig.PlotCFrame(i)
			check(flatLook(spawnPoint.CFrame):Dot(-flatLook(plotCf)) > 0.99, tag .. ": SpawnPoint schaut in die Base")
		end
		local sign = child(plot, "SignBoard")
		local signGui = child(sign, "SignGui")
		check(signGui ~= nil and signGui:IsA("SurfaceGui"), tag .. ": SignBoard/SignGui")
		check(child(signGui, "Title") ~= nil and child(signGui, "Subtitle") ~= nil, tag .. ": SignGui Title + Subtitle")
		if sign then
			check(flatLook(sign.CFrame):Dot(flatDir(sign.CFrame.Position, hubCenter)) > 0.8, tag .. ": SignBoard zeigt zum Hub")
		end
		local lights = child(plot, "Lights")
		local bulbs = 0
		if lights then
			for _, b in lights:GetChildren() do
				if b:GetAttribute("Bulb") == true then
					bulbs += 1
				end
			end
		end
		check(bulbs >= 10, tag .. ": Lights-Ordner mit Birnen (" .. bulbs .. ")")
		local chars, fishers = child(plot, "Characters"), child(plot, "Fishers")
		check(chars ~= nil and #chars:GetChildren() == 0, tag .. ": leerer Characters-Ordner")
		check(fishers ~= nil and #fishers:GetChildren() == 0, tag .. ": leerer Fishers-Ordner")
		check(child(plot, "Decor") ~= nil, tag .. ": Decor")
		local n = countParts(plot)
		plotCounts[i] = n
		check(n <= PLOT_BUDGET, tag .. ": " .. n .. " Teile > Budget " .. PLOT_BUDGET)
	end
end

-------------------------------------------------------------------------------
-- Hub: Stationen, Leaderboards, Spawn, Würfel
-------------------------------------------------------------------------------

local stationNames = { "ShopStation", "RebirthStation", "IndexStation", "QuestStation", "FishingStation" }
for _, name in stationNames do
	local st = world.Stations[name]
	check(st ~= nil and st.Name == name, "Station " .. name)
	local prompt = child(st, "PromptPart")
	check(prompt ~= nil and prompt.CanCollide == false and prompt.Transparency == 1, name .. ": PromptPart unsichtbar, ohne Kollision")
	local hasTitle = false
	if st then
		for _, d in st:GetDescendants() do
			if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
				hasTitle = true
			end
		end
		check(world.Hub:FindFirstChild("Stations"):FindFirstChild(name) == st, name .. " liegt in Hub/Stations")
	end
	check(hasTitle, name .. ": hat Titel-GUI")
end

local boardNames = { "Board_MostRolls", "Board_MostRebirths", "Board_TotalCash", "Board_RarestCollection", "Board_BaseValue" }
local wall = child(world.Hub, "LeaderboardWall")
check(wall ~= nil, "Hub/LeaderboardWall")
for _, name in boardNames do
	local board = world.Leaderboards[name]
	check(board ~= nil and board:IsA("BasePart") and board.Parent == wall, "Leaderboard " .. name)
	if board then
		check(board.Size.Y > board.Size.X and board.Size.Z <= 1.5, name .. ": steht aufrecht")
		check(flatLook(board.CFrame):Dot(flatDir(board.CFrame.Position, hubCenter)) > 0.8, name .. ": Front zeigt zur Plaza")
	end
end

local spawn = world.SpawnLocation
check(spawn ~= nil and spawn:IsA("SpawnLocation") and spawn.Neutral == true and spawn.Duration == 0, "SpawnLocation (Neutral, Duration 0)")
local spawnCount = 0
for _, d in world.Root:GetDescendants() do
	if d:IsA("SpawnLocation") then
		spawnCount += 1
	end
end
check(spawnCount == 1, "genau eine SpawnLocation")
check(world.PlazaDie ~= nil and world.PlazaDie.Name == "PlazaDie" and world.PlazaDie.PrimaryPart ~= nil, "PlazaDie mit PrimaryPart")

-------------------------------------------------------------------------------
-- Gebiete
-------------------------------------------------------------------------------

local areaCounts = {}
local areaIds = {}
for _, def in AreaConfig.List do
	if def.Id ~= AreaConfig.StartArea then
		table.insert(areaIds, def.Id)
		local area = world.Areas[def.Id]
		check(area ~= nil, "Gebiet " .. def.Id)
		if area then
			local gate = child(area, "Gate")
			check(gate ~= nil and gate:GetAttribute("AreaId") == def.Id and gate.CanCollide == true, def.Id .. ": Gate (AreaId, CanCollide)")
			if gate then
				local gz = def.Center.Z + def.Size.Z / 2
				check(math.abs(gate.CFrame.Position.Z - gz) < 0.01, def.Id .. ": Gate am Südrand")
				check(math.abs(gate.Size.X - WorldConfig.GateWidth) < 0.01 and math.abs(gate.Size.Y - WorldConfig.GateHeight) < 0.01, def.Id .. ": Gate-Maße")
			end
			local arrival = child(area, "ArrivalPoint")
			check(arrival ~= nil and arrival.CanCollide == false and arrival.Transparency == 1, def.Id .. ": ArrivalPoint")
			if arrival then
				check(arrival.CFrame.Position.Z < def.Center.Z + def.Size.Z / 2, def.Id .. ": ArrivalPoint hinter dem Tor")
			end
			local altar = child(area, "DiceAltar")
			check(child(altar, "PromptPart") ~= nil, def.Id .. ": DiceAltar/PromptPart")
			local expected
			for _, dice in DiceConfig.List do
				if dice.Area == def.Id then
					expected = dice.Id
				end
			end
			check(altar and altar:GetAttribute("DiceId") == expected, def.Id .. ": DiceAltar DiceId = " .. tostring(expected))
			local gui = child(child(child(area, "GateFrame"), "Lintel"), "GateGui")
			check(gui ~= nil and child(gui, "Title") ~= nil and child(gui, "Subtitle") ~= nil, def.Id .. ": GateGui mit Title/Subtitle")
			if gui then
				check(string.find(gui.Subtitle.Text, tostring(def.RequiredRebirths), 1, true) ~= nil, def.Id .. ": GateGui nennt Rebirths")
			end
			local n = countParts(area)
			areaCounts[def.Id] = n
			check(n <= AREA_BUDGET, def.Id .. ": " .. n .. " Teile > Budget " .. AREA_BUDGET)
		end
	end
end

-------------------------------------------------------------------------------
-- Budgets
-------------------------------------------------------------------------------

local total = countParts(world.Root)
check(world.PartCount == total, "PartCount stimmt")
check(total <= WORLD_BUDGET, "Welt: " .. total .. " Teile > Budget " .. WORLD_BUDGET)
local lightCount = 0
for _, d in world.Root:GetDescendants() do
	if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
		lightCount += 1
	end
end
check(lightCount <= LIGHT_BUDGET, "Lichter: " .. lightCount .. " > " .. LIGHT_BUDGET)

-------------------------------------------------------------------------------
-- Überschneidungen: Plots vs. Plots, Stationen, Road; Hub-Deko nicht in Plots
-------------------------------------------------------------------------------

local plotPolys = {}
for i = 1, WorldConfig.PlotCount do
	plotPolys[i] = plotPolygon(WorldConfig.PlotCFrame(i))
end
for i = 1, #plotPolys do
	for j = i + 1, #plotPolys do
		check(not overlaps(plotPolys[i], plotPolys[j]), string.format("Plot%d überlappt Plot%d", i, j))
	end
end

local stationModels = {}
for _, name in stationNames do
	stationModels[name] = world.Stations[name]
end
stationModels.LeaderboardWall = wall
for name, model in stationModels do
	if model then
		local fp = footprint(model)
		for i = 1, #plotPolys do
			check(not overlaps(plotPolys[i], fp), string.format("%s überlappt Plot%d", name, i))
		end
		for other, om in stationModels do
			if other < name and om then
				check(not overlaps(fp, footprint(om)), string.format("%s überlappt %s", name, other))
			end
		end
	end
end

-- Signal Road im Suburb (Plaza-Rand bis Nordrand) darf von keinem Plot berührt werden
local suburb = AreaConfig.Get("Suburb")
local rw = WorldConfig.RoadWidth
local roadPoly = rectPolygon(hubCenter.X - rw / 2, hubCenter.X + rw / 2, suburb.Center.Z - suburb.Size.Z / 2, hubCenter.Z - WorldConfig.PlazaRadius)
for i = 1, #plotPolys do
	check(not overlaps(plotPolys[i], roadPoly), string.format("Plot%d blockiert die Signal Road", i))
end

-- Kein kollidierendes Hindernis auf Laufhöhe im Straßenkorridor (ganze Strecke)
local lastArea = AreaConfig.List[#AreaConfig.List]
local corridor = rectPolygon(hubCenter.X - rw / 2 + 1, hubCenter.X + rw / 2 - 1, lastArea.Center.Z - lastArea.Size.Z / 2 + 45, hubCenter.Z - WorldConfig.PlazaRadius)
local bounds = world.Root:FindFirstChild("Bounds")
for _, d in world.Root:GetDescendants() do
	if d:IsA("BasePart") and d.CanCollide and d.Name ~= "Gate" and not d:IsDescendantOf(bounds) then
		local cs = corners(d)
		local yLo, yHi = math.huge, -math.huge
		for _, c in cs do
			yLo, yHi = math.min(yLo, c.Y), math.max(yHi, c.Y)
		end
		if yHi > 0.6 and yLo < 6 then
			local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
			for _, c in cs do
				x0, x1 = math.min(x0, c.X), math.max(x1, c.X)
				z0, z1 = math.min(z0, c.Z), math.max(z1, c.Z)
			end
			check(not overlaps(corridor, rectPolygon(x0, x1, z0, z1)), "Hindernis auf der Signal Road: " .. d:GetFullName())
		end
	end
end

-- Hub-Teile (außer Boden) liegen nicht in Plots
for _, d in world.Hub:GetDescendants() do
	if d:IsA("BasePart") and d.Name ~= "Ground" then
		local p = d.CFrame.Position
		local inside = false
		for i = 1, WorldConfig.PlotCount do
			local rel = WorldConfig.PlotCFrame(i):PointToObjectSpace(Vector3.new(p.X, 0, p.Z))
			if math.abs(rel.X) < WorldConfig.PlotSize.X / 2 and math.abs(rel.Z) < WorldConfig.PlotSize.Z / 2 then
				inside = true
			end
		end
		check(not inside, "Hub-Teil im Plot: " .. d:GetFullName())
	end
end

-------------------------------------------------------------------------------
-- Determinismus: zweiter Bau liefert dieselbe Map
-------------------------------------------------------------------------------

local function checksum(root): number
	local sum = 0
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			local p = d.CFrame.Position
			sum += p.X * 1.3 + p.Y * 0.7 + p.Z * 1.1 + d.Size.X + d.Size.Y + d.Size.Z
		end
	end
	return sum
end
local world2 = WorldBuilder.Build(Instance.new("Folder"))
check(world2.PartCount == world.PartCount, "Determinismus: gleiche Teilezahl")
check(math.abs(checksum(world2.Root) - checksum(world.Root)) < 1e-3, "Determinismus: gleiche Positionen")

-------------------------------------------------------------------------------
-- Ausgabe
-------------------------------------------------------------------------------

print(string.format("Build: %.2fs", buildTime))
local plotLine = {}
for i = 1, WorldConfig.PlotCount do
	table.insert(plotLine, tostring(plotCounts[i]))
end
print("Teile pro Plot: " .. table.concat(plotLine, ", "))
for _, id in areaIds do
	print(string.format("Teile %-11s %d", id, areaCounts[id] or -1))
end
print(string.format("Teile Hub: %d   Road: %d   Bounds: %d", countParts(world.Hub), countParts(world.Road), countParts(bounds)))
print(string.format("Teile gesamt: %d / %d   Lichter: %d / %d", total, WORLD_BUDGET, lightCount, LIGHT_BUDGET))
for _, name in stationNames do
	local p = child(world.Stations[name], "PromptPart")
	if p then
		local pos = p.CFrame.Position
		print(string.format("  %-15s PromptPart (%.1f, %.1f, %.1f)", name, pos.X, pos.Y, pos.Z))
	end
end

print(string.format("%d Checks, %d Fehler", checks, failures))
if failures > 0 then
	process.exit(1)
end
print("OK")
