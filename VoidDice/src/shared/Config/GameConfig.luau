--!strict
-- GameConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > GameConfig
--
-- Allgemeine Spielregeln und Limits, die zu keinem einzelnen System gehören.

local GameConfig = {}

GameConfig.Title = "VOID DICE"
GameConfig.Subtitle = "ROLL. COLLECT. SURVIVE."
GameConfig.Pitch = {
	"ROLL CHARACTERS.",
	"BUILD YOUR COLLECTION.",
	"GET RICH.",
	"FIND THE RAREST ENTITY.",
}

-- Server: 6–8 Spieler (in den Place-Einstellungen setzen, hier nur Info/Plots)
GameConfig.MaxPlayers = 8

-- Rolling --------------------------------------------------------------------
GameConfig.RollCooldown = 1.0 -- Sekunden zwischen zwei Rolls bei Roll Speed 1
GameConfig.MinRollCooldown = 0.3 -- harte Untergrenze, egal wie viele Boni
GameConfig.RollCooldownTolerance = 0.12 -- Netzwerk-Toleranz für manuelle Rolls
GameConfig.AutoRollUnlocked = true -- Auto Roll von Anfang an verfügbar

-- Base -------------------------------------------------------------------------
GameConfig.StartBaseSlots = 6
GameConfig.MaxBaseSlots = 25 -- physische Pads pro Plot (WorldConfig 5x5)
GameConfig.StartFishingSlots = 1
GameConfig.MaxFishingSlots = 4
GameConfig.StartGearSlots = 2
GameConfig.MaxGearSlots = 3

-- Inventar --------------------------------------------------------------------
-- Soft Cap: darüber werden neue Rolls automatisch verkauft, außer sie sind neu
-- im Index oder Legendary+. Hard Cap gilt immer (DataStore-Größe).
GameConfig.InventorySoftCap = 250
GameConfig.InventoryHardCap = 320
GameConfig.GearInventoryCap = 120
GameConfig.KeepRarityOverCap = "Legendary"

-- Neue Characters automatisch in die Base stellen, wenn sie mehr bringen als
-- der schwächste platzierte (Standard an, im Settings-Menü abschaltbar)
GameConfig.DefaultAutoPlace = true

-- Fishing wird freigeschaltet, sobald insgesamt so viel Cash verdient wurde
-- (Ziel laut Design: ca. Minute 3)
GameConfig.FishingUnlockCashEarned = 30000

-- Ticks -------------------------------------------------------------------------
GameConfig.EconomyTickInterval = 1
GameConfig.AutosaveInterval = 75
GameConfig.LeaderboardRefreshInterval = 120

-- Tutorial ------------------------------------------------------------------------
GameConfig.TutorialSteps = {
	{ Id = "Roll", Text = "Press ROLL to roll your first character!" },
	{ Id = "Reveal", Text = "Nice! Every character has a rarity. Rarer = more cash." },
	{ Id = "Place", Text = "Your character stands in your base and makes cash every second." },
	{ Id = "Collect", Text = "Cash piles up in your vault. Press COLLECT (or step on the green pad)." },
	{ Id = "Upgrade", Text = "Open a character and press UPGRADE to boost its $/s." },
	{ Id = "Fishing", Text = "Later you can send spare characters to your Rift Pond to fish for loot." },
}

-- Announcements -------------------------------------------------------------------
GameConfig.CrossServerAnnouncements = true -- MessagingService für Secret/Anomaly

-- Debug ---------------------------------------------------------------------------
-- In Studio: Debug-Befehle (Cash geben, Luck setzen …) über das Settings-Menü
GameConfig.StudioDebugTools = true

return GameConfig
