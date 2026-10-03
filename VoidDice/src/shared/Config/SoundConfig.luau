--!strict
-- SoundConfig (ModuleScript)
-- Ort: ReplicatedStorage > VoidDice > Config > SoundConfig
--
-- Alle Sounds an einer Stelle. Die Platzhalter nutzen Sounds, die in jedem
-- Roblox-Client eingebaut sind (rbxasset://sounds/...), variiert über Pitch.
-- Für das Release eigene oder lizenzierte Sounds hochladen und hier die
-- rbxassetid://... eintragen. KEINE Musik aus Stranger Things o. ä. verwenden.
--
-- Ambience/Musik: leer lassen = kein Loop. Eigene Tracks eintragen, der
-- AmbienceController blendet pro Gebiet über.

export type SoundDef = {
	Id: string,
	Volume: number,
	Pitch: number?,
	-- mehrere Layer gleichzeitig (z. B. Bass + Whoosh für Void)
	Layers: { { Id: string, Volume: number, Pitch: number?, Delay: number? } }?,
}

local SoundConfig = {}

local CLICK = "rbxasset://sounds/clickfast.wav"
local BUTTON = "rbxasset://sounds/button.wav"
local SWOOSH = "rbxasset://sounds/swoosh.wav"
local PING = "rbxasset://sounds/electronicpingshort.wav"
local SPLASH = "rbxasset://sounds/impact_water.mp3"
local SNAP = "rbxasset://sounds/snap.mp3"

SoundConfig.Sounds = {
	UIClick = { Id = BUTTON, Volume = 0.35, Pitch = 1.1 },
	UIOpen = { Id = SWOOSH, Volume = 0.25, Pitch = 1.4 },
	UIError = { Id = CLICK, Volume = 0.4, Pitch = 0.6 },
	Collect = { Id = PING, Volume = 0.4, Pitch = 1.3 },
	Upgrade = { Id = PING, Volume = 0.45, Pitch = 1.6 },
	Purchase = { Id = PING, Volume = 0.5, Pitch = 1.0 },
	Rebirth = { Id = SWOOSH, Volume = 0.7, Pitch = 0.5, Layers = { { Id = PING, Volume = 0.5, Pitch = 0.6, Delay = 0.2 } } },
	FishingCatch = { Id = SPLASH, Volume = 0.5, Pitch = 1.1 },
	FishingBigCatch = { Id = SPLASH, Volume = 0.7, Pitch = 0.7, Layers = { { Id = PING, Volume = 0.5, Pitch = 0.9, Delay = 0.15 } } },
	Quest = { Id = PING, Volume = 0.5, Pitch = 1.2 },
	Achievement = { Id = PING, Volume = 0.6, Pitch = 0.9, Layers = { { Id = PING, Volume = 0.4, Pitch = 1.35, Delay = 0.12 } } },
	Announcement = { Id = PING, Volume = 0.6, Pitch = 0.75 },

	-- Roll: pro Reveal-Stufe (RarityConfig.RevealTier)
	RollTick = { Id = CLICK, Volume = 0.25, Pitch = 1.5 },
	Reveal0 = { Id = SWOOSH, Volume = 0.25, Pitch = 1.6 },
	Reveal1 = { Id = SWOOSH, Volume = 0.35, Pitch = 1.3, Layers = { { Id = PING, Volume = 0.25, Pitch = 1.5 } } },
	Reveal2 = { Id = SWOOSH, Volume = 0.45, Pitch = 1.0, Layers = { { Id = PING, Volume = 0.35, Pitch = 1.2 } } },
	Reveal3 = { Id = SWOOSH, Volume = 0.6, Pitch = 0.8, Layers = { { Id = PING, Volume = 0.45, Pitch = 1.0 }, { Id = PING, Volume = 0.35, Pitch = 1.5, Delay = 0.18 } } },
	Reveal4 = { Id = SWOOSH, Volume = 0.7, Pitch = 0.6, Layers = { { Id = PING, Volume = 0.5, Pitch = 0.8 }, { Id = PING, Volume = 0.4, Pitch = 1.2, Delay = 0.2 } } },
	Reveal5 = { Id = SWOOSH, Volume = 0.8, Pitch = 0.45, Layers = { { Id = PING, Volume = 0.55, Pitch = 0.6 }, { Id = SNAP, Volume = 0.4, Pitch = 0.5, Delay = 0.3 } } },
	Reveal6 = { Id = SWOOSH, Volume = 0.9, Pitch = 0.3, Layers = { { Id = PING, Volume = 0.6, Pitch = 0.4 }, { Id = SNAP, Volume = 0.5, Pitch = 0.3, Delay = 0.4 } } },
	Reveal7 = { Id = SWOOSH, Volume = 1, Pitch = 0.25, Layers = { { Id = PING, Volume = 0.7, Pitch = 0.3 }, { Id = PING, Volume = 0.5, Pitch = 0.6, Delay = 0.5 }, { Id = SNAP, Volume = 0.6, Pitch = 0.25, Delay = 0.9 } } },
	Reveal8 = { Id = SWOOSH, Volume = 1, Pitch = 0.2, Layers = { { Id = PING, Volume = 0.8, Pitch = 0.25 }, { Id = PING, Volume = 0.6, Pitch = 0.5, Delay = 0.6 }, { Id = PING, Volume = 0.6, Pitch = 1.0, Delay = 1.2 }, { Id = SNAP, Volume = 0.7, Pitch = 0.2, Delay = 1.5 } } },
} :: { [string]: SoundDef }

-- Ambience pro Gebiet (AreaConfig.Ambience). Leer = aus.
SoundConfig.Ambience = {
	Suburb = { Id = "", Volume = 0.35 }, -- 80s Mystery Synth (eigene Komposition einsetzen)
	Forest = { Id = "", Volume = 0.4 }, -- Wind / Insekten
	Lab = { Id = "", Volume = 0.35 }, -- elektrisches Brummen
	Rift = { Id = "", Volume = 0.4 },
	Otherworld = { Id = "", Volume = 0.4 }, -- dunkle Atmosphäre
	Void = { Id = "", Volume = 0.45 }, -- sehr tiefes, seltsames Dröhnen
}

return SoundConfig
