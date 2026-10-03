--!strict
-- AuraLibrary (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Visual > AuraLibrary
--
-- Alle Aura-/Partikel-Effekte an einer Stelle. Wird benutzt von:
--   * CharacterConfig.AuraReference      (Character-Aura, z. B. "PsychicBlue")
--   * MutationConfig.Effect              (z. B. "ElectricSparks", "VoidVortex")
--   * ModelFactory.ApplyLevelVisual      ("LevelGlow1", "LevelGlow2", "LevelMax")
--
-- Keine externen Assets: nur die eingebauten rbxasset-Texturen.
--
-- Felder pro Eintrag:
--   Color / Color2   Farbverlauf der Partikel (Start -> Ende)
--   Light            nil = kein Licht, sonst { Brightness, Range } (Range in Studs
--                    bei einem 5-Studs-Character, wird mit der Model-Größe skaliert)
--   Particles        nil = keine Partikel, sonst:
--                      Texture        rbxasset-Pfad (nil = Roblox-Standard)
--                      Rate           Partikel/Sekunde bei Stärke 1 (max. 20)
--                      Lifetime       { min, max } Sekunden
--                      Speed          { min, max } Studs/Sekunde
--                      Size           Startgröße (Studs bei 5-Studs-Character)
--                      Size2          Endgröße (nil = Size * 0.3)
--                      LightEmission  0..1
--                      Transparency   Start-Transparenz (Ende immer 1)
--                      Spread         SpreadAngle in Grad (beide Achsen)
--                      Rise           Beschleunigung nach oben (negativ = fällt)
--                      Drag           Luftwiderstand
--                      RotSpeed       Drehung in Grad/Sekunde (+/-)
--                      Height         Höhe des Emitters relativ zur Model-Höhe (0 = Füße, 1 = Kopf)
--   Ring             true = ModelFactory legt eine leuchtende Bodenscheibe unter den Character
--
-- AuraLibrary.Apply(target, auraId, strength, options) hängt Partikel + Licht an
-- ein Attachment (target = Attachment) oder legt unter einem BasePart ein neues
-- Attachment an. Mit options.LowDetail = true wird NICHTS erzeugt.

export type ParticleSpec = {
	Texture: string?,
	Rate: number,
	Lifetime: { number },
	Speed: { number },
	Size: number,
	Size2: number?,
	LightEmission: number,
	Transparency: number?,
	Spread: number?,
	Rise: number?,
	Drag: number?,
	RotSpeed: number?,
	Height: number?,
}

export type AuraDef = {
	Id: string,
	Color: Color3,
	Color2: Color3,
	Light: { Brightness: number, Range: number }?,
	Particles: ParticleSpec?,
	Ring: boolean?,
}

export type ApplyOptions = {
	Color: Color3?,
	Color2: Color3?,
	Scale: number?,
	LowDetail: boolean?,
	Name: string?,
	Offset: Vector3?,
}

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

local MAX_RATE = 20

local rgb = Color3.fromRGB

local AuraLibrary = {}

AuraLibrary.Textures = { Sparkle = SPARKLE, Smoke = SMOKE, Fire = FIRE }

local defs: { [string]: AuraDef } = {
	---------------------------------------------------------------------------
	-- Level-Visuals (Farbe wird von ModelFactory mit der Rarity-Farbe überschrieben)
	---------------------------------------------------------------------------
	LevelGlow1 = {
		Id = "LevelGlow1", Color = rgb(255, 255, 255), Color2 = rgb(200, 220, 255),
		Light = nil,
		Particles = { Texture = SPARKLE, Rate = 4, Lifetime = { 1, 1.6 }, Speed = { 0.5, 1 }, Size = 0.35,
			LightEmission = 0.8, Transparency = 0.2, Spread = 60, Rise = 1.5, Height = 0.05 },
	},
	LevelGlow2 = {
		Id = "LevelGlow2", Color = rgb(255, 255, 255), Color2 = rgb(200, 220, 255),
		Light = { Brightness = 0.8, Range = 8 },
		Particles = { Texture = SPARKLE, Rate = 8, Lifetime = { 1.2, 1.8 }, Speed = { 0.6, 1.4 }, Size = 0.45,
			LightEmission = 1, Transparency = 0.1, Spread = 70, Rise = 2, Height = 0.05 },
	},
	LevelMax = {
		Id = "LevelMax", Color = rgb(255, 255, 255), Color2 = rgb(255, 230, 140),
		Light = { Brightness = 1.4, Range = 12 },
		Particles = { Texture = SPARKLE, Rate = 14, Lifetime = { 1.4, 2.2 }, Speed = { 0.8, 1.8 }, Size = 0.6,
			LightEmission = 1, Transparency = 0, Spread = 80, Rise = 2.5, RotSpeed = 90, Height = 0.05 },
		Ring = true,
	},

	---------------------------------------------------------------------------
	-- Mutationen (MutationConfig.Effect)
	---------------------------------------------------------------------------
	ElectricSparks = {
		Id = "ElectricSparks", Color = rgb(150, 230, 255), Color2 = rgb(60, 140, 255),
		Light = { Brightness = 1, Range = 9 },
		Particles = { Texture = SPARKLE, Rate = 12, Lifetime = { 0.15, 0.35 }, Speed = { 4, 8 }, Size = 0.4,
			Size2 = 0.05, LightEmission = 1, Transparency = 0, Spread = 180, Drag = 4, RotSpeed = 400, Height = 0.55 },
	},
	ShadowSmoke = {
		Id = "ShadowSmoke", Color = rgb(40, 30, 60), Color2 = rgb(5, 0, 10),
		Light = nil,
		Particles = { Texture = SMOKE, Rate = 8, Lifetime = { 1.5, 2.5 }, Speed = { 0.3, 0.8 }, Size = 1.6,
			Size2 = 2.6, LightEmission = 0, Transparency = 0.45, Spread = 180, Rise = 0.6, RotSpeed = 30, Height = 0.15 },
	},
	BloodMist = {
		Id = "BloodMist", Color = rgb(200, 20, 30), Color2 = rgb(80, 0, 10),
		Light = { Brightness = 0.6, Range = 8 },
		Particles = { Texture = SMOKE, Rate = 8, Lifetime = { 1.5, 2.4 }, Speed = { 0.3, 0.7 }, Size = 1.2,
			Size2 = 2.2, LightEmission = 0.3, Transparency = 0.5, Spread = 180, Rise = 0.4, RotSpeed = 20, Height = 0.2 },
	},
	RiftCracks = {
		Id = "RiftCracks", Color = rgb(190, 120, 255), Color2 = rgb(60, 220, 255),
		Light = { Brightness = 0.9, Range = 9 },
		Particles = { Texture = SPARKLE, Rate = 10, Lifetime = { 0.6, 1.1 }, Speed = { 1, 2.5 }, Size = 0.55,
			Size2 = 0.1, LightEmission = 1, Transparency = 0.05, Spread = 180, Drag = 2, RotSpeed = 180, Height = 0.5 },
	},
	GoldSparkle = {
		Id = "GoldSparkle", Color = rgb(255, 230, 120), Color2 = rgb(255, 170, 30),
		Light = { Brightness = 1, Range = 10 },
		Particles = { Texture = SPARKLE, Rate = 12, Lifetime = { 1, 1.6 }, Speed = { 0.5, 1.5 }, Size = 0.5,
			Size2 = 0.1, LightEmission = 1, Transparency = 0, Spread = 180, Rise = 0.8, RotSpeed = 120, Height = 0.6 },
	},
	VoidVortex = {
		Id = "VoidVortex", Color = rgb(150, 60, 255), Color2 = rgb(10, 0, 30),
		Light = { Brightness = 1.2, Range = 11 },
		Particles = { Texture = SMOKE, Rate = 14, Lifetime = { 1.2, 2 }, Speed = { 1, 2 }, Size = 1.1,
			Size2 = 0.2, LightEmission = 0.6, Transparency = 0.2, Spread = 180, Rise = 1.2, Drag = 1, RotSpeed = 220, Height = 0.4 },
		Ring = true,
	},

	---------------------------------------------------------------------------
	-- Character-Auren
	---------------------------------------------------------------------------
	PsychicBlue = {
		Id = "PsychicBlue", Color = rgb(120, 200, 255), Color2 = rgb(60, 90, 255),
		Light = { Brightness = 0.7, Range = 8 },
		Particles = { Texture = SPARKLE, Rate = 6, Lifetime = { 1, 1.6 }, Speed = { 0.4, 1 }, Size = 0.45,
			LightEmission = 1, Transparency = 0.2, Spread = 180, Rise = 0.5, RotSpeed = 60, Height = 0.75 },
	},
	PsionicSurge = {
		Id = "PsionicSurge", Color = rgb(220, 240, 255), Color2 = rgb(90, 120, 255),
		Light = { Brightness = 1.2, Range = 11 },
		Particles = { Texture = SPARKLE, Rate = 12, Lifetime = { 0.8, 1.4 }, Speed = { 1.5, 3 }, Size = 0.6,
			Size2 = 0.1, LightEmission = 1, Transparency = 0, Spread = 180, Drag = 2, RotSpeed = 160, Height = 0.7 },
		Ring = true,
	},
	RiftViolet = {
		Id = "RiftViolet", Color = rgb(170, 90, 255), Color2 = rgb(70, 160, 255),
		Light = { Brightness = 0.8, Range = 9 },
		Particles = { Texture = SPARKLE, Rate = 8, Lifetime = { 1, 1.8 }, Speed = { 0.5, 1.2 }, Size = 0.55,
			LightEmission = 1, Transparency = 0.15, Spread = 180, Rise = 0.8, RotSpeed = 90, Height = 0.5 },
	},
	Static = {
		Id = "Static", Color = rgb(235, 235, 245), Color2 = rgb(120, 130, 150),
		Light = nil,
		Particles = { Texture = SPARKLE, Rate = 10, Lifetime = { 0.1, 0.3 }, Speed = { 2, 5 }, Size = 0.3,
			Size2 = 0.05, LightEmission = 0.7, Transparency = 0.1, Spread = 180, Drag = 6, RotSpeed = 500, Height = 0.6 },
	},
	Ember = {
		Id = "Ember", Color = rgb(255, 200, 80), Color2 = rgb(255, 60, 20),
		Light = { Brightness = 0.9, Range = 9 },
		Particles = { Texture = FIRE, Rate = 9, Lifetime = { 0.8, 1.4 }, Speed = { 0.5, 1.5 }, Size = 0.55,
			Size2 = 0.05, LightEmission = 1, Transparency = 0.2, Spread = 40, Rise = 3, RotSpeed = 60, Height = 0.1 },
	},
	Frost = {
		Id = "Frost", Color = rgb(220, 245, 255), Color2 = rgb(120, 190, 255),
		Light = { Brightness = 0.6, Range = 8 },
		Particles = { Texture = SPARKLE, Rate = 8, Lifetime = { 1.5, 2.5 }, Speed = { 0.2, 0.6 }, Size = 0.35,
			LightEmission = 0.6, Transparency = 0.2, Spread = 180, Rise = -0.6, RotSpeed = 40, Height = 0.9 },
	},
	Spores = {
		Id = "Spores", Color = rgb(170, 255, 120), Color2 = rgb(60, 140, 60),
		Light = { Brightness = 0.4, Range = 7 },
		Particles = { Texture = SPARKLE, Rate = 7, Lifetime = { 2, 3 }, Speed = { 0.2, 0.6 }, Size = 0.3,
			LightEmission = 0.5, Transparency = 0.3, Spread = 180, Rise = 0.3, Drag = 0.5, Height = 0.5 },
	},
	Fireflies = {
		Id = "Fireflies", Color = rgb(255, 250, 140), Color2 = rgb(170, 255, 90),
		Light = { Brightness = 0.5, Range = 7 },
		Particles = { Texture = SPARKLE, Rate = 6, Lifetime = { 2, 3.5 }, Speed = { 0.3, 0.9 }, Size = 0.25,
			LightEmission = 1, Transparency = 0, Spread = 180, Drag = 0.4, Height = 0.6 },
	},
	LakeMist = {
		Id = "LakeMist", Color = rgb(180, 230, 255), Color2 = rgb(60, 120, 170),
		Light = nil,
		Particles = { Texture = SMOKE, Rate = 6, Lifetime = { 2, 3 }, Speed = { 0.2, 0.5 }, Size = 1.2,
			Size2 = 2.2, LightEmission = 0.2, Transparency = 0.6, Spread = 180, Rise = 0.2, RotSpeed = 15, Height = 0.1 },
	},
	RedSignal = {
		Id = "RedSignal", Color = rgb(255, 60, 60), Color2 = rgb(120, 0, 0),
		Light = { Brightness = 1.4, Range = 12 },
		Particles = { Texture = SPARKLE, Rate = 12, Lifetime = { 0.4, 0.9 }, Speed = { 2, 4 }, Size = 0.55,
			Size2 = 0.05, LightEmission = 1, Transparency = 0, Spread = 180, Drag = 3, RotSpeed = 300, Height = 0.6 },
		Ring = true,
	},
	Prism = {
		Id = "Prism", Color = rgb(255, 120, 220), Color2 = rgb(80, 255, 230),
		Light = { Brightness = 1, Range = 10 },
		Particles = { Texture = SPARKLE, Rate = 10, Lifetime = { 1, 1.8 }, Speed = { 0.6, 1.6 }, Size = 0.5,
			Size2 = 0.1, LightEmission = 1, Transparency = 0, Spread = 180, Rise = 0.5, RotSpeed = 140, Height = 0.6 },
	},
	Golden = {
		Id = "Golden", Color = rgb(255, 235, 150), Color2 = rgb(255, 160, 30),
		Light = { Brightness = 1.2, Range = 11 },
		Particles = { Texture = SPARKLE, Rate = 10, Lifetime = { 1.2, 2 }, Speed = { 0.4, 1 }, Size = 0.5,
			LightEmission = 1, Transparency = 0, Spread = 180, Rise = 0.6, RotSpeed = 90, Height = 0.7 },
		Ring = true,
	},
	Abyss = {
		Id = "Abyss", Color = rgb(30, 10, 60), Color2 = rgb(0, 0, 0),
		Light = { Brightness = 0.7, Range = 10 },
		Particles = { Texture = SMOKE, Rate = 10, Lifetime = { 1.8, 2.8 }, Speed = { 0.5, 1.2 }, Size = 2,
			Size2 = 3.2, LightEmission = 0, Transparency = 0.35, Spread = 180, Rise = -0.3, RotSpeed = 25, Height = 0.3 },
		Ring = true,
	},
	Otherglow = {
		Id = "Otherglow", Color = rgb(80, 255, 210), Color2 = rgb(255, 90, 170),
		Light = { Brightness = 0.9, Range = 10 },
		Particles = { Texture = SPARKLE, Rate = 8, Lifetime = { 1.6, 2.6 }, Speed = { 0.2, 0.7 }, Size = 0.4,
			LightEmission = 1, Transparency = 0.1, Spread = 180, Rise = -0.4, Drag = 0.6, Height = 0.8 },
	},
	Starfield = {
		Id = "Starfield", Color = rgb(255, 255, 255), Color2 = rgb(140, 100, 255),
		Light = { Brightness = 1, Range = 12 },
		Particles = { Texture = SPARKLE, Rate = 12, Lifetime = { 1.5, 2.5 }, Speed = { 0.3, 1 }, Size = 0.35,
			Size2 = 0.05, LightEmission = 1, Transparency = 0, Spread = 180, Drag = 0.5, RotSpeed = 60, Height = 0.6 },
		Ring = true,
	},
	NullLight = {
		Id = "NullLight", Color = rgb(255, 255, 255), Color2 = rgb(0, 255, 200),
		Light = { Brightness = 1.6, Range = 14 },
		Particles = { Texture = SPARKLE, Rate = 14, Lifetime = { 1, 1.8 }, Speed = { 1, 2.4 }, Size = 0.6,
			Size2 = 0.05, LightEmission = 1, Transparency = 0, Spread = 180, Drag = 1.5, RotSpeed = 200, Height = 0.6 },
		Ring = true,
	},
}

AuraLibrary.Defs = defs

function AuraLibrary.Get(auraId: string?): AuraDef?
	if auraId == nil then
		return nil
	end
	return defs[auraId]
end

function AuraLibrary.Has(auraId: string): boolean
	return defs[auraId] ~= nil
end

-- Sortierte Liste aller Ids (für Tests/Debug-UI)
function AuraLibrary.Ids(): { string }
	local out = {}
	for id in defs do
		table.insert(out, id)
	end
	table.sort(out)
	return out
end

local function numberRange(r: { number }, scale: number): NumberRange
	local a = r[1] * scale
	local b = (r[2] or r[1]) * scale
	return NumberRange.new(math.min(a, b), math.max(a, b))
end

-- Hängt die Aura an. Gibt das Attachment zurück (nil bei LowDetail/unbekannter Id).
function AuraLibrary.Apply(target: Instance, auraId: string, strength: number?, options: ApplyOptions?): Attachment?
	local def = defs[auraId]
	if not def then
		warn("[AuraLibrary] Unbekannte Aura-Id: " .. tostring(auraId))
		return nil
	end
	local opts: ApplyOptions = options or {}
	if opts.LowDetail then
		return nil
	end
	local s = math.clamp(strength or 1, 0, 1)
	local scale = opts.Scale or 1
	local color1 = opts.Color or def.Color
	local color2 = opts.Color2 or (if opts.Color then opts.Color:Lerp(def.Color2, 0.35) else def.Color2)

	local attachment: Attachment
	if target:IsA("Attachment") then
		attachment = target :: Attachment
	else
		attachment = Instance.new("Attachment")
		attachment.Name = opts.Name or ("Aura_" .. auraId)
		if opts.Offset then
			attachment.Position = opts.Offset
		end
		attachment.Parent = target
	end

	local p = def.Particles
	if p then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = auraId
		if p.Texture then
			emitter.Texture = p.Texture
		end
		emitter.Rate = math.clamp(math.floor(p.Rate * (0.4 + 0.6 * s) + 0.5), 1, MAX_RATE)
		emitter.Lifetime = numberRange(p.Lifetime, 1)
		emitter.Speed = numberRange(p.Speed, math.sqrt(scale))
		emitter.Color = ColorSequence.new(color1, color2)
		local size1 = p.Size * scale * (0.7 + 0.3 * s)
		local size2 = (p.Size2 or p.Size * 0.3) * scale * (0.7 + 0.3 * s)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, size1),
			NumberSequenceKeypoint.new(1, size2),
		})
		local t0 = p.Transparency or 0.2
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, t0),
			NumberSequenceKeypoint.new(0.7, math.min(1, t0 + 0.25)),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.LightEmission = p.LightEmission
		local spread = p.Spread or 180
		emitter.SpreadAngle = Vector2.new(spread, spread)
		if p.Rise then
			emitter.Acceleration = Vector3.new(0, p.Rise * math.sqrt(scale), 0)
		end
		if p.Drag then
			emitter.Drag = p.Drag
		end
		if p.RotSpeed then
			emitter.RotSpeed = NumberRange.new(-p.RotSpeed, p.RotSpeed)
			emitter.Rotation = NumberRange.new(0, 360)
		end
		emitter.LockedToPart = false
		emitter.Parent = attachment
	end

	local light = def.Light
	if light then
		local pl = Instance.new("PointLight")
		pl.Name = auraId .. "Light"
		pl.Color = color1
		pl.Brightness = light.Brightness * (0.5 + 0.5 * s)
		pl.Range = math.min(60, light.Range * scale)
		pl.Shadows = false
		pl.Parent = attachment
	end

	return attachment
end

return AuraLibrary
