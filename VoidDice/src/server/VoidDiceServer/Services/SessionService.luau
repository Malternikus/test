--!strict
-- SessionService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > SessionService
--
-- Verwaltet die Spieler-Sessions (Profil im Speicher + Laufzeitdaten) und ist
-- die einzige Stelle, an der Client-Actions ankommen:
--
--   Client: Action:FireServer("UpgradeCharacter", "c12", 1)
--   -> AntiCheat: Rate Limit + Typprüfung
--   -> registrierter Handler (z. B. CharacterService) mit Context
--   -> Logic ändert das Profil
--   -> flush(): Cash-Sanity, Events an den Client, Sync-Patch, Hooks
--      (Base neu aufbauen, Avatar-Titel, Leaderstats ...)
--
-- Andere Services registrieren Actions mit SessionService.registerAction und
-- reagieren mit onLoaded / onRemoving / onFlush.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local AntiCheatService = require(script.Parent:WaitForChild("AntiCheatService"))

export type Session = {
	Player: Player,
	UserId: number,
	Profile: any,
	Rng: Random,
	LastGood: { Cash: number, Vault: number },
	AutoRoll: boolean,
	NextRollAt: number,
	Plot: number?,
	JoinedAt: number,
	SecretRolls: number,
	Removing: boolean,
	Runtime: { [string]: any },
}

type Handler = (session: Session, ctx: any, ...any) -> (boolean?, string?)

local SessionService = {}

local sessions: { [Player]: Session } = {}
local handlers: { [string]: Handler } = {}
local loadedHooks: { (Session) -> () } = {}
local removingHooks: { (Session) -> () } = {}
local flushHooks: { (Session, any) -> () } = {}

-- Profil-Keys, die NICHT an den Client gehen
local PRIVATE_KEYS = {
	Purchases = true,
	NextCharUid = true,
	NextGearUid = true,
	Version = true,
}

local eventRemote: RemoteEvent
local syncRemote: RemoteEvent

function SessionService.get(player: Player): Session?
	local s = sessions[player]
	if s and not s.Removing then
		return s
	end
	return nil
end

function SessionService.all(): { [Player]: Session }
	return sessions
end

function SessionService.registerAction(name: string, handler: Handler)
	assert(Net.Actions[name], "Action fehlt in Net.Actions: " .. name)
	assert(not handlers[name], "Action doppelt registriert: " .. name)
	handlers[name] = handler
end

function SessionService.onLoaded(callback: (Session) -> ())
	table.insert(loadedHooks, callback)
end

function SessionService.onRemoving(callback: (Session) -> ())
	table.insert(removingHooks, callback)
end

function SessionService.onFlush(callback: (Session, any) -> ())
	table.insert(flushHooks, callback)
end

function SessionService.newContext(session: Session)
	return Logic.Context.new({
		now = os.time(),
		rng = session.Rng,
		userId = session.UserId,
		isStudio = RunService:IsStudio(),
	})
end

function SessionService.fire(session: Session, kind: string, data: any?)
	eventRemote:FireClient(session.Player, kind, data)
end

function SessionService.fireAll(kind: string, data: any?)
	eventRemote:FireAllClients(kind, data)
end

function SessionService.toast(session: Session, text: string, kind: string?)
	eventRemote:FireClient(session.Player, "Toast", { Text = text, Kind = kind or "info" })
end

local function publicProfile(profile)
	local view = {}
	for key, value in profile do
		if not PRIVATE_KEYS[key] then
			view[key] = value
		end
	end
	return view
end

function SessionService.sendFull(session: Session)
	local patch = publicProfile(session.Profile)
	patch.Full = true
	patch.Derived = Logic.derived(session.Profile)
	patch.Session = { AutoRoll = session.AutoRoll, Plot = session.Plot, MemoryMode = DataService.isMemoryMode(), IsStudio = RunService:IsStudio() }
	syncRemote:FireClient(session.Player, patch)
end

function SessionService.sendSession(session: Session)
	syncRemote:FireClient(session.Player, {
		Session = { AutoRoll = session.AutoRoll, Plot = session.Plot, MemoryMode = DataService.isMemoryMode(), IsStudio = RunService:IsStudio() },
	})
end

-- Änderungen eines Contexts an Client und Hooks weitergeben
function SessionService.flush(session: Session, ctx)
	local profile = session.Profile
	AntiCheatService.sanitize(session.Player, profile, session.LastGood)

	local patch = {}
	local any = false
	for key in ctx.dirty do
		if profile[key] ~= nil and not PRIVATE_KEYS[key] then
			patch[key] = profile[key]
		end
		any = true
	end
	if next(ctx.dirtyChars) then
		local chars = {}
		for uid in ctx.dirtyChars do
			chars[uid] = profile.Characters[uid] or false
		end
		patch.Characters = chars
		any = true
	end
	if next(ctx.dirtyGear) then
		local gear = {}
		for uid in ctx.dirtyGear do
			gear[uid] = profile.Gear[uid] or false
		end
		patch.Gear = gear
		any = true
	end
	if any then
		patch.Derived = Logic.derived(profile)
		syncRemote:FireClient(session.Player, patch)
	end

	for _, event in ctx.events do
		eventRemote:FireClient(session.Player, event.Kind, event.Data)
	end

	for _, hook in flushHooks do
		local ok, err = pcall(hook, session, ctx)
		if not ok then
			warn("[SessionService] Flush-Hook Fehler:", err)
		end
	end
end

-- Führt Logik für eine Session aus und flusht danach.
function SessionService.run(session: Session, fn: (profile: any, ctx: any) -> ...any): ...any
	local ctx = SessionService.newContext(session)
	local results = table.pack(pcall(fn, session.Profile, ctx))
	if not results[1] then
		warn("[SessionService] Logik-Fehler:", results[2])
		SessionService.toast(session, "Something went wrong. Please try again.", "error")
	end
	Logic.Goals.evaluateAchievements(session.Profile, ctx)
	SessionService.flush(session, ctx)
	return table.unpack(results, 2, results.n)
end

local function onAction(player: Player, action: any, ...: any)
	local session = SessionService.get(player)
	if not session then
		return
	end
	local args = table.pack(...)
	if not AntiCheatService.validate(player, action, args) then
		return
	end
	if not AntiCheatService.allow(player, action) then
		return
	end
	local handler = handlers[action]
	if not handler then
		return
	end
	local ctx = SessionService.newContext(session)
	local ok, success, err = pcall(handler, session, ctx, table.unpack(args, 1, args.n))
	if not ok then
		warn(string.format("[SessionService] Action %s Fehler: %s", tostring(action), tostring(success)))
		SessionService.toast(session, "Something went wrong.", "error")
	elseif success == false and err then
		eventRemote:FireClient(player, "Toast", { Text = err, Kind = "error" })
	end
	Logic.Goals.evaluateAchievements(session.Profile, ctx)
	SessionService.flush(session, ctx)
end

local function loadPlayer(player: Player)
	local stored, ok = DataService.load(player.UserId)
	if not ok then
		player:Kick("Your data could not be loaded safely. Please rejoin in a moment.")
		return
	end
	local profile = stored or Logic.ProfileTemplate.new()
	if not player.Parent then
		-- schon wieder weg: Lock sofort freigeben
		DataService.save(player.UserId, profile, true)
		return
	end
	local session: Session = {
		Player = player,
		UserId = player.UserId,
		Profile = profile,
		Rng = Random.new(),
		LastGood = { Cash = 0, Vault = 0 },
		AutoRoll = false,
		NextRollAt = 0,
		Plot = nil,
		JoinedAt = os.clock(),
		SecretRolls = 0,
		Removing = false,
		Runtime = {},
	}
	local ctx = SessionService.newContext(session)
	Logic.onLoad(profile, ctx)
	session.LastGood.Cash = profile.Cash
	session.LastGood.Vault = profile.Vault
	sessions[player] = session

	for _, hook in loadedHooks do
		local hookOk, err = pcall(hook, session)
		if not hookOk then
			warn("[SessionService] Loaded-Hook Fehler:", err)
		end
	end
	SessionService.sendFull(session)
	SessionService.flush(session, ctx)
end

local function removePlayer(player: Player)
	local session = sessions[player]
	if not session or session.Removing then
		return
	end
	session.Removing = true
	session.AutoRoll = false
	for _, hook in removingHooks do
		pcall(hook, session)
	end
	DataService.save(session.UserId, session.Profile, true)
	sessions[player] = nil
end

function SessionService.Init()
	Net.setup()
	eventRemote = Net.get("Event")
	syncRemote = Net.get("Sync")
end

function SessionService.Start()
	Net.get("Action").OnServerEvent:Connect(onAction)
end

-- Erst aufrufen, wenn alle anderen Services ihre Hooks registriert haben
function SessionService.Begin()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadPlayer, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		task.spawn(removePlayer, player)
	end)

	-- Autosave (gestaffelt)
	task.spawn(function()
		while true do
			task.wait(DataService.AutosaveInterval)
			for player, session in sessions do
				if not session.Removing then
					task.spawn(DataService.save, session.UserId, session.Profile, false)
					task.wait(0.5)
				end
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player, session in sessions do
			if not session.Removing then
				session.Removing = true
				pending += 1
				task.spawn(function()
					DataService.save(session.UserId, session.Profile, true)
					pending -= 1
				end)
			end
		end
		local started = os.clock()
		while (pending > 0 or DataService.pendingSaves() > 0) and os.clock() - started < 25 do
			task.wait(0.2)
		end
	end)
end

return SessionService
