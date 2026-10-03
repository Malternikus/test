--!strict
-- AmbienceController (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > AmbienceController
--
-- Spielt pro Gebiet einen Ambience-/Musik-Loop (SoundConfig.Ambience) und
-- blendet beim Gebietswechsel über. Leere Ids = Stille (bis eigene/
-- lizenzierte Tracks eingetragen sind). Respektiert Settings.Music.

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local SoundConfig = require(Config:WaitForChild("SoundConfig"))
local AreaConfig = require(Config:WaitForChild("AreaConfig"))

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local AreaController = require(script.Parent:WaitForChild("AreaController"))

local AmbienceController = {}

local current: Sound? = nil
local currentKey: string? = nil

local function musicEnabled(): boolean
	local settings = State.data.Settings
	return settings == nil or settings.Music ~= false
end

local function play(key: string?)
	if key == currentKey then
		return
	end
	currentKey = key
	local old = current
	if old then
		UI.tween(old, 1.5, { Volume = 0 })
		task.delay(1.6, function()
			old:Destroy()
		end)
	end
	current = nil
	local def = key and SoundConfig.Ambience[key]
	if not def or def.Id == "" or not musicEnabled() then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "Ambience_" .. key
	sound.SoundId = def.Id
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = SoundService
	sound:Play()
	UI.tween(sound, 2, { Volume = def.Volume })
	current = sound
end

function AmbienceController.init()
	AreaController.AreaChanged:Connect(function(areaId)
		local def = AreaConfig.Get(areaId)
		play(def and def.Ambience or nil)
	end)
	State.Changed:Connect(function(key)
		if key == "Settings" then
			if not musicEnabled() then
				play(nil)
			elseif AreaController.current then
				local def = AreaConfig.Get(AreaController.current)
				currentKey = nil
				play(def and def.Ambience or nil)
			end
		end
	end)
end

return AmbienceController
