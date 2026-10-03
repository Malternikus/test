-- VoidDiceServer (Script)
-- Ort: ServerScriptService > VoidDiceServer
--
-- Startet alle Services in fester Reihenfolge: erst Init (Vorbereitung, z. B.
-- Welt bauen, Remotes anlegen), dann Start (Verbindungen, Loops).
--
-- Aufbau:
--   Logic/     reine Spiellogik (Profil-Tabellen rein, Änderungen raus)
--   Services/  Roblox-Anbindung: Remotes, DataStore, Welt, Models, Robux
--   World/     prozeduraler Map-Bau (Hub, Bases, Gebiete)

local Services = script:WaitForChild("Services")

local ORDER = {
	"DataService",
	"AntiCheatService",
	"SessionService",
	"WorldService",
	"AnnouncementService",
	"EconomyService",
	"RollService",
	"CharacterService",
	"ProgressionService",
	"GoalsService",
	"BaseService",
	"AvatarService",
	"LeaderboardService",
	"MonetizationService",
	"DebugService",
}

local loaded = {}
for _, name in ORDER do
	loaded[name] = require(Services:WaitForChild(name)) :: any
end

for _, name in ORDER do
	local service = loaded[name]
	if service.Init then
		service.Init()
	end
end

for _, name in ORDER do
	local service = loaded[name]
	if service.Start then
		service.Start()
	end
end

-- Erst jetzt Spieler annehmen (alle Hooks sind registriert)
loaded.SessionService.Begin()

print("[VoidDice] Server bereit. ROLL. COLLECT. SURVIVE.")
