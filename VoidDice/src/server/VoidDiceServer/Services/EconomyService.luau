--!strict
-- EconomyService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > EconomyService
--
-- Der Server-Tick (jede Sekunde): passives Einkommen, Potion-Laufzeiten,
-- Fishing-Fortschritt, Spielzeit. Dazu "Collect" (Button und Collector-Pad).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local GameConfig = require(Config:WaitForChild("GameConfig"))

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local EconomyService = {}

function EconomyService.collect(session: SessionService.Session)
	SessionService.run(session, function(profile, ctx)
		local amount = Logic.Economy.collect(profile, ctx)
		if amount > 0 then
			SessionService.fire(session, "Collected", { Amount = amount })
		end
	end)
end

function EconomyService.Start()
	SessionService.registerAction("Collect", function(session, ctx)
		local amount = Logic.Economy.collect(session.Profile, ctx)
		if amount > 0 then
			SessionService.fire(session, "Collected", { Amount = amount })
		end
		return true
	end)

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(GameConfig.EconomyTickInterval)
			local now = os.clock()
			local dt = math.clamp(now - last, 0, 5)
			last = now
			for _, session in SessionService.all() do
				if not session.Removing then
					SessionService.run(session, function(profile, ctx)
						Logic.tick(profile, ctx, dt)
					end)
				end
			end
		end
	end)
end

return EconomyService
