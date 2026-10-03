--!strict
-- Accessories (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Visual > ModelFactory > Accessories
--
-- Prozedurale Ausrüstung und Frisuren. Jedes Accessory dockt an einen Anker aus
-- Bodies an (Head, Face, Top, Torso, Back, Waist, HandR/HandL, Feet, Under,
-- TailRoot, Center). Fehlt der Anker, wird das Accessory still übersprungen.
-- Sprengt ein Accessory das Part-Budget, wird es komplett zurückgerollt.
--
-- Hand-Items: das erste kommt als Gruppe "Held" in ArmR (bewegt sich mit dem Arm),
-- das zweite in die linke Hand (ArmL). Items mit "links bevorzugt" (Shield,
-- Skateboard, Clipboard, Notebook) nehmen zuerst die linke Hand.
--
-- Accessory-Vokabular (Accessories.Ids):
--   Kopf:   Cap, CapBackward, BikeHelmet, Headphones, Glasses, Shades, Goggles,
--           NightVision, GasMask, Headband, Bandana, SheriffHat, RangerHat,
--           DetectiveHat, BucketHat, Hood, Crown, Halo, Horns, Antlers, Antennae,
--           Earpiece, Beard, Eyestalks, ThirdEye, Mandibles, Teeth, Ears
--   Körper: LabCoat, Jacket, Trenchcoat, Vest, Apron, HazmatSuit, Scarf, Tie, Badge,
--           Camera, Whistle, Cape, Shoulderpads, Toolbelt, PaperBag, Backpack,
--           RadioPack, Wings, Spikes, Tail, Tentacles, Chains
--   Hand:   Flashlight, WalkieTalkie, Clipboard, Notebook, SpikedBat, SignalBat,
--           Detector, Lantern, FishingRod, Wrench, CoffeePot, Microphone, Crossbow,
--           Staff, GateKey, PhoneHandset, Cassette, StopSign, Boombox, Shield,
--           Skateboard, Magnifier, Crystal
--   Füße:   Rollerskates
--   Orbit:  OrbitDebris, OrbitRing, OrbitEyes
--
-- HairStyle-Vokabular: None, Short, Messy, Curly, Long, Mohawk, Bowl, Ponytail,
--                      Afro, Buzz, Spiky, Bun, Mullet

local Bodies = require(script.Parent:WaitForChild("Bodies"))

local Accessories = {}

local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rgb = Color3.fromRGB

local UPRIGHT = Bodies.UPRIGHT
local FORWARD = Bodies.FORWARD
local segment = Bodies.Segment
local ring = Bodies.Ring

local NEON = Enum.Material.Neon
local METAL = Enum.Material.Metal
local GLASS = Enum.Material.Glass
local WOOD = Enum.Material.Wood
local FABRIC = Enum.Material.Fabric

local BLACK = rgb(28, 26, 32)
local DARKGREY = rgb(58, 60, 66)
local GREY = rgb(140, 144, 150)
local SILVER = rgb(205, 210, 218)
local WHITE = rgb(240, 240, 236)
local GOLD = rgb(255, 196, 60)
local BROWN = rgb(110, 72, 42)
local RED = rgb(210, 40, 40)

type Builder = (ctx: any, a: any, C: { [string]: Color3 }) -> ()

local Builders: { [string]: Builder } = {}

-------------------------------------------------------------------------------
-- Hilfen
-------------------------------------------------------------------------------
-- Höhe (relativ zur Kopfmitte), auf der Hüte sitzen
local function hatY(a: any): number
	local head = a.Head
	return math.max(head.Size.Y / 2, (head.HairTop or head.Size.Y / 2) - 0.08)
end

local function darker(c: Color3, f: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), f)
end

-- Hand-Slot holen: (Gruppe, Griff-CFrame, Seite) oder nil
local function handSlot(ctx: any, a: any, preferLeft: boolean?): (Model?, CFrame?, number)
	local function right()
		if a.HandR and not a.HeldUsed then
			a.HeldUsed = true
			local g = ctx:Group("Held", a.HandR.Group, a.HandR.CF.Position)
			return g, a.HandR.CF, 1
		end
		return nil, nil, 0
	end
	local function left()
		if a.HandL and not a.LeftUsed then
			a.LeftUsed = true
			return a.HandL.Group, a.HandL.CF, -1
		end
		return nil, nil, 0
	end
	local g, cf, side
	if preferLeft then
		g, cf, side = left()
		if not g then
			g, cf, side = right()
		end
	else
		g, cf, side = right()
		if not g then
			g, cf, side = left()
		end
	end
	return g, cf, side
end

-- Gruppe "Orbit" holen/anlegen
local function orbitGroup(ctx: any, a: any): Model
	return ctx:GetGroup("Orbit", ctx.Model, a.Center.Position)
end

-- Mantel-Grundform (LabCoat, Jacket, Trenchcoat, Vest)
local function coat(ctx: any, a: any, color: Color3, length: number, sleeves: boolean, material: Enum.Material?)
	local T = a.Torso
	if not T or a.Kind ~= "Humanoid" then
		return
	end
	local w, h, d = T.Size.X, T.Size.Y, T.Size.Z
	local len = math.min(length, math.max(0, (a.HipY or 1) - 0.45))
	local total = h + len
	local cy = h / 2 - total / 2 + 0.03
	ctx:Part(T.Group, "CoatBack", "Block", V3(w + 0.1, total + 0.06, d * 0.72), T.CF * CF(0, cy, d * 0.16 + 0.04), color, material)
	for _, side in { -1, 1 } do
		ctx:Part(T.Group, "CoatFlap", "Block", V3(w * 0.3, total + 0.06, 0.08), T.CF * CF(side * (w * 0.35 + 0.05), cy, -d / 2 - 0.04), color, material)
	end
	if sleeves and a.Parts then
		ctx:Recolor(a.Parts.ArmL, color, material)
		ctx:Recolor(a.Parts.ArmR, color, material)
	end
end

-------------------------------------------------------------------------------
-- Frisuren
-------------------------------------------------------------------------------
local Hair: { [string]: (ctx: any, a: any, color: Color3) -> number } = {}

local function hairCap(ctx: any, a: any, color: Color3, t: number): ()
	local head = a.Head
	local W, H, D = head.Size.X, head.Size.Y, head.Size.Z
	local cf = head.CF * CF(0, H / 2 + t / 2 - 0.06, 0)
	if head.Round then
		ctx:Part(head.Group, "Hair", "Cyl", V3(t, W + 0.08, W + 0.08), cf * UPRIGHT, color)
	else
		ctx:Part(head.Group, "Hair", "Block", V3(W + 0.08, t, D + 0.08), cf, color)
	end
end

local function hairPart(ctx: any, a: any, color: Color3, shape: string, size: Vector3, x: number, y: number, z: number, rot: CFrame?)
	local cf = a.Head.CF * CF(x, y, z)
	if rot then
		cf *= rot
	end
	return ctx:Part(a.Head.Group, "Hair", shape, size, cf, color)
end

Hair.Short = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	hairCap(ctx, a, c, 0.22)
	hairPart(ctx, a, c, "Block", V3(s.X * 0.9, s.Y * 0.55, 0.16), 0, s.Y * 0.18, s.Z / 2 - 0.02)
	return s.Y / 2 + 0.16
end

Hair.Buzz = function(ctx: any, a: any, c: Color3): number
	hairCap(ctx, a, c, 0.12)
	return a.Head.Size.Y / 2 + 0.06
end

Hair.Messy = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	hairCap(ctx, a, c, 0.25)
	hairPart(ctx, a, c, "Block", V3(0.32, 0.22, 0.32), -s.X * 0.25, s.Y / 2 + 0.2, -0.1, ANG(0.3, 0.5, 0.4))
	hairPart(ctx, a, c, "Block", V3(0.3, 0.22, 0.34), s.X * 0.2, s.Y / 2 + 0.22, 0.05, ANG(-0.2, 0.8, -0.5))
	hairPart(ctx, a, c, "Block", V3(0.28, 0.2, 0.3), 0, s.Y / 2 + 0.18, s.Z * 0.28, ANG(0.6, 0.2, 0.1))
	hairPart(ctx, a, c, "Block", V3(s.X * 0.72, 0.15, 0.14), 0, s.Y * 0.38, -s.Z / 2 + 0.02)
	return s.Y / 2 + 0.3
end

Hair.Curly = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	local d = s.X * 0.48
	local spots = {
		{ -0.25, 0.5, -0.12 },
		{ 0.25, 0.5, -0.12 },
		{ 0, 0.56, 0.15 },
		{ -0.32, 0.28, 0.3 },
		{ 0.32, 0.28, 0.3 },
		{ 0, 0.3, 0.42 },
	}
	for _, p in spots do
		hairPart(ctx, a, c, "Ball", V3(d, d, d), p[1] * s.X, p[2] * s.Y, p[3] * s.Z)
	end
	return s.Y * 0.56 + d / 2
end

Hair.Long = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	hairCap(ctx, a, c, 0.22)
	hairPart(ctx, a, c, "Block", V3(s.X + 0.04, s.Y + 0.5, 0.22), 0, -0.25, s.Z / 2 - 0.02)
	for _, side in { -1, 1 } do
		hairPart(ctx, a, c, "Block", V3(0.14, s.Y * 0.85, s.Z * 0.5), side * (s.X / 2 + 0.02), -s.Y * 0.08, s.Z * 0.12)
	end
	return s.Y / 2 + 0.16
end

Hair.Mohawk = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	hairCap(ctx, a, c, 0.1)
	hairPart(ctx, a, c, "Block", V3(0.2, 0.55, s.Z * 0.9), 0, s.Y / 2 + 0.27, 0.05)
	return s.Y / 2 + 0.55
end

Hair.Bowl = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	hairCap(ctx, a, c, 0.14)
	if a.Head.Round then
		hairPart(ctx, a, c, "Cyl", V3(s.Y * 0.4, s.X + 0.14, s.X + 0.14), 0, s.Y * 0.41, 0, UPRIGHT)
	else
		hairPart(ctx, a, c, "Block", V3(s.X + 0.14, s.Y * 0.4, s.Z + 0.14), 0, s.Y * 0.41, 0)
	end
	return s.Y / 2 + 0.1
end

Hair.Ponytail = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	hairCap(ctx, a, c, 0.2)
	hairPart(ctx, a, c, "Block", V3(s.X * 0.82, s.Y * 0.45, 0.15), 0, s.Y * 0.2, s.Z / 2 - 0.02)
	hairPart(ctx, a, c, "Ball", V3(0.34, 0.34, 0.34), 0, s.Y * 0.22, s.Z / 2 + 0.14)
	hairPart(ctx, a, c, "Block", V3(0.26, 0.75, 0.26), 0, -s.Y * 0.18, s.Z / 2 + 0.22, ANG(-0.15, 0, 0))
	return s.Y / 2 + 0.14
end

Hair.Afro = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	local d = s.X * 1.45
	hairPart(ctx, a, c, "Ball", V3(d, d, d), 0, s.Y * 0.55, 0.2)
	return s.Y * 0.55 + d / 2
end

Hair.Spiky = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	hairCap(ctx, a, c, 0.2)
	local y = s.Y / 2 + 0.25
	hairPart(ctx, a, c, "Block", V3(0.22, 0.5, 0.22), -s.X * 0.25, y, 0, ANG(0, 0, 0.5))
	hairPart(ctx, a, c, "Block", V3(0.22, 0.5, 0.22), s.X * 0.25, y, 0, ANG(0, 0, -0.5))
	hairPart(ctx, a, c, "Block", V3(0.22, 0.55, 0.22), 0, y + 0.05, -s.Z * 0.18, ANG(-0.45, 0, 0))
	hairPart(ctx, a, c, "Block", V3(0.22, 0.5, 0.22), 0, y, s.Z * 0.22, ANG(0.5, 0, 0))
	return s.Y / 2 + 0.45
end

Hair.Bun = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	hairCap(ctx, a, c, 0.2)
	hairPart(ctx, a, c, "Ball", V3(0.5, 0.5, 0.5), 0, s.Y / 2 + 0.3, 0.12)
	return s.Y / 2 + 0.14
end

Hair.Mullet = function(ctx: any, a: any, c: Color3): number
	local s = a.Head.Size
	hairCap(ctx, a, c, 0.2)
	hairPart(ctx, a, c, "Block", V3(s.X * 0.86, s.Y * 0.85, 0.2), 0, -s.Y * 0.22, s.Z / 2)
	return s.Y / 2 + 0.14
end

Accessories.HairStyles = { "None", "Short", "Messy", "Curly", "Long", "Mohawk", "Bowl", "Ponytail", "Afro", "Buzz", "Spiky", "Bun", "Mullet" }

function Accessories.HasHairStyle(style: string): boolean
	return style == "None" or Hair[style] ~= nil
end

function Accessories.BuildHair(ctx: any, a: any, style: string, C: { [string]: Color3 }): boolean
	local fn = Hair[style]
	if not fn or not a.Head then
		return false
	end
	local cp = ctx:Checkpoint()
	local ok, result = pcall(fn, ctx, a, C.Hair)
	if not ok or ctx.Count > ctx.Limit then
		ctx:Rollback(cp)
		return false
	end
	a.Head.HairTop = result
	return true
end

-------------------------------------------------------------------------------
-- Kopf
-------------------------------------------------------------------------------
local function headPart(ctx: any, a: any, name: string, shape: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, props: any?)
	return ctx:Part(a.Head.Group, name, shape, size, a.Head.CF * offset, color, material, props)
end

local function capBase(ctx: any, a: any, C: { [string]: Color3 }, backward: boolean)
	local head = a.Head
	if not head then
		return
	end
	local s = head.Size
	local y = hatY(a)
	if head.Round then
		headPart(ctx, a, "Cap", "Cyl", V3(0.38, s.X + 0.12, s.X + 0.12), CF(0, y + 0.1, 0) * UPRIGHT, C.Accent)
	else
		headPart(ctx, a, "Cap", "Block", V3(s.X + 0.12, 0.38, s.Z + 0.12), CF(0, y + 0.1, 0), C.Accent)
	end
	local z = (s.Z / 2 + 0.25) * (if backward then 1 else -1)
	headPart(ctx, a, "Brim", "Block", V3(s.X * 0.8, 0.08, 0.6), CF(0, y - 0.06, z), darker(C.Accent, 0.2))
end

Builders.Cap = function(ctx: any, a: any, C: { [string]: Color3 })
	capBase(ctx, a, C, false)
end

Builders.CapBackward = function(ctx: any, a: any, C: { [string]: Color3 })
	capBase(ctx, a, C, true)
end

Builders.BikeHelmet = function(ctx: any, a: any, C: { [string]: Color3 })
	local head = a.Head
	if not head then
		return
	end
	local s = head.Size
	local y = hatY(a)
	headPart(ctx, a, "Helmet", "Sphere", V3(s.X + 0.34, 0.85, s.Z + 0.4), CF(0, y - 0.02, 0.04), C.Accent)
	headPart(ctx, a, "HelmetStripe", "Block", V3(0.18, 0.2, s.Z + 0.3), CF(0, y + 0.33, 0.04), WHITE)
	headPart(ctx, a, "HelmetVisor", "Block", V3(s.X * 0.7, 0.07, 0.28), CF(0, y - 0.05, -s.Z / 2 - 0.2), darker(C.Accent, 0.35))
end

Builders.Headphones = function(ctx: any, a: any, C: { [string]: Color3 })
	local head = a.Head
	if not head then
		return
	end
	local s = head.Size
	local y = hatY(a)
	headPart(ctx, a, "Band", "Block", V3(s.X + 0.3, 0.1, 0.16), CF(0, y + 0.1, 0), BLACK)
	for _, side in { -1, 1 } do
		headPart(ctx, a, "EarCup", "Cyl", V3(0.22, 0.48, 0.48), CF(side * (s.X / 2 + 0.1), 0, 0), C.Accent)
	end
end

Builders.Glasses = function(ctx: any, a: any, _C: { [string]: Color3 })
	local F = a.Face
	if not F then
		return
	end
	local W, H = F.W, F.H
	local z = -(if F.Round then 0.04 else 0.06)
	ctx:Part(F.Group, "GlassesFrame", "Block", V3(W * 0.82, 0.07, 0.05), F.CF * CF(0, H * 0.14, z - 0.02), BLACK, nil, { Role = "Eye" })
	for _, side in { -1, 1 } do
		local x = side * W * 0.2
		local back = if F.Round then F.Round - math.sqrt(F.Round ^ 2 - x * x) else 0
		ctx:Part(F.Group, "Lens", "Block", V3(W * 0.26, H * 0.24, 0.04), F.CF * CF(x, H * 0.07, back + z) * ANG(0, -math.asin(x / (F.Round or 1e3)), 0), rgb(180, 220, 255), GLASS, { Transparency = 0.45, Role = "Eye" })
	end
end

Builders.Shades = function(ctx: any, a: any, _C: { [string]: Color3 })
	local F = a.Face
	if not F then
		return
	end
	ctx:Part(F.Group, "Shades", "Block", V3(F.W * 0.86, F.H * 0.22, 0.08), F.CF * CF(0, F.H * 0.08, -0.05), BLACK, nil, { Reflectance = 0.3, Role = "Eye" })
end

Builders.Goggles = function(ctx: any, a: any, C: { [string]: Color3 })
	local head = a.Head
	if not head then
		return
	end
	local s = head.Size
	local y = s.Y * 0.3
	if head.Round then
		headPart(ctx, a, "Strap", "Cyl", V3(0.16, s.X + 0.06, s.X + 0.06), CF(0, y, 0) * UPRIGHT, BLACK)
	else
		headPart(ctx, a, "Strap", "Block", V3(s.X + 0.06, 0.16, s.Z + 0.06), CF(0, y, 0), BLACK)
	end
	for _, side in { -1, 1 } do
		headPart(ctx, a, "GoggleLens", "Cyl", V3(0.16, 0.36, 0.36), CF(side * s.X * 0.2, y + 0.04, -s.Z / 2 - 0.04) * FORWARD, C.Accent, GLASS, { Transparency = 0.2 })
	end
end

Builders.NightVision = function(ctx: any, a: any, C: { [string]: Color3 })
	local head = a.Head
	if not head then
		return
	end
	local s = head.Size
	local y = s.Y * 0.08
	if head.Round then
		headPart(ctx, a, "Strap", "Cyl", V3(0.18, s.X + 0.06, s.X + 0.06), CF(0, y, 0) * UPRIGHT, BLACK)
	else
		headPart(ctx, a, "Strap", "Block", V3(s.X + 0.06, 0.18, s.Z + 0.06), CF(0, y, 0), BLACK)
	end
	for _, side in { -1, 1 } do
		headPart(ctx, a, "NVTube", "Cyl", V3(0.3, 0.26, 0.26), CF(side * s.X * 0.2, y, -s.Z / 2 - 0.14) * FORWARD, DARKGREY, METAL)
		headPart(ctx, a, "NVLens", "Cyl", V3(0.05, 0.2, 0.2), CF(side * s.X * 0.2, y, -s.Z / 2 - 0.3) * FORWARD, C.Glow, NEON, { Role = "Glow" })
	end
end

Builders.GasMask = function(ctx: any, a: any, C: { [string]: Color3 })
	local F = a.Face
	if not F then
		return
	end
	local W, H = F.W, F.H
	ctx:Part(F.Group, "MaskPlate", "Block", V3(W * 0.8, H * 0.44, 0.12), F.CF * CF(0, -H * 0.2, -0.04), DARKGREY)
	ctx:Part(F.Group, "MaskSnout", "Cyl", V3(0.32, 0.42, 0.42), F.CF * CF(0, -H * 0.24, -0.24) * FORWARD, BLACK)
	ctx:Part(F.Group, "MaskFilter", "Cyl", V3(0.12, 0.32, 0.32), F.CF * CF(0, -H * 0.24, -0.44) * FORWARD, C.Accent)
end

local function band(ctx: any, a: any, color: Color3, y: number, t: number)
	local head = a.Head
	local s = head.Size
	if head.Round then
		headPart(ctx, a, "Band", "Cyl", V3(t, s.X + 0.06, s.X + 0.06), CF(0, y, 0) * UPRIGHT, color)
	else
		headPart(ctx, a, "Band", "Block", V3(s.X + 0.06, t, s.Z + 0.06), CF(0, y, 0), color)
	end
end

Builders.Headband = function(ctx: any, a: any, C: { [string]: Color3 })
	if not a.Head then
		return
	end
	band(ctx, a, C.Accent, a.Head.Size.Y * 0.32, 0.15)
end

Builders.Bandana = function(ctx: any, a: any, C: { [string]: Color3 })
	if not a.Head then
		return
	end
	local s = a.Head.Size
	band(ctx, a, C.Accent, s.Y * 0.3, 0.2)
	headPart(ctx, a, "Knot", "Block", V3(0.18, 0.4, 0.1), CF(0.12, s.Y * 0.12, s.Z / 2 + 0.08) * ANG(0, 0, 0.35), C.Accent)
	headPart(ctx, a, "Knot", "Block", V3(0.18, 0.36, 0.1), CF(-0.1, s.Y * 0.1, s.Z / 2 + 0.1) * ANG(0, 0, -0.3), C.Accent)
end

Builders.SheriffHat = function(ctx: any, a: any, C: { [string]: Color3 })
	if not a.Head then
		return
	end
	local s = a.Head.Size
	local y = hatY(a)
	headPart(ctx, a, "HatBrim", "Cyl", V3(0.09, s.X + 0.95, s.X + 0.95), CF(0, y, 0) * UPRIGHT, C.Accent)
	headPart(ctx, a, "HatCrown", "Block", V3(s.X * 0.82, 0.5, s.Z * 0.78), CF(0, y + 0.27, 0), C.Accent)
	headPart(ctx, a, "HatBand", "Block", V3(s.X * 0.84, 0.1, s.Z * 0.8), CF(0, y + 0.1, 0), darker(C.Accent, 0.5))
	headPart(ctx, a, "HatStar", "Block", V3(0.16, 0.16, 0.05), CF(0, y + 0.3, -s.Z * 0.4) * ANG(0, 0, math.pi / 4), GOLD, METAL)
end

Builders.RangerHat = function(ctx: any, a: any, C: { [string]: Color3 })
	if not a.Head then
		return
	end
	local s = a.Head.Size
	local y = hatY(a)
	headPart(ctx, a, "HatBrim", "Cyl", V3(0.08, s.X + 1.05, s.X + 1.05), CF(0, y, 0) * UPRIGHT, C.Accent)
	headPart(ctx, a, "HatCrown", "Cyl", V3(0.48, s.X * 0.8, s.X * 0.8), CF(0, y + 0.26, 0) * UPRIGHT, C.Accent)
	headPart(ctx, a, "HatPinch", "Block", V3(0.08, 0.14, s.X * 0.6), CF(0, y + 0.52, 0), darker(C.Accent, 0.25))
end

Builders.DetectiveHat = function(ctx: any, a: any, C: { [string]: Color3 })
	if not a.Head then
		return
	end
	local s = a.Head.Size
	local y = hatY(a)
	headPart(ctx, a, "HatBrim", "Cyl", V3(0.08, s.X + 0.55, s.X + 0.55), CF(0, y, 0) * UPRIGHT, C.Accent)
	headPart(ctx, a, "HatCrown", "Cyl", V3(0.46, s.X * 0.86, s.X * 0.86), CF(0, y + 0.25, 0) * UPRIGHT, C.Accent)
	headPart(ctx, a, "HatBand", "Cyl", V3(0.12, s.X * 0.88, s.X * 0.88), CF(0, y + 0.1, 0) * UPRIGHT, BLACK)
end

Builders.BucketHat = function(ctx: any, a: any, C: { [string]: Color3 })
	if not a.Head then
		return
	end
	local s = a.Head.Size
	local y = hatY(a)
	headPart(ctx, a, "HatCrown", "Cyl", V3(0.42, s.X + 0.08, s.X + 0.08), CF(0, y + 0.12, 0) * UPRIGHT, C.Accent, FABRIC)
	headPart(ctx, a, "HatBrim", "Cyl", V3(0.1, s.X + 0.5, s.X + 0.5), CF(0, y - 0.08, 0) * UPRIGHT, darker(C.Accent, 0.15), FABRIC)
end

Builders.Hood = function(ctx: any, a: any, C: { [string]: Color3 })
	local head = a.Head
	if not head then
		return
	end
	local s = head.Size
	headPart(ctx, a, "Hood", "Block", V3(s.X + 0.28, s.Y + 0.24, s.Z + 0.1), CF(0, 0.1, 0.18), C.Top)
	head.HairTop = s.Y / 2 + 0.22
	local T = a.Torso
	if T and a.Kind == "Humanoid" then
		ctx:Part(T.Group, "HoodDrape", "Block", V3(T.Size.X * 0.8, 0.3, T.Size.Z + 0.12), T.CF * CF(0, T.Size.Y / 2 + 0.05, 0.08), C.Top)
	end
end

local function topAnchor(a: any): (Model?, CFrame?, number)
	local top = a.Top
	if not top then
		return nil, nil, 1
	end
	local lift = 0
	if a.Head and a.Head.Group == top.Group then
		lift = math.max(0, (a.Head.HairTop or 0) - a.Head.Size.Y / 2)
	end
	return top.Group, top.CF * CF(0, lift, 0), top.W
end

Builders.Crown = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, cf, w = topAnchor(a)
	if not g or not cf then
		return
	end
	local d = w * 0.85
	ctx:Part(g, "CrownBand", "Cyl", V3(0.3, d, d), cf * CF(0, 0.12, 0) * UPRIGHT, C.Accent, METAL)
	for i = 0, 3 do
		local theta = i / 4 * math.pi * 2 + math.pi / 4
		ctx:Part(g, "CrownPoint", "Block", V3(0.22, 0.22, 0.08), cf * ANG(0, theta, 0) * CF(0, 0.34, -d / 2 + 0.02) * ANG(0, 0, math.pi / 4), C.Accent, METAL)
	end
	ctx:Part(g, "CrownGem", "Ball", V3(0.2, 0.2, 0.2), cf * CF(0, 0.14, -d / 2 - 0.04), C.Glow, NEON)
end

Builders.Halo = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, cf, w = topAnchor(a)
	if not g or not cf then
		return
	end
	ring(ctx, g, "Halo", cf * CF(0, 0.55, 0), w * 0.45 + 0.12, 0.11, 8, C.Glow, NEON, "Glow")
end

Builders.Horns = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, cf, w = topAnchor(a)
	if not g or not cf then
		return
	end
	local base = cf.Position
	for _, side in { -1, 1 } do
		local p0 = base + V3(side * w * 0.32, -0.08, 0)
		local p1 = p0 + V3(side * 0.38, 0.45, 0.05)
		local p2 = p1 + V3(side * 0.04, 0.42, -0.18)
		segment(ctx, g, "Horn", p0, p1, 0.26, C.Accent)
		segment(ctx, g, "HornTip", p1, p2, 0.15, darker(C.Accent, 0.2))
	end
end

Builders.Antlers = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, cf, w = topAnchor(a)
	if not g or not cf then
		return
	end
	local base = cf.Position
	for _, side in { -1, 1 } do
		local p0 = base + V3(side * w * 0.3, -0.05, 0)
		local p1 = p0 + V3(side * 0.55, 0.7, 0.1)
		local p2 = p1 + V3(side * 0.35, 0.6, -0.05)
		segment(ctx, g, "Antler", p0, p1, 0.14, C.Accent)
		segment(ctx, g, "Antler", p1, p2, 0.12, C.Accent)
		segment(ctx, g, "Tine", p1, p1 + V3(-side * 0.05, 0.5, -0.3), 0.1, C.Accent)
	end
end

Builders.Antennae = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, cf, w = topAnchor(a)
	if not g or not cf then
		return
	end
	local base = cf.Position
	for _, side in { -1, 1 } do
		local p0 = base + V3(side * w * 0.2, -0.05, -0.05)
		local p1 = p0 + V3(side * 0.35, 0.75, -0.25)
		segment(ctx, g, "Antenna", p0, p1, 0.07, C.Accent)
		ctx:Part(g, "AntennaTip", "Ball", V3(0.18, 0.18, 0.18), CF(p1), C.Glow, NEON)
	end
end

Builders.Earpiece = function(ctx: any, a: any, _C: { [string]: Color3 })
	local head = a.Head
	if not head then
		return
	end
	local s = head.Size
	headPart(ctx, a, "Earpiece", "Block", V3(0.1, 0.18, 0.14), CF(s.X / 2 + 0.04, 0, 0), BLACK)
	headPart(ctx, a, "EarCord", "Block", V3(0.04, 0.45, 0.04), CF(s.X / 2 + 0.04, -0.3, 0.05), rgb(230, 230, 230))
end

Builders.Beard = function(ctx: any, a: any, C: { [string]: Color3 })
	local F = a.Face
	if not F then
		return
	end
	local W, H = F.W, F.H
	ctx:Part(F.Group, "Beard", "Block", V3(W * 0.82, H * 0.4, 0.3), F.CF * CF(0, -H * 0.3, 0.02), C.Hair)
	ctx:Part(F.Group, "Moustache", "Block", V3(W * 0.5, H * 0.09, 0.14), F.CF * CF(0, -H * 0.1, -0.1), C.Hair)
end

Builders.Eyestalks = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, cf, w = topAnchor(a)
	if not g or not cf then
		return
	end
	local base = cf.Position
	for _, side in { -1, 1 } do
		local p0 = base + V3(side * w * 0.22, -0.05, 0)
		local p1 = p0 + V3(side * 0.3, 0.8, -0.15)
		segment(ctx, g, "Stalk", p0, p1, 0.13, C.Accent, nil, "Cyl")
		ctx:Part(g, "StalkEye", "Ball", V3(0.4, 0.4, 0.4), CF(p1), WHITE, nil, { Role = "Eye" })
		ctx:Part(g, "StalkPupil", "Ball", V3(0.18, 0.18, 0.18), CF(p1 + V3(0, 0, -0.14)), C.Glow, NEON, { Role = "Eye" })
	end
end

Builders.ThirdEye = function(ctx: any, a: any, C: { [string]: Color3 })
	local F = a.Face
	if not F then
		return
	end
	local W, H = F.W, F.H
	ctx:Part(F.Group, "ThirdEyeLid", "Sphere", V3(W * 0.26, H * 0.16, 0.08), F.CF * CF(0, H * 0.33, -0.01), C.Accent, nil, { Role = "Eye" })
	ctx:Part(F.Group, "ThirdEye", "Ball", V3(W * 0.09, W * 0.09, W * 0.09), F.CF * CF(0, H * 0.33, -0.04), C.Glow, NEON, { Role = "Eye" })
end

Builders.Mandibles = function(ctx: any, a: any, C: { [string]: Color3 })
	local F = a.Face
	if not F then
		return
	end
	local W, H = F.W, F.H
	for _, side in { -1, 1 } do
		local p0 = (F.CF * CF(side * W * 0.3, -H * 0.3, 0.05)).Position
		local p1 = (F.CF * CF(side * W * 0.38, -H * 0.42, -0.45)).Position
		local p2 = (F.CF * CF(side * W * 0.08, -H * 0.45, -0.7)).Position
		segment(ctx, F.Group, "Mandible", p0, p1, 0.14, C.Accent)
		segment(ctx, F.Group, "MandibleTip", p1, p2, 0.1, darker(C.Accent, 0.3))
	end
end

Builders.Teeth = function(ctx: any, a: any, _C: { [string]: Color3 })
	local F = a.Face
	if not F then
		return
	end
	local W, H = F.W, F.H
	for i = -2, 2 do
		ctx:Part(F.Group, "Tooth", "Block", V3(0.14, 0.14, 0.06), F.CF * CF(i * W * 0.1, -H * 0.33, -0.04) * ANG(0, 0, math.pi / 4), WHITE, nil, { Role = "Eye" })
	end
end

Builders.Ears = function(ctx: any, a: any, C: { [string]: Color3 })
	local head = a.Head
	if not head then
		return
	end
	local s = head.Size
	for _, side in { -1, 1 } do
		headPart(ctx, a, "Ear", "Wedge", V3(0.22, 0.5, 0.36), CF(side * s.X * 0.32, s.Y / 2 + 0.22, 0.02), C.Skin)
		headPart(ctx, a, "EarInner", "Wedge", V3(0.12, 0.34, 0.2), CF(side * s.X * 0.32, s.Y / 2 + 0.17, -0.06), C.Accent)
	end
end

-------------------------------------------------------------------------------
-- Körper
-------------------------------------------------------------------------------
Builders.LabCoat = function(ctx: any, a: any, _C: { [string]: Color3 })
	coat(ctx, a, rgb(238, 240, 242), 0.95, true)
end

Builders.Jacket = function(ctx: any, a: any, C: { [string]: Color3 })
	coat(ctx, a, C.Accent, 0.12, true)
end

Builders.Trenchcoat = function(ctx: any, a: any, C: { [string]: Color3 })
	coat(ctx, a, C.Accent, 1.35, true)
	local T = a.Torso
	if T and a.Kind == "Humanoid" then
		ctx:Part(T.Group, "CoatBelt", "Block", V3(T.Size.X + 0.14, 0.18, T.Size.Z + 0.16), T.CF * CF(0, -T.Size.Y * 0.25, 0), darker(C.Accent, 0.35))
	end
end

Builders.Vest = function(ctx: any, a: any, C: { [string]: Color3 })
	coat(ctx, a, C.Accent, 0, false)
end

Builders.Apron = function(ctx: any, a: any, C: { [string]: Color3 })
	local T = a.Torso
	if not T or a.Kind ~= "Humanoid" then
		return
	end
	local w, h, d = T.Size.X, T.Size.Y, T.Size.Z
	local len = h * 0.75 + math.min(0.7, (a.HipY or 1) * 0.4)
	ctx:Part(T.Group, "Apron", "Block", V3(w * 0.72, len, 0.06), T.CF * CF(0, h * 0.25 - len / 2, -d / 2 - 0.04), C.Accent)
	ctx:Part(T.Group, "ApronPocket", "Block", V3(w * 0.4, 0.3, 0.07), T.CF * CF(0, -h * 0.25, -d / 2 - 0.06), darker(C.Accent, 0.12))
end

Builders.HazmatSuit = function(ctx: any, a: any, C: { [string]: Color3 })
	local P = a.Parts
	local suit = rgb(240, 200, 40)
	if P and a.Kind == "Humanoid" then
		for _, key in { "Torso", "LegL", "LegR", "ArmL", "ArmR" } do
			ctx:Recolor(P[key], suit)
		end
		ctx:Recolor(P.ShoeL, BLACK)
		ctx:Recolor(P.ShoeR, BLACK)
		ctx:Recolor(P.HandL, BLACK)
		ctx:Recolor(P.HandR, BLACK)
	end
	local head = a.Head
	if head then
		local s = head.Size
		headPart(ctx, a, "HazmatHood", "Block", V3(s.X + 0.3, s.Y + 0.28, s.Z + 0.12), CF(0, 0.08, 0.2), suit)
		headPart(ctx, a, "HazmatVisor", "Block", V3(s.X * 0.8, s.Y * 0.62, 0.05), CF(0, 0.04, -s.Z / 2 - 0.1), rgb(200, 235, 255), GLASS, { Transparency = 0.55, Role = "Eye" })
		head.HairTop = s.Y / 2 + 0.22
	end
end

Builders.Scarf = function(ctx: any, a: any, C: { [string]: Color3 })
	local T = a.Torso
	if not T or a.Kind ~= "Humanoid" then
		return
	end
	local w, h, d = T.Size.X, T.Size.Y, T.Size.Z
	ctx:Part(T.Group, "Scarf", "Block", V3(w * 0.72, 0.32, d + 0.14), T.CF * CF(0, h / 2 + 0.06, 0), C.Accent, FABRIC)
	ctx:Part(T.Group, "ScarfTail", "Block", V3(0.3, 0.85, 0.09), T.CF * CF(-w * 0.2, h / 2 - 0.4, -d / 2 - 0.07) * ANG(0, 0, 0.08), C.Accent, FABRIC)
end

Builders.Tie = function(ctx: any, a: any, C: { [string]: Color3 })
	local T = a.Torso
	if not T or a.Kind ~= "Humanoid" then
		return
	end
	local w, h, d = T.Size.X, T.Size.Y, T.Size.Z
	ctx:Part(T.Group, "TieKnot", "Block", V3(w * 0.12, 0.14, 0.07), T.CF * CF(0, h / 2 - 0.1, -d / 2 - 0.035), darker(C.Accent, 0.2))
	ctx:Part(T.Group, "Tie", "Block", V3(w * 0.14, h * 0.6, 0.05), T.CF * CF(0, h * 0.12, -d / 2 - 0.03), C.Accent)
end

Builders.Badge = function(ctx: any, a: any, _C: { [string]: Color3 })
	local T = a.Torso
	if not T then
		return
	end
	local w, h, d = T.Size.X, T.Size.Y, T.Size.Z
	local cf = T.CF * CF(-w * 0.26, h * 0.2, -d / 2 - 0.04)
	ctx:Part(T.Group, "Badge", "Block", V3(0.26, 0.26, 0.05), cf * ANG(0, 0, math.pi / 4), GOLD, METAL)
	ctx:Part(T.Group, "BadgeCenter", "Block", V3(0.13, 0.13, 0.07), cf, rgb(255, 240, 180), METAL)
end

Builders.Camera = function(ctx: any, a: any, _C: { [string]: Color3 })
	local T = a.Torso
	if not T or a.Kind ~= "Humanoid" then
		return
	end
	local w, h, d = T.Size.X, T.Size.Y, T.Size.Z
	ctx:Part(T.Group, "CameraStrap", "Block", V3(0.06, h * 0.45, 0.04), T.CF * CF(w * 0.15, h * 0.3, -d / 2 - 0.03), BLACK)
	ctx:Part(T.Group, "Camera", "Block", V3(0.55, 0.36, 0.26), T.CF * CF(w * 0.15, 0, -d / 2 - 0.14), DARKGREY)
	ctx:Part(T.Group, "CameraLens", "Cyl", V3(0.2, 0.26, 0.26), T.CF * CF(w * 0.15, -0.02, -d / 2 - 0.36) * FORWARD, BLACK, GLASS)
end

Builders.Whistle = function(ctx: any, a: any, _C: { [string]: Color3 })
	local T = a.Torso
	if not T or a.Kind ~= "Humanoid" then
		return
	end
	local h, d = T.Size.Y, T.Size.Z
	ctx:Part(T.Group, "WhistleCord", "Block", V3(0.05, h * 0.38, 0.03), T.CF * CF(0, h * 0.3, -d / 2 - 0.02), RED)
	ctx:Part(T.Group, "Whistle", "Block", V3(0.14, 0.12, 0.22), T.CF * CF(0, h * 0.08, -d / 2 - 0.1), SILVER, METAL)
end

Builders.Cape = function(ctx: any, a: any, C: { [string]: Color3 })
	local T = a.Torso
	if not T then
		return
	end
	local w, h, d = T.Size.X, T.Size.Y, T.Size.Z
	local total = h + (a.HipY or 1) * 0.8
	ctx:Part(T.Group, "CapeCollar", "Block", V3(w + 0.2, 0.26, d + 0.16), T.CF * CF(0, h / 2 + 0.02, 0.02), darker(C.Accent, 0.25))
	ctx:Part(T.Group, "Cape", "Block", V3(w + 0.3, total, 0.12), T.CF * CF(0, h / 2, d / 2 + 0.1) * ANG(-0.08, 0, 0) * CF(0, -total / 2, 0), C.Accent, FABRIC)
end

Builders.Shoulderpads = function(ctx: any, a: any, C: { [string]: Color3 })
	for _, key in { "ArmL", "ArmR" } do
		local arm = a[key]
		if arm then
			ctx:Part(arm.Group, "Shoulderpad", "Block", V3(arm.W + 0.32, 0.3, arm.D + 0.3), arm.Shoulder * CF(0, 0.08, 0), C.Accent, METAL)
		end
	end
end

Builders.Toolbelt = function(ctx: any, a: any, _C: { [string]: Color3 })
	local W = a.Waist
	if not W then
		return
	end
	ctx:Part(W.Group, "Belt", "Block", V3(W.W + 0.08, 0.24, W.D + 0.08), W.CF, BROWN)
	ctx:Part(W.Group, "Pouch", "Block", V3(0.36, 0.34, 0.24), W.CF * CF(W.W * 0.3, -0.12, -W.D / 2 - 0.1), darker(BROWN, 0.2))
	ctx:Part(W.Group, "Hammer", "Block", V3(0.1, 0.5, 0.1), W.CF * CF(-W.W * 0.32, -0.2, -W.D / 2 - 0.08), GREY, METAL)
end

Builders.PaperBag = function(ctx: any, a: any, C: { [string]: Color3 })
	local T = a.Torso
	if not T or a.Kind ~= "Humanoid" then
		return
	end
	local w, h, d = T.Size.X, T.Size.Y, T.Size.Z
	local p0 = (T.CF * CF(-w * 0.38, h / 2, -d / 2 - 0.03)).Position
	local p1 = (T.CF * CF(w * 0.4, -h / 2, -d / 2 - 0.03)).Position
	segment(ctx, T.Group, "BagStrap", p0, p1, 0.1, darker(C.Accent, 0.3))
	ctx:Part(T.Group, "Bag", "Block", V3(0.32, 0.65, 0.75), T.CF * CF(w / 2 + 0.16, -h / 2 + 0.05, 0), C.Accent, FABRIC)
	ctx:Part(T.Group, "Papers", "Block", V3(0.22, 0.2, 0.6), T.CF * CF(w / 2 + 0.16, -h / 2 + 0.45, 0), WHITE)
end

Builders.Backpack = function(ctx: any, a: any, C: { [string]: Color3 })
	local B = a.Back
	if not B then
		return
	end
	local w, h = B.W, B.H
	ctx:Part(B.Group, "Backpack", "Block", V3(w * 0.8, h * 0.78, 0.5), B.CF * CF(0, -h * 0.02, -0.25), C.Accent)
	ctx:Part(B.Group, "BackpackPocket", "Block", V3(w * 0.55, h * 0.3, 0.18), B.CF * CF(0, -h * 0.2, -0.56), darker(C.Accent, 0.3))
	local T = a.Torso
	if T and a.Kind == "Humanoid" then
		for _, side in { -1, 1 } do
			ctx:Part(T.Group, "Strap", "Block", V3(0.13, T.Size.Y * 0.62, 0.04), T.CF * CF(side * T.Size.X * 0.27, T.Size.Y * 0.18, -T.Size.Z / 2 - 0.02), darker(C.Accent, 0.3))
		end
	end
end

Builders.RadioPack = function(ctx: any, a: any, C: { [string]: Color3 })
	local B = a.Back
	if not B then
		return
	end
	local w, h = B.W, B.H
	ctx:Part(B.Group, "Radio", "Block", V3(w * 0.88, h * 0.85, 0.66), B.CF * CF(0, 0, -0.33), DARKGREY, METAL)
	ctx:Part(B.Group, "RadioDial", "Block", V3(w * 0.5, 0.16, 0.05), B.CF * CF(0, h * 0.2, -0.68), C.Glow, NEON)
	local top = B.CF * CF(w * 0.3, h * 0.42, -0.3)
	ctx:Part(B.Group, "RadioAntenna", "Cyl", V3(2.0, 0.07, 0.07), top * CF(0, 1.0, 0) * UPRIGHT, SILVER, METAL)
	ctx:Part(B.Group, "RadioAntennaTip", "Ball", V3(0.2, 0.2, 0.2), top * CF(0, 2.02, 0), RED, NEON)
end

Builders.Wings = function(ctx: any, a: any, C: { [string]: Color3 })
	local B = a.Back
	if not B or a.HasWings then
		return
	end
	a.HasWings = true
	local base = (B.CF * CF(0, B.H * 0.2, -0.1)).Position
	for _, side in { -1, 1 } do
		local nm = if side > 0 then "R" else "L"
		local root = base + V3(side * 0.3, 0, 0)
		local g = ctx:Group("Wing" .. nm, ctx.Model, root)
		local cf = CF(root) * ANG(0, -side * 0.4, 0) * ANG(0, 0, side * 0.3)
		ctx:Part(g, "Wing", "Block", V3(1.9, 1.3, 0.08), cf * CF(side * 1.0, 0.35, 0), C.Accent)
		ctx:Part(g, "WingTip", "Block", V3(1.3, 0.85, 0.08), cf * CF(side * 1.25, -0.45, 0.04) * ANG(0, 0, -side * 0.35), darker(C.Accent, 0.25))
	end
end

Builders.Spikes = function(ctx: any, a: any, C: { [string]: Color3 })
	local B = a.Back
	if not B then
		return
	end
	for i = 0, 3 do
		local t = B.H * (0.36 - i * 0.24)
		ctx:Part(B.Group, "Spike", "Wedge", V3(0.16, 0.5, 0.6), B.CF * CF(0, t, -0.28), C.Accent)
	end
end

Builders.Tail = function(ctx: any, a: any, C: { [string]: Color3 })
	local root = a.TailRoot
	if not root or a.HasTail then
		return
	end
	a.HasTail = true
	local g = ctx:Group("Tail", ctx.Model, root)
	local p1 = root + V3(0, -0.3, 0.7)
	local p2 = p1 + V3(0, -0.05, 0.65)
	local p3 = p2 + V3(0, 0.45, 0.4)
	segment(ctx, g, "Tail", root, p1, 0.3, C.Skin)
	segment(ctx, g, "Tail", p1, p2, 0.24, C.Skin)
	segment(ctx, g, "TailTip", p2, p3, 0.16, C.Accent)
end

Builders.Tentacles = function(ctx: any, a: any, C: { [string]: Color3 })
	local U = a.Under
	if U then
		local base = U.CF.Position
		for i = 0, 3 do
			local ang = i / 4 * math.pi * 2 + math.pi / 4
			local dx, dz = math.cos(ang), math.sin(ang)
			local p0 = base + V3(dx * U.R * 0.6, 0, dz * U.R * 0.6)
			local p1 = base + V3(dx * (U.R + 0.5), -0.8, dz * (U.R + 0.5))
			local p2 = base + V3(dx * (U.R + 0.95), -1.5, dz * (U.R + 0.95))
			p1 = V3(p1.X, math.max(p1.Y, 0.2), p1.Z)
			p2 = V3(p2.X, math.max(p2.Y, 0.06), p2.Z)
			segment(ctx, U.Group, "Tentacle", p0, p1, 0.26, C.Accent, nil, "Cyl")
			segment(ctx, U.Group, "Tentacle", p1, p2, 0.16, C.Accent, nil, "Cyl")
		end
		return
	end
	local B = a.Back
	if not B then
		return
	end
	local base = B.CF.Position
	for i, off in { V3(-0.5, 0.4, 0), V3(0.5, 0.4, 0), V3(0, -0.3, 0) } do
		local side = if off.X < 0 then -1 elseif off.X > 0 then 1 else 0
		local p0 = base + off
		local p1 = p0 + V3(side * 0.6, 0.5, 0.6)
		local p2 = p1 + V3(side * 0.5, 0.7 - i * 0.2, 0.5)
		segment(ctx, B.Group, "Tendril", p0, p1, 0.24, C.Accent, nil, "Cyl")
		segment(ctx, B.Group, "Tendril", p1, p2, 0.15, C.Accent, nil, "Cyl")
	end
end

Builders.Chains = function(ctx: any, a: any, _C: { [string]: Color3 })
	local T = a.Torso
	if not T or a.Kind ~= "Humanoid" then
		return
	end
	local w, h, d = T.Size.X, T.Size.Y, T.Size.Z
	for _, side in { -1, 1 } do
		local p0 = (T.CF * CF(side * w * 0.45, h * 0.45, -d / 2 - 0.05)).Position
		local p1 = (T.CF * CF(-side * w * 0.45, -h * 0.45, -d / 2 - 0.05)).Position
		segment(ctx, T.Group, "Chain", p0, p1, 0.13, GREY, METAL)
	end
	ctx:Part(T.Group, "Padlock", "Block", V3(0.3, 0.34, 0.14), T.CF * CF(0, 0, -d / 2 - 0.12), GOLD, METAL)
end

-------------------------------------------------------------------------------
-- Hand-Items (G = Griff-CFrame, s = Seite: +1 rechts, -1 links)
-------------------------------------------------------------------------------
local function hand(ctx: any, a: any, preferLeft: boolean?): (Model?, CFrame, number)
	local g, cf, s = handSlot(ctx, a, preferLeft)
	return g, cf or CFrame.identity, s
end

Builders.Flashlight = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "FlashlightBody", "Cyl", V3(0.7, 0.22, 0.22), G * CF(0, 0, -0.22) * FORWARD, BLACK)
	ctx:Part(g, "FlashlightHead", "Cyl", V3(0.22, 0.34, 0.34), G * CF(0, 0, -0.64) * FORWARD, DARKGREY, METAL)
	ctx:Part(g, "FlashlightLens", "Cyl", V3(0.05, 0.28, 0.28), G * CF(0, 0, -0.77) * FORWARD, rgb(255, 245, 190), NEON, { Role = "Glow" })
end

Builders.WalkieTalkie = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if g then
		ctx:Part(g, "Walkie", "Block", V3(0.28, 0.52, 0.2), G * CF(0, 0.16, -0.12), DARKGREY)
		ctx:Part(g, "WalkieAntenna", "Cyl", V3(0.42, 0.06, 0.06), G * CF(0.08, 0.62, -0.12) * UPRIGHT, BLACK)
		ctx:Part(g, "WalkieLed", "Block", V3(0.07, 0.07, 0.04), G * CF(-0.06, 0.34, -0.23), RED, NEON)
		return
	end
	local W = a.Waist
	if W then
		ctx:Part(W.Group, "Walkie", "Block", V3(0.22, 0.48, 0.3), W.CF * CF(-(W.W / 2 + 0.12), -0.05, 0), DARKGREY)
		ctx:Part(W.Group, "WalkieAntenna", "Cyl", V3(0.38, 0.06, 0.06), W.CF * CF(-(W.W / 2 + 0.12), 0.38, 0.06) * UPRIGHT, BLACK)
	end
end

Builders.Clipboard = function(ctx: any, a: any, _C: { [string]: Color3 })
	local g, G = hand(ctx, a, true)
	if not g then
		return
	end
	local board = G * CF(0, 0.15, -0.38) * ANG(0.9, 0, 0)
	ctx:Part(g, "Clipboard", "Block", V3(0.62, 0.82, 0.06), board, BROWN)
	ctx:Part(g, "Paper", "Block", V3(0.52, 0.64, 0.02), board * CF(0, -0.05, -0.04), WHITE)
	ctx:Part(g, "Clip", "Block", V3(0.26, 0.09, 0.08), board * CF(0, 0.38, -0.05), SILVER, METAL)
end

Builders.Notebook = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G, s = hand(ctx, a, true)
	if not g then
		return
	end
	local book = G * CF(0, 0.08, -0.32) * ANG(0.9, 0, 0)
	ctx:Part(g, "Notebook", "Block", V3(0.46, 0.62, 0.1), book, C.Accent)
	ctx:Part(g, "Pages", "Block", V3(0.42, 0.56, 0.08), book * CF(s * 0.04, 0, -0.01), WHITE)
end

local function batBase(ctx: any, g: Model, G: CFrame, s: number): (Vector3, Vector3)
	local dir = V3(s * 0.3, 1, 0.2).Unit
	local start = G.Position - dir * 0.12
	segment(ctx, g, "BatGrip", start, start + dir * 0.55, 0.13, BLACK, nil, "Cyl")
	return start, dir
end

Builders.SpikedBat = function(ctx: any, a: any, _C: { [string]: Color3 })
	local g, G, s = hand(ctx, a)
	if not g then
		return
	end
	local start, dir = batBase(ctx, g, G, s)
	segment(ctx, g, "BatBarrel", start + dir * 0.55, start + dir * 1.85, 0.27, rgb(160, 110, 60), WOOD, "Cyl")
	local collar = start + dir * 1.5
	segment(ctx, g, "BatCollar", collar - dir * 0.1, collar + dir * 0.1, 0.36, GREY, METAL, "Cyl")
	local side = dir:Cross(V3(0, 0, 1)).Unit
	local fwd = dir:Cross(side).Unit
	for _, v in { side, -side, fwd } do
		segment(ctx, g, "BatSpike", collar, collar + v * 0.32, 0.07, SILVER, METAL)
	end
end

Builders.SignalBat = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G, s = hand(ctx, a)
	if not g then
		return
	end
	local start, dir = batBase(ctx, g, G, s)
	segment(ctx, g, "BatBarrel", start + dir * 0.55, start + dir * 1.8, 0.25, SILVER, METAL, "Cyl")
	segment(ctx, g, "BatCoil", start + dir * 0.75, start + dir * 1.1, 0.31, rgb(205, 115, 45), METAL, "Cyl")
	for _, t in { 1.3, 1.6 } do
		local p = start + dir * t
		segment(ctx, g, "BatSignal", p - dir * 0.05, p + dir * 0.05, 0.3, C.Glow, NEON, "Cyl")
	end
end

Builders.Detector = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "Detector", "Block", V3(0.42, 0.32, 0.62), G * CF(0, 0.06, -0.32), rgb(180, 170, 140))
	ctx:Part(g, "DetectorScreen", "Block", V3(0.28, 0.04, 0.3), G * CF(0, 0.23, -0.26), C.Glow, NEON)
	ctx:Part(g, "DetectorDish", "Cyl", V3(0.08, 0.42, 0.42), G * CF(0, 0.12, -0.68) * FORWARD, SILVER, METAL)
	ctx:Part(g, "DetectorRod", "Cyl", V3(0.5, 0.05, 0.05), G * CF(0.12, 0.45, -0.45) * UPRIGHT, BLACK)
end

Builders.Lantern = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "LanternHandle", "Block", V3(0.32, 0.06, 0.06), G * CF(0, -0.2, 0), BLACK)
	ctx:Part(g, "LanternCap", "Block", V3(0.42, 0.12, 0.42), G * CF(0, -0.3, 0), DARKGREY, METAL)
	ctx:Part(g, "LanternGlass", "Cyl", V3(0.46, 0.34, 0.34), G * CF(0, -0.6, 0) * UPRIGHT, C.Glow, NEON)
	ctx:Part(g, "LanternBase", "Block", V3(0.42, 0.1, 0.42), G * CF(0, -0.88, 0), DARKGREY, METAL)
end

Builders.FishingRod = function(ctx: any, a: any, _C: { [string]: Color3 })
	local g, G, s = hand(ctx, a)
	if not g then
		return
	end
	local dir = V3(s * 0.15, 0.75, -0.65).Unit
	local start = G.Position - dir * 0.3
	local tip = start + dir * 2.8
	segment(ctx, g, "RodHandle", start, start + dir * 0.5, 0.13, rgb(190, 150, 100), nil, "Cyl")
	segment(ctx, g, "Rod", start + dir * 0.5, tip, 0.07, rgb(40, 40, 60), nil, "Cyl")
	ctx:Part(g, "Reel", "Cyl", V3(0.12, 0.22, 0.22), CF(start + dir * 0.45 + V3(s * 0.12, 0, 0)), SILVER, METAL)
	local lineLen = math.max(0.4, tip.Y - 0.45)
	ctx:Part(g, "Line", "Block", V3(0.025, lineLen, 0.025), CF(tip - V3(0, lineLen / 2, 0)), WHITE, nil, { Transparency = 0.3 })
	ctx:Part(g, "Bobber", "Ball", V3(0.18, 0.18, 0.18), CF(tip - V3(0, lineLen, 0)), RED)
end

Builders.Wrench = function(ctx: any, a: any, _C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "Wrench", "Block", V3(0.14, 0.95, 0.08), G * CF(0, -0.2, -0.06), GREY, METAL)
	for _, side in { -1, 1 } do
		ctx:Part(g, "WrenchJaw", "Block", V3(0.1, 0.26, 0.08), G * CF(side * 0.11, -0.72, -0.06), GREY, METAL)
	end
end

Builders.CoffeePot = function(ctx: any, a: any, _C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "PotHandle", "Block", V3(0.08, 0.38, 0.1), G * CF(0, -0.32, -0.06), BLACK)
	ctx:Part(g, "PotLid", "Cyl", V3(0.12, 0.38, 0.38), G * CF(0, -0.18, -0.32) * UPRIGHT, BLACK)
	ctx:Part(g, "Pot", "Cyl", V3(0.55, 0.46, 0.46), G * CF(0, -0.5, -0.32) * UPRIGHT, rgb(110, 60, 30), GLASS, { Transparency = 0.15 })
end

Builders.Microphone = function(ctx: any, a: any, _C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "MicHandle", "Cyl", V3(0.42, 0.12, 0.12), G * CF(0, 0.16, -0.08) * UPRIGHT, BLACK)
	ctx:Part(g, "MicHead", "Ball", V3(0.27, 0.27, 0.27), G * CF(0, 0.44, -0.08), SILVER, METAL)
end

Builders.Crossbow = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "Stock", "Block", V3(0.16, 0.16, 1.05), G * CF(0, 0.06, -0.38), rgb(70, 50, 40), WOOD)
	for _, side in { -1, 1 } do
		ctx:Part(g, "BowArm", "Block", V3(0.62, 0.08, 0.08), G * CF(side * 0.3, 0.1, -0.82) * ANG(0, side * 0.35, 0), DARKGREY, METAL)
	end
	ctx:Part(g, "Bolt", "Block", V3(0.05, 0.05, 0.8), G * CF(0, 0.17, -0.55), C.Glow, NEON)
end

Builders.Staff = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "StaffPole", "Cyl", V3(3.2, 0.14, 0.14), G * CF(0, 0.6, -0.15) * UPRIGHT, darker(C.Accent, 0.4))
	ctx:Part(g, "StaffOrb", "Ball", V3(0.42, 0.42, 0.42), G * CF(0, 2.38, -0.15), C.Glow, NEON)
	for _, side in { -1, 1 } do
		ctx:Part(g, "StaffProng", "Block", V3(0.08, 0.5, 0.08), G * CF(side * 0.22, 2.35, -0.15) * ANG(0, 0, -side * 0.25), C.Accent, METAL)
	end
end

Builders.GateKey = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "KeyShaft", "Cyl", V3(2.4, 0.2, 0.2), G * CF(0, 0.5, -0.2) * UPRIGHT, C.Accent, METAL)
	ctx:Part(g, "KeyBow", "Cyl", V3(0.14, 0.85, 0.85), G * CF(0, 1.95, -0.2) * FORWARD, C.Accent, METAL)
	ctx:Part(g, "KeyCore", "Cyl", V3(0.18, 0.42, 0.42), G * CF(0, 1.95, -0.2) * FORWARD, C.Glow, NEON)
	ctx:Part(g, "KeyBit", "Block", V3(0.45, 0.16, 0.12), G * CF(0.2, -0.55, -0.2), C.Accent, METAL)
	ctx:Part(g, "KeyBit", "Block", V3(0.32, 0.14, 0.12), G * CF(0.14, -0.32, -0.2), C.Accent, METAL)
end

Builders.PhoneHandset = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "Earpiece", "Block", V3(0.24, 0.2, 0.22), G * CF(0, 0.45, -0.12), C.Accent)
	ctx:Part(g, "Handset", "Block", V3(0.14, 0.62, 0.14), G * CF(0, 0.15, -0.1), C.Accent)
	ctx:Part(g, "Mouthpiece", "Block", V3(0.24, 0.2, 0.22), G * CF(0, -0.16, -0.12), C.Accent)
	ctx:Part(g, "Cord", "Cyl", V3(0.5, 0.08, 0.08), G * CF(0, -0.5, -0.05) * UPRIGHT, darker(C.Accent, 0.3))
end

Builders.Cassette = function(ctx: any, a: any, _C: { [string]: Color3 })
	local g, G = hand(ctx, a, true)
	if not g then
		return
	end
	ctx:Part(g, "Tape", "Block", V3(0.13, 0.42, 0.72), G * CF(0, 0.05, -0.2), BLACK)
	ctx:Part(g, "TapeLabel", "Block", V3(0.14, 0.18, 0.5), G * CF(0, 0.08, -0.2), WHITE)
end

Builders.StopSign = function(ctx: any, a: any, _C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "SignPole", "Cyl", V3(2.0, 0.1, 0.1), G * CF(0, 0.5, -0.1) * UPRIGHT, GREY, METAL)
	ctx:Part(g, "Sign", "Cyl", V3(0.06, 0.95, 0.95), G * CF(0, 1.58, -0.14) * FORWARD, RED)
	ctx:Part(g, "SignBar", "Block", V3(0.62, 0.13, 0.07), G * CF(0, 1.58, -0.18), WHITE)
end

Builders.Boombox = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G, s = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "BoomboxHandle", "Block", V3(0.8, 0.08, 0.08), G * CF(s * 0.25, -0.04, 0), BLACK)
	ctx:Part(g, "Boombox", "Block", V3(1.2, 0.6, 0.36), G * CF(s * 0.25, -0.4, 0), DARKGREY)
	for _, x in { -0.32, 0.32 } do
		ctx:Part(g, "Speaker", "Cyl", V3(0.06, 0.42, 0.42), G * CF(s * 0.25 + x, -0.4, -0.19) * FORWARD, C.Accent)
	end
end

Builders.Shield = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G, s = hand(ctx, a, true)
	if not g then
		return
	end
	ctx:Part(g, "Shield", "Block", V3(1.0, 1.55, 0.1), G * CF(s * 0.1, 0.3, -0.45), C.Accent, GLASS, { Transparency = 0.35 })
	ctx:Part(g, "ShieldRim", "Block", V3(1.04, 0.12, 0.14), G * CF(s * 0.1, 1.05, -0.45), DARKGREY, METAL)
end

Builders.Skateboard = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G, s = hand(ctx, a, true)
	if not g then
		return
	end
	ctx:Part(g, "Deck", "Block", V3(0.1, 1.6, 0.52), G * CF(s * 0.18, 0.1, 0), C.Accent)
	for _, y in { -0.5, 0.7 } do
		ctx:Part(g, "Truck", "Block", V3(0.18, 0.14, 0.58), G * CF(s * 0.32, y, 0), WHITE)
	end
end

Builders.Magnifier = function(ctx: any, a: any, _C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	if not g then
		return
	end
	ctx:Part(g, "MagHandle", "Cyl", V3(0.36, 0.1, 0.1), G * CF(0, 0.15, -0.15) * UPRIGHT, BLACK)
	ctx:Part(g, "MagRim", "Cyl", V3(0.06, 0.52, 0.52), G * CF(0, 0.58, -0.15) * FORWARD, GOLD, METAL)
	ctx:Part(g, "MagLens", "Cyl", V3(0.05, 0.42, 0.42), G * CF(0, 0.58, -0.16) * FORWARD, rgb(200, 235, 255), GLASS, { Transparency = 0.5 })
end

Builders.Crystal = function(ctx: any, a: any, C: { [string]: Color3 })
	local g, G = hand(ctx, a)
	local base: CFrame
	if g then
		base = G * CF(0, 0.75, -0.3)
	else
		local tg, tcf = topAnchor(a)
		if not tg or not tcf then
			return
		end
		g = tg
		base = tcf * CF(0, 1.0, 0)
	end
	ctx:Part(g :: Model, "Crystal", "Block", V3(0.38, 0.62, 0.38), base * ANG(0, math.pi / 4, 0.25), C.Glow, NEON)
	ctx:Part(g :: Model, "CrystalShell", "Block", V3(0.5, 0.78, 0.5), base * ANG(0, math.pi / 4, 0.25), WHITE, GLASS, { Transparency = 0.6 })
end

-------------------------------------------------------------------------------
-- Füße
-------------------------------------------------------------------------------
Builders.Rollerskates = function(ctx: any, a: any, C: { [string]: Color3 })
	local F = a.Feet
	if not F then
		return
	end
	if a.Parts then
		ctx:Recolor(a.Parts.ShoeL, WHITE)
		ctx:Recolor(a.Parts.ShoeR, WHITE)
	end
	for _, key in { "L", "R" } do
		local foot: CFrame = F[key]
		for _, z in { -0.24, 0.22 } do
			ctx:Part(ctx.Body, "Wheel", "Cyl", V3(F.W + 0.16, 0.22, 0.22), foot * CF(0, -F.H / 2 + 0.11, z), C.Accent, NEON)
		end
	end
end

-------------------------------------------------------------------------------
-- Orbit
-------------------------------------------------------------------------------
local DEBRIS = {
	{ 0.0, -0.6, 0.55 },
	{ 1.26, 0.4, 0.4 },
	{ 2.51, 0.9, 0.6 },
	{ 3.77, -0.2, 0.35 },
	{ 5.03, 0.6, 0.45 },
}
Builders.OrbitDebris = function(ctx: any, a: any, C: { [string]: Color3 })
	if not a.Center then
		return
	end
	local g = orbitGroup(ctx, a)
	local c = a.Center
	local r = a.OrbitR or 2.4
	for i, d in DEBRIS do
		local cf = c * CF(math.cos(d[1]) * r, d[2], math.sin(d[1]) * r) * ANG(d[1], d[1] * 2, d[1] * 0.5)
		local glow = i % 2 == 0
		ctx:Part(g, "Debris", "Block", V3(d[3], d[3] * 0.8, d[3] * 0.9), cf, if glow then C.Glow else C.Accent, if glow then NEON else Enum.Material.Slate)
	end
end

Builders.OrbitRing = function(ctx: any, a: any, C: { [string]: Color3 })
	if not a.Center then
		return
	end
	local g = orbitGroup(ctx, a)
	ring(ctx, g, "OrbitRing", a.Center * ANG(0.18, 0, -0.12), (a.OrbitR or 2.4) * 0.92, 0.12, 12, C.Glow, NEON, "Glow")
end

Builders.OrbitEyes = function(ctx: any, a: any, C: { [string]: Color3 })
	if not a.Center then
		return
	end
	local g = orbitGroup(ctx, a)
	local r = (a.OrbitR or 2.4) + 0.2
	for i = 0, 3 do
		local theta = i / 4 * math.pi * 2 + 0.4
		local dir = V3(math.cos(theta), 0, math.sin(theta))
		local p = a.Center.Position + dir * r + V3(0, (i % 2) * 0.8 - 0.3, 0)
		ctx:Part(g, "OrbitEye", "Ball", V3(0.5, 0.5, 0.5), CF(p), WHITE, nil, { Role = "Eye" })
		ctx:Part(g, "OrbitPupil", "Ball", V3(0.24, 0.24, 0.24), CF(p + dir * 0.17), C.Glow, NEON, { Role = "Eye" })
	end
end

Accessories.Builders = Builders

local ids = {}
for id in Builders do
	table.insert(ids, id)
end
table.sort(ids)
Accessories.Ids = ids

function Accessories.Has(id: string): boolean
	return Builders[id] ~= nil
end

-- Baut ein Accessory. Rollt bei Fehler oder Budget-Überschreitung komplett zurück.
-- Rückgabe: true = gebaut (oder still übersprungen), false = verworfen.
function Accessories.Build(ctx: any, a: any, id: string, C: { [string]: Color3 }): boolean
	local fn = Builders[id]
	if not fn then
		warn("[ModelFactory.Accessories] Unbekanntes Accessory: " .. tostring(id))
		return false
	end
	local cp = ctx:Checkpoint()
	local flags = { a.HeldUsed, a.LeftUsed, a.HasWings, a.HasTail, a.Head and a.Head.HairTop }
	local ok, err = pcall(fn :: any, ctx, a, C)
	if not ok or ctx.Count > ctx.Limit then
		if not ok then
			warn(string.format("[ModelFactory.Accessories] '%s' fehlgeschlagen: %s", id, tostring(err)))
		end
		ctx:Rollback(cp)
		a.HeldUsed, a.LeftUsed, a.HasWings, a.HasTail = flags[1], flags[2], flags[3], flags[4]
		if a.Head then
			a.Head.HairTop = flags[5]
		end
		return false
	end
	return true
end

return Accessories
