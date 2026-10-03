--!strict
-- Faces (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Visual > ModelFactory > Faces
--
-- Part-basierte Gesichter (keine Decals): kleine schwarze bzw. leuchtende Parts
-- auf der Vorderseite des Kopfes. Billig und aus der Distanz gut lesbar.
--
-- Face-Vokabular:
--   Smile       Augen + lächelnder Mund
--   Determined  Augen + schräge, entschlossene Brauen + gerader Mund
--   Worried     Augen + besorgte Brauen + kleiner offener Mund
--   Calm        geschlossene Strich-Augen + kleiner Mund
--   Grin        Augen + breites Grinsen (weiß, dunkel umrandet)
--   GlowEyes    zwei leuchtende Augen (Visual.Glow)
--   Visor       leuchtender Visier-Balken
--   Blank       kein Gesicht
--   Hollow      dunkle Augenhöhlen mit glimmenden Pupillen + Mundschlitz
--   ManyEyes    sieben leuchtende Augen
--   Mask        glatte Maske (Visual.Accent) mit leuchtenden Sehschlitzen
--
-- Face-Anker (von Bodies): { Group, CF (Mitte der Vorderfläche, Blick -Z), W, H, Round? }
-- Round = Radius bei runden Köpfen -> Teile folgen der Krümmung.

local Faces = {}

local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local rgb = Color3.fromRGB

local DARK = rgb(24, 18, 28)
local WHITE = rgb(245, 245, 245)

Faces.Types = {
	"Smile",
	"Determined",
	"Worried",
	"Calm",
	"Grin",
	"GlowEyes",
	"Visor",
	"Blank",
	"Hollow",
	"ManyEyes",
	"Mask",
}

-- CFrame auf der Gesichtsfläche bei (x, y), "out" Studs davor
local function at(F: any, x: number, y: number, out: number): CFrame
	local back = 0
	local yaw = 0
	if F.Round then
		local r = F.Round
		local xx = math.clamp(x, -r * 0.9, r * 0.9)
		back = r - math.sqrt(r * r - xx * xx)
		yaw = -math.asin(xx / r)
	end
	return F.CF * CF(x, y, back - out) * ANG(0, yaw, 0)
end

local function piece(ctx: any, F: any, name: string, x: number, y: number, w: number, h: number, color: Color3, material: Enum.Material?, depth: number?, rot: number?, shape: string?)
	local d = depth or 0.06
	local cf = at(F, x, y, d / 2 - 0.015)
	if rot then
		cf *= ANG(0, 0, rot)
	end
	return ctx:Part(F.Group, name, shape or "Block", V3(w, h, d), cf, color, material, { Role = "Eye" })
end

-- Strich von (x1,y1) nach (x2,y2) auf der Gesichtsfläche
local function stroke(ctx: any, F: any, name: string, x1: number, y1: number, x2: number, y2: number, thick: number, color: Color3)
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	return piece(ctx, F, name, (x1 + x2) / 2, (y1 + y2) / 2, len, thick, color, nil, 0.06, math.atan2(dy, dx))
end

local function eyes(ctx: any, F: any, color: Color3?, material: Enum.Material?, scaleW: number?, scaleH: number?)
	local W, H = F.W, F.H
	local ex, ey = W * 0.2, H * 0.08
	for _, side in { -1, 1 } do
		piece(ctx, F, "Eye", side * ex, ey, W * 0.13 * (scaleW or 1), H * 0.22 * (scaleH or 1), color or DARK, material)
	end
end

local Builders: { [string]: (ctx: any, F: any, C: { [string]: Color3 }) -> () } = {}

Builders.Smile = function(ctx: any, F: any, _C: { [string]: Color3 })
	local W, H = F.W, F.H
	eyes(ctx, F)
	stroke(ctx, F, "Mouth", -W * 0.15, -H * 0.17, -W * 0.02, -H * 0.23, H * 0.05, DARK)
	stroke(ctx, F, "Mouth", W * 0.02, -H * 0.23, W * 0.15, -H * 0.17, H * 0.05, DARK)
end

Builders.Determined = function(ctx: any, F: any, _C: { [string]: Color3 })
	local W, H = F.W, F.H
	local ex, ey = W * 0.2, H * 0.08
	eyes(ctx, F)
	for _, side in { -1, 1 } do
		stroke(ctx, F, "Brow", side * (ex + W * 0.1), ey + H * 0.21, side * (ex - W * 0.09), ey + H * 0.14, H * 0.055, DARK)
	end
	piece(ctx, F, "Mouth", 0, -H * 0.21, W * 0.22, H * 0.05, DARK)
end

Builders.Worried = function(ctx: any, F: any, _C: { [string]: Color3 })
	local W, H = F.W, F.H
	local ex, ey = W * 0.2, H * 0.08
	eyes(ctx, F)
	for _, side in { -1, 1 } do
		stroke(ctx, F, "Brow", side * (ex + W * 0.1), ey + H * 0.15, side * (ex - W * 0.09), ey + H * 0.22, H * 0.05, DARK)
	end
	piece(ctx, F, "Mouth", 0, -H * 0.22, W * 0.1, H * 0.09, DARK)
end

Builders.Calm = function(ctx: any, F: any, _C: { [string]: Color3 })
	local W, H = F.W, F.H
	eyes(ctx, F, DARK, nil, 1.1, 0.3)
	piece(ctx, F, "Mouth", 0, -H * 0.2, W * 0.16, H * 0.045, DARK)
end

Builders.Grin = function(ctx: any, F: any, _C: { [string]: Color3 })
	local W, H = F.W, F.H
	eyes(ctx, F)
	piece(ctx, F, "MouthRim", 0, -H * 0.2, W * 0.42, H * 0.2, DARK, nil, 0.05)
	piece(ctx, F, "Teeth", 0, -H * 0.2, W * 0.36, H * 0.13, WHITE, nil, 0.08)
end

Builders.GlowEyes = function(ctx: any, F: any, C: { [string]: Color3 })
	eyes(ctx, F, C.Glow, Enum.Material.Neon, 1.25, 0.65)
end

Builders.Visor = function(ctx: any, F: any, C: { [string]: Color3 })
	local W, H = F.W, F.H
	piece(ctx, F, "VisorFrame", 0, H * 0.08, W * 0.82, H * 0.28, DARK, nil, 0.06)
	piece(ctx, F, "Visor", 0, H * 0.08, W * 0.72, H * 0.15, C.Glow, Enum.Material.Neon, 0.1)
end

Builders.Blank = function(_ctx: any, _F: any, _C: { [string]: Color3 }) end

Builders.Hollow = function(ctx: any, F: any, C: { [string]: Color3 })
	local W, H = F.W, F.H
	local ex, ey = W * 0.21, H * 0.1
	for _, side in { -1, 1 } do
		piece(ctx, F, "Socket", side * ex, ey, W * 0.26, H * 0.32, DARK, nil, 0.06, nil, "Sphere")
		piece(ctx, F, "Pupil", side * ex, ey, W * 0.07, W * 0.07, C.Glow, Enum.Material.Neon, 0.1)
	end
	piece(ctx, F, "Mouth", 0, -H * 0.24, W * 0.3, H * 0.06, DARK)
end

local MANY = {
	{ -0.27, 0.16, 0.14 },
	{ 0.27, 0.16, 0.14 },
	{ 0, 0.3, 0.12 },
	{ -0.11, -0.02, 0.1 },
	{ 0.11, -0.02, 0.1 },
	{ -0.33, -0.17, 0.08 },
	{ 0.33, -0.17, 0.08 },
}
Builders.ManyEyes = function(ctx: any, F: any, C: { [string]: Color3 })
	local W, H = F.W, F.H
	for _, e in MANY do
		local d = e[3] * W
		local cf = at(F, e[1] * W, e[2] * H, 0)
		ctx:Part(F.Group, "Eye", "Ball", V3(d, d, d), cf, C.Glow, Enum.Material.Neon, { Role = "Eye" })
	end
end

Builders.Mask = function(ctx: any, F: any, C: { [string]: Color3 })
	local W, H = F.W, F.H
	piece(ctx, F, "Mask", 0, 0, W * 0.8, H * 0.78, C.Accent, nil, 0.1)
	for _, side in { -1, 1 } do
		piece(ctx, F, "Slit", side * W * 0.18, H * 0.1, W * 0.17, H * 0.06, C.Glow, Enum.Material.Neon, 0.14)
	end
end

Faces.Builders = Builders

function Faces.Has(faceType: string): boolean
	return Builders[faceType] ~= nil
end

function Faces.Build(ctx: any, F: any, faceType: string, C: { [string]: Color3 })
	local builder = Builders[faceType]
	if not builder then
		warn("[ModelFactory.Faces] Unbekannter Face-Typ: " .. tostring(faceType))
		builder = Builders.Smile
	end
	builder(ctx, F, C)
end

return Faces
