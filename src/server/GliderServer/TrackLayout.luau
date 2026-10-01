-- TrackLayout (ModuleScript)
-- Ort: ServerScriptService > GliderServer > TrackLayout
--
-- Beschreibt die Teststrecke Abschnitt für Abschnitt. Hier kannst du die Map
-- später am einfachsten ändern: Längen, Breiten, Tore, Säulen...
--
-- Koordinaten innerhalb eines Abschnitts (relativ zu "base"):
--   x = links (-) / rechts (+) von der Mitte
--   y = Höhe über dem Boden
--   d = Distanz vom Abschnittsanfang nach vorne
--
-- Gesamtlänge ca. 7000 Studs, bei ~95-100 Studs/s also ungefähr 70 Sekunden.

local MapBuilder = require(script.Parent.MapBuilder)

local C = Color3.fromRGB

-- Farben je Abschnitt, damit man beim Testen sofort weiß, wo man ist
local STYLE_START = { wallColor = C(120, 115, 105), floorColor = C(90, 140, 75) }
local STYLE_ROCK = { wallColor = C(95, 92, 88), floorColor = C(105, 110, 80), ribColor = C(70, 68, 66) }
local STYLE_GATES = { wallColor = C(100, 110, 120), floorColor = C(80, 125, 90), ribColor = C(75, 85, 95) }
local STYLE_CANYON = {
	wallColor = C(170, 95, 60),
	floorColor = C(190, 150, 100),
	wallMaterial = Enum.Material.Sandstone,
	floorMaterial = Enum.Material.Sand,
	ribColor = C(140, 75, 45),
}
local STYLE_NARROW = { wallColor = C(85, 95, 85), floorColor = C(70, 110, 65), ribColor = C(60, 70, 60) }
local STYLE_TUNNEL = { wallColor = C(70, 70, 78), floorColor = C(80, 80, 80), floorMaterial = Enum.Material.Concrete, ribColor = C(55, 55, 60) }
local STYLE_UPDOWN = { wallColor = C(105, 100, 120), floorColor = C(95, 120, 85), ribColor = C(80, 75, 95) }
local STYLE_FINAL = { wallColor = C(60, 55, 60), floorColor = C(70, 75, 65), wallMaterial = Enum.Material.Basalt, ribColor = C(110, 40, 40) }
local STYLE_FINISH = { wallColor = C(120, 115, 105), floorColor = C(90, 140, 75) }

local ROCK = C(100, 96, 90)
local ROCK_DARK = C(75, 72, 70)
local CANYON_ROCK = C(150, 85, 55)
local GATE_WALL = C(115, 120, 130)
local FINAL_ROCK = C(55, 50, 55)

local TrackLayout = {}

function TrackLayout.Build(origin: CFrame?): Model
	-- Strecke startet etwas abseits vom Ursprung (Baseplate-Spawn liegt bei 0,0,0)
	local b = MapBuilder.new(origin or CFrame.new(0, 0, -300))
	local base: CFrame

	---------------------------------------------------------------------------
	-- 1) BREITER STARTBEREICH
	---------------------------------------------------------------------------
	local W = 260
	base = b:Corridor(620, W, STYLE_START)
	-- Rückwand + Startklippe
	b:Box(base, -W / 2, W / 2, 0, 198, 0, 20, ROCK_DARK)
	b:Box(base, -W / 2, W / 2, 0, 52, 20, 110, ROCK)
	b:Start(base, 140, 60, 52)
	-- Zwei Felstürme als Orientierung und ein großes, leichtes Einstiegstor
	b:Pillar(base, -85, 300, 22, ROCK)
	b:Pillar(base, 85, 300, 22, ROCK)
	b:WallWithHole(base, 450, W, 110, 80, 0, 65, GATE_WALL)
	b:Checkpoint("Felswände")

	---------------------------------------------------------------------------
	-- 2) GROSSE FELSWÄNDE (Slalom + Rechtskurve + Überhang)
	---------------------------------------------------------------------------
	W = 200
	base = b:Corridor(320, W, STYLE_ROCK)
	b:Box(base, -100, 15, 0, 198, 140, 180, ROCK) -- links (rechts vorbei)
	b:Box(base, -15, 100, 0, 198, 260, 300, ROCK) -- rechts (links vorbei)
	b:Turn(-30, 300, W, STYLE_ROCK)
	base = b:Corridor(280, W, STYLE_ROCK)
	b:Box(base, -100, 0, 0, 198, 60, 100, ROCK)
	b:Box(base, 0, 100, 0, 198, 160, 200, ROCK)
	b:Box(base, -100, 100, 110, 198, 235, 260, ROCK_DARK) -- Überhang: unten durch
	b:Checkpoint("Tore")

	---------------------------------------------------------------------------
	-- 3) TORE: Wände mit Öffnungen, durch die man fliegen muss
	---------------------------------------------------------------------------
	W = 220
	base = b:Corridor(900, W, STYLE_GATES)
	--                   d    breite höhe   x    y
	b:WallWithHole(base, 150, W, 60, 50, -40, 55, GATE_WALL)
	b:WallWithHole(base, 330, W, 55, 45, 50, 85, GATE_WALL)
	b:WallWithHole(base, 510, W, 50, 45, -20, 40, GATE_WALL)
	b:WallWithHole(base, 690, W, 45, 40, 45, 95, GATE_WALL)
	b:WallWithHole(base, 850, W, 45, 40, -10, 60, GATE_WALL)
	b:Checkpoint("Schlucht")

	---------------------------------------------------------------------------
	-- 4) SCHLUCHT: schmal, Kurven, Felsvorsprünge, Felsbrücke
	---------------------------------------------------------------------------
	W = 100
	b:Corridor(200, W, STYLE_CANYON)
	b:Turn(35, 250, W, STYLE_CANYON)
	base = b:Corridor(180, W, STYLE_CANYON)
	b:Box(base, -50, -22, 0, 120, 50, 80, CANYON_ROCK) -- Vorsprung links unten
	b:Box(base, 22, 50, 60, 198, 120, 150, CANYON_ROCK) -- Vorsprung rechts oben
	b:Turn(-45, 300, W, STYLE_CANYON)
	base = b:Corridor(220, W, STYLE_CANYON)
	b:Box(base, -50, 50, 85, 110, 100, 125, CANYON_ROCK) -- Felsbrücke: drunter oder drüber
	b:Checkpoint("Engstellen")

	---------------------------------------------------------------------------
	-- 5) ENGE PASSAGEN + HINDERNISSE LINKS/RECHTS
	---------------------------------------------------------------------------
	W = 140
	base = b:Corridor(900, W, STYLE_NARROW)
	-- Enge Stelle in der Mitte (50 breit)
	b:Box(base, -70, -25, 0, 198, 120, 200, ROCK)
	b:Box(base, 25, 70, 0, 198, 120, 200, ROCK)
	-- Säulen-Slalom
	b:Pillar(base, -30, 280, 16, ROCK_DARK)
	b:Pillar(base, 30, 340, 16, ROCK_DARK)
	b:Pillar(base, 0, 400, 16, ROCK_DARK)
	-- Enge Passage links versetzt (Lücke x -55..-5)
	b:Box(base, -70, -55, 0, 198, 480, 570, ROCK)
	b:Box(base, -5, 70, 0, 198, 480, 570, ROCK)
	-- Enge Passage rechts versetzt (Lücke x 5..50)
	b:Box(base, -70, 5, 0, 198, 700, 790, ROCK)
	b:Box(base, 50, 70, 0, 198, 700, 790, ROCK)
	b:Pillar(base, 0, 860, 14, ROCK_DARK)
	b:Checkpoint("Tunnel")

	---------------------------------------------------------------------------
	-- 6) KURZER TUNNEL (Innenraum 50 breit, Höhe 30..70)
	---------------------------------------------------------------------------
	W = 140
	base = b:Corridor(520, W, STYLE_TUNNEL)
	local t0, t1 = 130, 450
	b:Box(base, -70, -25, 0, 198, t0, t1, ROCK_DARK)
	b:Box(base, 25, 70, 0, 198, t0, t1, ROCK_DARK)
	b:Box(base, -25, 25, 0, 30, t0, t1, ROCK_DARK)
	b:Box(base, -25, 25, 70, 198, t0, t1, ROCK_DARK)
	-- Im Tunnel: erst von oben (unten durch), dann von unten (oben drüber)
	b:Box(base, -25, 25, 52, 70, 260, 272, C(200, 60, 50))
	b:Box(base, -25, 25, 30, 48, 360, 372, C(200, 60, 50))
	-- Leuchtstreifen im Tunnel (nur Optik) + ein paar Lichter
	local stripe = C(120, 220, 255)
	local d = t0 + 10
	local n = 0
	while d < t1 do
		b:Box(base, -25, -24.4, 30, 70, d, d + 1.5, stripe, Enum.Material.Neon, true)
		b:Box(base, 24.4, 25, 30, 70, d, d + 1.5, stripe, Enum.Material.Neon, true)
		local ceiling = b:Box(base, -25, 25, 69.4, 70, d, d + 1.5, stripe, Enum.Material.Neon, true)
		n += 1
		if ceiling and n % 2 == 0 then
			local light = Instance.new("PointLight")
			light.Range = 35
			light.Brightness = 1.5
			light.Color = stripe
			light.Parent = ceiling
		end
		d += 30
	end
	b:Checkpoint("Hoch & Runter")

	---------------------------------------------------------------------------
	-- 7) HOCH UND RUNTER: Wände mit waagerechten Schlitzen
	---------------------------------------------------------------------------
	W = 160
	base = b:Corridor(950, W, STYLE_UPDOWN)
	local slotHeight = 38
	for _, slot in { { 150, 40 }, { 300, 100 }, { 450, 45 }, { 600, 105 }, { 730, 60 }, { 860, 95 } } do
		b:WallWithHole(base, slot[1], W, W, slotHeight, 0, slot[2], GATE_WALL, C(255, 120, 40))
	end
	b:Checkpoint("Finale")

	---------------------------------------------------------------------------
	-- 8) SCHWIERIGER LETZTER ABSCHNITT
	---------------------------------------------------------------------------
	W = 150
	base = b:Corridor(560, W, STYLE_FINAL)
	local red = C(255, 70, 70)
	b:WallWithHole(base, 150, W, 34, 30, -30, 50, FINAL_ROCK, red)
	b:WallWithHole(base, 290, W, 32, 30, 25, 80, FINAL_ROCK, red)
	b:Pillar(base, -15, 390, 14, FINAL_ROCK)
	b:Pillar(base, 45, 390, 14, FINAL_ROCK)
	b:WallWithHole(base, 490, W, 30, 28, 0, 45, FINAL_ROCK, red)
	b:Checkpoint("Letzte Kurve")

	b:Turn(40, 260, W, STYLE_FINAL)
	base = b:Corridor(320, W, STYLE_FINAL)
	b:WallWithHole(base, 80, W, W, 45, 0, 47.5, FINAL_ROCK, red, 20) -- dicker Schlitz
	b:WallWithHole(base, 190, W, 30, 30, -30, 55, FINAL_ROCK, red)
	b:WallWithHole(base, 300, W, 28, 26, 10, 70, FINAL_ROCK, red)

	---------------------------------------------------------------------------
	-- 9) ZIELBEREICH
	---------------------------------------------------------------------------
	W = 220
	base = b:Corridor(380, W, STYLE_FINISH)
	b:Finish(base, 40, W)
	b:Box(base, -W / 2, W / 2, 0, 198, 360, 380, ROCK_DARK) -- Endwand

	return b:Finalize()
end

return TrackLayout
