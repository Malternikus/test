--!strict
-- WorldConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > WorldConfig
--
-- Layout-Konstanten für die Map. Map und Services lesen beide von hier, damit
-- Positionen nicht doppelt gepflegt werden.
--
-- Draufsicht (Norden = -Z):
--
--             [ VOID ]          z = -1590
--           [ OTHERWORLD ]      z = -1310
--           [ RIFT ZONE ]       z = -1030
--           [ SECRET LAB ]      z =  -750
--           [ DARK FOREST ]     z =  -470
--                 |  Signal Road
--          P8     |     P1          Ring aus 8 Plots (Radius 225) um den Hub,
--   P7   Fishing (PLAZA) Arcade  P2  davor eine achteckige Ringstraße
--   P6      Shop         Rebirth P3
--          Index          Quests
--          P5  [LEADERBOARDS]  P4

local WorldConfig = {}

WorldConfig.WorldFolderName = "VoidDiceWorld"
WorldConfig.GroundY = 0

-- Hub / Roll Plaza
WorldConfig.HubCenter = Vector3.new(0, 0, 0)
WorldConfig.PlazaRadius = 42
WorldConfig.SpawnOffset = Vector3.new(0, 3, 18)

-- Plots (Player Bases)
WorldConfig.PlotCount = 8
-- 225 statt 190: Bei 190 ragten die Vorderecken von Plot 1/8 bis x = ±10 in die
-- Signal Road (Breite 34). Mit 225 bleiben ~6 Studs Abstand zur Straße.
WorldConfig.PlotRingRadius = 225
WorldConfig.PlotSize = Vector3.new(96, 1, 96)
-- Winkel des ersten Plots (Grad, 0 = Norden). 22.5 lässt Norden für die
-- Signal Road frei.
WorldConfig.PlotAngleOffset = 22.5

-- Slot-Raster in Plot-Koordinaten (X = rechts, Z = nach hinten/weg vom Hub)
WorldConfig.SlotColumns = 5
WorldConfig.SlotRows = 5
WorldConfig.SlotSpacing = 12
WorldConfig.SlotPadSize = Vector3.new(9, 1, 9)
WorldConfig.SlotGridOrigin = Vector3.new(-40, 0, -10) -- Mitte des ersten Pads (linke Hälfte)

-- Rift Pond in jeder Base
WorldConfig.MaxFishingSeats = 4
WorldConfig.PondCenter = Vector3.new(30, 0, 16)
WorldConfig.PondRadius = 11

-- Sonstiges in der Base
WorldConfig.CollectorOffset = Vector3.new(30, 0, -26)
-- Hinten rechts: die "Investigation Station" (CRTs, Antenne, Mystery Board)
WorldConfig.StationOffset = Vector3.new(30, 0, 40)
WorldConfig.PlotSpawnOffset = Vector3.new(0, 3, -40)
WorldConfig.SignOffset = Vector3.new(-30, 0, -45)

-- Stationen im Hub (Weltkoordinaten)
-- Alle Stationen schauen zur Plaza-Mitte. Zwischen Index und Quests bleibt eine
-- freie Sichtachse von der Plaza zur Leaderboard-Wand im Süden.
WorldConfig.Stations = {
	Shop = Vector3.new(-60, 0, 30),
	Rebirth = Vector3.new(60, 0, 30),
	Index = Vector3.new(-66, 0, 78),
	Quests = Vector3.new(66, 0, 78),
	Fishing = Vector3.new(-86, 0, 0),
	Leaderboards = Vector3.new(0, 0, 120),
}

-- Signal Road und Tore zwischen den Gebieten
WorldConfig.RoadWidth = 34
WorldConfig.GateWidth = 34
WorldConfig.GateHeight = 26

-- Wie oft (Sekunden) der Client die aktuelle Zone prüft
WorldConfig.AreaCheckInterval = 0.5

function WorldConfig.PlotCFrame(index: number): CFrame
	local angle = math.rad(WorldConfig.PlotAngleOffset + (index - 1) * (360 / WorldConfig.PlotCount))
	-- Winkel 0 = Norden (-Z), im Uhrzeigersinn
	local dir = Vector3.new(math.sin(angle), 0, -math.cos(angle))
	local pos = WorldConfig.HubCenter + dir * WorldConfig.PlotRingRadius
	-- Plot "schaut" zum Hub: LookVector zeigt zur Mitte (= -dir).
	-- Bewusst über CFrame.Angles statt CFrame.lookAt: lookAt ist im Lune-Test-
	-- Emulator (0.8.9) fehlerhaft (Z-Komponente gespiegelt). Angles(0, a, 0)
	-- dreht (0,0,-1) auf (-sin a, 0, -cos a); mit a = pi - angle ergibt das -dir.
	return CFrame.new(pos) * CFrame.Angles(0, math.pi - angle, 0)
end

-- Lokale Plot-Koordinate: X nach rechts, Z nach hinten (weg vom Hub).
function WorldConfig.PlotLocal(plotCFrame: CFrame, offset: Vector3): CFrame
	return plotCFrame * CFrame.new(offset.X, offset.Y, offset.Z)
end

function WorldConfig.SlotLocalPosition(slotIndex: number): Vector3
	local i = slotIndex - 1
	local col = i % WorldConfig.SlotColumns
	local row = math.floor(i / WorldConfig.SlotColumns)
	return WorldConfig.SlotGridOrigin + Vector3.new(col * WorldConfig.SlotSpacing, 0, row * WorldConfig.SlotSpacing)
end

return WorldConfig
