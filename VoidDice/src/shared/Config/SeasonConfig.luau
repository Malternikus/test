--!strict
-- SeasonConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > SeasonConfig
--
-- Season Pass: Free Track + Premium Track. XP kommt aus Quests und
-- Achievements. Premium wird über den Gamepass "SeasonPremium" freigeschaltet
-- (MonetizationConfig). Premium-Belohnungen sind nur Cosmetics, Potions und
-- Cash, nie Characters.
--
-- Neue Season: Id ändern, Tiers austauschen. Fortschritt einer alten Season
-- wird beim Join automatisch zurückgesetzt (Logic > Season).

local SeasonConfig = {}

SeasonConfig.Id = "S1"
SeasonConfig.DisplayName = "SEASON 1: SIGNAL LOST"
SeasonConfig.XpPerTier = 100
SeasonConfig.Enabled = true

-- Reward: { Kind = "Cash", Seconds = n } | { Kind = "Potion", Id, Amount }
--         { Kind = "Cosmetic", Id } | { Kind = "Gear", Id }
local function cash(seconds: number)
	return { Kind = "Cash", Seconds = seconds }
end
local function potion(id: string, amount: number)
	return { Kind = "Potion", Id = id, Amount = amount }
end
local function cosmetic(id: string)
	return { Kind = "Cosmetic", Id = id }
end
local function gear(id: string)
	return { Kind = "Gear", Id = id }
end

SeasonConfig.Tiers = {
	{ Free = cash(60), Premium = potion("Luck", 2) },
	{ Free = potion("Luck", 1), Premium = cash(180) },
	{ Free = cash(90), Premium = cosmetic("PlateCRT") },
	{ Free = potion("Bait", 2), Premium = potion("SuperLuck", 1) },
	{ Free = gear("SignalBooster"), Premium = cosmetic("TrailNeon") },
	{ Free = cash(120), Premium = potion("Cash", 3) },
	{ Free = potion("RollSpeed", 2), Premium = cosmetic("RollCRT") },
	{ Free = cash(150), Premium = gear("PsychicAmplifier") },
	{ Free = potion("SuperLuck", 1), Premium = cosmetic("ThemeRedAlert") },
	{ Free = cosmetic("TitleSignalLost"), Premium = cosmetic("AuraSeasonRift") },
	{ Free = cash(240), Premium = potion("VoidElixir", 1) },
	{ Free = potion("FishingLuck", 2), Premium = gear("GoldenCassette") },
} :: { { Free: any, Premium: any } }

return SeasonConfig
