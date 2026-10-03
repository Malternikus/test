--!strict
-- GoalsService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > GoalsService
--
-- Quests, Season Pass, Cosmetics, Einstellungen, Tutorial.

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local GoalsService = {}

function GoalsService.Start()
	local register = SessionService.registerAction

	register("ClaimQuest", function(session, ctx, questId: string)
		return Logic.Goals.claimQuest(session.Profile, ctx, questId)
	end)

	register("ClaimSeason", function(session, ctx, track: string, tier: number)
		return Logic.Goals.claimSeason(session.Profile, ctx, track, tier)
	end)

	register("EquipCosmetic", function(session, ctx, kind: string, id: string)
		return Logic.Cosmetics.equip(session.Profile, ctx, kind, id)
	end)

	register("SetSetting", function(session, ctx, key: string, value: any)
		if not Logic.setSetting(session.Profile, ctx, key, value) then
			return false, "Invalid setting"
		end
		return true
	end)

	register("SetAutoDelete", function(session, ctx, rarityId: string, enabled: boolean)
		if not Logic.setAutoDelete(session.Profile, ctx, rarityId, enabled) then
			return false, "Auto Delete is only available up to Epic"
		end
		return true
	end)

	register("TutorialStep", function(session, ctx, stepId: string)
		Logic.tutorialStep(session.Profile, ctx, stepId)
		return true
	end)

	register("ReplayTutorial", function(session, ctx)
		Logic.replayTutorial(session.Profile, ctx)
		return true
	end)

	register("SkipTutorial", function(session, ctx)
		Logic.skipTutorial(session.Profile, ctx)
		return true
	end)
end

return GoalsService
