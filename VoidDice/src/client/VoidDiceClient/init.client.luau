-- VoidDiceClient (LocalScript)
-- Ort: StarterPlayer > StarterPlayerScripts > VoidDiceClient
--
-- Startet die Client-Seite. Der Client zeigt nur an und schickt Wünsche
-- (Actions) – entschieden wird alles auf dem Server.
--
--   State           Spiegel des Profils (Sync vom Server)
--   UI/             Bausteine (Components, Viewport, Root)
--   Controllers/    HUD, Reveal, Fenster, Base-Animation, Gebiete, Sound …

local Controllers = script:WaitForChild("Controllers")

local State = require(script:WaitForChild("State"))
local Root = require(script:WaitForChild("UI"):WaitForChild("Root"))

State.start()
Root.init()

local Sound = require(Controllers:WaitForChild("SoundController"))
Sound.preload()

local ORDER = {
	"WindowManager",
	"HUD",
	"RevealController",
	"Notifications",
	"BaseAnimator",
	"BaseInteraction",
	"AreaController",
	"AmbienceController",
	"TutorialController",
	"InputController",
}

for _, name in ORDER do
	local ok, err = pcall(function()
		local controller = require(Controllers:WaitForChild(name)) :: any
		controller.init()
	end)
	if not ok then
		warn("[VoidDiceClient] " .. name .. " konnte nicht starten:", err)
	end
end

-- SFX-Einstellung live übernehmen
State.Changed:Connect(function(key)
	if key == "Settings" and State.data.Settings then
		Sound.enabled = State.data.Settings.SFX ~= false
	end
end)

-- Falls der erste Sync schon vor dem Start der Controller ankam: alles einmal
-- neu zeichnen lassen.
if State.ready then
	for key in State.data do
		State.Changed:Fire(key)
	end
	State.Changed:Fire("Derived")
	State.Changed:Fire("Session")
end
