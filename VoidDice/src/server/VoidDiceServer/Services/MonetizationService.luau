--!strict
-- MonetizationService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > MonetizationService
--
-- Gamepasses und Developer Products.
--   * Gamepass-Besitz wird beim Join geprüft und im Profil gecacht.
--   * ProcessReceipt ist idempotent: Jede PurchaseId wird im Profil gemerkt
--     und erst nach erfolgreichem Speichern als "Granted" gemeldet. Stürzt der
--     Server vorher ab, liefert Roblox den Kauf erneut aus -> keine verlorenen
--     und keine doppelten Käufe.
--   * Keine Zufallsinhalte gegen Robux (siehe MonetizationConfig).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config"):WaitForChild("MonetizationConfig"))

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local MonetizationService = {}

local MAX_RECEIPTS = 100

local passByAssetId: { [number]: string } = {}
local productByAssetId: { [number]: string } = {}
for name, def in MonetizationConfig.Gamepasses do
	if def.Id ~= 0 then
		passByAssetId[def.Id] = name
	end
end
for name, def in MonetizationConfig.Products do
	if def.Id ~= 0 then
		productByAssetId[def.Id] = name
	end
end

local function grantPass(session, passName: string)
	SessionService.run(session, function(profile, ctx)
		if Logic.grantPass(profile, ctx, passName) then
			local def = MonetizationConfig.Gamepasses[passName]
			SessionService.toast(session, (def and def.DisplayName or passName) .. " unlocked!", "success")
		end
	end)
end

local function checkOwnedPasses(session)
	for name, def in MonetizationConfig.Gamepasses do
		if def.Id ~= 0 and not session.Profile.Passes[name] then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(session.UserId, def.Id)
			end)
			if ok and owns then
				SessionService.run(session, function(profile, ctx)
					Logic.grantPass(profile, ctx, name)
				end)
			end
		end
	end
end

local function processReceipt(receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local session = player and SessionService.get(player)
	if not session then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = session.Profile
	local purchaseId = tostring(receipt.PurchaseId)
	if table.find(profile.Purchases, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local productName = productByAssetId[receipt.ProductId]
	if not productName then
		warn("[Monetization] Unbekanntes Produkt:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local granted = SessionService.run(session, function(p, ctx)
		local ok = Logic.grantProduct(p, ctx, productName)
		if ok then
			table.insert(p.Purchases, purchaseId)
			while #p.Purchases > MAX_RECEIPTS do
				table.remove(p.Purchases, 1)
			end
		end
		return ok
	end)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not DataService.save(session.UserId, profile, false) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, assetId, purchased)
		if not purchased then
			return
		end
		local name = passByAssetId[assetId]
		local session = SessionService.get(player)
		if name and session then
			grantPass(session, name)
		end
	end)

	SessionService.onLoaded(function(session)
		task.spawn(checkOwnedPasses, session)
	end)

	-- Studio: Käufe ohne Robux testen
	SessionService.registerAction("TestPurchase", function(session, ctx, kind: string, name: string)
		if not (RunService:IsStudio() and MonetizationConfig.StudioTestPurchases) then
			return false, "Test purchases only work in Studio"
		end
		if kind == "Pass" and MonetizationConfig.Gamepasses[name] then
			Logic.grantPass(session.Profile, ctx, name)
			SessionService.toast(session, "[STUDIO] " .. name .. " granted", "success")
			return true
		elseif kind == "Product" and MonetizationConfig.Products[name] then
			Logic.grantProduct(session.Profile, ctx, name)
			SessionService.toast(session, "[STUDIO] " .. name .. " granted", "success")
			return true
		end
		return false, "Unknown item"
	end)
end

return MonetizationService
