--!strict
-- ProgressionService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > ProgressionService
--
-- Rebirth, Dice, Gebiete, Teleport, Fishing-Actions.
-- Bedingungen (Cash, Rebirth-Stufe, Gebiet frei) prüft die Logic.

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))
local WorldService = require(script.Parent:WaitForChild("WorldService"))

local ProgressionService = {}

local TELEPORT_COOLDOWN = 3

function ProgressionService.Start()
	local register = SessionService.registerAction

	register("Rebirth", function(session, ctx)
		local ok, err = Logic.Progression.rebirth(session.Profile, ctx)
		if ok then
			SessionService.fireAll("PlayerRebirth", { Player = session.Player.DisplayName, UserId = session.UserId, Rebirths = session.Profile.Rebirths })
		end
		return ok, err
	end)

	register("BuyDice", function(session, ctx, diceId: string)
		return Logic.Progression.buyDice(session.Profile, ctx, diceId)
	end)

	register("EquipDice", function(session, ctx, diceId: string)
		return Logic.Progression.equipDice(session.Profile, ctx, diceId)
	end)

	register("UnlockArea", function(session, ctx, areaId: string)
		return Logic.Progression.unlockArea(session.Profile, ctx, areaId)
	end)

	register("Teleport", function(session, _ctx, target: string)
		local now = os.clock()
		if (session.Runtime.LastTeleport or 0) + TELEPORT_COOLDOWN > now then
			return false, "Wait a moment"
		end
		local character = session.Player.Character
		if not character then
			return false, nil
		end
		local cf: CFrame?
		if target == "Base" then
			cf = WorldService.plotSpawn(session.Plot)
		elseif target == "Hub" then
			cf = WorldService.hubSpawn()
		else
			if not session.Profile.Areas[target] then
				return false, "Area locked"
			end
			cf = WorldService.areaArrival(target)
		end
		if not cf then
			return false, "Unknown destination"
		end
		session.Runtime.LastTeleport = now
		character:PivotTo(cf + Vector3.new(0, 3, 0))
		return true
	end)

	register("SendFishing", function(session, ctx, uid: string)
		return Logic.Fishing.send(session.Profile, ctx, uid, Logic.Modifiers.compute(session.Profile))
	end)

	register("RecallFishing", function(session, ctx, uid: string)
		if not Logic.Fishing.recall(session.Profile, ctx, uid) then
			return false, "Character is not fishing"
		end
		return true
	end)

	register("SetWaters", function(session, ctx, watersId: string)
		return Logic.Fishing.setWaters(session.Profile, ctx, watersId)
	end)
end

return ProgressionService
