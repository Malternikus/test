-- GliderServer (Script)
-- Ort: ServerScriptService > GliderServer
--
-- Aufgaben des Servers im Prototyp:
--   1. Teststrecke bauen (nur zur Laufzeit, die Place-Datei bleibt unverändert)
--   2. Kollisionsgruppe registrieren (Spieler kollidieren physikalisch nicht mit
--      der Map; Crashes werden vom Client per Blockcast erkannt)
--   3. Jedem Charakter den Gleiter anbauen
--
-- Die eigentliche Flugsteuerung läuft auf dem Client (für direkte, flüssige
-- Steuerung). Der Client besitzt seinen Charakter physikalisch, daher wird die
-- Bewegung automatisch zum Server repliziert.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GliderShared"):WaitForChild("Config"))
local TrackLayout = require(script.TrackLayout)
local GliderRig = require(script.GliderRig)

-- 1) Kollisionsgruppe ---------------------------------------------------------
local GROUP = Config.Names.CollisionGroup
local ok, err = pcall(function()
	PhysicsService:RegisterCollisionGroup(GROUP)
	PhysicsService:CollisionGroupSetCollidable(GROUP, "Default", false)
	PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)
end)
if not ok then
	warn("[GliderServer] Kollisionsgruppe konnte nicht angelegt werden:", err)
end

-- 2) Map bauen ----------------------------------------------------------------
-- Die Standard-Baseplate etwas absenken, damit sie nicht mit unserem Boden flackert.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.CFrame = baseplate.CFrame - Vector3.new(0, 30, 0)
end
-- Andere Spawns deaktivieren, damit alle auf der Startklippe erscheinen.
for _, inst in workspace:GetDescendants() do
	if inst:IsA("SpawnLocation") then
		inst.Enabled = false
	end
end

local startTime = os.clock()
local map = TrackLayout.Build()
print(string.format(
	"[GliderServer] Teststrecke gebaut: %d Parts, Länge %d Studs (%.1f ms)",
	map:GetAttribute("PartCount") or 0,
	map:GetAttribute("TrackLength") or 0,
	(os.clock() - startTime) * 1000
))

-- 3) Gleiter an Charaktere ----------------------------------------------------
local function onCharacterAdded(player: Player, character: Model)
	GliderRig.Attach(character)
	-- Falls das Avatar-Aussehen später nachlädt, Arme erneut ausrichten
	task.delay(1, function()
		if character.Parent then
			GliderRig.PoseArms(character)
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player.CharacterAppearanceLoaded:Connect(function(character)
		GliderRig.PoseArms(character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
