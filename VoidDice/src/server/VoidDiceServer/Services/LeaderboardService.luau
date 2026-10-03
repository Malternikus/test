--!strict
-- LeaderboardService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > LeaderboardService
--
-- * leaderstats (Spielerliste): Cash, Rebirths
-- * Globale Boards im Hub (OrderedDataStore): MOST ROLLS, MOST REBIRTHS,
--   TOTAL CASH, RAREST COLLECTION, BASE VALUE
--
-- OrderedDataStores speichern nur ganze Zahlen < 2^63. Total Cash wird
-- deshalb logarithmisch kodiert (log10 * 1000) und zur Anzeige zurückgerechnet.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("VoidDice")
local Config = Shared:WaitForChild("Config")
local GameConfig = require(Config:WaitForChild("GameConfig"))
local UIConfig = require(Config:WaitForChild("UIConfig"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))
local WorldService = require(script.Parent:WaitForChild("WorldService"))

local LeaderboardService = {}

type BoardDef = {
	Key: string,
	Title: string,
	Part: string,
	Score: (profile: any) -> number,
	Display: (value: number) -> string,
}

local BOARDS: { BoardDef } = {
	{
		Key = "MostRolls", Title = "MOST ROLLS", Part = "Board_MostRolls",
		Score = function(p) return math.floor(p.Stats.TotalRolls) end,
		Display = function(v) return Format.short(v) end,
	},
	{
		Key = "MostRebirths", Title = "MOST REBIRTHS", Part = "Board_MostRebirths",
		Score = function(p) return math.floor(p.Rebirths) end,
		Display = function(v) return tostring(v) end,
	},
	{
		Key = "TotalCash", Title = "TOTAL CASH", Part = "Board_TotalCash",
		Score = function(p) return math.floor(math.log10(math.max(1, p.Stats.TotalCashEarned)) * 1000) end,
		Display = function(v) return Format.cash(10 ^ (v / 1000)) end,
	},
	{
		Key = "RarestCollection", Title = "RAREST COLLECTION", Part = "Board_RarestCollection",
		Score = function(p) return math.floor(Logic.Economy.collectionScore(p)) end,
		Display = function(v) return Format.short(v) .. " pts" end,
	},
	{
		Key = "BaseValue", Title = "BASE VALUE", Part = "Board_BaseValue",
		Score = function(p) return math.floor(Logic.Economy.baseValue(p)) end,
		Display = function(v) return Format.short(v) end,
	},
}

local stores: { [string]: OrderedDataStore } = {}
local available = true

local function setupLeaderstats(session)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Value = Format.cash(session.Profile.Cash)
	cash.Parent = folder
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = session.Profile.Rebirths
	rebirths.Parent = folder
	folder.Parent = session.Player
end

local function updateLeaderstats(session)
	local folder = session.Player:FindFirstChild("leaderstats")
	if not folder then
		return
	end
	local cash = folder:FindFirstChild("Cash") :: StringValue?
	local rebirths = folder:FindFirstChild("Rebirths") :: IntValue?
	if cash then
		cash.Value = Format.cash(session.Profile.Cash)
	end
	if rebirths then
		rebirths.Value = session.Profile.Rebirths
	end
end

local function buildBoardGui(part: BasePart, title: string): Frame
	local existing = part:FindFirstChild("BoardGui")
	if existing then
		existing:Destroy()
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = part

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = UIConfig.Colors.Background
	bg.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = UIConfig.Colors.Purple
	stroke.Thickness = 6
	stroke.Parent = bg

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0.12, 0)
	header.BackgroundColor3 = UIConfig.Colors.PanelLight
	header.Font = UIConfig.Fonts.Title
	header.TextScaled = true
	header.TextColor3 = UIConfig.Colors.Gold
	header.Text = title
	header.Parent = bg

	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0.04, 0.14)
	list.Size = UDim2.fromScale(0.92, 0.84)
	list.Parent = bg
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.005, 0)
	layout.Parent = list
	return list
end

local function renderBoard(list: Frame, rows: { { name: string, value: string } })
	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.005, 0)
	layout.Parent = list
	for i, row in rows do
		local label = Instance.new("TextLabel")
		label.LayoutOrder = i
		label.Size = UDim2.new(1, 0, 0.095, 0)
		label.BackgroundTransparency = if i % 2 == 0 then 1 else 0.85
		label.BackgroundColor3 = UIConfig.Colors.PanelLight
		label.Font = UIConfig.Fonts.Body
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = if i == 1 then UIConfig.Colors.Gold elseif i <= 3 then UIConfig.Colors.Text else UIConfig.Colors.SubText
		label.Text = string.format("  #%d  %s   %s", i, row.name, row.value)
		label.Parent = list
	end
	if #rows == 0 then
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0.1, 0)
		label.BackgroundTransparency = 1
		label.Font = UIConfig.Fonts.Body
		label.TextScaled = true
		label.TextColor3 = UIConfig.Colors.SubText
		label.Text = if available then "No entries yet" else "Leaderboards need DataStore access"
		label.Parent = list
	end
end

local nameCache: { [number]: string } = {}
local function nameFor(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return game:GetService("Players"):GetNameFromUserIdAsync(userId)
	end)
	local result = if ok and name then name else ("Player " .. userId)
	nameCache[userId] = result
	return result
end

local function pushScores(session)
	if not available then
		return
	end
	for _, board in BOARDS do
		local store = stores[board.Key]
		if store then
			local score = board.Score(session.Profile)
			if score > 0 then
				pcall(function()
					store:SetAsync(tostring(session.UserId), score)
				end)
			end
		end
	end
end

local function refreshBoards()
	local world = WorldService.get()
	if not world then
		return
	end
	for _, board in BOARDS do
		local part = world.Leaderboards and world.Leaderboards[board.Part]
		if part then
			local gui = part:FindFirstChild("BoardGui")
			local list = if gui then gui:FindFirstChild("List", true) else nil
			if not list then
				list = buildBoardGui(part, board.Title)
			end
			local rows = {}
			local store = stores[board.Key]
			if available and store then
				local ok, pages = pcall(function()
					return store:GetSortedAsync(false, 10)
				end)
				if ok and pages then
					for _, entry in pages:GetCurrentPage() do
						table.insert(rows, { name = nameFor(tonumber(entry.key) or 0), value = board.Display(entry.value) })
					end
				end
			else
				-- Ohne DataStore: aktuelle Spieler im Server anzeigen
				local entries = {}
				for _, session in SessionService.all() do
					table.insert(entries, { name = session.Player.DisplayName, score = board.Score(session.Profile) })
				end
				table.sort(entries, function(a, b)
					return a.score > b.score
				end)
				for i = 1, math.min(10, #entries) do
					table.insert(rows, { name = entries[i].name, value = board.Display(entries[i].score) })
				end
			end
			renderBoard(list :: Frame, rows)
		end
	end
end

function LeaderboardService.Start()
	for _, board in BOARDS do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore("VoidDice_LB_" .. board.Key)
		end)
		if ok then
			stores[board.Key] = store
		else
			available = false
		end
	end
	if game:GetService("RunService"):IsStudio() then
		local probeOk = pcall(function()
			local s = stores.MostRolls
			if s then
				s:GetSortedAsync(false, 1)
			end
		end)
		available = available and probeOk
	end

	SessionService.onLoaded(setupLeaderstats)
	SessionService.onFlush(function(session, ctx)
		if ctx.dirty.Cash or ctx.dirty.Rebirths then
			updateLeaderstats(session)
		end
	end)
	SessionService.onRemoving(function(session)
		task.spawn(pushScores, session)
	end)

	task.spawn(function()
		task.wait(5)
		while true do
			for _, session in SessionService.all() do
				if not session.Removing then
					pushScores(session)
				end
			end
			pcall(refreshBoards)
			task.wait(GameConfig.LeaderboardRefreshInterval)
		end
	end)
end

return LeaderboardService
