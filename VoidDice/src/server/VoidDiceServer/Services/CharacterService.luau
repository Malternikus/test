--!strict
-- CharacterService (ModuleScript)
-- Ort: ServerScriptService > VoidDiceServer > Services > CharacterService
--
-- Actions rund um Characters und Items: platzieren, upgraden, verkaufen,
-- sperren, Gear, Potions, Relikte. Jede Action prüft Besitz über das Profil
-- (uid muss im eigenen Profil existieren) – fremde uids gibt es dort nicht.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Config")
local PotionConfig = require(Config:WaitForChild("PotionConfig"))
local Format = require(ReplicatedStorage:WaitForChild("VoidDice"):WaitForChild("Util"):WaitForChild("Format"))

local Server = script.Parent.Parent
local Logic = require(Server:WaitForChild("Logic"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))

local Inventory = Logic.Inventory
local Modifiers = Logic.Modifiers

local CharacterService = {}

function CharacterService.Start()
	local register = SessionService.registerAction

	register("PlaceCharacter", function(session, ctx, uid: string)
		local profile = session.Profile
		local mods = Modifiers.compute(profile)
		if Inventory.freeSlot(profile, mods) == nil then
			-- Base voll: schwächsten ersetzen, wenn der neue besser ist
			if not Inventory.autoPlace(profile, ctx, uid, mods) then
				return false, "Base is full – remove a character first"
			end
			return true
		end
		return Inventory.place(profile, ctx, uid, mods)
	end)

	register("RemoveCharacter", function(session, ctx, uid: string)
		if not Inventory.unplace(session.Profile, ctx, uid) then
			return false, "Character is not in your base"
		end
		return true
	end)

	register("PlaceBest", function(session, ctx)
		local profile = session.Profile
		Inventory.placeBest(profile, ctx, Modifiers.compute(profile))
		return true
	end)

	register("UpgradeCharacter", function(session, ctx, uid: string, times: number?)
		local ok, result = Logic.Upgrades.upgrade(session.Profile, ctx, uid, times or 1)
		if not ok then
			return false, result :: string
		end
		SessionService.fire(session, "Upgraded", { Uid = uid, Times = result })
		return true
	end)

	register("SellCharacter", function(session, ctx, uid: string)
		local ok, result = Inventory.sell(session.Profile, ctx, uid)
		if not ok then
			return false, result :: string
		end
		SessionService.fire(session, "Sold", { Amount = result, Count = 1 })
		return true
	end)

	register("SellRarity", function(session, ctx, rarityId: string)
		local count, total = Inventory.sellRarity(session.Profile, ctx, rarityId)
		if count == 0 then
			return false, "Nothing to sell (locked, placed, fishing and mutated characters are kept)"
		end
		SessionService.fire(session, "Sold", { Amount = total, Count = count })
		SessionService.toast(session, string.format("Sold %d characters for %s", count, Format.cash(total)), "success")
		return true
	end)

	register("LockCharacter", function(session, ctx, uid: string, locked: boolean)
		if not Inventory.setLocked(session.Profile, ctx, uid, locked) then
			return false, "Character not found"
		end
		return true
	end)

	register("EquipGear", function(session, ctx, gearUid: string, charUid: string)
		return Logic.Items.equipGear(session.Profile, ctx, gearUid, charUid)
	end)

	register("UnequipGear", function(session, ctx, gearUid: string)
		if not Logic.Items.unequipGear(session.Profile, ctx, gearUid) then
			return false, "Gear is not equipped"
		end
		return true
	end)

	register("SellGear", function(session, ctx, gearUid: string)
		local ok, result = Logic.Items.sellGear(session.Profile, ctx, gearUid)
		if not ok then
			return false, result :: string
		end
		SessionService.fire(session, "Sold", { Amount = result, Count = 1 })
		return true
	end)

	register("UsePotion", function(session, ctx, potionId: string)
		local ok, err = Logic.Items.usePotion(session.Profile, ctx, potionId)
		if ok then
			local def = PotionConfig.Get(potionId)
			SessionService.toast(session, (def and def.DisplayName or potionId) .. " active!", "success")
		end
		return ok, err
	end)

	register("SellRelic", function(session, ctx, relicId: string)
		local ok, result = Logic.Items.sellRelic(session.Profile, ctx, relicId)
		if not ok then
			return false, result :: string
		end
		SessionService.fire(session, "Sold", { Amount = result, Count = 1 })
		return true
	end)
end

return CharacterService
