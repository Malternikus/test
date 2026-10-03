--!strict
-- Components (ModuleScript)
-- Ort: StarterPlayerScripts > VoidDiceClient > UI > Components
--
-- Bausteine für die gesamte UI: Panels, Buttons, Fenster, Tabs, Grids,
-- Fortschrittsbalken. Alles nutzt UIConfig (Farben/Schriften), damit der
-- Look an einer Stelle angepasst werden kann.
--
-- Mobile: Buttons haben Mindestgröße UIConfig.MinTouchSize, Grids nutzen
-- große Karten, Fenster passen sich per Scale an kleine Bildschirme an.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local UIConfig = require(Config:WaitForChild("UIConfig"))
local RarityConfig = require(Config:WaitForChild("RarityConfig"))

local Client = script.Parent.Parent
local Sound = require(Client:WaitForChild("Controllers"):WaitForChild("SoundController"))

local C = UIConfig.Colors
local F = UIConfig.Fonts

local Components = {}
Components.Colors = C
Components.Fonts = F

type Props = { [string]: any }

-- Instanz mit Properties und Kindern erzeugen
function Components.new(className: string, props: Props?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				(inst :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
local new = Components.new

function Components.corner(parent: Instance, radius: number?): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, radius or UIConfig.CornerRadius), Parent = parent })
end

function Components.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	return new("UIStroke", {
		Color = color or C.Stroke,
		Thickness = thickness or UIConfig.StrokeThickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Components.padding(parent: Instance, px: number)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = parent,
	})
end

function Components.gradient(parent: Instance, c1: Color3, c2: Color3, rotation: number?): UIGradient
	return new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rotation or 90, Parent = parent })
end

function Components.list(parent: Instance, padding: number?, horizontal: boolean?, align: Enum.HorizontalAlignment?): UIListLayout
	return new("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = parent,
	})
end

function Components.label(props: Props): TextLabel
	local defaults: Props = {
		BackgroundTransparency = 1,
		Font = F.Body,
		TextColor3 = C.Text,
		TextScaled = true,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 24),
		Text = "",
	}
	for k, v in props do
		if k ~= "MaxTextSize" then -- Helfer-Key, keine TextLabel-Property
			defaults[k] = v
		end
	end
	local label = new("TextLabel", defaults)
	if props.TextScaled ~= false then
		new("UITextSizeConstraint", { MaxTextSize = props.MaxTextSize or 40, MinTextSize = 8, Parent = label })
	end
	return label
end

function Components.panel(props: Props): Frame
	local defaults: Props = {
		BackgroundColor3 = C.Panel,
		BorderSizePixel = 0,
	}
	for k, v in props do
		if k ~= "StrokeColor" and k ~= "StrokeThickness" then -- Helfer-Keys, keine Frame-Properties
			defaults[k] = v
		end
	end
	local frame = new("Frame", defaults)
	Components.corner(frame)
	Components.stroke(frame, props.StrokeColor or C.Stroke, props.StrokeThickness)
	return frame
end

-- Button mit Hover/Press-Animation und Klick-Sound.
-- props: Text, Color, TextColor, Size, Position, AnchorPoint, OnClick, Parent,
--        TextSize (Max), Font, LayoutOrder, Name, Icon (Emoji/Text vor dem Text)
function Components.button(props: Props): TextButton
	local color: Color3 = props.Color or C.Purple
	local button = new("TextButton", {
		Name = props.Name or "Button",
		AutoButtonColor = false,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromOffset(160, UIConfig.MinTouchSize),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Text = if props.Icon then props.Icon .. "  " .. (props.Text or "") else (props.Text or ""),
		Font = props.Font or F.Title,
		TextColor3 = props.TextColor or C.Text,
		TextScaled = true,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = if props.Visible == nil then true else props.Visible,
		Selectable = true,
		Parent = props.Parent,
	})
	Components.corner(button, props.Radius)
	Components.stroke(button, props.StrokeColor or color:Lerp(Color3.new(1, 1, 1), 0.35), 2)
	Components.gradient(button, Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 210), 90)
	new("UITextSizeConstraint", { MaxTextSize = props.TextSize or 26, MinTextSize = 8, Parent = button })
	Components.padding(button, 6)

	local scale = new("UIScale", { Parent = button })
	local info = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, info, { Scale = 1.05 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, info, { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, info, { Scale = 0.94 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, info, { Scale = 1 }):Play()
	end)
	if props.OnClick then
		button.Activated:Connect(function()
			if button:GetAttribute("Disabled") then
				Sound.play("UIError")
				return
			end
			Sound.play("UIClick")
			props.OnClick()
		end)
	end
	return button
end

function Components.setButtonEnabled(button: TextButton, enabled: boolean, color: Color3?)
	button:SetAttribute("Disabled", not enabled)
	button.BackgroundColor3 = if enabled then (color or button.BackgroundColor3) else C.Disabled
	button.TextTransparency = if enabled then 0 else 0.35
end

-- Scrollbares Raster. cell = Zellgröße in Pixeln.
function Components.grid(parent: Instance, cell: Vector2, padding: number?): ScrollingFrame
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.Purple,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Selectable = false,
		Parent = parent,
	})
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(cell.X, cell.Y),
		CellPadding = UDim2.fromOffset(padding or 8, padding or 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = scroll,
	})
	Components.padding(scroll, 6)
	return scroll
end

function Components.scrollList(parent: Instance, padding: number?): ScrollingFrame
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.Purple,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Selectable = false,
		Parent = parent,
	})
	Components.list(scroll, padding or 8, false, Enum.HorizontalAlignment.Center)
	Components.padding(scroll, 6)
	return scroll
end

-- Fortschrittsbalken: gibt Frame und Setter zurück
function Components.progress(props: Props): (Frame, (number, string?) -> ())
	local bar = new("Frame", {
		BackgroundColor3 = C.Background,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.new(1, 0, 0, 16),
		Position = props.Position or UDim2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	Components.corner(bar, 8)
	Components.stroke(bar, C.Stroke, 1)
	local fill = new("Frame", {
		BackgroundColor3 = props.Color or C.Blue,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		Parent = bar,
	})
	Components.corner(fill, 8)
	local text = Components.label({ Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 3, Parent = bar, MaxTextSize = 16 })
	local function set(value: number, label: string?)
		fill.Size = UDim2.fromScale(math.clamp(value, 0, 1), 1)
		text.Text = label or ""
	end
	return bar, set
end

-- Tab-Leiste: tabs = { "Dice", "Passes" }, onSelect(name)
function Components.tabs(parent: Instance, tabs: { string }, onSelect: (string) -> ()): (Frame, (string) -> ())
	local bar = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, UIConfig.MinTouchSize),
		Parent = parent,
	})
	Components.list(bar, 6, true, Enum.HorizontalAlignment.Center)
	local buttons = {}
	local function select(name: string)
		for tabName, b in buttons do
			b.BackgroundColor3 = if tabName == name then C.Purple else C.PanelLight
		end
		onSelect(name)
	end
	for i, name in tabs do
		buttons[name] = Components.button({
			Text = string.upper(name),
			Size = UDim2.new(1 / #tabs, -6, 1, 0),
			Color = C.PanelLight,
			LayoutOrder = i,
			TextSize = 20,
			Parent = bar,
			OnClick = function()
				select(name)
			end,
		})
	end
	return bar, select
end

function Components.rarityColor(rarityId: string): Color3
	local def = RarityConfig.ById[rarityId]
	return if def then def.Color else C.Text
end

-- Kleiner Tag ("NEW!", "GOLDEN", "LOCKED")
function Components.tag(props: Props): TextLabel
	local tag = Components.label({
		Text = props.Text,
		Size = props.Size or UDim2.fromOffset(60, 18),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundTransparency = 0,
		BackgroundColor3 = props.Color or C.Red,
		TextColor3 = props.TextColor or C.Text,
		Font = F.Title,
		ZIndex = props.ZIndex or 5,
		MaxTextSize = 16,
		Parent = props.Parent,
	})
	Components.corner(tag, 6)
	return tag
end

-- Leichter CRT-Effekt: horizontale Linien über einem Frame
function Components.scanlines(parent: Instance, lines: number?, transparency: number?)
	local holder = new("Frame", {
		Name = "Scanlines",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Active = false,
		Parent = parent,
	})
	local n = lines or 24
	for i = 0, n - 1 do
		new("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = transparency or 0.9,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.fromScale(0, i / n),
			ZIndex = 50,
			Parent = holder,
		})
	end
	return holder
end

function Components.tween(inst: Instance, time: number, props: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
	local tween = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

return Components
