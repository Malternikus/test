--!strict
-- MonetizationConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > MonetizationConfig
--
-- Grundsätze:
--   * Kein Pay-to-Win nötig. Alles Spielrelevante ist erspielbar.
--   * KEINE bezahlten zufälligen Characters, keine Robux-Lootboxen,
--     keine Mystery Crates, keine bezahlten Random-Mutationen.
--   * Produkte geben immer einen festen, vorher angezeigten Inhalt.
--
-- Die Ids sind 0, bis du im Creator Dashboard echte Gamepasses/Produkte
-- anlegst und die Ids hier einträgst. Mit Id 0 zeigt der Shop "Coming soon".
-- In Studio kann man mit StudioTestPurchases = true über den Shop testen,
-- ohne Robux auszugeben (Server prüft RunService:IsStudio()).

local MonetizationConfig = {}

MonetizationConfig.StudioTestPurchases = true

MonetizationConfig.Gamepasses = {
	DoubleCash = {
		Id = 0, DisplayName = "2X CASH", PriceHint = 199,
		Description = "Permanently double all cash from your base.",
	},
	DoubleLuck = {
		Id = 0, DisplayName = "2X LUCK", PriceHint = 249,
		Description = "Permanently double your roll luck.",
	},
	FastRoll = {
		Id = 0, DisplayName = "FAST ROLL", PriceHint = 99,
		Description = "Roll 40% faster, forever.",
	},
	ExtraSlots = {
		Id = 0, DisplayName = "+3 BASE SLOTS", PriceHint = 149,
		Description = "Three extra character slots in your base.",
	},
	VIP = {
		Id = 0, DisplayName = "VIP", PriceHint = 299,
		Description = "+10% Cash, +10% Luck, VIP tag, gold base lights and VIP aura.",
	},
	SeasonPremium = {
		Id = 0, DisplayName = "SEASON PASS PREMIUM", PriceHint = 349,
		Description = "Unlocks the premium track of the current season.",
	},
}

-- Werte der Gamepasses (Logic > Modifiers liest diese)
MonetizationConfig.PassEffects = {
	DoubleCash = { CashMultiplier = 2 },
	DoubleLuck = { LuckMultiplier = 2 },
	FastRoll = { RollSpeedPct = 40 },
	ExtraSlots = { BaseSlots = 3 },
	VIP = { CashPct = 10, LuckPct = 10, Cosmetics = { "TitleVIP", "PlateVIP", "AuraVIP", "ThemeVIP" } },
	SeasonPremium = {},
}

-- Developer Products: fester Inhalt, keine Zufallsbelohnungen
--   Kind "Potion": gibt Potions (feste Anzahl)
--   Kind "Cash":   Sekunden aktuelles Base-Einkommen (mit Mindestbetrag)
MonetizationConfig.Products = {
	LuckBoost = {
		Id = 0, DisplayName = "LUCK BOOST (15 MIN)", PriceHint = 39, Kind = "Potion",
		Potions = { SuperLuck = 1, Luck = 1 }, Description = "+75% Luck for ~10 minutes (2 potions).",
	},
	CashPackSmall = {
		Id = 0, DisplayName = "CASH PACK", PriceHint = 25, Kind = "Cash",
		Seconds = 600, Minimum = 5000, Description = "10 minutes of your current base income.",
	},
	CashPackLarge = {
		Id = 0, DisplayName = "CASH VAULT", PriceHint = 99, Kind = "Cash",
		Seconds = 3600, Minimum = 50000, Description = "1 hour of your current base income.",
	},
	PotionPack = {
		Id = 0, DisplayName = "POTION PACK", PriceHint = 49, Kind = "Potion",
		Potions = { Luck = 3, Cash = 3, RollSpeed = 2, FishingLuck = 2 },
		Description = "3 Luck, 3 Cash, 2 Roll Speed, 2 Fishing Luck potions.",
	},
}

return MonetizationConfig
