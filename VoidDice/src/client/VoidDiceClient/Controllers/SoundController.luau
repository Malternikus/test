--!strict
-- SoundController (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > SoundController
--
-- Spielt Sounds aus SoundConfig (inkl. Layer mit Verzögerung). Respektiert die
-- Einstellung SFX. Musik/Ambience macht der AmbienceController.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundConfig = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config"):WaitForChild("SoundConfig"))

local SoundController = {}

SoundController.enabled = true

local folder = Instance.new("Folder")
folder.Name = "VoidDiceSFX"
folder.Parent = SoundService

local templates: { [string]: Sound } = {}

local function template(id: string): Sound
	local existing = templates[id]
	if existing then
		return existing
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Parent = folder
	templates[id] = sound
	return sound
end

local function playOne(id: string, volume: number, pitch: number?)
	if id == "" then
		return
	end
	local sound = template(id):Clone()
	sound.Volume = volume
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = folder
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(8, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function SoundController.play(name: string)
	if not SoundController.enabled then
		return
	end
	local def = SoundConfig.Sounds[name]
	if not def then
		return
	end
	playOne(def.Id, def.Volume, def.Pitch)
	if def.Layers then
		for _, layer in def.Layers do
			if layer.Delay and layer.Delay > 0 then
				task.delay(layer.Delay, playOne, layer.Id, layer.Volume, layer.Pitch)
			else
				playOne(layer.Id, layer.Volume, layer.Pitch)
			end
		end
	end
end

-- Alle Templates vorladen (verhindert Verzögerung beim ersten Abspielen)
function SoundController.preload()
	for _, def in SoundConfig.Sounds do
		template(def.Id)
		for _, layer in def.Layers or {} do
			template(layer.Id)
		end
	end
	task.spawn(function()
		local list = {}
		for _, s in templates do
			table.insert(list, s)
		end
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(list)
		end)
	end)
end

return SoundController
