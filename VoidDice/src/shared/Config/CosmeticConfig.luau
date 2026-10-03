--!strict
-- CosmeticConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > CosmeticConfig
--
-- Rein optische Belohnungen. Kein Gameplay-Vorteil.
-- Kinds:
--   Title          Text über dem Kopf (und im Leaderboard)
--   Nameplate      Stil des Overhead-Schilds
--   Aura           Partikel am Spieler-Avatar
--   Trail          Trail am Spieler-Avatar
--   BaseTheme      Farben der Kommunikations-Lichter in der Base
--   RollEffect     Farbton der Reveal-Animation
--   FishingEffect  Farbe des Fang-Splashs am Rift Pond
--   RiftEffect     Effekt beim Teleport/Rebirth
--
-- Source sagt, wo es herkommt (nur Info für UI): Achievement, Fishing, Season,
-- Rebirth, VIP, Default.

export type CosmeticDef = {
	Id: string,
	Kind: string,
	DisplayName: string,
	Source: string,
	Color: Color3?,
	Color2: Color3?,
	Text: string?,
	Colors: { Color3 }?,
}

local CosmeticConfig = {}

CosmeticConfig.Kinds = { "Title", "Nameplate", "Aura", "Trail", "BaseTheme", "RollEffect", "FishingEffect", "RiftEffect" }

CosmeticConfig.List = {
	-- Titles
	{ Id = "TitleRookie", Kind = "Title", DisplayName = "ROOKIE", Text = "ROOKIE", Source = "Default", Color = Color3.fromRGB(180, 190, 210) },
	{ Id = "MysteryHunter", Kind = "Title", DisplayName = "MYSTERY HUNTER", Text = "MYSTERY HUNTER", Source = "Achievement", Color = Color3.fromRGB(255, 160, 80) },
	{ Id = "RiftWalker", Kind = "Title", DisplayName = "RIFT WALKER", Text = "RIFT WALKER", Source = "Rebirth", Color = Color3.fromRGB(150, 90, 255) },
	{ Id = "VoidSeeker", Kind = "Title", DisplayName = "VOID SEEKER", Text = "VOID SEEKER", Source = "Rebirth", Color = Color3.fromRGB(120, 50, 255) },
	{ Id = "AnomalyHunter", Kind = "Title", DisplayName = "ANOMALY HUNTER", Text = "ANOMALY HUNTER", Source = "Achievement", Color = Color3.fromRGB(0, 255, 200) },
	{ Id = "TheSurvivor", Kind = "Title", DisplayName = "THE SURVIVOR", Text = "THE SURVIVOR", Source = "Rebirth", Color = Color3.fromRGB(255, 60, 60) },
	{ Id = "Collector", Kind = "Title", DisplayName = "ARCHIVIST", Text = "ARCHIVIST", Source = "Achievement", Color = Color3.fromRGB(90, 220, 255) },
	{ Id = "DeepAngler", Kind = "Title", DisplayName = "DEEP ANGLER", Text = "DEEP ANGLER", Source = "Achievement", Color = Color3.fromRGB(60, 230, 200) },
	{ Id = "TitleAbyssAngler", Kind = "Title", DisplayName = "ABYSS ANGLER", Text = "ABYSS ANGLER", Source = "Fishing", Color = Color3.fromRGB(130, 50, 255) },
	{ Id = "MaxedOut", Kind = "Title", DisplayName = "MAXED OUT", Text = "MAXED OUT", Source = "Achievement", Color = Color3.fromRGB(255, 210, 60) },
	{ Id = "TitleVIP", Kind = "Title", DisplayName = "VIP", Text = "★ VIP", Source = "VIP", Color = Color3.fromRGB(255, 200, 60) },
	{ Id = "TitleSignalLost", Kind = "Title", DisplayName = "SIGNAL LOST", Text = "SIGNAL LOST", Source = "Season", Color = Color3.fromRGB(255, 70, 90) },

	-- Nameplates
	{ Id = "PlateDefault", Kind = "Nameplate", DisplayName = "STANDARD", Source = "Default", Color = Color3.fromRGB(14, 16, 34), Color2 = Color3.fromRGB(90, 110, 255) },
	{ Id = "PlateCRT", Kind = "Nameplate", DisplayName = "CRT GREEN", Source = "Season", Color = Color3.fromRGB(4, 20, 8), Color2 = Color3.fromRGB(60, 255, 120) },
	{ Id = "PlateVIP", Kind = "Nameplate", DisplayName = "VIP GOLD", Source = "VIP", Color = Color3.fromRGB(40, 28, 4), Color2 = Color3.fromRGB(255, 200, 60) },

	-- Auras (Spieler)
	{ Id = "AuraLabGlow", Kind = "Aura", DisplayName = "LAB GLOW", Source = "Fishing", Color = Color3.fromRGB(80, 230, 255) },
	{ Id = "AuraMirror", Kind = "Aura", DisplayName = "MIRROR SHIMMER", Source = "Fishing", Color = Color3.fromRGB(40, 230, 190) },
	{ Id = "AuraVIP", Kind = "Aura", DisplayName = "VIP SPARKLE", Source = "VIP", Color = Color3.fromRGB(255, 200, 60) },
	{ Id = "AuraSeasonRift", Kind = "Aura", DisplayName = "SIGNAL STORM", Source = "Season", Color = Color3.fromRGB(255, 70, 90) },

	-- Trails
	{ Id = "TrailStatic", Kind = "Trail", DisplayName = "STATIC TRAIL", Source = "Fishing", Color = Color3.fromRGB(200, 210, 230), Color2 = Color3.fromRGB(80, 90, 120) },
	{ Id = "TrailNeon", Kind = "Trail", DisplayName = "NEON ARCADE", Source = "Season", Color = Color3.fromRGB(255, 60, 200), Color2 = Color3.fromRGB(60, 200, 255) },

	-- Base Themes (Lichterketten)
	{ Id = "ThemeClassic", Kind = "BaseTheme", DisplayName = "CLASSIC LIGHTS", Source = "Default",
		Colors = { Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 200, 60), Color3.fromRGB(80, 220, 120), Color3.fromRGB(80, 160, 255) } },
	{ Id = "ThemeRift", Kind = "BaseTheme", DisplayName = "RIFT PULSE", Source = "Rebirth",
		Colors = { Color3.fromRGB(150, 80, 255), Color3.fromRGB(60, 220, 255) } },
	{ Id = "ThemeVIP", Kind = "BaseTheme", DisplayName = "VIP GOLD", Source = "VIP",
		Colors = { Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 255, 220) } },
	{ Id = "ThemeRedAlert", Kind = "BaseTheme", DisplayName = "RED ALERT", Source = "Season",
		Colors = { Color3.fromRGB(255, 40, 40), Color3.fromRGB(80, 0, 0) } },

	-- Roll / Fishing / Rift Effects
	{ Id = "RollDefault", Kind = "RollEffect", DisplayName = "STANDARD", Source = "Default", Color = Color3.fromRGB(90, 110, 255) },
	{ Id = "RollCRT", Kind = "RollEffect", DisplayName = "CRT SCANLINES", Source = "Season", Color = Color3.fromRGB(60, 255, 120) },
	{ Id = "FishingSporeSplash", Kind = "FishingEffect", DisplayName = "SPORE SPLASH", Source = "Fishing", Color = Color3.fromRGB(120, 255, 140) },
	{ Id = "RiftEffectFracture", Kind = "RiftEffect", DisplayName = "FRACTURE", Source = "Fishing", Color = Color3.fromRGB(170, 90, 255) },
} :: { CosmeticDef }

CosmeticConfig.ById = {} :: { [string]: CosmeticDef }
for _, def in CosmeticConfig.List do
	CosmeticConfig.ById[def.Id] = def
end

-- Standardmäßig besessen und ausgerüstet
CosmeticConfig.Defaults = {
	Title = "TitleRookie",
	Nameplate = "PlateDefault",
	BaseTheme = "ThemeClassic",
	RollEffect = "RollDefault",
}

function CosmeticConfig.Get(id: string): CosmeticDef?
	return CosmeticConfig.ById[id]
end

return CosmeticConfig
