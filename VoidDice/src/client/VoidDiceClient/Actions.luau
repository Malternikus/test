--!strict
-- Actions (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Actions
--
-- Der einzige Weg, wie der Client etwas vom Server will. Der Server prüft
-- und entscheidet; das Ergebnis kommt per Sync/Event zurück.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Net"))

local Actions = {}

local remote: RemoteEvent? = nil

function Actions.send(name: string, ...: any)
	assert(Net.Actions[name], "Unbekannte Action: " .. name)
	if not remote then
		remote = Net.get("Action")
	end
	(remote :: RemoteEvent):FireServer(name, ...)
end

return Actions
