-- HUD (ModuleScript)
-- Ort: StarterPlayerScripts > GliderClient > HUD
--
-- Sehr einfache Test-Oberfläche, komplett per Code erstellt:
-- Tempo, Zeit, Checkpoint, Bestzeit, Reset-Button, Meldungen in der Mitte.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HUD = {}
HUD.__index = HUD

local function label(parent: Instance, name: string, position: UDim2, size: UDim2, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = position
	l.Size = size
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextSize = textSize
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.4
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = ""
	l.Parent = parent
	return l
end

function HUD.formatTime(seconds: number): string
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	return string.format("%02d:%05.2f", minutes, rest)
end

function HUD.new(onReset: () -> ())
	local self = setmetatable({}, HUD)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "GliderHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Roter Blitz beim Crash
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 0
	flash.Parent = gui

	-- Info-Box oben links
	local panel = Instance.new("Frame")
	panel.Name = "Info"
	panel.Position = UDim2.new(0, 16, 0, 56)
	panel.Size = UDim2.new(0, 230, 0, 118)
	panel.BackgroundColor3 = Color3.new(0, 0, 0)
	panel.BackgroundTransparency = 0.55
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	self.speed = label(panel, "Speed", UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 30), 24)
	self.time = label(panel, "Time", UDim2.new(0, 12, 0, 36), UDim2.new(1, -24, 0, 26), 20)
	self.checkpoint = label(panel, "Checkpoint", UDim2.new(0, 12, 0, 62), UDim2.new(1, -24, 0, 24), 16)
	self.best = label(panel, "Best", UDim2.new(0, 12, 0, 88), UDim2.new(1, -24, 0, 22), 14)
	self.best.TextColor3 = Color3.fromRGB(255, 220, 90)
	self.best.Text = "Bestzeit: --:--.--"

	-- Reset-Button oben rechts
	local button = Instance.new("TextButton")
	button.Name = "ResetButton"
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, 56)
	button.Size = UDim2.new(0, 130, 0, 44)
	button.BackgroundColor3 = Color3.fromRGB(220, 70, 50)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "Reset (R)"
	button.Parent = gui
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button
	button.Activated:Connect(onReset)

	-- Meldung in der Mitte (Countdown, CRASH, Ziel...)
	local message = label(gui, "Message", UDim2.fromScale(0, 0.28), UDim2.new(1, 0, 0, 70), 54)
	message.TextXAlignment = Enum.TextXAlignment.Center
	message.Font = Enum.Font.GothamBlack
	local sub = label(gui, "SubMessage", UDim2.new(0, 0, 0.28, 72), UDim2.new(1, 0, 0, 30), 22)
	sub.TextXAlignment = Enum.TextXAlignment.Center

	-- Steuerungshinweis unten
	local hint = label(gui, "Hint", UDim2.new(0, 0, 1, -40), UDim2.new(1, 0, 0, 24), 16)
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.TextTransparency = 0.25
	hint.Text = "A / D = lenken   ·   W / S = hoch / runter   ·   R = Neustart"

	gui.Parent = playerGui

	self.gui = gui
	self.flash = flash
	self.message = message
	self.subMessage = sub
	self._lastSpeed = -1
	self._lastTime = ""
	self._messageToken = 0
	return self
end

function HUD:SetSpeed(speed: number)
	local rounded = math.floor(speed + 0.5)
	if rounded ~= self._lastSpeed then
		self._lastSpeed = rounded
		self.speed.Text = string.format("%d studs/s", rounded)
	end
end

function HUD:SetTime(seconds: number)
	local text = HUD.formatTime(seconds)
	if text ~= self._lastTime then
		self._lastTime = text
		self.time.Text = "Zeit: " .. text
	end
end

function HUD:SetCheckpoint(current: number, total: number, label: string?)
	local text = string.format("Checkpoint %d / %d", current, total)
	if label then
		text ..= "  (" .. label .. ")"
	end
	self.checkpoint.Text = text
end

function HUD:SetBest(seconds: number?)
	self.best.Text = "Bestzeit: " .. (seconds and HUD.formatTime(seconds) or "--:--.--")
end

-- Zeigt eine Meldung; duration = nil -> bleibt stehen
function HUD:ShowMessage(text: string, duration: number?, color: Color3?, subText: string?)
	self._messageToken += 1
	local token = self._messageToken
	self.message.Text = text
	self.message.TextColor3 = color or Color3.new(1, 1, 1)
	self.message.TextTransparency = 0
	self.subMessage.Text = subText or ""
	self.subMessage.TextTransparency = 0
	if duration then
		task.delay(duration, function()
			if self._messageToken == token then
				self.message.Text = ""
				self.subMessage.Text = ""
			end
		end)
	end
end

function HUD:ClearMessage()
	self._messageToken += 1
	self.message.Text = ""
	self.subMessage.Text = ""
end

function HUD:Flash(color: Color3?)
	self.flash.BackgroundColor3 = color or Color3.fromRGB(255, 40, 40)
	self.flash.BackgroundTransparency = 0.45
	TweenService:Create(self.flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
end

return HUD
