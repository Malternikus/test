--!strict
-- Map (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Map
--
-- Teleports (Base, Hub, freigeschaltete Gebiete) und Freischalten neuer
-- Gebiete (Rebirth-Voraussetzung + Cash, vorheriges Gebiet nötig). Zeigt pro
-- Gebiet die Tagline, die Dice und das Fishing-Gewässer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local DiceConfig = require(Config:WaitForChild("DiceConfig"))
local FishingConfig = require(Config:WaitForChild("FishingConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))

local C = UI.Colors

local Map = {}
Map.Title = "MAP"
Map.Icon = "🗺"
Map.Size = Vector2.new(800, 540)

type AreaRow = { status: TextLabel, button: TextButton }
local areaRows: { [string]: AreaRow } = {}
local watcher: Cards.Watcher

local function teleport(target: string)
	Actions.send("Teleport", target)
	Cards.close() -- nach dem Teleport freie Sicht auf das Ziel
end

local function previousArea(def: any): any?
	for _, other in AreaConfig.List do
		if other.Order == def.Order - 1 then
			return other
		end
	end
	return nil
end

local function refresh(_changed: { [string]: boolean }?)
	local areas = State.data.Areas or {}
	local rebirths = State.data.Rebirths or 0
	local cash = State.data.Cash or 0
	for _, def in AreaConfig.List do
		local row = areaRows[def.Id]
		if row then
			local prev = previousArea(def)
			if areas[def.Id] then
				row.status.Text = "✓ Unlocked"
				row.status.TextColor3 = C.Green
				row.button.Text = "TELEPORT"
				UI.setButtonEnabled(row.button, true, C.Blue)
			else
				local needs = {}
				if prev and not areas[prev.Id] then
					table.insert(needs, "Unlock " .. prev.DisplayName .. " first")
				end
				table.insert(needs, (if rebirths >= def.RequiredRebirths then "✓ " else "") .. "Rebirth " .. def.RequiredRebirths)
				table.insert(needs, Format.cash(def.UnlockCost))
				row.status.Text = "🔒 " .. table.concat(needs, " · ")
				row.status.TextColor3 = C.Gold
				local ready = (not prev or areas[prev.Id] == true) and rebirths >= def.RequiredRebirths
				row.button.Text = if ready then "UNLOCK\n" .. Format.cash(def.UnlockCost) else "🔒 LOCKED"
				UI.setButtonEnabled(row.button, ready and cash >= def.UnlockCost, C.Green)
			end
		end
	end
end

local function simpleRow(scroll: ScrollingFrame, order: number, title: string, sub: string, target: string)
	local row = Cards.row(scroll, 64, order, C.Blue)
	Cards.rowText(row, title, sub, C.Text, 140)
	UI.button({
		Text = "TELEPORT",
		Color = C.Blue,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(128, 50),
		TextSize = 18,
		Parent = row,
		OnClick = function()
			teleport(target)
		end,
	})
end

function Map.build(content: Frame)
	local scroll = UI.scrollList(content, 8)
	simpleRow(scroll, 1, "🏠 MY BASE", "Your plot with your characters and Rift Pond.", "Base")
	simpleRow(scroll, 2, "🏙 TOWN HUB", "Shop, Rift Machine, Case Archive, Notice Board and Bait Shop.", "Hub")
	Cards.header(scroll, "AREAS", 3)

	for _, def in AreaConfig.List do
		local row = Cards.row(scroll, 112, 10 + def.Order, def.PrimaryColor)
		local dice = {}
		for _, d in DiceConfig.List do
			if d.Area == def.Id then
				table.insert(dice, "🎲 " .. d.DisplayName)
			end
		end
		local waters = FishingConfig.WatersByArea[def.Id]
		if waters then
			table.insert(dice, "🎣 " .. waters.DisplayName)
		end
		local _, sub = Cards.rowText(row, def.DisplayName, def.Tagline .. "\n" .. table.concat(dice, " · "), def.PrimaryColor, 150)
		sub.Size = UDim2.new(1, -174, 0, 48)
		local status = UI.label({
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 16, 1, -28),
			Size = UDim2.new(1, -174, 0, 22),
			MaxTextSize = 15,
			Parent = row,
		})
		local id = def.Id
		local button = UI.button({
			Text = "",
			Color = C.Blue,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(138, 56),
			TextSize = 18,
			Parent = row,
			OnClick = function()
				if State.data.Areas and State.data.Areas[id] then
					teleport(id)
				else
					Actions.send("UnlockArea", id)
				end
			end,
		})
		areaRows[id] = { status = status, button = button }
	end
	Cards.paragraph(scroll, "Unlocked areas stay unlocked forever (also after Rebirth).", 99)

	watcher = Cards.watch({ Areas = true, Rebirths = true, Cash = true }, refresh, 0.2)
end

function Map.onOpen(_args: any?)
	watcher.open()
end

function Map.onClose()
	watcher.close()
end

return Map
