--!strict
-- Rebirth (Fenster)
-- Ort: StarterPlayerScripts > VoidDiceClient > Controllers > Windows > Rebirth
--
-- Zeigt aktuellen Rebirth, Kosten vs. Cash, was zurückgesetzt wird und was
-- bleibt, die Belohnungen des nächsten Rebirths (inkl. neu freischaltbarer
-- Gebiete), die aktuellen Gesamt-Boni und eine Vorschau der nächsten 3 Stufen.
-- REBIRTH braucht einen zweiten Tap zur Bestätigung.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local RebirthConfig = require(Config:WaitForChild("RebirthConfig"))
local AreaConfig = require(Config:WaitForChild("AreaConfig"))
local CosmeticConfig = require(Config:WaitForChild("CosmeticConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))

local Client = script.Parent.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Actions = require(Client:WaitForChild("Actions"))
local UI = require(Client:WaitForChild("UI"):WaitForChild("Components"))
local Cards = require(Client:WaitForChild("UI"):WaitForChild("Cards"))

local C = UI.Colors
local F = UI.Fonts

local Rebirth = {}
Rebirth.Title = "REBIRTH"
Rebirth.Icon = "♻"
Rebirth.Size = Vector2.new(780, 560)

local scroll: ScrollingFrame
local titleLabel: TextLabel
local setProgress: (number, string?) -> ()
local rebirthButton: TextButton
local setButtonText: (string) -> ()
local watcher: Cards.Watcher
local builtFor = -1

local function titleName(id: string): string
	local def = CosmeticConfig.Get(id)
	return if def then def.DisplayName else id
end

-- Belohnungen einer Stufe als Textzeilen
local function rewardLines(r: { [string]: any }): { string }
	local lines = {}
	if r.CashPct then
		table.insert(lines, string.format("💰 +%g%% Cash (permanent)", r.CashPct))
	end
	if r.LuckPct then
		table.insert(lines, string.format("🍀 +%g%% Luck (permanent)", r.LuckPct))
	end
	if r.BaseSlots then
		table.insert(lines, string.format("🏠 +%d Base Slots", r.BaseSlots))
	end
	if r.FishingSlots then
		table.insert(lines, string.format("🎣 +%d Fishing Spot", r.FishingSlots))
	end
	if r.GearSlots then
		table.insert(lines, string.format("🧰 +%d Gear Slot per character", r.GearSlots))
	end
	if r.AutoCollect then
		table.insert(lines, "🤖 Auto Collect (no more vault trips)")
	end
	if r.Title then
		table.insert(lines, "🏷 Title: " .. titleName(r.Title))
	end
	return lines
end

local function bulletList(lines: { string }, order: number, color: Color3?): number
	for _, text in lines do
		order += 1
		local label = Cards.paragraph(scroll, "  " .. text, order, color or C.Text)
		label.TextSize = 16
	end
	return order
end

local function rebuild()
	Cards.clear(scroll)
	local rebirths = State.data.Rebirths or 0
	local nextN = rebirths + 1
	local step = RebirthConfig.GetStep(nextN)
	local order = 0

	order += 1
	Cards.header(scroll, string.format("🎁 REBIRTH %d REWARDS", nextN), order, C.Green)
	order = bulletList(rewardLines(step.Rewards), order, C.Text)
	for _, area in AreaConfig.List do
		if area.RequiredRebirths == nextN then
			order += 1
			Cards.paragraph(scroll, string.format("  🗺 Unlocks access to %s (%s to open)", area.DisplayName, Format.cash(area.UnlockCost)), order, area.PrimaryColor)
		end
	end

	order += 1
	Cards.header(scroll, "⚠ RESETS", order, C.Red)
	order = bulletList({ "Cash and Vault → $0", "Character levels → Lv 1" }, order, C.Red:Lerp(Color3.new(1, 1, 1), 0.35))

	order += 1
	Cards.header(scroll, "✔ YOU KEEP", order, C.Green)
	order = bulletList({
		"All characters and their mutations",
		"Gear, potions and relics",
		"Dice and unlocked areas",
		"Index, cosmetics and titles",
		"All purchases and passes",
	}, order, C.SubText)

	local total = RebirthConfig.Accumulate(rebirths)
	order += 1
	Cards.header(scroll, string.format("📈 YOUR BONUSES NOW (REBIRTH %d)", rebirths), order, C.Luck)
	local now = {
		string.format("+%g%% Cash · +%g%% Luck", total.CashPct, total.LuckPct),
		string.format("+%d Base Slots · +%d Fishing Spots · +%d Gear Slots", total.BaseSlots, total.FishingSlots, total.GearSlots),
		"Auto Collect: " .. (if total.AutoCollect then "ON" else "not yet"),
	}
	if #total.Titles > 0 then
		local names = {}
		for _, id in total.Titles do
			table.insert(names, titleName(id))
		end
		table.insert(now, "Titles: " .. table.concat(names, ", "))
	end
	order = bulletList(now, order, C.Text)

	order += 1
	Cards.header(scroll, "🔮 COMING UP", order, C.Purple)
	for n = nextN + 1, nextN + 3 do
		local s = RebirthConfig.GetStep(n)
		local row = Cards.row(scroll, 64, order + n, C.Purple)
		Cards.rowText(row, string.format("REBIRTH %d · %s", n, Format.cash(s.Cost)), table.concat(rewardLines(s.Rewards), " · "), C.Text)
	end
	builtFor = rebirths
end

local function refresh(_changed: { [string]: boolean }?)
	local rebirths = State.data.Rebirths or 0
	if rebirths ~= builtFor then
		rebuild()
	end
	local cost = State.derived.RebirthCost or RebirthConfig.GetStep(rebirths + 1).Cost
	local cash = State.data.Cash or 0
	local ready = cash >= cost
	titleLabel.Text = string.format("♻ REBIRTH %d  →  %d", rebirths, rebirths + 1)
	setProgress(cash / math.max(1, cost), if ready then "READY! " .. Format.cash(cash) .. " / " .. Format.cash(cost) else Format.cash(cash) .. " / " .. Format.cash(cost))
	setButtonText(if ready then "♻ REBIRTH NOW" else "NEED " .. Format.cash(cost - cash) .. " MORE")
	UI.setButtonEnabled(rebirthButton, ready, C.Red)
end

function Rebirth.build(content: Frame)
	titleLabel = UI.label({ Font = F.Title, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 30), MaxTextSize = 28, Parent = content })
	local _, setter = UI.progress({ Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 24), Color = C.Purple, Parent = content })
	setProgress = setter

	local holder = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 1, -128), Parent = content })
	scroll = UI.scrollList(holder, 4)

	local button, setText = Cards.confirmButton({
		Text = "REBIRTH",
		ConfirmText = "TAP AGAIN: RESET CASH & LEVELS",
		Color = C.Red,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 0, 0, 58),
		TextSize = 28,
		Parent = content,
		OnConfirm = function()
			Actions.send("Rebirth")
		end,
	})
	rebirthButton = button
	setButtonText = setText

	watcher = Cards.watch({ Rebirths = true, Cash = true, Derived = Cards.derivedChanged({ "RebirthCost" }) }, refresh, 0.15)
end

function Rebirth.onOpen(_args: any?)
	watcher.open()
end

function Rebirth.onClose()
	watcher.close()
end

return Rebirth
