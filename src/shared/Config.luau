--!strict
-- Config (ModuleScript)
-- Ort: ReplicatedStorage > GliderShared > Config
--
-- Zentrale Stelle für alle Tuning-Werte. Hier drehen, testen, wieder drehen.
-- Winkel sind in Grad, Geschwindigkeiten in Studs pro Sekunde.

local Config = {}

-------------------------------------------------------------------------------
-- FLUG
-------------------------------------------------------------------------------
Config.Flight = {
	-- Grundgeschwindigkeit im Geradeausflug
	BaseSpeed = 95,
	-- Bonus beim Sturzflug (S) / Abzug beim Steigen (W), skaliert mit dem Pitch
	DiveSpeedBonus = 40,
	ClimbSpeedPenalty = 20,
	MinSpeed = 60,
	MaxSpeed = 140,
	-- Wie schnell sich die Geschwindigkeit an den Zielwert annähert (höher = direkter)
	SpeedResponse = 1.6,

	-- Lenken (A/D): maximale Drehrate in Grad pro Sekunde
	MaxYawRate = 62,
	-- Maximale sichtbare Schräglage beim Lenken
	MaxBankAngle = 42,
	-- Hoch/Runter (W/S): maximaler Nick-Winkel
	MaxPitchAngle = 32,
	-- Wie stark der Gleiter beim Steigen/Sinken sichtbar nickt (Anteil vom Flugwinkel)
	VisualPitchFactor = 0.7,

	-- TRÄGHEIT / WEICHHEIT (höher = reagiert schneller, niedriger = träger)
	-- Wie schnell der Eingabewert dem Tastendruck folgt
	SteerResponse = 4.5,
	PitchResponse = 4.0,
	-- Wie schnell sich Schräglage und Nicken visuell einstellen
	BankResponse = 5.0,
	PitchVisualResponse = 5.0,
	-- Wie schnell die Flugbahn der Blickrichtung folgt (leichtes "Nachschieben")
	VelocityResponse = 7.0,

	-- Leichtes Absinken im Geradeausflug (Gleiter-Gefühl). 0 = aus
	SinkRate = 2,

	-- Brems-Dauer nach dem Ziel (Sekunden)
	FinishBrakeTime = 1.5,
}

-------------------------------------------------------------------------------
-- EINGABE
-------------------------------------------------------------------------------
Config.Input = {
	-- true = W/Stick nach vorne lässt den Gleiter sinken (Flugzeug-Stil)
	InvertPitch = false,
	GamepadDeadzone = 0.15,
}

-------------------------------------------------------------------------------
-- KAMERA
-------------------------------------------------------------------------------
Config.Camera = {
	-- Abstand hinter / über dem Gleiter
	Distance = 17,
	Height = 5.5,
	-- Bei hoher Geschwindigkeit etwas weiter zurück (Geschwindigkeitsgefühl)
	ExtraDistanceAtMaxSpeed = 5,
	-- Punkt vor dem Gleiter, auf den die Kamera schaut
	LookAhead = 30,
	-- Verzögerung der Position (höher = enger am Spieler, niedriger = weicher)
	PositionResponse = 9,
	-- Verzögerung der Rotation
	RotationResponse = 7,
	-- Wie viel von der Schräglage die Kamera mitmacht (0 = gar nicht, 1 = voll)
	RollFactor = 0.3,
	-- Wie viel vom Nicken die Kamera mitmacht
	PitchFactor = 0.5,

	-- FOV-Effekt
	BaseFOV = 70,
	MaxFOVBoost = 12,
	FOVResponse = 3,

	-- Kamera-Wackeln beim Crash
	CrashShakeStrength = 0.6,
	CrashShakeDuration = 0.35,
}

-------------------------------------------------------------------------------
-- CRASH / KOLLISION
-------------------------------------------------------------------------------
Config.Crash = {
	-- Kollisionsbox relativ zum HumanoidRootPart (Breite, Höhe, Tiefe)
	-- Etwas kleiner als das sichtbare Modell = fairer
	BoxSize = Vector3.new(11, 7.5, 2.5),
	BoxOffset = Vector3.new(0, 1.4, 0),
	-- Zusätzlicher Blick nach vorne in Studs (verhindert "durch die Wand ruckeln")
	Lookahead = 1.5,

	-- Wie lange der Crash sichtbar ist, bevor zurückgesetzt wird
	RespawnDelay = 1.1,
	-- Wie lange nach dem Zurücksetzen geschwebt wird, bevor es weitergeht
	FreezeAfterRespawn = 1.0,

	-- Sicherheitsgrenzen der Map (Absturz bei Über-/Unterschreitung)
	MinAltitude = 2,
	MaxAltitude = 165,
}

-------------------------------------------------------------------------------
-- RUN
-------------------------------------------------------------------------------
Config.Run = {
	CountdownSeconds = 3,
	-- Taste für schnellen Neustart (zusätzlich zum Reset-Button)
	RestartKey = Enum.KeyCode.R,
}

-------------------------------------------------------------------------------
-- EFFEKTE
-------------------------------------------------------------------------------
Config.Effects = {
	-- Kleine Wind-Partikel vor der Kamera für das Geschwindigkeitsgefühl
	SpeedParticlesEnabled = true,
	SpeedParticlesMaxRate = 90,
}

-------------------------------------------------------------------------------
-- NAMEN (gemeinsam von Server und Client genutzt)
-------------------------------------------------------------------------------
Config.Names = {
	MapModel = "GliderMap",
	SolidFolder = "Solid", -- alles hier drin führt zum Crash
	DecorFolder = "Decor", -- nur Optik, keine Kollision
	TrackData = "GliderTrackData", -- in ReplicatedStorage, Checkpoint-Daten
	GliderModel = "Glider",
	CollisionGroup = "GliderPlayers",
}

return Config
