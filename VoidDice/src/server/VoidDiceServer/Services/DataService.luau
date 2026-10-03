--!strict
-- DataService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > DataService
--
-- Speichert Profile im DataStore – session-sicher:
--
--   * Session Lock: Beim Laden schreibt der Server per UpdateAsync seine JobId
--     in den Datensatz. Ein anderer Server, der das Profil noch hält, kann es
--     danach NICHT mehr überschreiben (sein Save prüft die JobId und bricht ab).
--     -> Kein Duplizieren durch schnelles Server-Hopping.
--   * Ist das Profil noch gesperrt (anderer Server speichert gerade beim
--     Verlassen), wird mit Pause erneut versucht. Ist der Lock älter als
--     LOCK_EXPIRY (Server abgestürzt), wird er übernommen.
--   * Autosave (GameConfig.AutosaveInterval), Save bei PlayerRemoving, Save
--     aller Profile bei BindToClose.
--   * Retries mit Backoff bei DataStore-Fehlern.
--   * Ohne DataStore-Zugriff (Studio ohne "Enable Studio Access to API
--     Services") läuft alles im Speicher, mit Warnung.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config"):WaitForChild("GameConfig"))

local DataService = {}

local STORE_NAME = "VoidDice_Profiles_v1"
local LOCK_EXPIRY = 600 -- Sekunden ohne Autosave = Server gilt als tot
local LOAD_ATTEMPTS = 8
local LOAD_RETRY_WAIT = 4
local SAVE_ATTEMPTS = 4

local JOB_ID = if game.JobId ~= "" then game.JobId else "studio-" .. tostring(math.random(1, 1e9))

local store: DataStore? = nil
local memoryMode = false
local memory: { [string]: any } = {}

local savingCount = 0

local function keyFor(userId: number): string
	return "u_" .. userId
end

local function waitForBudget(requestType: Enum.DataStoreRequestType)
	local waited = 0
	while DataStoreService:GetRequestBudgetForRequestType(requestType) < 1 and waited < 10 do
		task.wait(0.5)
		waited += 0.5
	end
end

function DataService.Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
		-- In Studio ohne API-Zugriff schlägt der erste echte Request fehl
		if RunService:IsStudio() then
			local probeOk, err = pcall(function()
				return (result :: DataStore):GetAsync("__probe")
			end)
			if not probeOk then
				warn("[DataService] Kein DataStore-Zugriff in Studio (" .. tostring(err) .. "). Speichern nur im Speicher. "
					.. "Game Settings > Security > Enable Studio Access to API Services aktivieren, um echtes Speichern zu testen.")
				memoryMode = true
			end
		end
	else
		warn("[DataService] DataStore nicht verfügbar, Speichern nur im Speicher:", result)
		memoryMode = true
	end
end

function DataService.isMemoryMode(): boolean
	return memoryMode
end

-- Lädt und sperrt das Profil. Gibt (profileTable oder nil für "neu", ok)
-- zurück. ok = false heißt: konnte nicht sicher geladen werden -> Spieler kicken.
function DataService.load(userId: number): (any, boolean)
	local key = keyFor(userId)
	if memoryMode or not store then
		local data = memory[key]
		return if data then data.Profile else nil, true
	end

	for attempt = 1, LOAD_ATTEMPTS do
		local lockedByOther = false
		waitForBudget(Enum.DataStoreRequestType.UpdateAsync)
		local ok, result = pcall(function()
			return (store :: DataStore):UpdateAsync(key, function(old)
				old = old or {}
				local lock = old.Lock
				local now = os.time()
				if lock and lock.JobId ~= JOB_ID and (now - (lock.Time or 0)) < LOCK_EXPIRY and attempt < LOAD_ATTEMPTS then
					lockedByOther = true
					return nil -- nichts schreiben
				end
				old.Lock = { JobId = JOB_ID, Time = now }
				return old
			end)
		end)
		if ok and not lockedByOther then
			local data = result or {}
			return data.Profile, true
		end
		if not ok then
			warn(string.format("[DataService] Laden fehlgeschlagen (Versuch %d/%d): %s", attempt, LOAD_ATTEMPTS, tostring(result)))
		end
		task.wait(LOAD_RETRY_WAIT * math.min(attempt, 3))
	end
	return nil, false
end

-- Speichert das Profil. release = Lock freigeben (Spieler verlässt Server).
-- Gibt false zurück, wenn der Lock verloren ging (anderer Server hat übernommen).
function DataService.save(userId: number, profile: any, release: boolean): boolean
	local key = keyFor(userId)
	if memoryMode or not store then
		memory[key] = { Profile = profile }
		return true
	end
	savingCount += 1
	local lostLock = false
	local success = false
	for attempt = 1, SAVE_ATTEMPTS do
		waitForBudget(Enum.DataStoreRequestType.UpdateAsync)
		local ok, err = pcall(function()
			return (store :: DataStore):UpdateAsync(key, function(old)
				old = old or {}
				if old.Lock and old.Lock.JobId ~= JOB_ID then
					lostLock = true
					return nil
				end
				-- zweiter Rückgabewert: UserIds für DSGVO-Löschanfragen
				return {
					Profile = profile,
					Lock = if release then nil else { JobId = JOB_ID, Time = os.time() },
					SavedAt = os.time(),
				}, { userId }
			end)
		end)
		if ok then
			success = not lostLock
			break
		end
		warn(string.format("[DataService] Speichern fehlgeschlagen (Versuch %d/%d): %s", attempt, SAVE_ATTEMPTS, tostring(err)))
		task.wait(2 ^ attempt)
	end
	savingCount -= 1
	if lostLock then
		warn("[DataService] Session Lock verloren für " .. key .. " – Save verworfen (kein Dupe).")
	end
	return success
end

function DataService.pendingSaves(): number
	return savingCount
end

DataService.AutosaveInterval = GameConfig.AutosaveInterval

return DataService
