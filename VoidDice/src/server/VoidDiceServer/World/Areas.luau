--!strict
-- Areas (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > World > Areas
--
-- Baut die Gebiete nördlich des Hubs (alle außer Suburb). Jedes Gebiet hat
-- denselben "Rahmen" (Boden, Tor, Ankunftspunkt, Dice-Altar) und eine eigene
-- Deko-Funktion mit klar unterscheidbarem Look:
--   DarkForest  dichte dunkle Tannen, Camp, abgestürzter Wetterballon, Leuchtpilze
--   SecretLab   Betongelände, Zäune, Laborgebäude mit Sicherheitstür, Tanks, Racks
--   RiftZone    zerbrochener Boden, Neon-Risse, schwebende Brocken und Vorstadt-Trümmer
--   Otherworld  Spiegel-Vorstadt in Türkis/Magenta: Häuser kopfüber am Himmel, Kristalle
--   Void        schwarzer Glasboden, lila Neon-Raster, schwebende Würfel/Ringe, riesiges Auge
--
-- Vertrag mit den Services:
--   <AreaId>                   Model, Attribut AreaId
--     Gate                     Energie-Barriere über der Straße am Südrand
--                              (Attribute AreaId, RequiredRebirths, UnlockCost; CanCollide true)
--     GateFrame/Lintel         SurfaceGui "GateGui" (Title = DisplayName, Subtitle = Rebirth-Info)
--     ArrivalPoint             unsichtbar, knapp hinter dem Tor, schaut nach Norden
--     DiceAltar                Model (Attribut DiceId) mit "PromptPart" und Würfel "Die"
--     Ground, Decor

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local WorldConfig = require(ConfigFolder:WaitForChild("WorldConfig"))
local DiceConfig = require(ConfigFolder:WaitForChild("DiceConfig"))

local Parts = require(script.Parent:WaitForChild("Parts"))
local Props = require(script.Parent:WaitForChild("Props"))

local Palette = Parts.Palette
local V3 = Vector3.new
local CF = CFrame.new
local Mat = Enum.Material

local Areas = {}

type Ctx = {
	Model: Model,
	Decor: Folder,
	Def: any,
	Rng: Random,
	C: Vector3,
	HX: number,
	HZ: number,
	South: number,
	North: number,
	Reserved: { { x: number, z: number, r: number } },
}

-------------------------------------------------------------------------------
-- Platzierungs-Hilfen
-------------------------------------------------------------------------------

local ROAD_CLEAR = WorldConfig.RoadWidth / 2 + 6

local function reserve(ctx: Ctx, x: number, z: number, r: number)
	table.insert(ctx.Reserved, { x = x, z = z, r = r })
end

-- Ist (x, z) frei? (im Gebiet, nicht auf der Straße, nicht in reservierten Kreisen)
local function free(ctx: Ctx, x: number, z: number, r: number): boolean
	local dx, dz = x - ctx.C.X, z - ctx.C.Z
	if math.abs(dx) > ctx.HX - r - 3 or math.abs(dz) > ctx.HZ - r - 3 then
		return false
	end
	if math.abs(dx) < ROAD_CLEAR + r then
		return false
	end
	for _, res in ctx.Reserved do
		local ex, ez = res.x - x, res.z - z
		if ex * ex + ez * ez < (res.r + r) * (res.r + r) then
			return false
		end
	end
	return true
end

-- Verteilt bis zu count Objekte zufällig (deterministisch über ctx.Rng)
local function scatter(ctx: Ctx, count: number, r: number, fn: (x: number, z: number, i: number) -> ())
	local placed, tries = 0, 0
	while placed < count and tries < count * 30 do
		tries += 1
		local x = ctx.C.X + ctx.Rng:NextNumber(-ctx.HX, ctx.HX)
		local z = ctx.C.Z + ctx.Rng:NextNumber(-ctx.HZ, ctx.HZ)
		if free(ctx, x, z, r) then
			placed += 1
			reserve(ctx, x, z, r)
			fn(x, z, placed)
		end
	end
end

local function at(ctx: Ctx, x: number, y: number, z: number): CFrame
	return CF(ctx.C.X + x, WorldConfig.GroundY + y, ctx.C.Z + z)
end

local function yaw(ctx: Ctx): CFrame
	return CFrame.Angles(0, ctx.Rng:NextNumber(0, math.pi * 2), 0)
end

-- Spiegelachse für schwebende Kopfüber-Objekte
local function flipped(cf: CFrame, mirrorY: number): CFrame
	local p = cf.Position
	return CF(p.X, 2 * mirrorY - p.Y, p.Z) * (cf - p) * CFrame.Angles(0, 0, math.pi)
end

local function emitter(ctx: Ctx, cf: CFrame, size: Vector3, opts: Parts.Opts)
	local p = Parts.Invisible(ctx.Decor, cf, size, "ParticleZone", false)
	Parts.Particles(p, opts)
end

-------------------------------------------------------------------------------
-- Gemeinsamer Rahmen: Tor, Ankunft, Altar
-------------------------------------------------------------------------------

local function buildGate(ctx: Ctx)
	local def = ctx.Def
	local gw, gh = WorldConfig.GateWidth, WorldConfig.GateHeight
	local x, z = ctx.C.X, ctx.South
	local gate = Parts.Part({
		Parent = ctx.Model,
		Name = "Gate",
		CFrame = CF(x, WorldConfig.GroundY + gh / 2, z),
		Size = V3(gw, gh, 1.5),
		Color = def.PrimaryColor,
		Material = Mat.ForceField,
		CanCollide = true,
		CastShadow = false,
		Attributes = {
			AreaId = def.Id,
			RequiredRebirths = def.RequiredRebirths,
			UnlockCost = def.UnlockCost,
		},
	})
	gate.CanTouch = true

	local frame = Parts.Model(ctx.Model, "GateFrame")
	local pillarH = gh + 6
	for _, sx in { -1, 1 } do
		local px = x + sx * (gw / 2 + 2)
		Parts.Box(frame, CF(px, pillarH / 2, z), V3(4, pillarH, 4), Palette.MetalDark, Mat.Metal, "Pillar")
		Parts.Neon(frame, CF(px, pillarH / 2, z + 2.05), V3(0.6, pillarH - 2, 0.2), def.PrimaryColor, "PillarGlow")
		Parts.Neon(frame, CF(px, pillarH / 2, z - 2.05), V3(0.6, pillarH - 2, 0.2), def.PrimaryColor, "PillarGlow")
	end
	local lintel = Parts.Box(frame, CF(x, gh + 3, z), V3(gw + 8, 6, 4), Palette.Navy, Mat.Metal, "Lintel")
	local reqText = if def.RequiredRebirths == 1 then "REBIRTH 1 REQUIRED" else ("REBIRTH " .. def.RequiredRebirths .. " REQUIRED")
	Parts.SurfaceLabel(lintel, Enum.NormalId.Back, def.DisplayName, reqText, {
		Name = "GateGui",
		TitleColor = def.PrimaryColor,
		SubtitleColor = Palette.White,
		Background = Palette.Night,
		PixelsPerStud = 16,
	})
	-- Rückseite (aus dem Gebiet heraus gesehen)
	Parts.SurfaceLabel(lintel, Enum.NormalId.Front, "SIGNAL ROAD", "SOUTH", {
		Name = "ExitGui",
		TitleColor = Palette.White,
		Background = Palette.Night,
		PixelsPerStud = 16,
	})
	Parts.Neon(frame, CF(x, gh + 0.2, z), V3(gw, 0.4, 4.2), def.PrimaryColor, "LintelGlow")
end

local function buildAltar(ctx: Ctx)
	local def = ctx.Def
	local dice = nil
	for _, d in DiceConfig.List do
		if d.Area == def.Id then
			dice = d
			break
		end
	end
	local x, z = ctx.C.X - 42, ctx.South - 60
	reserve(ctx, x, z, 16)
	local base = Parts.FaceTowards(V3(x, WorldConfig.GroundY, z), V3(ctx.C.X, WorldConfig.GroundY, z))
	local m = Parts.Model(ctx.Model, "DiceAltar")
	local color = if dice then dice.Color else def.PrimaryColor
	local color2 = if dice then dice.Color2 else def.SecondaryColor
	if dice then
		m:SetAttribute("DiceId", dice.Id)
	end
	Parts.VCyl(m, base * CF(0, 0.5, 0), 1, 16, Palette.MetalDark, Mat.Slate, "Step")
	Parts.VCyl(m, base * CF(0, 1.5, 0), 1, 11, Palette.NavyLight, Mat.Slate, "Step")
	Parts.VCyl(m, base * CF(0, 1.95, 0), 0.2, 11.6, color, Mat.Neon, "StepGlow")
	Parts.Box(m, base * CF(0, 3.5, 0), V3(3.5, 3, 3.5), Palette.Navy, Mat.Slate, "Pillar")
	Parts.Part({
		Parent = m,
		Name = "LightColumn",
		Shape = Enum.PartType.Cylinder,
		CFrame = base * CF(0, 7.5, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Size = V3(5, 2, 2),
		Color = color,
		Material = Mat.Neon,
		Transparency = 0.55,
		CanCollide = false,
	})
	local dieCf = base * CF(0, 12, 0) * CFrame.Angles(math.rad(35.26), 0, math.rad(45))
	local die = Props.Die(m, dieCf, { Name = "Die", Size = 6, Color = color, PipColor = color2 })
	Parts.Ring(m, base * CF(0, 12, 0) * CFrame.Angles(math.rad(90), 0, 0), 6.5, 10, 0.5, 0.5, color, Mat.Neon, "Orbit")
	local core = die.PrimaryPart :: BasePart
	Parts.Light(core, color, 20, 1.6)
	Parts.Billboard(core, if dice then dice.DisplayName else def.DisplayName, if dice then ("LUCK x" .. dice.Luck) else nil, {
		Name = "DiceGui",
		Offset = V3(0, 7, 0),
		Width = 14,
		Height = 4,
		TitleColor = color,
		MaxDistance = 140,
	})
	Parts.Invisible(m, base * CF(0, 3, -7), V3(4, 4, 4), "PromptPart", false)
end

-------------------------------------------------------------------------------
-- DARK FOREST
-------------------------------------------------------------------------------

local function buildDarkForest(ctx: Ctx)
	local d = ctx.Decor
	local rng = ctx.Rng
	local leafColors = { Palette.LeafDark, Color3.fromRGB(24, 48, 34), Color3.fromRGB(16, 34, 26), Color3.fromRGB(26, 40, 36) }

	-- Camp (rechts der Straße)
	local camp = at(ctx, 48, 0, 15)
	reserve(ctx, camp.X, camp.Z, 18)
	local tentCf = camp * CF(-7, 0, -7) * CFrame.Angles(0, math.rad(30), 0)
	Parts.Box(d, tentCf * CF(0, 0.1, 0), V3(7, 0.2, 8), Color3.fromRGB(60, 60, 50), Mat.Fabric, "TentFloor")
	for _, sx in { -1, 1 } do
		Parts.Box(d, tentCf * CF(sx * 1.6, 2.3, 0) * CFrame.Angles(0, 0, sx * math.rad(35)), V3(0.3, 5.6, 8), Palette.Orange, Mat.Fabric, "TentSide")
	end
	for k = 0, 3 do
		local a = k * math.pi / 2 + 0.4
		Props.Rock(d, camp * CF(math.cos(a) * 2.2, 0, math.sin(a) * 2.2), { Rng = rng, Size = 1.2, Parts = 1 })
	end
	for _, r in { 0.5, -0.6 } do
		Parts.Cyl(d, camp * CF(0, 0.4, 0) * CFrame.Angles(0, r, 0), 3.2, 0.6, Palette.Bark, Mat.Wood, "FireLog")
	end
	local flame = Parts.Neon(d, camp * CF(0, 1.3, 0) * CFrame.Angles(0, 0.7, 0), V3(1.4, 2, 1.4), Palette.Orange, "Flame")
	Parts.Neon(d, camp * CF(0, 1.9, 0) * CFrame.Angles(0, 0.2, 0), V3(0.8, 1.4, 0.8), Palette.Yellow, "Flame")
	Parts.Light(flame, Palette.Orange, 26, 2)
	Parts.Particles(flame, { Color = Palette.Orange, Rate = 10, Size = 0.25, Lifetime = 1.5, Speed = 2, Acceleration = V3(0, 4, 0) })
	for _, a in { 0.9, 2.4 } do
		Parts.Cyl(d, camp * CF(math.cos(a) * 5, 0.6, math.sin(a) * 5) * CFrame.Angles(0, a, 0), 4, 1.2, Palette.Bark, Mat.Wood, "SitLog")
	end
	Parts.Box(d, camp * CF(5, 1, -4), V3(2.6, 2, 1.8), Palette.Red, Mat.SmoothPlastic, "Cooler")
	Parts.Neon(d, camp * CF(5, 2.4, -4), V3(0.6, 0.8, 0.6), Palette.Amber, "Lantern")

	-- Abgestürzter Wetterballon (links, weiter hinten)
	local crash = at(ctx, -52, 0, -45)
	reserve(ctx, crash.X, crash.Z, 20)
	Parts.VCyl(d, crash * CF(0, 0.02 - 0.1, 0), 0.2, 22, Color3.fromRGB(20, 20, 18), Mat.Ground, "Scorch")
	local balloon = Parts.Part({
		Parent = d,
		Name = "Balloon",
		CFrame = crash * CF(5, 1.6, 2) * CFrame.Angles(0.15, 0.6, 0.1),
		Size = V3(16, 3.6, 12),
		Color = Color3.fromRGB(230, 230, 220),
		Material = Mat.SmoothPlastic,
		Transparency = 0.15,
		CanCollide = false,
	})
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = balloon
	local payloadCf = crash * CF(-4, 1.2, -2) * CFrame.Angles(0.3, 0.8, 0.25)
	local payload = Parts.Box(d, payloadCf, V3(3, 2.5, 3), Palette.Metal, Mat.Metal, "Payload")
	Parts.SurfaceLabel(payload, Enum.NormalId.Front, "WX-7", "PROBE", { TitleColor = Palette.Red, PixelsPerStud = 30 })
	Parts.Box(d, payloadCf * CF(0, 2.2, 0) * CFrame.Angles(0, math.rad(45), 0), V3(3.6, 0.15, 0.15), Palette.White, Mat.Metal, "Reflector")
	Parts.Box(d, payloadCf * CF(0, 2.2, 0) * CFrame.Angles(0, math.rad(-45), 0), V3(3.6, 0.15, 0.15), Palette.White, Mat.Metal, "Reflector")
	Parts.Ball(d, payloadCf * CF(0, 1.5, 0), 0.6, Palette.Red, Mat.Neon, "Blinker")
	for k = 1, 4 do
		local tip = crash * V3(5 + (k - 2.5) * 3, 2.5, 2 + (k % 2) * 3)
		Parts.Beam(d, payloadCf * V3(0, 1.25, 0), tip, 0.08, Palette.Paper, Mat.Fabric, "Cord")
	end
	for k = 0, 4 do
		local a = k * 1.25
		Props.Rock(d, crash * CF(math.cos(a) * 10, 0, math.sin(a) * 10), { Rng = rng, Size = rng:NextNumber(2, 3.5), Parts = 1, Color = Color3.fromRGB(56, 50, 44) })
	end

	-- Dichte Tannen + tote Bäume
	scatter(ctx, 68, 4.5, function(x, z)
		Props.PineTree(d, CF(x, WorldConfig.GroundY, z) * yaw(ctx), {
			Height = rng:NextNumber(24, 40),
			Tiers = 2,
			Color = leafColors[rng:NextInteger(1, #leafColors)],
			TrunkColor = Color3.fromRGB(46, 34, 28),
		})
	end)
	scatter(ctx, 10, 3, function(x, z)
		Props.DeadTree(d, CF(x, WorldConfig.GroundY, z) * yaw(ctx), { Height = rng:NextNumber(12, 20) })
	end)
	-- Leuchtpilze (auch dicht an der Straße erlaubt -> kleiner Radius)
	local mushroomColors = { Palette.Green, Palette.Cyan, Color3.fromRGB(170, 255, 120) }
	scatter(ctx, 24, 1.2, function(x, z, i)
		Props.Mushroom(d, CF(x, WorldConfig.GroundY, z), { Height = rng:NextNumber(1.2, 3.2), Color = mushroomColors[(i % 3) + 1] })
	end)

	-- Bodennebel + Glühwürmchen
	for k = -1, 1 do
		emitter(ctx, at(ctx, k * 70, 3, k * 50), V3(60, 2, 60), {
			Color = Color3.fromRGB(150, 190, 170),
			Rate = 3,
			Size = 9,
			Lifetime = 10,
			Speed = 0.3,
			Transparency = 0.85,
			LightEmission = 0,
			Acceleration = V3(0.2, 0, 0),
		})
	end
	emitter(ctx, at(ctx, 0, 6, 0), V3(200, 6, 200), { Color = Palette.Green, Rate = 12, Size = 0.25, Lifetime = 4 })
end

-------------------------------------------------------------------------------
-- SECRET LAB
-------------------------------------------------------------------------------

local function buildSecretLab(ctx: Ctx)
	local d = ctx.Decor
	local rng = ctx.Rng
	local wall = Color3.fromRGB(150, 152, 160)
	local hx, hz = ctx.HX, ctx.HZ

	-- Zäune an West- und Ostseite
	for _, sx in { -1, 1 } do
		local fx = sx * (hx - 6)
		local n = 4
		local zSeg = (hz * 2 - 12) / n
		for k = 0, n - 1 do
			local z = -hz + 6 + zSeg / 2 + k * zSeg
			Props.ChainFence(d, at(ctx, fx, 0, z) * CFrame.Angles(0, math.pi / 2, 0), { Length = zSeg, Height = 9 })
		end
		for _, z in { -hz + 30, hz - 30 } do
			Props.WarningLight(d, at(ctx, fx, 0, z), { Height = 10, Color = Palette.Red })
		end
	end

	-- Laborgebäude (West/Nord) mit Sicherheitstür zur Straße
	local bx, bz, bw, bd, bh = -72, -52, 64, 56, 22
	reserve(ctx, ctx.C.X + bx, ctx.C.Z + bz, 46)
	local b = at(ctx, bx, 0, bz)
	Parts.Box(d, b * CF(0, bh / 2, bd / 2 - 1), V3(bw, bh, 2), wall, Mat.Concrete, "LabWall")
	Parts.Box(d, b * CF(0, bh / 2, -bd / 2 + 1), V3(bw, bh, 2), wall, Mat.Concrete, "LabWall")
	Parts.Box(d, b * CF(-bw / 2 + 1, bh / 2, 0), V3(2, bh, bd), wall, Mat.Concrete, "LabWall")
	-- Ostwand mit Toröffnung (12 breit, 12 hoch)
	local seg = (bd - 12) / 2
	for _, sz in { -1, 1 } do
		Parts.Box(d, b * CF(bw / 2 - 1, bh / 2, sz * (6 + seg / 2)), V3(2, bh, seg), wall, Mat.Concrete, "LabWall")
	end
	Parts.Box(d, b * CF(bw / 2 - 1, 12 + (bh - 12) / 2, 0), V3(2, bh - 12, 12), wall, Mat.Concrete, "LabWall")
	Parts.Box(d, b * CF(0, bh + 0.5, 0), V3(bw + 1, 1, bd + 1), Palette.ConcreteDark, Mat.Concrete, "LabRoof")
	for _, sz in { -1, 1 } do
		Parts.Neon(d, b * CF(bw / 2 + 0.05, 16, sz * (6 + seg / 2)), V3(0.2, 2, seg - 4), Color3.fromRGB(180, 230, 255), "WindowBand")
	end
	-- Containment Door (geschlossene Sicherheitstür mit leuchtender Fuge)
	local door = b * CF(bw / 2 + 0.6, 0, 0)
	Parts.Box(d, door * CF(0, 6, -3.2), V3(1, 12, 5.6), Palette.MetalDark, Mat.DiamondPlate, "BlastDoor")
	Parts.Box(d, door * CF(0, 6, 3.2), V3(1, 12, 5.6), Palette.MetalDark, Mat.DiamondPlate, "BlastDoor")
	for _, sz in { -1, 1 } do
		Parts.Box(d, door * CF(0.55, 6, sz * 6.6), V3(0.4, 12, 1.2), Palette.Yellow, Mat.SmoothPlastic, "HazardStripe")
	end
	Parts.Neon(d, door * CF(0.6, 6, 0), V3(0.2, 11, 0.6), Palette.Red, "DoorSeam")
	local doorLight = Parts.Ball(d, door * CF(0.8, 13.2, 0), 1.4, Palette.Red, Mat.Neon, "AlarmLight")
	Parts.Light(doorLight, Palette.Red, 24, 2)
	local facility = Parts.Box(d, door * CF(0.4, 17.5, 0) * CFrame.Angles(0, -math.pi / 2, 0), V3(26, 4, 0.4), Palette.Night, Mat.SmoothPlastic, "FacilitySign")
	Parts.SurfaceLabel(facility, Enum.NormalId.Front, "KESTREL FACILITY", "SECTOR 4 - AUTHORIZED ONLY", {
		TitleColor = Color3.fromRGB(200, 230, 255),
		SubtitleColor = Palette.Red,
		Font = Enum.Font.Michroma,
	})
	for k = -1, 1 do
		Parts.Box(d, b * CF(k * 14, bh + 2.2, k * 10), V3(6, 3.4, 5), Palette.Metal, Mat.Metal, "ACUnit")
	end
	Props.AntennaMast(d, b * CF(-20, bh + 1, -16), { Height = 18 })

	-- Tank-Hof (Ost/Nord)
	local tx, tz = 62, -62
	reserve(ctx, ctx.C.X + tx, ctx.C.Z + tz, 24)
	for row = 0, 1 do
		for col = 0, 2 do
			Props.LabTank(d, at(ctx, tx - 12 + col * 12, 0, tz - 6 + row * 12), {
				Height = 11,
				Diameter = 5,
				LiquidColor = if (row + col) % 2 == 0 then Palette.Cyan else Palette.Green,
			})
		end
	end
	local tankGlow = Parts.Neon(d, at(ctx, tx, 0.06, tz), V3(34, 0.1, 22), Color3.fromRGB(40, 120, 160), "TankYardFloor")
	tankGlow.Transparency = 0.6
	Parts.Light(tankGlow, Palette.Cyan, 30, 1.2)

	-- Server-Hof unter Vordach (Ost/Süd)
	local sx0, sz0 = 62, 22
	reserve(ctx, ctx.C.X + sx0, ctx.C.Z + sz0, 20)
	local yard = at(ctx, sx0, 0, sz0)
	for k = 0, 5 do
		-- Reihe entlang Z, Front zeigt nach Westen (zur Straße)
		Props.ServerRack(d, yard * CF(-2, 0, -12.5 + k * 5) * CFrame.Angles(0, math.pi / 2, 0))
	end
	for _, c in { { -6, -16 }, { 6, -16 }, { -6, 16 }, { 6, 16 } } do
		Parts.Box(d, yard * CF(c[1], 5.5, c[2]), V3(0.8, 11, 0.8), Palette.MetalDark, Mat.Metal, "CanopyPost")
	end
	Parts.Box(d, yard * CF(0, 11.3, 0), V3(16, 0.6, 36), Palette.ConcreteDark, Mat.Metal, "Canopy")

	-- Wachhäuschen am Tor (Osten)
	local gh = at(ctx, 30, 0, hz - 20)
	reserve(ctx, gh.X, gh.Z, 7)
	Parts.Box(d, gh * CF(0, 4, 0), V3(6, 8, 6), wall, Mat.Concrete, "GuardBooth")
	Parts.Glass(d, gh * CF(-3.05, 5, 0), V3(0.2, 3, 4.4), Color3.fromRGB(160, 220, 255), 0.4, "GuardWindow")
	Parts.Box(d, gh * CF(0, 8.3, 0), V3(7, 0.6, 7), Palette.ConcreteDark, Mat.Concrete, "GuardRoof")
	Parts.Neon(d, gh * CF(-3.05, 7.4, 0), V3(0.2, 0.4, 5), Palette.Yellow, "GuardLight")

	-- Suchscheinwerfer-Türme an den Südecken
	for _, sx in { -1, 1 } do
		local t = at(ctx, sx * (hx - 18), 0, hz - 18)
		reserve(ctx, t.X, t.Z, 6)
		Parts.Box(d, t * CF(0, 9, 0), V3(1.4, 18, 1.4), Palette.MetalDark, Mat.Metal, "TowerPole")
		Parts.Box(d, t * CF(0, 18.3, 0), V3(5, 0.6, 5), Palette.MetalDark, Mat.DiamondPlate, "TowerDeck")
		local headCf = t * CF(0, 19.8, 0) * CFrame.Angles(math.rad(-25), sx * math.rad(30), 0)
		Parts.Box(d, headCf, V3(2.2, 2.2, 2.6), Palette.Metal, Mat.Metal, "Searchlight")
		local lens = Parts.Neon(d, headCf * CF(0, 0, -1.35), V3(1.8, 1.8, 0.1), Palette.White, "Lens")
		if sx == 1 then
			Parts.Light(lens, Color3.fromRGB(220, 240, 255), 60, 3, "Spot", Enum.NormalId.Front)
		end
	end

	-- Kleinkram verstreut: Warnschilder, Fässer, Van
	local signTexts = { { "DANGER", "BIOHAZARD" }, { "RESTRICTED", "LEVEL B4" }, { "WARNING", "HIGH VOLTAGE" } }
	scatter(ctx, 6, 3, function(x, z, i)
		local t = signTexts[(i - 1) % #signTexts + 1]
		Props.WarningSign(d, Parts.FaceTowards(V3(x, WorldConfig.GroundY, z), V3(ctx.C.X, WorldConfig.GroundY, z)), { Text = t[1], Subtext = t[2] })
	end)
	scatter(ctx, 3, 5, function(x, z)
		Props.Barrels(d, CF(x, WorldConfig.GroundY, z) * yaw(ctx), { Count = 3, Toxic = true, Color = Color3.fromRGB(200, 170, 40) })
	end)
	scatter(ctx, 1, 10, function(x, z)
		Props.Van(d, CF(x, WorldConfig.GroundY, z) * yaw(ctx), { Color = Palette.White, StripeColor = Palette.MetalDark })
	end)
	scatter(ctx, 6, 3, function(x, z)
		Props.Crate(d, CF(x, WorldConfig.GroundY, z) * yaw(ctx), { Size = rng:NextNumber(2.5, 4), Color = Color3.fromRGB(90, 110, 80) })
	end)
	-- Bodenmarkierungen (gelbe Streifen)
	for k = -2, 2 do
		Parts.Detail(d, at(ctx, 40, 0.0, k * 30), V3(20, 0.08, 0.8), Palette.Yellow, Mat.SmoothPlastic, "FloorMark")
	end
end

-------------------------------------------------------------------------------
-- RIFT ZONE
-------------------------------------------------------------------------------

local function buildRiftZone(ctx: Ctx)
	local d = ctx.Decor
	local rng = ctx.Rng
	local def = ctx.Def
	local rock = Color3.fromRGB(52, 40, 74)

	-- Senkrechte Risse ("Rift Tears") zuerst, damit sie Platz reservieren
	local tears = { { -70, -20 }, { 75, -70 }, { -90, 95 }, { 60, 50 }, { -60, -95 } }
	for i, t in tears do
		reserve(ctx, ctx.C.X + t[1], ctx.C.Z + t[2], 16)
		local cf = at(ctx, t[1], 0, t[2]) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
		local tear = Props.RiftCrack(d, cf, { Length = rng:NextNumber(18, 30), Width = 2.2, Vertical = true, Color = def.PrimaryColor, Rng = rng })
		if i <= 2 then
			local first = tear:FindFirstChild("Crack") :: BasePart?
			if first then
				Parts.Light(first, def.PrimaryColor, 30, 2.4)
				Parts.Particles(first, { Color = def.SecondaryColor, Rate = 10, Size = 0.4 })
			end
		end
	end
	-- Zerbrochener Boden: gekippte Schollen mit leuchtenden Fugen
	scatter(ctx, 14, 11, function(x, z)
		local sx, sz = rng:NextNumber(14, 24), rng:NextNumber(12, 20)
		local tilt = CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(0, 6.28), rng:NextNumber(-0.12, 0.12))
		local baseCf = CF(x, WorldConfig.GroundY, z) * tilt
		Parts.Neon(d, CF(x, WorldConfig.GroundY - 0.05, z) * (tilt - tilt.Position), V3(sx + 1.6, 0.2, sz + 1.6), def.PrimaryColor, "Seam")
		Parts.Box(d, baseCf * CF(0, rng:NextNumber(0.4, 2.2), 0), V3(sx, 2.4, sz), rock, Mat.Slate, "Slab")
	end)
	-- Risse im Boden
	scatter(ctx, 16, 6, function(x, z, i)
		Props.RiftCrack(d, CF(x, WorldConfig.GroundY, z) * yaw(ctx), {
			Length = rng:NextNumber(10, 22),
			Width = rng:NextNumber(0.8, 1.6),
			Color = if i % 3 == 0 then def.SecondaryColor else def.PrimaryColor,
			Rng = rng,
		})
	end)
	-- Schwebende Erdschollen
	for _ = 1, 14 do
		local x = rng:NextNumber(-ctx.HX + 10, ctx.HX - 10)
		local z = rng:NextNumber(-ctx.HZ + 10, ctx.HZ - 10)
		Props.FloatingIsland(d, at(ctx, x, rng:NextNumber(22, 70), z) * yaw(ctx) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), 0, rng:NextNumber(-0.2, 0.2)), {
			Size = rng:NextNumber(8, 18),
			Color = rock,
			TopColor = Color3.fromRGB(70, 56, 96),
		})
	end
	-- Schwebende Trümmer
	for _ = 1, 18 do
		local x = rng:NextNumber(-ctx.HX + 6, ctx.HX - 6)
		local z = rng:NextNumber(-ctx.HZ + 6, ctx.HZ - 6)
		Props.FloatingDebris(d, at(ctx, x, rng:NextNumber(10, 45), z), { Rng = rng, Count = 3, Color = rock, Size = rng:NextNumber(1.5, 3.5) })
	end
	-- Vorstadt-Trümmer, mitten in der Luft
	local function tilted(x: number, y: number, z: number): CFrame
		return at(ctx, x, y, z) * CFrame.Angles(rng:NextNumber(-0.6, 0.6), rng:NextNumber(0, 6.28), rng:NextNumber(-0.6, 0.6))
	end
	Props.Van(d, tilted(55, 24, 5), { Color = Color3.fromRGB(120, 90, 60) })
	Props.House(d, at(ctx, -62, 30, -40) * CFrame.Angles(0.35, 0.8, -0.25), { Color = Parts.HouseColors[2], Lit = false, Width = 20 })
	Props.Streetlamp(d, tilted(-30, 30, 30), { Height = 12, Color = def.SecondaryColor })
	Props.Mailbox(d, tilted(35, 18, 60))
	Props.Bicycle(d, tilted(-38, 16, 15), { Color = Palette.Red })
	Props.PicketFence(d, tilted(48, 36, -40), { Length = 10 })
	Props.ArcadeCabinet(d, tilted(-55, 20, 50), { Title = "RIFT KONG" })
	Props.CRT(d, tilted(28, 14, -12), { Text = "NO SIGNAL" })
	Props.Bench(d, tilted(-28, 22, -75))

	-- Zackige Felsnadeln an den Rändern
	for _, sx in { -1, 1 } do
		for k = 0, 11 do
			local z = -ctx.HZ + 10 + k * (ctx.HZ * 2 - 20) / 11
			local h = rng:NextNumber(18, 40)
			Parts.Box(d, at(ctx, sx * (ctx.HX - 6), h / 2 - 2, z) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 6.28), sx * rng:NextNumber(0.05, 0.25)), V3(rng:NextNumber(5, 9), h, rng:NextNumber(5, 9)), rock, Mat.Slate, "Spire")
		end
	end
	emitter(ctx, at(ctx, 0, 10, 0), V3(220, 10, 200), { Color = def.PrimaryColor, Rate = 14, Size = 0.35, Lifetime = 6 })
	emitter(ctx, at(ctx, 0, 30, 0), V3(220, 20, 200), { Color = def.SecondaryColor, Rate = 6, Size = 0.6, Lifetime = 8, Acceleration = V3(0, 1, 0) })
end

-------------------------------------------------------------------------------
-- OTHERWORLD (Spiegel-Vorstadt, Türkis/Magenta, kristallin)
-------------------------------------------------------------------------------

local function buildOtherworld(ctx: Ctx)
	local d = ctx.Decor
	local rng = ctx.Rng
	local def = ctx.Def
	local teal, magenta = def.PrimaryColor, def.SecondaryColor
	local mirrorY = 36
	local houseColors = { Color3.fromRGB(30, 70, 76), Color3.fromRGB(46, 60, 84), Color3.fromRGB(36, 84, 80), Color3.fromRGB(60, 44, 76) }

	-- Häuser an der Straße + ihre Kopfüber-Spiegelbilder am Himmel
	local houses = { { -50, 15 }, { -50, -55 }, { 50, 70 }, { 50, 0 }, { 50, -70 } }
	for i, h in houses do
		local pos = at(ctx, h[1], 0, h[2])
		reserve(ctx, pos.X, pos.Z, 17)
		local cf = Parts.FaceTowards(pos.Position, V3(ctx.C.X, WorldConfig.GroundY, pos.Z))
		local opts = {
			Width = 22,
			Depth = 16,
			Height = 10,
			Color = houseColors[(i - 1) % #houseColors + 1],
			RoofColor = Color3.fromRGB(20, 30, 40),
			WindowColor = if i % 2 == 0 then magenta else teal,
			Garage = i % 2 == 1,
		}
		Props.House(d, cf, opts)
		Props.House(d, flipped(cf, mirrorY), opts)
		-- Kristalle wachsen aus dem Vorgarten
		Props.Crystal(d, cf * CF(rng:NextNumber(-8, 8), 0, -15), { Height = rng:NextNumber(5, 9), Color = magenta, Color2 = teal, Rng = rng })
	end
	-- Kristall-Spitzen
	scatter(ctx, 10, 6, function(x, z, i)
		Props.Crystal(d, CF(x, WorldConfig.GroundY, z), {
			Height = rng:NextNumber(18, 32),
			Color = if i % 2 == 0 then teal else magenta,
			Color2 = if i % 2 == 0 then magenta else teal,
			Rng = rng,
		})
	end)
	scatter(ctx, 16, 2.5, function(x, z, i)
		Props.Crystal(d, CF(x, WorldConfig.GroundY, z), { Height = rng:NextNumber(4, 9), Color = if i % 2 == 0 then teal else magenta, Rng = rng })
	end)
	-- Türkise Bäume + ihre Spiegelbilder
	scatter(ctx, 6, 5, function(x, z)
		local cf = CF(x, WorldConfig.GroundY, z) * yaw(ctx)
		local opts = { Height = rng:NextNumber(18, 26), Tiers = 3, Color = Color3.fromRGB(20, 110, 100), TrunkColor = Color3.fromRGB(40, 30, 60) }
		Props.PineTree(d, cf, opts)
		Props.PineTree(d, flipped(cf, mirrorY + 4), opts)
	end)
	-- Kopfüber hängende Laternen über der Straße
	for k = 0, 3 do
		local z = ctx.HZ - 40 - k * 50
		local side = if k % 2 == 0 then -1 else 1
		local pos = at(ctx, side * 22, 0, z)
		local cf = Parts.FaceTowards(pos.Position, V3(ctx.C.X, WorldConfig.GroundY, pos.Z))
		Props.Streetlamp(d, flipped(cf, mirrorY + 6), { Height = 14, Color = magenta })
	end
	-- Schwebende Kristallsplitter
	for _ = 1, 10 do
		local cf = at(ctx, rng:NextNumber(-ctx.HX + 10, ctx.HX - 10), rng:NextNumber(20, 60), rng:NextNumber(-ctx.HZ + 10, ctx.HZ - 10))
		Parts.Neon(d, cf * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), 0), V3(1.2, rng:NextNumber(4, 9), 1.2), if rng:NextNumber() < 0.5 then teal else magenta, "FloatingShard")
	end
	-- Spiegelsee
	local lake = at(ctx, -62, 0, -100 + 10)
	reserve(ctx, lake.X, lake.Z, 20)
	local mirror = Parts.Part({
		Parent = d,
		Name = "MirrorLake",
		CFrame = lake * CF(0, 0.1 - 0.15, 0),
		Size = V3(40, 0.3, 26),
		Color = Color3.fromRGB(20, 60, 70),
		Material = Mat.Glass,
		Reflectance = 0.6,
		Transparency = 0.1,
	})
	Parts.Light(mirror, teal, 30, 1.5)
	for _, e in { { 0, -13.4, 41, 0.8 }, { 0, 13.4, 41, 0.8 } } do
		Parts.Neon(d, lake * CF(e[1], 0.08, e[2]), V3(e[3], 0.16, e[4]), magenta, "LakeRim")
	end
	for _, sx in { -1, 1 } do
		Parts.Neon(d, lake * CF(sx * 20.4, 0.08, 0), V3(0.8, 0.16, 26), magenta, "LakeRim")
	end
	-- Sporen
	emitter(ctx, at(ctx, 0, 8, 0), V3(220, 14, 200), { Color = teal, Rate = 18, Size = 0.3, Lifetime = 7, Speed = 0.4 })
	emitter(ctx, at(ctx, 0, 30, 0), V3(220, 20, 200), { Color = magenta, Rate = 10, Size = 0.45, Lifetime = 9, Acceleration = V3(0, -0.6, 0) })
	emitter(ctx, at(ctx, 0, 55, 0), V3(220, 10, 200), { Color = teal, Rate = 8, Size = 0.5, Lifetime = 9, Acceleration = V3(0, -1, 0) })
end

-------------------------------------------------------------------------------
-- THE VOID
-------------------------------------------------------------------------------

local function buildVoid(ctx: Ctx)
	local d = ctx.Decor
	local rng = ctx.Rng
	local def = ctx.Def
	local purple = def.PrimaryColor
	local magenta = Color3.fromRGB(220, 60, 255)

	-- Neon-Raster auf dem Glasboden
	local step = 20
	local x = -ctx.HX + step
	while x < ctx.HX do
		Parts.Neon(d, at(ctx, x, 0.0, 0), V3(0.4, 0.08, ctx.HZ * 2), purple, "GridLine")
		x += step
	end
	local z = -ctx.HZ + step
	while z < ctx.HZ do
		Parts.Neon(d, at(ctx, 0, 0.0, z), V3(ctx.HX * 2, 0.08, 0.4), purple, "GridLine")
		z += step
	end

	-- Endplattform der Straße + riesiges Auge darüber
	local endZ = -ctx.HZ + 40
	Parts.VCyl(d, at(ctx, 0, 0.12 - 0.5, endZ - 6), 1, 50, Color3.fromRGB(16, 8, 30), Mat.Glass, "EndPlatform")
	Parts.VCyl(d, at(ctx, 0, 0.1 - 0.5, endZ - 6), 1, 52, purple, Mat.Neon, "EndRing")
	local eyeCf = at(ctx, 0, 58, -ctx.HZ + 18) -- schaut nach Süden (+Z) -> Rotation 180°
		* CFrame.Angles(0, math.pi, 0)
	Parts.Ring(d, eyeCf, 34, 24, 2.2, 3, purple, Mat.Neon, "EyeRing")
	Parts.Ring(d, eyeCf * CF(0, 0, 1), 27, 20, 1.2, 2, magenta, Mat.Neon, "EyeRingInner")
	local iris = Parts.Part({
		Parent = d,
		Name = "Iris",
		Shape = Enum.PartType.Cylinder,
		CFrame = eyeCf * CF(0, 0, 0.5) * CFrame.Angles(0, math.pi / 2, 0),
		Size = V3(0.6, 30, 30),
		Color = Color3.fromRGB(150, 60, 255),
		Material = Mat.Neon,
		Transparency = 0.1,
		CanCollide = false,
	})
	Parts.Light(iris, purple, 60, 3)
	Parts.Part({
		Parent = d,
		Name = "Pupil",
		Shape = Enum.PartType.Cylinder,
		CFrame = eyeCf * CF(0, 0, -0.2) * CFrame.Angles(0, math.pi / 2, 0),
		Size = V3(1, 12, 12),
		Color = Palette.Black,
		Material = Mat.Glass,
		CanCollide = false,
	})
	Parts.Ball(d, eyeCf * CF(3.5, 3.5, -0.9), 2.6, Palette.White, Mat.Neon, "Glint")
	-- Lider: zwei Bögen eines größeren Kreises
	for _, sy in { -1, 1 } do
		local center = eyeCf * CF(0, -sy * 30, 0)
		-- Bogen von -54° bis +54°: trifft die Lid-Gegenseite bei y = 0 (Augenwinkel)
		for k = -6, 5 do
			local a0, a1 = math.rad(k * 9), math.rad((k + 1) * 9)
			local p0 = center * V3(math.sin(a0) * 52, sy * math.cos(a0) * 52, 0)
			local p1 = center * V3(math.sin(a1) * 52, sy * math.cos(a1) * 52, 0)
			Parts.Beam(d, p0, p1, 1.6, magenta, Mat.Neon, "EyeLid")
		end
	end

	-- Riesige schwebende Würfel (schwarzes Glas mit leuchtendem Kern)
	for _ = 1, 12 do
		local s = rng:NextNumber(8, 22)
		local cf = at(ctx, rng:NextNumber(-ctx.HX + 15, ctx.HX - 15), rng:NextNumber(24, 80), rng:NextNumber(-ctx.HZ + 50, ctx.HZ - 15))
			* CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28))
		Parts.Glass(d, cf, V3(s, s, s), Color3.fromRGB(10, 4, 20), 0.25, "VoidCube")
		Parts.Neon(d, cf, V3(s * 0.6, s * 0.6, s * 0.6), if rng:NextNumber() < 0.5 then purple else magenta, "VoidCore")
	end
	-- Schwebende Ringe
	for _ = 1, 5 do
		local cf = at(ctx, rng:NextNumber(-ctx.HX + 25, ctx.HX - 25), rng:NextNumber(26, 60), rng:NextNumber(-ctx.HZ + 60, ctx.HZ - 30))
			* CFrame.Angles(rng:NextNumber(-1, 1), rng:NextNumber(0, 6.28), 0)
		Parts.Ring(d, cf, rng:NextNumber(9, 16), 12, 1, 1.4, if rng:NextNumber() < 0.5 then purple else Palette.Cyan, Mat.Neon, "VoidRing")
	end
	-- Treppe ins Nichts
	local stairBase = at(ctx, 60, 0, 30) * CFrame.Angles(0, math.rad(-30), 0)
	reserve(ctx, ctx.C.X + 60, ctx.C.Z + 30 - 15, 22)
	for k = 0, 11 do
		Parts.Box(d, stairBase * CF(0, 1 + k * 2.2, -k * 3), V3(8, 1, 3), Color3.fromRGB(20, 10, 36), Mat.Glass, "FloatingStep")
	end
	-- Obelisken
	scatter(ctx, 10, 5, function(ox, oz)
		local h = rng:NextNumber(16, 34)
		local cf = CF(ox, WorldConfig.GroundY + h / 2 + rng:NextNumber(2, 8), oz) * yaw(ctx)
		Parts.Box(d, cf, V3(4, h, 4), Color3.fromRGB(12, 6, 22), Mat.Glass, "Obelisk")
		Parts.Neon(d, cf * CF(0, 0, -2.05), V3(0.5, h - 2, 0.1), purple, "ObeliskGlow")
	end)
	emitter(ctx, at(ctx, 0, 12, 0), V3(220, 20, 200), { Color = purple, Rate = 16, Size = 0.3, Lifetime = 8, Acceleration = V3(0, 0.8, 0) })
	emitter(ctx, at(ctx, 0, 4, 0), V3(220, 4, 200), { Color = Palette.White, Rate = 6, Size = 0.15, Lifetime = 5, Speed = 0.2 })
end

local BUILDERS: { [string]: (Ctx) -> () } = {
	DarkForest = buildDarkForest,
	SecretLab = buildSecretLab,
	RiftZone = buildRiftZone,
	Otherworld = buildOtherworld,
	Void = buildVoid,
}

-------------------------------------------------------------------------------
-- Build
-------------------------------------------------------------------------------

function Areas.Build(def: any, parent: Instance, rng: Random?): Model
	local model = Parts.Model(nil, def.Id)
	model:SetAttribute("AreaId", def.Id)
	local decor = Parts.Folder(model, "Decor")
	local c = def.Center
	local hx, hz = def.Size.X / 2, def.Size.Z / 2
	local ctx: Ctx = {
		Model = model,
		Decor = decor,
		Def = def,
		Rng = rng or Random.new(4000 + def.Order),
		C = V3(c.X, WorldConfig.GroundY, c.Z),
		HX = hx,
		HZ = hz,
		South = c.Z + hz,
		North = c.Z - hz,
		Reserved = {},
	}

	Parts.Part({
		Parent = model,
		Name = "Ground",
		CFrame = CF(c.X, WorldConfig.GroundY - 0.1 - 2, c.Z),
		Size = V3(def.Size.X, 4, def.Size.Z),
		Color = def.GroundColor,
		Material = def.GroundMaterial,
	})

	buildGate(ctx)
	Parts.Invisible(model, CF(c.X, WorldConfig.GroundY + 3, ctx.South - 14), V3(4, 1, 4), "ArrivalPoint", false)
	buildAltar(ctx)

	local builder = BUILDERS[def.Id]
	if builder then
		builder(ctx)
	end

	model.Parent = parent
	return model
end

return Areas
