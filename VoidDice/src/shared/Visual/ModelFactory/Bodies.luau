--!strict
-- Bodies (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Visual > ModelFactory > Bodies
--
-- Körper-Bauer für Visual.Body. Alle Maße sind "unskaliert" (Boden = y 0,
-- vorne = -Z, rechts = +X); der Builder rechnet Visual.Scale ein.
--
-- Body-Vokabular:
--   Kid        kleiner Mensch, großer Kopf
--   Teen       Jugendlicher
--   Adult      Erwachsener
--   Tall       groß, schlank, langer Hals
--   Bulky      breit, kräftig, Blockkopf
--   Shade      dünn, sehr groß, lange Glieder, spitze Füße
--   Colossus   riesiger Humanoid mit Schulterplatten und Brustkern
--   Quadruped  Vierbeiner mit Schnauze, Ohren und Schwanz
--   Crawler    Insekt mit 6 Beinen
--   Blob       Schleim-/Klumpenwesen (pulsierender Core)
--   Serpent    aufgerichtete Schlange aus Segmenten, Tail am Boden
--   Winged     schwebender Flieger (Motte/Fledermaus) mit WingL/WingR
--   Hive       Zellhaufen mit Tentakeln, leuchtendem Core und Insektenschwarm (Orbit)
--   Floating   schwebende Kutten-Gestalt ohne Beine
--   Orb        leuchtender Kern mit Glashülle und Orbit-Ringen
--   Eye        riesiges Auge mit Lidern und Tentakel-Beinen
--
-- Jeder Bauer gibt eine Anchors-Tabelle zurück, an der Faces/Hair/Accessories
-- andocken (Head, Face, Top, Torso, Back, Waist, HandR/HandL, Feet, Under,
-- TailRoot, Center, OrbitR, Parts ...). Fehlende Anker = Accessory wird übersprungen.

local Bodies = {}

local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rgb = Color3.fromRGB

local UPRIGHT = ANG(0, 0, math.pi / 2) -- Zylinderachse senkrecht
local FORWARD = ANG(0, math.pi / 2, 0) -- Zylinderachse entlang Z
local BACKFACE = ANG(0, math.pi, 0) -- LookVector nach +Z (Rückseite)
local UPFACE = ANG(math.pi / 2, 0, 0) -- LookVector nach +Y (Oberseite)

Bodies.UPRIGHT = UPRIGHT
Bodies.FORWARD = FORWARD

-- Part-Budget (inkl. Root und Joints). Menschen 45, große Entities 80.
Bodies.Budget = {
	Kid = 45,
	Teen = 45,
	Adult = 45,
	Tall = 45,
	Bulky = 45,
	Shade = 45,
	Quadruped = 60,
	Crawler = 60,
	Blob = 60,
	Serpent = 60,
	Winged = 60,
	Hive = 80,
	Floating = 80,
	Colossus = 80,
	Orb = 80,
	Eye = 80,
}

Bodies.Humanoid = {
	Kid = true,
	Teen = true,
	Adult = true,
	Tall = true,
	Bulky = true,
	Shade = true,
	Colossus = true,
}

Bodies.DefaultFace = {
	Kid = "Smile",
	Teen = "Smile",
	Adult = "Calm",
	Tall = "Calm",
	Bulky = "Determined",
	Shade = "GlowEyes",
	Colossus = "GlowEyes",
	Quadruped = "GlowEyes",
	Crawler = "ManyEyes",
	Blob = "Grin",
	Serpent = "GlowEyes",
	Winged = "GlowEyes",
	Hive = "ManyEyes",
	Floating = "Hollow",
	Orb = "Blank",
	Eye = "Blank",
}

local HUMAN_DEFAULTS = {
	Skin = rgb(234, 192, 150),
	Hair = rgb(70, 45, 30),
	Top = rgb(60, 90, 170),
	Bottom = rgb(50, 55, 80),
	Shoes = rgb(225, 225, 230),
	Accent = rgb(200, 60, 60),
	Glow = rgb(120, 200, 255),
}
local CREATURE_DEFAULTS = {
	Skin = rgb(70, 80, 64),
	Hair = rgb(40, 40, 40),
	Top = rgb(50, 58, 46),
	Bottom = rgb(40, 44, 36),
	Shoes = rgb(30, 30, 30),
	Accent = rgb(120, 130, 90),
	Glow = rgb(170, 255, 120),
}
local ENTITY_DEFAULTS = {
	Skin = rgb(220, 225, 240),
	Hair = rgb(20, 16, 30),
	Top = rgb(26, 20, 40),
	Bottom = rgb(16, 12, 26),
	Shoes = rgb(10, 8, 16),
	Accent = rgb(140, 80, 255),
	Glow = rgb(180, 120, 255),
}

Bodies.Defaults = {
	Kid = HUMAN_DEFAULTS,
	Teen = HUMAN_DEFAULTS,
	Adult = HUMAN_DEFAULTS,
	Tall = HUMAN_DEFAULTS,
	Bulky = HUMAN_DEFAULTS,
	Shade = ENTITY_DEFAULTS,
	Colossus = ENTITY_DEFAULTS,
	Quadruped = CREATURE_DEFAULTS,
	Crawler = CREATURE_DEFAULTS,
	Blob = CREATURE_DEFAULTS,
	Serpent = CREATURE_DEFAULTS,
	Winged = CREATURE_DEFAULTS,
	Hive = CREATURE_DEFAULTS,
	Floating = ENTITY_DEFAULTS,
	Orb = ENTITY_DEFAULTS,
	Eye = ENTITY_DEFAULTS,
}

local BLACK = rgb(18, 14, 22)

-- Block/Zylinder von a nach b (unskalierte Model-Koordinaten)
local function segment(ctx: any, parent: Instance, name: string, a: Vector3, b: Vector3, thickness: number, color: Color3, material: Enum.Material?, shape: string?): BasePart
	local dir = b - a
	local len = dir.Magnitude
	local mid = (a + b) / 2
	local up = if math.abs(dir.Unit.Y) > 0.98 then V3(0, 0, 1) else V3(0, 1, 0)
	local cf = CFrame.lookAt(mid, b, up)
	if shape == "Cyl" then
		return ctx:Part(parent, name, "Cyl", V3(len, thickness, thickness), cf * FORWARD, color, material)
	end
	return ctx:Part(parent, name, "Block", V3(thickness, thickness, len), cf, color, material)
end
Bodies.Segment = segment

-- Ring aus Segmenten (für Orb-Ringe, Halos usw.)
local function ring(ctx: any, parent: Instance, name: string, center: CFrame, radius: number, thickness: number, segments: number, color: Color3, material: Enum.Material?, role: string?)
	local segLen = 2 * math.pi * radius / segments * 1.08
	for i = 0, segments - 1 do
		local theta = (i / segments) * math.pi * 2
		ctx:Part(parent, name, "Block", V3(segLen, thickness, thickness), center * ANG(0, theta, 0) * CF(0, 0, -radius), color, material, if role then { Role = role } else nil)
	end
end
Bodies.Ring = ring

-------------------------------------------------------------------------------
-- Humanoide
-------------------------------------------------------------------------------
type HumanParams = {
	ShoeH: number,
	LegH: number,
	LegW: number,
	LegD: number,
	LegGap: number,
	TorsoW: number,
	TorsoH: number,
	TorsoD: number,
	ArmW: number,
	ArmD: number,
	ArmL: number,
	HandH: number,
	HeadH: number,
	HeadW: number,
	HeadD: number,
	HeadShape: string,
	Neck: number,
	ShoeShape: string?,
}

local PARAMS: { [string]: HumanParams } = {
	Kid = { ShoeH = 0.28, LegH = 1.05, LegW = 0.62, LegD = 0.68, LegGap = 0.04, TorsoW = 1.5, TorsoH = 1.25, TorsoD = 0.8,
		ArmW = 0.48, ArmD = 0.5, ArmL = 1.25, HandH = 0.36, HeadH = 1.12, HeadW = 1.28, HeadD = 1.28, HeadShape = "Cyl", Neck = 0 },
	Teen = { ShoeH = 0.3, LegH = 1.45, LegW = 0.66, LegD = 0.7, LegGap = 0.05, TorsoW = 1.65, TorsoH = 1.5, TorsoD = 0.85,
		ArmW = 0.52, ArmD = 0.54, ArmL = 1.5, HandH = 0.38, HeadH = 1.05, HeadW = 1.15, HeadD = 1.15, HeadShape = "Cyl", Neck = 0 },
	Adult = { ShoeH = 0.32, LegH = 1.75, LegW = 0.74, LegD = 0.78, LegGap = 0.06, TorsoW = 1.9, TorsoH = 1.8, TorsoD = 0.95,
		ArmW = 0.6, ArmD = 0.62, ArmL = 1.75, HandH = 0.42, HeadH = 1.05, HeadW = 1.1, HeadD = 1.1, HeadShape = "Cyl", Neck = 0.05 },
	Tall = { ShoeH = 0.3, LegH = 2.3, LegW = 0.6, LegD = 0.66, LegGap = 0.08, TorsoW = 1.6, TorsoH = 2.0, TorsoD = 0.8,
		ArmW = 0.5, ArmD = 0.52, ArmL = 2.1, HandH = 0.4, HeadH = 1.15, HeadW = 1.0, HeadD = 1.0, HeadShape = "Cyl", Neck = 0.15 },
	Bulky = { ShoeH = 0.36, LegH = 1.6, LegW = 0.92, LegD = 0.95, LegGap = 0.08, TorsoW = 2.6, TorsoH = 2.0, TorsoD = 1.4,
		ArmW = 0.8, ArmD = 0.82, ArmL = 1.85, HandH = 0.5, HeadH = 1.05, HeadW = 1.1, HeadD = 1.05, HeadShape = "Block", Neck = 0 },
	Shade = { ShoeH = 0.22, LegH = 2.9, LegW = 0.42, LegD = 0.45, LegGap = 0.14, TorsoW = 1.3, TorsoH = 2.3, TorsoD = 0.6,
		ArmW = 0.36, ArmD = 0.38, ArmL = 3.1, HandH = 0.6, HeadH = 1.35, HeadW = 0.82, HeadD = 0.85, HeadShape = "Block", Neck = 0.3,
		ShoeShape = "Wedge" },
	Colossus = { ShoeH = 0.5, LegH = 2.4, LegW = 1.25, LegD = 1.3, LegGap = 0.12, TorsoW = 3.4, TorsoH = 2.9, TorsoD = 1.8,
		ArmW = 1.15, ArmD = 1.2, ArmL = 3.0, HandH = 0.7, HeadH = 1.4, HeadW = 1.4, HeadD = 1.35, HeadShape = "Block", Neck = 0.1 },
}
Bodies.HumanParams = PARAMS

local function humanoid(ctx: any, C: { [string]: Color3 }, P: HumanParams, kind: string)
	local body = ctx.Body
	local parts: { [string]: BasePart } = {}
	local shoeH, legH, legW, legD = P.ShoeH, P.LegH, P.LegW, P.LegD
	local hipY = shoeH + legH
	local tW, tH, tD = P.TorsoW, P.TorsoH, P.TorsoD
	local lx = legW / 2 + P.LegGap / 2

	local feet = {}
	for _, side in { -1, 1 } do
		local nm = if side > 0 then "R" else "L"
		parts["Leg" .. nm] = ctx:Part(body, "Leg" .. nm, "Block", V3(legW, legH + 0.05, legD), CF(side * lx, shoeH + legH / 2, 0), C.Bottom)
		local shoeCF
		if P.ShoeShape == "Wedge" then
			shoeCF = CF(side * lx, shoeH / 2, -0.2)
			parts["Shoe" .. nm] = ctx:Part(body, "Shoe" .. nm, "Wedge", V3(legW + 0.04, shoeH, legD + 0.5), shoeCF, C.Shoes)
		else
			shoeCF = CF(side * lx, shoeH / 2, -0.09)
			parts["Shoe" .. nm] = ctx:Part(body, "Shoe" .. nm, "Block", V3(legW + 0.08, shoeH, legD + 0.2), shoeCF, C.Shoes)
		end
		feet[nm] = shoeCF
	end

	local torsoCF = CF(0, hipY + tH / 2, 0)
	parts.Torso = ctx:Part(body, "Torso", "Block", V3(tW, tH, tD), torsoCF, C.Top)

	-- Arme: Joint an der Schulter, Hand unten
	local armTop = hipY + tH
	local hands = {}
	local arms = {}
	for _, side in { -1, 1 } do
		local nm = if side > 0 then "R" else "L"
		local jx = side * (tW / 2 + P.ArmW / 2 + 0.02)
		local g = ctx:Group("Arm" .. nm, ctx.Model, V3(jx, armTop - P.ArmW / 2, 0))
		local sleeveL = P.ArmL - P.HandH
		parts["Arm" .. nm] = ctx:Part(g, "Arm", "Block", V3(P.ArmW, sleeveL, P.ArmD), CF(jx, armTop - sleeveL / 2, 0), C.Top)
		local handCF = CF(jx, armTop - sleeveL - P.HandH / 2, 0)
		parts["Hand" .. nm] =
			ctx:Part(g, "Hand", "Block", V3(P.ArmW * 0.92, P.HandH, P.ArmD * 0.92), handCF, C.Skin)
		hands[nm] = { Group = g, CF = handCF, W = P.ArmW }
		arms[nm] = { Group = g, Shoulder = CF(jx, armTop, 0), W = P.ArmW, D = P.ArmD }
	end

	-- Kopf
	local neckY = armTop
	local hg = ctx:Group("Head", ctx.Model, V3(0, neckY, 0))
	if P.Neck > 0 then
		ctx:Part(hg, "Neck", "Block", V3(P.HeadW * 0.42, P.Neck + 0.12, P.HeadW * 0.42), CF(0, neckY + P.Neck / 2, 0), C.Skin)
	end
	local hH, hW, hD = P.HeadH, P.HeadW, P.HeadD
	local headCF = CF(0, neckY + P.Neck + hH / 2, 0)
	local round: number? = nil
	if P.HeadShape == "Cyl" then
		parts.Head = ctx:Part(hg, "Head", "Cyl", V3(hH, hW, hW), headCF * UPRIGHT, C.Skin)
		hD = hW
		round = hW / 2
	else
		parts.Head = ctx:Part(hg, "Head", "Block", V3(hW, hH, hD), headCF, C.Skin)
	end
	local total = neckY + P.Neck + hH

	return {
		Kind = kind,
		Parts = parts,
		HipY = hipY,
		Height = total,
		Head = { Group = hg, CF = headCF, Size = V3(hW, hH, hD), Round = round, HairTop = hH / 2 },
		Face = { Group = hg, CF = headCF * CF(0, 0, -hD / 2), W = hW, H = hH, Round = round },
		Top = { Group = hg, CF = headCF * CF(0, hH / 2, 0), W = hW },
		Torso = { Group = body, CF = torsoCF, Size = V3(tW, tH, tD) },
		Back = { Group = body, CF = CF(0, hipY + tH / 2, tD / 2) * BACKFACE, W = tW, H = tH },
		Waist = { Group = body, CF = CF(0, hipY + 0.14, 0), W = tW, D = tD },
		HandR = hands.R,
		HandL = hands.L,
		ArmR = arms.R,
		ArmL = arms.L,
		Feet = { L = feet.L, R = feet.R, W = legW, D = legD, H = shoeH },
		TailRoot = V3(0, hipY + 0.1, tD / 2),
		Center = CF(0, total * 0.55, 0),
		OrbitR = math.max(tW, hW) * 0.5 + P.ArmW + 0.9,
	}
end

local Builders: { [string]: (ctx: any, C: { [string]: Color3 }, visual: any) -> any } = {}

for _, name in { "Kid", "Teen", "Adult", "Tall", "Bulky", "Shade" } do
	Builders[name] = function(ctx: any, C: { [string]: Color3 }, _visual: any)
		return humanoid(ctx, C, PARAMS[name], "Humanoid")
	end
end

Builders.Colossus = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local P = PARAMS.Colossus
	local a = humanoid(ctx, C, P, "Humanoid")
	-- Schulterplatten (bewegen sich mit den Armen)
	for _, side in { -1, 1 } do
		local arm = if side > 0 then a.ArmR else a.ArmL
		ctx:Part(arm.Group, "ShoulderPlate", "Block", V3(P.ArmW + 0.5, 0.55, P.ArmD + 0.45), arm.Shoulder * CF(side * 0.1, 0.12, 0), C.Accent, Enum.Material.Metal)
	end
	-- Gürtel und leuchtender Brustkern
	ctx:Part(ctx.Body, "Belt", "Block", V3(P.TorsoW + 0.1, 0.45, P.TorsoD + 0.1), CF(0, a.HipY + 0.22, 0), C.Accent, Enum.Material.Metal)
	ctx:Part(ctx.Body, "ChestCore", "Cyl", V3(0.12, 0.95, 0.95), CF(0, a.HipY + P.TorsoH * 0.62, -P.TorsoD / 2 - 0.04) * FORWARD, C.Glow, Enum.Material.Neon)
	a.OrbitR += 0.6
	return a
end

-------------------------------------------------------------------------------
-- Kreaturen
-------------------------------------------------------------------------------
Builders.Quadruped = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local body = ctx.Body
	local legH = 1.1
	local bW, bH, bD = 1.3, 1.1, 2.5
	local by = legH + bH / 2 - 0.1
	local parts = {}
	parts.Torso = ctx:Part(body, "Torso", "Block", V3(bW, bH, bD), CF(0, by, 0), C.Skin)
	ctx:Part(body, "Belly", "Block", V3(bW * 0.8, 0.3, bD * 0.75), CF(0, by - bH / 2 - 0.05, -0.05), C.Accent)
	ctx:Part(body, "Hump", "Sphere", V3(bW * 1.08, 0.75, 1.3), CF(0, by + bH / 2 - 0.08, -0.55), C.Top)
	for _, z in { -0.85, 0.85 } do
		for _, side in { -1, 1 } do
			ctx:Part(body, "Leg", "Block", V3(0.38, legH, 0.4), CF(side * 0.42, legH / 2, z), C.Skin)
			ctx:Part(body, "Paw", "Block", V3(0.46, 0.2, 0.52), CF(side * 0.42, 0.1, z - 0.06), C.Shoes)
		end
	end
	-- Kopf
	local hg = ctx:Group("Head", ctx.Model, V3(0, by + 0.3, -bD / 2))
	local headCF = CF(0, by + 0.6, -1.6)
	parts.Head = ctx:Part(hg, "Head", "Block", V3(1.0, 0.9, 1.0), headCF, C.Skin)
	ctx:Part(hg, "Snout", "Block", V3(0.62, 0.45, 0.55), CF(0, by + 0.4, -2.3), C.Accent)
	ctx:Part(hg, "Nose", "Block", V3(0.22, 0.14, 0.08), CF(0, by + 0.56, -2.6), BLACK, nil, { Role = "Eye" })
	for _, side in { -1, 1 } do
		ctx:Part(hg, "Ear", "Wedge", V3(0.22, 0.48, 0.34), CF(side * 0.33, by + 1.27, -1.5), C.Top)
	end
	-- Schwanz
	local tailRoot = V3(0, by + 0.3, bD / 2)
	local tg = ctx:Group("Tail", ctx.Model, tailRoot)
	ctx:Part(tg, "Tail", "Block", V3(0.24, 0.24, 1.25), CF(tailRoot) * ANG(-math.rad(35), 0, 0) * CF(0, 0, 0.6), C.Top)

	return {
		Kind = "Quadruped",
		Parts = parts,
		HipY = legH,
		Height = by + 1.5,
		HasTail = true,
		Head = { Group = hg, CF = headCF, Size = V3(1.0, 0.9, 1.0), HairTop = 0.45 },
		Face = { Group = hg, CF = CF(0, by + 0.77, -2.1), W = 1.0, H = 0.56 },
		Top = { Group = hg, CF = headCF * CF(0, 0.45, 0), W = 0.9 },
		Torso = { Group = body, CF = CF(0, by, 0), Size = V3(bW, bH, bD) },
		Back = { Group = body, CF = CF(0, by + bH / 2, 0.1) * UPFACE, W = bW, H = bD * 0.8 },
		Under = nil,
		TailRoot = tailRoot,
		Center = CF(0, by, 0),
		OrbitR = 2.2,
	}
end

Builders.Crawler = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local body = ctx.Body
	local parts = {}
	parts.Torso = ctx:Part(body, "Thorax", "Sphere", V3(1.2, 0.85, 1.1), CF(0, 1.05, -0.2), C.Skin)
	ctx:Part(body, "Abdomen", "Sphere", V3(1.5, 1.1, 2.0), CF(0, 1.25, 1.2) * ANG(math.rad(-12), 0, 0), C.Top)
	ctx:Part(body, "Stripe", "Sphere", V3(1.56, 0.95, 0.32), CF(0, 1.27, 1.15) * ANG(math.rad(-12), 0, 0), C.Accent)
	-- Beine: zwei Segmente (Hüfte -> Knie -> Fuß)
	local zs = { -0.55, -0.15, 0.3 }
	for i, z in zs do
		for _, side in { -1, 1 } do
			local hip = V3(side * 0.45, 1.0, z)
			local knee = V3(side * 1.25, 1.6, z + (i - 2) * 0.25)
			local foot = V3(side * 1.75, 0.04, z + (i - 2) * 0.6)
			segment(ctx, body, "LegUpper", hip, knee, 0.17, C.Skin)
			segment(ctx, body, "LegLower", knee, foot, 0.12, C.Shoes)
		end
	end
	local hg = ctx:Group("Head", ctx.Model, V3(0, 1.1, -0.75))
	local headCF = CF(0, 1.15, -1.05)
	parts.Head = ctx:Part(hg, "Head", "Sphere", V3(0.85, 0.75, 0.75), headCF, C.Skin)
	return {
		Kind = "Crawler",
		Parts = parts,
		HipY = 1.0,
		Height = 1.9,
		Head = { Group = hg, CF = headCF, Size = V3(0.85, 0.75, 0.75), Round = 0.42, HairTop = 0.38 },
		Face = { Group = hg, CF = CF(0, 1.2, -1.4), W = 0.8, H = 0.6, Round = 0.42 },
		Top = { Group = hg, CF = headCF * CF(0, 0.36, 0), W = 0.7 },
		Torso = { Group = body, CF = CF(0, 1.05, -0.2), Size = V3(1.2, 0.85, 1.1) },
		Back = { Group = body, CF = CF(0, 1.78, 1.1) * UPFACE, W = 1.3, H = 1.6 },
		TailRoot = V3(0, 1.4, 2.15),
		Center = CF(0, 1.2, 0.2),
		OrbitR = 2.4,
	}
end

Builders.Blob = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local body = ctx.Body
	local core = ctx:Group("Core", ctx.Model, V3(0, 1.0, 0))
	local parts = {}
	parts.Torso = ctx:Part(core, "Blob", "Sphere", V3(2.6, 2.1, 2.3), CF(0, 1.05, 0), C.Skin)
	ctx:Part(core, "Lump", "Sphere", V3(1.3, 1.0, 1.2), CF(0.25, 2.0, 0.3), C.Skin)
	ctx:Part(core, "Lump", "Ball", V3(0.95, 0.95, 0.95), CF(-1.15, 0.47, 0.35), C.Top)
	ctx:Part(core, "Lump", "Ball", V3(0.75, 0.75, 0.75), CF(1.15, 0.38, 0.5), C.Top)
	ctx:Part(core, "Spot", "Ball", V3(0.38, 0.38, 0.38), CF(-0.75, 0.55, -0.95), C.Accent)
	ctx:Part(core, "Spot", "Ball", V3(0.3, 0.3, 0.3), CF(0.85, 1.55, -0.7), C.Accent)
	ctx:Part(body, "Puddle", "Cyl", V3(0.08, 3.2, 3.2), CF(0, 0.04, 0.1) * UPRIGHT, C.Bottom, nil, { Transparency = 0.25 })
	return {
		Kind = "Blob",
		Parts = parts,
		HipY = 0.4,
		Height = 2.5,
		Head = { Group = core, CF = CF(0, 1.6, 0), Size = V3(2.0, 1.0, 1.8), HairTop = 0.5 },
		Face = { Group = core, CF = CF(0, 1.25, -1.13), W = 1.7, H = 1.0, Round = 1.15 },
		Top = { Group = core, CF = CF(0.25, 2.5, 0.3), W = 1.1 },
		Torso = { Group = core, CF = CF(0, 1.05, 0), Size = V3(2.6, 2.1, 2.3) },
		Back = { Group = core, CF = CF(0, 1.2, 1.1) * BACKFACE, W = 1.8, H = 1.4 },
		Under = { Group = core, CF = CF(0, 0.35, 0), R = 1.0 },
		TailRoot = V3(0, 0.6, 1.1),
		Center = CF(0, 1.2, 0),
		OrbitR = 2.3,
	}
end

Builders.Serpent = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local body = ctx.Body
	local parts = {}
	parts.Torso = ctx:Part(body, "Coil", "Sphere", V3(2.6, 0.8, 2.6), CF(0, 0.4, 0.5), C.Skin)
	ctx:Part(body, "Coil", "Sphere", V3(2.0, 0.75, 2.0), CF(0.15, 0.98, 0.55), C.Top)
	local spine = {
		{ V3(0.1, 1.55, 0.45), 1.15 },
		{ V3(0, 2.15, 0.2), 1.05 },
		{ V3(-0.05, 2.7, -0.1), 0.95 },
		{ V3(0, 3.2, -0.35), 0.85 },
	}
	for i, s in spine do
		ctx:Part(body, "Segment", "Ball", V3(s[2], s[2], s[2]), CF(s[1]), if i % 2 == 0 then C.Top else C.Skin)
	end
	-- Bauchschuppen vorne am Hals
	ctx:Part(body, "Belly", "Sphere", V3(0.7, 1.6, 0.4), CF(0, 2.4, -0.38) * ANG(math.rad(-15), 0, 0), C.Accent)
	local hg = ctx:Group("Head", ctx.Model, V3(0, 3.45, -0.45))
	local headCF = CF(0, 3.7, -0.85)
	parts.Head = ctx:Part(hg, "Head", "Sphere", V3(1.05, 0.8, 1.5), headCF, C.Skin)
	ctx:Part(hg, "Jaw", "Sphere", V3(0.85, 0.35, 1.2), CF(0, 3.4, -0.98), C.Accent)
	local tailRoot = V3(0.9, 0.35, 1.4)
	local tg = ctx:Group("Tail", ctx.Model, tailRoot)
	ctx:Part(tg, "TailSeg", "Ball", V3(0.62, 0.62, 0.62), CF(1.15, 0.31, 1.62), C.Skin)
	ctx:Part(tg, "TailSeg", "Ball", V3(0.46, 0.46, 0.46), CF(1.45, 0.24, 1.98), C.Top)
	ctx:Part(tg, "TailTip", "Wedge", V3(0.3, 0.28, 0.6), CF(1.62, 0.16, 2.38) * BACKFACE, C.Accent)
	return {
		Kind = "Serpent",
		Parts = parts,
		HipY = 1.0,
		Height = 4.1,
		HasTail = true,
		Head = { Group = hg, CF = headCF, Size = V3(1.05, 0.8, 1.5), Round = 0.5, HairTop = 0.4 },
		Face = { Group = hg, CF = CF(0, 3.84, -1.42), W = 0.9, H = 0.42, Round = 0.5 },
		Top = { Group = hg, CF = headCF * CF(0, 0.4, 0), W = 0.9 },
		Torso = { Group = body, CF = CF(0, 2.2, 0.15), Size = V3(1.05, 1.6, 1.05) },
		Back = { Group = body, CF = CF(0, 2.4, 0.68) * BACKFACE, W = 0.9, H = 1.6 },
		TailRoot = tailRoot,
		Center = CF(0, 2.0, 0),
		OrbitR = 2.4,
	}
end

Builders.Winged = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local body = ctx.Body
	local parts = {}
	parts.Torso = ctx:Part(body, "Thorax", "Sphere", V3(0.95, 1.05, 0.9), CF(0, 2.55, 0), C.Skin)
	ctx:Part(body, "Abdomen", "Sphere", V3(0.75, 1.35, 0.75), CF(0, 1.55, 0.18) * ANG(math.rad(10), 0, 0), C.Top)
	ctx:Part(body, "Collar", "Sphere", V3(1.18, 0.42, 1.05), CF(0, 2.98, 0), C.Accent)
	for _, side in { -1, 1 } do
		segment(ctx, body, "Leg", V3(side * 0.22, 2.2, -0.3), V3(side * 0.32, 1.6, -0.45), 0.1, C.Shoes)
	end
	local hg = ctx:Group("Head", ctx.Model, V3(0, 3.05, 0))
	local headCF = CF(0, 3.4, -0.1)
	parts.Head = ctx:Part(hg, "Head", "Ball", V3(0.8, 0.8, 0.8), headCF, C.Skin)
	-- Flügel: Joint an der Wurzel, große Platte + kleine Platte + Augenfleck
	for _, side in { -1, 1 } do
		local nm = if side > 0 then "R" else "L"
		local root = V3(side * 0.4, 2.7, 0.2)
		local g = ctx:Group("Wing" .. nm, ctx.Model, root)
		local up = CF(root) * ANG(0, 0, side * 0.2)
		ctx:Part(g, "WingUpper", "Block", V3(2.4, 1.7, 0.08), up * CF(side * 1.25, 0.45, 0), C.Top)
		ctx:Part(g, "WingLower", "Block", V3(1.5, 1.2, 0.08), CF(root) * ANG(0, 0, -side * 0.45) * CF(side * 0.85, -0.35, 0.02), C.Accent)
		ctx:Part(g, "EyeSpot", "Cyl", V3(0.1, 0.55, 0.55), up * CF(side * 1.45, 0.5, -0.06) * FORWARD, C.Glow, Enum.Material.Neon, { Role = "Glow" })
	end
	return {
		Kind = "Winged",
		Parts = parts,
		HipY = 1.8,
		Height = 3.8,
		HasWings = true,
		Head = { Group = hg, CF = headCF, Size = V3(0.8, 0.8, 0.8), Round = 0.4, HairTop = 0.4 },
		Face = { Group = hg, CF = CF(0, 3.42, -0.48), W = 0.75, H = 0.6, Round = 0.4 },
		Top = { Group = hg, CF = headCF * CF(0, 0.38, 0), W = 0.7 },
		Torso = { Group = body, CF = CF(0, 2.55, 0), Size = V3(0.95, 1.05, 0.9) },
		Back = { Group = body, CF = CF(0, 2.5, 0.45) * BACKFACE, W = 0.9, H = 1.0 },
		Under = { Group = body, CF = CF(0, 1.0, 0.25), R = 0.3 },
		TailRoot = V3(0, 0.95, 0.3),
		Center = CF(0, 2.3, 0),
		OrbitR = 2.8,
	}
end

Builders.Hive = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local body = ctx.Body
	local parts = {}
	parts.Torso = ctx:Part(body, "Cell", "Sphere", V3(2.4, 1.9, 2.3), CF(0, 0.95, 0), C.Skin)
	local cells = {
		{ V3(1.2, 1.1, 1.2), V3(-1.15, 0.6, -0.35), C.Top },
		{ V3(1.2, 1.0, 1.1), V3(1.1, 0.55, -0.25), C.Top },
		{ V3(1.1, 1.0, 1.1), V3(-0.8, 0.55, 0.95), C.Skin },
		{ V3(1.0, 0.9, 1.0), V3(0.85, 0.5, 0.95), C.Top },
		{ V3(1.4, 1.2, 1.3), V3(0, 1.95, 0.2), C.Skin },
		{ V3(0.8, 0.8, 0.8), V3(-0.6, 2.4, 0.4), C.Top },
	}
	for _, c in cells do
		ctx:Part(body, "Cell", "Sphere", c[1], CF(c[2]), c[3])
	end
	-- Poren
	for _, p in { V3(-1.15, 0.75, -0.93), V3(1.12, 0.65, -0.78), V3(0.45, 2.2, -0.4) } do
		ctx:Part(body, "Pore", "Cyl", V3(0.1, 0.32, 0.32), CF(p) * FORWARD, BLACK, nil, { Role = "Eye" })
	end
	-- Pulsierender Kern
	local core = ctx:Group("Core", ctx.Model, V3(0, 1.5, -0.8))
	ctx:Part(core, "CoreRim", "Cyl", V3(0.15, 1.25, 1.25), CF(0, 1.5, -0.95) * FORWARD, C.Accent)
	ctx:Part(core, "CoreGlow", "Ball", V3(0.95, 0.95, 0.95), CF(0, 1.5, -1.0), C.Glow, Enum.Material.Neon)
	-- Tentakel (2 Segmente + leuchtende Spitze)
	local tendrils = {
		{ V3(0.9, 1.6, 0.3), V3(1.7, 2.6, 0.5), V3(2.0, 3.3, 0.1) },
		{ V3(-0.9, 1.6, 0.3), V3(-1.6, 2.8, 0.6), V3(-1.8, 3.5, 0.2) },
		{ V3(0.4, 2.3, 0.6), V3(0.7, 3.4, 1.1), V3(0.3, 4.0, 1.3) },
		{ V3(-0.3, 1.0, 1.1), V3(-0.4, 1.8, 2.0), V3(-0.2, 2.2, 2.6) },
	}
	for _, t in tendrils do
		segment(ctx, body, "Tendril", t[1], t[2], 0.32, C.Accent, nil, "Cyl")
		segment(ctx, body, "Tendril", t[2], t[3], 0.2, C.Accent, nil, "Cyl")
		ctx:Part(body, "TendrilTip", "Ball", V3(0.28, 0.28, 0.28), CF(t[3]), C.Glow, Enum.Material.Neon)
	end
	-- Schwarm (Orbit)
	local orbit = ctx:GetGroup("Orbit", ctx.Model, V3(0, 2.0, 0))
	local heights = { 1.4, 2.6, 1.9, 3.0, 2.2 }
	for i = 1, 5 do
		local theta = (i - 1) / 5 * math.pi * 2
		ctx:Part(orbit, "Bug", "Ball", V3(0.26, 0.26, 0.26), CF(math.cos(theta) * 2.4, heights[i], math.sin(theta) * 2.4), C.Glow, Enum.Material.Neon)
	end
	return {
		Kind = "Hive",
		Parts = parts,
		HipY = 0.5,
		Height = 4.1,
		Head = nil,
		Face = { Group = body, CF = CF(0, 0.75, -1.12), W = 1.6, H = 0.7, Round = 1.15 },
		Top = { Group = body, CF = CF(0, 2.7, 0.2), W = 1.2 },
		Torso = { Group = body, CF = CF(0, 0.95, 0), Size = V3(2.4, 1.9, 2.3) },
		Back = { Group = body, CF = CF(0, 1.2, 1.15) * BACKFACE, W = 2.0, H = 1.6 },
		Under = { Group = body, CF = CF(0, 0.3, 0), R = 1.2 },
		TailRoot = V3(0, 0.8, 1.3),
		Center = CF(0, 2.0, 0),
		OrbitR = 2.6,
	}
end

-------------------------------------------------------------------------------
-- Entities
-------------------------------------------------------------------------------
Builders.Floating = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local body = ctx.Body
	local parts = {}
	ctx:Part(body, "Hem", "Block", V3(2.0, 1.0, 1.5), CF(0, 1.0, 0), C.Top)
	ctx:Part(body, "Robe", "Block", V3(1.7, 1.4, 1.25), CF(0, 2.15, 0), C.Top)
	parts.Torso = ctx:Part(body, "Chest", "Block", V3(1.9, 1.1, 1.2), CF(0, 3.35, 0), C.Top)
	ctx:Part(body, "Sash", "Block", V3(0.45, 2.7, 0.08), CF(0, 2.35, -0.66), C.Accent)
	ctx:Part(body, "Mantle", "Sphere", V3(2.35, 0.6, 1.5), CF(0, 3.9, 0.02), C.Bottom)
	for i, x in { -0.7, -0.23, 0.23, 0.7 } do
		ctx:Part(body, "Tatter", "Block", V3(0.42, 0.42, 0.42 + (i % 2) * 0.3), CF(x, 0.55 - (i % 2) * 0.08, 0) * ANG(0, 0, math.pi / 4), C.Bottom)
	end
	-- Kapuze
	local hg = ctx:Group("Head", ctx.Model, V3(0, 3.95, 0))
	local hoodCF = CF(0, 4.6, 0.05)
	parts.Head = ctx:Part(hg, "Hood", "Block", V3(1.35, 1.35, 1.3), hoodCF, C.Top)
	ctx:Part(hg, "HoodPeak", "Wedge", V3(1.0, 0.5, 0.95), CF(0, 5.5, 0.22), C.Top)
	ctx:Part(hg, "FaceVoid", "Block", V3(0.95, 0.95, 0.1), CF(0, 4.5, -0.62), BLACK, nil, { Role = "Eye" })
	-- Ärmel
	local hands = {}
	for _, side in { -1, 1 } do
		local nm = if side > 0 then "R" else "L"
		local g = ctx:Group("Arm" .. nm, ctx.Model, V3(side * 1.1, 3.65, 0))
		ctx:Part(g, "Arm", "Block", V3(0.6, 1.5, 0.65), CF(side * 1.15, 3.0, 0), C.Top)
		ctx:Part(g, "Cuff", "Block", V3(0.78, 0.35, 0.8), CF(side * 1.15, 2.2, 0), C.Bottom)
		local handCF = CF(side * 1.15, 1.85, 0)
		ctx:Part(g, "Hand", "Block", V3(0.38, 0.45, 0.38), handCF, C.Skin)
		hands[nm] = { Group = g, CF = handCF, W = 0.6 }
	end
	return {
		Kind = "Floating",
		Parts = parts,
		HipY = 1.5,
		Height = 5.75,
		Head = { Group = hg, CF = hoodCF, Size = V3(1.35, 1.35, 1.3), HairTop = 0.68 },
		Face = { Group = hg, CF = CF(0, 4.5, -0.68), W = 0.9, H = 0.85 },
		Top = { Group = hg, CF = CF(0, 5.3, 0.05), W = 1.2 },
		Torso = { Group = body, CF = CF(0, 3.35, 0), Size = V3(1.9, 1.1, 1.2) },
		Back = { Group = body, CF = CF(0, 3.0, 0.63) * BACKFACE, W = 1.8, H = 2.0 },
		HandR = hands.R,
		HandL = hands.L,
		Under = { Group = body, CF = CF(0, 0.6, 0), R = 0.8 },
		Center = CF(0, 2.9, 0),
		OrbitR = 2.4,
	}
end

Builders.Orb = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local body = ctx.Body
	local cy = 3.0
	local core = ctx:Group("Core", ctx.Model, V3(0, cy, 0))
	local parts = {}
	ctx:Part(core, "Heart", "Ball", V3(1.3, 1.3, 1.3), CF(0, cy, 0), C.Glow, Enum.Material.Neon)
	parts.Torso = ctx:Part(core, "Shell", "Ball", V3(2.2, 2.2, 2.2), CF(0, cy, 0), C.Skin, Enum.Material.Glass, { Transparency = 0.5 })
	ctx:Part(core, "Band", "Cyl", V3(0.25, 2.3, 2.3), CF(0, cy, 0) * UPRIGHT, C.Accent, Enum.Material.Metal)
	local orbit = ctx:GetGroup("Orbit", ctx.Model, V3(0, cy, 0))
	ring(ctx, orbit, "Ring", CF(0, cy, 0) * ANG(0.35, 0, 0.15), 2.1, 0.14, 10, C.Glow, Enum.Material.Neon)
	ring(ctx, orbit, "Ring", CF(0, cy, 0) * ANG(-0.5, 0, -0.3), 2.7, 0.12, 12, C.Accent, Enum.Material.Neon)
	ctx:Part(body, "Projector", "Cyl", V3(0.08, 1.8, 1.8), CF(0, 0.04, 0) * UPRIGHT, C.Accent, Enum.Material.Neon, { Transparency = 0.4 })
	return {
		Kind = "Orb",
		Parts = parts,
		HipY = cy - 1.1,
		Height = cy + 2.8,
		Head = nil,
		Face = { Group = core, CF = CF(0, cy + 0.1, -1.1), W = 1.4, H = 0.8, Round = 1.1 },
		Top = { Group = core, CF = CF(0, cy + 1.1, 0), W = 1.0 },
		Torso = { Group = core, CF = CF(0, cy, 0), Size = V3(2.2, 2.2, 2.2) },
		Back = { Group = core, CF = CF(0, cy, 1.1) * BACKFACE, W = 1.4, H = 1.4 },
		Under = { Group = core, CF = CF(0, cy - 1.0, 0), R = 0.6 },
		Center = CF(0, cy, 0),
		OrbitR = 3.3,
	}
end

Builders.Eye = function(ctx: any, C: { [string]: Color3 }, _visual: any)
	local body = ctx.Body
	local cy = 3.3
	local core = ctx:Group("Core", ctx.Model, V3(0, cy, 0))
	local parts = {}
	parts.Torso = ctx:Part(core, "Eyeball", "Ball", V3(2.6, 2.6, 2.6), CF(0, cy, 0), C.Skin)
	ctx:Part(core, "Iris", "Cyl", V3(0.2, 1.25, 1.25), CF(0, cy, -1.2) * FORWARD, C.Glow, Enum.Material.Neon, { Role = "Eye" })
	ctx:Part(core, "Pupil", "Cyl", V3(0.2, 0.55, 0.55), CF(0, cy, -1.28) * FORWARD, BLACK, nil, { Role = "Eye" })
	ctx:Part(core, "Glint", "Ball", V3(0.2, 0.2, 0.2), CF(0.22, cy + 0.22, -1.38), rgb(255, 255, 255), Enum.Material.Neon, { Role = "Eye" })
	ctx:Part(core, "LidUpper", "Sphere", V3(2.95, 1.1, 2.8), CF(0, cy + 1.15, 0.12), C.Top)
	ctx:Part(core, "LidLower", "Sphere", V3(2.85, 0.9, 2.7), CF(0, cy - 1.18, 0.12), C.Top)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + 0.3
		local cx, cz = math.cos(a), math.sin(a)
		local p0 = V3(cx * 0.5, cy - 1.0, cz * 0.5)
		local p1 = V3(cx * 1.3, cy - 2.1, cz * 1.3)
		local p2 = V3(cx * 2.0, 0.08, cz * 2.0)
		segment(ctx, body, "Tendril", p0, p1, 0.36, C.Accent, nil, "Cyl")
		segment(ctx, body, "Tendril", p1, p2, 0.22, C.Accent, nil, "Cyl")
	end
	return {
		Kind = "Eye",
		Parts = parts,
		HipY = cy - 1.3,
		Height = cy + 1.7,
		Head = nil,
		Face = nil,
		Top = { Group = core, CF = CF(0, cy + 1.7, 0.12), W = 2.0 },
		Torso = { Group = core, CF = CF(0, cy, 0), Size = V3(2.6, 2.6, 2.6) },
		Back = { Group = core, CF = CF(0, cy, 1.35) * BACKFACE, W = 2.0, H = 2.0 },
		Under = { Group = core, CF = CF(0, cy - 1.2, 0), R = 0.7 },
		Center = CF(0, cy, 0),
		OrbitR = 3.4,
	}
end

Bodies.Builders = Builders

-- Sortierte Liste aller Body-Typen (für Tests)
function Bodies.Types(): { string }
	local out = {}
	for name in Builders do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

return Bodies
