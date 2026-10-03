--!strict
-- WindowManager (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > WindowManager
--
-- Verwaltet die Menü-Fenster (immer nur eines offen). Jedes Fenster ist ein
-- Modul in Controllers > Windows mit:
--   Window.Title  = "INVENTORY"
--   Window.Icon   = "🎒"
--   Window.Size   = Vector2 (Pixel bei UIScale 1, optional)
--   Window.build(content: Frame)       -- einmalig beim ersten Öffnen
--   Window.onOpen(args: table?)        -- bei jedem Öffnen
--   Window.onClose()                   -- optional
--
-- Server kann Fenster öffnen (Event "OpenUI", z. B. über Stationen im Hub).

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Signal = require(Client:WaitForChild("Signal"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Root = require(Client:WaitForChild("UI"):WaitForChild("Root"))
local Sound = require(script.Parent:WaitForChild("SoundController"))

local UIConfig = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config"):WaitForChild("UIConfig"))

local C = UI.Colors
local F = UI.Fonts

local WindowManager = {}

WindowManager.Opened = Signal.new() -- (name)
WindowManager.Closed = Signal.new() -- (name)
WindowManager.current = nil :: string?

type WindowModule = {
	Title: string,
	Icon: string?,
	Size: Vector2?,
	build: (content: Frame) -> (),
	onOpen: ((args: any) -> ())?,
	onClose: (() -> ())?,
}

local modules: { [string]: WindowModule } = {}
local frames: { [string]: Frame } = {}
local built: { [string]: boolean } = {}

function WindowManager.register(name: string, module: WindowModule)
	modules[name] = module
end

local function createFrame(name: string, module: WindowModule): Frame
	local size = module.Size or Vector2.new(720, 470)
	local frame = UI.panel({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.new(0.94, 0, 0.86, 0),
		StrokeColor = C.Purple,
		StrokeThickness = 3,
		Visible = false,
		Parent = Root.Layers.Windows,
	})
	UI.new("UISizeConstraint", { MaxSize = size, MinSize = Vector2.new(300, 240), Parent = frame })
	UI.gradient(frame, C.Panel, C.Background, 90)

	local header = UI.new("Frame", {
		Name = "Header",
		BackgroundColor3 = C.PanelLight,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 52),
		Parent = frame,
	})
	UI.corner(header)
	UI.gradient(header, Color3.fromRGB(70, 40, 160), Color3.fromRGB(20, 22, 60), 0)
	UI.label({
		Name = "Title",
		Text = (module.Icon and (module.Icon .. "  ") or "") .. module.Title,
		Font = F.Title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -90, 0, 36),
		MaxTextSize = 32,
		Parent = header,
	})
	UI.button({
		Name = "Close",
		Text = "✕",
		Color = C.Red,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(UIConfig.MinTouchSize, 40),
		TextSize = 24,
		Parent = header,
		OnClick = function()
			WindowManager.close()
		end,
	})
	UI.new("Frame", {
		Name = "Accent",
		BackgroundColor3 = C.Red,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 52),
		Size = UDim2.new(1, 0, 0, 2),
		Parent = frame,
	})
	UI.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 62),
		Size = UDim2.new(1, -20, 1, -72),
		ClipsDescendants = true,
		Parent = frame,
	})
	UI.scanlines(frame, 30, 0.95)
	return frame
end

function WindowManager.open(name: string, args: any?)
	local module = modules[name]
	if not module then
		warn("[WindowManager] Unbekanntes Fenster:", name)
		return
	end
	if WindowManager.current and WindowManager.current ~= name then
		WindowManager.close(true)
	end
	local frame = frames[name]
	if not frame then
		frame = createFrame(name, module)
		frames[name] = frame
	end
	assert(frame)
	if not built[name] then
		built[name] = true
		module.build(frame:FindFirstChild("Content") :: Frame)
	end
	if module.onOpen then
		module.onOpen(args)
	end
	if not frame.Visible then
		frame.Visible = true
		local scale = frame:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = frame })
		scale.Scale = 0.9
		UI.tween(scale, 0.15, { Scale = 1 }, Enum.EasingStyle.Back)
		Sound.play("UIOpen")
	end
	WindowManager.current = name
	WindowManager.Opened:Fire(name)
	if GuiService.SelectedObject == nil and game:GetService("UserInputService").GamepadEnabled then
		GuiService.SelectedObject = (frame:FindFirstChild("Close", true) :: any)
	end
end

function WindowManager.close(switching: boolean?)
	local name = WindowManager.current
	if not name then
		return
	end
	local frame = frames[name]
	local module = modules[name]
	if frame then
		frame.Visible = false
	end
	if module and module.onClose then
		module.onClose()
	end
	WindowManager.current = nil
	GuiService.SelectedObject = nil
	if not switching then
		WindowManager.Closed:Fire(name)
	end
end

function WindowManager.toggle(name: string, args: any?)
	if WindowManager.current == name then
		WindowManager.close()
	else
		WindowManager.open(name, args)
	end
end

function WindowManager.isOpen(name: string): boolean
	return WindowManager.current == name
end

-- Alle Module in Controllers > Windows registrieren
function WindowManager.init()
	local folder = script.Parent:WaitForChild("Windows")
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, module = pcall(require, child)
			if ok then
				WindowManager.register(child.Name, module)
			else
				warn("[WindowManager] Fenster konnte nicht geladen werden:", child.Name, module)
			end
		end
	end
	State.on("OpenUI", function(data)
		if type(data) == "table" and type(data.Panel) == "string" then
			WindowManager.open(data.Panel, data)
		end
	end)
end

return WindowManager
