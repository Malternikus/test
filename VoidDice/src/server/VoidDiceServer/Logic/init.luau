--!strict
-- Logic (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Logic
--
-- Die komplette Spiellogik als reine Funktionen auf Profil-Tabellen.
-- Keine Remotes, keine DataStores, keine Instanzen. Dadurch:
--   * Services sind dünne Hüllen (Validierung, Rate Limits, Sync)
--   * Tests und die Economy-Simulation nutzen exakt denselben Code
--
-- Untermodule:
--   Context, ProfileTemplate, Modifiers, Economy, Inventory, Rolling,
--   Upgrades, Items, Fishing, Progression, Goals, Rewards, Cosmetics,
--   QuestTracker

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local GameConfig = require(Config:WaitForChild("GameConfig"))
local MonetizationConfig = require(Config:WaitForChild("MonetizationConfig"))

local Context = require(script:WaitForChild("Context"))
local ProfileTemplate = require(script:WaitForChild("ProfileTemplate"))
local Modifiers = require(script:WaitForChild("Modifiers"))
local Economy = require(script:WaitForChild("Economy"))
local Inventory = require(script:WaitForChild("Inventory"))
local Rolling = require(script:WaitForChild("Rolling"))
local Upgrades = require(script:WaitForChild("Upgrades"))
local Items = require(script:WaitForChild("Items"))
local Fishing = require(script:WaitForChild("Fishing"))
local Progression = require(script:WaitForChild("Progression"))
local Goals = require(script:WaitForChild("Goals"))
local Rewards = require(script:WaitForChild("Rewards"))
local Cosmetics = require(script:WaitForChild("Cosmetics"))
local QuestTracker = require(script:WaitForChild("QuestTracker"))

local Logic = {
	Context = Context,
	ProfileTemplate = ProfileTemplate,
	Modifiers = Modifiers,
	Economy = Economy,
	Inventory = Inventory,
	Rolling = Rolling,
	Upgrades = Upgrades,
	Items = Items,
	Fishing = Fishing,
	Progression = Progression,
	Goals = Goals,
	Rewards = Rewards,
	Cosmetics = Cosmetics,
	QuestTracker = QuestTracker,
}

-- Beim Laden eines Profils (Join)
function Logic.onLoad(profile, ctx: Context.Context)
	ProfileTemplate.reconcile(profile)
	if profile.FirstJoin == 0 then
		profile.FirstJoin = ctx.now
	end
	profile.LastJoin = ctx.now
	Goals.ensureSeason(profile, ctx)
	QuestTracker.ensureDaily(profile, ctx)
	local mods = Modifiers.compute(profile)
	Inventory.validateSlots(profile, ctx, mods)
	-- Pässe, die Cosmetics mitbringen (VIP)
	for passName, owned in profile.Passes do
		if owned then
			Logic.applyPassCosmetics(profile, ctx, passName)
		end
	end
end

-- Ein Server-Tick (dt Sekunden): Einkommen, Boosts, Fishing, Spielzeit
function Logic.tick(profile, ctx: Context.Context, dt: number)
	local mods = Modifiers.compute(profile)
	Economy.tick(profile, ctx, mods, dt)
	Items.tickBoosts(profile, ctx, dt)
	if Fishing.isUnlocked(profile) then
		Fishing.tick(profile, ctx, mods, dt)
	end
	profile.Stats.Playtime += dt
	QuestTracker.ensureDaily(profile, ctx)
	Goals.evaluateAchievements(profile, ctx)
end

-- Gamepass gekauft/erkannt
function Logic.grantPass(profile, ctx: Context.Context, passName: string): boolean
	if not MonetizationConfig.Gamepasses[passName] then
		return false
	end
	if not profile.Passes[passName] then
		profile.Passes[passName] = true
		Context.mark(ctx, "Passes")
	end
	Logic.applyPassCosmetics(profile, ctx, passName)
	return true
end

function Logic.applyPassCosmetics(profile, ctx: Context.Context, passName: string)
	local effects = MonetizationConfig.PassEffects[passName]
	if effects and effects.Cosmetics then
		for _, id in effects.Cosmetics do
			if not profile.Cosmetics.Owned[id] then
				profile.Cosmetics.Owned[id] = true
				Context.mark(ctx, "Cosmetics")
			end
		end
	end
end

-- Developer Product (fester Inhalt, keine Zufallsbelohnung)
function Logic.grantProduct(profile, ctx: Context.Context, productName: string): boolean
	local def = MonetizationConfig.Products[productName]
	if not def then
		return false
	end
	if def.Kind == "Cash" then
		local amount = Economy.scaledAmount(profile, def.Seconds, def.Minimum)
		Economy.earn(profile, ctx, amount, "Product")
	elseif def.Kind == "Potion" then
		for id, amount in def.Potions do
			Items.addPotion(profile, ctx, id, amount)
		end
	else
		return false
	end
	Context.event(ctx, "ProductGranted", { Id = productName })
	return true
end

-- Einstellungen (Whitelist + Typprüfung)
Logic.SettingTypes = {
	AutoPlace = "boolean",
	Music = "boolean",
	SFX = "boolean",
	ReducedEffects = "boolean",
	ShowOthersReveals = "boolean",
}

function Logic.setSetting(profile, ctx: Context.Context, key: string, value: any): boolean
	local expected = Logic.SettingTypes[key]
	if not expected or type(value) ~= expected then
		return false
	end
	profile.Settings[key] = value
	Context.mark(ctx, "Settings")
	return true
end

function Logic.setAutoDelete(profile, ctx: Context.Context, rarityId: string, enabled: boolean): boolean
	local RarityConfig = require(Config:WaitForChild("RarityConfig"))
	local def = RarityConfig.ById[rarityId]
	if not def or def.Order > Rolling.MaxAutoDeleteOrder then
		return false
	end
	profile.Settings.AutoDelete[rarityId] = if enabled then true else nil
	Context.mark(ctx, "Settings")
	return true
end

-- Tutorial: nur der jeweils aktuelle Schritt kann abgeschlossen werden
function Logic.tutorialStep(profile, ctx: Context.Context, stepId: string): boolean
	local tutorial = profile.Tutorial
	if tutorial.Done then
		return false
	end
	local current = GameConfig.TutorialSteps[tutorial.Step]
	if not current or current.Id ~= stepId then
		return false
	end
	tutorial.Step += 1
	if tutorial.Step > #GameConfig.TutorialSteps then
		tutorial.Done = true
		-- Belohnung nur beim ersten Durchlauf (Replay gibt nichts)
		if not tutorial.Rewarded then
			tutorial.Rewarded = true
			Items.addPotion(profile, ctx, "Luck", 1)
		end
		Context.event(ctx, "TutorialDone", {})
	end
	Context.mark(ctx, "Tutorial")
	return true
end

function Logic.replayTutorial(profile, ctx: Context.Context)
	profile.Tutorial.Step = 1
	profile.Tutorial.Done = false
	Context.mark(ctx, "Tutorial")
end

function Logic.skipTutorial(profile, ctx: Context.Context)
	if not profile.Tutorial.Done then
		profile.Tutorial.Done = true
		Context.mark(ctx, "Tutorial")
	end
end

-- Abgeleitete Werte für die UI (werden mit jedem Sync mitgeschickt)
function Logic.derived(profile)
	local mods = Modifiers.compute(profile)
	local income = Economy.incomePerSecond(profile, mods)
	return {
		Luck = mods.Luck,
		LuckBreakdown = mods.LuckBreakdown,
		CashMultiplier = mods.CashMultiplier,
		CashBreakdown = mods.CashBreakdown,
		RollCooldown = mods.RollCooldown,
		RollSpeed = mods.RollSpeed,
		FishingLuck = mods.FishingLuck,
		FishingSpeed = mods.FishingSpeed,
		MutationLuck = mods.MutationLuck,
		BaseSlots = mods.BaseSlots,
		FishingSlots = mods.FishingSlots,
		GearSlots = mods.GearSlots,
		AutoCollect = mods.AutoCollect,
		IncomePerSecond = income,
		VaultCapacity = Economy.vaultCapacity(income),
		RebirthCost = Progression.rebirthCost(profile),
		FishingUnlocked = Fishing.isUnlocked(profile),
		BaseValue = Economy.baseValue(profile),
		CollectionScore = Economy.collectionScore(profile),
		SeasonTier = Goals.seasonTier(profile),
		InventoryCount = Inventory.count(profile),
		Discovered = Modifiers.discovered(profile),
	}
end

return Logic
