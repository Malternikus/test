--!strict
-- UIConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > UIConfig
--
-- Farben, Schriften, Größen und Reveal-Timings. Moderne Roblox-UI mit
-- 80s/CRT-Details: dunkles Navy/Schwarz, Lila, Electric Blue, rote Akzente.

local UIConfig = {}

UIConfig.Colors = {
	Background = Color3.fromRGB(8, 9, 22),
	Panel = Color3.fromRGB(14, 16, 36),
	PanelLight = Color3.fromRGB(24, 27, 58),
	Stroke = Color3.fromRGB(70, 60, 160),
	Text = Color3.fromRGB(236, 238, 255),
	SubText = Color3.fromRGB(150, 156, 200),
	Purple = Color3.fromRGB(140, 70, 255),
	Blue = Color3.fromRGB(50, 160, 255),
	Red = Color3.fromRGB(255, 56, 72),
	Green = Color3.fromRGB(70, 230, 120),
	Gold = Color3.fromRGB(255, 200, 60),
	Cash = Color3.fromRGB(110, 255, 140),
	Luck = Color3.fromRGB(110, 230, 255),
	Disabled = Color3.fromRGB(60, 62, 84),
	CRTGreen = Color3.fromRGB(80, 255, 140),
}

UIConfig.Fonts = {
	Title = Enum.Font.FredokaOne,
	Body = Enum.Font.GothamBold,
	Mono = Enum.Font.Code,
}

UIConfig.CornerRadius = 12
UIConfig.StrokeThickness = 2

-- Mobile: Mindestgröße für Touch-Ziele (Pixel bei UIScale 1)
UIConfig.MinTouchSize = 48
-- Referenzauflösung für UIScale (kleinere Bildschirme werden skaliert)
UIConfig.ReferenceResolution = Vector2.new(1000, 560)
UIConfig.MinScale = 0.65
UIConfig.MaxScale = 1.25

-- Reveal-Stufen (RarityConfig.RevealTier). Duration = gesamte Zeit, die das
-- Reveal auf dem Schirm ist. Commons sind fast instant.
UIConfig.Reveal = {
	[0] = { Duration = 0.55, Spin = 0.18, Flash = 0, Shake = 0, Zoom = 0, Banner = false },
	[1] = { Duration = 0.8, Spin = 0.3, Flash = 0.15, Shake = 0, Zoom = 0, Banner = false },
	[2] = { Duration = 1.1, Spin = 0.4, Flash = 0.35, Shake = 0, Zoom = 0, Banner = false },
	[3] = { Duration = 1.9, Spin = 0.7, Flash = 0.6, Shake = 0.2, Zoom = 4, Banner = true },
	[4] = { Duration = 2.5, Spin = 0.9, Flash = 0.75, Shake = 0.35, Zoom = 8, Banner = true },
	[5] = { Duration = 3.2, Spin = 1.2, Flash = 0.85, Shake = 0.5, Zoom = 12, Banner = true },
	[6] = { Duration = 3.8, Spin = 1.5, Flash = 1, Shake = 0.7, Zoom = 15, Banner = true, Blackout = true },
	[7] = { Duration = 4.8, Spin = 2.0, Flash = 1, Shake = 0.9, Zoom = 18, Banner = true, Blackout = true, Glitch = true },
	[8] = { Duration = 5.8, Spin = 2.4, Flash = 1, Shake = 1, Zoom = 22, Banner = true, Blackout = true, Glitch = true, Rainbow = true },
}

-- Idle-Animationssets (BaseAnimator). Werte sind Amplituden/Frequenzen.
UIConfig.AnimationSets = {
	Default = { Bob = 0.08, BobSpeed = 1.6, HeadTurn = 15, ArmSwing = 6 },
	Flashlight = { Bob = 0.06, BobSpeed = 1.4, HeadTurn = 25, ArmSwing = 4, ArmRaise = 70, Sweep = 35 },
	Walkie = { Bob = 0.06, BobSpeed = 1.5, HeadTurn = 10, ArmSwing = 2, ArmRaise = 110, Talk = true },
	LookAround = { Bob = 0.05, BobSpeed = 1.2, HeadTurn = 45, ArmSwing = 3 },
	Sit = { Bob = 0.02, BobSpeed = 0.8, HeadTurn = 20, ArmSwing = 2, Sit = true },
	Investigate = { Bob = 0.04, BobSpeed = 1.0, HeadTurn = 20, ArmSwing = 3, HeadTilt = 25, ArmRaise = 40 },
	Talk = { Bob = 0.07, BobSpeed = 2.2, HeadTurn = 18, ArmSwing = 25 },
	Psychic = { Bob = 0.35, BobSpeed = 1.0, HeadTurn = 8, ArmSwing = 0, ArmRaise = 80, Hover = 0.8, BothArms = true },
	Float = { Bob = 0.6, BobSpeed = 0.7, HeadTurn = 12, ArmSwing = 10, Hover = 1.5, Spin = 0 },
	Creature = { Bob = 0.12, BobSpeed = 2.4, HeadTurn = 35, ArmSwing = 12, Breathe = 0.06 },
	Crawler = { Bob = 0.05, BobSpeed = 4.0, HeadTurn = 25, ArmSwing = 0, Jitter = 0.08 },
	Hover = { Bob = 0.5, BobSpeed = 1.2, HeadTurn = 20, ArmSwing = 0, Hover = 2, WingFlap = 40 },
	Pulse = { Bob = 0.2, BobSpeed = 0.9, HeadTurn = 0, ArmSwing = 0, Pulse = 0.08, Spin = 12 },
	Serpent = { Bob = 0.1, BobSpeed = 1.6, HeadTurn = 30, ArmSwing = 0, Sway = 12 },
	Heavy = { Bob = 0.04, BobSpeed = 0.6, HeadTurn = 15, ArmSwing = 5, Breathe = 0.04 },
}

-- Performance
UIConfig.AnimateDistance = 140 -- Studs: weiter weg werden Base-Models nicht animiert
UIConfig.MaxAnimatedModels = 70
UIConfig.ViewportCacheSize = 40

-- Zahlformat
UIConfig.NumberSuffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

return UIConfig
