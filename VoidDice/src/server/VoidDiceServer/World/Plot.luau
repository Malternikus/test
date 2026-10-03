--!strict
-- Plot (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > World > Plot
--
-- Baut eine Spieler-Base ("Plot1".."Plot8").
--
-- Plot-Koordinaten: X = rechts, Z = nach hinten (weg vom Hub), Ursprung =
-- Plot-Mitte auf Bodenhöhe. -Z (LookVector der Plot-CFrame) zeigt zum Hub;
-- dort ist auch der Eingang. Alles steht auf der Ebene y = 0 (Oberkante Floor).
--
-- Vertrag mit den Services (Namen nicht ändern!):
--   Plot<i>                 Model, Attribut PlotIndex, ModelStreamingMode Persistent
--     Floor                 PrimaryPart (96x1x96, Oberkante y = 0)
--     Slots/Slot1..25       Pad (Attribut SlotIndex), Kind-Part "Rim" (Neon, Farbe per Code)
--                           Charakter-CFrame = SlotN.CFrame * CFrame.new(0, SlotN.Size.Y/2, 0)
--     PondWater             Leuchtendes Wasser des Rift Pond
--     FishingSeats/Seat1..4 LookVector zeigt zur Teichmitte (Attribut SeatIndex)
--     Collector             Cash-Pad (Attribut IsCollector = true), BillboardGui "CollectorGui"
--     SpawnPoint            unsichtbar, schaut in die Base hinein
--     SignBoard             SurfaceGui "SignGui" mit TextLabels "Title" + "Subtitle"
--     Lights                Birnen der Lichterketten (Attribut Bulb = true)
--     Characters, Fishers   leer, werden von Services gefüllt
--     Decor                 alles andere

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))

local Parts = require(script.Parent:WaitForChild("Parts"))
local Props = require(script.Parent:WaitForChild("Props"))

local Palette = Parts.Palette
local V3 = Vector3.new
local CF = CFrame.new
local Mat = Enum.Material

local Plot = {}

local FLOOR_COLOR = Color3.fromRGB(46, 44, 70)
local PAD_COLOR = Color3.fromRGB(24, 22, 38)
local RIM_COLOR = Color3.fromRGB(110, 70, 220)
local ACCENT = Palette.Purple
local ENTRANCE_WIDTH = 20

-- Blickrichtungen in Plot-Koordinaten
local FACE_HUB = CFrame.new()
local FACE_BACK = CFrame.Angles(0, math.pi, 0)
local FACE_RIGHT = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)

-- Plot-lokale Blickrichtung von a nach b (nur Y-Rotation)
local function faceLocal(a: Vector3, b: Vector3): CFrame
	return Parts.FaceTowards(a, b) - a
end

function Plot.Build(index: number, cframe: CFrame, parent: Instance): Model
	local rng = Random.new(1000 + index)
	local model = Parts.Model(nil, "Plot" .. index)
	model:SetAttribute("PlotIndex", index)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local decor = Parts.Folder(model, "Decor")
	local slotsFolder = Parts.Folder(model, "Slots")
	local seatsFolder = Parts.Folder(model, "FishingSeats")
	local lightsFolder = Parts.Folder(model, "Lights")
	Parts.Folder(model, "Characters")
	Parts.Folder(model, "Fishers")

	-- Lokale CFrame -> Welt
	local function L(x: number, y: number, z: number, rot: CFrame?): CFrame
		return cframe * CF(x, y, z) * (rot or FACE_HUB)
	end
	local function W(x: number, y: number, z: number): Vector3
		return cframe * V3(x, y, z)
	end

	local size = WorldConfig.PlotSize
	local hx, hz = size.X / 2, size.Z / 2

	---------------------------------------------------------------------------
	-- Boden, Weg, Kantenleuchten
	---------------------------------------------------------------------------
	local floor = Parts.Part({
		Parent = model,
		Name = "Floor",
		CFrame = L(0, -size.Y / 2, 0),
		Size = size,
		Color = FLOOR_COLOR,
		Material = Mat.Concrete,
	})
	model.PrimaryPart = floor

	Parts.Box(decor, L(0, 0.05 - 0.5, -hz + 17), V3(10, 1, 34), Palette.AsphaltDark, Mat.Pavement, "Walkway")
	for _, e in { { 0, -hz + 2, size.X - 4, 0.6 }, { 0, hz - 2, size.X - 4, 0.6 } } do
		Parts.Neon(decor, L(e[1], 0.03, e[2]), V3(e[3], 0.08, e[4]), ACCENT, "EdgeGlow")
	end
	for _, x in { -hx + 2, hx - 2 } do
		Parts.Neon(decor, L(x, 0.03, 0), V3(0.6, 0.08, size.Z - 4), ACCENT, "EdgeGlow")
	end

	---------------------------------------------------------------------------
	-- Zaun mit Eingang vorne (Richtung Hub)
	---------------------------------------------------------------------------
	local fenceColor = Palette.Navy
	local function fencePanel(cx: number, cz: number, len: number, h: number, alongX: boolean)
		local sx, sz = if alongX then len else 0.8, if alongX then 0.8 else len
		Parts.Box(decor, L(cx, h / 2, cz), V3(sx, h, sz), fenceColor, Mat.WoodPlanks, "Fence")
		Parts.Neon(decor, L(cx, h + 0.15, cz), V3(sx + 0.05, 0.3, sz + 0.05), ACCENT, "FenceTrim")
	end
	local frontLen = hx - ENTRANCE_WIDTH / 2
	fencePanel(-hx + frontLen / 2, -hz + 0.4, frontLen, 3.5, true)
	fencePanel(hx - frontLen / 2, -hz + 0.4, frontLen, 3.5, true)
	fencePanel(-hx + 0.4, 0, size.Z, 3.5, false)
	fencePanel(hx - 0.4, 0, size.Z, 3.5, false)
	fencePanel(0, hz - 0.4, size.X, 6, true)

	-- Pfosten (hinten dienen sie als Aufhängung für die Lichterketten)
	local backPostX = { -hx + 0.4, -16, 16, hx - 0.4 }
	for _, x in backPostX do
		Parts.Box(decor, L(x, 4.5, hz - 0.4), V3(1.2, 9, 1.2), Palette.WoodDark, Mat.Wood, "Post")
	end
	for _, x in { -hx + 0.4, hx - 0.4 } do
		Parts.Box(decor, L(x, 2.5, -hz + 0.4), V3(1.2, 5, 1.2), Palette.WoodDark, Mat.Wood, "Post")
	end
	-- Eingangstor mit Querbalken
	local gx = ENTRANCE_WIDTH / 2 + 0.6
	for _, x in { -gx, gx } do
		Parts.Box(decor, L(x, 4, -hz + 0.4), V3(1.4, 8, 1.4), Palette.WoodDark, Mat.Wood, "GatePost")
		Parts.Ball(decor, L(x, 8.4, -hz + 0.4), 1.2, ACCENT, Mat.Neon, "GateCap")
	end
	Parts.Box(decor, L(0, 7.6, -hz + 0.4), V3(gx * 2, 1.2, 1.2), Palette.WoodDark, Mat.Wood, "GateBeam")
	Parts.Neon(decor, L(0, 6.9, -hz + 0.4), V3(gx * 2 - 1.4, 0.25, 0.5), ACCENT, "GateGlow")

	---------------------------------------------------------------------------
	-- Slots (5x5 Raster)
	---------------------------------------------------------------------------
	local padSize = WorldConfig.SlotPadSize
	local padTop = 0.3
	for i = 1, WorldConfig.SlotColumns * WorldConfig.SlotRows do
		local p = WorldConfig.SlotLocalPosition(i)
		local pad = Parts.Part({
			Parent = slotsFolder,
			Name = "Slot" .. i,
			CFrame = L(p.X, padTop - padSize.Y / 2, p.Z),
			Size = padSize,
			Color = PAD_COLOR,
			Material = Mat.SmoothPlastic,
			Attributes = { SlotIndex = i },
		})
		local rim = Parts.Part({
			Parent = pad,
			Name = "Rim",
			CFrame = L(p.X, padTop - 0.05 - (padSize.Y - 0.1) / 2, p.Z),
			Size = V3(padSize.X + 0.8, padSize.Y - 0.1, padSize.Z + 0.8),
			Color = RIM_COLOR,
			Material = Mat.Neon,
			CanCollide = false,
		})
		rim.CastShadow = false
	end

	---------------------------------------------------------------------------
	-- Rift Pond mit Angelplätzen
	---------------------------------------------------------------------------
	local pc = WorldConfig.PondCenter
	local pr = WorldConfig.PondRadius
	local water = Parts.Part({
		Parent = model,
		Name = "PondWater",
		Shape = Enum.PartType.Cylinder,
		CFrame = L(pc.X, 0.1, pc.Z) * CFrame.Angles(0, 0, math.pi / 2),
		Size = V3(0.6, pr * 2, pr * 2),
		Color = Color3.fromRGB(110, 80, 255),
		Material = Mat.Neon,
		Transparency = 0.25,
		CanCollide = false,
	})
	Parts.Light(water, Color3.fromRGB(140, 100, 255), 22, 1.4)
	Parts.Part({
		Parent = decor,
		Name = "PondSwirl",
		Shape = Enum.PartType.Cylinder,
		CFrame = L(pc.X, 0.12, pc.Z) * CFrame.Angles(0, 0, math.pi / 2),
		Size = V3(0.62, pr * 0.8, pr * 0.8),
		Color = Palette.Cyan,
		Material = Mat.Neon,
		Transparency = 0.45,
		CanCollide = false,
	})
	-- Steinkranz (Lücken an den Stegen)
	for k = 0, 15 do
		local deg = k * 22.5
		if deg % 90 ~= 45 then
			local a = math.rad(deg)
			local pos = V3(pc.X + math.cos(a) * (pr + 0.9), 0, pc.Z + math.sin(a) * (pr + 0.9))
			Props.Rock(decor, L(pos.X, 0, pos.Z), { Rng = rng, Size = rng:NextNumber(2.4, 3.4), Parts = 1, Color = Color3.fromRGB(60, 56, 78) })
		end
	end
	-- Angelplätze: Steg + Hocker + Köderdose, Blick zur Teichmitte
	for i = 1, WorldConfig.MaxFishingSeats do
		local a = math.rad(45 + (i - 1) * (360 / WorldConfig.MaxFishingSeats))
		local dir = V3(math.cos(a), 0, math.sin(a))
		local seatPos = V3(pc.X, 0, pc.Z) + dir * (pr + 2.2)
		local look = faceLocal(seatPos, V3(pc.X, 0, pc.Z))
		local plankPos = seatPos - dir * 1.6
		Parts.Box(decor, cframe * CF(plankPos.X, 0.25, plankPos.Z) * look, V3(2.8, 0.5, 6.2), Palette.Wood, Mat.WoodPlanks, "Dock")
		Parts.Part({
			Parent = seatsFolder,
			Name = "Seat" .. i,
			CFrame = cframe * CF(seatPos.X, 1.1, seatPos.Z) * look,
			Size = V3(2.2, 1.2, 2.2),
			Color = Palette.WoodLight,
			Material = Mat.WoodPlanks,
			Attributes = { SeatIndex = i },
		})
		local side = look.RightVector
		local bucket = seatPos + side * 1.9
		Parts.VCyl(decor, cframe * CF(bucket.X, 0.9, bucket.Z), 0.8, 0.9, Palette.Red, Mat.Metal, "BaitBucket")
	end

	---------------------------------------------------------------------------
	-- Collector (Cash-Pad) + Maschine
	---------------------------------------------------------------------------
	local co = WorldConfig.CollectorOffset
	Parts.Box(decor, L(co.X, -0.2, co.Z), V3(9.4, 1, 9.4), Palette.MetalDark, Mat.DiamondPlate, "CollectorFrame")
	local collector = Parts.Part({
		Parent = model,
		Name = "Collector",
		CFrame = L(co.X, 0.3, co.Z),
		Size = V3(8, 0.4, 8),
		Color = Color3.fromRGB(60, 255, 150),
		Material = Mat.Neon,
		Attributes = { IsCollector = true },
	})
	collector.CanTouch = true
	Parts.Light(collector, Color3.fromRGB(60, 255, 150), 14, 1.2)
	Parts.Billboard(collector, "$0", "STEP ON TO COLLECT", {
		Name = "CollectorGui",
		Offset = V3(0, 6, 0),
		Width = 12,
		Height = 4,
		TitleColor = Color3.fromRGB(120, 255, 170),
		MaxDistance = 90,
	})
	local mx = co.X + 9
	Parts.Box(decor, L(mx, 3, co.Z, FACE_LEFT), V3(5, 6, 3.5), Palette.Navy, Mat.Metal, "Machine")
	local screen = Parts.Neon(decor, L(mx - 1.8, 3.8, co.Z, FACE_LEFT), V3(3.4, 2, 0.1), Color3.fromRGB(60, 255, 150), "MachineScreen")
	Parts.SurfaceLabel(screen, Enum.NormalId.Front, "CASH", nil, { TitleColor = Palette.Night, PixelsPerStud = 30 })
	Parts.Beam(decor, W(mx - 1.75, 1, co.Z + 1), W(co.X + 4.2, 0.3, co.Z + 1), 0.6, Palette.Metal, Mat.Metal, "Pipe")
	Parts.Ball(decor, L(mx, 6.6, co.Z), 1.2, Palette.Green, Mat.Neon, "Beacon")

	---------------------------------------------------------------------------
	-- SpawnPoint + Schild
	---------------------------------------------------------------------------
	local sp = WorldConfig.PlotSpawnOffset
	Parts.Invisible(model, L(sp.X, sp.Y, sp.Z, FACE_BACK), V3(4, 1, 4), "SpawnPoint", false)

	local so = WorldConfig.SignOffset
	for _, x in { -7.6, 7.6 } do
		Parts.Box(decor, L(so.X + x, 4.5, so.Z + 0.3), V3(0.8, 9, 0.8), Palette.WoodDark, Mat.Wood, "SignPost")
	end
	Parts.Neon(decor, L(so.X, 6.25, so.Z + 0.45), V3(16.8, 6.3, 0.3), ACCENT, "SignGlow")
	local sign = Parts.Part({
		Parent = model,
		Name = "SignBoard",
		CFrame = L(so.X, 6.25, so.Z),
		Size = V3(16, 5.5, 0.6),
		Color = Palette.Navy,
		Material = Mat.SmoothPlastic,
	})
	Parts.SurfaceLabel(sign, Enum.NormalId.Front, "EMPTY BASE", "Claim on join", {
		Name = "SignGui",
		Background = Palette.Night,
		TitleColor = Palette.Amber,
		SubtitleColor = Palette.Cyan,
		PixelsPerStud = 24,
	})

	---------------------------------------------------------------------------
	-- Investigation Station (hinten rechts)
	---------------------------------------------------------------------------
	local st = WorldConfig.StationOffset -- (30, 0, 40)
	local deskZ = st.Z + 3.5
	Props.Desk(decor, L(st.X - 2, 0, deskZ), { Width = 12, Depth = 3.5, Height = 3 })
	Props.CRT(decor, L(st.X - 6, 3, deskZ), { Text = "SIGNAL\nDETECTED" })
	Props.CRT(decor, L(st.X - 2.4, 3, deskZ) * CFrame.Angles(0, -0.15, 0), { ScreenColor = Palette.Cyan, Text = "FREQ 7.83" })
	Props.Radio(decor, L(st.X + 1.6, 3, deskZ))
	Props.Crate(decor, L(st.X + 6.5, 0, deskZ + 0.5), { Size = 3 })
	Props.CRT(decor, L(st.X + 6.5, 3, deskZ + 0.5) * CFrame.Angles(0, 0.2, 0), { ScreenColor = Palette.Orange, Text = "???" })
	Props.Chair(decor, L(st.X - 2.4, 0, deskZ - 4, FACE_BACK))
	Props.Corkboard(decor, L(st.X + 12, 0, st.Z + 5))
	Props.MapTable(decor, L(st.X + 8, 0, st.Z - 7))
	local mastPos = V3(hx - 3.5, 0, st.Z - 3)
	Props.AntennaMast(decor, L(mastPos.X, 0, mastPos.Z), { Height = 22, GuySpread = 2.6 })
	Props.WalkieStand(decor, L(st.X - 11, 0, deskZ))
	Props.Cables(decor, L(st.X + 2, 0, deskZ - 1.5), { To = W(mastPos.X - 1.5, 0, mastPos.Z), Count = 2, Rng = rng })
	Props.Cables(decor, L(st.X - 7, 0, deskZ - 1.5), { To = W(st.X - 11, 0, deskZ - 1), Count = 2, Rng = rng })

	---------------------------------------------------------------------------
	-- Lichterketten (alle Birnen in "Lights")
	---------------------------------------------------------------------------
	local hangY = 8.6
	for i = 1, #backPostX - 1 do
		Props.StringLights(decor, L(backPostX[i], hangY, hz - 0.4), {
			To = W(backPostX[i + 1], hangY, hz - 0.4),
			Count = 10,
			Sag = 2.2,
			BulbParent = lightsFolder,
		})
	end
	Props.StringLights(decor, L(mastPos.X, 12, mastPos.Z), {
		To = W(16, hangY, hz - 0.4),
		Count = 10,
		Sag = 2.6,
		BulbParent = lightsFolder,
	})

	---------------------------------------------------------------------------
	-- Deko: Laternen, Van, Bäume, Fahrrad, Fässer, Arcade, Briefkasten
	---------------------------------------------------------------------------
	for _, c in { { -hx + 4, -hz + 4 }, { hx - 4, -hz + 4 }, { -hx + 4, hz - 4 } } do
		local pos = V3(c[1], 0, c[2])
		Props.Streetlamp(decor, cframe * CF(pos) * faceLocal(pos, V3(0, 0, 0)), { Height = 12 })
	end
	Props.Van(decor, L(-34, 0, -30, FACE_RIGHT), { Color = Parts.HouseColors[(index % #Parts.HouseColors) + 1] })
	Props.PineTree(decor, L(-18, 0, -40), { Height = 13, Tiers = 3 })
	Props.PineTree(decor, L(43, 0, -12), { Height = 12, Tiers = 3 })
	Props.Bush(decor, L(-43, 0, -19), { Size = 4 })
	Props.Bicycle(decor, L(-17, 0, -24, FACE_RIGHT), { Color = Parts.BulbColors[(index % #Parts.BulbColors) + 1], Lean = 0.12 })
	Props.Barrels(decor, L(17, 0, -42), { Count = 3 })
	Props.ArcadeCabinet(decor, L(44, 0, -2, FACE_LEFT), { Title = "BASE " .. index })
	Props.Mailbox(decor, L(13, 0, -45))

	model.Parent = parent
	return model
end

return Plot
