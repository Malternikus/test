--!strict
-- Net (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Net
--
-- Drei Remotes reichen für das ganze Spiel:
--   Action  (Client -> Server)  Action(name, ...)  – jede Spieleraktion
--   Sync    (Server -> Client)  Sync(patch)        – Zustand (Profil-Ansicht)
--   Event   (Server -> Client)  Event(kind, data)  – Roll-Ergebnisse, Toasts, Ansagen
--
-- Der Client schickt NUR Wünsche ("Roll", "Upgrade c12"). Ergebnisse, Kosten
-- und Zufall entscheidet immer der Server.

local RunService = game:GetService("RunService")

local Net = {}

Net.FolderName = "Remotes"
Net.Names = { "Action", "Sync", "Event" }

-- Alle erlaubten Actions mit Argument-Typen. Der Server lehnt alles andere ab.
-- Typen: "string", "number", "boolean", "uid" (kurzer String), "id" (Config-Id)
Net.Actions = {
	Roll = {},
	SetAutoRoll = { "boolean" },
	EquipDice = { "id" },
	BuyDice = { "id" },
	UnlockArea = { "id" },
	Teleport = { "id" },
	PlaceCharacter = { "uid" },
	RemoveCharacter = { "uid" },
	PlaceBest = {},
	UpgradeCharacter = { "uid", "number" },
	SellCharacter = { "uid" },
	SellRarity = { "id" },
	LockCharacter = { "uid", "boolean" },
	SendFishing = { "uid" },
	RecallFishing = { "uid" },
	SetWaters = { "id" },
	EquipGear = { "uid", "uid" },
	UnequipGear = { "uid" },
	SellGear = { "uid" },
	SellRelic = { "id" },
	UsePotion = { "id" },
	Collect = {},
	Rebirth = {},
	SetSetting = { "id", "any" },
	SetAutoDelete = { "id", "boolean" },
	ClaimQuest = { "id" },
	ClaimSeason = { "id", "number" },
	EquipCosmetic = { "id", "id" },
	TutorialStep = { "id" },
	SkipTutorial = {},
	ReplayTutorial = {},
	InspectBase = { "number" },
	TestPurchase = { "id", "id" }, -- nur Studio (MonetizationConfig.StudioTestPurchases)
	Debug = { "id", "any" }, -- nur Studio (GameConfig.StudioDebugTools)
}

local remotes: { [string]: RemoteEvent } = {}

local function folder(): Folder
	local parent = script.Parent
	if RunService:IsServer() then
		local f = parent:FindFirstChild(Net.FolderName)
		if not f then
			f = Instance.new("Folder")
			f.Name = Net.FolderName
			f.Parent = parent
		end
		return f :: Folder
	end
	return parent:WaitForChild(Net.FolderName) :: Folder
end

function Net.get(name: string): RemoteEvent
	local existing = remotes[name]
	if existing then
		return existing
	end
	local f = folder()
	local remote: RemoteEvent
	if RunService:IsServer() then
		remote = (f:FindFirstChild(name) :: RemoteEvent?) or Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = f
	else
		remote = f:WaitForChild(name) :: RemoteEvent
	end
	remotes[name] = remote
	return remote
end

-- Server: alle Remotes anlegen
function Net.setup()
	for _, name in Net.Names do
		Net.get(name)
	end
end

return Net
